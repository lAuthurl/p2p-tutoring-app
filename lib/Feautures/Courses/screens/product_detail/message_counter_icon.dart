import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../utils/constants/sizes.dart';
import '../../controllers/tutoring_controller.dart';
import 'chat.dart';

class InboxCounterIcon extends StatelessWidget {
  const InboxCounterIcon({
    super.key,
    this.iconColor,
    this.counterBgColor,
    this.counterTextColor,
  });

  final Color? iconColor, counterBgColor, counterTextColor;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TutoringController>();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => Get.to(() => const InboxScreen()),
          icon: Icon(Iconsax.message, color: iconColor ?? Colors.black),
        ),

        Positioned(
          right: 0,
          top: -2,
          child: Obx(() {
            // ✅ Read unreadCounts (public RxMap) directly.
            // Obx subscribes to the RxMap itself, so any write to
            // unreadCounts[chatId] immediately triggers this rebuild —
            // no proxy, no manual refresh(), no tap required.
            final total = controller.unreadCounts.values.fold(
              0,
              (sum, n) => sum + n,
            );

            if (total == 0) return const SizedBox.shrink();

            return Container(
              width: TSizes.fontSizeLg,
              height: TSizes.fontSizeLg,
              decoration: BoxDecoration(
                color: counterBgColor ?? Colors.red,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(
                  total > 99 ? '99+' : total.toString(),
                  style: TextStyle(
                    color: counterTextColor ?? Colors.white,
                    fontSize: TSizes.fontSizeSm,
                    fontWeight: FontWeight.bold,
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
