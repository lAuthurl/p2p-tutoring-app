import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:p2p_tutoring_app/common/widgets/loaders/circular_loader.dart';

import '../../../models/ModelProvider.dart';
import '../../Feautures/Booking/controllers/booking_controller.dart';
import '../../Feautures/Courses/controllers/tutoring_controller.dart';
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
  // ✅ These are recreated fresh each time the controller is instantiated,
  //    preventing "Multiple widgets used the same GlobalKey" after re-login
  // ---------------------------------------------------------------------------
  late GlobalKey<FormState> updateUserProfileFormKey;
  late GlobalKey<FormState> reAuthFormKey;

  // ---------------------------------------------------------------------------
  // TEXT CONTROLLERS
  // ✅ All created fresh in onInit — never reused after dispose
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
    // ✅ Always create fresh instances — safe after logout/re-login
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
    // ✅ Safe dispose — only dispose if not already disposed
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

      final updatedUser = user.copyWith(
        username: fullName.text.trim(),
        email: email.text.trim(),
        phoneNumber: phoneNo.text.trim(),
        skills:
            skills.text
                .trim()
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
        about: about.text.trim(),
      );

      await Amplify.DataStore.save(updatedUser);

      currentUser.value = updatedUser;
      assignDataToProfile();

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
  // PROFILE IMAGE UPLOAD
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

      final uploadedUrl = await _uploadImageToS3('Users/Images/Profile', image);

      final updatedUser = user.copyWith(profilePicture: uploadedUrl);

      await Amplify.DataStore.save(updatedUser);

      currentUser.value = updatedUser;
      profileImageUrl.value = uploadedUrl;

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

  Future<String> _uploadImageToS3(String folder, XFile image) async {
    final filename = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    final storagePath = StoragePath.fromString('$folder/$filename');

    await Amplify.Storage.uploadFile(
      localFile: AWSFile.fromPath(image.path),
      path: storagePath,
    ).result;

    final urlResult = await Amplify.Storage.getUrl(path: storagePath).result;
    return urlResult.url.toString();
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
          'Are you sure you want to permanently delete your account? This cannot be undone.',
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
