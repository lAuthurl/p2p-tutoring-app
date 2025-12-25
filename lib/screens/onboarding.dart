import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../utils/constants/colors.dart';
import 'package:p2p_tutoring_app/authentication/controllers.onboarding/onboarding_controller.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final obController = Get.put(OnBoardingController());

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Liquid Swipe Pages
          LiquidSwipe(
            pages: obController.pages,
            enableSideReveal: true,
            liquidController: obController.controller,
            onPageChangeCallback: obController.onPageChangedCallback,
            slideIconWidget: const Icon(
              Icons.arrow_back_ios,
              color: TColors.textWhite,
            ),
            waveType: WaveType.circularReveal,
          ),

          // Skip Button (Top Right)
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: () => obController.skip(),
              child: const Text(
                "Skip",
                style: TextStyle(
                  color: TColors.secondary, // Dark Blue
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Forward Button (Bottom Center, Black)
          Positioned(
            bottom: 40.0,
            left: 0,
            right: 0,
            child: Center(
              child: OutlinedButton(
                onPressed:
                    () => obController.animateToNextSlideWithLocalStorage(),
                style: ElevatedButton.styleFrom(
                  side: BorderSide(color: TColors.secondary),
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                  foregroundColor: Colors.white,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: const BoxDecoration(
                    color: TColors.textDarkPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Page Indicator
          Obx(
            () => Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSmoothIndicator(
                  count: obController.pages.length,
                  activeIndex: obController.currentPage.value,
                  effect: ExpandingDotsEffect(
                    activeDotColor: TColors.primary, // Light Blue
                    dotColor: TColors.primary.withOpacity(
                      0.5,
                    ), // Light transparent
                    dotHeight: 12,
                    dotWidth: 12,
                    expansionFactor: 4,
                    spacing: 8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
