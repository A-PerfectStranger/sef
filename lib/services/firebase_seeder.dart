import 'package:cloud_firestore/cloud_firestore.dart';

/// Script para poblar Firebase con datos de prueba
/// 
/// IMPORTANTE: Este script debe ejecutarse MANUALMENTE desde la app
/// después de registrar un usuario de prueba.
/// 
/// Para ejecutarlo:
/// 1. Crea un botón temporal en el Dashboard
/// 2. Llama a FirebaseSeeder.seedData(userId)
/// 3. Verifica los datos en Firebase Console
/// 4. Elimina el botón temporal

class FirebaseSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Poblar base de datos con datos de prueba
  static Future<void> seedData(String userId) async {
    try {
      print('🌱 Iniciando población de datos...');

      // 1. Crear medicamentos de prueba en tratamiento_actual
      await _createMedicamentos(userId);

      // 2. Crear mensajes motivacionales
      await _createMensajesMotivationales();

      // 3. Crear videos de ayuda (opcional)
      // await _createVideosAyuda();

      print('✅ Datos poblados exitosamente');
    } catch (e) {
      print('❌ Error al poblar datos: $e');
      rethrow;
    }
  }

  /// Crear medicamentos de prueba
  static Future<void> _createMedicamentos(String userId) async {
    print('📋 Creando medicamentos...');

    final medicamentos = [
      {
        'nombre': 'Ibuprofeno',
        'nombres_conocidos': ['Advil', 'Motrin', 'Nurofen'],
        'dosis_mg': '400mg',
        'dosis_pastillas': '1 tableta',
        'contraindicaciones':
            'No tomar con el estómago vacío. Evitar si tiene problemas gástricos.',
        'indicaciones':
            'Para alivio del dolor e inflamación. Tomar con alimentos.',
        'notas': 'Tomar después de las comidas principales',
        'horarios': ['08:00', '14:00', '20:00'],
        'activo': true,
        'fecha_creacion': FieldValue.serverTimestamp(),
      },
      {
        'nombre': 'Omeprazol',
        'nombres_conocidos': ['Prilosec', 'Losec'],
        'dosis_mg': '20mg',
        'dosis_pastillas': '1 cápsula',
        'contraindicaciones':
            'No usar por más de 14 días sin consultar al médico.',
        'indicaciones':
            'Protector gástrico. Tomar 30 minutos antes del desayuno.',
        'notas': 'En ayunas, antes del desayuno',
        'horarios': ['07:30'],
        'activo': true,
        'fecha_creacion': FieldValue.serverTimestamp(),
      },
      {
        'nombre': 'Metotrexato',
        'nombres_conocidos': ['Rheumatrex', 'Trexall'],
        'dosis_mg': '15mg',
        'dosis_pastillas': '3 tabletas de 5mg',
        'contraindicaciones':
            'No tomar durante el embarazo. Evitar alcohol. Requiere monitoreo de laboratorio.',
        'indicaciones':
            'Para artritis reumatoide. Tomar una vez por semana el mismo día.',
        'notas': 'Solo los lunes. Suplementar con ácido fólico otros días',
        'horarios': ['09:00'],
        'activo': true,
        'fecha_creacion': FieldValue.serverTimestamp(),
      },
      {
        'nombre': 'Vitamina D3',
        'nombres_conocidos': ['Colecalciferol'],
        'dosis_mg': '1000 UI',
        'dosis_pastillas': '1 cápsula',
        'contraindicaciones': 'No exceder la dosis recomendada.',
        'indicaciones':
            'Suplemento vitamínico. Tomar con una comida que contenga grasas.',
        'notas': 'Mejora la absorción del calcio',
        'horarios': ['08:00'],
        'activo': true,
        'fecha_creacion': FieldValue.serverTimestamp(),
      },
      {
        'nombre': 'Paracetamol',
        'nombres_conocidos': ['Tylenol', 'Acetaminofén'],
        'dosis_mg': '500mg',
        'dosis_pastillas': '1 tableta',
        'contraindicaciones':
            'No exceder 4g al día. Evitar con problemas hepáticos.',
        'indicaciones': 'Para alivio del dolor y fiebre. Cada 6-8 horas según necesidad.',
        'notas': 'Tomar solo si hay dolor o fiebre',
        'horarios': ['10:00', '18:00'],
        'activo': true,
        'fecha_creacion': FieldValue.serverTimestamp(),
      },
    ];

    final batch = _firestore.batch();

    for (final medicamento in medicamentos) {
      final ref = _firestore
          .collection('users')
          .doc(userId)
          .collection('tratamiento_actual')
          .doc();
      batch.set(ref, medicamento);
    }

    await batch.commit();
    print('✅ ${medicamentos.length} medicamentos creados');
  }

  /// Crear mensajes motivacionales
  static Future<void> _createMensajesMotivationales() async {
    print('💬 Creando mensajes motivacionales...');

    final mensajes = {
      'inicio': {
        'frases': [
          'Déjanos cuidarte',
          'Tu salud es nuestra prioridad',
          'Cada día es una nueva oportunidad',
          'Estamos aquí para ti',
          'Juntos en tu camino al bienestar',
          'Un paso a la vez hacia la salud',
          'Tu constancia es tu mejor medicina',
          'Hoy es un gran día para cuidarte',
        ]
      },
      'dia_completado': {
        'frases': [
          '¡Increíble! Completaste tu rutina de hoy',
          'Cada día más cerca de tu mejor versión',
          '¡Eres imparable!',
          '¡Lo lograste! Tu constancia marca la diferencia',
          '¡Excelente trabajo! Sigue así',
          'Tu compromiso con tu salud es inspirador',
          '¡Fantástico! Otro día exitoso',
          '¡Bravo! Estás construyendo hábitos saludables',
          'Tu dedicación es admirable',
          '¡Perfecto! Mantén el ritmo',
        ]
      },
    };

    final batch = _firestore.batch();

    mensajes.forEach((tipo, data) {
      final ref = _firestore.collection('mensajes_motivacionales').doc(tipo);
      batch.set(ref, data);
    });

    await batch.commit();
    print('✅ Mensajes motivacionales creados');
  }

  /// Crear videos de ayuda (opcional - estructura de ejemplo)
  static Future<void> _createVideosAyuda() async {
    print('🎥 Creando videos de ayuda...');

    final articulos = ['cuello', 'hombro', 'codo', 'muñeca', 'rodilla', 'tobillo'];

    final videosEjemplo = {
      'cuello': [
        {
          'titulo': 'Ejercicios de movilidad cervical',
          'url': 'https://www.youtube.com/watch?v=ejemplo1',
          'tipo': 'youtube',
          'duracion': '5:30',
          'thumbnail': 'https://via.placeholder.com/300x200',
        },
        {
          'titulo': 'Estiramientos para aliviar tensión',
          'url': 'https://www.youtube.com/watch?v=ejemplo2',
          'tipo': 'youtube',
          'duracion': '8:15',
          'thumbnail': 'https://via.placeholder.com/300x200',
        },
      ],
      'hombro': [
        {
          'titulo': 'Fortalecimiento de manguito rotador',
          'url': 'https://www.youtube.com/watch?v=ejemplo3',
          'tipo': 'youtube',
          'duracion': '10:00',
          'thumbnail': 'https://via.placeholder.com/300x200',
        },
      ],
      'codo': [
        {
          'titulo': 'Ejercicios para epicondilitis',
          'url': 'https://www.youtube.com/watch?v=ejemplo4',
          'tipo': 'youtube',
          'duracion': '6:45',
          'thumbnail': 'https://via.placeholder.com/300x200',
        },
      ],
      'muñeca': [
        {
          'titulo': 'Movilidad y fuerza de muñeca',
          'url': 'https://www.youtube.com/watch?v=ejemplo5',
          'tipo': 'youtube',
          'duracion': '7:20',
          'thumbnail': 'https://via.placeholder.com/300x200',
        },
      ],
      'rodilla': [
        {
          'titulo': 'Fortalecimiento de cuádriceps',
          'url': 'https://www.youtube.com/watch?v=ejemplo6',
          'tipo': 'youtube',
          'duracion': '12:30',
          'thumbnail': 'https://via.placeholder.com/300x200',
        },
      ],
      'tobillo': [
        {
          'titulo': 'Ejercicios de propiocepción',
          'url': 'https://www.youtube.com/watch?v=ejemplo7',
          'tipo': 'youtube',
          'duracion': '9:00',
          'thumbnail': 'https://via.placeholder.com/300x200',
        },
      ],
    };

    final batch = _firestore.batch();

    videosEjemplo.forEach((articulacion, videos) {
      for (final video in videos) {
        final ref = _firestore
            .collection('videos_ayuda')
            .doc(articulacion)
            .collection('videos')
            .doc();
        batch.set(ref, video);
      }
    });

    await batch.commit();
    print('✅ Videos de ayuda creados');
  }

  /// Verificar si ya existen datos
  static Future<bool> hasExistingData(String userId) async {
    final medicamentosSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tratamiento_actual')
        .limit(1)
        .get();

    return medicamentosSnapshot.docs.isNotEmpty;
  }

  /// Limpiar datos de prueba
  static Future<void> clearTestData(String userId) async {
    print('🗑️ Limpiando datos de prueba...');

    // Eliminar medicamentos
    final medicamentos = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tratamiento_actual')
        .get();

    final batch = _firestore.batch();
    for (final doc in medicamentos.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    print('✅ Datos de prueba eliminados');
  }
}

/// Widget helper para ejecutar el seeder (agregar temporalmente al Dashboard)
/// 
/// Ejemplo de uso en dashboard_screen.dart:
/// 
/// FloatingActionButton(
///   onPressed: () async {
///     final uid = authProvider.firebaseUser!.uid;
///     await FirebaseSeeder.seedData(uid);
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text('Datos poblados correctamente')),
///     );
///     // Recargar medicamentos
///     medicamentosProvider.refresh(uid);
///   },
///   child: Icon(Icons.add),
/// )
