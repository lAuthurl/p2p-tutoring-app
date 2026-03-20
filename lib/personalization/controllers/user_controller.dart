// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:p2p_tutoring_app/common/widgets/loaders/circular_loader.dart';

import '../../../models/ModelProvider.dart';
import '../../Feautures/booking/controllers/booking_controller.dart';
import '../../Feautures/sessions/controllers/tutoring_controller.dart';
import '../../Feautures/dashboard/Home/controllers/home_controller.dart';
import '../../Feautures/dashboard/Home/controllers/subject_controller.dart';
import '../../data/repository/authentication_repository/authentication_repository.dart';
import '../../utils/helpers/network_manager.dart';
import '../../utils/popups/exports.dart';
import '../../utils/constants/image_strings.dart';
import '../../routes/routes.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  // ---------------------------------------------------------------------------
  // STORAGE
  // ---------------------------------------------------------------------------
  final _storage = GetStorage();

  bool get hasSeenOnboarding => _storage.read('HAS_SEEN_ONBOARDING') ?? false;
  bool get isLoggedIn => _storage.read('IS_LOGGED_IN') ?? false;

  void setHasSeenOnboarding(bool value) =>
      _storage.write('HAS_SEEN_ONBOARDING', value);
  void setLoggedIn(bool value) => _storage.write('IS_LOGGED_IN', value);

  // ---------------------------------------------------------------------------
  // ONBOARDING STATE
  // ---------------------------------------------------------------------------
  final isLastPage = false.obs;
  void setIsLastPage(bool value) => isLastPage.value = value;

  // ---------------------------------------------------------------------------
  // USER STATE
  // ---------------------------------------------------------------------------
  final currentUser = Rxn<User>();
  final profileLoading = false.obs;
  final imageUploading = false.obs;
  final hidePassword = false.obs;
  final profileImageUrl = ''.obs;

  // ---------------------------------------------------------------------------
  // FORM KEYS
  // ---------------------------------------------------------------------------
  late GlobalKey<FormState> updateUserProfileFormKey;
  late GlobalKey<FormState> reAuthFormKey;

  // ---------------------------------------------------------------------------
  // TEXT CONTROLLERS
  // ---------------------------------------------------------------------------
  late TextEditingController verifyEmail;
  late TextEditingController verifyPassword;
  late TextEditingController email;
  late TextEditingController phoneNo;
  late TextEditingController fullName;
  late TextEditingController skills;
  late TextEditingController about;

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    updateUserProfileFormKey = GlobalKey<FormState>();
    reAuthFormKey = GlobalKey<FormState>();

    verifyEmail = TextEditingController();
    verifyPassword = TextEditingController();
    email = TextEditingController();
    phoneNo = TextEditingController();
    fullName = TextEditingController();
    skills = TextEditingController();
    about = TextEditingController();
  }

  @override
  void onClose() {
    _safeDispose(verifyEmail);
    _safeDispose(verifyPassword);
    _safeDispose(email);
    _safeDispose(phoneNo);
    _safeDispose(fullName);
    _safeDispose(skills);
    _safeDispose(about);
    super.onClose();
  }

  void _safeDispose(TextEditingController controller) {
    try {
      controller.dispose();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // ✅ STATIC: Resolve a fresh pre-signed S3 URL from a stored key or
  // an old expired pre-signed URL. Call this at display time — never
  // cache the result long-term since URLs expire after 15 minutes.
  // ---------------------------------------------------------------------------
  static Future<String?> resolveS3Url(String? keyOrUrl) async {
    if (keyOrUrl == null || keyOrUrl.isEmpty) return null;

    // Already a plain https URL with no signing params — return as-is
    if (keyOrUrl.startsWith('https://') && !keyOrUrl.contains('X-Amz-')) {
      return keyOrUrl;
    }

    // If it's an old expired pre-signed URL, extract just the path key
    String key = keyOrUrl;
    if (keyOrUrl.startsWith('https://')) {
      try {
        final uri = Uri.parse(keyOrUrl);
        // uri.path starts with '/' — strip the leading slash
        key = uri.path.substring(1);
      } catch (_) {
        return null;
      }
    }

    try {
      final result =
          await Amplify.Storage.getUrl(
            path: StoragePath.fromString(key),
          ).result;
      return result.url.toString();
    } catch (e) {
      debugPrint('resolveS3Url failed for key "$key": $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // FETCH USER
  // ---------------------------------------------------------------------------
  Future<void> fetchUserRecord({
    bool fetchLatestRecord = false,
    bool showErrorSnackBar = true,
  }) async {
    try {
      if (!fetchLatestRecord && currentUser.value != null) return;

      profileLoading.value = true;

      final authUser = await Amplify.Auth.getCurrentUser();
      if (authUser.userId.isEmpty) throw 'No signed-in user found';

      final users = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(authUser.userId),
      );

      if (users.isEmpty) {
        if (showErrorSnackBar) {
          TLoaders.warningSnackBar(
            title: 'Warning',
            message: 'User record not found.',
          );
        }
        currentUser.value = null;
        return;
      }

      currentUser.value = users.first;
      assignDataToProfile();
    } catch (e) {
      if (showErrorSnackBar) {
        TLoaders.warningSnackBar(
          title: 'Warning',
          message: 'Unable to fetch your information.',
        );
      }
      if (kDebugMode) print('fetchUserRecord failed: $e');
    } finally {
      profileLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD ALL USER RELATED DATA
  // ---------------------------------------------------------------------------
  Future<void> loadUserData() async {
    try {
      await fetchUserRecord(fetchLatestRecord: true, showErrorSnackBar: false);
      await BookingController.instance.fetchBookings();
      await TutoringController.instance.fetchSessions();
      await SubjectController.instance.fetchSubjects();
      if (kDebugMode) print('✅ User data loaded successfully.');
    } catch (e) {
      if (kDebugMode) print('❌ loadUserData failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE PROFILE
  // ---------------------------------------------------------------------------
  Future<void> updateUserProfile() async {
    try {
      TFullScreenLoader.openLoadingDialog(
        'Updating your information...',
        TImages.docerAnimation,
      );

      if (!await NetworkManager.instance.isConnected()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      if (!updateUserProfileFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      final user = currentUser.value;
      if (user == null) throw 'No user loaded';

      final updatedSkills =
          skills.text
              .trim()
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

      final updatedAbout = about.text.trim();
      final updatedName = fullName.text.trim();

      // ── Save User record ────────────────────────────────────────
      final updatedUser = user.copyWith(
        username: updatedName,
        email: email.text.trim(),
        phoneNumber: phoneNo.text.trim(),
        skills: updatedSkills,
        about: updatedAbout,
      );

      await Amplify.DataStore.save(updatedUser);
      currentUser.value = updatedUser;
      assignDataToProfile();

      // ── Sync Tutor record + refresh home ─────────────────────────
      await _syncTutorRecord(
        userEmail: updatedUser.email,
        name: updatedName,
        skills: updatedSkills,
        about: updatedAbout,
        image: updatedUser.profilePicture,
      );

      TFullScreenLoader.stopLoading();

      TLoaders.successSnackBar(
        title: 'Updated',
        message: 'Profile updated successfully.',
      );

      Get.offNamed(TRoutes.profileScreen);
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // SYNC TUTOR RECORD
  // ✅ After saving the Tutor, propagates the update to HomeController
  // allSessions and TutoringController caches so every session card and
  // profile screen reflects the new name/image immediately.
  // ---------------------------------------------------------------------------
  Future<void> _syncTutorRecord({
    required String userEmail,
    required String name,
    required List<String> skills,
    required String about,
    String? image,
  }) async {
    try {
      final tutors = await Amplify.DataStore.query(
        Tutor.classType,
        where: Tutor.EMAIL.eq(userEmail),
      );

      if (tutors.isEmpty) {
        if (kDebugMode) {
          print('⚠️ _syncTutorRecord: no Tutor found for $userEmail — skip');
        }
        return;
      }

      final tutor = tutors.first;

      final updatedTutor = tutor.copyWith(
        name: name.isNotEmpty ? name : tutor.name,
        skills: skills.isNotEmpty ? skills : tutor.skills,
        about: about.isNotEmpty ? about : tutor.about,
        // Only update image if one is set — avoids wiping the avatar
        // when the user hasn't changed their picture.
        image: (image != null && image.isNotEmpty) ? image : tutor.image,
      );

      await Amplify.DataStore.save(updatedTutor);

      // Warm TutoringController tutor cache
      if (Get.isRegistered<TutoringController>()) {
        TutoringController.instance.warmTutorCache(updatedTutor);
      }

      // Patch all matching sessions in HomeController so home grid
      // cards immediately show new name and avatar
      if (Get.isRegistered<HomeController>()) {
        HomeController.instance.refreshTutorInSessions(updatedTutor);
      }

      // Warm the User cache in TutoringController so review
      // cards also show the updated username/avatar
      if (currentUser.value != null && Get.isRegistered<TutoringController>()) {
        TutoringController.instance.warmUserCache(currentUser.value!);
      }

      if (kDebugMode) {
        print(
          '✅ _syncTutorRecord: Tutor ${tutor.id} updated and '
          'propagated to home + tutoring caches',
        );
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ _syncTutorRecord failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // PROFILE IMAGE UPLOAD
  // ✅ Stores the S3 key path (not the pre-signed URL) so the image
  // never expires. TUserAvatar resolves a fresh URL at display time.
  // ---------------------------------------------------------------------------
  Future<void> uploadUserProfilePicture() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxHeight: 512,
        maxWidth: 512,
      );

      final user = currentUser.value;
      if (image == null || user == null) return;

      imageUploading.value = true;

      // ✅ Returns S3 key, not a pre-signed URL
      final s3Key = await _uploadImageToS3('Users/Images/Profile', image);

      // Update User record with the S3 key
      final updatedUser = user.copyWith(profilePicture: s3Key);
      await Amplify.DataStore.save(updatedUser);
      currentUser.value = updatedUser;
      profileImageUrl.value = s3Key;

      // Sync key to Tutor record + propagate to home grid
      await _syncTutorRecord(
        userEmail: updatedUser.email,
        name: updatedUser.username,
        skills: updatedUser.skills ?? [],
        about: updatedUser.about ?? '',
        image: s3Key,
      );

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Profile image updated!',
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Upload Failed', message: e.toString());
    } finally {
      imageUploading.value = false;
    }
  }

  // ✅ Returns the S3 key path — NOT a pre-signed URL.
  // Pre-signed URLs expire after 15 min (X-Amz-Expires=900).
  // Store the key and call resolveS3Url() at display time instead.
  Future<String> _uploadImageToS3(String folder, XFile image) async {
    final filename = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    final storagePath = StoragePath.fromString('$folder/$filename');

    await Amplify.Storage.uploadFile(
      localFile: AWSFile.fromPath(image.path),
      path: storagePath,
    ).result;

    // Return the key, not the URL
    return '$folder/$filename';
  }

  // ---------------------------------------------------------------------------
  // REAUTHENTICATION
  // ---------------------------------------------------------------------------
  Future<void> reAuthenticateEmailAndPasswordUser() async {
    try {
      await Amplify.Auth.signIn(
        username: verifyEmail.text.trim(),
        password: verifyPassword.text.trim(),
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE ACCOUNT
  // ---------------------------------------------------------------------------
  void deleteAccountWarningPopup() {
    Get.defaultDialog(
      title: 'Delete Account',
      middleText:
          'Are you sure you want to permanently delete your account? '
          'This cannot be undone.',
      confirm: ElevatedButton(
        onPressed: deleteUserAccount,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        child: const Text('Delete'),
      ),
      cancel: OutlinedButton(
        onPressed: () => Navigator.of(Get.overlayContext!).pop(),
        child: const Text('Cancel'),
      ),
    );
  }

  Future<void> deleteUserAccount() async {
    try {
      TFullScreenLoader.openLoadingDialog(
        'Processing...',
        TImages.docerAnimation,
      );

      await Amplify.Auth.deleteUser();

      TFullScreenLoader.stopLoading();
      Get.offAllNamed(TRoutes.logIn);
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.warningSnackBar(title: 'Error', message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------
  void logout() {
    Get.defaultDialog(
      title: 'Logout',
      middleText: 'Are you sure you want to logout?',
      confirm: ElevatedButton(
        child: const Text('Confirm'),
        onPressed: () async {
          Get.dialog(const TCircularLoader(), barrierDismissible: false);
          await AuthenticationRepository.instance.logout();
        },
      ),
      cancel: OutlinedButton(
        onPressed: () => Navigator.of(Get.overlayContext!).pop(),
        child: const Text('Cancel'),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ASSIGN DATA TO CONTROLLERS
  // ---------------------------------------------------------------------------
  void assignDataToProfile() {
    fullName.text = currentUser.value?.username ?? '';
    email.text = currentUser.value?.email ?? '';
    phoneNo.text = currentUser.value?.phoneNumber ?? '';
    profileImageUrl.value = currentUser.value?.profilePicture ?? '';
    skills.text = (currentUser.value?.skills ?? []).join(', ');
    about.text = currentUser.value?.about ?? '';
  }
}
