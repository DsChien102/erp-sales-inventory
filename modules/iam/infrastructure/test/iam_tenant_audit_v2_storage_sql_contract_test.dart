import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String draft;
  late Directory migrations;

  setUpAll(() {
    final root = _findRepoRoot();
    migrations = Directory('${root.path}/supabase/migrations');
    draft = File(
      '${root.path}/supabase/migrations/_drafts/003_iam_tenant_audit_history_v2_storage.sql',
    ).readAsStringSync();
  });

  group('iam_tenant_audit_history_v2_storage draft SQL contract', () {
    test('declares correct patch header with touches', () {
      expect(draft, contains('-- Title: IAM tenant audit history V2 storage'));
      expect(draft, contains('-- Kind: patch'));
      expect(draft, contains('-- Intent: iam_tenant_audit_history_v2'));
      expect(
        draft,
        contains(
          '-- Touches: iam._audit_redact, iam._audit_event_category, iam._build_audit_actor_snapshot, iam._build_audit_subject_snapshot, iam.append_audit_log',
        ),
      );
    });

    test('adds columns and constraints for V2 storage', () {
      expect(draft, contains('add column if not exists event_category text'));
      expect(draft, contains('add column if not exists subject_snapshot jsonb'));
      expect(draft, contains('add column if not exists search_document text'));
      expect(
        draft,
        contains(
          "check (event_category is null or event_category in ('member', 'role', 'organization', 'invitation', 'account', 'security', 'system'))",
        ),
      );
    });

    test('defines category resolver and builders', () {
      expect(draft, contains('function iam._audit_event_category'));
      expect(draft, contains('function iam._build_audit_actor_snapshot'));
      expect(draft, contains('function iam._build_audit_subject_snapshot'));
      expect(draft, contains("raise exception 'AUDIT_EVENT_UNREGISTERED:%'"));
    });

    test('registry accepts every literal append_audit_log producer event code', () {
      final registryStart = draft.indexOf(
        'create or replace function iam._audit_event_category',
      );
      final registryEnd = draft.indexOf(
        'revoke all on function iam._audit_event_category',
      );
      expect(registryStart, greaterThanOrEqualTo(0));
      expect(registryEnd, greaterThan(registryStart));
      final registry = draft.substring(registryStart, registryEnd);

      final producerCodes = <String>{};
      final literalEvent = RegExp(r"p_event_code\s*=>\s*'([^']+)'");
      for (final file in migrations.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.sql')) continue;
        for (final match in literalEvent.allMatches(file.readAsStringSync())) {
          producerCodes.add(match.group(1)!);
        }
      }

      expect(producerCodes, isNotEmpty);
      for (final code in producerCodes) {
        expect(
          registry,
          contains("'$code'"),
          reason: 'append_audit_log producer event $code must be registered',
        );
      }
    });

    test('uses canonical identity and invitation schema without raw PII fallback', () {
      expect(draft, isNot(contains('auth.users')));
      expect(draft, isNot(contains('raw_user_meta_data')));
      expect(draft, contains('iam.platform_user_profiles'));
      expect(draft, contains('iam.tenant_legal_profiles'));
      expect(draft, contains('iam.platform_admins'));
      expect(draft, contains('invitee_email'));
      expect(draft, contains('initial_role_id'));
      expect(draft, isNot(contains('iam.platform_users')));
      expect(draft, isNot(contains('i.email')));
      expect(draft, isNot(contains('i.role')));
      expect(draft, isNot(contains('phone_masked')));
      expect(
        draft,
        isNot(contains("display_name,\n      email,")),
        reason: 'actor display name must never fall back to raw email',
      );
    });

    test('snapshot builders scope tenant-owned records to the audit tenant', () {
      expect(draft, contains('t.id = p_tenant_id'));
      expect(draft, contains('m.tenant_id = p_tenant_id'));
      expect(draft, contains('i.tenant_id = p_tenant_id'));
    });

    test('never backfills legacy actor/subject snapshots', () {
      expect(draft, isNot(contains('set actor_snapshot =')));
      expect(draft, isNot(contains('set subject_snapshot =')));
    });

    test('keeps unresolved snapshot display names unavailable rather than identifiers', () {
      expect(draft, contains("'display_name', v_display_name"));
      expect(draft, isNot(contains("'display_name', coalesce(v_display_name, p_subject_id)")));
      expect(draft, isNot(contains('p_actor_user_id::text')));
      expect(draft, contains('if v_display_name is null then'));
      expect(draft, contains('return null;'));
    });

    test('redacts normalized credential families in nested objects and arrays', () {
      expect(draft, contains("regexp_replace(lower(v_key), '[-_]', '', 'g')"));
      for (final key in [
        'credential',
        'clientsecret',
        'passwordhash',
        'apikey',
        'privatekey',
        'cookie',
        'bearer',
        'secretpayloadciphertext',
        'token',
        'otp',
        'verificationcode',
        'recoverycode',
      ]) {
        expect(draft, contains("v_normalized_key like '%$key%'"));
      }
      expect(draft, contains("v_normalized_key in ('code')"));
      expect(draft, contains('jsonb_array_elements(p)'));
      expect(draft, contains('iam._audit_redact(v_val)'));
    });

    test('uses platform operator actor provenance without tenant role fabrication', () {
      expect(draft, contains("'platform_operator'"));
      expect(draft, contains("'platform_admin'"));
      expect(draft, contains("'Quản trị nền tảng'"));
      expect(draft, contains("if v_actor_type <> 'platform_operator'"));
    });

    test('backfills deterministic event_category for known event codes', () {
      expect(draft, contains("update iam.audit_logs\nset event_category = case event_code"));
    });

    test('creates GIN trigram index for search_document', () {
      expect(draft, contains('create index if not exists idx_iam_audit_logs_search_document'));
      expect(draft, contains('using gin (search_document extensions.gin_trgm_ops)'));
    });

    test('preserves append_audit_log signature and security revocation', () {
      expect(
        draft,
        contains(
          'create or replace function iam.append_audit_log(\n  p_scope text,\n  p_tenant_id uuid,\n  p_actor_user_id uuid,\n  p_event_code text,\n  p_subject_type text,\n  p_subject_id text,\n  p_result text,\n  p_source text,\n  p_tracking_id text,\n  p_before jsonb default null,\n  p_after jsonb default null,\n  p_redaction_flags text[] default \'{}\'::text[]\n)',
        ),
      );
      expect(
        draft,
        contains(
          'revoke all on function iam.append_audit_log(text, uuid, uuid, text, text, text, text, text, text, jsonb, jsonb, text[]) from public, anon, authenticated',
        ),
      );
    });

    test('search document is built only from masked snapshots and identifiers', () {
      expect(draft, contains('v_safe_subject_id text'));
      expect(draft, contains('v_safe_tracking_id text'));
      expect(draft, contains('v_safe_subject_id,'));
      expect(draft, contains('v_safe_tracking_id,'));
      expect(draft, contains("v_actor_snapshot->>'display_name'"));
      expect(draft, contains("v_subject_snapshot->>'display_name'"));
      expect(draft, isNot(contains("v_actor_snapshot->>'email'")));
      expect(draft, isNot(contains("v_subject_snapshot->>'email'")));
      expect(draft, isNot(contains("v_actor_snapshot->>'phone'")));
      expect(draft, isNot(contains("v_subject_snapshot->>'phone'")));
    });

    test('search scrubbing catches email and phone embedded in identifiers', () {
      final emailMatch = RegExp(
        r"v_email_pattern constant text := '([^']+)';",
      ).firstMatch(draft);
      final phoneMatch = RegExp(
        r"v_phone_pattern constant text := '([^']+)';",
      ).firstMatch(draft);
      expect(emailMatch, isNotNull);
      expect(phoneMatch, isNotNull);
      if (emailMatch == null || phoneMatch == null) return;

      final emailPattern = RegExp(
        emailMatch.group(1)!,
        caseSensitive: false,
      );
      final phonePattern = RegExp(phoneMatch.group(1)!);
      expect(emailPattern.hasMatch('retry:user@example.com:2'), isTrue);
      expect(phonePattern.hasMatch('call:+84901234567'), isTrue);
      expect(
        draft,
        contains('regexp_replace(regexp_replace(p_subject_id'),
      );
      expect(
        draft,
        contains('regexp_replace(regexp_replace(p_tracking_id'),
      );
    });
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
