import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2p_tutoring_app/utils/constants/colors.dart';
import 'package:p2p_tutoring_app/utils/constants/sizes.dart';
import 'widgets/login_form_widget.dart';
import '../signup/signup_screen.dart';
import 'package:p2p_tutoring_app/utils/constants/image_strings.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                // Top Image - full width
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
                  'Welcome Back!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TSizes.sm),
                Text(
                  'Login to continue',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: TSizes.lg),
                const LoginFormWidget(),
                const SizedBox(height: TSizes.md),
                Center(
                  child: GestureDetector(
                    onTap: () => Get.off(() => const SignupScreen()),
                    child: Text.rich(
                      TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        children: [
                          TextSpan(
                            text: "Sign Up",
                            style: TextStyle(
                              color: const Color(0xFFEF8460),
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
