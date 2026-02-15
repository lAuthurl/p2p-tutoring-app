import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/booking_controller.dart';
import 'widgets/booking_items.dart';
import '../../checkout/screens/checkout.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BookingController.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bookings',
          style: TextStyle(
            fontSize: 18, // bigger header text
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16), // consistent with CheckoutScreen
        child: const TBookingItems(),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.to(() => const CheckoutScreen()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Obx(
                () => Text(
                  'Checkout \$${controller.totalBookingPrice.value.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
