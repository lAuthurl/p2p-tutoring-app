import 'package:p2p_tutoring_app/Feautures/dashboard/Home/models/tutor_model.dart';
import 'session_attribute_model.dart';
import 'session_variation_model.dart';

class TutoringSessionModel {
  String id;
  String title;
  int availableSeats; // total seats for this session
  double pricePerSession;
  String thumbnail;
  bool? isFeatured;
  TutorModel? tutor;
  String? description;
  String? subjectId;
  List<String>? images;
  DateTime? date; // general date of session
  List<SessionAttributeModel>? sessionAttributes; // updated
  List<SessionVariationModel>? sessionVariations; // updated

  TutoringSessionModel({
    required this.id,
    required this.title,
    required this.availableSeats,
    this.pricePerSession = 0.0,
    this.thumbnail = '',
    this.isFeatured = false,
    this.tutor,
    this.description,
    this.subjectId,
    this.images,
    this.date,
    this.sessionAttributes,
    this.sessionVariations,
  });

  double? get salePricePerSession => null;

  /// Create Empty for clean code
  static TutoringSessionModel empty() => TutoringSessionModel(
    id: '',
    title: '',
    availableSeats: 0,
    pricePerSession: 0.0,
    thumbnail: '',
    images: [],
  );
}
