// t_favourite_counter_icon.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../Courses/controllers/tutoring_controller.dart';
import '../dashboard/Home/controllers/home_controller.dart';
import 'favourite.dart';

class TFavouriteCounterIcon extends StatelessWidget {
  const TFavouriteCounterIcon({
    super.key,
    this.iconColor,
    this.counterBgColor,
    this.counterTextColor,
  });

  final Color? iconColor, counterBgColor, counterTextColor;

  @override
  Widget build(BuildContext context) {
    final tutoringController = TutoringController.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Stack(
      children: [
        IconButton(
          onPressed:
              () => Get.to(
                () =>
                    FavouriteScreen(homeController: Get.find<HomeController>()),
              ),
          icon: Icon(Iconsax.heart, color: iconColor),
        ),
        Positioned(
          right: 0,
          child: Obx(() {
            final count = tutoringController.favoriteSessions().length;
            if (count == 0) return const SizedBox.shrink();
            return Container(
              width: TSizes.fontSizeLg,
              height: TSizes.fontSizeLg,
              decoration: BoxDecoration(
                color: counterBgColor ?? (dark ? TColors.white : TColors.black),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.labelLarge!.apply(
                    color:
                        counterTextColor ??
                        (dark ? TColors.black : TColors.white),
                    fontSizeFactor: 0.8,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
