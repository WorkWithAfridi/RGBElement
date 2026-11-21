import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'data/pattern_catalog.dart';
import 'models/light_scene.dart';
import 'protocol/leddmx_protocol.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RGBElementApp(state: AppState()));
}

class RGBElementApp extends StatelessWidget {
  const RGBElementApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) {
      final dark = state.isDark;
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xffa8ed78),
        brightness: dark ? Brightness.dark : Brightness.light,
        surface: dark ? const Color(0xff121513) : const Color(0xfff5f7f1),
      );
      return MaterialApp(
        title: 'RGBElement',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: scheme,
          scaffoldBackgroundColor: scheme.surface,
          fontFamily: 'Roboto',
          sliderTheme: SliderThemeData(
            trackHeight: 5,
            activeTrackColor: const Color(0xffb2ed79),
            inactiveTrackColor: dark
                ? const Color(0xff343a35)
                : const Color(0xffdce3d6),
            thumbColor: const Color(0xffb2ed79),
            overlayColor: const Color(0xffb2ed79).withValues(alpha: .14),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: dark
                ? const Color(0xff101310)
                : const Color(0xfff5f7f1),
            indicatorColor: const Color(0xffb2ed79).withValues(alpha: .18),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                fontSize: 11,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: dark
                ? const Color(0xff303a32)
                : const Color(0xff242c26),
            contentTextStyle: const TextStyle(color: Colors.white),
          ),
        ),
        home: RGBElementHome(state: state),
      );
    },
  );
}

class RGBElementHome extends StatelessWidget {
  const RGBElementHome({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: state.selectedTab,
          children: [
            _HomeTab(state: state),
            _EffectsTab(state: state),
            _StudioTab(state: state),
            _DevicesTab(state: state),
            _SettingsTab(state: state),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.selectedTab,
        onDestinationSelected: state.selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny_rounded),
            label: 'Control',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'Effects',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Studio',
          ),
          NavigationDestination(
            icon: Icon(Icons.bluetooth_searching_rounded),
            selectedIcon: Icon(Icons.bluetooth_connected_rounded),
            label: 'Lights',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    ),
  );
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xffb2ed79);
    final color = Color(state.selectedColor);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 13, 22, 30),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.blur_on_rounded,
                      color: Color(0xff172011),
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'RGB',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
                  ),
                  Text(
                    'ELEMENT',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: .5),
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  _ConnectionPill(state: state, compact: true),
                ],
              ),
              const SizedBox(height: 27),
              Text(
                'YOUR SPACE,',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                  color: accent,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'in a new light.',
                style: TextStyle(
                  fontSize: 32,
                  letterSpacing: -1.5,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 18),
              _LightHero(state: state, color: color),
              const SizedBox(height: 23),
              Row(
                children: [
                  const _SectionHeading('Color studio'),
                  const Spacer(),
                  IconButton(
                    tooltip: state.hasFavorite(state.selectedColor)
                        ? 'Remove from favorites'
                        : 'Save color',
                    onPressed: () => state.toggleFavorite(),
                    icon: Icon(
                      state.hasFavorite(state.selectedColor)
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: state.hasFavorite(state.selectedColor)
                          ? const Color(0xffff7697)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              _ColorWheel(state: state),
              Padding(
                padding: const EdgeInsets.only(top: 1, bottom: 7),
                child: Text(
                  'Drag around the ring to choose a color',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: .55),
                  ),
                ),
              ),
              _SliderCard(
                icon: Icons.color_lens_outlined,
                title: 'Color richness',
                helper: 'Adjusts how vivid the color looks.',
                value: (HSVColor.fromColor(color).saturation * 100).round(),
                suffix:
                    '${(HSVColor.fromColor(color).saturation * 100).round()}%',
                onChanged: (value) => state.setColorRichness(value.round()),
              ),
              const SizedBox(height: 10),
              _SliderCard(
                icon: Icons.brightness_6_rounded,
                title: 'Brightness',
                helper: 'Adjusts how much light the strip emits.',
                value: state.brightness,
                suffix: '${state.brightness}%',
                onChanged: (value) => state.setBrightness(value.round()),
              ),
              const SizedBox(height: 12),
              _FavoriteColors(state: state),
              const SizedBox(height: 17),
              const SizedBox(height: 10),
              _AdvancedControls(state: state),
              const SizedBox(height: 18),
              Row(
                children: [
                  const _SectionHeading('Quick palette'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: state.demo,
                    icon: const Icon(Icons.play_arrow_rounded, size: 17),
                    label: const Text('Color tour'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _PresetPalette(state: state),
              const SizedBox(height: 18),
              _SectionHeading('Saved looks'),
              const SizedBox(height: 10),
              if (state.scenes.isEmpty)
                _EmptyHint(
                  icon: Icons.bookmark_add_outlined,
                  text:
                      'Save a color, effect and brightness together in Studio.',
                )
              else
                SizedBox(
                  height: 83,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: math.min(state.scenes.length, 6),
                    separatorBuilder: (_, _) => const SizedBox(width: 9),
                    itemBuilder: (context, index) =>
                        _SceneChip(state: state, scene: state.scenes[index]),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LightHero extends StatelessWidget {
  const _LightHero({required this.state, required this.color});
  final AppState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = state.isDark;
    return Container(
      height: 154,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [
                  const Color(0xff1b2821),
                  const Color(0xff151a17),
                  const Color(0xff17201b),
                ]
              : [const Color(0xffe7f4dc), const Color(0xffedf3e9)],
        ),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -73,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: state.isOn ? .27 : .09),
                    blurRadius: 65,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 12,
            child: Icon(
              Icons.waves_rounded,
              size: 105,
              color: color.withValues(alpha: .12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      state.isConnected
                          ? Icons.bluetooth_connected_rounded
                          : Icons.bluetooth_rounded,
                      size: 15,
                      color: const Color(0xffb2ed79),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        state.deviceName ?? 'Your ambient light',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: .75),
                        ),
                      ),
                    ),
                    if (state.rssi != null)
                      Text(
                        '${state.rssi} dBm',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: .45),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.isOn
                                ? 'Your light is on'
                                : 'Ready when you are',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.45,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.isConnected
                                ? 'Tap the switch to ${state.isOn ? 'wind down' : 'bring it to life'}'
                                : 'Connect a light to start creating',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface
                                  .withValues(alpha: .55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(19),
                      onTap: () => state.isConnected
                          ? state.setPower(!state.isOn)
                          : state.selectTab(3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: state.isOn
                              ? const Color(0xffb2ed79)
                              : (dark
                                    ? const Color(0xff2d3530)
                                    : const Color(0xffdce5d7)),
                          borderRadius: BorderRadius.circular(19),
                          boxShadow: state.isOn
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: .23),
                                    blurRadius: 22,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          state.isOn
                              ? Icons.power_settings_new_rounded
                              : Icons.power_rounded,
                          color: state.isOn
                              ? const Color(0xff172011)
                              : Theme.of(context).colorScheme.onSurface
                                    .withValues(alpha: .58),
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorWheel extends StatelessWidget {
  const _ColorWheel({required this.state});
  final AppState state;

  void _update(Offset local, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final delta = local - center;
    final radius = math.min(size.width, size.height) / 2;
    if (delta.distance < radius * .78) return;
    final hue = (math.atan2(delta.dy, delta.dx) * 180 / math.pi + 360) % 360;
    state.setHue(hue);
  }

  @override
  Widget build(BuildContext context) {
    final selected = Color(state.selectedColor);
    return Center(
      child: SizedBox(
        width: 248,
        height: 248,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final hsv = HSVColor.fromColor(selected);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (details) => _update(details.localPosition, size),
              onPanUpdate: (details) => _update(details.localPosition, size),
              child: CustomPaint(
                painter: _WheelPainter(
                  hsv,
                  Theme.of(context).colorScheme.surface,
                ),
                child: Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selected.withValues(alpha: .4),
                          blurRadius: 26,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter(this.hsv, this.surfaceColor);
  final HSVColor hsv;
  final Color surfaceColor;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final ringPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xffff5252),
          Color(0xffffdc52),
          Color(0xff54ee89),
          Color(0xff48d6ff),
          Color(0xff7964ff),
          Color(0xffed56d1),
          Color(0xffff5252),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, ringPaint);
    final inside = radius * .78;
    canvas.drawCircle(center, inside, Paint()..color = surfaceColor);
    canvas.drawCircle(
      center,
      inside,
      Paint()
        ..color = surfaceColor.withValues(alpha: .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final pos = Offset(
      center.dx + math.cos(hsv.hue * math.pi / 180) * radius * .89,
      center.dy + math.sin(hsv.hue * math.pi / 180) * radius * .89,
    );
    canvas.drawCircle(pos, 8, Paint()..color = Colors.white);
    canvas.drawCircle(pos, 5.2, Paint()..color = hsv.toColor());
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.hsv != hsv || oldDelegate.surfaceColor != surfaceColor;
}

class _FavoriteColors extends StatelessWidget {
  const _FavoriteColors({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    final colors = state.favorites.isEmpty
        ? [
            0xffff6b6b,
            0xffffc857,
            0xffb2ed79,
            0xff59d4bd,
            0xff7c8cff,
            0xffd28bff,
          ]
        : state.favorites.take(8).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: colors
          .map(
            (value) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: InkWell(
                onTap: () => state.setColor(0xff000000 | value),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color(0xff000000 | value),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          Color(0xff000000 | value) ==
                              Color(state.selectedColor)
                          ? Colors.white
                          : Colors.white.withValues(alpha: .13),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AdvancedControls extends StatelessWidget {
  const _AdvancedControls({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Container(
    decoration: _panel(context),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 15),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
      leading: const Icon(Icons.tune_rounded, size: 19),
      title: const Text(
        'Fine tune',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      subtitle: const Text(
        'Temperature, motion & sound',
        style: TextStyle(fontSize: 10),
      ),
      shape: const RoundedRectangleBorder(),
      collapsedShape: const RoundedRectangleBorder(),
      children: [
        _SliderLine(
          icon: Icons.thermostat_rounded,
          title: 'Warmth',
          value: state.temperature,
          onChanged: (v) => state.setTemperature(v.round()),
        ),
        _SliderLine(
          icon: Icons.speed_rounded,
          title: 'Effect speed',
          value: state.speed,
          onChanged: (v) => state.setSpeed(v.round()),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('React to music', style: TextStyle(fontSize: 12)),
          secondary: const Icon(Icons.graphic_eq_rounded, size: 19),
          value: state.isMicOn,
          onChanged: state.setMic,
        ),
      ],
    ),
  );
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.suffix,
    required this.onChanged,
    this.helper,
  });
  final IconData icon;
  final String title;
  final int value;
  final String suffix;
  final ValueChanged<double> onChanged;
  final String? helper;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
    decoration: _panel(context),
    child: Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: const Color(0xffb2ed79)),
            const SizedBox(width: 9),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              suffix,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: .7),
              ),
            ),
          ],
        ),
        if (helper != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 26, top: 4),
              child: Text(
                helper!,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: .5),
                ),
              ),
            ),
          ),
        Slider(value: value.toDouble(), min: 0, max: 100, onChanged: onChanged),
      ],
    ),
  );
}

class _SliderLine extends StatelessWidget {
  const _SliderLine({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final int value;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        icon,
        size: 18,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 82,
        child: Text(title, style: const TextStyle(fontSize: 11)),
      ),
      Expanded(
        child: Slider(
          value: value.toDouble(),
          min: 0,
          max: 100,
          onChanged: onChanged,
        ),
      ),
      SizedBox(
        width: 35,
        child: Text(
          '$value%',
          textAlign: TextAlign.end,
          style: const TextStyle(fontSize: 10),
        ),
      ),
    ],
  );
}

class _PresetPalette extends StatelessWidget {
  const _PresetPalette({required this.state});
  final AppState state;
  static const presets = [
    0xffff6577,
    0xffffbd66,
    0xffd7ed70,
    0xff6fe2a5,
    0xff62d9d2,
    0xff71a9ff,
    0xff9b86ff,
    0xffd580ec,
    0xfffff1d3,
  ];
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 9,
    runSpacing: 9,
    children: presets
        .map(
          (value) => InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => state.setColor(value, debounce: false),
            onLongPress: () => state.toggleFavorite(value),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(value),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: Color(value).withValues(alpha: .12),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: state.hasFavorite(value)
                  ? const Icon(
                      Icons.favorite_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        )
        .toList(),
  );
}

class _EffectsTab extends StatefulWidget {
  const _EffectsTab({required this.state});
  final AppState state;
  @override
  State<_EffectsTab> createState() => _EffectsTabState();
}

class _EffectsTabState extends State<_EffectsTab> {
  final search = TextEditingController();
  String query = '';
  int filter = 0;
  List<int> get matches => List.generate(patternNames.length, (i) => i)
      .where(
        (i) =>
            patternNames[i].toLowerCase().contains(query.toLowerCase()) &&
            (filter == 0 ||
                (filter == 1 && i > 0 && i <= 40) ||
                (filter == 2 && i > 40 && i <= 120) ||
                (filter == 3 && i > 120)),
      )
      .toList();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _PageHeader(
        title: 'Effects',
        subtitle: 'Give your light a little motion.',
        icon: Icons.auto_awesome_rounded,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
        child: TextField(
          controller: search,
          onChanged: (value) => setState(() => query = value),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: 'Find a look or effect',
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      search.clear();
                      setState(() => query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      SizedBox(
        height: 39,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            for (final entry in const [
              (0, 'All'),
              (1, 'Flow'),
              (2, 'Pulse'),
              (3, 'Ambient'),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(entry.$2),
                  selected: filter == entry.$1,
                  onSelected: (_) => setState(() => filter = entry.$1),
                ),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 3, 22, 5),
        child: Row(
          children: [
            Text(
              '${matches.length} looks',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.speed_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: .6),
            ),
            Expanded(
              child: Slider(
                value: widget.state.speed.toDouble(),
                min: 0,
                max: 100,
                onChanged: (v) => widget.state.setSpeed(v.round()),
              ),
            ),
            Text(
              '${widget.state.speed}%',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
      Expanded(
        child: matches.isEmpty
            ? const Center(
                child: _EmptyHint(
                  icon: Icons.search_off_rounded,
                  text: 'No effects found. Try another search.',
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(18, 5, 18, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.65,
                ),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final i = matches[index];
                  final selected = widget.state.pattern == i;
                  final hue = (i * 47 + 55) % 360;
                  final fxColor = HSVColor.fromAHSV(
                    1,
                    hue.toDouble(),
                    .55,
                    .95,
                  ).toColor();
                  return InkWell(
                    onTap: () => widget.state.setPattern(i),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: selected
                            ? fxColor.withValues(alpha: .15)
                            : Theme.of(context).colorScheme.surfaceContainerLow,
                        border: Border.all(
                          color: selected
                              ? fxColor.withValues(alpha: .65)
                              : Theme.of(context).colorScheme.outlineVariant
                                    .withValues(alpha: .3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: fxColor.withValues(alpha: .18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  i == 0
                                      ? Icons.circle_outlined
                                      : Icons.waves_rounded,
                                  color: fxColor,
                                  size: 16,
                                ),
                              ),
                              const Spacer(),
                              if (selected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 17,
                                  color: fxColor,
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            patternNames[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'LOOK ${i.toString().padLeft(3, '0')}',
                            style: TextStyle(
                              fontSize: 8,
                              letterSpacing: 1.4,
                              color: Theme.of(context).colorScheme.onSurface
                                  .withValues(alpha: .45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    ],
  );
}

class _StudioTab extends StatelessWidget {
  const _StudioTab({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(21, 12, 21, 28),
        sliver: SliverList.list(
          children: [
            _PageHeader(
              title: 'Studio',
              subtitle: 'Save a mood. Bring it back anytime.',
              icon: Icons.grid_view_rounded,
              compact: true,
            ),
            const SizedBox(height: 10),
            _StudioFeatureCard(state: state),
            const SizedBox(height: 22),
            Row(
              children: [
                const _SectionHeading('Your looks'),
                const Spacer(),
                Text(
                  '${state.scenes.length} saved',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: .5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            if (state.scenes.isEmpty)
              _EmptyHint(
                icon: Icons.collections_bookmark_outlined,
                text: 'Your favorite moods will live here. Set a color and save your first look.',
              )
            else
              ...state.scenes.map(
                (scene) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SceneCard(state: state, scene: scene),
                ),
              ),
            const SizedBox(height: 20),
            const _SectionHeading('Recent activity'),
            const SizedBox(height: 10),
            if (state.activity.isEmpty)
              _EmptyHint(
                icon: Icons.history_rounded,
                text: 'Your light activity will show up here.',
              )
            else
              ...state.activity
                  .take(8)
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 6,
                            color: Color(0xffb2ed79),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              line,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    ],
  );
}

class _StudioFeatureCard extends StatelessWidget {
  const _StudioFeatureCard({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        colors: [Color(0xff263829), Color(0xff1a211d)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xffb2ed79),
              size: 19,
            ),
            const SizedBox(width: 8),
            const Text(
              'Make it yours',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.palette_outlined,
              color: Color(state.selectedColor),
              size: 25,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Save your current color, brightness and effect as one tap.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .65),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffb2ed79),
              foregroundColor: const Color(0xff172011),
            ),
            onPressed: () => _saveLook(context, state),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Save current look'),
          ),
        ),
      ],
    ),
  );
}

Future<void> _saveLook(BuildContext context, AppState state) async {
  final nameController = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Name your look'),
      content: TextField(
        controller: nameController,
        autofocus: true,
        maxLength: 24,
        decoration: const InputDecoration(hintText: 'e.g. Slow Sunday'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = nameController.text.trim();
            if (value.isNotEmpty) Navigator.pop(context, value);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  nameController.dispose();
  if (name != null && context.mounted) {
    state.saveScene(name);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('“$name” added to your looks')));
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.state, required this.scene});
  final AppState state;
  final LightScene scene;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => state.applyScene(scene),
    onLongPress: () => _deleteScene(context, state, scene),
    borderRadius: BorderRadius.circular(19),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: _panel(context),
      child: Row(
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: Color(scene.color),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.wb_sunny_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scene.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${scene.brightness}% brightness  ·  ${scene.pattern == 0 ? 'Solid color' : patternNames[scene.pattern]}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: .55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Delete look',
            onPressed: () => _deleteScene(context, state, scene),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
    ),
  );
}

Future<void> _deleteScene(
  BuildContext context,
  AppState state,
  LightScene scene,
) async {
  final remove = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Remove ${scene.name}?'),
      content: const Text('This saved look will be removed from Studio.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep it'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (remove == true) state.removeScene(scene);
}

class _SceneChip extends StatelessWidget {
  const _SceneChip({required this.state, required this.scene});
  final AppState state;
  final LightScene scene;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => state.applyScene(scene),
    borderRadius: BorderRadius.circular(18),
    child: Container(
      width: 130,
      padding: const EdgeInsets.all(10),
      decoration: _panel(context),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 48,
            decoration: BoxDecoration(
              color: Color(scene.color),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              scene.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DevicesTab extends StatelessWidget {
  const _DevicesTab({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _PageHeader(
        title: 'My lights',
        subtitle: 'One little tap away from a new mood.',
        icon: Icons.bluetooth_rounded,
        state: state,
      ),
      if (state.errorMessage != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: _ErrorBanner(message: state.errorMessage!),
        ),
      if (state.isConnected)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _ConnectedDeviceCard(state: state),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(21, 4, 21, 12),
        child: Row(
          children: [
            const _SectionHeading('Nearby devices'),
            const Spacer(),
            Text(
              '${state.devices.length} found',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: .5),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: state.devices.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 35),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xffb2ed79).withValues(alpha: .12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          state.isScanning
                              ? Icons.radar_rounded
                              : Icons.bluetooth_searching_rounded,
                          color: const Color(0xffb2ed79),
                          size: 31,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        state.isScanning
                            ? 'Looking for your light…'
                            : 'Let’s find your light',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Keep the controller powered and nearby. Your phone will discover LEDDMX Bluetooth lights.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: .58),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: state.isScanning ? null : state.scan,
                        icon: Icon(
                          state.isScanning
                              ? Icons.hourglass_top_rounded
                              : Icons.search_rounded,
                        ),
                        label: Text(
                          state.isScanning ? 'Scanning…' : 'Find a light',
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: state.devices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  final result = state.devices[index];
                  final name = result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : result.advertisementData.advName;
                  return _DeviceRow(
                    name: name,
                    rssi: result.rssi,
                    connecting:
                        state.isConnecting &&
                        state.device?.remoteId == result.device.remoteId,
                    connected:
                        state.isConnected &&
                        state.device?.remoteId == result.device.remoteId,
                    onTap: () => state.connect(result.device),
                  );
                },
              ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: state.isScanning ? state.stopScan : state.scan,
            icon: Icon(
              state.isScanning
                  ? Icons.stop_circle_outlined
                  : Icons.radar_rounded,
            ),
            label: Text(
              state.isScanning ? 'Stop searching' : 'Scan for lights',
            ),
          ),
        ),
      ),
    ],
  );
}

class _ConnectedDeviceCard extends StatelessWidget {
  const _ConnectedDeviceCard({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: const Color(0xffb2ed79).withValues(alpha: .11),
      border: Border.all(color: const Color(0xffb2ed79).withValues(alpha: .24)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.lightbulb_circle_rounded,
          color: Color(0xffb2ed79),
          size: 35,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.deviceName ?? 'RGB Light',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                state.device?.remoteId.str ?? 'Bluetooth LE',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: .55),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: state.disconnect,
          child: const Text('Disconnect'),
        ),
      ],
    ),
  );
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.name,
    required this.rssi,
    required this.connecting,
    required this.connected,
    required this.onTap,
  });
  final String name;
  final int rssi;
  final bool connecting;
  final bool connected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
    tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
    leading: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xffb2ed79).withValues(alpha: .13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.lightbulb_outline_rounded,
        color: Color(0xffb2ed79),
      ),
    ),
    title: Text(
      name.isEmpty ? 'Bluetooth light' : name,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      '$rssi dBm  ·  ${_signalLabel(rssi)}',
      style: const TextStyle(fontSize: 10),
    ),
    trailing: connecting
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(
            connected
                ? Icons.check_circle_rounded
                : Icons.arrow_forward_ios_rounded,
            size: connected ? 20 : 14,
            color: connected ? const Color(0xffb2ed79) : null,
          ),
  );
}

String _signalLabel(int rssi) => rssi > -55
    ? 'Excellent signal'
    : rssi > -70
    ? 'Good signal'
    : 'Weak signal';

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(21, 12, 21, 30),
        sliver: SliverList.list(
          children: [
            _PageHeader(
              title: 'Settings',
              subtitle: 'Make RGBElement feel like yours.',
              icon: Icons.settings_rounded,
              compact: true,
            ),
            const SizedBox(height: 9),
            const _SectionHeading('Appearance'),
            const SizedBox(height: 9),
            SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
              title: const Text(
                'Dark appearance',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'A calmer look for nighttime',
                style: TextStyle(fontSize: 10),
              ),
              value: state.isDark,
              onChanged: state.setDark,
              secondary: const Icon(Icons.dark_mode_outlined),
            ),
            const SizedBox(height: 19),
            const _SectionHeading('Light compatibility'),
            const SizedBox(height: 9),
            Container(
              decoration: _panel(context),
              child: Column(
                children: [
                  _SettingsChoice(
                    title: 'Frame style',
                    subtitle: state.options.framePad == 0xff
                        ? 'Standard · 7B FF … BF'
                        : 'Alternate · 7B 04 … BF',
                    icon: Icons.data_object_rounded,
                    value: state.options.framePad == 0xff
                        ? 'standard'
                        : 'alternate',
                    options: const {
                      'standard': 'Standard',
                      'alternate': 'Alternate',
                    },
                    onChanged: (v) => state.updateOptions(
                      ProtocolOptions(
                        framePad: v == 'standard' ? 0xff : 0x04,
                        colorDataByte7: state.options.colorDataByte7,
                        powerOn: state.options.powerOn,
                        powerOff: state.options.powerOff,
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 54),
                  _SettingsChoice(
                    title: 'Color byte 7',
                    subtitle: state.options.colorDataByte7 == 0
                        ? '0x00 · LEDDMX color format'
                        : '0xFF · LED LAMP variant',
                    icon: Icons.palette_outlined,
                    value: state.options.colorDataByte7.toString(),
                    options: const {'0': '0x00', '255': '0xFF'},
                    onChanged: (v) => state.updateOptions(
                      ProtocolOptions(
                        framePad: state.options.framePad,
                        colorDataByte7: int.parse(v),
                        powerOn: state.options.powerOn,
                        powerOff: state.options.powerOff,
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 54),
                  _SettingsChoice(
                    title: 'Power command',
                    subtitle: state.options.powerOn == 1
                        ? 'Newer controller · 01 / 00'
                        : 'Legacy controller · 03 / 02',
                    icon: Icons.power_settings_new_rounded,
                    value: state.options.powerOn.toString(),
                    options: const {
                      '1': 'New · 01 / 00',
                      '3': 'Older · 03 / 02',
                    },
                    onChanged: (v) => state.updateOptions(
                      ProtocolOptions(
                        framePad: state.options.framePad,
                        colorDataByte7: state.options.colorDataByte7,
                        powerOn: int.parse(v),
                        powerOff: v == '1' ? 0 : 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 19),
            const _SectionHeading('Sleep timer'),
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: _panel(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.nightlight_round,
                        size: 18,
                        color: Color(0xffb2ed79),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          state.sleepMinutes == null
                              ? 'Turn off automatically'
                              : 'Turns off in ${state.sleepMinutes} min',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (state.sleepMinutes != null)
                        TextButton(
                          onPressed: () => state.setSleepTimer(null),
                          child: const Text('Cancel'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final minutes in [15, 30, 60, 120])
                        ChoiceChip(
                          label: Text('$minutes min'),
                          selected: state.sleepMinutes == minutes,
                          onSelected: (_) => state.setSleepTimer(minutes),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 19),
            const _SectionHeading('About'),
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: _panel(context),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xffb2ed79),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.blur_on_rounded,
                      color: Color(0xff172011),
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RGBElement',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Made for your light · v1.0.0',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => showAboutDialog(
                      context: context,
                      applicationName: 'RGBElement',
                      applicationVersion: '1.0.0',
                      applicationLegalese: 'An independent companion for LEDDMX Bluetooth lights.',
                    ),
                    icon: const Icon(Icons.info_outline_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SettingsChoice extends StatelessWidget {
  const _SettingsChoice({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String title, subtitle, value;
  final IconData icon;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, size: 19),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    ),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 10)),
    trailing: PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (_) => options.entries
          .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      child: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.compact = false,
    this.state,
  });
  final String title, subtitle;
  final IconData icon;
  final bool compact;
  final AppState? state;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(21, compact ? 8 : 15, 21, 13),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xffb2ed79).withValues(alpha: .15),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: const Color(0xffb2ed79), size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 21,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: .55),
                ),
              ),
            ],
          ),
        ),
        if (state != null)
          IconButton(
            onPressed: state!.scan,
            icon: const Icon(Icons.refresh_rounded),
          ),
      ],
    ),
  );
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.state, this.compact = false});
  final AppState state;
  final bool compact;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => state.selectTab(3),
    borderRadius: BorderRadius.circular(30),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: state.isConnected
            ? const Color(0xffb2ed79).withValues(alpha: .14)
            : Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.isConnected
                  ? const Color(0xffb2ed79)
                  : Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: .45),
            ),
          ),
          if (!compact) const SizedBox(width: 7),
          if (!compact)
            Text(
              state.connectionLabel,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: -.3,
    ),
  );
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: _panel(context),
    child: Row(
      children: [
        Icon(icon, size: 21, color: const Color(0xffb2ed79)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: .64),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xffff6b6b).withValues(alpha: .13),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: Color(0xffff8888),
          size: 18,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 11, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

BoxDecoration _panel(BuildContext context) => BoxDecoration(
  color: Theme.of(context).colorScheme.surfaceContainerLow,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .22),
  ),
);
