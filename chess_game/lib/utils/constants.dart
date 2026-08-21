import 'package:flutter/material.dart';

class AppColors {
  static const Color darkBackground = Color(0xFF1a1a2e);
  static const Color darkerBackground = Color(0xFF16213e);
  static const Color accent = Color(0xFFe94560);
  static const Color accentLight = Color(0xFFff6b6b);
  static const Color gold = Color(0xFFf4d03f);
  static const Color lightSquare = Color(0xFFf0d9b5);
  static const Color darkSquare = Color(0xFFb58863);
  static const Color highlight = Color(0xFF7b61ff);
  static const Color checkHighlight = Color(0xFFff4444);
  static const Color lastMove = Color(0xFFaaffaa);
  static const Color possibleMove = Color(0xFF4444ff);
}

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 6,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    color: Colors.white70,
  );

  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
}
