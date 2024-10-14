import 'package:demochat/view_models/chat_messages_model.dart';
import 'package:flutter/material.dart';
import 'package:demochat/view_models/chat_list_model.dart';
import 'package:badges/badges.dart' as badges;
import 'package:demochat/web_api/urls.dart';
import '../../../libraries/custom_classes.dart';

class ChatListCell extends StatefulWidget {
  const ChatListCell({super.key, required this.onTap, required this.model});
  final ConversationsModel model;
  final Function() onTap;
  @override
  State<ChatListCell> createState() => _ChatListCellState();
}

class _ChatListCellState extends State<ChatListCell> {
  late Image profileImage = Image.asset(
    ImagePath.instance.userPlaceholder,
    fit: BoxFit.cover,
  );
  @override
  void initState() {
    super.initState();
    setData();
  }

  setData() {
    setState(() {
      if (widget.model.conversationType == 'group'
          ? widget.model.groupImageUrl != ''
          : widget.model.userData?.userImageUrl != '') {
        final imageUrl = widget.model.conversationType == 'group'
            ? '${Urls.instance.fileUrl}${widget.model.groupImageUrl}'
            : '${Urls.instance.fileUrl}${widget.model.userData?.userImageUrl}';
        profileImage = Image.network(
          imageUrl,
          fit: BoxFit.cover,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var statusColor = widget.model.userData?.isActive == 1
        ? Colors.green
        : Colors.grey.shade400;
    // ignore: unrelated_type_equality_checks
    var lastMessage = widget.model.messageType == ChatMessageType.text
        ? Text(
            widget.model.lastMessage ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal),
          )
        : const Icon(
            Icons.image,
            size: 20,
            color: Colors.grey,
          );
    return GestureDetector(
      onTap: () {
        widget.onTap();
      },
      child: Padding(
        padding: const EdgeInsets.only(
            top: 8.0, bottom: 8.0, left: 15.0, right: 15.0),
        child: Container(
          // height: 70.0,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: <BoxShadow>[
                BoxShadow(color: Colors.grey.shade500, blurRadius: 4.0),
              ]),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                badges.Badge(
                  position: badges.BadgePosition.topStart(top: 2, start: 2),
                  showBadge:
                      widget.model.conversationType == 'group' ? false : true,
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
                  width: 10.0,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // const SizedBox(
                      //   height: 10,
                      // ),
                      Text(
                        widget.model.conversationType == 'group'
                            ? widget.model.groupName ?? ''
                            : widget.model.userData?.fullname ?? '',
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 0,
                      ),
                      lastMessage,
                      const SizedBox(
                        height: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Visibility(
                  visible: widget.model.unreadMsgCount > 0,
                  child: Container(
                    height: 20.0,
                    width: 20.0,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: CustomColor.instance.colorPrimary),
                    child: Center(
                      child: Text(
                        '${widget.model.unreadMsgCount}',
                        style: const TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
