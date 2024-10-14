import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

String currentFilePath = '';
String currentFileName = '';

class AudioRecorderManager {
  final recorder = AudioRecorder();
  String? _filePath;

  Future<void> checkMicrophonePermission() async {
    if (!await recorder.hasPermission()) {
      debugPrint("Permission denied");
    }
  }

  Future<bool> init(String roomId, String userId) async {
    if (!await recorder.hasPermission()) {
      debugPrint("Permission denied");
      return false;
    }
    final documentDir = await getApplicationDocumentsDirectory();
    final date = DateTime.now().millisecondsSinceEpoch;
    final dir = '${documentDir.path}/audio_records/conversations/$roomId';
    final audioDir = Directory(dir);
    await audioDir.create(recursive: true);
    _filePath = '$dir/$date.aac';
    debugPrint("Start recording on path: $_filePath");
    currentFilePath = _filePath ?? '';
    currentFileName = '$date.aac';
    return true;
  }

  Future<void> startRecording() async {
    if (await recorder.hasPermission()) {
      await recorder.start(
          const RecordConfig(
              encoder: AudioEncoder.aacLc,
              androidConfig: AndroidRecordConfig(useLegacy: true)),
          path: _filePath!);
    } else {
      debugPrint("Permission denied");
    }
  }

  Future<File?> stopRecording() async {
    final path = await recorder.stop();
    debugPrint("Save recording on path: $path");
    return File(path!);
  }

  Future<void> deleteRecording() async {
    if (_filePath == null) return;
    final path = await recorder.stop();
    final file = File(path!);
    if (await file.exists()) {
      await file.delete();
      debugPrint("Recording deleted on path: $path");
    }
  }

  void dispose() {
    recorder.dispose();
  }
}
