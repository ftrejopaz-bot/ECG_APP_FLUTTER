import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:borrador_proyecto/servicios/firebase_service.dart'; // Ajusta esta ruta si es necesario

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _service = FirebaseService();
  
  // Controladores
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  bool isLoading = true; 
  String rolUsuario = 'paciente'; // Variable para guardar el rol

  @override
  void initState() {
    super.initState();
    _cargarDatosActuales();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // 1. FUNCIÓN PARA DESCARGAR DATOS Y DETECTAR ROL
  void _cargarDatosActuales() async {
    try {
      DocumentSnapshot doc = await _service.getUserData();
      
      if (doc.exists && mounted) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
         print("DATOS DESCARGADOS DE FIREBASE: $data"); 
         print("ROL DETECTADO: ${data['rol']}");


        setState(() {
          // Detectamos el rol del usuario
          rolUsuario = data['rol'] ?? 'paciente';

          // El nombre es común para todos
          _nameController.text = data['nombre'] ?? '';
          
          // Solo cargamos datos biométricos SI es paciente
          if (rolUsuario == 'paciente' && data.containsKey('datos_biometricos')) {
            var bio = data['datos_biometricos'];
            _ageController.text = bio['edad']?.toString() ?? '';
            _weightController.text = bio['peso']?.toString() ?? '';
            _heightController.text = bio['altura']?.toString() ?? '';
          }
          
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      print("Error cargando perfil: $e");
    }
  }

  // 2. FUNCIÓN PARA GUARDAR CAMBIOS SEGÚN ROL
  void _guardarCambios() async {
    setState(() => isLoading = true);

    // Base de datos a actualizar (El nombre siempre va)
    Map<String, dynamic> datosActualizados = {
      'nombre': _nameController.text.trim(),
    };

    // Solo agregamos biométricos si es paciente
    if (rolUsuario == 'paciente') {
      datosActualizados['datos_biometricos'] = {
        'edad': int.tryParse(_ageController.text) ?? 0,
        'peso': double.tryParse(_weightController.text) ?? 0.0,
        'altura': int.tryParse(_heightController.text) ?? 0,
      };
    }

    String? error = await _service.actualizarPerfil(datosActualizados);

    if (mounted) {
      setState(() => isLoading = false);

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Perfil actualizado!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Volver
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $error"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        backgroundColor: rolUsuario == 'medico' ? Colors.blue : Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: rolUsuario == 'medico' ? Colors.blue.shade100 : Colors.teal.shade100,
                    child: Icon(
                      rolUsuario == 'medico' ? Icons.medical_services : Icons.person, 
                      size: 60, 
                      color: rolUsuario == 'medico' ? Colors.blue : Colors.teal
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rolUsuario == 'medico' ? "Perfil Profesional" : "Datos del Paciente",
                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  
                  // CAMPO NOMBRE (Visible para todos)
                  _buildTextField("Nombre Completo", _nameController, Icons.person),
                  
                  // CAMPOS BIOMÉTRICOS (Solo visibles si es Paciente)
                  if (rolUsuario == 'paciente') ...[
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Edad (años)", _ageController, Icons.cake, isNumber: true)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildTextField("Peso (kg)", _weightController, Icons.monitor_weight, isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildTextField("Altura (cm)", _heightController, Icons.height, isNumber: true),
                  ],

                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: rolUsuario == 'medico' ? Colors.blue : Colors.teal, 
                        foregroundColor: Colors.white
                      ),
                      onPressed: _guardarCambios,
                      child: const Text("GUARDAR CAMBIOS"),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}