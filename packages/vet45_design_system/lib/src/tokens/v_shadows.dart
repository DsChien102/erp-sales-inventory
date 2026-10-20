import 'package:flutter/material.dart';

class VShadows {
  VShadows._();

  static const List<BoxShadow> e1 = [
    BoxShadow(
      color: Color(0x080E1116),
      blurRadius: 6,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> e2 = [
    BoxShadow(
      color: Color(0x0F0E1116),
      blurRadius: 12,
      offset: Offset(0, 3),
    ),
  ];

  static const List<BoxShadow> e3 = [
    BoxShadow(
      color: Color(0x170E1116),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> e4 = [
    BoxShadow(
      color: Color(0x1F0E1116),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];
}
