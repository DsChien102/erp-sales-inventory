import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_design_system/src/components/v_text_field_focus_ring.dart';

ScrollableState _menuItemListScrollable(WidgetTester tester) {
  for (final element
      in find
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
  for (final element
      in find
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

/// Compose helper for recipe-shaped layout tests.
Widget _simpleCombobox({
  String? value,
  String? hintText = 'Chon',
  required List<(String value, String label)> items,
  ValueChanged<String?>? onChanged,
  bool? enabled,
  bool? open,
  ValueChanged<bool>? onOpenChange,
}) {
  final labels = {for (final item in items) item.$1: item.$2};
  return VCombobox<String>(
    value: value,
    enabled: enabled,
    open: open,
    onOpenChange: onOpenChange,
    onChanged: onChanged ?? (_) {},
    displayTextForValue: (v) => v == null ? '' : (labels[v] ?? ''),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VComboboxContent(
          child: VComboboxList(
            children: [
              for (final item in items)
                VComboboxItem<String>(
                  value: item.$1,
                  searchText: item.$2,
                  child: Text(item.$2),
                ),
            ],
          ),
        ),
        VComboboxInput(hintText: hintText),
      ],
    ),
  );
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
                                          child: _simpleCombobox(
                                            items: [
                                              for (var i = 0; i < 34; i++)
                                                ('p$i', 'Province $i'),
                                            ],
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
            child: _simpleCombobox(
              items: const [
                ('a', 'Alpha'),
                ('b', 'Beta'),
              ],
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

  testWidgets('VCombobox keeps focus when parent scrolls while menu is open', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              const SizedBox(height: 120),
              Padding(
                padding: const EdgeInsets.all(24),
                child: _simpleCombobox(
                  items: const [
                    ('a', 'Alpha'),
                    ('b', 'Beta'),
                  ],
                ),
              ),
              const SizedBox(height: 1200),
            ],
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
    expect(find.text('Alpha'), findsOneWidget);

    // Drag empty space above the field (not through the open menu overlay).
    await tester.dragFrom(const Offset(24, 40), const Offset(0, -180));
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('VCombobox menu shrinks to fit few items', (tester) async {
    const menuMaxHeight = 300.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: _simpleCombobox(
              items: const [
                ('a', 'Alpha'),
                ('b', 'Beta'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // Column + SingleChildScrollView; few items must not need scroll.
    expect(
      find.descendant(
        of: find.byType(MenuAnchor),
        matching: find.byType(SingleChildScrollView),
      ),
      findsWidgets,
    );
    var foundCompactScroll = false;
    for (final element in find
        .descendant(
          of: find.byType(MenuAnchor),
          matching: find.byType(Scrollable),
        )
        .evaluate()) {
      final state = tester.state<ScrollableState>(
        find.byElementPredicate((candidate) => candidate == element),
      );
      if (state.position.axis == Axis.vertical &&
          state.position.maxScrollExtent == 0) {
        foundCompactScroll = true;
        break;
      }
    }
    expect(foundCompactScroll, isTrue);

    RenderBox? shellBox;
    for (final element in find
        .ancestor(of: find.text('Alpha'), matching: find.byType(SizedBox))
        .evaluate()) {
      final box = element.renderObject;
      if (box is RenderBox &&
          box.hasSize &&
          box.size.height > VCombobox.controlHeight &&
          box.size.height < menuMaxHeight) {
        shellBox = box;
        break;
      }
    }
    expect(shellBox, isNotNull);
    // Auto-sized rows; shell stays compact (not full 300).
    expect(shellBox!.size.height, lessThan(menuMaxHeight));
    expect(shellBox.size.height, lessThan(VCombobox.controlHeight * 3));
  });

  testWidgets('VCombobox menu scrolls with vertical drag gesture', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: _simpleCombobox(
              items: [
                for (var i = 0; i < 20; i++) ('p$i', 'Province $i'),
              ],
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
            child: _simpleCombobox(
              items: [
                for (var i = 0; i < 20; i++) ('p$i', 'Province $i'),
              ],
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
            child: _simpleCombobox(
              items: const [
                ('a', 'Alpha'),
                ('b', 'Beta'),
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

  testWidgets(
    'VCombobox tap opens overlay with empty filter but keeps selected label',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: _simpleCombobox(
                value: 'a',
                items: const [
                  ('a', 'Alpha'),
                  ('b', 'Beta'),
                  ('c', 'Charlie'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(tester.widget<TextField>(textField).controller!.text, 'Alpha');

      await tester.tap(textField);
      await tester.pumpAndSettle();

      // Selected label stays in the field…
      expect(tester.widget<TextField>(textField).controller!.text, 'Alpha');
      // …but filter is empty so every item is listed (not only Alpha matches).
      expect(find.text('Alpha'), findsWidgets);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
    },
  );

  testWidgets(
    'VCombobox re-opens overlay on tap when closed while still focused',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: _simpleCombobox(
                items: const [
                  ('a', 'Alpha'),
                  ('b', 'Beta'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.pumpAndSettle();
      expect(find.text('Beta'), findsOneWidget);

      // Close via chevron while keeping focus path: unfocus then refocus would
      // reopen; instead close the MenuController through the root by tapping
      // the chevron (toggle).
      await tester.tap(find.byType(VIconBox));
      await tester.pumpAndSettle();
      expect(find.text('Beta'), findsNothing);

      // Field may still be focused; a second tap must reopen.
      await tester.tap(textField);
      await tester.pumpAndSettle();
      expect(find.text('Beta'), findsOneWidget);
    },
  );

  testWidgets('VCombobox shows empty overlay when search matches no items', (
    tester,
  ) async {
    const menuPadding = VSpacing.space2;
    const emptyShellHeight = menuPadding * 2 + VComboboxEmpty.preferredHeight;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: _simpleCombobox(
              items: const [
                ('a', 'Alpha'),
                ('b', 'Beta'),
              ],
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

    RenderBox? shellBox;
    for (final element in find
        .ancestor(
          of: find.byType(VComboboxEmpty),
          matching: find.byType(SizedBox),
        )
        .evaluate()) {
      final box = element.renderObject;
      if (box is RenderBox &&
          box.hasSize &&
          (box.size.height - emptyShellHeight).abs() < 0.5) {
        shellBox = box;
        break;
      }
    }
    expect(shellBox, isNotNull);
    expect(shellBox!.size.height, emptyShellHeight);
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

  testWidgets('VComboboxItem custom child filters by searchText only', (
    tester,
  ) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setState) {
                return VCombobox<String>(
                  value: selected,
                  onChanged: (value) => setState(() => selected = value),
                  displayTextForValue: (value) => switch (value) {
                    'hop' => 'Hộp',
                    'chai' => 'Chai',
                    _ => '',
                  },
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VComboboxContent(
                        child: VComboboxList(
                          children: [
                            VComboboxItem<String>(
                              value: 'hop',
                              searchText: 'Hop hop don vi',
                              child: Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Hộp'),
                                ],
                              ),
                            ),
                            VComboboxItem<String>(
                              value: 'chai',
                              searchText: 'Chai bottle',
                              child: Text('Chai'),
                            ),
                          ],
                        ),
                      ),
                      VComboboxInput(hintText: 'Chon'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text('Hộp'), findsOneWidget);
    expect(find.text('Chai'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'bottle');
    await tester.pumpAndSettle();
    expect(find.text('Chai'), findsOneWidget);
    expect(find.text('Hộp'), findsNothing);

    await tester.tap(find.text('Chai'));
    await tester.pumpAndSettle();
    expect(selected, 'chai');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Chai');
    expect(find.text('Chai bottle'), findsNothing);

    // Reselect hop: clear filter so both items show; input must keep display label.
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hộp'));
    await tester.pumpAndSettle();
    expect(selected, 'hop');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Hộp');
    expect(find.text('Hop hop don vi'), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hộp'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Hộp',
    );
  });

  testWidgets('VComboboxItem without searchText filters via displayTextForValue', (
    tester,
  ) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setState) {
                return VCombobox<String>(
                  value: selected,
                  onChanged: (value) => setState(() => selected = value),
                  displayTextForValue: (value) => switch (value) {
                    'a' => 'Alpha',
                    'b' => 'Beta',
                    _ => '',
                  },
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VComboboxContent(
                        child: VComboboxList(
                          children: [
                            VComboboxItem<String>(
                              value: 'a',
                              child: Text('Alpha'),
                            ),
                            VComboboxItem<String>(
                              value: 'b',
                              child: Text('Beta'),
                            ),
                          ],
                        ),
                      ),
                      VComboboxInput(hintText: 'Chon'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bet');
    await tester.pumpAndSettle();
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);

    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(selected, 'b');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Beta');
  });

  testWidgets('VComboboxContent footer shows with empty list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: VCombobox<String>(
              value: null,
              onChanged: (_) {},
              displayTextForValue: (value) => value ?? '',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VComboboxContent(
                    footer: const Text('Tao moi'),
                    child: const VComboboxList(
                      children: [
                        VComboboxItem<String>(
                          value: 'Alpha',
                          child: Text('Alpha'),
                        ),
                      ],
                    ),
                  ),
                  const VComboboxInput(hintText: 'Chon'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.byType(VComboboxEmpty), findsOneWidget);
    expect(find.text('Tao moi'), findsOneWidget);
  });

  testWidgets('VCombobox overlay refreshes when items change while open', (
    tester,
  ) async {
    var items = <String>['Alpha'];
    late VoidCallback addBeta;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              addBeta = () => setState(() => items = [...items, 'Beta']);
              return Padding(
                padding: const EdgeInsets.all(24),
                child: VCombobox<String>(
                  value: null,
                  onChanged: (_) {},
                  displayTextForValue: (value) => value ?? '',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VComboboxContent(
                        child: VComboboxList(
                          children: [
                            for (final label in items)
                              VComboboxItem<String>(
                                value: label,
                                child: Text(label),
                              ),
                          ],
                        ),
                      ),
                      const VComboboxInput(hintText: 'Chon'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);

    addBeta();
    await tester.pump(); // register overlay slot
    await tester.pump(); // post-frame notify → overlay rebuild
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('VComboboxInput focus ring turns on when focused', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: VCombobox<String>(
              value: null,
              onChanged: (_) {},
              displayTextForValue: (value) => value ?? '',
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VComboboxContent(
                    child: VComboboxList(
                      children: [
                        VComboboxItem<String>(
                          value: 'a',
                          child: Text('Alpha'),
                        ),
                      ],
                    ),
                  ),
                  VComboboxInput(hintText: 'Chon'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<VTextFieldFocusRing>(find.byType(VTextFieldFocusRing)).focused,
      isFalse,
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(
      tester.widget<VTextFieldFocusRing>(find.byType(VTextFieldFocusRing)).focused,
      isTrue,
    );
  });

  testWidgets('VComboboxItem multi-line child sizes taller than control height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: VCombobox<String>(
              value: null,
              onChanged: (_) {},
              displayTextForValue: (value) => value ?? '',
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VComboboxContent(
                    child: VComboboxList(
                      children: [
                        VComboboxItem<String>(
                          value: 'hop',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Hộp'),
                              Text('Đơn vị cơ sở'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  VComboboxInput(hintText: 'Chon'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final itemBox = tester.renderObject<RenderBox>(
      find.byType(MenuItemButton),
    );
    expect(itemBox.size.height, greaterThan(VCombobox.controlHeight));
    expect(find.text('Đơn vị cơ sở'), findsOneWidget);
  });

  testWidgets('VCombobox controlled open calls onOpenChange', (tester) async {
    var open = false;
    final opens = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: _simpleCombobox(
                  open: open,
                  onOpenChange: (next) {
                    opens.add(next);
                    setState(() => open = next);
                  },
                  items: const [
                    ('a', 'Alpha'),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(opens, isNotEmpty);
    expect(opens.first, isTrue);
    expect(find.text('Alpha'), findsOneWidget);
  });
}
