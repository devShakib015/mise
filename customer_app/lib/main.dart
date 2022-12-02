import 'package:customer_app/helpers/app_constants.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/views/wrapper.dart';

import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeConstant.getTheme(Brightness.light),
      locale: const Locale('en'),
      home: const Wrapper(),
    );
  }
}
