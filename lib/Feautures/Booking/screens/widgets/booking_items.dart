import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../controllers/booking_controller.dart';
import '../booking_item_style_01.dart';

class TBookingItems extends StatelessWidget {
  const TBookingItems({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingController = Get.find<BookingController>();

    return Obx(() {
      final bookingItems = bookingController.bookingItemsForUI;

      if (bookingItems.isEmpty) {
        return const Center(child: Text("No bookings yet."));
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: bookingItems.length,
        // Minimal space between items
        separatorBuilder: (_, _) => const SizedBox(height: TSizes.sm),
        itemBuilder: (context, index) {
          final item = bookingItems[index];

          // Only the item widget, no extra container
          return BookingItemStyle01(item: item);
        },
      );
    });
  }
}
