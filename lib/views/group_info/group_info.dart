import 'dart:async';

import 'package:demochat/components/custom_alert.dart';
import 'package:demochat/constants/screen_dimention.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/view_models/chat_list_model.dart';
import 'package:flutter/material.dart';

import '../../view_models/user_data_model.dart';
import '../chats/chat_screen/chat_screen.dart';
import '../group_call/group_call.dart';

// ignore: must_be_immutable
class GroupInfo extends StatefulWidget {
  late String roomId;
  late ConversationsModel model;
  late List<UserDataModel> users;

  GroupInfo(
      {super.key,
      required this.roomId,
      required this.model,
      required this.users});

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  late bool hideAlerts = false;

  void callGroup(CallType callType) {
    debugPrint('Call Type: $callType');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupCall(
          roomId: widget.roomId,
          users: widget.users,
          isOfferingCall: true,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                  border: Border.all(
                    color: CustomColor.instance.colorPrimary,
                    width: 3,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(50)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(
                  ImagePath.instance.placeholder,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.model.groupName ?? '',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Change Name and Photo',
                style: TextStyle(color: CustomColor.instance.colorPrimary),
              ),
            ),
            const SizedBox(height: 10),
            // Call, Video, Mail buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildActionButton(Icons.call, 'Audio', () {}),
                buildActionButton(Icons.videocam, 'Video', () {
                  callGroup(CallType.video);
                }),
              ],
            ),
            const SizedBox(height: 20),
            customListTile(
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: CustomColor.instance.colorPrimary,
                  child: const Icon(Icons.people, color: Colors.white),
                ),
                title: Text('${widget.users.length} Peoples'),
                subtitle: Text(
                  widget.users.map((e) => e.fullname).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Icon(
                  size: 15,
                  Icons.arrow_forward_ios,
                  color: Colors.grey.withOpacity(0.5),
                ),
                onTap: () {},
              ),
            ),
            // Media, Links, Docs
            customListTile(
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: CustomColor.instance.colorPrimary,
                  child: const Icon(Icons.photo, color: Colors.white),
                ),
                title: const Text('Media'),
                trailing: Icon(
                  size: 15,
                  Icons.arrow_forward_ios,
                  color: Colors.grey.withOpacity(0.5),
                ),
                onTap: () {},
              ),
            ),
            // Hide Alerts
            customListTile(
              ListTile(
                title: const Text('Hide Alerts'),
                trailing: Switch(
                  value: hideAlerts,
                  onChanged: (value) {
                    setState(() {
                      hideAlerts = value;
                    });
                  },
                ),
              ),
            ),
            customListTile(
              ListTile(
                title: const Text(
                  'Leave this Conversation',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  showAlertOkCancel('Leave this Group',
                      'Are you sure you want to leave this group?',
                      callBack: (action) {
                    if (action == Buttons.ok) {
                      debugPrint('Action: $action');
                      Timer(const Duration(milliseconds: 500), () {
                        Navigator.pop(context, GroupInfoAction.leaveGroup);
                      });
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActionButton(IconData icon, String label, Function() onTap) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: CustomColor.instance.colorPrimary,
            borderRadius: BorderRadius.circular(25),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: () {
              onTap();
            },
          ),
        ),
        const SizedBox(height: 5),
        Text(label),
      ],
    );
  }

  Widget customListTile(Widget? child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: getScreenWidth() * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
          borderRadius: BorderRadius.circular(15),
        ),
        child: child,
      ),
    );
  }
}

enum GroupInfoAction { leaveGroup }
