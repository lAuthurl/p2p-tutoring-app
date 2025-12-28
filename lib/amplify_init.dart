import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter/foundation.dart';
import 'amplifyconfiguration.dart';

final _amplifyConfigured = ValueNotifier<bool>(false);

Future<void> initializeAmplify() async {
  if (_amplifyConfigured.value) return;
  try {
    // Parse the amplify config and only add plugins that are present in it.
    final parsed = json.decode(amplifyconfig);
    if (parsed is! Map<String, dynamic>) {
      safePrint('Amplify configure skipped: config is not a JSON object');
      return;
    }

    bool hasAuth = false;
    bool hasStorage = false;
    bool hasApi = false;

    // Gen 1 structure: top-level 'auth', 'storage', 'api' with nested 'plugins'
    if (parsed['auth'] is Map) {
      final authMap = parsed['auth'] as Map;
      if (authMap['plugins'] is Map && (authMap['plugins'] as Map).isNotEmpty) {
        hasAuth = true;
      }
    }
    if (parsed['storage'] is Map) {
      final storageMap = parsed['storage'] as Map;
      if (storageMap['plugins'] is Map &&
          (storageMap['plugins'] as Map).isNotEmpty) {
        hasStorage = true;
      }
    }
    if (parsed['api'] is Map) {
      final apiMap = parsed['api'] as Map;
      if (apiMap['plugins'] is Map && (apiMap['plugins'] as Map).isNotEmpty) {
        hasApi = true;
      }
    }

    // Gen 2 or alternative: top-level 'plugins' map
    if (parsed['plugins'] is Map) {
      final pluginsMap = parsed['plugins'] as Map;
      for (final key in pluginsMap.keys) {
        final k = key.toString().toLowerCase();
        if (k.contains('auth')) hasAuth = true;
        if (k.contains('storage') || k.contains('s3')) hasStorage = true;
        if (k.contains('api')) hasApi = true;
      }
    }

    final List<AmplifyPluginInterface> pluginsToAdd = [];
    if (hasAuth) pluginsToAdd.add(AmplifyAuthCognito());
    if (hasStorage) pluginsToAdd.add(AmplifyStorageS3());
    if (hasApi) pluginsToAdd.add(AmplifyAPI());

    if (pluginsToAdd.isEmpty) {
      safePrint(
        'Amplify configure skipped: no plugins found in amplifyconfiguration.dart',
      );
      return;
    }

    await Amplify.addPlugins(pluginsToAdd);

    await Amplify.configure(amplifyconfig);
    _amplifyConfigured.value = true;
  } on AmplifyAlreadyConfiguredException {
    _amplifyConfigured.value = true;
  } catch (e) {
    safePrint('Failed to configure Amplify: $e');
    rethrow;
  }
}
