import 'dart:io';
import 'package:demochat/constants/screen_dimention.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String roomId;
  final String fileName;
  const VideoPlayerWidget({
    super.key,
    required this.roomId,
    required this.fileName,
  });

  @override
  // ignore: library_private_types_in_public_api
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool isPlaying = false;
  String _timer = '00:00';

  @override
  void initState() {
    super.initState();
    initializeVideoPlayer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void initializeVideoPlayer() async {
    try {
      final file = await createFile();
      debugPrint("Playing File: ${file.path}");
      if (file.existsSync()) {
        _controller = VideoPlayerController.file(file);
        _controller?.initialize().then((_) {
          setState(() {});
        });
        _controller?.addListener(() {
          setState(() {
            if (_controller == null) {
              return;
            }
            final remainingTime =
                _controller!.value.duration - _controller!.value.position;
            final minutes = remainingTime.inMinutes.toString().padLeft(2, '0');
            final seconds =
                (remainingTime.inSeconds % 60).toString().padLeft(2, '0');
            _timer = '-$minutes:$seconds';
            debugPrint("Remaining time: $_timer");
          });
          if (_controller?.value.isCompleted ?? false) {
            setState(() {
              isPlaying = false;
            });
          }
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<File> createFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        "${dir.path}/videos/conversations/${widget.roomId}/${widget.fileName}";
    final file = File(filePath);
    return file;
  }

  void playVideo() {
    _controller?.play();
    setState(() {
      isPlaying = true;
    });
  }

  void pauseVideo() {
    _controller?.pause();
    setState(() {
      isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Container(
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: buttonClose(),
                ),
                const Spacer(),
                Container(
                  width: getScreenWidth(),
                  height: getScreenHeight() / 2.5,
                  color: Colors.white,
                  child: _controller != null
                      ? VideoPlayer(_controller!)
                      : Container(),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 30,
                  child: Slider(
                    activeColor: Colors.white,
                    inactiveColor: Colors.grey,
                    value:
                        _controller?.value.position.inSeconds.toDouble() ?? 0.0,
                    min: 0.0,
                    max:
                        _controller?.value.duration.inSeconds.toDouble() ?? 0.0,
                    onChanged: (value) {
                      debugPrint("Value: $value");
                      _controller?.seekTo(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 0, right: 20),
                  child: Row(
                    children: [
                      const Spacer(),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: buttonPlayPause(),
                        ),
                      ),
                      remainingTimer(),
                    ],
                  ),
                ),
                const Spacer(),
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

  Widget buttonPlayPause() {
    return IconButton(
      onPressed: () {
        if (isPlaying) {
          pauseVideo();
        } else {
          playVideo();
        }
      },
      icon: Icon(
        isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget remainingTimer() {
    return Text(
      _timer,
      style: const TextStyle(color: Colors.white),
    );
  }
}
