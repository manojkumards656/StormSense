import 'dart:collection';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SignalGraphsWidget extends StatefulWidget {
  final Stream<double> brightnessStream;
  final Stream<double> amplitudeStream;

  const SignalGraphsWidget({
    Key? key,
    required this.brightnessStream,
    required this.amplitudeStream,
  }) : super(key: key);

  @override
  _SignalGraphsWidgetState createState() => _SignalGraphsWidgetState();
}

class _SignalGraphsWidgetState extends State<SignalGraphsWidget> {
  final Queue<double> _brightnessData = Queue();
  final Queue<double> _amplitudeData = Queue();
  final int maxDataPoints = 100;

  @override
  void initState() {
    super.initState();
    widget.brightnessStream.listen((val) {
      if (!mounted) return;
      setState(() {
        _brightnessData.addLast(val);
        if (_brightnessData.length > maxDataPoints) _brightnessData.removeFirst();
      });
    });

    widget.amplitudeStream.listen((val) {
      if (!mounted) return;
      setState(() {
        _amplitudeData.addLast(val);
        if (_amplitudeData.length > maxDataPoints) _amplitudeData.removeFirst();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildGraph("Camera Brightness", _brightnessData.toList(), Colors.yellow, 255.0),
        const SizedBox(height: 16),
        _buildGraph("Mic Amplitude (RMS)", _amplitudeData.toList(), AppTheme.accentColor, 1.0),
      ],
    );
  }

  Widget _buildGraph(String title, List<double> data, Color color, double maxVal) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.secondaryDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            width: double.infinity,
            child: CustomPaint(
              painter: _LineGraphPainter(data, maxDataPoints, color, maxVal),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineGraphPainter extends CustomPainter {
  final List<double> data;
  final int maxPoints;
  final Color color;
  final double maxValue;

  _LineGraphPainter(this.data, this.maxPoints, this.color, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final double stepX = size.width / (maxPoints - 1);
    
    // Fill the beginning with zeros if not enough data
    final int padding = maxPoints - data.length;

    for (int i = 0; i < data.length; i++) {
      final double x = (i + padding) * stepX;
      // Normalize to view bounds
      double normalized = data[i] / maxValue;
      if (normalized > 1.0) normalized = 1.0;
      
      final double y = size.height - (normalized * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
