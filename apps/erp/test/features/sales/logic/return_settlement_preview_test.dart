import 'package:erp/features/sales/data/models.dart';
import 'package:erp/features/sales/logic/return_settlement_preview.dart';
import 'package:flutter_test/flutter_test.dart';

ReturnExchangeOffsetCandidateDto _c(String id, String code, int outstanding) =>
    ReturnExchangeOffsetCandidateDto(
      salesOrderId: id,
      orderCode: code,
      completedAt: DateTime.utc(2026, 11, 1),
      outstandingMinor: outstanding,
      offsetAmountMinor: 0,
      overdueDays: 0,
      settlementVersion: 1,
    );

final _both = [_c('o2', 'DH-002', 2000000), _c('o3', 'DH-003', 6000000)];

List<int> _amounts(ReturnSettlementPreview p) =>
    p.offsets.map((o) => o.amountMinor).toList();

void main() {
  test('AC-01 offset 500k into DH-002', () {
    final p = planReturnSettlement(
      reduceOwnDebtMinor: 0,
      distributableMinor: 500000,
      candidates: _both,
      selectedIds: {'o2', 'o3'},
    );
    expect(_amounts(p), [500000, 0]);
    expect(p.refundMinor, 0);
    expect(p.showOffsetBlock, isTrue);
    expect(p.targetOrderIds, ['o2']);
    expect(p.offsetTotalMinor, 500000);
  });

  test('FR-04 untick DH-002 moves to DH-003', () {
    final p = planReturnSettlement(
      reduceOwnDebtMinor: 0,
      distributableMinor: 500000,
      candidates: _both,
      selectedIds: {'o3'},
    );
    expect(_amounts(p), [0, 500000]);
    expect(p.refundMinor, 0);
    expect(p.targetOrderIds, ['o3']);
  });

  test('AC-02 untick all refunds', () {
    final p = planReturnSettlement(
      reduceOwnDebtMinor: 0,
      distributableMinor: 500000,
      candidates: _both,
      selectedIds: {},
    );
    expect(_amounts(p), [0, 0]);
    expect(p.refundMinor, 500000);
    expect(p.targetOrderIds, isEmpty);
  });

  test('AC-03 own debt only hides block', () {
    final p = planReturnSettlement(
      reduceOwnDebtMinor: 600000,
      distributableMinor: 0,
      candidates: _both,
      selectedIds: {'o2'},
    );
    expect(p.reduceOwnDebtMinor, 600000);
    expect(p.refundMinor, 0);
    expect(p.showOffsetBlock, isFalse);
  });

  test('AC-02 US-03.2 offset 2tr refund 1tr', () {
    final p = planReturnSettlement(
      reduceOwnDebtMinor: 0,
      distributableMinor: 3000000,
      candidates: [_c('o2', 'DH-002', 2000000)],
      selectedIds: {'o2'},
    );
    expect(_amounts(p), [2000000]);
    expect(p.refundMinor, 1000000);
  });

  test('mixed', () {
    final p = planReturnSettlement(
      reduceOwnDebtMinor: 400000,
      distributableMinor: 2600000,
      candidates: [_c('o2', 'DH-002', 2000000)],
      selectedIds: {'o2'},
    );
    expect(p.reduceOwnDebtMinor, 400000);
    expect(_amounts(p), [2000000]);
    expect(p.refundMinor, 600000);
  });

  test('BR-27 server cap kept', () {
    final p = planReturnSettlement(
      reduceOwnDebtMinor: 2000000,
      distributableMinor: 1000000,
      candidates: _both,
      selectedIds: {'o2', 'o3'},
    );
    expect(p.reduceOwnDebtMinor, 2000000);
    expect(_amounts(p), [1000000, 0]);
    expect(p.refundMinor, 0);
  });

  test('no candidates', () {
    final p = planReturnSettlement(
      reduceOwnDebtMinor: 0,
      distributableMinor: 500000,
      candidates: const [],
      selectedIds: {},
    );
    expect(p.offsets, isEmpty);
    expect(p.refundMinor, 500000);
    expect(p.showOffsetBlock, isFalse);
  });
}
