-- Partner v2: enable search by MST (tax_code) + email-only when query has @.
-- Context: TH-03/EP-01/US-01 — search tên, SĐT, email, MST
-- Safety: idempotent ; depends on partner.v_partner_list + partner.search_partners
-- Apply after 03_partner_v2_read.sql (or re-apply this alone if 03 already applied)
-- Note: tax_code appended at end of view — Postgres CREATE OR REPLACE VIEW
-- cannot insert/rename columns in the middle (42P16).
-- Heuristic: query chứa '@' → chỉ match email.

create or replace view partner.v_partner_list
with (security_invoker = true)
as
select
  p.partner_id,
  p.tenant_id,
  p.partner_type::text as partner_type,
  p.status::text as status,
  p.display_name,
  p.version,
  p.created_at,
  p.updated_at,
  coalesce(pp.phone, op.phone) as phone,
  coalesce(pp.email, op.email) as email,
  coalesce(
    (
      select jsonb_agg(pr.role::text order by pr.role::text)
      from partner.partner_roles pr
      where pr.partner_id = p.partner_id
        and pr.is_active = true
    ),
    '[]'::jsonb
  ) as roles,
  coalesce(pp.tax_code, op.tax_code) as tax_code
from partner.partners p
left join partner.person_profiles pp on pp.partner_id = p.partner_id
left join partner.organization_profiles op on op.partner_id = p.partner_id;

create or replace function partner.search_partners(
  p_tenant_id uuid,
  p_query text default null,
  p_partner_type text default null,
  p_role text default null,
  p_status text default null,
  p_page integer default 1,
  p_limit integer default 20,
  p_sort text default 'updated_at_desc'
)
returns table (
  items jsonb,
  page integer,
  "limit" integer,
  total bigint
)
language plpgsql
stable
security definer
set search_path = partner, iam, pg_temp
as $$
declare
  v_page integer := greatest(coalesce(p_page, 1), 1);
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 100);
  v_offset integer := (greatest(coalesce(p_page, 1), 1) - 1) * v_limit;
  v_query text := nullif(btrim(coalesce(p_query, '')), '');
  v_email_only boolean := v_query is not null and position('@' in v_query) > 0;
  v_total bigint;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'partner.view') then
    raise exception 'permission denied: partner.view';
  end if;

  select count(*)
  into v_total
  from partner.v_partner_list v
  where v.tenant_id = p_tenant_id
    and (p_status is not null or v.status <> 'deleted')
    and (p_status is null or v.status = p_status)
    and (p_partner_type is null or v.partner_type = p_partner_type)
    and (
      p_role is null
      or v.roles ? p_role
    )
    and (
      v_query is null
      or (
        v_email_only
        and coalesce(v.email, '') ilike '%' || v_query || '%'
      )
      or (
        not v_email_only
        and (
          v.display_name ilike '%' || v_query || '%'
          or coalesce(v.phone, '') ilike '%' || v_query || '%'
          or coalesce(v.email, '') ilike '%' || v_query || '%'
          or coalesce(v.tax_code, '') ilike '%' || v_query || '%'
        )
      )
    );

  return query
  select
    coalesce((
      select jsonb_agg(row_to_json(s)::jsonb)
      from (
        select
          v.partner_id,
          v.display_name,
          v.partner_type,
          v.status,
          v.roles,
          v.phone,
          v.email,
          v.tax_code,
          v.updated_at
        from partner.v_partner_list v
        where v.tenant_id = p_tenant_id
          and (p_status is not null or v.status <> 'deleted')
          and (p_status is null or v.status = p_status)
          and (p_partner_type is null or v.partner_type = p_partner_type)
          and (
            p_role is null
            or v.roles ? p_role
          )
          and (
            v_query is null
            or (
              v_email_only
              and coalesce(v.email, '') ilike '%' || v_query || '%'
            )
            or (
              not v_email_only
              and (
                v.display_name ilike '%' || v_query || '%'
                or coalesce(v.phone, '') ilike '%' || v_query || '%'
                or coalesce(v.email, '') ilike '%' || v_query || '%'
                or coalesce(v.tax_code, '') ilike '%' || v_query || '%'
              )
            )
          )
        order by
          case when coalesce(p_sort, 'updated_at_desc') = 'display_name_asc'
            then v.display_name end asc,
          case when coalesce(p_sort, 'updated_at_desc') = 'display_name_desc'
            then v.display_name end desc,
          case when coalesce(p_sort, 'updated_at_desc') = 'updated_at_asc'
            then v.updated_at end asc,
          v.updated_at desc,
          v.partner_id
        offset v_offset
        limit v_limit
      ) s
    ), '[]'::jsonb) as items,
    v_page as page,
    v_limit as "limit",
    v_total as total;
end;
$$;
