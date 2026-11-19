import 'package:test/test.dart';
import 'package:c45_supabase_migrate/schema_lock.dart';

void main() {
  test('round-trips entries including quoted signatures', () {
    final lock = SchemaLock({
      'public.b_fn': const SchemaLockEntry(
        sourcePath: 'supabase/sql/public/functions/b_fn.sql',
        hash: 'sha256:abc',
        signatures: ['public.b_fn()'],
        lastMigration: '20990101001_first.sql',
      ),
      'catalog.a_fn': const SchemaLockEntry(
        sourcePath: 'modules/catalog/infrastructure/supabase/sql/functions/a_fn.sql',
        hash: 'sha256:def',
        signatures: [
          "catalog.a_fn(p_mode text default 'x')",
          'catalog.a_fn("Weird Name" int, p_tags text[])',
        ],
        lastMigration: '20990101002_second.sql',
      ),
    });

    final serialized = lock.serialize();
    final parsed = SchemaLock.parse(serialized);

    expect(serialized.indexOf('catalog.a_fn:'), lessThan(serialized.indexOf('public.b_fn:')));
    expect(parsed.entries.keys, unorderedEquals(['catalog.a_fn', 'public.b_fn']));
    final entry = parsed.entries['catalog.a_fn']!;
    expect(entry.sourcePath, lock.entries['catalog.a_fn']!.sourcePath);
    expect(entry.hash, 'sha256:def');
    expect(entry.signatures, lock.entries['catalog.a_fn']!.signatures);
    expect(entry.lastMigration, '20990101002_second.sql');
    expect(parsed.serialize(), serialized);
  });
}
