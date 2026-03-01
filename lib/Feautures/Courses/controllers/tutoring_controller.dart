// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'dart:io';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:path/path.dart' as p;
import '../../Booking/controllers/booking_controller.dart';
import '../../../../models/ModelProvider.dart';
import 'session_creation_controller.dart';

class TutoringController extends GetxController {
  // ---------------- Singleton ----------------
  static TutoringController get instance {
    if (Get.isRegistered<TutoringController>()) return Get.find();
    return Get.put(TutoringController());
  }

  // ---------------- Auth User ----------------
  Future<String?> get authUserId async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user.userId;
    } catch (_) {
      return null;
    }
  }

  // ---------------- Reactive State ----------------
  final sessions = <TutoringSession>[].obs;
  final featuredSessions = <TutoringSession>[].obs;
  final popularSessions = <TutoringSession>[].obs;

  final selectedAttributes = <String, String>{}.obs;
  final selectedSessionImage = ''.obs;

  final favorites = <String, RxBool>{}.obs;
  final isSynced = false.obs;

  final sessionMessages = <String, List<ChatMessage>>{}.obs;

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
    double price = session.pricePerSession ?? 0.0;

    // Adjust price for Duration
    final duration = attributes?['Duration']?.toLowerCase() ?? '';
    if (duration.contains('2hr') ||
        duration.contains('2 h') ||
        duration.contains('2h')) {
      price *= 2;
    }

    // Adjust price for Mode
    final mode = attributes?['Mode']?.toLowerCase() ?? '';
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

  void initializeSelectedAttributes(TutoringSession session) {
    selectedAttributes.clear();
    if (session.sessionAttributes?.isNotEmpty ?? false) {
      for (var attr in session.sessionAttributes!) {
        if (attr.values?.isNotEmpty ?? false) {
          selectedAttributes[attr.name] = attr.values!.first;
        }
      }
    }
    selectedAttributes.putIfAbsent('Duration', () => '1hr');
    selectedAttributes.putIfAbsent('Mode', () => 'Online');

    selectedSessionImage.value =
        session.images?.isNotEmpty == true
            ? session.images!.first
            : session.thumbnail ?? '';
  }

  // ---------------- Reactive Booking Helper ----------------
  Future<void> addSessionToBooking(
    TutoringSession session, {
    Map<String, String>? selectedAttributes,
    int quantity = 1,
    String? controllerTag, // optional tag to find the SessionCreationController
  }) async {
    // If we can't sync, just return
    if (!await _canSync()) return;

    final bookingController = BookingController.instance;

    // Ensure a booking exists
    Booking booking;
    if (bookingController.bookings.isNotEmpty) {
      booking = bookingController.bookings.first;
    } else {
      final created = await bookingController.createBooking(session: session);
      if (created == null) return;
      booking = created;
    }

    // Find the SessionCreationController to get dynamic price
    final tagToUse = controllerTag ?? session.id;
    final sessionController = Get.find<SessionCreationController>(
      tag: tagToUse,
    );

    // Calculate final dynamic price ONCE
    final double finalPrice = sessionController.calculateDynamicPrice(session);

    // Add booking item with the final price
    await bookingController.createBookingItem(
      booking: booking,
      sessionId: session.id,
      tutorId: session.tutor?.id,
      price: finalPrice, // <-- use finalPrice here
      quantity: quantity,
      serviceTitle: session.title,
      serviceImage: session.images?.first ?? session.thumbnail ?? '',
      providerName: session.tutor?.name ?? '',
      providerImage: session.tutor?.image ?? '',
      selectedAttributes: selectedAttributes,
      bookingDate: TemporalDateTime.now(),
    );

    // Close current screen
    Get.back();

    // Show confirmation
    Get.snackbar(
      "Added to Booking",
      "Session added with your selected options",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // ---------------- Favorites ----------------
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

  List<String> getAllSessionImages(TutoringSession session) {
    final List<String> images = [];
    if ((session.thumbnail?.isNotEmpty ?? false)) {
      images.add(session.thumbnail!);
    }
    if ((session.images?.isNotEmpty ?? false)) images.addAll(session.images!);
    return images;
  }

  List<Map<String, String>> generateCombinationsForUI(TutoringSession session) {
    List<Map<String, String>> combos = [{}];
    session.sessionAttributes?.forEach((attr) {
      final values = attr.values ?? [];
      List<Map<String, String>> newList = [];
      for (var combo in combos) {
        for (var val in values) {
          newList.add({...combo, attr.name: val});
        }
      }
      combos = newList;
    });
    return combos;
  }

  // ---------------- Sale Calculation ----------------
  int calculateSalePercentage(double originalPrice, double? discountedPrice) {
    if (discountedPrice == null || discountedPrice >= originalPrice) return 0;
    return ((1 - (discountedPrice / originalPrice)) * 100).round();
  }

  // ---------------- Compute Price Based on Selected Attributes ----------------
  double computeSelectedAttributesPrice() {
    // Use the currently selected session
    if (sessions.isEmpty) return 0.0;

    // Pick session based on selectedSessionImage or fallback to first
    final session = sessions.firstWhere(
      (s) => s.id == selectedSessionImage.value,
      orElse: () => sessions.first,
    );

    return _computeAdjustedPrice(session, selectedAttributes);
  }

  // ---------------- Reviews ----------------
  Future<Review> addReview({
    required TutoringSession session,
    required double rating,
    required String comment,
  }) async {
    if (!await _canSync()) throw Exception("User not signed in");
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      final userList = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(authUser.userId),
      );
      final currentUser = userList.first;

      final tutorList = await Amplify.DataStore.query(
        Tutor.classType,
        where: Tutor.ID.eq(session.tutor!.id),
      );
      final currentTutor = tutorList.first;

      final review = Review(
        user: currentUser,
        sessionId: session.id,
        tutor: currentTutor,
        rating: rating,
        comment: comment,
        createdAt: TemporalDateTime.now(),
      );

      await Amplify.DataStore.save(review);
      return review;
    } catch (e) {
      print('❌ Error adding review for session ${session.id}: $e');
      rethrow;
    }
  }

  Future<List<Review>> fetchReviews(String sessionId) async {
    if (!await _canSync()) return [];
    try {
      final reviews = await Amplify.DataStore.query(
        Review.classType,
        where: Review.SESSIONID.eq(sessionId),
      );
      return reviews.where((r) => r.createdAt != null).toList();
    } catch (e) {
      print('❌ Error fetching reviews for session $sessionId: $e');
      return [];
    }
  }

  Future<List<Review>> addReviewAndFetch({
    required TutoringSession session,
    required double rating,
    required String comment,
  }) async {
    final newReview = await addReview(
      session: session,
      rating: rating,
      comment: comment,
    );
    print(
      '✅ Review created at (UTC): ${newReview.createdAt!.getDateTimeInUtc()}',
    );
    return await fetchReviews(session.id);
  }

  Future<List<Review>> fetchReviewsByTutor(String tutorId) async {
    try {
      final reviews = await Amplify.DataStore.query(
        Review.classType,
        where: Review.TUTOR.eq(tutorId),
      );
      return reviews;
    } catch (e) {
      print("❌ Error fetching reviews for tutor $tutorId: $e");
      return [];
    }
  }

  // ---------------- Chat ----------------
  Future<void> sendMessage(String sessionId, String text) async {
    if (!await _canSync()) return;

    final authUser = await Amplify.Auth.getCurrentUser();
    final userId = authUser.userId;
    if (userId == null) return;

    final message = ChatMessage(
      sessionId: sessionId,
      senderId: userId,
      text: text,
      isVoice: false,
      createdAt: TemporalDateTime.now(),
    );

    await Amplify.DataStore.save(message);
  }

  Future<void> sendVoiceMessage(String sessionId, File audioFile) async {
    if (!await _canSync()) return;

    final authUser = await Amplify.Auth.getCurrentUser();
    final userId = authUser.userId;
    if (userId == null) return;

    final key =
        'chat/$sessionId/${DateTime.now().millisecondsSinceEpoch}${p.extension(audioFile.path)}';

    try {
      final uploadResult =
          await Amplify.Storage.uploadFile(
            localFile: AWSFile.fromPath(audioFile.path),
            path: StoragePath.fromString(key),
          ).result;

      final urlResult =
          await Amplify.Storage.getUrl(
            path: StoragePath.fromString(uploadResult.uploadedItem.path),
          ).result;
      final presignedUrl = urlResult.url.toString();

      final message = ChatMessage(
        sessionId: sessionId,
        senderId: userId,
        text: null,
        audioUrl: presignedUrl,
        isVoice: true,
        createdAt: TemporalDateTime.now(),
      );

      await Amplify.DataStore.save(message);

      sessionMessages.update(
        sessionId,
        (list) => list..add(message),
        ifAbsent: () => [message],
      );
    } on StorageException catch (e) {
      print('❌ S3 Upload or URL failed: ${e.message}');
    }
  }

  void observeChat(String sessionId) {
    Amplify.DataStore.observeQuery(
      ChatMessage.classType,
      where: ChatMessage.SESSIONID.eq(sessionId),
    ).listen((snapshot) {
      final msgs = snapshot.items.whereType<ChatMessage>().toList();
      msgs.sort(
        (a, b) => (a.createdAt?.getDateTimeInUtc() ?? DateTime.now()).compareTo(
          b.createdAt?.getDateTimeInUtc() ?? DateTime.now(),
        ),
      );
      sessionMessages[sessionId] = msgs;
    });
  }
}
