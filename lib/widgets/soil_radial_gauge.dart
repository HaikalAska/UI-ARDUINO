import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Kurva progres setengah lingkaran (half radial gauge) untuk Kelembapan Tanah
/// Sesuai Pilar 2 & Motion Design Blueprint T.H.A.L.I.A
class SoilRadialGauge extends StatefulWidget {
  final int soilPercent;
  final double size;

  const SoilRadialGauge({
    super.key,
    this.soilPercent = 38,
    this.size = 140.0,
  });

  @override
  State<SoilRadialGauge> createState() => _SoilRadialGaugeState();
}

class _SoilRadialGaugeState extends State<SoilRadialGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Gerakan pegas fluida (overshoot ease)
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.soilPercent.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant SoilRadialGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.soilPercent != widget.soilPercent) {
      final beginValue = _animation.value.clamp(0.0, 100.0);
      _controller.duration = const Duration(milliseconds: 300);
      _controller.reset();
      _animation = Tween<double>(
        begin: beginValue,
        end: widget.soilPercent.toDouble(),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ),
      );
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size * 0.65),
          painter: _SoilRadialPainter(
            currentValue: _animation.value,
            targetValue: widget.soilPercent.toDouble(),
          ),
        );
      },
    );
  }
}

class _SoilRadialPainter extends CustomPainter {
  final double currentValue;
  final double targetValue;

  _SoilRadialPainter({
    required this.currentValue,
    required this.targetValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.95);
    final radius = w * 0.42;

    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // 1. Lintasan Rel (Track)
    final trackPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11.0
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(arcRect, startAngle, sweepAngle, false, trackPaint);

    // 2. Progres Setengah Lingkaran (Emerald Green)
    final ratio = (currentValue / 100.0).clamp(0.0, 1.0);
    final activeSweep = sweepAngle * ratio;

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF34D399),
          AppColors.litosferEmerald,
          AppColors.litosferDarkEmerald,
        ],
      ).createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11.0
      ..strokeCap = StrokeCap.round;

    if (activeSweep > 0) {
      canvas.drawArc(arcRect, startAngle, activeSweep, false, progressPaint);
    }

    // 3. Teks Nilai di Tengah Busur
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final displayPercent = currentValue.round().clamp(0, 100);
    textPainter.text = TextSpan(
      children: [
        TextSpan(
          text: '$displayPercent%',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height - 4),
    );
  }

  @override
  bool shouldRepaint(covariant _SoilRadialPainter oldDelegate) =>
      oldDelegate.currentValue != currentValue;
}
