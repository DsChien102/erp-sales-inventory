/// User-facing error message resolver for catalog (TH-02 6.4).
library;

import 'package:erp/core/errors/app_exception.dart';

import '../data/catalog_errors.dart';

/// TH-02 6.4: câu riêng theo nội dung `serverMessage` (chữ thường, `contains`).
/// Thứ tự quan trọng: "already inactive" trước "already active".
const _knownServerMessages = <(String code, String fragment, String text)>[
  (AppErrorCode.validation, 'product name is required', 'Tên nội bộ không được bỏ trống'),
  (AppErrorCode.validation, 'base unit is required for stock or pricing', 'Cần thiết lập đơn vị cơ sở trước.'),
  (AppErrorCode.validation, 'already has a base unit', 'Đơn vị cơ sở không đổi được sau khi đã đặt.'),
  (AppErrorCode.validation, 'conversion rate must be greater than zero', 'Tỷ lệ quy đổi phải > 0'),
  (AppErrorCode.validation, 'base price cannot be negative', 'Giá cơ sở không hợp lệ'),
  (AppErrorCode.validation, 'markup ratios are invalid', 'Tỷ lệ giá sàn không được lớn hơn tỷ lệ giá niêm yết.'),
  (AppErrorCode.validation, 'single select field requires options', 'Cần có ít nhất 1 tùy chọn'),
  (AppErrorCode.validation, 'product is already inactive', 'Sản phẩm đã ngừng kinh doanh.'),
  (AppErrorCode.validation, 'product is already active', 'Sản phẩm đang kinh doanh.'),
  (CatalogErrorCodes.productRestoreBlocked, 'product is not soft-deleted', 'Sản phẩm chưa bị xoá.'),
];

String? _knownServerMessage(AppException error) {
  final message = error.serverMessage?.toLowerCase();
  if (message == null) return null;
  for (final (code, fragment, text) in _knownServerMessages) {
    if (error.code == code && message.contains(fragment)) return text;
  }
  return null;
}

/// [fallback]: câu của thao tác khi mã không có câu riêng (mặc định câu chung 6.4).
String catalogErrorMessage(
  Object error, {
  String fallback = 'Đã xảy ra lỗi. Vui lòng thử lại.',
}) {
  if (error is! AppException) return fallback;

  final known = _knownServerMessage(error);
  if (known != null) return known;

  final value = error.details?['value'] as String? ?? '';

  return switch (error.code) {
    AppErrorCode.noPermission || AppErrorCode.authRequired => 'Bạn không có quyền thực hiện thao tác này.',
    CatalogErrorCodes.productNotFound => 'Sản phẩm không tồn tại hoặc đã bị xoá.',
    CatalogErrorCodes.staleProductVersion => 'Sản phẩm đã được cập nhật ở nơi khác. Vui lòng tải lại.',
    CatalogErrorCodes.duplicateSku => 'SKU "$value" đã được sử dụng',
    CatalogErrorCodes.duplicateBarcode => 'Barcode "$value" đã được sử dụng',
    CatalogErrorCodes.productNameRequired => 'Tên nội bộ không được bỏ trống',
    CatalogErrorCodes.productSoftDeleted => 'Sản phẩm đã bị xoá, không sửa được.',
    CatalogErrorCodes.missingBaseUnit => 'Cần thiết lập đơn vị cơ sở trước.',
    CatalogErrorCodes.duplicateProductUnit => 'Đơn vị "$value" đã có trong sản phẩm.',
    CatalogErrorCodes.conversionUnitDeleteBlocked => error.serverMessage ?? fallback,
    CatalogErrorCodes.inactiveProductUnit => 'Đơn vị bán đang không hoạt động.',
    CatalogErrorCodes.staleStockQuantity =>
      'Tồn kho hiện tại đã thay đổi. Vui lòng tải lại dữ liệu trước khi điều chỉnh.',
    CatalogErrorCodes.invalidStockQuantity => 'Tồn kho phải là số nguyên không âm.',
    CatalogErrorCodes.floorGreaterThanList => 'Giá sàn không được lớn hơn giá niêm yết.',
    CatalogErrorCodes.staleBasePrice => 'Giá cơ sở vừa thay đổi. Vui lòng tải lại.',
    CatalogErrorCodes.missingBasePrice => 'Sản phẩm chưa có giá cơ sở.',
    CatalogErrorCodes.storePriceRuleNotFound => 'Cửa hàng chưa cấu hình khung giá.',
    CatalogErrorCodes.storePriceRuleInactive => 'Khung giá cửa hàng đang tắt.',
    CatalogErrorCodes.duplicateCustomFieldGroupName => 'Tên nhóm đã tồn tại.',
    CatalogErrorCodes.duplicateCustomFieldName => 'Tên trường đã tồn tại trong nhóm.',
    CatalogErrorCodes.trackingLocked => 'Đã có biến động kho, không đổi được.',
    CatalogErrorCodes.customFieldTypeChangeBlocked => 'Không đổi được kiểu dữ liệu do đã có dữ liệu.',
    CatalogErrorCodes.customFieldGroupNotFound || CatalogErrorCodes.customFieldNotFound =>
      'Không tìm thấy nhóm / trường.',
    CatalogErrorCodes.productDeleteBlocked || CatalogErrorCodes.productRestoreBlocked =>
      error.serverMessage ?? fallback,
    AppErrorCode.validation => (error.serverMessage?.trim().isNotEmpty ?? false) ? error.serverMessage! : fallback,
    _ => fallback,
  };
}

