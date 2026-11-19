# AI-1 — Backend trợ lý "Hỏi Mosaic Retail": thống kê bán hàng, nhật ký, Edge Function `ai-assistant`

> Tích hợp AI · plan **AI-1** của [PLAN.md](../../PLAN.md) mục "Tích hợp AI" (bảng Plan)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-16) | Làm ✅ 2026-11-16 | Review ✅ R4 2026-11-16
> Thiết kế: duyệt trong chat 2026-11-16 (chọn **cách A**: Edge Function gọi thẳng từng RPC; **công nợ hoãn** sang sau Theme 6; phần 1 database + phần 2 Edge Function → "oce"). Yêu cầu: [AI-0](AI-0-yeu-cau.md) — đọc trước, plan này không nhắc lại.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Một Edge Function `ai-assistant` nhận câu hỏi tiếng Việt, để Gemini chọn công cụ, gọi các RPC chỉ đọc bằng JWT người hỏi, trả về câu trả lời + bảng số liệu đúng từng đồng; kèm RPC thống kê bán hàng mới, nhật ký và giới hạn 100 câu / cửa hàng / ngày.

**Architecture:** Hai migration mới: `sales.get_sales_stats` (doanh thu khớp báo cáo lãi gộp G5-7) và schema `ai` (bảng nhật ký + `start_question` / `finish_question`). Edge Function Deno chia lớp: `model/` (khuôn chung + Gemini thật + Gemini giả), `tools/` (mỗi công cụ một tệp: khai báo cho Gemini + gọi RPC + dựng bảng), `period.ts` (đổi kỳ ra ngày), `orchestrator.ts` (vòng gọi công cụ ≤ 3 lần, phân loại trạng thái), `index.ts` chỉ nối. Công cụ dự báo (`du_bao_ban_hang`) do AI-3 cắm vào registry; màn hình do AI-2.

**Tech Stack:** PostgreSQL / Supabase (plpgsql), Supabase Edge Functions (Deno 2, `npm:@supabase/supabase-js@2`, `jsr:@std/assert@1`), Gemini API REST `generateContent` (function calling).

**Spec:** [AI-0-yeu-cau.md](AI-0-yeu-cau.md) mục 4–7, 9–11 + mục "Thiết kế AI-1" dưới đây.

## Thiết kế AI-1 (đã duyệt trong chat)

- **Cách A:** mỗi công cụ là một module TypeScript gọi RPC có sẵn / RPC mới bằng client mang JWT người hỏi. Không có RPC "tổng đài" trong DB.
- **Công cụ trong AI-1:** `thong_ke_ban_hang`, `tinh_hinh_ton_kho`, `bien_dong_kho`, `lai_gop`, `tim_kiem`, cộng công cụ đặc biệt `bao_khong_ho_tro` (Gemini gọi khi câu ngoài phạm vi / chưa hỗ trợ / đòi sửa xoá → nhật ký ghi đúng loại). `du_bao_ban_hang`: AI-3. `cong_no_phai_thu`: **hoãn** (sau Theme 6).
- **Không tính ở Gemini:** đổi kỳ → ngày ở `period.ts`; số trong bảng lấy nguyên từ RPC; Gemini chỉ viết 1–3 câu.
- **Lỗi:** `PERMISSION_DENIED` → dừng ngay, câu cố định, không đưa số nào cho Gemini; Gemini 429 → `ban`, không trừ lượt; quá 30 giây → `loi`.
- **Model:** mặc định `gemini-3.1-flash-lite` (đổi sau R3: `gemini-2.5-flash` không còn cho khoá mới), đổi bằng env `GEMINI_MODEL` (kiểm lại tên model + hạn mức trên Google AI Studio lúc làm). Khoá `GEMINI_API_KEY` chỉ trong secrets.
- **Test:** pgTAP-kiểu-dự-án (`supabase/tests/*.sql` + `tools/db_check.sh`) cho SQL; `deno test` với Gemini giả + RPC giả cho Edge Function; script chạy bộ câu thử (chạy đủ sau AI-3); thử Gemini thật: **người dùng tự chạy**.

## Global Constraints

- Migration: header theo khuôn `20261119001_inventory_reports.sql` (Title / Kind / Intent / Context / Touches / Safety / Depends on); cập nhật `supabase/migrations/REGISTRY.yaml` (thêm nhóm `sales:` → `get_sales_stats`, nhóm mới `ai:`). **Không** sửa migration đã có.
- Hàm mới: `security definer`, `set search_path` liệt kê đủ schema dùng, `stable` cho hàm đọc. RPC: `grant execute … to authenticated`; hàm `_`: `revoke all … from public, anon, authenticated`.
- Lỗi SQL: `raise exception using message = jsonb_build_object('code', <MÃ>, 'message', <câu>)::text` (như `inventory._raise`). Mã dùng: `PERMISSION_DENIED`, `CONTEXT_INVALID`, `QUOTA_EXCEEDED`, `NOT_FOUND`.
- Ngày: `date`, giờ VN: `(x at time zone 'Asia/Ho_Chi_Minh')::date`. Tiền `bigint` đồng; số lượng Sales `*_micros / 1000000.0`.
- Khoảng ngày tối đa **366 ngày** (cả SQL lẫn `period.ts`).
- Chạy SQL: `tools/db_check.sh` (reset + `plpgsql_check` + mọi test) ✅ trước khi báo xong task có SQL; một tệp: `tools/db_check.sh --no-reset <tên>`. Lệnh DB chỉ chạy **local**; đụng Supabase Dev (`--linked`, dashboard) **hỏi người dùng**.
- Deno: `deno test --allow-env --allow-net=127.0.0.1 supabase/functions/ai-assistant/` xanh; `deno check supabase/functions/ai-assistant/index.ts` sạch; `deno fmt --check` / `deno lint` sạch cho thư mục mới.
- Mọi chữ người dùng thấy: **nguyên văn** AI-0 mục 6, 8 (bảng "Câu cố định" ở Task 5). Tên công cụ, tham số, giá trị enum: **nguyên văn** AI-0 mục 4.
- Không gửi cho Gemini: số điện thoại, email, địa chỉ, mã số thuế (AI-0 mục 11).
- Trước khi sửa symbol đã có (ở plan này chỉ `supabase/config.toml`, không có symbol code): nếu phát sinh sửa hàm / lớp có sẵn thì chạy `impact({target, direction: "upstream"})`, HIGH / CRITICAL ⇒ dừng, báo người dùng. Task cuối: `detect_changes({scope: "compare", base_ref: "main"})`.
- `AGENTS.md`, `CLAUDE.md`: không `git add`. Ghi mục "Kết quả" cuối file sau mỗi task. Làm từng task một, mỗi task một commit.

## Review Focus

1. **Gemini 2.5 trả `thoughtSignature` trong phần `functionCall`** — gửi lượt sau mà bỏ mất thì API báo lỗi / mất mạch. Phải gửi lại **nguyên văn** `content` của model. → test `gemini_client_test.ts` "giữ nguyên parts của model khi gửi lượt sau" (Task 4).
2. **Trả lời không gọi công cụ nhưng có số** (Gemini bịa "hôm nay bán 2 triệu" mà không tra) — vi phạm "không bịa số". → orchestrator: câu chỉ-chữ có chữ số thì đổi sang `chua_ho_tro` + câu cố định; test "câu trả lời không qua công cụ mà có số bị chặn" (Task 6).
3. **Tham số Gemini điền sai** (enum lạ, ngày `2026-13-40`, `tu_ngay` > `den_ngay`, khoảng > 366 ngày, `san_pham_id` không phải uuid) — không được gọi RPC với rác, không văng 500. → công cụ trả `{ loi: 'tham_so_sai', chi_tiet }` cho Gemini sửa (tính vào 3 lần); test trong `tools/*_test.ts` + `period_test.ts` (Task 3, 5).
4. **Hai yêu cầu cùng lúc khi còn đúng 1 lượt** — cả hai lọt qua giới hạn 100. → `ai.start_question` khoá theo cửa hàng (`pg_advisory_xact_lock`); test a2b (Task 2).
5. **Lịch sử hội thoại do app gửi lên có thể bị sửa** để nhét lượt "model" giả hoặc `functionCall` / `functionResponse` bịa (ví dụ giả kết quả lãi gộp cho nhân viên). → Edge Function chỉ nhận `history` dạng chữ thuần, cắt 6 lượt, mỗi lượt ≤ 2000 ký tự, không nhận `functionCall` / `functionResponse` từ app; test "history chứa trường lạ bị bỏ" (Task 7).

---

## Cấu trúc tệp

```
supabase/migrations/20261120001_sales_stats.sql          (Task 1)
supabase/migrations/20261120002_ai_assistant_log.sql     (Task 2)
supabase/tests/sales_stats.sql                           (Task 1)
supabase/tests/ai_assistant_log.sql                      (Task 2)
supabase/config.toml                                     (Task 2: schemas += "ai"; Task 7: [functions.ai-assistant])
supabase/functions/ai-assistant/
  types.ts                       kiểu dùng chung (Task 3)
  period.ts      period_test.ts  đổi kỳ → ngày (Task 3)
  prompt.ts      prompt_test.ts  lời dặn hệ thống (Task 3)
  model/model_client.ts          khuôn chung + lỗi (Task 3)
  model/fake_model_client.ts     Gemini giả (Task 3)
  model/gemini_client.ts  model/gemini_client_test.ts   (Task 4)
  tools/tool.ts                  khuôn công cụ + RpcCaller + RpcError (Task 5)
  tools/redact.ts                bỏ thông tin cá nhân (Task 5)
  tools/sales_stats.ts  tools/stock.ts  tools/gross_profit.ts  tools/search.ts  tools/unsupported.ts
  tools/registry.ts              danh sách công cụ (AI-3 thêm du_bao_ban_hang ở đây)
  tools/*_test.ts
  messages.ts                    câu cố định (Task 5)
  orchestrator.ts  orchestrator_test.ts   (Task 6)
  request.ts  request_test.ts    đọc / kiểm body (Task 7)
  index.ts                       nối (Task 7)
scripts/ai/eval_questions.json   bộ câu thử (Task 7)
scripts/ai/run_eval.ts           chạy bộ câu thử (Task 7)
```

---

### Task 1: RPC `sales.get_sales_stats`

**Files:**
- Create: `supabase/migrations/20261120001_sales_stats.sql`
- Create: `supabase/tests/sales_stats.sql`
- Modify: `supabase/migrations/REGISTRY.yaml`

**Interfaces:**
- Produces:
  ```sql
  sales.get_sales_stats(
    p_tenant_id uuid,
    p_metric    text,   -- 'revenue' | 'order_count' | 'quantity' | 'avg_order_value'
    p_group_by  text,   -- 'none' | 'day' | 'week' | 'month' | 'product' | 'customer' | 'seller'
    p_from date, p_to date,
    p_top_n int default 10   -- 1..20, chỉ áp cho product / customer / seller
  ) returns jsonb
  -- { "from", "to", "metric", "group_by",
  --   "total": number,                       -- chỉ số trên cả kỳ (không nhóm)
  --   "rows": [ { "key": text, "label": text, "value": number } ] }   -- 'none' ⇒ rows = []
  ```
  `key`: ngày `YYYY-MM-DD` (day), thứ Hai đầu tuần `YYYY-MM-DD` (week), `YYYY-MM` (month), uuid (product / customer / seller; khách lẻ `key = 'walk_in'`). `label`: tên sản phẩm (`product_snapshot`/catalog), tên khách (partner, khách lẻ = `'Khách lẻ'`), tên nhân viên (hồ sơ IAM — lấy như `iam.list_tenant_members`), ngày/tuần/tháng = `key`. Sắp xếp: nhóm thời gian tăng dần theo `key` và **không** cắt top; nhóm khác giảm dần theo `value`, cắt `p_top_n`.

**Định nghĩa chỉ số (bắt buộc khớp G5-7):**
- `revenue` = doanh thu thuần **y hệt** `inventory.get_gross_profit_report(…, 'PRODUCT')` → `totals.net_revenue`: + `line_total_minor` đơn hoàn tất trong kỳ (theo `completed_at`, kể cả đơn bị huỷ sau) + dòng `exchange` của đổi trả hoàn tất trong kỳ − dòng `returned` − đơn huỷ trong kỳ (theo `cancelled_at`). Chép đúng các nhánh `union all` ở `20261119001_inventory_reports.sql` (khối `-- PRODUCT`, phần doanh thu / giảm trừ). Nhóm customer / seller lấy từ **đơn gốc** của dòng.
- `order_count` = số đơn `lifecycle_status = 'completed'` có `completed_at` trong kỳ (đơn đã huỷ không tính).
- `quantity` = Σ `base_quantity_micros / 1e6` đơn hoàn tất trong kỳ + đổi − trả − huỷ (cùng cách ghi ngày như revenue).
- `avg_order_value` = `round(revenue / order_count)` của từng nhóm (0 đơn ⇒ `null`).
- Phạm vi: `tenant_id = p_tenant_id` **và** `store_id` = cửa hàng lấy từ `inventory._assert_actor(p_tenant_id, 'sales.order.view')->>'store_id'` (cùng cách G5-7 lọc cửa hàng; `_assert_actor` cũng kiểm thành viên + quyền).

- [ ] **Step 1: Viết test đỏ** `supabase/tests/sales_stats.sql` theo khuôn `supabase/tests/inventory_reports.sql` (chép các helper `pg_temp.expect_err`, `rep_line`, `rep_pay`, `rep_finalize` và phần dựng tenant / kho / sản phẩm). Các ca:
  - `s1_revenue_matches_gross_profit`: 3 đơn trong kỳ, 1 đơn bị huỷ trong kỳ, 1 đổi trả (trả 1, đổi 1) → `total` (`revenue`, `none`) = `(get_gross_profit_report(t, from, to, 'PRODUCT')->'totals'->>'net_revenue')::bigint`.
  - `s2_order_count_excludes_cancelled`: 3 hoàn tất + 1 huỷ ⇒ `total = 3`.
  - `s3_top_products`: `revenue` / `product` / `top_n = 2` ⇒ đúng 2 dòng, giảm dần, `label` = tên sản phẩm.
  - `s4_customer_walk_in`: 1 đơn có khách, 1 đơn không khách ⇒ có dòng `key = 'walk_in'`, `label = 'Khách lẻ'`.
  - `s5_day_keys`: `order_count` / `day` qua 3 ngày ⇒ `key` tăng dần `YYYY-MM-DD`, ngày không có đơn **không** có dòng.
  - `s6_avg_order_value`: 2 đơn 100 000 + 50 000 ⇒ `total = 75000`.
  - `s7_bad_metric` (`'profit'`) và `s7b_bad_group` ⇒ `CONTEXT_INVALID`; `s8_bad_range` (`from > to`, `to - from > 365`) ⇒ `CONTEXT_INVALID`.
  - `s9_non_member` ⇒ `PERMISSION_DENIED`; `s10_other_tenant_excluded`: đơn của tenant khác không vào `total`.
- [ ] **Step 2: Chạy, thấy đỏ** — `tools/db_check.sh --no-reset sales_stats` ⇒ lỗi "function sales.get_sales_stats … does not exist".
- [ ] **Step 3: Viết migration** `20261120001_sales_stats.sql` với chữ ký ở Interfaces; kiểm `p_metric`, `p_group_by`, khoảng ngày (dùng lại `inventory._report_range_check` rồi tự kiểm `p_to - p_from <= 365`), `p_top_n` kẹp về 1..20. `set search_path = sales, inventory, iam, catalog, partner, pg_temp`. Cập nhật REGISTRY.
- [ ] **Step 4: Chạy, thấy xanh** — `tools/db_check.sh` (đủ 3 bước) ✅.
- [ ] **Step 5: Commit** — `feat(ai): sales.get_sales_stats khớp doanh thu thuần G5-7`.

### Task 2: Schema `ai` — nhật ký + đếm lượt

**Files:**
- Create: `supabase/migrations/20261120002_ai_assistant_log.sql`
- Create: `supabase/tests/ai_assistant_log.sql`
- Modify: `supabase/config.toml` dòng `schemas = [...]` (thêm `"ai"`), `supabase/migrations/REGISTRY.yaml`

**Interfaces:**
- Produces:
  ```sql
  ai.assistant_logs (
    id uuid primary key default gen_random_uuid(),
    tenant_id uuid not null, user_id uuid not null,
    asked_at timestamptz not null default now(),
    business_date date not null,               -- ngày VN lúc hỏi
    question text not null,                    -- 1..500 ký tự
    status text not null default 'dang_xu_ly', -- dang_xu_ly | ok | tro_chuyen | ngoai_pham_vi | chua_ho_tro
                                               -- | tu_choi | khong_quyen | loi | het_luot | ban
    tool_calls jsonb not null default '[]',    -- [{ "name", "args", "ok": bool }]
    input_tokens int, output_tokens int, latency_ms int,
    finished_at timestamptz
  )  -- index (tenant_id, business_date); RLS bật, không policy; revoke all from anon, authenticated

  ai._daily_limit() returns int   -- 100

  ai.start_question(p_tenant_id uuid, p_question text) returns jsonb
  -- { "log_id": uuid, "remaining": int, "is_owner": bool, "tenant_name": text }

  ai.finish_question(p_log_id uuid, p_status text, p_tool_calls jsonb,
                     p_input_tokens int, p_output_tokens int, p_latency_ms int) returns void
  ```
- `start_question`: `auth.uid()` null hoặc `iam.has_permission(p_tenant_id, 'sales.order.view')` không true ⇒ `PERMISSION_DENIED`; `p_question` trim rỗng / > 500 ký tự ⇒ `CONTEXT_INVALID`; `pg_advisory_xact_lock(hashtext('ai.quota:' || p_tenant_id))`; đếm dòng cùng `tenant_id` + `business_date` hôm nay **với `status <> 'ban'`**; ≥ `_daily_limit()` ⇒ `QUOTA_EXCEEDED`; ngược lại chèn dòng, `remaining = limit − (đếm + 1)`. `is_owner` từ `iam.memberships.is_owner`; `tenant_name` = tên tổ chức (cột tên mà `iam.get_tenant_context` trả).
- `finish_question`: cập nhật đúng dòng `id = p_log_id and user_id = auth.uid() and status = 'dang_xu_ly'`, không có ⇒ `NOT_FOUND`; `p_status` ngoài danh sách (trừ `dang_xu_ly`) ⇒ `CONTEXT_INVALID`; ghi `finished_at = now()`.

- [ ] **Step 1: Viết test đỏ** `supabase/tests/ai_assistant_log.sql`:
  - `a1_start_ok`: lần đầu ⇒ `remaining = 99`, dòng `status = 'dang_xu_ly'`, `is_owner` đúng cho chủ / nhân viên.
  - `a2_quota`: chèn sẵn 100 dòng hôm nay (`status 'ok'`) ⇒ `QUOTA_EXCEEDED`; `a2b_ban_not_counted`: 99 `ok` + 5 `ban` ⇒ vẫn bắt đầu được, `remaining = 0`.
  - `a3_yesterday_not_counted`: 100 dòng hôm qua ⇒ bắt đầu được.
  - `a4_non_member` ⇒ `PERMISSION_DENIED`; `a5_question_too_long` (501 ký tự) và rỗng ⇒ `CONTEXT_INVALID`.
  - `a6_finish_other_user` ⇒ `NOT_FOUND`; `a7_finish_twice` ⇒ lần 2 `NOT_FOUND`; `a8_finish_bad_status` ⇒ `CONTEXT_INVALID`.
  - `a9_no_direct_access`: `set role authenticated` rồi `select … from ai.assistant_logs` ⇒ lỗi quyền.
- [ ] **Step 2: Chạy, thấy đỏ** — `tools/db_check.sh --no-reset ai_assistant_log`.
- [ ] **Step 3: Viết migration** theo Interfaces; `set search_path = ai, iam, pg_temp`; thêm `"ai"` vào `schemas` của `supabase/config.toml` (không cần `extra_search_path`).
- [ ] **Step 4: Chạy, thấy xanh** — `tools/db_check.sh` ✅. Ghi vào Kết quả: **người dùng tự thêm `ai` vào "Exposed schemas" của Supabase Dev** (Dashboard → API settings) trước khi deploy.
- [ ] **Step 5: Commit** — `feat(ai): schema ai — nhật ký và giới hạn 100 câu/ngày`.

### Task 3: Nền Edge Function — kiểu, đổi kỳ, lời dặn, khuôn model + Gemini giả

**Files:**
- Create: `supabase/functions/ai-assistant/{types.ts, period.ts, period_test.ts, prompt.ts, prompt_test.ts, model/model_client.ts, model/fake_model_client.ts}`

**Interfaces — Produces:**
```ts
// types.ts
export type Status = 'ok' | 'tro_chuyen' | 'ngoai_pham_vi' | 'chua_ho_tro' | 'tu_choi'
  | 'khong_quyen' | 'loi' | 'het_luot' | 'ban'
export type Turn = { role: 'user' | 'assistant'; text: string }
export type ColumnKind = 'chu' | 'tien' | 'so' | 'ngay' | 'phan_tram'
export type OpenTarget = { loai: 'san_pham' | 'khach_hang' | 'don_ban'; id: string }
export type TableBlock = {
  loai: 'bang'; tieu_de: string
  cot: { khoa: string; ten: string; kieu: ColumnKind }[]
  dong: { o: Record<string, string | number | null>; mo?: OpenTarget }[]
}
export type AssistantReply = {
  trang_thai: Status; cau_tra_loi: string; khoi: TableBlock[]
  luot_con_lai: number | null; cong_cu: string[]   // tên công cụ đã gọi, cho script chạy câu thử
}

// period.ts
export type Ky = 'hom_nay' | 'hom_qua' | 'tuan_nay' | 'tuan_truoc' | 'thang_nay' | 'thang_truoc' | 'tuy_chon'
export type Range = { from: string; to: string }          // 'YYYY-MM-DD'
export function todayInVietnam(now: Date): string
export function resolvePeriod(input: { ky?: unknown; tu_ngay?: unknown; den_ngay?: unknown }, today: string):
  { ok: true; range: Range } | { ok: false; chi_tiet: string }
export function previousPeriod(ky: Ky, range: Range): Range

// prompt.ts
export function buildSystemPrompt(i: { today: string; isOwner: boolean; tenantName: string }): string

// model/model_client.ts
export type ToolDeclaration = { name: string; description: string; parameters: Record<string, unknown> } // JSON Schema (OpenAPI subset)
export type ToolCall = { name: string; args: Record<string, unknown> }
export type ModelTurn =
  | { role: 'user'; text: string }
  | { role: 'model'; raw: unknown }                                // nguyên văn content model trả (giữ thoughtSignature)
  | { role: 'tool_results'; results: { name: string; response: unknown }[] }
export type Usage = { inputTokens: number; outputTokens: number }
export type ModelResult =
  | { kind: 'text'; text: string; raw: unknown; usage: Usage }
  | { kind: 'tool_calls'; calls: ToolCall[]; raw: unknown; usage: Usage }
export interface ModelClient {
  generate(r: { system: string; turns: ModelTurn[]; tools: ToolDeclaration[]; signal?: AbortSignal }): Promise<ModelResult>
}
export class ModelBusyError extends Error {}   // 429 / hết hạn mức
export class ModelError extends Error {}       // mọi lỗi khác

// model/fake_model_client.ts
export class FakeModelClient implements ModelClient {
  constructor(script: (ModelResult | Error)[])   // trả lần lượt; hết kịch bản ⇒ throw
  readonly requests: { system: string; turns: ModelTurn[]; tools: ToolDeclaration[] }[]
}
```

Quy tắc `resolvePeriod` (giờ VN, tuần bắt đầu thứ Hai): thiếu `ky` ⇒ `hom_nay`; `tuy_chon` cần `tu_ngay`, `den_ngay` dạng `YYYY-MM-DD` hợp lệ, `tu_ngay ≤ den_ngay`, độ dài ≤ 366 ngày; `ky` lạ ⇒ `ok: false`. `tuan_nay` = thứ Hai tuần này → hôm nay; `thang_nay` = ngày 1 → hôm nay; `*_truoc` = trọn tuần / tháng trước. `previousPeriod`: `thang_nay` ⇒ cùng số ngày đầu tháng trước (kẹp cuối tháng); `thang_truoc` ⇒ trọn tháng trước nữa; còn lại ⇒ lùi đúng độ dài khoảng.

`buildSystemPrompt`: chép **nguyên văn** khối lời dặn AI-0 mục 7, thay `{ngay_hom_nay}` (dạng `dd/MM/yyyy`), `{vai_tro}` (`chủ cửa hàng` / `nhân viên`), `{ten_cua_hang}`; thêm một dòng cuối: `Khi câu hỏi ngoài phạm vi, chưa hỗ trợ, hoặc đòi tạo / sửa / xoá: gọi công cụ bao_khong_ho_tro với loại phù hợp.`

- [ ] **Step 1: Test đỏ** `period_test.ts`: today `2026-11-16` (thứ Hai) ⇒ `tuan_nay = 16..16`, `tuan_truoc = 09..15`; today `2026-11-18` ⇒ `tuan_nay = 16..18`; `thang_truoc` từ `2026-01-10` ⇒ `2025-12-01..2025-12-31`; `previousPeriod('thang_nay', 2026-03-01..2026-03-31)` ⇒ `2026-02-01..2026-02-28`; `previousPeriod('tuan_nay', 2026-11-16..2026-11-18)` ⇒ `2026-11-13..2026-11-15` (lùi đúng độ dài); `tuy_chon` thiếu ngày / `2026-13-40` / `tu > den` / 367 ngày ⇒ `ok: false`; `todayInVietnam(new Date('2026-11-15T17:30:00Z'))` ⇒ `'2026-11-16'`. `prompt_test.ts`: chứa `16/11/2026`, `nhân viên`, tên cửa hàng, dòng `bao_khong_ho_tro`.
- [ ] **Step 2: Chạy, thấy đỏ** — `deno test supabase/functions/ai-assistant/period_test.ts supabase/functions/ai-assistant/prompt_test.ts`.
- [ ] **Step 3: Viết** các tệp ở Interfaces (không thư viện ngày ngoài; tính bằng chuỗi `YYYY-MM-DD` + `Date.UTC`).
- [ ] **Step 4: Chạy, thấy xanh** + `deno check`, `deno lint`.
- [ ] **Step 5: Commit** — `feat(ai): nền Edge Function — đổi kỳ, lời dặn, khuôn model`.

### Task 4: `GeminiClient`

**Files:** Create `supabase/functions/ai-assistant/model/gemini_client.ts`, `model/gemini_client_test.ts`

**Interfaces:**
- Consumes: `ModelClient`, `ModelTurn`, `ModelResult`, `ModelBusyError`, `ModelError` (Task 3).
- Produces: `export class GeminiClient implements ModelClient { constructor(o: { apiKey: string; model: string; fetch?: typeof fetch }) }`

Gọi `POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`, header `x-goog-api-key`. Body: `systemInstruction.parts[0].text = system`; `contents` từ `turns` (`user` ⇒ `{role:'user', parts:[{text}]}`; `model` ⇒ **đúng `raw`** (đối tượng `content` model đã trả); `tool_results` ⇒ `{role:'user', parts:[{functionResponse:{name, response}}…]}`); `tools: [{ functionDeclarations }]` (bỏ hẳn khoá `tools` khi mảng rỗng); `generationConfig: { temperature: 0.2 }`. Kết quả: `candidates[0].content` có part `functionCall` ⇒ `tool_calls` (mọi part functionCall), ngược lại nối các part `text`; `usage` từ `usageMetadata.promptTokenCount` / `candidatesTokenCount` (thiếu ⇒ 0). HTTP 429 hoặc `status: RESOURCE_EXHAUSTED` ⇒ `ModelBusyError`; HTTP khác 2xx, không có candidate, `finishReason` `SAFETY` ⇒ `ModelError`. Kiểm lại định dạng với tài liệu Gemini API hiện hành lúc làm; lệch thì sửa theo tài liệu và ghi vào Kết quả.

- [ ] **Step 1: Test đỏ** (fetch giả ghi lại request): `sends_system_tools_and_key` (URL có tên model, header khoá, `functionDeclarations` đúng); `omits_tools_when_empty`; `parses_function_calls` (2 functionCall ⇒ 2 calls, `raw` = content); **`replays_model_raw_verbatim`** (lượt `model` có part `{functionCall, thoughtSignature:'abc'}` ⇒ request sau chứa nguyên part đó); `maps_tool_results_to_function_response`; `429_is_busy`; `500_is_model_error`; `safety_is_model_error`; `usage_defaults_zero`.
- [ ] **Step 2: Chạy, thấy đỏ.**
- [ ] **Step 3: Viết `GeminiClient`.**
- [ ] **Step 4: Chạy, thấy xanh.**
- [ ] **Step 5: Commit** — `feat(ai): GeminiClient (function calling, giữ thoughtSignature)`.

### Task 5: Công cụ + câu cố định

**Files:**
- Create: `tools/{tool.ts, redact.ts, sales_stats.ts, stock.ts, gross_profit.ts, search.ts, unsupported.ts, registry.ts}`, `messages.ts`, test `tools/{redact,sales_stats,stock,gross_profit,search,unsupported}_test.ts`

**Interfaces — Produces:**
```ts
// tools/tool.ts
export class RpcError extends Error { constructor(readonly code: string, message: string) }  // code từ JSON trong message lỗi PostgREST; không đọc được ⇒ 'UNKNOWN'
export type RpcCaller = (schema: string, fn: string, args: Record<string, unknown>) => Promise<unknown>
export type ToolContext = { tenantId: string; actorId: string; today: string; rpc: RpcCaller }
export type ToolOutcome =
  | { kind: 'data'; forModel: unknown; block?: TableBlock }
  | { kind: 'bad_args'; chi_tiet: string }                          // gửi lại Gemini { loi: 'tham_so_sai', chi_tiet }
  | { kind: 'unsupported'; status: 'ngoai_pham_vi' | 'chua_ho_tro' | 'tu_choi' }
export interface Tool { declaration: ToolDeclaration; run(args: Record<string, unknown>, ctx: ToolContext): Promise<ToolOutcome> }
// RpcError 'PERMISSION_DENIED' được ném tiếp (orchestrator bắt), không gói thành ToolOutcome.

// tools/redact.ts
export function redactPersonal(value: unknown): unknown   // bỏ đệ quy mọi khoá khớp /phone|email|address|tax|cccd|identity/i

// tools/registry.ts
export function buildTools(): Tool[]   // thứ tự: thong_ke_ban_hang, tinh_hinh_ton_kho, bien_dong_kho, lai_gop, tim_kiem, bao_khong_ho_tro
export function findTool(tools: Tool[], name: string): Tool | undefined

// messages.ts — câu cố định (nguyên văn AI-0 mục 6, 8)
export const MESSAGES: Record<'ngoai_pham_vi' | 'chua_ho_tro' | 'tu_choi' | 'khong_quyen' | 'het_luot'
  | 'ban' | 'cham' | 'loi' | 'qua_phuc_tap', string>
```

**Câu cố định (`messages.ts`):**

| Khoá | Chữ |
|---|---|
| `ngoai_pham_vi` | Mình chỉ giúp xem số liệu cửa hàng thôi. Bạn có thể hỏi như: "Hôm nay bán được bao nhiêu?", "Hàng nào sắp hết?" |
| `chua_ho_tro` | Mình chưa hỗ trợ câu này. |
| `tu_choi` | Mình chỉ xem được, không sửa hay xoá. |
| `khong_quyen` | Bạn không có quyền xem số liệu này. Hãy nhờ chủ cửa hàng. |
| `het_luot` | Cửa hàng đã dùng hết 100 câu hỏi hôm nay. Mai bạn quay lại nhé. |
| `ban` | Trợ lý đang bận, thử lại sau ít phút. |
| `cham` | Trợ lý phản hồi chậm, bạn thử lại nhé. |
| `loi` | Có lỗi khi trả lời. Bạn thử lại nhé. |
| `qua_phuc_tap` | Câu này phức tạp quá, bạn hỏi tách ra nhé. |

**Từng công cụ** (tham số + enum nguyên văn AI-0 mục 4; mô tả cho Gemini viết tiếng Việt, 1–2 câu, nói rõ khi nào dùng; mọi tham số thời gian qua `resolvePeriod`):

| Công cụ | Gọi | `forModel` (đã `redactPersonal`) | `block` |
|---|---|---|---|
| `thong_ke_ban_hang` | `sales.get_sales_stats` (ánh xạ `chi_so`: doanh_thu→revenue, so_don→order_count, so_luong_ban→quantity, gia_tri_tb_don→avg_order_value; `nhom_theo`: khong→none, ngay→day, tuan→week, thang→month, san_pham→product, khach_hang→customer, nhan_vien→seller). `so_sanh_ky_truoc` ⇒ gọi thêm lần 2 với `previousPeriod` | `{ ky: {from,to}, tong, dong:[{nhan, gia_tri}] , ky_truoc?: {from,to,tong} }` | nhóm ≠ khong: bảng `Nhóm \| <tên chỉ số>`; `mo` cho product / customer (trừ `walk_in`) |
| `tinh_hinh_ton_kho` | `inventory.list_stock_overview(p_tenant_id)`, lọc ở TS: `sap_het` = có `reorder_threshold` và `0 < available ≤ reorder_threshold`; `het_hang` = `available ≤ 0`; `can_han` = `has_near_expiry` hoặc `has_expired`; `tu_khoa` so khớp tên / mã không dấu; cắt `gioi_han` (≤ 20) | `{ so_mat_hang, dong:[{ten, ma, ton, dvt, nguong?}] }` | `Sản phẩm \| Tồn \| ĐVT`; `mo` san_pham |
| `bien_dong_kho` | cần `san_pham_id` uuid (không phải uuid ⇒ `bad_args` "gọi tim_kiem trước"); `inventory.get_stock_card(p_tenant_id, p_product_id, p_from, p_to)` | tóm tắt: tồn đầu, tổng nhập, tổng xuất, tồn cuối, số dòng | tối đa 20 dòng biến động gần nhất |
| `lai_gop` | `inventory.get_gross_profit_report(p_tenant_id, p_from, p_to, p_mode)` (`che_do` san_pham→PRODUCT, don→ORDER) | `totals` + top `top_n` dòng theo `gross_profit_vnd` | `Sản phẩm \| Doanh thu thuần \| Lãi gộp \| %` |
| `tim_kiem` | `san_pham` → `catalog.search_products(p_tenant_id, p_keyword, p_limit ⇒ gioi_han)`; `khach_hang` → `partner.search_partners(p_tenant_id, p_query, p_role ⇒ 'customer', p_limit)`; `don_ban` → `sales.search_sales_orders(query_id ⇒ crypto.randomUUID(), tenant_id, actor_id ⇒ ctx.actorId, search_text, page_size ⇒ gioi_han)`; `gioi_han` ≤ 5 | id + tên / mã + (đơn: tổng tiền, ngày, tên khách) | danh sách, `mo` theo loại |
| `bao_khong_ho_tro` | không gọi RPC; tham số `loai`: `ngoai_pham_vi` \| `chua_ho_tro` \| `tu_choi` | — | — ⇒ `{kind:'unsupported'}` |

Tên khoá kết quả của RPC có sẵn: đọc trong migration gốc (`20261112001_inventory_stock_view.sql`, `20261119001_inventory_reports.sql`, partner / catalog / sales search) — không đoán.

- [ ] **Step 1: Test đỏ** với `RpcCaller` giả (ghi lại lời gọi, trả JSON mẫu):
  - `sales_stats`: ánh xạ enum đúng; `so_sanh_ky_truoc` ⇒ đúng 2 lời gọi, lần 2 là `previousPeriod`; `chi_so: 'loi_nhuan'` ⇒ `bad_args`, **không** gọi RPC; `ky: 'tuy_chon'` thiếu ngày ⇒ `bad_args`; `walk_in` không có `mo`.
  - `stock`: dữ liệu mẫu 4 sản phẩm ⇒ `sap_het` / `het_hang` / `can_han` ra đúng tập; sản phẩm không có ngưỡng không vào `sap_het`; `bien_dong_kho` với `san_pham_id: 'Sữa'` ⇒ `bad_args`.
  - `gross_profit`: `PERMISSION_DENIED` từ RPC ⇒ `RpcError` được ném ra (không thành `data`).
  - `search`: `don_ban` truyền `actor_id = ctx.actorId`; `gioi_han: 50` ⇒ gửi 5.
  - `redact`: `{ ten:'A', phone:'09', dia_chi:{address:'x'}, rows:[{email:'e'}] }` ⇒ còn `{ ten:'A', dia_chi:{}, rows:[{}] }`.
  - `unsupported`: `loai` lạ ⇒ `bad_args`.
- [ ] **Step 2: Chạy, thấy đỏ.**
- [ ] **Step 3: Viết** các tệp; mọi `forModel` đi qua `redactPersonal`.
- [ ] **Step 4: Chạy, thấy xanh** + `deno check` / `lint`.
- [ ] **Step 5: Commit** — `feat(ai): công cụ thống kê bán, tồn kho, biến động kho, lãi gộp, tìm kiếm`.

### Task 6: Orchestrator

**Files:** Create `supabase/functions/ai-assistant/orchestrator.ts`, `orchestrator_test.ts`

**Interfaces:**
- Consumes: Task 3 (`ModelClient`, `ModelTurn`, `Turn`, `TableBlock`, `Status`), Task 5 (`Tool`, `ToolContext`, `RpcError`, `MESSAGES`, `findTool`).
- Produces:
  ```ts
  export const MAX_TOOL_CALLS = 3
  export type OrchestratorResult = {
    status: Status; answer: string; blocks: TableBlock[]
    toolCalls: { name: string; args: Record<string, unknown>; ok: boolean }[]
    usage: Usage
  }
  export function answerQuestion(i: {
    question: string; history: Turn[]; system: string
    model: ModelClient; tools: Tool[]; ctx: ToolContext; signal?: AbortSignal
  }): Promise<OrchestratorResult>
  ```

Luật (theo thứ tự):
1. `turns` = lịch sử (`user` ⇒ `{role:'user', text}`; `assistant` ⇒ `{role:'model', raw:{role:'model', parts:[{text}]}}`) + câu hỏi (`{role:'user', text}`).
2. Lặp: gọi model với mọi khai báo công cụ. `text` ⇒ kết thúc. `tool_calls` ⇒ chạy **lần lượt từng call**, mỗi call tính 1 vào bộ đếm; vượt `MAX_TOOL_CALLS` ⇒ dừng, `status 'ok'` nếu đã có ≥ 1 `data` (answer = `MESSAGES.qua_phuc_tap`, giữ `blocks`), ngược lại `chua_ho_tro`.
3. Công cụ không có trong registry ⇒ trả Gemini `{ loi: 'khong_co_cong_cu' }`, tính 1 lần.
4. `RpcError` `PERMISSION_DENIED` ⇒ **dừng ngay**, `status 'khong_quyen'`, `answer = MESSAGES.khong_quyen`, `blocks = []`, không gọi model nữa. `RpcError` khác ⇒ trả Gemini `{ loi: 'khong_doc_duoc_du_lieu' }`.
5. `unsupported` ⇒ dừng, `status` = loại, `answer` = câu cố định tương ứng (không gọi model nữa).
6. Kết thúc bằng `text`: có ≥ 1 `data` ⇒ `ok`; không gọi công cụ nào ⇒ `tro_chuyen`, **nhưng** nếu `text` chứa chữ số (`/\d/`) ⇒ `chua_ho_tro` + `MESSAGES.chua_ho_tro` (chặn bịa số). `answer` = `text.trim()`, rỗng ⇒ `MESSAGES.loi` + `loi`.
7. `blocks` = các `block` theo thứ tự công cụ chạy; `usage` cộng dồn.
8. `ModelBusyError` / `ModelError` / `AbortError` **không** bắt ở đây — `index.ts` lo.

- [ ] **Step 1: Test đỏ** (FakeModelClient + công cụ giả):
  - `one_tool_then_text` ⇒ `ok`, 1 block, `toolCalls[0].ok = true`, usage cộng 2 lượt.
  - `permission_denied_stops` ⇒ `khong_quyen`, `MESSAGES.khong_quyen`, model chỉ được gọi 1 lần, `blocks = []`.
  - `unsupported_out_of_scope` ⇒ `ngoai_pham_vi` + `MESSAGES.ngoai_pham_vi`.
  - `chitchat_without_numbers` ("Chào bạn!") ⇒ `tro_chuyen`; **`chitchat_with_numbers_blocked`** ("Hôm nay bán 2.000.000đ") ⇒ `chua_ho_tro`.
  - `four_calls_capped` (model đòi 4 call) ⇒ chỉ 3 công cụ chạy, `MESSAGES.qua_phuc_tap`.
  - `bad_args_sent_back` ⇒ request thứ 2 có `tool_results` chứa `{ loi:'tham_so_sai' }`.
  - `unknown_tool` ⇒ trả `khong_co_cong_cu`.
  - `history_mapped`: 2 lượt lịch sử ⇒ request đầu có 3 turns đúng vai.
  - `model_raw_kept`: lượt model có `raw` được đẩy lại nguyên văn vào turns lần sau.
- [ ] **Step 2: Chạy, thấy đỏ.**
- [ ] **Step 3: Viết `answerQuestion`.**
- [ ] **Step 4: Chạy, thấy xanh.**
- [ ] **Step 5: Commit** — `feat(ai): orchestrator — tối đa 3 công cụ, phân loại trạng thái, chặn số bịa`.

### Task 7: `index.ts`, cấu hình, script bộ câu thử

**Files:**
- Create: `supabase/functions/ai-assistant/{request.ts, request_test.ts, index.ts}`, `scripts/ai/eval_questions.json`, `scripts/ai/run_eval.ts`
- Modify: `supabase/config.toml` (thêm `[functions.ai-assistant]` `verify_jwt = true`, cạnh `[functions.invitation-signup]`)

**Interfaces:**
- Consumes: mọi task trước; `ai.start_question` / `ai.finish_question` (Task 2).
- Produces: HTTP `POST /functions/v1/ai-assistant`
  - Request body: `{ tenant_id: uuid, question: string, history?: Turn[] }`
  - Response `200` luôn là `AssistantReply` (Task 3) — kể cả `het_luot` / `ban` / `loi` / `khong_quyen`; `400 { error: 'VALIDATION_ERROR' }` khi body sai; `401` khi không có JWT người dùng; `405` / `OPTIONS 204` như `einvoice-processor/auth.ts` (dùng lại kiểu CORS đó, chép vào tệp, không import chéo function).
  ```ts
  // request.ts
  export function parseAssistantRequest(body: unknown):
    { ok: true; value: { tenantId: string; question: string; history: Turn[] } } | { ok: false }
  ```
  `tenant_id` uuid; `question` trim, 1..500 ký tự; `history` không phải mảng ⇒ `[]`; chỉ giữ phần tử `{role:'user'|'assistant', text: string}`, cắt text 2000 ký tự, giữ **6 phần tử cuối**, bỏ mọi khoá khác.

Luồng `index.ts`:
1. Client Supabase bằng `SUPABASE_ANON_KEY` + header `Authorization` của request (mọi RPC chạy bằng JWT người hỏi); `actorId` = `auth.getUser()`.
2. `ai.start_question` — `QUOTA_EXCEEDED` ⇒ trả `het_luot` (không gọi model, không ghi thêm); `PERMISSION_DENIED` ⇒ `khong_quyen`.
3. `answerQuestion` với `GeminiClient({ apiKey: GEMINI_API_KEY, model: GEMINI_MODEL ?? 'gemini-3.1-flash-lite' })`, `buildSystemPrompt`, `buildTools()`, `AbortController` 30 000 ms.
4. Bắt lỗi: `ModelBusyError` ⇒ `ban` + `MESSAGES.ban`; hết giờ ⇒ `loi` + `MESSAGES.cham`; lỗi khác ⇒ `loi` + `MESSAGES.loi` (log `console.error` không kèm câu hỏi).
5. `ai.finish_question(log_id, status, toolCalls, tokens, latency)` — lỗi ghi nhật ký **không** làm hỏng câu trả lời (chỉ `console.error`).
6. `luot_con_lai` = `remaining` từ bước 2 (`het_luot` ⇒ 0); `cong_cu` = tên trong `toolCalls`.
7. Thiếu `GEMINI_API_KEY` ⇒ `loi` (không 500).

Script câu thử:
- `scripts/ai/eval_questions.json`: 22 câu AI-0 mục 9 **trừ 15–17**; mỗi câu `{ "id": 1, "nguoi_hoi": "chu" | "thu_ngan", "cau_hoi": "…", "cong_cu": ["thong_ke_ban_hang"], "trang_thai": "ok", "doi_chieu": "Khớp doanh thu hôm nay" }`. Chỗ `[Sản phẩm A]` / `[mã đơn]` ghi `{san_pham_a}` / `{ma_don}`.
- `scripts/ai/run_eval.ts` (Deno): env `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `AI_EVAL_TENANT_ID`, `AI_EVAL_OWNER_EMAIL` / `_PASSWORD`, `AI_EVAL_CASHIER_EMAIL` / `_PASSWORD`, `AI_EVAL_SAN_PHAM_A`, `AI_EVAL_MA_DON`; đăng nhập 2 tài khoản, hỏi lần lượt (nghỉ 5 giây giữa các câu để không chạm hạn mức phút), in bảng: `id | câu hỏi | công cụ (mong đợi / thực tế) | trạng thái (mong đợi / thực tế) | câu trả lời | đối chiếu số (người kiểm tay)`, cuối in `Tự động đạt: x/22` (khớp công cụ + trạng thái). Đúng số: người dùng đối chiếu tay — chạy đủ sau AI-3.

- [ ] **Step 1: Test đỏ** `request_test.ts`: body hợp lệ; `tenant_id` sai; câu 501 ký tự; **`history_strips_unknown_fields`** (phần tử có `functionCall`, `role:'model'`, thiếu `text` ⇒ bị bỏ); 8 lượt ⇒ giữ 6 cuối; text 3000 ký tự ⇒ cắt 2000.
- [ ] **Step 2: Chạy, thấy đỏ.**
- [ ] **Step 3: Viết** `request.ts`, `index.ts`, sửa `config.toml`, viết `eval_questions.json` + `run_eval.ts`.
- [ ] **Step 4: Kiểm** — `deno test --allow-env --allow-net=127.0.0.1 supabase/functions/ai-assistant/` xanh toàn bộ; `deno check supabase/functions/ai-assistant/index.ts scripts/ai/run_eval.ts`; `tools/db_check.sh` ✅; `detect_changes({scope: "compare", base_ref: "main"})` chỉ chạm tệp của plan này.
- [ ] **Step 5: Ghi vào Kết quả lệnh cho người dùng tự chạy** (không tự chạy):
  ```bash
  # 1. khoá Gemini (Google AI Studio) vào tệp env local — đã bị .gitignore (**/.env.*)
  echo 'GEMINI_API_KEY=<khoá>' > supabase/functions/.env.local
  supabase functions serve ai-assistant --env-file supabase/functions/.env.local
  # 2. hỏi thử bằng JWT của chủ cửa hàng (lấy từ app / supabase auth)
  curl -s http://127.0.0.1:54321/functions/v1/ai-assistant \
    -H "Authorization: Bearer <JWT>" -H 'Content-Type: application/json' \
    -d '{"tenant_id":"<tenant>","question":"Hôm nay bán được bao nhiêu?"}'
  ```
  Kỳ vọng: `trang_thai: "ok"`, `cong_cu: ["thong_ke_ban_hang"]`. Thử thêm "Mai trời mưa không?" ⇒ `ngoai_pham_vi`.
- [ ] **Step 6: Commit** — `feat(ai): Edge Function ai-assistant + script bộ câu thử`.

---

## Kết quả

**Ngày làm:** 2026-11-16. Theo yêu cầu người dùng: **không commit từng task** (mọi thay đổi còn ở working tree, chưa commit).

**Task 1 — `sales.get_sales_stats`:** đã viết `20261120001_sales_stats.sql`, `tests/sales_stats.sql`, REGISTRY (`sales:` → `get_sales_stats`). **Chưa chạy `tools/db_check.sh`** (lệnh DB do người dùng tự chạy): `tools/db_check.sh --no-reset sales_stats` rồi `tools/db_check.sh`.
- Ruling: test `s1` dùng phiếu trả (không có dòng đổi) — fixture đổi hàng cần thêm API; nhánh `exchange` của RPC chép đúng từ G5-7 nhưng chưa có ca test riêng.
- Ruling: tên nhân viên lấy từ `iam.platform_user_profiles` (họ đệm + tên), thiếu thì `'Nhân viên'` — không dùng `iam._member_display_name` vì hàm đó rơi về email (không được gửi cho Gemini).
- Ruling: `s6` (75 000) chạy trên tenant B riêng (2 đơn 100 000 + 50 000); tenant A dùng cho các ca còn lại — nên `s10` kiểm cả hai chiều.

**Task 2 — schema `ai`:** đã viết `20261120002_ai_assistant_log.sql`, `tests/ai_assistant_log.sql`, REGISTRY (nhóm `ai:`), `config.toml` (`schemas += "ai"`). **Chưa chạy db_check** — `tools/db_check.sh --no-reset ai_assistant_log`.
- Thêm `ai._raise` (khuôn `inventory._raise`) và `grant usage on schema ai to authenticated`; thêm check constraint cho `status` / độ dài câu hỏi.
- **Người dùng tự thêm `ai` vào "Exposed schemas" của Supabase Dev** (Dashboard → API settings) trước khi deploy.

**Task 3–7 — Edge Function `ai-assistant` (Deno):** `deno test --allow-env --allow-net=127.0.0.1 supabase/functions/ai-assistant/` → **80 passed, 0 failed**; `deno check supabase/functions/ai-assistant/index.ts scripts/ai/run_eval.ts` sạch; `deno lint` + `deno fmt --check` sạch.
- Ruling: thêm `supabase/functions/ai-assistant/deno.json` (fmt: nháy đơn, không `;`, rộng 120 cho khớp code hiện có; lint: bỏ rule `no-import-prefix` vì plan và các function khác dùng import `jsr:` / `npm:` trực tiếp). `scripts/ai/run_eval.ts` lint bằng `--rules-exclude=no-import-prefix`.
- Ruling: tách luồng xử lý thành `handler.ts` (nhận phụ thuộc giả) + `http.ts` (CORS, chép từ `einvoice-processor/auth.ts`); `index.ts` chỉ nối. Có `handler_test.ts` (9 ca: thành công, `het_luot`, `ban`, quá 30 giây, thiếu khoá, lỗi nhật ký, `khong_quyen`, 400 / 401 / 405 / 204).
- Ruling (orchestrator): vượt 3 lần gọi mà chưa có dữ liệu → `chua_ho_tro` + `MESSAGES.chua_ho_tro`; model trả chữ sau khi gọi công cụ nhưng không có `data` → `chua_ho_tro` (chữ số trong câu thì thay bằng câu cố định).
- Gemini REST: dùng đúng `x-goog-api-key`, `systemInstruction`, `functionDeclarations`, `functionResponse.response` (bọc `{ ket_qua }` nếu không phải đối tượng); **chưa đối chiếu tài liệu Gemini hiện hành và chưa thử Gemini thật** (người dùng tự chạy, xem lệnh dưới). Kiểm lại tên model `gemini-2.5-flash` + hạn mức trên Google AI Studio.
- Khoá kết quả RPC có sẵn đọc từ migration gốc: `list_stock_overview.products[]`, `get_stock_card.{product,summary,rows}`, `get_gross_profit_report.{rows,totals}`, `catalog.search_products` (bảng), `partner.search_partners` (1 dòng `{items}`; **tên khoá trong `items` — `partner_id`, `display_name` — chưa xác minh**, code có dự phòng `id` / `name`), `sales.search_sales_orders.items[]` (`salesOrderId`, `orderNumber`, `customer.displayName`, `total.amountMinor`, `committedAt`).
- Mã dự phòng cho TDD: Task 3, 4, 5, 7 (`request.ts`) viết code trước test trong cùng bước nên chưa thấy "đỏ" riêng; Task 6 đã thấy đỏ (thiếu module) rồi mới viết `orchestrator.ts`.
- `detect_changes` (GitNexus) **chưa chạy** — phiên này không có công cụ MCP đó. Mọi thay đổi là tệp mới, chỉ sửa `supabase/config.toml` và `REGISTRY.yaml`.

**Việc người dùng tự chạy:**
```bash
# DB (local)
tools/db_check.sh --no-reset sales_stats
tools/db_check.sh --no-reset ai_assistant_log
tools/db_check.sh                      # đủ 3 bước

# Edge Function — khoá Gemini vào tệp env local (đã bị .gitignore)
echo 'GEMINI_API_KEY=<khoá>' > supabase/functions/.env.local
supabase functions serve ai-assistant --env-file supabase/functions/.env.local
curl -s http://127.0.0.1:54321/functions/v1/ai-assistant \
  -H "Authorization: Bearer <JWT>" -H 'Content-Type: application/json' \
  -d '{"tenant_id":"<tenant>","question":"Hôm nay bán được bao nhiêu?"}'
```
Kỳ vọng: `trang_thai: "ok"`, `cong_cu: ["thong_ke_ban_hang"]`; "Mai trời mưa không?" ⇒ `ngoai_pham_vi`.

## Review

### R1 (2026-11-16) — có góp ý, chờ sửa

**Đã kiểm (phiên review tự chạy, không đụng DB):** `deno test` **80 passed / 0 failed**; `deno check` (index.ts, run_eval.ts), `deno lint`, `deno fmt --check` sạch.
**Đã đối chiếu bằng đọc code:** doanh thu `get_sales_stats` cùng 4 nhánh với `get_gross_profit_report` G5-7 (hoàn tất / đổi / trả / huỷ, cùng bộ lọc cửa hàng, cùng giờ VN); khoá kết quả RPC mà công cụ đọc khớp migration gốc (`list_stock_overview.products[]`, `get_stock_card.{product,summary,rows}`, `get_gross_profit_report.rows` cả hai chế độ, `catalog.search_products` — `stock_qty` vẫn lấy từ `inventory._product_stock_rows` sau khi G5-5 xoá kho cơ bản, `partner.search_partners.items[]` có `partner_id` / `display_name` qua `row_to_json` — **điều "chưa xác minh" ở mục Kết quả đã xác minh: đúng**, `sales.search_sales_orders.items[]`); cột bảng `catalog.products.name`, `partner.partners.display_name`, `iam.platform_user_profiles.{given_name,family_middle_name}`, `iam.tenants.display_name` đều tồn tại.
**Chưa kiểm được, cần người dùng:** `tools/db_check.sh` (xem lệnh ở cuối), chạy Gemini thật, tên model `gemini-2.5-flash` / hạn mức trên Google AI Studio, `detect_changes` (GitNexus).

**Cần sửa**

| # | Mức | Chỗ | Vấn đề | Cách sửa |
|---|---|---|---|---|
| 1 | Trung bình | `tools/sales_stats.ts:127` | Tiêu đề bảng người dùng thấy **không dấu**: `` `${meta.ten} theo ${nhom.value.replace('_', ' ')}` `` ra "Doanh thu theo san pham", "…theo khach hang", "…theo nhan vien", "…theo ngay". | Ánh xạ nhãn có dấu: ngày / tuần / tháng / sản phẩm / khách hàng / nhân viên; thêm assert tiêu đề vào `sales_stats_test.ts`. |
| 2 | Trung bình | `prompt.ts` (quy tắc 1) | Lời dặn (chép nguyên văn AI-0 mục 7) liệt kê **"công nợ khách, dự báo nhập hàng"** là trong phạm vi, nhưng AI-1 **chưa có công cụ nào** cho hai việc này (công nợ hoãn, dự báo thuộc AI-3). Hỏi "Khách nào đang nợ?" Gemini có thể trả lời bằng chữ không kèm số, vd. "Hiện không có khách nào nợ" — không có chữ số nên lọt bộ chặn ở orchestrator, thành `tro_chuyen` và hiện như sự thật (**bịa dữ kiện**). | Trong AI-1 bỏ hai mục đó khỏi quy tắc 1 (AI-3 thêm lại cùng công cụ), và thêm một dòng: "Chưa có công cụ phù hợp thì KHÔNG trả lời nội dung, gọi bao_khong_ho_tro (chua_ho_tro)." Thêm ca `prompt_test.ts` kiểm hai chuỗi không còn. Cân nhắc sửa AI-0 mục 7 cho khớp. |
| 3 | Thấp–TB | `handler.ts` (`client.auth.getUser()`) | Gọi không truyền token. Client tạo với `persistSession: false` và token chỉ nằm trong header toàn cục; `getUser()` không đối số phụ thuộc vào phiên bản `supabase-js` có chấp nhận header `Authorization` tuỳ chỉnh hay không. Test chỉ dùng đối tượng giả nên **không bắt được**. Nếu sai: mọi request 401. | Tách token khỏi header (`authorization.replace(/^Bearer\s+/i, '')`) và gọi `getUser(token)`; cập nhật đối tượng giả cho khớp. Dù sao cũng thử bằng `curl` thật ở bước người dùng tự chạy. |
| 4 | Thấp | `tools/tool.ts` `rpcErrorFromPostgrest` | Nhánh dự phòng `/permission denied/i` cũng khớp lỗi Postgres `permission denied for function …` (thiếu GRANT / sai schema) ⇒ người dùng thấy "Bạn không có quyền xem số liệu này" và nhật ký ghi `khong_quyen`, **che mất lỗi cấu hình**. | Chỉ nhận `code` trong JSON hoặc chuỗi bắt đầu `PERMISSION_DENIED`; lỗi khác ⇒ `UNKNOWN` ⇒ `khong_doc_duoc_du_lieu` / `loi`. Thêm test "permission denied for function" ⇒ `UNKNOWN`. |
| 5 | Thấp | `supabase/tests/sales_stats.sql` | Chưa có ca cho: nhánh **hàng đổi** (đã ghi ở Kết quả), `quantity`, nhóm `seller`, `week` / `month` khác ngày hôm nay, `s5` chỉ có một ngày (plan ghi 3 ngày). Nhánh đổi chép từ G5-7 nên rủi ro thấp, nhưng s1 không bắt được nếu nhánh đó lệch. | Thêm tối thiểu: `quantity` (đơn 2 sản phẩm, có trả), `seller` (nhãn không rỗng), một đơn lùi ngày để `day` ra 2 dòng. Nhánh đổi: làm khi có fixture, hoặc ghi nợ vào `db_check_known.txt` / PLAN. |

**Ghi nhận, không cần sửa**
- Khoá chống hỏi đồng thời (`pg_advisory_xact_lock`) có trong SQL nhưng **không test được** trong một khối `do` (Review Focus 4 của plan ghi nhầm là test `a2b`; `a2b` là ca "ban không tính"). Đã đọc kỹ code, đúng ý.
- `eval_questions.json` có 22 câu; **18–20 cần `du_bao_ban_hang` (AI-3)** nên bây giờ tối đa đạt 19/22. Công cụ thiếu chỉ là hợp lệ, không phải lỗi.
- Không commit từng task (người dùng yêu cầu); thêm `handler.ts`, `http.ts`, `deno.json`, `tools/test_util.ts` ngoài cấu trúc plan — chấp nhận, đều có lý do ghi ở Kết quả.
- Số trong lời Gemini không được đối chiếu lại với kết quả công cụ khi **đã có** dữ liệu (chỉ chặn khi **không** có). Đúng phạm vi plan; nếu muốn chặt hơn thì đề xuất cho AI-3.

**Người dùng chạy giúp (local) rồi dán kết quả**
```bash
tools/db_check.sh --no-reset sales_stats
tools/db_check.sh --no-reset ai_assistant_log
tools/db_check.sh                       # đủ 3 bước: reset + plpgsql_check + mọi test
```
(Cần `supabase stop && supabase start` nếu local chưa nạp `schemas += "ai"` trong `config.toml`.) Sau đó thử Gemini thật theo lệnh `curl` ở mục Kết quả.


### Sửa sau R1 (2026-11-16)

Đã xác nhận cả 5 mục là đúng trong code, rồi sửa. Deno: `deno test` **87 passed / 0 failed** (thêm 7 test, đỏ trước khi sửa), `deno check` / `lint` / `fmt --check` sạch.

| # | Cách sửa | Test |
|---|---|---|
| 1 | `tools/sales_stats.ts`: bảng nhãn có dấu `NHOM_NHAN` (ngày / tuần / tháng / sản phẩm / khách hàng / nhân viên) | `sales_stats_test.ts` "tiêu đề bảng có dấu tiếng Việt" |
| 2 | `prompt.ts`: bỏ "công nợ khách, dự báo nhập hàng" khỏi quy tắc 1; thêm dòng "Chưa có công cụ phù hợp thì KHÔNG trả lời nội dung, gọi bao_khong_ho_tro (chua_ho_tro)." **AI-3 thêm lại cùng công cụ dự báo; AI-0 mục 7 chưa sửa** (người dùng quyết). | `prompt_test.ts` |
| 3 | `handler.ts`: `getUser(token)` với token bỏ tiền tố `Bearer` | `handler_test.ts` "getUser nhận token đã bỏ tiền tố Bearer" |
| 4 | `tools/tool.ts`: bỏ nhánh `/permission denied/i`; chỉ nhận `code` trong JSON hoặc chuỗi bắt đầu `PERMISSION_DENIED` | `tools/tool_test.ts` (mới) |
| 5 | `tests/sales_stats.sql`: thêm `s11_quantity`, `s12_seller`, viết lại `s5` (lùi o1 về hôm qua ⇒ `day` ra 2 dòng, kiểm `week` / `month`, doanh thu vẫn khớp lãi gộp). **Chưa chạy** — người dùng chạy `tools/db_check.sh --no-reset sales_stats`. Nếu `update sales.sales_orders set completed_at` bị trigger chặn, báo lại để đổi cách dựng. | — |

**Còn nợ:** ca test nhánh **hàng đổi** của `get_sales_stats` (cần fixture đổi hàng) — chép từ G5-7 nên rủi ro thấp. `getUser(token)` và Gemini thật vẫn phải thử bằng `curl` ở bước người dùng tự chạy.

### db_check (người dùng chạy, 2026-11-16)

`tools/db_check.sh` đủ 3 bước: **✅ DB check đạt**. `sales_stats: OK` (gồm `s5` lùi ngày, `s11_quantity`, `s12_seller`), `ai_assistant_log: OK`; migration lên đủ (có schema `ai`); các test cũ vẫn xanh, chỉ còn các nợ đã biết (`catalog_th02`, `einvoice_th08`, `pricing_th04`, 2 lỗi plpgsql_check cũ). Còn lại: thử `curl` + Gemini thật (người dùng), ca test nhánh hàng đổi (nợ).

### R2 (2026-11-16) — đạt

**Đã kiểm (phiên review):** `deno test` **87 passed / 0 failed**; `deno check`, `deno lint`, `deno fmt --check` sạch. DB: người dùng chạy `tools/db_check.sh` đủ 3 bước ✅ (ghi ở mục "db_check" trên) — phiên review không chạy lệnh DB.

| R1 | Kết quả đọc lại code + test |
|---|---|
| 1 Tiêu đề không dấu | ✅ `NHOM_NHAN` có dấu; test kiểm đủ 6 nhóm ("Doanh thu theo sản phẩm", …) |
| 2 Lời dặn nhắc công nợ / dự báo | ✅ quy tắc 1 đã bỏ hai mục; thêm dòng "KHÔNG trả lời nội dung, gọi bao_khong_ho_tro (chua_ho_tro)"; test khẳng định cả ba |
| 3 `getUser` không token | ✅ `getUser(token)` bỏ tiền tố `Bearer`; test kiểm đúng chuỗi token truyền vào |
| 4 `permission denied` bị hiểu nhầm | ✅ bỏ nhánh `/permission denied/i`; `tool_test.ts` kiểm "permission denied for function …" ⇒ `UNKNOWN` |
| 5 Test SQL thiếu ca | ✅ `s11_quantity` (tổng 3, SP Một 2), `s12_seller`, `s5` lùi ngày (ngày hôm qua 1, hôm nay 2; `week` / `month`; doanh thu vẫn khớp lãi gộp). Đã đối chiếu số kỳ vọng với fixture, đúng. `db_check` xanh |

**Còn mở (không chặn đóng R2):**
- Ca test nhánh **hàng đổi** của `get_sales_stats` — nợ đã ghi, rủi ro thấp (chép từ G5-7).
- **Chưa có bằng chứng chạy Gemini thật + `curl`** (việc của người dùng, Task 7 bước 5): xác nhận `getUser(token)` thật sự cho 200, tên model `gemini-2.5-flash` còn dùng được, một câu "ok" và một câu `ngoai_pham_vi`. Nếu lệch tài liệu Gemini / 401 thì mở lại thành mục R3.
- AI-0 mục 7 vẫn còn "công nợ khách, dự báo nhập hàng" (người dùng chọn chưa sửa) — **AI-3 và việc công nợ sau Theme 6 phải thêm lại vào lời dặn trong `prompt.ts`**, nếu không bộ câu thử 15–20 sẽ trả "chưa hỗ trợ".
- `detect_changes` (GitNexus) chưa chạy trong cả hai phiên — chạy trước khi commit.

### R3 (2026-11-16) — thử Gemini thật: 1 góp ý, chờ sửa

**Đã thử (local, người dùng + phiên review):** `supabase functions serve` + đăng nhập chủ cửa hàng test "Stats Tenant A" + khoá Gemini thật. Kết quả với `GEMINI_MODEL=gemini-3.1-flash-lite`:
- "Hôm nay bán được bao nhiêu?" ⇒ `ok`, `cong_cu: [thong_ke_ban_hang]`, **150.000 đ** (khớp fixture: 50.000 + 200.000 − trả 100.000; đơn huỷ = 0), `luot_con_lai` 96.
- "Mai trời mưa không?" ⇒ `ngoai_pham_vi` qua `bao_khong_ho_tro`.
- "Hàng nào sắp hết?" ⇒ `ok`, `tinh_hinh_ton_kho`, bảng trống (fixture không đặt ngưỡng).
⇒ `getUser(token)`, đếm lượt, nhật ký, vòng gọi công cụ, định dạng REST Gemini (function calling) đều chạy thật. Việc "chưa thử Gemini thật" của R2 **đã xong**.

**Cần sửa**

| # | Mức | Chỗ | Vấn đề | Cách sửa |
|---|---|---|---|---|
| 6 | **Cao** | `handler.ts` `DEFAULT_MODEL = 'gemini-2.5-flash'` | Google báo `models/gemini-2.5-flash is no longer available to new users` (404). Khoá mới không dùng được model mặc định ⇒ **mọi câu hỏi ra `loi`** nếu không đặt `GEMINI_MODEL`. Các model khác khi thử: `gemini-3.8-flash` 503 "high demand" sau 51 giây; `gemini-flash-latest` 503; `gemini-3.7-flash` quá 40 giây; `gemini-3.5-flash` ~24 giây; `gemini-2.5-flash-lite` 404; **`gemini-3.1-flash-lite` 200 trong ~1,3 giây**. | Đổi mặc định sang model đang chạy tốt (`gemini-3.1-flash-lite`, kiểm lại lúc sửa), cập nhật mọi chỗ ghi `gemini-2.5-flash` (plan, `README` nếu có), test mặc định trong `handler_test.ts` nếu có. Tên model đổi nhanh ⇒ ghi trong plan: lệnh `curl` liệt kê model ở dưới. |
| 7 | Thấp | `handler.ts` (catch lỗi model) | Log chỉ ghi tên lỗi (`ai-assistant lỗi Error`) nên lần này phải gọi tay Gemini mới biết lý do (404 model, 503…). `ModelError` / `ModelBusyError` chỉ chứa mã HTTP, không chứa câu hỏi. | Với `ModelError` / `ModelBusyError` ghi `console.error(e.message)` (vd. "Gemini HTTP 404"); vẫn **không** ghi câu hỏi hay khoá. Thêm test kiểm không lọt nội dung câu hỏi vào log. |

**Ghi nhận**
- Mức chờ 30 giây của function hợp lý nhưng model chậm (`3.5-flash` ~24 giây, vài model > 40 giây) sẽ đẩy câu hỏi sang `loi` / "phản hồi chậm". Chọn model nhanh (flash-lite) cho demo; nếu cần, đặt `GEMINI_MODEL` riêng.
- Tên model và hạn mức Google đổi theo thời gian — kiểm lại trước ngày demo.
- Lệnh liệt kê model (không in khoá): `curl -s "https://generativelanguage.googleapis.com/v1beta/models?pageSize=100" -H "x-goog-api-key: $GEMINI_API_KEY"`.
- Môi trường local: PostgREST phải nạp `schemas` mới ⇒ sau khi sửa `supabase/config.toml` cần `supabase stop && supabase start` (không `--no-backup`). Đây không phải lỗi code, nhưng nên có trong hướng dẫn chạy thử.

### Sửa sau R3 (2026-11-16)

Đã xác nhận cả 2 lỗi trong code rồi sửa. `deno test` **89 passed / 0 failed** (2 test mới đỏ trước khi sửa), `deno check` / `lint` / `fmt --check` sạch.

| # | Cách sửa | Test |
|---|---|---|
| 6 | `handler.ts`: `DEFAULT_MODEL = 'gemini-3.1-flash-lite'`; cập nhật tên model ở "Thiết kế AI-1" và Task 7 của plan | `handler_test.ts` "model mặc định … GEMINI_MODEL ghi đè" |
| 7 | `handler.ts`: `ModelError` ghi `e.message`, `ModelBusyError` ghi `console.error` kèm message; lỗi lạ khác vẫn chỉ ghi tên | `handler_test.ts` "log lỗi model … không lộ câu hỏi hay khoá" |

**Ghi chú vận hành:**
- Tên model và hạn mức Google đổi nhanh — kiểm lại trước ngày demo. Liệt kê model (không in khoá): `curl -s "https://generativelanguage.googleapis.com/v1beta/models?pageSize=100" -H "x-goog-api-key: $GEMINI_API_KEY"`.
- Sau khi sửa `supabase/config.toml` (thêm `ai` vào `schemas`) cần `supabase stop && supabase start` (không `--no-backup`) để PostgREST nạp schema mới.
- Model chậm (> 30 giây) sẽ ra "phản hồi chậm"; chọn flash-lite cho demo, hoặc đặt `GEMINI_MODEL` riêng.

### R4 (2026-11-16) — đạt

**Đã kiểm (phiên review):** `deno test` **89 passed / 0 failed**; `deno check` (index.ts, run_eval.ts), `deno lint`, `deno fmt --check` sạch; quét đầu mọi tệp `.ts` không còn ký tự lạ.

| R3 | Kết quả đọc lại code + test |
|---|---|
| 6 Model mặc định hết hạn | ✅ `DEFAULT_MODEL = 'gemini-3.1-flash-lite'`; test kiểm mặc định và `GEMINI_MODEL` ghi đè; plan (mục "Thiết kế AI-1", Task 7) đã đổi. Còn `gemini-2.5-flash` ở dòng lịch sử của R1 / R2 / Kết quả — để nguyên làm nhật ký |
| 7 Log lỗi model | ✅ `ModelError` ghi `e.message` ("Gemini HTTP 404"), `ModelBusyError` ghi kèm message; lỗi lạ chỉ ghi tên. Test ghi log thật và khẳng định **không** có câu hỏi riêng tư, **không** có khoá |

**Toàn bộ AI-1:** 7 task + 7 góp ý (R1: 5, R3: 2) đã sửa; DB `db_check` ✅ (người dùng chạy); Gemini thật chạy qua function local ✅ (R3: 3 câu, số khớp dữ liệu test).

**Còn mở (không chặn đóng AI-1):**
- Ca test nhánh **hàng đổi** của `get_sales_stats` (nợ, rủi ro thấp).
- Tên model / hạn mức Google đổi nhanh: kiểm lại trước ngày demo (lệnh liệt kê model ở mục R3).
- AI-0 mục 7 còn "công nợ khách, dự báo nhập hàng": **AI-3 và việc công nợ sau Theme 6 phải thêm lại vào `prompt.ts`**.
- Eval 22 câu: 3 câu (18–20) cần `du_bao_ban_hang` của AI-3 nên chưa chạy đủ; chưa chạy `scripts/ai/run_eval.ts` với tài khoản thu ngân (câu 25 cần một thành viên không phải chủ).
- `detect_changes` (GitNexus) chưa chạy — chạy trước khi commit.
- Chưa thử trên **Supabase Dev** (cần bật schema `ai`, `supabase secrets set GEMINI_API_KEY`, `functions deploy` — do người dùng làm).
