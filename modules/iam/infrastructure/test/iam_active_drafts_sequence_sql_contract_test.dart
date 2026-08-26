import 'dart:io';

import 'package:test/test.dart';

void main() {
  late Directory drafts;
  late List<File> activeFiles;
  late String activeSql;

  setUpAll(() {
    final root = _findRepoRoot();
    drafts = Directory('${root.path}/supabase/migrations/_drafts');
    activeFiles =
        drafts.listSync().whereType<File>().where((file) => file.path.endsWith('.sql')).toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    activeSql = activeFiles.map((file) => file.readAsStringSync()).join('\n');
  });

  test('only the final active sequence is bundled', () {
    expect(
      activeFiles.map((file) => file.uri.pathSegments.last),
      equals([
        '002_iam_fix_utc_now_offset.sql',
        '004_iam_tenant_audit_history_v2_payloads.sql',
        '006_iam_audit_owner_activation_cleanup.sql',
        '007_iam_audit_logs_v2_rebuild.sql',
      ]),
    );
  });

  test('superseded drafts are retained outside the active bundle', () {
    final archive = Directory('${drafts.path}/_archive');
    final names = archive
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .toSet();
    expect(
      names,
      containsAll({
        '001_iam_pending_platform_profile_onboarding.sql',
        '003_iam_tenant_audit_history_v2_storage.sql',
        '005_iam_tenant_audit_history_v2_read.sql',
      }),
    );
  });

  test('owner activation storage is only retired, never recreated or queried', () {
    final executableOwnerLines = activeSql
        .split('\n')
        .map((line) => line.trim())
        .where((line) => !line.startsWith('--'))
        .where((line) => line.contains('owner_activations'))
        .toList();
    expect(executableOwnerLines, equals(['drop table if exists iam.owner_activations;']));
    expect(
      activeSql,
      isNot(contains('create or replace function iam.inspect_owner_activation(')),
    );
    expect(
      activeSql,
      isNot(contains('create or replace function iam.accept_owner_activation(')),
    );
  });

  test('the final drafts own overlapping invitation and audit RPCs', () {
    final cleanup = File(
      '${drafts.path}/006_iam_audit_owner_activation_cleanup.sql',
    ).readAsStringSync();
    final rebuild = File(
      '${drafts.path}/007_iam_audit_logs_v2_rebuild.sql',
    ).readAsStringSync();

    expect(
      'create or replace function iam.accept_invitation('.allMatches(activeSql),
      hasLength(1),
    );
    expect(cleanup, contains('create or replace function iam.accept_invitation('));
    expect(
      rebuild,
      contains('create or replace function iam.search_tenant_audit_logs_v2('),
    );
    expect(
      rebuild,
      isNot(contains('create or replace function iam.search_tenant_audit_logs(')),
    );
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
