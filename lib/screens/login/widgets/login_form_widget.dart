import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:iconsax/iconsax.dart';
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
          _buildField(
            controller.email,
            TTexts.tEmail,
            LineAwesomeIcons.user,
            validator: TValidator.validateEmail,
          ),
          const SizedBox(height: TSizes.sm),
          Obx(
            () => _buildPasswordField(
              controller.password,
              controller.hidePassword.value,
              () =>
                  controller.hidePassword.value =
                      !controller.hidePassword.value,
            ),
          ),
          const SizedBox(height: TSizes.md),
          Obx(
            () => TPrimaryButton(
              text: TTexts.tLogin,
              isLoading: controller.isLoading.value,
              onPressed: () => controller.emailAndPasswordLogin(),
              backgroundColor: const Color(0xFFEF8460),
              textColor: Colors.white,
              fontSize: 16,
              height: 52, // increased height
              verticalPadding: 12, // ensure text not cut off
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Obx(
                    () => Checkbox(
                      value: controller.rememberMe.value,
                      onChanged: (v) => controller.rememberMe.value = v!,
                      checkColor: Colors.white,
                      activeColor: const Color(0xFFEF8460),
                    ),
                  ),
                  const Text(
                    'Remember me',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ), // white text
                  ),
                ],
              ),
              TextButton(
                onPressed:
                    () =>
                        ForgetPasswordScreen.buildShowModalBottomSheet(context),
                child: const Text(
                  'Forget password?',
                  style: TextStyle(color: Color(0xFFEF8460), fontSize: 12),
                ),
              ),
            ],
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
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.black), // typed text black
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
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFFFE4DB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        labelText: TTexts.tPassword,
        labelStyle: const TextStyle(color: Colors.black87),
        prefixIcon: const Icon(Icons.fingerprint, color: Colors.black54),
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: const Icon(Iconsax.eye_slash, color: Colors.black54),
        ),
      ),
    );
  }
}
