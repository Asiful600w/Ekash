import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thesis/Pages/authgate.dart';
import 'package:thesis/config/themes.dart';
import 'package:thesis/translations/app_translations.dart';

import 'controller/languagecontroller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, // optional: allows upside-down
  ]);

  OneSignal.initialize("a54cdbfc-5e89-4d76-8c8d-78486c9adfbe");
  OneSignal.Notifications.requestPermission(true);

  await Supabase.initialize(
      url: "https://oylrzccfdqmrjiyodxeo.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im95bHJ6Y2NmZHFtcmppeW9keGVvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk4ODcwMTYsImV4cCI6MjA1NTQ2MzAxNn0.PBtxK3RzEFEpkebaOBuxHh4pKyFXieP185-RyFKMsp0");
  final prefs = await SharedPreferences.getInstance();
  final locale = Locale(prefs.getString('language') ?? 'en_US');
  Get.put(LanguageController()..currentLocale.value = locale);

  runApp(MyApp(locale: locale));
}

class MyApp extends StatefulWidget {
  final Locale locale;
  const MyApp({super.key, required this.locale});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        translations: AppTranslations(),
        locale: widget.locale,
        fallbackLocale: const Locale('en_US'),
        debugShowCheckedModeBanner: false,
        title: 'Assignment App',
        theme: lightTheme,
        home: const authGate());
  }
}
