import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:borrador_proyecto/servicios/firebase_service.dart';

class SymptomScreen extends StatefulWidget {
  final String? userId; // ID del paciente (Opcional)
  const SymptomScreen({super.key, this.userId});

  @override
  State<SymptomScreen> createState() => _SymptomScreenState();
}

class _SymptomScreenState extends State<SymptomScreen> {
  final FirebaseService _service = FirebaseService();
  final TextEditingController _sintomaController = TextEditingController();

  void _mostrarDialogoSintoma({String? docId, String? textoActual}) {
      _sintomaController.text = textoActual ?? '';
      showDialog(
        context: context, 
        builder: (dialogContext) => AlertDialog(
            title: Text(docId == null ? "Nuevo Síntoma" : "Editar Síntoma"),
            content: TextField(
              controller: _sintomaController,
              decoration: const InputDecoration(hintText: "Ej: Mareo..."),
              maxLines: 3,
            ),
            actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancelar")),
                ElevatedButton(
                    onPressed: () async {
                        if (_sintomaController.text.isNotEmpty) {
                            Navigator.pop(dialogContext);
                            if (docId == null) await _service.registrarSintoma(_sintomaController.text);
                            else await _service.actualizarSintoma(docId, _sintomaController.text);
                        }
                    }, 
                    child: const Text("Guardar")
                )
            ]
        )
      );
  }

  void _confirmarEliminar(String docId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("¿Eliminar?"),
        content: const Text("No podrás deshacer esta acción."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _service.eliminarSintoma(docId);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool esMedico = widget.userId != null;

    return Scaffold(
      appBar: esMedico ? null : AppBar(title: const Text("Bitácora"), backgroundColor: Colors.teal),
      
      floatingActionButton: esMedico ? null : FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () => _mostrarDialogoSintoma(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.obtenerBitacora(uid: widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Sin registros."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              Timestamp? t = data['fecha'] as Timestamp?;
              String fecha = t != null ? "${t.toDate().day}/${t.toDate().month} ${t.toDate().hour}:${t.toDate().minute}" : "--";

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.medical_information, color: Colors.orange),
                  title: Text(data['descripcion'] ?? ""),
                  subtitle: Text(fecha),
                  trailing: esMedico ? null : PopupMenuButton<String>(
                    onSelected: (v) => v == 'edit' ? _mostrarDialogoSintoma(docId: doc.id, textoActual: data['descripcion']) : _confirmarEliminar(doc.id),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'edit', child: Text("Editar")),
                      const PopupMenuItem(value: 'delete', child: Text("Eliminar")),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}