// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:demochat/audio_player/audio_player.dart';
import 'package:demochat/audio_recorder/audio_recorder.dart';
import 'package:demochat/components/flat_button.dart';
import 'package:demochat/constants/screen_dimention.dart';
import 'package:demochat/video_recorder/video_recorder.dart';
import 'package:demochat/views/group_call/group_call.dart';
import 'package:demochat/views/group_info/group_info.dart';
import 'package:demochat/views/image_viewer/image_viewer.dart';
import 'package:demochat/views/oto_call/oto_calling.dart';
import 'package:flutter/material.dart';
import 'package:demochat/libraries/custom_widgets.dart';
import 'package:demochat/view_models/chat_list_model.dart';
import 'package:demochat/views/chats/create_group/create_group.dart';
import 'package:image_picker/image_picker.dart';
import 'package:demochat/components/custom_alert.dart';
import 'package:demochat/components/custom_round_button.dart';
import 'package:demochat/constants/global_functions.dart';
import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/view_models/chat_messages_model.dart';
import 'package:demochat/view_models/user_data_model.dart';
import 'package:demochat/views/chats/chat_screen/chat_bubble.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/socket_manager/socket_manager.dart';
import 'package:demochat/web_api/api_call.dart';
import 'package:demochat/web_api/urls.dart';
import 'package:demochat/libraries/stream_controllers.dart';
import 'package:url_launcher/url_launcher.dart';

List<Map<String, dynamic>> arrayFileSending = [];

enum ImageSourceType { camera, gallary }

class ChatScreenVc extends StatefulWidget {
  const ChatScreenVc(
      {super.key, required this.roomId, required this.conversationsModel});
  static var instance = _ChatScreenState();
  final String roomId;
  final ConversationsModel conversationsModel;
  @override
  State<ChatScreenVc> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreenVc> {
  final FocusNode _focusNode = FocusNode();
  late StreamSubscription<(Listner, dynamic)> subscription;
  late StreamSubscription<bool> subscriptionLocation;
  late Image image = Image.asset(
    widget.conversationsModel.conversationType == 'one_to_one'
        ? ImagePath.instance.userPlaceholder
        : ImagePath.instance.placeholder,
    fit: BoxFit.cover,
  );
  final AudioRecorderManager _audioRecorder = AudioRecorderManager();
  static List<ChatMessagesModel> messageListModel = [];
  static List<UserDataModel> groupUsers = [];
  final textMessageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late bool needScrolling = true;
  static bool isOTO = false;
  UserDataModel? secondUserData;
  String userStatus = '';
  Color borderColor = Colors.white;
  late Timer apiTimer;
  XFile? imageFile;
  XFile? videoFile;
  ImagePicker imagePicker = ImagePicker();
  bool isEditing = false;
  bool isAudioRecording = false;
  bool isRecordingCancel = false;
  String timerCount = '00:00';
  late Timer recoringTimer;
  var dropDownList = ['Add Member', 'Leave Group'];
  bool isSetState = false;
  bool isTyping = false;

  double startPosition = 0;
  double dx = 0.0;

  @override
  void initState() {
    super.initState();
    // debugPrint('Array: ${messageListModel.length.toString()}');
    isOTO = widget.conversationsModel.conversationType == 'one_to_one'
        ? true
        : false;
    secondUserData = isOTO ? widget.conversationsModel.userData : null;
    Timer(const Duration(milliseconds: 10), () {
      getChatMessages();
      getGroupUsers();
      setData();
    });
    subscription = chatScreenStreamController.stream.listen((onData) {
      final event = onData.$1;
      final data = onData.$2;
      switch (event) {
        case Listner.newChatMessage:
          ChatMessagesModel model = ChatMessagesModel().parseJsonData(data);
          Singleton.instance.messagesArray.add(model);
          if (model.receiverId == Singleton.instance.userDataModel?.userId &&
              isOTO) {
            seenMessage(model);
          } else {
            if (groupUsers.any((user) => user.userId == model.senderId)) {
              seenMessage(model);
            } else {
              debugPrint('Not in group');
            }
          }
          break;
        case Listner.messageSeen:
          ChatMessagesModel model = ChatMessagesModel().parseJsonData(data);
          final index = Singleton.instance.messagesArray
              .indexWhere((element) => element.messageId == model.messageId);
          Singleton.instance.messagesArray
              .replaceRange(index, index + 1, [model]);
          break;
        case Listner.uploadComplete:
          if (data != null && data['messageData'] != null) {
            final messageData = data['messageData'];
            final fileId = data['file_id'];
            Timer.periodic(const Duration(seconds: 2), (timer) {
              arrayFileSending
                  .removeWhere((element) => element['file_id'] == fileId);
              Singleton.instance.messagesArray
                  .removeWhere((element) => element.fileId == fileId);
              ChatMessagesModel model =
                  ChatMessagesModel().parseJsonData(messageData);
              Singleton.instance.messagesArray.add(model);
              if (model.receiverId ==
                  Singleton.instance.userDataModel?.userId) {
                seenMessage(model);
              }
              timer.cancel();
            });
          }
          break;
        case Listner.receiveLocationMessage:
          ChatMessagesModel model = ChatMessagesModel().parseJsonData(data);
          Singleton.instance.messagesArray.add(model);
          Singleton.instance.sharedLiveLocationData
              .add(ChatMessagesModel().parseJsonData(data));
          break;
        case Listner.isTyping:
          if (data['status'] == 'start') {
            isTyping = true;
          } else {
            isTyping = false;
          }
          break;
        default:
      }
      refreshList();
    });
    initializeLocationShareStream();
    _audioRecorder.checkMicrophonePermission();
  }

  @override
  void dispose() {
    super.dispose();
    debugPrint('Dispose');
    messageListModel.clear();
    groupUsers.clear();
    secondUserData = null;
    subscription.cancel();
    subscriptionLocation.cancel();
    AudioPlayerManager.instance.stopAudio();
  }

  void setData() {
    Singleton.instance.currentRoomId = widget.roomId;
    apiTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (isOTO) {
        // updateUserData();
      }
      apiTimer = timer;
    });
    setState(() {
      final imageUrlStr = isOTO
          ? secondUserData?.userImageUrl
          : widget.conversationsModel.groupImageUrl;
      if (imageUrlStr != '') {
        final imageUrl = '${Urls.instance.fileUrl}$imageUrlStr';
        image = Image.network(
          imageUrl,
          fit: BoxFit.cover,
        );
      }
      userStatus = isOTO
          ? secondUserData?.isActive == 1
              ? 'Online'
              : 'Offline'
          : '';
      borderColor = isOTO
          ? secondUserData?.isActive == 1
              ? Colors.green
              : Colors.white
          : Colors.white;
    });
  }

  ///
  void refreshList() {
    if (Singleton.instance.messagesArray.last.senderId ==
        Singleton.instance.userDataModel?.userId) {
      needScrolling = true;
    }
    if (mounted) {
      setState(() {
        isSetState = true;
        if (isTyping) {
          userStatus = isOTO ? 'Typing' : '';
        } else {
          userStatus = isOTO ? 'Online' : '';
        }
        messageListModel = Singleton.instance.messagesArray;
      });
    }
  }

  // Web API's
  void getChatMessages() async {
    APICall.instance.chatMessageListAPI(
        context, widget.roomId, widget.conversationsModel.conversationType,
        callBack: (dataModel) {
      messageListModel = dataModel;
      Singleton.instance.messagesArray = dataModel;
      final unseenMessages = Singleton.instance.messagesArray.where((element) =>
          (element.seen == 0 &&
              element.receiverId == Singleton.instance.userDataModel?.userId &&
              widget.conversationsModel.conversationType == 'one_to_one') ||
          (element.seen == 0 &&
              element.senderId != Singleton.instance.userDataModel?.userId &&
              widget.conversationsModel.conversationType == 'group'));
      for (var element in unseenMessages) {
        seenMessage(element);
      }
      setState(() {});
    });
  }

  void updateUserData() async {
    APICall.instance.getUserData(null, secondUserData?.userId ?? '',
        callBack: (userData) {
      if (!isTyping) {
        userStatus = userData.isActive == 1 ? 'Online' : 'Offline';
      }
      borderColor = userData.isActive == 1 ? Colors.green : Colors.white;
      setState(() {});
    });
  }

  void getGroupUsers() async {
    APICall.instance.getGroupUsers(null, widget.roomId, callBack: (dataModel) {
      final users = dataModel;
      groupUsers = users.where((element) {
        return element.userId != Singleton.instance.userDataModel?.userId;
      }).toList();
      setState(() {});
    });
  }

  void leaveGroup() {
    APICall.instance.leaveGroup(context, widget.roomId, callBack: (response) {
      if (response) {
        leaveConversation();
      }
    });
  }

  void sendTextMessage() async {
    if (textMessageController.text != '') {
      final message = textMessageController.text;
      final params = {
        'room_id': widget.roomId,
        'sender_id': Singleton.instance.userDataModel?.userId,
        'receiver_id': secondUserData?.userId,
        'message': message,
        'message_type': 'text',
        'conversation_type': widget.conversationsModel.conversationType,
      };
      textMessageController.clear();
      isEditing = false;
      SocketManager.instance
          .emitWithEvent(Emitter.sendChatMessage, params: params);
      startTyping(false);
    }
  }

  void sendFileMessage(XFile? file, String? messageType) async {
    File mediaFile = File(file!.path);
    final compressFile =
        await Singleton.instance.compressFile(mediaFile, messageType);
    if (compressFile == null) {
      return;
    }
    List<int> imageBytes = compressFile.readAsBytesSync();
    // debugPrint('Bytes count: ${imageBytes.length}');
    String base64Image = base64Encode(imageBytes);
    var fileName = '';
    if (messageType == 'image') {
      fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    } else if (messageType == 'video') {
      fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    }
    var params = {
      'room_id': widget.roomId,
      'conversation_type': widget.conversationsModel.conversationType,
      'sender_id': Singleton.instance.userDataModel?.userId,
      'receiver_id': secondUserData?.userId,
      'message_type': messageType,
      'file_id': '${widget.roomId}_${generateRandomNumber(5).toString()}',
      'file_name': fileName,
      'size': imageBytes.length,
      'data': base64Image,
    };
    arrayFileSending.add(params);
    final model = ChatMessagesModel().parseJsonData(params);
    messageListModel.add(model);
    setState(() {
      needScrolling = true;
    });
    SocketManager.instance
        .emitWithEvent(Emitter.startFileUpload, params: params);
  }

  void sendAudioMessage(
    File audioFile,
  ) async {
    List<int> bytes = audioFile.readAsBytesSync();
    // debugPrint('Bytes count: ${bytes.length}');
    if (bytes.length > 5000) {
      final base64Str = base64Encode(bytes);
      var params = {
        'room_id': widget.roomId,
        'conversation_type': widget.conversationsModel.conversationType,
        'sender_id': Singleton.instance.userDataModel?.userId,
        'receiver_id': secondUserData?.userId,
        'message_type': 'audio',
        'file_name': currentFileName,
        'file_id': '${widget.roomId}_${generateRandomNumber(5).toString()}',
        'size': bytes.length,
        'data': base64Str,
      };
      arrayFileSending.add(params);
      final model = ChatMessagesModel().parseJsonData(params);
      messageListModel.add(model);
      setState(() {
        needScrolling = true;
      });
      SocketManager.instance
          .emitWithEvent(Emitter.startFileUpload, params: params);
    }
  }

  void sendVideoMessage(File file) {
    final bytes = file.readAsBytesSync();
    // debugPrint('Bytes count: ${bytes.length}');
    final base64Str = base64Encode(bytes);
    var params = {
      'room_id': widget.roomId,
      'conversation_type': widget.conversationsModel.conversationType,
      'sender_id': Singleton.instance.userDataModel?.userId,
      'receiver_id': secondUserData?.userId,
      'message_type': 'video',
      'file_name': currentFileName,
      'file_id': '${widget.roomId}_${generateRandomNumber(5).toString()}',
      'file_path': '',
      'size': bytes.length,
      'data': base64Str,
    };
    arrayFileSending.add(params);
    final model = ChatMessagesModel().parseJsonData(params);
    messageListModel.add(model);
    setState(() {
      needScrolling = true;
    });
    SocketManager.instance
        .emitWithEvent(Emitter.startFileUpload, params: params);
  }

  void sendLocationMessage(String messageType, bool isLive) {
    final messageData = {
      'room_id': widget.roomId,
      'sender_id': Singleton.instance.userDataModel?.userId ?? '',
      'location_id': '${widget.roomId}_${generateRandomNumber(5).toString()}',
      'receiver_id': secondUserData?.userId,
      'latitude': Singleton.instance.locationManager?.currentPosition?.latitude,
      'longitude':
          Singleton.instance.locationManager?.currentPosition?.longitude,
      'message_type': messageType,
      'conversation_type': widget.conversationsModel.conversationType,
    };
    SocketManager.instance
        .emitWithEvent(Emitter.sendLocationMessage, params: messageData);
    Singleton.instance.isLiveLocationSharing = isLive;
  }

  void seenMessage(ChatMessagesModel model) {
    var params = {
      'room_id': isOTO ? model.otoConversationId : model.groupId,
      'conversation_type': isOTO ? 'one_to_one' : 'group',
      'message_id': model.messageId,
      'sender_id': model.senderId,
      'receiver_id': model.receiverId,
      'message': model.message,
      'file_path': model.filePath,
      'seen': 1,
      'sent': model.sent,
      'message_type': model.messageType.name,
    };
    // debugPrint('$params');
    SocketManager.instance
        .emitWithEvent(Emitter.seenChatMessage, params: params);
  }

  void startTyping(bool status) {
    var params = {
      'room_id': widget.roomId,
      'sender_id': Singleton.instance.userDataModel?.userId,
      'receiver_id': secondUserData?.userId
    };
    if (status) {
      SocketManager.instance.emitWithEvent(Emitter.startTyping, params: params);
    } else {
      SocketManager.instance.emitWithEvent(Emitter.stopTyping, params: params);
    }
  }

  void leaveConversation() {
    SocketManager.instance.emitWithEvent(Emitter.leaveConversation, params: {
      'room_id': widget.roomId,
      'user_id': Singleton.instance.userDataModel?.userId
    });
    Singleton.instance.currentRoomId = null;
    if (!Singleton.instance.isAppStoped) {
      subscription.cancel();
      apiTimer.cancel();
    }
    Navigator.pop(context);
  }

  void onListen(Listner event, dynamic data) async {
    switch (event) {
      case Listner.newChatMessage:
        chatScreenStreamController.add((Listner.newChatMessage, data));
        break;
      case Listner.messageSeen:
        chatScreenStreamController.add((Listner.messageSeen, data));
        break;
      case Listner.uploadingDataReq:
        final index = arrayFileSending
            .indexWhere((element) => element['file_id'] == data['file_id']);
        var params = arrayFileSending[index];
        params['file_path'] = data['file_path'];
        SocketManager.instance
            .emitWithEvent(Emitter.uploadFileReq, params: params);
        break;
      case Listner.uploadComplete:
        chatScreenStreamController.add((Listner.uploadComplete, data));
        break;
      case Listner.receiveLocationMessage:
        chatScreenStreamController.add((Listner.receiveLocationMessage, data));
        break;
      case Listner.isTyping:
        chatScreenStreamController.add((Listner.isTyping, data));
        break;
      case Listner.conversationLeft:
        break;
      default:
        break;
    }
  }

  void scrollToEnd() {
    scrollController.animateTo((scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 10), curve: Curves.easeOut);
    needScrolling = false;
  }

  void startAudioRecording() async {
    try {
      final status = await _audioRecorder.init(
          widget.roomId, Singleton.instance.userDataModel?.userId ?? '');
      if (status) {
        startRecordingTimer();
        await _audioRecorder.startRecording();
        debugPrint('Recording Started');
      } else {
        showAlertOkCancel('',
            'Please provide microphone permission from setting to send audio recording',
            callBack: (action) {
          if (action == Buttons.ok) {
            openSettings();
          }
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void stopAudioRecording() async {
    try {
      stopRecordingTimer();
      if (isRecordingCancel) {
        await _audioRecorder.deleteRecording();
        isRecordingCancel = false;
        return;
      } else {
        final audioFile = await _audioRecorder.stopRecording();
        if (audioFile == null) {
          debugPrint('No audio file received');
          return;
        }
        sendAudioMessage(audioFile);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void startRecordingTimer() {
    recoringTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final minutes = int.parse(timerCount.split(':')[0]);
      final seconds = int.parse(timerCount.split(':')[1]);
      if (seconds < 59) {
        if (seconds < 9) {
          setState(() {
            timerCount = '$minutes:0${seconds + 1}';
            FocusScope.of(context).requestFocus();
          });
        } else {
          setState(() {
            timerCount = '$minutes:${seconds + 1}';
          });
        }
      } else {
        setState(() {
          timerCount = '${minutes + 1}:00';
        });
      }
    });
  }

  void stopRecordingTimer() {
    recoringTimer.cancel();
    setState(() {
      timerCount = '00:00';
    });
  }

  void sendCurrentLocation() {
    final params = {
      'room_id': widget.roomId,
      'sender_id': Singleton.instance.userDataModel?.userId,
      'receiver_id': secondUserData?.userId,
      'latitude': Singleton.instance.locationManager?.currentPosition?.latitude,
      'longitude':
          Singleton.instance.locationManager?.currentPosition?.longitude,
      'conversation_type': widget.conversationsModel.conversationType,
    };
    SocketManager.instance
        .emitWithEvent(Emitter.shareLiveLocation, params: params);
  }

  void callUser(CallType callType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTOCallScreen(
          userDataModel: secondUserData,
          isMakingCall: true,
          isVideoCall: callType == CallType.video ? true : false,
          isAudioCall: callType == CallType.audio ? true : false,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void callGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupCall(
          roomId: widget.roomId,
          users: groupUsers,
          isOfferingCall: true,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void initializeLocationShareStream() {
    subscriptionLocation =
        shareLiveLocationStreamController.stream.listen((event) {
      sendCurrentLocation();
    });
  }

  void openSettings() async {
    var url = '';
    if (Platform.isIOS) {
      url = 'app-settings:';
    } else {
      url = 'package:com.android.settings';
    }
    final setingUrl = Uri.parse(url);
    if (await canLaunchUrl(setingUrl)) {
      await launchUrl(setingUrl);
    }
  }

  void tappedCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoRecorderScreen(roomId: widget.roomId),
        fullscreenDialog: true,
      ),
    ).then((videoFile) {
      if (videoFile != null) {
        sendVideoMessage(videoFile);
      }
    });
  }

  void tappedGallary() async {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) => showGallaryOptionBottomSheet(),
    ).whenComplete(() {
      // debugPrint('Gallary Sheet Closed');
      _focusNode.unfocus();
    });
  }

  void tappedLocation() {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) => showLocationOptionBottomSheet(),
    ).whenComplete(() {
      // debugPrint('Location Sheet Closed');
      _focusNode.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (needScrolling) {
      Timer.periodic(const Duration(milliseconds: 500), (timer) {
        scrollToEnd();
        timer.cancel();
      });
    }
    return loader(
      Container(
        color: CustomColor.instance.colorAppBar,
        child: SafeArea(
          child: Scaffold(
            appBar: AppBar(
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: SafeArea(
                child: Container(
                  padding: const EdgeInsets.only(right: 4),
                  child: Row(
                    children: <Widget>[
                      buttonBack(),
                      const SizedBox(
                        width: 2,
                      ),
                      imageChatProfile(),
                      const SizedBox(
                        width: 12,
                      ),
                      textChatTitleDesc(),
                      const Spacer(),
                      buttonVideoCall(),
                      Visibility(
                        visible: isOTO,
                        child: buttonAudioCall(),
                      ),
                      Visibility(
                        visible: !isOTO,
                        child: dropDownButton(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: SafeArea(
              child: GestureDetector(
                onTap: () {
                  _focusNode.unfocus();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 80),
                  controller: scrollController,
                  itemCount: messageListModel.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    return ChatBubble(
                      index: index,
                      message: messageListModel[index],
                      isOTO: isOTO,
                      isSetingState: isSetState,
                      userDataModel: secondUserData,
                    );
                  },
                ),
              ),
            ),
            bottomSheet: bottomSheet(context),
          ),
        ),
      ),
    );
  }

  Widget buttonBack() {
    return IconButton(
      onPressed: () {
        leaveConversation();
      },
      icon: const Icon(
        Icons.arrow_back_ios,
        color: Colors.white,
      ),
    );
  }

  Widget imageChatProfile() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageViewer(
              imageUrl:
                  '${isOTO ? secondUserData?.userImageUrl : widget.conversationsModel.groupImageUrl}',
            ),
            fullscreenDialog: true,
          ),
        );
      },
      child: Container(
        height: 45,
        width: 45,
        decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: 3,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(22.5)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.5),
          child: image,
        ),
      ),
    );
  }

  Widget textChatTitleDesc() {
    return GestureDetector(
      onTap: () {
        if (!isOTO) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupInfo(
                roomId: widget.roomId,
                model: widget.conversationsModel,
                users: groupUsers,
              ),
              fullscreenDialog: true,
            ),
          ).then((value) {
            if (value == null) return;
            switch (value as GroupInfoAction) {
              case GroupInfoAction.leaveGroup:
                leaveGroup();
                break;
              default:
            }
          });
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            isOTO
                ? secondUserData?.fullname ?? ''
                : widget.conversationsModel.groupName ?? '',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            userStatus,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget buttonVideoCall() {
    return IconButton(
      onPressed: () {
        isOTO ? callUser(CallType.video) : callGroup();
      },
      icon: const Icon(
        Icons.videocam,
        color: Colors.white,
      ),
    );
  }

  Widget buttonAudioCall() {
    return IconButton(
      onPressed: () {
        isOTO ? callUser(CallType.audio) : callGroup();
      },
      icon: const Icon(
        Icons.call,
        color: Colors.white,
      ),
    );
  }

  Widget dropDownButton() {
    return PopupMenuButton(
        offset: const Offset(0, 45),
        shadowColor: CustomColor.instance.colorPrimary,
        icon: const Icon(
          Icons.more_vert,
          color: Colors.white,
        ),
        onSelected: (value) {
          if (value == 'Add Member') {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: CreateGroup(
                    type: 'add_member',
                    groupId: widget.roomId,
                    groupMembers: groupUsers,
                  ),
                );
              },
            ).then((value) => {
                  getGroupUsers(),
                });
          } else {
            showAlertOk('Alert', 'Are you sure you want to leave group?',
                callBack: () {
              leaveGroup();
            });
          }
        },
        itemBuilder: (BuildContext context) {
          return dropDownList.map((String choice) {
            return PopupMenuItem(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        });
  }

  Widget bottomSheet(BuildContext context) {
    return Container(
      width: double.infinity,
      color: CustomColor.instance.colorPrimary,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomRoundButton(
              height: 40,
              width: 40,
              borderRadius: 20,
              bgColor: Colors.white,
              icon: Icons.attach_file,
              iconColor: CustomColor.instance.colorPrimary,
              shadowColor: Colors.white,
              onTap: () {
                showModalBottomSheet(
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (BuildContext context) => attachmentSheet(),
                ).whenComplete(() {
                  // debugPrint('Attachment Sheet Closed');
                  _focusNode.unfocus();
                });
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: isAudioRecording
                      ? showRecordingTimer()
                      : textFieldEnterMsg(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            isEditing ? buttonSendMessage() : buttonAudioRecord(),
          ],
        ),
      ),
    );
  }

  Widget createIcon(Color color, IconData icon, String title,
      {required Function onTap}) {
    return InkWell(
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      child: Column(
        children: [
          CircleAvatar(
              radius: 25,
              backgroundColor: color,
              child: Icon(
                icon,
                color: Colors.white,
              )),
          const SizedBox(
            height: 5,
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget attachmentSheet() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  createIcon(
                    Colors.pink,
                    Icons.camera_enhance,
                    'Camera',
                    onTap: () {
                      // debugPrint('Tap Camera');
                      Timer(const Duration(microseconds: 200), () {
                        tappedCamera();
                      });
                    },
                  ),
                  const SizedBox(width: 30),
                  createIcon(
                    Colors.purple,
                    Icons.image,
                    'Gallary',
                    onTap: () {
                      // debugPrint('Tap Gallary');
                      Timer(const Duration(microseconds: 200), () {
                        tappedGallary();
                      });
                    },
                  ),
                  const SizedBox(width: 30),
                  createIcon(
                    Colors.teal,
                    Icons.location_pin,
                    'Location',
                    onTap: () {
                      Timer(const Duration(microseconds: 200), () {
                        tappedLocation();
                      });
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget textFieldEnterMsg() {
    return TextField(
      controller: textMessageController,
      focusNode: _focusNode,
      keyboardType: TextInputType.multiline,
      minLines: 1,
      maxLines: 4,
      onChanged: (value) {
        if (value != '') {
          startTyping(true);
        } else {
          startTyping(false);
        }
        setState(() {
          isEditing = value != '' ? true : false;
        });
      },
      onEditingComplete: () {
        _focusNode.unfocus();
        startTyping(false);
      },
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: 'Enter your message...',
      ),
      style: const TextStyle(
        color: Colors.black,
        fontSize: 15,
      ),
    );
  }

  Widget buttonSendMessage() {
    return CustomRoundButton(
      height: 40,
      width: 40,
      borderRadius: 20,
      bgColor: Colors.white,
      icon: Icons.send,
      iconColor: CustomColor.instance.colorPrimary,
      shadowColor: Colors.white,
      onTap: () {
        sendTextMessage();
      },
    );
  }

  Widget buttonAudioRecord() {
    return GestureDetector(
      onPanStart: (details) {
        startPosition = details.localPosition.dx;
        // debugPrint('Start position: $startPosition');
      },
      onPanUpdate: (details) {
        final currentPosition = details.localPosition;
        dx = currentPosition.dx - startPosition;
      },
      onPanEnd: (details) {
        startPosition = 0;
        if (dx < -50) {
          setState(() {
            isRecordingCancel = true;
            isAudioRecording = false;
          });
        } else {
          isRecordingCancel = false;
          isAudioRecording = false;
        }
        stopAudioRecording();
      },
      child: CustomRoundButton(
        height: 40,
        width: 40,
        borderRadius: 20,
        bgColor: Colors.white,
        icon: Icons.mic,
        iconColor: CustomColor.instance.colorPrimary,
        shadowColor: Colors.white,
        onTap: () {},
        onTapUp: () {
          isAudioRecording = false;
          stopAudioRecording();
        },
        onTapDown: () {
          isAudioRecording = true;
          startAudioRecording();
        },
      ),
    );
  }

  Widget showRecordingTimer() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '$timerCount Recording...',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14),
            ),
            const Spacer(),
            const Text(
              'Slide to cancel',
            )
          ],
        ),
      ),
    );
  }

  Widget showGallaryOptionBottomSheet() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Container(
          height: 130,
          width: getScreenWidth(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 45,
                  child: CustomTextButton(
                      onTap: () async {
                        Navigator.pop(context);
                        imageFile = await imagePicker.pickImage(
                            source: ImageSource.gallery);
                        if (imageFile != null) {
                          sendFileMessage(imageFile, 'image');
                        }
                      },
                      title: 'Image',
                      fontSize: 20.0,
                      fontWeight: FontWeight.normal,
                      textColor: Colors.black),
                ),
                SizedBox(
                  height: 45,
                  child: CustomTextButton(
                      onTap: () async {
                        Navigator.pop(context);
                        videoFile = await imagePicker.pickVideo(
                            source: ImageSource.gallery);
                        if (videoFile != null) {
                          sendFileMessage(videoFile, 'video');
                        }
                      },
                      title: 'Video',
                      fontSize: 20.0,
                      fontWeight: FontWeight.normal,
                      textColor: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget showLocationOptionBottomSheet() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Container(
          height: 130,
          width: getScreenWidth(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 45,
                  child: CustomTextButton(
                      onTap: () {
                        Navigator.pop(context);
                        sendLocationMessage('location', false);
                      },
                      title: 'Share Current Location',
                      fontSize: 20.0,
                      fontWeight: FontWeight.normal,
                      textColor: Colors.black),
                ),
                SizedBox(
                  height: 45,
                  child: CustomTextButton(
                      onTap: () {
                        Navigator.pop(context);
                        sendLocationMessage('liveLocation', true);
                      },
                      title: 'Share Live Location',
                      fontSize: 20.0,
                      fontWeight: FontWeight.normal,
                      textColor: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum GroupAction { addMember, leaveGroup }

enum CallType { audio, video }
