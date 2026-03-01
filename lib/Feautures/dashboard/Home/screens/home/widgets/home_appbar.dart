import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2p_tutoring_app/common/widgets/appbar/home_appbar.dart';

import '../../../../../../personalization/controllers/user_controller.dart';
import '../../../../../../personalization/screens/profile/profile_screen.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/constants/sizes.dart';
import '../../../../../Booking/screens/t_booking_counter_icon.dart';

class THomeAppBar extends StatelessWidget {
  const THomeAppBar({super.key});

  Widget _profileAvatar(String? name, String? image) {
    const double avatarRadius = 23; // increased size

    if (image != null && image.isNotEmpty) {
      return CircleAvatar(
        radius: avatarRadius,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: SizedBox(
            width: avatarRadius * 2,
            height: avatarRadius * 2,
            child:
                image.startsWith('http')
                    ? Image.network(image, fit: BoxFit.cover)
                    : Image.asset(image, fit: BoxFit.cover),
          ),
        ),
      );
    }

    // fallback: initials
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

    return CircleAvatar(
      radius: avatarRadius,
      backgroundColor: TColors.primary,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20, // larger font to match bigger avatar
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userController = UserController.instance;
    final user = userController.currentUser.value;
    final name = user?.username ?? 'User';
    final image = user?.profilePicture;

    return TEComAppBar(
      horizontalPadding: EdgeInsets.only(
        left: TSizes.defaultSpace,
        right: TSizes.md,
      ),
      title: GestureDetector(
        onTap: () => Get.to(() => const ProfileScreen()),
        child: Row(
          children: [
            _profileAvatar(name, image),
            const SizedBox(width: TSizes.spaceBtwItems),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Welcome, ',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: Colors.white, // "Welcome," in white
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: name,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: TColors.primary, // Full name in primary color
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      actions: const [
        /// -- Booking counter icon (shows number of booked lectures)
        TBookingCounterIcon(
          iconColor: TColors.white,
          counterBgColor: TColors.black,
          counterTextColor: TColors.white,
        ),
      ],
    );
  }
}
