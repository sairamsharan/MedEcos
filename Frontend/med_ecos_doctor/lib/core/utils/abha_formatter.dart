import 'package:flutter/services.dart';

class AbhaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    
    // Remove all non-digit characters
    text = text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Limit to 16 digits
    if (text.length > 16) {
      text = text.substring(0, 16);
    }
    
    var newText = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        newText.write('-');
      }
      newText.write(text[i]);
    }
    
    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
