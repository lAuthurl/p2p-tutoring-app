import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2p_tutoring_app/utils/constants/colors.dart';

import '../../../../../common/widgets/form/form_divider_widget.dart';
import '../../../../../common/widgets/form/form_header_widget.dart';
import '../../../../../common/widgets/form/social_footer.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../login/login_screen.dart';
import 'widgets/signup_form_widget.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        backgroundColor:
            isDarkMode ? TColors.darkBackground : TColors.lightBackground,
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header
                Builder(
                  builder: (context) {
                    final h = MediaQuery.of(context).size.height;
                    final imageHeight =
                        h >= 900 ? 0.28 : (h >= 700 ? 0.22 : 0.18);

                    return FormHeaderWidget(
                      image: TImages.tWelcomeScreenImage,
                      title: TTexts.tSignUpTitle,
                      subTitle: TTexts.tSignUpSubTitle,
                      imageAlignment: Alignment.topCenter,
                      imageHeight: imageHeight,
                      titleColor:
                          isDarkMode
                              ? TColors.textDarkPrimary
                              : TColors.textPrimary,
                      subTitleColor:
                          isDarkMode
                              ? TColors.textDarkSecondary
                              : TColors.textSecondary,
                    );
                  },
                ),

                /// Email / Password Signup
                const SignUpFormWidget(),

                const TFormDividerWidget(),

                /// Login link
                SocialFooter(
                  text1: TTexts.tAlreadyHaveAnAccount,
                  text2: TTexts.tLogin,
                  onPressed: () => Get.off(() => const LoginScreen()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
