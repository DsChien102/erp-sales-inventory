// ignore_for_file: implementation_imports

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_order_read_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

const _six = [
  'NOT_FOUND',
  'PERMISSION_DENIED',
  'PROJECTION_PENDING',
  'DATA_SCOPE_DENIED',
  'STALE_VERSION',
  'DEPENDENCY_UNAVAILABLE',
];

String _json(String code) => '{"code":"$code","message":"m"}';

void main() {
  group('new', () {
    for (final code in _six) {
      final expected = code == 'PERMISSION_DENIED' ? 'NO_PERMISSION' : code;
      test('keeps $code', () {
        final e = salesOrderReadException(PostgrestException(message: _json(code)));
        expect(e.code, expected);
        expect(e.serverMessage, 'm');
      });
    }
    test('keeps IMPACT_PENDING', () {
      final e = salesOrderReadException(PostgrestException(message: _json('IMPACT_PENDING')));
      expect(e.code, 'IMPACT_PENDING');
      expect(e.serverMessage, 'm');
    });
    test('NETWORK_ERROR stays', () {
      expect(salesOrderReadException(const AppException('NETWORK_ERROR')).code, 'NETWORK_ERROR');
    });
    test('STALE_DATA → SYSTEM_ERROR', () {
      expect(
        salesOrderReadException(PostgrestException(message: _json('STALE_DATA'))).code,
        'SYSTEM_ERROR',
      );
    });
    test('FormatException → SYSTEM_ERROR', () {
      expect(salesOrderReadException(const FormatException('x')).code, 'SYSTEM_ERROR');
    });
  });
}
