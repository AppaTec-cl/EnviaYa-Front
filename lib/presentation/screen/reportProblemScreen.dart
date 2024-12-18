import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enviaya/services/email_service2.dart';
import 'dart_rut_validator.dart'; // Importa el validador de RUT

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
  final TextEditingController _additionalCommentsController =
      TextEditingController(); // Campo adicional para comentarios

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

  // Instancia del validador de RUT
  final RUTValidator _rutValidator = RUTValidator();

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
          .where('tracking_number',
              isEqualTo: _trackingNumberController.text.trim())
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
    final rut = _rutController.text.trim();
    final trackingNumber = _trackingNumberController.text.trim();

    // Validar campos obligatorios
    if (trackingNumber.isEmpty || rut.isEmpty || _selectedProblem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Por favor, completa todos los campos obligatorios.")),
      );
      return;
    }

    // Validar el RUT
    final String? rutError = _rutValidator.validator(rut);
    if (rutError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rutError)),
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
        'tracking_number': trackingNumber,
        'rut': rut,
        'problem': _selectedProblem,
        'comments': _commentsController.text.trim(),
        'additional_comments': _additionalCommentsController.text
            .trim(), // Guardar comentarios adicionales
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
        trackingNumber: trackingNumber,
        problemDescription: _selectedProblem!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reporte enviado con éxito.")),
      );

      // Limpiar los campos después de enviar
      _trackingNumberController.clear();
      _rutController.clear();
      _commentsController.clear();
      _additionalCommentsController.clear(); // Limpiar campo adicional
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
              TextField(
                controller: _rutController,
                onChanged: (value) {
                  RUTValidator.formatFromTextController(_rutController);
                },
                decoration: InputDecoration(
                  labelText: "RUT del destinatario",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
              TextField(
                controller: _additionalCommentsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Comentarios adicionales (opcional)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitReport,
                child: const Text("Enviar Reporte"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
