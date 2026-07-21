import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'price_rule_detail_state.dart';

/// Cubit chi tiết giá riêng (S3) + disable (S6) + reenable (S7).
///
/// SG-05: reenable bỏ qua duplicate_active_rule; nếu trùng tắt giá cũ, bật giá này.
final class PriceRuleDetailCubit extends Cubit<PriceRuleDetailState> {
  PriceRuleDetailCubit({
    required IPricingModule pricingModule,
    required IExecutionContext executionContext,
  }) : _pricingModule = pricingModule,
       _executionContext = executionContext,
       super(const PriceRuleDetailInitial());

  final IPricingModule _pricingModule;
  final IExecutionContext _executionContext;

  Future<void> loadDetail({
    required String ruleId,
  }) async {
    emit(const PriceRuleDetailLoading());
    try {
      final tenantId = await _executionContext.requireTenantId();
      final result = await _pricingModule.executeQueryAsync(
        GetCustomerPriceRuleDetailQuery(
          tenantId: tenantId,
          ruleId: ruleId,
          businessDate: DateTime.now().toUtc(),
        ),
      );

      List<CustomerPriceRuleActivityDto> recentActivities = const [];
      try {
        final history = await _pricingModule
            .executeQueryAsync<CursorPageDto<CustomerPriceRuleActivityDto>>(
          GetCustomerPriceRuleHistoryQuery(
            tenantId: tenantId,
            ruleId: ruleId,
            limit: 3,
          ),
        );
        recentActivities = history.items;
      } catch (_) {
        // History load failed (no permission, not supported, etc.)
        // — still show detail, hide history section.
      }

      emit(PriceRuleDetailLoaded(
        rule: result,
        recentActivities: recentActivities,
      ));
    } on PricingBlockedException catch (e) {
      if (e.code == PricingBlockedCodes.noPermission) {
        emit(const PriceRuleDetailNoPermission());
      } else if (e.code == PricingBlockedCodes.notFound) {
        emit(const PriceRuleDetailNotFound());
      } else {
        emit(PriceRuleDetailError(message: e.code));
      }
    } catch (error) {
      emit(PriceRuleDetailError(message: error.toString()));
    }
  }

  /// S6 — Tắt giá riêng.
  Future<CustomerPriceRuleDetailDto?> disableRule({
    required String ruleId,
    required int expectedVersion,
    String? reason,
  }) async {
    try {
      final result = await _pricingModule.executeCommandAsync(
        DisableCustomerPriceRuleCommand(
          ruleId: ruleId,
          expectedVersion: expectedVersion,
          reason: reason,
        ),
      );
      emit(PriceRuleDetailLoaded(
        rule: result,
        recentActivities: _currentRecentActivities,
      ));
      await _refreshRecentHistory(ruleId: ruleId, rule: result);
      return result;
    } on PricingBlockedException catch (e) {
      emit(PriceRuleDetailError(message: e.code));
      return null;
    } catch (error) {
      emit(PriceRuleDetailError(message: error.toString()));
      return null;
    }
  }

  /// S7 — Bật lại giá riêng.
  ///
  /// SG-05: Không precheck duplicate (bỏ D-06). Gọi trực tiếp
  /// [ReenableCustomerPriceRuleCommand]; nếu có giá riêng khác trùng,
  /// module tắt giá đó và bật giá này.
  Future<CustomerPriceRuleDetailDto?> reenableRule({
    required String ruleId,
    required int expectedVersion,
    bool acknowledgeFloorWarning = false,
    String? precheckToken,
  }) async {
    try {
      final result = await _pricingModule.executeCommandAsync(
        ReenableCustomerPriceRuleCommand(
          ruleId: ruleId,
          expectedVersion: expectedVersion,
          businessDate: DateTime.now().toUtc(),
          acknowledgeFloorWarning: acknowledgeFloorWarning,
          precheckToken: precheckToken,
        ),
      );
      emit(PriceRuleDetailLoaded(
        rule: result,
        recentActivities: _currentRecentActivities,
      ));
      await _refreshRecentHistory(ruleId: ruleId, rule: result);
      return result;
    } on PricingBlockedException catch (e) {
      emit(PriceRuleDetailError(message: e.code));
      return null;
    } catch (error) {
      emit(PriceRuleDetailError(message: error.toString()));
      return null;
    }
  }

  List<CustomerPriceRuleActivityDto> get _currentRecentActivities {
    final current = state;
    return switch (current) {
      PriceRuleDetailLoaded(:final recentActivities) => recentActivities,
      PriceRuleDetailActionSuccess(:final recentActivities) => recentActivities,
      _ => const [],
    };
  }

  Future<void> _refreshRecentHistory({
    required String ruleId,
    required CustomerPriceRuleDetailDto rule,
  }) async {
    try {
      final tenantId = await _executionContext.requireTenantId();
      final history = await _pricingModule
          .executeQueryAsync<CursorPageDto<CustomerPriceRuleActivityDto>>(
        GetCustomerPriceRuleHistoryQuery(
          tenantId: tenantId,
          ruleId: ruleId,
          limit: 3,
        ),
      );
      emit(PriceRuleDetailLoaded(
        rule: rule,
        recentActivities: history.items,
      ));
    } catch (_) {
      emit(PriceRuleDetailLoaded(rule: rule, recentActivities: const []));
    }
  }
}
