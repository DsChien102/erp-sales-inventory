import 'package:equatable/equatable.dart';

import '../../models/sales_order_draft/sales_compose_customer_vm.dart';
import '../../models/sales_order_draft/sales_compose_line_vm.dart';
import '../../models/sales_order_draft/sales_compose_totals.dart';
import 'sales_draft_contracts.dart';

enum SalesComposeSaveStatus { saved, saving, unsaved, error }

enum SalesComposePricingStatus { idle, refreshing, ready, stale, error }

enum SalesComposeBusy { none, checkingOut, adjustingPrice }

final class SalesComposePricingSlice extends Equatable {
  const SalesComposePricingSlice({
    this.status = SalesComposePricingStatus.idle,
    this.contextVersion = 0,
    this.pricedContextVersion = -1,
    this.previewToken,
    this.message,
  });

  final SalesComposePricingStatus status;
  final int contextVersion;
  final int pricedContextVersion;
  final String? previewToken;
  final String? message;

  SalesComposePricingSlice copyWith({
    SalesComposePricingStatus? status,
    int? contextVersion,
    int? pricedContextVersion,
    String? previewToken,
    bool clearPreviewToken = false,
    String? message,
    bool clearMessage = false,
  }) {
    return SalesComposePricingSlice(
      status: status ?? this.status,
      contextVersion: contextVersion ?? this.contextVersion,
      pricedContextVersion: pricedContextVersion ?? this.pricedContextVersion,
      previewToken: clearPreviewToken ? null : (previewToken ?? this.previewToken),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    status,
    contextVersion,
    pricedContextVersion,
    previewToken,
    message,
  ];
}

final class SalesComposeSaveSlice extends Equatable {
  const SalesComposeSaveSlice({
    this.status = SalesComposeSaveStatus.saved,
    this.message,
  });

  final SalesComposeSaveStatus status;
  final String? message;

  SalesComposeSaveSlice copyWith({
    SalesComposeSaveStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return SalesComposeSaveSlice(
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, message];
}

sealed class SalesComposeState extends Equatable {
  const SalesComposeState({
    required this.draftId,
    required this.customer,
    required this.lines,
    this.orderNote,
    this.pricing = const SalesComposePricingSlice(),
    this.save = const SalesComposeSaveSlice(),
    this.busy = SalesComposeBusy.none,
    this.title = 'Tạo đơn',
    this.draftVersion,
    this.restoreIssues = const <SalesDraftRestoreIssue>[],
  });

  final String draftId;
  final SalesComposeCustomerVm customer;
  final List<SalesComposeLineVm> lines;
  final String? orderNote;
  final SalesComposePricingSlice pricing;
  final SalesComposeSaveSlice save;
  final SalesComposeBusy busy;
  final String title;
  final int? draftVersion;
  final List<SalesDraftRestoreIssue> restoreIssues;

  SalesComposeSaveStatus get saveStatus => save.status;
  String? get saveMessage => save.message;
  SalesComposePricingStatus get pricingStatus => pricing.status;
  String? get pricingMessage => pricing.message;
  int get pricingContextVersion => pricing.contextVersion;
  int get pricedContextVersion => pricing.pricedContextVersion;
  String? get previewToken => pricing.previewToken;

  /// Tóm tắt thanh toán dựa trên số pricing preview trả về theo từng dòng.
  SalesComposeTotals get totals => SalesComposeTotals.fromLines(lines);

  int get subtotalMinor => totals.netAmountMinor;

  bool get hasLineWarnings => lines.any(
    (line) => line.warningLevel != SalesStockWarningLevel.none,
  );

  bool get canCheckout =>
      busy == SalesComposeBusy.none &&
      lines.isNotEmpty &&
      pricingStatus == SalesComposePricingStatus.ready &&
      pricedContextVersion == pricingContextVersion &&
      lines.every(
        (line) => line.pricing.isReady && line.pricing.blockingCodes.isEmpty,
      );

  /// US-06 FR-01 / EC-01: cần ≥1 dòng — khách lẻ được phép (không bắt Partner).
  bool get canSaveDraft => lines.isNotEmpty && busy == SalesComposeBusy.none;

  /// Có thay đổi local chưa được lưu nháp (kể cả lần lưu thất bại cần retry).
  bool get hasUnsavedChanges =>
      saveStatus == SalesComposeSaveStatus.unsaved || saveStatus == SalesComposeSaveStatus.error;

  /// O-02 leave guard: chỉ hỏi khi còn dòng SP chưa lưu.
  /// Chỉ đổi KH / ghi chú (chưa có dòng) → thoát thẳng.
  bool get shouldConfirmLeave => hasUnsavedChanges && lines.isNotEmpty;

  @override
  List<Object?> get props => [
    draftId,
    customer,
    lines,
    orderNote,
    pricing,
    save,
    busy,
    title,
    draftVersion,
    restoreIssues,
  ];
}

final class SalesComposeLoaded extends SalesComposeState {
  const SalesComposeLoaded({
    required super.draftId,
    required super.customer,
    required super.lines,
    super.orderNote,
    super.pricing,
    super.save,
    super.busy,
    super.title,
    super.draftVersion,
    super.restoreIssues,
  });
}

final class SalesComposeLoading extends SalesComposeState {
  const SalesComposeLoading({
    required super.draftId,
    required super.customer,
    required super.lines,
  }) : super(
         save: const SalesComposeSaveSlice(status: SalesComposeSaveStatus.saving),
         pricing: const SalesComposePricingSlice(),
         title: 'Soạn đơn',
       );
}

/// Restore failed — must not present as a checkout-capable empty/new order.
final class SalesComposeError extends SalesComposeState {
  SalesComposeError({
    required super.draftId,
    required this.message,
  }) : super(
         customer: const SalesComposeCustomerVm(
           displayName: 'Khách lẻ',
           isWalkIn: true,
         ),
         lines: const <SalesComposeLineVm>[],
         save: SalesComposeSaveSlice(
           status: SalesComposeSaveStatus.error,
           message: message,
         ),
         pricing: SalesComposePricingSlice(
           status: SalesComposePricingStatus.error,
         ),
         title: 'Không khôi phục được',
       );

  final String message;
}
