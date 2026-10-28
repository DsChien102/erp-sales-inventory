import 'package:erp/core/config/density.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('erpDensityMode', () {
    test('web with mouse/keyboard platforms resolves to compact', () {
      expect(
        erpDensityMode(isWeb: true, platform: TargetPlatform.macOS),
        equals(VDensityMode.compact),
      );
      expect(
        erpDensityMode(isWeb: true, platform: TargetPlatform.windows),
        equals(VDensityMode.compact),
      );
      expect(
        erpDensityMode(isWeb: true, platform: TargetPlatform.linux),
        equals(VDensityMode.compact),
      );
    });

    test('web with touch platforms resolves to comfortable', () {
      expect(
        erpDensityMode(isWeb: true, platform: TargetPlatform.iOS),
        equals(VDensityMode.comfortable),
      );
      expect(
        erpDensityMode(isWeb: true, platform: TargetPlatform.android),
        equals(VDensityMode.comfortable),
      );
    });

    test('non-web (mobile app) resolves to comfortable', () {
      expect(
        erpDensityMode(isWeb: false, platform: TargetPlatform.iOS),
        equals(VDensityMode.comfortable),
      );
      expect(
        erpDensityMode(isWeb: false, platform: TargetPlatform.android),
        equals(VDensityMode.comfortable),
      );
      expect(
        erpDensityMode(isWeb: false, platform: TargetPlatform.macOS),
        equals(VDensityMode.comfortable),
      );
    });
  });
}
