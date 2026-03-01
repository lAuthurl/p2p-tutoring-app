import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../common/widgets/texts/t_product_title_text.dart';
import '../../../common/widgets/texts/t_product_price_text.dart';
import '../../../models/ModelProvider.dart';
import 'package:get/get.dart';
import '../controllers/booking_controller.dart';

class BookingItemStyle01 extends StatelessWidget {
  const BookingItemStyle01({super.key, required this.item});

  final BookingItem item;

  @override
  Widget build(BuildContext context) {
    final rawUrl = item.serviceImage ?? '';
    final cleaned = THelperFunctions.normalizeImagePath(rawUrl);
    final isNetwork = THelperFunctions.isNetworkImagePath(rawUrl);

    final bookingDateTime =
        item.bookingDate?.getDateTimeInUtc().toLocal() ?? DateTime.now();
    final formattedDate = DateFormat.yMMMd().format(bookingDateTime);

    final itemTotal = item.price ?? 0.0;
    final bookingController = Get.find<BookingController>();

    return Container(
      padding: const EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: TColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // center everything vertically
        children: [
          // Avatar/Image
          CircleAvatar(
            radius: 30,
            backgroundColor: TColors.primary,
            backgroundImage: isNetwork ? NetworkImage(cleaned) : null,
            child:
                (!isNetwork || cleaned.isEmpty)
                    ? Text(
                      (item.providerName?.isNotEmpty == true
                              ? item.providerName![0]
                              : '?')
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),

          const SizedBox(
            width: TSizes.defaultSpace * 1.5,
          ), // more space between image & details
          // Info + Price/Trash
          Expanded(
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // center details vertically
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Column: Provider Name, Service Title, Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment:
                      MainAxisAlignment.center, // center vertically
                  children: [
                    // Provider Name
                    Text(
                      item.providerName ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: TSizes.xs),

                    // Service Title
                    TProductTitleText(
                      title: item.serviceTitle ?? '',
                      maxLines: 1,
                    ),
                    const SizedBox(height: TSizes.xs),

                    // Date & Time
                    Text(
                      '$formattedDate - ${item.timeSlot ?? ''}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),

                // Right Row: Price + Trash
                Row(
                  children: [
                    // Price badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TSizes.sm,
                        vertical: TSizes.xs,
                      ),
                      decoration: BoxDecoration(
                        color: TColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(TSizes.sm),
                      ),
                      child: TProductPriceText(
                        price: itemTotal.toStringAsFixed(2),
                        isLarge: false,
                      ),
                    ),
                    const SizedBox(width: TSizes.sm),

                    // Trash icon
                    InkWell(
                      onTap: () => bookingController.removeBooking(item),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(TSizes.xs),
                        decoration: BoxDecoration(
                          color: TColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: TColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
