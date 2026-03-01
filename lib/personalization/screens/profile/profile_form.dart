import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../../../../../personalization/controllers/user_controller.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/helper_functions.dart';

class ProfileFormScreen extends StatelessWidget {
  const ProfileFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;

    // Safely get the createdAt DateTime from TemporalDateTime
    final createdAt =
        controller.currentUser.value?.createdAt?.getDateTimeInUtc();

    return Form(
      key: controller.updateUserProfileFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ---------------- FULL NAME ----------------
            TextFormField(
              controller: controller.fullName,
              decoration: const InputDecoration(
                label: Text(TTexts.tFullName),
                prefixIcon: Icon(LineAwesomeIcons.user),
              ),
            ),
            const SizedBox(height: TSizes.xl - 10),

            /// ---------------- SKILLS ----------------
            TextFormField(
              controller: controller.skills,
              maxLines: 2,
              decoration: const InputDecoration(
                label: Text("Skills"),
                hintText: "e.g. Flutter, UI/UX Design, Mathematics, Physics",
                prefixIcon: Icon(LineAwesomeIcons.brain_solid),
              ),
            ),
            const SizedBox(height: TSizes.xl - 10),

            /// ---------------- ABOUT YOURSELF ----------------
            TextFormField(
              controller: controller.about,
              maxLines: 4,
              decoration: const InputDecoration(
                label: Text("About Yourself"),
                hintText:
                    "Tell others about yourself, your experience, teaching style, etc.",
                alignLabelWithHint: true,
                prefixIcon: Icon(LineAwesomeIcons.user_edit_solid),
              ),
            ),
            const SizedBox(height: TSizes.xl),

            /// ---------------- SUBMIT BUTTON ----------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.updateUserProfile(),
                child: const Text(TTexts.tEditProfile),
              ),
            ),
            const SizedBox(height: TSizes.xl),

            /// ---------------- JOINED DATE & DELETE ----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text.rich(
                  TextSpan(
                    text: TTexts.tJoined,
                    style: const TextStyle(fontSize: 12),
                    children: [
                      TextSpan(
                        text:
                            createdAt != null
                                ? THelperFunctions.getFormattedDate(createdAt)
                                : 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => controller.deleteAccountWarningPopup(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                    elevation: 0,
                    foregroundColor: Colors.red,
                    side: BorderSide.none,
                  ),
                  child: const Text(TTexts.tDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
