-- Title: iam member display name lookup
-- Kind: patch
-- Intent: iam_member_display_name
-- Context: TH-04 / KI-08 / Q7
-- Touches: _member_display_name
-- Safety: idempotent ; low
-- Depends on: 20260826004_iam_audit_logs_v2_rebuild

create or replace function iam._member_display_name(p_user_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p_user_id is null then null
    else coalesce(
      nullif(trim(concat_ws(' ', p.family_middle_name, p.given_name)), ''),
      nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), ''),
      nullif(trim(u.email), ''),
      'Không rõ'
    )
  end
  from (select p_user_id as id) input
  left join auth.users u on u.id = input.id
  left join iam.platform_user_profiles p on p.user_id = input.id;
$$;

revoke all on function iam._member_display_name(uuid) from public, anon, authenticated, service_role;

