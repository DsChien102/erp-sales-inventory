// ignore_for_file: implementation_imports

import 'dart:convert';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/mappers/sales_draft_json.dart';
import 'package:erp/features/sales/data/sales_draft_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'sales_draft_parity_expectations.dart';

void main() {
  group('new', () {
    late _RecordingRpc rpc;
    late SalesDraftRepository repo;

    setUp(() {
      rpc = _RecordingRpc();
      repo = SalesDraftRepository(
        rpc: rpc,
        tenantId: () async => draftParityTenantId,
        actorId: () async => draftParityActorId,
      );
    });

    void expectCall(String fn, Map<String, dynamic> params) {
      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, fn);
      expect(rpc.calls.single.params, equals(params));
    }

    test('params_save_sales_order_draft', () async {
      rpc.result = sampleDraftJson();
      final dto = await repo.save(
        storeId: draftParityStoreId,
        customer: draftParityCustomer(),
        currencyCode: draftParityCurrencyRaw,
        orderNote: 'Giao buoi chieu',
        pricingPreviewToken: 'preview-token-1',
        needsRevalidation: true,
        lines: draftParityLines(),
        idempotencyKey: draftParityIdempotencyRaw,
        payloadHash: 'hash-1',
      );
      expectCall('save_sales_order_draft', expectedSaveParams);
      expectDraft(dto);
    });

    test('params_update_sales_order_draft', () async {
      rpc.result = sampleDraftJson();
      final dto = await repo.update(
        draftId: draftParityDraftId,
        expectedVersion: 3,
        storeId: draftParityStoreId,
        customer: draftParityCustomer(),
        currencyCode: draftParityCurrencyRaw,
        orderNote: 'Giao buoi chieu',
        pricingPreviewToken: 'preview-token-1',
        needsRevalidation: true,
        lines: draftParityLines(),
        idempotencyKey: draftParityIdempotencyRaw,
        payloadHash: 'hash-1',
      );
      expectCall('update_sales_order_draft', expectedUpdateParams);
      expectDraft(dto);
    });

    test('params_cancel_sales_order_draft', () async {
      rpc.result = sampleDraftJson();
      final dto = await repo.cancel(
        draftId: draftParityDraftId,
        storeId: draftParityStoreId,
        expectedVersion: 3,
        idempotencyKey: draftParityIdempotencyRaw,
      );
      expectCall('cancel_sales_order_draft', expectedCancelParams);
      expectDraft(dto);
    });

    test('params_get_sales_order_draft_for_restore', () async {
      rpc.result = sampleRestoreJson();
      final dto = await repo.getForRestore(
        draftId: draftParityDraftId,
        storeId: draftParityStoreId,
        expectedVersion: 2,
      );
      expectCall('get_sales_order_draft_for_restore', expectedRestoreParams);
      expectRestore(dto);
    });

    test('params_list_sales_order_drafts', () async {
      rpc.result = samplePageJson();
      final dto = await repo.list(storeId: draftParityStoreId, cursor: 'cursor-1', pageSize: 10);
      expectCall('list_sales_order_drafts', expectedListParams);
      expectPage(dto);
    });

    test('parse_draft', () {
      expectDraft(SalesDraftJson.draft(sampleDraftJson()));
    });

    test('parse_restore', () {
      expectRestore(SalesDraftJson.restore(sampleRestoreJson()));
    });

    test('parse_page', () {
      expectPage(SalesDraftJson.page(samplePageJson()));
    });

    test('parse_rejects_missing_has_more', () async {
      rpc.result = samplePageJson()..remove('has_more');
      await expectLater(
        repo.list(storeId: draftParityStoreId),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'SYSTEM_ERROR')),
      );
    });

    test('parse_rejects_unknown_status', () async {
      rpc.result = sampleDraftJson()..['status'] = 'weird';
      await expectLater(
        repo.cancel(
          draftId: 'd',
          storeId: draftParityStoreId,
          expectedVersion: 1,
          idempotencyKey: 'k',
        ),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'SYSTEM_ERROR')),
      );
    });

    test('parse_rejects_blank_draft_id', () async {
      rpc.result = sampleDraftJson()..['draft_id'] = '   ';
      await expectLater(
        repo.cancel(
          draftId: 'd',
          storeId: draftParityStoreId,
          expectedVersion: 1,
          idempotencyKey: 'k',
        ),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'SYSTEM_ERROR')),
      );
    });

    for (final entry in draftErrorCases.entries) {
      test('error_${entry.key}', () async {
        rpc.error = PostgrestException(message: entry.value.message);
        await expectLater(
          repo.cancel(
            draftId: 'd',
            storeId: draftParityStoreId,
            expectedVersion: 1,
            idempotencyKey: 'k',
          ),
          throwsA(isA<AppException>().having((e) => e.code, 'code', entry.value.newCode)),
        );
      });
    }
  });
}

class DraftErrorCase {
  const DraftErrorCase(this.message, this.oldCode, this.newCode);
  final String message;
  final String oldCode;
  final String newCode;
}

class _Call {
  _Call(this.schema, this.fn, this.params);
  final String schema;
  final String fn;
  final Map<String, dynamic>? params;
}

class _RecordingRpc implements SupabaseRpc {
  final calls = <_Call>[];
  Object? result;
  Object? error;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    calls.add(_Call(schema, fn, params));
    final e = error;
    if (e != null) throw AppException.from(e);
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Bảng D5 (đầu vào PostgrestException.message → mã gateway cũ).
final draftErrorCases = <String, DraftErrorCase>{
  'stale_data': DraftErrorCase(
    jsonEncode({'code': 'STALE_DATA', 'message': 'Draft version has changed.'}),
    'STALE_DATA',
    'STALE_DATA',
  ),
  'permission_denied': DraftErrorCase(
    jsonEncode({'code': 'PERMISSION_DENIED'}),
    'PERMISSION_DENIED',
    'NO_PERMISSION',
  ),
  'data_scope_denied': DraftErrorCase(
    jsonEncode({'code': 'DATA_SCOPE_DENIED'}),
    'DATA_SCOPE_DENIED',
    'DATA_SCOPE_DENIED',
  ),
  'context_invalid': DraftErrorCase(
    jsonEncode({'code': 'CONTEXT_INVALID'}),
    'CONTEXT_INVALID',
    'CONTEXT_INVALID',
  ),
  'reference_unavailable': DraftErrorCase(
    jsonEncode({'code': 'REFERENCE_UNAVAILABLE'}),
    'REFERENCE_UNAVAILABLE',
    'REFERENCE_UNAVAILABLE',
  ),
  'idempotency_conflict': DraftErrorCase(
    jsonEncode({'code': 'IDEMPOTENCY_CONFLICT'}),
    'IDEMPOTENCY_CONFLICT',
    'IDEMPOTENCY_CONFLICT',
  ),
  'stale_version_unknown': DraftErrorCase(
    jsonEncode({'code': 'STALE_VERSION'}),
    'CONTEXT_INVALID',
    'SYSTEM_ERROR',
  ),
  'nested_data_scope_denied': DraftErrorCase(
    jsonEncode({
      'code': 'P0001',
      'message': jsonEncode({'code': 'DATA_SCOPE_DENIED', 'message': 'Store scope denied.'}),
    }),
    'DATA_SCOPE_DENIED',
    'DATA_SCOPE_DENIED',
  ),
  'boom': DraftErrorCase('boom', 'CONTEXT_INVALID', 'SYSTEM_ERROR'),
};
