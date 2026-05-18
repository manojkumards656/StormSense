import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class WeatherBackground extends StatefulWidget {
  final bool isFlashing;

  const WeatherBackground({Key? key, required this.isFlashing}) : super(key: key);

  @override
  _WeatherBackgroundState createState() => _WeatherBackgroundState();
}

class _WeatherBackgroundState extends State<WeatherBackground> with TickerProviderStateMixin {
  late AnimationController _rainController;
  late AnimationController _cloudController;
  final RainPainter _rainPainter = RainPainter();

  @override
  void initState() {
    super.initState();
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Speed of rain cycle
    )..repeat();

    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60), // Slower, grander cloud movement
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rainController.dispose();
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base sky color - Stormy slate blue
        Container(
          color: const Color(0xFF1E293B),
        ),

        // Clouds layer
        AnimatedBuilder(
          animation: _cloudController,
          builder: (context, child) {
            // Use sine waves to occasionally increase cloud density/opacity
            final denseOpacity1 = 0.5 + (sin(_cloudController.value * pi * 4) * 0.2);
            final denseOpacity2 = 0.4 + (cos(_cloudController.value * pi * 3) * 0.2);

            return Stack(
              children: [
                // Background slow clouds
                Positioned(
                  top: 50,
                  left: -200 + (400 * _cloudController.value),
                  child: _buildCloudCluster(const Color(0xFF334155).withValues(alpha: denseOpacity1)),
                ),
                Positioned(
                  top: 250,
                  right: -300 + (350 * _cloudController.value),
                  child: _buildCloudCluster(const Color(0xFF475569).withValues(alpha: denseOpacity2)),
                ),
                Positioned(
                  bottom: 100,
                  left: -150 - (200 * _cloudController.value),
                  child: _buildCloudCluster(const Color(0xFF1E293B).withValues(alpha: denseOpacity1)),
                ),
                
                // Occasional Dense Foreground Clouds
                Positioned(
                  top: -50,
                  right: -100 - (300 * _cloudController.value),
                  child: _buildCloudCluster(const Color(0xFF0F172A).withValues(alpha: 0.6 * denseOpacity2)),
                ),
                Positioned(
                  bottom: -100,
                  left: -200 + (500 * _cloudController.value),
                  child: _buildCloudCluster(const Color(0xFF0F172A).withValues(alpha: 0.7 * denseOpacity1)),
                ),
              ],
            );
          },
        ),

        // Rain layer
        AnimatedBuilder(
          animation: _rainController,
          builder: (context, child) {
            _rainPainter.animationValue = _rainController.value;
            return CustomPaint(
              painter: _rainPainter,
              size: Size.infinite,
            );
          },
        ),

        // Thunder Flash Overlay
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          color: widget.isFlashing ? Colors.white.withValues(alpha: 0.85) : Colors.transparent,
        ),
      ],
    );
  }

  // Builds a fluffy cloud shape by combining several blurred circles
  Widget _buildCloudCluster(Color color) {
    return SizedBox(
      width: 500,
      height: 300,
      child: Stack(
        children: [
          Positioned(
            left: 50,
            bottom: 20,
            child: _buildCloudPuff(200, 150, color),
          ),
          Positioned(
            left: 150,
            bottom: 60,
            child: _buildCloudPuff(250, 180, color),
          ),
          Positioned(
            left: 280,
            bottom: 40,
            child: _buildCloudPuff(180, 120, color),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudPuff(double width, double height, Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(width / 2),
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 60,
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }
}

class RainDrop {
  final double xFactor;
  final double startYFactor;
  final double speedMultiplier;
  final double dropLength;

  RainDrop(this.xFactor, this.startYFactor, this.speedMultiplier, this.dropLength);
}

class RainPainter extends CustomPainter {
  double animationValue = 0.0;
  final List<RainDrop> _drops = [];
  bool _initialized = false;

  RainPainter();

  void _initDrops() {
    if (_initialized) return;
    final random = Random(42);
    for (int i = 0; i < 200; i++) {
      _drops.add(RainDrop(
        random.nextDouble(),
        random.nextDouble(),
        0.8 + random.nextDouble() * 1.5,
        20.0 + random.nextDouble() * 30.0,
      ));
    }
    _initialized = true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _initDrops();
    for (final drop in _drops) {
      double x = drop.xFactor * size.width;
      double startYOffset = drop.startYFactor * size.height;
      double y = ((animationValue * size.height * 2 * drop.speedMultiplier) + startYOffset) % size.height;
      double xOffset = drop.dropLength * 0.15; 

      Offset startPoint = Offset(x, y);
      Offset endPoint = Offset(x - xOffset, y + drop.dropLength);

      final paint = Paint()
        ..shader = ui.Gradient.linear(
          startPoint,
          endPoint,
          [
            Colors.white.withValues(alpha: 0.0), // Tail fades out
            Colors.white.withValues(alpha: 0.4), // Head is bright
          ],
        )
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RainPainter oldDelegate) {
    return true; // We use a single instance and mutate animationValue, so always repaint when requested
  }
}
