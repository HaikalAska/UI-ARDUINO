import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// Kartu modular tactile dengan efek spring scale (0.97x) dan haptic feedback
/// sesuai spesifikasi Motion Design Blueprint T.H.A.L.I.A (spring tension: 300, friction: 20)
class TactileCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color backgroundColor;
  final Border? border;
  final double borderRadius;
  final List<BoxShadow>? shadows;

  const TactileCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.only(bottom: 16),
    this.backgroundColor = AppColors.cardSurface,
    this.border,
    this.borderRadius = 24.0,
    this.shadows,
  });

  @override
  State<TactileCard> createState() => _TactileCardState();
}

class _TactileCardState extends State<TactileCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  // Sesuai spesifikasi Blueprint: spring tension: 300, friction: 20
  static const _springDescription = SpringDescription(
    mass: 1.0,
    stiffness: 300.0, // Tension: 300
    damping: 20.0,    // Friction: 20
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: -0.1,
      upperBound: 1.1,
      value: 0.0,
    );

    // Pantulan elastis (1.0 -> 0.97x saat ditekan)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.animateTo(1.0, duration: const Duration(milliseconds: 90));
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      final simulation = SpringSimulation(
        _springDescription,
        _controller.value,
        0.0,
        -1.0,
      );
      _controller.animateWith(simulation);
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      final simulation = SpringSimulation(
        _springDescription,
        _controller.value,
        0.0,
        0.0,
      );
      _controller.animateWith(simulation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveShadows = widget.shadows ?? const [AppColors.cardShadow];
    final effectiveBorder = widget.border ??
        Border.all(color: const Color(0x0F000000), width: 1);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        margin: widget.margin,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: effectiveBorder,
                boxShadow: effectiveShadows,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
