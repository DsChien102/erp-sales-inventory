import 'money_dto.dart';
import 'quantity_dto.dart';

final class CheckoutLineInput {
  const CheckoutLineInput({
    required this.productId,
    required this.productUnitId,
    required this.quantity,
    this.unitPrice,
    this.note,
  });

  final String productId;
  final String productUnitId;
  final QuantityDto quantity;
  final MoneyDto? unitPrice;
  final String? note;
}
