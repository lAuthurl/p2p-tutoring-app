import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../personalization/controllers/user_controller.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../images/t_rounded_image.dart';

/// A reusable custom drawer widget displaying account info and menu items.
class TDrawer extends StatelessWidget {
  const TDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = UserController.instance;
    final user = userController.currentUser.value; // Updated to currentUser
    final networkImage = user?.profilePicture ?? '';
    final image =
        networkImage.isNotEmpty ? networkImage : TImages.tProfileImage;

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => Get.toNamed(TRoutes.profileScreen),
            child: Container(
              color: TColors.textDarkSecondary,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile image
                  TRoundedImage(
                    width: 60,
                    height: 60,
                    isNetworkImage: networkImage.isNotEmpty,
                    fit: BoxFit.fill,
                    imageUrl: image,
                    borderRadius: 50,
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    user?.username ?? 'Guest',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: TColors.dark,
                    ),
                  ),
                  // Email
                  Text(
                    user?.email ?? '',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.apply(color: TColors.dark),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Drawer menu items
          ..._drawerItems(),

          const Spacer(),
        ],
      ),
    );
  }

  /// Builds predefined drawer items
  List<Widget> _drawerItems() {
    return [
      _buildDrawerItem(
        icon: Iconsax.user,
        title: "Profile",
        onTap: () => Get.toNamed(TRoutes.profileScreen),
      ),
      _buildDrawerItem(
        icon: Iconsax.home,
        title: "Main Dashboard",
        onTap: () => Get.toNamed(TRoutes.mainDashboard),
      ),
      _buildDrawerItem(
        icon: Iconsax.shopping_cart,
        title: "Cart",
        onTap: () => Get.toNamed(TRoutes.cartScreen),
      ),
      _buildDrawerItem(
        icon: Iconsax.shopping_bag,
        title: "Checkout",
        onTap: () => Get.toNamed(TRoutes.checkoutScreen),
      ),
      _buildDrawerItem(
        icon: Iconsax.heart,
        title: "Wishlist",
        onTap: () => Get.toNamed(TRoutes.favouritesScreen),
      ),
    ];
  }

  /// Helper to build a drawer menu item
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: onTap,
    );
  }
}
