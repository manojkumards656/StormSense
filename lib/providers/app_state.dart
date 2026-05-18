import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/weather_conditions.dart';
import '../models/strike_record.dart';
import '../services/lightning_detector.dart';
import '../services/thunder_detector.dart';
import '../services/storage_service.dart';

enum AppStatus { idle, monitoring, flashDetected }

class AppState extends ChangeNotifier {
  final StorageService _storageService;
  final LightningDetector _lightningDetector;
  final ThunderDetector _thunderDetector;

  AppStatus _status = AppStatus.idle;
  WeatherConditions _weatherConditions;
  List<StrikeRecord> _strikeHistory = [];

  // Timer and distances
  DateTime? _flashTime;
  Timer? _activeTimer;
  double _elapsedSeconds = 0.0;
  
  double? _lastEstimatedDistanceKm;

  AppState(this._storageService, this._lightningDetector, this._thunderDetector)
      : _weatherConditions = _storageService.getWeatherConditions() {
    _strikeHistory = _storageService.getStrikeHistory();
    
    _lightningDetector.onFlashDetected = _handleFlashDetected;
    _thunderDetector.onThunderDetected = _handleThunderDetected;
  }

  AppStatus get status => _status;
  WeatherConditions get weatherConditions => _weatherConditions;
  List<StrikeRecord> get strikeHistory => _strikeHistory;
  double get elapsedSeconds => _elapsedSeconds;
  double? get lastEstimatedDistanceKm => _lastEstimatedDistanceKm;
  
  Stream<double> get brightnessStream => _lightningDetector.brightnessStream;
  Stream<double> get amplitudeStream => _thunderDetector.amplitudeStream;

  void updateWeather(WeatherConditions conditions) {
    _weatherConditions = conditions;
    _storageService.saveWeatherConditions(conditions);
    notifyListeners();
  }

  Future<void> toggleMonitoring() async {
    if (_status == AppStatus.idle) {
      await _startMonitoring();
    } else {
      await _stopMonitoring();
    }
  }

  Future<void> _startMonitoring() async {
    _status = AppStatus.monitoring;
    _lastEstimatedDistanceKm = null;
    _elapsedSeconds = 0.0;
    notifyListeners();
    
    await _lightningDetector.startMonitoring();
    await _thunderDetector.startMonitoring();
  }

  Future<void> _stopMonitoring() async {
    _status = AppStatus.idle;
    _cancelTimer();
    notifyListeners();
    
    await _lightningDetector.stopMonitoring();
    await _thunderDetector.stopMonitoring();
  }

  void _handleFlashDetected() {
    if (_status != AppStatus.monitoring) return;
    
    _status = AppStatus.flashDetected;
    _flashTime = DateTime.now();
    _elapsedSeconds = 0.0;
    
    // Start live timer
    _activeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_flashTime != null) {
        _elapsedSeconds = DateTime.now().difference(_flashTime!).inMilliseconds / 1000.0;
        
        // Timeout if no thunder after 30 seconds
        if (_elapsedSeconds > 30.0) {
          _cancelTimer();
          _status = AppStatus.monitoring; // Go back to listening for flash
        }
        notifyListeners();
      }
    });
    
    notifyListeners();
  }

  void _handleThunderDetected() {
    if (_status != AppStatus.flashDetected || _flashTime == null) return;
    
    final delay = DateTime.now().difference(_flashTime!).inMilliseconds / 1000.0;
    
    // Valid thunder should occur between 1 and 30 seconds after flash
    if (delay >= 1.0 && delay <= 30.0) {
      _cancelTimer();
      _elapsedSeconds = delay;
      
      _calculateAndSaveDistance(delay);
      
      _status = AppStatus.monitoring; // Ready for next strike
      notifyListeners();
    }
  }

  void _calculateAndSaveDistance(double delaySeconds) {
    // Base speed of sound: 331 + 0.6 * T
    double speedOfSound = 331.0 + (0.6 * _weatherConditions.temperatureCelsius);
    
    // Humidity adjustments
    double humidityMultiplier = 1.0;
    switch (_weatherConditions.humidity) {
      case HumidityLevel.low:
        humidityMultiplier = 0.99; // -1%
        break;
      case HumidityLevel.medium:
        humidityMultiplier = 1.0;
        break;
      case HumidityLevel.high:
        humidityMultiplier = 1.02; // +2%
        break;
    }
    
    // Wind adjustments (using simplified static values)
    double windMultiplier = 1.0;
    switch (_weatherConditions.wind) {
      case WindLevel.calm:
        windMultiplier = 1.0;
        break;
      case WindLevel.breezy:
        windMultiplier = 1.03; // +3%
        break;
      case WindLevel.windy:
        windMultiplier = 1.06; // +6%
        break;
    }
    
    double adjustedSpeed = speedOfSound * humidityMultiplier * windMultiplier;
    
    // Distance in meters
    double distanceMeters = delaySeconds * adjustedSpeed;
    _lastEstimatedDistanceKm = distanceMeters / 1000.0;
    
    final record = StrikeRecord(
      timestamp: DateTime.now(),
      delaySeconds: delaySeconds,
      estimatedDistanceKm: _lastEstimatedDistanceKm!,
      weatherConditions: _weatherConditions,
    );
    
    _strikeHistory.insert(0, record);
    _storageService.saveStrikeRecord(record);
  }

  void _cancelTimer() {
    _activeTimer?.cancel();
    _activeTimer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    _lightningDetector.dispose();
    _thunderDetector.dispose();
    super.dispose();
  }
}
