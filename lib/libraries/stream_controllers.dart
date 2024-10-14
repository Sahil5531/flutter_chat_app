import 'dart:async';

import 'package:demochat/socket_manager/socket_manager.dart';

StreamController<bool> chatListStreamController =
    StreamController<bool>.broadcast();
StreamController<bool> homeStreamController =
    StreamController<bool>.broadcast();
StreamController<(Listner, dynamic)> chatScreenStreamController =
    StreamController<(Listner, dynamic)>.broadcast();
StreamController<bool> googleMapScreenStreamController =
    StreamController<bool>.broadcast();
StreamController<bool> shareLiveLocationStreamController =
    StreamController<bool>.broadcast();
StreamController<(Listner, dynamic)> otoCallStreamController =
    StreamController<(Listner, dynamic)>.broadcast();
StreamController<(Listner, dynamic)> groupCallStreamController =
    StreamController<(Listner, dynamic)>.broadcast();
