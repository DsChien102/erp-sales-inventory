-- Title: iam clear stale last_selected_tenant_id after inactive membership
-- Kind: surgical
-- Intent: iam_clear_stale_last_selected_tenant
-- Context: TH-01 membership deactivate — backfill preference rows that still
--   point at a tenant whose membership is no longer active. Complements the
--   MembershipDeactivated inbox handler (sets last_selected to null going forward).
-- Touches:
-- Safety: idempotent; low
-- Depends on: 20260811008_iam_user_preferences.sql

-- Rows already null stay unchanged. Re-running this UPDATE is a no-op once
-- stale pointers are cleared.
update iam.user_preferences p
set
  last_selected_tenant_id = null,
  updated_at = timezone('utc', now())
where p.last_selected_tenant_id is not null
  and exists (
    select 1
    from iam.memberships m
    where m.user_id = p.user_id
      and m.tenant_id = p.last_selected_tenant_id
      and m.status is distinct from 'active'
  );
