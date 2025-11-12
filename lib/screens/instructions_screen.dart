import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:page_view_dot_indicator/page_view_dot_indicator.dart';

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key});

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _voiceCommandsEnabled = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talimatlar'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildWelcomePage(),
                _buildTipsPage(),
                _buildSettingsPage(),
              ],
            ),
          ),
          // Dot indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: PageViewDotIndicator(
              currentItem: _currentPage,
              count: 3,
              unselectedColor: Colors.grey[300]!,
              selectedColor: Theme.of(context).primaryColor,
            ),
          ),
          // Çekime başla butonu (sadece son sayfada)
          if (_currentPage == 2)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/camera');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Çekime Başla',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_camera,
              size: 100,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Hoş Geldiniz',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Self-Capture Tool ile 5 farklı açıdan fotoğrafınızı çekebilirsiniz. '
            'Sensör destekli yönlendirmeler ve otomatik deklanşör ile kolayca '
            'profesyonel fotoğraflar çekin.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTipsPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İpuçları',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          _buildTipItem(
            icon: Icons.wb_sunny,
            title: 'İyi Işık',
            description: 'Yeterli ve eşit ışık alan bir ortam seçin',
          ),
          const SizedBox(height: 24),
          _buildTipItem(
            icon: Icons.image,
            title: 'Düz Arka Plan',
            description: 'Sade ve düz bir arka plan kullanın',
          ),
          const SizedBox(height: 24),
          _buildTipItem(
            icon: Icons.face,
            title: 'Doğal Poz',
            description: 'Rahat ve doğal bir poz alın',
          ),
          const SizedBox(height: 24),
          _buildTipItem(
            icon: Icons.straighten,
            title: 'Yönlendirmeleri Takip Edin',
            description: 'Ekrandaki yönlendirmeleri dikkatlice takip edin',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue.shade700),
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
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ayarlar',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: SwitchListTile(
              title: const Text('Sesli Komutlar'),
              subtitle: const Text('Fotoğraf çekimi sırasında sesli yönlendirmeler'),
              value: _voiceCommandsEnabled,
              onChanged: (value) {
                setState(() {
                  _voiceCommandsEnabled = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Dil'),
              subtitle: const Text('Türkçe'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Dil seçimi ekranı
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dil seçimi yakında eklenecek'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

