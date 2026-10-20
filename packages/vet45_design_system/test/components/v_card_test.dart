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
    final container = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere(
          (c) => c.decoration is BoxDecoration,
        );
    return container.decoration as BoxDecoration?;
  }

  group('VCard shell', () {
    testWidgets('default has no boxShadow', (tester) async {
      await tester.pumpWidget(wrap(const VCard(child: Text('body'))));
      expect(cardDecoration(tester)!.boxShadow, isNull);
    });

    testWidgets('default border uses borderStrong', (tester) async {
      await tester.pumpWidget(wrap(const VCard(child: Text('body'))));
      final border = cardDecoration(tester)!.border! as Border;
      expect(border.top.color, VColorScheme.light.borderStrong);
    });

    testWidgets('enabled false keeps tone border and applies disabled opacity', (tester) async {
      await tester.pumpWidget(
        wrap(const VCard(enabled: false, child: Text('body'))),
      );
      final border = cardDecoration(tester)!.border! as Border;
      expect(border.top.color, VColorScheme.light.borderStrong);
      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, VOpacity.disabled);
    });

    testWidgets('enabled false keeps tone border for danger', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VCard(
            enabled: false,
            tone: VComponentTone.danger,
            child: Text('body'),
          ),
        ),
      );
      final decoration = cardDecoration(tester)!;
      expect(decoration.color, VColorScheme.light.dangerBg);
      final border = decoration.border! as Border;
      expect(border.top.color, VColorScheme.light.danger);
      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, VOpacity.disabled);
    });

    testWidgets('inherits disabled from ambient VComponentScope', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VComponentScope(
            enabled: false,
            child: VCard(child: Text('body')),
          ),
        ),
      );
      final border = cardDecoration(tester)!.border! as Border;
      expect(border.top.color, VColorScheme.light.borderStrong);
      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, VOpacity.disabled);
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

    testWidgets('tone primary uses surfaceBrand and borderBrand', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VCard(
            tone: VComponentTone.primary,
            child: Text('body'),
          ),
        ),
      );

      final decoration = cardDecoration(tester)!;
      expect(decoration.color, VColorScheme.light.surfaceBrand);
      final border = decoration.border! as Border;
      expect(border.top.color, VColorScheme.light.borderBrand);
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
        wrap(
          const VCard(
            child: VCardHeader(
              title: VCardTitle('Only title'),
            ),
          ),
        ),
      );

      expect(find.text('Only title'), findsOneWidget);
      expect(find.byType(VText), findsOneWidget);
    });
  });

  group('VCard tone scope', () {
    testWidgets('inherits card tone to icon', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VCard(
            tone: VComponentTone.warning,
            child: VCardIcon(iconData: Icons.store),
          ),
        ),
      );

      final iconBox = tester.widget<VIconBox>(find.byType(VIconBox));
      expect(iconBox.tone, VComponentTone.warning);
    });

    testWidgets('inherits header tone to title', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VCard(
            child: VCardHeader(
              tone: VComponentTone.warning,
              title: VCardTitle('Warn'),
            ),
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('Warn'));
      expect(title.style?.color, VColorScheme.light.warning);
    });

    testWidgets('local tone overrides inherited tone', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VCard(
            tone: VComponentTone.warning,
            child: Column(
              children: [
                VCardHeader(
                  title: VCardTitle('Danger title', tone: VComponentTone.danger),
                ),
                VCardIcon(
                  iconData: Icons.info_outline,
                  tone: VComponentTone.danger,
                ),
              ],
            ),
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('Danger title'));
      expect(title.style?.color, VColorScheme.light.danger);

      final iconBox = tester.widget<VIconBox>(find.byType(VIconBox));
      expect(iconBox.tone, VComponentTone.danger);
    });

    testWidgets('throws when title used outside header', (tester) async {
      await tester.pumpWidget(wrap(const VCardTitle('Orphan')));
      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('throws when header used outside card', (tester) async {
      await tester.pumpWidget(
        wrap(const VCardHeader(title: Text('Orphan'))),
      );
      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('throws when content used outside card', (tester) async {
      await tester.pumpWidget(
        wrap(const VCardContent(child: Text('Orphan'))),
      );
      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('throws when icon used outside card', (tester) async {
      await tester.pumpWidget(
        wrap(const VCardIcon(iconData: Icons.store)),
      );
      expect(tester.takeException(), isA<FlutterError>());
    });
  });
}
