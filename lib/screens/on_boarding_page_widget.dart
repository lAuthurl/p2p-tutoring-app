import 'package:flutter/material.dart';
import '../../models/model_on_boarding.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';

class OnBoardingPageWidget extends StatelessWidget {
  final OnBoardingModel model;
  const OnBoardingPageWidget({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      color: model.bgColor,
      padding: const EdgeInsets.symmetric(
        horizontal: TSizes.defaultSpace,
        vertical: TSizes.defaultSpace,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: size.height * 0.05),

            // Image
            Image.asset(
              model.image,
              height: size.height * 0.45,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            // Title
            Text(
              model.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: TColors.onBoardingTextColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: TSizes.spaceBtwItems / 2),

            // Subtitle
            Text(
              model.subTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TColors.onBoardingTextColor.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            // Counter
            Text(
              model.counterText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TColors.onBoardingTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
