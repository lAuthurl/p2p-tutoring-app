// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../common/widgets/texts/t_product_price_text.dart';
import '../../../../../common/widgets/texts/t_product_title_text.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/session_creation_controller.dart';
import '../../../../../models/ModelProvider.dart';

class TProductMetaData extends StatelessWidget {
  final TutoringSession session;
  final String? tag; // optional tag

  const TProductMetaData({super.key, required this.session, this.tag});

  @override
  Widget build(BuildContext context) {
    // Use the provided tag or fallback to session.id
    final controllerTag = tag ?? session.id;
    final controller = Get.find<SessionCreationController>(tag: controllerTag);
    final basePrice = session.pricePerSession ?? 0;

    return Obx(() {
      final adjustedPrice = controller.calculateDynamicPrice(session);

      int? salePercentage;
      if (adjustedPrice < basePrice && basePrice > 0) {
        salePercentage =
            ((basePrice - adjustedPrice) / basePrice * 100).round();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
    });
  }
}
