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
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      color: model.bgColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
          Column(
            children: [
              Text(
                model.title,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              Text(model.subTitle, textAlign: TextAlign.center),
            ],
          ),
          Text(
            model.counterText,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 80.0),
        ],
      ),
    );
  }
}
