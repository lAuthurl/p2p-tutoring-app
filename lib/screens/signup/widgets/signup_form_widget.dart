import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:iconsax/iconsax.dart';

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
          _buildField(
            controller.fullName,
            'Full Name',
            LineAwesomeIcons.user,
            validator: (v) => v!.isEmpty ? 'Name cannot be empty' : null,
          ),

          const SizedBox(height: TSizes.sm),

          _buildField(
            controller.email,
            'Email',
            LineAwesomeIcons.envelope,
            validator: TValidator.validateEmail,
          ),

          const SizedBox(height: TSizes.sm),

          Obx(
            () => _buildField(
              controller.password,
              'Password',
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

          const SizedBox(height: TSizes.sm),

          _buildField(
            controller.phoneNumber,
            'Phone No',
            LineAwesomeIcons.phone_solid,
            validator:
                (v) => v!.isEmpty ? 'Phone number cannot be empty' : null,
          ),

          const SizedBox(height: TSizes.md),

          Obx(
            () => TPrimaryButton(
              text: TTexts.tSignup,
              isLoading: controller.isLoading.value,
              onPressed: controller.signup,
              backgroundColor: TColors.primary,
              textColor: TColors.textWhite,
              fontSize: 16,
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
    String label,
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
      style: const TextStyle(color: TColors.textPrimary),
      decoration: InputDecoration(
        filled: true,
        fillColor: TColors.secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        labelText: label,
        labelStyle: const TextStyle(color: TColors.textSecondary),
        prefixIcon: Icon(icon, color: TColors.iconSecondaryLight),
        suffixIcon:
            isPassword
                ? IconButton(
                  onPressed: toggle,
                  icon: const Icon(
                    Iconsax.eye_slash,
                    color: TColors.iconSecondaryLight,
                  ),
                )
                : null,
      ),
    );
  }
}
