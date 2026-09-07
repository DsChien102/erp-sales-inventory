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
  late File seedSqlFile;
  late String seedSql;
  late File triggerSqlFile;
  late String triggerSql;

  setUpAll(() {
    final root = _repoRoot();
    sourceDraftFile = File(
      '${root.path}/supabase/migrations/_drafts/'
      '005_sales_einvoice_dev_acceptance_source.sql',
    );
    sql = sourceDraftFile.existsSync()
        ? sourceDraftFile.readAsStringSync()
        : '';

    seedSqlFile = File(
      '${root.path}/scripts/supabase/seed_einvoice_dev_acceptance_order.sql',
    );
    seedSql = seedSqlFile.existsSync() ? seedSqlFile.readAsStringSync() : '';

    triggerSqlFile = File(
      '${root.path}/scripts/supabase/trigger_einvoice_dev_acceptance_observation.sql',
    );
    triggerSql = triggerSqlFile.existsSync()
        ? triggerSqlFile.readAsStringSync()
        : '';
  });

  group('Sales acceptance source SQL contract', () {
    test('source draft file exists in supabase/migrations/_drafts/', () {
      expect(
        sourceDraftFile.existsSync(),
        isTrue,
        reason:
            'Missing 005_sales_einvoice_dev_acceptance_source.sql draft in _drafts/',
      );
    });

    test(
      'declares sales.einvoice_acceptance_orders with RLS and no authenticated grant',
      () {
        expect(sourceDraftFile.existsSync(), isTrue);
        expect(
          sql,
          contains(
            'create table if not exists sales.einvoice_acceptance_orders',
          ),
          reason: 'Must define sales.einvoice_acceptance_orders table',
        );
        expect(
          sql,
          contains(
            'alter table sales.einvoice_acceptance_orders enable row level security',
          ),
          reason: 'RLS must be enabled on sales.einvoice_acceptance_orders',
        );
        expect(
          sql,
          contains(
            'revoke all on sales.einvoice_acceptance_orders from public, anon, authenticated',
          ),
          reason:
              'Must revoke broad access on sales.einvoice_acceptance_orders',
        );
        expect(
          sql,
          isNot(
            matches(
              RegExp(
                r'grant\s+.*?\s+on\s+sales\.einvoice_acceptance_orders\s+to\s+authenticated',
                caseSensitive: false,
              ),
            ),
          ),
          reason:
              'sales.einvoice_acceptance_orders must have no table grant to authenticated',
        );
      },
    );

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

    test(
      'defines sales.can_access_sales_order enforcing auth.uid(), membership and fixture existence',
      () {
        expect(sourceDraftFile.existsSync(), isTrue);
        expect(
          sql,
          contains('create or replace function sales.can_access_sales_order('),
          reason: 'Must define sales.can_access_sales_order',
        );
        expect(sql, contains('auth.uid()'));
        expect(sql, contains('iam.memberships'));
        expect(sql, contains('sales.einvoice_acceptance_orders'));
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
      'draft contains no destructive statements and seeds only via separate script',
      () {
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
        expect(
          sql,
          isNot(
            matches(
              RegExp(
                r'insert\s+into\s+sales\.einvoice_acceptance_orders',
                caseSensitive: false,
              ),
            ),
          ),
          reason:
              'Draft must not seed fixture rows directly; seeding is script-only',
        );
      },
    );
  });

  group('Seed and Observation dev scripts contract', () {
    test(
      'seed SQL upserts fixed order e1000000-0000-4000-8000-000000000001 with 1,100,000 VND total',
      () {
        expect(seedSqlFile.existsSync(), isTrue);
        expect(seedSql, contains('e1000000-0000-4000-8000-000000000001'));
        expect(seedSql, contains('TEST-HDDT-001'));
        expect(
          seedSql,
          contains("'a73b8a24-2500-426a-a3a0-cba40c105bd2'::uuid"),
        );
        expect(
          seedSql,
          contains("'84fd1f8c-4e21-48d6-910f-6f31d067f149'::uuid"),
        );
        expect(seedSql, isNot(contains(":'tenant_id'")));
        expect(seedSql, isNot(contains(":'actor_id'")));
        expect(seedSql, contains('1000000'));
        expect(seedSql, contains('1100000'));
        expect(seedSql, contains('on conflict (tenant_id, id) do update'));
        expect(seedSql, isNot(contains('delete from')));
        expect(seedSql, isNot(contains('truncate')));
      },
    );

    test('trigger observation SQL calls service RPC for fixed order', () {
      expect(triggerSqlFile.existsSync(), isTrue);
      expect(triggerSql, contains('e1000000-0000-4000-8000-000000000001'));
      expect(
        triggerSql,
        contains('einvoice.request_provider_observation_refresh'),
      );
    });
  });
}
