import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. REGISTRO
  Future<String?> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
    required String rol, // "medico" o "paciente"
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;
      String? codigoVinculacion;

      if (rol == 'paciente') {
        codigoVinculacion = _generarCodigoAleatorio();
      }

      Map<String, dynamic> datosUsuario = {
        'uid': uid,
        'nombre': nombre,
        'email': email,
        'rol': rol,
        'fecha_registro': FieldValue.serverTimestamp(),
      };

      if (rol == 'paciente') {
        datosUsuario['codigo_vinculacion'] = codigoVinculacion;
        datosUsuario['medico_uid'] = null;
        datosUsuario['datos_biometricos'] = {'edad': 0, 'peso': 0.0, 'altura': 0};
      } else {
        datosUsuario['lista_pacientes'] = [];
        datosUsuario['especialidad'] = 'General';
      }

      await _db.collection('users').doc(uid).set(datosUsuario);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Error desconocido: $e";
    }
  }

  // 2. LOGIN
  Future<Map<String, dynamic>> iniciarSesion(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      String uid = userCredential.user!.uid;
      DocumentSnapshot docUsuario = await _db.collection('users').doc(uid).get();

      if (docUsuario.exists) {
        return {"status": "success", "rol": docUsuario['rol'], "nombre": docUsuario['nombre']};
      } else {
        return {"status": "error", "message": "Usuario no encontrado en BD"};
      }
    } on FirebaseAuthException catch (e) {
      return {"status": "error", "message": e.message ?? "Error de autenticación"};
    }
  }

  // 3. CERRAR SESIÓN
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  // 4. LEER DATOS USUARIO (Flexible: Mío o de otro)
  Future<DocumentSnapshot> getUserData({String? uid}) async {
    if (_auth.currentUser == null) throw Exception("No hay usuario");
    String targetUid = uid ?? _auth.currentUser!.uid;
    return await _db.collection('users').doc(targetUid).get();
  }

  // 5. ACTUALIZAR PERFIL
  Future<String?> actualizarPerfil(Map<String, dynamic> nuevosDatos) async {
    try {
      await _db.collection('users').doc(_auth.currentUser!.uid).update(nuevosDatos);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // 6. VINCULAR PACIENTE
  Future<String> vincularPaciente(String codigoIngresado) async {
    String uidMedico = _auth.currentUser!.uid;
    try {
      QuerySnapshot query = await _db.collection('users').where('codigo_vinculacion', isEqualTo: codigoIngresado).limit(1).get();
      if (query.docs.isEmpty) return "Error: Código no válido.";

      DocumentSnapshot docPaciente = query.docs.first;
      String uidPaciente = docPaciente.id;

      // Actualizar al médico (agregar a lista)
      await _db.collection('users').doc(uidMedico).update({
        'lista_pacientes': FieldValue.arrayUnion([uidPaciente])
      });
      
      // Actualizar al paciente (asignar médico)
      await _db.collection('users').doc(uidPaciente).update({'medico_uid': uidMedico});

      return "¡Éxito! Paciente vinculado.";
    } catch (e) {
      return "Error al vincular: $e";
    }
  }

  // 7. GUARDAR MEDICIÓN
  Future<void> guardarMedicion({required int bpm, required List<double> datosOnda}) async {
    await _db.collection('mediciones').add({
      'paciente_uid': _auth.currentUser!.uid,
      'fecha': FieldValue.serverTimestamp(),
      'bpm_promedio': bpm,
      'duracion_segundos': 30,
      'datos_onda': datosOnda,
    });
  }

  // 8. OBTENER HISTORIAL (Flexible)
  Stream<QuerySnapshot> obtenerHistorialPaciente({String? uid}) {
    String targetUid = uid ?? _auth.currentUser!.uid;
    return _db.collection('mediciones')
        .where('paciente_uid', isEqualTo: targetUid)
        .orderBy('fecha', descending: true)
        .snapshots();
  }
  
  // 9. OBTENER PACIENTES ASIGNADOS (Médico)
  Stream<QuerySnapshot> obtenerMisPacientes() {
    String uid = _auth.currentUser!.uid;
    return _db.collection('users').where('medico_uid', isEqualTo: uid).snapshots();
  }

  // 10. GUARDAR SÍNTOMA
  Future<void> registrarSintoma(String descripcion) async {
    await _db.collection('bitacora_sintomas').add({
      'paciente_uid': _auth.currentUser!.uid,
      'fecha': FieldValue.serverTimestamp(),
      'descripcion': descripcion,
    });
  }

  // 11. LEER BITÁCORA (Flexible)
  Stream<QuerySnapshot> obtenerBitacora({String? uid}) {
    String targetUid = uid ?? _auth.currentUser!.uid;
    return _db.collection('bitacora_sintomas')
        .where('paciente_uid', isEqualTo: targetUid)
        .orderBy('fecha', descending: true)
        .snapshots();
  }
  
  // 12. ACTUALIZAR SÍNTOMA
  Future<void> actualizarSintoma(String docId, String nuevaDescripcion) async {
    await _db.collection('bitacora_sintomas').doc(docId).update({'descripcion': nuevaDescripcion});
  }

  // 13. ELIMINAR SÍNTOMA
  Future<void> eliminarSintoma(String docId) async {
    await _db.collection('bitacora_sintomas').doc(docId).delete();
  }

  String _generarCodigoAleatorio() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }
}