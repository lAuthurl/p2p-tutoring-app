import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:get/get.dart';
// Using bundled Poppins via assets; avoid GoogleFonts network calls

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../authentication/controllers/otp_controller.dart';

class ReAuthenticatePhoneOtpScreen extends StatelessWidget {
  const ReAuthenticatePhoneOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OTPController.instance;
    controller.init();
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.white,
      body: Container(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              TTexts.tOtpTitle,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 80.0,
              ),
            ),
            Text(
              TTexts.tOtpSubTitle.toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 40.0),
            const Text(TTexts.tOtpMessage, textAlign: TextAlign.center),
            const SizedBox(height: 20.0),
            OtpTextField(
              mainAxisAlignment: MainAxisAlignment.center,
              numberOfFields: 6,
              fillColor: Colors.black.withValues(alpha: 0.1),
              filled: true,
              onSubmit: (code) {
                controller.otp = code;
                OTPController.instance.verifyOTP();
              },
            ),
            const SizedBox(height: 20.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    controller.loader.value
                        ? () {}
                        : () => controller.verifyOTP(),
                child: const Text(TTexts.tNext),
              ),
            ),
            const SizedBox(height: 20.0),
            Center(
              child: Obx(
                () => RichText(
                  text: TextSpan(
                    text: "Didn't receive code? ",
                    style: Theme.of(context).textTheme.titleSmall,
                    children: [
                      TextSpan(
                        text: TTexts.resendOTP,
                        recognizer:
                            (controller.secondsRemaining.value > 0)
                                  ? null
                                  : TapGestureRecognizer()
                              ?..onTap = () => controller.resendOTP(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color:
                              (controller.secondsRemaining.value > 0)
                                  ? TColors.disabledBackgroundLight
                                  : TColors.primary,
                        ),
                      ),
                      if (controller.secondsRemaining.value > 0)
                        TextSpan(
                          text: " in ${controller.secondsRemaining.value}s",
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            color: TColors.disabledBackgroundLight,
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
    );
  }
}
