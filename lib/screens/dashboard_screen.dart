import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/models/capture_angle.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/capture_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final captureState = ref.watch(captureProvider);
    final userName = authState.user?.name ?? 'Kullanıcı';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Self-Capture Tool'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Karşılama mesajı
            Text(
              'Merhaba, $userName',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fotoğraf çekimini başlatmak için aşağıdaki butona tıklayın',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // 5 fotoğraf açısı için grid
            Text(
              'Çekilecek Açılar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: CaptureAngle.values.length,
              itemBuilder: (context, index) {
                final angle = CaptureAngle.values[index];
                final isCaptured = captureState.isAngleCaptured(angle);

                return _AngleCard(
                  angle: angle,
                  isCaptured: isCaptured,
                );
              },
            ),
            const SizedBox(height: 32),

            // İlerleme göstergesi
            if (captureState.completedCount > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İlerleme: ${captureState.completedCount}/${CaptureAngle.values.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: captureState.completedCount / CaptureAngle.values.length,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 32),
                ],
              ),

            // Fotoğraf çekimini başlat butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/instructions');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Fotoğraf Çekimini Başlat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AngleCard extends StatelessWidget {
  final CaptureAngle angle;
  final bool isCaptured;

  const _AngleCard({
    required this.angle,
    required this.isCaptured,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isCaptured ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCaptured ? Colors.green : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: isCaptured ? Colors.green : Colors.grey.shade300,
            child: Icon(
              _getIconForAngle(angle),
              color: isCaptured ? Colors.white : Colors.grey.shade600,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            angle.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isCaptured ? Colors.green.shade700 : Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (isCaptured)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForAngle(CaptureAngle angle) {
    switch (angle) {
      case CaptureAngle.frontFace:
        return Icons.face;
      case CaptureAngle.leftSide:
        return Icons.face_3;
      case CaptureAngle.rightSide:
        return Icons.face_4;
      case CaptureAngle.topVertex:
        return Icons.face_5;
      case CaptureAngle.backDonor:
        return Icons.face_6;
    }
  }
}

