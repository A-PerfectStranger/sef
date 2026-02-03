import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String nombre;
  final DateTime? fechaNacimiento;
  final String? genero;
  final DateTime fechaRegistro;
  final int rachaActual;
  final int rachaMaxima;
  final int nivelActual;

  UserModel({
    required this.uid,
    required this.email,
    required this.nombre,
    this.fechaNacimiento,
    this.genero,
    required this.fechaRegistro,
    this.rachaActual = 0,
    this.rachaMaxima = 0,
    this.nivelActual = 0,
  });

  // Convertir desde Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      nombre: data['nombre'] ?? '',
      fechaNacimiento: data['fechaNacimiento'] != null 
          ? (data['fechaNacimiento'] as Timestamp).toDate() 
          : null,
      genero: data['genero'],
      fechaRegistro: (data['fechaRegistro'] as Timestamp).toDate(),
      rachaActual: data['racha_actual'] ?? 0,
      rachaMaxima: data['racha_maxima'] ?? 0,
      nivelActual: data['nivel_actual'] ?? 0,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nombre': nombre,
      'fechaNacimiento': fechaNacimiento != null 
          ? Timestamp.fromDate(fechaNacimiento!) 
          : null,
      'genero': genero,
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
      'racha_actual': rachaActual,
      'racha_maxima': rachaMaxima,
      'nivel_actual': nivelActual,
    };
  }

  // Copiar con modificaciones
  UserModel copyWith({
    String? uid,
    String? email,
    String? nombre,
    DateTime? fechaNacimiento,
    String? genero,
    DateTime? fechaRegistro,
    int? rachaActual,
    int? rachaMaxima,
    int? nivelActual,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      genero: genero ?? this.genero,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      rachaActual: rachaActual ?? this.rachaActual,
      rachaMaxima: rachaMaxima ?? this.rachaMaxima,
      nivelActual: nivelActual ?? this.nivelActual,
    );
  }
}
