import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'price_rule_history_state.dart';

class PriceRuleHistoryCubit extends Cubit<PriceRuleHistoryState> {
  PriceRuleHistoryCubit({
    required this.ruleId,
    required this.pricingModule,
    required this.executionContext,
  }) : super(const PriceRuleHistoryInitial());

  final String ruleId;
  final IPricingModule pricingModule;
  final IExecutionContext executionContext;

  Future<void> fetchHistory() async {
    if (state is PriceRuleHistoryLoading || state.hasReachedMax) return;

    emit(PriceRuleHistoryLoading(
      items: state.items,
      nextCursor: state.nextCursor,
      hasReachedMax: state.hasReachedMax,
      ruleContext: state.ruleContext,
      hasPermission: state.hasPermission,
      hasSensitivePermission: state.hasSensitivePermission,
      isFirstLoad: state.items.isEmpty,
    ));

    try {
      final tenantId = await executionContext.requireTenantId();

      // Load rule context on first fetch (D-02 header summary).
      CustomerPriceRuleDetailDto? ruleContext = state.ruleContext;
      if (ruleContext == null) {
        ruleContext = await pricingModule.executeQueryAsync(
          GetCustomerPriceRuleDetailQuery(
            tenantId: tenantId,
            ruleId: ruleId,
            businessDate: DateTime.now().toUtc(),
          ),
        );
      }

      final result =
          await pricingModule.executeQueryAsync<CursorPageDto<CustomerPriceRuleActivityDto>>(
        GetCustomerPriceRuleHistoryQuery(
          tenantId: tenantId,
          ruleId: ruleId,
          cursor: state.nextCursor,
        ),
      );

      final newItems = List.of(state.items)..addAll(result.items);
      emit(PriceRuleHistoryLoaded(
        items: newItems,
        nextCursor: result.nextCursor,
        hasReachedMax: result.nextCursor == null,
        ruleContext: ruleContext,
      ));
    } on PricingBlockedException catch (e) {
      if (e.code == PricingBlockedCodes.noPermission) {
        emit(PriceRuleHistoryNoPermission(ruleContext: state.ruleContext));
        return;
      }
      if (e.code == PricingBlockedCodes.notFound) {
        emit(PriceRuleHistoryError(
          items: state.items,
          nextCursor: state.nextCursor,
          hasReachedMax: state.hasReachedMax,
          message: 'Không tìm thấy giá riêng này.',
          ruleContext: state.ruleContext,
        ));
        return;
      }
      emit(PriceRuleHistoryError(
        items: state.items,
        nextCursor: state.nextCursor,
        hasReachedMax: state.hasReachedMax,
        message: e.code,
        ruleContext: state.ruleContext,
      ));
    } on ApplicationException catch (e) {
      emit(PriceRuleHistoryError(
        items: state.items,
        nextCursor: state.nextCursor,
        hasReachedMax: state.hasReachedMax,
        message: e.message,
        ruleContext: state.ruleContext,
      ));
    } catch (e) {
      emit(PriceRuleHistoryError(
        items: state.items,
        nextCursor: state.nextCursor,
        hasReachedMax: state.hasReachedMax,
        message: 'Đã xảy ra lỗi không xác định',
        ruleContext: state.ruleContext,
      ));
    }
  }

  void refresh() {
    emit(const PriceRuleHistoryInitial());
    fetchHistory();
  }
}
