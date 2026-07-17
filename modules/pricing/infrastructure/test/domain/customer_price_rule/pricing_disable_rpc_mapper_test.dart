import 'package:test/test.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_pricing_infrastructure/infrastructure.dart';

import '../../support/pricing_disable_fixtures.dart';

void main() {
  test('disable params contain exact RPC keys and no actor', () {
    final params = PricingDisableRpcMapper.params(
      tenantId: 'tenant-1',
      ruleId: 'rule-1',
      expectedVersion: 3,
      reason: 'Kết thúc thỏa thuận',
    );

    expect(params, {
      'p_tenant_id': 'tenant-1',
      'p_rule_id': 'rule-1',
      'p_expected_version': 3,
      'p_reason': 'Kết thúc thỏa thuận',
    });
    expect(params, isNot(contains('p_actor_id')));
  });

  test('disable result maps lifecycle audit metadata', () {
    final detail = PricingDisableRpcMapper.resultFromJson(disableDetailJson());
    expect(detail.persistedStatus, CustomerPriceRuleStatus.disabled);
    expect(detail.version, 4);
    expect(detail.disabledAt, DateTime.utc(2026, 7, 16, 9));
    expect(detail.disabledBy, 'context-user');
    expect(detail.disabledReason, 'Kết thúc thỏa thuận');
  });

  test('disabled payload without actor/time is malformed', () {
    final json = disableDetailJson()..remove('disabled_by');
    expect(
      () => PricingDisableRpcMapper.resultFromJson(json),
      throwsA(isA<FormatException>()),
    );
  });
}
