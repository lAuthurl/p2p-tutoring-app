// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../../../Feautures/checkout/controllers/paystack_card_controller.dart';
import '../../../Feautures/checkout/screens/paystack_card_entry_screen.dart';
import '../../../Feautures/dashboard/Home/controllers/subject_controller.dart';
import '../../../common/widgets/images/t_user_avatar.dart';
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

                  _SectionLabel(label: 'Payment'),
                  _MenuCard(
                    children: [
                      // ✅ Payment card management — tutors add once here,
                      // students can view/update their saved card.
                      // Navigates to PaystackCardEntryScreen which handles
                      // both add and update (prefills if card already saved).
                      _PaymentCardMenuItem(),
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
                        onTap: () => _showLogoutModal(context),
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

  // ── Logout bottom sheet ────────────────────────────────────────────────────
  void _showLogoutModal(BuildContext context) {
    HapticFeedback.mediumImpact();
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder:
          (_) => Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Log out?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You'll need to sign in again\nto access your account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      Get.back();
                      try {
                        await AuthenticationRepository.instance.logout();
                      } catch (e) {
                        Get.snackbar('Error', 'Logout failed: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Log out',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Get.back();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

// ── Payment card menu item ────────────────────────────────────────────────────
/// Shows the saved card type + masked number if one exists, or "Add Card"
/// if none is saved. Tapping always goes to PaystackCardEntryScreen where
/// the user can add or replace their card.
class _PaymentCardMenuItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cardCtrl = Get.put(PaystackCardController());
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final hasCard = cardCtrl.hasCard;
      final card = cardCtrl.savedCard.value;

      return InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Get.to(() => const PaystackCardEntryScreen());
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
                  color: const Color(0xFF0BA4DB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: Color(0xFF0BA4DB),
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCard ? 'Payment Card' : 'Add Payment Card',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (hasCard) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${card.cardType}  ${card.maskedNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 2),
                      Text(
                        'Required for sessions & checkout',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Edit badge when card exists, add icon otherwise.
              if (hasCard)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 11,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
      );
    });
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
