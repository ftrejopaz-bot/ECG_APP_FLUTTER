import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:borrador_proyecto/main.dart'; // Asegúrate que este import coincida con tu proyecto

void main() {
  testWidgets('Prueba de arranque de la App', (WidgetTester tester) async {
    // 1. Iniciamos la app pasándole el parámetro que faltaba
    // Le decimos 'false' para que cargue el Login directamente
    await tester.pumpWidget(const MyApp(mostrarOnboarding: false));

    // 2. Esperamos a que cargue la interfaz
    await tester.pump();

    // 3. Verificamos que la app arrancó buscando un texto del Login
    // (El test original buscaba '0' y '1', eso fallaría porque ya no es una app de contador)
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Busca correo y contraseña
  });
}