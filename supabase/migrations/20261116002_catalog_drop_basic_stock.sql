-- Title: Drop basic stock tables, columns, and RPCs from catalog (T7-G5-5 Task 8)
-- Kind: migration
-- Intent: catalog_drop_basic_stock
-- Context: G5-5 removes Theme 2 basic stock; Catalog reads stock from inventory ledger.
-- Depends on: 20261116001_inventory_stocktake.sql

drop trigger if exists trg_product_stock_profiles_refresh_operational_facts
  on catalog.product_stock_profiles;

drop function if exists catalog._trg_product_stock_profiles_refresh_operational_facts();
drop function if exists catalog.set_basic_stock_quantity_base(uuid, uuid, text, numeric);
drop function if exists catalog.adjust_basic_stock(uuid, uuid, numeric, text, numeric);
drop function if exists catalog.get_product_stock_history(uuid, uuid, int);
drop function if exists catalog.search_products(uuid, text, text[], text, boolean, int, int);

alter table catalog.products
  drop column if exists fact_has_stock,
  drop column if exists fact_stock_mode;

drop table if exists catalog.product_stock_movements, catalog.product_stock_profiles;

