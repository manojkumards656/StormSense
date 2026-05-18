import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/safety_banner.dart';
import '../../widgets/signal_graphs.dart';
import '../../widgets/weather_background.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    return Stack(
      children: [
        // New Dynamic Weather Background
        WeatherBackground(
          isFlashing: appState.status == AppStatus.flashDetected,
        ),
        
        // Content
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (appState.lastEstimatedDistanceKm != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: SafetyBanner(distanceKm: appState.lastEstimatedDistanceKm!),
                  ),
                  
                _buildStatusGlassCard(context, appState),
                const SizedBox(height: 32),
                
                if (appState.status != AppStatus.idle)
                  Container(
                    decoration: AppTheme.glassDecoration,
                    padding: const EdgeInsets.all(16.0),
                    child: SignalGraphsWidget(
                      brightnessStream: appState.brightnessStream,
                      amplitudeStream: appState.amplitudeStream,
                      frequencyStream: appState.frequencyStream,
                      maxFreq: appState.maxFreq,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusGlassCard(BuildContext context, AppState appState) {
    bool isMonitoring = appState.status != AppStatus.idle;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Increased blur for better contrast
        child: Container(
          decoration: AppTheme.glassDecoration,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              if (appState.status == AppStatus.flashDetected) ...[
                const Icon(Icons.flash_on, color: Colors.yellow, size: 64),
                const SizedBox(height: 16),
                Text(
                  "${appState.elapsedSeconds.toStringAsFixed(1)}s",
                  style: TextStyle(
                    fontSize: 64, 
                    fontWeight: FontWeight.w800, 
                    color: appState.accentColor,
                  ),
                ),
                const Text("Listening for thunder...", 
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                ),
              ] else if (appState.lastEstimatedDistanceKm != null) ...[
                Icon(Icons.thunderstorm, color: appState.accentColor, size: 64),
                const SizedBox(height: 16),
                Text(
                  "${appState.lastEstimatedDistanceKm!.toStringAsFixed(1)} km",
                  style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800),
                ),
                const Text("Storm Distance", 
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                ),
              ] else ...[
                Icon(
                  isMonitoring ? Icons.hearing : Icons.mic_none,
                  color: isMonitoring ? appState.accentColor : AppTheme.textMuted,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  isMonitoring ? "Monitoring environment" : "Ready to detect",
                  style: const TextStyle(fontSize: 20, color: AppTheme.textMuted),
                ),
              ],
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => appState.toggleMonitoring(),
                  icon: Icon(isMonitoring ? Icons.stop : Icons.fiber_manual_record),
                  label: Text(isMonitoring ? "Stop Recording" : "Start Recording"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMonitoring ? AppTheme.criticalColor : appState.accentColor,
                    foregroundColor: isMonitoring ? Colors.white : AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


