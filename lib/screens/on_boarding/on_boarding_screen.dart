import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../../utils/constants/colors.dart';
import '../../authentication/controllers/on_boarding_controller.dart';
import '../../../../../utils/popups/exports.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../bindings/app_bindings.dart';
import '../../../authentication/controllers/login_controller.dart';
import '../../../routes/routes.dart';
import '../../data/repository/authentication_repository/authentication_repository.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final obController = Get.find<OnBoardingController>();
    final loginController = Get.find<LoginController>();

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          /// Liquid Swipe
          GestureDetector(
            onPanStart: (_) => obController.isUserInteracting.value = true,
            onPanEnd: (_) => obController.isUserInteracting.value = false,
            onPanCancel: () => obController.isUserInteracting.value = false,
            child: LiquidSwipe(
              pages: obController.pages,
              enableSideReveal: true,
              liquidController: obController.controller,
              onPageChangeCallback: obController.onPageChangedCallback,
              waveType: WaveType.circularReveal,
            ),
          ),

          /// Swipe hint icon
          Obx(
            () => Positioned(
              bottom: 120,
              right: 20,
              child: AnimatedOpacity(
                opacity: obController.isUserInteracting.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(
                  Icons.arrow_back_ios,
                  size: 32,
                  color: TColors.iconPrimaryDark,
                ),
              ),
            ),
          ),

          /// Next Button
          Positioned(
            bottom: 42,
            right: 28,
            child: OutlinedButton(
              onPressed: () async {
                // Check if Remember Me is enabled
                final remember = loginController.rememberMe.value;
                final email = loginController.email.text.trim();
                final password = loginController.password.text;

                if (remember && email.isNotEmpty && password.isNotEmpty) {
                  try {
                    TFullScreenLoader.openLoadingDialog(
                      'Logging you in...',
                      TImages.docerAnimation,
                    );

                    // Auto-login
                    await AuthenticationRepository.instance
                        .loginWithEmailAndPassword(email, password);

                    // Inject app controllers
                    AppBindings().dependencies();

                    TFullScreenLoader.stopLoading();

                    // Navigate to Home
                    Get.offAllNamed(TRoutes.home);
                    return;
                  } catch (e) {
                    TFullScreenLoader.stopLoading();
                    TLoaders.errorSnackBar(
                      title: 'Auto-login Failed',
                      message: e.toString(),
                    );
                  }
                }

                // Otherwise, go to next onboarding slide
                obController.animateToNextSlideWithLocalStorage();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: TColors.borderLight, width: 1),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
                minimumSize: const Size(44, 44),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: TColors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: TColors.textWhite,
                  size: 18,
                ),
              ),
            ),
          ),

          /// Skip Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: ElevatedButton(
              onPressed: obController.skip,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.black,
                foregroundColor: TColors.textWhite,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          /// Page Indicator
          Obx(
            () => Positioned(
              bottom: 18,
              left: 28,
              child: AnimatedSmoothIndicator(
                count: obController.pages.length,
                activeIndex: obController.currentPage.value,
                effect: const ExpandingDotsEffect(
                  activeDotColor: TColors.dark,
                  dotColor: TColors.grey,
                  dotWidth: 12,
                  dotHeight: 12,
                  expansionFactor: 3.0,
                  spacing: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
