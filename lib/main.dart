import 'package:flutter/material.dart';
import 'package:enviaya/presentation/screen/loginScreen.dart';

// Función principal que inicia la aplicación
void main() {
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
      home: LoginScreen(),
    );
  }
}
