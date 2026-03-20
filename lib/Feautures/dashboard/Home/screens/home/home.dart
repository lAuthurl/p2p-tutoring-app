// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2p_tutoring_app/utils/constants/colors.dart';
import '../../../../../Feautures/dashboard/Home/controllers/home_controller.dart';
import '../../../../../Feautures/dashboard/Home/controllers/subject_controller.dart';
import '../../../../../common/widgets/layouts/grid_layout.dart';
import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';
import '../../../../sessions/screens/session_creation/create_tutoring_session_screen.dart';
import 'view_all_sessions.dart';
import 'widgets/header_search_container.dart';
import 'widgets/home_appbar.dart';
import 'widgets/promo_slider.dart';
import 'widgets/t_header_subjects.dart';
import '../../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../sessions/screens/product_cards/t_session_card_vertical.dart';

/// HomeScreen with reactive session filtering and search
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    final subjectController = Get.find<SubjectController>();
    final searchController = TextEditingController();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
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
                  TSearchContainer(
                    controller: searchController,
                    hintText: 'Search for Lectures or Tutors',
                    showBorder: false,
                    onChanged: (value) {
                      homeController.updateSearch(value);
                    },
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                  Obx(() {
                    final featuredSubjects = subjectController.featuredSubjects;
                    return featuredSubjects.isNotEmpty
                        ? THeaderSubjects(controller: homeController)
                        : const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No subjects found'),
                        );
                  }),
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

// ---------------------------------------------------------------------------
// Featured Lectures Section
// ---------------------------------------------------------------------------
// The controller's _applyFilters() already ranks sessions by composite score
// into featuredSessions — we just read it directly. No random shuffle needed.
// ---------------------------------------------------------------------------

class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TSectionHeading(title: 'Featured Lectures'),
        const SizedBox(height: TSizes.spaceBtwItems),
        Obx(() {
          final featured = controller.featuredSessions;

          if (featured.isEmpty) {
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
            itemCount: featured.length,
            itemBuilder:
                (_, index) => TSessionCardVertical(session: featured[index]),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// All Lectures Section (limit 6, sorted newest-first)
// ---------------------------------------------------------------------------
// filteredSessions is now pre-sorted by createdAt descending in the controller,
// so .take(6) naturally gives the 6 most recent sessions.
// ---------------------------------------------------------------------------

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
            // filteredSessions is already newest-first — dedupe and pass through
            final uniqueSessions =
                {
                  for (var s in controller.filteredSessions) s.id: s,
                }.values.toList();
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
          // filteredSessions is already sorted newest-first by the controller.
          // Dedupe by id then take 6 — no manual sort needed here.
          final uniqueSessions =
              {
                for (var s in controller.filteredSessions) s.id: s,
              }.values.toList();

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
