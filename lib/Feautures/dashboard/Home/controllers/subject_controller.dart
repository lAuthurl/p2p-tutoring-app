import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../models/ModelProvider.dart';

class SubjectController extends GetxController {
  // ---------------- Singleton ----------------
  static SubjectController get instance => Get.find();

  // ---------------- Reactive State ----------------
  final RxList<Subject> subjects = <Subject>[].obs;

  // ---------------- Lifecycle ----------------
  @override
  void onInit() {
    super.onInit();
    fetchSubjects();
  }

  // ---------------- Helper: Check if user can sync ----------------
  Future<bool> _canSync() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user != null;
    } catch (_) {
      print('⚠️ User not signed in, skipping DataStore fetch for subjects');
      return false;
    }
  }

  // ---------------- Fetch all subjects ----------------
  Future<void> fetchSubjects() async {
    if (!await _canSync()) return;

    try {
      final allSubjects = await Amplify.DataStore.query(Subject.classType);
      subjects.assignAll(allSubjects);
      print('✅ Subjects loaded: total=${subjects.length}');
    } catch (e) {
      print('❌ Error fetching subjects: $e');
    }
  }

  // ---------------- Getters ----------------
  List<Subject> getAllSubjects() => subjects.toList();

  List<Subject> getFeaturedSubjects({int limit = 8}) {
    final featured = subjects.where((s) => s.isFeatured ?? false).toList();
    return featured.length <= limit ? featured : featured.sublist(0, limit);
  }

  List<TutoringSession> getTutoringSessionsForSubject(String subjectId) {
    final subject = subjects.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => Subject(id: '', name: 'Unknown'),
    );
    return subject.tutoringSessions ?? [];
  }
}
