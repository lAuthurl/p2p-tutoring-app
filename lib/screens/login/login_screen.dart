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
    // ✅ Ensure LoginController is registered
    final loginController = Get.put(LoginController(), permanent: true);

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
                  'Welcome Back!',
                  style: TextStyle(
                    color: TColors.textDarkPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: TSizes.sm),

                Text(
                  'Login to continue',
                  style: TextStyle(
                    color: TColors.textDarkSecondary,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: TSizes.lg),

                // Login Form
                const LoginFormWidget(),

                const SizedBox(height: TSizes.md),

                // Google Sign-In Button
                Obx(
                  () => ElevatedButton.icon(
                    onPressed:
                        loginController.isGoogleLoading.value
                            ? null
                            : () => loginController.googleSignIn(),
                    icon: Image.asset(
                      'assets/logo/google-logo.png',
                      height: 24,
                      width: 24,
                    ),
                    label: Text(
                      loginController.isGoogleLoading.value
                          ? 'Signing in...'
                          : 'Sign in with Google',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: TSizes.md),

                // Signup Link
                Center(
                  child: GestureDetector(
                    onTap: () => Get.off(() => const SignupScreen()),
                    child: Text.rich(
                      TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(
                          color: TColors.textDarkSecondary,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: "Sign Up",
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
