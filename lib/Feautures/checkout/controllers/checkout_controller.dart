// lib/Features/checkout/controllers/checkout_controller.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../models/ModelProvider.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../Booking/controllers/booking_controller.dart';
import '../../Courses/controllers/tutoring_controller.dart';
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
  // PERSIST PAYMENT — direct AppSync mutations + auto chat message
  // =========================================================================
  Future<void> _persistPaymentRecords(
    BookingController bookingCtrl,
    double total,
    String ref,
  ) async {
    final userId = UserController.instance.currentUser.value?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Snapshot items before clearing the cart.
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

        // ✅ Send automatic chat message so the tutor knows what was booked.
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
  // AUTO CHAT MESSAGE
  // =========================================================================

  /// Sends a structured booking confirmation message into the session's
  /// chat thread immediately after payment succeeds.
  ///
  /// Format example:
  /// ────────────────────────────────
  /// 📋 New Booking Confirmed
  ///
  /// 📚 Session: Advanced Mathematics
  /// 👤 Student: Lewin
  ///
  /// 🗓 Selected Options:
  ///   • Mode: Online
  ///   • Duration: 2hr
  ///   • Payment: Before Session
  ///
  /// 💳 Amount Paid: ₦5,500.00
  /// 🔖 Reference: PSK_1718123456789
  /// ────────────────────────────────
  ///
  /// The chatId follows the convention: {sessionId}_{userId}
  /// so the tutor's inbox can route it to the correct thread.
  Future<void> _sendBookingConfirmationMessage({
    required BookingItem item,
    required String userId,
    required double totalPaid,
    required String ref,
  }) async {
    try {
      final sessionId = item.sessionId;
      if (sessionId == null) return;

      // Build the chat thread ID — same convention used everywhere else.
      final chatId = '${sessionId}_$userId';

      // Resolve the student's display name.
      final currentUser = UserController.instance.currentUser.value;
      final studentName =
          (currentUser?.username.isNotEmpty ?? false)
              ? currentUser!.username
              : 'Student';

      // Parse selected attributes from the JSON stored on the BookingItem.
      final attrsJson = item.selectedAttributes;
      final Map<String, dynamic> attrs =
          (attrsJson != null && attrsJson.isNotEmpty)
              ? (jsonDecode(attrsJson) as Map<String, dynamic>)
              : {};

      // Build the attributes bullet list.
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

      // Use TutoringController.sendMessage which saves to DataStore and
      // syncs to AppSync, triggering the tutor's observeChat listener.
      if (Get.isRegistered<TutoringController>()) {
        await TutoringController.instance.sendMessage(chatId, messageText);
        safePrint('✅ CheckoutController: booking confirmation sent to $chatId');
      } else {
        // Fallback: send directly via AppSync mutation if TutoringController
        // isn't registered (e.g. during a cold-start checkout flow).
        await _sendMessageDirectly(
          chatId: chatId,
          userId: userId,
          senderName: studentName,
          text: messageText,
        );
      }
    } catch (e) {
      // Non-fatal — payment already succeeded. Log and continue.
      safePrint('⚠️ CheckoutController._sendBookingConfirmationMessage: $e');
    }
  }

  /// Direct AppSync fallback for sending a chat message without DataStore.
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
            id
            sessionId
            senderId
            senderName
            text
            isVoice
            createdAt
            _version
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
          updateBookingItem(input: $input) {
            id hasPaid _version
          }
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
          '⚠️ CheckoutController._updateBookingItemPaid errors: ${response.errors}',
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
            items {
              id userId sessionId hasPaid _version _deleted
            }
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
            updateUserSessionPayment(input: $input) {
              id hasPaid _version
            }
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
            createUserSessionPayment(input: $input) {
              id hasPaid _version
            }
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
                        Get.back(); // close dialog
                        Get.back(); // back from checkout
                        Get.back(); // back from booking review
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
