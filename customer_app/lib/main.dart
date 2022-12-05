import 'package:customer_app/helpers/app_constants.dart';
import 'package:customer_app/helpers/config_loading.dart';
import 'package:customer_app/helpers/hive_constants.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/providers/hive_provider.dart';
import 'package:customer_app/views/wrapper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox(HiveConstants.hiveBox);

  runApp(
    EasyLocalization(
      supportedLocales: AppConstants.supportedLocales,
      path: AppConstants.translationsPath,
      fallbackLocale: AppConstants.supportedLocales.first,
      child: const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, ref) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    final brightness = SchedulerBinding.instance.window.platformBrightness;
    final themeRef = ref.watch(themeProvider);

    configLoading(themeRef.isDarkTheme == null
        ? brightness
        : themeRef.isDarkTheme == true
            ? Brightness.dark
            : Brightness.light);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeConstant.getTheme(themeRef.isDarkTheme == null
              ? brightness
              : themeRef.isDarkTheme == true
                  ? Brightness.dark
                  : Brightness.light)
          .copyWith(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const Wrapper(),
      builder: EasyLoading.init(),
    );
  }
}
