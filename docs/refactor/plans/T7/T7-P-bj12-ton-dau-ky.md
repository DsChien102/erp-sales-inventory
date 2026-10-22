# T7-P · BJ-12 Khởi tạo tồn đầu kỳ — thiết kế lại (bước B–E)

> Theme: Theme 7 Inventory · Trạng thái: Brief ✅ (duyệt 2026-10-21) | Plan C–E ✅ | Làm ✅ (2026-10-21, prototype v5.5.0, chưa commit) | Review ✅ 2026-10-22 (đạt; R1–R5 xong, v5.7.2 — [plan CAP-01 mục 10](T7-P-cap01-chinh-sach-ton.md#10-review))

> **Đổi 2026-10-22 (người dùng chốt, áp cho mọi BJ):** mỗi cửa hàng chỉ có một chủ; chủ lập cũng **gửi duyệt rồi tự vào màn duyệt bấm "Duyệt"** một lần nữa — bỏ nhánh ghi nhận thẳng ("Ghi nhận số dư đầu kỳ" + sheet `k2SelfCommitSheet`, "Chủ cửa hàng (tự duyệt)") đã dựng ở brief / v5.5.0. Phần mô tả nhánh đó trong plan này là lịch sử. Code: `bj12.js` bỏ `cf12SelfOpen` / `cf12IsOwner` / `open-self`; `shared-patterns.js` bỏ `k2SelfCommitSheet`; `SC_bj12_owner` và `SC_journey_1` đi qua Chờ duyệt (v5.8.0).
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) mục 8.2 **chặng 1 "Mở kho"**, BJ đầu tiên của Giai đoạn 2. Làm sau [gói H1](T7-P-thiet-ke-lai-luong.md#143-gói-h1--khung-web-cho-harness) (khung web, ✅).
> **Dựng 5 khuôn dùng chung** (T7-P mục 5): K1 trạng thái chung, K2 lập → duyệt → kết quả (cả nhánh Owner tự duyệt), K3 kết quả chưa rõ, K4 kết quả xong, K7 bố cục web. Các BJ sau dùng lại, không dựng lại.
> Thiết bị: **cả iPhone và web đều là thiết bị chính** (sửa 2026-10-22, T7-P mục 2). Plan viết khi còn "web chính, iPhone dùng được"; rà lại 2026-10-22: **đạt cả hai khung**; lỗi nhỏ còn lại sửa ở [plan hotfix T7-HF1](T7-HF1-hai-thiet-bi.md).
> Ước lượng: **~3 ngày, 3 commit** (C1 khuôn + Hub; C2 màn BJ-12; E tài liệu). Người làm: bạn. Review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị, chép nguyên văn. Chữ mới / đổi chữ có đánh dấu **(mới)** và vào T7-P mục 13 ở bước E.

## 0. Brief (bước B, đã duyệt 2026-10-21)

### 0.1 Việc thật

- **Ai:** Owner của cửa hàng mới (hoặc cửa hàng chuyển từ sổ tay / Excel sang). Thường **chính Owner làm một mình**, trên máy tính, một lần duy nhất trong đời cửa hàng. Đôi khi Owner nhờ nhân viên (kế toán) chuẩn bị tệp rồi Owner duyệt.
- **Lúc nào:** trước ngày bắt đầu dùng Kho. Khi chưa khởi tạo, Kho chưa kích hoạt: chưa nhận hàng, bán, kiểm kê được (UC-12-01 BR-01).
- **Cần đạt:** đưa đúng số tồn hiện có (theo lô, hạn dùng, tình trạng, giá trị) vào hệ thống, khớp với sổ của mình, rồi bắt đầu bán.
- **Nỗi lo:** "Tệp phải theo mẫu nào?", "Sai ở dòng nào, sửa thế nào?", "Tổng có khớp sổ không?", "Ghi rồi có làm lại được không?" (không — chỉ một lần, sai sau này sửa bằng điều chỉnh, BR-02).

### 0.2 Luồng hiện tại

Ảnh: `tools/.golden-phase1/UIF-12_SCR-066_READY.png` … `UIF-12_SCR-071_COMPLETED.png`; web: `tools/.golden-web-base/UIF-12_*@web.png`.

SCR-066 Khởi tạo tồn kho ("Bắt đầu") → SCR-067 Dữ liệu (tệp + ngày chốt + 2 số kiểm soát, "Kiểm tra dữ liệu") → SCR-068 Kết quả kiểm tra (lỗi → "Chọn lại tệp"; khớp → "Rà soát") → SCR-069 Rà soát ("Gửi phê duyệt") → SCR-066 chờ duyệt → (người duyệt) SCR-070 Duyệt ("Từ chối" | "Duyệt") → SCR-071 Kết quả ("Xem tồn kho"). Vào từ Home Kho → Thiết lập kho → "Khởi tạo tồn đầu kỳ".

### 0.3 Vấn đề

| # | Màn | Vấn đề |
|---|---|---|
| 1 | Hub | Kho chưa kích hoạt nhưng Home Kho vẫn như bình thường (4 nút nhanh bấm được); lối vào BJ-12 nằm sâu ở "Thiết lập kho". Người mới không biết phải làm việc này trước |
| 2 | 066 | Màn bắt đầu nói "Nguyên tắc: Chỉ có một số dư đầu kỳ chính thức" nhưng không nói **cần chuẩn bị gì** (tệp theo mẫu nào, ngày chốt, tổng theo sổ); không có tệp mẫu |
| 3 | 067 | Ô "Tổng giá trị kiểm soát" là số trần `386240000` không phân cách nghìn, không đơn vị; lỗi chỉ báo bằng banner trên đầu, không ở ô thiếu; trên web vẫn là cột điện thoại, không kéo thả tệp |
| 4 | 068 lỗi | Danh sách lỗi chỉ có "Dòng 18 · Vaccine Newcastle — Chưa xác định sản phẩm": **không nói cách sửa**; thẻ số "Lỗi cần sửa 3" nằm lẻ một hàng; trên web không có bảng |
| 5 | 068 lệch kiểm soát | Mở trực tiếp trạng thái `CONTROL_TOTAL_MISMATCH` thì fixture cho chênh lệch **0** (banner nói không khớp nhưng số khớp); tiêu đề "Kiểm tra dữ liệu" khác các trạng thái khác ("Kết quả kiểm tra dữ liệu") |
| 6 | 068 → 069 → 070 | Ba màn tóm tắt gần như giống nhau (Kho, Ngày chốt, Dòng, Sản phẩm, Tổng số lượng, Tổng giá trị); người lập đi qua hai màn chỉ để bấm "Gửi" |
| 7 | 069 / 070 | **Không xem được dòng nào sẽ vào kho** — chỉ có tổng và "Bán được 74 dòng / Không bán được 8 dòng"; UC-12-02 BF-01 yêu cầu người duyệt xem "sample/chi tiết" |
| 8 | 070 | Thẻ "Người chuẩn bị" đứng trên số liệu cần quyết; không đối chiếu số kiểm soát với tệp; không nhắc 8 dòng không bán được; banner "Kiểm tra trước khi duyệt" chung chung |
| 9 | Cả luồng | Owner làm một mình thì **kẹt**: phải gửi phê duyệt cho người khác (quy tắc mới: `is_owner` tự duyệt được — T7-P mục 2) |
| 10 | 071 | Chỉ có "Xem tồn kho"; không dẫn sang việc tiếp theo của chặng (đặt ngưỡng tồn, CAP-01) |
| 11 | 066 / 071 chưa rõ kết quả | Màn chưa rõ kết quả không có mã tham chiếu, thời điểm, và không nói điều gì an toàn ("tồn kho chưa mở", "đừng nạp lại tệp") |
| 12 | 066 bị từ chối | Không hiện **lý do** người duyệt đã nhập |

### 0.4 Đề xuất

**Luồng mới** (người lập là Owner — đường chính của demo, T7-P mục 10 bước 1):

```text
Home Kho (chưa kích hoạt) ─"Khởi tạo tồn kho"→ 066 Bắt đầu ─→ 067 Tệp + tổng theo sổ ─"Kiểm tra dữ liệu"→
068 Kết quả kiểm tra ── lỗi / lệch tổng → sửa → 067
                    └─ đạt: tóm tắt + bảng dòng ─"Ghi nhận số dư đầu kỳ"→ sheet xác nhận → 071 Kết quả ─→ "Xem tồn kho" (BJ-01) / "Đặt ngưỡng tồn" (CAP-01)
```

Người lập là nhân viên: ở 068 nút chính là "Gửi phê duyệt" → 066 chờ duyệt → Owner mở từ Home Kho "Chờ duyệt" → 070 → 071.

**Gộp SCR-069 vào SCR-068** (vấn đề 6): khi kiểm tra đạt, 068 chính là màn rà soát. SCR-069 bỏ, đăng ký `screenAliases` sang 068; ở bước E chuyển SCR-069 vào `RETIRED.md`. Người lập bớt một màn.

*Home Kho (Hub, chặng 1 nối lối vào)*

1. Kho **chưa kích hoạt**: ngay dưới ô tìm, một khối "Kho chưa kích hoạt" **(mới)** + mô tả "Nhập số tồn hiện có một lần để bắt đầu nhận, bán và kiểm kê hàng." **(mới)** + nút chính "Khởi tạo tồn kho"; 4 nút nhanh tắt. Đã kích hoạt: như hiện tại.
2. "Cần chú ý": dòng "Nhận hàng chờ phê duyệt" thành **"Chờ duyệt"** **(mới)** gom mọi BJ (K2), dòng phụ đếm theo nguồn: "3 nhận hàng · 1 số dư đầu kỳ" **(mới)**; danh sách chờ duyệt có thêm mục số dư đầu kỳ (mở 070 với vai người duyệt).

*SCR-066 Khởi tạo tồn kho* (màn trạng thái của BJ-12)

3. `READY` (chưa có gì): một câu "Nhập số tồn hiện có của cửa hàng một lần để bắt đầu dùng Kho." **(mới)**; khối "Cần chuẩn bị" **(mới)** 3 dòng: "Tệp số dư theo mẫu" + nút phụ **"Tải tệp mẫu"** **(mới)**; "Ngày chốt số dư"; "Tổng số lượng và tổng giá trị theo sổ để đối chiếu" **(mới)**. Ghi chú giữ: "Sau khi hoàn tất, mọi sửa sai được thực hiện bằng nghiệp vụ điều chỉnh có kiểm soát." Nút chính "Bắt đầu".
4. `REJECTED`: hiện **lý do từ chối** và người từ chối; nút "Tiếp tục chuẩn bị".
5. `PENDING_APPROVAL`: khuôn K2 phía người lập (ai sẽ duyệt, gửi lúc nào, dữ liệu đã khoá, tồn kho chưa đổi); lối ra "Về Kho".
6. `ACTIVE_RECONCILED`: khuôn K4 rút gọn; "Xem tồn kho" + "Đặt ngưỡng tồn" **(mới)**.

*SCR-067 Dữ liệu tồn kho đầu kỳ*

7. Web: hai cột — trái là biểu mẫu (vùng tệp "Kéo tệp vào đây hoặc Chọn tệp" **(mới, chỉ web)** + "Tải tệp mẫu"; "Ngày chốt số dư"; "Tổng số lượng kiểm soát"; "Tổng giá trị kiểm soát"); phải là "Tệp cần có các cột" **(mới)**: Mã sản phẩm · ĐVT · Tình trạng · Mã lô · Hạn dùng · Số lượng · Đơn giá, mỗi cột một dòng giải thích ngắn. iPhone: một cột, chỉ "Chọn tệp", phần cột đặt sau nút "Xem các cột cần có" **(mới)** mở sheet.
8. Ô tiền có phân cách nghìn và hậu tố "đ" (giá trị gửi đi vẫn là số). Lỗi hiện **tại ô** ("Nhập tổng giá trị theo sổ" **(mới)**…), banner chỉ tóm tắt.

*SCR-068 Kết quả kiểm tra dữ liệu* (gồm phần rà soát của 069)

9. `VALIDATION_FAILED`: dải số một hàng "82 dòng đọc được · 79 hợp lệ · 3 cần sửa" (thay 3 thẻ lẻ); **bảng lỗi** (web) / danh sách (iPhone): Dòng · Sản phẩm · Lỗi · **Cách sửa (mới)** — vd. "Chưa có sản phẩm này trong danh mục — Thêm sản phẩm ở Sản phẩm rồi kiểm tra lại"; "Trùng sản phẩm + kho + tình trạng + lô với dòng 12 — Gộp hai dòng trong tệp"; "Thiếu hạn dùng — Điền hạn dùng cho lô". Nút "Chọn lại tệp".
10. `CONTROL_TOTAL_MISMATCH`: tiêu đề thống nhất "Kết quả kiểm tra dữ liệu"; bảng đối chiếu 3 cột Theo tệp · Theo sổ · Chênh lệch cho số lượng và giá trị, chênh lệch tô cảnh báo; fixture có chênh lệch thật (vd. 4.830 vs 4.820 → +10). Nút chính "Sửa số kiểm soát", phụ "Chọn lại tệp".
11. `READY` (đạt): banner thành công một dòng; khối "Số dư sẽ ghi nhận" **(mới)**: Kho · Ngày chốt · 36 sản phẩm · 82 dòng · Tổng số lượng 4.820 · Tổng giá trị 386.240.000 đ · "Khớp số kiểm soát" ✓; **bảng dòng** có lọc "Tất cả 82 · Bán được 74 · Không bán được 8" (fixture 10 dòng mẫu, chân bảng "Hiện 10 / 82 dòng" **(mới)**). Nút chính theo vai: nhân viên "Gửi phê duyệt"; `is_owner` **"Ghi nhận số dư đầu kỳ" (mới)** → sheet xác nhận (K2 tự duyệt): tóm tắt 3 số + "Chỉ ghi nhận một lần. Sai sau này phải sửa bằng điều chỉnh." **(mới)** + "Huỷ" | "Ghi nhận".

*SCR-070 Duyệt số dư đầu kỳ* (người duyệt, khuôn K2 + K7)

12. Web hai cột: trái **"Cần quyết"**: câu hỏi "Duyệt số dư đầu kỳ của Kho trung tâm, chốt 31/08/2026?" **(mới)**; một dòng "Nguyễn An gửi 07/09/2026 · 10:32" (thay thẻ "Người chuẩn bị"); đối chiếu số kiểm soát (khớp ✓); **điều cần chú ý** lên đầu: "8 dòng không bán được (cách ly / hỏng)" **(mới)**, "Sau khi duyệt, Kho bắt đầu hoạt động" **(mới)**. Phải: bảng dòng (cùng thành phần với 068). iPhone: xếp dọc theo đúng thứ tự đó, bảng thành danh sách.
13. Chân: "Từ chối" | "Duyệt" (giữ); "Từ chối" mở sheet bắt buộc lý do (giữ).
14. `SELF_APPROVAL_NOT_ALLOWED` chỉ còn khi người lập **không** phải `is_owner` tự mở phiếu của mình (quy tắc mới); chữ giữ.

*SCR-071 Kết quả khởi tạo tồn kho* (khuôn K4)

15. `COMPLETED`: tóm tắt ai / lúc nào / bao nhiêu (Ngày chốt · Sản phẩm · Tổng số lượng · Tổng giá trị · Đối soát "Đã khớp" · "Người duyệt" — nhánh Owner ghi "Chủ cửa hàng (tự duyệt)" **(mới)**); nút chính "Xem tồn kho", phụ "Đặt ngưỡng tồn" → CAP-01.
16. `REJECTED_EXECUTION`: K4 cảnh báo + lý do + "Tiếp tục chuẩn bị".
17. `UNKNOWN` / `COMMIT_UNKNOWN` (cả ở 066): khuôn K3 — giữ "Kết quả chưa xác định" và "Chuyển sang xác minh"; thêm Mã tham chiếu "OB-2026-0001", "Thời điểm gửi", dòng "Tồn kho" = "Chưa mở cho đến khi xác minh xong" **(mới)**, câu "Không nạp lại tệp hay gửi lại." **(mới)**; lối ra phụ "Về Kho".

### 0.5 Trạng thái (sau thiết kế lại)

| Màn | Trạng thái | Hiện gì | Làm được gì | Lối ra |
|---|---|---|---|---|
| Hub | chưa kích hoạt | khối "Kho chưa kích hoạt", nút nhanh tắt | "Khởi tạo tồn kho" | — |
| 066 | READY | Cần chuẩn bị (3 dòng) | "Bắt đầu", "Tải tệp mẫu" | Về Kho |
| 066 | PREPARING | tóm tắt bản đang chuẩn bị | "Tiếp tục chuẩn bị" | Về Kho |
| 066 | PENDING_APPROVAL | K2 người lập: chờ ai, gửi lúc, đã khoá | — | Về Kho |
| 066 | REJECTED | lý do + người từ chối | "Tiếp tục chuẩn bị" | Về Kho |
| 066 | ACTIVE_RECONCILED | K4 rút gọn | "Xem tồn kho", "Đặt ngưỡng tồn" | Về Kho |
| 066 / 071 | UNKNOWN, COMMIT_UNKNOWN | K3 | "Chuyển sang xác minh" | Về Kho |
| 066, 067, 068, 070, 071 | PERMISSION_DENIED | K1: chuyện gì, làm gì tiếp | — | Về Kho |
| 066, 068 | LOADING | K1: khung xương đúng bố cục | — | — |
| 067 | READY / VALIDATION_ERROR | biểu mẫu; lỗi tại ô | "Kiểm tra dữ liệu" (tắt khi thiếu) | Quay lại |
| 067 | LOCKED | K1 khoá: chỉ đọc, vì sao | — | Quay lại |
| 067, 068 | CONFLICT | K1 dữ liệu cũ: banner + "Tải lại" | "Tải lại" | Quay lại |
| 068 | VALIDATION_FAILED | dải số + bảng lỗi có cách sửa | "Chọn lại tệp" | Quay lại |
| 068 | CONTROL_TOTAL_MISMATCH | đối chiếu 3 cột | "Sửa số kiểm soát", "Chọn lại tệp" | Quay lại |
| 068 | READY | số dư sẽ ghi + bảng dòng | nhân viên "Gửi phê duyệt" / Owner "Ghi nhận số dư đầu kỳ" | Quay lại |
| 070 | READY | Cần quyết + bảng dòng | "Duyệt", "Từ chối" (lý do) | Về Kho |
| 070 | SELF_APPROVAL_NOT_ALLOWED, APPROVAL_ALREADY_DECIDED, VALIDATION_ERROR | K1 / K2 | — | "Về danh sách" (giữ) |
| 071 | PROCESSING | đang ghi nhận | — | — |
| 071 | COMPLETED / ACTIVE_RECONCILED | K4 | "Xem tồn kho", "Đặt ngưỡng tồn" | Về Kho |
| 071 | REJECTED_EXECUTION | K4 cảnh báo | "Tiếp tục chuẩn bị" | Về Kho |

Trạng thái của SCR-069 cũ: `READY` → 068 READY; `PENDING_APPROVAL` → 066 PENDING_APPROVAL; `CONFLICT`, `VALIDATION_ERROR` → 068 CONFLICT; `PERMISSION_DENIED` → 068 PERMISSION_DENIED.

### 0.6 Khuôn dựng ở BJ này (mô tả vào T7-P mục 5 khi xong)

| Khuôn | Ở BJ-12 | Hàm dùng chung (mới, `app/shared-patterns.js`) |
|---|---|---|
| K1 | LOADING, PERMISSION_DENIED, CONFLICT, LOCKED, bảng lọc rỗng | `k1Loading`, `k1Denied`, `k1Stale`, `k1Locked`, `k1Empty`, `k1ExitAttr` |
| K2 | gửi phê duyệt, chờ duyệt (người lập), màn duyệt, từ chối có lý do, **Owner tự duyệt**, "Chờ duyệt" trên Home | `k2Pending`, `k2Decision`, `k2RejectSheet`, `k2SelfCommitSheet`, nguồn `window.__T7_PENDING_SOURCES__` |
| K3 | 066 / 071 chưa rõ kết quả | `k3Unknown` |
| K4 | 071, 066 đã kích hoạt | `k4Result` |
| K7 | 067 hai cột, bảng lỗi / bảng dòng, 070 hai cột, thanh nút bên phải | `k7Split`, `k7Table`, `k7FilterChips`; lớp `k7-wide` |

### 0.7 Không đổi

Quy tắc UC-12-01…03: một số dư chính thức (BR-02); chặn số âm / số 0 có giá trị (BR-03); không tự gộp dòng trùng (BR-04); lô / hạn dùng theo chính sách sản phẩm (BR-05); dòng không bán được không tăng khả dụng (BR-06); "Duyệt" chỉ là quyết định, ghi nhận do hệ thống (SCR-070); "Từ chối" bắt buộc lý do; không ghi gì khi lỗi / lệch tổng; chưa rõ kết quả không coi là thất bại và không làm lại. Chữ giữ: tiêu đề 6 màn, "Bắt đầu", "Tiếp tục chuẩn bị", "Kiểm tra dữ liệu", "Chọn lại tệp", "Sửa số kiểm soát", "Gửi phê duyệt", "Duyệt", "Từ chối", "Xem tồn kho", "Kết quả chưa xác định", "Chuyển sang xác minh", "Về danh sách".

### 0.8 Chữ mới / thành phần mới (→ T7-P mục 13 ở bước E)

Chữ: mọi chỗ **(mới)** ở 0.4. Thành phần: bảng dữ liệu web (`k7Table`; Flutter có sẵn `VTable`), vùng kéo thả tệp trên web (mở rộng `VFileDropZone` đang có trong prototype), dải số một hàng (biến thể ngang của `ac310SummaryMetrics`).

### 0.9 Kiểm (bước D)

- Golden **mobile** được khác: `UIF-12_*`, `SC_bj12_*`, `SC_entry_UIF-12_*`, `HUB_home`, kịch bản đi qua "Cần chú ý" (`SC_attention_*`), ca `UIF-12_SCR-069_*` **mất** (màn gộp). Mọi ca khác khớp hoàn toàn `tools/.golden-phase1`.
- Golden **web** được khác: `UIF-12_*@web`, `HUB_home@web`; ca khác khớp `tools/.golden-web-base`.
- Kịch bản mới: `SC_bj12_owner` (Owner tự làm từ Home chưa kích hoạt → ghi nhận → kết quả → "Đặt ngưỡng tồn"), `SC_bj12_template` ("Tải tệp mẫu"), `SC_hub_not_activated`, `SC_bj12_pending_list` (Home "Chờ duyệt" → mục số dư đầu kỳ → 070).

### 0.10 Ước lượng C–E

~3 ngày: C1 khuôn + Hub ~1; C2 màn BJ-12 ~1,25; D ~0,25; E tài liệu ~0,5.

### 0.11 Đã chốt khi duyệt brief (2026-10-21)

| # | Điểm | Chốt |
|---|---|---|
| a | Gộp SCR-069 vào SCR-068 | Gộp |
| b | "Tải tệp mẫu" | Thêm — prototype chỉ hiện toast "Đã tải tệp mẫu" |
| c | Owner tự duyệt | Ghi nhận ngay sau sheet xác nhận, không có trạng thái chờ |
| d | Home Kho khi kho chưa kích hoạt | Chặn 4 nút nhanh, hiện khối "Kho chưa kích hoạt" + "Khởi tạo tồn kho" |

---

## 1. Mục tiêu

1. Owner tự khởi tạo kho trên web trong một mạch: biết chuẩn bị gì, thấy lỗi kèm cách sửa, thấy dòng nào sẽ vào kho, ghi nhận một lần, đi tiếp sang xem tồn / đặt ngưỡng.
2. Nhân viên lập → Owner duyệt chạy đủ, Owner thấy việc chờ ở Home "Chờ duyệt".
3. Dựng K1, K2, K3, K4, K7 thành hàm dùng chung trong `app/shared-patterns.js` cho các BJ sau.
4. Cả luồng dùng được trên iPhone (bảng → danh sách, hai cột → xếp dọc).

## 2. Chuẩn bị

1. Máy chủ: `python3 -m http.server 8765 --bind 127.0.0.1 &` trong `html/`.
2. Mốc: `node tools/golden.mjs capture tools/.golden-bj12-base` và `DEVICE=web node tools/golden.mjs capture tools/.golden-bj12-web-base`; so lần lượt với `tools/.golden-phase1` và `tools/.golden-web-base` → "Khớp hoàn toàn". **Không chụp lại hai mốc này giữa gói** (T7-P 4.5).
3. Đọc brief mục 0 (đã duyệt 2026-10-21) và bảng chữ mục 9.

## 3. Bước C1 — khuôn dùng chung và Hub (commit 1)

### 3.1 `app/core.js`

1. `appShell({ …, extraClass = "" })`: thêm tham số, nối vào lớp của `.v-page-scaffold` (`class="v-page-scaffold ${figmaTemplate ? 'figma-calibrated-shell' : ''} ${extraClass}"`). Mặc định rỗng → không đổi hình mọi màn khác.
2. `entryTargets["UIF-12"]`: thêm `owner: { screen: "SCR-066", state: "READY" }` (giữ `approver`). Vai `owner` = người dùng `is_owner` (tự lập, tự duyệt).

### 3.2 `app/shared-patterns.js` (tạo)

Nạp trong `index.html` **sau** `app/shared-valuation.js`, **trước** `app/bj01.js`. Đầu file ghi: "Khuôn dùng chung K1–K4, K7 (T7-P mục 5), dựng ở BJ-12." Chỉ dựng chuỗi HTML từ helper có sẵn (`appShell`, `vBanner`, `ioResult`, `primaryFooter`, `ac310ApprovalFooter`, `ac310InfoSurface`, `ds24Chip`, `icon`, `esc`, `escapeAttribute`); token `--vet45-v2-*`; không đọc biến của BJ nào.

```js
// K1 — trạng thái chung
function k1ExitAttr(firstScreen)           // ThemeApp.inTheme() ? 'data-theme-sidebar-route="inventory"' : `data-v360-action="fallback-exit" data-v360-target="${firstScreen}"`
function k1Loading({ blocks = ["heading", "card", "card"] } = {})   // khung xương theo bố cục màn; kiểu khối: "heading" | "card" | "row" | "search" (BJ-01 dùng "row", "search"); dùng lớp .skeleton sẵn có, thêm .skeleton--row (cao 64, bo 12) và .skeleton--search (cao 44)
function k1Denied({ what, next, exitAttr })  // VEmptyState: tiêu đề "Bạn chưa có quyền …"(what), câu next, nút phụ "Về Kho"
function k1Stale({ title, description, actionLabel = "Tải lại", actionAttr })  // vBanner("warning") + nút phụ ngay dưới
function k1Locked({ title, description })   // vBanner("info"), không nút
function k1Empty({ title, description, actionLabel, actionAttr })  // dùng emptyBody làm nền, cho bảng lọc rỗng

// K2 — lập → duyệt → kết quả
function k2Pending({ approver, sentAt, facts })          // người lập: banner info "Đang chờ duyệt" + dòng "Chờ {approver} duyệt · gửi {sentAt}" + facts + câu "Dữ liệu đã khoá. Tồn kho chưa thay đổi."
function k2Decision({ question, maker, sentAt, attention = [], facts = [], detail = "" })
  // thứ tự cố định: câu hỏi (h2) → dòng người gửi → "Cần chú ý" (attention: [[nhãn, giá trị]] tô cảnh báo) → facts → detail (bảng)
function k2RejectSheet({ open, title, reason, reasonAttr, confirmAttr, closeAttr })  // tổng quát từ cf12RejectSheet hiện có (giữ chữ, data-ds-component="VBottomSheet")
function k2SelfCommitSheet({ open, title, facts, warning, confirmLabel, confirmAttr, closeAttr })  // sheet xác nhận Owner tự duyệt: facts + vBanner("warning", warning) + "Huỷ" | confirmLabel
```

```js
// K3 — kết quả chưa rõ
function k3Unknown({ operation, scope, ref, sentAt, safe, sourceFlow, exitAttr })
  // appShell title "Xác minh kết quả", không nút quay lại; thân = ioResult("Kết quả chưa xác định", mô tả cũ + safe, [["Nghiệp vụ",operation],["Phạm vi",scope],["Mã tham chiếu",ref],["Thời điểm gửi",sentAt],["Trạng thái","Chưa kết luận"]], "warning")
  // chân: phụ "Về Kho" (exitAttr) | chính "Chuyển sang xác minh" với data-v350-action="handoff-unknown" + data-source-flow / data-operation / data-scope (giữ đúng thuộc tính bj17.js đang đọc)

// K4 — kết quả xong
function k4Result({ kind = "success", title, description, facts, next })
  // thân = ioResult(title, description, facts, kind); next = [{ label, attr, primary }] → chân hai nút (phụ | chính) hoặc một nút

// K7 — bố cục web
function k7Split({ main, aside })                 // <div class="k7-split"><div class="k7-split__main">…</div><aside class="k7-split__aside">…</aside></div>
function k7Table({ columns, rows, mobileRow, caption = "", footer = "" })
  // columns: [{ key, label, align: "start"|"end", mono }]; rows: [{...}]
  // trả CẢ HAI: <table class="k7-table"> (hiện ở khung web) và <div class="k7-table-list"> dựng bằng mobileRow(row) (hiện ở khung mobile) — đổi khung bằng nút không render lại nên CSS ẩn / hiện
function k7FilterChips({ items, selected, attrName })  // ds24Chip có số: "Tất cả 82"; chip số 0 mờ
```

### 3.3 CSS (`styles/components.css`, khối mới `/* Khuôn K1–K4, K7 (BJ-12) */` cuối file)

- `.device-preview.is-web > .app-screen > .v-page-scaffold.k7-wide` (và mọi luật theo UIF đặt 402px): `width:100% !important; max-width:1120px !important;` — thoát cột 402px của H1 cho màn đã có bản web. Kiểm bằng `UIF-12_*@web`.
- `.k7-split`: mặc định một cột (mobile); `.device-preview.is-web .k7-split { display:grid; grid-template-columns: minmax(0, 5fr) minmax(0, 7fr); gap: var(--vet45-v2-space-6) }`.
- `.k7-table`: chỉ hiện `.is-web`; thead sticky, chữ 13–14px, số `font-family: var(--vet45-v2-font-mono)` căn phải, dòng cao 40px, viền `--vet45-v2-border-default`; `.k7-table-list` chỉ hiện `.is-mobile`.
- Chân màn trên web: `.device-preview.is-web .k7-wide .app-actions` căn nút sang phải, nút rộng theo chữ (`width:auto; min-width:160px`).
- Mật độ web dùng chiều cao control nhỏ hơn (compact) chỉ trong `.k7-wide`.

### 3.4 `app/hub.js`

1. **Kho chưa kích hoạt:** biến `inventoryActivated` (mặc định `true`; `?activation=pending` → `false`; BJ-12 gọi `ThemeApp.setActivated(true)` khi kết quả `COMPLETED`). Khi `false`, Home Kho chèn khối (dưới ô tìm) `vBanner("info", "Kho chưa kích hoạt", "Nhập số tồn hiện có một lần để bắt đầu nhận, bán và kiểm kê hàng.")` + nút chính "Khởi tạo tồn kho" (`data-theme-entry-flow="UIF-12"`); 4 nút nhanh thêm `disabled`.
2. **"Chờ duyệt" (K2):** nguồn việc chờ là mảng toàn cục `window.__T7_PENDING_SOURCES__` (BJ nạp trước `hub.js` nên đẩy vào mảng, không gọi `ThemeApp`); mỗi phần tử `{ id, label, rows() }`; `rows()` trả `[{ title, subtitle, attrs }]` (rỗng = không có việc chờ). Dòng "Cần chú ý" đầu tiên đổi tiêu đề thành "Chờ duyệt", dòng phụ ghép `"{số dòng} {label}"` của các nguồn có dòng, nối bằng " · ", số = tổng. Nguồn nhận hàng hiện có (`PENDING_RECEIPTS`, 3 dòng, giữ nguyên `attrs` đang dùng ở `hub.js` ~dòng 191) đăng ký trong `hub.js`. Màn danh sách `go('inventory','pending-approvals')`: tiêu đề "Nhận hàng chờ phê duyệt" → "Chờ duyệt"; dựng dòng của mọi nguồn bằng `ds24ListRow` như dòng nhận hàng hiện có.
   Thuộc tính mới `data-theme-entry-actor="approver"` trên dòng: trong handler click của Hub (`hub.js` ~dòng 367), nếu có thì gọi `window.__VET45_QA__.setActor(value)` trước khi vào luồng; dòng có `data-t380-target-screen` mở thẳng màn đó như nhận hàng đang làm.
3. Export thêm `setActivated`. Nguồn nhận hàng đẩy vào `window.__T7_PENDING_SOURCES__` ngay trong `hub.js`.

### 3.5 Kiểm C1

`node --check`; golden mobile + web: chỉ `HUB_home*`, kịch bản qua "Cần chú ý" khác (đúng chữ "Chờ duyệt"); mọi ca khác khớp mốc mục 2. Commit 1.

## 4. Bước C2 — màn BJ-12 (commit 2)

Sửa `app/bj12.js`. Mọi màn BJ-12 gọi `appShell({ …, extraClass: "k7-wide" })`.

### 4.1 Fixture và trạng thái

1. `cf12Lines`: 10 dòng mẫu, mỗi dòng `{ row, sku, name, uom, state, lot, expiry, qty, unitCost }`. **Phải chứa đúng 5 sản phẩm của BJ-01** (`bj01Products` trong `bj01.js`: Nobivac DHPPi SP-000184 hộp lô DH2507 / DH2509; Amox 500 SP-000066 hộp; Enrofloxacin 10% SP-000091 chai; Tylosin 20% SP-000122 lọ lô TY2408 / TY2511; Oxytetracycline LA SP-000147 chai) với cùng tên / mã / ĐVT / lô để hành trình chặng 1 (`SC_journey_1`) liền mạch; thêm dòng khác cho đủ loại: một dòng "Cách ly", một dòng "Hư hỏng"; `cf12Summary` giữ (82 / 36 / 4.820 / 386.240.000 / 74 / 8).
2. `cf12Issues`: 3 lỗi hiện có + cột `fix` (chữ "Cách sửa" ở brief 0.4 mục 9).
3. `cf12Filter` (`all` | `sellable` | `nonSellable`), `cf12SelfOpen` (sheet Owner), `cf12RejectBy`, `cf12RejectReason` giữ lại sau khi từ chối để 066 hiện.
4. Trạng thái `CONTROL_TOTAL_MISMATCH` mở trực tiếp: đặt `cf12ControlQty = "4830"` (chênh +10) trong `onScreenEnter["UIF-12:SCR-068"]` khi state là MISMATCH và số đang khớp — sửa vấn đề 5 mà không đổi luồng bấm.
5. `screenAliases`: `SCR-069` → `SCR-068` (state map ở brief 0.5); xoá `render069BJ12` và mục `"SCR-069"` khỏi `renderers`. Kiểm `data/workbench-data.js`: bỏ SCR-069 khỏi danh sách màn của UIF-12 nếu harness đọc từ đó (giữ ID ở `core.js` alias để link cũ vẫn mở).

### 4.2 Từng màn

| Màn | Việc |
|---|---|
| 066 | Viết lại theo brief 0.4 mục 3–6, 17: `READY` khối "Cần chuẩn bị" (`ac310InfoSurface` 3 dòng, dòng tệp kèm nút phụ "Tải tệp mẫu" `data-cf12-action="template"` → `showToast("Đã tải tệp mẫu")`); `PENDING_APPROVAL` → `k2Pending({ approver:"Chủ cửa hàng", sentAt, facts })`; `REJECTED` → banner + `ac310InfoSurface` có "Lý do" = `cf12RejectReason`, "Người từ chối"; `ACTIVE_RECONCILED` → `k4Result` rút gọn; `UNKNOWN` → `k3Unknown`; `LOADING` / `PERMISSION_DENIED` → K1 |
| 067 | `k7Split`: main = vùng tệp (`bj12FileDrop` thêm dòng "Kéo tệp vào đây hoặc Chọn tệp" chỉ hiện `.is-web`) + "Tải tệp mẫu" + 3 ô; aside = "Tệp cần có các cột" (7 dòng). Mobile: aside ẩn, thay bằng nút "Xem các cột cần có" mở sheet cùng nội dung. Ô giá trị: `cfField(…, "money")` (kiểu tiền đã có: phân cách nghìn qua `cfMoneyInput`); listener `input` hiện có vẫn giữ số trần trong `cf12ControlValue`. `VALIDATION_ERROR`: lỗi tại ô — thêm tham số thứ 6 `error = ""` vào `cfField` (`shared-control.js:95`, mặc định rỗng → BJ khác không đổi) dựng ô ở trạng thái lỗi + dòng lỗi dưới ô; banner một câu. `LOCKED` / `CONFLICT` → `k1Locked` / `k1Stale` |
| 068 | `VALIDATION_FAILED`: dải số ngang + `k7Table` cột Dòng · Sản phẩm · Lỗi · Cách sửa (mobile: `bj12IssueRow` thêm dòng cách sửa). `CONTROL_TOTAL_MISMATCH`: tiêu đề "Kết quả kiểm tra dữ liệu", `k7Table` 4 cột (Chỉ tiêu · Theo tệp · Theo sổ · Chênh lệch), chân hai nút "Chọn lại tệp" \| "Sửa số kiểm soát". `READY`: banner một dòng + `k7Split` (main "Số dư sẽ ghi nhận" + "Khớp số kiểm soát"; aside `k7FilterChips` + `k7Table` dòng, footer "Hiện 10 / 82 dòng"); chân: `currentActor()==="owner"` → "Ghi nhận số dư đầu kỳ" (`data-cf12-action="open-self"`), khác → "Gửi phê duyệt" (giữ `data-v350-action="cf12-send-approval"`); `k2SelfCommitSheet` khi `cf12SelfOpen` |
| 070 | `READY`: `k7Split` main = `k2Decision({ question, maker:"Nguyễn An", sentAt, attention:[["Không bán được","8 dòng (cách ly / hư hỏng)"],["Sau khi duyệt","Kho bắt đầu hoạt động"]], facts })`, aside = bảng dòng như 068; `k2RejectSheet` thay `cf12RejectSheet`. Trạng thái khác giữ chữ, dùng K1 |
| 071 | `COMPLETED` / `ACTIVE_RECONCILED` → `k4Result` (facts brief 0.4 mục 15; `Người duyệt` theo nhánh), next = phụ "Đặt ngưỡng tồn" (`data-cf12-action="go-policy"` → CAP-01 SCR-062) \| chính "Xem tồn kho" (giữ `see-inventory`); `REJECTED_EXECUTION` → `k4Result({kind:"warning"})` + "Tiếp tục chuẩn bị"; `UNKNOWN` / `COMMIT_UNKNOWN` → `k3Unknown`; `PROCESSING` giữ |

### 4.3 Xử lý sự kiện (listener `click` hiện có)

1. `open-self` → `cf12SelfOpen = true; renderAppScreen()`; `close-self` → đóng; `confirm-self` (`data-cf12-action`): kiểm `bj12ControlMatches()` (lệch → 068 MISMATCH như `cf12-send-approval`), rồi đi đúng đường `cf12-approve` hiện có từ bước "PROCESSING" (không qua 066 chờ duyệt), ghi `cf12ApprovedBy = "owner"`.
2. `cf12-approve` / `cf12-confirm-reject`: giữ kiểm `currentActor()` nhưng chấp nhận cả `"approver"` và `"owner"`; nếu người lập là `owner` thì không có màn 070 (đường tự duyệt).
3. Cuối `bj12.js`, đăng ký **một lần** lúc nạp: `(window.__T7_PENDING_SOURCES__ ||= []).push({ id:"UIF-12", label:"số dư đầu kỳ", rows:() => stateByScreen["SCR-066"]==="PENDING_APPROVAL" ? [{ title:"Số dư đầu kỳ · Kho trung tâm", subtitle:`Chốt ${cfDateVN(cf12Cutoff)} · Nguyễn An gửi 10:32`, attrs:'data-theme-entry-flow="UIF-12" data-t380-target-screen="SCR-070" data-theme-entry-actor="approver"' }] : [] })`.
4. Khi 071 thành `COMPLETED`: `ThemeApp.setActivated(true)`.
5. `template` → toast; `go-policy` → `activeFlowId="CAP-01"; activeScreenId="SCR-062"`, như `see-inventory` đang làm (CAP-01 lúc này còn màn cũ; plan CAP-01 mục 3.3.6 sẽ đổi sang bảng ngưỡng và đặt lối quay về 071).
6. Bỏ hàm không còn dùng: `cf12RejectSheet`, `bj12UnknownResult`, `bj12Result`, `bj12ExitList` nếu không còn chỗ gọi (`grep`).

### 4.4 Golden (`tools/golden.mjs`)

1. Bỏ ca `UIF-12_SCR-069_*` (tự mất khi màn rời danh sách luồng).
2. Thêm kịch bản ở mục 0.9 (theo cách các `SC_bj12_*` hiện có viết).
3. Thêm nhóm `HUB_home_not_activated` (`?mode=theme&app=inventory&activation=pending`).

## 5. Bước D — kiểm

1. Golden mobile so `tools/.golden-bj12-base`, web so `tools/.golden-bj12-web-base`: chỉ ca ở mục 0.9 khác; liệt kê ca khác vào ghi chú mục 10.
2. Bấm thử mọi màn × trạng thái của UIF-12 + Hub ở **cả hai khung**: 0 lỗi JS.
3. `/impeccable audit` phạm vi UIF-12 + Hub: tương phản ≥ 4,5:1, vùng chạm ≥ 44 (mobile), nhãn nút icon, đi bằng bàn phím trên web (Tab qua bảng lọc, Enter mở sheet, Esc đóng sheet).
4. Gửi ảnh: 066 READY, 067 web, 068 lỗi web, 068 đạt web + sheet Owner, 070 web, 071, Hub chưa kích hoạt; và 068 / 070 trên iPhone.
5. Mốc mới cho BJ sau: `tools/.golden-bj12-after`, `tools/.golden-bj12-web-after`.

## 6. Bước E — ghi lại (commit 3)

1. `CHANGELOG.md` `[5.5.0] — BJ-12 thiết kế lại; dựng K1–K4, K7`; phiên bản 5.5.0 (`manifest.json`, `workbench.js`, badge).
2. Viết lại theo `03.design/screens/_TEMPLATE.md`: SCR-066, 067, 068 (gồm phần rà soát), 070, 071 — chữ theo bảng mục 9; `status: IN_REVIEW`. SCR-069: thêm vào `screens/RETIRED.md` ("Thay bằng SCR-068", "Bỏ từ v5.5.0"), xoá file, sửa link trỏ tới nó (`grep -rn "SCR-069" specs/themes/theme-07 --include=*.md`).
3. Viết lại `03.design/flows/UIF-12-BJ-12.md` theo `flows/_TEMPLATE.md`: hai đường (Owner tự duyệt; nhân viên → Owner duyệt), lối vào Home "Kho chưa kích hoạt" và "Chờ duyệt".
4. **Quy tắc duyệt (T7-P mục 13):** phần của BJ-12 — UC-12-02 (BF-02 "segregation", kết quả "độc lập với người lập"), BJ-12 mục 2, SCR-070: ghi ngoại lệ `is_owner` tự duyệt; người duyệt khác = `is_owner` hoặc role `store_owner`. `T7-DR-081` sửa ở 7.3 (không ở đây).
5. T7-P mục 5: mô tả K1, K2, K3, K4, K7 đã dựng (tên hàm, chỗ dùng); mục 13: thêm các dòng chữ mới, đánh dấu đề xuất đã áp; mục 14 tiến độ.
6. `03.design/screens/INDEX.md`: dòng 066–071 (069 → "Đã bỏ"); `python3 tools/sync-registry.py`.

## 7. Thứ tự commit

1. C1: `shared-patterns.js`, `appShell` `extraClass`, CSS khuôn, Hub (chưa kích hoạt + "Chờ duyệt") — golden chỉ khác Hub.
2. C2: `bj12.js`, golden kịch bản mới.
3. E: tài liệu.

## 8. Không làm

- Bố cục web của BJ khác (dùng K7 ở BJ của chúng); các BJ khác chưa đăng ký nguồn "Chờ duyệt" (mỗi BJ tự đăng ký khi tới lượt).
- Đọc tệp Excel thật, tạo tệp mẫu thật (prototype chỉ toast).
- Sửa `T7-DR-081` / rà toàn bộ quy tắc duyệt (T7-P 7.3).
- Code Flutter.

## 9. Chữ trên màn (chuẩn cho bước E và Flutter)

| Màn / vị trí | Chữ |
|---|---|
| Hub, khối chặn | "Kho chưa kích hoạt" · "Nhập số tồn hiện có một lần để bắt đầu nhận, bán và kiểm kê hàng." · "Khởi tạo tồn kho" |
| Hub, Cần chú ý | "Chờ duyệt" · "{n} nhận hàng · {m} số dư đầu kỳ" |
| 066 READY | "Nhập số tồn hiện có của cửa hàng một lần để bắt đầu dùng Kho." · "Cần chuẩn bị" · "Tệp số dư theo mẫu" · "Tải tệp mẫu" · "Ngày chốt số dư" · "Tổng số lượng và tổng giá trị theo sổ để đối chiếu" · "Bắt đầu" |
| 066 REJECTED | "Lý do" · "Người từ chối" · "Tiếp tục chuẩn bị" |
| 066 / 071 đã kích hoạt | "Xem tồn kho" · "Đặt ngưỡng tồn" |
| 067 | "Kéo tệp vào đây hoặc Chọn tệp" (web) · "Tệp cần có các cột" · "Xem các cột cần có" (mobile) · "Nhập tổng giá trị theo sổ" / "Nhập tổng số lượng theo sổ" / "Chọn ngày chốt số dư" / "Chọn tệp số dư" (lỗi tại ô) |
| 068 lỗi | "{a} dòng đọc được · {b} hợp lệ · {c} cần sửa" · cột "Dòng", "Sản phẩm", "Lỗi", "Cách sửa" |
| 068 lệch | cột "Theo tệp", "Theo sổ", "Chênh lệch" |
| 068 đạt | "Số dư sẽ ghi nhận" · "Khớp số kiểm soát" · "Tất cả" / "Bán được" / "Không bán được" · "Hiện {n} / {m} dòng" · "Ghi nhận số dư đầu kỳ" (Owner) |
| Sheet Owner | "Ghi nhận số dư đầu kỳ" · "Chỉ ghi nhận một lần. Sai sau này phải sửa bằng điều chỉnh." · "Huỷ" · "Ghi nhận" |
| 070 | "Duyệt số dư đầu kỳ của {kho}, chốt {ngày}?" · "{người} gửi {thời điểm}" · "Cần chú ý" · "Không bán được" · "Sau khi duyệt" · "Kho bắt đầu hoạt động" |
| 071 | "Người duyệt" · "Chủ cửa hàng (tự duyệt)" |
| K3 | "Mã tham chiếu" · "Thời điểm gửi" · "Tồn kho" · "Chưa mở cho đến khi xác minh xong" · "Không nạp lại tệp hay gửi lại." · "Về Kho" |

## 10. Ghi chú khi làm

**Kết quả D (2026-10-21):** mobile 1376 ca / web 551 ca, 0 lỗi JS. So mốc: mobile `.golden-bj12-base` khớp `.golden-phase1` (1348 ca) và web `.golden-bj12-web-base` khớp `.golden-web-base` (555 ca) trước khi sửa. Mốc mới: `tools/.golden-bj12-after`, `tools/.golden-bj12-web-after`.

**Ca golden khác ngoài dự kiến ở mục 0.9 (mobile):** mọi kịch bản đi qua Home Kho đều khác vì dòng "Cần chú ý" đổi chữ "Nhận hàng chờ phê duyệt / 3 lần nhận đang chờ xử lý" → "Chờ duyệt / 3 nhận hàng": `SC_ws_*`, `SC_pending*`, `SC_quick_*`, `SC_search`, `SC_sidebar`, `SC_more`, `SC_mode`, `SC_hub_back`, `SC_bj01_theme`, cộng `SC_entry_state_12`. Đã kiểm vùng khác: chỉ dòng đó (hoặc nhiễu viền khung ~2.000 điểm ảnh, cùng loại mốc `HUB_home`); `SC_pending_1_list` / `_3_exit` khác ở tiêu đề "Chờ duyệt"; `SC_ws_setup_0_2_item` khác vì mở UIF-12 (SCR-066 mới). Web: chỉ `UIF-12_*@web` và `HUB_home@web`. Kịch bản `SC_bj12_*` khác vì bỏ bước `review` (màn gộp).

**Lệch plan / quyết định khi làm:**
1. **Nút "Kiểm tra dữ liệu" chỉ tắt khi chưa có tệp** (không tắt khi thiếu ô số). Lý do: nút tắt không nói được thiếu gì, và `VALIDATION_ERROR` (lỗi tại ô) không bao giờ vào được nếu nút tắt. Thiếu ô → bấm → lỗi hiện tại ô.
2. **Fixture lệch số kiểm soát đặt lúc dựng màn** (`cf12EnsureMismatchFixture` trong `render068BJ12`), không ở `onScreenEnter["UIF-12:SCR-068"]`: mở thẳng trạng thái từ harness / golden không đi qua `navigate`, nên móc `onScreenEnter` không chạy.
3. **Hậu tố tiền là "₫"** (helper `cfMoney` / `VMoneyField` sẵn có), không phải "đ" như chữ trong brief.
4. **Mở thẳng `VALIDATION_ERROR` khi dữ liệu đã đủ:** ô giá trị hiện trống kèm lỗi "Nhập tổng giá trị theo sổ" để thấy được lỗi tại ô (chỉ để hiển thị, không đổi dữ liệu).
5. **`k3Unknown` có thêm tham số `facts`** (dòng "Tồn kho …" chèn trước "Trạng thái"); thêm `k4Footer` (chân hai nút dùng chung K3 / K4).
6. **Lối vào Hub luôn đặt vai** (`data-theme-entry-actor`, mặc định `module`): "Khởi tạo tồn kho" và dòng Thiết lập kho → `owner`; mục "Số dư đầu kỳ" trong Chờ duyệt → `approver`. `entry=owner` mở BJ-12 ở nhánh Owner trong chế độ BJ.
7. **Chữ thêm ngoài mục 9** (đã vào T7-P mục 13): tiêu đề "Cần quyết" ở 070, "Dòng sẽ vào kho" trên bảng dòng, sheet Owner có thêm dòng "Ngày chốt" (4 dòng thay vì 3), banner 067 "Điền các ô được đánh dấu trước khi kiểm tra.", "Lý do" ở `REJECTED_EXECUTION` 071 ("Dữ liệu nguồn đã thay đổi trước khi ghi nhận"), câu K1 "Bạn chưa có quyền …".
8. Thêm: Esc đóng mọi sheet; lỗi tại ô tự biến mất khi ô có giá trị; `aria-label` cho 3 ô của 067.
9. SCR-069 vẫn còn trong danh sách `screens` của `workbench-data` (để alias hoạt động với URL cũ), chỉ bỏ khỏi `flows[UIF-12].screens`.

**Chưa làm / cần biết:**
- `/impeccable audit` chưa chạy; thay bằng kiểm tay: 0 lỗi JS; Tab / Enter / Esc dùng nút và `keydown` chuẩn (Esc đóng sheet đã thử); vùng chạm mobile đo 42px ở khung thu 0,955 = 44px thật; tương phản dùng token sẵn có của DS (chưa đo từng cặp).
- Công cụ GitNexus (`impact`, `detect_changes`) không có trong phiên này nên chưa chạy; blast radius đã kiểm bằng golden (mọi ca ngoài UIF-12 / Hub không đổi).
- Chưa commit (3 commit trong mục 7 chờ người dùng yêu cầu). Tài liệu bước E đã làm: CHANGELOG 5.5.0, 5 Screen Contract, RETIRED, INDEX, flow UIF-12, UC-12-02 / BJ-12 / SCR-070 (ngoại lệ `is_owner`), T7-P mục 5 / 6 / 13 / 14, registry.

## 11. Review

(2026-10-21, phiên review) — review chung cả chặng 1 (R1–R4 đã sửa ở v5.7.1; còn R5 `/impeccable audit` trước commit): [plan CAP-01 mục 10](T7-P-cap01-chinh-sach-ton.md#10-review). Lệch 1–9 chấp nhận. Phần của BJ-12: **R2** (Home chưa kích hoạt), **R4** (alias SCR-069 không mang trạng thái); góp ý 5, 6, 8, 10.
