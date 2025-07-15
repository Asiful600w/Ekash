import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thesis/Pages/Components/widgetComponents/textFieldWidget.dart';
import 'package:thesis/Pages/HomePage/homepage.dart';
import 'package:thesis/Pages/LoginAndSignUp/loginPage.dart';
import 'package:thesis/controller/userController.dart';
import 'package:get/get.dart';
import 'package:thesis/services/dbservice.dart';

class signUpScreen extends StatefulWidget {
  signUpScreen({super.key});

  @override
  State<signUpScreen> createState() => _signUpScreenState();
}

class _signUpScreenState extends State<signUpScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to bottom after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  userController UserController = Get.put(userController());
  @override
  final authService = dbMethods();

  void signUpFunc() async {
    final email = UserController.emailSign.text;
    final password = UserController.passSign.text;
    final pin = UserController.pin.text;
    final name = UserController.name.text;
    final number = UserController.number.text;

    // Number validation
    if (!number.startsWith('01')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Number must start with 01')),
      );
      return;
    }

    if (number.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Number must be 11 digits')),
      );
      return;
    }

    try {
      // Check if number exists in database
      final existingUser = await Supabase.instance.client
          .from('users')
          .select('Number')
          .eq('Number', number)
          .maybeSingle();

      if (existingUser != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Number already registered')),
        );
        return;
      }
      if (pin.length != 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The pin should be of 5 digits')),
        );
        return;
      }

      // Proceed with signup if validations pass
      final AuthResponse _response = await authService.signUp(email, password);
      if (_response.user == null) {
        throw Exception('Sign-up failed: No user returned.');
      }

      await Supabase.instance.client.from('users').insert({
        'userid': _response.user!.id,
        'Name': name,
        'Number': number,
        'Email': email,
        'Pin': pin,
        'Balance': 5000
      });

      if (mounted) {
        Get.offAll(sendMoney());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-up successful!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF85A947),
      body: SingleChildScrollView(
        controller: _scrollController,
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
            Text("Sign-Up",
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
              height: 10,
            ),
            Container(
              height: 600,
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
                    offset: Offset(5, 8), // Horizontal and vertical offsets
                  ),
                ],
              ),
              child: Center(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                width: 1, color: const Color(0xFF28390B)),
                          ),
                          width: 330,
                          child: textFieldWidgets(
                            hintText: "Email",
                            controller: UserController.emailSign,
                            inputType: TextInputType.text,
                            obscure: false,
                            iconPath: "Assets/Icons/login.svg",
                          )),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                width: 1, color: const Color(0xFF28390B)),
                          ),
                          width: 330,
                          child: textFieldWidgets(
                            hintText: "Password",
                            controller: UserController.passSign,
                            inputType: TextInputType.text,
                            obscure: true,
                            iconPath: "Assets/Icons/password.svg",
                          )),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(width: 1, color: Color(0xFF28390B)),
                          ),
                          width: 330,
                          child: textFieldWidgets(
                            hintText: "Number",
                            controller: UserController.number,
                            inputType: TextInputType.number,
                            obscure: false,
                            iconPath: "Assets/Icons/login.svg",
                          )),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(width: 1, color: Color(0xFF28390B)),
                          ),
                          width: 330,
                          child: textFieldWidgets(
                            hintText: "Name",
                            controller: UserController.name,
                            inputType: TextInputType.text,
                            obscure: false,
                            iconPath: "Assets/Icons/name.svg",
                          )),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                width: 1, color: const Color(0xFF28390B)),
                          ),
                          width: 330,
                          child: textFieldWidgets(
                            hintText: "Pin",
                            controller: UserController.pin,
                            inputType: TextInputType.text,
                            obscure: true,
                            iconPath: "Assets/Icons/password.svg",
                          )),
                      const SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                          onPressed: signUpFunc,
                          style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(
                                  0xFF28390B), // Text and icon color
                              minimumSize: const Size(200, 50)),
                          child: const Text("Signup")),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text("have an id?"),
                      const SizedBox(
                        height: 10,
                      ),
                      InkWell(
                          onTap: () {
                            Get.offAll(loginScreen());
                          },
                          child: const Text("Login"))
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
