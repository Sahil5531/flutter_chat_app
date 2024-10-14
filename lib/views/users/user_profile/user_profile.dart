import 'dart:async';
import 'package:demochat/view_models/chat_list_model.dart';
import 'package:flutter/material.dart';
import 'package:demochat/constants/screen_dimention.dart';
import 'package:demochat/libraries/custom_widgets.dart';
import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/socket_manager/socket_manager.dart';
import 'package:demochat/view_models/user_data_model.dart';
import 'package:demochat/views/chats/chat_screen/chat_screen.dart';
import 'package:demochat/components/my_button.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/web_api/api_call.dart';
import 'package:demochat/web_api/urls.dart';

StreamController<bool> streamController = StreamController<bool>.broadcast();

class UserProfileVc extends StatefulWidget {
  const UserProfileVc({super.key, required this.userData});
  static final instance = _UserProfileVcState();
  final UserDataModel userData;
  @override
  State<UserProfileVc> createState() => _UserProfileVcState();
}

class _UserProfileVcState extends State<UserProfileVc> {
  late StreamSubscription<bool> subscription;
  late Image profileImage;
  late String buttonTitle = 'Add';
  late Color? buttonBgColor = CustomColor.instance.colorPrimary;
  late bool isHideRejectButton = true;
  late bool response = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 10), () {
      checkFriendStatus();
      setData();
      subscription = streamController.stream.listen((event) {
        refreshItem();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    subscription.cancel();
  }

  // Set the profile image based on the user's data
  setData() {
    setState(() {
      if (widget.userData.userImageUrl != '') {
        final imageUrl =
            '${Urls.instance.fileUrl}${widget.userData.userImageUrl}';
        profileImage = Image.network(
          imageUrl,
          fit: BoxFit.cover,
        );
      } else {
        profileImage = Image.asset(
          ImagePath.instance.userPlaceholder,
          fit: BoxFit.cover,
        );
      }
    });
  }

  // Refresh the UI based on the event called
  refreshItem() {
    if (mounted) {
      setState(() {
        switch (Singleton.instance.eventCalled) {
          case Listner.newFriendRequest:
            buttonTitle = 'Request Sent';
            buttonBgColor = Colors.grey.shade400;
            break;
          case Listner.acceptedRequest:
            isHideRejectButton = true;
            buttonTitle = 'Message';
            buttonBgColor = CustomColor.instance.colorPrimary;
            break;
          case Listner.rejectedRequest:
            isHideRejectButton = true;
            buttonTitle = 'Add';
            buttonBgColor = CustomColor.instance.colorPrimary;
            break;
          default:
            // Handle the 'Listner.userConnected' case here
            break;
        }
      });
    }
  }

  // Check the friend status of the user
  Future checkFriendStatus() async {
    APICall.instance.checkFriendStatusAPI(
      context,
      friendId: widget.userData.userId,
      callBack: (json) {
        setState(() {
          if (json is String) {
            response = true;
            buttonTitle = 'Add';
            buttonBgColor = null;
          } else if (json is Map<String, dynamic>) {
            final status = json['request_status'] as String;
            switch (status) {
              case 'pending':
                if (json['sender_id'] ==
                    Singleton.instance.userDataModel?.userId) {
                  buttonTitle = 'Request Sent';
                  buttonBgColor = Colors.grey.shade400;
                } else {
                  buttonTitle = 'Accept';
                  buttonBgColor = null;
                  isHideRejectButton = false;
                }
                break;
              case 'accepted':
                buttonTitle = 'Message';
                buttonBgColor = null;
                break;
              case 'rejected':
                isHideRejectButton = true;
                buttonTitle = 'Add';
                buttonBgColor = CustomColor.instance.colorPrimary;
                break;
              default:
                break;
            }
            response = true;
          }
        });
      },
    );
  }

  // Add a friend
  Future addFriend() async {
    final params = {
      'sender_id': Singleton.instance.userDataModel?.userId,
      'receiver_id': widget.userData.userId,
    };
    SocketManager.instance
        .emitWithEvent(Emitter.sendFriendRequest, params: params);
  }

  // Create a chat room
  Future createChatRoom() async {
    final params = {
      'sender_id': Singleton.instance.userDataModel?.userId,
      'receiver_id': widget.userData.userId,
    };
    SocketManager.instance
        .emitWithEvent(Emitter.createOTOConversation, params: params);
  }

  // Handle the events received from the socket
  Future onListen(Listner event, dynamic data) async {
    switch (event) {
      case Listner.createAndConnectedOTOConversation:
        Singleton.instance.conversationsModel =
            ConversationsModel().parseJsonData(data);
        Navigator.push(
          Singleton.instance.context,
          MaterialPageRoute(
            builder: (context) => ChatScreenVc(
              roomId: Singleton.instance.conversationsModel.conversationType ==
                      'group'
                  ? Singleton.instance.conversationsModel.groupId ?? ''
                  : Singleton
                          .instance.conversationsModel.oneToOneConversationId ??
                      '',
              conversationsModel: Singleton.instance.conversationsModel,
            ),
          ),
        );
        break;
      case Listner.newFriendRequest:
        Singleton.instance.eventCalled = Listner.newFriendRequest;
        streamController.add(true);
        break;
      case Listner.acceptedRequest:
        Singleton.instance.eventCalled = Listner.acceptedRequest;
        streamController.add(true);
        break;
      case Listner.rejectedRequest:
        Singleton.instance.eventCalled = Listner.rejectedRequest;
        streamController.add(true);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return loader(
      response
          ? Scaffold(
              appBar: appBar('Profile'),
              body: Center(
                child: SafeArea(
                  minimum: const EdgeInsets.fromLTRB(0, 0, 0, 60),
                  child: Column(
                    children: [
                      profileImageWidget(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 40, right: 40),
                          child: Column(
                            children: [
                              userInfoWidget(),
                              const Spacer(),
                              buttonAddAccept(),
                              const SizedBox(height: 20),
                              Visibility(
                                visible: !isHideRejectButton,
                                child: buttonReject(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Scaffold(
              appBar: AppBar(
                backgroundColor: CustomColor.instance.colorPrimary,
                title: const Text(
                  'Profile',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }

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

  Widget userInfoWidget() {
    return Column(
      children: [
        Text(
          widget.userData.fullname,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          widget.userData.phoneNumber,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          widget.userData.address,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.normal,
          ),
        )
      ],
    );
  }

  Widget buttonAddAccept() {
    return MyButtons(
      title: buttonTitle,
      onTap: () {
        switch (buttonTitle) {
          case 'Message':
            createChatRoom();
            break;
          case 'Add':
            addFriend();
            break;
          case 'Accept':
            Singleton.instance
                .acceptOrRejctRequest('accepted', widget.userData.userId);
            break;
          default:
            break;
        }
      },
      backgroundColor: buttonBgColor,
      height: 45,
      width: null,
    );
  }

  Widget buttonReject() {
    return MyButtons(
      title: 'Reject',
      onTap: () {
        Singleton.instance
            .acceptOrRejctRequest('rejected', widget.userData.userId);
      },
      backgroundColor: Colors.red,
      height: 45,
      width: null,
    );
  }
}

class RoundCliper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height / 1.3);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height / 1.3);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
