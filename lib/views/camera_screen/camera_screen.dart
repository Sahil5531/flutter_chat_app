import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    CameraDescription description =
        await availableCameras().then((cameras) => cameras.first);
    _controller = CameraController(description, ResolutionPreset.high);
    await _controller!.initialize();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _takePicture() async {
    final file = await _controller!.takePicture();
    debugPrint('Image Path: ${file.path}');
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_null_comparison
    if (_controller == null) {
      return Container();
    }
    return Scaffold(
      body: Center(
        child: Stack(
          children: [
            CameraPreview(_controller!),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    iconSize: 40,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
