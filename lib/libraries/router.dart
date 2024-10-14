// import 'package:flutter/material.dart';
// import 'package:demochat/constants/routes_paths.dart' as routes;
// import 'package:demochat/main.dart';
// import 'package:demochat/views/home/chats/chat_list.dart';
// import 'package:demochat/views/home/chats/chat_screen/chat_screen.dart';
// import 'package:demochat/views/home/home.dart';
// import 'package:demochat/views/home/profile/profile.dart';
// import 'package:demochat/views/home/users/user_profile/user_profile.dart';
// import 'package:demochat/views/home/users/users_list.dart';
// import 'package:demochat/views/login/login.dart';
// import 'package:demochat/views/otp/otp.dart';

// MaterialPageRoute generateRoute(RouteSettings settings) {
//   switch (settings.name) {
//     case routes.launchVc:
//       return MaterialPageRoute(builder: ((context) => const LaunchVc()));
//     case routes.loginRoute:
//       return MaterialPageRoute(builder: ((context) => const LoginVc()));
//     case routes.otpRoute:
//       var number = settings.arguments as String;
//       return MaterialPageRoute(
//           builder: ((context) => OtpVc(
//                 number: number,
//               )));
//     case routes.homeRoute:
//       return MaterialPageRoute(builder: ((context) => const HomeVc()));
//     case routes.usersRoute:
//       return MaterialPageRoute(builder: ((context) => const UsersVc()));
//     case routes.chatsRoute:
//       return MaterialPageRoute(builder: ((context) => const ChatListVc()));
//     case routes.chatScreenRoute:
//       var roomId = settings.arguments as String;
//       return MaterialPageRoute(
//           builder: ((context) => ChatScreenVc(
//                 roomId: roomId,
//               )));
//     case routes.profileRoute:
//       return MaterialPageRoute(builder: ((context) => const ProfileVc()));
//     case routes.userProfileRoute:
//       return MaterialPageRoute(builder: ((context) => const UserProfileVc()));
//     default:
//       return MaterialPageRoute(
//           builder: ((context) => Scaffold(
//                 body: Center(
//                   child: Text('No path found for ${settings.name}'),
//                 ),
//               )));
//   }
// }
