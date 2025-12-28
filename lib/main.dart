import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:p2p_tutoring_app/data/repository/user_repository/user_repository.dart';

import 'app.dart';
import 'data/repository/authentication_repository/authentication_repository.dart';
import 'amplifyconfiguration.dart'; // Amplify generated config // adjust path if needed

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  /// Initialize GetStorage
  await GetStorage.init();

  /// Preserve native splash until initialization completes
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Simple startup timing
  final Stopwatch startupWatch = Stopwatch()..start();

  /// Initialize Amplify
  final auth = AmplifyAuthCognito();
  final storage = AmplifyStorageS3();

  try {
    await Amplify.addPlugins([auth, storage]);
    await Amplify.configure(
      amplifyconfig,
    ); // amplifyconfig from amplifyconfiguration.dart
    if (kDebugMode) print('Amplify configured successfully');
  } on AmplifyAlreadyConfiguredException {
    if (kDebugMode) print('Amplify was already configured.');
  }

  // AuthenticationRepository is registered lazily in GeneralBindings
  // Register UserRepository but defer UserController until after splash screen appears
  Get.put(UserRepository());

  /// Run the app
  runApp(const App());

  // Log time to first frame and remove native splash
  WidgetsBinding.instance.addPostFrameCallback((_) {
    startupWatch.stop();
    if (kDebugMode) {
      print(
        'Startup: time to first frame ${startupWatch.elapsedMilliseconds} ms',
      );
    }
    FlutterNativeSplash.remove();
    // Instantiate AuthenticationRepository now that GetMaterialApp is ready
    try {
      Get.find<AuthenticationRepository>();
    } catch (_) {
      // If not registered lazily, create it directly
      Get.put(AuthenticationRepository());
    }
  });
}
