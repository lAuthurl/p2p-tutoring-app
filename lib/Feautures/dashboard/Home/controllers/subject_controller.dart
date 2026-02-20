// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../models/ModelProvider.dart';

class SubjectController extends GetxController {
  // ---------------- Singleton ----------------
  static SubjectController get instance => Get.find();

  // ---------------- Reactive State ----------------
  final RxList<Subject> subjects = <Subject>[].obs;

  // 🔹 Track if subjects have finished loading
  final RxBool isLoaded = false.obs;

  // ---------------- Helper: Check if user can sync ----------------
  Future<bool> _canSync() async {
    try {
      await Amplify.Auth.getCurrentUser();
      return true;
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

      // 🔥 AUTO SEED IF EMPTY
      if (allSubjects.isEmpty) {
        print('📦 No subjects found. Seeding defaults...');
        await _seedDefaultSubjects();
      }

      final updatedSubjects = await Amplify.DataStore.query(Subject.classType);

      subjects.assignAll(updatedSubjects);
      isLoaded.value = true; // ✅ Mark as loaded

      print('✅ Subjects loaded: total=${subjects.length}');
    } catch (e) {
      print('❌ Error fetching subjects: $e');
      isLoaded.value =
          true; // even on error, mark loaded to avoid infinite loader
    }
  }

  // ---------------- Seed Default Subjects ----------------
  Future<void> _seedDefaultSubjects() async {
    final defaultSubjects = [
      Subject(
        id: "1",
        name: "Math",
        icon:
            "https://p2p-tutoring-assets.s3.amazonaws.com/icons/categories/math.png",
        thumbnail:
            "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/math-basics.png",
        isFeatured: true,
      ),
      Subject(
        id: "2",
        name: "Physics",
        icon:
            "https://p2p-tutoring-assets.s3.amazonaws.com/icons/categories/atom.png",
        thumbnail:
            "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/physics-intro.png",
        isFeatured: true,
      ),
      Subject(
        id: "3",
        name: "Chemistry",
        icon:
            "https://p2p-tutoring-assets.s3.amazonaws.com/icons/categories/enzyme.png",
        thumbnail:
            "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/chemistry-lab.png",
        isFeatured: true,
      ),
      Subject(
        id: "4",
        name: "Comp Sci",
        icon:
            "https://p2p-tutoring-assets.s3.amazonaws.com/icons/categories/code.png",
        thumbnail:
            "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/cs-101.png",
        isFeatured: true,
      ),
      Subject(
        id: "5",
        name: "Biology",
        icon:
            "https://p2p-tutoring-assets.s3.amazonaws.com/icons/categories/dna.png",
        thumbnail:
            "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/biology-101.png",
        isFeatured: true,
      ),
      Subject(
        id: "6",
        name: "Economics",
        icon:
            "https://p2p-tutoring-assets.s3.amazonaws.com/icons/categories/economic.png",
        thumbnail:
            "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/economics-101.png",
        isFeatured: true,
      ),
      Subject(
        id: "7",
        name: "Literature",
        icon:
            "https://p2p-tutoring-assets.s3.amazonaws.com/icons/categories/research.png",
        thumbnail:
            "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/literature.png",
        isFeatured: true,
      ),
      Subject(
        id: "8",
        name: "Engineering",
        icon:
            "https://p2p-tutoring-assets.s3.amazonaws.com/icons/categories/technology.png",
        thumbnail:
            "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/engineering.png",
        isFeatured: true,
      ),
      Subject(
        id: "9",
        name: "Arts",
        icon:
            "https://p2p-tutoring-assets.s3.amazonaws.com/icons/categories/art.png",
        thumbnail:
            "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/arts.png",
        isFeatured: true,
      ),
      Subject(
        id: "10",
        name: "Others",
        icon:
            "https://p2p-tutoring-assets.s3.amazonaws.com/icons/categories/application.png",
        thumbnail:
            "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/others.png",
        isFeatured: true,
      ),
    ];

    for (final subject in defaultSubjects) {
      await Amplify.DataStore.save(subject);
    }

    print('🚀 Default subjects seeded successfully');
  }

  // ---------------- Getters ----------------
  List<Subject> getAllSubjects() => subjects.toList();

  List<Subject> getFeaturedSubjects({int limit = 10}) {
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
