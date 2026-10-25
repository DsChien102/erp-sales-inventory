# T7-P · BJ-07 Trả nhà cung cấp + BJ-10 Tiêu hủy — thiết kế lại (bước B–E) + `SC_journey_4`

> Theme: Theme 7 Inventory · Trạng thái: Brief ✅ (duyệt 2026-10-25 — mục 0.10, mọi điểm theo đề xuất) | Plan C–E ✅ (rà lại theo code BJ-09 khi làm) | Làm ✅ 2026-10-26 (v5.14.0 + v5.15.0, chưa commit) | Review ✅ đạt 2026-10-25 sau R1–R3 (v5.15.1 — mục 14)
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) mục 8.2 **chặng 4 "Hàng có vấn đề"**, BJ thứ hai và thứ ba (làm chung một plan như gói A6 — cùng dùng màn chung 036 / 037 / 041). Làm **sau** [BJ-09](T7-P-bj09-tinh-trang-hang.md) (dùng K5 và fixture chung chặng 4 dựng ở đó).
> Dùng lại K1, **K2** (tiêu hủy cần chủ cửa hàng duyệt — UC-10-02), K3, K4, **K5** (dựng ở BJ-09), K6, K7. **BJ-07 không K2** (yêu cầu trả đã được Mua hàng duyệt; Kho không duyệt thương mại lần hai — SCR-036 v1.4.3). Không khuôn mới.
> Thiết bị: **cả iPhone và web đều là thiết bị chính** (T7-P mục 2). Nhân viên kiểm hàng trả và tiêu hủy tại kho bằng iPhone (chụp ảnh); bàn giao ở quầy có máy tính; chủ cửa hàng duyệt tiêu hủy lúc ở máy tính hoặc iPhone.
> Hết plan này = **hết chặng 4**: kịch bản `SC_journey_4` (mục 6.4) đi một mạch Home Kho → hàng cách ly → đổi sang hỏng → chủ duyệt → đề nghị tiêu hủy → chủ duyệt → xác nhận đã tiêu hủy → trả nhà cung cấp → về Home.
> Ước lượng: **~3 ngày, 4 commit** (C1 BJ-07; C2 BJ-10; C3 `SC_journey_4` + D; E). Người làm: bạn. Review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị, chép nguyên văn; **(mới)** = chữ mới, vào T7-P mục 13 ở bước E.

## 0. Brief (bước B, đã duyệt 2026-10-25)

### 0.1 Việc thật

- **BJ-07 — ai, lúc nào:** nhân viên kho, **vài lần / tháng**, khi bộ phận Mua hàng đã thống nhất trả hàng với nhà cung cấp (hàng hỏng, hết hạn, giao nhầm, thừa) và chuyển yêu cầu sang Kho. Kho **không quyết** trả hay không: chỉ tìm đúng hàng trên kệ, kiểm đúng lô / số lượng, ghi chênh lệch nếu thực tế khác yêu cầu, rồi giao cho nhà cung cấp hoặc đơn vị vận chuyển. Tồn và giá trị chỉ giảm lúc xác nhận đã bàn giao.
- **BJ-10 — ai, lúc nào:** nhân viên đề nghị khi hàng không bán được và không trả được (hết hạn, hỏng nặng) — **vài lần / tháng**; chủ cửa hàng duyệt vì mất tiền (thấy giá trị sẽ ghi giảm); sau khi duyệt, nhân viên tự tiêu hủy hoặc giao đơn vị xử lý, chụp ảnh / biên bản rồi xác nhận. Tồn và giá trị chỉ giảm lúc xác nhận đã tiêu hủy.
- **Quy tắc BJ-07** (UC-07-01…04 BR-01…06, UIF-07): yêu cầu trả do nguồn (Mua hàng) cấp phép, có phiên bản; lượng trả không vượt đồng thời lượng nguồn cho phép và lượng thực có theo đúng sản phẩm / lô; tạo hồ sơ chờ trả **không** giảm tồn vật lý, chỉ bàn giao thực tế mới giảm; nguồn đổi / hủy trước bàn giao → hệ thống cập nhật phần chờ trả, chỉ phần bị ảnh hưởng phải kiểm lại; Kho ghi chênh lệch thực tế, **không tự sửa yêu cầu hay thay lô**; giá trị giảm theo giá vốn chính thức, chênh lệch giá NCC là việc kế toán; `UNKNOWN` giữ mã thao tác, chuyển BJ-17.
- **Quy tắc BJ-10** (UC-10-01…04 BR-01…06, UIF-10): chỉ hàng **không bán được** của cửa hàng mới tiêu hủy được (hàng bán được phải qua BJ-09 trước); duyệt **chưa** giảm tồn, chỉ xác nhận đã tiêu hủy (kèm bằng chứng) mới ghi giảm; người lập không tự duyệt **trừ** `is_owner` (gửi rồi tự duyệt — K2); thiếu căn cứ giá thì không gửi được (giữ nháp); lượng thực tiêu hủy khác lượng duyệt chỉ trong phạm vi chính sách, vượt phải lập đề nghị mới; giá trị giảm theo giá vốn lúc hoàn tất; `UNKNOWN` → BJ-17.

### 0.2 Luồng hiện tại

Ảnh: `tools/.golden-bj09-after/UIF-07_*`, `UIF-10_*`, `SC_bj07_*`, `SC_bj10_*`, `SC_entry_UIF-07_*`, `SC_entry_UIF-10_*`; web `tools/.golden-bj09-web-after/UIF-07_*@web`, `UIF-10_*@web`. (036 và 037 của UIF-10 đã là K5 sau plan BJ-09.)

```text
BJ-07: 036 (K5, chip "Trả nhà cung cấp") ─yêu cầu→ 037 "Chuẩn bị hàng trả" (nhóm theo sản phẩm, mỗi lô một dòng)
  ─dòng→ sheet "Kiểm hàng thực tế" (lô thực tế, nguồn tồn) ─"Đúng hàng"→ 037 … (lặp mỗi dòng)
  ─"Không khớp"→ sheet "Ghi nhận chênh lệch" → yêu cầu "Chờ cập nhật" (chỉ xem)
  ─"Rà soát bàn giao"→ 039 (Thông tin bàn giao 4 dòng + danh sách) ─"Xác nhận đã bàn giao"→ 041 (bảng dài) ─→ "Về hàng chờ trả"
BJ-10: 036 / 037 (K5) ─"Đề nghị tiêu hủy"→ 040 (một màn, 10 trạng thái; "Amox 500 · L2407-A · 6 hộp" ghi cứng)
  ─"Gửi yêu cầu tiêu hủy"→ 040 PENDING_APPROVAL (ngõ cụt, "Về danh sách")
  người duyệt: ?entry=approver → 040 APPROVAL_REVIEW ─"Duyệt"→ 040 APPROVED_PENDING_DISPOSAL (ngõ cụt)
  người xác nhận: ?entry=completion-operator → 040 COMPLETION ─"Xác nhận đã tiêu hủy"→ 041
```

### 0.3 Vấn đề

| # | Màn | Vấn đề |
|---|---|---|
| 1 | 037 BJ-07 | Kiểm mỗi dòng mất **3 chạm** (dòng → sheet → "Đúng hàng"), 4 dòng = 12 chạm; không có kiểm một chạm. Badge ngữ cảnh "0/4" không có chữ |
| 2 | 037 BJ-07 | "Cần xác định nguồn tồn" / "Xác định nguồn tồn" / "Chưa đủ nguồn tồn" — chữ hệ thống, nhân viên không hiểu "nguồn tồn" là gì |
| 3 | 037 BJ-07 | "Rà soát bàn giao" tắt **không nói lý do**; hai nhóm "Nobivac DHPPi" (hộp / lọ) trông như trùng; mã "SP-00142" lệch BJ-01 "SP-000184" |
| 4 | 039 | Khối "Thông tin bàn giao" 4 dòng lặp 037; **không ghi giao cho ai** (BJ-07 mục 1: "bàn giao cho nhà cung cấp hoặc đơn vị vận chuyển"); không câu nào nói tồn chỉ giảm sau bước này |
| 5 | 041 BJ-07 | "Bàn giao lúc —" (ảnh mở thẳng); lặp lại danh sách dài (K4: không lặp danh sách); chỉ "Về hàng chờ trả"; `UNKNOWN` dùng `ioResult` (không K3); `PERMISSION_DENIED` là màn kết quả "Không có quyền thực hiện" thay K1 |
| 6 | 040 | **Một màn gánh 10 trạng thái** trông gần như nhau (bảng 4 dòng + ô); dữ liệu ghi cứng trong chuỗi HTML; số lượng không có gợi ý tối đa / "Cả {n}"; "Bằng chứng" là ô chữ; **thiếu "phương thức xử lý"** (UC-10-01 BF-03); "Căn cứ giá: Giá vốn hiện hành" hiện cho cả nhân viên nhưng chủ cửa hàng lại không thấy số tiền để quyết (BR-03 cấp duyệt từ lượng × giá) |
| 7 | 040 duyệt | Không theo K2, không có trong Home "Chờ duyệt"; chủ cửa hàng tự lập bị chặn (`bj10IsApprover` chỉ nhận `approver`); `ic10-reject` không hỏi lý do (UC-10-02 AF-A-01 bắt buộc) |
| 8 | 040 sau duyệt | `PENDING_APPROVAL` và `APPROVED_PENDING_DISPOSAL` là **ngõ cụt** ("Về danh sách"); xác nhận đã tiêu hủy chỉ vào được bằng `?entry=completion-operator`; thiếu bằng chứng cũng báo "Số lượng thực tế vượt phạm vi được duyệt" (`COMPLETION_QTY_BLOCKED` dùng chung hai lỗi) |
| 9 | 041 BJ-10 | `ioResult` canh giữa; "TH-0709-04", "Tồn vật lý còn lại" tính từ hằng số 6; `UNKNOWN` không K3; từ chối đi thẳng `REJECTED_EXECUTION` "Chưa ghi giảm" (lẫn với lỗi thực thi) |
| 10 | Web | Mọi màn của hai BJ là cột 402px giữa khung |
| 11 | Mã | BJ-07: hai bộ listener (`window` capture chặn trước + `document`), `ensureIo07ReviewFixture` sửa fixture khi dựng 039 (rò trạng thái như BJ-05 chặng 3). BJ-10: listener `input` **không kiểm luồng** (bắt `data-v350-ic10-*` ở mọi luồng); `render0xxIC10` lớp chuyển tiếp; nhãn `data-v350-*`, `data-ic10-*` |

### 0.4 Đề xuất

**Luồng mới**

```text
036 "Hàng cần xử lý" (K5) ─yêu cầu trả→ 037 "Chuẩn bị hàng trả": mỗi lô một dòng, nút "Đúng hàng" một chạm; sheet chỉ khi cần nhập lô / chọn phần hàng / không khớp
     ─"Rà soát bàn giao"→ 039 (giao cho ai; hàng sẽ bàn giao) ─"Xác nhận đã bàn giao"→ 041 (K4) → "Chuẩn bị yêu cầu tiếp theo" | "Về hàng cần xử lý"
037 (K5) / 041 BJ-09 ─"Đề nghị tiêu hủy"→ 040 Đề nghị ─"Gửi phê duyệt"→ 040 Chờ duyệt (K2)
     chủ cửa hàng: Home "Chờ duyệt" → 040 Duyệt (K2) ─"Duyệt"→ 040 Đã duyệt · chờ tiêu hủy ─"Xác nhận đã tiêu hủy"→ 040 Xác nhận ─→ 041 (K4)
036 chip "Tiêu hủy" ─dòng chờ tiêu hủy→ 040 Đã duyệt (mở đúng bước đang dở) ; dòng chờ duyệt → 040 Chờ duyệt (chỉ đọc)
```

**BJ-07**

*SCR-036* — K5 (plan BJ-09); dòng yêu cầu trả lấy từ `__T7_PROBLEM_SOURCES__` của BJ-07 (thay dòng tạm ở plan BJ-09 mục 4.1 điểm 2): phụ "{NCC} · {n} mặt hàng", badge `io07StageMeta` (giữ chữ).

*SCR-037 Chuẩn bị hàng trả* (vấn đề 1–3)

1. Tiêu đề "Chuẩn bị hàng trả" (giữ); phụ **"{mã yêu cầu} · {NCC}" (mới)** (thay dòng ngữ cảnh có badge "0/4"). Một dòng nhỏ **"Yêu cầu do Mua hàng chuyển sang Kho · {chứng từ}" (mới; vế đầu là chữ SCR-036 v1.4.3)**.
2. Thanh tiến độ mảnh (`.bj02-progress`) **"Đã kiểm {a}/{b} dòng" (chữ BJ-06)**. Banner "Yêu cầu đã cập nhật" + chi tiết thay đổi (giữ) khi nguồn đổi.
3. iPhone: mỗi sản phẩm một nhóm — đầu nhóm tên + **"{mã} · Trả {n} {ĐVT}" (mới)**; dưới là mỗi lô một dòng: "Lô {lô}" (giữ) / "Không theo lô" (giữ), phụ **"HSD {hsd} · Trả {n} {ĐVT}" (mới, theo mẫu BJ-05 "HSD {hsd} · Lấy {n} {ĐVT}")**; dòng bị nguồn đổi thêm "· Trước {cũ} {ĐVT}" (giữ ý "trước"). Bên phải: chưa kiểm → nút **"Đúng hàng"** (chữ nút sheet, giữ) một chạm (đánh dấu đã kiểm, `verifyMethod: "VISUAL"`); đã kiểm → badge "Đã kiểm" (giữ); không khớp → badge "Không khớp" (giữ); dòng cần chọn phần hàng → nút tắt, phụ thêm **"· Cần chọn phần hàng" (mới, thay "Cần xác định nguồn tồn")**. Chạm vào dòng (ngoài nút) → sheet "Kiểm hàng thực tế" (giữ) như hiện có.
4. Sheet "Kiểm hàng thực tế": giữ "Lô thực tế (không bắt buộc)", "Lô không khớp", "Không khớp" | "Đúng hàng"; khối nguồn tồn đổi chữ: tiêu đề **"Trả từ phần hàng nào" (mới)**, mô tả **"Lô này có hàng ở nhiều tình trạng. Ghi số lượng trả từ từng phần." (mới)**, lỗi **"Cần chia đủ {n} {ĐVT}" (mới, thay "Chưa đủ nguồn tồn" / "Cần phân bổ đúng …")**. Sheet "Ghi nhận chênh lệch" giữ nguyên chữ.
5. Web (K7, `k7Split({ wideMain:true })`): trái bảng Sản phẩm · Lô · HSD · **"Trả"** (mới) · **"Kiểm"** (mới; nút "Đúng hàng" / badge) — dòng bấm mở hộp thoại kiểm; phải khối "Tóm tắt" (chữ BJ-03): Nhà cung cấp · Yêu cầu trả · Chứng từ nguồn · Kho.
6. Chân `k4ReasonFooter` "Rà soát bàn giao" (giữ) + lý do khi tắt: **"Còn {n} dòng chưa kiểm" (chữ BJ-06)**, **"Có dòng không khớp · chờ Mua hàng cập nhật" (mới)**.
7. `WAITING` (đã gửi chênh lệch / Mua hàng đang sửa): banner "Chờ cập nhật yêu cầu" (giữ), dòng chỉ đọc, không chân. Yêu cầu bị hủy từ nguồn: banner "Yêu cầu đã được hủy" + câu (giữ) + "Về hàng cần xử lý" (thay "Về hàng chờ trả"). `SOURCE_UPDATED`: banner + chỉ dòng bị ảnh hưởng mất "Đã kiểm". `LOCKED` → `k1Locked`; `EXPIRED` / `FINANCIAL_RESTRICTED` (spec, chung cho 037) → dựng như `READY` (ghi CHANGELOG — 037 không có tiền, yêu cầu trả không hết hạn). `LOADING` / `PERMISSION_DENIED` → K1 (`k1Denied({ what:"Bạn chưa có quyền trả hàng nhà cung cấp" (mới), next:"Liên hệ chủ cửa hàng để được cấp quyền." })`).

*SCR-039 Bàn giao trả nhà cung cấp* (vấn đề 4)

8. Thứ tự: banner chặn (nếu có) → **"Giao cho" (chữ BJ-05)** `dsSegmented` **"Nhà cung cấp nhận" (mới)** | **"Đơn vị vận chuyển" (chữ BJ-05)** (mặc định "Nhà cung cấp nhận"; ghi `evidence.recipient`) → "Hàng sẽ bàn giao" (giữ) **"{n} mặt hàng · {m} dòng" (mới)** → bảng (web) / nhóm (iPhone) chỉ đọc → **"Xác nhận khi hàng đã giao thực tế. Tồn vật lý và giá trị chỉ giảm sau bước này." (mới, theo câu BJ-05)**. Bỏ khối "Thông tin bàn giao" (phụ đề màn "{mã yêu cầu} · {NCC}" thay; web vào khối "Tóm tắt").
9. `SOURCE_CHANGED` → `k1Stale({ title:"Cần kiểm lại trước khi bàn giao" (giữ), description:"Yêu cầu nguồn đã đổi. Chỉ phần bị ảnh hưởng cần kiểm lại." (giữ), actionLabel:"Kiểm lại hàng" (giữ) })`; `PHYSICAL_MISMATCH` / `VALIDATION_ERROR` → banner "Cần kiểm lại trước khi bàn giao" + "Một số hàng chưa đủ điều kiện bàn giao. Hãy kiểm lại." (giữ) + chân "Kiểm lại hàng". Web: `k7Split` — trái bảng; phải "Giao cho" + "Tóm tắt"; chân thanh nút bên phải "Xác nhận đã bàn giao" (giữ).

*SCR-041 Kết quả trả nhà cung cấp* (K4 — vấn đề 5)

10. `COMPLETED` → `k4Result({ screenTitle:"Kết quả trả nhà cung cấp" (giữ), title:"Đã bàn giao cho nhà cung cấp" (giữ), description:"Tồn vật lý và giá trị đã giảm theo đúng hàng bàn giao." (giữ) })`; `facts`: Nhà cung cấp · Yêu cầu trả · Chứng từ nguồn · "Giao cho" · **"Người bàn giao"** (chữ BJ-05) · "Bàn giao lúc" (**điền thật** — `confirmedAt` cố định "17/09/2026 16:05" ở fixture, hết "—"); liên kết **"Xem {n} dòng hàng"** (chữ BJ-02) mở sheet danh sách (thay danh sách dài trong màn).
11. Bước tiếp: còn yêu cầu "Cần chuẩn bị" / "Sẵn sàng" khác → phụ **"Về hàng cần xử lý"** | chính **"Chuẩn bị yêu cầu tiếp theo" (mới, theo "Lấy đơn tiếp theo" BJ-05)**; không còn → một nút "Về hàng cần xử lý".
12. `UNKNOWN` → `k3Unknown({ operation:"Bàn giao trả nhà cung cấp" (mới), scope:"{yêu cầu} · {NCC}", ref: operationId, sentAt, sourceFlow:"UIF-07", handoff:{ operation: operationId, scope:"{yêu cầu} · {chứng từ}" } })` — giá trị gửi BJ-17 giữ như cũ để bước BJ-17 của `SC_bj17_from_bj07` khớp; không truyền `safe`. `REJECTED_EXECUTION` → K4 cảnh báo "Chưa ghi nhận bàn giao" + câu (giữ) + "Xem yêu cầu hiện tại" / "Về hàng cần xử lý". `PERMISSION_DENIED` → K1. `PROCESSING` → `k1Loading`. `PENDING_APPROVAL` / `EXPIRED` (trạng thái chung của 041, không có ở BJ-07) → dựng như `COMPLETED` (ghi CHANGELOG).

**BJ-10**

*SCR-040 Đề nghị tiêu hủy* — một mã màn, **bốn chế độ dựng khác hẳn** (spec đã có `PREPARE` / `APPROVAL_REVIEW` / `COMPLETION`) (vấn đề 6–8)

13. **Đề nghị** (`READY`, `VALIDATION_ERROR`, `PRICE_BASIS_REQUIRED`): tiêu đề "Yêu cầu tiêu hủy" (giữ); phụ "{sản phẩm} · Lô {lô}"; `k5LotCard({ compact:true })` (iPhone) / khối "Tóm tắt" (web).
    - "Số lượng đề nghị" (giữ) — `k5QtyField` "Cả {n} {ĐVT}"; lỗi dưới ô **"Tối đa {n} {ĐVT}"**.
    - "Lý do" (giữ) — ô chữ, gợi ý sẵn theo tình trạng lô: Hết hạn → **"Hết hạn dùng" (mới)**, Hỏng → lý do đã ghi khi đổi sang Hỏng (BJ-09) nếu có; người dùng sửa được.
    - **"Cách xử lý" (mới)** `dsSegmented` **"Cửa hàng tự tiêu hủy" (mới)** | **"Thuê đơn vị xử lý" (mới)** (UC-10-01 BF-03 "phương thức xử lý"), không chọn sẵn.
    - **"Ảnh hiện trạng" (mới)** `k5Evidence` bắt buộc (thay ô chữ "Bằng chứng").
    - Chỉ chủ cửa hàng: dòng **"Giá trị ghi giảm dự kiến" "{x} đ" (mới)** (lượng × giá vốn của lô); nhân viên: không có số tiền trong DOM (`FINANCIAL_MASKED`). Bỏ dòng "Căn cứ giá: Giá vốn hiện hành" cho mọi người.
    - Chân `k4ReasonFooter` **"Gửi phê duyệt" (chữ BJ-02, thay "Gửi yêu cầu tiêu hủy")**; lý do: "Nhập số lượng", "Nhập lý do", **"Chọn cách xử lý"**, **"Thêm ảnh hiện trạng"** (mới).
    - `PRICE_BASIS_REQUIRED` (lô chưa có giá vốn — fixture `oil-demo`): banner "Chưa có căn cứ giá hợp lệ" + "Không thể gửi yêu cầu cho đến khi có căn cứ giá chính thức." (giữ); chân tắt, lý do **"Lô này chưa có giá vốn" (mới)**; nháp giữ nguyên (BR-04).
14. **Chờ duyệt** (`PENDING_APPROVAL`, người lập): `k2Pending({ approver:"chủ cửa hàng", sentAt, facts })` + dữ liệu khoá (số lượng, lý do, cách xử lý, ảnh); chân "Về hàng cần xử lý". Toast sau khi gửi: "Đã gửi yêu cầu tiêu hủy" (giữ).
15. **Duyệt** (`APPROVAL_REVIEW`): vào từ Home **"Chờ duyệt"** — nguồn `{ id:"UIF-10", label:"tiêu hủy" (mới) }`, dòng "{sản phẩm} · Lô {lô}" / "{n} {ĐVT} · {người gửi} gửi {lúc}", `__T7_DIRECT_CONTEXTS__["bj10-approval"]`. `k2Decision({ question:"Duyệt tiêu hủy {n} {ĐVT} {sản phẩm} lô {lô}?" (mới), maker, sentAt, attention:[["Giá trị ghi giảm dự kiến", "{x} đ"], ["Sau khi duyệt", "Tồn chưa giảm — giảm khi xác nhận đã tiêu hủy" (mới), "info"]], facts: Lý do · Cách xử lý · Ảnh hiện trạng })`; banner "Phê duyệt chưa phải tiêu hủy" bỏ (đã ở "Sau khi duyệt"). Chân "Từ chối" | "Duyệt" (giữ); từ chối → `k2RejectSheet` lý do bắt buộc. Ai duyệt: `approver` hoặc `owner` (như BJ-09); `SELF_APPROVAL_NOT_ALLOWED` → banner "Không thể tự duyệt" (giữ) + **"Chỉ chủ cửa hàng duyệt tiêu hủy." (mới)**.
16. **Đã duyệt · chờ tiêu hủy** (`APPROVED_PENDING_DISPOSAL`): banner "Đã duyệt — chờ xử lý thực tế" (giữ tiêu đề) + **"Tồn chưa giảm. Tiêu hủy xong thì chụp ảnh hoặc biên bản và xác nhận." (mới)**; facts Đã duyệt · Người duyệt · Cách xử lý; chân chính **"Xác nhận đã tiêu hủy" (giữ chữ)** → chế độ Xác nhận. Người duyệt vừa duyệt xong cũng thấy màn này (thay vì ngõ cụt) với phụ "Về hàng cần xử lý".
17. **Xác nhận đã tiêu hủy** (`COMPLETION`, `COMPLETION_QTY_BLOCKED`): tiêu đề "Xác nhận đã tiêu hủy" (giữ); một dòng "Chỉ xác nhận sau khi đã xử lý thực tế" (giữ tiêu đề banner, bỏ khung banner); "Đã tiêu hủy thực tế" (giữ) — `k5QtyField` "Cả {n} {ĐVT}" (n = lượng đã duyệt), **không điền sẵn**; vượt → lỗi dưới ô **"Tối đa {n} {ĐVT} đã duyệt. Phần vượt cần đề nghị mới." (mới)** (`COMPLETION_QTY_BLOCKED`, chỉ cho lỗi số lượng); **"Ảnh hoặc biên bản tiêu hủy" (mới)** `k5Evidence` bắt buộc; chân nút danger "Xác nhận đã tiêu hủy" (giữ) với lý do "Nhập số lượng đã tiêu hủy" / **"Thêm ảnh hoặc biên bản" (mới)**.
18. `PERMISSION_DENIED` → `k1Denied({ what:"Bạn chưa có quyền tiêu hủy hàng" (mới), next:"Liên hệ chủ cửa hàng để được cấp quyền." })`. Web mọi chế độ: `k7Split` — trái nội dung, phải "Tóm tắt" + ảnh; chân thanh nút bên phải.

*SCR-041 Kết quả tiêu hủy* (K4 — vấn đề 9)

19. `COMPLETED` → `k4Result({ screenTitle:"Kết quả tiêu hủy" (giữ), title:"Đã ghi nhận tiêu hủy" (giữ), description:"Tồn vật lý và giá trị đã giảm theo đúng số lượng thực tế được xác nhận." (giữ) })`; `facts`: Sản phẩm · Lô · "Đã tiêu hủy" (giữ) · **"Còn lại ở lô" (mới, thay "Tồn vật lý còn lại")** · **"Người xác nhận"** · **"Xác nhận lúc"** (mới); chủ cửa hàng thêm **"Giá trị ghi giảm" "{x} đ" (mới)**. Bước tiếp: một nút "Về hàng cần xử lý" (thay "Về hàng có thể xử lý").
20. Từ chối (người duyệt bấm "Xác nhận từ chối"): **`REJECTED`** (trạng thái màn mới, tách khỏi `REJECTED_EXECUTION`) → K4 cảnh báo **"Đã từ chối đề nghị tiêu hủy" (mới)** + "Lý do: {lý do}" (chữ BJ-06) + "Tồn kho không thay đổi." (mới); chân "Về hàng cần xử lý". `REJECTED_EXECUTION` (hệ thống từ chối lúc ghi) → K4 cảnh báo "Chưa ghi giảm" + câu (giữ). `UNKNOWN` / `COMMIT_UNKNOWN` → `k3Unknown({ operation:"Tiêu hủy hàng" (chữ Hub), scope:"{sản phẩm} · Lô {lô}", ref:"{mã đề nghị}", sentAt, sourceFlow:"UIF-10" })`. `PROCESSING` → `k1Loading`.

### 0.5 Trạng thái (sau thiết kế lại)

| Màn | Trạng thái | Hiện gì | Làm được gì | Lối ra |
|---|---|---|---|---|
| 037 (07) | READY / SOURCE_UPDATED | tiến độ, nhóm → lô, "Đúng hàng" | kiểm một chạm, sheet kiểm / chênh lệch, "Rà soát bàn giao" | Quay lại |
| 037 (07) | WAITING / đã hủy | banner, dòng chỉ đọc | — / "Về hàng cần xử lý" | Quay lại |
| 037 (07) | LOCKED | `k1Locked` | — | Quay lại |
| 039 | READY | giao cho, hàng sẽ bàn giao | chọn "Giao cho", "Xác nhận đã bàn giao" | Quay lại |
| 039 | SOURCE_CHANGED | `k1Stale` | "Kiểm lại hàng" | Quay lại |
| 039 | PHYSICAL_MISMATCH / VALIDATION_ERROR | banner | "Kiểm lại hàng" | Quay lại |
| 041 (07) | COMPLETED | K4 | "Xem {n} dòng hàng", "Chuẩn bị yêu cầu tiếp theo", "Về hàng cần xử lý" | Về Kho |
| 041 (07) | REJECTED_EXECUTION | K4 cảnh báo | "Xem yêu cầu hiện tại" | Về Kho |
| 041 (07) | UNKNOWN | K3 | "Chuyển sang xác minh" | "Về Kho" |
| 040 | READY / VALIDATION_ERROR | đề nghị: số lượng, lý do, cách xử lý, ảnh (+ giá trị cho chủ); lỗi tại ô | "Gửi phê duyệt" | Quay lại |
| 040 | PRICE_BASIS_REQUIRED | banner, chân tắt có lý do | — | Quay lại |
| 040 | PENDING_APPROVAL | `k2Pending` | — | "Về hàng cần xử lý" |
| 040 | APPROVAL_REVIEW | `k2Decision` | "Từ chối", "Duyệt" | Quay lại (về "Chờ duyệt") |
| 040 | SELF_APPROVAL_NOT_ALLOWED | banner | — | "Về hàng cần xử lý" |
| 040 | APPROVED_PENDING_DISPOSAL | đã duyệt, chờ tiêu hủy | "Xác nhận đã tiêu hủy" | "Về hàng cần xử lý" |
| 040 | COMPLETION / COMPLETION_QTY_BLOCKED | số lượng thực tế, ảnh / biên bản; lỗi tại ô | "Xác nhận đã tiêu hủy" | Quay lại |
| 041 (10) | COMPLETED | K4 | "Về hàng cần xử lý" | Về Kho |
| 041 (10) | REJECTED (mới) / REJECTED_EXECUTION | K4 cảnh báo | "Về hàng cần xử lý" | Về Kho |
| 041 (10) | UNKNOWN / COMMIT_UNKNOWN | K3 | "Chuyển sang xác minh" | "Về Kho" |
| 037…041 | LOADING / PROCESSING / PERMISSION_DENIED | K1 | — | "Về Kho" |

### 0.6 Khuôn dùng lại (không dựng mới)

- K5 (`render036K5`, `render037K5`, `k5LotCard`, `k5QtyField`, `k5Evidence`, `k5Open`, nguồn `__T7_PROBLEM_SOURCES__`), K1, K2 (BJ-10), K3, K4 (`k4Result`, `k4ReasonFooter`), K6, K7 (`k7Split`, `k7Table`, `k7-wide`), `dsSegmented` ("Giao cho", "Cách xử lý"), thanh tiến độ mảnh BJ-02.
- Nếu K5 thiếu gì cho hai BJ này (vd. `k5Evidence` cần nhiều tệp cho biên bản) → sửa K5, ghi CHANGELOG, chạy lại golden BJ-09.

### 0.7 Không đổi

BJ-07: `io07AllVerified`, `io07ApplySourceUpdate`, `io07CancelSource`, `recordObservation` (bản ghi chênh lệch, chuyển `WAITING`), `slicesResolved` / `sourceSliceSummary` (chỉ đổi chữ hiển thị), `io07CreateResult` (thêm `recipient`, `confirmedAt` cố định ở fixture), `onUnknownHandoff["UIF-07"]`. BJ-10: quy tắc `bj10RequestValid` / `bj10CompletionValid` (thêm cách xử lý + ảnh), duyệt chỉ đổi trạng thái đề nghị, ghi giảm chỉ ở xác nhận. Chữ giữ: liệt kê ở từng điểm 0.4 ("giữ").

### 0.8 Kiểm (bước D)

- Golden **mobile** được khác: `UIF-07_*`, `UIF-10_*`, `SC_bj07_*`, `SC_bj10_*`, `SC_entry_UIF-07_*`, `SC_entry_UIF-10_*`, `SC_banner_040_*`, `SC_bj17_from_bj07_0` (bước 0; bước BJ-17 **phải khớp** nhờ `handoff`), `SC_bj17_from_bj10_*` (phạm vi gửi BJ-17 đổi theo fixture mới — "Amox 500 · Lô L2407-A" → lô thật; ghi CHANGELOG), dòng yêu cầu trả trong 036 (`UIF-0[79]_SCR-036_*`, `SC_k5_*`, `SC_bj09_*` đi qua 036), `SC_bj09_quarantine_to_damaged_*` / `SC_bj09_expired_to_disposal_*` bước cuối (040 mới), mọi ca có Home khi fixture có đề nghị tiêu hủy chờ duyệt (không có ở fixture gốc — chỉ ca kịch bản), `SC_journey_4`. Ca khác khớp `tools/.golden-bj09-after`.
- Golden **web** được khác: như trên với `@web`; ca khác khớp `tools/.golden-bj09-web-after`.
- Kịch bản (mục 6): sửa `SC_bj07_verify`, `SC_bj07_handover`, `SC_bj07_source_changed`, `SC_bj10_flow`, `SC_bj10_approve`, `SC_bj10_complete`; thêm `SC_bj07_quick_verify`, `SC_bj07_split_source`, `SC_bj07_mismatch_wait`, `SC_bj07_next_request`, `SC_bj10_price_missing`, `SC_bj10_reject`, `SC_bj10_owner_self`, `SC_bj10_from_list`, `SC_bj10_qty_over`, `SC_journey_4`.

### 0.9 Ước lượng C–E

~3 ngày: C1 BJ-07 (037 / 039 / 041 + fixture) ~1; C2 BJ-10 (040 bốn chế độ, 041, "Chờ duyệt") ~1,25; C3 `SC_journey_4` + D ~0,5; E ~0,25. (T7-P mục 8.2 ghi 1 + 1 khi còn chia thiết bị chính / phụ; thêm bố cục web cho 6 màn, K2 cho BJ-10.)

### 0.10 Đã chốt khi duyệt brief (2026-10-25): **mọi điểm theo cột "Đề xuất"**

| # | Điểm | Đề xuất | Phương án khác |
|---|---|---|---|
| a | Kiểm hàng trả | **"Đúng hàng" một chạm trên dòng**; sheet chỉ khi cần nhập lô thực tế / chia phần hàng / báo không khớp | Giữ sheet cho mọi dòng (đối chiếu lô bắt buộc mỗi lần) |
| b | "Giao cho" ở 039 | **Thêm** "Nhà cung cấp nhận" \| "Đơn vị vận chuyển" (BJ-07 mục 1; cùng mẫu BJ-05) | Không thêm; ghi lệch vào T7-P mục 13 |
| c | SCR-040 | **Giữ một mã màn, bốn chế độ dựng khác hẳn** (đề nghị / chờ duyệt / duyệt / xác nhận) | Tách thành mã màn mới cho "Xác nhận đã tiêu hủy" (thêm Screen Contract) |
| d | Ai xác nhận đã tiêu hủy | **Bất kỳ nhân viên có quyền**, mở từ 036 chip "Tiêu hủy" hoặc ngay sau khi duyệt; giữ lối `entry=completion-operator` | Chỉ vai "người xác nhận" riêng (cửa hàng 1–3 nhân viên không có vai này) |
| e | "Cách xử lý" ở đề nghị | **Thêm** (UC-10-01 BF-03 "phương thức xử lý", prototype đang thiếu) | Không thêm; ghi lệch spec |
| f | Tiền ở BJ-10 | **Chủ cửa hàng thấy "Giá trị ghi giảm dự kiến" khi đề nghị / duyệt và "Giá trị ghi giảm" ở kết quả**; nhân viên không thấy số | Không hiện tiền ở BJ-10 |
| g | 041 BJ-07 | **"Chuẩn bị yêu cầu tiếp theo"** khi còn yêu cầu | Chỉ "Về hàng cần xử lý" |
| h | Chữ "nguồn tồn" | **Đổi** "Trả từ phần hàng nào" / "Cần chọn phần hàng" | Giữ "Xác định nguồn tồn" |
| i | Từ chối tiêu hủy | **Trạng thái 041 mới `REJECTED`** "Đã từ chối đề nghị tiêu hủy" (tách khỏi lỗi thực thi) | Dùng `REJECTED_EXECUTION` như hiện tại |

---

## 1. Mục tiêu

1. Kiểm hàng trả nhanh (một chạm mỗi dòng), chữ không thuật ngữ; bàn giao nói rõ giao cho ai; kết quả có thời điểm và bước tiếp.
2. Tiêu hủy đi trọn vẹn đề nghị → duyệt → xác nhận mà **không ngõ cụt**, mỗi bước nhìn khác nhau, có ảnh; chủ cửa hàng duyệt từ "Chờ duyệt" và thấy giá trị.
3. Hết chặng 4: `SC_journey_4` 0 lỗi ở cả hai khung; lối vào chặng 4 trên Home Kho nối xong.
4. Mọi trạng thái 0.5 dựng khác nhau và có lối ra, ở cả hai khung.

## 2. Chuẩn bị

1. BJ-09 đã làm và review (plan BJ-09 mục 13). Rà lại plan này theo code BJ-09: tên hàm K5, nguồn `__T7_PROBLEM_SOURCES__`, `k5Open` / lối vào, dòng tạm của BJ-07 / BJ-10 (plan BJ-09 mục 4.1 điểm 2) — ghi lệch vào mục 9.
2. Mốc = `tools/.golden-bj09-after` / `tools/.golden-bj09-web-after`. Nếu review BJ-09 sửa code sau khi chụp → chụp lại ở HEAD, so khớp, đặt tên `tools/.golden-bj07-base` / `-web-base`.
3. GitNexus (CLAUDE.md): `impact` hướng upstream cho `render037BJ07`, `render039BJ07`, `render041BJ07`, `io07CreateResult`, `ensureIo07ReviewFixture`, `render040BJ10`, `render041BJ10`, `render040IC10`, `render041IC10`; báo mức rủi ro vào mục 9.
4. Máy chủ `python3 -m http.server 8765 --bind 127.0.0.1 &` trong `html/`.

## 3. Fixture (commit 1 phần BJ-07, commit 2 phần BJ-10)

| Fixture | Hiện tại | Sau |
|---|---|---|
| RTV-260827-02 (Minh Dũng) | Nobivac "SP-00142" hai nhóm hộp / lọ | Nobivac DHPPi **SP-000184** (DH2507 4 hộp có hai phần hàng — giữ ca chia phần; DH2511 2 hộp); nhóm thứ hai đổi thành **Tylosin 20% · SP-000122 · TY2511 · 3 lọ**; Găng tay **SP-000271** 5 hộp |
| RTV-260903-03 (Thú Y Hoàng Gia) | Amox 500 AM2505 2 hộp, đã kiểm (trùng lô cách ly của chặng 4) | **Oxytetracycline LA · SP-000147 · không theo lô · 4 chai**, **chưa kiểm** (cho `SC_journey_4` kiểm một chạm) |
| RTV-260827-04, -05, -06 | — | giữ; mã SP theo BJ-01 nếu có |
| `confirmedAt` BJ-07 | `isoNow()` (thời gian thật — ảnh không lặp lại được) | cố định "17/09/2026 16:05" |
| `ensureIo07ReviewFixture` | sửa fixture khi dựng 039 | bỏ; thay bằng `bj07Seed(screen, state)` như `io05Seed`: chỉ dựng lại fixture khi trạng thái đặt từ ngoài (golden / bộ chọn), không khi đi bằng nút |
| Đề nghị tiêu hủy `bj10Requests` | biến rời `bj10RequestQty`… cho một yêu cầu ghi cứng | mảng yêu cầu; sẵn **TH-260910-01**: `glove-nitrile` 3 hộp Hỏng, "Rách bao bì, không dùng được", "Thuê đơn vị xử lý", ảnh mẫu, chủ cửa hàng duyệt "12/09/2026 10:15" → **Đã duyệt · chờ tiêu hủy** (dòng "Tiêu hủy" của 036; `entry=completion-operator` mở ca này) |
| Giá vốn (chỉ chủ thấy) | "Giá vốn hiện hành" (chữ) | `t7Lots` thêm `unitCost`: Tylosin 85.000 đ/lọ, Amox 42.000 đ/hộp, Găng tay 65.000 đ/hộp; `oil-demo` **không có** → `PRICE_BASIS_REQUIRED` thật |
| Mã đề nghị mới | "TH-0709-04" | `TH-260917-{nn}` tăng dần |

## 4. Bước C1 — BJ-07 (commit 1)

### 4.1 Dữ liệu và sự kiện (`app/bj07.js`)

1. Fixture mục 3; `bj07Seed`.
2. Nguồn K5: `__T7_PROBLEM_SOURCES__.push({ id:"UIF-07", rows })` — mỗi yêu cầu còn hiệu lực một dòng `kind:"REQUEST"`, `job: WAITING` khi `queue==="WAITING"` (dòng tắt), còn lại `RTV`; `open` = `applyEntry("UIF-07", "return-task")` với `io07Selected`. Xoá dòng tạm ở `shared-problem.js`.
3. `bj07VerifyQuick(allocationId)`: như nhánh `confirm-allocation` (không áp khi `!slicesResolved` hoặc dòng đang `physicalMismatch`), `verifyMethod:"VISUAL"`.
4. `io07Recipient = "SUPPLIER" | "CARRIER"` (mặc định `SUPPLIER`) → `evidence.recipient` trong `io07CreateResult` (thêm trường).
5. `io07NextActionableRequest()`: yêu cầu `ACTIONABLE` / `READY` đầu tiên khác yêu cầu vừa giao.
6. Gộp hai bộ listener về một khối (`document`, capture, kiểm `activeFlowId==="UIF-07"` đầu hàm); bỏ `stopImmediatePropagation` khi không còn listener chung nào bắt `data-io07-*` (`grep` trước). Nhãn mới: `data-io07-verify-quick`, `data-io07-recipient`, `data-io07-next-request`; giữ `data-io07-*` cũ cho golden.

### 4.2 Màn

| Màn | Việc |
|---|---|
| Chung | `appShell({ …, extraClass:"k7-wide" })`; K1 cho `LOADING` / `PERMISSION_DENIED` (thay `deniedBody` / `loadingBody`) |
| 037 | 0.4 điểm 1–7; nhóm iPhone + `k7Split` / `k7Table` web; sheet kiểm / chênh lệch thành hộp thoại giữa màn ở web; chân `k4ReasonFooter` |
| 039 | 0.4 điểm 8–9 |
| 041 | 0.4 điểm 10–12; sheet "Xem {n} dòng hàng" dùng khuôn sheet BJ-05 029 |
| CSS | gộp `v395-*`, `.io07-*` về khối BJ-07 trong `styles/screens.css`, bỏ `!important` không còn đối thủ |

## 5. Bước C2 — BJ-10 (commit 2)

### 5.1 Dữ liệu và sự kiện (`app/bj10.js`)

1. `bj10Requests` (mục 3) + đề nghị đang mở `bj10SelectedId`; lô lấy từ `t7Lot(k5SelectedLotId)` (thay hằng "Amox 500 · L2407-A · 6 hộp").
2. Vòng đời: `DRAFT` → (`submit`) `PENDING` → (`approve`) `APPROVED` / (`reject` + lý do) `REJECTED` → (`complete`) `COMPLETED`; khi `COMPLETED`: `t7Lot.qty -= actual` (hết thì lô rời danh sách), ghi `completedBy`, `completedAt` cố định.
3. Ai duyệt: `bj10CanDecide()` = `["approver", "owner"].includes(currentActor())` (thay `bj10IsApprover`). Ai xác nhận: mọi vai có quyền (0.10 d) — bỏ chặn `bj10IsCompletion`.
4. Nguồn K2 `{ id:"UIF-10", label:"tiêu hủy", needsActivation:true, rows }` + `__T7_DIRECT_CONTEXTS__["bj10-approval"]`. Nguồn K5 `{ id:"UIF-10", rows }`: đề nghị `PENDING` → `job: WAITING` "Chờ duyệt", `APPROVED` → `job: DISPOSAL` "Chờ tiêu hủy" (mở 040 `APPROVED_PENDING_DISPOSAL`); lô có đề nghị đang chạy không còn ở "Cần xử lý" (K5 gộp theo lô — một lô một dòng). Xoá dòng tạm ở `shared-problem.js`.
5. `entryTargets["UIF-10"]`: `completion-operator` → 040 `APPROVED_PENDING_DISPOSAL` của TH-260910-01 (thay `COMPLETION` — vào thẳng ô nhập là bỏ qua bước xem đã duyệt gì); `approver` → 040 `APPROVAL_REVIEW` của đề nghị chờ duyệt mới nhất, không có thì K2 rỗng "Không có đề nghị chờ duyệt" (**mới**).
6. Listener: một khối, kiểm `activeFlowId==="UIF-10"` đầu mọi listener (sửa lỗi `input` bắt ở mọi luồng); nhãn `data-v350-ic10-*` / `data-ic10-*` → `data-bj10-*` (sửa `tools/golden.mjs`). Xoá `render040IC10`, `render041IC10`, `render036BJ10`, `render037BJ10` (đã thay bằng K5), `getIC10` nếu không còn ai đọc.
7. `bj10Seed(screen, state)` như `bj09Seed`: 040 `READY` = đề nghị nháp cho `tylo-ty2408`; `PRICE_BASIS_REQUIRED` = `oil-demo`; `APPROVAL_REVIEW` / `PENDING_APPROVAL` = đề nghị mẫu Tylosin 11 lọ đã gửi; `COMPLETION*` / `APPROVED_PENDING_DISPOSAL` = TH-260910-01; 041 `COMPLETED` = TH-260910-01 đã xác nhận 3 hộp.

### 5.2 Màn

| Màn | Việc |
|---|---|
| 040 | 0.4 điểm 13–18 — một hàm dựng, rẽ theo chế độ (`bj10Mode(state)` → `PREPARE` / `PENDING` / `REVIEW` / `APPROVED` / `COMPLETION`) |
| 041 | 0.4 điểm 19–20; thêm `REJECTED` vào danh sách trạng thái SCR-041 (`data/workbench-data.js` hoặc nơi khai báo `screens`) |
| Hub | không đổi Home ngoài nguồn "Chờ duyệt" |
| CSS | gộp luật `[data-active-uif="UIF-10"]` / `v350-ic10-*` về khối BJ-10; bỏ `!important` không còn đối thủ |

## 6. Golden và `SC_journey_4` (commit 3, cùng D)

### 6.1 Golden mở thẳng

Bộ chọn trạng thái: 041 thêm `REJECTED`; ca `PENDING_APPROVAL` / `EXPIRED` của 041 UIF-07 dựng như `COMPLETED` (trùng ảnh có chủ đích — ghi CHANGELOG). Trạng thái đặt từ ngoài dùng `bj07Seed` / `bj10Seed`.

### 6.2 Kịch bản sửa

`SC_bj07_verify` (dòng → sheet → lô sai → "Không khớp" → chọn "Sai lô" → đóng — giữ ý), `SC_bj07_handover` (bỏ phụ thuộc `ensureIo07ReviewFixture`: đi từ 036 kiểm đủ RTV-260903-03 rồi rà soát), `SC_bj07_source_changed`, `SC_bj10_flow` (036 → `tylo-ty2408` → "Đề nghị tiêu hủy" → "Cả 11 lọ" → lý do gợi ý → "Cửa hàng tự tiêu hủy" → ảnh mẫu → "Gửi phê duyệt"), `SC_bj10_approve` (`entry=approver` → "Duyệt" → 040 đã duyệt), `SC_bj10_complete` (`entry=completion-operator` → "Xác nhận đã tiêu hủy" → "Cả 3 hộp" → ảnh → xác nhận → 041).

### 6.3 Kịch bản thêm (`S7 = '?uif=UIF-07&screen='`, `S10 = '?uif=UIF-10&screen='`)

| Kịch bản | Bắt đầu | Bước |
|---|---|---|
| `SC_bj07_quick_verify` | `S7 + 'SCR-036'` | RTV-260827-02 → "Đúng hàng" DH2511 → "Đúng hàng" TY2511 → "Đúng hàng" Găng tay → (DH2507 nút tắt, lý do chân "Còn 1 dòng chưa kiểm") |
| `SC_bj07_split_source` | `S7 + 'SCR-036'` | RTV-260827-02 → dòng DH2507 → chia "Bán được" 2 / "Hỏng" 2 → "Đúng hàng" |
| `SC_bj07_mismatch_wait` | `S7 + 'SCR-036'` | RTV-260827-02 → dòng DH2511 → "Không khớp" → "Sai số lượng" → 1 → "Gửi chênh lệch" → 037 `WAITING` → quay lại → 036 (dòng tắt, chip "Đang chờ") |
| `SC_bj07_next_request` | `S7 + 'SCR-036'` | RTV-260903-03 → "Đúng hàng" → "Rà soát bàn giao" → "Đơn vị vận chuyển" → "Xác nhận đã bàn giao" → 041 → "Xem {n} dòng hàng" → đóng → "Chuẩn bị yêu cầu tiếp theo" |
| `SC_bj10_price_missing` | `S10 + 'SCR-036'` | `oil-demo` (Dùng thử) → 037 → "Đề nghị tiêu hủy" → 040 `PRICE_BASIS_REQUIRED` (banner, chân tắt "Lô này chưa có giá vốn") → quay lại 037 |
| `SC_bj10_reject` | `?uif=UIF-10&entry=approver` (sau khi seed đề nghị Tylosin) | "Từ chối" → lý do → "Xác nhận từ chối" → 041 `REJECTED` |
| `SC_bj10_owner_self` | `T + 'inventory&entry=owner'` | "Hàng cần xử lý" → `tylo-ty2408` → "Đề nghị tiêu hủy" → điền → "Gửi phê duyệt" → `home(…)` → "Chờ duyệt" → dòng "tiêu hủy" → "Duyệt" (không chặn) → "Xác nhận đã tiêu hủy" → "Cả 11 lọ" → ảnh → xác nhận → 041 (có "Giá trị ghi giảm") |
| `SC_bj10_from_list` | `S10 + 'SCR-036'` | chip "Tiêu hủy" → TH-260910-01 (Găng tay) → 040 đã duyệt → "Xác nhận đã tiêu hủy" |
| `SC_bj10_qty_over` | `S10 + 'SCR-040&state=COMPLETION'` | "Đã tiêu hủy thực tế" 5 (lỗi dưới ô) → 3 → ảnh → xác nhận |

Chỉ dùng `data-io07-*` / `data-bj10-*` / `data-k5-*` / `data-theme-*`, không chọn theo chữ. Lô thiếu giá vốn chuyển 040 sang `PRICE_BASIS_REQUIRED` ngay khi mở (không đợi bấm gửi).

### 6.4 `SC_journey_4` — hết chặng 4

Một mạch ở chế độ Toàn Theme 7 (`T + 'inventory'`), vai mặc định (nhân viên), bước duyệt đi qua Home "Chờ duyệt" (dòng gắn vai người duyệt), cả hai khung. Helper `home(…)`, `chain(…)` như `SC_journey_3`.

| # | Bước (tên) | Thao tác | Thấy |
|---|---|---|---|
| 0 | (mở) | — | Home: "Cần chú ý" có "Hàng cần xử lý" "1 lô hết hạn · 1 cách ly / hỏng"… (số theo fixture) |
| 1 | `attention` | Home → "Hàng cần xử lý" | 036 chip "Cần xử lý" |
| 2 | `amox` | dòng `amox-am2505` | 037 Amox 500 · AM2505 · Cách ly, "Từ hàng khách trả RET-260827-03" |
| 3 | `change` → `damaged` → `fill` → `reason` → `photo` → `send` | "Đổi tình trạng" → "Hỏng" → "Cả 2 hộp" → lý do → ảnh mẫu → "Gửi phê duyệt" | 038 chờ duyệt (K2) |
| 4 | `home-1` → `pending` → `case-1` → `approve-1` | về Home → "Chờ duyệt" → dòng "đổi tình trạng" → "Duyệt" | 041 "Đã cập nhật tình trạng" · "Cách ly → Hỏng" |
| 5 | `dispose` | "Đề nghị tiêu hủy" | 040 Đề nghị, Amox 2 hộp Hỏng, lý do gợi ý |
| 6 | `qty` → `method` → `photo-2` → `send-2` | "Cả 2 hộp" → "Thuê đơn vị xử lý" → ảnh → "Gửi phê duyệt" | 040 chờ duyệt |
| 7 | `home-2` → `pending-2` → `case-2` → `approve-2` | về Home → "Chờ duyệt" → dòng "tiêu hủy" → "Duyệt" | 040 Đã duyệt · chờ tiêu hủy |
| 8 | `complete` → `actual` → `proof` → `confirm` | "Xác nhận đã tiêu hủy" → "Cả 2 hộp" → ảnh biên bản → xác nhận | 041 "Đã ghi nhận tiêu hủy" |
| 9 | `to-list` → `rtv-chip` → `rtv` | "Về hàng cần xử lý" → chip "Trả nhà cung cấp" → RTV-260903-03 | 037 "Chuẩn bị hàng trả" (Amox không còn trong danh sách) |
| 10 | `verify` → `review` → `carrier` → `handover` | "Đúng hàng" → "Rà soát bàn giao" → "Đơn vị vận chuyển" → "Xác nhận đã bàn giao" | 041 "Đã bàn giao cho nhà cung cấp" |
| 11 | `home-end` | về Home | Home: "Hàng cần xử lý" bớt 1; "Chờ duyệt" không còn hai dòng vừa duyệt |

Thêm `SC_journey_4` vào `WEB_SCENARIOS`. Kiểm: 0 lỗi JS, mỗi bước đổi màn đúng; nút quay lại / thanh bên không về nhầm màn con Hub (bẫy `SC_journey_2` / `_3`).

## 7. Bước D — kiểm

1. Golden mobile / web so mốc mục 2: chỉ ca ở 0.8 khác; ghi mục 9. Mọi trạng thái 0.5 cho ảnh khác nhau (trừ cặp trùng có chủ đích ở 6.1), cả hai khung — đặc biệt bốn chế độ của 040 và `041 REJECTED` / `REJECTED_EXECUTION`.
2. Bấm thử UIF-07, UIF-10 hai khung + Home "Chờ duyệt" + 036 chip "Trả nhà cung cấp" / "Tiêu hủy": 0 lỗi JS; `node --check app/*.js harness/*.js tools/golden.mjs`.
3. **`/impeccable audit` phạm vi UIF-07 + UIF-10 — chặn commit E.** Chạy trên 037 BJ-07 (READY, SOURCE_UPDATED, WAITING, sheet kiểm, sheet chia phần hàng, sheet chênh lệch), 039 (READY, SOURCE_CHANGED, PHYSICAL_MISMATCH), 041 BJ-07 (COMPLETED + sheet dòng hàng, UNKNOWN), 040 (đủ bốn chế độ + PRICE_BASIS_REQUIRED, VALIDATION_ERROR, COMPLETION_QTY_BLOCKED, SELF_APPROVAL_NOT_ALLOWED, sheet từ chối), 041 BJ-10 (COMPLETED chủ / nhân viên, REJECTED, UNKNOWN), ở cả hai khung. Đạt khi: chữ ≥ 4,5:1 (badge, phụ đề lô, dòng lý do, chữ trên nút danger); vùng chạm ≥ 44 × 44 ở iPhone (**nút "Đúng hàng" trong dòng**, "Cả {n} {ĐVT}", nút ảnh, `dsSegmented`); nhân viên **không có số tiền trong DOM** ở 040 / 041 (`grep "đ"` trên HTML vai nhân viên); trạng thái "đã kiểm / không khớp" không chỉ bằng màu; web đi được bằng bàn phím (Tab qua bảng → nút "Đúng hàng" → chân; Enter mở / Esc đóng hộp thoại, focus về nút đã mở, Tab không thoát `aria-modal`); web không còn cột 402px; iPhone không bảng ép nhỏ, số và ĐVT không gãy dòng. Lỗi trong phạm vi: sửa ngay; ngoài phạm vi: ghi mục 9.
4. **Audit dọc `SC_journey_4`** (bài học góp ý 2 chặng 3): mọi bước của 6.4, cả hai khung — tương phản, vùng chạm iPhone, tên nút, `alt` ảnh bằng chứng, tràn ngang, nút quay lại.
5. Gửi ảnh: 037 BJ-07 iPhone (sau hai "Đúng hàng") + web, 039 web, 041 BJ-07 iPhone, 040 đề nghị iPhone + web (chủ), 040 duyệt web, 040 đã duyệt iPhone, 040 xác nhận iPhone, 041 BJ-10 chủ, `SC_journey_4` bước 0 và 11 (Home).
6. Mốc hết chặng 4: `tools/.golden-chang4` / `tools/.golden-chang4-web`.

## 8. Bước E — ghi lại (commit 4)

1. `CHANGELOG.md` `[5.14.0] — BJ-07 thiết kế lại` và `[5.15.0] — BJ-10 thiết kế lại; hết chặng 4 (SC_journey_4)`; phiên bản 5.15.0 (`manifest.json`, `harness/workbench.js`, badge `index.html`, nhãn inspector UIF-07 / UIF-10).
2. Viết lại theo `_TEMPLATE.md`: SCR-037 (phần UIF-07 "Chuẩn bị hàng trả" + sheet kiểm / chia phần hàng / chênh lệch), SCR-039, SCR-040 (bốn chế độ), SCR-041 (phần BJ-07, BJ-10; trạng thái `REJECTED` mới); UIF-07 (danh sách chung, kiểm một chạm, "Chuẩn bị yêu cầu tiếp theo"), UIF-10 (lối vào từ 037 / 041 BJ-09, "Chờ duyệt", đã duyệt → xác nhận, lối từ 036 chip "Tiêu hủy").
3. T7-P mục 5 (K5: ghi BJ-07 / BJ-10 đã dùng, phần sửa K5 nếu có); mục 9 BJ-07 / BJ-10 (khuôn thực dùng); mục 2 bảng "Vị trí trên Home Kho" (dòng "Nhập, xuất & hoàn trả": 07 mở danh sách chung chip "Trả nhà cung cấp").
4. `INDEX.md` 036, 037, 039, 040, 041; T7-P mục 13 (chữ mới; "Giao cho" BJ-07; "Cách xử lý" — UC-10-01 BF-03; tiền ở BJ-10 cho chủ; `REJECTED` của 041; phần BJ-10 của dòng "mọi BJ theo K2": UC-10-02 / SCR-040 mục 6 ghi người duyệt `is_owner` / `store_owner`, chủ lập gửi rồi tự duyệt — UC-10 BR-03 đã ghi); mục 14: BJ-07, BJ-10 ✅, chặng 4 `SC_journey_4` ✅.
5. `python3 tools/sync-registry.py`.

## 9. Ghi chú khi làm

**Mốc.** `.golden-bj09-after` khớp hoàn toàn với bản chụp lại ở cây làm việc trước khi sửa → mốc làm việc = `tools/.golden-bj07-base` (mobile 1771 ca) / `tools/.golden-bj07-web-base` (web 881 ca; cả hai khớp `.golden-bj09-after` / `-web-after`). Sau làm: **`tools/.golden-chang4`** (mobile 1882 ca) / **`tools/.golden-chang4-web`** (web 1020 ca), 0 lỗi JS. So mốc: chỉ ca ở 0.8 khác — `UIF-07_SCR-03[6-9]_*` / `UIF-07_SCR-041_*`, `UIF-10_SCR-040_*` / `UIF-10_SCR-041_*`, dòng yêu cầu trả / tiêu hủy trong 036 (`UIF-0[79]_SCR-036_READY`, `UIF-10_SCR-036_READY`, `SC_k5_*`, `SC_ws_movement` / `SC_ws_control`, `SC_bj09_*` qua 036), `SC_bj07_*`, `SC_bj10_*`, `SC_entry_UIF-07_return-task` và `SC_entry_UIF-10_*` (chỉ chữ inspector đổi nhãn phiên bản), `SC_banner_040`, `SC_bj17_from_bj07_0`, `SC_bj17_from_bj10_*`, `SC_bj09_expired_to_disposal` / `SC_bj09_quarantine_to_damaged` / `SC_bj09_owner_self` bước cuối (040 mới). **`SC_bj17_from_bj07_1_handoff` khớp** nhờ `handoff`. Thêm ca mới: SCR-037 `SOURCE_UPDATED` / `WAITING` ×3 luồng, SCR-041 `REJECTED` ×3 luồng, 10 kịch bản mới (gồm `SC_journey_4`).

**GitNexus.** MCP GitNexus **không có trong phiên này** (không có công cụ `impact` / `detect_changes`), nên chưa chạy được hai bước CLAUDE.md yêu cầu. Thay bằng: `grep` toàn cây tham chiếu ra ngoài `bj07.js` / `bj10.js` — chỉ `shared-problem.js` (một dòng `request-disposal` gọi các biến rời của BJ-10, nay gọi `bj10StartDraft`), `bj09.js` (`bj09Restore` gọi `bj07Restore` / `bj10Restore`; `bj09Commit` giữ `unitCost`), `core.js` (`entryTargets["UIF-10"]`), `hub.js` (không đổi, đọc nguồn qua `__T7_PENDING_SOURCES__` / `__T7_DIRECT_CONTEXTS__`), `harness/workbench.js` (nhãn), `data/workbench-data.*` (trạng thái bộ chọn) — rủi ro tương đương **LOW**, và ảnh golden toàn bộ so mốc ở trên. **Việc phiên review / người làm tiếp cần chạy:** `node .gitnexus/run.cjs analyze` rồi `impact` cho `render037BJ07`, `render039BJ07`, `render041BJ07`, `io07CreateResult`, `render040BJ10`, `render041BJ10` và `detect_changes()` trước khi commit.

**Kết quả D.**

- Mọi trạng thái 0.5 dựng được và khác nhau ở cả hai khung (bốn chế độ của 040 + `PRICE_BASIS_REQUIRED`, `VALIDATION_ERROR`, `COMPLETION_QTY_BLOCKED`, `SELF_APPROVAL_NOT_ALLOWED`, sheet từ chối; 041 `REJECTED` / `REJECTED_EXECUTION`). Cặp trùng có chủ đích: 041 UIF-07 `PENDING_APPROVAL` / `EXPIRED` = `COMPLETED`; 037 UIF-07 `EXPIRED` = `READY`; 037 UIF-09 / UIF-10 `SOURCE_UPDATED` / `WAITING` = `READY` (trạng thái chỉ có nghĩa ở UIF-07).
- **Audit** (kịch bản tự viết ở scratchpad, Chrome không giao diện): 50 ca × 2 khung = 100 lượt — 037 (6 trạng thái + sheet kiểm, sheet chia phần hàng, sheet chênh lệch, hai dòng đã kiểm), 039 (5), 041 BJ-07 (5 + sheet), 040 (10 trạng thái × nhân viên / chủ + sheet từ chối), 041 BJ-10 (6 + bản chủ), 036 chip yêu cầu trả: chữ ≥ 4,5:1, vùng chạm iPhone ≥ 44 × 44, không tràn ngang, mọi nút / ô có tên, ảnh có `alt`, **nhân viên không có số tiền trong DOM** (regex số + "đ" trên 040 / 041): **0 lỗi** sau khi sửa một lỗi tìm được — màn duyệt hiện "Giá trị ghi giảm dự kiến" cho người không phải người duyệt khi trạng thái bị đặt từ ngoài (nay có `bj10CanSeeMoney`). Bàn phím web (CDP): Tab qua bảng → "Lô …" → "Đúng hàng" → chân; Enter mở / Esc đóng hộp thoại, focus về nút đã mở, Tab / Shift+Tab không thoát `aria-modal` — đạt cho sheet kiểm (BJ-07), sheet dòng hàng (041), sheet từ chối (BJ-10); lần đầu focus không về nút vì hai phần tử cùng mang `data-io07-allocation` (dòng bảng + nút) → dòng bảng đổi sang `data-io07-row`. Chưa chạy lệnh `/impeccable audit` đầy đủ — việc của phiên review.
- **Audit dọc `SC_journey_4`** (34 bước × 2 khung, `AUDIT_JS`): tương phản, vùng chạm, tên nút, `alt`, tràn ngang; 0 lỗi trong phạm vi. Ngoài phạm vi: nút đóng toast `button.toast-close` 20 × 20 ở bước gửi duyệt (thành phần dùng chung từ lâu, vùng chạm iPhone < 44) — xử lý ở dọn toast chung. Nút quay lại / thanh bên: bước `home-1` / `home-2` / `home-end` về Home đúng ở cả hai khung (không rơi vào màn con Hub).

**Lệch so với plan.**

- **Ảnh trong đề nghị (web):** ô "Ảnh hiện trạng" nằm ở cột trái cùng form (như BJ-09 "Ảnh bằng chứng"); cột phải chỉ có "Tóm tắt". Ở chế độ chờ duyệt / duyệt / đã duyệt cột phải là ảnh hiện trạng (theo plan 18).
- **`SC_bj10_price_missing`:** plan đi `oil-demo` → 037 → "Đề nghị tiêu hủy"; thực tế Dầu sát khuẩn đang có yêu cầu đổi tình trạng chờ duyệt (`ST-260915-01`) nên dòng mở 038 (chỉ đọc) và 037 không có nút "Đề nghị tiêu hủy" (đúng quy tắc: lô có việc đang chạy). Kịch bản đi bằng chính lối vào của nút đó (`bj10StartDraft` + `applyEntry("UIF-10","request")`). Hậu quả cho spec: `PRICE_BASIS_REQUIRED` chỉ gặp được khi lô không có việc đang chạy và chưa có giá vốn — hiện không có lô như vậy trong fixture (Nobivac bán được không đủ điều kiện).
- **Mã yêu cầu / giờ:** `TH-260917-{nn}`, giờ gửi "17/09/2026 15:20", duyệt "15:22", xác nhận "15:40" (cố định); `TH-260910-01` gửi "12/09/2026 09:50", duyệt "10:15".
- **Chữ mới ngoài plan 13:** "Trả từ {tình trạng} {n}" (dòng phần hàng nguồn ở 039 / sheet 041, thay nhãn "Nguồn tồn"); "Chi tiết {n} dòng hàng" / "Hàng đã bàn giao" (tiêu đề sheet 041 BJ-07); "Từ chối đề nghị tiêu hủy?" (tiêu đề sheet từ chối); "Đề nghị" / "Sản phẩm" trong K4 `REJECTED`; "Đã duyệt" · "Người duyệt" · "Cách xử lý" (khối đã duyệt).
- Xoá `.ic-action-stack` / `choice-list` / `io-product-*` cho UIF-10 nhưng **giữ** nhóm luật Figma chung `UIF-08…17` (`:is(...)`, `!important`): UIF-09 còn dùng cùng nhóm, gỡ một vế làm 036 / 037 của hai luồng lệch nhau — dọn khi cả nhóm không còn màn nào cũ (chặng 5).
- Chưa commit (như chặng 2 / 3: để phiên review xem trước, chia commit sau review). Ba mốc trung gian (`.golden-bj07-base`, `.golden-chang4`, `-web`) nằm ở `tools/` (git bỏ qua).

## 10. Thứ tự commit

1. C1 BJ-07 (fixture BJ-07, 037 / 039 / 041, nguồn K5 BJ-07).
2. C2 BJ-10 (fixture BJ-10, 040 / 041, nguồn K2 / K5 BJ-10).
3. C3 `SC_journey_4` + D (golden, sửa sau audit).
4. E (tài liệu, phiên bản, registry).

Như chặng 2 / 3: nếu làm một lượt thì để chưa commit cho phiên review xem trước, chia commit sau review. `detect_changes()` trước mỗi commit.

## 11. Không làm

- Tạo / sửa yêu cầu trả từ Kho, giảm công nợ NCC, chênh lệch giá NCC (Theme 10 / kế toán).
- Trả nhà cung cấp một phần (UC-07-04 không có) và quét mã khi kiểm hàng trả (như BJ-05 0.10 e).
- Bàn giao hàng tiêu hủy cho đơn vị xử lý như một bước riêng (chỉ ghi "Cách xử lý" + ảnh / biên bản).
- Sửa BJ-17 (chỉ giữ giá trị gửi sang qua `handoff`).
- Đổi BJ-02 / BJ-06 sang `k5Evidence`.

## 12. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| "Đúng hàng" một chạm làm nhân viên bỏ qua đối chiếu lô | Chỉ cho dòng không cần chia phần hàng; lô thực tế vẫn nhập được trong sheet; chênh lệch ghi qua "Không khớp" — tồn không giảm tới khi bàn giao |
| Bốn chế độ của 040 trên một hàm dựng thành rối | Một hàm rẽ sớm theo `bj10Mode`, mỗi chế độ một hàm con; golden mỗi trạng thái phải khác nhau (D1) |
| Ghi giảm lô khi xác nhận làm lệch số ở BJ-01 | Chặng 4 không sửa BJ-01 (Tylosin TY2408 ở BJ-01 vẫn 11 lọ sau tiêu hủy trong kịch bản) — ghi mục 9; nối số thật ở Giai đoạn 3 |
| `SC_bj17_from_bj10` đổi phạm vi gửi BJ-17 | Cho phép ở 0.8, ghi CHANGELOG; `SC_bj17_from_bj07` giữ khớp nhờ `handoff` |
| `SC_journey_4` dài (≈ 30 bước) dễ gãy giữa chừng | Bước nhiều thao tác gộp bằng `chain`; mỗi bước kiểm màn đích; chạy riêng từng khung trước khi chụp mốc |

## 13. Chữ trên màn

| Vị trí | Chữ |
|---|---|
| 037 (07) | "{mã yêu cầu} · {NCC}" · "Yêu cầu do Mua hàng chuyển sang Kho · {chứng từ}" · "Đã kiểm {a}/{b} dòng" · "{mã} · Trả {n} {ĐVT}" · "HSD {hsd} · Trả {n} {ĐVT}" · "· Cần chọn phần hàng" · "Trả từ phần hàng nào" · "Lô này có hàng ở nhiều tình trạng. Ghi số lượng trả từ từng phần." · "Cần chia đủ {n} {ĐVT}" · cột "Trả", "Kiểm" · lý do "Còn {n} dòng chưa kiểm", "Có dòng không khớp · chờ Mua hàng cập nhật" · "Về hàng cần xử lý" |
| 039 | "Giao cho" · "Nhà cung cấp nhận" · "Đơn vị vận chuyển" · "{n} mặt hàng · {m} dòng" · "Xác nhận khi hàng đã giao thực tế. Tồn vật lý và giá trị chỉ giảm sau bước này." |
| 041 (07) | "Người bàn giao" · "Xem {n} dòng hàng" · "Chuẩn bị yêu cầu tiếp theo" · K3 "Bàn giao trả nhà cung cấp" |
| 040 | "Hết hạn dùng" · "Cách xử lý" · "Cửa hàng tự tiêu hủy" · "Thuê đơn vị xử lý" · "Ảnh hiện trạng" · "Giá trị ghi giảm dự kiến" · "Gửi phê duyệt" · lý do "Chọn cách xử lý", "Thêm ảnh hiện trạng", "Lô này chưa có giá vốn", "Nhập số lượng đã tiêu hủy", "Thêm ảnh hoặc biên bản" · "Duyệt tiêu hủy {n} {ĐVT} {sản phẩm} lô {lô}?" · "Tồn chưa giảm — giảm khi xác nhận đã tiêu hủy" · "Chỉ chủ cửa hàng duyệt tiêu hủy." · "Tồn chưa giảm. Tiêu hủy xong thì chụp ảnh hoặc biên bản và xác nhận." · "Tối đa {n} {ĐVT} đã duyệt. Phần vượt cần đề nghị mới." · "Ảnh hoặc biên bản tiêu hủy" · Home "tiêu hủy" · "Không có đề nghị chờ duyệt" |
| 041 (10) | "Còn lại ở lô" · "Người xác nhận" · "Xác nhận lúc" · "Giá trị ghi giảm" · "Đã từ chối đề nghị tiêu hủy" · "Tồn kho không thay đổi." |
| Không có quyền | "Bạn chưa có quyền trả hàng nhà cung cấp" · "Bạn chưa có quyền tiêu hủy hàng" · "Liên hệ chủ cửa hàng để được cấp quyền." |

## 14. Review

**Review chặng 4 (BJ-09 + BJ-07 + BJ-10):** (2026-10-25, phiên review) — **đạt có điều kiện**, **đạt hẳn sau R1–R3** (v5.15.1, xem "Đã sửa" cuối mục). Review của BJ-09 trỏ về đây.

| Kiểm (chạy lại) | Kết quả |
|---|---|
| `node --check app/*.js harness/*.js tools/golden.mjs` | Sạch |
| Golden mobile / web chụp lại (tuần tự — chụp song song hai khung làm Chrome rớt CDP) | 1882 / 1020 ca, 0 lỗi JS; "Khớp hoàn toàn" với `tools/.golden-chang4` / `-web` (mốc tái lập được) |
| `.golden-chang3` → `.golden-chang4` | 687 / 406 khác biệt. Ngoài phạm vi 0.8 của hai plan còn các ca có Home (`SC_journey_1…3`, `SC_ws_*`, `SC_pending*`, `SC_quick_*`, `HUB_home`…) — `diff` thân `.txt` **chỉ** khác dòng "Cần chú ý" ("Lô sắp hết hạn · 3 lô" → "Hàng cần xử lý · 1 lô hết hạn · 1 cách ly / hỏng") và "Chờ duyệt" (+ "1 đổi tình trạng", 4 → 5, thêm dòng `ST-260915-01`) |
| Tiền ở BJ-10 | Số "… đ" chỉ có trong ca vai chủ / người duyệt (`SC_bj10_owner_self_*`, `SC_bj10_approve_1`, `SC_bj10_reject_*`); ca nhân viên không có |
| Tài liệu bước E | SCR-036…041, UIF-07 / 09 / 10: `IN_REVIEW`, không còn đoạn `### vX.Y`; SCR-041 có `REJECTED`; SCR-056 giữ `FROZEN` (chỉ sửa lối vào / ra — viết lại ở chặng 6) |
| Registry | `sync-registry.py` chạy lại: không đổi gì (đã khớp) |
| Ảnh | `SC_journey_4` mọi bước hai khung; 037 BJ-07 (`SC_bj07_quick_verify_4`) hai khung; 040 `READY@web`; 041 `REJECTED` |

Lệch plan ở ghi chú (BJ-09 mục 9, plan này mục 9): **chấp nhận**. `PRICE_BASIS_REQUIRED` không gặp được bằng luồng thật với fixture hiện tại — xem góp ý 4. GitNexus: phiên review cũng không có MCP GitNexus → `impact` / `detect_changes()` vẫn chưa chạy; chấp nhận như chặng 1–3 (prototype tĩnh), người commit chạy nếu có công cụ.

**Cần sửa (chặn commit):**

- **R1. Chữ cố định trong `k5Evidence` sai ngữ cảnh.** Khi có ảnh luôn hiện "Ảnh sẽ gửi kèm yêu cầu duyệt", khi trống luôn "Ảnh hiện trạng hàng" — sai ở 040 xác nhận đã tiêu hủy (không còn bước duyệt; là biên bản chứ không phải ảnh hiện trạng — ảnh `SC_bj10_complete_3_proof`, `SC_journey_4_24_proof`) và ở 038 nếu cặp "Ghi nhận ngay" bắt buộc ảnh. Sửa: `k5Evidence` nhận `hint` (plan BJ-09 mục 4.1 điểm 9 đã có) và tiêu đề vùng trống = `label`; 040 xác nhận: **"Lưu cùng ghi nhận tiêu hủy" (mới)**; 038 cặp không cần duyệt: bỏ dòng gợi ý. `setK5Evidence(owner)` cho `bj10c` dùng tệp mẫu "bien-ban-tieu-huy.jpg". Ghi chữ mới vào T7-P mục 13.
- **R2. "Cần chú ý" báo động giả ở 038.** Khối "Sau khi đổi" dựng bằng `k2Attention` nên mang thêm tiêu đề vàng "Cần chú ý" ngay dưới "Sau khi đổi" — kể cả khi chỉ có dòng thông tin "Tổng tồn và giá trị không đổi." (ảnh `SC_journey_4_7_photo` hai khung); ở màn duyệt (`SC_journey_4_11_case-1@web`) "Cần chú ý" chỉ chứa đúng câu trấn an đó. Sửa: `k2Attention(rows, { title })` (mặc định "Cần chú ý" — BJ-02 / 06 / 10 / 12 không đổi ảnh); 038 lập: khối "Sau khi đổi" không tiêu đề phụ; 038 duyệt: chỉ có "Cần chú ý" khi có dòng cảnh báo ("Đơn đang giữ … cần phân bổ lại"), còn lại các dòng "Sau khi đổi" vào khối số liệu.
- **R3. Chữ gãy dòng (tiêu chí D, bài học R2 chặng 3).** (a) 041 BJ-07 iPhone: nút chân "Chuẩn bị yêu cầu tiếp theo" gãy hai dòng (`SC_journey_4_32_handover`) — rút còn **"Yêu cầu tiếp theo"** (ghi mục 13) hoặc chân xếp dọc khi nhãn dài; (b) 036 iPhone: phụ dòng lô "Lô TY2408 · HSD 31/07/2026 ·" + "11 lọ" xuống dòng với "·" treo cuối dòng (`SC_journey_4_1_attention`) — trong `t7LotSub` nối " · " trước số lượng bằng khoảng trắng không ngắt để "· 11 lọ" đi cùng nhau; (c) web câu hỏi duyệt 038 gãy giữa tên tình trạng "Cách / ly" (`SC_journey_4_11_case-1@web`) — nối tên tình trạng trong câu hỏi bằng khoảng trắng không ngắt. Kiểm lại hai khung các ảnh nêu trên.

**Góp ý nhỏ (không chặn):**

1. **041 `REJECTED`:** biểu tượng đồng hồ (nghĩa "đang chờ") cho kết quả đã từ chối — dùng biểu tượng cảnh báo của K4; thêm "Lô" · "Số lượng" vào facts (hiện chỉ "Đề nghị" · "Sản phẩm").
2. **037 BJ-07 dòng "Cần chọn phần hàng":** nút "Đúng hàng" xám không bấm được, việc thật là mở sheet chia phần hàng — đổi nút thành **"Chọn phần hàng"** mở thẳng sheet (bỏ được một lần đoán "chạm vào dòng").
3. **037 K5 "Việc tiếp theo":** khi không có việc đang chạy, khối chỉ còn câu "Trả nhà cung cấp do bộ phận Mua hàng…", hành động thật ở chân — tiêu đề hứa nhiều hơn nội dung. Cân nhắc bỏ tiêu đề khi chỉ có ghi chú; badge tình trạng lặp chữ ngay trong dải số ("Cách ly" + "2 hộp Cách ly").
4. **`PRICE_BASIS_REQUIRED` không với tới được** bằng luồng thật (lô không giá vốn duy nhất đang có việc chờ duyệt). Thêm một lô "Hỏng" không giá vốn, không việc đang chạy vào fixture chặng 4 (một dòng, golden chỉ đổi 036 / Home) hoặc ghi T7-P mục 13 để chốt đặc tả 7.3 biết.
5. **Toast `button.toast-close` 20 × 20** (ghi chú mục 9, ngoài phạm vi): đưa vào đợt dọn chung cuối Giai đoạn 2 cùng dòng "bẫy focus cho mọi sheet" (T7-P mục 13).

**Đã sửa (2026-10-25, phiên review theo yêu cầu người dùng, v5.15.1) — review đạt:** R1 (`k5Evidence` thêm `emptyTitle` / `hint`; 040 xác nhận "Ảnh hoặc biên bản sau khi tiêu hủy" / "Lưu cùng ghi nhận tiêu hủy"; 038 cặp không cần duyệt bỏ dòng gợi ý; biên bản mẫu "bien-ban-tieu-huy.jpg"), R2 (`k2Attention(rows, { title })`, `.k2-attention--plain`; 038 lập và duyệt như mô tả ở R2), R3 ("Yêu cầu tiếp theo"; `t7LotSub` nối "·{NBSP}{n} {ĐVT}" — khi gãy, "· 11 lọ" xuống dòng cùng nhau; tên tình trạng trong câu hỏi duyệt nối NBSP). Kiểm: `node --check` sạch; golden 1882 / 1020 ca, 0 lỗi JS, chỉ ca nêu ở CHANGELOG `[5.15.1]` khác mốc, không ca BJ-02 / 06 / 12 nào đổi; ảnh 036 / 041 BJ-07 / 040 xác nhận iPhone, 038 lập / duyệt web đã xem. GitNexus CLI (`node .gitnexus/run.cjs impact --repo erp-sales-inventory`): `k2Attention` **LOW** (4 nơi gọi: `k2Decision`, `render010BJ02`, `render011BJ02`, `render070BJ12`); `k5Evidence` / `t7LotSub` chưa có trong chỉ mục (hàm mới). Mốc `tools/.golden-chang4*` chụp lại (v5.15.1). Góp ý 1–5 để lại.

**Phạm vi commit:** cây làm việc chỉ có chặng 4 (v5.13.0 → v5.15.0) + plan chặng 5 (chưa theo dõi, brief đã duyệt 2026-10-25). Sau R1–R3: chia commit theo mục 10 của hai plan nếu tách được theo tệp; không thì một commit chặng 4 + một commit plan chặng 5.
