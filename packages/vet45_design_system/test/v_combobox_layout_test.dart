import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

ScrollableState _menuItemListScrollable(WidgetTester tester) {
  for (final element in find
      .descendant(
        of: find.byType(MenuAnchor),
        matching: find.byType(Scrollable),
      )
      .evaluate()) {
    final state = tester.state<ScrollableState>(
      find.byElementPredicate((candidate) => candidate == element),
    );
    if (state.position.maxScrollExtent > 0) {
      return state;
    }
  }

  fail('Expected a scrollable menu item list inside MenuAnchor');
}

ScrollableState _menuOuterScrollable(WidgetTester tester) {
  ScrollableState? outerState;
  for (final element in find
      .descendant(
        of: find.byType(MenuAnchor),
        matching: find.byType(Scrollable),
      )
      .evaluate()) {
    final state = tester.state<ScrollableState>(
      find.byElementPredicate((candidate) => candidate == element),
    );
    if (state.position.axis == Axis.vertical && state.position.maxScrollExtent == 0) {
      outerState = state;
      break;
    }
  }

  if (outerState == null) {
    fail('Expected a pinned outer menu scrollable inside MenuAnchor');
  }
  return outerState!;
}

Finder _menuItemListScrollableFinder() {
  return find.byElementPredicate((element) {
    if (element.widget is! Scrollable) {
      return false;
    }
    final scrollable = element as StatefulElement;
    final state = scrollable.state;
    if (state is! ScrollableState) {
      return false;
    }
    return state.position.maxScrollExtent > 0;
  });
}

void main() {
  testWidgets(
    'VCombobox mounts in ListView accordion without hasSize error',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      FlutterErrorDetails? caught;
      final old = FlutterError.onError;
      FlutterError.onError = (details) {
        caught ??= details;
        old?.call(details);
      };
      addTearDown(() {
        FlutterError.onError = old;
        tester.binding.setSurfaceSize(null);
      });

      var expanded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            child: Column(
                              children: [
                                ListTile(
                                  title: const Text('5. Dia chi giao hang'),
                                  trailing: Icon(
                                    expanded ? Icons.expand_less : Icons.expand_more,
                                  ),
                                  onTap: () => setState(() => expanded = !expanded),
                                ),
                                if (expanded)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: 92,
                                          child: Text('Tinh'),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: VCombobox<String>(
                                            value: null,
                                            hintText: 'Chon',
                                            items: [
                                              for (var i = 0; i < 34; i++)
                                                DropdownMenuEntry(
                                                  value: 'p$i',
                                                  label: 'Province $i',
                                                ),
                                            ],
                                            onChanged: (_) {},
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 72),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('5. Dia chi giao hang'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(
        caught,
        isNull,
        reason: 'layout error: ${caught?.exceptionAsString()}',
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);

      await tester.tap(find.text('Chon'));
      await tester.pumpAndSettle();

      expect(find.byType(MenuAnchor), findsOneWidget);
    },
  );

  testWidgets('VCombobox unfocuses when tapping outside while menu is open', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: VCombobox<String>(
              value: null,
              hintText: 'Chon',
              items: const [
                DropdownMenuEntry(value: 'a', label: 'Alpha'),
                DropdownMenuEntry(value: 'b', label: 'Beta'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    await tester.tap(textField);
    await tester.pumpAndSettle();

    final focusNode = tester.widget<TextField>(textField).focusNode!;
    expect(focusNode.hasFocus, isTrue);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('VCombobox menu shrinks to fit few items', (tester) async {
    const menuMaxHeight = 300.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: VCombobox<String>(
              value: null,
              hintText: 'Chon',
              items: const [
                DropdownMenuEntry(value: 'a', label: 'Alpha'),
                DropdownMenuEntry(value: 'b', label: 'Beta'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(MenuAnchor),
        matching: find.byType(ListView),
      ),
      findsNothing,
    );

    final metrics = VOverlayMenuLayout.panelMetrics(
      itemCount: 2,
      menuMaxHeight: menuMaxHeight,
      itemHeight: VCombobox.controlHeight,
      menuPadding: VSpacing.space2,
    );
    expect(metrics.needsScroll, isFalse);
    expect(metrics.shellHeight, VCombobox.controlHeight * 2 + VSpacing.space2 * 2);

    final shellBox = tester.renderObject<RenderBox>(
      find.ancestor(
        of: find.text('Alpha'),
        matching: find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.height == metrics.shellHeight,
        ),
      ),
    );
    expect(shellBox.size.height, metrics.shellHeight);
  });

  testWidgets('VCombobox menu scrolls with vertical drag gesture', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: VCombobox<String>(
              value: null,
              hintText: 'Chon',
              items: [
                for (var i = 0; i < 20; i++)
                  DropdownMenuEntry(value: 'p$i', label: 'Province $i'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final innerState = _menuItemListScrollable(tester);
    final outerState = _menuOuterScrollable(tester);
    expect(innerState.position.pixels, 0);
    expect(outerState.position.pixels, 0);
    expect(outerState.position.maxScrollExtent, 0);

    await tester.drag(_menuItemListScrollableFinder(), const Offset(0, -240));
    await tester.pumpAndSettle();

    expect(innerState.position.pixels, greaterThan(0));
    expect(outerState.position.pixels, 0);
  });

  testWidgets('VCombobox menu stays open and focused while scrolling items', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: VCombobox<String>(
              value: null,
              hintText: 'Chon',
              items: [
                for (var i = 0; i < 20; i++)
                  DropdownMenuEntry(value: 'p$i', label: 'Province $i'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    await tester.tap(textField);
    await tester.pumpAndSettle();

    final focusNode = tester.widget<TextField>(textField).focusNode!;
    expect(focusNode.hasFocus, isTrue);

    await tester.drag(_menuItemListScrollableFinder(), const Offset(0, -240));
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isTrue);
    expect(find.byType(MenuItemButton), findsWidgets);
  });

  testWidgets('VCombobox selecting item closes menu and calls onChanged', (
    tester,
  ) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: VCombobox<String>(
              value: null,
              hintText: 'Chon',
              items: const [
                DropdownMenuEntry(value: 'a', label: 'Alpha'),
                DropdownMenuEntry(value: 'b', label: 'Beta'),
              ],
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    await tester.tap(textField);
    await tester.pumpAndSettle();

    final focusNode = tester.widget<TextField>(textField).focusNode!;
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();

    expect(selected, 'b');
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('VCombobox shows empty overlay when search matches no items', (
    tester,
  ) async {
    const menuPadding = VSpacing.space2;
    const emptyShellHeight =
        menuPadding * 2 + VComboboxEmpty.preferredHeight;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: VCombobox<String>(
              value: null,
              hintText: 'Chon',
              items: const [
                DropdownMenuEntry(value: 'a', label: 'Alpha'),
                DropdownMenuEntry(value: 'b', label: 'Beta'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    await tester.tap(textField);
    await tester.pumpAndSettle();

    expect(find.byType(MenuItemButton), findsWidgets);

    await tester.enterText(textField, 'zzz-no-match');
    await tester.pumpAndSettle();

    final focusNode = tester.widget<TextField>(textField).focusNode!;
    expect(focusNode.hasFocus, isTrue);
    expect(find.byType(MenuItemButton), findsNothing);
    expect(find.byType(VComboboxEmpty), findsOneWidget);
    expect(find.text('Không tìm thấy kết quả'), findsOneWidget);

    final shellBox = tester.renderObject<RenderBox>(
      find.ancestor(
        of: find.byType(VComboboxEmpty),
        matching: find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.height == emptyShellHeight,
        ),
      ),
    );
    expect(shellBox.size.height, emptyShellHeight);
    expect(shellBox.size.height, lessThan(120));
  });

  testWidgets('VComboboxEmpty uses custom message when provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VComboboxEmpty(message: 'Khong co ket qua'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khong co ket qua'), findsOneWidget);
    expect(VComboboxEmpty.preferredHeight, VSpacing.space2 * 2 + 22);
  });

  test(
    'VOverlayMenuLayout.panelMetrics caps shell height at menu max',
    () {
      const menuMaxHeight = 300.0;
      const menuPadding = VSpacing.space2;

      final compact = VOverlayMenuLayout.panelMetrics(
        itemCount: 2,
        menuMaxHeight: menuMaxHeight,
        itemHeight: VCombobox.controlHeight,
        menuPadding: menuPadding,
      );
      expect(compact.needsScroll, isFalse);
      expect(compact.shellHeight, VCombobox.controlHeight * 2 + menuPadding * 2);

      final scrollable = VOverlayMenuLayout.panelMetrics(
        itemCount: 20,
        menuMaxHeight: menuMaxHeight,
        itemHeight: VCombobox.controlHeight,
        menuPadding: menuPadding,
      );
      expect(scrollable.needsScroll, isTrue);
      expect(scrollable.shellHeight, menuMaxHeight);
      expect(scrollable.listViewportHeight, menuMaxHeight - menuPadding * 2);
    },
  );

  test('VOverlayMenuLayout.shadowBleedPadding reserves space for e2 shadow', () {
    final bleed = VOverlayMenuLayout.shadowBleedPadding(VShadows.e2);
    final shadow = VShadows.e2.single;
    expect(bleed.top, shadow.blurRadius - shadow.offset.dy);
    expect(bleed.bottom, shadow.blurRadius + shadow.offset.dy);
    expect(bleed.left, shadow.blurRadius);
    expect(bleed.right, shadow.blurRadius);
  });

  testWidgets(
    'VOverlayMenuLayout.availableSpace tolerates unlaid-out ancestors',
    (tester) async {
      late double space;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // During first build the render object may be missing/unlaid-out;
              // must not throw.
              space = VOverlayMenuLayout.availableSpace(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(space, VOverlayMenuLayout.defaultMenuHeight);
    },
  );
}
