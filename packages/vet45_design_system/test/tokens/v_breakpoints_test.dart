import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VBreakpoints', () {
    test('ofWidth thresholds', () {
      expect(VBreakpoints.ofWidth(599), VBreakpoint.mobile);
      expect(VBreakpoints.ofWidth(600), VBreakpoint.tablet);
      expect(VBreakpoints.ofWidth(1023), VBreakpoint.tablet);
      expect(VBreakpoints.ofWidth(1024), VBreakpoint.desktop);
    });

    test('isAtLeast / isAtMost', () {
      expect(VBreakpoint.desktop.isAtLeast(VBreakpoint.tablet), isTrue);
      expect(VBreakpoint.mobile.isAtLeast(VBreakpoint.tablet), isFalse);
      expect(VBreakpoint.mobile.isAtMost(VBreakpoint.tablet), isTrue);
      expect(VBreakpoint.desktop.isAtMost(VBreakpoint.tablet), isFalse);
    });
  });

  group('VPagePadding', () {
    test('horizontalForWidth matches spacing tokens', () {
      expect(VPagePadding.horizontalForWidth(400), VSpacing.screenMobile);
      expect(VPagePadding.horizontalForWidth(800), VSpacing.screenTablet);
      expect(VPagePadding.horizontalForWidth(1200), VSpacing.screenDesktop);
    });
  });
}
