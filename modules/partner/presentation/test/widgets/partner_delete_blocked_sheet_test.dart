import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_presentation/presentation.dart';

void main() {
  testWidgets('wgt_e02_u02_fr04_01: renders blocked delete copy + actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerDeleteBlockedSheet(),
        ),
      ),
    );

    expect(find.byKey(const Key('wgt_e02_u02_fr04_01')), findsOneWidget);
    expect(find.text('Không thể xóa hồ sơ'), findsOneWidget);
    expect(
      find.textContaining('đã phát sinh giao dịch'),
      findsOneWidget,
    );
    expect(
      find.textContaining('ngừng hoạt động để tránh sử dụng'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('delete_blocked_back')), findsOneWidget);
    expect(find.byKey(const Key('delete_blocked_deactivate')), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('deactivate returns deactivate; back returns dismissed', (
    tester,
  ) async {
    PartnerDeleteBlockedResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showPartnerDeleteBlockedSheet(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_blocked_deactivate')));
    await tester.pumpAndSettle();
    expect(result, PartnerDeleteBlockedResult.deactivate);

    result = null;
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_blocked_back')));
    await tester.pumpAndSettle();
    expect(result, PartnerDeleteBlockedResult.dismissed);
  });

  testWidgets('hides deactivate CTA when showDeactivateAction is false', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerDeleteBlockedSheet(showDeactivateAction: false),
        ),
      ),
    );

    expect(find.byKey(const Key('delete_blocked_deactivate')), findsNothing);
    expect(find.byKey(const Key('delete_blocked_back')), findsOneWidget);
    expect(
      find.textContaining('ngừng hoạt động để tránh sử dụng'),
      findsNothing,
    );
  });
}
