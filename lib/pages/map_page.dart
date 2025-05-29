import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  LocationData? _currentLocation;
  final Set<Marker> _markers = {};

  final LatLng _mangilikElCoords = const LatLng(51.090947, 71.418867);

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _checkTasksAndAddMarker();
  }

  Future<void> _getUserLocation() async {
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
    }

    if (permissionGranted == PermissionStatus.granted) {
      final loc = await location.getLocation();
      setState(() {
        _currentLocation = loc;
        _markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: LatLng(loc.latitude!, loc.longitude!),
            infoWindow: const InfoWindow(title: "You are here"),
          ),
        );
      });
    }
  }

  Future<void> _checkTasksAndAddMarker() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('todos')
        .where('userId', isEqualTo: user.uid)
        .where('location', isEqualTo: 'Mangilik El C1')
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('mangilik_el'),
            position: _mangilikElCoords,
            infoWindow: const InfoWindow(title: "Pass endterm"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map")),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        onMapCreated: (controller) => _mapController = controller,
        initialCameraPosition: CameraPosition(
          target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          zoom: 14,
        ),
        markers: _markers,
      ),
    );
  }
}
