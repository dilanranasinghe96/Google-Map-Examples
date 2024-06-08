import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchLocation extends StatefulWidget {
  const SearchLocation({super.key});

  @override
  State<SearchLocation> createState() => _SearchLocationState();
}

class _SearchLocationState extends State<SearchLocation> {
  String? searchAddr;
  GoogleMapController? mapController;
  LatLng? markerPosition;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Center(
            child: SizedBox(
              height: 36,
              child: TextField(
                maxLines: 1,
                style: const TextStyle(fontSize: 17),
                textAlignVertical: TextAlignVertical.center,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true,
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Search',
                  suffixIcon: IconButton(
                    onPressed: searchAndNavigate,
                    icon: const Icon(Icons.search),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    searchAddr = val;
                  });
                },
              ),
            ),
          ),
        ),
        body: Stack(
          children: <Widget>[
            GoogleMap(
              mapType: MapType.normal,
              onMapCreated: onMapCreated,
              initialCameraPosition: const CameraPosition(
                  target: LatLng(40.7128, -74.0060), zoom: 10.0),
              markers: {
                if (markerPosition != null)
                  Marker(
                    markerId: const MarkerId('My Location'),
                    position: markerPosition!,
                    icon: BitmapDescriptor.defaultMarker,
                    infoWindow: const InfoWindow(title: 'My Location'),
                  ),
              },
            )
          ],
        ),
      ),
    );
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  searchAndNavigate() async {
    if (searchAddr != null) {
      try {
        List<Location> locations = await locationFromAddress(searchAddr!);
        if (locations.isNotEmpty) {
          Location location = locations.first;
          setState(() {
            markerPosition = LatLng(location.latitude, location.longitude);
          });
          mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(location.latitude, location.longitude),
                zoom: 15,
              ),
            ),
          );
        }
      } catch (e) {
        print('Error: $e');
      }
    }
  }
}
