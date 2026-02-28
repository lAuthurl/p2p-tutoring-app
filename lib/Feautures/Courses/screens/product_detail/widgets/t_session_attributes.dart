// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../common/widgets/chips/rounded_choice_chips.dart';
import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../controllers/session_creation_controller.dart';
import '../../../../../models/ModelProvider.dart';

class TSessionAttributes extends StatelessWidget {
  final TutoringSession session;
  final String? tag; // optional tag for controller

  const TSessionAttributes({super.key, required this.session, this.tag});

  @override
  Widget build(BuildContext context) {
    final controllerTag = tag ?? session.id;

    // Safely get the controller with the provided tag
    final controller = Get.find<SessionCreationController>(tag: controllerTag);

    return Obx(() {
      final attrs = controller.sessionAttributes;

      if (attrs.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            attrs.entries.map((entry) {
              final name = entry.key;
              final values = entry.value;

              if (values.isEmpty) return const SizedBox.shrink();

              // Ensure there’s always a selected value
              controller.selectedAttributes.putIfAbsent(
                name,
                () => values.first,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TSectionHeading(title: name, showActionButton: false),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children:
                        values.map((value) {
                          final isSelected =
                              controller.selectedAttributes[name] == value;
                          return TChoiceChip(
                            text: value,
                            selected: isSelected,
                            onSelected:
                                (_) =>
                                    controller.onAttributeSelected(name, value),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
      );
    });
  }
}
