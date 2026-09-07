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

String _extractFunction(String sql, String signaturePrefix) {
  final start = sql.indexOf(signaturePrefix);
  if (start < 0) {
    return '';
  }
  final revoke = sql.indexOf('revoke all on function', start);
  final nextCreate = sql.indexOf(
    '\ncreate or replace function',
    start + signaturePrefix.length,
  );
  final endCandidates = [
    if (revoke > start) revoke,
    if (nextCreate > start) nextCreate,
    sql.length,
  ]..sort();
  return sql.substring(start, endCandidates.first);
}

void main() {
  late String draft006Sql;
  late String draft007Sql;
  late String draft008Sql;
  late String draft010Sql;
  late String draft013Sql;
  late String draft014Sql;

  setUpAll(() {
    final root = _repoRoot();
    final draft006 = File(
      '${root.path}/supabase/migrations/_drafts/'
      '006_einvoice_buyer_completion_and_preview_rpcs.sql',
    );
    final draft007 = File(
      '${root.path}/supabase/migrations/_drafts/'
      '007_einvoice_issuance_schema_and_publish_rpcs.sql',
    );
    final draft008 = File(
      '${root.path}/supabase/migrations/_drafts/'
      '008_einvoice_auto_issuance_and_retry_rpcs.sql',
    );
    final draft010 = File(
      '${root.path}/supabase/migrations/_drafts/'
      '010_einvoice_official_view_rpcs.sql',
    );
    final draft013 = File(
      '${root.path}/supabase/migrations/_drafts/'
      '013_einvoice_delivery_schema_and_start_rpcs.sql',
    );
    final draft014 = File(
      '${root.path}/supabase/migrations/_drafts/'
      '014_einvoice_delivery_results_and_projection_rpcs.sql',
    );
    draft006Sql = draft006.existsSync() ? draft006.readAsStringSync() : '';
    draft007Sql = draft007.existsSync() ? draft007.readAsStringSync() : '';
    draft008Sql = draft008.existsSync() ? draft008.readAsStringSync() : '';
    draft010Sql = draft010.existsSync() ? draft010.readAsStringSync() : '';
    draft013Sql = draft013.existsSync() ? draft013.readAsStringSync() : '';
    draft014Sql = draft014.existsSync() ? draft014.readAsStringSync() : '';
  });

  group('Access control and scope SQL contract', () {
    test(
      'acceptance-facing RPCs use canonical two-argument iam.has_permission',
      () {
        final readinessFn = _extractFunction(
          draft006Sql,
          'create or replace function einvoice.get_issuance_readiness(',
        );
        final requestPreviewFn = _extractFunction(
          draft006Sql,
          'create or replace function einvoice.request_invoice_preview(',
        );
        final getPreviewFn = _extractFunction(
          draft006Sql,
          'create or replace function einvoice.get_invoice_preview(',
        );
        final projectionFn = _extractFunction(
          draft014Sql,
          'create or replace function einvoice.get_order_invoice_projection(',
        );

        expect(
          '$draft006Sql\n$draft008Sql\n$draft014Sql',
          isNot(
            matches(
              RegExp(
                r'iam\.has_permission\(\s*p_tenant_id\s*,\s*p_actor_id\s*,',
              ),
            ),
          ),
          reason:
              'IAM exposes has_permission(uuid, text); passing actor_id causes PostgreSQL 42883',
        );
        expect(
          readinessFn,
          contains("iam.has_permission(p_tenant_id, 'einvoice.view')"),
        );
        expect(
          requestPreviewFn,
          contains(
            "iam.has_permission(p_tenant_id, 'einvoice.manage_issuance')",
          ),
        );
        expect(
          requestPreviewFn,
          contains("iam.has_permission(p_tenant_id, 'einvoice.view')"),
        );
        expect(
          getPreviewFn,
          contains("iam.has_permission(p_tenant_id, 'einvoice.view')"),
        );
        expect(
          projectionFn,
          contains("iam.has_permission(p_tenant_id, 'einvoice.view')"),
        );
      },
    );

    test(
      'sales.can_access_sales_order in draft 010 is not a stub returning false',
      () {
        expect(
          draft010Sql,
          isNot(contains('select false;')),
          reason:
              'Draft 010 must not contain the placeholder stub returning false for sales.can_access_sales_order',
        );
      },
    );

    test(
      'get_order_invoice_projection enforces auth.uid(), actor equality, permission, and sales scope',
      () {
        final projectionFn = _extractFunction(
          draft014Sql,
          'create or replace function einvoice.get_order_invoice_projection(',
        );
        expect(
          projectionFn.isNotEmpty,
          isTrue,
          reason: 'get_order_invoice_projection must exist',
        );

        expect(
          projectionFn,
          contains('auth.uid()'),
          reason: 'Must check auth.uid() is not null or equals actor',
        );
        expect(
          projectionFn,
          contains('p_actor_id'),
          reason: 'Must enforce actor equality with auth.uid()',
        );
        expect(
          projectionFn,
          contains('einvoice.view'),
          reason: 'Must enforce einvoice.view IAM permission',
        );
        expect(
          projectionFn,
          contains('sales.can_access_sales_order('),
          reason: 'Must enforce sales.can_access_sales_order data scope gate',
        );
      },
    );

    test(
      'get_order_invoice_projection grants execute to authenticated and service_role',
      () {
        final grantIndex = draft014Sql.lastIndexOf(
          'grant execute on function einvoice.get_order_invoice_projection',
        );
        expect(grantIndex, greaterThanOrEqualTo(0));
        final grantSection = draft014Sql.substring(grantIndex);

        expect(
          grantSection,
          matches(
            RegExp(
              r'grant\s+execute\s+on\s+function\s+einvoice\.get_order_invoice_projection\(.*?\)\s+to\s+[^;]*\bauthenticated\b',
              caseSensitive: false,
            ),
          ),
          reason:
              'Final get_order_invoice_projection grant must include authenticated role',
        );
        expect(
          grantSection,
          matches(
            RegExp(
              r'grant\s+execute\s+on\s+function\s+einvoice\.get_order_invoice_projection\(.*?\)\s+to\s+[^;]*\bservice_role\b',
              caseSensitive: false,
            ),
          ),
          reason:
              'Final get_order_invoice_projection grant must include service_role',
        );
      },
    );

    test(
      'issue_invoice and retry_issuance enforce auth, issue/manage_issuance, and sales scope',
      () {
        final issueFn = _extractFunction(
          draft008Sql,
          'create or replace function einvoice.issue_invoice(',
        );
        final retryFn = _extractFunction(
          draft008Sql,
          'create or replace function einvoice.retry_issuance(',
        );

        for (final entry in [
          ('issue_invoice', issueFn),
          ('retry_issuance', retryFn),
        ]) {
          final name = entry.$1;
          final body = entry.$2;
          expect(body.isNotEmpty, isTrue, reason: '$name must exist in draft 008');
          expect(body, contains('auth.uid()'), reason: '$name must check auth.uid()');
          expect(
            body,
            contains("iam.has_permission(p_tenant_id, 'einvoice.issue')"),
            reason: '$name must allow einvoice.issue',
          );
          expect(
            body,
            contains(
              "iam.has_permission(p_tenant_id, 'einvoice.manage_issuance')",
            ),
            reason: '$name must allow einvoice.manage_issuance fallback',
          );
          expect(
            body,
            contains('sales.can_access_sales_order('),
            reason: '$name must enforce sales scope',
          );
        }
      },
    );

    test(
      'issue_invoice and retry_issuance grant execute to authenticated and service_role',
      () {
        for (final fnName in ['issue_invoice', 'retry_issuance']) {
          final grantIndex = draft008Sql.lastIndexOf(
            'grant execute on function einvoice.$fnName',
          );
          expect(
            grantIndex,
            greaterThanOrEqualTo(0),
            reason: 'draft 008 must grant execute on einvoice.$fnName',
          );
          final grantSection = draft008Sql.substring(grantIndex);
          final grantEnd = grantSection.indexOf(';');
          final grantStmt = grantSection.substring(0, grantEnd + 1);

          expect(
            grantStmt,
            matches(
              RegExp(
                r'to\s+[^;]*\bauthenticated\b',
                caseSensitive: false,
              ),
            ),
            reason: '$fnName grant must include authenticated',
          );
          expect(
            grantStmt,
            matches(
              RegExp(
                r'to\s+[^;]*\bservice_role\b',
                caseSensitive: false,
              ),
            ),
            reason: '$fnName grant must include service_role',
          );
        }
      },
    );

    test(
      'digest-using issuance RPCs include extensions on search_path',
      () {
        for (final entry in [
          (
            'create or replace function einvoice.issue_invoice(',
            'einvoice, iam, sales, extensions, public',
          ),
          (
            'create or replace function einvoice.retry_issuance(',
            'einvoice, iam, sales, extensions, public',
          ),
          (
            'create or replace function einvoice._start_issuance_attempt(',
            'einvoice, extensions, public',
          ),
          (
            'create or replace function einvoice.start_auto_issuance(',
            'einvoice, extensions, public',
          ),
          (
            'create or replace function einvoice.reevaluate_auto_issuance(',
            'einvoice, extensions, public',
          ),
        ]) {
          final body = _extractFunction(draft008Sql, entry.$1);
          expect(body.isNotEmpty, isTrue, reason: '${entry.$1} must exist');
          expect(
            body,
            contains('set search_path = ${entry.$2}'),
            reason:
                '${entry.$1} must include extensions so pgcrypto digest() resolves',
          );
        }
      },
    );

    test(
      'issuance and delivery RPCs compare provider_connection_status as connected',
      () {
        expect(draft007Sql, isNot(contains("'CONNECTED'")));
        expect(draft008Sql, isNot(contains("'CONNECTED'")));
        expect(draft013Sql, isNot(contains("'CONNECTED'")));
        expect(draft008Sql, contains("pc.status = 'connected'"));
      },
    );
  });
}
