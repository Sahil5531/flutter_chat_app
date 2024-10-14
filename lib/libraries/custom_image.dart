import 'package:flutter/material.dart';

Image getImage(String path, double height, double width) => Image.asset(
      path,
      width: width,
      height: height,
    );
