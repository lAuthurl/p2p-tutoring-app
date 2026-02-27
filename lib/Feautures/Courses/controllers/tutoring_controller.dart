// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../Booking/controllers/booking_controller.dart';
import '../../../../models/ModelProvider.dart';

class TutoringController extends GetxController {
  // ---------------- Singleton ----------------
  static TutoringController get instance {
    if (Get.isRegistered<TutoringController>()) return Get.find();
    return Get.put(TutoringController());
  }

  int? calculateSalePercentage(double originalPrice, double? salePrice) {
    if (salePrice == null || salePrice >= originalPrice || originalPrice == 0) {
      return null;
    }
    final percent = ((originalPrice - salePrice) / originalPrice * 100).round();
    return percent > 0 ? percent : null;
  }

  // ---------------- Reactive State ----------------
  final sessions = <TutoringSession>[].obs;
  final RxList<TutoringSession> featuredSessions = <TutoringSession>[].obs;
  final RxList<TutoringSession> popularSessions = <TutoringSession>[].obs;

  RxInt selectedQuantity = 0.obs;
  RxMap<String, String> selectedAttributes = <String, String>{}.obs;

  Rx<SessionVariation> selectedVariation =
      SessionVariation(
        availableSeats: 0,
        pricePerSession: 0,
        lectureTime: TemporalDateTime(DateTime.now()),
        sessionAttributes: null,
        id: '',
        tutorId: '',
      ).obs;

  RxString variationStockStatus = ''.obs;
  RxString selectedSessionImage = ''.obs;

  final favorites = <String, RxBool>{}.obs;
  RxBool isSynced = false.obs;

  // ---------------- Lifecycle ----------------
  @override
  void onInit() {
    super.onInit();
    _observeSessions();
  }

  // ---------------- Helper: Check if user can sync ----------------
  Future<bool> _canSync() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user != null;
    } catch (_) {
      print('⚠️ User not signed in, skipping DataStore operations');
      return false;
    }
  }

  // ---------------- AWS DataStore Observers ----------------
  void _observeSessions() async {
    if (!await _canSync()) return;
    try {
      Amplify.DataStore.observeQuery(TutoringSession.classType).listen((
        snapshot,
      ) {
        final awsSessions =
            snapshot.items.whereType<TutoringSession>().toList();
        if (awsSessions.isNotEmpty) _mergeSessions(awsSessions);
        isSynced.value = snapshot.isSynced;
      }, onError: (e) => print('❌ Error observing sessions: $e'));
    } catch (e) {
      print('❌ Failed to start observeQuery: $e');
    }
  }

  void _mergeSessions(List<TutoringSession> newSessions) {
    sessions.assignAll(newSessions);
    featuredSessions.assignAll(
      sessions.where((s) => s.isFeatured == true).toList(),
    );
    popularSessions.assignAll(
      sessions.length > 4 ? sessions.sublist(0, 4) : sessions.toList(),
    );
  }

  Future<void> fetchSessions() async {
    if (!await _canSync()) return;
    try {
      final sessionsResponse = await Amplify.DataStore.query(
        TutoringSession.classType,
      );
      if (sessionsResponse.isEmpty) return;
      _mergeSessions(sessionsResponse);
    } catch (e) {
      print('❌ Error fetching sessions: $e');
    }
  }

  // ---------------- Session Utilities ----------------
  double _computeAdjustedPrice(
    TutoringSession session,
    Map<String, String>? attributes,
  ) {
    double price = session.pricePerSession ?? 0;

    final variation = selectedVariation.value;
    if ((session.sessionVariations?.isNotEmpty ?? false) &&
        variation.id.isNotEmpty) {
      final v = session.sessionVariations!.firstWhere(
        (v) => v.id == variation.id,
        orElse: () => variation,
      );
      price = v.pricePerSession ?? price;
    }

    final duration = (attributes?['Duration'] ?? '').toLowerCase();
    if (duration.contains('2hr') ||
        duration.contains('2 h') ||
        duration.contains('2h')) {
      price *= 2;
    }

    final mode = (attributes?['Mode'] ?? '').toLowerCase();
    if (mode.contains('in-person') ||
        mode.contains('offline') ||
        mode.contains('physical')) {
      price *= 1.2;
    }

    return price;
  }

  String getSessionPrice(TutoringSession session) {
    final price = _computeAdjustedPrice(session, selectedAttributes);
    return price % 1 == 0 ? price.toStringAsFixed(0) : price.toStringAsFixed(2);
  }

  void initializeAlreadySelectedQuantity(TutoringSession session) {
    selectedAttributes.clear();

    selectedVariation.value = SessionVariation(
      availableSeats: 0,
      pricePerSession: 0,
      lectureTime: TemporalDateTime(DateTime.now()),
      sessionAttributes: null,
      id: '',
      tutorId: session.tutor?.id ?? '',
    );

    selectedSessionImage.value =
        (session.images?.isNotEmpty ?? false)
            ? session.images!.first
            : session.thumbnail ?? '';

    initializeDefaultAttributes(session);
  }

  /// ---------------- Core: Book Session ----------------
  Future<void> addSessionToBooking(
    TutoringSession session, {
    Map<String, String>? selectedAttributes,
  }) async {
    if (!await _canSync()) {
      Get.snackbar('Error', 'Cannot book session: not signed in.');
      return;
    }

    final variation = selectedVariation.value;

    // Ensure a variation is selected if the session has variations
    if ((session.sessionVariations?.isNotEmpty ?? false) &&
        variation.id.isEmpty) {
      Get.snackbar(
        'Selection required',
        'Please select a variation before booking.',
      );
      return;
    }

    // Resolve image
    String serviceImage = '';
    if ((session.images?.isNotEmpty ?? false)) {
      serviceImage = session.images!.first;
    } else if ((session.thumbnail?.isNotEmpty ?? false)) {
      serviceImage = session.thumbnail!;
    } else if ((variation.image?.isNotEmpty ?? false)) {
      serviceImage = variation.image!;
    }

    // Compute price with selected attributes
    final adjustedPrice = _computeAdjustedPrice(session, selectedAttributes);

    // Add booking item
    BookingController.instance.addBookingItem(
      sessionId: session.id,
      tutorId: session.tutor?.id ?? '',
      bookingDate:
          variation.lectureTime?.getDateTimeInUtc().toLocal() ?? DateTime.now(),
      timeSlot: variation.id,
      price: adjustedPrice,
      serviceTitle: session.title,
      serviceImage: serviceImage,
      tutorName: session.tutor?.name ?? '',
      tutorImage: session.tutor?.image ?? '',
      session: session,
      selectedAttributes: selectedAttributes,
    );

    Get.back();
    Get.snackbar(
      "Added to Booking",
      "Session added with your selected options",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  bool isFavourite(String sessionId) => favorites[sessionId]?.value ?? false;

  void toggleFavoriteSession(String sessionId) {
    if (!favorites.containsKey(sessionId)) {
      favorites[sessionId] = true.obs;
    } else {
      favorites[sessionId]!.value = !favorites[sessionId]!.value;
    }
  }

  List<TutoringSession> favoriteSessions() =>
      sessions.where((s) => isFavourite(s.id)).toList();

  List<String> getAttributesAvailabilityInVariation(
    List<SessionVariation> variations,
    String attributeName,
  ) {
    final lowerAttr = attributeName.toLowerCase();
    final values = <String>{};

    for (final v in variations) {
      final attrs = v.sessionAttributes;
      if (attrs != null) {
        for (final attr in attrs) {
          if (attr.name.toLowerCase() == lowerAttr &&
              (attr.values?.isNotEmpty ?? false)) {
            values.addAll(attr.values!);
          }
        }
      }
    }

    return values.toList();
  }

  void onAttributeSelected(String attributeName, String value) {
    selectedAttributes[attributeName] = value;
    update();
  }

  List<String> getAllSessionImages(TutoringSession session) {
    final List<String> images = [];
    if ((session.thumbnail?.isNotEmpty ?? false)) {
      images.add(session.thumbnail!);
    }
    if ((session.images?.isNotEmpty ?? false)) images.addAll(session.images!);
    return images;
  }
}

/// ---------------- Extension ----------------
extension TutoringControllerExtensions on TutoringController {
  /// Initialize default attributes for a given session
  void initializeDefaultAttributes(TutoringSession session) {
    selectedAttributes.clear();

    final variations = session.sessionVariations ?? [];
    if (variations.isNotEmpty) {
      final firstVariation = variations.first;

      if (firstVariation.sessionAttributes != null) {
        for (var attr in firstVariation.sessionAttributes!) {
          if (attr.values?.isNotEmpty ?? false) {
            selectedAttributes[attr.name] = attr.values!.first;
          }
        }
      }

      selectedAttributes.putIfAbsent('Duration', () {
        final durationAttr =
            firstVariation.sessionAttributes
                ?.firstWhere(
                  (a) =>
                      a.name.toLowerCase() == 'duration' &&
                      (a.values?.isNotEmpty ?? false),
                  orElse:
                      () => SessionAttribute(
                        tutorId: session.tutor?.id ?? '',
                        name: 'Duration',
                        values: ['1hr'],
                        session: session,
                        id: '',
                      ),
                )
                .values
                ?.first;
        return durationAttr ?? '1hr';
      });

      selectedAttributes.putIfAbsent('Mode', () {
        final modeAttr =
            firstVariation.sessionAttributes
                ?.firstWhere(
                  (a) =>
                      a.name.toLowerCase() == 'mode' &&
                      (a.values?.isNotEmpty ?? false),
                  orElse:
                      () => SessionAttribute(
                        tutorId: session.tutor?.id ?? '',
                        name: 'Mode',
                        values: ['Online'],
                        session: session,
                        id: '',
                      ),
                )
                .values
                ?.first;
        return modeAttr ?? 'Online';
      });
    } else {
      selectedAttributes['Duration'] = '1hr';
      selectedAttributes['Mode'] = 'Online';
    }

    update();
  }
}
