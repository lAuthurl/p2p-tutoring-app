// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../common/widgets/appbar/home_appbar.dart';
import '../../../../../../personalization/controllers/user_controller.dart';
import '../../../../../../personalization/screens/profile/profile_screen.dart';
import '../../../../../Courses/screens/product_detail/message_counter_icon.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/constants/sizes.dart';
import '../../../../../Booking/screens/t_booking_counter_icon.dart';
import '../../../../../Courses/controllers/tutoring_controller.dart';
import '../../../../../favourites/favorites_counter_icon.dart';

class THomeAppBar extends StatelessWidget {
  const THomeAppBar({super.key});

  Widget _profileAvatar(String? name, String? image) {
    const double avatarRadius = 22;

    final Widget avatarCore;

    if (image != null && image.isNotEmpty) {
      avatarCore = Container(
        width: avatarRadius * 2,
        height: avatarRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: TColors.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: TColors.primary.withValues(alpha: 0.35),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipOval(
          child:
              image.startsWith('http')
                  ? Image.network(image, fit: BoxFit.cover)
                  : Image.asset(image, fit: BoxFit.cover),
        ),
      );
    } else {
      final initials =
          name != null && name.isNotEmpty
              ? name
                  .trim()
                  .split(' ')
                  .map((e) => e[0])
                  .take(2)
                  .join()
                  .toUpperCase()
              : '?';

      avatarCore = Container(
        width: avatarRadius * 2,
        height: avatarRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [TColors.primary, TColors.primary.withValues(alpha: 0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: TColors.primary.withValues(alpha: 0.4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    return Padding(padding: const EdgeInsets.only(left: 8), child: avatarCore);
  }

  @override
  Widget build(BuildContext context) {
    TutoringController.instance;
    final userController = UserController.instance;

    return TEComAppBar(
      horizontalPadding: const EdgeInsets.only(left: 8, right: TSizes.md),
      title: Obx(() {
        final user = userController.currentUser.value;
        final name = user?.username ?? 'User';
        final image = user?.profilePicture;
        final firstName = name.trim().split(' ').first;

        return GestureDetector(
          onTap: () => Get.to(() => const ProfileScreen()),
          child: Row(
            children: [
              _profileAvatar(name, image),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _greeting(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            firstName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('👋', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
      actions: [
        // ── Favourites counter ──────────────────────────────
        const TFavouriteCounterIcon(
          iconColor: TColors.white,
          counterBgColor: Colors.pink,
          counterTextColor: Colors.white,
        ),
        // ── Inbox counter ───────────────────────────────────
        InboxCounterIcon(
          iconColor: TColors.white,
          counterBgColor: Colors.redAccent,
          counterTextColor: Colors.white,
        ),
        // ── Booking counter ─────────────────────────────────
        const TBookingCounterIcon(
          iconColor: TColors.white,
          counterBgColor: TColors.black,
          counterTextColor: TColors.white,
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }
}
