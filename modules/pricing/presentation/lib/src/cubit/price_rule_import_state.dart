import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:vet45_pricing_application/application.dart';

/// Các bước trong luồng import Excel (S8).
enum PriceRuleImportStep { chooseFile, preview, confirm, result }

/// Tab lọc preview (D-02 / reopen từ D-05).
enum PriceRuleImportPreviewTab { valid, warning, error }

/// Trạng thái cubit import Excel (S8 — SG-04).
sealed class PriceRuleImportState extends Equatable {
  const PriceRuleImportState({
    this.step = PriceRuleImportStep.chooseFile,
  });

  final PriceRuleImportStep step;

  @override
  List<Object?> get props => [step];
}

final class PriceRuleImportInitial extends PriceRuleImportState {
  const PriceRuleImportInitial() : super(step: PriceRuleImportStep.chooseFile);
}

/// SC-07 — Không có quyền import khi mở flow.
final class PriceRuleImportNoPermission extends PriceRuleImportState {
  const PriceRuleImportNoPermission()
    : super(step: PriceRuleImportStep.chooseFile);
}

final class PriceRuleImportLoading extends PriceRuleImportState {
  const PriceRuleImportLoading({
    required super.step,
    this.message,
  });

  /// Copy loading (vd. "Đang kiểm tra dữ liệu...").
  final String? message;

  @override
  List<Object?> get props => [...super.props, message];
}

/// Bước 1: Đã chọn file, chờ bấm Tiếp tục (D-01).
final class PriceRuleImportFileSelected extends PriceRuleImportState {
  const PriceRuleImportFileSelected({
    required this.fileName,
    required this.fileSizeBytes,
  }) : super(step: PriceRuleImportStep.chooseFile);

  final String fileName;
  final int fileSizeBytes;

  @override
  List<Object?> get props => [...super.props, fileName, fileSizeBytes];
}

/// Bước 2: Đang xem trước kết quả (sau khi upload xong).
final class PriceRuleImportPreview extends PriceRuleImportState {
  const PriceRuleImportPreview({
    required this.importDetail,
    required this.rows,
    this.readOnly = false,
    this.initialTab = PriceRuleImportPreviewTab.valid,
  }) : super(step: PriceRuleImportStep.preview);

  final CustomerPriceRuleImportDetailDto importDetail;
  final List<CustomerPriceRuleImportRowPreviewDto> rows;

  /// Mở lại từ màn kết quả — không cho Tiếp tục confirm.
  final bool readOnly;
  final PriceRuleImportPreviewTab initialTab;

  @override
  List<Object?> get props => [
    ...super.props,
    importDetail.batch.id,
    importDetail.batch.version,
    rows.length,
    readOnly,
    initialTab,
  ];
}

/// Bước 3: Xác nhận — SG-04: Không có section "Hiệu lực mặc định".
final class PriceRuleImportConfirm extends PriceRuleImportState {
  const PriceRuleImportConfirm({
    required this.importDetail,
    this.acknowledgeWarningRows = false,
    this.isRefreshingMode = false,
  }) : super(step: PriceRuleImportStep.confirm);

  final CustomerPriceRuleImportDetailDto importDetail;

  /// SG-04: Không có effectiveFrom default — chỉ acknowledge warnings.
  final bool acknowledgeWarningRows;

  /// Đang đổi importMode — giữ UI confirm + overlay VLoading.
  final bool isRefreshingMode;

  @override
  List<Object?> get props => [
    ...super.props,
    importDetail.batch.id,
    importDetail.batch.importMode,
    importDetail.batch.version,
    acknowledgeWarningRows,
    isRefreshingMode,
  ];
}

/// Bước 4: Kết quả import.
final class PriceRuleImportResult extends PriceRuleImportState {
  const PriceRuleImportResult({required this.result})
    : super(step: PriceRuleImportStep.result);

  final CustomerPriceRuleImportResultDto result;

  /// Success / partial / failed theo counters batch.
  PriceRuleImportOutcome get outcome {
    final batch = result.batch;
    if (batch.importedRows <= 0) return PriceRuleImportOutcome.failed;
    if (batch.failedRows > 0 || batch.skippedRows > 0) {
      return PriceRuleImportOutcome.partial;
    }
    return PriceRuleImportOutcome.success;
  }

  @override
  List<Object?> get props => [...super.props, result.batch.importedRows];
}

enum PriceRuleImportOutcome { success, partial, failed }

final class PriceRuleImportError extends PriceRuleImportState {
  const PriceRuleImportError({
    required this.code,
    required super.step,
  });

  final String code;

  @override
  List<Object?> get props => [...super.props, code];
}

/// Bytes file đã chọn — không đưa vào Equatable state (tránh rebuild nặng).
final class PriceRuleImportPendingFile {
  const PriceRuleImportPendingFile({
    required this.fileName,
    required this.fileBytes,
  });

  final String fileName;
  final Uint8List fileBytes;

  int get fileSizeBytes => fileBytes.length;
}
