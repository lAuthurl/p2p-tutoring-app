// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../../../../common/widgets/images/t_rounded_image.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text("Create Tutoring Session")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                final thumbnailUrl = controller.selectedThumbnail;
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TRoundedImage(
                        width: 100,
                        height: 100,
                        isNetworkImage: thumbnailUrl != null,
                        imageUrl: thumbnailUrl ?? "",
                        borderRadius: 50,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        thumbnailUrl != null
                            ? "Thumbnail auto-selected"
                            : "Select a subject to see thumbnail",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: TSizes.spaceBtwSections),

              TextFormField(
                controller: controller.title,
                decoration: InputDecoration(
                  label: const Text("Session Title"),
                  prefixIcon: const Icon(LineAwesomeIcons.book_solid),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),

              TextFormField(
                controller: controller.description,
                maxLines: 3,
                decoration: InputDecoration(
                  label: const Text("Description"),
                  prefixIcon: const Icon(LineAwesomeIcons.align_left_solid),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),

              TextFormField(
                controller: controller.price,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  label: const Text("Price per session"),
                  prefixIcon: const Icon(LineAwesomeIcons.money_bill_solid),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),

              Obx(
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
                    label: const Text("Subject"),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.isEmpty)
                              ? "Please select a subject"
                              : null,
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: TPrimaryButton(
                    text:
                        controller.isUploading.value
                            ? "Uploading..."
                            : "Create Session",
                    verticalPadding: 16,
                    onPressed:
                        controller.isUploading.value
                            ? null
                            : controller.createSession,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
