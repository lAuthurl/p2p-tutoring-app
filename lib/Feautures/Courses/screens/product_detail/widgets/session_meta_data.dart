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
import '../../../models/tutoring_session_model.dart';

class TProductMetaData extends StatelessWidget {
  const TProductMetaData({super.key, required this.session});

  final TutoringSessionModel session;

  @override
  Widget build(BuildContext context) {
    final controller = TutoringController.instance;

    // Calculate sale percentage if needed
    final salePercentage = controller.calculateSalePercentage(
      session.pricePerSession,
      session.salePricePerSession,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Price & Sale Price
        Row(
          children: [
            /// -- Sale Tag
            if (salePercentage != null)
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

            // Original Price if sale exists
            if (session.salePricePerSession != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.pricePerSession.toString(),
                    style: Theme.of(context).textTheme.titleSmall!.apply(
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                ],
              ),

            // Main Price (sale price if exists)
            Obx(
              () => TProductPriceText(
                price: controller.getSessionPrice(session),
                isLarge: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 1.5),

        /// Session Title
        TProductTitleText(title: session.title),
        const SizedBox(height: TSizes.spaceBtwItems / 1.5),

        /// Duration (if available)
        Builder(
          builder: (_) {
            String? durationDisplay;
            final sel = controller.selectedAttributes['Duration'];
            if (sel != null && (sel).isNotEmpty) {
              durationDisplay = sel;
            } else {
              if (session.sessionAttributes != null) {
                for (final a in session.sessionAttributes!) {
                  if (a.name.toLowerCase() == 'duration' &&
                      a.values.isNotEmpty) {
                    durationDisplay = a.values.first;
                    break;
                  }
                }
              }
              if (durationDisplay == null &&
                  session.sessionVariations != null) {
                for (final v in session.sessionVariations!) {
                  final dv =
                      v.sessionAttributes['Duration'] ??
                      v.sessionAttributes['duration'] ??
                      '';
                  if (dv.isNotEmpty) {
                    durationDisplay = dv;
                    break;
                  }
                }
              }
            }

            if (durationDisplay != null && durationDisplay.isNotEmpty) {
              return Column(
                children: [
                  Row(
                    children: [
                      const TProductTitleText(
                        title: 'Duration : ',
                        smallSize: true,
                      ),
                      Text(
                        durationDisplay,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems / 2),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),

        /// Tutor / Provider
        if (session.tutor != null)
          Row(
            children: [
              TCircularImage(
                image: session.tutor!.image,
                width: 32,
                height: 32,
                overlayColor: TColors.textWhite,
              ),
              const SizedBox(width: 8),
              TBrandTitleWithVerifiedIcon(
                title: session.tutor!.name,
                brandTextSize: TextSizes.medium,
              ),
            ],
          ),
      ],
    );
  }
}
