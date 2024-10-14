import 'package:demochat/constants/screen_dimention.dart';
import 'package:flutter/material.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/libraries/custom_widgets.dart';

// ignore: must_be_immutable
class OtpTextField extends StatelessWidget {
  OtpTextField(
      {super.key,
      required this.controller,
      required this.focus,
      required this.onChanged});
  // ignore: prefer_typing_uninitialized_variables
  final controller;
  late bool focus;
  final Function() onChanged;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getScreenWidth() / 8,
      width: getScreenWidth() / 8,
      child: TextField(
        controller: controller,
        autofocus: focus,
        onChanged: (value) {
          onChanged();
        },
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          border: OutlineInputBorder(
              borderRadius: cornerRadiusTen(),
              borderSide:
                  customBorder(CustomColor.instance.colorTextFieldBorder, 2.0)),
          hintText: "*",
        ),
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.bottom,
      ),
    );
  }
}
