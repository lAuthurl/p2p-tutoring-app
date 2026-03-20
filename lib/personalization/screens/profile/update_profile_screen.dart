// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../../../../../common/widgets/shimmers/shimmer.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../personalization/controllers/user_controller.dart';
import '../../../common/widgets/images/t_user_avatar.dart';
import 'profile_form.dart';

// FIX: converted to StatefulWidget so assignDataToProfile() is called in
// initState, not inside build() — which caused "setState during build".
class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  late final UserController _controller;

  @override
  void initState() {
    super.initState();
    _controller = UserController.instance;
    // Safe to call here — not inside a build phase
    _controller.assignDataToProfile();
  }

  @override
  Widget build(BuildContext context) {
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
                Container(
                  width: double.infinity,
                  height: 260,
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
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tappable avatar
                        Obx(() {
                          final user = _controller.currentUser.value;
                          final imageUrl = user?.profilePicture;
                          return GestureDetector(
                            onTap:
                                _controller.imageUploading.value
                                    ? null
                                    : () =>
                                        _controller.uploadUserProfilePicture(),
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
                                      _controller.imageUploading.value
                                          ? const TShimmerEffect(
                                            width: 86,
                                            height: 86,
                                            radius: 100,
                                          )
                                          : TUserAvatar(
                                            imageKeyOrUrl: imageUrl,
                                            radius: 43,
                                            fallbackInitial:
                                                user?.username ?? '?',
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.25),
                                            foregroundColor: Colors.white,
                                          ),
                                ),
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

                        Obx(() {
                          final user = _controller.currentUser.value;
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
