import 'dart:async';
import 'dart:io';
import 'package:demochat/view_models/user_data_model.dart';
import 'package:demochat/views/google_map/google_map.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:custom_clippers/custom_clippers.dart';
import 'package:demochat/audio_player/audio_player.dart';
import 'package:demochat/components/custom_round_button.dart';
import 'package:demochat/libraries/generate_thumnails.dart';
import 'package:demochat/video_player/video_player.dart';
import 'package:demochat/views/image_viewer/image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/view_models/chat_messages_model.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/web_api/urls.dart';
import 'package:path_provider/path_provider.dart';
import 'package:capped_progress_indicator/capped_progress_indicator.dart';

StreamController<bool> chatBubbleStreamController =
    StreamController<bool>.broadcast();

// ignore: must_be_immutable
class ChatBubble extends StatefulWidget {
  ChatBubble({
    super.key,
    required this.index,
    required this.message,
    required this.isOTO,
    required this.isSetingState,
    required this.userDataModel,
  });
  int index;
  ChatMessagesModel message;
  bool isOTO;
  bool isSetingState;
  UserDataModel? userDataModel;
  AudioState audioState = AudioState.stopped;

  @override
  // ignore: library_private_types_in_public_api
  _ChatBubbleState createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  late StreamSubscription<bool> subscription;
  bool isCurrentUser = false;
  bool isSetingState = false;
  bool isFileDownloaded = false;
  bool isDownloading = false;
  String _roomId = '';
  Image? _thumbnailFile;
  String endLocationTitle = 'End Live Location';
  bool isLocationEnded = false;

  @override
  void initState() {
    super.initState();
    _roomId = widget.isOTO
        ? widget.message.otoConversationId
        : widget.message.groupId;
    isCurrentUser =
        widget.message.senderId == Singleton.instance.userDataModel?.userId;

    if (widget.message.messageType != ChatMessageType.text) {
      checkFileExist(widget.message.filePath.split('/').last, _roomId,
          ChatMessageType.video);
    }
    subscription = chatBubbleStreamController.stream.listen((events) {
      debugPrint('Event: $events');
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    subscription.cancel();
  }

  void checkFileExist(
      String fileName, String roomId, ChatMessageType type) async {
    switch (type) {
      case ChatMessageType.video:
        final docDir = await getApplicationDocumentsDirectory();
        final filePath =
            '${docDir.path}/videos/conversations/$roomId/$fileName';
        final file = File(filePath);
        if (mounted) {
          if (file.existsSync()) {
            setState(() {
              isFileDownloaded = true;
            });
          } else {
            setState(() {
              isFileDownloaded = false;
            });
          }
        }
        getThumbnail();
        break;
      default:
        break;
    }
  }

  Future<void> getThumbnail() async {
    if (widget.message.messageType == ChatMessageType.video &&
        widget.message.filePath != '') {
      final cacheDir = await getTemporaryDirectory();
      final fileName =
          (widget.message.filePath.split('/').last).split('.').first;
      final path = '${cacheDir.path}/$fileName.jpg';
      final file = File(path);
      if (file.existsSync()) {
        _thumbnailFile = Image.file(file, fit: BoxFit.cover);
        if (mounted) {
          setState(() {
            widget.isSetingState = false;
          });
        }
        return;
      }
      if (Platform.isAndroid) {
        final docDir = await getApplicationDocumentsDirectory();
        final filePath =
            '${docDir.path}/videos/conversations/$_roomId/$fileName.mp4';
        final file = File(filePath);
        if (file.existsSync()) {
          await GenerateVideoThumnail.getThumbnailFromPath(file.path)
              .then((value) {
            if (value != null) {
              _thumbnailFile = value;
              if (mounted) {
                setState(() {
                  widget.isSetingState = false;
                });
              }
            } else {
              debugPrint('Value is null');
              _thumbnailFile = Image.file(file, fit: BoxFit.cover);
              setState(() {
                widget.isSetingState = false;
              });
            }
          });
        }
      } else {
        await GenerateVideoThumnail.getThumbnailFromUrl(
                '${Urls.instance.fileUrl}${widget.message.filePath}')
            .then((value) {
          if (value != null) {
            _thumbnailFile = value;
            if (mounted) {
              setState(() {
                widget.isSetingState = false;
              });
            }
          }
        });
      }
    }
  }

  void tapAudioPlay(bool isCurrentUser) {
    debugPrint('Audio state: ${widget.audioState}');
    switch (widget.audioState) {
      case AudioState.playing:
        AudioPlayerManager.instance.pauseAudio();
        setState(() {
          widget.audioState = AudioState.paused;
        });
        break;
      case AudioState.paused:
        AudioPlayerManager.instance.resumeAudio();
        setState(() {
          widget.audioState = AudioState.playing;
        });
        break;
      case AudioState.stopped:
        final fileName = widget.message.filePath.split('/').last;
        isCurrentUser
            ? playSavedAudio(fileName)
            : downloadAndPlayAudio(fileName);
        break;
    }
    debugPrint('Audio state: ${widget.audioState}');
  }

  void playSavedAudio(String fileName) {
    setState(() {
      widget.audioState = AudioState.playing;
    });
    AudioPlayerManager.instance.playAudioFile(fileName, _roomId, (state) {
      debugPrint('Audio state: $state');
      if (state == PlayerState.completed) {
        widget.audioState = AudioState.stopped;
        chatBubbleStreamController.add(true);
      }
    });
  }

  void downloadAndPlayAudio(String fileName) {
    setState(() {
      widget.audioState = AudioState.playing;
    });
    AudioPlayerManager.instance.downloadFileAndPlay(
        '${Urls.instance.fileUrl}${widget.message.filePath}', _roomId, fileName,
        (filePath) {
      AudioPlayerManager.instance.playAudioFile(
        fileName,
        _roomId,
        (state) {
          debugPrint('Audio state: $state');
          if (state == PlayerState.completed) {
            widget.audioState = AudioState.stopped;
            chatBubbleStreamController.add(true);
          }
        },
      );
    });
  }

  void downlodVideo(String videoUrl) async {
    setState(() {
      isDownloading = true;
    });
    final dir = await getApplicationDocumentsDirectory();
    final fileName = widget.message.filePath.split('/').last;
    final filePath = '${dir.path}/videos/conversations/$_roomId/$fileName';
    debugPrint('Downloading video at $filePath');
    debugPrint('Video Url: $videoUrl');
    final response = await http.get(Uri.parse(videoUrl));
    final bytes = response.bodyBytes;
    debugPrint('Bytes: ${bytes.length}');
    try {
      final file = File(filePath);
      file.createSync(recursive: true);
      await file.writeAsBytes(bytes);
      debugPrint('File saved at: ${file.path}');
      await getThumbnail();
      setState(() {
        isFileDownloaded = true;
        isDownloading = false;
      });
    } catch (e) {
      debugPrint('Error saving file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSetingState) {
      _roomId = widget.isOTO
          ? widget.message.otoConversationId
          : widget.message.groupId;
      isCurrentUser =
          widget.message.senderId == Singleton.instance.userDataModel?.userId;
      getThumbnail();
    }
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: isCurrentUser
            ? const EdgeInsets.only(left: 100, top: 8, right: 15, bottom: 8)
            : const EdgeInsets.only(left: 15, top: 8, right: 100, bottom: 8),
        child: ClipPath(
          clipper: isCurrentUser
              ? LowerNipMessageClipper(MessageType.send)
              : UpperNipMessageClipper(MessageType.receive),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? CustomColor.instance.colorPrimary
                  : const Color.fromARGB(255, 207, 207, 207),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Padding(
              padding: isCurrentUser
                  ? const EdgeInsets.only(
                      left: 10,
                      top: 8,
                      right: 20,
                      bottom: 15,
                    )
                  : const EdgeInsets.only(
                      left: 20,
                      top: 20,
                      right: 12,
                      bottom: 12,
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Visibility(
                    visible: widget.message.messageType == ChatMessageType.text,
                    child: textMessage(),
                  ),
                  Visibility(
                    visible:
                        widget.message.messageType == ChatMessageType.image,
                    child: imageMessage(),
                  ),
                  Visibility(
                    visible:
                        widget.message.messageType == ChatMessageType.audio,
                    child: audioMessage(),
                  ),
                  Visibility(
                    visible:
                        widget.message.messageType == ChatMessageType.video,
                    child: videoMessage(),
                  ),
                  Visibility(
                    visible: widget.message.messageType ==
                        ChatMessageType.liveLocation,
                    child: liveLocation(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '14:00',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: isCurrentUser ? Colors.white : Colors.black,
                            fontSize: 10.0),
                      ),
                      Visibility(
                        visible: isCurrentUser,
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 4.0,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 2, top: 4, right: 0, bottom: 2),
                              child: Image.asset(
                                ImagePath.instance.doubleTick,
                                height: 10,
                                width: 15,
                                fit: BoxFit.cover,
                                color: widget.message.seen == 1
                                    ? Colors.blueAccent
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget textMessage() {
    return Text(
      widget.message.message,
      style: TextStyle(
          fontSize: 15.0,
          color: widget.message.senderId ==
                  Singleton.instance.userDataModel?.userId
              ? Colors.white
              : Colors.black),
    );
  }

  Widget audioMessage() {
    return Container(
      height: 30,
      width: 150,
      decoration: BoxDecoration(
        color: isCurrentUser
            ? CustomColor.instance.colorPrimary
            : const Color.fromARGB(255, 207, 207, 207),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomRoundButton(
            height: 30,
            width: 30,
            borderRadius: 15,
            bgColor: isCurrentUser
                ? Colors.white
                : CustomColor.instance.colorPrimary,
            iconColor: isCurrentUser
                ? CustomColor.instance.colorPrimary
                : Colors.white,
            icon: widget.audioState == AudioState.playing
                ? Icons.pause_circle
                : Icons.play_arrow,
            onTap: () {
              tapAudioPlay(isCurrentUser);
            },
          ),
          Text(
            'Audio Message',
            style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black,
                fontSize: 15.0),
          ),
        ],
      ),
    );
  }

  Widget imageMessage() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageViewer(
              imageUrl: widget.message.filePath,
            ),
            fullscreenDialog: true,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(10.0),
        ),
        child: widget.message.filePath != ''
            ? Image.network(
                '${Urls.instance.fileUrl}${widget.message.filePath}',
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              )
            : Image.asset(
                ImagePath.instance.placeholder,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget videoMessage() {
    return GestureDetector(
      onTap: () {
        if (!isFileDownloaded) {
          downlodVideo('${Urls.instance.fileUrl}${widget.message.filePath}');
        } else {
          final fileName = widget.message.filePath.split('/').last;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerWidget(
                roomId: _roomId,
                fileName: fileName,
              ),
              fullscreenDialog: true,
            ),
          );
        }
      },
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: isCurrentUser
              ? CustomColor.instance.colorPrimary
              : const Color.fromARGB(255, 207, 207, 207),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black,
          ),
          child: Stack(
            children: [
              Center(
                child: _thumbnailFile != null
                    ? Opacity(
                        opacity: isFileDownloaded ? 1.0 : 0.3,
                        child: _thumbnailFile,
                      )
                    : Image.asset(
                        ImagePath.instance.placeholder,
                        color: Colors.black,
                      ),
              ),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: isDownloading
                        ? Colors.transparent
                        : CustomColor.instance.colorPrimary,
                  ),
                  child: isDownloading
                      ? const CircularCappedProgressIndicator(
                          strokeCap: StrokeCap.square,
                          color: Colors.white,
                        )
                      : Image.asset(
                          isFileDownloaded
                              ? ImagePath.instance.play
                              : ImagePath.instance.download,
                          height: 35,
                          width: 35,
                          color: Colors.white,
                        ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget liveLocation() {
    return GestureDetector(
      onTap: () {
        if (isLocationEnded) {
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapScreen(
              imageUrl: widget.userDataModel?.userImageUrl ?? '',
            ),
            fullscreenDialog: true,
          ),
        ).then((value) => {
              // debugPrint('Location: $value'),
            });
      },
      child: Column(
        children: [
          Container(
            height: 130,
            width: 150,
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? CustomColor.instance.colorPrimary
                  : const Color.fromARGB(255, 207, 207, 207),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                color: Colors.transparent,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      ImagePath.instance.googleMap,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: isCurrentUser,
            child: SizedBox(
              height: 35,
              child: TextButton(
                onPressed: () {
                  if (isLocationEnded) {
                    return;
                  }
                  Singleton.instance.sharedLiveLocationData.removeWhere(
                      (value) => value.messageId == widget.message.messageId);
                  setState(() {
                    endLocationTitle = 'Location Ended';
                    isLocationEnded = true;
                  });
                },
                child: Text(
                  endLocationTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum AudioState { playing, paused, stopped }
