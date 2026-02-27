import 'package:flutter/material.dart';
import '../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../common/widgets/texts/t_product_price_text.dart';
import '../../../../../common/widgets/texts/t_product_title_text.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/tutoring_controller.dart';
import '../../../../../models/ModelProvider.dart';

class TProductMetaData extends StatelessWidget {
  const TProductMetaData({
    super.key,
    required this.session,
    required this.selectedAttributes,
  });

  final TutoringSession session;
  final Map<String, String> selectedAttributes; // normal Map

  @override
  Widget build(BuildContext context) {
    final controller = TutoringController.instance;
    final basePrice = session.pricePerSession ?? 0;

    double calculateAdjustedPrice(Map<String, String> attrs) {
      double price = basePrice;
      if ((attrs['Mode'] ?? '').toLowerCase() == 'offline') price *= 1.10;
      if ((attrs['Duration'] ?? '').toLowerCase() == '2hr') price *= 2;
      if ((attrs['Payment'] ?? '').toLowerCase() == 'after session') {
        price *= 1.02;
      }
      return price;
    }

    final adjustedPrice = calculateAdjustedPrice(selectedAttributes);

    // Optional sale percentage
    int? salePercentage;
    final adjustedPriceFromController =
        double.tryParse(controller.getSessionPrice(session)) ?? basePrice;
    if (adjustedPriceFromController < basePrice && basePrice > 0) {
      salePercentage =
          ((basePrice - adjustedPriceFromController) / basePrice * 100).round();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// TITLE + PRICE ROW
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TProductTitleText(
                title: session.title,
                customStyle: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (salePercentage != null && salePercentage > 0)
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
            if (salePercentage != null)
              Padding(
                padding: const EdgeInsets.only(left: TSizes.spaceBtwItems),
                child: Text(
                  basePrice.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.titleSmall!.apply(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: TSizes.spaceBtwItems),
              child: TProductPriceText(
                price: adjustedPrice.toStringAsFixed(2),
                isLarge: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: TSizes.spaceBtwItems / 1.5),
      ],
    );
  }
}
