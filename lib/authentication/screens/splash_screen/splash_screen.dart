import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/animations/fade_in_animation/fade_in_animation_controller.dart';

// ✅ REMOVED imports of UserController and routes — the splash no longer
// decides where to navigate. AuthenticationRepository.screenRedirect() is
// the single source of truth for routing. Having two places decide routing
// caused a race: sometimes the splash timer fired first (correct), sometimes
// screenRedirect fired first and the splash timer then fired again and
// overrode it (incorrect — sent logged-in users to onboarding).

class SplashScreen extends StatelessWidget {
  final int screenNumber;

  const SplashScreen({super.key, this.screenNumber = 1});

  @override
  Widget build(BuildContext context) {
    final FadeInAnimationController animationController = Get.put(
      FadeInAnimationController(),
    );

    final isDark = screenNumber != 3;
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    // ✅ No routing logic here at all — just start the animation.
    // AuthenticationRepository.initializeCurrentUser() calls screenRedirect()
    // as soon as auth resolves, which replaces this screen via offAllNamed().
    // The splash simply shows the brand while that async work completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      animationController.startSplashAnimation();
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
                  opacity: animationController.opacity.value,
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOut,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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

                      Text(
                        'TutorMe',
                        style: TextStyle(
                          color: isLight ? Colors.black : Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),

                      const SizedBox(height: 6),

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
