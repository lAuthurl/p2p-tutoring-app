import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../Feautures/dashboard/Home/controllers/subject_controller.dart';
import '../../authentication/controllers/on_boarding_controller.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final obController = Get.find<OnBoardingController>();

    if (!Get.isRegistered<SubjectController>()) {
      Get.lazyPut(() => SubjectController());
    }

    return Scaffold(
      body: Stack(
        children: [
          // ── Liquid swipe ──────────────────────────────────────
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

          // ── Skip ──────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                obController.handleFinish();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom bar ────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Dots
                    Obx(
                      () => AnimatedSmoothIndicator(
                        count: obController.pages.length,
                        activeIndex: obController.currentPage.value,
                        effect: const ExpandingDotsEffect(
                          activeDotColor: Colors.black,
                          dotColor: Colors.black26,
                          dotWidth: 8,
                          dotHeight: 8,
                          expansionFactor: 3.5,
                          spacing: 6,
                        ),
                      ),
                    ),

                    // Next / Get Started button
                    // ✅ AnimatedCrossFade avoids null width constraint crash
                    Obx(() {
                      final isLast =
                          obController.currentPage.value ==
                          obController.pages.length - 1;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          obController.animateToNextSlideWithLocalStorage();
                        },
                        child: AnimatedCrossFade(
                          duration: const Duration(milliseconds: 250),
                          crossFadeState:
                              isLast
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                          // Circle arrow button
                          firstChild: Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          // Get Started pill
                          secondChild: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'Get Started',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
