import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const titles = ['Tài khoản', 'Cửa hàng', 'Xác minh email'];

  Widget wrap(Widget child, {double? textScale}) => MaterialApp(
        theme: VTheme.lightTheme,
        builder: textScale == null
            ? null
            : (context, c) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
                  child: c!,
                ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(alignment: Alignment.topLeft, child: child),
          ),
        ),
      );

  Color barColor(WidgetTester t, int i) {
    final w = t.widget(find.byKey(Key('v-step-bar-$i')));
    final deco = (w as DecoratedBox).decoration as BoxDecoration;
    return deco.color!;
  }

  Color? labelColor(WidgetTester t, String s) => t.widget<Text>(find.text(s)).style!.color;

  final c = VColorScheme.light;

  testWidgets('labels are numbered and bars are 4 high', (tester) async {
    await tester.pumpWidget(wrap(const VStepProgress(titles: titles, currentIndex: 1)));
    expect(find.text('1. Tài khoản'), findsOneWidget);
    expect(find.text('2. Cửa hàng'), findsOneWidget);
    expect(find.text('3. Xác minh email'), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('v-step-bar-0'))).height, 4);
    final gap = tester.getTopLeft(find.byKey(const Key('v-step-bar-1'))).dx -
        tester.getTopRight(find.byKey(const Key('v-step-bar-0'))).dx;
    expect(gap, 8);
  });

  testWidgets('standard colors', (tester) async {
    await tester.pumpWidget(wrap(const VStepProgress(titles: titles, currentIndex: 1)));
    expect(barColor(tester, 0), c.primary);
    expect(barColor(tester, 1), c.primary);
    expect(barColor(tester, 2), c.borderDefault);
    expect(labelColor(tester, '1. Tài khoản'), c.textSecondary);
    expect(labelColor(tester, '2. Cửa hàng'), c.primary);
    expect(labelColor(tester, '3. Xác minh email'), c.textMuted);
  });

  testWidgets('mobile colors', (tester) async {
    await tester.pumpWidget(wrap(const VStepProgress(
      titles: titles,
      currentIndex: 1,
      variant: VStepProgressVariant.mobile,
    )));
    expect(barColor(tester, 2), c.borderStrong);
    expect(labelColor(tester, '1. Tài khoản'), c.textSecondary);
    expect(labelColor(tester, '3. Xác minh email'), c.textSecondary);
    expect(labelColor(tester, '2. Cửa hàng'), c.textBrand);
  });

  testWidgets('exposes one semantics label', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(wrap(const VStepProgress(titles: titles, currentIndex: 1)));
    expect(find.bySemanticsLabel('2/3 · Cửa hàng'), findsOneWidget);
    h.dispose();
  });

  testWidgets('fits 288 at text scale 2.0', (tester) async {
    await tester.pumpWidget(wrap(
      const SizedBox(
        width: 288,
        child: VStepProgress(titles: titles, currentIndex: 2),
      ),
      textScale: 2.0,
    ));
    expect(tester.takeException(), isNull);
    final t = tester.widget<Text>(find.text('3. Xác minh email'));
    expect(t.maxLines, 1);
  });
}
