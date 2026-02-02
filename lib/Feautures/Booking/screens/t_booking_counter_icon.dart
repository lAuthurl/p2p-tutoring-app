import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../utils/constants/sizes.dart';
import '../controllers/booking_controller.dart';
import 'booking_screen.dart';

class TBookingCounterIcon extends StatelessWidget {
  const TBookingCounterIcon({
    super.key,
    this.iconColor,
    this.counterBgColor,
    this.counterTextColor,
  });

  final Color? iconColor, counterBgColor, counterTextColor;

  @override
  Widget build(BuildContext context) {
    final controller = BookingController.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Stack(
      children: [
        IconButton(
          onPressed: () => Get.to(() => const BookingScreen()),
          icon: Icon(Iconsax.shopping_bag, color: iconColor),
        ),
        Positioned(
          right: 0,
          child: Container(
            width: TSizes.fontSizeLg,
            height: TSizes.fontSizeLg,
            decoration: BoxDecoration(
              color: counterBgColor ?? (dark ? TColors.white : TColors.black),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: Obx(
                () => Text(
                  controller.totalBookedSessions().toString(),
                  style: Theme.of(context).textTheme.labelLarge!.apply(
                    color:
                        counterTextColor ??
                        (dark ? TColors.black : TColors.white),
                    fontSizeFactor: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
