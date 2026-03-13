// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../common/widgets/chips/rounded_choice_chips.dart';
import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../controllers/session_creation_controller.dart';
import '../../../../../models/ModelProvider.dart';

/// Tutee-facing attribute selector shown on the session detail page.
///
/// Rules:
/// • Only attribute groups the tutor enabled (i.e. saved as
///   [SessionAttribute] records) are shown.
/// • Each group is a single-select row — the tutee picks exactly one value.
/// • If no value has been selected yet the first option is highlighted
///   automatically (controller seeds this in [initializeAttributesForSession]).
/// • If both default values exist, both chips are shown; if only one was
///   saved the group still renders but with just that chip.
class TSessionAttributes extends StatelessWidget {
  final TutoringSession session;
  final String? tag;

  const TSessionAttributes({super.key, required this.session, this.tag});

  @override
  Widget build(BuildContext context) {
    final controllerTag = tag ?? session.id;
    final controller = Get.find<SessionCreationController>(tag: controllerTag);

    return Obx(() {
      // enabledAttributes drives which groups to show
      final enabled = controller.enabledAttributes;
      if (enabled.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            enabled.map((groupKey) {
              final options = controller.optionsFor(groupKey);
              if (options.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TSectionHeading(title: groupKey, showActionButton: false),
                    const SizedBox(height: 6),
                    Obx(() {
                      final selected =
                          controller.getSelectedValue(groupKey) ??
                          options.first;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children:
                            options.map((value) {
                              final isSelected = selected == value;
                              return TChoiceChip(
                                text: value,
                                selected: isSelected,
                                onSelected:
                                    (_) => controller.onAttributeSelected(
                                      groupKey,
                                      value,
                                    ),
                              );
                            }).toList(),
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
      );
    });
  }
}
