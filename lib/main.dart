import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
// LIBRERÍA CLÁSICA
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'; 
import 'package:permission_handler/permission_handler.dart';

import 'servicios/firebase_service.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';
import 'screens/qr_share_screen.dart';
import 'screens/qr_scan_screen.dart';
import 'screens/symptom_screen.dart';
import 'screens/onboarding_screen.dart'; 
import 'screens/patient_detail_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void _guardarTema(bool esOscuro) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('es_modo_oscuro', esOscuro);
  themeNotifier.value = esOscuro ? ThemeMode.dark : ThemeMode.light;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final prefs = await SharedPreferences.getInstance();
  final bool visto = prefs.getBool('visto_tutorial') ?? false;
  final bool esOscuro = prefs.getBool('es_modo_oscuro') ?? false;
  themeNotifier.value = esOscuro ? ThemeMode.dark : ThemeMode.light;

  runApp(MyApp(mostrarOnboarding: !visto));
}

class MyApp extends StatelessWidget {
  final bool mostrarOnboarding;
  const MyApp({super.key, required this.mostrarOnboarding});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Monitor ECG IoT',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.teal,
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.grey[50],
            appBarTheme: const AppBarTheme(backgroundColor: Colors.teal, foregroundColor: Colors.white),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.teal,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1F1F1F), foregroundColor: Colors.tealAccent),
            colorScheme: const ColorScheme.dark(primary: Colors.teal, secondary: Colors.tealAccent),
          ),
          themeMode: currentMode,
          home: mostrarOnboarding ? const OnboardingScreen() : const AuthCheckScreen(),
        );
      },
    );
  }
}

// --- PANTALLA INTERMEDIA ---
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});
  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSesionYRol();
  }

  void _verificarSesionYRol() async {
    final user = FirebaseService().getUserEmail(); // Usamos helper
    if (user == null) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    // Nota: Para producción, usar FirebaseAuth.instance.currentUser directamente es mejor, 
    // pero aquí simplificamos asumiendo que si no es null, intentamos.
    // Idealmente:
    // final user = FirebaseAuth.instance.currentUser; 
    
    try {
      // Asumiendo que FirebaseService tiene una instancia accesible o usamos FirebaseAuth directo
      // Aquí simulamos la redirección basada en la lógica anterior
      // (Reutiliza tu lógica de AuthCheckScreen anterior si la tenías más compleja)
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } catch (e) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// --- LOGIN SCREEN (Simplificada para el ejemplo, usa la tuya completa) ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ... COPIA TU LÓGICA DE LOGIN COMPLETA AQUÍ (LoginScreenState) ...
  // Para que el código entre en un solo mensaje, asumo que esta parte ya la tienes dominada.
  // Si necesitas el Login completo de nuevo, dímelo.
  @override
  Widget build(BuildContext context) {
      // Placeholder para que veas donde va
      return Scaffold(body: Center(child: ElevatedButton(onPressed: (){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientDashboard()));
      }, child: const Text("Ir a Dashboard (Login Simulado)")))); 
  }
}

// ===========================================================================
// DASHBOARD DEL PACIENTE (BLUETOOTH CLÁSICO)
// ===========================================================================
class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final FirebaseService _authService = FirebaseService();

  // --- VARIABLES BLUETOOTH CLÁSICO ---
  BluetoothConnection? connection;
  bool isConnected = false;
  bool isConnecting = false;
  
  // --- VARIABLES DE DATOS ---
  int batteryLevel = 0;
  int bpm = 0;
  List<double> ecgPoints = List.filled(100, 2048.0, growable: true);
  String _dataBuffer = ""; // Buffer para armar el JSON

  // --- SIMULACIÓN ---
  bool isSimulationMode = false;
  Timer? _simTimer;
  double _simTime = 0;

  // --- PERFIL ---
  String displayNombre = "Cargando...";
  String displayEdad = "--";
  String displayPeso = "--";
  String displayAltura = "--";

  @override
  void initState() {
    super.initState();
    _cargarDatosPaciente();
    _checkPermissions();
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    // Cerrar conexión clásica
    if (isConnected) {
      connection?.dispose();
    }
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    // Pedir permisos necesarios (Android 12+ requiere estos también para Clásico)
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  void _cargarDatosPaciente() async {
    try {
      var doc = await _authService.getUserData();
      if (doc.exists && mounted) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          displayNombre = data['nombre'] ?? "Paciente";
          var bio = data['datos_biometricos'];
          if(bio != null) {
             displayEdad = "${bio['edad']}"; displayPeso = "${bio['peso']}"; displayAltura = "${bio['altura']}";
          }
        });
      }
    } catch (e) { print(e); }
  }

  // --- LÓGICA CONEXIÓN CLÁSICA ---
  Future<void> _abrirSelectorBluetooth() async {
    if (isSimulationMode) _stopSimulation();

    // 1. Obtener lista de emparejados
    List<BluetoothDevice> devices = [];
    try {
      devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) { print(e); }

    // 2. Mostrar Modal
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Selecciona tu ESP32", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("No hay dispositivos emparejados. Ve a Ajustes de Android > Bluetooth y empareja primero el 'Monitor_ECG_ESP32'."),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(devices[index].name ?? "Desconocido"),
                        subtitle: Text(devices[index].address),
                        onTap: () {
                          Navigator.pop(context);
                          _conectarDispositivo(devices[index]);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _conectarDispositivo(BluetoothDevice device) async {
    setState(() => isConnecting = true);

    try {
      // Conexión Clásica (Socket RFCOMM)
      connection = await BluetoothConnection.toAddress(device.address);
      
      if(mounted) {
        setState(() {
          isConnected = true;
          isConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Conectado"), backgroundColor: Colors.green));
      }

      // Escuchar flujo de datos (Stream de Bytes)
      connection!.input!.listen(_onDataReceived).onDone(() {
        if (mounted) {
          setState(() => isConnected = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Desconectado"), backgroundColor: Colors.red));
        }
      });

    } catch (e) {
      print("Error conexión: $e");
      if (mounted) {
        setState(() { isConnected = false; isConnecting = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo conectar"), backgroundColor: Colors.red));
      }
    }
  }

  void _desconectar() {
    connection?.dispose();
    setState(() => isConnected = false);
  }

  // --- PROCESAMIENTO DE DATOS (Buffer JSON) ---
  void _onDataReceived(Uint8List data) {
    String incoming = utf8.decode(data);
    _dataBuffer += incoming;

    try {
      if(_dataBuffer.length > 3000) _dataBuffer = ""; // Limpieza de seguridad

      // Buscar JSON completo { ... }
      int openBrace = _dataBuffer.indexOf('{');
      int closeBrace = _dataBuffer.indexOf('}');

      // Procesar mientras haya paquetes completos
      while (openBrace != -1 && closeBrace != -1 && closeBrace > openBrace) {
        String jsonStr = _dataBuffer.substring(openBrace, closeBrace + 1);
        _dataBuffer = _dataBuffer.substring(closeBrace + 1); // Remover lo procesado
        
        _procesarJSON(jsonStr);

        // Buscar siguiente
        openBrace = _dataBuffer.indexOf('{');
        closeBrace = _dataBuffer.indexOf('}');
      }
    } catch (e) { 
      // Esperar más datos 
    }
  }

  void _procesarJSON(String jsonString) {
    try {
      Map<String, dynamic> data = jsonDecode(jsonString);
      if (data.containsKey("status") && data["status"] == "LEADS_OFF") return;

      setState(() {
        if (data.containsKey('bpm')) bpm = data['bpm'];
        if (data.containsKey('bat')) batteryLevel = data['bat'];
        if (data.containsKey('wave')) {
          List<dynamic> wave = data['wave'];
          for (var val in wave) {
            // Normalización
            double normalized = (val - 2048) / 500.0 * -1.0;
            if (ecgPoints.length >= 100) ecgPoints.removeAt(0);
            ecgPoints.add(normalized);
          }
        }
      });
    } catch (e) { print("JSON Error: $e"); }
  }

  // --- SIMULACIÓN ---
  void _toggleSimulation() {
    if (isSimulationMode) _stopSimulation();
    else _startSimulation();
  }

  void _startSimulation() {
    if (isConnected) _desconectar();
    setState(() { isSimulationMode = true; batteryLevel = 100; });
    
    _simTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _simTime += 0.2;
          double rawVal = -1.0 * math.exp(-math.pow(_simTime % 4 - 0.5, 2) / 0.1) +
              5.0 * math.exp(-math.pow(_simTime % 4 - 1.5, 2) / 0.05) +
              1.5 * math.exp(-math.pow(_simTime % 4 - 2.5, 2) / 0.2);
          rawVal += (math.Random().nextDouble() - 0.5) * 0.2;
          
          if (ecgPoints.length >= 100) ecgPoints.removeAt(0);
          ecgPoints.add(rawVal);
          
          if (_simTime % 20 < 0.2) {
             bpm = 70 + math.Random().nextInt(10);
             if(batteryLevel > 0) batteryLevel--;
          }
        });
      }
    });
  }

  void _stopSimulation() {
    _simTimer?.cancel();
    setState(() { isSimulationMode = false; bpm = 0; ecgPoints = List.filled(100, 0.0); });
  }

  Color getBatteryColor() {
    if (batteryLevel > 50) return Colors.green;
    if (batteryLevel > 20) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    bool sistemaActivo = isConnected || isSimulationMode;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              accountName: Text(displayNombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text(_authService.getUserEmail() ?? ""),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.teal),
              ),
            ),
            ListTile(title: const Text("Inicio"), leading: const Icon(Icons.home), onTap: () => Navigator.pop(context)),
            ListTile(title: const Text("Compartir mi Código"), leading: const Icon(Icons.qr_code), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const QrShareScreen())); }),
            ListTile(title: const Text("Historial"), leading: const Icon(Icons.history), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())); }),
            ListTile(title: const Text("Bitácora"), leading: const Icon(Icons.edit_note), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomScreen())); }),
            const Divider(),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (_, mode, __) {
                return SwitchListTile(
                  title: const Text("Modo Oscuro"),
                  secondary: Icon(mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
                  value: mode == ThemeMode.dark,
                  onChanged: (val) { _guardarTema(val); },
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
              onTap: () async {
                if(isConnected) _desconectar();
                Navigator.pop(context);
                await _authService.cerrarSesion();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (Route<dynamic> route) => false);
                }
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Monitor Cardíaco"),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              child: Row(
                children: [
                  Text(sistemaActivo ? "$batteryLevel%" : "--%", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Icon(Icons.battery_std, color: sistemaActivo ? getBatteryColor() : Colors.grey),
                ],
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ESTADO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Estado del Sensor", style: TextStyle(color: Colors.grey)),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 12, color: sistemaActivo ? Colors.green : Colors.red),
                        const SizedBox(width: 6),
                        Text(
                          isSimulationMode 
                              ? "SIMULANDO" 
                              : (isConnected ? "CONECTADO" : (isConnecting ? "CONECTANDO..." : "DESCONECTADO")), 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                      ],
                    )
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text("RITMO (BPM)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(bpm > 0 ? "$bpm" : "--", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            
            // GRÁFICA
            const Text("Señal en Tiempo Real (AD8232)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[800]!)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(painter: ECGPainter(ecgPoints)),
              ),
            ),
            const SizedBox(height: 20),

            // BOTONES
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnected ? Colors.red.shade100 : Colors.teal,
                      foregroundColor: isConnected ? Colors.red : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: (isConnecting || isSimulationMode) ? null : (isConnected ? _desconectar : _abrirSelectorBluetooth),
                    icon: Icon(isConnected ? Icons.bluetooth_disabled : Icons.bluetooth),
                    label: Text(isConnected ? "DESCONECTAR" : "CONECTAR SENSOR"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSimulationMode ? Colors.orange : Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: isConnected ? null : _toggleSimulation,
                    icon: Icon(isSimulationMode ? Icons.stop : Icons.play_arrow),
                    label: Text(isSimulationMode ? "DETENER SIM" : "SIMULAR"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (sistemaActivo)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                  icon: const Icon(Icons.save),
                  label: const Text("GUARDAR LECTURA ACTUAL EN NUBE"),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Guardando datos...")));
                    if(isSimulationMode) _stopSimulation();
                    await _authService.guardarMedicion(bpm: bpm > 0 ? bpm : 0, datosOnda: ecgPoints);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Lectura guardada!"), backgroundColor: Colors.green));
                  },
                ),
              ),

            // DATOS
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 const Text("Mis Datos Fisiológicos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 IconButton(onPressed: _cargarDatosPaciente, icon: const Icon(Icons.refresh, color: Colors.teal))
              ],
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(children: [Expanded(child: _buildInfoField("Edad", "$displayEdad años")), const SizedBox(width: 10), Expanded(child: _buildInfoField("Peso", "$displayPeso kg"))]),
                    const SizedBox(height: 10),
                    Row(children: [Expanded(child: _buildInfoField("Nombre", displayNombre)), const SizedBox(width: 10), Expanded(child: _buildInfoField("Altura", "$displayAltura cm"))]),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                          _cargarDatosPaciente();
                        }, 
                        child: const Text("Actualizar Datos")
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ... (DOCTOR DASHBOARD Y ECG PAINTER IGUALES, CÓPIALOS DE TU VERSIÓN ANTERIOR O PÍDEMELOS SI LOS PERDISTE) ...
// Puse ... para que entrara en un mensaje, pero recuerda pegar el DoctorDashboard y ECGPainter
class DoctorDashboard extends StatefulWidget { const DoctorDashboard({super.key}); @override State<DoctorDashboard> createState() => _DoctorDashboardState(); }
class _DoctorDashboardState extends State<DoctorDashboard> { @override Widget build(BuildContext context) { return const Scaffold(body: Center(child: Text("Pega tu DoctorDashboard aquí"))); } }
class ECGPainter extends CustomPainter { final List<double> p; ECGPainter(this.p); @override void paint(Canvas c, Size s) {} @override bool shouldRepaint(old) => true; }