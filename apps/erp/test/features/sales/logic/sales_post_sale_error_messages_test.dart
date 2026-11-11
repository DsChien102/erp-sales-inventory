import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/logic/sales_post_sale_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/data/models.dart';

void main() {
  group('salesPostSaleErrorMessage (Table A)', () {
    const fallback = 'Lỗi mặc định.';

    test('maps all Table A codes to expected Vietnamese messages', () {
      final expectedTableA = <String, String>{
        'NO_PERMISSION': 'Bạn không có quyền thực hiện thao tác này.',
        'DATA_SCOPE_DENIED': 'Cửa hàng hiện tại không còn khả dụng.',
        'CONTEXT_INVALID': 'Dữ liệu không hợp lệ.',
        'FIELD_NOT_ALLOWED': 'Dữ liệu không hợp lệ.',
        'IDEMPOTENCY_CONFLICT': 'Yêu cầu bị xung đột',
        'IN_PROGRESS': 'Yêu cầu đang được xử lý, vui lòng chờ.',
        'STALE_VERSION': 'Đơn hàng đã thay đổi. Hãy tải lại chi tiết rồi thử lại.',
        'NOT_FOUND': 'Đơn hàng không tồn tại hoặc đã bị xóa.',
        'COMPETING_CANCELLATION': 'Đơn đã được hủy.',
        'RETURN_EXCHANGE_BLOCKED': 'Không thể đổi/trả.',
        'RETURN_QUANTITY_EXCEEDED': 'Số lượng trả vượt số còn có thể trả.',
        'INVALID_QUANTITY': 'Số lượng không hợp lệ với đơn vị bán.',
        'PRODUCT_NOT_SELLABLE': 'Sản phẩm đã ngừng bán. Vui lòng quay lại đơn.',
        'PRICING_BLOCKED': 'Sản phẩm này chưa có giá bán.',
        'INSUFFICIENT_STOCK': 'Không đủ tồn kho để đổi hàng.',
        'NETWORK_ERROR': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.',
      };

      for (final entry in expectedTableA.entries) {
        final result = salesPostSaleErrorMessage(
          AppException(entry.key, serverMessage: 'Server English message'),
          fallback: fallback,
        );
        expect(result, equals(entry.value), reason: 'Code ${entry.key} must match Table A');
        expect(result.contains('Server English'), isFalse);
      }
    });

    test('codes not in Table A return fallback', () {
      final fallbackCodes = [
        'DEPENDENCY_UNAVAILABLE',
        'SYSTEM_ERROR',
        'WEIRD_UNKNOWN_CODE',
        'CANCELLATION_BLOCKED',
        'PRICE_CHANGED',
      ];

      for (final code in fallbackCodes) {
        final result = salesPostSaleErrorMessage(
          AppException(code, serverMessage: 'Some error message'),
          fallback: fallback,
        );
        expect(result, equals(fallback), reason: 'Code $code should return fallback');
      }
    });

    test('overrides take precedence over Table A and fallback', () {
      final result1 = salesPostSaleErrorMessage(
        AppException('PRICE_CHANGED'),
        fallback: fallback,
        overrides: {'PRICE_CHANGED': 'Giá đã thay đổi, vui lòng tính lại.'},
      );
      expect(result1, equals('Giá đã thay đổi, vui lòng tính lại.'));

      final result2 = salesPostSaleErrorMessage(
        AppException('NOT_FOUND'),
        fallback: fallback,
        overrides: {'NOT_FOUND': 'Ghi đè không tìm thấy.'},
      );
      expect(result2, equals('Ghi đè không tìm thấy.'));
    });

    test('non-AppException errors return fallback', () {
      expect(salesPostSaleErrorMessage(StateError('boom'), fallback: fallback), equals(fallback));
      expect(salesPostSaleErrorMessage(Exception('boom'), fallback: fallback), equals(fallback));
      expect(salesPostSaleErrorMessage('raw string', fallback: fallback), equals(fallback));
    });

    test('AppException serverMessage is ignored when code is mapped', () {
      final result = salesPostSaleErrorMessage(
        AppException('NOT_FOUND', serverMessage: 'Sales order not found.'),
        fallback: fallback,
      );
      expect(result, equals('Đơn hàng không tồn tại hoặc đã bị xóa.'));
      expect(result.contains('Sales'), isFalse);
    });
  });

  group('salesBlockerMessage (Table B)', () {
    const fallback = 'Không thể thực hiện.';

    test('maps all Table B blocker codes to expected messages', () {
      final expectedTableB = <String, String>{
        'PAYMENT_ALREADY_COLLECTED': 'Đơn đã có thanh toán, vui lòng đổi/trả',
        'ORDER_ALREADY_CANCELLED': 'Đơn đã được hủy.',
        'COMPETING_CANCELLATION': 'Đơn đã được hủy.',
        'RETURN_EXCHANGE_CONFLICT': 'Đơn đã có phiếu đổi/trả, không thể hủy.',
        'DRAFT_RETURN_ACTIVE': 'Đơn đang có phiếu đổi/trả chưa hoàn tất.',
      };

      for (final entry in expectedTableB.entries) {
        final blocker = SalesBlockerDto(
          code: entry.key,
          message: 'English server message: ${entry.key}',
          field: 'field_${entry.key}',
        );
        final result = salesBlockerMessage(blocker, fallback: fallback);
        expect(result, equals(entry.value));
        expect(result.contains('English'), isFalse);
      }
    });

    test('unrecognized blocker codes return fallback', () {
      final unknownCodes = [
        'CANCELLATION_BLOCKED',
        'RETURN_EXCHANGE_BLOCKED',
        'DEPENDENCY_UNAVAILABLE',
        'UNKNOWN_BLOCKER',
      ];

      for (final code in unknownCodes) {
        final blocker = SalesBlockerDto(code: code, message: 'Server blocker');
        expect(salesBlockerMessage(blocker, fallback: fallback), equals(fallback));
      }
    });
  });

  group('localizeBlockers', () {
    const fallback = 'Không thể đổi/trả.';

    test('preserves code and field, localizes message, deduplicates identical messages', () {
      final blockers = [
        SalesBlockerDto(
          code: 'PAYMENT_ALREADY_COLLECTED',
          message: 'Net confirmed collection must be zero',
          field: 'payment',
        ),
        SalesBlockerDto(
          code: 'ORDER_ALREADY_CANCELLED',
          message: 'Order was already cancelled',
          field: 'status',
        ),
        SalesBlockerDto(
          code: 'COMPETING_CANCELLATION',
          message: 'Cancellation already in progress',
          field: 'status',
        ),
        SalesBlockerDto(
          code: 'CUSTOM_BLOCKER_1',
          message: 'Custom message 1',
        ),
        SalesBlockerDto(
          code: 'CUSTOM_BLOCKER_2',
          message: 'Custom message 2',
        ),
      ];

      final localized = localizeBlockers(blockers, fallback: fallback);

      // 'ORDER_ALREADY_CANCELLED' and 'COMPETING_CANCELLATION' map to the same message: 'Đơn đã được hủy.'
      // 'CUSTOM_BLOCKER_1' and 'CUSTOM_BLOCKER_2' both map to fallback: 'Không thể đổi/trả.'
      // Deduplication should leave 3 blockers:
      // 1. PAYMENT_ALREADY_COLLECTED -> 'Đơn đã có thanh toán, vui lòng đổi/trả'
      // 2. ORDER_ALREADY_CANCELLED -> 'Đơn đã được hủy.'
      // 3. CUSTOM_BLOCKER_1 -> 'Không thể đổi/trả.'
      expect(localized.length, equals(3));

      expect(localized[0].code, equals('PAYMENT_ALREADY_COLLECTED'));
      expect(localized[0].field, equals('payment'));
      expect(localized[0].message, equals('Đơn đã có thanh toán, vui lòng đổi/trả'));

      expect(localized[1].code, equals('ORDER_ALREADY_CANCELLED'));
      expect(localized[1].field, equals('status'));
      expect(localized[1].message, equals('Đơn đã được hủy.'));

      expect(localized[2].code, equals('CUSTOM_BLOCKER_1'));
      expect(localized[2].message, equals(fallback));
    });
  });
}

