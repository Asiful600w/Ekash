// lib/controllers/language_controller.dart
import 'dart:ui';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  Rx<Locale> currentLocale = const Locale('en_US').obs;

  @override
  void onInit() async {
    super.onInit();
    await loadSavedLocale();
  }

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('language') ?? 'en_US';
    currentLocale.value = Locale(savedLang);
  }

  Future<void> changeLanguage(Locale newLocale) async {
    currentLocale.value = newLocale;
    Get.updateLocale(newLocale);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', newLocale.languageCode);
  }
}
