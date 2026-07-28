import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  BoxDecoration? cardDecoration(WidgetTester tester) {
    final container = tester.widgetList<Container>(find.byType(Container)).firstWhere(
      (c) => c.decoration is BoxDecoration,
    );
    return container.decoration as BoxDecoration?;
  }

  group('VCard shell', () {
    testWidgets('default has no boxShadow', (tester) async {
      await tester.pumpWidget(wrap(const VCard(child: Text('body'))));
      expect(cardDecoration(tester)!.boxShadow, isNull);
    });

    testWidgets('emphasis medium applies e1 shadow', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VCard(
            emphasis: VComponentEmphasis.medium,
            child: Text('body'),
          ),
        ),
      );
      expect(cardDecoration(tester)!.boxShadow, VShadows.e1);
    });

    testWidgets('emphasis strong applies e2 shadow', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VCard(
            emphasis: VComponentEmphasis.strong,
            child: Text('body'),
          ),
        ),
      );
      expect(cardDecoration(tester)!.boxShadow, VShadows.e2);
    });

    testWidgets('tone danger uses dangerBg and danger border', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VCard(
            tone: VComponentTone.danger,
            child: Text('body'),
          ),
        ),
      );

      final decoration = cardDecoration(tester)!;
      expect(decoration.color, VColorScheme.light.dangerBg);
      final border = decoration.border! as Border;
      expect(border.top.color, VColorScheme.light.danger);
    });

    testWidgets('elevated true with subtle still applies e1', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VCard(
            // ignore: deprecated_member_use_from_same_package
            elevated: true,
            emphasis: VComponentEmphasis.subtle,
            child: Text('body'),
          ),
        ),
      );
      expect(cardDecoration(tester)!.boxShadow, VShadows.e1);
    });

    testWidgets('explicit backgroundColor overrides tone', (tester) async {
      const override = Color(0xFF112233);
      await tester.pumpWidget(
        wrap(
          const VCard(
            tone: VComponentTone.danger,
            backgroundColor: override,
            child: Text('body'),
          ),
        ),
      );
      expect(cardDecoration(tester)!.color, override);
    });
  });

  group('VCard compound children', () {
    testWidgets('renders title, description, and footer', (tester) async {
      await tester.pumpWidget(
        wrap(
          VCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const VCardHeader(
                  title: VCardTitle(
                    'Đối tác',
                    description: 'Mô tả',
                  ),
                  action: VCardAction(child: Text('action')),
                ),
                const VCardContent(
                  child: Column(
                    children: [
                      VCardIcon(iconData: Icons.store),
                      Text('content-body'),
                    ],
                  ),
                ),
                VCardFooter(
                  child: VButton(label: 'Lưu', onPressed: () {}),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Đối tác'), findsOneWidget);
      expect(find.text('Mô tả'), findsOneWidget);
      expect(find.text('content-body'), findsOneWidget);
      expect(find.text('action'), findsOneWidget);
      expect(find.text('Lưu'), findsOneWidget);
    });

    testWidgets('VCardTitle without description omits secondary text', (tester) async {
      await tester.pumpWidget(
        wrap(const VCardTitle('Only title')),
      );

      expect(find.text('Only title'), findsOneWidget);
      expect(find.byType(VText), findsOneWidget);
    });
  });
}
