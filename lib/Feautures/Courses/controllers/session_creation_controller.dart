// lib/Features/Sessions/controllers/session_creation_controller.dart
// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../../../../models/ModelProvider.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../checkout/controllers/paystack_card_controller.dart';
import '../../checkout/screens/paystack_card_entry_screen.dart';
import '../../dashboard/Home/controllers/home_controller.dart';

class SessionCreationController extends GetxController {
  static SessionCreationController get instance => Get.find();

  late GlobalKey<FormState> formKey;

  // ── Form fields ──────────────────────────────────────────────────
  late TextEditingController title;
  late TextEditingController description;
  late TextEditingController price;

  final subjectId = ''.obs;
  final isUploading = false.obs;
  final isFree = false.obs;

  static const double kMaxPriceNaira = 5000.0;

  static const Map<String, List<String>> _defaultAttributeOptions = {
    'Duration': ['1hr', '2hr'],
    'Mode': ['Online', 'Offline'],
    'Payment': ['Before Session', 'After Session'],
  };

  final RxSet<String> enabledAttributes = <String>{}.obs;
  final RxMap<String, String> selectedAttributes = <String, String>{}.obs;

  Tutor? _cachedTutor;

  @override
  void onInit() {
    super.onInit();
    formKey = GlobalKey<FormState>();
    title = TextEditingController();
    description = TextEditingController();
    price = TextEditingController();
    enabledAttributes.clear();
    selectedAttributes.clear();
  }

  // ── Attribute helpers ────────────────────────────────────────────

  List<String> get allAttributeKeys =>
      _defaultAttributeOptions.keys.toList(growable: false);

  List<String> optionsFor(String groupKey) =>
      _defaultAttributeOptions[groupKey] ?? [];

  void toggleAttributeGroup(String groupKey) {
    if (enabledAttributes.contains(groupKey)) {
      enabledAttributes.remove(groupKey);
      selectedAttributes.remove(groupKey);
    } else {
      enabledAttributes.add(groupKey);
      final options = optionsFor(groupKey);
      if (options.isNotEmpty) selectedAttributes[groupKey] = options.first;
    }
  }

  bool isGroupEnabled(String groupKey) => enabledAttributes.contains(groupKey);

  void onAttributeSelected(String groupKey, String value) {
    if (!enabledAttributes.contains(groupKey)) return;
    selectedAttributes[groupKey] = value;
  }

  String? getSelectedValue(String groupKey) {
    if (selectedAttributes.containsKey(groupKey)) {
      return selectedAttributes[groupKey];
    }
    final options = optionsFor(groupKey);
    return options.isNotEmpty ? options.first : null;
  }

  // ── Dynamic Pricing ──────────────────────────────────────────────

  double calculateDynamicPrice(TutoringSession session) {
    double adjusted = session.pricePerSession ?? 0;
    final mode = selectedAttributes['Mode'];
    final duration = selectedAttributes['Duration'];
    final payment = selectedAttributes['Payment'];
    if (mode == 'Offline') adjusted += adjusted * 0.10;
    if (duration == '2hr') adjusted *= 2;
    if (payment == 'After Session') adjusted += adjusted * 0.05;
    return adjusted;
  }

  // ── Thumbnail ────────────────────────────────────────────────────

  String? get selectedThumbnail =>
      subjectId.value.isNotEmpty ? _seededThumbnails[subjectId.value] : null;

  static const Map<String, String> _seededThumbnails = {
    '1':
        'https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/math-basics.png',
    '2':
        'https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/physics-intro.png',
    '3':
        'https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/chemistry-lab.png',
    '4':
        'https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/cs-101.png',
    '5':
        'https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/biology-101.png',
    '6':
        'https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/economics-101.png',
    '7':
        'https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/literature.png',
    '8':
        'https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/engineering.png',
    '9': 'https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/arts.png',
    '10':
        'https://p2p-tutoring-assets.s3.amazonaws.com/images/courses/others.png',
  };

  // ── Tutor resolution ─────────────────────────────────────────────

  Future<Tutor> getOrCreateTutor() async {
    if (_cachedTutor != null) return _cachedTutor!;

    final user = UserController.instance.currentUser.value;
    if (user == null) throw Exception('User not signed in');

    final byEmail = await Amplify.DataStore.query(
      Tutor.classType,
      where: Tutor.EMAIL.eq(user.email),
    );

    if (byEmail.isNotEmpty) {
      _cachedTutor = byEmail.first;
      return _cachedTutor!;
    }

    final newTutor = Tutor(
      name: user.username,
      email: user.email,
      about: (user.about?.isNotEmpty ?? false) ? user.about : null,
      skills: (user.skills?.isNotEmpty ?? false) ? user.skills! : [],
    );

    await Amplify.DataStore.save(newTutor);
    _cachedTutor = newTutor;
    return _cachedTutor!;
  }

  // ── Create Session ───────────────────────────────────────────────

  Future<void> createSession() async {
    // ✅ Card gate — only prompt ONCE if no card is saved yet.
    // PaystackCardController persists the card to SharedPreferences, so
    // once the tutor adds a card it's remembered across all future sessions.
    // We never re-prompt or re-navigate after a card already exists.
    final cardCtrl = Get.put(PaystackCardController());

    // Wait for the controller to finish loading from SharedPreferences.
    // isLoading is true briefly on first access — wait for it to settle.
    if (cardCtrl.isLoading.value) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return cardCtrl.isLoading.value;
      });
    }

    if (!cardCtrl.hasCard) {
      // ✅ Show a friendly one-time prompt explaining WHY a card is needed
      // before navigating to the card entry screen.
      final shouldAdd = await Get.dialog<bool>(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Payment Card',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Tutors need a card on file to receive payouts from students. '
            'You only need to do this once — your card is saved securely '
            'for all future sessions.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0BA4DB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Add Card'),
            ),
          ],
        ),
      );

      if (shouldAdd != true) return;

      // Navigate to card entry and wait for the user to return.
      await Get.to(() => const PaystackCardEntryScreen());

      // After returning, re-check. If the user skipped adding a card, abort.
      if (!cardCtrl.hasCard) {
        Get.snackbar(
          'Card Required',
          'Please add a payment card to create a session.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return;
      }
    }

    // ── Card exists — proceed with session creation ───────────────
    if (!formKey.currentState!.validate()) return;

    if (subjectId.value.isEmpty) {
      Get.snackbar('Error', 'Please select a subject');
      return;
    }

    isUploading.value = true;

    try {
      final tutor = await getOrCreateTutor();
      final sessionId = UUID.getUUID();
      final capturedSubjectId = subjectId.value;

      final priceVal =
          isFree.value ? 0.0 : double.tryParse(price.text.trim()) ?? 0.0;

      const mutationDoc = """
mutation CreateTutoringSession(\$input: CreateTutoringSessionInput!) {
  createTutoringSession(input: \$input) {
    id title description pricePerSession thumbnail
    tutorId subjectId isFeatured hasPaid createdAt updatedAt
  }
}
""";

      final variables = {
        'input': {
          'id': sessionId,
          'title': title.text.trim(),
          'description': description.text.trim(),
          'pricePerSession': priceVal,
          'thumbnail': selectedThumbnail,
          'tutorId': tutor.id,
          'subjectId': capturedSubjectId,
          'isFeatured': false,
          'hasPaid': false,
        },
      };

      final request = GraphQLRequest<String>(
        document: mutationDoc,
        variables: variables,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        safePrint('❌ GraphQL errors: ${response.errors}');
        Get.snackbar(
          'Error',
          'Failed to create session: ${response.errors.first.message}',
        );
        return;
      }

      safePrint('✅ Session created via GraphQL: $sessionId');

      // Save attributes
      for (final key in enabledAttributes) {
        final options = optionsFor(key);
        if (options.isEmpty) continue;

        final sessionRef = TutoringSession(
          id: sessionId,
          title: title.text.trim(),
        );

        final attr = SessionAttribute(
          name: key,
          values: options,
          session: sessionRef,
          tutorId: tutor.id,
        );

        await Amplify.DataStore.save(attr);
      }

      // Optimistic UI update
      if (Get.isRegistered<HomeController>()) {
        final subjects = await Amplify.DataStore.query(
          Subject.classType,
          where: Subject.ID.eq(capturedSubjectId),
        );

        final optimisticSession = TutoringSession(
          id: sessionId,
          title: title.text.trim(),
          description: description.text.trim(),
          pricePerSession: priceVal,
          thumbnail: selectedThumbnail,
          tutor: tutor,
          subject: subjects.isNotEmpty ? subjects.first : null,
        );

        final home = Get.find<HomeController>();
        home.warmSessionSubjectMap(sessionId, capturedSubjectId);
        home.warmTutorCache(tutor);
        home.allSessions.insert(0, optimisticSession);
        home.recentSessions.insert(0, optimisticSession);
      }

      Get.back();
      Get.snackbar('Success', 'Session created!');
    } catch (e, st) {
      safePrint('❌ Error creating session: $e\n$st');
      Get.snackbar('Error', 'Failed to create session');
    } finally {
      isUploading.value = false;
    }
  }

  // ── Detail Screen init ───────────────────────────────────────────

  void initializeAttributesForSession(Map<String, List<String>> attrs) {
    enabledAttributes.clear();
    selectedAttributes.clear();

    attrs.forEach((key, values) {
      if (values.isNotEmpty) {
        enabledAttributes.add(key);
        selectedAttributes[key] = values.first;
      }
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Map<String, String> get effectiveSelections =>
      Map<String, String>.from(selectedAttributes);

  void invalidateTutorCache() => _cachedTutor = null;

  @override
  void onClose() {
    title.dispose();
    description.dispose();
    price.dispose();
    super.onClose();
  }
}
