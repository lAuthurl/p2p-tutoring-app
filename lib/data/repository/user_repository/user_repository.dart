import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../personalization/models/user_model.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import '../authentication_repository/authentication_repository.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();
  final GetStorage _local = GetStorage('users');

  /// Save user data locally
  Future<void> saveUserRecord(UserModel user) async {
    try {
      await _local.write(user.id, user.toJson());
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Fetch user details
  Future<UserModel> fetchUserDetails() async {
    try {
      final data = _local.read(AuthenticationRepository.instance.getUserID);
      if (data != null && data is Map<String, dynamic>) {
        return UserModel.fromMap(data);
      }
      return UserModel.empty();
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Upload image to Amplify S3
  Future<String> uploadImage(String path, XFile image) async {
    try {
      final key = '$path/${image.name}';
      final localFile = File(image.path);

      // Upload file to Amplify Storage (use AWSFile and StoragePath)
      final uploadOp = Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(localFile.path),
        path: StoragePath.fromString(key),
      );
      await uploadOp.result;

      // Get the file URL
      final getUrlOp = Amplify.Storage.getUrl(
        path: StoragePath.fromString(key),
      );
      final urlResult = await getUrlOp.result;

      return (urlResult.url).toString();
    } on StorageException catch (e) {
      throw 'Upload failed: ${e.message}';
    } on AmplifyException catch (e) {
      throw 'Storage error: ${e.message}';
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Update user locally
  Future<void> updateUserDetails(UserModel updatedUser) async {
    try {
      await _local.write(updatedUser.id, updatedUser.toJson());
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Update single field in user record
  Future<void> updateSingleField(Map<String, dynamic> json) async {
    try {
      final id = AuthenticationRepository.instance.getUserID;
      final existing = _local.read(id) ?? {};
      if (existing is Map<String, dynamic>) {
        existing.addAll(json);
        await _local.write(id, existing);
      } else {
        await _local.write(id, json);
      }
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Remove user record
  Future<void> removeUserRecord(String userId) async {
    try {
      await _local.remove(userId);
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Clear all local user records
  Future<void> clearAllUsers() async {
    try {
      await _local.erase();
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }
}
