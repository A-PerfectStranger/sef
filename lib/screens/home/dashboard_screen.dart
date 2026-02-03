import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medicamentos_provider.dart';
import '../../widgets/medicamento_card.dart';
import '../../services/notification_service.dart';
import '../../services/firebase_seeder.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  bool _hasRequestedPermissions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _requestNotificationPermissions();
    });
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final medicamentosProvider = Provider.of<MedicamentosProvider>(
      context,
      listen: false,
    );

    if (authProvider.firebaseUser != null) {
      await medicamentosProvider.loadMedicamentos(
        authProvider.firebaseUser!.uid,
      );
    }
  }

  Future<void> _requestNotificationPermissions() async {
    if (_hasRequestedPermissions) return;
    _hasRequestedPermissions = true;

    final notificationService = NotificationService();
    final granted = await notificationService.requestPermissions();

    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Las notificaciones te ayudarán a recordar tus medicamentos',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final medicamentosProvider = Provider.of<MedicamentosProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.turquoise.o10(), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(authProvider),

              // Body
              Expanded(
                child: medicamentosProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : medicamentosProvider.diaCompletado
                    ? _buildDayCompletedView()
                    : medicamentosProvider.hasPendientes
                    ? _buildCardStack(authProvider, medicamentosProvider)
                    : _buildEmptyState(),
              ),

              // Footer con botones
              if (medicamentosProvider.hasPendientes)
                _buildActionButtons(authProvider, medicamentosProvider),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final uid = authProvider.firebaseUser!.uid;

          // Importar el seeder (asegúrate de tener el import arriba)
          final hasData = await FirebaseSeeder.hasExistingData(uid);

          if (hasData) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ya existen datos de prueba'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          // Mostrar loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Poblando base de datos...'),
              duration: Duration(seconds: 2),
            ),
          );

          // Poblar datos
          await FirebaseSeeder.seedData(uid);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Datos poblados correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Recargar medicamentos
          await medicamentosProvider.refresh(uid);
        },
        icon: const Icon(Icons.science),
        label: const Text('Poblar DB'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  Widget _buildHeader(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${authProvider.userModel?.nombre ?? "Amigo"}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Consumer<MedicamentosProvider>(
                builder: (context, provider, _) {
                  if (provider.diaCompletado) {
                    return const Text(
                      '¡Día completado! 🎉',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                  return Text(
                    '${provider.medicamentosRestantes} medicamento${provider.medicamentosRestantes == 1 ? "" : "s"} pendiente${provider.medicamentosRestantes == 1 ? "" : "s"}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ],
          ),
          // Avatar con racha
          _buildProfileAvatar(authProvider),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(AuthProvider authProvider) {
    final nombre = authProvider.userModel?.nombre ?? "U";
    final inicial = nombre[0].toUpperCase();
    final racha = authProvider.userModel?.rachaActual ?? 0;

    return Stack(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              inicial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (racha > 0)
          Positioned(
            right: -5,
            bottom: -5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.goldenYellow,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Text('🔥', style: TextStyle(fontSize: 12)),
            ),
          ),
      ],
    );
  }

  Widget _buildCardStack(
    AuthProvider authProvider,
    MedicamentosProvider medicamentosProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CardSwiper(
        controller: _swiperController,
        cardsCount: medicamentosProvider.medicamentosPendientes.length,
        numberOfCardsDisplayed: 3,
        backCardOffset: const Offset(0, 40),
        padding: const EdgeInsets.all(24),
        duration: const Duration(milliseconds: 300),
        maxAngle: 30,
        threshold: 50,
        scale: 0.9,
        isLoop: false,
        onSwipe: (previousIndex, currentIndex, direction) => _handleSwipe(
          authProvider,
          medicamentosProvider,
          previousIndex,
          direction,
        ),
        cardBuilder: (context, index, horizontalThreshold, verticalThreshold) {
          final medicamento =
              medicamentosProvider.medicamentosPendientes[index];
          return MedicamentoCard(
            medicamento: medicamento,
            userName: authProvider.userModel?.nombre ?? "Amigo",
          );
        },
      ),
    );
  }

  bool _handleSwipe(
    AuthProvider authProvider,
    MedicamentosProvider medicamentosProvider,
    int previousIndex,
    CardSwiperDirection direction,
  ) {
    final medicamento =
        medicamentosProvider.medicamentosPendientes[previousIndex];

    if (direction == CardSwiperDirection.right) {
      // Tomado
      medicamentosProvider.marcarComoTomado(
        authProvider.firebaseUser!.uid,
        medicamento,
      );
    } else if (direction == CardSwiperDirection.left) {
      // Saltado
      medicamentosProvider.marcarComoSaltado(
        authProvider.firebaseUser!.uid,
        medicamento,
      );
    }

    return true;
  }

  Widget _buildActionButtons(
    AuthProvider authProvider,
    MedicamentosProvider medicamentosProvider,
  ) {
    final medicamento = medicamentosProvider.medicamentosPendientes.first;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Botón Saltar (izquierda)
          _buildActionButton(
            icon: Icons.close,
            color: AppColors.error,
            onTap: () {
              _swiperController.swipe(CardSwiperDirection.left);
            },
          ),

          // Botón Detalles (centro)
          _buildActionButton(
            icon: Icons.info_outline,
            color: AppColors.info,
            size: 60,
            iconSize: 32,
            onTap: () {
              _showMedicamentoDetails(medicamento);
            },
          ),

          // Botón Tomado (derecha)
          _buildActionButton(
            icon: Icons.check,
            color: AppColors.success,
            onTap: () {
              _swiperController.swipe(CardSwiperDirection.right);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 70,
    double iconSize = 36,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.o30(), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }

  void _showMedicamentoDetails(dynamic medicamento) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight.o30(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicamento.nombre,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      'Dosis',
                      '${medicamento.dosisPastillas ?? ""} ${medicamento.dosisMg ?? ""}',
                    ),
                    if (medicamento.nombresConocidos != null &&
                        medicamento.nombresConocidos!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'También conocido como',
                        medicamento.nombresConocidos!.join(', '),
                      ),
                    ],
                    if (medicamento.indicaciones != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Indicaciones',
                        medicamento.indicaciones!,
                      ),
                    ],
                    if (medicamento.contraindicaciones != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Contraindicaciones',
                        medicamento.contraindicaciones!,
                      ),
                    ],
                    if (medicamento.notas != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow('Notas', medicamento.notas!),
                    ],
                  ],
                ),
              ),
            ),

            // Close button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.turquoise,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildDayCompletedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            Text(
              '¡Día completado!',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Has tomado todos tus medicamentos del día.\n¡Sigue así!',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication, size: 80, color: AppColors.textLight),
            const SizedBox(height: 24),
            Text(
              'No hay medicamentos pendientes',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Tu médico aún no ha configurado tu tratamiento',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
