import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../core/errors/app_exception.dart';
import '../data/customer_price_rule_repository.dart';
import '../data/models.dart';
import '../data/pricing_errors.dart';
import 'price_rule_history_state.dart';
import 'pricing_error_messages.dart';

class PriceRuleHistoryCubit extends Cubit<PriceRuleHistoryState> {
  PriceRuleHistoryCubit({
    required this.ruleId,
    required this.repository,
  }) : super(const PriceRuleHistoryInitial());

  final String ruleId;
  final CustomerPriceRuleRepository repository;

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
      // Load rule context on first fetch (D-02 header summary).
      CustomerPriceRuleDetailDto? ruleContext = state.ruleContext;
      if (ruleContext == null) {
        ruleContext = await repository.getDetail(
          ruleId: ruleId,
          businessDate: VDateTime.currentBusinessDate(),
        );
      }

      final result = await repository.getHistory(
        ruleId: ruleId,
        cursor: state.nextCursor,
      );

      final newItems = List.of(state.items)..addAll(result.items);
      emit(PriceRuleHistoryLoaded(
        items: newItems,
        nextCursor: result.nextCursor,
        hasReachedMax: result.nextCursor == null,
        ruleContext: ruleContext,
      ));
    } on AppException catch (e) {
      if (e.code == PricingErrorCodes.noPermission) {
        emit(PriceRuleHistoryNoPermission(ruleContext: state.ruleContext));
        return;
      }
      emit(PriceRuleHistoryError(
        items: state.items,
        nextCursor: state.nextCursor,
        hasReachedMax: state.hasReachedMax,
        message: pricingErrorMessage(
          e,
          fallback: 'Không thể tải lịch sử. Vui lòng thử lại.',
          overrides: const {
            PricingErrorCodes.notFound: 'Không tìm thấy giá riêng này.',
          },
        ),
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
