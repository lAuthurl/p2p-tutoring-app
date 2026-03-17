// lib/Features/checkout/controllers/checkout_controller.dart

// ignore_for_file: use_build_context_synchronously

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../models/ModelProvider.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../Booking/controllers/booking_controller.dart';
import '../models/paystack_card_model.dart';
import 'paystack_card_controller.dart';
import '../screens/paystack_card_entry_screen.dart';

class CheckoutController extends GetxController {
  static CheckoutController get instance => Get.find();

  final isProcessing = false.obs;
  final paymentSuccess = false.obs;

  // ── Paystack colours (used in dialogs) ──────────────────────────
  static const Color _paystackBlue = Color(0xFF0BA4DB);
  static const Color _successGreen = Color(0xFF00C48C);

  // ── Main entry point called from CheckoutScreen ─────────────────
  Future<void> processPaystackPayment(BuildContext context) async {
    final cardCtrl = Get.put(PaystackCardController());

    // 1. Ensure a card is saved
    if (!cardCtrl.hasCard) {
      await Get.to(() => const PaystackCardEntryScreen());
      // After returning, re-check
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

    // 2. Show processing modal
    _showProcessingDialog(context, cardCtrl.savedCard.value, totalPrice);

    try {
      // 3. Simulate Paystack network round-trip (1.6 s)
      await Future.delayed(const Duration(milliseconds: 1600));

      // 4. Generate fake reference
      final ref = 'PSK_${DateTime.now().millisecondsSinceEpoch}';

      // 5. Persist payment records in DataStore
      await _persistPaymentRecords(bookingCtrl, totalPrice, ref);

      // 6. Done
      paymentSuccess.value = true;
      isProcessing.value = false;

      // Close processing dialog
      if (Navigator.canPop(context)) Get.back();

      // Show success dialog
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

  // ── Persist BookingItem.hasPaid + UserSessionPayment ────────────
  Future<void> _persistPaymentRecords(
    BookingController bookingCtrl,
    double total,
    String ref,
  ) async {
    final userId = UserController.instance.currentUser.value?.id;

    for (final item in List.from(bookingCtrl.bookingItems)) {
      // a) Mark BookingItem as paid
      final updatedItem = item.copyWith(hasPaid: true);
      await Amplify.DataStore.save(updatedItem);

      // b) Upsert UserSessionPayment so SessionDetailScreen can gate chat
      if (item.sessionId != null && userId != null) {
        // Check if a record already exists (idempotent)
        final existing = await Amplify.DataStore.query(
          UserSessionPayment.classType,
          where: UserSessionPayment.USERID
              .eq(userId)
              .and(UserSessionPayment.SESSIONID.eq(item.sessionId!)),
        );

        if (existing.isEmpty) {
          final payment = UserSessionPayment(
            userId: userId,
            sessionId: item.sessionId!,
            hasPaid: true,
            paidAt: TemporalDateTime(DateTime.now()),
            amountPaid: total,
            reference: ref,
          );
          await Amplify.DataStore.save(payment);
        } else {
          // Already has a record — update it to paid
          final updated = existing.first.copyWith(
            hasPaid: true,
            paidAt: TemporalDateTime(DateTime.now()),
            amountPaid: total,
            reference: ref,
          );
          await Amplify.DataStore.save(updated);
        }
      }
    }

    // Clear cart after successful payment
    bookingCtrl.clearBooking();
  }

  // ── Processing dialog ────────────────────────────────────────────
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
                    // Paystack logo area
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

  // ── Success dialog ───────────────────────────────────────────────
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
                  // Success checkmark
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
