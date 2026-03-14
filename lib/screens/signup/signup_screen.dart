import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:p2p_tutoring_app/utils/constants/colors.dart';
import 'package:p2p_tutoring_app/utils/constants/sizes.dart';
import 'package:p2p_tutoring_app/utils/constants/image_strings.dart';

import 'widgets/signup_form_widget.dart';
import '../login/login_screen.dart';
import '../../authentication/controllers/signup_controller.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SignUpController(), permanent: true);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TColors.darkBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero image — full bleed top ───────────────────
            SizedBox(
              width: double.infinity,
              height: size.height * 0.32,
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
                    'Create Account 🎉',
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
                    'Join thousands of students and tutors today',
                    style: TextStyle(
                      color: TColors.textDarkSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: TSizes.lg),

                  // ── Form ──────────────────────────────────────
                  const SignUpFormWidget(),

                  const SizedBox(height: TSizes.xl),

                  // ── Login link ────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () => Get.off(() => const LoginScreen()),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account?  ',
                          style: TextStyle(
                            color: TColors.textDarkSecondary,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: 'Login',
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
