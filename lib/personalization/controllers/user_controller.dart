import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:p2p_tutoring_app/screens/login/login_screen.dart';
import '../../common/widgets/loaders/circular_loader.dart';
import '../../data/repository/authentication_repository/authentication_repository.dart';
import '../../data/repository/user_repository/user_repository.dart';
import '../../data/services/notifications/notification_service.dart';
import '../models/user_model.dart';
import '../../routes/routes.dart';
import '../../utils/constants/enums.dart';
import '../../utils/constants/image_strings.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/helpers/network_manager.dart';
import 'package:p2p_tutoring_app/utils/popups/exports.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  /// Repositories
  Rx<UserModel> user = UserModel.empty().obs;
  final profileLoading = false.obs;
  final hidePassword = false.obs;
  final verifyEmail = TextEditingController();
  final verifyPassword = TextEditingController();
  final userRepository = Get.find<UserRepository>();
  GlobalKey<FormState> reAuthFormKey = GlobalKey<FormState>();

  // Profile Screen Controllers
  final email = TextEditingController();
  final phoneNo = TextEditingController();
  final fullName = TextEditingController();
  final imageUploading = false.obs;
  final profileImageUrl = ''.obs;
  GlobalKey<FormState> updateUserProfileFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    // Don't auto-fetch on init - wait for explicit calls to avoid snackbar errors before overlay is ready
    super.onInit();
  }

  /// Fetch user record from local storage or Amplify
  Future<void> fetchUserRecord({
    bool fetchLatestRecord = false,
    bool showErrorSnackBar = true,
  }) async {
    try {
      if (fetchLatestRecord) {
        profileLoading.value = true;
        final userData = await userRepository.fetchUserDetails();
        user(userData);
      } else {
        if (user.value.id != AuthenticationRepository.instance.getUserID) {
          user.value = UserModel.empty();
        }
        if (user.value.id.isEmpty) {
          profileLoading.value = true;
          final userData = await userRepository.fetchUserDetails();
          user(userData);
        }
      }
    } catch (e) {
      // Avoid showing an annoying warning on automatic startup/redirects where failures
      // are expected (e.g., first run or offline). Only show when explicitly requested.
      if (showErrorSnackBar) {
        TLoaders.warningSnackBar(
          title: 'Warning',
          message: 'Unable to fetch your information. Try again.',
        );
      }
      if (kDebugMode) {
        print('fetchUserRecord failed: $e');
      }
    } finally {
      profileLoading.value = false;
    }
  }

  /// Save user record after registration/login
  Future<void> saveUserRecord({
    UserModel? userData,
    dynamic userCredentials,
  }) async {
    try {
      await fetchUserRecord();
      if (user.value.id.isEmpty) {
        if (userCredentials != null) {
          final fcmToken =
              await TNotificationService.getToken(); // placeholder for device token
          final credUser = userCredentials.user;
          final newUser = UserModel(
            id: credUser.uid,
            fullName: credUser.displayName ?? '',
            email: credUser.email ?? '',
            profilePicture: credUser.photoURL ?? '',
            deviceToken: fcmToken,
            isEmailVerified: true,
            isProfileActive: true,
            updatedAt: DateTime.now(),
            createdAt: DateTime.now(),
            verificationStatus: VerificationStatus.approved,
            phoneNumber: '',
          );

          await userRepository.saveUserRecord(newUser);
          user(newUser);
        } else if (userData != null) {
          await userRepository.saveUserRecord(userData);
          user(userData);
        }
      }
    } catch (e) {
      TLoaders.warningSnackBar(
        title: 'Data not saved',
        message:
            'Something went wrong while saving your information. You can re-save your data in your Profile.',
      );
    }
  }

  /// Re-authenticate user using email & password (wrapper)
  Future<void> reAuthenticateEmailAndPasswordUser() async {
    try {
      await AuthenticationRepository.instance
          .reAuthenticateWithEmailAndPassword(
            verifyEmail.text.trim(),
            verifyPassword.text.trim(),
          );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: e.toString());
    }
  }

  /// Update user profile locally
  Future<void> updateUserProfile() async {
    try {
      TFullScreenLoader.openLoadingDialog(
        'We are updating your information...',
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

      Map<String, dynamic> json = {
        'fullName': fullName.text.trim(),
        'email': email.text.trim(),
      };
      await userRepository.updateSingleField(json);

      user.value.fullName = fullName.text.trim();
      user.value.email = email.text.trim();
      user.value.phoneNumber = phoneNo.text.trim();

      TFullScreenLoader.stopLoading();
      TLoaders.successSnackBar(
        title: 'Congratulations',
        message: 'Your Name has been updated.',
      );
      Get.offNamed(TRoutes.profileScreen);
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  /// Upload profile picture using Amplify Storage
  Future<void> uploadUserProfilePicture() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxHeight: 512,
        maxWidth: 512,
      );

      if (image != null) {
        imageUploading.value = true;
        final uploadedImage = await userRepository.uploadImage(
          'Users/Images/Profile/',
          image,
        );

        profileImageUrl.value = uploadedImage;
        await userRepository.updateSingleField({
          'profilePicture': uploadedImage,
        });
        user.value.profilePicture = uploadedImage;
        user.refresh();

        imageUploading.value = false;
        TLoaders.successSnackBar(
          title: 'Congratulations',
          message: 'Your Profile Image has been updated!',
        );
      }
    } catch (e) {
      imageUploading.value = false;
      TLoaders.errorSnackBar(
        title: 'Oh Snap',
        message: 'Something went wrong: $e',
      );
    }
  }

  /// Update user record with device token
  Future<void> updateUserRecordWithToken(String newToken) async {
    try {
      await fetchUserRecord();
      await userRepository.updateSingleField({'deviceToken': newToken});
      user.value.deviceToken = newToken;
      user.refresh();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update user record: $e',
      );
    }
  }

  /// Delete account confirmation dialog
  void deleteAccountWarningPopup() {
    Get.defaultDialog(
      contentPadding: const EdgeInsets.all(TSizes.md),
      title: 'Delete Account',
      middleText:
          'Are you sure you want to delete your account permanently? This action is not reversible and all of your data will be removed permanently.',
      confirm: ElevatedButton(
        onPressed: () async => deleteUserAccount(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: TSizes.lg),
          child: Text('Delete'),
        ),
      ),
      cancel: OutlinedButton(
        child: const Text('Cancel'),
        onPressed: () => Navigator.of(Get.overlayContext!).pop(),
      ),
    );
  }

  /// Delete user account
  void deleteUserAccount() async {
    try {
      TFullScreenLoader.openLoadingDialog('Processing', TImages.docerAnimation);
      await AuthenticationRepository.instance.deleteAccount();
      TFullScreenLoader.stopLoading();
      Get.offAll(() => LoginScreen());
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.warningSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  /// Logout
  void logout() {
    Get.defaultDialog(
      contentPadding: const EdgeInsets.all(TSizes.md),
      title: 'Logout',
      middleText: 'Are you sure you want to Logout?',
      confirm: ElevatedButton(
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: TSizes.lg),
          child: Text('Confirm'),
        ),
        onPressed: () async {
          Get.defaultDialog(
            title: '',
            barrierDismissible: false,
            backgroundColor: Colors.transparent,
            content: const TCircularLoader(),
          );
          await AuthenticationRepository.instance.logout();
        },
      ),
      cancel: OutlinedButton(
        child: const Text('Cancel'),
        onPressed: () => Navigator.of(Get.overlayContext!).pop(),
      ),
    );
  }

  void assignDataToProfile() {
    fullName.text = user.value.fullName;
    email.text = user.value.email;
    phoneNo.text = user.value.phoneNumber;
  }
}
