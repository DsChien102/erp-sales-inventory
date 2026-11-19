import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  Finder shellFinder() => find.byKey(const ValueKey<String>('v_empty_state_shell'));

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
            child: VEmptyHeader(
              children: [
                VEmptyMedia(iconData: Icons.inbox_outlined),
                VEmptyTitle('Empty'),
              ],
            ),
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
            child: VEmptyHeader(
              children: [
                VEmptyMedia(iconData: Icons.inbox_outlined),
                VEmptyTitle('Empty'),
              ],
            ),
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
            child: VEmptyHeader(
              children: [
                VEmptyMedia(iconData: Icons.inbox_outlined),
                VEmptyTitle('Empty'),
              ],
            ),
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
          // ignore: deprecated_member_use
          VEmptyState(
            // ignore: deprecated_member_use
            iconData: Icons.inbox_outlined,
            // ignore: deprecated_member_use
            title: 'No orders yet',
            // ignore: deprecated_member_use
            description: 'Create your first order.',
            // ignore: deprecated_member_use
            actionLabel: 'Create order',
            // ignore: deprecated_member_use
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
          // ignore: deprecated_member_use
          const VEmptyState(
            // ignore: deprecated_member_use
            icon: VIcons.cloudOff,
            // ignore: deprecated_member_use
            title: 'Offline',
            tone: VComponentTone.danger,
          ),
        ),
      );
      final empty = tester.widget<VEmptyState>(find.byType(VEmptyState));
      // ignore: deprecated_member_use
      expect(empty.icon, VIcons.cloudOff);
      expect(empty.tone, VComponentTone.danger);
    });
  });

  group('VEmptyHeader tone scope', () {
    testWidgets('shell tone cascades to title without header tone', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VEmptyState(
            tone: VComponentTone.warning,
            child: VEmptyHeader(
              children: [
                VEmptyMedia(iconData: Icons.warning_amber_outlined),
                VEmptyTitle('Warn'),
                VEmptyDescription('Details'),
              ],
            ),
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('Warn'));
      expect(title.style?.color, VColorScheme.light.warning);
    });

    testWidgets('inherits tone to title media description', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VEmptyState(
            child: VEmptyHeader(
              tone: VComponentTone.warning,
              children: [
                VEmptyMedia(iconData: Icons.warning_amber_outlined),
                VEmptyTitle('Warn'),
                VEmptyDescription('Details'),
              ],
            ),
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('Warn'));
      expect(title.style?.color, VColorScheme.light.warning);

      final description = tester.widget<VText>(
        find.descendant(
          of: find.byType(VEmptyDescription),
          matching: find.byType(VText),
        ),
      );
      expect(description.color, VColorScheme.light.textSecondary);
    });

    testWidgets('local tone overrides header tone', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VEmptyState(
            child: VEmptyHeader(
              tone: VComponentTone.warning,
              children: [
                VEmptyMedia(iconData: Icons.info_outline),
                VEmptyTitle('Danger title', tone: VComponentTone.danger),
                VEmptyDescription('Still secondary'),
              ],
            ),
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('Danger title'));
      expect(title.style?.color, VColorScheme.light.danger);

      final description = tester.widget<VText>(
        find.descendant(
          of: find.byType(VEmptyDescription),
          matching: find.byType(VText),
        ),
      );
      expect(description.color, VColorScheme.light.textSecondary);
    });

    testWidgets('throws when title used outside header', (tester) async {
      await tester.pumpWidget(
        wrap(const VEmptyTitle('Orphan')),
      );
      expect(tester.takeException(), isA<FlutterError>());
    });
  });

  group('VEmptyState hardening', () {
    const longChild = VEmptyHeader(
      children: [
        VEmptyMedia(iconData: Icons.inbox_outlined),
        VEmptyTitle('Không tìm thấy kết quả phù hợp với bộ lọc hiện tại của bạn'),
        VEmptyDescription(
          'Hãy thử bỏ bớt bộ lọc, kiểm tra lại chính tả hoặc tìm bằng mã vạch. '
          'Nếu sản phẩm chưa tồn tại, bạn có thể tạo mới ngay trong danh mục.',
        ),
      ],
    );

    testWidgets('scrolls instead of overflowing in a short viewport', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SizedBox(
                height: 160,
                child: const VEmptyState(bordered: true, child: longChild),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('works inside an unbounded scroll view', (tester) async {
      await tester.pumpWidget(
        wrap(const SingleChildScrollView(child: VEmptyState(child: longChild))),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('legacy title is announced once and CTA keeps its own node', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          // ignore: deprecated_member_use
          VEmptyState(
            // ignore: deprecated_member_use
            iconEmoji: '📭',
            // ignore: deprecated_member_use
            title: 'Chưa có đơn hàng',
            // ignore: deprecated_member_use
            actionLabel: 'Tạo đơn',
            // ignore: deprecated_member_use
            onActionPressed: () {},
          ),
        ),
      );
      expect(find.bySemanticsLabel('Chưa có đơn hàng'), findsOneWidget);
      expect(find.bySemanticsLabel('📭'), findsNothing);
      expect(find.bySemanticsLabel('Tạo đơn'), findsWidgets);
      handle.dispose();
    });
  });
}
