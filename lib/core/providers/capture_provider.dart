import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/capture_angle.dart';

/// Çekilen fotoğraf modeli
class CapturedPhoto {
  final CaptureAngle angle;
  final String filePath;
  final DateTime capturedAt;

  CapturedPhoto({
    required this.angle,
    required this.filePath,
    required this.capturedAt,
  });
}

/// Capture durumu
class CaptureState {
  final Map<CaptureAngle, String?> capturedPhotos;
  final CaptureAngle? currentAngle;
  final int currentStep;

  CaptureState({
    Map<CaptureAngle, String?>? capturedPhotos,
    this.currentAngle,
    this.currentStep = 1,
  }) : capturedPhotos = capturedPhotos ?? {};

  bool isAngleCaptured(CaptureAngle angle) {
    return capturedPhotos[angle] != null;
  }

  int get completedCount {
    return capturedPhotos.values.where((path) => path != null).length;
  }

  bool get allCaptured {
    return completedCount == CaptureAngle.values.length;
  }

  CaptureState copyWith({
    Map<CaptureAngle, String?>? capturedPhotos,
    CaptureAngle? currentAngle,
    int? currentStep,
  }) {
    return CaptureState(
      capturedPhotos: capturedPhotos ?? this.capturedPhotos,
      currentAngle: currentAngle ?? this.currentAngle,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

/// Capture Provider
class CaptureNotifier extends StateNotifier<CaptureState> {
  CaptureNotifier() : super(CaptureState());

  void setCurrentAngle(CaptureAngle angle) {
    state = state.copyWith(
      currentAngle: angle,
      currentStep: angle.stepNumber,
    );
  }

  void addCapturedPhoto(CaptureAngle angle, String filePath) {
    final updatedPhotos = Map<CaptureAngle, String?>.from(state.capturedPhotos);
    updatedPhotos[angle] = filePath;

    state = state.copyWith(capturedPhotos: updatedPhotos);
  }

  void reset() {
    state = CaptureState();
  }

  CaptureAngle? getNextAngle() {
    for (var angle in CaptureAngle.values) {
      if (!state.isAngleCaptured(angle)) {
        return angle;
      }
    }
    return null;
  }
}

final captureProvider = StateNotifierProvider<CaptureNotifier, CaptureState>((ref) {
  return CaptureNotifier();
});

