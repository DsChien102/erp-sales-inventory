create or replace function catalog._build_product_search_text(
  p_tenant_id uuid,
  p_product_id uuid
)
returns text
language sql
stable
security definer
set search_path = catalog, extensions, pg_temp
as $$
  select lower(
    catalog.unaccent_immutable(
      trim(
        both from concat_ws(
          ' ',
          nullif(btrim(coalesce(p.name, '')), ''),
          nullif(btrim(coalesce(p.trade_name, '')), ''),
          nullif(btrim(coalesce(p.sku, '')), ''),
          nullif(btrim(coalesce(p.barcode, '')), ''),
          nullif(
            btrim(
              coalesce(
                (
                  select string_agg(
                    catalog._product_custom_field_display_value(
                      f.field_type,
                      v.value_text,
                      v.value_number,
                      v.value_date,
                      v.value_boolean,
                      o.label
                    ),
                    ' '
                  )
                  from catalog.custom_field_groups g
                  join catalog.custom_fields f
                    on f.group_id = g.id
                   and f.tenant_id = p_tenant_id
                  join catalog.product_custom_field_values v
                    on v.custom_field_id = f.id
                   and v.product_id = p_product_id
                   and v.tenant_id = p_tenant_id
                  left join catalog.custom_field_options o
                    on o.id = v.value_option_id
                  where g.tenant_id = p_tenant_id
                    and g.status = 'active'
                    and f.status = 'active'
                    and f.is_searchable = true
                    and f.field_type in ('text', 'singleSelect')
                ),
                ''
              )
            ),
            ''
          )
        )
      )
    )
  )
  from catalog.products p
  where p.id = p_product_id
    and p.tenant_id = p_tenant_id;
$$;
