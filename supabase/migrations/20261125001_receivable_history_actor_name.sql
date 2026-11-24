-- Title: receivable history actor display name
-- Kind: patch
-- Intent: receivable_history_actor_name
-- Context: TH-06 6.2 (T6-2b Task 1)
-- Touches: list_customer_receivable_history
-- Safety: idempotent ; low
-- Depends on: 20261124002_receivable_return_offsets

-- Them khoa actorDisplayName (= iam._member_display_name(actor_id)) vao moi dong lich su.
-- Chu ky, quyen, cursor khong doi.
create or replace function receivable.list_customer_receivable_history(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_customer_partner_id uuid,
  p_cursor text default null,
  p_page_size int default 20
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_size int := least(greatest(coalesce(p_page_size, 20), 1), 100);
  v_cursor jsonb;
  v_rows jsonb;
  v_items jsonb;
  v_next text;
begin
  perform receivable._assert_actor(p_tenant_id, p_actor_id, array['receivable.view']);

  if not exists (
    select 1 from partner.partners p
    where p.tenant_id = p_tenant_id and p.partner_id = p_customer_partner_id
  ) then
    perform receivable._raise_error('NOT_FOUND', 'Customer was not found.');
  end if;

  if nullif(p_cursor, '') is not null then
    begin
      v_cursor := convert_from(decode(p_cursor, 'base64'), 'utf8')::jsonb;
    exception when others then
      perform receivable._raise_error('CONTEXT_INVALID', 'Cursor is invalid.');
    end;
  end if;

  select coalesce(jsonb_agg(page.item order by page.ord), '[]'::jsonb)
  into v_rows
  from (
    select row_number() over (order by h.occurred_at desc, h.row_id desc) as ord,
           jsonb_build_object(
             'kind', h.kind,
             'occurredAt', h.occurred_at,
             'amountMinor', h.amount_minor,
             'paymentMethodCode', h.payment_method_code,
             'externalReference', h.external_reference,
             'actorId', h.actor_id,
             'actorDisplayName', iam._member_display_name(h.actor_id),
             'salesOrderId', h.sales_order_id,
             'orderCode', h.order_code,
             'allocations', h.allocations,
             'sourceOrderCode', h.source_order_code,
             'targetOrderCode', h.target_order_code,
             'returnExchangeReference', h.return_exchange_reference,
             '_k', jsonb_build_array(h.occurred_at::text, h.row_id)
           ) as item
    from (
      select cc.occurred_at, cc.id as row_id, 'customer_collection'::text as kind,
             cc.amount_minor, cc.payment_method_code::text as payment_method_code,
             cc.external_reference::text as external_reference,
             cc.collected_by_user_id as actor_id,
             null::uuid as sales_order_id, null::text as order_code,
             cc.allocation_snapshot as allocations,
             null::text as source_order_code, null::text as target_order_code,
             null::text as return_exchange_reference
      from receivable.customer_collections cc
      where cc.tenant_id = p_tenant_id and cc.customer_partner_id = p_customer_partner_id

      union all

      select t.occurred_at, t.id,
             case when t.transaction_type = 'collection' then 'order_collection' else 'refund' end,
             t.amount_minor, t.payment_method_code::text, t.external_reference::text,
             t.initiated_by_user_id, so.id, so.order_code::text, null::jsonb,
             null::text, null::text, null::text
      from receivable.sales_payment_transactions t
      join receivable.sales_order_settlements s
        on s.tenant_id = t.tenant_id and s.id = t.sales_order_settlement_id
      join sales.sales_orders so
        on so.tenant_id = s.tenant_id and so.id = s.sales_order_id
      where t.tenant_id = p_tenant_id
        and so.customer_partner_id = p_customer_partner_id
        and t.status = 'confirmed'
        and t.payment_method_code <> 'offset'
        and ((t.transaction_type = 'collection'
              and t.source_context in ('checkout', 'additional_collection'))
          or (t.transaction_type = 'refund' and t.source_context = 'return_exchange'))
        and iam.can_access_store(p_tenant_id, so.store_id, p_actor_id)

      union all

      select o.occurred_at, o.id, 'offset', o.amount_minor, 'offset'::text, null::text,
             o.created_by_user_id, null::uuid, null::text, null::jsonb,
             src.order_code::text, tgt.order_code::text, rx.reference_number::text
      from receivable.receivable_offsets o
      join sales.sales_orders src
        on src.tenant_id = o.tenant_id and src.id = o.source_sales_order_id
      join sales.sales_orders tgt
        on tgt.tenant_id = o.tenant_id and tgt.id = o.target_sales_order_id
      left join sales.return_exchange_orders rx
        on rx.tenant_id = o.tenant_id and rx.id = o.return_exchange_order_id
      where o.tenant_id = p_tenant_id
        and o.customer_partner_id = p_customer_partner_id
        and iam.can_access_store(p_tenant_id, src.store_id, p_actor_id)
        and iam.can_access_store(p_tenant_id, tgt.store_id, p_actor_id)
    ) h
    where v_cursor is null
       or h.occurred_at < (v_cursor ->> 0)::timestamptz
       or (h.occurred_at = (v_cursor ->> 0)::timestamptz
           and h.row_id < (v_cursor ->> 1)::uuid)
    order by h.occurred_at desc, h.row_id desc
    limit v_size + 1
  ) page;

  if jsonb_array_length(v_rows) > v_size then
    v_next := replace(
      encode(convert_to((v_rows -> (v_size - 1) -> '_k')::text, 'utf8'), 'base64'),
      E'\n', '');
  end if;

  select coalesce(jsonb_agg(t.e - '_k' order by t.ord), '[]'::jsonb)
  into v_items
  from jsonb_array_elements(v_rows) with ordinality as t(e, ord)
  where t.ord <= v_size;

  return jsonb_build_object('items', v_items, 'nextCursor', v_next);
end;
$$;

revoke all on function receivable.list_customer_receivable_history(uuid, uuid, uuid, text, int) from public, anon;
grant execute on function receivable.list_customer_receivable_history(uuid, uuid, uuid, text, int) to authenticated;
