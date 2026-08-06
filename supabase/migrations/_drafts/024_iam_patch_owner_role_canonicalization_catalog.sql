-- Title: iam patch owner-role canonicalization — role catalog + membership backfill
-- Kind: patch
-- Intent: iam_owner_role_canonicalization
-- Context: TH-01 EP-04 — Owner ≠ role; 4 system roles; no role OWNER
-- Touches: iam.role_definitions, iam.list_assignable_invitation_roles
-- Safety: idempotent ; medium
-- Depends on: 20260805024_iam_list_assignable_invitation_roles, 20260805017_iam_tenant_membership_lifecycle

-- 1) Replace the bogus 'manager' role with canonical 'store_owner' (Chủ cửa hàng).
delete from iam.role_definitions where code = 'manager';

insert into iam.role_definitions (id, code, label, status)
values
  ('a0000000-0000-4000-8000-000000000004'::uuid, 'store_owner', 'Chủ cửa hàng', 'active')
on conflict (code) do update
set label = excluded.label,
    status = 'active',
    updated_at = timezone('utc', now());

-- 2) Backfill: memberships that still carry the fictional role 'owner' become
--    role 'store_owner' (their is_owner flag was already set by ...017).
update iam.memberships
set role = 'store_owner',
    updated_at = now()
where role = 'owner';

-- 3) Assignable-roles list no longer needs to hide a fake 'owner' role.
create or replace function iam.list_assignable_invitation_roles(
  p_tenant_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = iam, public
as $$
declare
  v_caller uuid := auth.uid();
begin
  if v_caller is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if not iam.has_permission(p_tenant_id, 'tenant.member.invite') then
    raise exception 'PERMISSION_DENIED';
  end if;

  if not exists (
    select 1
    from iam.memberships m
    where m.tenant_id = p_tenant_id
      and m.user_id = v_caller
      and m.status = 'active'
  ) then
    raise exception 'PERMISSION_DENIED';
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object('role_id', r.id, 'label', r.label)
        order by r.label
      )
      from iam.role_definitions r
      where r.status = 'active'
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function iam.list_assignable_invitation_roles(uuid) from public;
grant execute on function iam.list_assignable_invitation_roles(uuid) to authenticated;
