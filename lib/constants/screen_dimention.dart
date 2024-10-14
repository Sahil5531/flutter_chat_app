import 'package:flutter/material.dart';
import 'package:demochat/libraries/singleton.dart';

double getScreenHeight() {
  return MediaQuery.of(Singleton.instance.context).size.height;
}

double getScreenWidth() {
  return MediaQuery.of(Singleton.instance.context).size.width;
}
