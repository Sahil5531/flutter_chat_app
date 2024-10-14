import 'dart:async';
import 'dart:io';
import 'package:demochat/audio_recorder/audio_recorder.dart';
import 'package:demochat/components/custom_alert.dart';
import 'package:demochat/components/custom_round_button.dart';
import 'package:demochat/constants/screen_dimention.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/libraries/generate_thumnails.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

// ignore: must_be_immutable
class VideoRecorderScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _VideoRecorderScreenState createState() => _VideoRecorderScreenState();

  VideoRecorderScreen({super.key, required this.roomId});
  late String roomId;
}

class _VideoRecorderScreenState extends State<VideoRecorderScreen> {
  CameraController? _controller;
  VideoPlayerController? _videoPlayerController;
  bool _isRecording = false;
  // bool _isPlaying = false;
  VideoPlayerStatus _videoPlayerStatus = VideoPlayerStatus.stopped;
  bool _isVideoPlayerInitialized = false;
  File? _videoFile;
  Timer? _timer;
  String _timerCount = '00:00';
  bool _isVideoRecorded = false;
  CameraDescription? _frontCam;
  CameraDescription? _backCam;
  CameraLensDirection _cameraDirection = CameraLensDirection.back;
  bool _isFlashOn = false;
  MediaInfo? compressVideoInfo;
  Subscription? _subscription;
  Image? thumbnail;

  @override
  void initState() {
    super.initState();
    _subscription = VideoCompress.compressProgress$.subscribe((progress) {
      debugPrint('Progress: $progress');
      setState(() {
        // _progress = progress;
      });
    });
    _initializeCamera();
  }

  @override
  void dispose() {
    debugPrint('Dispose video recorder');
    _controller?.dispose();
    _timer?.cancel();
    _subscription!.unsubscribe();
    VideoCompress.cancelCompression();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      return;
    }
    _backCam = cameras.first;
    _frontCam = cameras.last;
    _controller = CameraController(_backCam!, ResolutionPreset.high);
    await _controller?.initialize();
    setState(() {
      _controller!.setFlashMode(FlashMode.off);
    });
  }

  Future<void> initializeVideoPlayer(String path) async {
    _videoPlayerController = VideoPlayerController.file(File(path));
    await _videoPlayerController?.initialize().then((_) {
      debugPrint('Video player initialized');
      setState(() {
        _isVideoPlayerInitialized = true;
        _videoPlayerStatus = VideoPlayerStatus.stopped;
      });
    });
    _videoPlayerController?.addListener(() {
      if (_videoPlayerController!.value.isCompleted) {
        setState(() {
          // _isPlaying = false;
          _videoPlayerStatus = VideoPlayerStatus.stopped;
        });
      }
    });
  }

  Future<void> _startRecording() async {
    debugPrint('Start video recording');
    if (!_controller!.value.isInitialized) {
      return;
    }

    try {
      await _controller?.startVideoRecording().then((_) {
        debugPrint('Recording started');
        setState(() {
          _isRecording = true;
          startRecordingTimer();
        });
      });
    } catch (e) {
      debugPrint('Error catch: $e');
    }
  }

  Future<void> _stopRecording() async {
    debugPrint('Stop video recording');
    if (!_controller!.value.isRecordingVideo) {
      return;
    }

    try {
      await _controller!.stopVideoRecording().then((XFile file) async {
        debugPrint('Recording stopped');
        File originalFile = File(file.path);
        final bytes = originalFile.readAsBytesSync();
        debugPrint('Bytes count original: ${bytes.length}');
        stopRecordingTimer();
        await compressVideoSize(file.path);
        debugPrint('Compressed video path: ${compressVideoInfo?.file?.path}');
        _videoFile = File(compressVideoInfo?.file?.path ?? "");
        final newBytes = _videoFile!.readAsBytesSync();
        debugPrint('Bytes count compressed: ${newBytes.length}');
        _controller?.pausePreview();
        await initializeVideoPlayer(_videoFile!.path);
        await GenerateVideoThumnail.getThumbnailFromPath(_videoFile!.path)
            .then((value) {
          thumbnail = value;
          setState(() {
            _isRecording = false;
            _isVideoRecorded = true;
          });
        });
      });
    } catch (e) {
      debugPrint('Error catch: $e');
    }
  }

  void startRecordingTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final minutes = int.parse(_timerCount.split(':')[0]);
      final seconds = int.parse(_timerCount.split(':')[1]);
      if (seconds < 59) {
        if (seconds < 9) {
          setState(() {
            _timerCount = '0$minutes:0${seconds + 1}';
          });
        } else {
          setState(() {
            _timerCount = '0$minutes:${seconds + 1}';
          });
        }
      } else {
        setState(() {
          _timerCount = '${minutes + 1}:00';
        });
      }
    });
  }

  void stopRecordingTimer() async {
    _timer!.cancel();
    setState(() {
      _timerCount = '00:00';
    });
  }

  void playVideo() {
    if (_isVideoPlayerInitialized) {
      _videoPlayerController?.play();
      setState(() {
        // _isPlaying = true;
        _videoPlayerStatus = VideoPlayerStatus.playing;
      });
    }
  }

  void pauseVideo() {
    if (_isVideoPlayerInitialized) {
      _videoPlayerController?.pause();
      setState(() {
        // _isPlaying = false;
        _videoPlayerStatus = VideoPlayerStatus.paused;
      });
    }
  }

  Future<void> sendVideo() async {
    if (_videoFile != null) {
      final bytes = _videoFile?.readAsBytesSync();
      final length = bytes?.length ?? 0;
      if (length < 52428800) {
        final videoName = _videoFile?.path.split('/').last;
        currentFileName = videoName!;
        Navigator.pop(context, _videoFile);
        await storeVideoInDocuments();
        deleteVideo();
      } else {
        showAlertOk('Alert', 'Video size should be less than 50MB');
      }
    }
  }

  Future<void> storeVideoInDocuments() async {
    final docDir = await getApplicationDocumentsDirectory();
    final newPath = '${docDir.path}/videos/conversations/${widget.roomId}';
    debugPrint('New path: $newPath');
    final dir = Directory(newPath);
    await dir.create(recursive: true);
    final newFile = await _videoFile?.copy('$newPath/$currentFileName');
    newFile?.createSync(recursive: true);
    debugPrint('Video stored at ${newFile?.path}');
  }

  void deleteVideo() async {
    _controller?.resumePreview();
    _videoPlayerController?.dispose();
    if (await _videoFile!.exists()) {
      await _videoFile!.delete();
      debugPrint("Video deleted");
    }
  }

  Future<void> compressVideoSize(String path) async {
    compressVideoInfo = await VideoCompress.compressVideo(
      path,
      quality: VideoQuality.MediumQuality,
      includeAudio: true,
      frameRate: 30,
      deleteOrigin: true, // If you want to delete the original file
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return Container();
    }
    return SafeArea(
      child: Scaffold(
        body: Container(
          color: Colors.black,
          child: Center(
            child: Stack(
              children: [
                CameraPreview(_controller!),
                Visibility(
                  visible: _cameraDirection == CameraLensDirection.back,
                  child: Positioned(
                    top: 25,
                    left: 15,
                    child: buttonFlash(),
                  ),
                ),
                Visibility(
                  visible: _isRecording,
                  child: recordingTimer(),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: buttonClose(),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _isRecording
                          ? buttonStopRecording()
                          : buttonStartRecording(),
                    ],
                  ),
                ),
                Visibility(
                  visible: !_isRecording,
                  child: Positioned(
                    bottom: 30,
                    right: 20,
                    child: buttonSwitchCamera(),
                  ),
                ),
                Visibility(
                  visible: _isVideoRecorded,
                  child: _isVideoRecorded ? previewVideo() : Container(),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buttonClose() {
    return IconButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      icon: const Icon(Icons.close),
      iconSize: 40,
      color: Colors.white,
    );
  }

  Widget buttonFlash() {
    return GestureDetector(
      onTap: () {
        if (!_isFlashOn) {
          _controller!.setFlashMode(FlashMode.torch);
          _isFlashOn = true;
        } else {
          _controller!.setFlashMode(FlashMode.off);
          _isFlashOn = false;
        }
        setState(() {});
      },
      child: Icon(
        _isFlashOn ? Icons.flash_on : Icons.flash_off,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget recordingTimer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 15),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _timerCount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget buttonStartRecording() {
    return GestureDetector(
      onTap: () {
        _startRecording();
      },
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
        ),
      ),
    );
  }

  Widget buttonStopRecording() {
    return GestureDetector(
      onTap: () => _stopRecording(),
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
        ),
        child: Center(
          child: Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(5),
              )),
        ),
      ),
    );
  }

  Widget buttonSwitchCamera() {
    return GestureDetector(
      onTap: () {
        if (_controller!.description.lensDirection ==
            CameraLensDirection.front) {
          _controller = CameraController(
            _backCam!,
            ResolutionPreset.high,
          );
        } else {
          _controller = CameraController(
            _frontCam!,
            ResolutionPreset.high,
          );
        }
        _controller!.initialize().then((_) {
          setState(() {
            _cameraDirection = _controller!.description.lensDirection;
          });
        });
      },
      child: const Icon(
        Icons.switch_camera_outlined,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget previewVideo() {
    return Container(
      color: Colors.black,
      height: getScreenHeight(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Visibility(
              visible: _videoPlayerStatus == VideoPlayerStatus.stopped,
              child: Container(
                height: getScreenHeight() / 1.5,
                width: getScreenWidth(),
                color: Colors.black,
                child: thumbnail,
              ),
            ),
            Visibility(
              visible: _videoPlayerStatus != VideoPlayerStatus.stopped,
              child: Container(
                height: getScreenHeight() / 1.5,
                // width: getScreenWidth(),
                color: Colors.black,
                child: VideoPlayer(_videoPlayerController!),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buttonNewRecording(),
                  const Spacer(),
                  buttonPlay(),
                  const Spacer(),
                  buttonSend(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buttonNewRecording() {
    return IconButton(
      onPressed: () {
        deleteVideo();
        setState(() {
          _isVideoRecorded = false;
        });
      },
      icon: const Icon(Icons.close),
      iconSize: 40,
      color: Colors.white,
    );
  }

  Widget buttonPlay() {
    return IconButton(
      onPressed: () {
        _videoPlayerStatus == VideoPlayerStatus.playing
            ? pauseVideo()
            : playVideo();
      },
      icon: _videoPlayerStatus == VideoPlayerStatus.playing
          ? const Icon(Icons.pause_circle_outline)
          : const Icon(Icons.play_circle_outline),
      iconSize: 50,
      color: Colors.white,
    );
  }

  Widget buttonSend() {
    return CustomRoundButton(
      height: 40,
      width: 40,
      borderRadius: 20,
      bgColor: Colors.white,
      icon: Icons.send,
      iconColor: CustomColor.instance.colorPrimary,
      shadowColor: Colors.white,
      onTap: () {
        sendVideo();
      },
    );
  }
}

enum VideoPlayerStatus { playing, paused, stopped }
