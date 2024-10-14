import 'package:demochat/views/oto_call/models/otp_calling_models.dart';

import '../../../view_models/user_data_model.dart';

class GroupCallModel {
  late String roomId;
  late List<UserDataModel> users;
  late CallStatus callStatus;

  GroupCallModel({
    required this.roomId,
    required this.users,
    required this.callStatus,
  });
}
