-- Title: partner get_partner_action_logs read RPC
-- Kind: surgical
-- Intent: partner_action_logs_read
-- Context: TH-03 / Lịch sử thao tác (audit) from partner detail
-- Touches: get_partner_action_logs
-- Safety: idempotent ; low
-- Depends on: 20260714001_partner_v2_schema, 20260714003_partner_v2_read

-- ---------------------------------------------------------------------------
-- RPC: get_partner_action_logs — audit trail for partner mutations
-- ---------------------------------------------------------------------------

create or replace function partner.get_partner_action_logs(
  p_tenant_id uuid,
  p_partner_id uuid,
  p_page integer default 1,
  p_limit integer default 20
)
returns table (
  items jsonb,
  page integer,
  "limit" integer,
  total bigint
)
language plpgsql
stable
security definer
set search_path = partner, iam, pg_temp
as $$
declare
  v_page integer := greatest(coalesce(p_page, 1), 1);
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 100);
  v_offset integer := (v_page - 1) * v_limit;
  v_total bigint;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'partner.detail.view') then
    raise exception 'permission denied: partner.detail.view';
  end if;

  if not exists (
    select 1
    from partner.partners p
    where p.tenant_id = p_tenant_id
      and p.partner_id = p_partner_id
  ) then
    perform partner._raise_partner_error('NOT_FOUND', 'partner not found');
  end if;

  select count(*)
  into v_total
  from partner.partner_action_logs l
  where l.tenant_id = p_tenant_id
    and l.partner_id = p_partner_id;

  return query
  select
    coalesce((
      select jsonb_agg(row_to_json(s)::jsonb)
      from (
        select
          l.action_log_id,
          l.action_type::text as action_type,
          l.actor_user_id,
          l.reason,
          l.created_at
        from partner.partner_action_logs l
        where l.tenant_id = p_tenant_id
          and l.partner_id = p_partner_id
        order by l.created_at desc, l.action_log_id desc
        offset v_offset
        limit v_limit
      ) s
    ), '[]'::jsonb) as items,
    v_page as page,
    v_limit as "limit",
    v_total as total;
end;
$$;

revoke all on function partner.get_partner_action_logs(
  uuid, uuid, integer, integer
) from public, anon;
grant execute on function partner.get_partner_action_logs(
  uuid, uuid, integer, integer
) to authenticated;
