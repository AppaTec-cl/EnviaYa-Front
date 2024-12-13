import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart_rut_validator.dart'; // Importa el validador de RUT
import 'package:enviaya/services/email_service.dart';

class AddPackageScreen extends StatefulWidget {
  const AddPackageScreen({super.key});

  @override
  _AddPackageScreenState createState() => _AddPackageScreenState();
}

class _AddPackageScreenState extends State<AddPackageScreen> {
  final TextEditingController _rutController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Instancia del validador de RUT
  final RUTValidator _rutValidator = RUTValidator();

  // Generar número de seguimiento único
  Future<String> _generateTrackingNumber() async {
    String trackingNumber;
    bool exists = true;

    final random = Random();

    do {
      trackingNumber = 'ENV-${random.nextInt(99999999).toString().padLeft(8, '0')}';
      final querySnapshot = await _firestore
          .collection('orders')
          .where('tracking_number', isEqualTo: trackingNumber)
          .get();
      exists = querySnapshot.docs.isNotEmpty;
    } while (exists);

    return trackingNumber;
  }

  // Método para agregar el paquete a Firestore
  Future<void> _addPackage() async {
    // Validar el RUT
    final rutError = _rutValidator.validator(_rutController.text.trim());
    if (rutError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rutError)),
      );
      return;
    }

    // Validar campos obligatorios
    if (_nameController.text.trim().isEmpty ||
        _surnameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _postalCodeController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, completa todos los campos obligatorios."),
        ),
      );
      return;
    }

    try {
      // Generar número de seguimiento único
      final trackingNumber = await _generateTrackingNumber();

    // Guardar datos en Firestore
    await _firestore.collection('orders').add({
      'tracking_number': trackingNumber,
      'rut': _rutController.text.trim(),
      'name': _nameController.text.trim(),
      'surname': _surnameController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'postal_code': _postalCodeController.text.trim(),
      'email': _emailController.text.trim(),
      'notes': _notesController.text.trim(),
      'status': 'Pendiente',
      'assigned': false, // Campo añadido
      'timestamp': FieldValue.serverTimestamp(),
    });


      // Enviar correo al cliente
      await sendTrackingEmail(
        recipientEmail: _emailController.text.trim(),
        recipientName: _nameController.text.trim(),
        trackingNumber: trackingNumber,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
      );


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Paquete agregado con éxito.")),
      );

      // Limpiar los campos después de agregar
      _rutController.clear();
      _nameController.clear();
      _surnameController.clear();
      _addressController.clear();
      _cityController.clear();
      _postalCodeController.clear();
      _emailController.clear();
      _notesController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al agregar el paquete: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agregar Paquete"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _rutController,
                onChanged: (value) {
                  RUTValidator.formatFromTextController(_rutController);
                },
                decoration: InputDecoration(
                  labelText: "RUT (con puntos y guión)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Nombre",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _surnameController,
                decoration: InputDecoration(
                  labelText: "Apellido",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: "Dirección",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: "Ciudad",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _postalCodeController,
                decoration: InputDecoration(
                  labelText: "Código Postal",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Correo Electrónico",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Notas adicionales (opcional)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addPackage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    backgroundColor: Colors.black,
                  ),
                  child: const Text(
                    "Agregar Paquete",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
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
