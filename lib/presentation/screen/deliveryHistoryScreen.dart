import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  String? _workerId;
  List<Map<String, dynamic>> _deliveryHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchWorkerId(); // Obtener workerId al cargar la pantalla
  }

  // Obtener el workerId desde Firebase Authentication y Firestore
  Future<void> _fetchWorkerId() async {
    try {
      // Obtener el usuario autenticado
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Verificar si el usuario existe en la colección 'users'
        final DocumentSnapshot workerSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (workerSnapshot.exists) {
          setState(() {
            _workerId = user.uid; // Asignar el workerId desde el usuario autenticado
          });

          // Después de obtener el workerId, cargar el historial de entregas
          _fetchDeliveryHistory();
        } else {
          throw Exception('El usuario no existe en la base de datos.');
        }
      } else {
        throw Exception('No hay un usuario autenticado.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener el ID del trabajador: $e')),
      );
    }
  }

  // Obtener el historial de entregas desde Firestore
  Future<void> _fetchDeliveryHistory() async {
    if (_workerId == null) return;

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('workerId', isEqualTo: _workerId)
          .where('status', isEqualTo: 'Entregado')
          .get();

      setState(() {
        _deliveryHistory = snapshot.docs.map((doc) {
          return {
            'tracking_number': doc['tracking_number'],
            'address': doc['address'],
            'city': doc['city'],
            'timestamp': doc['timestamp'],
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el historial: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Entregas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _workerId == null
            ? const Center(child: CircularProgressIndicator())
            : _deliveryHistory.isEmpty
                ? const Center(
                    child: Text('No se encontraron entregas en tu historial.'),
                  )
                : ListView.builder(
                    itemCount: _deliveryHistory.length,
                    itemBuilder: (context, index) {
                      final delivery = _deliveryHistory[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.local_shipping),
                          title: Text(
                              'Pedido: ${delivery['tracking_number']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Dirección: ${delivery['address']}, ${delivery['city']}'),
                              Text(
                                  'Fecha: ${(delivery['timestamp'] as Timestamp).toDate()}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
