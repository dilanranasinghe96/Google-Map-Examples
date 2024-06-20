import 'dart:convert';

import 'package:fab_circular_menu_plus/fab_circular_menu_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_preview/controllers/auth_controlller.dart';
import 'package:google_map_preview/custom%20widgets/custom_text.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:multi_dropdown/multiselect_dropdown.dart';
import 'package:share/share.dart';

import 'directions_page.dart';
import 'search_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.user});

  final User user;
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
  String apiKey = 'API_KEY_MAP';
  double _distance = 0.0;
  bool _isDistanceVisible =
      false; // New variable to control distance label visibility
  MapType mapType = MapType.normal;
  User? user;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUserProfile();
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isDistanceVisible = false;
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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
              _polylines.clear(); // Clear all polylines
              _isDistanceVisible = false; // Hide distance label when searching
              for (var result in data['results']) {
                final lat = result['geometry']['location']['lat'];
                final lng = result['geometry']['location']['lng'];
                final name = result['name'];
                final address = result['formatted_address'];
                _markers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed),
                    markerId: MarkerId(name),
                    position: LatLng(lat, lng),
                    infoWindow: InfoWindow(title: name, snippet: address),
                  ),
                );
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

  void _loadUserProfile() {
    user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: Colors.amber.shade300),
                  accountName: CustomText(
                      text: user?.displayName ?? 'User Name',
                      color: Colors.black,
                      fsize: 16,
                      fweight: FontWeight.w500),
                  accountEmail: CustomText(
                      text: user?.email ?? 'User Email',
                      color: Colors.black,
                      fsize: 16,
                      fweight: FontWeight.w500),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: NetworkImage(user?.photoURL ?? ''),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                            selectedOptionIcon: const Icon(Icons.check_circle),
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
                          ListTile(
                            title: const Text('Sign out'),
                            leading: const Icon(Icons.logout),
                            onTap: () {
                              AuthController.signOutUser(context);
                              // Navigator.pop(context); // Close the drawer
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
        title: CustomText(
            text: 'Google Map',
            color: Colors.black,
            fsize: 25,
            fweight: FontWeight.bold),
        backgroundColor: Colors.amber.shade300,
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
          if (_isDistanceVisible) // Check if distance is visible
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.white,
                child: Text(
                  'Distance: ${_distance.toStringAsFixed(2)} km',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FabCircularMenuPlus(
          alignment: Alignment.bottomLeft,
          fabColor: Colors.amber.shade300,
          fabOpenColor: Colors.amber.shade100,
          ringDiameter: 250.0,
          ringWidth: 60.0,
          ringColor: Colors.amber.shade300,
          fabSize: 60.0,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isDistanceVisible = false;
                });

                _markers.add(
                  Marker(
                    markerId: const MarkerId('Current Location'),
                    position: _currentPosition ?? const LatLng(0, 0),
                    infoWindow: const InfoWindow(title: 'Current Location'),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed),
                  ),
                );
                _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: _currentPosition ?? const LatLng(0, 0),
                      zoom: 15,
                    ),
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
    );
  }
}
