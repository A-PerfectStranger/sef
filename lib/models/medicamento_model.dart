import 'package:cloud_firestore/cloud_firestore.dart';

class MedicamentoModel {
  final String id;
  final String nombre;
  final List<String>? nombresConocidos;
  final String? dosisMg;
  final String? dosisPastillas;
  final String? contraindicaciones;
  final String? indicaciones;
  final String? notas;
  final List<String> horarios;
  final bool activo;
  final DateTime? fechaCreacion;

  MedicamentoModel({
    required this.id,
    required this.nombre,
    this.nombresConocidos,
    this.dosisMg,
    this.dosisPastillas,
    this.contraindicaciones,
    this.indicaciones,
    this.notas,
    required this.horarios,
    this.activo = true,
    this.fechaCreacion,
  });

  // Convertir desde Firestore
  factory MedicamentoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicamentoModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      nombresConocidos: data['nombres_conocidos'] != null 
          ? List<String>.from(data['nombres_conocidos']) 
          : null,
      dosisMg: data['dosis_mg'],
      dosisPastillas: data['dosis_pastillas'],
      contraindicaciones: data['contraindicaciones'],
      indicaciones: data['indicaciones'],
      notas: data['notas'],
      horarios: data['horarios'] != null 
          ? List<String>.from(data['horarios']) 
          : [],
      activo: data['activo'] ?? true,
      fechaCreacion: data['fecha_creacion'] != null 
          ? (data['fecha_creacion'] as Timestamp).toDate() 
          : null,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'nombres_conocidos': nombresConocidos,
      'dosis_mg': dosisMg,
      'dosis_pastillas': dosisPastillas,
      'contraindicaciones': contraindicaciones,
      'indicaciones': indicaciones,
      'notas': notas,
      'horarios': horarios,
      'activo': activo,
      'fecha_creacion': fechaCreacion != null 
          ? Timestamp.fromDate(fechaCreacion!) 
          : FieldValue.serverTimestamp(),
    };
  }

  // Copiar con modificaciones
  MedicamentoModel copyWith({
    String? id,
    String? nombre,
    List<String>? nombresConocidos,
    String? dosisMg,
    String? dosisPastillas,
    String? contraindicaciones,
    String? indicaciones,
    String? notas,
    List<String>? horarios,
    bool? activo,
    DateTime? fechaCreacion,
  }) {
    return MedicamentoModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      nombresConocidos: nombresConocidos ?? this.nombresConocidos,
      dosisMg: dosisMg ?? this.dosisMg,
      dosisPastillas: dosisPastillas ?? this.dosisPastillas,
      contraindicaciones: contraindicaciones ?? this.contraindicaciones,
      indicaciones: indicaciones ?? this.indicaciones,
      notas: notas ?? this.notas,
      horarios: horarios ?? this.horarios,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  // Obtener hora más cercana
  String? getProximaHora() {
    if (horarios.isEmpty) return null;
    
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;
    
    for (final horario in horarios) {
      final parts = horario.split(':');
      if (parts.length != 2) continue;
      
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;
      
      final medicationTime = hour * 60 + minute;
      
      if (medicationTime >= currentTime) {
        return horario;
      }
    }
    
    // Si ya pasaron todas las horas de hoy, devolver la primera de mañana
    return horarios.first;
  }

  // Verificar si tiene horario pendiente hoy
  bool tieneHorarioPendiente() {
    if (horarios.isEmpty) return false;
    
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;
    
    for (final horario in horarios) {
      final parts = horario.split(':');
      if (parts.length != 2) continue;
      
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;
      
      final medicationTime = hour * 60 + minute;
      
      if (medicationTime >= currentTime) {
        return true;
      }
    }
    
    return false;
  }
}

// Modelo para el historial de medicamentos
class HistorialMedicamento {
  final String medicamentoId;
  final bool tomado;
  final DateTime? horaConfirmacion;
  final bool saltado;

  HistorialMedicamento({
    required this.medicamentoId,
    required this.tomado,
    this.horaConfirmacion,
    required this.saltado,
  });

  factory HistorialMedicamento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HistorialMedicamento(
      medicamentoId: doc.id,
      tomado: data['tomado'] ?? false,
      horaConfirmacion: data['hora_confirmacion'] != null 
          ? (data['hora_confirmacion'] as Timestamp).toDate() 
          : null,
      saltado: data['saltado'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tomado': tomado,
      'hora_confirmacion': horaConfirmacion != null 
          ? Timestamp.fromDate(horaConfirmacion!) 
          : null,
      'saltado': saltado,
    };
  }
}
