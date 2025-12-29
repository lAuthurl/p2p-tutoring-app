import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:iconsax/iconsax.dart';
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
          _buildField(
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
              onPressed: () => controller.signup(),
              backgroundColor: const Color(0xFFEF8460),
              textColor: Colors.white,
              fontSize: 16,
              height: 52, // increased height
              verticalPadding: 12, // prevent text cut off
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
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFFFE4DB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87),
        prefixIcon: Icon(icon, color: Colors.black54),
        suffixIcon:
            isPassword
                ? IconButton(
                  onPressed: toggle,
                  icon: const Icon(Iconsax.eye_slash, color: Colors.black54),
                )
                : null,
      ),
    );
  }
}
