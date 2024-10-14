import 'dart:async';

import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/libraries/stream_controllers.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationManager {
  Position? currentPosition;
  StreamSubscription<Position>? _positionStream;

  startLocationUpdates() async {
    _checkPermissionAndStartLocationUpdates();
  }

  stopLocationUpdates() {
    _positionStream?.cancel();
  }

  Future<void> _checkPermissionAndStartLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, don't continue
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, don't continue
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, handle appropriately
      return;
    }

    // Start listening for location updates
    try {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter:
              1, // minimum distance (in meters) a user must move to trigger an update
        ),
      ).listen(
        (Position position) {
          currentPosition = position;
          // debugPrint(
          //     'Location: ${currentPosition?.latitude} ${currentPosition?.longitude}');
          // debugPrint('${Singleton.instance.sharedLiveLocationData.isNotEmpty}');
          if (Singleton.instance.sharedLiveLocationData.isNotEmpty) {
            shareLiveLocationStreamController.add(true);
          }
        },
      );
    } catch (e) {
      debugPrint("An error occurred: $e");
    }
  }
}
