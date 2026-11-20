import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('VSwipeReveal', () {
    const rowLabel = 'Dòng hàng';

    Widget host({
      List<VSwipeSemanticAction> semanticActions = const [],
      bool disableAnimations = false,
      bool enabled = true,
      VoidCallback? onDelete,
    }) {
      return MaterialApp(
        theme: VTheme.lightTheme,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
          ),
          child: app!,
        ),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 60,
              child: VSwipeReveal(
                actionExtent: 100,
                enabled: enabled,
                semanticActions: semanticActions,
                actionsBuilder: (context, close) => SizedBox(
                  width: 100,
                  child: TextButton(
                    onPressed: () {
                      onDelete?.call();
                      close();
                    },
                    child: const Text('Xóa'),
                  ),
                ),
                child: const ColoredBox(
                  color: Colors.white,
                  child: Center(child: Text(rowLabel)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    double rowDx(WidgetTester tester) => tester.getTopLeft(find.text(rowLabel)).dx;

    testWidgets('without semanticActions hidden buttons stay in semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host());
      expect(find.bySemanticsLabel('Xóa'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('with semanticActions hidden buttons leave semantics while closed', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          semanticActions: [
            VSwipeSemanticAction(label: 'Xóa', onInvoke: () {}),
          ],
        ),
      );
      expect(find.bySemanticsLabel('Xóa'), findsNothing);
      handle.dispose();
    });

    testWidgets('hidden buttons come back once revealed', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          semanticActions: [
            VSwipeSemanticAction(label: 'Xóa', onInvoke: () {}),
          ],
        ),
      );
      await tester.drag(find.text(rowLabel), const Offset(-150, 0));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Xóa'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('card publishes custom actions that run the callback', (tester) async {
      final handle = tester.ensureSemantics();
      var deleted = 0;
      await tester.pumpWidget(
        host(
          semanticActions: [
            VSwipeSemanticAction(label: 'Chiết khấu', onInvoke: () {}),
            VSwipeSemanticAction(label: 'Xóa', onInvoke: () => deleted++),
          ],
        ),
      );

      final node = tester.getSemantics(find.text(rowLabel));
      final ids = node.getSemanticsData().customSemanticsActionIds!;
      final labels = [
        for (final id in ids) CustomSemanticsAction.getAction(id)!.label,
      ];
      expect(labels, containsAll(['Chiết khấu', 'Xóa']));

      final deleteId = ids.firstWhere(
        (id) => CustomSemanticsAction.getAction(id)!.label == 'Xóa',
      );
      node.owner!.performAction(node.id, SemanticsAction.customAction, deleteId);
      expect(deleted, 1);
      handle.dispose();
    });

    testWidgets('disabled shell publishes no custom actions', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          enabled: false,
          semanticActions: [
            VSwipeSemanticAction(label: 'Xóa', onInvoke: () {}),
          ],
        ),
      );
      final ids = tester
          .getSemantics(find.text(rowLabel))
          .getSemanticsData()
          .customSemanticsActionIds;
      expect(ids ?? const <int>[], isEmpty);
      handle.dispose();
    });

    testWidgets('slides over 200ms by default', (tester) async {
      await tester.pumpWidget(host());
      final closedDx = rowDx(tester);

      await tester.drag(find.text(rowLabel), const Offset(-70, 0));
      await tester.pump();

      // Released past the threshold; the animation has not finished yet.
      expect(rowDx(tester), greaterThan(closedDx - 100));
      await tester.pumpAndSettle();
      expect(rowDx(tester), closedDx - 100);
    });

    testWidgets('jumps open with reduced motion', (tester) async {
      await tester.pumpWidget(host(disableAnimations: true));
      final closedDx = rowDx(tester);

      await tester.drag(find.text(rowLabel), const Offset(-70, 0));
      await tester.pump();

      expect(rowDx(tester), closedDx - 100);
    });

    testWidgets('jumps closed with reduced motion', (tester) async {
      await tester.pumpWidget(host(disableAnimations: true));
      final closedDx = rowDx(tester);
      await tester.drag(find.text(rowLabel), const Offset(-150, 0));
      await tester.pump();
      expect(rowDx(tester), closedDx - 100);

      await tester.tap(find.text(rowLabel));
      await tester.pump();
      expect(rowDx(tester), closedDx);
    });
  });
}
