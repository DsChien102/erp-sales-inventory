import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_pricing_infrastructure/infrastructure.dart';

import '../../support/pricing_reenable_fixtures.dart';

void main() {
  const ruleId = '00000000-0000-4000-8000-000000000001';

  test('precheck params contain exact RPC keys and no actor', () {
    final params = PricingReenableRpcMapper.precheckParams(
      PrecheckCustomerPriceRuleReenableQuery(
        tenantId: 'tenant-1',
        ruleId: ruleId,
        expectedVersion: 4,
        businessDate: DateTime.utc(2026, 7, 16),
      ),
    );

    expect(params, {
      'p_tenant_id': 'tenant-1',
      'p_rule_id': ruleId,
      'p_expected_version': 4,
      'p_business_date': '2026-07-16',
    });
    expect(params, isNot(contains('p_actor_id')));
  });

  test('reenable params contain exact RPC keys and no actor', () {
    final params = PricingReenableRpcMapper.reenableParams(
      ReenableCustomerPriceRuleCommand(
        tenantId: 'tenant-1',
        actorId: 'user-1',
        ruleId: ruleId,
        expectedVersion: 4,
        businessDate: DateTime.utc(2026, 7, 16),
        precheckToken: reenableToken,
        acknowledgeFloorWarning: true,
      ),
    );

    expect(params, {
      'p_tenant_id': 'tenant-1',
      'p_rule_id': ruleId,
      'p_expected_version': 4,
      'p_business_date': '2026-07-16',
      'p_precheck_token': reenableToken,
      'p_acknowledge_floor_warning': true,
      'p_acknowledge_overwrite': false,
    });
    expect(params, isNot(contains('p_actor_id')));
  });

  test('precheck result parses token, version, date, and outcome', () {
    final dto = PricingReenableRpcMapper.precheckResultFromJson(
      reenablePrecheckJson(),
    );

    expect(dto.precheckToken, reenableToken);
    expect(dto.ruleVersion, 4);
    expect(dto.businessDate, DateTime.utc(2026, 7, 16));
    expect(dto.validationOutcome.outcome, 'valid');
    expect(dto.validationOutcome.listPrice?.amountMinor, 150000);
    expect(dto.validationOutcome.floorPrice?.amountMinor, 125000);
  });

  test('precheck result rejects malformed token, version, and date', () {
    expect(
      () => PricingReenableRpcMapper.precheckResultFromJson(
        reenablePrecheckJson(token: 'abc'),
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => PricingReenableRpcMapper.precheckResultFromJson(
        reenablePrecheckJson()..['rule_version'] = 0,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => PricingReenableRpcMapper.precheckResultFromJson(
        reenablePrecheckJson()..['business_date'] = 'invalid',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('precheck result rejects hidden floor with value', () {
    final json = reenablePrecheckJson();
    final validation = Map<String, dynamic>.from(
      json['validation_outcome'] as Map<String, dynamic>,
    );
    validation['floor_price_hidden'] = true;
    validation['floor_price'] = {
      'amount_minor': 125000,
      'currency_code': 'VND',
    };
    json['validation_outcome'] = validation;

    expect(
      () => PricingReenableRpcMapper.precheckResultFromJson(json),
      throwsA(isA<FormatException>()),
    );
  });

  test('reenable result maps active detail payload', () {
    final detail = PricingReenableRpcMapper.reenableResultFromJson(
      reenableDetailJson(),
    );

    expect(detail.persistedStatus, CustomerPriceRuleStatus.active);
    expect(detail.version, 5);
    expect(detail.disabledAt, isNull);
    expect(detail.disabledBy, isNull);
    expect(detail.disabledReason, isNull);
  });

  test('reenable result rejects malformed detail payload', () {
    final json = reenableDetailJson()..remove('version');
    expect(
      () => PricingReenableRpcMapper.reenableResultFromJson(json),
      throwsA(isA<FormatException>()),
    );
  });
}
