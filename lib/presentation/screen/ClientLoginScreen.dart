import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enviaya/presentation/screen/registerClientScreen.dart';
import 'package:enviaya/presentation/screen/homeUser.dart';

class ClienteLoginScreen extends StatefulWidget {
  const ClienteLoginScreen({super.key});

  @override
  _ClienteLoginScreenState createState() => _ClienteLoginScreenState();
}

class _ClienteLoginScreenState extends State<ClienteLoginScreen> {
  bool _isPasswordVisible = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para iniciar sesión con validación en 'clients'
  Future<void> _signInWithEmailAndPassword() async {
    try {
      // Intentar inicio de sesión en Firebase Auth
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Verificar si el usuario existe en la colección 'clients'
      final clientSnapshot = await _firestore
          .collection('clients')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (clientSnapshot.docs.isNotEmpty) {
        // Si el usuario existe en 'clients', permitir acceso
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeUserScreen()),
        );
      } else {
        // Si el usuario no está en 'clients', cerrar sesión y mostrar mensaje
        await _auth.signOut();
        _showMessage(
            "No tienes permisos para acceder. Esta cuenta no pertenece a un cliente.");
      }
    } catch (e) {
      _showMessage("Error: El correo electrónico o la contraseña es incorrecto");
    }
  }

  // Método para mostrar mensajes
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
                  "Iniciar sesión - Cliente",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Accede con tu cuenta de cliente",
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
                    onPressed: () {
                      _auth.sendPasswordResetEmail(
                          email: _emailController.text.trim());
                      _showMessage("Correo de recuperación enviado.");
                    },
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
                      backgroundColor: Colors.teal,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "¿No tienes una cuenta? ",
                      style: TextStyle(fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterClientScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Regístrate ahora",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}