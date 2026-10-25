# T7-P · BJ-08 Kiểm kê — thiết kế lại (bước B–E) + fixture chung chặng 5

> Theme: Theme 7 Inventory · Trạng thái: Brief ✅ (duyệt 2026-10-25 — mục 0.10, mọi điểm theo đề xuất) | Plan C–E ✅ (rà lại theo code chặng 4 khi làm) | Làm ✅ 2026-10-25 (v5.16.0, chưa commit — để phiên review xem trước) | Review ✅ (2026-10-25: đạt sau R1–R3, v5.18.1 — mục 14)
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) mục 8.2 **chặng 5 "Kiểm kê và sửa sai"**, BJ thứ nhất. Làm **sau** chặng 4 (`SC_journey_4`, plan [BJ-07 + BJ-10](T7-P-bj07-bj10-tra-ncc-tieu-huy.md)). BJ sau: [BJ-11](T7-P-bj11-sua-sai.md), rồi [BJ-16 + BJ-17](T7-P-bj16-bj17-doi-soat.md) (cuối chặng, có `SC_journey_5`).
> Dùng lại K1, **K2** (điều chỉnh chênh lệch cần chủ cửa hàng duyệt — UC-08-04), K3, K4, **K6** (danh sách phiên), K7. Không khuôn mới. Kèm **bước C0 — fixture chung chặng 5** (mục 3).
> Thiết bị: **cả iPhone và web đều là thiết bị chính** (T7-P mục 2). Nhân viên đếm tại kệ bằng iPhone (quét mã → gõ số) hoặc đếm ra giấy rồi gõ ở máy tính (gõ số → Enter → dòng sau); chủ cửa hàng duyệt lúc ở máy tính hoặc iPhone.
> Ước lượng: **~2,5 ngày, 3 commit** (C0 + C1 danh sách, tạo phiên, đếm; C2 đếm lại + duyệt + kết quả + D; E). Người làm: bạn. Review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị, chép nguyên văn; **(mới)** = chữ mới, vào T7-P mục 13 ở bước E.

## 0. Brief (bước B, đã duyệt 2026-10-25)

### 0.1 Việc thật

- **Ai, lúc nào:** **mỗi tháng một lần** nhân viên đếm toàn kho hoặc từng nhóm hàng, thường ngoài giờ bán (trong lúc kiểm, hàng trong phạm vi bị khoá — UC-08-01 BR-04); **khi nghi số sai** (app báo còn mà kệ hết) thì đếm riêng một vài sản phẩm. Chủ cửa hàng mở phiên hoặc giao cho nhân viên, rồi duyệt phần chênh lệch — thường cuối ngày ở máy tính, đôi khi trên iPhone.
- **Cần biết / làm gì:** người đếm: đếm những gì, còn bao nhiêu mặt hàng chưa đếm, gõ số nhanh từng dòng; sau khi nộp: dòng nào lệch, lệch bao nhiêu → đếm lại đúng các dòng đó. Chủ cửa hàng: lệch mấy mặt hàng, thiếu / thừa bao nhiêu, **đáng bao nhiêu tiền**, ai đếm, đã đếm lại mấy lần → duyệt điều chỉnh hoặc yêu cầu đếm lại.
- **Quy tắc** (BJ-08, UC-08-01…05, UIF-08): mở phiên = chốt phạm vi + số sổ + khoá trong một lần (BR-01); phạm vi không đổi sau khi mở (BR-02); **đếm mù** — trước khi nộp lần đầu người đếm không thấy số sổ, chênh lệch hay thứ gì suy ra được (UC-08-02 BR-01); mỗi lần đếm / đếm lại được lưu riêng, không ghi đè (BR-02); chênh lệch bằng 0 → xong luôn, không cần duyệt (BR-03); người đếm không nhập giá hàng thừa (BR-04) — thiếu giá vốn của hàng thừa thì phiên bị chặn, vẫn giữ khoá (UC-08-03 BR-04); người duyệt = `is_owner` hoặc `store_owner`, **không phải người đã đếm — trừ chủ cửa hàng: chủ đếm thì vẫn gửi rồi tự duyệt** (UC-08-04 BR-01, K2); duyệt gắn với đúng bản chênh lệch, đổi gì cũng phải lập lại (BR-02); "Yêu cầu đếm lại" mở vòng đếm mới, không sửa vòng cũ (BR-03); rủi ro tính bằng tổng trị tuyệt đối, không bù thừa với thiếu (BR-04); hủy phải có lý do, không tạo điều chỉnh, mở khoá (UC-08-05); `UNKNOWN` không gửi lại, chuyển BJ-17.
- **Ranh giới chặng 5** (00-business-journey-map): BJ-08 chỉ điều chỉnh số đếm; sai ở **phiếu nguồn** (phiếu nhận ghi thừa…) đi BJ-11 **sau khi phiên kết thúc** (BJ-08 mục 5) — plan này không thêm lối BJ-08 → BJ-11 (mục 11).

### 0.2 Luồng hiện tại

Ảnh: `tools/.golden-chang4/UIF-08_*`, `SC_bj08_*`, `SC_entry_UIF-08_*`; web `tools/.golden-chang4-web/UIF-08_*@web`.

```text
Hub nút nhanh "Kiểm kê" / Kiểm kê & xử lý → "Kiểm kê kho" → 042 "Kiểm kê kho" (2 phiên cố định: KK-0709-03 "Đang đếm 12/38", KK-0708-02 "Chờ duyệt")
  "Tạo phiên kiểm kê" → 043 (bảng nhãn–giá trị, ô chọn phạm vi, banner) → sheet "Mở phiên kiểm kê?" → 044 "Đếm mù" (phiên KK-1709-01 — mã khác 042)
  044: mỗi dòng một nút mở bàn phím số riêng (VNumericKeypadSheet) → "Lưu"; chân "Hủy phiên" | "Nộp kết quả đếm" → sheet → 045 hoặc 047 (khớp)
  045: mỗi dòng lệch: Theo sổ / Lần đếm đầu / Chênh lệch + bàn phím → sheet → 042 PENDING_APPROVAL (banner)
  người duyệt: ?entry=approver hoặc dòng "Chờ duyệt" của 042 (vai hiện tại → nhân viên bị chặn) → 046 (bảng theo dòng) → sheet → 047 (ds24Result canh giữa) → "Về kiểm kê"
```

### 0.3 Vấn đề

| # | Màn | Vấn đề |
|---|---|---|
| 1 | 042 | Không theo K6: chip không số, không có cột / dòng "Đã đếm"; dữ liệu lệch các màn sau (KK-0709-03 "12/38" ở danh sách, KK-1709-01 với 2 dòng ở 044); dòng "Chờ duyệt" mở 046 bằng vai đang dùng (nhân viên) → `SELF_APPROVAL_NOT_ALLOWED`; nhánh `CANCEL_REQUEST` không có trong danh sách trạng thái (chết); `PENDING_APPROVAL` của 042 là banner thay cho trạng thái của phiên |
| 2 | Home | Kết quả kiểm kê chờ duyệt không có trong "Chờ duyệt" (K2); chủ cửa hàng không biết có việc |
| 3 | 043 | Bảng nhãn–giá trị "Kho / Thời điểm chốt: Khi mở phiên / Người đếm" không cho chọn gì; phạm vi là ô chọn + nút phụ; không nói **mở phiên thì hàng trong phạm vi tạm không bán / nhận / xuất được** (việc quan trọng nhất với cửa hàng); sheet xác nhận "Hệ thống khóa phạm vi trước khi chốt số sổ…" (chữ kỹ thuật); `COUNT_SCOPE_HAS_UNRESOLVED_VALUATION` là ngõ cụt ("Về kiểm kê", không lối sang hàng chờ xác lập giá trị); `CONFLICT` / `VALIDATION_ERROR` không có nhánh dựng |
| 4 | 044 | Gõ số phải mở bàn phím riêng cho **từng dòng** (2 chạm + "Lưu"); không quét mã, không tìm, không biết còn bao nhiêu dòng chưa đếm; banner "Đếm mù" luôn hiện; **"Hủy phiên" (nút đỏ) ngang hàng "Nộp kết quả đếm"** ở chân; `VALIDATION_ERROR` là banner chung không chỉ dòng nào thiếu; `LOCK_LOST` / `CONFLICT` không có nhánh dựng |
| 5 | 044 hàng ngoài phạm vi | Ô chọn hệ thống cho "Trạng thái hàng"; dòng "Giá trị hàng thừa do nguồn có thẩm quyền cung cấp; người đếm không nhập giá." (chữ kỹ thuật, người đếm không cần biết) |
| 6 | 045 | Mỗi dòng 3 hàng nhãn–giá trị + bàn phím; không có cách nhanh xác nhận "đếm lại vẫn như lần đầu"; khối "Căn cứ giá hàng thừa: Đã xác nhận · Khóa phạm vi: Đang giữ" (kỹ thuật, luôn hiện); `PRICE_BASIS_REQUIRED` không nói ai làm gì; gửi xong về 042 banner (người đếm mất ngữ cảnh) |
| 7 | 046 | Không theo K2 (câu hỏi → người gửi → Cần chú ý → số liệu); **không có số tiền** dù chủ cửa hàng là người duyệt (BR-04 rủi ro theo giá trị); "Mức duyệt: Đã xác định theo rủi ro hiện hành", "Cần quyết định độc lập" (kỹ thuật); nút "Yêu cầu xem lại" nhưng sheet ghi "Yêu cầu đếm lại?"; thêm một sheet xác nhận khi duyệt; **chủ cửa hàng tự đếm bị chặn** (chỉ `actor === "approver"`) — sai K2 |
| 8 | 047 | `ds24Result` canh giữa; không theo K4 (không người duyệt, không bước tiếp ngoài "Về kiểm kê"); `UNKNOWN` không theo K3 |
| 9 | Fixture | Sản phẩm không có ở chặng nào khác (Amox "SP-00128" lô L2407-A, Găng tay M, Vitamin C); người đếm "Nguyễn An" (chặng 3–4: "Nguyễn Văn An"); số sổ / mã phiên rời rạc giữa các màn |
| 10 | Web | Mọi màn là cột iPhone 402px giữa khung; đếm trên máy tính phải bấm từng nút mở bàn phím |
| 11 | Mã | `deniedBody` / `loadingBody` / `ioEmpty` / `ds24Result` riêng thay K1 / K4; `ac310SanitizeMarkup` cho chữ đã viết lại; `ic08SessionRow`, nhánh "other" của 042, `ic08Evidence`, `ic08ConfirmKind` không dùng; nhãn `data-v350-ic08-*`, `data-v3100-ic08-*`, `data-v360-action="fallback-exit"`; `.replace()` đổi nhãn trên chuỗi HTML cuối `render042BJ08` |

### 0.4 Đề xuất

**Luồng mới**

```text
Home nút nhanh "Kiểm kê" / Hub Kiểm kê & xử lý → "Kiểm kê kho" → 042 (K6: chip có số "Tất cả · Đang đếm · Chờ duyệt · Đã xong")
  dòng mở đúng bước đang dở: Đang đếm → 044 · Đếm lại → 045 · Chờ duyệt → 046 (chủ: duyệt; người khác: chỉ đọc) · Đã xong → 047
  "Tạo phiên kiểm kê" → 043 → sheet "Mở phiên kiểm kê?" (nói rõ hàng nào bị tạm khoá) → 044
044 (ô số ngay trên dòng, quét / tìm, "Đã đếm {a}/{b}") → sheet "Nộp kết quả đếm?" → khớp hết → 047 · có lệch → 045
045 (chỉ dòng lệch, "Vẫn {n}") → sheet → khớp hết → 047 · còn lệch → 046 chờ duyệt (K2, người đếm) + toast
chủ cửa hàng: Home "Chờ duyệt" → dòng "kiểm kê" → 046 duyệt (K2, có tiền) → "Duyệt và điều chỉnh" → 047 (K4)
                                                          → "Yêu cầu đếm lại" (lý do) → 045 vòng mới
"Hủy phiên" → nút chữ cuối nội dung 044 / 045 (không ở chân) → sheet có lý do → 047 đã hủy
```

*SCR-042 Kiểm kê kho* (K6 — vấn đề 1, 2)

1. Tiêu đề "Kiểm kê kho" (giữ); ô tìm "Tìm phiên kiểm kê" (giữ). `k6TaskList` chip có số: "Tất cả" · "Đang đếm" (giữ; gồm phiên đang đếm lần đầu và đang đếm lại) · "Chờ duyệt" (giữ) · **"Đã xong" (mới)** (hoàn tất / đã hủy, 30 ngày gần nhất).
2. Dòng iPhone: tiêu đề mã phiên; phụ **"{phạm vi} · {người đếm} · Đã đếm {a}/{b}" (mới)** (phiên đã nộp: "· {k} mặt hàng lệch" thay vế "Đã đếm"); badge "Đang đếm" (info) · **"Đếm lại" (mới, warning)** · "Chờ duyệt" (warning) · **"Đã xong" (mới, success)** · **"Đã hủy" (mới, neutral)**.
3. Web (K7): bảng **"Phiên"** · **"Phạm vi"** · "Người đếm" · **"Đã đếm"** ("{a}/{b}") · **"Mở lúc"** · "Tình trạng" (mới — đầu cột).
4. `rowAttr` theo bước đang dở (K6): Đang đếm → 044; Đếm lại → 045; Chờ duyệt → 046 (`approver` / `owner` = duyệt; còn lại = chỉ đọc `PENDING_APPROVAL`); Đã xong / Đã hủy → 047 chỉ đọc. Chân "Tạo phiên kiểm kê" (giữ).
5. `EMPTY` → `k1Empty` **"Chưa có phiên kiểm kê" (mới)** / **"Tạo phiên để đếm toàn kho hoặc một nhóm hàng." (mới)**; `FILTER_EMPTY` → `k1Empty` "Không tìm thấy phiên kiểm kê" (giữ) / "Thử từ khóa hoặc bộ lọc khác." (giữ) + "Xem tất cả" (chữ CAP-01); `LOADING` / `PERMISSION_DENIED` → K1 (`what:` **"Bạn chưa có quyền kiểm kê" (mới)**, `next:` "Liên hệ chủ cửa hàng để được cấp quyền."). `PENDING_APPROVAL` của 042 bỏ khỏi bộ chọn trạng thái (thay bằng 046 `PENDING_APPROVAL`, điểm 19); nhánh `CANCEL_REQUEST` xoá (ghi CHANGELOG).
6. Home "Chờ duyệt": nguồn K2 `{ id:"UIF-08", label:**"kiểm kê" (mới)** }`, dòng **"{mã phiên} · {phạm vi}" / "{k} mặt hàng lệch · {người đếm} gửi {lúc}" (mới)**, mở 046 của đúng phiên.

*SCR-043 Tạo phiên kiểm kê* (vấn đề 3)

7. Tiêu đề "Tạo phiên kiểm kê" (giữ). **"Phạm vi"** (giữ) — `dsChoiceRow` bốn mục "Toàn kho" · "Nhóm sản phẩm" · "Sản phẩm" · "Lô" (giữ chữ), mô tả **"{n} mặt hàng" (mới)** khi đã biết (Toàn kho luôn biết). Chọn khác "Toàn kho" → nút "Chọn phạm vi cụ thể" (giữ) mở sheet "Chọn phạm vi" (giữ, có ô tìm); đã chọn thì nút thành tên phạm vi + "Đổi" (**mới**).
8. "Người đếm" (giữ) — `cfSelect` từ danh sách thành viên fixture ("Nguyễn Văn An", "Trần Thị Bình", "Chủ cửa hàng"); mặc định người đang lập. "Lý do kiểm kê" (giữ) — ô chữ, mặc định "Kiểm kê định kỳ" (giữ). Bỏ hàng "Kho" (một kho) và "Thời điểm chốt: Khi mở phiên".
9. Khối **"Khi mở phiên" (mới)** (`k2Attention` tone warning): **"Tạm khoá {n} mặt hàng: không nhận, xuất hay bán được cho tới khi kiểm xong." (mới)** + **"Số theo sổ được chốt lúc mở phiên." (mới)**. Bỏ banner "Phạm vi được khóa khi mở phiên".
10. Chân `k4ReasonFooter` "Mở phiên kiểm kê" (giữ); lý do khi tắt **"Chọn phạm vi cụ thể"** (chữ nút, dùng làm lý do). Sheet "Mở phiên kiểm kê?" (giữ) — mô tả **"Trong lúc kiểm, {n} mặt hàng này tạm không nhận, xuất hay bán được." (mới — thay "Hệ thống khóa phạm vi trước khi chốt số sổ và mở phiên.")**; "Quay lại" | "Mở phiên" (giữ).
11. `COUNT_SCOPE_HAS_UNRESOLVED_VALUATION` → `vBanner` "Chưa thể mở phiên" (giữ) + câu (giữ); chủ cửa hàng: nút chính **"Mở hàng chờ xác lập giá trị" (mới — chữ Hub "Hàng chờ xác lập giá trị")** → BJ-03 SCR-014; nhân viên: "Về kiểm kê" (giữ). `CONFLICT` → `k1Stale({ title:**"Phạm vi đang có phiên khác" (mới)**, description:**"{mã phiên} đang kiểm {phạm vi}. Mở phiên đó hoặc chọn phạm vi khác." (mới)**, actionLabel:**"Mở phiên đang kiểm" (mới)** })`. `VALIDATION_ERROR` → lỗi tại ô ("Chọn phạm vi cụ thể", **"Nhập lý do kiểm kê" (mới)**).
12. Web: `k7Split` — trái các ô; phải khối "Tóm tắt" (chữ BJ-03): **"Mặt hàng trong phạm vi" (mới)** liệt kê tối đa 8 + **"và {n} mặt hàng khác" (mới)**.

*SCR-044 Đếm mù* (vấn đề 4, 5)

13. Tiêu đề "Đếm mù" (giữ); phụ **"{mã phiên} · {phạm vi} · {người đếm}" (mới)**; một dòng chữ phụ (không banner) "Số lượng theo sổ chỉ xuất hiện sau khi nộp lần đếm đầu." (giữ). Thanh tiến độ mảnh (`.bj02-progress`) **"Đã đếm {a}/{b} mặt hàng" (mới)**.
14. Ô tìm **"Tìm hoặc quét sản phẩm trong phạm vi" (mới)** có nút quét (thành phần BJ-01); quét / chọn kết quả → cuộn tới dòng, đặt focus vào ô số của dòng đó. Chip có số **"Chưa đếm"** · **"Đã đếm"** · "Tất cả" (mới; mặc định "Chưa đếm").
15. Dòng iPhone: tên sản phẩm; phụ **"{mã} · Lô {lô} · {tình trạng}" (mới; bỏ ĐVT khỏi phụ đề)**; bên phải **ô số nhập thẳng** (`k7EditCell`, hậu tố ĐVT, `inputmode="numeric"`, `enterkeyhint="next"`) — **bỏ** `VNumericKeypadSheet` riêng (như BJ-02); nhãn ô "Số lượng thực tế" (giữ, `aria-label`). Ô trống = chưa đếm; "0" = đã đếm, không có hàng. Enter / "Tiếp" → ô của dòng chưa đếm kế tiếp.
16. Web: bảng "Sản phẩm" · "Lô" · "Tình trạng" · **"Đếm được" (mới)** (cột ô số); Tab / Enter đi dọc cột. Không có cột hay thuộc tính nào chứa số sổ (BR-01 — audit kiểm DOM).
17. "Thêm hàng thực tế" (giữ) — nút phụ cuối danh sách → sheet "Thêm hàng thực tế" (giữ) có ô tìm + quét; dòng thêm vào có badge "Hàng thực tế" (giữ), **"Tình trạng" (mới — thay "Trạng thái hàng")** là `dsSegmented` "Bán được | Cách ly | Hỏng" (giữ chữ) thay ô chọn hệ thống, và ô số như điểm 15. Bỏ dòng "Giá trị hàng thừa do nguồn có thẩm quyền cung cấp…".
18. Chân `k4ReasonFooter` "Nộp kết quả đếm" (giữ); lý do khi tắt **"Còn {n} mặt hàng chưa đếm" (mới)**, **"Chọn tình trạng cho hàng thực tế" (mới)**. Sheet "Nộp lần đếm đầu?" (giữ) — mô tả "Sau khi nộp, số sổ và chênh lệch mới được hiển thị." (giữ) + **"Không sửa được lần đếm này." (mới)**; "Quay lại" | "Nộp kết quả" (giữ). `VALIDATION_ERROR` (đặt từ ngoài) → dòng thiếu có lỗi dưới ô **"Nhập số đếm được" (mới)** + chip "Chưa đếm" chọn sẵn.
19. "Hủy phiên" (giữ chữ) chuyển thành **nút chữ màu danger cuối nội dung** (không ở chân, không ngang nút chính); sheet "Hủy phiên kiểm kê?" (giữ) + "Không tạo điều chỉnh; toàn bộ lịch sử đếm được giữ và phạm vi được mở khóa." (giữ) + "Lý do" bắt buộc (giữ) → `k2RejectSheet` dạng xác nhận nguy hiểm ("Quay lại" | "Hủy phiên").
20. `LOCK_LOST` → `k1Stale({ title:**"Phiên không còn hiệu lực" (mới)**, description:**"Phiên đã bị hủy hoặc đã mở khoá. Số đã đếm vẫn được lưu." (mới)**, actionLabel:"Về kiểm kê" })`. `CONFLICT` → `k1Stale({ title:**"Người khác vừa nộp phiên này" (mới)**, actionLabel:"Tải lại" })`. `PERMISSION_DENIED` → K1.

*SCR-045 Chênh lệch và đếm lại* (vấn đề 6)

21. Tiêu đề "Chênh lệch và đếm lại" (giữ); phụ **"{mã phiên} · Đếm lại lần {n}" (mới — thay banner "Đếm lại lần {n}")**; dải số một hàng (`cf12Strip`) **"{k} mặt hàng lệch · {m} khớp" (mới)**. Dòng "Kết quả vòng trước được giữ nguyên trong lịch sử." (giữ vế sau của banner cũ) là chữ phụ.
22. Chỉ dòng lệch được đếm lại; dòng khớp gom vào một nút **"Xem {m} mặt hàng khớp" (mới)** (mở sheet chỉ đọc).
23. Dòng iPhone: tên; phụ **"Theo sổ {a} · Đếm đầu {b} {ĐVT}" (mới)**; badge **"Thiếu {d} {ĐVT}" / "Thừa {d} {ĐVT}" (mới, warning)**; ô "Số lượng đếm lại" (giữ, ô số như điểm 15) + nút **"Vẫn {b} {ĐVT}" (mới)** điền đúng số đếm đầu (vẫn là một lần đếm lại có ghi nhận — BR-01). Web: bảng "Sản phẩm" · "Lô" · "Theo sổ" · **"Đếm đầu" (mới)** · "Chênh lệch" · **"Đếm lại" (mới)** (ô số + nút "Vẫn {b}").
24. Bỏ khối "Căn cứ giá hàng thừa / Khóa phạm vi". `PRICE_BASIS_REQUIRED` → `vBanner` warning **"Hàng thừa chưa có giá vốn" (mới)** / **"{sản phẩm} chưa có giá vốn nên chưa duyệt được. Phiên vẫn khoá; chủ cửa hàng cần xác lập giá trị trước." (mới)**; chân tắt, lý do **"Chờ giá vốn của hàng thừa" (mới)**.
25. Chân `k4ReasonFooter` "Gửi kết quả đếm lại" (giữ); lý do **"Còn {n} mặt hàng chưa đếm lại" (mới)**. Sheet "Gửi kết quả đếm lại?" (giữ) — mô tả **"Kết quả được lưu thành một lần đếm lại, không sửa được." (mới — thay "…một vòng đếm lại bất biến.")**. Khớp hết → 047; còn lệch → 046 `PENDING_APPROVAL` + toast **"Đã gửi chủ cửa hàng duyệt" (chữ BJ-09)**. "Hủy phiên" như điểm 19. `LOCK_LOST` / `VALIDATION_ERROR` như điểm 18, 20.

*SCR-046 Duyệt kết quả kiểm kê* (K2 — vấn đề 7)

26. Tiêu đề "Duyệt kết quả kiểm kê" (giữ). `k2Decision({ question:**"Duyệt điều chỉnh {k} mặt hàng lệch của phiên {mã}?" (mới)**, maker: người đếm, sentAt, attention, facts })`:
    - `attention`: mỗi dòng lệch một mục **"Thiếu {d} {ĐVT} {sản phẩm}" / "Thừa {d} {ĐVT} {sản phẩm}" (mới)** kèm giá trị **"{±x} đ"** (chủ cửa hàng); dòng cuối **"Tổng chênh lệch (không bù trừ): {x} đ" (mới)** (BR-04).
    - `facts`: "Phạm vi" (mới) · **"Số lần đếm lại" (mới)** · "Người đã tham gia đếm" (giữ) · **"Sau khi duyệt" (chữ K2) "Tồn kho ghi theo số đếm lại, phạm vi mở khoá" (mới)**.
    - bảng chi tiết (K7 trên web, thẻ trên iPhone): Sản phẩm · Lô · Theo sổ · **"Đếm lại"** (giữ) · "Chênh lệch" · **"Giá trị" (mới, chỉ chủ)**.
    Bỏ banner "Cần quyết định độc lập", hàng "Mức duyệt".
27. Chân "Yêu cầu đếm lại" (**thống nhất — thay "Yêu cầu xem lại"; chữ sheet**) | "Duyệt và điều chỉnh" (giữ). "Duyệt và điều chỉnh" ghi ngay (bỏ sheet "Duyệt và điều chỉnh?" — K2 không có sheet duyệt). "Yêu cầu đếm lại" → `k2RejectSheet` (tiêu đề "Yêu cầu đếm lại?" (giữ) + "Vòng đếm hiện tại được giữ nguyên. Một vòng đếm lại mới sẽ được mở." (giữ) + "Lý do" bắt buộc) → 045 vòng mới, người đếm thấy ở 042 badge "Đếm lại".
28. Ai duyệt được: `currentActor()` là `approver` hoặc `owner` (như `bj09CanDecide`); chủ cửa hàng đếm thì vẫn gửi rồi tự duyệt (K2). `SELF_APPROVAL_NOT_ALLOWED` chỉ khi người bấm đã đếm và không phải chủ: `vBanner` "Không thể tự duyệt" (giữ) + **"Bạn đã đếm phiên này. Chủ cửa hàng sẽ duyệt." (mới — thay "…Công việc cần người duyệt độc lập.")**.
29. `PENDING_APPROVAL` (người đếm / nhân viên khác) → `k2Pending({ approver:"chủ cửa hàng", sentAt, facts })` + bảng chênh lệch **không có cột "Giá trị"** (tiền chỉ chủ thấy — `FINANCIAL_MASKED`: không số tiền trong DOM); chân **"Về kiểm kê"** (giữ chữ 047). `COUNT_APPROVAL_SNAPSHOT_STALE` → `k1Stale({ title:"Kết quả cần được lập lại" (giữ), description:"Căn cứ giá hoặc dữ liệu kiểm kê đã thay đổi. Không thể điều chỉnh theo lần duyệt cũ." (giữ), actionLabel:"Về kiểm kê" })`. `APPROVAL_ALREADY_DECIDED` → `k1Locked({ title:"Công việc đã có quyết định" (giữ), description:"Mở kết quả phiên để xem trạng thái hiện hành." (giữ) })` + "Xem kết quả" (giữ). `PERMISSION_DENIED` → K1.
30. Web: `k7Split({ wideMain:true })` — trái câu hỏi + Cần chú ý + bảng; phải khối "Tóm tắt": tổng thiếu / thừa / giá trị (chủ).

*SCR-047 Kết quả kiểm kê* (K4 — vấn đề 8)

31. `COMPLETED` (có điều chỉnh) → `k4Result({ screenTitle:"Kết quả kiểm kê" (giữ), title:"Đã hoàn tất kiểm kê" (giữ), description:"Điều chỉnh chênh lệch đã được ghi và phạm vi đã mở khóa." (giữ) })`; `facts`: "Phiên" · "Phạm vi" · "Đã điều chỉnh" "{n} dòng" (giữ) · **"Thiếu / thừa" "Thiếu {a} · thừa {b} mặt hàng" (mới)** · **"Giá trị điều chỉnh" "{±x} đ" (mới, chỉ chủ)** · "Người duyệt" (chữ BJ-09) · "Ghi nhận lúc" (giữ). Bỏ "Khóa phạm vi: Đã mở" (đã nói ở mô tả) và mã "ADJ-…".
32. Khớp hết (`ZERO`) → K4 "Đã hoàn tất kiểm kê" (giữ) + "Kết quả thực tế khớp số sổ. Không cần tạo điều chỉnh và phạm vi đã mở khóa." (giữ) + "Hoàn tất lúc" (giữ). `CANCELLED` → K4 kind warning "Đã hủy phiên" (giữ) + câu (giữ) + **"Lý do"** (mới, chữ của lý do hủy). `REJECTED_EXECUTION` → K4 warning "Chưa thực hiện điều chỉnh" (giữ) + câu (giữ). `UNKNOWN` → `k3Unknown({ operation:**"Ghi điều chỉnh kiểm kê" (mới)**, scope:"{mã phiên} · {phạm vi}", ref, sentAt, sourceFlow:"UIF-08" })` (không truyền `safe`). `PROCESSING` → `k1Loading`. `PERMISSION_DENIED` → K1.
33. Bước tiếp (`next`): phụ "Về kiểm kê" (giữ) | chính **"Xem tồn kho" (chữ BJ-02)** → BJ-01 SCR-001 (`COMPLETED`, `ZERO`); `CANCELLED` / `REJECTED_EXECUTION` → một nút "Về kiểm kê".

### 0.5 Trạng thái (sau thiết kế lại)

| Màn | Trạng thái | Hiện gì | Làm được gì | Lối ra |
|---|---|---|---|---|
| 042 | READY | K6: chip có số, danh sách / bảng | lọc, tìm, mở phiên (đúng bước), "Tạo phiên kiểm kê" | Về Kho |
| 042 | EMPTY / FILTER_EMPTY | `k1Empty` | "Tạo phiên kiểm kê" / "Xem tất cả" | Về Kho |
| 042…047 | LOADING / PERMISSION_DENIED | K1 | — | "Về Kho" |
| 043 | READY / VALIDATION_ERROR | phạm vi, người đếm, lý do, "Khi mở phiên"; lỗi tại ô | "Mở phiên kiểm kê" → sheet | Quay lại |
| 043 | COUNT_SCOPE_HAS_UNRESOLVED_VALUATION | banner | chủ: "Mở hàng chờ xác lập giá trị" | "Về kiểm kê" |
| 043 | CONFLICT | `k1Stale` | "Mở phiên đang kiểm" | Quay lại |
| 044 | BLIND_COUNT / VALIDATION_ERROR | tiến độ, tìm / quét, chip, ô số tại dòng; lỗi tại dòng | gõ số, "Thêm hàng thực tế", "Nộp kết quả đếm", "Hủy phiên" | Quay lại (về 042, giữ số đã gõ) |
| 044 / 045 | LOCK_LOST | `k1Stale` | "Về kiểm kê" | — |
| 044 | CONFLICT | `k1Stale` | "Tải lại" | Quay lại |
| 045 | RECOUNT_REQUIRED / READY / VALIDATION_ERROR | dải lệch / khớp, dòng lệch, "Vẫn {n}" | "Gửi kết quả đếm lại", "Hủy phiên" | Quay lại |
| 045 | PRICE_BASIS_REQUIRED | banner, chân tắt có lý do | "Hủy phiên" | Quay lại |
| 046 | READY (`APPROVAL_REVIEW`) | `k2Decision`, tiền (chủ) | "Yêu cầu đếm lại" (lý do), "Duyệt và điều chỉnh" | Quay lại (về "Chờ duyệt") |
| 046 | PENDING_APPROVAL | `k2Pending`, bảng không tiền | — | "Về kiểm kê" |
| 046 | SELF_APPROVAL_NOT_ALLOWED | banner | — | "Về kiểm kê" |
| 046 | COUNT_APPROVAL_SNAPSHOT_STALE | `k1Stale` | "Về kiểm kê" | — |
| 046 | APPROVAL_ALREADY_DECIDED | `k1Locked` | "Xem kết quả" | Quay lại |
| 047 | COMPLETED (có điều chỉnh / khớp) | K4 | "Xem tồn kho" | "Về kiểm kê" |
| 047 | CANCELLED / REJECTED_EXECUTION | K4 cảnh báo | — | "Về kiểm kê" |
| 047 | UNKNOWN | K3 | "Chuyển sang xác minh" | "Về Kho" |
| 047 | PROCESSING | `k1Loading` | — | — |

### 0.6 Khuôn dùng lại

- K1, K2 (`k2Decision`, `k2Pending`, `k2Attention`, `k2RejectSheet`, nguồn "Chờ duyệt", `__T7_DIRECT_CONTEXTS__["bj08-approval"]`), K3 (`k3Unknown`), K4 (`k4Result`, `k4ReasonFooter`), K6 (`k6TaskList`), K7 (`k7Split`, `k7Table`, `k7EditCell`, lớp `k7-wide`), `dsChoiceRow`, `dsSegmented`, `cfSelect`, `cf12Strip`, `.bj02-progress`, nút quét của BJ-01.
- Không thành phần DS mới. `VNumericKeypadSheet` không còn dùng ở BJ-08 (BJ-02 đã bỏ) — ghi T7-P mục 6 để giai đoạn 5 không dựng.

### 0.7 Không đổi

Quy tắc ở 0.1; dữ liệu vòng đếm `bj08RoundHistory` (mỗi lần nộp một bản ghi, không ghi đè), cách tính chênh lệch `bj08CurrentVariance`, `bj08AllZero`, nhánh khớp hết → 047, `REQUEST_RECOUNT` mở vòng mới (`bj08RoundNo += 1`), `handoff-unknown` của UIF-08. Chữ giữ: "Kiểm kê kho", "Tìm phiên kiểm kê", "Đang đếm", "Chờ duyệt", "Tạo phiên kiểm kê", "Phạm vi", "Toàn kho", "Nhóm sản phẩm", "Sản phẩm", "Lô", "Chọn phạm vi cụ thể", "Chọn phạm vi", "Người đếm", "Lý do kiểm kê", "Kiểm kê định kỳ", "Mở phiên kiểm kê", "Mở phiên kiểm kê?", "Mở phiên", "Chưa thể mở phiên" + câu, "Đếm mù", "Số lượng theo sổ chỉ xuất hiện sau khi nộp lần đếm đầu.", "Số lượng thực tế", "Thêm hàng thực tế", "Hàng thực tế", "Nộp kết quả đếm", "Nộp lần đếm đầu?" + câu, "Nộp kết quả", "Hủy phiên", "Hủy phiên kiểm kê?" + câu, "Lý do", "Quay lại", "Chênh lệch và đếm lại", "Theo sổ", "Chênh lệch", "Số lượng đếm lại", "Gửi kết quả đếm lại", "Gửi kết quả đếm lại?", "Gửi kết quả", "Duyệt kết quả kiểm kê", "Đếm lại", "Người đã tham gia đếm", "Duyệt và điều chỉnh", "Yêu cầu đếm lại?" + câu, "Không thể tự duyệt", "Kết quả cần được lập lại" + câu, "Công việc đã có quyết định" + câu, "Xem kết quả", "Kết quả kiểm kê", "Đã hoàn tất kiểm kê" + hai câu, "Đã điều chỉnh", "Ghi nhận lúc", "Hoàn tất lúc", "Đã hủy phiên" + câu, "Chưa thực hiện điều chỉnh" + câu, "Về kiểm kê".

### 0.8 Kiểm (bước D)

- Golden **mobile** được khác: `UIF-08_*`, `SC_bj08_*`, `SC_entry_UIF-08_*`, `SC_bj17_from_bj08_*` nếu có (bước 0), `SC_ws_control_*` (dòng kiểm kê không đổi chữ — chỉ khác nếu Hub đổi), **mọi ca có Home Kho** (số "Chờ duyệt" thêm nguồn "kiểm kê" — fixture có phiên KK-260915-02 chờ duyệt). Ca khác khớp mốc `tools/.golden-chang4`.
- Golden **web** được khác: như trên với `@web`; ca khác khớp `tools/.golden-chang4-web`.
- Kịch bản (mục 6): sửa `SC_bj08_list`, `SC_bj08_create`, `SC_bj08_blind`, `SC_bj08_recount`, `SC_bj08_approve`, `SC_bj08_self_approve`, `SC_bj08_review`, `SC_bj08_cancel`, `SC_bj08_unknown`; thêm `SC_bj08_zero`, `SC_bj08_scan`, `SC_bj08_unexpected`, `SC_bj08_price_basis`, `SC_bj08_owner_self`, `SC_bj08_from_home`, `SC_bj08_pending_view`.

### 0.9 Ước lượng C–E

~2,5 ngày: C0 fixture chung chặng 5 ~0,25; C1 042 + 043 + 044 ~1; C2 045 + 046 + 047 + "Chờ duyệt" ~0,75; D ~0,25; E ~0,25. (T7-P mục 8.2 ghi 2 khi còn chia thiết bị chính / phụ; thêm bảng nhập số trên web và K2 có tiền.)

### 0.10 Đã chốt khi duyệt brief (2026-10-25): **mọi điểm theo cột "Đề xuất"**

| # | Điểm | Đề xuất | Phương án khác |
|---|---|---|---|
| a | Nhập số ở 044 / 045 | **Ô số ngay trên dòng** (bàn phím số hệ thống trên iPhone, gõ + Enter trên web); bỏ bàn phím riêng | Giữ `VNumericKeypadSheet` từng dòng (thêm nút +/−) |
| b | Chỗ đặt "Hủy phiên" | **Nút chữ danger cuối nội dung** 044 / 045 | Nút "⋯" trên đầu màn mở menu phiên (cần thành phần menu mới) |
| c | Xác nhận đếm lại bằng một chạm | **Có** — nút "Vẫn {n} {ĐVT}" điền số đếm đầu, vẫn ghi một lần đếm lại | Không — người đếm phải gõ lại số |
| d | Sheet xác nhận khi duyệt | **Bỏ** (K2: "Duyệt và điều chỉnh" ghi ngay); giữ sheet có lý do cho "Yêu cầu đếm lại" | Giữ sheet "Duyệt và điều chỉnh?" |
| e | Tiền ở 046 / 047 | **Có, chỉ chủ cửa hàng** (giá trị từng dòng + "Tổng chênh lệch (không bù trừ)"); nhân viên không có số tiền trong DOM | Không hiện tiền ở BJ-08 (xem ở BJ-14 / BJ-15) |
| f | Lối khi phạm vi còn hàng chờ giá trị (043) | **Chủ: nút "Mở hàng chờ xác lập giá trị" → BJ-03**; nhân viên: "Về kiểm kê" | Giữ ngõ cụt "Về kiểm kê" cho mọi người |
| g | Chip "Đã xong" ở 042 | **Có** (30 ngày, chỉ đọc 047) | Không — phiên xong biến khỏi danh sách |

---

## 1. Mục tiêu

1. Đếm nhanh một tay trên iPhone và gõ liên tục trên web: ô số tại dòng, quét / tìm, biết còn bao nhiêu dòng chưa đếm.
2. Đếm mù thật: không có số sổ trong DOM trước khi nộp lần đầu.
3. Duyệt theo K2: chủ cửa hàng thấy việc ở Home "Chờ duyệt", thấy thiếu / thừa và tiền trước khi quyết; chủ tự đếm vẫn tự duyệt được.
4. Không ngõ cụt; hủy phiên không đứng cạnh nút chính.
5. Mọi trạng thái 0.5 dựng khác nhau và có lối ra, ở cả hai khung.

## 2. Chuẩn bị

1. Chặng 4 đã review và commit (T7-P mục 14). Nếu review chặng 2–4 chốt đề xuất "lối về Kho ở K4" / "bẫy focus cho mọi sheet" (T7-P mục 13, dòng `13 / 03 / mọi K4`) thì làm theo cách đã chốt.
2. Rà lại plan theo code chặng 4: tên hàm K5 / `t7Lots` (mã sản phẩm, lô, `unitCost` dùng ở mục 3), cách Hub gắn vai cho dòng "Chờ duyệt", `__T7_DIRECT_CONTEXTS__` — lệch ghi mục 10.
3. Mốc = `tools/.golden-chang4` / `tools/.golden-chang4-web`. Chụp lại ở HEAD, so "Khớp hoàn toàn"; lệch → chụp `tools/.golden-bj08-base` / `-web-base` làm mốc và ghi mục 10.
4. GitNexus (CLAUDE.md): `impact` hướng upstream cho `render042BJ08`…`render047BJ08`, `ic08NumericSheet`, `ic08SelectSheet`, `bj08ConfirmSheet`, `renderHubHome`, `pendingSummary`; báo mức rủi ro vào mục 10. Chỉ mục cũ thì `node .gitnexus/run.cjs analyze` trước; trả lại `CLAUDE.md` / `AGENTS.md` nếu `analyze` ghi đè số ký hiệu.
5. Máy chủ `python3 -m http.server 8765 --bind 127.0.0.1 &` trong `html/`.

## 3. Bước C0 — fixture chung chặng 5 (commit 1, cùng C1)

Mục đích: `SC_journey_5` (plan [BJ-16 + BJ-17](T7-P-bj16-bj17-doi-soat.md) mục 6.4) đi "kiểm kê → chênh lệch → chủ duyệt → hồ sơ đối soát phát hiện phiếu sai → sửa sai → chủ duyệt → đóng hồ sơ" trên **sản phẩm của chặng 1–4**, và **mỗi sản phẩm một câu chuyện** để các BJ không sửa chồng lên nhau (vd. kiểm kê đã điều chỉnh thiếu 2 hộp Amox rồi sửa phiếu nhận Amox thêm −2 nữa — sai nghiệp vụ).

**Phân vai sản phẩm chặng 5** (mã / lô / ĐVT lấy từ `t7Lots` và fixture BJ-01; số sổ là fixture riêng của từng BJ):

| Sản phẩm · mã | Dùng ở | Câu chuyện | Plan áp |
|---|---|---|---|
| Oxytetracycline LA · SP-000147 · không theo lô | BJ-08 phiên mới KK-260917-01 | sổ 12 chai, đếm 10, đếm lại "Vẫn 10" → thiếu 2 chai | plan này |
| Tylosin 20% · SP-000122 · lô TY2511 | BJ-08 phiên mới | sổ 3 lọ, đếm 4 (thừa 1), đếm lại 3 → khớp | plan này |
| Tylosin 20% · lô TY2408 · Hết hạn | BJ-08 phiên mới | sổ 11 lọ, đếm 11 → khớp (đếm cả hàng hết hạn) | plan này |
| Găng tay khám Nitrile · SP-000271 | BJ-08 phiên KK-260915-02 (Chờ duyệt sẵn) | "Nhóm vật tư", sổ 10 hộp, đếm lại 9 → thiếu 1 hộp, "Nguyễn Văn An" gửi "15/09/2026 17:40" | plan này |
| Dầu sát khuẩn · SP-00606 · L2406-T (không có `unitCost` từ chặng 4) | BJ-08 "Thêm hàng thực tế" → `PRICE_BASIS_REQUIRED`; BJ-11 phiếu nhận PN-260901-07 ghi 6 chai, đúng 4 (yêu cầu sửa sai chờ duyệt sẵn) | | plan này / [BJ-11](T7-P-bj11-sua-sai.md) |
| Amox 500 · SP-000066 | BJ-16 hồ sơ "Cần sửa nghiệp vụ nguồn" → BJ-11 phiếu nhận PN-260904-08 ghi 20 hộp, hoá đơn 18 | **không** có trong phiên kiểm kê nào | [BJ-11](T7-P-bj11-sua-sai.md), [BJ-16](T7-P-bj16-bj17-doi-soat.md) |
| Nobivac DHPPi · SP-000184 · DH2507 | BJ-16 hồ sơ "Số trên app lệch sổ kho" (app 116, sổ 118 hộp) | **không** có phiếu sửa sai nào | [BJ-16](T7-P-bj16-bj17-doi-soat.md) |

Fixture BJ-08 (`app/bj08.js`):

1. `BJ08_META` / `BJ08_BOOK` → mảng phiên `bj08Sessions` (mỗi phiên: `id`, `scope: { kind, label }`, `counter`, `openedAt`, `status` `COUNTING | RECOUNT | PENDING | DONE | CANCELLED`, `lines: [{ key, product, code, lot, state, uom, book, unitCost }]`, `rounds`, `result`). Phiên sẵn:
   - `KK-260916-01` · Toàn kho · "Trần Thị Bình" · Đang đếm 9/38 (dòng chỉ để hiện tiến độ; mở thì 044 hiện 38 dòng sinh từ `t7Lots` + fixture BJ-01 — nếu không đủ 38 thì để số thật và sửa chữ ở fixture, ghi mục 10).
   - `KK-260915-02` · "Nhóm vật tư" · "Nguyễn Văn An" · Chờ duyệt (Găng tay thiếu 1 hộp, `unitCost` 65.000 đ — chặng 4).
   - `KK-260830-01` · Toàn kho · Đã xong (khớp, không điều chỉnh).
   - Phiên mới tạo trong kịch bản: mã `KK-260917-{nn}` tăng dần; nhóm **"Thuốc kháng sinh"** (Oxytetracycline LA, Tylosin TY2511, Tylosin TY2408) có trong sheet "Chọn phạm vi" (cùng "Nhóm vật tư", "Nhóm vaccine").
2. `unitCost`: Oxytetracycline LA **55.000 đ/chai** (thêm vào `t7Lots` / fixture chung nếu chặng 4 chưa có); Tylosin 85.000 đ/lọ, Găng tay 65.000 đ/hộp (chặng 4); Dầu sát khuẩn **không có**.
3. Sheet "Thêm hàng thực tế": "Dầu sát khuẩn · SP-00606 · L2406-T" và "Amox 500 · SP-000066" (bỏ Vitamin C, Amox L2501-A).
4. Thành viên: "Nguyễn Văn An" (thay "Nguyễn An"), "Trần Thị Bình", "Chủ cửa hàng". Thời điểm cố định: mở phiên "17/09/2026 18:30", nộp lần đầu "17/09/2026 19:05", gửi đếm lại "17/09/2026 19:20", duyệt "17/09/2026 20:10" (ngày nghiệp vụ `BUSINESS_DATE = '17/09/2026'`).
5. `bj08Seed(screen, state)` (như `io05Seed` / `bj09Seed`): trạng thái đặt từ ngoài (golden / bộ chọn) dựng lại fixture gốc — 044 = phiên mới đã mở, chưa đếm; 045 = đã nộp lần đầu (Oxy 10, TY2511 4, TY2408 11); 046 = `KK-260915-02`; 047 `COMPLETED` = kết quả mẫu của phiên mới. Đi bằng nút thì không seed.

## 4. Bước C1 — danh sách, tạo phiên, đếm (commit 1)

### 4.1 Dữ liệu và trạng thái (`app/bj08.js`)

1. Biến rời `ic08Counts`, `ic08Recounts`, `ic08UnexpectedLine`, `ic08Scope*`, `ic08AssignedCounter`, `bj08RoundNo`, `bj08ContributorNames`, `bj08ResultSnapshot` gom vào phiên đang mở `bj08Current()` (đọc `bj08SelectedId`). Giữ `bj08RoundHistory` qua `__VET45_QA__` (golden đọc) — trả về `rounds` của phiên đang mở.
2. Nguồn K2: `__T7_PENDING_SOURCES__.push({ id:"UIF-08", label:"kiểm kê", needsActivation:true, rows })` — mọi phiên `PENDING`; `__T7_DIRECT_CONTEXTS__["bj08-approval"]` đặt phiên đang duyệt + 046 `READY`. `entry=approver` mở `KK-260915-02`.
3. `bj08CanDecide()` = `["approver", "owner"].includes(currentActor())`; `SELF_APPROVAL_NOT_ALLOWED` khi `!bj08CanDecide()` hoặc người bấm có trong người đếm của phiên mà không phải `owner`.
4. Tiền: `bj08ShowMoney()` = `currentActor() === "owner" || currentActor() === "approver"`; mọi chuỗi tiền dựng qua một hàm, nhân viên trả chuỗi rỗng (không dựng phần tử).
5. Quét: `__VET45_QA__.scanBJ08(code)` (như "Quét thử" của BJ-02) đặt `bj08FocusKey` rồi render; sau render đặt focus vào ô của dòng đó (`requestAnimationFrame`).
6. Xoá mã chết (vấn đề 11): `ic08SessionRow`, nhánh "other" và `CANCEL_REQUEST` của 042, `ic08Evidence`, `ic08ConfirmKind`, `ic08NumericSheet` + `data-ic08-key` / `keypad-*`, các `.replace()` cuối `render042BJ08`, `ac310SanitizeMarkup` / `ac310Return` ở BJ-08 (chữ đã viết lại — đo trước: nếu còn chữ cần lọc thì sửa chữ gốc). Nhãn `data-v350-ic08-*`, `data-v3100-ic08-*`, `data-ic08-*`, `data-v360-action="fallback-exit"` → `data-bj08-*`. Sửa `tools/golden.mjs` theo nhãn mới.

### 4.2 Màn

| Màn | Việc |
|---|---|
| 042 | 0.4 điểm 1–6; `appShell({ extraClass:"k7-wide" })` |
| 043 | 0.4 điểm 7–12; sheet "Chọn phạm vi" dùng `k7FilterChips` / danh sách + ô tìm lọc tại chỗ |
| 044 | 0.4 điểm 13–20 |
| Hub | `renderHubHome`: không đổi chữ; "Chờ duyệt" tự thêm nguồn "kiểm kê" qua `pendingSummary` (kiểm số và chữ "… · 1 kiểm kê") |

### 4.3 Sự kiện

1. `data-bj08-filter` / `data-bj08-search` / `data-bj08-row` (042, lọc tại chỗ như K6 BJ-05).
2. 043: `data-bj08-scope` (dsChoiceRow), `data-bj08-scope-open` / `data-bj08-scope-pick` / `data-bj08-scope-close`, `data-bj08-counter`, `data-bj08-reason`, `data-bj08-action="open" | "confirm-open" | "dialog-close" | "to-valuation"`.
3. 044: `data-bj08-count="{key}"` (input — **không dựng lại cả màn khi gõ**: chỉ cập nhật tiến độ, chip, chân như `syncVerifyButton` của BJ-07; Enter → focus ô kế tiếp), `data-bj08-count-filter`, `data-bj08-find`, `data-bj08-add-open` / `data-bj08-add-pick`, `data-bj08-unexpected-state` (dsSegmented), `data-bj08-action="submit-first" | "confirm-first" | "cancel-open" | "confirm-cancel"`.

## 5. Bước C2 — đếm lại, duyệt, kết quả (commit 2, cùng D)

### 5.1 Màn

045 (0.4 điểm 21–25), 046 (26–30), 047 (31–33). Sự kiện: `data-bj08-recount="{key}"`, `data-bj08-same="{key}"` ("Vẫn {n}"), `data-bj08-matched-open`, `data-bj08-action="submit-recount" | "confirm-recount" | "approve" | "review-open" | "review-close" | "review-confirm" | "approval-result" | "to-list" | "to-stock"`. Sau "Duyệt và điều chỉnh": đi 047 ngay (`PROCESSING` chỉ khi đặt từ ngoài). Toast ngay sau `render()`.

CSS: gom luật BJ-08 (`[data-active-uif="UIF-08"]`, `.ac321-*`, `.ac320-*`, `.ds24-keypad*`, `.ds24-session-*` — `grep` xem chỉ BJ-08 dùng) về khối BJ-08 trong `styles/screens.css`, bỏ `!important` không còn đối thủ (T7-P mục 4.4); xoá luật bàn phím riêng nếu không BJ nào còn dùng (`golden.mjs usage`). Bỏ luật cột 402px của khung web cho UIF-08.

### 5.2 Golden mở thẳng

Bộ chọn trạng thái: 042 bỏ `PENDING_APPROVAL` (0.4 điểm 5). Mọi trạng thái đặt từ ngoài qua `bj08Seed` (mục 3 điểm 5). 046 `READY` mở bằng vai mặc định của golden → phải là `owner` / `approver` để thấy `k2Decision` (nếu golden mở bằng nhân viên thì 046 `READY` thành `PENDING_APPROVAL` — đặt `entry=approver` cho ca `UIF-08_SCR-046_READY`, ghi mục 10).

## 6. Kịch bản golden (`tools/golden.mjs`, `S8 = '?uif=UIF-08&screen='`)

Sửa: `SC_bj08_list` (chip "Đã xong", dòng `KK-260916-01` → 044), `SC_bj08_create` ("Nhóm sản phẩm" → "Chọn phạm vi cụ thể" → "Thuốc kháng sinh" → "Mở phiên kiểm kê" → "Mở phiên"), `SC_bj08_blind` (gõ Oxy 10 → Enter → TY2511 4 → Enter → TY2408 11 → "Nộp kết quả đếm" → "Nộp kết quả"), `SC_bj08_recount` (Oxy "Vẫn 10 chai" → TY2511 3 → gửi → 046 chờ duyệt), `SC_bj08_approve` (`entry=approver` → "Duyệt và điều chỉnh" → 047), `SC_bj08_self_approve` (nhân viên mở 046 `READY` của phiên mình → "Không thể tự duyệt"), `SC_bj08_review` ("Yêu cầu đếm lại" → lý do → xác nhận → 045 lần 2), `SC_bj08_cancel` (nút chữ "Hủy phiên" → lý do → 047 đã hủy), `SC_bj08_unknown`.

| Kịch bản | Bắt đầu | Bước |
|---|---|---|
| `SC_bj08_zero` | `S8 + 'SCR-044'` | gõ đúng số sổ cho cả ba dòng (QA đặt) → nộp → 047 khớp |
| `SC_bj08_scan` | `S8 + 'SCR-044'` | `scanBJ08('SP-000122')` → focus ô TY2511 → gõ 4 → chip "Đã đếm" |
| `SC_bj08_unexpected` | `S8 + 'SCR-044'` | "Thêm hàng thực tế" → "Dầu sát khuẩn" → "Bán được" → 1 → đếm đủ → nộp → 045 (dòng Dầu sát khuẩn thừa 1, `PRICE_BASIS_REQUIRED`) |
| `SC_bj08_price_basis` | `S8 + 'SCR-045&state=PRICE_BASIS_REQUIRED'` | (ảnh) → "Hủy phiên" → lý do → 047 |
| `SC_bj08_owner_self` | `T + 'inventory&entry=owner'` | nút nhanh "Kiểm kê" → tạo phiên → đếm → đếm lại → gửi → Home "Chờ duyệt" → dòng "kiểm kê" → "Duyệt và điều chỉnh" được, 047 "Người duyệt" "Chủ cửa hàng" |
| `SC_bj08_from_home` | `T + 'inventory'` | "Chờ duyệt" → dòng `KK-260915-02` (vai `approver` do dòng gắn) → 046 (có tiền) → quay lại → về "Chờ duyệt" |
| `SC_bj08_pending_view` | `S8 + 'SCR-042'` | chip "Chờ duyệt" → dòng `KK-260915-02` (vai nhân viên) → 046 `PENDING_APPROVAL`, không số tiền |

`T = '?mode=theme&app='`. `WEB_SCENARIOS` thêm `SC_bj08_list`, `SC_bj08_create`, `SC_bj08_blind`, `SC_bj08_recount`, `SC_bj08_approve`, `SC_bj08_from_home`. Chỉ dùng `data-bj08-*` / `data-theme-*` / `data-k*`, không chọn theo chữ.

## 7. Bước D — kiểm

1. Golden mobile / web so mốc mục 2: chỉ ca ở 0.8 khác; ghi mục 10. Mọi trạng thái 0.5 cho ảnh khác nhau (`diff` thân `.txt` trước dòng `@inspector`; hash PNG), cả hai khung.
2. Bấm thử UIF-08 hai khung + Home nút nhanh "Kiểm kê", "Chờ duyệt" + Hub "Kiểm kê kho": 0 lỗi JS; `node --check app/*.js harness/*.js tools/golden.mjs`.
3. **Đếm mù:** HTML của 044 (mọi trạng thái, hai khung) không chứa số sổ của phiên — `grep` số sổ từng dòng (12, 3, 11 cạnh tên sản phẩm) và thuộc tính `data-*` có số sổ; vai nhân viên ở 046 / 047 không có "đ" trong HTML.
4. **`/impeccable audit` phạm vi UIF-08 — chặn commit E.** Chạy trên 042 (READY từng chip, EMPTY, FILTER_EMPTY), 043 (READY trống, đã chọn phạm vi, sheet "Chọn phạm vi", sheet "Mở phiên kiểm kê?", COUNT_SCOPE_HAS_UNRESOLVED_VALUATION chủ / nhân viên, CONFLICT), 044 (trống, đang gõ, VALIDATION_ERROR, hàng thực tế, sheet nộp, sheet hủy, LOCK_LOST), 045 (RECOUNT_REQUIRED, PRICE_BASIS_REQUIRED, sheet dòng khớp), 046 (READY chủ, PENDING_APPROVAL nhân viên, sheet "Yêu cầu đếm lại", SELF_APPROVAL_NOT_ALLOWED, STALE), 047 (COMPLETED chủ / nhân viên, khớp, CANCELLED, UNKNOWN), Home "Chờ duyệt", ở cả hai khung. Đạt khi: chữ ≥ 4,5:1 (badge, phụ đề dòng, dòng lý do ở chân, **nút chữ "Hủy phiên"**, dòng chữ phụ "Số lượng theo sổ…"); vùng chạm ≥ 44 × 44 ở iPhone (ô số trong dòng, "Vẫn {n}", chip cuộn ngang, nút quét, `dsChoiceRow`); thiếu / thừa không chỉ phân biệt bằng màu (có chữ "Thiếu" / "Thừa"); web đi được bằng bàn phím (Tab / Enter dọc cột "Đếm được" và "Đếm lại", Tab tới nút chân; Enter mở / Esc đóng sheet, focus về nút đã mở, Tab không thoát `aria-modal`); web không còn cột 402px; iPhone không bảng ép nhỏ, số và ĐVT không gãy dòng (nối bằng khoảng trắng không ngắt). Lỗi trong phạm vi: sửa ngay; ngoài phạm vi: ghi mục 10.
5. Gửi ảnh: 042 web + iPhone, 043 iPhone (đã chọn nhóm) + sheet "Mở phiên kiểm kê?", 044 iPhone (đang gõ) + web, 045 iPhone + web, 046 web (chủ) + iPhone (nhân viên chờ duyệt), 047 iPhone (chủ), Home "Chờ duyệt" hai khung.
6. Mốc cho plan sau: `tools/.golden-bj08-after` / `tools/.golden-bj08-web-after`.

## 8. Bước E — ghi lại (commit 3)

1. `CHANGELOG.md` `[5.16.0] — BJ-08 thiết kế lại; fixture chung chặng 5`; phiên bản 5.16.0 (`manifest.json`, `harness/workbench.js`, badge `index.html`, nhãn inspector UIF-08). Ghi các trạng thái bỏ khỏi bộ chọn (042 `PENDING_APPROVAL`, `CANCEL_REQUEST`) và lý do.
2. Viết lại theo `_TEMPLATE.md`: SCR-042…047, UIF-08 (sơ đồ mới: K6, "Chờ duyệt", ô số tại dòng, hủy phiên từ nội dung, 047 → BJ-01).
3. T7-P mục 2 bảng "Vị trí trên Home Kho" (dòng "Chờ duyệt" có kiểm kê); mục 6 (ghi `VNumericKeypadSheet` không còn dùng ở Theme 7 sau BJ-02 / BJ-08); mục 9 BJ-08: khuôn "K1, K2, K3, K4, K6, K7".
4. `INDEX.md` 042…047; T7-P mục 13 (chữ mới; tiền ở 046 / 047 cho chủ; trạng thái bỏ; phần BJ-08 của dòng "mọi BJ theo K2": UC-08-04 BR-01 đã ghi ngoại lệ chủ cửa hàng — SCR-046 mục 6 ghi người duyệt `is_owner` / `store_owner`); mục 14: BJ-08 ✅.
5. `python3 tools/sync-registry.py`.

## 9. Thứ tự commit

1. C0 + C1 (fixture chung chặng 5, 042 / 043 / 044, nguồn "Chờ duyệt") — golden khác ở 042–044, Home.
2. C2 + D (045 / 046 / 047, golden mới, sửa sau audit).
3. E (tài liệu, phiên bản, registry).

Như các chặng trước: nếu làm một lượt thì để chưa commit cho phiên review xem trước, chia commit sau review. `detect_changes()` trước mỗi commit (CLAUDE.md).

## 10. Ghi chú khi làm

**Mốc.** Chặng 4 đã review (v5.15.1). `tools/.golden-chang4` **không** khớp HEAD (review chặng 4 đổi 97 / 40 ca có chủ đích), nên chụp lại ở HEAD làm mốc: `tools/.golden-bj08-base` (mobile 1882 ca) / `.golden-bj08-web-base` (web 1020 ca), chụp từ bản sao `git archive HEAD` chạy cổng 8766. Sau khi làm: `tools/.golden-bj08-after` (**1926 ca**) / `.golden-bj08-web-after` (**1051 ca**), 0 lỗi JS ở cả hai khung. **Lưu ý:** `golden.mjs` dùng cổng Chrome cố định 9400+n (và 9500+n cho `usage`) — không chạy hai lần chụp cùng lúc (lần đầu chụp mốc song song với chụp thử đã lẫn kết quả; phải chụp lại tuần tự).

**GitNexus (`impact` upstream, repo `erp-sales-inventory`).** `render042BJ08`, `render046BJ08`: 0 hàm gọi — LOW. `ic08NumericSheet` (7, nội bộ bj08.js), `bj08ConfirmSheet` (5, nội bộ) — LOW, đã xoá. `renderHubHome` (1), `pendingSummary` (3) — LOW, không sửa (nguồn "kiểm kê" đăng ký qua `__T7_PENDING_SOURCES__`). `k2RejectSheet` (3 nơi gọi: BJ-06 / 09 / 10 / 12) — LOW, chỉ **thêm** tham số tuỳ chọn, mặc định cho đúng HTML cũ (ca BJ khác không đổi). `detect_changes()` cuối: 23 tệp, 0 quy trình bị ảnh hưởng, rủi ro thấp.

**Kết quả D.**
1. So mốc: mobile 440 / web 185 dòng khác — **chỉ** `UIF-08_SCR-042…047_*`, `SC_bj08_*`, `SC_entry_UIF-08_*`, `SC_quick_UIF-08`, `SC_banner_046` (046 mở bằng vai nhân viên → "Không thể tự duyệt"; không nằm trong danh sách 0.8 nhưng là hệ quả trực tiếp), chữ inspector "v5.16.0 · BJ-08 thiết kế lại", và mọi ca có Home Kho / "Chờ duyệt" (đã đối chiếu từng dòng chữ khác của các ca ngoài UIF-08: chỉ "… · 1 kiểm kê · …", số "Chờ duyệt" +1, dòng `KK-260915-02 · Nhóm vật tư` / "1 mặt hàng lệch · Nguyễn Văn An gửi 15/09/2026 17:40"). Không ca BJ khác nào đổi chữ hay ảnh (CSS cũng không làm đổi điểm ảnh ca khác).
2. Bấm thử: toàn bộ `SC_bj08_*` (17 kịch bản mobile; 6 kịch bản web) 0 lỗi JS; `node --check app/*.js harness/*.js tools/golden.mjs` đạt.
3. **Đếm mù:** HTML 044 (cả hai khung, `BLIND_COUNT` / `VALIDATION_ERROR`, phiên "Thuốc kháng sinh" và "Toàn kho") không có số sổ trong chữ lẫn thuộc tính `data-*` / `aria-*` (chỉ trùng `cx` / `cy` của biểu tượng SVG); không có chữ "Theo sổ / Chênh lệch / Thiếu / Thừa". Vai nhân viên ở 046 `PENDING_APPROVAL` / 047 `COMPLETED`: không có "đ" nào trong HTML; vai `approver`: có.
4. **Audit (`/impeccable audit` phạm vi UIF-08)** — chạy bằng biểu thức kiểm dọc `AUDIT_JS` (tương phản chữ ≥ 4,5 : 1 — 3 : 1 cho chữ lớn —, vùng chạm ≥ 44 × 44 ở iPhone / ≥ 40 ở web, tràn ngang, thành phần không tên) trên **mọi** ca `UIF-08_*` (38 mobile / 33 web) và `SC_bj08_*` (99 / 32), gồm cả sheet mở (nộp, hủy, yêu cầu đếm lại, chọn phạm vi, thêm hàng thực tế, quét, mặt hàng khớp): **không có lỗi tương phản, vùng chạm, tràn ngang** trong phạm vi BJ-08 (nút chữ "Hủy phiên", "Vẫn {n}", ô số, chip, `dsChoiceRow`, nút quét đều ≥ 44). Hai việc đã sửa: ô "Lý do kiểm kê" và "Người đếm" thiếu tên truy cập (thêm `aria-label`); banner dài ở 045 / 043 bị cắt do chiều cao cố định (`.v-banner` auto cao ở UIF-08). Kiểm bằng phím: Enter đi dọc ô số (chưa đếm trước), Enter ở ô tìm → ô đầu; sheet: focus vào hộp thoại, Esc đóng và trả focus về nút đã mở, Tab không thoát hộp thoại. **Ngoài phạm vi, ghi lại:** nút đóng của toast dùng chung (`toast-close`) cao 20 × 20 — không thuộc BJ-08, không sửa ở đây.
5. Ảnh gửi review: các ảnh nêu ở mục 7.5 nằm trong `tools/.golden-bj08-after` / `-web-after` (`UIF-08_SCR-042_READY`, `SC_bj08_create_*`, `SC_bj08_blind_*`, `SC_bj08_recount_*`, `UIF-08_SCR-046_READY`, `SC_bj08_approve_*`, `SC_bj08_from_home_*`).

**Lệch so với plan / quyết định khi làm.**
- **Fixture "Toàn kho" có 9 mặt hàng, không phải 38** (`t7Lots` + BJ-01 chỉ có chừng đó sản phẩm / lô): `KK-260916-01` hiện "Đã đếm 4/9" (mục 3 điểm 1 đã cho phép "để số thật"). Phạm vi thuộc nhóm: "Thuốc kháng sinh" (Oxytetracycline LA, Tylosin TY2511, TY2408), "Nhóm vật tư" (Găng tay Nitrile, Dầu sát khuẩn), "Nhóm vaccine" (Nobivac DH2507 / DH2509); Amox 500 (không lô và AM2505) chỉ nằm trong "Toàn kho". `unitCost` đặt ngay trong `BJ08_CATALOG` (Oxytetracycline LA 55.000 đ — không thêm vào `t7Lots` vì BJ-09 / 10 tách / ghi giảm theo lô ở đó); Tylosin 85.000, Găng tay 65.000, Amox 42.000, Nobivac 118.000 khớp chặng 4 / BJ-01; Dầu sát khuẩn không có.
- **`CONFLICT` ở 043** chỉ bắt khi trùng đúng loại + tên phạm vi với một phiên đang đếm / chờ duyệt (vd. chọn "Toàn kho" khi `KK-260916-01` đang đếm), để kịch bản "Thuốc kháng sinh" mở được dù có phiên "Toàn kho" đang đếm.
- **046:** dòng "Sau khi duyệt — Tồn kho ghi theo số đếm lại, phạm vi mở khoá" đặt trong khối "Cần chú ý" (dòng thông tin, như BJ-10), **không** ở `facts` như điểm 26 — chữ dài làm hàng nhãn–giá trị bị tràn. "Số lần đếm lại" = số vòng đếm lại đã nộp.
- **045 từ vòng 3:** nhãn "Đếm đầu" / "Vẫn {b}" lấy số đếm **gần nhất** của dòng (vòng đầu = lần đếm đầu); không đổi chữ thành "Đếm trước".
- **Tên sự kiện** theo `data-bj08-action` thống nhất: `add-open`, `scan-open`, `matched-open`, `scope-open`, `dialog-close` (thay `review-close`, `scope-close`), `confirm-review` (thay `review-confirm`).
- **Sheet "Thêm hàng thực tế":** ô tìm lọc tại chỗ, chưa có nút quét riêng (chỉ hai sản phẩm mẫu, đã có quét ở màn 044). Sheet "Quét mã vạch" dùng chữ của BJ-01 ("Đưa mã vạch vào khung", "Quét thử: {tên}"); quét không thấy → toast "Không có trong phạm vi kiểm kê".
- **Chữ mới ngoài mục 13** (đã ghi thêm một dòng vào T7-P mục 13): "Đã đếm hết các mặt hàng." · "Mặt hàng khớp" (sheet) · "Khớp" · "Không tìm thấy sản phẩm / Thử mã, tên hoặc bộ lọc khác." (044) · "Không tìm thấy phạm vi" · "Không còn sản phẩm để thêm" · "Chỉ chủ cửa hàng duyệt kết quả kiểm kê." · "Không có phiên kiểm kê / Mở lại từ danh sách phiên kiểm kê." · "Tải lại để xem bước hiện hành của phiên." · "Chưa chọn tình trạng" · `UNKNOWN` mã tham chiếu "ADJ-{mã phiên}".
- **047 `CANCELLED`:** số liệu "Phiên · Phạm vi · Lý do · Thời điểm" (bỏ "Điều chỉnh: Không tạo" và "Khóa phạm vi: Đã mở" vì mô tả đã nói).
- **`UIF-08_SCR-046_READY`** mở bằng `entry=approver` (nhóm golden riêng — mục 5.2); `UIF-08_SCR-046_APPROVAL_REVIEW` không có trong bộ chọn nên chỉ ca `SC_banner_046` dùng.
- **CSS:** `components.css` / `screens.css` — gỡ luật chỉ của UIF-08 và UIF-08 khỏi các danh sách chỉ có UIF-01 / 02 / 04 / 05 (hình học dòng 370 px); giữ UIF-08 trong các danh sách dùng chung với UIF-09…17 (copy / chip / banner của khung đã thiết kế lại). Xoá `.ds24-keypad*`, `.ds24-session-*`, `.ds24-quantity-trigger` (không BJ nào còn dùng). Còn lại ngoài phạm vi: `ac321CanonicalChips` / `.ac321-chip-wrap` dùng ở BJ-11 / 16.
- **Không làm (như mục 11):** không thêm lối BJ-08 → BJ-11; khoá phạm vi kiểm kê chưa nối sang BJ-01 / BJ-09 (037 `LOCKED` đã có chữ).


## 11. Không làm

- Lối BJ-08 → BJ-11 khi phát hiện phiếu nguồn sai (spec: chỉ sau khi phiên kết thúc; hồ sơ đối soát BJ-16 là đường vào — plan [BJ-16 + BJ-17](T7-P-bj16-bj17-doi-soat.md)).
- Khoá phạm vi kiểm kê hiện ở BJ-01 / BJ-09 (037 `LOCKED` đã có chữ; không nối dữ liệu phiên sang hai BJ đó ở chặng này).
- Lưu nháp số đếm qua nhiều thiết bị, chia nhiều người đếm một phiên (spec một người đếm được phân công).
- Thiết kế lại BJ-03 (lối "Mở hàng chờ xác lập giá trị" chỉ mở màn có sẵn).

## 12. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| Gõ số tại dòng làm dựng lại cả màn, mất focus giữa chừng | Sự kiện `input` chỉ cập nhật tiến độ / chip / chân (4.3 điểm 3); kịch bản `SC_bj08_blind` gõ liên tục ba dòng bằng Enter |
| Số sổ lọt vào DOM 044 qua thuộc tính / bảng tóm tắt | Kiểm D3 bằng `grep` trên HTML; số sổ chỉ đọc trong hàm dựng 045 trở đi |
| Chủ cửa hàng được tự duyệt làm vỡ ca `SELF_APPROVAL_NOT_ALLOWED` | Giữ ca bằng vai nhân viên đã đếm; `SC_bj08_owner_self` kiểm nhánh chủ |
| 38 dòng "Toàn kho" của `KK-260916-01` làm ảnh dài, golden chậm | Ảnh golden chỉ chụp khung nhìn; chip mặc định "Chưa đếm"; nếu fixture không đủ 38 mặt hàng thì dùng số thật |
| Fixture chung chặng 5 lệch dữ liệu chặng 4 (`unitCost`, mã lô) | Rà lại ở mục 2 điểm 2; lệch ghi mục 10, không sửa dữ liệu chặng 4 trong plan này |

## 13. Chữ trên màn

| Vị trí | Chữ |
|---|---|
| 042 | chip "Đã xong" · "{phạm vi} · {người đếm} · Đã đếm {a}/{b}" · "· {k} mặt hàng lệch" · badge "Đếm lại", "Đã xong", "Đã hủy" · cột "Phiên", "Phạm vi", "Đã đếm", "Mở lúc", "Tình trạng" · rỗng "Chưa có phiên kiểm kê" / "Tạo phiên để đếm toàn kho hoặc một nhóm hàng." · "Bạn chưa có quyền kiểm kê" |
| Home | "Chờ duyệt" nguồn "kiểm kê" · "{mã phiên} · {phạm vi}" / "{k} mặt hàng lệch · {người đếm} gửi {lúc}" |
| 043 | "{n} mặt hàng" · "Đổi" · "Khi mở phiên" · "Tạm khoá {n} mặt hàng: không nhận, xuất hay bán được cho tới khi kiểm xong." · "Số theo sổ được chốt lúc mở phiên." · "Trong lúc kiểm, {n} mặt hàng này tạm không nhận, xuất hay bán được." · "Mở hàng chờ xác lập giá trị" · "Phạm vi đang có phiên khác" / "{mã phiên} đang kiểm {phạm vi}. Mở phiên đó hoặc chọn phạm vi khác." / "Mở phiên đang kiểm" · "Nhập lý do kiểm kê" · "Mặt hàng trong phạm vi" · "và {n} mặt hàng khác" |
| 044 | "{mã phiên} · {phạm vi} · {người đếm}" · "Đã đếm {a}/{b} mặt hàng" · "Tìm hoặc quét sản phẩm trong phạm vi" · chip "Chưa đếm", "Đã đếm" · "{mã} · Lô {lô} · {tình trạng}" · cột "Đếm được" · "Tình trạng" · "Còn {n} mặt hàng chưa đếm" · "Chọn tình trạng cho hàng thực tế" · "Không sửa được lần đếm này." · "Nhập số đếm được" · "Phiên không còn hiệu lực" / "Phiên đã bị hủy hoặc đã mở khoá. Số đã đếm vẫn được lưu." · "Người khác vừa nộp phiên này" |
| 045 | "{mã phiên} · Đếm lại lần {n}" · "{k} mặt hàng lệch · {m} khớp" · "Xem {m} mặt hàng khớp" · "Theo sổ {a} · Đếm đầu {b} {ĐVT}" · "Thiếu {d} {ĐVT}" / "Thừa {d} {ĐVT}" · "Vẫn {b} {ĐVT}" · cột "Đếm đầu", "Đếm lại" · "Hàng thừa chưa có giá vốn" / "{sản phẩm} chưa có giá vốn nên chưa duyệt được. Phiên vẫn khoá; chủ cửa hàng cần xác lập giá trị trước." · "Chờ giá vốn của hàng thừa" · "Còn {n} mặt hàng chưa đếm lại" · "Kết quả được lưu thành một lần đếm lại, không sửa được." · toast "Đã gửi chủ cửa hàng duyệt" |
| 046 | "Duyệt điều chỉnh {k} mặt hàng lệch của phiên {mã}?" · "Thiếu {d} {ĐVT} {sản phẩm}" / "Thừa {d} {ĐVT} {sản phẩm}" · "Tổng chênh lệch (không bù trừ): {x} đ" · "Phạm vi" · "Số lần đếm lại" · "Tồn kho ghi theo số đếm lại, phạm vi mở khoá" · cột "Giá trị" · "Yêu cầu đếm lại" (nút) · "Bạn đã đếm phiên này. Chủ cửa hàng sẽ duyệt." |
| 047 | "Phạm vi" · "Thiếu / thừa" "Thiếu {a} · thừa {b} mặt hàng" · "Giá trị điều chỉnh" · "Người duyệt" · "Lý do" · "Xem tồn kho" · K3 "Ghi điều chỉnh kiểm kê" |

## 14. Review

Review chặng 5 (2026-10-25): **đạt sau R1–R3** (v5.18.1) — xem [plan BJ-16 + BJ-17 mục 14](T7-P-bj16-bj17-doi-soat.md#14-review). Phần của BJ-08: không có điểm chặn riêng (R2 dùng số tồn BJ-08 làm chuẩn); góp ý 3 (044 "Bán / được" gãy dòng), 7 ("Kho trung tâm" trong phạm vi K3), 8 (dòng đã đếm vẫn dưới chip "Chưa đếm"). Ghi chú mục 10 về `bj08Visible` (`offsetParent`): không lỗi — phần tử **trong** sheet `position: fixed` vẫn có `offsetParent`; kiểm bàn phím ở mục 10 đã đạt.
