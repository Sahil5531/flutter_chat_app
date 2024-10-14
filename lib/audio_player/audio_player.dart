import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AudioPlayerManager {
  static var instance = AudioPlayerManager();
  final player = AudioPlayer();
  late BytesSource source;
  void setPlayerCallback(Function(PlayerState) callback) {
    player.onPlayerStateChanged.listen(callback);
  }

  void init() {}

  Future<void> playAudioFile(
      String fileName, String roomId, Function(PlayerState) callback) async {
    var dir = await getApplicationDocumentsDirectory();
    final filePath =
        "${dir.path}/audio_records/conversations/$roomId/$fileName";
    DeviceFileSource source = DeviceFileSource(filePath);
    debugPrint("Playing audio from $filePath");
    player.setSource(source);
    await player.play(source, volume: 1.0);
    player.onPlayerStateChanged.listen(callback);
  }

  Future<void> playAudioFromUrl(String url) async {
    debugPrint("Playing audio from $url");
    // final urlSource = UrlSource(url);
    player.setSourceUrl(url);
    player.play(UrlSource(url, mimeType: 'audio/aac'));
  }

  Future<void> downloadFileAndPlay(
      String url, String roomId, String fileName, Function callBack) async {
    var dir = await getApplicationDocumentsDirectory();
    if (await checkIfDirExist(dir.path, roomId)) {
      final filePath =
          "${dir.path}/audio_records/conversations/$roomId/$fileName";
      if (await checkIfFileExists(filePath)) {
        callBack(filePath);
        return;
      }
      debugPrint("Downloading audio from $url");
      var response = await http.get(Uri.parse(url));
      var bytes = response.bodyBytes;
      debugPrint('Bytes: ${bytes.length}');
      try {
        final file = File(filePath);
        file.createSync(recursive: true);
        debugPrint("File path: ${file.path}");
        await file.writeAsBytes(bytes);
        callBack(file.path);
      } catch (e) {
        debugPrint("Error saving file: $e");
      }
    }
  }

  Future<bool> checkIfFileExists(String filePath) async {
    var file = File(filePath);
    if (await file.exists()) {
      debugPrint("File exists");
      return true;
    } else {
      debugPrint("File does not exist");
      return false;
    }
  }

  Future<bool> checkIfDirExist(String path, String roomId) async {
    final dir = '$path/audio_records/conversations/$roomId';
    if (await Directory(dir).exists()) {
      return true;
    } else {
      final audioDir = Directory(dir);
      await audioDir.create(recursive: true);
      return true;
    }
  }

  void pauseAudio() {
    player.pause();
  }

  void resumeAudio() {
    player.resume();
  }

  void stopAudio() {
    player.stop();
  }
}
