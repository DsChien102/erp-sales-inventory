import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

// Bridge API still covered in tests.
// ignore_for_file: deprecated_member_use

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('VTabs', () {
    testWidgets('deprecated flat API renders all tab labels', (tester) async {
      await tester.pumpWidget(
        wrap(
          VTabs(
            tabs: const ['One', 'Two', 'Three'],
            selectedIndex: 0,
            onTabSelected: (_) {},
          ),
        ),
      );

      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
    });

    testWidgets('VTabsList throws when used outside VTabs', (tester) async {
      await tester.pumpWidget(
        wrap(
          VTabsList(
            children: const [VTabsTrigger(label: 'Orphan')],
          ),
        ),
      );
      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('VTabsTrigger throws when used outside VTabsList', (tester) async {
      await tester.pumpWidget(
        wrap(
          VTabs(
            selectedIndex: 0,
            onTabSelected: (_) {},
            child: const VTabsTrigger(label: 'Orphan'),
          ),
        ),
      );
      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('VTabsContent throws when used outside VTabs', (tester) async {
      await tester.pumpWidget(
        wrap(
          VTabsContent(
            expand: false,
            children: const [Text('Orphan')],
          ),
        ),
      );
      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('tap trigger updates selected index', (tester) async {
      await tester.pumpWidget(wrap(const _TabsHarness()));

      expect(find.text('Panel 0'), findsOneWidget);

      await tester.tap(find.text('Tab 2'));
      await tester.pumpAndSettle();

      expect(find.text('Panel 2'), findsOneWidget);
    });

    testWidgets('body swipe changes tab and calls onTabSelected', (tester) async {
      await tester.pumpWidget(wrap(const _TabsHarness()));

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Panel 1'), findsOneWidget);
    });

    testWidgets('bar fling changes tab when not scrollable', (tester) async {
      await tester.pumpWidget(wrap(const _TabsHarness()));

      await tester.fling(find.text('Tab 0'), const Offset(-300, 0), 1200);
      await tester.pumpAndSettle();

      expect(find.text('Panel 1'), findsOneWidget);
    });

    testWidgets('bar fling does not change tab when scrollable', (tester) async {
      await tester.pumpWidget(wrap(const _TabsHarness(isScrollable: true)));

      await tester.fling(find.text('Tab 0'), const Offset(-300, 0), 1200);
      await tester.pumpAndSettle();

      expect(find.text('Panel 0'), findsOneWidget);
    });

    testWidgets('swipe skips disabled tab', (tester) async {
      await tester.pumpWidget(
        wrap(const _TabsHarness(disabledIndices: {1})),
      );

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Panel 2'), findsOneWidget);
    });

    testWidgets('external selectedIndex change syncs PageView', (tester) async {
      final key = GlobalKey<_TabsHarnessState>();
      await tester.pumpWidget(wrap(_TabsHarness(key: key)));

      key.currentState!.select(2);
      await tester.pumpAndSettle();

      expect(find.text('Panel 2'), findsOneWidget);
    });

    testWidgets('plain variant omits line indicator on trigger', (tester) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            height: 120,
            child: VTabs(
              selectedIndex: 0,
              onTabSelected: (_) {},
              child: Column(
                children: [
                  VTabsList(
                    variant: VTabsListVariant.plain,
                    children: const [
                      VTabsTrigger(label: 'Plain A'),
                      VTabsTrigger(label: 'Plain B'),
                    ],
                  ),
                  VTabsContent(
                    children: const [
                      Center(child: Text('A')),
                      Center(child: Text('B')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final plainTrigger = find.ancestor(
        of: find.text('Plain A'),
        matching: find.byType(InkWell),
      );
      final inkWell = tester.widget<InkWell>(plainTrigger);
      final container = inkWell.child as Container;
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, isNull);
    });

    testWidgets('vertical list lays out inside Row without infinite width', (tester) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            height: 200,
            child: VTabs(
              selectedIndex: 0,
              orientation: VTabsOrientation.vertical,
              onTabSelected: (_) {},
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VTabsList(
                    children: const [
                      VTabsTrigger(label: 'Tổng quan'),
                      VTabsTrigger(label: 'Liên hệ'),
                    ],
                  ),
                  VTabsContent(
                    children: const [
                      Center(child: Text('Panel 0')),
                      Center(child: Text('Panel 1')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Tổng quan'), findsOneWidget);
    });

    testWidgets('scrollable horizontal list lays out without infinite width', (tester) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            height: 200,
            child: VTabs(
              selectedIndex: 0,
              onTabSelected: (_) {},
              child: Column(
                children: [
                  VTabsList(
                    isScrollable: true,
                    children: const [
                      VTabsTrigger(label: 'Tab A'),
                      VTabsTrigger(label: 'Tab B'),
                      VTabsTrigger(label: 'Tab C'),
                    ],
                  ),
                  VTabsContent(
                    children: const [
                      Center(child: Text('Panel 0')),
                      Center(child: Text('Panel 1')),
                      Center(child: Text('Panel 2')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Tab A'), findsOneWidget);
    });

    testWidgets('non-scrollable triggers share equal horizontal flex', (tester) async {
      await tester.pumpWidget(wrap(const _TabsHarness()));

      final tab0 = tester.getRect(find.text('Tab 0'));
      final tab1 = tester.getRect(find.text('Tab 1'));
      expect(tab0.width, closeTo(tab1.width, 0.01));
    });

    testWidgets('vertical triggers share the list width', (tester) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            height: 200,
            child: VTabs(
              selectedIndex: 0,
              orientation: VTabsOrientation.vertical,
              onTabSelected: (_) {},
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VTabsList(
                    children: const [
                      VTabsTrigger(label: 'Ngắn'),
                      VTabsTrigger(label: 'Nhãn dài hơn'),
                    ],
                  ),
                  VTabsContent(
                    children: const [
                      Center(child: Text('Panel 0')),
                      Center(child: Text('Panel 1')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final shortTab = tester.getRect(
        find.ancestor(of: find.text('Ngắn'), matching: find.byType(InkWell)),
      );
      final longTab = tester.getRect(
        find.ancestor(of: find.text('Nhãn dài hơn'), matching: find.byType(InkWell)),
      );
      expect(shortTab.width, closeTo(longTab.width, 0.01));
    });
  });
}

class _TabsHarness extends StatefulWidget {
  const _TabsHarness({super.key, this.isScrollable = false, this.disabledIndices});

  final bool isScrollable;
  final Set<int>? disabledIndices;

  @override
  State<_TabsHarness> createState() => _TabsHarnessState();
}

class _TabsHarnessState extends State<_TabsHarness> {
  int _index = 0;

  void select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: VTabs(
        selectedIndex: _index,
        disabledIndices: widget.disabledIndices,
        onTabSelected: (i) => setState(() => _index = i),
        child: Column(
          children: [
            VTabsList(
              isScrollable: widget.isScrollable,
              children: const [
                VTabsTrigger(label: 'Tab 0'),
                VTabsTrigger(label: 'Tab 1'),
                VTabsTrigger(label: 'Tab 2'),
              ],
            ),
            VTabsContent(
              children: const [
                Center(child: Text('Panel 0')),
                Center(child: Text('Panel 1')),
                Center(child: Text('Panel 2')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
