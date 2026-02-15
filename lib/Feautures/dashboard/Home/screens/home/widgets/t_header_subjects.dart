import 'package:flutter/material.dart';
import '../../../../../../common/widgets/image_text/image_text_vertical.dart';
import '../../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/constants/sizes.dart';
import '../../../controllers/home_controller.dart';

class THeaderSubjects extends StatelessWidget {
  // ---------------- Required Controller Parameter ----------------
  final HomeController controller;

  const THeaderSubjects({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final subjects =
        controller.getFeaturedSubjects(); // Uses isFeatured internally

    return Padding(
      padding: const EdgeInsets.only(left: TSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TSectionHeading(
            title: 'Popular Subjects',
            textColor: TColors.textWhite,
            showActionButton: false,
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          SizedBox(
            height: 80,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: subjects.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, index) {
                final subject = subjects[index];
                return TVerticalImageAndText(
                  image: subject.icon ?? '', // <-- Use Amplify icon field
                  title: subject.name,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? TColors.darkContainer
                          : TColors.lightBackground,
                  textColor: TColors.textWhite,
                  onTap: () {
                    // Optional: navigate to subject details
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
