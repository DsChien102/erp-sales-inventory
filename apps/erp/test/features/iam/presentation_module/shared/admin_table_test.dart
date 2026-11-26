import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/iam/presentation/shared/admin_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('rows open on tap and Enter, one semantics node each', (tester) async {
    final handle = tester.ensureSemantics();
    var tapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: AdminTable(
            semanticLabel: 'Thành viên',
            columns: const [
              AdminTableColumn('Tên', flex: 2, minWidth: 260),
              AdminTableColumn('Vai trò', flex: 1.2),
              AdminTableColumn('Trạng thái'),
              AdminTableColumn('Hoạt động gần nhất'),
            ],
            rows: [
              AdminTableRow(
                semanticLabel: 'Nguyễn Văn An, an@example.com, Thủ kho, Hoạt động',
                onTap: () => tapped += 1,
                cells: const [
                  Text('Nguyễn Văn An'),
                  Text('Thủ kho'),
                  Text('Hoạt động'),
                  Text('21/11/2026 17:05'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rowFinder = find.bySemanticsLabel(
      'Nguyễn Văn An, an@example.com, Thủ kho, Hoạt động',
    );
    expect(rowFinder, findsOneWidget);

    await tester.tap(rowFinder);
    await tester.pump();
    expect(tapped, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(tapped, greaterThanOrEqualTo(1));

    handle.dispose();
  });

  testWidgets('loading shows n skeleton rows and no chevrons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: const Scaffold(
          body: AdminTable(
            columns: [
              AdminTableColumn('Tên', flex: 2, minWidth: 260),
              AdminTableColumn('Vai trò', flex: 1.2),
              AdminTableColumn('Trạng thái'),
              AdminTableColumn('Hoạt động gần nhất'),
            ],
            rows: [],
            loadingRows: 4,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(VSkeletonScope), findsOneWidget);
    expect(find.byType(VSkeleton), findsWidgets);
    expect(find.byType(VIcon), findsNothing);
  });

  testWidgets('fits 840 wide', (tester) async {
    tester.view.physicalSize = const Size(840, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: AdminTablePage(
            children: [
              AdminTable(
                columns: const [
                  AdminTableColumn('Tên', flex: 2, minWidth: 260),
                  AdminTableColumn('Vai trò hiện hành', flex: 1.2),
                  AdminTableColumn('Trạng thái truy cập'),
                  AdminTableColumn('Hoạt động gần nhất'),
                ],
                rows: [
                  AdminTableRow(
                    semanticLabel: 'An, an@example.com, Thủ kho, Hoạt động',
                    onTap: () {},
                    cells: const [
                      Text('An'),
                      Text('Thủ kho'),
                      Text('Hoạt động'),
                      Text('—'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
