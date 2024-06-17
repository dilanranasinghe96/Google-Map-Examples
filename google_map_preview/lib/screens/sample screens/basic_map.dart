import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_preview/services/gps-service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BasicMap extends StatefulWidget {
  const BasicMap({super.key});

  @override
  State<BasicMap> createState() => _BasicMapState();
}

class _BasicMapState extends State<BasicMap> {
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
          }),
    );
  }
}
