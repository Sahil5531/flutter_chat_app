// ignore_for_file: must_be_immutable, library_private_types_in_public_api

import 'package:demochat/constants/screen_dimention.dart';
import 'package:demochat/web_api/urls.dart';
import 'package:flutter/material.dart';

import '../../view_models/user_data_model.dart';

class UserListPopup extends StatefulWidget {
  UserListPopup({super.key, required this.userList});
  late List<UserDataModel> userList;
  @override
  _UserListPopupState createState() => _UserListPopupState();
}

class _UserListPopupState extends State<UserListPopup> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 20),
        child: SizedBox(
          height: getScreenHeight() * 0.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Group Members',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.close,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                itemCount: widget.userList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: widget
                              .userList[index].userImageUrl.isNotEmpty
                          ? NetworkImage(
                              '${Urls.instance.fileUrl}${widget.userList[index].userImageUrl}')
                          : const AssetImage('assets/images/user.png')
                              as ImageProvider,
                    ),
                    title: Text(
                      widget.userList[index].fullname,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return const Divider(
                    thickness: 0,
                    color: Colors.grey,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
