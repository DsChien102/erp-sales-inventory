-- Vet45 dev seed — IAM baseline role permissions (temporary until SRS).
-- Owner role bypasses permission checks in RPC; only non-owner roles need rows here.
-- Values must match vet45_iam_domain: IamPermissions + InterimPermissionCodes.
-- See modules/iam/docs/interim-domain.md

insert into iam.role_permissions (role, permission)
values
  ('staff', 'settings.einvoice.configure'), -- InterimPermissionCodes.settingsEinvoiceConfigure
  ('staff', 'iam.members.read')       -- IamPermissions.membersRead
on conflict do nothing;
