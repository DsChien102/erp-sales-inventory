import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';

enum ReportStatus { loading, ready, denied, error }

/// Phân loại lỗi tải báo cáo: `PERMISSION_DENIED` ⇒ `denied`, còn lại ⇒ `error` kèm câu báo.
({ReportStatus status, String? message}) classifyReportError(
  Object error, {
  required String fallback,
}) {
  final ex = AppException.from(error);
  if (ex.code == InventoryErrorCode.permissionDenied) {
    return (status: ReportStatus.denied, message: null);
  }
  return (
    status: ReportStatus.error,
    message: inventoryErrorMessage(ex, fallback: fallback),
  );
}
