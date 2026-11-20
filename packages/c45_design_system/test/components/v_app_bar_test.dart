import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('VAppBar', () {
    Future<void> pumpPushed(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(appBar: VAppBar(title: 'Chi tiết')),
                  ),
                ),
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
    }

    testWidgets('back button is named "Quay lại"', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPushed(tester);

      expect(find.byTooltip('Quay lại'), findsOneWidget);
      final node = tester.getSemantics(find.byTooltip('Quay lại'));
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.tooltip.isNotEmpty || node.label.contains('Quay lại'), isTrue);
      handle.dispose();
    });

    testWidgets('back button pops the route', (tester) async {
      await pumpPushed(tester);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết'), findsNothing);
    });

    testWidgets('showBackButton: false trên route pop được: không có BackButton ngầm', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(
                      appBar: VAppBar(title: 'Chi tiết', showBackButton: false),
                    ),
                  ),
                ),
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byTooltip('Quay lại'), findsNothing);
      expect(find.byTooltip('Back'), findsNothing);
    });

    testWidgets('no back button on the root route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(appBar: VAppBar(title: 'Gốc')),
        ),
      );
      expect(find.byTooltip('Quay lại'), findsNothing);
    });

    testWidgets('back button respects PopScope and does not pop when canPop is false', (tester) async {
      final calls = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PopScope(
                      canPop: false,
                      onPopInvokedWithResult: (didPop, _) => calls.add(didPop),
                      child: const Scaffold(appBar: VAppBar(title: 'X')),
                    ),
                  ),
                ),
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();

      expect(find.text('X'), findsOneWidget);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();

      expect(find.text('X'), findsOneWidget);
      expect(calls, equals([false]));
    });

    testWidgets('poppableNavigator: false looks at root navigator when nearest cannot pop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (rootContext) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(rootContext).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: Navigator(
                        onGenerateRoute: (_) => MaterialPageRoute<void>(
                          builder: (_) => const Scaffold(
                            appBar: VAppBar(
                              title: 'Nested Root Route',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open Nested'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Nested'));
      await tester.pumpAndSettle();

      expect(find.text('Nested Root Route'), findsOneWidget);
      expect(find.byTooltip('Quay lại'), findsOneWidget);

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();

      expect(find.text('Nested Root Route'), findsNothing);
      expect(find.text('Open Nested'), findsOneWidget);
    });

    testWidgets('VAppBar.popNearest pops nearest navigator if it can pop, otherwise root', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (rootContext) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(rootContext).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: Navigator(
                        onGenerateRoute: (_) => MaterialPageRoute<void>(
                          builder: (nestedContext) => Scaffold(
                            body: TextButton(
                              onPressed: () => VAppBar.popNearest(nestedContext),
                              child: const Text('Call PopNearest'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text('Go Deep'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go Deep'));
      await tester.pumpAndSettle();

      expect(find.text('Call PopNearest'), findsOneWidget);

      await tester.tap(find.text('Call PopNearest'));
      await tester.pumpAndSettle();

      expect(find.text('Call PopNearest'), findsNothing);
      expect(find.text('Go Deep'), findsOneWidget);
    });
  });
}
