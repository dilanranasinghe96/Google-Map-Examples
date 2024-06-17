import 'dart:convert';

import 'package:fab_circular_menu_plus/fab_circular_menu_plus.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:multi_dropdown/multiselect_dropdown.dart';
import 'package:share/share.dart';

import 'directions_page.dart';
import 'search_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _currentPosition;
  final List<Place> _places = [];
  String apiKey = 'AIzaSyCvJD8KpIoHBzaOr1WyTvqEto3pBf4-v60';
  double _distance = 0.0;
  bool _isDistanceVisible =
      false; // New variable to control distance label visibility
  MapType mapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition!,
          zoom: 15,
        ),
      ),
    );
    _addCurrentLocationMarker(_currentPosition!);
  }

  void _addCurrentLocationMarker(LatLng position) {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: position,
          infoWindow: const InfoWindow(title: 'Current Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }

  void _navigateToSearchPage() async {
    final searchQuery = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPage(searchController: _searchController),
      ),
    );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      _searchController.text = searchQuery;
      _searchAndNavigate();
    }
  }

  void _navigateToDirectionsPage() async {
    final routeData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectionsPage(
          startController: _startController,
          endController: _endController,
        ),
      ),
    );

    if (routeData != null &&
        routeData['start'].isNotEmpty &&
        routeData['end'].isNotEmpty) {
      _startController.text = routeData['start'];
      _endController.text = routeData['end'];
      _drawPolyline();
    }
  }

  Future<void> _drawPolyline() async {
    try {
      List<Location> startPlacemark =
          await locationFromAddress(_startController.text);
      List<Location> endPlacemark =
          await locationFromAddress(_endController.text);

      LatLng startLatLng =
          LatLng(startPlacemark[0].latitude, startPlacemark[0].longitude);
      LatLng endLatLng =
          LatLng(endPlacemark[0].latitude, endPlacemark[0].longitude);

      setState(() {
        _polylines.clear();
        _markers.removeWhere((marker) =>
            marker.markerId.value ==
            'currentLocation'); // Remove current location marker
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: [startLatLng, endLatLng],
          color: Colors.blue,
          width: 5,
        ));

        // Adding markers for start and end locations
        _markers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: startLatLng,
            infoWindow: const InfoWindow(title: 'Start Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
          ),
        );
        _markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: endLatLng,
            infoWindow: const InfoWindow(title: 'End Location'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );

        _distance = Geolocator.distanceBetween(
                startLatLng.latitude,
                startLatLng.longitude,
                endLatLng.latitude,
                endLatLng.longitude) /
            1000; // in kilometers
        _isDistanceVisible = true; // Show distance label
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
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
      print('Error: $e');
    }
  }

  void _searchAndNavigate() async {
    if (_searchController.text.isNotEmpty) {
      try {
        List<Location> locations =
            await locationFromAddress(_searchController.text);
        if (locations.isNotEmpty) {
          Location location = locations.first;
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(location.latitude, location.longitude),
                zoom: 15,
              ),
            ),
          );

          String url =
              'https://maps.googleapis.com/maps/api/place/textsearch/json?query=${_searchController.text}&location=${location.latitude},${location.longitude}&radius=5000&key=$apiKey';

          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            setState(() {
              _markers.clear();
              _places.clear();
              _polylines.clear(); // Clear all polylines
              _isDistanceVisible = false; // Hide distance label when searching
              for (var result in data['results']) {
                final lat = result['geometry']['location']['lat'];
                final lng = result['geometry']['location']['lng'];
                final name = result['name'];
                final address = result['formatted_address'];
                _markers.add(
                  Marker(
                    markerId: MarkerId(name),
                    position: LatLng(lat, lng),
                    infoWindow: InfoWindow(title: name, snippet: address),
                  ),
                );
                _places.add(Place(name, address, LatLng(lat, lng)));
              }
            });
          } else {
            throw Exception('Failed to load places');
          }
        }
      } catch (e) {
        print('Error: $e');
      }
    }
  }

//   Future<void> _shareLocation() async {
//   if (_currentPosition != null) {
//     String googleMapsUrl =
//         'https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}';

//     try {
//       // ignore: deprecated_member_use
//       await launch(googleMapsUrl);
//     } catch (e) {
//       print('Error launching URL: $e');
//       // Handle the error, e.g., show a snackbar or log the error
//     }
//   }
// }

  Future<void> _shareLocation() async {
    if (_currentPosition != null) {
      String googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}';
      String encodedGoogleMapsUrl = Uri.encodeFull(googleMapsUrl);

      try {
        await Share.share(
          'Check out my location: $encodedGoogleMapsUrl',
          subject: 'Location Sharing',
        );
      } catch (e) {
        print('Error sharing location: $e');
        // Handle the error, e.g., show a snackbar or log the error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share location: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Handle case where current location is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location not available.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        drawer: Drawer(
          child: Column(
            children: [
              Container(
                height: size.height * 0.25, // Example height for top section
                color: Colors.purpleAccent,
                // Your top section content here
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            MultiSelectDropDown<int>(
                              onOptionSelected:
                                  (List<ValueItem<int>> selectedOptions) {
                                setState(() {
                                  if (selectedOptions.isNotEmpty) {
                                    int? selectedValue =
                                        selectedOptions.first.value;
                                    if (selectedValue == 1) {
                                      mapType = MapType.normal;
                                      Navigator.pop(context);
                                    } else if (selectedValue == 2) {
                                      mapType = MapType.satellite;
                                      Navigator.pop(context);
                                    } else if (selectedValue == 3) {
                                      mapType = MapType.hybrid;
                                      Navigator.pop(context);
                                    } else if (selectedValue == 4) {
                                      mapType = MapType.terrain;
                                      Navigator.pop(context);
                                    }
                                  }
                                });
                              },
                              options: const [
                                ValueItem(label: 'Normal', value: 1),
                                ValueItem(label: 'Satellite', value: 2),
                                ValueItem(label: 'Hybrid', value: 3),
                                ValueItem(label: 'Terrain', value: 4),
                              ],
                              maxItems: 4,
                              selectionType: SelectionType.single,
                              chipConfig:
                                  const ChipConfig(wrapType: WrapType.wrap),
                              dropdownHeight: 200,
                              optionTextStyle: const TextStyle(fontSize: 18),
                              selectedOptionIcon:
                                  const Icon(Icons.check_circle),
                              hint: 'Map type..',
                              hintColor: Colors.grey.shade900,
                              hintStyle: const TextStyle(fontSize: 18),
                              singleSelectItemStyle:
                                  const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 50),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              title: const Text('Settings'),
                              leading: const Icon(Icons.settings),
                              onTap: () {
                                // Handle settings tap here
                                Navigator.pop(context); // Close the drawer
                              },
                            ),
                            ListTile(
                              title: const Text('Help'),
                              leading: const Icon(Icons.help),
                              onTap: () {
                                // Handle help tap here
                                Navigator.pop(context); // Close the drawer
                              },
                            ),
                            ListTile(
                              title: const Text('Support'),
                              leading: const Icon(Icons.support),
                              onTap: () {
                                // Handle support tap here
                                Navigator.pop(context); // Close the drawer
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        appBar: AppBar(
          title: const Text('Google Maps Integration'),
          backgroundColor: Colors.purpleAccent,
        ),
        body: Stack(
          children: [
            GoogleMap(
              mapType: mapType,
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? const LatLng(0, 0),
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _getCurrentLocation();
              },
              markers: _markers,
              polylines: _polylines,
            ),
            if (_places.isNotEmpty)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _places.length,
                    itemBuilder: (context, index) {
                      return _placeCard(_places[index]);
                    },
                  ),
                ),
              ),
            if (_isDistanceVisible) // Check if distance is visible
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.white,
                  child: Text(
                    'Distance: ${_distance.toStringAsFixed(2)} km',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FabCircularMenuPlus(
            alignment: Alignment.bottomLeft,
            fabColor: Colors.purpleAccent,
            fabOpenColor: Colors.purpleAccent.shade200,
            ringDiameter: 250.0,
            ringWidth: 60.0,
            ringColor: Colors.purpleAccent.shade100,
            fabSize: 60.0,
            children: [
              IconButton(
                onPressed: () {
                  _mapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: _currentPosition ?? const LatLng(0, 0),
                        zoom: 15,
                      ),
                    ),
                  );
                  _markers.add(
                    Marker(
                      markerId: const MarkerId('Current Location'),
                      position: _currentPosition ?? const LatLng(0, 0),
                      infoWindow:
                          InfoWindow(title: _currentPosition.toString()),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.my_location,
                  size: 30,
                ),
              ),
              IconButton(
                onPressed: _navigateToDirectionsPage,
                icon: const Icon(
                  Icons.navigation,
                  size: 30,
                ),
              ),
              IconButton(
                onPressed: _navigateToSearchPage,
                icon: const Icon(
                  Icons.search,
                  size: 30,
                ),
              ),
              IconButton(
                onPressed: () {
                  _shareLocation();
                },
                icon: const Icon(
                  Icons.share,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeCard(Place place) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(place.address),
            const Spacer(),
            TextButton(
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(place.location),
                );
              },
              child: const Text('View on map'),
            ),
          ],
        ),
      ),
    );
  }
}

class Place {
  final String name;
  final String address;
  final LatLng location;

  Place(this.name, this.address, this.location);
}
