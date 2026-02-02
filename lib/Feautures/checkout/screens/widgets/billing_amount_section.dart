import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/helpers/pricing_calculator.dart';
import '../../../Booking/controllers/booking_controller.dart';
import '../../../../utils/constants/sizes.dart';

/// Displays the billing summary for the peer tutoring checkout,
/// including session subtotals, optional discounts, and total price.
class TBillingAmountSection extends StatelessWidget {
  const TBillingAmountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingController = BookingController.instance;

    return Obx(() {
      // Calculate session subtotals
      final sessionPrices =
          bookingController.bookingItems.map((item) {
            return TPricingCalculator.calculateSessionPrice(
              isPhysical: item.isPhysical,
              applyDiscount: item.applyDiscount,
              negotiatedPrice: item.negotiatedPrice,
            );
          }).toList();

      final subTotal = sessionPrices.fold(0.0, (prev, curr) => prev + curr);

      // Calculate total discount
      final totalDiscount = _calculateTotalDiscount(
        bookingController.bookingItems,
      );

      // Calculate total price
      final totalPrice = subTotal - totalDiscount;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Subtotal
          Row(
            children: [
              Expanded(
                child: Text(
                  'Subtotal',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '\$${subTotal.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          // --- Discounts (if any)
          if (totalDiscount > 0)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Discount',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '-\$${totalDiscount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          if (totalDiscount > 0) const SizedBox(height: TSizes.spaceBtwItems),

          // --- Total
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ],
      );
    });
  }

  /// Calculate total discount for the booking items
  double _calculateTotalDiscount(List bookingItems) {
    double totalDiscount = 0.0;
    for (var item in bookingItems) {
      if (item.applyDiscount) {
        final originalPrice =
            item.isPhysical
                ? item.negotiatedPrice ?? 35.0
                : 20.0; // default base prices
        final discountedPrice = TPricingCalculator.calculateSessionPrice(
          isPhysical: item.isPhysical,
          applyDiscount: true,
          negotiatedPrice: item.negotiatedPrice,
        );
        totalDiscount += (originalPrice - discountedPrice);
      }
    }
    return totalDiscount;
  }
}
