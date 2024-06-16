import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_preview/services/gps-service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OnTapMarker extends StatefulWidget {
  const OnTapMarker({super.key});

  @override
  State<OnTapMarker> createState() => _OnTapMarkerState();
}

class _OnTapMarkerState extends State<OnTapMarker> {
  List<Marker> myMarker = [];
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
                  zoom: 15,
                  target: LatLng(position.latitude, position.longitude)),
              markers: Set.from(myMarker),
              onTap: _handleTap,
            );
          }),
    );
  }

  _handleTap(LatLng tappedPoint) {
    setState(() {
      myMarker = [];
      myMarker.add(
        Marker(
            markerId: MarkerId(tappedPoint.toString()),
            position: tappedPoint,
            draggable: true),
      );
    });
  }
}
