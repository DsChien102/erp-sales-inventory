import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  final colors = VColorScheme.light;
  const text = 4.5; // WCAG 1.4.3
  const nonText = 3.0; // WCAG 1.4.11

  group('VColorScheme.light contrast', () {
    for (final tone in [
      VComponentTone.success,
      VComponentTone.warning,
      VComponentTone.danger,
      VComponentTone.info,
    ]) {
      test('${tone.name}: foreground on surface ≥ 4.5', () {
        expect(
          contrast(colors.foregroundForTone(tone)!, colors.surface),
          greaterThanOrEqualTo(text),
        );
      });

      test('${tone.name}: foreground on its tinted background ≥ 4.5', () {
        expect(
          contrast(colors.foregroundForTone(tone)!, colors.backgroundForTone(tone)!),
          greaterThanOrEqualTo(text),
        );
      });
    }

    test('textInverse on filled primary / warning / danger ≥ 4.5', () {
      for (final fill in [colors.primary, colors.warning, colors.danger]) {
        expect(contrast(colors.textInverse, fill), greaterThanOrEqualTo(text));
      }
    });

    test('textInverse on hover / pressed fills ≥ 4.5', () {
      for (final fill in [
        colors.primaryHover,
        colors.primaryPressed,
        colors.warningHover,
        colors.warningPressed,
        colors.dangerHover,
        colors.dangerPressed,
        colors.infoHover,
        colors.infoPressed,
      ]) {
        expect(contrast(colors.textInverse, fill), greaterThanOrEqualTo(text));
      }
    });

    test('text tokens on surface ≥ 4.5', () {
      for (final fg in [colors.textPrimary, colors.textSecondary, colors.textMuted]) {
        expect(contrast(fg, colors.surface), greaterThanOrEqualTo(text));
      }
    });

    test('textSecondary on page background ≥ 4.5', () {
      expect(
        contrast(colors.textSecondary, colors.background),
        greaterThanOrEqualTo(text),
      );
    });

    test('borderInput on surface ≥ 3.0', () {
      expect(contrast(colors.borderInput, colors.surface), greaterThanOrEqualTo(nonText));
    });

    test('borderInput stays distinct from the divider token', () {
      expect(colors.borderInput, isNot(colors.borderDefault));
      expect(colors.borderInput, isNot(colors.borderStrong));
    });
  });

  group('VColorScheme.dark status tones', () {
    final dark = VColorScheme.dark;
    for (final tone in [
      VComponentTone.success,
      VComponentTone.warning,
      VComponentTone.danger,
      VComponentTone.info,
    ]) {
      test('${tone.name}: foreground on surface and tint ≥ 4.5', () {
        final fg = dark.foregroundForTone(tone)!;
        expect(contrast(fg, dark.surface), greaterThanOrEqualTo(text));
        expect(contrast(fg, dark.backgroundForTone(tone)!), greaterThanOrEqualTo(text));
      });

      test('${tone.name}: tint differs from the neutral surface', () {
        expect(dark.backgroundForTone(tone), isNot(dark.surface));
      });
    }

    test('textInverse on filled primary / warning / danger / info ≥ 4.5', () {
      for (final fill in [dark.primary, dark.warning, dark.danger, dark.info]) {
        expect(contrast(dark.textInverse, fill), greaterThanOrEqualTo(text));
      }
    });

    test('textInverse on hover / pressed fills ≥ 4.5', () {
      for (final fill in [
        dark.primaryHover,
        dark.primaryPressed,
        dark.warningHover,
        dark.warningPressed,
        dark.dangerHover,
        dark.dangerPressed,
        dark.infoHover,
        dark.infoPressed,
      ]) {
        expect(contrast(dark.textInverse, fill), greaterThanOrEqualTo(text));
      }
    });
  });

  group('VColorScheme.dark borderInput', () {
    test('≥ 3.0 on surface', () {
      expect(
        contrast(VColorScheme.dark.borderInput, VColorScheme.dark.surface),
        greaterThanOrEqualTo(nonText),
      );
    });
  });

  test('copyWith / lerp carry borderInput', () {
    const probe = Color(0xFF123456);
    expect(colors.copyWith(borderInput: probe).borderInput, probe);
    expect(colors.lerp(VColorScheme.dark, 0).borderInput, colors.borderInput);
    expect(colors.lerp(VColorScheme.dark, 1).borderInput, VColorScheme.dark.borderInput);
  });
}
