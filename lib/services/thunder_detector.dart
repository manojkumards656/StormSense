import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:fftea/fftea.dart';
import 'package:flutter/foundation.dart';

class ThunderDetector {
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription? _audioSubscription;
  bool _isMonitoring = false;

  // Signal processing parameters
  static const int sampleRate = 8000;
  static const int bufferSize = 1024; // Must be power of 2 for FFT
  
  final _amplitudeStreamController = StreamController<double>.broadcast();
  Stream<double> get amplitudeStream => _amplitudeStreamController.stream;

  final _frequencyStreamController = StreamController<List<double>>.broadcast();
  Stream<List<double>> get frequencyStream => _frequencyStreamController.stream;

  Function()? onThunderDetected;

  // State for duration tracking
  DateTime? _thunderStartTime;
  
  // Configuration thresholds
  double rmsThreshold = 0.05; 
  int minDurationMs = 300;
  final Duration maxDuration = const Duration(seconds: 5);
  final Duration impulseRejectDuration = const Duration(milliseconds: 150);
  
  // Low frequency band for thunder (20Hz - maxFreqHz)
  static const double minFreq = 20.0;
  double maxFreq = 300.0;
  double lowFreqEnergyRatio = 0.5;
  
  // Calibration State
  bool _isCalibrating = false;
  final List<double> _calibrationRms = [];
  final List<double> _calibrationLfRatios = [];

  bool get isMonitoring => _isMonitoring;
  bool get isCalibrating => _isCalibrating;

  Future<void> startCalibration() async {
    _calibrationRms.clear();
    _calibrationLfRatios.clear();
    _isCalibrating = true;
    if (!_isMonitoring) {
      await startMonitoring();
    }
  }

  void stopCalibration() {
    _isCalibrating = false;
    if (_calibrationRms.isEmpty || _calibrationLfRatios.isEmpty) return;

    // Filter out quiet parts (bottom 25% of RMS)
    final sortedRms = List<double>.from(_calibrationRms)..sort();
    final thresholdIndex = (sortedRms.length * 0.25).floor();
    final activeRmsThreshold = sortedRms[thresholdIndex];

    double sumRms = 0;
    double sumLfRatio = 0;
    int count = 0;

    for (int i = 0; i < _calibrationRms.length; i++) {
      if (_calibrationRms[i] >= activeRmsThreshold) {
        sumRms += _calibrationRms[i];
        sumLfRatio += _calibrationLfRatios[i];
        count++;
      }
    }

    if (count > 0) {
      final averageRms = sumRms / count;
      final averageLfRatio = sumLfRatio / count;

      rmsThreshold = (averageRms * 0.5).clamp(0.001, 1.0);
      lowFreqEnergyRatio = (averageLfRatio * 0.8).clamp(0.01, 1.0);
      
      debugPrint("Calibrated! New RMS: $rmsThreshold, New LF: $lowFreqEnergyRatio");
    }
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    if (await _audioRecorder.hasPermission()) {
      _isMonitoring = true;
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
        ),
      );

      // We need to buffer data to bufferSize chunks for FFT
      List<int> buffer = [];

      _audioSubscription = stream.listen((Uint8List data) {
        if (!_isMonitoring) return;
        
        // Convert PCM 16-bit to Int16List then to double list [-1.0, 1.0]
        final int16Data = data.buffer.asInt16List();
        
        for (int i = 0; i < int16Data.length; i++) {
          buffer.add(int16Data[i]);
          if (buffer.length == bufferSize) {
            _processAudioBuffer(buffer);
            buffer = [];
          }
        }
      });
    }
  }

  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;
    _isMonitoring = false;
    await _audioSubscription?.cancel();
    await _audioRecorder.stop();
  }

  void _processAudioBuffer(List<int> int16Buffer) {
    // Normalize to [-1.0, 1.0]
    final doubleBuffer = int16Buffer.map((s) => s / 32768.0).toList();
    
    // 1. Compute RMS Amplitude
    double sqSum = 0;
    for (final sample in doubleBuffer) {
      sqSum += sample * sample;
    }
    final rms = sqrt(sqSum / doubleBuffer.length);
    
    _amplitudeStreamController.add(rms);

    if (rms < rmsThreshold) {
      _evaluateThunderDuration();
      _thunderStartTime = null; // Reset
      return;
    }

    // 2. Perform FFT
    final fft = FFT(bufferSize);
    final freqData = fft.realFft(doubleBuffer);
    
    // Compute magnitude spectrum
    final magnitudes = freqData.discardConjugates().magnitudes();
    _frequencyStreamController.add(magnitudes);
    
    // 3. Analyze low-frequency band
    // Frequency resolution = sampleRate / bufferSize (e.g. 8000/1024 = 7.8Hz per bin)
    final double binWidth = sampleRate / bufferSize;
    int minBin = (minFreq / binWidth).floor();
    int maxBin = (maxFreq / binWidth).ceil();
    
    double lowFreqEnergy = 0;
    double totalEnergy = 0;
    
    for (int i = 0; i < magnitudes.length; i++) {
      final energy = magnitudes[i] * magnitudes[i];
      totalEnergy += energy;
      if (i >= minBin && i <= maxBin) {
        lowFreqEnergy += energy;
      }
    }
    
    final double lfRatio = totalEnergy > 0 ? (lowFreqEnergy / totalEnergy) : 0;
    
    if (_isCalibrating) {
      _calibrationRms.add(rms);
      _calibrationLfRatios.add(lfRatio);
    }
    
    // Check if dominant energy is in low frequency band
    if (totalEnergy > 0 && lfRatio > lowFreqEnergyRatio) {
      if (_thunderStartTime == null) {
        _thunderStartTime = DateTime.now();
      }
    } else {
      // Sound is loud but not low frequency (e.g. talking, dropping something)
      _evaluateThunderDuration();
      _thunderStartTime = null;
    }
  }

  void _evaluateThunderDuration() {
    if (_thunderStartTime == null) return;
    
    final duration = DateTime.now().difference(_thunderStartTime!);
    
    final minDuration = Duration(milliseconds: minDurationMs);
    if (duration > minDuration && duration < maxDuration) {
      // Valid thunder rumble duration
      debugPrint("Thunder detected! Duration: ${duration.inMilliseconds}ms");
      onThunderDetected?.call();
    }
    // Note: If duration < impulseRejectDuration, it's rejected as short impulse
  }

  void dispose() {
    stopMonitoring();
    _amplitudeStreamController.close();
    _frequencyStreamController.close();
    _audioRecorder.dispose();
  }
}
