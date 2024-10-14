import 'package:flutter/material.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/libraries/singleton.dart';

Future showAlertOk(String title, String message, {Function? callBack}) async {
  return showDialog(
      context: Singleton.instance.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16.0),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (callBack != null) {
                  callBack();
                }
              },
              child: Text(
                'Ok',
                style: TextStyle(
                    color: CustomColor.instance.colorPrimary,
                    fontWeight: FontWeight.bold),
              ),
            )
          ],
        );
      });
}

enum Buttons { ok, cancel }

Future showAlertOkCancel(String title, String message,
    {required Function callBack}) async {
  return showDialog(
      context: Singleton.instance.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16.0),
          ),
          actions: [
            TextButton(
              onPressed: () {
                callBack(Buttons.ok);
                Navigator.of(context).pop();
              },
              child: Text(
                'Ok',
                style: TextStyle(
                    color: CustomColor.instance.colorPrimary,
                    fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                callBack(Buttons.cancel);
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                    color: CustomColor.instance.colorPrimary,
                    fontWeight: FontWeight.bold),
              ),
            )
          ],
        );
      });
}
