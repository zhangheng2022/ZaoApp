class GenUiMiniAppPackage {
  const GenUiMiniAppPackage({
    required this.id,
    required this.schemaVersion,
    required this.appVersion,
    required this.name,
    required this.prompt,
    required this.surfaceJson,
    required this.runtimeData,
    required this.savedAt,
    required this.updatedAt,
  });

  final String id;
  final int schemaVersion;
  final int appVersion;
  final String name;
  final String prompt;
  final List<Map<String, Object?>> surfaceJson;
  final Map<String, Object?> runtimeData;
  final DateTime savedAt;
  final DateTime updatedAt;

  factory GenUiMiniAppPackage.fromJson(Map<String, Object?> json) {
    final surfaceJson = (json['surfaceJson'] as List<Object?>? ?? const [])
        .map((item) => Map<String, Object?>.from(item! as Map))
        .toList(growable: false);

    return GenUiMiniAppPackage(
      id: json['id'] as String? ?? '',
      schemaVersion: json['schemaVersion'] as int? ?? 0,
      appVersion: json['appVersion'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      surfaceJson: surfaceJson,
      runtimeData: Map<String, Object?>.from(
        json['runtimeData'] as Map? ?? const {},
      ),
      savedAt: DateTime.parse(json['savedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'schemaVersion': schemaVersion,
    'appVersion': appVersion,
    'name': name,
    'prompt': prompt,
    'surfaceJson': surfaceJson,
    'runtimeData': runtimeData,
    'savedAt': savedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  GenUiMiniAppPackage copyWith({
    String? id,
    int? schemaVersion,
    int? appVersion,
    String? name,
    String? prompt,
    List<Map<String, Object?>>? surfaceJson,
    Map<String, Object?>? runtimeData,
    DateTime? savedAt,
    DateTime? updatedAt,
  }) => GenUiMiniAppPackage(
    id: id ?? this.id,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    appVersion: appVersion ?? this.appVersion,
    name: name ?? this.name,
    prompt: prompt ?? this.prompt,
    surfaceJson: surfaceJson ?? this.surfaceJson,
    runtimeData: runtimeData ?? this.runtimeData,
    savedAt: savedAt ?? this.savedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
