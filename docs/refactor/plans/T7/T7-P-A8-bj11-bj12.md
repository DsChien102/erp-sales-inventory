# T7-P · Gói A8 — viết lại code sạch BJ-11 Hủy & sửa sai, BJ-12 Khởi tạo tồn đầu kỳ

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ | Làm ✅ | Review ✅
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) Giai đoạn 1, gói A8 (mục 8.1). Ước lượng: **~2,5 ngày, 1 commit**, 6 chặng (0 → 5), golden kiểm sau mỗi chặng.
> Người làm: bạn. Review: phiên plan / review. Mẫu: `app/bj08.js` (cụm kiểm soát, `shared-control.js`), `app/bj10.js` (dựng lại màn UNKNOWN của `v350`); đoạn đo: [A1](T7-P-A1-bj04-bj05.md) mục 4.5.
> Làm **sau A7** (dùng `shared-control.js`, đã bỏ `render()` lúc nạp). Chặng 0 sửa hai chỗ A7 xoá nhầm — nếu A7 chưa commit, sửa luôn trong A7 rồi bỏ mục 4.1.b.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/`. Đo ngày 2026-10-17 trên working tree (A7 chưa commit) — chỉ neo theo chuỗi; chạy lại mục 2.8.

## 1. Mục tiêu

1. BJ-11 (UIF-11: SCR-048, 049, 052, 050, 051, 053) → `app/bj11.js`; BJ-12 (UIF-12: SCR-066…071) → `app/bj12.js`.
2. **Khôi phục** những gì gói trước làm mất (mục 2.6): listener "Correction & Recovery" của UIF-11/16/17 (mất từ A5), `render()` trong `crSwitchFlow` và trong hẹn giờ duyệt sửa sai (A7 xoá nhầm).
3. Helper `ac310*` mà BJ-11/12 dùng và **BJ khác cũng dùng** → `app/shared-control.js`; helper chỉ một BJ dùng → `bjNN.js`.
4. Gỡ phần BJ-11/12 khỏi `app.js` (đầu `core.js`), `v310`, `v350`, `v360` (toast).
5. `UIF-11`, `UIF-12` vào `ownedFlows`. **Giao diện và hành vi không đổi**, trừ hai sửa lỗi có chủ đích: khôi phục ở chặng 0 và nút "Từ chối" ở chặng 5 (mục 2.7).

Không làm: đổi thiết kế (Giai đoạn 2); phần BJ-16/17 của `v310` / `v350` (A10 — chặng 0 chỉ đặt lại listener của chúng vào `core.js`); `handoff-unknown` chung của `v350` (A10); CSS `.cr-*`, `.cf-*`, `.ac310-*` (A11); helper `cf*` / `cr*` mà BJ-15/16/17 còn dùng.

## 2. Bản đồ hiện trạng

### 2.1 Thứ tự nạp

`app.js` (state `cr11*` / `cf12*`, `cr11Operations`, `cf12Summary`; `render048CR11 … render053CR11`, `render066CF12 … render071CF12`; literal `renderers`; listener input / click UIF-12) → `v310` (`ac310BaseRenderers` chụp bản `app.js`; `ac310Render048…052`, `ac310Render066…070`, `ac310Cf12Review`, `ac310IssueRow`; `renderers["SCR-053"]` / `["SCR-071"]` = `ac310Base`) → `v350` (BJ-12: `.replace` thuộc tính 067 / 069 / 070, tự dựng 068 `CONTROL_TOTAL_MISMATCH`, `wrapUnknown` 066 / 071; BJ-16: chèn `IO-260904-021` vào `cr11Operations`; BJ-11: `.replace` 051 hai lần; listener `cf12-*`, `cr11-*`) → `v360` (toast 2 dòng, `v360RootScreens` / `v360ExitTargets`).

`v320`, `v351`, `legacy-*`: không có nhánh riêng cho BJ-11/12 (đo `grep` 2.8). `v361`, `v440`, `v470`: chạy chung trên mọi luồng chưa sở hữu → đo ở chặng 4.

### 2.2 Bản thắng — BJ-11

| Màn | Trạng thái | Chuỗi thật sự chạy |
|---|---|---|
| 048 | `READY` | `ac310Render048` |
| 048 | `LOADING`, `EMPTY`, `PERMISSION_DENIED`, `FILTER_EMPTY` | `ac310SanitizeMarkup(render048CR11)`; `FILTER_EMPTY` rơi vào dòng cuối `cr11ListRows()` (kiểu `io*` cũ, chip `ac321CanonicalChips`) |
| 049 | `READY`, `CORRECTABLE`, `CANCELABLE`, `UNKNOWN`, `BLOCKED_PHYSICAL_HANDOVER`, `TERMINAL` | `ac310Render049` |
| 049 | `LOADING`, `PERMISSION_DENIED` | `ac310SanitizeMarkup(render049CR11)` |
| 052 | `CANCEL_UNEXECUTED`, `CORRECTION_ROUTE`, `VALIDATION_ERROR` | `ac310Render052` |
| 052 | `DEPENDENCY_BLOCKED`, `PERIOD_POLICY_VIOLATION`, `PERMISSION_DENIED` | base `render052CR11` (sanitize) |
| 050 | `READY`, `VALIDATION_ERROR` | `ac310Render050` |
| 050 | `SOURCE_VERSION_STALE`, `CONFLICT`, `PERMISSION_DENIED` | base `render050CR11` (sanitize) |
| 051 | `READY`, `VALIDATION_ERROR` | `ac310Render051` → `v350` `.replace`: `approval-result`→`data-v350-action="cr11-approval-result"`, rồi `approve`→`cr11-approve`, `reject-confirm`→`cr11-reject-confirm` |
| 051 | `SELF_APPROVAL_NOT_ALLOWED`, `APPROVAL_ALREADY_DECIDED`, `PERMISSION_DENIED` | base `render051CR11` (sanitize) → cùng hai `.replace` của `v350` |
| 053 | mọi | base `render053CR11` (sanitize) |

### 2.3 Bản thắng — BJ-12

| Màn | Trạng thái | Chuỗi thật sự chạy |
|---|---|---|
| 066 | `READY`, `PENDING_APPROVAL`, `REJECTED`, `ACTIVE_RECONCILED` | `ac310Render066` |
| 066 | `UNKNOWN` | `v350UnknownResult` (qua `wrapUnknown`) — **không** qua `ac310SanitizeMarkup` |
| 066 | `LOADING`, `PERMISSION_DENIED`, `PREPARING` | base `render066CF12` (sanitize) |
| 067 | `READY`, `VALIDATION_ERROR` | `ac310Render067` → `.replace` `check`→`data-v350-action="cf12-check"` |
| 067 | `CONFLICT`, `LOCKED`, `PERMISSION_DENIED` | base (sanitize) |
| 068 | `CONTROL_TOTAL_MISMATCH` | `v350` tự dựng (`crFactCard`, tiêu đề "Kiểm tra dữ liệu", nút "Sửa số kiểm soát") — không sanitize |
| 068 | `READY`, `VALIDATION_FAILED` | `ac310Render068` |
| 068 | `LOADING`, `CONFLICT`, `PERMISSION_DENIED` | base (sanitize) |
| 069 | `READY`, `PENDING_APPROVAL` | `ac310Render069` → `.replace` `send-approval`→`cf12-send-approval` |
| 069 | `VALIDATION_ERROR`, `CONFLICT`, `PERMISSION_DENIED` | base (sanitize) |
| 070 | `READY` | `ac310Render070` (+ `cf12RejectSheet`) → `.replace` `approve`→`cf12-approve`, `confirm-reject`→`cf12-confirm-reject` |
| 070 | `SELF_APPROVAL_NOT_ALLOWED`, `APPROVAL_ALREADY_DECIDED`, `VALIDATION_ERROR`, `PERMISSION_DENIED` | base (sanitize) |
| 071 | `UNKNOWN`, `COMMIT_UNKNOWN` | `v350UnknownResult` |
| 071 | còn lại | base (sanitize) |

### 2.4 Mã chết

| Mã | Vì sao |
|---|---|
| Base `render049CR11` từ sau nhánh `LOADING` | `ac310Render049` xử lý mọi trạng thái còn lại |
| Base `render052CR11` nhánh huỷ + `CORRECTION_ROUTE`; `crChoice` | `ac310Render052` xử lý; `crChoice` chỉ nhánh đó gọi |
| Base `render050CR11` nhánh banner `VALIDATION_ERROR` | `ac310Render050` xử lý `VALIDATION_ERROR` (thân còn lại sống cho `STALE` / `CONFLICT`) |
| Base `render051CR11` `READY` / `VALIDATION_ERROR` (sheet, footer); `crTextAction` | `ac310Render051`; `crTextAction` chỉ nhánh đó gọi |
| `ac310Render068` nhánh `CONTROL_TOTAL_MISMATCH`; base 068 `READY` / `VALIDATION_FAILED` / `CONTROL_TOTAL_MISMATCH` | `v350` / `ac310` đè |
| Base 066 `READY` / `PENDING_APPROVAL` / `REJECTED` / `UNKNOWN` / `ACTIVE_RECONCILED`; base 067 `READY` / `VALIDATION_ERROR`; base 069 `READY` / `PENDING_APPROVAL`; base 070 `READY` + `cf12ApprovalFooter`; base 071 `UNKNOWN` / `COMMIT_UNKNOWN` | bản thắng 2.3 |
| Listener click UIF-12 (`app.js`): `check`, `send-approval`, `approve`, `confirm-reject` | Thuộc tính đã bị `v350` đổi thành `data-v350-action="cf12-*"` |
| `v360` toast `[data-cf12-action="send-approval"]` | Như trên — selector không bao giờ khớp (toast không hiện; **giữ không hiện**) |
| Listener khôi phục (2.6) UIF-11: `approve`, `reject-confirm`, `approval-result` | `v350` đã đổi thuộc tính → **không chép** ba nhánh này |
| Guard `if(activeFlowId!=="UIF-11"/"UIF-12")` + `renderGeneric` trong mọi hàm dựng | SCR-048…053 chỉ thuộc UIF-11, 066…071 chỉ thuộc UIF-12 |
| `renderers["SCR-053"]=(s)=>…?ac310Base(…):ac310Base(…)`, tương tự 071 | Hai nhánh như nhau |

Kiểm từng mục bằng phép "thuộc tính có được hàm thắng phát không" (A5 mục 2.4).

### 2.5 Sống, phải gộp

| Mã | Ở đâu | Xử lý |
|---|---|---|
| State `cr11*`, `cr11Operations`, `cr11Current`, `cr11StateFor`, `cr11ListRows` | `app.js` | `bj11.js` |
| Chèn `IO-260904-021` vào `cr11Operations` (vị trí 2) | `v350` phần BJ-16 — **chạy lúc nạp** | Đưa thẳng vào literal `cr11Operations` trong `bj11.js` (đúng vị trí 2), xoá dòng ở `v350` **cùng lúc** (bẫy 7.1) |
| State `cf12*`, `cf12Summary`, `cf12ReviewCard`, `cf12RejectSheet` | `app.js` | `bj12.js` |
| `v350Cf12ApprovalHash`, `v350Cf12Hash`, `v350Cf12Matches` | `v350` | `bj12.js` (`bj12ApprovalHash`, `bj12Hash()`, `bj12ControlMatches()`); `__VET45_V350__.setCf12Control` gọi `bj12ControlMatches()` lúc chạy (giữ hàm dev) |
| `v350` 068 `CONTROL_TOTAL_MISMATCH` | `v350` | Nhánh trong `render068BJ12` |
| `v350UnknownResult` cho 066 / 071 | `v350` (biến cục bộ trong IIFE — `bj12.js` không gọi được) | Helper `bj12UnknownResult()` dựng lại đúng markup (mẫu `bj10.js` dòng ~80: `ioResult` + `appShell({title:"Xác minh kết quả",…,centered:true,back:false})`, footer `data-v350-action="handoff-unknown" data-source-flow="UIF-12" data-operation="Khởi tạo tồn kho đầu kỳ" data-scope="Kho trung tâm · {ngày chốt}"`) |
| Listener `v350` `cf12-check`, `cf12-send-approval`, `cf12-approve` (kiểm người duyệt + hash, hẹn giờ 420 ms) | `v350` listener 1 | `bj12.js`; kiểm người duyệt bằng `window.__VET45_V350__?.getActor?.()==='approver'` (như `bj08.js`) |
| Listener `v350` `cr11-approval-result` | `v350` listener 1 | `bj11.js` |
| Listener `v350` actor `cr11-approve` (hẹn giờ 300 ms), `cr11-reject-confirm`, `cf12-confirm-reject` | `v350` listener 2 | Tách theo BJ vào `bj11.js` / `bj12.js` |
| Listener input / click UIF-12 (`app.js`, khối "v1.8.0 — targeted interactions") | `app.js` | Nhánh sống → `bj12.js`; nhánh UIF-15 **ở lại** (A9) |
| Listener input / change / click UIF-11 (khôi phục, 2.6) | `core.js.before-a5` | Chặng 0 đặt lại vào `core.js`; chặng 3 chuyển phần UIF-11 sang `bj11.js` |
| `v360` toast `[data-cr11-action="submit-correction"]` "Đã gửi yêu cầu sửa sai" | `v360` | Gọi `showToast` ngay sau `navigate("SCR-053")` trong handler `submit-correction`; xoá dòng ở bảng toast |
| `cr16-correction-handoff` (đặt `cr11SelectedId`, `crSwitchFlow("UIF-11",…)`) | `v350` | **Giữ** ở `core.js` (A10); chạy lúc bấm nên đọc được `let` của `bj11.js` |
| Lối vào `entry=operation-context` / `approver` (UIF-11), `approver` (UIF-12) | khối routing đầu `core.js` | Giữ (khung, A11) |
| `v360RootScreens` (048, 066), `v360ExitTargets` (051–053 → 048; 070, 071 → 066) | `v360` | Giữ; nút fallback cần gộp được đo ở chặng 4 |

Ở lại `core.js` vì BJ-15/16/17 hoặc BJ-09/10 còn dùng: `crFactCard`, `crSwitchFlow`, `icTextarea`, `ioResult`, `cfMoney`, `cfMoneyInput`, `cfNumber`, `cfDateVN`, `cfDateKey`, `cfField`, `cfSelect`, `cfSummaryGrid`, `cfSecondary` (định nghĩa nằm giữa khối BJ-12 của `app.js` — để nguyên chỗ, thêm một dòng chú thích "dùng chung BJ-12/15").

### 2.6 Đã mất ở gói trước — khôi phục ở chặng 0

| Mất | Từ gói | Hậu quả hiện tại | Nguồn khôi phục |
|---|---|---|---|
| Khối listener `// v1.7.0 Correction & Recovery interactions` (input / change / click cho UIF-11, UIF-16, UIF-17) | A5 (có trong `app/core.js.before-a5`, không còn từ `before-a6`) | UIF-11: lọc, tìm, mở nghiệp vụ, chọn cách sửa, huỷ, sửa sai, mở sheet từ chối… **không làm gì**. UIF-16/17: lọc, tìm, mở hồ sơ, `open-plan`… cũng chết | `grep -n "Correction & Recovery interactions" app/core.js.before-a5` (~60 dòng ngay sau) |
| `render()` cuối `crSwitchFlow` | A7 (chú thích `/* load-time render removed T7-P A7 */` — nhưng hàm này chạy lúc bấm) | Mọi `handoff-unknown` (BJ-02/05/06/07/08/10/12 qua `v350HandoffUnknown`), `cr16-correction-handoff`, `handoff-unknown` của BJ-11 đổi URL sang SCR-079 / SCR-049 nhưng **màn không vẽ lại** | Bản HEAD: `…syncReviewUrl();render();}` |
| `render()` trong hẹn giờ 300 ms của `cr11-approve` (`v350` listener 2) | A7 (cùng chú thích) | Duyệt sửa sai kẹt ở `PROCESSING` | Bản HEAD: `…stateByScreen["SCR-053"]="COMPLETED";syncReviewUrl();render();` |

Hai lời gọi `render()` lúc nạp mà A7 xoá đúng (cuối `v350`, cuối `v360`, cuối `v310` / `v320` / `v351`) — **giữ nguyên đã xoá**.

### 2.7 Lỗi lớp chồng — sửa có chủ đích ở chặng 5

Nút "Từ chối" trong sheet từ chối của **SCR-051** và **SCR-070** dựng `disabled` khi lý do rỗng (lý do bị đặt rỗng mỗi lần mở sheet). Listener input bật nút bằng selector `[data-cr11-action="reject-confirm"]` / `[data-cf12-action="confirm-reject"]`, nhưng `v350` đã đổi thuộc tính thành `data-v350-action="cr11-reject-confirm"` / `"cf12-confirm-reject"` → nút **không bao giờ bật**, người duyệt không từ chối được (ngõ cụt, trái tiêu chí 4 của T7-P). Sửa: listener input chọn đúng thuộc tính cuối. Không muốn đổi hành vi ở Giai đoạn 1 → bỏ chặng 5, ghi cho brief BJ-11 / BJ-12.

### 2.8 Lệnh đo lại

```bash
grep -n 'renderers\[.SCR-0\(4[89]\|5[0-3]\|6[6-9]\|7[01]\).\]\s*=' app/core.js   # v310, v350
grep -n 'cr11\|cf12\|UIF-1[12]' app/core.js | cut -c1-160
grep -n 'render removed' app/core.js                                              # 2.6: dòng crSwitchFlow + cr11-approve là runtime
grep -n 'Correction & Recovery interactions' app/core.js.before-a5
grep -n '"SCR-0\(4[89]\|5[0-3]\|6[6-9]\|7[01]\)"' app/core.js                       # literal renderers, FIGMA_TEMPLATE, v360
```

### 2.9 Helper `ac310*` (đo 2026-10-17)

| Helper | BJ-11 | BJ-12 | BJ khác còn gọi (trong `core.js`) | Về đâu |
|---|---|---|---|---|
| `ac310SectionTitle`, `ac310KeyValueSurface`, `ac310ListSurface`, `ac310RadioSurface`, `ac310AuditItem`, `ac310AuditSurface`, `ac310SummaryMetrics` | có / — | — / có | BJ-15, 16, 09 (`ac310Render056`) | `shared-control.js` |
| `ac310Field`, `ac310ApprovalFooter` | có | có | — | `shared-control.js` (hai BJ dùng) |
| `ac310Textarea`, `ac310RadioChoice` | có | — | — | `bj11.js` (`bj11Textarea`, `bj11RadioChoice`) |
| `ac310FileDrop`, `ac310Result`, `ac310IssueRow`, `ac310Cf12Review` | — | có | — | `bj12.js` (tiền tố `bj12`) |
| `ac310ProductRow`, `ac310ModeChoice`, `ac310EvidenceRows`, `ac310CaseRows`, `ac310Cf15ProductSheet`, `ac310StateLabel`, `ac321CanonicalChips`, `ac310Base` (+ `ac310BaseRenderers`) | — | — | BJ-08/09/15/16/17 | Ở lại (A9–A11). `cr11ListRows` gọi `ac321CanonicalChips` lúc dựng — được |

## 3. Chuẩn bị

1. Server, kịch bản golden (mục 6) + sửa công cụ `wait` (mục 6.1), chụp mốc `.golden-base`, chụp lần hai, so — khớp.
2. Kiểm trên trình duyệt, xác nhận 2.6 (để biết golden nào sẽ đổi ở chặng 0):
   - `?uif=UIF-05&screen=SCR-029&state=UNKNOWN` → "Chuyển sang xác minh": URL sang `SCR-079` nhưng màn **vẫn là SCR-029** → xác nhận lỗi `crSwitchFlow`.
   - `?uif=UIF-11&screen=SCR-048` → bấm chip "Có thể hủy" / một dòng nghiệp vụ: **không có gì xảy ra** → xác nhận mất listener.
   - `?uif=UIF-11&entry=approver` → "Từ chối" → gõ lý do: nút "Từ chối" trong sheet vẫn mờ → xác nhận 2.7.
   Kết quả khác mô tả → dừng, báo phiên review.

## 4. Các bước

### 4.1 Chặng 0 — khôi phục (thay đổi có chủ đích)

a. **Listener Correction & Recovery:** chép khối `document.addEventListener("input"…)` / `("change"…)` / `("click"…)` từ `core.js.before-a5` vào `core.js` ngay sau `/* UIF-07 click listener moved to app/bj07.js (T7-P A6) */` (vị trí gốc trong phần `app.js`). Bỏ ba nhánh UIF-11 chết (2.4: `approve`, `reject-confirm`, `approval-result`). Giữ nguyên phần UIF-16/17 (A10 chuyển).
b. **`render()` runtime:** thêm lại `render();` cuối `crSwitchFlow` và trong hẹn giờ `cr11-approve`; bỏ hai chú thích `load-time render removed` sai ở hai chỗ đó.
c. Golden: chụp vào thư mục mới, so với mốc. **Chỉ được khác:** `SC_bj02_unknown_2_handoff`, `SC_bj05_unknown_1_handoff`, `SC_bj06_unknown_1_handoff`, `SC_bj08_unknown_1_handoff` (giờ hiện SCR-079 của UIF-17) và các bước của kịch bản mới `SC_bj11_*` sau bước đầu tiên bấm vào nút `data-cr11-*` (giờ có hành vi). Mọi ca trạng thái tĩnh `UIF-11_*`, `UIF-12_*`, `UIF-16_*`, `UIF-17_*` **khớp**.
d. Mốc mới `.golden-a8-0` = kết quả chặng 0; các chặng sau so với mốc này và phải **khớp hoàn toàn**.

### 4.2 Chặng 1 — xoá mã chết (2.4)

Theo bảng. Xoá luôn `crChoice`, `crTextAction`, `cf12ApprovalFooter` sau khi `grep` chắc không ai gọi. Golden.

### 4.3 Chặng 2 — gộp (vẫn trong `core.js`)

1. **BJ-11:** `render048BJ11 … render053BJ11` theo 2.2 — nhánh `ac310` + nhánh base còn sống, bọc `ac310SanitizeMarkup` đúng như chuỗi hiện tại; 051 viết thẳng thuộc tính cuối (`data-v350-action="cr11-approve"`, `"cr11-reject-confirm"`, `"cr11-approval-result"`) thay hai `.replace`.
2. **BJ-12:** `render066BJ12 … render071BJ12` theo 2.3 — thuộc tính cuối viết thẳng (`cf12-check`, `cf12-send-approval`, `cf12-approve`, `cf12-confirm-reject` trong `cf12RejectSheet`); 068 `CONTROL_TOTAL_MISMATCH` lấy thân `v350` (không sanitize); 066 / 071 `UNKNOWN` (+ `COMMIT_UNKNOWN` ở 071) → `bj12UnknownResult()` (không sanitize).
3. Thay các `renderers["SCR-…"]=` của `v310` / `v350` bằng hàm hợp nhất; xoá `ac310Render048…052`, `ac310Render066…070`, các `v350Render0xxBase`, mục 066 / 071 trong `unknowns` của `v350`. Mục SCR-047 còn lại đã chết từ A7 (`bj08.js` đè `renderers["SCR-047"]` sau khi `v350` bọc) → xoá luôn; mảng rỗng → xoá cả `wrapUnknown`.
4. Đo nhanh trước–sau bằng đoạn đo A1 cho mọi trạng thái (HTML phải giống hệt, kể cả thứ tự thuộc tính sau sanitize). Golden.

### 4.4 Chặng 3 — chuyển file

1. `shared-control.js`: thêm helper nhóm "về `shared-control.js`" ở 2.9; sửa chú thích đầu file (danh sách còn ở `core.js` chờ A9–A10).
2. `app/bj11.js`: state + `cr11Operations` (**đã chèn `IO-260904-021`**) + helper `bj11*` + `cr11ListRows` + 6 hàm dựng; listener UIF-11 (từ chặng 0) + `cr11-approval-result` / `cr11-approve` / `cr11-reject-confirm` của `v350`; toast `submit-correction`; `Object.assign(renderers, …)`; xoá 6 mục trong literal `renderers`. Viết lại chú thích đầu file theo mẫu `bj08.js`.
3. `app/bj12.js`: state + `cf12Summary` + helper `bj12*` + hash + 6 hàm dựng; listener input / click UIF-12 (nhánh sống) + `cf12-check` / `cf12-send-approval` / `cf12-approve` / `cf12-confirm-reject`; `Object.assign`; xoá 6 mục literal.
4. Xoá ở `core.js`: dòng chèn `IO-260904-021` của `v350`; phần UIF-11 của khối listener chặng 0; phần UIF-12 của listener "v1.8.0" (để lại UIF-15); `v350Cf12*`; nhánh `cf12-*` / `cr11-*` trong hai listener `v350` (listener 2 chỉ còn rỗng → xoá cả listener và `v350Render051ActorBase` / `v350Render070ActorBase`); dòng `cr11` / `cf12` trong `toastRules` của `v360` (mảng rỗng → xoá cả listener toast).
5. Listener mới: đầu mỗi listener `if (activeFlowId !== "UIF-11") return;` / `"UIF-12"`; giữ pha capture như gốc; `event.stopPropagation()` ở đúng nhánh như gốc.
6. `node --check`; mở deep link mọi luồng cụm kiểm soát (mục 5); golden.

### 4.5 Chặng 4 — đo, rồi sở hữu

1. Đoạn đo A1 (`rendererFor`), luồng `["UIF-11","UIF-12"]`, mọi trạng thái. Ứng viên lệch:
   - `v360` `ensureStableExitAffordance` — màn không có nút: 051 `SELF_APPROVAL_NOT_ALLOWED`, 070 `SELF_APPROVAL_NOT_ALLOWED` / `APPROVAL_ALREADY_DECIDED` / `VALIDATION_ERROR`, các `PERMISSION_DENIED` có `back:false` (051, 053, 070, 071) → `primaryFooter("Về danh sách",'data-v360-action="fallback-exit" data-v360-target="SCR-048"/"SCR-066"')` (mẫu `bj08ExitList`). 066 / 048 là màn gốc → không.
   - `v361` footer: 051 / 070 `READY` truyền `ac310ApprovalFooter` (đã là `<footer>`) vào `actions` → có thể bị chuẩn hoá footer đôi.
   - `v440` grouped surface trên `crFactCard` (nhánh base 052 / 050 / 066 `PREPARING` / 067 / 069 / 070, 068 mismatch).
   - `v470`: dòng "Chênh lệch" / "Điều chỉnh" (050, 051, 068) → class `v470-kv--attention`, dấu trừ U+2212.
   Gộp tới "không khác"; bỏ qua `data-v470="1"`.
2. Tải lại trang giữa các lần đo (`cr11CorrectQty`, `cf12RejectOpen`, hash nằm trong state file).
3. `ownedFlows.add("UIF-11")`, `ownedFlows.add("UIF-12")`. Golden khớp hoàn toàn với `.golden-a8-0`.

### 4.6 Chặng 5 — nút "Từ chối" (thay đổi có chủ đích, 2.7)

1. `bj11.js` listener input `[data-cr11-approval-reason]`: chọn `[data-v350-action="cr11-reject-confirm"]`.
2. `bj12.js` listener input `[data-cf12-reject-reason]`: chọn `[data-v350-action="cf12-confirm-reject"]`.
3. Golden: chỉ được khác các bước sau bước gõ lý do của `SC_bj11_reject` và `SC_bj12_reject`. Ghi CHANGELOG mục "Sửa lỗi".

## 5. Kiểm

| Kiểm | Cách | Đạt khi |
|---|---|---|
| Cú pháp | `node --check app/core.js app/shared-control.js app/bj11.js app/bj12.js` | Không lỗi |
| Không còn mã cũ | `grep -n "cr11\|cf12\|UIF-1[12]\|SCR-04[89]\|SCR-05[0-3]\|SCR-06[6-9]\|SCR-07[01]" app/core.js` | Chỉ còn: routing `entryMode` (UIF-11/12), `FIGMA_TEMPLATE_BY_FLOW_SCREEN`, nhãn inspector (`"UIF-11":"v3.2.0 …"`), `v360RootScreens` / `v360ExitTargets`, `cr16-correction-handoff` (đặt `cr11SelectedId`), danh sách `AC310_SCREEN_IDS` / `AC320_SCOPE` |
| Không còn `.replace` thuộc tính | `grep -n "replace(/data-c[rf]1[12]-action" app/*.js` | Rỗng |
| Không còn `render()` lúc nạp | `grep -n "^\s*\(if *([^)]*) *\)\?render();" app/core.js` | Rỗng (A7) |
| Deep link mọi luồng | `?uif=UIF-08&screen=SCR-042`, `UIF-09`, `UIF-10`, `UIF-11&screen=SCR-048`, `UIF-12&screen=SCR-066`, `UIF-15`, `UIF-16`, `UIF-17` | Dựng đúng, console sạch (bắt lỗi nạp, bẫy 7.1) |
| Golden | `capture` + `compare` với `.golden-a8-0` | **Khớp hoàn toàn** sau chặng 1–4; chặng 5 chỉ khác như 4.6 |
| Lỗi JS | `_errors.json` | Rỗng |

## 6. Kịch bản golden thêm

Khối `// BJ-11 / BJ-12 — T7-P A8`. Lấy selector cụ thể trên trang trước khi viết; bước không làm màn đổi → chỉnh, ghi mục 9.

| Tên | Bắt đầu | Bước |
|---|---|---|
| `SC_bj11_list` | `?uif=UIF-11&screen=SCR-048` | `[data-cr11-filter="CANCEL"]` → `"UNKNOWN"` → `"ALL"` → `typeIn('[data-cr11-search]','Nobivac')` → `typeIn(…,'')` → `[data-cr11-operation="IO-260901-014"]` (049 `CORRECTABLE`) |
| `SC_bj11_correct` | `?uif=UIF-11&screen=SCR-048` | dòng `IO-260901-014` → `[data-cr11-action="open-correction"]` (052) → `[data-cr11-strategy][value="FULL"]` → `edit-correction` (050) → `typeIn('[data-cr11-correct-qty]','117')` → `typeIn('[data-cr11-correction-reason]','Đếm lại thùng')` → `submit-correction` (053 `PENDING_APPROVAL` + toast) → `to-list` |
| `SC_bj11_cancel` | `?uif=UIF-11&screen=SCR-048` | dòng `IO-260906-022` (049 `CANCELABLE`) → `open-cancel` → `typeIn('[data-cr11-cancel-reason]','Lập nhầm phiếu')` → `confirm-cancel` (053 `CANCELLED`) → `to-list` |
| `SC_bj11_blocked` | `?uif=UIF-11&screen=SCR-048` | dòng `IO-260902-005` (049 `BLOCKED_PHYSICAL_HANDOVER`) → `to-list` |
| `SC_bj11_unknown` | `?uif=UIF-11&screen=SCR-048` | dòng `IO-260906-031` (049 `UNKNOWN`) → `[data-cr11-action="handoff-unknown"]` (UIF-17 SCR-079) |
| `SC_bj11_back` | `?uif=UIF-11&screen=SCR-050` | `back` → `back` → `back` (050 → 052 → 049 → 048) |
| `SC_bj11_approve` | `?uif=UIF-11&entry=approver` | `[data-v350-action="cr11-approve"]` (053 `PROCESSING`) → `wait(400)` (053 `COMPLETED`) → `to-list` |
| `SC_bj11_reject` | `?uif=UIF-11&entry=approver` | `reject-open` → `reject-close` → `reject-open` → `typeIn('[data-cr11-approval-reason]','Thiếu chứng từ')` → `[data-v350-action="cr11-reject-confirm"]` (trước chặng 5: không đổi; sau: 053 `REJECTED`) |
| `SC_bj11_self_approve` | `?uif=UIF-11&screen=SCR-051` | `cr11-approve` (`SELF_APPROVAL_NOT_ALLOWED`) → `[data-v360-action="fallback-exit"]` (048) |
| `SC_bj11_decided` | `?uif=UIF-11&screen=SCR-051&state=APPROVAL_ALREADY_DECIDED` | `[data-v350-action="cr11-approval-result"]` (053) |
| `SC_bj11_context` | `?uif=UIF-11&entry=operation-context` | `back` |
| `SC_bj12_prepare` | `?uif=UIF-12&screen=SCR-066` | `[data-cf12-action="start"]` (067) → `choose-file` → `typeIn('[data-cf12-control-qty]','')` → `[data-v350-action="cf12-check"]` (`VALIDATION_ERROR`) → `typeIn(…,'4820')` → `cf12-check` (068 `READY`) → `review` (069) → `[data-v350-action="cf12-send-approval"]` (066 `PENDING_APPROVAL`) |
| `SC_bj12_mismatch` | `?uif=UIF-12&screen=SCR-067` | `typeIn('[data-cf12-control-qty]','4800')` → `cf12-check` (068 `CONTROL_TOTAL_MISMATCH`) → `back-file` (067) |
| `SC_bj12_failed` | `?uif=UIF-12&screen=SCR-068&state=VALIDATION_FAILED` | `back-file` |
| `SC_bj12_approve` | `?uif=UIF-12&screen=SCR-067` | `cf12-check` → `review` → `cf12-send-approval` → `window.__VET45_V350__.applyEntry('UIF-12','approver')` (070) → `cf12-approve` (071 `PROCESSING`) → `wait(500)` (`COMPLETED`) → `[data-cf12-action="see-inventory"]` (UIF-01) |
| `SC_bj12_stale` | `?uif=UIF-12&entry=approver` | `cf12-approve` (070 `VALIDATION_ERROR` — chưa có hash) |
| `SC_bj12_self` | `?uif=UIF-12&screen=SCR-070` | `cf12-approve` (`SELF_APPROVAL_NOT_ALLOWED`) → `fallback-exit` (066) |
| `SC_bj12_reject` | `?uif=UIF-12&entry=approver` | `open-reject` → `close-reject` → `open-reject` → `typeIn('[data-cf12-reject-reason]','Sai nhóm vaccine')` → `[data-v350-action="cf12-confirm-reject"]` (sau chặng 5: 070 `APPROVAL_ALREADY_DECIDED`) → `fallback-exit` (066 `REJECTED`) → `fix-rejected` (067) |
| `SC_bj12_unknown` | `?uif=UIF-12&screen=SCR-071&state=UNKNOWN` | `[data-v350-action="handoff-unknown"]` (UIF-17 SCR-079) |

### 6.1 Sửa công cụ: bước chờ

Hiện `golden.mjs` chạy bước bằng `(${c.act}, ${frames})` — biểu thức dấu phẩy chỉ chờ `frames`, không chờ Promise của bước → không có cách chờ hẹn giờ 300 / 420 ms. Sửa:

```js
const wait = (ms) => `new Promise((r)=>setTimeout(()=>r(true),${ms}))`;
// trong worker:
if (c.act) await evalv(`Promise.resolve(${c.act}).then(()=>${frames})`);
```

Đổi công cụ **trước** khi chụp mốc ở mục 3; chụp lại toàn bộ và so với mốc cũ (trước sửa công cụ) — phải khớp hoàn toàn.

## 7. Bẫy

1. **Truy cập lúc nạp tới biến đã chuyển ra `bjNN.js`** — `v350` chèn `IO-260904-021` vào `cr11Operations` ngay lúc nạp `core.js`. Chuyển `cr11Operations` mà quên dòng này → `ReferenceError` ở cấp cao nhất, `core.js` dừng giữa `v350`, **hỏng mọi luồng**. Tương tự literal `const renderers = {"SCR-048":render048CR11,…}`: chuyển hàm mà chưa xoá mục literal → lỗi nạp. Kiểm bằng deep link mọi luồng (mục 5) sau chặng 3.
2. **`v350UnknownResult` / `v350HandoffUnknown` / `isApproverEntry` là biến cục bộ trong IIFE `v350`** — `bj12.js` không gọi được (`typeof` = `"undefined"`). Dựng lại markup (2.5); người duyệt qua `window.__VET45_V350__.getActor()`.
3. **Sanitize không đồng đều:** nhánh `ac310` và base bọc `ac310SanitizeMarkup`; 068 `CONTROL_TOTAL_MISMATCH` của `v350` và màn UNKNOWN **không** bọc. Gộp đúng như chuỗi; đo bằng HTML, không chỉ bằng ảnh.
4. **Hai listener `v350` cùng bắt `[data-v350-action]` ở pha capture** — listener 1 gọi `stopPropagation()` nhưng listener 2 vẫn chạy (cùng nút `document`). Khi tách sang `bjNN.js`, mỗi khoá chỉ xử lý ở **một** chỗ; không để listener 1 còn sót nhánh `cr11-*` / `cf12-*`.
5. **Listener khôi phục dùng `navigate` / `renderAppScreen` / `crSwitchFlow`** — chặng 0 phải làm 4.1.b trước khi chụp mốc, nếu không `SC_bj11_unknown` chụp màn cũ.
6. **Tên trần cấp file**: helper chuyển ra `bjNN.js` phải có tiền tố (`bj11*`, `bj12*`); state giữ tên `cr11*` / `cf12*` vì `core.js` (`cr16-correction-handoff`, `__VET45_V350__.setCf12Control`) còn đọc.
7. **Hẹn giờ 300 / 420 ms** kiểm `activeFlowId` + `activeScreenId` + trạng thái trước khi vẽ — giữ nguyên điều kiện; golden dùng `wait` (6.1).
8. **Toast**: `v360` hẹn 30 ms, handler mới gọi ngay sau `navigate` — có thể khác ảnh ở bước `submit` của `SC_bj11_correct` nếu mốc chụp trước khi toast hiện; chấp nhận nếu chỉ khác toast, ghi mục 9.

## 8. Ghi lại và commit

1. `CHANGELOG.md` mục `[5.1.8] — T7-P Giai đoạn 1, gói A8: BJ-11, BJ-12 viết lại sạch`; ghi rõ hai nhóm thay đổi có chủ đích (chặng 0 khôi phục listener / `render()`; chặng 5 nút "Từ chối") và các ca golden khác; `manifest.json`.
2. Plan tổng: mục 14 A8 Làm ✅; mục 4.1 bẫy: thêm "chú thích `load-time` phải đúng là lúc nạp — hàm chạy lúc bấm (`crSwitchFlow`, hẹn giờ) giữ `render()`" và "kiểm listener của BJ còn đủ trước khi tách (A5 làm mất khối Correction & Recovery)"; mục 8.1 hàng A10: listener UIF-16/17 đã đặt lại ở `core.js` (chặng 0).
3. `python3 tools/sync-registry.py`; `detect_changes()`; commit `refactor(prototype): T7-P A8 — BJ-11, BJ-12 clean code`.

## 9. Ghi chú khi làm

- `tools/golden.mjs`: thêm `wait(ms)` + `Promise.resolve(act).then(frames)` (§6.1) trước khi chụp.
- Chặng 0: khôi phục listener Correction & Recovery (bỏ 3 nhánh UIF-11 chết) + `render()` trong `crSwitchFlow` / hẹn giờ `cr11-approve`.
- Extract: `tools/_a8_extract.py` sinh `bj11.js` / `bj12.js`, mở rộng `shared-control.js`, dọn `core.js` (backup `core.js.before-a8`).
- `v350EntryTargets` thêm UIF-11 / UIF-12 (cho `applyEntry` trong `SC_bj12_approve`).
- Bẫy: nút `cf12-confirm-reject` nằm trong backdrop `close-reject` → listener phải xử lý `data-v350-action` **trước** `data-cf12-action`.
- `syncReviewUrl()` thêm sau đổi state qua `renderAppScreen` (self-approve / reject / validation) để `@url` golden khớp.
- Timer COMPLETED của BJ-12: thêm `syncReviewUrl()` trước `render()` (cùng kiểu BJ-11).

## 10. Review

- **Ngày:** 2026-10-19, rà trên working tree cuối Giai đoạn 1 (sau A11, chưa commit; HEAD `4c7020013`). Kiểm chung: [plan tổng mục 14.1](T7-P-thiet-ke-lai-luong.md#141-review-giai-đoạn-1-2026-10-19).
- **Kết quả: ❌ → ✅ sau A12 bước R2 (2026-10-19):** 5 ca golden từng lệch hình so với mốc trước Giai đoạn 1 nay khớp lại `tools/.golden-a5-base`.
- **Đã kiểm:**
  - Chữ: mọi ca `UIF-11_*`, `UIF-12_*`, `SC_bj11_*`, `SC_bj12_*` khớp mốc gốc. Chặng 0 khôi phục đúng: handoff UNKNOWN của BJ-02/05/06/08 lại sang BJ-17 như mốc gốc; `crSwitchFlow` / hẹn giờ duyệt có `render()`.
  - Hai sửa lỗi có chủ đích (nút "Từ chối" trong sheet SCR-051 / SCR-070) — đúng, đã ghi CHANGELOG.
  - `core.js` không còn `cr11` / `cf12`; không còn `.replace(/data-c[rf]1[12]-action`.
- **Lệch (có từ mốc `.golden-a8-smoke`, tức do A8; so với `tools/.golden-a5-base`):**
  1. `UIF-11_SCR-051_READY`, `UIF-11_SCR-051_VALIDATION_ERROR`, `UIF-12_SCR-070_READY` — footer duyệt mất dạng hai nút ngang của `v361`: trước là "Từ chối" viền đỏ bên trái + "Duyệt" bên phải trên **một hàng**; nay hai nút xếp dọc, "Từ chối" xám, "Duyệt" bị đẩy ra ngoài đáy khung 402×874. Nguyên nhân: `ac310ApprovalFooter` (`shared-control.js`) phát `<footer class="app-actions figma-sticky-footer ac310-two-actions">` trần; trước A8 `normalizeDualFooters` của `v361` bọc `renderAppScreen` thêm lớp lúc chạy. Khi đo pipe vs bare (checklist bước 5) phải thấy khác này — ghi chú mục 9 không nhắc tới bước đo.
  2. `UIF-11_SCR-050_READY`, `UIF-11_SCR-050_VALIDATION_ERROR` — dòng "Điều chỉnh" trong thẻ "Hệ thống tự tính" mất dạng nhấn mạnh (chữ đậm đen, thụt vào, kẻ trên) và thành chữ thường + giá trị màu cảnh báo. Nguyên nhân: `bj11KeyValueSurface` tự viết markup `<div class="ds24-key-value-row v470-kv--attention">` thay vì `ds24KeyValueRow(label, value, true)` (mất lớp `ds24-key-value-row--emphasis` và `data-ds-prop-state="Emphasis"`).
- **Ghi nhận quy trình:** kiểm mục 5 so với `.golden-a8-0`, nhưng các thư mục còn lại (`.golden-a8-check` 110 ca, `-smoke` 160, `-fix` 24, `-fix2` 22) đều là tập con — không có lần so **toàn bộ** golden nào sau A8, nên 5 ca trên lọt qua.
