import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'services/lightning_detector.dart';
import 'services/storage_service.dart';
import 'services/thunder_detector.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final storageService = await StorageService.init();
  final lightningDetector = LightningDetector();
  final thunderDetector = ThunderDetector();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(
            storageService,
            lightningDetector,
            thunderDetector,
          ),
        ),
      ],
      child: const StormSenseApp(),
    ),
  );
}

class StormSenseApp extends StatelessWidget {
  const StormSenseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StormSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
