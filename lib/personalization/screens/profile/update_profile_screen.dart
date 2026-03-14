// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../../../../../common/widgets/shimmers/shimmer.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../personalization/controllers/user_controller.dart';
import 'profile_form.dart';

class UpdateProfileScreen extends StatelessWidget {
  const UpdateProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;
    controller.assignDataToProfile();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero ──────────────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Primary banner
                Container(
                  width: double.infinity,
                  height: 260, // was 240
                  decoration: const BoxDecoration(
                    color: TColors.dashboardAppbarBackground,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                ),

                SafeArea(
                  bottom: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        // Nav row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Get.back(),
                                icon: const Icon(
                                  LineAwesomeIcons.angle_left_solid,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'Edit Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const Spacer(),
                              // Balance the back arrow visually
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tappable avatar
                        Obx(() {
                          final user = controller.currentUser.value;
                          final imageUrl = user?.profilePicture;
                          return GestureDetector(
                            onTap:
                                controller.imageUploading.value
                                    ? null
                                    : () =>
                                        controller.uploadUserProfilePicture(),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child:
                                      controller.imageUploading.value
                                          ? const TShimmerEffect(
                                            width: 86,
                                            height: 86,
                                            radius: 100,
                                          )
                                          : CircleAvatar(
                                            radius: 43,
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.25),
                                            backgroundImage:
                                                (imageUrl != null &&
                                                        imageUrl.isNotEmpty)
                                                    ? NetworkImage(imageUrl)
                                                    : null,
                                            child:
                                                (imageUrl == null ||
                                                        imageUrl.isEmpty)
                                                    ? Text(
                                                      (user?.username != null &&
                                                              user!
                                                                  .username
                                                                  .isNotEmpty)
                                                          ? user.username[0]
                                                              .toUpperCase()
                                                          : '?',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 30,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    )
                                                    : null,
                                          ),
                                ),
                                // Edit badge
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: TColors.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      LineAwesomeIcons.pencil_alt_solid,
                                      color: TColors.primary,
                                      size: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 10),

                        // Name
                        Obx(() {
                          final user = controller.currentUser.value;
                          final name =
                              (user?.username.isNotEmpty ?? false)
                                  ? user!.username
                                  : TTexts.tProfileHeading;
                          return Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          );
                        }),

                        const SizedBox(height: 4),

                        Text(
                          'Tap photo to change',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Form section ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PERSONAL INFO',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: TSizes.md),
                  Container(
                    padding: const EdgeInsets.all(TSizes.defaultSpace),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.12),
                        width: 0.5,
                      ),
                    ),
                    child: ProfileFormScreen(),
                  ),
                  const SizedBox(height: TSizes.defaultSpace),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
