import 'package:flutter/material.dart';

class CustomColor {
  static CustomColor instance = CustomColor();
  final Color colorPrimary = const Color.fromRGBO(106, 72, 142, 1);
  final Color colorButtonBg = const Color.fromRGBO(106, 72, 142, 1);
  final Color colorAppBar = const Color.fromARGB(255, 106, 72, 142);
  final Color colorButtonText = const Color.fromARGB(255, 255, 255, 255);
  final Color colorTextFieldBorder = const Color.fromARGB(255, 94, 94, 94);
}

class ImagePath {
  static ImagePath instance = ImagePath();
  String imagesPath = "assets/images";
  String get logoImage => '$imagesPath/logo.png';
  String get userPlaceholder => '$imagesPath/user.png';
  String get userProfileSelected => '$imagesPath/profile_user_black.png';
  String get userProfileUnSelected => '$imagesPath/profile_user_white.png';
  String get incomingRequest => '$imagesPath/new_request.png';
  String get addGroup => '$imagesPath/add_group.png';
  String get plus => '$imagesPath/add.png';
  String get placeholder => '$imagesPath/placeholder_image.jpg';
  String get googleMap => '$imagesPath/google_maps.png';
  String get doubleTick => '$imagesPath/double_tick.png';
  String get singleTick => '$imagesPath/single_tick.png';
  String get flagIndia => '$imagesPath/flag_india.png';
  String get download => '$imagesPath/download.png';
  String get play => '$imagesPath/play.png';
}

class ScreenSize {
  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}

class RequestType {
  final post = 'post';
  final get = 'get';
}
