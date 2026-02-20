// ignore_for_file: avoid_print

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
            children: [
              // IMAGE PICKER
              GetBuilder<SessionCreationController>(
                builder:
                    (_) => Column(
                      children: [
                        TRoundedImage(
                          width: 100,
                          height: 100,
                          isNetworkImage: false,
                          imageUrl: controller.selectedImage?.path ?? "",
                          borderRadius: 50,
                          fit: BoxFit.cover,
                        ),
                        TextButton.icon(
                          onPressed: controller.pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text("Upload Thumbnail"),
                        ),
                      ],
                    ),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              // TITLE
              TextFormField(
                controller: controller.title,
                decoration: InputDecoration(
                  label: const Text("Session Title"),
                  prefixIcon: const Icon(LineAwesomeIcons.book_solid),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: TSizes.spaceBtwInputFields),

              // DESCRIPTION
              TextFormField(
                controller: controller.description,
                maxLines: 3,
                decoration: InputDecoration(
                  label: const Text("Description"),
                  prefixIcon: const Icon(LineAwesomeIcons.align_left_solid),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwInputFields),

              // PRICE
              TextFormField(
                controller: controller.price,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  label: const Text("Price per session"),
                  prefixIcon: const Icon(LineAwesomeIcons.money_bill_solid),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwInputFields),

              // SUBJECT DROPDOWN
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

              // SUBMIT BUTTON
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
