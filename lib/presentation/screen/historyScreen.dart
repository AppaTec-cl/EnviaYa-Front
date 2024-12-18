import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _userEmail; // Correo del usuario autenticado
  List<Map<String, dynamic>> _orders = []; // Lista de pedidos del usuario
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  // Obtener pedidos desde Firestore usando el correo electrónico
  Future<void> _fetchOrders() async {
    try {
      // Obtener el correo electrónico del usuario autenticado
      final User? user = _auth.currentUser;
      if (user == null) {
        _showMessage("Usuario no autenticado.");
        return;
      }
      setState(() {
        _userEmail = user.email;
      });

      // Consultar Firestore para obtener los pedidos relacionados con el email
      final QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('email', isEqualTo: _userEmail) // Filtrar por el email
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _orders = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      _showMessage("Error al obtener el historial de pedidos: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Mostrar mensaje en SnackBar
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Pedidos"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Cargando...
          : _orders.isEmpty
              ? const Center(child: Text("No tienes pedidos registrados."))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
                      child: ListTile(
                        leading: const Icon(Icons.local_shipping),
                        title: Text(
                            "Pedido: ${order['tracking_number'] ?? 'Sin número'}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Estado: ${order['status'] ?? 'Desconocido'}"),
                            Text("Dirección: ${order['address'] ?? 'No disponible'}"),
                            Text("Ciudad: ${order['city'] ?? 'No disponible'}"),
                            Text("Fecha: ${_formatDate(order['timestamp'])}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  // Formatear la fecha para mostrarla en pantalla
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Fecha no disponible";
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute}";
  }
}
