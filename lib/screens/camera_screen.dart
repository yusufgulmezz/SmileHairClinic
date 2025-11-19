import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../core/models/capture_angle.dart';
import '../core/providers/capture_provider.dart';
import '../core/utils/image_converter.dart';
import '../core/utils/sensor_angle_detector.dart';
import '../core/utils/face_side_detector.dart';
import '../widgets/oval_camera_mask.dart';
import '../widgets/circular_progress_ring.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isSwitchingCamera = false;
  bool _isCapturing = false;

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
  String _faceDetectionStatus = 'Başlatılıyor...';
  bool _isCorrectFaceSide = false; // Yüzün doğru tarafı görünüyor mu?

  // Sensör verileri
  double _pitch = 0.0;
  double _roll = 0.0;

  // Sensör bazlı pozisyon kontrolü
  List<double> _pitchHistory = [];
  List<double> _rollHistory = [];
  static const int _maxHistorySize = 20;
  bool _isPositionValid = false;
  bool _isPositionStable = false;
  String _sensorGuidance = '';
  Timer? _autoCaptureTimer;

  // Stream subscription'ları
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  void _resetCaptureProgress() {
    ref.read(captureProvider.notifier).reset();
    final captureNotifier = ref.read(captureProvider.notifier);
    captureNotifier.setCurrentAngle(CaptureAngle.frontFace);

    setState(() {
      _detectedFaces = [];
      _customPaint = null;
      _faceDetectionStatus = 'Başlatılıyor...';
      _isCorrectFaceSide = false;
      _faceDetectionEnabled = true;
      _faceDetectionErrorCount = 0;
      _pitchHistory.clear();
      _rollHistory.clear();
      _isPositionValid = false;
      _isPositionStable = false;
      _sensorGuidance = '';
      _cancelAutoCaptureTimer();
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeSensors();
    _initializeCurrentAngle();
  }

  void _initializeCurrentAngle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final captureNotifier = ref.read(captureProvider.notifier);
      final nextAngle = captureNotifier.getNextAngle() ?? CaptureAngle.frontFace;
      captureNotifier.setCurrentAngle(nextAngle);
    });
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('Kamera bulunamadı');
        return;
      }

      int frontCameraIndex = _cameras!.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      if (frontCameraIndex == -1) {
        frontCameraIndex = 0;
      }

      _currentCameraIndex = frontCameraIndex;
      await _switchCamera(frontCameraIndex);
    } catch (e) {
      debugPrint('Kamera başlatma hatası: $e');
    }
  }

  Future<void> _switchCamera(int cameraIndex) async {
    if (_isSwitchingCamera || cameraIndex >= _cameras!.length) return;

    setState(() {
      _isSwitchingCamera = true;
      _isCameraInitialized = false;
    });

    try {
      await _cameraController?.stopImageStream();
      await _cameraController?.dispose();

      // Yüz algılama için medium resolution yeterli ve daha performanslı
      // Android'de YUV420, iOS'ta BGRA8888 kullan
      _cameraController = CameraController(
        _cameras![cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        // Android'de YUV420 destekleniyor, iOS'ta BGRA8888
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.yuv420 
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
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

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

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

  void _initializeSensors() {
    // Gyroscope verileri şu an kullanılmıyor ama gelecekte kullanılabilir
    _gyroscopeSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      // Gyroscope verileri gelecekte kullanılabilir
    });

    _accelerometerSubscription =
        accelerometerEventStream().listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          // Pitch ve Roll hesapla
          _pitch = SensorAngleDetector.calculatePitch(
            event.x,
            event.y,
            event.z,
          );
          _roll = SensorAngleDetector.calculateRoll(
            event.x,
            event.y,
            event.z,
          );

          // Geçmiş verileri güncelle
          _pitchHistory.add(_pitch);
          _rollHistory.add(_roll);

          // Geçmiş verileri sınırla
          if (_pitchHistory.length > _maxHistorySize) {
            _pitchHistory.removeAt(0);
          }
          if (_rollHistory.length > _maxHistorySize) {
            _rollHistory.removeAt(0);
          }

          // Mevcut açıya göre pozisyon kontrolü yap
          _checkSensorBasedPosition();
        });
      }
    });
  }

  /// Sensör bazlı pozisyon kontrolü (Vertex ve Back Donor için)
  void _checkSensorBasedPosition() {
    final captureState = ref.read(captureProvider);
    final currentAngle = captureState.currentAngle ?? CaptureAngle.frontFace;

    // Sadece Vertex ve Back Donor için sensör kontrolü yap
    if (currentAngle == CaptureAngle.topVertex) {
      _isPositionValid = SensorAngleDetector.isVertexAngleValid(_pitch, _roll);
      _sensorGuidance = SensorAngleDetector.getVertexGuidance(_pitch, _roll);
    } else if (currentAngle == CaptureAngle.backDonor) {
      _isPositionValid = SensorAngleDetector.isBackDonorAngleValid(_pitch, _roll);
      _sensorGuidance = SensorAngleDetector.getBackDonorGuidance(_pitch, _roll);
    } else {
      // Front, Left, Right için yüz algılama kullanılacak
      _isPositionValid = false;
      _sensorGuidance = '';
      return;
    }

    // Pozisyon stabilitesini kontrol et
    _isPositionStable = SensorAngleDetector.isPositionStable(
      _pitchHistory,
      _rollHistory,
    );

    // Pozisyon doğru ve stabilse otomatik çekim için timer başlat
    if (_isPositionValid && _isPositionStable) {
      _startAutoCaptureTimer();
    } else {
      _cancelAutoCaptureTimer();
    }
  }

  /// Otomatik çekim timer'ı başlat (2 saniye sonra çek)
  void _startAutoCaptureTimer() {
    if (_autoCaptureTimer != null && _autoCaptureTimer!.isActive) {
      return; // Timer zaten aktif
    }

    _autoCaptureTimer?.cancel();
    _autoCaptureTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _isPositionValid && _isPositionStable && !_isCapturing) {
        final captureState = ref.read(captureProvider);
        final currentAngle = captureState.currentAngle;
        
        // Sadece Vertex ve Back Donor için otomatik çekim
        if (currentAngle == CaptureAngle.topVertex ||
            currentAngle == CaptureAngle.backDonor) {
          _capturePhoto();
        }
      }
    });
  }

  /// Otomatik çekim timer'ını iptal et
  void _cancelAutoCaptureTimer() {
    _autoCaptureTimer?.cancel();
    _autoCaptureTimer = null;
  }

  // Yüz algılama için frame sayacı (her N frame'de bir algılama yap)
  int _frameCount = 0;
  static const int _framesToSkip = 5; // Her 5 frame'de bir yüz algılama yap

  // Yüz algılama hatası sayacı - çok fazla hata varsa yüz algılamayı devre dışı bırak
  int _faceDetectionErrorCount = 0;
  bool _faceDetectionEnabled = true;

  Future<void> _processCameraImage(CameraImage image) async {
    // Mevcut açıya göre yüz algılamayı kontrol et
    final captureState = ref.read(captureProvider);
    final currentAngle = captureState.currentAngle ?? CaptureAngle.frontFace;

    // Vertex ve Back Donor için yüz algılama gerekmez (sensör kontrolü kullanılacak)
    if (currentAngle == CaptureAngle.topVertex ||
        currentAngle == CaptureAngle.backDonor) {
      if (mounted && _faceDetectionStatus != 'Sensör kontrolü aktif') {
        setState(() {
          _faceDetectionStatus = 'Sensör kontrolü aktif';
          _detectedFaces = [];
          _customPaint = null;
        });
      }
      return;
    }

    // Yüz algılama devre dışı bırakıldıysa atla
    if (!_faceDetectionEnabled) {
      if (mounted && _faceDetectionStatus != 'Yüz algılama devre dışı') {
        setState(() {
          _faceDetectionStatus = 'Yüz algılama devre dışı';
        });
      }
      return;
    }

    // Frame skip - performans için
    _frameCount++;
    if (_frameCount % _framesToSkip != 0) {
      return;
    }

    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final InputImage? inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final List<Face> faces = await _faceDetector.processImage(inputImage);
      
      // Başarılı algılama - hata sayacını sıfırla
      _faceDetectionErrorCount = 0;

      if (mounted) {
        // Yüzün doğru tarafının görünür olup olmadığını kontrol et
        bool isCorrectSide = false;
        String sideGuidance = '';
        
        if (faces.length == 1) {
          final face = faces[0];
          isCorrectSide = FaceSideDetector.isCorrectFaceSideVisible(face, currentAngle);
          sideGuidance = FaceSideDetector.getFaceSideGuidance(face, currentAngle);
        }

        setState(() {
          _detectedFaces = faces;
          _isCorrectFaceSide = isCorrectSide;
          _customPaint = _createCustomPaint(faces, image);
          
          // Yüz algılama durumu mesajını güncelle
          if (faces.isEmpty) {
            _faceDetectionStatus = 'Yüz algılanamadı - Kameraya bakın';
          } else if (faces.length == 1) {
            if (currentAngle == CaptureAngle.frontFace ||
                currentAngle == CaptureAngle.leftSide ||
                currentAngle == CaptureAngle.rightSide) {
              // Yüz yönü kontrolü gereken açılar için
              if (isCorrectSide) {
                _faceDetectionStatus = '✓ ${sideGuidance.isNotEmpty ? sideGuidance : "Pozisyon iyi - Fotoğraf çekilebilir"}';
              } else {
                _faceDetectionStatus = '⚠ $sideGuidance';
              }
            } else {
              _faceDetectionStatus = '✓ 1 yüz algılandı - Fotoğraf çekilebilir';
            }
          } else {
            _faceDetectionStatus = '⚠ ${faces.length} yüz algılandı - Tek başınıza çekim yapın';
          }
        });
      }
    } catch (e) {
      _faceDetectionErrorCount++;
      debugPrint('Yüz algılama hatası ($_faceDetectionErrorCount): $e');
      
      // 10'dan fazla hata varsa yüz algılamayı devre dışı bırak
      if (_faceDetectionErrorCount > 10) {
        _faceDetectionEnabled = false;
        if (mounted) {
          setState(() {
            _faceDetectionStatus = 'Yüz algılama devre dışı';
            _detectedFaces = [];
            _customPaint = null;
          });
        }
      } else if (mounted) {
        setState(() {
          _faceDetectionStatus = 'Yüz algılama hazır';
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameras == null || _cameras!.isEmpty || _cameraController == null) {
      return null;
    }

    try {
      final CameraDescription camera = _cameras![_currentCameraIndex];
      final imageRotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation);
      
      // Format kontrolü - YUV420 formatını doğru şekilde işle
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) {
        debugPrint('Format null: ${image.format.raw}');
        return null;
      }

      // YUV420 formatı için NV21'e dönüştür
      if (image.format.group == ImageFormatGroup.yuv420) {
        try {
          final nv21Bytes = ImageConverter.convertYUV420ToNV21(image);
          if (nv21Bytes == null) {
            return null;
          }

          // NV21 formatı için InputImage oluştur
          return InputImage.fromBytes(
            bytes: nv21Bytes,
            metadata: InputImageMetadata(
              size: Size(image.width.toDouble(), image.height.toDouble()),
              rotation: imageRotation!,
              format: InputImageFormat.nv21,
              bytesPerRow: image.width, // NV21 için bytesPerRow width'e eşit
            ),
          );
        } catch (e) {
          debugPrint('YUV420 to NV21 dönüşüm hatası: $e');
          return null;
        }
      }

      // imageRotation null kontrolü
      if (imageRotation == null) {
        debugPrint('Image rotation null');
        return null;
      }

      // Diğer formatlar için standart işleme
      final plane = image.planes[0];
      try {
        return InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: imageRotation,
            format: format,
            bytesPerRow: plane.bytesPerRow,
          ),
        );
      } catch (e) {
        debugPrint('InputImage oluşturma hatası: $e');
        return null;
      }
    } catch (e) {
      debugPrint('InputImage oluşturma hatası: $e');
      return null;
    }
  }

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

  /// Fotoğraf çekilebilir mi kontrol et
  bool _canCapturePhoto(CaptureAngle currentAngle) {
    if (_isCapturing || _cameraController == null || !_isCameraInitialized) {
      return false;
    }

    // Vertex ve Back Donor için sensör kontrolü
    if (currentAngle == CaptureAngle.topVertex ||
        currentAngle == CaptureAngle.backDonor) {
      return _isPositionValid && _isPositionStable;
    }

    // Front, Left, Right için yüz algılama ve yüz yönü kontrolü
    if (!_faceDetectionEnabled ||
        _detectedFaces.isEmpty ||
        _detectedFaces.length != 1) {
      return false;
    }

    // Yüzün doğru tarafının görünür olup olmadığını kontrol et
    if (currentAngle == CaptureAngle.frontFace ||
        currentAngle == CaptureAngle.leftSide ||
        currentAngle == CaptureAngle.rightSide) {
      return _isCorrectFaceSide;
    }

    return true;
  }

  Future<void> _capturePhoto() async {
    final captureState = ref.read(captureProvider);
    final currentAngle = captureState.currentAngle;
    
    if (currentAngle == null) {
      _showSnackBar('Açı seçilmedi');
      return;
    }

    if (!_canCapturePhoto(currentAngle)) {
      if (currentAngle == CaptureAngle.topVertex ||
          currentAngle == CaptureAngle.backDonor) {
        if (!_isPositionValid) {
          _showSnackBar('Doğru pozisyona gelin');
        } else if (!_isPositionStable) {
          _showSnackBar('Telefonu sabit tutun');
        }
      } else {
        if (!_faceDetectionEnabled) {
          _showSnackBar('Yüz algılama aktif değil. Lütfen bekleyin...');
              } else if (_detectedFaces.isEmpty) {
                _showSnackBar('Yüz algılanamadı. Lütfen kameraya bakın!');
              } else if (_detectedFaces.length > 1) {
                _showSnackBar('Birden fazla yüz algılandı. Lütfen tek başınıza çekim yapın.');
              } else if (!_isCorrectFaceSide) {
                // Yüzün doğru tarafı görünmüyor
                if (_detectedFaces.isNotEmpty) {
                  final guidance = FaceSideDetector.getFaceSideGuidance(
                    _detectedFaces[0],
                    currentAngle,
                  );
                  _showSnackBar(guidance);
                } else {
                  _showSnackBar('Lütfen yüzünüzün doğru tarafını gösterin.');
                }
              }
      }
      return;
    }

    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      final String savedPath = await _savePhoto(photo, currentAngle);

      ref.read(captureProvider.notifier).addCapturedPhoto(currentAngle, savedPath);

      setState(() {
        _isCapturing = false;
      });

      _showSnackBar('Fotoğraf çekildi: ${currentAngle.name}');

      // Sonraki açıya geç veya summary'ye yönlendir
      final captureNotifier = ref.read(captureProvider.notifier);
      final nextAngle = captureNotifier.getNextAngle();
      if (nextAngle != null) {
        captureNotifier.setCurrentAngle(nextAngle);
      } else {
        // Tüm fotoğraflar çekildi
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            context.go('/summary');
          }
        });
      }
    } catch (e) {
      debugPrint('Fotoğraf çekme hatası: $e');
      _showSnackBar('Fotoğraf çekilemedi: $e');
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<String> _savePhoto(XFile photo, CaptureAngle angle) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String photosDir = path.join(appDir.path, 'captured_photos');
      final Directory dir = Directory(photosDir);
      
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${angle.name}_$timestamp.jpg';
      final String filePath = path.join(photosDir, fileName);

      await photo.saveTo(filePath);
      return filePath;
    } catch (e) {
      debugPrint('Fotoğraf kaydetme hatası: $e');
      rethrow;
    }
  }

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
    _cancelAutoCaptureTimer();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureProvider);
    final currentAngle = captureState.currentAngle ?? CaptureAngle.frontFace;

    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Kamera preview boyutunu al
    final previewSize = _cameraController!.value.previewSize;

    // Oval boyutları
    const double ovalWidth = 240;
    const double ovalHeight = 300;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Kamera Önizlemesi - Oval mask ile
          Positioned.fill(
            child: OvalCameraMask(
              cameraPreview: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: previewSize?.height ?? 480,
                    height: previewSize?.width ?? 640,
                    child: Stack(
                      children: [
                        CameraPreview(_cameraController!),
                        // Yüz algılama bounding box'ları (sadece oval içinde görünecek)
                        if (_customPaint != null)
                          _customPaint!,
                      ],
                    ),
                  ),
                ),
              ),
              width: ovalWidth,
              height: ovalHeight,
              backgroundColor: Colors.white,
            ),
          ),

          // Oval border (kırmızı çerçeve)
          Center(
            child: Container(
              width: ovalWidth,
              height: ovalHeight,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(ovalHeight / 2),
                // border: Border.all(
                //   color: Colors.red,
                //   width: 3.0,
                // ),
              ),
            ),
          ),

          // Circle dışında 5 parçalı yeşil progress ring
          Center(
            child: CircularProgressRing(
              completedSteps: captureState.completedCount,
              totalSteps: 5,
              circleRadius: ovalHeight / 2 + 5, // Oval'ın 5px dışında
              strokeWidth: 10.0,
              completedColor: Colors.green,
              remainingColor: Colors.grey.shade300,
            ),
          ),

          // Üst başlık (sadece açı adı)
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                currentAngle.name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Geri ve sıfırlama butonları (sol üst)
          Positioned(
            top: 50,
            left: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: 'backToGuide',
                  onPressed: () {
                    context.go('/guide');
                  },
                  backgroundColor: Colors.black.withOpacity(0.6),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  mini: true,
                  heroTag: 'resetCaptures',
                  onPressed: _resetCaptureProgress,
                  backgroundColor: Colors.black.withOpacity(0.6),
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Kamera değiştirme butonu
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

          // Alt kısım - İlerleme çubuğu ve butonlar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sensör bazlı yönlendirme (Vertex ve Back Donor için)
                    if (currentAngle == CaptureAngle.topVertex ||
                        currentAngle == CaptureAngle.backDonor)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Column(
                          children: [
                            // Debug: Pitch ve Roll değerleri (test için)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Pitch: ${_pitch.toStringAsFixed(1)}°',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Roll: ${_roll.toStringAsFixed(1)}°',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Yönlendirme mesajı
                            Text(
                              _sensorGuidance.isNotEmpty
                                  ? _sensorGuidance
                                  : 'Pozisyonu ayarlayın...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isPositionValid && _isPositionStable
                                    ? Colors.green
                                    : Colors.orange,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Pozisyon durumu göstergesi
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Pozisyon geçerliliği
                                Icon(
                                  _isPositionValid
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _isPositionValid
                                      ? Colors.green
                                      : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pozisyon: ${_isPositionValid ? "Doğru" : "Yanlış"}',
                                  style: TextStyle(
                                    color: _isPositionValid
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Stabilite durumu
                                Icon(
                                  _isPositionStable
                                      ? Icons.check_circle
                                      : Icons.sync,
                                  color: _isPositionStable
                                      ? Colors.green
                                      : Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Stabil: ${_isPositionStable ? "Evet" : "Hayır"}',
                                  style: TextStyle(
                                    color: _isPositionStable
                                        ? Colors.green
                                        : Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            if (_isPositionValid && _isPositionStable)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  '2 saniye sonra otomatik çekim yapılacak',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    // Talimat metni (Front, Left, Right için)
                    if (currentAngle != CaptureAngle.topVertex &&
                        currentAngle != CaptureAngle.backDonor)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Text(
                          currentAngle.instruction,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    // Yüz algılama durumu (Front, Left, Right için)
                    if (currentAngle != CaptureAngle.topVertex &&
                        currentAngle != CaptureAngle.backDonor &&
                        _faceDetectionEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _faceDetectionStatus,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _detectedFaces.isEmpty
                                ? Colors.orange
                                : (_detectedFaces.length == 1
                                    ? Colors.green
                                    : Colors.red),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Fotoğraf çekme butonu
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: FloatingActionButton(
                        heroTag: 'capture',
                        onPressed: _canCapturePhoto(currentAngle)
                            ? _capturePhoto
                            : null,
                        backgroundColor: _canCapturePhoto(currentAngle)
                            ? Colors.red
                            : Colors.grey.shade400,
                        child: _isCapturing
                            ? const SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 30,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
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
    final double scaleX = size.width / imageSize.height;
    final double scaleY = size.height / imageSize.width;

    for (Face face in faces) {
      final Rect boundingBox = face.boundingBox;
      final double left = boundingBox.left * scaleX;
      final double top = boundingBox.top * scaleY;
      final double width = boundingBox.width * scaleX;
      final double height = boundingBox.height * scaleY;

      final Paint paint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRect(
        Rect.fromLTWH(left, top, width, height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.cameraPreviewSize != cameraPreviewSize;
  }
}

