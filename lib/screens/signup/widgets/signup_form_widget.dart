import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import 'package:p2p_tutoring_app/utils/constants/colors.dart';
import 'package:p2p_tutoring_app/utils/constants/sizes.dart';
import 'package:p2p_tutoring_app/utils/constants/text_strings.dart';
import 'package:p2p_tutoring_app/utils/validators/validation.dart';

import '../../../../authentication/controllers/signup_controller.dart';
import '../../../../../../common/widgets/buttons/primary_button.dart';

class SignUpFormWidget extends StatelessWidget {
  const SignUpFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SignUpController>();

    return Form(
      key: controller.signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Username ──────────────────────────────────────────
          _FieldLabel(label: 'Username'),
          const SizedBox(height: 6),
          _buildField(
            controller.username,
            'Enter your username',
            LineAwesomeIcons.user,
            validator:
                (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Username cannot be empty'
                        : null,
          ),

          const SizedBox(height: TSizes.md),

          // ── Email ─────────────────────────────────────────────
          _FieldLabel(label: 'Email'),
          const SizedBox(height: 6),
          _buildField(
            controller.email,
            'Enter your email',
            LineAwesomeIcons.envelope,
            validator: TValidator.validateEmail,
          ),

          const SizedBox(height: TSizes.md),

          // ── Password ──────────────────────────────────────────
          _FieldLabel(label: 'Password'),
          const SizedBox(height: 6),
          Obx(
            () => _buildField(
              controller.password,
              'Create a password',
              Icons.fingerprint,
              validator: TValidator.validatePassword,
              isPassword: true,
              obscureText: controller.hidePassword.value,
              toggle:
                  () =>
                      controller.hidePassword.value =
                          !controller.hidePassword.value,
            ),
          ),

          const SizedBox(height: TSizes.md),

          // ── Phone number ──────────────────────────────────────
          _FieldLabel(label: 'Phone Number'),
          const SizedBox(height: 6),
          _buildField(
            controller.phoneNumber,
            'Enter your phone number',
            LineAwesomeIcons.phone_solid,
            validator:
                (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Phone number cannot be empty'
                        : null,
          ),

          const SizedBox(height: TSizes.lg),

          // ── Sign up button ────────────────────────────────────
          Obx(
            () => TPrimaryButton(
              text: TTexts.tSignup,
              isLoading: controller.isLoading.value,
              onPressed: controller.signup,
              backgroundColor: TColors.primary,
              textColor: Colors.white,
              fontSize: 15,
              height: 52,
              verticalPadding: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    String? Function(String?)? validator,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? toggle,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: isPassword ? obscureText : false,
      style: const TextStyle(color: TColors.textDarkPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        hintText: hint,
        hintStyle: TextStyle(color: TColors.textDarkSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: TColors.textDarkSecondary, size: 18),
        suffixIcon:
            isPassword
                ? IconButton(
                  onPressed: toggle,
                  icon: Icon(
                    obscureText ? Iconsax.eye_slash : Iconsax.eye,
                    color: TColors.textDarkSecondary,
                    size: 18,
                  ),
                )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: TColors.textDarkSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}
