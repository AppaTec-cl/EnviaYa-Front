import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  _ReportProblemScreenState createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final TextEditingController _trackingNumberController =
      TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  String? _selectedProblem;
  LocationData? _currentLocation;

  final List<String> _problems = [
    "Paquete dañado",
    "Dirección incorrecta",
    "Cliente ausente",
    "Retraso en la entrega",
    "Problemas de acceso",
    "Clima extremo",
    "Problemas con el vehículo",
    "Problemas técnicos",
  ];

  late GoogleMapController _mapController;
  LatLng? _currentLatLng;

  // Obtener la ubicación actual
  Future<void> _getCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _currentLocation = await location.getLocation();
    setState(() {
      _currentLatLng = LatLng(
        _currentLocation!.latitude!,
        _currentLocation!.longitude!,
      );
    });
  }

  // Enviar el reporte
  void _submitReport() {
    if (_trackingNumberController.text.trim().isEmpty || _selectedProblem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, completa todos los campos obligatorios."),
        ),
      );
      return;
    }

    // Aquí se enviará el reporte al servidor o a Firebase
    print("Número de seguimiento: ${_trackingNumberController.text}");
    print("Problema: $_selectedProblem");
    print("Comentarios: ${_commentsController.text}");
    print("Ubicación: ${_currentLocation?.latitude}, ${_currentLocation?.longitude}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reporte enviado con éxito."),
      ),
    );

    // Limpiar los campos después de enviar
    _trackingNumberController.clear();
    _commentsController.clear();
    setState(() {
      _selectedProblem = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Obtener la ubicación al iniciar la pantalla
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reportar Problema"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mostrar mapa si la ubicación está disponible
              if (_currentLatLng != null)
                SizedBox(
                  height: 300,
                  child: GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _currentLatLng!,
                      zoom: 15.0,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('currentLocation'),
                        position: _currentLatLng!,
                        infoWindow: const InfoWindow(title: "Ubicación actual"),
                      ),
                    },
                  ),
                )
              else
                const Center(child: CircularProgressIndicator()),

              const SizedBox(height: 20),

              // Número de seguimiento o RUT
              TextField(
                controller: _trackingNumberController,
                decoration: InputDecoration(
                  labelText: "Número de seguimiento o RUT del destinatario",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Selección del problema
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Selecciona el problema",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                value: _selectedProblem,
                items: _problems.map((problem) {
                  return DropdownMenuItem<String>(
                    value: problem,
                    child: Text(problem),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProblem = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Comentarios adicionales
              TextField(
                controller: _commentsController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Comentarios adicionales (opcional)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botón para enviar el reporte
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    backgroundColor: Colors.black,
                  ),
                  child: const Text(
                    "Enviar Reporte",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
