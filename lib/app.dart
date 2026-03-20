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
      title: "Starter Template",
      initialBinding: GeneralBindings(),
      initialRoute: TRoutes.splash,

      themeMode: ThemeMode.dark,
      theme: TAppTheme.darkTheme,
      darkTheme: TAppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      getPages: AppRoutes.pages,

      // ✅ REMOVED: home: Scaffold(CircularProgressIndicator())
      // That `home` was rendering a spinner widget BEFORE initialRoute
      // could resolve, causing the visible flash. When both `initialRoute`
      // and `home` are set, GetX uses `home` as the very first frame —
      // remove it so the splash is the only thing that ever renders.
    );
  }
}
