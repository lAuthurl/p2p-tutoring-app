import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:liquid_swipe/PageHelpers/LiquidController.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../models/model_on_boarding.dart';
import '../../screens/on_boarding/on_boarding_page_widget.dart';
import '../../../routes/routes.dart';
import '../../../data/repository/authentication_repository/authentication_repository.dart';

class OnBoardingController extends GetxController {
  final userStorage = GetStorage();
  final controller = LiquidController();
  RxInt currentPage = 0.obs;
  final RxBool isUserInteracting = false.obs;

  bool _isNavigating = false;
  DateTime _lastPageChange = DateTime.now();
  static const _pageChangeCooldown = Duration(milliseconds: 400);

  // =========================================================
  // PAGE CHANGE CALLBACK
  // =========================================================

  int onPageChangedCallback(int activePageIndex) {
    final now = DateTime.now();
    if (now.difference(_lastPageChange) < _pageChangeCooldown) {
      return currentPage.value;
    }
    _lastPageChange = now;
    currentPage.value = activePageIndex;
    return activePageIndex;
  }

  // =========================================================
  // NEXT BUTTON
  // =========================================================

  void animateToNextSlideWithLocalStorage() {
    if (_isNavigating) return;

    final isLastPage = currentPage.value == pages.length - 1;

    if (isLastPage) {
      handleFinish();
    } else {
      final nextPage = currentPage.value + 1;
      controller.animateToPage(page: nextPage);
    }
  }

  // =========================================================
  // SKIP / FINISH
  // =========================================================

  Future<void> handleFinish() async {
    if (_isNavigating) return;
    _isNavigating = true;

    // ✅ Use AuthenticationRepository.markOnboardingComplete() as the
    //    single source of truth for the isFirstTime flag — keeps the key
    //    name and write logic in one place.
    AuthenticationRepository.instance.markOnboardingComplete();

    try {
      final session = await Amplify.Auth.fetchAuthSession();

      if (session.isSignedIn) {
        await Get.offAllNamed(TRoutes.mainDashboard);
      } else {
        await Get.offAllNamed(TRoutes.logIn);
      }
    } catch (_) {
      await Get.offAllNamed(TRoutes.logIn);
    } finally {
      _isNavigating = false;
    }
  }

  // =========================================================
  // HELPERS
  // =========================================================

  void animateToLastSlide() {
    final lastPage = pages.length - 1;
    controller.animateToPage(page: lastPage);
    currentPage.value = lastPage;
  }

  dynamic skip() => handleFinish();

  // =========================================================
  // PAGES
  // =========================================================

  final pages = [
    OnBoardingPageWidget(
      model: OnBoardingModel(
        image: TImages.tOnBoardingImage1,
        title: TTexts.tOnBoardingTitle1,
        subTitle: TTexts.tOnBoardingSubTitle1,
        counterText: TTexts.tOnBoardingCounter1,
        bgColor: TColors.onBoardingPage1Color,
      ),
    ),
    OnBoardingPageWidget(
      model: OnBoardingModel(
        image: TImages.tOnBoardingImage2,
        title: TTexts.tOnBoardingTitle2,
        subTitle: TTexts.tOnBoardingSubTitle2,
        counterText: TTexts.tOnBoardingCounter2,
        bgColor: TColors.onBoardingPage2Color,
      ),
    ),
    OnBoardingPageWidget(
      model: OnBoardingModel(
        image: TImages.tOnBoardingImage3,
        title: TTexts.tOnBoardingTitle3,
        subTitle: TTexts.tOnBoardingSubTitle3,
        counterText: TTexts.tOnBoardingCounter3,
        bgColor: TColors.onBoardingPage3Color,
      ),
    ),
  ];
}
