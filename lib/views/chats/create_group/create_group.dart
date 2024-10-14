import 'dart:async';

import 'package:demochat/components/custom_alert.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/libraries/custom_widgets.dart';
import 'package:demochat/view_models/user_data_model.dart';
import 'package:demochat/web_api/api_call.dart';
import 'package:flutter/material.dart';

import '../../../libraries/singleton.dart';

class CreateGroup extends StatefulWidget {
  const CreateGroup({
    super.key,
    required this.type,
    required this.groupId,
    required this.groupMembers,
  });
  final String type;
  final String groupId;
  final List<UserDataModel> groupMembers;

  @override
  // ignore: library_private_types_in_public_api
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  static List<UserDataModel> usersListModel = [];

  List<bool> selected = [];
  TextEditingController enterGroupName = TextEditingController();

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 10), () {
      getUserList();
    });
  }

  @override
  void dispose() {
    super.dispose();
    usersListModel.clear();
  }

  /// Web API's
  void getUserList() {
    APICall.instance.usersListAPI(context, callBack: (dataModel) {
      setState(() {
        usersListModel = dataModel;
        usersListModel = dataModel.where((element) {
          return widget.groupMembers
              .every((member) => member.userId != element.userId);
        }).toList();
        selected = List<bool>.filled(usersListModel.length, false);
      });
    });
  }

  void createGroup(List<String> selectedUsers) {
    if (enterGroupName.text.isEmpty) {
      showAlertOk('Alert', 'Please enter group name.');
      return;
    }
    APICall.instance.createGroup(context, enterGroupName.text, selectedUsers,
        callBack: (response) {
      if (response) {
        Navigator.pop(context);
      } else {
        showAlertOk('Alert', 'Group Already Exist.');
      }
    });
  }

  void addMember(List<String> selectedUsers) {
    APICall.instance.addMembersToGroup(context, widget.groupId, selectedUsers,
        callBack: (response) {
      if (response) {
        Navigator.pop(context);
      } else {
        showAlertOk('Alert', 'Something went wrong.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return loader(
      Column(
        children: [
          navigationBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Visibility(
                    visible: widget.type == 'create_group' ? true : false,
                    child: groupNameTextField(),
                  ),
                  const SizedBox(height: 10.0),
                  usersListModel.isNotEmpty
                      ? usersListing()
                      : const Text('No users available'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget navigationBar() {
    return Container(
      height: 50.0,
      decoration: BoxDecoration(
        color: CustomColor.instance.colorAppBar,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white, fontSize: 15.0),
            ),
          ),
          const Spacer(),
          Text(
            widget.type == 'create_group'
                ? 'Create Group'
                : 'Select Members to Add',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              final List<String> selectedUsers = [];
              for (var i = 0; i < selected.length; i++) {
                if (selected[i]) {
                  selectedUsers.add(usersListModel[i].userId);
                }
              }
              if (widget.type == 'create_group') {
                selectedUsers.add(Singleton.instance.userDataModel!.userId);
              }
              widget.type == 'create_group'
                  ? createGroup(selectedUsers)
                  : addMember(selectedUsers);
            },
            child: Text(
              widget.type == 'create_group' ? 'Create' : 'Add',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget groupNameTextField() {
    return SizedBox(
      height: 80.0,
      child: TextField(
        controller: enterGroupName,
        decoration: const InputDecoration(
          hintText: 'Enter Group Name',
        ),
      ),
    );
  }

  Widget usersListing() {
    return Expanded(
      child: ListView.builder(
        itemCount: usersListModel.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/user.png'),
            ),
            title: Text(usersListModel[index].fullname),
            trailing: Checkbox(
              value: selected[index],
              shape: const CircleBorder(),
              onChanged: (value) {
                setState(() {
                  selected[index] = value ?? false;
                });
              },
            ),
          );
        },
      ),
    );
  }
}
