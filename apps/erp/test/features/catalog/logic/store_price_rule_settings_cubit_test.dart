import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_price_repository.dart';
import 'package:erp/features/catalog/logic/store_price_rule_settings_cubit.dart';
import 'package:erp/features/catalog/logic/store_price_rule_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _MockProductPriceRepository extends Fake implements ProductPriceRepository {
  _MockProductPriceRepository({
    this.onSetStorePriceRule,
  });

  final Future<StorePriceRuleDto> Function({
    required String name,
    required double listMarkupRatio,
    required double floorMarkupRatio,
    StorePriceRuleStatus status,
  })? onSetStorePriceRule;

  @override
  Future<StorePriceRuleDto?> getStorePriceRule() async {
    return const StorePriceRuleDto(
      id: 'rule-1',
      tenantId: 'tenant-1',
      name: 'Khung giá cửa hàng',
      calculationType: StorePriceCalculationType.markup,
      listMarkupRatio: 0.3,
      floorMarkupRatio: 0.15,
      status: StorePriceRuleStatus.active,
    );
  }

  @override
  Future<StorePriceRuleDto> setStorePriceRule({
    required String name,
    required double listMarkupRatio,
    required double floorMarkupRatio,
    StorePriceRuleStatus status = StorePriceRuleStatus.active,
  }) async {
    if (onSetStorePriceRule != null) {
      return onSetStorePriceRule!(
        name: name,
        listMarkupRatio: listMarkupRatio,
        floorMarkupRatio: floorMarkupRatio,
        status: status,
      );
    }
    throw UnimplementedError();
  }
}

void main() {
  group('StorePriceRuleSettingsCubit (H16)', () {
    test('1. saveRule emits error when floorMarkupRatio > listMarkupRatio', () async {
      final repo = _MockProductPriceRepository(
        onSetStorePriceRule: ({
          required name,
          required listMarkupRatio,
          required floorMarkupRatio,
          status = StorePriceRuleStatus.active,
        }) async {
          throw const AppException(CatalogErrorCodes.floorGreaterThanList);
        },
      );

      final cubit = StorePriceRuleSettingsCubit(productPriceRepository: repo);

      final result = await cubit.saveRule(
        listMarkupRatio: 0.1,
        floorMarkupRatio: 0.2,
      );

      expect(result, isFalse);
      expect(cubit.state, isA<StorePriceRuleSettingsError>());
      final errorState = cubit.state as StorePriceRuleSettingsError;
      expect(errorState.message, 'Giá sàn không được lớn hơn giá niêm yết.');
    });

    test('2. saveRule successfully emits Loaded with new rule', () async {
      const updatedRule = StorePriceRuleDto(
        tenantId: 'tenant-1',
        id: 'rule-1',
        name: 'Khung giá cửa hàng',
        calculationType: StorePriceCalculationType.markup,
        listMarkupRatio: 0.35,
        floorMarkupRatio: 0.20,
        status: StorePriceRuleStatus.active,
      );

      final repo = _MockProductPriceRepository(
        onSetStorePriceRule: ({
          required name,
          required listMarkupRatio,
          required floorMarkupRatio,
          status = StorePriceRuleStatus.active,
        }) async {
          return updatedRule;
        },
      );

      final cubit = StorePriceRuleSettingsCubit(productPriceRepository: repo);

      final result = await cubit.saveRule(
        listMarkupRatio: 0.35,
        floorMarkupRatio: 0.20,
      );

      expect(result, isTrue);
      expect(cubit.state, isA<StorePriceRuleSettingsLoaded>());
      final loadedState = cubit.state as StorePriceRuleSettingsLoaded;
      expect(loadedState.rule, updatedRule);
    });
  });
}
