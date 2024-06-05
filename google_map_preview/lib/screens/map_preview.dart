import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_preview/services/gps-service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:multi_dropdown/multiselect_dropdown.dart';

class MapPreview extends StatefulWidget {
  const MapPreview({super.key});

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  MapType mapType = MapType.normal;

  final MultiSelectController _controller = MultiSelectController();
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
          drawer: Drawer(
            child: Column(
              children: [
                Container(
                  height: size.height * 0.25,
                  color: Colors.amber,
                ),
                Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, top: 10),
                    child: Column(
                      children: [
                        MultiSelectDropDown<int>(
                          onOptionSelected: (List<ValueItem> selectedOptions) {
                            setState(() {
                              if (selectedOptions.isNotEmpty) {
                                int selectedValue = selectedOptions.first.value;
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
                          //fieldBackgroundColor: Colors.purple.shade50,
                          //borderColor: Colors.black,
                          //borderWidth: 2,
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
            backgroundColor: Colors.blue,
          ),
          body: Stack(
            children: [
              FutureBuilder(
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
                      mapType: mapType,
                      initialCameraPosition: CameraPosition(
                          target: LatLng(position.latitude, position.longitude),
                          zoom: 15),
                      markers: {
                        Marker(
                            markerId: const MarkerId('My Location'),
                            icon: BitmapDescriptor.defaultMarker,
                            infoWindow: const InfoWindow(title: 'My Location'),
                            position:
                                LatLng(position.latitude, position.longitude)),
                      });
                },
              ),
            ],
          )),
    );
  }
}