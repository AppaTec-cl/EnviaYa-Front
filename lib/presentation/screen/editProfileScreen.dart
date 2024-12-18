import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rutController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Cargar los datos del usuario desde Firestore
  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final docSnapshot =
          await _firestore.collection('clients').doc(user.uid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;

        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _addressController.text = data['address'] ?? '';
        _cityController.text = data['city'] ?? '';
        _postalCodeController.text = data['postal_code'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _rutController.text = data['rut'] ?? ''; // Cargar RUT pero no editable
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar datos: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

    // Actualizar datos del usuario
Future<void> _updateUserData() async {
  final user = _auth.currentUser;

  if (user == null) return;

  // Validar campos requeridos
  if (_nameController.text.trim().isEmpty ||
      _emailController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Por favor, completa todos los campos.")),
    );
    return;
  }

  try {
    // Verificar si el correo electrónico ha cambiado
    if (_emailController.text.trim() != user.email) {
      await user.verifyBeforeUpdateEmail(_emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Se envió un correo de verificación. Verifica antes de continuar.")),
      );
    }

    // Actualizar datos en Firestore (sin modificar el RUT)
    await _firestore.collection('clients').doc(user.uid).update({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'postal_code': _postalCodeController.text.trim(),
      'phone': _phoneController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Datos actualizados con éxito.")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error al actualizar los datos: $e")),
    );
  }
}


  // Widget para los campos de texto
  Widget _buildTextField(String label, TextEditingController controller,
      {bool readOnly = false}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField("Nombre", _nameController),
                  const SizedBox(height: 10),
                  _buildTextField("Correo Electrónico", _emailController),
                  const SizedBox(height: 10),
                  _buildTextField("Dirección", _addressController),
                  const SizedBox(height: 10),
                  _buildTextField("Ciudad", _cityController),
                  const SizedBox(height: 10),
                  _buildTextField("Código Postal", _postalCodeController),
                  const SizedBox(height: 10),
                  _buildTextField("Teléfono", _phoneController),
                  const SizedBox(height: 10),
                  _buildTextField(
                    "RUT",
                    _rutController,
                    readOnly: true, // RUT no editable
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: const Text(
                        "Guardar Cambios",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
