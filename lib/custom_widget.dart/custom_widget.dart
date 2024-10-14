import 'package:flutter/material.dart';

import '../components/custom_button.dart';

enum CameraMode { front, back }

enum SelectionState { selected, unselected }

Widget buildButton(
    String title, Color bgColor, Color textColor, Function() onTap) {
  return CustomButton(
    onTap: onTap,
    title: title,
    height: 70,
    width: 70,
    backgroundColor: bgColor,
    borderRadius: 35,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    textColor: textColor,
  );
}

Widget buildCallToolButtons(
    SelectionState selectionState, IconData icon, Function() onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: selectionState == SelectionState.selected
            ? Colors.black87
            : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Icon(
        icon,
        color: selectionState == SelectionState.selected
            ? Colors.white
            : Colors.black87,
      ),
    ),
  );
}
