import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:p2p_tutoring_app/screens/on_boarding/on_boarding_screen.dart';

class FadeInAnimationController extends GetxController {
  static FadeInAnimationController get find => Get.find();

  RxBool animateTwoWay = false.obs;
  RxBool animateSingle = false.obs;

  // Observable opacity for fade-in animation
  RxDouble opacity = 0.0.obs;

  /// Start the splash animation with fade-in and navigation
  Future<void> startSplashAnimation() async {
    // Start fade-in after first frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animateOpacity();
    });

    // Optional: animateTwoWay effect
    await Future.delayed(const Duration(milliseconds: 500));
    animateTwoWay.value = true;

    // Keep splash visible for 3 seconds
    await Future.delayed(const Duration(milliseconds: 3000));
    animateTwoWay.value = false;

    // Optional delay before navigating
    await Future.delayed(const Duration(milliseconds: 2000));

    // Navigate to OnBoardingScreen
    Get.off(
      () => const OnBoardingScreen(),
      duration: const Duration(milliseconds: 1000),
      transition: Transition.fadeIn,
    );
  }

  /// Fade-in animation from 0 to 1 over 800ms
  void _animateOpacity() async {
    const duration = Duration(milliseconds: 800);
    const steps = 40;
    final stepTime = duration.inMilliseconds ~/ steps;

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: stepTime));
      opacity.value = i / steps;
    }
  }

  /// Can be used to animate in after calling the next screen
  Future<void> animationIn() async {
    await Future.delayed(const Duration(milliseconds: 500));
    animateSingle.value = true;
  }

  /// Can be used to animate out before calling the next screen
  Future<void> animationOut() async {
    animateSingle.value = false;
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
