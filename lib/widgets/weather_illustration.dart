import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Ilustrasi vektor garis minimalis cuaca dengan bulatan aksen warna pastel
/// Sesuai Pilar 1 Blueprint (Clean White Minimalist Nordic Aesthetic)
class WeatherIllustration extends StatefulWidget {
  final double size;

  const WeatherIllustration({
    super.key,
    this.size = 110.0,
  });

  @override
  State<WeatherIllustration> createState() => _WeatherIllustrationState();
}

class _WeatherIllustrationState extends State<WeatherIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _NordicWeatherPainter(animationValue: _controller.value),
        );
      },
    );
  }
}

class _NordicWeatherPainter extends CustomPainter {
  final double animationValue;

  _NordicWeatherPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Bulatan Aksen Warna Pastel Matahari (Warm Sun Glow)
    final sunCenter = Offset(w * 0.68, h * 0.38 + (animationValue * 3.0));
    final sunRadius = w * 0.22;

    final sunFillPaint = Paint()
      ..color = AppColors.atmosferWarm.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(sunCenter, sunRadius, sunFillPaint);

    final sunCorePaint = Paint()
      ..color = const Color(0xFFFDE68A).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(sunCenter, sunRadius * 0.65, sunCorePaint);

    // Garis lingkar luar matahari halus
    final sunOutlinePaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(sunCenter, sunRadius, sunOutlinePaint);

    // Sinar halus tipis minimalis
    final rayPaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) + (animationValue * 0.05);
      final rayStart = Offset(
        sunCenter.dx + math.cos(angle) * (sunRadius + 3),
        sunCenter.dy + math.sin(angle) * (sunRadius + 3),
      );
      final rayEnd = Offset(
        sunCenter.dx + math.cos(angle) * (sunRadius + 7),
        sunCenter.dy + math.sin(angle) * (sunRadius + 7),
      );
      canvas.drawLine(rayStart, rayEnd, rayPaint);
    }

    // 2. Bulatan aksen warna pastel langit (Cyan Sky Accent)
    final cyanAccentPaint = Paint()
      ..color = AppColors.atmosferSky.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.28, h * 0.58), w * 0.18, cyanAccentPaint);

    // 3. Ilustrasi Garis Vektor Bersih Awan (Clean Outlined Cloud)
    final cloudStrokePaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cloudFillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final cloudPath = Path();
    final baseY = h * 0.72 - (animationValue * 2.0);
    final leftX = w * 0.18;
    final rightX = w * 0.82;

    cloudPath.moveTo(leftX + 16, baseY);
    cloudPath.lineTo(rightX - 16, baseY);
    cloudPath.arcToPoint(
      Offset(rightX, baseY - 16),
      radius: const Radius.circular(16),
      clockwise: false,
    );
    cloudPath.arcToPoint(
      Offset(w * 0.65, h * 0.46),
      radius: Radius.circular(w * 0.18),
      clockwise: false,
    );
    cloudPath.arcToPoint(
      Offset(w * 0.36, h * 0.52),
      radius: Radius.circular(w * 0.17),
      clockwise: false,
    );
    cloudPath.arcToPoint(
      Offset(leftX, baseY - 14),
      radius: Radius.circular(w * 0.12),
      clockwise: false,
    );
    cloudPath.arcToPoint(
      Offset(leftX + 16, baseY),
      radius: const Radius.circular(16),
      clockwise: false,
    );
    cloudPath.close();

    canvas.drawPath(cloudPath, cloudFillPaint);
    canvas.drawPath(cloudPath, cloudStrokePaint);

    // 4. Titik Aksen Pastel Bergaris Halus (Nordic Floating Dots)
    final dot1 = Paint()
      ..color = AppColors.hidrosferAqua.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.88, h * 0.30), 3.0, dot1);

    final dot2 = Paint()
      ..color = AppColors.litosferEmerald.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.14, h * 0.40), 2.5, dot2);
  }

  @override
  bool shouldRepaint(covariant _NordicWeatherPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
