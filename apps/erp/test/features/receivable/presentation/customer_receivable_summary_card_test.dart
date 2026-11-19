import 'package:erp/features/receivable/data/receivable_models.dart';
import 'package:erp/features/receivable/presentation/widgets/customer_receivable_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_receivable_repository.dart';
import 'receivable_test_harness.dart';

void main() {
  Future<FakeReceivableRepository> pump(
    WidgetTester tester,
    Object result, {
    RouteLog? log,
  }) async {
    final repo = FakeReceivableRepository()..summaryResult = result;
    await pumpReceivable(
      tester,
      Scaffold(
        body: CustomerReceivableSummaryCard(
          customerId: 'c1',
          repository: repo,
          today: DateTime(2026, 11, 19),
        ),
      ),
      log: log,
    );
    return repo;
  }

  testWidgets('with debt shows amount, orders and overdue label', (tester) async {
    final handle = tester.ensureSemantics();
    final repo = await pump(
      tester,
      const CustomerReceivableSummary(outstandingMinor: 18000000, openOrderCount: 3, maxOverdueDays: 8),
    );
    expect(repo.summaryCalls, ['c1']);
    expect(find.text('Công nợ'), findsOneWidget);
    expect(find.text('Còn nợ 18.000.000 ₫ · 3 đơn'), findsOneWidget);
    expect(find.text('Quá hạn 8 ngày'), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('wgt_pt07_receivable_card'))).height, greaterThanOrEqualTo(44));
    expect(
      find.bySemanticsLabel('Công nợ, Còn nợ 18.000.000 ₫ · 3 đơn, Quá hạn 8 ngày'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('no debt shows Không còn nợ without label', (tester) async {
    await pump(
      tester,
      const CustomerReceivableSummary(outstandingMinor: 0, openOrderCount: 0, maxOverdueDays: 0),
    );
    expect(find.text('Không còn nợ'), findsOneWidget);
    expect(find.textContaining('Quá hạn'), findsNothing);
  });

  testWidgets('error hides the card without error text', (tester) async {
    await pump(tester, Exception('boom'));
    expect(find.byKey(const Key('wgt_pt07_receivable_card')), findsNothing);
    expect(find.textContaining('boom'), findsNothing);
    expect(find.text('Công nợ'), findsNothing);
  });

  testWidgets('tap opens customer receivable', (tester) async {
    final log = RouteLog();
    await pump(
      tester,
      const CustomerReceivableSummary(outstandingMinor: 1000, openOrderCount: 1, maxOverdueDays: 0),
      log: log,
    );
    await tester.tap(find.byKey(const Key('wgt_pt07_receivable_card')));
    await tester.pumpAndSettle();
    expect(log.locations, ['/more/receivables/c1']);
  });
}
