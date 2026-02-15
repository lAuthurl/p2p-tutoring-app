import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../../../../../common/widgets/images/t_rounded_image.dart';
import '../../../../../common/widgets/buttons/primary_button.dart';
import '../../../common/widgets/shimmers/shimmer.dart';
import '../../../../../data/repository/authentication_repository/authentication_repository.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../personalization/controllers/theme_controller.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../routes/routes.dart';
import '../../../../bindings/general_bindings.dart';
import 'update_profile_screen.dart';
import 'widgets/profile_menu.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.instance;
    final userController = UserController.instance;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(LineAwesomeIcons.angle_left_solid),
        ),
        title: Text(
          TTexts.tProfile,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                themeController.isDark.value
                    ? LineAwesomeIcons.sun
                    : LineAwesomeIcons.moon,
              ),
              onPressed: () => themeController.toggleTheme(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          children: [
            // Profile Image
            Stack(
              children: [
                Obx(() {
                  final user = userController.currentUser.value;
                  final imageUrl =
                      (user?.profilePicture?.isNotEmpty ?? false)
                          ? user!.profilePicture!
                          : TImages.tProfileImage;

                  return userController.imageUploading.value
                      ? const TShimmerEffect(width: 80, height: 80, radius: 100)
                      : TRoundedImage(
                        width: 80,
                        height: 80,
                        isNetworkImage:
                            user?.profilePicture?.isNotEmpty ?? false,
                        imageUrl: imageUrl,
                        borderRadius: 50,
                        fit: BoxFit.cover,
                      );
                }),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Obx(() {
                    return GestureDetector(
                      onTap:
                          userController.imageUploading.value
                              ? null
                              : () => userController.uploadUserProfilePicture(),
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: TColors.primary,
                        ),
                        child: const Icon(
                          LineAwesomeIcons.pencil_alt_solid,
                          color: Colors.black,
                          size: 18,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Name & Email
            Obx(() {
              final user = userController.currentUser.value;
              final name =
                  (user?.username.isNotEmpty ?? false)
                      ? user!.username
                      : TTexts.tProfileHeading;
              final email =
                  (user?.email.isNotEmpty ?? false)
                      ? user!.email
                      : TTexts.tProfileSubHeading;

              return Column(
                children: [
                  Text(name, style: Theme.of(context).textTheme.headlineMedium),
                  Text(email, style: Theme.of(context).textTheme.bodyMedium),
                ],
              );
            }),
            const SizedBox(height: 20),

            // Edit Profile Button
            SizedBox(
              width: 200,
              child: TPrimaryButton(
                text: TTexts.tEditProfile,
                onPressed: () => Get.to(() => const UpdateProfileScreen()),
                verticalPadding: 16,
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),

            // Menu Options
            ProfileMenuWidget(
              title: "Home Dashboard",
              icon: Icons.home,
              onPress: () => Get.toNamed(TRoutes.mainDashboard),
            ),
            ProfileMenuWidget(
              title: "Checkout",
              icon: Icons.shopping_bag,
              onPress: () => Get.toNamed(TRoutes.checkoutScreen),
            ),
            ProfileMenuWidget(
              title: "Wishlist",
              icon: Icons.favorite,
              onPress: () => Get.toNamed(TRoutes.favouritesScreen),
            ),
            const Divider(),
            const SizedBox(height: 10),
            ProfileMenuWidget(
              title: "Logout",
              icon: LineAwesomeIcons.sign_out_alt_solid,
              textColor: Colors.red,
              endIcon: false,
              onPress: _showLogoutModal,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutModal() {
    Get.defaultDialog(
      title: "LOGOUT",
      titleStyle: const TextStyle(fontSize: 20),
      content: const Padding(
        padding: EdgeInsets.symmetric(vertical: 15.0),
        child: Text("Are you sure you want to logout?"),
      ),
      confirm: TPrimaryButton(
        onPressed: () async {
          try {
            // 1️⃣ Logout user
            await AuthenticationRepository.instance.logout();

            // 2️⃣ Remove all existing controllers
            Get.deleteAll(force: true);

            // 3️⃣ Re-initialize GeneralBindings
            GeneralBindings().dependencies();

            // 4️⃣ Navigate to Login/Onboarding
            Get.offAllNamed(TRoutes.logIn);
          } catch (e) {
            print('❌ Logout failed: $e');
          }
        },
        text: "Yes",
        verticalPadding: 16,
      ),
      cancel: SizedBox(
        width: 100,
        child: OutlinedButton(
          onPressed: () => Get.back(),
          child: const Text("No"),
        ),
      ),
    );
  }
}
