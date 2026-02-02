class SubjectModel {
  String id;
  String name;
  String image;
  String? parentId; // For subtopics
  bool? isFeatured;

  SubjectModel({
    required this.id,
    required this.name,
    required this.image,
    this.parentId,
    this.isFeatured,
  });

  static SubjectModel empty() => SubjectModel(id: '', image: '', name: '');
}
