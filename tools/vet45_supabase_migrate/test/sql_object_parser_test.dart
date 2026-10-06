import 'package:test/test.dart';
import 'package:vet45_supabase_migrate/sql_object_parser.dart';

void main() {
  group('parseSqlObjects', () {
    test('parses every function overload with schema, name and signature', () {
      const sql = r'''
-- header comment; with semicolon
create or replace function catalog.search_products(p_tenant_id uuid, p_query text)
returns setof jsonb
language plpgsql
as $$
begin
  perform 1; -- inner ; statements
  return query select '{"a":";"}'::jsonb;
end;
$$;

CREATE FUNCTION catalog.search_products(
  p_tenant_id uuid,
  p_query     text,
  p_limit     int default 20
) RETURNS setof jsonb LANGUAGE sql AS $fn$ select null::jsonb; $fn$;
''';

      final objects = parseSqlObjects(sql);

      expect(objects, hasLength(2));
      expect(objects.every((o) => o.kind == SqlObjectKind.function), isTrue);
      expect(objects.map((o) => o.qualifiedName).toSet(), {
        'catalog.search_products',
      });
      expect(objects[0].signature,
          'catalog.search_products(p_tenant_id uuid, p_query text)');
      expect(objects[1].signature,
          'catalog.search_products(p_tenant_id uuid, p_query text, p_limit int default 20)');
    });

    test('returns the verbatim SQL block of each object', () {
      const fn = r'''create function iam.f(numeric(10, 2))
returns int language sql as $$ select 1; $$;''';
      const view = 'create or replace view iam.v as select 1;';
      final objects = parseSqlObjects('-- lead\n$fn\n\n/* c; */ $view\n');

      expect(objects.map((o) => o.sql), [fn, view]);
      expect(objects[0].signature, 'iam.f(numeric(10, 2))');
    });

    test('parses views including materialized views', () {
      final objects = parseSqlObjects('''
create or replace view sales.order_summary as select 1 as x;
create materialized view if not exists sales.daily_totals as select 2;
''');

      expect(objects.map((o) => (o.kind, o.qualifiedName)), [
        (SqlObjectKind.view, 'sales.order_summary'),
        (SqlObjectKind.view, 'sales.daily_totals'),
      ]);
      expect(objects.every((o) => o.table == null && o.signature == null),
          isTrue);
    });

    test('parses triggers with their table', () {
      final objects = parseSqlObjects('''
create trigger trg_touch_updated_at
  before insert or update of name on catalog.products
  for each row execute function catalog.touch_updated_at();
CREATE OR REPLACE TRIGGER "Trg_Audit" AFTER DELETE ON iam.memberships
  FOR EACH ROW EXECUTE PROCEDURE iam.audit();
''');

      expect(objects, hasLength(2));
      expect(objects[0].kind, SqlObjectKind.trigger);
      expect(objects[0].schema, 'catalog');
      expect(objects[0].name, 'trg_touch_updated_at');
      expect(objects[0].table, 'catalog.products');
      expect(objects[1].name, 'Trg_Audit');
      expect(objects[1].table, 'iam.memberships');
    });

    test('parses policies with their table', () {
      final objects = parseSqlObjects('''
create policy "Tenant members can read" on partner.partners
  for select using (tenant_id = any (iam.current_tenant_ids()));
create policy tenant_write on partner.partners for insert with check (true);
''');

      expect(objects.map((o) => (o.kind, o.name, o.table, o.schema)), [
        (
          SqlObjectKind.policy,
          'Tenant members can read',
          'partner.partners',
          'partner',
        ),
        (SqlObjectKind.policy, 'tenant_write', 'partner.partners', 'partner'),
      ]);
    });

    test('ignores other statements', () {
      final objects = parseSqlObjects('''
create table catalog.t (id uuid);
alter table catalog.t enable row level security;
grant execute on function catalog.f() to authenticated;
drop function if exists catalog.f();
''');

      expect(objects, isEmpty);
    });
  });
}
