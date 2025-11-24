import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/servicios/firebase_service.dart';
import 'measurement_detail_screen.dart'; // Importamos la pantalla de detalle

class HistoryScreen extends StatelessWidget {
  final String? userId; // ID del paciente (Opcional, para el médico)

  // Si userId es null, mostrará el historial del usuario logueado (paciente viendo sus datos)
  // Si userId tiene valor, mostrará el historial de ese paciente (médico viendo a paciente)
  const HistoryScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final FirebaseService service = FirebaseService();

    return Scaffold(
      // Si hay userId (es médico viendo paciente), no mostramos AppBar porque esta pantalla
      // seguramente estará dentro de una pestaña del expediente.
      // Si es null (es paciente viendo sus datos), mostramos la AppBar normal.
      appBar: userId == null 
          ? AppBar(
              title: const Text("Historial de Mediciones"), 
              backgroundColor: Colors.teal, 
              foregroundColor: Colors.white
            )
          : null,
      
      body: StreamBuilder<QuerySnapshot>(
        // Pasamos el ID al servicio. Si es null, el servicio usará el currentUser.
        stream: service.obtenerHistorialPaciente(uid: userId),
        builder: (context, snapshot) {
          // 1. Estado de Carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Estado de Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("Error al cargar historial: ${snapshot.error}", textAlign: TextAlign.center),
              )
            );
          }
          
          // 3. Estado Sin Datos
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text("No hay mediciones registradas.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 4. Lista de Mediciones
          var documentos = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              var data = documentos[index].data() as Map<String, dynamic>;
              
              // Formato de Fecha manual (DD/MM/AAAA HH:MM)
              // Si quieres usar 'intl', descomenta y usa DateFormat
              Timestamp? t = data['fecha'] as Timestamp?;
              String fechaTexto = "Fecha desconocida";
              
              if (t != null) {
                DateTime date = t.toDate();
                String dia = date.day.toString().padLeft(2, '0');
                String mes = date.month.toString().padLeft(2, '0');
                String anio = date.year.toString();
                String hora = date.hour.toString().padLeft(2, '0');
                String min = date.minute.toString().padLeft(2, '0');
                fechaTexto = "$dia/$mes/$anio $hora:$min";
              }

              int bpm = data['bpm_promedio'] ?? 0;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    // Color según riesgo: Rojo (peligro), Naranja (alerta), Verde (normal)
                    backgroundColor: _getColorBPM(bpm),
                    radius: 25,
                    child: Text(
                      "$bpm", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ),
                  title: const Text(
                    "Medición ECG", 
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Fecha: $fechaTexto"),
                      const Text("Duración: 30 seg", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // Navegar al detalle de la medición para ver la gráfica
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MeasurementDetailScreen(
                          medicionData: data, // Pasamos todo el mapa de datos (incluyendo el array de la onda)
                          fecha: fechaTexto,  // Pasamos la fecha ya formateada para no recalcularla
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Función auxiliar para determinar el color del círculo según los BPM
  Color _getColorBPM(int bpm) {
    if (bpm == 0) return Colors.grey;   // Error o desconectado
    if (bpm < 60) return Colors.orange; // Bradicardia
    if (bpm > 100) return Colors.red;   // Taquicardia
    return Colors.green;                // Normal
  }
}