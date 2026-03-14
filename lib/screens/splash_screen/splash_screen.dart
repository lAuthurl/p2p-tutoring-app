import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/animations/fade_in_animation/fade_in_animation_controller.dart';
import '../../personalization/controllers/user_controller.dart';
import '../../routes/routes.dart';
import '../on_boarding/on_boarding_screen.dart';

class SplashScreen extends StatelessWidget {
  final int screenNumber;

  const SplashScreen({super.key, this.screenNumber = 1});

  @override
  Widget build(BuildContext context) {
    final FadeInAnimationController animationController = Get.put(
      FadeInAnimationController(),
    );
    final UserController userController = Get.find<UserController>();

    final isDark = screenNumber != 3;
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      animationController.startSplashAnimation();
      // ── Bumped from 2s → 3.5s so the splash has time to breathe
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (!userController.hasSeenOnboarding) {
          Get.offAll(() => OnBoardingScreen());
        } else if (!userController.isLoggedIn) {
          Get.offAllNamed(TRoutes.logIn);
        } else {
          Get.offAllNamed(TRoutes.mainDashboard);
        }
      });
    });

    final isLight = screenNumber == 3;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: double.infinity,
        decoration:
            isLight
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
                ),
        child: Stack(
          children: [
            // ── Decorative circle — top left ──────────────────
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isLight
                          ? Colors.black.withValues(alpha: 0.04)
                          : Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // ── Decorative circle — bottom right ──────────────
            Positioned(
              bottom: -100,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isLight
                          ? Colors.black.withValues(alpha: 0.03)
                          : Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            // ── Small accent circle — top right ───────────────
            Positioned(
              top: 80,
              right: 40,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TColors.primary.withValues(alpha: 0.15),
                ),
              ),
            ),

            // ── Centre: logo + app name ───────────────────────
            Center(
              child: Obx(
                () => AnimatedOpacity(
                  // ── Slowed fade from instant → 900ms
                  opacity: animationController.opacity.value,
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOut,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo container
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isLight
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.1),
                          border: Border.all(
                            color:
                                isLight
                                    ? Colors.black.withValues(alpha: 0.06)
                                    : Colors.white.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Image.asset(
                            'assets/logo/t-store-splash-logo-black.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // App name
                      Text(
                        'TutorLink',
                        style: TextStyle(
                          color: isLight ? Colors.black : Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Tagline
                      Text(
                        'Learn from the best',
                        style: TextStyle(
                          color:
                              isLight
                                  ? Colors.black.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.45),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Loading indicator — bottom centre ─────────────
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Obx(
                () => AnimatedOpacity(
                  opacity: animationController.opacity.value,
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOut,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isLight
                              ? Colors.black.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
