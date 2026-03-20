// lib/Features/checkout/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2p_tutoring_app/Feautures/checkout/screens/widgets/billing_payment_section.dart';
import 'package:p2p_tutoring_app/Feautures/checkout/screens/widgets/t_payment_section.dart';

import '../../booking/controllers/booking_controller.dart';
import '../controllers/checkout_controller.dart';
import '../../booking/screens/widgets/booking_items.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final checkoutController = Get.put(CheckoutController());
    final bookingController = Get.put(BookingController());
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Booking Review',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section label ──────────────────────────────────────
            const _SectionLabel(label: 'Your Sessions'),
            const SizedBox(height: 10),

            // ── Booking items card ─────────────────────────────────
            const _Card(child: TBookingItems()),
            const SizedBox(height: 20),

            // ── Billing summary ────────────────────────────────────
            const _SectionLabel(label: 'Order Summary'),
            const SizedBox(height: 10),
            const _Card(child: TBillingAmountSection()),
            const SizedBox(height: 20),

            // ── Payment method ─────────────────────────────────────
            const _SectionLabel(label: 'Payment'),
            const SizedBox(height: 10),
            const _Card(child: TPaymentSection()),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // ── Pay button ─────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Obx(() {
              final totalPrice = bookingController.totalBookingPrice.value;
              final processing = checkoutController.isProcessing.value;

              return ElevatedButton(
                onPressed:
                    processing
                        ? null
                        : () =>
                            checkoutController.processPaystackPayment(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      processing
                          ? const Color(0xFF0BA4DB).withValues(alpha: 0.6)
                          : const Color(0xFF0BA4DB),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(
                    0xFF0BA4DB,
                  ).withValues(alpha: 0.5),
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child:
                    processing
                        ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Processing…',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_rounded, size: 17),
                            const SizedBox(width: 8),
                            Text(
                              'Pay  ₦${totalPrice.toStringAsFixed(2)}  ·  Paystack',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}
