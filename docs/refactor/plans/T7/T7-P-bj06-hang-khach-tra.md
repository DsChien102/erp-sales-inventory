# T7-P · BJ-06 Hàng khách trả — thiết kế lại (bước B–E) + `SC_journey_3`

> Theme: Theme 7 Inventory · Trạng thái: Brief ✅ (duyệt 2026-10-24 — mục 0.10, mọi điểm theo đề xuất) | Plan C–E ✅ (rà lại theo code BJ-04 / 05 khi làm) | Làm ✅ 2026-10-24 (v5.12.0, chưa commit) | Review ⬜
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) mục 8.2 **chặng 3 "Bán và giao"**, BJ cuối chặng. Làm **sau** [BJ-04 / 05](T7-P-bj04-bj05-lay-hang.md) (dùng K6 và fixture chung chặng 3 dựng ở đó).
> Dùng lại K1, **K2** (ngoại lệ lô cần chủ cửa hàng duyệt — UC-06-02), K3, K4, **K6** (dựng ở BJ-05), K7. Không khuôn mới.
> Thiết bị: **cả iPhone và web đều là thiết bị chính** (T7-P mục 2). Nhân viên nhận hàng trả ở quầy (máy tính hoặc iPhone); chủ cửa hàng duyệt ngoại lệ lô lúc ở máy tính hoặc iPhone.
> Hết plan này = **hết chặng 3**: kịch bản `SC_journey_3` (mục 5.4) đi một mạch Home Kho → lấy hàng → giữ hàng → bàn giao → khách trả → phân loại → duyệt ngoại lệ lô → về Home.
> Ước lượng: **~2,25 ngày, 3 commit** (C1 nhận + duyệt; C2 phân loại + kết quả + `SC_journey_3` + D; E). Người làm: bạn. Review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị, chép nguyên văn; **(mới)** = chữ mới, vào T7-P mục 13 ở bước E.

## 0. Brief (bước B, đã duyệt 2026-10-24)

### 0.1 Việc thật

- **Ai, lúc nào:** nhân viên (thủ kho), **vài lần / tuần**, khi khách mang hàng trả lại theo một yêu cầu trả đã được Bán hàng (Theme 5) chấp nhận. Đứng ở quầy, hàng để trước mặt.
- **Cần biết / làm gì — hai mốc:** (1) **Nhận vào:** đếm từng dòng (không quá lượng được nhận), xem lô trên bao bì có đúng lô đã giao không; khác lô → chụp nhãn lô, gửi chủ cửa hàng duyệt; đủ thì ghi nhận (hàng vào "chờ phân loại", chưa bán được). (2) **Phân loại:** mỗi dòng còn bán được, phải cách ly hay đã hỏng; lô đã hết hạn thì hệ thống tự xếp "Hết hạn".
- **Chủ cửa hàng:** duyệt / từ chối ngoại lệ lô từ Home "Chờ duyệt" (K2), xem ảnh nhãn lô trước khi quyết.
- **Quy tắc giữ** (BJ-06, UC-06-01…04 BR-01…06, UIF-06): lượng thực nhận trong `0…lượng được phép nhận` của dòng, nhận ít hơn là hợp lệ, yêu cầu phải có ít nhất một dòng > 0; lô đã giao chỉ đọc; lô thực nhận phải xác định (lô có sẵn hoặc lô mới có HSD theo cấu hình); **sai lô luôn qua duyệt theo từng dòng** (lý do `RETURNED_DIFFERENT_LOT` mặc định hoặc `OTHER` + mô tả, ảnh nhãn lô có khoá nội dung), sửa dữ liệu sau khi gửi → yêu cầu duyệt cũ hết hiệu lực; từ chối chỉ từ chối dòng đó; **duyệt chưa tự ghi nhận** — thủ kho vẫn bấm ghi nhận; ghi nhận cả yêu cầu cùng lúc hoặc không gì; giá trị ghi cùng lúc nhận, phân loại không ghi giá trị lần hai; **tình trạng khách khai chỉ để đối chiếu, không điền sẵn phân loại**; lô chưa hết hạn: Bán được + Cách ly + Hỏng = lượng chờ phân loại; lô hết hạn: toàn bộ "Hết hạn", không ghi đè; combo chỉ tăng tồn thành phần; người duyệt = `is_owner` / role `store_owner`, chủ lập cũng gửi rồi tự duyệt (T7-P mục 2, K2); `UNKNOWN` không gửi lại, chuyển BJ-17.

### 0.2 Luồng hiện tại

Ảnh: `tools/.golden-chang2/UIF-06_*`, `SC_bj06_*`; web `tools/.golden-chang2-web/UIF-06_*@web`.

```text
Hub → Quản lý kho → Nhập, xuất & hoàn trả → "Hàng khách trả" → 030 danh sách ─"Cần nhận"→ 031 Kiểm hàng khách trả
  ─dòng→ 032 Chi tiết hàng trả (gõ số, chọn "Lô DH2507 / Lô khác"; lô khác → mã lô, lý do, ảnh) ─"Xong" / "Lưu ngoại lệ"→ 031
  ─"Gửi ngoại lệ duyệt" (031 chờ) … người duyệt: ?entry=approver → 034 danh sách riêng "Ngoại lệ lô cần duyệt" → chi tiết → "Duyệt ngoại lệ" / "Từ chối"
  ─"Ghi nhận hàng trả"→ 035 "Đã nhận hàng khách trả" ─"Phân loại ngay"→ 033 (mỗi dòng mở sheet ba ô Bán được / Cách ly / Hỏng)
  ─"Hoàn tất phân loại"→ 035 "Đã phân loại hàng trả" ─→ 030
030 ─"Cần phân loại"→ 033 thẳng; ─"Chờ duyệt lô"→ dòng tắt
```

### 0.3 Vấn đề

| # | Màn | Vấn đề |
|---|---|---|
| 1 | 031 / 032 | Kiểm một dòng mất 4–5 chạm (dòng → gõ số → chọn lô → "Xong"), không có "nhận đủ"; dòng 031 chia hai tầng ("Tối đa 3 hộp" ở dòng, "Lô giao DH2507" ở khối dưới) |
| 2 | 031 / 033 | Hai mốc (nhận vào → phân loại) không thấy trên màn: 031 tiêu đề "Kiểm hàng khách trả", 033 "Phân loại hàng trả", không có gì nói đây là bước 1 / 2 của cùng một yêu cầu |
| 3 | 032 | Chữ kỹ thuật: "Ảnh đã khóa nội dung cho approval", "Thay đổi dữ liệu sẽ tạo approval subject mới."; chọn ảnh chỉ có một ô `input file` (iPhone không có "Chụp ảnh" như BJ-02) |
| 4 | 034 | Danh sách duyệt **riêng** "Ngoại lệ lô cần duyệt / Việc dành cho người phê duyệt", không nằm trong Home "Chờ duyệt" (K2); màn quyết định không theo thứ tự K2 (câu hỏi → người gửi → cần chú ý → số liệu); "Ảnh nhãn lô đã được khóa theo evidence version"; duyệt / từ chối xong ở lại cùng màn với banner, không có kết quả rõ |
| 5 | 033 | Mỗi dòng là sheet ba ô số, kể cả khi cả dòng cùng một loại (thường gặp nhất); ảnh `READY` mở yêu cầu **chưa nhận** RET-260827-03: "— hộp · Đã xong", lô hiện "Không theo lô" (lượng `null` bị tính là hợp lệ) |
| 6 | 035 | Tiêu đề lặp (thanh trên "Đã nhận hàng khách trả" + khối kết quả cùng chữ); "Ghi nhận lúc —", "Phân loại lúc —"; `COMPLETED` liệt kê "0 hộp"; `UNKNOWN` không theo K3, có "operation identity" |
| 7 | 030 | Dòng "Chờ duyệt lô" tắt hẳn — thủ kho không mở xem được dòng nào đang chờ; chip không có số |
| 8 | Trạng thái | Golden trùng nhau: 031 `CONFLICT` = `LOCKED` = `SOURCE_CHANGED`, `WAITING_APPROVAL` = `READY`; 032 `VALIDATION_ERROR` / `PENDING_APPROVAL` / `APPROVED_EXCEPTION` / `CONFLICT` / `LOCKED` = `READY`; 033 `VALIDATION_ERROR` = `READY`, `CONFLICT` = `LOCKED`; 034 `TASK_LIST` = `READY` = `APPROVED` = `REJECTED`; 030 `EMPTY` = `READY` |
| 9 | Web | Mọi màn là cột iPhone giữa khung |
| 10 | Fixture | Lô DH2507 HSD "2027-07-31" (BJ-02 chặng 2 và BJ-05 sau C0: 30/11/2026); `BJ06_LOTS` khai lại HSD riêng thay vì dùng lô chung |
| 11 | Mã | Nhãn `data-v394-*`, `data-v360-action="fallback-exit"`; `deniedBody` / `loadingBody` / `ioResult` thay K1 / K4; listener `click` ở pha capture chặn trước listener chung (giữ từ A2) |

### 0.4 Đề xuất

**Luồng mới**

```text
Hub → Nhập, xuất & hoàn trả → "Hàng khách trả" → 030 (K6: chip có số; mở đúng bước; dòng chờ duyệt mở được, chỉ đọc)
  ─"Cần nhận"/"Cần xử lý ngoại lệ"/"Sẵn sàng ghi nhận"→ 031 "Bước 1/2 · Nhận hàng"
      iPhone: dòng → 032 ("Nhận đủ", lô đúng / lô khác) ─"Xong"→ 031
      web: hai cột — trái bảng dòng hàng, phải 032 của dòng đang chọn ("Xong" chọn tiếp dòng chưa kiểm)
      ─có dòng sai lô→ "Gửi ngoại lệ duyệt" → 031 chờ duyệt (K2) … Owner: Home → "Chờ duyệt" → 034 (K2) → "Duyệt ngoại lệ" / "Từ chối"
      ─đủ điều kiện→ "Ghi nhận hàng trả" → 035 (K4) "Đã nhận hàng khách trả" ─"Phân loại ngay"→ 033
  ─"Cần phân loại"→ 033 "Bước 2/2 · Phân loại": mỗi dòng một lựa chọn lớn; "Chia nhiều loại" mới mở ba ô
      ─"Hoàn tất phân loại"→ 035 (K4) "Đã phân loại hàng trả" → "Về Hàng khách trả" / "Xem tồn kho"
```

*SCR-030 Hàng khách trả* — K6 (dựng ở BJ-05)

1. Tiêu đề "Hàng khách trả" + phụ "Yêu cầu trả đủ điều kiện để Kho xử lý" (giữ); ô tìm "Tìm yêu cầu, đơn bán hoặc khách hàng" (giữ); chip có số "Tất cả" · "Cần xử lý" · "Đang chờ" (giữ).
2. Dòng iPhone: tiêu đề mã yêu cầu; phụ "{khách} · {đơn bán}" (giữ); badge = bước đang dở (giữ chữ `io06RefreshRequestState`: "Cần nhận", "Sẵn sàng ghi nhận", "Cần xử lý ngoại lệ", "Cần phân loại", "Chờ duyệt lô"). Web: bảng Yêu cầu · Khách hàng · Đơn bán · Mặt hàng ("{n}") · Tình trạng.
3. Mở đúng bước (K6): "Cần phân loại" → 033; còn lại → 031. **Dòng "Chờ duyệt lô" mở được** → 031 chỉ đọc (khác BJ-05: thủ kho cần thấy dòng nào đang chờ; spec SCR-030 không cấm — 0.10 a).
4. `EMPTY` → `k1Empty` "Chưa có yêu cầu trả cần xử lý" **(mới)** / "Yêu cầu trả hàng được Bán hàng chấp nhận sẽ hiện ở đây." **(mới)**; `FILTER_EMPTY` → `k1Empty` "Không tìm thấy yêu cầu phù hợp" / "Thử từ khóa khác hoặc đổi bộ lọc." (giữ) + "Xem tất cả"; `LOADING` → `k1Loading`; `PERMISSION_DENIED` → `k1Denied({ what:"Bạn chưa có quyền nhận hàng khách trả" (mới), next:"Liên hệ chủ cửa hàng để được cấp quyền." (chữ BJ-05) })` — dùng cho 030…033, 035.

*SCR-031 Kiểm hàng khách trả* (vấn đề 1, 2, 7)

5. Tiêu đề "Kiểm hàng khách trả" (giữ — chữ prototype, spec ghi "Hàng khách trả"; ghi mục 13); phụ "{mã yêu cầu} · {khách}" (thay dòng ngữ cảnh "0/4 đã kiểm"); dòng **"Bước 1/2 · Nhận hàng" (mới)** + thanh tiến độ mảnh **"Đã kiểm {a}/{b} dòng" (mới, theo mẫu BJ-02)**.
6. iPhone: mỗi dòng — tiêu đề tên sản phẩm; phụ **"Lô giao {lô} · được nhận {n} {ĐVT}" (mới; không theo lô: "Không theo lô · được nhận {n} {ĐVT}")**, combo thêm "Thuộc {combo}" (giữ chữ "Thuộc"); bên phải lượng đã kiểm + badge (giữ chữ `io06ReturnLineRow`: "Đã kiểm", "Chờ gửi duyệt", "Chờ duyệt lô", "Đã duyệt", "Bị từ chối"). Bỏ khối "Lô giao" tách riêng.
7. Web (K7 danh sách – chi tiết): `k7Split` — trái `k7Table` Sản phẩm · Lô giao · Được nhận · Thực nhận · Lô thực nhận · Tình trạng; phải: **nội dung 032 của dòng đang chọn** (điểm 9–12), không đổi trang. Chọn dòng = `data-io06-line` (giống iPhone). "Xong" ở cột phải → lưu, chọn dòng chưa kiểm kế tiếp.
8. Chân: có dòng sai lô đủ bằng chứng chưa gửi → "Gửi ngoại lệ duyệt" (giữ); còn lại "Ghi nhận hàng trả" (giữ) + dòng lý do khi tắt (`k4ReasonFooter` dựng ở BJ-05): "Còn {n} dòng chưa kiểm" **(mới)** / "Chờ chủ cửa hàng duyệt ngoại lệ lô" **(mới)** / "Sửa dòng bị từ chối rồi gửi lại" **(mới)**. Giữ ghi chú "Chỉ ghi nhận khi tất cả dòng hợp lệ; tồn kho chưa đổi trong lúc kiểm." (giữ).
9. `WAITING_APPROVAL` (đã gửi ngoại lệ): `k2Pending({ approver:"chủ cửa hàng", sentAt })` + dòng chỉ đọc; không chân (vào lại từ 030 sau khi duyệt). `RETURN_CAP_CHANGED` → banner "Lượng được nhận đã thay đổi" / "Làm mới và kiểm lại từng dòng trước khi tiếp tục." (giữ) + "Làm mới yêu cầu" (giữ). `SOURCE_CHANGED` → `k1Stale({ title:"Yêu cầu đã thay đổi", description:"Làm mới để dùng dữ liệu hiện hành.", actionLabel:"Làm mới yêu cầu" })` (giữ chữ). `CONFLICT` → như `SOURCE_CHANGED` nhưng tiêu đề **"Người khác vừa cập nhật yêu cầu này" (mới)**. `LOCKED` → `k1Locked({ title:"Yêu cầu đang được xử lý" (mới), description:"Đợi lần xử lý hiện tại xong rồi mở lại." (mới) })`.

*SCR-032 Chi tiết hàng trả* (vấn đề 1, 3)

10. Đầu màn: tên sản phẩm + "{mã} · {ĐVT}" (giữ); "Căn cứ trả hàng" (giữ) gọn còn "Được phép nhận lần này" · "Tình trạng khai báo" · "Lô đã giao" (giữ). Ô "Số lượng thực nhận *" (giữ) + nút chữ **"Nhận đủ {n} {ĐVT}" (chữ BJ-02 084)** điền `n` = lượng được phép; lỗi "Không thể nhận vượt {n} {ĐVT} được phép trong yêu cầu hiện tại." (giữ) dưới ô.
11. "Lô thực nhận" (giữ): hai `dsChoiceRow` "Lô {lô giao}" / "Đúng lô đã giao" và "Lô khác" / "Thực nhận khác lô đã giao" (giữ); **không chọn sẵn** (phải nhìn bao bì — UC-06-01 BR-03). Lô khác → "Mã lô thực nhận *" (giữ) + khối lô có sẵn / lô mới (giữ chữ) + phần ngoại lệ: banner "Lô thực nhận khác lô đã giao" / "Cần lý do, ảnh nhãn lô và phê duyệt trước khi ghi nhận." (giữ), "Lý do ngoại lệ" (giữ hai lựa chọn), "Ảnh nhãn lô thực nhận *" (giữ) theo `VFileDropZone` của BJ-02: iPhone "Chụp ảnh" | "Chọn tệp" (chữ BJ-02), web "Kéo tệp vào đây hoặc Chọn tệp" (chữ BJ-12) + ảnh xem trước.
12. Chữ thay: "Ảnh đã khóa nội dung cho approval" → **"Ảnh sẽ gửi kèm yêu cầu duyệt" (mới)**; banner đã duyệt "Thay đổi dữ liệu sẽ tạo approval subject mới." → **"Sửa dòng này thì phải gửi duyệt lại." (mới)**; banner chờ "Dữ liệu đã gửi duyệt đang được khóa." (giữ); bị từ chối: thêm **"Lý do: {lý do}" (chữ BJ-12 071)** dưới "Cập nhật lô hoặc bằng chứng rồi gửi lại." (giữ).
13. Chân: "Xong" (giữ) / "Lưu ngoại lệ" (giữ) qua `k4ReasonFooter`: "Nhập số lượng thực nhận" **(mới)**, "Chọn lô thực nhận" **(mới)**, "Thêm ảnh nhãn lô" **(mới)**. Trạng thái: `VALIDATION_ERROR` = vượt lượng / lô chưa đủ thông tin (lỗi tại ô); `PENDING_APPROVAL` = mọi ô tắt + banner chờ; `APPROVED_EXCEPTION` / `REJECTED_EXCEPTION` = banner tương ứng; `CONFLICT` / `LOCKED` như 031 điểm 9.

*SCR-034 Ngoại lệ lô cần duyệt* — K2 (vấn đề 4)

14. **Lối vào chính = Home "Cần chú ý · Chờ duyệt"**: BJ-06 đăng ký nguồn `{ id:"UIF-06", label:"ngoại lệ lô hàng trả" (mới), rows }` vào `window.__T7_PENDING_SOURCES__` — mỗi ca chờ một dòng "{sản phẩm} · Lô {lô thực nhận}" / "{mã yêu cầu} · {người gửi} gửi {lúc}"; Home đọc "3 nhận hàng · 1 ngoại lệ lô hàng trả". `TASK_LIST` (lối `entry=approver` ở chế độ BJ) giữ, dựng bằng K6 với cùng dòng.
15. `READY` = `k2Decision({ question:"Duyệt nhận lô {lô thực nhận} thay cho lô {lô giao}?" (mới), maker, sentAt, attention:[["Lô thực nhận khác lô đã giao", "{lô thực nhận} · giao {lô giao}"]], facts: Yêu cầu trả · Đơn bán · Khách hàng · Số lượng · "Hạn dùng lô thực nhận" · "Lý do" (giữ nhãn) })` + ảnh nhãn lô (giữ tiêu đề "Ảnh nhãn lô thực nhận"). Web: `k7Split` — trái quyết định, phải ảnh lớn. Bỏ "Ảnh nhãn lô đã được khóa theo evidence version" (không có ảnh thì "Chưa có ảnh nhãn lô" **(mới)**).
16. Chân "Từ chối" | "Duyệt ngoại lệ" (giữ); "Từ chối" → `k2RejectSheet({ title:"Từ chối ngoại lệ" })` (giữ tiêu đề; nút "Xác nhận từ chối" của K2).
17. `APPROVED` / `REJECTED` → K4 trong 034: "Đã duyệt ngoại lệ" / "Đã từ chối ngoại lệ" (giữ) + câu **"Thủ kho ghi nhận hàng trả khi tất cả dòng hợp lệ." (mới)** / "Lý do: {lý do}" (giữ); `facts` Yêu cầu trả · Người duyệt "Chủ cửa hàng" (chữ BJ-12); chân "Về danh sách phê duyệt" (giữ; về Home "Chờ duyệt" ở chế độ Toàn Theme 7, về `TASK_LIST` ở chế độ BJ). `PERMISSION_DENIED` → `k1Denied({ what:"Bạn chưa có quyền duyệt ngoại lệ lô" (mới), next:"Chỉ chủ cửa hàng duyệt ngoại lệ lô hàng trả." (mới) })`; người lập không phải `is_owner` tự mở ca mình → `SELF_APPROVAL_NOT_ALLOWED` theo K2 (như BJ-12 SCR-070).

*SCR-033 Phân loại hàng trả* (vấn đề 5)

18. Tiêu đề "Phân loại hàng trả" (giữ); phụ "{mã yêu cầu} · {khách}"; **"Bước 2/2 · Phân loại" (mới)** + thanh tiến độ "Đã phân loại {a}/{b} dòng" **(mới)**.
19. iPhone: mỗi dòng (sản phẩm · "Lô {lô}" · lượng) mở sheet; sheet = "Tình trạng khai báo: {…}. Đây chỉ là thông tin đối chiếu." (giữ) + **bốn `dsChoiceRow`**: "Bán được" / "Cách ly" / "Hỏng" (giữ nhãn) — chọn = **cả {n} {ĐVT}** vào loại đó (mô tả **"Cả {n} {ĐVT}" (mới)**) — và **"Chia nhiều loại" (mới)** mở ba ô số "Bán được" / "Cách ly" / "Hỏng" (giữ) + "Đã phân loại {a}/{n} {ĐVT}" (giữ); không chọn sẵn (UC-06-01 BR-06). "Xong" (giữ). Lô hết hạn: dòng chỉ đọc "Hết hạn · hệ thống xác định" (giữ), sheet banner "Lô đã hết hạn" (giữ).
20. Web: `k7Table` Sản phẩm · Lô · Số lượng · Phân loại (`dsSegmented` "Bán được" | "Cách ly" | "Hỏng" | "Chia") · Bán được · Cách ly · Hỏng (`k7EditCell`, chỉ sửa được khi "Chia"); dòng hết hạn chỉ đọc. Không cộng khác ĐVT thành một tổng (BR-06).
21. Chân "Hoàn tất phân loại" (giữ) + lý do "Còn {n} dòng chưa phân loại" **(mới)**. `VALIDATION_ERROR` = tổng chia ≠ lượng (banner "Vượt lượng cần phân loại" giữ / thiếu: **"Còn {n} {ĐVT} chưa phân loại" (mới)**). `SOURCE_CHANGED` → `k1Stale` "Dữ liệu hàng trả đã thay đổi" / "Về danh sách để mở lại dữ liệu hiện hành." / "Về Hàng khách trả" (giữ); `CONFLICT` / `LOCKED` như 031 điểm 9. Ảnh trạng thái mở thẳng dùng yêu cầu **đã nhận** (RET-260827-05), lượng `null` không bao giờ tính là xong.

*SCR-035 Kết quả hàng trả* — K4 (vấn đề 6)

22. `RECEIVED_PENDING_CLASSIFICATION`: `k4Result({ screenTitle:"Kết quả hàng trả" (tên spec, hết lặp), title:"Đã nhận hàng khách trả", description:"Hàng đang chờ phân loại; chưa tự trở lại bán được." (giữ) })`; `facts` Yêu cầu trả · Đơn bán · "Ghi nhận lúc" (**điền thật**) · **"Người nhận" (mới)**; "Xem {n} dòng hàng" (chữ BJ-02) mở sheet "Hàng đã nhận" (giữ); chân "Để sau" | "Phân loại ngay" (giữ).
23. `COMPLETED`: "Đã phân loại hàng trả" / "Chỉ phần đủ điều kiện mới trở lại khả dụng." (giữ); `facts` Yêu cầu trả · Đơn bán · "Phân loại lúc" (điền thật) + mỗi loại có lượng > 0 một dòng theo sản phẩm / lô (bỏ dòng "0 hộp"); "Xem {n} dòng hàng" mở "Kết quả theo sản phẩm và lô" (giữ); chân phụ **"Xem tồn kho" (chữ BJ-02)** → BJ-01 | chính "Về Hàng khách trả" (giữ). Có cách ly / hỏng → thêm dòng thông tin **"Hàng cách ly / hỏng chờ xử lý ở Hàng cần xử lý." (mới)** (lối sang BJ-09 nối ở chặng 4).
24. `UNKNOWN` → `k3Unknown({ operation:"Nhận hàng khách trả" (mới), scope:"{mã yêu cầu} · {đơn bán}", ref: operationId, sentAt, safe:"Không gửi lại thao tác. Chuyển đúng lần ghi nhận này sang xác minh." (mới, thay câu có "operation identity"), sourceFlow:"UIF-06" })`; giữ `onUnknownHandoff["UIF-06"]`. `REJECTED_EXECUTION` → K4 cảnh báo "Chưa thể ghi nhận" (giữ) + nút giữ. `PERMISSION_DENIED` → `k1Denied`.

### 0.5 Trạng thái (sau thiết kế lại)

| Màn | Trạng thái | Hiện gì | Làm được gì | Lối ra |
|---|---|---|---|---|
| 030 | READY | K6: chip có số, danh sách / bảng | lọc, tìm, mở đúng bước (cả dòng chờ duyệt) | Về Kho |
| 030 | EMPTY / FILTER_EMPTY | `k1Empty` | "Xem tất cả" (FILTER_EMPTY) | Về Kho |
| 030…035 | LOADING / PERMISSION_DENIED | K1 | — | "Về Kho" |
| 031 | READY | bước 1/2, tiến độ, dòng hàng (web + chi tiết bên phải) | kiểm dòng, "Gửi ngoại lệ duyệt" / "Ghi nhận hàng trả" | Quay lại |
| 031 | WAITING_APPROVAL | `k2Pending`, dòng chỉ đọc | — | Quay lại |
| 031 | RETURN_CAP_CHANGED / SOURCE_CHANGED / CONFLICT | banner / `k1Stale` | "Làm mới yêu cầu" | Quay lại |
| 031 | LOCKED | `k1Locked` | — | Quay lại |
| 032 | READY / VALIDATION_ERROR | ô số + "Nhận đủ", lô; lỗi tại ô | "Xong" / "Lưu ngoại lệ" | Quay lại |
| 032 | PENDING_APPROVAL | ô tắt + banner chờ | — | Quay lại |
| 032 | APPROVED_EXCEPTION / REJECTED_EXCEPTION | banner + lý do | sửa, lưu lại | Quay lại |
| 032 | CONFLICT / LOCKED | như 031 | — | Quay lại |
| 034 | TASK_LIST | K6 ca chờ | mở ca | Về Kho |
| 034 | READY | K2 quyết định + ảnh | "Duyệt ngoại lệ", "Từ chối" | Quay lại |
| 034 | APPROVED / REJECTED | K4 | "Về danh sách phê duyệt" | Về Kho |
| 033 | READY / VALIDATION_ERROR | bước 2/2, dòng + lựa chọn lớn | phân loại, "Hoàn tất phân loại" | Quay lại |
| 033 | EXPIRED_GUARD | dòng hết hạn chỉ đọc | — | Quay lại |
| 033 | SOURCE_CHANGED / CONFLICT / LOCKED | `k1Stale` / `k1Locked` | "Về Hàng khách trả" | Quay lại |
| 035 | RECEIVED_PENDING_CLASSIFICATION | K4 | "Phân loại ngay", "Để sau" | Về Kho |
| 035 | COMPLETED | K4 | "Xem tồn kho", "Về Hàng khách trả" | Về Kho |
| 035 | REJECTED_EXECUTION | K4 cảnh báo | nút giữ | Về Kho |
| 035 | UNKNOWN | K3 | "Chuyển sang xác minh" | "Về Kho" |

### 0.6 Khuôn dùng lại (không dựng mới)

K1 (`k1Loading`, `k1Denied`, `k1Empty`, `k1Stale`, `k1Locked`, `k1ExitAttr`), **K2** (`k2Pending`, `k2Decision`, `k2RejectSheet`, nguồn `__T7_PENDING_SOURCES__`), K3 (`k3Unknown`), K4 (`k4Result`, `k4Footer`, `k4ReasonFooter`), **K6** (`k6TaskList`), K7 (`k7Split`, `k7Table`, `k7EditCell`), `dsChoiceRow` (lô thực nhận, phân loại), `dsSegmented` (phân loại web), `VFileDropZone` biến thể iPhone của BJ-02, thanh tiến độ mảnh BJ-02. **Chuyển `io06SelectionRow` sang `dsChoiceRow`** (T7-P mục 5: CAP-01 chép từ `io06SelectionRow`, "chuyển sang khi tới lượt, chặng 3").

### 0.7 Không đổi

Quy tắc ở 0.1; `io06LineApprovalState`, `io06SnapshotMatches`, `io06InvalidateCaseIfChanged`, `io06CreateCase`, `bj06SubjectHash`, `bj06ResolveLot`, `bj06IsExpired`, `io06ClassValid` (chỉ sửa: lượng `null` không hợp lệ), `io06ReceiptReady`, `io06RequestCanSubmitExceptions`, các khoá `commit-receipt` / `confirm-classification` / `approve-exception` / `confirm-reject`; `onUnknownHandoff["UIF-06"]`, `bumpIO06Source`. Chữ giữ: tiêu đề 030 / 031 / 032 / 033 / 034 / 035 (034 trong chế độ BJ), "Căn cứ trả hàng", "Được phép nhận lần này", "Tình trạng khai báo", "Lô đã giao", "Số lượng thực nhận *", "Lô thực nhận", "Đúng lô đã giao", "Lô khác", "Thực nhận khác lô đã giao", "Mã lô thực nhận *", "Lý do ngoại lệ", "Khách trả lô khác lô đã giao", "Ảnh nhãn lô thực nhận *", "Lưu ngoại lệ", "Xong", "Gửi ngoại lệ duyệt", "Ghi nhận hàng trả", "Duyệt ngoại lệ", "Từ chối ngoại lệ", "Đã duyệt ngoại lệ", "Đã từ chối ngoại lệ", "Bán được", "Cách ly", "Hỏng", "Hết hạn · hệ thống xác định", "Lô đã hết hạn", "Hoàn tất phân loại", "Đã nhận hàng khách trả", "Phân loại ngay", "Để sau", "Đã phân loại hàng trả", "Về Hàng khách trả".

### 0.8 Kiểm (bước D)

- Golden **mobile** được khác: `UIF-06_*`, `SC_bj06_*`, `SC_entry_UIF-06_*`, **mọi ca có Home Kho đã kích hoạt chỉ ở dòng "Cần chú ý · Chờ duyệt"** ("3 nhận hàng" → "3 nhận hàng · 1 ngoại lệ lô hàng trả", số 3 → 4: `SC_quick_*` bước 0, `SC_ws_*` bước 0 / home, `SC_journey_1` bước cuối, `SC_journey_2`, ca Hub) — `diff` thân `.txt` phải chỉ khác dòng đó; `SC_bj17_from_*` khớp. Ca BJ-04 / 05 khớp mốc `tools/.golden-bj05-after`.
- Golden **web** được khác: `UIF-06_*@web`, ca Home như trên + kịch bản web mới; ca khác khớp `tools/.golden-bj05-web-after`.
- Kịch bản (mục 5.3): sửa `SC_bj06_*` theo selector mới; thêm `SC_bj06_full`, `SC_bj06_split`, `SC_bj06_exception_submit`, `SC_bj06_owner_approve`, `SC_bj06_after_approval`, `SC_bj06_waiting_open`, **`SC_journey_3`** (mục 5.4).

### 0.9 Ước lượng C–E

~2,25 ngày: C1 030 / 031 / 032 / 034 + nguồn "Chờ duyệt" ~0,9; C2 033 / 035 ~0,5; `SC_journey_3` ~0,3; D ~0,25; E ~0,3. (T7-P mục 8.2 ghi 1,5 khi còn chia thiết bị chính / phụ.)

### 0.10 Đã chốt khi duyệt brief (2026-10-24): **mọi điểm theo cột "Đề xuất"**

| # | Điểm | Đề xuất | Phương án khác |
|---|---|---|---|
| a | Dòng "Chờ duyệt lô" ở 030 | **Mở được, chỉ đọc** (031 `WAITING_APPROVAL`, thấy dòng nào chờ, gửi lúc nào) | Giữ tắt như BJ-05 (quy tắc SCR-025 v2.7.3) |
| b | Duyệt ngoại lệ lô | **Gom vào Home "Chờ duyệt" (K2)**; 034 `TASK_LIST` chỉ còn cho lối `entry=approver` ở chế độ BJ | Giữ danh sách riêng "Ngoại lệ lô cần duyệt" |
| c | Phân loại cả dòng | **Lựa chọn lớn "Bán được / Cách ly / Hỏng" = cả dòng, "Chia nhiều loại" mới mở ba ô**; không chọn sẵn | Giữ ba ô số cho mọi dòng; hoặc chọn sẵn "Bán được" (trái UC-06-01 BR-06 nếu hiểu "không điền sẵn" rộng) |
| d | Web 031 + 032 | **Một trang hai cột** (K7 danh sách – chi tiết): trái bảng dòng, phải chi tiết dòng đang chọn | Bảng sửa tại dòng (ô số + lô) và chỉ mở hộp thoại khi "Lô khác" |
| e | "Bước 1/2 · Nhận hàng" / "Bước 2/2 · Phân loại" | **Thêm** (hai mốc của BJ-06 hiện ra trên màn) | Chỉ đổi tiêu đề, không có dòng bước |
| f | Lô thực nhận | **Không chọn sẵn** "Lô {lô giao}" (phải nhìn bao bì) | Chọn sẵn lô đã giao, đổi khi khác |

---

## 1. Mục tiêu

1. Kiểm một dòng đúng lô còn 3 chạm (dòng → "Nhận đủ" → "Lô {lô}" → "Xong" ở iPhone; web không đổi trang).
2. Hai mốc nhận vào / phân loại thấy rõ; phân loại cả dòng một chạm.
3. Ngoại lệ lô đi đúng K2: chủ cửa hàng duyệt từ Home "Chờ duyệt", thủ kho thấy trạng thái chờ và quay lại ghi nhận.
4. Mọi trạng thái 0.5 dựng khác nhau và có lối ra, ở cả hai khung.
5. Chặng 3 chạy một mạch: `SC_journey_3` ở cả hai khung.

## 2. Chuẩn bị

1. BJ-04 / 05 đã xong (K6 `k6TaskList`, `k4ReasonFooter`, fixture C0). Rà lại 0.4 và mục 3 với code thật của K6; K6 cần chỉnh để mở dòng chờ (0.10 a) thì chỉnh ở `shared-patterns.js`, chạy lại golden BJ-05, ghi CHANGELOG.
2. Mốc = `tools/.golden-bj05-after` / `tools/.golden-bj05-web-after`; nếu chưa có, chụp ở HEAD và so khớp.
3. GitNexus: `impact` upstream cho `render030BJ06`…`render035BJ06`, `io06ClassValid`, `io06RefreshRequestState`, `openDirect` / `applyDirectContext` (hub), và mảng `__T7_PENDING_SOURCES__` (đổi số "Chờ duyệt" trên Home); ghi mức rủi ro mục 8.
4. Máy chủ `python3 -m http.server 8765 --bind 127.0.0.1 &` trong `html/`.

## 3. Bước C1 — nhận hàng trả, ngoại lệ, duyệt (commit 1)

### 3.1 Fixture (`app/bj06.js`)

1. `BJ06_LOTS.DH2507.expiryDate` → `'2026-11-30'` (khớp BJ-02 / BJ-05 sau C0); DH2509 `'2027-09-30'`, DH2408 (đã hết hạn, ca `EXPIRED_GUARD`) giữ. Ngày nghiệp vụ `BJ06_BUSINESS_DATE` giữ 2026-09-16 (DH2507 chưa hết hạn).
2. RET-260827-03 (Phòng khám Minh Tâm, SO-260812-44): giữ bốn dòng — đường chính của `SC_journey_3`.
3. EX-06-001 (RET-260827-07, Nhà thuốc thú y Hòa Bình, lô DH2509 thay DH2507, người gửi "Nguyễn Minh · Thủ kho", 03/09/2026 09:18): giữ — là ca "Chờ duyệt" trên Home.
4. Thời điểm hiển thị: `recordedAt` / `classifiedAt` dùng `bj06IsoNow()` (cố định) cho cả ảnh trạng thái mở thẳng (hết "—").
5. Ảnh trạng thái `SCR-033_*` mở thẳng → chọn RET-260827-05 (đã nhận); `SCR-035_RECEIVED_PENDING_CLASSIFICATION` mở thẳng → RET-260827-03 với lượng = lượng được phép, lô = lô giao (dựng sẵn bằng một hàm `bj06SeedReceived(reqId)` chỉ dùng khi mở thẳng).

### 3.2 Màn

| Màn | Việc |
|---|---|
| Chung | `appShell({ …, extraClass:"k7-wide" })`; K1 thay `deniedBody` / `loadingBody`; `io06SelectionRow` → `dsChoiceRow`; đổi `data-v394-*` → `data-bj06-*`, `data-v360-action="fallback-exit"` → `k1ExitAttr` (sửa `tools/golden.mjs`); listener `click` bỏ pha capture nếu không còn đối thủ (đo bằng golden), không thì giữ và ghi mục 8 |
| 030 | `k6TaskList` theo 0.4 điểm 1–4; `rowAttr` mọi dòng có `data-io06-request` + `data-io06-target` (031 / 033), kể cả dòng chờ (0.10 a) |
| 031 | 0.4 điểm 5–9; iPhone danh sách; web `k7Split` trái bảng / phải `bj06LineDetail(line)` (phần thân của 032 tách thành hàm, 032 iPhone gọi lại); chân `k4ReasonFooter` |
| 032 | 0.4 điểm 10–13; `data-io06-fill-max` ("Nhận đủ"); `VFileDropZone` theo `bj02EvidenceZone` (chép cấu trúc, nhãn `data-io06-evidence-*`; "Chụp ảnh" ở prototype mở cùng ô chọn tệp `accept="image/*" capture`) |
| 034 | 0.4 điểm 14–17; `k2Decision` + `k2RejectSheet`; `TASK_LIST` = `k6TaskList` với dòng ca chờ |
| Hub | Không sửa `WORKSPACES`; Home tự đọc nguồn "Chờ duyệt" mới |

### 3.3 Nguồn "Chờ duyệt" và lối vào trực tiếp

1. Cuối `bj06.js`: `(window.__T7_PENDING_SOURCES__ ||= []).push({ id:"UIF-06", label:"ngoại lệ lô hàng trả", rows:() => io06ApprovalCases.filter(c => c.status === "PENDING").map(c => ({ title, subtitle, icon:"rotate", attrs:`data-theme-entry-flow="UIF-06" data-t380-target-screen="SCR-034" data-t380-context="bj06-approval:${c.id}" data-theme-entry-actor="approver"` })) })` — nạp trước `hub.js` như `bj12.js:311`.
2. `hub.js` `openDirect`: thêm **móc chung** `window.__T7_DIRECT_CONTEXTS__` — `{ [tiền tố]: (giá trị) => void }`, BJ đăng ký; `openDirect` tách `context` theo dấu `:`, gọi móc nếu có, không có thì chạy nhánh BJ-02 như cũ. BJ-06 đăng ký `"bj06-approval": (caseId) => { io06SelectedApprovalCaseId = caseId; io06ApproverListMode = false; io06RejectOpen = false; stateByScreen["SCR-034"] = "READY"; }`. Không chuyển nhánh BJ-02 (ngoài phạm vi; ghi mục 8 nếu muốn gom sau).
3. Sau "Duyệt ngoại lệ" / "Xác nhận từ chối": `io06AfterApprovalDecision` (giữ) → 034 `APPROVED` / `REJECTED` (K4). "Về danh sách phê duyệt": chế độ Toàn Theme 7 → Home danh sách "Chờ duyệt" (cùng đích nút "Chờ duyệt" của Hub); chế độ BJ → `TASK_LIST`.
4. Thủ kho mở lại RET-260827-07 từ 030: dòng "Sẵn sàng ghi nhận" (đã duyệt) → 031 → "Ghi nhận hàng trả" (UIF-06-T08: duyệt chưa tự ghi).

### 3.4 Sự kiện

1. `data-io06-fill-max` → `line.qty = bj06LineMax(line)`, `io06SetLineDirty(line)`, render; focus giữ ở ô số.
2. Web 031: `data-io06-line` không `navigate` mà đặt `io06ActiveLineId` + render (cột phải đổi); `save-return-line` / `save-return-exception` ở web chọn dòng chưa kiểm kế tiếp thay vì `navigate("SCR-031")`.
3. Lựa chọn lô (`dsChoiceRow`) giữ khoá `data-io06-select-actual-lot` / `data-io06-select-other-lot`.

## 4. Bước C2 — phân loại, kết quả (commit 2, cùng `SC_journey_3` và D)

### 4.1 Màn

| Màn | Việc |
|---|---|
| 033 | 0.4 điểm 18–21; nháp phân loại thêm `mode: "SELLABLE" \| "QUARANTINE" \| "DAMAGED" \| "SPLIT" \| null` (chọn một loại → ba lượng tự điền: cả dòng vào loại đó, hai loại kia 0; `SPLIT` mở ô số); `data-io06-class-mode="{mode}"`; `io06ClassValid`: `qty` phải là số (`null` → không hợp lệ) |
| 035 | 0.4 điểm 22–24; `k4Result` / `k3Unknown`; sheet "Xem {n} dòng hàng" (khuôn sheet BJ-03 019) dùng `io06ResultGroupsHtml` (lọc bỏ lượng 0); "Xem tồn kho" → `applyEntry("UIF-01", …)` như BJ-02 012 |

### 4.2 Sự kiện

1. `data-io06-class-mode` → đặt `mode` + ba lượng trong `io06ClassificationDraft`, render; `SPLIT` giữ lượng đang có.
2. Web 033: `dsSegmented` cùng khoá `data-io06-class-mode` kèm `data-io06-class-line`; `k7EditCell` cùng khoá `data-io06-class` (giữ) — sửa ngay vào `line.classification`, không sheet.

## 5. Golden và `SC_journey_3`

### 5.1 Golden mở thẳng

Mọi trạng thái 0.5 mở thẳng (`?uif=UIF-06&screen=…&state=…`) dựng khác nhau (vấn đề 8): fixture mục 3.1 điểm 4–5; `CONFLICT` / `LOCKED` / `SOURCE_CHANGED` khác chữ; 034 `TASK_LIST` / `READY` / `APPROVED` / `REJECTED` khác khung.

### 5.2 Kịch bản sửa

`SC_bj06_line`, `SC_bj06_other_lot`, `SC_bj06_receipt`, `SC_bj06_classify`, `SC_bj06_approve`, `SC_bj06_reject`, `SC_bj06_approver_entry`: đổi selector (`dsChoiceRow`, `data-bj06-*`, `data-io06-class-mode`).

### 5.3 Kịch bản thêm (`U` = `'?uif=UIF-06&screen='`)

| Kịch bản | Bắt đầu | Bước |
|---|---|---|
| `SC_bj06_full` | `U + 'SCR-030'` | RET-260827-03 → dòng 1 → "Nhận đủ 3 hộp" → "Lô DH2507" → "Xong" → (iPhone) 031 "Đã kiểm 1/4 dòng" |
| `SC_bj06_split` | `U + 'SCR-030'` | RET-260827-05 → dòng Nobivac → "Chia nhiều loại" → Bán được 3, Cách ly 1 → "Xong" → Găng tay → "Bán được" → "Hoàn tất phân loại" → 035 |
| `SC_bj06_exception_submit` | `U + 'SCR-030'` | RET-260827-03 → dòng 1 → "Lô khác" → mã "DH2509" → (đặt ảnh bằng `window.__VET45_QA__.setIO06Evidence(lineId)` — thêm hàm QA, ảnh SVG mẫu như `io06EvidenceSvg`) → "Lưu ngoại lệ" → kiểm 3 dòng còn lại → "Gửi ngoại lệ duyệt" → 031 `k2Pending` |
| `SC_bj06_owner_approve` | `T + 'inventory'` | "Chờ duyệt" → dòng EX-06-001 → 034 K2 → "Duyệt ngoại lệ" → K4 "Đã duyệt ngoại lệ" |
| `SC_bj06_after_approval` | `U + 'SCR-034&state=TASK_LIST'` | ca EX-06-001 → "Duyệt ngoại lệ" → "Về danh sách phê duyệt" → (chuyển `UIF-06` `SCR-030`) → RET-260827-07 "Sẵn sàng ghi nhận" → "Ghi nhận hàng trả" → 035 |
| `SC_bj06_waiting_open` | `U + 'SCR-030'` | chip "Đang chờ" → RET-260827-07 → 031 chờ duyệt (chỉ đọc) |

`WEB_SCENARIOS` thêm `SC_bj06_full`, `SC_bj06_split`, `SC_bj06_owner_approve`, `SC_journey_3`.

### 5.4 `SC_journey_3` — hết chặng 3

Bắt đầu `T + 'inventory'` (kho đã kích hoạt). Vai: lối "Lấy hàng" và "Hàng khách trả" đặt `module` (nhân viên); dòng "Chờ duyệt" đặt `approver` (K2). Chỉ dùng `data-io05-*` / `data-bj04-*` / `data-io06-*` / `data-bj06-*` / `data-theme-*`.

| Bước | Thao tác | Thấy |
|---|---|---|
| 0 | — | Home Kho; "Cần chú ý · Chờ duyệt" "3 nhận hàng · 1 ngoại lệ lô hàng trả" |
| 1 | "Lấy hàng" (nút nhanh) | 025: SO-260827-21 "Đang lấy hàng", chip "Chờ bàn giao 1" |
| 2 | SO-260827-21 | 026 "Đã lấy đủ 0/2 mặt hàng"; Nobivac lô DH2507 "HSD 30/11/2026" |
| 3 | "Xem giữ hàng" | 021 "Đơn SO-260827-21 · Đại lý An Phú"; Nobivac đang giữ 20 hộp |
| 4 | "Lấy hàng" | 026 cùng đơn |
| 5 | "Lấy đủ" DH2509 → "Lấy đủ" Găng tay | 026 "Đã lấy đủ 2/2 mặt hàng" |
| 6 | "Rà soát bàn giao" | 028 "Giao lần này 2 mặt hàng", "Còn lại sau lần này 0 mặt hàng" |
| 7 | "Xác nhận đã bàn giao" | 029 "Đã bàn giao toàn bộ", "Bàn giao lúc 16/09/2026 13:08" |
| 8 | Về Home (như `SC_journey_2` bước 11) → Quản lý kho → Nhập, xuất & hoàn trả → "Hàng khách trả" | 030, RET-260827-03 "Cần nhận" |
| 9 | RET-260827-03 → mỗi dòng: "Nhận đủ" → lô giao (dòng có lô) → "Xong" (×4) | 031 "Đã kiểm 4/4 dòng" |
| 10 | "Ghi nhận hàng trả" | 035 "Đã nhận hàng khách trả", "Ghi nhận lúc" có giờ |
| 11 | "Phân loại ngay" → 3 dòng "Bán được", Amox 500 "Cách ly" → "Hoàn tất phân loại" | 035 "Đã phân loại hàng trả"; dòng "Hàng cách ly / hỏng chờ xử lý ở Hàng cần xử lý." |
| 12 | Về Home → "Chờ duyệt" → ngoại lệ lô EX-06-001 | 034 "Duyệt nhận lô DH2509 thay cho lô DH2507?" |
| 13 | "Duyệt ngoại lệ" | K4 "Đã duyệt ngoại lệ" |
| 14 | Về Home | Home Kho; "Chờ duyệt" "3 nhận hàng" |

Chạy ở cả hai khung (`SC_journey_3@web`). Đổi vai giữa chừng mà Hub chưa đặt được → `window.__VET45_QA__.setActor(...)` ngay trước bước đó, ghi mục 8 (như `SC_journey_2`).

## 6. Bước D — kiểm

1. Golden mobile / web so mốc mục 2: chỉ ca ở 0.8 khác; ca Home chỉ khác dòng "Chờ duyệt" (`diff` thân `.txt`); ghi mục 8. Mọi trạng thái 0.5 cho ảnh khác nhau, đặc biệt các cặp trùng ở vấn đề 8.
2. Bấm thử UIF-06 hai khung + Home "Chờ duyệt": 0 lỗi JS; `node --check app/*.js harness/*.js`.
3. **`/impeccable audit` phạm vi UIF-06 — chặn commit E.** Chạy trên 030 (READY, FILTER_EMPTY), 031 (READY web hai cột, WAITING_APPROVAL, RETURN_CAP_CHANGED), 032 (READY, lô khác + ảnh, PENDING_APPROVAL, REJECTED_EXCEPTION), 034 (TASK_LIST, READY, sheet từ chối, APPROVED), 033 (READY, sheet lựa chọn, "Chia nhiều loại", EXPIRED_GUARD), 035 (RECEIVED_PENDING_CLASSIFICATION, COMPLETED, UNKNOWN), ở cả hai khung. Đạt khi: chữ ≥ 4,5:1 (badge, chữ phụ, dòng lý do, banner); vùng chạm ≥ 44 × 44 ở iPhone (`dsChoiceRow`, "Nhận đủ", "Chụp ảnh"); ảnh nhãn lô có `alt`; tình trạng không chỉ bằng màu; web đi được bằng bàn phím (Tab bảng trái → cột phải → "Xong"; `dsSegmented` bằng phím mũi tên hoặc Tab; Esc đóng sheet / hộp thoại, focus về nút đã mở; Tab không thoát hộp thoại `aria-modal`); web không còn cột 402px; iPhone không bảng ép nhỏ. Lỗi trong phạm vi: sửa ngay; ngoài phạm vi: ghi mục 8.
4. **Hết chặng 3:** `SC_journey_3` 0 lỗi ở cả hai khung; Home Kho đã nối lối vào của BJ-05 (nút nhanh "Lấy hàng"), BJ-04 (qua 026), BJ-06 (Nhập, xuất & hoàn trả; "Chờ duyệt") — T7-P mục 4.2b. **`/impeccable audit` chạy lại một lượt cho cả đường `SC_journey_3`** (chuyển màn giữa ba BJ, 026 ↔ 021, nút quay lại, thanh bên web, đổi vai ở "Chờ duyệt").
5. Gửi ảnh: 030 web, 031 web (hai cột) + iPhone, 032 lô khác iPhone, 034 web + iPhone, 033 web + sheet iPhone, 035 hai kết quả; `SC_journey_3` bước 0 / 3 / 7 / 9 / 11 / 12.
6. Mốc mới cho chặng 4: `tools/.golden-chang3`, `tools/.golden-chang3-web`.

## 7. Bước E — ghi lại (commit 3)

1. `CHANGELOG.md` `[5.12.0] — BJ-06 thiết kế lại; hết chặng 3 (SC_journey_3)`; phiên bản 5.12.0 (`manifest.json`, `harness/workbench.js`, badge `index.html`, nhãn inspector UIF-06).
2. Viết lại theo `_TEMPLATE.md`: SCR-030, SCR-031 (gồm bố cục web hai cột), SCR-032, SCR-033, SCR-034 (K2, lối vào Home "Chờ duyệt"), SCR-035; UIF-06 (sơ đồ mới: lối vào chủ cửa hàng từ Home "Chờ duyệt"; dòng chờ mở được; ra BJ-01 / BJ-17; ghi chú lối BJ-09 ở chặng 4).
3. Áp phần BJ-06 của dòng "mọi BJ theo K2" (T7-P mục 13): UC-06-02 / SCR-034 "người duyệt = `is_owner` hoặc `store_owner`; chủ lập cũng gửi rồi tự duyệt"; UIF-06-T06 "không self-approve" → theo K2.
4. T7-P mục 5: dòng `io06SelectionRow` / `.cf-segmented` → "BJ-06 đã chuyển sang `dsChoiceRow`" (BJ-15 còn); mục 9 BJ-06: khuôn "K1, K2, K3, K4, K6, K7".
5. `INDEX.md` 030–035; T7-P mục 13 (chữ mới), mục 14: BJ-06 ✅ và **`SC_journey_3` ✅**.
6. `python3 tools/sync-registry.py`.

## 8. Ghi chú khi làm

(2026-10-24, v5.12.0; chưa commit — ba commit C1 / C2 / E theo plan chưa tách vì người dùng chưa yêu cầu commit.)

**GitNexus (mục 2.3):** `render030BJ06` … `render035BJ06` LOW (0 người gọi ngoài file); `io06ClassValid` LOW (4, cùng file); `io06RefreshRequestState` **MEDIUM** (5, cùng file, 0 luồng); `openDirect` LOW (1), `applyDirectContext` LOW (2). Không có HIGH / CRITICAL. `__T7_PENDING_SOURCES__` chỉ đọc trong `hub.js`.

**Lệch so với plan:**

1. **Mốc golden:** `tools/.golden-bj05-after` / `-web-after` đã cũ (nhãn inspector đổi sau khi chụp). Mốc so sánh = bản sao thư mục trước BJ-06 (`bj06.js`, CSS, `hub.js` về trước khi sửa) chụp ở cổng khác: mobile 1708 → 1708, web 844 → 844, 0 lỗi JS. Ca ngoài UIF-06 / `SC_bj06_*` / `SC_journey_3` chỉ khác đúng dòng Home "Chờ duyệt" (89 ca mobile / 26 web: "3 nhận hàng · 1 ngoại lệ lô hàng trả", 3 → 4, thêm một dòng ở danh sách "Chờ duyệt"), cộng nhãn inspector UIF-06 và `SC_ws_movement_2_2_item` (mở 030 từ Hub). Không ca nào chỉ khác ảnh. `SC_bj17_from_*` và ca BJ-04 / 05 khớp. Mốc chặng 4 = `tools/.golden-chang3` (1708) và `tools/.golden-chang3-web` (844).
2. **Kho chưa kích hoạt:** nguồn "Chờ duyệt" của BJ-06 gắn `needsActivation` (hub bỏ qua khi chưa kích hoạt) — nếu không, `HUB_home_not_activated` và `SC_journey_1` sẽ hiện thêm dòng ngoại lệ lô. Plan không nói; `hub.js` thêm `rowsOf(src)`.
3. **Móc `openDirect`:** đúng 3.3 điểm 2. Thêm trong `hub.js` một lối thoát chung `data-theme-exit-to-pending` (về danh sách "Chờ duyệt") — BJ-02 dùng `data-action="exit-approval"` riêng nên không dùng lại được.
4. **`EXPIRED_GUARD` / `RET-260827-05`:** plan 3.1 điểm 5 + `SC_bj06_split` cần Nobivac (RET-L4) chia được, nhưng fixture cũ ép RET-L4 thành lô hết hạn DH2408 cho cả yêu cầu. Giữ RET-L4 = DH2509 (đúng lô giao); `EXPIRED_GUARD` do `io06Seed` đổi RET-L4 sang DH2408 (lô hết hạn thật) và mở sheet "Lô đã hết hạn" ở iPhone. Bỏ cách ép "dòng đang mở theo trạng thái".
5. **`io06ClassValid(line, c)`** bỏ tham số `state` (không còn hack `EXPIRED_GUARD`); lượng `null` → không hợp lệ (đúng plan 0.7).
6. **Phân loại cả dòng lưu ngay:** chọn "Bán được / Cách ly / Hỏng" ở sheet iPhone **lưu và đóng sheet luôn**, không có "Xong" (theo kịch bản `SC_bj06_split` / `SC_journey_3` bước 11 trong plan, không có "Xong" giữa các dòng); chỉ "Chia nhiều loại" có "Hủy" | "Xong".
7. **Lý do chân khi nút tắt:** "Chờ chủ cửa hàng duyệt ngoại lệ lô" (0.4 điểm 8) không dùng — điểm 9 nói `WAITING_APPROVAL` không có chân và `io06RefreshRequestState` luôn đặt "chờ duyệt" trước "bị từ chối", nên không có trạng thái nào cần chữ này. Chữ ngoài plan (đã vào T7-P mục 13): "Cần nhận ít nhất một dòng", "Nhập hạn dùng lô mới", "Mô tả lý do ngoại lệ", "Chọn lý do ngoại lệ", "Không thể tự duyệt", "Chưa kiểm", "Chưa phân loại" / "Chưa đủ" / "Không nhận", "Chờ quyết định", "Sản phẩm" (đầu bảng quyết định 034).
8. **034:** `SELF_APPROVAL_NOT_ALLOWED` là trạng thái nội bộ (không có trong `workbench-data`, nên không có ca golden riêng; có `SC_bj06_self_approval`). Vì vai mặc định `module` không được duyệt, `SC_bj06_approve` / `reject` / `after_approval` vào bằng `&entry=approver` (plan ghi URL không có). Lối `entry=approver` ở URL: `onEntry` đăng ký sau khi core đã áp lối vào nên bj06.js đặt `TASK_LIST` ngay lúc nạp.
9. **`SC_bj06_after_approval`:** bước "chuyển UIF-06 SCR-030" = `navigate('SCR-030')` (đi trong luồng, không dựng lại fixture) thay vì `setActor`; `SC_journey_3` không cần `setActor` — vai `approver` do dòng "Chờ duyệt" tự đặt.
10. **Web 031 / 032 trùng ảnh:** 031 `WAITING_APPROVAL` và 032 `PENDING_APPROVAL` ở khung web là cùng một trang (đúng thiết kế "một trang hai cột"), nên ảnh giống nhau; khác nhau ở iPhone.
11. **K3 `safe`:** theo plan ("Không gửi lại thao tác. Chuyển đúng lần ghi nhận này sang xác minh.") nên câu "Không gửi lại thao tác." hiện hai lần (khuôn K3 đã có câu đó; BJ-05 cũng vậy) — đề nghị review gỡ ở khuôn K3.
12. **CSS:** gỡ 87 luật chỉ thuộc `body[data-active-uif="UIF-06"]` (ép 370px, hàng 76px, `io06-*`) ở `screens.css` / `components.css`; khối `bj06-*` cuối `screens.css`. `!important` mới (6 luật): ghi đè luật dùng chung của UIF-05 / 06 / 07 đang ép `ds24-list-row__copy > small` một dòng và chiều cao hàng 76px (`.bj06-line-row`, `.k6-list`), và chiều cao hàng chọn trong sheet (`.bj06-sheet .ds-choice-row`).
13. **Listener `click` vẫn ở pha capture** (plan 3.2 cho phép giữ): `k2RejectSheet` chặn nổi bọt bằng `onclick="event.stopPropagation()"` nên pha bubble không thấy nút trong sheet. Nền sheet (`close-reject`) chỉ đóng khi bấm đúng nền.
14. Thêm kịch bản `SC_bj06_self_approval`; `SC_bj06_exception_submit` cũng chạy ở web (ngoài 4 ca web của plan) để có ảnh web cho lô khác + ảnh.

**Bước D:** 0 lỗi JS (`node --check app/*.js harness/*.js tools/golden.mjs`; golden 1708 + 844 ca). Bấm thử UIF-06 hai khung bằng `SC_bj06_*` + `SC_journey_3` (25 bước, cả hai khung): đúng các mốc ở 5.4 — Home "3 nhận hàng · 1 ngoại lệ lô hàng trả" → … → "Bàn giao lúc 16/09/2026 13:08" → RET-260827-03 "Đã kiểm 4/4 dòng" → "Đã nhận hàng khách trả" (Ghi nhận lúc 16/09/2026 15:00) → "Đã phân loại hàng trả" + "Hàng cách ly / hỏng chờ xử lý ở Hàng cần xử lý." → "Duyệt nhận lô DH2509 thay cho lô DH2507?" → "Đã duyệt ngoại lệ" → Home "3 nhận hàng".

**Audit (`/impeccable audit`, Chrome headless CDP, 55 ca = 6 màn × trạng thái × 2 khung + sheet chia, sheet kết quả, sheet từ chối, lô khác + ảnh):** chữ ≥ 4,5:1 (0 lỗi); vùng chạm iPhone ≥ 44 × 44 (0 lỗi: "Nhận đủ", "Chụp ảnh" / "Chọn tệp", `dsChoiceRow`, nút chân); web nút ≥ 40 (`dsSegmented` 38 → 40 sau audit); 0 ảnh thiếu `alt`; 0 nút thiếu tên; 0 tràn ngang. Bàn phím web: Tab đi bảng trái (dòng, Tab tới được) → cột phải (ô số, "Nhận đủ", lô); sheet / hộp thoại giữ Tab trong hộp thoại, Esc đóng và trả focus về nút / dòng đã mở. **Lỗi trong phạm vi đã sửa:** focus không về dòng 033 sau Esc (bảng ẩn trong DOM iPhone trùng `data-io06-class-line`) → thêm `data-bj06-row`; banner "Lô đã hết hạn" / "bị từ chối" bị cắt 2 dòng (đổi sang mật độ Default). Ngoài phạm vi: detector `impeccable detect` chỉ báo chữ 10px / tương phản của bộ kiểm (`nav-group-label`, số màn) — ngoài khung app.

**Chưa làm:** `/impeccable audit` **chưa chạy riêng cho cả đường `SC_journey_3`** (mục 6.4 — chuyển màn giữa ba BJ, nút quay lại, đổi vai): mới kiểm qua các bước golden `SC_journey_3` / `SC_bj05_theme` (đúng màn, đúng chữ, 0 lỗi JS), không đo tương phản / vùng chạm / bàn phím trên các màn BJ-04 / 05 của đường đó.

**Cần người xem:** ảnh gửi review (mục 6.5) chưa gửi — ảnh nằm trong `tools/.golden-chang3*`; chưa thử chọn tệp thật cho "Chụp ảnh" / "Chọn tệp" (headless không chọn được tệp; dùng `setIO06Evidence`); chưa commit.

## 9. Không làm

- Hoàn tiền, đổi hàng, quyết định thương mại của yêu cầu trả (Theme 5).
- Lối sang BJ-09 "Hàng cần xử lý" cho hàng cách ly / hỏng (chặng 4 dựng danh sách chung; ở đây chỉ dòng thông tin).
- Chuyển nhánh BJ-02 của `openDirect` sang móc chung (mục 3.3 điểm 2).
- Camera thật (prototype "Chụp ảnh" mở ô chọn tệp).

## 10. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| Nguồn "Chờ duyệt" mới làm khác golden Home ở mọi chặng | Chỉ được khác dòng "Chờ duyệt"; kiểm bằng `diff` thân `.txt`, liệt kê ở mục 8 |
| Web 031 hai cột đổi cách lưu (không `navigate`) làm lệch kịch bản iPhone | Cùng khoá sự kiện; nhánh web chỉ khác bước sau "Xong"; `SC_bj06_full` chạy ở cả hai khung |
| Lựa chọn lớn ở 033 bị hiểu là "điền sẵn" | Không chọn sẵn; 0.10 c chốt trước khi dựng |
| Móc `__T7_DIRECT_CONTEXTS__` đụng nhánh BJ-02 của `openDirect` | Móc chạy trước, chỉ khi tiền tố khớp; golden `SC_bj02_*` / `SC_journey_2` phải khớp (trừ dòng "Chờ duyệt") |
| `SC_journey_3` dài, dễ vỡ | Chỉ dùng nhãn `data-*`, không chữ; chia nhỏ bằng kịch bản riêng ở 5.3 để biết vỡ ở BJ nào |

## 11. Chữ trên màn

| Vị trí | Chữ |
|---|---|
| 030 | "Chưa có yêu cầu trả cần xử lý" · "Yêu cầu trả hàng được Bán hàng chấp nhận sẽ hiện ở đây." · cột "Yêu cầu", "Khách hàng", "Đơn bán", "Mặt hàng", "Tình trạng" |
| 031 | "Bước 1/2 · Nhận hàng" · "Đã kiểm {a}/{b} dòng" · "Lô giao {lô} · được nhận {n} {ĐVT}" · "Không theo lô · được nhận {n} {ĐVT}" · lý do: "Còn {n} dòng chưa kiểm", "Chờ chủ cửa hàng duyệt ngoại lệ lô", "Sửa dòng bị từ chối rồi gửi lại" · "Người khác vừa cập nhật yêu cầu này" · "Yêu cầu đang được xử lý" · "Đợi lần xử lý hiện tại xong rồi mở lại." |
| 032 | "Nhận đủ {n} {ĐVT}" (chữ BJ-02) · "Ảnh sẽ gửi kèm yêu cầu duyệt" · "Sửa dòng này thì phải gửi duyệt lại." · lý do: "Nhập số lượng thực nhận", "Chọn lô thực nhận", "Thêm ảnh nhãn lô" |
| 034 / Home | "ngoại lệ lô hàng trả" · "Duyệt nhận lô {lô thực nhận} thay cho lô {lô giao}?" · "Lô thực nhận khác lô đã giao" · "Chưa có ảnh nhãn lô" · "Thủ kho ghi nhận hàng trả khi tất cả dòng hợp lệ." · "Bạn chưa có quyền duyệt ngoại lệ lô" · "Chỉ chủ cửa hàng duyệt ngoại lệ lô hàng trả." |
| 033 | "Bước 2/2 · Phân loại" · "Đã phân loại {a}/{b} dòng" · "Cả {n} {ĐVT}" · "Chia nhiều loại" · "Chia" (web) · "Còn {n} {ĐVT} chưa phân loại" · "Còn {n} dòng chưa phân loại" |
| 035 | "Người nhận" · "Hàng cách ly / hỏng chờ xử lý ở Hàng cần xử lý." · K3: "Nhận hàng khách trả" · "Không gửi lại thao tác. Chuyển đúng lần ghi nhận này sang xác minh." |
| Không có quyền | "Bạn chưa có quyền nhận hàng khách trả" · "Liên hệ chủ cửa hàng để được cấp quyền." (chữ BJ-05) |

## 12. Review

**Review chặng 3 (BJ-04 / 05 + BJ-06):** (2026-10-24, phiên review) — **đạt có điều kiện**, **đạt hẳn 2026-10-25 sau R1–R3** (sửa ở phiên review theo yêu cầu người dùng → v5.12.1, xem "Đã sửa" cuối mục). Review của BJ-04 / 05 trỏ về đây.

| Kiểm (chạy lại) | Kết quả |
|---|---|
| `node --check app/*.js harness/*.js tools/golden.mjs` | Sạch |
| Golden mobile / web chụp lại | 1708 / 844 ca, 0 lỗi JS; "Khớp hoàn toàn" với `tools/.golden-chang3` / `-web` (mốc tái lập được) |
| `.golden-chang2` → `.golden-chang3` | 602 / 248 khác biệt. Ngoài phạm vi 0.8 của hai plan (`UIF-0[456]_*`, `SC_bj0[456]*`, `SC_quick_UIF-05_*`, `SC_entry_UIF-0[456]_*`, `SC_bj17_from_bj05_0`, `SC_ws_movement_[12]_2_item`, `SC_journey_3`) còn 77 + 19 ca — `diff` thân `.txt` **chỉ** khác dòng Home "Chờ duyệt" ("3 nhận hàng" → "… · 1 ngoại lệ lô hàng trả", 3 → 4, thêm dòng EX-06-001) |
| Trạng thái trùng ảnh | iPhone: 0 cặp trùng ở UIF-04 / 05 / 06. Web: chỉ 031 ↔ 032 (`READY`, `WAITING_APPROVAL` / `PENDING_APPROVAL`, `CONFLICT`, `LOCKED`) — đúng thiết kế một trang hai cột (ghi chú 10) |
| Mã dùng chung | `k6TaskList`, `k4ReasonFooter`, `k3Unknown({ handoff })`, `hub.js` (`rowsOf` / `needsActivation`, móc `__T7_DIRECT_CONTEXTS__`, `data-keep-back`, `data-theme-exit-to-pending`): đúng plan, không đụng nhánh BJ-02 |
| Registry | `sync-registry.py` chạy lại ở phiên review |
| Ảnh | 026 web / iPhone, 031 web / iPhone, 033 iPhone, 034 web (`SC_journey_3`) |

Lệch plan ở ghi chú (BJ-04 / 05 mục 11: 1–10; BJ-06 mục 8: 1–14): **chấp nhận**. BJ-05 ghi chú 4 ("Xác nhận đã điều chỉnh hàng" giữ quy tắc cũ): giữ, không làm gọn ở chặng này. `detect_changes()` không chạy: chấp nhận như chặng 1 (prototype tĩnh).

**Cần sửa (chặn commit):**

- **R1. iPhone 026 — dòng lô lấy một phần tràn khỏi thẻ.** Ảnh `UIF-05_SCR-026_READY` (màn mặc định) và `_STALE_RECOVERED`: lô DH2509 có ba dòng chữ ("HSD 09/2027 · Lấy 16 hộp" + "Đã lấy 8/16 hộp"); badge "Đã lấy một phần" trồi lên viền trên, nút "Lấy đủ" lòi ra đáy thẻ. Cụm `.bj05-lot-stack` (badge + nút) cao hơn hàng. Sửa: hàng `.bj05-lot` cao theo nội dung (bỏ / đè chiều cao cố định của list row trong UIF-05), cụm phải căn giữa dọc; kiểm thêm `SC_bj05_stale`, `SC_journey_3_2_order`.
- **R2. iPhone 031 — số và ĐVT gãy dòng.** "Lô giao DH2507 · được nhận 3 / hộp" (ảnh `SC_journey_3_14_line-2`, cả bốn dòng), trái tiêu chí D "số không gãy dòng". Sửa: nối "{n} {ĐVT}" bằng khoảng trắng không ngắt (hoặc bọc `white-space:nowrap`) trong phụ đề dòng 031; rà cùng chỗ ở 033 / 035 / 026 / 021.
- **R3. K3 lặp câu.** 029 / 035 `UNKNOWN`: "Không gửi lại thao tác. Chuyển đúng lần xử lý này sang xác minh kết quả. Không gửi lại thao tác. Chuyển đúng lần ghi nhận này sang xác minh." (BJ-05 tương tự với "bàn giao"). Sửa ở BJ (không đổi khuôn K3 để giữ ảnh BJ-02 / BJ-13): bỏ `safe` ở BJ-05 / BJ-06 (câu khuôn đã đủ). Ghi T7-P mục 13: hai chữ mới "Không gửi lại bàn giao…" / "Không gửi lại thao tác. Chuyển đúng lần ghi nhận…" bị bỏ.

**Góp ý nhỏ (không chặn):**

1. **Web 031 / 032:** ở 1280 × 800 nút "Xong" của cột phải nằm dưới mép chân (phải cuộn mới thấy) — cân nhắc đưa "Xong" lên đầu khối lô hoặc cho cột phải cuộn riêng với nút dính đáy.
2. **Mục 6.4 chưa làm:** `/impeccable audit` riêng cho cả đường `SC_journey_3` (ghi chú "Chưa làm"). Làm cùng R1–R3 (chỉ cần các màn chuyển giữa ba BJ, nút quay lại, thanh bên web).
3. **`k6TaskList`:** `defaultRow` dùng `rowAttr(r)` thay `attrOf(r)` — dòng tắt ở iPhone không có `aria-disabled` trên phần tử mang thuộc tính mở (đang đỡ nhờ `ds24ListRow({ disabled })`); đổi cho đồng bộ với bảng web.
4. **`k4ReasonFooter`** (khuôn chung) vẫn dùng lớp `bj02-footer-*` / `data-bj02-reason` — đổi tên khi dọn CSS cuối Giai đoạn 2.
5. **Khối "Tóm tắt" web (`ac310KeyValueSurface`):** giá trị chữ ("Đại lý An Phú", "Kho chính") hiện font mono — mono chỉ nên cho số / mã. Rà ở đợt dọn CSS.

**Phạm vi commit:** cây làm việc còn chứa **chặng 2 BJ-13 (v5.10.0) chưa review** (mục 14) — dùng chung `CHANGELOG.md`, `hub.js`, `golden.mjs`, CSS với chặng 3 nên không tách sạch theo tệp. Commit sau R1–R3 sẽ gồm cả BJ-13, trừ khi review BJ-13 trước.

**Đã sửa (2026-10-25, phiên review, v5.12.1):** R1 (`screens.css`: luật đè `.figma-calibrated-shell .bj05-lot.ds24-list-row[data-ds-prop-density="Default"]` — `height:auto`, `max-height:none`, đệm dọc; luật cũ `body[data-active-uif="UIF-05"] .bj05-lot` thua độ ưu tiên của luật khung Figma 76px), R2 (`bj06LineSub` nối số và ĐVT bằng ` `), R3 (bỏ `safe` ở `render029BJ05` / `render035BJ06`; hai chữ mới tương ứng bỏ khỏi T7-P mục 13 nếu đã ghi). Góp ý 1–5 làm ở v5.12.2 (dòng dưới). Kiểm: `node --check` sạch; golden 1708 / 844 ca, 0 lỗi JS, chỉ ca nêu ở CHANGELOG `[5.12.1]` khác mốc; ảnh 026 / 031 iPhone đã xem. Mốc `tools/.golden-chang3*` chụp lại (v5.12.1). GitNexus `impact` upstream: `render029BJ05`, `render035BJ06` LOW (0 người gọi); `io05MobileLotRow` / `bj06LineSub` chưa có trong chỉ mục (hàm mới, chỉ gọi trong tệp). Commit chung với chặng 2 BJ-13 theo yêu cầu người dùng.

**Góp ý 1–5 (2026-10-25, phiên review, v5.12.2):** 1 — web 031 / 032 thanh "Xong" dính đáy vùng cuộn (`position: sticky`); 2 — audit dọc `SC_journey_3` (Chrome không giao diện, 29 bước cả hai khung: tương phản, vùng chạm iPhone, tên nút, `alt`, tràn ngang; có bước 021 → quay lại → 026 và sheet từ chối) tìm thêm lỗi **028 iPhone** (dòng sản phẩm trong thẻ tràn 17px vì luật khung Figma ép 370px; dòng "Giao lần này" thụt 12px) → đã sửa, chạy lại 0 lỗi / 0 lỗi JS; bàn phím web không đo lại ở lượt này (đã đo theo từng BJ ở bước D); 3 — không cần sửa mã: `ds24ListRow({ disabled })` đã gắn `aria-disabled`, chỉ thêm ghi chú (góp ý ban đầu sai); 4 — `bj02-footer-*` / `data-bj02-reason` → `k4-reason-footer*` / `data-k4-reason`; 5 — giá trị chữ trong "Tóm tắt" web dùng Inter (luật K7 thêm `!important`). Golden: chỉ ca ghi ở CHANGELOG `[5.12.2]` khác mốc; mốc `tools/.golden-chang3*` chụp lại.
