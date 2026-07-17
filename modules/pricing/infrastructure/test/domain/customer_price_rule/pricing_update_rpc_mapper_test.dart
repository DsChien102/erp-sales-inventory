import 'package:test/test.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_pricing_infrastructure/infrastructure.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../support/pricing_update_fixtures.dart';

void main() {
  test('context params are exact date-only and actor-free', () {
    final params = PricingUpdateRpcMapper.contextParams(updateCommand());
    expect(params, {
      'p_tenant_id': 'tenant-1',
      'p_rule_id': updateRuleId,
      'p_expected_version': 3,
      'p_rule_price_minor': 95000,
      'p_effective_from': '2026-07-16',
      'p_effective_to': '2026-07-20',
    });
    expect(params, isNot(contains('p_actor_id')));
  });

  test('context mapper reconstitutes current rule and live snapshots', () {
    final context = PricingUpdateRpcMapper.contextFromJson(
      command: updateCommand(),
      json: updateContextJson(),
    );
    expect(context.currentRule.id, updateRuleId);
    expect(context.currentRule.version, 3);
    expect(context.currentRule.domainEvents, isNull);
    expect(
      context.currentRule.reviewStatus,
      CustomerPriceRuleReviewStatus.clear,
    );
    expect(context.productUnit.floorPriceMinor, 100000);
    expect(context.hasConflictingRule, isFalse);
  });

  test('update params use immutable aggregate currency and no actor', () {
    final params = PricingUpdateRpcMapper.updateParams(
      candidate: updateCandidate(),
      expectedVersion: 3,
      acknowledgeFloorWarning: true,
    );
    expect(params['p_tenant_id'], 'tenant-1');
    expect(params['p_rule_id'], updateRuleId);
    expect(params['p_expected_version'], 3);
    expect(params['p_rule_price_minor'], 95000);
    expect(params['p_note'], 'Updated note');
    expect(params, isNot(contains('p_currency_code')));
    expect(params, isNot(contains('p_actor_id')));
  });

  test('update result reuses S3 detail mapper', () {
    final result = PricingUpdateRpcMapper.updateResultFromJson(
      updateDetailJson(version: 4, amountMinor: 95000),
    );
    expect(result.id, updateRuleId);
    expect(result.version, 4);
    expect(result.price.amountMinor, 95000);
  });

  for (final code in ['STATE_CHANGED', 'INVALID_STATUS']) {
    test('error mapper preserves $code', () {
      final mapped = mapPricingRpcError(
        RpcException('{"code":"$code","message":"blocked","details":{}}'),
      );
      expect(mapped.code, code);
    });
  }
}
