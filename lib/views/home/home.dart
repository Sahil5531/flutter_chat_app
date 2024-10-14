import 'dart:async';
import 'package:demochat/views/chats/create_group/create_group.dart';
import 'package:flutter/material.dart';
import 'package:demochat/libraries/custom_widgets.dart';
import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/views/chats/chat_list.dart';
import 'package:demochat/views/friend_requests/friend_requests.dart';
import 'package:demochat/views/profile/profile.dart';
import 'package:demochat/views/users/users_list.dart';
import 'package:demochat/libraries/custom_classes.dart';
import '../../libraries/stream_controllers.dart';
import '../../socket_manager/socket_manager.dart';
import 'package:badges/badges.dart' as badges;

class HomeVc extends StatefulWidget {
  const HomeVc({super.key});
  static final instance = _HomeVcState();
  @override
  State<HomeVc> createState() => _HomeVcState();
}

class _HomeVcState extends State<HomeVc> with WidgetsBindingObserver {
  late StreamSubscription<bool> subscription;
  int _selectedIndex = 0;
  final screens = [const UsersVc(), const ChatListVc(), const ProfileVc()];
  String screenTitle = 'Home';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getRequestCount();
    subscription = homeStreamController.stream.listen((event) {
      getRequestCount();
    });
    SocketManager.instance.emitWithEvent(Emitter.connectUser,
        params: {'user_id': Singleton.instance.userDataModel?.userId ?? ''});
    changeUserStatus('1');
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    // debugPrint('Dispose home');
    subscription.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint("RESUMED");
        changeUserStatus('1');
        break;
      case AppLifecycleState.inactive:
        debugPrint("INACTIVE");
        break;
      case AppLifecycleState.paused:
        debugPrint("PAUSED");
        changeUserStatus('0');
        break;
      case AppLifecycleState.detached:
        debugPrint("DETACHED");
        changeUserStatus('0');
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  getRequestCount() {
    Singleton.instance.getFriendRequest(null, callBack: (data) {
      setState(() {});
    });
  }

  Future onListen(Listner event, dynamic data) async {
    switch (event) {
      case Listner.newFriendRequest ||
            Listner.acceptedRequest ||
            Listner.rejectedRequest:
        homeStreamController.add(true);
        break;
      default:
    }
  }

  changeUserStatus(String status) {
    final params = {
      'user_id': Singleton.instance.userDataModel?.userId,
      'status': status
    };
    Singleton.instance.changeUserActiveStatus(params);
  }

  @override
  Widget build(BuildContext context) {
    Singleton.instance.context = context;
    return loader(
      Scaffold(
        appBar: AppBar(
          title: Text(screenTitle),
          titleTextStyle: appBarTitleTextStyle(),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: badges.Badge(
                position: badges.BadgePosition.topEnd(top: -12, end: -5),
                showBadge:
                    Singleton.instance.friendRequestCounts > 0 ? true : false,
                onTap: () {},
                badgeContent: Text(
                  '${Singleton.instance.friendRequestCounts}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
                child: Row(
                  children: [
                    Visibility(
                      visible: _selectedIndex == 1,
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (BuildContext context) {
                              return SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.8,
                                child: const CreateGroup(
                                  type: 'create_group',
                                  groupId: '',
                                  groupMembers: [],
                                ),
                              );
                            },
                          ).then(
                            (value) => {
                              setState(() {
                                debugPrint('Popped');
                                ChatListVc.instance.getChatList(context);
                              })
                            },
                          );
                        },
                        child: Image.asset(
                          ImagePath.instance.plus,
                          color: Colors.white,
                          height: 20,
                          width: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const FriendRequestVc()));
                      },
                      child: Image.asset(
                        ImagePath.instance.incomingRequest,
                        color: Colors.white,
                        height: 25,
                        width: 25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(child: screens[_selectedIndex]),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: Colors.white),
          )),
          child: NavigationBar(
            height: 60.0,
            backgroundColor: CustomColor.instance.colorPrimary,
            indicatorColor: Colors.white,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (value) => setState(() {
              _selectedIndex = value;
              switch (value) {
                case 0:
                  screenTitle = 'Home';
                  break;
                case 1:
                  screenTitle = 'Chats';
                  break;
                case 2:
                  screenTitle = 'Profile';
                  break;
                default:
              }
            }),
            destinations: [
              const NavigationDestination(
                  icon: Icon(
                    Icons.home,
                    color: Colors.white,
                  ),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home'),
              const NavigationDestination(
                  icon: Icon(
                    Icons.chat_bubble,
                    color: Colors.white,
                  ),
                  selectedIcon: Icon(Icons.chat_bubble),
                  label: 'Chats'),
              NavigationDestination(
                  icon: Image.asset(
                    ImagePath.instance.userProfileUnSelected,
                    height: 25,
                    width: 25,
                  ),
                  selectedIcon: Image.asset(
                    ImagePath.instance.userProfileSelected,
                    height: 25,
                    width: 25,
                  ),
                  label: 'Profile')
            ],
          ),
        ),
      ),
    );
  }
}
