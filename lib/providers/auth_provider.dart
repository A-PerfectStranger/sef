import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _initAuthListener();
  }

  /// Inicializar listener del estado de autenticación
  void _initAuthListener() {
    _firebaseService.authStateChanges.listen((User? user) {
      _firebaseUser = user;
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  /// Cargar perfil del usuario
  Future<void> _loadUserProfile(String uid) async {
    try {
      _userModel = await _firebaseService.getUserProfile(uid);
      notifyListeners();
    } catch (e) {
      print('Error al cargar perfil: $e');
    }
  }

  /// Registrar nuevo usuario
  Future<bool> register(String email, String password, String nombre) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await _firebaseService.registerWithEmail(email, password);
      
      if (user != null) {
        // Crear perfil en Firestore
        final userModel = UserModel(
          uid: user.uid,
          email: email,
          nombre: nombre,
          fechaRegistro: DateTime.now(),
        );
        
        await _firebaseService.createUserProfile(userModel);
        _userModel = userModel;
        
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Iniciar sesión
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await _firebaseService.signInWithEmail(email, password);
      
      if (user != null) {
        await _loadUserProfile(user.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      _firebaseUser = null;
      _userModel = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Actualizar perfil del usuario
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      if (_firebaseUser == null) return false;

      _isLoading = true;
      notifyListeners();

      await _firebaseService.updateUserProfile(_firebaseUser!.uid, data);
      await _loadUserProfile(_firebaseUser!.uid);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Actualizar racha
  Future<void> updateRacha(int rachaActual, int rachaMaxima) async {
    if (_userModel == null) return;

    _userModel = _userModel!.copyWith(
      rachaActual: rachaActual,
      rachaMaxima: rachaMaxima,
    );
    notifyListeners();

    // Actualizar en Firestore
    if (_firebaseUser != null) {
      await updateProfile({
        'racha_actual': rachaActual,
        'racha_maxima': rachaMaxima,
      });
    }
  }
}
