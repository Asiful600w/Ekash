import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thesis/Pages/Components/widgetComponents/textFieldWidget.dart';
import 'package:thesis/Pages/HomePage/homepage.dart';
import 'package:thesis/Pages/LoginAndSignUp/signUpScreen.dart';
import 'package:thesis/controller/userController.dart';
import 'package:get/get.dart';
import 'package:thesis/services/dbservice.dart';

class loginScreen extends StatefulWidget {
  loginScreen({super.key});

  @override
  State<loginScreen> createState() => _loginScreenState();
}

class _loginScreenState extends State<loginScreen> {
  userController UserController = Get.put(userController());
  final authservice = dbMethods();
  void logIn() async {
    final email = UserController.email.text;
    final password = UserController.password.text;

    try {
      final AuthResponse loginResponse =
          await authservice.login(email, password);
      if (loginResponse.user != null) {
        Get.offAll(sendMoney());
      }
    } catch (e) {
      if (mounted) {}
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You have No Account create one")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF85A947),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  "Assets/Images/Background.svg",
                  color: const Color(0xFFEFE3C2),
                ),
              ],
            ),
            Text("Login",
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontSize: 50)),
            Container(
              width: 200.0, // Set the width of the divider
              child: const Divider(
                color: Color(0xFFEFE3C2), // Line color
                thickness: 6.0, // Line thickness
                indent: 20.0, // Space before the line
                endIndent: 20.0, // Space after the line
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Container(
              height: 350,
              width: 380,
              decoration: BoxDecoration(
                color: const Color(0xFFEFE3C2),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.2), // Shadow color with opacity
                    spreadRadius: 3, // How much the shadow spreads
                    blurRadius: 10, // How soft the shadow looks
                    offset:
                        const Offset(5, 8), // Horizontal and vertical offsets
                  ),
                ],
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 30,
                      ),
                      Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(width: 1, color: Color(0xFF28390B)),
                          ),
                          width: 330,
                          child: textFieldWidgets(
                            hintText: "Email",
                            controller: UserController.email,
                            inputType: TextInputType.text,
                            obscure: false,
                            iconPath: "Assets/Icons/login.svg",
                          )),
                      const SizedBox(
                        height: 30,
                      ),
                      Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(width: 1, color: Color(0xFF28390B)),
                          ),
                          width: 330,
                          child: textFieldWidgets(
                            hintText: "Password",
                            controller: UserController.password,
                            inputType: TextInputType.text,
                            obscure: true,
                            iconPath: "Assets/Icons/password.svg",
                          )),
                      const SizedBox(
                        height: 20,
                      ),
                      ElevatedButton(
                          onPressed: logIn,
                          style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(
                                  0xFF28390B), // Text and icon color
                              minimumSize: const Size(200, 50)),
                          child: const Text("Login")),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text("Dont have an id?"),
                      const SizedBox(
                        height: 10,
                      ),
                      InkWell(
                          onTap: () {
                            Get.offAll(signUpScreen());
                          },
                          child: const Text("SignUp"))
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
