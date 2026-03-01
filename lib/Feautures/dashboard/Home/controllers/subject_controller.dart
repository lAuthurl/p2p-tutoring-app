// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../models/ModelProvider.dart';

class SubjectController extends GetxController {
  // ---------------- Singleton ----------------
  static SubjectController get instance => Get.find();

  // ---------------- Reactive State ----------------
  final RxList<Subject> subjects = <Subject>[].obs;

  // Currently selected subject (nullable)
  final Rxn<Subject> selectedSubject = Rxn<Subject>();

  // Filtered sessions based on selected subject
  final RxList<TutoringSession> filteredSessions = <TutoringSession>[].obs;

  // Featured subjects (reactive)
  final RxList<Subject> featuredSubjects = <Subject>[].obs;

  // Reactive filtered subjects for search
  final RxList<Subject> filteredSubjects = <Subject>[].obs;

  // Track loading state
  final RxBool isLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Recompute filtered sessions whenever selection changes
    ever(selectedSubject, (_) => _updateFilteredSessions());

    // Update filtered sessions and featured subjects whenever subjects list changes
    ever(subjects, (_) {
      _updateFilteredSessions();
      _updateFeaturedSubjects();
    });

    // Update filtered subjects whenever featuredSubjects changes
    ever(featuredSubjects, (_) {
      filteredSubjects.assignAll(featuredSubjects);
    });

    // Initial fetch
    fetchSubjects();
  }

  // ---------------- Fetch all subjects ----------------
  Future<void> fetchSubjects() async {
    if (!await _canSync()) return;

    try {
      final allSubjects = await Amplify.DataStore.query(Subject.classType);

      if (allSubjects.isEmpty) {
        print('📦 No subjects found. Seeding defaults...');
        await _seedDefaultSubjects();
      }

      final updatedSubjects = await Amplify.DataStore.query(Subject.classType);
      subjects.assignAll(updatedSubjects);
      isLoaded.value = true;

      print('✅ Subjects loaded: total=${subjects.length}');
    } catch (e) {
      print('❌ Error fetching subjects: $e');
      isLoaded.value = true;
    }
  }

  // ---------------- Check if user can sync ----------------
  Future<bool> _canSync() async {
    try {
      await Amplify.Auth.getCurrentUser();
      return true;
    } catch (_) {
      print('⚠️ User not signed in, skipping DataStore fetch for subjects');
      return false;
    }
  }

  // ---------------- Seed default subjects ----------------
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

  // ---------------- Reactive Updates ----------------
  void _updateFilteredSessions() {
    if (selectedSubject.value == null) {
      filteredSessions.value =
          subjects
              .expand<TutoringSession>(
                (s) => s.tutoringSessions ?? <TutoringSession>[],
              )
              .toList();
    } else {
      filteredSessions.value =
          selectedSubject.value!.tutoringSessions ?? <TutoringSession>[];
    }
  }

  void _updateFeaturedSubjects({int limit = 10}) {
    final featured = subjects.where((s) => s.isFeatured ?? false).toList();
    featuredSubjects.value =
        featured.length <= limit ? featured : featured.sublist(0, limit);

    // Reset filteredSubjects for search
    filteredSubjects.assignAll(featuredSubjects);
  }

  // ---------------- Select / Deselect Subject ----------------
  void selectSubject(Subject subject) {
    if (selectedSubject.value?.id == subject.id) {
      selectedSubject.value = null;
    } else {
      selectedSubject.value = subject;
    }
  }

  // ---------------- Search Filter ----------------
  void filterSubjects(String query) {
    if (query.isEmpty) {
      filteredSubjects.assignAll(featuredSubjects);
    } else {
      filteredSubjects.assignAll(
        featuredSubjects
            .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
            .toList(),
      );
    }
  }
}
