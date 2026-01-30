import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/animations/fade_in_animation/fade_in_animation_controller.dart';

class SplashScreen extends StatelessWidget {
  final int screenNumber; // 1, 2, or 3

  const SplashScreen({super.key, required this.screenNumber});

  @override
  Widget build(BuildContext context) {
    final FadeInAnimationController controller = Get.put(
      FadeInAnimationController(),
    );

    // Start splash animation
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.startSplashAnimation(),
    );

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
              opacity: controller.opacity.value,
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
