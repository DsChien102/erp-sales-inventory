# Kế hoạch thực hiện refactor

> Đi kèm [SCOPE.md](SCOPE.md) (phạm vi và các quyết định đã chốt). File này trả lời câu hỏi: **làm gì, theo thứ tự nào, xong thì kiểm tra thế nào.**
> Branch làm việc: `refactor/simple-arch` (tách từ `feature/theme8`). Ngày lập: 2026-10-06.
> **Cập nhật 2026-11-20:** `refactor/simple-arch` đã merge vào `dev` (PR #1, `207bde8ef`); làm tiếp trên `dev`. `main` mới có "Initial Commit" — merge `dev` → `main` + tag `v2.0.0` là việc 10.6.
> Commit `4d14f189c` (2026-11-20) xoá file plan AI-2…AI-5 và T6-2a/2b/2c, trong đó AI-2…5 và T6-2c **chưa đóng review**; việc còn mở chép vào dòng tương ứng bên dưới, nội dung đầy đủ đọc bằng `git show 4d14f189c^:docs/refactor/plans/<AI|T6>/<tệp>.md`.

## Tổng quan

```text
Chuẩn bị ─▶ Nền core/ ─▶ Theme 1 IAM ─▶ Theme 1 làm gọn IAM ─▶ Đợt kiểm IAM ─▶ Theme 3 Partner ─▶ Theme 2 Catalog ─▶ Theme 4 Pricing ─▶ Theme 5 Sales ─▶ Theme 8 E-invoice ─▶ Theme 7 Kho & Giá vốn (gồm nối kho Sales) ─▶ Tích hợp AI ─▶ Theme 6 Công nợ ─▶ Dọn dẹp ─▶ Báo cáo

Theme 7 — làm sau Theme 8 (chốt 2026-11-03); việc Theme 7 đã làm trước đó (T7-0…, prototype T7-P) giữ nguyên
Web cho app (W-1 khung, W-2 Theme 1): hoãn, sau Theme 7 prototype; W-1 trước màn Flutter web đầu tiên
```

**Đặt tên theo theme** (2026-10-14): mỗi mục nghiệp vụ mang số theme TH-0x của `docs/requirements`; mục không thuộc theme nào (Chuẩn bị, Nền core, Dọn dẹp, Báo cáo) giữ tên riêng. **Thứ tự trong file = thứ tự làm.**

**Rút gọn Theme 7 2026-11-09 (người dùng chốt):** từ 17 BJ + CAP-01 (70 màn) còn 10 plan G5 theo luồng demo chính, bỏ duyệt K2 / xác minh K3, **bỏ tồn đầu kỳ** (kho bắt đầu trống). **Giá vốn làm kỹ** (trọng tâm báo cáo, chốt cùng ngày): hai phương pháp bình quân, cửa hàng chọn một, chốt kỳ + điều chỉnh liên kết, **ưu đãi nhà cung cấp** (giảm theo bậc, mua X tặng Y, chiết khấu đạt mốc số lượng — giáo viên hướng dẫn yêu cầu) — [spec giá vốn](plans/T7/T7-G5-gia-von-thiet-ke.md). Danh sách giữ / bỏ: mục Theme 7 → "Rút gọn 2026-11-09". AI và Theme 6 giữ nguyên.

**Sửa thứ tự 2026-11-09 (người dùng chốt):** **Tích hợp AI** lên ngay sau Theme 7; **Theme 6 Công nợ** để sau AI; Dọn dẹp sau Theme 6, rồi Báo cáo. Công cụ "công nợ phải thu" của AI đọc công nợ đơn TH-05 (không chờ Theme 6).

**Thứ tự chốt lại 2026-11-03 (thay thứ tự 2026-10-14 bên dưới):** chuyển **hết các theme đã có code** sang kiến trúc mới trước (Theme 2 → Theme 4 → Theme 5 → Theme 8), **rồi** mới làm Theme 7. Hệ quả (người dùng chốt): (1) việc nối kho của Sales tách khỏi Theme 5, làm trong Theme 7 (G5-7 / G5-8; từ rút gọn 2026-11-09 là G5-4); Theme 5 chuyển kiến trúc và giữ tồn cơ bản như hiện tại; (2) Theme 6 (dựng mới) làm sau Theme 7; (3) 5-C (dọn module catalog + inventory, chạy sau Theme 7) thành **dọn module cuối**, nên việc xoá hẳn `modules/` và các package chỉ module dùng chuyển từ 7-C sang 5-C. **Sửa 2026-11-04:** 5-C làm **ngay** (SP-10 chuyển sang `ProductRepository`, không chờ Theme 7) ⇒ 7-C lại là dọn module cuối: xoá `modules/` + `c45_adapters`, `c45_generator` trở về 7-C; `c45_annotations` xoá ở 9-1 (cùng `c45_shared`, vì `c45_shared_application` re-export nó).

**Thứ tự chốt 2026-10-14 (đã thay):** Theme 7 (Kho & Giá vốn, dựng mới theo spec v1) làm **trọn một lượt ngay sau Theme 2**, vì nó chỉ cần sản phẩm / ĐVT (Theme 2) và nhà cung cấp (Theme 3), và thay luôn tồn kho cơ bản của Theme 2. Theme 5 (Sales) làm sau Theme 7 để nối sổ kho thật một lần thay vì refactor xong rồi quay lại. Theme 8 (HĐĐT) làm sau Theme 5, gắn khu HĐĐT vào màn chi tiết đơn đã refactor.

**Mã plan và thư mục giữ theo số phase cũ** để không gãy link (vd `2-A1`, `3-E`, `plans/P2`). Bảng tra:


| Mục                                  | Mã cũ  | Mã plan / thư mục                      |
| ------------------------------------ | ------ | -------------------------------------- |
| Chuẩn bị                             | P0     | `0`                                    |
| Nền core                             | P1     | `1.1`, `1-A`, `1-B` · `plans/P1` (đã xoá hết)       |
| Theme 1 (TH-01 Tổ chức & người dùng) | P2, P3 | `2-*` · `plans/P2`; `3-*` · `plans/P3` (đã xoá hết) |
| Theme 3 (TH-03 Đối tác)              | P4     | `4-*` · `plans/P4`                     |
| Theme 2 (TH-02 Sản phẩm & giá bán)   | P5     | `5-*` · `plans/P5`                     |
| Web cho app (khung web, Theme 1 web) | —      | `W-*` · `plans/W`                      |
| Theme 7 (Kho & Giá vốn)              | —      | `T7-*` · `plans/T7`                    |
| Theme 4 (TH-04 Chính sách giá)       | P6     | `6-*` · `plans/P6`                     |
| Theme 5 (TH-05 Bán hàng)             | P8     | `8-*` · `plans/P8`                     |
| Theme 6 (TH-06 Công nợ phải thu)     | —      | `T6-*` · `plans/T6`                    |
| Theme 8 (TH-08 Hoá đơn điện tử)      | P7     | `7-A*`, `7-B*`, `7-E*`, `7-C` · `plans/P7` (khung cũ `7-1`…`7-5`, dựng lại 2026-11-08; `7-5` → `7-C`) |
| Dọn dẹp                              | P9     | `9-*` · `plans/P9`                     |
| Tích hợp AI                          | —      | `AI-*` · `plans/AI`                    |
| Báo cáo                              | P10    | `10-*` · `plans/P10`                   |


Trong phần mô tả bên dưới, chỗ nào còn ghi `P2`, `P5`, `P7.5`… là mã cũ, tra theo bảng này.


**Ước lượng sửa 2026-10-27** theo tốc độ thật (nhanh hơn bản ước cũ khoảng 3–4 lần: T7-P Giai đoạn 2 ước 24 ngày, làm ~6 ngày; Giai đoạn 3 ước 8–9 ngày, làm ~2 ngày). Phạm vi giữ đủ. Hạn đồ án **2026-12-02**. Mục đã xong giữ số cũ.

| Mục | Nội dung | Ước lượng | Phụ thuộc | Lý do thứ tự |
|---|---|---|---|---|
| Chuẩn bị | Chuẩn bị branch, commit việc dở, chụp checklist | 0,5 ngày | — | |
| Nền core | Dựng `core/` + mẫu feature | 2 ngày | Chuẩn bị | |
| Theme 1 | Auth, đăng ký cửa hàng, IAM | 5 ngày (code xong; còn kiểm tay) | Nền core | |
| Theme 1 (tiếp) | Làm gọn IAM: bỏ `modules/iam`, `apps/admin`, worker, luồng onboarding cũ, Platform Admin | 3 ngày | Theme 1 | Làm nối tiếp IAM khi còn nhớ ngữ cảnh |
| — | **Đợt kiểm IAM** (đóng Theme 1) | 0,5 ngày | Theme 1 (tiếp) | `db reset --linked` → kịch bản SQL → Vault → `functions deploy send-email` → bật xác minh email → kiểm tay TH-01 9.3 → tick CHECKLIST |
| Web cho app | Khung web thanh bên (W-1) + Theme 1 trên web (W-2) | ~1,5 ngày | Theme 1 | Chốt thiết bị 2026-10-20. **Hoãn** sau Theme 7 prototype; W-1 phải xong trước màn Flutter web đầu tiên |
| Theme 3 | Partner (+ dọn module, 3 module rỗng) | 1 ngày | Theme 1 | Nhỏ; Theme 7 (nhà cung cấp), Theme 4, Theme 5 cần nó |
| Theme 2 | Catalog + tồn kho cơ bản (+ dọn module 5-C) | 2 ngày | Theme 1 | Lớn; Theme 7, Theme 4, Theme 5 cần nó |
| Theme 4 | Pricing (+ dọn module) | 1 ngày | Theme 3, Theme 2 | Sales cần giá |
| Theme 5 | Sales (+ dọn module; nối kho làm ở Theme 7 G5-4) | ~2,5 ngày | Theme 3, 2, 4 | Chuyển kiến trúc trước Theme 7 (chốt 2026-11-03); giữ tồn cơ bản tới Theme 7 G5-5 |
| Theme 8 | E-invoice (+ dọn module einvoice, `c45_misa`) | ~3,5 ngày (dựng lại khung 2026-11-08: thêm 3 plan Edge Function) | Theme 5 | Khu HĐĐT trên đơn (7.3) gắn vào màn chi tiết đơn **đã refactor** ở Theme 5; server trước (worker đã xoá, hiện không có gì chạy lệnh MISA); hạ tầng Edge Function + `pg_cron` giống 2-B2 |
| Theme 7 | **Kho & Giá vốn** — **rút gọn 2026-11-09**: 10 plan G5 (tồn & lô, **chương trình NCC**, nhận hàng có giá gốc, nối Sales, kiểm kê / điều chỉnh, **ghi nhận chiết khấu NCC**, **giá vốn & chốt kỳ**, báo cáo tồn + lãi gộp), 18 màn BJ + 5 màn NCC + 7 màn Hub (từ 17 BJ + CAP-01, 70 màn) | không ước lượng (xem bảng Plan Theme 7) | Theme 2, Theme 3; làm sau Theme 8 | Prototype / đặc tả xong (T7-P, T7-G4). Mỗi plan kèm backend, RPC thật không seed, thay tồn kho cơ bản của Theme 2 |
| Tích hợp AI | Trợ lý "Hỏi Mosaic Retail" (Gemini API) hỏi đáp số liệu + dự báo nhập hàng (giảng viên yêu cầu "tích hợp AI vào app") | ~4,5 ngày | Theme 7 (công nợ đọc từ đơn TH-05) | Chốt 2026-11-09: làm **ngay sau Theme 7 (gồm nối kho Sales)**, trước Theme 6 (trước đây làm cuối, 2026-10-27); trợ lý hỏi đáp + dự báo nhập hàng, Gemini API |
| Theme 6 | **Công nợ phải thu khách hàng** (từ đơn bán) + thu tiền + cấn trừ; không có phải trả nhà cung cấp | ~4,5 ngày | Theme 5, Theme 3; làm sau Tích hợp AI | Phải thu đi ra từ công nợ đơn của Theme 5. **Kèm việc AI hoãn lại (2026-11-16):** công cụ `cong_no_phai_thu` cho "Hỏi Mosaic Retail", câu thử 15–17, bước demo 4, ô Home "Phải thu" — xem [AI-0](plans/AI/AI-0-yeu-cau.md) |
| Dọn dẹp | Dọn dẹp còn lại (`c45_shared`, Melos, DB messaging; không gộp migration — chốt 2026-11-19) | 1 ngày | Nền core → Theme 6 (sau 5-C, Theme 7) | Thứ tự 2026-11-03: theme cuối là Theme 6 |
| Báo cáo | Tài liệu, sơ đồ cho báo cáo, kịch bản demo, tập bảo vệ | 3 ngày | Dọn dẹp | |
| | **Tổng phần còn lại** | Không cộng tổng (2026-11-09: ước lượng không sát; Theme 7 rút gọn thay vì ước lại) — hạn đồ án **2026-12-02** | | |

Ước lượng tính cho 1 người. Sales và Catalog lớn nhất, nên chia nhỏ PR.

## Cách làm việc: lên plan → làm → review


| Bước       | Ai     | Kết quả                                                                                                                                                   |
| ---------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Plan**   | Claude | File `docs/refactor/plans/<phase>/<mã việc>-<tên>.md`: mục tiêu, file sẽ sửa/tạo, từng bước, mã mẫu khi cần, cách kiểm tra, rủi ro. Bạn duyệt rồi mới làm |
| **Làm**    | Bạn    | Code theo plan trên branch `refactor/simple-arch` (hoặc branch con), commit                                                                               |
| **Review** | Claude | Đọc diff so với plan và tài liệu TH, chạy analyze/test, ghi kết quả vào cuối file plan (mục "Review"); có góp ý thì bạn sửa rồi review lại                |


**Đơn vị theo dõi là plan**, không phải từng việc nhỏ: mỗi phase có bảng **Plan** (mỗi plan khoảng 0,5–1,5 ngày, gom các việc phải làm cùng nhau; cột "Gồm việc" trỏ về bảng chi tiết bên dưới). Ký hiệu trong cột Plan / Làm / Review của bảng đó và dòng "Trạng thái" đầu mỗi phase:


| Cột    | ⬜           | 📝 / 🔄                   | ✅                | khác                         |
| ------ | ----------- | ------------------------- | ---------------- | ---------------------------- |
| Plan   | chưa viết   | 📝 đã viết, chờ bạn duyệt | đã duyệt         | — không cần (việc làm thẳng) |
| Làm    | chưa làm    | 🔄 đang làm               | xong, chờ review | ⏭ bỏ qua (ghi lý do)         |
| Review | chưa review | 🔄 có góp ý, đang sửa     | đạt              | — không cần                  |


Một việc chỉ tính **xong** khi Review ✅. Ghi commit/PR vào bảng [Theo dõi tiến độ](#theo-dõi-tiến-độ).

Khi đã có file plan, cột **Plan** ghi trạng thái kèm link, ví dụ `📝 [plan](plans/T7/T7-G5-0a-ui-nen.md)`; plan đã làm + review xong thì xoá tệp, ô ghi `✅ plan (đã xoá)` (nội dung tra lại trong lịch sử git, vd. `git show c0faec9e2^:<đường dẫn>`). Tiến độ theo dõi trong bảng của từng Theme.

### Plan có màn Flutter: kèm code + ảnh prototype (chốt 2026-11-09)

Lý do: dựng màn từ mô tả bằng lời làm UI Flutter lệch prototype nặng (T7-G5-0a R1). Áp cho **mọi plan có dựng hoặc sửa màn Flutter**, mọi Theme. Chi tiết cách chép code: Theme 7 → "Quy ước chung cho mọi plan G5" → "UI Flutter: trích nguyên code prototype vào plan".

1. **Code prototype:** task dựng màn chép nguyên văn hàm render + CSS của màn (kèm `tệp:dòng`) và bảng ánh xạ phần tử → widget / token.
2. **Ảnh đích, lúc viết plan:** chép ảnh prototype của từng màn × trạng thái mà plan dựng vào `docs/refactor/plans/<phase>/img/<mã plan>/`, tên `proto-<SCR>-<trạng thái>-390.png` / `-1280.png`. Nguồn ảnh Theme 7: `specs/themes/theme-07/03.design/prototype/html/tools/proto-final/{iphone,web}/` (đọc README của prototype). Theme khác: ảnh prototype của Theme đó nếu có, không có thì ghi "không có ảnh" và lý do.
3. **Trong plan:** đặt ảnh ngay ở task dựng màn đó, dạng bảng hai cột:
   ```markdown
   | Prototype | Flutter |
   |---|---|
   | ![](img/<mã plan>/proto-SCR-066-normal-390.png) | ![](img/<mã plan>/flutter-SCR-066-normal-390.png) |
   ```
   Lúc viết plan cột Flutter để trống; phiên code thêm ảnh `flutter-…` (golden test cùng bề rộng, mặt vẽ thật).
4. **Ảnh người dùng chụp lỗi:** bỏ vào cùng thư mục, tên `user-<SCR>-<mô tả>.png`; phiên review / code đọc ảnh và chuyển thành việc cần sửa trong mục Review.
5. **Review** so từng cặp ảnh trước khi đọc code; lệch ghi kèm tên ảnh.
6. Plan xoá (đã ✅) thì xoá luôn thư mục `img/<mã plan>/` (ảnh tra lại trong lịch sử git).

### Plan xoá / tách / thay code cũ: test giữ hành vi trước (chốt 2026-10-28)

Lý do: 2-B6 R1 (lỗi Tỉnh / Xã) và W-1 R1 (`DashboardPage._buildBody`, `MorePage(tenantBlocked:)`) đều là plan bỏ một cơ chế cũ mà sót việc nó đang làm ⇒ lỗi P1, sửa lại cả plan lẫn code.

Áp cho mọi plan có bước **xoá, tách, gộp hoặc thay** một widget / page / cubit / route đang chạy:

1. **Plan có bảng "Đang làm gì"** cho từng thứ bị xoá / tách: đọc hết thân của nó, mỗi dòng một nhánh / guard / tham số truyền xuống / side effect, cột "Sau khi sửa nằm ở đâu" và cột "Test giữ hành vi". Không dòng nào được để trống cột thứ hai.
2. **Bước 0 của phiên code:** viết test cho từng dòng của bảng **trên code cũ**, chạy xanh, ghi tên test vào mục Kết quả — rồi mới sửa. Test này phải còn xanh sau khi sửa (được đổi cách dựng widget trong test, không đổi điều kiện kiểm).
3. Phiên review đối chiếu bảng với code cũ (`git show HEAD:<tệp>`) trước khi duyệt plan, và kiểm bước 0 có đủ test trước khi đọc diff.

### Plan chuyển kiến trúc: giữ nghiệp vụ, thấy lỗi thì báo người dùng quyết (chốt 2026-11-03)

Plan chuyển sang kiến trúc mới (module → repository, bước (a) của mỗi Theme) **chỉ đổi cách triển khai**, **giữ nguyên nghiệp vụ**: cùng tham số gửi server, cùng rule đầu vào, cùng câu lỗi, cùng luồng màn hình. Chỉ được đổi hành vi ở chỗ mà người dùng **đã chốt** (một Q trong mục Quyết định của plan, hoặc một KI của tài liệu TH) và chỗ đó phải ghi "đổi có chủ đích" ở bảng "Đang làm gì".

Khi viết hoặc rà plan mà thấy code cũ **có vẻ sai** (lỗi nghiệp vụ, rule không bao giờ chạy tới, câu lỗi sai, dữ liệu lệch múi giờ…):

1. **Không** tự sửa trong plan, cũng không lặng lẽ chép lỗi rồi bỏ qua.
2. Báo người dùng ngay lúc viết plan: lỗi gì, ở `tệp:dòng`, ảnh hưởng ra sao, các cách xử lý và đề xuất. Người dùng chọn: sửa luôn trong plan này (thành một Q, ghi đổi có chủ đích, có test), để sang plan sửa KI của Theme (vd. 5-B), hoặc giữ nguyên.
3. Ghi lựa chọn vào plan (mục Quyết định, hoặc mục Rủi ro nếu để sau).

### Quy tắc dọn module (chốt 2026-10-11)

Mỗi phase nghiệp vụ kết thúc bằng một plan **dọn sạch module** của nó (4-C, 5-C, 6-C, 7-C, 8-C — giống 3-C / 3-D của IAM), không để dồn tới P9:

1. App `erp` không còn import `c45_<module>_*` — kể cả chỗ feature **khác** đang gọi chéo (đo 2026-10-11: `sales/presentation` gọi catalog 2, partner 1, pricing 2, einvoice 20; `pricing/presentation` gọi catalog 2, partner 1; `dashboard/presentation` gọi inventory 2).
2. Xoá thư mục module + mục workspace / DI / router / test liên quan.
3. DB của schema đó: bỏ outbox / inbox / RPC / bảng chỉ module cũ dùng — **sửa migration gốc** (quy tắc migration bên dưới).
4. Ràng buộc thứ tự: `modules/einvoice` phụ thuộc `partner/integration_events` và `sales/integration_events` → 4-C giữ `partner/integration_events`, 8-C giữ `sales/integration_events`, tới 7-C. Từ 2026-11-04 5-C làm ngay sau 5-W (SP-10 sang `ProductRepository`), nên **7-C là module cuối**: xoá `modules/` và `c45_adapters` / `c45_generator` ở 7-C; `c45_annotations` ở 9-1 (`c45_shared_application` re-export nó). (Bản 2026-11-03: 5-C là module cuối, chạy sau Theme 7 — đã thay.)


### Quy tắc migration (chốt 2026-10-11)

**Sửa thẳng trong migration gốc, không tạo migration mới chỉ để ghi đè cái cũ.** Áp dụng cho mọi plan từ nay, cho tới khi Prod chạy thật (P10).


| Trường hợp                                       | Làm thế nào                                                                                                                                  |
| ------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Sửa một hàm / trigger / view đã có               | Sửa trong file migration chứa **định nghĩa mới nhất** của đối tượng đó (`grep -l "function iam.<tên>(" supabase/migrations/*.sql | tail -1`) |
| Bỏ một đối tượng của luồng cũ                    | Xoá câu `create …` (và `grant`, trigger đi kèm) khỏi migration gốc; không viết `drop` ở migration mới                                        |
| Bảng / cột / ràng buộc                           | Sửa câu `create table` / `alter table` gốc (vd thêm FK ngay chỗ tạo cột; xoá câu `drop constraint` đã gỡ nó)                                 |
| Đối tượng **mới hoàn toàn**                      | Vẫn tạo migration mới (timestamp lớn nhất)                                                                                                   |
| Migration chỉ còn là bản ghi đè rỗng sau khi gộp | Xoá file + dòng trong `REGISTRY.yaml`                                                                                                        |


**Hệ quả bắt buộc:** Supabase chỉ chạy mỗi file một lần → sửa file **đã áp** thì Dev không tự nhận. Mỗi đợt có sửa migration đã áp: `supabase db reset --linked` trên Dev (xoá sạch DB Dev rồi chạy lại toàn bộ migration + `seed.sql`). Dev hiện gần như trống (0 tài khoản, chỉ dữ liệu seed — đo 2026-10-11) nên reset an toàn; **hỏi trước mỗi lần reset**. Prod chưa đụng tới — P10 dựng mới từ bộ migration cuối. **Sau khi Prod chạy thật, quay lại quy tắc cũ** (chỉ thêm migration mới).

### Thiết bị (chốt 2026-10-20)

Ưu tiên **iPhone** và **web trên máy tính**; Android build từ cùng mã, xếp sau; không iPad, không app macOS / Windows. Khung web = **thanh bên trái**, cửa sổ hẹp về thanh dưới 5 tab. **Cả hai đều là thiết bị chính ở mọi màn** (sửa 2026-10-22). Chi tiết: [LUONG-UNG-DUNG mục 1.1](../requirements/LUONG-UNG-DUNG.md#11-thiết-bị-và-khung-chốt-2026-10-20).

Áp cho mọi plan từ nay:

1. Plan có màn hình thiết kế **đủ cả hai bố cục** cho từng màn — iPhone và web (danh sách – chi tiết, bảng, hộp thoại), tối ưu như nhau — ngay trong plan; không để dồn sang một đợt sau. Theme 2, 3, 4, 5, 8 làm bố cục web trong chính plan của theme; Theme 1 (đã làm) sửa ở mục **Web cho app**; Theme 7 theo T7-P. **Thứ tự (2026-10-20):** Theme 7 trước, rồi mới quay lại từng theme.
2. Review kiểm cả hai: iPhone (simulator) và Chrome cửa sổ rộng + hẹp; trên web đi được bằng bàn phím.
3. Bố cục theo bề rộng; mật độ (`VDensity`) theo cách thao tác (`compact` khi dùng chuột), không suy từ bề rộng.

---


## Cách chuyển MỘT feature (công thức dùng cho Theme 1–5, 8)

Hiện tại:

```text
Page ─▶ Cubit ─▶ IXxxModule.executeCommandAsync(XCommand) ─▶ Handler ─▶ Aggregate/Rule ─▶ Gateway ─▶ SchemaRpcClient ─▶ supabase.schema('x').rpc('fn')
```

Sau refactor:

```text
Page ─▶ Cubit ─▶ XxxRepository.method() ─▶ supabase.schema('x').rpc('fn')
```

**8 bước cho mỗi feature:**

1. **Liệt kê**: grep `executeCommandAsync|executeQueryAsync` trong `apps/erp/lib/features/<x>` để ra danh sách Command/Query mà UI đang dùng.
2. **Truy vết**: với mỗi Command/Query, đi theo Handler → Gateway để ghi lại **tên RPC, tham số, cách map kết quả**.
3. **Model**: tạo `features/<x>/data/models/`. Chuyển DTO đang dùng (từ `modules/<x>/application`) sang và giữ nguyên tên field để UI không phải sửa.
4. **Repository**: tạo `features/<x>/data/<x>_repository.dart`, mỗi Command/Query thành 1 method gọi **đúng RPC cũ**. Lỗi RPC (`raise exception 'CODE'`) được map sang `AppException(code)` dùng chung.
5. **Rule nghiệp vụ**: rule kiểm tra ở Aggregate/Handler (ví dụ MST, giá ≥ 0, số lượng > 0) chuyển thành hàm thuần trong `features/<x>/logic/<x>_rules.dart`. Test domain cũ được giữ lại bằng cách trỏ sang hàm mới.
6. **Đổi Cubit**: thay `IXxxModule` bằng `XxxRepository` trong constructor. Thay `executeXAsync(Command(...))` bằng `repo.method(...)`. Cubit chuyển từ `presentation/bloc/` sang `logic/`.
7. **DI và Router**: đăng ký repository trong `core/di`; route truyền repository thay cho module.
8. **Kiểm tra**: `dart analyze` sạch, test cubit/repository chạy qua, tự bấm hết màn hình của feature trong checklist P0. Sau đó mở PR.

**Quy tắc khi làm:**

- **Tách hai bước, hai PR** (chốt 2026-10-08):
  - **(a) Chuyển kiến trúc**: không đổi hành vi, không sửa UI ngoài import/dependency, không sửa RPC.
  - **(b) Sửa theo tài liệu TH**: các mục 🔧 / 🆕 của theme đó (UI, RPC bằng migration mới, Edge Function). Mỗi mục có plan riêng.
  - Làm (a) trước (b). Có lỗi thì biết ngay do chuyển kiến trúc hay do sửa nghiệp vụ.
- Module cũ **vẫn chạy song song** tới P9: feature nào chưa chuyển thì vẫn dùng module.
- Mỗi feature (hoặc nhóm màn hình lớn) là **1 PR vào** `refactor/simple-arch`.

---


## Chuẩn bị (0,5 ngày)

**Trạng thái:** ✅ Xong (2026-10-08)


| Plan  | Nội dung | Gồm việc | Plan | Làm | Review |
| ----- | -------- | -------- | ---- | --- | ------ |
| **0** | Chuẩn bị | 0.1–0.6  | —    | ✅   | —      |


Chi tiết từng việc:


| #   | Việc                                                                                                                                                               | Kết quả                                                                     |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------- |
| 0.1 | `git checkout refactor/simple-arch` (mang theo 51 thay đổi đang dở)                                                                                                | Đứng trên branch refactor                                                   |
| 0.2 | Commit việc dở thành các nhóm: ① bỏ Railway/CircleCI/GitLab, ② đổi bundle id iOS/Android, ③ docs vận hành, ④ `docs/refactor/` (SCOPE + PLAN)                       | Thư mục làm việc sạch                                                       |
| 0.3 | Tag mốc `v-legacy-arch` tại commit đầu branch và push                                                                                                              | Luôn quay lại được bản cũ                                                   |
| 0.4 | Chạy app bản cũ trên Supabase local và lập **checklist màn hình** `docs/refactor/CHECKLIST.md`: mỗi màn 1 dòng (route, thao tác chính, ☐ đã kiểm tra sau refactor) | Danh sách nghiệm thu 119 dòng. Cột "Cũ" ⏭ bỏ qua theo quyết định 2026-10-08 |
| 0.5 | Chạy toàn bộ test hiện có và ghi lại số pass/fail làm mốc                                                                                                          | Biết test nào vốn đã fail                                                   |
| 0.6 | Chuyển tài liệu / rule / skill của kiến trúc cũ vào `docs/_legacy/`; viết lại `AGENTS.md` và rule Cursor theo kiến trúc mới                                        | AI agent không viết code theo kiểu cũ                                       |


**Xong khi:** branch sạch, có tag, có checklist và mốc test.

---


## Nền `core/` (2 ngày)

**Trạng thái:** ✅ Xong code, merge `7c455c6a7` (2026-10-08) — còn kiểm tay trên Dev theo plan 1-B mục 5


| Plan    | Nội dung                                                                                   | Gồm việc      | Plan                                                | Làm | Review |
| ------- | ------------------------------------------------------------------------------------------ | ------------- | --------------------------------------------------- | --- | ------ |
| **1.1** | Cấu trúc thư mục `core/`                                                                   | 1.1           | ✅ plan (đã xoá)             | ✅   | ✅      |
| **1-A** | `AppException` + bộ dịch lỗi, feature mẫu `partner_change_history`, lint ranh giới feature | 1.2, 1.5, 1.6 | ✅ plan (đã xoá) | ✅   | ✅      |
| **1-B** | `SessionController` + router guard (3 nhánh hiện có; 3 nhánh mới làm ở 2-B1 / P3)          | 1.3, 1.4      | ✅ plan (đã xoá)  | ✅   | ✅      |


Chi tiết từng việc:


| #   | Việc                        | Chi tiết                                                                                                                                                                                |
| --- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.1 | Cấu trúc thư mục            | Dời `lib/configurations/` → `lib/core/config/` trên `refactor/p1-core`                                                                                                                  |
| 1.2 | `AppException` + bộ map lỗi | Một lớp lỗi chung, map từ `PostgrestException.message` (mã `PERMISSION_DENIED`, `VALIDATION_ERROR`…) sang thông báo tiếng Việt. Gộp từ `exception_mapper.dart` và các `IamBlockedCodes` |
| 1.3 | `SessionController`         | Giữ: user hiện tại, có phải platform admin không, danh sách membership, tenant/store đang chọn. Thay cho `ICurrentUser` + `TenantContextCubit` + session port của module                |
| 1.4 | Router guard                | Viết lại `redirect` theo **bảng định tuyến ở SCOPE 3.5**: chưa đăng nhập, chưa xác minh, platform admin, không có tổ chức, tenant bị chặn, tenant active                                |
| 1.5 | Feature mẫu                 | Làm **trước 1 feature nhỏ**: `partner_change_history` (1 query, 1 cubit) theo đủ 8 bước, để làm mẫu cho cả nhóm                                                                         |
| 1.6 | Lint                        | Script `tool/check_feature_imports.dart` kiểm 3 luật phụ thuộc của SCOPE 3.1 cho tầng `data/`, `logic/` (feature khác chỉ dùng repository của nhau)                                     |


**Xong khi:** app chạy như cũ; feature mẫu chạy qua repository; guard là hàm thuần có test (3 nhánh hiện có, 3 nhánh mới của TH-01 2.3 thêm ở 2-B1 / P3); có test cho `SessionController` và guard.

---


## Theme 1. Auth, đăng ký cửa hàng, IAM (5 ngày)

**Trạng thái:** 🔄 Đang làm

**Đóng Theme 1 khi (chốt 2026-10-27):** (A) việc trên Dev của 2-B1 / 2-B2 / 2-B5 — Vault, deploy `invitation-signup`, bật Confirm email + mẫu mã 6 số + rate limit, kiểm tay TH-01 9.3 kịch bản 1–4, tick 33 màn ở CHECKLIST; (B) 2-B6 + 2-B7 (rà lại theo code hiện tại trước khi giao); (C) **W-1 khung web + W-2 Theme 1 trên web** — web là thiết bị chính nên gồm luôn trong lần đóng Theme 1; rồi kiểm tay lần cuối cả iPhone và web. **Danh sách kiểm tay** của các plan đã xoá: `git show 6529acd82:docs/refactor/plans/P2/2-B6-ui-ux-auth.md` (mục "Còn chờ kiểm tay", 6.2, R3), `…/P2/2-B7-ui-ux-iam.md` (R3-2, 6.2), `…/W/W-1-khung-web.md` (mục 5, R2).


| Plan     | Nội dung                                                                                                                                                                                                                                                                                                                                                                                         | Gồm việc                                       | Plan                                                      | Làm | Review                                                              |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------- | --------------------------------------------------------- | --- | ------------------------------------------------------------------- |
| **2-A1** | (a) IAM: tài khoản của tôi, hồ sơ tổ chức, hồ sơ pháp lý, quên mật khẩu                                                                                                                                                                                                                                                                                                                          | 2B.6 (một phần)                                | ✅ plan (đã xoá)          | ✅   | ✅                                                                   |
| **2-A2** | (a) IAM: thành viên, vai trò, lời mời (quản trị), nhật ký quản trị, hub "Người dùng & vai trò"                                                                                                                                                                                                                                                                                                   | 2B.6 (phần còn lại)                            | ✅ plan (đã xoá) | ✅   | ✅                                                                   |
| **2-A3** | (a) Phiên & đăng nhập: `SessionController` gọi RPC trực tiếp (`get_tenant_context`, `list_accessible_tenants`, `switch_tenant_context`, `user_preferences`) và tự cập nhật `IamSession`; `LoginCubit`, đăng xuất, nhập mã lời mời `/invitation` (`InvitationAcceptanceCubit`); xử lý 2 góp ý review 1-B (`core` import `features`, reset state khi đổi người dùng)                               | 2B.5, 1-B góp ý                                | ✅ plan (đã xoá)        | ✅   | ✅                                                                   |
| **2-B1** | (b) Đăng ký cửa hàng mới: trigger DB, cấu hình OTP, `/login`, `/signup`, `/verify-email`, `/no-organization`, banner hồ sơ pháp lý; thêm nhánh guard "chưa xác minh", "không có tổ chức", chọn tổ chức hoạt động đầu tiên                                                                                                                                                                        | 2A.1, 2A.2, 2A.3, 2B.1, 2B.2, 2B.3, 2B.4, 2B.7 | ✅ plan (đã xoá)               | ✅   | 🔄 DB ✅, xác minh email đã bật (2026-10-28); chờ kiểm tay |
| **2-B2** | (b) Email qua Edge Function `send-email`: `iam.email_jobs`, `enqueue_outbox_message` chuyển email sang job, `pg_net` + `pg_cron`, Resend                                                                                                                                                                                                                                                         | 2A.4                                           | ✅ plan (đã xoá)            | ✅   | 🔄 SQL ✅, `send-email` đã deploy, Vault ✅ (2026-10-28); chờ gửi mail lời mời thật |
| **2-B3** | (b) Sửa KI của TH-01: KI-02 (`accept_invitation` kích hoạt lại thành viên đã loại), KI-06, KI-10…KI-14, phần app của KI-05 (bỏ readiness cửa hàng). KI-03 và KI-05 DB/platform dời P3                                                                                                                                                                                                            | TH-01 mục 9.2                                  | ✅ plan (đã xoá)                     | ✅   | ✅                                                                   |
| **2-B4** | (b) Hoàn thiện sau rà soát TH-01: mất quyền khi đang dùng → tải lại phiên; đổi mật khẩu xong đăng xuất; câu lời mời tổ chức tạm ngừng; đăng ký lại cùng email (A3); đếm ngược gửi lại (A4)                                                                                                                                                                                                       | Rà soát 2026-10-10                             | ✅ plan (đã xoá)                 | ✅   | ✅                                                                   |
| **2-B5** | (b) Nhân viên chưa có tài khoản chỉ nhập mã lời mời 8 ký tự (bỏ mã 6 số): Edge Function `invitation-signup` tạo tài khoản đã xác minh + nhận lời mời                                                                                                                                                                                                                                             | Quyết định 2026-10-12                          | ✅ plan (đã xoá)                 | ✅   | 🔄 code đạt; `invitation-signup` đã deploy (2026-10-12); chờ kiểm tay |
| **2-B6** | (b) Hoàn thiện UI/UX màn auth theo audit impeccable: sheet xác nhận lời mời đủ Tổ chức / Vai trò / Email, nút "Tiếp tục" ở nhập mã lời mời, lỗi đăng ký theo từng trường, lỗi đăng nhập dưới form, tự điền (Keychain / Autofill / mã 6 số), ô mã 6 số dùng `VVerificationCodeField`, nhãn nút quay lại, vùng chạm link. Làm sau khi 2-B5 commit                                                  | Audit 2026-10-13                               | ✅ plan (đã xoá)                     | ✅   | ✅ R3 — commit `72b4cc2dd`; còn kiểm tay iPhone + web, VoiceOver / TalkBack (plan mục "Còn chờ kiểm tay") |
| **2-B7** | (b) Hoàn thiện UI/UX màn IAM theo audit impeccable: bàn phím MST nhập được dấu gạch (BR-21), nút mời `+` trên app bar, nhãn "Chủ sở hữu" ở thẻ thành viên, lỗi mời thành viên dưới ô Email, chặn rời form khi chưa lưu, nhãn / vùng chạm (nút lọc, quay lại, "Thử lại", sao chép), tab và chip có trạng thái chọn; `VChip(onTap)` 44 + `VCard(onTap)` là nút; gộp 3 thẻ hành động, xoá file chết | Audit 2026-10-13 | ✅ plan (đã xoá) | ✅   | ✅ R3 — R3-1 xong 2026-10-28; commit `72b4cc2dd`; kiểm tay (R3-2 `VInput` + mục 6.2) gộp vào lượt test Theme 1 |


Chi tiết từng việc:

### 2A. Database (làm trước)


| #    | Migration mới                     | Nội dung                                                                                                                                                                                                                                                                                                                                                                                                                        |
| ---- | --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2A.1 | `iam_create_tenant_for_owner.sql` | Hàm nội bộ `iam._create_tenant_for_owner(user_id, payload jsonb)`: tạo tenant `active`, Owner, cửa hàng mặc định, `last_selected_tenant_id`, audit. Có kiểm tra **mỗi user tối đa 1 tổ chức sở hữu**                                                                                                                                                                                                                            |
| 2A.2 | `iam_on_auth_user_confirmed.sql`  | Trigger trên `auth.users` khi `email_confirmed_at` chuyển từ null sang có giá trị (và khi insert đã xác minh sẵn): tạo profile `active`, có `signup_tenant` thì gọi 2A.1, rồi xoá `signup_tenant` khỏi metadata                                                                                                                                                                                                                 |
| 2A.3 | Cấu hình Auth                     | `supabase/config.toml`: bật xác minh email (`enable_confirmations = true`), dùng **OTP 6 số** (template email đổi `{{ .ConfirmationURL }}` thành `{{ .Token }}`), `max_frequency = "1m0s"`, `site_url` / `additional_redirect_urls` theo deep link của app. Đẩy lên **Dev và Prod** bằng `supabase config push` (lệnh này áp ngay, không hỏi lại). Hiện Dev đang tắt xác nhận email, 1 giây/lần gửi để khớp app cũ (2026-10-07) |
| 2A.4 | Email qua Edge Function           | Tạo `supabase/functions/send-email` (Resend), bảng `iam.email_jobs` và Database Webhook. Sửa RPC lời mời / reset mật khẩu: ghi `email_jobs` thay cho `enqueue_outbox_message`                                                                                                                                                                                                                                                   |


### 2B. Màn hình


| #    | Màn                           | Ghi chú                                                                                                                                                                                          |
| ---- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 2B.1 | `/login`                      | Giữ màn cũ (đã có "Bạn đã nhận được lời mời? → Kích hoạt tài khoản"), thêm nút **Đăng ký cửa hàng mới**. Gộp `sign_in_platform_admin` và `sign_in_tenant_user` thành 1                           |
| 2B.2 | `/signup` (mới)               | Wizard 3 bước: Tài khoản → Cửa hàng → Xác minh email                                                                                                                                             |
| 2B.3 | `/verify-email` (mới)         | Nhập mã, gửi lại mã. Dùng cả cho trường hợp đăng nhập mà email chưa xác minh                                                                                                                     |
| 2B.4 | `/no-organization` (mới)      | "Bạn chưa thuộc tổ chức nào" + Nhập mã lời mời + Đăng xuất                                                                                                                                       |
| 2B.5 | `/invitation`                 | Giữ luồng lời mời nhân viên, chuyển sang repository                                                                                                                                              |
| 2B.6 | IAM trong app (khoảng 20 màn) | Tài khoản của tôi, hồ sơ tổ chức, hồ sơ pháp lý, thành viên, vai trò, lời mời, audit log, quên mật khẩu: chuyển theo công thức 8 bước. **Bỏ** `tenant_readiness_page` và route `/more/readiness` |
| 2B.7 | Banner                        | Banner "Bổ sung hồ sơ pháp lý" ở trang chủ khi chưa có MST                                                                                                                                       |


**Repository:** `AuthRepository` (signIn, signUp, verifyOtp, resend, signOut, resetPassword), `OrganizationRepository`, `MemberRepository`, `InvitationRepository`, `AuditLogRepository`.

Đặc tả chi tiết (chuỗi UI, quy tắc, sửa lỗi KI-02…KI-14, kịch bản kiểm thử): [TH-01 v4.0](../requirements/TH-01-to-chuc-va-nguoi-dung.md) mục 4, 9.2, 9.3.

**Xong khi:**

- Từ `db reset`: đăng ký → nhập mã → vào trang chủ có cửa hàng mặc định.
- Bỏ dở ở bước nhập mã, đăng nhập lại sẽ tới `/verify-email`; xác minh xong vẫn có cửa hàng.
- Owner mời nhân viên, nhân viên nhận mã, tham gia và thấy đúng quyền.
- Không có nút nào tạo tổ chức sau khi đăng nhập.
- Các màn IAM trong checklist đều đã tick.

---


## Theme 1 (tiếp). Làm gọn IAM (3 ngày)

> Ban đầu (2026-10-09, phương án A) phase này chuyển phần quản trị tổ chức của `apps/admin` vào tab **Thêm** (3-A). Từ 2026-10-11 mở rộng thành **làm gọn IAM** (3-B, 3-C, 3-D). Ngày 2026-10-12 **bỏ hẳn Platform Admin** (3-E): phần app của 3-A bị gỡ lại; tổ chức / tài khoản chỉ còn trạng thái hoạt động.

**Trạng thái:** ✅ Xong (2026-10-12). Kiểm tay cùng đợt kiểm IAM


| Plan    | Nội dung                                                                                                                                                                                                                                                                                                                               | Gồm việc                 | Plan                                            | Làm | Review         |
| ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------ | ----------------------------------------------- | --- | -------------- |
| **3-A** | (app) Quản trị tổ chức trong tab Thêm: `isPlatformAdmin`, guard G7, repository + cubit, màn C1–C6, lối vào ở tab Thêm và `/no-organization`, admin mẫu                                                                                                                                                                                 | 3.1, 3.2, 3.3, 3.5       | ✅ plan (đã xoá)      | ✅   | ✅              |
| **3-C** | (app) App không còn phụ thuộc `c45_iam_*`: hằng số / DTO sang core, `SessionStore` + 4 lớp contract thay `IamSession` / `IamStartup`, Sales bỏ `IIamModule`, viết lại 27 test                                                                                                                                                        | Làm gọn IAM (2026-10-11) | ✅ plan (đã xoá) | ✅   | ✅              |
| **3-D** | Xoá `modules/iam`, `apps/admin`, `apps/messaging_worker` + workspace / CI / script                                                                                                                                                                                                                                                     | Làm gọn IAM; kéo 9.1 lên | ✅ plan (đã xoá)            | ✅   | ✅              |
| **3-B** | (DB, sau 3-D, cùng đợt kiểm IAM) KI-08 chặn chuyển Owner cho người đã là Owner nơi khác; dọn onboarding / `provisioning` / `pending_activation`; FK `memberships.user_id` (KI-03)                                                                                                                                                      | 3.4, 3.6                 | ✅ plan (đã xoá)  | ✅   | ✅ (2026-10-12) |
| **3-E** | Bỏ Platform Admin (thay phương án A của 3-A, quyết định 2026-10-12): xoá `features/platform_admin`, G7, RPC `platform_*`, `platform_admins`, `platform_audit_logs`, `c45 admin`; tổ chức / tài khoản chỉ còn hoạt động (bỏ cột `status`, ID-09, `TENANT_SUSPENDED/CLOSED`); bỏ chuyển Owner (KI-08). Làm trước khi tiếp đợt kiểm IAM | Quyết định 2026-10-12    | ✅ plan (đã xoá)     | ✅   | ✅ (2026-10-12) |


Chi tiết từng việc:


| #   | Việc                                                                                                                                                                 |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 3.1 | `features/platform_admin/`~~,~~ `SessionController.isPlatformAdmin`~~, guard G7~~ — làm ở 3-A, gỡ ở 3-E                                                              |
| 3.2 | ~~Chuyển từ~~ `apps/admin`~~: danh sách / chi tiết tổ chức, tạm ngừng / khôi phục / đóng, đổi chủ sở hữu~~ — làm ở 3-A, gỡ ở 3-E                                     |
| 3.3 | ~~Lối vào "Quản trị nền tảng" ở tab Thêm và~~ `/no-organization` — làm ở 3-A, gỡ ở 3-E                                                                               |
| 3.4 | ~~KI-08:~~ `transfer_platform_tenant_ownership` ~~chặn người nhận đã là Owner nơi khác~~ — làm ở 3-B, bỏ cùng chuyển Owner ở 3-E                                     |
| 3.5 | `c45 admin create` ~~+ admin mẫu trong~~ `seed.sql` — gỡ ở 3-E                                                                                                     |
| 3.6 | KI-03 FK `memberships.user_id`; xoá onboarding cũ, owner activation, readiness RPC, trạng thái `provisioning` / `pending_activation` (3-B)                           |
| 3.7 | Bỏ `modules/iam`, `apps/admin`, `apps/messaging_worker`; app hết `c45_iam_*` (3-C, 3-D)                                                                            |
| 3.8 | Bỏ Platform Admin: RPC `platform_*`, bảng `platform_admins`, `platform_audit_logs`; cột trạng thái tổ chức / tài khoản; ID-09 phần tổ chức / tài khoản bị chặn (3-E) |


**Không chuyển** từ `apps/admin`: toàn bộ (sau 3-E).

**Xong khi:** repo không còn `modules/iam`, `apps/admin`, `apps/messaging_worker`, `features/platform_admin`; DB không còn RPC onboarding / `platform_*`, cột trạng thái tổ chức / tài khoản; `db reset --linked` + kịch bản SQL IAM chạy qua (đợt kiểm IAM).

---


## Web cho app (W) (~1,5 ngày)

**Trạng thái:** 🔄 (2026-10-28; trước đó hoãn 2026-10-20, người dùng): làm Theme 7 trước (prototype T7-P, gồm khung web trên prototype), rồi mới quay lại từng theme đã làm; người dùng lướt lại tài liệu một lượt trước khi giao. W-1 phải xong **trước khi code Flutter màn web đầu tiên** (Theme 7 **T7-G5** hoặc theme đầu tiên quay lại). **2026-10-28:** W-1 ✅ (R2), commit `72b4cc2dd`. **2026-10-29:** W-2 ✅ (R4), commit `1bd9268af`. Chỉ còn kiểm tay (gộp đợt đóng Theme 1).

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **W-1** | Khung web: thanh bên trái 5 mục (+ mục con của "Thêm"), ngưỡng bề rộng chuyển thanh dưới ↔ thanh bên, `VDensity.compact` khi thao tác chuột, vùng nội dung giới hạn bề rộng; 5 tab thành `StatefulShellRoute` có URL (~2 ngày) | W.1–W.4 | ✅ plan (đã xoá) | ✅ | ✅ R2 (2 góp ý P3 không chặn; kiểm tay người dùng tự làm); commit `72b4cc2dd` |
| **W-2** | Theme 1 trên web: màn công khai (đăng nhập, đăng ký, xác minh, lời mời) căn giữa cột hẹp; quản trị tổ chức / người dùng / vai trò / nhật ký dạng danh sách – chi tiết hoặc bảng. Gộp hoặc làm ngay sau 2-B6 / 2-B7 (UI/UX auth, IAM — chưa làm) để không sửa một màn hai lần | W.5, W.6 | ✅ plan (đã xoá) duyệt 2026-10-28; rà theo "test giữ hành vi trước" cùng ngày (bổ sung 4 chỗ sót + bảng H1–H13 + bước 0; Q7 sheet lọc iPhone đổi theo DS) | ✅ | ✅ R4 2026-10-29 (2 góp ý P3 không chặn; còn kiểm tay 6.2 — người dùng); commit `1bd9268af`. Kiểm tay xong thì xoá plan |

Chi tiết từng việc:

| # | Việc |
|---|---|
| W.1 | Shell của router: một `ShellRoute` dựng thanh dưới hoặc thanh bên theo bề rộng; giữ nguyên route và guard (LUONG-UNG-DUNG mục 3) |
| W.2 | Thành phần thanh bên trong `c45_design_system` (cùng mục, nhãn, `Semantics` như `VBottomNavigationBar` — 10-4); test |
| W.3 | Chọn density theo thiết bị trỏ (web + chuột → `compact`), không theo bề rộng; Android / iPhone giữ `comfortable` |
| W.4 | Kiểm `flutter build web` + chạy Chrome; phím tắt cơ bản (Tab, Enter, Esc đóng hộp thoại / sheet) |
| W.5 | Màn công khai TH-01 trên web |
| W.6 | Màn quản trị TH-01 trên web (danh sách – chi tiết, bảng thành viên / nhật ký); sheet → hộp thoại |

**Xong khi:** mọi màn Theme 1 dùng được trên Chrome cửa sổ rộng và hẹp, không vỡ, đi được bằng bàn phím; iPhone không đổi so với trước (ảnh chụp so sánh).

---

## Theme 3. Partner (1 ngày)

**Trạng thái:** ✅ plan (2026-11-01) Đã viết và người dùng duyệt 4 plan 4-A → 4-B → 4-W → 4-C. Chốt cùng người dùng: bố cục web ở plan riêng 4-W; 4-A đổi luôn câu lỗi thô theo TH-03 6.4; bỏ so version + kiểm quyền ở client, giữ rule domain thành hàm thuần; hồ sơ nằm trong tab (iPhone vẫn thấy thanh tab khi xem hồ sơ)


| Plan    | Nội dung                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | Gồm việc                | Plan | Làm | Review |
| ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- | ---- | --- | ------ |
| **4-A** | (a) Chuyển partner sang `PartnerRepository` (model, rule, cubit → `logic/`, sales + pricing + router + DI, `FakePartnerRepository`) + rule MST dùng chung; bỏ so version / kiểm quyền ở client, câu lỗi theo TH-03 6.4 (chốt 2026-11-01) | 4.1, 4.2                | ✅ plan (đã xoá) duyệt 2026-11-01 | ✅ 2026-11-01 (chưa commit) | ✅ R1 2026-11-01 (3 góp ý P3 không chặn; còn kiểm tay 7.2 — người dùng) |
| **4-B** | (b) Trigger lịch sử giao dịch đối tác từ `sales.sales_orders` + các sửa KI của TH-03 (03, 05, 07 `unaccent`, 09, 10, 11, 13) + toast lỗi màn người liên hệ + test SQL TH-03 9.3 | 4.3, TH-03 mục 9.2      | ✅ plan (đã xoá) duyệt 2026-11-01 | ✅ 2026-11-01 (chưa commit; SQL chưa chạy trên DB local đúng HEAD) | ✅ R1 2026-11-01 (code đạt; còn người dùng: reset local + `partner_th03.sql`, reset Dev, kiểm tay 7.2) |
| **4-W** | (web) Theme 3 trên web: danh sách – hồ sơ 2 cột trong tab KH & NCC (hồ sơ thành route con của tab, chốt 2026-11-01), 18 sheet → `showVAdaptiveSheet`; màn con giữ toàn màn cột 720 | Thiết bị (2026-10-20), TH-03 5.9 | ✅ plan (đã xoá) duyệt 2026-11-01 | ✅ 2026-11-01 (chưa commit) | ✅ R2 2026-11-02 (đã sửa R1-1, R1-2 của R1; 1 góp ý P3 không chặn; còn kiểm tay 6.2 — người dùng) |
| **4-C** | (dọn) **Dọn sạch module partner**: app hết `c45_partner_*` (kể cả 1 chỗ ở `sales/presentation`, 1 ở `pricing/presentation`, router, DI); xoá `modules/partner/{domain,application,infrastructure}` — **giữ** `modules/partner/integration_events` **tới 7-C** (einvoice phụ thuộc); DB schema `partner`: bỏ outbox / inbox / RPC cũ không còn dùng (sửa migration gốc). Kèm: xoá 3 module rỗng `accounting`, `costing`, `dashboard` (erp không dùng), `packages/c45_resend` (chỉ worker dùng), kiểm `apps/erp/example` | Dọn module (2026-10-11) | ✅ plan (đã xoá) duyệt 2026-11-01 | ✅ 2026-11-01 (chưa commit) | ✅ R1 2026-11-02 (code đạt; 3 góp ý P3 không chặn; còn người dùng: `db reset` local + `partner_th03.sql` / `iam_*.sql`, reset Dev) |


Chi tiết từng việc:

11 file gọi module, 8 cubit, 8 màn: danh sách, tạo, chi tiết, sửa, chuyển cá nhân → tổ chức, liên hệ, lịch sử.


| #   | Việc                                                                                                                                                                                        |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 4.1 | `PartnerRepository` (search, detail, create, update, transform, contacts, deactivate/reactivate/soft-delete, check duplicate)                                                               |
| 4.2 | Rule MST (10/12/10-3) dùng chung với IAM: chuyển vào `core/validation/tax_code.dart`                                                                                                        |
| 4.3 | **Trigger DB ghi lịch sử giao dịch đối tác**: trigger trên `sales.sales_orders` gọi `partner.upsert_partner_history` (TH-03 KI-02). `partner_action_logs` đã được ghi trong RPC, giữ nguyên |


Chia PR và các sửa lỗi đi kèm (KI-02…KI-13): xem [TH-03 mục 9.2](../requirements/TH-03-doi-tac-giao-dich.md#92-chia-pr-của-p4).

**Xong khi:** 8 màn đã tick; tạo đơn bán cho khách thì khách đó không còn xoá được (`HAS_TRANSACTIONS`); 5 kịch bản đầu–cuối ở TH-03 mục 9.3 chạy qua.

---


## Theme 2. Catalog + tồn kho cơ bản (2 ngày)

**Trạng thái:** ✅ plan (2026-11-01) Đã viết và người dùng duyệt 6 plan 5-A1 → 5-A2 → 5-A3 → 5-A4 → 5-B → 5-W (điều kiện: giữ nghiệp vụ cũ, chỉ đổi những chỗ TH-02 KI / người dùng đã chốt); 5-C viết 2026-11-04 (làm ngay, không chờ Theme 7). Chốt cùng người dùng: chia 5-A **theo lớp** (dữ liệu 5-A1/5-A2, đổi UI một lượt 5-A3) vì các nhóm màn dùng chung kiểu / widget và test e2e đi xuyên mọi màn; bỏ RPC đọc trước / sau và kiểm quyền client, giữ rule đầu vào; chép hết kiểu + fake ở 5-A; SP-10 giữ module tới 5-C, bỏ KI tồn (01, 02, 04–07 phần tồn, 12: Theme 7 thay); bỏ sheet cảnh báo giá ngay ở 5-A3; promote migration nháp cặp cửa hàng–kho ở 5-A4; web: PCC trong tab, màn con có id trên URL, Cài đặt sản phẩm toàn màn cột 720


| Plan     | Nội dung | Gồm việc | Plan | Làm | Review |
| -------- | -------- | -------- | ---- | --- | ------ |
| **5-A1** | (a) Dữ liệu: model (chép từ module), phân loại lỗi catalog → `AppException` + câu lỗi TH-02 6.4, rule đầu vào, bộ dựng readiness / PCC, `ProductRepository` (kể cả 4 method hàng bán được cho Sales); test parity `old` / `new`. Chưa đổi UI | 5.1 (data) | ✅ plan (đã xoá) duyệt 2026-11-01; rà lại theo code 2026-11-02 | ✅ 2026-11-03 (đã sửa R1-1 … R1-3, T1 … T4) | ✅ R2 2026-11-03 (đã sửa R1-1, R1-2, R1-3 của R1; thêm T1–T4) |
| **5-A2** | (a) Dữ liệu: `MeasurementUnitRepository`, `CustomFieldRepository`, `ProductPriceRepository` + model, rule; khung giá `customConfig` để server tự tính; không chép bộ cảnh báo giá | 5.2, 5.3, 5.4 (data) | ✅ plan (đã xoá) duyệt 2026-11-01; rà lại theo code sau 5-A1 2026-11-03 (Q8 kiểm id) | ✅ 2026-11-03 | ✅ R3 2026-11-03 |
| **5-A3** | (a) Đổi **toàn bộ** UI catalog + sales + pricing + router + DI sang 4 repository một lượt; 15 cubit → `logic/`; câu lỗi theo 6.4 (KI-07 phần catalog); bỏ sheet "Xác nhận cảnh báo giá" (KI-16 phần sheet); chép `FakeCatalogModule` → `FakeCatalogBackend` + 4 fake repository + `FakeStockCatalogModule`. SP-10 giữ module | 5.1–5.4 (UI) | ✅ plan (đã xoá) duyệt 2026-11-01; rà lại theo code sau 5-A2 2026-11-03 (Q12–Q14 đổi số, Q15 bỏ `final`) | ✅ 2026-11-03 (đã sửa R1-1…R1-10) | ✅ R3 2026-11-04 |
| **5-A4** | (a) Promote `_drafts/inventory_default_pair.sql` thành migration mới (DB dựng từ migration hiện thiếu 2 RPC ⇒ cổng chặn cả app) + `DefaultPairGateCubit` sang `DefaultPairRepository`; bỏ `IInventoryModule` khỏi DI | 5.5 | ✅ plan (đã xoá) duyệt 2026-11-01; rà lại theo code + viết lại Task 0–4, duyệt lại 2026-11-04 | ✅ 2026-11-04 (chưa commit) | 🔄 R1 2026-11-04 chưa đạt (code đạt); đã sửa R1-1…R1-3, R1-4 lúc commit |
| **5-B**  | (b) KI-10 (server chặn > 8 ảnh), 13 (chip "Đã xóa"), 14 ("Giá cơ sở"), 15 (bỏ ô ghi chú), 16 (chữ thừa), 17, 18 (code chết checklist) + test SQL / widget TH-02 9.3. Không làm KI tồn (Theme 7 thay), KI-08 (Theme 5) | TH-02 mục 9.2 | ✅ plan (đã xoá) duyệt 2026-11-01; rà lại theo code sau 5-A3 2026-11-04 | ✅ 2026-11-04 (chưa commit) | ✅ R3 2026-11-04 (đã sửa R1-1…R1-4, R2-1; còn chạy `catalog_th02.sql` + kiểm tay 7.2 — người dùng) |
| **5-W**  | (web) Theme 2 trên web: danh sách – PCC 2 cột trong tab Sản phẩm (PCC là route con `/products/items/:productId`), 11 màn con thành `/products/items/:productId/<x>` toàn màn cột 720, mở từ màn tạo qua route gốc `…/view`; Cài đặt sản phẩm toàn màn; 15 sheet → `showVAdaptiveSheet` | Thiết bị (2026-10-20) | ✅ plan (đã xoá) duyệt 2026-11-01; rà lại theo code sau 5-B 2026-11-04 (thiếu `extra` dùng `redirect`, đổi router test, Task 0–8) | ✅ 2026-11-04 (chưa commit) | ✅ R2 2026-11-04 (còn kiểm tay 6.2) |
| **5-C**  | (dọn) **SP-10 sang repository + dọn sạch module catalog + inventory** (làm ngay sau 5-W, không chờ Theme 7 — chốt 2026-11-04): SP-10 qua `ProductStockAdjustmentCubit` → `ProductRepository.setBasicStock` / `adjustBasicStock` (KI-07 phần app, KI-04; sửa mở từ checklist); fake / DI / nhóm `old` của test parity bỏ module; xoá `modules/catalog`, `modules/inventory` (3 tệp SQL khai báo → `supabase/sql/catalog/functions/`); DB: bỏ outbox / inbox `catalog`, `inventory` (sửa migration gốc), **giữ** mọi RPC, schema `catalog` (kể cả `unaccent_immutable`), `inventory`. **Không** xoá `modules/`, `c45_adapters` / `c45_generator` (7-C), `c45_annotations` (9-1) | Dọn module (2026-10-11) | ✅ plan (đã xoá) | ✅ 2026-11-04 | ✅ R2 2026-11-04 |


Chi tiết từng việc:

ERP có **80 tệp** import module catalog / inventory, **15 cubit**, **23 màn** (đo lại 2026-11-01). Bảng dưới là nhóm màn theo nghiệp vụ; plan chia **theo lớp** (5-A1/5-A2 dữ liệu, 5-A3 đổi UI một lượt), xem bảng Plan:


| PR  | Nhóm              | Màn chính                                                                                                                                         |
| --- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| 5.1 | Sản phẩm cốt lõi  | Danh sách/tab sản phẩm, control center, tạo nhanh/guided, sửa hồ sơ, ảnh, vô hiệu/khôi phục/xoá, lịch sử thay đổi, readiness sản phẩm             |
| 5.2 | Đơn vị tính       | ĐVT tenant, ĐVT sản phẩm, quy đổi                                                                                                                 |
| 5.3 | Trường tuỳ chỉnh  | Nhóm, field, giá trị, sắp xếp                                                                                                                     |
| 5.4 | Giá trong catalog | Giá gốc thủ công, khung giá theo đơn vị, quy tắc giá cửa hàng + lịch sử                                                                           |
| 5.5 | **Tồn kho cơ bản** | Chỉ chuyển **cổng cặp cửa hàng–kho mặc định** (`DefaultPairGateCubit` ở trang chủ, `inventory.default_pair`) sang `DefaultPairRepository`. **Không** refactor màn điều chỉnh tồn (`product_stock_adjustment_page`) và bước nhập tồn khi tạo sản phẩm (`product_guided_step_inventory`): Theme 7 thay bằng BJ-08 (kiểm kê, điều chỉnh) và BJ-12 (tồn đầu kỳ), chốt 2026-10-14. Tồn cơ bản của TH-02 **khác** Kho & Giá vốn của Theme 7 |


Repository: `ProductRepository`, `MeasurementUnitRepository`, `CustomFieldRepository`, `ProductPriceRepository`, `DefaultPairRepository` (không dùng tên `InventoryRepository`: tên đó là repo màn Kho của Theme 7).
Riêng tìm sản phẩm bán được / quét barcode (`search_sellable_products`, `resolve_sellable_barcode`): đặt trong `ProductRepository` để P8 Sales dùng lại.

Các sửa lỗi: [TH-02 mục 9.2](../requirements/TH-02-san-pham-va-gia-ban.md#92-theo-pr-của-p5) (KI-01…KI-18) gom ở 5-B, trừ KI-07 phần catalog (5-A3), KI-16 phần sheet (5-A3), KI tồn 01, 02, 04–07 (phần tồn), 12 (Theme 7 thay, chốt 2026-11-01). Kiểm đơn vị đã bán khi xoá (TH-02 KI-08) làm ở P8 PR 8.1.

**Xong khi:** các màn catalog trong checklist đều đã tick (trừ SP-10: Theme 7 thay); kịch bản đầu–cuối 1–4 và test RPC ở TH-02 mục 9.3 trong phạm vi 5-B chạy qua (kịch bản 5 "điều chỉnh tồn hai máy" và test tồn 🔧: Theme 7); cổng cặp cửa hàng–kho chạy trên DB dựng từ migration.

---


## Theme 4. Pricing (1 ngày)

**Trạng thái:** 🔄 đang làm (2026-11-06): code + review xong cả 4 plan (6-A1, 6-A2, 6-B, 6-C; 6-C review R1 đạt 2026-11-06), đã commit. Còn việc người dùng: `db reset` local + `pricing_th04.sql`, reset Dev, kiểm tay (6-A2 7.2, 6-B 8.2). Chốt cùng người dùng: chia 6-A **theo lớp** như Theme 2 (6-A1 dữ liệu, 6-A2 đổi UI một lượt); Sales chuyển ngay trong 6-A (`SalesPricingRepository`); sửa luôn lỗi bật lại mất cờ ghi đè; câu lỗi thô đổi theo TH-04 6.4; **bỏ hẳn nhập Excel** (EP-04, PR-09) và màn "Chọn cách thêm" (PR-03) ngay ở 6-A, DB nhập xoá ở 6-C


| Plan    | Nội dung                                                                                                                                                                                    | Gồm việc                | Plan | Làm | Review |
| ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- | ---- | --- | ------ |
| **6-A1** | (a) Dữ liệu: model (chép từ module), phân loại lỗi → `AppException` + câu lỗi TH-04 6.4, rule đầu vào, `CustomerPriceRuleRepository`, `SalesPricingRepository`; test parity `old` / `new`. Bỏ RPC đọc trước (create / update context), sửa bật lại gửi đúng `p_acknowledge_overwrite`. Không làm nhập Excel. Chưa đổi UI | 6.1 (data) | ✅ plan (đã xoá) | ✅ 2026-11-04 (commit 6-A1…6-B) | ✅ R2 2026-11-04 (đã sửa R1-1 mã tiền tệ chữ hoa, R1-2 ghi lệch mã lỗi Q7) |
| **6-A2** | (a) Đổi UI pricing + Sales (`sales_pricing_lookup`, `sales_draft_backend`) + router + DI sang repository một lượt; 4 cubit → `logic/`; xoá màn nhập Excel (PR-09) và màn "Chọn cách thêm" (PR-03: nút thêm mở thẳng form); câu lỗi thô theo 6.4; `FakePricingModule` → `FakeCustomerPriceRuleRepository` + `RecordingSalesPricingRepository` | 6.1 (UI), 6.3 | ✅ plan (đã xoá) | ✅ 2026-11-04 (commit 6-A1…6-B) | ✅ R3 2026-11-05 (đã sửa R1-1 state lịch sử, R1-2 + R2-1 ghi chép; còn kiểm tay 7.2 — người dùng) |
| **6-B** | (b) Các sửa KI của TH-04 (trừ KI-03: nhập Excel đã bỏ); bỏ lọc nhanh lịch sử "Nhập Excel" cùng KI-02; + 4 lỗi thấy khi viết plan (tên người tắt / cập nhật, tổng số, link banner trùng, chip "Tùy chọn") | TH-04 mục 9.2 | ✅ plan (đã xoá) | ✅ 2026-11-06 (commit 6-A1…6-B) | ✅ R2 2026-11-06 (đã sửa R1-1…R1-6; TH-04 lên 3.2; còn chạy `pricing_th04.sql` + kiểm tay 8.2 — người dùng) |
| **6-C** | (dọn) **Dọn sạch module pricing**: app hết `c45_pricing_*` (sales đã chuyển ở 6-A2; nhóm `old` của test parity, `pubspec.yaml`); xoá `modules/pricing`; DB schema `pricing`: bỏ RPC cũ không còn dùng, **xoá phần nhập Excel** (4 RPC `*_customer_price_rule_import`, hàm phụ, bảng lô / dòng nhập, `catalog._resolve_product_unit_for_pricing_import`; kiểm dữ liệu nguồn `excel_import`) + 2 RPC đọc trước `get_customer_price_rule_create_context` / `update_context` (sửa migration gốc); giữ 4 cột truy vết nhập (bỏ FK), giữ `delete_customer_price_rule`, `save_remembered_price_from_order`; live test dọn qua RPC | Dọn module (2026-10-11) | ✅ plan (đã xoá) duyệt 2026-11-06 | ✅ 2026-11-06 | ✅ R1 2026-11-06 (không có việc sửa; review cập nhật `TEST-BASELINE.md` mục "Sau 6-C"; còn `db reset` + `pricing_th04.sql`, reset Dev — người dùng) |


Chi tiết từng việc:

9 file gọi module, 5 cubit, 9 màn: danh sách, form, chi tiết, lịch sử, import, các màn chọn (sản phẩm/khách/đơn vị). Từ 2026-11-04 bỏ màn import và màn chọn cách thêm ⇒ còn 7 màn.


| #   | Việc                                                                                  |
| --- | ------------------------------------------------------------------------------------- |
| 6.1 | `CustomerPriceRuleRepository` (CRUD, tắt/bật, lịch sử, resolve áp dụng)               |
| 6.2 | ~~`PriceImportRepository` (template, start/confirm/cancel import)~~ — **bỏ** (2026-11-04, người dùng: bỏ nhập Excel) |
| 6.3 | Màn chọn sản phẩm/khách dùng lại `ProductRepository` (P5) và `PartnerRepository` (P4) — đã xong ở 4-A / 5-A3 (đo 2026-11-04) |


Chia PR và các sửa lỗi đi kèm (KI-02…KI-15): xem [TH-04 mục 9.2](../requirements/TH-04-chinh-sach-gia.md#92-chia-pr-của-p6).

**Xong khi:** 7 màn còn lại đã tick (PR-03, PR-09 bỏ); 4 kịch bản đầu–cuối 1–4 ở TH-04 mục 9.3 chạy qua (kịch bản 5 nhập Excel bỏ).

---


## Theme 5. Sales (~2,5 ngày; nối kho ở Theme 7)

**Trạng thái:** 🔄 8-A1…8-A3 xong (review ĐẠT 2026-11-07); 8-A4 xong (review R2 ĐẠT 2026-11-07). Chốt cùng người dùng: chia 8-A **theo nhóm màn** (giữ bảng dưới); repository gọi thẳng RPC nhưng **trả DTO của `c45_sales_application`**, chép kiểu + đổi import một lượt ở 8-C; lỗi repository là `AppException`; câu lỗi thô đổi theo TH-05 6.4 ngay ở (a); việc đổi hành vi / sửa DB của 8.1 (KI-07, TH-02 KI-08) sang 8-B. 8-B chia 3 plan (chốt 2026-11-07): 8-B1 server → 8-B2 app → 8-B3 Thu tiền, người dùng duyệt 2026-11-07; 2026-11-08: 8-C xong (review R1 ĐẠT).


| Plan     | Nội dung                                                                                                                                                                                                                                                                                                                                                                                         | Gồm việc                | Plan | Làm | Review |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------- | ---- | --- | ------ |
| **8-A1** | (a) Soạn đơn + nháp: `SalesDraftRepository` (5 RPC nháp, trả DTO của module — chép kiểu ở 8-C), lỗi `AppException`, câu lỗi SG-01 theo TH-05 6.4; `SalesDraftListCubit` + `SalesDraftBackend` → `logic/`. KI-07, TH-02 KI-08, KI-21, KI-22 → 8-B (chốt 2026-11-06) | 8.1 | 📝 plan (đã xoá) | ✅ 2026-11-07 | ✅ 2026-11-07 |
| **8-A2** | (a) Checkout + thanh toán: `SalesCheckoutRepository` + `SalesPaymentRepository` + `SalesOrderRepository.get`; record payment/refund không chuyển (chốt 2026-11-07)                                                                                                                                                                                                                                                                                                                                                                      | 8.2                     | 📝 plan (đã xoá) | ✅ 2026-11-07 | ✅ 2026-11-07 |
| **8-A3** | (a) Tra cứu đơn + phiếu: `SalesOrderRepository` thêm list / search / detail / timeline / return summary / post-sale actions / cancellation; `SalesReceiptRepository` (generate / get / original / in / chia sẻ); câu lỗi thô SG-08 / SG-09 theo TH-05; KI-06/07/09 → 8-B (chốt 2026-11-07) | 8.3, 8.4                | 📝 plan (đã xoá) | ✅ 2026-11-07 | ✅ 2026-11-07 |
| **8-A4** | (a) Huỷ đơn + đổi/trả: `SalesCancellationRepository` (precheck / confirm) + `ReturnExchangeRepository` (precheck, returnable, preview giá, detail, start / update / cancel / confirm / complete, evaluate); bỏ `_get_return_exchange_context` trước confirm / evaluate; lớp request thay 6 command; câu lỗi + blocker theo TH-05 6.4; 3 cubit → `logic/`; KI-05/08/10/17/18 → 8-B (chốt 2026-11-07) | 8.5 | 📝 plan (đã xoá) | ✅ 2026-11-07 | ✅ 2026-11-07 |
| **8-B1** | (b) Server: KI-03 `CUSTOMER_INVALID`, KI-04 `RECEIVABLE_DUE_DATE_INVALID` (precheck / finalize / confirm đổi trả), KI-05 lưu ngày hẹn đổi hàng, KI-09 tìm đơn không dấu, TH-02 KI-08 đơn vị đã bán; KI-02 đã có ở finalize (chỉ test); câu mã chặn mới ở `_classifyResult`; `supabase/tests/sales_th05.sql` (TH-05 9.3) — chốt 2026-11-07 | TH-05 mục 9.2 (8.1, 8.2, 8.3, 8.5) | ✅ plan (đã xoá) duyệt 2026-11-07 | ✅ 2026-11-07 | ✅ R2 2026-11-07 |
| **8-B2** | (b) App: KI-07 (+ "Công nợ cũ" trên PDF), KI-08, KI-10, KI-17, KI-18; SG-01 KI-21 (trang 25, tải thêm, tìm + "Đơn của tôi" ở server theo người tạo), KI-22 ("Tạo bởi" từ server); xoá nháp `REFERENCE_UNAVAILABLE` = tải lại, câu "Không xóa được đơn nháp" — chốt 2026-11-07; review thêm: "Đơn nháp (N)" = tổng nháp cửa hàng (`total_count`), bỏ QR mẫu SG-06 (KI-23) — chốt 2026-11-07 | TH-05 mục 9.2 (8.1, 8.3, 8.5) | ✅ plan (đã xoá) duyệt 2026-11-07 | ✅ 2026-11-07 | ✅ R2 2026-11-08 (đã sửa R1-1…R1-6, R2-1, R2-2; còn `db reset` + `sales_th05.sql`, kiểm tay 7.2 — người dùng) |
| **8-B3** | (b) Màn Thu tiền SG-11 (KI-06 / EP-04): `SalesPaymentRepository.recordPayment`, mục "Thu tiền" ở sheet Thao tác, `showVAdaptiveSheet` (iPhone + web) — chốt 2026-11-07 | TH-05 mục 9.2 (8.3) | ✅ plan (đã xoá) duyệt 2026-11-07 | ✅ 2026-11-08 | ✅ R2 2026-11-08 (đã sửa R1-1…R1-5; còn chạy `sales_th05.sql` P01–P04, kiểm tay 7.2 — người dùng) |
| **8-C** | (dọn) **Dọn sạch module sales**: app hết `c45_sales_*` (20 file `sales/presentation` còn gọi einvoice chạy song song tới 7-A2); xoá `modules/sales` **trừ `modules/sales/integration_events`** (einvoice còn dùng, xoá ở 7-C); DB schema `sales`: bỏ messaging (inbox / internal_commands / hàm hàng đợi). **Chốt 2026-11-08:** `Core*` (`CoreExecutionContext` / `CorePermissionChecker` / `CoreTenantAccessChecker`) dời 7-C (einvoice còn dùng); giữ `sales.outbox_messages` làm nhật ký sự kiện của đơn (Lịch sử đơn); không xoá RPC nào | Dọn module (2026-10-11) | ✅ plan (đã xoá) duyệt 2026-11-08 | ✅ 2026-11-08 | ✅ R1 2026-11-08 (không có việc sửa; review cập nhật `TEST-BASELINE.md` mục "Sau 8-C"; còn `db reset` + `sales_th05.sql`, reset Dev — người dùng) |


Chi tiết từng việc:

20 file gọi module, 13 cubit, khoảng 20 màn. Chia thành 5 PR:


| PR  | Nhóm                  | RPC/Query chính                                                                                                                                                                    |
| --- | --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 8.1 | Soạn đơn + nháp       | save/update/cancel draft, list drafts, restore; preview pricing (gọi pricing). Sửa `catalog._product_unit_has_sales_transaction_usage` đọc dòng đơn / nháp / đổi trả (TH-02 KI-08) |
| 8.2 | Checkout + thanh toán | precheck checkout, **finalize_sales_order** (transaction ở DB), record payment/refund, settlement, payment summary                                                                 |
| 8.3 | Tra cứu đơn           | list/search/detail/timeline, post-sale actions                                                                                                                                     |
| 8.4 | Phiếu/biên lai        | generate/get receipt, original receipt, printed/shared, slip preview                                                                                                               |
| 8.5 | Huỷ đơn + đổi/trả     | cancellation (lý do, precheck, confirm); return/exchange (start, preview pricing, update, confirm, complete, cancel)                                                               |


**Integration event:** bỏ messaging; `sales.outbox_messages` giữ làm nhật ký sự kiện (8-C, 2026-11-08). Phát hành HĐĐT tự động dùng trigger trên `sales.sales_orders` khi đơn Hoàn tất, ghi việc vào `einvoice.internal_commands` (làm ở 7.5 của Theme 8, sau Theme 5; TH-08 KI-19, KI-20). Không gọi "nhớ giá từ đơn" (ngoài phạm vi, TH-04 KI-02). Trừ/cộng tồn khi bán, huỷ, đổi trả: Theme 5 **giữ tồn cơ bản như hiện tại** (chỉ chuyển kiến trúc); nối sổ kho Theme 7 ở Theme 7 **G5-4**.

**Xong khi:** đủ 6 kịch bản: bán thường, bán nợ rồi thu sau, hoàn tiền, huỷ đơn, đổi hàng, trả hàng. Công nợ (còn phải thu của đơn) đúng sau mỗi kịch bản. Tồn kho (tồn cơ bản) đúng như trước khi chuyển kiến trúc sau mỗi kịch bản; tồn theo sổ kho kiểm ở Theme 7 G5-4. Các màn sales trong checklist đều đã tick.

---


## Theme 8. E-invoice (~3,5 ngày)

**Trạng thái:** 🔄 Đang làm. Dựng lại khung 2026-11-08 (người dùng chốt): **server trước** (7-B1 → 7-E1 → 7-E2a → 7-E2b → 7-E2c → 7-E3), rồi app (7-A1 → 7-A2a → 7-A2b → 7-B2; 7-A2 tách đôi 2026-11-08), cuối cùng 7-C; (a) chia **theo lớp** như Theme 2/4 (7-A1 dữ liệu, 7-A2a UI thiết lập, 7-A2b UI trên đơn); bố cục web làm trong 7-B2 (không có plan 7-W); mã cũ 7-1…7-5 đổi sang 7-A*, 7-B*, 7-E*, 7-C. Hiện trạng: 7-B1, 7-E1..E3, 7-A1..A2b, 7-B2, 7-C đã xong code (2026-11-09; 7-C xoá sạch `modules/`, viết lại migration `20261031002`, bỏ 5 script guard); còn review 7-C và các mục kiểm tay live trên Dev của người dùng.


| Plan     | Nội dung | Gồm việc | Plan | Làm | Review |
| -------- | -------- | -------- | ---- | --- | ------ |
| **7-B1** | (b) Server: KI-02 `update_automation_policy` bật tự động khi chưa sẵn sàng → `CONFIG_NOT_READY`; KI-04 kiểm người mua hiệu lực trong `issue_invoice` / `retry_issuance` / `start_auto_issuance` / `reevaluate_auto_issuance` (hàm chung `_buyer_issuance_blocker`) (`ISSUANCE_NOT_READY` + `BUYER_*`, tự động → `PENDING_REEVALUATION`); KI-06 chép lại trường người mua mỗi lượt khi chưa có hoá đơn + readiness ưu tiên hồ sơ hiện hành; KI-02 chỉ chặn khi bật mới; khoá 4 hàm bộ xử lý chỉ `service_role` (lỗi grant `authenticated`); map `CONFIG_NOT_READY` phía app → 7-A1 — chốt 2026-11-08. Sửa migration gốc (`20261031004` / `006` / `008` / `023`); `supabase/tests/einvoice_th08.sql` (phần SQL của TH-08 9.3) | 7.1 | ✅ plan (đã xoá) duyệt 2026-11-08 | ✅ 2026-11-08 | ✅ R1 2026-11-08 (ĐẠT, 4 góp ý nhỏ; còn `db reset` + `einvoice_th08.sql`, reset Dev — người dùng) |
| **7-E1** | Edge Function `supabase/functions/einvoice-processor` (Deno / TypeScript, `service_role`): client MISA (đăng nhập + token theo tổ chức, lấy mẫu, xem trước, phát hành, `getStatus`, tải, gửi email; phân loại lỗi như `packages/c45_misa`) + chép 62 test của `c45_misa` sang Deno test; khung hàng đợi (claim / complete / fail `internal_commands`, giới hạn số việc mỗi lần gọi, mật khẩu qua `read_provider_credentials`); handler `einvoice.sync_capabilities`; thêm `einvoice.list_tenants_with_due_commands`, sửa `reschedule_internal_command` ghi cột `updated_at` không có (KI-22) — chốt 2026-11-08 | 7.4 | ✅ plan (đã xoá) duyệt 2026-11-08 | ✅ 2026-11-08 (chưa commit; còn `db reset` + `einvoice_th08.sql` — người dùng) | ✅ R2 2026-11-08 (ĐẠT; R1 sửa KI-23 `created_at` trong 7 `insert internal_commands` + CORS; còn `db reset` + `einvoice_th08.sql` E32–E34, E40, reset Dev — người dùng) |
| **7-E2a** | Luồng phát hành: `preview_invoice`, `publish_invoice` (+ khoá ký hiệu, **không** gia hạn — khoá 300 giây > giới hạn 150 giây), `poll_issuance_status` (đối soát) + dead-letter preview / publish; chép 106 test Dart; ca SQL khoá ký hiệu / thử lại bền E41–E45. Giữ nguyên RPC `record_*`, số lượt thử, lịch đối soát — chốt 2026-11-08 (7-E2 tách 3 plan theo luồng) | 7.4 | ✅ plan (đã xoá) duyệt 2026-11-08 | ✅ 2026-11-08 (chưa commit; còn `db reset` + `einvoice_th08.sql` E41–E45 — người dùng) | ✅ R2 ĐẠT 2026-11-08 (R1: E44 `now()`, Kết quả) |
| **7-E2b** | `fetch_official_view`, `download_invoice_document` (+ Storage), `poll_provider_observation` + dead-letter official view / document; chép 34 test Dart; `getForTenant` trả thêm `taxCode`; bucket `einvoice-documents` nhận `application/zip` (KI-24, sửa `20261031011`) + ca SQL E46 — chốt 2026-11-08 | 7.4 | ✅ plan (đã xoá) duyệt 2026-11-08 | ✅ 2026-11-08 (chưa commit; còn `db reset` + `einvoice_th08.sql` E46 — người dùng) | ✅ R2 ĐẠT 2026-11-08 (R1: `loadObservationContext` nuốt `NOT_FOUND`, log MISA không ra, Kết quả; còn `db reset` + `einvoice_th08.sql` E46 — người dùng) |
| **7-E2c** | `send_invoice_email`, `reconcile_invoice_delivery` + dead-letter delivery / reconciliation; chép 72 test Dart; dead-letter đối soát gửi đọc payload camelCase (KI-25) — chốt 2026-11-08 | 7.4 | ✅ plan (đã xoá) duyệt 2026-11-08 | ✅ 2026-11-08 (chưa commit) | ✅ R2 ĐẠT 2026-11-08 (R1: tên ca thiếu group, gateway bool / int, Kết quả) |
| **7-E3** | Kích hoạt phía server: 3 trigger tự động (đơn Hoàn tất, hồ sơ khách đổi theo `partners.version`, hoá đơn mới xếp gửi tự động — KI-26; sửa `…008`, `…013`) ghi thẳng `einvoice.internal_commands`; cron `20261108001` gọi `einvoice-processor` mỗi 30s qua `pg_net` + Vault `service_role_key`; 3 handler mới (chép 33 test Dart); viết lại 2 checklist MISA + RUNBOOK-einvoice; checklist UI sau 7-A2 (Q1–Q6) | 7.5 (server) | ✅ plan (đã xoá) duyệt 2026-11-08 | ✅ 2026-11-08 (chưa commit; còn `db reset` + `einvoice_th08.sql` E47–E52, Vault, deploy, mục kiểm server của S1 — người dùng) | ✅ R2 ĐẠT 2026-11-08 (R1: S1 / RUNBOOK gửi tự động trên testapi, TH-08 6.2 / KI-20, Kết quả) |
| **7-A1** | (a) Dữ liệu: 2 repository `EInvoiceConfigurationRepository` (10 phương thức: kết nối, mẫu, cấu hình mặc định, tự động, sẵn sàng cấu hình) và `EInvoiceRepository` (14 phương thức: hình chiếu, sẵn sàng, phát hành, thử lại, bản chính thức, tài liệu Storage, gửi email, lịch sử), model chép từ module, phân loại lỗi → `AppException` + câu lỗi theo TH-08 6.4, `IssuanceReadinessEvaluator` → `logic/`, test parity `old` / `new`; repository gọi `functions.invoke('einvoice-processor')` sau mỗi RPC ghi yêu cầu. Chưa đổi UI | 7.2, 7.3 (dữ liệu), 7.5 (app) | ✅ plan (đã xoá) duyệt 2026-11-08 | ✅ 2026-11-08 (chưa commit) | ✅ R2 ĐẠT 2026-11-08 (R1: `requestPreview` chặn rộng hơn handler, `reconnect` thừa rule, mapper `toUtc` / `toUpperCase`, câu lỗi so chuỗi thô, import, Kết quả) |
| **7-A2a** | (a) UI thiết lập: 4 trang `/more/einvoice/*` sang `EInvoiceConfigurationRepository` — chép 29 tệp thiết lập của `modules/einvoice/presentation` về `features/einvoice/{logic,presentation}`, cubit so `AppException.code`; trang Kết nối hỏi lại bằng `Timer` 2 giây trong cubit (KI-16); không chép `recheck` / 2 màn chết (KI-15); HD-04 hiện đúng toast "Mẫu không tương thích" / "Chưa kết nối MISA" (`einvoiceException` thêm `TEMPLATE_NOT_AVAILABLE`, `SIGNING_CONFIGURATION_NOT_AVAILABLE` — chốt 2026-11-08); router + DI + fake repository; chép 7 tệp test module | 7.2 (UI) | ✅ plan (đã xoá) duyệt 2026-11-08 | ✅ 2026-11-08 | ✅ R2 ĐẠT 2026-11-08 (R1: dòng trống cuối 37 tệp, 2 ca test mất kiểm gọi lưu 1 lần, Kết quả; còn kiểm tay 6.7 — người dùng) |
| **7-A2b** | (a) UI trên đơn: khu HĐĐT của `features/sales` (section, 2 cubit + lịch sử, sheet, exporter, `sales_order_detail_cubit`, màn kết quả bán) về `features/einvoice`, gộp bản trùng (KI-17), cubit → `logic/`; hỏi lại bằng `Timer` trong cubit thay `c45_async_query`, giữ nhịp cũ (5 giây); bỏ `QueryClient` khỏi DI / `main.dart`; fake `EInvoiceRepository`. Bỏ cache `QueryClient` (chỉ áp snapshot khi đọc thành công, Q1 — chốt 2026-11-08); `IEInvoiceModule` / `c45_einvoice_*` trong DI để 7-C | 7.3 (UI) | ✅ plan (đã xoá) duyệt 2026-11-08 | ✅ 2026-11-08 | ✅ R2 ĐẠT 2026-11-08 (R1: câu lỗi dò chuỗi thô, 4 tệp test chép còn test module, 2 ca đỏ, thiếu B0-1…3, test import module, Kết quả; còn kiểm tay 5.7 — người dùng) |
| **7-B2** | (b) App: KI-01 HD-04 hiện `last_verified_at` (cubit đọc thêm `getConnectionScreen`, lỗi / không có thì bỏ dòng); KI-08 HD-12 lấy lần gửi **thành công** gần nhất + nhãn nguồn + dòng tóm tắt dưới ô email; giờ HĐĐT theo giờ máy (KI-27, HD-02 lệch UTC); bố cục web: HD-01…05, HD-13 đã ở cột 720 (chỉ test), HD-03 và HD-07…12 qua `showVAdaptiveSheet(title:)` (iPhone + web); phần UI của `DEV-LIVE-ACCEPTANCE-CHECKLIST` do người dùng chạy (7-E3 Q3) — chốt 2026-11-08 | 7.2, 7.3 | ✅ plan (đã xoá) duyệt 2026-11-08 | ✅ 2026-11-08 | ✅ R1 ĐẠT 2026-11-08 (2 góp ý nhỏ: import thừa trong test, dùng CLI GitNexus; còn kiểm tay 5.7 + checklist live 6.6 — người dùng) |
| **7-C**  | (dọn; mã cũ 7-5) **Dọn sạch module einvoice**: app hết `c45_einvoice_*` (4 trang thiết lập chuyển ở 7-A2a, khu HĐĐT của `features/sales` ở 7-A2b); xoá `modules/` (gồm `einvoice`, `partner/integration_events`, `sales/integration_events`), `packages/c45_misa` (đã thay bằng client TypeScript 7-E1), `packages/c45_async_query`, `packages/c45_adapters`, `c45_generator`; bỏ `EinvoiceStartup`, `CorePermissionChecker`, `CoreTenantAccessChecker` khỏi DI (`core/session`), **giữ `CoreExecutionContext`** cho `features/sales` đến 9-1 (Q1); test hợp đồng SQL **mới** ở `apps/erp/test/features/einvoice/data/einvoice_sql_contract_test.dart` (test module bỏ, không chuyển — Q4); viết lại migration `20261031002` tạo thẳng `internal_commands` + `outbox_messages` (nhật ký sự kiện, không ai đọc), bỏ inbox / hàm outbox / đăng ký `platform` (Q2), **không đụng nền `platform`** đến 9-1 (Q3); xoá `renew_publish_series_lease` trong `20261031019` và `REGISTRY.yaml` (Q3); xoá 5 script/guard của module (Q5). | Dọn module (2026-10-11) | ✅ plan (đã xoá) duyệt 2026-11-09 | ✅ 2026-11-09 | ✅ R1 2026-11-09 (góp ý R1-1, R1-2 đã sửa; review cập nhật `TEST-BASELINE.md` mục "Sau 7-C"; còn `db reset` + `einvoice_th08.sql` + một lượt phát hành trên Dev — người dùng) |


Chi tiết từng việc:

Đặc tả: [TH-08](../requirements/TH-08-hoa-don-dien-tu.md). Chia PR theo [TH-08 mục 9.2](../requirements/TH-08-hoa-don-dien-tu.md#92-chia-pr-của-p7) (PR 7.1…7.5 ứng với việc 7.1…7.5 dưới đây; plan gom lại như bảng trên). Quyết định 2026-10-07: **giữ hành vi hiện có** (hàng đợi, đối soát nền, phát hành và gửi tự động, chống trùng) nhưng **bỏ** `apps/messaging_worker` (đã xoá 2026-10-11): mọi lệnh gọi MISA chuyển sang Edge Function `einvoice-processor` (TypeScript), kích hoạt bởi app và `pg_cron` mỗi 30 giây (TH-08 KI-20). UI e-invoice hiện tách giữa `modules/einvoice/presentation` và bản sao trong `features/sales` (KI-17).


| #   | Việc |
| --- | ---- |
| 7.1 | **DB**: ~~promote 23 file `supabase/migrations/_drafts/001…023` thành migration chính thức~~ — ✅ `8b08bb01c` (2026-11-02, KI-18); còn sửa `update_automation_policy` (KI-02), kiểm người mua trong `issue_invoice` / `retry_issuance` / `start_auto_issuance` (KI-04), chép lại trường người mua mỗi lượt (KI-06) — 7-B1 |
| 7.2 | **Thiết lập**: chuyển 4 màn vào `apps/erp/lib/features/einvoice/presentation`; `EInvoiceConfigurationRepository` (kết nối, mẫu, chính sách, sẵn sàng) gọi RPC `einvoice`; KI-01, 15, 16 — 7-A1 / 7-A2a / 7-B2 |
| 7.3 | **Trên đơn** (Theme 5 đã refactor xong: gắn vào màn chi tiết đơn **mới**): `OrderEInvoiceSection` + 2 cubit dùng repository; gộp các sheet về một chỗ; hỏi lại trạng thái bằng `Timer` trong cubit (bỏ `c45_async_query`, giữ hành vi); KI-08, 17 — 7-A1 / 7-A2b / 7-B2 |
| 7.4 | **Edge Function** `einvoice-processor`: viết lại client MISA bằng TypeScript (theo `packages/c45_misa`, chép 62 test sang Deno) và handler cho 9 loại lệnh `internal_commands` (đồng bộ mẫu, xem trước, phát hành + khóa ký hiệu, đối soát, bản chính thức, tải tài liệu, quan sát, gửi email, đối soát gửi) — 7-E1 / 7-E2a / 7-E2b / 7-E2c |
| 7.5 | **Kích hoạt**: `pg_cron` + `pg_net` gọi Edge Function mỗi 30 giây; trigger khi đơn Hoàn tất và khi hồ sơ khách đổi ghi thẳng `internal_commands` (thay outbox/inbox); trigger trên `electronic_invoices` xếp việc gửi tự động (KI-26) — 7-E3; app gọi `functions.invoke` sau mỗi RPC ghi yêu cầu — 7-A1 |


**Xong khi:** chỉ với Edge Function (không còn worker): kết nối MISA sandbox → phát hành từ đơn → xem/tải PDF → gửi email → gửi lại → phát hành lại sau lỗi; tự phát hành + tự gửi chạy khi bật, kể cả khi app đã đóng; MISA timeout thì `pg_cron` đối soát ra đúng một hóa đơn (TH-08 mục 9.3).

---


## Theme 7. Inventory — Kho & Giá vốn

**Trạng thái (2026-11-20):** 🔄 **Code + review xong cả 10 plan G5** (G5-0a … G5-8, G5-8 R3 2026-11-13: 709 test, `db_check` đạt). Còn: kiểm tay luồng demo trên Dev (tiêu chí 4 mục "Xong khi"), reset Dev `--linked`.

**Lịch sử:** 🔄 **Rút gọn phạm vi 2026-11-09** (người dùng chốt, vì hạn 2026-12-02): còn 10 plan G5 theo luồng demo chính (kho trống → chương trình NCC → nhận hàng có giá gốc + ưu đãi → bán / trả / huỷ qua Sales → kiểm kê → ghi nhận chiết khấu NCC → giá vốn & chốt kỳ → báo cáo tồn + lãi gộp). G5-0a ✅ (2026-11-09). G5-0b ✅ (2026-11-10). G5-2b ✅ (2026-11-10). **2026-11-10:** lấy lại CAP-01 (G5-2a, làm trước G5-2); plan G5-2a + G5-2 ✅ (duyệt cùng ngày). Code BJ-02 / 03 cũ (v4.6.8) giữ tới G5-3 thì xoá. **G5-3 ✅ (2026-11-11)**, đã xoá code BJ-02 / 03 cũ. 2026-11-11: thêm `tools/db_check.sh`; sửa fixture `inventory_core` / `stock_policy` / `stock_view` (role `store_owner`, `products.reference_id`, mỗi user làm chủ 1 tenant) ⇒ 6/6 tệp test SQL Kho xanh. Nợ ngoài Theme 7 ghi ở `tools/db_check_known.txt`: 4 hàm catalog / einvoice tham chiếu cột không có, 4 tệp test (`catalog_th02`, `einvoice_th08`, `pricing_th04`, `sales_th05`) đỏ.

> **Đã xong (bỏ khỏi bảng 2026-11-09):** T7-0 / T7-0b / T7-0c (Flutter BJ-02 / 03 theo prototype v4.6.8, commit `49967966e` — sẽ viết lại ở G5-3), T7-P0 (dọn prototype), T7-P (thiết kế lại trên prototype, đóng 2026-10-27, v5.26.1 — [plan](plans/T7/T7-P-thiet-ke-lai-luong.md) giữ để tra khuôn K1–K7, mục 5), T7-G4 (chốt đặc tả FROZEN v5.27.0, 2026-11-09). Prototype **v5.28.0 rút gọn** (2026-11-09, người dùng yêu cầu): chỉ còn 5 luồng app làm (bỏ cả tồn đầu kỳ), đã gỡ duyệt / nhập tệp / nhận theo chứng từ mua / tình trạng hàng / K3 (`?scope=full` hiện thêm luồng bỏ để tra cứu; xem CHANGELOG 5.28.0). Ảnh `proto-final` là của v5.27.0 ⇒ plan chụp lại màn đã đổi trước khi dùng làm đích. Bảng cũ (17 BJ, G5-0a…G5-17): `git show e5c9d4599:docs/refactor/PLAN.md`.

> **Thay tồn cơ bản của Theme 2 (chốt 2026-11-04, Q3 của 5-C; đổi plan 2026-11-09; đã làm ở G5-5, 2026-11-12):** G5-4 chuyển Sales sang sổ kho Theme 7; **G5-5** đã xoá SP-10 `product_stock_adjustment_page.dart`, route `/products/items/:productId/stock`, bảng/RPC tồn cơ bản (`product_stock_profiles`, `product_stock_movements`, `set_basic_stock_quantity_base`, `adjust_basic_stock`, `get_product_stock_history`) và bước nhập tồn khi tạo sản phẩm; thẻ Tồn kho ở PCC chỉ xem và mở `/warehouse/stock/:productId`; readiness bỏ `missing_stock` / `pendingStockFromInventory`.

> Nguồn: [`specs/themes/theme-07`](../../specs/themes/theme-07/README.md) **v5.27.0 FROZEN** — từ 2026-11-09 là **tài liệu tham khảo**: chỉ các BJ / màn trong bảng Plan dưới đây được làm, và làm theo bản rút gọn (bỏ duyệt, bỏ xác minh…); chỗ app khác spec ghi vào báo cáo đồ án, không sửa spec. Prototype `03.design/prototype/html` v5.26.1 (đối chiếu hình ảnh); [T7-P](plans/T7/T7-P-thiet-ke-lai-luong.md) mục 5 (khuôn K1, K4, K6, K7), 6 (DS mới). [TH-07](../requirements/TH-07-kho.md) chỉ là con trỏ. Vai trò: Claude viết plan và review, bạn tự code.

### Rút gọn 2026-11-09 (người dùng chốt)

Lý do: phạm vi 17 BJ + CAP-01, 70 màn, quá lớn so với thời gian còn lại tới hạn và với một đồ án tốt nghiệp. Giữ luồng một cửa hàng thú y dùng hằng ngày, có lô + HSD và giá vốn; phần bỏ ghi vào báo cáo là "hướng phát triển".

**Bỏ — chức năng (BJ):**

| Bỏ | Thay bằng |
|---|---|
| BJ-04 Giữ hàng, BJ-05 Lấy hàng & bàn giao (K6 dựng ở đây) | Thanh toán đơn ⇒ xuất kho ngay (G5-4). K6 đã có ở G5-0a, dùng cho danh sách phiên kiểm kê nếu cần |
| BJ-06 màn Hàng khách trả | Đơn trả / đổi hàng của Sales ⇒ nhập lại kho tự động (G5-4), không có màn kho riêng |
| BJ-07 Trả nhà cung cấp | — |
| BJ-09 Tình trạng hàng (cách ly / hỏng) + khuôn K5 | — (không có tình trạng hàng; hàng hỏng / hết hạn xử lý bằng điều chỉnh có lý do ở G5-5) |
| BJ-10 Tiêu hủy | Đã thay bằng lý do trên dòng thiếu (G5-5, 2026-11-12): điều chỉnh giảm có lý do "Thất thoát" / "Hỏng" / "Hết hạn" |
| BJ-11 Hủy & sửa sai chứng từ | — (phiếu đã ghi không sửa; sai thì kiểm kê điều chỉnh) |
| BJ-13 Điều chỉnh giá trị hàng nhập | Chi phí thu mua / chiết khấu thương mại nhập ngay trên phiếu nhận, phân bổ vào dòng (G5-3); không điều chỉnh sau khi ghi — **trừ** chiết khấu NCC đạt mốc có chứng từ (G5-5b, spec giá vốn mục 12) |
| BJ-14 phần nhiều phạm vi chốt, giá tham chiếu định giá bán | — (BJ-14 còn lại **làm**, xem "Giá vốn") |
| BJ-16 Đối soát, BJ-17 Xác minh UNKNOWN | — |
| ~~CAP-01 Chính sách tồn & cận hạn~~ | **Lấy lại 2026-11-10** (người dùng) ở **G5-2a**, bản rút gọn: ngưỡng cảnh báo + mức tồn mục tiêu theo sản phẩm; cận hạn = số ngày mặc định (không có giá trị sẵn — chưa đặt thì không đánh dấu cận hạn) + riêng theo sản phẩm, **chỉ cảnh báo** (bỏ "Chặn bán"); bỏ SCR-065 / `LOCKED`. Không có cột `min_stock` ở Theme 2 |

**Bỏ — cơ chế dùng chung:**

| Bỏ | Thay bằng |
|---|---|
| K2 lập → duyệt (ApprovalCase, màn "Chờ duyệt" của Hub, SCR-011 / 046 / 070 duyệt) | Ghi nhận thẳng sau bước rà soát; chỉ kiểm quyền |
| K3 kết quả chưa rõ (nhật ký lệnh, `get_command_outcome`, nút "Chuyển sang xác minh") | Khoá idempotency trên phiếu (gửi lại cùng khoá không ghi hai lần); mất mạng ⇒ báo lỗi + "Thử lại" (cùng khoá) |
| Kích hoạt kho | Kho chưa có biến động ⇒ Hub hiện "Kho chưa có hàng" + "Lập phiếu nhận" |
| **BJ-12 Khởi tạo tồn đầu kỳ** (chốt 2026-11-09, sau rút gọn) | **Bỏ.** Kho bắt đầu trống; hàng vào kho lần đầu qua phiếu nhận (G5-3). Tồn cơ bản Theme 2 **không** chuyển sang sổ kho (bỏ khi G5-5) |
| BJ-02: nhập nhanh riêng, đối soát, duyệt khi nhận vượt, ảnh bằng chứng, chia "Đạt / Cách ly / Hỏng / Từ chối" | Một phiếu nhận: nhà cung cấp, số chứng từ, dòng (sản phẩm, lô, HSD, số lượng, giá nhập) |
| Q8 rà / đổi domain DRAFT → FROZEN | Không sửa spec; chỗ lệch ghi báo cáo |

**Rút gọn quy trình UI (thay bước 5–6 cũ):** chép code prototype cho **màn chính** của mỗi plan; so ảnh **trạng thái chính** (iPhone 390 + web 1280); widget test trạng thái chính + lỗi chính (không phủ mọi trạng thái Screen Contract).

**Ảnh hưởng tới việc đã làm:**

- **G5-0a ✅:** ẩn / xoá màn "Chờ duyệt" (`/warehouse/approvals`) và nguồn "Chờ duyệt" của Hub; gỡ lối vào Hub của BJ bị bỏ khỏi `warehouse_entries.dart` (không để `route: null` chờ). Làm ở G5-0b (Task Hub).
- **G5-0b (plan ✅, đã code Task 0–2):** sửa plan trước khi code tiếp — bỏ Task 5 (duyệt K2, `approval_cases`, `_open_approval`, RPC duyệt), bỏ kích hoạt kho + `get_command_outcome` / UNKNOWN ở Task 3 / Task 6 (giữ khoá idempotency), RPC tóm tắt Hub bỏ phần chờ duyệt; **thêm giá vốn** vào lõi theo [spec giá vốn](plans/T7/T7-G5-gia-von-thiet-ke.md) mục 3–4: **giữ** `value_movements` (dạng mới, có dòng điều chỉnh), `product_costs` theo tổ chức + sản phẩm (giá trị sổ, bình quân liên hoàn, giá chính thức), `cost_policies`, `cost_periods`, `cost_versions`; `_post_movements` ghi dòng giá trị theo phương pháp, chặn `PERIOD_CLOSED`; bỏ chiều tình trạng hàng / trạng thái định giá (Q-b11 của plan). Mã lỗi lõi bỏ các mã chỉ dùng cho duyệt / xác minh / kích hoạt. ~~Cột `min_stock` (tồn tối thiểu) làm ở G5-2~~ — thay bằng CAP-01 ở G5-2a (2026-11-10). Plan G5-0b đã sửa theo các điểm này (duyệt 2026-11-09), **phần giá vốn sửa lại theo spec** (duyệt 2026-11-09); Task 0–2 đã commit, phần thừa / đổi làm ở Task 2b.

### Giá vốn (chốt 2026-11-09, làm kỹ — trọng tâm báo cáo)

Thiết kế đầy đủ: [spec giá vốn](plans/T7/T7-G5-gia-von-thiet-ke.md) (người dùng duyệt từng phần trong chat 2026-11-09). Thay bản "chỉ bình quân liên hoàn" ghi sáng cùng ngày.

| # | Quyết định |
|---|---|
| GV-1 | Trọng tâm: **nghiệp vụ kế toán đúng chuẩn** (VAS 02, TT 200 / 133), chứng minh bằng công thức, ví dụ số, test |
| GV-2 | **Cửa hàng chọn phương pháp** bình quân liên hoàn / bình quân cuối kỳ (đổi chỉ trước lần công bố đầu); mỗi lần tính luôn tính **cả hai** để đối chiếu; chốt kỳ theo tháng + cập nhật giữa kỳ |
| GV-3 | **Giá gốc trên phiếu nhận:** giá mua trước thuế + chi phí thu mua − chiết khấu thương mại, phân bổ theo giá trị dòng |
| GV-5 | **Ưu đãi nhà cung cấp** (spec mục 12, chốt 2026-11-09 theo yêu cầu giáo viên hướng dẫn): (1) giảm giá theo bậc số lượng trên phiếu → giảm ngay giá gốc; (2) mua X tặng Y cùng sản phẩm → tiền mua chia cho SL mua + tặng; (3) chiết khấu đạt mốc **số lượng tích luỹ, không hạn thời gian** → có chứng từ mới ghi, phần tồn giảm giá trị tồn, phần đã bán giảm giá vốn (TT 200). Kèm tiến độ, giá vốn dự kiến (không ghi sổ), so sánh NCC |
| GV-6 | **Giá gốc gồm VAT đầu vào** (hộ kinh doanh không khấu trừ, KB-KGV-019 mục 5) |
| GV-4 | **Tính lại từ sổ:** lần tính bất biến tới mốc chốt (`ledger_sequence`) → rà soát → công bố một giao dịch (ghi dòng điều chỉnh liên kết, phiên bản giá chính thức mới, khoá kỳ); không sửa dòng sổ cũ |

Phạm vi giá: tổ chức + sản phẩm (không theo kho / lô). Trong kỳ: nhập theo giá gốc; xuất theo bình quân liên hoàn (`MOVING`) hoặc giá chính thức đang hiệu lực (`PERIODIC`, chưa có thì "giá tạm"). Lúc công bố: điều chỉnh giá vốn hàng bán / hao hụt / làm tròn chỉ ghi phần chênh. Kiểm cân bằng: đầu đoạn + nhập = xuất đã điều chỉnh + tồn cuối.

> **Ghi chú G5-7 (đã chốt ở G5-6):** mốc chốt kỳ tính theo tháng (D1: `period_month` đầu tháng); các dòng điều chỉnh `COGS_TRUE_UP` / `LOSS_TRUE_UP` ghi vào `value_movements` với dấu giảm/tăng giá trị tồn (D5: báo cáo lãi gộp G5-7 đọc với dấu `−amount`).
> **Ghi chú G5-7 (làm xong):** giá trị 055 / 056 = giá trị sổ (lệch SCR-055 §6); bỏ xuất tệp, công tắc loại ngày, sửa sai (Q-7-3, Q-7-4 của plan G5-7) — ghi báo cáo đồ án.

### Đã chốt (người dùng, 2026-11-09 — trước khi rút gọn; còn hiệu lực trừ chỗ ghi "đổi")

| Q | Quyết định |
|---|---|
| Q1 | **Viết lại BJ-02 / BJ-03 theo v5.27** (đổi: gộp vào G5-3, bản rút gọn). Giữ model / luật thuần còn đúng (vd. `LotDate`, `formatQuantity`); xoá page / cubit / repository cũ khi màn mới thay |
| Q2 | Chia plan: nền + mỗi chặng một plan (đổi: 8 plan, bảng Plan) |
| Q3 | **Bố cục web làm trong cùng plan** (không có plan `-W` riêng): mỗi màn dựng iPhone + web một lần |
| Q4 | **Mỗi plan kèm luôn backend**: migration (bảng, RLS, RPC), repository gọi RPC thật, UI, test. Không có plan `T7-B*` riêng |
| Q5 | **Backend lõi dùng chung dựng ở G5-0b** (đổi: sổ biến động, tồn theo lô + giá vốn, phiếu kho chung, idempotency, kiểm quyền; bỏ ApprovalCase, nhật ký lệnh UNKNOWN) |
| Q6 | **Dữ liệu: RPC thật, không seed.** Widget test dùng fake repository. Dữ liệu demo người dùng tự tạo qua app (kho trống → nhận hàng → bán …) |
| Q7 | **Nối kho Sales ở G5-4** (đổi: gộp G5-7 + G5-8 cũ): checkout → xuất kho FEFO (`BC-IO-04`, không giữ hàng / bàn giao), huỷ đơn → hoàn nguyên (`BC-IO-13`), khả dụng khi chọn sản phẩm (`BC-IO-01`, thay tồn cơ bản trong `search_sellable_products`), đơn trả / đổi → nhập lại (`BC-IO-07`, không màn kho). 6 kịch bản Theme 5 (bán thường, bán nợ rồi thu sau, hoàn tiền, huỷ đơn, đổi hàng, trả hàng) cho tồn + giá vốn đúng theo sổ kho là tiêu chí của G5-4 |
| Q8 | ~~Rà / FROZEN domain~~ — **bỏ** (rút gọn 2026-11-09) |
| Q9 | **Home Kho dựng khung ở G5-0a**, mỗi plan tự gắn lối vào (bảng lối vào của Hub) và nguồn "Cần chú ý". Lối vào chưa có màn thì **ẩn**; lối vào của BJ bị bỏ thì **gỡ** |

Quyết định cũ vẫn giữ: danh tính người dùng lấy từ phiên thật (`SessionStore.userId`, `isOwner`); `features/inventory/` là của Theme 7; 5-A4 chỉ chuyển cổng cặp mặc định sang `DefaultPairRepository` (không dùng tên `InventoryRepository`).

### Plan

Thứ tự = luồng demo (không seed: phải khởi tạo tồn trước mới nhận / bán / kiểm kê được). Không ghi ước lượng ngày (2026-11-09: người dùng bỏ; theo dõi bằng tiến độ từng plan).

| Plan | Nội dung | Màn (Screen Contract) | Phụ thuộc | Plan | Làm | Review |
|---|---|---|---|---|---|---|
| **G5-0a** | UI nền: DS mới, khuôn K1–K4 / K6 / K7, Home Kho, route `/warehouse`, xoá `WarehouseHomePage` v3.8 | 090…096 | W-1 ✅ | ✅ plan (đã xoá) | ✅ 2026-11-09 | ✅ R2 đạt (2026-11-09) |
| **G5-0b** | Backend lõi (bản rút gọn): kho / lô / sổ biến động chỉ thêm / tồn + khả dụng + **sổ giá trị + luật giá theo phương pháp** (spec giá vốn mục 3–4), `_post_movements` (khoá, chặn tồn âm), phiếu kho chung + khoá idempotency, quyền + che tài chính, RPC tóm tắt Hub; lớp RPC Flutter; ô gạt "Quản lý theo lô" ở Theme 2; gỡ "Chờ duyệt" / K2 / K3 / lối vào BJ bị bỏ khỏi Hub | — | G5-0a (Task Hub) | ✅ plan (đã xoá) (rút gọn + spec giá vốn, duyệt 2026-11-09) | ✅ 2026-11-10 | ✅ R3 đạt (2026-11-10; còn nợ chạy test SQL) |
| ~~G5-1~~ | ~~BJ-12 Khởi tạo tồn đầu kỳ~~ — **bỏ** (2026-11-09: kho bắt đầu trống) | — | — | — | — | — |
| **G5-2a** | **CAP-01 Chính sách tồn & cận hạn** (lấy lại 2026-11-10): bảng chính sách + RPC đọc / lưu (chủ cửa hàng, `revision`), helper tồn + cờ hết hạn / cận hạn theo sản phẩm (`_product_stock_rows`, G5-2 / G5-4 / Hub dùng), luật chỉ báo Flutter; màn 062 (bảng sửa tại dòng / một sản phẩm) + 063 (cận hạn, chỉ cảnh báo); `K7EditCell`; Hub "Thiết lập kho" | 062, 063 | G5-0b | ✅ plan (đã xoá) (duyệt 2026-11-10) | ✅ 2026-11-10 | ✅ R3 đạt (2026-11-10; còn nợ chạy test SQL) |
| G5-2 | BJ-01 Tồn kho & khả dụng (theo lô, HSD, khả dụng = tồn lô còn hạn, giá vốn chỉ chủ cửa hàng) + "Đặt / Sửa ngưỡng" mở G5-2a + "Cần chú ý" Hub (hết hàng, tồn thấp, hết hạn, cận hạn); bỏ nút quét mã vạch (ô tìm khớp mã vạch) | 001, 003 | G5-0b, G5-2a | ✅ plan (đã xoá) (duyệt 2026-11-10) | ✅ 2026-11-10 | ✅ R2 đạt (2026-11-10; còn nợ P3 + chạy test SQL) |
| **G5-2b** | **Chương trình nhà cung cấp** (spec giá vốn mục 12.1–12.3, 12.6–12.7): bảng chương trình (3 loại), RPC tạo / sửa / kết thúc / danh sách / chi tiết / tuỳ chọn form / gợi ý cho dòng phiếu; màn P1 danh sách, P2 tạo / sửa, P3 chi tiết (chưa ghi nhận); khối "Chương trình ưu đãi" ở chi tiết NCC Theme 3 (~~"Lịch sử nhập hàng"~~ dời sang G5-3, 2026-11-10); lối vào Hub; đối tác hệ thống "Mua lẻ / khác" cho mỗi tenant (`partners.is_system`, chặn ở `_lock_partner`). Ưu đãi gắn cặp **NCC + sản phẩm**, chỉ áp cho phiếu cùng NCC; **mỗi NCC tối đa 1 chương trình đang hiệu lực**; **không chia quyền** chủ cửa hàng / nhân viên (chốt 2026-11-10). **Không có prototype** ⇒ plan vẽ khung ASCII | P1, P2, P3 | G5-0b | ✅ plan (đã xoá) (duyệt 2026-11-10) | ✅ 2026-11-10 | ✅ R2 đạt (2026-11-10; còn nợ P3 + chạy test SQL) |
| G5-3 | BJ-02 Nhận hàng **gộp BJ-03** (giá mua ở từng dòng) — một phiếu: nhà cung cấp (**bắt buộc**; mua lẻ chọn "Mua lẻ / khác"), số chứng từ, dòng, **chi phí thu mua + chiết khấu thương mại phân bổ ra giá gốc** (spec giá vốn mục 4.1) + **ưu đãi NCC trên dòng** (bậc giảm giá, SL tặng, cộng tiến độ chương trình đạt mốc → `REACHED`; mục 12.3), rà soát có bảng phân bổ, kết quả; xem lại phiếu đã ghi; khối **"Lịch sử nhập hàng"** ở chi tiết NCC Theme 3 (dời từ G5-2b); mở rộng `_program_is_locked` (dòng phiếu có `program_id`). **Xoá code BJ-02 / 03 cũ** | 007, 008, 009, 084, 010, 012 | G5-0b, G5-2b | ✅ plan (đã xoá) (duyệt 2026-11-10) | ✅ 2026-11-11 | ✅ R4 đạt 2026-11-11 (SQL `inventory_goods_receipts.sql` + `inventory_supplier_programs.sql` xanh trên `db reset`; nợ P3 R3-2) |
| G5-4 | **Nối Sales** (Q7): xuất kho FEFO (**bỏ qua lô hết hạn** — `_lot_expiry_end` của G5-2a; khả dụng khi bán = `available` của `_product_stock_rows`) + dòng đơn lưu **giá vốn, phiên bản giá, cờ giá tạm** khi thanh toán, huỷ / trả cùng đoạn → `SALE_REVERSAL`, trả hàng của đoạn đã công bố → `RETURN_IN`, khả dụng khi chọn sản phẩm; test giữ hành vi 6 kịch bản Theme 5 | màn Sales (không màn kho mới) | G5-2 | ✅ plan (đã xoá) (duyệt 2026-11-11) | ✅ 2026-11-11 | ✅ R4 đạt (2026-11-11; Dev cần reset --linked) |
| G5-5 | BJ-08 Kiểm kê (tạo phiên, đếm, chênh lệch, ghi nhận thẳng) + **điều chỉnh có lý do** (hỏng / hết hạn / thất thoát — thay BJ-10; định giá theo phương pháp, điều chỉnh vào **hao hụt**, phiên kiểm kê mở chặn lần tính giá vốn) + **bỏ tồn cơ bản Theme 2** (SP-10, bảng / RPC; ghi chú "Thay tồn cơ bản" ở đầu mục) | 042, 043, 044, 045, 047 | G5-2, G5-4 | ✅ plan (đã xoá) (duyệt 2026-11-11) | ✅ 2026-11-12 | ✅ R2 đạt 2026-11-12 |
| **G5-5b** | **Ghi nhận chiết khấu NCC & so sánh NCC** (spec giá vốn mục 12.4–12.7): RPC xem trước / ghi nhận chiết khấu đạt mốc (phân bổ phần tồn / phần đã bán), giá vốn dự kiến, so sánh NCC; màn P4 ghi nhận, P5 so sánh, khối "Giá vốn dự kiến" + nút ghi nhận ở P3; "Cần chú ý" Hub | P4, P5 | G5-2b, G5-4 | ✅ plan (đã xoá) (duyệt 2026-11-12) | ✅ 2026-11-12 (Dev cần reset `--linked`) | ✅ R2 2026-11-12 |
| **G5-6** | **BJ-14 Giá vốn & chốt kỳ** ([spec giá vốn](plans/T7/T7-G5-gia-von-thiet-ke.md) mục 5–7): `cost_runs` / `cost_run_lines`; RPC tổng quan, đổi phương pháp, tạo / xem / công bố / bỏ lần tính, lịch sử phiên bản; chốt kỳ + cập nhật giữa kỳ; điều kiện chặn, lần tính cũ; xử lý dòng `SUPPLIER_REBATE`; 17 kịch bản `supabase/tests/inventory_costing.sql` | 072, 074, 077 | G5-3, G5-4, G5-5, G5-5b | ✅ plan (đã xoá) (duyệt 2026-11-12) | ✅ 2026-11-12 | ✅ R3 đạt 2026-11-12 |
| G5-7 | BJ-15 Báo cáo nhập – xuất – tồn / thẻ kho (giá trị sổ) + chi tiết biến động ("Mở phiếu gốc") + **báo cáo lãi gộp** (theo sản phẩm theo kỳ: giá vốn lúc bán + điều chỉnh − chiết khấu NCC; theo đơn: giá vốn lúc bán; hao hụt dòng riêng) + báo cáo nhập hàng theo NCC (SL mua / tặng, giá gốc) | 055, 056 | G5-6 | ✅ plan (đã xoá) (duyệt 2026-11-13) | ✅ 2026-11-13 (Dev cần reset `--linked`) | ✅ R2 đạt 2026-11-13 |
| G5-8 | Rà cuối: bảng màn → route → test, luồng demo, không còn lối vào trỏ BJ bị bỏ, tương phản / vùng chạm / `Semantics`, quét chuỗi giả | toàn Theme | tất cả | ✅ plan (đã xoá) (11 phần) | ✅ 2026-11-13 | ✅ R3 2026-11-13 (709 test, `db_check` đạt) |

Tổng: 18 màn BJ + 5 màn NCC (P1–P5, ngoài spec Theme 7) + 7 màn Hub (từ 70). Màn bỏ (Screen Contract vẫn FROZEN trong spec, app không dựng): 014, 015, 019, 021, 025…035, 036…041, 046, 048…053, 011, 013, 059, 062…065, 066…071, 078, 079, 081…083, 085…089.

Plan con: `docs/refactor/plans/T7/T7-G5-<mã>-<slug>.md`, viết bằng `superpowers:writing-plans`, đi trước phiên làm code đúng một plan. Plan đã làm + review xong thì xoá tệp (như mọi plan).

### Quy ước chung cho mọi plan G5

Mọi plan G5 trỏ về mục này trong "Global Constraints" và chỉ ghi phần riêng của plan.

#### Cấu trúc code

| Lớp | Chỗ | Quy ước |
|---|---|---|
| Thành phần DS chung (không mang nghĩa Kho) | `packages/c45_design_system/lib/src/{components,primitives,forms}/` + export ở `design_system.dart` | Thêm khi plan con đầu tiên cần (bảng "Thành phần DS mới"); có test trong `packages/c45_design_system/test/` |
| Khuôn K1, K4, K6, K7 (mang nghĩa Kho) | `apps/erp/lib/features/inventory/presentation/patterns/` | Đã dựng ở G5-0a. K2 / K3 dựng ở G5-0a **không dùng nữa** (rút gọn): plan đầu tiên đụng tới thì xoá nếu không còn chỗ gọi |
| Hub Kho | `features/inventory/presentation/hub/`, `logic/warehouse_hub_*` | G5-0a |
| Một BJ | `features/inventory/{data,logic,presentation}/<bj>/` (vd. `data/opening_balance/`) | Model + luật thuần (`logic/<bj>/<x>_rules.dart`) có unit test; repository một class, mỗi phương thức gọi **đúng một RPC**; Cubit; Page dựng theo "Thứ bậc thông tin" của Screen Contract (bỏ phần thuộc cơ chế đã bỏ) |
| Lỗi | `features/inventory/data/inventory_rpc_errors.dart` (G5-0b) | Mã lỗi server → `AppException`; câu hiển thị theo Screen Contract; không hiện `e.toString()` |
| SQL | `supabase/migrations/2026MMDDnnn_inventory_<bj>.sql` | Sửa thẳng migration gốc tới khi lên Prod (không tạo bản ghi đè). **Đổi 2026-11-11 (sau G5-3):** plan có bước chạy **`tools/db_check.sh`** (reset DB local → `plpgsql_check` mọi hàm → chạy mọi `supabase/tests/*.sql`; thoát 1 khi có lỗi mới; nợ đã biết ở `tools/db_check_known.txt`; chỉ một tệp: `tools/db_check.sh --no-reset <tên>`); phiên làm chạy trước khi báo xong, review chạy lại, phải ✅ mới commit. Reset Dev (`--linked`) vẫn hỏi người dùng. Khi plan mô tả JSON RPC trả về, ghi rõ **khoá ← bảng.cột nguồn** (vd. `code ← products.sku`, `base_uom ← catalog._product_base_unit_name(…)`, `name ← product_units.unit_name`) |
| Test SQL | `apps/erp/test/features/inventory/data/<bj>_sql_contract_test.dart` + `supabase/tests/inventory_<bj>.sql` | Test hợp đồng đọc tệp migration, kiểm có hàm / RLS / `security definer` / kiểm quyền / mã lỗi (cùng kiểu `sales_sql_contract_test.dart`) — **không** bắt được tên cột sai (thân plpgsql chỉ phân giải lúc chạy; G5-3 lọt 5 bảng sai cột qua 3 vòng review). Vì vậy tệp `supabase/tests/*.sql` phải **chạy xanh** qua `tools/db_check.sh` mới tính xong (bước `plpgsql_check` bắt tên cột sai kể cả nhánh test không chạy tới); fixture chép khuôn `inventory_goods_receipts.sql` (role `store_owner` + `is_owner`, `products.reference_id`, `store_warehouse_assignments`) |
| Mẫu RPC ghi | `supabase/migrations/` | Mỗi RPC ghi một phiếu kho / nghiệp vụ gọi `_post_movements` (mục 2.3 của spec lõi). Giá vốn: chỉ qua `_post_movements` (→ `_value_line`); vào kho truyền `unit_cost` / `amount_vnd`, ra kho lấy `lines[]` trả về (đơn giá, số tiền, phiên bản, cờ giá tạm) |

#### Review plan có SQL (chốt 2026-11-11, sau G5-3)

- Chạy `tools/db_check.sh` (reset + `plpgsql_check` + mọi tệp test SQL, gồm tệp của plan trước); dán phần kết quả vào mục Review. Fixture lỗi thì đối chiếu `information_schema.columns`.
- Mục `### Rn` chỉ phiên review ghi; phiên làm ghi "Kết quả" / "Sửa sau Rn".

#### Điều hướng

- Hub `/warehouse`, khu `/warehouse/area/:areaId`: trong nhánh tab "Thêm" (iPhone có thanh 5 tab, web có thanh bên). `/inventory` chuyển hướng sang `/warehouse` (G5-0a). `/warehouse/approvals` bỏ (rút gọn).
- Màn trong luồng BJ: `GoRoute` con của `ShellRoute(StoreShell)`, **ngoài** `StatefulShellRoute` ⇒ web có thanh bên, iPhone không có thanh tab (PAT-NAV mục 5). Đường dẫn `/warehouse/<bj-slug>/…`, có id trên URL cho màn chi tiết.
- Màn kết quả K4 trên iPhone hiện thanh 5 tab (`K4ResultPage` tự gắn, G5-0a).
- Màn đầu luồng mở từ Hub: nút quay lại "Quay về Kho". Sau khi ghi nhận: màn kết quả không có nút quay lại.

#### Mỗi plan BJ gồm (thứ tự task)

1. **SQL:** migration bảng + RLS + RPC (gọi `_post_movements` của lõi); test hợp đồng SQL.
2. **Repository + model + luật thuần:** chữ ký theo RPC; unit test luật.
3. **Cubit + Page từng màn:** trạng thái chính + lỗi chính có nhánh dựng và widget test (cả hai bề rộng khi khác bố cục). Chữ trên màn chép **nguyên văn** mục 8 của Screen Contract (bỏ câu thuộc cơ chế đã bỏ).
4. **Điều hướng:** route; đăng ký lối vào Hub (`warehouse_entries.dart`) + nguồn "Cần chú ý" nếu có; lối vào ngữ cảnh (PAT-NAV mục 3).
5. **Luồng đầu–cuối:** một test đi hết luồng chính trên fake repository.
6. **Đối chiếu prototype:** so ảnh prototype với ảnh Flutter của **trạng thái chính** (mục "UI Flutter" bước 5); ghi lệch vào Kết quả.
7. **Kết quả** (mẫu "Cách làm việc") + **Review** (phiên review ghi).

Mỗi plan có mục "Quyết định" (câu hỏi đã chốt với người dùng) và "Review Focus". Plan xoá / thay code đang chạy có bảng "Đang làm gì" + bước 0 test giữ hành vi (PLAN.md "Cách làm việc").

#### UI Flutter: trích code prototype vào plan (chốt 2026-11-09, rút gọn cùng ngày)

Lý do: UI Flutter làm từ Screen Contract và mô tả bằng lời lệch prototype nặng (G5-0a R1: chevron đôi, tiêu đề thừa, giá trị tràn, đo badge sai). Phiên code không được tự đoán bố cục. Áp cho **mọi plan có màn Flutter**:

1. **Plan chép nguyên văn code prototype của màn chính** (mỗi màn trong cột "Màn" của bảng Plan) vào task dựng màn, trong khối ```` ```js ```` / ```` ```css ````, kèm `tệp:dòng`: hàm render + hàm con, luật CSS của class màn dùng (gồm `@media` web), biến `var(--…)` tra ra giá trị ở `styles/tokens.css`. Trạng thái phụ (rỗng, lỗi, không có quyền) dùng khuôn K1, không chép code.
2. **Bảng ánh xạ phần tử → Flutter** ngay dưới code: mỗi phần tử HTML một dòng: widget DS / khuôn K, tham số, token với giá trị px của CSS. Giá trị CSS không có token: ghi số và lý do. Phần tử prototype thuộc phần đã bỏ (duyệt, xác minh, tình trạng hàng…) ghi "bỏ — rút gọn".
3. **Thứ tự, chữ, điều kiện hiện / ẩn lấy từ code prototype**. Screen Contract mục 8 dùng để kiểm chữ; lệch nhau thì hỏi người dùng lúc viết plan.
4. **Phiên code dựng theo bảng ánh xạ**, không thêm phần tử ngoài bảng. Cần lệch thì ghi "Lệch plan + lý do" ở Kết quả.
5. **Đối chiếu bằng ảnh, trạng thái chính**: ảnh prototype ở `specs/themes/theme-07/03.design/prototype/html/tools/proto-final/{iphone,web}/` (không vào git) ⇒ lúc viết plan **chép ảnh trạng thái chính** sang `docs/refactor/plans/T7/img/<plan>/` (`proto-<SCR>-<trạng thái>-390|1280.png`). Phiên code thêm ảnh Flutter (`matchesGoldenFile`, cùng bề rộng) tên `flutter-…` cạnh đó; review so ảnh trước khi đọc code. Plan xoá thì xoá luôn `img/<plan>/`.

#### Thành phần DS mới (T7-P mục 6) → plan dựng

Flutter đã có sẵn: `VSegmentedControl`, `VProgress`, `VFileDropZone`, `VCheckbox`, `VNumberField`, `VMoneyField`, `VTable`, `VSearchBar(suffix)`, `VBadge(showDot)`, `VChoiceList`. Plan con chỉ **mở rộng** khi thiếu.

| Thành phần (T7-P mục 6) | Flutter | Plan |
|---|---|---|
| `VListRow`, `VQuickActionButton`, `VChip.count`, `VKeyValueRow` / `VKeyValueGroup` (`mono`), `VTable.onRowTap`, `InventoryReasonFooter` | — | G5-0a ✅ |
| Dải số một hàng (`cf12Strip`) | mới `VSummaryStrip` | G5-3 |
| `VMoneyField` trạng thái lỗi | đã có `errorText` (kiểm lúc viết plan G5-3) | — |
| Ô hạn dùng tự hiểu độ chính xác | `InventoryExpiryField` ở `features/inventory/presentation/patterns/` (dùng `LotDate`; gói DS không phụ thuộc app — plan G5-3) | G5-3 |
| Ô số sửa tại dòng (`k7EditCell`) | `K7EditCell` (patterns, bọc `VNumberField`, hậu tố ĐVT) | G5-2a (dời từ G5-5) |
| `ds24DotBadge` (chấm đặc / rỗng) | thêm kiểu chấm rỗng vào `VBadge` | G5-2 |
| `VStockRow` (cột phải hai tầng) | mới `VStockRow` | G5-2 |
| Nút quét mã vạch trong ô tìm | **không dựng** (2026-11-10: chưa có gói camera; ô tìm khớp mã vạch) | — |
| Khối "Tóm tắt" + dải tổng | `VKeyValueGroup` + `VSummaryStrip` | G5-3 |
| Ô số nhập thẳng tại dòng, Enter sang ô kế tiếp | `VNumberField` + `textInputAction.next` | G5-5 |
| Nút chữ nguy hiểm | kiểm `VButton` (variant text + tone danger); thêm nếu thiếu | G5-5 |
| Vùng kéo thả tệp, ảnh bằng chứng (`InventoryEvidenceField`), ô "Đạt / Cách ly / Hỏng / Từ chối", ô tick trong bảng, thẻ lựa chọn lớn (`dsChoiceRow`), `VNumericKeypadSheet` | **không dựng** (rút gọn) | — |

#### Đề xuất G3-7 đã ghi vào Screen Contract (T7-P mục 13, Flutter làm)

| Đề xuất | Plan |
|---|---|
| U5: K4 thêm dòng "Tồn kho đã đổi: {sản phẩm} {trước} → {sau}". Server trả tồn vật lý trước / sau trong kết quả RPC ghi nhận (`stockChanges`, T7-G4 1a) | khuôn ở G5-0a ✅; dữ liệu ở G5-3, G5-5 |
| "Tóm tắt" lặp thẻ chính (SCR-011) | G5-3 |
| Dòng K6 iPhone: badge xuống dưới tiêu đề khi tiêu đề gãy hai dòng | G5-0a ✅ |
| Số tiền mono ở thẻ số liệu / "Tóm tắt" | `VKeyValueRow(mono:)` G5-0a ✅; mọi plan dùng |

### Việc còn treo của T7-P / T7-G4 → plan

| Việc (nguồn) | Xử lý |
|---|---|
| Gom CSS theo BJ / bỏ `!important` (G3-1); review gói G3-1 … G3-7 | **Bỏ** (prototype không còn là nguồn; thay bằng bước đối chiếu ảnh của từng plan + G5-8) |
| Vùng ảnh bằng chứng (G3-2); fixture lô Amox / Nobivac (G3-4); sổ kho tĩnh `SC_demo` | **Hết việc** (rút gọn / Q6 không seed; BJ-01, BJ-15 cùng đọc sổ biến động thật) |
| T7-G4 1a: kết quả RPC ghi nhận trả tồn vật lý trước / sau | G5-3, G5-5 (`stockChanges`) |
| Toast nút đóng 20 × 20; dòng bảng web chưa có `role`; bẫy focus sheet | Flutter: `VToast`, `VTable.onRowTap` (G5-0a), `showVAdaptiveSheet` |
| `onUnknownResolved` / quay lại sau xác minh | **Bỏ** (K3 / BJ-17 bỏ) |
| BJ-02 chưa có màn xem phiếu đã nhận → BJ-15 "Mở phiếu gốc" | Xem lại phiếu đã ghi: bố cục SCR-010 chỉ đọc ở G5-3 (SCR-011 bỏ ở prototype v5.28.0); G5-7 nối "Mở phiếu gốc" |
| `README.md` theme dòng 131 còn ghi "v5.0.0" | G5-0b |
| SP-10 tồn cơ bản | G5-5 (hỏi người dùng nút "Sửa" thẻ Tồn kho của PCC và mục readiness `missing_stock` mở màn Theme 7 nào) |

### Rủi ro riêng

| Rủi ro | Cách xử lý |
|---|---|
| **Quá hạn** 2026-12-02 dù đã rút gọn | Theo dõi sau mỗi plan con; plan con viết đi trước một bước để phiên code không chờ. Cần cắt thêm thì ưu tiên giữ G5-0b → G5-4 → **G5-6** (luồng demo bán hàng có tồn + giá vốn + chốt kỳ), rồi G5-2b / G5-5b (ưu đãi NCC — giáo viên yêu cầu); G5-5 / G5-7 rút gọn trước |
| Backend lõi (G5-0b) thiết kế sai làm vỡ các plan sau | G5-0b bám AGG / ENT / BC của spec (phần còn giữ); plan sau được mở rộng bảng lõi (sửa migration gốc) nhưng phải ghi vào Kết quả |
| Giá vốn sai (xuất / trả / kiểm kê / chốt kỳ / làm tròn) | Luật giá tách hàm `inventory._value_line` (G5-0b); lần tính đọc lại từ sổ; 11 kịch bản `inventory_costing.sql` so từng đồng + bất biến cân bằng (spec giá vốn mục 9, 11) |
| Không seed ⇒ muốn thử một plan giữa chặng phải đi lại luồng từ đầu | Chấp nhận (Q6). Test tự động dùng fake |
| Code G5-0a còn K2 / K3 / "Chờ duyệt" không dùng | G5-0b gỡ "Chờ duyệt" khỏi Hub; G5-8 kiểm không còn code chết của K2 / K3 và lối vào trỏ BJ bị bỏ |
| Nợ biết khi đóng G5-8 (R3) | Danh sách nhận hàng chỉ lấy 100 phiếu gần nhất, không phân trang (R1 #7, chọn tăng `limit`); sau khi kết thúc chương trình NCC mà tải lại lỗi, nhãn trạng thái vẫn hiện "đang áp dụng" dù đã ẩn nút Kết thúc / Sửa (R2 #5); `Semantics` mới phủ một phần nút trong Kho. Cả ba chấp nhận cho đồ án |
| Spec FROZEN nhiều hơn app ⇒ hội đồng hỏi | Báo cáo có mục "Phạm vi đã làm / hướng phát triển" liệt kê bảng "Rút gọn 2026-11-09" |

### Xong khi

| # | Tiêu chí | Kiểm bằng |
|---|---|---|
| 1 | 18 màn BJ + 2 màn CAP-01 (062, 063) + 5 màn NCC (bảng Plan) + 7 màn Hub chạy trên Flutter, cả iPhone lẫn web, mở được từ Home Kho hoặc lối vào ngữ cảnh; không còn toast / SnackBar giả hành vi, không còn lối vào trỏ BJ bị bỏ | G5-8: bảng màn → route → test mở màn |
| 2 | Trạng thái chính + lỗi chính của mỗi màn có widget test (iPhone 390 × 844 **và** web 1280 × 800 khi bố cục khác nhau) | mỗi plan con |
| 3 | Mỗi plan ghi dữ liệu thật qua RPC Supabase, có test hợp đồng SQL; luật nghiệp vụ (chặn tồn âm, FEFO, giá vốn đúng từng đồng theo **cả hai** phương pháp, khoá sổ kỳ đã chốt, idempotency) kiểm ở server | test `*_sql_contract_test.dart` + `supabase/tests/*.sql` |
| 4 | Luồng demo đi được trên DB Dev dựng từ migration, **dữ liệu tạo qua app**, kho bắt đầu trống: nhận hàng có giá → bán (xuất FEFO, có giá vốn) → trả hàng → huỷ đơn → kiểm kê / điều chỉnh hỏng → **chương trình NCC đạt mốc → ghi nhận chiết khấu (phần tồn / phần đã bán)** → **cập nhật giá vốn giữa kỳ → rà soát (so sánh hai phương pháp) → công bố** → thẻ kho + giá trị tồn khớp + lãi gộp sau điều chỉnh | G5-8 kiểm tay (người dùng) |
| 5 | 6 kịch bản Theme 5 cho tồn + giá vốn đúng theo sổ kho; tồn cơ bản Theme 2 đã bỏ | G5-4, G5-5 |
| 6 | `dart analyze lib/features/inventory test/features/inventory` = 0 lỗi; `flutter test` không thêm lỗi so với `TEST-BASELINE.md` | mỗi plan con |
| 7 | Code BJ-02 / BJ-03 cũ (v4.6.8) và `WarehouseHomePage` v3.8 đã xoá | G5-0a ✅, G5-3 |
| 8 | 17 kịch bản spec mục 9 (`inventory_costing.sql` + ca trỏ ở plan G5-6 mục 2.5) đạt (gồm 6 ca ưu đãi NCC) | G5-2b, G5-3, G5-5b, G5-6; người dùng chạy |

---

## Tích hợp AI (~4,5 ngày)

**Trạng thái (2026-11-20):** 🔄 AI-0, AI-1 ✅; AI-2 làm xong, chưa review; AI-3 / AI-4 / AI-5 ⏸ tạm dừng từ 2026-11-18 (chuyển sang Theme 6). Việc còn mở ghi ở từng dòng bảng; file plan AI-2…5 đã xoá ở `4d14f189c` (đọc `git show 4d14f189c^:docs/refactor/plans/AI/<tệp>.md`). Công cụ `cong_no_phai_thu` (hoãn từ AI-1) làm khi Theme 6 đóng.

Giảng viên phụ trách yêu cầu "tích hợp AI vào app". Làm **ngay sau Theme 7** (chốt 2026-11-09; trước đây làm cuối, sau Dọn dẹp), trước Theme 6.

**Đã chốt (2026-10-27, người dùng; không hỏi lại giáo viên; plan chi tiết viết khi tới phần này, làm cùng người dùng):** tính năng = trợ lý **"Hỏi Mosaic Retail"** hỏi đáp số liệu cửa hàng bằng tiếng Việt, chỉ đọc, theo quyền người hỏi, **kèm dự báo nhập hàng** (AI-3: app tính dự báo bằng công thức thống kê trong RPC, Gemini chỉ giải thích — không huấn luyện model riêng, không để Gemini tự tính số). Công cụ là vài RPC tổng hợp **có tham số** (chỉ số × nhóm theo × lọc × thời gian, giá trị chọn trong danh sách cố định; SQL do mình viết), không viết một RPC cho mỗi câu hỏi; câu không có công cụ → trả lời "chưa hỗ trợ", ghi nhật ký. Đọc ảnh phiếu giao hàng: chỉ là ý tưởng nếu dư thời gian, không nằm trong plan. **Làm đủ chức năng** (người dùng chốt 2026-10-27): cả trợ lý lẫn dự báo, đủ các công cụ (thống kê bán hàng, tồn kho, biến động kho, công nợ, dự báo, tìm kiếm) và bộ 20–30 câu hỏi thử — không chia tầng cắt; người dùng đẩy nhanh các theme trước để dành thời gian cho phần này. Model: **Gemini API, hạn mức miễn phí** (khoá tạo ở Google AI Studio, chỉ nằm trong secrets Edge Function); phần gọi model tách một lớp riêng để đổi nhà cung cấp được.

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
| ---- | -------- | -------- | ---- | --- | ------ |
| **AI-0** | Yêu cầu ngắn cho "Hỏi Mosaic Retail": danh sách câu hỏi phải trả lời được, công cụ và bộ tham số (thống kê bán hàng, tình hình tồn kho, biến động kho, công nợ phải thu, dự báo bán hàng, tìm sản phẩm / khách / đơn), lời dặn hệ thống, chữ trên màn, quyền, giới hạn; bộ 20–30 câu hỏi thử để đánh giá | ~0,5 ngày | ✅ [plan](plans/AI/AI-0-yeu-cau.md) (yêu cầu, không code) | — | — |
| **AI-1** | Backend: Edge Function `ai-assistant` gọi Gemini API (function calling); **viết mới RPC tổng hợp chỉ đọc có tham số** (app hiện chưa có RPC tổng doanh thu — `list_sales_orders` chỉ trả danh sách theo trang; thẻ doanh thu Home đang gõ cứng), dùng lại RPC đọc của Theme 7; ~~công cụ công nợ phải thu~~ **hoãn** (người dùng chốt 2026-11-16: làm sau Theme 6, xem [AI-0](plans/AI/AI-0-yeu-cau.md)); gọi bằng JWT của người hỏi (RLS + quyền tự áp); nhật ký (người hỏi, công cụ, token, câu không có công cụ), giới hạn số câu mỗi tổ chức mỗi ngày | ~2 ngày | ✅ plan (đã xoá) | ✅ | ✅ R4 |
| **AI-2** | UI (iPhone + web): màn "Hỏi Mosaic Retail", lối vào từ Home; câu trả lời + bảng dựng từ kết quả công cụ + nút mở màn; đang trả lời, lỗi, hết lượt, không có quyền; `/impeccable audit` | ~1 ngày | ✅ plan (đã xoá ở `4d14f189c` khi **chưa review**; tệp `AI-2-man-hoi-c45.md`) | ✅ (web + dev đã chạy thật; chưa kiểm tay: iPhone, thu ngân, tắt mạng, bấm khách) | ⬜ — còn: golden 390 / 1280 so `proto-*` (Task 5 Step 1), hỏi thử 5 câu trên iPhone + web (Step 2); audit còn nợ P2/P3 (`liveRegion`, cuộn tới đầu câu trả lời dài, chọn / sao chép chữ, vòng xoay khi chờ) |
| **AI-3** | Dự báo nhập hàng: RPC tính tốc độ bán trung bình có trọng số 8 tuần → số ngày còn hàng + lượng nên nhập theo **ngưỡng cảnh báo / mức tồn mục tiêu** của sản phẩm (CAP-01, Theme 7 G5-2a — `inventory.product_stock_policies`); công cụ `du_bao_ban_hang`; script sinh lịch sử bán mô phỏng vài tháng (ghi rõ trong báo cáo là dữ liệu mô phỏng) | ~1 ngày | ✅ plan (đã xoá) | ✅ 2026-11-17 (Dev: migration + test SQL + seed + dự báo trên app ✅) | ⏸ tạm dừng 2026-11-18 (R2 đạt phần đọc code) — còn: bộ câu thử (gộp vào AI-5 Task 4; kiểm câu 8 ⇒ `tinh_hinh_ton_kho`, câu 18 ⇒ `du_bao_ban_hang`) |
| **AI-4** | Hỏi Mosaic Retail **tự truy vấn** (người dùng chốt 2026-11-17, sau khi thấy câu ngoài danh sách bị "chưa hỗ trợ"): schema `ai_read` gồm 6 view chỉ đọc đã lọc theo cửa hàng (không dữ liệu cá nhân; mọi thành viên hỏi như nhau, chưa phân quyền theo vai trò), role `ai_reader`, `ai.run_query` (một câu SELECT, danh sách hàm cho phép, 5 giây / 50 dòng); công cụ `truy_van` cho Gemini tự viết SELECT khi không công cụ chuyên dụng nào khớp; mở `lai_gop` (RPC `get_gross_profit_report`) cho mọi thành viên để nhất quán; bộ ~45 câu thử mở rộng (gồm nhóm an toàn) | ~2–3 ngày | ✅ plan (đã xoá) (duyệt 2026-11-17) | ✅ 2026-11-18 (local `db_check` ✅, db push + deploy Dev ✅, `truy_van` chạy trên app) | ⏸ tạm dừng 2026-11-18 (R5: `db_check` local ✅) — còn: R6 đóng bằng bộ 45 câu (AI-5 Task 4; A–F ≥ 80%, G 100%), lỗi bấm mở đơn (UI) |
| **AI-5** | Hỏi Mosaic Retail chạy bằng **Claude Haiku 5.5** (effort `low`, đổi qua `CLAUDE_MODEL` / `CLAUDE_EFFORT`) thay Gemini (gói miễn phí treo / 503 trên Dev 2026-11-17); `model/claude_client.ts` qua `@anthropic-ai/sdk`; **bỏ hẳn Gemini** (xoá client + biến `GEMINI_*`, không dự phòng); bộ câu thử AI-4 chạy `low` / `medium` để chốt effort và đóng AI-4 | ~1 ngày | ✅ plan (đã xoá) (duyệt 2026-11-17) | ✅ Task 1–3 2026-11-18 (Dev chạy Claude Haiku 5.5 low, ~0,001 USD/câu) | ⏸ tạm dừng 2026-11-18 (R1 chưa đóng) — còn: Task 4 (seed Demo AI + bộ 45 câu `low`/`medium`, chốt `CLAUDE_EFFORT`), lỗi màn đỏ `!keyReservation.contains(key)` / GlobalKey `root` trùng khi bấm dòng đơn từ `/ask` (Flutter), gỡ / rút gọn log `ai-trace` sau eval |

**Xong khi:** tính năng chọn ở AI-0 chạy được từ đầu đến cuối trong app (iPhone + web), chỉ dùng dữ liệu của tổ chức và theo quyền người dùng; có một kịch bản demo cho hội đồng.

---

## Theme 6. Công nợ phải thu (~6 ngày)

**Trạng thái (2026-11-20):** 🔄 T6-0, T6-1a, T6-1b, T6-2a, T6-2b ✅ (T6-2b R3, DB `receivable_th06: OK`). **Chỉ còn T6-2c:** review R3 phần sửa R2 (`aaa67325c`) ở phiên khác + kịch bản 9.1 trên iPhone + web. File plan T6-2a/2b/2c đã xoá ở `4d14f189c` (đọc `git show 4d14f189c^:docs/refactor/plans/T6/<tệp>.md`). Đóng Theme 6 xong ⇒ làm công cụ AI `cong_no_phai_thu` (mục Tích hợp AI). Dữ liệu tiền của đơn chuyển từ schema `sales` sang `receivable` (chốt 2026-11-18, TH-06 Q12–Q13). SCOPE.md mục 2.3 trước đây để TH-06 ngoài phạm vi, nay đưa vào (chốt 2026-10-27).

**Phạm vi (chốt 2026-10-27):** chỉ **phải thu khách hàng**, sinh từ phần còn phải thu của đơn bán (công nợ đơn ở TH-05); **có cấn trừ**. **Không** có phải trả nhà cung cấp.

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
| ---- | -------- | -------- | ---- | --- | ------ |
| **T6-0** | Viết `docs/requirements/TH-06-cong-no.md` (độ sâu như TH-07 v1: US / AC / EC / Gherkin / màn): công nợ theo khách, thu tiền, phân bổ vào đơn, cấn trừ, quyền, chữ trên màn. Đầu vào: bản nháp BA `specs/themes/theme-06` v2.1.3 (knowledge, 6 journey, aggregate; bị xoá ở commit `5db3c62d9`, đọc bằng `git show 5db3c62d9^:specs/themes/theme-06/…`) — chỉ lấy phần phải thu + cấn trừ | ~1 ngày | — (chốt trong chat 2026-11-18) | ✅ [TH-06](../requirements/TH-06-cong-no.md) v1.0 2026-11-18 | ✅ người dùng duyệt 2026-11-18 |
| **T6-1a** | DB: chuyển 3 bảng tiền (`sales_order_settlements`, `sales_payment_transactions`, `settlement_obligation_adjustments`) từ `sales` sang schema mới `receivable` (chốt 2026-11-18, cách A) và chuyển `sales_orders.payment_due_date` vào bảng quyết toán (Q13 R1); tạo lại 25 hàm `sales` + sửa view `ai_read.don_ban`; sửa 8 test SQL; app không đổi. [TH-06 3.6](../requirements/TH-06-cong-no.md#36-chuyển-bảng-tiền-sang-schema-receivable-q12-cách-a-q13-r1) | ~1,5 ngày | ✅ plan (đã xoá) (duyệt 2026-11-18, cách 2: sinh thân hàm từ DB) | ✅ | ✅ R1 |
| **T6-1b** | DB: công nợ theo khách đọc từ quyết toán đơn; thu theo khách chia vào từng đơn (cũ trước); cấn trừ khi đổi/trả (giảm nợ đơn đó → cấn trừ đơn khác → hoàn); 4 bảng mới trong `receivable` (lần thu, cấn trừ, kế hoạch tiền đổi/trả tách khỏi `valuation_details` — Q13 R2, chống trùng riêng — R3) + 5 RPC; RPC + test. Phạm vi: [TH-06](../requirements/TH-06-cong-no.md) | ~1,5 ngày | ✅ plan (đã xoá) (duyệt 2026-11-18; cách 2 "làm gọn": xoá `settle_return_exchange_difference`, hai migration) | ✅ 2026-11-19 | ✅ R1 |
| **T6-2a** | Prototype HTML (iPhone 390 + web 1280) cho CN-01, CN-02, CN-03, SG-13 bản cấn trừ + màn gom `patches` (sửa SG-09 / 09b / 09c / 14, PT-07, menu Thêm); thư mục riêng `specs/themes/theme-06/03.design/prototype/html/` (chép `tokens.css` Theme 7, rút `components.css`); hàm thuần `allocateOldestFirst` / `planReturnSettlement` có test; bộ ảnh đích 90 ảnh (45 ca × 2 khổ; bản chốt, token khớp Dart). Làm **trước** T6-2, không phụ thuộc DB (TH-06 5.6). Dừng sau khi có ảnh để người dùng duyệt | ~0,5 ngày | ✅ plan (đã xoá) (duyệt 2026-11-18, hướng B; review plan cùng ngày: ẩn khối cấn trừ khi `còn_lại = 0`) | ✅ 2026-11-18 (`880df71c7`, `b05cbb3e3`) | ✅ người dùng chốt 2026-11-18 |
| **T6-2b** | Flutter feature `receivable` (iPhone + web hai cột): CN-01 danh sách khách còn nợ, CN-02 công nợ một khách, CN-03 thu tiền theo khách; route `/more/receivables`, mục menu Thêm; migration nhỏ thêm `actorDisplayName` vào lịch sử; golden 390 / 1280 so ảnh T6-2a | ~1 ngày | ✅ plan (đã xoá) (duyệt 2026-11-19, hướng A) | ✅ 2026-11-19 Flutter (`47e6e75e7`, `63ec503fe`, `c93e9881d`, `8920fd120`); migration `actorDisplayName` (`b2924e0d3`; `receivable_th06: OK`) | ✅ R3 |
| **T6-2c** | Sửa màn cũ: SG-13 khối cấn trừ (DTO + lệnh xác nhận `offset_target_order_ids`), SG-09 bỏ "Thu tiền" + dòng "Xem công nợ của khách ›", SG-09b / 09c / 14 dòng cấn trừ, PT-07 khối Công nợ; `/impeccable audit`; kịch bản 9.1; bỏ SG-11; migration nhỏ: xác nhận đổi/trả ghi cách chia thật + nhãn lịch sử thu theo khách (bổ sung 2026-11-19) | ~1,3 ngày | ✅ plan (đã xoá) (duyệt 2026-11-19, hướng A) | ✅ 2026-11-19 Task 1–8 (`435f2e530` … `aa0bb054d`; migration `20261126001` ở `271144279`; DB local `receivable_th06: OK`, `sales_th05: OK`); bỏ golden `patch-*` + audit | 🔄 R1 sửa (`8331ae736`), R2 sửa (`aaa67325c`, nhãn đọc màn hình ô cấn trừ có hạn nợ) — còn: **R3** ở phiên khác + kịch bản 9.1 iPhone + web (người dùng) |

**Xong khi:** bán nợ → thu một phần → thu đủ; khách trả hàng → cấn trừ vào đơn còn nợ (app không giữ tiền dư của khách); số còn phải thu của khách = tổng công nợ các đơn sau mỗi bước; kịch bản đầu–cuối của TH-06 chạy qua trên cả iPhone và web.

---

## Dọn dẹp (1 ngày)

**Trạng thái:** 🔄 9-1 ✅ (review R1 2026-11-19); 9-2 ✅ (2026-11-19; `db reset` + vòng test SQL xanh, gồm `catalog_th02` / `pricing_th04` / `einvoice_th08` đã sửa theo schema ở `c57ac4185`, `4169b89a4`). Còn: reset Dev; xoá 3 dòng `test` tương ứng khỏi `tools/db_check_known.txt` nếu `db_check` xanh; đối chiếu DoD SCOPE mục 6. **Chốt 2026-11-19 (người dùng): không gộp migration** (phương án B) — 9-2 chỉ sửa migration gốc; 9.5 bỏ.

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **9-1** | Dọn code: thay `IExecutionContext` / `CoreExecutionContext` trong `features/sales/logic` (10 tệp) bằng `SessionController` (7-C Q1); gộp phần còn dùng của `c45_shared` vào `core/` rồi xoá; bỏ Melos; xoá `apps/erp/example`; xoá `packages/c45_annotations` cùng `c45_shared` (chuyển từ 5-C / 7-C, 2026-11-04). `c45_env` đã xoá ở `8ad18cd27` | 9.1, 9.2, 9.3, 9.6 | ✅ plan (đã xoá) duyệt 2026-11-19 | ✅ 2026-11-19 | ✅ R1 2026-11-19 (R1-1…R1-3 đã sửa) |
| **9-2** | Dọn DB: dọn nền messaging `platform` (`20260623000001/000002`, `20260820008`, 4 schema `iam` / `costing` / `accounting` / `dashboard`) (7-C Q3); bỏ outbox/inbox/onboarding (trừ `sales.outbox_messages`, nhật ký sự kiện của đơn, 8-C Q1); **không gộp migration** (chốt 2026-11-19) | 9.4 | ✅ plan (đã xoá) duyệt 2026-11-19 | ✅ 2026-11-19 | ✅ 2026-11-19 (người dùng đánh đạt) |

Chi tiết từng việc:

| # | Việc | Kiểm tra |
|---|---|---|
| 9.1 | Kiểm **không còn** `modules/`, `apps/admin`, `apps/messaging_worker` (`modules/` đã xoá hết ở 7-C; 3-D IAM / admin / worker; 4-C partner; 5-C catalog, inventory; 6-C pricing; 7-C einvoice + 4 package; 8-C sales) | `grep -r "c45_.*_application"` không còn kết quả |
| 9.2 | Gộp phần còn dùng của `c45_shared` (`ApplicationException`, `TenantAccessRevokedSignal`…) vào `core/` rồi xoá `packages/c45_shared`, `packages/c45_annotations` và `apps/erp/example` (4 package `c45_misa`, `c45_async_query`, `c45_adapters`, `c45_generator` đã xoá ở 7-C) | `flutter pub get` OK |
| 9.3 | Bỏ Melos; `pubspec.yaml` gốc chỉ còn workspace `apps/erp`, `packages/c45_lints`, `packages/c45_design_system`. Lệnh gốc: `dart pub get`, `dart analyze apps/erp packages`, codegen `cd apps/erp && dart run build_runner build --delete-conflicting-outputs`. `packages/c45_misa` đã xoá (viết lại bằng TypeScript trong Edge Function ở P7.4) | `dart pub get` OK; `dart analyze` không lỗi |
| 9.4 | DB: bỏ nền messaging `platform` + schema `costing` / `accounting` / `dashboard`; bỏ outbox / inbox `iam`, outbox `einvoice` (trừ `sales.outbox_messages`, 8-C Q1); giữ `einvoice.internal_commands`, `iam.idempotency_records`; đường email IAM ⇒ `iam.enqueue_email_job`. Onboarding / readiness / `provisioning` / `pending_activation` / FK `memberships.user_id` đã xong ở 3-B | `supabase db reset` OK |
| 9.5 | ~~Gộp migration~~ **Bỏ (chốt 2026-11-19)**: giữ migration hiện có, 9-2 chỉ sửa migration gốc | — |
| 9.6 | `tools/c45_supabase_migrate` và `tools/c45_env` **đã xoá** ở `8ad18cd27` (guard CI không còn dùng đã bỏ). Đã dọn nốt (2026-11-20): xoá `.c45/`, `c45.workspace.json`, các `c45.target.json`, `environment-manager.md`; viết lại `environments.md` theo `.env` viết tay | — |

**Xong khi:** đạt toàn bộ **Definition of Done ở SCOPE mục 6**.

---

## Hoàn thiện cho báo cáo đồ án (3 ngày)

**Trạng thái (2026-11-20):** 🔄 10-4, 10-5, 10-6 ✅; 10-7 ✅ trừ task "Cuối"; 10.5 bỏ. Báo cáo `DATN.md` (gốc repo) đang viết: đủ khung Mở đầu → Chương 1–4 → Kết luận → Tài liệu tham khảo. Còn: 10-1, 10-2, 10-8 (rà soát lại từng theme, mở 2026-11-21), 10.6 (merge `dev` → `main`, tag `v2.0.0`).

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **10-1** | Tài liệu kiến trúc, sơ đồ báo cáo, README | 10.1, 10.2, 10.3 | ⬜ | ⬜ | ⬜ |
| **10-2** | Kịch bản demo bảo vệ | 10.4 | ⬜ | ⬜ | ⬜ |
| **10-3** | ~~Đổi tên `c45` (tùy chọn)~~ (bỏ), merge `dev` → `main` và tag `v2.0.0` — làm thẳng (`refactor/simple-arch` → `dev` đã xong, PR #1) | 10.6 | — | ⬜ | — |
| **10-4** | Tương phản màu xanh chủ đạo, nhãn + semantics thanh dưới (độc lập, làm lúc nào cũng được) | 10.7 | ✅ plan (đã xoá) | ✅ | ✅ |
| **10-5** | Tương phản tone trạng thái, chữ phụ, viền ô nhập (độc lập) | 10.8 | ✅ plan (đã xoá) | ✅ | ✅ |
| **10-6** | Vùng chạm, nhãn trình đọc màn hình, inset thanh dưới, giảm chuyển động (độc lập) | 10.9 | ✅ plan (đã xoá) | ✅ | ✅ |
| **10-7** | Tinh chỉnh `c45_design_system` từng mảng bằng impeccable (10 task, độc lập) | — | ✅ [plan](plans/P10/10-7-tinh-chinh-design-system-impeccable.md) | ✅ | ✅ — còn task "Cuối": `polish` + `document` (DESIGN.md ở gốc repo), bump version DS (đang `1.7.0`) |
| **10-8** | Rà soát lại từng theme (người dùng tự rà, tự sửa — mở 2026-11-21): rà UI bằng impeccable trên prototype HTML (Flutter không dùng được impeccable ⇒ theme chưa có prototype thì chuyển màn Flutter sang HTML / CSS như Theme 6, 7), sửa xong chuyển ngược về Flutter; tick cột "Mới" CHECKLIST | 10.10 | — | ⬜ | ⬜ |

Chi tiết từng việc:

| # | Việc |
|---|---|
| 10.1 | Viết lại `docs/architecture/` thành 2 file: `ARCHITECTURE.md` (sơ đồ 3 tầng, luồng request, quy tắc phụ thuộc) và `DATABASE.md` (ERD theo schema, RLS, các RPC transaction) |
| 10.2 | Sơ đồ cho báo cáo: kiến trúc tổng thể, use case theo vai trò (Owner / Nhân viên), sequence đăng ký cửa hàng, sequence checkout → HĐĐT; **chương "Giá vốn hàng tồn kho"** theo [spec giá vốn](plans/T7/T7-G5-gia-von-thiet-ke.md) mục 10 (giá gốc VAS 02 gồm VAT với hộ kinh doanh, hai công thức + ví dụ, ưu đãi nhà cung cấp ba cách hạch toán, điều chỉnh liên kết, mốc chốt theo số thứ tự sổ, sơ đồ trạng thái lần tính, bảng ca test) |
| 10.3 | Cập nhật README: cách chạy local (Supabase + seed + app) |
| 10.4 | Kịch bản demo bảo vệ: đăng ký cửa hàng → thêm sản phẩm → thêm khách → bán hàng → phát hành HĐĐT → đổi trả |
| 10.5 | ~~(Tùy chọn) Đổi tên công cụ `c45` / thư mục `.c45` / `tools/c45_env`~~ — bỏ: công cụ đã xoá (2026-11-20) |
| 10.6 | Merge `refactor/simple-arch` → `dev` → `main`, tag `v2.0.0` |
| 10.7 | Sửa lỗi khả năng tiếp cận trong `c45_design_system`: theme sáng đổi `primary` / `success` sang `primary600` (đạt 4.5:1), `VBottomNavigationBar` hiện nhãn + `Semantics`; tab 4 ERP đổi `KH&NCC` → `Đối tác` |
| 10.8 | Theme sáng: warning `yellow700`, danger `red600`, info `blue600`, `textSecondary` `neutral600`, `textMuted` `neutral500`; token mới `borderInput` (`neutral450`) cho viền ô nhập / checkbox / radio; test tương phản tự động |
| 10.9 | Vùng chạm ≥ 44 (nút mật khẩu, nút xoá chip, `VIconBox` có `onTap`); nhãn cho nút quay lại `VAppBar`, mũi tên combobox, bàn phím số; `VSwipeReveal.semanticActions`; thanh dưới chừa đủ inset; skeleton / swipe tôn trọng giảm chuyển động |
| 10.10 | Rà soát lại từng theme — xem bảng 10-8 bên dưới |

### 10-8. Rà soát lại từng theme

Mỗi theme đi 3 bước:

1. **Prototype HTML:** theme chưa có prototype thì chuyển màn Flutter sang HTML / CSS theo khuôn Theme 6 (`specs/themes/theme-06/03.design/prototype/html/`): thư mục `specs/themes/theme-0X/03.design/prototype/html/`, symlink `html/shared` → `specs/prototype/shared` (không chép tay `tokens.css` / `components.css`), CSS riêng có tiền tố của theme, mỗi màn một file `app/<màn>.js`, trạng thái ở `cases.js`. Bố cục iPhone 390 + web 1280.
2. **Rà UI bằng impeccable** trên prototype HTML — **người dùng tự rà**, agent không chạy impeccable; agent chỉ dựng prototype (bước 1) và sửa theo kết quả rà khi người dùng yêu cầu. Sửa token ở `shared/` thì sửa cùng lúc `c45_design_system` (token HTML khớp Dart) và nhìn lại Theme 6 / 7 vì dùng chung.
3. **Chuyển ngược về Flutter** theo mục "Plan có màn Flutter: kèm code + ảnh prototype" (chép nguyên JS / CSS màn + bảng ánh xạ widget / token, so ảnh `proto-*` / `flutter-*` 390 / 1280); test phạm vi theme, `dart analyze lib test`, `check_feature_imports`; tick cột "Mới" CHECKLIST.

**Khung chung làm trước:** prototype mọi theme dựng bên trong khung này (thanh bên / thanh dưới, đầu trang), nên rà xong khung rồi mới sang theme. Khung web trên prototype Theme 7 (T7-P) là điểm xuất phát; đưa phần khung ra `specs/prototype/shared/` để theme khác dùng lại. Chuyển khung về Flutter làm theo thứ tự 10-8a → b → c (thiết kế duyệt 2026-11-23).

| Mục | Prototype HTML | Refactor lại UI | Plan chuyển Flutter | Xong | Ghi chú |
|---|---|---|---|---|---|
| Layout tổng thể (web + iPhone) | ✅ [shell](../../specs/prototype/shell/html/README.md) | ✅ 2026-11-23 | ✅ [10-8a](plans/P10/10-8a-khung-flutter.md) | 🟡 2026-11-24 review R2 đạt, chờ kiểm tay APP-04 | Web: thanh bên trái, cửa sổ hẹp ⇒ thanh dưới 5 tab; iPhone: thanh dưới. Flutter: `features/dashboard/presentation/store_shell.dart`, `erp_tab_scaffold.dart`, `widgets/erp_side_navigation.dart`, `widgets/erp_bottom_navigation.dart` (W-1). Gồm chọn cửa hàng APP-04 |
| Trang chủ (dashboard) | ✅ [home](../../specs/prototype/home/html/README.md) | ✅ 2026-11-23 | ✅ [10-8b](plans/P10/10-8b-trang-chu-flutter.md) | 🟡 2026-11-24 review R1 đạt (5 góp ý nhỏ), chờ kiểm tay APP-01 | APP-01 "Bảng giá chợ": `home_tab_page.dart`, `widgets/home_board.dart`, RPC `sales.get_home_summary`; "Hỏi Mosaic Retail" nổi (`AssistantChatPanel`); bỏ banner pháp lý ở Trang chủ (TH-01 BR-14) |
| Menu Thêm + Thiết lập hệ thống | ✅ [more](../../specs/prototype/more/html/README.md) | ✅ 2026-11-23 | ✅ [10-8c](plans/P10/10-8c-menu-them-flutter.md) | ⬜ | APP-02, `features/more/presentation/` (`more_page.dart`, `system_settings_page.dart`, `users_and_roles_page.dart`, `more_entries.dart`); mục Công nợ (Theme 6), HĐĐT (Theme 8) |

| Theme | Prototype HTML | Refactor lại UI | Plan chuyển Flutter | Xong | Ghi chú |
|---|---|---|---|---|---|
| Theme 1 (TH-01) + Web cho app | ✅ [theme-01](../../specs/themes/theme-01/03.design/prototype/html/README.md) | ⬜ | ⬜ | ⬜ | W-2 (Theme 1 trên web). ID-08 dùng APP-04 của khung chung; ID-10 dùng APP-02 (Menu Thêm); ID-23 vẽ chung với ID-04 |
| Theme 3 (TH-03) | ✅ [theme-03](../../specs/themes/theme-03/03.design/prototype/html/README.md) | ⬜ | ⬜ | ⬜ | DS chép từ Theme 1 (`ds.js`, tiền tố `t3-`; gom về `shared/` để sau). PT-07 vẽ đủ khối Công nợ (Theme 6), Chương trình ưu đãi + Lịch sử nhập hàng (Theme 7) như Flutter |
| Theme 2 (TH-02) | ✅ [theme-02](../../specs/themes/theme-02/03.design/prototype/html/README.md) | ⬜ | ⬜ | ⬜ | DS chép từ Theme 3 (`ds.js`, tiền tố `t2-`). SP-10 đã bỏ (G5-5). PCC vẽ thẻ Tồn kho (Theme 7) như Flutter; ô gạt "Quản lý theo lô" ở SP-05 |
| Theme 4 (TH-04) | ✅ [theme-04](../../specs/themes/theme-04/03.design/prototype/html/README.md) | ⬜ | ⬜ | ⬜ | DS chép từ Theme 2 (`ds.js`, tiền tố `t4-`). Route `/pricing/*` ngoài khung ⇒ vẽ không thanh bên / thanh dưới, web 1 cột 720. Sheet là `showVBottomSheet` ⇒ web cũng sheet đáy 640 |
| Theme 5 (TH-05) | ✅ [theme-05](../../specs/themes/theme-05/03.design/prototype/html/README.md) | ⬜ | ⬜ | ⬜ | DS chép từ Theme 4 (`ds.js`, tiền tố `t5-`). `/sales/*` ngoài khung ⇒ không thanh bên / thanh dưới, web 1 cột 720; chỉ SG-08 `/orders` trong khung. SG-11 đã gỡ (T6-2c) nên không vẽ; HD-06, khối cấn trừ vẽ như Flutter. SG-08 trong khung: sheet lọc (`showVBottomSheet`, navigator lồng) chỉ phủ vùng nội dung |
| Theme 8 (TH-08) | ✅ [theme-08](../../specs/themes/theme-08/03.design/prototype/html/README.md) | ⬜ | ⬜ | ⬜ | DS chép từ Theme 4 (`ds.js`, tiền tố `t8-`). Route `/more/einvoice/*`, `/sales/result/:id`, `/sales/orders/:id` ngoài khung ⇒ web 1 cột 720. HD-06 vẽ trong SG-06 / SG-08 chép từ Flutter (không dùng file Theme 5). Mọi sheet là `showVAdaptiveSheet` ⇒ web hộp thoại 480. `shared/icons.js` `error` ≠ `VIcons.error` (circle-x), sửa cục bộ |
| Theme 7 (Kho & Giá vốn) | ✅ [theme-07](../../specs/themes/theme-07/03.design/prototype/html/README.md) | ⬜ | ⬜ | ⬜ | Prototype FROZEN, chưa dùng `shared/`. Kiểm theo [test-theme7.md](plans/T7/test-theme7.md) |
| Tích hợp AI | ✅ [assistant](../../specs/prototype/assistant/html/README.md) | ⬜ | ⬜ | ⬜ | Gồm lỗi màn đỏ khi bấm dòng đơn từ `/ask` (AI-5) — prototype không tái hiện, ghi ở ca `answer/orders`. `/ask` ngoài khung ⇒ web cột 840 giữa nền xám. DS chép từ Theme 8 (`ds.js`, tiền tố `ai-`) |
| Theme 6 (TH-06) | ✅ [theme-06](../../specs/themes/theme-06/03.design/prototype/html/README.md) | ⬜ | ⬜ | ⬜ | Gồm R3 T6-2c + kịch bản 9.1 |


## Theo dõi tiến độ

| Mục | Trạng thái | PR | Ghi chú |
|---|---|---|---|
| Chuẩn bị | ✅ | — (commit trực tiếp trên branch) | Tag `v-legacy-arch`; CHECKLIST lập xong, cột "Cũ" bỏ qua; TEST-BASELINE 5688 đạt / 160 lỗi; Supabase Dev đủ 162 migration; tài liệu cũ vào `docs/_legacy/` |
| Nền core | ✅ | Merge `7c455c6a7` (branch `refactor/p1-core`) | 1.1 `16bcfe263`; 1-A `d8f4e9ca8`, `8550b3561`; 1-B `3a48c19b5`, `373002481`. Còn kiểm tay + tick CHECKLIST |
| Theme 1 | 🔄 | — | Code xong và đã commit cả 2-A1…2-B7 (2-B6, 2-B7 ở `72b4cc2dd`). Việc trên Dev xong (2026-10-28). **Chỉ còn kiểm tay:** TH-01 9.3 kịch bản 1–4 (2-B1, 2-B2 gửi mail lời mời thật, 2-B5), danh sách kiểm tay 2-B6 / 2-B7 / W-1 / W-2 6.2, tick 33 màn CHECKLIST |
| Theme 1 (tiếp) | ✅ | — | 3-A…3-E ✅ (2026-10-12). 4 kịch bản SQL IAM đạt trên Dev sau `db reset --linked` |
| Đợt kiểm IAM | 🔄 | — | 2026-10-12: Resend + DNS ✅, secrets Edge Function ✅, SMTP Auth ✅, `db reset --linked` ✅, 4 kịch bản SQL ✅, `send-email` đã deploy ✅. 2026-10-28: Vault ✅, `invitation-signup` đã deploy (12/10) ✅. Confirm email + mẫu mã 6 số + rate limit ✅. Còn: kiểm tay TH-01 9.3 kịch bản 1–4 → tick CHECKLIST |
| Web cho app | 🔄 | | Mở 2026-10-20 (chốt thiết bị iPhone + web). 2026-10-28: W-1 ✅ (R2; test app 1524 pass / 61 fail có sẵn; DS 435 / 1 có sẵn), commit `72b4cc2dd`; W-2 plan đã duyệt + rà theo quy tắc "test giữ hành vi trước"; 2026-10-29: W-2 ✅ R4 (test app 1555 pass / 61 fail có sẵn; DS 447 / 1 có sẵn; audit 15/20), commit `1bd9268af`; còn kiểm tay W-1 mục 5 + W-2 6.2 |
| Theme 3 | 🔄 | | 2026-11-02: code 4-A, 4-B, 4-W, 4-C xong, review ✅ cả 4 (4-W R2, các plan còn lại R1), đã commit. **Chỉ còn việc người dùng:** kiểm tay (4-A 7.2, 4-B 7.2, 4-W 6.2); `db reset` local + `supabase/tests/partner_th03.sql` / `iam_*.sql` (4-B, 4-C); reset Dev |
| Theme 2 | 🔄 | | 5-A1, 5-A2, 5-A3, 5-C ✅ (5-C R2 2026-11-04). `catalog_th02.sql` sửa theo schema và xanh ở 9-2 (`4169b89a4`, điều kiện nới). Còn: reset Dev |
| Theme 4 | 🔄 | | 6-A1, 6-A2, 6-B, 6-C ✅ (6-C R1 2026-11-06). `pricing_th04.sql` sửa theo schema và xanh ở 9-2 (`4169b89a4`). Còn: reset Dev; kiểm tay 6-A2 7.2, 6-B 8.2 |
| Theme 5 | 🔄 | | 8-A1…8-A4, 8-B1…8-B3, 8-C ✅ (review đạt; 8-C R1 2026-11-08). Nối kho: Theme 7 G5-4 ✅ (2026-11-11; đạt 6 kịch bản kiểm tra `inventory_sales_link.sql`). `sales_th05: OK` (2026-11-19). Còn: reset Dev |
| Theme 8 | 🔄 | | 2026-11-09: 7-B1, 7-E1..E3, 7-A1..A2b, 7-B2, 7-C ✅ (review R1 đạt 2026-11-09; xoá xong `modules/`). `einvoice_th08.sql` sửa theo schema và xanh ở 9-2 (`c57ac4185`). 2026-11-20: MISA bỏ sandbox → Dev dùng tài khoản thật, thêm chốt `MISA_MEINVOICE_PUBLISH_ENABLED` (mặc định tắt, 425 test Deno đạt). Còn: deploy `einvoice-processor`, reset Dev, đổi secret sang `api.meinvoice.vn` (RUNBOOK-einvoice mục 1), kiểm live **kết nối → mẫu → xem trước** |
| Theme 7 | 🔄 | — | Prototype + đặc tả xong (T7-P đóng 2026-10-27; T7-G4 ✅ FROZEN v5.27.0). **Cả 10 plan G5 ✅:** G5-0a, 0b, 2a, 2, 2b, 3, 4 (2026-11-11), 5, 5b, 6 (2026-11-12), 7, 8 (2026-11-13; R3: 709 test, `db_check` đạt). Còn: kiểm tay luồng demo trên Dev (tiêu chí 4), reset Dev |
| Tích hợp AI | 🔄 | | AI-0 ✅, AI-1 ✅ R4; AI-2 làm xong, review ⬜; AI-3 / AI-4 / AI-5 ⏸ từ 2026-11-18 (còn AI-5 Task 4 bộ 45 câu, lỗi màn đỏ bấm dòng đơn ở `/ask`, gỡ log `ai-trace`); công cụ `cong_no_phai_thu` chờ Theme 6 đóng. File plan AI-2…5 đã xoá ở `4d14f189c` khi chưa đóng review |
| Theme 6 | 🔄 | | T6-0, 1a, 1b, 2a, 2b ✅; T6-2c code + DB xanh, R2 đã sửa — còn review R3 + kịch bản 9.1 iPhone + web |
| Dọn dẹp | 🔄 | PR #1 (`207bde8ef`, gộp vào `dev`) | 9-1 ✅ R1; 9-2 ✅ (2026-11-19). Còn: reset Dev, đối chiếu DoD SCOPE mục 6 |
| Báo cáo | 🔄 | | 10-4, 10-5, 10-6 ✅; 10-7 còn task "Cuối"; 10.5 bỏ; `DATN.md` đang viết. Còn: 10-1, 10-2, 10.6 merge `main` + tag |

## Rủi ro theo mục

| Mục | Rủi ro | Cách xử lý |
|---|---|---|
| Theme 1 | Trigger trên `auth.users` lỗi làm hỏng việc xác minh email | Test kỹ ở local; trigger bắt lỗi rõ ràng; validate dữ liệu cửa hàng trên client trước khi `signUp` |
| Theme 1 | Email OTP local khó test | Dùng Inbucket/Mailpit có sẵn trong `supabase start` để đọc mã |
| Theme 2 / Theme 7 | SP-10 (tồn cơ bản) sau 5-C chạy qua `ProductRepository`; `set_basic_stock_quantity_base` không kiểm đơn vị cơ sở (chỉ UI chặn) | Theme 7 thay SP-10 (xem Q3 của 5-C, mục Theme 7) |
| Theme 7 | Mỗi BJ tự dựng lại row / sheet khiến UI lệch nhau | Khuôn K1–K7 + DS mới (mục Theme 7 → "Quy ước chung cho mọi plan G5"); Review kiểm trùng lặp trước khi ✅ |
| Theme 7 | Nhiều trạng thái → test phình | Rút gọn 2026-11-09: chỉ test trạng thái chính + lỗi chính |
| Theme 7 | Theme 7 lớn làm sau Theme 8 → dồn về cuối, vượt hạn 2026-12-02 | Rút gọn 2026-11-09 (mục Theme 7 → "Rút gọn 2026-11-09"); cần cắt thêm thì giữ G5-0b → G5-4 trước |
| Theme 5 / Theme 7 | Sales phải sửa 2 lần: chuyển kiến trúc ở Theme 5, nối sổ kho ở Theme 7 G5-4 | Theme 5 giữ tồn cơ bản đúng như cũ; G5-4 chỉ đổi chỗ đọc / ghi tồn, có test giữ hành vi 6 kịch bản |
| Mọi theme | Thêm bố cục web làm mỗi theme dài thêm (~10–20% phần UI; cao hơn từ 2026-10-22 vì không còn thiết bị phụ) | Không cắt bằng cách hạ một thiết bị xuống phụ. Dùng lại khuôn bố cục web chung (K7 của Theme 7) thay vì dựng lại từng theme; ước lượng lại trong plan từng theme |
| Theme 5 | Mất rule nghiệp vụ khi bỏ Aggregate | Bước 5 của công thức: port rule thành hàm thuần và giữ test cũ |
| Theme 5 | Từ lúc sổ kho Theme 7 chạy tới khi nối kho (G5-4), Sales cũ vẫn đọc tồn cơ bản không còn cập nhật | Chỉ ảnh hưởng Dev (Prod chưa chạy); G5-4 chuyển sang khả dụng của Theme 7 |
| Theme 8 | UI einvoice nằm ở module nên phải chuyển nhiều file | Chuyển nguyên thư mục trước, đổi dependency sau, 2 PR riêng |
| Dọn dẹp | ~~Gộp migration làm lệch schema~~ | Bỏ: không gộp migration (chốt 2026-11-19); 9-2 sửa migration gốc, kiểm bằng `db reset` + test SQL |

