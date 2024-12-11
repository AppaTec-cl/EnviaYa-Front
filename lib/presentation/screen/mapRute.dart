import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:google_places_flutter/google_places_flutter.dart';

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  // Completer para gestionar el controlador de Google Maps de forma asíncrona
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  // Controlador de texto para capturar la búsqueda de direcciones
  final TextEditingController _searchController = TextEditingController();

  // Posición inicial del mapa
  static const LatLng _initialPosition =
      LatLng(-22.447249647343373, -68.92844046673834);

  // Posición actual y de destino
  LatLng _currentPosition = _initialPosition;
  LatLng? _destinationPosition;

  // Ubicación actual obtenida con el paquete 'location'
  LocationData? _currentLocation;

  // Conjuntos para marcadores y polilíneas (rutas) en el mapa
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  final String _apiKey = 'AIzaSyBUG45qeydoyjANTcG2Qnf0Ce6nOEXW6kw';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Obtener ubicación actual al inicializar el estado
  }

  // Obtener la ubicación actual del usuario
  Future<void> _getCurrentLocation() async {
    Location location = Location();

    // Solicitar permiso de ubicación y verificar si el servicio está habilitado
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled =
          await location.requestService(); // Solicitar habilitar el servicio
      if (!_serviceEnabled)
        return; // Salir si el usuario no habilita el servicio
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted =
          await location.requestPermission(); // Solicitar permisos
      if (_permissionGranted != PermissionStatus.granted) return;
    }

    // Obtener la ubicación actual
    _currentLocation = await location.getLocation();

    setState(() {
      // Actualizar posición actual y agregar marcador en el mapa
      _currentPosition =
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: _currentPosition,
          infoWindow: const InfoWindow(title: 'Mi ubicación'),
        ),
      );
    });

    // Mover la cámara a la ubicación actual
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _currentPosition, zoom: 14.0),
    ));
  }

  // Obtener y dibujar la ruta hacia el destino
  Future<void> _getDirections() async {
    if (_destinationPosition == null) return;

    // URL para obtener direcciones usando la API de Google Directions
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_currentPosition.latitude},${_currentPosition.longitude}&destination=${_destinationPosition!.latitude},${_destinationPosition!.longitude}&key=$_apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      // Verificar si existen rutas disponibles
      if (json['routes'].isEmpty) {
        _showError('No se encontraron rutas.');
        return;
      }

      // Decodificar los puntos de la ruta
      final points = json['routes'][0]['overview_polyline']['points'];
      final List<LatLng> polylinePoints = _decodePoly(points);

      setState(() {
        // Limpiar y agregar nueva ruta
        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: Colors.blue, // Color de la línea de ruta
          width: 5, // Grosor de la línea
        ));
      });

      // Ajustar la cámara para mostrar toda la ruta
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngBounds(
        _boundsFromLatLngList([_currentPosition, _destinationPosition!]),
        50, // Margen de la vista
      ));
    } else {
      _showError('Error al obtener la ruta.');
    }
  }

  // Decodificar polilínea de Google Directions
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

      // Agregar puntos decodificados
      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  // Calcular límites del mapa para ajustar la vista de cámara
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double x0 = list[0].latitude;
    double x1 = list[0].latitude;
    double y0 = list[0].longitude;
    double y1 = list[0].longitude;
    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }
    return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
  }

  // Mostrar un mensaje de error al usuario
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Método llamado cuando el usuario selecciona un lugar en las sugerencias
  void _onPlaceSelected(Prediction prediction) async {
    String placeId = prediction.placeId!;
    String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final location = json['result']['geometry']['location'];

      // Actualizar la posición de destino
      _destinationPosition = LatLng(location['lat'], location['lng']);

      setState(() {
        // Actualizar marcador del destino
        _markers
            .removeWhere((marker) => marker.markerId.value == 'destination');
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: _destinationPosition!,
            infoWindow: InfoWindow(title: prediction.description),
          ),
        );
      });

      // Obtener y dibujar la ruta
      _getDirections();
    } else {
      _showError('Error al obtener detalles del lugar.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa con Ruta'),
      ),
      body: Stack(
        children: [
          // Mapa de Google
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition:
                CameraPosition(target: _initialPosition, zoom: 14.0),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers, // Mostrar marcadores
            polylines: _polylines, // Mostrar rutas
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller); // Configurar controlador
            },
          ),
          // Campo de búsqueda de direcciones
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Container(
              color: Colors.white,
              child: GooglePlaceAutoCompleteTextField(
                textEditingController: _searchController,
                googleAPIKey: _apiKey, // Usar clave API
                inputDecoration: const InputDecoration(
                  hintText: 'Buscar dirección',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(left: 15, top: 15),
                ),
                debounceTime: 800, // Evitar múltiples llamadas rápidas
                countries: const ["cl"], // Restricción de países
                isLatLngRequired: true, // Requerir coordenadas
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  _onPlaceSelected(prediction); // Llamar al método de selección
                },
                itemClick: (Prediction prediction) {
                  _searchController.text = prediction.description!;
                  _onPlaceSelected(prediction); // Actualizar lugar seleccionado
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
