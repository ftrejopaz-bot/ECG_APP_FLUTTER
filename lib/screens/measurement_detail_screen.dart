import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../main.dart'; // Para usar ECGPainter

class MeasurementDetailScreen extends StatelessWidget {
  final Map<String, dynamic> medicionData;
  final String fecha;

  const MeasurementDetailScreen({super.key, required this.medicionData, required this.fecha});

  @override
  Widget build(BuildContext context) {
    List<dynamic> rawPoints = medicionData['datos_onda'] ?? [];
    List<double> ecgPoints = rawPoints.map((e) => (e as num).toDouble()).toList();
    int bpm = medicionData['bpm_promedio'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text("Detalle de Medición"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [const Text("FECHA", style: TextStyle(color: Colors.grey, fontSize: 12)), Text(fecha, style: const TextStyle(fontWeight: FontWeight.bold))]),
                    Column(children: [const Text("BPM", style: TextStyle(color: Colors.grey, fontSize: 12)), Text("$bpm", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: bpm < 60 || bpm > 100 ? Colors.red : Colors.teal))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Gráfica Registrada", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                height: 300,
                width: math.max(MediaQuery.of(context).size.width, ecgPoints.length * 3.0),
                decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.grey)),
                child: CustomPaint(painter: ECGPainter(ecgPoints)),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Desliza para ver más ->", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}