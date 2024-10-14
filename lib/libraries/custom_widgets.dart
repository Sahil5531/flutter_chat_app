import 'package:flutter/material.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:loader_overlay/loader_overlay.dart';

BorderRadius cornerRadiusTen() => BorderRadius.circular(10.0);

BorderSide customBorder(Color color, double width) =>
    BorderSide(color: color, width: width);

EdgeInsets edgeInsets(
        {double left = 0.0,
        double right = 0.0,
        double top = 0.0,
        double bottom = 0.0}) =>
    EdgeInsets.only(left: left, right: right, top: top, bottom: bottom);

TextStyle senderChatBubble() => const TextStyle(
    fontSize: 15.0,
    color: Colors.black,
    backgroundColor: Color.fromARGB(255, 250, 250, 250));

TextStyle receiverChatBubble() => TextStyle(
    fontSize: 15.0,
    color: Colors.white,
    backgroundColor: CustomColor.instance.colorPrimary);

TextStyle appBarTitleTextStyle() => const TextStyle(
    color: Colors.white, fontSize: 17.0, fontWeight: FontWeight.w600);

AppBar appBar(String titleStr) => AppBar(
      title: Text(titleStr),
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: appBarTitleTextStyle(),
    );

List<BoxShadow> shadowTextField() => [
      BoxShadow(color: Colors.grey.shade500, blurRadius: 4.0),
    ];

Widget loader(Widget child) {
  return LoaderOverlay(
    // ignore: deprecated_member_use
    useDefaultLoading: false,
    closeOnBackButton: true,
    overlayWidgetBuilder: (_) {
      return Center(
        child: SpinKitCubeGrid(
          color: CustomColor.instance.colorPrimary,
          size: 50.0,
        ),
      );
    },
    child: child,
  );
}
