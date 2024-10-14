import 'dart:async';

import 'package:demochat/constants/screen_dimention.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/libraries/stream_controllers.dart';
import 'package:demochat/socket_manager/socket_manager.dart';
import 'package:demochat/view_models/user_data_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../custom_widget.dart/custom_widget.dart';
import 'models/otp_calling_models.dart';

// ignore: must_be_immutable
class OTOCallScreen extends StatefulWidget {
  OTOCallScreen({
    super.key,
    this.userDataModel,
    this.isVideoCall,
    this.isAudioCall,
    this.isMakingCall,
    this.isReceivingCall,
    this.sdp,
  });
  static final instance = _OTOCallScreenState();
  UserDataModel? userDataModel;
  bool? isVideoCall = false;
  bool? isAudioCall = false;
  bool? isMakingCall = false;
  bool? isReceivingCall = false;
  String? sdp;
  @override
  // ignore: library_private_types_in_public_api
  _OTOCallScreenState createState() => _OTOCallScreenState();
}

class _OTOCallScreenState extends State<OTOCallScreen> {
  late StreamSubscription<(Listner, dynamic)> _subscription;
  static RTCPeerConnection? _rtcPeerConnection;
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String _timerCount = '00:00';
  Timer? _callTimer;
  OTOCallingModels? _otoCallingModels;
  CameraMode _cameraMode = CameraMode.front;
  bool isCameraOn = true;
  bool isMicOn = true;
  bool isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    setupDataModel();
    _localRenderer.initialize();
    _remoteRenderer.initialize();
    initializeWebRTC();
    Singleton.instance.isCallStarted = true;
    addSubscription();
  }

  @override
  void dispose() {
    super.dispose();
    _rtcPeerConnection?.close();
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
    _localStream?.dispose();
    _localStream = null;
    _rtcPeerConnection = null;
    _subscription.cancel();
    if (_callTimer != null) {
      _callTimer?.cancel();
    }
    Singleton.instance.isCallStarted = false;
  }

  Future<void> setupDataModel() async {
    _otoCallingModels = OTOCallingModels(
        userDataModel: widget.userDataModel ?? UserDataModel(),
        isVideoCall: widget.isVideoCall,
        isAudioCall: widget.isAudioCall,
        isMakingCall: widget.isMakingCall,
        isReceivingCall: widget.isReceivingCall,
        sdp: widget.sdp,
        callStatus: CallStatus.calling);
  }

  void addSubscription() {
    _subscription = otoCallStreamController.stream.listen((onData) {
      final event = onData.$1;
      final data = onData.$2;
      if (mounted) {
        setState(() {
          switch (event) {
            case Listner.answerOTOVideoCallHandler:
              _otoCallingModels?.sdp = data['sdp'];
              _otoCallingModels?.callStatus = CallStatus.connected;
              startCallTimer();
              handleAnswer(_otoCallingModels?.sdp ?? '');
              break;
            case Listner.answerOTOAudioCallHandler:
              _otoCallingModels?.sdp = data['sdp'];
              handleAnswer(_otoCallingModels?.sdp ?? '');
              break;
            case Listner.receivedOTOCallHandler:
              _otoCallingModels?.callStatus = CallStatus.ringing;
              break;
            case Listner.rejectOTOCallHandler:
              Navigator.pop(context);
              break;
            case Listner.iceCandidateHandler:
              handleNewIceCandidate(data);
              break;
            case Listner.endOTOCallHandler:
              Navigator.pop(context);
              break;
            case Listner.busyCallHandler:
              setState(() {
                _otoCallingModels?.callStatus = CallStatus.busy;
              });
              break;
            default:
          }
        });
      }
    });
  }

  void initializeWebRTC() async {
    _localStream = await navigator.mediaDevices.getUserMedia(
      {
        'audio': true,
        'video': _otoCallingModels?.isAudioCall ?? false
            ? false
            : {
                'mandatory': {
                  'minWidth': '640',
                  'minHeight': '480',
                  'minFrameRate': '30',
                },
                'facingMode': 'user',
                'optional': [],
              },
      },
    );
    _localRenderer.srcObject = _localStream;

    _rtcPeerConnection = await createPeerConnection(
      {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      },
    );

    if (_localStream == null) return;
    final audioTrack = _localStream?.getAudioTracks().first;
    _rtcPeerConnection?.addTrack(audioTrack!, _localStream!);

    if (_otoCallingModels?.isVideoCall ?? false) {
      final videoTrack = _localStream?.getVideoTracks().first;
      _rtcPeerConnection?.addTrack(videoTrack!, _localStream!);
    }

    _rtcPeerConnection?.onIceCandidate = (candidate) {
      final params = {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'sender_id': Singleton.instance.userDataModel?.userId ?? '',
        'receiver_id': _otoCallingModels?.userDataModel?.userId ?? '',
      };
      SocketManager.instance
          .emitWithEvent(Emitter.iceCandidate, params: params);
    };
    _rtcPeerConnection?.onAddStream = (stream) {
      debugPrint('Adding Remote Stream');
      _remoteRenderer.srcObject = stream;
      if (mounted) {
        setState(() {
          Timer.periodic(const Duration(seconds: 2), (timer) {
            audioTrack?.enableSpeakerphone(true);
            isSpeakerOn = true;
            timer.cancel();
          });
        });
      }
    };

    setState(() {});
    if (_otoCallingModels?.isMakingCall ?? false) {
      createOffer();
    }
    if (_otoCallingModels?.isReceivingCall ?? false) {
      Timer.periodic(const Duration(seconds: 1), (timer) {
        receivedCall();
        timer.cancel();
      });
    }
  }

  void cameraSwitch(CameraMode mode) async {
    if (isCameraOn) {
      if (_localStream != null) {
        final videoTrack = _localStream?.getVideoTracks().first;
        if (videoTrack == null) return;
        _localStream?.removeTrack(videoTrack);
        videoTrack.stop();
        final stream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': {
            'mandatory': {
              'minWidth': '640',
              'minHeight': '480',
              'minFrameRate': '30',
            },
            'facingMode': mode == CameraMode.front ? 'user' : 'environment',
            'optional': [],
          },
        });
        final newVideoTrack = stream.getVideoTracks().first;
        _localStream?.addTrack(newVideoTrack);
        _localRenderer.srcObject = _localStream;
        _cameraMode = mode;
        var senders = await _rtcPeerConnection?.getSenders();
        var sender =
            senders?.firstWhere((element) => element.track?.kind == 'video');
        if (sender != null) {
          await sender.replaceTrack(newVideoTrack);
        }
        setState(() {});
      }
    }
  }

  void cameraOnOff() {
    if (_localStream == null) return;
    if (isCameraOn) {
      final videoTrack = _localStream?.getVideoTracks().first;
      if (videoTrack == null) return;
      videoTrack.enabled = false;
      setState(() {
        isCameraOn = false;
      });
    } else {
      final videoTrack = _localStream?.getVideoTracks().first;
      if (videoTrack == null) return;
      videoTrack.enabled = true;
      setState(() {
        isCameraOn = true;
      });
    }
  }

  void micOnOff() {
    final audioTrack = _localStream?.getAudioTracks().first;
    audioTrack?.enabled = !isMicOn;
    setState(() {
      isMicOn = !isMicOn;
    });
  }

  void speakerOnOff() {
    final audioTrack = _localStream?.getAudioTracks().first;
    audioTrack?.enableSpeakerphone(!isSpeakerOn);
    setState(() {
      isSpeakerOn = !isSpeakerOn;
    });
  }

  void receivedCall() {
    final params = {
      'sender_id': Singleton.instance.userDataModel?.userId,
      'receiver_id': _otoCallingModels?.userDataModel?.userId,
    };
    SocketManager.instance
        .emitWithEvent(Emitter.receivedOTOCall, params: params);
  }

  void createOffer() async {
    if (_rtcPeerConnection == null) return;
    RTCSessionDescription description = await _rtcPeerConnection!.createOffer();
    _rtcPeerConnection?.setLocalDescription(description).then((_) {
      final params = {
        'sdp': description.sdp,
        'sender_id': Singleton.instance.userDataModel?.userId ?? '',
        'receiver_id': _otoCallingModels?.userDataModel?.userId ?? '',
        'type': description.type,
      };
      SocketManager.instance.emitWithEvent(
          _otoCallingModels?.isVideoCall ?? false
              ? Emitter.offerOTOVideoCall
              : Emitter.offerOTOAudioCall,
          params: params);
    });
  }

  void handlerOffer(String sdp) async {
    RTCSessionDescription description = RTCSessionDescription(sdp, 'offer');
    await _rtcPeerConnection?.setRemoteDescription(description);
    createAnswer();
  }

  void createAnswer() async {
    if (_rtcPeerConnection == null) return;
    RTCSessionDescription description =
        await _rtcPeerConnection!.createAnswer();
    await _rtcPeerConnection?.setLocalDescription(description).then((_) {
      debugPrint('Answer Created');
      final params = {
        'sdp': description.sdp,
        'sender_id': Singleton.instance.userDataModel?.userId ?? '',
        'receiver_id': _otoCallingModels?.userDataModel?.userId ?? '',
        'type': description.type,
      };
      SocketManager.instance
          .emitWithEvent(Emitter.answerOTOVideoCall, params: params);
      setState(() {
        _otoCallingModels?.callStatus = CallStatus.connected;
        startCallTimer();
      });
    });
  }

  void handleAnswer(String sdp) async {
    if (_rtcPeerConnection != null) {
      debugPrint('Handle Answer');
      RTCSessionDescription description = RTCSessionDescription(sdp, 'answer');
      await _rtcPeerConnection?.setRemoteDescription(description).then((_) {
        debugPrint('Answer Handled');
      });
    } else {
      debugPrint('RTC Peer Connection is Null');
    }
  }

  void handleNewIceCandidate(Map<String, dynamic> candidate) async {
    if (_rtcPeerConnection != null) {
      debugPrint('Adding Candidate');
      RTCIceCandidate iceCandidate = RTCIceCandidate(
        candidate['candidate'],
        candidate['sdpMid'],
        candidate['sdpMLineIndex'],
      );
      try {
        await _rtcPeerConnection?.addCandidate(iceCandidate);
        debugPrint('New Ice Candidate Added');
      } catch (e) {
        debugPrint('Error Adding Candidate: $e');
      }
    } else {
      debugPrint('RTC Peer Connection is Null');
    }
  }

  // Buttons Actions
  void endCall() {
    if (_otoCallingModels?.callStatus != CallStatus.busy) {
      SocketManager.instance.emitWithEvent(Emitter.endOTOCall, params: {
        'sender_id': Singleton.instance.userDataModel?.userId,
        'receiver_id': _otoCallingModels?.userDataModel?.userId ?? '',
      });
    }
    Navigator.pop(context);
  }

  void rejectCall() {
    SocketManager.instance.emitWithEvent(Emitter.rejectOTOCall, params: {
      'sender_id': Singleton.instance.userDataModel?.userId,
      'receiver_id': _otoCallingModels?.userDataModel?.userId ?? '',
    });
    Navigator.pop(context);
  }

  void answerCall(String sdp) {
    debugPrint('Answer Call:');
    handlerOffer(sdp);
  }

  void startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final minutes = int.parse(_timerCount.split(':')[0]);
      final seconds = int.parse(_timerCount.split(':')[1]);
      if (seconds < 59) {
        if (seconds < 9) {
          if (mounted) {
            setState(() {
              _timerCount = '$minutes:0${seconds + 1}';
              FocusScope.of(context).requestFocus();
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _timerCount = '$minutes:${seconds + 1}';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _timerCount = '${minutes + 1}:00';
          });
        }
      }
    });
  }

  Future onListen(Listner event, dynamic data) async {
    switch (event) {
      case Listner.answerOTOVideoCallHandler:
        otoCallStreamController.add((Listner.answerOTOVideoCallHandler, data));
        break;
      case Listner.answerOTOAudioCallHandler:
        otoCallStreamController.add((Listner.answerOTOAudioCallHandler, data));
        break;
      case Listner.rejectOTOCallHandler:
        otoCallStreamController.add((Listner.rejectOTOCallHandler, data));
        break;
      case Listner.endOTOCallHandler:
        otoCallStreamController.add((Listner.endOTOCallHandler, data));
        break;
      case Listner.iceCandidateHandler:
        otoCallStreamController.add((Listner.iceCandidateHandler, data));
        break;
      case Listner.receivedOTOCallHandler:
        otoCallStreamController.add((Listner.receivedOTOCallHandler, data));
        break;
      case Listner.busyCallHandler:
        otoCallStreamController.add((Listner.busyCallHandler, data));
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _otoCallingModels?.callStatus == CallStatus.connected
                      ? Text(
                          _timerCount,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        )
                      : Text(
                          '${_otoCallingModels?.isReceivingCall ?? false ? '${_otoCallingModels?.userDataModel?.fullname ?? ''} is ${_otoCallingModels?.callStatus?.value}' : _otoCallingModels?.callStatus?.value}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                ],
              ),
            ),
            Visibility(
              visible: _otoCallingModels?.isAudioCall ?? false,
              child: Expanded(
                child: Center(
                  child: Stack(
                    children: [
                      Image.asset(
                        ImagePath.instance.userPlaceholder,
                        height: getScreenWidth() / 2,
                        width: getScreenWidth() / 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Visibility(
              visible: _otoCallingModels?.isVideoCall ?? false,
              child: Expanded(
                child: Stack(
                  children: [
                    Container(
                      color: Colors.black,
                      child: RTCVideoView(
                        _remoteRenderer,
                        mirror: true,
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 15,
                      child: Stack(children: [
                        Container(
                          height: getScreenHeight() / 3.5,
                          width: getScreenWidth() / 2.5,
                          color: Colors.black,
                          child: RTCVideoView(
                            _localRenderer,
                            mirror: true,
                          ),
                        ),
                        Positioned(
                          right: 2,
                          top: 20,
                          child: Container(
                            height: 35,
                            width: 35,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(17.5),
                            ),
                            child: IconButton(
                              onPressed: () {
                                cameraSwitch(_cameraMode == CameraMode.front
                                    ? CameraMode.back
                                    : CameraMode.front);
                              },
                              iconSize: 17,
                              icon: const Icon(
                                Icons.switch_camera,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _otoCallingModels?.callStatus == CallStatus.connected
                ? Container(
                    height: 70,
                    width: getScreenWidth() * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (_otoCallingModels?.isVideoCall ?? false)
                          buildCallToolButtons(
                            isCameraOn
                                ? SelectionState.selected
                                : SelectionState.unselected,
                            isCameraOn ? Icons.videocam : Icons.videocam_off,
                            () {
                              cameraOnOff();
                            },
                          ),
                        buildCallToolButtons(
                          isSpeakerOn
                              ? SelectionState.selected
                              : SelectionState.unselected,
                          isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                          () {
                            speakerOnOff();
                          },
                        ),
                        buildCallToolButtons(
                          isMicOn
                              ? SelectionState.selected
                              : SelectionState.unselected,
                          isMicOn ? Icons.mic : Icons.mic_off,
                          () {
                            micOnOff();
                          },
                        ),
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: IconButton(
                            onPressed: () {
                              endCall();
                            },
                            icon: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Visibility(
                        visible:
                            (_otoCallingModels?.isReceivingCall ?? false) &&
                                !(_otoCallingModels?.callStatus ==
                                    CallStatus.connected),
                        child: buildButton(
                          'Answer',
                          Colors.green,
                          Colors.white,
                          () {
                            answerCall(_otoCallingModels?.sdp ?? '');
                          },
                        ),
                      ),
                      SizedBox(
                          width:
                              (_otoCallingModels?.isReceivingCall ?? false) &&
                                      !(_otoCallingModels?.callStatus ==
                                          CallStatus.connected)
                                  ? 15
                                  : 0),
                      Visibility(
                        visible:
                            (_otoCallingModels?.isReceivingCall ?? false) &&
                                !(_otoCallingModels?.callStatus ==
                                    CallStatus.connected),
                        child: buildButton(
                          'Reject',
                          Colors.red,
                          Colors.white,
                          () {
                            rejectCall();
                          },
                        ),
                      ),
                      SizedBox(
                          width:
                              (_otoCallingModels?.isReceivingCall ?? false) &&
                                      !(_otoCallingModels?.callStatus ==
                                          CallStatus.connected)
                                  ? 15
                                  : 0),
                      Visibility(
                        visible: (_otoCallingModels?.isMakingCall ?? false) ||
                            (_otoCallingModels?.callStatus ==
                                CallStatus.connected),
                        child: buildButton(
                          'End',
                          Colors.red,
                          Colors.white,
                          () {
                            endCall();
                          },
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
