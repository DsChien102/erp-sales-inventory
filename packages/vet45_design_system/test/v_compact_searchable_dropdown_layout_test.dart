import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  testWidgets(
    'VCompactSearchableDropdown mounts in ListView accordion without hasSize error',
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
                                          child: VCompactSearchableDropdown<String>(
                                            value: null,
                                            hintText: 'Chon',
                                            stickyActionsReserve: 72,
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

      expect(find.byType(DropdownMenu<String>), findsOneWidget);

      final menu = tester.widget<DropdownMenu<String>>(
        find.byType(DropdownMenu<String>),
      );
      expect(menu.expandedInsets, EdgeInsets.zero);
    },
  );

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
