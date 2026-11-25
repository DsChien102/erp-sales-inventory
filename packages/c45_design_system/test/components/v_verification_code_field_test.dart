import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  group('VVerificationCodeField', () {
    testWidgets('numeric mode completes 6 digits', (tester) async {
      String? completed;
      await tester.pumpWidget(
        wrap(
          VVerificationCodeField(
            onCompleted: (code) => completed = code,
          ),
        ),
      );

      // Single hidden TextField drives all cells.
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();

      expect(completed, '123456');
    });

    testWidgets('alphanumeric mode uppercases and completes 8 chars', (
      tester,
    ) async {
      String? completed;
      String? latest;
      await tester.pumpWidget(
        wrap(
          VVerificationCodeField(
            length: 8,
            charset: VVerificationCodeCharset.alphanumeric,
            onChanged: (code) => latest = code,
            onCompleted: (code) => completed = code,
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'k7p29xqm');
      await tester.pump();

      expect(latest, 'K7P29XQM');
      expect(completed, 'K7P29XQM');
    });

    testWidgets('alphanumeric rejects symbols', (tester) async {
      var latest = 'unset';
      await tester.pumpWidget(
        wrap(
          VVerificationCodeField(
            length: 8,
            charset: VVerificationCodeCharset.alphanumeric,
            onChanged: (code) => latest = code,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '@');
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text ?? '', isEmpty);
      expect(latest == 'unset' || latest.isEmpty, isTrue);
    });

    testWidgets('legacy flat label and helper still render', (tester) async {
      await tester.pumpWidget(
        wrap(
          // ignore: deprecated_member_use
          const VVerificationCodeField(
            // ignore: deprecated_member_use
            label: 'OTP',
            // ignore: deprecated_member_use
            helperText: 'From SMS',
            // ignore: deprecated_member_use
            isRequired: true,
          ),
        ),
      );
      expect(find.text('OTP'), findsOneWidget);
      expect(find.text('From SMS'), findsOneWidget);
      expect(find.text(' *'), findsOneWidget);
    });

    group('layouts (10-8d)', () {
      Future<void> setView(WidgetTester tester, double w) async {
        tester.view.physicalSize = Size(w, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      }

      Finder cell(int i) => find.byKey(Key('v-code-cell-$i'));
      Color borderOf(WidgetTester tester, int i) {
        final box = tester.widget<DecoratedBox>(
          find.descendant(of: cell(i), matching: find.byType(DecoratedBox)).first,
        );
        return ((box.decoration as BoxDecoration).border! as Border).top.color;
      }

      double fontOf(WidgetTester tester, int i) => tester
          .widget<Text>(find.descendant(of: cell(i), matching: find.byType(Text)))
          .style!
          .fontSize!;

      testWidgets('compact keeps 48x56 cells', (tester) async {
        await setView(tester, 390);
        await tester.pumpWidget(wrap(const VVerificationCodeField()));
        expect(tester.getSize(cell(0)), const Size(48, 56));
      });

      testWidgets('fill spreads cells over the column', (tester) async {
        await setView(tester, 390);
        await tester.pumpWidget(wrap(const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 358,
            child: VVerificationCodeField(layout: VVerificationCodeLayout.fill),
          ),
        )));
        final size = tester.getSize(cell(0));
        expect(size.width, moreOrLessEquals(53, epsilon: .01));
        expect(size.height, 56);
      });

      testWidgets('fill inside the 326 card keeps 56 / 18', (tester) async {
        await setView(tester, 390);
        await tester.pumpWidget(wrap(const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 326,
            child: VVerificationCodeField(layout: VVerificationCodeLayout.fill),
          ),
        )));
        expect(tester.getSize(cell(0)).height, 56);
        expect(fontOf(tester, 0), 18);
      });

      testWidgets('fill below 40 wide drops to 48 / 14', (tester) async {
        await setView(tester, 390);
        await tester.pumpWidget(wrap(const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 256,
            child: VVerificationCodeField(layout: VVerificationCodeLayout.fill),
          ),
        )));
        expect(tester.getSize(cell(0)).height, 48);
        expect(fontOf(tester, 0), 14);
      });

      testWidgets('split4 groups 4 + 4', (tester) async {
        await setView(tester, 390);
        await tester.pumpWidget(wrap(const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 358,
            child: VVerificationCodeField(
              length: 8,
              charset: VVerificationCodeCharset.alphanumeric,
              layout: VVerificationCodeLayout.split4,
            ),
          ),
        )));
        expect(tester.getSize(cell(0)).height, 52);
        expect(tester.getTopLeft(cell(1)).dx - tester.getTopRight(cell(0)).dx, closeTo(5, .01));
        expect(tester.getTopLeft(cell(4)).dx - tester.getTopRight(cell(3)).dx, closeTo(18, .01));
        expect(tester.getTopRight(cell(7)).dx, closeTo(16 + 358, .01));
      });

      testWidgets('invalid turns every cell border danger', (tester) async {
        await setView(tester, 390);
        await tester.pumpWidget(wrap(const VField(
          invalid: true,
          child: VVerificationCodeField(autofocus: true),
        )));
        await tester.pump();
        await tester.pump();
        for (var i = 0; i < 6; i++) {
          expect(borderOf(tester, i), VColorScheme.light.danger, reason: 'cell $i');
        }
      });

      testWidgets('valid: only focused cell is primary', (tester) async {
        await setView(tester, 390);
        await tester.pumpWidget(wrap(const VVerificationCodeField(autofocus: true)));
        await tester.pump();
        await tester.pump();
        expect(borderOf(tester, 0), VColorScheme.light.primary);
        for (var i = 1; i < 6; i++) {
          expect(borderOf(tester, i), VColorScheme.light.borderInput, reason: 'cell $i');
        }
      });

      testWidgets('caret shows only in the focused empty cell', (tester) async {
        await setView(tester, 390);
        await tester.pumpWidget(wrap(const VVerificationCodeField(autofocus: true)));
        await tester.pump();
        await tester.pump();
        expect(find.byKey(const Key('v-code-caret')), findsOneWidget);
        expect(tester.getSize(find.byKey(const Key('v-code-caret'))), const Size(2, 22));
        await tester.enterText(find.byType(TextField), '123456');
        await tester.pump();
        expect(find.byKey(const Key('v-code-caret')), findsNothing);
        await tester.enterText(find.byType(TextField), '12');
        await tester.pump();
        expect(find.byKey(const Key('v-code-caret')), findsOneWidget);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        expect(find.byKey(const Key('v-code-caret')), findsNothing);
      });

      testWidgets('paste in split4 completes once', (tester) async {
        await setView(tester, 390);
        var calls = 0;
        String? got;
        await tester.pumpWidget(wrap(VVerificationCodeField(
          length: 8,
          charset: VVerificationCodeCharset.alphanumeric,
          layout: VVerificationCodeLayout.split4,
          onCompleted: (c) {
            calls++;
            got = c;
          },
        )));
        await tester.enterText(find.byType(TextField), 'k7m2p9qx');
        await tester.pump();
        expect(calls, 1);
        expect(got, 'K7M2P9QX');
      });

      testWidgets('fill and split4 fit 320 at text scale 2.0', (tester) async {
        await setView(tester, 320);
        for (final split in [false, true]) {
          await tester.pumpWidget(MaterialApp(
            theme: VTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: VVerificationCodeField(
                  length: split ? 8 : 6,
                  charset: VVerificationCodeCharset.alphanumeric,
                  layout: split ? VVerificationCodeLayout.split4 : VVerificationCodeLayout.fill,
                ),
              ),
            ),
          ));
          await tester.enterText(find.byType(TextField), split ? 'WWWWWWWW' : 'WWWWWW');
          await tester.pump();
          expect(tester.takeException(), isNull);
          final last = split ? 7 : 5;
          expect(tester.getTopRight(cell(last)).dx - tester.getTopLeft(cell(0)).dx, lessThanOrEqualTo(288.01));
        }
      });
    });
  });
}
