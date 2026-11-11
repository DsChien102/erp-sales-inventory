import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft.dart';

enum ReceiptDraftStatus { loading, ready, loadFailed }

enum ReceiptSubmitStatus { idle, submitting, failed }

class ReceiptDraftState extends Equatable {
  const ReceiptDraftState({
    this.status = ReceiptDraftStatus.loading,
    this.options,
    this.draft = const ReceiptDraft(),
    this.selectedLineKey,
    this.hintsLoading = false,
    this.submit = ReceiptSubmitStatus.idle,
    this.submitError,
    this.submitNetworkError = false,
    this.result,
    this.idempotencyKey,
  });

  final ReceiptDraftStatus status;
  final ReceiptFormOptions? options;
  final ReceiptDraft draft;
  final String? selectedLineKey;
  final bool hintsLoading;
  final ReceiptSubmitStatus submit;
  final String? submitError;
  final bool submitNetworkError;
  final RecordReceiptResult? result;
  final String? idempotencyKey;

  ReceiptDraftState copyWith({
    ReceiptDraftStatus? status,
    ReceiptFormOptions? options,
    ReceiptDraft? draft,
    String? selectedLineKey,
    bool clearSelectedLineKey = false,
    bool? hintsLoading,
    ReceiptSubmitStatus? submit,
    String? submitError,
    bool clearSubmitError = false,
    bool? submitNetworkError,
    RecordReceiptResult? result,
    String? idempotencyKey,
    bool clearIdempotencyKey = false,
  }) {
    return ReceiptDraftState(
      status: status ?? this.status,
      options: options ?? this.options,
      draft: draft ?? this.draft,
      selectedLineKey: clearSelectedLineKey
          ? null
          : (selectedLineKey ?? this.selectedLineKey),
      hintsLoading: hintsLoading ?? this.hintsLoading,
      submit: submit ?? this.submit,
      submitError:
          clearSubmitError ? null : (submitError ?? this.submitError),
      submitNetworkError: submitNetworkError ?? this.submitNetworkError,
      result: result ?? this.result,
      idempotencyKey: clearIdempotencyKey
          ? null
          : (idempotencyKey ?? this.idempotencyKey),
    );
  }

  @override
  List<Object?> get props => [
        status,
        options,
        draft,
        selectedLineKey,
        hintsLoading,
        submit,
        submitError,
        submitNetworkError,
        result,
        idempotencyKey,
      ];
}

