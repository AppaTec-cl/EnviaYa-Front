import 'package:flutter/material.dart';
import 'package:enviaya/presentation/screen/mapRute.dart';
import 'package:enviaya/presentation/reportProblemScreen.dart';

class WorkerWelcomeScreen extends StatelessWidget {
  const WorkerWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                "¡Bienvenido Trabajador!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Estamos listos para comenzar. Usa las opciones a continuación para gestionar tus tareas.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromRGBO(158, 158, 158, 1),
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: [
                    _buildOptionCard(
                      icon: Icons.map,
                      label: "Mapa de Pedidos",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapSample(),
                          ),
                        );
                      },
                    ),
                    _buildOptionCard(
                      icon: Icons.check_circle,
                      label: "Confirmar Entrega",
                      onTap: () {
                        // Acción para Confirmar Entrega
                      },
                    ),
                    _buildOptionCard(
                      icon: Icons.history,
                      label: "Historial de Entregas",
                      onTap: () {
                        // Acción para Historial de Entregas
                      },
                    ),
                    _buildOptionCard(
                      icon: Icons.report_problem,
                      label: "Reportar Problema",
                      onTap: () {
                          Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReportProblemScreen(),
                          ),
                        );
                            // Acción para Reportar Problema
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.black,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
