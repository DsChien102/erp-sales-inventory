// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_receipt_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/src/domain/sales_receipt/supabase_sales_receipt_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

const _eight = [
  'NOT_FOUND',
  'PERMISSION_DENIED',
  'PROJECTION_PENDING',
  'DATA_SCOPE_DENIED',
  'STALE_VERSION',
  'IDEMPOTENCY_CONFLICT',
  'DEPENDENCY_UNAVAILABLE',
  'CONTEXT_INVALID',
];

String _json(String code, {String message = 'x'}) => '{"code":"$code","message":"$message"}';

class _OldRpc implements IRpcClient {
  _OldRpc(this.error);
  final Object error;
  @override
  Future<Map<String, dynamic>> call(String procedure, {Map<String, dynamic>? params}) async {
    if (error is String) throw RpcException(error as String);
    throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<String> _oldCode(Object error) async {
  try {
    await SupabaseSalesReceiptGateway(rpcClient: _OldRpc(error)).generate(
      GenerateSalesReceiptCommand(
        tenantId: 't',
        actorId: 'a',
        salesOrderId: 'o',
        idempotencyKey: 'k',
      ),
    );
  } on SalesContractException catch (e) {
    return e.code;
  }
  return 'none';
}

void main() {
  group('old', () {
    for (final code in _eight) {
      test('keeps $code', () async => expect(await _oldCode(_json(code)), code));
    }
    test('CANCELLATION_BLOCKED → DEPENDENCY_UNAVAILABLE', () async {
      expect(await _oldCode(_json('CANCELLATION_BLOCKED')), 'DEPENDENCY_UNAVAILABLE');
    });
    test('unhandled PostgrestException → DEPENDENCY_UNAVAILABLE', () async {
      expect(await _oldCode('boom'), 'DEPENDENCY_UNAVAILABLE');
    });
    test('FormatException → DEPENDENCY_UNAVAILABLE', () async {
      expect(await _oldCode(const FormatException('x')), 'DEPENDENCY_UNAVAILABLE');
    });
    test('nested json 2 layers → DEPENDENCY_UNAVAILABLE', () async {
      expect(
        await _oldCode('{"message":"{\\"code\\":\\"NOT_FOUND\\"}"}'),
        'DEPENDENCY_UNAVAILABLE',
      );
    });
  });

  group('new', () {
    for (final code in _eight) {
      final expected = code == 'PERMISSION_DENIED' ? 'NO_PERMISSION' : code;
      test('maps $code to $expected', () {
        final e = salesReceiptException(
          PostgrestException(message: _json(code, message: 'msg-$code')),
        );
        expect(e.code, expected);
        expect(e.serverMessage, 'msg-$code');
      });
    }
    test('CANCELLATION_BLOCKED → SYSTEM_ERROR', () {
      expect(
        salesReceiptException(PostgrestException(message: _json('CANCELLATION_BLOCKED'))).code,
        'SYSTEM_ERROR',
      );
    });
    test('PostgrestException boom → SYSTEM_ERROR', () {
      expect(salesReceiptException(const PostgrestException(message: 'boom')).code, 'SYSTEM_ERROR');
    });
    test('NETWORK_ERROR stays', () {
      expect(salesReceiptException(const AppException('NETWORK_ERROR')).code, 'NETWORK_ERROR');
    });
    test('FormatException → SYSTEM_ERROR', () {
      expect(salesReceiptException(const FormatException('x')).code, 'SYSTEM_ERROR');
    });
    test('nested json 2 layers → NOT_FOUND', () {
      final e = salesReceiptException(
        const PostgrestException(message: '{"message":"{\\"code\\":\\"NOT_FOUND\\"}"}'),
      );
      expect(e.code, 'NOT_FOUND');
    });
  });
}
