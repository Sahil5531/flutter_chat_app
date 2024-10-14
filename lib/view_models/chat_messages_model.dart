class ChatMessagesModel {
  late String groupId;
  late String otoConversationId;
  late String messageId;
  late String message;
  late String filePath;
  late String senderId;
  late String receiverId;
  late int seen;
  late int sent;
  late ChatMessageType messageType;
  late String createdAt;
  late String fileId;
  late String? locationId;

  List<ChatMessagesModel> parseJsonArray(List<dynamic> data) {
    List<ChatMessagesModel> array = [];
    for (var json in data) {
      ChatMessagesModel model = ChatMessagesModel();
      model.groupId = json['group_id'] ?? '';
      model.otoConversationId = json['one_to_one_conversation_id'] ?? '';
      model.messageId = json['message_id'] ?? '';
      model.message = json['message'] ?? '';
      model.filePath = json['file_path'] ?? '';
      model.senderId = json['sender_id'] ?? '';
      model.receiverId = json['receiver_id'] ?? '';
      model.seen = json['seen'] ?? 0;
      model.sent = json['sent'] ?? 0;
      model.createdAt = json['created_at'] ?? '';
      model.fileId = json['file_id'] ?? '';
      model.locationId = json['location_id'] ?? '';
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
        case 'liveLocation':
          model.messageType = ChatMessageType.liveLocation;
          break;
        default:
          model.messageType = ChatMessageType.text;
          break;
      }
      array.add(model);
    }
    return array;
  }

  ChatMessagesModel parseJsonData(dynamic json) {
    ChatMessagesModel model = ChatMessagesModel();
    model.groupId = json['group_id'] ?? '';
    model.otoConversationId = json['one_to_one_conversation_id'] ?? '';
    model.messageId = json['message_id'] ?? '';
    model.message = json['message'] ?? '';
    model.filePath = json['file_path'] ?? '';
    model.senderId = json['sender_id'] ?? '';
    model.receiverId = json['receiver_id'] ?? '';
    model.seen = json['seen'] ?? 0;
    model.sent = json['sent'] ?? 0;
    model.createdAt = json['created_at'] ?? '';
    model.fileId = json['file_id'] ?? '';
    model.locationId = json['location_id'] ?? '';
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
      case 'liveLocation':
        model.messageType = ChatMessageType.liveLocation;
        break;
      default:
        model.messageType = ChatMessageType.text;
        break;
    }
    return model;
  }
}

enum ChatMessageType { text, image, audio, video, file, location, liveLocation }
