import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/_drafts/013_iam_platform_audit_read.sql',
    ).readAsStringSync();
  });

  group('iam.audit_logs canonical table', () {
    test('declares the locked §3.4 columns', () {
      for (final col in const [
        'tenant_id uuid',
        'scope text not null',
        'actor_user_id uuid',
        'actor_snapshot jsonb',
        'event_code text not null',
        'subject_type text not null',
        'subject_id text not null',
        'result text not null',
        'source text not null',
        'tracking_id text not null',
        'before_state jsonb',
        'after_state jsonb',
        'redaction_flags text[] not null',
        'occurred_at timestamptz not null',
      ]) {
        expect(sql, contains(col), reason: 'missing column $col');
      }
    });

    test('constrains scope and requires tenant_id for tenant scope', () {
      expect(sql, contains("check (scope in ('tenant', 'platform'))"));
      expect(sql, contains("scope <> 'tenant' or tenant_id is not null"));
    });

    test('has both required indexes', () {
      expect(sql, contains('(tenant_id, occurred_at desc, id desc)'));
      expect(sql, contains('(scope, occurred_at desc, id desc)'));
    });

    test('is immutable — app roles cannot insert/update/delete directly', () {
      expect(
        sql,
        contains(
          'revoke insert, update, delete on table iam.audit_logs from public, anon, authenticated',
        ),
      );
    });
  });

  group('iam.append_audit_log', () {
    test('is not granted directly to app roles', () {
      expect(
        sql,
        contains(
          'revoke all on function iam.append_audit_log(text, uuid, uuid, text, text, text, text, text, text, jsonb, jsonb, text[]) from public, anon, authenticated',
        ),
      );
      expect(
        sql,
        isNot(contains('grant execute on function iam.append_audit_log')),
      );
    });

    test('applies the recursive secret denylist', () {
      expect(sql, contains('iam._audit_redact(p_before)'));
      expect(sql, contains('iam._audit_redact(p_after)'));
      for (final key in const [
        'password',
        'refresh_token',
        'otp',
        'session',
        'token_hash',
      ]) {
        expect(sql, contains("'$key'"), reason: 'denylist missing $key');
      }
    });
  });

  group('iam.record_account_security_event', () {
    test('derives actor from auth.uid() and calls append helper', () {
      expect(sql, contains('v_actor uuid := auth.uid()'));
      expect(sql, contains('return iam.append_audit_log('));
      expect(
        sql,
        contains(
          'grant execute on function iam.record_account_security_event(text, text, text) to authenticated',
        ),
      );
    });
  });

  test('no audit.* schema and no dual-write helper', () {
    expect(sql, isNot(contains('create schema audit')));
    expect(sql, isNot(contains('insert into iam.platform_audit_logs')));
  });
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    current = parent;
  }
  return current;
}
