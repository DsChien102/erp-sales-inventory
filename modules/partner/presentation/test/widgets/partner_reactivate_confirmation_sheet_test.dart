import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_presentation/presentation.dart';

void main() {
  testWidgets('wgt_e02_u01_fr03_01: renders reactivate confirmation copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerReactivateConfirmationSheet(),
        ),
      ),
    );

    expect(find.byKey(const Key('wgt_e02_u01_fr03_01')), findsOneWidget);
    expect(find.text('Kích hoạt lại KH & NCC?'), findsOneWidget);
    expect(
      find.text('KH & NCC này sẽ có thể được chọn lại cho giao dịch mới.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('reactivate_cancel')), findsOneWidget);
    expect(find.byKey(const Key('reactivate_confirm')), findsOneWidget);
    expect(find.byIcon(VIcons.power.value), findsOneWidget);
  });

  testWidgets('confirm returns true; cancel returns null', (tester) async {
    bool? result = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showPartnerReactivateConfirmationSheet(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reactivate_confirm')));
    await tester.pumpAndSettle();
    expect(result, isTrue);

    result = false;
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reactivate_cancel')));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
