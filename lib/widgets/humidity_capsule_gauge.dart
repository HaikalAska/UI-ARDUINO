import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Kapsul pengukur vertikal (pill humidity gauge) warna kuning/biru
/// Sesuai Pilar 2 Blueprint T.H.A.L.I.A
class HumidityCapsuleGauge extends StatefulWidget {
  final int humidityPercent;
  final double width;
  final double height;

  const HumidityCapsuleGauge({
    super.key,
    this.humidityPercent = 72,
    this.width = 46.0,
    this.height = 110.0,
  });

  @override
  State<HumidityCapsuleGauge> createState() => _HumidityCapsuleGaugeState();
}

class _HumidityCapsuleGaugeState extends State<HumidityCapsuleGauge>
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
      end: widget.humidityPercent / 100.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant HumidityCapsuleGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.humidityPercent != widget.humidityPercent) {
      final beginRatio = _animation.value.clamp(0.0, 1.0);
      _controller.duration = const Duration(milliseconds: 300);
      _controller.reset();
      _animation = Tween<double>(
        begin: beginRatio,
        end: (widget.humidityPercent / 100.0).clamp(0.0, 1.0),
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
        final fillRatio = _animation.value.clamp(0.0, 1.0);
        final displayPercent = (fillRatio * 100).round().clamp(0, 100);
        return Container(
          width: widget.width,
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(widget.width / 2),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Liquid Fill
              FractionallySizedBox(
                heightFactor: fillRatio,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.width / 2),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.atmosferWarm, // Kuning hangat
                        AppColors.atmosferSky,  // Biru langit
                      ],
                    ),
                  ),
                ),
              ),

              // Level Indicator Ticks & Text
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Icon(
                        Icons.water_drop_outlined,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '$displayPercent%',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
