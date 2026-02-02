import 'dart:math';
import 'package:get/get.dart';
import '../models/subject_model.dart';
import '../../../Courses/models/tutoring_session_model.dart';
import 'subject_controller.dart';
import 'dummy_tutoring_data.dart';

class HomeController extends GetxController {
  static HomeController get instance => Get.find();

  // --- Carousel
  final carouselCurrentIndex = 0.obs;

  void updatePageIndicator(int index) {
    carouselCurrentIndex.value = index;
  }

  // --- Featured Subjects
  List<SubjectModel> getFeaturedSubjects({int limit = 8}) {
    final subjectController = Get.put(SubjectController());
    final subjects = subjectController.getFeaturedSubjects(limit);
    return subjects.isNotEmpty ? subjects : [];
  }

  // --- Featured Tutoring Sessions
  List<TutoringSessionModel> getFeaturedSessions({int limit = 6}) {
    final sessions =
        DummyTutoringData.tutoringSessions
            .where((session) => session.isFeatured ?? false)
            .toList();

    if (sessions.isEmpty) return [];
    return sessions.length <= limit ? sessions : sessions.sublist(0, limit);
  }

  // --- Popular Tutoring Sessions (last 4)
  List<TutoringSessionModel> getPopularSessions({int count = 4}) {
    final sessions = DummyTutoringData.tutoringSessions;
    if (sessions.isEmpty) return [];

    final startIndex = max(0, sessions.length - count);
    return sessions.sublist(startIndex).toList();
  }

  // --- Recent Tutoring Sessions (last 4)
  late final List<TutoringSessionModel> recentTutoringSessions;

  @override
  void onInit() {
    super.onInit();
    _initRecentSessions();
  }

  void _initRecentSessions({int count = 4}) {
    final sessions = DummyTutoringData.tutoringSessions;
    if (sessions.isEmpty) {
      recentTutoringSessions = [];
      return;
    }

    final startIndex = max(0, sessions.length - count);
    recentTutoringSessions = sessions.sublist(startIndex);
  }
}
