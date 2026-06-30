-- Vet45 dev seed — IAM baseline role permissions (temporary until SRS).
-- Owner role bypasses permission checks in RPC; only non-owner roles need rows here.

insert into iam.role_permissions (role, permission)
values
  ('staff', 'partner.read'),
  ('staff', 'partner.write'),
  ('staff', 'settings.einvoice.configure')
on conflict do nothing;
