import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:demochat/components/custom_round_button.dart';
import 'package:demochat/components/flat_button.dart';
import 'package:demochat/constants/screen_dimention.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/libraries/custom_widgets.dart';
import 'package:demochat/libraries/stream_controllers.dart';
import 'package:demochat/socket_manager/socket_manager.dart';
import 'package:demochat/web_api/urls.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

// ignore: must_be_immutable
class MapScreen extends StatefulWidget {
  static final instance = MapScreenState();
  MapScreen({super.key, required this.imageUrl});
  String? imageUrl;
  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  late StreamSubscription<bool> subscription;
  late CameraPosition? _initialPosition;
  late Marker _marker;
  String? userImage;

  @override
  void initState() {
    super.initState();
    MapScreenModel.instance.initModel(0.0, 0.0);
    _initializeMarker();
    _initialPosition = CameraPosition(
      target: MapScreenModel.instance.userLatLong,
      zoom: 15.0,
    );
    userImage = '${Urls.instance.fileUrl}${widget.imageUrl}';
    _addMarker();
    initializeStream();
  }

  @override
  void dispose() {
    debugPrint('Dispose called');
    subscription.cancel();
    super.dispose();
  }

  void initializeStream() {
    subscription = googleMapScreenStreamController.stream.listen((event) {
      setState(() {
        _updateMarkerAndMoveCamera(MapScreenModel.instance.userLatLong);
      });
    });
  }

  Future<BitmapDescriptor> _getNetworkImageMarker(String url, int size) async {
    final http.Response response = await http.get(Uri.parse(url));
    final Uint8List bytes = response.bodyBytes;
    debugPrint('Bytes: ${bytes.length}');
    final ui.Codec codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: size,
      targetHeight: size,
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;
    // Create a circular canvas and draw the image onto it
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..isAntiAlias = true;

    final double radius = size / 2;
    // Draw a circular clip path
    canvas.drawCircle(Offset(radius, radius), radius, paint);
    // Clip the image to the circular area
    paint.shader = ImageShader(
        image, TileMode.clamp, TileMode.clamp, Matrix4.identity().storage);
    canvas.drawCircle(Offset(radius, radius), radius, paint);
    // Convert the canvas to an image
    final ui.Image circularImage =
        await pictureRecorder.endRecording().toImage(size, size);
    final ByteData? byteData =
        await circularImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedBytes = byteData!.buffer.asUint8List();
    debugPrint('Resized Bytes: ${resizedBytes.length}');
    return BitmapDescriptor.bytes(resizedBytes);
  }

  void _initializeMarker() {
    // Initialize _marker with a default value or actual marker
    _marker = const Marker(
      markerId: MarkerId('initial_marker'),
      position: LatLng(0.0, 0.0), // Example coordinates
    );
  }

  Future<void> _addMarker() async {
    late BitmapDescriptor markerIcon;
    if (Platform.isAndroid) {
      final http.Response response = await http.get(Uri.parse(userImage ?? ''));
      final Uint8List bytes = response.bodyBytes;
      img.Image originalImage = img.decodeImage(bytes.buffer.asUint8List())!;
      img.Image resizedImage =
          img.copyResize(originalImage, width: 100, height: 100);
      final Uint8List resizedData =
          Uint8List.fromList(img.encodePng(resizedImage));
      markerIcon = BitmapDescriptor.fromBytes(resizedData);
    } else {
      markerIcon = await _getNetworkImageMarker(userImage ?? '', 45);
    }

    setState(() {
      _marker = Marker(
        markerId: const MarkerId('customMarker'),
        position: MapScreenModel.instance.userLatLong,
        icon: markerIcon,
        infoWindow: const InfoWindow(
          title: 'Custom Position',
          snippet: 'This is a custom marker',
        ),
      );
    });
  }

  void _updateMarkerAndMoveCamera(LatLng newPosition) {
    _marker = _marker.copyWith(
      positionParam: newPosition,
    );
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(newPosition),
    );
  }

  void onListen(Listner event, dynamic data) {
    switch (event) {
      case Listner.receiveLiveLocation:
        MapScreenModel.instance
            .initModel(data['latitude'] ?? 0.0, data['longitude'] ?? 0.0);
        googleMapScreenStreamController.add(true);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Scaffold(
        appBar: appBar('Location'),
        backgroundColor: CustomColor.instance.colorPrimary,
        body: Stack(
          children: [
            googleMap(),
            Positioned(
              right: 20,
              bottom: 20,
              child: Column(
                children: [
                  buttonMyLocation(),
                  const SizedBox(
                    height: 10,
                  ),
                  buttonShareLocation(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget googleMap() {
    return GoogleMap(
      mapType: MapType.normal,
      myLocationButtonEnabled: false,
      initialCameraPosition: _initialPosition!,
      markers: {
        _marker,
      },
      onMapCreated: (controller) {
        _mapController = controller;
      },
    );
  }

  Widget buttonMyLocation() {
    return CustomRoundButton(
      height: 50,
      width: 50,
      borderRadius: 25,
      bgColor: CustomColor.instance.colorAppBar,
      icon: Icons.my_location,
      iconColor: Colors.white,
      onTap: () {
        _updateMarkerAndMoveCamera(MapScreenModel.instance.userLatLong);
      },
    );
  }

  Widget buttonShareLocation() {
    return CustomRoundButton(
      height: 50,
      width: 50,
      borderRadius: 25,
      bgColor: CustomColor.instance.colorAppBar,
      icon: Icons.share_location,
      iconColor: Colors.white,
      onTap: () {
        showModalBottomSheet(
          backgroundColor: Colors.transparent,
          context: context,
          builder: (BuildContext context) => showBottomSheet(),
        );
      },
    );
  }

  Widget showBottomSheet() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Container(
          height: 130,
          width: getScreenWidth(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 45,
                  child: CustomTextButton(
                      onTap: () {},
                      title: 'Share live location',
                      fontSize: 20.0,
                      fontWeight: FontWeight.normal,
                      textColor: Colors.black),
                ),
                SizedBox(
                  height: 45,
                  child: CustomTextButton(
                      onTap: () {},
                      title: 'Share live location',
                      fontSize: 20.0,
                      fontWeight: FontWeight.normal,
                      textColor: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MapScreenModel {
  static final instance = MapScreenModel();
  late LatLng userLatLong;

  void initModel(double lat, double long) {
    userLatLong = LatLng(lat, long);
  }
}
