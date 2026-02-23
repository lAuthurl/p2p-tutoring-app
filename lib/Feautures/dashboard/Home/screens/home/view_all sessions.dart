import 'package:flutter/material.dart';
import 'package:p2p_tutoring_app/utils/constants/colors.dart';
import 'package:p2p_tutoring_app/utils/constants/sizes.dart';
import 'package:p2p_tutoring_app/common/widgets/layouts/grid_layout.dart';
import '../../../../Courses/screens/product_cards/t_session_card_vertical.dart';
import '../../../../../models/ModelProvider.dart';
import '../../../../../utils/device/device_utility.dart';

/// Screen to display all lectures (scrollable grid, no limit)
class AllLecturesScreen extends StatelessWidget {
  final String title;
  final List<TutoringSession> sessions;

  const AllLecturesScreen({
    super.key,
    required this.title,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: TColors.dashboardAppbarBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          children: [
            TGridLayout(
              itemCount: sessions.length,
              itemBuilder:
                  (_, index) => TSessionCardVertical(session: sessions[index]),
            ),
            SizedBox(
              height:
                  TDeviceUtils.getBottomNavigationBarHeight() +
                  TSizes.defaultSpace,
            ),
          ],
        ),
      ),
    );
  }
}
