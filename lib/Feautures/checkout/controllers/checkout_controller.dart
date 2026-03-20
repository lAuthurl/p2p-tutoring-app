// lib/Features/checkout/controllers/checkout_controller.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:ui' as ui;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'dart:io';

import '../../../../models/ModelProvider.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../booking/controllers/booking_controller.dart';
import '../../sessions/controllers/tutoring_controller.dart';
import '../../favourites/controllers/favorites_controller.dart';
import '../../dashboard/Home/controllers/home_controller.dart';
import '../models/paystack_card_model.dart';
import 'paystack_card_controller.dart';
import '../screens/paystack_card_entry_screen.dart';

class CheckoutController extends GetxController {
  static CheckoutController get instance => Get.find();

  final isProcessing = false.obs;
  final paymentSuccess = false.obs;

  static const Color _paystackBlue = Color(0xFF0BA4DB);
  static const Color _successGreen = Color(0xFF00C48C);

  Future<void> processPaystackPayment(BuildContext context) async {
    final cardCtrl = Get.put(PaystackCardController());

    if (!cardCtrl.hasCard) {
      await Get.to(() => const PaystackCardEntryScreen());
      if (!cardCtrl.hasCard) {
        Get.snackbar(
          'Card Required',
          'Please add a payment card to continue',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    final bookingCtrl = BookingController.instance;
    final totalPrice = bookingCtrl.totalBookingPrice.value;

    if (totalPrice <= 0 && bookingCtrl.bookingItems.isEmpty) {
      Get.snackbar(
        'Empty Booking',
        'Add sessions before checking out',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isProcessing.value = true;
    _showProcessingDialog(context, cardCtrl.savedCard.value, totalPrice);

    try {
      await Future.delayed(const Duration(milliseconds: 1600));

      final ref = 'PSK_${DateTime.now().millisecondsSinceEpoch}';

      await _persistPaymentRecords(bookingCtrl, totalPrice, ref);

      paymentSuccess.value = true;
      isProcessing.value = false;

      if (Navigator.canPop(context)) Get.back();
      _showSuccessDialog(context, totalPrice, ref);
    } catch (e, st) {
      isProcessing.value = false;
      if (Navigator.canPop(context)) Get.back();
      safePrint('❌ CheckoutController.processPaystackPayment error: $e\n$st');
      Get.snackbar(
        'Payment Failed',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // =========================================================================
  // PERSIST PAYMENT
  // =========================================================================

  Future<void> _persistPaymentRecords(
    BookingController bookingCtrl,
    double total,
    String ref,
  ) async {
    final userId = UserController.instance.currentUser.value?.id;
    if (userId == null) throw Exception('User not authenticated');

    final items = List<BookingItem>.from(bookingCtrl.bookingItems);

    for (final item in items) {
      await _updateBookingItemPaid(item);

      if (item.sessionId != null) {
        await _upsertUserSessionPayment(
          userId: userId,
          sessionId: item.sessionId!,
          total: total,
          ref: ref,
        );

        await _autoFavoriteSession(item.sessionId!);
        await _incrementEnrolledCount(item.sessionId!);

        await _sendBookingConfirmationMessage(
          item: item,
          userId: userId,
          totalPaid: total,
          ref: ref,
        );
      }
    }

    await bookingCtrl.clearBooking();
  }

  // =========================================================================
  // AUTO-FAVORITE
  // =========================================================================

  Future<void> _autoFavoriteSession(String sessionId) async {
    try {
      final favCtrl =
          Get.isRegistered<FavoritesController>()
              ? FavoritesController.instance
              : Get.put(FavoritesController(), permanent: true);

      if (!favCtrl.isFavourite(sessionId)) {
        await favCtrl.toggleFavorite(sessionId);
        safePrint('✅ CheckoutController: session $sessionId auto-favorited');
      }
    } catch (e) {
      safePrint('⚠️ CheckoutController._autoFavoriteSession: $e');
    }
  }

  // =========================================================================
  // INCREMENT ENROLLED COUNT
  // =========================================================================

  Future<void> _incrementEnrolledCount(String sessionId) async {
    try {
      if (Get.isRegistered<HomeController>()) {
        await HomeController.instance.incrementEnrolledCount(sessionId);
      }
    } catch (e) {
      safePrint('⚠️ CheckoutController._incrementEnrolledCount: $e');
    }
  }

  // =========================================================================
  // QR CODE HELPERS
  // =========================================================================

  bool _isPhysicalSession(Map<String, dynamic> attrs) {
    final mode =
        (attrs['Mode'] ?? attrs['mode'] ?? '').toString().toLowerCase();
    final location =
        (attrs['Location'] ?? attrs['location'] ?? '').toString().toLowerCase();
    final type =
        (attrs['Type'] ?? attrs['type'] ?? '').toString().toLowerCase();
    return mode.contains('offline') ||
        mode.contains('physical') ||
        mode.contains('in-person') ||
        location.contains('physical') ||
        type.contains('physical');
  }

  String _buildQrPayload({
    required String sessionId,
    required String bookingRef,
    required String sessionTitle,
    required String studentName,
    required String tutorName,
    required Map<String, dynamic> attrs,
    required double amountPaid,
  }) {
    final payload = {
      'type': 'TUTORLINK_BOOKING',
      'sessionId': sessionId,
      'ref': bookingRef,
      'session': sessionTitle,
      'student': studentName,
      'tutor': tutorName,
      'attrs': attrs,
      'paid': amountPaid,
      'ts': DateTime.now().toUtc().toIso8601String(),
    };
    return jsonEncode(payload);
  }

  // =========================================================================
  // ✅ FIXED: renders a clean centered QR code on a white card — no clutter
  // =========================================================================
  Future<File?> _renderQrToFile({
    required String qrData,
    required String ref,
  }) async {
    try {
      const double cardSize = 900;
      const double pixelRatio = 3.0;
      const double qrSize = 600;
      const double padding = (cardSize - qrSize) / 2;
      const double cornerRadius = 48.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        const Rect.fromLTWH(0, 0, cardSize, cardSize),
      );

      // ── White card background ──────────────────────────────────────────
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, cardSize, cardSize),
          const Radius.circular(cornerRadius),
        ),
        bgPaint,
      );

      // ── Centered QR code ───────────────────────────────────────────────
      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF1A1A2E),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF1A1A2E),
        ),
      );

      canvas.save();
      canvas.translate(padding, padding);
      qrPainter.paint(canvas, const Size(qrSize, qrSize));
      canvas.restore();

      // ── Finalise ───────────────────────────────────────────────────────
      final picture = recorder.endRecording();
      final img = await picture.toImage(
        (cardSize * pixelRatio).toInt(),
        (cardSize * pixelRatio).toInt(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/booking_qr_${ref.replaceAll('_', '')}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (e, st) {
      safePrint('⚠️ _renderQrToFile error: $e\n$st');
      return null;
    }
  }

  // =========================================================================
  // ✅ FIXED: QR sent only to the purchasing student's chat thread
  // =========================================================================
  Future<void> _sendQrCode({
    required String sessionId,
    required String studentUserId,
    required String qrData,
    required String sessionTitle,
    required String ref,
  }) async {
    try {
      final qrFile = await _renderQrToFile(qrData: qrData, ref: ref);

      if (qrFile == null) {
        safePrint('⚠️ _sendQrCode: QR render failed, skipping');
        return;
      }

      // ✅ Show download sheet ONLY to the student (purchaser)
      if (Get.context != null) {
        await _showQrDownloadSheet(
          context: Get.context!,
          qrFile: qrFile,
          sessionTitle: sessionTitle,
          ref: ref,
        );
      }

      // ✅ Send QR notice ONLY to student's own chat thread
      final studentChatId = '${sessionId}_$studentUserId';
      const qrNotice =
          '📍 Physical Session QR Code\n\n'
          'A verification QR code has been generated for this booking. '
          'Show it at the start of your session for instant verification.\n\n'
          '🔒 Ref: ';

      if (Get.isRegistered<TutoringController>()) {
        await TutoringController.instance.sendMessage(
          studentChatId,
          '$qrNotice$ref',
        );
      }

      safePrint(
        '✅ QR code notice sent to student $studentUserId for session $sessionId',
      );
    } catch (e) {
      safePrint('⚠️ _sendQrCode error: $e');
    }
  }

  Future<void> _showQrDownloadSheet({
    required BuildContext context,
    required File qrFile,
    required String sessionTitle,
    required String ref,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _QrDownloadSheet(
            qrFile: qrFile,
            sessionTitle: sessionTitle,
            ref: ref,
          ),
    );
  }

  // =========================================================================
  // AUTO CHAT MESSAGE
  // =========================================================================

  Future<void> _sendBookingConfirmationMessage({
    required BookingItem item,
    required String userId,
    required double totalPaid,
    required String ref,
  }) async {
    try {
      final sessionId = item.sessionId;
      if (sessionId == null) return;

      // ✅ Student-only chat thread
      final chatId = '${sessionId}_$userId';

      final currentUser = UserController.instance.currentUser.value;
      final studentName =
          (currentUser?.username.isNotEmpty ?? false)
              ? currentUser!.username
              : 'Student';

      final attrsJson = item.selectedAttributes;
      final Map<String, dynamic> attrs =
          (attrsJson != null && attrsJson.isNotEmpty)
              ? (jsonDecode(attrsJson) as Map<String, dynamic>)
              : {};

      final attrLines = attrs.entries
          .map((e) => '  • ${e.key}: ${e.value}')
          .join('\n');

      final sessionTitle = item.serviceTitle ?? 'Session';
      final tutorName = item.providerName ?? 'Tutor';

      final messageText = [
        '📋 New Booking Confirmed',
        '',
        '📚 Session: $sessionTitle',
        '👤 Student: $studentName',
        if (tutorName.isNotEmpty) '🎓 Tutor: $tutorName',
        '',
        if (attrs.isNotEmpty) ...['🗓 Selected Options:', attrLines, ''],
        '💳 Amount Paid: ₦${totalPaid.toStringAsFixed(2)}',
        '🔖 Reference: $ref',
      ].join('\n');

      if (Get.isRegistered<TutoringController>()) {
        await TutoringController.instance.sendMessage(chatId, messageText);
      } else {
        await _sendMessageDirectly(
          chatId: chatId,
          userId: userId,
          senderName: studentName,
          text: messageText,
        );
      }

      safePrint('✅ CheckoutController: booking confirmation sent to $chatId');

      // ✅ Physical session — generate QR for student only
      if (_isPhysicalSession(attrs)) {
        safePrint('📍 Physical session — generating QR for student');

        final qrData = _buildQrPayload(
          sessionId: sessionId,
          bookingRef: ref,
          sessionTitle: sessionTitle,
          studentName: studentName,
          tutorName: tutorName,
          attrs: attrs,
          amountPaid: totalPaid,
        );

        await _sendQrCode(
          sessionId: sessionId,
          studentUserId: userId,
          qrData: qrData,
          sessionTitle: sessionTitle,
          ref: ref,
        );
      }
    } catch (e) {
      safePrint('⚠️ CheckoutController._sendBookingConfirmationMessage: $e');
    }
  }

  Future<void> _sendMessageDirectly({
    required String chatId,
    required String userId,
    required String senderName,
    required String text,
  }) async {
    try {
      const mutationDoc = r"""
        mutation CreateChatMessage($input: CreateChatMessageInput!) {
          createChatMessage(input: $input) {
            id sessionId senderId senderName text isVoice createdAt _version
          }
        }
      """;

      final now = DateTime.now().toUtc().toIso8601String();

      await Amplify.API
          .mutate(
            request: GraphQLRequest<String>(
              document: mutationDoc,
              variables: {
                'input': {
                  'sessionId': chatId,
                  'senderId': userId,
                  'senderName': senderName,
                  'text': text,
                  'isVoice': false,
                  'createdAt': now,
                },
              },
            ),
          )
          .response;

      safePrint('✅ CheckoutController: fallback message sent to $chatId');
    } catch (e) {
      safePrint('⚠️ CheckoutController._sendMessageDirectly: $e');
    }
  }

  // =========================================================================
  // UPDATE BOOKING ITEM PAID
  // =========================================================================

  Future<void> _updateBookingItemPaid(BookingItem item) async {
    try {
      const getDoc = r"""
        query GetBookingItem($id: ID!) {
          getBookingItem(id: $id) { id _version _deleted }
        }
      """;

      final getResponse =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: getDoc,
                  variables: {'id': item.id},
                ),
              )
              .response;

      int version = 1;
      if (getResponse.errors.isEmpty && getResponse.data != null) {
        final decoded = jsonDecode(getResponse.data!) as Map<String, dynamic>;
        final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
        final obj = root['getBookingItem'] as Map<String, dynamic>?;
        if (obj == null || obj['_deleted'] == true) return;
        final v = obj['_version'];
        if (v != null) version = (v as num).toInt();
      }

      const mutationDoc = r"""
        mutation UpdateBookingItem($input: UpdateBookingItemInput!) {
          updateBookingItem(input: $input) { id hasPaid _version }
        }
      """;

      final response =
          await Amplify.API
              .mutate(
                request: GraphQLRequest<String>(
                  document: mutationDoc,
                  variables: {
                    'input': {
                      'id': item.id,
                      '_version': version,
                      'hasPaid': true,
                      'updatedAt': DateTime.now().toUtc().toIso8601String(),
                    },
                  },
                ),
              )
              .response;

      if (response.errors.isNotEmpty) {
        safePrint(
          '⚠️ CheckoutController._updateBookingItemPaid: ${response.errors}',
        );
      } else {
        safePrint(
          '✅ CheckoutController: BookingItem ${item.id} marked as paid',
        );
      }
    } catch (e) {
      safePrint('❌ CheckoutController._updateBookingItemPaid: $e');
    }
  }

  // =========================================================================
  // UPSERT USER SESSION PAYMENT
  // =========================================================================

  Future<void> _upsertUserSessionPayment({
    required String userId,
    required String sessionId,
    required double total,
    required String ref,
  }) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();

      const listDoc = r"""
        query ListPaymentsByUser($userId: ID!, $limit: Int) {
          listUserSessionPaymentsByUser(userId: $userId, limit: $limit) {
            items { id userId sessionId hasPaid _version _deleted }
          }
        }
      """;

      final listResponse =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: listDoc,
                  variables: {'userId': userId, 'limit': 100},
                ),
              )
              .response;

      String? existingId;
      int existingVersion = 1;

      if (listResponse.errors.isEmpty && listResponse.data != null) {
        final decoded = jsonDecode(listResponse.data!) as Map<String, dynamic>;
        final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
        final listObj =
            root['listUserSessionPaymentsByUser'] as Map<String, dynamic>?;
        final items = listObj?['items'] as List<dynamic>? ?? [];

        for (final raw in items) {
          final item = raw as Map<String, dynamic>;
          if (item['sessionId'] == sessionId && item['_deleted'] != true) {
            existingId = item['id'] as String?;
            final v = item['_version'];
            if (v != null) existingVersion = (v as num).toInt();
            break;
          }
        }
      }

      if (existingId != null) {
        const updateDoc = r"""
          mutation UpdateUserSessionPayment($input: UpdateUserSessionPaymentInput!) {
            updateUserSessionPayment(input: $input) { id hasPaid _version }
          }
        """;

        await Amplify.API
            .mutate(
              request: GraphQLRequest<String>(
                document: updateDoc,
                variables: {
                  'input': {
                    'id': existingId,
                    '_version': existingVersion,
                    'hasPaid': true,
                    'paidAt': now,
                    'amountPaid': total,
                    'reference': ref,
                    'updatedAt': now,
                  },
                },
              ),
            )
            .response;

        safePrint(
          '✅ CheckoutController: UserSessionPayment $existingId updated',
        );
      } else {
        const createDoc = r"""
          mutation CreateUserSessionPayment($input: CreateUserSessionPaymentInput!) {
            createUserSessionPayment(input: $input) { id hasPaid _version }
          }
        """;

        await Amplify.API
            .mutate(
              request: GraphQLRequest<String>(
                document: createDoc,
                variables: {
                  'input': {
                    'userId': userId,
                    'sessionId': sessionId,
                    'hasPaid': true,
                    'paidAt': now,
                    'amountPaid': total,
                    'reference': ref,
                    'createdAt': now,
                    'updatedAt': now,
                  },
                },
              ),
            )
            .response;

        safePrint('✅ CheckoutController: UserSessionPayment created');
      }
    } catch (e) {
      safePrint('❌ CheckoutController._upsertUserSessionPayment: $e');
    }
  }

  // =========================================================================
  // PROCESSING DIALOG
  // =========================================================================

  void _showProcessingDialog(
    BuildContext context,
    PaystackCardModel card,
    double total,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => PopScope(
            canPop: false,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _paystackBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: _paystackBlue,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Processing Payment',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Charging ${card.maskedNumber}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₦${total.toStringAsFixed(2)} via Paystack',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      backgroundColor: _paystackBlue.withValues(alpha: 0.12),
                      color: _paystackBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Please do not close this screen',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // =========================================================================
  // SUCCESS DIALOG
  // =========================================================================

  void _showSuccessDialog(BuildContext context, double amount, String ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: _successGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Payment Successful!',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₦${amount.toStringAsFixed(2)} paid',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'via Paystack · $ref',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _successGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 14,
                          color: _successGreen,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Chat with your tutor is now unlocked',
                          style: TextStyle(
                            fontSize: 12,
                            color: _successGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.back();
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _paystackBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

// =============================================================================
// QR Download Bottom Sheet
// =============================================================================

class _QrDownloadSheet extends StatelessWidget {
  const _QrDownloadSheet({
    required this.qrFile,
    required this.sessionTitle,
    required this.ref,
  });

  final File qrFile;
  final String sessionTitle;
  final String ref;

  static const _blue = Color(0xFF0BA4DB);

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
          const SizedBox(height: 24),

          // ── Icon + title ─────────────────────────────────────────
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_blue, Color(0xFF0886B8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _blue.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Your QR Code is Ready',
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Show this at your session for instant\nverification.',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.55),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // ── QR preview ───────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              qrFile,
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ref: $ref',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),

          // ── Action buttons ───────────────────────────────────────
          Row(
            children: [
              // ✅ FIXED: Save uses gal package to save to gallery
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _saveToGallery(context);
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _blue,
                    side: const BorderSide(color: _blue, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Share
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(qrFile.path)],
                        text:
                            'My TutorLink session QR — $sessionTitle (Ref: $ref)',
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text(
                    'Share',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Done',
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

  // ✅ FIXED: uses gal to properly save PNG to device photo gallery
  Future<void> _saveToGallery(BuildContext context) async {
    try {
      // Request permission first
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }

      // Save the PNG file to the gallery
      await Gal.putImage(qrFile.path, album: 'TutorLink');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('QR code saved to your gallery'),
              ],
            ),
            backgroundColor: const Color(0xFF00C48C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      safePrint('⚠️ _saveToGallery error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not save image. Please try again.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
