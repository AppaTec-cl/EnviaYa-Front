import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:signature/signature.dart';
import 'dart_rut_validator.dart'; // Importa el validador de RUT

class ConfirmDeliveryScreen extends StatefulWidget {
  const ConfirmDeliveryScreen({super.key});

  @override
  _ConfirmDeliveryScreenState createState() => _ConfirmDeliveryScreenState();
}

class _ConfirmDeliveryScreenState extends State<ConfirmDeliveryScreen> {
  final TextEditingController _trackingNumberController = TextEditingController();
  final TextEditingController _rutController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );

  // Instancia del validador de RUT
  final RUTValidator _rutValidator = RUTValidator();

  Future<void> _confirmDelivery() async {
    final String trackingNumber = _trackingNumberController.text.trim();
    final String rut = _rutController.text.trim();

    // Validar campos
    if (trackingNumber.isEmpty || rut.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, completa todos los campos obligatorios.")),
      );
      return;
    }

    // Validar RUT
    final String? rutError = _rutValidator.validator(rut);
    if (rutError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rutError)),
      );
      return;
    }

    try {
      // Verificar número de seguimiento
      final querySnapshot = await _firestore
          .collection('orders')
          .where('tracking_number', isEqualTo: trackingNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se encontró el pedido con el número de seguimiento proporcionado.")),
        );
        return;
      }

      final orderId = querySnapshot.docs.first.id;

      // Obtener la imagen de la firma
      final signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes == null || signatureBytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor, obtén la firma del cliente.")),
        );
        return;
      }

      // Actualizar el pedido en Firestore
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'Entregado',
        'signature': signatureBytes, // Guardar la firma como bytes
        'client_rut': rut, // Guardar el RUT del cliente
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entrega confirmada con éxito.")),
      );

      // Limpiar los campos después de confirmar
      _trackingNumberController.clear();
      _rutController.clear();
      _signatureController.clear();
    } catch (e) {
      print('Error al confirmar entrega: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al confirmar la entrega: $e')),
      );
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmar Entrega"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo para número de seguimiento
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

              // Campo para RUT del cliente
              TextField(
                controller: _rutController,
                onChanged: (value) {
                  RUTValidator.formatFromTextController(_rutController);
                },
                decoration: InputDecoration(
                  labelText: "RUT del Cliente (con puntos y guión)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Canvas para la firma
              const Text(
                "Firma del Cliente:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                height: 200,
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _signatureController.clear(),
                    child: const Text("Limpiar Firma"),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Botón para confirmar la entrega
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmDelivery,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    backgroundColor: Colors.black,
                  ),
                  child: const Text(
                    "Confirmar Entrega",
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
