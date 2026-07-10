-- Partner v2 read models: views + search/detail/history RPCs.
-- Context: TH-03/EP-01 CMD-01,02,11,13 + dup-check; harness/07-api-contracts.md
-- Safety: idempotent ; read-only objects
-- Depends on: partner_v2_schema.sql
-- Contracts: SearchPartnersQuery, GetPartnerDetailQuery, CheckDuplicatePartnersQuery,
--            CheckDeleteEligibilityQuery, GetPartnerHistoryQuery

-- Org delivery detail address (additive; safe if already present).
alter table partner.organization_profiles
  add column if not exists delivery_address text null;

-- ---------------------------------------------------------------------------
-- Views
-- ---------------------------------------------------------------------------

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

create or replace view partner.v_partner_detail
with (security_invoker = true)
as
select
  p.partner_id,
  p.tenant_id,
  p.partner_type::text as partner_type,
  p.status::text as status,
  p.display_name,
  p.version as expected_version,
  p.created_at,
  p.updated_at,
  coalesce(
    (
      select jsonb_agg(pr.role::text order by pr.role::text)
      from partner.partner_roles pr
      where pr.partner_id = p.partner_id
        and pr.is_active = true
    ),
    '[]'::jsonb
  ) as roles,
  case
    when pp.partner_id is null then null
    else jsonb_build_object(
      'title', pp.title,
      'full_name', pp.full_name,
      'nickname', pp.nickname,
      'phone', pp.phone,
      'phone2', pp.phone2,
      'email', pp.email,
      'tax_code', pp.tax_code,
      'invoice', jsonb_build_object(
        'name', pp.invoice_name,
        'address', pp.invoice_address,
        'email', pp.invoice_email
      ),
      'delivery', jsonb_build_object(
        'province', pp.delivery_province,
        'commune', pp.delivery_commune,
        'address', pp.delivery_address
      ),
      'note', pp.note
    )
  end as person_profile,
  case
    when op.partner_id is null then null
    else jsonb_build_object(
      'organization_type', op.organization_type::text,
      'organization_name', op.organization_name,
      'short_name', op.short_name,
      'intl_name', op.intl_name,
      'phone', op.phone,
      'email', op.email,
      'tax_code', op.tax_code,
      'company_address', op.company_address,
      'invoice', jsonb_build_object(
        'name', op.invoice_name,
        'address', op.invoice_address,
        'email', op.invoice_email
      ),
      'delivery', jsonb_build_object(
        'province', op.delivery_province,
        'commune', op.delivery_commune,
        'address', op.delivery_address
      ),
      'note', op.note
    )
  end as organization_profile,
  coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'person_partner_id', oc.person_partner_id,
          'display_name', cp.display_name,
          'title', cpp.title,
          'phone', coalesce(cpp.phone, null),
          'phone2', cpp.phone2,
          'email', coalesce(cpp.email, null),
          'contact_role', oc.contact_role,
          'is_primary', oc.is_primary,
          'note', oc.note
        )
        order by oc.is_primary desc, cp.display_name
      )
      from partner.organization_contacts oc
      join partner.partners cp on cp.partner_id = oc.person_partner_id
      left join partner.person_profiles cpp on cpp.partner_id = oc.person_partner_id
      where oc.organization_partner_id = p.partner_id
    ),
    '[]'::jsonb
  ) as contacts
from partner.partners p
left join partner.person_profiles pp on pp.partner_id = p.partner_id
left join partner.organization_profiles op on op.partner_id = p.partner_id;

create or replace view partner.v_partner_history
with (security_invoker = true)
as
select
  h.history_id,
  h.tenant_id,
  h.partner_id,
  h.role::text as role,
  h.transaction_type::text as transaction_type,
  h.source_module,
  h.source_id,
  h.reference_code,
  h.transaction_date,
  h.status,
  h.amount,
  h.currency,
  h.can_open_source,
  h.created_at,
  h.updated_at
from partner.partner_history_views h;

revoke all on partner.v_partner_list from public, anon;
revoke all on partner.v_partner_detail from public, anon;
revoke all on partner.v_partner_history from public, anon;
grant select on partner.v_partner_list to authenticated;
grant select on partner.v_partner_detail to authenticated;
grant select on partner.v_partner_history to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: search_partners (CMD-01 / SearchPartnersQuery)
-- ---------------------------------------------------------------------------

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

-- ---------------------------------------------------------------------------
-- RPC: get_partner_detail (CMD-02 / GetPartnerDetailQuery)
-- ---------------------------------------------------------------------------

create or replace function partner.get_partner_detail(
  p_tenant_id uuid,
  p_partner_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = partner, iam, pg_temp
as $$
declare
  v_row partner.v_partner_detail%rowtype;
  v_actions text[] := array[]::text[];
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'partner.detail.view') then
    raise exception 'permission denied: partner.detail.view';
  end if;

  select *
  into v_row
  from partner.v_partner_detail v
  where v.tenant_id = p_tenant_id
    and v.partner_id = p_partner_id;

  if not found then
    perform partner._raise_partner_error('NOT_FOUND', 'partner not found');
  end if;

  if v_row.status = 'deleted' then
    perform partner._raise_partner_error('NOT_FOUND', 'partner is deleted');
  end if;

  if iam.has_permission(p_tenant_id, 'partner.update') then
    v_actions := array_append(v_actions, 'update');
  end if;
  if iam.has_permission(p_tenant_id, 'partner.status.manage') then
    if v_row.status = 'active' then
      v_actions := array_append(v_actions, 'deactivate');
    elsif v_row.status = 'inactive' then
      v_actions := array_append(v_actions, 'reactivate');
    end if;
  end if;
  if iam.has_permission(p_tenant_id, 'partner.delete')
    and v_row.status in ('active', 'inactive') then
    v_actions := array_append(v_actions, 'delete');
  end if;
  if iam.has_permission(p_tenant_id, 'partner.transform')
    and v_row.partner_type = 'person'
    and v_row.status <> 'deleted' then
    v_actions := array_append(v_actions, 'transform');
  end if;
  if iam.has_permission(p_tenant_id, 'partner.contact.manage')
    and v_row.partner_type = 'organization' then
    v_actions := array_append(v_actions, 'manageContacts');
  end if;
  if iam.has_permission(p_tenant_id, 'partner.history.view') then
    v_actions := array_append(v_actions, 'viewHistory');
  end if;

  return jsonb_build_object(
    'partner_id', v_row.partner_id,
    'partner_type', v_row.partner_type,
    'status', v_row.status,
    'display_name', v_row.display_name,
    'roles', v_row.roles,
    'available_actions', to_jsonb(v_actions),
    'expected_version', v_row.expected_version,
    'person_profile', v_row.person_profile,
    'organization_profile', v_row.organization_profile,
    'contacts', v_row.contacts,
    'created_at', v_row.created_at,
    'updated_at', v_row.updated_at
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: check_duplicate (CheckDuplicatePartnersQuery)
-- ---------------------------------------------------------------------------

create or replace function partner.check_duplicate(
  p_tenant_id uuid,
  p_phone text default null,
  p_email text default null,
  p_tax_code text default null,
  p_name text default null,
  p_exclude_partner_id uuid default null
)
returns table (
  partner_id uuid,
  display_name text,
  matched_field text,
  partner_type text,
  matched_value text
)
language plpgsql
stable
security definer
set search_path = partner, iam, pg_temp
as $$
declare
  v_phone text := nullif(btrim(coalesce(p_phone, '')), '');
  v_email text := nullif(lower(btrim(coalesce(p_email, ''))), '');
  v_tax_code text := nullif(btrim(coalesce(p_tax_code, '')), '');
  v_name text := nullif(lower(btrim(coalesce(p_name, ''))), '');
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not (
    iam.has_permission(p_tenant_id, 'partner.create')
    or iam.has_permission(p_tenant_id, 'partner.update')
  ) then
    raise exception 'permission denied: partner.create';
  end if;

  return query
  select m.partner_id, m.display_name, m.matched_field, m.partner_type, m.matched_value
  from (
    select
      p.partner_id,
      p.display_name,
      'phone'::text as matched_field,
      p.partner_type::text as partner_type,
      pp.phone as matched_value
    from partner.partners p
    join partner.person_profiles pp on pp.partner_id = p.partner_id
    where p.tenant_id = p_tenant_id
      and p.status <> 'deleted'
      and v_phone is not null
      and btrim(pp.phone) = v_phone
      and (p_exclude_partner_id is null or p.partner_id <> p_exclude_partner_id)
    union all
    select
      p.partner_id,
      p.display_name,
      'phone'::text,
      p.partner_type::text,
      op.phone
    from partner.partners p
    join partner.organization_profiles op on op.partner_id = p.partner_id
    where p.tenant_id = p_tenant_id
      and p.status <> 'deleted'
      and v_phone is not null
      and btrim(op.phone) = v_phone
      and (p_exclude_partner_id is null or p.partner_id <> p_exclude_partner_id)
    union all
    select
      p.partner_id,
      p.display_name,
      'email'::text,
      p.partner_type::text,
      coalesce(pp.email, op.email)
    from partner.partners p
    left join partner.person_profiles pp on pp.partner_id = p.partner_id
    left join partner.organization_profiles op on op.partner_id = p.partner_id
    where p.tenant_id = p_tenant_id
      and p.status <> 'deleted'
      and v_email is not null
      and lower(btrim(coalesce(pp.email, op.email, ''))) = v_email
      and (p_exclude_partner_id is null or p.partner_id <> p_exclude_partner_id)
    union all
    select
      p.partner_id,
      p.display_name,
      'tax_code'::text,
      p.partner_type::text,
      coalesce(pp.tax_code, op.tax_code)
    from partner.partners p
    left join partner.person_profiles pp on pp.partner_id = p.partner_id
    left join partner.organization_profiles op on op.partner_id = p.partner_id
    where p.tenant_id = p_tenant_id
      and p.status <> 'deleted'
      and v_tax_code is not null
      and btrim(coalesce(pp.tax_code, op.tax_code, '')) = v_tax_code
      and (p_exclude_partner_id is null or p.partner_id <> p_exclude_partner_id)
    union all
    select
      p.partner_id,
      p.display_name,
      'name'::text,
      p.partner_type::text,
      p.display_name
    from partner.partners p
    left join partner.person_profiles pp on pp.partner_id = p.partner_id
    left join partner.organization_profiles op on op.partner_id = p.partner_id
    where p.tenant_id = p_tenant_id
      and p.status <> 'deleted'
      and v_name is not null
      and v_phone is not null
      and lower(p.display_name) = v_name
      and btrim(coalesce(pp.phone, op.phone, '')) = v_phone
      and (p_exclude_partner_id is null or p.partner_id <> p_exclude_partner_id)
  ) m
  order by m.matched_field, m.display_name;
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: check_delete_eligibility (CMD-11 / CheckDeleteEligibilityQuery)
-- ---------------------------------------------------------------------------

create or replace function partner.check_delete_eligibility(
  p_tenant_id uuid,
  p_partner_id uuid
)
returns table (
  eligible boolean,
  reason text
)
language plpgsql
stable
security definer
set search_path = partner, iam, pg_temp
as $$
declare
  v_partner partner.partners%rowtype;
  v_has_transactions boolean;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'partner.delete') then
    raise exception 'permission denied: partner.delete';
  end if;

  select *
  into v_partner
  from partner.partners p
  where p.tenant_id = p_tenant_id
    and p.partner_id = p_partner_id;

  if not found then
    perform partner._raise_partner_error('NOT_FOUND', 'partner not found');
  end if;

  if v_partner.status = 'deleted' then
    return query select false, 'partner already deleted';
    return;
  end if;

  select exists (
    select 1
    from partner.partner_history_views h
    where h.tenant_id = p_tenant_id
      and h.partner_id = p_partner_id
  )
  into v_has_transactions;

  if v_has_transactions then
    return query select false, 'HAS_TRANSACTIONS';
    return;
  end if;

  return query select true, null::text;
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: get_partner_history (CMD-13 / GetPartnerHistoryQuery)
-- ---------------------------------------------------------------------------

create or replace function partner.get_partner_history(
  p_tenant_id uuid,
  p_partner_id uuid,
  p_role text default null,
  p_transaction_type text default null,
  p_date_from timestamptz default null,
  p_date_to timestamptz default null,
  p_page integer default 1,
  p_limit integer default 20
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
  v_offset integer := (v_page - 1) * v_limit;
  v_total bigint;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'partner.history.view') then
    raise exception 'permission denied: partner.history.view';
  end if;

  if not exists (
    select 1
    from partner.partners p
    where p.tenant_id = p_tenant_id
      and p.partner_id = p_partner_id
  ) then
    perform partner._raise_partner_error('NOT_FOUND', 'partner not found');
  end if;

  select count(*)
  into v_total
  from partner.v_partner_history h
  where h.tenant_id = p_tenant_id
    and h.partner_id = p_partner_id
    and (p_role is null or h.role = p_role)
    and (p_transaction_type is null or h.transaction_type = p_transaction_type)
    and (p_date_from is null or h.transaction_date >= p_date_from)
    and (p_date_to is null or h.transaction_date <= p_date_to);

  return query
  select
    coalesce((
      select jsonb_agg(row_to_json(s)::jsonb)
      from (
        select
          h.history_id,
          h.role,
          h.transaction_type,
          h.source_module,
          h.source_id,
          h.reference_code,
          h.transaction_date,
          h.status,
          h.amount,
          h.currency,
          h.can_open_source
        from partner.v_partner_history h
        where h.tenant_id = p_tenant_id
          and h.partner_id = p_partner_id
          and (p_role is null or h.role = p_role)
          and (p_transaction_type is null or h.transaction_type = p_transaction_type)
          and (p_date_from is null or h.transaction_date >= p_date_from)
          and (p_date_to is null or h.transaction_date <= p_date_to)
        order by h.transaction_date desc, h.history_id desc
        offset v_offset
        limit v_limit
      ) s
    ), '[]'::jsonb) as items,
    v_page as page,
    v_limit as "limit",
    v_total as total;
end;
$$;

revoke all on function partner.search_partners(
  uuid, text, text, text, text, integer, integer, text
) from public, anon;
grant execute on function partner.search_partners(
  uuid, text, text, text, text, integer, integer, text
) to authenticated;

revoke all on function partner.get_partner_detail(uuid, uuid) from public, anon;
grant execute on function partner.get_partner_detail(uuid, uuid) to authenticated;

revoke all on function partner.check_duplicate(
  uuid, text, text, text, text, uuid
) from public, anon;
grant execute on function partner.check_duplicate(
  uuid, text, text, text, text, uuid
) to authenticated;

revoke all on function partner.check_delete_eligibility(uuid, uuid) from public, anon;
grant execute on function partner.check_delete_eligibility(uuid, uuid) to authenticated;

revoke all on function partner.get_partner_history(
  uuid, uuid, text, text, timestamptz, timestamptz, integer, integer
) from public, anon;
grant execute on function partner.get_partner_history(
  uuid, uuid, text, text, timestamptz, timestamptz, integer, integer
) to authenticated;
