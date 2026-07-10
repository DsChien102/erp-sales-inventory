-- TH-02 cross-cutting: product reference_id (business key, dual mode hash / legacy explicit).
-- Context: docs/themes/TH-02-product-pricing/harness/07-api-contracts.md §Cross-cutting-reference_id
-- Depends: catalog.products from promoted guided-create migration.

create or replace function catalog._base32_sha256_prefix(p_input bytea, p_length int default 10)
returns text
language plpgsql
immutable
as $$
declare
  v_alphabet constant text := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  v_digest bytea := digest(p_input, 'sha256');
  v_bits bigint := 0;
  v_bit_count int := 0;
  v_result text := '';
  v_i int;
  v_byte int;
begin
  for v_i in 0 .. length(v_digest) - 1 loop
    v_byte := get_byte(v_digest, v_i);
    v_bits := (v_bits << 8) | v_byte;
    v_bit_count := v_bit_count + 8;
    while v_bit_count >= 5 loop
      v_bit_count := v_bit_count - 5;
      v_result := v_result || substr(v_alphabet, ((v_bits >> v_bit_count) & 31) + 1, 1);
      exit when length(v_result) >= p_length;
    end loop;
    exit when length(v_result) >= p_length;
  end loop;

  if length(v_result) < p_length and v_bit_count > 0 then
    v_result := v_result || substr(v_alphabet, ((v_bits << (5 - v_bit_count)) & 31) + 1, 1);
  end if;

  return left(v_result, p_length);
end;
$$;

create or replace function catalog._product_reference_id_from_uuid(p_id uuid)
returns text
language sql
immutable
as $$
  select 'P' || catalog._base32_sha256_prefix(uuid_send(p_id), 10);
$$;

alter table catalog.products
  add column if not exists reference_id text;

update catalog.products p
set reference_id = catalog._product_reference_id_from_uuid(p.id)
where p.reference_id is null;

alter table catalog.products
  alter column reference_id set not null;

alter table catalog.products
  drop constraint if exists chk_products_reference_id_not_blank,
  add constraint chk_products_reference_id_not_blank
    check (length(btrim(reference_id)) > 0);

drop index if exists catalog.uq_products_tenant_reference_id_normalized;

create unique index if not exists uq_products_tenant_reference_id
  on catalog.products (tenant_id, reference_id);

create or replace function catalog.create_product(
  p_tenant_id uuid,
  p_name text,
  p_reference_id text,
  p_actor_id uuid default auth.uid(),
  p_trade_name text default null,
  p_sku text default null,
  p_barcode text default null,
  p_description text default null,
  p_note text default null,
  p_images jsonb default '[]'::jsonb,
  p_base_unit_name text default null,
  p_readiness_status text default 'incomplete',
  p_readiness_blockers jsonb default '[]'::jsonb,
  p_idempotency_key uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
declare
  v_product_id uuid;
  v_sku_normalized text;
  v_barcode_normalized text;
  v_reference_id text;
  v_base_unit_name text;
  v_image jsonb;
  v_outbox_payload jsonb;
  v_readiness_status catalog.product_readiness_status;
  v_storage_key text;
  v_slot_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if p_actor_id is null or p_actor_id <> auth.uid() then
    raise exception 'actor mismatch';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.create') then
    raise exception 'permission denied: catalog.product.create';
  end if;

  if length(btrim(coalesce(p_name, ''))) = 0 then
    raise exception 'product name is required';
  end if;

  v_reference_id := btrim(coalesce(p_reference_id, ''));
  if length(v_reference_id) = 0 then
    raise exception 'reference id is required';
  end if;

  if p_idempotency_key is not null then
    select p.id
    into v_product_id
    from catalog.products p
    where p.tenant_id = p_tenant_id
      and p.idempotency_key = p_idempotency_key;

    if v_product_id is not null then
      return v_product_id;
    end if;
  end if;

  v_sku_normalized := nullif(lower(btrim(coalesce(p_sku, ''))), '');
  v_barcode_normalized := nullif(btrim(coalesce(p_barcode, '')), '');
  v_base_unit_name := nullif(btrim(coalesce(p_base_unit_name, '')), '');

  if exists (
    select 1
    from catalog.products p
    where p.tenant_id = p_tenant_id
      and p.reference_id = v_reference_id
  ) then
    raise exception 'duplicate reference_id';
  end if;

  if v_sku_normalized is not null
    and exists (
      select 1
      from catalog.products p
      where p.tenant_id = p_tenant_id
        and p.sku_normalized = v_sku_normalized
    ) then
    raise exception 'duplicate sku';
  end if;

  if v_barcode_normalized is not null
    and exists (
      select 1
      from catalog.products p
      where p.tenant_id = p_tenant_id
        and p.barcode_normalized = v_barcode_normalized
    ) then
    raise exception 'duplicate barcode';
  end if;

  v_readiness_status := coalesce(
    p_readiness_status::catalog.product_readiness_status,
    'incomplete'::catalog.product_readiness_status
  );

  begin
    insert into catalog.products (
      tenant_id,
      idempotency_key,
      reference_id,
      name,
      trade_name,
      sku,
      sku_normalized,
      barcode,
      barcode_normalized,
      description,
      note,
      business_status,
      created_by,
      updated_by
    )
    values (
      p_tenant_id,
      p_idempotency_key,
      v_reference_id,
      btrim(p_name),
      nullif(btrim(coalesce(p_trade_name, '')), ''),
      nullif(btrim(coalesce(p_sku, '')), ''),
      v_sku_normalized,
      nullif(btrim(coalesce(p_barcode, '')), ''),
      v_barcode_normalized,
      nullif(btrim(coalesce(p_description, '')), ''),
      nullif(btrim(coalesce(p_note, '')), ''),
      'active',
      p_actor_id,
      p_actor_id
    )
    returning id into v_product_id;
  exception
    when unique_violation then
      if exists (
        select 1 from catalog.products p
        where p.tenant_id = p_tenant_id
          and p.reference_id = v_reference_id
      ) then
        raise exception 'duplicate reference_id';
      end if;
      if v_sku_normalized is not null
        and exists (
          select 1 from catalog.products p
          where p.tenant_id = p_tenant_id and p.sku_normalized = v_sku_normalized
        ) then
        raise exception 'duplicate sku';
      end if;
      if v_barcode_normalized is not null
        and exists (
          select 1 from catalog.products p
          where p.tenant_id = p_tenant_id and p.barcode_normalized = v_barcode_normalized
        ) then
        raise exception 'duplicate barcode';
      end if;
      raise;
  end;

  if p_images is not null and jsonb_typeof(p_images) = 'array' then
    for v_image in select * from jsonb_array_elements(p_images)
    loop
      v_storage_key := btrim(v_image ->> 'storage_key');
      if v_storage_key is null or length(v_storage_key) = 0 then
        continue;
      end if;

      begin
        v_slot_id := catalog._consume_image_upload_slot(
          p_tenant_id,
          v_storage_key,
          p_actor_id
        );
      exception
        when others then
          continue;
      end;

      insert into catalog.product_images (
        tenant_id,
        product_id,
        storage_key,
        file_url,
        is_primary,
        sort_order,
        processing_status,
        upload_slot_id
      )
      values (
        p_tenant_id,
        v_product_id,
        v_storage_key,
        nullif(btrim(coalesce(v_image ->> 'url', '')), ''),
        coalesce((v_image ->> 'is_primary')::boolean, false),
        coalesce((v_image ->> 'sort_order')::integer, 0),
        'ready',
        v_slot_id
      );
    end loop;
  end if;

  if v_base_unit_name is not null then
    insert into catalog.product_units (
      tenant_id,
      product_id,
      unit_name,
      is_base_unit,
      conversion_rate_to_base
    )
    values (
      p_tenant_id,
      v_product_id,
      v_base_unit_name,
      true,
      1
    );
  end if;

  insert into catalog.product_readiness (
    product_id,
    tenant_id,
    status,
    blockers
  )
  values (
    v_product_id,
    p_tenant_id,
    v_readiness_status,
    coalesce(p_readiness_blockers, '[]'::jsonb)
  );

  insert into catalog.product_change_history (
    tenant_id,
    product_id,
    action,
    payload,
    actor_id
  )
  values (
    p_tenant_id,
    v_product_id,
    'CREATED',
    jsonb_build_object(
      'product_id', v_product_id,
      'reference_id', v_reference_id,
      'name', btrim(p_name),
      'sku', nullif(btrim(coalesce(p_sku, '')), ''),
      'barcode', nullif(btrim(coalesce(p_barcode, '')), '')
    ),
    p_actor_id
  );

  v_outbox_payload := jsonb_build_object(
    'product_id', v_product_id,
    'reference_id', v_reference_id,
    'tenant_id', p_tenant_id,
    'name', btrim(p_name)
  );

  perform catalog.enqueue_outbox_message(
    p_tenant_id,
    'catalog.product.created',
    v_outbox_payload
  );

  return v_product_id;
end;
$$;

revoke all on function catalog.create_product(
  uuid, text, text, uuid, text, text, text, text, text, jsonb, text, text, jsonb, uuid
) from public, anon;
grant execute on function catalog.create_product(
  uuid, text, text, uuid, text, text, text, text, text, jsonb, text, text, jsonb, uuid
) to authenticated, service_role;

-- Discovery read RPCs: expose reference_id on list / control center projections.

create or replace function catalog.search_products(
  p_tenant_id uuid,
  p_keyword text default null,
  p_business_statuses text[] default array['active']::text[],
  p_readiness_filter text default null,
  p_include_soft_deleted boolean default false,
  p_limit int default 50,
  p_offset int default 0
)
returns table (
  product_id uuid,
  name text,
  trade_name text,
  sku text,
  barcode text,
  primary_image_url text,
  business_status text,
  is_soft_deleted boolean,
  base_unit_name text,
  stock_qty numeric,
  list_price numeric,
  floor_price numeric,
  updated_at timestamptz,
  has_base_unit boolean,
  has_images boolean,
  has_stock boolean,
  has_base_price boolean,
  has_price_band boolean,
  has_required_custom_fields boolean,
  stock_mode text,
  base_price_mode text,
  total_count bigint
)
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
declare
  v_keyword text;
  v_keyword_normalized text;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.view') then
    raise exception 'permission denied: catalog.product.view';
  end if;

  v_keyword := nullif(btrim(coalesce(p_keyword, '')), '');
  v_keyword_normalized := nullif(lower(v_keyword), '');

  return query
  with filtered as (
    select
      p.id,
      p.name,
      p.trade_name,
      p.sku,
      p.barcode,
      (
        select coalesce(i.file_url, i.storage_key)
        from catalog.product_images i
        where i.product_id = p.id
          and i.tenant_id = p_tenant_id
        order by i.is_primary desc, i.sort_order asc, i.created_at asc
        limit 1
      ) as primary_image_url,
      p.business_status::text as business_status,
      (p.deleted_at is not null) as is_soft_deleted,
      (
        select u.unit_name
        from catalog.product_units u
        where u.product_id = p.id
          and u.tenant_id = p_tenant_id
          and u.is_base_unit = true
        limit 1
      ) as base_unit_name,
      (
        select sp.initial_stock
        from catalog.product_stock_profiles sp
        where sp.product_id = p.id
          and sp.tenant_id = p_tenant_id
        limit 1
      ) as stock_qty,
      (
        select pb.list_price_amount
        from catalog.product_unit_price_bands pb
        join catalog.product_units bu
          on bu.id = pb.product_unit_id
         and bu.product_id = p.id
         and bu.is_base_unit = true
        where pb.product_id = p.id
          and pb.tenant_id = p_tenant_id
        limit 1
      ) as list_price,
      (
        select pb.floor_price_amount
        from catalog.product_unit_price_bands pb
        join catalog.product_units bu
          on bu.id = pb.product_unit_id
         and bu.product_id = p.id
         and bu.is_base_unit = true
        where pb.product_id = p.id
          and pb.tenant_id = p_tenant_id
        limit 1
      ) as floor_price,
      p.updated_at,
      f.has_base_unit,
      f.has_images,
      f.has_stock,
      f.has_base_price,
      f.has_price_band,
      f.has_required_custom_fields,
      f.stock_mode,
      f.base_price_mode
    from catalog.products p
    cross join lateral catalog._product_operational_facts(p_tenant_id, p.id) f
    where p.tenant_id = p_tenant_id
      and (p_include_soft_deleted or p.deleted_at is null)
      and p.business_status::text = any (p_business_statuses)
      and (
        v_keyword is null
        or p.name ilike '%' || v_keyword || '%'
        or coalesce(p.trade_name, '') ilike '%' || v_keyword || '%'
        or (v_keyword_normalized is not null and p.sku_normalized = v_keyword_normalized)
        or (v_keyword is not null and p.barcode_normalized = btrim(v_keyword))
      )
  ),
  readiness_filtered as (
    select *
    from filtered f
    where p_readiness_filter is null
      or (
        p_readiness_filter = 'ready_to_sell'
        and catalog._product_readiness_is_ready(
          f.has_base_unit, f.has_images, f.has_stock, f.has_base_price,
          f.has_price_band, f.has_required_custom_fields, f.stock_mode, f.base_price_mode
        )
      )
      or (
        p_readiness_filter = 'incomplete'
        and not catalog._product_readiness_is_ready(
          f.has_base_unit, f.has_images, f.has_stock, f.has_base_price,
          f.has_price_band, f.has_required_custom_fields, f.stock_mode, f.base_price_mode
        )
      )
  ),
  counted as (
    select count(*)::bigint as total_count from readiness_filtered
  )
  select
    rf.id as product_id,
    rf.name,
    rf.trade_name,
    rf.sku,
    rf.barcode,
    rf.primary_image_url,
    rf.business_status,
    rf.is_soft_deleted,
    rf.base_unit_name,
    rf.stock_qty,
    rf.list_price,
    rf.floor_price,
    rf.updated_at,
    rf.has_base_unit,
    rf.has_images,
    rf.has_stock,
    rf.has_base_price,
    rf.has_price_band,
    rf.has_required_custom_fields,
    rf.stock_mode,
    rf.base_price_mode,
    c.total_count
  from readiness_filtered rf
  cross join counted c
  order by rf.updated_at desc, rf.name asc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
end;
$$;

create or replace function catalog.get_product_control_center(
  p_tenant_id uuid,
  p_product_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
declare
  v_result jsonb;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.view_detail') then
    raise exception 'permission denied: catalog.product.view_detail';
  end if;

  select jsonb_build_object(
    'product_id', p.id,
    'name', p.name,
    'trade_name', p.trade_name,
    'sku', p.sku,
    'barcode', p.barcode,
    'description', p.description,
    'note', p.note,
    'business_status', p.business_status::text,
    'is_soft_deleted', (p.deleted_at is not null),
    'primary_image_url', (
      select coalesce(i.file_url, i.storage_key)
      from catalog.product_images i
      where i.product_id = p.id and i.tenant_id = p_tenant_id
      order by i.is_primary desc, i.sort_order asc
      limit 1
    ),
    'images', coalesce((
      select jsonb_agg(coalesce(i.file_url, i.storage_key) order by i.is_primary desc, i.sort_order asc)
      from catalog.product_images i
      where i.product_id = p.id and i.tenant_id = p_tenant_id
    ), '[]'::jsonb),
    'base_unit_name', (
      select u.unit_name
      from catalog.product_units u
      where u.product_id = p.id and u.is_base_unit = true
      limit 1
    ),
    'conversion_units', coalesce((
      select jsonb_agg(jsonb_build_object(
        'name', u.unit_name,
        'conversion_rate', u.conversion_rate_to_base,
        'is_active', true
      ) order by u.created_at)
      from catalog.product_units u
      where u.product_id = p.id
        and u.tenant_id = p_tenant_id
        and u.is_base_unit = false
    ), '[]'::jsonb),
    'stock_mode', f.stock_mode,
    'stock_qty', (
      select sp.initial_stock
      from catalog.product_stock_profiles sp
      where sp.product_id = p.id
      limit 1
    ),
    'base_price_mode', f.base_price_mode,
    'base_price_amount', (
      select bp.base_price_amount
      from catalog.product_base_price_profiles bp
      where bp.product_id = p.id
      limit 1
    ),
    'base_price_currency', coalesce((
      select bp.currency
      from catalog.product_base_price_profiles bp
      where bp.product_id = p.id
      limit 1
    ), 'VND'),
    'list_price', (
      select pb.list_price_amount
      from catalog.product_unit_price_bands pb
      join catalog.product_units bu on bu.id = pb.product_unit_id and bu.is_base_unit = true
      where pb.product_id = p.id
      limit 1
    ),
    'floor_price', (
      select pb.floor_price_amount
      from catalog.product_unit_price_bands pb
      join catalog.product_units bu on bu.id = pb.product_unit_id and bu.is_base_unit = true
      where pb.product_id = p.id
      limit 1
    ),
    'has_base_unit', f.has_base_unit,
    'has_images', f.has_images,
    'has_stock', f.has_stock,
    'has_base_price', f.has_base_price,
    'has_price_band', f.has_price_band,
    'has_required_custom_fields', f.has_required_custom_fields,
    'change_history_preview', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', h.id,
        'occurred_at', h.created_at,
        'actor_display_name', left(h.actor_id::text, 8),
        'change_type', h.action,
        'summary', h.action,
        'value_before', h.payload ->> 'value_before',
        'value_after', h.payload ->> 'value_after'
      ) order by h.created_at desc)
      from (
        select *
        from catalog.product_change_history h
        where h.product_id = p.id
          and h.tenant_id = p_tenant_id
        order by h.created_at desc
        limit 5
      ) h
    ), '[]'::jsonb)
  )
  into v_result
  from catalog.products p
  cross join lateral catalog._product_operational_facts(p_tenant_id, p.id) f
  where p.tenant_id = p_tenant_id
    and p.id = p_product_id;

  if v_result is null then
    raise exception 'product not found';
  end if;

  return v_result;
end;
$$;
