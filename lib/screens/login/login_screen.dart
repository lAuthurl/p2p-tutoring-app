import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:p2p_tutoring_app/utils/constants/colors.dart';
import 'package:p2p_tutoring_app/utils/constants/sizes.dart';
import 'package:p2p_tutoring_app/utils/constants/image_strings.dart';

import '../../authentication/controllers/login_controller.dart';
import 'widgets/login_form_widget.dart';
import '../signup/signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginController = Get.put(LoginController(), permanent: true);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TColors.darkBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero image — full bleed top ───────────────────
            SizedBox(
              width: double.infinity,
              height: size.height * 0.38,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(TImages.tWelcomeScreenImage, fit: BoxFit.cover),
                  // Bottom fade into dark background
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, TColors.darkBackground],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TSizes.defaultSpace,
                0,
                TSizes.defaultSpace,
                TSizes.defaultSpace,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heading
                  Text(
                    'Welcome Back 👋',
                    style: TextStyle(
                      color: TColors.textDarkPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Sign in to continue your learning journey',
                    style: TextStyle(
                      color: TColors.textDarkSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: TSizes.lg),

                  // ── Form ──────────────────────────────────────
                  const LoginFormWidget(),

                  const SizedBox(height: TSizes.lg),

                  // ── Divider ───────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.08),
                          thickness: 0.5,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            color: TColors.textDarkSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.08),
                          thickness: 0.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: TSizes.lg),

                  // ── Google button ──────────────────────────────
                  Obx(
                    () => GestureDetector(
                      onTap:
                          loginController.isGoogleLoading.value
                              ? null
                              : () => loginController.googleSignIn(),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/logo/google-logo.png',
                              height: 20,
                              width: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              loginController.isGoogleLoading.value
                                  ? 'Signing in...'
                                  : 'Sign in with Google',
                              style: TextStyle(
                                color: TColors.textDarkPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: TSizes.xl),

                  // ── Sign up link ───────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () => Get.off(() => const SignupScreen()),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account?  ",
                          style: TextStyle(
                            color: TColors.textDarkSecondary,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign Up',
                              style: TextStyle(
                                color: TColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: TSizes.md),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
