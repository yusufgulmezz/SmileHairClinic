import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/models/capture_angle.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/capture_provider.dart';

class GuideScreen extends ConsumerStatefulWidget {
  const GuideScreen({super.key});

  @override
  ConsumerState<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends ConsumerState<GuideScreen> {
  final PageController _pageController = PageController();
  final Color _accentColor = const Color(0xFF041332);
  int _currentPage = 0;

  int get _totalPages => 2 + _steps.length;

  late final List<_GuideStep> _steps = [
    _GuideStep(
      angle: CaptureAngle.frontFace,
      title: 'Ön Açı',
      description: 'Telefonu yüz hizasında tutarak tüm yüzünüzü kadraja alın.',
      assetPath: 'assets/front.png',
      tips: const [
        'Çekim sırasında ışık kaynağı yüzünüzün önünde olsun.',
        'Çene çizginizi net göstermek için başınızı dik tutun.',
      ],
    ),
    _GuideStep(
      angle: CaptureAngle.leftSide,
      title: 'Sol Profil',
      description: 'Başınızı sola çevirip kulak hizasından saç çizgisini gösterin.',
      assetPath: 'assets/left.png',
      tips: const [
        'Omuzlarınızı gevşetip sadece başınızı çevirin.',
        'Camera göz hizasında kalsın.',
      ],
    ),
    _GuideStep(
      angle: CaptureAngle.rightSide,
      title: 'Sağ Profil',
      description: 'Sağ taraftaki saç çizgisini net şekilde çerçeveleyin.',
      assetPath: 'assets/right.png',
      tips: const [
        'Başınızı hafifçe sağa çevirin, gözler ileri baksın.',
        'Kulak ve şakak bölgesi görünür olsun.',
      ],
    ),
    _GuideStep(
      angle: CaptureAngle.topVertex,
      title: 'Tepe Bölgesi',
      description: 'Telefonu hafif yukarı kaldırarak tepe bölgesini gösterin.',
      assetPath: 'assets/vertex.png',
      tips: const [
        'Omuzlarınızı sabit tutup sadece telefonu kaldırın.',
        'Işığın direkt tepeden gelmesine dikkat edin.',
      ],
    ),
    _GuideStep(
      angle: CaptureAngle.backDonor,
      title: 'Arka Donör',
      description: 'Başınızın arka kısmını kadraja alacak şekilde telefonu konumlandırın.',
      assetPath: 'assets/back.png',
      tips: const [
        'Mümkünse aynadan yardım alın.',
        'Boynunuzu dik tutarak saç yoğunluğunu gösterin.',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final captureState = ref.watch(captureProvider);
    final userName = authState.user?.name ?? 'Kullanıcı';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Merhaba $userName',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '5 adımda çekim rehberi',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Çıkış yap',
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalPages,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _GuideWelcomePage(accentColor: _accentColor);
                  } else if (index == 1) {
                    return _GuideTipsPage(accentColor: _accentColor);
                  } else {
                    final step = _steps[index - 2];
                    return _CaptureGuidePage(
                      step: step,
                      accentColor: _accentColor,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            _DotsIndicator(
              length: _totalPages,
              activeIndex: _currentPage,
              color: _accentColor,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hazır olduğunuzda çekime başlayın. Tamamlanan açı: ${captureState.completedCount}/${CaptureAngle.values.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Çekime Başla',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideWelcomePage extends StatelessWidget {
  final Color accentColor;

  const _GuideWelcomePage({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_camera,
              size: 100,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Hoş Geldiniz',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Self-Capture Tool ile 5 farklı açıdan fotoğraflarınızı çekerek saç analiz sürecini hızlandırabilirsiniz. Sensör destekli yönlendirmeler ve otomatik tetikleme ile profesyonel çekimler elde edin.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GuideTipsPage extends StatelessWidget {
  final Color accentColor;

  const _GuideTipsPage({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'İpuçları',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 32),
          _TipItem(
            icon: Icons.wb_sunny,
            color: accentColor,
            title: 'İyi Işık',
            description: 'Eşit aydınlatılmış bir ortam seçerek gölge oluşumunu azaltın.',
          ),
          const SizedBox(height: 24),
          _TipItem(
            icon: Icons.image,
            color: accentColor,
            title: 'Düz Arka Plan',
            description: 'Sade arka plan saç hattını net göstermeye yardımcı olur.',
          ),
          const SizedBox(height: 24),
          _TipItem(
            icon: Icons.face,
            color: accentColor,
            title: 'Doğal Poz',
            description: 'Rahat bir duruşla talimatları uygulayın, başınızı gereksiz hareket ettirmeyin.',
          ),
          const SizedBox(height: 24),
          _TipItem(
            icon: Icons.straighten,
            color: accentColor,
            title: 'Yönlendirmeleri Takip Edin',
            description: 'Ekrandaki rehber ve sesli komutlara dikkat edin.',
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _TipItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CaptureGuidePage extends StatelessWidget {
  final _GuideStep step;
  final Color accentColor;

  const _CaptureGuidePage({
    required this.step,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Image.asset(
              step.assetPath,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 32),
          ...step.tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int length;
  final int activeIndex;
  final Color color;

  const _DotsIndicator({
    required this.length,
    required this.activeIndex,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        length,
        (index) {
          final isActive = index == activeIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: isActive ? 28 : 8,
            decoration: BoxDecoration(
              color: isActive ? color : color.withOpacity(0.25),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

class _GuideStep {
  final CaptureAngle angle;
  final String title;
  final String description;
  final String assetPath;
  final List<String> tips;

  const _GuideStep({
    required this.angle,
    required this.title,
    required this.description,
    required this.assetPath,
    required this.tips,
  });
}

