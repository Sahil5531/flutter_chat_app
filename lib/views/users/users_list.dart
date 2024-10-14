import 'dart:async';

import 'package:flutter/material.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/view_models/user_data_model.dart';
import 'package:demochat/views/users/user_profile/user_profile.dart';
import 'package:demochat/views/users/users_cell.dart';
import 'package:demochat/web_api/api_call.dart';

class UsersVc extends StatefulWidget {
  const UsersVc({super.key});
  static var instance = _UsersVCState();
  @override
  State<UsersVc> createState() => _UsersVCState();
}

class _UsersVCState extends State<UsersVc> {
  List<UserDataModel> usersListModel = [];
  @override
  void initState() {
    super.initState();
    getUserList(context);
  }

  Future getUserList(BuildContext? context) async {
    APICall.instance.usersListAPI(context, callBack: (dataModel) {
      usersListModel = dataModel;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () {
          return Future(() {
            getUserList(null);
          });
        },
        color: CustomColor.instance.colorPrimary,
        child: Center(
          child: usersListModel.isEmpty
              ? const Text(
                  'No user found.',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.normal,
                  ),
                )
              : ListView.builder(
                  itemCount: usersListModel.length,
                  itemBuilder: (BuildContext context, int index) {
                    return UserCell(
                      tag: index,
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UserProfileVc(
                                      userData: usersListModel[index],
                                    )));
                      },
                      model: usersListModel[index],
                    );
                  },
                ),
        ),
      ),
    );
  }
}
