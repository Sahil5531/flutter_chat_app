import 'package:flutter/material.dart';

class CustomRoundButton extends StatelessWidget {
  const CustomRoundButton(
      {super.key,
      required this.height,
      required this.width,
      required this.borderRadius,
      required this.bgColor,
      required this.icon,
      required this.iconColor,
      this.shadowColor,
      required this.onTap,
      this.onTapDown,
      this.onTapUp,
      this.isShadow});

  final double height;
  final double width;
  final double borderRadius;
  final Color bgColor;
  final Color iconColor;
  final Color? shadowColor;
  final IconData icon;
  final Function onTap;
  final Function? onTapDown;
  final Function? onTapUp;
  final bool? isShadow;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      onTapDown: (details) {
        if (onTapDown != null) {
          onTapDown!();
        }
      },
      onTapUp: (details) {
        if (onTapUp != null) {
          onTapUp!();
        }
      },
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: shadowColor ?? Colors.white,
              offset: Offset.zero,
              blurRadius: isShadow ?? false ? 4 : 0,
              blurStyle: BlurStyle.normal,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: height / 2,
        ),
      ),
    );
  }
}
