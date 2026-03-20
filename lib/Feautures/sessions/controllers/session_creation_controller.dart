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
import '../../../../routes/routes.dart';

class SessionCreationController extends GetxController {
  static SessionCreationController get instance => Get.find();

  late GlobalKey<FormState> formKey;

  // ── Form fields ──────────────────────────────────────────────────
  late TextEditingController title;
  late TextEditingController description;
  late TextEditingController price;
  late TextEditingController maxStudents;

  final subjectId = ''.obs;
  final isUploading = false.obs;
  final isFree = false.obs;
  final hasStudentLimit = false.obs;

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
    maxStudents = TextEditingController();
    enabledAttributes.clear();
    selectedAttributes.clear();
  }

  @override
  void onClose() {
    title.dispose();
    description.dispose();
    price.dispose();
    maxStudents.dispose();
    super.onClose();
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
    final cardCtrl = Get.put(PaystackCardController());

    if (cardCtrl.isLoading.value) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return cardCtrl.isLoading.value;
      });
    }

    if (!cardCtrl.hasCard) {
      // ✅ Show polished bottom sheet instead of plain AlertDialog
      final shouldAdd = await _showCardRequiredSheet();
      if (shouldAdd != true) return;

      // Navigate to card entry screen and wait for return
      await Get.to(() => const PaystackCardEntryScreen());

      if (!cardCtrl.hasCard) {
        Get.snackbar(
          'Card Required',
          'Please add a payment card to create a session.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // ✅ Card just added — go to home and create session from there
      // so the tutor sees their new session land on the home screen live.
      await _createSessionData();
      Get.offAllNamed(TRoutes.mainDashboard);
      Get.snackbar(
        '🎉 Session Created!',
        'Your session is now live on the home screen.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF00C48C),
        colorText: Colors.white,
      );
      return;
    }

    // Card already on file — normal flow
    if (!formKey.currentState!.validate()) return;
    if (subjectId.value.isEmpty) {
      Get.snackbar('Error', 'Please select a subject');
      return;
    }

    isUploading.value = true;
    try {
      await _createSessionData();
      Get.back();
      Get.snackbar('✅ Session created!', 'Your session is now live.');
    } catch (e, st) {
      safePrint('❌ Error creating session: $e\n$st');
      Get.snackbar('Error', 'Failed to create session');
    } finally {
      isUploading.value = false;
    }
  }

  // ── Card Required Bottom Sheet ───────────────────────────────────

  /// Polished modal bottom sheet that explains WHY a card is needed.
  /// Returns true if the tutor taps "Add Card", false/null on dismiss.
  Future<bool?> _showCardRequiredSheet() {
    final context = Get.context;
    if (context == null) return Future.value(false);

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _CardRequiredSheet(),
    );
  }

  // ── Core session creation logic ──────────────────────────────────

  /// Extracted so it can be called from both the normal flow and the
  /// post-card-entry flow without duplicating code.
  Future<void> _createSessionData() async {
    if (!formKey.currentState!.validate()) {
      throw Exception('Form validation failed');
    }
    if (subjectId.value.isEmpty) {
      throw Exception('No subject selected');
    }

    isUploading.value = true;

    try {
      final tutor = await getOrCreateTutor();
      final sessionId = UUID.getUUID();
      final capturedSubjectId = subjectId.value;

      final priceVal =
          isFree.value ? 0.0 : double.tryParse(price.text.trim()) ?? 0.0;

      final int? maxStudentsVal =
          hasStudentLimit.value && maxStudents.text.trim().isNotEmpty
              ? int.tryParse(maxStudents.text.trim())
              : null;

      const mutationDoc = """
mutation CreateTutoringSession(\$input: CreateTutoringSessionInput!) {
  createTutoringSession(input: \$input) {
    id title description pricePerSession thumbnail
    tutorId subjectId isFeatured hasPaid
    maxStudents enrolledCount
    createdAt updatedAt
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
          if (maxStudentsVal != null) 'maxStudents': maxStudentsVal,
          'enrolledCount': 0,
        },
      };

      final response =
          await Amplify.API
              .mutate(
                request: GraphQLRequest<String>(
                  document: mutationDoc,
                  variables: variables,
                ),
              )
              .response;

      if (response.errors.isNotEmpty) {
        throw Exception(response.errors.first.message);
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
          maxStudents: maxStudentsVal,
          enrolledCount: 0,
        );

        final home = Get.find<HomeController>();
        home.warmSessionSubjectMap(sessionId, capturedSubjectId);
        home.warmTutorCache(tutor);
        home.allSessions.insert(0, optimisticSession);
        home.recentSessions.insert(0, optimisticSession);
      }
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
}

// =============================================================================
// Card Required Bottom Sheet
// =============================================================================

class _CardRequiredSheet extends StatelessWidget {
  const _CardRequiredSheet();

  static const _blue = Color(0xFF0BA4DB);
  static const _green = Color(0xFF00C48C);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.of(context).viewInsets.bottom + 36,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // ── Icon badge ───────────────────────────────────────────
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_blue, Color(0xFF0886B8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _blue.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),

          // ── Headline ─────────────────────────────────────────────
          Text(
            'One-time card setup',
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your card so you can receive payouts from students. '
            'This only needs to be done once.',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.55),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // ── Trust bullets ─────────────────────────────────────────
          _TrustRow(
            icon: Icons.lock_outline_rounded,
            color: _green,
            label: 'Stored securely — never shared',
          ),
          const SizedBox(height: 12),
          _TrustRow(
            icon: Icons.replay_rounded,
            color: _blue,
            label: 'Required once, remembered forever',
          ),
          const SizedBox(height: 12),
          _TrustRow(
            icon: Icons.flash_on_rounded,
            color: const Color(0xFFF59E0B),
            label: 'Your session goes live immediately after',
          ),
          const SizedBox(height: 32),

          // ── CTA ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.add_card_rounded, size: 20),
              label: const Text(
                'Add My Card',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Dismiss link ─────────────────────────────────────────
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Maybe later',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small trust row widget ────────────────────────────────────────────────────

class _TrustRow extends StatelessWidget {
  const _TrustRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}
