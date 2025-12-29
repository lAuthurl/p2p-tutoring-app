import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/animations/fade_in_animation/animation_design.dart';
import '../../../../../utils/animations/fade_in_animation/fade_in_animation_controller.dart';
import '../../../../../utils/animations/fade_in_animation/fade_in_animation_model.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../login/login_screen.dart';
import '../signup/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FadeInAnimationController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.animationIn();
    });

    return SafeArea(
      child: Scaffold(
        backgroundColor: TColors.darkBackground,
        body: TFadeInAnimation(
          isTwoWayAnimation: false,
          durationInMs: 1200,
          animate: TAnimatePosition(
            bottomAfter: 0,
            bottomBefore: -100,
            leftBefore: 0,
            leftAfter: 0,
            topAfter: 0,
            topBefore: 0,
            rightAfter: 0,
            rightBefore: 0,
          ),
          child: Center(
            child: Container(
              width: 393,
              height: 852,
              decoration: BoxDecoration(
                color: TColors.darkContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  // Hero Image
                  Positioned(
                    left: -19,
                    top: 50,
                    child: SizedBox(
                      width: 432,
                      height: 360,
                      child: Image.asset(
                        TImages.tWelcomeScreenImage,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),

                  // Title
                  Positioned(
                    top: 420,
                    left: 0,
                    right: 0,
                    child: Text(
                      TTexts.tWelcomeTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: TColors.textDarkPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),

                  // Subtitle
                  Positioned(
                    top: 470,
                    left: 33,
                    right: 33,
                    child: Text(
                      TTexts.tWelcomeSubTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: TColors.textDarkSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),

                  // Login Button
                  Positioned(
                    top: 540,
                    left: 33,
                    right: 33,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF8460),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                        elevation: 0,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () => Get.to(() => LoginScreen()),
                      child: const Center(
                        child: Text(
                          TTexts.tLogin,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Sign Up Button
                  Positioned(
                    top: 610,
                    left: 33,
                    right: 33,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF8460),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                        elevation: 0,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () => Get.to(() => const SignupScreen()),
                      child: const Center(
                        child: Text(
                          TTexts.tSignup,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
