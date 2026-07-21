import 'package:equatable/equatable.dart';
import 'package:vet45_pricing_application/application.dart';

/// Các bước trong luồng import Excel (S8).
enum PriceRuleImportStep { chooseFile, preview, confirm, result }

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

final class PriceRuleImportLoading extends PriceRuleImportState {
  const PriceRuleImportLoading({required super.step});
}

/// Bước 1: Đã chọn file, đang chờ xem trước.
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
  }) : super(step: PriceRuleImportStep.preview);

  final CustomerPriceRuleImportDetailDto importDetail;
  final List<CustomerPriceRuleImportRowPreviewDto> rows;

  @override
  List<Object?> get props => [
    ...super.props,
    importDetail.batch.id,
    importDetail.batch.version,
    rows.length,
  ];
}

/// Bước 3: Xác nhận — SG-04: Không có section "Hiệu lực mặc định".
final class PriceRuleImportConfirm extends PriceRuleImportState {
  const PriceRuleImportConfirm({
    required this.importDetail,
    this.acknowledgeWarningRows = false,
  }) : super(step: PriceRuleImportStep.confirm);

  final CustomerPriceRuleImportDetailDto importDetail;

  /// SG-04: Không có effectiveFrom default — chỉ acknowledge warnings.
  final bool acknowledgeWarningRows;

  @override
  List<Object?> get props => [
    ...super.props,
    importDetail.batch.id,
    acknowledgeWarningRows,
  ];
}

/// Bước 4: Kết quả import.
final class PriceRuleImportResult extends PriceRuleImportState {
  const PriceRuleImportResult({required this.result})
    : super(step: PriceRuleImportStep.result);

  final CustomerPriceRuleImportResultDto result;

  @override
  List<Object?> get props => [...super.props, result.batch.importedRows];
}

final class PriceRuleImportError extends PriceRuleImportState {
  const PriceRuleImportError({
    required this.code,
    required super.step,
  });

  final String code;

  @override
  List<Object?> get props => [...super.props, code];
}
