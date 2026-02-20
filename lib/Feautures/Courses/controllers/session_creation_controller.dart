// ignore_for_file: public_member_api_docs, prefer_const_constructors, unnecessary_null_aware_assignments, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../../../../models/ModelProvider.dart';
import '../../../personalization/controllers/user_controller.dart';

class SessionCreationController extends GetxController {
  static SessionCreationController get instance => Get.find();

  final formKey = GlobalKey<FormState>();

  // TEXT FIELDS
  final title = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  final duration = TextEditingController();
  final mode = TextEditingController();
  final subjectId = ''.obs;

  final isFeatured = false.obs;
  final isUploading = false.obs;

  XFile? selectedImage;

  // PICK IMAGE
  Future<void> pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage = image;
      update();
    }
  }

  // UPLOAD IMAGE TO S3
  Future<String?> uploadImage() async {
    if (selectedImage == null) return null;

    final filename =
        '${DateTime.now().millisecondsSinceEpoch}_${selectedImage!.name}';
    final storagePath = StoragePath.fromString('Sessions/$filename');

    try {
      // Upload using AWSFile from path
      await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(selectedImage!.path),
        path: storagePath,
      ).result;

      // Optional: get a presigned URL
      final getUrlResult =
          await Amplify.Storage.getUrl(path: storagePath).result;

      return getUrlResult.url.toString();
    } catch (e) {
      Get.snackbar("Error", "Image upload failed: $e");
      return null;
    }
  }

  // CREATE SESSION
  Future<void> createSession() async {
    if (!formKey.currentState!.validate()) return;

    isUploading.value = true;

    try {
      final user = UserController.instance.currentUser.value!;
      final imageUrl = await uploadImage();

      // Fetch Tutor object from DataStore
      final tutorList = await Amplify.DataStore.query(
        Tutor.classType,
        where: Tutor.ID.eq(user.id),
      );
      final tutor = tutorList.firstOrNull;

      // Fetch Subject object from DataStore
      final subjectList = await Amplify.DataStore.query(
        Subject.classType,
        where: Subject.ID.eq(subjectId.value),
      );
      final subject = subjectList.firstOrNull;

      if (tutor == null || subject == null) {
        Get.snackbar("Error", "Tutor or Subject not found");
        return;
      }

      final session = TutoringSession(
        title: title.text.trim(),
        description: description.text.trim(),
        pricePerSession: double.tryParse(price.text) ?? 0,
        isFeatured: isFeatured.value,
        tutor: tutor,
        subject: subject,
        thumbnail: imageUrl,
      );

      await Amplify.DataStore.save(session);

      Get.back();
      Get.snackbar("Success", "Session created successfully!");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isUploading.value = false;
    }
  }
}
