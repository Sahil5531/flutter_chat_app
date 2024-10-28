import 'dart:async';
import 'package:demochat/libraries/navigation.dart';
import 'package:demochat/location_manager/location_manager.dart';
import 'package:demochat/notification_manager/notification_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/view_models/user_data_model.dart';
import 'package:demochat/views/login/login.dart';
import 'socket_manager/socket_manager.dart';
import 'local_storage/local_storage_manager.dart';
import 'views/home/home.dart';

void main() async {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const LaunchVc(),
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: CustomColor.instance.colorAppBar,
        ),
      ),
    );
  }
}

class LaunchVc extends StatefulWidget {
  const LaunchVc({super.key});
  @override
  State<LaunchVc> createState() => _LaunchVcState();
}

class _LaunchVcState extends State<LaunchVc> {
  static const platform = MethodChannel('remote_notification');

  @override
  void initState() {
    super.initState();
    setupLocationManager();
    registerRemoteNotification();
    // registerPlatformMethod();
    SharedPrefManager.instance.fetchData(StorageKey.isLogin,
        callBack: (isLogin) {
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (isLogin is bool) {
          if (isLogin) {
            SharedPrefManager.instance.fetchData(StorageKey.authenticationToken,
                callBack: (token) {
              if (token is String) {
                Singleton.instance.authenticationToken = token;
              }
            });
            SharedPrefManager.instance.fetchData(StorageKey.userData,
                callBack: (userData) {
              if (userData is Map<String, dynamic>) {
                Singleton.instance.userDataModel =
                    UserDataModel().parseJsonData(userData);
              }
            });
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const HomeVc()));
          } else {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const Login()));
          }
        } else {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const Login()));
        }
        SocketManager.instance.initializeSocket();
        timer.cancel();
      });
    });
  }

  registerRemoteNotification() async {
    await Firebase.initializeApp();
    Singleton.instance.notificationManager = NotificationManager();
    Singleton.instance.notificationManager?.initialize();
  }

  setupLocationManager() {
    Singleton.instance.locationManager = LocationManager();
    Singleton.instance.locationManager?.startLocationUpdates();
  }

  registerPlatformMethod() {
    platform.setMethodCallHandler((call) async {
      debugPrint(call.method);
      switch (call.method) {
        case 'updateDeliveryStatus':
          break;
        default:
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Image.asset(
            ImagePath.instance.logoImage,
            scale: 3,
          ),
        ),
      ),
    );
  }
}
