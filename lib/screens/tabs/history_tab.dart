import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/strike_history.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Recent Strikes",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "History of detected lightning and thunder events.",
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: AppTheme.glassDecoration,
                padding: const EdgeInsets.all(16.0),
                child: StrikeHistoryWidget(records: appState.strikeHistory),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
