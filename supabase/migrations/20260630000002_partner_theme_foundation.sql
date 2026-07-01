-- Partner theme foundation: TH-03 partner profile schema and minimal contracts.
-- Context: TH-03/Epic-01 foundation; docs/themes/TH-03-partner/harness/*
-- Safety: idempotent ; low lock impact on empty/new schema

create extension if not exists pg_trgm;

create schema if not exists partner;

do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'partner'
      and t.typname = 'entity_type'
  ) then
    create type partner.entity_type as enum (
      'individual',
      'household_business',
      'company'
    );
  end if;

  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'partner'
      and t.typname = 'partner_status'
  ) then
    create type partner.partner_status as enum ('active', 'inactive');
  end if;

  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'partner'
      and t.typname = 'partner_role'
  ) then
    create type partner.partner_role as enum ('customer', 'supplier');
  end if;

  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'partner'
      and t.typname = 'partner_transaction_role'
  ) then
    create type partner.partner_transaction_role as enum ('customer', 'supplier');
  end if;
end $$;

create table if not exists partner.business_partners (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  partner_code text null,
  idempotency_key uuid null,
  entity_type partner.entity_type not null,
  display_name text not null,
  individual_name text null,
  business_name text null,
  company_name text null,
  phone text not null,
  phone_normalized text not null,
  email text null,
  email_normalized text null,
  address text null,
  tax_code text null,
  tax_code_normalized text null,
  invoice_name text null,
  invoice_address text null,
  invoice_email text null,
  bank_name text null,
  bank_account_number text null,
  bank_account_holder text null,
  status partner.partner_status not null default 'active',
  status_changed_at timestamptz null,
  status_changed_by uuid null,
  status_note text null,
  note text null,
  created_at timestamptz not null default now(),
  created_by uuid not null,
  updated_at timestamptz not null default now(),
  updated_by uuid not null,
  version integer not null default 1,
  constraint chk_business_partners_display_name_not_blank
    check (length(btrim(display_name)) > 0),
  constraint chk_business_partners_phone_not_blank
    check (length(btrim(phone)) > 0),
  constraint chk_business_partners_phone_normalized_not_blank
    check (length(btrim(phone_normalized)) > 0),
  constraint chk_business_partners_email_normalization
    check (email is null or email_normalized is not null),
  constraint chk_business_partners_tax_normalization
    check (tax_code is null or tax_code_normalized is not null),
  constraint chk_business_partners_individual_name
    check (entity_type <> 'individual' or length(btrim(coalesce(individual_name, ''))) > 0),
  constraint chk_business_partners_business_name
    check (entity_type <> 'household_business' or length(btrim(coalesce(business_name, ''))) > 0),
  constraint chk_business_partners_company_name
    check (entity_type <> 'company' or length(btrim(coalesce(company_name, ''))) > 0)
);

comment on table partner.business_partners is
'Canonical partner profile table for TH-03. One row per business partner per tenant.';

create table if not exists partner.business_partner_roles (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  business_partner_id uuid not null references partner.business_partners(id) on delete cascade,
  role partner.partner_role not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint uq_business_partner_roles_partner_role
    unique (business_partner_id, role)
);

comment on table partner.business_partner_roles is
'Partner roles. A business partner may be a customer, supplier, or both.';

create table if not exists partner.partner_transaction_histories (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  business_partner_id uuid not null references partner.business_partners(id) on delete cascade,
  transaction_role partner.partner_transaction_role not null,
  source_module text not null,
  source_type text not null,
  source_id uuid not null,
  source_code text null,
  transaction_date timestamptz not null,
  amount numeric(18,2) null,
  status text null,
  description text null,
  created_at timestamptz not null default now(),
  constraint uq_partner_transaction_histories_source
    unique (tenant_id, source_module, source_type, source_id, business_partner_id, transaction_role)
);

comment on table partner.partner_transaction_histories is
'Read-model/projection for Epic-03 transaction history lookup by partner.';

create table if not exists partner.partner_audit_logs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  business_partner_id uuid null references partner.business_partners(id) on delete set null,
  action text not null,
  field_name text null,
  old_value jsonb null,
  new_value jsonb null,
  actor_id uuid not null,
  created_at timestamptz not null default now(),
  constraint chk_partner_audit_logs_action_not_blank
    check (length(btrim(action)) > 0)
);

comment on table partner.partner_audit_logs is
'Audit log for partner profile, role, status, delete, and delete-rejected actions.';

create index if not exists idx_business_partners_tenant_status_updated
  on partner.business_partners (tenant_id, status, updated_at desc);
create unique index if not exists uq_business_partners_tenant_idempotency_key
  on partner.business_partners (tenant_id, idempotency_key)
  where idempotency_key is not null;
create index if not exists idx_business_partners_tenant_entity_type
  on partner.business_partners (tenant_id, entity_type);
create index if not exists idx_business_partners_phone_normalized
  on partner.business_partners (tenant_id, phone_normalized);
create index if not exists idx_business_partners_email_normalized
  on partner.business_partners (tenant_id, email_normalized)
  where email_normalized is not null;
create index if not exists idx_business_partners_tax_code_normalized
  on partner.business_partners (tenant_id, tax_code_normalized)
  where tax_code_normalized is not null;
create index if not exists idx_business_partners_display_name_trgm
  on partner.business_partners using gin (display_name gin_trgm_ops);

create index if not exists idx_business_partner_roles_tenant_role
  on partner.business_partner_roles (tenant_id, role, is_active);
create index if not exists idx_business_partner_roles_partner
  on partner.business_partner_roles (business_partner_id);

create index if not exists idx_partner_transaction_histories_partner_time
  on partner.partner_transaction_histories (tenant_id, business_partner_id, transaction_date desc);
create index if not exists idx_partner_transaction_histories_partner_role_time
  on partner.partner_transaction_histories (
    tenant_id,
    business_partner_id,
    transaction_role,
    transaction_date desc
  );
create index if not exists idx_partner_transaction_histories_source_code_trgm
  on partner.partner_transaction_histories using gin (source_code gin_trgm_ops)
  where source_code is not null;

create index if not exists idx_partner_audit_logs_partner_time
  on partner.partner_audit_logs (tenant_id, business_partner_id, created_at desc);

create or replace function partner.tg_set_business_partner_updated_meta()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  new.version := old.version + 1;
  return new;
end;
$$;

drop trigger if exists trg_business_partners_set_updated_meta on partner.business_partners;
create trigger trg_business_partners_set_updated_meta
before update on partner.business_partners
for each row
execute function partner.tg_set_business_partner_updated_meta();

alter table partner.business_partners enable row level security;
alter table partner.business_partner_roles enable row level security;
alter table partner.partner_transaction_histories enable row level security;
alter table partner.partner_audit_logs enable row level security;

drop policy if exists p_business_partners_tenant_membership on partner.business_partners;
create policy p_business_partners_tenant_membership
on partner.business_partners
using (
  exists (
    select 1
    from iam.memberships m
    where m.tenant_id = business_partners.tenant_id
      and m.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from iam.memberships m
    where m.tenant_id = business_partners.tenant_id
      and m.user_id = auth.uid()
  )
);

drop policy if exists p_business_partner_roles_tenant_membership on partner.business_partner_roles;
create policy p_business_partner_roles_tenant_membership
on partner.business_partner_roles
using (
  exists (
    select 1
    from iam.memberships m
    where m.tenant_id = business_partner_roles.tenant_id
      and m.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from iam.memberships m
    where m.tenant_id = business_partner_roles.tenant_id
      and m.user_id = auth.uid()
  )
);

drop policy if exists p_partner_transaction_histories_tenant_membership on partner.partner_transaction_histories;
create policy p_partner_transaction_histories_tenant_membership
on partner.partner_transaction_histories
using (
  exists (
    select 1
    from iam.memberships m
    where m.tenant_id = partner_transaction_histories.tenant_id
      and m.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from iam.memberships m
    where m.tenant_id = partner_transaction_histories.tenant_id
      and m.user_id = auth.uid()
  )
);

drop policy if exists p_partner_audit_logs_tenant_membership on partner.partner_audit_logs;
create policy p_partner_audit_logs_tenant_membership
on partner.partner_audit_logs
using (
  exists (
    select 1
    from iam.memberships m
    where m.tenant_id = partner_audit_logs.tenant_id
      and m.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from iam.memberships m
    where m.tenant_id = partner_audit_logs.tenant_id
      and m.user_id = auth.uid()
  )
);

create or replace function partner.check_duplicate(
  p_tenant_id uuid,
  p_phone_normalized text default null,
  p_email_normalized text default null,
  p_tax_code_normalized text default null
)
returns table (
  duplicate_field text,
  business_partner_id uuid,
  display_name text,
  matched_value text
)
language plpgsql
security definer
set search_path = partner, iam, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'partner.create') then
    raise exception 'permission denied: partner.create';
  end if;

  return query
  select 'phone'::text, bp.id, bp.display_name, bp.phone
  from partner.business_partners bp
  where bp.tenant_id = p_tenant_id
    and p_phone_normalized is not null
    and bp.phone_normalized = p_phone_normalized
  union all
  select 'email'::text, bp.id, bp.display_name, bp.email
  from partner.business_partners bp
  where bp.tenant_id = p_tenant_id
    and p_email_normalized is not null
    and bp.email_normalized = p_email_normalized
  union all
  select 'tax_code'::text, bp.id, bp.display_name, bp.tax_code
  from partner.business_partners bp
  where bp.tenant_id = p_tenant_id
    and p_tax_code_normalized is not null
    and bp.tax_code_normalized = p_tax_code_normalized
  order by duplicate_field, display_name;
end;
$$;

create or replace function partner.register_partner(
  p_tenant_id uuid,
  p_entity_type partner.entity_type,
  p_display_name text,
  p_phone text,
  p_phone_normalized text,
  p_roles partner.partner_role[],
  p_actor_id uuid default auth.uid(),
  p_partner_code text default null,
  p_individual_name text default null,
  p_business_name text default null,
  p_company_name text default null,
  p_email text default null,
  p_email_normalized text default null,
  p_address text default null,
  p_tax_code text default null,
  p_tax_code_normalized text default null,
  p_invoice_name text default null,
  p_invoice_address text default null,
  p_invoice_email text default null,
  p_bank_name text default null,
  p_bank_account_number text default null,
  p_bank_account_holder text default null,
  p_note text default null,
  p_confirm_duplicate boolean default false,
  p_idempotency_key uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = partner, iam, pg_temp
as $$
declare
  v_partner_id uuid;
  v_role partner.partner_role;
  v_duplicate_count integer;
  v_outbox_payload jsonb;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if p_actor_id is null or p_actor_id <> auth.uid() then
    raise exception 'actor mismatch';
  end if;

  if not iam.has_permission(p_tenant_id, 'partner.create') then
    raise exception 'permission denied: partner.create';
  end if;

  if p_roles is null or cardinality(p_roles) = 0 then
    raise exception 'at least one partner role is required';
  end if;

  if length(btrim(coalesce(p_display_name, ''))) = 0 then
    raise exception 'display_name is required';
  end if;

  if length(btrim(coalesce(p_phone, ''))) = 0
    or length(btrim(coalesce(p_phone_normalized, ''))) = 0 then
    raise exception 'phone is required';
  end if;

  if p_idempotency_key is not null then
    select bp.id
    into v_partner_id
    from partner.business_partners bp
    where bp.tenant_id = p_tenant_id
      and bp.idempotency_key = p_idempotency_key;

    if v_partner_id is not null then
      return v_partner_id;
    end if;
  end if;

  select count(*)
  into v_duplicate_count
  from partner.business_partners bp
  where bp.tenant_id = p_tenant_id
    and (
      bp.phone_normalized = p_phone_normalized
      or (
        p_email_normalized is not null
        and bp.email_normalized = p_email_normalized
      )
      or (
        p_tax_code_normalized is not null
        and bp.tax_code_normalized = p_tax_code_normalized
      )
    );

  if v_duplicate_count > 0 and not p_confirm_duplicate then
    raise exception 'duplicate confirmation required';
  end if;

  insert into partner.business_partners (
    tenant_id,
    partner_code,
    idempotency_key,
    entity_type,
    display_name,
    individual_name,
    business_name,
    company_name,
    phone,
    phone_normalized,
    email,
    email_normalized,
    address,
    tax_code,
    tax_code_normalized,
    invoice_name,
    invoice_address,
    invoice_email,
    bank_name,
    bank_account_number,
    bank_account_holder,
    note,
    created_by,
    updated_by
  )
  values (
    p_tenant_id,
    nullif(btrim(coalesce(p_partner_code, '')), ''),
    p_idempotency_key,
    p_entity_type,
    btrim(p_display_name),
    nullif(btrim(coalesce(p_individual_name, '')), ''),
    nullif(btrim(coalesce(p_business_name, '')), ''),
    nullif(btrim(coalesce(p_company_name, '')), ''),
    btrim(p_phone),
    btrim(p_phone_normalized),
    nullif(btrim(coalesce(p_email, '')), ''),
    nullif(btrim(coalesce(p_email_normalized, '')), ''),
    nullif(btrim(coalesce(p_address, '')), ''),
    nullif(btrim(coalesce(p_tax_code, '')), ''),
    nullif(btrim(coalesce(p_tax_code_normalized, '')), ''),
    nullif(btrim(coalesce(p_invoice_name, '')), ''),
    nullif(btrim(coalesce(p_invoice_address, '')), ''),
    nullif(btrim(coalesce(p_invoice_email, '')), ''),
    nullif(btrim(coalesce(p_bank_name, '')), ''),
    nullif(btrim(coalesce(p_bank_account_number, '')), ''),
    nullif(btrim(coalesce(p_bank_account_holder, '')), ''),
    nullif(btrim(coalesce(p_note, '')), ''),
    p_actor_id,
    p_actor_id
  )
  returning id into v_partner_id;

  foreach v_role in array p_roles loop
    insert into partner.business_partner_roles (
      tenant_id,
      business_partner_id,
      role
    )
    values (
      p_tenant_id,
      v_partner_id,
      v_role
    )
    on conflict (business_partner_id, role) do nothing;
  end loop;

  insert into partner.partner_audit_logs (
    tenant_id,
    business_partner_id,
    action,
    field_name,
    new_value,
    actor_id
  )
  values (
    p_tenant_id,
    v_partner_id,
    'partner_registered',
    null,
    jsonb_build_object(
      'business_partner_id', v_partner_id,
      'entity_type', p_entity_type,
      'roles', p_roles,
      'display_name', btrim(p_display_name)
    ),
    p_actor_id
  );

  v_outbox_payload := jsonb_build_object(
    'business_partner_id', v_partner_id,
    'tenant_id', p_tenant_id,
    'entity_type', p_entity_type,
    'roles', p_roles,
    'display_name', btrim(p_display_name)
  );

  perform partner.enqueue_outbox_message(
    p_tenant_id,
    'partner.partner.registered',
    v_outbox_payload
  );

  return v_partner_id;
end;
$$;

revoke all on schema partner from public, anon;
grant usage on schema partner to authenticated, service_role;

revoke all on all tables in schema partner from public, anon, authenticated;
grant select, insert, update, delete on all tables in schema partner to service_role;

revoke all on function partner.check_duplicate(uuid, text, text, text) from public, anon;
revoke all on function partner.register_partner(
  uuid,
  partner.entity_type,
  text,
  text,
  text,
  partner.partner_role[],
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  boolean,
  uuid
) from public, anon;

grant execute on function partner.check_duplicate(uuid, text, text, text) to authenticated;
grant execute on function partner.register_partner(
  uuid,
  partner.entity_type,
  text,
  text,
  text,
  partner.partner_role[],
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  boolean,
  uuid
) to authenticated;
