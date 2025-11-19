import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../core/models/capture_angle.dart';
import '../core/providers/capture_provider.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captureState = ref.watch(captureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Özet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              'Tebrikler, Tüm Fotoğraflar Çekildi!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Çekilen fotoğrafları kontrol edin ve onaylayın',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Fotoğraf önizlemeleri
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: CaptureAngle.values.length,
              itemBuilder: (context, index) {
                final angle = CaptureAngle.values[index];
                final filePath = captureState.capturedPhotos[angle];

                return _PhotoPreviewCard(
                  angle: angle,
                  filePath: filePath,
                );
              },
            ),
            const SizedBox(height: 32),

            // Butonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Tekrar çek
                      ref.read(captureProvider.notifier).reset();
                      context.go('/camera');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Tekrar Çek'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Onayla ve gönder
                      _handleSubmit(context, ref);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Onayla ve Gönder'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit(BuildContext context, WidgetRef ref) {
    final captureState = ref.read(captureProvider);
    
    // Tüm fotoğrafların çekildiğini kontrol et
    if (!captureState.allCaptured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm fotoğrafları çekin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Fotoğrafları sunucuya gönder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gönderiliyor'),
        content: const Text('Fotoğraflar sunucuya gönderiliyor...'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Başarılı gönderim sonrası guide ekranına dön
              ref.read(captureProvider.notifier).reset();
              context.go('/guide');
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

class _PhotoPreviewCard extends StatelessWidget {
  final CaptureAngle angle;
  final String? filePath;

  const _PhotoPreviewCard({
    required this.angle,
    this.filePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filePath != null ? Colors.green : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fotoğraf önizlemesi
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: filePath != null && File(filePath!).existsSync()
                  ? Image.file(
                      File(filePath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
          ),
          // Açı adı
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(
                  filePath != null ? Icons.check_circle : Icons.cancel,
                  color: filePath != null ? Colors.green : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    angle.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: filePath != null ? Colors.green.shade700 : Colors.grey.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

