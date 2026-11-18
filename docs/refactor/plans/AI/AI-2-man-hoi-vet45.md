# AI-2 — Màn "Hỏi VET45" (iPhone + web)

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development hoặc superpowers:executing-plans. Dự án này **người dùng tự code, Claude review ở phiên khác** (xem [README plans](../README.md)); các bước dùng checkbox để người dùng tick.

> Tích hợp AI · plan **AI-2** của [PLAN.md](../../PLAN.md) mục "Tích hợp AI"
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-16) | Làm ✅ (2026-11-17; còn vài mục kiểm tay ghi ở Ghi chú) | Review ⬜
> Spec: [`docs/superpowers/specs/2026-11-16-ai-2-man-hoi-vet45-design.md`](../../../superpowers/specs/2026-11-16-ai-2-man-hoi-vet45-design.md) (người dùng duyệt 2026-11-16) · Yêu cầu: [AI-0](AI-0-yeu-cau.md) mục 4–8 · Backend: [AI-1](AI-1-backend.md) (R4 ✅)

**Goal:** Màn chat `/ask` gọi Edge Function `ai-assistant`, hiện câu trả lời + bảng (thẻ trên iPhone, bảng thật trên web), đủ các trạng thái, bấm dòng mở sản phẩm / khách / đơn.

**Architecture:** Feature mới `features/assistant/` theo nền `data/ logic/ presentation/`. `AssistantRepository` gọi `functions.invoke`, `AskAssistantCubit` giữ hội thoại trong bộ nhớ, trang `/ask` dựng bong bóng + bảng từ `khoi`. Số trong bảng chỉ được **định dạng**, không tính.

**Tech Stack:** Flutter, `flutter_bloc`, `get_it`, `go_router`, `supabase` (`FunctionsClient`), `vet45_design_system`, `mocktail`.

## Global Constraints

- Không sửa `home_tab_page.dart` hay bất kỳ widget Home nào (người dùng tự gắn lối vào sau).
- Chữ trên màn **nguyên văn** [AI-0 mục 8](AI-0-yeu-cau.md); câu trả lời lỗi / từ chối **lấy từ `cau_tra_loi` backend trả về**, app không tự viết lại (trừ mất mạng và lỗi HTTP — xem Task 2).
- Câu hỏi 1–500 ký tự; gửi kèm tối đa 6 lượt gần nhất, chỉ chữ thuần `{role, text}`.
- `tenant_id` lấy **tại lúc gửi** từ `getIt<SessionController>().requireTenantId()`, không lưu trong cubit.
- Không lưu hội thoại ra đĩa; đóng màn là quên.
- Chỉ dùng token / widget của `vet45_design_system` (không màu / cỡ chữ gõ cứng).
- UI Flutter **trích nguyên code prototype** đã duyệt (Task 1) vào plan + bảng ánh xạ widget/token trước khi code (quy ước PLAN.md "Cách làm việc").
- Không chạy lệnh DB; app chỉ gọi Edge Function đã có.

## Review Focus

1. `khoi` rỗng, hoặc bảng có `dong` rỗng → hiện bong bóng chữ, không vẽ bảng trống / tiêu đề lẻ loi.
2. Ô số `null`, số âm (lãi gộp âm, `-990.000đ`), chuỗi lạ trong cột số → hiện `—` hoặc nguyên văn, không crash, không "NaN".
3. Tên sản phẩm rất dài / nhiều dòng, màn rộng 320 → cắt chữ (ellipsis), không tràn.
4. Bấm Gửi hai lần liên tiếp, hoặc đóng màn khi đang chờ → chỉ một lời gọi; không `emit` sau khi cubit đã đóng.
5. Đổi cửa hàng giữa phiên / hết phiên đăng nhập (HTTP 401) → không hỏi nhầm cửa hàng cũ; báo lỗi, giữ câu hỏi để Thử lại.

---

## Cấu trúc tệp

| Tệp | Việc |
|---|---|
| `docs/refactor/plans/AI/prototype/ask-vet45.html` + `img/AI-2/` | Prototype + ảnh (Task 1) |
| `lib/features/assistant/data/models/assistant_reply.dart` | `AssistantReply`, `AssistantStatus`, `TableBlock`, `TableColumn`, `TableRow`, `OpenTarget` |
| `lib/features/assistant/data/assistant_repository.dart` | Gọi Edge Function |
| `lib/features/assistant/logic/ask_assistant_state.dart`, `ask_assistant_cubit.dart` | Hội thoại |
| `lib/features/assistant/presentation/assistant_cell_format.dart` | Định dạng ô theo `kieu` |
| `lib/features/assistant/presentation/assistant_open_target.dart` | `OpenTarget` → đường dẫn |
| `lib/features/assistant/presentation/widgets/…` | Bong bóng, bảng (thẻ / bảng), ô nhập, gợi ý, chân màn |
| `lib/features/assistant/presentation/pages/ask_assistant_page.dart` | Trang |
| `lib/features/assistant/presentation.dart`, `data.dart`… | Barrel theo kiểu các feature khác |
| `lib/core/di/injection.dart` | Đăng ký `AssistantRepository` |
| `lib/core/router/app_router.dart` | Route `/ask` (toàn màn, trước `ShellRoute`) |
| `test/features/assistant/{data,logic,presentation}/…` | Test |

---

### Task 1: Prototype HTML — **cổng duyệt, chưa duyệt thì chưa làm Task 5**

Claude dựng (không phải code sản phẩm), người dùng duyệt. Task 2–4 không phụ thuộc prototype, làm song song được.

**Files:** Create `docs/refactor/plans/AI/prototype/ask-vet45.html`, `docs/refactor/plans/AI/img/AI-2/proto-{iphone,web}-<trạng thái>.png`.

- [x] **Step 1:** Dựng HTML tĩnh dùng giá trị token thật của `vet45_design_system` (màu, cỡ chữ, khoảng cách) cho các trạng thái: màn trống + gợi ý; hỏi đáp có bảng 4 cột (Sản phẩm | Tồn | Còn bán (ngày) | Nên nhập — dữ liệu mẫu); đang trả lời; lỗi + Thử lại; hết lượt (ô nhập khoá); không có quyền. Mỗi trạng thái ở 390 (thẻ) và 1280 (bảng thật).
- [x] **Step 2:** Chụp ảnh, đặt vào `img/AI-2/`.
- [x] **Step 3 (người dùng):** Duyệt ảnh → ghi vào mục "Ghi chú duyệt prototype" cuối file này.
- [x] **Step 4:** Chép **nguyên** hàm dựng + mọi rule CSS của các class dùng (kèm `file:dòng`, giá trị token đã quy ra số) vào mục "Code prototype" cuối file, cùng bảng **phần tử → widget Flutter / token**.

---

### Task 2: Model + `AssistantRepository`

**Files:** Create `lib/features/assistant/data/models/assistant_reply.dart`, `lib/features/assistant/data/assistant_repository.dart`; Test `test/features/assistant/data/assistant_repository_test.dart`; Modify `lib/core/di/injection.dart`.

**Interfaces — Produces:**
```dart
enum AssistantStatus { ok, troChuyen, ngoaiPhamVi, chuaHoTro, tuChoi, khongQuyen, loi, hetLuot, ban }
enum ColumnKind { chu, tien, so, ngay, phanTram }
class OpenTarget { final String loai; final String id; }           // loai: san_pham | khach_hang | don_ban
class TableColumn { final String key; final String name; final ColumnKind kind; }
class TableRow { final Map<String, Object?> cells; final OpenTarget? open; }
class TableBlock { final String title; final List<TableColumn> columns; final List<TableRow> rows; }
class AssistantReply { final AssistantStatus status; final String text; final List<TableBlock> blocks; final int? remaining; final List<String> tools; }
class AssistantTurn { final String role; final String text; }       // 'user' | 'assistant'
class AssistantRepository {
  AssistantRepository({required FunctionsClient functions});
  Future<AssistantReply> ask({required String tenantId, required String question, required List<AssistantTurn> history});
}
```
JSON khớp `supabase/functions/ai-assistant/types.ts` (`trang_thai`, `cau_tra_loi`, `khoi[].{loai,tieu_de,cot[].{khoa,ten,kieu},dong[].{o,mo}}`, `luot_con_lai`, `cong_cu`).

- [x] **Step 1: Test (mẫu `test/features/auth/data/invitation_acceptance_repository_test.dart`, `_MockFunctions extends Mock implements FunctionsClient`):**
  - `ask sends snake_case body` — `functions.invoke('ai-assistant', body: {'tenant_id': T, 'question': Q, 'history': [{'role':'user','text':'a'}]})`.
  - `parses all 9 trang_thai values` (bảng ánh xạ chuỗi → enum).
  - `parses table block with open target and null cell`.
  - `unknown trang_thai falls back to loi`; `missing khoi → empty list`.
  - `FunctionsFetchException → AppException(code: AppErrorCode.network)`.
  - `FunctionException status 401 → AppException(code: AppErrorCode.authRequired)`; status 400/405/500 → `AppErrorCode.unknown`.
- [x] **Step 2:** `flutter test test/features/assistant/data` → FAIL (chưa có file).
- [x] **Step 3:** Cài model (`factory fromJson`) và `ask` theo chữ ký trên; bắt lỗi giống `registerAndAccept` ở `invitation_acceptance_repository.dart:50-62`. Giá trị ô giữ nguyên (`num` / `String` / `null`), **không đổi kiểu**.
- [x] **Step 4:** Đăng ký `AssistantRepository(functions: supabaseModule.client.functions)` trong `injection.dart` cạnh `InvitationAcceptanceRepository` (dòng ~169).
- [x] **Step 5:** Test PASS → commit `feat(ai): AssistantRepository gọi ai-assistant`.

---

### Task 3: `AskAssistantCubit`

**Files:** Create `logic/ask_assistant_state.dart`, `logic/ask_assistant_cubit.dart`; Test `test/features/assistant/logic/ask_assistant_cubit_test.dart` (`bloc_test` nếu repo đã dùng, nếu không dùng `expectLater(cubit.stream, …)`).

**Interfaces — Consumes:** `AssistantRepository.ask`. **Produces:**
```dart
sealed class ChatMessage { }
class UserMessage extends ChatMessage { final String text; }
class AssistantMessage extends ChatMessage { final AssistantReply reply; }
class ErrorMessage extends ChatMessage { final bool offline; }      // mất mạng / lỗi HTTP; có nút Thử lại
class AskAssistantState { final List<ChatMessage> messages; final bool waiting; final bool locked; final int? remaining; }
class AskAssistantCubit extends Cubit<AskAssistantState> {
  AskAssistantCubit({required AssistantRepository repository, required String Function() tenantId});
  static const maxQuestionLength = 500;
  static const maxHistoryTurns = 6;
  Future<void> send(String question);   // trim; rỗng / >500 / đang chờ / locked → bỏ qua
  Future<void> retry();                 // gửi lại câu cuối, không thêm bong bóng người dùng mới
}
```
Quy tắc: `locked = true` khi `status == hetLuot`; `remaining` = `reply.remaining` mới nhất; history = các `UserMessage` và `AssistantMessage.reply.text` (bỏ `ErrorMessage`), cắt 6 cuối, **không gồm câu đang hỏi**.

- [x] **Step 1: Test:** `send adds user message then assistant message`; `ignores empty / whitespace / 501-char question`; `ignores second send while waiting` (repository gọi đúng 1 lần — Review Focus 4); `history is last 6 text turns and excludes errors`; `tenantId read at each send` (đổi giá trị trả về giữa hai lần gửi → body dùng giá trị mới — Review Focus 5); `hetLuot locks further sends`; `khongQuyen does not lock`; `AppException(network) → ErrorMessage(offline: true)`; `AppException(authRequired) → ErrorMessage` và câu hỏi giữ cho `retry`; `retry resends last question without a new user bubble`; `close while waiting → no emit after close`.
- [x] **Step 2:** Chạy → FAIL.
- [x] **Step 3:** Cài cubit theo chữ ký; trước mỗi `emit` sau `await` kiểm tra `isClosed`.
- [x] **Step 4:** PASS → commit `feat(ai): AskAssistantCubit`.

---

### Task 4: Định dạng ô + đường dẫn mở màn (hàm thuần)

**Files:** Create `presentation/assistant_cell_format.dart`, `presentation/assistant_open_target.dart`; Test `test/features/assistant/presentation/assistant_cell_format_test.dart`, `assistant_open_target_test.dart`.

**Interfaces — Produces:**
```dart
String formatAssistantCell(ColumnKind kind, Object? value);
String? assistantOpenLocation(OpenTarget target);
```
- [x] **Step 1: Test `formatAssistantCell`:**
  - `tien`: `1245000 → '1.245.000đ'`, `-990000 → '-990.000đ'` (dùng `MoneyFormatter.formatMinor`, làm tròn về số nguyên).
  - `so`: `1234 → '1.234'`, `12.5 → '12,5'` (tối đa 1 số lẻ, dấu phẩy thập phân).
  - `phan_tram`: `32.5 → '32,5%'`, `-4 → '-4%'`.
  - `ngay`: `'2026-11-16' → '16/11/2026'`; chuỗi sai dạng → trả nguyên văn.
  - `chu`: nguyên văn.
  - `null` (mọi kind) → `'—'`; kiểu sai (chuỗi trong cột `so`) → nguyên văn, không throw (Review Focus 2).
- [x] **Step 2: Test `assistantOpenLocation`:** `san_pham,id → '/products/items/<id>/view'`; `khach_hang → '/partner/<id>'`; `don_ban → '/sales/orders/<id>'`; `loai` lạ hoặc id rỗng → `null`.
- [x] **Step 3:** Chạy → FAIL → cài → PASS. Hàm **chỉ định dạng**, không phép tính nào trên số.
- [x] **Step 4:** Commit `feat(ai): định dạng ô và đường dẫn mở màn`.

---

### Task 5: Màn + bảng hai dạng + route (**sau khi Task 1 được duyệt**)

**Files:** Create `presentation/widgets/{assistant_message_bubble,assistant_result_table,assistant_result_cards,assistant_composer,assistant_suggestions,assistant_footer}.dart`, `presentation/pages/ask_assistant_page.dart`; Modify `app_router.dart` (route `GoRoute(path: '/ask', name: 'assistant.ask', …)` khai báo cạnh các route toàn màn trước `ShellRoute`, mẫu `/products/items/new` dòng ~318; `BlocProvider(create: AskAssistantCubit(repository: getIt<AssistantRepository>(), tenantId: () => getIt<SessionController>().requireTenantId()))`); Test `test/features/assistant/presentation/ask_assistant_page_test.dart`.

- [x] **Step 0:** Đọc mục "Code prototype" + bảng ánh xạ của Task 1; không có thì dừng.
- [x] **Step 1: Widget test (cubit giả / repository giả):**
  - Màn trống hiện lời chào + 4 câu gợi ý (AI-0 mục 8); bấm gợi ý → gọi `send` với đúng câu đó.
  - Mỗi `AssistantStatus` hiện `reply.text`; `hetLuot` → ô nhập `enabled: false` và chữ hết lượt; `ErrorMessage` hiện nút **Thử lại** → gọi `retry`.
  - `waiting` → hiện "Đang trả lời…", sau 8 giây "Vẫn đang xử lý, chờ chút nhé…" (đổi 2026-11-17: câu chào cũng hiện chờ, không nên nói "xem số liệu"), nút Gửi vô hiệu.
  - Ô nhập có `maxLength: 500`.
  - Bảng: ở khung rộng 1280 render `VTable` có tiêu đề cột và căn phải cột `tien/so/phan_tram`; ở 390 render từng thẻ (cột đầu = tiêu đề thẻ, còn lại "nhãn: giá trị"); chọn dạng bằng `LayoutBuilder` theo bề rộng **khung bảng** ≥ `VBreakpoints.tablet` (600) *(điều chỉnh so với spec: dùng token có sẵn thay cho 900)*.
  - Bấm dòng / thẻ có `open` hợp lệ → `context.push(<location>)`; dòng không `open` hoặc location `null` → không bấm được.
  - `khoi` rỗng hoặc `dong` rỗng → không vẽ bảng (Review Focus 1); tên 120 ký tự ở rộng 320 → không overflow (Review Focus 3).
  - `remaining ≤ 10` hiện số lượt còn lại, lớn hơn thì ẩn.
- [x] **Step 2:** Chạy → FAIL.
- [x] **Step 3:** Cài trang + widget theo code prototype đã trích (Step 0). `ListView` tự cuộn xuống tin mới nhất; chân màn đúng chữ AI-0 mục 8.
- [x] **Step 4:** PASS; `flutter analyze` không lỗi mới.
- [x] **Step 5:** Commit `feat(ai): màn Hỏi VET45`.

---

### Task 6: Kiểm tra đầu–cuối + audit

- [ ] **Step 1:** Golden / ảnh Flutter ở 390 và 1280 cho từng trạng thái, đặt `img/AI-2/flutter-*.png`; so với `proto-*.png`, ghi lệch (nếu có) vào Review.
- [ ] **Step 2 (người dùng chạy, local):** bật Edge Function theo [AI-1 mục Kết quả](AI-1-backend.md) rồi mở `/ask` trên iPhone simulator và web; hỏi 5 câu: "Hôm nay bán được bao nhiêu?", "5 mặt hàng bán chạy tháng này?" (bấm dòng → mở sản phẩm), "Lãi gộp tháng này?" bằng **tài khoản thu ngân** (→ không có quyền), "Mai trời mưa không?", "Xoá đơn HD0012". Đối chiếu số trong bảng với màn tương ứng.
- [ ] **Step 3:** Tắt mạng rồi hỏi → "Không có kết nối mạng." + Thử lại; bật lại → Thử lại ra kết quả.
- [ ] **Step 4:** `/impeccable audit` trên màn; sửa mục nghiêm trọng.
- [ ] **Step 5:** `flutter analyze`, `flutter test test/features/assistant`, so `TEST-BASELINE.md` (không lỗi thêm); cập nhật dòng AI-2 ở PLAN.md.

---

## Kiểm tra (tổng)
- [ ] `flutter analyze` không lỗi mới
- [ ] `flutter test test/features/assistant` xanh; toàn bộ test không thêm lỗi so `TEST-BASELINE.md`
- [ ] Chạy thật 5 câu ở Task 6 trên iPhone + web
- [ ] Không có thay đổi nào ở `home_tab_page.dart`

## Rủi ro / lưu ý
- Route khách `/partner/:partnerId` nằm trong `ShellRoute`; `context.push` từ màn toàn màn `/ask` có thể mở trong shell — **kiểm tra tay ở Task 6** trên cả hai nền tảng, nếu sai chuyển sang `context.go` hoặc đưa route khách ra ngoài shell.
- Backend đối khi trả HTTP lỗi (400/401/405) thay vì `trang_thai`; app đã xử lý ở Task 2.
- Điểm lệch spec: ngưỡng bảng/thẻ dùng 600 theo khung bảng (token `VBreakpoints.tablet`), không phải 900; dòng `khach_hang` / `don_ban` **không ẩn** vì cả hai route đã có sẵn.

## Ghi chú duyệt prototype
Người dùng duyệt 2026-11-16 (12 ảnh `img/AI-2/proto-*.png`, 6 trạng thái × 390/1280).

## Code prototype
Nguồn: `prototype/ask-vet45.html` (CSS dòng 7–38, hàm dựng `table()` / `U` / `A` và ghép màn ở phần `<script>`). Prototype dùng giá trị token thật; bảng ánh xạ sang Flutter:

| Phần tử prototype | Widget Flutter | Token |
|---|---|---|
| `.bar` thanh tiêu đề | `VAppBar(title: 'Hỏi VET45')` | — |
| `.screen` nền | `Scaffold(backgroundColor: c.background)` | neutral50 |
| `.body` (padding 16, max 840) | `ListView(padding: VSpacing.md)` trong `ConstrainedBox(maxWidth: 840)` | space4 |
| `.u` bong bóng người dùng | `Container` + `VText(color: c.textInverse)` | `c.primary`, `VRadius.r12` |
| `.a` bong bóng trợ lý / `.err` / `.warn` | `_Bubble` | surface+borderDefault / dangerBg+danger / warningBg+warning |
| `.chip` gợi ý | `AssistantSuggestions` (InkWell + Container pill, cao ≥ 44) | `VRadius.pill`, `c.borderInput`, `VSpacing.minTouchTarget` |
| `.btn` Thử lại | `VButton(variant: secondary)` | — |
| `table` / `th` / `td` | `VTable` (`VTableHeader.isNumeric`), cột đầu `FlexColumnWidth(3)` | — |
| `.card` / `.kv` | `_RowCard` (cột đầu = `headingH4`, còn lại `bodySmall` nhãn + giá trị) | `VRadius.card`, borderBrand nếu bấm được |
| `.comp` / `.inp` / `.send` | `VTextField` + `VButton.icon(VIcons.send)` | `c.surface` |
| `.foot` | `AssistantFooter` (`VTextVariant.caption`, `c.textMuted`) | — |

Mã Flutter tương ứng nằm ở `lib/features/assistant/presentation/widgets/*`.

## Ghi chú khi làm (rulings)
- `SessionController.requireTenantId()` là `Future<String>` → cubit nhận `Future<String> Function() tenantId` (plan ghi sync). Lỗi lấy tenant rơi vào nhánh `ErrorMessage`.
- `VTextField` không có `maxLength` → giới hạn 500 bằng `LengthLimitingTextInputFormatter`.
- Chữ "Còn N câu hỏi hôm nay." (khi `remaining ≤ 10`) do tôi đặt, AI-0 mục 8 chưa có.
- Task 6 Step 1 (golden `flutter-*.png`): **bỏ** theo quyết định của người dùng; đối chiếu bằng mắt khi chạy app thật (Step 2).
- Audit (Step 4, đọc từ mã nguồn, ~15/20): đã sửa 2 mục P1 — composer bị home indicator che (thêm `SafeArea`), nút Thử lại của lỗi cũ còn hoạt động sau khi hỏi tiếp (chỉ lỗi cuối có nút). Còn lại (P2/P3, chưa làm): thông báo cho VoiceOver khi có câu trả lời mới (`liveRegion`), cuộn tới đầu câu trả lời dài thay vì cuối, không chọn / sao chép được chữ trả lời, chưa có vòng xoay khi chờ.

- Lệch plan (theo yêu cầu người dùng 2026-11-17): thêm nút **Hỏi VET45** vào `home_tab_page.dart` để mở `/ask` (Global Constraints cấm sửa Home). Lối vào chính thức (ô "Sắp hết") vẫn để sau.
- Sửa `supabase/functions/ai-assistant/http.ts`: thêm `x-vet45-app` vào `Access-Control-Allow-Headers` (app gắn header này ở `main.dart`; thiếu thì web bị chặn CORS). Đã deploy lại lên dev.
- Chạy thật trên **web + Supabase dev** (2026-11-17): hỏi doanh thu hôm nay → ra số; hỏi "5 mặt hàng bán chạy" → ra bảng, tên sản phẩm bấm được. **Chưa kiểm:** iPhone (dạng thẻ), "Mai trời mưa không?", "Xoá đơn HD0012", tài khoản thu ngân (không có quyền), tắt mạng + Thử lại, bấm dòng mở sản phẩm, khách `/partner/:id` từ `/ask`.
- Góp ý cho AI-1: câu "5 mặt hàng bán chạy nhất" không nêu thời gian → Gemini trả "chưa ghi nhận dữ liệu hôm nay" rồi hỏi lại; nên mặc định tháng này.

## Review
<!-- Claude ghi sau khi người dùng code xong -->
- Ngày, commit được review:
- Kết quả:
- Góp ý:
