import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small wrapper around FlutterSecureStorage to unify usage across the app.
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  // Use a single instance of FlutterSecureStorage
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }
}
