// import 'package:flutter/widgets.dart';

// class NavigationService {
//   final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

//   Future<dynamic> navigateTo(String routeName, {dynamic arguments}) async {
//     return navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
//   }

//   Future<void> popView() async {
//     return navigatorKey.currentState?.pop();
//   }

//   void popToRoot() {
//     return navigatorKey.currentState?.popUntil((route) => route.isFirst);
//   }
// }
import 'package:flutter/material.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
