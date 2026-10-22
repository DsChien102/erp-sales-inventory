# T7-P · BJ-03 Xác lập giá trị nhập ban đầu — thiết kế lại (bước B–E)

> Theme: Theme 7 Inventory · Trạng thái: Brief ✅ (duyệt 2026-10-21 — mục 0.10) | Plan C–E ✅ (viết cùng brief; **rà lại theo code sau khi BJ-02 xong**) | Làm ⬜ | Review ⬜
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) mục 8.2 **chặng 2 "Nhập hàng"**, BJ thứ hai. Làm **sau** [BJ-02](T7-P-bj02-nhan-hang.md) (fixture chung chặng 2 ở bước C0 của BJ-02; nút "Xác lập giá trị" ở SCR-012). Sau BJ-03 là [BJ-13](T7-P-bj13-dieu-chinh-gia-tri.md).
> Dùng lại K1, K3, K4, K7 và `k7EditCell`, `dsSegmented`; không có duyệt (UC-03-01 không có bước duyệt) nên **không dùng K2**.
> Thiết bị chính: **web** (Owner ngồi máy tính, T7-P mục 2); iPhone dùng được đủ việc.
> Ước lượng: **~1,5 ngày, 2 commit** (C + D; E). Người làm: bạn. Review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị, chép nguyên văn; **(mới)** = chữ mới, vào T7-P mục 13 ở bước E.

## 0. Brief (bước B, đã duyệt 2026-10-21)

### 0.1 Việc thật

- **Ai, lúc nào:** Owner (cửa hàng không có kế toán riêng — "kế toán kho" trong spec là Owner), ngay sau khi duyệt / tự nhận một phiếu (BJ-02 → "Xác lập giá trị"), hoặc gom vài phiếu cuối tuần trên máy tính.
- **Cần biết / làm gì:** hàng vừa nhận giá bao nhiêu một đơn vị, lấy từ đâu, tổng bao nhiêu; ghi một lần để tồn có giá trị và giá vốn được tính lại (BJ-14). Nhận theo chứng từ: giá đã có ở chứng từ mua → **chỉ xem và xác nhận**. Nhập nhanh: chưa có chứng từ → Owner **tự nhập giá** kèm nguồn và lý do.
- **Thường gặp:** 1–5 sản phẩm / phiếu, đa số đủ căn cứ; thỉnh thoảng giá đơn mua và xác nhận NCC lệch nhau (phải thống nhất ở Mua hàng trước).
- **Quy tắc giữ** (BJ-03, UC-03-01 BR-01…05, JA-01…05): công thức giá trị nhập (giá mua − giảm giá + thuế/phí không thu hồi + chi phí mua đã đủ căn cứ); **không tự chia số lượng** — chỉ ghi phần căn cứ bao phủ; nguồn và bằng chứng lưu riêng; không sửa PO / hoá đơn (Theme 10 chỉ đọc); **mâu thuẫn thương mại không được chọn tuỳ ý một giá** — quay về Mua hàng; căn cứ trực tiếp của nhập nhanh **chỉ VND**, nguồn và ngày phải rõ, bắt buộc lý do; UI chỉ hiện giá trị VND đã chuẩn hoá, không hỏi tỷ giá; nguồn đổi trước khi xác nhận → từ chối cả lệnh, rà lại; ghi xong không tạo giá vốn chính thức, chỉ đánh dấu sản phẩm + kỳ cần BJ-14; fact đến sau → BJ-13, nhập sai → BJ-11.

### 0.2 Luồng hiện tại

Ảnh: web `tools/.golden-chang1-web/UIF-03_SCR-014_READY@web`, `…SCR-015_READY@web`, `…SCR-017_READY@web`; mobile `tools/.golden-chang1/SC_bj03_basis_2_add-basis`, `…UIF-03_SCR-019_COMPLETED`.

```text
Hub → Quản lý kho → Giá trị kho → "Giá trị hàng nhập" → 014 Hàng chờ xác lập giá trị (danh sách phiếu)
  → 015 Xác lập giá trị nhập ban đầu: chạm dòng sản phẩm để chọn (không có ô tick); nhập nhanh: "Thêm căn cứ giá" → sheet 8 ô
  ─"Rà soát"→ 017 Rà soát giá trị nhập ban đầu ─"Xác nhận giá trị"→ 019 Kết quả ─"Tiếp tục xử lý" / "Về danh sách"
Không có lối vào từ kết quả nhận hàng (BJ-02 SCR-012).
```

### 0.3 Vấn đề

| # | Màn | Vấn đề |
|---|---|---|
| 1 | Lối vào | Chỉ vào được qua Hub → Giá trị kho; nhận hàng xong (BJ-02 012) không dẫn sang |
| 2 | Tên gọi | Bốn tên cho một việc: Hub "Giá trị hàng nhập" / "Xác nhận giá trị ban đầu…", inspector "Xác nhận giá nhập", màn "Hàng chờ xác lập giá trị", "Xác lập giá trị nhập ban đầu" |
| 3 | 014 | Dòng phụ bị cắt ("Minh Dũng · Theo chứng từ · 2 dòn…"); phiếu sẵn sàng không có badge; không biết phiếu chờ bao lâu; web là cột điện thoại |
| 4 | 015 | Dòng sản phẩm trông như dòng tĩnh, chọn bằng chạm dòng, không có ô tick; trước khi chọn hiện "**0 đ/hộp**"; không thấy thành tiền; "Rà soát" tắt không nói vì sao |
| 5 | 015 | Dòng mâu thuẫn chỉ có banner "Căn cứ mua hàng đang mâu thuẫn" — không nói giá nào lệch giá nào, ai xử lý, làm gì tiếp |
| 6 | 015 | Phiếu ngoại tệ hiện "4,1 USD/lọ", nhãn "FX authoritative" — trái JA-05 (UI chỉ làm việc với VND đã chuẩn hoá) |
| 7 | 015 sheet | "Thêm căn cứ giá" 8 ô, có ô **chọn tiền tệ VND / USD** (trái JA-05: căn cứ trực tiếp Phase 1 chỉ VND); "Ngày căn cứ" để trống; không có gợi ý giá để so; chữ "Kế toán có thể lập căn cứ…" — cửa hàng không có kế toán |
| 8 | 017 | Một màn riêng chỉ để rà 1–3 sản phẩm; khối "Tổng giá trị sẽ ghi" xám lớn; "Chi tiết căn cứ" là nút trong thẻ |
| 9 | 019 | "2 sản phẩm/dòng còn cần xử lý."; "Giá vốn: Cần cập nhật" không có lối sang BJ-14; `UNKNOWN` không theo K3 (thiếu mã tham chiếu, thời điểm, "Về Kho") |
| 10 | Trạng thái | Golden giống hệt `READY`: 015 `LOADING` / `EVIDENCE_MISSING` / `SOURCE_CHANGED` / `ALREADY_CONFIRMED` / `VALIDATION_ERROR`; 014 `EMPTY` / `FILTER_EMPTY` / `FINANCIAL_MASKED` (hàm dựng bỏ qua trạng thái) |
| 11 | Fixture | PN-260816-04 ở BJ-03 là Nobivac 100 hộp chia 3 lát (DH2507, DH2509, DH2509 cách ly) + "Amoxicillin LA" — khác phiếu BJ-02 vừa nhận (Nobivac 121 hộp lô DH2507 + Oxytetracycline LA 24 chai sau C0 của BJ-02) |
| 12 | Mã | Hai khối dựng (v430 và v461) cùng định nghĩa 015 / 016 / 017 / 019 — khối v430 chết trừ 014; `ensureVal03ReviewFixture` / `ensureVal03ResultFixture` tự chọn dữ liệu khi vào thẳng |

### 0.4 Đề xuất

**Luồng mới**

```text
BJ-02 012 "Xác lập giá trị" ─────────────────────────────┐
Hub → Giá trị kho → "Hàng chờ xác lập giá trị" → 014 ──┤
                                                         ▼
015 Xác lập giá trị nhập ban đầu (một phiếu): bảng sản phẩm · đơn giá căn cứ · thành tiền · tình trạng
    dòng đủ căn cứ được chọn sẵn; nhập nhanh: "Nhập giá" → sheet "Thêm căn cứ giá" (gọn, chỉ VND)
    ─"Ghi giá trị ({n})"→ sheet xác nhận (thay 017) ─"Xác nhận giá trị"→ 019 Kết quả (K4)
       → còn hàng chờ: "Tiếp tục xử lý" (về 015) · hết: "Về danh sách" · phụ "Cập nhật giá vốn" (BJ-14)
```

*Tên gọi* (vấn đề 2)

1. Giữ thuật ngữ của spec, **dùng một tên ở mọi nơi**: dòng Hub = tên màn 014 "Hàng chờ xác lập giá trị" + phụ "Ghi giá nhập cho hàng đã nhận" **(mới)**; inspector / `hub.js` `FLOW_LABELS["UIF-03"]` = "Xác lập giá trị nhập ban đầu"; nút từ màn khác "Xác lập giá trị" (BJ-02). Chốt ở 0.10 a.

*SCR-014 Hàng chờ xác lập giá trị*

2. Chip lọc có số: "Tất cả" · "Có thể xác lập" · "Cần xử lý" (giữ chữ; số theo `ds24Chip(…, count)`).
3. Dòng: tiêu đề = mã phiếu; phụ "{NCC} · {Theo chứng từ | Nhập nhanh}" (bỏ "· n dòng chờ" khỏi dòng phụ để không bị cắt); bên phải "{n} sản phẩm chờ" **(mới)** + badge theo `val03ReceiptBadge` ("Có thể xử lý" / "Cần đối chiếu" / "Chờ căn cứ" — giữ chữ, phiếu sẵn sàng cũng có badge). Phiếu vừa nhận ở BJ-02 đứng đầu.
4. Web: `k7Table` — Phiếu nhận · Nhà cung cấp · Cách nhận · Ngày nhận · Sản phẩm chờ · "Chờ" ("{n} ngày" **(mới)**, từ `ageDays`) · Tình trạng.
5. `EMPTY` → `k1Empty({ title:"Không còn hàng chờ giá trị", description:"Các phiếu nhận đã được xác lập giá trị." (mới) })`; `FILTER_EMPTY` → `k1Empty` + "Xem tất cả" (chữ CAP-01); `LOADING` → `k1Loading`; `PERMISSION_DENIED` và `FINANCIAL_MASKED` → `k1Denied` (mục 13).

*SCR-015 Xác lập giá trị nhập ban đầu* (một phiếu; web chính, K7)

6. Đầu: dòng ngữ cảnh "{phiếu} · {NCC}" + phụ "{Theo chứng từ | Nhập nhanh} · nhận {ngày}".
7. **Bảng sản phẩm** (`k7Table`; iPhone danh sách thẻ): ô tick · Sản phẩm (tên + mã; dưới tên các lô "Lô {mã} · {SL} {ĐVT}") · Số lượng chờ · "Đơn giá" (đ/{ĐVT}) · "Thành tiền" · Tình trạng. Dòng **đủ căn cứ được tick sẵn** (chốt 0.10 c); bỏ tick được.
8. Theo tình trạng của dòng (giữ cách tính `val03EvidenceState` / `groupState`):

| Tình trạng | Đơn giá / thành tiền | Tình trạng hiện | Làm được |
|---|---|---|---|
| `READY` (theo chứng từ) | đơn giá căn cứ, chỉ đọc; thành tiền = SL × đơn giá | badge "Đủ căn cứ" (giữ) + phụ "Căn cứ: {nhãn căn cứ}" | tick; liên kết "Cách tính" **(mới)** mở sheet bảng `breakdown(g)` (giữ chữ: "Giá mua", "Chiết khấu dòng", "Chiết khấu chứng từ", "Chi phí mua đã biết", "Thuế/phí tính vào giá trị", "Đơn giá ghi nhận ban đầu") |
| `COMMERCIAL_CONFLICT` | "—" | badge "Cần đối chiếu" (giữ) + phụ "{nguồn 1} {giá 1} · {nguồn 2} {giá 2}" **(mới)** + "Thống nhất giá ở Mua hàng rồi quay lại." **(mới)** | không tick được |
| `COMMERCIAL_MISSING` | "—" | badge "Chờ căn cứ" (giữ) + phụ "Chứng từ mua chưa có giá cho dòng này." **(mới)** | không tick được |
| `DIRECT_MISSING` (nhập nhanh) | nút **"Nhập giá" (mới)** | badge "Chưa có căn cứ" (giữ) | "Nhập giá" → sheet mục 10 |
| `DIRECT_CONFLICT` | "—" | badge "Cần kiểm tra" + banner giữ "Có nhiều căn cứ trực tiếp cần kiểm tra" | không tick được |

9. Ngoại tệ (vấn đề 6): đơn giá và thành tiền chỉ hiện **VND đã chuẩn hoá**; sheet "Cách tính" ghi một dòng "Quy đổi từ USD theo tỷ giá kế toán" **(mới)**, không hiện tỷ giá.
10. **Sheet "Thêm căn cứ giá"** (giữ tiêu đề; chỉ nhập nhanh): bỏ ô "Tiền tệ" (JA-05, cố định VND); "Đơn giá mua" có hậu tố "đ/{ĐVT}" **(mới)** + gợi ý dưới ô "Giá vốn hiện tại: {giá} đ/{ĐVT}" **(mới)** khi sản phẩm có giá vốn chính thức (chỉ gợi ý, không điền sẵn — chốt 0.10 f); "Cách hiểu giá" thành `dsSegmented` "Đã gồm thuế | Chưa gồm thuế" (giữ chữ, bỏ hai câu giải thích dài); "Thuế trên căn cứ" chỉ hiện khi chưa gồm thuế (giữ); "Căn cứ giá từ đâu?" (giữ, giữ placeholder); "Ngày căn cứ" **điền sẵn ngày nhận**; "Tham chiếu / bằng chứng" (giữ); "Lý do xác lập trực tiếp" (giữ, bắt buộc). Bỏ câu "Kế toán có thể lập căn cứ…" → phụ của dòng: "Chưa có chứng từ mua — nhập giá theo hoá đơn hoặc báo giá của nhà cung cấp." **(mới)**. Lưu → dòng thành `READY`, tick sẵn; web: hộp thoại giữa màn (khuôn sheet của BJ-12).
11. Dải tổng ngay trên chân: "Đã chọn {n} sản phẩm · {tổng}" **(mới)**. Chân **"Ghi giá trị ({n})" (mới, thay "Rà soát")**; tắt kèm dòng lý do "Chọn ít nhất một sản phẩm đủ căn cứ" **(mới)**.
12. Web: `k7Split` — trái bảng; phải khối "Tóm tắt" (phiếu, NCC, ngày nhận, đã chọn, tổng, nút "Ghi giá trị ({n})"); iPhone: bảng thành thẻ, tóm tắt thành dải tổng + chân.
13. **Quyền:** chỉ Owner (`is_owner` / `store_owner`). `currentActor()==="staff"` và `FINANCIAL_MASKED` → `k1Denied({ what:"Bạn chưa có quyền xác lập giá trị" (mới), next:"Chỉ chủ cửa hàng xem và ghi giá nhập." (mới) })` ở cả 014, 015, 019.

*Sheet xác nhận (thay SCR-017)* — chốt 0.10 b

14. "Ghi giá trị nhập ban đầu?" **(mới)**; số liệu: Phiếu nhận · "{n} sản phẩm" · "Tổng giá trị sẽ ghi" (giữ chữ 017) + danh sách ngắn "{tên}: {SL} {ĐVT} × {đơn giá} = {thành tiền}" **(mới)**; câu "Ghi xong không sửa trực tiếp. Chi phí phát sinh sau dùng điều chỉnh giá trị." **(mới)**; "Quay lại" | "Xác nhận giá trị" (giữ chữ 017).
15. Nguồn đổi lúc xác nhận (`SOURCE_CHANGED`, EF-C): đóng sheet, 015 hiện banner "Căn cứ đã thay đổi" + "Quay lại kiểm tra dữ liệu hiện hành trước khi xác nhận." (giữ) và số mới; tick giữ nguyên; nút "Kiểm tra lại" (giữ) chỉ đóng banner.
16. SCR-017 → RETIRED ("Thay bằng sheet xác nhận trong SCR-015", v5.9.0); alias `SCR-017` → `SCR-015`.

*SCR-019 Kết quả xác lập giá trị* (K4)

17. `COMPLETED`: `k4Result({ title:"Đã ghi giá trị nhập ban đầu", description:"Giá trị đã được ghi cho đúng phạm vi; sản phẩm liên quan cần cập nhật giá vốn." })` (giữ chữ); `facts`: Phiếu nhận · Sản phẩm đã xác lập · Tổng giá trị đã ghi · Giá vốn "Cần cập nhật" (giữ) · Người ghi · Lúc; còn hàng chờ: thêm dòng "Còn chờ giá trị" "{n} sản phẩm" **(mới, thay "{n} sản phẩm/dòng còn cần xử lý.")**. "Xem chi tiết {n} sản phẩm" (giữ) mở sheet danh sách.
18. Bước tiếp: phụ **"Cập nhật giá vốn" (mới)** → BJ-14 `entryTargets["UIF-14"]["dirty-scope"]` (màn hiện có; chặng 6 thiết kế lại); chính "Tiếp tục xử lý" (còn hàng chờ, về 015 cùng phiếu) hoặc "Về danh sách" (hết, về 014) — giữ chữ.
19. `UNKNOWN` → `k3Unknown({ operation:"Xác lập giá trị nhập ban đầu", scope:"{phiếu} · {n} sản phẩm", ref, sentAt, sourceFlow:"UIF-03" })` (giữ câu "Không gửi lại lệnh xác nhận…"). `REJECTED_EXECUTION` → K4 cảnh báo "Chưa ghi giá trị nhập ban đầu" + "Không có thay đổi. Kiểm tra lại căn cứ hiện hành." + "Xem lại công việc" (giữ). `PROCESSING` → `k1Loading`.

*Lối vào*

20. BJ-02 012 "Xác lập giá trị" gọi `val03OpenForReceipt(ref)` (mục 3.3).
21. Hub Giá trị kho: dòng UIF-03 đổi chữ như mục 1. Không thêm dòng "Cần chú ý" trên Home (chốt 0.10 e).

### 0.5 Trạng thái (sau thiết kế lại)

| Màn | Trạng thái | Hiện gì | Làm được gì | Lối ra |
|---|---|---|---|---|
| 014 | READY | bảng / danh sách phiếu, chip có số | mở phiếu, lọc, tìm | Về Kho |
| 014 | EMPTY / FILTER_EMPTY | `k1Empty` | "Xem tất cả" (lọc rỗng) | Về Kho |
| 014, 015 | LOADING | `k1Loading` | — | — |
| 014, 015, 019 | PERMISSION_DENIED / FINANCIAL_MASKED | `k1Denied` | — | "Về Kho" |
| 015 | READY | bảng, dòng đủ căn cứ tick sẵn | tick, "Cách tính", "Nhập giá", "Ghi giá trị ({n})" | Quay lại |
| 015 | EVIDENCE_MISSING | mọi dòng "Chờ căn cứ" / "Cần đối chiếu", nút ghi tắt + lý do | xem | Quay lại |
| 015 | VALIDATION_ERROR | sheet căn cứ mở, lỗi tại ô | sửa, "Lưu căn cứ" | đóng sheet |
| 015 | SOURCE_CHANGED | banner "Căn cứ đã thay đổi" + số mới | "Kiểm tra lại", ghi lại | Quay lại |
| 015 | ALREADY_CONFIRMED | `k1Locked({ title:"Phiếu này đã được xác lập giá trị" (mới), description:"Chi phí phát sinh sau dùng điều chỉnh giá trị." (mới) })` | — | "Về danh sách" |
| 019 | PROCESSING | `k1Loading` | — | — |
| 019 | COMPLETED | K4 | "Cập nhật giá vốn", "Tiếp tục xử lý" / "Về danh sách" | Về Kho |
| 019 | REJECTED_EXECUTION | K4 cảnh báo | "Xem lại công việc" | Về Kho |
| 019 | UNKNOWN | K3 | "Chuyển sang xác minh" | "Về Kho" |

Alias: 016 → 015 (giữ), 017 (mọi trạng thái) → 015 mặc định, 018 → UIF-13 085 (giữ).

### 0.6 Khuôn dùng lại (không dựng mới)

K1 (`k1Loading`, `k1Denied`, `k1Empty`, `k1Locked`, `k1ExitAttr`), K3 (`k3Unknown`), K4 (`k4Result`, `k4Footer`), K7 (`k7Split`, `k7Table`, lớp `k7-wide`), `dsSegmented`, sheet / hộp thoại của BJ-12. Bảng có ô tick cần **ô tick trong `k7Table`**: thêm cột tuỳ chọn `select: { attr, checked, disabled, label }` vào `k7Table` (`shared-patterns.js:113`) — bỏ trống thì HTML như cũ (BJ-12 / CAP-01 không đổi). BJ-13 dùng lại.

Thành phần mới (→ T7-P mục 6): ô tick trong bảng (`VTable` có cột chọn; trên iPhone là `VCheckbox` đầu thẻ).

### 0.7 Không đổi

Quy tắc ở 0.1; mọi hàm tính trong khối v397 (`basisCandidate`, `calc`, `confirmationAmount`, `tokenStale`, `bootstrapConflict`, `val03ApplySourceUpdate`, `val03Commit`); khối thuế / FX nội bộ (`taxPolicy`, `fxFor`) giữ, chỉ bỏ ô chọn tiền tệ (cố định `"VND"`). Chữ giữ: tiêu đề 014 / 015 / 019, "Thêm căn cứ giá", "Đơn giá mua", "Cách hiểu giá", "Đã gồm thuế", "Chưa gồm thuế", "Thuế trên căn cứ", "Căn cứ giá từ đâu?", "Ngày căn cứ", "Tham chiếu / bằng chứng", "Lý do xác lập trực tiếp", "Lưu căn cứ", "Đủ căn cứ", "Cần đối chiếu", "Chờ căn cứ", "Chưa có căn cứ", "Tổng giá trị sẽ ghi", "Xác nhận giá trị", "Căn cứ đã thay đổi", "Kiểm tra lại", "Đã ghi giá trị nhập ban đầu", "Tiếp tục xử lý", "Về danh sách", "Xem lại công việc".

### 0.8 Kiểm (bước D)

- Golden **mobile** được khác: `UIF-03_*` (ca `UIF-03_SCR-017_*` **mất**), `SC_bj03_*`, `SC_entry_UIF-03_*`, `SC_ws_valuation_*` (chữ dòng Hub), ca BJ-02 đi qua "Xác lập giá trị" (`SC_bj02_owner_self_*` bước cuối). Mọi ca khác khớp mốc `tools/.golden-bj02-after`.
- Golden **web** được khác: `UIF-03_*@web` và kịch bản web mới; ca khác khớp `tools/.golden-bj02-web-after`.
- Kịch bản mới (mục 3.5): `SC_bj03_from_receipt`, `SC_bj03_direct`, `SC_bj03_list`, `SC_bj03_stale`, `SC_bj03_staff`, `SC_bj03_unknown`.

### 0.9 Ước lượng C–E

~1,5 ngày: C ~0,9 (fixture + 014 + 015 + sheet + 019 + dọn khối v430); D ~0,3; E ~0,3.

### 0.10 Đã chốt khi duyệt brief (2026-10-21): **mọi điểm theo cột "Đề xuất"**

| # | Điểm | Đề xuất | Phương án khác |
|---|---|---|---|
| a | Tên gọi | **Giữ thuật ngữ spec**, một tên ở mọi nơi (Hub = "Hàng chờ xác lập giá trị") | Đổi chữ hiển thị sang "Giá nhập" / "Chốt giá nhập" (sửa Screen Contract, UC giữ thuật ngữ) |
| b | Màn rà soát 017 | **Bỏ**, thành sheet xác nhận trong 015 | Giữ 017, chỉ làm gọn |
| c | Dòng đủ căn cứ | **Tick sẵn** (trường hợp thường: ghi hết) | Không tick sẵn, Owner tự chọn từng dòng |
| d | Ô "Tiền tệ" ở căn cứ trực tiếp | **Bỏ, cố định VND** (đúng JA-05 / UC-03-01 mục 7.1) | — (sửa lỗi so với spec, không phải lựa chọn) |
| e | Dòng "Hàng chờ xác lập giá trị" trong "Cần chú ý" trên Home | **Không thêm** (lối vào = kết quả nhận hàng + Giá trị kho; Home dùng chung cho nhân viên) | Thêm dòng có số phiếu chờ |
| f | Gợi ý giá trong sheet căn cứ | **Thêm** "Giá vốn hiện tại: {giá} đ/{ĐVT}" (chỉ chữ gợi ý) | Không gợi ý |

---

## 1. Mục tiêu

1. Từ kết quả nhận hàng, Owner xác lập giá phiếu vừa nhận trong một mạch: thấy đơn giá, thành tiền, dòng nào ghi được và dòng nào phải chờ, ghi một lần.
2. Nhập nhanh: Owner nhập giá trực tiếp bằng VND trong một sheet gọn, có nguồn và lý do.
3. Mọi trạng thái ở 0.5 dựng khác nhau và có lối ra.

## 2. Chuẩn bị

1. BJ-02 đã xong (C0 fixture chung, 012 có "Xác lập giá trị"). Rà lại mục 3 với code BJ-02 thật (biến bàn giao `bj02LastCommitted = { ref, mode, lines }` — plan BJ-02 mục 5.2) trước khi làm.
2. Mốc = `tools/.golden-bj02-after` / `tools/.golden-bj02-web-after` (bước D của BJ-02); nếu chưa có, chụp ngay và so khớp HEAD.
3. Máy chủ `python3 -m http.server 8765 --bind 127.0.0.1 &` trong `html/`.

## 3. Bước C — dựng (commit 1)

### 3.1 Fixture (`app/bj03.js`)

1. `val03Receipts[0]` (VAL03-R1, PN-260816-04, Minh Dũng): **khớp phiếu BJ-02** — G1 Nobivac DHPPi (`code` = `SP-000184`, hộp, LOT) một lát `ROL-401 | LOT-DH2507 | SELLABLE` 121 hộp (căn cứ `BASIS-G1-A` giữ → 81.700 đ/hộp → 9.885.700 đ); G2 đổi "Amoxicillin LA" → **Oxytetracycline LA** (`SP-000147`, chai, NONE) 24 chai, hai căn cứ PO 120.000 / xác nhận NCC 121.000 (giữ → `CONFLICT`). Bỏ lát DH2509 / cách ly của Nobivac (ghi chú CHANGELOG: ca nhiều lát giữ ở logic, fixture không còn).
2. Các phiếu khác (R2 nhập nhanh Găng tay — `DIRECT_MISSING`; R3 Vaccine Canine X — USD đã chuẩn hoá; R4 VietVet — một dòng đủ căn cứ, một dòng `COMMERCIAL_MISSING`) giữ, chỉ thêm `ageDays` nếu thiếu và `officialCostVnd` cho Găng tay (135.000 đ/hộp, lấy từ `quickProductCatalog` của BJ-02) để gợi ý giá.
3. `isQuick(r)` đọc trường `entryType:"QUICK"|"DOCUMENT"` (thêm vào fixture) thay vì so `id`.
4. Bỏ `ensureVal03ReviewFixture` (017 không còn; hàm nằm ở `shared-valuation.js:42`) và thay `ensureVal03ResultFixture` (`shared-valuation.js:52`) bằng một kết quả mẫu tĩnh cho ca vào thẳng `SCR-019&state=COMPLETED` (`val03LastResult ||= {...}` dựng từ R1 G1) — không gọi `val03Commit` khi render.

### 3.2 Lối vào

1. `val03OpenForReceipt(ref)` (mới, export qua `window.__VET45_QA__`): tìm `val03Receipts` có `receipt === ref`; nếu `bj02` vừa ghi phiếu đó (`bj02LastCommitted?.ref === ref`) thì cập nhật số lượng / lô của các nhóm cùng `code` theo dòng BJ-02 (Đạt + Cách ly + Hỏng; mỗi lô một lát `SELLABLE` cho phần Đạt, lát `QUARANTINE` / `DAMAGED` nếu có); đặt `val03SelectedReceiptId`, tick sẵn dòng đủ căn cứ (`selectGroup(g,true)` cho `groupState==='READY'`), `activeFlowId="UIF-03"; activeScreenId="SCR-015"; stateByScreen["SCR-015"]="READY"; syncReviewUrl(); render();`. Nút quay lại của 015 khi vào từ BJ-02 → về 012 (`val03ReturnFlow` / `val03ReturnScreen`, như `capExit`).
2. `entryTargets["UIF-03"]["receipt-task"]` giữ (SCR-015); mở từ Hub vào 014.
3. `hub.js`: dòng `valuation.items` UIF-03 → `title:'Hàng chờ xác lập giá trị', subtitle:'Ghi giá nhập cho hàng đã nhận'`; `FLOW_LABELS['UIF-03'] = 'Xác lập giá trị nhập ban đầu'`.

### 3.3 Màn

| Màn | Việc |
|---|---|
| Chung | Mọi màn `appShell({ …, extraClass:"k7-wide" })`; vai `staff` hoặc state `FINANCIAL_MASKED` / `PERMISSION_DENIED` → `k1Denied` (0.4 mục 13). Viết lại trong **một** khối; xoá khối v430 của 015 / 016 / 017 / 019 (`render015V430` và listener `data-v430-val03-*` trừ phần của 014) — `grep -n "v430-val03" app/*.js tools/golden.mjs` trước khi xoá |
| 014 | `k7FilterChips` hoặc `ds24Chip(…, count)` (chọn cách BJ-01 — góp ý 7 chặng 1); `k7Table` cột 0.4 mục 4; `mobileRow` = `ds24ListRow` tiêu đề mã phiếu, phụ "{NCC} · {cách nhận}", trailing "{n} sản phẩm chờ" + badge; `data-bj03-receipt="{id}"`; trạng thái theo 0.5 |
| 015 | `k7Split({ main: ngữ cảnh + k7Table(select…), aside: tóm tắt })`; dòng theo bảng 0.4 mục 8 (`data-bj03-select="{groupId}"`, `data-bj03-breakdown="{groupId}"`, `data-bj03-add-basis="{groupId}"`); sheet "Cách tính" dùng `breakdown(g)` giữ; chân `k4Footer([{ label:\`Ghi giá trị (${n})\`, attr:'data-bj03-open-confirm', primary:true, disabled:n===0 }])` + dòng lý do |
| Sheet căn cứ | `basisForm` bỏ `selectField('Tiền tệ…')`, `d.currency` cố định `"VND"`; `amountField` hậu tố "đ/{ĐVT}"; gợi ý giá vốn; `taxChoice` → `dsSegmented({ items:[["INCLUDED","Đã gồm thuế"],["EXCLUDED","Chưa gồm thuế"]], value:d.taxMode, attr:"data-bj03-tax-mode" })`; `d.date` mặc định ngày nhận `r.receivedAt`; giữ kiểm lỗi `saveBasis` (bỏ hai lỗi tiền tệ) |
| Sheet xác nhận | khuôn sheet BJ-12 (`bottom-sheet`, web là hộp thoại); `data-bj03-confirm` / `data-bj03-confirm-close`; Escape đóng |
| 015 trạng thái | `EVIDENCE_MISSING`: dựng với mọi nhóm của phiếu ở `MISSING` (chọn phiếu R4 hoặc đánh dấu tạm, không sửa fixture gốc); `SOURCE_CHANGED`: banner giữ trên bảng; `ALREADY_CONFIRMED`: `k1Locked`; `VALIDATION_ERROR`: mở sheet căn cứ của R2 G3 với lỗi tại ô; `LOADING`: `k1Loading({ blocks:["heading","row","row","row"] })` |
| 019 | `k4Result` / `k3Unknown` như 0.4 mục 17–19; "Cập nhật giá vốn" `data-bj03-go-cost` → `activeFlowId="UIF-14"; activeScreenId="SCR-073"; stateByScreen["SCR-073"]="READY"; syncReviewUrl(); render();`; "Tiếp tục xử lý" `data-bj03-result-back`, "Về danh sách" `data-bj03-result-list` |

### 3.4 Sự kiện

1. Đổi thuộc tính `data-v461-val03-*` / `data-v430-val03-*` → `data-bj03-*` (sửa `tools/golden.mjs` cùng lúc).
2. `data-bj03-select` → bật / tắt nhóm (chỉ khi `groupState==='READY'`), `renderAppScreen()`.
3. `data-bj03-open-confirm` → lưu `val03ReviewSourceVersion = r.sourceVersion`, mở sheet. `data-bj03-confirm` → nếu `Number(val03ReviewSourceVersion)!==Number(r.sourceVersion)` (hoặc `tokenStale`): đóng sheet, `stateByScreen["SCR-015"]="SOURCE_CHANGED"`, render; ngược lại `val03Commit()` → `stateByScreen["SCR-019"]="COMPLETED"; navigate("SCR-019")`.
4. Sheet căn cứ: giữ `input` / `change` đồng bộ nháp (`syncBasisDraft`); `data-bj03-tax-mode` đặt `taxMode`.
5. Escape đóng mọi sheet của BJ-03.

### 3.5 Golden (`tools/golden.mjs`)

Sửa `SC_bj03_list`, `SC_bj03_basis`, `SC_bj03_confirm` theo selector mới (`SC_bj03_confirm` bắt đầu ở 015 thay vì 017). Thêm:

| Kịch bản | Bắt đầu | Bước |
|---|---|---|
| `SC_bj03_from_receipt` | `R + 'SCR-007&entry=owner'` (gốc UIF-02 của BJ-02) | đi như `SC_bj02_owner_self` tới 012 → "Xác lập giá trị" → 015 PN-260816-04 (Nobivac tick sẵn, Oxy "Cần đối chiếu") → "Cách tính" → đóng → "Ghi giá trị (1)" → sheet → "Xác nhận giá trị" → 019 "Còn chờ giá trị · 1 sản phẩm" → "Cập nhật giá vốn" |
| `SC_bj03_direct` | `V3 + 'SCR-014'` | PN-260816-02 → "Nhập giá" → 120000 → "Đã gồm thuế" → nguồn "Báo giá NCC" → lý do → "Lưu căn cứ" → dòng tick sẵn → "Ghi giá trị (1)" → "Xác nhận giá trị" → 019 → "Về danh sách" |
| `SC_bj03_list` | `V3 + 'SCR-014'` | chip "Có thể xác lập" / "Cần xử lý" / "Tất cả", tìm "Minh", xoá tìm, mở R1 |
| `SC_bj03_stale` | `V3 + 'SCR-015'` | "Ghi giá trị (1)" → gọi `val03ApplySourceUpdate('VAL03-G1', 84000)` → "Xác nhận giá trị" → banner "Căn cứ đã thay đổi" → "Kiểm tra lại" |
| `SC_bj03_staff` | `V3 + 'SCR-014&entry=staff'` | — (thấy `k1Denied`) — thêm `entryTargets["UIF-03"].staff = { screen:"SCR-014" }` |
| `SC_bj03_unknown` | `V3 + 'SCR-019&state=UNKNOWN'` | "Chuyển sang xác minh" |

`WEB_SCENARIOS` thêm `SC_bj03_from_receipt`, `SC_bj03_direct`, `SC_bj03_list`.

## 4. Bước D — kiểm

1. Golden mobile / web so mốc mục 2: chỉ ca ở 0.8 khác; ghi vào mục 8. Mọi trạng thái 0.5 của 014 / 015 / 019 cho ảnh **khác nhau** (kiểm bằng `diff` thân `.txt` như vấn đề 10 — không còn ca "giống hệt READY" ngoài chủ đích).
2. Bấm thử UIF-03 hai khung + nút "Xác lập giá trị" từ BJ-02: 0 lỗi JS; `node --check app/*.js harness/*.js`.
3. **`/impeccable audit` phạm vi UIF-03 — chặn commit E.** Chạy trên 014, 015 (bảng có tick, dòng mâu thuẫn, sheet "Cách tính", sheet căn cứ, sheet xác nhận, `SOURCE_CHANGED`), 019 (`COMPLETED`, `UNKNOWN`), ở cả hai khung. Đạt khi: chữ ≥ 4,5:1 (badge, chữ phụ xám trong bảng); vùng chạm ≥ 44 × 44 ở iPhone (ô tick, "Nhập giá", "Cách tính"); ô tick có `role="checkbox"` / `aria-checked` + nhãn "{tên sản phẩm}"; ô tiền có `aria-label`; web đi được bằng bàn phím (Tab qua ô tick và nút, Space tick, Esc đóng sheet, focus về nút đã mở). Lỗi trong phạm vi: sửa ngay; ngoài phạm vi: ghi mục 9.
4. Gửi ảnh: 014 web, 015 web (bảng + tóm tắt), 015 iPhone, sheet căn cứ iPhone, sheet xác nhận web, 019, `SOURCE_CHANGED`.
5. Mốc mới cho BJ-13: `tools/.golden-bj03-after`, `tools/.golden-bj03-web-after`.

## 5. Bước E — ghi lại (commit 2)

1. `CHANGELOG.md` `[5.9.0] — BJ-03 thiết kế lại`; phiên bản 5.9.0.
2. Viết lại theo `_TEMPLATE.md`: SCR-014, SCR-015 (gồm sheet căn cứ, sheet "Cách tính", sheet xác nhận; trạng thái 0.5), SCR-019; SCR-017 → `RETIRED.md` ("Thay bằng sheet xác nhận trong SCR-015", v5.9.0), xoá file, sửa link; UIF-03 (sơ đồ mới, lối vào từ BJ-02 012 và Hub, lối ra sang BJ-14 / BJ-17).
3. Sửa đặc tả: UC-03-01 mục 8 (liên hệ giao diện: 017 bỏ), ghi rõ "Kế toán kho" = Owner ở cửa hàng nhỏ (BJ-03 mục 2, một dòng chú thích); không đổi quy tắc.
4. `INDEX.md` 014–019; T7-P mục 5 (K7: `k7Table` có cột chọn), mục 6, mục 13 (chữ mới), mục 14 (BJ-03).
5. `python3 tools/sync-registry.py` (sửa `data/workbench-data.js` nếu còn `SCR-017` trong `screen_ids`).

## 6. Không làm

- Sửa nguồn mua / giải quyết mâu thuẫn giá (Theme 10).
- Xác lập một phần số lượng do người dùng tự chia (BR-02 cấm); ca căn cứ bao phủ một phần (AF-C) giữ logic, không thêm fixture.
- Thiết kế lại BJ-14 (chặng 6) — "Cập nhật giá vốn" mở màn hiện có.
- Gộp `VAL_UI_430` / `VAL_UI_461` (BJ-13 / BJ-14 còn dùng) — xem plan BJ-13.

## 7. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| Đổi fixture R1 làm số của BJ-13 (4.085.000 đ) lệch | Plan BJ-13 mục 3.1 đổi theo (9.885.700 đ); trong lúc chờ, golden BJ-13 khác được ghi ở mục 8 |
| Xoá khối v430 kéo theo 014 / BJ-13 | Chỉ xoá phần 015 / 016 / 017 / 019; `grep` `VAL_UI_430` trước và sau |
| `val03OpenForReceipt` đọc biến của BJ-02 khi BJ-02 chưa chạy | Chỉ đọc qua `typeof bj02LastCommitted !== "undefined"`; không có thì dùng fixture tĩnh (đã khớp) |
| Bảng có ô tick trên iPhone vỡ | `k7Table` trả cả bảng và thẻ; thẻ có `VCheckbox` đầu thẻ, chạm cả thẻ để tick |

## 8. Ghi chú khi làm

(Điền khi làm.)

## 9. Chữ trên màn

| Vị trí | Chữ |
|---|---|
| Hub | "Hàng chờ xác lập giá trị" · "Ghi giá nhập cho hàng đã nhận" |
| 014 | chip "Tất cả" · "Có thể xác lập" · "Cần xử lý" · "{n} sản phẩm chờ" · cột "Phiếu nhận", "Nhà cung cấp", "Cách nhận", "Ngày nhận", "Sản phẩm chờ", "Chờ", "Tình trạng" · "{n} ngày" · "Không còn hàng chờ giá trị" · "Các phiếu nhận đã được xác lập giá trị." |
| 015 | cột "Sản phẩm", "Số lượng", "Đơn giá", "Thành tiền", "Tình trạng" · "Căn cứ: {nhãn}" · "Cách tính" · "{nguồn 1} {giá 1} · {nguồn 2} {giá 2}" · "Thống nhất giá ở Mua hàng rồi quay lại." · "Chứng từ mua chưa có giá cho dòng này." · "Nhập giá" · "Chưa có chứng từ mua — nhập giá theo hoá đơn hoặc báo giá của nhà cung cấp." · "Quy đổi từ USD theo tỷ giá kế toán" · "Đã chọn {n} sản phẩm · {tổng}" · "Ghi giá trị ({n})" · "Chọn ít nhất một sản phẩm đủ căn cứ" · "Tóm tắt" |
| Sheet căn cứ | "đ/{ĐVT}" · "Giá vốn hiện tại: {giá} đ/{ĐVT}" |
| Sheet xác nhận | "Ghi giá trị nhập ban đầu?" · "{tên}: {SL} {ĐVT} × {đơn giá} = {thành tiền}" · "Ghi xong không sửa trực tiếp. Chi phí phát sinh sau dùng điều chỉnh giá trị." · "Quay lại" · "Xác nhận giá trị" |
| 015 khoá | "Phiếu này đã được xác lập giá trị" · "Chi phí phát sinh sau dùng điều chỉnh giá trị." |
| 019 | "Còn chờ giá trị" · "{n} sản phẩm" · "Cập nhật giá vốn" |
| Không có quyền | "Bạn chưa có quyền xác lập giá trị" · "Chỉ chủ cửa hàng xem và ghi giá nhập." |

## 10. Review

(Phiên review điền.)
