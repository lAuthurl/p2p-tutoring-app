import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../Booking/controllers/booking_controller.dart';

class TBillingAmountSection extends StatelessWidget {
  const TBillingAmountSection({super.key});

  static const double appFeePercentage = 0.10;

  @override
  Widget build(BuildContext context) {
    final bookingController = BookingController.instance;
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final bookingItems = bookingController.bookingItems;
      final baseTotal = bookingItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.price ?? 0.0),
      );
      final appFee = baseTotal * appFeePercentage;
      final totalAmount = baseTotal + appFee;

      return Column(
        children: [
          _BillingRow(
            label: 'Base Total',
            amount: baseTotal,
            icon: Icons.receipt_outlined,
            iconColor: Colors.teal,
          ),
          Divider(
            height: TSizes.spaceBtwItems * 2,
            thickness: 0.5,
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
          _BillingRow(
            label: 'App Fee (10%)',
            amount: appFee,
            icon: Icons.percent_rounded,
            iconColor: Colors.orange,
          ),
          Divider(
            height: TSizes.spaceBtwItems * 2,
            thickness: 0.5,
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
          // Total row — highlighted
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: TColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: TColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: TColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: TColors.primary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Text(
                  '₦${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: TColors.primary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _BillingRow extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color iconColor;

  const _BillingRow({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
        Text(
          '₦${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
