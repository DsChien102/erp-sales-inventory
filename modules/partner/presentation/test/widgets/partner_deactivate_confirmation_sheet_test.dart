import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_presentation/presentation.dart';

void main() {
  testWidgets('wgt_e02_u01_fr05_01: renders deactivate confirmation copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerDeactivateConfirmationSheet(),
        ),
      ),
    );

    expect(find.byKey(const Key('wgt_e02_u01_fr05_01')), findsOneWidget);
    expect(find.text('Ngừng hoạt động KH & NCC?'), findsOneWidget);
    expect(
      find.textContaining('không còn được chọn cho giao dịch mới'),
      findsOneWidget,
    );
    expect(find.text('Lý do (không bắt buộc)'), findsOneWidget);
    expect(find.text('0/200'), findsOneWidget);
    expect(find.byKey(const Key('deactivate_cancel')), findsOneWidget);
    expect(find.byKey(const Key('deactivate_confirm')), findsOneWidget);
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
                result = await showPartnerDeactivateConfirmationSheet(context);
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
      find.byKey(const Key('deactivate_reason_input')),
      '  Không còn giao dịch  ',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('deactivate_confirm')));
    await tester.pumpAndSettle();
    expect(result, 'Không còn giao dịch');

    result = 'sentinel';
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deactivate_cancel')));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
