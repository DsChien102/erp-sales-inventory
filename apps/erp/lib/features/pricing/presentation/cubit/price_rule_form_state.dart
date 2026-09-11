import 'package:equatable/equatable.dart';
import 'package:vet45_pricing_application/application.dart';

/// Mode của form tạo/sửa giá riêng.
enum PriceRuleFormMode { create, edit }

/// Trạng thái cubit form tạo/sửa giá riêng (S1/S5 — SG-03).
sealed class PriceRuleFormState extends Equatable {
  const PriceRuleFormState();

  @override
  List<Object?> get props => [];
}

final class PriceRuleFormInitial extends PriceRuleFormState {
  const PriceRuleFormInitial();
}

final class PriceRuleFormEditing extends PriceRuleFormState {
  const PriceRuleFormEditing({
    this.customerId,
    this.customerName,
    this.customerRoleLabel,
    this.productId,
    this.productName,
    this.productUnitId,
    this.productUnitName,
    this.rulePriceMinor,
    this.currencyCode = 'VND',
    this.effectiveFrom,
    this.effectiveTo,
    this.note,
    this.listPriceMinor,
    this.floorPriceMinor,
    this.floorPriceHidden = true,
    this.hasConflictingRule = false,
    this.conflictingRuleId,
    this.hasStateChanged = false,
    this.isDirty = false,
    this.fieldErrors = const {},
    this.isSubmitting = false,
  });

  final String? customerId;
  final String? customerName;
  /// Vai trò hiển thị (VD: Khách hàng) — từ picker.
  final String? customerRoleLabel;
  final String? productId;
  final String? productName;
  final String? productUnitId;
  final String? productUnitName;
  final int? rulePriceMinor;
  final String currencyCode;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final String? note;

  /// Giá niêm yết / sàn advisory (từ detail khi sửa; create context khi có).
  final int? listPriceMinor;
  final int? floorPriceMinor;
  final bool floorPriceHidden;
  final bool hasConflictingRule;
  final String? conflictingRuleId;

  /// D-09: Phiên bản rule đã thay đổi — cần tải lại.
  final bool hasStateChanged;

  /// SC-06: Form đã có thay đổi chưa lưu (tạo: đã nhập; sửa: khác baseline).
  final bool isDirty;

  final Map<String, String> fieldErrors;
  final bool isSubmitting;

  bool get isBelowFloor =>
      !floorPriceHidden &&
      floorPriceMinor != null &&
      rulePriceMinor != null &&
      rulePriceMinor! < floorPriceMinor!;

  bool get isValid =>
      customerId != null &&
      productId != null &&
      productUnitId != null &&
      rulePriceMinor != null &&
      rulePriceMinor! > 0 &&
      effectiveFrom != null;

  /// D-05: Bảng so sánh giá khi đã có giá riêng + giá hiện tại/sàn.
  bool get showReadinessSummary =>
      rulePriceMinor != null &&
      rulePriceMinor! > 0 &&
      (listPriceMinor != null ||
          (!floorPriceHidden && floorPriceMinor != null));

  PriceRuleFormEditing copyWith({
    String? customerId,
    String? customerName,
    Object? customerRoleLabel = _sentinel,
    String? productId,
    String? productName,
    String? productUnitId,
    String? productUnitName,
    Object? rulePriceMinor = _sentinel,
    String? currencyCode,
    DateTime? effectiveFrom,
    Object? effectiveTo = _sentinel,
    String? note,
    Object? listPriceMinor = _sentinel,
    Object? floorPriceMinor = _sentinel,
    bool? floorPriceHidden,
    bool? hasConflictingRule,
    Object? conflictingRuleId = _sentinel,
    bool? hasStateChanged,
    bool? isDirty,
    Map<String, String>? fieldErrors,
    bool? isSubmitting,
  }) {
    return PriceRuleFormEditing(
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerRoleLabel: customerRoleLabel == _sentinel
          ? this.customerRoleLabel
          : customerRoleLabel as String?,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productUnitId: productUnitId ?? this.productUnitId,
      productUnitName: productUnitName ?? this.productUnitName,
      rulePriceMinor: rulePriceMinor == _sentinel
          ? this.rulePriceMinor
          : rulePriceMinor as int?,
      currencyCode: currencyCode ?? this.currencyCode,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo:
          effectiveTo == _sentinel
              ? this.effectiveTo
              : effectiveTo as DateTime?,
      note: note ?? this.note,
      listPriceMinor: listPriceMinor == _sentinel
          ? this.listPriceMinor
          : listPriceMinor as int?,
      floorPriceMinor: floorPriceMinor == _sentinel
          ? this.floorPriceMinor
          : floorPriceMinor as int?,
      floorPriceHidden: floorPriceHidden ?? this.floorPriceHidden,
      hasConflictingRule: hasConflictingRule ?? this.hasConflictingRule,
      conflictingRuleId: conflictingRuleId == _sentinel
          ? this.conflictingRuleId
          : conflictingRuleId as String?,
      hasStateChanged: hasStateChanged ?? this.hasStateChanged,
      isDirty: isDirty ?? this.isDirty,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
    customerId,
    customerName,
    customerRoleLabel,
    productId,
    productName,
    productUnitId,
    productUnitName,
    rulePriceMinor,
    effectiveFrom,
    effectiveTo,
    listPriceMinor,
    floorPriceMinor,
    floorPriceHidden,
    hasConflictingRule,
    conflictingRuleId,
    hasStateChanged,
    isDirty,
    fieldErrors,
    isSubmitting,
  ];
}

final class PriceRuleFormNoPermission extends PriceRuleFormState {
  const PriceRuleFormNoPermission();
}

final class PriceRuleFormSuccess extends PriceRuleFormState {
  const PriceRuleFormSuccess({required this.rule});

  final CustomerPriceRuleDetailDto rule;

  @override
  List<Object?> get props => [rule.id];
}

final class PriceRuleFormError extends PriceRuleFormState {
  const PriceRuleFormError({
    required this.code,
    this.fieldErrors = const {},
  });

  final String code;
  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [code, fieldErrors];
}

// Sentinel để phân biệt null explicit vs không truyền.
const _sentinel = Object();
