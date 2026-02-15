import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/animations/fade_in_animation/fade_in_animation_controller.dart';
import '../../personalization/controllers/user_controller.dart';
import '../../routes/routes.dart';
import '../on_boarding/on_boarding_screen.dart';

class SplashScreen extends StatelessWidget {
  final int screenNumber; // 1, 2, or 3

  const SplashScreen({super.key, this.screenNumber = 1});

  @override
  Widget build(BuildContext context) {
    // Ensure controllers are available
    final FadeInAnimationController animationController = Get.put(
      FadeInAnimationController(),
    );

    final UserController userController = Get.find<UserController>();

    // Start splash animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      animationController.startSplashAnimation();

      // Delay navigation after splash
      Future.delayed(const Duration(seconds: 2), () {
        if (!userController.hasSeenOnboarding) {
          Get.offAll(() => OnBoardingScreen());
        } else if (!userController.isLoggedIn) {
          Get.offAllNamed(TRoutes.logIn);
        } else {
          Get.offAllNamed(TRoutes.mainDashboard);
        }
      });
    });

    final BoxDecoration background =
        screenNumber == 3
            ? const BoxDecoration(color: TColors.lightBackground)
            : const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(1, -1),
                end: Alignment(1, 1),
                colors: [
                  TColors.splashGradientStart,
                  TColors.splashGradientEnd,
                ],
              ),
            );

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: double.infinity,
        decoration: background,
        child: Center(
          child: Obx(
            () => Opacity(
              opacity: animationController.opacity.value,
              child: Image.asset(
                'assets/logo/t-store-splash-logo-black.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
