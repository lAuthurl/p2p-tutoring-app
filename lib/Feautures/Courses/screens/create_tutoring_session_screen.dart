// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../../../../common/widgets/buttons/primary_button.dart';
import '../../../../utils/constants/sizes.dart';
import '../../dashboard/Home/controllers/subject_controller.dart';
import '../controllers/session_creation_controller.dart';

class CreateTutoringSessionScreen extends StatelessWidget {
  const CreateTutoringSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SessionCreationController());
    final subjectController = SubjectController.instance;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text("Create Session"),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TSizes.defaultSpace,
          8,
          TSizes.defaultSpace,
          TSizes.defaultSpace,
        ),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail hero ─────────────────────────────────────────
              Obx(() {
                final thumbnailUrl = controller.selectedThumbnail;
                return Center(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child:
                              thumbnailUrl != null
                                  ? Image.network(
                                    thumbnailUrl,
                                    fit: BoxFit.cover,
                                  )
                                  : Container(
                                    color: colorScheme.primaryContainer
                                        .withValues(alpha: 0.4),
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 40,
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                        ),
                      ),
                      if (thumbnailUrl != null)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Auto-selected",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Thumbnail updates when you pick a subject",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              // ── Step 1: Session details ────────────────────────────────
              _StepCard(
                step: 1,
                title: "Session Details",
                colorScheme: colorScheme,
                theme: theme,
                child: Column(
                  children: [
                    TextFormField(
                      controller: controller.title,
                      decoration: InputDecoration(
                        labelText: "Session Title",
                        prefixIcon: const Icon(
                          LineAwesomeIcons.book_solid,
                          size: 20,
                        ),
                        border: _inputBorder(),
                        enabledBorder: _inputBorder(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        focusedBorder: _inputBorder(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? "Title is required"
                                  : null,
                    ),
                    const SizedBox(height: TSizes.spaceBtwInputFields),
                    TextFormField(
                      controller: controller.description,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Description",
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(
                            LineAwesomeIcons.align_left_solid,
                            size: 20,
                          ),
                        ),
                        border: _inputBorder(),
                        enabledBorder: _inputBorder(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        focusedBorder: _inputBorder(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),

              // ── Step 2: Subject ────────────────────────────────────────
              _StepCard(
                step: 2,
                title: "Subject",
                colorScheme: colorScheme,
                theme: theme,
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue:
                        controller.subjectId.value.isEmpty
                            ? null
                            : controller.subjectId.value,
                    items:
                        subjectController.subjects
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => controller.subjectId.value = v ?? '',
                    decoration: InputDecoration(
                      labelText: "Select a subject",
                      prefixIcon: const Icon(Icons.category_outlined, size: 20),
                      border: _inputBorder(),
                      enabledBorder: _inputBorder(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      focusedBorder: _inputBorder(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                    validator:
                        (v) =>
                            (v == null || v.isEmpty)
                                ? "Please select a subject"
                                : null,
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),

              // ── Step 3: Pricing ────────────────────────────────────────
              Obx(() {
                final free = controller.isFree.value;
                return _StepCard(
                  step: 3,
                  title: "Pricing",
                  colorScheme: colorScheme,
                  theme: theme,
                  child: Column(
                    children: [
                      // Free toggle row
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              free
                                  ? colorScheme.primaryContainer.withValues(
                                    alpha: 0.35,
                                  )
                                  : colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                free
                                    ? colorScheme.primary.withValues(alpha: 0.4)
                                    : colorScheme.outline.withValues(
                                      alpha: 0.25,
                                    ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color:
                                    free
                                        ? colorScheme.primary.withValues(
                                          alpha: 0.12,
                                        )
                                        : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                free
                                    ? Icons.volunteer_activism_outlined
                                    : Icons.money_off_outlined,
                                size: 18,
                                color:
                                    free
                                        ? colorScheme.primary
                                        : colorScheme.onSurface.withValues(
                                          alpha: 0.5,
                                        ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    free
                                        ? "This session is free"
                                        : "Free Session",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          free
                                              ? colorScheme.primary
                                              : colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    free
                                        ? "Students can join at no cost"
                                        : "Toggle to offer at no cost",
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: free,
                              onChanged: (val) {
                                controller.isFree.value = val;
                                if (val) controller.price.clear();
                              },
                            ),
                          ],
                        ),
                      ),

                      // Price field — animates in/out
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child:
                            free
                                ? const SizedBox.shrink()
                                : Padding(
                                  padding: const EdgeInsets.only(
                                    top: TSizes.spaceBtwInputFields,
                                  ),
                                  child: TextFormField(
                                    controller: controller.price,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      labelText: "Base Price",
                                      prefixIcon: const Icon(
                                        LineAwesomeIcons.money_bill_solid,
                                        size: 20,
                                      ),
                                      prefixText: '₦ ',
                                      hintText: "e.g. 2500",
                                      helperText: "Maximum ₦5,000",
                                      border: _inputBorder(),
                                      enabledBorder: _inputBorder(
                                        color: colorScheme.outline.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      focusedBorder: _inputBorder(
                                        color: colorScheme.primary,
                                        width: 1.5,
                                      ),
                                      filled: true,
                                      fillColor: colorScheme.surface,
                                    ),
                                    validator: (v) {
                                      if (free) return null;
                                      if (v == null || v.trim().isEmpty) {
                                        return "Price is required";
                                      }
                                      final parsed = double.tryParse(v.trim());
                                      if (parsed == null) {
                                        return "Enter a valid amount";
                                      }
                                      if (parsed <= 0) {
                                        return "Price must be greater than ₦0";
                                      }
                                      if (parsed >
                                          SessionCreationController
                                              .kMaxPriceNaira) {
                                        return "Cannot exceed ₦${SessionCreationController.kMaxPriceNaira.toStringAsFixed(0)}";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: TSizes.spaceBtwSections),

              // ── Submit ─────────────────────────────────────────────────
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: TPrimaryButton(
                    text:
                        controller.isUploading.value
                            ? "Creating..."
                            : "Create Session",
                    verticalPadding: 16,
                    onPressed:
                        controller.isUploading.value
                            ? null
                            : controller.createSession,
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),
            ],
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _inputBorder({Color? color, double width = 1.0}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: color ?? Colors.transparent,
          width: width,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step card — numbered section container
// ─────────────────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.colorScheme,
    required this.theme,
    required this.child,
  });

  final int step;
  final String title;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$step',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
