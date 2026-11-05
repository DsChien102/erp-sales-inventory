import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../core/errors/app_exception.dart';
import '../data/customer_price_rule_repository.dart';
import '../data/models.dart';
import '../data/pricing_errors.dart';
import 'price_rule_detail_state.dart';
import 'pricing_error_messages.dart';

/// Cubit chi tiết giá riêng (S3) + disable (S6) + reenable (S7).
///
/// SG-05: reenable bỏ qua duplicate_active_rule; nếu trùng tắt giá cũ, bật giá này.
final class PriceRuleDetailCubit extends Cubit<PriceRuleDetailState> {
  PriceRuleDetailCubit({
    required CustomerPriceRuleRepository repository,
  }) : _repository = repository,
       super(const PriceRuleDetailInitial());

  final CustomerPriceRuleRepository _repository;

  Future<void> loadDetail({
    required String ruleId,
  }) async {
    emit(const PriceRuleDetailLoading());
    try {
      final result = await _fetchDetail(ruleId: ruleId);
      emit(PriceRuleDetailLoaded(
        rule: result.rule,
        recentActivities: result.recentActivities,
      ));
    } on AppException catch (e) {
      if (e.code == PricingErrorCodes.noPermission) {
        emit(const PriceRuleDetailNoPermission());
      } else if (e.code == PricingErrorCodes.notFound) {
        emit(const PriceRuleDetailNotFound());
      } else {
        emit(PriceRuleDetailError(message: _messageForBlocked(e)));
      }
    } catch (error) {
      emit(const PriceRuleDetailError(
        message: 'Không thể tải chi tiết. Vui lòng thử lại.',
      ));
    }
  }

  /// Refresh detail trước khi mở sheet Thao tác — lấy `availableActions` mới nhất.
  ///
  /// Không emit [PriceRuleDetailLoading] để tránh flash skeleton toàn trang.
  Future<CustomerPriceRuleDetailDto?> refreshDetailForActions({
    required String ruleId,
  }) async {
    _actionErrorMessage = null;
    try {
      final result = await _fetchDetail(ruleId: ruleId);
      emit(PriceRuleDetailLoaded(
        rule: result.rule,
        recentActivities: result.recentActivities,
      ));
      return result.rule;
    } on AppException catch (e) {
      _actionErrorMessage = _messageForActionBlocked(e);
      if (e.code == PricingErrorCodes.notFound) {
        emit(const PriceRuleDetailNotFound());
      } else if (e.code == PricingErrorCodes.noPermission) {
        emit(const PriceRuleDetailNoPermission());
      }
      return null;
    } catch (_) {
      _actionErrorMessage = 'Không thể tải thao tác. Vui lòng thử lại.';
      return null;
    }
  }

  /// Lỗi từ lần gọi [refreshDetailForActions] / [disableRule] / [reenableRule] gần nhất.
  String? get actionErrorMessage => _actionErrorMessage;

  String? _actionErrorMessage;

  Future<({CustomerPriceRuleDetailDto rule, List<CustomerPriceRuleActivityDto> recentActivities})>
      _fetchDetail({
    required String ruleId,
  }) async {
    final result = await _repository.getDetail(
      ruleId: ruleId,
      businessDate: VDateTime.currentBusinessDate(),
    );

    List<CustomerPriceRuleActivityDto> recentActivities = const [];
    try {
      final history = await _repository.getHistory(
        ruleId: ruleId,
        limit: 3,
      );
      recentActivities = history.items;
    } catch (_) {
      // History load failed — still show detail.
    }

    return (rule: result, recentActivities: recentActivities);
  }

  /// S6 — Tắt giá riêng.
  Future<CustomerPriceRuleDetailDto?> disableRule({
    required String ruleId,
    required int expectedVersion,
    String? reason,
  }) async {
    _actionErrorMessage = null;
    final previous = _currentLoadedState;
    try {
      final result = await _repository.disable(
        ruleId: ruleId,
        expectedVersion: expectedVersion,
        reason: reason,
      );
      emit(PriceRuleDetailLoaded(
        rule: result,
        recentActivities: _currentRecentActivities,
      ));
      await _refreshRecentHistory(ruleId: ruleId, rule: result);
      return result;
    } on AppException catch (e) {
      _actionErrorMessage = _messageForActionBlocked(e);
      if (previous != null) {
        emit(previous);
      }
      return null;
    } catch (_) {
      _actionErrorMessage = 'Không thể tắt giá riêng. Vui lòng thử lại.';
      if (previous != null) {
        emit(previous);
      }
      return null;
    }
  }

  /// S7 — Precheck trước khi bật lại giá riêng (US-08 FR-02).
  Future<CustomerPriceRuleReenablePrecheckDto?> precheckReenable({
    required String ruleId,
    required int expectedVersion,
  }) async {
    _actionErrorMessage = null;
    try {
      return await _repository.precheckReenable(
        ruleId: ruleId,
        expectedVersion: expectedVersion,
        businessDate: VDateTime.currentBusinessDate(),
      );
    } on AppException catch (e) {
      _actionErrorMessage = _messageForActionBlocked(e);
      return null;
    } catch (_) {
      _actionErrorMessage = 'Không thể kiểm tra điều kiện bật lại. Vui lòng thử lại.';
      return null;
    }
  }

  /// S7 — Bật lại giá riêng.
  ///
  /// SG-05: Không precheck duplicate (bỏ D-06). Gọi trực tiếp
  /// [CustomerPriceRuleRepository.reenable]; nếu có giá riêng khác trùng,
  /// backend tắt giá đó và bật giá này.
  Future<CustomerPriceRuleDetailDto?> reenableRule({
    required String ruleId,
    required int expectedVersion,
    bool acknowledgeFloorWarning = false,
    String? precheckToken,
  }) async {
    _actionErrorMessage = null;
    final previous = _currentLoadedState;
    try {
      final result = await _repository.reenable(
        ruleId: ruleId,
        expectedVersion: expectedVersion,
        businessDate: VDateTime.currentBusinessDate(),
        acknowledgeFloorWarning: acknowledgeFloorWarning,
        acknowledgeOverwrite: true,
        precheckToken: precheckToken,
      );
      emit(PriceRuleDetailLoaded(
        rule: result,
        recentActivities: _currentRecentActivities,
      ));
      await _refreshRecentHistory(ruleId: ruleId, rule: result);
      return result;
    } on AppException catch (e) {
      _actionErrorMessage = _messageForActionBlocked(e);
      if (previous != null) {
        emit(previous);
      }
      return null;
    } catch (_) {
      _actionErrorMessage = 'Không thể bật lại giá riêng. Vui lòng thử lại.';
      if (previous != null) {
        emit(previous);
      }
      return null;
    }
  }

  PriceRuleDetailLoaded? get _currentLoadedState {
    final current = state;
    return switch (current) {
      PriceRuleDetailLoaded() => current,
      PriceRuleDetailActionSuccess(:final rule, :final recentActivities) =>
        PriceRuleDetailLoaded(rule: rule, recentActivities: recentActivities),
      _ => null,
    };
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
      final history = await _repository.getHistory(
        ruleId: ruleId,
        limit: 3,
      );
      emit(PriceRuleDetailLoaded(
        rule: rule,
        recentActivities: history.items,
      ));
    } catch (_) {
      emit(PriceRuleDetailLoaded(rule: rule, recentActivities: const []));
    }
  }

  String _messageForBlocked(AppException e) => pricingErrorMessage(
    e,
    fallback: 'Không thể tải chi tiết. Vui lòng thử lại.',
    overrides: const {
      PricingErrorCodes.validationError: 'Dữ liệu không hợp lệ.',
      PricingErrorCodes.systemError: 'Không thể tải chi tiết. Vui lòng thử lại.',
    },
  );

  String _messageForActionBlocked(AppException e) => pricingErrorMessage(
    e,
    fallback: 'Không thể thực hiện thao tác. Vui lòng thử lại.',
    overrides: const {
      PricingErrorCodes.noPermission: 'Bạn không có quyền thực hiện thao tác này.',
      PricingErrorCodes.stateChanged: 'Dữ liệu đã thay đổi. Vui lòng tải lại và thử lại.',
      PricingErrorCodes.invalidStatus: 'Không thể thực hiện với trạng thái hiện tại.',
      PricingErrorCodes.notFound: 'Mức giá riêng không còn tồn tại.',
      PricingErrorCodes.belowFloorBlocked: 'Giá dưới sàn và chưa được xác nhận.',
      PricingErrorCodes.duplicateActiveRule:
          'Đã có giá riêng khác đang áp dụng cho cùng khách hàng và sản phẩm.',
      PricingErrorCodes.referenceInvalid: 'Thông tin khách hàng hoặc sản phẩm không còn hợp lệ.',
      PricingErrorCodes.validationError: 'Dữ liệu không hợp lệ.',
      PricingErrorCodes.systemError: 'Không thể thực hiện thao tác. Vui lòng thử lại.',
    },
  );

  String messageForPrecheckBlocked(RuleValidationOutcomeDto outcome) {
    final codes = outcome.blockingCodes;
    if (codes.contains('duplicate_active_rule')) {
      return 'Đã có giá riêng khác đang áp dụng cho cùng khách hàng và sản phẩm.';
    }
    if (codes.contains('effective_period_expired')) {
      return 'Giá riêng đã hết hiệu lực, không thể bật lại.';
    }
    if (codes.contains('customer_reference_invalid')) {
      return 'Khách hàng không còn hợp lệ để bật lại giá riêng.';
    }
    if (codes.contains('product_unit_reference_invalid')) {
      return 'Sản phẩm hoặc đơn vị bán không còn hợp lệ.';
    }
    if (codes.contains('currency_mismatch')) {
      return 'Đơn vị tiền tệ không khớp với sản phẩm hiện tại.';
    }
    if (codes.contains('override_permission_required')) {
      return 'Giá riêng dưới giá sàn và bạn không có quyền ghi đè.';
    }
    return 'Không thể bật lại giá riêng với điều kiện hiện tại.';
  }
}
