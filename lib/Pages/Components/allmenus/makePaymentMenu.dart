import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:lottie/lottie.dart';
import 'package:thesis/Pages/MakePayment/makePaymentpage.dart';

class makePaymentMenu extends StatelessWidget {
  const makePaymentMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () {
          Get.to(const MakePaymentScreen());
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: const Color(0xFFEFE3C2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: constraints.maxHeight * 0.6,
                    child: Lottie.asset(
                      "Assets/LOTTIE/makepayment.json",
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.05),
                  Container(
                    height: constraints.maxHeight * 0.25,
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF85A947),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "makePayment".tr,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(color: Colors.white),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.05),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
