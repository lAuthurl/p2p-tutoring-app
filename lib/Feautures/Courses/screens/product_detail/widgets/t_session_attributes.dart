import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2p_tutoring_app/common/widgets/chips/rounded_choice_chips.dart';
import 'package:p2p_tutoring_app/common/widgets/texts/section_heading.dart';
import '../../../controllers/tutoring_controller.dart';
import '../../../models/tutoring_session_model.dart';
import '../../../models/session_attribute_model.dart';

class TSessionAttributes extends StatelessWidget {
  final TutoringSessionModel session;
  const TSessionAttributes({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final controller = TutoringController.instance;

    return Obx(() {
      // Start with declared attributes
      final attrs = List<SessionAttributeModel>.from(
        session.sessionAttributes ?? [],
      );

      // Gather durations from variations
      var variationDurations =
          (session.sessionVariations ?? [])
              .map(
                (v) =>
                    (v.sessionAttributes['Duration'] ??
                        v.sessionAttributes['duration'] ??
                        ''),
              )
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList();

      // If no durations found but there's exactly one variation, infer a default duration so users can select it
      if (variationDurations.isEmpty &&
          (session.sessionVariations ?? []).length == 1) {
        final v = session.sessionVariations!.first;
        final dv =
            v.sessionAttributes['Duration'] ??
            v.sessionAttributes['duration'] ??
            '';
        variationDurations = dv.isNotEmpty ? [dv] : ['1hr'];
      }

      // If no Duration attribute declared but variations have durations (or inferred), add synthetic attribute
      if (!attrs.any((a) => a.name.toLowerCase() == 'duration') &&
          variationDurations.isNotEmpty) {
        attrs.add(
          SessionAttributeModel(name: 'Duration', values: variationDurations),
        );
      }

      final attrsToShow =
          attrs.where((a) {
            final n = a.name.toLowerCase();
            return n != 'stock' && n != 'level';
          }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            attrsToShow.map((attribute) {
              final nameLower = attribute.name.toLowerCase();

              // Force 'Mode' to always show Online/Offline options
              if (nameLower == 'mode') {
                final values = ['Online', 'Offline'];
                final availableValues = ['Online', 'Offline'];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TSectionHeading(
                      title: attribute.name,
                      showActionButton: false,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children:
                          values.map((value) {
                            final isSelected =
                                controller.selectedAttributes[attribute.name] ==
                                value;
                            final available = availableValues.contains(value);

                            return TChoiceChip(
                              text: value,
                              selected: isSelected,
                              onSelected:
                                  available
                                      ? (selected) =>
                                          controller.onAttributeSelected(
                                            attribute.name,
                                            value,
                                          )
                                      : null,
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }

              // Duration: combine declared values and variation-derived values
              List<String> values;
              if (nameLower == 'duration') {
                final set = <String>{};
                set.addAll(attribute.values);
                set.addAll(variationDurations);
                // Ensure every session has a '2hr' option available
                set.add('2hr');
                values = set.toList();
              } else {
                values = attribute.values;
              }

              final availableValues = controller
                  .getAttributesAvailabilityInVariation(
                    session.sessionVariations ?? [],
                    attribute.name,
                  );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TSectionHeading(
                    title: attribute.name,
                    showActionButton: false,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children:
                        values.map((value) {
                          final isSelected =
                              controller.selectedAttributes[attribute.name] ==
                              value;
                          final available =
                              availableValues.contains(value) ||
                              attribute.name.toLowerCase() == 'duration' &&
                                  values.contains(value);

                          return TChoiceChip(
                            text: value,
                            selected: isSelected,
                            onSelected:
                                available
                                    ? (selected) =>
                                        controller.onAttributeSelected(
                                          attribute.name,
                                          value,
                                        )
                                    : null,
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
