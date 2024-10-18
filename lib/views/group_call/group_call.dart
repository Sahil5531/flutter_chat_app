import 'dart:async';

import 'package:demochat/constants/screen_dimention.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/libraries/stream_controllers.dart';
import 'package:demochat/views/group_call/model/group_call_model.dart';
import 'package:flutter/material.dart';
import '../../components/custom_button.dart';
import '../../custom_widget.dart/custom_widget.dart';
import '../../socket_manager/socket_manager.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../view_models/user_data_model.dart';
import '../oto_call/models/otp_calling_models.dart';

// ignore: must_be_immutable
class GroupCall extends StatefulWidget {
  GroupCall({
    super.key,
    required this.roomId,
    required this.isOfferingCall,
    this.isReceivingCall,
    this.users,
    this.callerUserDataModel,
  });
  String roomId;
  bool isOfferingCall;
  bool? isReceivingCall = false;
  List<UserDataModel>? users = [];
  UserDataModel? callerUserDataModel;
  static final instance = _GroupCallState();
  @override
  // ignore: library_private_types_in_public_api
  _GroupCallState createState() => _GroupCallState();
}

class _GroupCallState extends State<GroupCall> {
  late StreamSubscription<(Listner, dynamic)> _subscription;
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  late final List<Map<String, dynamic>> _videoViews = [];
  MediaStream? _localStream;
  late GroupCallModel _groupCallModel;
  CameraMode _cameraMode = CameraMode.front;
  bool isCameraOn = true;
  bool isMicOn = true;
  bool isSpeakerOn = true;

  @override
  void initState() {
    super.initState();
    _groupCallModel = GroupCallModel(
        roomId: widget.roomId,
        users: widget.users ?? [],
        callStatus: widget.isOfferingCall
            ? CallStatus.calling
            : widget.isReceivingCall ?? false
                ? CallStatus.incomingCall
                : CallStatus.ringing);
    _addSubscription();
    _addLocalStream();
    if (widget.isOfferingCall) {
      joinGroupCall();
    }
    Singleton.instance.isCallStarted = true;
  }

  @override
  void dispose() {
    super.dispose();
    _localStream!.dispose();
    _localRenderer.dispose();
    _subscription.cancel();
    Singleton.instance.isCallStarted = false;
  }

  void _addSubscription() {
    _subscription = groupCallStreamController.stream.listen((onData) {
      final event = onData.$1;
      final data = onData.$2;
      final sdp = data['sdp'];

      switch (event) {
        case Listner.joinGroupCallHandler:
          final userId = data['user_id'];
          if (Singleton.instance.userDataModel?.userId != userId) {
            _createPeerConnection(userId).then((_) {
              _createOffer(userId);
            });
          }
          _groupCallModel.callStatus = CallStatus.connected;
          setState(() {});
          break;
        case Listner.handleGroupOffer:
          _handleOffer(sdp, data['sender_id']);
          break;
        case Listner.handleGroupAnswer:
          _handleAnswer(sdp, data['sender_id']);
          break;
        case Listner.iceCandidateGroupHandler:
          _handleIceCandidate(data, data['sender_id']);
          break;
        case Listner.leftGroupCallHandler:
          final userId = data['user_id'];
          if (userId != Singleton.instance.userDataModel?.userId) {
            _handleLeftGroup(userId);
          }
          break;
        default:
      }
    });
  }

  Future<void> joinGroupCall() async {
    final params = {
      'room_id': _groupCallModel.roomId,
      'user_id': Singleton.instance.userDataModel?.userId,
      'isOfferingCall': widget.isOfferingCall,
      'userIds': _groupCallModel.users.map((e) => e.userId).toList(),
    };
    SocketManager.instance.emitWithEvent(Emitter.joinGroupcall, params: params);
  }

  void _addLocalStream() async {
    await _localRenderer.initialize();
    _localStream = await navigator.mediaDevices.getUserMedia(
      {
        'audio': true,
        'video': {
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
    final audioTrack = _localStream!.getAudioTracks().first;
    Timer(const Duration(seconds: 3), () {
      setState(() {
        audioTrack.enableSpeakerphone(true);
        isSpeakerOn = true;
      });
    });
    setState(() {
      _localRenderer.srcObject = _localStream;
      final data = {
        'id': Singleton.instance.userDataModel?.userId,
        'widget': RTCVideoView(_localRenderer,
            mirror: true,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
      };
      _videoViews.add(data);
    });
  }

  void _addRemoteStream(MediaStream stream, String userId) async {
    RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
    await remoteRenderer.initialize();
    remoteRenderer.srcObject = stream;
    _remoteRenderers[userId] = remoteRenderer;
    setState(() {
      final data = {
        'id': userId,
        'widget': RTCVideoView(remoteRenderer,
            mirror: false,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
      };
      _videoViews.add(data);
    });
  }

  Future<RTCPeerConnection> _createPeerConnection(String userId) async {
    final configuration = {
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };
    final peerConnection = await createPeerConnection(configuration);
    _peerConnections[userId] = peerConnection;
    final audioTrack = _localStream!.getAudioTracks().first;
    final videoTrack = _localStream!.getVideoTracks().first;
    peerConnection.addTrack(videoTrack, _localStream!);
    peerConnection.addTrack(audioTrack, _localStream!);

    peerConnection.onAddStream = (stream) async {
      debugPrint('Adding Stream for user: $userId');
      _addRemoteStream(stream, userId);
    };

    peerConnection.onIceCandidate = (candidate) {
      debugPrint('Sending Ice Candidate to user: $userId');
      final iceCandidate = {
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'sdpMid': candidate.sdpMid,
        'candidate': candidate.candidate,
        'receiver_id': userId,
        'sender_id': Singleton.instance.userDataModel?.userId,
      };
      SocketManager.instance
          .emitWithEvent(Emitter.iceCandidateGroup, params: iceCandidate);
    };
    return peerConnection;
  }

  void cameraSwitch(CameraMode mode) async {
    if (isCameraOn) {
      if (_localStream != null) {
        final videoTrack = _localStream?.getVideoTracks().first;
        if (videoTrack != null) {
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
              'facingMode':
                  _cameraMode == CameraMode.front ? 'environment' : 'user',
              'optional': [],
            },
          });
          _cameraMode = mode;
          final newVideoTrack = stream.getVideoTracks().first;
          _localStream?.addTrack(newVideoTrack);
          _localRenderer.srcObject = _localStream;
          setState(() {
            final view = _videoViews
                .where(
                    (e) => e['id'] == Singleton.instance.userDataModel?.userId)
                .first;
            final index = _videoViews.indexOf(view);
            _videoViews.removeAt(index);
            view['widget'] = RTCVideoView(
              _localRenderer,
              mirror: _cameraMode == CameraMode.back ? false : true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            );
            _videoViews.insert(index, view);
          });
          for (final pc in _peerConnections.values) {
            final senders = await pc.getSenders();
            for (var sender in senders) {
              if (sender.track?.kind == 'video') {
                sender.replaceTrack(newVideoTrack);
              }
            }
          }
        }
      }
    }
  }

  void cameraOnOff() async {
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
    if (_localStream == null) return;
    final audioTrack = _localStream?.getAudioTracks().first;
    if (audioTrack == null) return;
    audioTrack.enabled = !audioTrack.enabled;
    setState(() {
      isMicOn = audioTrack.enabled;
    });
  }

  void speakerOnOff() {
    final audioTrack = _localStream?.getAudioTracks().first;
    audioTrack?.enableSpeakerphone(!isSpeakerOn);
    setState(() {
      isSpeakerOn = !isSpeakerOn;
    });
  }

  void _createOffer(String userId) async {
    final pc = _peerConnections[userId];
    RTCSessionDescription offer = await pc!.createOffer();
    await pc.setLocalDescription(offer).then((_) {
      final params = {
        'sdp': offer.sdp,
        'receiver_id': userId,
        'sender_id': Singleton.instance.userDataModel?.userId,
      };
      SocketManager.instance
          .emitWithEvent(Emitter.createGroupOffer, params: params);
    });
  }

  void _handleOffer(String sdp, String userId) async {
    final pc = await _createPeerConnection(userId);
    RTCSessionDescription offer = RTCSessionDescription(sdp, 'offer');
    await pc.setRemoteDescription(offer).then((_) {
      _createAnswer(pc, userId);
    });
  }

  void _createAnswer(RTCPeerConnection pc, String userId) async {
    RTCSessionDescription answer = await pc.createAnswer();
    await pc.setLocalDescription(answer).then((_) {
      final params = {
        'sdp': answer.sdp,
        'receiver_id': userId,
        'sender_id': Singleton.instance.userDataModel?.userId,
      };
      SocketManager.instance
          .emitWithEvent(Emitter.createGroupAnswer, params: params);
    });
  }

  void _handleAnswer(String sdp, String userId) async {
    final pc = _peerConnections[userId];
    RTCSessionDescription answer = RTCSessionDescription(sdp, 'answer');
    await pc?.setRemoteDescription(answer);
  }

  void _handleIceCandidate(
      Map<String, dynamic> candidate, String userId) async {
    final pc = _peerConnections[userId];
    final iceCandidate = RTCIceCandidate(
      candidate['candidate'],
      candidate['sdpMid'],
      candidate['sdpMLineIndex'],
    );
    await pc?.addCandidate(iceCandidate);
  }

  void _handleLeftGroup(String userId) async {
    _peerConnections[userId]?.close();
    _peerConnections.remove(userId);
    _remoteRenderers[userId]?.srcObject = null;
    _remoteRenderers[userId]?.dispose();
    _remoteRenderers.remove(userId);
    _videoViews.removeWhere((element) => element['id'] == userId);
    setState(() {});
  }

  void _tapReject() {
    Navigator.pop(context);
  }

  void _tapEnd() {
    final params = {
      'room_id': _groupCallModel.roomId,
      'user_id': Singleton.instance.userDataModel?.userId,
    };
    SocketManager.instance.emitWithEvent(Emitter.leftGroupCall, params: params);
    _remoteRenderers.forEach((key, value) {
      value.dispose();
    });
    _peerConnections.forEach((key, value) {
      value.dispose();
    });
    _remoteRenderers.clear();
    _peerConnections.clear();
    _videoViews.clear();
    Navigator.pop(context);
  }

  Future onListen(Listner event, dynamic data) async {
    groupCallStreamController.add((event, data));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: videoGridNew(),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    (widget.isReceivingCall ?? false) &&
                            (_groupCallModel.callStatus ==
                                CallStatus.incomingCall)
                        ? SizedBox(
                            height: 60,
                            width: getScreenWidth() * 0.8,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                buildButton(
                                  'Join',
                                  50.0,
                                  100.0,
                                  CustomColor.instance.colorPrimary,
                                  Colors.white,
                                  () {
                                    joinGroupCall();
                                  },
                                ),
                                buildButton(
                                  'Reject',
                                  50.0,
                                  100.0,
                                  Colors.red,
                                  Colors.white,
                                  () {
                                    _tapReject();
                                  },
                                )
                              ],
                            ),
                          )
                        : Container(
                            height: 60,
                            width: getScreenWidth() * 0.8,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                buildCallToolButtons(
                                  isSpeakerOn
                                      ? SelectionState.selected
                                      : SelectionState.unselected,
                                  isSpeakerOn
                                      ? Icons.volume_up
                                      : Icons.volume_off,
                                  () {
                                    speakerOnOff();
                                  },
                                ),
                                buildCallToolButtons(
                                  isCameraOn
                                      ? SelectionState.selected
                                      : SelectionState.unselected,
                                  isCameraOn
                                      ? Icons.videocam
                                      : Icons.videocam_off,
                                  () {
                                    cameraOnOff();
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
                                      _tapEnd();
                                    },
                                    icon: const Icon(
                                      Icons.call_end,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildButton(String title, double height, double width, Color bgColor,
      Color textColor, Function() onTap) {
    return CustomButton(
      onTap: onTap,
      title: title,
      height: height,
      width: width,
      backgroundColor: bgColor,
      borderRadius: 30,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      textColor: textColor,
    );
  }

  Widget videoGridNew() {
    int participants = _videoViews.length;
    if (_videoViews.isNotEmpty) {
      _videoViews[0]['widget'] = Stack(
        children: [
          _videoViews[0]['widget'],
          Positioned(
            top: 10,
            right: 10,
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
          ),
        ],
      );
    }
    if (participants <= 2) {
      return Column(
        children: _videoViews
            .map((view) => Expanded(child: view['widget']))
            .toList()
            .reversed
            .toList(),
      );
    } else if (participants <= 4) {
      return GridView.count(
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        crossAxisCount: 2,
        children: _videoViews
            .map(
              (view) => Container(
                color: Colors.white,
                child: view['widget'],
              ),
            )
            .toList()
            .reversed
            .toList(),
      );
    } else if (participants <= 8) {
      // Display participants in a 3x3 grid for up to 8 members
      return GridView.count(
        crossAxisCount: 3,
        children: _videoViews
            .map((view) => Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: view['widget'],
                ))
            .toList()
            .reversed
            .toList(),
      );
    } else {
      // Handle more participants if needed.
      return const Center(
        child: Text("More than 8 participants not supported yet."),
      );
    }
  }
}
