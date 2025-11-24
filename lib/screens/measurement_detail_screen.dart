import 'package:flutter/material.dart';
import '/main.dart'; 
import 'dart:math' as math;

class MeasurementDetailScreen extends StatelessWidget {
  final Map<String, dynamic> medicionData;
  final String fecha;

  const MeasurementDetailScreen({
    super.key, 
    required this.medicionData, 
    required this.fecha
  });

  @override
  Widget build(BuildContext context) {
    // Recuperar los datos
    List<dynamic> rawPoints = medicionData['datos_onda'] ?? [];
    int bpm = medicionData['bpm_promedio'] ?? 0;
    
    // Convertir a List<double> para el pintor
    List<double> ecgPoints = rawPoints.map((e) => (e as num).toDouble()).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de Medición"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // TARJETA DE RESUMEN
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text("FECHA", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(fecha, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text("BPM PROMEDIO", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text("$bpm", style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: bpm < 60 || bpm > 100 ? Colors.red : Colors.teal
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            const Text("Gráfica Registrada", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // VISOR DE GRÁFICA
            // Usamos un SingleChildScrollView horizontal para que si la gráfica es larga, se pueda deslizar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                height: 300,
                // Calculamos un ancho dinámico: 3 pixeles por cada punto de dato
                // Así la onda no se ve apretada, sino que se puede scrollear
                width: math.max(MediaQuery.of(context).size.width, ecgPoints.length * 3.0),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.grey),
                ),
                child: CustomPaint(
                  // Reutilizamos el pintor que ya tienes en main.dart
                  painter: ECGPainter(ecgPoints), 
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            const Text(
              "Desliza horizontalmente para ver toda la grabación ->", 
              style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)
            ),
          ],
        ),
      ),
    );
  }
}
// Necesitamos importar math para el cálculo del ancho
