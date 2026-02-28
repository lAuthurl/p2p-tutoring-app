import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../Booking/controllers/booking_controller.dart';

/// Displays the billing summary for the peer tutoring checkout,
/// showing base total, app fee (commission), and total amount.
class TBillingAmountSection extends StatelessWidget {
  const TBillingAmountSection({super.key});

  static const double appFeePercentage = 0.10; // 10% fee

  @override
  Widget build(BuildContext context) {
    final bookingController = BookingController.instance;

    return Obx(() {
      final bookingItems = bookingController.bookingItems;

      // Sum of all booking item prices (Base Total)
      final baseTotal = bookingItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.price ?? 0.0),
      );

      // App fee (10% of Base Total)
      final appFee = baseTotal * appFeePercentage;

      // Total amount = Base Total + App Fee
      final totalAmount = baseTotal + appFee;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow(context, 'Base Total', baseTotal),
          const SizedBox(height: TSizes.spaceBtwItems),
          _buildRow(context, 'App Fee', appFee),
          const SizedBox(height: TSizes.spaceBtwItems),
          _buildRow(context, 'Total', totalAmount, isTotal: true),
        ],
      );
    });
  }

  /// Helper to build a row with label and amount
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
        Text("\$${amount.toStringAsFixed(2)}", style: style),
      ],
    );
  }
}
