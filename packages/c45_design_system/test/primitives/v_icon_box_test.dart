import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('VIconBox', () {
    Widget wrap(Widget child) => MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Align(alignment: Alignment.topLeft, child: child),
          ),
        );

    testWidgets('without onTap keeps its drawn size', (tester) async {
      await tester.pumpWidget(
        wrap(const VIconBox(icon: VIcons.camera, size: 24, iconSize: 16)),
      );
      expect(tester.getSize(find.byType(VIconBox)), const Size(24, 24));
    });

    testWidgets('with onTap the layout box is at least 44×44', (tester) async {
      await tester.pumpWidget(
        wrap(
          VIconBox(
            icon: VIcons.camera,
            size: 24,
            iconSize: 16,
            semanticLabel: 'Chụp ảnh',
            onTap: () {},
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(VIconBox)),
        const Size(VSpacing.minTouchTarget, VSpacing.minTouchTarget),
      );
    });

    testWidgets('already large box is not changed', (tester) async {
      await tester.pumpWidget(
        wrap(
          VIconBox(
            icon: VIcons.camera,
            size: 56,
            semanticLabel: 'Chụp ảnh',
            onTap: () {},
          ),
        ),
      );
      expect(tester.getSize(find.byType(VIconBox)), const Size(56, 56));
    });

    testWidgets('taps outside the drawn box but inside 44×44 hit', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          VIconBox(
            icon: VIcons.camera,
            size: 24,
            iconSize: 16,
            semanticLabel: 'Chụp ảnh',
            onTap: () => taps++,
          ),
        ),
      );
      final rect = tester.getRect(find.byType(VIconBox));
      await tester.tapAt(rect.topLeft + const Offset(2, 2));
      expect(taps, 1);
    });

    testWidgets('exposes semanticLabel as a button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          VIconBox(
            icon: VIcons.camera,
            semanticLabel: 'Chụp ảnh',
            onTap: () {},
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(VIconBox));
      expect(node.label, 'Chụp ảnh');
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('visible label doubles as the name when no semanticLabel',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(VIconBox(label: 'AB', onTap: () {})),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSemantics(find.byType(VIconBox)).label, 'AB');
      handle.dispose();
    });

    testWidgets('onTap without any name asserts in debug', (tester) async {
      await tester.pumpWidget(
        wrap(VIconBox(icon: VIcons.camera, onTap: () {})),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('meets iOS tap target and labelled guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          VIconBox(
            icon: VIcons.camera,
            size: 24,
            semanticLabel: 'Chụp ảnh',
            onTap: () {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
