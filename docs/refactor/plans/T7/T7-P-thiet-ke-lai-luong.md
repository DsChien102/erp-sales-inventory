# T7-P — Thiết kế lại Theme 7 trên prototype (plan tổng thể)

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ (2026-10-16, bản chi tiết) · Giai đoạn 2 sắp lại theo chặng hành trình 📝 (2026-10-20, chờ duyệt — mục 8.2) · Chặng 2 (BJ-02 → BJ-03 → BJ-13): plan + brief ✅ (duyệt 2026-10-21, theo đề xuất) | Làm 🔄 | Review 🔄 · Chặng 3 (BJ-04 / 05 → BJ-06): plan + brief ✅ (duyệt 2026-10-24, theo đề xuất) · Chặng 4 (BJ-09 → BJ-07 / BJ-10): plan + brief ✅ (duyệt 2026-10-25, theo đề xuất — [BJ-09](T7-P-bj09-tinh-trang-hang.md), [BJ-07 + BJ-10](T7-P-bj07-bj10-tra-ncc-tieu-huy.md)) · Chặng 5 (BJ-08 → BJ-11 → BJ-16 / 17): plan + brief 📝 (2026-10-25, chờ duyệt — [BJ-08](T7-P-bj08-kiem-ke.md), [BJ-11](T7-P-bj11-sua-sai.md), [BJ-16 + BJ-17](T7-P-bj16-bj17-doi-soat.md))
> Thuộc [PLAN.md](../../PLAN.md) mục "Theme 7". Làm sau [T7-P0](T7-P0-don-prototype.md) (✅).
> Phạm vi: prototype `specs/themes/theme-07/03.design/prototype/html` và tài liệu thiết kế `specs/themes/theme-07/03.design` (Screen Contract, UIF, pattern). Code Flutter làm theo prototype đã chốt (giai đoạn 5).
> **Thiết bị (chốt 2026-10-20, cho cả app):** iPhone + web trên máy tính, khung web thanh bên — xem [LUONG-UNG-DUNG mục 1.1](../../../02-yeu-cau/LUONG-UNG-DUNG.md) và [PLAN mục Thiết bị](../../PLAN.md). **Cả hai là thiết bị chính ở mọi màn** (sửa 2026-10-22): mục 2.
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

| Giữ nguyên                                                                                                                                                                                                                     | Được thiết kế lại                                    |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------- |
| Nghiệp vụ trong BJ / UC: quy tắc, trạng thái nghiệp vụ, ai được làm gì, người duyệt = `is_owner` hoặc role `store_owner`, khác người lập — **trừ** `is_owner` **lập thì tự duyệt được** (chốt 2026-10-20; **2026-10-22 làm rõ:** vẫn qua đủ hai bước — gửi duyệt rồi tự vào màn duyệt bấm "Duyệt" một lần nữa để kiểm lại, không có đường ghi nhận thẳng; mỗi cửa hàng chỉ có một chủ; sửa đặc tả ở mục 13) | Luồng giữa các màn, lối vào, điều hướng              |
| Chuỗi chữ của spec. Đổi chữ = đề xuất sửa Screen Contract (mục 13), không sửa thẳng trên UI khi chưa duyệt                                                                                                                     | Bố cục màn, thứ tự khối, mật độ, gom / tách / bỏ màn |
| Token DESIGN.md, thành phần `vet45_design_system`; được thêm thành phần mới (mục 6)                                                                                                                                            | Screen Contract, UIF: chỉ là tham khảo               |
| **Home Kho = bản candidate** (SCR-090): tìm kiếm → 4 nút nhanh → Cần chú ý → Quản lý kho (5 khu) → Thiết lập kho                                                                                                               | Chi tiết bên trong Home candidate                    |

**Người dùng:** cửa hàng có **Owner + 1–3 nhân viên**. Nhân viên lập phiếu (nhận hàng, kiểm kê, đổi tình trạng, tiêu hủy…); **Owner duyệt và là người duy nhất xem tiền**. Nhân viên dùng iPhone ngay tại kho / quầy giữa lúc bán hàng (mode Operate); Owner duyệt và làm việc giá trị lúc ở máy tính, lúc trên iPhone — cả hai phải làm trọn vẹn như nhau.

**Cả hai là thiết bị chính (sửa 2026-10-22).** iPhone và web ngang nhau ở **mọi màn** của Theme 7: mỗi màn có bố cục iPhone và bố cục web (K7) được thiết kế, dựng, kiểm và audit như nhau; không có bên nào chỉ cần "không vỡ, đủ hành động". Bối cảnh ở đoạn trên (nhân viên tại kho, Owner ngồi bàn) chỉ giúp chọn bố cục cho từng bên. Bản 2026-10-20 chia "thiết bị chính theo màn" (việc tại kho → iPhone; duyệt, giá trị, giá vốn, báo cáo → web) là hiểu sai — bỏ; màn đã làm theo bản cũ mà chưa đủ hai bố cục sửa ở plan hotfix riêng [T7-HF1](T7-HF1-hai-thiet-bi.md), không thuộc plan này.

Nhập liệu khác nhau theo thiết bị: quét mã vạch = camera trên iPhone, máy quét USB (gõ như bàn phím vào ô tìm) trên web; chọn tệp = nút trên iPhone, kéo thả được trên web; bàn phím số trên iPhone, gõ phím + Tab / Enter trên web.

**Lối vào:** trên iPhone Kho nằm trong tab "Thêm"; khung 5 tab của app không đổi. Trên web Kho là mục con của "Thêm" trên thanh bên trái (khung app, PLAN mục W-1). Mỗi BJ bắt đầu ở nơi việc phát sinh, menu Kho là đường phụ: BJ-04 / 05 / 06 từ đơn hàng, BJ-07 từ mua hàng, BJ-03 ngay sau khi nhận hàng xong, BJ-16 / 17 từ cảnh báo, BJ-09 / 10 từ hàng hoặc lô có vấn đề.

**Vị trí trên Home Kho:**

| Vị trí | BJ | Cách tới |
|---|---|---|
| 4 nút nhanh | 02 Nhận hàng, 05 Lấy hàng, 08 Kiểm kê, 01 Tra cứu tồn | 1 chạm |
| Cần chú ý (chỉ khi có việc) | Chờ duyệt (khuôn duyệt của mọi BJ), **"Hàng cần xử lý" "{a} lô hết hạn · {b} cách ly / hỏng" (09; thay "lô sắp hết hạn", cận hạn chỉ xem ở BJ-01)**, sai lệch (16), kết quả chưa rõ (17) | 1 chạm |
| Quản lý kho → Tồn kho | 01, CAP-01 (09 "Tình trạng hàng" bỏ từ v5.13.0 — trùng "Hàng cần xử lý" và BJ-01) | Lớp thứ hai |
| Quản lý kho → Nhập, xuất & hoàn trả | 02, 05 (+04), 06, 07 (07 mở danh sách chung "Hàng cần xử lý", chip "Trả nhà cung cấp") | Lớp thứ hai |
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
3. **Chuyển sang** `app/bjNN.js`**:** fixture, biến trạng thái, hàm dựng **cuối cùng** của từng màn, helper riêng, xử lý sự kiện (click / input / change / keydown / focusin) đang nằm trong `core.js`. Helper dùng chung giữa nhiều BJ → `app/shared-<cụm>.js` (vd. `shared-valuation.js`, `shared-control.js`), nạp trước các `bjNN.js` của cụm. Đường cũ / màn retired: đăng ký `screenAliases` (móc trong `navigate` gốc, A5) thay wrapper `navigate` từng lớp.
4. **Màn bị định nghĩa nhiều lần:** lấy bản thắng (bản gán sau cùng), gộp các `.replace()` / phần bọc của wrapper vào chuỗi gốc, xoá bản bị đè. Hàm toàn cục bị gán lại (vd. `io05ApplyHandover = function…`) → giữ **một** định nghĩa: bản cuối.
5. **Bước sửa sau dựng:** đo HTML "trần" (gọi thẳng `renderers[...]`) với HTML qua chuỗi legacy cho mọi trạng thái; khác ở đâu thì gộp vào hàm dựng. Các bước dùng chung hay gặp: `ensureRepresentativeFixture` / `ensureStableExitAffordance` (`v360`), `normalizeDualFooters` (`v361`), `cleanupDismissibleSheets`, `polishCrossThemeCopy`, `applyGroupedSurfaceRule` (`v440`), tone / badge của `v470`, `v471`.
6. **Wrapper** `navigate` **/ toast:** nhánh của BJ trong wrapper `navigate` (`v350`, `v430`, `v460`, `v461`) và dòng của BJ trong bảng toast của `v360` → chuyển vào xử lý sự kiện của BJ (gọi `showToast` ngay sau `render()`, không hẹn giờ).
7. **Đăng ký:** `Object.assign(renderers, …)`; `ownedFlows.add("UIF-NN")`; xoá mục của màn khỏi literal `const renderers = {…}` trong `core.js`; xoá phần của BJ trong mọi lớp legacy.
8. **Kiểm:** golden toàn bộ **khớp hoàn toàn**; bộ bấm thử 0 lỗi JS; `node --check app/*.js`.
9. **Ghi:** CHANGELOG (mục "Giai đoạn 1 — gói …"), đầu `app/bjNN.js` (đã viết lại sạch), tiến độ mục 14, `python3 tools/sync-registry.py`.

**Bẫy đã gặp ở BJ-01** (plan gói nhắc lại khi liên quan):

- Hàm có tham số mặc định dạng object (`function f(p,{a=1}={})`): tìm thân hàm sau dấu `)` đóng tham số, không phải ngoặc `{` đầu tiên.
- Khối xử lý sự kiện của BJ thường là nhánh `if (activeFlowId === "UIF-NN") {…}` có `return` sớm trong một listener chung: tách nguyên khối, giữ điều kiện.
- Toast hẹn giờ 30 ms của `v360` chạy từ pha capture; khi chuyển vào handler của BJ phải gọi ngay sau `render()`.
- Helper của BJ được BJ khác gọi (vd. `bj01Empty` dùng ở BJ-08): giữ tên, ghi chú ở đầu file; gom về `core.js` ở gói A11.
- Lần render đầu chạy trước khi `bjNN.js` nạp: không sao, `hub.js` gọi `render()` sau cùng.
- **Không gọi** `render()` **/** `renderAppScreen()` **lúc nạp trong** `core.js` (A7): helper chuyển sang file nạp sau (`shared-control.js`…) sẽ `ReferenceError` ở cấp cao nhất và dừng nạp `core.js` giữa chừng — hỏng mọi luồng, không chỉ BJ đang tách.
- **Chú thích** `load-time render removed` **phải đúng là lúc nạp** (A8): hàm chạy lúc bấm (`crSwitchFlow`, hẹn giờ duyệt) **giữ** `render()` — A7 xoá nhầm hai chỗ đó.
- **Kiểm listener của BJ còn đủ trước khi tách** (A5/A8): A5 làm mất khối Correction & Recovery (UIF-11/16/17); A8 chặng 0 đặt lại vào `core.js` (phần UIF-16/17 chờ A10 chuyển).
- **Cơ chế dùng chung nằm trong IIFE** (`v350`): chuyển hẳn ra file sở hữu và nối bằng móc (`onUnknownHandoff`), không gọi chéo vào biến cục bộ (A10).

### 4.2 Giai đoạn 1 — gói A11: dọn khung (sau khi mọi gói xong)

Plan: [T7-P-A11-don-khung.md](T7-P-A11-don-khung.md). Phạm vi chốt 2026-10-19:

1. `core.js` chỉ còn khung: xoá `renderFlowScreen`, `ownedFlows`, mọi khối `vNNN` (`v350`, `v360`, `v361`, `v362`–`v364`, `v440`, `v450`, `v470`); `renderAppScreen` = màn gốc theme → `ThemeApp`, còn lại → `rendererFor(...)` + `ThemeApp.afterFlowRender()`.
2. Bước sau dựng **còn sống dù mọi luồng đã sở hữu** (bọc `render` / `MutationObserver`): `simplifyNormalBanners` → gộp vào hàm dựng BJ-08 / BJ-10 (khác biệt có chủ đích, ghi CHANGELOG); `v440` grouped surface → đo trước, 0 tác động thì xoá, còn thì giữ làm **một** bước dựng chung có tên trong khung.
3. Routing lối vào + actor gộp một bảng `entryTargets` / `applyEntry` / `currentActor()`; mọi API QA `__VET45_V350__` / `__V360__` / `__V3101__` / `__BJ10__`… → **một** `window.__VET45_QA__` (BJ tự đăng ký). Giữ tên thuộc tính `data-v350-action` / `data-v360-action` (đổi ở Giai đoạn 2).
4. Helper dùng chéo: `bj01Empty` → `ds24EmptyState`; bản trùng `icCard…icApprovalButtons` (`core.js` + `bj09.js`) → `shared-control.js`.
5. Tách harness → `harness/workbench.js` / `figma-ds-map.js` / `workbench.css`; `renderFlowInspector` **giữ nguyên chữ** (golden đọc inspector).
6. CSS chỉ phần an toàn: xoá luật không dùng (chế độ `golden.mjs usage`), gồm `.cr-*` / `.ac310-*` chết. **Gom CSS theo BJ và bỏ** `!important` **dời sang bước C của từng BJ** (mục 4.4).
7. Xoá mã chết JS còn lại (độ phủ + `grep`), file tạm của các gói trước. Kiểm: golden khớp hoàn toàn (trừ mục 2); bấm thử 0 lỗi JS.

### 4.2b Giai đoạn 2 — theo chặng hành trình, mỗi BJ đi B → E

Làm theo **6 chặng của vòng đời cửa hàng** (mục 8.2, chốt 2026-10-20), không theo số BJ. Trong một chặng, BJ đi đúng thứ tự việc thật (BJ trước chuyển việc cho BJ sau). Một BJ đi đủ B → E rồi mới sang BJ sau; phiên review viết brief của BJ sau trong lúc bạn làm C–E của BJ trước.

**Hết mỗi chặng:** thêm một kịch bản golden `SC_journey_<N>` đi một mạch hết chặng (từ Home Kho, qua mọi BJ của chặng, nút nhảy giữa các BJ, về lại Home), chạy 0 lỗi; lối vào của chặng trên Home Kho (SCR-090…096) nối xong.

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
4. Dựng đủ hai bố cục cho mọi màn (mục 2): iPhone và web tối ưu như nhau, không có bên chỉ kiểm "không vỡ". Màn web dùng khuôn K7 và density `compact` của DS.
5. Cập nhật kịch bản golden theo brief.

### 4.5 D — Kiểm

1. Golden: chỉ các ca đã liệt kê trong brief được khác; mọi ca khác **khớp hoàn toàn**. So **toàn bộ** golden với **một** mốc chụp trước bước C, không chụp lại mốc giữa chừng (bài học 14.1). Mọi màn chụp ở cả khung iPhone và khung web.
2. Bộ bấm thử 0 lỗi JS.
3. `/impeccable audit` phạm vi BJ: tương phản ≥ 4,5:1, vùng chạm ≥ 44 (iPhone), nhãn cho nút icon; trên web thêm đi được bằng bàn phím (Tab, Enter, Esc đóng sheet). **Hai khung đều là thiết kế thật** (thêm 2026-10-22): trên web không màn nào còn là cột 402px giữa khung hay bản iPhone kéo giãn (nút, dòng dài hết khung); trên iPhone không có bảng ép nhỏ, số không gãy dòng — xem ảnh iPhone và ảnh `@web` của **mọi** màn trong brief.
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

| #   | Khuôn                                                                                                                                                                                                                                                                                                                                                                       | Dựng ở                                                                                               | Dùng lại ở                             |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- | -------------------------------------- |
| K1  | **Trạng thái chung:** không có quyền, đang tải, rỗng, rỗng sau lọc, dữ liệu cũ, bị khoá                                                                                                                                                                                                                                                                                     | BJ-12                                                                                                | tất cả (đã dùng ở BJ-12, BJ-01)        |
| K2  | **Lập → duyệt → kết quả:** người lập gửi; danh sách "Chờ duyệt" (Home → Cần chú ý); màn duyệt (thứ cần quyết đầu tiên, ngoại lệ nổi bật, Duyệt / Từ chối có lý do); người lập thấy trạng thái chờ, khoá sửa; kết quả. `is_owner` **lập thì cũng gửi duyệt rồi tự duyệt** (mục 2, làm rõ 2026-10-22): rà soát → "Gửi phê duyệt" → chờ duyệt → chính chủ vào Home → Chờ duyệt → "Duyệt" → kết quả; không có đường ghi nhận thẳng; lịch sử ghi người duyệt "Chủ cửa hàng" | BJ-12 (một đường cho mọi người lập: gửi → Owner duyệt SCR-070, kể cả Owner tự lập)                        | 02, 06, 08, 09, 10, 11, 13, 14, CAP-01 |
| K3  | **Kết quả chưa rõ → xác minh:** không coi là thất bại; mã tham chiếu + giờ; điều gì an toàn; một nút xác minh; lối ra; BJ-17 là màn xác minh chung                                                                                                                                                                                                                          | BJ-12                                                                                                | mọi BJ có ghi dữ liệu                  |
| K4  | **Kết quả xong:** tóm tắt (ai, lúc nào, bao nhiêu), bước tiếp hợp lý (xem tồn, làm tiếp, về Kho), không lặp danh sách dài                                                                                                                                                                                                                                                   | BJ-12                                                                                                | mọi BJ có màn kết quả                  |
| K5  | **Chọn hàng → xử lý → bàn giao:** danh sách hàng đủ điều kiện, chọn lô / lượng, xác nhận, bàn giao                                                                                                                                                                                                                                                                          | BJ-09 (màn dùng chung 036 / 037 / 041, dựng chung cho cả ba luồng, **không mượn tên màn của BJ-07**) | 07, 10                                 |
| K6  | **Danh sách công việc:** danh sách phiếu / phiên với trạng thái, lọc theo trạng thái, mở tiếp đúng bước đang dở                                                                                                                                                                                                                                                             | BJ-05 (nếu brief BJ-12 cần danh sách lần khởi tạo thì dựng ở BJ-12)                                  | 06, 07, 08, 11, 12, 14, 16             |
| K7  | **Bố cục web:** danh sách – chi tiết hai cột (chọn bên trái, xem / duyệt bên phải, không đổi trang); bảng thay danh sách thẻ khi có nhiều cột số; footer hành động thành thanh nút bên phải; sheet thành hộp thoại / bảng bên. Dưới bề rộng ngưỡng tự về bố cục iPhone                                                                                                      | BJ-12 (bảng lỗi tệp, màn duyệt SCR-070)                                                   | mọi màn web chính (mục 2)              |

**Đã dựng ở BJ-12 (2026-10-21, prototype v5.5.0,** `app/shared-patterns.js`**; các BJ sau gọi lại, không dựng lại):**

| Khuôn | Hàm | Dùng thế nào |
|---|---|---|
| K1 | `k1Loading({ blocks })`, `k1Denied({ what, next, exitAttr })`, `k1Stale({ title, description, actionLabel, actionAttr })`, `k1Locked`, `k1Empty` (bảng lọc rỗng), `k1ExitAttr(firstScreen)` | Khung xương theo bố cục ("heading" / "card" / "row" / "search"); không có quyền = tiêu đề "Bạn chưa có quyền …" + câu làm gì tiếp + "Về Kho"; dữ liệu cũ = banner + "Tải lại"; "Về Kho" về Hub khi ở chế độ Toàn Theme 7, về màn đầu luồng khi ở chế độ BJ |
| K2 | `k2Pending`, `k2Decision`, `k2RejectSheet`, `k2SelfCommitSheet`; nguồn `window.__T7_PENDING_SOURCES__` | Người lập sau khi gửi: "Chờ {ai} duyệt · gửi {lúc}" + dữ liệu đã khoá. Màn duyệt: câu hỏi → người gửi → "Cần chú ý" → số liệu → chi tiết (bảng). Từ chối bắt buộc lý do. Owner tự lập: sheet xác nhận "Chỉ ghi nhận một lần…" rồi ghi nhận ngay. Mỗi BJ đăng ký nguồn `{ id, label, rows() }` để Home hiện "Chờ duyệt" ("3 nhận hàng · 1 số dư đầu kỳ") và danh sách chờ duyệt; dòng gắn `data-theme-entry-actor="approver"` để vào đúng vai |
| K3 | `k3Unknown({ operation, scope, ref, sentAt, safe, sourceFlow, exitAttr, facts })` | "Kết quả chưa xác định": nghiệp vụ, phạm vi, mã tham chiếu, thời điểm gửi, điều an toàn, "Về Kho" \| "Chuyển sang xác minh" (BJ-17) |
| K4 | `k4Result({ screenTitle, kind, title, description, facts, next })` | Kết quả: tóm tắt ai / lúc nào / bao nhiêu; chân phụ \| chính |
| K7 | `k7Split`, `k7Table`, `k7FilterChips`, `k7EditCell({ value, attr, unit, error, label, disabled })` (dựng ở CAP-01: ô số sửa tại dòng, hậu tố đơn vị, lỗi dưới ô, `aria-label`); lớp `k7-wide` qua `appShell({ extraClass })` | Web: hai cột 5fr / 7fr; bảng thay danh sách thẻ (hàm trả cả hai, CSS chọn theo khung); chân là thanh nút bên phải; sheet thành hộp thoại giữa. Dưới khung web tự về một cột iPhone. **BJ-03 (v5.9.0):** `k7Table({ …, select: (r) => ({ attr, checked, disabled, label }) })` thêm cột ô tick đầu bảng (bỏ trống thì HTML như cũ; iPhone: mobileRow tự dựng ô tick qua `k7CheckMark`); `k7Check` (ô tick nút ≥ 44 × 44); `k7Split({ wideMain, asideWebOnly })`: bảng rộng + khối tóm tắt hẹp, iPhone ẩn khối phải |

**Đã dựng ở BJ-04 / BJ-05 (2026-10-24, prototype v5.11.0,** `app/shared-patterns.js`**):**

| Khuôn | Hàm | Dùng thế nào |
|---|---|---|
| K6 | `k6TaskList({ search, filters, columns, rows, total, mobileRow, rowAttr, empty, filterEmpty, filterEmptyAttr })` | Thân màn danh sách việc: ô tìm (`search: { value, attr, placeholder }`) → chip có số (`filters: { items: [[key, label, count]], selected, attrName }`) → bảng web / danh sách iPhone (`k7Table`) → khối "không tìm thấy" luôn dựng sẵn (ẩn) để ô tìm lọc tại chỗ. `rows` đã lọc, mỗi dòng có `status: { label, tone }` và `disabled` (dòng chỉ xem: `aria-disabled`, không mở). `rowAttr(r)` do BJ quyết — K6 không biết màn đích, mỗi BJ tự chọn bước mở tiếp đúng bước đang dở (BJ-05: "Chờ bàn giao" → SCR-028, còn lại SCR-026). `total = 0` → `k1Empty` (`empty`); lọc ra rỗng → `k1Empty` + "Xem tất cả" (`filterEmpty`). Cột đầu của bảng là nút `.k7-row-link` để Tab tới được |
| K4 | `k4ReasonFooter({ label, attr, disabled, reason })` | Chân một nút có dòng lý do ngay trên nút khi tắt (chuyển từ `bj02Footer`; BJ-02 và BJ-05 dùng) |
| K3 | `k3Unknown({ …, handoff: { operation, scope } })` | Tham số tùy chọn: giá trị gửi sang BJ-17 khi khác chữ hiển thị (BJ-05 gửi mã nghiệp vụ, chữ hiển thị "Bàn giao hàng") |

**Đã dựng ở BJ-09 (2026-10-25, prototype v5.13.0,** `app/shared-problem.js`**; BJ-07 / BJ-10 dùng lại, không dựng lại):**

| Khuôn | Hàm | Dùng thế nào |
|---|---|---|
| K5 | `render036K5`, `render037K5` (đăng ký `flowRenderers` cho UIF-07 / 09 / 10 SCR-036 và UIF-09 / 10 SCR-037) | **Một danh sách chung "Hàng cần xử lý"** (K6: ô tìm + chip có số "Tất cả · Cần xử lý · Trả nhà cung cấp · Tiêu hủy · Đang chờ"; web bảng "Hàng · Lô / yêu cầu · HSD · Số lượng · Việc · Tình trạng") và **chi tiết hàng** (thẻ lô + "Việc tiếp theo" theo tình trạng; nút chân Đổi tình trạng / Đề nghị tiêu hủy / Xem yêu cầu). Chip và ô tìm là trạng thái của K5 (`k5Filter`, `k5Query`), không của luồng |
| K5 | `window.__T7_PROBLEM_SOURCES__` — mỗi BJ đẩy `{ id, rows() }`; `k5LotRow(lot, { job, task, suffix, open, pending, banner, disabled })` | Dòng: `kind` "LOT" / "REQUEST", `job` "OPEN" (Cần xử lý) / "RTV" / "DISPOSAL" / "WAITING", `open()` = bước tiếp do BJ quyết. **Một lô một dòng**: DISPOSAL > WAITING > OPEN thắng; yêu cầu trả không gộp. BJ-07 (yêu cầu trả, `job` "RTV" / "WAITING") và BJ-10 (đề nghị tiêu hủy chờ duyệt → "WAITING", đã duyệt → "DISPOSAL") đẩy dòng từ dữ liệu thật ✅ v5.14.0 / v5.15.0 |
| K5 | `t7Lots`, `t7Lot`, `t7LotStateLabel`, `t7LotTone`, `t7LotSub` | Fixture lô chặng 4 (5 lô: Tylosin TY2408 hết hạn, Amox AM2505 cách ly, Găng tay Nitrile hỏng, Dầu sát khuẩn dùng thử, Nobivac DH2507 bán được) |
| K5 | `k5LotCard({ lot, compact })`, `k5QtyField({ value, max, uom, attr, fillAttr, error, label })`, `k5Evidence({ owner, evidence, required, label, error })` + `k5RegisterEvidence(owner, { set, rerender })` | Thẻ lô (badge + "{n} {ĐVT} {tình trạng} · Khả dụng bán {k}" + nguồn); ô số + nút "Cả {n} {ĐVT}" (BJ-09, **BJ-10** dùng cho "Số lượng đề nghị" / "Đã tiêu hủy thực tế"); vùng ảnh bằng chứng (BJ-09, **BJ-10** "Ảnh hiện trạng" / "Ảnh hoặc biên bản tiêu hủy") (chụp ảnh / chọn tệp / kéo thả, xem trước có `alt`, "Xoá ảnh"; chép từ `bj06EvidenceZone`, BJ-02 / BJ-06 chưa đổi sang) |
| K5 | `k5ShowLot(lotId, returnTo)`, `k5SetEntryFilter(flowId, filter)`, `k5AttentionSummary()` | Mở 037 của một lô (`returnTo` = quay lại BJ-01); chip theo lối vào Hub / Home; dòng "Hàng cần xử lý" của Home đọc số từ nguồn (không gõ cứng) |

Thành phần dùng chung dựng ở CAP-01 (2026-10-21, v5.7.0, `app/shared-patterns.js` + `components.css`): `dsSegmented({ items, value, attr })` (thanh chọn hai / ba mục, `VSegmentedControl`) và `dsChoiceRow({ title, subtitle, selected, attrs })` (thẻ lựa chọn lớn có nút tròn) — chép giá trị từ `.cf-segmented` (BJ-15) và `io06SelectionRow` (BJ-06); **BJ-06 đã chuyển sang** `dsChoiceRow` **/** `dsSegmented` **(v5.12.0)**, BJ-15 còn (chuyển khi tới lượt, chặng 6). `k4Footer` nhận thêm `disabled` cho từng nút.

Quy tắc chung cho mọi khuôn: một hành động chính mỗi trạng thái; footer hai nút (Phụ | Chính); `VBanner` chỉ cho ngoại lệ / cảnh báo / chặn; thành công cùng màn dùng toast; tiền chỉ Owner thấy (`FINANCIAL_MASKED` = không có số trong DOM).

## 6. Thành phần DS mới

Thêm khi phát sinh ở bước B; dựng trong `styles/components.css` (prototype) và đưa vào `vet45_design_system` ở giai đoạn 5.

| Thành phần | Phát sinh ở | Mô tả | Trạng thái |
|---|---|---|---|
| `ds24DotBadge` / `.ds24-badge--dot` | BJ-01 (bước A) | VBadge có chấm: đặc = cảnh báo, rỗng = nguy hiểm | ✅ prototype |
| `VStockRow` | BJ-01 | List Row có cột phải hai tầng: số lượng mono + badge | ✅ prototype |
| Nút quét mã vạch trong `VSearchBar` | BJ-01 | Hành động cuối ô tìm | ✅ prototype |
| `VChip` có số đếm | BJ-01 | Chip lọc kèm số; số 0 mờ, vẫn bấm được | ✅ prototype |
| Bảng dữ liệu web (`k7Table`; Flutter có sẵn `VTable`) | BJ-12 | Bảng có tiêu đề cố định, số mono căn phải; trên iPhone thành danh sách thẻ | ✅ prototype |
| Vùng kéo thả tệp trên web (`VFileDropZone` mở rộng) | BJ-12 | Thêm dòng "Kéo tệp vào đây hoặc Chọn tệp", chỉ web | ✅ prototype |
| Dải số một hàng (`cf12Strip`, biến thể ngang của `ac310SummaryMetrics`) | BJ-12 | "82 dòng đọc được · 79 hợp lệ · 3 cần sửa" | ✅ prototype |
| `VMoneyField` trạng thái lỗi | BJ-12 | Viền + dòng lỗi dưới ô (`cfField(…, error)`) | ✅ prototype |
| Ô số sửa tại dòng (`k7EditCell`; Flutter dùng `VNumberField` trong `VTable`) | CAP-01 | Ô số có hậu tố đơn vị, lỗi dưới ô, `aria-label`; chạm ≥ 44 trên iPhone | ✅ prototype |
| `VSegmentedControl` (`dsSegmented`, lớp `.ds-segmented`) | CAP-01 | Thanh chọn hai / ba mục; mục chọn nổi nền trắng | ✅ prototype |
| Thẻ lựa chọn lớn (`dsChoiceRow`, lớp `.ds-choice-row` / `.ds-radio`) | CAP-01 | List Row chọn một có tiêu đề + mô tả + nút tròn | ✅ prototype |
| Thanh tiến độ mảnh (`.bj02-progress`; Flutter: `VProgress` dạng thanh nếu DS chưa có) | BJ-02 | "Đã xử lý {a}/{b} mặt hàng" dưới dòng ngữ cảnh | ✅ prototype |
| Ô hạn dùng tự hiểu độ chính xác (mở rộng `VTextField` ngày) | BJ-02 | Một ô nhận "30/11/2026", "11/2026" hoặc "2026"; lỗi tại ô; lưu `expiryPrecision` | ✅ prototype |
| `VFileDropZone` biến thể iPhone có "Chụp ảnh" | BJ-02 | Hai nút "Chụp ảnh" \| "Chọn tệp" + danh sách tệp có "Xoá" | ✅ prototype |
| Ô số lớn nhập thẳng + ba ô nhỏ (`VNumberField`, bàn phím số hệ thống) | BJ-02 | "Đạt" lớn, "Cách ly" / "Hỏng" / "Từ chối" một hàng; thay `VNumericKeypadSheet` riêng | ✅ prototype |
| Ô tick (`role="checkbox"`) kèm mô tả | BJ-02 | "Tôi xác nhận hàng này thuộc sở hữu của cửa hàng" | ✅ prototype |
| Chân màn có dòng lý do (`bj02Footer`) | BJ-02 | Dòng chữ ngay trên nút khi nút tắt | ✅ prototype |
| Ô tick trong bảng (`k7Table` cột `select`, `k7Check`; Flutter: `VTable` có cột chọn; iPhone: `VCheckbox` đầu thẻ) | BJ-03 | Chọn dòng sản phẩm; `role="checkbox"` + `aria-checked` + nhãn = tên sản phẩm; dòng không chọn được thì tắt | ✅ prototype |
| Khối "Tóm tắt" + dải tổng (`.bj03-facts`, `.bj03-total-strip`) | BJ-03 | Web: nhãn — giá trị căn phải cạnh bảng kèm nút "Ghi giá trị ({n})"; iPhone: "Đã chọn {n} sản phẩm · {tổng}" trên chân | ✅ prototype |

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
| A2 | **BJ-06** | 030–035 | `io06` | `app.js`; `v350`; `v394` (SCR-032…035, bọc `renderFlowScreen` đổi tiêu đề SCR-031, gán lại 18 hàm `io06`*, listener `window` capture chặn trước listener chung); `legacy-cross-theme-copy` (SCR-031); `v360` (2 toast, đang chết) | 1 | ✅ | Móc `onPrevious` (theo luồng) thay nhánh trong `previousScreen` — các gói sau dùng lại |
| A3 | **CAP-01** | 062–065 | `cap` | `v360` (toàn bộ CAP-01, phần CAP-01 của `renderFlowInspector`) | 0 | 0,5 | |
| A4 | **BJ-02** | 006–013, 084 | `bj02` | `app.js`; `v350` (011, 012, 013); `v360` (`ensureBj02ReviewFixture`, toast); `v392` (cả 9 màn, gán lại 11 hàm + bọc 2); `v460` / `v461` (SCR-008); `v466`–`v468`; `v470` (tone "rủi ro"); `v471`; `legacy-sheet-cleanup`; `legacy-cross-theme-copy` (SCR-012); `hub.js` (`addPendingReviewExit` — để lại `hub.js`, xem plan A4 mục 2.5) | 4 | 2 | 58 trạng thái, demo chính; cụm "nhập nhanh đời đầu" đang chết, xoá ở A4 |
| A5 | **BJ-03, BJ-13, BJ-14** | 014–019; 085–089; 072–077 | `val03`, `val13`, `val14` | `app.js`; `v313`; `v430` (bọc `navigate`); `v460` / `v461` (bọc `navigate`, gán lại `val14CreateRun`); `v397`; `v398`; `v399`; `v350`; `v360` (3 fixture); `v431` | 10 | 3 | Helper chung → `app/shared-valuation.js` |
| A6 | **BJ-07, BJ-09, BJ-10** | 036, 037, 039, 041; 038, 056; 040 | `io07`, `ic09`, `ic10` | `app.js`; `v310`; `v350`; `v395` (gán lại 8 hàm `io07`*); `v3101`; `v351` (056); `v360` (041, toast); `legacy-cross-theme-copy` (038) | 12 | 3 | Màn dùng chung (036 / 037 / 041; 056 với BJ-15) dựng **theo luồng** qua móc `flowRenderers` (plan A6, khác hướng ban đầu "dựng ở `bj07.js`"); 056 của BJ-09 tạm rơi về chuỗi BJ-15 tới A9 |
| A7 | **BJ-08** | 042–047 | `ic08`, `ac310`, `ac321` | `app.js`; `v310`; `v320`; `v340` (gán lại `ac310CountGroup`, `ac310RecountGroup`); `v350` (gán lại `ic08ConfirmationSheet`, `ic08QuantityTrigger`); `v3100`; `v360`; `legacy-sheet-cleanup` | 6 | 2 | Helper `ac310`* / `ac321`* dùng chung cụm kiểm soát → `app/shared-control.js` (dựng ở gói này); bỏ mọi `render()` lúc nạp trong `core.js` (plan A7 mục 4.1) |
| A8 | **BJ-11, BJ-12** | 048–053; 066–071 | `cr11`, `cf12` | `app.js`; `v310`; `v350`; `v360` (toast) | 5 | 2,5 | Dùng `shared-control.js`. Chặng 0 khôi phục listener UIF-11/16/17 (mất từ A5) và `render()` trong `crSwitchFlow` / hẹn giờ duyệt (A7 xoá nhầm) — plan [A8](T7-P-A8-bj11-bj12.md) mục 2.6 |
| A9 | **BJ-15** | 054, 055, 057, 058, 059 (+056 từ A6) | `cf15` | `app.js`; `v310`; `v320` (cả khối); `v350` (seed `cf15Movements` lúc nạp, gán lại `cf15InventoryResult`, `cf15StockCardResult`, bọc 055 / 058); `v351` (cả khối); `legacy-sheet-cleanup` (cả khối) | 4 | 1,5 | Plan [A9](T7-P-A9-bj15.md). SCR-056 BJ-09 không có `movement` tự dựng trong `bj09.js` (tránh đệ quy qua `flowScreen`); `cf`* + `ac310ProductRow` → `shared-control.js` |
| A10 | **BJ-16, BJ-17** | 078–083 | `cr16`, `cr17` | `app.js`; `v310` (phần còn lại → xoá cả khối); `v350` (seed `cr16/17Cases` lúc nạp, `.replace` 079–082, `handoff-unknown` + `bj02-`*); `legacy-cross-theme-copy` (cả khối) | 9 | 2 | Plan [A10](T7-P-A10-bj16-bj17.md). Một bộ màn, hai luồng qua `flowRenderers`, `bj17.js` gọi lại helper `bj16.js`. Cơ chế K3 (`handoff-unknown`) → `bj17.js` + móc `onUnknownHandoff` cho UIF-05/06/07. `ac310ProductRow` / `cf`* đã ở `shared-control.js` (A9). Xong A10 = mọi luồng đã sở hữu |
| A11 | **Dọn khung** | — | — | `v350`, `v360`, `v361`, `v362`–`v364`, `v440`, `v450`, `v470`; harness trong `core.js` / `components.css`; CSS không dùng | — | 3 | Plan [A11](T7-P-A11-don-khung.md). `v440` / `simplifyNormalBanners` vẫn chạy trên luồng đã sở hữu (bọc `render`) — đo trước. Một API `__VET45_QA__`. CSS chỉ xoá luật không dùng; gom theo BJ dời Giai đoạn 2 |
| | **Cộng** | | | | | **~21** | |

Thứ tự gợi ý: A1 → A2 → A3 (gói nhỏ, ít lớp chồng, để quen cách làm) → A4 (BJ-02, demo chính) → A5 (cụm giá trị) → A6 → A7 (dựng `shared-control.js`) → A8 → A9 → A10 → A11. Plan gói `T7-P-A<n>-*.md` được viết ngay trước khi bạn làm gói đó.

**Mốc hết Giai đoạn 1:** mọi luồng dựng thẳng qua `renderers` / `flowRenderers` (A11 bỏ `ownedFlows`); `core.js` chỉ còn khung, harness ở `harness/`; không còn khối `vNNN-…`; golden khớp hoàn toàn với mốc trước Giai đoạn 1 (trừ khác biệt có chủ đích ghi trong CHANGELOG); bấm thử 0 lỗi JS.

### 8.2 Giai đoạn 2 — thiết kế lại theo chặng hành trình (sắp lại 2026-10-20)

Thứ tự theo **vòng đời một cửa hàng** dùng Kho, lấy từ quan hệ chuyển việc giữa các BJ trong spec ([00-business-journey-map.md](../../../../specs/themes/theme-07/02.specification/behavior/journeys/00-business-journey-map.md) mục 2): mở kho một lần → nhập hàng → bán và giao → xử lý hàng có vấn đề → kiểm kê và sửa sai → chốt kỳ. Luồng demo (mục 10) đi đúng thứ tự này. Bản trước (đợt 1–5 theo số BJ và theo khuôn) bỏ.

| Chặng | Hành trình (việc thật) | BJ theo thứ tự trong chặng | Màn · trạng thái | B–E (ngày) | Khuôn dựng ở chặng | Mốc khi xong chặng |
|---|---|---|---|---|---|---|
| 0 | Dọn tài liệu 7.1 | — | | ✅ | Khuôn Screen Contract / UIF | |
| 0 | Gói H1 — khung web cho harness (✅ [plan](#143-gói-h1--khung-web-cho-harness), mục 14.3) | — | | ✅ 2026-10-21 (review ✅) | — | Golden chụp được khung iPhone và khung web; điều kiện để làm BJ-12 |
| 1 | **Mở kho** — Owner khởi tạo kho một lần, xem tồn, đặt ngưỡng | **BJ-12** Tồn đầu kỳ (3) → **BJ-01** Tồn & khả dụng (1) → **CAP-01** Chính sách tồn & cận hạn (1) | 12 · 64 | 5 | K1, K2, K3, K4, K7 (ở BJ-12) | `SC_journey_1`: tải tệp đầu kỳ → sửa lỗi → gửi duyệt → Owner duyệt → tồn kích hoạt → xem tồn → đặt ngưỡng |
| 2 | **Nhập hàng** — NCC giao hàng, nhân viên nhận, Owner duyệt và chốt giá (vài lần / tuần) | **BJ-02** Nhận hàng mua (2,75) → **BJ-03** Giá trị nhập ban đầu (1,5) → **BJ-13** Điều chỉnh giá trị hàng nhập (1,25) | 16 · 95 | 5,5 | — (dùng K1–K4, K7; fixture chung chặng 2 ở BJ-02 C0) | `SC_journey_2`: nhận hàng → duyệt → xác lập giá → điều chỉnh giá trị |
| 3 | **Bán và giao** — đơn bán giữ hàng, nhân viên lấy và bàn giao, khách trả lại (hằng ngày) | **BJ-04** Giữ hàng → **BJ-05** Lấy & bàn giao (1,5 cả hai) → **BJ-06** Hàng khách trả (1,5) | 12 · 64 | 3 | K6 (ở BJ-05) | `SC_journey_3`: đơn → giữ → lấy → bàn giao → khách trả → phân loại |
| 4 | **Hàng có vấn đề** — lô hết hạn / hỏng / trả lại NCC / tiêu hủy | **BJ-09** Tình trạng hàng (2) → **BJ-07** Trả NCC (1) → **BJ-10** Tiêu hủy (1) | 13 · 86 | 4 | K5 (ở BJ-09) | `SC_journey_4`: lô hết hạn → đổi tình trạng → trả NCC / tiêu hủy |
| 5 | **Kiểm kê và sửa sai** — kiểm kê định kỳ, sửa nghiệp vụ sai, đối soát sai lệch, kết quả chưa rõ | **BJ-08** Kiểm kê (2) → **BJ-11** Hủy & sửa sai (1,5) → **BJ-16 / 17** Đối soát / kết quả chưa rõ (2) | 18 · 108 | 5,5 | — | `SC_journey_5`: kiểm kê → chênh lệch → duyệt → phát hiện sai → sửa sai → đối soát |
| 6 | **Chốt kỳ** — Owner tính giá vốn, xem báo cáo và thẻ kho (cuối kỳ) | **BJ-14** Giá vốn (1,5) → **BJ-15** Báo cáo & thẻ kho (1,5) | 9 · 49 | 3 | — | `SC_journey_6` + `SC_demo_`* (mục 10) |
| | **Cộng** | | | **~27** | | |

- **Vì sao chặng 1 lên đầu:** chưa khởi tạo tồn đầu kỳ thì kho chưa kích hoạt (`INVENTORY_NOT_ACTIVATED`), mọi BJ khác chưa dùng được; BJ-01 đọc kết quả của BJ-12; ngưỡng tồn (CAP-01) hiện trong BJ-01. Chặng 1 dựng 5 / 7 khuôn nên nặng nhất (BJ-12 ~3 ngày); các chặng sau nhanh hơn.
- **Trong chặng 4:** BJ-09 trước vì nó quyết hàng đi đâu (spec: BJ-09 → BJ-07 "RTV candidate", BJ-09 → BJ-10 "Disposal candidate"); vì vậy màn dùng chung 036 / 037 / 041 và K5 dựng ở BJ-09.
- **Home Kho:** mỗi chặng nối lối vào của mình (mốc "hết chặng", mục 4.2b); Giai đoạn 3 chỉ rà lại toàn bộ.
- **Plan đã viết:** plan BJ-01 ([T7-P-bj01-ton-kho.md](T7-P-bj01-ton-kho.md), brief đã duyệt 2026-10-16) giữ, nay làm **sau BJ-12**; khi rà lại theo code sau Giai đoạn 1, đổi phần "dựng K1" thành dùng K1 đã dựng ở BJ-12. Plan dọn tài liệu đã xong (mục 14).
- Ước lượng chưa gồm phần web (mục 12, ~+4–5 ngày — đo khi còn chia thiết bị chính / phụ; nay cả hai là chính nên cao hơn, ước lượng lại ở brief từng BJ).

---

## 9. Từng BJ: hướng thiết kế lại sơ bộ

Sắp theo chặng (mục 8.2). Hướng dưới đây là **giả thuyết để mở bước B**, chưa phải quyết định; bước B chụp ảnh, critique và chốt. "Vấn đề đã biết" lấy từ critique 2026-10-15 và từ dữ liệu prototype.

### Chặng 1 — Mở kho

#### BJ-12 Khởi tạo tồn đầu kỳ (UIF-12)

- **Plan:** [T7-P-bj12-ton-dau-ky.md](T7-P-bj12-ton-dau-ky.md) (brief mục 0 đã duyệt 2026-10-21; bước C–E).
- **Màn:** 066 Khởi tạo tồn kho (8), 067 Dữ liệu đầu kỳ (5), 068 Kết quả kiểm tra (6), 069 Rà soát (5), 070 Duyệt (5), 071 Kết quả (7).
- **Hướng sơ bộ:** trình hướng dẫn 3 bước (tải tệp → sửa lỗi → gửi duyệt) có tiến trình; lỗi tệp liệt kê theo dòng (bảng trên web), sửa được ngay; web: kéo thả tệp + nút chọn tệp; iPhone: nút chọn tệp.
- **Khuôn:** **dựng K1, K2, K3, K4, K7** (BJ đầu tiên của Giai đoạn 2; bảng lỗi tệp, màn duyệt SCR-070). K2: một đường cho mọi người lập (gửi → Owner duyệt); `is_owner` lập cũng gửi rồi tự duyệt ở màn duyệt (mục 2, làm rõ 2026-10-22; trước đó brief BJ-12 dựng nhánh ghi nhận thẳng, đã bỏ ở v5.8.0) — các BJ sau dùng lại.
- **Tài liệu bước E:** SCR-066…071, UIF-12.

#### BJ-01 Theo dõi tồn & khả dụng (UIF-01)

- **Plan:** [T7-P-bj01-ton-kho.md](T7-P-bj01-ton-kho.md) (brief duyệt 2026-10-16; rà lại theo code 2026-10-21).
- **Ai, khi nào:** nhân viên khi có khách hỏi; Owner đầu ngày / trước khi đặt hàng.
- **Màn:** SCR-001 Tồn kho (6 trạng thái), SCR-003 Chi tiết tồn kho (4); SCR-004 = sheet lô của 003.
- **Lối vào / ra:** Home → "Tra cứu tồn" / ô tìm / Quản lý kho → Tồn kho; ra: chi tiết → thẻ kho (BJ-15), nhận hàng (BJ-02), xử lý lô (BJ-09).
- **Vấn đề đã biết và hướng:** xem brief trong [T7-P-bj01-ton-kho.md](T7-P-bj01-ton-kho.md).
- **Khuôn:** K1 (dựng ở BJ-12).
- **Tài liệu bước E:** SCR-001, SCR-003 (+ ghi chú 002, 004, 005, 060, 061 trong INDEX), UIF-01.

#### CAP-01 Chính sách tồn & cận hạn

- **Plan:** [T7-P-cap01-chinh-sach-ton.md](T7-P-cap01-chinh-sach-ton.md) (brief mục 0 đã duyệt 2026-10-21; bước C–E; `SC_journey_1` hết chặng 1).
- **Màn:** 062 Chính sách tồn (5), 063 Hàng cận hạn (5), 064 Rà soát (4), 065 Kết quả (4).
- **Hướng sơ bộ:** đặt ngưỡng ngay trong chi tiết sản phẩm (BJ-01, khi "Chưa có ngưỡng tồn"); màn thiết lập chung cho mặc định cửa hàng.
- **Khuôn:** K2 (nếu cần duyệt), K4.
- **Tài liệu bước E:** SCR-062…065.

### Chặng 2 — Nhập hàng

#### BJ-02 Nhận hàng mua (UIF-02)

- **Plan:** [T7-P-bj02-nhan-hang.md](T7-P-bj02-nhan-hang.md) (brief mục 0 duyệt 2026-10-21 theo đề xuất ở 0.10; bước C0 = fixture chung chặng 2). Hướng dưới đây là bản trước brief.
- **Ai, khi nào:** nhân viên khi NCC giao hàng (vài lần / tuần); Owner duyệt khi vượt chứng từ hoặc nhập nhanh.
- **Màn:** 006 Chọn cách nhận (5), 007 Chứng từ chờ nhận (7), 008 Thông tin nhập nhanh (5), 009 Hàng thực nhận (7), 084 Chi tiết hàng thực nhận (6), 010 Rà soát (7), 011 Phê duyệt (7), 012 Kết quả (7), 013 Đối soát kết quả (7).
- **Vấn đề đã biết:** hai chế độ (theo chứng từ / nhập nhanh) chỉ phân biệt bằng một dòng phụ; SCR-008 "kéo tệp" trên điện thoại, "Xác nhận quyền sở hữu" là tiêu đề không có ô tick; người duyệt không thấy lượng theo chứng từ cạnh lượng thực nhận; SCR-012 hoàn tất sơ sài, không có bước tiếp; SCR-012 UNKNOWN vừa vòng quay vừa nút; fixture SCR-009 thiếu nhà cung cấp.
- **Hướng sơ bộ:** màn chọn cách nhận rõ hai trường hợp (có chứng từ / hàng đến chưa có chứng từ); nhập dòng hàng nhanh hơn (quét mã, lô theo bao bì, bàn phím số); rà soát và duyệt đặt ngoại lệ lên đầu (chứng từ 120 · thực nhận 121 · +1); kết quả theo K4 với "Xác lập giá trị" (BJ-03, chỉ Owner), "Nhận tiếp", "Xem tồn"; UNKNOWN theo K3.
- **Khuôn:** K2, K3, K4, K7 (dựng ở BJ-12; mọi màn đủ bố cục iPhone và web — sửa 2026-10-22).
- **Liên kết:** từ BJ-01 ("Nhận hàng"), sang BJ-03.
- **Phụ thuộc quyết định:** đã chốt 2026-10-20 (mục 2, mục 13) — `is_owner` tự lập thì vẫn gửi duyệt rồi tự duyệt (hai bước); người duyệt khác = `is_owner` / role `store_owner`; cách thể hiện chốt ở brief BJ-12 (K2), BJ-02 dùng lại.
- **Tài liệu bước E:** SCR-006…013, 084; UIF-02.

#### BJ-03 Xác lập giá trị nhập ban đầu (UIF-03)

- **Plan:** [T7-P-bj03-gia-nhap.md](T7-P-bj03-gia-nhap.md) (brief mục 0 duyệt 2026-10-21 theo đề xuất ở 0.10; rà lại theo code sau BJ-02).
- **Ai, khi nào:** Owner, sau mỗi lần nhận hàng (hàng nhận chưa có giá).
- **Màn:** 014 Hàng chờ xác lập (6), 015 Xác lập (7), 017 Rà soát (3), 019 Kết quả (5).
- **Vấn đề đã biết:** SCR-015 nút chính tắt không nói lý do; "0 đ/hộp"; khoảng cách không đều; thuật ngữ "Xác lập giá trị nhập ban đầu".
- **Hướng sơ bộ:** vào thẳng từ kết quả nhận hàng; một màn nhập giá theo dòng (giá gợi ý từ lần trước / chứng từ), lý do khi nút tắt nằm ngay cạnh; rà soát gộp vào bước xác nhận nếu ít dòng.
- **Khuôn:** K1, K3, K4.
- **Tài liệu bước E:** SCR-014, 015, 017, 019 (016, 018 đã retired), UIF-03.

#### BJ-13 Điều chỉnh giá trị hàng nhập (UIF-13)

- **Plan:** [T7-P-bj13-dieu-chinh-gia-tri.md](T7-P-bj13-dieu-chinh-gia-tri.md) (brief mục 0 duyệt 2026-10-21 theo đề xuất ở 0.10; `SC_journey_2` hết chặng 2).
- **Màn:** 085 Danh sách (6), 086 Phân bổ (5), 089 Kết quả (5); 087 / 088 đã retired.
- **Hướng sơ bộ:** ~~nhập một khoản điều chỉnh~~ (sai spec: khoản đến từ nguồn, Owner không tự gõ — brief BJ-13 0.1); mở khoản từ nguồn, xem cách phân bổ, xem trước số mỗi sản phẩm nhận; chỉ Owner.
- **Khuôn:** K1, K3, K4, K7 — **không K2** (UC-13-01 không có bước duyệt).
- **Tài liệu bước E:** SCR-085, 086, 089, UIF-13.

### Chặng 3 — Bán và giao

#### BJ-04 Giữ hàng (UIF-04) và BJ-05 Lấy hàng & bàn giao (UIF-05)

- **Plan:** [T7-P-bj04-bj05-lay-hang.md](T7-P-bj04-bj05-lay-hang.md) (brief mục 0 duyệt 2026-10-24 theo đề xuất ở 0.10; bước C0 = fixture chung chặng 3; dựng K6). Hướng dưới đây là bản trước brief.
- **Ai, khi nào:** nhân viên soạn hàng theo đơn sỉ / online; giữ hàng do hệ thống, chỉ xem trong đơn.
- **Màn:** 021 Giữ hàng theo đơn (3); 025 Đơn cần lấy (5), 026 Hàng cần lấy (5), 027 Chi tiết lấy hàng (3), 028 Rà soát bàn giao (5), 029 Kết quả bàn giao (5).
- **Hướng sơ bộ:** danh sách đơn theo K6 (đang lấy / chờ bàn giao); lấy hàng theo lô FEFO gợi ý sẵn, đánh dấu từng dòng; thiếu hàng xử lý ngay trên dòng; bàn giao một bước khi đủ.
- **Khuôn:** dựng K6; K1, K3, K4, K7 (đã dựng ở BJ-05, 2026-10-24).
- **Liên kết:** từ đơn hàng (Theme 5); BJ-04 chỉ xem trong chi tiết đơn; SCR-026 ↔ SCR-021 hai chiều.
- **Tài liệu bước E:** SCR-021, 025…029 (+ 020, 022–024 trong INDEX), UIF-04, UIF-05.

#### BJ-06 Hàng khách trả (UIF-06)

- **Plan:** [T7-P-bj06-hang-khach-tra.md](T7-P-bj06-hang-khach-tra.md) (brief mục 0 duyệt 2026-10-24 theo đề xuất ở 0.10; `SC_journey_3` hết chặng 3; rà lại theo code sau BJ-04 / 05). Hướng dưới đây là bản trước brief.
- **Màn:** 030 Danh sách (5), 031 Chi tiết (8), 032 Chi tiết hàng trả (8), 033 Phân loại (7), 034 Ngoại lệ lô cần duyệt (5), 035 Kết quả (5).
- **Vấn đề đã biết:** 030 và 031 cùng tiêu đề "Hàng khách trả" (lớp vá đổi tạm thành "Kiểm hàng khách trả").
- **Hướng sơ bộ:** hai mốc rõ ràng (nhận vào → phân loại); phân loại bằng lựa chọn lớn (bán lại được / cách ly / hỏng / hết hạn); ngoại lệ lô theo K2.
- **Khuôn:** K1, K2, K3, K4, K6, K7 (làm xong v5.12.0 — `dsChoiceRow` thay `io06SelectionRow`).
- **Tài liệu bước E:** SCR-030…035, UIF-06 ✅ 2026-10-24.

### Chặng 4 — Hàng có vấn đề

#### BJ-09 Tình trạng hàng (UIF-09)

- **Plan:** [T7-P-bj09-tinh-trang-hang.md](T7-P-bj09-tinh-trang-hang.md) (brief mục 0 duyệt 2026-10-25 theo đề xuất ở 0.10; bước C0 = fixture chung chặng 4; dựng K5 = danh sách chung "Hàng cần xử lý" + chi tiết lô dùng chung BJ-09 / BJ-10). Hướng dưới đây là bản trước brief.
- **Màn:** dùng chung 036 / 037 / 041 + 038 Chuyển trạng thái (8), 056 Chi tiết movement (6).
- **Vấn đề đã biết:** màn vào là SCR-036 **"Hàng chờ trả nhà cung cấp"** (tên của BJ-07).
- **Lối vào (chốt 2026-10-20):** **một danh sách chung** "Hàng cần xử lý" (SCR-036) cho cả ba việc của chặng 4 — đổi tình trạng (BJ-09), trả NCC (BJ-07), tiêu hủy (BJ-10) — lọc theo việc, đặt ở khu Kiểm kê & xử lý; vẫn vào thẳng được từ một lô có vấn đề (BJ-01 "Xử lý lô hết hạn", Home "Lô sắp hết hạn") và mở đúng việc. Không làm danh sách riêng cho từng BJ.
- **Hướng sơ bộ:** chọn tình trạng đích bằng lựa chọn lớn; gửi duyệt theo K2.
- **Khuôn:** **dựng K5** trên màn dùng chung 036 / 037 / 041 (BJ đầu tiên của chặng 4, đặt tên màn trung tính, không mượn tên của BJ-07) ✅ v5.13.0; K1, K2, K3, K4, K6, K7.
- **Tài liệu bước E:** SCR-038, 056 + phần BJ-09 của 036 / 037 / 041, UIF-09.

#### BJ-07 Trả nhà cung cấp (UIF-07)

- **Plan:** [T7-P-bj07-bj10-tra-ncc-tieu-huy.md](T7-P-bj07-bj10-tra-ncc-tieu-huy.md) (chung với BJ-10; brief mục 0 duyệt 2026-10-25 theo đề xuất ở 0.10; rà lại theo code BJ-09 khi làm). Hướng dưới đây là bản trước brief.
- **Màn:** 036 Hàng chờ trả NCC (6), 037 Chuẩn bị hàng trả (6), 039 Bàn giao (5), 041 Kết quả (7).
- **Hướng sơ bộ:** vào từ danh sách chung "Hàng cần xử lý" (lọc "Trả nhà cung cấp") hoặc từ lô; dùng K5 dựng ở BJ-09 (chọn hàng → xử lý → bàn giao); thêm bước bàn giao cho nhà cung cấp (SCR-039).
- **Khuôn thực dùng ✅ v5.14.0:** K5 (dòng yêu cầu trả của danh sách chung), K1, K3, K4 (`k4Result`, `k4ReasonFooter`), K7 (`k7Split`, `k7Table`), `dsSegmented` ("Giao cho"); thanh tiến độ mảnh BJ-02. Không khuôn mới.
- **Tài liệu bước E ✅:** SCR-036, 037, 039, 041 (phần BJ-07), UIF-07.

#### BJ-10 Tiêu hủy (UIF-10)

- **Plan:** [T7-P-bj07-bj10-tra-ncc-tieu-huy.md](T7-P-bj07-bj10-tra-ncc-tieu-huy.md) (chung với BJ-07; `SC_journey_4` hết chặng 4). Hướng dưới đây là bản trước brief.
- **Màn:** dùng chung 036 / 037 / 041 + 040 Yêu cầu tiêu hủy (10 trạng thái).
- **Vấn đề đã biết:** cùng vấn đề tên màn vào như BJ-09; SCR-040 gánh 10 trạng thái (lập, duyệt, chờ tiêu hủy, xác nhận hoàn tất) trong một màn.
- **Hướng sơ bộ:** vào từ danh sách chung "Hàng cần xử lý" (lọc "Tiêu hủy") hoặc đi tiếp từ BJ-09 (hàng hỏng / hết hạn); tách rõ "đề nghị" → "duyệt" → "xác nhận đã tiêu hủy" (K2 + một bước xác nhận có ảnh bằng chứng).
- **Khuôn thực dùng ✅ v5.15.0:** K5 (`k5LotCard`, `k5QtyField`, `k5Evidence`), K2 (`k2Pending`, `k2Decision`, `k2RejectSheet`, nguồn "Chờ duyệt"), K1, K3, K4 (`k4ReasonFooter` nhận thêm `tone` cho nút nguy hiểm), K7, `dsSegmented` ("Cách xử lý"). Không khuôn mới.
- **Tài liệu bước E ✅:** SCR-040 + phần BJ-10 của 036 / 037 / 041, UIF-10.

### Chặng 5 — Kiểm kê và sửa sai

#### BJ-08 Kiểm kê (UIF-08)

- **Plan:** [T7-P-bj08-kiem-ke.md](T7-P-bj08-kiem-ke.md) (brief mục 0 duyệt 2026-10-25 theo đề xuất ở 0.10; bước C0 = fixture chung chặng 5, phân vai mỗi sản phẩm một câu chuyện để BJ-08 / 11 / 16 không sửa chồng). Hướng dưới đây là bản trước brief.
- **Màn:** 042 Danh sách phiên (6), 043 Tạo phiên (5), 044 Đếm mù (5), 045 Chênh lệch và đếm lại (6), 046 Duyệt điều chỉnh (6), 047 Kết quả (6).
- **Vấn đề đã biết:** SCR-044 "Hủy phiên" đặt ngang hàng cạnh "Nộp kết quả đếm"; đếm phải gõ bàn phím từng dòng, không quét mã, không +/−.
- **Hướng sơ bộ:** đếm mù tối ưu một tay (quét mã → bàn phím số → dòng kế tiếp); huỷ phiên chuyển vào menu của phiên; chênh lệch nổi bật bằng màu cảnh báo (đã có); duyệt theo K2.
- **Khuôn:** K2, K3, K4, K6.
- **Tài liệu bước E:** SCR-042…047, UIF-08.

#### BJ-11 Hủy & sửa sai (UIF-11)

- **Plan:** [T7-P-bj11-sua-sai.md](T7-P-bj11-sua-sai.md) (brief mục 0 duyệt 2026-10-25 theo đề xuất ở 0.10; gộp SCR-052 vào SCR-050, hủy thành sheet ở 049; lối vào từ thẻ kho để chặng 6). Hướng dưới đây là bản trước brief.
- **Màn:** 048 Nghiệp vụ cần kiểm soát (5), 049 Chi tiết nghiệp vụ (8), 052 Hủy hoặc chọn cách sửa (6), 050 Nội dung sửa sai (5), 051 Duyệt (5), 053 Kết quả (8).
- **Hướng sơ bộ:** vào từ chính phiếu bị sai (chi tiết nghiệp vụ, thẻ kho), không chủ yếu từ menu; một màn giải thích "huỷ được hay phải sửa" bằng lời thường; duyệt theo K2.
- **Khuôn:** K2, K3, K4.
- **Tài liệu bước E:** SCR-048…053, UIF-11.

#### BJ-16 Đối soát sai lệch và BJ-17 Kết quả chưa rõ (UIF-16, UIF-17)

- **Plan:** [T7-P-bj16-bj17-doi-soat.md](T7-P-bj16-bj17-doi-soat.md) (brief mục 0 duyệt 2026-10-25 theo đề xuất ở 0.10; một danh sách "Hồ sơ cần kiểm tra" cho hai luồng, Home một dòng, bỏ SCR-080; `SC_journey_5` hết chặng 5). Hướng dưới đây là bản trước brief.
- **Màn:** 078 Hồ sơ cần kiểm tra (7), 079 Bằng chứng & kết luận (10), 080 Phương án xử lý (5), 081 Đang khôi phục số liệu (5), 082 Rà soát kết quả (3), 083 Kết quả xử lý (6); BJ-17 dùng 078 / 079 / 080 / 082 / 083.
- **Vấn đề đã biết:** thuật ngữ kỹ thuật ("Số liệu hiển thị / Sổ kho / Nguồn nghiệp vụ / Bảo vệ phạm vi").
- **Hướng sơ bộ:** viết lại bằng lời Owner ("Số trên app lệch 2 hộp so với sổ; sổ vẫn đúng"); một bộ màn, hai lối vào (sai lệch / kết quả chưa rõ); kết luận → hành động cụ thể (khôi phục số / chuyển sửa sai BJ-11).
- **Khuôn:** K3 (là đích của mọi K3), K4.
- **Tài liệu bước E:** SCR-078…083, UIF-16, UIF-17.

### Chặng 6 — Chốt kỳ

#### BJ-14 Tính và công bố giá vốn (UIF-14)

- **Màn:** 072 Công việc giá vốn (4), 074 Tính và rà soát (5), 077 Kết quả (4); 073 / 075 / 076 đã retired.
- **Vấn đề đã biết:** thuật ngữ "Bình quân liên hoàn / cuối kỳ" không giải thích; màu tiền đã sửa (bước colorize).
- **Hướng sơ bộ:** một màn "chốt kỳ" kể theo thứ tự: kỳ nào → việc gì còn chặn → kết quả tính → phần chênh lệch sẽ ghi → Công bố; giải thích phương pháp bằng một dòng.
- **Khuôn:** K3, K4.
- **Tài liệu bước E:** SCR-072, 074, 077, UIF-14.

#### BJ-15 Báo cáo tồn và thẻ kho (UIF-15)

- **Màn:** 054 Tra cứu thẻ kho (5), 055 Danh sách biến động (10), 056 Chi tiết movement (6), 057 Dòng thời gian nguồn (5), 058 Xuất báo cáo (5), 059 Kết quả xuất (5).
- **Hướng sơ bộ:** vào từ một sản phẩm (BJ-01) là đường chính; bộ lọc thời gian gọn; ngày ghi nhận / ngày nghiệp vụ là một công tắc; xuất báo cáo là hành động phụ.
- **Khuôn:** K1, K6.
- **Tài liệu bước E:** SCR-054…059, UIF-15.

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

Hết chặng 6: kịch bản golden `SC_demo_*` đi đúng các bước trên (mỗi chặng đã có `SC_journey_<N>` riêng, mục 4.2b).

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
| Thêm bố cục web làm Giai đoạn 2 dài thêm (ước lượng thô **+4–5 ngày** khi còn chia chính / phụ; nay mọi BJ đủ hai bố cục nên cao hơn) | Không cắt bằng cách hạ một thiết bị xuống phụ (sửa 2026-10-22); dùng lại K7 / `k7Table` (bảng ↔ thẻ) để hai bố cục chung một nguồn dữ liệu. Ước lượng lại ở brief từng BJ |
| Khuôn dùng chung dựng ở chặng 1 (BJ-12) chưa đủ tổng quát — BJ-12 là việc một lần, khác nhịp hằng ngày của BJ-02 / 05 | Mô tả khuôn ở mục 5 ngay khi dựng; brief BJ-12 nêu rõ phần nào của khuôn phải hợp cho BJ-02 (lập trên iPhone, duyệt trên web); chặng 2 được phép chỉnh khuôn (ghi CHANGELOG, chạy lại golden BJ đã làm) |
| Đổi chữ vượt đặc tả | Mọi chữ mới vào mục 13, chỉ áp khi duyệt |
| Prototype đi xa hơn backend làm được | Bước B giữ nguyên quy tắc nghiệp vụ; điểm nào cần backend mới ghi rõ trong brief |
| Phần BJ-02 / 03 đã code Flutter phải làm lại | Chấp nhận; giai đoạn 5 lập plan sửa riêng |

## 13. Đề xuất sửa đặc tả và thành phần mới (điền dần)

| BJ             | Màn                                     | Loại (luồng / chữ / trạng thái / thành phần) | Đề xuất                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Đã duyệt                                                    |
| -------------- | --------------------------------------- | -------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| 02             | SCR-011                                 | trạng thái                                   | Dòng "Vượt chứng từ" hiện lượng theo chứng từ cạnh lượng thực nhận                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | ✅ 2026-10-22 (v5.8.0)                                                           |
| 02             | SCR-006 / SCR-007                       | luồng / chữ                                  | **Gộp SCR-006 vào SCR-007** (006 → RETIRED, "Bỏ từ v5.8.0"): tiêu đề "Nhận hàng"; ô tìm "Tìm chứng từ, nhà cung cấp hoặc sản phẩm"; "+{n}"; dòng "Hàng đến chưa có chứng từ" + "Nhập hàng nhanh · cần chủ cửa hàng duyệt"; EMPTY "Không có chứng từ đang chờ nhận" / "Hàng đến mà chưa có chứng từ mua thì nhập hàng nhanh." (chữ ngoài brief); cột bảng web "Chứng từ", "Nhà cung cấp", "Ngày", "Mặt hàng", "Tình trạng" + "Chờ nhận" (chữ ngoài brief) | ✅ 2026-10-22 (v5.8.0) |
| 02             | SCR-008                                 | luồng / chữ / thành phần                     | "Chụp ảnh" | "Chọn tệp"; ô tick "Tôi xác nhận hàng này thuộc sở hữu của cửa hàng"; chân "Tiếp tục" (thay "Xác nhận & tiếp tục") + lý do "Thêm chứng từ giao nhận" / "Tick xác nhận quyền sở hữu"; nhãn "Kho và ngày nhận" (chữ ngoài brief); `VFileDropZone` biến thể iPhone | ✅ 2026-10-22 (v5.8.0) |
| 02             | SCR-009                                 | chữ / thành phần                             | "Đã xử lý {a}/{b} mặt hàng" (thanh tiến độ mảnh, mới); "Còn {n} mặt hàng chưa xử lý"; nút quét trong ô tìm, "Quét thử: Oxytetracycline LA"; "Thêm ít nhất một mặt hàng" (chữ ngoài brief) | ✅ 2026-10-22 (v5.8.0) |
| 02             | SCR-084                                 | luồng / chữ / thành phần                     | "Nhận đủ {n} {ĐVT}"; "Hàng không đạt"; ô hạn dùng một ô "Ghi như trên bao bì: ngày/tháng/năm, tháng/năm hoặc năm" / "Hạn dùng chưa đúng dạng"; lý do ở chân "Nhập mã lô" / "Nhập hạn dùng"; bỏ `VNumericKeypadSheet` riêng; chữ ngoài brief: "Ngày sản xuất chưa đúng dạng" | ✅ 2026-10-22 (v5.8.0) |
| 02             | SCR-010                                 | luồng / chữ / trạng thái                     | "Cần chú ý" đứng đầu ("Vượt chứng từ", "Hàng không đạt", "Nhập nhanh"); ~~"Ghi nhận nhận hàng" + sheet tự duyệt~~ **bỏ 2026-10-22**: chủ cửa hàng lập cũng "Gửi phê duyệt" rồi tự vào SCR-011 duyệt (cửa hàng chỉ có một chủ); thêm `REJECTED` ("Yêu cầu bị từ chối", "Nhận lại"); bỏ `APPROVER_CONFIGURATION_MISSING` và `FINANCIAL_MASKED` | ✅ 2026-10-22 (v5.8.0) |
| 02             | SCR-011                                 | luồng / chữ                                  | "Duyệt nhận hàng {chứng từ} của {NCC}?" / "Duyệt nhập hàng nhanh của {NCC}?"; bảng Sản phẩm · Lô / HSD · Theo chứng từ · Thực nhận · Chênh lệch · Tình trạng; "Từ chối" dùng `k2RejectSheet`; "Đã từ chối nhận hàng"; "Tổng giá trị rủi ro" tone thường | ✅ 2026-10-22 (v5.8.0) |
| 02             | SCR-012                                 | luồng / chữ                                  | K4: "Vào tồn" "{n} mặt hàng · {m} lô", "Giá trị" "Chờ xác lập", "Xem {n} dòng hàng"; chân theo vai: chủ cửa hàng "Nhận tiếp" \| "Xác lập giá trị" (→ BJ-03), nhân viên "Xem tồn kho" \| "Nhận tiếp"; "Quay lại rà soát"; `UNKNOWN` / `COMMIT_UNKNOWN` mở SCR-013 | ✅ 2026-10-22 (v5.8.0) |
| 02             | SCR-013                                 | luồng / chữ                                  | Một màn phục hồi ngắn (K3, thêm `title` và `detail` cho `k3Unknown`); "Chuyển sang xác minh" thay "Xem hỗ trợ xử lý" | ✅ 2026-10-22 (v5.8.0) |
| 02             | UC-02-03, BJ-02, SCR-011                | nghiệp vụ                                    | Phần BJ-02 của dòng "mọi BJ theo K2": ngoại lệ `is_owner` ghi vào UC-02-03 (mục tiêu, tác nhân, BR-02), BJ-02 (mục 2): chủ lập vẫn gửi duyệt rồi tự duyệt, không có đường ghi nhận thẳng | ✅ 2026-10-22 (v5.8.0) |
| 01             | SCR-001                                 | thành phần                                   | `VStockRow`: List Row có cột phải hai tầng (số khả dụng mono + badge tình trạng)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | ✅                                                           |
| 01             | SCR-001                                 | chữ / thành phần                             | Nút "Quét mã vạch" trong ô tìm                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | ✅                                                           |
| 01             | SCR-003                                 | luồng / chữ                                  | Tiêu đề = tên sản phẩm; "Gợi ý nhập thêm …" + "Nhận hàng" → BJ-02; "Xử lý lô hết hạn" → BJ-09                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | ✅                                                           |
| 01             | SCR-001, 003                            | chữ / thành phần                             | Chữ mới: sheet "Quét mã vạch" / "Đưa mã vạch vào khung"; banner "Có lô hết hạn" / "Lô {mã} · {SL} {ĐVT} không đủ điều kiện bán."; chip lọc kèm số; không có quyền: "Bạn chưa có quyền xem tồn kho" / "Bạn chưa được cấp quyền xem tồn kho. Liên hệ chủ cửa hàng nếu cần." / "Về Kho"                                                                                                                                                                                                                                                                                                                                                                                                                                                    | ✅                                                           |
| mọi BJ theo K2 | SCR-011, 034, 038, 040, 046, 051, 070 … | nghiệp vụ                                    | **Người duyệt =** `is_owner` **hoặc role** `store_owner` (kiểm thẳng ở RPC duyệt / ghi nhận, không thêm quyền `inventory.approve`; `hasPermission` hiện cho mọi thành viên có role — TH-01 BR-52 — nên không dùng được). **Chỉ** `is_owner` **được tự duyệt phiếu mình lập — bằng cách gửi duyệt rồi tự bấm "Duyệt" ở màn duyệt (không có đường ghi nhận thẳng, 2026-10-22; mỗi cửa hàng một chủ)**; role `store_owner` không phải `is_owner` vẫn cần `is_owner` duyệt; vi phạm → `SELF_APPROVAL_NOT_ALLOWED`. "Owner" trong spec Theme 7 = `is_owner`. Sửa `T7-DR-081` (vế "không phải người lập") và `T7-DR-078` (hoàn nguyên "tuân thủ maker–checker"); UC / BC / SCR / UIF đang có `SELF_APPROVAL_NOT_ALLOWED` hoặc "không tự duyệt" (BJ-02, 06, 08, 09, 10, 11, 12; `ENT-IC-02`, glossary, KB-KGV-011 / 021 / 031). Từng BJ áp ở bước E, rà toàn bộ ở 7.3 | ✅ 2026-10-20 (người dùng)                                   |
| 12             | SCR-066                                 | luồng / chữ                                  | Home Kho khi kho chưa kích hoạt: khối "Kho chưa kích hoạt" + "Khởi tạo tồn kho", 4 nút nhanh tắt; "Nhận hàng chờ phê duyệt" → **"Chờ duyệt"** (gom mọi BJ, "3 nhận hàng · 1 số dư đầu kỳ"). 066: "Cần chuẩn bị", "Tải tệp mẫu", lý do + người từ chối, "Tiếp tục chuẩn bị", "Đặt ngưỡng tồn"; chưa rõ kết quả: "Mã tham chiếu", "Thời điểm gửi", "Tồn kho: Chưa mở cho đến khi xác minh xong", "Không nạp lại tệp hay gửi lại."                                                                                                                                                                                                                                                                                                         | ✅ brief 2026-10-21; áp ở prototype v5.5.0                   |
| 12             | SCR-067                                 | chữ / thành phần                             | "Kéo tệp vào đây hoặc Chọn tệp" (web), "Tệp cần có các cột", "Xem các cột cần có" (iPhone), lỗi tại ô ("Chọn tệp số dư", "Chọn ngày chốt số dư", "Nhập tổng số lượng theo sổ", "Nhập tổng giá trị theo sổ"), banner "Điền các ô được đánh dấu trước khi kiểm tra."                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | ✅ brief; áp v5.5.0                                          |
| 12             | SCR-068 / SCR-069                       | luồng / chữ                                  | **Gộp SCR-069 vào SCR-068** (069 → RETIRED, "Bỏ từ v5.5.0"). 068: "{a} dòng đọc được · {b} hợp lệ · {c} cần sửa", cột "Cách sửa" (kèm cách sửa từng lỗi), cột "Theo tệp / Theo sổ / Chênh lệch", "Số dư sẽ ghi nhận", "Khớp số kiểm soát", "Dòng sẽ vào kho", chip "Tất cả / Bán được / Không bán được", "Hiện {n} / {m} dòng", "Ghi nhận số dư đầu kỳ" (Owner) + sheet "Chỉ ghi nhận một lần. Sai sau này phải sửa bằng điều chỉnh." / "Huỷ" / "Ghi nhận"                                                                                                                                                                                                                                                                              | ✅ brief; áp v5.5.0                                          |
| 12             | SCR-070                                 | chữ / trạng thái                             | "Cần quyết", "Duyệt số dư đầu kỳ của {kho}, chốt {ngày}?", "{người} gửi {thời điểm}", "Cần chú ý", "Không bán được: {n} dòng (cách ly / hư hỏng)", "Sau khi duyệt: Kho bắt đầu hoạt động", bảng "Dòng sẽ vào kho" (UC-12-02 BF-01); `SELF_APPROVAL_NOT_ALLOWED` chỉ khi người lập không phải `is_owner`                                                                                                                                                                                                                                                                                                                                                                                                                                 | ✅ brief; áp v5.5.0                                          |
| 12             | SCR-071                                 | chữ                                          | "Người duyệt: Chủ cửa hàng" (chủ lập cũng gửi duyệt rồi tự duyệt; **bỏ** "(tự duyệt)" và nhánh "Ghi nhận số dư đầu kỳ" + sheet, 2026-10-22); "Đặt ngưỡng tồn" → CAP-01; `REJECTED_EXECUTION` có "Lý do" + "Tiếp tục chuẩn bị" (chữ "Lý do" của 071: đề xuất của người làm, chưa có trong brief)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | ✅ brief; áp v5.5.0                                          |
| 12             | UC-12-02, BJ-12, SCR-070                | nghiệp vụ                                    | Phần BJ-12 của dòng "mọi BJ theo K2" ở trên: ghi ngoại lệ `is_owner` (lập thì vẫn gửi duyệt rồi tự duyệt, không ghi nhận thẳng — làm rõ 2026-10-22) vào UC-12-02 (BF-02, kết quả), BJ-12 (mục 2), SCR-070 mục 6; người duyệt khác = `is_owner` hoặc `store_owner`. `T7-DR-081` / `T7-DR-078` sửa ở 7.3                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | ✅ áp ở bước E BJ-12 (2026-10-21)                            |
| 06             | SCR-030                                 | luồng / chữ                                  | K6: chip có số "Tất cả / Cần xử lý / Đang chờ"; dòng "Chờ duyệt lô" **mở được, chỉ đọc**; rỗng "Chưa có yêu cầu trả cần xử lý" / "Yêu cầu trả hàng được Bán hàng chấp nhận sẽ hiện ở đây."; không có quyền "Bạn chưa có quyền nhận hàng khách trả" / "Liên hệ chủ cửa hàng để được cấp quyền."                                                                                                                                                                                                                                  | ✅ brief 2026-10-24; áp v5.12.0                              |
| 06             | SCR-031, 032                            | luồng / chữ                                  | Hai mốc: "Bước 1/2 · Nhận hàng", "Đã kiểm {a}/{b} dòng", "Lô giao {lô} · được nhận {n} {ĐVT}"; web **SCR-031 + 032 một trang hai cột**; "Nhận đủ {n} {ĐVT}"; lô thực nhận không chọn sẵn; "Ảnh sẽ gửi kèm yêu cầu duyệt", "Sửa dòng này thì phải gửi duyệt lại.", "Lý do: {lý do}"; lý do chân: "Còn {n} dòng chưa kiểm", "Sửa dòng bị từ chối rồi gửi lại", "Nhập số lượng thực nhận", "Chọn lô thực nhận", "Thêm ảnh nhãn lô"; chặn: "Người khác vừa cập nhật yêu cầu này", "Yêu cầu đang được xử lý", "Đợi lần xử lý hiện tại xong rồi mở lại." (tiêu đề 031 "Kiểm hàng khách trả" là chữ prototype, spec cũ ghi "Hàng khách trả") | ✅ brief; áp v5.12.0                                         |
| 06             | SCR-033, 035                            | luồng / chữ                                  | "Bước 2/2 · Phân loại", "Đã phân loại {a}/{b} dòng"; mỗi dòng một lựa chọn lớn "Bán được / Cách ly / Hỏng" ("Cả {n} {ĐVT}") + "Chia nhiều loại" (web "Chia"), không chọn sẵn; "Còn {n} {ĐVT} chưa phân loại", "Còn {n} dòng chưa phân loại"; 035: tiêu đề màn "Kết quả hàng trả", "Người nhận", "Ghi nhận lúc" / "Phân loại lúc" điền thật, "Hàng cách ly / hỏng chờ xử lý ở Hàng cần xử lý.", K3 "Nhận hàng khách trả"                                                                | ✅ brief; áp v5.12.0                                         |
| 06             | SCR-034                                 | luồng / chữ                                  | Duyệt ngoại lệ lô vào từ Home **"Chờ duyệt"** (K2; dòng "ngoại lệ lô hàng trả"); "Duyệt nhận lô {lô thực nhận} thay cho lô {lô giao}?"; "Chưa có ảnh nhãn lô"; K4 "Thủ kho ghi nhận hàng trả khi tất cả dòng hợp lệ."; "Bạn chưa có quyền duyệt ngoại lệ lô" / "Chỉ chủ cửa hàng duyệt ngoại lệ lô hàng trả."; **chữ ngoài brief:** "Không thể tự duyệt", "Sản phẩm" (đầu bảng số liệu), "Cần nhận ít nhất một dòng", "Nhập hạn dùng lô mới", "Mô tả lý do ngoại lệ", "Chọn lý do ngoại lệ", "Chưa phân loại" / "Chưa đủ" / "Không nhận" (badge 033), "Chưa kiểm" (bảng 031), "Chờ quyết định" (ca ở danh sách) | ✅ brief; áp v5.12.0 (chữ ngoài brief: đề xuất của người làm) |
| 06             | UC-06-02, BJ-06, SCR-034, UIF-06-T06    | nghiệp vụ                                    | Phần BJ-06 của dòng "mọi BJ theo K2": người duyệt = `is_owner` hoặc `store_owner`; chủ lập cũng gửi rồi tự duyệt; UIF-06-T06 "không self-approve" → theo K2; duyệt chưa tự ghi nhận                                                                                                                                                                                                                                                                                                                                                                                                                                                       | ✅ áp ở bước E BJ-06 (UC-06-02 BR-06, SCR-034 mục 6, UIF-06) |
| CAP-01         | SCR-062                                 | luồng / chữ / thành phần                     | Ngưỡng tồn theo từng sản phẩm: bảng sửa tại dòng (web) / danh sách + sheet sửa (iPhone) / một sản phẩm (từ BJ-01); thanh chọn "Ngưỡng tồn | Cận hạn"; "Huỷ thay đổi", "Lưu thay đổi ({n})"; sheet tác động "Lưu {n} thay đổi?", "{tên}: {cũ} → {ngưỡng} / {mục tiêu} {ĐVT}", "chưa có", "Tồn thấp: {a} → {b} sản phẩm"; toast "Đã lưu chính sách · Lần {N}"; "Sau khi lưu: {chỉ báo}" / "Sau khi lưu: Không có cảnh báo"; lỗi "Mục tiêu phải lớn hơn hoặc bằng ngưỡng."; bỏ ô "Nguồn áp dụng" (OP-01); **chữ ngoài brief:** badge "Bình thường", lọc rỗng "Không còn sản phẩm nào chưa có ngưỡng" / "Mọi sản phẩm đã có ngưỡng cảnh báo." / "Xem tất cả"                                                                                | ✅ brief; áp v5.7.0 (chữ ngoài brief: đề xuất của người làm) |
| CAP-01         | SCR-063                                 | luồng / chữ                                  | "Mặc định cho mọi sản phẩm", thẻ "Cảnh báo" / "Chặn bán" kèm mô tả, "Sản phẩm có chính sách riêng", "Dùng mặc định", "Thêm sản phẩm"; **chữ ngoài brief:** "Số ngày cận hạn phải lớn hơn 0.", "Chưa có sản phẩm nào có chính sách riêng.", "Mọi sản phẩm theo lô đều đã có chính sách riêng."                                                                                                                                                                                                                                                                                                                                                                                                                                           | ✅ brief; áp v5.7.0                                          |
| CAP-01         | SCR-064 / SCR-065                       | luồng / trạng thái                           | **SCR-064 → RETIRED** ("Bỏ từ v5.7.0", thay bằng sheet tác động trong 062); bỏ `APPROVAL_REQUIRED` (không có luồng duyệt, nhân viên chỉ xem: "Chỉ chủ cửa hàng thay đổi được chính sách." / "Bạn có thể xem các mức hiện tại."); 065 chỉ còn `UNKNOWN` / `REJECTED_EXECUTION` ("Chưa cập nhật chính sách", "Quay lại chính sách") / `PERMISSION_DENIED`                                                                                                                                                                                                                                                                                                                                                                                 | ✅ brief; áp v5.7.0                                          |
| 01             | SCR-003                                 | luồng / chữ                                  | "Đặt ngưỡng tồn" (sản phẩm chưa có ngưỡng) và "Sửa ngưỡng" (Hết hàng / Tồn thấp, trong khối cảnh báo) → CAP-01 SCR-062 một sản phẩm, lưu xong về SCR-003                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | ✅ brief; áp v5.7.0                                          |
| 03             | SCR-014                                 | luồng / chữ                                  | Dòng Hub = tên màn "Hàng chờ xác lập giá trị" + "Ghi giá nhập cho hàng đã nhận" (`FLOW_LABELS` "Xác lập giá trị nhập ban đầu"); chip lọc có số; dòng "{n} sản phẩm chờ" + badge cho mọi phiếu; web bảng có cột "Chờ" ("{n} ngày"); rỗng "Không còn hàng chờ giá trị" / "Các phiếu nhận đã được xác lập giá trị."                                                                                                                                                                                                                                                                                                                                                                                                                        | ✅ 2026-10-22 (v5.9.0)                                       |
| 03             | SCR-015                                 | luồng / chữ / thành phần                     | Bảng sản phẩm có ô tick (dòng đủ căn cứ tick sẵn); "Cách tính"; "Nhập giá"; "Thống nhất giá ở Mua hàng rồi quay lại."; "Chứng từ mua chưa có giá cho dòng này."; "Chưa có chứng từ mua — nhập giá theo hoá đơn hoặc báo giá của nhà cung cấp."; "Quy đổi từ USD theo tỷ giá kế toán"; "Tóm tắt"; "Đã chọn {n} sản phẩm · {tổng}"; "Ghi giá trị ({n})" (thay "Rà soát") + "Chọn ít nhất một sản phẩm đủ căn cứ"; "Phiếu này đã được xác lập giá trị"                                                                                                                                                                                                                                                                                     | ✅ 2026-10-22 (v5.9.0)                                       |
| 03             | SCR-015 (sheet)                         | luồng / chữ                                  | Bỏ ô "Tiền tệ" (JA-05: căn cứ trực tiếp chỉ VND); "đ/{ĐVT}"; "Giá vốn hiện tại: {giá} đ/{ĐVT}"; "Cách hiểu giá" thành thanh chọn (mặc định "Đã gồm thuế"); "Ngày căn cứ" điền sẵn ngày nhận; bỏ "Kế toán có thể lập căn cứ…"; **chữ ngoài brief:** "Quay lại" (đóng sheet), "Đóng" (sheet "Cách tính" / chi tiết)                                                                                                                                                                                                                                                                                                                                                                                                                       | ✅ 2026-10-22 (v5.9.0)                                       |
| 03             | SCR-017 / SCR-015                       | luồng / chữ                                  | **SCR-017 → RETIRED** ("Bỏ từ v5.9.0", thay bằng sheet xác nhận trong SCR-015): "Ghi giá trị nhập ban đầu?", "{tên}: {SL} {ĐVT} × {đơn giá} = {thành tiền}", "Ghi xong không sửa trực tiếp. Chi phí phát sinh sau dùng điều chỉnh giá trị."; `SOURCE_CHANGED` đóng sheet, banner ở 015                                                                                                                                                                                                                                                                                                                                                                                                                                                  | ✅ 2026-10-22 (v5.9.0)                                       |
| 03             | SCR-019                                 | luồng / chữ                                  | K4 "Sản phẩm đã xác lập", "Người ghi", "Lúc", "Còn chờ giá trị"; chân "Cập nhật giá vốn" (→ BJ-14) | "Tiếp tục xử lý" / "Về danh sách"; K3 / K1; **chữ ngoài brief:** "Chi tiết {n} sản phẩm" (tiêu đề sheet chi tiết)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | ✅ 2026-10-22 (v5.9.0)                                       |
| 03             | mọi màn                                 | chữ / quyền                                  | Không có quyền: "Bạn chưa có quyền xác lập giá trị" / "Chỉ chủ cửa hàng xem và ghi giá nhập." (cả `FINANCIAL_MASKED`); chỉ chủ cửa hàng xem và ghi                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | ✅ 2026-10-22 (v5.9.0)                                       |
| 03             | UC-03-01                                | nghiệp vụ                                    | Ghi rõ "Kế toán kho" = chủ cửa hàng khi không có kế toán riêng (một dòng chú thích mục 8); mục 8 bỏ SCR-017. Không đổi quy tắc                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | ✅ 2026-10-22 (v5.9.0)                                       |
| 13             | SCR-085 / Hub                           | luồng / chữ                                  | Dòng Hub = tên màn "Điều chỉnh giá trị hàng nhập" + "Chi phí, chiết khấu phát sinh sau khi đã xác lập giá" (thay "Chi phí mua bổ sung" — danh sách có cả khoản giảm); chip có số; web bảng Nguồn · Loại · Đối tác · Số tiền · Sản phẩm · Tình trạng; số tiền luôn có dấu; "Chờ quy đổi" (thay "0 đ"); rỗng "Không có khoản điều chỉnh nào" / "Khoản phát sinh sau khi đã xác lập giá sẽ hiện ở đây." | ✅ 2026-10-24 (v5.10.0) |
| 13             | SCR-086                                 | luồng / chữ                                  | Một màn hai cột (web): bỏ khối "Phạm vi áp dụng" (một bảng "Kết quả phân bổ" + "Phạm vi do nguồn xác định, không bỏ bớt sản phẩm được."); cột "Giá trị nhập" (thay "Căn cứ phân bổ"), "Tỷ trọng", "Phân bổ"; "Xem chứng từ"; kỳ một dòng "Ghi vào kỳ {kỳ mở} · kỳ gốc {kỳ gốc} đã khoá" / "Ghi vào kỳ {kỳ}" (bỏ banner "Kỳ của hàng gốc đã khóa"); lỗi "Hàng trong phạm vi chưa đủ dữ liệu để chia theo cùng một cách. Hệ thống không tự chia đều." (bỏ "metric"); nguồn đang chờ mở chỉ đọc | ✅ 2026-10-24 (v5.10.0) |
| 13             | SCR-088 / SCR-086                       | luồng / chữ                                  | Sheet "Ghi điều chỉnh giá trị?" (SCR-088 đã RETIRED) thêm "{n} sản phẩm"; nút "Xác nhận" (thay "Ghi điều chỉnh" trong sheet) | ✅ 2026-10-24 (v5.10.0) |
| 13             | SCR-089                                 | luồng / chữ                                  | K4; "Cập nhật giá vốn" (→ BJ-14, chữ BJ-03); "Xem chi tiết phân bổ ({n})" mở sheet "Kết quả phân bổ" + "Đóng"; `UNKNOWN` theo K3 với "Không ghi lại điều chỉnh. Chuyển đúng thao tác này sang xác minh." (bỏ "adjustment") | ✅ 2026-10-24 (v5.10.0) |
| 13             | mọi màn                                 | chữ / quyền                                  | Không có quyền: "Bạn chưa có quyền điều chỉnh giá trị" / "Chỉ chủ cửa hàng xem và ghi điều chỉnh giá trị." (cả `FINANCIAL_MASKED`) | ✅ 2026-10-24 (v5.10.0) |
| 13             | UC-13-01                                | nghiệp vụ                                    | Ghi rõ "Kế toán" = chủ cửa hàng khi không có kế toán riêng (như UC-03-01); mục 8 bỏ SCR-087 / 088. Không đổi quy tắc | ⬜ (chốt đặc tả 7.3) |
| 13 / 03 / mọi K4 | SCR-019, 089, Hub                     | luồng                                        | iPhone Toàn Theme 7: màn kết quả K4 không có lối về Home ngoài đi vòng (không thanh dưới trong luồng) — đề xuất thanh dưới trong luồng hoặc "Về Kho" ở K4; bẫy focus cho mọi sheet đưa vào `core.js` (ghi chú mục 8 plan BJ-13) | ⬜ đề xuất |
| 04 | SCR-021 | luồng / chữ | Phụ "Đơn {mã} · {khách}"; dải "{a} đang giữ · {b} thiếu · {c} đã xong"; iPhone "{mã} · Đang giữ {h}/{r} {ĐVT}" + badge "Giữ đủ" (mới); web bảng Sản phẩm · "Cần giữ" · "Đang giữ" · "Đã bàn giao" · "Thiếu" · Tình trạng + khối "Tóm tắt"; chân "Lấy hàng" (chữ nút nhanh Hub) → SCR-026; **lối vào mới** từ SCR-026 "Xem giữ hàng" (quay lại về SCR-026); không có quyền "Bạn chưa có quyền xem giữ hàng" / "Liên hệ chủ cửa hàng để được cấp quyền." | ✅ 2026-10-24 (v5.11.0) |
| 05 | SCR-025 | luồng / chữ / thành phần | **Dựng K6**: chip có số "Tất cả" · "Cần lấy" · **"Chờ bàn giao"** (mới) · "Đang chờ"; dòng "{khách} · {n} mặt hàng" (thay "· Kho chính"); web bảng Đơn · Khách hàng · "Đã lấy" ("{a}/{b} mặt hàng") · Tình trạng; đơn "Chờ bàn giao" mở thẳng SCR-028; không có quyền "Bạn chưa có quyền lấy và bàn giao hàng" / "Liên hệ chủ cửa hàng để được cấp quyền." | ✅ 2026-10-24 (v5.11.0) |
| 05 | SCR-026 / SCR-027 | luồng / chữ | **Gộp SCR-027 vào SCR-026** (027 → RETIRED, "Bỏ từ v5.11.0"): "Đã lấy đủ {a}/{b} mặt hàng"; mỗi lô một dòng "Lô {mã}" · "HSD {hsd} · Lấy {n} {ĐVT}"; nút **"Lấy đủ"** (mới); "Đã lấy {p}/{n}"; sheet "Đã lấy" lưu ngay (bỏ "Lưu lượng đã lấy"); "Giao một phần" "Được" / "Không" (mới); "Xem giữ hàng" (mới); lý do chân: "Lấy ít nhất một mặt hàng", "Đơn này yêu cầu giao đủ · còn {n} mặt hàng chưa lấy đủ", "Xác nhận điều chỉnh lô trước khi bàn giao" | ✅ 2026-10-24 (v5.11.0) |
| 05 | SCR-028 | luồng / chữ | **"Giao cho"** — "Khách nhận tại quầy" \| "Đơn vị vận chuyển" (UC-05-03 BF-03 có "người/đơn vị nhận", prototype trước thiếu; ghi `evidence.recipient`); "Giao lần này" / "Còn lại sau lần này" "{n} mặt hàng" (thay "Trong lần này" / "Chưa hoàn tất" / "dòng hàng"); `READY` chỉ đọc, `PARTIAL_ALLOWED` có ô sửa; `PARTIAL_BLOCKED` chân tắt có lý do | ✅ 2026-10-24 (v5.11.0) — **cần chốt ở 7.3 nếu giữ "Giao cho"** |
| 05 | SCR-029 | luồng / chữ | K4: thêm "Giao cho", "Người bàn giao", "Bàn giao lúc" điền thật; **"Lấy đơn tiếp theo"** (mới); `UNKNOWN` theo K3 (nghiệp vụ "Bàn giao hàng"; câu khuôn K3, không thêm câu riêng — review chặng 3 R3); `PERMISSION_DENIED` là K1 thay màn kết quả đỏ | ✅ 2026-10-24 (v5.11.0) |
| 05 | UC-05-02, UC-05-04, 00-use-case-map, PAT-NAV | nghiệp vụ / tài liệu | Mục "màn sử dụng" còn ghi SCR-027 → đổi sang SCR-026 (UC-05-02, UC-05-04, `00-use-case-map.md`); không đổi quy tắc. `PAT-NAV.md` đã sửa | ⬜ (chốt đặc tả 7.3) |
| 09 | SCR-036 | luồng / chữ / trạng thái | **Dựng K5** — một danh sách chung "Hàng cần xử lý" cho UIF-07 / 09 / 10 (thay "Tình trạng hàng" / "Hàng chờ trả nhà cung cấp" / "Hàng có thể xử lý"); phụ "Hàng không bán được và yêu cầu trả nhà cung cấp"; ô tìm "Tìm sản phẩm, lô hoặc mã yêu cầu"; chip có số "Cần xử lý" · "Trả nhà cung cấp" · "Tiêu hủy" · "Đang chờ" (hàng "Bán được" không vào danh sách); phụ "Lô {lô} · HSD {hsd} · {n} {ĐVT}" + "· Chờ duyệt đổi sang {tình trạng}" / "· Chờ tiêu hủy"; "{NCC} · {n} mặt hàng"; web bảng Hàng · Lô / yêu cầu · HSD · Số lượng · Việc · Tình trạng ("Chưa xử lý", "Trả {NCC}"); rỗng "Không có hàng cần xử lý" / "Hàng hết hạn, cách ly, hỏng và yêu cầu trả nhà cung cấp sẽ hiện ở đây."; không có quyền "Bạn chưa có quyền xử lý hàng có vấn đề"; **bỏ trạng thái `EXPIRED` khỏi bộ chọn** | ✅ 2026-10-25 (v5.13.0) |
| 09 | SCR-037 | luồng / chữ / trạng thái | Một "Chi tiết hàng" cho UIF-09 và UIF-10 (tiêu đề = tên sản phẩm; phụ "Lô {lô} · HSD {hsd}"); thẻ lô + "{n} {ĐVT} {tình trạng} · Khả dụng bán {k}", "Từ hàng khách trả {mã}" / "Từ nhận hàng {mã}"; **"Việc tiếp theo"** + "Đề nghị tiêu hủy" cho lô hết hạn / hỏng / cách ly / dùng thử (hết ngõ cụt), "Xem yêu cầu"; "Trả nhà cung cấp do bộ phận Mua hàng lập yêu cầu. Khi có yêu cầu, hàng hiện ở mục Trả nhà cung cấp." (UC-07-01: Kho không tự tạo yêu cầu trả); **bỏ `FINANCIAL_RESTRICTED`** (màn không có tiền) | ✅ 2026-10-25 (v5.13.0) |
| 09 | SCR-038 | luồng / chữ / thành phần | Tiêu đề "Đổi tình trạng" (thay "Chuyển tình trạng hàng"); "Đổi sang" chọn bằng `dsChoiceRow`, **không chọn sẵn**, "Cần chủ cửa hàng duyệt" (thay "Cần người duyệt độc lập") / "Ghi nhận ngay"; "Số lượng" + "Cả {n} {ĐVT}" (`k5QtyField`); "Ảnh bằng chứng" (thay ô chữ "Bằng chứng"); khối "Sau khi đổi": "Khả dụng bán: {a} → {b} {ĐVT}", "Đơn đang giữ: {n} {ĐVT} cần phân bổ lại", "Tổng tồn và giá trị không đổi."; chân "Gửi phê duyệt" + lý do "Chọn tình trạng mới" / "Nhập số lượng" / "Nhập lý do" / "Thêm ảnh bằng chứng"; toast "Đã gửi chủ cửa hàng duyệt"; "Về hàng cần xử lý" | ✅ 2026-10-25 (v5.13.0) |
| 09 | SCR-038 (duyệt) / Home | luồng / chữ / quyền | Duyệt theo K2: Home "Chờ duyệt" nguồn "đổi tình trạng" ("{sản phẩm} · Lô {lô}" / "{n} {ĐVT} · {từ} → {sang} · {người gửi} gửi {lúc}"); câu "Duyệt đổi {n} {ĐVT} {sản phẩm} lô {lô} từ {từ} sang {sang}?"; bỏ banner "Phê duyệt không ghi tồn"; "Duyệt" ghi ngay (không sheet); "Từ chối yêu cầu?" dùng `k2RejectSheet`; **chủ cửa hàng tự lập vẫn tự duyệt được** (UC-09-02: người duyệt `is_owner` / `store_owner`); `SELF_APPROVAL_NOT_ALLOWED` "Không thể tự duyệt" + "Chỉ chủ cửa hàng duyệt đổi tình trạng." | ✅ 2026-10-25 (v5.13.0) |
| 09 | SCR-041 | luồng / chữ | K4 "Đã cập nhật tình trạng" thêm "Người duyệt" ("Chủ cửa hàng" / "Không cần duyệt") và "Ghi nhận lúc"; sang "Hỏng" → "Đề nghị tiêu hủy" (→ BJ-10); `EXPIRED` K4 cảnh báo + "Đề nghị tiêu hủy"; `UNKNOWN` theo K3 (nghiệp vụ "Đổi tình trạng hàng"); "Về hàng cần xử lý" | ✅ 2026-10-25 (v5.13.0) |
| 09 | Hub / Home / BJ-01 | luồng | Hub "Hàng cần xử lý" và "Trả nhà cung cấp" cùng mở SCR-036 (chip "Tất cả" / "Trả nhà cung cấp"); **bỏ "Tồn kho → Tình trạng hàng"**; Home "Cần chú ý" "Hàng cần xử lý" "{a} lô hết hạn · {b} cách ly / hỏng" thay "Lô sắp hết hạn · 3 lô"; BJ-01 sheet lô thêm "Đổi tình trạng", "Xử lý lô hết hạn" mở thẳng SCR-037 của lô | ✅ 2026-10-25 (v5.13.0) |
| 07 | SCR-036 / SCR-037 | luồng / chữ / thành phần | Dòng yêu cầu trả ở danh sách chung (phụ "{NCC} · {n} mặt hàng"); 037: phụ "{mã yêu cầu} · {NCC}", "Yêu cầu do Mua hàng chuyển sang Kho · {chứng từ}", "Đã kiểm {a}/{b} dòng", "{mã} · Trả {n} {ĐVT}", "HSD {hsd} · Trả {n} {ĐVT}", nút **"Đúng hàng"** một chạm trên dòng, "· Cần chọn phần hàng" (thay "Cần xác định nguồn tồn"), sheet "Trả từ phần hàng nào" / "Lô này có hàng ở nhiều tình trạng. Ghi số lượng trả từ từng phần." / "Cần chia đủ {n} {ĐVT}"; web bảng Sản phẩm · Lô · HSD · "Trả" · "Kiểm" + "Tóm tắt"; chân "Còn {n} dòng chưa kiểm" / "Có dòng không khớp · chờ Mua hàng cập nhật"; `EXPIRED` / `FINANCIAL_RESTRICTED` của 037 dựng như `READY`; thêm trạng thái bộ chọn `SOURCE_UPDATED`, `WAITING` | ✅ 2026-10-26 (v5.14.0) |
| 07 | SCR-039 | luồng / chữ | **"Giao cho"** — "Nhà cung cấp nhận" \| "Đơn vị vận chuyển" (BJ-07 mục 1 "giao cho nhà cung cấp hoặc đơn vị vận chuyển"; ghi `evidence.recipient`; cùng mẫu BJ-05); "Hàng sẽ bàn giao" "{n} mặt hàng · {m} dòng"; "Trả từ {tình trạng} {n}"; "Xác nhận khi hàng đã giao thực tế. Tồn vật lý và giá trị chỉ giảm sau bước này."; bỏ khối "Thông tin bàn giao"; `SOURCE_CHANGED` theo `k1Stale`; viết lại theo `_TEMPLATE.md` (bỏ `FROZEN`) | ✅ 2026-10-26 (v5.14.0) |
| 07 | SCR-041 | luồng / chữ | K4 "Đã bàn giao cho nhà cung cấp": "Nhà cung cấp" · "Yêu cầu trả" · "Chứng từ nguồn" · "Giao cho" · "Người bàn giao" · "Bàn giao lúc" (điền thật); "Xem {n} dòng hàng" (sheet, không lặp danh sách dài); **"Yêu cầu tiếp theo"** (mới; rút từ "Chuẩn bị yêu cầu tiếp theo" — review chặng 4 R3); `UNKNOWN` theo K3 (nghiệp vụ "Bàn giao trả nhà cung cấp"); `PERMISSION_DENIED` là K1 "Bạn chưa có quyền trả hàng nhà cung cấp" | ✅ 2026-10-26 (v5.14.0) |
| 10 | SCR-040 | luồng / chữ / trạng thái | **Một mã màn, bốn chế độ dựng khác hẳn** (đề nghị / chờ duyệt / duyệt / đã duyệt → xác nhận); "Cách xử lý" — "Cửa hàng tự tiêu hủy" \| "Thuê đơn vị xử lý" (UC-10-01 BF-03 "phương thức xử lý", prototype trước thiếu); "Ảnh hiện trạng" / "Ảnh hoặc biên bản tiêu hủy" bắt buộc (thay ô chữ "Bằng chứng"); lỗi tại ô "Tối đa {n} {ĐVT}"; chân "Gửi phê duyệt" (thay "Gửi yêu cầu tiêu hủy"); "Lô này chưa có giá vốn"; không còn ngõ cụt sau gửi / duyệt | ✅ 2026-10-26 (v5.15.0) |
| 10 | SCR-040 / Home | luồng / chữ / quyền | Duyệt theo K2: Home "Chờ duyệt" nguồn **"tiêu hủy"** ("{sản phẩm} · Lô {lô}" / "{n} {ĐVT} · {người gửi} gửi {lúc}"); "Duyệt tiêu hủy {n} {ĐVT} {sản phẩm} lô {lô}?"; "Sau khi duyệt" "Tồn chưa giảm — giảm khi xác nhận đã tiêu hủy"; từ chối bắt buộc lý do; "Chỉ chủ cửa hàng duyệt tiêu hủy."; "Không có đề nghị chờ duyệt"; chủ cửa hàng lập thì gửi rồi tự duyệt; "Đã duyệt — chờ xử lý thực tế" + "Tồn chưa giảm. Tiêu hủy xong thì chụp ảnh hoặc biên bản và xác nhận."; ai xác nhận: bất kỳ nhân viên có quyền (lối từ 036 chip "Tiêu hủy") | ✅ 2026-10-26 (v5.15.0) |
| 10 | SCR-040 / SCR-041 | chữ / quyền | **Tiền ở BJ-10:** chủ cửa hàng / người duyệt thấy "Giá trị ghi giảm dự kiến" (đề nghị, duyệt) và "Giá trị ghi giảm" (kết quả); nhân viên không có số tiền trong DOM (`FINANCIAL_MASKED`); bỏ dòng "Căn cứ giá: Giá vốn hiện hành" | ✅ 2026-10-26 (v5.15.0) |
| 10 | SCR-041 | trạng thái / chữ | **Thêm trạng thái `REJECTED`** (tách khỏi `REJECTED_EXECUTION`): "Đã từ chối đề nghị tiêu hủy" + "Lý do: {lý do}" + "Tồn kho không thay đổi."; K4 "Đã ghi nhận tiêu hủy": "Còn lại ở lô" (thay "Tồn vật lý còn lại"), "Người xác nhận", "Xác nhận lúc"; `UNKNOWN` / `COMMIT_UNKNOWN` theo K3 (nghiệp vụ "Tiêu hủy hàng") | ✅ 2026-10-26 (v5.15.0) |
| 10 | UC-10-02, SCR-040 mục 6 | nghiệp vụ | Phần BJ-10 của dòng "mọi BJ theo K2": người duyệt tiêu hủy = `is_owner` / `store_owner`, chủ lập gửi rồi tự duyệt (UC-10 BR-03 đã ghi); SCR-040 mục 6 ghi lại | ⬜ (chốt đặc tả 7.3) |
| 09 | UC-09-02, SCR-036…041 | nghiệp vụ / tài liệu | UC-09-02 ghi người duyệt = `is_owner` / `store_owner`, chủ cửa hàng lập thì gửi rồi tự duyệt (như K2); mục "màn sử dụng" của UC-09 / UC-07-01 / UC-10-01 theo tên màn mới | ⬜ (chốt đặc tả 7.3) |
| 07 / 09 / 10 | SCR-036, 038, 040, 041 | chữ | Review chặng 4 (v5.15.1): 041 BJ-07 **"Yêu cầu tiếp theo"** (rút từ "Chuẩn bị yêu cầu tiếp theo"); 040 xác nhận "Ảnh hoặc biên bản sau khi tiêu hủy" / **"Lưu cùng ghi nhận tiêu hủy" (mới)**; 038 "Sau khi đổi" là khối thường, "Cần chú ý" chỉ khi có dòng cảnh báo | ✅ 2026-10-25 (v5.15.1) |

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
| So với mốc trước Giai đoạn 1 (`tools/.golden-base` 911 ca, `tools/.golden-a5-base` 960 ca, chung tên) | **Chữ khớp 100%.** Hình: mọi ca lệch 4 góc khung thiết bị (A11); 23 ca trạng thái lệch thật — 5 do A8, 18 do A11 (+ các ca `SC_`* đi qua cùng màn) |
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

**R1. CSS mất ở A11 (chặn).** ✅ 2026-10-19 (phiên review) — góc khung: luật `.device-preview` bị đảo thứ tự (bản bo 32px thắng bản 34px) + một bản sao bo 32px trong `screens.css`; đặt lại thứ tự `styles.css` gốc (base → is-wide → v0.2.3 34px → khung chuẩn 402×874 → `:not(.is-wide)`), xoá bản sao. Khối "Review cards" chèn lại đúng chỗ. Không cần bước 3: `UIF-13_SCR-089_`* cũng hết lệch. Kết quả: **0 khác biệt** với cả bốn mốc R0. Hướng gốc:

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

**R2. Footer duyệt và dòng "Điều chỉnh" của A8 (chặn).** ✅ 2026-10-19 (phiên review, theo yêu cầu người dùng) — 5 ca khớp `tools/.golden-a5-base`; so với trước khi sửa chỉ khác các ca SCR-050 / 051 / 070 (+ `SC_bj11_`* / `SC_bj12_`* / `SC_entry_UIF-11/12_approver` đi qua), chữ không đổi, 0 lỗi JS.

1. `shared-control.js` `ac310ApprovalFooter`: viết sẵn kết quả của `normalizeDualFooters` (`v361`) như `bj02.js` (SCR-011) / `cap01.js` (SCR-064) đã làm — footer thêm lớp `v361-dual-footer v361-dual-footer--danger`, `data-ds-prop-layout="Dual" data-ds-prop-tone="Danger"`; nút "Từ chối" (đứng trước nút chính) thêm `data-ds-prop-tone="VComponentTone.danger" data-ds-profile="button.destructiveSecondary"`. Nguồn chuẩn: `git show HEAD:specs/themes/theme-07/03.design/prototype/html/v361-footer-action-correction.js`. Dùng ở `bj11.js` (SCR-051) và `bj12.js` (SCR-070).
2. `bj11.js` `bj11KeyValueSurface`: dòng có cờ nhấn mạnh (`r[2]`) dựng bằng `ds24KeyValueRow(label, value, true)` (lớp `ds24-key-value-row--emphasis`, `data-ds-prop-state="Emphasis"`) như trước A8; chỉ thêm `v470-kv--attention` nếu mốc gốc có (mở `UIF-11_SCR-051_READY.png` trong `tools/.golden-a5-base`: "Điều chỉnh −2 hộp" đậm đen, không màu cảnh báo). Giữ dấu trừ U+2212 (mốc gốc SCR-051 có `−2`; SCR-050 có `-2` — đối chiếu `.txt`).
3. Đích: `UIF-11_SCR-050_READY`, `_VALIDATION_ERROR`, `SCR-051_READY`, `_VALIDATION_ERROR`, `UIF-12_SCR-070_READY` khớp `tools/.golden-a5-base`.

**R3. Một định nghĩa (A5, A6).** ✅ 2026-10-19 (phiên review) — cách làm thực tế: bản thắng nằm trong IIFE `v395`/`v397`–`v399` và cần biến cục bộ của khối, nên **xoá 37 bản chết** (tree-sitter, đúng ranh giới hàm) và khai báo `let tên…;` một dòng ở chỗ bản chết đầu tiên (không còn biến toàn cục ngầm); `val14CreateRun` gộp: `bj14ApplyPolicy` / `BJ14_COST_POLICY` lên cấp file, bản `v399` `return bj14ApplyPolicy(run)`, bỏ `baseCreate14`; bỏ export thừa `window.val03ApplySourceUpdate` / `val13ApplySourceUpdate` / `val13V398` (bj14 gọi `val13Engine`). Đoạn đếm rỗng; golden 1348 ca khớp hoàn toàn bản sau R2; 0 lỗi JS. Kiểm `grep "=\s*function"` của plan A5/A6 vẫn ra các phép gán trong IIFE — đó là định nghĩa duy nhất, dùng đoạn đếm dưới đây làm tiêu chí. Hướng gốc (giữ để đối chiếu): Với từng hàm trong danh sách ở review A5 / A6: giữ **bản cuối** (bản đang chạy), đổi `name=function(...)` thành `function name(...)` đặt ở chỗ bản đầu, xoá bản đầu. `val14CreateRun`: gộp ba bản thành một = thân bản `v399` (dòng 93) + `applyPolicy(r)` trước `return`; xoá `baseCreate14`. Cẩn thận hàm được **chụp tham chiếu lúc nạp** (`const x = tênHàm`) — grep `=\s*val0\|=\s*val1\|=\s*io07` trước khi xoá. `window.val13V398` → `bj14.js` gọi thẳng `val13Engine.methodEligible`. Kiểm: đoạn đếm ở cuối mục này rỗng; golden khớp `tools/.golden-a12-r1` (sau R1–R2) hoàn toàn.

```bash
node -e 'const fs=require("fs");for(const f of fs.readdirSync("app")){const s=fs.readFileSync("app/"+f,"utf8"),m={};for(const r of s.matchAll(/(?:^|[\s;{}(])function\s+([A-Za-z0-9_$]+)\s*\(|(?:^|[\s;{}])([A-Za-z0-9_$]+)\s*=\s*function\b/gm)){const n=r[1]||r[2];m[n]=(m[n]||0)+1}const d=Object.keys(m).filter(k=>m[k]>1);if(d.length)console.log(f,d.join(" "))}'
```

**R4. Chú thích.** ✅ 2026-10-19. `core.js`: xoá dòng 13 `/* ===== app.js ===== */`, các dòng `// v1.7.0 …`, `// v1.8.0 …` (2 chỗ), `/* flowScreen assigns after framework */`; dòng 7 bỏ `simplifyNormalBanners`. Đầu `bj01.js` / `bj04.js`: sửa câu cụt "… màn dựng"; `bj05/06/07.js`: bỏ thụt   `*/`; `cap01.js`: bỏ "Còn ở core.js (gỡ dần ở A11): fallback-exit". `bj10.js`: bỏ lớp chuyển tiếp `render0xxBJ10`.

**R5. Công cụ và thư mục mốc.** ✅ 2026-10-19 — mốc `tools/.golden-phase1` (1348 ca, 0 lỗi JS, 0 khác biệt với bốn mốc gốc) chụp **trước** khi xoá 32 thư mục mốc tạm; README prototype trỏ mốc mới. `tools/golden.mjs`: bỏ nhánh `||window.__VET45_V350__` / `__VET45_V3101__`. Sau khi A12 đạt: chụp mốc Giai đoạn 2 `tools/.golden-phase1`; xoá mọi `tools/.golden-a`*, `tools/.golden-{base,check,sc-a,sc-b,bj02-sc}`, `tools/.full-`*, `tools/.usage-*`, và `.golden-*` ở gốc `html/`. `tools/.gitignore` thêm `.full*/` và `.usage*/`.

**R6. Ghi lại và commit.** ✅ 2026-10-19 — CHANGELOG `[5.3.1]`, `manifest.json` / badge 5.3.1, `sync-registry.py`; commit theo yêu cầu người dùng. CHANGELOG `[5.3.1] — T7-P A12: sửa sau review Giai đoạn 1` (R1 CSS trả lại, R2 footer / dòng nhấn mạnh, R3 một định nghĩa); sửa mục 5.3.0 bỏ `simplifyNormalBanners` khỏi danh sách khung. `manifest.json` 5.3.1; `python3 tools/sync-registry.py`. **Commit gồm cả cấu trúc T7-P0 + A11 chưa từng commit**: 214 file legacy đã xoá, `styles/`, `harness/`, `data/`, `index.html` — kiểm bằng `git stash -u && git status` không còn gì rồi mở `index.html` từ một bản `git worktree` sạch. `detect_changes()` trước commit. Commit: `refactor(prototype): T7-P A11+A12 — framework cleanup, harness split, post-review fixes`.

**R7. Tách lại cụm giá trị theo BJ (A5).** ✅ 2026-10-19 (phiên review, theo yêu cầu người dùng) — helper giao diện của hai khối → `VAL_UI_430` / `VAL_UI_461` trong `shared-valuation.js` (giữ nguyên thân; 5 helper chỉ BJ-03 dùng ở lại `bj03.js`); phần dựng + listener tách thành khối riêng theo BJ: `bj03.js` dựng SCR-014/015/016/017/019, `bj13.js` SCR-085…089, `bj14.js` SCR-072…077. Xoá mã chết lộ ra: nhánh listener `data-v430-val14-`* (không màn nào phát, tham chiếu biến không tồn tại), `VALUATION_FLOWS`, `SCREEN_ALIAS`, `if(typeof renderers==='undefined')`, `val03Commit = val03Commit430` lặp. Gộp nốt định nghĩa trùng dạng bí danh mà đoạn đếm R3 bỏ sót: `val03EvidenceState` / `Source` / `GroupSelectedQty` / `Calc`, `val03Commit` (bản `v397` chết), `val13SelectedTargets` / `Preview` / `PreviewHashOf` / `CanOpenAllocation` / `CanPreview`. Golden 1348 ca khớp hoàn toàn bản sau R3; 0 lỗi JS. Mô tả lúc phát hiện (giữ để đối chiếu): Phát hiện khi làm R3: `bj03.js` chứa khối `v430` dựng SCR-014 (BJ-03) **và SCR-085 (BJ-13)** + listener `data-v430-val14-`* (BJ-14); `bj14.js` chứa khối `v461` dựng SCR-015/017/019 (BJ-03), **SCR-086/089 (BJ-13)** và SCR-072/074/077 (BJ-14); `bj13.js` chỉ có fixture + helper. Mục tiêu A5 "BJ-NN → `app/bjNN.js`" chưa đạt. Hướng: chuyển hàm dựng + listener theo màn về đúng file (helper cục bộ dùng chung của `v430` / `v461` → `shared-valuation.js`), golden khớp hoàn toàn. Ước lượng ~0,5–1 ngày. Có thể dời sang bước C của Đợt giá trị ở Giai đoạn 2 (khi BJ-03/13/14 được viết lại) nếu chấp nhận.

Xong A12: plan tổng mục 14 đổi Review A5 / A6 / A8 / A11 sang ✅ và ghi "Hết Giai đoạn 1".

### 14.3 Gói H1 — khung web cho harness

Chuẩn bị Giai đoạn 2. Plan ✅ (duyệt 2026-10-21) | Làm ✅ 2026-10-21 (chưa commit) | Review ✅ 2026-10-21. Ước lượng **~1 ngày, 1 commit**. Làm **trước brief / bước C của BJ-12** (BJ đầu tiên). Người làm: bạn; review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/`. Server: `python3 -m http.server 8765 --bind 127.0.0.1 &`.

**Mục tiêu.** Harness có thêm khung **Web · 1280 × 800** cạnh khung **Mobile · 402 × 874**: cửa sổ máy tính có thanh bên trái của app (đúng khung đã chốt ở [LUONG-UNG-DUNG 1.1](../../../02-yeu-cau/LUONG-UNG-DUNG.md) và [W-1](../W/W-1-khung-web.md) mục 3.3), nội dung giữa rộng tối đa 1120px. Golden chụp được cả hai khung. **Không đổi màn nào**: màn chưa thiết kế lại cho web hiện bố cục iPhone trong vùng nội dung; mọi ca iPhone hiện có phải **khớp hoàn toàn** `tools/.golden-phase1`.

**Hiện trạng (đo 2026-10-20).**

| Mục                        | Hiện trạng                                                                                                                                                                                                                                                                                                                                                                               |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Nút chọn khung             | `index.html` dòng ~57: chỉ một nút `data-viewport="mobile"` "Mobile · 402 × 874"                                                                                                                                                                                                                                                                                                         |
| Biến khung                 | `app/core.js:69` `let viewport = initialParams.get("viewport") === "wide" ? "wide" : "mobile"`; `syncReviewUrl()` (`core.js:476`) ghi `viewport` lên URL; `harness/workbench.js:406–418` đổi lớp `device-preview is-${viewport}`                                                                                                                                                         |
| Chế độ `is-wide` cũ        | Không còn nút bật, golden không dùng; còn **25 chỗ** (`grep -n "is-wide" app/*.js styles/*.css harness/`*): luật `.device-preview.is-wide …` trong `styles/components.css` (dòng ~90, 163–183, 910–929, 943, 969, 1213–1214) và **6 luật** `:not(.is-wide)` định khung iPhone 418×890 (`components.css:110`, `:2733`; `screens.css:2797`, `:2892`, `:3392`, `:3398`); `workbench.js:430` |
| Thu khung cho vừa sân khấu | `fitReviewDeviceToViewport()` (`workbench.js:426`) chỉ tính cho khung iPhone (418 × 890)                                                                                                                                                                                                                                                                                                 |
| Khung app                  | `app/hub.js:75` `bottomNav()` dựng thanh dưới 5 tab trong `shell()`; màn của luồng (BJ) dựng thẳng vào `#app-screen`, có `statusBar` iOS                                                                                                                                                                                                                                                 |
| Golden                     | `tools/golden.mjs`: nhóm ca theo luồng (dòng ~81–84: `?uif=…&screen=…`), `HUB_home`, kịch bản `SC_*` (dòng ~312); cửa sổ chụp 1600 × 1100 (`setDeviceMetricsOverride`, dòng ~405, ~501); ảnh = vùng `#device-preview`                                                                                                                                                                    |
| Khai báo                   | `workbench.js:449` `window.__VET45_PROTOTYPE__`: `productKind: "mobile_app"`, `devicePresets` chỉ `iphone-402`; phiên bản 5.3.1 ở `workbench.js:451`, `manifest.json`, badge `index.html:28`                                                                                                                                                                                             |

**H0. Mốc.** Chụp `node tools/golden.mjs capture tools/.golden-h1-base`; so với `tools/.golden-phase1` phải "Khớp hoàn toàn (1348 ca)". Không chụp lại mốc này giữa gói.

**H1. Dọn** `is-wide` **(không đổi hình).**

1. `styles/components.css`, `styles/screens.css`: xoá mọi luật có selector `.device-preview.is-wide` (kể cả trong `@media`); đổi 6 luật `.device-preview:not(.is-wide)` thành `.device-preview.is-mobile` (giữ nguyên thân luật và vị trí). Sửa chú thích `components.css:76` cho khớp (bỏ "is-wide").
2. `app/core.js:69` → `let viewport = initialParams.get("viewport") === "web" ? "web" : "mobile";` (URL cũ `viewport=wide` rơi về mobile).
3. `harness/workbench.js:430`: bỏ điều kiện `is-wide` (H5 viết lại hàm).
4. Kiểm: `grep -rn "is-wide" app styles harness index.html` rỗng; golden mobile khớp hoàn toàn `.golden-h1-base`.

**H2. Nút và khai báo.**

1. `index.html`: thêm `<button class="viewport-button" data-viewport="web" type="button">Web · 1280 × 800</button>` sau nút Mobile.
2. `workbench.js` `__VET45_PROTOTYPE__`: `productKind: "app"`; `devicePresets` thêm `{ id: "web-1280", kind: "web", width: 1280, height: 800 }`.
3. Bấm nút đổi khung và tải lại trang với `&viewport=web` → vào đúng khung.

**H3. Khung web (CSS).** Trong `styles/components.css`, ngay sau khối khung iPhone (sau luật `.device-preview.is-mobile` đầu tiên, dòng ~110), thêm khối `/* Khung web 1280×800 (H1) */`:

- `.device-preview.is-web`: `width:1280px; height:800px; min-height:800px; border:1px solid var(--vet45-v2-neutral-300); border-radius:8px;` (không viền dày 8px như iPhone), `display:grid; grid-template-columns:240px minmax(0,1fr);`, nền `--vet45-v2-neutral-100`.
- `.device-preview.is-web > .app-screen`: cuộn trong vùng của nó; nội dung con căn giữa, `max-width:1120px`.
- `.device-preview.is-web .app-statusbar { display:none; }`, `.device-preview.is-web .t7-app-bottom-nav { display:none; }` (thanh bên thay thanh dưới).
- Mọi giá trị dùng token `--vet45-v2-*`; tra `styles/tokens.css`, không gõ tay màu.

**H4. Thanh bên giả (**`hub.js`**).**

1. `index.html`: trong `#device-preview`, trước `#app-screen`, thêm `<nav id="web-sidebar" class="t7-web-sidebar" aria-label="Điều hướng chính" hidden></nav>`; CSS: chỉ hiện khi `.device-preview.is-web` (`.device-preview:not(.is-web) .t7-web-sidebar { display:none }`).
2. `app/hub.js`: thêm `webSidebar()` dựng một lần khi nạp và mỗi khi `render()` (giống `bottomNav()`), chữ lấy đúng của app (W-1 mục 3.3):
   - đầu: tên tổ chức trong fixture của Hub;
   - 5 mục chính "Trang chủ · Đơn hàng · Sản phẩm · Đối tác · Thêm" (chỉ "Thêm" bật, `data-theme-sidebar-route="more"` như `bottomNav()`);
   - mục con của "Thêm": "Kho" (đang chọn; bấm → Home Kho bằng `data-theme-sidebar-route="inventory"`, cùng route cột trái của harness dùng ở `hub.js:247`; handler sẵn có ở `hub.js:367`), "Giá riêng / Nhớ giá", "Người dùng & vai trò", "Tài khoản của tôi", "Thiết lập" (tắt);
   - cuối: "Đăng xuất" (tắt).
     Mục chọn tô `--vet45-v2-primary-*` như tab đang chọn của thanh dưới; mục tắt mờ như `bottomNav()`; `aria-current="page"` ở "Kho".
3. Không sửa file `bjNN.js` nào.

**H5. Thu khung cho vừa sân khấu.** `fitReviewDeviceToViewport()`: khung iPhone giữ nguyên công thức (`890` / `418`); khung web: `scale = min(1, availableHeight / 802, availableWidth / 1282)`. Cửa sổ `≤ 840` giữ scale 1 như cũ.

**H6. Golden hai khung.** `tools/golden.mjs`:

1. Biến môi trường `DEVICE` (`mobile` mặc định, hoặc `web`). Với `web`: mọi URL nhóm thêm `&viewport=web`; tên ca thêm hậu tố `@web`; `setDeviceMetricsOverride` cửa sổ **2400 × 1300** để khung web không bị thu (scale 1); chỉ chụp nhóm màn × trạng thái + `HUB_home`, **bỏ kịch bản** `SC_`* (thêm dần khi BJ có bản web).
2. `DEVICE` để trống → hành vi như cũ, tên ca không đổi (mốc cũ còn so được).
3. `README.md` (html): thêm `DEVICE=web node tools/golden.mjs capture tools/.golden-web-now` và cách so.
4. Kiểm: `DEVICE=web … capture tools/.golden-web-base` chạy hết, 0 lỗi JS, ảnh 1280 × 800 (+ viền); mobile `capture tools/.golden-now` → `compare tools/.golden-h1-base tools/.golden-now` "Khớp hoàn toàn". Mốc `tools/.golden-web-base` là mốc web cho BJ-12 (mục 4.5).

**H7. Ghi lại.** CHANGELOG `[5.4.0] — H1: harness khung web 1280×800` (H1–H6, không đổi màn); phiên bản 5.4.0 ở `manifest.json`, `workbench.js` `__VET45_PROTOTYPE__.version`, badge `index.html:28` "v5.4.0 · H1 khung web"; `python3 tools/sync-registry.py`; mục 14 (dòng "Khung web cho harness") và mục 8.2 chặng 0 đánh ✅.

**Kiểm cả gói.**

| Kiểm | Đạt khi |
|---|---|
| Golden mobile | Khớp hoàn toàn `tools/.golden-phase1` (1348 ca), 0 lỗi JS |
| Golden web | `DEVICE=web` chụp hết, 0 lỗi JS |
| Bấm thử trên khung web | Mọi màn × trạng thái + Hub, bấm lần lượt từng nút (như các gói trước): 0 lỗi JS |
| Mắt | Khung web: thanh bên trái, "Kho" được chọn, không thanh dưới, không thanh trạng thái iOS, nội dung không tràn ngang; khung mobile như cũ |
| `node --check app/*.js harness/*.js` | Sạch |

**Không làm:** bố cục web của màn nào (bước C của từng BJ, khuôn K7); thanh bên thật trong Flutter (W-1).

**Ghi chú khi làm:** (2026-10-21)

- **Kết quả kiểm:** `tools/.golden-h1-base` (chụp trước khi sửa) = `.golden-phase1` "Khớp hoàn toàn (1348 ca)"; sau H1–H7, golden mobile khớp cả hai mốc, 0 lỗi JS. `DEVICE=web` chụp 555 ca, 0 lỗi JS, ảnh 1280 × 800; mốc `tools/.golden-web-base`, chụp lại lần hai khớp hoàn toàn. Bấm thử khung web: 497 màn × trạng thái, 2250 lần bấm (mọi nút trong `#app-screen` và `#web-sidebar`), 0 lỗi JS. `grep -rn "is-wide" app styles harness index.html` rỗng; `node --check` sạch. Thử tay ở cửa sổ 1440 × 900: khung web thu còn ~0,64 và nằm giữa sân khấu; đổi nút Mobile ↔ Web ẩn / hiện thanh bên, URL ghi `viewport=…`.
- **Lệch / bổ sung so với plan:**
  1. *Màn BJ trong khung web.* Plan chỉ nói "nội dung giữa tối đa 1120px"; thực tế mỗi UIF đặt cứng `width:402px; height:874px` cho `.figma-calibrated-shell`, nên chỉ đặt `max-width` thì màn BJ lệch trái và chân trang (nút chính) bị đẩy ra dưới khung. Thêm vào H3: `.device-preview.is-web > .app-screen > .v-page-scaffold` cao 100% khung (`!important` để thắng luật theo UIF); màn Hub / Thêm (`.t7-integrated-shell`) rộng tới 1120px, màn BJ giữ cột 402px ở giữa. Đã kiểm cả 497 màn × trạng thái: không tràn ngang.
  2. *Sân khấu hẹp hơn 1280px.* Cột lưới của `.stage-canvas` giãn theo khung 1280 làm khung thu lệch phải; thêm `.stage-canvas:has(.device-preview.is-web) { grid-template-columns: minmax(0,1fr) }` trong H3. Đổi khung bằng nút gọi lại `fitReviewDeviceToViewport()` ngay (H5).
  3. *Tên tổ chức ở thanh bên.* Fixture của Hub không có tên tổ chức nào; thêm hằng `ORG_NAME = 'VET45 Demo'` trong `hub.js` (đổi được khi BJ-12 cần tên thật).
  4. *Mục con "Kho".* Bấm "Kho" / "Thêm" chỉ chạy ở chế độ "Toàn Theme 7" (handler `data-theme-sidebar-route` sẵn có không chạy ở chế độ Theo BJ / UIF), giống nút "Thêm" của thanh dưới.
  5. *Không có biểu tượng cho mục con và "Đăng xuất"* (plan không nêu; W-1 3.3 không nêu).
  6. `prototype.manifest.json` (còn ghi 5.0.0, `mobile_app`) không đụng — không nằm trong H7.
- Việc chưa làm: không chạy `detect_changes()` của GitNexus (công cụ MCP không có trong phiên này); prototype chỉ là HTML / JS / CSS tĩnh, không phải code ERP được lập chỉ mục. Chưa commit — chờ yêu cầu.

**Review:** (2026-10-21, phiên review) — **đạt**, chưa commit.

| Kiểm (chạy lại) | Kết quả |
|---|---|
| Golden mobile | 1348 ca, 0 lỗi JS; "Khớp hoàn toàn" với `tools/.golden-phase1` |
| Golden web | `DEVICE=web` 555 ca (màn × trạng thái + `HUB_home`, không `SC_*`), 0 lỗi JS; "Khớp hoàn toàn" với `tools/.golden-web-base` |
| `node --check app/*.js harness/*.js` | Sạch |
| `is-wide` | `grep` rỗng; 6 luật `:not(.is-wide)` → `.is-mobile` giữ nguyên thân luật |
| Token | Mọi `--vet45-v2-*` mới dùng đều có trong `styles/tokens.css` |
| Registry | `sync-registry.py` chạy lại không đổi thêm; `shasum -c` toàn bộ OK |
| Diff | Đúng phạm vi H0–H7; không file `bjNN.js` nào bị sửa |

Lệch 1–6 trong ghi chú: chấp nhận. Lệch 1 (màn BJ giữ cột 402px ở giữa khung web, `!important` để thắng luật theo UIF) đúng tinh thần "màn chưa thiết kế lại hiện bố cục iPhone"; bước C của từng BJ bỏ luật này cho màn của mình khi dựng K7.

Góp ý nhỏ (không chặn, sửa khi tiện):

1. `index.html`: thuộc tính `hidden` trên `#web-sidebar` không có tác dụng (`.t7-web-sidebar { display:flex }` thắng); việc ẩn do luật `.device-preview:not(.is-web) .t7-web-sidebar` làm. Bỏ `hidden` cho khỏi hiểu nhầm.
2. `components.css` khối `.t7-web-sidebar`: hai chỗ `font: … Inter, system-ui, sans-serif` → dùng `var(--vet45-v2-font-sans)`.
3. `prototype.manifest.json` còn `5.0.0` / `mobile_app` (ngoài H7) — để mục 7.3 (chốt đặc tả) cập nhật.

### Giai đoạn 2 — thiết kế lại (theo chặng, mục 8.2)

| Việc                                                                                                           | B. Brief           | C. Dựng                    | D. Kiểm                                             | E. Ghi lại                                                                                                                                                                                                                                |
| -------------------------------------------------------------------------------------------------------------- | ------------------ | -------------------------- | --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Dọn tài liệu 7.1 ([plan](T7-P-doc-don-tai-lieu.md))                                                            | —                  | ✅ `684a2f7b6`, `fc93c752e` | ✅ review 2026-10-20                                 | —                                                                                                                                                                                                                                         |
| Gói H1 — khung web cho harness, chuẩn bị trước BJ-12 · ✅ [plan](#143-gói-h1--khung-web-cho-harness) (mục 14.3) | —                  | ✅ 2026-10-21               | ✅ review 2026-10-21                                 | ✅                                                                                                                                                                                                                                         |
| **Chặng 1 — Mở kho** (làm theo thứ tự BJ-12 → BJ-01 → CAP-01)                                                  |                    |                            |                                                     | `SC_journey_1` ✅ 2026-10-22 — review đạt; R1–R4 (v5.7.1) + R5 audit (v5.7.2) xong, chưa commit ([plan CAP-01 mục 10](T7-P-cap01-chinh-sach-ton.md#10-review)) — [plan CAP-01 mục 3.5](T7-P-cap01-chinh-sach-ton.md)                       |
| BJ-12 ([plan](T7-P-bj12-ton-dau-ky.md))                                                                        | ✅ duyệt 2026-10-21 | ✅ 2026-10-21 (v5.5.0)      | ✅ 2026-10-21 (ghi chú mục 10 của plan)              | ✅ 2026-10-22 — R1–R4 (v5.7.1) + R5 audit (v5.7.2)                                                                                                                                                                                         |
| BJ-01 ([plan](T7-P-bj01-ton-kho.md), rà lại 2026-10-21)                                                        | ✅ duyệt 2026-10-16 | ✅ 2026-10-21 (v5.6.0)      | ✅ 2026-10-21 (ghi chú mục 10 của plan)              | ✅ 2026-10-22 — R1–R4 (v5.7.1) + R5 audit (v5.7.2)                                                                                                                                                                                         |
| CAP-01 ([plan](T7-P-cap01-chinh-sach-ton.md))                                                                  | ✅ duyệt 2026-10-21 | ✅ 2026-10-21 (v5.7.0)      | ✅ 2026-10-21 (ghi chú mục 8 của plan)               | ✅ 2026-10-22 — R1–R4 (v5.7.1) + R5 audit (v5.7.2)                                                                                                                                                                                         |
| **Chặng 2 — Nhập hàng**                                                                                        |                    |                            |                                                     | `SC_journey_2` ✅ 2026-10-24 — 0 lỗi ở cả hai khung (v5.10.0, chưa commit, chưa review) — [plan BJ-13 mục 3.6](T7-P-bj13-dieu-chinh-gia-tri.md)                                                                                            |
| BJ-02 ([plan](T7-P-bj02-nhan-hang.md))                                                                         | ✅ duyệt 2026-10-21 | ✅ 2026-10-22 (v5.8.0)      | ✅ 2026-10-22 (ghi chú mục 11 của plan; chưa review) | ✅ 2026-10-22                                                                                                                                                                                                                              |
| BJ-03 ([plan](T7-P-bj03-gia-nhap.md))                                                                          | ✅ duyệt 2026-10-21 | ✅ 2026-10-22 (v5.9.0)      | ✅ 2026-10-22 (ghi chú mục 8 của plan; chưa review)  | ✅ 2026-10-22                                                                                                                                                                                                                              |
| BJ-13 ([plan](T7-P-bj13-dieu-chinh-gia-tri.md))                                                                | ✅ duyệt 2026-10-21 | ✅ 2026-10-24 (v5.10.0)     | ✅ 2026-10-24 (ghi chú mục 8 của plan; chưa review)  | ✅ 2026-10-24                                                                                                                                                                                                                              |
| **Chặng 3 — Bán và giao**                                                                                      |                    |                            |                                                     | `SC_journey_3` ✅ 2026-10-24 — 0 lỗi ở cả hai khung (v5.12.0, chưa commit); review **đạt** 2026-10-25 sau R1–R3 (v5.12.1) ([plan BJ-06 mục 12](T7-P-bj06-hang-khach-tra.md#12-review)) — [plan BJ-06 mục 5.4](T7-P-bj06-hang-khach-tra.md) |
| BJ-04 / 05 ([plan](T7-P-bj04-bj05-lay-hang.md))                                                                | ✅ duyệt 2026-10-24 | ✅ 2026-10-24 (v5.11.0)     | ✅ 2026-10-24 (ghi chú mục 11 của plan; chưa review) | ✅ 2026-10-24                                                                                                                                                                                                                              |
| BJ-06 ([plan](T7-P-bj06-hang-khach-tra.md))                                                                    | ✅ duyệt 2026-10-24 | ✅ 2026-10-24 (v5.12.0)     | ✅ 2026-10-24 (ghi chú mục 8 của plan; chưa review)  | ✅ 2026-10-24                                                                                                                                                                                                                              |
| **Chặng 4 — Hàng có vấn đề**                                                                                   |                    |                            |                                                     | `SC_journey_4` ✅ 2026-10-26 — 0 lỗi ở cả hai khung (v5.15.0, chưa commit); review **đạt** 2026-10-25 sau R1–R3 (v5.15.1) ([plan BJ-07 + BJ-10 mục 14](T7-P-bj07-bj10-tra-ncc-tieu-huy.md#14-review)) — [plan BJ-07 + BJ-10 mục 6.4](T7-P-bj07-bj10-tra-ncc-tieu-huy.md)                                                                                                                                                      |
| BJ-09 ([plan](T7-P-bj09-tinh-trang-hang.md))                                                                   | ✅ duyệt 2026-10-25     | ✅ 2026-10-25 (v5.13.0)| ✅ 2026-10-25 (ghi chú mục 9 của plan; chưa review)  | ✅ 2026-10-25                                                                                                                                                                                                                              |
| BJ-07 ([plan](T7-P-bj07-bj10-tra-ncc-tieu-huy.md))                                                             | ✅ duyệt 2026-10-25     | ✅ 2026-10-26 (v5.14.0)                     | ✅ 2026-10-26 (ghi chú mục 9 của plan; chưa review)                                                   | ✅ 2026-10-26                                                                                                                                                                                                                                         |
| BJ-10 ([plan](T7-P-bj07-bj10-tra-ncc-tieu-huy.md))                                                             | ✅ duyệt 2026-10-25     | ✅ 2026-10-26 (v5.15.0)                     | ✅ 2026-10-26 (ghi chú mục 9 của plan; chưa review)                                                   | ✅ 2026-10-26                                                                                                                                                                                                                                         |
| **Chặng 5 — Kiểm kê và sửa sai**                                                                               |                    |                            |                                                     | `SC_journey_5` ⬜ — [plan BJ-16 + BJ-17 mục 6.4](T7-P-bj16-bj17-doi-soat.md)                                                                                                                                                              |
| BJ-08 ([plan](T7-P-bj08-kiem-ke.md))                                                                           | ✅ duyệt 2026-10-25 | ⬜                          | ⬜                                                   | ⬜                                                                                                                                                                                                                                         |
| BJ-11 ([plan](T7-P-bj11-sua-sai.md))                                                                           | ✅ duyệt 2026-10-25 | ⬜                          | ⬜                                                   | ⬜                                                                                                                                                                                                                                         |
| BJ-16 / 17 ([plan](T7-P-bj16-bj17-doi-soat.md))                                                                | ✅ duyệt 2026-10-25 | ⬜                          | ⬜                                                   | ⬜                                                                                                                                                                                                                                         |
| **Chặng 6 — Chốt kỳ**                                                                                          |                    |                            |                                                     | `SC_journey_6` ⬜                                                                                                                                                                                                                          |
| BJ-14                                                                                                          | ⬜                  | ⬜                          | ⬜                                                   | ⬜                                                                                                                                                                                                                                         |
| BJ-15                                                                                                          | ⬜                  | ⬜                          | ⬜                                                   | ⬜                                                                                                                                                                                                                                         |

## 15. Câu hỏi còn mở

Không còn câu hỏi mở (2026-10-20). Câu đã trả lời xoá khỏi đây, quyết định ghi vào mục liên quan: quy tắc duyệt — mục 2 + 13; quét mã trong prototype — plan BJ-01; khung web — LUONG-UNG-DUNG 1.1; lối vào hàng có vấn đề (danh sách chung "Hàng cần xử lý") — mục 9 chặng 4. Câu mới phát sinh ở bước B ghi vào đây.
