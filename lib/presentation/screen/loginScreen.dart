import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enviaya/presentation/screen/homeEmployee.dart';
import 'package:enviaya/presentation/screen/homeAssing.dart';
import 'package:enviaya/presentation/screen/registerScreen.dart'; // Pantalla de registro

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController(); // Controlador para la contraseña de administrador

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para iniciar sesión
  Future<void> _signInWithEmailAndPassword() async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final String userRole = userData['role'] ?? '';

        if (userRole == 'Repartidor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WorkerWelcomeScreen()),
          );
        } else if (userRole == 'Encargado de asignar paquetes') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeAssignScreen()),
          );
        } else {
          _showMessage("Rol desconocido. Contacta al administrador.");
        }
      } else {
        _showMessage("El usuario no tiene datos registrados. Contacta al administrador.");
      }
    } catch (e) {
      _showMessage("Error: ${e.toString()}");
    }
  }

  // Método para enviar correo de recuperación de contraseña
  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showMessage("Por favor, ingresa tu correo electrónico.");
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      _showMessage(
          "Correo de recuperación enviado. Revisa tu bandeja de entrada.");
    } catch (e) {
      _showMessage("Error al enviar el correo: ${e.toString()}");
    }
  }

  // Método para verificar la contraseña de administrador
  Future<void> _verifyAdminPassword() async {
    try {
      // Consulta todos los documentos en la colección "admin_codes"
      final QuerySnapshot querySnapshot =
          await _firestore.collection('admin_codes').get();

      // Buscar si existe un documento con el adminCode igual al ingresado
      final bool adminCodeExists = querySnapshot.docs.any((doc) {
        final adminData = doc.data() as Map<String, dynamic>;
        return adminData['adminCode'] == _adminPasswordController.text.trim();
      });

      if (adminCodeExists) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const RegisterScreen()), // Redirige a la pantalla de registro
        );
      } else {
        _showMessage("Contraseña de administrador incorrecta.");
      }
    } catch (e) {
      _showMessage("Error al verificar la contraseña: ${e.toString()}");
    }
  }



  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  "¡Bienvenido de nuevo!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "¡Nos alegra verte otra vez!",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Correo electrónico",
                    labelStyle: const TextStyle(fontSize: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    labelStyle: const TextStyle(fontSize: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: const Text(
                      "¿Olvidaste tu contraseña?",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signInWithEmailAndPassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      backgroundColor: Colors.black,
                    ),
                    child: const Text(
                      "Iniciar sesión",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showAdminPasswordDialog(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      backgroundColor: Colors.grey[800],
                    ),
                    child: const Text(
                      "Registrar nuevo usuario",
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
      ),
    );
  }

  // Mostrar diálogo para ingresar la contraseña de administrador
  void _showAdminPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Contraseña de administrador"),
          content: TextField(
            controller: _adminPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Contraseña",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _verifyAdminPassword();
              },
              child: const Text("Verificar"),
            ),
          ],
        );
      },
    );
  }
}
