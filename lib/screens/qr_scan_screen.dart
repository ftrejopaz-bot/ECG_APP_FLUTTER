import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:borrador_proyecto/servicios/firebase_service.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool isScanning = true; // Para evitar lecturas dobles

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escanear Qr de Paciente")),
      body: MobileScanner(
        // Controlador de la cámara
        onDetect: (capture) {
          if (!isScanning) return; // Si ya leyó uno, ignorar los demás
          
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              // ¡CÓDIGO ENCONTRADO!
              _procesarCodigo(barcode.rawValue!);
              break; // Solo queremos el primero
            }
          }
        },
      ),
    );
  }

  void _procesarCodigo(String codigo) async {
    setState(() => isScanning = false); // Detener escaneo visual
    
    // Mostrar carga
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator())
    );

    // Llamar a tu servicio de Firebase existente
    final FirebaseService service = FirebaseService();
    String mensaje = await service.vincularPaciente(codigo);

    if (!mounted) return;
    Navigator.pop(context); // Cerrar el loading
    
    // Mostrar resultado y salir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: mensaje.contains("Éxito") ? Colors.green : Colors.red,
      )
    );

    Navigator.pop(context); // Volver al Dashboard médico
  }
}
