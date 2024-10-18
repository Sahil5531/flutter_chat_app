import 'package:demochat/libraries/singleton.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationManager {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  dynamic initialize() {
    registerFirebaseNotification();
    onMessage();
    onBackgroudMessage();
    onTerminatedApp();
    onMessageOpenedApp();
  }

  dynamic registerFirebaseNotification() async {
    debugPrint("registerFirebaseNotification");
    await _firebaseMessaging.setAutoInitEnabled(true);
    await _firebaseMessaging.requestPermission(
        alert: true, badge: true, sound: true);
    await _firebaseMessaging.getAPNSToken().then((value) {
      debugPrint("APNSToken $value");
    });
    await _firebaseMessaging.getToken().then((value) {
      debugPrint("FCMToken $value");
      Singleton.instance.fcmToken = value ?? "";
    });
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);
  }

  dynamic onMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("onMessage: ${message.data}");
    });
  }

  dynamic onBackgroudMessage() {
    FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
      debugPrint("onBackgroundMessage: ${message.data}");
    });
  }

  dynamic onTerminatedApp() {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        debugPrint("onTerminatedApp: ${message.data}");
      }
    });
  }

  dynamic onMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("onMessageOpenedApp: ${message.data}");
    });
  }
}
