# Smile Hair Clinic - Self-Capture Tool Proje Kuralları

## 1. Teknoloji Foku
Bu proje **YALNIZCA Flutter** ile geliştirilecektir. React Native veya başka bir framework ile ilgili kod önerilerinde bulunma.

## 2. Paket Öncelikleri

### Kamera
- **Kamera:** `camera` paketini kullan.

### Sensörler
- Cihaz eğimi ve konumu için `sensors_plus` paketinden jiroskop ve ivmeölçer verilerini kullan.

### ML/Görüntü İşleme
- Kafa/yüz pozisyonu algılaması için `google_ml_kit_face_detection` paketini kullan.

### Depolama
- Fotoğrafları kaydetmek için `path_provider` ve `image_picker` (veya `camera` paketinin kendi kaydetme metodu) kullanılacak.

## 3. Mimari Ayrımı
UI (Frontend) kodunu, 'Core Logic' (sensör işleme, açı hesaplama, ML analizleri) kodundan **KESİNLİKLE** ayrı tut. Logic işlemlerini state management çözümleri (örn. Riverpod, BLoC) veya servis sınıfları içinde yönet. UI widget'ları içinde karmaşık hesaplamalar yapma.

## 4. Brief'e Bağlılık
Tüm yönlendirme mantığı, PDF brief'inde tanımlanan 5 spesifik fotoğraf açısını temel almalıdır. Özellikle "Tepe (Vertex)" ve "Arka Donör" açılarının zorluğunu göz önünde bulundurarak bu açılar için sensör bazlı (örn: "telefonu 90 derece eğ") ve görsel bazlı (örn: "kafanızı çerçevenin içine alın") yönlendirmeleri birleştiren kodlar yaz.

## 5. Otomatik Deklanşör
Deklanşör mekanizması manuel olmayacak. Yalnızca "doğru telefon açısı" **VE** "doğru kafa pozisyonu" kriterleri aynı anda sağlandığında otomatik olarak (tercihen kısa bir geri sayım veya sesli bildirimle) çalışmalıdır.

## 6. Kod Kalitesi
Tüm kodlar null-safe olmalı, asenkron işlemler (Streams, Futures) düzgün yönetilmeli ve özellikle sensör verilerini yorumlayan karmaşık matematiksel hesaplamalar için açıklayıcı yorum satırları eklenmelidir.

