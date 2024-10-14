import 'package:flutter/material.dart';
import 'package:demochat/constants/screen_dimention.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/libraries/custom_widgets.dart';

// ignore: must_be_immutable
class MyButtons extends StatelessWidget {
  MyButtons(
      {super.key,
      required this.title,
      required this.onTap,
      this.backgroundColor,
      required this.height,
      this.width});
  final String title;
  final Function() onTap;
  late Color? backgroundColor;
  late double height;
  late double? width = getScreenWidth();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
            color: backgroundColor ?? CustomColor.instance.colorButtonBg,
            borderRadius: cornerRadiusTen(),
            boxShadow: [
              BoxShadow(
                color: backgroundColor ?? CustomColor.instance.colorButtonBg,
              ),
            ]),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
                color: CustomColor.instance.colorButtonText,
                fontSize: 15.0,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
