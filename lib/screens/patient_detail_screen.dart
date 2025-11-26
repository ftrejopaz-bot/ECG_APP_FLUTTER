import 'package:flutter/material.dart';
import 'history_screen.dart';
import 'symptom_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  final String pacienteId;
  final Map<String, dynamic> datosPaciente;

  const PatientDetailScreen({
    super.key, 
    required this.pacienteId, 
    required this.datosPaciente
  });

  @override
  Widget build(BuildContext context) {
    String nombre = datosPaciente['nombre'] ?? "Paciente";
    var bio = datosPaciente['datos_biometricos'] ?? {};

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Expediente de $nombre"),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.person), text: "Perfil"),
              Tab(icon: Icon(Icons.show_chart), text: "Historial"),
              Tab(icon: Icon(Icons.note), text: "Bitácora"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // PESTAÑA 1: PERFIL (Información estática)
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(radius: 50, backgroundColor: Colors.blue, child: Icon(Icons.person, size: 60, color: Colors.white)),
                  const SizedBox(height: 20),
                  _buildInfoCard(Icons.email, "Correo", datosPaciente['email'] ?? "--"),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard(Icons.cake, "Edad", "${bio['edad'] ?? '--'} años")),
                      const SizedBox(width: 10),
                      Expanded(child: _buildInfoCard(Icons.monitor_weight, "Peso", "${bio['peso'] ?? '--'} kg")),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildInfoCard(Icons.height, "Altura", "${bio['altura'] ?? '--'} cm"),
                ],
              ),
            ),

            // PESTAÑA 2: HISTORIAL (Reutilizamos la pantalla, pasándole el ID del paciente)
            HistoryScreen(userId: pacienteId),

            // PESTAÑA 3: BITÁCORA (Reutilizamos la pantalla, pasándole el ID del paciente)
            SymptomScreen(userId: pacienteId),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}