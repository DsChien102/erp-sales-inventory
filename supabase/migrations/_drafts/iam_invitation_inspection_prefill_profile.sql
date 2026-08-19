-- Title: IAM invitation inspection pre-fills activation profile
-- Kind: patch
-- Intent: iam_invitation_inspection_prefill_profile
-- Touches: iam.inspect_invitation_token

create or replace function iam.inspect_invitation_token(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_inv iam.tenant_invitations;
  v_owner_activation record;
  v_role iam.role_definitions;
  v_tenant iam.tenants;
  v_account_exists boolean := false;
  v_should_be_owner boolean := false;
  v_hash text;
  v_legacy_hash text;
  v_now timestamptz := timezone('utc', now());
begin
  begin
    v_inv := iam._load_invitation_by_token(p_token);
  exception
    when others then
      if sqlerrm like 'INVITATION_TOKEN_INVALID%' then
        v_hash := iam._invitation_token_hash(p_token);
        v_legacy_hash := encode(
          extensions.digest(upper(trim(coalesce(p_token, ''))), 'sha256'),
          'hex'
        );

        select * into v_owner_activation
        from iam.owner_activations oa
        where oa.code_hash in (v_hash, v_legacy_hash)
        limit 1;

        if not found then
          raise exception 'INVITATION_TOKEN_INVALID';
        end if;

        if v_owner_activation.status = 'accepted' then
          raise exception 'INVITATION_ALREADY_USED';
        end if;
        if v_owner_activation.status = 'expired'
            or v_owner_activation.expires_at <= v_now then
          raise exception 'INVITATION_EXPIRED';
        end if;
        if v_owner_activation.status <> 'pending' then
          raise exception 'INVITATION_TOKEN_INVALID';
        end if;

        select * into v_tenant
        from iam.tenants t
        where t.id = v_owner_activation.tenant_id;

        select exists (
          select 1
          from auth.users u
          left join iam.platform_user_profiles p on p.user_id = u.id
          where lower(trim(u.email::text)) = v_owner_activation.invitee_email
            and coalesce(p.status, 'active') <> 'pending_activation'
        ) into v_account_exists;

        return jsonb_build_object(
          'tenant_id', v_owner_activation.tenant_id,
          'tenant_name', coalesce(v_tenant.name, ''),
          'invitee_email', v_owner_activation.invitee_email,
          'initial_role_id', 'owner',
          'initial_role_label', 'Chủ sở hữu',
          'expires_at', v_owner_activation.expires_at,
          'account_exists', v_account_exists,
          'given_name', v_owner_activation.given_name,
          'family_name', v_owner_activation.family_name,
          'phone', v_owner_activation.phone
        );
      end if;
      raise;
  end;

  -- Terminal / expiry checks — still no accountExists on invalid path above.
  if v_inv.status = 'revoked' then
    raise exception 'INVITATION_REVOKED';
  end if;
  if v_inv.status in ('accepted', 'declined') then
    raise exception 'INVITATION_ALREADY_USED';
  end if;
  if v_inv.status = 'expired' or v_inv.expires_at <= v_now then
    raise exception 'INVITATION_EXPIRED';
  end if;
  if v_inv.status <> 'pending' then
    raise exception 'INVITATION_TOKEN_INVALID';
  end if;

  select * into v_tenant from iam.tenants t where t.id = v_inv.tenant_id;
  select * into v_role from iam.role_definitions r where r.id = v_inv.initial_role_id;

  v_should_be_owner := not exists (
    select 1
    from iam.memberships m
    where m.tenant_id = v_inv.tenant_id
      and m.status = 'active'
      and (m.is_owner is true or m.role = 'owner')
  );

  select exists (
    select 1 from auth.users u
    where lower(trim(u.email::text)) = v_inv.invitee_email
  ) into v_account_exists;

  return jsonb_build_object(
    'tenant_id', v_inv.tenant_id,
    'tenant_name', coalesce(v_tenant.name, ''),
    'invitee_email', v_inv.invitee_email,
    'initial_role_id', case when v_should_be_owner then 'owner' else v_inv.initial_role_id::text end,
    'initial_role_label', case when v_should_be_owner then 'Chủ sở hữu' else coalesce(v_role.label, '') end,
    'expires_at', v_inv.expires_at,
    'account_exists', v_account_exists,
    'given_name', null,
    'family_name', null,
    'phone', null
  );
end;
$$;

grant usage on schema iam to anon;
revoke all on function iam.inspect_invitation_token(text) from public;
grant execute on function iam.inspect_invitation_token(text) to anon, authenticated;
