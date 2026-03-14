import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../../../../../personalization/controllers/user_controller.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/helper_functions.dart';

class ProfileFormScreen extends StatelessWidget {
  const ProfileFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;
    final colorScheme = Theme.of(context).colorScheme;
    final createdAt =
        controller.currentUser.value?.createdAt?.getDateTimeInUtc();

    return Form(
      key: controller.updateUserProfileFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Full name ─────────────────────────────────────────
          _FormField(
            label: 'Full Name',
            controller: controller.fullName,
            hint: 'Enter your full name',
            icon: LineAwesomeIcons.user,
            iconColor: TColors.primary,
          ),

          const SizedBox(height: TSizes.lg),

          // ── Skills ────────────────────────────────────────────
          _FormField(
            label: 'Skills',
            controller: controller.skills,
            hint: 'e.g. Flutter, Mathematics, Physics',
            icon: LineAwesomeIcons.brain_solid,
            iconColor: Colors.orange,
            maxLines: 2,
          ),

          const SizedBox(height: TSizes.lg),

          // ── About ─────────────────────────────────────────────
          _FormField(
            label: 'About Yourself',
            controller: controller.about,
            hint: 'Your experience, teaching style, etc.',
            icon: LineAwesomeIcons.user_edit_solid,
            iconColor: Colors.teal,
            maxLines: 4,
          ),

          const SizedBox(height: TSizes.xl),

          // ── Save button ───────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.updateUserProfile(),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text(TTexts.tEditProfile),
            ),
          ),

          const SizedBox(height: TSizes.lg),

          Divider(
            height: 1,
            thickness: 0.5,
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),

          const SizedBox(height: TSizes.lg),

          // ── Joined date + delete ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Joined pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: TColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: TColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      createdAt != null
                          ? 'Joined ${THelperFunctions.getFormattedDate(createdAt)}'
                          : 'Joined N/A',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Delete pill
              GestureDetector(
                onTap: () => controller.deleteAccountWarningPopup(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        size: 13,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        TTexts.tDelete,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reusable form field ───────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final Color iconColor;
  final int maxLines;

  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    required this.iconColor,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row with icon
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Input
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: iconColor, width: 1.5),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerLowest,
          ),
        ),
      ],
    );
  }
}
