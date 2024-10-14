import 'package:flutter/material.dart';

class CustomTextButton extends StatelessWidget {
  const CustomTextButton({super.key, 
  required this.onTap, 
  required this.title, 
  required this.fontSize, 
  required this.fontWeight, 
  required this.textColor});

  final Function() onTap;
  final String title;
  final double fontSize;
  final FontWeight fontWeight;
  final Color textColor;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 19,
      child: GestureDetector(
        onTap: () {
          onTap();        
        },
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor
          ),
        ),
      ),
    );
  }
}