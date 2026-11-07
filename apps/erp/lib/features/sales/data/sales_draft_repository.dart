import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/mappers/sales_draft_json.dart';
import 'package:erp/features/sales/data/models/sales_draft_list_page.dart';
import 'package:erp/features/sales/data/sales_draft_errors.dart';
import 'package:erp/features/sales/logic/sales_draft_rules.dart';
import 'package:erp/features/sales/data/models.dart';

/// 5 RPC nháp của schema `sales`. Nhận / trả kiểu của `vet45_sales_application` (Q1).
class SalesDraftRepository {
  SalesDraftRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
    required Future<String> Function() actorId,
  }) : _rpc = rpc,
       _tenantId = tenantId,
       _actorId = actorId;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;
  final Future<String> Function() _actorId;

  Future<SalesOrderDraftDto> save({
    required String storeId,
    CustomerSnapshotDto? customer,
    required String currencyCode,
    String? orderNote,
    String? pricingPreviewToken,
    bool needsRevalidation = false,
    required List<SalesOrderDraftLineInput> lines,
    required String idempotencyKey,
    String? payloadHash,
  }) => _guard(() async {
    checkSaveDraft(
      storeId: storeId,
      customer: customer,
      currencyCode: currencyCode,
      lines: lines,
      idempotencyKey: idempotencyKey,
    );
    final raw = await _rpc.call(
      'sales',
      'save_sales_order_draft',
      params: <String, dynamic>{
        'p_tenant_id': await _tenantId(),
        'p_actor_id': await _actorId(),
        'p_store_id': storeId,
        'p_customer': SalesDraftJson.customerParams(customer),
        'p_currency_code': currencyCode.trim().toUpperCase(),
        'p_order_note': orderNote,
        'p_pricing_preview_token': pricingPreviewToken,
        'p_needs_revalidation': needsRevalidation,
        'p_lines': SalesDraftJson.lineParams(lines),
        'p_idempotency_key': idempotencyKey.trim(),
        'p_payload_hash': ?payloadHash,
      },
    );
    return SalesDraftJson.draft(_asMap(raw));
  });

  Future<SalesOrderDraftDto> update({
    required String draftId,
    required int expectedVersion,
    required String storeId,
    CustomerSnapshotDto? customer,
    required String currencyCode,
    String? orderNote,
    String? pricingPreviewToken,
    bool needsRevalidation = false,
    required List<SalesOrderDraftLineInput> lines,
    required String idempotencyKey,
    String? payloadHash,
  }) => _guard(() async {
    checkUpdateDraft(
      draftId: draftId,
      expectedVersion: expectedVersion,
      storeId: storeId,
      customer: customer,
      currencyCode: currencyCode,
      lines: lines,
      idempotencyKey: idempotencyKey,
    );
    final raw = await _rpc.call(
      'sales',
      'update_sales_order_draft',
      params: <String, dynamic>{
        'p_tenant_id': await _tenantId(),
        'p_actor_id': await _actorId(),
        'p_draft_id': draftId,
        'p_store_id': storeId,
        'p_customer': SalesDraftJson.customerParams(customer),
        'p_currency_code': currencyCode.trim().toUpperCase(),
        'p_order_note': orderNote,
        'p_pricing_preview_token': pricingPreviewToken,
        'p_needs_revalidation': needsRevalidation,
        'p_lines': SalesDraftJson.lineParams(lines),
        'p_expected_version': expectedVersion,
        'p_idempotency_key': idempotencyKey.trim(),
        'p_payload_hash': ?payloadHash,
      },
    );
    return SalesDraftJson.draft(_asMap(raw));
  });

  Future<SalesOrderDraftDto> cancel({
    required String draftId,
    required String storeId,
    required int expectedVersion,
    required String idempotencyKey,
  }) => _guard(() async {
    checkCancelDraft(
      draftId: draftId,
      expectedVersion: expectedVersion,
      idempotencyKey: idempotencyKey,
    );
    final raw = await _rpc.call(
      'sales',
      'cancel_sales_order_draft',
      params: <String, dynamic>{
        'p_tenant_id': await _tenantId(),
        'p_actor_id': await _actorId(),
        'p_draft_id': draftId,
        'p_store_id': storeId,
        'p_expected_version': expectedVersion,
        'p_idempotency_key': idempotencyKey.trim(),
      },
    );
    return SalesDraftJson.draft(_asMap(raw));
  });

  Future<SalesDraftListPage> list({
    required String storeId,
    String? cursor,
    int pageSize = 25,
    String? search,
    String? createdByUserId,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'list_sales_order_drafts',
      params: <String, dynamic>{
        'p_tenant_id': await _tenantId(),
        'p_actor_id': await _actorId(),
        'p_store_id': storeId,
        'p_cursor': cursor,
        'p_page_size': pageSize,
        'p_search': search,
        'p_created_by': createdByUserId,
      },
    );
    return SalesDraftJson.page(_asMap(raw));
  });

  Future<SalesOrderDraftForRestoreDto> getForRestore({
    required String draftId,
    required String storeId,
    int? expectedVersion,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'get_sales_order_draft_for_restore',
      params: <String, dynamic>{
        'p_tenant_id': await _tenantId(),
        'p_actor_id': await _actorId(),
        'p_draft_id': draftId,
        'p_store_id': storeId,
        'p_expected_version': ?expectedVersion,
      },
    );
    return SalesDraftJson.restore(_asMap(raw));
  });

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on Object catch (error) {
      throw salesDraftException(error);
    }
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) return raw.cast<String, dynamic>();
    throw FormatException('Expected JSON object, got $raw.');
  }
}
