import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Fotoğraf çekim açıları
enum CaptureAngle {
  frontFace('Ön Yüz', 'Kameraya doğrudan bakın'),
  rightSide('Sağ Yüz', 'Kafanızı sağa çevirin'),
  leftSide('Sol Yüz', 'Kafanızı sola çevirin'),
  topVertex('Tepe (Vertex)', 'Telefonu kafanızın üstüne kaldırın'),
  backDonor('Arka Donör', 'Telefonu kafanızın arkasına alın');

  final String name;
  final String instruction;
  const CaptureAngle(this.name, this.instruction);
}

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isSwitchingCamera = false;

  // Aktif çekim açısı
  CaptureAngle _currentAngle = CaptureAngle.frontFace;

  // Sensör verileri (ileride açı kontrolü için kullanılacak)
  // ignore: unused_field
  double _gyroscopeX = 0.0;
  // ignore: unused_field
  double _gyroscopeY = 0.0;
  // ignore: unused_field
  double _gyroscopeZ = 0.0;
  // ignore: unused_field
  double _accelerometerX = 0.0;
  // ignore: unused_field
  double _accelerometerY = 0.0;
  // ignore: unused_field
  double _accelerometerZ = 0.0;

  // Hesaplanan açılar (pitch, roll)
  double _pitch = 0.0;
  double _roll = 0.0;

  // Yüz algılama
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
      minFaceSize: 0.1,
    ),
  );
  List<Face> _detectedFaces = [];
  CustomPaint? _customPaint;
  
  // Fotoğraf çekme durumu
  bool _isCapturing = false;
  Map<CaptureAngle, String?> _capturedPhotos = {};
  
  // Yüz algılama debug bilgisi
  String _faceDetectionStatus = 'Başlatılıyor...';

  // Stream subscription'ları
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeSensors();
  }

  /// Kamera başlatma - Varsayılan olarak ön kamera
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('Kamera bulunamadı');
        return;
      }

      // Ön kamerayı bul (varsayılan)
      int frontCameraIndex = _cameras!.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      // Ön kamera bulunamazsa ilk kamerayı kullan
      if (frontCameraIndex == -1) {
        frontCameraIndex = 0;
      }

      _currentCameraIndex = frontCameraIndex;

      await _switchCamera(frontCameraIndex);
    } catch (e) {
      debugPrint('Kamera başlatma hatası: $e');
    }
  }

  /// Kamera değiştirme
  Future<void> _switchCamera(int cameraIndex) async {
    if (_isSwitchingCamera || cameraIndex >= _cameras!.length) return;

    setState(() {
      _isSwitchingCamera = true;
      _isCameraInitialized = false;
    });

    try {
      // Mevcut kamerayı durdur
      await _cameraController?.stopImageStream();
      await _cameraController?.dispose();

      // Yeni kamerayı başlat
      _cameraController = CameraController(
        _cameras![cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Kamera görüntüsünü işlemeye başla
      _cameraController!.startImageStream(_processCameraImage);

      if (mounted) {
        setState(() {
          _currentCameraIndex = cameraIndex;
          _isCameraInitialized = true;
          _isSwitchingCamera = false;
        });
      }
    } catch (e) {
      debugPrint('Kamera değiştirme hatası: $e');
      if (mounted) {
        setState(() {
          _isSwitchingCamera = false;
        });
      }
    }
  }

  /// Kamera değiştirme butonu için
  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    // Mevcut kameranın tersini bul
    final currentCamera = _cameras![_currentCameraIndex];
    final targetDirection = currentCamera.lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    final targetIndex = _cameras!.indexWhere(
      (camera) => camera.lensDirection == targetDirection,
    );

    if (targetIndex != -1) {
      await _switchCamera(targetIndex);
    }
  }

  /// Sensörleri başlatma
  void _initializeSensors() {
    // Gyroscope stream
    _gyroscopeSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (mounted) {
        setState(() {
          _gyroscopeX = event.x;
          _gyroscopeY = event.y;
          _gyroscopeZ = event.z;
        });
      }
    });

    // Accelerometer stream
    _accelerometerSubscription =
        accelerometerEventStream().listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          _accelerometerX = event.x;
          _accelerometerY = event.y;
          _accelerometerZ = event.z;

          // Pitch ve Roll hesaplama (accelerometer'dan)
          // Pitch: X ekseni etrafında dönüş
          // Roll: Y ekseni etrafında dönüş
          _pitch = (180 / math.pi) *
              (math.atan2(-event.x, math.sqrt(event.y * event.y + event.z * event.z)));
          _roll = (180 / math.pi) * (math.atan2(event.y, event.z));
        });
      }
    });
  }

  /// Kamera görüntüsünü işle ve yüz algılama yap
  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      final InputImage? inputImage = _inputImageFromCameraImage(image);

      // InputImage oluşturulamadıysa (format/rotation null) işlemi durdur
      if (inputImage == null) {
        if (mounted) {
          setState(() {
            _faceDetectionStatus = 'Görüntü formatı desteklenmiyor';
          });
        }
        _isProcessing = false;
        return;
      }

      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _detectedFaces = faces;
          _customPaint = _createCustomPaint(faces, image);
          
          // Yüz algılama durumu güncelle
          if (faces.isEmpty) {
            _faceDetectionStatus = 'Yüz algılanamadı - Kameraya bakın';
          } else {
            _faceDetectionStatus = '${faces.length} yüz algılandı';
          }
        });
      }
    } catch (e) {
      debugPrint('Yüz algılama hatası: $e');
      if (mounted) {
        setState(() {
          _faceDetectionStatus = 'Hata: $e';
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// CameraImage'i InputImage'e dönüştür
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameras == null || _cameras!.isEmpty || _cameraController == null) {
      return null;
    }

    final CameraDescription camera = _cameras![_currentCameraIndex];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    // Format veya rotation null ise null döndür
    if (format == null || imageRotation == null) {
      return null;
    }

    final plane = image.planes[0];
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  /// Yüz algılamaları için CustomPaint oluştur (bounding box çizmek için)
  CustomPaint? _createCustomPaint(List<Face> faces, CameraImage image) {
    if (faces.isEmpty || _cameraController == null) {
      return null;
    }

    return CustomPaint(
      painter: FaceDetectorPainter(
        faces: faces,
        imageSize: Size(image.width.toDouble(), image.height.toDouble()),
        cameraPreviewSize: Size(
          _cameraController!.value.previewSize!.height,
          _cameraController!.value.previewSize!.width,
        ),
      ),
    );
  }

  /// Fotoğraf çekme
  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showSnackBar('Kamera hazır değil');
      return;
    }

    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Fotoğraf çek
      final XFile photo = await _cameraController!.takePicture();

      // Fotoğrafı kaydet
      final String savedPath = await _savePhoto(photo, _currentAngle);

      // Çekilen fotoğrafı kaydet
      setState(() {
        _capturedPhotos[_currentAngle] = savedPath;
        _isCapturing = false;
      });

      _showSnackBar('Fotoğraf çekildi: ${_currentAngle.name}');
      debugPrint('Fotoğraf kaydedildi: $savedPath');
    } catch (e) {
      debugPrint('Fotoğraf çekme hatası: $e');
      _showSnackBar('Fotoğraf çekilemedi: $e');
      setState(() {
        _isCapturing = false;
      });
    }
  }

  /// Fotoğrafı cihaza kaydet
  Future<String> _savePhoto(XFile photo, CaptureAngle angle) async {
    try {
      // Uygulama dizinini al
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String photosDir = path.join(appDir.path, 'captured_photos');

      // Dizin yoksa oluştur
      final Directory dir = Directory(photosDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Dosya adını oluştur (açı adı + timestamp)
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${angle.name}_$timestamp.jpg';
      final String filePath = path.join(photosDir, fileName);

      // Fotoğrafı kopyala
      await photo.saveTo(filePath);

      return filePath;
    } catch (e) {
      debugPrint('Fotoğraf kaydetme hatası: $e');
      rethrow;
    }
  }

  /// Tüm çekilen fotoğrafları göster
  void _showCapturedPhotos() {
    if (_capturedPhotos.isEmpty) {
      _showSnackBar('Henüz fotoğraf çekilmedi');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çekilen Fotoğraflar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _capturedPhotos.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      entry.value != null ? Icons.check_circle : Icons.cancel,
                      color: entry.value != null ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (entry.value != null)
                      Text(
                        path.basename(entry.value!),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// SnackBar göster
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Kamera önizlemesi
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),

          // Yüz algılama bounding box'ları
          if (_customPaint != null)
            Positioned.fill(
              child: _customPaint!,
            ),

          // Açı seçimi ve bilgi paneli (üst kısım)
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Açı seçim butonları
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: CaptureAngle.values.map((angle) {
                        final isSelected = _currentAngle == angle;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(
                              angle.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _currentAngle = angle;
                                });
                              }
                            },
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            selectedColor: Colors.blue.withOpacity(0.7),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Yönlendirme mesajı
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentAngle.instruction,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Sensör verileri göstergesi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AÇILAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pitch: ${_pitch.toStringAsFixed(2)}°',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        'Roll: ${_roll.toStringAsFixed(2)}°',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Yüz Sayısı: ${_detectedFaces.length}',
                        style: TextStyle(
                          color: _detectedFaces.isEmpty ? Colors.orange : Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _faceDetectionStatus,
                        style: TextStyle(
                          color: _detectedFaces.isEmpty ? Colors.orange : Colors.greenAccent,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Kamera değiştirme butonu (sağ üst köşe)
          Positioned(
            top: 50,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: _isSwitchingCamera ? null : _toggleCamera,
              backgroundColor: Colors.black.withOpacity(0.6),
              child: _isSwitchingCamera
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      _cameras != null &&
                              _currentCameraIndex < _cameras!.length &&
                              _cameras![_currentCameraIndex].lensDirection ==
                                  CameraLensDirection.front
                          ? Icons.camera_rear
                          : Icons.camera_front,
                      color: Colors.white,
                    ),
            ),
          ),

          // Alt kısım butonları
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Çekilen fotoğrafları göster butonu
                FloatingActionButton(
                  heroTag: 'gallery',
                  onPressed: _showCapturedPhotos,
                  backgroundColor: Colors.black.withOpacity(0.6),
                  child: Stack(
                    children: [
                      const Icon(Icons.photo_library, color: Colors.white),
                      if (_capturedPhotos.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${_capturedPhotos.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Fotoğraf çekme butonu (ana buton)
                FloatingActionButton(
                  heroTag: 'capture',
                  onPressed: _isCapturing ? null : _capturePhoto,
                  backgroundColor: _detectedFaces.isEmpty
                      ? Colors.grey.withOpacity(0.6)
                      : Colors.red.withOpacity(0.8),
                  child: _isCapturing
                      ? const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 30,
                        ),
                ),

                // Açı durumu göstergesi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _capturedPhotos.containsKey(_currentAngle) &&
                                _capturedPhotos[_currentAngle] != null
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: _capturedPhotos.containsKey(_currentAngle) &&
                                _capturedPhotos[_currentAngle] != null
                            ? Colors.green
                            : Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentAngle.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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

/// Yüz algılama bounding box'larını çizen CustomPainter
class FaceDetectorPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size cameraPreviewSize;

  FaceDetectorPainter({
    required this.faces,
    required this.imageSize,
    required this.cameraPreviewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Görüntü boyutunu önizleme boyutuna ölçeklendir
    final double scaleX = size.width / imageSize.height;
    final double scaleY = size.height / imageSize.width;

    for (Face face in faces) {
      final Rect boundingBox = face.boundingBox;

      // Bounding box'ı ölçeklendir
      final double left = boundingBox.left * scaleX;
      final double top = boundingBox.top * scaleY;
      final double width = boundingBox.width * scaleX;
      final double height = boundingBox.height * scaleY;

      // Dikdörtgen çiz
      final Paint paint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRect(
        Rect.fromLTWH(left, top, width, height),
        paint,
      );

      // Yüz açısı bilgisini göster (eğer varsa)
      if (face.headEulerAngleY != null && face.headEulerAngleZ != null) {
        final TextSpan span = TextSpan(
          text:
              'Y: ${face.headEulerAngleY!.toStringAsFixed(1)}°\nZ: ${face.headEulerAngleZ!.toStringAsFixed(1)}°',
          style: const TextStyle(
            color: Colors.green,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
        final TextPainter textPainter = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(left, top - textPainter.height - 5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.cameraPreviewSize != cameraPreviewSize;
  }
}

