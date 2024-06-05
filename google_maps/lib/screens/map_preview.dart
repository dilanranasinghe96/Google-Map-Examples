import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_preview/services/gps-service.dart';
import 'package:google_map_preview_flutter/google_map_preview_flutter.dart';

class MapPreview extends StatefulWidget {
  const MapPreview({super.key});

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder(
      future: GpsService.determinePosition(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Something went wrong'),
          );
        }

        Position position = snapshot.data!;

        return GoogleMap(
            initialCameraPosition: CameraPosition(
                target: LatLng(position.latitude, position.longitude)));
      },
    ));
  }
}
