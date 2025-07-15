import 'package:thesis/config/color.dart';
import 'package:flutter/material.dart';

var lightTheme=ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    //Color Scheme
    colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: primaryColor,
        secondary: secondaryColor,
        onSecondary: backroundColor,
        error: Colors.red,
        onError: fontColor,
        surface: backroundColor,
        onSurface: fontColor),
    //Text theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          fontFamily:'Poppins',
          fontSize: 30,
          fontWeight: FontWeight.w800
      ),




      labelLarge: TextStyle(
          fontFamily:'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: backroundColor
      ),


    )
);
