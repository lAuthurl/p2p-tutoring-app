import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../common/widgets/image_text/image_text_vertical.dart';
import '../../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/constants/sizes.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/subject_controller.dart';

class THeaderSubjects extends StatelessWidget {
  final HomeController controller;
  const THeaderSubjects({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    final subjectController = Get.find<SubjectController>();
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
            child: Obx(() {
              final subjects = subjectController.featuredSubjects;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: subjects.length,
                itemBuilder: (_, index) {
                  final subject = subjects[index];
                  final isSelected =
                      subjectController.selectedSubject.value?.id == subject.id;
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: TSizes.spaceBtwItems / 2,
                    ),
                    child: GestureDetector(
                      onTap: () => subjectController.selectSubject(subject),
                      child: TVerticalImageAndText(
                        image: subject.icon ?? '',
                        title: subject.name,
                        backgroundColor:
                            isSelected
                                ? TColors.dashboardAppbarBackground
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? TColors.darkContainer
                                    : TColors.lightBackground),
                        textColor: TColors.textWhite,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
