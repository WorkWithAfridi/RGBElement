import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:material_ui/material_ui.dart' show Color, HSVColor;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/light_scene.dart';
import '../protocol/leddmx_protocol.dart';

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  AppState() {
    WidgetsBinding.instance.addObserver(this);
    _scanSubscription = FlutterBluePlus.onScanResults.listen(_onScanResults);
    _scanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
      isScanning = scanning;
      notifyListeners();
    });
  }

  static const serviceId = '0000ffe0-0000-1000-8000-00805f9b34fb';
  static const characteristicId = '0000ffe1-0000-1000-8000-00805f9b34fb';

  final Map<String, ScanResult> _results = {};
  final List<LightScene> scenes = [];
  final List<int> favorites = [];
  final List<String> activity = [];
  final ValueNotifier<bool> darkMode = ValueNotifier(true);
  final ValueNotifier<int> tabSelection = ValueNotifier(0);
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<bool>? _scanningSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  Timer? _colorDebounce;
  Timer? _brightnessDebounce;
  Timer? _speedDebounce;
  Timer? _temperatureDebounce;
  Timer? _persistenceDebounce;
  BluetoothDevice? device;
  BluetoothCharacteristic? _writeCharacteristic;
  ProtocolOptions options = const ProtocolOptions();
  int selectedTab = 0;
  int selectedColor = 0xff73e5b0;
  int brightness = 78;
  int speed = 48;
  int temperature = 50;
  int pattern = 0;
  bool isOn = false;
  bool isMicOn = false;
  bool isScanning = false;
  bool isConnecting = false;
  bool isConnected = false;
  bool isDark = true;
  String? errorMessage;
  String? deviceName;
  String? lastDeviceId;
  int? rssi;
  int? sleepMinutes;
  Timer? _sleepTimer;
  bool _restoreInProgress = false;
  bool _manualDisconnect = false;

  List<ScanResult> get devices =>
      _results.values
          .where((result) => result.device.remoteId.str != lastDeviceId)
          .toList()
        ..sort((a, b) => b.rssi.compareTo(a.rssi));

  void selectTab(int index) {
    selectedTab = index;
    tabSelection.value = index;
    notifyListeners();
  }

  String get connectionLabel => isConnected
      ? 'Connected'
      : isConnecting
      ? 'Connecting'
      : 'Not connected';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final storedScenes = LightScene.decodeAll(
      prefs.getString('rgbelement.scenes'),
    );
    scenes
      ..clear()
      ..addAll(storedScenes);
    final colors = prefs.getStringList('rgbelement.favorites') ?? [];
    favorites
      ..clear()
      ..addAll(colors.map((value) => int.tryParse(value) ?? 0));
    final log = prefs.getStringList('rgbelement.activity') ?? [];
    activity
      ..clear()
      ..addAll(log);
    isDark = prefs.getBool('rgbelement.dark') ?? true;
    darkMode.value = isDark;
    selectedColor =
        0xff000000 |
        (prefs.getInt('rgbelement.color') ?? (selectedColor & 0xffffff));
    brightness = prefs.getInt('rgbelement.brightness') ?? brightness;
    speed = prefs.getInt('rgbelement.speed') ?? speed;
    options = ProtocolOptions(
      framePad: prefs.getInt('rgbelement.framePad') ?? 0xff,
      colorDataByte7: prefs.getInt('rgbelement.colorByte7') ?? 0,
      powerOn: prefs.getInt('rgbelement.powerOn') ?? 1,
      powerOff: prefs.getInt('rgbelement.powerOff') ?? 0,
    );
    lastDeviceId = prefs.getString('rgbelement.lastDeviceId');
    deviceName = prefs.getString('rgbelement.lastDeviceName');
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rgbelement.scenes', LightScene.encodeAll(scenes));
    await prefs.setStringList(
      'rgbelement.favorites',
      favorites.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      'rgbelement.activity',
      activity.take(30).toList(),
    );
    await prefs.setBool('rgbelement.dark', isDark);
    await prefs.setInt('rgbelement.color', selectedColor & 0xffffff);
    await prefs.setInt('rgbelement.brightness', brightness);
    await prefs.setInt('rgbelement.speed', speed);
    await prefs.setInt('rgbelement.framePad', options.framePad);
    await prefs.setInt('rgbelement.colorByte7', options.colorDataByte7);
    await prefs.setInt('rgbelement.powerOn', options.powerOn);
    await prefs.setInt('rgbelement.powerOff', options.powerOff);
    if (lastDeviceId == null) {
      await prefs.remove('rgbelement.lastDeviceId');
      await prefs.remove('rgbelement.lastDeviceName');
    } else {
      await prefs.setString('rgbelement.lastDeviceId', lastDeviceId!);
      await prefs.setString(
        'rgbelement.lastDeviceName',
        deviceName ?? 'RGB Light',
      );
    }
  }

  void _scheduleSave() {
    _persistenceDebounce?.cancel();
    _persistenceDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_save());
    });
  }

  Future<void> scan() async {
    errorMessage = null;
    var needsLocation = false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
        needsLocation = sdkInt < 31;
        final permissions = needsLocation
            ? [Permission.locationWhenInUse]
            : [Permission.bluetoothScan, Permission.bluetoothConnect];
        final statuses = await permissions.request();
        if (statuses.values.any((status) => !status.isGranted)) {
          errorMessage = 'Bluetooth permission is needed to find your light.';
          notifyListeners();
          return;
        }
      }
      _results.clear();
      isScanning = true;
      notifyListeners();
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        continuousUpdates: true,
        androidUsesFineLocation: needsLocation,
      );
    } catch (error) {
      errorMessage = _friendlyError(error);
      isScanning = false;
      notifyListeners();
    }
  }

  void _onScanResults(List<ScanResult> results) {
    isScanning = FlutterBluePlus.isScanningNow;
    for (final result in results) {
      final name = result.device.platformName.isNotEmpty
          ? result.device.platformName
          : result.advertisementData.advName;
      if (name.isNotEmpty &&
          (name.toUpperCase().contains('LEDDMX') ||
              name.toUpperCase().contains('LED'))) {
        _results[result.device.remoteId.str] = result;
      }
    }
    notifyListeners();
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    isScanning = false;
    notifyListeners();
  }

  Future<void> reconnectSaved() async {
    final id = lastDeviceId;
    if (id == null ||
        id.isEmpty ||
        isConnecting ||
        isConnected ||
        _restoreInProgress) {
      return;
    }
    _manualDisconnect = false;
    _restoreInProgress = true;
    try {
      await connect(BluetoothDevice.fromId(id), restoring: true);
    } finally {
      _restoreInProgress = false;
    }
  }

  Future<void> forgetSavedDevice() async {
    await disconnect(userInitiated: true);
    lastDeviceId = null;
    deviceName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rgbelement.lastDeviceId');
    await prefs.remove('rgbelement.lastDeviceName');
    notifyListeners();
  }

  Future<void> _restoreLastDevice() async {
    if (_manualDisconnect) return;
    await reconnectSaved();
  }

  Future<void> restoreSavedDeviceOnStartup() => _restoreLastDevice();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_restoreLastDevice());
    }
  }

  Future<void> connect(BluetoothDevice target, {bool restoring = false}) async {
    if (device?.remoteId == target.remoteId && isConnected) return;
    if (device?.remoteId == target.remoteId && isConnecting) return;
    await stopScan();
    await disconnect();
    _manualDisconnect = false;
    device = target;
    isConnecting = true;
    errorMessage = null;
    final result = _results[target.remoteId.str];
    final rememberedName = target.remoteId.str == lastDeviceId
        ? deviceName
        : null;
    deviceName = target.platformName.isNotEmpty
        ? target.platformName
        : result?.advertisementData.advName ?? rememberedName;
    rssi = result?.rssi;
    notifyListeners();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
        if (sdkInt >= 31 &&
            !(await Permission.bluetoothConnect.request()).isGranted) {
          throw Exception(
            'Bluetooth permission is needed to reconnect to your light.',
          );
        }
      }
      await target.connect(
        timeout: const Duration(seconds: 15),
        license: License.nonprofit,
      );
      _connectionSubscription = target.connectionState.listen((state) {
        isConnected = state == BluetoothConnectionState.connected;
        if (!isConnected) _writeCharacteristic = null;
        isConnecting = false;
        notifyListeners();
      });
      final services = await target.discoverServices(timeout: 15);
      final service = services
          .where((s) => s.uuid.str128.toLowerCase() == serviceId)
          .firstOrNull;
      if (service == null) {
        throw Exception('The light did not expose its FFE0 service.');
      }
      final characteristic = service.characteristics
          .where((c) => c.uuid.str128.toLowerCase() == characteristicId)
          .firstOrNull;
      if (characteristic == null) {
        throw Exception('The writable FFE1 control channel was not found.');
      }
      _writeCharacteristic = characteristic;
      isConnected = true;
      isOn = true;
      lastDeviceId = target.remoteId.str;
      deviceName ??= target.platformName.isNotEmpty
          ? target.platformName
          : 'RGB Light';
      unawaited(_save());
      _record('Connected to ${deviceName ?? 'RGB light'}');
      await send(options.power(true));
    } catch (error) {
      isConnecting = false;
      isConnected = false;
      errorMessage = _friendlyError(error);
      if (!restoring) _record('Connection failed: $errorMessage');
      try {
        await target.disconnect();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> disconnect({bool userInitiated = false}) async {
    if (userInitiated) _manualDisconnect = true;
    _colorDebounce?.cancel();
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    final old = device;
    _writeCharacteristic = null;
    isConnected = false;
    isConnecting = false;
    device = null;
    if (old != null) {
      try {
        await old.disconnect();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> send(List<int> bytes) async {
    final characteristic = _writeCharacteristic;
    if (!isConnected || characteristic == null) {
      errorMessage = 'Connect to your light to send controls.';
      notifyListeners();
      return;
    }
    try {
      final withoutResponse = characteristic.properties.writeWithoutResponse;
      await characteristic.write(bytes, withoutResponse: withoutResponse);
    } catch (error) {
      errorMessage = _friendlyError(error);
      notifyListeners();
    }
  }

  void setPower(bool on) {
    isOn = on;
    notifyListeners();
    send(options.power(on));
    _record(on ? 'Light turned on' : 'Light turned off');
  }

  void setColor(int color, {bool debounce = true}) {
    selectedColor = color | 0xff000000;
    _scheduleSave();
    notifyListeners();
    _colorDebounce?.cancel();
    if (!debounce) {
      _sendColor();
    } else {
      _colorDebounce = Timer(const Duration(milliseconds: 65), _sendColor);
    }
  }

  void setHue(double hue) {
    final current = HSVColor.fromColor(Color(selectedColor));
    setColor(current.withHue(hue).toColor().toARGB32());
  }

  void setColorRichness(int value) {
    final current = HSVColor.fromColor(Color(selectedColor));
    setColor(
      current.withSaturation(value.clamp(0, 100) / 100).toColor().toARGB32(),
    );
  }

  Future<void> _sendColor() async {
    final color = selectedColor;
    await send(
      options.color((color >> 16) & 0xff, (color >> 8) & 0xff, color & 0xff),
    );
  }

  void setBrightness(int value) {
    brightness = value.clamp(0, 100);
    notifyListeners();
    _brightnessDebounce?.cancel();
    _brightnessDebounce = Timer(const Duration(milliseconds: 70), () {
      unawaited(send(options.brightness(brightness)));
    });
    _scheduleSave();
  }

  void setSpeed(int value) {
    speed = value.clamp(0, 100);
    notifyListeners();
    _speedDebounce?.cancel();
    _speedDebounce = Timer(const Duration(milliseconds: 70), () {
      unawaited(send(options.speed(speed)));
    });
    _scheduleSave();
  }

  void setTemperature(int value) {
    temperature = value.clamp(0, 100);
    notifyListeners();
    _temperatureDebounce?.cancel();
    _temperatureDebounce = Timer(const Duration(milliseconds: 70), () {
      unawaited(send(options.temperature(temperature)));
    });
  }

  void setPattern(int value) {
    pattern = value.clamp(0, 210);
    notifyListeners();
    send(options.pattern(pattern));
  }

  void setMic(bool enabled) {
    isMicOn = enabled;
    notifyListeners();
    send(options.mic(enabled));
  }

  bool hasFavorite(int color) => favorites.contains(color & 0xffffff);

  void toggleFavorite([int? color]) {
    final value = (color ?? selectedColor) & 0xffffff;
    if (favorites.contains(value)) {
      favorites.remove(value);
    } else {
      favorites.insert(0, value);
      if (favorites.length > 24) favorites.removeLast();
    }
    _save();
    notifyListeners();
  }

  void saveScene(String name) {
    scenes.add(
      LightScene(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        color: selectedColor,
        brightness: brightness,
        speed: speed,
        pattern: pattern,
        temperature: temperature,
      ),
    );
    _save();
    _record('Saved look “$name”');
  }

  Future<void> applyScene(LightScene scene) async {
    selectedColor = scene.color;
    brightness = scene.brightness;
    speed = scene.speed;
    pattern = scene.pattern;
    temperature = scene.temperature;
    isOn = true;
    notifyListeners();
    await send(options.power(true));
    await send(
      options.color(
        (selectedColor >> 16) & 0xff,
        (selectedColor >> 8) & 0xff,
        selectedColor & 0xff,
      ),
    );
    await send(options.brightness(brightness));
    await send(options.speed(speed));
    await send(options.pattern(pattern));
    await send(options.temperature(temperature));
    _save();
  }

  void removeScene(LightScene scene) {
    scenes.removeWhere((item) => item.id == scene.id);
    _save();
    notifyListeners();
  }

  void setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    sleepMinutes = minutes;
    if (minutes != null) {
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        setPower(false);
        sleepMinutes = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    isDark = value;
    darkMode.value = value;
    notifyListeners();
    await _save();
  }

  void updateOptions(ProtocolOptions value) {
    options = value;
    _save();
    notifyListeners();
  }

  Future<void> demo() async {
    if (!isConnected) {
      errorMessage = 'Connect to a light to start the color tour.';
      notifyListeners();
      return;
    }
    setPower(true);
    for (final color in [
      0xffff5370,
      0xffffc857,
      0xff73e5b0,
      0xff7c8cff,
      0xffca8cff,
    ]) {
      if (!isConnected) return;
      selectedColor = color;
      notifyListeners();
      await _sendColor();
      await Future<void>.delayed(const Duration(milliseconds: 850));
    }
  }

  void _record(String message) {
    final time = DateTime.now();
    activity.insert(
      0,
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}  $message',
    );
    if (activity.length > 30) activity.removeLast();
    _save();
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('timeout') || message.contains('Timeout')) {
      return 'The light took too long to respond. Power-cycle it and try again.';
    }
    if (message.contains('permission') || message.contains('Permission')) {
      return 'Bluetooth permission is required to find nearby lights.';
    }
    return message.replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanSubscription?.cancel();
    _scanningSubscription?.cancel();
    _connectionSubscription?.cancel();
    _colorDebounce?.cancel();
    _brightnessDebounce?.cancel();
    _speedDebounce?.cancel();
    _temperatureDebounce?.cancel();
    _persistenceDebounce?.cancel();
    _sleepTimer?.cancel();
    darkMode.dispose();
    tabSelection.dispose();
    super.dispose();
  }
}
