import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/inventory/presentation/patterns/k2_approval.dart';
import '../../support/inventory_test_surface.dart';

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

  group('K2Pending', () {
    testWidgets('pending_text_with_and_without_subject', (tester) async {
      await tester.pumpWidget(
        wrap(
          const K2Pending(
            approver: 'chủ cửa hàng',
            sentAt: '09:41',
            subject: 'sửa sai',
          ),
        ),
      );

      expect(
        find.text('Chờ chủ cửa hàng duyệt sửa sai · gửi 09:41'),
        findsOneWidget,
      );

      await tester.pumpWidget(
        wrap(
          const K2Pending(
            approver: 'chủ cửa hàng',
            sentAt: '09:41',
          ),
        ),
      );

      expect(
        find.text('Chờ chủ cửa hàng duyệt · gửi 09:41'),
        findsOneWidget,
      );
    });

    testWidgets('pending_lock_note', (tester) async {
      await tester.pumpWidget(
        wrap(
          const K2Pending(
            approver: 'chủ cửa hàng',
            sentAt: '09:41',
          ),
        ),
      );

      expect(
        find.text('Dữ liệu đã khoá. Tồn kho chưa thay đổi.'),
        findsOneWidget,
      );
    });
  });

  group('K2Attention', () {
    testWidgets('attention_empty_renders_nothing', (tester) async {
      await tester.pumpWidget(
        wrap(
          const K2Attention(items: []),
        ),
      );

      expect(find.text('Cần chú ý'), findsNothing);
    });

    testWidgets('attention_strips_trailing_colon', (tester) async {
      await tester.pumpWidget(
        wrap(
          const K2Attention(
            items: [
              K2AttentionItem(
                label: 'Chênh lệch tồn:',
                value: '-5 hộp',
                tone: K2AttentionTone.warning,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Chênh lệch tồn'), findsOneWidget);
      expect(find.text('Chênh lệch tồn:'), findsNothing);
      expect(find.text('-5 hộp'), findsOneWidget);
    });
  });

  group('K2Decision', () {
    testWidgets('decision_order', (tester) async {
      await tester.pumpWidget(
        wrap(
          const K2Decision(
            question: 'Duyệt điều chỉnh giảm 5 hộp thuốc?',
            maker: 'Minh Dũng',
            sentAt: '10:15',
            attention: [
              K2AttentionItem(label: 'Cảnh báo', value: 'Vượt hạn mức'),
            ],
            facts: [
              VKeyValueRow(label: 'Kho', value: 'Kho Chính'),
            ],
          ),
        ),
      );

      final titleDy = tester.getTopLeft(find.text('Cần quyết')).dy;
      final questionDy =
          tester.getTopLeft(find.text('Duyệt điều chỉnh giảm 5 hộp thuốc?')).dy;
      final makerDy = tester.getTopLeft(find.text('Minh Dũng gửi 10:15')).dy;
      final attentionDy = tester.getTopLeft(find.text('Cần chú ý')).dy;
      final factsDy = tester.getTopLeft(find.text('Kho')).dy;

      expect(titleDy, lessThan(questionDy));
      expect(questionDy, lessThan(makerDy));
      expect(makerDy, lessThan(attentionDy));
      expect(attentionDy, lessThan(factsDy));
    });
  });

  group('showK2ReasonSheet', () {
    testWidgets('reason_sheet_confirm_disabled_until_reason', (tester) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showK2ReasonSheet(
                  context,
                  title: 'Từ chối duyệt',
                ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final confirmBtnFinder = find.widgetWithText(VButton, 'Xác nhận từ chối');
      expect(confirmBtnFinder, findsOneWidget);
      final confirmBtn = tester.widget<VButton>(confirmBtnFinder);
      expect(confirmBtn.onPressed, isNull);

      await tester.enterText(find.byType(VTextField), 'Sai số lượng');
      await tester.pumpAndSettle();

      final updatedConfirmBtn = tester.widget<VButton>(confirmBtnFinder);
      expect(updatedConfirmBtn.onPressed, isNotNull);
    });

    testWidgets('reason_sheet_returns_trimmed_reason', (tester) async {
      String? result;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showK2ReasonSheet(
                    context,
                    title: 'Từ chối duyệt',
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(VTextField), '  Nhập sai lô   ');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận từ chối'));
      await tester.pumpAndSettle();

      expect(result, 'Nhập sai lô');
    });

    testWidgets('reason_sheet_cancel_returns_null', (tester) async {
      String? result = 'not-null';
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showK2ReasonSheet(
                    context,
                    title: 'Từ chối duyệt',
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('reason_sheet_is_dialog_on_web', (tester) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showK2ReasonSheet(
                  context,
                  title: 'Từ chối duyệt',
                ),
                child: const Text('Open'),
              );
            },
          ),
          size: const Size(1280, 800),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(VSheetDialog), findsOneWidget);
    });
  });
}
