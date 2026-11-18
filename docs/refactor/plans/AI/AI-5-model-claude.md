# AI-5 — Hỏi VET45 chạy bằng Claude Haiku 5.5 (bỏ Gemini)

> Tích hợp AI · plan **AI-5** của [PLAN.md](../../PLAN.md) mục "Tích hợp AI"
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-17) | Làm ✅ Task 1–3 (2026-11-18) | Review ⏸ **tạm dừng 2026-11-18** (người dùng chuyển sang công nợ). **Việc còn mở khi quay lại:** (1) Task 4 — seed Demo AI + bộ 45 câu `low` / `medium`, chốt effort, đóng AI-4; (2) lỗi Flutter: bấm dòng đơn trong bảng trợ lý ⇒ màn đỏ `!keyReservation.contains(key)` / GlobalKey `root` trùng (đang khoanh vùng: thử mở đơn từ tab Đơn hàng, thử bấm dòng sản phẩm); (3) gỡ / rút gọn log chẩn đoán `ai-trace` sau eval.
> Thiết kế: duyệt trong chat 2026-11-17. Lý do: trên Dev, Gemini (`gemini-3.1-flash-lite`, `gemini-3.8-flash`) treo 12–30 giây hoặc trả 503 ngay cả với câu "chào" gửi thẳng từ máy người dùng (gói miễn phí bị xếp sau khi quá tải); `gemini-2.5-flash` trả 404. Người dùng chốt: **Claude Haiku 5.5, effort `low`**, **bỏ hẳn Gemini** (không dự phòng, không đổi tay). Nền: [AI-1](AI-1-backend.md), [AI-4](AI-4-truy-van-sql.md).

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development hoặc superpowers:executing-plans. Dự án này **người dùng tự code, Claude review ở phiên khác**; các bước dùng checkbox để người dùng tick.

**Goal:** Edge Function `ai-assistant` gọi Claude Haiku 5.5 thay cho Gemini, giữ nguyên công cụ / `truy_van` / DB / app; đổi được model và effort bằng biến môi trường; xoá code Gemini.

**Architecture:** Thêm `model/claude_client.ts` cài đặt `ModelClient` có sẵn bằng SDK chính thức `@anthropic-ai/sdk` (Messages API; vòng lặp gọi công cụ vẫn do `orchestrator.ts` chạy). `model/config.ts` đọc biến môi trường. Lượt trả lời cũ trong `history` thành lượt chữ đơn giản `model_text` (orchestrator không cần biết định dạng của nhà cung cấp; `ClaudeClient` tự đổi sang `assistant`). Xoá `gemini_client.ts` và mọi biến `GEMINI_*`.

**Tech Stack:** Deno (Supabase Edge Functions), `npm:@anthropic-ai/sdk` (ghim phiên bản chính xác), Claude Messages API.

**Spec:** thiết kế AI-5 trong chat 2026-11-17 (bản "sửa lần 1", chốt effort `low`, chốt bỏ Gemini); tóm tắt ở mục Thiết kế dưới.

## Thiết kế (đã duyệt)

- Model `claude-haiku-5-5` (biến `CLAUDE_MODEL`), effort `low` (biến `CLAUDE_EFFORT`: `low` | `medium` | `high`, giá trị khác ⇒ `low`). Không gửi `thinking` (Haiku 5.5 mặc định suy nghĩ thích ứng), **không** gửi `temperature` / `top_p` / `top_k` (Haiku 5.5 trả 400 với giá trị khác mặc định).
- Thiếu `ANTHROPIC_API_KEY` ⇒ như hiện nay với key Gemini (`console.error`, trạng thái `loi`).
- Lỗi: 429 / 529 / quá giờ một lần gọi ⇒ `ModelBusyError` ("bận"); `stop_reason` `refusal` / lỗi khác ⇒ `ModelError` ("lỗi"); huỷ do hết 30 giây tổng ⇒ ném nguyên lỗi huỷ (handler hiện "chậm").
- Bộ nhớ đệm: bật `cache_control` tự động cấp request (phần công cụ + lời dặn lặp lại giữa các vòng).
- **Bỏ Gemini:** xoá `model/gemini_client.ts`, `model/gemini_client_test.ts`, biến `GEMINI_API_KEY`, `GEMINI_MODEL` (người dùng gỡ secret trên Dev). Không còn `AI_PROVIDER`.
- Không làm: streaming, dự phòng, lưu tên model vào DB.

## Global Constraints

- SDK: `import Anthropic from 'npm:@anthropic-ai/sdk@<x.y.z>'` — **ghim đúng một phiên bản** (bản mới nhất lúc làm: `npm view @anthropic-ai/sdk version`), cập nhật `deno.lock`. Dùng lớp lỗi của SDK (`Anthropic.RateLimitError`, `Anthropic.APIError` với `.status`, `Anthropic.APIConnectionTimeoutError`, `Anthropic.APIUserAbortError`), **không** so chuỗi thông báo.
- Gọi: `client.messages.create({ model, max_tokens: 8000, system, tools, messages, output_config: { effort }, cache_control: { type: 'ephemeral' } }, { signal, timeout: 12_000 })`; client tạo với `{ apiKey, maxRetries: 1 }` (SDK tự gọi lại 1 lần với 429 / 5xx / 529 / quá giờ).
- Công cụ: `{ name, description, input_schema: parameters }` từ `ToolDeclaration` — **không** đổi nội dung mô tả.
- Kết quả công cụ gửi lại: một tin `user` chứa các khối `{ type: 'tool_result', tool_use_id, content: JSON.stringify(response) }` **cùng thứ tự** các khối `tool_use` của lượt `assistant` ngay trước; lượt `assistant` gửi lại **nguyên văn** `response.content` (kể cả khối `thinking`).
- Không gửi số điện thoại / email / địa chỉ (giữ `redactPersonal`). Không log câu hỏi.
- **Không commit.** Test Deno chạy trên máy (`cd supabase/functions/ai-assistant && deno test --no-check -A .`, không cần DB) sau mỗi task. Luồng thực tế test trên Dev bằng app.
- Secrets trên Dev (người dùng đặt): `ANTHROPIC_API_KEY` (đã đặt 2026-11-17), tuỳ chọn `CLAUDE_MODEL`, `CLAUDE_EFFORT`. **Không** dán key vào chat / tài liệu.
- Ghi mục "Kết quả" cuối file sau mỗi task.

## Review Focus

1. **Một lượt gọi nhiều công cụ** (vd. `thong_ke_ban_hang` ×2) — `tool_use_id` phải khớp đúng thứ tự, sai ⇒ Claude trả 400. → test `claude_tool_results_match_ids` (Task 2).
2. **Hội thoại có lượt trả lời cũ** (`history`, kể cả lượt sinh từ thời Gemini còn trong app) — phải chạy. → test `history_assistant_is_text_turn` (Task 1), `claude_maps_model_text` (Task 2).
3. **Claude trả chữ mở đầu kèm `tool_use`** trong cùng một lượt — phải coi là gọi công cụ, giữ nguyên văn để gửi lại. → test `claude_text_and_tool_use_is_tool_calls` (Task 2).
4. **`stop_reason` `refusal` / `max_tokens`** — không văng 500, không trả chữ cụt như câu trả lời đúng. → test `claude_refusal_is_model_error` (Task 2).
5. **Hết 30 giây tổng giữa lúc gọi Claude** — phải hiện "Trợ lý phản hồi chậm", không phải "Có lỗi". → test `claude_user_abort_rethrown` (Task 2).

---

## Cấu trúc tệp

```
supabase/functions/ai-assistant/model/model_client.ts            (Task 1: thêm lượt model_text)
supabase/functions/ai-assistant/model/config.ts  config_test.ts  (Task 1: tạo)
supabase/functions/ai-assistant/orchestrator.ts  orchestrator_test.ts   (Task 1: history ⇒ model_text; nhãn log)
supabase/functions/ai-assistant/model/claude_client.ts  claude_client_test.ts   (Task 2: tạo)
supabase/functions/ai-assistant/deno.lock                        (Task 2)
supabase/functions/ai-assistant/handler.ts  index.ts  handler_test.ts   (Task 3)
supabase/functions/ai-assistant/model/gemini_client.ts  gemini_client_test.ts   (Task 3: XOÁ)
scripts/ai/run_eval.ts                                            (Task 4: thêm cột thời gian)
docs/refactor/plans/AI/AI-0-yeu-cau.md, AI-4-truy-van-sql.md, PLAN.md   (Task 4)
```

---

### Task 1: Lượt chữ `model_text` + cấu hình Claude

**Files:** Modify `model/model_client.ts`, `orchestrator.ts`, `orchestrator_test.ts`; Create `model/config.ts`, `model/config_test.ts`.

**Interfaces — Produces:**
```ts
// model/model_client.ts — thêm vào union ModelTurn
| { role: 'model_text'; text: string }        // lượt trả lời cũ trong history (chỉ chữ)

// model/config.ts
export type Effort = 'low' | 'medium' | 'high'
export type ModelConfig = { apiKey: string; model: string; effort: Effort }
export const DEFAULT_CLAUDE_MODEL = 'claude-haiku-5-5'
/** null ⇒ thiếu ANTHROPIC_API_KEY (handler log lỗi cấu hình, trạng thái loi). */
export function modelConfigFromEnv(getEnv: (k: string) => string | undefined): ModelConfig | null
```
`orchestrator.ts`: lượt `assistant` của `history` ⇒ `{ role: 'model_text', text }` (thay cho khối `parts` kiểu Gemini); đổi nhãn log `ai-trace gemini …` ⇒ `ai-trace model …`.

- [ ] **Step 1: Test** `model/config_test.ts`:
  - `default_haiku_low`: env `{ ANTHROPIC_API_KEY: 'k' }` ⇒ `{ apiKey: 'k', model: 'claude-haiku-5-5', effort: 'low' }`.
  - `overrides`: `CLAUDE_MODEL=claude-sonnet-5-5`, `CLAUDE_EFFORT=medium` ⇒ dùng đúng hai giá trị.
  - `bad_effort_falls_back_low`: `CLAUDE_EFFORT=max` ⇒ `effort: 'low'`.
  - `missing_key_null`: không có `ANTHROPIC_API_KEY` ⇒ `null`.
- [ ] **Step 2: Test** `orchestrator_test.ts` `history_assistant_is_text_turn`: history `[user 'a', assistant 'b']` ⇒ `model.requests[0].turns` bắt đầu bằng `{ role: 'user', text: 'a' }, { role: 'model_text', text: 'b' }`.
- [ ] **Step 3: Viết code** theo Interfaces.
- [ ] **Step 4:** `deno test --no-check -A .` ⇒ xanh (Gemini còn nguyên ở task này; `gemini_client.ts` chưa map `model_text` — không sao, xoá ở Task 3).

---

### Task 2: `ClaudeClient`

**Files:** Create `model/claude_client.ts`, `model/claude_client_test.ts`; Modify `deno.lock`.

**Interfaces:**
- Consumes: `ModelClient`, `ModelTurn` (gồm `model_text`), `ToolDeclaration`, `ModelResult`, `ModelBusyError`, `ModelError` (`model/model_client.ts`); `ModelConfig` (`model/config.ts`).
- Produces:
  ```ts
  export class ClaudeClient implements ModelClient {
    constructor(o: ModelConfig & { fetch?: typeof fetch })  // fetch truyền vào SDK (test)
  }
  ```
  `generate()` trả `{ kind: 'tool_calls', calls, raw: response.content, usage }` khi có khối `tool_use` (bất kể có chữ đi kèm), ngược lại `{ kind: 'text', text: <nối các khối text>, raw: response.content, usage }`. `usage.inputTokens` = `input_tokens + cache_read_input_tokens + cache_creation_input_tokens`, `outputTokens` = `output_tokens`.
- Ánh xạ lượt: `user` ⇒ `{ role: 'user', content: text }`; `model_text` ⇒ `{ role: 'assistant', content: text }`; `model` ⇒ `{ role: 'assistant', content: raw }`; `tool_results` ⇒ một tin `user` gồm các `tool_result`, `tool_use_id` theo thứ tự các khối `tool_use` trong lượt `model` liền trước (Global Constraints).

- [ ] **Step 1: Test** `model/claude_client_test.ts` (fetch giả trả JSON Messages API, ghi lại body từng request):
  - `claude_request_shape`: body có `model: 'claude-haiku-5-5'`, `output_config: { effort: 'low' }`, `cache_control: { type: 'ephemeral' }`, `tools[0].input_schema` = `parameters` của khai báo, `system` = lời dặn; **không** có `temperature`, `thinking`.
  - `claude_text_answer`: phản hồi `[{ type: 'text', text: 'Chào' }]`, `stop_reason: 'end_turn'` ⇒ `{ kind: 'text', text: 'Chào' }`.
  - `claude_text_and_tool_use_is_tool_calls` (Review Focus 3): `[text 'Để mình xem', tool_use { id: 't1', name: 'tim_kiem', input: { tu_khoa: 'a' } }]` ⇒ `kind: 'tool_calls'`, `calls = [{ name: 'tim_kiem', args: { tu_khoa: 'a' } }]`, `raw` là nguyên mảng.
  - `claude_tool_results_match_ids` (Review Focus 1): lượt `model` có `tool_use` `t1`, `t2` + `tool_results` 2 phần tử ⇒ request kế tiếp có tin `assistant` đúng nguyên văn (kể cả một khối `{ type: 'thinking', thinking: '', signature: 's' }` đặt sẵn) và tin `user` với `tool_use_id` `t1`, `t2` đúng thứ tự, `content` là JSON chuỗi.
  - `claude_maps_model_text` (Review Focus 2): `model_text 'b'` ⇒ `{ role: 'assistant', content: 'b' }`.
  - `claude_refusal_is_model_error` (Review Focus 4): `stop_reason: 'refusal'` ⇒ ném `ModelError`; `stop_reason: 'max_tokens'` không có `tool_use` ⇒ ném `ModelError`.
  - `claude_429_529_busy`: fetch trả 429 hai lần (hết lượt gọi lại) ⇒ `ModelBusyError`; 529 ⇒ `ModelBusyError`; 400 ⇒ `ModelError`.
  - `claude_user_abort_rethrown` (Review Focus 5): `signal` đã huỷ ⇒ lỗi ném ra **không** phải `ModelError` / `ModelBusyError`.
- [ ] **Step 2: Viết** `model/claude_client.ts` (`new Anthropic({ apiKey, maxRetries: 1, fetch })`, gọi như Global Constraints; bắt lỗi theo lớp SDK: `APIUserAbortError` ⇒ ném lại; `RateLimitError`, `APIError` có `status === 529`, `APIConnectionTimeoutError` ⇒ `ModelBusyError`; còn lại ⇒ `ModelError(\`Claude HTTP ${status}\`)` hoặc tên lỗi). Cập nhật `deno.lock`.
- [ ] **Step 3:** `deno test --no-check -A .` ⇒ xanh; `deno check model/claude_client.ts` ⇒ không lỗi.

---

### Task 3: Nối Claude, xoá Gemini, chạy trên Dev

**Files:** Modify `handler.ts`, `index.ts`, `handler_test.ts`; Delete `model/gemini_client.ts`, `model/gemini_client_test.ts`.

- `HandlerDeps.makeModel` đổi thành `(cfg: ModelConfig) => ModelClient`; handler gọi `modelConfigFromEnv(deps.getEnv)` (null ⇒ `console.error('ANTHROPIC_API_KEY chưa được cấu hình')`, trạng thái `loi`, không gọi model); bỏ `DEFAULT_MODEL` Gemini; log `console.log('ai-trace model', cfg.model, cfg.effort)`. `index.ts`: `makeModel: (cfg) => new ClaudeClient(cfg)`.

- [ ] **Step 1: Test** `handler_test.ts`: sửa các ca đang dùng `GEMINI_API_KEY` / `GEMINI_MODEL` sang `ANTHROPIC_API_KEY` / `CLAUDE_MODEL` (giữ nguyên ý từng ca); thêm `claude_config_passed`: env `ANTHROPIC_API_KEY` ⇒ `makeModel` nhận `{ model: 'claude-haiku-5-5', effort: 'low' }`; `missing_anthropic_key_loi`: không có key ⇒ `trang_thai: 'loi'`, không gọi model.
- [ ] **Step 2:** Sửa `handler.ts`, `index.ts`; xoá hai tệp Gemini; `grep -rn -i gemini supabase/functions/ai-assistant` ⇒ không còn (trừ chú thích lịch sử nếu có lý do). `deno test --no-check -A .` ⇒ xanh.
- [ ] **Step 3 (người dùng, Dev):** `supabase functions deploy ai-assistant` (ghi `script size` vào Kết quả); `supabase secrets unset GEMINI_API_KEY GEMINI_MODEL`. Trên app hỏi: "xin chào", "Liệt kê các đơn hôm qua" (bấm một dòng ⇒ mở đúng đơn), "Khách nào chưa mua gì 30 ngày qua?", "Doanh thu hôm nay?". Dán các dòng `ai-trace` (phải có `ai-trace model claude-haiku-5-5 low`).
- [ ] **Step 4 (người dùng):** Console Anthropic → Usage: ghi số tiền đã tiêu sau 4 câu vào Kết quả.

---

### Task 4: Bộ câu thử `low` / `medium`, chốt effort, đóng AI-4 + AI-5

**Files:** Modify `scripts/ai/run_eval.ts` (cột thời gian ms mỗi câu + dòng tổng); `docs/refactor/plans/AI/AI-0-yeu-cau.md` (mục chọn model: Gemini ⇒ Claude Haiku 5.5, lý do; mọi chỗ ghi `GEMINI_*`), `AI-4-truy-van-sql.md` (Review R6 đóng bằng bộ câu này), `docs/refactor/PLAN.md` (dòng AI-5, AI-4).

- [ ] **Step 1:** `run_eval.ts` đo `Date.now()` quanh mỗi `ask(...)` (cả các câu `truoc`), in cột `ms` và dòng `Thời gian: TB … ms, chậm nhất … ms (câu #…)`.
- [ ] **Step 2 (người dùng, Dev):** seed cửa hàng Demo AI nếu chưa có (`supabase db query --linked -f scripts/ai/seed_demo_sales.sql`); chạy `deno run --allow-env --allow-net --allow-read scripts/ai/run_eval.ts scripts/ai/eval_questions_ai4.json` với effort mặc định (`low`), dán bảng. Rồi `supabase secrets set CLAUDE_EFFORT=medium`, chạy lại, dán bảng. Ghi tiền đã tiêu mỗi lượt (Console → Usage).
- [ ] **Step 3: Chốt:** chọn effort **thấp nhất** có nhóm A–F ≥ 80% và G = 100%; đặt `CLAUDE_EFFORT` theo đó (hoặc `supabase secrets unset CLAUDE_EFFORT` để về `low`). Cả hai < 80% ⇒ **dừng**, ghi vào Kết quả, bàn nâng `CLAUDE_MODEL=claude-sonnet-5-5` + `CLAUDE_EFFORT=medium`. Câu sai vì mô tả view / lời dặn ⇒ sửa như AI-4 Task 5 Step 3.
- [ ] **Step 4:** Cập nhật AI-0, AI-4 (R6), PLAN.md. Báo cáo đồ án ghi: dữ liệu câu hỏi và kết quả truy vấn gửi tới Anthropic (đã lọc số điện thoại / email / địa chỉ).

---

## Kiểm tra (tổng)
- [ ] `deno test --no-check -A .` xanh (gồm `config_test.ts`, `claude_client_test.ts`); không còn tệp / biến Gemini
- [ ] Trên Dev: 4 câu Task 3 đúng, log có `ai-trace model claude-haiku-5-5 low`
- [ ] Bộ 45 câu: A–F ≥ 80%, G 100% ở effort đã chốt; thời gian TB và chậm nhất ghi vào Kết quả

## Rủi ro / lưu ý
- **Chỉ một nhà cung cấp:** Anthropic sự cố ⇒ trợ lý "bận / lỗi" cho tới khi hết sự cố; muốn có lại Gemini phải khôi phục từ git (`git show HEAD:supabase/functions/ai-assistant/model/gemini_client.ts`).
- **Gói `npm:@anthropic-ai/sdk` trong Edge:** kích thước / thời gian khởi động tăng — xem `script size` khi deploy; quá lớn ⇒ báo lại, bàn gọi REST trực tiếp.
- **Hết tiền (5 USD, auto-reload tắt):** API trả lỗi thanh toán ⇒ trợ lý báo "lỗi". Kiểm số dư trước buổi bảo vệ; credits hết hạn 1 năm sau ngày nạp.
- **Effort `low` viết SQL kém** ⇒ Task 4 đo, nâng `medium`.
- **Dữ liệu gửi sang Anthropic** thay vì Google — ghi vào báo cáo.

## Kết quả
- **Task 1 ✅** `model/config.ts` + `config_test.ts` (4 ca); lượt `model_text`; orchestrator map history ⇒ `model_text`, nhãn log `ai-trace model`.
- **Task 2 ✅** `model/claude_client.ts` + `claude_client_test.ts` (8 ca xanh); `deno check` sạch. **Ruling:** ghim `@anthropic-ai/sdk@1.8.0` thay vì 1.9.0 (mới nhất, đăng 2026-11-16 <24 giờ nên Deno chặn theo `minimum dependency age`) — nâng lên 1.9.0 sau khi quá 24 giờ nếu muốn; chi phí nếu sai: không (cùng major). `deno.lock` đã cập nhật.
- **Task 3 (phần code) ✅** handler/index dùng `modelConfigFromEnv` + `ClaudeClient`; xoá `gemini_client.ts` + test; `handler_test.ts` đổi sang `ANTHROPIC_API_KEY` (+ `claude_config_passed`, `missing_anthropic_key_loi`). `deno test --no-check -A .` ⇒ 99 passed, 0 failed. Chỉ còn chữ "Gemini" trong tài liệu lịch sử. **Chờ người dùng:** deploy (ghi `script size`), `secrets unset GEMINI_*`, 4 câu thử trên app, số tiền Usage.
- **Task 4:** Step 1 ✅ (`run_eval.ts` có cột `ms` + dòng Thời gian; bỏ chờ 5 giây của Gemini, còn 1 giây). AI-0 đã thêm ghi chú đổi model; PLAN.md cập nhật trạng thái. **Chờ người dùng:** Step 2–3 (chạy eval `low` / `medium`, chốt effort, đóng R6 của AI-4).
- **Task 3 (Dev) 2026-11-18:** deploy `script size: 2.5 MB` (trước 808 kB, do SDK); `secrets unset GEMINI_API_KEY GEMINI_MODEL` ✅. Log `ai-trace model claude-haiku-5-5 low`; mỗi lần gọi model 1,1–3,3 giây, `truy_van` 27–94 ms. Usage Console: **0,01 USD sau ~10 câu** (≈ 0,001 USD/câu). Sửa trong lúc chạy: bộ lọc chống bịa số chặn nhầm "VET45" (bỏ tên trước khi dò, test `chitchat_mentions_vet45_not_blocked`); quy tắc 3 câu chào không chứa chữ số; quy tắc 11 chỉ trả lời câu mới nhất (Haiku chạy lại câu cũ); mô tả `truy_van` **LUÔN** chọn cột khoá. Còn mở: bấm dòng đơn từ `/ask` ⇒ màn đỏ Flutter (trùng khoá trang ở Navigator gốc) — đang khoanh vùng, không thuộc Edge Function.

## Review

### R1 — 2026-11-17 (Claude, đọc code + `deno test`: 99 passed / 0 failed; `deno check index.ts` sạch)

**Đúng plan:** `config.ts` (mặc định `claude-haiku-5-5` / `low`, effort lạ ⇒ `low`, thiếu key ⇒ `null`); `ClaudeClient` gửi đúng `output_config.effort`, `cache_control`, `input_schema`, không `temperature` / `thinking`; lượt `model` gửi lại nguyên văn; `tool_use_id` ghép theo thứ tự; `refusal` / `max_tokens` không có `tool_use` ⇒ `ModelError`; 429 / 529 / quá giờ ⇒ `ModelBusyError`; huỷ ⇒ ném lại (handler xếp "chậm" nhờ `Promise.race` với `TimeoutError`); đủ 8 ca test Claude + 4 ca config + 2 ca handler; Gemini đã xoá; `run_eval.ts` có cột `ms`. Ruling ghim SDK `1.8.0` (1.9.0 chưa qua tuổi tối thiểu của Deno) chấp nhận.

**Phải sửa**
1. **MED — lịch sử có thể làm Claude trả 400 ở mọi câu sau một lần lỗi.** App (`ask_assistant_cubit.dart:76-86`) **bỏ** các bong bóng lỗi khỏi `history` và cắt `maxHistoryTurns` lượt cuối ⇒ server có thể nhận (a) hai lượt `user` liền nhau (câu bị lỗi + câu mới), (b) lịch sử bắt đầu bằng lượt `assistant` sau khi cắt, (c) lượt `assistant` chữ rỗng. Gemini chịu được; Messages API của Claude yêu cầu tin đầu là `user` và không nhận khối chữ rỗng (hai `user` liền nhau tuỳ phiên bản API — không nên dựa vào). Hậu quả: sau một lần "bận / lỗi", **mọi câu tiếp theo trong cùng cuộc trò chuyện** có thể ra "Có lỗi khi trả lời". Sửa trong `toMessages` (`claude_client.ts`) — chỉ áp cho các lượt chữ (`user`, `model_text`), không đụng `model` / `tool_results`: bỏ lượt chữ rỗng (sau `trim`); bỏ các lượt `model_text` đứng trước lượt `user` đầu tiên; gộp các lượt chữ **cùng vai liền nhau** thành một (nối bằng `\n\n`). Test `claude_history_normalized`: turns `[model_text 'x', user 'a', user 'b', model_text '', model_text 'c', user 'q']` ⇒ messages `[{user,'a\n\nb'}, {assistant,'c'}, {user,'q'}]`.

**Nên sửa (không chặn)**
2. LOW — `ModelError(\`Claude HTTP ${e.status ?? e.name}\`)`: hết tiền và sai tham số đều ra "Claude HTTP 400", khó phân biệt khi xem log. Thêm `e.type` của SDK (vd. `invalid_request_error`, `billing_error`, `overloaded_error`) vào thông báo: `Claude HTTP ${status} ${type}`. Không chứa câu hỏi / key nên log được.

**Chưa có bằng chứng (người dùng chạy):** Task 3 Step 3–4 (deploy + `script size`, `secrets unset GEMINI_API_KEY GEMINI_MODEL`, 4 câu trên app + dòng `ai-trace model claude-haiku-5-5 low`, tiền Usage), Task 4 Step 2–3 (eval `low` / `medium`).

**Đã sửa (Claude, theo yêu cầu người dùng 2026-11-17):** 1 (`pushText` trong `claude_client.ts`: bỏ chữ rỗng, bỏ câu trả lời đứng trước câu hỏi đầu, gộp lượt chữ cùng vai liền nhau; test `claude_history_normalized`) và 2 (thông báo lỗi kèm `e.type`; test `claude_error_type_in_message`). `deno test`: 101 passed / 0 failed; `deno check` sạch.

**Kết luận R1:** chưa đóng — sửa 1 (và 2 nếu muốn), chạy `deno test`, rồi deploy và gửi bằng chứng Dev ⇒ R2.
