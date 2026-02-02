import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2p_tutoring_app/Feautures/dashboard/Home/controllers/home_controller.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/controllers/tutoring_controller.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/screens/product_cards/t_session_card_vertical.dart';
import 'package:p2p_tutoring_app/common/widgets/layouts/grid_layout.dart';
import 'package:p2p_tutoring_app/common/widgets/texts/section_heading.dart';
import 'package:p2p_tutoring_app/utils/constants/sizes.dart';
import 'package:p2p_tutoring_app/utils/device/device_utility.dart';
import '../../../../Booking/controllers/booking_controller.dart'; // updated
import 'widgets/t_header_subjects.dart';
import 'widgets/header_search_container.dart';
import 'widgets/home_appbar.dart';
import 'widgets/promo_slider.dart';
import '../../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../../../utils/constants/image_strings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    Get.put(BookingController());
    Get.put(TutoringController.instance);

    final featuredSessions = controller.getFeaturedSessions();
    final popularSessions = controller.getPopularSessions();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const TPrimaryHeaderContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  THomeAppBar(),
                  SizedBox(height: TSizes.spaceBtwSections),
                  TSearchContainer(
                    text: 'Search for Lectures or Tutors',
                    showBorder: false,
                  ),
                  SizedBox(height: TSizes.spaceBtwSections),
                  THeaderSubjects(),
                  SizedBox(height: TSizes.spaceBtwSections * 2),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TPromoSlider(
                    banners: [
                      TImages.tutorPromo1,
                      TImages.tutorPromo2,
                      TImages.tutorPromo3,
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections * 1.5),
                  TSectionHeading(title: 'Featured Lectures', onPressed: () {}),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  TGridLayout(
                    itemCount: featuredSessions.length,
                    itemBuilder:
                        (_, index) => TSessionCardVertical(
                          session: featuredSessions[index],
                        ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections * 2),
                  const TPromoSlider(
                    banners: [
                      TImages.studentBanner1,
                      TImages.studentBanner2,
                      TImages.studentBanner3,
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections * 1.5),
                  TSectionHeading(title: 'Popular Lectures', onPressed: () {}),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  TGridLayout(
                    itemCount: popularSessions.length,
                    itemBuilder:
                        (_, index) => TSessionCardVertical(
                          session: popularSessions[index],
                        ),
                  ),
                  SizedBox(
                    height:
                        TDeviceUtils.getBottomNavigationBarHeight() +
                        TSizes.defaultSpace,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
