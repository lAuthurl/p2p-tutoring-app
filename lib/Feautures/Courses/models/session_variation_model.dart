class SessionVariationModel {
  final String id;
  String? image;
  String? description;
  double pricePerSession;
  int availableSeats; // seats available for this variation
  Map<String, String>
  sessionAttributes; // e.g., {'Level': 'Beginner', 'Duration': '1hr', 'Mode': 'Online'}
  DateTime? lectureTime; // scheduled lecture time

  SessionVariationModel({
    required this.id,
    this.image,
    this.description,
    this.pricePerSession = 0.0,
    this.availableSeats = 0,
    required this.sessionAttributes,
    this.lectureTime,
  });

  /// Create empty for clean code
  static SessionVariationModel empty() =>
      SessionVariationModel(id: '', sessionAttributes: {});

  /// Map JSON (Firebase) to Model
  factory SessionVariationModel.fromJson(Map<String, dynamic> document) {
    return SessionVariationModel(
      id: document['id'] ?? '',
      image: document['image'],
      description: document['description'],
      pricePerSession: document['pricePerSession']?.toDouble() ?? 0.0,
      availableSeats: document['availableSeats'] ?? 0,
      sessionAttributes: Map<String, String>.from(
        document['sessionAttributes'] ?? {},
      ),
      lectureTime:
          document['lectureTime'] != null
              ? DateTime.parse(document['lectureTime'])
              : null,
    );
  }
}
