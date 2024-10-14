import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class GenerateVideoThumnail {
  static Future<Image?> getThumbnailFromUrl(String videoUrl) async {
    try {
      final directory = await getTemporaryDirectory();
      debugPrint('$directory, VideoUrl: $videoUrl');
      final String? fileName = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: directory.path,
        imageFormat: ImageFormat.JPEG,
        quality: 50,
      );
      if (fileName != null) {
        return Image.file(File(fileName), fit: BoxFit.cover);
      }
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
    }
    return null;
  }

  static Future<Image?> getThumbnailFromPath(String videoPath) async {
    debugPrint('Genrating thumnail from path: $videoPath');
    try {
      final uint8list = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        quality: 50,
      );
      if (uint8list == null) {
        return null;
      }
      return Image.memory(uint8list, fit: BoxFit.cover);
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }
}
