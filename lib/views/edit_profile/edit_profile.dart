import 'dart:io';

import 'package:flutter/material.dart';
import 'package:demochat/components/image_picker.dart';
import 'package:demochat/constants/screen_dimention.dart';
import 'package:demochat/components/custom_alert.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/libraries/custom_widgets.dart';
import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/components/custom_round_button.dart';
import 'package:demochat/components/my_button.dart';
import 'package:demochat/components/custom_text_field.dart';
import 'package:demochat/views/users/user_profile/user_profile.dart';
import 'package:demochat/web_api/api_call.dart';
import 'package:image_picker/image_picker.dart';
import 'package:demochat/web_api/urls.dart';

class EditProfileVc extends StatefulWidget {
  const EditProfileVc({super.key});

  @override
  State<EditProfileVc> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfileVc> {
  late TextEditingController textControllerFullName = TextEditingController();
  late TextEditingController textControllerAddress = TextEditingController();
  XFile? imageFile;
  late Image? profileImage = Image.asset(
    ImagePath.instance.userPlaceholder,
    fit: BoxFit.cover,
  );

  @override
  void initState() {
    super.initState();
    setData();
  }

  // Main widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar('Edit Profile'),
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                profileImageWidget(),
                const SizedBox(
                  height: 10,
                ),
                textFieldFullName(),
                const SizedBox(
                  height: 20,
                ),
                textFieldAddress(),
                const SizedBox(
                  height: 40,
                ),
                saveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Profile Image Widget
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
              // boxShadow: const [
              //   BoxShadow(
              //     color: Colors.white,
              //     offset: Offset(1, 1),
              //     blurRadius: 0,
              //     blurStyle: BlurStyle.normal,
              //   ),
              // ],
            ),
            child: Stack(
              children: [
                SizedBox(
                  width: containerHeight,
                  height: containerHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular((containerHeight / 2)),
                    child: profileImage,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CustomRoundButton(
                    onTap: tappedEditImage,
                    height: (containerWidth / 3) / 3.5,
                    width: (containerWidth / 3) / 3.5,
                    borderRadius: 35,
                    bgColor: Colors.white,
                    icon: Icons.camera_alt,
                    iconColor: Colors.black,
                    shadowColor: Colors.grey.shade500,
                    isShadow: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Full Name Text Field Widget
  Widget textFieldFullName() {
    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Full Name',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          CustomTextField(
              textController: textControllerFullName,
              hintText: 'Enter full name',
              obscureText: false,
              keyboardType: TextInputType.text),
        ],
      ),
    );
  }

  // Address Text Field Widget
  Widget textFieldAddress() {
    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Address',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          CustomTextField(
              textController: textControllerAddress,
              hintText: 'Enter address',
              obscureText: false,
              keyboardType: TextInputType.text),
        ],
      ),
    );
  }

  // Save Button Widget
  Widget saveButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 40),
      child: MyButtons(
        title: 'Save',
        onTap: () {
          saveProfile(null);
        },
        backgroundColor: CustomColor.instance.colorPrimary,
        height: 45,
        width: null,
      ),
    );
  }

  // Tap on Edit Image action
  Future<void> tappedEditImage() async {
    debugPrint('Opening Image Picker');
    CustomImagePicker.instance.openImagePicker(callback: (file) {
      setState(() {
        imageFile = file;
        profileImage = Image.file(
          File(imageFile!.path),
          fit: BoxFit.cover,
        );
        saveProfile(imageFile);
      });
    });
  }

  // Set Data
  setData() {
    setState(() {
      if (Singleton.instance.userDataModel?.userImageUrl != '') {
        final imageUrl =
            '${Urls.instance.fileUrl}${Singleton.instance.userDataModel?.userImageUrl}';
        imageFile = XFile(imageUrl);
        profileImage = Image.network(
          imageUrl,
          fit: BoxFit.cover,
        );
      }
      textControllerFullName.text =
          Singleton.instance.userDataModel?.fullname ?? '';
      textControllerAddress.text =
          Singleton.instance.userDataModel?.address ?? '';
    });
  }

  // Save Profile API
  saveProfile(XFile? file) {
    if (textControllerFullName.text == '') {
      showAlertOk('Alert', 'Please enter your name', callBack: () {});
    } else {
      final params = {
        'user_id': Singleton.instance.userDataModel?.userId,
        'full_name': textControllerFullName.text,
        'address': textControllerAddress.text,
      };
      if (file != null) {
        var filePath = file.path;
        APICall.instance.editProfileAPI(
            context, 'profileImage', 'profile_image', 'image/jpeg', filePath,
            params: params, callBack: (response) {});
      } else {
        APICall.instance.editProfileAPI(
          context,
          '',
          '',
          '',
          '',
          params: params,
          callBack: (response) {
            if (response) {
              showAlertOk('Alert', 'Profile data updated successfully',
                  callBack: () {
                textControllerFullName.clear();
                textControllerAddress.clear();
                Navigator.pop(context);
              });
            }
          },
        );
      }
    }
  }
}
