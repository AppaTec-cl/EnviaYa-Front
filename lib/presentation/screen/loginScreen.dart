import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:enviaya/presentation/screen/homeEmployee.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;

  // Controladores para capturar el correo y la contraseña
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Instancia de FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Método para iniciar sesión con Firebase
  Future<void> _signInWithEmailAndPassword() async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Navigator.push(context,
          MaterialPageRoute(builder: (context) => WorkerWelcomeScreen()));
    } catch (e) {
      // Muestra un mensaje de error si el inicio de sesión falla
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
                    onPressed: _resetPassword, // Agregamos el método aquí
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "¿No tienes una cuenta? ",
                      style: TextStyle(fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text(
                        "Regístrate ahora",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
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
