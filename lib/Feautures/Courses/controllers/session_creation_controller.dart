// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../models/ModelProvider.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../dashboard/Home/controllers/home_controller.dart';

class SessionCreationController extends GetxController {
  static SessionCreationController get instance => Get.find();

  final formKey = GlobalKey<FormState>();

  // Text Controllers
  final title = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  final subjectId = ''.obs;

  final isFeatured = false.obs;
  final isUploading = false.obs;

  /// -------------------------
  /// Predefined subject thumbnails
  /// -------------------------
  final Map<String, String> seededThumbnails = {
    "1":
        "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/math-basics.png",
    "2":
        "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/physics-intro.png",
    "3":
        "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/chemistry-lab.png",
    "4":
        "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/cs-101.png",
    "5":
        "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/biology-101.png",
    "6":
        "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/economics-101.png",
    "7":
        "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/literature.png",
    "8":
        "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/engineering.png",
    "9": "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/arts.png",
    "10":
        "https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/others.png",
  };

  /// Get thumbnail based on selected subject
  String? get selectedThumbnail => seededThumbnails[subjectId.value];

  /// ================================
  /// ENSURE TUTOR EXISTS
  /// ================================
  Future<Tutor> getOrCreateTutor() async {
    final currentUser = UserController.instance.currentUser.value;
    if (currentUser == null) {
      throw Exception("User not authenticated");
    }

    final tutors = await Amplify.DataStore.query(
      Tutor.classType,
      where: Tutor.NAME.eq(currentUser.username),
    );

    if (tutors.isNotEmpty) return tutors.first;

    final newTutor = Tutor(
      name: currentUser.username,
      email: currentUser.email,
    );

    await Amplify.DataStore.save(newTutor);
    safePrint('✅ Tutor created for user: ${currentUser.username}');
    return newTutor;
  }

  /// ================================
  /// CREATE SESSION
  /// ================================
  Future<void> createSession() async {
    if (!formKey.currentState!.validate()) return;

    if (subjectId.value.isEmpty) {
      Get.snackbar("Error", "Please select a subject");
      return;
    }

    isUploading.value = true;

    try {
      final currentUser = UserController.instance.currentUser.value;
      if (currentUser == null) {
        Get.snackbar("Error", "User not found");
        return;
      }

      // Ensure tutor exists
      final tutor = await getOrCreateTutor();

      // Fetch subject
      final subjects = await Amplify.DataStore.query(
        Subject.classType,
        where: Subject.ID.eq(subjectId.value),
      );

      if (subjects.isEmpty) {
        Get.snackbar("Error", "Subject not found");
        return;
      }

      final subject = subjects.first;

      // Use seeded thumbnail if subject is selected
      final thumbnailUrl = selectedThumbnail;

      // Create session object
      final session = TutoringSession(
        title: title.text.trim(),
        description: description.text.trim(),
        pricePerSession: double.tryParse(price.text.trim()) ?? 0,
        isFeatured: isFeatured.value,
        thumbnail: thumbnailUrl,
        tutor: tutor,
        subject: subject,
      );

      // Save session to DataStore
      await Amplify.DataStore.save(session);

      safePrint('✅ Session created: ${session.title}');

      // -----------------------------
      // REFRESH HOMESCREEN
      // -----------------------------
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();

        // Insert newly created session at top of recent sessions
        homeController.recentSessions.insert(0, session);

        // Optional: update getters to include this new session
        homeController.getAllSessions();

        safePrint('🏠 HomeController updated with new session');
      }

      Get.back();
      Get.snackbar("Success", "Session created successfully!");
    } catch (e, st) {
      safePrint('❌ Error creating session: $e\n$st');
      Get.snackbar("Error", "Failed to create session");
    } finally {
      isUploading.value = false;
    }
  }

  @override
  void onClose() {
    title.dispose();
    description.dispose();
    price.dispose();
    super.onClose();
  }
}
