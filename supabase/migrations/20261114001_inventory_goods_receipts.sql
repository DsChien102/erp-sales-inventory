-- Title: inventory goods receipts
-- Kind: schema
-- Intent: inventory_goods_receipts
-- Context: TH-07 / spec gia von muc 4.1, 12.1-12.3; PLAN T7-G5-3
-- Touches: goods_receipts, goods_receipt_lines, goods_receipt_lots, _program_is_locked, get_goods_receipt_form_options, record_goods_receipt, list_goods_receipts, get_goods_receipt
-- Safety: one-shot ; low lock impact on new tables
-- Depends on: 20261110001_inventory_core, 20261113001_inventory_supplier_programs

create schema if not exists inventory;

-- ---------------------------------------------------------------------------
-- 1. Tables
-- ---------------------------------------------------------------------------

create table inventory.goods_receipts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  receipt_no text not null,
  warehouse_id uuid not null references inventory.warehouses (id),
  supplier_id uuid not null references partner.partners (partner_id),
  supplier_doc_no text null,
  business_date date not null,
  freight_cost_vnd bigint not null default 0,
  trade_discount_vnd bigint not null default 0,
  purchase_total_vnd bigint not null,
  landed_total_vnd bigint not null,
  line_count int not null,
  lot_count int not null,
  created_by uuid not null,
  created_at timestamptz not null default now(),
  constraint goods_receipts_tenant_no_key unique (tenant_id, receipt_no),
  constraint chk_goods_receipts_freight check (freight_cost_vnd >= 0),
  constraint chk_goods_receipts_discount check (trade_discount_vnd >= 0),
  constraint chk_goods_receipts_discount_max check (trade_discount_vnd <= purchase_total_vnd + freight_cost_vnd),
  constraint chk_goods_receipts_landed_total check (landed_total_vnd = purchase_total_vnd + freight_cost_vnd - trade_discount_vnd),
  constraint chk_goods_receipts_supplier_doc check (supplier_doc_no is null or length(btrim(supplier_doc_no)) between 1 and 60)
);

create index goods_receipts_tenant_supplier_idx
  on inventory.goods_receipts (tenant_id, supplier_id, created_at desc);

create table inventory.goods_receipt_lines (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references inventory.goods_receipts (id) on delete cascade,
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  line_no int not null,
  product_id uuid not null references catalog.products (id),
  unit_id uuid not null references catalog.product_units (id),
  unit_name text not null,
  conversion_rate numeric not null check (conversion_rate > 0),
  paid_qty int not null check (paid_qty > 0),
  free_qty int not null default 0 check (free_qty >= 0),
  unit_price_vnd bigint not null check (unit_price_vnd > 0),
  gross_amount_vnd bigint not null,
  program_id uuid null references inventory.supplier_programs (id),
  tier_discount_percent numeric(5,2) null check (tier_discount_percent is null or (tier_discount_percent >= 0 and tier_discount_percent <= 100)),
  tier_discount_vnd bigint not null default 0,
  purchase_amount_vnd bigint not null,
  allocated_freight_vnd bigint not null default 0,
  allocated_discount_vnd bigint not null default 0,
  landed_amount_vnd bigint not null,
  landed_unit_cost numeric(18,4) not null,
  constraint goods_receipt_lines_receipt_product_unit_key unique (receipt_id, product_id, unit_id),
  constraint goods_receipt_lines_receipt_line_no_key unique (receipt_id, line_no),
  constraint chk_goods_receipt_lines_purchase check (purchase_amount_vnd = gross_amount_vnd - tier_discount_vnd),
  constraint chk_goods_receipt_lines_landed check (landed_amount_vnd = purchase_amount_vnd + allocated_freight_vnd - allocated_discount_vnd)
);

create index goods_receipt_lines_program_idx
  on inventory.goods_receipt_lines (program_id);

create table inventory.goods_receipt_lots (
  id uuid primary key default gen_random_uuid(),
  line_id uuid not null references inventory.goods_receipt_lines (id) on delete cascade,
  lot_no int not null,
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  lot_id uuid null references inventory.lots (id),
  lot_code text null,
  expiry_date date null,
  expiry_precision text null,
  manufacture_date date null,
  quantity int not null check (quantity > 0),
  quantity_base numeric not null check (quantity_base > 0),
  amount_vnd bigint not null,
  movement_id uuid not null,
  value_movement_id uuid not null,
  constraint chk_goods_receipt_lots_code check ((lot_id is null and lot_code is null) or (lot_id is not null and lot_code is not null)),
  constraint chk_goods_receipt_lots_no check (lot_no > 0),
  constraint unique_goods_receipt_lots_line_no unique (line_id, lot_no)
);

alter table inventory.goods_receipts enable row level security;
alter table inventory.goods_receipt_lines enable row level security;
alter table inventory.goods_receipt_lots enable row level security;

revoke all on inventory.goods_receipts from public, anon, authenticated;
revoke all on inventory.goods_receipt_lines from public, anon, authenticated;
revoke all on inventory.goods_receipt_lots from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. Public RPCs
-- ---------------------------------------------------------------------------

-- 2.1 get_goods_receipt_form_options
create or replace function inventory.get_goods_receipt_form_options(p_tenant_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_actor jsonb;
  v_warehouse_id uuid;
  v_warehouse_name text;
  v_today date := inventory._today();
  v_suppliers jsonb := '[]'::jsonb;
  v_products jsonb := '[]'::jsonb;
  v_lots jsonb := '[]'::jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  perform inventory._ensure_walk_in_supplier(p_tenant_id);
  v_warehouse_id := (v_actor->>'warehouse_id')::uuid;

  select display_name into v_warehouse_name
  from inventory.warehouses
  where id = v_warehouse_id;

  -- Suppliers
  select coalesce(jsonb_agg(s_obj order by s_obj->>'is_system' desc, s_obj->>'display_name'), '[]'::jsonb)
  into v_suppliers
  from (
    select jsonb_build_object(
      'partner_id', p.partner_id,
      'display_name', p.display_name,
      'is_system', coalesce(p.is_system, false)
    ) as s_obj
    from partner.partners p
    where p.tenant_id = p_tenant_id
      and p.status = 'active'
      and exists (
        select 1 from partner.partner_roles pr
        where pr.partner_id = p.partner_id
          and pr.tenant_id = p_tenant_id
          and pr.role = 'supplier'
          and pr.is_active
      )
  ) s;

  -- Products with units
  select coalesce(jsonb_agg(p_obj order by p_obj->>'name'), '[]'::jsonb)
  into v_products
  from (
    select jsonb_build_object(
      'product_id', p.id,
      'name', p.name,
      'code', p.sku,
      'barcode', p.barcode,
      'tracking_mode', p.tracking_mode,
      'expiry_required', p.expiry_required,
      'base_uom', coalesce(catalog._product_base_unit_name(p_tenant_id, p.id), ''),
      'units', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'unit_id', u.id,
            'name', u.unit_name,
            'rate', u.conversion_rate_to_base,
            'is_base', u.is_base_unit
          ) order by u.is_base_unit desc, u.conversion_rate_to_base
        )
        from catalog.product_units u
        where u.product_id = p.id
          and u.tenant_id = p_tenant_id
          and u.is_active
      ), '[]'::jsonb)
    ) as p_obj
    from catalog.products p
    where p.tenant_id = p_tenant_id
      and p.deleted_at is null
      and p.business_status = 'active'
  ) pr;

  -- Lots
  select coalesce(jsonb_agg(l_obj), '[]'::jsonb)
  into v_lots
  from (
    select jsonb_build_object(
      'product_id', l.product_id,
      'lot_code', l.lot_code,
      'expiry_date', l.expiry_date,
      'expiry_precision', l.expiry_precision
    ) as l_obj
    from inventory.lots l
    where l.tenant_id = p_tenant_id
  ) lt;

  return jsonb_build_object(
    'warehouse_name', coalesce(v_warehouse_name, ''),
    'today', v_today,
    'suppliers', v_suppliers,
    'products', v_products,
    'lots', v_lots
  );
end;
$$;

grant execute on function inventory.get_goods_receipt_form_options(uuid) to authenticated;

-- 2.2 record_goods_receipt
create or replace function inventory.record_goods_receipt(
  p_tenant_id uuid,
  p_idempotency_key text,
  p_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_actor jsonb;
  v_actor_id uuid;
  v_warehouse_id uuid;
  v_idemp jsonb;
  v_seen_keys text[] := '{}';
  v_today date := inventory._today();

  v_supplier_id uuid;
  v_supplier_doc_no text;
  v_freight bigint;
  v_discount bigint;
  v_lines jsonb;

  v_receipt_id uuid := gen_random_uuid();
  v_receipt_no text;
  v_seq int;

  v_line jsonb;
  v_line_idx int := 0;
  v_line_count int;
  v_lot_count int := 0;

  v_purchase_total bigint := 0;
  v_landed_total bigint := 0;

  -- Arrays / temps for calculation
  v_calc_lines jsonb := '[]'::jsonb;
  v_calc_item jsonb;
  v_max_purchase_idx int := -1;
  v_max_purchase_val bigint := -1;
  v_sum_f bigint := 0;
  v_sum_k bigint := 0;
  v_rem_f bigint;
  v_rem_k bigint;

  -- Movements lines payload
  v_movement_lines jsonb := '[]'::jsonb;
  v_post_res jsonb;
  v_post_lines jsonb;
  v_post_line jsonb;

  -- Supplier program handling
  v_reached_programs jsonb := '[]'::jsonb;
  v_prog inventory.supplier_programs%rowtype;
  v_res jsonb;
  v_supplier_name text;
  v_created_by_name text;
begin
  -- 1. Actor & Idempotency
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_actor_id := (v_actor->>'actor_id')::uuid;
  v_warehouse_id := (v_actor->>'warehouse_id')::uuid;

  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    perform inventory._raise('CONTEXT_INVALID', 'Dữ liệu không hợp lệ.');
  end if;

  v_idemp := inventory._begin_idempotency(p_tenant_id, 'goods_receipt.record', p_idempotency_key, md5(p_payload::text));

  if (v_idemp->>'decision') = 'replay' then
    return v_idemp->'result_snapshot';
  elsif (v_idemp->>'decision') = 'in_progress' then
    perform inventory._raise('COMMAND_IN_PROGRESS', 'Thao tác đang được xử lý.');
  end if;

  -- 2. Validate Supplier
  begin
    v_supplier_id := (p_payload->>'supplier_id')::uuid;
  exception when others then
    perform inventory._raise('SUPPLIER_REQUIRED', 'Nhà cung cấp là bắt buộc.');
  end;

  if v_supplier_id is null then
    perform inventory._raise('SUPPLIER_REQUIRED', 'Nhà cung cấp là bắt buộc.');
  end if;

  select display_name into v_supplier_name
  from partner.partners p
  where p.partner_id = v_supplier_id
    and p.tenant_id = p_tenant_id
    and p.status = 'active'
    and exists (
      select 1 from partner.partner_roles pr
      where pr.partner_id = p.partner_id
        and pr.tenant_id = p_tenant_id
        and pr.role = 'supplier'
        and pr.is_active
    );

  if not found then
    perform inventory._raise('SUPPLIER_INVALID', 'Nhà cung cấp không hợp lệ hoặc đã ngừng hoạt động.');
  end if;

  -- 3. Header Fields
  v_freight := coalesce((p_payload->>'freight_cost_vnd')::bigint, 0);
  v_discount := coalesce((p_payload->>'trade_discount_vnd')::bigint, 0);
  if v_freight < 0 or v_discount < 0 then
    perform inventory._raise('CONTEXT_INVALID', 'Chi phí hoặc chiết khấu không được âm.');
  end if;

  v_supplier_doc_no := btrim(p_payload->>'supplier_doc_no');
  if v_supplier_doc_no = '' then
    v_supplier_doc_no := null;
  elsif length(v_supplier_doc_no) > 60 then
    perform inventory._raise('CONTEXT_INVALID', 'Số chứng từ nhà cung cấp tối đa 60 ký tự.');
  end if;

  -- 4. Validate lines
  v_lines := p_payload->'lines';
  if v_lines is null or jsonb_typeof(v_lines) <> 'array' or jsonb_array_length(v_lines) = 0 or jsonb_array_length(v_lines) > 200 then
    perform inventory._raise('CONTEXT_INVALID', 'Phiếu nhận phải có từ 1 đến 200 dòng hàng.');
  end if;

  v_line_count := jsonb_array_length(v_lines);

  for v_line in select * from jsonb_array_elements(v_lines)
  loop
    v_line_idx := v_line_idx + 1;
    declare
      v_pid uuid;
      v_uid uuid;
      v_u_name text;
      v_rate numeric;
      v_price bigint;
      v_free int;
      v_program_id uuid;
      v_tier_pct numeric(5,2);
      v_lots jsonb;
      v_lot_item jsonb;
      v_sum_qty int := 0;
      v_paid int;
      v_gross bigint;
      v_tier_vnd bigint := 0;
      v_purchase bigint;
      v_prod record;
      v_lot_codes text[] := '{}';
      v_l_code text;
      v_l_qty int;
    begin
      v_pid := (v_line->>'product_id')::uuid;
      v_uid := (v_line->>'unit_id')::uuid;

      if (v_pid::text || ':' || v_uid::text) = any(v_seen_keys) then
        perform inventory._raise('CONTEXT_INVALID', 'Mỗi mặt hàng và đơn vị chỉ được xuất hiện một dòng trong phiếu.');
      end if;
      v_seen_keys := array_append(v_seen_keys, (v_pid::text || ':' || v_uid::text));

      v_price := (v_line->>'unit_price_vnd')::bigint;
      v_free := coalesce((v_line->>'free_qty')::int, 0);

      if (v_line->>'program_id') is not null and (v_line->>'program_id') <> '' then
        v_program_id := (v_line->>'program_id')::uuid;
      else
        v_program_id := null;
      end if;

      if (v_line->>'tier_discount_percent') is not null and (v_line->>'tier_discount_percent') <> '' then
        v_tier_pct := (v_line->>'tier_discount_percent')::numeric;
      else
        v_tier_pct := null;
      end if;

      v_lots := v_line->'lots';

      if v_price is null or v_price <= 0 or v_free < 0 or v_lots is null or jsonb_typeof(v_lots) <> 'array' or jsonb_array_length(v_lots) = 0 then
        perform inventory._raise('CONTEXT_INVALID', 'Thông tin dòng không hợp lệ.');
      end if;

      select id, name, tracking_mode, expiry_required
      into v_prod
      from catalog.products
      where id = v_pid and tenant_id = p_tenant_id and deleted_at is null and business_status = 'active';

      if not found then
        perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm không hợp lệ: ' || v_pid::text);
      end if;

      select unit_name, conversion_rate_to_base
      into v_u_name, v_rate
      from catalog.product_units
      where id = v_uid and product_id = v_pid and tenant_id = p_tenant_id;

      if not found then
        perform inventory._raise('CONTEXT_INVALID', 'Đơn vị tính không thuộc sản phẩm.');
      end if;

      -- Validate lots
      for v_lot_item in select * from jsonb_array_elements(v_lots)
      loop
        v_l_qty := (v_lot_item->>'quantity')::int;
        if v_l_qty is null or v_l_qty <= 0 then
          perform inventory._raise('CONTEXT_INVALID', 'Số lượng lô phải lớn hơn 0.');
        end if;
        v_sum_qty := v_sum_qty + v_l_qty;
        v_lot_count := v_lot_count + 1;

        if v_prod.tracking_mode = 'none' then
          if jsonb_array_length(v_lots) > 1 or (v_lot_item->>'lot_code') is not null then
            perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm không quản lý lô chỉ có đúng 1 phần tử không mã lô.');
          end if;
        elsif v_prod.tracking_mode = 'lot' then
          v_l_code := lower(btrim(coalesce(v_lot_item->>'lot_code', '')));
          if v_l_code = '' then
            perform inventory._raise('CONTEXT_INVALID', 'Mã lô là bắt buộc với sản phẩm quản lý theo lô.');
          end if;
          if v_l_code = any(v_lot_codes) then
            perform inventory._raise('CONTEXT_INVALID', 'Mã lô trùng lặp trong cùng dòng hàng.');
          end if;
          v_lot_codes := array_append(v_lot_codes, v_l_code);
        end if;

        if (v_lot_item ? 'expiry_precision') and (v_lot_item->>'expiry_precision') is not null then
          if (v_lot_item->>'expiry_precision') not in ('DAY', 'MONTH', 'YEAR') then
            perform inventory._raise('CONTEXT_INVALID', 'Độ chính xác hạn dùng không hợp lệ.');
          end if;
        end if;
      end loop;

      v_paid := v_sum_qty - v_free;
      if v_paid <= 0 then
        perform inventory._raise('CONTEXT_INVALID', 'Số lượng thanh toán (tổng trừ tặng) phải lớn hơn 0.');
      end if;

      -- 5. Program validation
      v_prog := inventory._effective_receipt_program(p_tenant_id, v_supplier_id, v_pid);
      if coalesce(v_prog.id, '00000000-0000-0000-0000-000000000000'::uuid) <> coalesce(v_program_id, '00000000-0000-0000-0000-000000000000'::uuid) then
        perform inventory._raise('RECEIPT_PROGRAM_CHANGED', 'Chương trình ưu đãi của nhà cung cấp đã thay đổi.');
      end if;

      if v_prog.id is not null and v_prog.kind = 'VOLUME_REBATE' then
        declare
          v_locked_status text;
        begin
          select sp.status into v_locked_status
          from inventory.supplier_programs sp
          where sp.id = v_prog.id and sp.tenant_id = p_tenant_id
          for update;

          if not found or v_locked_status not in ('ACTIVE', 'REACHED') then
            perform inventory._raise('RECEIPT_PROGRAM_CHANGED', 'Chương trình ưu đãi của nhà cung cấp đã thay đổi.');
          end if;
        end;
      end if;

      if v_prog.id is not null and v_prog.kind = 'TIER_DISCOUNT' then
        v_tier_pct := coalesce(v_tier_pct, 0);
        if v_tier_pct < 0 or v_tier_pct > 100 then
          perform inventory._raise('CONTEXT_INVALID', 'Mức giảm theo bậc phải từ 0 đến 100%.');
        end if;
      else
        if v_tier_pct is not null then
          perform inventory._raise('CONTEXT_INVALID', 'Không được truyền mức giảm bậc khi không có chương trình bậc.');
        end if;
        v_tier_pct := null;
      end if;

      -- Amounts
      v_gross := round(v_paid * v_price);
      if v_tier_pct is not null and v_tier_pct > 0 then
        v_tier_vnd := round(v_gross * v_tier_pct / 100);
      else
        v_tier_vnd := 0;
      end if;
      v_purchase := v_gross - v_tier_vnd;
      v_purchase_total := v_purchase_total + v_purchase;

      if v_purchase > v_max_purchase_val then
        v_max_purchase_val := v_purchase;
        v_max_purchase_idx := v_line_idx - 1;
      end if;

      v_calc_lines := v_calc_lines || jsonb_build_array(
        jsonb_build_object(
          'line_no', v_line_idx,
          'product_id', v_pid,
          'unit_id', v_uid,
          'unit_name', v_u_name,
          'conversion_rate', v_rate,
          'paid_qty', v_paid,
          'free_qty', v_free,
          'unit_price_vnd', v_price,
          'gross_amount_vnd', v_gross,
          'program_id', v_program_id,
          'program_kind', v_prog.kind,
          'tier_discount_percent', v_tier_pct,
          'tier_discount_vnd', v_tier_vnd,
          'purchase_amount_vnd', v_purchase,
          'total_qty', v_sum_qty,
          'lots', v_lots
        )
      );
    end;
  end loop;

  -- Check discount size
  if v_discount > (v_purchase_total + v_freight) then
    perform inventory._raise('RECEIPT_DISCOUNT_TOO_LARGE', 'Chiết khấu không được lớn hơn tổng giá mua và chi phí.');
  end if;

  v_landed_total := v_purchase_total + v_freight - v_discount;

  -- 6. Allocate freight and trade discount to lines
  v_sum_f := 0;
  v_sum_k := 0;
  for i in 0 .. (v_line_count - 1)
  loop
    v_calc_item := v_calc_lines->i;
    declare
      v_a_i bigint := (v_calc_item->>'purchase_amount_vnd')::bigint;
      v_f_i bigint;
      v_k_i bigint;
    begin
      if v_purchase_total > 0 then
        v_f_i := floor(v_freight * v_a_i / v_purchase_total::numeric)::bigint;
        v_k_i := floor(v_discount * v_a_i / v_purchase_total::numeric)::bigint;
      else
        v_f_i := 0;
        v_k_i := 0;
      end if;
      v_sum_f := v_sum_f + v_f_i;
      v_sum_k := v_sum_k + v_k_i;

      v_calc_lines := jsonb_set(v_calc_lines, array[i::text, 'allocated_freight_vnd'], to_jsonb(v_f_i));
      v_calc_lines := jsonb_set(v_calc_lines, array[i::text, 'allocated_discount_vnd'], to_jsonb(v_k_i));
    end;
  end loop;

  v_rem_f := v_freight - v_sum_f;
  v_rem_k := v_discount - v_sum_k;

  if v_max_purchase_idx >= 0 then
    v_calc_item := v_calc_lines->v_max_purchase_idx;
    v_calc_lines := jsonb_set(
      v_calc_lines,
      array[v_max_purchase_idx::text, 'allocated_freight_vnd'],
      to_jsonb((v_calc_item->>'allocated_freight_vnd')::bigint + v_rem_f)
    );
    v_calc_lines := jsonb_set(
      v_calc_lines,
      array[v_max_purchase_idx::text, 'allocated_discount_vnd'],
      to_jsonb((v_calc_item->>'allocated_discount_vnd')::bigint + v_rem_k)
    );
  end if;

  -- 7. Receipt Number sequence
  perform pg_advisory_xact_lock(hashtextextended(p_tenant_id::text || ':goods_receipt_no:' || v_today::text, 0));
  select count(*) + 1 into v_seq
  from inventory.goods_receipts
  where tenant_id = p_tenant_id and business_date = v_today;

  v_receipt_no := 'PN-' || to_char(v_today, 'YYMMDD') || '-' || lpad(v_seq::text, 2, '0');

  -- 8. Insert goods_receipts
  insert into inventory.goods_receipts (
    id, tenant_id, receipt_no, warehouse_id, supplier_id, supplier_doc_no,
    business_date, freight_cost_vnd, trade_discount_vnd, purchase_total_vnd,
    landed_total_vnd, line_count, lot_count, created_by, created_at
  ) values (
    v_receipt_id, p_tenant_id, v_receipt_no, v_warehouse_id, v_supplier_id, v_supplier_doc_no,
    v_today, v_freight, v_discount, v_purchase_total,
    v_landed_total, v_line_count, v_lot_count, v_actor_id, now()
  );

  -- 9. Insert lines & Prepare movement lines
  for i in 0 .. (v_line_count - 1)
  loop
    v_calc_item := v_calc_lines->i;
    declare
      v_line_id uuid := gen_random_uuid();
      v_a_i bigint := (v_calc_item->>'purchase_amount_vnd')::bigint;
      v_f_i bigint := (v_calc_item->>'allocated_freight_vnd')::bigint;
      v_k_i bigint := (v_calc_item->>'allocated_discount_vnd')::bigint;
      v_g_i bigint := v_a_i + v_f_i - v_k_i;
      v_rate numeric := (v_calc_item->>'conversion_rate')::numeric;
      v_tot_qty int := (v_calc_item->>'total_qty')::int;
      v_qty_base numeric := v_tot_qty * v_rate;
      v_landed_cost numeric(18,4) := round(v_g_i / v_qty_base, 4);
      v_item_lots jsonb := v_calc_item->'lots';
      v_lot_len int := jsonb_array_length(v_item_lots);
      v_lot_item jsonb;
      v_max_lot_idx int := -1;
      v_max_lot_qty int := -1;
      v_sum_lot_amt bigint := 0;
      v_lot_amounts bigint[] := '{}';
      v_amt_ij bigint;
      v_rem_lot_amt bigint;
    begin
      -- compute lot amounts
      for j in 0 .. (v_lot_len - 1)
      loop
        v_lot_item := v_item_lots->j;
        declare
          v_q_ij int := (v_lot_item->>'quantity')::int;
        begin
          v_amt_ij := floor(v_g_i * v_q_ij / v_tot_qty::numeric)::bigint;
          v_sum_lot_amt := v_sum_lot_amt + v_amt_ij;
          v_lot_amounts := array_append(v_lot_amounts, v_amt_ij);

          if v_q_ij > v_max_lot_qty then
            v_max_lot_qty := v_q_ij;
            v_max_lot_idx := j;
          end if;
        end;
      end loop;

      v_rem_lot_amt := v_g_i - v_sum_lot_amt;
      if v_max_lot_idx >= 0 and v_rem_lot_amt <> 0 then
        v_lot_amounts[v_max_lot_idx + 1] := v_lot_amounts[v_max_lot_idx + 1] + v_rem_lot_amt;
      end if;

      insert into inventory.goods_receipt_lines (
        id, receipt_id, tenant_id, line_no, product_id, unit_id, unit_name,
        conversion_rate, paid_qty, free_qty, unit_price_vnd, gross_amount_vnd,
        program_id, tier_discount_percent, tier_discount_vnd, purchase_amount_vnd,
        allocated_freight_vnd, allocated_discount_vnd, landed_amount_vnd, landed_unit_cost
      ) values (
        v_line_id, v_receipt_id, p_tenant_id, (v_calc_item->>'line_no')::int,
        (v_calc_item->>'product_id')::uuid, (v_calc_item->>'unit_id')::uuid,
        v_calc_item->>'unit_name', v_rate, (v_calc_item->>'paid_qty')::int,
        (v_calc_item->>'free_qty')::int, (v_calc_item->>'unit_price_vnd')::bigint,
        (v_calc_item->>'gross_amount_vnd')::bigint, (v_calc_item->>'program_id')::uuid,
        (v_calc_item->>'tier_discount_percent')::numeric, (v_calc_item->>'tier_discount_vnd')::bigint,
        v_a_i, v_f_i, v_k_i, v_g_i, v_landed_cost
      );

      v_calc_lines := jsonb_set(v_calc_lines, array[i::text, 'line_id'], to_jsonb(v_line_id));

      -- append lot movement lines
      for j in 0 .. (v_lot_len - 1)
      loop
        v_lot_item := v_item_lots->j;
        declare
          v_lot_row_id uuid := gen_random_uuid();
          v_q int := (v_lot_item->>'quantity')::int;
        begin
          v_item_lots := jsonb_set(v_item_lots, array[j::text, 'lot_row_id'], to_jsonb(v_lot_row_id));
          v_item_lots := jsonb_set(v_item_lots, array[j::text, 'amount_vnd'], to_jsonb(v_lot_amounts[j + 1]));

          v_movement_lines := v_movement_lines || jsonb_build_array(
            jsonb_build_object(
              'line_id', v_lot_row_id,
              'product_id', (v_calc_item->>'product_id')::uuid,
              'lot_code', v_lot_item->>'lot_code',
              'expiry_date', v_lot_item->>'expiry_date',
              'expiry_precision', v_lot_item->>'expiry_precision',
              'manufacture_date', v_lot_item->>'manufacture_date',
              'quantity_delta', v_q * v_rate,
              'movement_kind', 'RECEIPT',
              'unit_cost', v_landed_cost,
              'amount_vnd', v_lot_amounts[j + 1]
            )
          );
        end;
      end loop;

      v_calc_lines := jsonb_set(v_calc_lines, array[i::text, 'lots'], v_item_lots);
    end;
  end loop;

  -- 10. Post movements
  v_post_res := inventory._post_movements(
    p_tenant_id, v_warehouse_id, 'GOODS_RECEIPT', v_receipt_id, v_today, v_movement_lines, v_actor_id
  );
  v_post_lines := v_post_res->'lines';

  -- 11. Insert goods_receipt_lots
  for i in 0 .. (v_line_count - 1)
  loop
    v_calc_item := v_calc_lines->i;
    declare
      v_line_id uuid := (v_calc_item->>'line_id')::uuid;
      v_pid uuid := (v_calc_item->>'product_id')::uuid;
      v_rate numeric := (v_calc_item->>'conversion_rate')::numeric;
      v_item_lots jsonb := v_calc_item->'lots';
      v_lot_item jsonb;
      v_lot_idx int := 0;
    begin
      for v_lot_item in select * from jsonb_array_elements(v_item_lots)
      loop
        v_lot_idx := v_lot_idx + 1;
        declare
          v_lot_row_id uuid := (v_lot_item->>'lot_row_id')::uuid;
          v_lot_code text := btrim(coalesce(v_lot_item->>'lot_code', ''));
          v_lot_id uuid := null;
          v_post_match jsonb := null;
          v_p_elem jsonb;
        begin
          if v_lot_code <> '' then
            select id into v_lot_id
            from inventory.lots
            where tenant_id = p_tenant_id
              and product_id = v_pid
              and lower(lot_code) = lower(v_lot_code);
          end if;

          for v_p_elem in select * from jsonb_array_elements(v_post_lines)
          loop
            if (v_p_elem->>'line_id')::uuid = v_lot_row_id then
              v_post_match := v_p_elem;
              exit;
            end if;
          end loop;

          insert into inventory.goods_receipt_lots (
            id, line_id, lot_no, tenant_id, lot_id, lot_code, expiry_date,
            expiry_precision, manufacture_date, quantity, quantity_base,
            amount_vnd, movement_id, value_movement_id
          ) values (
            v_lot_row_id, v_line_id, v_lot_idx, p_tenant_id, v_lot_id,
            case when v_lot_code = '' then null else v_lot_code end,
            (v_lot_item->>'expiry_date')::date,
            v_lot_item->>'expiry_precision',
            (v_lot_item->>'manufacture_date')::date,
            (v_lot_item->>'quantity')::int,
            ((v_lot_item->>'quantity')::numeric * v_rate),
            (v_lot_item->>'amount_vnd')::bigint,
            (v_post_match->>'movement_id')::uuid,
            (v_post_match->>'value_movement_id')::uuid
          );
        end;
      end loop;
    end;
  end loop;

  -- 12. Volume rebate progress
  for i in 0 .. (v_line_count - 1)
  loop
    v_calc_item := v_calc_lines->i;
    if (v_calc_item->>'program_kind') = 'VOLUME_REBATE' and (v_calc_item->>'program_id') is not null then
      declare
        v_pr_id uuid := (v_calc_item->>'program_id')::uuid;
        v_pr_row inventory.supplier_programs%rowtype;
        v_p_qty numeric := (v_calc_item->>'paid_qty')::numeric * (v_calc_item->>'conversion_rate')::numeric;
        v_p_amt bigint := (v_calc_item->>'purchase_amount_vnd')::bigint;
      begin
        select * into v_pr_row
        from inventory.supplier_programs
        where id = v_pr_id and tenant_id = p_tenant_id
        for update;

        if found then
          insert into inventory.supplier_program_receipts (
            tenant_id, program_id, receipt_line_id, paid_qty, purchase_amount_vnd
          ) values (
            p_tenant_id, v_pr_id, (v_calc_item->>'line_id')::uuid, v_p_qty, v_p_amt
          );

          update inventory.supplier_programs
          set progress_qty = progress_qty + v_p_qty,
              status = case when status = 'ACTIVE' and (progress_qty + v_p_qty >= target_qty) then 'REACHED' else status end,
              reached_at = case when status = 'ACTIVE' and (progress_qty + v_p_qty >= target_qty) then now() else reached_at end,
              updated_by = v_actor_id,
              updated_at = now()
          where id = v_pr_id;

          if v_pr_row.status = 'ACTIVE' and (v_pr_row.progress_qty + v_p_qty >= v_pr_row.target_qty) then
            v_reached_programs := v_reached_programs || jsonb_build_array(
              jsonb_build_object('program_id', v_pr_id, 'name', v_pr_row.name)
            );
          end if;
        end if;
      end;
    end if;
  end loop;

  v_created_by_name := iam._member_display_name(v_actor_id);

  v_res := jsonb_build_object(
    'receipt_id', v_receipt_id,
    'receipt_no', v_receipt_no,
    'supplier_name', v_supplier_name,
    'supplier_doc_no', v_supplier_doc_no,
    'business_date', v_today,
    'line_count', v_line_count,
    'lot_count', v_lot_count,
    'landed_total_vnd', v_landed_total,
    'created_by_name', coalesce(v_created_by_name, ''),
    'stock_changes', coalesce(v_post_res->'stock_changes', '[]'::jsonb),
    'reached_programs', v_reached_programs
  );

  perform inventory._complete_idempotency(p_tenant_id, 'goods_receipt.record', p_idempotency_key, 'succeeded', v_res);

  return v_res;
end;
$$;

grant execute on function inventory.record_goods_receipt(uuid, text, jsonb) to authenticated;

-- 2.3 list_goods_receipts
create or replace function inventory.list_goods_receipts(
  p_tenant_id uuid,
  p_supplier_id uuid default null,
  p_limit integer default 100
)
returns jsonb
language plpgsql
stable
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_lim int := least(greatest(coalesce(p_limit, 100), 1), 200);
  v_list jsonb := '[]'::jsonb;
begin
  perform inventory._assert_actor(p_tenant_id, 'inventory.read');

  select coalesce(jsonb_agg(r_obj), '[]'::jsonb)
  into v_list
  from (
    select jsonb_build_object(
      'receipt_id', r.id,
      'receipt_no', r.receipt_no,
      'supplier_id', r.supplier_id,
      'supplier_name', p.display_name,
      'supplier_doc_no', r.supplier_doc_no,
      'business_date', r.business_date,
      'line_count', r.line_count,
      'landed_total_vnd', r.landed_total_vnd,
      'created_at', r.created_at
    ) as r_obj
    from inventory.goods_receipts r
    join partner.partners p on p.partner_id = r.supplier_id
    where r.tenant_id = p_tenant_id
      and (p_supplier_id is null or r.supplier_id = p_supplier_id)
    order by r.created_at desc
    limit v_lim
  ) t;

  return jsonb_build_object('receipts', v_list);
end;
$$;

grant execute on function inventory.list_goods_receipts(uuid, uuid, integer) to authenticated;

-- 2.4 get_goods_receipt
create or replace function inventory.get_goods_receipt(
  p_tenant_id uuid,
  p_receipt_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_rc record;
  v_lines jsonb := '[]'::jsonb;
  v_header jsonb;
begin
  perform inventory._assert_actor(p_tenant_id, 'inventory.read');

  select r.*, p.display_name as supplier_name, coalesce(p.is_system, false) as supplier_is_system,
         w.display_name as warehouse_name, iam._member_display_name(r.created_by) as created_by_name
  into v_rc
  from inventory.goods_receipts r
  join partner.partners p on p.partner_id = r.supplier_id
  join inventory.warehouses w on w.id = r.warehouse_id
  where r.id = p_receipt_id and r.tenant_id = p_tenant_id;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Phiếu nhận không tồn tại hoặc không thuộc cửa hàng.');
  end if;

  v_header := jsonb_build_object(
    'receipt_id', v_rc.id,
    'receipt_no', v_rc.receipt_no,
    'supplier_id', v_rc.supplier_id,
    'supplier_name', v_rc.supplier_name,
    'supplier_is_system', v_rc.supplier_is_system,
    'supplier_doc_no', v_rc.supplier_doc_no,
    'business_date', v_rc.business_date,
    'warehouse_name', v_rc.warehouse_name,
    'freight_cost_vnd', v_rc.freight_cost_vnd,
    'trade_discount_vnd', v_rc.trade_discount_vnd,
    'purchase_total_vnd', v_rc.purchase_total_vnd,
    'landed_total_vnd', v_rc.landed_total_vnd,
    'line_count', v_rc.line_count,
    'lot_count', v_rc.lot_count,
    'created_by_name', coalesce(v_rc.created_by_name, ''),
    'created_at', v_rc.created_at
  );

  select coalesce(jsonb_agg(l_obj order by (l_obj->>'line_no')::int), '[]'::jsonb)
  into v_lines
  from (
    select jsonb_build_object(
      'line_id', l.id,
      'line_no', l.line_no,
      'product_id', l.product_id,
      'product_name', pr.name,
      'product_code', pr.sku,
      'base_uom', coalesce(catalog._product_base_unit_name(p_tenant_id, pr.id), ''),
      'unit_name', l.unit_name,
      'conversion_rate', l.conversion_rate,
      'paid_qty', l.paid_qty,
      'free_qty', l.free_qty,
      'unit_price_vnd', l.unit_price_vnd,
      'gross_amount_vnd', l.gross_amount_vnd,
      'program_id', l.program_id,
      'program_name', sp.name,
      'program_kind', sp.kind,
      'tier_discount_percent', l.tier_discount_percent,
      'tier_discount_vnd', l.tier_discount_vnd,
      'purchase_amount_vnd', l.purchase_amount_vnd,
      'allocated_freight_vnd', l.allocated_freight_vnd,
      'allocated_discount_vnd', l.allocated_discount_vnd,
      'landed_amount_vnd', l.landed_amount_vnd,
      'landed_unit_cost', l.landed_unit_cost,
      'lots', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'lot_code', lt.lot_code,
            'expiry_date', lt.expiry_date,
            'expiry_precision', lt.expiry_precision,
            'manufacture_date', lt.manufacture_date,
            'quantity', lt.quantity,
            'allocated_landed_cost_vnd', lt.amount_vnd
          )
          order by lt.lot_no asc
        )
        from inventory.goods_receipt_lots lt
        where lt.line_id = l.id
      ), '[]'::jsonb)
    ) as l_obj
    from inventory.goods_receipt_lines l
    join catalog.products pr on pr.id = l.product_id
    left join inventory.supplier_programs sp on sp.id = l.program_id
    where l.receipt_id = p_receipt_id and l.tenant_id = p_tenant_id
  ) lines_t;

  return jsonb_build_object(
    'receipt', v_header,
    'lines', v_lines
  );
end;
$$;

grant execute on function inventory.get_goods_receipt(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Extend _program_is_locked to check goods_receipt_lines
-- ---------------------------------------------------------------------------
create or replace function inventory._program_is_locked(p_program_id uuid)
returns boolean
language sql
stable
security definer
set search_path = inventory, pg_temp
as $$
  select exists (
    select 1
    from inventory.supplier_program_receipts r
    where r.program_id = p_program_id
  ) or exists (
    select 1
    from inventory.goods_receipt_lines l
    where l.program_id = p_program_id
  );
$$;

revoke all on function inventory._program_is_locked(uuid) from public, anon, authenticated;


