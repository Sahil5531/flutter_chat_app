import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/libraries/singleton.dart';

class CustomImagePicker {
  static final instance = CustomImagePicker();
  XFile? imageFile;

  Future openImagePicker({required Function callback}) async {
    showDialog(
        context: Singleton.instance.context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Image From'),
            actions: [
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final imagePicker = ImagePicker();
                    imageFile =
                        await imagePicker.pickImage(source: ImageSource.camera);
                    if (imageFile != null) {
                      callback(imageFile);
                    }
                  },
                  child: Text(
                    'Camera',
                    style: TextStyle(color: CustomColor.instance.colorPrimary),
                  )),
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final imagePicker = ImagePicker();
                    imageFile = await imagePicker.pickImage(
                        source: ImageSource.gallery);
                    if (imageFile != null) {
                      callback(imageFile);
                    }
                  },
                  child: Text(
                    'Gallary',
                    style: TextStyle(color: CustomColor.instance.colorPrimary),
                  )),
            ],
          );
        });
  }
}
