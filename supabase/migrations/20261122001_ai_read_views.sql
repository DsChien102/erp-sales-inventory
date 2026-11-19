-- Title: ai_read views (read-only, per-store filtered) + ai_reader role + ai.get_catalog
-- Kind: schema
-- Intent: ai_read_views
-- Context: AI-4 Task 1 (trợ lý "Hỏi Mosaic Retail" tự truy vấn); 6 view đã lọc theo cửa hàng của người hỏi
-- Touches: ai_reader, _tenant, _store, _warehouse, get_catalog, ai_read.don_ban, ai_read.ban_hang_thuan, ai_read.ton_kho, ai_read.bien_dong_kho, ai_read.san_pham, ai_read.khach_hang
-- Safety: one-shot ; new role, new schema and views only, no change to existing tables
-- Depends on: 20261120002_ai_assistant_log, 20261120001_sales_stats, 20261112001_inventory_stock_view, 20260714001_partner_v2_schema

-- 1. Role chỉ đọc view -------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'ai_reader') then
    create role ai_reader nologin;
  end if;
end;
$$;

-- Để hàm security definer (chủ postgres) `set local role ai_reader` được.
grant ai_reader to postgres;

-- Khi gọi qua PostgREST, session user là `authenticator`; SET ROLE kiểm theo session user.
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'authenticator') then
    grant ai_reader to authenticator;
  end if;
end;
$$;

create schema if not exists ai_read;
revoke all on schema ai_read from public, anon, authenticated;
grant usage on schema ai_read to ai_reader;

-- 2. Biến phiên do ai.run_query đặt ------------------------------------------
create or replace function ai._tenant()
returns uuid
language sql
stable
security definer
set search_path = pg_catalog, pg_temp
as $$
  select nullif(current_setting('ai.tenant_id', true), '')::uuid;
$$;

create or replace function ai._store()
returns uuid
language sql
stable
security definer
set search_path = pg_catalog, pg_temp
as $$
  select nullif(current_setting('ai.store_id', true), '')::uuid;
$$;

create or replace function ai._warehouse()
returns uuid
language sql
stable
security definer
set search_path = pg_catalog, pg_temp
as $$
  select nullif(current_setting('ai.warehouse_id', true), '')::uuid;
$$;

revoke all on function ai._tenant() from public, anon, authenticated;
revoke all on function ai._store() from public, anon, authenticated;
revoke all on function ai._warehouse() from public, anon, authenticated;

-- Hàm gọi trong view được kiểm quyền EXECUTE theo người đọc (ai_reader), không theo chủ view.
-- ai_reader không có USAGE trên schema ai / inventory / catalog và _validate_sql chặn gọi trực tiếp.
grant execute on function ai._tenant(), ai._store(), ai._warehouse() to ai_reader;
grant execute on function inventory._product_stock_rows(uuid, uuid[]) to ai_reader;
grant execute on function catalog._product_base_unit_name(uuid, uuid) to ai_reader;

-- 3. Views -------------------------------------------------------------------
-- Mặc định view đọc bảng bằng quyền chủ view (không security_invoker): ai_reader cần SELECT trên view
-- và EXECUTE trên các hàm view gọi (cấp ở trên).

create or replace view ai_read.don_ban as
select
  so.id as don_id,
  so.order_code::text as ma_don,
  (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date as ngay_ban,
  to_char(so.completed_at at time zone 'Asia/Ho_Chi_Minh', 'HH24:MI') as gio_ban,
  case so.lifecycle_status when 'cancelled' then 'da_huy' else 'hoan_tat' end as trang_thai,
  so.customer_partner_id as khach_id,
  case when so.customer_partner_id is null then 'Khách lẻ'
       else coalesce(pt.display_name, 'Khách') end as ten_khach,
  coalesce(
    (select nullif(trim(concat_ws(' ', pr.family_middle_name, pr.given_name)), '')
       from iam.platform_user_profiles pr where pr.user_id = so.seller_user_id),
    'Nhân viên') as ten_nhan_vien,
  (select count(*)::int from sales.sales_order_lines l
    where l.tenant_id = so.tenant_id and l.sales_order_id = so.id) as so_dong,
  so.payable_amount_minor::bigint as tong_tien_vnd,
  coalesce(st.collected_amount_minor, 0)::bigint as da_thu_vnd,
  coalesce(st.outstanding_amount_minor, 0)::bigint as con_no_vnd,
  so.payment_due_date as han_thanh_toan,
  (so.cancelled_at at time zone 'Asia/Ho_Chi_Minh')::date as ngay_huy
from sales.sales_orders so
left join sales.sales_order_settlements st
  on st.tenant_id = so.tenant_id and st.sales_order_id = so.id
left join partner.partners pt
  on pt.tenant_id = so.tenant_id and pt.partner_id = so.customer_partner_id
where so.tenant_id = ai._tenant()
  and so.store_id = ai._store();

create or replace view ai_read.ban_hang_thuan as
with facts as (
  -- bán: đơn hoàn tất trong kỳ (kể cả đơn bị huỷ sau đó)
  select 'ban'::text as loai_dong,
         (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date as ngay,
         so.id as don_id, so.order_code::text as ma_don,
         so.customer_partner_id as khach_id, so.seller_user_id,
         sol.product_id,
         sol.base_quantity_micros / 1000000.0 as so_luong,
         sol.line_total_minor::bigint as doanh_thu_vnd,
         coalesce(sol.cogs_amount_vnd, 0)::bigint as gia_von_vnd,
         so.tenant_id
  from sales.sales_orders so
  join sales.sales_order_lines sol
    on sol.tenant_id = so.tenant_id and sol.sales_order_id = so.id
  where so.tenant_id = ai._tenant() and so.store_id = ai._store()
  union all
  -- đổi: dòng hàng mới khách nhận
  select 'doi',
         (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date,
         so.id, so.order_code::text, so.customer_partner_id, so.seller_user_id,
         rl.product_id,
         rl.base_quantity_micros / 1000000.0,
         round(rl.quantity_micros::numeric / 1000000.0 * rl.unit_value_minor)::bigint,
         coalesce(rl.cogs_amount_vnd, 0)::bigint,
         so.tenant_id
  from sales.return_exchange_orders rx
  join sales.sales_orders so on so.tenant_id = rx.tenant_id and so.id = rx.sales_order_id
  join sales.return_exchange_lines rl
    on rl.tenant_id = rx.tenant_id and rl.return_exchange_order_id = rx.id
  where rx.tenant_id = ai._tenant() and so.store_id = ai._store()
    and rx.status = 'completed' and rl.line_role = 'exchange'
  union all
  -- trả: số lượng và tiền âm
  select 'tra',
         (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date,
         so.id, so.order_code::text, so.customer_partner_id, so.seller_user_id,
         rl.product_id,
         -(rl.base_quantity_micros / 1000000.0),
         -round(rl.quantity_micros::numeric / 1000000.0 * rl.unit_value_minor)::bigint,
         -coalesce(rl.cogs_amount_vnd, 0)::bigint,
         so.tenant_id
  from sales.return_exchange_orders rx
  join sales.sales_orders so on so.tenant_id = rx.tenant_id and so.id = rx.sales_order_id
  join sales.return_exchange_lines rl
    on rl.tenant_id = rx.tenant_id and rl.return_exchange_order_id = rx.id
  where rx.tenant_id = ai._tenant() and so.store_id = ai._store()
    and rx.status = 'completed' and rl.line_role = 'returned'
  union all
  -- huỷ: đảo ngược đơn bán, ghi theo ngày huỷ
  select 'huy',
         (so.cancelled_at at time zone 'Asia/Ho_Chi_Minh')::date,
         so.id, so.order_code::text, so.customer_partner_id, so.seller_user_id,
         sol.product_id,
         -(sol.base_quantity_micros / 1000000.0),
         -sol.line_total_minor::bigint,
         -coalesce(sol.cogs_amount_vnd, 0)::bigint,
         so.tenant_id
  from sales.sales_orders so
  join sales.sales_order_lines sol
    on sol.tenant_id = so.tenant_id and sol.sales_order_id = so.id
  where so.tenant_id = ai._tenant() and so.store_id = ai._store()
    and so.lifecycle_status = 'cancelled'
)
select
  f.loai_dong,
  f.ngay,
  f.don_id,
  f.ma_don,
  f.khach_id,
  case when f.khach_id is null then 'Khách lẻ' else coalesce(pt.display_name, 'Khách') end as ten_khach,
  coalesce(
    (select nullif(trim(concat_ws(' ', pr.family_middle_name, pr.given_name)), '')
       from iam.platform_user_profiles pr where pr.user_id = f.seller_user_id),
    'Nhân viên') as ten_nhan_vien,
  f.product_id as san_pham_id,
  coalesce(p.name, 'Sản phẩm') as ten_san_pham,
  f.so_luong,
  f.doanh_thu_vnd,
  f.gia_von_vnd
from facts f
left join partner.partners pt on pt.tenant_id = f.tenant_id and pt.partner_id = f.khach_id
left join catalog.products p on p.tenant_id = f.tenant_id and p.id = f.product_id;

create or replace view ai_read.ton_kho as
select
  p.id as san_pham_id,
  coalesce(p.sku, '') as ma_san_pham,
  p.name as ten_san_pham,
  catalog._product_base_unit_name(p.tenant_id, p.id) as don_vi,
  sr.physical as ton_vat_ly,
  sr.available as ton_kha_dung,
  psp.reorder_threshold as nguong_canh_bao,
  psp.target_level as muc_ton_muc_tieu,
  sr.has_near_expiry as can_han,
  sr.has_expired as da_het_han
from catalog.products p
join inventory._product_stock_rows(ai._tenant()) sr on sr.product_id = p.id
left join inventory.product_stock_policies psp
  on psp.tenant_id = p.tenant_id and psp.product_id = p.id
where p.tenant_id = ai._tenant()
  and p.deleted_at is null
  and p.business_status = 'active';

create or replace view ai_read.bien_dong_kho as
select
  sm.business_date as ngay,
  sm.product_id as san_pham_id,
  coalesce(p.name, 'Sản phẩm') as ten_san_pham,
  sm.movement_kind as loai,
  sm.quantity_delta as so_luong_thay_doi
from inventory.stock_movements sm
left join catalog.products p on p.tenant_id = sm.tenant_id and p.id = sm.product_id
where sm.tenant_id = ai._tenant()
  and sm.warehouse_id = ai._warehouse();

create or replace view ai_read.san_pham as
select
  p.id as san_pham_id,
  coalesce(p.sku, '') as ma_san_pham,
  p.name as ten_san_pham,
  coalesce(p.barcode, '') as ma_vach,
  p.business_status::text as trang_thai,
  (p.tracking_mode = 'lot') as theo_doi_lo
from catalog.products p
where p.tenant_id = ai._tenant()
  and p.deleted_at is null;

create or replace view ai_read.khach_hang as
select
  pt.partner_id as khach_id,
  pt.display_name as ten_khach,
  pt.status::text as trang_thai,
  (pt.created_at at time zone 'Asia/Ho_Chi_Minh')::date as ngay_tao
from partner.partners pt
where pt.tenant_id = ai._tenant()
  and pt.is_system = false
  and pt.status <> 'deleted'
  and exists (
    select 1 from partner.partner_roles r
    where r.partner_id = pt.partner_id and r.role = 'customer' and r.is_active
  );

-- 4. Mô tả (nguồn duy nhất cho Gemini) ---------------------------------------
comment on view ai_read.don_ban is
  'Mỗi dòng là một đơn bán đã hoàn tất hoặc đã huỷ của cửa hàng. Số đơn bán = đếm don_id với trang_thai = ''hoan_tat''. Dùng để liệt kê đơn, tìm đơn lớn nhất, đơn theo khách / nhân viên / giờ.';
comment on column ai_read.don_ban.don_id is 'Khoá đơn (ẩn khỏi bảng, dùng để mở đơn).';
comment on column ai_read.don_ban.ma_don is 'Mã đơn hiển thị cho người dùng.';
comment on column ai_read.don_ban.ngay_ban is 'Ngày bán (giờ Việt Nam).';
comment on column ai_read.don_ban.gio_ban is 'Giờ bán dạng HH24:MI (giờ Việt Nam).';
comment on column ai_read.don_ban.trang_thai is 'hoan_tat = đơn đã bán; da_huy = đơn đã bị huỷ.';
comment on column ai_read.don_ban.khach_id is 'Khoá khách (null = khách lẻ).';
comment on column ai_read.don_ban.ten_khach is 'Tên khách; ''Khách lẻ'' khi không gắn khách.';
comment on column ai_read.don_ban.ten_nhan_vien is 'Tên nhân viên bán đơn.';
comment on column ai_read.don_ban.so_dong is 'Số dòng hàng của đơn.';
comment on column ai_read.don_ban.tong_tien_vnd is 'Tổng tiền khách phải trả của đơn (đồng).';
comment on column ai_read.don_ban.da_thu_vnd is 'Số tiền đã thu của đơn (đồng).';
comment on column ai_read.don_ban.con_no_vnd is 'Số tiền khách còn nợ của đơn (đồng).';
comment on column ai_read.don_ban.han_thanh_toan is 'Hạn thanh toán của đơn bán nợ (ngày; có thể trống).';
comment on column ai_read.don_ban.ngay_huy is 'Ngày huỷ đơn (trống nếu chưa huỷ).';

comment on view ai_read.ban_hang_thuan is
  'Mỗi dòng là một dòng hàng của sự kiện bán / đổi / trả / huỷ. Doanh thu thuần = tổng doanh_thu_vnd (đã có dấu: trả và huỷ là số âm), khớp báo cáo thống kê. Đếm số đơn thì dùng don_ban, không đếm ở đây. Không dùng gia_von_vnd để tính lãi gộp chính thức (dùng công cụ lãi gộp).';
comment on column ai_read.ban_hang_thuan.loai_dong is 'ban = bán; doi = hàng đổi; tra = hàng khách trả; huy = đơn bị huỷ.';
comment on column ai_read.ban_hang_thuan.ngay is 'Ngày xảy ra sự kiện (giờ Việt Nam): ngày bán, ngày đổi / trả hoặc ngày huỷ.';
comment on column ai_read.ban_hang_thuan.don_id is 'Khoá đơn gốc (ẩn khỏi bảng, dùng để mở đơn).';
comment on column ai_read.ban_hang_thuan.ma_don is 'Mã đơn gốc.';
comment on column ai_read.ban_hang_thuan.khach_id is 'Khoá khách (null = khách lẻ).';
comment on column ai_read.ban_hang_thuan.ten_khach is 'Tên khách; ''Khách lẻ'' khi không gắn khách.';
comment on column ai_read.ban_hang_thuan.ten_nhan_vien is 'Tên nhân viên bán đơn gốc.';
comment on column ai_read.ban_hang_thuan.san_pham_id is 'Khoá sản phẩm (ẩn khỏi bảng, dùng để mở sản phẩm).';
comment on column ai_read.ban_hang_thuan.ten_san_pham is 'Tên sản phẩm.';
comment on column ai_read.ban_hang_thuan.so_luong is 'Số lượng theo đơn vị cơ bản, có dấu (trả và huỷ là số âm).';
comment on column ai_read.ban_hang_thuan.doanh_thu_vnd is 'Doanh thu của dòng (đồng), có dấu (trả và huỷ là số âm).';
comment on column ai_read.ban_hang_thuan.gia_von_vnd is 'Giá vốn của dòng (đồng), dấu như so_luong; chỉ để tham khảo.';

comment on view ai_read.ton_kho is
  'Mỗi dòng là một sản phẩm đang kinh doanh với tồn kho hiện tại. Dùng để xếp hạng tồn, so với ngưỡng / mức tồn mục tiêu.';
comment on column ai_read.ton_kho.san_pham_id is 'Khoá sản phẩm (ẩn khỏi bảng, dùng để mở sản phẩm).';
comment on column ai_read.ton_kho.ma_san_pham is 'Mã sản phẩm (SKU).';
comment on column ai_read.ton_kho.ten_san_pham is 'Tên sản phẩm.';
comment on column ai_read.ton_kho.don_vi is 'Đơn vị cơ bản của sản phẩm.';
comment on column ai_read.ton_kho.ton_vat_ly is 'Tồn vật lý hiện có trong kho.';
comment on column ai_read.ton_kho.ton_kha_dung is 'Tồn còn dùng được (không tính lô đã hết hạn).';
comment on column ai_read.ton_kho.nguong_canh_bao is 'Ngưỡng cảnh báo sắp hết (trống nếu chưa đặt).';
comment on column ai_read.ton_kho.muc_ton_muc_tieu is 'Mức tồn mục tiêu khi nhập thêm (trống nếu chưa đặt).';
comment on column ai_read.ton_kho.can_han is 'true nếu có lô sắp hết hạn.';
comment on column ai_read.ton_kho.da_het_han is 'true nếu có lô đã hết hạn.';

comment on view ai_read.bien_dong_kho is
  'Mỗi dòng là một dòng sổ kho (nhập, bán, trả, kiểm kê, huỷ hàng). Xuất kho do bán có so_luong_thay_doi âm.';
comment on column ai_read.bien_dong_kho.ngay is 'Ngày nghiệp vụ của dòng sổ kho.';
comment on column ai_read.bien_dong_kho.san_pham_id is 'Khoá sản phẩm (ẩn khỏi bảng, dùng để mở sản phẩm).';
comment on column ai_read.bien_dong_kho.ten_san_pham is 'Tên sản phẩm.';
comment on column ai_read.bien_dong_kho.loai is 'Loại biến động: OPENING, RECEIPT (nhập), SALE (bán), SALE_REVERSAL, RETURN_IN (khách trả), COUNT_GAIN, COUNT_LOSS, WRITE_OFF.';
comment on column ai_read.bien_dong_kho.so_luong_thay_doi is 'Số lượng thay đổi, có dấu (nhập dương, xuất âm).';

comment on view ai_read.san_pham is
  'Mỗi dòng là một sản phẩm chưa bị xoá của cửa hàng (kể cả ngừng kinh doanh). Dùng để đếm hoặc tra danh mục.';
comment on column ai_read.san_pham.san_pham_id is 'Khoá sản phẩm (ẩn khỏi bảng, dùng để mở sản phẩm).';
comment on column ai_read.san_pham.ma_san_pham is 'Mã sản phẩm (SKU).';
comment on column ai_read.san_pham.ten_san_pham is 'Tên sản phẩm.';
comment on column ai_read.san_pham.ma_vach is 'Mã vạch.';
comment on column ai_read.san_pham.trang_thai is 'active = đang kinh doanh; inactive = ngừng kinh doanh.';
comment on column ai_read.san_pham.theo_doi_lo is 'true nếu sản phẩm theo dõi theo lô / hạn dùng.';

comment on view ai_read.khach_hang is
  'Mỗi dòng là một khách hàng đã lưu của cửa hàng. Không có số điện thoại, email, địa chỉ.';
comment on column ai_read.khach_hang.khach_id is 'Khoá khách (ẩn khỏi bảng, dùng để mở khách).';
comment on column ai_read.khach_hang.ten_khach is 'Tên khách.';
comment on column ai_read.khach_hang.trang_thai is 'active = đang giao dịch; inactive = ngừng.';
comment on column ai_read.khach_hang.ngay_tao is 'Ngày tạo khách (giờ Việt Nam).';

-- 5. Quyền -------------------------------------------------------------------
revoke all on all tables in schema ai_read from public, anon, authenticated;
grant select on
  ai_read.don_ban, ai_read.ban_hang_thuan, ai_read.ton_kho,
  ai_read.bien_dong_kho, ai_read.san_pham, ai_read.khach_hang
to ai_reader;

-- 6. Danh mục view cho Gemini --------------------------------------------------
create or replace function ai.get_catalog()
returns json
language plpgsql
stable
security definer
set search_path = pg_catalog, pg_temp
as $$
declare
  v_result json;
begin
  if auth.uid() is null or not exists (
    select 1 from iam.memberships m where m.user_id = auth.uid() and m.is_active
  ) then
    perform ai._raise('PERMISSION_DENIED', 'Permission denied.');
  end if;

  select coalesce(json_agg(v.item order by v.view_name), '[]'::json)
  into v_result
  from (
    select c.relname::text as view_name,
           json_build_object(
             'view', 'ai_read.' || c.relname,
             'mo_ta', coalesce(obj_description(c.oid, 'pg_class'), ''),
             'cot', (
               select json_agg(json_build_object(
                        'ten', a.attname,
                        'kieu', format_type(a.atttypid, a.atttypmod),
                        'mo_ta', coalesce(col_description(c.oid, a.attnum), '')
                      ) order by a.attnum)
               from pg_attribute a
               where a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
             )
           ) as item
    from pg_class c
    where c.relnamespace = 'ai_read'::regnamespace
      and c.relkind = 'v'
  ) v;

  return v_result;
end;
$$;

revoke all on function ai.get_catalog() from public, anon;
grant execute on function ai.get_catalog() to authenticated;
