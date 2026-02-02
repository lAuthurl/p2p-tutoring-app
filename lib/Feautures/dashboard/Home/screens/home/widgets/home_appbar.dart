import 'package:p2p_tutoring_app/common/widgets/appbar/home_appbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../personalization/screens/profile/profile_screen.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/constants/text_strings.dart';
import '../../../../../../utils/constants/sizes.dart';
import '../../../../../Booking/screens/t_booking_counter_icon.dart';

class THomeAppBar extends StatelessWidget {
  const THomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return TEComAppBar(
      horizontalPadding: EdgeInsets.only(
        left: TSizes.defaultSpace,
        right: TSizes.md,
      ),
      title: GestureDetector(
        onTap: () => Get.to(() => const ProfileScreen()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TTexts.homeAppbarTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium!.apply(color: TColors.grey),
            ),
            Text(
              TTexts.homeAppbarSubTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall!.apply(color: TColors.white),
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
