create or replace function catalog._normalize_product_sku(p_sku text)
returns text
language sql
immutable
as $$
  select nullif(upper(btrim(coalesce(p_sku, ''))), '');
$$;
