import 'package:p2p_tutoring_app/utils/validators/validation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../../../../../../common/widgets/buttons/primary_button.dart';
import '../../../../../../utils/constants/sizes.dart';
import '../../../../../../utils/constants/text_strings.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../authentication/controllers/login_controller.dart';
import '../../forget_password/forget_password_options/forget_password_model_bottom_sheet.dart';

class LoginFormWidget extends StatelessWidget {
  const LoginFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();
    final isDarkMode = Get.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: TSizes.xl),
      child: Form(
        key: controller.loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// -- Email Field
            TextFormField(
              validator: (value) => TValidator.validateEmail(value),
              controller: controller.email,
              style: TextStyle(
                color:
                    isDarkMode ? TColors.textDarkPrimary : TColors.textPrimary,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  LineAwesomeIcons.user,
                  color:
                      isDarkMode
                          ? TColors.textDarkSecondary
                          : TColors.textSecondary,
                ),
                labelText: TTexts.tEmail,
                hintText: TTexts.tEmail,
                labelStyle: TextStyle(
                  color:
                      isDarkMode
                          ? TColors.textDarkPrimary
                          : TColors.textSecondary,
                ),
                hintStyle: TextStyle(
                  color:
                      isDarkMode
                          ? TColors.textDarkPrimary
                          : TColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: TSizes.xl - 20),

            /// -- Password Field
            Obx(
              () => TextFormField(
                obscureText: controller.hidePassword.value,
                controller: controller.password,
                style: TextStyle(
                  color:
                      isDarkMode
                          ? TColors.textDarkPrimary
                          : TColors.textPrimary,
                ),
                validator:
                    (value) => TValidator.validateEmptyText('Password', value),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.fingerprint,
                    color:
                        isDarkMode
                            ? TColors.textDarkSecondary
                            : TColors.textSecondary,
                  ),
                  labelText: TTexts.tPassword,
                  hintText: TTexts.tPassword,
                  labelStyle: TextStyle(
                    color:
                        isDarkMode
                            ? TColors.textDarkPrimary
                            : TColors.textSecondary,
                  ),
                  hintStyle: TextStyle(
                    color:
                        isDarkMode
                            ? TColors.textDarkPrimary
                            : TColors.textSecondary,
                  ),
                  suffixIcon: IconButton(
                    onPressed:
                        () =>
                            controller.hidePassword.value =
                                !controller.hidePassword.value,
                    icon: const Icon(Iconsax.eye_slash),
                  ),
                ),
              ),
            ),
            const SizedBox(height: TSizes.xl - 20),

            // Forgot password button moved below the login button

            /// -- LOGIN BTN
            Obx(
              () => TPrimaryButton(
                isLoading: controller.isLoading.value ? true : false,
                text: TTexts.tLogin.tr,
                onPressed:
                    controller.isFacebookLoading.value ||
                            controller.isGoogleLoading.value
                        ? () {}
                        : controller.isLoading.value
                        ? () {}
                        : () => controller.emailAndPasswordLogin(),
              ),
            ),

            const SizedBox(height: TSizes.sm),

            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed:
                    () =>
                        ForgetPasswordScreen.buildShowModalBottomSheet(context),
                child: Text(
                  TTexts.tForgetPassword,
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? TColors.textDarkSecondary
                            : TColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
