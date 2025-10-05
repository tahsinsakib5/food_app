import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class RiderTrackingPage extends StatefulWidget {
  final double riderLat;
  final double riderLng;
  final String restaurantName;
  final String orderNumber;

  const RiderTrackingPage({
    Key? key,
    required this.riderLat,
    required this.riderLng,
    required this.restaurantName,
    required this.orderNumber,
  }) : super(key: key);

  @override
  State<RiderTrackingPage> createState() => _RiderTrackingPageState();
}

class _RiderTrackingPageState extends State<RiderTrackingPage> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _userLocation;
  bool _isLoading = true;

  // Rider location (from your data)
  final LatLng _riderLocation = const LatLng(24.141970995333942, 90.6950284241064);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // Get user's current location
    await _getUserLocation();
    
    // Set up markers and polylines
    _setupMapMarkers();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getUserLocation() async {
    try {
      // Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print("Error getting location: $e");
      // Use a default location if unable to get current location
      _userLocation = const LatLng(24.1419, 90.6950);
    }
  }

  void _setupMapMarkers() {
    // Rider marker
    _markers.add(
      Marker(
        markerId: const MarkerId('rider'),
        position: _riderLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Your Rider',
          snippet: 'On the way to you',
        ),
      ),
    );

    // User marker (if location available)
    if (_userLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Delivery destination',
          ),
        ),
      );

      // Add polyline between rider and user
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          width: 4,
          points: [_riderLocation, _userLocation!],
        ),
      );
    }

    // Restaurant marker (optional - you can add if you have restaurant location)
    _markers.add(
      Marker(
        markerId: const MarkerId('restaurant'),
        position: const LatLng(24.1425, 90.6960), // Example restaurant location
        icon:  BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: widget.restaurantName,
          snippet: 'Pickup location',
                 
          
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;  
    
    // Fit map to show all markers
    if (_userLocation != null) {
      _fitMapToMarkers();
    }
  }

  void _fitMapToMarkers() {
    if (_mapController != null && _markers.isNotEmpty) {
      LatLngBounds bounds = _calculateBounds();
      _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    }
  }

  LatLngBounds _calculateBounds() {
    double minLat = _riderLocation.latitude;
    double maxLat = _riderLocation.latitude;
    double minLng = _riderLocation.longitude;
    double maxLng = _riderLocation.longitude;

    for (Marker marker in _markers) {
      double lat = marker.position.latitude;
      double lng = marker.position.longitude;
      
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Your Order'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Order Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[50],
                  child: Row(
                    children: [
                      const Icon(Icons.delivery_dining, color: Colors.orange, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${widget.orderNumber}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'From ${widget.restaurantName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rider is on the way',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                    ],
                  ),
                ),
                
                // Map
                Expanded(
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _riderLocation,
                      zoom: 14,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    mapType: MapType.normal,
                  ),
                ),
                
                // Rider Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Rider Avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Rider Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rider Name',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'ETA: 15-20 mins',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action Buttons
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            onPressed: () {
                              // Call rider functionality
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.message, color: Colors.blue),
                            onPressed: () {
                              // Message rider functionality
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

