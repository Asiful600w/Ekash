import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

class textFieldWidgets2 extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final TextInputType inputType;
  final bool obscure;
  final String iconPath;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final FocusNode focusNode;
  final TextInputAction? textInputAction;

  const textFieldWidgets2({
    super.key,
    required this.hintText,
    required this.controller,
    required this.inputType,
    required this.obscure,
    required this.iconPath,
    this.enabled = true,
    required this.focusNode,
    this.onSubmitted,
    this.textInputAction,
  });

  @override
  final String preNumber = '+88';
  Widget build(BuildContext context) {
    return TextFormField(
      textInputAction: textInputAction,
      focusNode: focusNode,
      enabled: enabled,
      onFieldSubmitted: onSubmitted,
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
