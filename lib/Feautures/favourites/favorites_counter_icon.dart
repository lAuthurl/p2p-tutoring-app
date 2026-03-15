import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
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
    final favoritesController = FavoritesController.instance;

    return IconButton(
      onPressed: () {
        favoritesController.reloadForUser();
        Get.to(
          () => FavouriteScreen(homeController: Get.find<HomeController>()),
        );
      },
      icon: Icon(Iconsax.heart, color: iconColor),
    );
  }
}
