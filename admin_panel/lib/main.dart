import 'package:admin_panel/helpers/app_constants.dart';
import 'package:admin_panel/helpers/config_loading.dart';
import 'package:admin_panel/helpers/theme_constants.dart';
import 'package:admin_panel/views/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    configLoading(Theme.of(context).brightness);

    return MacosApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.light,
      builder: EasyLoading.init(),
      home: const Wrapper(),
    );
  }
}
