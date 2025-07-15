import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.length > 3 && text.length <= 6) {
      return TextEditingValue(
        text: '${text.substring(0, 3)}-${text.substring(3)}',
        selection: TextSelection.collapsed(offset: newValue.text.length + 1),
      );
    }
    if (text.length > 6) {
      return TextEditingValue(
        text:
            '${text.substring(0, 3)}-${text.substring(3, 6)}-${text.substring(6)}',
        selection: TextSelection.collapsed(offset: newValue.text.length + 2),
      );
    }
    return TextEditingValue(text: text);
  }
}
