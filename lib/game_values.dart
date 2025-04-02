import 'package:flutter/material.dart';

class GameValues {
  static const double borderRadius = 10.0;
  // static const double borderWidth = 2.0;
  static const double gridPadding = 4.0;
  static const double tileRadius = 5.0;
  static const double moveInterval = .5;
  static const int millisecondsAnimation = 200;

  static const Map<int, Color> tileColors = {
    2: Color(0xFFEEE4DA),
    4: Color(0xFFEDE0C8),
    8: Color(0xFFF2B179),
    16: Color(0xFFF59563),
    32: Color(0xFFF67C5F),
    64: Color(0xFFF65E3B),
    128: Color(0xFFEDCF72),
    256: Color(0xFFEDCC61),
    512: Color(0xFFEDC850),
    1024: Color(0xFFEDC53F),
    2048: Color(0xFFEDC22E),
  };

  static const Map<int, Color> textColors = {
    2: Color(0xFF776E65),
    4: Color(0xFF776E65),
    8: Color(0xFFF9F6F2),
    16: Color(0xFFF9F6F2),
    32: Color(0xFFF9F6F2),
    64: Color(0xFFF9F6F2),
    128: Color(0xFFF9F6F2),
    256: Color(0xFFF9F6F2),
    512: Color(0xFFF9F6F2),
    1024: Color(0xFFF9F6F2),
    2048: Color(0xFFF9F6F2),
  };

  static const Map<int, double> fontSizes = {
    2: 36.0,
    4: 36.0,
    8: 32.0,
    16: 32.0,
    32: 28.0,
    64: 28.0,
    128: 24.0,
    256: 24.0,
    512: 24.0,
    1024: 20.0,
    2048: 20.0,
  };

  static const Map<int, FontWeight> fontWeights = {
    2: FontWeight.w700,
    4: FontWeight.w700,
    8: FontWeight.w700,
    16: FontWeight.w700,
    32: FontWeight.w700,
    64: FontWeight.w700,
    128: FontWeight.w800,
    256: FontWeight.w800,
    512: FontWeight.w800,
    1024: FontWeight.w900,
    2048: FontWeight.w900,
  };
  static const Map<int, Color> scoreTextColors = {
    100: Colors.white70,
    500: Colors.yellow,
    1000: Colors.orange,
    3000: Colors.red,
    5000: Colors.purple,
    10000: Colors.blue,
  };
  static Color getScoreTextColor(int score) {
    if (score >= 10000) return scoreTextColors[10000]!;
    if (score >= 5000) return scoreTextColors[5000]!;
    if (score >= 3000) return scoreTextColors[3000]!;
    if (score >= 1000) return scoreTextColors[1000]!;
    if (score >= 500) return scoreTextColors[500]!;
    if (score >= 100) return scoreTextColors[100]!;
    return Colors.white;
  }

  static TextStyle getScoreTextStyle(int score) {
    return TextStyle(
      color: getScoreTextColor(score),
      fontSize: 16.0,
      fontWeight: FontWeight.bold,
    );
  }

  static const Color tileBorderColor = Color(0xFF776E65);
  static const Color emptyTileColor = Color(0xFFCDC1B4);

  static const Color boardBackgroundColor = Color(0xFFBBADA0);

  static Color getTileColor(int value) {
    return tileColors[value] ?? emptyTileColor;
  }

  static TextStyle getTextStyle(int value) {
    return TextStyle(
      color: textColors[value] ?? Colors.black,
      fontSize: fontSizes[value] ?? 36.0,
      fontWeight: fontWeights[value] ?? FontWeight.w700,
    );
  }
}
