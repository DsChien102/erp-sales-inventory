import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models.dart';
import '../data/product_price_repository.dart';
import 'catalog_error_messages.dart';
import 'store_price_rule_settings_state.dart';

class StorePriceRuleSettingsCubit extends Cubit<StorePriceRuleSettingsState> {
  StorePriceRuleSettingsCubit({
    required ProductPriceRepository productPriceRepository,
  })  : _productPriceRepository = productPriceRepository,
        super(StorePriceRuleSettingsInitial());

  final ProductPriceRepository _productPriceRepository;

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
      final rule = await _productPriceRepository.getStorePriceRule();
      emit(StorePriceRuleSettingsLoaded(rule: rule));
    } catch (e) {
      emit(
        StorePriceRuleSettingsError(
          message: catalogErrorMessage(e),
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
      final rule = await _productPriceRepository.setStorePriceRule(
        name: previousRule?.name ?? 'Khung giá cửa hàng',
        listMarkupRatio: listMarkupRatio,
        floorMarkupRatio: floorMarkupRatio,
        status: previousRule?.status ?? StorePriceRuleStatus.active,
      );
      emit(StorePriceRuleSettingsLoaded(rule: rule));
      return true;
    } catch (e) {
      emit(
        StorePriceRuleSettingsError(
          message: catalogErrorMessage(e),
          previousRule: previousRule,
        ),
      );
      return false;
    }
  }
}
