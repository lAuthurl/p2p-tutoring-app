class TutorReview {
  final String reviewText;
  final double rating;

  TutorReview({
    required this.reviewText,
    required this.rating,
  });
}

class TutorModel {
  final String name;
  final String image;
  final double rating;
  final String? description;
  final List<String>? skills;
  final String? experience;
  final List<TutorReview>? reviews;

  TutorModel({
    required this.name,
    required this.image,
    required this.rating,
    this.description,
    this.skills,
    this.experience,
    this.reviews,
  });
}
