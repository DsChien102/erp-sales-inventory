/// Thông báo giá món đổi dùng chung cho màn đổi/trả và màn quyết toán.
abstract final class SalesReturnExchangePricingCopy {
  /// Màn đổi/trả: giá đã được làm mới ngay trên màn.
  static const priceChanged =
      'Giá món đổi đã thay đổi. Đã cập nhật giá mới, vui lòng kiểm tra lại.';

  /// Màn quyết toán: màn này không làm mới giá; người dùng phải quay lại màn
  /// đổi/trả (màn đó làm mới giá khi quay về).
  static const priceChangedGoBack =
      'Giá món đổi đã thay đổi. Vui lòng quay lại màn đổi/trả để cập nhật giá.';
  static const pricingBlocked = 'Sản phẩm này chưa có giá bán.';
  static const previewFailed = 'Không lấy được giá sản phẩm. Vui lòng thử lại.';
}
