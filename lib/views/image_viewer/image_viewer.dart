import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/web_api/urls.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class ImageViewer extends StatelessWidget {
  late String imageUrl = '';

  ImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 60, 10, 0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 30,
                    ),
                    color: Colors.white, // Replace with your desired icon color
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Visibility(
                  visible: imageUrl.isEmpty,
                  child: Image.asset(
                    ImagePath.instance.placeholder,
                    fit: BoxFit.cover,
                    height: MediaQuery.of(context).size.height * 0.7,
                  ),
                ),
                Visibility(
                  visible: imageUrl.isNotEmpty,
                  child: Image.network(
                    '${Urls.instance.fileUrl}$imageUrl',
                    fit: BoxFit.contain,
                    height: MediaQuery.of(context).size.height * 0.7,
                    width: MediaQuery.of(context).size.width,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
