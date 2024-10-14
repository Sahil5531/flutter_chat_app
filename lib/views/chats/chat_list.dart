import 'dart:async';
import 'package:flutter/material.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/view_models/chat_list_model.dart';
import 'package:demochat/views/chats/chat_list_cell.dart';
import 'package:demochat/views/chats/chat_screen/chat_screen.dart';
import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/socket_manager/socket_manager.dart';
import 'package:demochat/web_api/api_call.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../../libraries/stream_controllers.dart';

class ChatListVc extends StatefulWidget {
  const ChatListVc({super.key});
  static var instance = _ChatListState();
  @override
  State<ChatListVc> createState() => _ChatListState();
}

class _ChatListState extends State<ChatListVc> {
  late StreamSubscription<bool> subscription;
  List<ConversationsModel> arrayConversationModel = [];
  int selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    getChatList(context);
    subscription = chatListStreamController.stream.listen((event) {
      refreshList();
    });
  }

  @override
  void dispose() {
    super.dispose();
    subscription.cancel();
  }

  Future refreshList() async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (mounted) {
      hideLoader(context);
      setState(() {
        arrayConversationModel = Singleton.instance.arrayConversationModel;
      });
    }
  }

  void showLoader(BuildContext? context) {
    context?.loaderOverlay.show();
  }

  void hideLoader(BuildContext? context) {
    context?.loaderOverlay.hide();
  }

  Future getChatList(BuildContext? context) async {
    APICall.instance.chatListAPI(context, callBack: (dataModel) {
      Singleton.instance.arrayConversationModel = dataModel;
      chatListStreamController.add(true);
    });
  }

  Future joinChatRoom(
      BuildContext? context, String roomId, String conversationType) async {
    showLoader(context);
    SocketManager.instance.emitWithEvent(Emitter.joinConversation, params: {
      'room_id': roomId,
      'user_id': Singleton.instance.userDataModel?.userId,
      'conversation_type': conversationType
    });
  }

  Future onListen(Listner event, dynamic data) async {
    switch (event) {
      case Listner.connectedToConversation:
        chatListStreamController.add(true);
        Navigator.push(
            Singleton.instance.context,
            MaterialPageRoute(
                builder: (context) => ChatScreenVc(
                      roomId: Singleton.instance.conversationsModel
                                  .conversationType ==
                              'one_to_one'
                          ? Singleton.instance.conversationsModel
                                  .oneToOneConversationId ??
                              ''
                          : Singleton.instance.conversationsModel.groupId ?? '',
                      conversationsModel: Singleton.instance.conversationsModel,
                    ))).then(
          (value) => {
            getChatList(null),
          },
        );
        break;
      case Listner.userEvent:
        // Refresh List Message.
        final model = ConversationsModel().parseJsonData(data);
        final result = Singleton.instance.arrayConversationModel.where(
            (element) =>
                (element.oneToOneConversationId ==
                        model.oneToOneConversationId &&
                    element.conversationType == 'one_to_one') ||
                (element.groupId == model.groupId &&
                    element.conversationType == 'group'));
        debugPrint('updated chat list: $data');
        if (result.isNotEmpty) {
          int index = Singleton.instance.arrayConversationModel.indexWhere(
              (element) =>
                  (element.oneToOneConversationId ==
                          model.oneToOneConversationId &&
                      element.conversationType == 'one_to_one') ||
                  (element.groupId == model.groupId &&
                      element.conversationType == 'group'));
          debugPrint('Item index: $index');
          Singleton.instance.arrayConversationModel
              .replaceRange(index, index + 1, [model]);
        } else {
          Singleton.instance.arrayConversationModel.add(model);
        }
        chatListStreamController.add(true);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    Singleton.instance.context = context;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () {
          return Future(() {
            getChatList(null);
          });
        },
        color: CustomColor.instance.colorPrimary,
        child: Center(
          child: arrayConversationModel.isEmpty
              ? const Text(
                  'No chat found.',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.normal,
                  ),
                )
              : ListView.builder(
                  itemCount: arrayConversationModel.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ChatListCell(
                      onTap: () {
                        Singleton.instance.conversationsModel =
                            Singleton.instance.arrayConversationModel[index];
                        joinChatRoom(
                            context,
                            arrayConversationModel[index].conversationType ==
                                    'one_to_one'
                                ? arrayConversationModel[index]
                                        .oneToOneConversationId ??
                                    ''
                                : arrayConversationModel[index].groupId ?? '',
                            arrayConversationModel[index].conversationType);
                      },
                      model: arrayConversationModel[index],
                    );
                  },
                ),
        ),
      ),
    );
  }
}
