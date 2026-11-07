// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_order_read_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/src/domain/sales_order/supabase_sales_order_read_gateway.dart';
import 'package:vet45_sales_infrastructure/src/domain/sales_order_cancellation/supabase_sales_order_cancellation_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

const _six = [
  'NOT_FOUND',
  'PERMISSION_DENIED',
  'PROJECTION_PENDING',
  'DATA_SCOPE_DENIED',
  'STALE_VERSION',
  'DEPENDENCY_UNAVAILABLE',
];

String _json(String code) => '{"code":"$code","message":"m"}';

class _OldRpc implements IRpcClient {
  _OldRpc(this.message);
  final String message;
  @override
  Future<Map<String, dynamic>> call(String procedure, {Map<String, dynamic>? params}) async =>
      throw RpcException(message);
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<String> _oldCode(String message) async {
  try {
    await SupabaseSalesOrderReadGateway(rpcClient: _OldRpc(message)).getSalesOrder(
      GetSalesOrderQuery(tenantId: 't', actorId: 'a', salesOrderId: 'o'),
    );
  } on SalesContractException catch (e) {
    return e.code;
  }
  return 'none';
}

void main() {
  group('old', () {
    for (final code in _six) {
      test('keeps $code', () async => expect(await _oldCode(_json(code)), code));
    }
    test('STALE_DATA → DEPENDENCY_UNAVAILABLE', () async {
      expect(await _oldCode(_json('STALE_DATA')), 'DEPENDENCY_UNAVAILABLE');
    });
    test('IMPACT_PENDING kept by cancellation gateway', () async {
      try {
        await SupabaseSalesOrderCancellationGateway(rpcClient: _OldRpc(_json('IMPACT_PENDING'))).getDetail(
          GetSalesOrderCancellationQuery(tenantId: 't', actorId: 'a', salesOrderId: 'o'),
        );
      } on SalesContractException catch (e) {
        expect(e.code, 'IMPACT_PENDING');
      }
    });
  });

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
