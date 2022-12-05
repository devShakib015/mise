import 'package:customer_app/helpers/hive_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final themeProvider = ChangeNotifierProvider<ThemeProvider>((ref) {
  return ThemeProvider();
});

class ThemeProvider extends ChangeNotifier {
  Future<void> saveTheme(bool isDark) async {
    final box = Hive.box(HiveConstants.hiveBox);
    await box.put(HiveConstants.theme, isDark);
    notifyListeners();
  }

  bool? get isDarkTheme {
    final box = Hive.box(HiveConstants.hiveBox);
    return box.get(HiveConstants.theme, defaultValue: null);
  }
}
