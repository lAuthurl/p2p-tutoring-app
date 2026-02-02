import 'package:flutter/material.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../common/widgets/images/t_rounded_image.dart';
import '../../../common/widgets/texts/t_brand_title_text_with_verified_icon.dart';
import '../../../common/widgets/texts/t_product_title_text.dart';
import '../models/booking_item_model.dart';

class BookingItemStyle01 extends StatelessWidget {
  const BookingItemStyle01({super.key, required this.item});

  final BookingItemModel item;

  @override
  Widget build(BuildContext context) {
    final rawUrl = item.serviceImage;
    final cleaned = THelperFunctions.normalizeImagePath(rawUrl);
    final isNetwork = THelperFunctions.isNetworkImagePath(rawUrl);

    return Row(
      children: [
        TRoundedImage(
          width: 60,
          height: 60,
          imageUrl: cleaned.isEmpty ? '' : cleaned,
          isNetworkImage: isNetwork,
          padding: const EdgeInsets.all(TSizes.sm),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        const SizedBox(width: TSizes.spaceBtwItems),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TBrandTitleWithVerifiedIcon(title: item.providerName),
              Flexible(
                child: TProductTitleText(title: item.serviceTitle, maxLines: 1),
              ),
              Text(
                '${item.bookingDate.toLocal()} - ${item.timeSlot}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
