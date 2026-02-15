import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2p_tutoring_app/common/widgets/chips/rounded_choice_chips.dart';
import 'package:p2p_tutoring_app/common/widgets/texts/section_heading.dart';
import '../../../controllers/tutoring_controller.dart';
import '../../../../../models/ModelProvider.dart';

/// -----------------------------
/// Helper Extension for Nullable Lists
/// -----------------------------
extension NullableListX<T> on List<T>? {
  List<T> get orEmpty => this ?? const [];
}

/// -----------------------------
/// TSessionAttributes Widget
/// -----------------------------
class TSessionAttributes extends StatelessWidget {
  final TutoringSession session;
  final String tutorId; // <-- Required tutorId

  const TSessionAttributes({
    super.key,
    required this.session,
    required this.tutorId, // <-- pass it explicitly
  });

  // ignore: unintended_html_in_doc_comment
  /// Safely convert Amplify JSON -> Map<String,String>
  Map<String, String> _attrs(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, String>) return raw;
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return {};
  }

  /// Extract durations from variations
  List<String> _variationDurations() {
    final vars = session.sessionVariations.orEmpty;
    final set = <String>{};

    for (final v in vars) {
      final attrs = _attrs(v.sessionAttributes);
      final d = attrs['Duration'] ?? attrs['duration'];
      if (d != null && d.isNotEmpty) set.add(d);
    }

    // If only 1 variation exists but no duration stored
    if (set.isEmpty && vars.length == 1) {
      set.add('1hr');
    }

    return set.toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = TutoringController.instance;

    return Obx(() {
      /// ---------------- ATTRIBUTES FROM DB ----------------
      final attributes =
          session.sessionAttributes.orEmpty
              .whereType<SessionAttribute>()
              .toList();

      final variationDurations = _variationDurations();

      /// If backend forgot to send duration attribute → synthesize one
      if (!attributes.any((a) => a.name.toLowerCase() == 'duration') &&
          variationDurations.isNotEmpty) {
        attributes.add(
          SessionAttribute(
            tutorId: tutorId, // <-- use the explicit tutorId
            name: 'Duration',
            values: variationDurations,
          ),
        );
      }

      /// Remove useless attributes
      final attrsToShow =
          attributes.where((a) {
            final n = a.name.toLowerCase();
            return n != 'stock' && n != 'level';
          }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            attrsToShow.map((attribute) {
              final nameLower = attribute.name.toLowerCase();

              /// ---------------- MODE ----------------
              if (nameLower == 'mode') {
                const values = ['Online', 'Offline'];

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

                            return TChoiceChip(
                              text: value,
                              selected: isSelected,
                              onSelected:
                                  (_) => controller.onAttributeSelected(
                                    attribute.name,
                                    value,
                                  ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }

              /// ---------------- NORMAL ATTRIBUTES ----------------
              List<String> values = List<String>.from(attribute.values.orEmpty);

              /// Merge durations from variations
              if (nameLower == 'duration') {
                final set = <String>{};
                set.addAll(values);
                set.addAll(variationDurations);
                set.add('2hr'); // fallback option
                values = set.toList();
              }

              final availableValues = controller
                  .getAttributesAvailabilityInVariation(
                    session.sessionVariations.orEmpty,
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
                              nameLower == 'duration';

                          return TChoiceChip(
                            text: value,
                            selected: isSelected,
                            onSelected:
                                available
                                    ? (_) => controller.onAttributeSelected(
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
