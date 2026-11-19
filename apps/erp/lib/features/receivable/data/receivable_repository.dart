import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';

import 'receivable_models.dart';

/// Mọi RPC của schema `receivable` (TH-06 6.2). `p_tenant_id`, `p_actor_id` lấy từ phiên.
class ReceivableRepository {
  ReceivableRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
    required Future<String> Function() actorId,
  }) : _rpc = rpc,
       _tenantId = tenantId,
       _actorId = actorId;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;
  final Future<String> Function() _actorId;

  static const _schema = 'receivable';

  Future<Map<String, dynamic>> _call(String fn, Map<String, dynamic> params) async {
    final result = await _rpc.call(
      _schema,
      fn,
      params: {
        'p_tenant_id': await _tenantId(),
        'p_actor_id': await _actorId(),
        ...params,
      },
    );
    if (result is! Map) throw const AppException(AppErrorCode.unknown);
    return Map<String, dynamic>.from(result);
  }

  Future<CustomerReceivablePage> list({
    ReceivableFilter filter = ReceivableFilter.all,
    String? search,
    String? cursor,
  }) async {
    final text = search?.trim();
    final json = await _call('list_customer_receivables', {
      'p_filter': filter.name,
      'p_search': text == null || text.isEmpty ? null : text,
      'p_cursor': cursor,
      'p_page_size': 50,
    });
    return CustomerReceivablePage.fromJson(json);
  }

  Future<CustomerReceivableDetail> getCustomer(String customerId) async {
    final json = await _call('get_customer_receivable', {'p_customer_partner_id': customerId});
    return CustomerReceivableDetail.fromJson(json);
  }

  Future<ReceivableHistoryPage> history(String customerId, {String? cursor}) async {
    final json = await _call('list_customer_receivable_history', {
      'p_customer_partner_id': customerId,
      'p_cursor': cursor,
      'p_page_size': 20,
    });
    return ReceivableHistoryPage.fromJson(json);
  }

  Future<CustomerCollectionResult> recordCollection(CustomerCollectionRequest request) async {
    final ref = request.externalReference?.trim();
    final json = await _call('record_customer_collection', {
      'p_customer_partner_id': request.customerId,
      'p_amount_minor': request.amountMinor,
      'p_payment_method_code': request.method.name,
      'p_external_reference': ref == null || ref.isEmpty ? null : ref,
      'p_order_ids': request.orderIds,
      'p_expected_outstanding_minor': request.expectedOutstandingMinor,
      'p_idempotency_key': request.idempotencyKey,
    });
    return CustomerCollectionResult.fromJson(json);
  }
}
