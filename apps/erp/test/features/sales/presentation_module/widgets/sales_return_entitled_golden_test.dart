import 'package:erp/features/sales/data/models.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:erp/features/sales/presentation/widgets/sales_receivable_changed_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../inventory/support/inventory_test_surface.dart';
import '../../../receivable/presentation/receivable_test_harness.dart';

String _goldenPath(String name) =>
    '${repoRoot()}/docs/refactor/plans/T6/img/T6-2c/$name.png';

ReturnExchangeOffsetCandidateDto _cand(String id, String code, int out, DateTime due, int overdue) =>
    ReturnExchangeOffsetCandidateDto(
      salesOrderId: id,
      orderCode: code,
      completedAt: DateTime.utc(2026, 11, 1),
      outstandingMinor: out,
      offsetAmountMinor: 0,
      dueDate: due,
      overdueDays: overdue,
      settlementVersion: 1,
    );

final _dh2 = _cand('o2', 'DH-002', 2000000, DateTime(2026, 11, 16), 3);
final _dh3 = _cand('o3', 'DH-003', 6000000, DateTime(2026, 11, 30), 0);

ReturnExchangeValuationDto _valuation({
  required int entitled,
  int reduce = 0,
  int offset = 0,
  int refund = 0,
  List<ReturnExchangeOffsetCandidateDto> candidates = const [],
}) => ReturnExchangeValuationDto(
  returnValue: MoneyDto(amountMinor: entitled, currencyCode: 'VND'),
  exchangeValue: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
  settlementDifference: MoneyDto(amountMinor: -entitled, currencyCode: 'VND'),
  settlementPlan: ReturnExchangeSettlementPlanDto(
    currencyCode: 'VND',
    netDifferenceMinor: -entitled,
    collectAmountMinor: 0,
    refundAmountMinor: refund,
    receivableCreateAmountMinor: 0,
    receivableReverseAmountMinor: reduce,
    processedCollectMinor: 0,
    processedRefundMinor: 0,
    pendingReceivableCreateMinor: 0,
    pendingReceivableReverseMinor: 0,
    remainderCollectMinor: 0,
    remainderRefundMinor: refund,
    sourceOrderVersion: 1,
    sourceSettlementVersion: 1,
    offsetAmountMinor: offset,
    offsetCandidates: candidates,
  ),
  sourceOrderVersion: 1,
);

SalesReturnExchangeSettlementState _state(
  ReturnExchangeValuationDto v,
  Set<String> selected, {
  String order = 'DH-001',
}) => SalesReturnExchangeSettlementState(
  orderId: 'order-1',
  returnExchangeId: 'return-1',
  orderNumber: order,
  customerDisplayName: 'Anh Tuấn',
  status: SalesReturnExchangeSettlementStatus.ready,
  valuation: v,
  selectedOffsetOrderIds: selected,
);

Future<void> _capture(
  WidgetTester tester, {
  required Size size,
  required SalesReturnExchangeSettlementState state,
  required String name,
  Future<void> Function(BuildContext context)? overlay,
}) async {
  useInventoryTestSurface(size);
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      builder: (context, child) => RepaintBoundary(key: key, child: child!),
      home: Builder(
        builder: (context) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: VPageScaffold(
              title: 'Quyết toán đổi/trả',
              showBackButton: size.width < 840,
              bottomBar: Container(
                padding: const EdgeInsets.all(VSpacing.space4),
                decoration: BoxDecoration(
                  color: context.vColors.surface,
                  border: Border(top: BorderSide(color: context.vColors.borderDefault)),
                ),
                child: VButton(
                  label: 'Xác nhận đổi/trả',
                  variant: VButtonVariant.primary,
                  tone: VComponentTone.success,
                  size: VButtonSize.large,
                  fullWidth: true,
                  onPressed: () {},
                ),
              ),
              body: SalesReturnExchangeSettlementBody(
                state: state,
                today: DateTime(2026, 11, 19),
                onToggleOffset: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  if (overlay != null) {
    final ctx = tester.element(find.byType(VPageScaffold));
    overlay(ctx);
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }
  await expectLater(find.byKey(key), matchesGoldenFile(_goldenPath(name)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadInterFont);

  final base = _valuation(entitled: 500000, offset: 500000, candidates: [_dh2, _dh3]);
  final cases = <String, SalesReturnExchangeSettlementState>{
    'all-selected': _state(base, {'o2', 'o3'}),
    'one-unchecked': _state(base, {'o3'}),
    'none-selected': _state(base, {}),
    'mixed': _state(
      _valuation(entitled: 3000000, reduce: 400000, offset: 2000000, refund: 600000, candidates: [_dh2]),
      {'o2'},
      order: 'DH-010',
    ),
    'source-has-debt': _state(
      _valuation(entitled: 600000, reduce: 600000, candidates: [_dh2, _dh3]),
      {'o2', 'o3'},
      order: 'DH-010',
    ),
    'no-other-debt': _state(_valuation(entitled: 500000, refund: 500000), {}),
  };

  for (final entry in cases.entries) {
    for (final size in const [Size(390, 844), Size(1280, 800)]) {
      testWidgets('SG-13 ${entry.key} ${size.width.toInt()}', (tester) async {
        await _capture(
          tester,
          size: size,
          state: entry.value,
          name: 'flutter-SG-13-${entry.key}-${size.width.toInt()}',
        );
      });
    }
  }

  for (final size in const [Size(390, 844), Size(1280, 800)]) {
    testWidgets('SG-13 confirm ${size.width.toInt()}', (tester) async {
      await _capture(
        tester,
        size: size,
        state: cases['all-selected']!,
        name: 'flutter-SG-13-confirm-${size.width.toInt()}',
        overlay: (context) => showSalesReturnConfirmSettlementSheet(
          context,
          vm: const SalesReturnExchangeSettlementVm(
            returnExchangeId: 'r',
            currencyCode: 'VND',
            netDifferenceMinor: -500000,
            storeRefundMinor: 0,
            customerCollectMinor: 0,
            receivableCreateMinor: 0,
            receivableReverseMinor: 0,
            sourceOrderVersion: 1,
            sourceSettlementVersion: 1,
          ),
          settlementLines: const ['Cấn trừ 500.000 ₫ vào đơn DH-002'],
        ),
      );
    });

    testWidgets('SG-13 stale ${size.width.toInt()}', (tester) async {
      await _capture(
        tester,
        size: size,
        state: cases['all-selected']!,
        name: 'flutter-SG-13-stale-${size.width.toInt()}',
        overlay: (context) => showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const SalesReceivableChangedDialog(
            title: 'Công nợ của khách vừa thay đổi. Hãy tải lại quyết toán.',
          ),
        ),
      );
    });
  }
}
