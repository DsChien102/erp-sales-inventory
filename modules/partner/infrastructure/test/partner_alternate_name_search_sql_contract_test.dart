import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('partner search SQL matches profile alternate names in both predicates', () {
    final repoRoot = _findRepoRoot();
    final sql = _readAuthoritativeSearchSql(repoRoot);
    expect(sql, contains('pp.nickname'));
    expect(
      RegExp(r"coalesce\(v\.nickname, ''\) ilike").allMatches(sql),
      hasLength(2),
    );
    expect(sql, contains('op.short_name'));
    expect(
      RegExp(r"coalesce\(v\.short_name, ''\) ilike").allMatches(sql),
      hasLength(2),
    );
  });
}

String _readAuthoritativeSearchSql(Directory repoRoot) {
  final migrations = Directory('${repoRoot.path}/supabase/migrations');
  final draft = File(
    '${migrations.path}/_drafts/001_partner_patch_alternate_name_search.sql',
  );
  if (draft.existsSync()) {
    return draft.readAsStringSync();
  }

  final definitions =
      migrations
          .listSync()
          .whereType<File>()
          .where((file) => RegExp(r'/\d+_.*\.sql$').hasMatch(file.path))
          .where(
            (file) => file.readAsStringSync().contains(
              'create or replace function partner.search_partners',
            ),
          )
          .toList()
        ..sort((left, right) => right.path.compareTo(left.path));
  if (definitions.isEmpty) {
    throw StateError('Could not locate partner.search_partners SQL');
  }
  return definitions.first.readAsStringSync();
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!File('${current.path}/pubspec.yaml').existsSync() ||
      !Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    current = parent;
  }
  return current;
}
