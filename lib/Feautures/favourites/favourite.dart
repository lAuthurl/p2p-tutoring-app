import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/controllers/tutoring_controller.dart';
import '../../../../common/widgets/icons/t_circular_icon.dart';
import '../../../../common/widgets/layouts/grid_layout.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/device/device_utility.dart';
import '../Courses/screens/product_cards/t_session_card_vertical.dart'; // updated
import '../../../../../common/widgets/appbar/home_appbar.dart';
import '../dashboard/course/screens/dashboard/courses_dashboard.dart';

class FavouriteScreen extends StatelessWidget {
  const FavouriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tutoringController = Get.put(TutoringController());

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
            onPressed: () => Get.to(() => const CoursesDashboard()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              Obx(() {
                final sessions = tutoringController.favoriteSessions();
                return TGridLayout(
                  itemCount: sessions.length,
                  itemBuilder:
                      (_, index) =>
                          TSessionCardVertical(session: sessions[index]),
                );
              }),
              SizedBox(
                height:
                    TDeviceUtils.getBottomNavigationBarHeight() +
                    TSizes.defaultSpace,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
