import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enviaya/services/email_service2.dart';
class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  _ReportProblemScreenState createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final TextEditingController _trackingNumberController =
      TextEditingController();
  final TextEditingController _rutController = TextEditingController();
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
  final EmailService _emailService = EmailService();

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

  // Validar si el número de seguimiento existe
  Future<Map<String, dynamic>?> _validateTrackingNumber() async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('tracking_number', isEqualTo: _trackingNumberController.text.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Error al validar el número de seguimiento: $e');
      return null;
    }
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
        _rutController.text.trim().isEmpty ||
        _selectedProblem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, completa todos los campos obligatorios.")),
      );
      return;
    }

    // Validar si el número de seguimiento existe
    final orderData = await _validateTrackingNumber();
    if (orderData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El número de seguimiento no existe.")),
      );
      return;
    }

    try {
      // Guardar el reporte en Firestore
      final String? imageBase64 = _encodeImageToBase64(_selectedImage);

      await _firestore.collection('problem_reports').add({
        'tracking_number': _trackingNumberController.text.trim(),
        'rut': _rutController.text.trim(),
        'problem': _selectedProblem,
        'comments': _commentsController.text.trim(),
        'image_base64': imageBase64,
        'location': _currentLatLng != null
            ? {
                'latitude': _currentLatLng!.latitude,
                'longitude': _currentLatLng!.longitude,
              }
            : null,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Enviar correo al cliente
      await _emailService.sendProblemReportEmail(
        recipientEmail: orderData['email'],
        recipientName: '${orderData['name']} ${orderData['surname']}',
        trackingNumber: _trackingNumberController.text.trim(),
        problemDescription: _selectedProblem!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reporte enviado con éxito.")),
      );

      // Limpiar los campos después de enviar
      _trackingNumberController.clear();
      _rutController.clear();
      _commentsController.clear();
      setState(() {
        _selectedProblem = null;
        _selectedImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al enviar el reporte: $e")),
      );
    }
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

              // Número de seguimiento
              TextField(
                controller: _trackingNumberController,
                decoration: InputDecoration(
                  labelText: "Número de seguimiento",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // RUT
              TextField(
                controller: _rutController,
                decoration: InputDecoration(
                  labelText: "RUT del destinatario",
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
