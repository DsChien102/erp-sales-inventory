import 'money_dto.dart';
import 'quantity_dto.dart';

final class CheckoutLineInput {
  const CheckoutLineInput({
    required this.productId,
    required this.productUnitId,
    required this.quantity,
    this.unitPrice,
    this.note,
    this.manualUnitPriceMinor,
    this.manualDiscountMinor,
    this.manualDiscountBasisPoints,
  });

  final String productId;
  final String productUnitId;
  final QuantityDto quantity;
  final MoneyDto? unitPrice;
  final String? note;

  /// Lựa chọn điều chỉnh của nhân viên — server tự tính giá từ đây (không tin `unitPrice`).
  final int? manualUnitPriceMinor;
  final int? manualDiscountMinor;
  final int? manualDiscountBasisPoints;
}
