// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get_storage/get_storage.dart';
import 'package:p2p_tutoring_app/bindings/general_bindings.dart';
import 'app.dart';
import 'amplify_init.dart';
import 'data_store _manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preserve native splash until setup done
  FlutterNativeSplash.preserve(
    widgetsBinding: WidgetsFlutterBinding.ensureInitialized(),
  );

  // Initialize local storage
  await GetStorage.init();

  // Initialize Amplify
  await AmplifyInitializer.configure();
  print("🟢 Amplify fully configured");

  DataStoreManager().init();

  // Inject persistent controllers & repositories
  GeneralBindings().dependencies();

  // Run the app
  runApp(const App());

  // Remove splash after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });
}
