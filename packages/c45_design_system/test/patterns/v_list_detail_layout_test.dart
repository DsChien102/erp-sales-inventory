import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

class _CounterWidget extends StatefulWidget {
  const _CounterWidget();

  @override
  State<_CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<_CounterWidget> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    final isSplit = VListDetailLayout.isSplitOf(context);
    return Column(
      children: [
        Text('Count: $count'),
        Text('Split: $isSplit'),
        ElevatedButton(
          onPressed: () => setState(() => count++),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

class _ListProbe extends StatelessWidget {
  const _ListProbe();

  @override
  Widget build(BuildContext context) {
    final isSplit = VListDetailLayout.isSplitOf(context);
    return Text('List split: $isSplit');
  }
}

void main() {
  group('VListDetailLayout', () {
    testWidgets('rộng 1000: dựng cả list và detail, isSplitOf là true', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 1000,
                height: 600,
                child: const VListDetailLayout(
                  list: _ListProbe(),
                  detail: _CounterWidget(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('List split: true'), findsOneWidget);
      expect(find.text('Split: true'), findsOneWidget);
    });

    testWidgets('rộng 800: chỉ dựng detail, list không dựng, isSplitOf là false', (tester) async {
      var listBuilt = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 600,
                child: VListDetailLayout(
                  list: Builder(
                    builder: (context) {
                      listBuilt = true;
                      return const Text('List');
                    },
                  ),
                  detail: const _CounterWidget(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(listBuilt, isFalse);
      expect(find.text('List'), findsNothing);
      expect(find.text('Split: false'), findsOneWidget);
    });

    testWidgets('đổi bề rộng qua ngưỡng không mất state của detail', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final widthNotifier = ValueNotifier<double>(1000);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: ValueListenableBuilder<double>(
              valueListenable: widthNotifier,
              builder: (context, width, child) {
                return SizedBox(
                  width: width,
                  height: 600,
                  child: const VListDetailLayout(
                    list: _ListProbe(),
                    detail: _CounterWidget(),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Count: 0'), findsOneWidget);
      expect(find.text('Split: true'), findsOneWidget);

      // Increment counter in detail
      await tester.tap(find.text('Increment'));
      await tester.pumpAndSettle();
      expect(find.text('Count: 1'), findsOneWidget);

      // Resize to 800 (narrow - below default threshold 840)
      widthNotifier.value = 800;
      await tester.pumpAndSettle();

      // State is preserved!
      expect(find.text('Count: 1'), findsOneWidget);
      expect(find.text('Split: false'), findsOneWidget);

      // Resize back to 1000 (split)
      widthNotifier.value = 1000;
      await tester.pumpAndSettle();

      expect(find.text('Count: 1'), findsOneWidget);
      expect(find.text('Split: true'), findsOneWidget);
    });

    testWidgets('bề rộng >= 840: toast phát từ detail chỉ hiện ở cột chi tiết, toast từ list chỉ hiện ở list', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      late BuildContext listContext;
      late BuildContext detailContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 1000,
                height: 600,
                child: VListDetailLayout(
                  list: Scaffold(
                    body: Builder(
                      builder: (context) {
                        listContext = context;
                        return const Text('List Content');
                      },
                    ),
                  ),
                  detail: Scaffold(
                    body: Builder(
                      builder: (context) {
                        detailContext = context;
                        return const Text('Detail Content');
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show toast from detail
      ScaffoldMessenger.of(detailContext).showSnackBar(
        const SnackBar(content: Text('toast-detail')),
      );
      await tester.pump();

      expect(find.text('toast-detail'), findsOneWidget);
      final detailToastCenter = tester.getCenter(find.text('toast-detail'));
      expect(detailToastCenter.dx, greaterThan(500));

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Show toast from list
      ScaffoldMessenger.of(listContext).showSnackBar(
        const SnackBar(content: Text('toast-list')),
      );
      await tester.pump();

      expect(find.text('toast-list'), findsOneWidget);
      final listToastCenter = tester.getCenter(find.text('toast-list'));
      expect(listToastCenter.dx, lessThan(500));
    });
  });
}
