import 'package:erp/core/errors/app_exception.dart';

/// 14 mã lỗi lõi của backend Kho (mục 2.5).
abstract final class InventoryErrorCode {
  static const permissionDenied = AppErrorCode.noPermission;
  static const contextInvalid = 'CONTEXT_INVALID';
  static const dataScopeDenied = 'DATA_SCOPE_DENIED';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const commandInProgress = 'COMMAND_IN_PROGRESS';
  static const versionConflict = 'VERSION_CONFLICT';
  static const insufficientStock = 'INSUFFICIENT_STOCK';
  static const lotRequired = 'LOT_REQUIRED';
  static const lotNotAllowed = 'LOT_NOT_ALLOWED';
  static const expiryRequired = 'EXPIRY_REQUIRED';
  static const lotAttributeConflict = 'LOT_ATTRIBUTE_CONFLICT';
  static const trackingLocked = 'TRACKING_LOCKED';
  static const unitCostRequired = 'UNIT_COST_REQUIRED';
  static const periodClosed = 'PERIOD_CLOSED';
}

/// Chuyển đổi mã lỗi sang thông báo thân thiện người dùng tiếng Việt.
String inventoryErrorMessage(
  AppException error, {
  required String fallback,
  Map<String, String> overrides = const {},
}) {
  if (overrides.containsKey(error.code)) {
    return overrides[error.code]!;
  }
  return switch (error.code) {
    InventoryErrorCode.permissionDenied =>
      'Bạn không có quyền thực hiện thao tác này.',
    InventoryErrorCode.contextInvalid =>
      'Dữ liệu hoặc ngữ cảnh yêu cầu không hợp lệ.',
    InventoryErrorCode.dataScopeDenied =>
      'Bạn không có quyền thao tác trên kho này.',
    InventoryErrorCode.idempotencyConflict =>
      'Yêu cầu bị trùng lặp với nội dung khác.',
    InventoryErrorCode.commandInProgress =>
      'Yêu cầu đang được xử lý, vui lòng chờ trong giây lát.',
    InventoryErrorCode.versionConflict =>
      'Dữ liệu đã bị thay đổi bởi người khác, vui lòng thử lại.',
    InventoryErrorCode.insufficientStock =>
      'Tồn kho không đủ để thực hiện thao tác.',
    InventoryErrorCode.lotRequired =>
      'Sản phẩm yêu cầu nhập thông tin lô.',
    InventoryErrorCode.lotNotAllowed =>
      'Sản phẩm không quản lý theo lô.',
    InventoryErrorCode.expiryRequired =>
      'Sản phẩm bắt buộc phải có hạn dùng.',
    InventoryErrorCode.lotAttributeConflict =>
      'Thông tin hạn dùng bị xung đột với lô đã có.',
    InventoryErrorCode.trackingLocked =>
      'Đã có biến động kho, không đổi được.',
    InventoryErrorCode.unitCostRequired =>
      'Bắt buộc phải nhập đơn giá vốn.',
    InventoryErrorCode.periodClosed =>
      'Kỳ giá vốn đã đóng, không thể ghi sổ.',
    _ => fallback,
  };
}
