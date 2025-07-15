import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class loadingScreen extends StatelessWidget {
  const loadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF85A947),
      body: Center(
        child: Container(
          child: Lottie.asset('Assets/LOTTIE/loading.json'),
        ),
      ),
    );
  }
}
