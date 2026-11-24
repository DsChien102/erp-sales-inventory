import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

/// Loads the bundled TTFs under the same family names the tokens use, so the
/// measurements below run on real Inter / JetBrains Mono outlines.
Future<void> _loadFamily(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    final bytes = File('assets/fonts/$file').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Paints [text] and returns how many pixels of ink fall above / below the
/// line box. Positive means the glyphs leave the box (clipped by any clipping
/// parent, or colliding with the previous line).
Future<({double top, double bottom})> _inkOverflow(
  String text,
  TextStyle style,
) async {
  const pad = 40.0;
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: style.copyWith(color: const Color(0xFF000000)),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), const Offset(0, pad));
  final width = painter.width.ceil() + 2;
  final height = (painter.height + pad * 2).ceil();
  final image = await recorder.endRecording().toImage(width, height);
  final pixels = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;

  int? inkTop;
  int? inkBottom;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (pixels.getUint8((y * width + x) * 4 + 3) > 24) {
        inkTop ??= y;
        inkBottom = y;
        break;
      }
    }
  }
  return (
    top: pad - inkTop!,
    bottom: inkBottom! + 1 - pad - painter.height,
  );
}

double _width(String text, TextStyle style) => (TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout())
        .width;

void main() {
  const textRoles = <String, TextStyle>{
    'headingH1': VTypography.headingH1,
    'headingH2': VTypography.headingH2,
    'headingH3': VTypography.headingH3,
    'headingH4': VTypography.headingH4,
    'bodyDefault': VTypography.bodyDefault,
    'bodySmall': VTypography.bodySmall,
    'labelDefault': VTypography.labelDefault,
    'actionDefault': VTypography.actionDefault,
    'caption': VTypography.caption,
    'labelSmall': VTypography.labelSmall,
    'headingH1Mono': VTypography.headingH1Mono,
    'headingH2Mono': VTypography.headingH2Mono,
    'headingH3Mono': VTypography.headingH3Mono,
    'headingH4Mono': VTypography.headingH4Mono,
    'bodyDefaultMono': VTypography.bodyDefaultMono,
    'bodySmallMono': VTypography.bodySmallMono,
    'labelDefaultMono': VTypography.labelDefaultMono,
    'monoNumeric': VTypography.monoNumeric,
  };
  const numeralRoles = <String, TextStyle>{
    'displayD1': VTypography.displayD1,
    'displayD1Mono': VTypography.displayD1Mono,
  };

  setUpAll(() async {
    await _loadFamily(VTypography.fontFamily, const [
      'ttf_Inter/Inter-Medium.ttf',
      'ttf_Inter/Inter-SemiBold.ttf',
      'ttf_Inter/Inter-Bold.ttf',
      'ttf_Inter/Inter-ExtraBold.ttf',
    ]);
    await _loadFamily(VTypography.monoFontFamily, const [
      'ttf_JetBrainsMono/JetBrainsMono-Medium.ttf',
      'ttf_JetBrainsMono/JetBrainsMono-SemiBold.ttf',
      'ttf_JetBrainsMono/JetBrainsMono-Bold.ttf',
      'ttf_JetBrainsMono/JetBrainsMono-ExtraBold.ttf',
    ]);
  });

  group('VTypography Vietnamese marks', () {
    for (final role in textRoles.entries) {
      testWidgets('${role.key} keeps stacked marks inside the line box',
          (tester) async {
        final overflow = await tester.runAsync(
          () => _inkOverflow('ẪỖẶỮỸ Ống ỵặg', role.value),
        );
        expect(overflow!.top, lessThanOrEqualTo(0), reason: 'mark above');
        expect(overflow.bottom, lessThanOrEqualTo(0), reason: 'dot below');
      });
    }

    for (final role in numeralRoles.entries) {
      testWidgets('${role.key} fits amounts inside the line box',
          (tester) async {
        final overflow = await tester.runAsync(
          () => _inkOverflow('1.234.567.890 ₫', role.value),
        );
        expect(overflow!.top, lessThanOrEqualTo(0));
        expect(overflow.bottom, lessThanOrEqualTo(0));
      });
    }
  });

  group('VTypography numerals', () {
    for (final role in {...textRoles, ...numeralRoles}.entries) {
      test('${role.key} uses tabular digits', () {
        expect(
          _width('111', role.value),
          moreOrLessEquals(_width('888', role.value), epsilon: 0.01),
        );
      });
    }
  });
}
