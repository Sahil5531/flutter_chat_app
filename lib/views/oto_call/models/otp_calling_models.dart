import 'package:demochat/view_models/user_data_model.dart';

class OTOCallingModels {
  // static final instance = OTOCallingModels();

  UserDataModel? userDataModel;
  bool? isVideoCall = false;
  bool? isAudioCall = false;
  bool? isMakingCall = false;
  bool? isReceivingCall = false;
  String? sdp;
  CallStatus? callStatus = CallStatus.calling;

  OTOCallingModels({
    this.userDataModel,
    this.isVideoCall,
    this.isAudioCall,
    this.isMakingCall,
    this.isReceivingCall,
    this.sdp,
    this.callStatus,
  });
}

enum CallStatus {
  calling,
  incomingCall,
  ringing,
  connected,
  disscconnected,
  busy,
  noAnswer,
  rejected,
  cancelled,
}

extension CallStatusExtension on CallStatus {
  String get value {
    switch (this) {
      case CallStatus.calling:
        return 'Calling...';
      case CallStatus.ringing:
        return 'Ringing...';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.disscconnected:
        return 'Disscconnected';
      case CallStatus.busy:
        return 'Busy...';
      case CallStatus.noAnswer:
        return 'No Answer...';
      case CallStatus.rejected:
        return 'Rejected';
      case CallStatus.cancelled:
        return 'Cancelled';
      case CallStatus.incomingCall:
        return 'Incoming Call...';
    }
  }
}
