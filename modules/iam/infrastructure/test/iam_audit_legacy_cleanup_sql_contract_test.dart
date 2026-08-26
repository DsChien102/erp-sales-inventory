import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String canonicalAuditSql;
  late String cleanupDraftSql;

  setUpAll(() {
    final root = _findRepoRoot();
    canonicalAuditSql = File(
      '${root.path}/supabase/migrations/20260811013_iam_platform_audit_read.sql',
    ).readAsStringSync();
    cleanupDraftSql = File(
      '${root.path}/supabase/migrations/_drafts/006_iam_audit_owner_activation_cleanup.sql',
    ).readAsStringSync();
  });

  group('platform audit cleanup', () {
    test('platform audit reads canonical audit_logs only', () {
      // `get_platform_audit_log` và `search_platform_audit_logs` có thể xuất
      // hiện theo BẤT KỲ thứ tự nào trong file migration (hiện tại hàm detail
      // đứng trước). Cắt thân mỗi hàm từ header của chính nó đến ranh giới hàm
      // kế tiếp thay vì giả định thứ tự.
      String bodyOf(String header) {
        final start = canonicalAuditSql.indexOf(header);
        if (start < 0) return '';
        final next = canonicalAuditSql.indexOf(
          'create or replace function ',
          start + header.length,
        );
        return next < 0
            ? canonicalAuditSql.substring(start)
            : canonicalAuditSql.substring(start, next);
      }

      final searchBody = bodyOf(
        'create or replace function iam.search_platform_audit_logs(',
      );
      final detailBody = bodyOf(
        'create or replace function iam.get_platform_audit_log(',
      );
      expect(searchBody, isNotEmpty);
      expect(detailBody, isNotEmpty);

      expect(searchBody, contains('from iam.audit_logs a'));
      expect(searchBody, contains("where a.scope = 'platform'"));
      expect(searchBody, isNot(contains('from iam.platform_audit_logs')));

      expect(detailBody, contains('from iam.audit_logs a'));
      expect(detailBody, contains("and a.scope = 'platform'"));
      expect(detailBody, isNot(contains('from iam.platform_audit_logs')));
    });

    test('cleanup draft drops legacy platform_audit_logs storage', () {
      expect(
        cleanupDraftSql,
        contains('drop table if exists iam.platform_audit_logs'),
      );
      expect(
        cleanupDraftSql,
        contains(
          'drop function if exists iam._platform_audit_redacted_payload(jsonb)',
        ),
      );
      expect(
        cleanupDraftSql,
        isNot(contains('insert into iam.platform_audit_logs')),
      );
    });

    test('cleanup draft drops the dead legacy lifecycle overloads that still '
        'wrote to platform_audit_logs', () {
      // Gateway đang chạy gọi các overload mới mang
      // (p_expected_version, p_idempotency_key); các overload đó KHÔNG chạm
      // platform_audit_logs. Chỉ các overload cũ 1-/2-tham số này còn tham
      // chiếu bảng, nên phải drop chúng TRƯỚC bảng.
      expect(
        cleanupDraftSql,
        contains('drop function if exists iam.suspend_platform_user(uuid, text)'),
      );
      expect(
        cleanupDraftSql,
        contains('drop function if exists iam.restore_platform_user(uuid)'),
      );
      expect(
        cleanupDraftSql,
        contains('drop function if exists iam.send_activation_invitation(uuid)'),
      );
      expect(
        cleanupDraftSql,
        contains(
          'drop function if exists iam.request_platform_password_reset(uuid)',
        ),
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
