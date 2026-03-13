// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../models/ModelProvider.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../dashboard/Home/controllers/home_controller.dart';

class SessionCreationController extends GetxController {
  static SessionCreationController get instance => Get.find();

  // ✅ Fresh GlobalKey on every onInit — prevents "Multiple widgets used the
  //    same GlobalKey" errors after logout/re-login
  late GlobalKey<FormState> formKey;

  // ---------------- Form fields ----------------
  late TextEditingController title;
  late TextEditingController description;
  late TextEditingController price;

  final subjectId = ''.obs;
  final isUploading = false.obs;
  final isFree = false.obs;

  /// Maximum allowed session price in Naira (₦)
  static const double kMaxPriceNaira = 5000.0;

  // ─────────────────────────────────────────────────────────────────
  // Attribute model
  //
  // • [_defaultAttributeOptions] — the full catalogue of attribute
  //   groups and their possible values. Never changes at runtime.
  //
  // • [enabledAttributes] — set of attribute-group keys the TUTOR
  //   has toggled ON when creating the session.  Only enabled groups
  //   are saved to DataStore and shown to tutees on the detail page.
  //
  // • [selectedAttributes] — single-value selection per group used
  //   by the TUTEE on the detail page (and for dynamic pricing).
  //   Defaults to the first value of each enabled group.
  // ─────────────────────────────────────────────────────────────────

  static const Map<String, List<String>> _defaultAttributeOptions = {
    'Duration': ['1hr', '2hr'],
    'Mode': ['Online', 'Offline'],
    'Payment': ['Before Session', 'After Session'],
  };

  /// Which attribute groups the tutor has enabled for this session.
  final RxSet<String> enabledAttributes = <String>{}.obs;

  /// The tutee's single-value selection per group (used on detail screen).
  /// Automatically seeded with [values.first] when a group is enabled.
  final RxMap<String, String> selectedAttributes = <String, String>{}.obs;

  // ✅ Cache the resolved tutor so getOrCreateTutor() only hits DataStore once
  Tutor? _cachedTutor;

  @override
  void onInit() {
    super.onInit();

    formKey = GlobalKey<FormState>();
    title = TextEditingController();
    description = TextEditingController();
    price = TextEditingController();

    // Start with nothing enabled — tutor explicitly enables what they offer
    enabledAttributes.clear();
    selectedAttributes.clear();
  }

  // ─────────────────────────────────────────────────────────────────
  // Tutor-side: enabling / disabling attribute groups
  // ─────────────────────────────────────────────────────────────────

  /// All possible attribute group keys.
  List<String> get allAttributeKeys =>
      _defaultAttributeOptions.keys.toList(growable: false);

  /// The possible values for [groupKey].
  List<String> optionsFor(String groupKey) =>
      _defaultAttributeOptions[groupKey] ?? [];

  /// Toggles a whole attribute group on or off.
  /// When enabled, [selectedAttributes] is seeded with the first value
  /// so dynamic pricing and the detail page always have a valid default.
  void toggleAttributeGroup(String groupKey) {
    if (enabledAttributes.contains(groupKey)) {
      enabledAttributes.remove(groupKey);
      selectedAttributes.remove(groupKey);
    } else {
      enabledAttributes.add(groupKey);
      final options = optionsFor(groupKey);
      if (options.isNotEmpty) {
        selectedAttributes[groupKey] = options.first;
      }
    }
  }

  bool isGroupEnabled(String groupKey) => enabledAttributes.contains(groupKey);

  // ─────────────────────────────────────────────────────────────────
  // Tutee-side: picking a value within an enabled group
  // ─────────────────────────────────────────────────────────────────

  /// Called when the tutee selects [value] for [groupKey] on the detail page.
  void onAttributeSelected(String groupKey, String value) {
    if (!enabledAttributes.contains(groupKey)) return;
    selectedAttributes[groupKey] = value;
  }

  /// Returns the tutee's current selection for [groupKey],
  /// falling back to the first available option if nothing is set.
  String? getSelectedValue(String groupKey) {
    if (selectedAttributes.containsKey(groupKey)) {
      return selectedAttributes[groupKey];
    }
    final options = optionsFor(groupKey);
    return options.isNotEmpty ? options.first : null;
  }

  // ─────────────────────────────────────────────────────────────────
  // Dynamic pricing
  // ─────────────────────────────────────────────────────────────────

  /// Calculates the adjusted price based on the tutee's current selections
  /// across enabled attribute groups.
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

  // ─────────────────────────────────────────────────────────────────
  // Thumbnail
  // ─────────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────────
  // Tutor resolution
  // ─────────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────────
  // Create session
  // ─────────────────────────────────────────────────────────────────

  Future<void> createSession() async {
    if (!formKey.currentState!.validate()) return;
    if (subjectId.value.isEmpty) {
      Get.snackbar('Error', 'Please select a subject');
      return;
    }

    isUploading.value = true;

    try {
      final tutor = await getOrCreateTutor();

      final subjects = await Amplify.DataStore.query(
        Subject.classType,
        where: Subject.ID.eq(subjectId.value),
      );
      if (subjects.isEmpty) {
        Get.snackbar('Error', 'Subject not found');
        return;
      }

      final session = TutoringSession(
        title: title.text.trim(),
        description: description.text.trim(),
        pricePerSession:
            isFree.value ? 0 : (double.tryParse(price.text.trim()) ?? 0),
        thumbnail: selectedThumbnail,
        tutor: tutor,
        subject: subjects.first,
      );

      await Amplify.DataStore.save(session);

      // Only save SessionAttribute records for groups the tutor enabled.
      // Each record stores the full list of options for that group so the
      // tutee can pick from them on the detail page.
      for (final key in enabledAttributes) {
        final options = optionsFor(key);
        if (options.isEmpty) continue;
        final attr = SessionAttribute(
          name: key,
          values: options,
          session: session,
          tutorId: tutor.id,
        );
        await Amplify.DataStore.save(attr);
      }

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().recentSessions.insert(0, session);
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

  // ─────────────────────────────────────────────────────────────────
  // Detail-screen initialisation
  //
  // Called by SessionDetailScreen._initializeAttributes().
  // Populates [enabledAttributes] and [selectedAttributes] from the
  // SessionAttribute records already saved in DataStore so the tutee
  // sees only what the tutor enabled, defaulting to the first option.
  // ─────────────────────────────────────────────────────────────────

  void initializeAttributesForSession(Map<String, List<String>> attrs) {
    enabledAttributes.clear();
    selectedAttributes.clear();

    attrs.forEach((key, values) {
      if (values.isNotEmpty) {
        enabledAttributes.add(key);
        // Default to the first value (tutee can change later)
        selectedAttributes[key] = values.first;
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────

  /// Flat list of every enabled-group + value combination. Used by
  /// booking logic that needs a concrete attribute map.
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
