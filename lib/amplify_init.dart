import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:p2p_tutoring_app/data_store%20_manager.dart';
import 'amplifyconfiguration.dart';
import 'models/ModelProvider.dart';

/// -------------------------------
/// AmplifyInitializer: Configure Amplify
/// -------------------------------
class AmplifyInitializer {
  static bool _configured = false;

  /// Configure Amplify with Auth, API, DataStore
  static Future<void> configure() async {
    if (_configured || Amplify.isConfigured) {
      safePrint('🟡 Amplify already configured — skipping');
      return;
    }

    try {
      // Add plugins in correct order
      await Amplify.addPlugins([
        AmplifyAuthCognito(),
        AmplifyAPI(),
        AmplifyDataStore(modelProvider: ModelProvider.instance),
      ]);

      await Amplify.configure(amplifyconfig);
      _configured = true;
      safePrint('🟢 Amplify fully configured');

      // Initialize DataStore hub listener
      DataStoreManager().init();

      // Start DataStore if signed in
      await _startDataStoreIfSignedIn();
    } on AmplifyAlreadyConfiguredException {
      _configured = true;
      safePrint('🟡 Amplify was previously configured');
    } catch (e, st) {
      safePrint('🔴 Amplify configuration failed: $e');
      safePrint(st.toString());
      rethrow;
    }
  }

  /// Start DataStore if user session exists
  static Future<void> _startDataStoreIfSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        await Amplify.DataStore.start();
        safePrint('✅ DataStore started successfully');
      } else {
        safePrint('⚠️ User not signed in — DataStore not started');
      }
    } catch (e) {
      safePrint('⚠️ Failed to start DataStore: $e');
    }
  }

  /// Logout helper
  static Future<void> logout() async {
    try {
      await Amplify.Auth.signOut();
      await DataStoreManager().clear(); // clear local DataStore
      safePrint('✅ User logged out and DataStore cleared');
    } catch (e) {
      safePrint('❌ Logout failed: $e');
    }
  }
}
