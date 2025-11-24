import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:borrador_proyecto/servicios/firebase_service.dart';

class QrShareScreen extends StatefulWidget {
  const QrShareScreen({super.key});

  @override
  State<QrShareScreen> createState() => _QrShareScreenState();
}

class _QrShareScreenState extends State<QrShareScreen> {
  final FirebaseService _service = FirebaseService();
  String? myCode;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarCodigo();
  }

  void _cargarCodigo() async {
    var doc = await _service.getUserData();
    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      setState(() {
        // Obtenemos el código que generamos al registrarnos
        myCode = data['codigo_vinculacion']; 
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Código de Vinculación")),
      body: Center(
        child: isLoading 
            ? const CircularProgressIndicator()
            : myCode == null 
                ? const Text("No tienes código asignado.")
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Muestra este código a tu médico",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      
                      // EL CÓDIGO QR
                      QrImageView(
                        data: myCode!, // El texto que se convierte en QR
                        version: QrVersions.auto,
                        size: 280.0,
                      ),
                      
                      const SizedBox(height: 20),
                      Text(
                        myCode!, 
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 5)
                      ),
                    ],
                  ),
      ),
    );
  }
}
