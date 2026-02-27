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

  // Form fields
  final title = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  final subjectId = ''.obs;

  final isFeatured = false.obs;
  final isUploading = false.obs;

  // Attributes
  final RxMap<String, List<String>> sessionAttributes =
      <String, List<String>>{}.obs;

  /// Track selected attribute values
  final RxMap<String, String> selectedAttributes = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();

    // Default session attributes
    sessionAttributes["Duration"] = ["1hr", "2hr"];
    sessionAttributes["Mode"] = ["Online", "Offline"];
    sessionAttributes["Payment"] = ["Before Session", "After Session"];

    // Set defaults for selected attributes
    sessionAttributes.forEach((key, values) {
      if (values.isNotEmpty) {
        selectedAttributes[key] = values.first;
      }
    });
  }

  /// Called when user selects a value for an attribute
  void onAttributeSelected(String name, String value) {
    selectedAttributes[name] = value;
  }

  String? get selectedThumbnail =>
      subjectId.value.isNotEmpty ? seededThumbnails[subjectId.value] : null;

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

  /// Fetch or create a tutor for the current user
  Future<Tutor> _getOrCreateTutor() async {
    final user = UserController.instance.currentUser.value;
    if (user == null) throw Exception("User not signed in");

    final tutors = await Amplify.DataStore.query(
      Tutor.classType,
      where: Tutor.NAME.eq(user.username),
    );

    if (tutors.isNotEmpty) return tutors.first;

    // Create a new tutor object
    final newTutor = Tutor(name: user.username, email: user.email);

    // Save the tutor (returns void)
    await Amplify.DataStore.save(newTutor);

    // Return the saved object manually
    return newTutor;
  }

  Future<void> createSession() async {
    if (!formKey.currentState!.validate()) return;
    if (subjectId.value.isEmpty) {
      Get.snackbar("Error", "Please select a subject");
      return;
    }

    isUploading.value = true;

    try {
      final tutor = await _getOrCreateTutor();

      final subjects = await Amplify.DataStore.query(
        Subject.classType,
        where: Subject.ID.eq(subjectId.value),
      );

      if (subjects.isEmpty) {
        Get.snackbar("Error", "Subject not found");
        isUploading.value = false;
        return;
      }

      final session = TutoringSession(
        title: title.text.trim(),
        description: description.text.trim(),
        pricePerSession: double.tryParse(price.text.trim()) ?? 0,
        isFeatured: isFeatured.value,
        thumbnail: selectedThumbnail,
        tutor: tutor,
        subject: subjects.first,
      );

      await Amplify.DataStore.save(session);

      // Save attributes
      final savedAttrs = <SessionAttribute>[];
      for (final e in sessionAttributes.entries) {
        final attr = SessionAttribute(
          name: e.key,
          values: e.value,
          session: session,
          tutorId: tutor.id,
        );
        await Amplify.DataStore.save(attr);
        savedAttrs.add(attr);
      }

      // Generate and save variations
      final combos = _generateCombinations(sessionAttributes);
      for (final combo in combos) {
        final variationAttrs = <SessionAttribute>[];
        for (final saved in savedAttrs) {
          if (combo.containsKey(saved.name)) {
            variationAttrs.add(
              SessionAttribute(
                name: saved.name,
                values: [combo[saved.name]!],
                session: session,
                tutorId: tutor.id,
              ),
            );
          }
        }

        await Amplify.DataStore.save(
          SessionVariation(
            session: session,
            tutorId: tutor.id,
            pricePerSession: double.tryParse(price.text.trim()) ?? 0,
            availableSeats: 10,
            sessionAttributes: variationAttrs,
          ),
        );
      }

      // Refresh HomeController
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.recentSessions.insert(0, session);
        homeController.getAllSessions();
      }

      Get.back();
      Get.snackbar("Success", "Session created!");
    } catch (e, st) {
      safePrint('❌ Error creating session: $e\n$st');
      Get.snackbar("Error", "Failed to create session");
    } finally {
      isUploading.value = false;
    }
  }

  /// -----------------------------
  /// Add this inside SessionCreationController
  /// -----------------------------
  void initializeAttributesForSession(Map<String, List<String>> attrs) {
    // Clear previous attributes
    sessionAttributes.clear();
    selectedAttributes.clear();

    // Assign new session-specific attributes
    sessionAttributes.addAll(attrs);

    // Set default selected value for each attribute
    attrs.forEach((key, values) {
      if (values.isNotEmpty) {
        selectedAttributes[key] = values.first;
      }
    });
  }

  List<Map<String, String>> _generateCombinations(
    Map<String, List<String>> map,
  ) {
    List<Map<String, String>> combos = [{}];
    map.forEach((key, values) {
      List<Map<String, String>> newList = [];
      for (var combo in combos) {
        for (var val in values) {
          newList.add({...combo, key: val});
        }
      }
      combos = newList;
    });
    return combos;
  }

  @override
  void onClose() {
    title.dispose();
    description.dispose();
    price.dispose();
    super.onClose();
  }
}
