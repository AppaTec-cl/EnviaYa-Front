import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

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
  Set<Marker> _markers = {};
  final String _apiKey = 'AIzaSyBUG45qeydoyjANTcG2Qnf0Ce6nOEXW6kw';
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchAssignedOrders();
  }

  // Obtener ubicación actual del repartidor
  Future<void> _getCurrentLocation() async {
    Location location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) return;
    }

    _permissionGranted = await location.hasPermission();
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

  // Obtener pedidos asignados al repartidor desde Firestore
  Future<void> _fetchAssignedOrders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Usuario no autenticado")),
        );
        return;
      }

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('workerId', isEqualTo: user.uid)
          .where('assigned', isEqualTo: true)
          .get();

      final List<Map<String, dynamic>> orders = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      if (orders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No tienes pedidos asignados.")),
        );
        return;
      }

      for (var order in orders) {
        final LatLng? coordinates = await _getCoordinatesFromAddress(
          "${order['address']}, ${order['city']}",
        );

        if (coordinates != null) {
          setState(() {
            _markers.add(Marker(
              markerId: MarkerId(order['id']),
              position: coordinates,
              infoWindow: InfoWindow(
                title: "Pedido: ${order['tracking_number']}",
                snippet: "${order['address']}, ${order['city']}",
              ),
            ));
          });
        } else {
          print("No se encontraron coordenadas para: ${order['address']}, ${order['city']}");
        }
      }

      // Ajustar la cámara para mostrar todos los marcadores
      if (_markers.isNotEmpty) {
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngBounds(
          _boundsFromMarkers(_markers),
          50,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al obtener pedidos asignados: $e")),
      );
    }
  }

  // Convertir dirección en coordenadas usando la API de Google Geocoding
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

    return null; // Retorna null si no se encontraron coordenadas
  }

  // Calcular límites para ajustar la cámara
  LatLngBounds _boundsFromMarkers(Set<Marker> markers) {
    final List<LatLng> latLngList = markers.map((marker) => marker.position).toList();
    double x0 = latLngList[0].latitude;
    double x1 = latLngList[0].latitude;
    double y0 = latLngList[0].longitude;
    double y1 = latLngList[0].longitude;
    for (LatLng latLng in latLngList) {
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
        title: const Text('Mapa con Ruta'),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 14.0),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }
}
