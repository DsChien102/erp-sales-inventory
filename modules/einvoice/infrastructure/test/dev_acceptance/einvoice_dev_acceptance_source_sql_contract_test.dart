import 'dart:io';

import 'package:test/test.dart';

Directory _repoRoot() {
  var dir = Directory.current;
  while (!Directory('${dir.path}/supabase/migrations/_drafts').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }
  return dir;
}

void main() {
  late File sourceDraftFile;
  late String sql;

  setUpAll(() {
    final root = _repoRoot();
    sourceDraftFile = File(
      '${root.path}/supabase/migrations/_drafts/'
      '018_sales_einvoice_source_contract.sql',
    );
    sql = sourceDraftFile.existsSync()
        ? sourceDraftFile.readAsStringSync()
        : '';
  });

  group('Sales acceptance source SQL contract', () {
    test('source draft file exists in supabase/migrations/_drafts/', () {
      expect(
        sourceDraftFile.existsSync(),
        isTrue,
        reason:
            'Missing 018_sales_einvoice_source_contract.sql draft in _drafts/',
      );
    });

    test(
      'defines sales.get_einvoice_source_snapshot with correct signature and security definer',
      () {
        expect(sourceDraftFile.existsSync(), isTrue);
        expect(
          sql,
          contains(
            'create or replace function sales.get_einvoice_source_snapshot(',
          ),
          reason: 'Must define sales.get_einvoice_source_snapshot',
        );
        expect(sql, contains('p_tenant_id uuid,'));
        expect(sql, contains('p_sales_order_id uuid'));
        expect(sql, contains('returns table ('));
        expect(sql, contains('security definer'));
        expect(
          sql,
          contains(
            'grant execute on function sales.get_einvoice_source_snapshot(uuid, uuid) to service_role',
          ),
          reason:
              'Only service_role or definer should execute snapshot loading',
        );
      },
    );

    test('get_einvoice_source_snapshot reads real Sales order tables', () {
      expect(sourceDraftFile.existsSync(), isTrue);
      expect(sql, contains('from sales.sales_orders'));
      expect(sql, contains('from sales._sales_order_current_lines(p_tenant_id, p_sales_order_id) c'));
      expect(sql, isNot(contains('from sales.sales_order_lines')));
      expect(sql, isNot(contains('customer_snapshot')));
      expect(sql, isNot(contains('tax_snapshot,')));
      expect(sql, contains("v_order.sales_context_snapshot -> 'customer'"));
      expect(sql, contains("'ORDER_FULLY_RETURNED'"));
      expect(sql, contains("'taxAmountMinor',   0"));
      expect(sql, contains("'payableMinor',  coalesce(sum(cur.line_total_minor), 0)"));
      expect(sql, contains('v_order.version::text'));
      expect(sql, contains("'grossAmountMinor'"));
      expect(sql, contains("'lineTotalMinor'"));
      expect(sql, contains("'quantityMicros'"));
      expect(sql, contains("v_order.customer_partner_id"));
      expect(sql, contains("v_order.lifecycle_status = 'completed'"));
      expect(
        sql,
        contains('set search_path = sales, public, pg_temp'),
        reason: 'security definer must pin pg_temp last',
      );
    });

    // Theme 08 không được suy "khách lẻ" từ việc thiếu buyerType: đơn cũ của
    // khách định danh cũng thiếu buyer_tax_snapshot và sẽ bị gán nhầm.
    // Sales phải nói tường minh khi đơn không gắn khách hàng.
    test(
      'snapshot states retail explicitly when the order has no customer',
      () {
        expect(
          sql,
          contains('when v_order.customer_partner_id is null then \'retail\''),
          reason:
              'walk-in must be declared by the source, not inferred downstream',
        );
      },
    );

    test(
      'defines sales.can_access_sales_order enforcing auth.uid(), membership and real order existence',
      () {
        expect(sourceDraftFile.existsSync(), isTrue);
        expect(
          sql,
          contains('create or replace function sales.can_access_sales_order('),
          reason: 'Must define sales.can_access_sales_order',
        );
        expect(sql, contains('auth.uid()'));
        expect(sql, contains('iam.memberships'));
        expect(sql, contains('sales.sales_orders'));
        expect(
          sql,
          matches(
            RegExp(
              r'grant\s+execute\s+on\s+function\s+sales\.can_access_sales_order\(.*?\)\s+to\s+[^;]*\bauthenticated\b',
              caseSensitive: false,
            ),
          ),
          reason:
              'sales.can_access_sales_order must be executable by authenticated users',
        );
      },
    );

    test(
      'can_access_sales_order enforces permission, active membership and store access',
      () {
        expect(sourceDraftFile.existsSync(), isTrue);
        expect(sql, contains('p_actor_id is null'));
        expect(
          sql,
          contains("iam.has_permission(p_tenant_id, 'sales.order.view')"),
        );
        expect(sql, contains('and is_active'));
        expect(sql, contains('and removed_at is null'));
        expect(
          sql,
          contains(
            'iam.can_access_store(p_tenant_id, v_order_store_id, p_actor_id)',
          ),
        );
        expect(
          sql,
          isNot(contains('iam.membership_store_scopes')),
          reason: 'IAM single-store era removed membership_store_scopes',
        );
        expect(
          sql,
          isNot(contains("status = 'active'\n  ) then")),
          reason: 'iam.memberships has no status column (is_active/removed_at)',
        );
        expect(sql, contains('set search_path = sales, iam, public, pg_temp'));
      },
    );

    test('draft contains no destructive statements', () {
      expect(sourceDraftFile.existsSync(), isTrue);
      expect(
        sql,
        isNot(matches(RegExp(r'\btruncate\b', caseSensitive: false))),
        reason: 'Draft must not truncate tables',
      );
      expect(
        sql,
        isNot(matches(RegExp(r'\bdelete\s+from\b', caseSensitive: false))),
        reason: 'Draft must not delete from tables',
      );
    });

    test('fixture table is gone; Theme 05 is the only order source', () {
      expect(
        sql,
        isNot(contains('sales.einvoice_acceptance_orders')),
        reason: 'fixture existed only while Theme 05 was unavailable',
      );
    });
  });
}
