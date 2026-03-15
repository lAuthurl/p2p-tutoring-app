import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../utils/constants/colors.dart';
import '../../../common/widgets/icons/t_circular_icon.dart';
import '../../dashboard/Home/controllers/favorites_controller.dart';

class TFavouriteIcon extends StatelessWidget {
  /// A custom Icon widget to add or remove tutoring sessions from favorites.
  /// Just pass the sessionId, and it handles the logic automatically.
  const TFavouriteIcon({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final controller = FavoritesController.instance;

    return Obx(() {
      final isFav = controller.favoriteIds.contains(sessionId);
      return TCircularIcon(
        icon: isFav ? Iconsax.heart5 : Iconsax.heart,
        color: isFav ? TColors.error : null,
        onPressed: () => controller.toggleFavorite(sessionId),
      );
    });
  }
}
