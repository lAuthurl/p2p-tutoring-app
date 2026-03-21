import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../../../../../../utils/constants/colors.dart';
import '../../../../../../personalization/controllers/user_controller.dart';
import '../../../../common/widgets/images/t_network_image.dart';

class ImageWithIcon extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const ImageWithIcon({super.key, this.size = 120, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = UserController.instance.currentUser.value;

      debugPrint('🖼️ ImageWithIcon profilePicture: ${user?.profilePicture}');

      final initials =
          (user?.username != null && user!.username.isNotEmpty)
              ? user.username[0].toUpperCase()
              : '?';

      final imageUrl = user?.profilePicture;

      final Widget initialsAvatar = Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: TColors.primary,
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      return Stack(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child:
                  imageUrl != null && imageUrl.isNotEmpty
                      ? TNetworkImage(
                        imageKeyOrUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                        fallbackWidget: initialsAvatar,
                      )
                      : initialsAvatar,
            ),
          ),

          // Edit icon
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: Colors.white,
                ),
                child: const Icon(
                  LineAwesomeIcons.pencil_alt_solid,
                  color: TColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
