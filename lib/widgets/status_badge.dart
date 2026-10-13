import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BadgeType { safe, warning, danger, neutral, blockchain }

class StatusBadge extends StatelessWidget {
  final String label;
  final Widget? icon;
  final BadgeType type;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.type = BadgeType.safe,
    this.fontSize = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  factory StatusBadge.fromStatus(String status, {Widget? icon, double fontSize = 12.0}) {
    final lower = status.toLowerCase();
    BadgeType type = BadgeType.safe;
    if (lower.contains('waspada') || lower.contains('sedang')) {
      type = BadgeType.warning;
    } else if (lower.contains('bahaya') ||
        lower.contains('buruk') ||
        lower.contains('kritis') ||
        lower.contains('tinggi')) {
      type = BadgeType.danger;
    } else if (lower.contains('blockchain') || lower.contains('on-chain')) {
      type = BadgeType.blockchain;
    }
    return StatusBadge(
      label: status,
      icon: icon,
      type: type,
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    Color borderColor;

    switch (type) {
      case BadgeType.safe:
        textColor = AppColors.statusSafeText;
        bgColor = AppColors.statusSafeBg;
        borderColor = const Color(0xFFA7F3D0);
        break;
      case BadgeType.warning:
        textColor = AppColors.statusWarningText;
        bgColor = AppColors.statusWarningBg;
        borderColor = const Color(0xFFFDE68A);
        break;
      case BadgeType.danger:
        textColor = AppColors.statusDangerText;
        bgColor = AppColors.statusDangerBg;
        borderColor = const Color(0xFFFECACA);
        break;
      case BadgeType.blockchain:
        textColor = AppColors.blockchainIndigo;
        bgColor = AppColors.blockchainIndigoBg;
        borderColor = AppColors.blockchainIndigoBorder;
        break;
      case BadgeType.neutral:
        textColor = AppColors.textSecondary;
        bgColor = AppColors.surfaceMuted;
        borderColor = AppColors.borderLight;
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
