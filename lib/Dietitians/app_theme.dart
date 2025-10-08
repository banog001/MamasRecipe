import 'package:flutter/material.dart';

// Color constants
const Color primaryColor = Color(0xFF6200EE); // Replace with your app's primary color
const Color textColorOnPrimary = Colors.white;

// Helper methods
Color scaffoldBgColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.grey[900]!
      : Colors.grey[50]!;
}

Color cardBgColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.grey[850]!
      : Colors.white;
}

Color textColorPrimary(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : Colors.black87;
}

Color textColorSecondary(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.grey[400]!
      : Colors.grey[600]!;
}

TextStyle getTextStyle(
    BuildContext context, {
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
    }) {
  return TextStyle(
    fontSize: fontSize ?? 14,
    fontWeight: fontWeight ?? FontWeight.normal,
    color: color ?? textColorPrimary(context),
  );
}