import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  static const LatLng _initialPosition = LatLng(-22.447249647343373, -68.92844046673834);
  LatLng _currentPosition = _initialPosition;

  LocationData? _currentLocation;
  final String _apiKey = 'AIzaSyBUG45qeydoyjANTcG2Qnf0Ce6nOEXW6kw';

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  List<LatLng> _deliveryPoints = [];
  String? _workerId;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchWorkerIdAndOrders(); // Obtener workerId y pedidos asignados
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) return;
    }

    PermissionStatus _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return;
    }

    _currentLocation = await location.getLocation();
    setState(() {
      _currentPosition = LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
      _markers.add(Marker(
        markerId: const MarkerId('currentLocation'),
        position: _currentPosition,
        infoWindow: const InfoWindow(title: 'Mi ubicación'),
      ));
    });

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _currentPosition, zoom: 14.0),
    ));
  }

  Future<void> _fetchWorkerIdAndOrders() async {
    try {
      // Obtener el ID del usuario autenticado
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("No se encontró un usuario autenticado.");
      }

      // Consultar el documento del usuario en Firestore
      final DocumentSnapshot workerSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!workerSnapshot.exists) {
        throw Exception("No se encontró información del usuario en la base de datos.");
      }

      setState(() {
        _workerId = workerSnapshot.id; // Asignar el workerId desde Firestore
      });

      // Obtener los pedidos asignados al workerId
      await _fetchAssignedOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al obtener workerId: $e")),
      );
    }
  }

  Future<void> _fetchAssignedOrders() async {
    if (_workerId == null) return;

    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('workerId', isEqualTo: _workerId)
        .where('assigned', isEqualTo: true)
        .get();

    for (var doc in snapshot.docs) {
      String address = "${doc['address']}, ${doc['city']}";
      LatLng? coordinates = await _getCoordinatesFromAddress(address);
      if (coordinates != null) {
        setState(() {
          _deliveryPoints.add(coordinates);
          _markers.add(Marker(
            markerId: MarkerId(doc.id),
            position: coordinates,
            infoWindow: InfoWindow(title: "Pedido: ${doc.id}"),
          ));
        });
      }
    }

    if (_deliveryPoints.isNotEmpty) {
      _drawRoute();
    }
  }

  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['results'].isNotEmpty) {
        final location = json['results'][0]['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
    }
    return null;
  }

  Future<void> _drawRoute() async {
    if (_deliveryPoints.length < 2) return;

    String waypoints = _deliveryPoints
        .sublist(1, _deliveryPoints.length - 1)
        .map((point) => "${point.latitude},${point.longitude}")
        .join('|');

    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_currentPosition.latitude},${_currentPosition.longitude}&destination=${_deliveryPoints.last.latitude},${_deliveryPoints.last.longitude}&waypoints=$waypoints&optimizeWaypoints=true&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['routes'].isNotEmpty) {
        final points = json['routes'][0]['overview_polyline']['points'];
        final List<LatLng> polylinePoints = _decodePoly(points);

        setState(() {
          _polylines.add(Polyline(
            polylineId: const PolylineId('route'),
            points: polylinePoints,
            color: Colors.blue,
            width: 5,
          ));
        });

        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngBounds(
          _boundsFromLatLngList([_currentPosition, ..._deliveryPoints]),
          50,
        ));
      }
    }
  }

  List<LatLng> _decodePoly(String poly) {
    List<LatLng> polyline = [];
    int index = 0, len = poly.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;

      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double x0 = list[0].latitude, x1 = list[0].latitude;
    double y0 = list[0].longitude, y1 = list[0].longitude;
    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }
    return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas Asignadas'),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 14.0),
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }
}
