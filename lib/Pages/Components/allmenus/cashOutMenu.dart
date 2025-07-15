import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:lottie/lottie.dart';
import 'package:thesis/Pages/CashOut/cashOutPage.dart';

class cashOutMenu extends StatelessWidget {
  const cashOutMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () {
          Get.to(cashOutScreen());
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEFE3C2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: constraints.maxHeight * 0.6,
                      child: Lottie.asset(
                        "Assets/LOTTIE/cashout1.json",
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.05),
                    Container(
                        height: constraints.maxHeight * 0.25,
                        width: MediaQuery.of(context).size.width * 0.7,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF85A947),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: LayoutBuilder(
                            builder: (context, buttonConstraints) {
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'cashOut'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize:
                                          _calculateFontSize(buttonConstraints),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        })),
                    SizedBox(height: constraints.maxHeight * 0.05),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _calculateFontSize(BoxConstraints constraints) {
    // Calculate font size based on container dimensions
    final baseSize = constraints.maxHeight * 0.4; // 40% of button height
    const maxSize = 36.0; // Maximum font size
    return baseSize.clamp(14.0, maxSize); // Ensure between 14 and 36
  }
}
