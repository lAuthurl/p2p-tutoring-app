import 'package:flutter/material.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../models/model_on_boarding.dart';

class OnBoardingPageWidget extends StatelessWidget {
  const OnBoardingPageWidget({
    super.key,
    required this.model,
    this.onUserInteraction,
  });

  final OnBoardingModel model;
  final VoidCallback? onUserInteraction;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final displayWidth = size.width * 0.9;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onUserInteraction,
      onHorizontalDragStart: (_) => onUserInteraction?.call(),
      child: Container(
        color: model.bgColor,
        padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: displayWidth,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset(
                    model.image,
                    fit: BoxFit.contain,
                    cacheWidth: 400,
                    cacheHeight: 400,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                model.title,
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                model.subTitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Text(
                model.counterText,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
