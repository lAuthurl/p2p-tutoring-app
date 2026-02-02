class TutorModel {
  String id;
  String name;
  String image;
  bool? isFeatured;
  int? sessionsCount; // Number of tutoring sessions offered

  TutorModel({
    required this.id,
    required this.image,
    required this.name,
    this.isFeatured,
    this.sessionsCount,
  });

  /// Empty placeholder tutor
  static TutorModel empty() => TutorModel(id: '', image: '', name: '');
}
