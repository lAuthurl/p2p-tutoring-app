import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../utils/constants/colors.dart';
import '../../../common/widgets/icons/t_circular_icon.dart';
import '../../dashboard/Home/controllers/favorites_controller.dart';

class TFavouriteIcon extends StatelessWidget {
  const TFavouriteIcon({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final controller = FavoritesController.instance;

    return Obx(() {
      final isFav = controller.favoriteIds.contains(sessionId);
      final isToggling = controller.isToggling(sessionId);

      // While the mutation is in flight: dim the icon and overlay a small
      // spinner. onPressed is still wired up but the _inProgress guard in
      // FavoritesController will ignore any tap that arrives during flight.
      return Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: isToggling ? 0.4 : 1.0,
            child: TCircularIcon(
              icon: isFav ? Iconsax.heart5 : Iconsax.heart,
              color: isFav ? TColors.error : null,
              onPressed:
                  isToggling
                      ? null
                      : () => controller.toggleFavorite(sessionId),
            ),
          ),
          if (isToggling)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: isFav ? TColors.error : TColors.primary,
              ),
            ),
        ],
      );
    });
  }
}
