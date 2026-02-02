import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/sizes.dart';
import '../../../common/widgets/appbar/home_appbar.dart';
import '../controllers/booking_controller.dart';
import 'widgets/booking_items.dart';
import '../../checkout/screens/checkout.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BookingController.instance;

    return Scaffold(
      appBar: TEComAppBar(
        showBackArrow: true,
        centerTitle: true,
        title: Text(
          'Bookings',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(TSizes.defaultSpace),
          child: TBookingItems(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.to(() => const CheckoutScreen()),
              child: Obx(
                () => Text('Checkout ${controller.totalBookingPrice.value}'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
