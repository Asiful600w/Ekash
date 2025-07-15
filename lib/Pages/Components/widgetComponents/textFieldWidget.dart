import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class textFieldWidgets extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final TextInputType inputType;
  final bool obscure;
  final String iconPath;
  const textFieldWidgets(
      {super.key,
      required this.hintText,
      required this.controller,
      required this.inputType,
      required this.obscure,
      required this.iconPath});

  @override
  final String preNumber = '+88';
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      obscureText: obscure,
      decoration: InputDecoration(
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 3)),
          enabledBorder:
              OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 20, // Bigger font size for hint text
            color: Colors.blueGrey, // Custom color for the hint
            fontWeight: FontWeight.w400, // Adjust font weight
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          suffixIcon: SvgPicture.asset(
            iconPath,
            width: .2, // Set width
            height: .2, // Set height
          )),
    );
  }
}
