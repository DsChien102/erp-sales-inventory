import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/k6_task_list.dart';
import '../../support/inventory_test_surface.dart';

class _TestTask {
  const _TestTask({
    required this.id,
    required this.title,
    required this.statusLabel,
    this.disabled = false,
  });

  final String id;
  final String title;
  final String statusLabel;
  final bool disabled;
  final VComponentTone statusTone = VComponentTone.warning;
}

void main() {
  Widget wrap(Widget child, {Size size = const Size(390, 844)}) {
    useInventoryTestSurface(size);
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  final sampleColumns = [
    K7Column<_TestTask>(
      label: 'Phiếu',
      cell: (t) => Text(t.title),
    ),
    K7Column<_TestTask>(
      label: 'Trạng thái',
      cell: (t) => VBadge(label: t.statusLabel, tone: t.statusTone),
    ),
  ];

  const emptyState = InventoryEmpty(
    title: 'Không có phiếu',
    description: 'Danh sách rỗng.',
  );

  const filterEmptyState = InventoryEmpty(
    title: 'Không tìm thấy kết quả',
    description: 'Thử đổi bộ lọc.',
  );

  group('K6TaskList', () {
    testWidgets('total_zero_shows_empty', (tester) async {
      await tester.pumpWidget(
        wrap(
          K6TaskList<_TestTask>(
            columns: sampleColumns,
            rows: const [],
            total: 0,
            title: (t) => t.title,
            status: (t) => K6Status(label: t.statusLabel, tone: t.statusTone),
            onOpen: (_) {},
            empty: emptyState,
            filterEmpty: filterEmptyState,
          ),
        ),
      );

      expect(find.text('Không có phiếu'), findsOneWidget);
      expect(find.text('Không tìm thấy kết quả'), findsNothing);
    });

    testWidgets('filtered_empty_shows_filter_empty', (tester) async {
      await tester.pumpWidget(
        wrap(
          K6TaskList<_TestTask>(
            columns: sampleColumns,
            rows: const [],
            total: 5,
            title: (t) => t.title,
            status: (t) => K6Status(label: t.statusLabel, tone: t.statusTone),
            onOpen: (_) {},
            empty: emptyState,
            filterEmpty: filterEmptyState,
          ),
        ),
      );

      expect(find.text('Không tìm thấy kết quả'), findsOneWidget);
      expect(find.text('Không có phiếu'), findsNothing);
    });

    testWidgets('tap_row_opens / disabled_row_does_not_open', (tester) async {
      _TestTask? opened;
      final tasks = [
        const _TestTask(
          id: '1',
          title: 'PN-01',
          statusLabel: 'Chờ duyệt',
        ),
        const _TestTask(
          id: '2',
          title: 'PN-02',
          statusLabel: 'Đã khoá',
          disabled: true,
        ),
      ];

      await tester.pumpWidget(
        wrap(
          K6TaskList<_TestTask>(
            columns: sampleColumns,
            rows: tasks,
            total: 2,
            title: (t) => t.title,
            status: (t) => K6Status(label: t.statusLabel, tone: t.statusTone),
            isDisabled: (t) => t.disabled,
            onOpen: (t) => opened = t,
            empty: emptyState,
            filterEmpty: filterEmptyState,
          ),
        ),
      );

      // Tap enabled row
      await tester.tap(find.text('PN-01'));
      await tester.pumpAndSettle();
      expect(opened?.id, '1');

      // Tap disabled row
      opened = null;
      await tester.tap(find.text('PN-02'));
      await tester.pumpAndSettle();
      expect(opened, isNull);
    });

    testWidgets('web_uses_table_iphone_uses_rows', (tester) async {
      final tasks = [
        const _TestTask(
          id: '1',
          title: 'PN-01',
          statusLabel: 'Chờ duyệt',
        ),
      ];

      // Web: 1280 -> VTable
      await tester.pumpWidget(
        wrap(
          K6TaskList<_TestTask>(
            columns: sampleColumns,
            rows: tasks,
            total: 1,
            title: (t) => t.title,
            status: (t) => K6Status(label: t.statusLabel, tone: t.statusTone),
            onOpen: (_) {},
            empty: emptyState,
            filterEmpty: filterEmptyState,
          ),
          size: const Size(1280, 800),
        ),
      );

      expect(find.byType(VTable), findsOneWidget);

      // iPhone: 390 -> K6TaskRow
      await tester.pumpWidget(
        wrap(
          K6TaskList<_TestTask>(
            columns: sampleColumns,
            rows: tasks,
            total: 1,
            title: (t) => t.title,
            status: (t) => K6Status(label: t.statusLabel, tone: t.statusTone),
            onOpen: (_) {},
            empty: emptyState,
            filterEmpty: filterEmptyState,
          ),
          size: const Size(390, 844),
        ),
      );

      expect(find.byType(VTable), findsNothing);
      expect(find.byType(K6TaskRow<_TestTask>), findsOneWidget);
    });

    testWidgets('long_title_moves_badge_below', (tester) async {
      const longTitle = 'Phiếu nhận hàng nhập nhanh PN-260905-02 · Minh Dũng';
      final tasks = [
        const _TestTask(
          id: '1',
          title: longTitle,
          statusLabel: 'Chờ duyệt',
        ),
      ];

      await tester.pumpWidget(
        wrap(
          K6TaskList<_TestTask>(
            columns: sampleColumns,
            rows: tasks,
            total: 1,
            title: (t) => t.title,
            status: (t) => K6Status(label: t.statusLabel, tone: t.statusTone),
            onOpen: (_) {},
            empty: emptyState,
            filterEmpty: filterEmptyState,
          ),
          size: const Size(390, 844),
        ),
      );

      final titleBottom = tester.getBottomLeft(find.text(longTitle)).dy;
      final badgeTop = tester.getTopLeft(find.byType(VBadge)).dy;

      // dy của badge > dy cuối của tiêu đề (badge ở dưới tiêu đề)
      expect(badgeTop, greaterThan(titleBottom - 2));
    });

    testWidgets('short_title_badge_right', (tester) async {
      const shortTitle = 'PN-01';
      final tasks = [
        const _TestTask(
          id: '1',
          title: shortTitle,
          statusLabel: 'Chờ duyệt',
        ),
      ];

      await tester.pumpWidget(
        wrap(
          K6TaskList<_TestTask>(
            columns: sampleColumns,
            rows: tasks,
            total: 1,
            title: (t) => t.title,
            status: (t) => K6Status(label: t.statusLabel, tone: t.statusTone),
            onOpen: (_) {},
            empty: emptyState,
            filterEmpty: filterEmptyState,
          ),
          size: const Size(390, 844),
        ),
      );

      final titleRight = tester.getTopRight(find.text(shortTitle)).dx;
      final badgeLeft = tester.getTopLeft(find.byType(VBadge)).dx;

      // Badge ở cột phải: badgeLeft > titleRight
      expect(badgeLeft, greaterThan(titleRight));
    });
    // R1-4: tiêu đề vừa một dòng ở cỡ chữ 1.0 nhưng gãy ở 1.5 ⇒ badge xuống dưới.
    for (final scale in const [1.0, 1.5]) {
      testWidgets('long_title_moves_badge_below_large_text x$scale', (tester) async {
        const title = 'PN-260905-02';
        final tasks = [
          const _TestTask(id: '1', title: title, statusLabel: 'Chờ duyệt'),
        ];

        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                ),
                child: K6TaskList<_TestTask>(
                  columns: sampleColumns,
                  rows: tasks,
                  total: 1,
                  title: (t) => t.title,
                  status: (t) =>
                      K6Status(label: t.statusLabel, tone: t.statusTone),
                  onOpen: (_) {},
                  empty: emptyState,
                  filterEmpty: filterEmptyState,
                ),
              ),
            ),
            size: const Size(390, 844),
          ),
        );

        expect(tester.takeException(), isNull);
        final titleBottom = tester.getBottomLeft(find.text(title)).dy;
        final badgeTop = tester.getTopLeft(find.byType(VBadge)).dy;
        if (scale == 1.0) {
          expect(badgeTop, lessThan(titleBottom)); // cột phải
        } else {
          expect(badgeTop, greaterThanOrEqualTo(titleBottom)); // dưới tiêu đề
        }
      });
    }
    testWidgets('search_shows_initial_value', (tester) async {
      await tester.pumpWidget(
        wrap(
          K6TaskList<_TestTask>(
            search: K6Search(value: 'PN-26', hint: 'Tìm phiếu', onChanged: (_) {}),
            columns: sampleColumns,
            rows: const [
              _TestTask(id: '1', title: 'PN-260905-02', statusLabel: 'Chờ duyệt'),
            ],
            total: 1,
            title: (t) => t.title,
            status: (t) => K6Status(label: t.statusLabel, tone: t.statusTone),
            onOpen: (_) {},
            empty: emptyState,
            filterEmpty: filterEmptyState,
          ),
        ),
      );

      expect(find.text('PN-26'), findsOneWidget);
    });

    testWidgets('below_rendered_under_subtitle', (tester) async {
      await tester.pumpWidget(
        wrap(
          K6TaskList<_TestTask>(
            columns: sampleColumns,
            rows: const [
              _TestTask(id: '1', title: 'PN-01', statusLabel: 'Chờ duyệt'),
            ],
            total: 1,
            title: (t) => t.title,
            subtitle: (_) => 'NCC A · Chiết khấu đạt mốc',
            below: (_) => const Text('1.000 / 1.000 hộp'),
            status: (t) => K6Status(label: t.statusLabel, tone: t.statusTone),
            onOpen: (_) {},
            empty: emptyState,
            filterEmpty: filterEmptyState,
          ),
          size: const Size(390, 844),
        ),
      );

      final subtitleBottom =
          tester.getBottomLeft(find.text('NCC A · Chiết khấu đạt mốc')).dy;
      final belowTop = tester.getTopLeft(find.text('1.000 / 1.000 hộp')).dy;
      expect(belowTop, greaterThanOrEqualTo(subtitleBottom));
    });
  });
}
