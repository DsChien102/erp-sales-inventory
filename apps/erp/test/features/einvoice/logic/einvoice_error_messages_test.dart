import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/logic/einvoice_error_messages.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

void main() {
  group('einvoiceErrorMessage', () {
    test('every row of TH-08 6.4 table maps correctly by code', () {
      expect(
        einvoiceErrorMessage(const AppException('NO_PERMISSION')),
        'Bạn không có quyền thực hiện thao tác này.',
      );
      expect(
        einvoiceErrorMessage(const AppException('STATE_CHANGED')),
        'Trạng thái đơn hàng đã thay đổi. Vui lòng tải lại trang.',
      );
      expect(
        einvoiceErrorMessage(const AppException('TEMPLATE_NOT_AVAILABLE')),
        'Mẫu hóa đơn đã chọn không còn khả dụng. Vui lòng cập nhật cấu hình phát hành.',
      );
      expect(
        einvoiceErrorMessage(const AppException('SIGNING_CONFIGURATION_NOT_AVAILABLE')),
        'Hình thức ký không hợp lệ với mẫu hóa đơn. Vui lòng cập nhật cấu hình phát hành.',
      );
      expect(
        einvoiceErrorMessage(const AppException('UNSUPPORTED_TAX_DATA')),
        'Dữ liệu thuế trên đơn hàng không hợp lệ để phát hành hóa đơn. Vui lòng liên hệ hỗ trợ.',
      );
      expect(
        einvoiceErrorMessage(const AppException('BUYER_ADDRESS_REQUIRED')),
        'Khách tổ chức có mã số thuế nhưng thiếu địa chỉ xuất hóa đơn. Vui lòng bổ sung thông tin người mua.',
      );
      expect(
        einvoiceErrorMessage(const AppException('ORDER_FULLY_RETURNED')),
        'Đơn hàng đã trả hết hàng, không cần xuất hóa đơn.',
      );
      expect(
        einvoiceErrorMessage(const AppException('SOURCE_VERSION_MISMATCH')),
        'Đơn hàng vừa thay đổi (đổi/trả). Vui lòng tải lại rồi phát hành.',
      );
      expect(
        einvoiceErrorMessage(const AppException('CONFIG_NOT_READY')),
        'Chưa chọn mẫu hóa đơn. Vui lòng cập nhật cấu hình phát hành.',
      );
      expect(
        einvoiceErrorMessage(const AppException('ISSUANCE_NOT_READY')),
        'Đơn hàng chưa đủ điều kiện phát hành hóa đơn. Kiểm tra thiết lập hóa đơn điện tử và thông tin người mua.',
      );
      expect(
        einvoiceErrorMessage(const AppException('VALIDATION_ERROR')),
        'Dữ liệu đơn hàng chưa hợp lệ để lập hóa đơn. Vui lòng kiểm tra lại thông tin đơn.',
      );
      expect(
        einvoiceErrorMessage(const AppException('STALE_VERSION')),
        'Đơn hàng vừa được cập nhật. Vui lòng tải lại rồi thử lại.',
      );
      expect(
        einvoiceErrorMessage(const AppException('DELIVERY_NOT_SUPPORTED')),
        'Cổng kết nối hóa đơn chưa hỗ trợ tính năng gửi email.',
      );
      expect(
        einvoiceErrorMessage(const AppException('OPERATION_IN_PROGRESS')),
        'Yêu cầu đang được xử lý, vui lòng chờ giây lát.',
      );
      expect(
        einvoiceErrorMessage(const AppException('NOT_FOUND')),
        'Không tìm thấy hóa đơn điện tử của đơn hàng này.',
      );
      expect(
        einvoiceErrorMessage(const AppException('PROVIDER_UNAVAILABLE')),
        'Cổng kết nối hóa đơn tạm thời không khả dụng. Vui lòng thử lại.',
      );
      expect(
        einvoiceErrorMessage(const AppException('DOCUMENT_UNAVAILABLE')),
        'Tài liệu hóa đơn chưa sẵn sàng. Vui lòng thử lại sau.',
      );
      expect(
        einvoiceErrorMessage(const AppException('NETWORK_ERROR')),
        'Không kết nối được dịch vụ hóa đơn điện tử. Vui lòng thử lại.',
      );
      expect(
        einvoiceErrorMessage(TimeoutException('timeout')),
        'Không kết nối được dịch vụ hóa đơn điện tử. Vui lòng thử lại.',
      );
      expect(
        einvoiceErrorMessage(
          PlatformException(code: 'ACTIVITY_NOT_FOUND', message: 'No activity found to handle intent'),
        ),
        'Không thể mở liên kết xem hóa đơn trên thiết bị. Vui lòng kiểm tra trình duyệt.',
      );
    });

    test('maps by details blockers array', () {
      expect(
        einvoiceErrorMessage(
          const AppException(
            'ISSUANCE_NOT_READY',
            details: {
              'blockers': ['ORDER_FULLY_RETURNED'],
            },
          ),
        ),
        'Đơn hàng đã trả hết hàng, không cần xuất hóa đơn.',
      );
      expect(
        einvoiceErrorMessage(
          const AppException(
            'ISSUANCE_NOT_READY',
            details: {
              'blockers': ['BUYER_ADDRESS_REQUIRED'],
            },
          ),
        ),
        'Khách tổ chức có mã số thuế nhưng thiếu địa chỉ xuất hóa đơn. Vui lòng bổ sung thông tin người mua.',
      );
    });

    test('earlier row wins when multiple blockers are present', () {
      expect(
        einvoiceErrorMessage(
          const AppException(
            'ISSUANCE_NOT_READY',
            details: {
              'blockers': ['BUYER_ADDRESS_REQUIRED', 'ORDER_FULLY_RETURNED'],
            },
          ),
        ),
        'Khách tổ chức có mã số thuế nhưng thiếu địa chỉ xuất hóa đơn. Vui lòng bổ sung thông tin người mua.',
      );
    });

    test('ISSUANCE_NOT_READY without matching blocker returns fallback row', () {
      expect(
        einvoiceErrorMessage(
          const AppException(
            'ISSUANCE_NOT_READY',
            details: {
              'blockers': ['BUYER_TAX_CODE_REQUIRED'],
            },
          ),
        ),
        'Đơn hàng chưa đủ điều kiện phát hành hóa đơn. Kiểm tra thiết lập hóa đơn điện tử và thông tin người mua.',
      );
      expect(
        einvoiceErrorMessage(const AppException('ISSUANCE_NOT_READY')),
        'Đơn hàng chưa đủ điều kiện phát hành hóa đơn. Kiểm tra thiết lập hóa đơn điện tử và thông tin người mua.',
      );
    });

    test('does not return raw serverMessage when no override is given', () {
      expect(
        einvoiceErrorMessage(
          const AppException('ISSUANCE_NOT_READY', serverMessage: 'Không đủ điều kiện xem trước'),
        ),
        'Đơn hàng chưa đủ điều kiện phát hành hóa đơn. Kiểm tra thiết lập hóa đơn điện tử và thông tin người mua.',
      );
    });

    test('overrides take precedence by code', () {
      expect(
        einvoiceErrorMessage(
          const AppException('ISSUANCE_NOT_READY', serverMessage: 'Không đủ điều kiện xem trước'),
          overrides: {'ISSUANCE_NOT_READY': 'Không đủ điều kiện xem trước'},
        ),
        'Không đủ điều kiện xem trước',
      );
    });

    test('unknown error and null return generic fallback', () {
      expect(
        einvoiceErrorMessage(const AppException('X_CODE', serverMessage: 'raw')),
        'Không thể thực hiện thao tác hóa đơn điện tử. Vui lòng thử lại.',
      );
      expect(
        einvoiceErrorMessage(null),
        'Không thể thực hiện thao tác hóa đơn điện tử. Vui lòng thử lại.',
      );
    });

    test('raw strings in AppException do not trigger false positive matching', () {
      expect(
        einvoiceErrorMessage(
          const AppException('SYSTEM_ERROR', serverMessage: 'missing permission scope'),
        ),
        'Không thể thực hiện thao tác hóa đơn điện tử. Vui lòng thử lại.',
      );
      expect(
        einvoiceErrorMessage(
          const AppException('X_CODE', serverMessage: 'PlatformException'),
        ),
        'Không thể thực hiện thao tác hóa đơn điện tử. Vui lòng thử lại.',
      );
    });

    test('// Q1: einvoiceErrorMessage maps einvoiceException(PostgrestException TEMPLATE_NOT_AVAILABLE) to template error message', () {
      final pgEx = const PostgrestException(
        message: 'TEMPLATE_NOT_AVAILABLE: template has no invoice series',
        code: 'P0001',
      );
      final ex = einvoiceException(AppException('SYSTEM_ERROR', cause: pgEx));
      expect(
        einvoiceErrorMessage(ex),
        'Mẫu hóa đơn đã chọn không còn khả dụng. Vui lòng cập nhật cấu hình phát hành.',
      );
    });
  });

  group('einvoiceDeliveryErrorMessage', () {
    test('6 rows of delivery table + PROVIDER_UNAVAILABLE + fallback', () {
      expect(
        einvoiceDeliveryErrorMessage(const AppException('NO_PERMISSION')),
        'Bạn không có quyền gửi hóa đơn điện tử.',
      );
      expect(
        einvoiceDeliveryErrorMessage(const AppException('DELIVERY_NOT_SUPPORTED')),
        'Cổng kết nối hóa đơn chưa hỗ trợ tính năng gửi email.',
      );
      expect(
        einvoiceDeliveryErrorMessage(const AppException('OPERATION_IN_PROGRESS')),
        'Yêu cầu gửi trước đang được xử lý. Vui lòng chờ kết quả.',
      );
      expect(
        einvoiceDeliveryErrorMessage(const AppException('VALIDATION_ERROR')),
        'Email người nhận không hợp lệ. Vui lòng kiểm tra lại.',
      );
      expect(
        einvoiceDeliveryErrorMessage(const AppException('NOT_FOUND')),
        'Không tìm thấy hóa đơn điện tử của đơn hàng này.',
      );
      expect(
        einvoiceDeliveryErrorMessage(const AppException('NETWORK_ERROR')),
        'Không kết nối được dịch vụ gửi hóa đơn. Vui lòng thử lại.',
      );
      expect(
        einvoiceDeliveryErrorMessage(const AppException('PROVIDER_UNAVAILABLE')),
        'Không kết nối được dịch vụ gửi hóa đơn. Vui lòng thử lại.',
      );
      expect(
        einvoiceDeliveryErrorMessage(TimeoutException('timeout')),
        'Không kết nối được dịch vụ gửi hóa đơn. Vui lòng thử lại.',
      );
      expect(
        einvoiceDeliveryErrorMessage(const AppException('UNKNOWN_CODE')),
        einvoiceDeliveryFallbackMessage,
      );
      expect(
        einvoiceDeliveryErrorMessage(null),
        einvoiceDeliveryFallbackMessage,
      );
    });
  });
}
