import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../dashboard/Home/controllers/favorites_controller.dart';
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
    // ✅ FIX: Read directly from FavoritesController.favoriteIds (RxSet).
    //    The old code called tutoringController.favoriteSessions().length
    //    inside Obx — favoriteSessions() is a plain method returning a
    //    filtered list, not a reactive value. Obx had nothing to subscribe
    //    to so the counter never updated.
    //    favoriteIds is an RxSet: any add/remove immediately triggers Obx.
    final favoritesController = FavoritesController.instance;
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
            final count = favoritesController.favoriteIds.length;
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
