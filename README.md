# Smile Hair Clinic - Self-Capture Tool

Smile Hair Clinic Hackathon'u için geliştirilmiş mobil self-capture uygulaması. Kullanıcıların 5 kritik açıdan (Ön Yüz, Sol Taraf, Sağ Taraf, Üst Taraf [Vertex], Arka Donör) kendi fotoğraflarını sensör destekli yönlendirmeler ve otomatik çekim özellikleriyle çekebilmesini sağlar.

## 🎯 Özellikler

### ✨ Temel Özellikler
- **5 Adımlı Rehber:** Kullanıcıyı her açı için hazırlayan interaktif rehber ekranları
- **Sensör Destekli Yönlendirme:** Accelerometer ile pitch/roll ölçümü ve gerçek zamanlı pozisyon kontrolü
- **Yüz Algılama:** ML Kit ile yüz tespiti ve doğru açı kontrolü
- **Otomatik Çekim:** Doğru pozisyon ve stabilite sağlandığında otomatik fotoğraf çekimi
- **Görsel/Sesli/Titreşim Geri Bildirimi:** Doğru açı yakalandığında bildirim
- **Oval Kamera Maskesi:** Profesyonel çekim için oval kadraj
- **İlerleme Takibi:** 5 açı için tamamlanma durumu gösterimi

### 📱 Uygulama Akışı
1. **Splash Screen** → Logo gösterimi ve otomatik yönlendirme
2. **Login Screen** → Test hesabı ile otomatik giriş (aitech_test@gmail.com / 123123)
3. **Guide Screen** → Hoş geldiniz mesajı, ipuçları ve 5 açı için görsel rehber
4. **Camera Screen** → Sensör ve yüz algılama destekli fotoğraf çekimi
5. **Summary Screen** → Çekilen fotoğrafların önizlemesi ve onay

## 🛠 Teknoloji Stack

### Framework ve Dil
- **Flutter 3.0.0+**
- **Dart SDK >=3.0.0**

### Kullanılan Paketler

| Paket | Versiyon | Kullanım |
|-------|----------|----------|
| `flutter_riverpod` | ^2.4.9 | State management (auth, capture state) |
| `go_router` | ^13.0.0 | Navigasyon ve routing |
| `camera` | ^0.10.5+5 | Kamera erişimi ve fotoğraf çekimi |
| `sensors_plus` | ^4.0.2 | Accelerometer/Gyroscope verileri |
| `google_mlkit_face_detection` | ^0.9.0 | Yüz algılama ve tespiti |
| `path_provider` | ^2.1.1 | Dosya sistemi erişimi |
| `path` | ^1.8.3 | Dosya yolu işlemleri |
| `page_view_dot_indicator` | ^2.0.3 | Rehber sayfaları için göstergeler |
| `vibration` | ^1.8.4 | Titreşim geri bildirimi |

## 📋 Ön Gereksinimler

- Flutter SDK (3.0.0 veya üzeri)
- Android Studio / Xcode (geliştirme için)
- Android SDK (minSdkVersion: 21, targetSdkVersion: 33+)
- iOS SDK (iOS 12.0+)

Flutter'ı yüklemek için: [Flutter Kurulum Kılavuzu](https://docs.flutter.dev/get-started/install)

## 🚀 Kurulum

1. **Projeyi klonlayın:**
```bash
git clone <repository-url>
cd SmileHairClinic
```

2. **Bağımlılıkları yükleyin:**
```bash
flutter pub get
```

3. **Android için izinler:**
   - ✅ İzinler zaten `android/app/src/main/AndroidManifest.xml` dosyasında tanımlı:
     - `CAMERA` - Kamera erişimi
     - `WRITE_EXTERNAL_STORAGE` - Dosya yazma
     - `READ_EXTERNAL_STORAGE` - Dosya okuma
     - `READ_MEDIA_IMAGES` - Android 13+ için medya erişimi

4. **iOS için izinler:**
   - ✅ İzinler zaten `ios/Runner/Info.plist` dosyasında tanımlı:
     - `NSCameraUsageDescription` - Kamera erişimi
     - `NSPhotoLibraryUsageDescription` - Fotoğraf kütüphanesi erişimi
     - `NSPhotoLibraryAddUsageDescription` - Fotoğraf ekleme izni

## ▶️ Çalıştırma

### Debug Modu
```bash
flutter run
```

### Release Modu
```bash
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## 📁 Proje Yapısı

```
lib/
├── main.dart                      # Ana uygulama giriş noktası
│
├── core/                          # Çekirdek katman
│   ├── models/
│   │   └── capture_angle.dart    # Fotoğraf açıları enum
│   ├── providers/
│   │   ├── auth_provider.dart    # Kimlik doğrulama state
│   │   └── capture_provider.dart # Çekim durumu yönetimi
│   ├── router/
│   │   └── app_router.dart       # GoRouter yapılandırması
│   └── utils/
│       ├── face_side_detector.dart      # Yüz tarafı algılama
│       ├── image_converter.dart         # Kamera görüntüsü dönüşümü
│       └── sensor_angle_detector.dart   # Sensör açı hesaplamaları
│
├── screens/                       # Ekranlar
│   ├── splash_screen.dart        # Açılış ekranı
│   ├── login_screen.dart         # Giriş ekranı
│   ├── guide_screen.dart         # 5 adımlı rehber
│   ├── camera_screen.dart        # Kamera ve çekim ekranı
│   └── summary_screen.dart       # Özet ve onay ekranı
│
└── widgets/                       # Özel widget'lar
    ├── circular_progress_ring.dart    # İlerleme halkası
    ├── oval_camera_mask.dart          # Oval kamera maskesi
    └── oval_overlay.dart              # Overlay bileşenleri
```

## 🎨 Özellik Detayları

### Sensör Bazlı Kontrol (Vertex & Back Donor)
- Accelerometer verilerinden **pitch** ve **roll** açıları hesaplanır
- Pozisyon doğruluğu ve stabilite kontrolü yapılır
- 2 saniyelik timer ile otomatik çekim tetiklenir
- Gerçek zamanlı yönlendirme mesajları gösterilir

### Yüz Algılama (Front, Left, Right)
- ML Kit ile yüz tespiti
- Yüzün doğru tarafının görünür olup olmadığı kontrol edilir
- Tek yüz algılandığında otomatik çekim aktif olur
- Gerçek zamanlı yönlendirme ve pozisyon bilgisi

### Geri Bildirim Sistemi
- **Ses:** Sistem uyarı sesi (`SystemSoundType.alert`)
- **Titreşim:** Güçlü titreşim (150ms, amplitude 200)
- **Görsel:** Ekranda gerçek zamanlı durum mesajları

### Otomatik Çekim Özelliği
- **Front, Left, Right:** Yüz algılama ile otomatik çekim
- **Vertex, Back Donor:** Sensör kontrolü ile otomatik çekim
- Tüm açılarda 2 saniyelik gecikme ile tetiklenir

## 🔐 Test Hesabı

Uygulama açılışında otomatik olarak doldurulan test hesabı:
- **E-posta:** aitech_test@gmail.com
- **Şifre:** 123123

## 📸 Çekim Açıları

1. **Ön Yüz (Front Face)** - Yüz algılama
2. **Sol Taraf (Left Side)** - Yüz algılama + otomatik çekim
3. **Sağ Taraf (Right Side)** - Yüz algılama + otomatik çekim
4. **Üst Taraf (Vertex)** - Sensör kontrolü + otomatik çekim
5. **Arka Donör (Back Donor)** - Sensör kontrolü + otomatik çekim
