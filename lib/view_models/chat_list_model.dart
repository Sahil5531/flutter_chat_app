import 'package:demochat/view_models/chat_messages_model.dart';
import 'package:demochat/view_models/user_data_model.dart';

class ChatListModel {
  late String roomId;
  late String senderId;
  late String receiverId;
  late String lastMsgId;
  late String lastMessage;
  late String messageType;
  late UserDataModel usersData;
  late String createdAt;
  var unreadMsgCount = 0;

  List<ChatListModel> parseJsonArray(List<dynamic> data) {
    List<ChatListModel> array = [];
    for (var element in data) {
      ChatListModel model = ChatListModel();
      model.roomId = element['room_id'] ?? '';
      model.senderId = element['sender_id'] ?? '';
      model.receiverId = element['receiver_id'] ?? '';
      model.lastMsgId = element['last_message_id'] ?? '';
      model.lastMessage = element['last_message'] ?? '';
      model.messageType = element['message_type'] ?? '';
      model.unreadMsgCount = element['unread_message_count'] ?? 0;
      model.usersData = UserDataModel().parseJsonData(element['userData']);
      model.createdAt = element['created_at'] ?? '';
      array.add(model);
    }
    return array;
  }

  ChatListModel parseJsonData(dynamic json) {
    ChatListModel model = ChatListModel();
    model.roomId = json['room_id'] ?? '';
    model.senderId = json['sender_id'] ?? '';
    model.receiverId = json['receiver_id'] ?? '';
    model.lastMsgId = json['last_message_id'] ?? '';
    model.lastMessage = json['last_message'] ?? '';
    model.messageType = json['message_type'] ?? '';
    model.unreadMsgCount = json['unread_message_count'] ?? 0;
    model.usersData = UserDataModel().parseJsonData(json['userData']);
    model.createdAt = json['created_at'] ?? '';
    return model;
  }
}

class ConversationsModel {
  late int id;
  late String conversationId;
  late String conversationType;
  late String? oneToOneConversationId;
  late String? groupId;
  late String createdAt;
  late String? groupName;
  late String? groupImageUrl;
  late String? createdUserId;
  late String? secondUserId;
  late String? lastMessageId;
  late String? lastMessage;
  late ChatMessageType? messageType;
  var unreadMsgCount = 0;
  late UserDataModel? userData;

  List<ConversationsModel> parseJsonArray(List<dynamic> data) {
    List<ConversationsModel> array = [];
    for (var element in data) {
      ConversationsModel model = ConversationsModel();
      model.id = element['id'] ?? 0;
      model.conversationId = element['conversation_id'] ?? '';
      model.conversationType = element['conversation_type'] ?? '';
      model.oneToOneConversationId =
          element['one_to_one_conversation_id'] ?? '';
      model.groupId = element['group_id'] ?? '';
      model.createdAt = element['created_at'] ?? '';
      model.groupName = element['group_name'] ?? '';
      model.groupImageUrl = element['group_image_url'] ?? '';
      model.createdUserId = element['created_user_id'] ?? '';
      model.secondUserId = element['second_user_id'] ?? '';
      model.lastMessageId = element['last_message_id'] ?? '';
      model.lastMessage = element['last_message'] ?? '';
      // model.messageType = element['message_type'] ?? '';
      model.unreadMsgCount = element['unread_message_count'] ?? 0;
      if (element['userData'] != null) {
        model.userData = UserDataModel().parseJsonData(element['userData']);
      } else {
        model.userData = null;
      }
      switch (element['message_type']) {
        case 'text':
          model.messageType = ChatMessageType.text;
          break;
        case 'image':
          model.messageType = ChatMessageType.image;
          break;
        case 'audio':
          model.messageType = ChatMessageType.audio;
          break;
        case 'video':
          model.messageType = ChatMessageType.video;
          break;
        case 'file':
          model.messageType = ChatMessageType.file;
          break;
        case 'location':
          model.messageType = ChatMessageType.location;
          break;
        default:
          model.messageType = ChatMessageType.text;
          break;
      }

      array.add(model);
    }
    return array;
  }

  ConversationsModel parseJsonData(dynamic json) {
    ConversationsModel model = ConversationsModel();
    model.id = json['id'] ?? 0;
    model.conversationId = json['conversation_id'] ?? '';
    model.conversationType = json['conversation_type'] ?? '';
    model.oneToOneConversationId = json['one_to_one_conversation_id'] ?? '';
    model.groupId = json['group_id'] ?? '';
    model.createdAt = json['created_at'] ?? '';
    model.groupName = json['group_name'] ?? '';
    model.groupImageUrl = json['group_image_url'] ?? '';
    model.createdUserId = json['created_user_id'] ?? '';
    model.secondUserId = json['second_user_id'] ?? '';
    model.lastMessageId = json['last_message_id'] ?? '';
    model.lastMessage = json['last_message'] ?? '';
    // model.messageType = json['message_type'] ?? '';
    model.unreadMsgCount = json['unread_message_count'] ?? 0;
    if (json['userData'] != null) {
      model.userData = UserDataModel().parseJsonData(json['userData']);
    } else {
      model.userData = null;
    }
    switch (json['message_type']) {
      case 'text':
        model.messageType = ChatMessageType.text;
        break;
      case 'image':
        model.messageType = ChatMessageType.image;
        break;
      case 'audio':
        model.messageType = ChatMessageType.audio;
        break;
      case 'video':
        model.messageType = ChatMessageType.video;
        break;
      case 'file':
        model.messageType = ChatMessageType.file;
        break;
      case 'location':
        model.messageType = ChatMessageType.location;
        break;
      default:
        model.messageType = ChatMessageType.text;
        break;
    }
    return model;
  }
}
