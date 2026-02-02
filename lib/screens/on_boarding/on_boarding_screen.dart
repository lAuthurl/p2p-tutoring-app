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

          /// Next Button (smaller and moved to the right)
          Positioned(
            bottom: 42,
            right: 28,
            child: OutlinedButton(
              onPressed: obController.animateToNextSlideWithLocalStorage,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: TColors.borderLight, width: 1),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
                minimumSize: const Size(44, 44),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: TColors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: TColors.textWhite,
                  size: 18,
                ),
              ),
            ),
          ),

          /// Skip Button (primary background, top-right, safe from status bar)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: ElevatedButton(
              onPressed: obController.skip,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.black,
                foregroundColor: TColors.textWhite,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          /// Page Indicator (moved left, slightly lower than button)
          Obx(
            () => Positioned(
              bottom: 18,
              left: 28,
              child: AnimatedSmoothIndicator(
                count: obController.pages.length,
                activeIndex: obController.currentPage.value,
                effect: const ExpandingDotsEffect(
                  activeDotColor: TColors.dark,
                  dotColor: TColors.grey,
                  dotWidth: 12,
                  dotHeight: 12,
                  expansionFactor: 3.0,
                  spacing: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
