import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    sql = _readAuthoritativeSearchSql(_findRepoRoot());
  });

  test('search excludes roleless rows from total and items', () {
    expect(
      RegExp(
        r"p_role = 'any' and v\.roles <> '\[\]'::jsonb",
      ).allMatches(sql),
      hasLength(2),
    );
  });

  test('search matches partner alternate names in total and items', () {
    expect(
      RegExp(r"coalesce\(v\.nickname, ''\) ilike").allMatches(sql),
      hasLength(2),
    );
    expect(
      RegExp(r"coalesce\(v\.short_name, ''\) ilike").allMatches(sql),
      hasLength(2),
    );
  });

  test('organization search correlates active person contacts twice', () {
    expect(RegExp(r'and exists \(').allMatches(sql), hasLength(2));
    expect(
      RegExp(r'from partner\.organization_contacts oc').allMatches(sql),
      hasLength(2),
    );
    expect(
      RegExp(r'join partner\.partners cp').allMatches(sql),
      hasLength(2),
    );
    expect(
      RegExp(r'join partner\.person_profiles cpp').allMatches(sql),
      hasLength(2),
    );
    expect(
      RegExp(r"v\.partner_type = 'organization'").allMatches(sql),
      hasLength(2),
    );
    expect(RegExp(r"cp\.partner_type = 'person'").allMatches(sql), hasLength(2));
    expect(RegExp(r"cp\.status = 'active'").allMatches(sql), hasLength(2));
    expect(
      RegExp(r'oc\.organization_partner_id = v\.partner_id').allMatches(sql),
      hasLength(2),
    );
    expect(RegExp(r'oc\.tenant_id = p_tenant_id').allMatches(sql), hasLength(2));
  });

  test('contact matching covers identity fields but not link metadata', () {
    for (final field in [
      'cp.display_name',
      'cpp.full_name',
      'cpp.nickname',
      'cpp.title',
      'cpp.phone',
      'cpp.phone2',
    ]) {
      expect(
        RegExp('${RegExp.escape(field)}(?=\\s|,).*?ilike').allMatches(sql),
        hasLength(2),
        reason: '$field must be searched in total and items predicates',
      );
    }

    expect(
      RegExp(r"coalesce\(cpp\.email, ''\) ilike").allMatches(sql),
      hasLength(4),
      reason: 'contact email is searched in email-only and normal branches',
    );
    expect(sql, isNot(contains('oc.contact_role')));
    expect(sql, isNot(contains('oc.note')));
  });

  test('email-only branch matches only organization or contact email', () {
    expect(
      RegExp(
        r"v_email_only\s+and\s+coalesce\(v\.email, ''\) ilike",
      ).allMatches(sql),
      hasLength(2),
    );

    final contactEmailBeforeNormalFields = RegExp(
      r"v_email_only\s+and\s+coalesce\(cpp\.email, ''\) ilike.*?"
      r"or\s+\(\s*not v_email_only\s+and\s+\(",
      dotAll: true,
    );
    expect(contactEmailBeforeNormalFields.allMatches(sql), hasLength(2));
  });
}

String _readAuthoritativeSearchSql(Directory repoRoot) {
  final migrations = Directory('${repoRoot.path}/supabase/migrations');
  final draft = File(
    '${migrations.path}/_drafts/partner_list_search_behavior.sql',
  );
  if (draft.existsSync()) {
    return draft.readAsStringSync();
  }

  final legacyDraft = File(
    '${migrations.path}/_drafts/partner_exclude_roleless_search.sql',
  );
  if (legacyDraft.existsSync()) {
    return legacyDraft.readAsStringSync();
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
