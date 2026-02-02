class SessionAttributeModel {
  String name; // e.g., Level, Duration, Mode
  final List<String> values;

  SessionAttributeModel({required this.name, required this.values});

  /// Map JSON (Firebase) to Model
  factory SessionAttributeModel.fromJson(Map<String, dynamic> document) {
    return SessionAttributeModel(
      name: document['name'] ?? '',
      values: List<String>.from(document['values'] ?? []),
    );
  }
}
