-- Title: ai.run_query + ai._validate_sql (read-only SQL for the AI assistant)
-- Kind: schema
-- Intent: ai_run_query
-- Context: AI-4 Task 2 (trợ lý "Hỏi Mosaic Retail" tự truy vấn); một câu SELECT trên view ai_read, giới hạn 50 dòng / 5 giây
-- Touches: _validate_sql, _begin_query, run_query
-- Safety: one-shot ; new functions only, no change to existing objects
-- Depends on: 20261122001_ai_read_views, 20261110001_inventory_core

-- 1. Kiểm tra câu SQL --------------------------------------------------------
create or replace function ai._validate_sql(p_sql text)
returns text
language plpgsql
stable
set search_path = pg_catalog, pg_temp
as $$
declare
  v_msg constant text := 'Chỉ nhận một câu SELECT trên các view ai_read.';
  v_sql text := regexp_replace(coalesce(p_sql, ''), '^\s+|\s+$', '', 'g');
  v_lc text;
  v_scan text;
  v_name text;
  v_m text[];
  v_allowed constant text[] := array[
    -- hàm cho phép
    'sum', 'count', 'avg', 'min', 'max', 'round', 'ceil', 'floor', 'abs', 'coalesce', 'nullif',
    'greatest', 'least', 'date_trunc', 'to_char', 'extract', 'date_part', 'lower', 'upper',
    'length', 'trim', 'substring', 'replace', 'concat', 'string_agg', 'array_agg', 'row_number',
    'rank', 'dense_rank', 'lag', 'lead', 'first_value', 'last_value', 'now', 'current_date',
    'make_date', 'age', 'generate_series', 'cast', 'unaccent',
    'trunc', 'sign', 'power', 'sqrt', 'mod', 'split_part', 'initcap', 'ltrim', 'rtrim', 'btrim',
    'position', 'to_date', 'bool_and', 'bool_or', 'ntile', 'percent_rank', 'date',
    -- kiểu có tham số: numeric(10,2), varchar(20)
    'numeric', 'decimal', 'varchar', 'char',
    -- từ khoá đứng trước ngoặc
    'in', 'exists', 'over', 'filter', 'values', 'as', 'and', 'or', 'not', 'on', 'using', 'from',
    'join', 'where', 'having', 'select', 'by', 'partition', 'order', 'any', 'all', 'some',
    'distinct', 'case', 'when', 'then', 'else', 'between', 'like', 'ilike', 'with', 'union',
    'intersect', 'except', 'limit', 'offset', 'interval', 'array', 'rows', 'range', 'within',
    'group', 'lateral', 'left', 'right', 'inner', 'outer', 'cross', 'full'
  ];
begin
  if v_sql = '' or char_length(v_sql) > 4000 then
    perform ai._raise('CONTEXT_INVALID', v_msg);
  end if;

  -- bỏ đúng một dấu ';' cuối
  if right(v_sql, 1) = ';' then
    v_sql := regexp_replace(left(v_sql, -1), '^\s+|\s+$', '', 'g');
  end if;
  if v_sql = '' or position(';' in v_sql) > 0 then
    perform ai._raise('CONTEXT_INVALID', v_msg);
  end if;

  -- chú thích, định danh có ngoặc kép, dollar-quote, gạch chéo ngược
  if v_sql ~ '(--|/\*|"|\$|\\)' then
    perform ai._raise('CONTEXT_INVALID', v_msg);
  end if;

  v_lc := lower(v_sql);
  if v_lc !~ '^(select|with)([^a-z0-9_]|$)' then
    perform ai._raise('CONTEXT_INVALID', v_msg);
  end if;

  -- bỏ nội dung chuỗi '...' trước khi dò từ khoá / hàm
  v_scan := regexp_replace(v_lc, '''([^'']|'''')*''', '''''', 'g');

  if v_scan ~ '\m(pg_[a-z0-9_]*|information_schema|current_setting|set_config|into|copy|insert|update|delete|drop|alter|create|truncate|grant|revoke|call|execute|do|lock|vacuum|analyze|explain|listen|notify|reset|set|show)\M'
     or v_scan ~ '\mai\.' then
    perform ai._raise('CONTEXT_INVALID', v_msg);
  end if;

  -- không gọi hàm có tiền tố schema (schema.hàm(...))
  if v_scan ~ '[a-z_]\.[a-z_][a-z0-9_]*\s*\(' then
    perform ai._raise('CONTEXT_INVALID', v_msg);
  end if;

  -- mọi `tên(` phải thuộc danh sách cho phép
  for v_m in select regexp_matches(v_scan, '([a-z_][a-z0-9_]*)\s*\(', 'g') loop
    v_name := v_m[1];
    if not (v_name = any (v_allowed)) then
      perform ai._raise('CONTEXT_INVALID', v_msg);
    end if;
  end loop;

  return v_sql;
end;
$$;

revoke all on function ai._validate_sql(text) from public, anon, authenticated;

-- 2. Kiểm quyền + kiểm câu + đặt biến phiên (cần quyền chủ hàm) -----------------
-- PostgreSQL cấm SET ROLE bên trong hàm security definer ("cannot set parameter role within
-- security-definer function"), nên tách: phần cần quyền chủ hàm ở đây (security definer),
-- còn ai.run_query chạy bằng quyền người gọi để được `set local role ai_reader`.
-- Gọi trực tiếp hàm này vô hại: chỉ đặt biến phiên của cửa hàng mà người gọi là thành viên,
-- và chỉ ai_reader đọc được view dùng các biến đó.
create or replace function ai._begin_query(p_tenant_id uuid, p_sql text)
returns text
language plpgsql
volatile
security definer
set search_path = pg_catalog, pg_temp
as $$
declare
  v_actor jsonb;
  v_sql text;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'sales.order.view');
  v_sql := ai._validate_sql(p_sql);

  perform set_config('ai.tenant_id', p_tenant_id::text, true);
  perform set_config('ai.store_id', v_actor->>'store_id', true);
  perform set_config('ai.warehouse_id', v_actor->>'warehouse_id', true);
  perform set_config('statement_timeout', '5s', true);

  return v_sql;
end;
$$;

revoke all on function ai._begin_query(uuid, text) from public, anon;
grant execute on function ai._begin_query(uuid, text) to authenticated;

-- 3. Chạy câu SQL đã kiểm tra (security invoker) ------------------------------
-- `set local role ai_reader` kiểm theo session user (postgres ở local, authenticator qua PostgREST),
-- cả hai đều được grant ai_reader ở 20261122001. Sau khi chạy, trả về đúng role trước đó.
create or replace function ai.run_query(p_tenant_id uuid, p_sql text)
returns json
language plpgsql
volatile
security invoker
set search_path = pg_catalog, pg_temp
as $$
declare
  v_prev_role text := current_user;
  v_sql text;
  v_wrapped text;
  v_plan json;
  v_cost numeric;
  v_err text;
  v_all json;
  v_n int := 0;
  v_cut boolean := false;
  v_rows json := '[]'::json;
  v_cols json := '[]'::json;
begin
  v_sql := ai._begin_query(p_tenant_id, p_sql);

  begin
    set local role ai_reader;
    perform set_config('search_path', 'ai_read, pg_catalog', true);

    v_wrapped := 'select * from (' || v_sql || ') s limit 51';

    -- Chặn câu quá nặng trước khi chạy (statement_timeout đặt giữa câu lệnh không đủ tin cậy).
    execute 'explain (format json) ' || v_wrapped into v_plan;
    v_cost := ((v_plan -> 0) -> 'Plan' ->> 'Total Cost')::numeric;

    if v_cost > 1000000 then
      v_err := 'Câu SQL quá nặng, hãy thu hẹp điều kiện lọc.';
    else
      execute 'select coalesce(json_agg(row_to_json(q)), ''[]''::json) from ('
              || v_wrapped || ') q' into v_all;
    end if;
    execute format('set local role %I', v_prev_role);
  exception
    when insufficient_privilege then
      v_err := 'Chỉ được đọc các view ai_read.';
    when query_canceled then
      v_err := 'Câu SQL chạy quá 5 giây, hãy thu hẹp điều kiện lọc.';
    when others then
      v_err := 'Câu SQL lỗi: ' || left(regexp_replace(
        sqlerrm,
        '\m(iam|auth|catalog|sales|inventory|partner|public|ai|information_schema|pg_catalog)\.[a-zA-Z0-9_]+',
        'đối tượng không được phép', 'g'), 200);
  end;

  if v_err is not null then
    raise exception using message = jsonb_build_object(
      'code', 'CONTEXT_INVALID', 'message', v_err)::text;
  end if;

  v_n := json_array_length(v_all);
  if v_n > 50 then
    v_cut := true;
  end if;
  if v_n > 0 then
    select coalesce(json_agg(t.e order by t.o), '[]'::json)
    into v_rows
    from json_array_elements(v_all) with ordinality as t(e, o)
    where t.o <= 50;

    select coalesce(json_agg(k), '[]'::json)
    into v_cols
    from json_object_keys(v_all -> 0) as k;
  end if;

  return json_build_object('cot', v_cols, 'dong', v_rows, 'bi_cat', v_cut);
end;
$$;

revoke all on function ai.run_query(uuid, text) from public, anon;
grant execute on function ai.run_query(uuid, text) to authenticated;
