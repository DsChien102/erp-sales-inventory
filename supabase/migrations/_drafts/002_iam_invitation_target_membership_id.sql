-- Title: IAM tenant_invitations target_membership_id (hybrid staff)
-- Kind: patch
-- Intent: iam_invitation_target_membership_id
-- Context: TH-01 hybrid staff invite — link precreated membership
-- Touches: iam.tenant_invitations
-- Safety: idempotent ; low
-- Depends on: 20260811017_iam_tenant_invitation_create.sql, 001_iam_ensure_default_store_scope_helpers.sql

alter table iam.tenant_invitations
  add column if not exists target_membership_id uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'iam'
      and t.relname = 'tenant_invitations'
      and c.conname = 'tenant_invitations_target_membership_id_fkey'
  ) then
    alter table iam.tenant_invitations
      add constraint tenant_invitations_target_membership_id_fkey
      foreign key (target_membership_id)
      references iam.memberships (id)
      on delete set null;
  end if;
end;
$$;

create index if not exists tenant_invitations_target_membership_id_idx
  on iam.tenant_invitations (target_membership_id)
  where target_membership_id is not null;
