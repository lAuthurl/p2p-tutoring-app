import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/texts/t_product_price_text.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../controllers/booking_controller.dart';
import '../booking_item_style_01.dart';

class TBookingItems extends StatelessWidget {
  const TBookingItems({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingController = Get.put(BookingController());
    final bookingItems = bookingController.bookingItems;

    return Obx(
      () => ListView.separated(
        shrinkWrap: true,
        itemCount: bookingItems.length,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder:
            (context, index) => const SizedBox(height: TSizes.spaceBtwSections),
        itemBuilder: (context, index) {
          final item = bookingItems[index];
          final itemTotal = item.price * item.quantity;
          return Column(
            children: [
              /// -- Booking Item Style
              BookingItemStyle01(item: item),

              const SizedBox(height: TSizes.spaceBtwItems),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Total price
                  TProductPriceText(price: itemTotal.toString()),

                  /// Remove button on the right
                  IconButton(
                    onPressed: () => bookingController.removeBooking(item),
                    icon: const Icon(Icons.delete, size: 20),
                    color: Theme.of(context).colorScheme.error,
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
