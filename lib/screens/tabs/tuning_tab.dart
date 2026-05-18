import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../models/weather_conditions.dart';
import '../../theme/app_theme.dart';

class TuningTab extends StatelessWidget {
  const TuningTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Settings & Tuning",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Configure environmental variables and detection sensitivity.",
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            _buildWeatherConfig(appState),
            const SizedBox(height: 24),
            _buildTuningConfig(appState),
            const SizedBox(height: 24),
            _buildThemeConfig(appState),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherConfig(AppState appState) {
    final weather = appState.weatherConditions;
    
    return Container(
      decoration: AppTheme.glassDecoration,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Weather Adjustments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          
          // Temperature Slider
          Row(
            children: [
              Icon(Icons.thermostat, color: appState.accentColor),
              const SizedBox(width: 12),
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
              SizedBox(
                width: 48,
                child: Text("${weather.temperatureCelsius.round()}°C", textAlign: TextAlign.right),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Humidity Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop, color: appState.accentColor),
                  const SizedBox(width: 12),
                  const Text("Humidity", style: TextStyle(fontSize: 16)),
                ],
              ),
              DropdownButton<HumidityLevel>(
                value: weather.humidity,
                dropdownColor: AppTheme.secondaryDark,
                underline: Container(),
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
          const SizedBox(height: 16),
          
          // Wind Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.air, color: appState.accentColor),
                  const SizedBox(width: 12),
                  const Text("Wind", style: TextStyle(fontSize: 16)),
                ],
              ),
              DropdownButton<WindLevel>(
                value: weather.wind,
                dropdownColor: AppTheme.secondaryDark,
                underline: Container(),
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
    );
  }

  Widget _buildTuningConfig(AppState appState) {
    return Container(
      decoration: AppTheme.glassDecoration,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Detection Tuning", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),

          // Light Detection Mode
          SwitchListTile(
            title: const Text("Auto Brightness Calib"),
            subtitle: const Text("Learns ambient brightness"),
            value: appState.isLightAutoMode,
            onChanged: (val) => appState.setLightAutoMode(val),
            contentPadding: EdgeInsets.zero,
          ),
          if (!appState.isLightAutoMode)
            Row(
              children: [
                Icon(Icons.lightbulb, color: appState.accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: appState.manualLightThreshold,
                    min: 10.0,
                    max: 255.0,
                    divisions: 245,
                    label: appState.manualLightThreshold.round().toString(),
                    onChanged: (val) => appState.setManualLightThreshold(val),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(appState.manualLightThreshold.round().toString(), textAlign: TextAlign.right),
                ),
              ],
            ),
          
          const Divider(height: 48, color: Colors.white24),

          // Audio Detection Mode
          SwitchListTile(
            title: const Text("Auto Noise Calib"),
            subtitle: const Text("Learns ambient background noise"),
            value: appState.isAudioAutoMode,
            onChanged: (val) => appState.setAudioAutoMode(val),
            contentPadding: EdgeInsets.zero,
          ),
          
          const SizedBox(height: 16),
          
          // Auto Calibration Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => appState.toggleCalibration(),
              icon: Icon(appState.isCalibrating ? Icons.stop : Icons.mic),
              label: Text(appState.isCalibrating ? "Stop Recording" : "Record Thunder Sample"),
              style: ElevatedButton.styleFrom(
                backgroundColor: appState.isCalibrating ? AppTheme.criticalColor : appState.accentColor.withOpacity(0.2),
                foregroundColor: appState.isCalibrating ? Colors.white : appState.accentColor,
                elevation: 0,
                side: BorderSide(color: appState.accentColor.withOpacity(0.5)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // RMS Threshold
          Row(
            children: [
              Icon(Icons.volume_up, color: appState.accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: appState.rmsThreshold,
                  min: 0.001,
                  max: 1.0,
                  divisions: 100,
                  label: appState.rmsThreshold.toStringAsFixed(3),
                  onChanged: (val) {
                    appState.setRmsThreshold(val);
                  },
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(appState.rmsThreshold.toStringAsFixed(2), textAlign: TextAlign.right),
              ),
            ],
          ),
          
          // Low Freq Energy Ratio
          Row(
            children: [
              Icon(Icons.graphic_eq, color: appState.accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: appState.lowFreqEnergyRatio,
                  min: 0.01,
                  max: 1.0,
                  divisions: 100,
                  label: appState.lowFreqEnergyRatio.toStringAsFixed(2),
                  onChanged: (val) {
                    appState.setLowFreqEnergyRatio(val);
                  },
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(appState.lowFreqEnergyRatio.toStringAsFixed(2), textAlign: TextAlign.right),
              ),
            ],
          ),

          // Min Duration
          Row(
            children: [
              Icon(Icons.timer, color: appState.accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: appState.minDurationMs.toDouble(),
                  min: 50,
                  max: 1000,
                  divisions: 95,
                  label: "${appState.minDurationMs}ms",
                  onChanged: (val) {
                    appState.setMinDurationMs(val.round());
                  },
                ),
              ),
              SizedBox(
                width: 40,
                child: Text("${appState.minDurationMs}", textAlign: TextAlign.right),
              ),
            ],
          ),

          // Max Freq
          Row(
            children: [
              Icon(Icons.waves, color: appState.accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: appState.maxFreq,
                  min: 100,
                  max: 2000,
                  divisions: 190,
                  label: "${appState.maxFreq.round()}Hz",
                  onChanged: (val) {
                    appState.setMaxFreq(val);
                  },
                ),
              ),
              SizedBox(
                width: 40,
                child: Text("${appState.maxFreq.round()}", textAlign: TextAlign.right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeConfig(AppState appState) {
    final List<Color> palette = [
      const Color(0xFF0EA5E9), // Sky Blue
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFF59E0B), // Amber/Lightning
      const Color(0xFF10B981), // Emerald
      const Color(0xFFEC4899), // Pink
      const Color(0xFF94A3B8), // Slate Grey
    ];

    return Container(
      decoration: AppTheme.glassDecoration,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Accent Color", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: palette.map((color) {
              bool isSelected = appState.accentColor == color;
              return GestureDetector(
                onTap: () => appState.setAccentColor(color),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
