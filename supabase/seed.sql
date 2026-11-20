-- Mosaic Retail dev seed — IAM baseline role permissions (temporary until SRS).
-- Owner role bypasses permission checks in RPC; only non-owner roles need rows here.
-- Values must match apps/erp/lib/core/iam/iam_codes.dart (permission codes).

insert into iam.role_permissions (role, permission)
values
  ('staff', 'settings.einvoice.configure'), -- InterimPermissionCodes.settingsEinvoiceConfigure
  ('staff', 'iam.members.read')       -- IamPermissions.membersRead
on conflict do nothing;
