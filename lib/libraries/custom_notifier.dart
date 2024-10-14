import 'package:flutter/material.dart';

class CustomNotifier extends ChangeNotifier {
  dynamic _data;
  dynamic get data => _data;
  void otoCallScreen(dynamic newData) {
    _data = newData;
    notifyListeners();
  }
}
