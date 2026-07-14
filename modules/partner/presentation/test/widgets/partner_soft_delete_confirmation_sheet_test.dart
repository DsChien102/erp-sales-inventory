import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_presentation/presentation.dart';

void main() {
  testWidgets('wgt_e02_u02_fr05_01: renders soft delete confirmation copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerSoftDeleteConfirmationSheet(),
        ),
      ),
    );

    expect(find.byKey(const Key('wgt_e02_u02_fr05_01')), findsOneWidget);
    expect(find.text('Xóa hồ sơ KH & NCC?'), findsOneWidget);
    expect(
      find.textContaining('xóa khỏi danh sách làm việc'),
      findsOneWidget,
    );
    expect(
      find.text('Thao tác này không xóa giao dịch hoặc chứng từ đã phát sinh.'),
      findsOneWidget,
    );
    expect(find.text('Lý do (không bắt buộc)'), findsOneWidget);
    expect(find.text('0/200'), findsOneWidget);
    expect(find.byKey(const Key('soft_delete_cancel')), findsOneWidget);
    expect(find.byKey(const Key('soft_delete_confirm')), findsOneWidget);
    expect(find.byKey(const Key('soft_delete_close')), findsOneWidget);
  });

  testWidgets('confirm returns trimmed reason; cancel returns null', (
    tester,
  ) async {
    String? result = 'sentinel';

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showPartnerSoftDeleteConfirmationSheet(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('soft_delete_reason_input')),
      '  Tạo nhầm  ',
    );
    await tester.tap(find.byKey(const Key('soft_delete_confirm')));
    await tester.pumpAndSettle();
    expect(result, 'Tạo nhầm');

    result = 'sentinel';
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('soft_delete_cancel')));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
