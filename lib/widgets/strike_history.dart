import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/strike_record.dart';
import '../theme/app_theme.dart';

class StrikeHistoryWidget extends StatelessWidget {
  final List<StrikeRecord> records;

  const StrikeHistoryWidget({Key? key, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            "No strikes recorded yet.\nStart monitoring to detect lightning.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryDark,
              child: const Icon(Icons.flash_on, color: AppTheme.warningColor),
            ),
            title: Text(
              "${record.estimatedDistanceKm.toStringAsFixed(2)} km away",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${record.delaySeconds.toStringAsFixed(1)}s delay • ${DateFormat('HH:mm:ss').format(record.timestamp)}",
            ),
            trailing: _buildWeatherIcons(record),
          ),
        );
      },
    );
  }

  Widget _buildWeatherIcons(StrikeRecord record) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.thermostat, size: 16, color: AppTheme.textMuted),
        Text("${record.weatherConditions.temperatureCelsius.toInt()}°", style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ],
    );
  }
}
