import 'dart:convert';

class LightScene {
  const LightScene({
    required this.id,
    required this.name,
    required this.color,
    required this.brightness,
    required this.speed,
    required this.pattern,
    required this.temperature,
  });

  final String id;
  final String name;
  final int color;
  final int brightness;
  final int speed;
  final int pattern;
  final int temperature;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'brightness': brightness,
    'speed': speed,
    'pattern': pattern,
    'temperature': temperature,
  };

  factory LightScene.fromJson(Map<String, Object?> json) => LightScene(
    id: json['id']! as String,
    name: json['name']! as String,
    color: json['color']! as int,
    brightness: json['brightness']! as int,
    speed: json['speed']! as int,
    pattern: json['pattern']! as int,
    temperature: json['temperature']! as int,
  );

  static String encodeAll(List<LightScene> scenes) =>
      jsonEncode(scenes.map((scene) => scene.toJson()).toList());

  static List<LightScene> decodeAll(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((item) => LightScene.fromJson(item as Map<String, Object?>))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
