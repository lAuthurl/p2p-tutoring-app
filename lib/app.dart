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

      // Force dark mode
      themeMode: ThemeMode.dark,
      theme: TAppTheme.darkTheme, // Only use darkTheme
      darkTheme: TAppTheme.darkTheme, // Same dark theme
      debugShowCheckedModeBanner: false,
      getPages: AppRoutes.pages,

      home: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
