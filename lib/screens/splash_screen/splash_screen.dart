import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../utils/animations/fade_in_animation/fade_in_animation_controller.dart';
import '../../../../../utils/constants/colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FadeInAnimationController controller = Get.put(
      FadeInAnimationController(),
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.startSplashAnimation(),
    );

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        color:
            Get.isDarkMode ? TColors.darkBackground : TColors.lightBackground,
        child: Center(
          child: Image.asset(
            Get.isDarkMode
                ? 'assets/logo/t-store-splash-logo-white.png'
                : 'assets/logo/t-store-splash-logo-black.png',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
            cacheHeight: 180,
            cacheWidth: 180,
          ),
        ),
      ),
    );
  }
}
