import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../../utils/constants/colors.dart';
import '../../authentication/controllers/on_boarding_controller.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final obController = Get.find<OnBoardingController>();

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          /// Liquid Swipe (default icon removed)
          GestureDetector(
            onPanStart: (_) => obController.isUserInteracting.value = true,
            onPanEnd: (_) => obController.isUserInteracting.value = false,
            onPanCancel: () => obController.isUserInteracting.value = false,
            child: LiquidSwipe(
              pages: obController.pages,
              enableSideReveal: true,
              liquidController: obController.controller,
              onPageChangeCallback: obController.onPageChangedCallback,
              waveType: WaveType.circularReveal,
            ),
          ),

          /// Swipe hint icon (visible only during interaction)
          Obx(
            () => Positioned(
              bottom: 120,
              right: 20,
              child: AnimatedOpacity(
                opacity: obController.isUserInteracting.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(
                  Icons.arrow_back_ios,
                  size: 32,
                  color: TColors.iconPrimaryDark,
                ),
              ),
            ),
          ),

          /// Next Button
          Positioned(
            bottom: 50,
            child: OutlinedButton(
              onPressed: obController.animateToNextSlideWithLocalStorage,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: TColors.borderLight),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: TColors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: TColors.textWhite,
                ),
              ),
            ),
          ),

          /// Skip Button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: obController.skip,
              child: const Text(
                'Skip',
                style: TextStyle(color: TColors.textSecondary),
              ),
            ),
          ),

          /// Page Indicator
          Obx(
            () => Positioned(
              bottom: 10,
              child: AnimatedSmoothIndicator(
                count: obController.pages.length,
                activeIndex: obController.currentPage.value,
                effect: const ExpandingDotsEffect(
                  activeDotColor: TColors.dark,
                  dotColor: TColors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
