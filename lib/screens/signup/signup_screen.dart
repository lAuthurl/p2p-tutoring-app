import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:p2p_tutoring_app/utils/constants/colors.dart';
import 'package:p2p_tutoring_app/utils/constants/sizes.dart';
import 'package:p2p_tutoring_app/utils/constants/image_strings.dart';

import 'widgets/signup_form_widget.dart';
import '../login/login_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.darkBackground,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 360,
            padding: const EdgeInsets.symmetric(
              horizontal: TSizes.lg,
              vertical: TSizes.xl,
            ),
            decoration: BoxDecoration(
              color: TColors.darkBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Image
                SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: Image.asset(
                    TImages.tWelcomeScreenImage,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: TSizes.lg),

                Text(
                  'Create Account Now!',
                  style: TextStyle(
                    color: TColors.textDarkPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: TSizes.lg),

                const SignUpFormWidget(),

                const SizedBox(height: TSizes.md),

                Center(
                  child: GestureDetector(
                    onTap: () => Get.off(() => const LoginScreen()),
                    child: Text.rich(
                      TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(
                          color: TColors.textDarkSecondary,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: "Login",
                            style: TextStyle(
                              color: TColors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
