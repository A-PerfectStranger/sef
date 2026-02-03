import 'package:flutter/material.dart';
import '../config/colors.dart';
import '../models/medicamento_model.dart';

class MedicamentoCard extends StatelessWidget {
  final MedicamentoModel medicamento;
  final String userName;

  const MedicamentoCard({
    super.key,
    required this.medicamento,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.turquoise.o30(),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Patrón de fondo
            Positioned.fill(child: CustomPaint(painter: PatternPainter())),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Icono del medicamento
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.o30(),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Center(
                      child: Text('💊', style: TextStyle(fontSize: 60)),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Mensaje principal
                  Text(
                    'Hoy toca ${medicamento.nombre}, $userName',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Hora
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.o20(),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getHoraDisplay(),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Dosis
                  if (medicamento.dosisPastillas != null ||
                      medicamento.dosisMg != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.o20(),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getDosisDisplay(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Instrucciones de swipe
                  Text(
                    'Desliza ← para saltar o → para confirmar',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white.o80()),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getHoraDisplay() {
    final proximaHora = medicamento.getProximaHora();
    if (proximaHora != null) {
      return proximaHora;
    }
    if (medicamento.horarios.isNotEmpty) {
      return medicamento.horarios.first;
    }
    return 'Sin hora definida';
  }

  String _getDosisDisplay() {
    final List<String> parts = [];

    if (medicamento.dosisPastillas != null) {
      parts.add(medicamento.dosisPastillas!);
    }

    if (medicamento.dosisMg != null) {
      parts.add(medicamento.dosisMg!);
    }

    return parts.join(' - ');
  }
}

// Painter para el patrón de fondo
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.o05()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const spacing = 40.0;

    // Dibujar círculos
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 10, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
