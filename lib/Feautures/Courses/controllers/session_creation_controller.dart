// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../../../../models/ModelProvider.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../dashboard/Home/controllers/home_controller.dart';

class SessionCreationController extends GetxController {
  static SessionCreationController get instance => Get.find();

  late GlobalKey<FormState> formKey;

  // ---------------- Form fields ----------------
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

  // ─────────────────────────────────────────────
  // Attribute Groups
  // ─────────────────────────────────────────────

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

  // ─────────────────────────────────────────────
  // Dynamic Pricing
  // ─────────────────────────────────────────────

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

  // ─────────────────────────────────────────────
  // Thumbnail
  // ─────────────────────────────────────────────

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

  // ─────────────────────────────────────────────
  // Tutor Resolution
  // ─────────────────────────────────────────────

  Future<Tutor> getOrCreateTutor() async {
    if (_cachedTutor != null) return _cachedTutor!;

    final user = UserController.instance.currentUser.value;

    if (user == null) {
      throw Exception('User not signed in');
    }

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

  // ─────────────────────────────────────────────
  // Create Session
  // ─────────────────────────────────────────────

  Future<void> createSession() async {
    if (!formKey.currentState!.validate()) return;

    if (subjectId.value.isEmpty) {
      Get.snackbar('Error', 'Please select a subject');
      return;
    }

    isUploading.value = true;

    try {
      final tutor = await getOrCreateTutor();
      final sessionId = UUID.getUUID();

      final priceVal =
          isFree.value ? 0.0 : double.tryParse(price.text.trim()) ?? 0.0;

      final mutationDoc = """
mutation CreateTutoringSession(\$input: CreateTutoringSessionInput!) {
  createTutoringSession(input: \$input) {
    id
    title
    description
    pricePerSession
    thumbnail
    tutorId
    subjectId
    isFeatured
    hasPaid
    createdAt
    updatedAt
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
          'subjectId': subjectId.value,
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
          where: Subject.ID.eq(subjectId.value),
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

  // ─────────────────────────────────────────────
  // Detail Screen Initialization
  // ─────────────────────────────────────────────

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

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

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
