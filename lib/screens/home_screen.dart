import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/app_state.dart';
import '../models/weather_conditions.dart';
import '../theme/app_theme.dart';
import '../widgets/safety_banner.dart';
import '../widgets/signal_graphs.dart';
import '../widgets/strike_history.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('StormSense'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (appState.lastEstimatedDistanceKm != null)
                SafetyBanner(distanceKm: appState.lastEstimatedDistanceKm!),
                
              _buildStatusCard(appState),
              const SizedBox(height: 24),
              
              if (appState.status != AppStatus.idle)
                SignalGraphsWidget(
                  brightnessStream: appState.brightnessStream,
                  amplitudeStream: appState.amplitudeStream,
                ),
                
              const SizedBox(height: 24),
              _buildWeatherConfig(appState),
              const SizedBox(height: 24),
              _buildTuningConfig(appState),
              const SizedBox(height: 24),
              
              const Text("Strike History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StrikeHistoryWidget(records: appState.strikeHistory),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(AppState appState) {
    bool isMonitoring = appState.status != AppStatus.idle;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (appState.status == AppStatus.flashDetected) ...[
              const Icon(Icons.flash_on, color: Colors.yellow, size: 48),
              const SizedBox(height: 8),
              Text(
                "${appState.elapsedSeconds.toStringAsFixed(1)}s",
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
              ),
              const Text("Listening for thunder...", style: TextStyle(color: AppTheme.textMuted)),
            ] else if (appState.lastEstimatedDistanceKm != null) ...[
              const Icon(Icons.thunderstorm, color: AppTheme.accentColor, size: 48),
              const SizedBox(height: 8),
              Text(
                "${appState.lastEstimatedDistanceKm!.toStringAsFixed(2)} km",
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const Text("Last estimated distance", style: TextStyle(color: AppTheme.textMuted)),
            ] else ...[
              Icon(
                isMonitoring ? Icons.radar : Icons.shield,
                color: isMonitoring ? AppTheme.accentColor : AppTheme.textMuted,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                isMonitoring ? "Monitoring environment" : "Ready to detect",
                style: const TextStyle(fontSize: 18, color: AppTheme.textMuted),
              ),
            ],
            
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => appState.toggleMonitoring(),
              icon: Icon(isMonitoring ? Icons.stop : Icons.play_arrow),
              label: Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isMonitoring ? AppTheme.criticalColor : AppTheme.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherConfig(AppState appState) {
    final weather = appState.weatherConditions;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Weather Adjustments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            // Temperature Slider
            Row(
              children: [
                const Icon(Icons.thermostat, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                const Text("Temp:"),
                Expanded(
                  child: Slider(
                    value: weather.temperatureCelsius,
                    min: -10,
                    max: 45,
                    divisions: 55,
                    label: "${weather.temperatureCelsius.round()}°C",
                    onChanged: (val) {
                      appState.updateWeather(weather.copyWith(temperatureCelsius: val));
                    },
                  ),
                ),
                Text("${weather.temperatureCelsius.round()}°C"),
              ],
            ),
            
            // Humidity Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.water_drop, color: AppTheme.textMuted),
                    SizedBox(width: 8),
                    Text("Humidity:"),
                  ],
                ),
                DropdownButton<HumidityLevel>(
                  value: weather.humidity,
                  dropdownColor: AppTheme.secondaryDark,
                  items: HumidityLevel.values.map((h) {
                    return DropdownMenuItem(
                      value: h,
                      child: Text(h.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) appState.updateWeather(weather.copyWith(humidity: val));
                  },
                ),
              ],
            ),
            
            // Wind Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.air, color: AppTheme.textMuted),
                    SizedBox(width: 8),
                    Text("Wind:"),
                  ],
                ),
                DropdownButton<WindLevel>(
                  value: weather.wind,
                  dropdownColor: AppTheme.secondaryDark,
                  items: WindLevel.values.map((w) {
                    return DropdownMenuItem(
                      value: w,
                      child: Text(w.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) appState.updateWeather(weather.copyWith(wind: val));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTuningConfig(AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Filter Tuning (Advanced)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            // RMS Threshold
            Row(
              children: [
                const Icon(Icons.volume_up, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                const Text("Min Vol:"),
                Expanded(
                  child: Slider(
                    value: appState.rmsThreshold,
                    min: 0.01,
                    max: 0.5,
                    divisions: 49,
                    label: appState.rmsThreshold.toStringAsFixed(2),
                    onChanged: (val) {
                      appState.setRmsThreshold(val);
                    },
                  ),
                ),
                Text(appState.rmsThreshold.toStringAsFixed(2)),
              ],
            ),
            
            // Low Freq Energy Ratio
            Row(
              children: [
                const Icon(Icons.graphic_eq, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                const Text("LF Ratio:"),
                Expanded(
                  child: Slider(
                    value: appState.lowFreqEnergyRatio,
                    min: 0.1,
                    max: 0.9,
                    divisions: 80,
                    label: appState.lowFreqEnergyRatio.toStringAsFixed(2),
                    onChanged: (val) {
                      appState.setLowFreqEnergyRatio(val);
                    },
                  ),
                ),
                Text(appState.lowFreqEnergyRatio.toStringAsFixed(2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

