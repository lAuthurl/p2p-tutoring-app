import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import 'package:p2p_tutoring_app/utils/constants/colors.dart';
import 'package:p2p_tutoring_app/utils/constants/sizes.dart';
import 'package:p2p_tutoring_app/utils/constants/text_strings.dart';
import 'package:p2p_tutoring_app/utils/validators/validation.dart';

import '../../../../authentication/controllers/login_controller.dart';
import '../../../../../../common/widgets/buttons/primary_button.dart';
import '../../forget_password/forget_password_options/forget_password_model_bottom_sheet.dart';

class LoginFormWidget extends StatelessWidget {
  const LoginFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();

    return Form(
      key: controller.loginFormKey,
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
            validator: (v) => null,
          ),

          const SizedBox(height: TSizes.md),

          // ── Email ─────────────────────────────────────────────
          _FieldLabel(label: TTexts.tEmail),
          const SizedBox(height: 6),
          _buildField(
            controller.email,
            'Enter your email',
            LineAwesomeIcons.envelope,
            validator: (v) {
              if ((controller.username.text.trim().isEmpty) &&
                  (v == null || v.trim().isEmpty)) {
                return 'Enter your username or email';
              }
              if (v != null && v.trim().isNotEmpty) {
                return TValidator.validateEmail(v);
              }
              return null;
            },
          ),

          const SizedBox(height: TSizes.md),

          // ── Password ──────────────────────────────────────────
          _FieldLabel(label: TTexts.tPassword),
          const SizedBox(height: 6),
          Obx(
            () => _buildPasswordField(
              controller.password,
              controller.hidePassword.value,
              () =>
                  controller.hidePassword.value =
                      !controller.hidePassword.value,
            ),
          ),

          const SizedBox(height: TSizes.sm),

          // ── Remember me + Forgot password ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Obx(
                    () => Transform.scale(
                      scale: 0.85,
                      child: Checkbox(
                        value: controller.rememberMe.value,
                        onChanged:
                            (v) => controller.rememberMe.value = v ?? false,
                        activeColor: TColors.primary,
                        checkColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Remember me',
                    style: TextStyle(
                      color: TColors.textDarkSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap:
                    () =>
                        ForgetPasswordScreen.buildShowModalBottomSheet(context),
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: TColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: TSizes.md),

          // ── Login button ──────────────────────────────────────
          Obx(
            () => TPrimaryButton(
              text: TTexts.tLogin,
              isLoading: controller.isLoading.value,
              onPressed: controller.emailAndPasswordLogin,
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
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: TColors.textDarkPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        hintText: hint,
        hintStyle: TextStyle(color: TColors.textDarkSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: TColors.textDarkSecondary, size: 18),
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

  Widget _buildPasswordField(
    TextEditingController controller,
    bool obscure,
    VoidCallback toggle,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: (v) => TValidator.validateEmptyText('Password', v),
      style: const TextStyle(color: TColors.textDarkPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        hintText: 'Enter your password',
        hintStyle: TextStyle(color: TColors.textDarkSecondary, fontSize: 14),
        prefixIcon: Icon(
          Icons.fingerprint,
          color: TColors.textDarkSecondary,
          size: 18,
        ),
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(
            obscure ? Iconsax.eye_slash : Iconsax.eye,
            color: TColors.textDarkSecondary,
            size: 18,
          ),
        ),
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
