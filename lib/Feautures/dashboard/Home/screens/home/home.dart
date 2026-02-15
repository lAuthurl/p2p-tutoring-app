import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../Feautures/dashboard/Home/controllers/home_controller.dart';
import '../../../../../Feautures/dashboard/Home/controllers/subject_controller.dart';
import '../../../../../common/widgets/layouts/grid_layout.dart';
import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';
import 'widgets/header_search_container.dart';
import 'widgets/home_appbar.dart';
import 'widgets/promo_slider.dart';
import 'widgets/t_header_subjects.dart';
import '../../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../Courses/screens/product_cards/t_session_card_vertical.dart';

/// HomeScreen with loading state check
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    Get.find<SubjectController>();

    return Obx(() {
      if (homeController.isLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      return const _HomeContent();
    });
  }
}

/// Core UI content of HomeScreen
class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    final subjectController = Get.find<SubjectController>();

    final featuredSubjects = subjectController.getFeaturedSubjects(limit: 8);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            TPrimaryHeaderContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const THomeAppBar(),
                  const SizedBox(height: TSizes.spaceBtwSections),
                  const TSearchContainer(
                    text: 'Search for Lectures or Tutors',
                    showBorder: false,
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                  if (featuredSubjects.isNotEmpty)
                    THeaderSubjects(controller: homeController)
                  else
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No subjects available'),
                    ),
                  const SizedBox(height: TSizes.spaceBtwSections * 2),
                ],
              ),
            ),

            Padding(
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
                  const _FeaturedSection(),
                  const SizedBox(height: TSizes.spaceBtwSections * 2),
                  const TPromoSlider(
                    banners: [
                      TImages.studentBanner1,
                      TImages.studentBanner2,
                      TImages.studentBanner3,
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections * 1.5),
                  const _PopularSection(),
                ],
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
    );
  }
}

/// Featured Lectures Section
class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TSectionHeading(title: 'Featured Lectures', onPressed: () {}),
        const SizedBox(height: TSizes.spaceBtwItems),
        Obx(() {
          if (controller.featuredSessions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No featured lectures available.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return TGridLayout(
            itemCount: controller.featuredSessions.length,
            itemBuilder:
                (_, index) => TSessionCardVertical(
                  session: controller.featuredSessions[index],
                ),
          );
        }),
      ],
    );
  }
}

/// Popular + Recent Lectures Section
class _PopularSection extends StatelessWidget {
  const _PopularSection();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TSectionHeading(title: 'All Lectures', onPressed: () {}),
        const SizedBox(height: TSizes.spaceBtwItems),
        Obx(() {
          if (controller.popularSessions.isEmpty &&
              controller.recentSessions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No lectures available.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final allSessions = [
            ...controller.popularSessions,
            ...controller.recentSessions,
          ];

          return TGridLayout(
            itemCount: allSessions.length,
            itemBuilder:
                (_, index) => TSessionCardVertical(session: allSessions[index]),
          );
        }),
      ],
    );
  }
}
