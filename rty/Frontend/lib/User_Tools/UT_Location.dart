import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:tap_on/Home%20page.dart';
import 'package:tap_on/User_Tools/UT_NearbyShops.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:tap_on/services/location_services.dart';

class UT_Location extends StatefulWidget {
  final String tool;
  const UT_Location({super.key, required this.tool});

  @override
  _UT_LocationState createState() => _UT_LocationState();
}

class _UT_LocationState extends State<UT_Location> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _typeAheadController = TextEditingController();
  bool _isLoadingLocation = false;
  String _currentAddress = "";
  LatLng? currentPosition;
  double? _latitude;
  double? _longitude;
  late GoogleMapController mapController;
  String _selectedCity = '';

  final Set<google_maps.Marker> _markers = {};

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _currentAddress = 'Location services are disabled.';
        _isLoadingLocation = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _currentAddress = 'Location permissions are denied';
          _isLoadingLocation = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _currentAddress = 'Location permissions are permanently denied';
        _isLoadingLocation = false;
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    Placemark place = placemarks[0];

    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _currentAddress =
          "${place.locality}, ${place.postalCode}, ${place.country}";
      _locationController.text = place.locality ?? '';
      _isLoadingLocation = false;
      _markers.add(google_maps.Marker(
        markerId: google_maps.MarkerId('My Location'),
        position: google_maps.LatLng(
            _latitude ?? 6.9388614, _longitude ?? 79.8542005), // San Francisco
        infoWindow: google_maps.InfoWindow(title: 'My Location'),
      ));
    });
  }

  void _goToCurrentLocation() async {
    final loc.Location location = loc.Location();
    final currentLocation = await location.getLocation();
    if (currentLocation.latitude != null && currentLocation.longitude != null) {
      setState(() {
        currentPosition = LatLng(
          currentLocation.latitude ?? 0.0,
          currentLocation.longitude ?? 0.0,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
            // Action when the button is pressed
          },
        ),
        title: Text('Set Delivery Location'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TypeAheadField(
                suggestionsCallback: (pattern) async {
                  if (pattern.isEmpty) {
                    return [];
                  }
                  return await LocationService.fetchLocationSuggestions(
                      pattern);
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion),
                  );
                },
                onSelected: (suggestion) {
                  _typeAheadController.text = suggestion;
                  setState(() {
                    _selectedCity = suggestion;
                  });
                },
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      icon: const Icon(Icons.location_on, color: Colors.black),
                      label: const Text('Select Nearest City',
                          style: TextStyle(color: Colors.black)),
                      filled: true,
                      helperStyle: const TextStyle(color: Colors.blue),
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide:
                            const BorderSide(color: Colors.black, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 1),
                      ),
                    ),
                    style: const TextStyle(color: Colors.black),
                  );
                },
              ),
            // Input field for location search
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Enter a location',
                suffixIcon: Icon(Icons.save),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),

            // Button to use current location
            Center(
              child: ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: Icon(Icons.my_location),
                label: Text('Use My Current Location'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white
                ),
              ),
            ),
            SizedBox(height: 16.0),

            // Display current address and coordinates or loading spinner
            _isLoadingLocation
                ? Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_currentAddress.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Current Address: $_currentAddress',
                            style: TextStyle(fontSize: 16.0),
                          ),
                        ),
                      if (_latitude != null && _longitude != null)
                        Text(
                          'Latitude: $_latitude, Longitude: $_longitude',
                          style: TextStyle(fontSize: 16.0),
                        ),
                      if (_latitude == null && _longitude == null)
                        Text(
                          'No location selected',
                          style: TextStyle(fontSize: 16.0),
                        ),
                    ],
                  ),
            SizedBox(height: 16.0),

            // Container(
            //   height: 250,
            //   margin: EdgeInsets.symmetric(horizontal: 20),
            //   decoration: BoxDecoration(
            //     color: Colors.white.withOpacity(0.2),
            //     borderRadius: BorderRadius.circular(20),
            //     boxShadow: const [
            //       BoxShadow(
            //         color: Colors.black26,
            //         blurRadius: 10,
            //         offset: Offset(0, 5),
            //       )
            //     ],
            //     border:
            //         Border.all(color: Colors.white.withOpacity(0.4), width: 1),
            //   ),
            //   child: FlutterMap(
            //     options: MapOptions(
            //       initialCenter: latlong.LatLng(
            //         _latitude ?? 6.9388614,
            //         _longitude ?? 79.8542005,
            //       ), // Starting position
            //       initialZoom: _latitude != null ? 13.0 : 7.0,
            //       onTap: (tapPosition, point) {
            //         //_addMarker(point);
            //       },
            //     ),
            //     children: [
            //       TileLayer(
            //         urlTemplate:
            //             "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            //       ),
            //     ],
            //   ),
            // ),

            // Google Maps widget with proper spacing
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                          _latitude ?? 6.9388614, _longitude ?? 79.8542005),
                      zoom: 13,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    markers: _markers,
                  ),

                  // FloatingActionButton positioned on the map
                  // Positioned(
                  //   bottom: 10,
                  //   right: 10,
                  //   child: FloatingActionButton(
                  //     onPressed: _goToCurrentLocation,
                  //     backgroundColor: Colors.grey,
                  //     child: Icon(Icons.add_location_alt),
                  //   ),
                  // ),
                ],
              ),
            ),
            SizedBox(height: 30.0),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_locationController.text.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UT_NearbyShops(
                              userLocation: _locationController.text,
                              tool: widget.tool)),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please select a location first.'),
                      ),
                    );
                  }
                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => UT_NearbyShops()));
                },
                icon: Icon(Icons.search),
                label: Text('Find Shops Near Me ',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                  backgroundColor: Colors.green[600]!,
                  foregroundColor: Colors.white
                ),
              ),
            ),

            // Find Tool button centered below the map
            SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}
