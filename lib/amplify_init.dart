import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'amplifyconfiguration.dart';
import 'data_store_manager.dart';
import 'models/ModelProvider.dart';

class AmplifyInitializer {
  static bool _configured = false;

  static Future<void> configure() async {
    if (_configured || Amplify.isConfigured) {
      safePrint('🟡 Amplify already configured');
      return;
    }

    try {
      await Amplify.addPlugins([
        AmplifyAuthCognito(),
        AmplifyAPI(),
        AmplifyDataStore(modelProvider: ModelProvider.instance),
      ]);

      await Amplify.configure(amplifyconfig);
      _configured = true;

      safePrint('🟢 Amplify configured');

      // Initialize hub listener
      DataStoreManager().init();

      // Start DataStore ONLY if signed in
      await startDataStoreIfSignedIn();
    } catch (e, st) {
      safePrint('🔴 Amplify config failed: $e');
      safePrint(st.toString());
      rethrow;
    }
  }

  static Future<void> startDataStoreIfSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();

      if (!session.isSignedIn) {
        safePrint('⚠️ Not signed in — DataStore not started');
        return;
      }

      await Amplify.DataStore.start();
      safePrint('✅ DataStore started');
    } catch (e) {
      safePrint('⚠️ DataStore start failed: $e');
    }
  }

  static Future<void> logout() async {
    try {
      await Amplify.DataStore.stop(); // 🔥 stop first
      await Amplify.DataStore.clear();
      await Amplify.Auth.signOut();

      safePrint('✅ Logged out & DataStore stopped');
    } catch (e) {
      safePrint('❌ Logout failed: $e');
    }
  }
}
