import 'package:flutter/material.dart';
import 'package:demochat/view_models/user_data_model.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:badges/badges.dart' as badges;
import 'package:demochat/web_api/urls.dart';

// ignore: must_be_immutable
class UserCell extends StatefulWidget {
  UserCell(
      {super.key, required this.tag, required this.onTap, required this.model});
  static final instance = _UserCellState();
  int tag;
  UserDataModel model;
  final Function() onTap;

  @override
  State<UserCell> createState() => _UserCellState();
}

class _UserCellState extends State<UserCell> {
  late Image profileImage = Image.asset(
    ImagePath.instance.userPlaceholder,
    fit: BoxFit.cover,
  );

  @override
  void initState() {
    super.initState();
    setData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  setData() {
    setState(() {
      if (widget.model.userImageUrl != '') {
        final imageUrl = '${Urls.instance.fileUrl}${widget.model.userImageUrl}';
        profileImage = Image.network(
          imageUrl,
          fit: BoxFit.cover,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var statusColor =
        widget.model.isActive == 1 ? Colors.green : Colors.grey.shade400;
    return GestureDetector(
      onTap: () {
        widget.onTap();
      },
      child: Padding(
        padding: const EdgeInsets.only(
            top: 8.0, bottom: 8.0, left: 15.0, right: 15.0),
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
              badges.Badge(
                position: badges.BadgePosition.topStart(top: 2, start: 2),
                showBadge: true,
                badgeStyle: badges.BadgeStyle(
                    badgeColor: statusColor, shape: badges.BadgeShape.circle),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: CustomColor.instance.colorPrimary,
                        width: 3,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(25)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: profileImage,
                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}
