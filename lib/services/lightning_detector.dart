import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class LightningDetector {
  CameraController? _cameraController;
  bool _isMonitoring = false;
  
  // Brightness tracking
  final int _historyLength = 30; // Rolling average history size
  final List<double> _brightnessHistory = [];
  
  // Configuration
  bool isAutoMode = true;
  double manualThreshold = 150.0;
  final double flashMultiplier = 3.0; // Flash threshold multiplier
  final Duration cooldown = const Duration(seconds: 10);
  
  DateTime? _lastDetectionTime;
  
  final _brightnessStreamController = StreamController<double>.broadcast();
  Stream<double> get brightnessStream => _brightnessStreamController.stream;

  Function()? onFlashDetected;

  bool get isMonitoring => _isMonitoring;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint("No cameras available.");
      return;
    }

    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    // Low resolution for battery efficiency
    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    
    _brightnessHistory.clear();
    _isMonitoring = true;

    _cameraController!.startImageStream((CameraImage image) {
      _processImage(image);
    });
  }

  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;
    _isMonitoring = false;
    
    if (_cameraController?.value.isStreamingImages ?? false) {
      await _cameraController!.stopImageStream();
    }
    
    await _cameraController?.dispose();
    _cameraController = null;
  }

  void _processImage(CameraImage image) {
    if (!_isMonitoring) return;

    // Calculate average brightness
    // Using Y plane from YUV420 format (luminance)
    final yPlane = image.planes.first;
    final bytes = yPlane.bytes;
    
    // Subsample for efficiency: every 10th pixel
    int sum = 0;
    int count = 0;
    for (int i = 0; i < bytes.length; i += 10) {
      sum += bytes[i];
      count++;
    }
    
    final currentBrightness = sum / count;
    _brightnessStreamController.add(currentBrightness);

    _detectFlash(currentBrightness);

    // Update rolling average
    _brightnessHistory.add(currentBrightness);
    if (_brightnessHistory.length > _historyLength) {
      _brightnessHistory.removeAt(0);
    }
  }

  void _detectFlash(double currentBrightness) {
    bool isFlash = false;

    if (isAutoMode) {
      if (_brightnessHistory.length < 10) return; // Need some baseline
      final averageBrightness = _brightnessHistory.reduce((a, b) => a + b) / _brightnessHistory.length;
      
      // Sudden spike detection
      if (currentBrightness > averageBrightness * flashMultiplier) {
        isFlash = true;
      }
    } else {
      if (currentBrightness >= manualThreshold) {
        isFlash = true;
      }
    }

    if (isFlash) {
      final now = DateTime.now();
      if (_lastDetectionTime == null || now.difference(_lastDetectionTime!) > cooldown) {
        _lastDetectionTime = now;
        debugPrint("Lightning flash detected! Brightness: $currentBrightness");
        onFlashDetected?.call();
      }
    }
  }

  void dispose() {
    stopMonitoring();
    _brightnessStreamController.close();
  }
}
