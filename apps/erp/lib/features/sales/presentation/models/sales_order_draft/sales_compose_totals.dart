import 'package:equatable/equatable.dart';

import 'sales_compose_line_vm.dart';

/// Tóm tắt thanh toán SG-02 — **một** định nghĩa duy nhất cho mọi surface
/// (summary bar, thẻ tóm tắt, checkout preflight).
///
/// Công thức card (không có giảm cấp đơn trong MVP):
/// - Mỗi dòng so sánh **giá niêm yết** ([SalesComposeLineVm.listAmountMinor]) với
///   **tiền bán** ([SalesComposeLineVm.lineTotalMinor]):
///   - bán > niêm yết → phần chênh cộng vào [merchandiseAmountMinor]
///   - bán < niêm yết → phần chênh cộng vào [discountMinor]
/// - [merchandiseAmountMinor] = Σ max(niêm yết, tiền bán)
/// - [discountMinor] = Σ max(0, niêm yết − tiền bán) (+ giảm cấp đơn nếu có)
/// - [netAmountMinor] = merchandise − discount (= Σ tiền bán − giảm cấp đơn)
final class SalesComposeTotals extends Equatable {
  const SalesComposeTotals({
    required this.itemCount,
    required this.merchandiseAmountMinor,
    required this.discountMinor,
    required this.netAmountMinor,
  });

  factory SalesComposeTotals.fromLines(
    List<SalesComposeLineVm> lines, {
    int orderDiscountMinor = 0,
  }) {
    var itemCount = 0;
    var merchandise = 0;
    var lineDiscount = 0;
    for (final line in lines) {
      itemCount += line.input.quantity;
      final listAmt = line.listAmountMinor;
      final soldAmt = line.lineTotalMinor;
      merchandise += listAmt > soldAmt ? listAmt : soldAmt;
      if (listAmt > soldAmt) {
        lineDiscount += listAmt - soldAmt;
      }
    }
    final orderDiscount = orderDiscountMinor < 0 ? 0 : orderDiscountMinor;
    final discount = lineDiscount + orderDiscount;
    final net = merchandise - discount;
    return SalesComposeTotals(
      itemCount: itemCount,
      merchandiseAmountMinor: merchandise,
      discountMinor: discount,
      netAmountMinor: net < 0 ? 0 : net,
    );
  }

  static const empty = SalesComposeTotals(
    itemCount: 0,
    merchandiseAmountMinor: 0,
    discountMinor: 0,
    netAmountMinor: 0,
  );

  /// Tổng số lượng sản phẩm trong đơn.
  final int itemCount;

  /// Tổng tiền hàng: Σ max(niêm yết, tiền bán) — phần giá riêng cao hơn list
  /// đã được cộng vào đây.
  final int merchandiseAmountMinor;

  /// Giảm giá: Σ (niêm yết − tiền bán) khi bán thấp hơn list (+ giảm cấp đơn).
  final int discountMinor;

  /// Thành tiền = [merchandiseAmountMinor] − [discountMinor].
  final int netAmountMinor;

  @override
  List<Object?> get props => [
    itemCount,
    merchandiseAmountMinor,
    discountMinor,
    netAmountMinor,
  ];
}
