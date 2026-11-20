import '../../../core/errors/app_exception.dart';
import '../data/pricing_errors.dart';

const Map<String, String> _pricingMessages = {
  PricingErrorCodes.noPermission: 'Bạn không có quyền thực hiện thao tác này.',
  PricingErrorCodes.validationError: 'Thông tin nhập không hợp lệ.',
  PricingErrorCodes.referenceInvalid: 'Khách hàng hoặc sản phẩm không hợp lệ.',
  PricingErrorCodes.belowFloorBlocked: 'Giá nhập thấp hơn giá sàn quy định.',
  PricingErrorCodes.duplicateActiveRule:
      'Đã có giá riêng khác đang áp dụng cho cùng khách hàng và sản phẩm.',
  PricingErrorCodes.stateChanged: 'Dữ liệu đã thay đổi. Vui lòng tải lại.',
  PricingErrorCodes.invalidStatus:
      'Không thể thực hiện với trạng thái hiện tại.',
  PricingErrorCodes.notFound: 'Mức giá riêng không còn tồn tại.',
  PricingErrorCodes.idempotencyConflict:
      'Không thể lưu giá riêng. Vui lòng thử lại.',
  PricingErrorCodes.systemError: 'Đã xảy ra lỗi. Vui lòng thử lại.',
};

/// TH-04 mục 6.4. [overrides] để màn giữ câu riêng đã có cho một mã.
String pricingErrorMessage(
  Object error, {
  required String fallback,
  Map<String, String> overrides = const {},
}) {
  final code = error is AppException ? error.code : PricingErrorCodes.systemError;
  return overrides[code] ?? _pricingMessages[code] ?? fallback;
}

