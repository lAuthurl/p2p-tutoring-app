import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Booking/controllers/booking_controller.dart';
import '../controllers/checkout_controller.dart';
import './widgets/billing_amount_section.dart';
import 'widgets/t_payment_section.dart';
import '../../Booking/screens/widgets/booking_items.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final checkoutController = CheckoutController.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            TBookingItems(),
            SizedBox(height: 16),

            /// Billing summary (Subtotal, Discounts, Total)
            TBillingAmountSection(),
            SizedBox(height: 16),

            /// Payment methods
            TPaymentSection(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Obx(() {
            // Get total from BookingController dynamically
            final totalPrice =
                BookingController.instance.totalBookingPrice.value;
            final paymentMethod =
                checkoutController.selectedPaymentMethod.value.name;

            return ElevatedButton(
              onPressed: () {
                // TODO: Implement payment process
                Get.snackbar('Payment', 'Processing with $paymentMethod');
              },
              child: Text('Checkout \$${totalPrice.toStringAsFixed(2)}'),
            );
          }),
        ),
      ),
    );
  }
}
