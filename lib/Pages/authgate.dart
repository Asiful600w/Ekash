import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thesis/Pages/HomePage/homepage.dart';
import 'package:thesis/Pages/LoginAndSignUp/loginPage.dart';

import '../controller/languagecontroller.dart';

class authGate extends StatelessWidget {
  const authGate({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(LanguageController());
    return StreamBuilder(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final session = snapshot.hasData ? snapshot.data!.session : null;
          if (session != null) {
            return sendMoney();
          } else {
            return loginScreen();
          }
        });
  }
}
