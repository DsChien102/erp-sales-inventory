import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import '../../support/inventory_test_surface.dart';

void main() {
  Widget wrap(Widget child, {Size size = const Size(390, 844)}) {
    useInventoryTestSurface(size);
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('K1 States', () {
    testWidgets('denied_has_title_next_and_exit', (tester) async {
      var exited = false;
      await tester.pumpWidget(
        wrap(
          InventoryDenied(
            what: 'nhận hàng',
            next: 'Liên hệ chủ cửa hàng để được cấp quyền.',
            onExit: () => exited = true,
          ),
        ),
      );

      expect(find.text('Bạn chưa có quyền nhận hàng'), findsOneWidget);
      expect(find.text('Liên hệ chủ cửa hàng để được cấp quyền.'), findsOneWidget);
      expect(find.text('Về Kho'), findsOneWidget);

      await tester.tap(find.text('Về Kho'));
      await tester.pumpAndSettle();
      expect(exited, isTrue);
    });

    testWidgets('stale_banner_and_action', (tester) async {
      var refreshed = false;
      await tester.pumpWidget(
        wrap(
          InventoryStale(
            title: 'Dữ liệu đã cũ',
            description: 'Tồn kho đã thay đổi trên máy khác.',
            actionLabel: 'Tải lại',
            onAction: () => refreshed = true,
          ),
        ),
      );

      expect(find.text('Dữ liệu đã cũ'), findsOneWidget);
      expect(find.text('Tồn kho đã thay đổi trên máy khác.'), findsOneWidget);
      expect(find.text('Tải lại'), findsOneWidget);

      await tester.tap(find.text('Tải lại'));
      await tester.pumpAndSettle();
      expect(refreshed, isTrue);
    });

    testWidgets('locked_has_no_button', (tester) async {
      await tester.pumpWidget(
        wrap(
          const InventoryLocked(
            title: 'Phiếu đã khoá',
            description: 'Phiếu đang chờ duyệt.',
          ),
        ),
      );

      expect(find.text('Phiếu đã khoá'), findsOneWidget);
      expect(find.text('Phiếu đang chờ duyệt.'), findsOneWidget);
      expect(find.byType(VButton), findsNothing);
    });

    testWidgets('empty_action_optional', (tester) async {
      await tester.pumpWidget(
        wrap(
          const InventoryEmpty(
            title: 'Không có dữ liệu',
            description: 'Chưa có phiếu nào ở đây.',
          ),
        ),
      );

      expect(find.text('Không có dữ liệu'), findsOneWidget);
      expect(find.byType(VButton), findsNothing);

      await tester.pumpWidget(
        wrap(
          InventoryEmpty(
            title: 'Không có dữ liệu',
            description: 'Chưa có phiếu nào ở đây.',
            actionLabel: 'Tạo phiếu mới',
            onAction: () {},
          ),
        ),
      );

      expect(find.text('Tạo phiếu mới'), findsOneWidget);
      expect(find.byType(VButton), findsOneWidget);
    });
  });

  group('K7 Layout & Table', () {
    testWidgets('k7_split_row_on_web_column_on_iphone', (tester) async {
      const mainKey = Key('main_widget');
      const asideKey = Key('aside_widget');

      // Web: 1280
      await tester.pumpWidget(
        wrap(
          const K7Split(
            main: SizedBox(key: mainKey, width: 100, height: 100),
            aside: SizedBox(key: asideKey, width: 100, height: 100),
          ),
          size: const Size(1280, 800),
        ),
      );

      final mainOffsetWeb = tester.getTopLeft(find.byKey(mainKey));
      final asideOffsetWeb = tester.getTopLeft(find.byKey(asideKey));
      // Cùng hàng dọc (dy tương đương nhau)
      expect(mainOffsetWeb.dy, equals(asideOffsetWeb.dy));
      expect(mainOffsetWeb.dx, lessThan(asideOffsetWeb.dx));

      // iPhone: 390
      await tester.pumpWidget(
        wrap(
          const K7Split(
            main: SizedBox(key: mainKey, width: 100, height: 100),
            aside: SizedBox(key: asideKey, width: 100, height: 100),
          ),
          size: const Size(390, 844),
        ),
      );

      final mainOffsetPhone = tester.getTopLeft(find.byKey(mainKey));
      final asideOffsetPhone = tester.getTopLeft(find.byKey(asideKey));
      // Xếp dọc: dy main < dy aside
      expect(mainOffsetPhone.dy, lessThan(asideOffsetPhone.dy));
    });

    testWidgets('k7_split_aside_web_only_hidden_on_iphone', (tester) async {
      const asideKey = Key('aside_web_only');

      await tester.pumpWidget(
        wrap(
          const K7Split(
            main: Text('Main'),
            aside: Text('Aside', key: asideKey),
            asideWebOnly: true,
          ),
          size: const Size(390, 844),
        ),
      );

      expect(find.byKey(asideKey), findsNothing);
    });

    testWidgets('k7_table_web_is_vtable_iphone_is_list', (tester) async {
      final columns = [
        K7Column<String>(label: 'Mã', cell: (item) => Text(item)),
      ];
      final rows = ['A1', 'A2'];

      // Web: 1280 -> uses VTable
      await tester.pumpWidget(
        wrap(
          K7Table<String>(
            columns: columns,
            rows: rows,
            mobileRow: (item) => Text('Mobile: $item'),
          ),
          size: const Size(1280, 800),
        ),
      );

      expect(find.byType(VTable), findsOneWidget);
      expect(find.text('Mobile: A1'), findsNothing);

      // iPhone: 390 -> uses mobileRow
      await tester.pumpWidget(
        wrap(
          K7Table<String>(
            columns: columns,
            rows: rows,
            mobileRow: (item) => Text('Mobile: $item'),
          ),
          size: const Size(390, 844),
        ),
      );

      expect(find.byType(VTable), findsNothing);
      expect(find.text('Mobile: A1'), findsOneWidget);
    });

    testWidgets('selected_row_highlighted', (tester) async {
      final columns = [
        K7Column<String>(label: 'Mã', cell: (item) => Text(item)),
      ];
      final rows = ['A1', 'A2'];

      await tester.pumpWidget(
        wrap(
          K7Table<String>(
            columns: columns,
            rows: rows,
            selected: 'A2',
            mobileRow: (item) => Text('Mobile: $item'),
          ),
          size: const Size(1280, 800),
        ),
      );

      final table = tester.widget<Table>(find.byType(Table));
      final colors = tester.element(find.byType(Table)).vColors;
      // Row 0 is header, Row 1 is A1, Row 2 is A2 (selected)
      expect(table.children[1].decoration, isNull);
      final selectedDecoration = table.children[2].decoration as BoxDecoration?;
      expect(selectedDecoration?.color, colors.surfaceBrand);

      final a2Semantics = tester.getSemantics(find.text('A2'));
      expect(a2Semantics.flagsCollection.isSelected.toBoolOrNull(), isTrue);
    });

    testWidgets('k7_filter_chips_single_line', (tester) async {
      final filters = [
        const K7Filter(key: 'all', label: 'Tất cả', count: 10),
        const K7Filter(key: 'pending', label: 'Chờ duyệt', count: 2),
      ];

      await tester.pumpWidget(
        wrap(
          K7FilterChips(
            items: filters,
            selected: 'all',
            onSelected: (_) {},
          ),
        ),
      );

      expect(find.byType(Wrap), findsNothing);
      final scrollViewFinder = find.byType(SingleChildScrollView);
      expect(scrollViewFinder, findsOneWidget);
      final scrollView = tester.widget<SingleChildScrollView>(scrollViewFinder);
      expect(scrollView.scrollDirection, Axis.horizontal);
    });
  });

  group('Footer', () {
    testWidgets('footer_two_short_labels_row', (tester) async {
      await tester.pumpWidget(
        wrap(
          InventoryFooter(
            actions: [
              InventoryFooterAction(label: 'Hủy', onPressed: () {}),
              InventoryFooterAction(label: 'Lưu', primary: true, onPressed: () {}),
            ],
          ),
          size: const Size(390, 844),
        ),
      );

      final cancelOffset = tester.getTopLeft(find.text('Hủy'));
      final saveOffset = tester.getTopLeft(find.text('Lưu'));
      expect(cancelOffset.dy, equals(saveOffset.dy));
    });

    testWidgets('footer_long_label_stacks_on_iphone_primary_first', (tester) async {
      await tester.pumpWidget(
        wrap(
          InventoryFooter(
            actions: [
              InventoryFooterAction(label: 'Hủy', onPressed: () {}),
              InventoryFooterAction(
                label: 'Chuyển sang xác minh', // 20 ký tự (> 17)
                primary: true,
                onPressed: () {},
              ),
            ],
          ),
          size: const Size(390, 844),
        ),
      );

      final cancelOffset = tester.getTopLeft(find.text('Hủy'));
      final verifyOffset = tester.getTopLeft(find.text('Chuyển sang xác minh'));
      // Xếp dọc, nút chính (primary) ở trên nút phụ
      expect(verifyOffset.dy, lessThan(cancelOffset.dy));
    });

    testWidgets('footer_long_label_stays_row_on_web', (tester) async {
      await tester.pumpWidget(
        wrap(
          InventoryFooter(
            actions: [
              InventoryFooterAction(label: 'Hủy', onPressed: () {}),
              InventoryFooterAction(
                label: 'Chuyển sang xác minh',
                primary: true,
                onPressed: () {},
              ),
            ],
          ),
          size: const Size(1280, 800),
        ),
      );

      final cancelOffset = tester.getTopLeft(find.text('Hủy'));
      final verifyOffset = tester.getTopLeft(find.text('Chuyển sang xác minh'));
      // Web: giữ hàng ngang
      expect(cancelOffset.dy, equals(verifyOffset.dy));
    });

    testWidgets('reason_footer_shows_reason_when_disabled_note_when_enabled', (tester) async {
      // Khi disabled (onPressed == null) -> hiện reason
      await tester.pumpWidget(
        wrap(
          const InventoryReasonFooter(
            label: 'Nhận hàng',
            onPressed: null,
            reason: 'Chưa chọn mặt hàng nào',
            note: 'Sẽ tạo phiếu nhận ngay',
          ),
        ),
      );

      expect(find.text('Chưa chọn mặt hàng nào'), findsOneWidget);
      expect(find.text('Sẽ tạo phiếu nhận ngay'), findsNothing);

      // Khi enabled (onPressed != null) -> hiện note
      await tester.pumpWidget(
        wrap(
          InventoryReasonFooter(
            label: 'Nhận hàng',
            onPressed: () {},
            reason: 'Chưa chọn mặt hàng nào',
            note: 'Sẽ tạo phiếu nhận ngay',
          ),
        ),
      );

      expect(find.text('Chưa chọn mặt hàng nào'), findsNothing);
      expect(find.text('Sẽ tạo phiếu nhận ngay'), findsOneWidget);
    });
  });
}
