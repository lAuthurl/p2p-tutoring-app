import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:p2p_tutoring_app/utils/constants/colors.dart';
import 'package:p2p_tutoring_app/utils/constants/sizes.dart';

import '../../authentication/controllers/verify_email_controller.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    // ✅ Register controller if not already (safe to call multiple times)
    if (!Get.isRegistered<VerifyEmailController>()) {
      Get.put(VerifyEmailController());
    }
    final controller = Get.find<VerifyEmailController>();
    final TextEditingController codeController = TextEditingController();

    return Scaffold(
      backgroundColor: TColors.darkBackground,
      appBar: AppBar(
        backgroundColor: TColors.darkBackground,
        title: const Text(
          'Verify Email',
          style: TextStyle(color: TColors.textDarkPrimary),
        ),
        iconTheme: const IconThemeData(color: TColors.textDarkPrimary),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 360,
            padding: const EdgeInsets.symmetric(
              horizontal: TSizes.lg,
              vertical: TSizes.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: TColors.primary,
                ),

                const SizedBox(height: TSizes.lg),

                Text(
                  'Check Your Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TColors.textDarkPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: TSizes.sm),

                Text(
                  'A verification code was sent to:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TColors.textDarkSecondary,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: TSizes.xl),

                // ✅ Code input
                TextFormField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TColors.textPrimary,
                    fontSize: 20,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: TColors.secondaryBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintText: '------',
                    hintStyle: TextStyle(
                      color: TColors.textSecondary,
                      letterSpacing: 8,
                    ),
                  ),
                ),

                const SizedBox(height: TSizes.md),

                // ✅ Confirm button — triggers confirmCode → auto-login
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      await controller.confirmCode(
                        email,
                        codeController.text.trim(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirm & Login',
                      style: TextStyle(
                        color: TColors.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: TSizes.sm),

                // ✅ Resend code
                TextButton(
                  onPressed: () => controller.resendCode(email),
                  child: const Text(
                    'Resend Code',
                    style: TextStyle(color: TColors.primary, fontSize: 14),
                  ),
                ),

                const SizedBox(height: TSizes.sm),

                // ✅ Skip / continue without verifying
                TextButton(
                  onPressed: () => controller.skip(),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      color: TColors.textDarkSecondary,
                      fontSize: 13,
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
