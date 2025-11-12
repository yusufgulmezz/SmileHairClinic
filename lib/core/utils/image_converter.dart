import 'dart:typed_data';
import 'package:camera/camera.dart';

/// YUV420 formatını NV21 formatına dönüştür (Android için ML Kit uyumluluğu)
class ImageConverter {
  /// YUV420_888 formatını NV21 formatına dönüştür
  /// NV21: Y plane + interleaved VU plane (V önce, U sonra)
  static Uint8List? convertYUV420ToNV21(CameraImage cameraImage) {
    try {
      if (cameraImage.planes.length < 3) {
        print('YUV420 için 3 plane gerekli, bulunan: ${cameraImage.planes.length}');
        return null;
      }

      final yPlane = cameraImage.planes[0];
      final uPlane = cameraImage.planes[1];
      final vPlane = cameraImage.planes[2];

      final width = cameraImage.width;
      final height = cameraImage.height;
      final ySize = width * height;
      final uvSize = (width ~/ 2) * (height ~/ 2);

      // NV21 formatı: Y verisi (ySize) + interleaved VU verisi (uvSize * 2)
      final nv21 = Uint8List(ySize + uvSize * 2);

      // Y plane'i kopyala (bytesPerRow dikkate alınarak)
      final yBuffer = yPlane.bytes;
      final yRowStride = yPlane.bytesPerRow;
      final yPixelStride = yPlane.bytesPerRow > width ? 1 : 1;

      int nv21Offset = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final yIndex = (y * yRowStride) + (x * yPixelStride);
          if (yIndex < yBuffer.length) {
            nv21[nv21Offset++] = yBuffer[yIndex];
          }
        }
      }

      // UV plane'leri interleave et (VU sırası - NV21 formatı)
      final uBuffer = uPlane.bytes;
      final vBuffer = vPlane.bytes;
      final uRowStride = uPlane.bytesPerRow;
      final vRowStride = vPlane.bytesPerRow;
      final uPixelStride = uPlane.bytesPerRow > (width ~/ 2) ? 2 : 1;
      final vPixelStride = vPlane.bytesPerRow > (width ~/ 2) ? 2 : 1;

      for (int y = 0; y < height ~/ 2; y++) {
        for (int x = 0; x < width ~/ 2; x++) {
          final uvX = x;
          final uvY = y;
          
          final vIndex = (uvY * vRowStride) + (uvX * vPixelStride);
          final uIndex = (uvY * uRowStride) + (uvX * uPixelStride);

          // V değeri (önce V, sonra U - NV21 formatı)
          if (vIndex < vBuffer.length) {
            nv21[nv21Offset++] = vBuffer[vIndex];
          } else {
            nv21[nv21Offset++] = 128; // Varsayılan değer
          }

          // U değeri
          if (uIndex < uBuffer.length) {
            nv21[nv21Offset++] = uBuffer[uIndex];
          } else {
            nv21[nv21Offset++] = 128; // Varsayılan değer
          }
        }
      }

      return nv21;
    } catch (e) {
      print('YUV420 to NV21 dönüşüm hatası: $e');
      return null;
    }
  }
}
