import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';

enum RebateRecordStatus {
  loading,
  loadError,
  notOwner,
  notReached,
  ready,
  submitting,
  recorded,
  stale,
}

class RebateRecordState {
  final RebateRecordStatus status;
  final ProgramDetail? program;
  final RebatePreview? preview;
  final bool previewLoading;
  final String documentNo;
  final DateTime documentDate;
  final String amountText;
  final String reason;
  final bool showErrors;
  final bool confirming;
  final RebateRecordResult? result;
  final String? errorCode;
  final String? previewErrorCode;
  final Map<String, String> errors;

  const RebateRecordState({
    this.status = RebateRecordStatus.loading,
    this.program,
    this.preview,
    this.previewLoading = false,
    this.documentNo = '',
    required this.documentDate,
    this.amountText = '',
    this.reason = '',
    this.showErrors = false,
    this.confirming = false,
    this.result,
    this.errorCode,
    this.previewErrorCode,
    this.errors = const {},
  });

  RebateRecordState copyWith({
    RebateRecordStatus? status,
    ProgramDetail? program,
    RebatePreview? preview,
    bool clearPreview = false,
    bool? previewLoading,
    String? documentNo,
    DateTime? documentDate,
    String? amountText,
    String? reason,
    bool? showErrors,
    bool? confirming,
    RebateRecordResult? result,
    bool clearResult = false,
    String? errorCode,
    bool clearErrorCode = false,
    String? previewErrorCode,
    bool clearPreviewErrorCode = false,
    Map<String, String>? errors,
  }) {
    return RebateRecordState(
      status: status ?? this.status,
      program: program ?? this.program,
      preview: clearPreview ? null : (preview ?? this.preview),
      previewLoading: previewLoading ?? this.previewLoading,
      documentNo: documentNo ?? this.documentNo,
      documentDate: documentDate ?? this.documentDate,
      amountText: amountText ?? this.amountText,
      reason: reason ?? this.reason,
      showErrors: showErrors ?? this.showErrors,
      confirming: confirming ?? this.confirming,
      result: clearResult ? null : (result ?? this.result),
      errorCode: clearErrorCode ? null : (errorCode ?? this.errorCode),
      previewErrorCode: clearPreviewErrorCode
          ? null
          : (previewErrorCode ?? this.previewErrorCode),
      errors: errors ?? this.errors,
    );
  }
}

