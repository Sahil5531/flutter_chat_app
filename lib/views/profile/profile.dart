import 'package:flutter/material.dart';
import 'package:demochat/constants/screen_dimention.dart';
import 'package:demochat/components/custom_alert.dart';
import 'package:demochat/local_storage/local_storage_manager.dart';
import 'package:demochat/socket_manager/socket_manager.dart';
import 'package:demochat/views/edit_profile/edit_profile.dart';
import 'package:demochat/views/users/user_profile/user_profile.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/main.dart';
import 'package:demochat/web_api/urls.dart';

import '../../libraries/navigation.dart';

class ProfileVc extends StatefulWidget {
  const ProfileVc({super.key});

  @override
  State<ProfileVc> createState() => _ProfileVcState();
}

class _ProfileVcState extends State<ProfileVc> {
  var userDataModel = Singleton.instance.userDataModel;
  late Image? profileImage = Image.asset(
    ImagePath.instance.userPlaceholder,
    fit: BoxFit.cover,
  );
  @override
  void initState() {
    super.initState();
    setData();
  }

  refreshScreen() {
    setData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
      children: [
        profileImageWidget(),
        userInfoWidget(),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: 20, bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                children: [
                  buttonEdit(),
                  const SizedBox(
                    height: 10,
                  ),
                  buttonLogout()
                ],
              )
            ],
          ),
        ),
      ],
    )));
  }

  // User Detail
  Widget userInfoWidget() {
    return Column(
      children: [
        Text(
          userDataModel?.fullname ?? '',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          userDataModel?.phoneNumber ?? '',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          userDataModel?.address ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.normal,
          ),
        )
      ],
    );
  }

  // Widget's
  Widget profileImageWidget() {
    double containerHeight = getScreenHeight() / 3;
    double containerWidth = getScreenWidth();
    return ClipPath(
      clipper: RoundCliper(),
      child: Container(
        height: containerHeight,
        width: containerWidth,
        decoration: BoxDecoration(
          color: CustomColor.instance.colorPrimary,
        ),
        child: Center(
          child: Container(
            transform: Matrix4.translationValues(0, -20, 0),
            height: containerHeight / 2,
            width: containerHeight / 2,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular((containerHeight / 2)),
              border: Border.all(
                color: Colors.white,
                width: 3,
                style: BorderStyle.solid,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular((getScreenWidth() / 1.3) / 2),
              child: SizedBox(
                width: getScreenWidth() / 3,
                height: getScreenWidth() / 3,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular((getScreenWidth() / 3) / 2),
                  child: profileImage,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Edit Button
  Widget buttonEdit() {
    return FloatingActionButton(
        heroTag: 1,
        backgroundColor: CustomColor.instance.colorPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditProfileVc(),
            ),
          ).then((value) => {refreshScreen()});
        },
        child: const Icon(Icons.edit));
  }

  // Logout Button
  Widget buttonLogout() {
    return FloatingActionButton(
        heroTag: 2,
        backgroundColor: CustomColor.instance.colorPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        onPressed: () {
          logout();
        },
        child: const Icon(Icons.logout));
  }

  // Set Data
  setData() {
    setState(() {
      userDataModel = Singleton.instance.userDataModel;
      if (userDataModel?.userImageUrl != '') {
        final imageUrl =
            '${Urls.instance.fileUrl}${userDataModel?.userImageUrl}';
        profileImage = Image.network(
          imageUrl,
          fit: BoxFit.cover,
        );
      }
    });
  }

  // Logout
  Future logout() async {
    showAlertOkCancel('Alert', 'Are you sure you want to logout.',
        callBack: (action) {
      if (action == Buttons.ok) {
        SocketManager.instance.emitWithEvent(Emitter.disconnectUser,
            params: {'user_id': Singleton.instance.userDataModel?.userId});
        SharedPrefManager.instance.clearAllData();
        navigatorKey = GlobalKey<NavigatorState>();
        Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
                pageBuilder: ((context, _, __) => const MainApp())),
            (route) => false);
      }
    });
  }
}
