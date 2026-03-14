// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../../../Feautures/dashboard/Home/controllers/subject_controller.dart';
import '../../../common/widgets/shimmers/shimmer.dart';
import '../../../../../data/repository/authentication_repository/authentication_repository.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../routes/routes.dart';
import 'update_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = UserController.instance;
    final colorScheme = Theme.of(context).colorScheme;

    if (!Get.isRegistered<SubjectController>()) {
      Get.lazyPut(() => SubjectController());
    }

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
                              IconButton(
                                onPressed:
                                    () => Get.to(
                                      () => const UpdateProfileScreen(),
                                    ),
                                icon: const Icon(
                                  Icons.tune_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Avatar
                        Obx(() {
                          final user = userController.currentUser.value;
                          final imageUrl = user?.profilePicture;
                          return Stack(
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
                                    userController.imageUploading.value
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
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap:
                                      userController.imageUploading.value
                                          ? null
                                          : () =>
                                              userController
                                                  .uploadUserProfilePicture(),
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
                              ),
                            ],
                          );
                        }),

                        const SizedBox(height: 12),

                        // Name
                        Obx(() {
                          final user = userController.currentUser.value;
                          final name =
                              (user?.username.isNotEmpty ?? false)
                                  ? user!.username
                                  : TTexts.tProfileHeading;
                          return Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          );
                        }),

                        const SizedBox(height: 4),

                        // Email
                        Obx(() {
                          final user = userController.currentUser.value;
                          final email =
                              (user?.email.isNotEmpty ?? false)
                                  ? user!.email
                                  : TTexts.tProfileSubHeading;
                          return Text(
                            email,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Action buttons ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: TTexts.tEditProfile,
                      icon: Icons.edit_outlined,
                      onTap: () => Get.to(() => const UpdateProfileScreen()),
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      label: 'Favourites',
                      icon: Icons.favorite_outline,
                      onTap: () => Get.toNamed(TRoutes.favouritesScreen),
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Menu sections ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: 'Navigate'),
                  _MenuCard(
                    children: [
                      _MenuItem(
                        icon: Icons.home_outlined,
                        iconColor: TColors.primary,
                        title: 'Dashboard',
                        onTap: () => Get.toNamed(TRoutes.mainDashboard),
                      ),
                      _ItemDivider(),
                      _MenuItem(
                        icon: Icons.shopping_bag_outlined,
                        iconColor: Colors.orange,
                        title: 'Checkout',
                        onTap: () => Get.toNamed(TRoutes.checkoutScreen),
                      ),
                      _ItemDivider(),
                      _MenuItem(
                        icon: Icons.calendar_today_outlined,
                        iconColor: Colors.teal,
                        title: 'Bookings',
                        onTap: () => Get.toNamed(TRoutes.bookingsScreen),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _SectionLabel(label: 'Account'),
                  _MenuCard(
                    children: [
                      _MenuItem(
                        icon: LineAwesomeIcons.sign_out_alt_solid,
                        iconColor: Colors.red,
                        title: 'Logout',
                        titleColor: Colors.red,
                        showChevron: false,
                        onTap: _showLogoutModal,
                      ),
                    ],
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

  void _showLogoutModal() {
    Get.defaultDialog(
      title: 'LOGOUT',
      titleStyle: const TextStyle(fontSize: 20),
      content: const Padding(
        padding: EdgeInsets.symmetric(vertical: 15.0),
        child: Text('Are you sure you want to logout?'),
      ),
      confirm: SizedBox(
        width: 120,
        child: ElevatedButton(
          onPressed: () async {
            try {
              Get.back();
              await AuthenticationRepository.instance.logout();
            } catch (e) {
              Get.snackbar('Error', 'Logout failed: $e');
            }
          },
          child: const Text('Yes'),
        ),
      ),
      cancel: SizedBox(
        width: 100,
        child: OutlinedButton(
          onPressed: () => Get.back(),
          child: const Text('No'),
        ),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:
              isPrimary
                  ? TColors.primary
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isPrimary
                    ? TColors.primary
                    : colorScheme.outline.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isPrimary
                      ? Colors.white
                      : colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    isPrimary
                        ? Colors.white
                        : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Menu card ─────────────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Column(children: children),
    );
  }
}

// ── Menu item ─────────────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final bool showChevron;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.showChevron = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? colorScheme.onSurface,
                ),
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Item divider ──────────────────────────────────────────────────────────────
class _ItemDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 66,
      endIndent: 0,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
