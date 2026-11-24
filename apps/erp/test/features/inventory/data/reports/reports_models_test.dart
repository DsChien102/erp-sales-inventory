import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stock_report_from_json_masked_null_money', () {
    final r = StockReport.fromJson({
      'from': '2026-11-01',
      'to': '2026-11-13',
      'as_of': '2026-11-13T03:20:00Z',
      'show_available': true,
      'financial_masked': true,
      'rows': [
        {
          'product_id': 'p1',
          'name': 'Vắc xin',
          'code': 'VX',
          'uom': 'hộp',
          'opening_qty': 122,
          'in_qty': 10,
          'out_qty': 12,
          'closing_qty': 120,
          'available': 118,
          'closing_value': null,
        },
      ],
      'total_closing_value': null,
    });
    expect(r.financialMasked, isTrue);
    expect(r.rows.single.closingValue, isNull);
    expect(r.rows.single.available, 118);
    expect(r.totalClosingValue, isNull);
    expect(r.from, DateTime(2026, 11, 1));
  });

  test('stock_card_from_json', () {
    final c = StockCard.fromJson({
      'product': {
        'product_id': 'p1',
        'name': 'Vắc xin',
        'code': 'VX',
        'uom': 'hộp',
        'is_lot_tracked': true,
      },
      'from': '2026-11-01',
      'to': '2026-11-13',
      'as_of': '2026-11-13T03:20:00Z',
      'financial_masked': false,
      'lots': [
        {'lot_id': 'l1', 'lot_code': 'A', 'closing_qty': 9},
      ],
      'summary': {
        'opening_qty': 0,
        'in_qty': 19,
        'out_qty': 6,
        'closing_qty': 13,
      },
      'closing_value': 1300000,
      'rows': [
        {
          'movement_id': 'm1',
          'business_date': '2026-11-02',
          'recorded_at': '2026-11-02T01:00:00Z',
          'movement_kind': 'RECEIPT',
          'reason': null,
          'intent_type': 'GOODS_RECEIPT',
          'doc_code': 'PN-1',
          'lot_code': 'A',
          'quantity_delta': 10,
          'balance_after': 10,
          'actor_name': 'Chủ',
        },
      ],
    });
    expect(c.product.isLotTracked, isTrue);
    expect(c.lots.single.closingQty, 9);
    expect(c.summary.closingQty, 13);
    expect(c.closingValue, 1300000);
    expect(c.rows.single.lotCode, 'A');
    expect(c.rows.single.reason, isNull);
  });

  test('movement_source_route', () {
    expect(
      MovementSource.fromJson({
        'kind': 'RECEIPT',
        'doc_code': 'PN-1',
        'target': {'receipt_id': 'r1'},
      }).route,
      '/warehouse/receipts/r1',
    );
    expect(
      MovementSource.fromJson({
        'kind': 'ORDER',
        'doc_code': 'DH-1',
        'target': {'order_id': 'o1'},
      }).route,
      '/sales/orders/o1',
    );
    expect(
      MovementSource.fromJson({
        'kind': 'CANCELLATION',
        'doc_code': 'DH-1',
        'target': {'order_id': 'o1'},
      }).route,
      '/sales/orders/o1',
    );
    expect(
      MovementSource.fromJson({
        'kind': 'RETURN_EXCHANGE',
        'doc_code': 'DH-1',
        'target': {'order_id': 'o1', 'return_id': 'x1'},
      }).route,
      '/sales/orders/o1/returns/x1/detail',
    );
    expect(
      MovementSource.fromJson({
        'kind': 'STOCKTAKE',
        'doc_code': 'KK-1',
        'target': null,
      }).route,
      isNull,
    );
    expect(
      MovementSource.fromJson({'kind': 'OTHER', 'doc_code': '', 'target': null})
          .route,
      isNull,
    );
  });

  test('movement_detail_from_json_masked', () {
    final m = MovementDetail.fromJson({
      'movement_id': 'm1',
      'product': {
        'product_id': 'p1',
        'name': 'Vắc xin',
        'code': 'VX',
        'uom': 'hộp',
        'is_lot_tracked': false,
      },
      'lot_code': null,
      'movement_kind': 'RECEIPT',
      'reason': null,
      'intent_type': 'GOODS_RECEIPT',
      'quantity_delta': 20,
      'before_qty': 28,
      'after_qty': 48,
      'business_date': '2026-09-04',
      'recorded_at': '2026-09-04T01:00:00Z',
      'actor_name': 'Chủ',
      'value_amount': null,
      'source': {
        'kind': 'RECEIPT',
        'doc_code': 'PN-260904-08',
        'target': {'receipt_id': 'r1'},
      },
    });
    expect(m.valueAmount, isNull);
    expect(m.beforeQty + m.quantityDelta, m.afterQty);
    expect(m.source.docCode, 'PN-260904-08');
  });

  test('gross_profit_from_json', () {
    final g = GrossProfitByProduct.fromJson({
      'from': '2026-11-01',
      'to': '2026-11-13',
      'as_of': '2026-11-13T03:20:00Z',
      'mode': 'PRODUCT',
      'rows': [
        {
          'product_id': 'p1',
          'name': 'Amox',
          'code': 'AM',
          'uom': 'hộp',
          'revenue_vnd': 750000,
          'deduction_vnd': 600000,
          'net_revenue_vnd': 150000,
          'cogs_at_sale_vnd': 100000,
          'cogs_adjust_vnd': 0,
          'rebate_vnd': 0,
          'cogs_after_vnd': 100000,
          'gross_profit_vnd': 50000,
          'margin_pct': 33.3,
        },
      ],
      'loss_vnd': 100000,
      'totals': {
        'revenue': 750000,
        'deduction': 600000,
        'net_revenue': 150000,
        'cogs_at_sale': 100000,
        'cogs_adjust': 0,
        'rebate': 0,
        'cogs_after': 100000,
        'gross_profit': 50000,
        'margin_pct': null,
        'loss': 100000,
        'profit_after_loss': -50000,
      },
    });
    expect(g.rows.single.marginPct, 33.3);
    expect(g.totals.marginPct, isNull);
    expect(g.totals.profitAfterLoss, -50000);
    expect(g.lossVnd, 100000);

    final o = GrossProfitByOrder.fromJson({
      'from': '2026-11-01',
      'to': '2026-11-13',
      'as_of': '2026-11-13T03:20:00Z',
      'mode': 'ORDER',
      'rows': [
        {
          'order_id': 'o1',
          'order_code': 'DH-1',
          'completed_on': '2026-11-02',
          'revenue_vnd': 160000,
          'cogs_vnd': 100000,
          'gross_profit_vnd': 60000,
          'margin_pct': 37.5,
          'has_provisional': true,
        },
      ],
      'totals': {
        'revenue': 160000,
        'cogs': 100000,
        'gross_profit': 60000,
        'margin_pct': 37.5,
      },
    });
    expect(o.rows.single.hasProvisional, isTrue);
    expect(o.rows.single.completedOn, DateTime(2026, 11, 2));
  });

  test('supplier_purchase_from_json', () {
    final s = SupplierPurchaseReport.fromJson({
      'from': '2026-11-01',
      'to': '2026-11-13',
      'as_of': '2026-11-13T03:20:00Z',
      'suppliers': [
        {
          'supplier_id': 's1',
          'name': 'Cty A',
          'is_system': false,
          'receipt_count': 3,
          'purchase_vnd': 1000,
          'freight_vnd': 50,
          'trade_discount_vnd': 20,
          'landed_vnd': 1030,
          'rebate_vnd': 0,
          'products': [
            {
              'product_id': 'p1',
              'name': 'X',
              'code': 'X1',
              'uom': 'hộp',
              'paid_qty': 10,
              'free_qty': 1,
              'purchase_vnd': 1000,
              'landed_vnd': 1030,
              'avg_landed_unit_cost': '93.6364',
            },
          ],
        },
      ],
      'totals': {
        'purchase': 1000,
        'freight': 50,
        'trade_discount': 20,
        'landed': 1030,
        'rebate': 0,
      },
    });
    expect(s.suppliers.single.products.single.avgLandedUnitCost, 93.6364);
    expect(s.suppliers.single.receiptCount, 3);
    expect(s.totals.landed, 1030);
  });
}
