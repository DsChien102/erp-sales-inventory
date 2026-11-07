
import 'dart:convert';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_draft_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

PostgrestException _pg(String message) => PostgrestException(message: message);

void main() {
  group('new', () {
    test('stale_data_keeps_code_and_server_message', () {
      final e = salesDraftException(
        _pg(jsonEncode({'code': 'STALE_DATA', 'message': 'Draft version has changed.'})),
      );
      expect(e.code, 'STALE_DATA');
      expect(e.serverMessage, 'Draft version has changed.');
    });

    test('permission_denied_becomes_no_permission', () {
      expect(
        salesDraftException(_pg(jsonEncode({'code': 'PERMISSION_DENIED'}))).code,
        'NO_PERMISSION',
      );
    });

    for (final code in [
      'DATA_SCOPE_DENIED',
      'CONTEXT_INVALID',
      'REFERENCE_UNAVAILABLE',
      'IDEMPOTENCY_CONFLICT',
    ]) {
      test('keeps_$code', () {
        expect(salesDraftException(_pg(jsonEncode({'code': code}))).code, code);
      });
    }

    test('nested_postgrest_message_json_is_unwrapped', () {
      final nested = jsonEncode({'code': 'DATA_SCOPE_DENIED', 'message': 'Store scope denied.'});
      final e = salesDraftException(_pg(jsonEncode({'code': 'P0001', 'message': nested})));
      expect(e.code, 'DATA_SCOPE_DENIED');
      expect(e.serverMessage, 'Store scope denied.');
    });

    test('nested_permission_denied_becomes_no_permission', () {
      final nested = jsonEncode({'code': 'PERMISSION_DENIED'});
      final e = salesDraftException(_pg(jsonEncode({'code': 'P0001', 'message': nested})));
      expect(e.code, 'NO_PERMISSION');
    });

    test('unknown_code_becomes_system_error', () {
      final e = salesDraftException(_pg(jsonEncode({'code': 'STALE_VERSION'})));
      expect(e.code, 'SYSTEM_ERROR');
    });

    test('plain_postgrest_becomes_system_error', () {
      expect(salesDraftException(_pg('boom')).code, 'SYSTEM_ERROR');
    });

    test('non_app_errors_become_system_error', () {
      expect(salesDraftException(const FormatException('x')).code, 'SYSTEM_ERROR');
      expect(salesDraftException(StateError('x')).code, 'SYSTEM_ERROR');
    });

    test('app_exception_context_invalid_passes_through', () {
      const original = AppException(
        'CONTEXT_INVALID',
        serverMessage: 'Draft line quantity must be positive.',
      );
      expect(identical(salesDraftException(original), original), isTrue);
    });
  });
}
