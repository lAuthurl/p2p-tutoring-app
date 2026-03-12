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
          onPressed: () => Get.to(() => InboxScreen()),
          icon: Icon(Iconsax.message, color: iconColor ?? Colors.black),
        ),

        // Obx re-renders whenever sessionMessages changes.
        // sessionMessages.refresh() is called by the controller both when
        // a new message arrives (_onNewMessage) and when a session is
        // marked read (markSessionRead), so this badge stays in sync
        // with no extra wiring needed here.
        Positioned(
          right: 0,
          top: -2,
          child: Obx(() {
            // Touch sessionMessages so Obx subscribes to its stream.
            // The actual count comes from _unreadCounts via unreadCount().
            // ignore: unnecessary_statement
            controller.sessionMessages.entries; // reactive dependency

            final totalUnread = controller.activeSessions.fold<int>(
              0,
              (sum, session) => sum + controller.unreadCount(session.id),
            );

            if (totalUnread == 0) return const SizedBox.shrink();

            return Container(
              width: TSizes.fontSizeLg,
              height: TSizes.fontSizeLg,
              decoration: BoxDecoration(
                color: counterBgColor ?? Colors.red,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(
                  totalUnread > 99 ? '99+' : totalUnread.toString(),
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
