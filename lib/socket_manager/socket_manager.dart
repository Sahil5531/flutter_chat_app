import 'package:demochat/libraries/navigation.dart';
import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/views/chats/chat_list.dart';
import 'package:demochat/views/chats/chat_screen/chat_screen.dart';
import 'package:demochat/views/friend_requests/friend_requests.dart';
import 'package:demochat/views/google_map/google_map.dart';
import 'package:demochat/views/group_call/group_call.dart';
import 'package:demochat/views/home/home.dart';

import 'package:demochat/views/users/user_profile/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:demochat/web_api/urls.dart';

import '../view_models/user_data_model.dart';
import '../views/oto_call/oto_calling.dart';

enum Emitter {
  connectUser,
  reconnectUser,
  createOTOConversation,
  joinConversation,
  leaveConversation,
  rejoinRoom,
  sendChatMessage,
  seenChatMessage,
  sendFriendRequest,
  disconnectUser,
  acceptOrRejectRequest,
  userActiveInactive,
  startTyping,
  stopTyping,
  startFileUpload,
  uploadFileReq,
  sendLocationMessage,
  shareLiveLocation,
  offerOTOVideoCall,
  offerOTOAudioCall,
  answerOTOVideoCall,
  answerOTOAudioCall,
  rejectOTOCall,
  endOTOCall,
  iceCandidate,
  receivedOTOCall,
  busyCall,
  noAnswerCall,
  joinGroupcall,
  createGroupOffer,
  createGroupAnswer,
  leftGroupCall,
  iceCandidateGroup,
}

enum Listner {
  userConnected,
  userEvent,
  createAndConnectedOTOConversation,
  connectedToConversation,
  conversationLeft,
  newChatMessage,
  newFriendRequest,
  userDisconnected,
  acceptedRequest,
  rejectedRequest,
  changedActiveInactive,
  isTyping,
  uploadingDataReq,
  uploadComplete,
  messageSeen,
  receiveLocationMessage,
  receiveLiveLocation,
  offerOTOVideoCallHandler,
  offerOTOAudioCallHandler,
  answerOTOVideoCallHandler,
  answerOTOAudioCallHandler,
  rejectOTOCallHandler,
  endOTOCallHandler,
  iceCandidateHandler,
  receivedOTOCallHandler,
  busyCallHandler,
  noAnswerCallHandler,
  offerGroupCallHandler,
  joinGroupCallHandler,
  handleGroupOffer,
  handleGroupAnswer,
  leftGroupCallHandler,
  iceCandidateGroupHandler,
}

class SocketManager {
  static final instance = SocketManager();

  late io.Socket socket;
  List<Listner> arrayListners = [
    Listner.userConnected,
    Listner.userEvent,
    Listner.createAndConnectedOTOConversation,
    Listner.connectedToConversation,
    Listner.conversationLeft,
    Listner.newChatMessage,
    Listner.newFriendRequest,
    Listner.userDisconnected,
    Listner.acceptedRequest,
    Listner.rejectedRequest,
    Listner.changedActiveInactive,
    Listner.isTyping,
    Listner.uploadComplete,
    Listner.uploadingDataReq,
    Listner.messageSeen,
    Listner.receiveLocationMessage,
    Listner.receiveLiveLocation,
    Listner.offerOTOVideoCallHandler,
    Listner.offerOTOAudioCallHandler,
    Listner.answerOTOVideoCallHandler,
    Listner.answerOTOAudioCallHandler,
    Listner.rejectOTOCallHandler,
    Listner.endOTOCallHandler,
    Listner.iceCandidateHandler
  ];

  initializeSocket() {
    socket = io.io(Urls.instance.socketUrl, <String, dynamic>{
      'forceNew': true,
      'transports': ['websocket']
    });
    socket.connect();
    socket.onConnect((data) {
      debugPrint('Socket Connected');
      if (Singleton.instance.userDataModel != null) {
        emitWithEvent(Emitter.connectUser,
            params: {'user_id': Singleton.instance.userDataModel!.userId});
      }
      if (Singleton.instance.currentRoomId != null) {
        emitWithEvent(Emitter.rejoinRoom,
            params: {'room_id': Singleton.instance.currentRoomId});
      }
      callListners();
    });
    socket.onDisconnect((data) {
      debugPrint('Socket Disconnected');
      for (var element in arrayListners) {
        socket.off(element.name);
      }
    });
  }

  disconnectSocket() async {
    socket.clearListeners();
    socket.disconnect();
    socket.close();
    socket.destroy();
  }

  callListners() {
    socket.on(Listner.userConnected.name, (data) {
      debugPrint('userConnected');
    });
    socket.on(Listner.userEvent.name, (data) {
      debugPrint('userEvent');
      ChatListVc.instance.onListen(Listner.userEvent, data);
    });
    socket.on(Listner.createAndConnectedOTOConversation.name, (data) {
      if (data['user_id'] == Singleton.instance.userDataModel?.userId) {
        debugPrint('createAndConnectedOTOConversation');
        UserProfileVc.instance
            .onListen(Listner.createAndConnectedOTOConversation, data);
      }
    });
    socket.on(Listner.connectedToConversation.name, (data) {
      if (data['user_id'] == Singleton.instance.userDataModel?.userId) {
        debugPrint('connectedToConversation');
        ChatListVc.instance.onListen(Listner.connectedToConversation, data);
      }
    });
    socket.on(Listner.conversationLeft.name, (data) {
      debugPrint('conversationLeft');
      ChatScreenVc.instance.onListen(Listner.conversationLeft, data);
    });
    socket.on(Listner.newChatMessage.name, (data) {
      debugPrint('newChatMessage');
      ChatScreenVc.instance.onListen(Listner.newChatMessage, data);
    });
    socket.on(Listner.messageSeen.name, (data) {
      debugPrint('messageSeen');
      ChatScreenVc.instance.onListen(Listner.messageSeen, data);
    });
    socket.on(Listner.newFriendRequest.name, (data) {
      debugPrint('newFriendRequest');
      UserProfileVc.instance.onListen(Listner.newFriendRequest, data);
      HomeVc.instance.onListen(Listner.newFriendRequest, data);
    });
    socket.on(Listner.acceptedRequest.name, (data) {
      debugPrint('acceptedRequest: $data');
      UserProfileVc.instance.onListen(Listner.acceptedRequest, data);
      FriendRequestVc.instance.onListen(Listner.acceptedRequest, data);
      HomeVc.instance.onListen(Listner.acceptedRequest, data);
    });
    socket.on(Listner.rejectedRequest.name, (data) {
      debugPrint('rejectedRequest: $data');
      UserProfileVc.instance.onListen(Listner.rejectedRequest, data);
      FriendRequestVc.instance.onListen(Listner.rejectedRequest, data);
      HomeVc.instance.onListen(Listner.rejectedRequest, data);
    });
    socket.on(Listner.changedActiveInactive.name, (data) {
      if (data['user_id'] != Singleton.instance.userDataModel?.userId) {
        ChatScreenVc.instance.onListen(Listner.changedActiveInactive, data);
      }
    });
    socket.on(Listner.isTyping.name, (data) {
      debugPrint(data['sender_id']);
      if (data['sender_id'] != Singleton.instance.userDataModel?.userId) {
        ChatScreenVc.instance.onListen(Listner.isTyping, data);
      }
    });
    socket.on(Listner.uploadingDataReq.name, (data) {
      debugPrint('uploadingDataReq $data');
      if (data['sender_id'] == Singleton.instance.userDataModel?.userId) {
        ChatScreenVc.instance.onListen(Listner.uploadingDataReq, data);
      }
    });
    socket.on(Listner.uploadComplete.name, (data) {
      debugPrint('uploadComplete $data');
      ChatScreenVc.instance.onListen(Listner.uploadComplete, data);
    });
    socket.on(Listner.receiveLocationMessage.name, (data) {
      debugPrint('receiveLocationMessage $data');
      ChatScreenVc.instance.onListen(Listner.receiveLocationMessage, data);
    });
    socket.on(Listner.receiveLiveLocation.name, (data) {
      debugPrint('receiveLiveLocation');
      MapScreen.instance.onListen(Listner.receiveLiveLocation, data);
    });
    socket.on(Listner.offerOTOVideoCallHandler.name, (data) {
      debugPrint(
          'offerOTOVideoCallHandler ${Singleton.instance.isCallStarted}');
      if (!Singleton.instance.isCallStarted) {
        if (data['receiver_id'] == Singleton.instance.userDataModel?.userId) {
          final model = UserDataModel().parseJsonData(data['sender_data']);
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => OTOCallScreen(
                userDataModel: model,
                isVideoCall: true,
                isMakingCall: false,
                isReceivingCall: true,
                sdp: data['sdp'],
              ),
              fullscreenDialog: true,
            ),
          );
        }
      } else {
        emitWithEvent(Emitter.busyCall, params: {
          'sender_id': Singleton.instance.userDataModel?.userId,
          'receiver_id': data['sender_id']
        });
      }
    });
    socket.on(Listner.offerOTOAudioCallHandler.name, (data) {
      debugPrint('offerOTOAudioCallHandler');
      if (!Singleton.instance.isCallStarted) {
        if (data['receiver_id'] == Singleton.instance.userDataModel?.userId) {
          final model = UserDataModel().parseJsonData(data['sender_data']);
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => OTOCallScreen(
                userDataModel: model,
                isAudioCall: true,
                isMakingCall: false,
                isReceivingCall: true,
                sdp: data['sdp'],
              ),
              fullscreenDialog: true,
            ),
          );
        }
      } else {
        emitWithEvent(Emitter.busyCall, params: {
          'sender_id': Singleton.instance.userDataModel?.userId,
          'receiver_id': data['sender_id']
        });
      }
    });
    socket.on(Listner.answerOTOVideoCallHandler.name, (data) {
      debugPrint('answerOTOVideoCallHandler');
      if (Singleton.instance.isCallStarted) {
        OTOCallScreen.instance
            .onListen(Listner.answerOTOVideoCallHandler, data);
      }
    });
    socket.on(Listner.answerOTOAudioCallHandler.name, (data) {
      debugPrint('answerOTOAudioCallHandler');
      if (Singleton.instance.isCallStarted) {
        OTOCallScreen.instance
            .onListen(Listner.answerOTOAudioCallHandler, data);
      }
    });
    socket.on(Listner.rejectOTOCallHandler.name, (data) {
      debugPrint('rejectOTOCallHandler');
      OTOCallScreen.instance.onListen(Listner.rejectOTOCallHandler, data);
    });
    socket.on(Listner.endOTOCallHandler.name, (data) {
      debugPrint('endOTOCallHandler');
      OTOCallScreen.instance.onListen(Listner.endOTOCallHandler, data);
    });
    socket.on(Listner.iceCandidateHandler.name, (data) {
      debugPrint('iceCandidateHandler');
      if (Singleton.instance.isCallStarted) {
        OTOCallScreen.instance.onListen(Listner.iceCandidateHandler, data);
      }
    });
    socket.on(Listner.receivedOTOCallHandler.name, (data) {
      debugPrint('receivedOTOCallHandler $data');
      OTOCallScreen.instance.onListen(Listner.receivedOTOCallHandler, data);
    });
    socket.on(Listner.busyCallHandler.name, (data) {
      debugPrint('busyCallHandler');
      if (Singleton.instance.isCallStarted) {
        if (data['receiver_id'] == Singleton.instance.userDataModel?.userId) {
          OTOCallScreen.instance.onListen(Listner.busyCallHandler, data);
        }
      }
    });
    socket.on(Listner.offerGroupCallHandler.name, (data) {
      debugPrint('offerGroupCallHandler ${Singleton.instance.isCallStarted}');
      if (!Singleton.instance.isCallStarted) {
        if (data['user_id'] != Singleton.instance.userDataModel?.userId) {
          debugPrint('Hello------');
          final model = UserDataModel().parseJsonData(data['user_data']);
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => GroupCall(
                roomId: data['room_id'],
                isOfferingCall: false,
                isReceivingCall: true,
                callerUserDataModel: model,
              ),
            ),
          );
        }
      }
    });
    socket.on(Listner.joinGroupCallHandler.name, (data) {
      debugPrint('joinGroupCallHandler');
      GroupCall.instance.onListen(Listner.joinGroupCallHandler, data);
    });
    socket.on(Listner.handleGroupOffer.name, (data) {
      debugPrint('handleGroupOffer');
      if (Singleton.instance.isCallStarted) {
        GroupCall.instance.onListen(Listner.handleGroupOffer, data);
      }
    });
    socket.on(Listner.handleGroupAnswer.name, (data) {
      debugPrint('handleGroupAnswer');
      if (Singleton.instance.isCallStarted) {
        GroupCall.instance.onListen(Listner.handleGroupAnswer, data);
      }
    });
    socket.on(Listner.leftGroupCallHandler.name, (data) {
      debugPrint('leftGroupCallHandler');
      if (Singleton.instance.isCallStarted) {
        GroupCall.instance.onListen(Listner.leftGroupCallHandler, data);
      }
    });
    socket.on(Listner.iceCandidateGroupHandler.name, (data) {
      if (Singleton.instance.isCallStarted) {
        GroupCall.instance.onListen(Listner.iceCandidateGroupHandler, data);
      }
    });
  }

  emitWithEvent(Emitter event, {required dynamic params}) {
    debugPrint('Event: $event');
    socket.emit(event.name, [params]);
  }
}
