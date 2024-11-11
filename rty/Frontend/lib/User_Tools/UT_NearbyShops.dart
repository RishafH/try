import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tap_on/Home%20page.dart';
import 'package:tap_on/User_Tools/UT_ToolMenu.dart';
import 'package:http/http.dart' as http;
import 'package:tap_on/services/geo_services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;

class UT_NearbyShops extends StatefulWidget {
  final String userLocation;
  final String tool;
  const UT_NearbyShops({super.key, 
    required this.userLocation,
    required this.tool,
  });

  @override
  State<UT_NearbyShops> createState() => _UT_NearbyShopsState();
}

class _UT_NearbyShopsState extends State<UT_NearbyShops> {
  double _latitude = 6.9271;
  double _longitude = 79.8612;
  late GoogleMapController mapController;
  final Set<google_maps.Marker> _markers = {};

  final List<Map<String, dynamic>> serviceProviders = [
    // {
    //   'id': '6710fa1daf3e9327c922ca0d',
    //   'name': 'Icom hardware',
    //   'address': 'ViharaMahathevi Park Road,Town Hall , Colombo',
    //   'rating': 4.5,
    //   'Shipping': 'Free Shipping ',
    //   'image': 'assets/images/muhammed.jpeg',
    // },
    // {
    //   'id': '6710fa1daf3e9327c922ca0d',
    //   'name': 'Salman Store',
    //   'address': 'No.19,Old Boc Lane Kinniya-04',
    //   'rating': 2.9,
    //   'Shipping': 'Free Shipping ',
    //   'image': 'assets/images/salman.jpeg',
    // },
    // {
    //   'id': '6710fa1daf3e9327c922ca0d',
    //   'name': 'Guy Hawkins',
    //   'address': 'Diyagama,Homagama,colombo-5.',
    //   'rating': 4.0,
    //   'Shipping': 'Free Shipping ',
    //   'image': 'assets/images/sarukan.jpeg',
    // },
  ];

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  void _initAsync() async {
    await getAllTools();
  }

  Future<void> getAllTools() async {
    try {
      final baseURL = dotenv.env['BASE_URL']; // Get the base URL

      final coordinates = await getCoordinatesFromCity(widget.userLocation).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Location service timeout'),
      );

      setState(() {
        _latitude = coordinates['latitude'] ?? 6.9271;
        _longitude = coordinates['longitude'] ?? 79.8612;
      });

      final bodyData = {
        'category': widget.tool,
        'location_long': coordinates['longitude'],
        'location_lat': coordinates['latitude'],
      };

      final response = await http.post(
        Uri.parse('$baseURL/shop/get/all/category/location'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyData),
      );

      final data = jsonDecode(response.body);
      final status = data['status'];

      debugPrint(data.toString());

      if (status == 200) {
        final services = data['data'];
        if (services.length > 0) {
          List<Map<String, dynamic>> providers = [];
          Set<google_maps.Marker> providerMarkers = {};
          
          for (var service in services) {
            providers.add({
              'id': service['_id'] ?? 'N/A',
              'shop_name': service['shop_name'] ?? 'N/A',
              'name': service['name'] ?? 'N/A',
              'address': service['address'] ?? 'N/A',
              'rating': service['rating'] ?? 0.0,
              'category': service['category'] ?? 'N/A',
              'image': service['pic'] ?? '',
              'email': service['email'] ?? 'N/A',
              'phone': service['phone'] ?? 'N/A',
              'location_lat': service['location_lat'],
              'location_long': service['location_long'],
            });

            if (service['location_lat'] != null && service['location_long'] != null) {
              providerMarkers.add(
                google_maps.Marker(
                  markerId: google_maps.MarkerId(service['shop_name'] ?? 'N/A'),
                  position: google_maps.LatLng(service['location_lat'], service['location_long']),
                  infoWindow: google_maps.InfoWindow(title: service['shop_name'] ?? 'N/A'),
                ),
              );
            }
          }
          
          setState(() {
            serviceProviders.clear();
            serviceProviders.addAll(providers);
            _markers.clear();
            _markers.addAll(providerMarkers);
          });
        }
      }
    } catch (e) {
      print(e);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Oops...',
        text: 'Failed to fetch nearby shops. Please try again.',
        backgroundColor: Colors.black,
        titleColor: Colors.white,
        textColor: Colors.white,
      );
    }
  }

  double _calculateDistance(double? lat1, double? lon1) {
    if (lat1 == null || lon1 == null) {
      return 0.0; // Return default distance if coordinates are null
    }
    
    const double R = 6371; // Earth's radius in kilometers
    
    double dLat = _toRadians(_latitude - lat1);
    double dLon = _toRadians(_longitude - lon1);
    
    double a = sin(dLat/2) * sin(dLat/2) +
        cos(_toRadians(lat1)) * cos(_toRadians(_latitude)) * 
        sin(dLon/2) * sin(dLon/2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1-a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Applying a Gradient Background
      body: Container(
        decoration: BoxDecoration(
                   gradient: LinearGradient(
            colors: [Color.fromARGB(255, 47, 221, 105), Color.fromARGB(255, 17, 202, 79), Color.fromARGB(255, 45, 251, 114), const Color.fromARGB(255, 45, 251, 182)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        
        child: Column(
          
          children: [
            // AppBar with Custom Styling
            SafeArea(
             
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16.0, horizontal: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon:
                          Icon(Icons.arrow_back, color: Colors.black, size: 30),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomePage()));
                      },
                    ),
                    const Text(
                      'Nearby Shops',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        
                      ),
                    ),
                    SizedBox(width: 30),
                    // Placeholder to balance the title alignment
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),

            //Map Placeholder with Glassmorphism Effect
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
            //           _latitude, _longitude), // Starting position
            //       initialZoom: 13.0,
            //       onTap: (tapPosition, point) {
            //         //_addMarker(point);
            //       },
            //     ),
            //     children: [
            //       TileLayer(
            //         urlTemplate:
            //             "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            //       ),
            //       //MarkerLayer(markers: _markers),
            //       flutter_map_lib.MarkerLayer(markers: _markers),
            //     ],
            //   ),
            // ),

            Container(
              height: 250,
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
                border:
                    Border.all(color: Colors.white.withOpacity(0.4), width: 1),
              ),
              child: Expanded(
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
            ),
            SizedBox(height: 20),

            // List of Service Providers with Enhanced Design
            Expanded(
              child: ListView.builder(
                itemCount: serviceProviders.length,
                itemBuilder: (context, index) {
                  final provider = serviceProviders[index];

                  return GestureDetector(
                    child: Card(
                      elevation: 10,
                      margin:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.grey[200]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        provider['shop_name'] ?? 'Shop Name',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Owner: ${provider['name'] ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    provider['category'] ?? 'N/A',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.red[400], size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    provider['address'] ?? 'Address not available',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.phone, color: Colors.blue[400], size: 20),
                                SizedBox(width: 8),
                                Text(
                                  provider['phone'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Distance: ${_calculateDistance(
                                    provider['location_lat']?.toDouble(),
                                    provider['location_long']?.toDouble(),
                                  ).toStringAsFixed(2)} km',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UT_ToolMenu(
                                          shopName: provider['shop_name'] ?? 'N/A',
                                          shopId: provider['id'] ?? 'N/A', 
                                          shopEmail: provider['email'] ?? 'N/A',
                                          shopPhone: provider['phone'] ?? 'N/A',
                                          product: 'YourProduct', // Add the required product argument
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[700],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'View Product',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
