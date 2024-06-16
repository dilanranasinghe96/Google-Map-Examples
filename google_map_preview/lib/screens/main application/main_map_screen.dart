import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:multi_dropdown/multiselect_dropdown.dart';

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
  String apiKey = 'AIzaSyBsHNN0wRTqbFOspHRvcl-l4plfE6DUahw';
  double _distance = 0.0;
  MapType mapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // void _getCurrentLocation() async {
  //   Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high);
  //   setState(() {
  //     _currentPosition = LatLng(position.latitude, position.longitude);
  //   });
  //   _mapController?.animateCamera(
  //     CameraUpdate.newCameraPosition(
  //       CameraPosition(
  //         target: _currentPosition!,
  //         zoom: 15,
  //       ),
  //     ),
  //   );
  // }

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
        _markers.clear(); // Clear existing markers
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: [startLatLng, endLatLng],
          color: Colors.blue,
          width: 5,
        ));

        // Adding markers for start, end, and current locations
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
        if (_currentPosition != null) {
          _markers.add(
            Marker(
              markerId: const MarkerId('current'),
              position: _currentPosition!,
              infoWindow: const InfoWindow(title: 'Current Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
            ),
          );
        }

        _distance = Geolocator.distanceBetween(
                startLatLng.latitude,
                startLatLng.longitude,
                endLatLng.latitude,
                endLatLng.longitude) /
            1000; // in kilometers
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

  // Future<void> _drawPolyline() async {
  //   try {
  //     List<Location> startPlacemark =
  //         await locationFromAddress(_startController.text);
  //     List<Location> endPlacemark =
  //         await locationFromAddress(_endController.text);

  //     LatLng startLatLng =
  //         LatLng(startPlacemark[0].latitude, startPlacemark[0].longitude);
  //     LatLng endLatLng =
  //         LatLng(endPlacemark[0].latitude, endPlacemark[0].longitude);

  //     setState(() {
  //       _polylines.clear();
  //       _polylines.add(Polyline(
  //         polylineId: const PolylineId('route'),
  //         points: [startLatLng, endLatLng],
  //         color: Colors.blue,
  //         width: 5,
  //       ));
  //       _distance = Geolocator.distanceBetween(
  //               startLatLng.latitude,
  //               startLatLng.longitude,
  //               endLatLng.latitude,
  //               endLatLng.longitude) /
  //           1000; // in kilometers
  //     });

  //     _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
  //       LatLngBounds(
  //         southwest: LatLng(
  //           startLatLng.latitude < endLatLng.latitude
  //               ? startLatLng.latitude
  //               : endLatLng.latitude,
  //           startLatLng.longitude < endLatLng.longitude
  //               ? startLatLng.longitude
  //               : endLatLng.longitude,
  //         ),
  //         northeast: LatLng(
  //           startLatLng.latitude > endLatLng.latitude
  //               ? startLatLng.latitude
  //               : endLatLng.latitude,
  //           startLatLng.longitude > endLatLng.longitude
  //               ? startLatLng.longitude
  //               : endLatLng.longitude,
  //         ),
  //       ),
  //       50,
  //     ));
  //   } catch (e) {
  //     print('Error: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              height: size.height * 0.25,
              color: Colors.amber,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                child: Column(
                  children: [
                    MultiSelectDropDown<int>(
                      onOptionSelected: (List<ValueItem<int>> selectedOptions) {
                        setState(() {
                          if (selectedOptions.isNotEmpty) {
                            int? selectedValue = selectedOptions.first.value;
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
                      chipConfig: const ChipConfig(wrapType: WrapType.wrap),
                      dropdownHeight: 200,
                      optionTextStyle: const TextStyle(fontSize: 18),
                      selectedOptionIcon: const Icon(Icons.check_circle),
                      hint: 'Map type..',
                      hintColor: Colors.grey.shade900,
                      hintStyle: const TextStyle(fontSize: 18),
                      singleSelectItemStyle: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Google Maps Integration'),
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
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search location',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchAndNavigate,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _startController,
                  decoration: InputDecoration(
                    hintText: 'Start location',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _endController,
                  decoration: InputDecoration(
                    hintText: 'End location',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _drawPolyline,
                  child: const Text('Draw Route'),
                ),
                if (_distance > 0)
                  Text(
                    'Distance: ${_distance.toStringAsFixed(2)} km',
                    style: const TextStyle(fontSize: 16),
                  ),
              ],
            ),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentPosition ?? const LatLng(0, 0),
                zoom: 15,
              ),
            ),
          );
        },
        child: const Icon(Icons.my_location),
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
