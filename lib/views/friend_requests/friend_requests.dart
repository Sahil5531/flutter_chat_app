import 'dart:async';

import 'package:flutter/material.dart';
import 'package:demochat/libraries/custom_widgets.dart';
import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/socket_manager/socket_manager.dart';
import 'package:demochat/view_models/user_data_model.dart';
import 'package:demochat/views/friend_requests/friend_request_cell.dart';

StreamController<bool> streamController = StreamController<bool>.broadcast();

class FriendRequestVc extends StatefulWidget {
  const FriendRequestVc({super.key});
  static final instance = _FriendRequestState();
  @override
  State<FriendRequestVc> createState() => _FriendRequestState();
}

class _FriendRequestState extends State<FriendRequestVc> {
  late StreamSubscription<bool> subscription;
  List<UserDataModel> requestsList = [];
  int count = 0;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 10), () {
      getFriendRequests();
    });
    subscription = streamController.stream.listen((event) {
      getFriendRequests();
    });
  }

  @override
  void dispose() {
    super.dispose();
    subscription.cancel();
  }

  getFriendRequests() {
    Singleton.instance.getFriendRequest(context, callBack: (data) {
      requestsList = data;
      setState(() {});
    });
  }

  Future onListen(Listner event, dynamic data) async {
    if (event == Listner.acceptedRequest || event == Listner.rejectedRequest) {
      streamController.add(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return loader(
      Scaffold(
        appBar: appBar('Friend Requests'),
        body: SafeArea(
          maintainBottomViewPadding: true,
          child: Center(
            child: ListView.builder(
                itemCount: requestsList.length,
                itemBuilder: (context, index) {
                  return FriendRequestCell(
                      model: requestsList[index], index: index);
                }),
          ),
        ),
      ),
    );
  }
}
