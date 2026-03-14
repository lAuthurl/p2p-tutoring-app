// ── CheckoutScreen ────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:p2p_tutoring_app/Feautures/checkout/screens/widgets/billing_payment_section.dart';
import 'package:p2p_tutoring_app/Feautures/checkout/screens/widgets/t_payment_section.dart';

import '../../Booking/controllers/booking_controller.dart';
import '../controllers/checkout_controller.dart';
import '../../Booking/screens/widgets/booking_items.dart';
import '../../../../../utils/constants/colors.dart';

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
            // ── Section label ─────────────────────────────────────
            _SectionLabel(label: 'Your Sessions'),
            const SizedBox(height: 10),

            // ── Booking items card ────────────────────────────────
            _Card(child: const TBookingItems()),
            const SizedBox(height: 20),

            // ── Billing summary ───────────────────────────────────
            _SectionLabel(label: 'Order Summary'),
            const SizedBox(height: 10),
            _Card(child: const TBillingAmountSection()),
            const SizedBox(height: 20),

            // ── Payment method ────────────────────────────────────
            _SectionLabel(label: 'Payment'),
            const SizedBox(height: 10),
            _Card(child: const TPaymentSection()),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // ── Checkout button ───────────────────────────────────────
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
              final paymentMethod =
                  checkoutController.selectedPaymentMethod.value.name;

              return ElevatedButton(
                onPressed: () {
                  Get.snackbar(
                    'Payment',
                    'Processing payment with $paymentMethod',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.security_safe, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Pay  ₦${totalPrice.toStringAsFixed(2)}',
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
