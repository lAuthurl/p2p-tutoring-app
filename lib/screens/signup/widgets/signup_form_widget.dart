import 'package:p2p_tutoring_app/utils/validators/validation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../../../../../../common/widgets/buttons/primary_button.dart';
import '../../../../../../utils/constants/sizes.dart';
import '../../../../../../utils/constants/text_strings.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../authentication/controllers/signup_controller.dart';

class SignUpFormWidget extends StatelessWidget {
  const SignUpFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SignUpController>();
    final isDarkMode = Get.isDarkMode;
    return Container(
      padding: const EdgeInsets.only(top: TSizes.xl - 15, bottom: TSizes.xl),
      child: Form(
        key: controller.signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: controller.fullName,
              validator: (value) {
                if (value!.isEmpty) return 'Name cannot be empty';
                return null;
              },
              style: TextStyle(
                color:
                    isDarkMode ? TColors.textDarkPrimary : TColors.textPrimary,
              ),
              cursorColor:
                  isDarkMode ? TColors.textDarkPrimary : TColors.textPrimary,
              decoration: InputDecoration(
                label: Text(
                  TTexts.tFullName,
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? TColors.textDarkPrimary
                            : TColors.textSecondary,
                  ),
                ),
                prefixIcon: Icon(
                  LineAwesomeIcons.user,
                  color:
                      isDarkMode
                          ? TColors.textDarkSecondary
                          : TColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: TSizes.xl - 20),
            TextFormField(
              controller: controller.email,
              validator: (value) => TValidator.validateEmail(value),
              style: TextStyle(
                color:
                    isDarkMode ? TColors.textDarkPrimary : TColors.textPrimary,
              ),
              cursorColor:
                  isDarkMode ? TColors.textDarkPrimary : TColors.textPrimary,
              decoration: InputDecoration(
                label: Text(
                  TTexts.tEmail,
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? TColors.textDarkPrimary
                            : TColors.textSecondary,
                  ),
                ),
                prefixIcon: Icon(
                  LineAwesomeIcons.envelope,
                  color:
                      isDarkMode
                          ? TColors.textDarkSecondary
                          : TColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: TSizes.xl - 20),
            TextFormField(
              controller: controller.phoneNumber,
              validator: (value) {
                if (value!.isEmpty) return 'Phone number cannot be empty';
                return null;
              },
              style: TextStyle(
                color:
                    isDarkMode ? TColors.textDarkPrimary : TColors.textPrimary,
              ),
              cursorColor:
                  isDarkMode ? TColors.textDarkPrimary : TColors.textPrimary,
              decoration: InputDecoration(
                label: Text(
                  TTexts.tPhoneNo,
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? TColors.textDarkPrimary
                            : TColors.textSecondary,
                  ),
                ),
                prefixIcon: Icon(
                  LineAwesomeIcons.phone_solid,
                  color:
                      isDarkMode
                          ? TColors.textDarkSecondary
                          : TColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: TSizes.xl - 20),
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
                cursorColor:
                    isDarkMode ? TColors.textDarkPrimary : TColors.textPrimary,
                validator: (value) => TValidator.validatePassword(value),
                decoration: InputDecoration(
                  label: Text(
                    TTexts.tPassword,
                    style: TextStyle(
                      color:
                          isDarkMode
                              ? TColors.textDarkPrimary
                              : TColors.textSecondary,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.fingerprint,
                    color:
                        isDarkMode
                            ? TColors.textDarkSecondary
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
            const SizedBox(height: TSizes.xl - 10),
            Obx(
              () => TPrimaryButton(
                isLoading: controller.isLoading.value ? true : false,
                text: TTexts.tSignup.tr,
                onPressed:
                    controller.isFacebookLoading.value ||
                            controller.isGoogleLoading.value
                        ? () {}
                        : controller.isLoading.value
                        ? () {}
                        : () => controller.signup(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
