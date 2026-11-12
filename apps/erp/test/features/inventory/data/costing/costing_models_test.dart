import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CostRunView.fromJson parses example 5.1 PERIODIC correctly', () {
    final json = <String, dynamic>{
      'run_id': 'run-1',
      'code': 'GV-2611-01',
      'kind': 'MID_PERIOD',
      'period_month': '2026-11-01',
      'status': 'READY_FOR_REVIEW',
      'method': 'PERIODIC',
      'from_sequence': 0,
      'cut_off_sequence': 4,
      'cut_off_at': '2026-11-12T08:00:00Z',
      'created_at': '2026-11-12T08:00:00Z',
      'published_at': null,
      'blockers': <dynamic>[],
      'product_count': 1,
      'changed_count': 1,
      'totals': <String, dynamic>{
        'closing_value': 880000,
        'cogs_value': 770000,
        'cogs_adjust': 20000,
        'value_adjust': -20000,
        'balance_ok': true,
      },
      'alt': <String, dynamic>{
        'method': 'MOVING',
        'closing_value': 900000,
        'cogs_value': 750000,
      },
      'lines': <dynamic>[
        <String, dynamic>{
          'product_id': 'p-1',
          'name': 'Nobivac DHPPi',
          'code': 'NB-01',
          'uom': 'hộp',
          'old_official_unit_cost': null,
          'opening_qty': 0,
          'opening_value': 0,
          'inbound_qty': 150,
          'inbound_value': 1650000,
          'rebate_value': 0,
          'sale_qty': 70,
          'sale_value_recorded': 750000,
          'loss_qty': 0,
          'loss_value_recorded': 0,
          'closing_qty': 80,
          'closing_value_before': 900000,
          'moving_avg_end': 11250,
          'periodic_avg': 11000,
          'selected_unit_cost': 11000,
          'cogs_true_up': 20000,
          'loss_true_up': 0,
          'rounding_adjust': 0,
          'closing_value_after': 880000,
          'new_unit_cost': 11000,
          'line_adjust': -20000,
          'balance_diff': 0,
        },
      ],
    };

    final run = CostRunView.fromJson(json);

    expect(run.runId, 'run-1');
    expect(run.code, 'GV-2611-01');
    expect(run.kind, CostRunKind.midPeriod);
    expect(run.status, CostRunStatus.readyForReview);
    expect(run.method, CostMethod.periodic);
    expect(run.totals.cogsAdjust, 20000);
    expect(run.totals.valueAdjust, -20000);
    expect(run.totals.balanceOk, isTrue);
    expect(run.alt.method, CostMethod.moving);
    expect(run.alt.closingValue, 900000);
    expect(run.lines, hasLength(1));
    expect(run.lines[0].lineAdjust, -20000);
    expect(run.lines[0].oldOfficialUnitCost, isNull);
    expect(run.lines[0].newUnitCost, 11000);
  });
}

