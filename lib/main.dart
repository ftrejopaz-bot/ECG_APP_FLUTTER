import 'dart:async';
import 'dart:convert'; // Para decodificar JSON
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Librería BLE
import 'package:permission_handler/permission_handler.dart'; // Permisos

// Importaciones de tus pantallas y servicios
import 'servicios/firebase_service.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';
import 'screens/qr_share_screen.dart';
import 'screens/qr_scan_screen.dart';
import 'screens/symptom_screen.dart';
import 'screens/onboarding_screen.dart'; 
import 'screens/patient_detail_screen.dart';

// 1. VARIABLE GLOBAL PARA EL TEMA
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Verificar si ya vio el tutorial
  final prefs = await SharedPreferences.getInstance();
  final bool visto = prefs.getBool('visto_tutorial') ?? false;

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
          
          // Tema Claro
          theme: ThemeData(
            primarySwatch: Colors.teal,
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.grey[50],
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
          
          // Tema Oscuro
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.teal,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F1F1F),
              foregroundColor: Colors.tealAccent,
            ),
            colorScheme: const ColorScheme.dark(
              primary: Colors.teal,
              secondary: Colors.tealAccent,
            ),
          ),
          
          themeMode: currentMode,
          
          home: mostrarOnboarding ? const OnboardingScreen() : const LoginScreen(),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// PANTALLA DE LOGIN
// ---------------------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool isDoctor = false;
  bool isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monitor_heart, size: 80, color: Colors.teal),
                const SizedBox(height: 20),
                Text(
                  isLogin ? "Bienvenido de nuevo" : "Crear Cuenta",
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  isLogin ? "Ingresa tus credenciales" : "Llena tus datos para registrarte",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),

                if (!isLogin) ...[
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "Nombre Completo",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Correo Electrónico",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 24),

                if (!isLogin) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Soy Paciente"),
                        Switch(
                          value: isDoctor,
                          onChanged: (val) => setState(() => isDoctor = val),
                          activeColor: Colors.blue,
                        ),
                        const Text("Soy Médico"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isLoading ? null : _handleAuthAction,
                    child: isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isLogin ? "INICIAR SESIÓN" : "REGISTRARSE", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                      _emailController.clear();
                      _passController.clear();
                      _nameController.clear();
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      children: [
                        TextSpan(text: isLogin ? "¿No tienes cuenta? " : "¿Ya tienes cuenta? "),
                        TextSpan(
                          text: isLogin ? "Regístrate aquí" : "Inicia sesión",
                          style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAuthAction() async {
    FocusScope.of(context).unfocus();

    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      _mostrarError("Por favor llena el correo y la contraseña");
      return;
    }

    if (!isLogin && _nameController.text.isEmpty) {
      _mostrarError("Por favor escribe tu nombre");
      return;
    }

    setState(() => isLoading = true);

    if (isLogin) {
      var resultado = await _firebaseService.iniciarSesion(
        _emailController.text.trim(),
        _passController.text.trim(),
      );

      if (!mounted) return;

      if (resultado['status'] == 'success') {
        String rol = resultado['rol'];
        _navegarSegunRol(rol);
      } else {
        _mostrarError(resultado['message']);
      }
    } else {
      String? error = await _firebaseService.registrarUsuario(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
        nombre: _nameController.text.trim(),
        rol: isDoctor ? "medico" : "paciente",
      );

      if (!mounted) return;

      if (error == null) {
        _navegarSegunRol(isDoctor ? "medico" : "paciente");
      } else {
        _mostrarError("Error: $error");
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _navegarSegunRol(String rol) {
    if (rol.toLowerCase() == 'medico') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DoctorDashboard()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientDashboard()));
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating),
    );
  }
}

// ---------------------------------------------------------------------------
// DASHBOARD DEL PACIENTE (CON BLE)
// ---------------------------------------------------------------------------
class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final FirebaseService _authService = FirebaseService();

  // Variables BLE
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;
  StreamSubscription? scanSubscription;
  StreamSubscription? valueSubscription;
  
  bool isConnected = false;
  bool isScanning = false;
  
  // UUID de la característica del ESP32 (Debe coincidir con el código Arduino)
  final String TARGET_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // Datos Reales
  int batteryLevel = 0;
  int bpm = 0;
  List<double> ecgPoints = List.filled(100, 2048.0, growable: true);
  String _dataBuffer = "";

  // Datos de Perfil
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
    scanSubscription?.cancel();
    valueSubscription?.cancel();
    connectedDevice?.disconnect();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted) {
      // Permisos concedidos
    }
  }

  void _cargarDatosPaciente() async {
    try {
      var doc = await _authService.getUserData();
      if (doc.exists && mounted) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          displayNombre = data['nombre'] ?? "Paciente";
          var bio = data['datos_biometricos'];
          if (bio != null) {
            displayEdad = "${bio['edad']}";
            displayPeso = "${bio['peso']}";
            displayAltura = "${bio['altura']}";
          }
        });
      }
    } catch (e) {
      print("Error cargando perfil: $e");
    }
  }

  // --- LÓGICA BLE ---
  void _startScan() async {
    setState(() => isScanning = true);
    
    // Escanear por 5 segundos
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // Buscamos el dispositivo por su nombre
        if (r.device.platformName == "Monitor_ECG_BLE") { 
          FlutterBluePlus.stopScan();
          _connectToDevice(r.device);
          break;
        }
      }
    });

    // Apagar spinner si no encuentra nada
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !isConnected) setState(() => isScanning = false);
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        connectedDevice = device;
        isConnected = true;
        isScanning = false;
      });

      // Descubrir servicios y características
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == TARGET_UUID) {
            targetCharacteristic = characteristic;
            
            // Habilitar notificaciones para recibir datos en tiempo real
            await characteristic.setNotifyValue(true);
            valueSubscription = characteristic.lastValueStream.listen((value) {
              _onDataReceived(value);
            });
          }
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Conectado a ${device.platformName}"), backgroundColor: Colors.green)
      );

    } catch (e) {
      print("Error BLE: $e");
      if (mounted) {
        setState(() { isConnected = false; isScanning = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo conectar"), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _disconnect() async {
    await connectedDevice?.disconnect();
    setState(() {
      isConnected = false;
      targetCharacteristic = null;
    });
  }

  void _onDataReceived(List<int> data) {
    // Decodificar bytes a texto
    String incoming = utf8.decode(data);
    _dataBuffer += incoming;

    try {
      // Limpiar buffer si es basura muy larga
      if(_dataBuffer.length > 2000) _dataBuffer = "";

      // Buscar paquete JSON completo { ... }
      int openBrace = _dataBuffer.indexOf('{');
      int closeBrace = _dataBuffer.indexOf('}');

      if (openBrace != -1 && closeBrace != -1 && closeBrace > openBrace) {
        String jsonStr = _dataBuffer.substring(openBrace, closeBrace + 1);
        _dataBuffer = _dataBuffer.substring(closeBrace + 1); // Remover procesado
        _procesarJSON(jsonStr);
      }
    } catch (e) {
      // Esperar siguiente paquete
    }
  }

  void _procesarJSON(String jsonString) {
    try {
      Map<String, dynamic> data = jsonDecode(jsonString);
      
      // Si el ESP32 reporta electrodos desconectados
      if (data.containsKey("status") && data["status"] == "LEADS_OFF") {
        // Aquí podrías mostrar una alerta visual
        return;
      }

      setState(() {
        if (data.containsKey('bpm')) bpm = data['bpm'];
        if (data.containsKey('bat')) batteryLevel = data['bat'];
        
        if (data.containsKey('wave')) {
          List<dynamic> wave = data['wave'];
          for (var val in wave) {
            // Normalizar para la gráfica (aprox -2.0 a 2.0)
            double normalized = (val - 2048) / 500.0 * -1.0;
            if (ecgPoints.length >= 100) ecgPoints.removeAt(0);
            ecgPoints.add(normalized);
          }
        }
      });
    } catch (e) { print(e); }
  }

  Color getBatteryColor() {
    if (batteryLevel > 50) return Colors.green;
    if (batteryLevel > 20) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- DRAWER ---
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
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Inicio"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text("Compartir mi Código"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QrShareScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Historial Médico"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text("Bitácora de Síntomas"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SymptomScreen()));
              },
            ),
            const Divider(),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (_, mode, __) {
                return SwitchListTile(
                  title: const Text("Modo Oscuro"),
                  secondary: Icon(mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
                  value: mode == ThemeMode.dark,
                  onChanged: (val) {
                    themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  },
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
              onTap: () async {
                _disconnect();
                Navigator.pop(context);
                await _authService.cerrarSesion();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      
      // --- APPBAR ---
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
                  Text(isConnected ? "$batteryLevel%" : "--%", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Icon(Icons.battery_std, color: getBatteryColor()),
                ],
              ),
            ),
          )
        ],
      ),
      
      // --- BODY ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado y BPM
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Estado del Sensor", style: TextStyle(color: Colors.grey)),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 12, color: isConnected ? Colors.green : Colors.red),
                        const SizedBox(width: 6),
                        Text(
                          isConnected ? "CONECTADO" : (isScanning ? "BUSCANDO..." : "DESCONECTADO"), 
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

            // Gráfica
            const Text("Señal en Tiempo Real (AD8232)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(painter: ECGPainter(ecgPoints)),
              ),
            ),

            const SizedBox(height: 20),

            // BOTÓN CONEXIÓN
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected ? Colors.red.shade100 : (isScanning ? Colors.orange.shade100 : Colors.teal),
                  foregroundColor: isConnected ? Colors.red : (isScanning ? Colors.orange : Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: isScanning ? null : (isConnected ? _disconnect : _startScan),
                icon: isScanning 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : Icon(isConnected ? Icons.bluetooth_disabled : Icons.bluetooth),
                label: Text(
                  isConnected ? "DESCONECTAR SENSOR" : (isScanning ? "BUSCANDO..." : "ESCANEAR Y CONECTAR")
                ),
              ),
            ),

            const SizedBox(height: 12),

            // BOTÓN GUARDAR
            if (isConnected)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text("GUARDAR LECTURA ACTUAL EN NUBE"),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Guardando datos reales...")));
                    await _authService.guardarMedicion(bpm: bpm > 0 ? bpm : 0, datosOnda: ecgPoints);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Lectura guardada!"), backgroundColor: Colors.green));
                  },
                ),
              ),

            const SizedBox(height: 30),
            const Divider(),
            
            // Datos Fisiológicos
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
                    Row(
                      children: [
                        Expanded(child: _buildInfoField("Edad", "$displayEdad años")),
                        const SizedBox(width: 10),
                        Expanded(child: _buildInfoField("Peso", "$displayPeso kg")),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildInfoField("Nombre", displayNombre)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildInfoField("Altura", "$displayAltura cm")),
                      ],
                    ),
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

// ---------------------------------------------------------------------------
// DASHBOARD DEL MÉDICO
// ---------------------------------------------------------------------------
class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final FirebaseService _authService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              accountName: const Text("Médico", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text(_authService.getUserEmail() ?? "doctor@hospital.com"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.medical_services, size: 40, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Inicio"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text("Mi Perfil"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              },
            ),
            const Divider(),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (_, mode, __) {
                return SwitchListTile(
                  title: const Text("Modo Oscuro"),
                  secondary: Icon(mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
                  value: mode == ThemeMode.dark,
                  onChanged: (val) {
                    themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  },
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _authService.cerrarSesion();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Panel Médico"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: _authService.obtenerMisPacientes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text("No tienes pacientes asignados.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  const Text("Usa el botón + para escanear un QR.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var pacienteDoc = snapshot.data!.docs[index];
              var data = pacienteDoc.data() as Map<String, dynamic>;
              
              String nombre = data['nombre'] ?? "Paciente Sin Nombre";
              String email = data['email'] ?? "";
              var bio = data['datos_biometricos'] ?? {};
              String infoExtra = "Edad: ${bio['edad'] ?? '--'} | Peso: ${bio['peso'] ?? '--'}";

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(nombre[0].toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("$email\n$infoExtra"),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientDetailScreen(
                          pacienteId: pacienteDoc.id,
                          datosPaciente: data,
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
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: (){
           Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScanScreen()));
        },
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }
}

class ECGPainter extends CustomPainter {
  final List<double> points;
  ECGPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()..color = Colors.green.withOpacity(0.2)..strokeWidth = 0.5;
    double stepX = size.width / 20;
    double stepY = size.height / 10;
    for (double x = 0; x <= size.width; x += stepX) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += stepY) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final Paint wavePaint = Paint()..color = const Color(0xFF00FF00)..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final Path path = Path();
    
    if (points.isNotEmpty) {
      double xInterval = size.width / (points.length - 1);
      double startY = size.height / 2 - (points[0] * 20); 
      path.moveTo(0, startY);
      for (int i = 1; i < points.length; i++) {
        double x = i * xInterval;
        double y = size.height / 2 - (points[i] * 20);
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}