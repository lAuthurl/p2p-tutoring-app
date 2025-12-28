import 'package:p2p_tutoring_app/bindings/general_bindings.dart';
import 'package:p2p_tutoring_app/routes/app_routes.dart';
import 'package:p2p_tutoring_app/routes/routes.dart';
import 'package:p2p_tutoring_app/utils/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      /// -- README(Docs[3]) -- Bindings
      title: "Starter Template",
      initialBinding: GeneralBindings(),
      initialRoute: TRoutes.splash,
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      getPages: AppRoutes.pages,

      /// -- README(Docs[4]) -- To use Screen Transitions here
      /// -- README(Docs[5]) -- Home Screen or Progress Indicator
      // `initialRoute` is set to splash so `home` shows a brief loader.
      home: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
