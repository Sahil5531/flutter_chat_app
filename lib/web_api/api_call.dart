import 'package:demochat/view_models/chat_list_model.dart';
import 'package:demochat/view_models/chat_messages_model.dart';
import 'package:demochat/view_models/user_data_model.dart';
import 'package:demochat/local_storage/local_storage_manager.dart';
import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/web_api/api_request.dart';
import 'package:flutter/material.dart';

class APICall {
  static final instance = APICall();

  sendOtpAPI(BuildContext? context, String number,
      {required Function callBack}) {
    final Map<String, dynamic> params = {'phone_number': number, 'uuid': ''};
    APIRequest.instance.sendPostRequest(context, 'send_otp', params,
        successBlock: (jsonData) {
      if (jsonData['status'] as bool) {
        callBack(jsonData['data']);
      } else {
        callBack(false);
      }
    });
  }

  verifyOtpAPI(BuildContext? context,
      {required String number,
      required String otp,
      required Function callBack}) {
    final Map<String, dynamic> params = {
      'phone_number': number,
      'otp': otp,
      'uuid': ''
    };
    APIRequest.instance.sendPostRequest(context, 'verify_otp', params,
        successBlock: (jsonData) {
      if (jsonData['status'] as bool) {
        SharedPrefManager.instance.setData(StorageKey.isLogin, true);
        SharedPrefManager.instance
            .setData(StorageKey.userData, jsonData['data']);
        SharedPrefManager.instance.setData(
            StorageKey.authenticationToken, jsonData['authenticationToken']);
        Singleton.instance.userDataModel =
            UserDataModel().parseJsonData(jsonData['data']);
        debugPrint('User data: ${jsonData['data']}');
        Singleton.instance.authenticationToken =
            jsonData['authenticationToken'];
        callBack(true);
      } else {
        callBack(false);
      }
    });
  }

  addFriendAPI(BuildContext? context, String receiverId,
      {required Function callBack}) {
    final params = {
      'sender_id': Singleton.instance.userDataModel?.userId,
      'receiver_id': receiverId
    };
    APIRequest.instance.sendPostRequest(context, 'send_friend_request', params,
        successBlock: (jsonData) {
      if (jsonData['status'] as bool) {}
    });
  }

  usersListAPI(BuildContext? context, {required Function callBack}) {
    final userId = Singleton.instance.userDataModel?.userId ?? '';
    final Map<String, dynamic> params = {'user_id': userId};

    APIRequest.instance.sendPostRequest(context, 'get_all_users', params,
        successBlock: (jsonData) {
      if (jsonData['status'] as bool) {
        List<UserDataModel> models =
            UserDataModel().parseJsonArray(jsonData['data']);
        callBack(models);
      }
    });
  }

  chatListAPI(BuildContext? context, {required Function callBack}) {
    final userId = Singleton.instance.userDataModel?.userId ?? '';
    APIRequest.instance.sendGetRequest(
        context, 'get_chat_list', {'user_id': Uri.encodeComponent(userId)},
        successBlock: (jsonData) {
      if (jsonData['status'] as bool) {
        List<ConversationsModel> modelsChatList =
            ConversationsModel().parseJsonArray(jsonData['data']);
        modelsChatList = modelsChatList
            .where((element) =>
                (element.lastMessageId != '' &&
                    element.conversationType == 'one_to_one') ||
                (element.conversationType == 'group'))
            .toList();
        callBack(modelsChatList);
      }
    });
  }

  chatMessageListAPI(
      BuildContext? context, String roomId, String conversationType,
      {required Function callBack}) {
    APIRequest.instance.sendGetRequest(context, 'get_chat_messages', {
      'room_id': Uri.encodeComponent(roomId),
      'conversation_type': conversationType
    }, successBlock: (jsonData) {
      // debugPrint('Chat Messages: $jsonData');
      if (jsonData['status'] as bool) {
        List<ChatMessagesModel> models =
            ChatMessagesModel().parseJsonArray(jsonData['data']);
        callBack(models);
      }
    });
  }

  editProfileAPI(BuildContext? context, String? fileName, String? fileParam,
      String? fileType, String? filePath,
      {required Map<String, dynamic> params, required Function callBack}) {
    APIRequest.instance.sendMultipleFormDataRequest(
        context,
        'edit_profile',
        params,
        fileName,
        fileParam,
        fileType,
        filePath, successBlock: (jsonData) {
      if (jsonData['status'] as bool) {
        Singleton.instance.userDataModel =
            UserDataModel().parseJsonData(jsonData['data']);
        SharedPrefManager.instance
            .setData(StorageKey.userData, jsonData['data']);
        callBack(true);
      }
    });
  }

  getFriendRequestsAPI(BuildContext? context, {required Function callBack}) {
    final userId = Singleton.instance.userDataModel?.userId ?? '';
    APIRequest.instance.sendGetRequest(
        context, 'get_friend_request', {'user_id': Uri.encodeComponent(userId)},
        successBlock: (jsonData) {
      if (jsonData['status'] as bool) {
        final array = UserDataModel().parseJsonArray(jsonData['data']);
        callBack(array);
      }
    });
  }

  checkFriendStatusAPI(BuildContext? context,
      {required String friendId, required Function callBack}) {
    final params = {
      'user_id': Singleton.instance.userDataModel?.userId ?? '',
      'friend_id': friendId
    };
    APIRequest.instance.sendPostRequest(context, 'check_friend_status', params,
        successBlock: (jsonData) {
      if (jsonData['status'] as bool) {
        final data = jsonData['data'];
        callBack(data);
      } else {
        callBack('no_request');
      }
    });
  }

  getUserData(BuildContext? context, String userId,
      {required Function(UserDataModel) callBack}) {
    APIRequest.instance.sendGetRequest(
        context, 'get_user_data', {'user_id': Uri.encodeComponent(userId)},
        successBlock: (jsonData) {
      if (jsonData['status'] as bool) {
        final data = UserDataModel().parseJsonData(jsonData['result']);
        callBack(data);
      }
    });
  }

  createGroup(BuildContext? context, String groupName, List<String> userIds,
      {required Function callBack}) {
    final userIdsString = userIds.join(',');
    final params = {
      'user_id': Singleton.instance.userDataModel?.userId ?? '',
      'group_name': groupName,
      'users_list': userIdsString,
      'group_image': ''
    };
    APIRequest.instance.sendMultipleFormDataRequest(
        context, 'create_group', params, '', '', '', '',
        successBlock: (jsonData) {
      if (jsonData['status'] as bool) {
        callBack(true);
      } else {
        callBack(false);
      }
    });
  }

  addMembersToGroup(BuildContext? context, String groupId, List<String> userIds,
      {required Function callBack}) {
    final userIdsString = userIds.join(',');
    final Map<String, dynamic> params = {
      'group_id': groupId,
      'users_list': userIdsString,
      'added_by_user_id': Singleton.instance.userDataModel?.userId
    };
    APIRequest.instance.sendPostRequest(context, 'add_group_members', params,
        successBlock: (jsonData) {
      if (jsonData['status'] as bool) {
        callBack(true);
      } else {
        callBack(false);
      }
    });
  }

  leaveGroup(BuildContext? context, String groupId,
      {required Function callBack}) {
    final params = {
      'group_id': groupId,
      'user_id': Singleton.instance.userDataModel?.userId
    };
    APIRequest.instance.sendPostRequest(context, 'leave_group', params,
        successBlock: (jsonData) {
      if (jsonData['status'] as bool) {
        callBack(true);
      } else {
        callBack(false);
      }
    });
  }

  getGroupUsers(BuildContext? context, String groupId,
      {required Function callBack}) {
    final params = {'group_id': groupId};
    APIRequest.instance.sendGetRequest(context, 'get_group_users', params,
        successBlock: (jsonData) {
      if (jsonData['status'] as bool) {
        final array = UserDataModel().parseJsonArray(jsonData['data']);
        callBack(array);
      }
    });
  }
}
