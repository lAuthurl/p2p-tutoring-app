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
      final bookingItems = bookingController.bookingItems;

      // Calculate session subtotals safely
      final sessionPrices =
          bookingItems.map<double>((item) {
            return TPricingCalculator.calculateSessionPrice(
              isPhysical: item.isPhysical ?? false,
              applyDiscount: item.applyDiscount ?? false,
              negotiatedPrice: item.negotiatedPrice,
            );
          }).toList();

      final subTotal = sessionPrices.fold<double>(
        0.0,
        (prev, curr) => prev + curr,
      );

      // Calculate total discount safely
      final totalDiscount = _calculateTotalDiscount(bookingItems);

      final totalPrice = subTotal - totalDiscount;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Subtotal
          _buildRow(context, 'Subtotal', subTotal),

          const SizedBox(height: TSizes.spaceBtwItems),

          // --- Discounts (if any)
          if (totalDiscount > 0) _buildRow(context, 'Discount', -totalDiscount),
          if (totalDiscount > 0) const SizedBox(height: TSizes.spaceBtwItems),

          // --- Total
          _buildRow(context, 'Total', totalPrice, isTotal: true),
        ],
      );
    });
  }

  /// Helper to build a price row
  Widget _buildRow(
    BuildContext context,
    String label,
    double amount, {
    bool isTotal = false,
  }) {
    final style =
        isTotal
            ? Theme.of(context).textTheme.titleMedium
            : Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(
          amount < 0
              ? "-\$${(-amount).toStringAsFixed(2)}"
              : "\$${amount.toStringAsFixed(2)}",
          style: style,
        ),
      ],
    );
  }

  /// Calculate total discount for the booking items
  double _calculateTotalDiscount(List bookingItems) {
    double totalDiscount = 0.0;

    for (var item in bookingItems) {
      final applyDiscount = item.applyDiscount ?? false;
      final isPhysical = item.isPhysical ?? false;

      if (applyDiscount) {
        final originalPrice = isPhysical ? item.negotiatedPrice ?? 35.0 : 20.0;
        final discountedPrice = TPricingCalculator.calculateSessionPrice(
          isPhysical: isPhysical,
          applyDiscount: true,
          negotiatedPrice: item.negotiatedPrice,
        );
        totalDiscount += (originalPrice - discountedPrice);
      }
    }

    return totalDiscount;
  }
}
