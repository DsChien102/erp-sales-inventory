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
  static const programOverlap = 'PROGRAM_OVERLAP';
  static const programSupplierInvalid = 'PROGRAM_SUPPLIER_INVALID';
  static const programUomMismatch = 'PROGRAM_UOM_MISMATCH';
  static const programLocked = 'PROGRAM_LOCKED';
  static const supplierRequired = 'SUPPLIER_REQUIRED';
  static const supplierInvalid = 'SUPPLIER_INVALID';
  static const receiptProgramChanged = 'RECEIPT_PROGRAM_CHANGED';
  static const receiptDiscountTooLarge = 'RECEIPT_DISCOUNT_TOO_LARGE';
  static const stocktakeScopeEmpty = 'STOCKTAKE_SCOPE_EMPTY';
  static const stocktakeStateChanged = 'STOCKTAKE_STATE_CHANGED';
  static const stocktakeCountMissing = 'STOCKTAKE_COUNT_MISSING';
  static const stocktakeLineExists = 'STOCKTAKE_LINE_EXISTS';
  static const cancelReasonRequired = 'CANCEL_REASON_REQUIRED';
  static const programNotReached = 'PROGRAM_NOT_REACHED';
  static const rebateAmountInvalid = 'REBATE_AMOUNT_INVALID';
  static const rebateReasonRequired = 'REBATE_REASON_REQUIRED';
  static const costRunStale = 'COST_RUN_STALE';
  static const costRunNotReady = 'COST_RUN_NOT_READY';
  static const costPolicyLocked = 'COST_POLICY_LOCKED';
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
    InventoryErrorCode.programOverlap =>
      'NCC này đang có chương trình khác đang chạy. Kết thúc chương trình đó trước khi tạo chương trình mới.',
    InventoryErrorCode.programSupplierInvalid =>
      'Nhà cung cấp không hợp lệ hoặc đã ngừng hoạt động.',
    InventoryErrorCode.programUomMismatch =>
      'Các sản phẩm phải cùng đơn vị tính cơ sở.',
    InventoryErrorCode.programLocked =>
      'Chương trình đã có phiếu nhận gắn hoặc đã kết thúc nên không sửa được.',
    InventoryErrorCode.supplierRequired =>
      'Chọn nhà cung cấp',
    InventoryErrorCode.supplierInvalid =>
      'Nhà cung cấp không hợp lệ hoặc đã ngừng hoạt động.',
    InventoryErrorCode.receiptProgramChanged =>
      'Ưu đãi của nhà cung cấp vừa thay đổi. Đã cập nhật lại gợi ý, kiểm tra rồi ghi nhận lại.',
    InventoryErrorCode.receiptDiscountTooLarge =>
      'Chiết khấu không được lớn hơn tổng giá mua và chi phí',
    InventoryErrorCode.stocktakeScopeEmpty =>
      'Kho chưa có hàng trong phạm vi này để kiểm kê.',
    InventoryErrorCode.stocktakeStateChanged =>
      'Người khác vừa nộp phiên này',
    InventoryErrorCode.stocktakeCountMissing => 'Nhập số đếm được',
    InventoryErrorCode.stocktakeLineExists => 'Mặt hàng này đã có trong phiên.',
    InventoryErrorCode.cancelReasonRequired => 'Nhập lý do hủy phiên',
    InventoryErrorCode.programNotReached =>
      'Chương trình chưa đạt mốc hoặc đã ghi nhận chiết khấu.',
    InventoryErrorCode.rebateAmountInvalid =>
      'Số tiền ghi nhận phải từ 1 đ đến tổng tiền mua.',
    InventoryErrorCode.rebateReasonRequired =>
      'Nhập lý do khi số tiền khác đề xuất.',
    InventoryErrorCode.costRunStale =>
      'Dữ liệu đầu vào đã thay đổi. Hãy tạo lần tính kế tiếp.',
    InventoryErrorCode.costRunNotReady =>
      'Lần tính không còn ở trạng thái chờ công bố.',
    InventoryErrorCode.costPolicyLocked =>
      'Đã công bố giá vốn nên không đổi được phương pháp.',
    _ => fallback,
  };
}
