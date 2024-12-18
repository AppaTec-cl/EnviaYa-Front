import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  _HelpSupportScreenState createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _questionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lista de preguntas frecuentes
  final List<Map<String, String>> _faqs = [
    {"question": "¿Cómo rastrear mi pedido?", "answer": "Puedes rastrear tu pedido en la sección 'Seguimiento de Envíos'."},
    {"question": "¿Cómo reporto un problema?", "answer": "Desde el menú, selecciona 'Reportar Problema'."},
    {"question": "¿Qué hago si no recibí mi pedido?", "answer": "Contacta al soporte usando el formulario o el correo."},
  ];

  // Enviar consulta a Firestore
  Future<void> _submitQuery() async {
    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes iniciar sesión para enviar una consulta.")),
      );
      return;
    }

    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, escribe tu consulta.")),
      );
      return;
    }

    try {
      // Obtener información adicional del usuario
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.exists ? userDoc['name'] : 'Usuario Desconocido';
      final userEmail = user.email ?? 'Sin correo';

      await _firestore.collection('support_queries').add({
        'query': _questionController.text.trim(),
        'userId': user.uid,
        'name': userName,
        'email': userEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Consulta enviada con éxito.")),
      );
      _questionController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al enviar consulta: $e")),
      );
    }
  }

  // Abrir cliente de correo
  Future<void> _contactSupportByEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'contacto@appatec.com',
      query: 'subject=Soporte%20al%20Cliente&body=Escribe%20tu%20consulta%20aquí',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir el cliente de correo.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayuda y Soporte"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Preguntas Frecuentes (FAQ)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ..._faqs.map((faq) => ExpansionTile(
                    title: Text(faq['question']!),
                    children: [Padding(padding: const EdgeInsets.all(8.0), child: Text(faq['answer']!))],
                  )),
              const SizedBox(height: 20),
              const Text(
                "Envíanos una consulta",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _questionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Escribe tu consulta aquí...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitQuery,
                  child: const Text("Enviar Consulta"),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "¿Necesitas más ayuda?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _contactSupportByEmail,
                  icon: const Icon(Icons.email),
                  label: const Text("Contactar por Correo"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
