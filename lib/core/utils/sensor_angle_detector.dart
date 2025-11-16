import 'dart:math' as math;

/// Sensör bazlı açı algılama ve pozisyon kontrolü
class SensorAngleDetector {
  /// Pitch açısını radyandan dereceye çevir
  static double calculatePitch(double accelX, double accelY, double accelZ) {
    return (180 / math.pi) *
        math.atan2(-accelX, math.sqrt(accelY * accelY + accelZ * accelZ));
  }

  /// Roll açısını radyandan dereceye çevir
  static double calculateRoll(double accelX, double accelY, double accelZ) {
    return (180 / math.pi) * math.atan2(accelY, accelZ);
  }

  /// Yaw açısını hesapla (magnetometer olmadan tam doğru olmayabilir)
  static double calculateYaw(double gyroX, double gyroY, double gyroZ) {
    // Basit bir yaklaşım - gyroscope'tan yaw hesaplama
    return math.atan2(gyroY, gyroX) * (180 / math.pi);
  }

  /// Vertex (Üst Taraf) için doğru pozisyon kontrolü
  /// Telefon kafanın üstüne, yukarı bakacak şekilde tutulmalı
  /// Telefon yatay tutulduğunda pitch 0'a yakın, dikey tutulduğunda 90'a yakın olur
  static bool isVertexAngleValid(double pitch, double roll, {double tolerance = 30.0}) {
    // Pitch: -30 ile 120 derece arası kabul edilebilir (telefon yukarı bakıyor)
    // Yatay pozisyon (pitch ~0) veya dikey pozisyon (pitch ~90) kabul edilir
    // Roll: -45 ile 45 derece arası (telefon düz tutulmalı, hafif eğiklik kabul edilir)
    final pitchValid = pitch >= -tolerance && pitch <= 90 + tolerance;
    final rollValid = roll.abs() <= 45.0;
    
    return pitchValid && rollValid;
  }

  /// Back Donor (Arka Taraf) için doğru pozisyon kontrolü
  /// Telefon kafanın arkasında, ters yönde olmalı
  static bool isBackDonorAngleValid(double pitch, double roll, {double tolerance = 20.0}) {
    // Pitch: -90 ile -70 veya 70 ile 90 arası (telefon yatay veya hafif eğik)
    // Roll: 160-200 derece arası (telefon ters yönde)
    final pitchValid = (pitch >= -90 - tolerance && pitch <= -90 + tolerance) ||
                       (pitch >= 90 - tolerance && pitch <= 90 + tolerance);
    final rollValid = (roll >= 180 - tolerance && roll <= 180 + tolerance) ||
                      (roll >= -180 + tolerance && roll <= -180 - tolerance) ||
                      (roll.abs() >= 160 && roll.abs() <= 200);
    
    return pitchValid || rollValid;
  }

  /// Pozisyonun stabilitesini kontrol et (sallanma var mı?)
  static bool isPositionStable(
    List<double> pitchHistory,
    List<double> rollHistory, {
    double stabilityThreshold = 5.0,
    int requiredStableFrames = 10,
  }) {
    if (pitchHistory.length < requiredStableFrames ||
        rollHistory.length < requiredStableFrames) {
      return false;
    }

    // Son N frame'in standart sapmasını hesapla
    final pitchStdDev = _calculateStandardDeviation(
      pitchHistory.sublist(pitchHistory.length - requiredStableFrames),
    );
    final rollStdDev = _calculateStandardDeviation(
      rollHistory.sublist(rollHistory.length - requiredStableFrames),
    );

    return pitchStdDev <= stabilityThreshold && rollStdDev <= stabilityThreshold;
  }

  /// Standart sapma hesapla
  static double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
        .map((x) => math.pow(x - mean, 2))
        .reduce((a, b) => a + b) / values.length;
    
    return math.sqrt(variance);
  }

  /// Vertex açısı için yönlendirme mesajı
  static String getVertexGuidance(double pitch, double roll) {
    // Vertex için telefon yukarı bakmalı (pitch 0-90 arası kabul edilir)
    // Yatay pozisyon (pitch ~0) veya dikey pozisyon (pitch ~90) kabul edilir
    if (pitch < -30) {
      return 'Telefonu yukarı doğru çevirin';
    } else if (pitch > 120) {
      return 'Telefonu biraz aşağı indirin';
    } else if (roll.abs() > 45) {
      return 'Telefonu daha düz tutun';
    } else {
      return 'Pozisyon iyi! Sabit tutun';
    }
  }

  /// Back Donor açısı için yönlendirme mesajı
  static String getBackDonorGuidance(double pitch, double roll) {
    // Back Donor için basit yönlendirmeler
    if (roll.abs() < 30 || (roll.abs() > 150 && roll.abs() < 210)) {
      return 'Telefonu kafanızın arkasına alın ve sabit tutun';
    } else {
      return 'Pozisyonu ayarlayın - Telefonu kafanızın arkasına alın';
    }
  }
}

