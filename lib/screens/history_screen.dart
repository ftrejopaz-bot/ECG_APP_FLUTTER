import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../servicios/firebase_service.dart';
import 'measurement_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  final String? userId; // ID opcional

  const HistoryScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final FirebaseService service = FirebaseService();

    return Scaffold(
      appBar: userId == null 
          ? AppBar(title: const Text("Historial de Mediciones"), backgroundColor: Colors.teal, foregroundColor: Colors.white)
          : null,
      
      body: StreamBuilder<QuerySnapshot>(
        stream: service.obtenerHistorialPaciente(uid: userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("Error: ${snapshot.error}")));
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              Timestamp? t = data['fecha'] as Timestamp?;
              String fechaTexto = "Fecha desconocida";
              if (t != null) {
                DateTime d = t.toDate();
                fechaTexto = "${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute}";
              }
              int bpm = data['bpm_promedio'] ?? 0;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: bpm < 60 || bpm > 100 ? Colors.orange : Colors.green,
                    radius: 25,
                    child: Text("$bpm", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: const Text("Medición ECG", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Fecha: $fechaTexto\nDuración: 30 seg"),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MeasurementDetailScreen(
                          medicionData: data,
                          fecha: fechaTexto,
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
}