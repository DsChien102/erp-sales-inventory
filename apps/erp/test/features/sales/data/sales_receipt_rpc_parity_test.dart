// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/sales_receipt_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/src/domain/sales_receipt/sales_receipt_rpc_mapper.dart';
import 'package:vet45_sales_infrastructure/src/domain/sales_receipt/supabase_sales_receipt_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'sales_order_inquiry_parity_expectations.dart';

class _OldRpc implements IRpcClient {
  _OldRpc(this.message);
  final String message;
  @override
  Future<Map<String, dynamic>> call(String procedure, {Map<String, dynamic>? params}) async =>
      throw RpcException(message);
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _RecordingRpc implements SupabaseRpc {
  final calls = <({String schema, String fn, Map<String, dynamic>? params})>[];
  Object? result;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    calls.add((schema: schema, fn: fn, params: params));
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('old', () {
    test('params_generate', () {
      final command = GenerateSalesReceiptCommand(
        id: inquiryCommandId,
        tenantId: inquiryTenantId,
        actorId: inquiryActorId,
        salesOrderId: inquiryOrderId,
        idempotencyKey: 'idem-1',
        correlationId: 'corr-1',
        expectedVersion: 3,
      );
      final params = SalesReceiptRpcMapper.generateParams(command);
      expect(params, equals(expectedGenerateParams(expectedVersion: 3)));
    });

    test('params_get_receipt_with_version', () {
      final query = GetSalesReceiptQuery(
        id: inquiryQueryId,
        tenantId: inquiryTenantId,
        actorId: inquiryActorId,
        receiptId: inquiryReceiptId,
        expectedSourceVersion: 4,
      );
      final params = SalesReceiptRpcMapper.getReceiptParams(query);
      expect(params, equals(expectedGetReceiptParams(expectedSourceVersion: 4)));
    });

    test('params_get_receipt_null_version', () {
      final query = GetSalesReceiptQuery(
        id: inquiryQueryId,
        tenantId: inquiryTenantId,
        actorId: inquiryActorId,
        receiptId: inquiryReceiptId,
        expectedSourceVersion: null,
      );
      final params = SalesReceiptRpcMapper.getReceiptParams(query);
      expect(params, equals(expectedGetReceiptParams(expectedSourceVersion: null)));
    });

    test('params_original_receipt', () {
      final query = GetSalesOrderOriginalReceiptQuery(
        id: inquiryQueryId,
        tenantId: inquiryTenantId,
        actorId: inquiryActorId,
        salesOrderId: inquiryOrderId,
      );
      final params = SalesReceiptRpcMapper.originalReceiptParams(query);
      expect(params, equals(expectedOriginalReceiptParams()));
    });

    test('params_record_printed', () {
      final command = RecordSalesReceiptPrintedCommand(
        id: inquiryCommandId,
        tenantId: inquiryTenantId,
        actorId: inquiryActorId,
        receiptId: inquiryReceiptId,
        idempotencyKey: 'idem-print-1',
        correlationId: 'corr-1',
      );
      final params = SalesReceiptRpcMapper.printedParams(command);
      expect(
        params,
        equals(
          expectedPrintedParams(
            commandId: inquiryCommandId,
            idempotencyKey: 'idem-print-1',
            correlationId: 'corr-1',
          ),
        ),
      );
    });

    test('params_record_shared', () {
      final command = RecordSalesReceiptSharedCommand(
        id: inquiryCommandId,
        tenantId: inquiryTenantId,
        actorId: inquiryActorId,
        receiptId: inquiryReceiptId,
        idempotencyKey: 'idem-share-1',
        correlationId: 'corr-1',
      );
      final params = SalesReceiptRpcMapper.sharedParams(command);
      expect(
        params,
        equals(
          expectedSharedParams(
            commandId: inquiryCommandId,
            idempotencyKey: 'idem-share-1',
            correlationId: 'corr-1',
          ),
        ),
      );
    });

    test('parse_receipt', () {
      final dto = SalesReceiptRpcMapper.salesReceiptFromJson(sampleReceiptJson());
      expectReceiptDto(dto);
    });

    test('parse_original_document', () {
      final dto = SalesReceiptRpcMapper.documentFromJson(sampleOriginalDocumentJson());
      expectOriginalDocumentDto(dto);
    });

    test('receipt_gateway_maps_rpc_error', () async {
      final gateway = SupabaseSalesReceiptGateway(
        rpcClient: _OldRpc('{"code":"STALE_VERSION","message":"Stale"}'),
      );
      expect(
        () => gateway.generate(
          GenerateSalesReceiptCommand(
            tenantId: inquiryTenantId,
            actorId: inquiryActorId,
            salesOrderId: inquiryOrderId,
            idempotencyKey: 'idem-1',
          ),
        ),
        throwsA(isA<SalesContractException>().having((e) => e.code, 'code', 'STALE_VERSION')),
      );
    });
  });

  group('new', () {
    late _RecordingRpc rpc;
    late SalesReceiptRepository repository;

    setUp(() {
      rpc = _RecordingRpc();
      repository = SalesReceiptRepository(
        rpc: rpc,
        tenantId: () async => inquiryTenantId,
        actorId: () async => inquiryActorId,
        newId: () => inquiryQueryId,
      );
    });

    test('params_generate', () async {
      rpc.result = sampleReceiptJson();
      await repository.generate(salesOrderId: inquiryOrderId, expectedVersion: 3);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'generate_sales_receipt');
      expect(
        rpc.calls.single.params,
        equals(
          expectedGenerateParams(
            expectedVersion: 3,
            commandId: inquiryQueryId,
            correlationId: inquiryQueryId,
            idempotencyKey: 'sales-receipt:$inquiryTenantId:$inquiryOrderId:v3',
          ),
        ),
      );
    });

    test('params_get_receipt_with_version', () async {
      rpc.result = sampleReceiptJson();
      await repository.get(receiptId: inquiryReceiptId, expectedSourceVersion: 4);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'get_sales_receipt');
      expect(rpc.calls.single.params, equals(expectedGetReceiptParams(expectedSourceVersion: 4)));
    });

    test('params_get_receipt_null_version', () async {
      rpc.result = sampleReceiptJson();
      await repository.get(receiptId: inquiryReceiptId, expectedSourceVersion: null);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'get_sales_receipt');
      expect(
        rpc.calls.single.params,
        equals(expectedGetReceiptParams(expectedSourceVersion: null)),
      );
    });

    test('params_original_receipt', () async {
      rpc.result = sampleOriginalDocumentJson();
      await repository.getOriginal(salesOrderId: inquiryOrderId);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'get_sales_order_original_receipt');
      expect(rpc.calls.single.params, equals(expectedOriginalReceiptParams()));
    });

    test('params_record_printed', () async {
      rpc.result = sampleReceiptJson();
      await repository.recordPrinted(
        receiptId: inquiryReceiptId,
        commandId: inquiryCommandId,
        idempotencyKey: 'idem-print-1',
      );
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'record_sales_receipt_activity');
      expect(
        rpc.calls.single.params,
        equals(
          expectedPrintedParams(
            commandId: inquiryCommandId,
            idempotencyKey: 'idem-print-1',
            correlationId: inquiryQueryId,
          ),
        ),
      );
    });

    test('params_record_shared', () async {
      rpc.result = sampleReceiptJson();
      await repository.recordShared(
        receiptId: inquiryReceiptId,
        commandId: inquiryCommandId,
        idempotencyKey: 'idem-share-1',
      );
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'record_sales_receipt_activity');
      expect(
        rpc.calls.single.params,
        equals(
          expectedSharedParams(
            commandId: inquiryCommandId,
            idempotencyKey: 'idem-share-1',
            correlationId: inquiryQueryId,
          ),
        ),
      );
    });

    test('parse_receipt', () async {
      rpc.result = sampleReceiptJson();
      final dto = await repository.generate(salesOrderId: inquiryOrderId, expectedVersion: 1);
      expectReceiptDto(dto);
    });

    test('parse_original_document', () async {
      rpc.result = sampleOriginalDocumentJson();
      final dto = await repository.getOriginal(salesOrderId: inquiryOrderId);
      expectOriginalDocumentDto(dto);
    });
  });
}
