import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/main.dart'; // Para navegar al LoginScreen

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  // Función para completar el tutorial y guardar la preferencia
  void _terminarOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('visto_tutorial', true); // Marca como visto

    if (context.mounted) {
      // Navegar al Login y borrar historial para no volver atrás
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        // PÁGINA 1: Bienvenida
        PageViewModel(
          title: "Bienvenido a CardioTrack",
          body: "Tu monitor cardíaco portátil e inteligente. Lleva el control de tu salud desde tu bolsillo.",
          image: const Icon(Icons.monitor_heart, size: 150, color: Colors.teal),
          decoration: _pageDecoration(),
        ),
        
        // PÁGINA 2: Conexión
        PageViewModel(
          title: "Conexión Fácil",
          body: "Enciende tu dispositivo portátil, activa el Bluetooth y conéctalo con un solo toque.",
          image: const Icon(Icons.bluetooth_audio, size: 150, color: Colors.blue),
          decoration: _pageDecoration(),
        ),

        // PÁGINA 3: QR y Médicos
        PageViewModel(
          title: "Comparte con tu Médico",
          body: "Genera tu código QR único para que tu doctor pueda ver tu historial en tiempo real.",
          image: const Icon(Icons.qr_code_scanner, size: 150, color: Colors.orange),
          decoration: _pageDecoration(),
        ),
      ],
      
      // Botones de control
      onDone: () => _terminarOnboarding(context),
      onSkip: () => _terminarOnboarding(context),
      showSkipButton: true,
      skip: const Text("Saltar", style: TextStyle(fontWeight: FontWeight.bold)),
      next: const Icon(Icons.arrow_forward),
      done: const Text("Empezar", style: TextStyle(fontWeight: FontWeight.bold)),
      
      // Estilos de los puntos indicadores
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: Colors.teal,
        color: Colors.black26,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
      ),
    );
  }

  // Estilo común para las páginas
  PageDecoration _pageDecoration() {
    return const PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
      bodyTextStyle: TextStyle(fontSize: 19.0),
      imagePadding: EdgeInsets.all(20),
      pageColor: Colors.white, // Puedes cambiarlo si usas modo oscuro
    );
  }
}