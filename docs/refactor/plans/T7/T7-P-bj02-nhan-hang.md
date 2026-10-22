# T7-P · BJ-02 Nhận hàng mua — thiết kế lại (bước B–E)

> Theme: Theme 7 Inventory · Trạng thái: Brief ✅ (duyệt 2026-10-21 — mục 0.10) | Plan C–E ✅ (viết cùng brief) | Làm ⬜ | Review ⬜
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) mục 8.2 **chặng 2 "Nhập hàng"**, BJ đầu tiên của chặng. Làm **sau khi chặng 1 xong hẳn** (R5 `/impeccable audit` và commit của [CAP-01](T7-P-cap01-chinh-sach-ton.md#10-review)). Sau BJ-02 là [BJ-03](T7-P-bj03-gia-nhap.md) rồi [BJ-13](T7-P-bj13-dieu-chinh-gia-tri.md) (hết chặng, `SC_journey_2`).
> Dùng lại K1–K4, K7 (dựng ở BJ-12), không dựng khuôn mới. Kèm **bước C0 — fixture chung của chặng 2** (mục 3): BJ-03, BJ-13 đọc lại cùng sản phẩm, cùng phiếu nhận.
> Thiết bị chính: **iPhone** cho lập phiếu (007, 008, 009, 084, 010); **web** cho duyệt và kết quả (011, 012, 013) — T7-P mục 2.
> Ước lượng: **~2,75 ngày, 3 commit** (C0 + C1 fixture và lập phiếu; C2 duyệt, kết quả, Hub, BJ-01; E tài liệu). Người làm: bạn. Review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị, chép nguyên văn; **(mới)** = chữ mới, vào T7-P mục 13 ở bước E.

## 0. Brief (bước B, đã duyệt 2026-10-21)

### 0.1 Việc thật

- **Nhân viên, vài lần / tuần:** nhà cung cấp giao hàng tới. Nhân viên đứng ở kho, cầm iPhone: đối chiếu phiếu giao với chứng từ mua, đếm, đọc mã lô và hạn dùng trên bao bì, tách ngay hàng hỏng / cần cách ly / trả lại tài xế. Thường 2–10 mặt hàng một lần; **đa số nhận đủ, không lỗi**.
- **Hàng đến chưa có chứng từ mua** (Owner mua miệng, NCC giao bù): nhân viên vẫn nhận được bằng nhập hàng nhanh, chụp phiếu giao làm bằng chứng; luôn cần Owner duyệt.
- **Owner:** duyệt khi nhận vượt chứng từ hoặc nhập nhanh, thường trên máy tính cuối buổi; Owner tự nhận thì ghi nhận luôn (T7-P mục 2). Nhận xong hàng vào tồn vật lý ngay nhưng **chưa có giá** → Owner xác lập giá (BJ-03).
- **Quy tắc giữ** (BJ-02, UC-02-01…05): một NCC mỗi phiếu nhận; nhận thiếu hợp lệ, phần còn lại nhận lần sau theo `remaining_receivable_qty`; **cần duyệt** khi Đạt + Cách ly + Hỏng (quy về ĐVT gốc) vượt lượng còn được nhận; **nhập nhanh luôn cần duyệt**; người duyệt = `is_owner` / `store_owner`, khác người lập — trừ `is_owner` tự lập thì tự duyệt; từ chối bắt buộc lý do; "Từ chối" (trả lại tại chỗ) không vào tồn; nhập nhanh không có bản nháp, gửi hợp lệ mới tạo phiếu; nhập nhanh bắt buộc xác nhận quyền sở hữu + chứng từ giao nhận; hệ thống tự ghi nhận khi đủ điều kiện, **không có nút ghi lại**; chưa rõ kết quả không làm lại — phục hồi ngắn rồi chuyển BJ-17.

### 0.2 Luồng hiện tại

Ảnh (`tools/.golden-chang1/`): `UIF-02_SCR-006_READY_document`, `UIF-02_SCR-009_READY_document`, `SC_bj02_lot_2_line`, `UIF-02_SCR-010_READY_document`, `UIF-02_SCR-012_COMPLETED_document`; web `tools/.golden-chang1-web/UIF-02_SCR-011_APPROVAL_REQUIRED_document@web`.

```text
Home "Nhận hàng" → 006 Chọn cách nhận ─"Nhận theo chứng từ"→ 007 Chứng từ chờ nhận → 009 Hàng thực nhận
  → 084 Chi tiết dòng (mỗi ô số mở một bàn phím số) ─"Xong"→ 009 ─"Rà soát"→ 010
  → không vượt: "Xác nhận nhận hàng" → 012 (PROCESSING → kết quả) ─"Xong"→ 006
  → vượt: "Gửi phê duyệt" → 010 PENDING_APPROVAL; người duyệt: Home "Chờ duyệt" → danh sách → 011 ─"Duyệt"→ 012
006 ─"Nhập hàng nhanh"→ 008 Thông tin nhập nhanh → 009 (ô tìm sản phẩm) → 084 → 010 "Gửi phê duyệt"
012 UNKNOWN (vòng quay + nút "Xác minh kết quả") → 013 Đối soát → "Xem hỗ trợ xử lý" → BJ-17
```

### 0.3 Vấn đề

| # | Màn | Vấn đề |
|---|---|---|
| 1 | 006 | Một màn chỉ để chọn hai đường, khác nhau bằng một dòng phụ; trường hợp hay gặp (có chứng từ) mất thêm một chạm |
| 2 | 007 | Chỉ tìm theo mã chứng từ / NCC, không theo sản phẩm; thẻ "2 mặt hàng đang chờ nhận" không nói hàng gì; không có lối sang nhập nhanh |
| 3 | 009 | Khối "Thông tin lần nhận" 4 dòng chiếm 1/3 màn; tiến độ "0/2 đã xử lý" chữ nhỏ ở góc; dòng hàng không có badge; "Rà soát" tắt không nói vì sao |
| 4 | 084 | Mỗi ô số (Đạt / Cách ly / Hỏng / Từ chối) mở một sheet bàn phím số riêng; nhận đủ vẫn phải gõ lại đúng số chứng từ; ô chọn "Cách ghi hạn dùng" đứng trước ô hạn dùng; màn dài, phần số lượng khuất dưới nút "Xong" |
| 5 | 008 | "Chọn hoặc kéo tệp" trên điện thoại, không có chụp ảnh; "Xác nhận quyền sở hữu" là banner, không có ô tick, nhưng "Xác nhận & tiếp tục" ngầm ghi xác nhận |
| 6 | 010 | Ngoại lệ (vượt chứng từ, hàng không đạt, chưa nhận) chỉ là badge trong từng dòng; lưới 5 ô thông tin đứng đầu; Owner tự nhận vượt chứng từ vẫn phải "Gửi phê duyệt" cho chính mình |
| 7 | 010 | `APPROVER_CONFIGURATION_MISSING` ("Chưa có người duyệt phù hợp") không còn xảy ra: người duyệt luôn là Owner (T7-P mục 2) |
| 8 | 011 | Không thấy lượng theo chứng từ cạnh thực nhận (T7-P mục 13, dòng "02 · SCR-011" ⬜); lý do cần duyệt là banner chung; web là cột điện thoại giữa màn; "Tổng giá trị rủi ro" tô cảnh báo cả khi chỉ vượt 1 hộp |
| 9 | 012 | Hoàn tất sơ sài: chỉ "Xong" về 006, không có bước tiếp (xác lập giá, nhận tiếp, xem tồn); lặp lại danh sách dòng của 010 |
| 10 | 012 UNKNOWN | Vừa vòng quay "Đang xác minh kết quả" vừa nút "Xác minh kết quả" — không rõ đang chờ hay phải bấm; 013 là màn thứ hai cho cùng việc |
| 11 | Hub | Dòng "Chờ duyệt" của nhận hàng không gắn vai người duyệt (`data-theme-entry-actor`), khác BJ-12 |
| 12 | Fixture | Sản phẩm BJ-02 / 03 / 13 lệch BJ-01 (mã NOB-DHPP / SP-00142 / SP-000184; "Amoxicillin LA" không có ở BJ-01); nhận xong tồn ở BJ-01 không đổi (ghi chú 11 review chặng 1) |
| 13 | BJ-01 | "Nhận hàng" ở chi tiết tồn mở thẳng nhập nhanh (008), bỏ qua chứng từ đang chờ có sản phẩm đó |
| 14 | Mã | `render009BJ02` thay chữ bằng `.replaceAll('sản phẩm','mặt hàng')`; `bj02ReviewProductBlocks` dựng HTML rồi sửa DOM (vá v471); cờ chết `lineClassificationExpanded` / `lotClassificationExpanded`; thuộc tính `data-v392-*`, `data-v350-action="bj02-*"` |

### 0.4 Đề xuất

**Luồng mới**

```text
Nhân viên (iPhone):
Home "Nhận hàng" ─→ 007 Nhận hàng: chứng từ chờ nhận + dòng "Hàng đến chưa có chứng từ"
   ├─ chứng từ ─→ 009 ─dòng→ 084 ("Nhận đủ 120 hộp" hoặc đếm) ─"Xong"→ 009 ─"Rà soát"→ 010
   │     không vượt: "Xác nhận nhận hàng" → 012
   │     vượt:       "Gửi phê duyệt" → 010 chờ duyệt (K2)
   └─ chưa có chứng từ ─→ 008 (NCC, chụp phiếu giao, ô tick sở hữu) ─→ 009 … ─→ 010 "Gửi phê duyệt"
Owner (web):    Home "Chờ duyệt" ─→ 011 Duyệt (K2 + K7) ─"Duyệt"→ 012 ─"Xác lập giá trị"→ BJ-03
Owner tự nhận:  010 "Ghi nhận nhận hàng" → sheet tự duyệt (K2) → 012
Chưa rõ:        012 → 013 Đối soát (phục hồi ngắn, khung K3) ─vẫn chưa rõ→ "Chuyển sang xác minh" (BJ-17)
```

*SCR-006 → gộp vào SCR-007* (vấn đề 1)

1. Bỏ 006; `screenAliases["UIF-02"]["SCR-006"] = "SCR-007"`; bước E chuyển 006 vào `RETIRED.md` ("Gộp vào SCR-007", "Bỏ từ v5.8.0"). Link cũ mở 007 ở trạng thái mặc định (cách (b) của R4 chặng 1).

*SCR-007 Nhận hàng* (iPhone chính)

2. Tiêu đề **"Nhận hàng"** (chữ của 006). Ô tìm "Tìm chứng từ, nhà cung cấp hoặc sản phẩm" **(mới)** — tìm cả theo tên / mã sản phẩm trong chứng từ.
3. Thẻ chứng từ: mã · NCC · ngày; dòng hàng "Nobivac DHPPi, Oxytetracycline LA" (tối đa 2 tên + "+{n}" **(mới)**); badge "Đã nhận một phần" (giữ).
4. Cuối danh sách, và trong `EMPTY` / `FILTER_EMPTY`: dòng **"Hàng đến chưa có chứng từ" (mới)** + phụ "Nhập hàng nhanh · cần chủ cửa hàng duyệt" **(mới)** → 008. Ẩn khi không có quyền nhập nhanh; tắt kèm lý do khi `BJ02_CONTEXT.quickBlocker` (giữ cơ chế 006).
5. Web: `k7Table` (Chứng từ · Nhà cung cấp · Ngày · Mặt hàng · Tình trạng); dòng nhập nhanh thành nút phụ "Hàng đến chưa có chứng từ" trên đầu bảng.

*SCR-009 Hàng thực nhận*

6. Đầu màn **một** dòng ngữ cảnh: "PN-260816-04 · Minh Dũng" + phụ "Kho trung tâm · nhận 16/09/2026" (thay khối 4 dòng); nhập nhanh: "Nhập nhanh · {NCC}" + liên kết "Sửa" → 008.
7. Thanh tiến độ "Đã xử lý {a}/{b} mặt hàng" **(mới)** ngay dưới.
8. Ô tìm có nút quét mã (cách làm của BJ-01: nút `scan` trong `ds24Search`, sheet "Quét mã vạch" / "Đưa mã vạch vào khung" — chữ đã duyệt). Theo chứng từ: gõ / quét đúng một dòng → mở thẳng 084 của dòng đó; nhập nhanh: thay ô tìm sản phẩm hiện có (cùng hành vi thêm dòng).
9. Dòng hàng: tên · phụ "{SKU} · {ĐVT}" · bên phải số mono "{nhận} / {chứng từ}" + badge (chữ giữ của 010: "Đã xong", "Vượt chứng từ", "Nhận một phần", "Có cách ly", "Có hàng hỏng", "Có từ chối", "Chưa nhận"). Chưa xử lý: không badge, phụ "Còn chờ nhận {n} {ĐVT}" (giữ).
10. Chân "Rà soát"; khi tắt, dòng lý do ngay trên nút "Còn {n} mặt hàng chưa xử lý" **(mới)**.

*SCR-084 Chi tiết hàng thực nhận*

11. Đầu: sản phẩm + "Còn chờ nhận {n} {ĐVT}" (giữ). Theo chứng từ: nút phụ **"Nhận đủ {n} {ĐVT}" (mới)** điền Đạt = lượng còn chờ nhận (dòng không theo lô: điền thẳng; theo lô: điền vào lô đang mở). Người dùng vẫn phải bấm "Xong".
12. Số lượng: **"Đạt" là ô số lớn nhập thẳng** (bàn phím số của máy, `inputmode="numeric"`, hậu tố ĐVT); "Cách ly", "Hỏng", "Từ chối" là ba ô nhỏ trên một hàng dưới nhãn "Hàng không đạt" **(mới)** — vẫn luôn hiện (giữ quyết định v0.3.4). Bỏ sheet bàn phím số riêng (`bj02NumericPad…`, `VNumericKeypadSheet`) — chốt ở 0.10 c.
13. Hạn dùng: **một ô** nhận "30/11/2026", "11/2026" hoặc "2026", tự suy độ chính xác (vẫn lưu `expiryPrecision` = `DAY` / `MONTH` / `YEAR`); phụ "Ghi như trên bao bì: ngày/tháng/năm, tháng/năm hoặc năm" **(mới)**; lỗi tại ô "Hạn dùng chưa đúng dạng" **(mới)**. Bỏ hai ô chọn "Cách ghi hạn dùng" / "Cách ghi ngày sản xuất"; ngày sản xuất dùng cùng cách, vẫn sau "Thêm ngày sản xuất" (giữ).
14. Lô: lô đóng là một dòng gọn "{mã} · HSD {hạn} · {số} {ĐVT}"; một lô mở một lúc; "Thêm lô khác", cảnh báo trùng mã lô + "Mở lô đã có", "Xóa lô" (giữ).
15. Chân "Xong" (giữ); khi chưa hợp lệ, dòng lý do trên nút: "Nhập mã lô" **(mới)**, "Nhập hạn dùng" **(mới)**, "Nhập ít nhất một phân loại số lượng để tiếp tục." (giữ). "Chưa nhận lần này", "Xóa khỏi lần nhận" (giữ).

*SCR-008 Thông tin nhập hàng nhanh*

16. "Nhà cung cấp" (sheet chọn — giữ); "Kho nhận" và "Ngày nhận" gộp một dòng chỉ đọc "Kho trung tâm · 16/09/2026".
17. "Chứng từ giao nhận": iPhone hai nút **"Chụp ảnh" (mới)** | **"Chọn tệp" (mới)**; web dùng vùng kéo thả của BJ-12 ("Kéo tệp vào đây hoặc Chọn tệp"). Tệp đã chọn là danh sách có nút "Xoá" từng tệp. Prototype: "Chụp ảnh" thêm tệp mẫu "Anh-phieu-giao-1.jpg".
18. **Ô tick thật** "Tôi xác nhận hàng này thuộc sở hữu của cửa hàng" **(mới)** + phụ giữ "Hệ thống lưu người xác nhận, thời điểm và chứng từ giao nhận."; chỉ khi tick mới gọi `bj02MakeOwnershipAssertion()` (bỏ banner "Xác nhận quyền sở hữu").
19. Chân **"Tiếp tục" (mới, thay "Xác nhận & tiếp tục")**, tắt kèm dòng lý do ("Chọn nhà cung cấp trong danh sách." giữ; "Thêm chứng từ giao nhận" **(mới)**; "Tick xác nhận quyền sở hữu" **(mới)**).

*SCR-010 Rà soát nhận hàng*

20. Thứ tự: (1) **"Cần chú ý"** (chữ của K2) chỉ khi có ngoại lệ — "Vượt chứng từ: {tên} {b} / {a} {ĐVT} (+{c})" **(mới)**, "Hàng không đạt: {tên} {n} cách ly · {m} hỏng" **(mới)**, "Chưa nhận lần này: {tên}" (chữ giữ), "Nhập nhanh: chưa có chứng từ mua" **(mới)**; (2) danh sách dòng như 009, chỉ đọc, chạm mở sheet chi tiết (giữ); (3) "Thông tin lần nhận" gọn một dòng như 009 + "Đổi chứng từ" / "Sửa" (giữ).
21. Nút chính theo trường hợp:

| Trường hợp | Nút | Sau khi bấm |
|---|---|---|
| Không cần duyệt | "Xác nhận nhận hàng" (giữ) | 012 PROCESSING → kết quả |
| Cần duyệt, người lập không phải `is_owner` | "Gửi phê duyệt" (giữ) | 010 `PENDING_APPROVAL` = `k2Pending({ approver:"chủ cửa hàng", … })` + "Về Kho" |
| Cần duyệt, `is_owner` lập | **"Ghi nhận nhận hàng" (mới)** | `k2SelfCommitSheet`: "Ghi nhận nhận hàng?" **(mới)**; số liệu Chứng từ · Mặt hàng · "Vượt chứng từ" / "Nhập nhanh"; cảnh báo "Bạn là chủ cửa hàng nên hàng vào kho ngay, không qua duyệt." **(mới)**; "Huỷ" \| "Ghi nhận" → 012 |

22. Bỏ `APPROVER_CONFIGURATION_MISSING` (vấn đề 7) và `FINANCIAL_MASKED` (010 không có số tiền) — alias về `READY`; ghi ở SCR-010 bước E.
23. **`REJECTED` (mới, phía người lập):** banner lỗi "Yêu cầu bị từ chối" **(mới)** + "{người} · {lúc}" + "Lý do" (chữ BJ-12); nút "Nhận lại" **(mới)** → 007 (nhập nhanh không có nháp nên nhập lại; theo chứng từ thì lượng còn chờ nhận vẫn như cũ).

*SCR-011 Phê duyệt yêu cầu nhận hàng* (web chính, K2 + K7)

24. `k7Split`: **trái** `k2Decision({ question:"Duyệt nhận hàng {chứng từ} của {NCC}?" (mới) — nhập nhanh: "Duyệt nhập hàng nhanh của {NCC}?" (mới), maker, sentAt, attention, facts })` — `attention`: từng dòng vượt "{tên}: chứng từ {a} · thực nhận {b} {ĐVT} (+{c})" (**áp T7-P mục 13 dòng 02 · SCR-011**), "Nhập nhanh — chưa có chứng từ mua" (`info`), hàng không đạt (`info`); `facts`: Nhà cung cấp · Kho nhận · Ngày nhận · "Tổng giá trị rủi ro" (chỉ Owner thấy số; tone thường); nút "Xem chứng từ giao nhận" (giữ). **Phải** `k7Table`: Sản phẩm · Lô / HSD · Theo chứng từ · Thực nhận · Chênh lệch · Tình trạng; iPhone thành danh sách thẻ.
25. Chân "Từ chối" | "Duyệt" (giữ). "Từ chối" dùng `k2RejectSheet` (thay sheet riêng của BJ-02; chữ giữ "Từ chối yêu cầu", "Lý do từ chối", "Xác nhận từ chối").
26. Từ chối xong: `k4Result({ kind:"warning", title:"Đã từ chối nhận hàng" (mới), facts:[Lý do, Người gửi], next:[{ label:"Về danh sách", primary }] })` → Hub danh sách chờ duyệt. `APPROVAL_ALREADY_DECIDED` → `k1Locked`; `SELF_APPROVAL_NOT_ALLOWED` chỉ khi người lập không phải `is_owner` tự mở phiếu của mình (chữ giữ "Không được tự phê duyệt").

*SCR-012 Kết quả nhận hàng* (K4)

27. `COMPLETED` và `VALUATION_PENDING_RESULT` cùng một bố cục: `k4Result({ title:"Đã ghi nhận hàng", description:"Đã tăng tồn vật lý theo {n} dòng hàng được xử lý." })` (giữ chữ); `facts`: Phiếu nhận · Chứng từ (hoặc "Nhập nhanh") · Nhà cung cấp · Người nhận · Người duyệt (nếu có; Owner tự nhận: "Chủ cửa hàng (tự duyệt)" — chữ BJ-12) · "Vào tồn" "{n} mặt hàng · {m} lô" **(mới)** · Owner thêm "Giá trị" "Chờ xác lập" **(mới, thay banner "Đang chờ xác nhận giá")**. Không lặp danh sách; liên kết "Xem {n} dòng hàng" **(mới)** mở sheet chi tiết.
28. Bước tiếp: **Owner** (vai `owner` hoặc `approver` — người duyệt luôn là Owner) phụ "Nhận tiếp" **(mới)** | chính **"Xác lập giá trị" (mới)** → BJ-03 SCR-015 của đúng phiếu (`val03OpenForReceipt`, plan BJ-03). **Nhân viên** phụ "Xem tồn kho" (chữ BJ-12) | chính "Nhận tiếp".
29. `PROCESSING` (giữ). `REJECTED_EXECUTION` → K4 cảnh báo "Chưa ghi nhận hàng" + "Yêu cầu bị chặn trước khi tồn kho thay đổi." (giữ) + "Quay lại rà soát" **(mới)**. `UNKNOWN` / `COMMIT_UNKNOWN` → alias sang 013 `PROCESSING_OR_UNKNOWN` (vấn đề 10; chốt 0.10 e).

*SCR-013 Đối soát nhận hàng* (phục hồi ngắn UC-02-05, khung K3)

30. Thân theo K3: "Kết quả chưa xác định" + số liệu Nghiệp vụ "Nhận hàng" · Phạm vi "{chứng từ} · {n} dòng" · Mã tham chiếu `REC-…` · Thời điểm gửi; **giữ** dòng thời gian bằng chứng (4 mốc, chữ giữ) và "Lần kiểm tra gần nhất". `PROCESSING_OR_UNKNOWN`: "Làm mới" (giữ); `TERMINAL` → về 012 (giữ "Đã xác lập kết quả"). Chân K3 "Về Kho" | "Chuyển sang xác minh" (thay "Xem hỗ trợ xử lý") → BJ-17.

*Hub (Home Kho) và BJ-01*

31. Quick action "Nhận hàng" và Quản lý kho → Nhập, xuất & hoàn trả → "Nhận hàng" mở 007.
32. Dòng "Chờ duyệt" của nhận hàng (`hub.js`, `PENDING_RECEIPTS`) gắn `data-theme-entry-actor="approver"` như BJ-12; dòng đầu là phiếu của fixture 011 (Minh Dũng · Nguyễn Văn An gửi 09:41); hai dòng còn lại mở cùng fixture (prototype, ghi chú UIF-02).
33. BJ-01 SCR-003 "Nhận hàng" → 007 với ô tìm điền sẵn tên sản phẩm (thay mở thẳng 008, vấn đề 13).
34. Ghi nhận xong (012 kết quả): cộng lượng vào `bj01Products` của sản phẩm cùng mã — Đạt vào khả dụng; Đạt + Cách ly + Hỏng vào tồn vật lý; `latestPhysicalMovement = { label:"Nhận hàng", source: chứng từ / mã phiếu, delta }` → "Xem tồn kho" thấy số mới.

*Fixture chung chặng 2* (C0, vấn đề 12) — chi tiết ở mục 3.

### 0.5 Trạng thái (sau thiết kế lại)

| Màn | Trạng thái | Hiện gì | Làm được gì | Lối ra |
|---|---|---|---|---|
| 007 | READY / PARTIAL_RECEIPT | chứng từ chờ nhận + dòng nhập nhanh | mở chứng từ, "Hàng đến chưa có chứng từ" | Về Kho |
| 007 | EMPTY / FILTER_EMPTY | `k1Empty` + dòng nhập nhanh | nhập nhanh / xoá tìm | Về Kho |
| 007 | SOURCE_VERSION_STALE | `k1Stale` "Tải lại" | "Tải lại" | Về Kho |
| 007, 008, 009, 084, 010, 011, 012, 013 | PERMISSION_DENIED | `k1Denied` | — | "Về Kho" |
| 007, 013 | LOADING | `k1Loading` | — | — |
| 007, 008, 009 | LOCKED / READ_ONLY | `k1Locked` + dữ liệu chỉ đọc | — | Quay lại |
| 008, 009 | CONFLICT | `k1Stale` | "Tải lại" | Quay lại |
| 008 | READY / VALIDATION_ERROR | biểu mẫu; lỗi tại ô | "Tiếp tục" | Quay lại |
| 009 | READY / VALIDATION_ERROR / EMPTY | ngữ cảnh + tiến độ + dòng | mở dòng, quét, "Rà soát" | Quay lại |
| 084 | READY / VALIDATION_ERROR | sản phẩm, lô, số lượng | "Nhận đủ", "Xong", "Chưa nhận lần này" | Quay lại |
| 084 | DUPLICATE_LINE / LOT_CONFLICT | cảnh báo + "Mở … đã có" (giữ) | mở dòng / lô đã có | Quay lại |
| 010 | READY / APPROVAL_REQUIRED | Cần chú ý + dòng + thông tin | nút theo bảng mục 21 | Quay lại |
| 010 | PENDING_APPROVAL | `k2Pending` | — | Về Kho |
| 010 | REJECTED **(mới)** | lý do + người từ chối | "Nhận lại" | Về Kho |
| 011 | READY / APPROVAL_REQUIRED | `k2Decision` + bảng | "Duyệt", "Từ chối" | về danh sách chờ duyệt |
| 011 | APPROVAL_ALREADY_DECIDED / SELF_APPROVAL_NOT_ALLOWED / VALIDATION_ERROR | `k1Locked` / banner giữ | — | "Về danh sách" |
| 011 | FINANCIAL_MASKED | như READY, "Tổng giá trị rủi ro" = "Không có quyền xem" (giữ) | "Duyệt", "Từ chối" | về danh sách |
| 012 | PROCESSING | đang ghi nhận | — | — |
| 012 | COMPLETED / VALUATION_PENDING_RESULT | K4 | theo vai (mục 28) | Về Kho |
| 012 | REJECTED_EXECUTION | K4 cảnh báo | "Quay lại rà soát" | Về Kho |
| 013 | PROCESSING_OR_UNKNOWN / STALE / READY / EMPTY | K3 + dòng thời gian | "Làm mới", "Chuyển sang xác minh" | "Về Kho" |
| 013 | TERMINAL | "Đã xác lập kết quả" | tự về 012 | — |

Alias: 006 (mọi trạng thái) → 007 mặc định; 010 `APPROVER_CONFIGURATION_MISSING` / `FINANCIAL_MASKED` → 010 READY; 012 `UNKNOWN` / `COMMIT_UNKNOWN` → 013 `PROCESSING_OR_UNKNOWN`.

### 0.6 Khuôn dùng lại (không dựng mới)

K1 (`k1Loading`, `k1Denied`, `k1Stale`, `k1Locked`, `k1Empty`, `k1ExitAttr`), K2 (`k2Pending`, `k2Decision`, `k2RejectSheet`, `k2SelfCommitSheet`), K3 (`k3Unknown`), K4 (`k4Result`, `k4Footer`), K7 (`k7Split`, `k7Table`, lớp `k7-wide`). Một chỉnh nhỏ ở khuôn: `k3Unknown` nhận thêm `title` và `detail` (HTML chèn sau bảng số liệu) để 013 giữ tiêu đề "Đối soát nhận hàng" và dòng thời gian; bỏ trống thì như cũ (BJ-12 không đổi).

Thành phần mới (→ T7-P mục 6): thanh tiến độ mảnh (`VProgress` dạng thanh, nếu DS chưa có); ô hạn dùng tự hiểu độ chính xác (mở rộng `VTextField` ngày); `VFileDropZone` biến thể iPhone có "Chụp ảnh".

### 0.7 Không đổi

Quy tắc ở 0.1; cách tính `lineTotals`, `bj02RequiresApproval`, `receiptRiskValue`, `documentLineVariance`; sheet chọn NCC; cảnh báo trùng dòng / trùng lô; "Đổi chứng từ?" (giữ chữ). Chữ giữ: "Nhận hàng", "Hàng thực nhận", "Chi tiết hàng thực nhận", "Rà soát nhận hàng", "Phê duyệt yêu cầu nhận hàng", "Kết quả nhận hàng", "Đối soát nhận hàng", "Đạt", "Cách ly", "Hỏng", "Từ chối", "Mã lô", "Hạn dùng", "Thêm lô khác", "Tổng kiểm nhận", "Chưa nhận lần này", "Xác nhận nhận hàng", "Gửi phê duyệt", "Duyệt", "Từ chối", "Xem chứng từ giao nhận", "Tổng giá trị rủi ro", "Đã ghi nhận hàng", "Chưa ghi nhận hàng", "Làm mới".

### 0.8 Kiểm (bước D)

- Golden **mobile** được khác: `UIF-02_*` (ca `UIF-02_SCR-006_*` **mất**), `SC_bj02_*`, `SC_entry_UIF-02_*`, `SC_quick_UIF-02_*`, ca BJ-01 đi qua "Nhận hàng" (`SC_bj01_receive_*`), ca Hub / "Cần chú ý" mở chờ duyệt nhận hàng (`SC_attention_*`, `SC_ws_*` có UIF-02). Mọi ca khác khớp mốc `tools/.golden-chang1`.
- Golden **web** được khác: `UIF-02_*@web` và kịch bản web mới; ca khác khớp `tools/.golden-chang1-web`.
- Kịch bản mới (mục 5.6): `SC_bj02_doc_full`, `SC_bj02_over_staff`, `SC_bj02_owner_self`, `SC_bj02_approve`, `SC_bj02_reject`, `SC_bj02_quick`, `SC_bj02_scan`, `SC_bj02_unknown`, `SC_bj02_from_bj01`.

### 0.9 Ước lượng C–E

~2,75 ngày: C0 fixture ~0,25; C1 lập phiếu (007 / 008 / 009 / 084 / 010) ~1; C2 duyệt / kết quả / 013 / Hub / BJ-01 ~0,75; D ~0,25; E ~0,5.

### 0.10 Đã chốt khi duyệt brief (2026-10-21): **mọi điểm theo cột "Đề xuất"**

| # | Điểm | Đề xuất | Phương án khác |
|---|---|---|---|
| a | Màn chọn cách nhận 006 | **Gộp vào 007**: danh sách chứng từ + dòng "Hàng đến chưa có chứng từ" | Giữ 006, chỉ làm rõ chữ hai lựa chọn |
| b | Nút "Nhận đủ {n} {ĐVT}" ở 084 | **Thêm** (chỉ theo chứng từ; vẫn phải bấm "Xong"; rà soát vẫn hiện lại số) | Không thêm — buộc gõ số đã đếm để tránh nhận khống |
| c | Bàn phím số riêng ở 084 | **Bỏ**, ô số nhập thẳng bằng bàn phím số của máy | Giữ `VNumericKeypadSheet` cho cả 4 ô |
| d | Ô chọn "Cách ghi hạn dùng" | **Bỏ**, một ô tự hiểu ngày/tháng/năm, tháng/năm, năm | Giữ ô chọn |
| e | 012 chưa rõ kết quả | **Gộp vào 013** (một màn phục hồi ngắn) | Giữ 012 UNKNOWN riêng, chỉ bỏ vòng quay |
| f | `APPROVER_CONFIGURATION_MISSING` ở 010 | **Bỏ** (người duyệt luôn là Owner) | Giữ cho trường hợp tenant chưa có Owner |
| g | Người lập bị từ chối | **Thêm 010 `REJECTED`** + "Nhận lại" | Chỉ người duyệt thấy kết quả từ chối |

---

## 1. Mục tiêu

1. Nhân viên nhận một chứng từ bình thường (không lỗi) trên iPhone với ít chạm nhất: Home → chứng từ → mỗi dòng "Nhận đủ" + lô / HSD → "Rà soát" → "Xác nhận nhận hàng".
2. Ngoại lệ (vượt, không đạt, chưa nhận) nổi lên đầu ở rà soát và ở màn duyệt; Owner duyệt trên web thấy chứng từ cạnh thực nhận.
3. Owner tự nhận không phải duyệt cho chính mình; kết quả dẫn thẳng sang xác lập giá (BJ-03).
4. Một bộ sản phẩm / phiếu nhận chung cho cả chặng 2, khớp BJ-01.

## 2. Chuẩn bị

1. Chặng 1 đã commit (gồm R5 audit). Máy chủ `python3 -m http.server 8765 --bind 127.0.0.1 &` trong `html/`.
2. Mốc = `tools/.golden-chang1` (mobile) và `tools/.golden-chang1-web` (web). Nếu R5 có sửa thì đó là mốc đã chụp lại sau R5; chạy `node tools/golden.mjs compare` với HEAD trước khi sửa, phải "Khớp hoàn toàn".
3. Đọc lại `app/bj02.js` (1464 dòng) và khối CSS của BJ-02 (`.bj02-*`, `[data-active-uif="UIF-02"]`, `v392` / `v470` / `v471`) trong `styles/screens.css` + `styles/components.css` trước khi sửa.

## 3. Bước C0 — fixture chung chặng 2 (commit 1, cùng C1)

Mục đích: BJ-01 → BJ-02 → BJ-03 → BJ-13 nói về **cùng** sản phẩm và **cùng** phiếu nhận, để `SC_journey_2` đọc được như một câu chuyện.

| Fixture | Hiện tại | Sau C0 |
|---|---|---|
| `quickProductCatalog` (`bj02.js`) | Nobivac (NOB-DHPP), Amoxicillin LA (AMX-LA), Găng tay (GLOVE-N) | **Nobivac DHPPi** (`sku` = mã BJ-01 `SP-000184`, mã vạch `8938500001012`, ĐVT hộp / lọ, theo lô, bắt buộc HSD) · **Oxytetracycline LA** (`SP-000147`, mã vạch `8938500007144`, chai, không theo lô, không HSD; giá cơ sở 120.000 đ/chai) · Găng tay khám Nitrile (giữ, không có ở BJ-01) |
| `documentReceiptCatalog["PN-260816-04"]` | Nobivac 120 hộp + Amoxicillin LA 24 chai (theo lô) | Nobivac 120 hộp + **Oxytetracycline LA 24 chai (không theo lô)** — một dòng có lô, một dòng không lô |
| `PN-260816-05` | Găng tay 34 hộp, nhận một phần | giữ |
| Thêm `productRef` vào mỗi sản phẩm | — | `bj01Id` = `"INV-NOB"` / `"INV-OXY"` / `null` để cộng tồn (mục 4.8) |

- Oxytetracycline LA là sản phẩm chặng 1 vừa đặt ngưỡng (26 ≤ 30 → "Tồn thấp"); nhận 24 chai → khả dụng 50 → hết "Tồn thấp". Nobivac 121 hộp (vượt +1) giữ làm ca cần duyệt.
- Tên "Amoxicillin LA" biến khỏi BJ-02; BJ-03 / BJ-13 đổi theo ở plan của chúng (ghi ở đầu `bj02.js`: "Fixture chung chặng 2 — BJ-03 / BJ-13 đọc cùng tên, mã").
- `grep -n "Amoxicillin\|AMX-LA\|NOB-DHPP" app/*.js tools/golden.mjs` trước khi đổi; selector golden dùng `data-*` nên ít chỗ phải sửa.

## 4. Bước C1 — lập phiếu (commit 1)

### 4.1 Dữ liệu và trạng thái (`app/bj02.js`)

1. Xoá `render006BJ02`; `Object.assign(screenAliases, { "UIF-02": { ...(screenAliases["UIF-02"]||{}), "SCR-006":"SCR-007" } })` (xem cách BJ-03 khai alias ở `bj03.js:260`). `entryTargets["UIF-02"]` (`core.js:75`): thêm `owner: { screen:"SCR-007" }`; mọi chỗ `navigate("SCR-006")` → `"SCR-007"` (`exit-flow`, `onPrevious`, Hub).
2. Vai: `const bj02IsOwner = () => currentActor() === "owner";` (như `cf12IsOwner`). Mặc định `module` = nhân viên lập.
3. Xoá cờ chết `lineClassificationExpanded`, `lotClassificationExpanded`; bỏ `bj02NumericPad`, `openBj02NumericPad`, `updateBj02NumericPad`, `closeBj02NumericPad`, `saveBj02NumericPad`, `bj02NumericKeypadOverlay` và listener của chúng (nếu 0.10 c = bỏ).
4. `bj02ExpiryParse(text)` → `{ precision:"DAY"|"MONTH"|"YEAR", valid }` thay `bj02ValidPrecisionValue(value, precision)`; khi lưu lô ghi `expiryPrecision` / `manufacturePrecision` theo kết quả.
5. Đổi thuộc tính: `data-v392-*` → `data-bj02-*` (`quick-continue`, `change-source`, `cancel-source-change`, `confirm-source-change`, `open-evidence`, `close-evidence`, `preview-file`, `lot-precision` bỏ); `data-v350-action="bj02-verify-unknown"` / `"bj02-handoff-unknown"` → `data-bj02-action="…"`. Sửa selector trong `tools/golden.mjs` cùng lúc.

### 4.2 Màn

| Màn | Việc |
|---|---|
| 007 | `appShell({ title:"Nhận hàng", back:false })`; ô tìm `ds24Search(documentSearchQuery, 'data-bj02-document-search', 'Tìm chứng từ, nhà cung cấp hoặc sản phẩm')`; `data-bj02-document-search-text` gồm mã + NCC + tên + SKU các dòng; thẻ chứng từ (`bj02RecordCard` giữ) với dòng hàng ≤ 2 tên + "+{n}"; dòng nhập nhanh `ds24ListRow({ title:"Hàng đến chưa có chứng từ", subtitle:"Nhập hàng nhanh · cần chủ cửa hàng duyệt", leading:"zap", attrs:'data-flow="quick"' })` cuối danh sách (cả khi EMPTY / FILTER_EMPTY); web: `k7Table` cột ở 0.4 mục 5, `mobileRow` = thẻ hiện có; `EMPTY` / `FILTER_EMPTY` dùng `k1Empty`; `SOURCE_VERSION_STALE` dùng `k1Stale` |
| 009 | Bỏ `.replaceAll(…)` — viết thẳng "mặt hàng". `bj02ReceiptContext()` → một dòng `ds24ListRow` Status (title "{chứng từ} · {NCC}" / "Nhập nhanh · {NCC}", subtitle "Kho trung tâm · nhận {ngày}", trailing liên kết "Sửa" khi nhập nhanh); thanh tiến độ `<div class="bj02-progress" role="progressbar" aria-valuenow="{a}" aria-valuemax="{b}">` + nhãn "Đã xử lý {a}/{b} mặt hàng"; ô tìm + nút quét (`data-bj02-scan`, sheet theo `bj01ScanSheet`, nút mẫu "Quét thử: Oxytetracycline LA"); dòng hàng = `ds24ListRow` có cột phải số mono + `vBadge` (dùng `bj02ReviewIssue` cho badge); chân `primaryFooter("Rà soát", 'data-next="SCR-010"', disabled)` + dòng lý do |
| 084 | Đầu: `ds24ContextStatusRow` giữ; nút phụ "Nhận đủ {n} {ĐVT}" `data-bj02-action="fill-remaining"`; ô Đạt `cfField`-kiểu số lớn (`data-bj02-qty="accepted"`, hậu tố ĐVT, `inputmode="numeric"`), hàng ba ô nhỏ (`data-bj02-qty="quarantine"/"damaged"/"rejected"`) dưới nhãn "Hàng không đạt"; ô HSD một ô (`data-bj02-lot-field="expiry"`), lỗi tại ô; lô đóng = một dòng gọn; chân "Xong" + dòng lý do (`lineEditorInvalidReason()` trả câu đầu tiên còn thiếu) |
| 008 | NCC giữ sheet; một dòng chỉ đọc kho · ngày; chứng từ: iPhone hai nút `data-bj02-evidence-camera` ("Chụp ảnh", thêm tệp mẫu) / `data-bj02-evidence-file` ("Chọn tệp"); web vùng kéo thả (`cf12`-kiểu, `.device-preview.is-web`); danh sách tệp + "Xoá" (`data-bj02-evidence-remove="{id}"`); ô tick `data-bj02-ownership` (`role="checkbox"`, `aria-checked`); chân "Tiếp tục" `data-bj02-quick-continue` + dòng lý do |
| 010 | Khối "Cần chú ý" (dựng như `k2Decision` phần attention — tách hàm `k2Attention(rows)` ra `shared-patterns.js` và cho `k2Decision` gọi lại, kết quả HTML của BJ-12 không đổi); danh sách dòng = cùng hàm dòng của 009 ở chế độ chỉ đọc (`data-bj02-review-line` mở sheet giữ); thông tin một dòng + "Đổi chứng từ" / "Sửa"; chân theo bảng 0.4 mục 21 (`data-action="submit"` / `data-bj02-action="open-self"`); sheet tự duyệt `k2SelfCommitSheet({ open:bj02SelfOpen, … confirmAttr:'data-bj02-action="confirm-self"', closeAttr:'data-bj02-action="close-self"' })`; `PENDING_APPROVAL` → `k2Pending` + `k4Footer([{ label:"Về Kho", attr:k1ExitAttr("SCR-007") }])`; `REJECTED` mới |

### 4.3 Sự kiện

1. `fill-remaining` → `lineEditorDraft.accepted = remainingReceivableQty` (dòng không lô) hoặc vào lô đang mở; `lineEditorDirty = true`; `renderAppScreen()`.
2. `input` trên `data-bj02-qty` / `data-bj02-lot-field` → cập nhật nháp, render lại và **giữ con trỏ** (lưu `selectionStart` + `data-*` của ô, trả lại sau render — cách CAP-01 làm ở `cap01.js`).
3. Quét: `data-bj02-scan` mở sheet; nút mẫu chọn dòng có `productRef` tương ứng → `beginLineEditor(lineId)` (theo chứng từ) / `addQuickOverviewLine` (nhập nhanh).
4. `open-self` → `bj02SelfOpen = true`; `confirm-self` → đóng sheet, `bj02Approver = { name:"Chủ cửa hàng (tự duyệt)" }`, `startAutoExecution()`; Escape đóng sheet (như `bj12.js:253`).
5. `submit`: giữ nhánh hiện có; thêm: `bj02IsOwner() && bj02RequiresApproval()` → `open-self` thay vì gửi.
6. Ô tick sở hữu bật / tắt `bj02Header.ownershipAssertion` (tick = `bj02MakeOwnershipAssertion()`, bỏ tick = `null`).

## 5. Bước C2 — duyệt, kết quả, phục hồi, Hub, BJ-01 (commit 2)

### 5.1 SCR-011

`k7Split({ main: k2Decision({…}) + nút chứng từ, aside: k7Table({ columns:[…6 cột ở 0.4 mục 24], rows, mobileRow }) })` trong `appShell({ extraClass:"k7-wide", backAction:"exit-approval" })`. "Chênh lệch" = thực nhận − theo chứng từ (quy ĐVT dòng), dương tô cảnh báo; nhập nhanh: cột "Theo chứng từ" = "—". Từ chối: bỏ `openRejectSheet` / `closeRejectSheet` / `confirmReject` (chèn DOM) → biến `bj02RejectOpen`, `approvalRejectReason`; `k2RejectSheet({ open, title:"Từ chối yêu cầu", reason, reasonAttr:'data-bj02-reject-reason', confirmAttr:'data-bj02-action="confirm-reject"', closeAttr:'data-bj02-action="close-reject"' })`; xác nhận → `stateByScreen["SCR-011"]="REJECTED_DONE"` (trạng thái nội bộ, không vào bảng Screen Contract) dựng K4 0.4 mục 26 và đặt `stateByScreen["SCR-010"]="REJECTED"` cho phía người lập.

### 5.2 SCR-012

Bỏ hàm `resultHero` + danh sách; `k4Result` như 0.4 mục 27–28. `bj02Approver` (null / người duyệt / tự duyệt) và `BJ02_CONTEXT.submitted` cấp số liệu. Khi chuyển sang kết quả (một lần mỗi phiếu) đặt **`bj02LastCommitted = { ref: chứng từ (nhập nhanh: mã phiếu), mode: flowMode, lines: cloneBj02(bj02Lines) }`** — BJ-03 đọc biến này. Nút theo vai: `["owner","approver"].includes(currentActor())` → bộ nút Owner; còn lại → bộ nút nhân viên. "Xác lập giá trị" `data-bj02-action="go-valuation"` → `if (typeof val03OpenForReceipt === "function") return val03OpenForReceipt(bj02LastCommitted.ref);` — trước khi làm BJ-03, hàm chưa có: dùng `activeFlowId="UIF-03"; navigate("SCR-015")` qua `entryTargets["UIF-03"]["receipt-task"]` (plan BJ-03 thay). "Nhận tiếp" → `resetBj02Receipt("document"); navigate("SCR-007")`. "Xem tồn kho" → `activeFlowId="UIF-01"; navigate("SCR-001")` (cách BJ-12 `see-inventory`). "Xem {n} dòng hàng" mở `bj02ReviewDetailSheet` dạng danh sách.

### 5.3 SCR-013

`k3Unknown({ title:"Đối soát nhận hàng", operation:"Nhận hàng", scope:"{chứng từ} · {n} dòng", ref:BJ02_CONTEXT.submitted.receiptRef, sentAt:BJ02_CONTEXT.submitted.submittedAt, sourceFlow:"UIF-02", exitAttr:k1ExitAttr("SCR-007"), detail: dòng thời gian + "Lần kiểm tra gần nhất" + "Làm mới" })`. Sửa `k3Unknown` (`shared-patterns.js:91`) nhận `title = "Xác minh kết quả"` và `detail = ""` mặc định. Bỏ listener `bj02-verify-unknown`; `bj02-handoff-unknown` thay bằng `handoff-unknown` chung của K3 (đã gọi `bj17HandoffUnknown`). Alias 012 UNKNOWN / COMMIT_UNKNOWN: trong `render012BJ02` gọi `stateByScreen["SCR-013"]="PROCESSING_OR_UNKNOWN"; return renderers["SCR-013"]("PROCESSING_OR_UNKNOWN")` hoặc đăng ký alias trạng thái nếu `screenAliases` hỗ trợ.

### 5.4 Hub (`app/hub.js`)

1. Quick action / dòng Quản lý kho UIF-02 không đổi thuộc tính; màn đích là 007 nhờ alias (kiểm `SC_ws_*`).
2. `PENDING_RECEIPTS[0]` = `{ id:'REC-260916-04', supplier:'Minh Dũng', meta:'Kho trung tâm · 2 mặt hàng · Nguyễn Văn An gửi 09:41' }`; `attrs` thêm `data-theme-entry-actor="approver"`.
3. Không chuyển nguồn chờ duyệt sang `bj02.js` (cần `inventoryActivated` trong IIFE của Hub) — ghi chú giữ ở đầu `bj02.js`.

### 5.5 BJ-01 (`app/bj01.js`, sửa nhỏ)

1. `[data-bj01-receive]` (`bj01.js:199`): `activeFlowId="UIF-02"; flowMode="document"; resetBj02Receipt("document"); documentSearchQuery = sản phẩm.name; activeScreenId="SCR-007"; stateByScreen["SCR-007"]="READY"; syncReviewUrl(); render();`.
2. Hàm `bj01ApplyReceipt(lines, ref)` (mới, ở `bj01.js`): với mỗi dòng có `productRef` → cộng `physical`, `eligible`, `available` như 0.4 mục 34, đặt `latestPhysicalMovement`. `bj02.js` gọi khi 012 chuyển sang kết quả (một lần mỗi phiếu: cờ `bj02AppliedRefs`).

### 5.6 Golden (`tools/golden.mjs`)

Sửa kịch bản `SC_bj02_*` hiện có theo selector mới (`SC_bj02_choose` bỏ — 006 không còn; `SC_bj02_quick` bắt đầu ở 007). Thêm (viết như `SC_bj01_*`, `R` = gốc UIF-02 hiện có):

| Kịch bản | Bắt đầu | Bước |
|---|---|---|
| `SC_bj02_doc_full` | `R + 'SCR-007'` | mở PN-260816-04 → Nobivac → mã lô "DH2507", HSD "30/11/2026" → "Nhận đủ 120 hộp" → "Xong" → Oxy → "Nhận đủ 24 chai" → "Xong" → "Rà soát" → "Xác nhận nhận hàng" → chờ hết PROCESSING → "Xem tồn kho" (thấy Oxytetracycline LA khả dụng 50, hết "Tồn thấp") |
| `SC_bj02_over_staff` | như trên | Nobivac Đạt 121 → … → 010 thấy "Cần chú ý · Vượt chứng từ" → "Gửi phê duyệt" → 010 chờ duyệt → "Về Kho" |
| `SC_bj02_owner_self` | `R + 'SCR-007&entry=owner'` | như `over_staff` đến 010 → "Ghi nhận nhận hàng" → sheet → "Ghi nhận" → 012 "Chủ cửa hàng (tự duyệt)" → "Xác lập giá trị" |
| `SC_bj02_approve` | Hub `T + 'inventory'` | "Cần chú ý · Chờ duyệt" → dòng Minh Dũng → 011 → "Duyệt" → 012 |
| `SC_bj02_reject` | `R + 'SCR-011'` | "Từ chối" → gõ lý do → "Xác nhận từ chối" → K4 "Đã từ chối nhận hàng" |
| `SC_bj02_quick` | `R + 'SCR-007'` | "Hàng đến chưa có chứng từ" → chọn NCC → "Chụp ảnh" → tick sở hữu → "Tiếp tục" → thêm Găng tay → 084 Đạt 10 → "Xong" → "Rà soát" → "Gửi phê duyệt" |
| `SC_bj02_scan` | `R + 'SCR-009&flow=document'` | nút quét → "Quét thử: Oxytetracycline LA" → 084 của Oxy |
| `SC_bj02_unknown` | `R + 'SCR-012&state=UNKNOWN'` | thấy 013 K3 → "Làm mới" → "Chuyển sang xác minh" |
| `SC_bj02_from_bj01` | `?uif=UIF-01&screen=SCR-003` (sản phẩm Oxy) | "Nhận hàng" → 007, ô tìm "Oxytetracycline LA", còn PN-260816-04 |

`WEB_SCENARIOS` thêm `SC_bj02_approve`, `SC_bj02_reject`, `SC_bj02_owner_self` (màn web chính).

## 6. Bước D — kiểm

1. Golden mobile / web so mốc mục 2: chỉ ca ở 0.8 khác; ghi danh sách khác vào mục 10.
2. Bấm thử UIF-02 hai khung (mọi nút, sheet, Escape, quay lại) + Hub "Chờ duyệt" + BJ-01 "Nhận hàng": 0 lỗi JS. `node --check app/*.js harness/*.js`.
3. **`/impeccable audit` phạm vi UIF-02 — chặn commit E** (bài học R5 chặng 1). Máy chủ ở mục 2; chạy trên 007, 008, 009, 084 (lô mở + sheet quét), 010 (thường / chờ duyệt / sheet tự duyệt / REJECTED), 011, 012, 013, ở **cả hai khung** (`viewport=web`). Đạt khi: chữ ≥ 4,5:1 (chữ lớn / icon ≥ 3:1); vùng chạm ≥ 44 × 44 ở iPhone (ô số, ô tick, nút "Nhận đủ", nút quét); mọi nút icon, ô số và ô tick có `aria-label` / `role`; web đi được bằng bàn phím (Tab qua bảng và nút, Enter mở sheet, Esc đóng sheet, focus về nút đã mở). Lỗi trong phạm vi BJ-02 / `shared-patterns.js`: sửa ngay; ngoài phạm vi: ghi thành dòng ở mục 11.
4. Gửi ảnh: 007 iPhone + web, 009, 084 (có lô), 008, 010 (Cần chú ý), sheet tự duyệt, 011 web, 012 Owner và nhân viên, 013.
5. Mốc mới cho BJ-03: `tools/.golden-bj02-after`, `tools/.golden-bj02-web-after`.

## 7. Bước E — ghi lại (commit 3)

1. `CHANGELOG.md` `[5.8.0] — BJ-02 thiết kế lại; fixture chung chặng 2`; phiên bản 5.8.0 ở `manifest.json`, `harness/workbench.js` (`__VET45_PROTOTYPE__.version`), badge `index.html`.
2. Viết lại theo `_TEMPLATE.md`: SCR-007 (gồm lối nhập nhanh), 008, 009, 084, 010 (bảng nút theo vai; `REJECTED`; bỏ hai trạng thái), 011, 012, 013; SCR-006 → `RETIRED.md` ("Gộp vào SCR-007", v5.8.0), xoá file, sửa link (`grep -rn "SCR-006" specs/themes/theme-07`); UIF-02 (sơ đồ mới, lối vào từ Hub / BJ-01, lối ra sang BJ-03 / BJ-01 / BJ-17, ghi chú prototype: ba dòng chờ duyệt mở cùng fixture).
3. Sửa đặc tả theo T7-P mục 13 dòng "mọi BJ theo K2", phần BJ-02: UC-02-03 (người duyệt = `is_owner` / `store_owner`; `is_owner` lập thì tự duyệt), BJ-02 mục 2 ("người lập không tự duyệt" → trừ `is_owner`), SCR-011 mục quyền.
4. `INDEX.md` các dòng 006–013, 084; T7-P mục 6 (thành phần mới), mục 13 (chữ mới + đánh dấu dòng "02 · SCR-011" ✅ đã áp), mục 14 (BJ-02).
5. `python3 tools/sync-registry.py`; sửa nguồn `data/workbench-data.js` nếu còn `SCR-006` trong `screen_ids` rồi chạy lại.

## 8. Thứ tự commit

1. C0 + C1 (fixture chung, 007 / 008 / 009 / 084 / 010, golden lập phiếu) — golden chỉ khác UIF-02 lập phiếu + ca BJ-01 receive.
2. C2 + D (011 / 012 / 013, Hub, BJ-01 cộng tồn, golden còn lại, audit).
3. E (tài liệu, registry).

Trước mỗi commit: `detect_changes()` của GitNexus nếu công cụ có trong phiên (prototype HTML tĩnh không được lập chỉ mục — như H1 / chặng 1, ghi lại nếu không chạy được).

## 9. Không làm

- Chuyển nguồn "Chờ duyệt" của nhận hàng khỏi `hub.js` (mục 5.4); ba phiếu chờ duyệt khác nhau thật.
- Quét mã chứng từ / phiếu giao; nhận nhiều chứng từ một lần; in tem lô.
- Tối ưu web cho lập phiếu (chỉ cần không vỡ, đủ hành động).
- Sửa `PENDING_RECEIPTS` thành dữ liệu sinh từ phiếu đã gửi trong phiên.

## 10. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| Đổi Amoxicillin → Oxytetracycline làm vỡ ca golden BJ-03 / BJ-13 trước khi tới lượt | BJ-03 / BJ-13 giữ fixture riêng tới plan của chúng; C0 chỉ sửa fixture trong `bj02.js` |
| `bj01ApplyReceipt` làm golden BJ-01 khác khi chạy chung | Mỗi ca golden tải trang mới; chỉ `SC_bj02_doc_full`, `SC_journey_2` thấy số mới |
| Ô số nhập thẳng mất con trỏ khi render lại | Giữ `selectionStart` theo `data-*` sau render (CAP-01) |
| `k3Unknown` thêm tham số làm khác golden BJ-12 | Tham số mặc định giữ HTML cũ; so golden `UIF-12_*` phải khớp |
| Bỏ `VNumericKeypadSheet` lệch DS Flutter | Ghi ở SCR-084 mục thành phần: dùng `VNumberField` với bàn phím số hệ thống; DS không xoá component |

## 11. Ghi chú khi làm

(Điền khi làm: ca golden khác, lệch plan, chữ ngoài brief, kết quả audit.)

## 12. Chữ trên màn

| Vị trí | Chữ |
|---|---|
| 007 | "Nhận hàng" · "Tìm chứng từ, nhà cung cấp hoặc sản phẩm" · "+{n}" · "Hàng đến chưa có chứng từ" · "Nhập hàng nhanh · cần chủ cửa hàng duyệt" |
| 009 | "{chứng từ} · {NCC}" · "Nhập nhanh · {NCC}" · "Kho trung tâm · nhận {ngày}" · "Đã xử lý {a}/{b} mặt hàng" · "Còn {n} mặt hàng chưa xử lý" · "Quét thử: Oxytetracycline LA" |
| 084 | "Nhận đủ {n} {ĐVT}" · "Hàng không đạt" · "Ghi như trên bao bì: ngày/tháng/năm, tháng/năm hoặc năm" · "Hạn dùng chưa đúng dạng" · "Nhập mã lô" · "Nhập hạn dùng" |
| 008 | "Chụp ảnh" · "Chọn tệp" · "Tôi xác nhận hàng này thuộc sở hữu của cửa hàng" · "Tiếp tục" · "Thêm chứng từ giao nhận" · "Tick xác nhận quyền sở hữu" |
| 010 | "Cần chú ý" · "Vượt chứng từ: {tên} {b} / {a} {ĐVT} (+{c})" · "Hàng không đạt: {tên} {n} cách ly · {m} hỏng" · "Nhập nhanh: chưa có chứng từ mua" · "Ghi nhận nhận hàng" · "Ghi nhận nhận hàng?" · "Bạn là chủ cửa hàng nên hàng vào kho ngay, không qua duyệt." · "Yêu cầu bị từ chối" · "Nhận lại" |
| 011 | "Duyệt nhận hàng {chứng từ} của {NCC}?" · "Duyệt nhập hàng nhanh của {NCC}?" · "{tên}: chứng từ {a} · thực nhận {b} {ĐVT} (+{c})" · cột "Sản phẩm", "Lô / HSD", "Theo chứng từ", "Thực nhận", "Chênh lệch", "Tình trạng" · "Đã từ chối nhận hàng" |
| 012 | "Vào tồn" · "{n} mặt hàng · {m} lô" · "Giá trị" · "Chờ xác lập" · "Xem {n} dòng hàng" · "Nhận tiếp" · "Xác lập giá trị" · "Quay lại rà soát" |
| 013 | "Chuyển sang xác minh" (chữ K3, thay "Xem hỗ trợ xử lý") |

## 13. Review

(Phiên review điền.)
