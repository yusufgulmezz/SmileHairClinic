import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/capture_angle.dart';

/// Yüzün hangi tarafının görünür olduğunu tespit eden yardımcı sınıf
class FaceSideDetector {
  /// Yüzün doğru tarafının görünür olup olmadığını kontrol et
  /// 
  /// [face]: Algılanan yüz
  /// [currentAngle]: Mevcut çekim açısı
  /// 
  /// Returns: true eğer doğru taraf görünürse
  static bool isCorrectFaceSideVisible(Face face, CaptureAngle currentAngle) {
    // Ön yüz için herhangi bir yön kontrolü yok
    if (currentAngle == CaptureAngle.frontFace) {
      // Ön yüz için yüzün düz (0'a yakın) olması gerekir
      final headEulerAngleY = face.headEulerAngleY ?? 0.0;
      return headEulerAngleY.abs() <= 20.0; // -20 ile +20 arası kabul edilebilir
    }

    // Sol taraf çekimi için: Yüz sola dönük olmalı (sol taraf görünür)
    // Yüzün tamamının görünmesi için yaklaşık 60 derece sola dönmüş olmalı
    if (currentAngle == CaptureAngle.leftSide) {
      final headEulerAngleY = face.headEulerAngleY ?? 0.0;
      // Negatif değer: Yüz sola dönük, sol taraf görünür
      // -50 ile -70 derece arası ideal (60 derece ± 10 derece tolerans)
      return headEulerAngleY <= -50.0 && headEulerAngleY >= -70.0;
    }

    // Sağ taraf çekimi için: Yüz sağa dönük olmalı (sağ taraf görünür)
    // Yüzün tamamının görünmesi için yaklaşık 60 derece sağa dönmüş olmalı
    if (currentAngle == CaptureAngle.rightSide) {
      final headEulerAngleY = face.headEulerAngleY ?? 0.0;
      // Pozitif değer: Yüz sağa dönük, sağ taraf görünür
      // 50-70 derece arası ideal (60 derece ± 10 derece tolerans)
      return headEulerAngleY >= 50.0 && headEulerAngleY <= 70.0;
    }

    // Vertex ve Back Donor için yüz yönü kontrolü yok
    return true;
  }

  /// Yüz yönü için yönlendirme mesajı
  static String getFaceSideGuidance(Face face, CaptureAngle currentAngle) {
    final headEulerAngleY = face.headEulerAngleY ?? 0.0;

    if (currentAngle == CaptureAngle.frontFace) {
      if (headEulerAngleY.abs() > 20.0) {
        if (headEulerAngleY > 0) {
          return 'Yüzünüzü biraz sola çevirin (düz bakın)';
        } else {
          return 'Yüzünüzü biraz sağa çevirin (düz bakın)';
        }
      }
      return 'Pozisyon iyi!';
    }

    if (currentAngle == CaptureAngle.leftSide) {
      if (headEulerAngleY > -50.0) {
        if (headEulerAngleY > 0) {
          return 'Yüzünüzü sola çevirin (sol tarafınızı gösterin)';
        } else {
          return 'Yüzünüzü daha fazla sola çevirin (yaklaşık 60° döndürün)';
        }
      } else if (headEulerAngleY < -70.0) {
        return 'Yüzünüzü biraz sağa çevirin (çok fazla döndü)';
      }
      return 'Sol taraf görünüyor - Pozisyon iyi!';
    }

    if (currentAngle == CaptureAngle.rightSide) {
      if (headEulerAngleY < 50.0) {
        if (headEulerAngleY < 0) {
          return 'Yüzünüzü sağa çevirin (sağ tarafınızı gösterin)';
        } else {
          return 'Yüzünüzü daha fazla sağa çevirin (yaklaşık 60° döndürün)';
        }
      } else if (headEulerAngleY > 70.0) {
        return 'Yüzünüzü biraz sola çevirin (çok fazla döndü)';
      }
      return 'Sağ taraf görünüyor - Pozisyon iyi!';
    }

    return '';
  }

  /// Yüzün yönünü metin olarak döndür (debug için)
  static String getFaceSideDescription(Face face) {
    final headEulerAngleY = face.headEulerAngleY;
    if (headEulerAngleY == null) {
      return 'Yön bilgisi yok';
    }

    if (headEulerAngleY.abs() <= 20.0) {
      return 'Ön yüz (${headEulerAngleY.toStringAsFixed(1)}°)';
    } else if (headEulerAngleY < -20.0) {
      return 'Sol taraf görünür (${headEulerAngleY.toStringAsFixed(1)}°)';
    } else {
      return 'Sağ taraf görünür (${headEulerAngleY.toStringAsFixed(1)}°)';
    }
  }
}

