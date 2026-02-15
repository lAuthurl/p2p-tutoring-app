import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../common/widgets/images/t_circular_image.dart';
import '../../../../../common/widgets/texts/t_product_price_text.dart';
import '../../../../../common/widgets/texts/t_product_title_text.dart';
import '../../../../../common/widgets/texts/t_brand_title_text_with_verified_icon.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/enums.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/tutoring_controller.dart';
import '../../../../../models/ModelProvider.dart';

class TProductMetaData extends StatelessWidget {
  const TProductMetaData({super.key, required this.session});

  final TutoringSession session;

  @override
  Widget build(BuildContext context) {
    final controller = TutoringController.instance;

    final basePrice = session.pricePerSession ?? 0;

    /// calculate % discount based on variation price difference
    final adjustedPrice =
        double.tryParse(controller.getSessionPrice(session)) ?? basePrice;

    int? salePercentage;
    if (adjustedPrice < basePrice && basePrice > 0) {
      salePercentage = ((basePrice - adjustedPrice) / basePrice * 100).round();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// PRICE
        Row(
          children: [
            if (salePercentage != null && salePercentage > 0)
              Row(
                children: [
                  TRoundedContainer(
                    backgroundColor: TColors.primary,
                    radius: TSizes.sm,
                    padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.sm,
                      vertical: TSizes.xs,
                    ),
                    child: Text(
                      '$salePercentage%',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge!.apply(color: TColors.black),
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                ],
              ),

            if (salePercentage != null)
              Row(
                children: [
                  Text(
                    basePrice.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.titleSmall!.apply(
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                ],
              ),

            Obx(
              () => TProductPriceText(
                price: controller.getSessionPrice(session),
                isLarge: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: TSizes.spaceBtwItems / 1.5),

        /// TITLE
        TProductTitleText(title: session.title),

        const SizedBox(height: TSizes.spaceBtwItems / 1.5),

        /// DURATION (SAFE)
        Builder(
          builder: (_) {
            String? duration;

            duration = controller.selectedAttributes['Duration'];

            if (duration == null) {
              for (final attr in session.sessionAttributes ?? []) {
                if (attr.name.toLowerCase() == 'duration' &&
                    attr.values.isNotEmpty) {
                  duration = attr.values.first;
                  break;
                }
              }
            }

            if (duration == null) {
              for (final v in session.sessionVariations ?? []) {
                final map = Map<String, String>.from(v.sessionAttributes ?? {});
                duration = map['Duration'] ?? map['duration'];
                if (duration != null) break;
              }
            }

            if (duration == null) return const SizedBox.shrink();

            return Column(
              children: [
                Row(
                  children: [
                    const TProductTitleText(
                      title: 'Duration : ',
                      smallSize: true,
                    ),
                    Text(
                      duration,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
              ],
            );
          },
        ),

        /// TUTOR
        if (session.tutor != null)
          Row(
            children: [
              TCircularImage(
                image: session.tutor?.image ?? '',
                width: 32,
                height: 32,
                overlayColor: TColors.textWhite,
              ),
              const SizedBox(width: 8),
              TBrandTitleWithVerifiedIcon(
                title: session.tutor?.name ?? 'Tutor',
                brandTextSize: TextSizes.medium,
              ),
            ],
          ),
      ],
    );
  }
}
