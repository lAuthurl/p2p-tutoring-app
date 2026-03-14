// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/session_creation_controller.dart';
import '../../../../../models/ModelProvider.dart';
import '../../../../../utils/constants/colors.dart';

/// Tutee-facing attribute selector shown on the session detail page.
class TSessionAttributes extends StatelessWidget {
  final TutoringSession session;
  final String? tag;

  const TSessionAttributes({super.key, required this.session, this.tag});

  static const _groupIcons = <String, IconData>{
    'Mode': Icons.videocam_outlined,
    'Duration': Icons.schedule_outlined,
    'Payment': Icons.payment_outlined,
    'Language': Icons.language_outlined,
    'Level': Icons.bar_chart_outlined,
    'Format': Icons.grid_view_outlined,
  };

  IconData _iconFor(String key) => _groupIcons[key] ?? Icons.tune_outlined;

  @override
  Widget build(BuildContext context) {
    final controllerTag = tag ?? session.id;
    final controller = Get.find<SessionCreationController>(tag: controllerTag);
    // ✅ Use colorScheme so the widget inherits the exact same surface
    //    colors as the detail page — no hardcoded hex or manual isDark checks.
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final enabled = controller.enabledAttributes;
      if (enabled.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            enabled.map((groupKey) {
              final options = controller.optionsFor(groupKey);
              if (options.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AttributeGroup(
                  groupKey: groupKey,
                  options: options,
                  icon: _iconFor(groupKey),
                  controller: controller,
                  colorScheme: colorScheme,
                ),
              );
            }).toList(),
      );
    });
  }
}

// ── Attribute Group Card ──────────────────────────────────────────────────────
class _AttributeGroup extends StatelessWidget {
  final String groupKey;
  final List<String> options;
  final IconData icon;
  final SessionCreationController controller;
  final ColorScheme colorScheme;

  const _AttributeGroup({
    required this.groupKey,
    required this.options,
    required this.icon,
    required this.controller,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // ✅ surfaceContainerHighest sits one step above the page surface —
        //    it reads as a card on both light and dark detail backgrounds.
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Group header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: TColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 14, color: TColors.primary),
                ),
                const SizedBox(width: 9),
                Text(
                  groupKey,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),

          // ── Option buttons ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(10),
            child: Obx(() {
              final selected =
                  controller.getSelectedValue(groupKey) ?? options.first;
              return options.length <= 3
                  ? Row(
                    children:
                        options.asMap().entries.map((e) {
                          final idx = e.key;
                          final value = e.value;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: idx < options.length - 1 ? 6 : 0,
                              ),
                              child: _OptionButton(
                                value: value,
                                isSelected: selected == value,
                                colorScheme: colorScheme,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  controller.onAttributeSelected(
                                    groupKey,
                                    value,
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                  )
                  : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        options
                            .map(
                              (value) => _OptionButton(
                                value: value,
                                isSelected: selected == value,
                                colorScheme: colorScheme,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  controller.onAttributeSelected(
                                    groupKey,
                                    value,
                                  );
                                },
                              ),
                            )
                            .toList(),
                  );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Option Button ─────────────────────────────────────────────────────────────
class _OptionButton extends StatelessWidget {
  final String value;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _OptionButton({
    required this.value,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  static const _valueIcons = <String, IconData>{
    'Online': Icons.wifi_rounded,
    'Offline': Icons.location_on_outlined,
    'In-Person': Icons.location_on_outlined,
    '1hr': Icons.hourglass_bottom_rounded,
    '2hr': Icons.hourglass_full_rounded,
    'Before Session': Icons.lock_clock_outlined,
    'After Session': Icons.check_circle_outline_rounded,
    'Beginner': Icons.looks_one_outlined,
    'Intermediate': Icons.looks_two_outlined,
    'Advanced': Icons.looks_3_outlined,
  };

  IconData? get _icon => _valueIcons[value];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: TColors.primary.withValues(alpha: 0.12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
          decoration: BoxDecoration(
            // ✅ Selected: primary fill. Unselected: one level above the card
            //    background so it reads clearly on any theme surface.
            color:
                isSelected
                    ? TColors.primary
                    : colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.9,
                    ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isSelected
                      ? TColors.primary
                      : colorScheme.outline.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: TColors.primary.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_icon != null) ...[
                Icon(
                  _icon,
                  size: 13,
                  color:
                      isSelected
                          ? Colors.white
                          : colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSelected
                            ? Colors.white
                            : colorScheme.onSurface.withValues(alpha: 0.65),
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
