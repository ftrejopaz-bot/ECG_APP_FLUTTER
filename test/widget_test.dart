import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:borrador_proyecto/main.dart'; // Verifica que este sea el nombre de tu proyecto

void main() {
  testWidgets('Prueba de arranque de la App', (WidgetTester tester) async {
    // CORRECCIÓN: Usamos 'mostrarOnboarding: false' para simular que ya vio el tutorial
    // y que debe ir directo al Login.
    await tester.pumpWidget(const MyApp(mostrarOnboarding: false));

    // Esperamos a que cargue
    await tester.pump();

    // Verificamos que aparezca algo del Login (ej. "Bienvenido de nuevo")
    // Nota: Asegúrate que este texto exista en tu pantalla de Login
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
  });
}