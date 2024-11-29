import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  File? _selectedImage;
  LatLng? _currentLatLng;

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Capturar o seleccionar una foto
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Codificar imagen a Base64
  String? _encodeImageToBase64(File? image) {
    if (image == null) return null;
    final bytes = image.readAsBytesSync();
    return base64Encode(bytes);
  }

  // Enviar el reporte a Firestore
  Future<void> _submitReport() async {
    if (_trackingNumberController.text.trim().isEmpty ||
        _selectedProblem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, completa todos los campos obligatorios."),
        ),
      );
      return;
    }

    final String? imageBase64 = _encodeImageToBase64(_selectedImage);

    await _firestore.collection('problem_reports').add({
      'tracking_number': _trackingNumberController.text.trim(),
      'problem': _selectedProblem,
      'comments': _commentsController.text.trim(),
      'location': {
        'latitude': _currentLocation?.latitude,
        'longitude': _currentLocation?.longitude,
      },
      'image_base64': imageBase64, // Imagen codificada en Base64
      'timestamp': FieldValue.serverTimestamp(),
    });

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
      _selectedImage = null;
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

              // Selección de foto
              Wrap(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Tomar Foto"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: const Text("Seleccionar de Galería"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_selectedImage != null)
                Image.file(
                  _selectedImage!,
                  height: 150,
                  fit: BoxFit.cover,
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
