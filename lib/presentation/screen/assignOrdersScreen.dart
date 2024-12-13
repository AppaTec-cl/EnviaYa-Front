import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignOrdersScreen extends StatefulWidget {
  const AssignOrdersScreen({super.key});

  @override
  _AssignOrdersScreenState createState() => _AssignOrdersScreenState();
}

class _AssignOrdersScreenState extends State<AssignOrdersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedWorker;
  List<String> _selectedOrders = [];
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _workers = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _fetchWorkers();
  }

  // Obtener pedidos desde Firestore
  Future<void> _fetchOrders() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('assigned', isEqualTo: false)
          .get();

      setState(() {
        _orders = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar pedidos: $e")),
      );
    }
  }

  // Obtener trabajadores desde Firestore
  Future<void> _fetchWorkers() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Repartidor')
          .get();

      setState(() {
        _workers = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar trabajadores: $e")),
      );
    }
  }

  // Asignar pedidos al trabajador seleccionado
  Future<void> _assignOrders() async {
    if (_selectedWorker == null || _selectedOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, selecciona un trabajador y al menos un pedido."),
        ),
      );
      return;
    }

    try {
      for (String orderId in _selectedOrders) {
        await _firestore.collection('orders').doc(orderId).update({
          'assigned': true,
          'workerId': _selectedWorker,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pedidos asignados con éxito.")));

      // Limpiar selección
      setState(() {
        _selectedOrders = [];
        _selectedWorker = null;
      });

      // Recargar datos
      _fetchOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al asignar pedidos: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Asignar Pedidos"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selección de trabajador
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Selecciona un trabajador",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              value: _selectedWorker,
              items: _workers.map((worker) {
                return DropdownMenuItem<String>(
                  value: worker['id'],
                  child: Text("${worker['name']} ${worker['surname']}"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedWorker = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Lista de pedidos
            const Text(
              "Selecciona los pedidos:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: _orders.isEmpty
                  ? const Center(
                      child: Text("No hay pedidos disponibles."),
                    )
                  : ListView.builder(
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return Card(
                          elevation: 4,
                          child: CheckboxListTile(
                            title: Text("Pedido: ${order['tracking_number']}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Cliente: ${order['name']} ${order['surname']}"),
                                Text("Dirección: ${order['address']}"),
                              ],
                            ),
                            value: _selectedOrders.contains(order['id']),
                            onChanged: (bool? selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedOrders.add(order['id']);
                                } else {
                                  _selectedOrders.remove(order['id']);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),

            // Botón para asignar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _assignOrders,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  backgroundColor: Colors.black,
                ),
                child: const Text(
                  "Asignar Pedidos",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
