import 'package:test/test.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_canonical_mapper.dart';

void main() {
  group('S2 end-to-end from real Sales source', () {
    // Đơn 150.000đ: 1 dòng, gross 150000, chiết khấu 0, line_total 150000.
    // GD-3: VND minor unit = đồng, totalAmount phải là 150000 chứ không phải 1500.
    // buyerAddress khớp mặc định SQL build_canonical_invoice khi snapshot thiếu địa chỉ.
    final canonical = <String, Object?>{
      'modelVersion': '1.0.0',
      'invSeries': '1C26TAA',
      'signType': 2,
      'invDate': '2026-09-14',
      'currencyCode': 'VND',
      'exchangeRate': 1,
      'paymentMethodName': 'TM/CK',
      'buyerLegalName': 'Bán cho người tiêu dùng',
      'buyerAddress': 'Việt Nam',
      'totalSaleAmount': 150000,
      'totalDiscountAmount': 0,
      'totalVatAmount': 0,
      'totalAmount': 150000,
      'taxRateInfo': [
        {'vatRateName': 'KCT', 'turnover': 150000, 'vatAmount': 0},
      ],
      'originalInvoiceDetail': [
        {
          'lineNumber': 1,
          'sortOrder': 1,
          'vatRateName': 'KCT',
          'vatAmount': 0,
          'itemName': 'Thức ăn cho chó 1kg',
          'itemCode': 'SKU-001',
          'unitName': 'Túi',
          'quantity': 2.0,
          'unitPrice': 75000,
          'amount': 150000,
          'discountAmount': 0,
          'amountWithoutVat': 150000,
        },
      ],
    };

    test('canonical from real order passes mapper validation', () {
      expect(
        () => MeInvoiceCanonicalMapper.validate(canonical),
        returnsNormally,
      );
    });

    test('canonical from real order maps to MISA wire with KCT tax rate', () {
      final invoice = MeInvoiceCanonicalMapper.toPreviewInvoice(canonical);

      expect(invoice.originalInvoiceDetail, hasLength(1));
      final line = invoice.originalInvoiceDetail!.first;
      expect(line.itemName, equals('Thức ăn cho chó 1kg'));
      expect(line.itemCode, equals('SKU-001'));
      expect(line.unitName, equals('Túi'));
      expect(line.quantity, equals(2.0));
      expect(line.amount, equals(150000));
      expect(line.amountWithoutVat, equals(150000));
      // ADR-TH08-KCT: MISA bắt buộc TaxRateInfo (sandbox 2026-09-14 từ chối
      // payload thiếu khoá này), trong khi không theme nào sở hữu cấu hình
      // thuế suất. Quyết định của chủ dự án: gán KCT, tiền thuế 0.
      expect(line.vatRateName, equals('KCT'));
      expect(line.vatAmount, equals(0));
      expect(invoice.taxRateInfo, hasLength(1));
      expect(invoice.taxRateInfo!.first.vatRateName, equals('KCT'));
      expect(invoice.taxRateInfo!.first.vatAmountOc, equals(0));
      expect(
        invoice.taxRateInfo!.first.amountWithoutVatOc,
        equals(150000),
        reason: 'turnover = tổng tiền không thuế = số tiền đã thu',
      );
    });

    test('missing taxRateInfo is rejected locally, not by MISA', () {
      final withoutTax = Map<String, dynamic>.from(canonical)
        ..remove('taxRateInfo');

      expect(
        () => MeInvoiceCanonicalMapper.validate(withoutTax),
        throwsA(
          isA<CanonicalValidationFault>().having(
            (f) => f.reasonCode,
            'reasonCode',
            'CANONICAL_MISSING_TAX_RATES',
          ),
        ),
        reason: 'chặn tại chỗ, không để payload đi 3 vòng tới MISA rồi về',
      );
    });

    test('money keeps VND minor unit as dong (GD-3)', () {
      final invoice = MeInvoiceCanonicalMapper.toPreviewInvoice(canonical);
      expect(invoice.totalAmount, equals(150000));
      expect(invoice.totalAmount, isNot(equals(1500)));
    });

    test('totals identity holds', () {
      final sale = canonical['totalSaleAmount'] as int;
      final discount = canonical['totalDiscountAmount'] as int;
      final total = canonical['totalAmount'] as int;
      expect(sale - discount, equals(total));
    });

    // GD-2: Amount = trước chiết khấu, AmountWithoutVAT = sau chiết khấu.
    // Mapper có fallback chép amount → amountWithoutVat khi trường này vắng
    // (me_invoice_canonical_mapper.dart). Với dòng có chiết khấu,
    // fallback đó cho ra sai lệch đúng bằng tiền chiết khấu. Builder luôn đặt
    // amountWithoutVat tường minh nên nhánh đó không được phép chạy.
    test('discounted line keeps Amount gross and AmountWithoutVAT net', () {
      final discounted = <String, Object?>{
        ...canonical,
        'totalSaleAmount': 100000,
        'totalDiscountAmount': 10000,
        'totalAmount': 90000,
        'taxRateInfo': [
          {'vatRateName': 'KCT', 'turnover': 90000, 'vatAmount': 0},
        ],
        'originalInvoiceDetail': [
          {
            'lineNumber': 1,
            'sortOrder': 1,
            'vatRateName': 'KCT',
            'vatAmount': 0,
            'itemName': 'Hàng có chiết khấu',
            'unitName': 'Cái',
            'quantity': 1.0,
            'unitPrice': 100000,
            'amount': 100000,
            'discountAmount': 10000,
            'amountWithoutVat': 90000,
          },
        ],
      };

      final invoice = MeInvoiceCanonicalMapper.toPreviewInvoice(discounted);
      final line = invoice.originalInvoiceDetail!.first;

      expect(
        line.amount,
        equals(100000),
        reason: 'Amount phải là tiền TRƯỚC chiết khấu',
      );
      expect(line.discountAmount, equals(10000));
      expect(
        line.amountWithoutVat,
        equals(90000),
        reason: 'AmountWithoutVAT là tiền SAU chiết khấu',
      );
      expect(
        line.amountWithoutVat,
        isNot(equals(line.amount)),
        reason:
            'fallback amount→amountWithoutVat không được phép chạy cho dòng có chiết khấu',
      );
    });
  });
}
