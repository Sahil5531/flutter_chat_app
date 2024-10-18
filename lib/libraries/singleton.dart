import 'dart:io';

import 'package:demochat/location_manager/location_manager.dart';
import 'package:demochat/notification_manager/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:demochat/socket_manager/socket_manager.dart';
import 'package:demochat/view_models/chat_list_model.dart';
import 'package:demochat/view_models/chat_messages_model.dart';
import 'package:demochat/view_models/user_data_model.dart';
import 'package:demochat/web_api/api_call.dart';
import 'package:video_compress/video_compress.dart';

class Singleton {
  static final instance = Singleton();
  LocationManager? locationManager;
  NotificationManager? notificationManager;
  UserDataModel? userDataModel;
  String fcmToken = '';
  late bool isUserConnected = false;
  late String authenticationToken = '';
  late BuildContext context;
  late List<ChatMessagesModel> messagesArray = [];
  late List<ConversationsModel> arrayConversationModel = [];
  late Listner eventCalled;
  late ConversationsModel conversationsModel;
  late UserDataModel selectedUser;
  late int friendRequestCounts = 0;
  late bool isAppStoped = false;
  String? currentRoomId;
  late List<ChatMessagesModel> sharedLiveLocationData = [];
  late bool isLiveLocationSharing = false;
  late bool isCallStarted = false;

  // Common Functions.
  getFriendRequest(BuildContext? context, {required Function callBack}) {
    APICall.instance.getFriendRequestsAPI(context, callBack: (data) {
      Singleton.instance.friendRequestCounts = data.length;
      debugPrint('${Singleton.instance.friendRequestCounts}');
      callBack(data);
    });
  }

  acceptOrRejctRequest(String action, String senderId) {
    final params = {
      'receiver_id': Singleton.instance.userDataModel?.userId,
      'sender_id': senderId,
      'action': action
    };
    SocketManager.instance
        .emitWithEvent(Emitter.acceptOrRejectRequest, params: params);
  }

  changeUserActiveStatus(dynamic params) {
    SocketManager.instance
        .emitWithEvent(Emitter.userActiveInactive, params: params);
  }

  Future<File?> compressFile(File file, String? type) async {
    switch (type) {
      case 'image':
        var imageBytes = await FlutterImageCompress.compressWithFile(
          file.path,
          quality: 10, // Adjust quality as needed
        );
        debugPrint('Compress Bytes count: ${imageBytes?.length}');
        return file.writeAsBytes(imageBytes!);
      case 'video':
        final info = await VideoCompress.compressVideo(
          file.path,
          quality: VideoQuality.MediumQuality,
          includeAudio: true,
          frameRate: 30,
          deleteOrigin: true,
        );
        final compressedFile = File(info?.file?.path ?? '');
        return compressedFile;
      default:
        break;
    }
    return null;
  }
}
