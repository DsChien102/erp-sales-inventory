import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'price_rule_form_state.dart';

/// Kết quả tra cứu giá advisory khi chọn sản phẩm (create mode).
typedef PriceRuleAdvisoryLookup = ({
  int? listPriceMinor,
  int? floorPriceMinor,
  bool floorPriceHidden,
})? Function(String productId);

/// Cubit form tạo/sửa giá riêng (S1/S5 — SG-03).
///
/// SG-03:
/// - Tất cả field trên 1 màn hình.
/// - Duplicate active interval bị authoritative backend chặn khi tạo thủ công.
/// - FE giữ nguyên dữ liệu form để người dùng điều chỉnh rồi thử lại.
final class PriceRuleFormCubit extends Cubit<PriceRuleFormState> {
  PriceRuleFormCubit({
    required IPricingModule pricingModule,
    required IExecutionContext executionContext,
    PriceRuleFormMode mode = PriceRuleFormMode.create,
    CustomerPriceRuleDetailDto? existingRule,
    PriceRuleAdvisoryLookup? advisoryLookup,
  }) : _pricingModule = pricingModule,
       _executionContext = executionContext,
       _mode = mode,
       _existingRule = existingRule,
       _advisoryLookup = advisoryLookup,
       super(const PriceRuleFormInitial()) {
    _initFromExisting();
  }

  final IPricingModule _pricingModule;
  final IExecutionContext _executionContext;
  final PriceRuleFormMode _mode;
  CustomerPriceRuleDetailDto? _existingRule;
  final PriceRuleAdvisoryLookup? _advisoryLookup;

  // Idempotency key cho lần tạo mới.
  String? _idempotencyKey;

  void _initFromExisting() {
    final rule = _existingRule;
    if (rule != null && _mode == PriceRuleFormMode.edit) {
      final outcome = rule.validationOutcome;
      emit(
        PriceRuleFormEditing(
          customerId: rule.customer.customerId,
          customerName: rule.customer.displayName,
          customerRoleLabel: rule.customer.status,
          productId: rule.productUnit.productId,
          productName: rule.productUnit.productName,
          productUnitId: rule.productUnit.productUnitId,
          productUnitName: rule.productUnit.unitName,
          rulePriceMinor: rule.price.amountMinor,
          currencyCode: rule.price.currencyCode,
          effectiveFrom: rule.effectivePeriod.effectiveFrom,
          effectiveTo: rule.effectivePeriod.effectiveTo,
          note: rule.note,
          listPriceMinor: outcome.listPrice?.amountMinor,
          floorPriceMinor: outcome.floorPrice?.amountMinor,
          floorPriceHidden: outcome.floorPriceHidden,
        ),
      );
    } else {
      emit(const PriceRuleFormEditing());
    }
  }

  void selectCustomer({
    required String customerId,
    required String customerName,
    String? customerRoleLabel,
  }) {
    final current = _editingOrNew();
    emit(
      current.copyWith(
        customerId: customerId,
        customerName: customerName,
        customerRoleLabel: customerRoleLabel,
        hasStateChanged: false,
        isDirty: true,
      ),
    );
  }

  void selectProduct({
    required String productId,
    required String productName,
    int? listPriceMinor,
    int? floorPriceMinor,
  }) {
    final current = _editingOrNew();
    // Reset đơn vị khi đổi sản phẩm.
    emit(
      current.copyWith(
        productId: productId,
        productName: productName,
        productUnitId: null,
        productUnitName: null,
        listPriceMinor: listPriceMinor,
        floorPriceMinor: floorPriceMinor,
        floorPriceHidden: floorPriceMinor == null,
        isDirty: true,
      ),
    );
    _applyAdvisory(productId);
  }

  void selectProductUnit({
    required String productUnitId,
    required String productUnitName,
    int? listPriceMinor,
    int? floorPriceMinor,
    bool? floorPriceHidden,
  }) {
    final current = _editingOrNew();
    emit(
      current.copyWith(
        productUnitId: productUnitId,
        productUnitName: productUnitName,
        listPriceMinor: listPriceMinor ?? current.listPriceMinor,
        floorPriceMinor: floorPriceMinor ?? current.floorPriceMinor,
        floorPriceHidden: floorPriceHidden ?? current.floorPriceHidden,
        isDirty: true,
      ),
    );
    final productId = current.productId;
    if (productId != null &&
        listPriceMinor == null &&
        floorPriceMinor == null) {
      _applyAdvisory(productId);
    }
  }

  void _applyAdvisory(String productId) {
    if (_mode == PriceRuleFormMode.edit) return;
    final advisory = _advisoryLookup?.call(productId);
    if (advisory == null) return;
    final current = _editingOrNew();
    emit(
      current.copyWith(
        listPriceMinor: advisory.listPriceMinor,
        floorPriceMinor: advisory.floorPriceMinor,
        floorPriceHidden: advisory.floorPriceHidden,
      ),
    );
  }

  void updatePrice(int? amountMinor) {
    final current = _editingOrNew();
    emit(current.copyWith(rulePriceMinor: amountMinor, isDirty: true));
  }

  void updateDates({DateTime? effectiveFrom, Object? effectiveTo = _sentinel}) {
    final current = _editingOrNew();
    final newFrom = effectiveFrom ?? current.effectiveFrom;
    final newTo = effectiveTo == _sentinel ? current.effectiveTo : effectiveTo as DateTime?;
    final rule = _existingRule;
    final isDateChanged = rule != null &&
        (newFrom != rule.effectivePeriod.effectiveFrom ||
            newTo != rule.effectivePeriod.effectiveTo);

    emit(
      current.copyWith(
        effectiveFrom: newFrom,
        effectiveTo: newTo,
        hasConflictingRule: isDateChanged,
        isDirty: true,
      ),
    );
  }

  void clearEffectiveTo() {
    final current = _editingOrNew();
    final rule = _existingRule;
    final isDateChanged = rule != null &&
        (current.effectiveFrom != rule.effectivePeriod.effectiveFrom ||
            rule.effectivePeriod.effectiveTo != null);

    emit(
      current.copyWith(
        effectiveTo: null,
        hasConflictingRule: isDateChanged,
        isDirty: true,
      ),
    );
  }

  void updateNote(String? note) {
    final current = _editingOrNew();
    emit(
      current.copyWith(
        note: note?.trim().isEmpty == true ? null : note,
        isDirty: true,
      ),
    );
  }

  /// D-09: Tải lại rule khi STATE_CHANGED.
  Future<void> reloadExistingRule() async {
    final ruleId = _existingRule?.id;
    if (ruleId == null || _mode != PriceRuleFormMode.edit) return;

    final tenantId = await _executionContext.requireTenantId();
    try {
      final detail = await _pricingModule.executeQueryAsync(
        GetCustomerPriceRuleDetailQuery(
          tenantId: tenantId,
          ruleId: ruleId,
          businessDate: DateTime.now().toUtc(),
        ),
      );
      _existingRule = detail;
      _initFromExisting();
    } catch (_) {
      emit(const PriceRuleFormError(code: PricingBlockedCodes.systemError));
      _initFromExisting();
    }
  }

  /// SG-03: Submit form. Tạo thủ công bị chặn nếu trùng active interval.
  Future<void> submit({String? changeReason}) async {
    final current = _editingOrNew();
    if (!current.isValid) return;

    emit(
      current.copyWith(
        isSubmitting: true,
        hasStateChanged: false,
      ),
    );

    try {
      if (_mode == PriceRuleFormMode.create) {
        await _createRule(current);
      } else {
        await _updateRule(current, changeReason: changeReason);
      }
    } on PricingBlockedException catch (e) {
      await _handleBlocked(e);
    } catch (error) {
      final editing = _editingOrNew();
      emit(PriceRuleFormError(code: PricingBlockedCodes.systemError));
      emit(editing.copyWith(isSubmitting: false));
    }
  }

  Future<void> _handleBlocked(PricingBlockedException e) async {
    final editing = _editingOrNew();
    if (e.code == PricingBlockedCodes.stateChanged) {
      emit(
        editing.copyWith(
          isSubmitting: false,
          hasStateChanged: true,
        ),
      );
    } else if (e.code == PricingBlockedCodes.noPermission) {
      emit(const PriceRuleFormNoPermission());
      emit(editing.copyWith(isSubmitting: false));
    } else if (e.code == PricingBlockedCodes.duplicateActiveRule) {
      final conflictingId = e.details['conflictingRuleId'] as String?;
      emit(
        PriceRuleFormError(
          code: e.code,
          fieldErrors: _parseFieldErrors(e),
        ),
      );
      emit(
        editing.copyWith(
          isSubmitting: false,
          hasConflictingRule: true,
          conflictingRuleId: conflictingId,
        ),
      );
    } else {
      emit(
        PriceRuleFormError(
          code: e.code,
          fieldErrors: _parseFieldErrors(e),
        ),
      );
      emit(editing.copyWith(isSubmitting: false));
    }
  }

  Future<void> confirmOverwrite({String? changeReason}) async {
    final current = _editingOrNew();
    emit(current.copyWith(isSubmitting: true));

    try {
      if (_mode == PriceRuleFormMode.create) {
        await _createRule(current, acknowledgeOverwrite: true);
      } else {
        await _updateRule(
          current,
          changeReason: changeReason,
          acknowledgeOverwrite: true,
        );
      }
    } on PricingBlockedException catch (e) {
      await _handleBlocked(e);
    } catch (error) {
      final editing = _editingOrNew();
      emit(const PriceRuleFormError(code: PricingBlockedCodes.systemError));
      emit(editing.copyWith(isSubmitting: false));
    }
  }

  Future<void> _createRule(
    PriceRuleFormEditing form, {
    bool acknowledgeOverwrite = false,
  }) async {
    _idempotencyKey ??= _generateIdempotencyKey();
    final tenantId = await _executionContext.requireTenantId();
    final result = await _pricingModule.executeCommandAsync(
      CreateCustomerPriceRuleCommand(
        tenantId: tenantId,
        customerId: form.customerId!,
        productId: form.productId!,
        productUnitId: form.productUnitId!,
        rulePriceMinor: form.rulePriceMinor!,
        currencyCode: form.currencyCode,
        effectiveFrom: form.effectiveFrom!,
        effectiveTo: form.effectiveTo,
        note: form.note,
        acknowledgeFloorWarning: form.isBelowFloor,
        acknowledgeOverwrite: acknowledgeOverwrite,
        idempotencyKey: _idempotencyKey!,
      ),
    );
    emit(PriceRuleFormSuccess(rule: result.rule));
  }

  Future<void> _updateRule(
    PriceRuleFormEditing form, {
    String? changeReason,
    bool acknowledgeOverwrite = false,
  }) async {
    final rule = _existingRule!;
    final tenantId = await _executionContext.requireTenantId();
    final note = changeReason ?? form.note;
    final result = await _pricingModule.executeCommandAsync(
      UpdateCustomerPriceRuleCommand(
        tenantId: tenantId,
        ruleId: rule.id,
        expectedVersion: rule.version,
        rulePriceMinor: form.rulePriceMinor!,
        effectiveFrom: form.effectiveFrom!,
        effectiveTo: form.effectiveTo,
        note: note,
        acknowledgeFloorWarning: form.isBelowFloor,
        acknowledgeOverwrite: acknowledgeOverwrite,
      ),
    );
    emit(PriceRuleFormSuccess(rule: result));
  }

  PriceRuleFormEditing _editingOrNew() {
    final s = state;
    return s is PriceRuleFormEditing ? s : const PriceRuleFormEditing();
  }

  Map<String, String> _parseFieldErrors(PricingBlockedException e) {
    // Placeholder: parse structured details if available.
    return {};
  }

  String _generateIdempotencyKey() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'form_$now';
  }
}

const _sentinel = Object();
