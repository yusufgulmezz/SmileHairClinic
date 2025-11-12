# Smile Hair Clinic - Self-Capture Tool

Smile Hair Clinic Hackathon'u için geliştirilmiş mobil self-capture uygulaması. Kullanıcıların 5 kritik açıdan (özellikle Tepe [Vertex] ve Arka Donör bölgeleri) kendi fotoğraflarını sensör destekli yönlendirmelerle çekebilmesini sağlar.

## Teknoloji Stack

- **Framework:** Flutter
- **Kamera:** camera paketi
- **Sensörler:** sensors_plus (gyroscope, accelerometer)
- **Yüz Algılama:** google_ml_kit_face_detection

## Ön Gereksinimler

- Flutter SDK (3.0.0 veya üzeri)
- Android Studio / Xcode (geliştirme için)
- Android SDK / iOS SDK

Flutter'ı yüklemek için: [Flutter Kurulum Kılavuzu](https://docs.flutter.dev/get-started/install)

## Kurulum

1. **Proje bağımlılıklarını yükleyin:**
```bash
flutter pub get
```

2. **Android için gerekli izinler:**
   - ✅ **İzinler zaten eklendi!** `android/app/src/main/AndroidManifest.xml` dosyasında:
     - Kamera izni
     - Depolama izinleri
     - Android 13+ için READ_MEDIA_IMAGES izni

3. **iOS için gerekli izinler:**
   - ✅ **İzinler zaten eklendi!** `ios/Runner/Info.plist` dosyasında:
     - NSCameraUsageDescription
     - NSPhotoLibraryUsageDescription
     - NSPhotoLibraryAddUsageDescription

## Çalıştırma

```bash
flutter run
```

## MVP Adım 1 - Prototip Ekran

`lib/screens/capture_screen.dart` dosyası aşağıdaki özellikleri içerir:

- ✅ Tam ekran kamera önizlemesi
- ✅ Gyroscope ve Accelerometer verilerinin gerçek zamanlı gösterimi
- ✅ Pitch ve Roll açılarının hesaplanması ve gösterimi
- ✅ Yüz algılama ve bounding box çizimi
- ✅ Yüz açılarının (headEulerAngleY, headEulerAngleZ) gösterimi

## Proje Yapısı

```
lib/
├── main.dart                 # Ana uygulama giriş noktası
└── screens/
    └── capture_screen.dart   # Prototip kamera ekranı
```

## Sonraki Adımlar

- [ ] Core Logic katmanını ayrı servis sınıflarına taşıma
- [ ] 5 spesifik açı için yönlendirme mantığı ekleme
- [ ] Otomatik deklanşör mekanizması
- [ ] Sesli ve görsel yönlendirmeler
- [ ] Fotoğraf kaydetme işlevi

## Notlar

- Bu proje Flutter 3.0.0+ gerektirir
- Null-safe kod yazılmıştır
- Sensör verileri gerçek zamanlı olarak işlenmektedir
- Yüz algılama ML Kit kullanılarak yapılmaktadır

