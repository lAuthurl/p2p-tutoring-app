import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2p_tutoring_app/utils/constants/colors.dart';
import '../../../../../Feautures/dashboard/Home/controllers/home_controller.dart';
import '../../../../../Feautures/dashboard/Home/controllers/subject_controller.dart';
import '../../../../../common/widgets/layouts/grid_layout.dart';
import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';
import '../../../../Courses/screens/create_tutoring_session_screen.dart';
import 'view_all sessions.dart';
import 'widgets/header_search_container.dart';
import 'widgets/home_appbar.dart';
import 'widgets/promo_slider.dart';
import 'widgets/t_header_subjects.dart';
import '../../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../Courses/screens/product_cards/t_session_card_vertical.dart';
import '../../../../../models/ModelProvider.dart';

/// HomeScreen with lazy SubjectController initialization
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lazy initialize HomeController if not registered
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }
    final homeController = Get.find<HomeController>();

    // Lazy initialize SubjectController if not registered
    if (!Get.isRegistered<SubjectController>()) {
      Get.lazyPut(() => SubjectController());
    }

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

    // Load all subjects (formerly "featured")
    final allSubjects = subjectController.getFeaturedSubjects(limit: 20);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const CreateTutoringSessionScreen()),
        icon: const Icon(Icons.add),
        label: const Text("Create Session"),
        backgroundColor: TColors.dashboardAppbarBackground,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                  if (allSubjects.isNotEmpty)
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
                children: const [
                  TPromoSlider(
                    banners: [
                      TImages.tutorPromo1,
                      TImages.tutorPromo2,
                      TImages.tutorPromo3,
                    ],
                  ),
                  SizedBox(height: TSizes.spaceBtwSections * 1.5),
                  _FeaturedSection(),
                  SizedBox(height: TSizes.spaceBtwSections * 2),
                  TPromoSlider(
                    banners: [
                      TImages.studentBanner1,
                      TImages.studentBanner2,
                      TImages.studentBanner3,
                    ],
                  ),
                  SizedBox(height: TSizes.spaceBtwSections * 1.5),
                  _PopularSection(),
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

/// Featured Lectures Section (2 Random Popular + 2 Random Recent, changes daily)
class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Removed onPressed: () {} to hide "View All" button
        TSectionHeading(title: 'Featured Lectures'),
        const SizedBox(height: TSizes.spaceBtwItems),
        Obx(() {
          final today = DateTime.now();
          final seed = today.year * 10000 + today.month * 100 + today.day;
          final random = Random(seed);

          List<TutoringSession> pickRandom(
            List<TutoringSession> list,
            int count,
          ) {
            if (list.isEmpty) return [];
            final shuffled = List<TutoringSession>.from(list)..shuffle(random);
            return shuffled.take(count).toList();
          }

          final randomPopular = pickRandom(controller.popularSessions, 2);
          final randomRecent = pickRandom(controller.recentSessions, 2);

          final selectedSessions =
              {
                for (var s in [...randomPopular, ...randomRecent]) s.id: s,
              }.values.toList();

          if (selectedSessions.isEmpty) {
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
            itemCount: selectedSessions.length,
            itemBuilder:
                (_, index) =>
                    TSessionCardVertical(session: selectedSessions[index]),
          );
        }),
      ],
    );
  }
}

/// All Lectures Section (limit 6)
class _PopularSection extends StatelessWidget {
  const _PopularSection();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TSectionHeading(
          title: 'All Lectures',
          onPressed: () {
            final allSessions = [
              ...controller.featuredSessions,
              ...controller.popularSessions,
              ...controller.recentSessions,
            ];

            final uniqueSessions =
                {for (var s in allSessions) s.id: s}.values.toList();

            // Sort by createdAt descending
            uniqueSessions.sort((a, b) {
              final aTime =
                  a.createdAt?.getDateTimeInUtc() ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bTime =
                  b.createdAt?.getDateTimeInUtc() ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bTime.compareTo(aTime);
            });

            // NO limit here because All Lectures screen should show all
            Get.to(
              () => AllLecturesScreen(
                title: 'All Lectures',
                sessions: uniqueSessions,
              ),
            );
          },
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Obx(() {
          final allSessions = [
            ...controller.featuredSessions,
            ...controller.popularSessions,
            ...controller.recentSessions,
          ];

          final uniqueSessions =
              {for (var s in allSessions) s.id: s}.values.toList();

          // Sort by createdAt descending
          uniqueSessions.sort((a, b) {
            final aTime =
                a.createdAt?.getDateTimeInUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                b.createdAt?.getDateTimeInUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

          // **LIMIT to 6 only for HomeScreen**
          final limitedSessions = uniqueSessions.take(6).toList();

          if (limitedSessions.isEmpty) {
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

          return TGridLayout(
            itemCount: limitedSessions.length,
            itemBuilder:
                (_, index) =>
                    TSessionCardVertical(session: limitedSessions[index]),
          );
        }),
      ],
    );
  }
}
