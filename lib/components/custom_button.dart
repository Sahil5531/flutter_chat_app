import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({super.key, 
  required this.onTap, 
  required this.title,
  required this.height,
  required this.width,
  required this.backgroundColor,
  required this.borderRadius,
  required this.fontSize, 
  required this.fontWeight, 
  required this.textColor});

  final Function() onTap;
  final String title;
  final double height;
  final double width;
  final Color backgroundColor;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final Color textColor;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: GestureDetector(
        onTap: () {
          onTap();        
        },
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius)
          ),
          child: Center(
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
        ),
      ),
    );
  }
}