import 'package:vet45_pricing_application/application.dart';

/// Chuyển mã lỗi/cảnh báo import giá riêng thành nội dung tiếng Việt.
abstract final class PriceRuleImportIssueFormatter {
  static String errorMessage(
    String code,
    CustomerPriceRuleImportRowPreviewDto row,
  ) => _knownMessage(code, row) ?? 'Lỗi chưa xác định ($code).';

  static String warningMessage(
    String code,
    CustomerPriceRuleImportRowPreviewDto row,
  ) => _knownMessage(code, row) ?? 'Cảnh báo chưa xác định ($code).';

  static String? _knownMessage(
    String code,
    CustomerPriceRuleImportRowPreviewDto row,
  ) => switch (code) {
    'IMPORT_MODE_MISMATCH' =>
      'Dòng dữ liệu không phù hợp với chế độ import đã chọn.',
    'INVALID_RULE_ID' => 'Mã giá riêng không đúng định dạng.',
    'REFERENCE_INVALID' => 'Không tìm thấy khách hàng hoặc sản phẩm hợp lệ.',
    'AMBIGUOUS_PRODUCT_UNIT' =>
      'Không thể xác định duy nhất đơn vị cơ sở đang hoạt động của sản phẩm.',
    'INVALID_PRICE' => 'Giá riêng phải là số nguyên lớn hơn 0.',
    'EFFECTIVE_FROM_DEFAULTED' =>
      'Ngày bắt đầu để trống, hệ thống sẽ dùng ngày hiện tại.',
    'INVALID_DATE' =>
      'Ngày hiệu lực không hợp lệ. Hãy dùng định dạng YYYY-MM-DD.',
    'INVALID_PERIOD' => 'Ngày kết thúc phải từ ngày bắt đầu trở đi.',
    'NOTE_TOO_LONG' => 'Ghi chú không được vượt quá 500 ký tự.',
    'RULE_KEY_MISMATCH' =>
      'Khách hàng hoặc sản phẩm không khớp với giá riêng cần cập nhật.',
    'BELOW_FLOOR_PRICE' => _belowFloorMessage(row, isBlocked: false),
    'BELOW_FLOOR_BLOCKED' => _belowFloorMessage(row, isBlocked: true),
    'DUPLICATE_ACTIVE_RULE' =>
      'Đã tồn tại giá riêng đang hoạt động trùng thời gian.',
    'STATE_CHANGED' =>
      'Dữ liệu đã thay đổi sau bước kiểm tra. Vui lòng kiểm tra lại file.',
    _ => null,
  };

  static String _belowFloorMessage(
    CustomerPriceRuleImportRowPreviewDto row, {
    required bool isBlocked,
  }) {
    final price = row.normalizedPriceMinor;
    final floor = _intValue(row.productSnapshot?['floor_price_minor']);
    final suffix = isBlocked ? ' và bạn không có quyền ghi đè' : '';
    if (price == null || floor == null) {
      return 'Giá riêng thấp hơn giá sàn$suffix.';
    }
    return 'Giá riêng ${_formatMoney(price)} thấp hơn giá sàn '
        '${_formatMoney(floor)}$suffix.';
  }

  static int? _intValue(Object? value) => switch (value) {
    int() => value,
    num() => value.toInt(),
    String() => int.tryParse(value),
    _ => null,
  };

  static String _formatMoney(int value) =>
      '${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
}
