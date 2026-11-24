-- TH-07 / KB-KGV-003 / PLAN 5-A4: Cặp cửa hàng–kho mặc định (RPC inventory).
-- Chạy trên DB LOCAL sau `supabase db reset`:
--   psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/inventory_default_pair.sql
-- Kết thúc bằng `raise notice 'inventory_default_pair: OK'`; mọi ca sai đều `raise exception 'FAIL: …'`.

begin;

do $$
declare
  v_owner uuid := gen_random_uuid();
  v_stranger uuid := gen_random_uuid();
  v_tenant uuid;
  v_default_store_id uuid;
  v_claims text;
  v_res jsonb;
  v_res2 jsonb;
  v_get jsonb;
  v_caught boolean;
  v_walk_in_count int;
begin
  -- 0) Tạo auth.users cho owner và stranger
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  )
  values
    (
      v_owner, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
      'owner-' || v_owner::text || '@example.com',
      '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
    ),
    (
      v_stranger, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
      'stranger-' || v_stranger::text || '@example.com',
      '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
    );

  v_tenant := iam._create_tenant_for_owner(
    v_owner,
    jsonb_build_object(
      'name', 'Nha thuoc Test Default Pair', 'contact_phone', '0900000001',
      'contact_email', 'owner@example.com', 'province_code', '01',
      'commune_code', '00001', 'address_text', 'So 1'
    )
  );

  if v_tenant is null then
    raise exception 'FAIL: tenant was not created';
  end if;

  -- Thiết lập session role authenticated với sub = v_owner
  v_claims := json_build_object('sub', v_owner::text, 'role', 'authenticated')::text;
  perform set_config('request.jwt.claims', v_claims, true);
  perform set_config('request.jwt.claim.sub', v_owner::text, true);
  set local role authenticated;

  -- 1) get khi chưa có cặp → bắt lỗi DEFAULT_PAIR_MISSING
  v_caught := false;
  begin
    perform inventory.get_default_store_warehouse_pair(v_tenant);
  exception when others then
    if sqlerrm = 'DEFAULT_PAIR_MISSING' then
      v_caught := true;
    else
      raise exception 'FAIL [1]: expected DEFAULT_PAIR_MISSING but got [%]', sqlerrm;
    end if;
  end;
  if not v_caught then
    raise exception 'FAIL [1]: get_default_store_warehouse_pair succeeded when pair is missing';
  end if;

  -- 2) ensure → storeId = id cửa hàng code = 'default' của tổ chức, replayed = false
  v_res := inventory.ensure_default_store_warehouse_pair(v_tenant, gen_random_uuid());
  if v_res is null then
    raise exception 'FAIL [2]: ensure returned null';
  end if;

  select id into v_default_store_id
  from iam.stores
  where tenant_id = v_tenant and code = 'default';

  if v_default_store_id is null then
    raise exception 'FAIL [2]: default store not found in iam.stores';
  end if;

  if (v_res->>'storeId')::uuid <> v_default_store_id then
    raise exception 'FAIL [2]: expected storeId % but got %', v_default_store_id, v_res->>'storeId';
  end if;

  if (v_res->>'replayed')::boolean is not false then
    raise exception 'FAIL [2]: expected replayed false on first ensure';
  end if;

  if (v_res->>'warehouseId') is null or (v_res->>'warehouseName') is null then
    raise exception 'FAIL [2]: missing warehouseId or warehouseName in result';
  end if;

  -- 3) ensure lần hai → cùng warehouseId, replayed = true
  v_res2 := inventory.ensure_default_store_warehouse_pair(v_tenant, gen_random_uuid());
  if (v_res2->>'warehouseId')::uuid <> (v_res->>'warehouseId')::uuid then
    raise exception 'FAIL [3]: expected same warehouseId % but got %', v_res->>'warehouseId', v_res2->>'warehouseId';
  end if;

  if (v_res2->>'storeId')::uuid <> v_default_store_id then
    raise exception 'FAIL [3]: expected same storeId % but got %', v_default_store_id, v_res2->>'storeId';
  end if;

  if (v_res2->>'replayed')::boolean is not true then
    raise exception 'FAIL [3]: expected replayed true on second ensure';
  end if;

  -- 3b) "Mua lẻ / khác" được tạo đúng một lần (G5-2b)
  reset role;
  select count(*) into v_walk_in_count
  from partner.partners p
  join partner.partner_roles r on r.partner_id = p.partner_id and r.role = 'supplier'
  where p.tenant_id = v_tenant
    and p.is_system
    and p.display_name = 'Mua lẻ / khác';
  if v_walk_in_count <> 1 then
    raise exception 'FAIL [3b]: walk_in_created_once expected 1 system supplier, got %', v_walk_in_count;
  end if;
  set local role authenticated;

  -- 4) get → cùng storeId / warehouseId
  v_get := inventory.get_default_store_warehouse_pair(v_tenant);
  if (v_get->>'storeId')::uuid <> v_default_store_id then
    raise exception 'FAIL [4]: expected storeId % in get, got %', v_default_store_id, v_get->>'storeId';
  end if;

  if (v_get->>'warehouseId')::uuid <> (v_res->>'warehouseId')::uuid then
    raise exception 'FAIL [4]: expected warehouseId % in get, got %', v_res->>'warehouseId', v_get->>'warehouseId';
  end if;

  -- 5) claims của user không là thành viên → get lỗi 'Permission denied: inventory.default_pair.read'
  reset role;
  v_claims := json_build_object('sub', v_stranger::text, 'role', 'authenticated')::text;
  perform set_config('request.jwt.claims', v_claims, true);
  perform set_config('request.jwt.claim.sub', v_stranger::text, true);
  set local role authenticated;

  v_caught := false;
  begin
    perform inventory.get_default_store_warehouse_pair(v_tenant);
  exception when others then
    if sqlerrm = 'Permission denied: inventory.default_pair.read' then
      v_caught := true;
    else
      raise exception 'FAIL [5]: expected Permission denied: inventory.default_pair.read but got [%]', sqlerrm;
    end if;
  end;
  if not v_caught then
    raise exception 'FAIL [5]: stranger accessed get_default_store_warehouse_pair without permission';
  end if;

  reset role;
  raise notice 'inventory_default_pair: OK';
end;
$$;

rollback;

