import 'package:flutter/foundation.dart';
import 'package:c45_design_system/design_system.dart';

/// Web trên máy tính (chuột / bàn phím) → compact; iPhone, Android, web trên điện thoại → comfortable.
VDensityMode erpDensityMode({
  bool isWeb = kIsWeb,
  TargetPlatform? platform,
}) {
  final p = platform ?? defaultTargetPlatform;
  final touch = p == TargetPlatform.iOS || p == TargetPlatform.android;
  return isWeb && !touch ? VDensityMode.compact : VDensityMode.comfortable;
}
