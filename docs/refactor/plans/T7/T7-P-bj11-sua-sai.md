# T7-P · BJ-11 Hủy & sửa sai — thiết kế lại (bước B–E)

> Theme: Theme 7 Inventory · Trạng thái: Brief ✅ (duyệt 2026-10-25 — mục 0.10, mọi điểm theo đề xuất) | Plan C–E ✅ (rà lại theo code BJ-08 khi làm) | Làm ✅ 2026-10-25 (v5.17.0, chưa commit — để phiên review xem trước) | Review ✅ (2026-10-25: đạt sau R1–R3, v5.18.1 — mục 14)
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) mục 8.2 **chặng 5 "Kiểm kê và sửa sai"**, BJ thứ hai. Làm **sau** [BJ-08](T7-P-bj08-kiem-ke.md) (dùng fixture chung chặng 5 ở mục 3 của plan đó). BJ sau: [BJ-16 + BJ-17](T7-P-bj16-bj17-doi-soat.md) — hồ sơ "Cần sửa nghiệp vụ nguồn" mở thẳng màn sửa sai của plan này.
> Dùng lại K1, **K2** (sửa sai cần chủ cửa hàng duyệt — UC-11-04), K3, K4, K6, K7. Không khuôn mới.
> Thiết bị: **cả iPhone và web đều là thiết bị chính** (T7-P mục 2). Người lập (thường người đã ghi sai, hoặc chủ cửa hàng khi đối soát) làm trên iPhone hoặc máy tính; chủ cửa hàng duyệt ở cả hai.
> Ước lượng: **~1,75 ngày, 3 commit** (C1 danh sách + chi tiết + sửa sai + hủy; C2 duyệt + kết quả + D; E). Người làm: bạn. Review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị, chép nguyên văn; **(mới)** = chữ mới, vào T7-P mục 13 ở bước E.

## 0. Brief (bước B, đã duyệt 2026-10-25)

### 0.1 Việc thật

- **Ai, lúc nào:** **vài lần / tháng**. Nhân viên hoặc chủ cửa hàng phát hiện một phiếu kho đã ghi sai — phiếu nhận ghi thừa / thiếu so với hoá đơn, đổi tình trạng nhầm số lượng — thường khi đối chiếu hoá đơn nhà cung cấp, khi hồ sơ đối soát (BJ-16) chỉ ra phiếu sai, hoặc khi xem thẻ kho. Ít hơn nữa: hủy một yêu cầu kho **chưa thực hiện** (gửi nhầm). Chủ cửa hàng duyệt mọi lần sửa phiếu đã ghi.
- **Cần biết / làm gì:** phiếu này **hủy được hay phải sửa**, vì sao (bằng lời thường); sửa thì sửa thành bao nhiêu, tồn sẽ đổi ra sao, phiếu cũ có mất không. Chủ cửa hàng: phiếu nào, sai gì, sửa từ bao nhiêu thành bao nhiêu, ảnh hưởng tồn và tiền → duyệt / từ chối.
- **Quy tắc** (BJ-11, UC-11-01…05 BR-01…06, UIF-11): chỉ phiếu **chưa thực hiện** (nháp / chờ duyệt / sẵn sàng) mới hủy được, hủy không tạo biến động tồn / giá trị (BR-01); phiếu kết quả **chưa xác định** không hủy, không sửa — đối soát bằng đúng mã (BR-02, BJ-17); phiếu **đã hoàn tất không sửa tại chỗ** — tạo phiếu sửa sai liên kết, phiếu gốc giữ nguyên (BR-03); chặn khi sửa làm âm tồn hoặc có nghiệp vụ phía sau phụ thuộc (BR-04); "sửa phần sai" khi chỉ phần chênh sửa riêng được, "hoàn nguyên và ghi lại" khi cả phiếu sai (BR-05); hàng bán đã giao cho khách chỉ quay về kho qua BJ-06, không qua sửa sai (BR-06); duyệt không tự ghi — hệ thống kiểm lại điều kiện rồi mới ghi (UC-11-04); người duyệt = `is_owner` hoặc `store_owner`, chủ cửa hàng lập thì vẫn gửi rồi tự duyệt (T7-P mục 2, K2); sửa sai trong kỳ đã khoá ghi vào kỳ đang mở, không có kỳ mở thì chặn.
- **Ranh giới chặng 5:** BJ-16 kết luận "cần sửa phiếu gốc" thì chuyển sang đây (00-business-journey-map: BJ-16 → BJ-11); BJ-11 sửa xong thì hồ sơ BJ-16 kiểm lại và đóng (plan sau). BJ-11 không tự đóng hồ sơ đối soát.

### 0.2 Luồng hiện tại

Ảnh: `tools/.golden-bj08-after/UIF-11_*`, `SC_bj11_*`, `SC_bj16_correction_*`; web `tools/.golden-bj08-web-after/UIF-11_*@web`.

```text
Hub Kiểm kê & xử lý → "Hủy & sửa sai nghiệp vụ" → 048 "Kiểm soát nghiệp vụ kho" (5 nghiệp vụ; dòng tiêu đề = loại, phụ = "IO-… · PN-… · hàng")
  dòng → 049 "Chi tiết nghiệp vụ kho" (nhãn–giá trị "Kho / Hàng / Số lượng / Tác động")
     có thể hủy → "Hủy yêu cầu" → 052 "Hủy yêu cầu kho" (ô lý do) → 053 "Đã hủy yêu cầu"
     có thể sửa → "Sửa sai" → 052 "Chọn cách sửa" (radio) → "Tiếp tục" → 050 "Nội dung sửa sai" (số đúng, lý do có sẵn chữ) → "Gửi phê duyệt" → 053 "Đã gửi chờ duyệt"
     chưa xác định → "Xác minh kết quả" → BJ-17 · đã giao khách → banner, "Về danh sách"
  người duyệt: ?entry=approver → 051 (luôn là IO-260901-014) → "Duyệt" → 053 PROCESSING → 053 "Đã hoàn tất sửa sai"
BJ-16 hồ sơ "Cần sửa nghiệp vụ nguồn" → "Mở yêu cầu sửa sai" → 049 → (như trên); không có đường quay về hồ sơ
```

### 0.3 Vấn đề

| # | Màn | Vấn đề |
|---|---|---|
| 1 | 048 | Tiêu đề "Kiểm soát nghiệp vụ kho" khác chữ Hub; dòng lấy **mã IO nội bộ** làm phụ đề, tiêu đề là loại ("Nhận hàng") — người dùng tìm phiếu theo **mã phiếu** (PN-…) và sản phẩm; chip không số; badge "Luồng trả hàng" khó hiểu; không theo K6 (web không có bảng) |
| 2 | 049 | Không nói **vì sao** hủy được / phải sửa; bảng "Kho / Hàng / Số lượng / Tác động" lặp; khối "Dấu vết" một dòng cố định; nút "Hủy yêu cầu" danger là nút chính duy nhất; nhánh hàng đã giao không có lối sang Hàng khách trả |
| 3 | 052 → 050 | Hai màn cho một việc (chọn cách → nhập số); mô tả cách sửa trừu tượng; banner "Nghiệp vụ gốc luôn được giữ nguyên…" luôn hiện; "Kỳ gốc: Đã khóa" không nói sửa ghi vào kỳ nào; 052 hủy là một màn chỉ có ô lý do |
| 4 | 050 | Ô "Lý do sửa sai" **có sẵn chữ** ("Ghi nhận thừa 2 hộp khi nhận hàng"); "Hệ thống tự tính · Điều chỉnh" không nói tồn sau sửa; `VALIDATION_ERROR` banner chung; `DEPENDENCY_BLOCKED` không nói nghiệp vụ nào phụ thuộc; `CONFLICT` không có nút mở yêu cầu đang chờ |
| 5 | 051 | Không theo K2; **luôn hiện `cr11Operations[1]`** (không phải yêu cầu đang duyệt); không có trong Home "Chờ duyệt"; "Công việc phê duyệt độc lập" (kỹ thuật); không tiền dù chủ duyệt; **chủ cửa hàng tự lập bị chặn** (chỉ `actor === "approver"`); sheet từ chối riêng |
| 6 | 053 | `ioResult` canh giữa; `COMPLETED` ghi cứng "IO-260901-014" và tính "Điều chỉnh" bằng `số đúng − 120` (sai với phiếu khác); `PENDING_APPROVAL` là màn kết quả thay vì K2 chờ duyệt; `UNKNOWN` không theo K3; tiêu đề `CANCELLED` là "Kết quả kiểm soát" (khác các trạng thái còn lại) |
| 7 | BJ-16 → BJ-11 | Đi sang BJ-11 xong không có đường về hồ sơ đối soát để kiểm lại và đóng |
| 8 | Fixture | Sản phẩm / lô lệch các chặng trước (Amox lô L2407-A, Vitamin C L2310-C); Nobivac DH2507 vừa là phiếu sửa sai vừa là hồ sơ "số trên app lệch" (hai câu chuyện chồng nhau) |
| 9 | Web | Cột iPhone 402px giữa khung |
| 10 | Mã | `ac310SanitizeMarkup` / `ac310Return`, `cr11ListRows` (nhánh trùng của 048), `deniedBody` / `loadingBody` / `ioEmpty` / `ioResult`, hai hàm khối số (`bj11KeyValueSurface` và `ac310KeyValueSurface`), nhãn `data-v350-action="cr11-*"`, `data-v360-action="fallback-exit"`; `setTimeout` 300 ms cho `PROCESSING` |

### 0.4 Đề xuất

**Luồng mới**

```text
Hub Kiểm kê & xử lý → "Hủy & sửa sai nghiệp vụ" → 048 "Hủy & sửa sai" (K6: chip có số "Tất cả · Hủy được · Sửa được · Đang chờ")
  dòng → 049 "{loại} {mã phiếu}" (một câu "hủy được / phải sửa / không sửa ở đây" + phiếu gốc + "Việc tiếp theo")
     hủy được → "Hủy yêu cầu" → sheet có lý do → 053 đã hủy (K4)
     sửa được → "Sửa sai" → 050 "Sửa sai" (cách sửa + số đúng + lý do + "Sau khi sửa") → "Gửi phê duyệt" → 053 chờ duyệt (K2) + toast
     chưa xác định → K3 → BJ-17 · đã giao khách → "Mở hàng khách trả" (BJ-06)
  chủ cửa hàng: Home "Chờ duyệt" → dòng "sửa sai" → 051 duyệt (K2, có tiền) → "Duyệt" → 053 (K4) · "Từ chối" (lý do) → 053 không duyệt
BJ-16 hồ sơ "Cần sửa phiếu gốc" → "Sửa phiếu gốc" → 050 của đúng phiếu (bỏ qua 048 / 049) → … → 053 → "Về hồ sơ đối soát" (BJ-16 079)
```

*SCR-048 Hủy & sửa sai* (K6 — vấn đề 1)

1. Tiêu đề **"Hủy & sửa sai" (mới — chữ Hub "Hủy & sửa sai nghiệp vụ" rút gọn; thay "Kiểm soát nghiệp vụ kho")**; phụ **"Phiếu kho gần đây" (mới)**. Ô tìm **"Tìm mã phiếu hoặc sản phẩm" (mới — thay "Tìm mã nghiệp vụ hoặc chứng từ")**.
2. Chip có số: "Tất cả" · **"Hủy được" (mới — thay "Có thể hủy")** · **"Sửa được" (mới — thay "Có thể sửa")** · **"Đang chờ" (chữ BJ-07)** = yêu cầu sửa sai chờ duyệt + phiếu đang xác minh. Phiếu đã giao khách thuộc "Tất cả".
3. Dòng iPhone: tiêu đề **"{loại} {mã phiếu}" (mới)** ("Nhận hàng PN-260904-08"); phụ **"{sản phẩm} · {n} {ĐVT} · {ngày}" (mới)**; badge "Có thể hủy" / "Có thể sửa" (giữ) · **"Chờ duyệt sửa sai" (mới)** · "Đang xác minh" (giữ) · **"Đã giao khách" (mới — thay "Luồng trả hàng")**. Mã IO không hiện ở danh sách (chỉ ở 049 "Mã nghiệp vụ").
4. Web (K7): bảng **"Phiếu"** · **"Loại"** · "Sản phẩm" · "Số lượng" · **"Ngày"** · "Tình trạng" (mới — đầu cột).
5. `rowAttr` (K6): hủy được / sửa được / đã giao khách → 049; chờ duyệt sửa sai → 053 `PENDING_APPROVAL` (chỉ đọc) — chủ cửa hàng thì 051; đang xác minh → 049 `UNKNOWN` (K3).
6. `EMPTY` → `k1Empty` "Chưa có nghiệp vụ cần kiểm soát" (giữ) / "Các nghiệp vụ đủ điều kiện sẽ xuất hiện tại đây." (giữ); `FILTER_EMPTY` → `k1Empty` "Không có nghiệp vụ phù hợp" (giữ) / "Thử đổi bộ lọc hoặc từ khóa tìm kiếm." (giữ) + "Xem tất cả"; `LOADING` / `PERMISSION_DENIED` → K1 (`what:` **"Bạn chưa có quyền hủy hoặc sửa sai" (mới)**, `next:` "Liên hệ chủ cửa hàng để được cấp quyền.").
7. Home "Chờ duyệt": nguồn K2 `{ id:"UIF-11", label:**"sửa sai" (mới)** }`, dòng **"{loại} {mã phiếu} · {sản phẩm}" / "{a} → {b} {ĐVT} · {người lập} gửi {lúc}" (mới)**, mở 051 của đúng yêu cầu.

*SCR-049 Chi tiết nghiệp vụ kho* (vấn đề 2)

8. Tiêu đề **"{loại} {mã phiếu}" (mới — thay "Chi tiết nghiệp vụ kho")**; phụ "{sản phẩm} · Lô {lô}" (chữ BJ-09).
9. Khối **"Việc tiếp theo" (chữ BJ-09)** — một câu giải thích theo trường hợp, nút ở chân:

   | Trường hợp | Câu | Chính | Phụ |
   |---|---|---|---|
   | Chưa thực hiện (`CANCELABLE`) | "Nghiệp vụ chưa thực thi nên có thể hủy mà không tạo biến động tồn kho." (giữ) | "Hủy yêu cầu" (giữ, tone danger) | — |
   | Đã hoàn tất (`CORRECTABLE`) | **"Phiếu đã ghi vào kho nên không sửa thẳng. Sửa sai sẽ ghi thêm một phiếu liên kết; phiếu này giữ nguyên." (mới)** | "Sửa sai" (giữ) | — |
   | Đã giao khách (`BLOCKED_PHYSICAL_HANDOVER`) | "Hàng đã được bàn giao thực tế" (giữ, tiêu đề banner) + "Khách trả hàng phải qua nghiệp vụ Hàng khách trả; không xử lý bằng sửa sai." (giữ) | **"Mở hàng khách trả" (mới — chữ Hub "Hàng khách trả")** → BJ-06 SCR-030 | — |
   | Đã dừng (`TERMINAL`) | "Không còn tác động cần sửa" + "Nghiệp vụ đã dừng trước khi thực thi." (giữ) | — | — |
   | Chờ duyệt sửa sai | `k2Pending` "Chờ chủ cửa hàng duyệt · gửi {lúc}" | **"Xem yêu cầu" (chữ BJ-09)** → 053 | — |
   | Chưa xác định (`UNKNOWN`) | `k3Unknown({ operation:"{loại}", scope, ref:{mã phiếu}, sentAt, sourceFlow:"UIF-11" })` | "Chuyển sang xác minh" (K3) | — |

10. Khối **"Phiếu gốc" (mới)** (nhãn–giá trị): "Mã phiếu" (mới) · **"Mã nghiệp vụ" (mới)** (IO-…) · "Số lượng" (giữ) · **"Ghi vào kho" (mới)** "+{n} {ĐVT} · {ngày}" / "Chưa ghi" · **"Sửa sai trước đó" (mới)** "Chưa có" / "{mã} · {ngày}". Bỏ hàng "Kho", "Tác động" và khối "Dấu vết" một dòng.
11. "Hủy yêu cầu" → sheet **"Hủy yêu cầu {mã phiếu}?" (mới)** + "Tồn kho và giá trị không thay đổi." (giữ) + "Lý do hủy" (giữ, bắt buộc) + "Quay lại" | "Hủy yêu cầu" (giữ) → 053 `CANCELLED`. **SCR-052 bỏ** (điểm 12). `LOADING` / `PERMISSION_DENIED` → K1.
12. Web: `k7Split` — trái "Việc tiếp theo" + "Phiếu gốc"; phải khối "Tóm tắt" (sản phẩm, lô, ngày, người ghi).

*SCR-050 Sửa sai* (gộp SCR-052 vào — vấn đề 3, 4)

13. **Gộp SCR-052 vào SCR-050** (052 → RETIRED, "Bỏ từ v5.17.0"; hủy thành sheet ở 049, điểm 11). Tiêu đề **"Sửa sai" (mới — thay "Nội dung sửa sai" / "Chọn cách sửa")**; phụ "{loại} {mã phiếu} · {sản phẩm}".
14. **"Cách sửa"** (giữ) — `dsChoiceRow` "Sửa phần sai" (giữ) / **"Giữ phần đúng, chỉ ghi thêm phần chênh." (mới — thay "Điều chỉnh riêng phần sai và giữ nguyên phần đúng.")**; "Hoàn nguyên và ghi lại đúng" (giữ) / **"Dùng khi sai cả phiếu (nhầm sản phẩm, nhầm lô): hoàn nguyên rồi ghi lại." (mới)**; chọn sẵn "Sửa phần sai".
15. **"Số đúng"** (giữ) — ô số `k7EditCell` hậu tố ĐVT; dòng gợi ý **"Đã ghi {n} {ĐVT}" (mới)**. **"Lý do sửa sai"** (giữ) — ô chữ **trống**, gợi ý "Mô tả ngắn điều đã sai và căn cứ sửa" (giữ chữ placeholder).
16. Khối **"Sau khi sửa" (mới)** (`k2Attention` tone info): **"Tồn {sản phẩm}: {a} → {b} {ĐVT}" (mới)**; **"Ghi vào kỳ {kỳ mở}" (mới; kỳ gốc khoá thì "· kỳ gốc {kỳ} đã khoá" — chữ BJ-13)**; chủ cửa hàng thêm **"Giá trị: {±x} đ" (mới)** khi có giá vốn; dòng cố định **"Phiếu gốc giữ nguyên; app ghi thêm phiếu sửa sai liên kết." (mới, rút từ banner "Nghiệp vụ gốc luôn được giữ nguyên")**.
17. Chân `k4ReasonFooter` "Gửi phê duyệt" (giữ); lý do khi tắt **"Nhập số đúng" (mới)**, **"Số đúng đang bằng số đã ghi" (mới)**, **"Nhập lý do sửa sai" (mới)**. `VALIDATION_ERROR` → lỗi tại ô (bỏ banner chung). Sau gửi: 053 `PENDING_APPROVAL` + toast "Đã gửi yêu cầu sửa sai" (giữ).
18. `DEPENDENCY_BLOCKED` → `k1Locked({ title:"Chưa thể sửa sai" (giữ), description:**"Sau phiếu này đã {xuất / bán} {n} {ĐVT}; sửa bây giờ làm tồn âm. Xử lý nghiệp vụ đó trước." (mới — thay "Có nghiệp vụ phía sau đang phụ thuộc…")** })` + "Về chi tiết" (giữ). `PERIOD_POLICY_VIOLATION` → `k1Locked` "Chưa có kỳ mở để ghi nhận sửa sai" (giữ) + câu (giữ). `SOURCE_VERSION_STALE` → `k1Stale({ title:"Nghiệp vụ nguồn đã thay đổi" (giữ), description: câu (giữ), actionLabel:"Về chi tiết" })`. `CONFLICT` → `k1Stale({ title:"Đã có yêu cầu sửa sai khác" (giữ), description: câu (giữ), actionLabel:**"Mở yêu cầu đang chờ" (mới)** })`. `PERMISSION_DENIED` → K1.
19. Web: `k7Split` — trái cách sửa + số đúng + lý do; phải "Sau khi sửa" + "Phiếu gốc" thu gọn.
20. **Vào từ BJ-16** (`entry=correction-from-case`, **mới**): mở thẳng 050 của phiếu trong hồ sơ, điền sẵn "Số đúng" theo hồ sơ (số chứng từ), lý do **trống**; ghi `cr11ReturnCase = {mã hồ sơ}`. Quay lại từ 050 → về 079 của hồ sơ (không về 049 / 048).

*SCR-051 Duyệt sửa sai* (K2 — vấn đề 5)

21. Tiêu đề "Duyệt sửa sai" (giữ). `k2Decision({ question:**"Duyệt sửa {loại} {mã phiếu}: {sản phẩm} từ {a} thành {b} {ĐVT}?" (mới)**, maker, sentAt, attention, facts })` — đọc **đúng yêu cầu đang duyệt** (sửa lỗi `cr11Operations[1]`):
    - `attention`: **"Tồn giảm {d} {ĐVT}" / "Tồn tăng {d} {ĐVT}" (mới)**; chủ: **"Giá trị: {±x} đ" (mới)**; khi hoàn nguyên: **"Hoàn nguyên cả phiếu rồi ghi lại" (mới)**.
    - `facts`: "Lý do" (giữ) · "Cách sửa" (giữ) · **"Ghi vào kỳ" (mới)** · khi có: **"Từ hồ sơ đối soát" (mới)** "{mã hồ sơ}".
    - bảng "Trước và sau" (giữ): "Trước" · "Sau" · "Điều chỉnh" (giữ).
    Bỏ banner "Công việc phê duyệt độc lập".
22. Chân "Từ chối" | "Duyệt" (giữ). Từ chối → `k2RejectSheet` (tiêu đề "Từ chối sửa sai" (giữ), "Lý do từ chối" (giữ), "Xác nhận từ chối" (chữ K2)) → 053 `REJECTED`.
23. Ai duyệt được: `currentActor()` là `approver` hoặc `owner`; chủ cửa hàng lập thì tự duyệt (K2). `SELF_APPROVAL_NOT_ALLOWED` chỉ khi người bấm là người lập mà không phải chủ: `vBanner` "Bạn không thể tự duyệt yêu cầu này" (giữ) + **"Chủ cửa hàng sẽ duyệt yêu cầu bạn lập." (mới — thay "Người lập và người duyệt phải độc lập theo chính sách kiểm soát.")**. `APPROVAL_ALREADY_DECIDED` → `k1Locked` "Yêu cầu đã có quyết định" (giữ) + câu (giữ) + "Xem kết quả" (giữ). `PERMISSION_DENIED` → K1.
24. Web: `k7Split` — trái câu hỏi + Cần chú ý + "Trước và sau"; phải "Phiếu gốc" (điểm 10).

*SCR-053 Kết quả sửa sai* (K4 — vấn đề 6, 7)

25. `COMPLETED` → `k4Result({ screenTitle:"Kết quả sửa sai" (giữ), title:"Đã hoàn tất sửa sai" (giữ), description:"Nghiệp vụ gốc được giữ nguyên; bản ghi sửa sai mới đã ghi phần điều chỉnh và liên kết đầy đủ." (giữ) })`; `facts`: "Nghiệp vụ gốc" (giữ, "{loại} {mã phiếu}") · "Bản ghi sửa sai" (giữ) · "Điều chỉnh" (giữ, **tính theo phiếu đang sửa**) · chủ: "Giá trị" · "Người duyệt" · "Ghi nhận lúc". Bước tiếp: vào từ BJ-16 → chính **"Về hồ sơ đối soát" (mới)** (→ UIF-16 079 của `cr11ReturnCase`); còn lại → phụ "Về danh sách" (giữ) | chính "Xem tồn kho" (chữ BJ-02).
26. `PENDING_APPROVAL` → `k2Pending({ approver:"chủ cửa hàng", sentAt, facts:[Nghiệp vụ gốc, "Trước và sau", Lý do] })` + chân "Về danh sách" (giữ) — vào từ BJ-16 thì "Về hồ sơ đối soát". `CANCELLED` → K4 warning, tiêu đề màn **"Kết quả sửa sai" (thống nhất — thay "Kết quả kiểm soát")**, "Đã hủy yêu cầu" (giữ) + câu (giữ) + "Lý do". `REJECTED` → K4 warning "Yêu cầu không được duyệt" (giữ) + câu (giữ) + **"Lý do từ chối" (giữ chữ sheet)**; nút chính **"Sửa lại" (mới)** → 050 với số / lý do cũ. `BLOCKED` → K4 warning "Chưa thể ghi sửa sai" (giữ) + câu (giữ). `UNKNOWN` → `k3Unknown({ operation:**"Ghi sửa sai" (mới)**, scope:"{loại} {mã phiếu}", ref, sentAt, sourceFlow:"UIF-11" })`. `PROCESSING` → `k1Loading` (chỉ khi đặt từ ngoài; "Duyệt" đi thẳng `COMPLETED`, bỏ `setTimeout`). `PERMISSION_DENIED` → K1.

### 0.5 Trạng thái (sau thiết kế lại)

| Màn | Trạng thái | Hiện gì | Làm được gì | Lối ra |
|---|---|---|---|---|
| 048 | READY | K6: chip có số, danh sách / bảng | lọc, tìm, mở phiếu (đúng bước) | Về Kho |
| 048 | EMPTY / FILTER_EMPTY | `k1Empty` | "Xem tất cả" (FILTER_EMPTY) | Về Kho |
| 048…053 | LOADING / PERMISSION_DENIED | K1 | — | "Về Kho" |
| 049 | CANCELABLE | câu, phiếu gốc | "Hủy yêu cầu" → sheet có lý do | Quay lại |
| 049 | CORRECTABLE (`READY`) | câu, phiếu gốc | "Sửa sai" | Quay lại |
| 049 | BLOCKED_PHYSICAL_HANDOVER | banner | "Mở hàng khách trả" | Quay lại |
| 049 | TERMINAL | banner | — | Quay lại |
| 049 | UNKNOWN | K3 | "Chuyển sang xác minh" | "Về Kho" |
| 049 | (chờ duyệt sửa sai) | `k2Pending` | "Xem yêu cầu" | Quay lại |
| 050 | READY / VALIDATION_ERROR | cách sửa, số đúng, lý do, "Sau khi sửa"; lỗi tại ô | "Gửi phê duyệt" | Quay lại (về 049, hoặc 079 khi vào từ BJ-16) |
| 050 | DEPENDENCY_BLOCKED / PERIOD_POLICY_VIOLATION | `k1Locked` | "Về chi tiết" | Quay lại |
| 050 | SOURCE_VERSION_STALE / CONFLICT | `k1Stale` | "Về chi tiết" / "Mở yêu cầu đang chờ" | Quay lại |
| 051 | READY / VALIDATION_ERROR | `k2Decision` (+ sheet từ chối có lỗi) | "Từ chối", "Duyệt" | Quay lại (về "Chờ duyệt") |
| 051 | SELF_APPROVAL_NOT_ALLOWED | banner | — | "Về danh sách" |
| 051 | APPROVAL_ALREADY_DECIDED | `k1Locked` | "Xem kết quả" | Quay lại |
| 053 | COMPLETED | K4 | "Xem tồn kho" / "Về hồ sơ đối soát" | "Về danh sách" |
| 053 | PENDING_APPROVAL | `k2Pending` | — | "Về danh sách" / "Về hồ sơ đối soát" |
| 053 | CANCELLED / BLOCKED | K4 cảnh báo | — | "Về danh sách" |
| 053 | REJECTED | K4 cảnh báo + lý do từ chối | "Sửa lại" | "Về danh sách" |
| 053 | UNKNOWN | K3 | "Chuyển sang xác minh" | "Về Kho" |
| 053 | PROCESSING | `k1Loading` | — | — |

### 0.6 Khuôn dùng lại

- K1, K2 (`k2Decision`, `k2Pending`, `k2Attention`, `k2RejectSheet`, nguồn "Chờ duyệt", `__T7_DIRECT_CONTEXTS__["bj11-approval"]`), K3, K4 (`k4Result`, `k4ReasonFooter`, `k4Footer`), K6, K7 (`k7Split`, `k7Table`, `k7EditCell`), `dsChoiceRow`.
- Không thành phần DS mới.

### 0.7 Không đổi

Quy tắc ở 0.1; phân loại `cr11StateFor` (hủy / sửa / chưa xác định / đã giao khách); hai cách sửa `DELTA` / `FULL`; luồng K3 `handoff-unknown` sang BJ-17. Chữ giữ: "Có thể hủy", "Có thể sửa", "Đang xác minh", "Chưa có nghiệp vụ cần kiểm soát" + câu, "Không có nghiệp vụ phù hợp" + câu, "Nghiệp vụ chưa thực thi nên có thể hủy mà không tạo biến động tồn kho.", "Hủy yêu cầu", "Sửa sai", "Hàng đã được bàn giao thực tế" + câu, "Không còn tác động cần sửa" + câu, "Tồn kho và giá trị không thay đổi.", "Lý do hủy", "Cách sửa", "Sửa phần sai", "Hoàn nguyên và ghi lại đúng", "Số đúng", "Lý do sửa sai", "Mô tả ngắn điều đã sai và căn cứ sửa", "Gửi phê duyệt", "Đã gửi yêu cầu sửa sai", "Chưa thể sửa sai", "Chưa có kỳ mở để ghi nhận sửa sai" + câu, "Nghiệp vụ nguồn đã thay đổi" + câu, "Đã có yêu cầu sửa sai khác" + câu, "Về chi tiết", "Duyệt sửa sai", "Lý do", "Trước và sau", "Trước", "Sau", "Điều chỉnh", "Từ chối", "Duyệt", "Từ chối sửa sai", "Lý do từ chối", "Bạn không thể tự duyệt yêu cầu này", "Yêu cầu đã có quyết định" + câu, "Xem kết quả", "Kết quả sửa sai", "Đã hoàn tất sửa sai" + câu, "Nghiệp vụ gốc", "Bản ghi sửa sai", "Đã hủy yêu cầu" + câu, "Yêu cầu không được duyệt" + câu, "Chưa thể ghi sửa sai" + câu, "Về danh sách".

### 0.8 Kiểm (bước D)

- Golden **mobile** được khác: `UIF-11_*` (SCR-052 bỏ — ca `UIF-11_SCR-052_*` xoá khỏi danh sách, ghi CHANGELOG), `SC_bj11_*`, `SC_entry_UIF-11_*`, `SC_bj16_correction_*` (bước 049 → 050 mới), `SC_bj17_from_bj11_*` (bước 0), `SC_ws_control_*`, **mọi ca có Home Kho** ("Chờ duyệt" thêm nguồn "sửa sai" — fixture có yêu cầu SS-260915-01). Ca khác khớp mốc `tools/.golden-bj08-after`.
- Golden **web** được khác: như trên với `@web`; ca khác khớp `tools/.golden-bj08-web-after`.
- Kịch bản (mục 6): sửa `SC_bj11_list`, `SC_bj11_correct`, `SC_bj11_cancel`, `SC_bj11_blocked`, `SC_bj11_unknown`, `SC_bj11_back`, `SC_bj11_approve`, `SC_bj11_reject`, `SC_bj11_self_approve`, `SC_bj11_decided`, `SC_bj11_context`; thêm `SC_bj11_full`, `SC_bj11_owner_self`, `SC_bj11_from_home`, `SC_bj11_rejected_redo`, `SC_bj11_dependency`, `SC_bj11_from_case`.

### 0.9 Ước lượng C–E

~1,75 ngày: C1 048 + 049 + 050 (gộp 052) + sheet hủy + fixture ~0,75; C2 051 + 053 + "Chờ duyệt" + lối từ / về BJ-16 ~0,5; D ~0,25; E ~0,25. (T7-P mục 8.2 ghi 1,5 khi còn chia thiết bị chính / phụ.)

### 0.10 Đã chốt khi duyệt brief (2026-10-25): **mọi điểm theo cột "Đề xuất"**

| # | Điểm | Đề xuất | Phương án khác |
|---|---|---|---|
| a | Chọn cách sửa và nhập số | **Một màn "Sửa sai"** (gộp SCR-052 vào SCR-050, 052 → RETIRED) | Giữ hai màn 052 → 050 |
| b | Hủy yêu cầu chưa thực hiện | **Sheet có lý do ngay ở 049** | Giữ màn 052 "Hủy yêu cầu kho" |
| c | Tiêu đề 048 | **"Hủy & sửa sai"** (chữ Hub rút gọn) + phụ "Phiếu kho gần đây" | Giữ "Kiểm soát nghiệp vụ kho"; hoặc "Nghiệp vụ cần kiểm soát" (tên màn trong INDEX) |
| d | Lối vào từ phiếu / thẻ kho | **Để chặng 6** (BJ-15 thiết kế lại SCR-056 thì thêm "Sửa sai" trên chi tiết biến động); chặng này: Hub + hồ sơ BJ-16 | Thêm nút "Sửa sai" vào SCR-056 hiện tại ngay ở plan này |
| e | Bị từ chối thì sao | **053 có "Sửa lại"** (mở 050 với số / lý do cũ, gửi lại thành yêu cầu mới) | Chỉ "Về danh sách"; lập lại từ đầu |
| f | Tiền ở 050 / 051 / 053 | **Có, chỉ chủ cửa hàng** ("Giá trị: {±x} đ" khi có giá vốn) | Không hiện tiền ở BJ-11 |

---

## 1. Mục tiêu

1. Tìm phiếu sai theo mã phiếu / sản phẩm; biết ngay hủy được, phải sửa hay phải đi việc khác, bằng một câu thường.
2. Sửa sai một màn: cách sửa, số đúng, lý do, thấy tồn (và tiền với chủ) sau khi sửa.
3. Duyệt theo K2 đúng yêu cầu: Home "Chờ duyệt", chủ tự lập vẫn tự duyệt.
4. Vào từ hồ sơ đối soát và quay về đúng hồ sơ.
5. Mọi trạng thái 0.5 dựng khác nhau và có lối ra, ở cả hai khung.

## 2. Chuẩn bị

1. BJ-08 đã làm (plan BJ-08 mục 14 review, hoặc ít nhất D xong). Rà lại plan này theo code BJ-08: cách dùng `k2Decision` có tiền, `bj08ShowMoney` (đưa thành helper chung nếu BJ-11 dùng y hệt — đặt trong `shared-patterns.js`, tên `t7ShowMoney()`), fixture chung chặng 5 — ghi lệch vào mục 9.
2. Mốc = `tools/.golden-bj08-after` / `tools/.golden-bj08-web-after`; lệch so HEAD → chụp `tools/.golden-bj11-base` / `-web-base`.
3. GitNexus: `impact` hướng upstream cho `render048BJ11`…`render053BJ11`, `cr11StateFor`, `cr11Current`, listener `cr16-correction-handoff` (`bj16.js`), `crSwitchFlow`; báo mức rủi ro vào mục 9.
4. Máy chủ `python3 -m http.server 8765 --bind 127.0.0.1 &` trong `html/`.

## 3. Fixture (`app/bj11.js`, commit 1)

Theo bảng phân vai sản phẩm chặng 5 ([BJ-08 mục 3](T7-P-bj08-kiem-ke.md)). `cr11Operations` mỗi dòng thêm `docType`, `docCode`, `docDate`, `lot`, `uom`, `unitCost`, `recordedQty`, `period`, `dependency` (cho `DEPENDENCY_BLOCKED`):

| Mã nghiệp vụ | Phiếu | Sản phẩm | Hiện tại | Sau |
|---|---|---|---|---|
| IO-260906-022 | ST-260906-04 Đổi tình trạng | Amox 500 · Lô L2407-A · 12 hộp | Có thể hủy | **Amox 500 · Lô AM2505 · 2 hộp** (lô thật chặng 4), chưa thực hiện → hủy được |
| IO-260904-021 | PN-260904-08 Nhận hàng | Amox 500 · L2407-A · 20 → 18 | Có thể sửa | **Amox 500 · SP-000066 · không theo lô** (BJ-01), ghi 20 hộp, hoá đơn 18 → câu chuyện của `SC_journey_5` (mở từ hồ sơ BJ-16); `unitCost` 42.000 đ |
| IO-260901-014 | PN-260901-07 Nhận hàng | Nobivac DH2507 · 120 → 118 | Có thể sửa (mặc định) | **Dầu sát khuẩn · SP-00606 · L2406-T · ghi 6 chai, đúng 4** — có sẵn yêu cầu **SS-260915-01** chờ duyệt ("Nguyễn Văn An" gửi "15/09/2026 16:45", lý do "Phiếu giao chỉ có 4 chai") → Home "Chờ duyệt" "sửa sai"; không giá vốn → 051 không có dòng "Giá trị" |
| IO-260906-031 | DSP-260906-02 Tiêu hủy | Vitamin C · L2310-C · 5 hộp | Đang xác minh | **TH-260906-02 · Găng tay khám Nitrile · 5 hộp** (cùng mã với BJ-17 `REC-UNKNOWN-01`, sửa ở plan sau cho khớp) |
| IO-260902-005 | SO-260902-19 Xuất bán | Oxytetracycline LA · 3 chai | Đã giao khách | giữ |
| **IO-260903-017 (mới)** | PN-260903-05 Nhận hàng | — | — | **Tylosin 20% · TY2511 · ghi 5 lọ, đúng 3** — sau phiếu đã bán 3 lọ → `DEPENDENCY_BLOCKED` thật ("Sau phiếu này đã bán 3 lọ…") |

- Yêu cầu sửa sai thành mảng `cr11Requests` (`SS-260917-{nn}` tăng dần khi gửi; `SS-260915-01` sẵn). Thời điểm cố định "17/09/2026 20:30" (gửi), "17/09/2026 20:40" (duyệt); bản ghi sửa sai `IO-260917-{nnn}`.
- Kỳ: kỳ mở "09/2026"; phiếu tháng 8 (nếu thêm) → "· kỳ gốc 08/2026 đã khoá".
- `bj11Seed(screen, state)` như `bj08Seed`: 050 = IO-260904-021 nháp (số đúng trống); 051 = SS-260915-01; 053 `COMPLETED` = kết quả mẫu IO-260904-021; 053 `PENDING_APPROVAL` = SS-260915-01.
- `entry=approver` mở SS-260915-01; `entry=operation-context` mở 049 IO-260904-021; **`entry=correction-from-case` (mới)** mở 050 IO-260904-021 kèm `cr11ReturnCase = "REC-260907-04"`.

## 4. Bước C1 — danh sách, chi tiết, sửa sai, hủy (commit 1)

### 4.1 Dữ liệu và sự kiện (`app/bj11.js`)

1. `cr11Current()` đọc `cr11SelectedId`; **051 / 053 đọc yêu cầu đang chọn** `cr11SelectedRequestId` (sửa vấn đề 5, 6). "Điều chỉnh" = `số đúng − recordedQty` của phiếu đó.
2. Nguồn K2: `__T7_PENDING_SOURCES__.push({ id:"UIF-11", label:"sửa sai", needsActivation:true, rows })`; `__T7_DIRECT_CONTEXTS__["bj11-approval"]`. `bj11CanDecide()` như BJ-08.
3. Bản nháp sửa sai: `resetDraft(op)` → `strategy:"DELTA"`, `correctQty:""` (hoặc số của hồ sơ khi vào từ BJ-16), `reason:""`.
4. Gõ vào ô số / lý do không dựng lại cả màn: chỉ cập nhật khối "Sau khi sửa" và chân.
5. Sự kiện: `data-bj11-filter` / `data-bj11-search` / `data-bj11-row`; `data-bj11-action="cancel-open" | "cancel-close" | "cancel-confirm" | "correct" | "submit" | "to-list" | "to-detail" | "to-return" | "to-stock" | "to-case" | "view-request" | "redo"`; `data-bj11-strategy`, `data-bj11-correct-qty`, `data-bj11-reason`, `data-bj11-cancel-reason`.
6. Quay lại: `onPrevious["UIF-11"]` — 050 khi `cr11ReturnCase` → `crSwitchFlow("UIF-16", "SCR-079")` của hồ sơ; 050 thường → 049; 049 → 048.
7. Xoá mã chết (vấn đề 10): `render052BJ11` (đăng ký `screenAliases["SCR-052"] → "SCR-050"` để link cũ không gãy), `cr11ListRows`, `bj11KeyValueSurface` (dùng `ac310KeyValueSurface` hoặc khối K2), `bj11RadioChoice` (dùng `dsChoiceRow`), `ac310SanitizeMarkup` / `ac310Return` ở BJ-11 (đo trước như BJ-08), `setTimeout` của `PROCESSING`. Nhãn `data-cr11-*`, `data-v350-action="cr11-*"`, `data-v360-action="fallback-exit"` → `data-bj11-*`. Sửa `tools/golden.mjs`.

### 4.2 Màn

| Màn | Việc |
|---|---|
| 048 | 0.4 điểm 1–7; `appShell({ extraClass:"k7-wide" })` |
| 049 | 0.4 điểm 8–12 |
| 050 | 0.4 điểm 13–20 |
| 052 | xoá khỏi `screens` của UIF-11 (bộ chọn trạng thái, inspector `core.js` dòng 40); `screenAliases` → 050 |
| `bj16.js` | `cr16-correction-handoff` → `applyEntry("UIF-11", "correction-from-case")` với `cr11SelectedId = c.correctionOperationId`, `cr11ReturnCase = c.id` (thay `crSwitchFlow(... "SCR-049", "CORRECTABLE")`); plan BJ-16 đổi chữ nút |

## 5. Bước C2 — duyệt, kết quả (commit 2, cùng D)

051 (0.4 điểm 21–24), 053 (25–26). "Về hồ sơ đối soát" → đặt `cr16Cases` của `cr11ReturnCase` `correctionDone = true` (cờ mới; plan BJ-16 dựng nhánh 079 "Đã sửa phiếu gốc") rồi `crSwitchFlow("UIF-16", "SCR-079", "CORRECTION_REQUIRED")`. Ở plan này 079 chưa có nhánh mới → hiện như cũ; ghi mục 9.

CSS: gom luật BJ-11 (`[data-active-uif="UIF-11"]`, `.ac310-radio-*` nếu chỉ BJ-11 dùng, `.cr-*` còn lại) về khối BJ-11 trong `styles/screens.css`, bỏ `!important` không còn đối thủ; bỏ luật cột 402px cho UIF-11.

## 6. Kịch bản golden (`tools/golden.mjs`, `S11 = '?uif=UIF-11&screen='`)

Sửa: `SC_bj11_list` (chip mới, tìm "PN-260904"), `SC_bj11_correct` (IO-260904-021 → "Sửa sai" → số đúng 18 → lý do → "Gửi phê duyệt" → 053 chờ duyệt), `SC_bj11_cancel` (IO-260906-022 → "Hủy yêu cầu" → sheet → lý do → 053 đã hủy), `SC_bj11_blocked` (IO-260902-005 → "Mở hàng khách trả" → BJ-06 030), `SC_bj11_unknown` (IO-260906-031 → K3 → BJ-17), `SC_bj11_back` (050 → back → 049 → back → 048), `SC_bj11_approve` (`entry=approver` → "Duyệt" → 053 COMPLETED → "Về danh sách"), `SC_bj11_reject` (→ "Từ chối" → lý do → "Xác nhận từ chối" → 053 REJECTED), `SC_bj11_self_approve` (nhân viên lập rồi tự mở 051 → banner), `SC_bj11_decided`, `SC_bj11_context`.

| Kịch bản | Bắt đầu | Bước |
|---|---|---|
| `SC_bj11_full` | `S11 + 'SCR-048'` | IO-260904-021 → "Sửa sai" → "Hoàn nguyên và ghi lại đúng" → số đúng 18 → lý do → gửi |
| `SC_bj11_owner_self` | `T + 'inventory&entry=owner'` | workspace "control" → "Hủy & sửa sai nghiệp vụ" → IO-260904-021 → sửa → gửi → Home "Chờ duyệt" → dòng "sửa sai" → "Duyệt" được; 053 "Người duyệt" "Chủ cửa hàng", có "Giá trị" |
| `SC_bj11_from_home` | `T + 'inventory'` | "Chờ duyệt" → dòng SS-260915-01 (vai `approver`) → 051 (Dầu sát khuẩn, không dòng "Giá trị") → quay lại |
| `SC_bj11_rejected_redo` | `S11 + 'SCR-053&state=REJECTED'` | "Sửa lại" → 050 có số / lý do cũ |
| `SC_bj11_dependency` | `S11 + 'SCR-048'` | IO-260903-017 → "Sửa sai" → 050 `DEPENDENCY_BLOCKED` → "Về chi tiết" |
| `SC_bj11_from_case` | `?uif=UIF-11&entry=correction-from-case` | 050 điền sẵn 18 → lý do → gửi → 053 chờ duyệt → "Về hồ sơ đối soát" (079 REC-260907-04) |

`WEB_SCENARIOS` thêm `SC_bj11_list`, `SC_bj11_correct`, `SC_bj11_approve`, `SC_bj11_from_home`, `SC_bj11_from_case`. Chỉ dùng `data-bj11-*` / `data-theme-*` / `data-k*`.

## 7. Bước D — kiểm

1. Golden mobile / web so mốc mục 2: chỉ ca ở 0.8 khác; ghi mục 9. Mọi trạng thái 0.5 cho ảnh khác nhau, cả hai khung.
2. Bấm thử UIF-11 hai khung + Home "Chờ duyệt" + hồ sơ BJ-16 "Cần sửa nghiệp vụ nguồn" → 050 → "Về hồ sơ đối soát": 0 lỗi JS; `node --check app/*.js harness/*.js tools/golden.mjs`. Vai nhân viên: không "đ" trong HTML 050 / 051 / 053.
3. **`/impeccable audit` phạm vi UIF-11 — chặn commit E.** Chạy trên 048 (READY từng chip, EMPTY, FILTER_EMPTY), 049 (sáu trường hợp ở điểm 9 + sheet hủy), 050 (READY trống, đủ ô, VALIDATION_ERROR, DEPENDENCY_BLOCKED, PERIOD_POLICY_VIOLATION, SOURCE_VERSION_STALE, CONFLICT, vào từ BJ-16), 051 (READY chủ, sheet từ chối, SELF_APPROVAL_NOT_ALLOWED, APPROVAL_ALREADY_DECIDED), 053 (COMPLETED chủ / nhân viên / từ BJ-16, PENDING_APPROVAL, CANCELLED, REJECTED, BLOCKED, UNKNOWN), ở cả hai khung. Đạt khi: chữ ≥ 4,5:1 (badge, phụ đề dòng, dòng lý do ở chân, chữ trên nút danger "Hủy yêu cầu"); vùng chạm ≥ 44 × 44 ở iPhone (chip cuộn ngang, `dsChoiceRow`, ô số); tăng / giảm không chỉ bằng màu (có chữ "Tồn giảm" / "Tồn tăng", dấu "−" / "+"); web đi được bằng bàn phím (Tab qua ô tìm → chip → bảng → nút chân; `dsChoiceRow` chọn bằng mũi tên / Space; Enter mở / Esc đóng sheet hủy / từ chối, focus về nút đã mở, Tab không thoát `aria-modal`); web không còn cột 402px; iPhone không bảng ép nhỏ, số và ĐVT không gãy dòng. Lỗi trong phạm vi: sửa ngay; ngoài phạm vi: ghi mục 9.
4. Gửi ảnh: 048 web + iPhone, 049 sửa được iPhone + đã giao khách iPhone, 049 web, sheet hủy iPhone, 050 iPhone (đủ ô) + web, 051 web (chủ), 053 COMPLETED iPhone (từ BJ-16) + REJECTED iPhone, Home "Chờ duyệt" hai khung.
5. Mốc cho plan sau: `tools/.golden-bj11-after` / `tools/.golden-bj11-web-after`.

## 8. Bước E — ghi lại (commit 3)

1. `CHANGELOG.md` `[5.17.0] — BJ-11 thiết kế lại; gộp SCR-052 vào SCR-050`; phiên bản 5.17.0 (`manifest.json`, `harness/workbench.js`, badge `index.html`, nhãn inspector UIF-11).
2. Viết lại theo `_TEMPLATE.md`: SCR-048, 049, 050 (gộp 052), 051, 053; SCR-052 → `RETIRED.md` ("Bỏ từ v5.17.0", thay bằng SCR-050 + sheet hủy ở SCR-049); UIF-11 (sơ đồ mới: K6, sheet hủy, một màn sửa sai, "Chờ duyệt", lối từ / về BJ-16, 049 → BJ-06).
3. T7-P mục 2 bảng "Vị trí trên Home Kho" (dòng "Chờ duyệt" có sửa sai); mục 9 BJ-11: khuôn "K1, K2, K3, K4, K6, K7"; mục 9 chặng 6 BJ-15: thêm "SCR-056 có lối 'Sửa sai' → BJ-11 050" (0.10 d).
4. `INDEX.md` 048…053; T7-P mục 13 (chữ mới; gộp 052; "Mở hàng khách trả"; "Sửa lại"; tiền cho chủ; phần BJ-11 của dòng "mọi BJ theo K2": UC-11-04 ghi người duyệt = `is_owner` / `store_owner`, chủ lập gửi rồi tự duyệt; UC-11-01…05 mục "màn sử dụng" còn ghi SCR-052 → đổi SCR-049 / 050 ở 7.3); mục 14: BJ-11 ✅.
5. `python3 tools/sync-registry.py`.

## 9. Ghi chú khi làm

**Mốc.** Dùng `tools/.golden-bj08-after` (mobile 1926 ca) / `.golden-bj08-web-after` (web 1051 ca): BJ-08 chưa commit nên HEAD làm việc chính là bản đã chụp mốc, không chụp base riêng. Sau khi làm: `tools/.golden-bj11-after` (**1959 ca**) / `.golden-bj11-web-after` (**1073 ca**), 0 lỗi JS ở cả hai khung. `golden.mjs` chạy tuần tự (mobile rồi web).

**GitNexus (`impact` upstream, repo `erp-sales-inventory` — CLI cần `--repo erp-sales-inventory`).** `render048BJ11`…`render053BJ11`: 0 hàm gọi — LOW. `cr11StateFor`: 1 (nội bộ `bj11.js`) — LOW. `cr11Current`: 5 (nội bộ `bj11.js`, giữ chữ ký) — MEDIUM, chỉ trong file. `crSwitchFlow`: 2 (`bj16.js`, `bj11.js`) — LOW, không sửa. Listener `cr16-correction-handoff` (`bj16.js`): sửa một dòng, đổi `crSwitchFlow(... "SCR-049")` thành `applyEntry("UIF-11", "correction-from-case")`. `detect_changes()` cuối: 27 tệp, 228 symbol (phần lớn tài liệu), 0 quy trình bị ảnh hưởng, rủi ro thấp.

**Kết quả D.**
1. So mốc: mobile 433 / web 188 dòng khác — **chỉ** `UIF-11_SCR-048…053_*` (ca `UIF-11_SCR-052_*` bỏ khỏi danh sách), `SC_bj11_*`, `SC_entry_UIF-11_*`, `SC_bj16_correction` (bước 2: mở thẳng SCR-050), `SC_ws_control_2_*` (Hub → "Hủy & sửa sai nghiệp vụ"), chữ inspector "v5.17.0 · BJ-11 thiết kế lại", và mọi ca có Home Kho / "Chờ duyệt" (đã đối chiếu từng dòng chữ khác của các ca ngoài UIF-11: chỉ "… · 1 sửa sai", số "Chờ duyệt" +1, dòng `Nhận hàng PN-260901-07 · Dầu sát khuẩn` / `6 → 4 chai · Nguyễn Văn An gửi 15/09/2026 16:45`, nhãn inspector).
2. Bấm thử: toàn bộ `SC_bj11_*` (18 kịch bản mobile; 5 web) 0 lỗi JS; `node --check app/*.js harness/*.js tools/golden.mjs` đạt. Kiểm thêm bằng CDP: hồ sơ BJ-16 `REC-260907-04` → mở sửa sai (Số đúng 18 điền sẵn) → gửi → chủ duyệt → "Về hồ sơ đối soát" → 079 với `correctionDone = true`, `cr11ReturnCase` được xoá; nút quay lại ở 050 về đúng hồ sơ.
3. **Tiền:** chỉ các bước vai chủ cửa hàng của `SC_bj11_owner_self` có "… đ" trong chữ (050 "Giá trị: −84.000 đ", 051, 053 "Giá trị"); mọi ca nhân viên (050, 051 `SELF_APPROVAL_NOT_ALLOWED`, 053 `PENDING_APPROVAL`) không có số tiền trong chữ và không trong HTML; 051 của `SS-260915-01` (Dầu sát khuẩn, không giá vốn) không có dòng "Giá trị" kể cả vai người duyệt.
4. **Audit (`/impeccable audit` phạm vi UIF-11)** — chạy bằng biểu thức kiểm dọc `AUDIT_JS` (tương phản chữ ≥ 4,5 : 1 — 3 : 1 cho chữ lớn —, vùng chạm ≥ 44 × 44 ở iPhone / ≥ 40 ở web, tràn ngang, thành phần không tên) trên **mọi** ca `UIF-11_*` (37 mobile / 34 web) và `SC_bj11_*` (84 / 25), gồm sheet hủy, sheet từ chối, vào từ BJ-16: **0 lỗi tương phản, vùng chạm, tràn ngang, thành phần không tên** (ngoài phạm vi, như BJ-10: nút đóng toast "Đã gửi yêu cầu sửa sai" 20 × 20 là thành phần dùng chung). Bàn phím (CDP, web): Tab đi ô tìm → 4 chip → 6 dòng bảng (dòng `<tr>` có `tabindex="0"`, Enter / Space mở); Enter ở "Hủy yêu cầu" mở sheet và đưa focus vào ô lý do, Tab chỉ đi vòng trong sheet, Esc đóng và **trả focus về nút đã mở** (cả sheet từ chối); mũi tên đổi "Cách sửa" và chuyển focus. Web không còn cột 402 px (`k7-wide`); iPhone không bảng ép nhỏ, số và ĐVT không gãy dòng (mã phiếu dùng gạch nối không ngắt). Lỗi trong phạm vi đã sửa ngay (xem dưới); ngoài phạm vi: `bj08Visible` ở BJ-08 cũng dựa `offsetParent` nên có thể cùng lỗi focus / Tab trap với sheet `position: fixed` (chưa kiểm — ghi cho review BJ-08).
5. Ảnh gửi review: `tools/.golden-bj11-after` / `-web-after` — `UIF-11_SCR-048_READY`, `UIF-11_SCR-049_CORRECTABLE` / `BLOCKED_PHYSICAL_HANDOVER`, `SC_bj11_cancel_3_reason` (sheet hủy), `SC_bj11_owner_self_7_reason` (050 đủ ô, vai chủ) và `UIF-11_SCR-050_READY@web`, `SC_bj11_from_case_2_submit` + `SC_bj11_from_case_3_to-case`, `UIF-11_SCR-053_REJECTED`, `SC_bj11_from_home_*` (Home "Chờ duyệt" hai khung).

**Lệch so với plan / quyết định khi làm.**
- **Sửa khi audit:** mã phiếu bị cắt "…" / gãy ở dấu "-" trên dòng iPhone → cho tiêu đề và phụ đề dòng wrap, tiêu đề dùng gạch nối không ngắt (U+2011, chỉ ở dòng iPhone); "Sau khi sửa" là khối thường (không nền cảnh báo của `k2Attention`); lỗi ô lý do có viền / chữ đỏ; `bj11Visible` dùng `getClientRects()` vì sheet là `position: fixed`; thêm Enter / Space cho dòng `<tr>`; mũi tên cho `dsChoiceRow`.
- **`t7ShowMoney()` / `t7FmtMoney()`** đặt ở `app/shared-patterns.js` (mục 2.1); `bj08ShowMoney` gọi lại — sửa một dòng ở `bj08.js` (chưa commit, cùng đợt).
- **Fixture:** tồn hiện tại lấy theo fixture BJ-08 (Amox 500 = 46, Dầu sát khuẩn = 2, Tylosin TY2511 = 3). `DEPENDENCY_BLOCKED` của Tylosin theo đúng chữ plan ("đã bán 3 lọ … làm tồn âm") dù phép tính tồn không âm — chữ là chuỗi chuẩn của plan, fixture chỉ cần "có nghiệp vụ phụ thuộc". Phiếu đã sửa xong vẫn "Có thể sửa" (số đã ghi mới = số sau sửa; "Sửa sai trước đó" hiện mã bản ghi).
- **K3 từ 049 / 053:** BJ-17 mở hồ sơ mới `REC-11-…` (như BJ-05 / 06 / 07 / 10) thay vì `REC-UNKNOWN-01` có sẵn — hồ sơ mẫu đó có `sourceFlow: "UIF-17"` nên không khớp; trước đây BJ-11 tự đặt `cr17SelectedId`. Plan [BJ-16 + BJ-17](T7-P-bj16-bj17-doi-soat.md) chỉnh fixture cho khớp (đã ghi ở mục 3 bảng).
- **051 cho người không phải chủ:** banner "Bạn không thể tự duyệt yêu cầu này" + "Chủ cửa hàng sẽ duyệt yêu cầu bạn lập." (người lập) hoặc "Chỉ chủ cửa hàng duyệt yêu cầu sửa sai." (người khác) — như BJ-08. `VALIDATION_ERROR` = sheet từ chối mở sẵn, ô lý do trống, lỗi "Nhập lý do từ chối". `SOURCE_VERSION_STALE` / `CONFLICT` ở 050 chỉ hiện khối K1 + nút (không dựng lại biểu mẫu bên dưới).
- **Chuyển trạng thái `UNKNOWN` ở danh sách:** dòng "Đang xác minh" mở 049 `UNKNOWN` (K3) như 0.4 điểm 5; không có trạng thái "đã hủy" trong plan — thêm badge "Đã hủy" (Neutral) và 049 `TERMINAL` cho phiếu vừa hủy.
- **Chữ mới ngoài mục 13** (đã ghi thêm một dòng vào T7-P mục 13): loại phiếu "Đổi tình trạng"; "Ghi vào kho" "Chưa xác định"; "Không có yêu cầu sửa sai" / "Mở lại từ danh sách chờ duyệt."; "Chỉ chủ cửa hàng duyệt yêu cầu sửa sai."; "Nhập lý do từ chối"; "Lý do được lưu trong lịch sử kiểm soát.".
- **CSS:** bỏ luật `.io-product-*`, `.cr-fact-card`, `.cr-choice` riêng UIF-11 ở `components.css`; **giữ** `.io-read-card` / `.io-meta-row` cho UIF-11 (K4 `ioResult` còn dùng) và các danh sách chung UIF-08…17 ở `screens.css`; `.ac310-radio-*` còn `ac310-mode-row` (BJ-15) dùng nên giữ. Không có luật cột 402 px riêng của UIF-11: khung web thoát cột nhờ `k7-wide`.
- **Không làm (như mục 11):** nhánh 079 "Đã sửa phiếu gốc"; lối "Sửa sai" từ SCR-056; plan BJ-16 + BJ-17 đổi chữ nút "Mở yêu cầu sửa sai" → "Sửa phiếu gốc" (nút vẫn chữ cũ ở bản này).
- **Đã thêm ngoài danh sách kịch bản mục 6:** `SC_bj11_case_back` (BJ-16 → 050 → quay lại hồ sơ), `SC_entry_UIF-11_correction-from-case`.

## 10. Thứ tự commit

1. C1 (fixture, 048 / 049 / 050, sheet hủy, bỏ 052, lối vào từ BJ-16).
2. C2 + D (051 / 053, "Chờ duyệt", "Về hồ sơ đối soát", golden mới, sửa sau audit).
3. E (tài liệu, phiên bản, registry).

Nếu làm một lượt thì để chưa commit cho phiên review xem trước. `detect_changes()` trước mỗi commit.

## 11. Không làm

- Nhánh 079 "Đã sửa phiếu gốc" của hồ sơ BJ-16 (plan [BJ-16 + BJ-17](T7-P-bj16-bj17-doi-soat.md)); plan này chỉ đặt cờ `correctionDone`.
- Lối "Sửa sai" từ SCR-056 / thẻ kho (chặng 6 — 0.10 d).
- Sửa sai nhiều dòng một lần, đổi sản phẩm / lô khi hoàn nguyên (prototype chỉ sửa số lượng một dòng — giữ như hiện tại).
- Sửa giá trị (BJ-13) — lỗi nhập giá của BJ-03 đi BJ-11 theo spec nhưng prototype chưa có phiếu giá trong `cr11Operations`.

## 12. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| Bỏ SCR-052 làm gãy link / golden cũ trỏ `screen=SCR-052` | `screenAliases` → 050; xoá ca golden 052 có ghi CHANGELOG |
| Lối từ BJ-16 sang BJ-11 và quay về đổi luồng hai lần, nút quay lại / thanh bên về nhầm | `cr11ReturnCase` + `onPrevious`; `SC_bj11_from_case` và `SC_journey_5` (plan sau) chạy ở chế độ Toàn Theme 7, cả hai khung |
| Chủ cửa hàng được tự duyệt làm vỡ ca `SELF_APPROVAL_NOT_ALLOWED` | Giữ ca bằng nhân viên tự mở yêu cầu mình lập; `SC_bj11_owner_self` kiểm nhánh chủ |
| Sửa lỗi "051 luôn là cr11Operations[1]" làm ảnh 051 đổi ở mọi ca duyệt | Chấp nhận (0.8); `diff` thân `.txt` chỉ khác phần yêu cầu |

## 13. Chữ trên màn

| Vị trí | Chữ |
|---|---|
| 048 | "Hủy & sửa sai" · "Phiếu kho gần đây" · "Tìm mã phiếu hoặc sản phẩm" · chip "Hủy được", "Sửa được", "Đang chờ" · "{loại} {mã phiếu}" · "{sản phẩm} · {n} {ĐVT} · {ngày}" · badge "Chờ duyệt sửa sai", "Đã giao khách" · cột "Phiếu", "Loại", "Ngày", "Tình trạng" · "Bạn chưa có quyền hủy hoặc sửa sai" |
| Home | "Chờ duyệt" nguồn "sửa sai" · "{loại} {mã phiếu} · {sản phẩm}" / "{a} → {b} {ĐVT} · {người lập} gửi {lúc}" |
| 049 | "{loại} {mã phiếu}" · "Phiếu đã ghi vào kho nên không sửa thẳng. Sửa sai sẽ ghi thêm một phiếu liên kết; phiếu này giữ nguyên." · "Mở hàng khách trả" · "Phiếu gốc" · "Mã phiếu" · "Mã nghiệp vụ" · "Ghi vào kho" · "Chưa ghi" · "Sửa sai trước đó" · "Chưa có" · "Hủy yêu cầu {mã phiếu}?" |
| 050 | "Sửa sai" · "Giữ phần đúng, chỉ ghi thêm phần chênh." · "Dùng khi sai cả phiếu (nhầm sản phẩm, nhầm lô): hoàn nguyên rồi ghi lại." · "Đã ghi {n} {ĐVT}" · "Sau khi sửa" · "Tồn {sản phẩm}: {a} → {b} {ĐVT}" · "Ghi vào kỳ {kỳ mở}" · "Giá trị: {±x} đ" · "Phiếu gốc giữ nguyên; app ghi thêm phiếu sửa sai liên kết." · lý do "Nhập số đúng", "Số đúng đang bằng số đã ghi", "Nhập lý do sửa sai" · "Sau phiếu này đã {xuất / bán} {n} {ĐVT}; sửa bây giờ làm tồn âm. Xử lý nghiệp vụ đó trước." · "Mở yêu cầu đang chờ" |
| 051 | "Duyệt sửa {loại} {mã phiếu}: {sản phẩm} từ {a} thành {b} {ĐVT}?" · "Tồn giảm {d} {ĐVT}" / "Tồn tăng {d} {ĐVT}" · "Hoàn nguyên cả phiếu rồi ghi lại" · "Ghi vào kỳ" · "Từ hồ sơ đối soát" · "Chủ cửa hàng sẽ duyệt yêu cầu bạn lập." |
| 053 | "Về hồ sơ đối soát" · "Sửa lại" · K3 "Ghi sửa sai" |

## 14. Review

Review chặng 5 (2026-10-25): **đạt sau R1–R3** (v5.18.1) — xem [plan BJ-16 + BJ-17 mục 14](T7-P-bj16-bj17-doi-soat.md#14-review). Phần của BJ-11: **R1** (b, c — 053 `UNKNOWN` gửi mã yêu cầu; nhãn "Sửa sai" ở BJ-17), **R2** (050 "Tồn Amox 500: 46 → 44" đúng; 079 / 082 phải theo), **R3** (câu `DEPENDENCY_BLOCKED`); góp ý 4 (phiếu nguồn vẫn "Đang xác minh" sau khi BJ-17 xác lập).
