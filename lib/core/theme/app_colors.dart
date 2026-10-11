// Copyright-free. Core palette for Bolt QR Scan and Generator.
// Workers: import this file for every color. Do not hard-code hex elsewhere.
import 'package:flutter/material.dart';

/// Brand + semantic colors (light scheme baseline).
class AppColors {
  const AppColors._();

  /// Volt yellow #FFD60A — main accent.
  static const Color voltYellow = Color(0xFFFFD60A);

  /// Ink #14121F — primary text / dark surfaces.
  static const Color ink = Color(0xFF14121F);

  /// Electric blue #3D4DFF — links, focus, selected input.
  static const Color electricBlue = Color(0xFF3D4DFF);

  /// Paper #F6F5FA — light background.
  static const Color paper = Color(0xFFF6F5FA);

  /// Card white #FFFFFF.
  static const Color cardWhite = Color(0xFFFFFFFF);

  /// Line #E4E2EE — light dividers/borders.
  static const Color line = Color(0xFFE4E2EE);

  /// Muted text #6B6880.
  static const Color muted = Color(0xFF6B6880);

  /// Success #0E8A55.
  static const Color success = Color(0xFF0E8A55);

  /// Camera-screen black #0B0A12 — scan screen is always dark.
  static const Color cameraBlack = Color(0xFF0B0A12);

  /// Dark theme card #15141F.
  static const Color darkCard = Color(0xFF15141F);

  /// Dark theme line #26243A.
  static const Color darkLine = Color(0xFF26243A);

  /// Danger red.
  static const Color danger = Color(0xFFD92D20);

  /// Muted text on dark backgrounds.
  static const Color darkMuted = Color(0xFF9C99B5);
}
