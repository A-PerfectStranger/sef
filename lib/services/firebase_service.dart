import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/medicamento_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== AUTENTICACIÓN ====================
  
  /// Registrar nuevo usuario
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Iniciar sesión
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Obtener usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Stream del estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Manejar excepciones de autenticación
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado. Intenta iniciar sesión.';
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta. Inténtalo de nuevo.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }

  // ==================== USUARIOS ====================

  /// Crear perfil de usuario en Firestore
  Future<void> createUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap());
    } catch (e) {
      throw 'Error al crear perfil: $e';
    }
  }

  /// Obtener perfil de usuario
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Error al obtener perfil: $e';
    }
  }

  /// Actualizar perfil de usuario
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw 'Error al actualizar perfil: $e';
    }
  }

  /// Stream del perfil de usuario
  Stream<UserModel?> getUserProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // ==================== MEDICAMENTOS ====================

  /// Obtener medicamentos activos del tratamiento actual
  Future<List<MedicamentoModel>> getMedicamentosActivos(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('tratamiento_actual')
          .where('activo', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => MedicamentoModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Error al obtener medicamentos: $e';
    }
  }

  /// Stream de medicamentos activos
  Stream<List<MedicamentoModel>> getMedicamentosActivosStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('tratamiento_actual')
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicamentoModel.fromFirestore(doc))
            .toList());
  }

  /// Registrar medicamento como tomado
  Future<void> registrarMedicamentoTomado(
    String uid,
    String medicamentoId,
  ) async {
    try {
      final fecha = DateTime.now();
      final fechaStr = _formatDate(fecha);

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('historial_medicamentos')
          .doc(fechaStr)
          .collection('medicamentos')
          .doc(medicamentoId)
          .set({
        'tomado': true,
        'hora_confirmacion': FieldValue.serverTimestamp(),
        'saltado': false,
      });

      // Actualizar racha si es necesario
      await _actualizarRacha(uid);
    } catch (e) {
      throw 'Error al registrar medicamento: $e';
    }
  }

  /// Registrar medicamento como saltado
  Future<void> registrarMedicamentoSaltado(
    String uid,
    String medicamentoId,
  ) async {
    try {
      final fecha = DateTime.now();
      final fechaStr = _formatDate(fecha);

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('historial_medicamentos')
          .doc(fechaStr)
          .collection('medicamentos')
          .doc(medicamentoId)
          .set({
        'tomado': false,
        'hora_confirmacion': FieldValue.serverTimestamp(),
        'saltado': true,
      });

      // Verificar si rompió la racha
      await _actualizarRacha(uid);
    } catch (e) {
      throw 'Error al registrar medicamento saltado: $e';
    }
  }

  /// Obtener historial de medicamentos de un día
  Future<List<HistorialMedicamento>> getHistorialDia(
    String uid,
    DateTime fecha,
  ) async {
    try {
      final fechaStr = _formatDate(fecha);
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('historial_medicamentos')
          .doc(fechaStr)
          .collection('medicamentos')
          .get();

      return snapshot.docs
          .map((doc) => HistorialMedicamento.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Error al obtener historial: $e';
    }
  }

  /// Verificar si ya se completó el día
  Future<bool> isDiaCompletado(String uid) async {
    try {
      final medicamentos = await getMedicamentosActivos(uid);
      final historial = await getHistorialDia(uid, DateTime.now());

      if (medicamentos.isEmpty) return false;

      // Verificar que todos los medicamentos fueron tomados
      final medicamentosTomados = historial
          .where((h) => h.tomado)
          .map((h) => h.medicamentoId)
          .toSet();

      return medicamentos.every(
        (m) => medicamentosTomados.contains(m.id),
      );
    } catch (e) {
      return false;
    }
  }

  // ==================== RACHA ====================

  /// Actualizar racha del usuario
  Future<void> _actualizarRacha(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      int rachaActual = userData['racha_actual'] ?? 0;
      int rachaMaxima = userData['racha_maxima'] ?? 0;

      // Verificar si el día de hoy está completo
      final diaCompleto = await isDiaCompletado(uid);

      if (diaCompleto) {
        rachaActual++;
        if (rachaActual > rachaMaxima) {
          rachaMaxima = rachaActual;
        }
      } else {
        // Verificar si rompió la racha (saltó todos los medicamentos)
        final historial = await getHistorialDia(uid, DateTime.now());
        final todosSaltados = historial.isNotEmpty &&
            historial.every((h) => h.saltado);

        if (todosSaltados) {
          rachaActual = 0;
        }
      }

      await _firestore.collection('users').doc(uid).update({
        'racha_actual': rachaActual,
        'racha_maxima': rachaMaxima,
      });
    } catch (e) {
      // No lanzar error para no interrumpir el flujo
      print('Error al actualizar racha: $e');
    }
  }

  // ==================== MENSAJES MOTIVACIONALES ====================

  /// Obtener frase motivacional aleatoria
  Future<String> getFraseMotivaacional(String tipo) async {
    try {
      final doc = await _firestore
          .collection('mensajes_motivacionales')
          .doc(tipo)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final frases = List<String>.from(data['frases'] ?? []);
        if (frases.isNotEmpty) {
          frases.shuffle();
          return frases.first;
        }
      }
      return _getFraseDefaultPorTipo(tipo);
    } catch (e) {
      return _getFraseDefaultPorTipo(tipo);
    }
  }

  String _getFraseDefaultPorTipo(String tipo) {
    switch (tipo) {
      case 'inicio':
        return 'Déjanos cuidarte';
      case 'dia_completado':
        return '¡Increíble! Completaste tu rutina de hoy';
      default:
        return 'Juntos en tu camino al bienestar';
    }
  }

  // ==================== UTILIDADES ====================

  /// Formatear fecha a string YYYYMMDD
  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
