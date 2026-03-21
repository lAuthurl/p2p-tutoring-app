// ignore_for_file: avoid_print

import 'dart:convert';

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
  // STATIC: Resolve a fresh pre-signed S3 URL
  // ---------------------------------------------------------------------------
  static Future<String?> resolveS3Url(String? keyOrUrl) async {
    if (keyOrUrl == null || keyOrUrl.isEmpty) return null;

    if (keyOrUrl.startsWith('https://') && !keyOrUrl.contains('X-Amz-')) {
      return keyOrUrl;
    }

    String key = keyOrUrl;
    if (keyOrUrl.startsWith('https://')) {
      try {
        final uri = Uri.parse(keyOrUrl);
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
  // FETCH USER — AppSync direct, no DataStore
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

      const query = '''
        query GetUser(\$id: ID!) {
          getUser(id: \$id) {
            id username email phoneNumber profilePicture
            deviceToken isEmailVerified isProfileActive
            role verificationStatus skills about profileCompleted
            createdAt updatedAt
          }
        }
      ''';

      final res =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: query,
                  variables: {'id': authUser.userId},
                ),
              )
              .response;

      if (res.errors.isNotEmpty || res.data == null) {
        debugPrint('❌ fetchUserRecord AppSync errors: ${res.errors}');
        if (showErrorSnackBar) {
          TLoaders.warningSnackBar(
            title: 'Warning',
            message: 'Unable to fetch your information.',
          );
        }
        return;
      }

      final decoded = jsonDecode(res.data!) as Map<String, dynamic>;
      final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
      final raw = root['getUser'] as Map<String, dynamic>?;

      debugPrint(
        '🌐 fetchUserRecord AppSync profilePicture: ${raw?['profilePicture']}',
      );

      if (raw == null) {
        if (showErrorSnackBar) {
          TLoaders.warningSnackBar(
            title: 'Warning',
            message: 'User record not found.',
          );
        }
        currentUser.value = null;
        return;
      }

      final freshUser = User(
        id: raw['id'] as String,
        username: raw['username'] as String? ?? '',
        email: raw['email'] as String? ?? '',
        phoneNumber: raw['phoneNumber'] as String?,
        profilePicture: raw['profilePicture'] as String?,
        deviceToken: raw['deviceToken'] as String?,
        isEmailVerified: raw['isEmailVerified'] as bool?,
        isProfileActive: raw['isProfileActive'] as bool?,
        role: raw['role'] as String?,
        verificationStatus: raw['verificationStatus'] as String?,
        skills: (raw['skills'] as List?)?.cast<String>(),
        about: raw['about'] as String?,
        profileCompleted: raw['profileCompleted'] as bool?,
      );

      currentUser.value = freshUser;
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
  // UPDATE PROFILE — AppSync direct mutation
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

      // ── Get current _version for conflict detection ──────────────
      const getDoc = '''
        query GetUser(\$id: ID!) {
          getUser(id: \$id) {
            id _version
          }
        }
      ''';

      final getRes =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: getDoc,
                  variables: {'id': user.id},
                ),
              )
              .response;

      int version = 1;
      if (getRes.errors.isEmpty && getRes.data != null) {
        final decoded = jsonDecode(getRes.data!) as Map<String, dynamic>;
        final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
        final obj = root['getUser'] as Map<String, dynamic>?;
        final v = obj?['_version'];
        if (v != null) version = (v as num).toInt();
      }

      // ── Mutation ─────────────────────────────────────────────────
      const mutDoc = '''
        mutation UpdateUser(\$input: UpdateUserInput!) {
          updateUser(input: \$input) {
            id username email phoneNumber profilePicture
            skills about role profileCompleted _version
          }
        }
      ''';

      final mutRes =
          await Amplify.API
              .mutate(
                request: GraphQLRequest<String>(
                  document: mutDoc,
                  variables: {
                    'input': {
                      'id': user.id,
                      'username': updatedName,
                      'email': email.text.trim(),
                      'phoneNumber': phoneNo.text.trim(),
                      'skills': updatedSkills,
                      'about': updatedAbout,
                      '_version': version,
                    },
                  },
                ),
              )
              .response;

      if (mutRes.errors.isNotEmpty) {
        throw mutRes.errors.first.message;
      }

      // ── Update local state ────────────────────────────────────────
      final updatedUser = user.copyWith(
        username: updatedName,
        email: email.text.trim(),
        phoneNumber: phoneNo.text.trim(),
        skills: updatedSkills,
        about: updatedAbout,
      );

      currentUser.value = updatedUser;
      assignDataToProfile();

      // ── Sync Tutor record ─────────────────────────────────────────
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
        image: (image != null && image.isNotEmpty) ? image : tutor.image,
      );

      await Amplify.DataStore.save(updatedTutor);

      if (Get.isRegistered<TutoringController>()) {
        TutoringController.instance.warmTutorCache(updatedTutor);
      }

      if (Get.isRegistered<HomeController>()) {
        HomeController.instance.refreshTutorInSessions(updatedTutor);
      }

      if (currentUser.value != null && Get.isRegistered<TutoringController>()) {
        TutoringController.instance.warmUserCache(currentUser.value!);
      }

      if (kDebugMode) {
        print('✅ _syncTutorRecord: Tutor ${tutor.id} updated');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ _syncTutorRecord failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // PROFILE IMAGE UPLOAD — AppSync direct mutation
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

      final s3Key = await _uploadImageToS3('Users/Images/Profile', image);

      // ── Get current _version ──────────────────────────────────────
      const getDoc = '''
        query GetUser(\$id: ID!) {
          getUser(id: \$id) {
            id _version
          }
        }
      ''';

      final getRes =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: getDoc,
                  variables: {'id': user.id},
                ),
              )
              .response;

      int version = 1;
      if (getRes.errors.isEmpty && getRes.data != null) {
        final decoded = jsonDecode(getRes.data!) as Map<String, dynamic>;
        final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
        final obj = root['getUser'] as Map<String, dynamic>?;
        final v = obj?['_version'];
        if (v != null) version = (v as num).toInt();
      }

      // ── Mutation ──────────────────────────────────────────────────
      const mutDoc = '''
        mutation UpdateUser(\$input: UpdateUserInput!) {
          updateUser(input: \$input) {
            id profilePicture _version
          }
        }
      ''';

      final mutRes =
          await Amplify.API
              .mutate(
                request: GraphQLRequest<String>(
                  document: mutDoc,
                  variables: {
                    'input': {
                      'id': user.id,
                      'profilePicture': s3Key,
                      '_version': version,
                    },
                  },
                ),
              )
              .response;

      if (mutRes.errors.isNotEmpty) {
        throw mutRes.errors.first.message;
      }

      debugPrint('✅ uploadUserProfilePicture: saved s3Key=$s3Key');

      // ── Update local state ────────────────────────────────────────
      final updatedUser = user.copyWith(profilePicture: s3Key);
      currentUser.value = updatedUser;
      profileImageUrl.value = s3Key;

      // ── Sync to Tutor record ──────────────────────────────────────
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

  Future<String> _uploadImageToS3(String folder, XFile image) async {
    final filename = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    final storagePath = StoragePath.fromString('$folder/$filename');

    await Amplify.Storage.uploadFile(
      localFile: AWSFile.fromPath(image.path),
      path: storagePath,
    ).result;

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
