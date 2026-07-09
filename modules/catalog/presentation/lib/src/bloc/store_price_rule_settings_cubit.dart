import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'store_price_rule_settings_state.dart';

class StorePriceRuleSettingsCubit
    extends Cubit<StorePriceRuleSettingsState> {
  StorePriceRuleSettingsCubit({
    required IModuleMediator moduleMediator,
    required IExecutionContext executionContext,
  })  : _moduleMediator = moduleMediator,
        _executionContext = executionContext,
        super(StorePriceRuleSettingsInitial());

  final IModuleMediator _moduleMediator;
  final IExecutionContext _executionContext;

  Future<void> loadRule() async {
    emit(StorePriceRuleSettingsLoading());
    try {
      final tenantId = await _executionContext.requireTenantId();
      final query = GetStorePriceRuleQuery(tenantId: tenantId);
      final rule =
          await _moduleMediator.executeQueryAsync<StorePriceRuleDto?>(query);
      emit(StorePriceRuleSettingsLoaded(rule: rule));
    } catch (e) {
      emit(StorePriceRuleSettingsError(message: e.toString()));
    }
  }

  Future<void> saveRule({
    required double listMarkupRatio,
    required double floorMarkupRatio,
  }) async {
    StorePriceRuleDto? previousRule;
    if (state is StorePriceRuleSettingsLoaded) {
      previousRule = (state as StorePriceRuleSettingsLoaded).rule;
    }

    emit(StorePriceRuleSettingsSaving(previousRule: previousRule));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final command = SetStorePriceRuleCommand(
        tenantId: tenantId,
        name: 'Khung giá cửa hàng',
        listMarkupRatio: listMarkupRatio,
        floorMarkupRatio: floorMarkupRatio,
      );
      final result =
          await _moduleMediator.executeCommandAsync<SetStorePriceRuleResult>(
        command,
      );
      emit(StorePriceRuleSettingsSaved(rule: result.rule));
    } catch (e) {
      emit(StorePriceRuleSettingsError(
        message: e.toString(),
        previousRule: previousRule,
      ));
    }
  }
}
