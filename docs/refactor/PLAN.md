# Kế hoạch thực hiện refactor

> Đi kèm [SCOPE.md](SCOPE.md) (phạm vi và các quyết định đã chốt). File này trả lời câu hỏi: **làm gì, theo thứ tự nào, xong thì kiểm tra thế nào.**
> Branch làm việc: `refactor/simple-arch` (tách từ `feature/theme8`). Ngày lập: 2026-10-06.

## Tổng quan

```text
Chuẩn bị ─▶ Nền core/ ─▶ Theme 1 IAM ─▶ Theme 1 làm gọn IAM ─▶ Đợt kiểm IAM ─▶ Theme 3 Partner ─▶ Theme 2 Catalog ─▶ Theme 4 Pricing ─▶ Theme 5 Sales ─▶ Theme 8 E-invoice ─▶ Theme 7 Kho & Giá vốn ─▶ 8-D nối kho Sales ─▶ Theme 6 Công nợ ─▶ Dọn dẹp ─▶ Tích hợp AI ─▶ Báo cáo

Theme 7 — làm sau Theme 8 (chốt 2026-11-03); việc Theme 7 đã làm trước đó (T7-0…, prototype T7-P) giữ nguyên
Web cho app (W-1 khung, W-2 Theme 1): hoãn, sau Theme 7 prototype; W-1 trước màn Flutter web đầu tiên
```

**Đặt tên theo theme** (2026-10-14): mỗi mục nghiệp vụ mang số theme TH-0x của `docs/02-yeu-cau`; mục không thuộc theme nào (Chuẩn bị, Nền core, Dọn dẹp, Báo cáo) giữ tên riêng. **Thứ tự trong file = thứ tự làm.**

**Thứ tự chốt lại 2026-11-03 (thay thứ tự 2026-10-14 bên dưới):** chuyển **hết các theme đã có code** sang kiến trúc mới trước (Theme 2 → Theme 4 → Theme 5 → Theme 8), **rồi** mới làm Theme 7. Hệ quả (người dùng chốt): (1) việc nối kho của Sales **8-D** tách khỏi Theme 5, thành mục riêng chạy ngay sau Theme 7; Theme 5 chuyển kiến trúc và giữ tồn cơ bản như hiện tại, sau 8-D thì quay lại sales một lần; (2) Theme 6 (dựng mới) làm sau 8-D; (3) 5-C (dọn module catalog + inventory, chạy sau Theme 7) thành **dọn module cuối**, nên việc xoá hẳn `modules/` và các package chỉ module dùng chuyển từ 7-C sang 5-C. **Sửa 2026-11-04:** 5-C làm **ngay** (SP-10 chuyển sang `ProductRepository`, không chờ Theme 7) ⇒ 7-C lại là dọn module cuối: xoá `modules/` + `vet45_adapters`, `vet45_generator` trở về 7-C; `vet45_annotations` xoá ở 9-1 (cùng `vet45_shared`, vì `vet45_shared_application` re-export nó).

**Thứ tự chốt 2026-10-14 (đã thay):** Theme 7 (Kho & Giá vốn, dựng mới theo spec v1) làm **trọn một lượt ngay sau Theme 2**, vì nó chỉ cần sản phẩm / ĐVT (Theme 2) và nhà cung cấp (Theme 3), và thay luôn tồn kho cơ bản của Theme 2. Theme 5 (Sales) làm sau Theme 7 để nối sổ kho thật một lần (8-D) thay vì refactor xong rồi quay lại. Theme 8 (HĐĐT) làm sau Theme 5, gắn khu HĐĐT vào màn chi tiết đơn đã refactor.

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
| Theme 1 | Auth, đăng ký cửa hàng, IAM | 5 ngày (còn ~1–1,5: 2-B6, 2-B7) | Nền core | |
| Theme 1 (tiếp) | Làm gọn IAM: bỏ `modules/iam`, `apps/admin`, worker, luồng onboarding cũ, Platform Admin | 3 ngày | Theme 1 | Làm nối tiếp IAM khi còn nhớ ngữ cảnh |
| — | **Đợt kiểm IAM** (đóng Theme 1) | 0,5 ngày | Theme 1 (tiếp) | `db reset --linked` → kịch bản SQL → Vault → `functions deploy send-email` → bật xác minh email → kiểm tay TH-01 9.3 → tick CHECKLIST |
| Web cho app | Khung web thanh bên (W-1) + Theme 1 trên web (W-2) | ~1,5 ngày | Theme 1 | Chốt thiết bị 2026-10-20. **Hoãn** sau Theme 7 prototype; W-1 phải xong trước màn Flutter web đầu tiên |
| Theme 3 | Partner (+ dọn module, 3 module rỗng) | 1 ngày | Theme 1 | Nhỏ; Theme 7 (nhà cung cấp), Theme 4, Theme 5 cần nó |
| Theme 2 | Catalog + tồn kho cơ bản (+ dọn module 5-C) | 2 ngày | Theme 1 | Lớn; Theme 7, Theme 4, Theme 5 cần nó |
| Theme 4 | Pricing (+ dọn module) | 1 ngày | Theme 3, Theme 2 | Sales cần giá |
| Theme 5 | Sales (+ dọn module; **8-D tách sau Theme 7**) | ~2,5 ngày | Theme 3, 2, 4 | Chuyển kiến trúc trước Theme 7 (chốt 2026-11-03); giữ tồn cơ bản tới 8-D |
| Theme 8 | E-invoice (+ dọn module einvoice, `vet45_misa`) | ~3,5 ngày (dựng lại khung 2026-11-08: thêm 3 plan Edge Function) | Theme 5 | Khu HĐĐT trên đơn (7.3) gắn vào màn chi tiết đơn **đã refactor** ở Theme 5; server trước (worker đã xoá, hiện không có gì chạy lệnh MISA); hạ tầng Edge Function + `pg_cron` giống 2-B2 |
| Theme 7 | **Kho & Giá vốn** (dựng mới; 17 BJ + CAP-01, 73 màn) | ~12 ngày UI + ~4 ngày backend | Theme 2, Theme 3; làm sau Theme 8 | Chốt 2026-11-03: chuyển hết theme đã có code trước rồi mới làm Theme 7. Thay tồn kho cơ bản của Theme 2. Trong theme: **UI trước** (fixture), backend sau |
| 8-D | Nối kho cho Sales: xuất kho khi checkout, hoàn nguyên khi huỷ, nhận hàng trả, khả dụng khi chọn sản phẩm | ~0,5–1 ngày | Theme 7, Theme 5 | Tách khỏi Theme 5 (chốt 2026-11-03); sửa lại sales một lần sau khi có sổ kho |
| Theme 6 | **Công nợ phải thu khách hàng** (từ đơn bán) + thu tiền + cấn trừ; không có phải trả nhà cung cấp | ~4,5 ngày | Theme 5, Theme 3 | Phải thu đi ra từ công nợ đơn của Theme 5 |
| Dọn dẹp | Dọn dẹp còn lại (`vet45_shared`, Melos, DB messaging, baseline) | 1 ngày | Nền core → Theme 6 (sau 5-C, 8-D) | Thứ tự 2026-11-03: theme cuối là Theme 6 |
| Tích hợp AI | Trợ lý "Hỏi VET45" (Gemini API) hỏi đáp số liệu + dự báo nhập hàng (giảng viên yêu cầu "tích hợp AI vào app") | ~4,5 ngày | Dọn dẹp (cần dữ liệu thật của các theme) | Người dùng chốt làm **cuối cùng** (2026-10-27); trợ lý hỏi đáp + dự báo nhập hàng, Gemini API |
| Báo cáo | Tài liệu, sơ đồ cho báo cáo, kịch bản demo, tập bảo vệ | 3 ngày | Tích hợp AI | |
| | **Tổng phần còn lại** (từ 2026-10-27) | **~42 ngày** (Theme 7 ~16, Theme 6 ~4,5, AI ~4,5) — hạn đồ án **2026-12-02** (~36 ngày lịch): **hụt ~6 ngày** so với tốc độ đang tính | | |

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

Khi đã có file plan, cột **Plan** ghi trạng thái kèm link, ví dụ `📝 [plan](plans/T7/T7-1-ton-kho-bj01.md)`; plan đã làm + review xong thì xoá tệp, ô ghi `✅ plan (đã xoá)` (nội dung tra lại trong lịch sử git, vd. `git show c0faec9e2^:<đường dẫn>`). Tiến độ theo dõi trong bảng của từng Theme.

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

1. App `erp` không còn import `vet45_<module>_*` — kể cả chỗ feature **khác** đang gọi chéo (đo 2026-10-11: `sales/presentation` gọi catalog 2, partner 1, pricing 2, einvoice 20; `pricing/presentation` gọi catalog 2, partner 1; `dashboard/presentation` gọi inventory 2).
2. Xoá thư mục module + mục workspace / DI / router / test liên quan.
3. DB của schema đó: bỏ outbox / inbox / RPC / bảng chỉ module cũ dùng — **sửa migration gốc** (quy tắc migration bên dưới).
4. Ràng buộc thứ tự: `modules/einvoice` phụ thuộc `partner/integration_events` và `sales/integration_events` → 4-C giữ `partner/integration_events`, 8-C giữ `sales/integration_events`, tới 7-C. Từ 2026-11-04 5-C làm ngay sau 5-W (SP-10 sang `ProductRepository`), nên **7-C là module cuối**: xoá `modules/` và `vet45_adapters` / `vet45_generator` ở 7-C; `vet45_annotations` ở 9-1 (`vet45_shared_application` re-export nó). (Bản 2026-11-03: 5-C là module cuối, chạy sau Theme 7 — đã thay.)



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

Ưu tiên **iPhone** và **web trên máy tính**; Android build từ cùng mã, xếp sau; không iPad, không app macOS / Windows. Khung web = **thanh bên trái**, cửa sổ hẹp về thanh dưới 5 tab. **Cả hai đều là thiết bị chính ở mọi màn** (sửa 2026-10-22). Chi tiết: [LUONG-UNG-DUNG mục 1.1](../02-yeu-cau/LUONG-UNG-DUNG.md#11-thiết-bị-và-khung-chốt-2026-10-20).

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
- Theo `CLAUDE.md`: chạy GitNexus `impact` trước khi sửa symbol, và `detect_changes` trước khi commit.
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
| **2-B1** | (b) Đăng ký cửa hàng mới: trigger DB, cấu hình OTP, `/login`, `/signup`, `/verify-email`, `/no-organization`, banner hồ sơ pháp lý; thêm nhánh guard "chưa xác minh", "không có tổ chức", chọn tổ chức hoạt động đầu tiên                                                                                                                                                                        | 2A.1, 2A.2, 2A.3, 2B.1, 2B.2, 2B.3, 2B.4, 2B.7 | ✅ [plan](plans/P2/2-B1-dang-ky-cua-hang.md)               | ✅   | 🔄 DB ✅, xác minh email đã bật (2026-10-28); chờ kiểm tay |
| **2-B2** | (b) Email qua Edge Function `send-email`: `iam.email_jobs`, `enqueue_outbox_message` chuyển email sang job, `pg_net` + `pg_cron`, Resend                                                                                                                                                                                                                                                         | 2A.4                                           | ✅ [plan](plans/P2/2-B2-email-edge-function.md)            | ✅   | 🔄 SQL ✅, `send-email` đã deploy, Vault ✅ (2026-10-28); chờ gửi mail lời mời thật |
| **2-B3** | (b) Sửa KI của TH-01: KI-02 (`accept_invitation` kích hoạt lại thành viên đã loại), KI-06, KI-10…KI-14, phần app của KI-05 (bỏ readiness cửa hàng). KI-03 và KI-05 DB/platform dời P3                                                                                                                                                                                                            | TH-01 mục 9.2                                  | ✅ plan (đã xoá)                     | ✅   | ✅                                                                   |
| **2-B4** | (b) Hoàn thiện sau rà soát TH-01: mất quyền khi đang dùng → tải lại phiên; đổi mật khẩu xong đăng xuất; câu lời mời tổ chức tạm ngừng; đăng ký lại cùng email (A3); đếm ngược gửi lại (A4)                                                                                                                                                                                                       | Rà soát 2026-10-10                             | ✅ plan (đã xoá)                 | ✅   | ✅                                                                   |
| **2-B5** | (b) Nhân viên chưa có tài khoản chỉ nhập mã lời mời 8 ký tự (bỏ mã 6 số): Edge Function `invitation-signup` tạo tài khoản đã xác minh + nhận lời mời                                                                                                                                                                                                                                             | Quyết định 2026-10-12                          | ✅ [plan](plans/P2/2-B5-loi-moi-mot-ma.md)                 | ✅   | 🔄 code đạt; `invitation-signup` đã deploy (2026-10-12); chờ kiểm tay |
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

Đặc tả chi tiết (chuỗi UI, quy tắc, sửa lỗi KI-02…KI-14, kịch bản kiểm thử): [TH-01 v4.0](../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md) mục 4, 9.2, 9.3.

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
| **3-C** | (app) App không còn phụ thuộc `vet45_iam_*`: hằng số / DTO sang core, `SessionStore` + 4 lớp contract thay `IamSession` / `IamStartup`, Sales bỏ `IIamModule`, viết lại 27 test                                                                                                                                                        | Làm gọn IAM (2026-10-11) | ✅ plan (đã xoá) | ✅   | ✅              |
| **3-D** | Xoá `modules/iam`, `apps/admin`, `apps/messaging_worker` + workspace / CI / script                                                                                                                                                                                                                                                     | Làm gọn IAM; kéo 9.1 lên | ✅ plan (đã xoá)            | ✅   | ✅              |
| **3-B** | (DB, sau 3-D, cùng đợt kiểm IAM) KI-08 chặn chuyển Owner cho người đã là Owner nơi khác; dọn onboarding / `provisioning` / `pending_activation`; FK `memberships.user_id` (KI-03)                                                                                                                                                      | 3.4, 3.6                 | ✅ plan (đã xoá)  | ✅   | ✅ (2026-10-12) |
| **3-E** | Bỏ Platform Admin (thay phương án A của 3-A, quyết định 2026-10-12): xoá `features/platform_admin`, G7, RPC `platform_*`, `platform_admins`, `platform_audit_logs`, `vet45 admin`; tổ chức / tài khoản chỉ còn hoạt động (bỏ cột `status`, ID-09, `TENANT_SUSPENDED/CLOSED`); bỏ chuyển Owner (KI-08). Làm trước khi tiếp đợt kiểm IAM | Quyết định 2026-10-12    | ✅ plan (đã xoá)     | ✅   | ✅ (2026-10-12) |


Chi tiết từng việc:


| #   | Việc                                                                                                                                                                 |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 3.1 | `features/platform_admin/`~~,~~ `SessionController.isPlatformAdmin`~~, guard G7~~ — làm ở 3-A, gỡ ở 3-E                                                              |
| 3.2 | ~~Chuyển từ~~ `apps/admin`~~: danh sách / chi tiết tổ chức, tạm ngừng / khôi phục / đóng, đổi chủ sở hữu~~ — làm ở 3-A, gỡ ở 3-E                                     |
| 3.3 | ~~Lối vào "Quản trị nền tảng" ở tab Thêm và~~ `/no-organization` — làm ở 3-A, gỡ ở 3-E                                                                               |
| 3.4 | ~~KI-08:~~ `transfer_platform_tenant_ownership` ~~chặn người nhận đã là Owner nơi khác~~ — làm ở 3-B, bỏ cùng chuyển Owner ở 3-E                                     |
| 3.5 | `vet45 admin create` ~~+ admin mẫu trong~~ `seed.sql` — gỡ ở 3-E                                                                                                     |
| 3.6 | KI-03 FK `memberships.user_id`; xoá onboarding cũ, owner activation, readiness RPC, trạng thái `provisioning` / `pending_activation` (3-B)                           |
| 3.7 | Bỏ `modules/iam`, `apps/admin`, `apps/messaging_worker`; app hết `vet45_iam_*` (3-C, 3-D)                                                                            |
| 3.8 | Bỏ Platform Admin: RPC `platform_*`, bảng `platform_admins`, `platform_audit_logs`; cột trạng thái tổ chức / tài khoản; ID-09 phần tổ chức / tài khoản bị chặn (3-E) |


**Không chuyển** từ `apps/admin`: toàn bộ (sau 3-E).

**Xong khi:** repo không còn `modules/iam`, `apps/admin`, `apps/messaging_worker`, `features/platform_admin`; DB không còn RPC onboarding / `platform_*`, cột trạng thái tổ chức / tài khoản; `db reset --linked` + kịch bản SQL IAM chạy qua (đợt kiểm IAM).

---



## Web cho app (W) (~1,5 ngày)

**Trạng thái:** 🔄 (2026-10-28; trước đó hoãn 2026-10-20, người dùng): làm Theme 7 trước (prototype T7-P, gồm khung web trên prototype), rồi mới quay lại từng theme đã làm; người dùng lướt lại tài liệu một lượt trước khi giao. W-1 phải xong **trước khi code Flutter màn web đầu tiên** (Theme 7 **T7-G5** hoặc theme đầu tiên quay lại). **2026-10-28:** W-1 ✅ (R2), commit `72b4cc2dd`. **2026-10-29:** W-2 ✅ (R4), commit `1bd9268af`. Chỉ còn kiểm tay (gộp đợt đóng Theme 1).

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **W-1** | Khung web: thanh bên trái 5 mục (+ mục con của "Thêm"), ngưỡng bề rộng chuyển thanh dưới ↔ thanh bên, `VDensity.compact` khi thao tác chuột, vùng nội dung giới hạn bề rộng; 5 tab thành `StatefulShellRoute` có URL (~2 ngày) | W.1–W.4 | ✅ plan (đã xoá) | ✅ | ✅ R2 (2 góp ý P3 không chặn; kiểm tay người dùng tự làm); commit `72b4cc2dd` |
| **W-2** | Theme 1 trên web: màn công khai (đăng nhập, đăng ký, xác minh, lời mời) căn giữa cột hẹp; quản trị tổ chức / người dùng / vai trò / nhật ký dạng danh sách – chi tiết hoặc bảng. Gộp hoặc làm ngay sau 2-B6 / 2-B7 (UI/UX auth, IAM — chưa làm) để không sửa một màn hai lần | W.5, W.6 | ✅ [plan](plans/W/W-2-theme1-web.md) duyệt 2026-10-28; rà theo "test giữ hành vi trước" cùng ngày (bổ sung 4 chỗ sót + bảng H1–H13 + bước 0; Q7 sheet lọc iPhone đổi theo DS) | ✅ | ✅ R4 2026-10-29 (2 góp ý P3 không chặn; còn kiểm tay 6.2 — người dùng); commit `1bd9268af`. Kiểm tay xong thì xoá plan |

Chi tiết từng việc:

| # | Việc |
|---|---|
| W.1 | Shell của router: một `ShellRoute` dựng thanh dưới hoặc thanh bên theo bề rộng; giữ nguyên route và guard (LUONG-UNG-DUNG mục 3) |
| W.2 | Thành phần thanh bên trong `vet45_design_system` (cùng mục, nhãn, `Semantics` như `VBottomNavigationBar` — 10-4); test |
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
| **4-A** | (a) Chuyển partner sang `PartnerRepository` (model, rule, cubit → `logic/`, sales + pricing + router + DI, `FakePartnerRepository`) + rule MST dùng chung; bỏ so version / kiểm quyền ở client, câu lỗi theo TH-03 6.4 (chốt 2026-11-01) | 4.1, 4.2                | ✅ [plan](plans/P4/4-A-partner-repository.md) duyệt 2026-11-01 | ✅ 2026-11-01 (chưa commit) | ✅ R1 2026-11-01 (3 góp ý P3 không chặn; còn kiểm tay 7.2 — người dùng) |
| **4-B** | (b) Trigger lịch sử giao dịch đối tác từ `sales.sales_orders` + các sửa KI của TH-03 (03, 05, 07 `unaccent`, 09, 10, 11, 13) + toast lỗi màn người liên hệ + test SQL TH-03 9.3 | 4.3, TH-03 mục 9.2      | ✅ [plan](plans/P4/4-B-sua-ki-th03.md) duyệt 2026-11-01 | ✅ 2026-11-01 (chưa commit; SQL chưa chạy trên DB local đúng HEAD) | ✅ R1 2026-11-01 (code đạt; còn người dùng: reset local + `partner_th03.sql`, reset Dev, kiểm tay 7.2) |
| **4-W** | (web) Theme 3 trên web: danh sách – hồ sơ 2 cột trong tab KH & NCC (hồ sơ thành route con của tab, chốt 2026-11-01), 18 sheet → `showVAdaptiveSheet`; màn con giữ toàn màn cột 720 | Thiết bị (2026-10-20), TH-03 5.9 | ✅ [plan](plans/P4/4-W-partner-web.md) duyệt 2026-11-01 | ✅ 2026-11-01 (chưa commit) | ✅ R2 2026-11-02 (đã sửa R1-1, R1-2 của R1; 1 góp ý P3 không chặn; còn kiểm tay 6.2 — người dùng) |
| **4-C** | (dọn) **Dọn sạch module partner**: app hết `vet45_partner_*` (kể cả 1 chỗ ở `sales/presentation`, 1 ở `pricing/presentation`, router, DI); xoá `modules/partner/{domain,application,infrastructure}` — **giữ** `modules/partner/integration_events` **tới 7-C** (einvoice phụ thuộc); DB schema `partner`: bỏ outbox / inbox / RPC cũ không còn dùng (sửa migration gốc). Kèm: xoá 3 module rỗng `accounting`, `costing`, `dashboard` (erp không dùng), `packages/vet45_resend` (chỉ worker dùng), kiểm `apps/erp/example` | Dọn module (2026-10-11) | ✅ [plan](plans/P4/4-C-don-module-partner.md) duyệt 2026-11-01 | ✅ 2026-11-01 (chưa commit) | ✅ R1 2026-11-02 (code đạt; 3 góp ý P3 không chặn; còn người dùng: `db reset` local + `partner_th03.sql` / `iam_*.sql`, reset Dev) |


Chi tiết từng việc:

11 file gọi module, 8 cubit, 8 màn: danh sách, tạo, chi tiết, sửa, chuyển cá nhân → tổ chức, liên hệ, lịch sử.


| #   | Việc                                                                                                                                                                                        |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 4.1 | `PartnerRepository` (search, detail, create, update, transform, contacts, deactivate/reactivate/soft-delete, check duplicate)                                                               |
| 4.2 | Rule MST (10/12/10-3) dùng chung với IAM: chuyển vào `core/validation/tax_code.dart`                                                                                                        |
| 4.3 | **Trigger DB ghi lịch sử giao dịch đối tác**: trigger trên `sales.sales_orders` gọi `partner.upsert_partner_history` (TH-03 KI-02). `partner_action_logs` đã được ghi trong RPC, giữ nguyên |


Chia PR và các sửa lỗi đi kèm (KI-02…KI-13): xem [TH-03 mục 9.2](../02-yeu-cau/TH-03-doi-tac-giao-dich.md#92-chia-pr-của-p4).

**Xong khi:** 8 màn đã tick; tạo đơn bán cho khách thì khách đó không còn xoá được (`HAS_TRANSACTIONS`); 5 kịch bản đầu–cuối ở TH-03 mục 9.3 chạy qua.

---



## Theme 2. Catalog + tồn kho cơ bản (2 ngày)

**Trạng thái:** ✅ plan (2026-11-01) Đã viết và người dùng duyệt 6 plan 5-A1 → 5-A2 → 5-A3 → 5-A4 → 5-B → 5-W (điều kiện: giữ nghiệp vụ cũ, chỉ đổi những chỗ TH-02 KI / người dùng đã chốt); 5-C viết 2026-11-04 (làm ngay, không chờ Theme 7). Chốt cùng người dùng: chia 5-A **theo lớp** (dữ liệu 5-A1/5-A2, đổi UI một lượt 5-A3) vì các nhóm màn dùng chung kiểu / widget và test e2e đi xuyên mọi màn; bỏ RPC đọc trước / sau và kiểm quyền client, giữ rule đầu vào; chép hết kiểu + fake ở 5-A; SP-10 giữ module tới 5-C, bỏ KI tồn (01, 02, 04–07 phần tồn, 12: Theme 7 thay); bỏ sheet cảnh báo giá ngay ở 5-A3; promote migration nháp cặp cửa hàng–kho ở 5-A4; web: PCC trong tab, màn con có id trên URL, Cài đặt sản phẩm toàn màn cột 720


| Plan     | Nội dung | Gồm việc | Plan | Làm | Review |
| -------- | -------- | -------- | ---- | --- | ------ |
| **5-A1** | (a) Dữ liệu: model (chép từ module), phân loại lỗi catalog → `AppException` + câu lỗi TH-02 6.4, rule đầu vào, bộ dựng readiness / PCC, `ProductRepository` (kể cả 4 method hàng bán được cho Sales); test parity `old` / `new`. Chưa đổi UI | 5.1 (data) | ✅ [plan](plans/P5/5-A1-catalog-data-san-pham.md) duyệt 2026-11-01; rà lại theo code 2026-11-02 | ✅ 2026-11-03 (đã sửa R1-1 … R1-3, T1 … T4) | ✅ R2 2026-11-03 (đã sửa R1-1, R1-2, R1-3 của R1; thêm T1–T4) |
| **5-A2** | (a) Dữ liệu: `MeasurementUnitRepository`, `CustomFieldRepository`, `ProductPriceRepository` + model, rule; khung giá `customConfig` để server tự tính; không chép bộ cảnh báo giá | 5.2, 5.3, 5.4 (data) | ✅ [plan](plans/P5/5-A2-catalog-data-don-vi-truong-gia.md) duyệt 2026-11-01; rà lại theo code sau 5-A1 2026-11-03 (Q8 kiểm id) | ✅ 2026-11-03 | ✅ R3 2026-11-03 |
| **5-A3** | (a) Đổi **toàn bộ** UI catalog + sales + pricing + router + DI sang 4 repository một lượt; 15 cubit → `logic/`; câu lỗi theo 6.4 (KI-07 phần catalog); bỏ sheet "Xác nhận cảnh báo giá" (KI-16 phần sheet); chép `FakeCatalogModule` → `FakeCatalogBackend` + 4 fake repository + `FakeStockCatalogModule`. SP-10 giữ module | 5.1–5.4 (UI) | ✅ [plan](plans/P5/5-A3-catalog-ui-sang-repository.md) duyệt 2026-11-01; rà lại theo code sau 5-A2 2026-11-03 (Q12–Q14 đổi số, Q15 bỏ `final`) | ✅ 2026-11-03 (đã sửa R1-1…R1-10) | ✅ R3 2026-11-04 |
| **5-A4** | (a) Promote `_drafts/inventory_default_pair.sql` thành migration mới (DB dựng từ migration hiện thiếu 2 RPC ⇒ cổng chặn cả app) + `DefaultPairGateCubit` sang `DefaultPairRepository`; bỏ `IInventoryModule` khỏi DI | 5.5 | ✅ [plan](plans/P5/5-A4-cap-cua-hang-kho-mac-dinh.md) duyệt 2026-11-01; rà lại theo code + viết lại Task 0–4, duyệt lại 2026-11-04 | ✅ 2026-11-04 (chưa commit) | 🔄 R1 2026-11-04 chưa đạt (code đạt); đã sửa R1-1…R1-3, R1-4 lúc commit |
| **5-B**  | (b) KI-10 (server chặn > 8 ảnh), 13 (chip "Đã xóa"), 14 ("Giá cơ sở"), 15 (bỏ ô ghi chú), 16 (chữ thừa), 17, 18 (code chết checklist) + test SQL / widget TH-02 9.3. Không làm KI tồn (Theme 7 thay), KI-08 (Theme 5) | TH-02 mục 9.2 | ✅ [plan](plans/P5/5-B-sua-ki-th02.md) duyệt 2026-11-01; rà lại theo code sau 5-A3 2026-11-04 | ✅ 2026-11-04 (chưa commit) | ✅ R3 2026-11-04 (đã sửa R1-1…R1-4, R2-1; còn chạy `catalog_th02.sql` + kiểm tay 7.2 — người dùng) |
| **5-W**  | (web) Theme 2 trên web: danh sách – PCC 2 cột trong tab Sản phẩm (PCC là route con `/products/items/:productId`), 11 màn con thành `/products/items/:productId/<x>` toàn màn cột 720, mở từ màn tạo qua route gốc `…/view`; Cài đặt sản phẩm toàn màn; 15 sheet → `showVAdaptiveSheet` | Thiết bị (2026-10-20) | ✅ [plan](plans/P5/5-W-catalog-web.md) duyệt 2026-11-01; rà lại theo code sau 5-B 2026-11-04 (thiếu `extra` dùng `redirect`, đổi router test, Task 0–8) | ✅ 2026-11-04 (chưa commit) | ✅ R2 2026-11-04 (còn kiểm tay 6.2) |
| **5-C**  | (dọn) **SP-10 sang repository + dọn sạch module catalog + inventory** (làm ngay sau 5-W, không chờ Theme 7 — chốt 2026-11-04): SP-10 qua `ProductStockAdjustmentCubit` → `ProductRepository.setBasicStock` / `adjustBasicStock` (KI-07 phần app, KI-04; sửa mở từ checklist); fake / DI / nhóm `old` của test parity bỏ module; xoá `modules/catalog`, `modules/inventory` (3 tệp SQL khai báo → `supabase/sql/catalog/functions/`); DB: bỏ outbox / inbox `catalog`, `inventory` (sửa migration gốc), **giữ** mọi RPC, schema `catalog` (kể cả `unaccent_immutable`), `inventory`. **Không** xoá `modules/`, `vet45_adapters` / `vet45_generator` (7-C), `vet45_annotations` (9-1) | Dọn module (2026-10-11) | ✅ plan (đã xoá) | ✅ 2026-11-04 | ✅ R2 2026-11-04 |


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

Các sửa lỗi: [TH-02 mục 9.2](../02-yeu-cau/TH-02-san-pham-va-gia-ban.md#92-theo-pr-của-p5) (KI-01…KI-18) gom ở 5-B, trừ KI-07 phần catalog (5-A3), KI-16 phần sheet (5-A3), KI tồn 01, 02, 04–07 (phần tồn), 12 (Theme 7 thay, chốt 2026-11-01). Kiểm đơn vị đã bán khi xoá (TH-02 KI-08) làm ở P8 PR 8.1.

**Xong khi:** các màn catalog trong checklist đều đã tick (trừ SP-10: Theme 7 thay); kịch bản đầu–cuối 1–4 và test RPC ở TH-02 mục 9.3 trong phạm vi 5-B chạy qua (kịch bản 5 "điều chỉnh tồn hai máy" và test tồn 🔧: Theme 7); cổng cặp cửa hàng–kho chạy trên DB dựng từ migration.

---



## Theme 4. Pricing (1 ngày)

**Trạng thái:** 🔄 đang làm (2026-11-06): code + review xong cả 4 plan (6-A1, 6-A2, 6-B, 6-C; 6-C review R1 đạt 2026-11-06), đã commit. Còn việc người dùng: `db reset` local + `pricing_th04.sql`, reset Dev, kiểm tay (6-A2 7.2, 6-B 8.2). Chốt cùng người dùng: chia 6-A **theo lớp** như Theme 2 (6-A1 dữ liệu, 6-A2 đổi UI một lượt); Sales chuyển ngay trong 6-A (`SalesPricingRepository`); sửa luôn lỗi bật lại mất cờ ghi đè; câu lỗi thô đổi theo TH-04 6.4; **bỏ hẳn nhập Excel** (EP-04, PR-09) và màn "Chọn cách thêm" (PR-03) ngay ở 6-A, DB nhập xoá ở 6-C


| Plan    | Nội dung                                                                                                                                                                                    | Gồm việc                | Plan | Làm | Review |
| ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- | ---- | --- | ------ |
| **6-A1** | (a) Dữ liệu: model (chép từ module), phân loại lỗi → `AppException` + câu lỗi TH-04 6.4, rule đầu vào, `CustomerPriceRuleRepository`, `SalesPricingRepository`; test parity `old` / `new`. Bỏ RPC đọc trước (create / update context), sửa bật lại gửi đúng `p_acknowledge_overwrite`. Không làm nhập Excel. Chưa đổi UI | 6.1 (data) | ✅ [plan](plans/P6/6-A1-pricing-data.md) | ✅ 2026-11-04 (commit 6-A1…6-B) | ✅ R2 2026-11-04 (đã sửa R1-1 mã tiền tệ chữ hoa, R1-2 ghi lệch mã lỗi Q7) |
| **6-A2** | (a) Đổi UI pricing + Sales (`sales_pricing_lookup`, `sales_draft_backend`) + router + DI sang repository một lượt; 4 cubit → `logic/`; xoá màn nhập Excel (PR-09) và màn "Chọn cách thêm" (PR-03: nút thêm mở thẳng form); câu lỗi thô theo 6.4; `FakePricingModule` → `FakeCustomerPriceRuleRepository` + `RecordingSalesPricingRepository` | 6.1 (UI), 6.3 | ✅ [plan](plans/P6/6-A2-pricing-ui-sang-repository.md) | ✅ 2026-11-04 (commit 6-A1…6-B) | ✅ R3 2026-11-05 (đã sửa R1-1 state lịch sử, R1-2 + R2-1 ghi chép; còn kiểm tay 7.2 — người dùng) |
| **6-B** | (b) Các sửa KI của TH-04 (trừ KI-03: nhập Excel đã bỏ); bỏ lọc nhanh lịch sử "Nhập Excel" cùng KI-02; + 4 lỗi thấy khi viết plan (tên người tắt / cập nhật, tổng số, link banner trùng, chip "Tùy chọn") | TH-04 mục 9.2 | ✅ plan (đã xoá) | ✅ 2026-11-06 (commit 6-A1…6-B) | ✅ R2 2026-11-06 (đã sửa R1-1…R1-6; TH-04 lên 3.2; còn chạy `pricing_th04.sql` + kiểm tay 8.2 — người dùng) |
| **6-C** | (dọn) **Dọn sạch module pricing**: app hết `vet45_pricing_*` (sales đã chuyển ở 6-A2; nhóm `old` của test parity, `pubspec.yaml`); xoá `modules/pricing`; DB schema `pricing`: bỏ RPC cũ không còn dùng, **xoá phần nhập Excel** (4 RPC `*_customer_price_rule_import`, hàm phụ, bảng lô / dòng nhập, `catalog._resolve_product_unit_for_pricing_import`; kiểm dữ liệu nguồn `excel_import`) + 2 RPC đọc trước `get_customer_price_rule_create_context` / `update_context` (sửa migration gốc); giữ 4 cột truy vết nhập (bỏ FK), giữ `delete_customer_price_rule`, `save_remembered_price_from_order`; live test dọn qua RPC | Dọn module (2026-10-11) | ✅ [plan](plans/P6/6-C-don-module-pricing.md) duyệt 2026-11-06 | ✅ 2026-11-06 | ✅ R1 2026-11-06 (không có việc sửa; review cập nhật `TEST-BASELINE.md` mục "Sau 6-C"; còn `db reset` + `pricing_th04.sql`, reset Dev — người dùng) |


Chi tiết từng việc:

9 file gọi module, 5 cubit, 9 màn: danh sách, form, chi tiết, lịch sử, import, các màn chọn (sản phẩm/khách/đơn vị). Từ 2026-11-04 bỏ màn import và màn chọn cách thêm ⇒ còn 7 màn.


| #   | Việc                                                                                  |
| --- | ------------------------------------------------------------------------------------- |
| 6.1 | `CustomerPriceRuleRepository` (CRUD, tắt/bật, lịch sử, resolve áp dụng)               |
| 6.2 | ~~`PriceImportRepository` (template, start/confirm/cancel import)~~ — **bỏ** (2026-11-04, người dùng: bỏ nhập Excel) |
| 6.3 | Màn chọn sản phẩm/khách dùng lại `ProductRepository` (P5) và `PartnerRepository` (P4) — đã xong ở 4-A / 5-A3 (đo 2026-11-04) |


Chia PR và các sửa lỗi đi kèm (KI-02…KI-15): xem [TH-04 mục 9.2](../02-yeu-cau/TH-04-chinh-sach-gia.md#92-chia-pr-của-p6).

**Xong khi:** 7 màn còn lại đã tick (PR-03, PR-09 bỏ); 4 kịch bản đầu–cuối 1–4 ở TH-04 mục 9.3 chạy qua (kịch bản 5 nhập Excel bỏ).

---



## Theme 5. Sales (~2,5 ngày; 8-D tách sau Theme 7)

**Trạng thái:** 🔄 8-A1…8-A3 xong (review ĐẠT 2026-11-07); 8-A4 xong (review R2 ĐẠT 2026-11-07). Chốt cùng người dùng: chia 8-A **theo nhóm màn** (giữ bảng dưới); repository gọi thẳng RPC nhưng **trả DTO của `vet45_sales_application`**, chép kiểu + đổi import một lượt ở 8-C; lỗi repository là `AppException`; câu lỗi thô đổi theo TH-05 6.4 ngay ở (a); việc đổi hành vi / sửa DB của 8.1 (KI-07, TH-02 KI-08) sang 8-B. 8-B chia 3 plan (chốt 2026-11-07): 8-B1 server → 8-B2 app → 8-B3 Thu tiền, người dùng duyệt 2026-11-07; 2026-11-08: 8-C xong (review R1 ĐẠT).


| Plan     | Nội dung                                                                                                                                                                                                                                                                                                                                                                                         | Gồm việc                | Plan | Làm | Review |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------- | ---- | --- | ------ |
| **8-A1** | (a) Soạn đơn + nháp: `SalesDraftRepository` (5 RPC nháp, trả DTO của module — chép kiểu ở 8-C), lỗi `AppException`, câu lỗi SG-01 theo TH-05 6.4; `SalesDraftListCubit` + `SalesDraftBackend` → `logic/`. KI-07, TH-02 KI-08, KI-21, KI-22 → 8-B (chốt 2026-11-06) | 8.1 | 📝 [plan](plans/P8/8-A1-sales-nhap.md) | ✅ 2026-11-07 | ✅ 2026-11-07 |
| **8-A2** | (a) Checkout + thanh toán: `SalesCheckoutRepository` + `SalesPaymentRepository` + `SalesOrderRepository.get`; record payment/refund không chuyển (chốt 2026-11-07)                                                                                                                                                                                                                                                                                                                                                                      | 8.2                     | 📝 [plan](plans/P8/8-A2-sales-thanh-toan.md) | ✅ 2026-11-07 | ✅ 2026-11-07 |
| **8-A3** | (a) Tra cứu đơn + phiếu: `SalesOrderRepository` thêm list / search / detail / timeline / return summary / post-sale actions / cancellation; `SalesReceiptRepository` (generate / get / original / in / chia sẻ); câu lỗi thô SG-08 / SG-09 theo TH-05; KI-06/07/09 → 8-B (chốt 2026-11-07) | 8.3, 8.4                | 📝 [plan](plans/P8/8-A3-sales-tra-cuu-phieu.md) | ✅ 2026-11-07 | ✅ 2026-11-07 |
| **8-A4** | (a) Huỷ đơn + đổi/trả: `SalesCancellationRepository` (precheck / confirm) + `ReturnExchangeRepository` (precheck, returnable, preview giá, detail, start / update / cancel / confirm / complete, evaluate); bỏ `_get_return_exchange_context` trước confirm / evaluate; lớp request thay 6 command; câu lỗi + blocker theo TH-05 6.4; 3 cubit → `logic/`; KI-05/08/10/17/18 → 8-B (chốt 2026-11-07) | 8.5 | 📝 [plan](plans/P8/8-A4-sales-huy-doi-tra.md) | ✅ 2026-11-07 | ✅ 2026-11-07 |
| **8-B1** | (b) Server: KI-03 `CUSTOMER_INVALID`, KI-04 `RECEIVABLE_DUE_DATE_INVALID` (precheck / finalize / confirm đổi trả), KI-05 lưu ngày hẹn đổi hàng, KI-09 tìm đơn không dấu, TH-02 KI-08 đơn vị đã bán; KI-02 đã có ở finalize (chỉ test); câu mã chặn mới ở `_classifyResult`; `supabase/tests/sales_th05.sql` (TH-05 9.3) — chốt 2026-11-07 | TH-05 mục 9.2 (8.1, 8.2, 8.3, 8.5) | ✅ [plan](plans/P8/8-B1-sales-server-ki.md) duyệt 2026-11-07 | ✅ 2026-11-07 | ✅ R2 2026-11-07 |
| **8-B2** | (b) App: KI-07 (+ "Công nợ cũ" trên PDF), KI-08, KI-10, KI-17, KI-18; SG-01 KI-21 (trang 25, tải thêm, tìm + "Đơn của tôi" ở server theo người tạo), KI-22 ("Tạo bởi" từ server); xoá nháp `REFERENCE_UNAVAILABLE` = tải lại, câu "Không xóa được đơn nháp" — chốt 2026-11-07; review thêm: "Đơn nháp (N)" = tổng nháp cửa hàng (`total_count`), bỏ QR mẫu SG-06 (KI-23) — chốt 2026-11-07 | TH-05 mục 9.2 (8.1, 8.3, 8.5) | ✅ [plan](plans/P8/8-B2-sales-app-ki.md) duyệt 2026-11-07 | ✅ 2026-11-07 | ✅ R2 2026-11-08 (đã sửa R1-1…R1-6, R2-1, R2-2; còn `db reset` + `sales_th05.sql`, kiểm tay 7.2 — người dùng) |
| **8-B3** | (b) Màn Thu tiền SG-11 (KI-06 / EP-04): `SalesPaymentRepository.recordPayment`, mục "Thu tiền" ở sheet Thao tác, `showVAdaptiveSheet` (iPhone + web) — chốt 2026-11-07 | TH-05 mục 9.2 (8.3) | ✅ [plan](plans/P8/8-B3-sales-thu-tien.md) duyệt 2026-11-07 | ✅ 2026-11-08 | ✅ R2 2026-11-08 (đã sửa R1-1…R1-5; còn chạy `sales_th05.sql` P01–P04, kiểm tay 7.2 — người dùng) |
| **8-C** | (dọn) **Dọn sạch module sales**: app hết `vet45_sales_*` (20 file `sales/presentation` còn gọi einvoice chạy song song tới 7-A2); xoá `modules/sales` **trừ `modules/sales/integration_events`** (einvoice còn dùng, xoá ở 7-C); DB schema `sales`: bỏ messaging (inbox / internal_commands / hàm hàng đợi). **Chốt 2026-11-08:** `Core*` (`CoreExecutionContext` / `CorePermissionChecker` / `CoreTenantAccessChecker`) dời 7-C (einvoice còn dùng); giữ `sales.outbox_messages` làm nhật ký sự kiện của đơn (Lịch sử đơn); không xoá RPC nào | Dọn module (2026-10-11) | ✅ [plan](plans/P8/8-C-don-module-sales.md) duyệt 2026-11-08 | ✅ 2026-11-08 | ✅ R1 2026-11-08 (không có việc sửa; review cập nhật `TEST-BASELINE.md` mục "Sau 8-C"; còn `db reset` + `sales_th05.sql`, reset Dev — người dùng) |


Chi tiết từng việc:

20 file gọi module, 13 cubit, khoảng 20 màn. Chia thành 5 PR:


| PR  | Nhóm                  | RPC/Query chính                                                                                                                                                                    |
| --- | --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 8.1 | Soạn đơn + nháp       | save/update/cancel draft, list drafts, restore; preview pricing (gọi pricing). Sửa `catalog._product_unit_has_sales_transaction_usage` đọc dòng đơn / nháp / đổi trả (TH-02 KI-08) |
| 8.2 | Checkout + thanh toán | precheck checkout, **finalize_sales_order** (transaction ở DB), record payment/refund, settlement, payment summary                                                                 |
| 8.3 | Tra cứu đơn           | list/search/detail/timeline, post-sale actions                                                                                                                                     |
| 8.4 | Phiếu/biên lai        | generate/get receipt, original receipt, printed/shared, slip preview                                                                                                               |
| 8.5 | Huỷ đơn + đổi/trả     | cancellation (lý do, precheck, confirm); return/exchange (start, preview pricing, update, confirm, complete, cancel)                                                               |


**Integration event:** bỏ messaging; `sales.outbox_messages` giữ làm nhật ký sự kiện (8-C, 2026-11-08). Phát hành HĐĐT tự động dùng trigger trên `sales.sales_orders` khi đơn Hoàn tất, ghi việc vào `einvoice.internal_commands` (làm ở 7.5 của Theme 8, sau Theme 5; TH-08 KI-19, KI-20). Không gọi "nhớ giá từ đơn" (ngoài phạm vi, TH-04 KI-02). Trừ/cộng tồn khi bán, huỷ, đổi trả: Theme 5 **giữ tồn cơ bản như hiện tại** (chỉ chuyển kiến trúc); nối sổ kho Theme 7 ở **8-D**, mục riêng sau Theme 7 (chốt 2026-11-03).

**Xong khi:** đủ 6 kịch bản: bán thường, bán nợ rồi thu sau, hoàn tiền, huỷ đơn, đổi hàng, trả hàng. Công nợ (còn phải thu của đơn) đúng sau mỗi kịch bản. Tồn kho (tồn cơ bản) đúng như trước khi chuyển kiến trúc sau mỗi kịch bản; tồn theo sổ kho kiểm ở 8-D. Các màn sales trong checklist đều đã tick.

---



## Theme 8. E-invoice (~3,5 ngày)

**Trạng thái:** ⬜ Chưa làm. Dựng lại khung 2026-11-08 (người dùng chốt): **server trước** (7-B1 → 7-E1 → 7-E2a → 7-E2b → 7-E2c → 7-E3), rồi app (7-A1 → 7-A2 → 7-B2), cuối cùng 7-C; (a) chia **theo lớp** như Theme 2/4 (7-A1 dữ liệu, 7-A2 đổi UI một lượt); bố cục web làm trong 7-B2 (không có plan 7-W); mã cũ 7-1…7-5 đổi sang 7-A*, 7-B*, 7-E*, 7-C. Hiện trạng: 23 draft HĐĐT **đã promote** thành `20261031001…023` (`8b08bb01c`, 2026-11-02 — KI-18 xong, chưa sửa KI-02/04/06); `apps/messaging_worker` **đã xoá** (`c1d3a5445`, 2026-10-11) ⇒ hiện **không có gì chạy lệnh MISA** (phát hành / xem / tải / gửi / đối soát nằm im trong `einvoice.internal_commands`), và 8-C đã bỏ messaging sales ⇒ tín hiệu đơn Hoàn tất cho phát hành tự động đang đứt tới 7-E3.


| Plan     | Nội dung | Gồm việc | Plan | Làm | Review |
| -------- | -------- | -------- | ---- | --- | ------ |
| **7-B1** | (b) Server: KI-02 `update_automation_policy` bật tự động khi chưa sẵn sàng → `CONFIG_NOT_READY`; KI-04 kiểm người mua hiệu lực trong `issue_invoice` / `retry_issuance` / `start_auto_issuance` / `reevaluate_auto_issuance` (hàm chung `_buyer_issuance_blocker`) (`ISSUANCE_NOT_READY` + `BUYER_*`, tự động → `PENDING_REEVALUATION`); KI-06 chép lại trường người mua mỗi lượt khi chưa có hoá đơn + readiness ưu tiên hồ sơ hiện hành; KI-02 chỉ chặn khi bật mới; khoá 4 hàm bộ xử lý chỉ `service_role` (lỗi grant `authenticated`); map `CONFIG_NOT_READY` phía app → 7-A1 — chốt 2026-11-08. Sửa migration gốc (`20261031004` / `006` / `008` / `023`); `supabase/tests/einvoice_th08.sql` (phần SQL của TH-08 9.3) | 7.1 | ✅ [plan](plans/P7/7-B1-einvoice-server-ki.md) duyệt 2026-11-08 | ✅ 2026-11-08 | ✅ R1 2026-11-08 (ĐẠT, 4 góp ý nhỏ; còn `db reset` + `einvoice_th08.sql`, reset Dev — người dùng) |
| **7-E1** | Edge Function `supabase/functions/einvoice-processor` (Deno / TypeScript, `service_role`): client MISA (đăng nhập + token theo tổ chức, lấy mẫu, xem trước, phát hành, `getStatus`, tải, gửi email; phân loại lỗi như `packages/vet45_misa`) + chép 62 test của `vet45_misa` sang Deno test; khung hàng đợi (claim / complete / fail `internal_commands`, giới hạn số việc mỗi lần gọi, mật khẩu qua `read_provider_credentials`); handler `einvoice.sync_capabilities`; thêm `einvoice.list_tenants_with_due_commands`, sửa `reschedule_internal_command` ghi cột `updated_at` không có (KI-22) — chốt 2026-11-08 | 7.4 | ✅ [plan](plans/P7/7-E1-einvoice-processor-khung.md) duyệt 2026-11-08 | ✅ 2026-11-08 (chưa commit; còn `db reset` + `einvoice_th08.sql` — người dùng) | ✅ R2 2026-11-08 (ĐẠT; R1 sửa KI-23 `created_at` trong 7 `insert internal_commands` + CORS; còn `db reset` + `einvoice_th08.sql` E32–E34, E40, reset Dev — người dùng) |
| **7-E2a** | Luồng phát hành: `preview_invoice`, `publish_invoice` (+ khoá ký hiệu, **không** gia hạn — khoá 300 giây > giới hạn 150 giây), `poll_issuance_status` (đối soát) + dead-letter preview / publish; chép 106 test Dart; ca SQL khoá ký hiệu / thử lại bền E41–E45. Giữ nguyên RPC `record_*`, số lượt thử, lịch đối soát — chốt 2026-11-08 (7-E2 tách 3 plan theo luồng) | 7.4 | ✅ [plan](plans/P7/7-E2a-einvoice-processor-phat-hanh.md) duyệt 2026-11-08 | ✅ 2026-11-08 (chưa commit; còn `db reset` + `einvoice_th08.sql` E41–E45 — người dùng) | ✅ R2 ĐẠT 2026-11-08 (R1: E44 `now()`, Kết quả) |
| **7-E2b** | `fetch_official_view`, `download_invoice_document` (+ Storage), `poll_provider_observation` + dead-letter official view / document; chép 34 test Dart; `getForTenant` trả thêm `taxCode`; bucket `einvoice-documents` nhận `application/zip` (KI-24, sửa `20261031011`) + ca SQL E46 — chốt 2026-11-08 | 7.4 | ✅ [plan](plans/P7/7-E2b-einvoice-processor-tai-lieu.md) duyệt 2026-11-08 | ✅ 2026-11-08 (chưa commit; còn `db reset` + `einvoice_th08.sql` E46 — người dùng) | ✅ R2 ĐẠT 2026-11-08 (R1: `loadObservationContext` nuốt `NOT_FOUND`, log MISA không ra, Kết quả; còn `db reset` + `einvoice_th08.sql` E46 — người dùng) |
| **7-E2c** | `send_invoice_email`, `reconcile_invoice_delivery` + dead-letter delivery / reconciliation | 7.4 | ⬜ | ⬜ | ⬜ |
| **7-E3** | Kích hoạt phía server: `pg_cron` + `pg_net` gọi `einvoice-processor` mỗi 30 giây; trigger khi đơn Hoàn tất (`sales.sales_orders`) và khi hồ sơ khách đổi ghi thẳng `einvoice.internal_commands` (thay outbox / inbox); `record_issuance_success` tự xếp việc gửi tự động (KI-19, KI-20); chạy checklist MISA sandbox (`docs/themes/TH-08-e-invoice/harness/S1-MISA-SANDBOX-CHECKLIST.md`, `DEV-LIVE-ACCEPTANCE-CHECKLIST.md`) | 7.5 (server) | ⬜ | ⬜ | ⬜ |
| **7-A1** | (a) Dữ liệu: `EInvoiceRepository` (25 Command / Query app đang dùng → gọi thẳng RPC `einvoice`), model chép từ module, phân loại lỗi → `AppException` + câu lỗi theo TH-08 6.4, `IssuanceReadinessEvaluator` → `logic/`, test parity `old` / `new`; repository gọi `functions.invoke('einvoice-processor')` sau mỗi RPC ghi yêu cầu. Chưa đổi UI | 7.2, 7.3 (dữ liệu), 7.5 (app) | ⬜ | ⬜ | ⬜ |
| **7-A2** | (a) Đổi UI một lượt: 4 trang thiết lập (đang dùng `modules/einvoice/presentation`) + 21 file HĐĐT của `features/sales` (20 ở `presentation`, `logic/sales_order_detail_cubit.dart`) về `features/einvoice`, gộp bản trùng (KI-17), cubit → `logic/`; hỏi lại bằng `Timer` trong cubit thay `vet45_async_query`, giữ nhịp cũ, khoá theo tổ chức (KI-16); xoá màn / nút chết (KI-15); router + DI + fake repository | 7.2, 7.3 (UI) | ⬜ | ⬜ | ⬜ |
| **7-B2** | (b) App: KI-01 HD-04 hiện `last_verified_at` (không có thì bỏ dòng); KI-08 HD-12 lấy lần gửi **thành công** gần nhất; bố cục web: HD-01…05 cột 720, HD-07…13 qua `showVAdaptiveSheet` (iPhone + web) | 7.2, 7.3 | ⬜ | ⬜ | ⬜ |
| **7-C**  | (dọn; mã cũ 7-5) **Dọn sạch module einvoice**: app hết `vet45_einvoice_*` (21 file HĐĐT của `features/sales` đã chuyển ở 7-A2); xoá `modules/einvoice` (gồm `presentation` + `example`), `packages/vet45_misa` (thay bằng client TypeScript 7-E1), `packages/vet45_async_query` (hết người dùng sau 7-A2), `modules/partner/integration_events` (hết người dùng); `modules/sales/integration_events` (8-C để lại); **là module cuối** (5-C làm trước, 2026-11-04): xoá hẳn `modules/` (kiểm trước: 6-C, 8-C đã xoá `modules/pricing`, `modules/sales` trừ `integration_events`); và `packages/vet45_adapters`, `vet45_generator`; bỏ `CoreExecutionContext` / `CorePermissionChecker` / `CoreTenantAccessChecker` trong `core/session` (chuyển từ 8-C, 2026-11-08); **không** xoá `vet45_annotations` (9-1, `vet45_shared_application` re-export); test hợp đồng SQL einvoice còn giá trị chuyển sang `apps/erp/test/features/einvoice/data/`, 60 test đọc `_drafts/` xoá cùng module (như 6-C, 8-C); DB schema `einvoice`: bỏ outbox / inbox, **giữ** `internal_commands`; xét xoá `renew_publish_series_lease` (Edge Function không gia hạn khoá, 7-E2a Q2); xoá `platform.list_tenants_with_pending_messaging` / `messaging_module_registry` nếu hết người dùng (Edge Function dùng `einvoice.list_tenants_with_due_commands`, 7-E1). (`apps/messaging_worker` đã xoá từ 2026-10-11) | Dọn module (2026-10-11) | ⬜ | ⬜ | ⬜ |


Chi tiết từng việc:

Đặc tả: [TH-08](../02-yeu-cau/TH-08-hoa-don-dien-tu.md). Chia PR theo [TH-08 mục 9.2](../02-yeu-cau/TH-08-hoa-don-dien-tu.md#92-chia-pr-của-p7) (PR 7.1…7.5 ứng với việc 7.1…7.5 dưới đây; plan gom lại như bảng trên). Quyết định 2026-10-07: **giữ hành vi hiện có** (hàng đợi, đối soát nền, phát hành và gửi tự động, chống trùng) nhưng **bỏ** `apps/messaging_worker` (đã xoá 2026-10-11): mọi lệnh gọi MISA chuyển sang Edge Function `einvoice-processor` (TypeScript), kích hoạt bởi app và `pg_cron` mỗi 30 giây (TH-08 KI-20). UI e-invoice hiện tách giữa `modules/einvoice/presentation` và bản sao trong `features/sales` (KI-17).


| #   | Việc |
| --- | ---- |
| 7.1 | **DB**: ~~promote 23 file `supabase/migrations/_drafts/001…023` thành migration chính thức~~ — ✅ `8b08bb01c` (2026-11-02, KI-18); còn sửa `update_automation_policy` (KI-02), kiểm người mua trong `issue_invoice` / `retry_issuance` / `start_auto_issuance` (KI-04), chép lại trường người mua mỗi lượt (KI-06) — 7-B1 |
| 7.2 | **Thiết lập**: chuyển 4 màn vào `apps/erp/lib/features/einvoice/presentation`; `EInvoiceRepository` (kết nối, mẫu, chính sách, sẵn sàng) gọi RPC `einvoice`; KI-01, 15, 16 — 7-A1 / 7-A2 / 7-B2 |
| 7.3 | **Trên đơn** (Theme 5 đã refactor xong: gắn vào màn chi tiết đơn **mới**): `OrderEInvoiceSection` + 2 cubit dùng repository; gộp các sheet về một chỗ; hỏi lại trạng thái bằng `Timer` trong cubit (bỏ `vet45_async_query`, giữ hành vi); KI-08, 17 — 7-A1 / 7-A2 / 7-B2 |
| 7.4 | **Edge Function** `einvoice-processor`: viết lại client MISA bằng TypeScript (theo `packages/vet45_misa`, chép 62 test sang Deno) và handler cho 9 loại lệnh `internal_commands` (đồng bộ mẫu, xem trước, phát hành + khóa ký hiệu, đối soát, bản chính thức, tải tài liệu, quan sát, gửi email, đối soát gửi) — 7-E1 / 7-E2a / 7-E2b / 7-E2c |
| 7.5 | **Kích hoạt**: `pg_cron` + `pg_net` gọi Edge Function mỗi 30 giây; trigger khi đơn Hoàn tất và khi hồ sơ khách đổi ghi thẳng `internal_commands` (thay outbox/inbox); `record_issuance_success` tự xếp việc gửi tự động (KI-19, KI-20) — 7-E3; app gọi `functions.invoke` sau mỗi RPC ghi yêu cầu — 7-A1 |


**Xong khi:** chỉ với Edge Function (không còn worker): kết nối MISA sandbox → phát hành từ đơn → xem/tải PDF → gửi email → gửi lại → phát hành lại sau lỗi; tự phát hành + tự gửi chạy khi bật, kể cả khi app đã đóng; MISA timeout thì `pg_cron` đối soát ra đúng một hóa đơn (TH-08 mục 9.3).

---



## Theme 7. Inventory — Kho & Giá vốn

**Trạng thái:** 🔄 UI BJ-02, BJ-03 đã code trước khi có plan (chưa commit, review ở T7-0); T7-1 đã có plan; backend chưa lập plan

> **Thay tồn cơ bản của Theme 2 (chốt 2026-11-04, Q3 của 5-C):** khi BJ-08 (kiểm kê / điều chỉnh) và BJ-12 (tồn đầu kỳ) có màn: xoá SP-10 `product_stock_adjustment_page.dart` (đã chạy qua `ProductRepository` + `ProductStockAdjustmentCubit` từ 5-C) và route `/products/items/:productId/stock`; nút "Sửa" thẻ Tồn kho ở PCC và mục readiness `missing_stock` mở màn Theme 7 tương ứng; bước nhập tồn khi tạo sản phẩm giữ / bỏ theo plan Theme 7. DB tồn cơ bản giữ tới 8-D.

> Theme 7 gồm UI và backend. Làm **UI trước** (màn hình, trạng thái, điều hướng, test; plan `T7-0…T7-16`, ~12 ngày) trên fixture; cả UI lẫn backend làm **sau Theme 8** (chốt 2026-11-03, thay "UI song song, backend ngay sau Theme 2" của 2026-10-14; việc T7 đã làm giữ nguyên), plan mã `T7-B1…` chưa lập, khi lập thì thêm vào bảng Plan của mục này; riêng phần nối với bán hàng (xuất kho khi checkout, huỷ, hàng trả, BJ-04/05/06) làm ở **8-D**, mục ngay sau Theme 7. Nguồn: [`specs/themes/theme-07`](../../specs/themes/theme-07/README.md) v4.6.8 (17 BJ + CAP-01, FROZEN) và prototype `03.design/prototype/html`; đặc tả giữ nguyên v1 đầy đủ theo quyết định 2026-10-07 ([TH-07](../02-yeu-cau/TH-07-kho.md) chỉ là con trỏ). Phạm vi: **73 màn active / 421 trạng thái** (đếm mỗi màn một lần).


|                       |                                                                                                                                                                                      |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Dữ liệu | **Fixture trong bộ nhớ sau lớp Repository** (cùng cách BJ-02, BJ-03 đang làm), chép giá trị từ prototype để so mắt với HTML. Chữ ký repository giữ ổn định để thay thân bằng RPC khi có backend |
| Chưa làm trong đợt UI | RPC / migration; ghi tồn thật; số liệu tài chính thật; trừ tồn khi bán (nối ở 8-D) |
| Vai trò               | Như mọi phase: Claude viết plan và review, bạn tự code                                                                                                                               |
| Thẩm quyền            | Nghiệp vụ: BJ / UC / UIF / Screen Contract. Thành phần, token, mật độ: Figma DS (`DS-CONFORMANCE.md` của prototype). HTML prototype là chuẩn đối chiếu hình ảnh                      |




### Plan


| Plan      | Nội dung                                                                                                                                                              | Gồm việc (màn · số trạng thái)                    | Plan                                     | Làm | Review |
| --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- | ---------------------------------------- | --- | ------ |
| **T7-0**  | (Đợt 0, ~2 ngày, 2 PR) Sửa lỗi dữ liệu và luồng phê duyệt BJ-02/03 (review 2026-10-14): thêm trùng ghi đè, dòng chưa xong bị bỏ, HSD tự điền, mã lô / số âm, BJ-03 xác lập hai lần, người lập tự duyệt, gửi xong sai màn | BJ-02 (58), BJ-03 (21) | ✅ plan (đã xoá) | ✅   | ✅ (2026-10-14) |
| **T7-0b** | (Đợt 0, ~2 ngày, 2 PR) BJ-02 nhập hàng nhanh đúng spec: SCR-006/008/009/084/010/011/012 (câu chữ, bố cục, tìm sản phẩm trên màn, HSD theo cách ghi bao bì, lô trùng khác hạn) + 3 góp ý review T7-0 | SCR-006, 008, 009, 084, 010, 011, 012 | ✅ plan (đã xoá) | ✅ | ✅ (2026-10-14; G1, G2 chuyển T7-0c) |
| **T7-0c** | (Đợt 0, ~1,5–2 ngày, 2 PR) Sửa còn lại của T7-0b (G1 key thẻ lô, G2 "Sửa" ở SCR-010) + trạng thái chung BJ-02 qua `ReceiptScenario` (không quyền, kho khoá, dữ liệu vừa đổi, chưa có người duyệt, đang ghi nhận, chưa rõ kết quả, bị chặn) + SCR-013 Đối soát + bảng trạng thái → test | SCR-006…013 | ✅ plan (đã xoá) | ✅ | ✅ (2026-10-14) |
| **T7-P0** | (Trước T7-P tiếp, ~5–6 ngày, 4 PR) Dọn prototype: công cụ golden (chụp mọi UIF × màn × trạng thái), xoá 18 file không nạp + CHANGELOG / qa cũ + Hub v3.8, gộp 68 CSS → tokens / components / screens, gộp 45 JS → `core.js` + một file mỗi BJ, gộp lớp `v470`–`v472` vào nguồn; golden phải khớp. Từ đây sửa thẳng vào file sở hữu, không tạo lớp vá | Prototype toàn Theme | ✅ plan (đã xoá) | ✅ khung chung + token + Hub (từng BJ viết lại ở T7-P) | ✅ 2026-10-16 (mục 11 của plan) |
| **T7-P**  | Thiết kế lại Theme 7 trên prototype — **chỉ prototype**, ba giai đoạn: GĐ1 viết lại code sạch cho 17 BJ + CAP-01 theo 11 gói A1–A11 (~20 ngày, golden khớp, giao diện không đổi); GĐ2 thiết kế lại từng BJ theo 6 chặng (brief → bạn duyệt → plan thực thi → bạn làm, ~24 ngày); GĐ3 hoàn thiện (8 gói G3-0…G3-7, ~8–9 ngày: dọn CSS, khung dùng chung, sổ kho chung, không ngõ cụt, critique ≥ 32/40). Chốt đặc tả và Flutter: T7-G4, T7-G5. Phiên này chỉ viết plan / brief và review | Prototype toàn Theme | ✅ [plan tổng thể](plans/T7/T7-P-thiet-ke-lai-luong.md) · ✅ GĐ3 (đã xoá) | ✅ GĐ1 (`v5.3.0`) · GĐ2 (`v5.20.1`) · GĐ3 (`v5.26.1`, 2026-10-27; critique 31/40, mục tiêu 32 chưa đạt — người dùng chốt đóng) | ✅ **Đóng hẳn** 2026-10-27 (GĐ1 ✅ · GĐ2 ✅ · review GĐ3 chuyển T7-G5; lỗi sau đó sửa theo yêu cầu) |
| **T7-G4** | (Sau T7-P GĐ3, ~1–2 ngày) **Chốt đặc tả**: áp các đề xuất ⬜ của [T7-P mục 13](plans/T7/T7-P-thiet-ke-lai-luong.md) vào UC / BJ / PROC / Screen Contract / UIF; rà toàn bộ `03.design`, đổi `IN_REVIEW` → `FROZEN` đồng loạt với mốc phiên bản mới; `PAT-UI-UX` / `PAT-NAV` theo khuôn dùng chung K1…K7 (T7-P mục 5); `INDEX.md`, registry (`sync-registry.py`). Gồm chữ còn treo của GĐ3 (K3 lặp câu ở `UIF-13_SCR-089_UNKNOWN`) | Tài liệu Theme 7 | ⬜ (phiên review viết, bạn duyệt) | ⬜ | ⬜ |
| **T7-G5** | (Sau T7-G4) **Nối sang Flutter**: rà lại T7-0d, T7-1, T7-0e theo prototype đã chốt; plan sửa phần BJ-02 / 03 đã code; thành phần DS mới ([T7-P mục 6](plans/T7/T7-P-thiet-ke-lai-luong.md)) vào `vet45_design_system`; rồi đi tiếp T7-1…T7-15 (T7-15 dựng Home Kho candidate). W-1 phải xong trước màn web đầu tiên. Việc GĐ3 hoãn sang đây (chốt 2026-10-26: xong G3-7 là đóng T7-P, phần còn lại làm sau): gom CSS theo BJ / bỏ `!important` (còn 55 luật) không cần làm nữa (CSS prototype không còn là nguồn); vùng ảnh BJ-02 / 06 sang `k5Evidence`; lô Amox thống nhất giữa BJ-01 / 06 / 08 / 09; số giữ hàng Nobivac khớp BJ-04; fixture BJ-07 dựng theo tồn BJ-01; review các gói G3-1…G3-7 (plan G3 mục 14) | Flutter toàn Theme | ⬜ (phiên review viết plan từng phần) | ⬜ | ⬜ |
| **T7-0d** | (Đợt 0, ~2,5 ngày, 2 PR) BJ-02 nhận theo chứng từ: fixture chứng từ mua + bản nháp tự lưu + kiểm phiên bản; SCR-007; chế độ chứng từ của SCR-009 / 084 / 010 / 011 / 012 (`Chưa nhận lần này`, chênh lệch, `Đổi chứng từ`, chỉ duyệt khi vượt, không vượt thì ghi nhận ngay, tổng giá trị rủi ro); đổi đường dẫn phiên `quick` → `session` | SCR-007, 009, 084, 010, 011, 012 | 📝 [plan](plans/T7/T7-0d-nhan-theo-chung-tu.md) | ⬜ | ⬜ |
| **T7-0e** | (Đợt 0, ~1,5 ngày) BJ-03 theo spec (SCR-014/015/017/019 + trạng thái, form căn cứ: Tiền tệ, không chọn sẵn cách hiểu giá) + kiến trúc / DS còn lại BJ-02/03 (Cubit cho page còn lại, `VToast`, token màu, widget dùng chung, tiền số nguyên) | BJ-03 (21) | ⬜ | ⬜ | ⬜ |
| **T7-1**  | (Đợt 1, 1,5 ngày) BJ-01 Tồn kho & khả dụng                                                                                                                            | SCR-001, 003 · 10                                 | 📝 [plan](plans/T7/T7-1-ton-kho-bj01.md) | ⬜   | ⬜      |
| **T7-2**  | (Đợt 1, 1,5 ngày) BJ-13 Điều chỉnh giá trị hàng nhập                                                                                                                  | SCR-085, 086, 089 · 16                            | ⬜                                        | ⬜   | ⬜      |
| **T7-3**  | (Đợt 1, 2 ngày) BJ-14 Tính và công bố giá vốn                                                                                                                         | SCR-072, 074, 077 · 13                            | ⬜                                        | ⬜   | ⬜      |
| **T7-4**  | (Đợt 2, 3 ngày) BJ-04 Giữ hàng (chỉ đọc) + BJ-05 Lấy hàng và bàn giao                                                                                                 | SCR-021 · 3; SCR-025…029 · 23                     | ⬜                                        | ⬜   | ⬜      |
| **T7-5**  | (Đợt 2, 3 ngày) BJ-06 Hàng khách trả                                                                                                                                  | SCR-030…035 · 38                                  | ⬜                                        | ⬜   | ⬜      |
| **T7-6**  | (Đợt 2, 2,5 ngày) BJ-07 Trả nhà cung cấp — **dựng 3 màn dùng chung** cho BJ-09/10                                                                                     | SCR-036, 037, 039, 041 · 24                       | ⬜                                        | ⬜   | ⬜      |
| **T7-7**  | (Đợt 3, 2 ngày) BJ-09 Trạng thái hàng + SCR-056 (dùng lại ở T7-13)                                                                                                    | SCR-038 · 8; SCR-056 · 6; chế độ trên 036/037/041 | ⬜                                        | ⬜   | ⬜      |
| **T7-8**  | (Đợt 3, 2 ngày) BJ-10 Tiêu hủy hàng                                                                                                                                   | SCR-040 · 10; chế độ trên 036/037/041             | ⬜                                        | ⬜   | ⬜      |
| **T7-9**  | (Đợt 3, 3,5 ngày) BJ-08 Kiểm kê (đếm mù, `VNumericKeypadSheet`)                                                                                                       | SCR-042…047 · 34                                  | ⬜                                        | ⬜   | ⬜      |
| **T7-10** | (Đợt 4, 3 ngày) BJ-11 Hủy và sửa sai nghiệp vụ kho                                                                                                                    | SCR-048…053 · 37                                  | ⬜                                        | ⬜   | ⬜      |
| **T7-11** | (Đợt 4, 3 ngày) BJ-16 + BJ-17 Đối soát và phục hồi UNKNOWN (một bộ màn, hai ngữ cảnh vào)                                                                             | SCR-078…083 · 36                                  | ⬜                                        | ⬜   | ⬜      |
| **T7-12** | (Đợt 4, 3 ngày) BJ-12 Khởi tạo tồn đầu kỳ (nhập tệp, `VFileDropZone`)                                                                                                 | SCR-066…071 · 36                                  | ⬜                                        | ⬜   | ⬜      |
| **T7-13** | (Đợt 5, 3 ngày) BJ-15 Báo cáo tồn và thẻ kho (ngày ghi nhận / ngày nghiệp vụ)                                                                                         | SCR-054, 055, 057, 058, 059 · 30                  | ⬜                                        | ⬜   | ⬜      |
| **T7-14** | (Đợt 5, 1,5 ngày) CAP-01 Chính sách tồn & cận hạn                                                                                                                     | SCR-062…065 · 18                                  | ⬜                                        | ⬜   | ⬜      |
| **T7-15** | (Đợt 5, 2 ngày) Kho Home: lối vào, "Cần chú ý", "Tất cả chức năng kho", deep link; thay hard-code `task.id` và toast còn sót                                          | `warehouse_home_*`                                | ⬜                                        | ⬜   | ⬜      |
| **T7-16** | (Đợt 5, 2 ngày) Rà soát cuối: bảng 421 trạng thái → test, luồng đầu–cuối mỗi BJ, tương phản / vùng chạm / `Semantics`, quét chuỗi giả                                 | Toàn Theme                                        | ⬜                                        | ⬜   | ⬜      |


**Thứ tự đợt:** 0 làm trước (BJ-02/03 có lỗi dữ liệu và sai vai phê duyệt, lại là mẫu cho các BJ sau) → 1 nối tiếp cụm valuation → 2 xuất và hoàn trả (có LOT, Product/UOM) → 3 kiểm soát tồn (BJ-09/10 dùng lại màn của BJ-07) → 4 sửa sai / đối soát / khởi tạo (cần nghiệp vụ gốc để có cái mà sửa) → 5 báo cáo, chính sách, Home (đọc từ mọi nguồn, gom mọi lối vào nên làm cuối). Ước lượng thô cho 1 người, gồm UI + test, chưa gồm backend (plan `T7-B*` chưa lập). Thứ tự BJ trong đợt lấy theo `runOrder` của prototype, chỉ nhóm lại theo phụ thuộc màn dùng chung.

### Hiện trạng (2026-10-13)


| Hạng mục                                                   | Trạng thái                                                                                                                                                                                                                                              |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| BJ-02                                                      | Có SCR-006, 008, 009, 084, 010, 011, 012 (nhập nhanh, `QuickReceiptSessionCubit`). **Thiếu** SCR-007 (nhận theo chứng từ — nút "Nhập theo PO" chỉ hiện SnackBar) và SCR-013 (đối soát UNKNOWN)                                                          |
| BJ-03                                                      | Có SCR-014, 015, 017, 019 + sheet căn cứ trực tiếp; có `sourceChanged`, `commercialConflict`                                                                                                                                                            |
| Trạng thái chưa thấy trong `lib/features/inventory` (grep) | `PERMISSION_DENIED`, `UNKNOWN` / `COMMIT_UNKNOWN`, `FINANCIAL_MASKED`, `LOCKED`, `SELF_APPROVAL_NOT_ALLOWED`, `APPROVAL_ALREADY_DECIDED`, `PENDING_APPROVAL`, `APPROVER_CONFIGURATION_MISSING`                                                          |
| Home                                                       | `WarehouseHomePage` v3.8: Việc của bạn · Bắt đầu việc mới · Tra cứu. Điều hướng việc còn hard-code `task.id == 'receipt_01'`, phần còn lại toast; `/warehouse/stock`, `/warehouse/reports` chưa có route                                                |
| Build                                                      | Đã sửa lỗi `th` (2026-10-13 23:32): `dart analyze lib/features/inventory` sạch, 14 test xanh. `flutter analyze` sập vì đường dẫn có dấu ("Đồ án") — lỗi môi trường, dùng `dart analyze` |




### Công thức làm MỘT BJ (phía UI)

1. **Đọc**: UIF → từng Screen Contract (Information hierarchy, Trạng thái, Hành động) → UC (luồng thay thế / ngoại lệ) → fixture trong `app/core.js` / `app/bjNN.js` của prototype.
2. **Model + luật thuần**: `data/models/` và hàm suy ra (chỉ báo, điều kiện bật nút, tính tiền) là Dart thuần, có unit test; không để luật nằm trong widget.
3. **Repository fixture**: một class, chữ ký như RPC sau này; tham số kịch bản (`normal / empty / stale / permissionDenied / unknown…`) để test và demo ép trạng thái.
4. **Cubit**: Page → Cubit → Repository; lỗi qua `AppException`, không hiện exception thô.
5. **Page**: dựng đúng thứ tự "Information hierarchy"; **mỗi trạng thái trong contract có một nhánh dựng và một test**.
6. **Điều hướng**: đăng ký route, nối **đúng lối vào đã có trên Home** (thay toast / SnackBar giả); Back về đúng nơi gọi, giữ bộ lọc.
7. **Test**: unit (luật), widget từng trạng thái, một luồng đầu–cuối.
8. **So với prototype**: `index.html` → UIF → đối chiếu từng trạng thái ở inspector; ghi lệch vào mục Review của plan.

**Quy tắc UI chung** (rút từ `DS-CONFORMANCE.md` của prototype):

- Dùng thành phần DS có sẵn (`VChip`, `VSearchBar`, `VBanner`, `VBottomSheet`, `VEmptyState`, `VButton`, `VBadge`, `VNumericKeypadSheet`, `VFileDropZone`…); không tạo thành phần riêng cho một tính năng khi DS đã đủ.
- Từ 2 Info / Key-value Row cùng nhóm ngữ nghĩa thì **một bề mặt chung**; list độc lập nền trong suốt. Product → LOT là cha–con (row phẳng cùng bề mặt), không card lồng card.
- Mỗi trạng thái **một hành động chính**; footer hai nút xếp ngang (Phụ | Chính). Không có trạng thái cụt; Back / điều hướng không được đổi finality.
- `VBanner` chỉ cho ngoại lệ, cảnh báo, chặn, hệ quả. Thành công cùng màn dùng toast; không toast trùng màn kết quả / lỗi inline / UNKNOWN. `UNKNOWN` ≠ thất bại, luôn có đường phục hồi.
- Chip lọc một hàng, cuộn ngang, không wrap. Hủy đối tượng đang mở nằm trong ngữ cảnh đối tượng, không đặt ở danh sách.
- Nội dung: "mã vạch" (không "barcode"), UOM luôn đi với số lượng, không ID kỹ thuật. `PERMISSION_DENIED`: dữ liệu được bảo vệ **không có mặt** trong cây widget; `FINANCIAL_MASKED`: không hiện số tiền.
- Tương phản, vùng chạm ≥ 44, nhãn `Semantics` cho nút icon theo 10-4…10-6.

**Dùng lại, đừng làm lại:**


| Dùng chung                                                                      | Ở đâu                                      | Plan           |
| ------------------------------------------------------------------------------- | ------------------------------------------ | -------------- |
| Row điều hướng, Key-value Row (`inventory_list_row`, `inventory_key_value_row`) | `features/inventory/presentation/widgets/` | T7-1           |
| SCR-036 / 037 / 041 (BJ-07 · BJ-09 · BJ-10)                                     | dựng ở BJ-07; BJ-09/10 chỉ đổi chế độ      | T7-6           |
| SCR-056 Chi tiết movement (BJ-09 · BJ-15)                                       | dựng ở BJ-09                               | T7-7           |
| SCR-078…083 (BJ-16 · BJ-17)                                                     | một bộ màn, hai ngữ cảnh vào               | T7-11          |
| Hàng chờ → làm việc → rà soát → kết quả (BJ-03)                                 | mẫu cho BJ-13, BJ-14, BJ-05, BJ-07         | T7-0 chuẩn hoá |




### Quyết định cần chốt


| #   | Câu hỏi                                                                                                                                                                                                                          | Gợi ý                                                                                                         |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| 1   | Home: giữ v3.8 đang làm hay chuyển candidate v4.6.4 (Cần chú ý + 6 nhóm chức năng)?                                                                                                                                              | **Đã chốt 2026-10-16: Home Kho = candidate** (SCR-090). `WarehouseHomePage` Flutter (v3.8) phải đổi theo ở T7-15 |
| 2   | Widget dùng chung ở feature hay lên `vet45_design_system`?                                                                                                                                                                       | Ở feature trước; đẩy lên package khi ≥ 3 BJ dùng và hình dạng đã ổn (plan riêng)                              |
| 3   | Fixture dùng chung một chỗ (`data/fixtures/`) để cùng sản phẩm không lệch mã giữa BJ (hiện BJ-01 `SP-000184`, BJ-03 `SP-00142`)?                                                                                                 | Có, từ T7-1; T7-0 chuyển fixture BJ-02/03 sang                                                                |
| 4   | Vai người dùng (Chủ, Thủ kho, Kế toán…) để thấy `PERMISSION_DENIED`, `FINANCIAL_MASKED`, `SELF_APPROVAL_NOT_ALLOWED`: phiên thật hay tham số kịch bản?                                                                           | **Danh tính: phiên thật** (`SessionStore.userId` + `AccountRepository`), chốt trong T7-0 để kiểm người lập ≠ người duyệt; **quyền / che tài chính: tham số kịch bản** ở giai đoạn UI |


**Đã chốt (2026-10-14):** `features/inventory/` là của Theme 7; 5-A4 chỉ chuyển cổng cặp mặc định sang `DefaultPairRepository` (không dùng tên `InventoryRepository`), phần tồn cơ bản để Theme 7 thay.

**Xong khi (UI):** 73 màn active đều mở được từ Home hoặc deep link, không còn toast / SnackBar giả hành vi; mỗi trạng thái trong Screen Contract có nhánh dựng và ít nhất một test; `dart analyze lib/features/inventory test/features/inventory` = 0 lỗi và `flutter test` không lỗi thêm so với `TEST-BASELINE.md`; mỗi UIF đối chiếu inspector prototype đạt, không còn đường cụt.

---

## Nối kho cho Sales — 8-D (~0,5–1 ngày)

**Trạng thái:** ⬜ Chưa làm. Tách khỏi Theme 5, chạy ngay sau Theme 7 (chốt 2026-11-03). Cần Theme 5 đã chuyển kiến trúc và sổ kho Theme 7 đã chạy.

| Plan     | Nội dung                                                                                                                                                                                                                                                                                                                                                                                         | Gồm việc                | Plan | Làm | Review |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------- | ---- | --- | ------ |
| **8-D** | (b) **Nối kho Theme 7**: xuất kho cùng checkout (`BC-IO-04`), hoàn nguyên khi huỷ đơn (`BC-IO-13`), nhận hàng khách trả (`BC-IO-07`), khả dụng khi chọn sản phẩm (`BC-IO-01`, thay tồn cơ bản trong `search_sellable_products`); backend BJ-04 giữ hàng, BJ-05 lấy và bàn giao, BJ-06 hàng khách trả | Thứ tự 2026-10-14 | ⬜ | ⬜ | ⬜ |

**Xong khi:** 6 kịch bản của Theme 5 (bán thường, bán nợ rồi thu sau, hoàn tiền, huỷ đơn, đổi hàng, trả hàng) cho tồn kho đúng theo sổ kho Theme 7 (xuất, hoàn nguyên, nhận hàng trả); khả dụng khi chọn sản phẩm lấy từ Theme 7.

---

## Theme 6. Công nợ phải thu (~4,5 ngày)

**Trạng thái:** ⬜ Chưa làm. Chưa có tài liệu yêu cầu TH-06 trong `docs/02-yeu-cau`; SCOPE.md mục 2.3 trước đây để TH-06 ngoài phạm vi, nay đưa vào (chốt 2026-10-27).

**Phạm vi (chốt 2026-10-27):** chỉ **phải thu khách hàng**, sinh từ phần còn phải thu của đơn bán (công nợ đơn ở TH-05); **có cấn trừ**. **Không** có phải trả nhà cung cấp.

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
| ---- | -------- | -------- | ---- | --- | ------ |
| **T6-0** | Viết `docs/02-yeu-cau/TH-06-cong-no.md` (độ sâu như TH-07 v1: US / AC / EC / Gherkin / màn): công nợ theo khách, thu tiền, phân bổ vào đơn, cấn trừ, quyền, chữ trên màn. Đầu vào: bản nháp BA `specs/themes/theme-06` v2.1.3 (knowledge, 6 journey, aggregate; bị xoá ở commit `5db3c62d9`, đọc bằng `git show 5db3c62d9^:specs/themes/theme-06/…`) — chỉ lấy phần phải thu + cấn trừ | ~1 ngày | ⬜ | ⬜ | ⬜ |
| **T6-1** | DB: công nợ theo khách lấy từ công nợ đơn TH-05; phiếu thu + phân bổ vào từng đơn (cũ trước); cấn trừ (tiền khách trả dư / hoàn tiền / trả hàng cấn vào nợ đơn khác); RPC + test | ~1,5 ngày | ⬜ | ⬜ | ⬜ |
| **T6-2** | UI (iPhone + web): danh sách khách còn nợ, chi tiết công nợ một khách (đơn còn nợ, lịch sử thu / cấn trừ), ghi nhận thu tiền, cấn trừ; lối vào từ Đối tác và từ chi tiết đơn; `/impeccable audit` | ~2 ngày | ⬜ | ⬜ | ⬜ |

**Xong khi:** bán nợ → thu một phần → thu đủ; khách trả dư / trả hàng → cấn trừ vào đơn còn nợ; số còn phải thu của khách = tổng công nợ các đơn sau mỗi bước; kịch bản đầu–cuối của TH-06 chạy qua trên cả iPhone và web.

---

## Dọn dẹp (1 ngày)

**Trạng thái:** ⬜ Chưa làm

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **9-1** | Dọn code: gộp phần còn dùng của `vet45_shared` vào `core/` rồi xoá; bỏ Melos; gọn `vet45_env` (module / app / package cũ đã xoá ở 3-D, 4-C, 5-C, 6-C, 7-C, 8-C); xoá `packages/vet45_annotations` cùng `vet45_shared` (chuyển từ 5-C / 7-C, 2026-11-04) | 9.1, 9.2, 9.3, 9.6 | ⬜ | ⬜ | ⬜ |
| **9-2** | Dọn DB: bỏ outbox/inbox/onboarding (trừ `sales.outbox_messages`, nhật ký sự kiện của đơn, 8-C Q1), gộp migration baseline | 9.4, 9.5 | ⬜ | ⬜ | ⬜ |

Chi tiết từng việc:

| # | Việc | Kiểm tra |
|---|---|---|
| 9.1 | Kiểm **không còn** `modules/`, `apps/admin`, `apps/messaging_worker` (xoá dần: 3-D IAM / admin / worker; 4-C partner + 3 module rỗng; 5-C catalog, inventory; 6-C pricing; 7-C einvoice; 8-C sales) | `grep -r "vet45_.*_application"` không còn kết quả |
| 9.2 | Gộp phần còn dùng của `vet45_shared` (`ApplicationException`, `TenantAccessRevokedSignal`…) vào `core/` rồi xoá `packages/vet45_shared` (các package khác đã xoá ở 4-C, 7-C, 8-C) | `flutter pub get` OK |
| 9.3 | Bỏ Melos, `pubspec.yaml` gốc chỉ còn workspace nhỏ (`apps/erp`, `packages/vet45_design_system`, `tools/vet45_env`). Lệnh `melos run env:*` đổi thành `.vet45/bin/vet45 …` (dựng bằng `dart compile exe`) hoặc `dart run tools/vet45_env/bin/run.dart …`. Xoá `packages/vet45_misa` (đã viết lại bằng TypeScript trong Edge Function ở P7.4) | `flutter analyze` sạch |
| 9.4 | DB: bỏ outbox/inbox của mọi schema (kể cả `einvoice`; trừ `sales.outbox_messages` (nhật ký sự kiện của đơn, 8-C Q1)) và RPC/view messaging của `platform`; **giữ `einvoice.internal_commands`** (hàng đợi của Edge Function). Bỏ idempotency/onboarding, RPC readiness/activate/onboarding, trạng thái `provisioning`/`pending_activation`; thêm lại FK `memberships.user_id` | `supabase db reset` OK |
| 9.5 | **Gộp migration**: dump schema thành ~5 file baseline (`00_schemas`, `01_tables`, `02_functions`, `03_rls`, `04_triggers`) + `seed.sql`; chuyển migration cũ vào `supabase/_archive/` | `db reset` từ baseline + chạy lại checklist |
| 9.6 | Xoá `tools/vet45_supabase_migrate` và guard CI không còn dùng. **Giữ `tools/vet45_env`** (đổi môi trường local/Dev/Prod, `sync` env, `link`, `doctor`), gọn lại: bỏ target `admin`, `worker` và action `run worker …`, bỏ key `MESSAGING_CLIENT_POLL_ENABLED`, `WORKER_*`; thêm key secrets cho Edge Function (`MISA_*`, `RESEND_*`) nếu cần | `vet45 doctor` sạch; `vet45 switch` + `sync` sinh đúng `apps/erp/.env` |

**Xong khi:** đạt toàn bộ **Definition of Done ở SCOPE mục 6**.

---

## Tích hợp AI (~4,5 ngày)

**Trạng thái:** ⬜ Chưa làm. Giảng viên phụ trách yêu cầu "tích hợp AI vào app". Làm **cuối cùng**, sau Dọn dẹp, để AI dùng dữ liệu thật của các theme đã xong.

**Đã chốt (2026-10-27, người dùng; không hỏi lại giáo viên; plan chi tiết viết khi tới phần này, làm cùng người dùng):** tính năng = trợ lý **"Hỏi VET45"** hỏi đáp số liệu cửa hàng bằng tiếng Việt, chỉ đọc, theo quyền người hỏi, **kèm dự báo nhập hàng** (AI-3: app tính dự báo bằng công thức thống kê trong RPC, Gemini chỉ giải thích — không huấn luyện model riêng, không để Gemini tự tính số). Công cụ là vài RPC tổng hợp **có tham số** (chỉ số × nhóm theo × lọc × thời gian, giá trị chọn trong danh sách cố định; SQL do mình viết), không viết một RPC cho mỗi câu hỏi; câu không có công cụ → trả lời "chưa hỗ trợ", ghi nhật ký. Đọc ảnh phiếu giao hàng: chỉ là ý tưởng nếu dư thời gian, không nằm trong plan. **Làm đủ chức năng** (người dùng chốt 2026-10-27): cả trợ lý lẫn dự báo, đủ các công cụ (thống kê bán hàng, tồn kho, biến động kho, công nợ, dự báo, tìm kiếm) và bộ 20–30 câu hỏi thử — không chia tầng cắt; người dùng đẩy nhanh các theme trước để dành thời gian cho phần này. Model: **Gemini API, hạn mức miễn phí** (khoá tạo ở Google AI Studio, chỉ nằm trong secrets Edge Function); phần gọi model tách một lớp riêng để đổi nhà cung cấp được.

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
| ---- | -------- | -------- | ---- | --- | ------ |
| **AI-0** | Yêu cầu ngắn cho "Hỏi VET45": danh sách câu hỏi phải trả lời được, công cụ và bộ tham số (thống kê bán hàng, tình hình tồn kho, biến động kho, công nợ phải thu, dự báo bán hàng, tìm sản phẩm / khách / đơn), lời dặn hệ thống, chữ trên màn, quyền, giới hạn; bộ 20–30 câu hỏi thử để đánh giá | ~0,5 ngày | ⬜ | ⬜ | ⬜ |
| **AI-1** | Backend: Edge Function `ai-assistant` gọi Gemini API (function calling); **viết mới RPC tổng hợp chỉ đọc có tham số** (app hiện chưa có RPC tổng doanh thu — `list_sales_orders` chỉ trả danh sách theo trang; thẻ doanh thu Home đang gõ cứng), dùng lại RPC đọc của Theme 6 / 7; gọi bằng JWT của người hỏi (RLS + quyền tự áp); nhật ký (người hỏi, công cụ, token, câu không có công cụ), giới hạn số câu mỗi tổ chức mỗi ngày | ~2 ngày | ⬜ | ⬜ | ⬜ |
| **AI-2** | UI (iPhone + web): màn "Hỏi VET45", lối vào từ Home; câu trả lời + bảng dựng từ kết quả công cụ + nút mở màn; đang trả lời, lỗi, hết lượt, không có quyền; `/impeccable audit` | ~1 ngày | ⬜ | ⬜ | ⬜ |
| **AI-3** | Dự báo nhập hàng: RPC tính tốc độ bán trung bình có trọng số 8 tuần → số ngày còn hàng + lượng nên nhập theo mức tồn mục tiêu CAP-01; công cụ `du_bao_ban_hang`; script sinh lịch sử bán mô phỏng vài tháng (ghi rõ trong báo cáo là dữ liệu mô phỏng) | ~1 ngày | ⬜ | ⬜ | ⬜ |

**Xong khi:** tính năng chọn ở AI-0 chạy được từ đầu đến cuối trong app (iPhone + web), chỉ dùng dữ liệu của tổ chức và theo quyền người dùng; có một kịch bản demo cho hội đồng.

---

## Hoàn thiện cho báo cáo đồ án (3 ngày)

**Trạng thái:** ⬜ Chưa làm

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **10-1** | Tài liệu kiến trúc, sơ đồ báo cáo, README | 10.1, 10.2, 10.3 | ⬜ | ⬜ | ⬜ |
| **10-2** | Kịch bản demo bảo vệ | 10.4 | ⬜ | ⬜ | ⬜ |
| **10-3** | Đổi tên `vet45` (tùy chọn), merge và tag `v2.0.0` — làm thẳng | 10.5, 10.6 | — | ⬜ | — |
| **10-4** | Tương phản màu xanh chủ đạo, nhãn + semantics thanh dưới (độc lập, làm lúc nào cũng được) | 10.7 | ✅ plan (đã xoá) | ✅ | ✅ |
| **10-5** | Tương phản tone trạng thái, chữ phụ, viền ô nhập (độc lập) | 10.8 | ✅ plan (đã xoá) | ✅ | ✅ |
| **10-6** | Vùng chạm, nhãn trình đọc màn hình, inset thanh dưới, giảm chuyển động (độc lập) | 10.9 | ✅ plan (đã xoá) | ✅ | ✅ |
| **10-7** | Tinh chỉnh `vet45_design_system` từng mảng bằng impeccable (10 task, độc lập) | — | ✅ [plan](plans/P10/10-7-tinh-chinh-design-system-impeccable.md) | ✅ | ✅ — còn task "Cuối": `polish` + `document` (DESIGN.md), bump version DS (đang `1.7.0`) |

Chi tiết từng việc:

| # | Việc |
|---|---|
| 10.1 | Viết lại `docs/architecture/` thành 2 file: `ARCHITECTURE.md` (sơ đồ 3 tầng, luồng request, quy tắc phụ thuộc) và `DATABASE.md` (ERD theo schema, RLS, các RPC transaction) |
| 10.2 | Sơ đồ cho báo cáo: kiến trúc tổng thể, use case theo vai trò (Owner / Nhân viên), sequence đăng ký cửa hàng, sequence checkout → HĐĐT |
| 10.3 | Cập nhật README: cách chạy local (Supabase + seed + app) |
| 10.4 | Kịch bản demo bảo vệ: đăng ký cửa hàng → thêm sản phẩm → thêm khách → bán hàng → phát hành HĐĐT → đổi trả |
| 10.5 | (Tùy chọn) Đổi tên công cụ `vet45` / thư mục `.vet45` / `tools/vet45_env` cho khớp tên dự án mới |
| 10.6 | Merge `refactor/simple-arch` → `dev` → `main`, tag `v2.0.0` |
| 10.7 | Sửa lỗi khả năng tiếp cận trong `vet45_design_system`: theme sáng đổi `primary` / `success` sang `primary600` (đạt 4.5:1), `VBottomNavigationBar` hiện nhãn + `Semantics`; tab 4 ERP đổi `KH&NCC` → `Đối tác` |
| 10.8 | Theme sáng: warning `yellow700`, danger `red600`, info `blue600`, `textSecondary` `neutral600`, `textMuted` `neutral500`; token mới `borderInput` (`neutral450`) cho viền ô nhập / checkbox / radio; test tương phản tự động |
| 10.9 | Vùng chạm ≥ 44 (nút mật khẩu, nút xoá chip, `VIconBox` có `onTap`); nhãn cho nút quay lại `VAppBar`, mũi tên combobox, bàn phím số; `VSwipeReveal.semanticActions`; thanh dưới chừa đủ inset; skeleton / swipe tôn trọng giảm chuyển động |



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
| Theme 2 | 🔄 | | Đang làm: 5-A1 ✅, 5-A2 ✅, 5-A3 ✅; 5-C ✅ (review R2 2026-11-04; còn việc người dùng: `db reset` local + `catalog_th02.sql`, reset Dev) |
| Theme 4 | 🔄 | | 6-A1, 6-A2, 6-B, 6-C ✅ (review đạt, đã commit; 6-C R1 2026-11-06). **Chỉ còn việc người dùng:** `db reset` local + `supabase/tests/pricing_th04.sql`, reset Dev; kiểm tay 6-A2 7.2, 6-B 8.2 |
| Theme 5 | 🔄 | | 8-A1…8-A4, 8-B1…8-B3, 8-C ✅ (review đạt; 8-C R1 2026-11-08). Còn: 8-D (sau Theme 7), việc người dùng của 8-B2 / 8-B3 |
| Theme 8 | ⬜ | | 2026-11-08: dựng lại khung — 7-B1 → 7-E1 → 7-E2a → 7-E2b → 7-E2c → 7-E3 → 7-A1 → 7-A2 → 7-B2 → 7-C; chưa viết plan nào |
| Theme 7 | 🔄 | — | 2026-10-14: T7-0 ✅ (sửa lỗi dữ liệu + luồng phê duyệt BJ-02/03, chưa commit); T7-0b ✅, T7-0c ✅ (commit `49967966e`); T7-0d có plan 📝; T7-0e chưa lập; T7-1 (BJ-01) có plan 📝. Backend chưa lập plan `T7-B*`. 2026-10-16: chốt **sửa prototype trước (T7-P), rồi mới code Flutter**; T7-0d, T7-1 tạm dừng, rà lại theo prototype mới trước khi giao |
| 8-D | ⬜ | | Tách khỏi Theme 5 (2026-11-03); sau Theme 7 |
| Theme 6 | ⬜ | | Mới thêm 2026-10-27: phải thu + cấn trừ |
| Dọn dẹp | ⬜ | | |
| Tích hợp AI | ⬜ | | Mới thêm 2026-10-27: giảng viên yêu cầu; làm cuối cùng |
| Báo cáo | ⬜ | | |

## Rủi ro theo mục

| Mục | Rủi ro | Cách xử lý |
|---|---|---|
| Theme 1 | Trigger trên `auth.users` lỗi làm hỏng việc xác minh email | Test kỹ ở local; trigger bắt lỗi rõ ràng; validate dữ liệu cửa hàng trên client trước khi `signUp` |
| Theme 1 | Email OTP local khó test | Dùng Inbucket/Mailpit có sẵn trong `supabase start` để đọc mã |
| Theme 2 / Theme 7 | SP-10 (tồn cơ bản) sau 5-C chạy qua `ProductRepository`; `set_basic_stock_quantity_base` không kiểm đơn vị cơ sở (chỉ UI chặn) | Theme 7 thay SP-10 (xem Q3 của 5-C, mục Theme 7) |
| Theme 7 | Prototype đã dọn T7-P0 (CSS `styles/*`, JS `app/core.js` + stub BJ); vẫn có thể còn lớp vá bên trong `core.js` đến khi tách finer | Đối chiếu **hiển thị cuối cùng** trong `index.html`; dữ liệu và luật lấy từ `app/core.js` / `app/bjNN.js` + Screen Contract |
| Theme 7 | Số liệu lệch giữa tài liệu prototype (README 82 màn, manifest 73 màn active / 482 render) | Dùng `manifest.json` v4.6.8 + `workbench-data.js`; đếm lại khi spec đổi |
| Theme 7 | Mỗi BJ tự dựng lại row / sheet khiến UI lệch nhau | Bảng "Dùng lại"; Review kiểm trùng lặp trước khi ✅ |
| Theme 7 | UI trên fixture che lỗi hợp đồng dữ liệu (kiểu số, null, phân trang) | Repository giữ chữ ký như RPC; model theo `PRJ-*` / `ENT-*`; plan backend rà lại model trước khi nối |
| Theme 7 | 421 trạng thái → test phình | Bảng "trạng thái → test" ở T7-0 / T7-16; test theo bảng, không viết tay từng cái |
| Theme 7 | Theme 7 lớn (UI ~12 ngày + backend ~4) làm sau Theme 8 (thứ tự 2026-11-03) → dồn về cuối, sát hạn 2026-12-02 | Theo dõi tiến độ sát; chuyển kiến trúc Theme 4 / 5 / 8 không kéo dài quá ước lượng |
| Theme 5 / 8-D | Sales phải sửa 2 lần: chuyển kiến trúc ở Theme 5, nối sổ kho ở 8-D (đổi so với thứ tự 2026-10-14) | Theme 5 giữ tồn cơ bản đúng như cũ; 8-D chỉ đổi chỗ đọc / ghi tồn, có test giữ hành vi 6 kịch bản |
| Mọi theme | Thêm bố cục web làm mỗi theme dài thêm (~10–20% phần UI; cao hơn từ 2026-10-22 vì không còn thiết bị phụ) | Không cắt bằng cách hạ một thiết bị xuống phụ. Dùng lại khuôn bố cục web chung (K7 của Theme 7) thay vì dựng lại từng theme; ước lượng lại trong plan từng theme |
| Theme 5 | Mất rule nghiệp vụ khi bỏ Aggregate | Bước 5 của công thức: port rule thành hàm thuần và giữ test cũ |
| Theme 5 | Từ lúc sổ kho Theme 7 chạy tới khi Theme 5 nối kho (8-D), Sales cũ vẫn đọc tồn cơ bản không còn cập nhật | Chỉ ảnh hưởng Dev (Prod chưa chạy); 8-D chuyển sang khả dụng của Theme 7 |
| Theme 8 | UI einvoice nằm ở module nên phải chuyển nhiều file | Chuyển nguyên thư mục trước, đổi dependency sau, 2 PR riêng |
| Dọn dẹp | Gộp migration làm lệch schema | So `pg_dump --schema-only` trước và sau; chạy lại toàn bộ checklist |

