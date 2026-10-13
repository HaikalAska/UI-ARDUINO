import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Slider busur skala warna pH (0 s/d 14) dengan pin jarum spring animation
/// Sesuai Pilar 2 & Motion Design Blueprint T.H.A.L.I.A
class PhArcGauge extends StatefulWidget {
  final double phValue;
  final double size;

  const PhArcGauge({
    super.key,
    this.phValue = 7.2,
    this.size = 180.0,
  });

  @override
  State<PhArcGauge> createState() => _PhArcGaugeState();
}

class _PhArcGaugeState extends State<PhArcGauge>
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
    _animation = Tween<double>(begin: 0.0, end: widget.phValue).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant PhArcGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phValue != widget.phValue) {
      final beginValue = _animation.value.clamp(0.0, 14.0);
      _controller.duration = const Duration(milliseconds: 300);
      _controller.reset();
      _animation = Tween<double>(begin: beginValue, end: widget.phValue).animate(
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
          size: Size(widget.size, widget.size * 0.62),
          painter: _PhArcPainter(
            currentValue: _animation.value,
            targetValue: widget.phValue,
          ),
        );
      },
    );
  }
}

class _PhArcPainter extends CustomPainter {
  final double currentValue;
  final double targetValue;

  _PhArcPainter({
    required this.currentValue,
    required this.targetValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.95);
    final radius = w * 0.38;

    const startAngle = math.pi; // 180 deg (kiri)
    const sweepAngle = math.pi; // 180 deg sweep (ke kanan)

    // 1. Lintasan Rel Latar Belakang (Track)
    final trackPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(arcRect, startAngle, sweepAngle, false, trackPaint);

    // 2. Busur Spektrum Warna pH (0-14)
    // Red (0) -> Amber (5) -> Emerald Green (7) -> Cyan (8) -> Blue (10) -> Violet (14)
    final gradient = const SweepGradient(
      startAngle: math.pi,
      endAngle: 2 * math.pi,
      colors: [
        Color(0xFFEF4444), // Asam pekat (0)
        Color(0xFFF59E0B), // Asam ringan (4)
        Color(0xFF10B981), // Netral Bersih (7)
        Color(0xFF06B6D4), // Basa ringan (8)
        Color(0xFF3B82F6), // Basa sedang (11)
        Color(0xFF8B5CF6), // Basa pekat (14)
      ],
      stops: [0.0, 0.28, 0.50, 0.60, 0.80, 1.0],
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, arcPaint);

    // 3. Ticks Penanda (0, 7, 14)
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const labels = [
      (0.0, '0'),
      (7.0, '7'),
      (14.0, '14'),
    ];

    for (final item in labels) {
      final ratio = item.$1 / 14.0;
      final angle = startAngle + (sweepAngle * ratio);
      final tickRadius = radius + 12;
      final tx = center.dx + math.cos(angle) * tickRadius;
      final ty = center.dy + math.sin(angle) * tickRadius;

      textPainter.text = TextSpan(
        text: item.$2,
        style: TextStyle(
          color: item.$1 == 7.0 ? AppColors.litosferEmerald : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: item.$1 == 7.0 ? FontWeight.w700 : FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(tx - textPainter.width / 2, ty - textPainter.height / 2),
      );
    }

    // 4. Pin Jarum Penunjuk Berbasis Fisika (Needle Pointer)
    final clampedValue = currentValue.clamp(0.0, 14.0);
    final needleRatio = clampedValue / 14.0;
    final needleAngle = startAngle + (sweepAngle * needleRatio);

    final needleLength = radius - 2;
    final needleTip = Offset(
      center.dx + math.cos(needleAngle) * needleLength,
      center.dy + math.sin(needleAngle) * needleLength,
    );

    // Garis jarum tajam modern
    final needlePaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleTip, needlePaint);

    // Pin indicator head di ujung busur
    final pinHeadPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(needleTip, 4.0, pinHeadPaint);

    final pinGlowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(needleTip, 1.8, pinGlowPaint);

    // Poros jarum (center pivot)
    final pivotOuterPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6.0, pivotOuterPaint);

    final pivotInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, pivotInnerPaint);
  }

  @override
  bool shouldRepaint(covariant _PhArcPainter oldDelegate) =>
      oldDelegate.currentValue != currentValue;
}
