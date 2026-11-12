import 'package:erp/features/inventory/logic/reports/reports_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('movement_label_table', () {
    expect(movementLabel('RECEIPT', 'GOODS_RECEIPT', null), 'Nhận hàng');
    expect(movementLabel('SALE', 'SALES_ORDER', null), 'Bán hàng');
    expect(movementLabel('SALE', 'RETURN_EXCHANGE', null), 'Đổi hàng');
    expect(movementLabel('SALE_REVERSAL', 'SALES_CANCELLATION', null), 'Huỷ đơn');
    expect(movementLabel('SALE_REVERSAL', 'RETURN_EXCHANGE', null), 'Trả hàng');
    expect(movementLabel('RETURN_IN', 'RETURN_EXCHANGE', null), 'Trả hàng');
    expect(movementLabel('COUNT_GAIN', 'STOCKTAKE', 'COUNT'), 'Kiểm kê thừa');
    expect(movementLabel('COUNT_LOSS', 'STOCKTAKE', 'COUNT'), 'Kiểm kê thiếu');
    expect(movementLabel('COUNT_LOSS', 'STOCKTAKE', null), 'Kiểm kê thiếu');
    expect(movementLabel('WRITE_OFF', 'STOCKTAKE', 'DAMAGED'), 'Hỏng');
    expect(movementLabel('WRITE_OFF', 'STOCKTAKE', 'EXPIRED'), 'Hết hạn');
    expect(movementLabel('COUNT_LOSS', 'STOCKTAKE', 'LOSS'), 'Thất thoát');
  });

  test('signed_qty', () {
    expect(signedQty(20), '+20');
    expect(signedQty(-2), '−2');
    expect(signedQty(0), '0');
    expect(signedQty(1.5), '+1,5');
  });

  test('margin_text', () {
    expect(marginText(35.2), '35,2%');
    expect(marginText(33), '33,0%');
    expect(marginText(null), '—');
  });

  test('as_of_text', () {
    expect(asOfText(DateTime(2026, 11, 13, 9, 5)), '13/11/2026 · 09:05');
  });
}
