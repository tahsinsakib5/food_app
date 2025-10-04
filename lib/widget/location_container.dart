import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationDisplayContainer extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String apiKey;

  const LocationDisplayContainer({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.apiKey,
  });

  @override
  State<LocationDisplayContainer> createState() => _LocationDisplayContainerState();
}

class _LocationDisplayContainerState extends State<LocationDisplayContainer> {
  late GoogleMapController mapController;
  late LatLng currentPosition;

  @override
  void initState() {
    super.initState();
    currentPosition = LatLng(widget.latitude, widget.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Row(
        children: [
          // Map section
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: currentPosition,
                  zoom: 14.0,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('selected_location'),
                    position: currentPosition,
                    infoWindow: const InfoWindow(title: 'Selected Location'),
                  ),
                },
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                },
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),
          ),
          
          // Coordinates section
          // Expanded(
          //   flex: 2,
          //   child: Container(
          //     padding: const EdgeInsets.all(12),
          //     child: Column(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         const Text(
          //           'Selected Location',
          //           style: TextStyle(
          //             fontWeight: FontWeight.bold,
          //             fontSize:8,
          //           ),
          //         ),
          //         const SizedBox(height: 10),
          //         Row(
          //           children: [
          //             const Icon(Icons.language, size: 16, color: Colors.blue),
          //             const SizedBox(width: 5),
          //             Text(
          //               'Lat: ${widget.latitude.toStringAsFixed(6)}',
          //               style: const TextStyle(fontSize: 10),
          //             ),
          //           ],
          //         ),
          //         const SizedBox(height: 5),
          //         Row(
          //           children: [
          //             const Icon(Icons.language, size: 16, color: Colors.blue),
          //             const SizedBox(width: 5),
          //             Text(
          //               'Lng: ${widget.longitude.toStringAsFixed(6)}',
          //               style: const TextStyle(fontSize:5),
          //             ),
          //           ],
          //         ),
          //         const SizedBox(height: 10),
          //         ElevatedButton(
          //           onPressed: () {
          //             // You can add functionality to change the location
          //             // or open a larger map view
          //           },
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: Colors.blue,
          //             foregroundColor: Colors.white,
          //             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          //             textStyle: const TextStyle(fontSize: 12),
          //           ),
          //           child: const Text('Change Location'),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}

// Example usage in your RestaurantRegistrationPage
