import 'package:get/get.dart';
import '../models/subject_model.dart';
import '../../../Courses/models/tutoring_session_model.dart';
import 'dummy_tutoring_data.dart';

class SubjectController extends GetxController {
  static SubjectController get instance => Get.find();

  /// -- Load Featured Subjects (Top-level)
  List<SubjectModel> getFeaturedSubjects(int take) {
    return DummyTutoringData.subjects
        .where(
          (subject) =>
              (subject.isFeatured ?? false) && subject.parentId == null,
        )
        .take(take)
        .toList();
  }

  /// -- Load Subtopics for a Subject
  List<SubjectModel> getSubTopics(String subjectId) {
    return DummyTutoringData.subjects
        .where((subject) => subject.parentId == subjectId)
        .toList();
  }

  /// -- Get Tutoring Sessions for a Subtopic
  List<TutoringSessionModel> getSessionsBySubTopic(
    String subTopicId,
    int take,
  ) {
    return DummyTutoringData.tutoringSessions
        .where((session) => session.subjectId == subTopicId)
        .take(take)
        .toList();
  }
}
