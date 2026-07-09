String formatProductChangeHistoryDateTime(DateTime occurredAt) {
  final local = occurredAt.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

String formatProductChangeHistorySummary({
  required String summary,
  required String changeType,
}) {
  final fromSummary = _vietnameseSummaryFromToken(summary);
  if (fromSummary != null) {
    return fromSummary;
  }

  final fromChangeType = _vietnameseSummaryFromToken(changeType);
  if (fromChangeType != null) {
    return fromChangeType;
  }

  final trimmed = summary.trim();
  if (trimmed.isNotEmpty) {
    return trimmed;
  }

  return changeType;
}

String? _vietnameseSummaryFromToken(String raw) {
  final token = raw.trim().toLowerCase();
  return switch (token) {
    'created' || 'product_created' => 'Tạo sản phẩm',
    'update_product_profile' || 'product_profile_updated' => 'Cập nhật hồ sơ sản phẩm',
    'update_product_images' || 'product_images_updated' => 'Cập nhật ảnh sản phẩm',
    'set_product_unit_price_band' || 'set_initial_price_band' => 'Cập nhật khung giá',
    'set_manual_base_price' => 'Cập nhật giá cơ sở',
    'apply_store_price_rule' => 'Áp dụng khung giá cửa hàng',
    'set_initial_stock' || 'adjust_basic_stock' => 'Cập nhật tồn kho',
    'product_status_changed' => 'Thay đổi trạng thái kinh doanh',
    'product_soft_deleted' => 'Ẩn sản phẩm',
    'product_restored' => 'Khôi phục sản phẩm',
    _ => null,
  };
}
