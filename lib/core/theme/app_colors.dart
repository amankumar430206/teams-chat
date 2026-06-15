import 'package:flutter/material.dart';

/// Central color palette. Use these tokens everywhere instead of raw hex codes.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9C95FF);
  static const Color primaryDark = Color(0xFF3D35CC);

  static const Color secondary = Color(0xFFFF6584);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF6F7FB);
  static const Color backgroundDark = Color(0xFF121212);

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E2D);

  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF252535);

  // Text
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textPrimaryDark = Color(0xFFF0F0F0);

  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Message bubbles
  static const Color myBubble = primary;
  static const Color myBubbleText = Colors.white;
  static const Color theirBubbleLight = Color(0xFFEEEEF5);
  static const Color theirBubbleDark = Color(0xFF2E2E45);
  static const Color theirBubbleText = textPrimaryLight;

  // Status indicators
  static const Color online = Color(0xFF22C55E);
  static const Color offline = Color(0xFF9CA3AF);
  static const Color sending = Color(0xFFD1D5DB);
  static const Color delivered = primary;
  static const Color error = Color(0xFFEF4444);

  // Misc
  static const Color divider = Color(0xFFE5E7EB);
  static const Color dividerDark = Color(0xFF374151);
  static const Color unreadBadge = secondary;
  static const Color inputBackground = Color(0xFFF3F4F6);
  static const Color inputBackgroundDark = Color(0xFF2A2A3E);
}
