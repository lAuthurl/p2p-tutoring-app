import 'package:flutter/material.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../models/model_on_boarding.dart';

class OnBoardingPageWidget extends StatelessWidget {
  const OnBoardingPageWidget({super.key, required this.model});

  final OnBoardingModel model;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final displayWidth = size.width * 0.9;

    return Container(
      color: model.bgColor,
      padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // column takes minimal vertical space
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: displayWidth,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Image.asset(
                  model.image,
                  fit: BoxFit.contain,
                  cacheWidth: 400,
                  cacheHeight: 400,
                ),
              ),
            ),
            const SizedBox(height: 20), // spacing between image and title
            Text(
              model.title,
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10), // spacing between title and subtitle
            Text(
              model.subTitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30), // spacing before counter
            Text(
              model.counterText,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20), // small bottom spacing
          ],
        ),
      ),
    );
  }
}
