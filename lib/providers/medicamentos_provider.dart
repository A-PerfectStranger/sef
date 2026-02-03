import 'package:flutter/foundation.dart';
import '../models/medicamento_model.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class MedicamentosProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();

  List<MedicamentoModel> _medicamentos = [];
  List<MedicamentoModel> _medicamentosPendientes = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _diaCompletado = false;

  // Getters
  List<MedicamentoModel> get medicamentos => _medicamentos;
  List<MedicamentoModel> get medicamentosPendientes => _medicamentosPendientes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get diaCompletado => _diaCompletado;
  int get totalMedicamentos => _medicamentos.length;
  int get medicamentosRestantes => _medicamentosPendientes.length;

  /// Cargar medicamentos activos del usuario
  Future<void> loadMedicamentos(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      _medicamentos = await _firebaseService.getMedicamentosActivos(uid);
      await _updateMedicamentosPendientes(uid);

      _isLoading = false;
      notifyListeners();

      // Programar notificaciones
      await _scheduleNotifications();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualizar lista de medicamentos pendientes
  Future<void> _updateMedicamentosPendientes(String uid) async {
    try {
      final historial = await _firebaseService.getHistorialDia(uid, DateTime.now());
      final historialIds = historial.map((h) => h.medicamentoId).toSet();

      _medicamentosPendientes = _medicamentos
          .where((m) => !historialIds.contains(m.id))
          .toList();

      _diaCompletado = _medicamentosPendientes.isEmpty && _medicamentos.isNotEmpty;
    } catch (e) {
      print('Error al actualizar pendientes: $e');
    }
  }

  /// Registrar medicamento como tomado
  Future<void> marcarComoTomado(String uid, MedicamentoModel medicamento) async {
    try {
      await _firebaseService.registrarMedicamentoTomado(uid, medicamento.id);
      
      // Remover de pendientes
      _medicamentosPendientes.removeWhere((m) => m.id == medicamento.id);
      
      // Verificar si completó el día
      if (_medicamentosPendientes.isEmpty) {
        _diaCompletado = true;
        // Mostrar celebración
        await _showDayCompletedNotification();
      }

      notifyListeners();

      // Cancelar notificación
      await _notificationService.cancelNotification(medicamento.id.hashCode);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Registrar medicamento como saltado
  Future<void> marcarComoSaltado(String uid, MedicamentoModel medicamento) async {
    try {
      await _firebaseService.registrarMedicamentoSaltado(uid, medicamento.id);
      
      // Remover de pendientes
      _medicamentosPendientes.removeWhere((m) => m.id == medicamento.id);
      
      notifyListeners();

      // Cancelar notificación
      await _notificationService.cancelNotification(medicamento.id.hashCode);

      // Verificar si rompió la racha
      final todosLosMedicamentosSaltados = _medicamentos.length ==
          (await _firebaseService.getHistorialDia(uid, DateTime.now()))
              .where((h) => h.saltado)
              .length;

      if (todosLosMedicamentosSaltados) {
        await _notificationService.showStreakBrokenMotivation();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Programar notificaciones para medicamentos
  Future<void> _scheduleNotifications() async {
    final hasPermissions = await _notificationService.arePermissionsGranted();
    if (!hasPermissions) return;

    for (final medicamento in _medicamentosPendientes) {
      for (final horario in medicamento.horarios) {
        final parts = horario.split(':');
        if (parts.length != 2) continue;

        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;

        await _notificationService.scheduleMedicationNotification(
          id: '${medicamento.id}_$horario'.hashCode,
          medicationName: medicamento.nombre,
          dose: medicamento.dosisPastillas ?? medicamento.dosisMg ?? '',
          hour: hour,
          minute: minute,
        );
      }
    }
  }

  /// Mostrar notificación de día completado
  Future<void> _showDayCompletedNotification() async {
    final frase = await _firebaseService.getFraseMotivaacional('dia_completado');
    await _notificationService.showNotification(
      id: 1000,
      title: '🎉 ¡Día completado!',
      body: frase,
    );
  }

  /// Obtener próximo medicamento
  MedicamentoModel? get proximoMedicamento {
    if (_medicamentosPendientes.isEmpty) return null;

    // Ordenar por hora más cercana
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    _medicamentosPendientes.sort((a, b) {
      final horaA = a.getProximaHora();
      final horaB = b.getProximaHora();

      if (horaA == null) return 1;
      if (horaB == null) return -1;

      final minutesA = _horaToMinutes(horaA);
      final minutesB = _horaToMinutes(horaB);

      return minutesA.compareTo(minutesB);
    });

    return _medicamentosPendientes.first;
  }

  int _horaToMinutes(String hora) {
    final parts = hora.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  /// Recargar medicamentos
  Future<void> refresh(String uid) async {
    await loadMedicamentos(uid);
  }

  /// Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Verificar si hay medicamentos pendientes
  bool get hasPendientes => _medicamentosPendientes.isNotEmpty;
}
