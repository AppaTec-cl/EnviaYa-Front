import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importar Firebase
import 'firebase_options.dart'; // Importar las opciones generadas
import 'package:enviaya/presentation/screen/homeScreen.dart'; // Tu pantalla inicial
import 'package:enviaya/presentation/screen/registerScreen.dart';

// Función principal que inicia la aplicación
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Necesario para inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Inicializa Firebase
  );
  runApp(const MiAplicacion());
}

// Clase principal de la aplicación que extiende StatefulWidget
class MiAplicacion extends StatefulWidget {
  const MiAplicacion({super.key});

  @override
  State<MiAplicacion> createState() => _EstadoMiAplicacion();
}

// Estado de la clase principal MiAplicacion
class _EstadoMiAplicacion extends State<MiAplicacion> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: WelcomeScreen(), // Pantalla inicial
      routes: {
      '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
