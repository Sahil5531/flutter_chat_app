import 'package:flutter/material.dart';
import 'package:demochat/libraries/custom_widgets.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField(
      {super.key,
      required this.textController,
      required this.hintText,
      required this.obscureText,
      required this.keyboardType});

  final TextEditingController textController;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: cornerRadiusTen(),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade500, blurRadius: 4.0),
          ]),
      child: Padding(
        padding: edgeInsets(left: 15.0, right: 15.0),
        child: TextField(
          controller: textController,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hintText,
            fillColor: Colors.grey,
          ),
        ),
      ),
    );
  }
}
