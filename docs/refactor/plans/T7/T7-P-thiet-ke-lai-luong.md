# T7-P — Thiết kế lại Theme 7 trên prototype (plan tổng thể)

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ (2026-10-16, bản chi tiết) | Làm 🔄 | Review 🔄
> Thuộc [PLAN.md](../../PLAN.md) mục "Theme 7". Làm sau [T7-P0](T7-P0-don-prototype.md) (✅).
> Phạm vi: prototype `specs/themes/theme-07/03.design/prototype/html` và tài liệu thiết kế `specs/themes/theme-07/03.design` (Screen Contract, UIF, pattern). Code Flutter làm theo prototype đã chốt (giai đoạn 5).
> **Hai giai đoạn (chốt 2026-10-16):** Giai đoạn 1 viết lại code sạch cho cả 17 BJ + CAP-01 (giao diện không đổi, golden phải khớp); Giai đoạn 2 mới thiết kế lại từng BJ.
> Ước lượng thô: Giai đoạn 1 **~20 ngày**; Giai đoạn 2 **~24 ngày**; hoàn thiện + chốt đặc tả ~4–5 ngày.

## Mục lục

1. Mục tiêu và tiêu chí xong
2. Đã chốt
3. Hiện trạng
4. Quy trình: Giai đoạn 1 (viết lại code) và Giai đoạn 2 (thiết kế lại)
5. Khuôn dùng chung
6. Thành phần DS mới
7. Dọn tài liệu `03.design`
8. Thứ tự, gói, đợt, mốc
9. Từng BJ: hướng thiết kế lại sơ bộ
10. Luồng demo
11. Sau Giai đoạn 2
12. Rủi ro
13. Đề xuất sửa đặc tả và thành phần mới
14. Tiến độ
15. Câu hỏi còn mở

---

## 1. Mục tiêu và tiêu chí xong

| # | Mục tiêu | Đo bằng |
|---|---|---|
| 1 | Mỗi BJ có luồng thiết kế lại từ việc thật của Owner / nhân viên, không chép lại Screen Contract cũ | Brief bước B được duyệt cho đủ 17 BJ + CAP-01 |
| 2 | Prototype là nguồn hình ảnh và hành vi duy nhất cho Flutter | Mỗi màn một hàm dựng trong `app/bjNN.js`; `app/core.js` chỉ còn khung; không lớp vá |
| 3 | Chất lượng giao diện | Critique toàn theme **≥ 32/40** (gốc 24/40), 0 vấn đề P0 / P1; `audit` từng BJ không còn lỗi tương phản / vùng chạm |
| 4 | Không ngõ cụt | Mọi trạng thái có lối ra; mọi màn mở được từ Home Kho hoặc từ màn trước trong luồng; bộ bấm thử 0 lỗi JS |
| 5 | Đặc tả khớp prototype | Screen Contract / UIF viết lại theo khuôn mới (mục 7), không còn đoạn `### vX.Y` |
| 6 | Demo đi một mạch | Kịch bản golden `SC_demo_*` (mục 10) chạy hết, không lỗi |

## 2. Đã chốt

| Giữ nguyên | Được thiết kế lại |
|---|---|
| Nghiệp vụ trong BJ / UC: quy tắc, trạng thái nghiệp vụ, ai được làm gì, người duyệt khác người lập | Luồng giữa các màn, lối vào, điều hướng |
| Chuỗi chữ của spec. Đổi chữ = đề xuất sửa Screen Contract (mục 13), không sửa thẳng trên UI khi chưa duyệt | Bố cục màn, thứ tự khối, mật độ, gom / tách / bỏ màn |
| Token DESIGN.md, thành phần `vet45_design_system`; được thêm thành phần mới (mục 6) | Screen Contract, UIF: chỉ là tham khảo |
| **Home Kho = bản candidate** (SCR-090): tìm kiếm → 4 nút nhanh → Cần chú ý → Quản lý kho (5 khu) → Thiết lập kho | Chi tiết bên trong Home candidate |

**Người dùng:** cửa hàng có **Owner + 1–3 nhân viên**. Nhân viên lập phiếu (nhận hàng, kiểm kê, đổi tình trạng, tiêu hủy…); **Owner duyệt và là người duy nhất xem tiền**. Dùng trên điện thoại giữa lúc bán hàng (mode Operate).

**Lối vào:** Kho nằm trong tab "Thêm"; khung 5 tab của app không đổi. Mỗi BJ bắt đầu ở nơi việc phát sinh, menu Kho là đường phụ: BJ-04 / 05 / 06 từ đơn hàng, BJ-07 từ mua hàng, BJ-03 ngay sau khi nhận hàng xong, BJ-16 / 17 từ cảnh báo, BJ-09 / 10 từ hàng hoặc lô có vấn đề.

**Vị trí trên Home Kho:**

| Vị trí | BJ | Cách tới |
|---|---|---|
| 4 nút nhanh | 02 Nhận hàng, 05 Lấy hàng, 08 Kiểm kê, 01 Tra cứu tồn | 1 chạm |
| Cần chú ý (chỉ khi có việc) | Chờ duyệt (khuôn duyệt của mọi BJ), lô sắp hết hạn (09), sai lệch (16), kết quả chưa rõ (17) | 1 chạm |
| Quản lý kho → Tồn kho | 01, 09, CAP-01 | Lớp thứ hai |
| Quản lý kho → Nhập, xuất & hoàn trả | 02, 05 (+04), 06, 07 | Lớp thứ hai |
| Quản lý kho → Kiểm kê & xử lý | 08, 09, 11, 16 | Lớp thứ hai |
| Quản lý kho → **Giá trị kho** | 03, 13, 14 (chỉ Owner) | Lớp thứ hai |
| Quản lý kho → Báo cáo & lịch sử | 15 | Lớp thứ hai |
| Thiết lập kho | 12, CAP-01 | Sâu |

## 3. Hiện trạng (2026-10-16)

| Hạng mục | Trạng thái |
|---|---|
| Critique toàn theme | 24/40 (2026-10-15), lưu ở `.impeccable/critique/` |
| Màu theo DESIGN.md, màu mang nghĩa cho tiền / tồn | ✅ |
| Rút gọn SCR-010 / 011 / 012 / 074 | ✅, giữ thứ tự cũ của SCR-011; xem lại ở BJ-02 |
| Home Kho candidate mặc định, "Cần chú ý" đúng tone, thanh dưới theo khung app | ✅ |
| Dọn prototype (T7-P0) | ✅ khung chung (`app/core.js`), chế độ theme + Hub (`app/hub.js`), một bộ token |
| BJ-01 bước A | ✅ `app/bj01.js` (gói A0 của Giai đoạn 1) |
| Công cụ | `tools/golden.mjs capture / compare` (714 ca, ~17 giây); bộ bấm thử dò lỗi JS; `tools/sync-registry.py` |

---

## 4. Quy trình

**Vai trò (chốt 2026-10-16):** phiên plan / review **chỉ viết plan, brief và review**; **bạn làm** mọi bước sửa file và duyệt.

**Thứ tự (chốt 2026-10-16):** viết lại code sạch cho **cả 17 BJ + CAP-01 trước** (Giai đoạn 1), rồi mới thiết kế lại từng BJ (Giai đoạn 2). Lý do: dọn mã được golden bảo vệ trọn vẹn vì giao diện không đổi; khi bắt đầu thiết kế lại, mọi BJ đã sửa thẳng được và `core.js` chỉ còn khung.

| Giai đoạn | Bước | Đổi giao diện? | Ai làm | Ra |
|---|---|---|---|---|
| 1 | A. Viết lại code (theo gói, mục 8.1) | Không | Bạn, theo plan gói `T7-P-A<n>-*.md` | `app/bjNN.js` sạch; golden khớp |
| 1 | Dọn khung (gói A11, cuối Giai đoạn 1) | Không | Bạn, theo plan gói | `core.js` chỉ còn khung; CSS gom theo BJ |
| 2 | B. Brief thiết kế lại | Chưa (quyết định) | Phiên review viết, **bạn duyệt** | Plan thực thi `T7-P-bjNN-*.md` (brief ở đầu plan) |
| 2 | C. Dựng thiết kế mới | **Có** | Bạn | Prototype mới của BJ |
| 2 | D. Kiểm | Không | Bạn; phiên review kiểm lại khi review | Ảnh chụp, golden |
| 2 | E. Ghi lại | Không | Bạn | CHANGELOG, Screen Contract / UIF mới, registry |

### 4.1 Giai đoạn 1 — bước A: viết lại code (không đổi giao diện)

Làm theo **gói** (mục 8.1): các BJ dùng chung lớp cũ hoặc dùng chung màn được làm cùng nhau. Mỗi gói có plan riêng, phiên review viết ngay trước khi bạn bắt đầu gói đó.

Checklist cho mỗi gói (rút từ BJ-01, đã làm 2026-10-16):

1. **Kịch bản golden trước:** thêm kịch bản thao tác của các BJ trong gói (lọc, mở chi tiết, sheet, gửi, duyệt, quay lại, vào từ Hub) vào `tools/golden.mjs`; chụp `.golden-base` **trước khi** đụng code; chụp hai lần phải khớp.
2. **Bản đồ:** liệt kê màn của gói và các lớp đang định nghĩa / bọc / sửa chúng (bảng mục 8.1 là điểm bắt đầu; đầu mỗi `app/bjNN.js` đã ghi lớp định nghĩa màn).
3. **Chuyển sang `app/bjNN.js`:** fixture, biến trạng thái, hàm dựng **cuối cùng** của từng màn, helper riêng, xử lý sự kiện (click / input / change / keydown / focusin) đang nằm trong `core.js`. Helper dùng chung giữa nhiều BJ → `app/shared-<cụm>.js` (vd. `shared-valuation.js`, `shared-control.js`), nạp trước các `bjNN.js` của cụm. Đường cũ / màn retired: đăng ký `screenAliases` (móc trong `navigate` gốc, A5) thay wrapper `navigate` từng lớp.
4. **Màn bị định nghĩa nhiều lần:** lấy bản thắng (bản gán sau cùng), gộp các `.replace()` / phần bọc của wrapper vào chuỗi gốc, xoá bản bị đè. Hàm toàn cục bị gán lại (vd. `io05ApplyHandover = function…`) → giữ **một** định nghĩa: bản cuối.
5. **Bước sửa sau dựng:** đo HTML "trần" (gọi thẳng `renderers[...]`) với HTML qua chuỗi legacy cho mọi trạng thái; khác ở đâu thì gộp vào hàm dựng. Các bước dùng chung hay gặp: `ensureRepresentativeFixture` / `ensureStableExitAffordance` (`v360`), `normalizeDualFooters` (`v361`), `cleanupDismissibleSheets`, `polishCrossThemeCopy`, `applyGroupedSurfaceRule` (`v440`), tone / badge của `v470`, `v471`.
6. **Wrapper `navigate` / toast:** nhánh của BJ trong wrapper `navigate` (`v350`, `v430`, `v460`, `v461`) và dòng của BJ trong bảng toast của `v360` → chuyển vào xử lý sự kiện của BJ (gọi `showToast` ngay sau `render()`, không hẹn giờ).
7. **Đăng ký:** `Object.assign(renderers, …)`; `ownedFlows.add("UIF-NN")`; xoá mục của màn khỏi literal `const renderers = {…}` trong `core.js`; xoá phần của BJ trong mọi lớp legacy.
8. **Kiểm:** golden toàn bộ **khớp hoàn toàn**; bộ bấm thử 0 lỗi JS; `node --check app/*.js`.
9. **Ghi:** CHANGELOG (mục "Giai đoạn 1 — gói …"), đầu `app/bjNN.js` (đã viết lại sạch), tiến độ mục 14, `python3 tools/sync-registry.py`.

**Bẫy đã gặp ở BJ-01** (plan gói nhắc lại khi liên quan):

- Hàm có tham số mặc định dạng object (`function f(p,{a=1}={})`): tìm thân hàm sau dấu `)` đóng tham số, không phải ngoặc `{` đầu tiên.
- Khối xử lý sự kiện của BJ thường là nhánh `if (activeFlowId === "UIF-NN") {…}` có `return` sớm trong một listener chung: tách nguyên khối, giữ điều kiện.
- Toast hẹn giờ 30 ms của `v360` chạy từ pha capture; khi chuyển vào handler của BJ phải gọi ngay sau `render()`.
- Helper của BJ được BJ khác gọi (vd. `bj01Empty` dùng ở BJ-08): giữ tên, ghi chú ở đầu file; gom về `core.js` ở gói A11.
- Lần render đầu chạy trước khi `bjNN.js` nạp: không sao, `hub.js` gọi `render()` sau cùng.
- **Không gọi `render()` / `renderAppScreen()` lúc nạp trong `core.js`** (A7): helper chuyển sang file nạp sau (`shared-control.js`…) sẽ `ReferenceError` ở cấp cao nhất và dừng nạp `core.js` giữa chừng — hỏng mọi luồng, không chỉ BJ đang tách.
- **Chú thích `load-time render removed` phải đúng là lúc nạp** (A8): hàm chạy lúc bấm (`crSwitchFlow`, hẹn giờ duyệt) **giữ** `render()` — A7 xoá nhầm hai chỗ đó.
- **Kiểm listener của BJ còn đủ trước khi tách** (A5/A8): A5 làm mất khối Correction & Recovery (UIF-11/16/17); A8 chặng 0 đặt lại vào `core.js` (phần UIF-16/17 chờ A10 chuyển).
- **Cơ chế dùng chung nằm trong IIFE** (`v350`): chuyển hẳn ra file sở hữu và nối bằng móc (`onUnknownHandoff`), không gọi chéo vào biến cục bộ (A10).

### 4.2 Giai đoạn 1 — gói A11: dọn khung (sau khi mọi gói xong)

Plan: [T7-P-A11-don-khung.md](T7-P-A11-don-khung.md). Phạm vi chốt 2026-10-19:

1. `core.js` chỉ còn khung: xoá `renderFlowScreen`, `ownedFlows`, mọi khối `vNNN` (`v350`, `v360`, `v361`, `v362`–`v364`, `v440`, `v450`, `v470`); `renderAppScreen` = màn gốc theme → `ThemeApp`, còn lại → `rendererFor(...)` + `ThemeApp.afterFlowRender()`.
2. Bước sau dựng **còn sống dù mọi luồng đã sở hữu** (bọc `render` / `MutationObserver`): `simplifyNormalBanners` → gộp vào hàm dựng BJ-08 / BJ-10 (khác biệt có chủ đích, ghi CHANGELOG); `v440` grouped surface → đo trước, 0 tác động thì xoá, còn thì giữ làm **một** bước dựng chung có tên trong khung.
3. Routing lối vào + actor gộp một bảng `entryTargets` / `applyEntry` / `currentActor()`; mọi API QA `__VET45_V350__` / `__V360__` / `__V3101__` / `__BJ10__`… → **một** `window.__VET45_QA__` (BJ tự đăng ký). Giữ tên thuộc tính `data-v350-action` / `data-v360-action` (đổi ở Giai đoạn 2).
4. Helper dùng chéo: `bj01Empty` → `ds24EmptyState`; bản trùng `icCard…icApprovalButtons` (`core.js` + `bj09.js`) → `shared-control.js`.
5. Tách harness → `harness/workbench.js` / `figma-ds-map.js` / `workbench.css`; `renderFlowInspector` **giữ nguyên chữ** (golden đọc inspector).
6. CSS chỉ phần an toàn: xoá luật không dùng (chế độ `golden.mjs usage`), gồm `.cr-*` / `.ac310-*` chết. **Gom CSS theo BJ và bỏ `!important` dời sang bước C của từng BJ** (mục 4.4).
7. Xoá mã chết JS còn lại (độ phủ + `grep`), file tạm của các gói trước. Kiểm: golden khớp hoàn toàn (trừ mục 2); bấm thử 0 lỗi JS.

### 4.2b Giai đoạn 2 — mỗi BJ đi B → E

Một BJ đi đủ B → E rồi mới sang BJ sau. Phiên review viết brief của BJ sau trong lúc bạn làm C–E của BJ trước.

### 4.3 B — Brief thiết kế lại (khuôn)

Mỗi brief có đủ các phần sau, ngắn gọn, có ảnh chụp tham chiếu:

1. **Việc thật:** ai, lúc nào, cần biết / làm gì; tần suất.
2. **Luồng hiện tại:** màn → màn, ảnh golden tương ứng.
3. **Vấn đề:** bảng (màn · vấn đề), lấy từ critique, ảnh chụp và việc thật.
4. **Đề xuất:** theo từng màn; màn giữ / gộp / bỏ / thêm; thứ tự khối; lối vào và lối ra (gồm nút nhảy sang BJ khác); khuôn dùng chung áp dụng.
5. **Trạng thái:** mỗi trạng thái hiện gì, làm gì được, lối ra.
6. **Không đổi:** quy tắc nghiệp vụ được giữ.
7. **Chữ mới / đổi chữ** và **thành phần mới** → thêm vào mục 13.
8. **Kiểm:** ca golden được phép khác; kịch bản golden thêm.
9. **Ước lượng C–E.**

Bạn duyệt bằng cách đồng ý cả brief hoặc chỉ ra điểm bỏ / sửa (một vòng sửa).

### 4.4 C — Dựng thiết kế mới

1. Sửa thẳng `app/bjNN.js`; CSS riêng của BJ trong `styles/screens.css` (khối có tiêu đề BJ), thành phần dùng chung trong `styles/components.css`. **Dời từ A11:** gom mọi luật của BJ (`[data-active-uif="UIF-NN"]`, tiền tố BJ, rải trong các khối `vNNN-…css`) về khối của BJ, bỏ `!important` khi không còn đối thủ — làm cùng lúc dựng thiết kế mới vì golden của BJ được phép khác.
2. Dùng token `--vet45-v2-*`; không màu / cỡ chữ / khoảng cách gõ tay.
3. Mọi trạng thái trong brief có nhánh dựng; nút nhảy sang BJ khác đi qua `navigate` / `ThemeApp` (không sửa DOM của BJ khác).
4. Cập nhật kịch bản golden theo brief.

### 4.5 D — Kiểm

1. Golden: chỉ các ca đã liệt kê trong brief được khác; mọi ca khác **khớp hoàn toàn**.
2. Bộ bấm thử 0 lỗi JS.
3. `/impeccable audit` phạm vi BJ: tương phản ≥ 4,5:1, vùng chạm ≥ 44, nhãn cho nút icon.
4. Gửi bạn ảnh chụp các màn chính và trạng thái mới; bạn chấp nhận hoặc yêu cầu sửa.
5. Chụp golden mới làm mốc cho BJ sau.

### 4.6 E — Ghi lại

1. `CHANGELOG.md`: mục BJ (thiết kế lại gì, khác golden ở đâu).
2. **Viết lại Screen Contract và UIF của BJ theo khuôn mới** (mục 7.1): gộp các đoạn `### vX.Y` vào nội dung chính, đưa vào thay đổi đã duyệt ở B, chữ theo bảng đã duyệt; trạng thái file `IN_REVIEW`.
3. Mục 13: đánh dấu đề xuất đã áp.
4. `03.design/screens/INDEX.md`: cập nhật dòng các màn của BJ (tên, trạng thái file, có trong prototype).
5. `python3 tools/sync-registry.py`; mục 14 tiến độ.

---

## 5. Khuôn dùng chung

Mỗi khuôn được dựng lần đầu ở một BJ, mô tả ở đây khi dựng xong, các BJ sau dùng lại (không dựng lại).

| # | Khuôn | Dựng ở | Dùng lại ở |
|---|---|---|---|
| K1 | **Trạng thái chung:** không có quyền, đang tải, rỗng, rỗng sau lọc, dữ liệu cũ, bị khoá | BJ-01 | tất cả |
| K2 | **Lập → duyệt → kết quả:** người lập gửi; danh sách "Chờ duyệt" (Home → Cần chú ý); màn duyệt (thứ cần quyết đầu tiên, ngoại lệ nổi bật, Duyệt / Từ chối có lý do); người lập thấy trạng thái chờ, khoá sửa; kết quả | BJ-02 | 08, 09, 10, 11, 12, 13, 14, CAP-01 |
| K3 | **Kết quả chưa rõ → xác minh:** không coi là thất bại; mã tham chiếu + giờ; điều gì an toàn; một nút xác minh; lối ra; BJ-17 là màn xác minh chung | BJ-02 | mọi BJ có ghi dữ liệu |
| K4 | **Kết quả xong:** tóm tắt (ai, lúc nào, bao nhiêu), bước tiếp hợp lý (xem tồn, làm tiếp, về Kho), không lặp danh sách dài | BJ-02 | mọi BJ có màn kết quả |
| K5 | **Chọn hàng → xử lý → bàn giao:** danh sách hàng đủ điều kiện, chọn lô / lượng, xác nhận, bàn giao | BJ-07 | 09, 10 |
| K6 | **Danh sách công việc:** danh sách phiếu / phiên với trạng thái, lọc theo trạng thái, mở tiếp đúng bước đang dở | BJ-05 | 06, 07, 08, 11, 12, 14, 16 |

Quy tắc chung cho mọi khuôn: một hành động chính mỗi trạng thái; footer hai nút (Phụ | Chính); `VBanner` chỉ cho ngoại lệ / cảnh báo / chặn; thành công cùng màn dùng toast; tiền chỉ Owner thấy (`FINANCIAL_MASKED` = không có số trong DOM).

## 6. Thành phần DS mới

Thêm khi phát sinh ở bước B; dựng trong `styles/components.css` (prototype) và đưa vào `vet45_design_system` ở giai đoạn 5.

| Thành phần | Phát sinh ở | Mô tả | Trạng thái |
|---|---|---|---|
| `ds24DotBadge` / `.ds24-badge--dot` | BJ-01 (bước A) | VBadge có chấm: đặc = cảnh báo, rỗng = nguy hiểm | ✅ prototype |
| `VStockRow` | BJ-01 (đề xuất) | List Row có cột phải hai tầng: số lượng mono + badge | ⬜ |
| Nút quét mã vạch trong `VSearchBar` | BJ-01 (đề xuất) | Hành động cuối ô tìm | ⬜ |

## 7. Dọn tài liệu `03.design`

Hiện trạng (đo 2026-10-16): 96 Screen Contract nhưng prototype dùng 73 màn; 36 file có đoạn chèn `### vX.Y — …` giữa nội dung (SCR-041: 11 đoạn); hai hệ đánh số chồng nhau (khung `## 1…10` + số cũ `### 1…9`); 7 file `RETIRED` chỉ vài dòng; 9 màn `FROZEN` không có trong prototype (002, 004, 005, 020, 022–024, 060, 061); Hub 090–096 có trong `hub.js` nhưng không trong danh sách luồng; Screen Contract `FROZEN` còn UIF `IN_REVIEW`; mốc phiên bản rải v3.10.1 → v4.6.7; `prototype/README.md` 13 KB chủ yếu là lịch sử.

### 7.1 Trước Giai đoạn 2 (~0,5 ngày, trước bước C của BJ đầu tiên) — plan: [T7-P-doc-don-tai-lieu.md](T7-P-doc-don-tai-lieu.md)

1. **Khuôn Screen Contract mới** (`03.design/screens/_TEMPLATE.md`): Mục đích → Lối vào / lối ra → Thứ bậc thông tin → Bảng trạng thái (trạng thái · hiện gì · làm được gì · lối ra) → Hành động → Quyền và che tài chính → Thành phần DS → Bảng chữ → Truy vết (BJ / UC / UIF). Không có mục lịch sử (git + CHANGELOG giữ).
2. **Khuôn UIF mới** (`03.design/flows/_TEMPLATE.md`): Việc thật → Lối vào / ra → Sơ đồ luồng (Mermaid, khớp prototype) → Bảng chuyển màn → Khuôn dùng chung áp dụng → Liên kết BJ khác.
3. Gom 7 file `RETIRED` vào `03.design/screens/RETIRED.md` (bảng: màn · thay bằng · từ phiên bản), xoá file lẻ.
4. Thêm `03.design/screens/INDEX.md`: bảng 96 màn · BJ · có trong prototype không · ghi chú (chưa dựng / đã gộp / Hub).
5. Thay `prototype/README.md` bằng hướng dẫn ngắn (chạy, cấu trúc, golden); lịch sử trỏ sang `html/CHANGELOG.md` và git.

### 7.2 Theo từng BJ (bước E, Giai đoạn 2)

Viết lại Screen Contract của các màn trong BJ và UIF của BJ theo khuôn 7.1.

### 7.3 Chốt đặc tả (sau Giai đoạn 2)

Rà toàn bộ, chốt `FROZEN` đồng loạt với mốc phiên bản mới; pattern `PAT-UI-UX` / `PAT-NAV` cập nhật theo các khuôn ở mục 5; registry.

---

## 8. Thứ tự, gói, đợt, mốc

### 8.1 Giai đoạn 1 — gói viết lại code

Bản đồ lớp cũ đo ngày 2026-10-16 trên `app/core.js`. "Lớp" = khối `===== vNNN… =====` đang định nghĩa / bọc / sửa màn của gói; tiền tố = tiền tố `data-*` và tên biến của BJ.

| Gói | BJ | Màn | Tiền tố | Lớp cũ phải gỡ | Màn định nghĩa nhiều lần | A (ngày) | Ghi chú |
|---|---|---|---|---|---|---|---|
| A0 | BJ-01 | 001, 003 (+004) | `bj01` | — | 0 | ✅ | Làm ở phiên review 2026-10-16 |
| A1 | **BJ-04, BJ-05** | 021; 025–029 | `io04`, `io05` | `app.js`; `v350` (gán lại `io05ApplyHandover`, `io05VisibleOrders`; xác minh UNKNOWN); `v393` (SCR-029 UNKNOWN, gán lại `io05VisibleOrders`); `v396` (`render021IO04`); `v360` (toast "Đã cập nhật lô lấy hàng") | 0 | ✅ | Móc `onScreenEnter` (khoá `UIF-NN:SCR-NNN`) thay wrapper `navigate` — các gói sau dùng lại |
| A2 | **BJ-06** | 030–035 | `io06` | `app.js`; `v350`; `v394` (SCR-032…035, bọc `renderFlowScreen` đổi tiêu đề SCR-031, gán lại 18 hàm `io06*`, listener `window` capture chặn trước listener chung); `legacy-cross-theme-copy` (SCR-031); `v360` (2 toast, đang chết) | 1 | ✅ | Móc `onPrevious` (theo luồng) thay nhánh trong `previousScreen` — các gói sau dùng lại |
| A3 | **CAP-01** | 062–065 | `cap` | `v360` (toàn bộ CAP-01, phần CAP-01 của `renderFlowInspector`) | 0 | 0,5 | |
| A4 | **BJ-02** | 006–013, 084 | `bj02` | `app.js`; `v350` (011, 012, 013); `v360` (`ensureBj02ReviewFixture`, toast); `v392` (cả 9 màn, gán lại 11 hàm + bọc 2); `v460` / `v461` (SCR-008); `v466`–`v468`; `v470` (tone "rủi ro"); `v471`; `legacy-sheet-cleanup`; `legacy-cross-theme-copy` (SCR-012); `hub.js` (`addPendingReviewExit` — để lại `hub.js`, xem plan A4 mục 2.5) | 4 | 2 | 58 trạng thái, demo chính; cụm "nhập nhanh đời đầu" đang chết, xoá ở A4 |
| A5 | **BJ-03, BJ-13, BJ-14** | 014–019; 085–089; 072–077 | `val03`, `val13`, `val14` | `app.js`; `v313`; `v430` (bọc `navigate`); `v460` / `v461` (bọc `navigate`, gán lại `val14CreateRun`); `v397`; `v398`; `v399`; `v350`; `v360` (3 fixture); `v431` | 10 | 3 | Helper chung → `app/shared-valuation.js` |
| A6 | **BJ-07, BJ-09, BJ-10** | 036, 037, 039, 041; 038, 056; 040 | `io07`, `ic09`, `ic10` | `app.js`; `v310`; `v350`; `v395` (gán lại 8 hàm `io07*`); `v3101`; `v351` (056); `v360` (041, toast); `legacy-cross-theme-copy` (038) | 12 | 3 | Màn dùng chung (036 / 037 / 041; 056 với BJ-15) dựng **theo luồng** qua móc `flowRenderers` (plan A6, khác hướng ban đầu "dựng ở `bj07.js`"); 056 của BJ-09 tạm rơi về chuỗi BJ-15 tới A9 |
| A7 | **BJ-08** | 042–047 | `ic08`, `ac310`, `ac321` | `app.js`; `v310`; `v320`; `v340` (gán lại `ac310CountGroup`, `ac310RecountGroup`); `v350` (gán lại `ic08ConfirmationSheet`, `ic08QuantityTrigger`); `v3100`; `v360`; `legacy-sheet-cleanup` | 6 | 2 | Helper `ac310*` / `ac321*` dùng chung cụm kiểm soát → `app/shared-control.js` (dựng ở gói này); bỏ mọi `render()` lúc nạp trong `core.js` (plan A7 mục 4.1) |
| A8 | **BJ-11, BJ-12** | 048–053; 066–071 | `cr11`, `cf12` | `app.js`; `v310`; `v350`; `v360` (toast) | 5 | 2,5 | Dùng `shared-control.js`. Chặng 0 khôi phục listener UIF-11/16/17 (mất từ A5) và `render()` trong `crSwitchFlow` / hẹn giờ duyệt (A7 xoá nhầm) — plan [A8](T7-P-A8-bj11-bj12.md) mục 2.6 |
| A9 | **BJ-15** | 054, 055, 057, 058, 059 (+056 từ A6) | `cf15` | `app.js`; `v310`; `v320` (cả khối); `v350` (seed `cf15Movements` lúc nạp, gán lại `cf15InventoryResult`, `cf15StockCardResult`, bọc 055 / 058); `v351` (cả khối); `legacy-sheet-cleanup` (cả khối) | 4 | 1,5 | Plan [A9](T7-P-A9-bj15.md). SCR-056 BJ-09 không có `movement` tự dựng trong `bj09.js` (tránh đệ quy qua `flowScreen`); `cf*` + `ac310ProductRow` → `shared-control.js` |
| A10 | **BJ-16, BJ-17** | 078–083 | `cr16`, `cr17` | `app.js`; `v310` (phần còn lại → xoá cả khối); `v350` (seed `cr16/17Cases` lúc nạp, `.replace` 079–082, `handoff-unknown` + `bj02-*`); `legacy-cross-theme-copy` (cả khối) | 9 | 2 | Plan [A10](T7-P-A10-bj16-bj17.md). Một bộ màn, hai luồng qua `flowRenderers`, `bj17.js` gọi lại helper `bj16.js`. Cơ chế K3 (`handoff-unknown`) → `bj17.js` + móc `onUnknownHandoff` cho UIF-05/06/07. `ac310ProductRow` / `cf*` đã ở `shared-control.js` (A9). Xong A10 = mọi luồng đã sở hữu |
| A11 | **Dọn khung** | — | — | `v350`, `v360`, `v361`, `v362`–`v364`, `v440`, `v450`, `v470`; harness trong `core.js` / `components.css`; CSS không dùng | — | 3 | Plan [A11](T7-P-A11-don-khung.md). `v440` / `simplifyNormalBanners` vẫn chạy trên luồng đã sở hữu (bọc `render`) — đo trước. Một API `__VET45_QA__`. CSS chỉ xoá luật không dùng; gom theo BJ dời Giai đoạn 2 |
| | **Cộng** | | | | | **~21** | |

Thứ tự gợi ý: A1 → A2 → A3 (gói nhỏ, ít lớp chồng, để quen cách làm) → A4 (BJ-02, demo chính) → A5 (cụm giá trị) → A6 → A7 (dựng `shared-control.js`) → A8 → A9 → A10 → A11. Plan gói `T7-P-A<n>-*.md` được viết ngay trước khi bạn làm gói đó.

**Mốc hết Giai đoạn 1:** mọi luồng dựng thẳng qua `renderers` / `flowRenderers` (A11 bỏ `ownedFlows`); `core.js` chỉ còn khung, harness ở `harness/`; không còn khối `vNNN-…`; golden khớp hoàn toàn với mốc trước Giai đoạn 1 (trừ khác biệt có chủ đích ghi trong CHANGELOG); bấm thử 0 lỗi JS.

### 8.2 Giai đoạn 2 — thiết kế lại theo đợt

| Đợt | BJ | Màn · trạng thái | B–E (ngày) | Phụ thuộc | Mốc khi xong |
|---|---|---|---|---|---|
| 0 | Dọn tài liệu 7.1 | | 0,5 | | Khuôn Screen Contract / UIF |
| 1 | BJ-01 Tồn kho | 2 · 10 | 1 | 7.1 | K1 (brief đã duyệt, plan [T7-P-bj01-ton-kho.md](T7-P-bj01-ton-kho.md)) |
| 1 | BJ-02 Nhận hàng mua | 9 · 58 | 3 | BJ-01 (nút "Nhận hàng") | K2, K3, K4; câu hỏi 15.1 chốt |
| 1 | BJ-03 Giá trị nhập ban đầu | 4 · 21 | 1,5 | BJ-02 (lối tắt sau nhận) | Khu Giá trị kho |
| 2 | BJ-05 Lấy & bàn giao + BJ-04 Giữ hàng | 6 · 26 | 1,5 | | K6 |
| 2 | BJ-06 Hàng khách trả | 6 · 38 | 1,5 | K2 | |
| 2 | BJ-07 Trả nhà cung cấp | 4 · 24 | 1,5 | K2 | K5 |
| 3 | BJ-09 Tình trạng hàng | 5 · 33 | 1,5 | K5, BJ-01 (lô hết hạn) | |
| 3 | BJ-10 Tiêu hủy | 4 · 29 | 1 | K5, BJ-09 | |
| 3 | BJ-08 Kiểm kê | 6 · 34 | 2 | K2, K6 | |
| 4 | BJ-11 Hủy & sửa sai | 6 · 37 | 1,5 | K2, K3 | |
| 4 | BJ-16 / 17 Đối soát / kết quả chưa rõ | 6 · 37 | 2 | K3 | |
| 4 | BJ-12 Tồn đầu kỳ | 6 · 36 | 1,5 | K2 | |
| 5 | BJ-13 Điều chỉnh giá trị | 3 · 16 | 1 | BJ-03 | |
| 5 | BJ-14 Giá vốn | 3 · 13 | 1,5 | BJ-03, BJ-13 | |
| 5 | BJ-15 Báo cáo & thẻ kho | 6 · 36 | 1,5 | mọi BJ ghi dữ liệu | |
| 5 | CAP-01 Chính sách tồn | 4 · 18 | 1 | BJ-01 | Kịch bản demo |
| | **Cộng** | | **~24,5** | | |

Đợt 1 quan trọng nhất: dựng 4 / 6 khuôn dùng chung, nên các đợt sau nhanh hơn. Plan thực thi BJ-01 ([T7-P-bj01-ton-kho.md](T7-P-bj01-ton-kho.md)) và plan dọn tài liệu ([T7-P-doc-don-tai-lieu.md](T7-P-doc-don-tai-lieu.md)) đã viết, **để dành cho Giai đoạn 2**; trước khi làm, phiên review rà lại theo code sau Giai đoạn 1.

---

## 9. Từng BJ: hướng thiết kế lại sơ bộ

Hướng dưới đây là **giả thuyết để mở bước B**, chưa phải quyết định; bước B chụp ảnh, critique và chốt. "Vấn đề đã biết" lấy từ critique 2026-10-15 và từ dữ liệu prototype.

### BJ-01 Theo dõi tồn & khả dụng (UIF-01)

- **Ai, khi nào:** nhân viên khi có khách hỏi; Owner đầu ngày / trước khi đặt hàng.
- **Màn:** SCR-001 Tồn kho (6 trạng thái), SCR-003 Chi tiết tồn kho (4); SCR-004 = sheet lô của 003.
- **Lối vào / ra:** Home → "Tra cứu tồn" / ô tìm / Quản lý kho → Tồn kho; ra: chi tiết → thẻ kho (BJ-15), nhận hàng (BJ-02), xử lý lô (BJ-09).
- **Vấn đề đã biết và hướng:** xem brief trong [T7-P-bj01-ton-kho.md](T7-P-bj01-ton-kho.md).
- **Khuôn:** dựng K1.
- **Tài liệu bước E:** SCR-001, SCR-003 (+ ghi chú 002, 004, 005, 060, 061 trong INDEX), UIF-01.

### BJ-02 Nhận hàng mua (UIF-02)

- **Ai, khi nào:** nhân viên khi NCC giao hàng (vài lần / tuần); Owner duyệt khi vượt chứng từ hoặc nhập nhanh.
- **Màn:** 006 Chọn cách nhận (5), 007 Chứng từ chờ nhận (7), 008 Thông tin nhập nhanh (5), 009 Hàng thực nhận (7), 084 Chi tiết hàng thực nhận (6), 010 Rà soát (7), 011 Phê duyệt (7), 012 Kết quả (7), 013 Đối soát kết quả (7).
- **Vấn đề đã biết:** hai chế độ (theo chứng từ / nhập nhanh) chỉ phân biệt bằng một dòng phụ; SCR-008 "kéo tệp" trên điện thoại, "Xác nhận quyền sở hữu" là tiêu đề không có ô tick; người duyệt không thấy lượng theo chứng từ cạnh lượng thực nhận; SCR-012 hoàn tất sơ sài, không có bước tiếp; SCR-012 UNKNOWN vừa vòng quay vừa nút; fixture SCR-009 thiếu nhà cung cấp.
- **Hướng sơ bộ:** màn chọn cách nhận rõ hai trường hợp (có chứng từ / hàng đến chưa có chứng từ); nhập dòng hàng nhanh hơn (quét mã, lô theo bao bì, bàn phím số); rà soát và duyệt đặt ngoại lệ lên đầu (chứng từ 120 · thực nhận 121 · +1); kết quả theo K4 với "Xác lập giá trị" (BJ-03, chỉ Owner), "Nhận tiếp", "Xem tồn"; UNKNOWN theo K3.
- **Khuôn:** dựng K2, K3, K4.
- **Liên kết:** từ BJ-01 ("Nhận hàng"), sang BJ-03.
- **Phụ thuộc quyết định:** câu hỏi 15.1 (Owner tự lập phiếu thì ai duyệt).
- **Tài liệu bước E:** SCR-006…013, 084; UIF-02.

### BJ-03 Xác lập giá trị nhập ban đầu (UIF-03)

- **Ai, khi nào:** Owner, sau mỗi lần nhận hàng (hàng nhận chưa có giá).
- **Màn:** 014 Hàng chờ xác lập (6), 015 Xác lập (7), 017 Rà soát (3), 019 Kết quả (5).
- **Vấn đề đã biết:** SCR-015 nút chính tắt không nói lý do; "0 đ/hộp"; khoảng cách không đều; thuật ngữ "Xác lập giá trị nhập ban đầu".
- **Hướng sơ bộ:** vào thẳng từ kết quả nhận hàng; một màn nhập giá theo dòng (giá gợi ý từ lần trước / chứng từ), lý do khi nút tắt nằm ngay cạnh; rà soát gộp vào bước xác nhận nếu ít dòng.
- **Khuôn:** K1, K3, K4.
- **Tài liệu bước E:** SCR-014, 015, 017, 019 (016, 018 đã retired), UIF-03.

### BJ-04 Giữ hàng (UIF-04) và BJ-05 Lấy hàng & bàn giao (UIF-05)

- **Ai, khi nào:** nhân viên soạn hàng theo đơn sỉ / online; giữ hàng do hệ thống, chỉ xem trong đơn.
- **Màn:** 021 Giữ hàng theo đơn (3); 025 Đơn cần lấy (5), 026 Hàng cần lấy (5), 027 Chi tiết lấy hàng (3), 028 Rà soát bàn giao (5), 029 Kết quả bàn giao (5).
- **Hướng sơ bộ:** danh sách đơn theo K6 (đang lấy / chờ bàn giao); lấy hàng theo lô FEFO gợi ý sẵn, đánh dấu từng dòng; thiếu hàng xử lý ngay trên dòng; bàn giao một bước khi đủ.
- **Khuôn:** dựng K6; K3, K4.
- **Liên kết:** từ đơn hàng (Theme 5); BJ-04 chỉ xem trong chi tiết đơn.
- **Tài liệu bước E:** SCR-021, 025…029 (+ 020, 022–024 trong INDEX), UIF-04, UIF-05.

### BJ-06 Hàng khách trả (UIF-06)

- **Màn:** 030 Danh sách (5), 031 Chi tiết (8), 032 Chi tiết hàng trả (8), 033 Phân loại (7), 034 Ngoại lệ lô cần duyệt (5), 035 Kết quả (5).
- **Vấn đề đã biết:** 030 và 031 cùng tiêu đề "Hàng khách trả" (lớp vá đổi tạm thành "Kiểm hàng khách trả").
- **Hướng sơ bộ:** hai mốc rõ ràng (nhận vào → phân loại); phân loại bằng lựa chọn lớn (bán lại được / cách ly / hỏng / hết hạn); ngoại lệ lô theo K2.
- **Khuôn:** K2, K3, K4, K6.
- **Tài liệu bước E:** SCR-030…035, UIF-06.

### BJ-07 Trả nhà cung cấp (UIF-07)

- **Màn:** 036 Hàng chờ trả NCC (6), 037 Chuẩn bị hàng trả (6), 039 Bàn giao (5), 041 Kết quả (7).
- **Hướng sơ bộ:** dựng K5 (chọn hàng → xử lý → bàn giao) đủ tổng quát để BJ-09 / 10 dùng lại mà **không mượn tên màn của BJ-07**.
- **Khuôn:** dựng K5; K3, K4, K6.
- **Tài liệu bước E:** SCR-036, 037, 039, 041 (phần BJ-07), UIF-07.

### BJ-09 Tình trạng hàng (UIF-09)

- **Màn:** dùng chung 036 / 037 / 041 + 038 Chuyển trạng thái (8), 056 Chi tiết movement (6).
- **Vấn đề đã biết:** màn vào là SCR-036 **"Hàng chờ trả nhà cung cấp"** (tên của BJ-07).
- **Hướng sơ bộ:** vào từ hàng / lô có vấn đề (BJ-01 "Xử lý lô hết hạn", Home "Lô sắp hết hạn"); chọn tình trạng đích bằng lựa chọn lớn; gửi duyệt theo K2.
- **Khuôn:** K5 (từ BJ-07), K2.
- **Tài liệu bước E:** SCR-038, 056 + phần BJ-09 của 036 / 037 / 041, UIF-09.

### BJ-10 Tiêu hủy (UIF-10)

- **Màn:** dùng chung 036 / 037 / 041 + 040 Yêu cầu tiêu hủy (10 trạng thái).
- **Vấn đề đã biết:** cùng vấn đề tên màn vào như BJ-09; SCR-040 gánh 10 trạng thái (lập, duyệt, chờ tiêu hủy, xác nhận hoàn tất) trong một màn.
- **Hướng sơ bộ:** đi tiếp từ BJ-09 (hàng hỏng / hết hạn); tách rõ "đề nghị" → "duyệt" → "xác nhận đã tiêu hủy" (K2 + một bước xác nhận có ảnh bằng chứng).
- **Khuôn:** K5, K2.
- **Tài liệu bước E:** SCR-040 + phần BJ-10 của 036 / 037 / 041, UIF-10.

### BJ-08 Kiểm kê (UIF-08)

- **Màn:** 042 Danh sách phiên (6), 043 Tạo phiên (5), 044 Đếm mù (5), 045 Chênh lệch và đếm lại (6), 046 Duyệt điều chỉnh (6), 047 Kết quả (6).
- **Vấn đề đã biết:** SCR-044 "Hủy phiên" đặt ngang hàng cạnh "Nộp kết quả đếm"; đếm phải gõ bàn phím từng dòng, không quét mã, không +/−.
- **Hướng sơ bộ:** đếm mù tối ưu một tay (quét mã → bàn phím số → dòng kế tiếp); huỷ phiên chuyển vào menu của phiên; chênh lệch nổi bật bằng màu cảnh báo (đã có); duyệt theo K2.
- **Khuôn:** K2, K3, K4, K6.
- **Tài liệu bước E:** SCR-042…047, UIF-08.

### BJ-11 Hủy & sửa sai (UIF-11)

- **Màn:** 048 Nghiệp vụ cần kiểm soát (5), 049 Chi tiết nghiệp vụ (8), 052 Hủy hoặc chọn cách sửa (6), 050 Nội dung sửa sai (5), 051 Duyệt (5), 053 Kết quả (8).
- **Hướng sơ bộ:** vào từ chính phiếu bị sai (chi tiết nghiệp vụ, thẻ kho), không chủ yếu từ menu; một màn giải thích "huỷ được hay phải sửa" bằng lời thường; duyệt theo K2.
- **Khuôn:** K2, K3, K4.
- **Tài liệu bước E:** SCR-048…053, UIF-11.

### BJ-16 Đối soát sai lệch và BJ-17 Kết quả chưa rõ (UIF-16, UIF-17)

- **Màn:** 078 Hồ sơ cần kiểm tra (7), 079 Bằng chứng & kết luận (10), 080 Phương án xử lý (5), 081 Đang khôi phục số liệu (5), 082 Rà soát kết quả (3), 083 Kết quả xử lý (6); BJ-17 dùng 078 / 079 / 080 / 082 / 083.
- **Vấn đề đã biết:** thuật ngữ kỹ thuật ("Số liệu hiển thị / Sổ kho / Nguồn nghiệp vụ / Bảo vệ phạm vi").
- **Hướng sơ bộ:** viết lại bằng lời Owner ("Số trên app lệch 2 hộp so với sổ; sổ vẫn đúng"); một bộ màn, hai lối vào (sai lệch / kết quả chưa rõ); kết luận → hành động cụ thể (khôi phục số / chuyển sửa sai BJ-11).
- **Khuôn:** K3 (là đích của mọi K3), K4.
- **Tài liệu bước E:** SCR-078…083, UIF-16, UIF-17.

### BJ-12 Khởi tạo tồn đầu kỳ (UIF-12)

- **Màn:** 066 Khởi tạo tồn kho (8), 067 Dữ liệu đầu kỳ (5), 068 Kết quả kiểm tra (6), 069 Rà soát (5), 070 Duyệt (5), 071 Kết quả (7).
- **Hướng sơ bộ:** trình hướng dẫn 3 bước (tải tệp → sửa lỗi → gửi duyệt) có tiến trình; lỗi tệp liệt kê theo dòng, sửa được ngay; chọn tệp bằng nút (không "kéo tệp" trên điện thoại).
- **Khuôn:** K2, K3, K4.
- **Tài liệu bước E:** SCR-066…071, UIF-12.

### BJ-13 Điều chỉnh giá trị hàng nhập (UIF-13)

- **Màn:** 085 Danh sách (6), 086 Phân bổ (5), 089 Kết quả (5); 087 / 088 đã retired.
- **Hướng sơ bộ:** nhập một khoản điều chỉnh, chọn cách phân bổ, xem trước số mỗi sản phẩm nhận; chỉ Owner.
- **Khuôn:** K2, K3, K4.
- **Tài liệu bước E:** SCR-085, 086, 089, UIF-13.

### BJ-14 Tính và công bố giá vốn (UIF-14)

- **Màn:** 072 Công việc giá vốn (4), 074 Tính và rà soát (5), 077 Kết quả (4); 073 / 075 / 076 đã retired.
- **Vấn đề đã biết:** thuật ngữ "Bình quân liên hoàn / cuối kỳ" không giải thích; màu tiền đã sửa (bước colorize).
- **Hướng sơ bộ:** một màn "chốt kỳ" kể theo thứ tự: kỳ nào → việc gì còn chặn → kết quả tính → phần chênh lệch sẽ ghi → Công bố; giải thích phương pháp bằng một dòng.
- **Khuôn:** K3, K4.
- **Tài liệu bước E:** SCR-072, 074, 077, UIF-14.

### BJ-15 Báo cáo tồn và thẻ kho (UIF-15)

- **Màn:** 054 Tra cứu thẻ kho (5), 055 Danh sách biến động (10), 056 Chi tiết movement (6), 057 Dòng thời gian nguồn (5), 058 Xuất báo cáo (5), 059 Kết quả xuất (5).
- **Hướng sơ bộ:** vào từ một sản phẩm (BJ-01) là đường chính; bộ lọc thời gian gọn; ngày ghi nhận / ngày nghiệp vụ là một công tắc; xuất báo cáo là hành động phụ.
- **Khuôn:** K1, K6.
- **Tài liệu bước E:** SCR-054…059, UIF-15.

### CAP-01 Chính sách tồn & cận hạn

- **Màn:** 062 Chính sách tồn (5), 063 Hàng cận hạn (5), 064 Rà soát (4), 065 Kết quả (4).
- **Hướng sơ bộ:** đặt ngưỡng ngay trong chi tiết sản phẩm (BJ-01, khi "Chưa có ngưỡng tồn"); màn thiết lập chung cho mặc định cửa hàng.
- **Khuôn:** K2 (nếu cần duyệt), K4.
- **Tài liệu bước E:** SCR-062…065.

---

## 10. Luồng demo

| Bước | BJ | Người | Thấy gì |
|---|---|---|---|
| 1 | 12 Khởi tạo tồn | Owner | Tải tệp tồn đầu kỳ, sửa lỗi, duyệt, tồn kho kích hoạt |
| 2 | 01 Tồn kho | Owner | Danh sách có chỉ báo; mở một sản phẩm tồn thấp |
| 3 | 02 Nhận hàng | Nhân viên → Owner | Nhận theo chứng từ, vượt 1 hộp, Owner duyệt từ "Cần chú ý" |
| 4 | 03 Giá trị nhập | Owner | Từ kết quả nhận hàng xác lập giá |
| 5 | (Theme 5 bán) → 05 Lấy hàng | Nhân viên | Lấy theo lô gợi ý, bàn giao |
| 6 | 08 Kiểm kê | Nhân viên → Owner | Đếm mù, chênh lệch, duyệt điều chỉnh |
| 7 | 14 Giá vốn | Owner | Chốt kỳ, công bố |
| 8 | 15 Báo cáo | Owner | Thẻ kho của sản phẩm ở bước 2 |

Sau đợt 5: kịch bản golden `SC_demo_*` đi đúng các bước trên.

## 11. Sau Giai đoạn 2

| Giai đoạn | Việc | Ai | Ước lượng |
|---|---|---|---|
| 3. Hoàn thiện | Critique lại toàn theme (≥ 32/40); `/impeccable polish`; Home Kho nối đủ lối vào | Bạn, theo plan; phiên review review | 2–3 ngày |
| 4. Chốt đặc tả | Mục 7.3; áp mục 13; registry | Phiên review viết, bạn duyệt | 1–2 ngày |
| 5. Nối sang Flutter | Rà plan T7-0d, T7-1, T7-0e… theo prototype mới; sửa phần BJ-02 / 03 đã code; T7-15 dựng Home candidate; thành phần mục 6 vào `vet45_design_system` | Phiên review viết plan, bạn code | theo từng plan |

## 12. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| Giai đoạn 1 dài (~20 ngày) trước khi thấy thiết kế mới | Gói nhỏ trước (A1–A3) để quen cách làm; mỗi gói kết thúc bằng golden khớp nên dừng giữa chừng vẫn an toàn |
| Code viết lại ở Giai đoạn 1 lại bị viết lại ở Giai đoạn 2 | Chấp nhận (quyết định 2026-10-16); Giai đoạn 2 sửa trên code sạch nên nhẹ hơn |
| Brief chờ duyệt lâu làm chậm Giai đoạn 2 | Brief ngắn, có câu hỏi chốt cụ thể; phiên review viết brief BJ sau trong lúc bạn làm BJ trước |
| Thiết kế lại một BJ làm gãy luồng của BJ khác (nút nhảy chéo) | Kịch bản golden của BJ khác phải khớp; nút nhảy chéo chỉ gọi `navigate` / `ThemeApp` |
| Khuôn dùng chung dựng ở đợt 1 chưa đủ tổng quát | Mô tả khuôn ở mục 5 ngay khi dựng; đợt 2 được phép chỉnh khuôn (ghi CHANGELOG, chạy lại golden BJ đã làm) |
| Đổi chữ vượt đặc tả | Mọi chữ mới vào mục 13, chỉ áp khi duyệt |
| Prototype đi xa hơn backend làm được | Bước B giữ nguyên quy tắc nghiệp vụ; điểm nào cần backend mới ghi rõ trong brief |
| Phần BJ-02 / 03 đã code Flutter phải làm lại | Chấp nhận; giai đoạn 5 lập plan sửa riêng |

## 13. Đề xuất sửa đặc tả và thành phần mới (điền dần)

| BJ | Màn | Loại (luồng / chữ / trạng thái / thành phần) | Đề xuất | Đã duyệt |
|---|---|---|---|---|
| 02 | SCR-011 | trạng thái | Dòng "Vượt chứng từ" hiện lượng theo chứng từ cạnh lượng thực nhận | ⬜ |
| 01 | SCR-001 | thành phần | `VStockRow`: List Row có cột phải hai tầng (số khả dụng mono + badge tình trạng) | ⬜ |
| 01 | SCR-001 | chữ / thành phần | Nút "Quét mã vạch" trong ô tìm | ⬜ |
| 01 | SCR-003 | luồng / chữ | Tiêu đề = tên sản phẩm; "Gợi ý nhập thêm …" + "Nhận hàng" → BJ-02; "Xử lý lô hết hạn" → BJ-09 | ⬜ |

## 14. Tiến độ

### Giai đoạn 1 — viết lại code

| Gói | BJ | Plan | Làm | Review |
|---|---|---|---|---|
| A0 | BJ-01 | — | ✅ 2026-10-16 (phiên review) | ✅ |
| A1 | BJ-04, BJ-05 | ✅ [plan](T7-P-A1-bj04-bj05.md) | ✅ | ✅ |
| A2 | BJ-06 | ✅ [plan](T7-P-A2-bj06.md) | ✅ | ✅ |
| A3 | CAP-01 | ✅ [plan](T7-P-A3-cap01.md) | ✅ | ✅ |
| A4 | BJ-02 | ✅ [plan](T7-P-A4-bj02.md) | ✅ | ✅ |
| A5 | BJ-03, BJ-13, BJ-14 | ✅ [plan](T7-P-A5-gia-tri.md) | ✅ | ✅ |
| A6 | BJ-07, BJ-09, BJ-10 | ✅ [plan](T7-P-A6-bj07-bj09-bj10.md) | ✅ | ✅ |
| A7 | BJ-08 | ✅ [plan](T7-P-A7-bj08.md) | ✅ | ✅ |
| A8 | BJ-11, BJ-12 | ✅ [plan](T7-P-A8-bj11-bj12.md) | ✅ | ✅ |
| A9 | BJ-15 | ✅ [plan](T7-P-A9-bj15.md) | ✅ | ✅ |
| A10 | BJ-16, BJ-17 | ✅ [plan](T7-P-A10-bj16-bj17.md) | ✅ | ✅ |
| A11 | Dọn khung | ✅ [plan](T7-P-A11-don-khung.md) | ✅ | ✅ |

### 14.1 Review Giai đoạn 1 (2026-10-19)

Rà trên working tree sau A11 (chưa commit; HEAD `4c7020013`), từng plan ghi kết quả ở mục 10 của plan đó. Code của mỗi gói đã bị gói sau sửa tiếp nên rà theo **trạng thái cuối**, đối chiếu golden với các mốc còn lưu.

**Kiểm chung**

| Kiểm | Kết quả |
|---|---|
| `node --check app/*.js harness/*.js` | Sạch |
| Golden toàn bộ (1348 ca) | 0 lỗi JS; khớp hoàn toàn `tools/.golden-a11-base` / `-final` — nhưng hai mốc này chụp **sau** khi A11 mất CSS, nên không chứng minh được "giao diện không đổi" |
| So với mốc trước Giai đoạn 1 (`tools/.golden-base` 911 ca, `tools/.golden-a5-base` 960 ca, chung tên) | **Chữ khớp 100%.** Hình: mọi ca lệch 4 góc khung thiết bị (A11); 23 ca trạng thái lệch thật — 5 do A8, 18 do A11 (+ các ca `SC_*` đi qua cùng màn) |
| So với `.golden-a10` (186 ca, ngay sau A10) | Chỉ lệch các ca do A11 → A1–A10 sạch về hình trừ A8 |
| Sau A12 (2026-10-19) | Mốc `tools/.golden-phase1`: **0 khác biệt** (chữ + hình) với `.golden-a5-base`, `.golden-base`, `.golden-a10`, `.golden-a8-check` trên mọi ca chung tên; 0 lỗi JS; bấm thử các luồng đã sửa 0 lỗi |
| Mốc gốc trước A1 | **Không còn** (`tools/.golden-base` bị chụp lại sau A4, 15:32 17/10); git không giữ được vì prototype T7-P0 chưa từng commit đủ (xem R6) |
| Bấm thử (mọi màn × trạng thái, bấm lần lượt từng nút + nút footer kế tiếp, Hub) | 1301 lần bấm, **0 lỗi JS** |
| "Một định nghĩa" (checklist 4.1 bước 4) | Lúc review chưa đạt: `bj03.js` 15, `bj13.js` 10, `bj14.js` 5 (`val14CreateRun` ×3), `bj07.js` 7 hàm định nghĩa lặp → **đã sửa ở A12 R3** (+ 10 hàm dạng bí danh `X = tênHàmCụcBộ` sửa ở R7) |

**Bài học (thêm vào checklist 4.1 cho Giai đoạn 2):**

- Mỗi gói so **toàn bộ** golden với **một** mốc cố định chụp trước khi đụng code; không chụp lại mốc giữa gói. Mốc chụp lại = mất bằng chứng (A11). Chụp tập con (A7, A8) để lọt lệch.
- Chưa chạy được golden thì không đánh "Làm ✅" (A9).
- Khi bỏ một bước sửa sau dựng (`v361`, `v470`…), đo pipe vs bare cho **mọi** màn còn dùng helper chung (A8 bỏ sót footer duyệt).

### 14.2 Gói A12 — sửa sau review Giai đoạn 1 ✅ (2026-10-19, phiên review làm theo yêu cầu người dùng) — **hết Giai đoạn 1**

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/`. Server: `python3 -m http.server 8765 --bind 127.0.0.1 &`.

**R0. Mốc.** Đổi tên `tools/.golden-a11-final` → `tools/.golden-a12-pre` (trạng thái hiện tại). Mốc đích để so: `tools/.golden-a5-base` (960 ca, trước A5), `tools/.golden-base` (911 ca, sau A4), `.golden-a10` (186 ca, sau A10), `tools/.golden-a8-check` (110 ca). Đích của A12: so với **cả bốn** mốc (chỉ trên ca chung tên) → `Khớp hoàn toàn`, chấp nhận duy nhất: (a) ca nháy con trỏ ≤ 30 điểm ảnh ở ô tìm / ô nhập (`SC_attention_UIF-09_1_open`, `UIF-02_SCR-009_VALIDATION_ERROR_quick`, `SC_bj16_denied_1_exit`, `SC_bj17_committed_0`, `UIF-11_SCR-048_READY`, `UIF-13_SCR-085_FINANCIAL_MASKED`); (b) khác biệt có chủ đích đã ghi CHANGELOG (handoff UNKNOWN của A8 chặng 0 — chỉ khác `.golden-a7-after`, không khác bốn mốc trên).

**R1. CSS mất ở A11 (chặn).** ✅ 2026-10-19 (phiên review) — góc khung: luật `.device-preview` bị đảo thứ tự (bản bo 32px thắng bản 34px) + một bản sao bo 32px trong `screens.css`; đặt lại thứ tự `styles.css` gốc (base → is-wide → v0.2.3 34px → khung chuẩn 402×874 → `:not(.is-wide)`), xoá bản sao. Khối "Review cards" chèn lại đúng chỗ. Không cần bước 3: `UIF-13_SCR-089_*` cũng hết lệch. Kết quả: **0 khác biệt** với cả bốn mốc R0. Hướng gốc:

1. *Góc khung thiết bị* (mọi ca): so một ảnh bất kỳ (`CAP-01_SCR-062_READY.png`) giữa `.golden-a10` và bản chụp mới — chỉ khác 4 góc 45×45. Tìm luật `.device-preview` / `#review-stage` / nền sân khấu (bo góc 32 vs 34px, viền 8px, `box-shadow`, màu nền sau góc) đã đổi khi tách `harness/workbench.css`; đối chiếu bản legacy trong git (`git show HEAD:specs/themes/theme-07/03.design/prototype/html/workbench.css`, `…/styles.css`, `…/v281-device-frame-correction.css`) và trả lại đúng giá trị + thứ tự. Làm bước này **trước** để `compare` không còn lệch ở mọi ca.
2. *Khối "Review cards"*: chèn vào `styles/components.css` ngay sau dòng `.approval-actions > :last-child { min-height:52px; }` (≈ dòng 1139, đúng vị trí trong chuỗi luật cũ), bản gốc ở `git show HEAD:specs/themes/theme-07/03.design/prototype/html/styles.css` dòng 2111–2117:
   ```css
   /* Review cards composed from VCardHeader/VCardContent-like anatomy */
   .review-card-header { min-height:auto; padding:var(--v-space-4) var(--v-space-4) var(--v-space-2); border-bottom:0; background:var(--v-color-surface); }
   .review-card-header strong { font-size:14px; line-height:19px; font-weight:600; }
   .review-card-body { gap:var(--v-space-2); padding:0 var(--v-space-4) var(--v-space-4); }
   .review-line { grid-template-columns:minmax(100px,.8fr) minmax(0,1.2fr); gap:var(--v-space-3); }
   .review-line > span { color:var(--v-color-text-secondary); font-size:13px; line-height:20px; }
   .review-line > strong { color:var(--v-color-text-primary); font-size:13px; line-height:20px; font-weight:600; }
   ```
   Đổi biến `--v-*` sang `--vet45-v2-*` theo cách T7-P0 đã đổi các dòng ngay trên (`.app-actions` dùng `--vet45-v2-space-3`, `--vet45-v2-surface-default`; tra `styles/tokens.css` cho `text-secondary` / `text-primary`).
3. Chụp `tools/.golden-a12-r1`, so với bốn mốc R0. Còn ca lệch hình (dự kiến `UIF-13_SCR-089_*` nếu chưa hết) → mở ảnh hai bên, tìm phần tử lệch, tìm luật legacy trong git cho phần tử đó mà `styles/*` không còn **và** không có trong `tools/.usage-a11-6/_css-deletable.txt` → trả lại đúng chỗ. Lặp tới khi chỉ còn 5 ca của R2.

**R2. Footer duyệt và dòng "Điều chỉnh" của A8 (chặn).** ✅ 2026-10-19 (phiên review, theo yêu cầu người dùng) — 5 ca khớp `tools/.golden-a5-base`; so với trước khi sửa chỉ khác các ca SCR-050 / 051 / 070 (+ `SC_bj11_*` / `SC_bj12_*` / `SC_entry_UIF-11/12_approver` đi qua), chữ không đổi, 0 lỗi JS.

1. `shared-control.js` `ac310ApprovalFooter`: viết sẵn kết quả của `normalizeDualFooters` (`v361`) như `bj02.js` (SCR-011) / `cap01.js` (SCR-064) đã làm — footer thêm lớp `v361-dual-footer v361-dual-footer--danger`, `data-ds-prop-layout="Dual" data-ds-prop-tone="Danger"`; nút "Từ chối" (đứng trước nút chính) thêm `data-ds-prop-tone="VComponentTone.danger" data-ds-profile="button.destructiveSecondary"`. Nguồn chuẩn: `git show HEAD:specs/themes/theme-07/03.design/prototype/html/v361-footer-action-correction.js`. Dùng ở `bj11.js` (SCR-051) và `bj12.js` (SCR-070).
2. `bj11.js` `bj11KeyValueSurface`: dòng có cờ nhấn mạnh (`r[2]`) dựng bằng `ds24KeyValueRow(label, value, true)` (lớp `ds24-key-value-row--emphasis`, `data-ds-prop-state="Emphasis"`) như trước A8; chỉ thêm `v470-kv--attention` nếu mốc gốc có (mở `UIF-11_SCR-051_READY.png` trong `tools/.golden-a5-base`: "Điều chỉnh −2 hộp" đậm đen, không màu cảnh báo). Giữ dấu trừ U+2212 (mốc gốc SCR-051 có `−2`; SCR-050 có `-2` — đối chiếu `.txt`).
3. Đích: `UIF-11_SCR-050_READY`, `_VALIDATION_ERROR`, `SCR-051_READY`, `_VALIDATION_ERROR`, `UIF-12_SCR-070_READY` khớp `tools/.golden-a5-base`.

**R3. Một định nghĩa (A5, A6).** ✅ 2026-10-19 (phiên review) — cách làm thực tế: bản thắng nằm trong IIFE `v395`/`v397`–`v399` và cần biến cục bộ của khối, nên **xoá 37 bản chết** (tree-sitter, đúng ranh giới hàm) và khai báo `let tên…;` một dòng ở chỗ bản chết đầu tiên (không còn biến toàn cục ngầm); `val14CreateRun` gộp: `bj14ApplyPolicy` / `BJ14_COST_POLICY` lên cấp file, bản `v399` `return bj14ApplyPolicy(run)`, bỏ `baseCreate14`; bỏ export thừa `window.val03ApplySourceUpdate` / `val13ApplySourceUpdate` / `val13V398` (bj14 gọi `val13Engine`). Đoạn đếm rỗng; golden 1348 ca khớp hoàn toàn bản sau R2; 0 lỗi JS. Kiểm `grep "=\s*function"` của plan A5/A6 vẫn ra các phép gán trong IIFE — đó là định nghĩa duy nhất, dùng đoạn đếm dưới đây làm tiêu chí. Hướng gốc (giữ để đối chiếu): Với từng hàm trong danh sách ở review A5 / A6: giữ **bản cuối** (bản đang chạy), đổi `name=function(...)` thành `function name(...)` đặt ở chỗ bản đầu, xoá bản đầu. `val14CreateRun`: gộp ba bản thành một = thân bản `v399` (dòng 93) + `applyPolicy(r)` trước `return`; xoá `baseCreate14`. Cẩn thận hàm được **chụp tham chiếu lúc nạp** (`const x = tênHàm`) — grep `=\s*val0\|=\s*val1\|=\s*io07` trước khi xoá. `window.val13V398` → `bj14.js` gọi thẳng `val13Engine.methodEligible`. Kiểm: đoạn đếm ở cuối mục này rỗng; golden khớp `tools/.golden-a12-r1` (sau R1–R2) hoàn toàn.

```bash
node -e 'const fs=require("fs");for(const f of fs.readdirSync("app")){const s=fs.readFileSync("app/"+f,"utf8"),m={};for(const r of s.matchAll(/(?:^|[\s;{}(])function\s+([A-Za-z0-9_$]+)\s*\(|(?:^|[\s;{}])([A-Za-z0-9_$]+)\s*=\s*function\b/gm)){const n=r[1]||r[2];m[n]=(m[n]||0)+1}const d=Object.keys(m).filter(k=>m[k]>1);if(d.length)console.log(f,d.join(" "))}'
```

**R4. Chú thích.** ✅ 2026-10-19. `core.js`: xoá dòng 13 `/* ===== app.js ===== */`, các dòng `// v1.7.0 …`, `// v1.8.0 …` (2 chỗ), `/* flowScreen assigns after framework */`; dòng 7 bỏ `simplifyNormalBanners`. Đầu `bj01.js` / `bj04.js`: sửa câu cụt "… màn dựng"; `bj05/06/07.js`: bỏ thụt `  */`; `cap01.js`: bỏ "Còn ở core.js (gỡ dần ở A11): fallback-exit". `bj10.js`: bỏ lớp chuyển tiếp `render0xxBJ10`.

**R5. Công cụ và thư mục mốc.** ✅ 2026-10-19 — mốc `tools/.golden-phase1` (1348 ca, 0 lỗi JS, 0 khác biệt với bốn mốc gốc) chụp **trước** khi xoá 32 thư mục mốc tạm; README prototype trỏ mốc mới. `tools/golden.mjs`: bỏ nhánh `||window.__VET45_V350__` / `__VET45_V3101__`. Sau khi A12 đạt: chụp mốc Giai đoạn 2 `tools/.golden-phase1`; xoá mọi `tools/.golden-a*`, `tools/.golden-{base,check,sc-a,sc-b,bj02-sc}`, `tools/.full-*`, `tools/.usage-*`, và `.golden-*` ở gốc `html/`. `tools/.gitignore` thêm `.full*/` và `.usage*/`.

**R6. Ghi lại và commit.** ✅ 2026-10-19 — CHANGELOG `[5.3.1]`, `manifest.json` / badge 5.3.1, `sync-registry.py`; commit theo yêu cầu người dùng. CHANGELOG `[5.3.1] — T7-P A12: sửa sau review Giai đoạn 1` (R1 CSS trả lại, R2 footer / dòng nhấn mạnh, R3 một định nghĩa); sửa mục 5.3.0 bỏ `simplifyNormalBanners` khỏi danh sách khung. `manifest.json` 5.3.1; `python3 tools/sync-registry.py`. **Commit gồm cả cấu trúc T7-P0 + A11 chưa từng commit**: 214 file legacy đã xoá, `styles/`, `harness/`, `data/`, `index.html` — kiểm bằng `git stash -u && git status` không còn gì rồi mở `index.html` từ một bản `git worktree` sạch. `detect_changes()` trước commit. Commit: `refactor(prototype): T7-P A11+A12 — framework cleanup, harness split, post-review fixes`.

**R7. Tách lại cụm giá trị theo BJ (A5).** ✅ 2026-10-19 (phiên review, theo yêu cầu người dùng) — helper giao diện của hai khối → `VAL_UI_430` / `VAL_UI_461` trong `shared-valuation.js` (giữ nguyên thân; 5 helper chỉ BJ-03 dùng ở lại `bj03.js`); phần dựng + listener tách thành khối riêng theo BJ: `bj03.js` dựng SCR-014/015/016/017/019, `bj13.js` SCR-085…089, `bj14.js` SCR-072…077. Xoá mã chết lộ ra: nhánh listener `data-v430-val14-*` (không màn nào phát, tham chiếu biến không tồn tại), `VALUATION_FLOWS`, `SCREEN_ALIAS`, `if(typeof renderers==='undefined')`, `val03Commit = val03Commit430` lặp. Gộp nốt định nghĩa trùng dạng bí danh mà đoạn đếm R3 bỏ sót: `val03EvidenceState` / `Source` / `GroupSelectedQty` / `Calc`, `val03Commit` (bản `v397` chết), `val13SelectedTargets` / `Preview` / `PreviewHashOf` / `CanOpenAllocation` / `CanPreview`. Golden 1348 ca khớp hoàn toàn bản sau R3; 0 lỗi JS. Mô tả lúc phát hiện (giữ để đối chiếu): Phát hiện khi làm R3: `bj03.js` chứa khối `v430` dựng SCR-014 (BJ-03) **và SCR-085 (BJ-13)** + listener `data-v430-val14-*` (BJ-14); `bj14.js` chứa khối `v461` dựng SCR-015/017/019 (BJ-03), **SCR-086/089 (BJ-13)** và SCR-072/074/077 (BJ-14); `bj13.js` chỉ có fixture + helper. Mục tiêu A5 "BJ-NN → `app/bjNN.js`" chưa đạt. Hướng: chuyển hàm dựng + listener theo màn về đúng file (helper cục bộ dùng chung của `v430` / `v461` → `shared-valuation.js`), golden khớp hoàn toàn. Ước lượng ~0,5–1 ngày. Có thể dời sang bước C của Đợt giá trị ở Giai đoạn 2 (khi BJ-03/13/14 được viết lại) nếu chấp nhận.

Xong A12: plan tổng mục 14 đổi Review A5 / A6 / A8 / A11 sang ✅ và ghi "Hết Giai đoạn 1".

### Giai đoạn 2 — thiết kế lại

| Việc | B. Brief | C. Dựng | D. Kiểm | E. Ghi lại |
|---|---|---|---|---|
| Dọn tài liệu 7.1 ([plan](T7-P-doc-don-tai-lieu.md)) | — | ⬜ | — | — |
| BJ-01 ([plan](T7-P-bj01-ton-kho.md), rà lại sau GĐ1) | ✅ duyệt 2026-10-16 | ⬜ | ⬜ | ⬜ |
| BJ-02 | ⬜ | ⬜ | ⬜ | ⬜ |
| BJ-03 | ⬜ | ⬜ | ⬜ | ⬜ |
| BJ-04 / 05 | ⬜ | ⬜ | ⬜ | ⬜ |
| BJ-06 | ⬜ | ⬜ | ⬜ | ⬜ |
| BJ-07 | ⬜ | ⬜ | ⬜ | ⬜ |
| BJ-09 | ⬜ | ⬜ | ⬜ | ⬜ |
| BJ-10 | ⬜ | ⬜ | ⬜ | ⬜ |
| BJ-08 | ⬜ | ⬜ | ⬜ | ⬜ |
| BJ-11 | ⬜ | ⬜ | ⬜ | ⬜ |
| BJ-16 / 17 | ⬜ | ⬜ | ⬜ | ⬜ |
| BJ-12 | ⬜ | ⬜ | ⬜ | ⬜ |
| BJ-13 | ⬜ | ⬜ | ⬜ | ⬜ |
| BJ-14 | ⬜ | ⬜ | ⬜ | ⬜ |
| BJ-15 | ⬜ | ⬜ | ⬜ | ⬜ |
| CAP-01 | ⬜ | ⬜ | ⬜ | ⬜ |

## 15. Câu hỏi còn mở

| # | Câu hỏi | Chốt ở |
|---|---|---|
| 15.1 | Owner tự lập phiếu (vd. nhập hàng nhanh khi nhân viên vắng) thì ai duyệt? Nghiệp vụ yêu cầu người duyệt khác người lập; với Owner + nhân viên, nhân viên duyệt phiếu của Owner là ngược vai | Bước B của BJ-02 |
| 15.2 | ~~Quét mã vạch trong prototype mô phỏng thế nào~~ → sheet giả lập có nút "Quét thử" (plan BJ-01) | ✅ |
| 15.3 | BJ-09 / 10 có còn cần màn danh sách riêng không, hay luôn vào từ hàng / lô có vấn đề | Bước B của BJ-09 |
