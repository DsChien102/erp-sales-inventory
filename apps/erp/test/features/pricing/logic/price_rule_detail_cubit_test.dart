import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/data/pricing_errors.dart';
import 'package:erp/features/pricing/presentation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pricing_e2e_harness.dart';

void main() {
  test('detail_maps_no_permission_not_found_error', () async {
    final noPermissionCubit = PriceRuleDetailCubit(
      repository: _ErrorDetailRepository(PricingErrorCodes.noPermission),
    );
    await noPermissionCubit.loadDetail(ruleId: 'fake-rule-1');
    expect(noPermissionCubit.state, isA<PriceRuleDetailNoPermission>());
    await noPermissionCubit.close();

    final notFoundCubit = PriceRuleDetailCubit(
      repository: FakeCustomerPriceRuleRepository(
        detailScenario: FakePricingScenario.ruleDetailNotFound,
      ),
    );
    await notFoundCubit.loadDetail(ruleId: 'fake-rule-1');
    expect(notFoundCubit.state, isA<PriceRuleDetailNotFound>());
    await notFoundCubit.close();

    final systemErrorCubit = PriceRuleDetailCubit(
      repository: _ErrorDetailRepository(PricingErrorCodes.systemError),
    );
    await systemErrorCubit.loadDetail(ruleId: 'fake-rule-1');
    expect(
      systemErrorCubit.state,
      isA<PriceRuleDetailError>().having(
        (s) => s.message,
        'message',
        'Không thể tải chi tiết. Vui lòng thử lại.',
      ),
    );
    await systemErrorCubit.close();
  });

  test('detail_shows_rule_when_history_fails', () async {
    final cubit = PriceRuleDetailCubit(
      repository: FakeCustomerPriceRuleRepository(
        detailScenario: FakePricingScenario.ruleDetailActive,
        historyScenario: FakePricingScenario.historySystemError,
      ),
    );

    await cubit.loadDetail(ruleId: 'fake-rule-1');

    expect(cubit.state, isA<PriceRuleDetailLoaded>());
    final loaded = cubit.state as PriceRuleDetailLoaded;
    expect(loaded.rule.id, 'fake-rule-1');
    expect(loaded.recentActivities, isEmpty);
    await cubit.close();
  });

  test('disable_error_restores_previous_and_sets_message', () async {
    final cubit = PriceRuleDetailCubit(
      repository: FakeCustomerPriceRuleRepository(
        detailScenario: FakePricingScenario.ruleDetailActive,
        disableScenario: FakePricingScenario.disableRuleStateChanged,
        historyScenario: FakePricingScenario.historyEmptyLegacy,
      ),
    );

    await cubit.loadDetail(ruleId: 'fake-rule-1');
    final previous = cubit.state as PriceRuleDetailLoaded;

    final result = await cubit.disableRule(
      ruleId: previous.rule.id,
      expectedVersion: previous.rule.version,
    );

    expect(result, isNull);
    expect(cubit.state, isA<PriceRuleDetailLoaded>());
    expect((cubit.state as PriceRuleDetailLoaded).rule.id, previous.rule.id);
    expect(
      cubit.actionErrorMessage,
      'Dữ liệu đã thay đổi. Vui lòng tải lại và thử lại.',
    );
    await cubit.close();
  });

  test('reenable_passes_acknowledge_overwrite', () async {
    final repo = FakeCustomerPriceRuleRepository(
      detailScenario: FakePricingScenario.ruleDetailDisabled,
      reenableScenario: FakePricingScenario.reenableOk,
      historyScenario: FakePricingScenario.historyEmptyLegacy,
    );
    final cubit = PriceRuleDetailCubit(repository: repo);
    await cubit.loadDetail(ruleId: 'fake-rule-1');
    final rule = (cubit.state as PriceRuleDetailLoaded).rule;

    final result = await cubit.reenableRule(
      ruleId: rule.id,
      expectedVersion: rule.version,
      acknowledgeFloorWarning: true,
      precheckToken: 'tok-1',
    );

    expect(result, isNotNull);
    final reenableCall = repo.calls.singleWhere((c) => c.method == 'reenable');
    expect(reenableCall.args['acknowledgeOverwrite'], isTrue);
    expect(reenableCall.args['acknowledgeFloorWarning'], isTrue);
    expect(reenableCall.args['precheckToken'], 'tok-1');
    await cubit.close();
  });
}

final class _ErrorDetailRepository extends FakeCustomerPriceRuleRepository {
  _ErrorDetailRepository(this.code);

  final String code;

  @override
  Future<CustomerPriceRuleDetailDto> getDetail({
    required String ruleId,
    required DateTime businessDate,
  }) async {
    throw AppException(code);
  }
}
