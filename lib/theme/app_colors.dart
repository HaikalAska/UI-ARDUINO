import 'package:flutter/material.dart';

/// Palet warna resmi T.H.A.L.I.A berdasarkan UI/UX Design Blueprint (Nordic Clean Minimalist)
class AppColors {
  AppColors._();

  // Canvas & Surfaces
  static const Color canvas = Color(0xFFF8FAFC);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Shadows
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x0A000000), // rgba(0,0,0,0.04)
    blurRadius: 20,
    offset: Offset(0, 4),
  );

  static const BoxShadow softGlow = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 12,
    offset: Offset(0, 2),
  );

  static const BoxShadow floatingShadow = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  // Typography
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Habitat Accents
  static const Color atmosferSky = Color(0xFF38BDF8);
  static const Color atmosferWarm = Color(0xFFFBBF24);
  static const Color hidrosferAqua = Color(0xFF06B6D4);
  static const Color hidrosferBlue = Color(0xFF0284C7);
  static const Color litosferEmerald = Color(0xFF10B981);
  static const Color litosferDarkEmerald = Color(0xFF059669);

  // Blockchain / Web3 Sepolia
  static const Color blockchainIndigo = Color(0xFF6366F1);
  static const Color blockchainIndigoBg = Color(0xFFEEF2FF);
  static const Color blockchainIndigoBorder = Color(0xFFC7D2FE);

  // Status Badges
  static const Color statusSafeText = Color(0xFF10B981);
  static const Color statusSafeBg = Color(0xFFECFDF5);

  static const Color statusWarningText = Color(0xFFF59E0B);
  static const Color statusWarningBg = Color(0xFFFFFBEB);

  static const Color statusDangerText = Color(0xFFEF4444);
  static const Color statusDangerBg = Color(0xFFFEF2F2);
}
