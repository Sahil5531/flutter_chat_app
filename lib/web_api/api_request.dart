import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';
import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/web_api/urls.dart';
import 'package:loader_overlay/loader_overlay.dart';

class APIRequest {
  static final instance = APIRequest();
  var client = http.Client();

  Future<void> sendPostRequest(
      BuildContext? context, String urlStr, Map<String, dynamic>? params,
      {required Function successBlock}) async {
    try {
      bool isValidUrl = Uri.parse(Urls.instance.apiUrl + urlStr).isAbsolute;
      final url = Uri.parse(Urls.instance.apiUrl + urlStr);
      debugPrint('Request Url: $url');
      debugPrint('Requested params: $params');
      if (isValidUrl) {
        Map<String, String> header = {};
        final token = Singleton.instance.authenticationToken;
        if (token != '') {
          header = {'Content-Type': 'application/json', 'authorization': token};
        } else {
          header = {
            'Content-Type': 'application/json',
          };
        }
        context?.loaderOverlay.show();
        final response = await http
            .post(
              url,
              headers: header,
              body: jsonEncode(params),
            )
            .timeout(const Duration(seconds: 20));
        if (context?.mounted ?? false) {
          context?.loaderOverlay.hide();
        }
        debugPrint('Response code: ${response.statusCode}');
        if (response.statusCode == 200) {
          var jsonObj = json.decode(response.body);
          debugPrint('Json Data: $jsonObj');
          successBlock(jsonObj);
        } else {
          debugPrint(response.body);
        }
      } else {
        debugPrint('Invalid URL');
      }
    } catch (err) {
      if (context?.mounted ?? false) {
        context?.loaderOverlay.hide();
      }
      debugPrint("Error sendPostRequest: ${err.toString()}");
    }
  }

  Future<void> sendGetRequest(
      BuildContext? context, String urlStr, Map<String, dynamic> params,
      {required Function successBlock}) async {
    try {
      bool isValidUrl = Uri.parse('${Urls.instance.apiUrl}$urlStr').isAbsolute;
      if (params.isNotEmpty) {
        urlStr = '$urlStr?';
        params.forEach((key, value) {
          urlStr = '$urlStr$key=$value&';
        });
        urlStr = urlStr.substring(0, urlStr.length - 1);
      }
      var url = Uri.parse('${Urls.instance.apiUrl}$urlStr');
      debugPrint('Request Url: $url');
      debugPrint('Requested params: $params');
      if (isValidUrl) {
        Map<String, String> header = {};
        final token = Singleton.instance.authenticationToken;
        if (token != '') {
          header = {'Content-Type': 'application/json', 'authorization': token};
        } else {
          header = {
            'Content-Type': 'application/json',
          };
        }
        context?.loaderOverlay.show();
        final response = await http
            .get(url, headers: header)
            .timeout(const Duration(seconds: 20));
        if (context?.mounted ?? false) {
          context?.loaderOverlay.hide();
        }
        debugPrint('Response code: ${response.statusCode}');
        if (response.statusCode == 200) {
          var jsonObj = json.decode(response.body);
          successBlock(jsonObj);
        }
      } else {
        debugPrint('Invalid URL');
      }
    } catch (err) {
      if (context?.mounted ?? false) {
        context?.loaderOverlay.hide();
      }
      debugPrint("Error sendGetRequest: ${err.toString()}");
    }
  }

  Future sendMultipleFormDataRequest(
      BuildContext? context,
      String urlStr,
      Map<String, dynamic>? params,
      String? fileName,
      String? fileParam,
      String? fileType,
      String? filePath,
      {required Function successBlock}) async {
    try {
      bool isValidUrl = Uri.parse(Urls.instance.apiUrl + urlStr).isAbsolute;
      final url = Uri.parse(Urls.instance.apiUrl + urlStr);
      debugPrint('Request Url: $url');
      debugPrint('Requested params: $params');

      if (isValidUrl) {
        var request = http.MultipartRequest('POST', url);
        params!.forEach((key, value) {
          request.fields[key] = value.toString();
        });

        request.headers['Content-Type'] = 'application/json';
        request.headers['authorization'] =
            Singleton.instance.authenticationToken;
        context?.loaderOverlay.show();
        if (filePath != '') {
          var multipart = await http.MultipartFile.fromPath(
            fileParam!,
            filePath!,
            filename: fileName,
            contentType: MediaType.parse(fileType!),
          ).timeout(const Duration(seconds: 30));
          request.files.add(multipart);
        }

        final streamResponse = await request.send();
        var response = await http.Response.fromStream(streamResponse);
        if (context?.mounted ?? false) {
          context?.loaderOverlay.hide();
        }
        debugPrint('Response code: ${response.statusCode}');
        if (response.statusCode == 200) {
          var jsonObj = json.decode(response.body);
          successBlock(jsonObj);
        }
      } else {
        debugPrint('Invalid URL');
      }
    } catch (err) {
      if (context?.mounted ?? false) {
        context?.loaderOverlay.hide();
      }
      debugPrint("Error sendMultipleFormDataRequest: ${err.toString()}");
    }
  }
}
