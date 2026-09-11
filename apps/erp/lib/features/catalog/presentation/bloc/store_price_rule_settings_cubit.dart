import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'store_price_rule_settings_state.dart';

class StorePriceRuleSettingsCubit extends Cubit<StorePriceRuleSettingsState> {
  StorePriceRuleSettingsCubit({
    required IModuleMediator moduleMediator,
    required IExecutionContext executionContext,
  }) : _moduleMediator = moduleMediator,
       _executionContext = executionContext,
       super(StorePriceRuleSettingsInitial());

  final IModuleMediator _moduleMediator;
  final IExecutionContext _executionContext;

  StorePriceRuleDto? get _currentRule {
    final current = state;
    if (current is StorePriceRuleSettingsLoaded) {
      return current.rule;
    }
    if (current is StorePriceRuleSettingsSaving) {
      return current.previousRule;
    }
    if (current is StorePriceRuleSettingsError) {
      return current.previousRule;
    }
    return null;
  }

  Future<void> loadRule() async {
    final previousRule = _currentRule;
    emit(StorePriceRuleSettingsLoading());
    try {
      final tenantId = await _executionContext.requireTenantId();
      final query = GetStorePriceRuleQuery(tenantId: tenantId);
      final rule = await _moduleMediator.executeQueryAsync<StorePriceRuleDto?>(query);
      emit(StorePriceRuleSettingsLoaded(rule: rule));
    } catch (e) {
      emit(
        StorePriceRuleSettingsError(
          message: e.toString(),
          previousRule: previousRule,
        ),
      );
    }
  }

  Future<bool> saveRule({
    required double listMarkupRatio,
    required double floorMarkupRatio,
  }) async {
    final previousRule = _currentRule;

    emit(StorePriceRuleSettingsSaving(previousRule: previousRule));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final command = SetStorePriceRuleCommand(
        tenantId: tenantId,
        name: previousRule?.name ?? 'Khung giá cửa hàng',
        listMarkupRatio: listMarkupRatio,
        floorMarkupRatio: floorMarkupRatio,
        status: previousRule?.status ?? StorePriceRuleStatus.active,
      );
      final result = await _moduleMediator.executeCommandAsync<SetStorePriceRuleResult>(
        command,
      );
      emit(StorePriceRuleSettingsLoaded(rule: result.rule));
      return true;
    } catch (e) {
      emit(
        StorePriceRuleSettingsError(
          message: e.toString(),
          previousRule: previousRule,
        ),
      );
      return false;
    }
  }
}
