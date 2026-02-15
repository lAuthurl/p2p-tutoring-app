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
    // Initialize controllers
    final checkoutController = Get.put(CheckoutController());
    final bookingController = Get.put(BookingController());

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Review'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            // Booking items
            TBookingItems(),
            SizedBox(height: 16),

            // Billing summary
            TBillingAmountSection(),
            SizedBox(height: 16),

            // Payment selection section
            TPaymentSection(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16), // same as BookingScreen
          child: SizedBox(
            width: double.infinity, // full-width button
            child: Obx(() {
              final totalPrice = bookingController.totalBookingPrice.value;
              final paymentMethod =
                  checkoutController.selectedPaymentMethod.value.name;

              return ElevatedButton(
                onPressed: () {
                  // TODO: Integrate actual payment gateway
                  Get.snackbar(
                    'Payment',
                    'Processing payment with $paymentMethod',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Checkout \$${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 15),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
