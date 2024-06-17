import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DrawingRoutes extends StatefulWidget {
  const DrawingRoutes({super.key});

  @override
  State<DrawingRoutes> createState() => _DrawingRoutesState();
}

class _DrawingRoutesState extends State<DrawingRoutes> {
  late GoogleMapController _mapController;
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final List<LatLng> _polylineCoordinates = [];
  final Set<Polyline> _polylines = {};
  String? _errorMessage;

  Future<void> _drawPolyline() async {
    try {
      // Get coordinates from addresses
      List<Location> startPlacemark =
          await locationFromAddress(_startController.text);
      List<Location> endPlacemark =
          await locationFromAddress(_endController.text);

      LatLng startLatLng =
          LatLng(startPlacemark[0].latitude, startPlacemark[0].longitude);
      LatLng endLatLng =
          LatLng(endPlacemark[0].latitude, endPlacemark[0].longitude);

      setState(() {
        _polylineCoordinates.clear();
        _polylineCoordinates.add(startLatLng);
        _polylineCoordinates.add(endLatLng);

        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: _polylineCoordinates,
          color: Colors.blue,
          width: 5,
        ));

        _errorMessage = null;
      });

      _mapController.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            startLatLng.latitude < endLatLng.latitude
                ? startLatLng.latitude
                : endLatLng.latitude,
            startLatLng.longitude < endLatLng.longitude
                ? startLatLng.longitude
                : endLatLng.longitude,
          ),
          northeast: LatLng(
            startLatLng.latitude > endLatLng.latitude
                ? startLatLng.latitude
                : endLatLng.latitude,
            startLatLng.longitude > endLatLng.longitude
                ? startLatLng.longitude
                : endLatLng.longitude,
          ),
        ),
        50,
      ));
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Draw Route')),
      body: FutureBuilder<Position>(
        future: Geolocator.getCurrentPosition(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Unable to determine position'),
            );
          }

          Position position = snapshot.data!;
          LatLng initialPosition =
              LatLng(position.latitude, position.longitude);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _startController,
                  decoration: const InputDecoration(
                    hintText: 'Enter start location',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _endController,
                  decoration: const InputDecoration(
                    hintText: 'Enter end location',
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _drawPolyline,
                child: const Text('Draw Route'),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initialPosition,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  polylines: _polylines,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
