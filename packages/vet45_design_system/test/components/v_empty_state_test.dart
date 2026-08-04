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

  Finder shellFinder() =>
      find.byKey(const ValueKey<String>('v_empty_state_shell'));

  BoxDecoration? emptyDecoration(WidgetTester tester) {
    final finder = shellFinder();
    if (finder.evaluate().isEmpty) return null;
    return tester.widget<DecoratedBox>(finder).decoration as BoxDecoration?;
  }

  group('VEmptyState shell', () {
    testWidgets('default has no border or background', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VEmptyState(
            iconData: Icons.inbox_outlined,
            title: 'Empty',
          ),
        ),
      );
      expect(emptyDecoration(tester), isNull);
      expect(find.text('Empty'), findsOneWidget);
    });

    testWidgets('bordered draws default outline', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VEmptyState(
            bordered: true,
            iconData: Icons.inbox_outlined,
            title: 'Empty',
          ),
        ),
      );
      final decoration = emptyDecoration(tester)!;
      final border = decoration.border! as Border;
      expect(border.top.color, VColorScheme.light.borderDefault);
    });

    testWidgets('filled uses surfaceAlt background', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VEmptyState(
            filled: true,
            iconData: Icons.inbox_outlined,
            title: 'Empty',
          ),
        ),
      );
      expect(emptyDecoration(tester)!.color, VColorScheme.light.surfaceAlt);
    });
  });

  group('VEmptyState composition', () {
    testWidgets('renders header title description and content', (tester) async {
      await tester.pumpWidget(
        wrap(
          VEmptyState(
            bordered: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VEmptyHeader(
                  children: [
                    VEmptyMedia(iconData: Icons.cloud_off_outlined),
                    VEmptyTitle('No projects'),
                    VEmptyDescription('Create your first project.'),
                  ],
                ),
                const VGap.xl(),
                VEmptyContent(
                  child: VButton(label: 'Create', onPressed: () {}),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('No projects'), findsOneWidget);
      expect(find.text('Create your first project.'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
      expect(find.byType(VEmptyMedia), findsOneWidget);
      expect(find.byType(VEmptyHeader), findsOneWidget);
      expect(find.byType(VEmptyContent), findsOneWidget);
    });
  });

  group('VEmptyState legacy flat API', () {
    testWidgets('maps title description and action', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        wrap(
          VEmptyState(
            iconData: Icons.inbox_outlined,
            title: 'No orders yet',
            description: 'Create your first order.',
            actionLabel: 'Create order',
            onActionPressed: () => pressed = true,
          ),
        ),
      );

      expect(find.text('No orders yet'), findsOneWidget);
      expect(find.text('Create your first order.'), findsOneWidget);
      await tester.tap(find.text('Create order'));
      expect(pressed, isTrue);
    });

    testWidgets('exposes icon and tone for existing tests', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VEmptyState(
            icon: VIcons.cloudOff,
            title: 'Offline',
            tone: VComponentTone.danger,
          ),
        ),
      );
      final empty = tester.widget<VEmptyState>(find.byType(VEmptyState));
      expect(empty.icon, VIcons.cloudOff);
      expect(empty.tone, VComponentTone.danger);
    });
  });
}
