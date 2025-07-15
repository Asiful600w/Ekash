import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:lottie/lottie.dart';

import '../../SendMoney/sendmoneypage.dart';

class sendMoneyMenu extends StatelessWidget {
  final String balance;
  const sendMoneyMenu({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => Get.to(sendMoneyScreen(Balance: double.parse(balance))),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: MediaQuery.of(context).size.width,
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
                        "Assets/LOTTIE/sendmoney.json",
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
                                'sendMoney'.tr,
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
    final maxSize = 36.0; // Maximum font size
    return baseSize.clamp(14.0, maxSize); // Ensure between 14 and 36
  }
}
