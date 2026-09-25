import 'dart:io';

import 'package:test/test.dart';

/// Active rebuild SQL owners (Tasks 2–11). Legacy Group B–I / `600_draft`–`604`
/// are intentionally excluded from authority counting.
const _ownerFiles = <String>[
  '006_sales_shared_rpc_helpers.sql',
  '007_sales_draft_rpcs.sql',
  '008_sales_checkout_rpcs.sql',
  '009_sales_settlement_rpcs.sql',
  '010_sales_inquiry_receipt_rpcs.sql',
  '011_sales_adjustment_cancellation_rpcs.sql',
  '012_sales_return_exchange_session_rpcs.sql',
  '013_sales_return_exchange_settlement_rpcs.sql',
  '014_sales_return_exchange_confirmation_rpcs.sql',
  '015_sales_integration_rpcs.sql',
];

/// Gateway procedure → expected owner file + mapper-emitted named params.
/// Private helpers are excluded from gateway expectations.
const _gatewaySurface = <String, ({String owner, Set<String> mapperKeys})>{
  // Draft
  'save_sales_order_draft': (
    owner: '007_sales_draft_rpcs.sql',
    mapperKeys: {
      'p_tenant_id',
      'p_actor_id',
      'p_store_id',
      'p_customer',
      'p_currency_code',
      'p_lines',
      'p_idempotency_key',
      'p_order_note',
      'p_pricing_preview_token',
      'p_needs_revalidation',
      'p_payload_hash',
      'p_correlation_id',
      'p_causation_id',
    },
  ),
  'update_sales_order_draft': (
    owner: '007_sales_draft_rpcs.sql',
    mapperKeys: {
      'p_tenant_id',
      'p_actor_id',
      'p_draft_id',
      'p_store_id',
      'p_customer',
      'p_currency_code',
      'p_lines',
      'p_expected_version',
      'p_idempotency_key',
      'p_order_note',
      'p_pricing_preview_token',
      'p_needs_revalidation',
      'p_payload_hash',
      'p_correlation_id',
      'p_causation_id',
    },
  ),
  'cancel_sales_order_draft': (
    owner: '007_sales_draft_rpcs.sql',
    mapperKeys: {
      'p_tenant_id',
      'p_actor_id',
      'p_draft_id',
      'p_store_id',
      'p_expected_version',
      'p_idempotency_key',
      'p_payload_hash',
      'p_correlation_id',
      'p_causation_id',
    },
  ),
  'get_sales_order_draft_for_restore': (
    owner: '007_sales_draft_rpcs.sql',
    mapperKeys: {
      'p_tenant_id',
      'p_actor_id',
      'p_draft_id',
      'p_store_id',
      'p_expected_version',
    },
  ),
  'list_sales_order_drafts': (
    owner: '007_sales_draft_rpcs.sql',
    mapperKeys: {
      'p_tenant_id',
      'p_actor_id',
      'p_store_id',
      'p_cursor',
      'p_page_size',
    },
  ),
  // Checkout
  'precheck_sales_order_checkout': (
    owner: '008_sales_checkout_rpcs.sql',
    mapperKeys: {
      'p_query_id',
      'p_tenant_id',
      'p_actor_id',
      'p_store_id',
      'p_customer_id',
      'p_currency_code',
      'p_lines',
      'p_payment_intents',
      'p_expected_source_version',
    },
  ),
  'finalize_sales_order': (
    owner: '008_sales_checkout_rpcs.sql',
    mapperKeys: {
      'p_command_id',
      'p_tenant_id',
      'p_actor_id',
      'p_store_id',
      'p_source_draft_id',
      'p_customer_id',
      'p_currency_code',
      'p_order_note',
      'p_commercial_snapshot',
      'p_lines',
      'p_payment_intents',
      'p_idempotency_key',
      'p_payload_hash',
      'p_correlation_id',
      'p_causation_id',
      'p_expected_source_version',
    },
  ),
  'get_checkout_result': (
    owner: '008_sales_checkout_rpcs.sql',
    mapperKeys: {
      'p_query_id',
      'p_tenant_id',
      'p_actor_id',
      'p_store_id',
      'p_idempotency_key',
    },
  ),
  // Read / inquiry / receipt
  'get_sales_order': (
    owner: '010_sales_inquiry_receipt_rpcs.sql',
    mapperKeys: {'p_query_id', 'p_tenant_id', 'p_actor_id', 'p_sales_order_id'},
  ),
  'get_sales_order_payment_summary': (
    owner: '010_sales_inquiry_receipt_rpcs.sql',
    mapperKeys: {
      'p_query_id',
      'p_tenant_id',
      'p_actor_id',
      'p_sales_order_id',
      'p_expected_source_version',
    },
  ),
  'get_order_integration_status': (
    owner: '010_sales_inquiry_receipt_rpcs.sql',
    mapperKeys: {
      'p_query_id',
      'p_tenant_id',
      'p_actor_id',
      'p_sales_order_id',
      'p_expected_source_version',
    },
  ),
  'list_sales_orders': (
    owner: '010_sales_inquiry_receipt_rpcs.sql',
    mapperKeys: {
      'query_id',
      'tenant_id',
      'actor_id',
      'cursor',
      'page_size',
      'completed_from',
      'completed_to',
      'store_id',
      'seller_id',
      'customer_id',
      'lifecycle_status',
      'lock_status',
      'settlement_status',
      'has_return_exchange',
      'e_invoice_status',
      'has_outstanding_receivable',
    },
  ),
  'search_sales_orders': (
    owner: '010_sales_inquiry_receipt_rpcs.sql',
    mapperKeys: {
      'query_id',
      'tenant_id',
      'actor_id',
      'search_text',
      'cursor',
      'page_size',
      'completed_from',
      'completed_to',
      'store_id',
      'seller_id',
      'customer_id',
      'lifecycle_status',
      'lock_status',
      'settlement_status',
      'has_return_exchange',
      'e_invoice_status',
      'has_outstanding_receivable',
    },
  ),
  'get_sales_order_detail': (
    owner: '010_sales_inquiry_receipt_rpcs.sql',
    mapperKeys: {
      'query_id',
      'tenant_id',
      'actor_id',
      'sales_order_id',
      'expected_source_version',
    },
  ),
  'get_sales_order_settlement': (
    owner: '010_sales_inquiry_receipt_rpcs.sql',
    mapperKeys: {
      'query_id',
      'tenant_id',
      'actor_id',
      'sales_order_id',
      'expected_source_version',
    },
  ),
  'get_sales_order_payment_transactions': (
    owner: '010_sales_inquiry_receipt_rpcs.sql',
    mapperKeys: {
      'query_id',
      'tenant_id',
      'actor_id',
      'sales_order_id',
      'expected_source_version',
    },
  ),
  'get_sales_order_timeline': (
    owner: '010_sales_inquiry_receipt_rpcs.sql',
    mapperKeys: {
      'query_id',
      'tenant_id',
      'actor_id',
      'sales_order_id',
      'expected_source_version',
    },
  ),
  'get_sales_order_return_summary': (
    owner: '010_sales_inquiry_receipt_rpcs.sql',
    mapperKeys: {
      'query_id',
      'tenant_id',
      'actor_id',
      'sales_order_id',
      'expected_source_version',
    },
  ),
  'generate_sales_receipt': (
    owner: '010_sales_inquiry_receipt_rpcs.sql',
    mapperKeys: {
      'p_command_id',
      'p_tenant_id',
      'p_actor_id',
      'p_sales_order_id',
      'p_idempotency_key',
      'p_payload_hash',
      'p_correlation_id',
      'p_causation_id',
      'p_expected_source_version',
    },
  ),
  'get_sales_receipt': (
    owner: '010_sales_inquiry_receipt_rpcs.sql',
    mapperKeys: {
      'p_query_id',
      'p_tenant_id',
      'p_actor_id',
      'p_receipt_id',
      'p_expected_source_version',
    },
  ),
  'get_sales_order_original_receipt': (
    owner: '010_sales_inquiry_receipt_rpcs.sql',
    mapperKeys: {
      'p_query_id',
      'p_tenant_id',
      'p_actor_id',
      'p_sales_order_id',
    },
  ),
  'record_sales_receipt_activity': (
    owner: '010_sales_inquiry_receipt_rpcs.sql',
    mapperKeys: {
      'p_command_id',
      'p_tenant_id',
      'p_actor_id',
      'p_receipt_id',
      'p_activity_type',
      'p_idempotency_key',
      'p_payload_hash',
      'p_correlation_id',
      'p_causation_id',
      'p_expected_source_version',
    },
  ),
  // Cancellation + available post-sale actions
  'get_available_post_sale_actions': (
    owner: '011_sales_adjustment_cancellation_rpcs.sql',
    mapperKeys: {
      'query_id',
      'tenant_id',
      'actor_id',
      'sales_order_id',
      'expected_source_version',
    },
  ),
  'precheck_sales_order_cancellation': (
    owner: '011_sales_adjustment_cancellation_rpcs.sql',
    mapperKeys: {
      'query_id',
      'tenant_id',
      'actor_id',
      'sales_order_id',
      'expected_source_version',
    },
  ),
  'confirm_sales_order_cancellation': (
    owner: '011_sales_adjustment_cancellation_rpcs.sql',
    mapperKeys: {
      'command_id',
      'tenant_id',
      'actor_id',
      'sales_order_id',
      'reason_text',
      'idempotency_key',
      'payload_hash',
      'correlation_id',
      'causation_id',
      'expected_order_version',
      'expected_settlement_version',
    },
  ),
  'get_sales_order_cancellation': (
    owner: '011_sales_adjustment_cancellation_rpcs.sql',
    mapperKeys: {
      'query_id',
      'tenant_id',
      'actor_id',
      'sales_order_id',
      'expected_source_version',
    },
  ),
  'list_sales_order_cancellation_reasons': (
    owner: '011_sales_adjustment_cancellation_rpcs.sql',
    mapperKeys: {'query_id', 'tenant_id', 'actor_id'},
  ),
  // Return/exchange
  'precheck_return_exchange': (
    owner: '012_sales_return_exchange_session_rpcs.sql',
    mapperKeys: {
      'query_id',
      'tenant_id',
      'actor_id',
      'sales_order_id',
      'expected_source_version',
    },
  ),
  'get_returnable_order_lines': (
    owner: '012_sales_return_exchange_session_rpcs.sql',
    mapperKeys: {
      'query_id',
      'tenant_id',
      'actor_id',
      'sales_order_id',
      'expected_source_version',
    },
  ),
  'get_return_exchange_form_policy': (
    owner: '012_sales_return_exchange_session_rpcs.sql',
    mapperKeys: {'query_id', 'tenant_id', 'actor_id'},
  ),
  'get_return_exchange_detail': (
    owner: '012_sales_return_exchange_session_rpcs.sql',
    mapperKeys: {
      'query_id',
      'tenant_id',
      'actor_id',
      'return_exchange_id',
      'expected_version',
    },
  ),
  'start_return_exchange': (
    owner: '012_sales_return_exchange_session_rpcs.sql',
    mapperKeys: {
      'command_id',
      'tenant_id',
      'actor_id',
      'sales_order_id',
      'entry_source',
      'lines',
      'idempotency_key',
      'payload_hash',
      'correlation_id',
      'causation_id',
      'expected_source_version',
      'reference_decision',
    },
  ),
  'update_return_exchange': (
    owner: '012_sales_return_exchange_session_rpcs.sql',
    mapperKeys: {
      'command_id',
      'tenant_id',
      'actor_id',
      'return_exchange_id',
      'lines',
      'idempotency_key',
      'payload_hash',
      'correlation_id',
      'causation_id',
      'expected_version',
      'reference_decision',
    },
  ),
  'cancel_return_exchange': (
    owner: '012_sales_return_exchange_session_rpcs.sql',
    mapperKeys: {
      'command_id',
      'tenant_id',
      'actor_id',
      'return_exchange_id',
      'idempotency_key',
      'payload_hash',
      'correlation_id',
      'causation_id',
      'expected_version',
    },
  ),
  'evaluate_return_exchange_valuation': (
    owner: '013_sales_return_exchange_settlement_rpcs.sql',
    mapperKeys: {
      'query_id',
      'tenant_id',
      'actor_id',
      'return_exchange_id',
      'expected_source_version',
      'reference_decision',
    },
  ),
  'settle_return_exchange_difference': (
    owner: '013_sales_return_exchange_settlement_rpcs.sql',
    mapperKeys: {
      'command_id',
      'tenant_id',
      'actor_id',
      'operation',
      'amount_minor',
      'currency_code',
      'method',
      'reference',
      'idempotency_key',
      'payload_hash',
      'correlation_id',
      'causation_id',
      'expected_source_version',
    },
  ),
  'confirm_return_exchange': (
    owner: '014_sales_return_exchange_confirmation_rpcs.sql',
    mapperKeys: {
      'command_id',
      'tenant_id',
      'actor_id',
      'return_exchange_id',
      'idempotency_key',
      'payload_hash',
      'correlation_id',
      'causation_id',
      'expected_version',
      'reference_decision',
      'payment_settled_now_minor',
      'payment_method',
      'payment_due_date',
    },
  ),
  'complete_return_exchange': (
    owner: '014_sales_return_exchange_confirmation_rpcs.sql',
    mapperKeys: {
      'command_id',
      'tenant_id',
      'actor_id',
      'return_exchange_id',
      'idempotency_key',
      'payload_hash',
      'correlation_id',
      'causation_id',
      'expected_version',
    },
  ),
  // Integration — Model B delivery/reconciliation RPCs are deferred, so 015 owns
  // nothing today; only the stubbed get_order_integration_status read remains.
};

/// Public settlement RPCs owned by rebuild but not yet wired through a gateway.
const _publicNonGatewayRpcs = <String, String>{
  'record_sales_payment': '009_sales_settlement_rpcs.sql',
  'record_sales_refund': '009_sales_settlement_rpcs.sql',
};

void main() {
  late final Map<String, List<String>> ownersByFunction;
  late final Map<String, Set<String>> paramsByFunction;

  setUpAll(() {
    final parsed = _parseOwners();
    ownersByFunction = parsed.owners;
    paramsByFunction = parsed.params;
  });

  test('every public rebuild RPC has exactly one active SQL owner', () {
    final publicFns = ownersByFunction.keys
        .where((name) => !name.startsWith('_'))
        .toList(growable: false);
    expect(publicFns, isNotEmpty);
    for (final fn in publicFns) {
      expect(
        ownersByFunction[fn],
        hasLength(1),
        reason: '$fn must have exactly one active SQL owner',
      );
    }
  });

  test('gateway surface maps to one owner and mapper keys ⊆ SQL params', () {
    expect(_gatewaySurface.length, greaterThanOrEqualTo(37));
    for (final entry in _gatewaySurface.entries) {
      final procedure = entry.key;
      final expectedOwner = entry.value.owner;
      final mapperKeys = entry.value.mapperKeys;

      expect(
        ownersByFunction[procedure],
        equals([expectedOwner]),
        reason: '$procedure must have exactly one active SQL owner ($expectedOwner)',
      );

      final sqlParams = paramsByFunction[procedure]!;
      expect(
        sqlParams,
        containsAll(mapperKeys),
        reason:
            '$procedure SQL params $sqlParams must contain all mapper keys $mapperKeys',
      );
    }
  });

  test('settlement public RPCs without gateway still have a single owner', () {
    for (final entry in _publicNonGatewayRpcs.entries) {
      expect(ownersByFunction[entry.key], equals([entry.value]));
    }
  });

  test('ADR-2 sign is present on valuation owner', () {
    final valuation = _readOwner('013_sales_return_exchange_settlement_rpcs.sql');
    expect(valuation, contains('exchange_value_minor - return_value_minor'));
    expect(valuation, isNot(contains('return_value_minor - exchange_value_minor')));
  });
}

({Map<String, List<String>> owners, Map<String, Set<String>> params}) _parseOwners() {
  final owners = <String, List<String>>{};
  final params = <String, Set<String>>{};
  final fnPattern = RegExp(
    r'create or replace function sales\.([a-zA-Z0-9_]+)\s*\((.*?)\)\s*returns',
    caseSensitive: false,
    dotAll: true,
  );

  for (final name in _ownerFiles) {
    final sql = _readOwner(name);
    for (final match in fnPattern.allMatches(sql)) {
      final fn = match.group(1)!;
      owners.putIfAbsent(fn, () => <String>[]).add(name);
      params[fn] = _namedParams(match.group(2)!);
    }
  }
  return (owners: owners, params: params);
}

Set<String> _namedParams(String args) {
  final params = <String>{};
  var depth = 0;
  final current = StringBuffer();
  for (final ch in args.split('')) {
    if (ch == '(') depth++;
    if (ch == ')') depth--;
    if (ch == ',' && depth == 0) {
      final part = current.toString().trim();
      if (part.isNotEmpty) params.add(part.split(RegExp(r'\s+')).first);
      current.clear();
    } else {
      current.write(ch);
    }
  }
  final part = current.toString().trim();
  if (part.isNotEmpty) params.add(part.split(RegExp(r'\s+')).first);
  return params;
}

String _readOwner(String fileName) {
  const draftDir = 'supabase/migrations/_drafts';
  final draftCandidates = [
    File('$draftDir/$fileName'),
    File('../../../$draftDir/$fileName'),
    File('../../../../$draftDir/$fileName'),
  ];
  for (final candidate in draftCandidates) {
    if (candidate.existsSync()) return candidate.readAsStringSync();
  }

  final match = RegExp(r'^(\d{3})_(.+)$').firstMatch(fileName);
  if (match != null) {
    final promotedName = '20260830${match.group(1)}_${match.group(2)}';
    const migrationsDir = 'supabase/migrations';
    final promotedCandidates = [
      File('$migrationsDir/$promotedName'),
      File('../../../$migrationsDir/$promotedName'),
      File('../../../../$migrationsDir/$promotedName'),
    ];
    for (final candidate in promotedCandidates) {
      if (candidate.existsSync()) return candidate.readAsStringSync();
    }
  }

  throw StateError('Missing owner draft $fileName');
}
