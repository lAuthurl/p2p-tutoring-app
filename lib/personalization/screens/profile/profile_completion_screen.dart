import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../../../../../../utils/constants/colors.dart';
import '../../../../../../personalization/controllers/user_controller.dart';

class ImageWithIcon extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const ImageWithIcon({super.key, this.size = 120, this.onTap});

  @override
  Widget build(BuildContext context) {
    final user = UserController.instance.currentUser.value;

    // Get the first letter of the user's name, fallback to '?'
    final initials =
        (user?.username != null && user!.username.isNotEmpty)
            ? user.username[0].toUpperCase()
            : '?';

    final imageUrl = user?.profilePicture;

    return Stack(
      children: [
        // Profile image or initials
        SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child:
                imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(
                      color: TColors.primary,
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
                    ),
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
  }
}
