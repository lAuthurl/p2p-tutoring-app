import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../common/widgets/icons/t_circular_icon.dart';
import '../../../../common/widgets/layouts/grid_layout.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/device/device_utility.dart';
import '../Courses/screens/product_cards/t_session_card_vertical.dart';
import '../../../../../common/widgets/appbar/home_appbar.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/controllers/tutoring_controller.dart';
import 'package:p2p_tutoring_app/Feautures/dashboard/Home/controllers/home_controller.dart';

class FavouriteScreen extends StatelessWidget {
  // ---------------- Required Controller ----------------
  final HomeController homeController;

  const FavouriteScreen({super.key, required this.homeController});

  @override
  Widget build(BuildContext context) {
    // Use the singleton instance of TutoringController
    final tutoringController = TutoringController.instance;

    return Scaffold(
      appBar: TEComAppBar(
        showBackArrow: true,
        title: Text(
          'Wishlist',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          TCircularIcon(
            icon: Iconsax.add,
            onPressed:
                () => Get.to(() => homeController), // Use passed controller
          ),
        ],
      ),
      body: Obx(() {
        // Get only favorite sessions
        final favoriteSessions = tutoringController.favoriteSessions();

        if (favoriteSessions.isEmpty) {
          return Center(
            child: Text(
              'No favorites yet!',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              TGridLayout(
                itemCount: favoriteSessions.length,
                itemBuilder:
                    (_, index) =>
                        TSessionCardVertical(session: favoriteSessions[index]),
              ),
              SizedBox(
                height:
                    TDeviceUtils.getBottomNavigationBarHeight() +
                    TSizes.defaultSpace,
              ),
            ],
          ),
        );
      }),
    );
  }
}
