import 'package:flutter/material.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/view_models/user_data_model.dart';
import 'package:demochat/components/custom_button.dart';

class FriendRequestCell extends StatefulWidget {
  const FriendRequestCell(
      {super.key, required this.model, required this.index});
  final UserDataModel model;
  final int index;

  @override
  State<FriendRequestCell> createState() => FriendRequestCellState();
}

class FriendRequestCellState extends State<FriendRequestCell> {
  @override
  Widget build(BuildContext context) {
    var buttonAccept = CustomButton(
        onTap: () {
          Singleton.instance
              .acceptOrRejctRequest('accepted', widget.model.userId);
        },
        title: 'Accept',
        height: 30,
        width: 70,
        backgroundColor: CustomColor.instance.colorPrimary,
        borderRadius: 15,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        textColor: Colors.white);
    var buttonReject = CustomButton(
        onTap: () {
          Singleton.instance
              .acceptOrRejctRequest('rejected', widget.model.userId);
        },
        title: 'Reject',
        height: 30,
        width: 70,
        backgroundColor: Colors.grey.shade600,
        borderRadius: 15,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        textColor: Colors.white);
    return Padding(
      padding:
          const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 15.0, right: 15.0),
      child: Container(
        height: 70.0,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: <BoxShadow>[
              BoxShadow(color: Colors.grey.shade500, blurRadius: 4.0),
            ]),
        child: Row(
          children: [
            const SizedBox(
              width: 10.0,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                ImagePath.instance.userPlaceholder,
                height: 40,
                width: 40,
              ),
            ),
            const SizedBox(
              width: 20.0,
            ),
            Text(
              widget.model.fullname,
              style: const TextStyle(
                  fontSize: 15.0, fontWeight: FontWeight.normal),
            ),
            const Spacer(),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: buttonAccept,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: buttonReject,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
