# T7-P · BJ-09 Tình trạng hàng — thiết kế lại (bước B–E) + dựng K5 "Hàng cần xử lý"

> Theme: Theme 7 Inventory · Trạng thái: Brief ✅ (duyệt 2026-10-25 — mục 0.10, mọi điểm theo đề xuất) | Plan C–E ✅ | Làm ✅ 2026-10-25 (v5.13.0, chưa commit) | Review ✅ đạt 2026-10-25 sau R1–R3 (v5.15.1 — mục 13)
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) mục 8.2 **chặng 4 "Hàng có vấn đề"**, BJ thứ nhất. Làm **sau** chặng 3 (`SC_journey_3`, review đạt, commit `2718499a8`). BJ sau: [BJ-07 + BJ-10](T7-P-bj07-bj10-tra-ncc-tieu-huy.md) (cuối chặng, có `SC_journey_4`).
> **Dựng K5** (hàng có vấn đề: danh sách chung → lô → việc → kết quả — T7-P mục 5) trên màn dùng chung SCR-036 / 037 / 041; BJ-07 và BJ-10 dùng lại ngay trong chặng. Dùng lại K1, **K2** (đổi tình trạng cần chủ cửa hàng duyệt — UC-09-02), K3, K4, K6, K7. Kèm **bước C0 — fixture chung chặng 4** (mục 3).
> Thiết bị: **cả iPhone và web đều là thiết bị chính** (T7-P mục 2). Nhân viên phát hiện hàng có vấn đề tại kệ / quầy bằng iPhone; chủ cửa hàng duyệt lúc ở máy tính hoặc iPhone — hai bố cục thiết kế và kiểm như nhau.
> Ước lượng: **~2,5 ngày, 3 commit** (C0 + C1 K5 + danh sách + chi tiết; C2 đổi tình trạng + duyệt + kết quả + D; E). Người làm: bạn. Review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị, chép nguyên văn; **(mới)** = chữ mới, vào T7-P mục 13 ở bước E.

## 0. Brief (bước B, đã duyệt 2026-10-25)

### 0.1 Việc thật

- **Ai, lúc nào:** nhân viên (1–3 người) **vài lần / tuần**, khi thấy hàng không bán được: bao bì móp / rách lúc soạn hàng, hàng khách trả bị xếp "Cách ly" / "Hỏng" (BJ-06), hàng nhận về không đạt (BJ-02), lô đã qua hạn dùng (hệ thống tự xác định). Chủ cửa hàng duyệt những lần đổi có rủi ro (ra khỏi "Bán được", hoặc đưa lại vào "Bán được").
- **Cần biết / làm gì:** hàng nào đang không bán được và **phải làm gì tiếp** với nó: xem lại rồi cho bán lại, chuyển sang hỏng, đề nghị tiêu hủy (BJ-10), hoặc chờ bộ phận Mua hàng lập yêu cầu trả nhà cung cấp (BJ-07). Khi đổi: đổi sang gì, bao nhiêu, vì sao, có ảnh không; đổi xong thì khả dụng bán và đơn đang giữ hàng bị ảnh hưởng ra sao.
- **Quy tắc** (BJ-09, UC-09-01…04 BR-01…06, UIF-09): chỉ các cặp chuyển trong ma trận (`POLICY.transitions`); mỗi cặp quy định lý do / bằng chứng / cần duyệt; đổi tình trạng **không** đổi tổng tồn vật lý và giá trị ghi sổ; **hết hạn do hệ thống xác định** từ hạn dùng và ngày nghiệp vụ, người dùng không tự chọn "Hết hạn", không đổi được lô hết hạn sang tình trạng khác; cận hạn chỉ là chỉ báo, không phải tình trạng; khả dụng giảm thì phát tác động để đơn đang giữ (BJ-04) phân bổ lại, BJ-09 không tự sửa đơn; người duyệt = `is_owner` hoặc `store_owner`, chủ cửa hàng lập thì vẫn gửi rồi tự duyệt (T7-P mục 2, K2); `UNKNOWN` không gửi lại, chuyển BJ-17.
- **Ranh giới chặng 4** (00-business-journey-map: BJ-09 → BJ-07 "RTV candidate", BJ-09 → BJ-10 "Disposal candidate"): BJ-09 quyết hàng **đang ở tình trạng nào**; tiêu hủy (BJ-10) chỉ nhận hàng **không bán được** (UC-10-01 BR-01); trả nhà cung cấp (BJ-07) **do Mua hàng lập yêu cầu** (UC-07-01 tác nhân "System process; Purchase/source"), Kho không tự tạo — Kho chỉ chuẩn bị và bàn giao.

### 0.2 Luồng hiện tại

Ảnh: `tools/.golden-chang3/UIF-09_*`, `UIF-10_SCR-036_*`, `UIF-07_SCR-036_*`, `SC_bj09_*`, `SC_attention_UIF-09_*`, `SC_bj01_expired*`; web `tools/.golden-chang3-web/UIF-09_*@web`, `UIF-07_SCR-036_READY@web`.

```text
Ba lối vào, ba danh sách khác nhau trên cùng mã màn SCR-036:
  Hub → Tồn kho → "Tình trạng hàng"  ─┐
  Hub → Kiểm kê & xử lý → "Hàng cần xử lý" ─┴→ UIF-09 036 "Tình trạng hàng" (mọi lô, kể cả Bán được; chip theo tình trạng)
  Hub → Nhập, xuất & hoàn trả → "Trả nhà cung cấp" → UIF-07 036 "Hàng chờ trả nhà cung cấp" (yêu cầu trả)
  (không có lối Hub) ?uif=UIF-10 → 036 "Hàng có thể xử lý" (2 dòng cố định trong chuỗi HTML)
  Home "Cần chú ý" → "Lô sắp hết hạn · 3 lô" → UIF-09 036
  BJ-01 SCR-003 lô hết hạn → "Xử lý lô hết hạn" → UIF-09 036 lọc "Hết hạn" + tìm mã lô

UIF-09: 036 ─lô→ 037 "Chi tiết tình trạng hàng" (7 dòng nhãn–giá trị) ─"Thay đổi tình trạng"→ 038 (radio + số lượng + lý do)
  ─"Gửi xử lý"→ 038 PENDING_APPROVAL (banner) … người duyệt: ?entry=approver → 038 APPROVAL_REVIEW → "Duyệt" → 041 → "Về tình trạng hàng"
  037 lô hết hạn: banner, không nút (ngõ cụt)
```

### 0.3 Vấn đề

| # | Màn | Vấn đề |
|---|---|---|
| 1 | 036 (ba luồng) | Ba tiêu đề, ba bộ dữ liệu, ba kiểu dòng cho cùng "hàng có vấn đề"; Hub có hai mục cùng mở UIF-09 và mục "Trả nhà cung cấp" ở khu khác; tiêu hủy không có lối vào. Quyết định 2026-10-20 (T7-P mục 9 chặng 4): **một danh sách chung "Hàng cần xử lý"**, lọc theo việc |
| 2 | 036 UIF-09 | Liệt kê cả hàng "Bán được" (Amox 18 hộp) — trùng BJ-01, làm loãng danh sách việc; chip không có số; lọc rỗng không có "Xem tất cả"; không cho biết hàng nào đang chờ duyệt / chờ tiêu hủy |
| 3 | Home | "Lô sắp hết hạn · 3 lô" (số cố định) mở BJ-09 — cận hạn chỉ là chỉ báo (UC-09 BR-04), BJ-09 không có việc gì cho nó; hàng thật sự cần xử lý (hết hạn, cách ly, hỏng) không có số trên Home |
| 4 | 037 | Bảng tra 7 dòng; một nút "Thay đổi tình trạng"; lô **hết hạn không có nút nào** (ngõ cụt — không sang tiêu hủy); hàng cách ly / hỏng không có lối sang tiêu hủy (BJ-10 có 037 riêng với dữ liệu khác) |
| 5 | 038 | Lựa chọn ghi "Cần người duyệt độc lập" (sai K2: chủ cửa hàng duyệt); nút "Gửi xử lý" không nói gửi đi đâu; không có "Cả {n}"; bằng chứng là ô chữ (không chụp ảnh); không hiện tác động (khả dụng giảm, đơn đang giữ cần phân bổ lại) dù `buildBasis` đã tính; `VALIDATION_ERROR` là banner chung không chỉ ô sai; ô "Lý do" mặc định có sẵn chữ ở bản nháp đầu |
| 6 | 038 duyệt | Bảng nhãn–giá trị, không theo K2 (câu hỏi → người gửi → Cần chú ý); không có trong Home "Chờ duyệt"; sheet từ chối riêng; **chủ cửa hàng tự lập bị chặn** `SELF_APPROVAL_NOT_ALLOWED` (chỉ `actor === "approver"` duyệt được) — sai K2 |
| 7 | 041 | `ioResult` canh giữa; `UNKNOWN` không theo K3 (không mã tham chiếu, thời điểm, "Về Kho"); đổi sang "Hỏng" xong không có bước tiếp (đề nghị tiêu hủy) |
| 8 | Fixture | Mã sản phẩm lệch các chặng trước (Amox "SP-00128" — BJ-01 / BJ-06 là "SP-000066"; lô L2407-A, Vitamin C, Găng tay M không có ở đâu khác); 2 hộp Amox AM2505 bị xếp "Cách ly" ở `SC_journey_3` không xuất hiện; BJ-10 ghi cứng "Amox 500 · L2407-A · 6 hộp" trong chuỗi HTML |
| 9 | Web | Mọi màn là cột iPhone 402px giữa khung (ảnh `UIF-07_SCR-036_READY@web`), chân là nút kéo dài hết cột |
| 10 | Mã | `deniedBody` / `loadingBody` / `ioEmpty` / `ioResult` riêng thay K1 / K4; `icChoice`, `ic09Destination`, listener `data-ic09-destination` và nhánh `data-ic09-action="submit" / "approve" / "reject" / "verify"` không còn màn nào phát (chết); hai bộ listener (`v3101` trong IIFE + cấp file); nhãn `data-v3101-*`, `data-v351-*`, `data-v360-action="fallback-exit"` |

### 0.4 Đề xuất

**Luồng mới**

```text
Lối vào chung → 036 "Hàng cần xử lý" (K5 + K6: chip có số "Tất cả · Cần xử lý · Trả nhà cung cấp · Tiêu hủy · Đang chờ")
  Hub → Kiểm kê & xử lý → "Hàng cần xử lý"           (chip "Tất cả")
  Hub → Nhập, xuất & hoàn trả → "Trả nhà cung cấp"   (chip "Trả nhà cung cấp")
  Home "Cần chú ý" → "Hàng cần xử lý" "{a} lô hết hạn · {b} cách ly / hỏng"  (chip "Cần xử lý")
  BJ-01 lô hết hạn → "Xử lý lô hết hạn" → 037 của đúng lô (không qua danh sách)

036 ─dòng lô→ 037 "{tên sản phẩm}" (K5: thẻ lô + "Việc tiếp theo")
        ─"Đổi tình trạng"→ 038 ─"Gửi phê duyệt"→ 038 chờ duyệt (K2) … chủ cửa hàng: Home "Chờ duyệt" → 038 duyệt → 041 (K4)
                                ─"Đổi tình trạng" (cặp không cần duyệt)→ 041
        ─"Đề nghị tiêu hủy"→ BJ-10 040 (plan BJ-07 + BJ-10)
     ─dòng yêu cầu trả NCC→ BJ-07 037 (plan BJ-07 + BJ-10)
     ─dòng chờ tiêu hủy→ BJ-10 040 xác nhận đã tiêu hủy
     ─dòng chờ duyệt→ 038 chờ duyệt (chỉ đọc) / 040 chờ duyệt
BJ-01 lô bán được → "Đổi tình trạng" (mới, trong sheet lô) → 038 của lô đó
041 sang "Hỏng" → "Đề nghị tiêu hủy" (BJ-10) | "Về hàng cần xử lý"
```

*SCR-036 Hàng cần xử lý* — **dựng K5** trên K6 (mục 4.1); một hàm dựng cho cả UIF-07 / 09 / 10

1. Tiêu đề **"Hàng cần xử lý"** (tên màn trong spec, thay "Tình trạng hàng" / "Hàng chờ trả nhà cung cấp" / "Hàng có thể xử lý"); phụ **"Hàng không bán được và yêu cầu trả nhà cung cấp" (mới)**. Ô tìm **"Tìm sản phẩm, lô hoặc mã yêu cầu" (mới; gộp "Tìm sản phẩm hoặc lô" và "Tìm mã yêu cầu, NCC hoặc chứng từ")**.
2. Chip có số (lọc theo việc): "Tất cả" · **"Cần xử lý" (mới)** = lô không bán được chưa có việc nào đang chạy · **"Trả nhà cung cấp"** (chữ Hub) = yêu cầu trả còn hiệu lực · **"Tiêu hủy"** (chữ Hub "Tiêu hủy hàng" rút gọn) = đề nghị tiêu hủy chờ duyệt + đã duyệt chờ tiêu hủy · "Đang chờ" (chữ BJ-07) = đổi tình trạng chờ duyệt + yêu cầu trả chờ Mua hàng cập nhật. Một dòng chỉ thuộc một chip ngoài "Tất cả". Thứ tự ở "Tất cả": hết hạn → hỏng → cách ly → dùng thử → chờ tiêu hủy → trả nhà cung cấp → đang chờ.
3. **Hàng "Bán được" không vào danh sách** (đổi hàng bán được bắt đầu từ BJ-01, điểm 25). Chip "Bán được" / "Cách ly" / "Hỏng" / "Dùng thử" / "Hết hạn" theo tình trạng bỏ — tình trạng hiện ở badge.
4. Dòng iPhone (một kiểu cho cả hai loại việc):
   - lô: tiêu đề tên sản phẩm; phụ **"Lô {lô} · HSD {hsd} · {n} {ĐVT}" (mới)** (không theo lô: "{n} {ĐVT}"); thêm vế cuối khi có việc đang chạy: **"· Chờ duyệt đổi sang {tình trạng}"**, **"· Chờ tiêu hủy"** (mới); bên phải badge tình trạng: "Hết hạn" / "Hỏng" (danger), "Cách ly" (warning), "Dùng thử" (info) — chữ giữ.
   - yêu cầu trả: tiêu đề mã yêu cầu; phụ "{NCC} · {n} mặt hàng" (**mới**, thay "{NCC} · {chứng từ}"); badge giữ chữ `io07StageMeta` ("Cần chuẩn bị", "Sẵn sàng", "Cần kiểm lại", "Chờ cập nhật").
   - dòng "Chờ cập nhật" (Mua hàng đang sửa yêu cầu) tắt như hiện tại; dòng chờ duyệt **mở được, chỉ đọc** (như BJ-06).
5. Web (K7): bảng **"Hàng"** · **"Lô / yêu cầu"** · **"HSD"** · **"Số lượng"** · **"Việc"** · "Tình trạng" (mới — đầu cột). "Việc" là chữ thường: "Chưa xử lý" (mới) / "Chờ duyệt" / "Chờ tiêu hủy" / "Trả {NCC}" (mới).
6. `rowAttr` mở đúng bước đang dở (K6): lô chưa có việc / chờ duyệt đổi tình trạng → UIF-09 037 / 038; lô chờ duyệt tiêu hủy / chờ tiêu hủy → UIF-10 040 (plan sau); yêu cầu trả → UIF-07 037 (plan sau). Đổi luồng bằng `applyEntry` như BJ-04 ↔ 05; chip / ô tìm là trạng thái của K5, không của luồng, nên quay lại 036 từ luồng nào cũng thấy cùng danh sách.
7. `EMPTY` → `k1Empty` "Không có hàng cần xử lý" (**mới**) / "Hàng hết hạn, cách ly, hỏng và yêu cầu trả nhà cung cấp sẽ hiện ở đây." (**mới**); `FILTER_EMPTY` → `k1Empty` "Không có hàng phù hợp" (giữ) / "Thử đổi bộ lọc hoặc từ khóa tìm kiếm." (giữ) + "Xem tất cả" (chữ CAP-01); `LOADING` → `k1Loading`; `PERMISSION_DENIED` → `k1Denied({ what:"Bạn chưa có quyền xử lý hàng có vấn đề" (mới), next:"Liên hệ chủ cửa hàng để được cấp quyền." })`. Trạng thái `EXPIRED` của 036 (spec) = danh sách có lô hết hạn → bỏ khỏi bộ chọn trạng thái, dùng `READY` (ghi CHANGELOG).

*SCR-037 Chi tiết hàng* (UIF-09 và UIF-10 — vấn đề 4)

8. Tiêu đề = **tên sản phẩm** (như SCR-003 của BJ-01); phụ "Lô {lô} · HSD {hsd}" (mới) hoặc "Không theo lô" (giữ chữ BJ-05).
9. Thẻ lô `k5LotCard` (mục 4.1): badge tình trạng + dải số một hàng (`cf12Strip`) **"{n} {ĐVT} {tình trạng} · Khả dụng bán {k}" (mới)**; dòng nguồn khi biết: **"Từ hàng khách trả {mã}" / "Từ nhận hàng {mã}" (mới)**. Bỏ các dòng "Mã", "Tình trạng", "Tồn vật lý" lặp.
10. Khối **"Việc tiếp theo" (mới)** theo tình trạng — nút chính / phụ ở chân (`k4Footer`):

    | Tình trạng lô | Banner | Chính | Phụ |
    |---|---|---|---|
    | Hết hạn | "Lô đã hết hạn" + "Hết hạn theo ngày nghiệp vụ {ngày}; hệ thống tự loại khỏi khả dụng." (giữ) | **"Đề nghị tiêu hủy" (chữ BJ-10)** | — |
    | Hỏng | — | "Đề nghị tiêu hủy" | "Đổi tình trạng" |
    | Cách ly | — | "Đổi tình trạng" | "Đề nghị tiêu hủy" |
    | Dùng thử | — | "Đổi tình trạng" | "Đề nghị tiêu hủy" |
    | Bán được (vào từ BJ-01) | — | "Đổi tình trạng" | — |
    | Có việc đang chạy | `k2Pending` "Chờ chủ cửa hàng duyệt · gửi {lúc}" hoặc "Đã duyệt · chờ tiêu hủy" (plan sau) | "Xem yêu cầu" (**mới**) | — |

    Dưới khối: một dòng **"Trả nhà cung cấp do bộ phận Mua hàng lập yêu cầu. Khi có yêu cầu, hàng hiện ở mục Trả nhà cung cấp." (mới)** cho lô Hết hạn / Hỏng / Cách ly (UC-07-01: Kho không tự tạo). Liên kết "Xem lịch sử" (giữ) → 056.
11. `LOCKED` → `k1Locked({ title:"Đang thuộc phạm vi kiểm kê" (giữ), description:"Thông tin chỉ đọc cho đến khi phiên kiểm kê kết thúc." (giữ) })`, thẻ lô vẫn hiện, không nút. `FINANCIAL_RESTRICTED` (spec): 037 không có số tiền → dựng như `READY` (ghi CHANGELOG). `LOADING` / `PERMISSION_DENIED` → K1.
12. Web: `k7Split` — trái thẻ lô + "Việc tiếp theo"; phải khối "Tóm tắt" (chữ BJ-03): Sản phẩm · Mã · Lô · HSD · Nguồn · Khả dụng bán; chân là thanh nút bên phải.

*SCR-038 Đổi tình trạng* (vấn đề 5)

13. Tiêu đề **"Đổi tình trạng" (mới — thay "Chuyển tình trạng hàng"; chữ nút ở 037)**; phụ "{sản phẩm} · Lô {lô}". Thẻ lô thu gọn một dòng (iPhone) / khối "Tóm tắt" (web).
14. **"Đổi sang" (mới)** — `dsChoiceRow` mỗi cặp được phép từ tình trạng hiện tại (`POLICY.transitions`), chữ tình trạng giữ; mô tả: **"Cần chủ cửa hàng duyệt" (mới — thay "Cần người duyệt độc lập")** / **"Ghi nhận ngay" (mới — thay "Có thể xử lý ngay theo quy tắc hiện hành")**; **không chọn sẵn** (bản cũ chọn sẵn "Cách ly"). Bỏ dòng "Yêu cầu này sẽ được gửi người duyệt độc lập." (lặp mô tả).
15. "Số lượng" (**mới**, thay "Số lượng chuyển") — `k5QtyField`: ô số + nút **"Cả {n} {ĐVT}" (chữ BJ-06)**; lỗi dưới ô **"Tối đa {n} {ĐVT}" (giữ vế "Tối đa")**. Bỏ câu "Hệ thống tự xác định đúng phần tồn được chuyển." (chi tiết nội bộ).
16. "Lý do" (giữ) — ô chữ trống, bắt buộc. "Ảnh bằng chứng" (**mới**, thay ô chữ "Bằng chứng") — `k5Evidence` ("Chụp ảnh" | "Chọn tệp" iPhone, "Kéo tệp vào đây hoặc Chọn tệp" web — chữ BJ-02 / BJ-06), chỉ hiện khi cặp chuyển bắt buộc bằng chứng.
17. Khối **"Sau khi đổi" (mới)** (`k2Attention` tone info): **"Khả dụng bán: {a} → {b} {ĐVT}" (mới)**; khi `reservationImpact.shortfall > 0`: **"Đơn đang giữ: {n} {ĐVT} cần phân bổ lại" (mới, tone warning)**; dòng cố định "Tổng tồn và giá trị không đổi." (**mới**, rút từ "Đổi tình trạng chỉ phân loại lại cùng lượng hàng…").
18. Chân `k4ReasonFooter`: cặp cần duyệt → **"Gửi phê duyệt" (chữ BJ-02)**; không cần duyệt → "Đổi tình trạng". Lý do khi tắt: **"Chọn tình trạng mới"**, **"Nhập số lượng"**, **"Nhập lý do"**, **"Thêm ảnh bằng chứng"** (mới). `VALIDATION_ERROR` → lỗi tại ô (không banner chung).
19. `PENDING_APPROVAL` (người lập) → `k2Pending({ approver:"chủ cửa hàng", sentAt, facts })` + dữ liệu khoá; chân "Về hàng cần xử lý" (**mới**, thay "Về danh sách"). `LOCKED` → `k1Locked` (giữ chữ). `STATE_CHANGE_BASIS_STALE` / `CONFLICT` → `k1Stale({ title:"Cần lập lại yêu cầu" (giữ), description:"Dữ liệu đã thay đổi; quyết định cũ không còn hiệu lực." (giữ), actionLabel:"Lập lại yêu cầu" (giữ) })`.

*SCR-038 Duyệt đổi tình trạng* (K2 — vấn đề 6)

20. Vào từ Home **"Chờ duyệt"**: nguồn `__T7_PENDING_SOURCES__` `{ id:"UIF-09", label:"đổi tình trạng" (mới) }`, dòng "{sản phẩm} · Lô {lô}" / "{n} {ĐVT} · {từ} → {sang} · {người gửi} gửi {lúc}" (mới), mở 038 của đúng yêu cầu (`__T7_DIRECT_CONTEXTS__["bj09-approval"]`).
21. `k2Decision({ question:"Duyệt đổi {n} {ĐVT} {sản phẩm} lô {lô} từ {từ} sang {sang}?" (mới), maker, sentAt, attention: khối "Sau khi đổi" của điểm 17, facts: Lý do · Ảnh bằng chứng (ảnh nhỏ) })`; banner "Phê duyệt không ghi tồn" bỏ (K2 đã nói ở "Sau khi duyệt"). Chân "Từ chối" | "Duyệt" (giữ). Từ chối → `k2RejectSheet` (giữ chữ "Từ chối yêu cầu?", "Lý do từ chối", "Xác nhận từ chối").
22. Ai duyệt được: `currentActor()` là `approver` hoặc `owner` (như `bj06CanDecide`); chủ cửa hàng tự lập: gửi rồi tự vào "Chờ duyệt" duyệt (K2). `SELF_APPROVAL_NOT_ALLOWED` chỉ khi người bấm không phải chủ: `vBanner` "Không thể tự duyệt" (giữ) + **"Chỉ chủ cửa hàng duyệt đổi tình trạng." (mới)**.
23. Web: `k7Split` — trái câu hỏi + Cần chú ý + số liệu; phải ảnh bằng chứng.

*SCR-041 Kết quả đổi tình trạng* (K4 — vấn đề 7)

24. `COMPLETED` → `k4Result({ screenTitle:"Kết quả thay đổi" (giữ), title:"Đã cập nhật tình trạng" (giữ), description:"Cùng lượng hàng đã được phân loại lại; tổng tồn vật lý và giá trị không thay đổi." (giữ) })`; `facts`: Sản phẩm · Lô · "Đã chuyển" "{n} {ĐVT} · {từ} → {sang}" (giữ) · "Còn ở trạng thái nguồn" (giữ) · **"Người duyệt"** ("Chủ cửa hàng" / "Không cần duyệt") · **"Ghi nhận lúc"** (mới) · "Cần phân bổ lại" (giữ, khi có); liên kết "Xem biến động" (giữ) → 056. Bước tiếp: sang "Hỏng" → phụ **"Về hàng cần xử lý"** | chính "Đề nghị tiêu hủy"; còn lại → một nút "Về hàng cần xử lý". `EXPIRED` (UIF-09-T09: hệ thống tự xác định) → K4 cảnh báo "Lô đã hết hạn" (giữ câu) + chính "Đề nghị tiêu hủy". `REJECTED_EXECUTION` / `STATE_CHANGE_BASIS_STALE` → K4 cảnh báo "Yêu cầu chưa được thực hiện" (giữ câu) + "Về hàng cần xử lý". `UNKNOWN` → `k3Unknown({ operation:"Đổi tình trạng hàng" (mới), scope:"{sản phẩm} · Lô {lô}", ref, sentAt, sourceFlow:"UIF-09" })` (không truyền `safe` — bài học R3 chặng 3). `PROCESSING` → `k1Loading`. `PERMISSION_DENIED` → K1.

*Lối vào ở BJ-01 và Hub* (vấn đề 1, 3)

25. BJ-01 sheet lô (SCR-003): lô bán được thêm nút phụ **"Đổi tình trạng" (mới)** → UIF-09 038 của lô đó (lô có trong fixture chặng 4); lô hết hạn: "Xử lý lô hết hạn" (giữ chữ) mở thẳng **037** của lô (thay 036 lọc). Quay lại → SCR-003.
26. Hub — "Kiểm kê & xử lý": "Hàng cần xử lý" giữ chữ, mở 036 chip "Tất cả". "Nhập, xuất & hoàn trả": "Trả nhà cung cấp" giữ chữ, mở **cùng 036** chip "Trả nhà cung cấp". "Tồn kho": **bỏ "Tình trạng hàng"** (trùng; xem tình trạng từng lô ở BJ-01).
27. Home "Cần chú ý": thay "Lô sắp hết hạn · 3 lô" bằng **"Hàng cần xử lý" + "{a} lô hết hạn · {b} cách ly / hỏng" (mới)**, số = số dòng chip "Cần xử lý" (không đếm "Dùng thử"), mở 036 chip "Cần xử lý"; không có dòng nào thì không hiện. Cận hạn vẫn xem ở BJ-01 (chip "Cận hạn") — không thêm dòng Home (0.10 c).

### 0.5 Trạng thái (sau thiết kế lại)

| Màn | Trạng thái | Hiện gì | Làm được gì | Lối ra |
|---|---|---|---|---|
| 036 | READY | K5: chip có số, danh sách / bảng | lọc, tìm, mở dòng (đúng bước) | Về Kho |
| 036 | EMPTY / FILTER_EMPTY | `k1Empty` | "Xem tất cả" (FILTER_EMPTY) | Về Kho |
| 036…041 | LOADING | `k1Loading` | — | — |
| 036…041 | PERMISSION_DENIED | `k1Denied` | — | "Về Kho" |
| 037 | READY | thẻ lô, "Việc tiếp theo" theo tình trạng | "Đổi tình trạng", "Đề nghị tiêu hủy", "Xem lịch sử" | Quay lại |
| 037 | EXPIRED | banner hết hạn, thẻ lô | "Đề nghị tiêu hủy" | Quay lại |
| 037 | LOCKED | `k1Locked`, thẻ lô | "Xem lịch sử" | Quay lại |
| 037 | (lô có việc đang chạy) | `k2Pending` / "chờ tiêu hủy" | "Xem yêu cầu" | Quay lại |
| 038 | READY / VALIDATION_ERROR | đổi sang, số lượng, lý do, ảnh, "Sau khi đổi"; lỗi tại ô | "Gửi phê duyệt" / "Đổi tình trạng" | Quay lại |
| 038 | PENDING_APPROVAL | `k2Pending`, dữ liệu khoá | — | "Về hàng cần xử lý" |
| 038 | APPROVAL_REVIEW | `k2Decision` | "Từ chối", "Duyệt" | Quay lại (về "Chờ duyệt") |
| 038 | SELF_APPROVAL_NOT_ALLOWED | banner | — | "Về hàng cần xử lý" |
| 038 | STATE_CHANGE_BASIS_STALE / CONFLICT | `k1Stale` | "Lập lại yêu cầu" | Quay lại |
| 038 | LOCKED | `k1Locked` | — | Quay lại |
| 041 | COMPLETED | K4 | "Xem biến động", "Đề nghị tiêu hủy" (khi sang Hỏng), "Về hàng cần xử lý" | Về Kho |
| 041 | EXPIRED | K4 cảnh báo | "Đề nghị tiêu hủy" | Về Kho |
| 041 | REJECTED_EXECUTION / STATE_CHANGE_BASIS_STALE | K4 cảnh báo | "Về hàng cần xử lý" | Về Kho |
| 041 | UNKNOWN | K3 | "Chuyển sang xác minh" | "Về Kho" |
| 041 | PROCESSING | `k1Loading` | — | — |
| 056 | (giữ) | lịch sử tình trạng của lô — thiết kế lại ở chặng 6 (BJ-15) | — | Quay lại → 037 |

### 0.6 Khuôn dùng lại và khuôn dựng mới

- **Dựng K5** (mục 4.1): `app/shared-problem.js` — fixture lô chặng 4, nguồn dòng `__T7_PROBLEM_SOURCES__`, `render036K5`, `render037K5`, `k5LotCard`, `k5QtyField`, `k5Evidence`, `k5Open`. BJ-07 (036), BJ-10 (036, 037) dùng lại ngay ở plan sau.
- Dùng lại: K1, K2 (`k2Pending`, `k2Decision`, `k2Attention`, `k2RejectSheet`, nguồn "Chờ duyệt", `__T7_DIRECT_CONTEXTS__`), K3 (`k3Unknown`), K4 (`k4Result`, `k4Footer`, `k4ReasonFooter`), K6 (`k6TaskList`), K7 (`k7Split`, `k7Table`, lớp `k7-wide`), `dsChoiceRow`, `cf12Strip`.
- `k5Evidence` chép HTML vùng ảnh của BJ-06 (`bj06EvidenceZone`); **không** đổi BJ-02 / BJ-06 sang hàm mới ở chặng này (giữ golden chặng 2–3) — gộp ở đợt dọn cuối Giai đoạn 2.
- Không thành phần DS mới ngoài K5.

### 0.7 Không đổi

Quy tắc ở 0.1; `POLICY` (ma trận chuyển, lý do / bằng chứng / duyệt theo cặp), `resolveSlices`, `eligibleQty`, `buildBasis` (gồm `reservationImpact`), `systemCommit` (tách lô khi đổi một phần, giữ trạng thái định giá), `queueSystemCommit`, `onUnknownHandoff` của UIF-09 (thêm nếu chưa có — mục 4.3). Chữ giữ: tên tình trạng ("Bán được", "Cách ly", "Hỏng", "Dùng thử", "Hết hạn"), "Lô đã hết hạn" + câu, "Đang thuộc phạm vi kiểm kê" + câu, "Lý do", "Duyệt", "Từ chối", "Từ chối yêu cầu?", "Lý do từ chối", "Xác nhận từ chối", "Không thể tự duyệt", "Cần lập lại yêu cầu", "Lập lại yêu cầu", "Kết quả thay đổi", "Đã cập nhật tình trạng", "Đã chuyển", "Còn ở trạng thái nguồn", "Cần phân bổ lại", "Xem biến động", "Xem lịch sử", "Yêu cầu chưa được thực hiện", "Lịch sử tình trạng".

### 0.8 Kiểm (bước D)

- Golden **mobile** được khác: `UIF-09_*`, `UIF-07_SCR-036_*`, `UIF-10_SCR-036_*`, `UIF-10_SCR-037_*`, `SC_bj09_*`, `SC_bj07_list_*` (036 mới), `SC_bj10_flow_0`…`_1` (036 / 037 mới; bước 040 trở đi **phải khớp** tới plan sau), `SC_attention_UIF-09_*` (dòng Home mới), `SC_entry_UIF-09_*`, `SC_entry_UIF-10_product-context_*`, `SC_ws_inventory_*` (bỏ một mục), `SC_ws_movement_3_*`, `SC_ws_control_1_*`, `SC_bj01_expired*`, `SC_bj01_detail_*` / `SC_bj01_tylo_*` (nút mới trong sheet lô), `SC_bj17_from_bj09_*` nếu có (bước 0), và **mọi ca có Home Kho** (dòng "Cần chú ý" đổi; số "Chờ duyệt" thêm nguồn "đổi tình trạng" nếu fixture có ca chờ). Ca khác khớp mốc `tools/.golden-chang3`.
- Golden **web** được khác: như trên với `@web` + kịch bản web mới; ca khác khớp `tools/.golden-chang3-web`.
- Kịch bản (mục 5.3): sửa `SC_bj09_flow`, `SC_bj09_approve`, `SC_bj09_history_back`, `SC_bj01_expired`, `SC_bj01_expired_sheet`; thêm `SC_k5_list`, `SC_k5_filter_empty`, `SC_bj09_quarantine_to_damaged`, `SC_bj09_no_approval`, `SC_bj09_owner_self`, `SC_bj09_reject`, `SC_bj09_from_bj01`, `SC_bj09_expired_to_disposal`, `SC_k5_hub_rtv`.

### 0.9 Ước lượng C–E

~2,5 ngày: C0 fixture ~0,25; C1 K5 + 036 + 037 + lối vào Hub / Home / BJ-01 ~1; C2 038 + duyệt + 041 ~0,75; D ~0,25; E ~0,25. (T7-P mục 8.2 ghi 2 khi còn chia thiết bị chính / phụ; thêm danh sách chung cho ba luồng và bố cục web.)

### 0.10 Đã chốt khi duyệt brief (2026-10-25): **mọi điểm theo cột "Đề xuất"**

| # | Điểm | Đề xuất | Phương án khác |
|---|---|---|---|
| a | Danh sách chung có hàng "Bán được" không | **Không** — chỉ hàng không bán được + yêu cầu trả; đổi hàng bán được bắt đầu từ sheet lô ở BJ-01 (điểm 25) | Giữ chip "Bán được" (danh sách thành bản sao BJ-01) |
| b | Chip của 036 | **Theo việc**: "Tất cả · Cần xử lý · Trả nhà cung cấp · Tiêu hủy · Đang chờ" (tình trạng ở badge) | Theo tình trạng: "Tất cả · Hết hạn · Cách ly · Hỏng · Dùng thử" + chip "Trả nhà cung cấp" |
| c | Home "Cần chú ý" | **Thay** "Lô sắp hết hạn" bằng "Hàng cần xử lý" "{a} lô hết hạn · {b} cách ly / hỏng" → 036; cận hạn chỉ xem ở BJ-01 | Giữ cả hai dòng: "Lô cận hạn" → BJ-01 chip "Cận hạn" và "Hàng cần xử lý" → 036 |
| d | Hub "Tồn kho → Tình trạng hàng" | **Bỏ** (trùng "Hàng cần xử lý" và BJ-01) | Giữ, mở cùng 036 |
| e | 037 dùng chung cho BJ-09 và BJ-10 | **Một màn** (tên sản phẩm, "Việc tiếp theo"): đổi tình trạng và đề nghị tiêu hủy đều từ đây | Giữ hai 037 riêng theo luồng |
| f | "Trả nhà cung cấp" từ một lô | **Chỉ một dòng giải thích** (Mua hàng lập yêu cầu — UC-07-01); không nút | Nút "Báo Mua hàng" (Theme 10 chưa có, cần backend) |
| g | Ảnh bằng chứng ở 038 | **Chụp ảnh / chọn tệp** (`k5Evidence`) thay ô chữ | Giữ ô chữ "Nhập hoặc tham chiếu bằng chứng" |

---

## 1. Mục tiêu

1. Một danh sách "Hàng cần xử lý" cho cả ba việc của chặng 4, lọc theo việc, mở đúng bước đang dở.
2. Không ngõ cụt: lô hết hạn / hỏng đi tiếp được sang đề nghị tiêu hủy; lô bán được đổi được từ BJ-01.
3. Đổi tình trạng theo K2 thật: chủ cửa hàng duyệt từ Home "Chờ duyệt", thấy tác động trước khi quyết.
4. K5 dựng xong, mô tả ở T7-P mục 5, BJ-07 / BJ-10 dùng được ngay.
5. Mọi trạng thái 0.5 dựng khác nhau và có lối ra, ở cả hai khung.

## 2. Chuẩn bị

1. Chặng 3 đã review và commit (T7-P mục 14 — `2718499a8`). Nếu review chặng 2 / 3 chốt đề xuất "lối về Kho ở K4" / "bẫy focus cho mọi sheet" (T7-P mục 13, dòng `13 / 03 / mọi K4`) thì làm theo cách đã chốt.
2. Mốc = `tools/.golden-chang3` / `tools/.golden-chang3-web` (chụp ở v5.12.2). Chụp lại ở HEAD, so "Khớp hoàn toàn"; lệch → chụp `tools/.golden-bj09-base` / `-web-base` làm mốc và ghi mục 9.
3. GitNexus (CLAUDE.md): `impact` hướng upstream cho `render036BJ09`, `render037BJ09`, `render038BJ09`, `render041BJ09`, `render036BJ07`, `render036BJ10`, `render037BJ10`, `renderHubHome`, `bj01` listener (`data-bj01-dispose-lot`), `applyEntry`; báo mức rủi ro vào mục 9. Chỉ mục cũ thì `node .gitnexus/run.cjs analyze` trước; trả lại `CLAUDE.md` / `AGENTS.md` nếu `analyze` ghi đè số ký hiệu.
4. Máy chủ `python3 -m http.server 8765 --bind 127.0.0.1 &` trong `html/`.

## 3. Bước C0 — fixture chung chặng 4 (commit 1, cùng C1)

Mục đích: `SC_journey_4` (plan sau) đi "hàng cách ly từ khách trả → đổi sang hỏng → trả nhà cung cấp; lô hết hạn → tiêu hủy" trên **cùng sản phẩm / lô với chặng 1–3**.

Fixture lô chuyển từ `bj09.js` (`ic09Items`) sang `app/shared-problem.js` (`t7Lots`; `ic09Items` thành bí danh trỏ cùng mảng tới khi BJ-07 / 10 đổi xong, rồi xoá ở plan sau).

| Lô (`id`) | Sản phẩm · mã | Lô · HSD | Lượng · tình trạng | Nguồn | Dùng cho |
|---|---|---|---|---|---|
| `tylo-ty2408` | Tylosin 20% · SP-000122 | TY2408 · 31/07/2026 | 11 lọ · Hết hạn | BJ-01 (`INV-TYLO`) | BJ-01 "Xử lý lô hết hạn" → 037; BJ-10 tiêu hủy |
| `amox-am2505` | Amox 500 · SP-000066 | AM2505 · 31/05/2027 | 2 hộp · Cách ly | "Từ hàng khách trả RET-260827-03" (`SC_journey_3` xếp RET-L2 "Cách ly") | BJ-09 Cách ly → Hỏng; BJ-07 yêu cầu RTV-260903-03 |
| `glove-nitrile` | Găng tay khám Nitrile · SP-000271 | không theo lô | 3 hộp · Hỏng | "Từ nhận hàng PN-260905-02" | BJ-10 "Chờ tiêu hủy" (plan sau) |
| `oil-demo` | Dầu sát khuẩn · SP-00606 | L2406-T · 31/12/2027 | 2 chai · Dùng thử | — | BJ-09 Dùng thử → Bán được (cần duyệt + ảnh) |
| `nob-dh2507` | Nobivac DHPPi · SP-000184 | DH2507 · 30/11/2026 | 70 hộp · Bán được | BJ-01 (`INV-NOB`) | BJ-01 "Đổi tình trạng" → Cách ly (không vào danh sách) |

- Bỏ: Amox L2407-A, Găng tay M, Vitamin C (không có ở chặng nào khác).
- `SOURCE` (slice định giá) thêm cho cả năm lô (một slice `VALUATION_CONFIRMED`; `nob-dh2507` có `reservationBefore:12` khớp BJ-01 "giữ 12 hộp" để thấy "Đơn đang giữ … cần phân bổ lại").
- Một yêu cầu **chờ duyệt** sẵn: `ST-260915-01` — `oil-demo` Dùng thử → Bán được, 2 chai, "Hết đợt trưng bày, hàng còn nguyên hộp", ảnh mẫu, "Nguyễn Văn An" gửi "15/09/2026 16:20" → Home "Chờ duyệt" có dòng "đổi tình trạng"; `?uif=UIF-09&entry=approver` mở ca này (bỏ bước `seed` trong golden).
- Ngày nghiệp vụ giữ `BUSINESS_DATE = '17/09/2026'`.
- Không sửa fixture BJ-01 / BJ-06 (Amox ở BJ-01 không theo lô, BJ-06 theo lô AM2505 — lệch đã có từ trước; ghi mục 9, sửa ở Giai đoạn 3 nếu cần).

## 4. Bước C1 — K5, danh sách chung, chi tiết, lối vào (commit 1)

### 4.1 Khuôn K5 (`app/shared-problem.js`, nạp sau `shared-patterns.js`, trước `bj07.js`)

1. Fixture lô (mục 3) + `t7Lot(id)`, `t7LotStateLabel(state)`, `t7LotTone(state)` (gộp `ic09StatusTone`, `stateLabel`).
2. **Nguồn dòng** `window.__T7_PROBLEM_SOURCES__` (cùng kiểu nguồn "Chờ duyệt" của K2): mỗi BJ đẩy `{ id, rows() }`; mỗi dòng:
   ```js
   { key, kind: "LOT" | "REQUEST", title, sub, lot, expiry, qty, uom,
     state: { label, tone },   // badge
     job: "OPEN" | "RTV" | "DISPOSAL" | "WAITING", // chip
     task: "Chưa xử lý" | "Chờ duyệt" | "Chờ tiêu hủy" | "Trả {NCC}", // cột "Việc"
     lotId, order, disabled, open }   // open = thuộc tính mở bước tiếp (applyEntry do BJ quyết)
   ```
   **Một lô một dòng:** nhiều nguồn cùng trả dòng cho một `lotId` thì K5 giữ dòng có việc đang chạy (`DISPOSAL` / `WAITING` thắng `OPEN`) — BJ-09 cứ trả dòng `OPEN` cho mọi lô không bán được, không cần biết BJ-10 đang làm gì.
   BJ-09 đẩy dòng lô (`OPEN` / `WAITING` khi có yêu cầu đổi chờ duyệt). Ở plan này BJ-07 / BJ-10 **tạm** đẩy dòng từ dữ liệu hiện có (`io07ActiveRequests()` → `RTV`/`WAITING`; lô `glove-nitrile` → `DISPOSAL` "Chờ tiêu hủy" mở 040 `COMPLETION` hiện tại) để danh sách đủ ngay; plan sau thay bằng dữ liệu thật của hai BJ.
3. `render036K5(state)`: trạng thái K5 `k5Filter` ("ALL" | "OPEN" | "RTV" | "DISPOSAL" | "WAITING"), `k5Query`; dựng bằng `k6TaskList` theo 0.4 điểm 1–7 (`mobileRow` riêng: badge tình trạng bên phải, phụ có vế việc). `appShell({ …, extraClass:"k7-wide" })`. Nhãn sự kiện `data-k5-filter`, `data-k5-search`, `data-k5-row`, `data-k5-filter-empty`.
4. `k5Open(row)`: đặt lô / yêu cầu đang chọn rồi `applyEntry(flow, entry)` — UIF-09 `product-context` (037), UIF-09 `request-view` (**mới**, 038 `PENDING_APPROVAL`), UIF-07 `return-task` (037), UIF-10 `completion-operator` (040). Ghi `k5ReturnTo = "SCR-036"` để nút quay lại của màn đích về 036 (dùng `data-keep-back` của Hub như BJ-04).
5. `k5SetEntryFilter(flow)`: vào 036 bằng lối Hub "Trả nhà cung cấp" (UIF-07) → `k5Filter = "RTV"`; Home "Hàng cần xử lý" → `"OPEN"`; còn lại `"ALL"`.
6. `render037K5(state)`: theo 0.4 điểm 8–12; nút: `data-k5-action="change-state"` (→ UIF-09 038), `data-k5-action="request-disposal"` (→ `applyEntry("UIF-10", "product-context")` với lô đang chọn — plan sau dựng 040 mới; ở plan này đi vào 040 `READY` hiện có), `data-k5-action="view-request"`, `data-k5-action="history"` (→ 056).
7. `k5LotCard({ lot, compact })`: badge + `cf12Strip` + dòng nguồn; `compact` = một dòng cho 038 / 040 iPhone.
8. `k5QtyField({ value, max, uom, attr, fillAttr, error, label })`: `k7EditCell` + nút "Cả {n} {ĐVT}" (≥ 44 × 44 ở iPhone).
9. `k5Evidence({ files, attrPrefix, required, hint })`: chép `bj06EvidenceZone` (nút chụp `capture="environment"`, chọn tệp, danh sách tệp có "Xoá", dòng web "Kéo tệp vào đây hoặc Chọn tệp"); `window.__VET45_QA__.setK5Evidence(key)` đặt ảnh mẫu như `setIO06Evidence`.

### 4.2 Dữ liệu và trạng thái (`app/bj09.js`)

1. `ic09Selected` → `k5SelectedLotId` (K5); `current()` đọc `t7Lot`.
2. Bản nháp: `resetDraft()` không chọn sẵn đích (`destination:""`), lượng trống, lý do trống (vấn đề 5). `basisValid` theo đích rỗng → lý do chân "Chọn tình trạng mới".
3. Danh sách yêu cầu `bj09Requests` (gồm `ST-260915-01` mục 3): `submit` cặp cần duyệt → thêm yêu cầu `PENDING` (người gửi = `IO05_ACTOR`/"Nguyễn Văn An" khi actor nhân viên, "Chủ cửa hàng" khi `owner`), thời điểm cố định "17/09/2026 15:02". Duyệt / từ chối đổi `status`.
4. Nguồn K2: `__T7_PENDING_SOURCES__.push({ id:"UIF-09", label:"đổi tình trạng", needsActivation:true, rows })` + `__T7_DIRECT_CONTEXTS__["bj09-approval"]` (đặt yêu cầu đang duyệt, 038 `APPROVAL_REVIEW`).
5. Nguồn K5: `__T7_PROBLEM_SOURCES__.push({ id:"UIF-09", rows })` — mọi lô không "Bán được" (`OPEN`), lô có yêu cầu đổi chờ duyệt (`WAITING`); lô đang có đề nghị tiêu hủy do nguồn BJ-10 thắng (quy tắc "một lô một dòng", 4.1 điểm 2).
6. `bj09CanDecide()` = `["approver", "owner"].includes(currentActor())` (thay `actor()!=='approver'`).
7. `systemCommit` giữ; sau khi ghi: nếu đích là `DAMAGED` → 041 có "Đề nghị tiêu hủy". Lô tách mới (đổi một phần) nhận `id` ổn định `${id}-${to}` (thay `Date.now()`) để golden lặp lại được.
8. `onUnknownHandoff["UIF-09"]` (**mới** — hiện chưa có): khoá yêu cầu đang xác minh (không mở lại 038, dòng 036 vào "Đang chờ") như `bj07.js:437`. `bj17.js` nhận mọi `sourceFlow` qua `bj17RecoveryCase` nên không sửa `bj17.js`; `k3Unknown` dựng nút `handoff-unknown` với `data-operation` = mã yêu cầu (`ST-…`).
9. Xoá mã chết (vấn đề 10): `icChoice`, `ic09Destination`, listener `data-ic09-destination`, nhánh `data-ic09-action` `submit` / `approve` / `reject` / `verify`, `render036IC09` / `render037IC09` / `render041IC09` (gộp K1 / K4), `bj09HistoryBase` gộp vào `render056BJ09History`. Gộp hai bộ listener về một khối cuối file; nhãn `data-v3101-*` → `data-bj09-*`, `data-v351-ic09-history-back` → `data-bj09-history-back`, `data-v360-action="fallback-exit"` → `data-k5-action="to-list"`. Sửa `tools/golden.mjs` theo nhãn mới.

### 4.3 Màn

| Màn | Việc |
|---|---|
| Chung | `flowRenderers["UIF-07" / "UIF-09" / "UIF-10"]["SCR-036"] = render036K5`; `flowRenderers["UIF-09" / "UIF-10"]["SCR-037"] = render037K5` (đăng ký trong `shared-problem.js`; `bj07.js` / `bj10.js` **bỏ** đăng ký 036 / 037-UIF-10 của mình, giữ hàm tới plan sau rồi xoá). Nhãn inspector `core.js` dòng 36–39: 036 "Mobile / Root List" giữ |
| 036 | 0.4 điểm 1–7 |
| 037 | 0.4 điểm 8–12 |
| 038 | 0.4 điểm 13–23 (C2) |
| 041 | 0.4 điểm 24 (C2) |
| 056 | giữ nội dung; K1 cho `LOADING` / `PERMISSION_DENIED`; quay lại → 037 (`data-bj09-history-back`) |
| Hub | `hub.js` `WORKSPACES.inventory` bỏ mục UIF-09; `movement` mục UIF-07 và `control` mục UIF-09 đặt `k5SetEntryFilter`; `renderHubHome` thay dòng "Lô sắp hết hạn" (0.4 điểm 27) — dòng đọc số từ `__T7_PROBLEM_SOURCES__` (không gõ cứng), `data-t462-attention="UIF-09"` giữ để `SC_attention_UIF-09` còn chạy |
| BJ-01 | `bj01.js`: sheet lô thêm `data-bj01-change-state="{lô}"` cho lô bán được có trong `t7Lots`; `data-bj01-dispose-lot` mở `applyEntry("UIF-09", "product-context")` với `k5SelectedLotId` của lô (thay đặt `ic09Filter` / `ic09Query`) |

### 4.4 Sự kiện

1. `data-k5-filter` / `data-k5-search` (lọc tại chỗ như K6 BJ-05) / `data-k5-row` → `k5Open`.
2. `data-k5-action` theo 4.1 điểm 6; `data-k5-action="to-list"` → 036 (giữ chip).
3. 038: `data-bj09-destination` (dsChoiceRow), `data-bj09-qty`, `data-bj09-qty-fill`, `data-bj09-reason`, `data-bj09-evidence-*`, `data-bj09-action="submit" | "approve" | "reject-open" | "reject-close" | "reject-confirm" | "rebuild"`. Gõ vào ô không dựng lại cả màn (giữ focus) — chỉ cập nhật chân và khối "Sau khi đổi" như `syncVerifyButton` của BJ-07.
4. Sau "Gửi phê duyệt": toast **"Đã gửi chủ cửa hàng duyệt" (mới)** ngay sau `render()`; "Đổi tình trạng" (không cần duyệt): đi 041 không toast.

## 5. Bước C2 — đổi tình trạng, duyệt, kết quả, golden (commit 2, cùng D)

### 5.1 Màn

038 (0.4 điểm 13–23) và 041 (điểm 24). Gộp CSS `v364-radio-*` (chỉ BJ-09 dùng — `grep` trước), `.ic-action-stack` của BJ-09 về khối BJ-09 trong `styles/screens.css`, bỏ `!important` không còn đối thủ (T7-P mục 4.4); khối K5 trong `styles/components.css`. Bỏ luật cột 402px của khung web cho UIF-09 (H1 lệch 1) khi màn đã có bố cục K7.

### 5.2 Golden mở thẳng

Bộ chọn trạng thái: 036 bỏ `EXPIRED` (0.4 điểm 7); 037 bỏ `FINANCIAL_RESTRICTED` nếu dựng giống `READY` (giữ ca nếu bỏ không được — ghi mục 9). Trạng thái đặt từ ngoài (golden) dựng lại fixture gốc như `io05Seed` / `io06Seed` (bài học chặng 3): `bj09Seed(screen, state)` — 038 `APPROVAL_REVIEW` = `ST-260915-01`; 038 `PENDING_APPROVAL` = yêu cầu mẫu `amox-am2505` Cách ly → Hỏng; 041 `COMPLETED` = kết quả mẫu `amox-am2505` → Hỏng.

### 5.3 Kịch bản (`tools/golden.mjs`, `S9 = '?uif=UIF-09&screen='`)

Sửa: `SC_bj09_flow` (bỏ chip "Bán được"; dòng `amox-am2505` → "Đổi tình trạng" → "Hỏng" → "Cả 2 hộp" → lý do → ảnh mẫu → "Gửi phê duyệt"), `SC_bj09_approve` (bỏ `seed`; `?uif=UIF-09&entry=approver` → từ chối → lý do → đóng → duyệt), `SC_bj09_history_back`, `SC_bj01_expired` / `SC_bj01_expired_sheet` (đích 037 Tylosin).

| Kịch bản | Bắt đầu | Bước |
|---|---|---|
| `SC_k5_list` | `S9 + 'SCR-036'` | chip "Cần xử lý" → "Trả nhà cung cấp" → "Tiêu hủy" → "Đang chờ" → "Tất cả" → tìm "TY2408" → xoá → dòng `tylo-ty2408` |
| `SC_k5_filter_empty` | `S9 + 'SCR-036'` | tìm "zzz" → "Xem tất cả" |
| `SC_bj09_quarantine_to_damaged` | `T + 'inventory'` (Toàn Theme 7) | workspace "control" → "Hàng cần xử lý" → `amox-am2505` → "Đổi tình trạng" → "Hỏng" → "Cả 2 hộp" → lý do → ảnh mẫu → "Gửi phê duyệt" → `home(…)` (helper của `SC_journey_3`) → "Chờ duyệt" → dòng `ST-…` (vai `approver` do dòng gắn) → "Duyệt" → 041 → "Đề nghị tiêu hủy" (dừng ở 040 hiện có) |
| `SC_bj09_no_approval` | `S9 + 'SCR-036'` | `amox-am2505` → "Đổi tình trạng" → "Dùng thử" → số lượng 1 → lý do → "Đổi tình trạng" → 041 (lô tách) → "Về hàng cần xử lý" |
| `SC_bj09_owner_self` | `T + 'inventory&entry=owner'` | như `quarantine_to_damaged` tới gửi → Home "Chờ duyệt" → dòng → "Duyệt" được, không `SELF_APPROVAL_NOT_ALLOWED`; 041 "Người duyệt" "Chủ cửa hàng". Không đổi cách Hub gắn vai cho dòng "Chờ duyệt" (dùng chung với BJ-02 / 06 / 12) |
| `SC_bj09_reject` | `?uif=UIF-09&entry=approver` | "Từ chối" → lý do → "Xác nhận từ chối" → 041 cảnh báo |
| `SC_bj09_from_bj01` | `?uif=UIF-01&screen=SCR-001` | `INV-NOB` → lô DH2507 → "Đổi tình trạng" → "Cách ly" → số lượng 20 → (khối "Sau khi đổi" có "Đơn đang giữ: … cần phân bổ lại") |
| `SC_bj09_expired_to_disposal` | `?uif=UIF-01&screen=SCR-001` | `INV-TYLO` → "Xử lý lô hết hạn" → 037 Tylosin → "Đề nghị tiêu hủy" (dừng ở 040) |
| `SC_k5_hub_rtv` | `?mode=theme&app=inventory` | workspace "movement" → "Trả nhà cung cấp" (036 chip "Trả nhà cung cấp") → quay lại → workspace "control" → "Hàng cần xử lý" (chip "Tất cả") |

`T = '?mode=theme&app='` (đã có trong `golden.mjs`). `WEB_SCENARIOS` thêm `SC_k5_list`, `SC_bj09_quarantine_to_damaged`, `SC_bj09_approve`, `SC_bj09_from_bj01`, `SC_k5_hub_rtv`. Chỉ dùng `data-k5-*` / `data-bj09-*` / `data-theme-*`, không chọn theo chữ.

## 6. Bước D — kiểm

1. Golden mobile / web so mốc mục 2: chỉ ca ở 0.8 khác; ghi mục 9. Mọi trạng thái 0.5 cho ảnh khác nhau (`diff` thân `.txt` trước dòng `@inspector`; hash PNG), cả hai khung.
2. Bấm thử UIF-07 / 09 / 10 (036 chung) hai khung + Hub ("Hàng cần xử lý", "Trả nhà cung cấp", Home "Cần chú ý", "Chờ duyệt") + BJ-01 sheet lô: 0 lỗi JS; `node --check app/*.js harness/*.js tools/golden.mjs`.
3. **`/impeccable audit` phạm vi K5 + UIF-09 — chặn commit E.** Chạy trên 036 (READY, FILTER_EMPTY, EMPTY, từng chip), 037 (Hết hạn, Hỏng, Cách ly, Dùng thử, có việc đang chạy, LOCKED), 038 (READY trống, đủ ô, VALIDATION_ERROR, PENDING_APPROVAL, APPROVAL_REVIEW + sheet từ chối, SELF_APPROVAL_NOT_ALLOWED, STATE_CHANGE_BASIS_STALE), 041 (COMPLETED → Hỏng, COMPLETED → Dùng thử, EXPIRED, REJECTED_EXECUTION, UNKNOWN), Home "Cần chú ý", ở cả hai khung. Đạt khi: chữ ≥ 4,5:1 (badge, phụ đề dòng, dòng lý do ở chân, dòng giải thích trả NCC); vùng chạm ≥ 44 × 44 ở iPhone (chip cuộn ngang, "Cả {n} {ĐVT}", nút ảnh, `dsChoiceRow`); tình trạng không chỉ phân biệt bằng màu (có chữ trong badge); web đi được bằng bàn phím (Tab qua ô tìm → chip → bảng → nút chân; `dsChoiceRow` chọn bằng phím mũi tên / Space trong `role="radiogroup"`; Enter mở / Esc đóng sheet từ chối, focus về nút đã mở, Tab không thoát khỏi `aria-modal`); web không còn cột 402px; iPhone không bảng ép nhỏ, số và ĐVT không gãy dòng (nối bằng khoảng trắng không ngắt — bài học R2 chặng 3). Lỗi trong phạm vi: sửa ngay; ngoài phạm vi: ghi mục 9.
4. Gửi ảnh: 036 web + iPhone (Tất cả, Cần xử lý), 037 Hết hạn + Cách ly (iPhone), 037 web, 038 iPhone (đủ ô) + web, 038 duyệt web, 041 → Hỏng iPhone, Home "Cần chú ý" hai khung.
5. Mốc cho plan sau: `tools/.golden-bj09-after` / `tools/.golden-bj09-web-after`.

## 7. Bước E — ghi lại (commit 3)

1. `CHANGELOG.md` `[5.13.0] — BJ-09 thiết kế lại; K5 "Hàng cần xử lý"`; phiên bản 5.13.0 (`manifest.json`, `harness/workbench.js`, badge `index.html`, nhãn inspector UIF-09).
2. Viết lại theo `_TEMPLATE.md`: SCR-036 (K5 — một danh sách cho UIF-07 / 09 / 10, bỏ các đoạn `v1.x` / `v2.x` / `v3.x` override theo luồng; phần dòng yêu cầu trả ghi "chi tiết ở plan BJ-07"), SCR-037 (phần UIF-09 / 10; phần UIF-07 "Chuẩn bị hàng trả" giữ tới plan sau), SCR-038, SCR-041 (phần BJ-09), SCR-056 (lối vào / ra); UIF-09 (sơ đồ mới: danh sách chung, lối từ BJ-01, "Chờ duyệt", 041 → BJ-10).
3. T7-P mục 5: thêm bảng **K5 đã dựng** (hàm, tham số, nguồn `__T7_PROBLEM_SOURCES__`, quy tắc mở bước); mục 2 bảng "Vị trí trên Home Kho" (dòng "Cần chú ý": "Hàng cần xử lý" thay "lô sắp hết hạn"; "Quản lý kho → Tồn kho" bỏ 09); mục 9 BJ-09: khuôn "dựng K5; K1, K2, K3, K4, K6, K7".
4. `INDEX.md` 036, 037, 038, 041, 056; T7-P mục 13 (chữ mới, danh sách chung, Home, BJ-01 "Đổi tình trạng", phần BJ-09 của dòng "mọi BJ theo K2": UC-09-02 ghi người duyệt = `is_owner` / `store_owner`, chủ lập gửi rồi tự duyệt); mục 14: BJ-09 ✅.
5. `python3 tools/sync-registry.py`.

## 8. Thứ tự commit

1. C0 + C1 (fixture chung, K5, 036 / 037, lối vào Hub / Home / BJ-01) — golden khác ở 036 / 037 ba luồng, Home, Hub, BJ-01 sheet lô.
2. C2 + D (038, duyệt K2, 041, golden mới, sửa sau audit).
3. E (tài liệu, phiên bản, registry).

Như chặng 2 / 3: nếu làm một lượt thì để chưa commit cho phiên review xem trước, chia commit sau review. `detect_changes()` trước mỗi commit (CLAUDE.md).

## 9. Ghi chú khi làm

**Mốc.** `.golden-chang3` chụp lại ở HEAD (v5.12.2) lệch 2 ca nhiễu của mobile (`SC_bj15_sheet_2_nob`, `SC_bj15_sheet_4_glv`; web khớp hoàn toàn) → mốc làm việc = `tools/.golden-bj09-base` / `-web-base`. Sau làm: `tools/.golden-bj09-after` (mobile 1771 ca) / `-web-after` (881 ca), 0 lỗi JS. So mốc: chỉ ca ở 0.8 khác (036 / 037 / 038 / 041 / 056 ba luồng, `SC_bj07_list`, `SC_bj09_*`, `SC_attention_UIF-09`, `SC_entry_*`, `SC_bj01_expired*`, `SC_ws_inventory_*`, mọi ca có Home); ca BJ-07 từ 037 và BJ-10 từ 040 trở đi, `SC_bj17_from_bj07/10` **khớp**. `SC_bj07_verify` chỉ khác bước đầu (danh sách mới), `SC_bj10_flow` khác bước 1 (037 mới).

**GitNexus** (`impact` upstream, repo `erp-sales-inventory`): `render036BJ09`, `render036BJ07`, `render036BJ10`, `render037BJ10`, `renderHubHome`, `applyEntry` đều **LOW** (0–2 phụ thuộc trực tiếp; đồ thị gọi không thấy lời gọi qua sự kiện DOM nên rủi ro thật nằm ở golden — đã so). `detect_changes()` (cây làm việc, trước commit): 27 file, 135 ký hiệu, 0 luồng bị ảnh hưởng, rủi ro **low**.

**Lệch so với plan**

- Không dùng `k5ReturnTo` / `data-keep-back`: 036 và 037 cùng nằm trong `screens` của cả ba luồng nên nút quay lại mặc định (màn trước trong luồng) đã về 036; chỉ lối từ BJ-01 cần `bj09ReturnTo` (quay lại SCR-003, `onPrevious["UIF-09"]`).
- Ghi sổ **đồng bộ** (bỏ `queueSystemCommit` 180 ms): hết ca golden phụ thuộc thời gian; `PROCESSING` chỉ còn khi đặt từ ngoài.
- 037 "Việc tiếp theo" chỉ hiện khi có việc đang chạy hoặc lô không bán được (kèm dòng "Trả nhà cung cấp do Mua hàng lập…"); lô bán được từ BJ-01 không có khối này (khối chỉ có tiêu đề thì rỗng).
- `SC_bj09_from_bj01`: đổi sang "Cách ly" lô Nobivac DH2507 bằng "Cả 70 hộp" (không phải 20): lô 70 hộp, đang giữ 12 — chỉ đổi từ 59 hộp trở lên mới thấy "Đơn đang giữ: 12 hộp cần phân bổ lại".
- Khối "Sau khi đổi" bỏ dòng "Khả dụng bán" khi trước = sau (vd. Cách ly → Hỏng: "0 → 0") — chỉ còn "Tổng tồn và giá trị không đổi."
- `SC_bj09_owner_self`: lối vào Hub luôn đặt lại vai `module` nên kịch bản đặt vai chủ cửa hàng bằng `__VET45_QA__.setActor('owner')` sau khi vào luồng; dòng "Chờ duyệt" gắn vai `approver` như các BJ khác.
- `SC_bj09_quarantine_to_damaged`: sau khi gửi duyệt đi "Về hàng cần xử lý" → quay lại → Home (màn `PENDING_APPROVAL` không có nút quay lại); dòng "Chờ duyệt" lấy ca thứ hai (`ST-260915-01` đứng đầu).
- SCR-041 `PENDING_APPROVAL` (còn trong bộ chọn) dựng `k2Pending`; `STATE_CHANGE_BASIS_STALE` của 041 dựng được dù chưa có trong danh sách trạng thái của màn.
- Chưa gỡ `render036BJ10` / `render037BJ10` / `render036BJ07` (hàm không còn được đăng ký) — để plan BJ-07 + BJ-10. `.ic-action-stack` và `io-product-*` còn dùng ở BJ-10 nên giữ; `v364-radio-*` và `choice-list` của UIF-09 đã xoá. Nhóm luật CSS chung `UIF-08/09/10` (khung Figma 402px, `!important`) chưa gỡ: màn mới đều dùng `k7-wide` nên không bị ép cột (đã kiểm ảnh web), phần còn lại dọn khi BJ-10 xong.
- Fixture chung: 037 của lô `glove-nitrile` đang "Chờ tiêu hủy" mở 040 `COMPLETION` hiện có (còn ghi cứng "Amox 500 · L2407-A"); sửa ở plan BJ-07 + BJ-10.

**Kết quả D**

- Mọi trạng thái 0.5 dựng được, 0 lỗi JS; ảnh trong cùng một luồng khác nhau trừ SCR-056 `READY` / `LOCKED` / `CONFLICT` / `FINANCIAL_RESTRICTED` (giữ nội dung như plan; chỉ `LOADING` / `PERMISSION_DENIED` là K1). Ảnh giống nhau giữa UIF-09 và UIF-10 ở 036 / 037 là chủ ý (màn dùng chung).
- **Audit** (Chrome headless CDP, kịch bản tự viết ở scratchpad, 36 ca × hai khung): 036 (5 trạng thái + 4 chip), 037 (5 trạng thái + lô hết hạn + lô chờ duyệt), 038 (8 trạng thái + đủ ô + duyệt có sheet từ chối), 041 (7 trạng thái), Home "Cần chú ý" / "Chờ duyệt", 056: chữ ≥ 4,5:1, vùng chạm iPhone ≥ 44 × 44, không tràn ngang, không nút / ô thiếu tên, ảnh có `alt`, Esc đóng sheet: **0 lỗi**. Radiogroup "Đổi sang" thêm phím mũi tên. Chưa chạy lệnh `/impeccable audit` đầy đủ (kiểm tab / focus trả về nút đã mở bằng tay) — việc của phiên review.

## 10. Không làm

- Thiết kế lại 037 "Chuẩn bị hàng trả", 039, 041 của BJ-07 và 040, 041 của BJ-10 (plan [BJ-07 + BJ-10](T7-P-bj07-bj10-tra-ncc-tieu-huy.md)); ở plan này hai BJ chỉ đổi lối vào 036 / 037.
- Thiết kế lại SCR-056 (chặng 6, BJ-15).
- Tạo yêu cầu trả nhà cung cấp từ Kho (Theme 10 sở hữu — 0.10 f).
- Màn / dòng Home riêng cho lô cận hạn (0.10 c).
- Đổi BJ-02 / BJ-06 sang `k5Evidence` (0.6).
- Sửa fixture BJ-01 / BJ-06 cho khớp lô Amox (mục 3).

## 11. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| Một màn 036 cho ba luồng làm nút quay lại / Hub về nhầm luồng | Chip / tìm là trạng thái K5 (không theo luồng); `k5ReturnTo` + `data-keep-back`; kiểm `SC_k5_hub_rtv` và `SC_bj09_quarantine_to_damaged` ở chế độ Toàn Theme 7, cả hai khung |
| BJ-07 / BJ-10 chưa thiết kế lại nhưng 036 / 037 đã mới → ảnh trung gian lai | Plan này chỉ đổi lối vào của hai BJ; ca BJ-07 / 10 từ 037 / 040 trở đi **phải khớp** mốc (0.8); dòng tạm ở 4.1 điểm 2 thay ở plan sau |
| Đổi chủ cửa hàng được tự duyệt làm vỡ ca `SELF_APPROVAL_NOT_ALLOWED` | Giữ ca bằng actor nhân viên khác người gửi (`entry` mặc định); `SC_bj09_owner_self` kiểm nhánh chủ |
| Lô tách khi đổi một phần làm danh sách lệch giữa các lần chụp | `id` ổn định (4.2 điểm 7); `bj09Seed` dựng lại fixture khi trạng thái đặt từ ngoài |
| Home đọc số từ nhiều nguồn làm mọi ca Home khác | Chấp nhận (0.8); `diff` thân `.txt` chỉ khác dòng "Cần chú ý" / "Chờ duyệt" |

## 12. Chữ trên màn

| Vị trí | Chữ |
|---|---|
| 036 | "Hàng cần xử lý" · "Hàng không bán được và yêu cầu trả nhà cung cấp" · "Tìm sản phẩm, lô hoặc mã yêu cầu" · chip "Cần xử lý", "Trả nhà cung cấp", "Tiêu hủy", "Đang chờ" · "Lô {lô} · HSD {hsd} · {n} {ĐVT}" · "· Chờ duyệt đổi sang {tình trạng}" · "· Chờ tiêu hủy" · "{NCC} · {n} mặt hàng" · cột "Hàng", "Lô / yêu cầu", "HSD", "Số lượng", "Việc", "Tình trạng" · "Chưa xử lý" · "Trả {NCC}" · rỗng "Không có hàng cần xử lý" / "Hàng hết hạn, cách ly, hỏng và yêu cầu trả nhà cung cấp sẽ hiện ở đây." |
| 037 | "Lô {lô} · HSD {hsd}" · "{n} {ĐVT} {tình trạng} · Khả dụng bán {k}" · "Từ hàng khách trả {mã}" · "Từ nhận hàng {mã}" · "Việc tiếp theo" · "Đề nghị tiêu hủy" · "Xem yêu cầu" · "Trả nhà cung cấp do bộ phận Mua hàng lập yêu cầu. Khi có yêu cầu, hàng hiện ở mục Trả nhà cung cấp." |
| 038 | "Đổi tình trạng" · "Đổi sang" · "Cần chủ cửa hàng duyệt" · "Ghi nhận ngay" · "Số lượng" · "Ảnh bằng chứng" · "Sau khi đổi" · "Khả dụng bán: {a} → {b} {ĐVT}" · "Đơn đang giữ: {n} {ĐVT} cần phân bổ lại" · "Tổng tồn và giá trị không đổi." · "Gửi phê duyệt" · lý do "Chọn tình trạng mới", "Nhập số lượng", "Nhập lý do", "Thêm ảnh bằng chứng" · "Về hàng cần xử lý" · toast "Đã gửi chủ cửa hàng duyệt" |
| 038 duyệt | "Duyệt đổi {n} {ĐVT} {sản phẩm} lô {lô} từ {từ} sang {sang}?" · "Chỉ chủ cửa hàng duyệt đổi tình trạng." · Home "đổi tình trạng" · "{n} {ĐVT} · {từ} → {sang} · {người gửi} gửi {lúc}" |
| 041 | "Người duyệt" · "Không cần duyệt" · "Ghi nhận lúc" · K3 "Đổi tình trạng hàng" |
| Home / BJ-01 | "Hàng cần xử lý" · "{a} lô hết hạn · {b} cách ly / hỏng" · BJ-01 "Đổi tình trạng" |
| Không có quyền | "Bạn chưa có quyền xử lý hàng có vấn đề" · "Liên hệ chủ cửa hàng để được cấp quyền." |

## 13. Review

Review chung chặng 4 (2026-10-25): **đạt** sau R1–R3 (v5.15.1) — xem [plan BJ-07 + BJ-10 mục 14](T7-P-bj07-bj10-tra-ncc-tieu-huy.md#14-review). Phần của BJ-09 / K5: R1 (`k5Evidence`), R2 (038 "Sau khi đổi" / "Cần chú ý"), R3 b–c (036 phụ dòng lô, câu hỏi duyệt 038).
