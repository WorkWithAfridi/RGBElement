class ProtocolOptions {
  const ProtocolOptions({
    this.framePad = 0xff,
    this.colorDataByte7 = 0x00,
    this.powerOn = 0x01,
    this.powerOff = 0x00,
  });

  final int framePad;
  final int colorDataByte7;
  final int powerOn;
  final int powerOff;

  List<int> frame(int command, [List<int> data = const []]) {
    final payload = List<int>.filled(5, 0xff);
    for (var i = 0; i < data.length && i < 5; i++) {
      payload[i] = data[i].clamp(0, 255);
    }
    return [0x7b, framePad, command, ...payload, 0xbf];
  }

  List<int> power(bool on) => frame(0x04, [on ? powerOn : powerOff]);
  List<int> color(int r, int g, int b) =>
      frame(0x07, [r, g, b, colorDataByte7]);
  List<int> brightness(int value) {
    final p = value.clamp(0, 100);
    return frame(0x01, [p * 32 ~/ 100, p, 0x00]);
  }

  List<int> temperature(int value) {
    final p = value.clamp(0, 100);
    return frame(0x09, [p * 32 ~/ 100, p]);
  }

  List<int> pattern(int index) => frame(0x03, [index.clamp(0, 210)]);
  List<int> speed(int value) => frame(0x02, [value.clamp(0, 100), 0x00]);
  List<int> mic(bool enabled) => frame(0x0b, [enabled ? 1 : 0, 0x00]);
}
