import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final TextEditingController _trackingController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _orderData;

  // Método para buscar el envío por número de seguimiento
  Future<void> _fetchTrackingData() async {
    final trackingNumber = _trackingController.text.trim();

    if (trackingNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, ingresa el número de seguimiento.")),
      );
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('tracking_number', isEqualTo: trackingNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _orderData = querySnapshot.docs.first.data();
        });
      } else {
        setState(() {
          _orderData = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se encontró ningún envío con este número.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al buscar el envío: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seguimiento de Envíos"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _trackingController,
              decoration: InputDecoration(
                labelText: "Número de seguimiento",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _fetchTrackingData,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_orderData != null) ...[
              const Text(
                "Detalles del envío:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildOrderDetails(),
            ] else
              const Center(
                child: Text("Ingresa un número de seguimiento para ver los detalles."),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow("Número de Seguimiento", _orderData?['tracking_number'] ?? ''),
            _buildDetailRow("Estado", _orderData?['status'] ?? ''),
            _buildDetailRow("Nombre del Destinatario", "${_orderData?['name']} ${_orderData?['surname']}"),
            _buildDetailRow("Dirección", _orderData?['address'] ?? ''),
            _buildDetailRow("Comentarios", _orderData?['comments'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
