import 'package:flutter/material.dart';

class VShadows {
  VShadows._();

  static const List<BoxShadow> e1 = [
    BoxShadow(
      color: Color(0x0A0E1116),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> e2 = [
    BoxShadow(
      color: Color(0x140E1116),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> e3 = [
    BoxShadow(
      color: Color(0x1F0E1116),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> e4 = [
    BoxShadow(
      color: Color(0x290E1116),
      blurRadius: 32,
      offset: Offset(0, 16),
    ),
  ];
}
