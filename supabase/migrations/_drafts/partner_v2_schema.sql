-- Partner v2 schema: bounded-context tables, indexes, tenant RLS.
-- Context: TH-03/EP-01+EP-02; docs/themes/TH-03-partner/harness/01-domain-model.md
-- Safety: idempotent ; low lock impact on empty/new schema
-- Contracts: modules/partner/application (PartnerPermissions, DTOs)

create schema if not exists partner;

-- ---------------------------------------------------------------------------
-- Types / enums
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'partner'
      and t.typname = 'partner_type'
  ) then
    create type partner.partner_type as enum ('person', 'organization');
  end if;

  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'partner'
      and t.typname = 'partner_status'
  ) then
    create type partner.partner_status as enum ('active', 'inactive', 'deleted');
  end if;

  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'partner'
      and t.typname = 'partner_role_type'
  ) then
    create type partner.partner_role_type as enum ('customer', 'supplier');
  end if;

  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'partner'
      and t.typname = 'organization_type'
  ) then
    create type partner.organization_type as enum (
      'company',
      'business_household',
      'other'
    );
  end if;

  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'partner'
      and t.typname = 'partner_action_type'
  ) then
    create type partner.partner_action_type as enum (
      'create',
      'update',
      'add_contact',
      'remove_contact',
      'transform',
      'deactivate',
      'reactivate',
      'delete'
    );
  end if;

  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'partner'
      and t.typname = 'partner_transaction_type'
  ) then
    create type partner.partner_transaction_type as enum (
      'sales_order',
      'inventory_inbound',
      'accounting_receivable',
      'accounting_payable'
    );
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists partner.partners (
  partner_id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  partner_type partner.partner_type not null,
  status partner.partner_status not null default 'active',
  display_name text not null,
  version integer not null default 1,
  created_at timestamptz not null default now(),
  created_by uuid not null,
  updated_at timestamptz not null default now(),
  updated_by uuid not null,
  constraint chk_partners_display_name_not_blank
    check (length(btrim(display_name)) > 0),
  constraint chk_partners_version_positive
    check (version > 0)
);

create table if not exists partner.person_profiles (
  partner_id uuid primary key references partner.partners (partner_id) on delete cascade,
  tenant_id uuid not null,
  title text null,
  full_name text not null,
  nickname text null,
  phone text not null,
  phone_normalized text not null,
  phone2 text null,
  phone2_normalized text null,
  email text null,
  email_normalized text null,
  tax_code text null,
  tax_code_normalized text null,
  invoice_name text null,
  invoice_address text null,
  invoice_email text null,
  delivery_province text null,
  delivery_commune text null,
  delivery_address text null,
  note text null,
  constraint chk_person_profiles_full_name_not_blank
    check (length(btrim(full_name)) > 0),
  constraint chk_person_profiles_phone_not_blank
    check (length(btrim(phone)) > 0)
);

create table if not exists partner.organization_profiles (
  partner_id uuid primary key references partner.partners (partner_id) on delete cascade,
  tenant_id uuid not null,
  organization_type partner.organization_type not null,
  organization_name text not null,
  short_name text null,
  intl_name text null,
  phone text not null,
  phone_normalized text not null,
  email text null,
  email_normalized text null,
  tax_code text null,
  tax_code_normalized text null,
  company_address text null,
  invoice_name text null,
  invoice_address text null,
  invoice_email text null,
  delivery_province text null,
  delivery_commune text null,
  note text null,
  constraint chk_organization_profiles_name_not_blank
    check (length(btrim(organization_name)) > 0),
  constraint chk_organization_profiles_phone_not_blank
    check (length(btrim(phone)) > 0)
);

create table if not exists partner.partner_roles (
  partner_id uuid not null references partner.partners (partner_id) on delete cascade,
  tenant_id uuid not null,
  role partner.partner_role_type not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (partner_id, role)
);

create table if not exists partner.organization_contacts (
  organization_partner_id uuid not null references partner.partners (partner_id) on delete cascade,
  person_partner_id uuid not null references partner.partners (partner_id) on delete restrict,
  tenant_id uuid not null,
  contact_role text null,
  is_primary boolean not null default false,
  note text null,
  created_at timestamptz not null default now(),
  created_by uuid not null,
  updated_at timestamptz not null default now(),
  updated_by uuid not null,
  primary key (organization_partner_id, person_partner_id),
  constraint chk_organization_contacts_distinct_partners
    check (organization_partner_id <> person_partner_id)
);

create table if not exists partner.partner_action_logs (
  action_log_id uuid primary key default gen_random_uuid(),
  partner_id uuid not null references partner.partners (partner_id) on delete cascade,
  tenant_id uuid not null,
  action_type partner.partner_action_type not null,
  actor_user_id uuid not null,
  reason text null,
  before_state jsonb not null default '{}'::jsonb,
  after_state jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists partner.partner_history_views (
  history_id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  partner_id uuid not null references partner.partners (partner_id) on delete cascade,
  role partner.partner_role_type not null,
  transaction_type partner.partner_transaction_type not null,
  source_module text not null,
  source_id uuid not null,
  reference_code text not null,
  transaction_date timestamptz not null,
  status text not null,
  amount numeric(18, 2) null,
  currency text null,
  can_open_source boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chk_partner_history_views_source_module_not_blank
    check (length(btrim(source_module)) > 0),
  constraint chk_partner_history_views_reference_code_not_blank
    check (length(btrim(reference_code)) > 0)
);

create unique index if not exists uq_partner_history_views_source
  on partner.partner_history_views (tenant_id, source_module, source_id);

-- ---------------------------------------------------------------------------
-- Indexes (tenant_id, phone, status per harness)
-- ---------------------------------------------------------------------------

create index if not exists idx_partners_tenant_id
  on partner.partners (tenant_id);

create index if not exists idx_partners_tenant_status
  on partner.partners (tenant_id, status);

create index if not exists idx_partners_tenant_updated_at
  on partner.partners (tenant_id, updated_at desc);

create index if not exists idx_partners_tenant_display_name
  on partner.partners (tenant_id, display_name);

create index if not exists idx_person_profiles_tenant_phone
  on partner.person_profiles (tenant_id, phone_normalized);

create index if not exists idx_person_profiles_tenant_email
  on partner.person_profiles (tenant_id, email_normalized)
  where email_normalized is not null;

create index if not exists idx_person_profiles_tenant_tax_code
  on partner.person_profiles (tenant_id, tax_code_normalized)
  where tax_code_normalized is not null;

create index if not exists idx_organization_profiles_tenant_phone
  on partner.organization_profiles (tenant_id, phone_normalized);

create index if not exists idx_organization_profiles_tenant_email
  on partner.organization_profiles (tenant_id, email_normalized)
  where email_normalized is not null;

create index if not exists idx_organization_profiles_tenant_tax_code
  on partner.organization_profiles (tenant_id, tax_code_normalized)
  where tax_code_normalized is not null;

create index if not exists idx_partner_roles_tenant_partner
  on partner.partner_roles (tenant_id, partner_id);

create index if not exists idx_organization_contacts_org
  on partner.organization_contacts (tenant_id, organization_partner_id);

create index if not exists idx_organization_contacts_person
  on partner.organization_contacts (tenant_id, person_partner_id);

create index if not exists idx_partner_action_logs_partner
  on partner.partner_action_logs (tenant_id, partner_id, created_at desc);

create index if not exists idx_partner_history_views_partner
  on partner.partner_history_views (tenant_id, partner_id, transaction_date desc);

-- ---------------------------------------------------------------------------
-- Shared helpers
-- ---------------------------------------------------------------------------

create or replace function partner._tenant_member(p_tenant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = partner, iam, pg_temp
as $$
  select exists (
    select 1
    from iam.memberships m
    where m.tenant_id = p_tenant_id
      and m.user_id = auth.uid()
  );
$$;

create or replace function partner._normalize_phone(p_phone text)
returns text
language sql
immutable
as $$
  select nullif(regexp_replace(lower(btrim(coalesce(p_phone, ''))), '[^0-9+]', '', 'g'), '');
$$;

create or replace function partner._normalize_email(p_email text)
returns text
language sql
immutable
as $$
  select nullif(lower(btrim(coalesce(p_email, ''))), '');
$$;

create or replace function partner._normalize_tax_code(p_tax_code text)
returns text
language sql
immutable
as $$
  select nullif(lower(btrim(coalesce(p_tax_code, ''))), '');
$$;

create or replace function partner._profile_phone(p_partner_id uuid)
returns text
language sql
stable
security definer
set search_path = partner, pg_temp
as $$
  select coalesce(pp.phone, op.phone)
  from partner.partners p
  left join partner.person_profiles pp on pp.partner_id = p.partner_id
  left join partner.organization_profiles op on op.partner_id = p.partner_id
  where p.partner_id = p_partner_id;
$$;

create or replace function partner._raise_partner_error(
  p_code text,
  p_message text default ''
)
returns void
language plpgsql
as $$
begin
  raise exception '%: %', p_code, coalesce(nullif(btrim(p_message), ''), p_code)
    using errcode = 'P0001';
end;
$$;

revoke all on function partner._tenant_member(uuid) from public, anon;
grant execute on function partner._tenant_member(uuid) to authenticated;

revoke all on function partner._normalize_phone(text) from public, anon;
grant execute on function partner._normalize_phone(text) to authenticated;

revoke all on function partner._normalize_email(text) from public, anon;
grant execute on function partner._normalize_email(text) to authenticated;

revoke all on function partner._normalize_tax_code(text) from public, anon;
grant execute on function partner._normalize_tax_code(text) to authenticated;

revoke all on function partner._profile_phone(uuid) from public, anon;
grant execute on function partner._profile_phone(uuid) to authenticated;

revoke all on function partner._raise_partner_error(text, text) from public, anon;
grant execute on function partner._raise_partner_error(text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- RLS — tenant membership isolation (mirrors iam.memberships pattern)
-- ---------------------------------------------------------------------------

alter table partner.partners enable row level security;
alter table partner.person_profiles enable row level security;
alter table partner.organization_profiles enable row level security;
alter table partner.partner_roles enable row level security;
alter table partner.organization_contacts enable row level security;
alter table partner.partner_action_logs enable row level security;
alter table partner.partner_history_views enable row level security;

drop policy if exists p_partners_tenant_read on partner.partners;
create policy p_partners_tenant_read on partner.partners
  for select
  to authenticated
  using (partner._tenant_member(tenant_id));

drop policy if exists p_person_profiles_tenant_read on partner.person_profiles;
create policy p_person_profiles_tenant_read on partner.person_profiles
  for select
  to authenticated
  using (partner._tenant_member(tenant_id));

drop policy if exists p_organization_profiles_tenant_read on partner.organization_profiles;
create policy p_organization_profiles_tenant_read on partner.organization_profiles
  for select
  to authenticated
  using (partner._tenant_member(tenant_id));

drop policy if exists p_partner_roles_tenant_read on partner.partner_roles;
create policy p_partner_roles_tenant_read on partner.partner_roles
  for select
  to authenticated
  using (partner._tenant_member(tenant_id));

drop policy if exists p_organization_contacts_tenant_read on partner.organization_contacts;
create policy p_organization_contacts_tenant_read on partner.organization_contacts
  for select
  to authenticated
  using (partner._tenant_member(tenant_id));

drop policy if exists p_partner_action_logs_tenant_read on partner.partner_action_logs;
create policy p_partner_action_logs_tenant_read on partner.partner_action_logs
  for select
  to authenticated
  using (partner._tenant_member(tenant_id));

drop policy if exists p_partner_history_views_tenant_read on partner.partner_history_views;
create policy p_partner_history_views_tenant_read on partner.partner_history_views
  for select
  to authenticated
  using (partner._tenant_member(tenant_id));

-- Mutations are security-definer RPC only; no direct table write policies.

revoke all on table partner.partners from public, anon;
revoke all on table partner.person_profiles from public, anon;
revoke all on table partner.organization_profiles from public, anon;
revoke all on table partner.partner_roles from public, anon;
revoke all on table partner.organization_contacts from public, anon;
revoke all on table partner.partner_action_logs from public, anon;
revoke all on table partner.partner_history_views from public, anon;

grant select on table partner.partners to authenticated;
grant select on table partner.person_profiles to authenticated;
grant select on table partner.organization_profiles to authenticated;
grant select on table partner.partner_roles to authenticated;
grant select on table partner.organization_contacts to authenticated;
grant select on table partner.partner_action_logs to authenticated;
grant select on table partner.partner_history_views to authenticated;

-- Notes:
-- - Depends on iam.memberships + iam.has_permission (iam_foundation migration).
-- - partner.outbox_messages installed via platform.install_module_messaging('partner')
--   or partner_v2_outbox.sql fallback helper.
