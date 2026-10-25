# T7-P · BJ-16 Đối soát sai lệch + BJ-17 Kết quả chưa rõ — thiết kế lại (bước B–E) + `SC_journey_5`

> Theme: Theme 7 Inventory · Trạng thái: Brief ✅ (duyệt 2026-10-25 — mục 0.10, mọi điểm theo đề xuất) | Plan C–E ✅ (rà lại theo code BJ-11 khi làm) | Làm ✅ 2026-10-25 (v5.18.0, chưa commit) | Review ✅ (2026-10-25: đạt sau R1–R3, v5.18.1 — mục 14)
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) mục 8.2 **chặng 5 "Kiểm kê và sửa sai"**, BJ thứ ba và thứ tư (một plan như gói A10 — một bộ màn 078–083, hai luồng). Làm **sau** [BJ-11](T7-P-bj11-sua-sai.md) (hồ sơ "Cần sửa phiếu gốc" mở màn sửa sai của BJ-11 và nhận lại kết quả).
> Dùng lại K1, **K3** (BJ-17 là đích của mọi K3), K4, K6, K7. **Không K2** (đối soát / xác minh không có bước duyệt trong spec). Không khuôn mới.
> Thiết bị: **cả iPhone và web đều là thiết bị chính** (T7-P mục 2). Ở cửa hàng nhỏ người đối soát là **chủ cửa hàng** (hoặc nhân viên được giao); thường làm ở máy tính khi Home báo "Cần chú ý", có khi trên iPhone.
> Hết plan này = **hết chặng 5**: kịch bản `SC_journey_5` (mục 6.4) đi một mạch Home Kho → kiểm kê → chênh lệch → chủ duyệt → hồ sơ đối soát chỉ ra phiếu sai → sửa sai → chủ duyệt → đóng hồ sơ → cập nhật số trên app → xác minh kết quả chưa rõ → về Home.
> Ước lượng: **~2,75 ngày, 4 commit** (C1 danh sách chung + hồ sơ + BJ-16; C2 BJ-17 + K3; C3 `SC_journey_5` + D; E). Người làm: bạn. Review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị, chép nguyên văn; **(mới)** = chữ mới, vào T7-P mục 13 ở bước E.

## 0. Brief (bước B, đã duyệt 2026-10-25)

### 0.1 Việc thật

- **Ai, lúc nào:** **ít, vài lần / tháng**, khi Home Kho báo "Cần chú ý": số trên app lệch sổ kho, phiếu nhận lệch hoá đơn nhà cung cấp, báo cáo cuối ngày khác số tồn, hoặc một thao tác mất mạng giữa chừng nên app **chưa biết đã ghi hay chưa** (K3 của mọi BJ chuyển sang). Chủ cửa hàng xem, hiểu chuyện gì xảy ra, làm **một** việc đúng rồi đóng.
- **Cần biết / làm gì:** sai ở đâu, nói bằng lời thường ("Số trên app lệch 2 hộp so với sổ kho; sổ kho đúng"); hàng nào đang bị tạm khoá vì hồ sơ này; việc tiếp theo là gì (cập nhật số trên app / sửa phiếu gốc / chuyển Mua hàng / không cần làm gì / nhờ hỗ trợ); làm xong thì số đã khớp chưa; thao tác chưa rõ kết quả thì **đã ghi vào kho chưa** — đã ghi thì chỉ xác nhận, chưa ghi thì làm tiếp đúng thao tác đó, chưa biết thì giữ nguyên.
- **Quy tắc** (BJ-16, UC-16-01…04 BR-01…06; BJ-17, UC-17-01…04 BR-01…06): một phạm vi một hồ sơ, tín hiệu mới gắn vào hồ sơ đang mở (BR-01); phải phân biệt năm loại: phiếu nguồn lệch, kết quả chưa rõ, số trên app lệch, cần sửa phiếu, nghi sổ kho sai (BR-02); **chỉ cập nhật số trên app khi đã chứng minh sổ kho đúng** (BR-03); chỉ khoá phạm vi cần thiết, có người giữ và điều kiện mở (BR-04); chỉ đóng khi có bằng chứng và việc cần làm đã xong; bằng chứng mới thì mở lại (BR-05); nghi sổ kho sai thì **dừng mọi sửa tự động**, chuyển xử lý sâu, không dựng sổ từ báo cáo (BR-06); BJ-16 không tự sửa phiếu — chuyển BJ-11 hoặc nghiệp vụ nguồn. BJ-17: chưa rõ **không** phải thất bại (BR-01); chỉ tra / làm tiếp bằng đúng mã thao tác (BR-02); đã ghi → chỉ xác lập, không ghi lần hai (BR-03); chưa ghi và không có phần ghi dở → làm tiếp cùng mã (BR-04); chưa đủ bằng chứng → giữ chưa rõ, không đoán (BR-05); không tự hoàn tất đơn bán / phiếu mua của Theme khác (BR-06).

### 0.2 Luồng hiện tại

Ảnh: `tools/.golden-bj11-after/UIF-16_*`, `UIF-17_*`, `SC_bj16_*`, `SC_bj17_*`, `SC_attention_UIF-16_*`, `SC_attention_UIF-17_*`; web `tools/.golden-bj11-web-after/UIF-16_*@web`, `UIF-17_*@web`.

```text
Home "Cần chú ý": "Sai lệch cần đối soát" (số "1" cố định) → UIF-16 078 "Đối soát sai lệch" (5 hồ sơ; chip "Cần xử lý · Đang chờ · Ưu tiên cao")
                  "Nghiệp vụ chưa xác định kết quả" ("1" cố định) → UIF-17 078 "Nghiệp vụ cần xác minh" (3 hồ sơ; chip "Đã có tác động · Chưa có tác động · Cần chuyên sâu")
Hub Kiểm kê & xử lý → "Đối soát sai lệch" → UIF-16 078 · K3 của BJ-02 / 05 / 06 / 07 / 08 / 10 / 11 → UIF-17 079
079 "Bằng chứng & kết luận" (banner + "Nguồn nghiệp vụ / Sổ kho / Số liệu hiển thị" + "Bảo vệ phạm vi: Đang áp dụng")
  số liệu hiển thị lệch → "Khôi phục số liệu hiển thị" → 080 "Phương án xử lý" (nói lại điều 079 đã nói) → "Bắt đầu khôi phục" → 081 (thanh 68%) → "Rà soát kết quả" → 082 → "Đóng hồ sơ & mở khóa" → 083
  cần sửa nghiệp vụ → "Mở yêu cầu sửa sai" → BJ-11 (không đường về)
  không lệch thật → "Rà soát đóng hồ sơ" → 082 → 083 · sổ kho nghi sai → "Xem trạng thái chuyển xử lý" → 083 · nguồn lệch → "Chuyển cho nghiệp vụ nguồn" → 083
UIF-17 079 "Bằng chứng kết quả" → "Xem phương án xác lập / tiếp tục" → 080 → "Xác lập đã hoàn tất" / "Tiếp tục lần xử lý này" → 082 → "Hoàn tất xác minh" → 083
```

### 0.3 Vấn đề

| # | Màn | Vấn đề |
|---|---|---|
| 1 | Home / 078 | Hai dòng "Cần chú ý" mở hai danh sách khác nhau trên cùng SCR-078, số cố định ("1" trong khi có 5 / 3 hồ sơ); Hub chỉ có lối vào BJ-16; chip mỗi luồng một kiểu ("Ưu tiên cao", "Cần chuyên sâu", "Đã có tác động" — chữ kỹ thuật) |
| 2 | 078 | Dòng tiêu đề là mã hồ sơ / mã IO, phụ đề là câu kỹ thuật ("Số liệu hiển thị lệch sổ kho"); không theo K6 (chip không số, web không bảng) |
| 3 | 079 | Thuật ngữ kỹ thuật: "Số liệu hiển thị", "Nguồn nghiệp vụ", "Bảo vệ phạm vi: Đang áp dụng", "Người xử lý: Vận hành nền tảng / Nghiệp vụ nguồn", "Định danh nghiệp vụ: Giữ nguyên"; không nói **lệch bao nhiêu** bằng một câu; không nói hàng nào đang bị khoá và khoá tới khi nào |
| 4 | 080 | Màn trung gian chỉ nhắc lại kết luận + "Tác động: Không thay đổi" ba dòng (UIF-16) / "Không thực hiện: Không / Không / Không" (UIF-17) → một chạm thừa |
| 5 | 081 / 082 | Thanh tiến độ cố định 68%; 081 `READY` ("Đã khôi phục…") rồi lại 082 "Rà soát kết quả" — hai màn xác nhận liền nhau; nút "Đóng hồ sơ & mở khóa" (kỹ thuật) |
| 6 | 079 → BJ-11 | "Mở yêu cầu sửa sai" mở BJ-11 049 (phải bấm "Sửa sai" lần nữa); sửa xong không về hồ sơ, hồ sơ không bao giờ đóng được |
| 7 | 083 | `ioResult` canh giữa; `ESCALATED` cùng một câu cho ba trường hợp khác nhau (nghi sổ kho sai, chờ nghiệp vụ nguồn, chưa đủ bằng chứng); `UNKNOWN` = `ESCALATED` (giống hệt); `RESOLVED` trong danh sách trạng thái nhưng không có nhánh |
| 8 | UIF-17 | 082 "Rà soát kết quả" chỉ in lại "Lần xử lý: Không thay đổi / Nghiệp vụ mới: Không tạo" rồi mới "Hoàn tất xác minh"; ca từ K3 các BJ khác luôn tạo hồ sơ "Chưa đủ bằng chứng" (không thấy nhánh xác lập / làm tiếp từ nguồn thật) |
| 9 | Fixture | Sản phẩm lệch các chặng trước (Amox L2407-A, Vitamin C, "Găng tay M", "SP-00606" ở hồ sơ sổ kho); Nobivac DH2507 vừa ở hồ sơ "số trên app" vừa là phiếu sửa sai BJ-11 (đã tách ở fixture chung chặng 5) |
| 10 | Web | Cột iPhone 402px giữa khung |
| 11 | Mã | `bj16CaseListLegacy` (nhánh trùng của 078), `bj16EvidenceCard` / `crFactCard` / `ac310InfoSurface` ba kiểu khối cho cùng nội dung, `bj16Denied` / `bj16Loading` thay K1, `ac310SanitizeMarkup` lọc chữ kỹ thuật thay vì viết lại chữ gốc, `setTimeout` 250 ms ở 081; nhãn `data-v350-action="cr16-*" / "cr17-*"`, `data-v360-action="fallback-exit"` |

### 0.4 Đề xuất

**Luồng mới**

```text
Lối vào chung → 078 "Hồ sơ cần kiểm tra" (K6: chip có số "Tất cả · Sai lệch · Chưa rõ kết quả · Đang chờ")
  Home "Cần chú ý" → "Hồ sơ cần kiểm tra" "{a} sai lệch · {b} chưa rõ kết quả"   (chip "Tất cả")
  Hub Kiểm kê & xử lý → "Đối soát sai lệch"                                   (chip "Sai lệch")
  K3 của mọi BJ → "Chuyển sang xác minh" → 079 của hồ sơ chưa rõ (không qua danh sách)
078 ─dòng→ 079 "Bằng chứng & kết luận" (kết luận một câu + so sánh + "Đang tạm khoá …" + một việc tiếp theo)
  Số trên app lệch → "Cập nhật số trên app" → sheet → 081 đang cập nhật → 082 kiểm lại (khớp) → "Đóng hồ sơ" → 083
  Cần sửa phiếu gốc → "Sửa phiếu gốc" → BJ-11 050 → … → 053 → "Về hồ sơ đối soát" → 079 "Đã sửa phiếu gốc" → "Kiểm lại" → 082 → "Đóng hồ sơ" → 083
  Không lệch thật → "Đóng hồ sơ" → sheet → 083
  Nghi sổ kho sai → "Gửi bộ phận hỗ trợ" → 083 đã gửi · Phiếu nguồn lệch → "Chuyển cho Mua hàng" → 083 đã chuyển
  Chưa rõ, đã ghi → "Xác nhận đã hoàn tất" → sheet → 083 · chưa ghi → "Làm tiếp thao tác" → sheet → 083 · chưa đủ bằng chứng → "Gửi bộ phận hỗ trợ" → 083
SCR-080 bỏ (thay bằng sheet xác nhận ở 079)
```

*SCR-078 Hồ sơ cần kiểm tra* (K6 — vấn đề 1, 2)

1. **Một danh sách cho UIF-16 và UIF-17** (như K5 chặng 4): một hàm dựng `render078Recon`, đăng ký cho cả hai luồng; chip / ô tìm là trạng thái chung, không theo luồng. Tiêu đề **"Hồ sơ cần kiểm tra" (mới — tên màn trong INDEX; thay "Đối soát sai lệch" / "Nghiệp vụ cần xác minh")**; phụ **"Sai lệch số liệu và thao tác chưa rõ kết quả" (mới)**. Ô tìm **"Tìm hồ sơ, sản phẩm hoặc mã phiếu" (mới — gộp hai câu cũ)**.
2. Chip có số: "Tất cả" · **"Sai lệch" (mới)** (hồ sơ BJ-16 cần làm) · **"Chưa rõ kết quả" (mới)** (hồ sơ BJ-17 cần làm) · "Đang chờ" (giữ) (đã chuyển hỗ trợ / Mua hàng / chờ duyệt sửa sai). Bỏ "Cần xử lý", "Ưu tiên cao", "Đã có tác động", "Chưa có tác động", "Cần chuyên sâu".
3. Dòng iPhone: tiêu đề = **kết luận ngắn** (điểm 6 cột "Tiêu đề dòng"); phụ **"{phạm vi} · {mã hồ sơ}" (mới)**; badge **"Cần làm" (mới, warning)** / "Đang chờ" (giữ, neutral) / **"Nghi sổ kho sai" (mới, danger)**. Web (K7): bảng **"Hồ sơ"** · **"Loại"** ("Sai lệch" / "Chưa rõ kết quả") · "Phạm vi" · **"Mở lúc"** · "Tình trạng" (mới — đầu cột).
4. `rowAttr`: hồ sơ BJ-16 → `applyEntry("UIF-16", "case-context")`; BJ-17 → `applyEntry("UIF-17", "unknown-context")` — 079 của đúng hồ sơ; `crReturnTo = "SCR-078"`. Hồ sơ đã đóng không hiện.
5. `EMPTY` → `k1Empty` **"Không có hồ sơ cần kiểm tra" (mới)** / "Danh sách sẽ cập nhật khi có tín hiệu cần kiểm tra." (giữ); `FILTER_EMPTY` → `k1Empty` "Không có hồ sơ phù hợp" (giữ) / "Thử đổi bộ lọc hoặc từ khóa tìm kiếm." (giữ) + "Xem tất cả"; `LOADING` / `PERMISSION_DENIED` → K1 (`what:` **"Bạn chưa có quyền đối soát" (mới)**). Trạng thái `INVESTIGATING` / `ESCALATED` của 078 (spec) = danh sách có hồ sơ đang làm / đang chờ → bỏ khỏi bộ chọn, dùng `READY` (ghi CHANGELOG).
6. **Home "Cần chú ý"**: thay hai dòng "Sai lệch cần đối soát" / "Nghiệp vụ chưa xác định kết quả" bằng **một dòng "Hồ sơ cần kiểm tra" + "{a} sai lệch · {b} chưa rõ kết quả" (mới)** (số = dòng "Cần làm"; vế bằng 0 thì bỏ vế; cả hai bằng 0 thì không hiện); mở 078 chip "Tất cả". Hub: "Đối soát sai lệch" (giữ chữ) mở 078 chip "Sai lệch".

*SCR-079 Bằng chứng & kết luận* (vấn đề 3, 4, 6)

7. Tiêu đề "Bằng chứng & kết luận" (giữ; UIF-17 "Bằng chứng kết quả" (giữ)); phụ "{mã hồ sơ} · {phạm vi}".
8. Khối **"Kết luận" (mới)** — một câu theo loại, rồi khối **"So sánh" (mới)** (bảng ba dòng, dòng lệch nổi bật bằng chữ "lệch {±d} {ĐVT}" + tone warning) và nút chính:

   | Loại (trạng thái) | Tiêu đề dòng 078 | Câu kết luận (mới) | So sánh (mới) | Chính |
   |---|---|---|---|---|
   | Số trên app lệch (`PROJECTION_MISMATCH`) | "Số trên app lệch sổ kho" | "Số trên app lệch {d} {ĐVT} so với sổ kho. Sổ kho đúng; chỉ cần cập nhật số trên app." | "Phiếu gốc" · "Sổ kho" · "Số trên app" | **"Cập nhật số trên app"** (thay "Khôi phục số liệu hiển thị") |
   | Cần sửa phiếu (`CORRECTION_REQUIRED`) | "Phiếu nhận ghi khác hoá đơn" | "Phiếu {mã} ghi {a} {ĐVT}, hoá đơn chỉ {b} {ĐVT}. Cần sửa phiếu gốc; không sửa thẳng số tồn." | "Phiếu gốc" · "Hoá đơn nhà cung cấp" · "Sổ kho" | **"Sửa phiếu gốc"** (thay "Mở yêu cầu sửa sai") → BJ-11 `correction-from-case` |
   | … đã sửa (cờ `correctionDone`) | "Đã sửa phiếu gốc · chờ kiểm lại" | "Phiếu sửa sai {mã} đã ghi. Kiểm lại số rồi đóng hồ sơ." | như trên + "Phiếu sửa sai" | **"Kiểm lại"** → 082 |
   | … sửa sai chờ duyệt | (dòng ở chip "Đang chờ") | `k2Pending` "Chờ chủ cửa hàng duyệt sửa sai · gửi {lúc}" | như trên | "Xem yêu cầu" → BJ-11 053 |
   | Không lệch thật (`NO_REAL_DIFFERENCE`) | "Báo cáo khác số tồn" | "Không có lệch thật. Báo cáo lấy số lúc {giờ}, trước khi {nghiệp vụ} ghi vào kho." | "Báo cáo lúc {giờ}" · "Sổ kho" · "Số trên app" | **"Đóng hồ sơ"** → sheet |
   | Nghi sổ kho sai (`LEDGER_INTEGRITY_RISK`) | "Sổ kho có dấu hiệu sai" | "Sổ kho có dấu hiệu sai. App dừng mọi cập nhật tự động cho phạm vi này; cần bộ phận hỗ trợ kiểm tra." | "Phiếu gốc" · "Sổ kho" (không nhất quán) | **"Gửi bộ phận hỗ trợ"** → 083 |
   | Phiếu nguồn lệch (`SOURCE_MISMATCH`) | "Phiếu mua chưa khớp kho" | "Phiếu {mã} chưa khớp dữ liệu kho. Mua hàng cần kiểm lại phiếu; Kho không tự sửa." | "Phiếu mua" · "Sổ kho" | **"Chuyển cho Mua hàng"** (thay "Chuyển cho nghiệp vụ nguồn") → 083 |
   | Chưa đủ bằng chứng (BJ-16 `INSUFFICIENT_EVIDENCE`) | "Chưa rõ nguyên nhân" | "Chưa đủ bằng chứng kết luận" (giữ) + "Giữ hồ sơ mở cho tới khi xác định được nguyên nhân." (giữ) | các dòng đã có | — (chỉ "Quay lại") |
   | Chưa rõ, đã ghi (BJ-17 `UNKNOWN_EVIDENCE` + đã ghi) | "{nghiệp vụ} đã ghi vào kho" | "Thao tác đã ghi vào kho. Chỉ cần xác nhận kết quả; không ghi lại lần hai." | "Yêu cầu" · "Ghi vào kho" · "{nghiệp vụ nguồn}" | **"Xác nhận đã hoàn tất"** (thay "Xem phương án xác lập" / "Xác lập đã hoàn tất") → sheet |
   | Chưa rõ, chưa ghi (BJ-17 `UNKNOWN_EVIDENCE` + chưa ghi) | "{nghiệp vụ} chưa ghi vào kho" | "Thao tác chưa ghi vào kho và không có phần ghi dở. Có thể làm tiếp đúng thao tác này." | như trên | **"Làm tiếp thao tác"** (thay "Xem phương án tiếp tục" / "Tiếp tục lần xử lý này") → sheet |
   | Chưa rõ, chưa đủ bằng chứng (BJ-17 `INSUFFICIENT_EVIDENCE`) | "Chưa biết đã ghi hay chưa" | "Chưa biết thao tác đã ghi vào kho hay chưa. Giữ nguyên, không làm lại; cần bộ phận hỗ trợ kiểm tra." | như trên | **"Gửi bộ phận hỗ trợ"** → 083 |

   Chữ so sánh mới thay chữ cũ: "Số trên app" (thay "Số liệu hiển thị"), "Phiếu gốc" (thay "Nguồn nghiệp vụ"), "Ghi vào kho" (thay "Tác động tồn kho"); giá trị "Đã có" / "Chưa có" / "Chưa rõ" (mới — thay "Đã tìm thấy đúng phạm vi" / "Chưa phát hiện" / "Chưa đủ bằng chứng").
9. Dòng **"Đang tạm khoá {phạm vi}: chưa nhận, xuất hay bán được cho tới khi đóng hồ sơ." (mới)** (khi phạm vi được khoá; thay hàng "Bảo vệ phạm vi: Đang áp dụng"); không khoá thì không hiện. Bỏ hàng "Người xử lý" (cửa hàng một người làm; người nhận khi chuyển hiện ở 083), "Định danh nghiệp vụ / Lần xử lý: Giữ nguyên". BJ-17 thêm một dòng cố định **"Không tạo thao tác mới, không ghi lại lần hai." (mới)**.
10. **SCR-080 bỏ** (080 → RETIRED, "Bỏ từ v5.18.0"): sheet xác nhận ở 079 thay "Phương án xử lý":
    - "Cập nhật số trên app" → **"Cập nhật số trên app theo sổ kho?" (mới)** / **"Sổ kho và phiếu gốc không đổi. {phạm vi} vẫn tạm khoá tới khi đóng hồ sơ." (mới)** / "Quay lại" | **"Cập nhật" (mới)** → 081.
    - "Đóng hồ sơ" (không lệch thật) → **"Đóng hồ sơ?" (mới)** / **"Không có lệch thật; không cần sửa gì." (mới)** / "Quay lại" | "Đóng hồ sơ" → 083.
    - "Xác nhận đã hoàn tất" → **"Xác nhận {nghiệp vụ} {mã} đã hoàn tất?" (mới)** / "Dùng tác động đã tồn tại để xác lập kết quả; không ghi lại biến động lần hai." (giữ) → 083.
    - "Làm tiếp thao tác" → **"Làm tiếp {nghiệp vụ} {mã}?" (mới)** / "Tiếp tục cùng định danh sau khi đã xác nhận chưa có tác động bán phần." → **"Dùng đúng thao tác cũ, không tạo thao tác mới." (mới — thay câu kỹ thuật)** → 083.
    Bằng chứng đổi giữa lúc mở sheet và lúc bấm (`evidenceVersion`) → đóng sheet, 079 `k1Stale({ title:"Kết luận đã thay đổi" (giữ — chữ 080 CONFLICT), description:"Bằng chứng mới làm thay đổi phương án. Quay lại bước bằng chứng để rà soát." → **"Có bằng chứng mới. Xem lại kết luận trước khi làm tiếp." (mới)**, actionLabel:"Tải lại" })`. Phạm vi do hồ sơ khác giữ (080 `LOCKED`) → 079 `k1Locked({ title:"Phạm vi đang do hồ sơ khác bảo vệ" → **"Phạm vi đang thuộc hồ sơ khác" (mới)**, description:**"{mã hồ sơ} đang kiểm {phạm vi}. Mở hồ sơ đó để làm tiếp." (mới)** })` + **"Mở hồ sơ đó" (mới)**.
11. `LOADING` / `PERMISSION_DENIED` → K1. Web: `k7Split` — trái kết luận + so sánh + dòng khoá; phải khối **"Hồ sơ" (giữ)**: Mã · **"Nguồn tín hiệu" (mới)** ("Kiểm soát tự động", "Báo cáo cuối ngày", "Hoá đơn nhà cung cấp", "{BJ nguồn} — chưa rõ kết quả") · **"Mở lúc" (mới)**.

*SCR-081 Đang cập nhật số trên app* (vấn đề 5)

12. Tiêu đề **"Đang cập nhật số trên app" (mới — thay "Đang khôi phục số liệu")**; `k1Loading` + dòng "Bạn có thể rời màn hình; hồ sơ tự cập nhật khi hoàn tất." (giữ); bỏ thanh 68% cố định. Xong → **tự sang 082** (bỏ 081 `READY` "Đã khôi phục số liệu hiển thị" — 082 là màn kiểm lại). `VALIDATION_FAILED` / `CONFLICT` → `k1Stale({ title:"Chưa thể hoàn tất khôi phục" → **"Chưa cập nhật được số trên app" (mới)**, description:"Bằng chứng hoặc phạm vi đã thay đổi. Hồ sơ vẫn được giữ mở và sổ kho không bị sửa." (giữ), actionLabel:**"Về hồ sơ" (mới)** })`. Prototype: chuyển 081 → 082 bằng nút QA / hẹn giờ có tên trong `__VET45_QA__` (golden chờ có điều kiện, không `wait(400)` mù).

*SCR-082 Rà soát kết quả* (chỉ UIF-16 — vấn đề 5)

13. Tiêu đề "Rà soát kết quả" (giữ); khối `vBanner` success "Số liệu đã khớp" (giữ) + **"Số trên app khớp sổ kho." (mới — thay "Số liệu hiển thị hiện khớp với sổ kho.")** / sau sửa phiếu: **"Sổ kho đã theo phiếu sửa sai." (mới)**; bảng "Sổ kho" · "Số trên app" · "Chênh lệch" "0 {ĐVT}" (giữ). Chân **"Đóng hồ sơ" (mới — thay "Đóng hồ sơ & mở khóa")** + dòng trên nút **"Đóng xong, {phạm vi} mở khoá." (mới)** (`k4ReasonFooter` dòng mô tả).
14. `MISMATCH_REMAINS` → `vBanner` "Sai lệch vẫn còn" (giữ) + "Giữ hồ sơ mở và phạm vi được bảo vệ. Quay lại bằng chứng để tiếp tục điều tra." → **"Hồ sơ vẫn mở, {phạm vi} vẫn tạm khoá. Quay lại bằng chứng để xem tiếp." (mới)**; bảng có "Chênh lệch" "−1 hộp"; chân "Quay lại bằng chứng" (giữ). `PERMISSION_DENIED` → K1.
15. UIF-17 **không dùng 082** (sheet ở 079 → 083 thẳng; vấn đề 8) — bỏ 082 khỏi danh sách màn UIF-17 (ghi CHANGELOG).

*SCR-083 Kết quả xử lý* (K4 — vấn đề 7)

16. `COMPLETED` (BJ-16) → `k4Result({ screenTitle:"Kết quả đối soát" (giữ), title:"Đã xử lý sai lệch" (giữ), description:"Hồ sơ được đóng bằng bằng chứng và phạm vi liên quan đã được mở khóa." (giữ) })`; `facts`: "Hồ sơ" · "Kết luận" (giữ; giá trị = tiêu đề dòng 078) · **"Đã làm" (mới)** ("Cập nhật số trên app" / "Sửa phiếu {mã} · {mã phiếu sửa sai}" / "Không cần làm gì") · "Phạm vi" "Đã mở khóa" (giữ) · **"Đóng lúc" (mới)**. Bước tiếp: phụ "Về Kho" | chính **"Về hồ sơ cần kiểm tra" (mới — thay "Về danh sách đối soát")** (còn hồ sơ "Cần làm"); không còn thì một nút "Về Kho".
17. `ESCALATED` theo loại (thay một câu chung): nghi sổ kho sai / chưa đủ bằng chứng → K4 warning **"Đã gửi bộ phận hỗ trợ" (mới)** + "Hồ sơ vẫn mở; phạm vi rủi ro tiếp tục được bảo vệ cho tới khi có bằng chứng mới." (giữ) + `facts` "Hồ sơ" · **"Người nhận" (mới)** "Bộ phận hỗ trợ" · "Phạm vi" "Chưa mở khóa" (giữ) · **"Gửi lúc" (mới)**; phiếu nguồn lệch → **"Đã chuyển cho Mua hàng" (mới)** + **"Hồ sơ chờ Mua hàng kiểm lại phiếu {mã}; Kho không tự sửa." (mới)** + "Người nhận" "Mua hàng". BJ-17 chưa đủ bằng chứng → "Chưa xác định — đã chuyển xử lý" (giữ) + câu (giữ). `UNKNOWN` (gửi chuyển xử lý mà chưa rõ kết quả) → `k3Unknown({ operation:**"Chuyển hồ sơ" (mới)**, … })` — không còn trùng `ESCALATED`. `RESOLVED` → dựng như `COMPLETED` (bỏ khỏi bộ chọn, ghi CHANGELOG).
18. `COMPLETED` (BJ-17) → K4 "Đã xác lập kết quả nghiệp vụ" (giữ) + "Kết quả chính thức đã được ghi cho đúng nghiệp vụ; không tạo nghiệp vụ mới hoặc ghi tác động trùng." (giữ) + `facts` "Nghiệp vụ" (giữ) · **"Kết quả" (giữ)** "Đã hoàn tất" / **"Đã làm tiếp, đã ghi" (mới)** · **"Từ" (mới)** "{BJ nguồn}" (khi đến từ K3). Bước tiếp như điểm 16. `PROCESSING` → `k1Loading`; `PERMISSION_DENIED` → K1 + "Về Kho".

*K3 của các BJ khác* (vấn đề 8)

19. `bj17HandoffUnknown` giữ (nhận `sourceFlow`, `operation`, `scope`); ca tạo mới lấy `evidence` từ bảng `bj17SourceEvidence[sourceFlow]` nếu có (mục 3), mặc định "INSUFFICIENT" như hiện tại — để `SC_bj17_from_bj05` thấy nhánh "chưa ghi → làm tiếp". `onUnknownHandoff` của BJ nguồn giữ (khoá thao tác nguồn). Không đổi chữ K3 của BJ nguồn.

### 0.5 Trạng thái (sau thiết kế lại)

| Màn | Trạng thái | Hiện gì | Làm được gì | Lối ra |
|---|---|---|---|---|
| 078 | READY | K6: chip có số, danh sách / bảng | lọc, tìm, mở hồ sơ (đúng luồng) | Về Kho |
| 078 | EMPTY / FILTER_EMPTY | `k1Empty` | "Xem tất cả" (FILTER_EMPTY) | Về Kho |
| 078…083 | LOADING / PERMISSION_DENIED | K1 | — | "Về Kho" |
| 079 | PROJECTION_MISMATCH | kết luận, so sánh, dòng khoá | "Cập nhật số trên app" → sheet | Quay lại |
| 079 | CORRECTION_REQUIRED (chưa sửa / chờ duyệt / đã sửa) | kết luận, so sánh; `k2Pending` khi chờ duyệt | "Sửa phiếu gốc" / "Xem yêu cầu" / "Kiểm lại" | Quay lại |
| 079 | NO_REAL_DIFFERENCE | kết luận, so sánh | "Đóng hồ sơ" → sheet | Quay lại |
| 079 | LEDGER_INTEGRITY_RISK | kết luận, so sánh, dòng khoá | "Gửi bộ phận hỗ trợ" | Quay lại |
| 079 | SOURCE_MISMATCH | kết luận, so sánh | "Chuyển cho Mua hàng" | Quay lại |
| 079 | INSUFFICIENT_EVIDENCE (BJ-16) | banner | — | Quay lại |
| 079 | UNKNOWN_EVIDENCE (đã ghi / chưa ghi) | kết luận, so sánh, "Không tạo thao tác mới…" | "Xác nhận đã hoàn tất" / "Làm tiếp thao tác" → sheet | Quay lại |
| 079 | INSUFFICIENT_EVIDENCE (BJ-17) | kết luận | "Gửi bộ phận hỗ trợ" | Quay lại |
| 079 | (bằng chứng đổi / phạm vi thuộc hồ sơ khác) | `k1Stale` / `k1Locked` | "Tải lại" / "Mở hồ sơ đó" | Quay lại |
| 081 | REBUILDING | `k1Loading` + dòng chữ | — (tự sang 082) | Về Kho |
| 081 | VALIDATION_FAILED / CONFLICT | `k1Stale` | "Về hồ sơ" | — |
| 082 | READY | số đã khớp | "Đóng hồ sơ" | Quay lại |
| 082 | MISMATCH_REMAINS | banner + bảng còn lệch | "Quay lại bằng chứng" | — |
| 083 | COMPLETED (BJ-16 / BJ-17) | K4 | "Về hồ sơ cần kiểm tra" | "Về Kho" |
| 083 | ESCALATED | K4 cảnh báo theo loại | "Về hồ sơ cần kiểm tra" | "Về Kho" |
| 083 | UNKNOWN | K3 | "Chuyển sang xác minh" | "Về Kho" |
| 083 | PROCESSING | `k1Loading` | — | — |

### 0.6 Khuôn dùng lại

- K1, K3 (`k3Unknown`; BJ-17 là đích), K4 (`k4Result`, `k4Footer`, `k4ReasonFooter`), K6 (`k6TaskList`), K7 (`k7Split`, `k7Table`), `k2Pending` (chỉ để hiện "chờ duyệt sửa sai" của BJ-11 — không thêm nguồn K2), `k2Attention` cho khối "Kết luận".
- Mẫu "một danh sách cho nhiều luồng" chép cách K5 làm (chip / tìm là trạng thái chung, `applyEntry` mở đúng luồng) — **không** dựng khuôn mới; nếu K5 có helper tổng quát (`k5Open`) thì gọi lại, không có thì viết `crOpen` trong `bj16.js`.
- Không thành phần DS mới.

### 0.7 Không đổi

Quy tắc ở 0.1; `evidenceVersion` / `planEvidenceVersion` / `recoveryEvidenceVersion` và kiểm khớp trước khi làm (đổi chỗ kiểm từ 080 sang lúc bấm trong sheet); `resolutionRecord` của BJ-17 (không tạo thao tác mới, không ghi trùng); `bj17RecoveryCase`, `bj17HandoffUnknown`, `onUnknownHandoff`; `__VET45_QA__.bumpCR16Evidence` / `bumpCR17Evidence` / `getBJ17`. Chữ giữ: "Bằng chứng & kết luận", "Bằng chứng kết quả", "Không có hồ sơ phù hợp" + câu, "Danh sách sẽ cập nhật khi có tín hiệu cần kiểm tra.", "Đang chờ", "Sổ kho", "Chưa đủ bằng chứng kết luận" + câu, "Kết luận đã thay đổi", "Hồ sơ", "Dùng tác động đã tồn tại để xác lập kết quả; không ghi lại biến động lần hai.", "Bạn có thể rời màn hình; hồ sơ tự cập nhật khi hoàn tất.", "Bằng chứng hoặc phạm vi đã thay đổi. Hồ sơ vẫn được giữ mở và sổ kho không bị sửa.", "Rà soát kết quả", "Số liệu đã khớp", "Chênh lệch", "Sai lệch vẫn còn", "Quay lại bằng chứng", "Kết quả đối soát", "Đã xử lý sai lệch" + câu, "Kết luận", "Phạm vi", "Đã mở khóa", "Chưa mở khóa", "Hồ sơ vẫn mở; phạm vi rủi ro tiếp tục được bảo vệ cho tới khi có bằng chứng mới.", "Chưa xác định — đã chuyển xử lý" + câu, "Đã xác lập kết quả nghiệp vụ" + câu, "Nghiệp vụ", "Kết quả", "Đã hoàn tất", "Đối soát sai lệch" (Hub).

### 0.8 Kiểm (bước D)

- Golden **mobile** được khác: `UIF-16_*`, `UIF-17_*` (SCR-080 bỏ — ca `UIF-1[67]_SCR-080_*` xoá; 082 bỏ khỏi UIF-17), `SC_bj16_*`, `SC_bj17_*` (gồm `SC_bj17_from_bj0[2-8]`, `_from_bj10`, `_from_bj11` — bước 0 ở BJ nguồn **phải khớp**, bước 079 trở đi khác), `SC_attention_UIF-16_*` / `SC_attention_UIF-17_*` (một dòng Home mới), `SC_ws_control_*`, `SC_bj11_from_case` (bước "Về hồ sơ đối soát" trở đi), **mọi ca có Home Kho** (dòng "Cần chú ý" đổi), `SC_journey_5`. Ca khác khớp mốc `tools/.golden-bj11-after`.
- Golden **web** được khác: như trên với `@web`; ca khác khớp `tools/.golden-bj11-web-after`.
- Kịch bản (mục 6): sửa `SC_bj16_list`, `SC_bj16_recovery`, `SC_bj16_conflict`, `SC_bj16_mismatch`, `SC_bj16_correction`, `SC_bj16_no_real`, `SC_bj16_ledger`, `SC_bj16_source`, `SC_bj16_back`, `SC_bj16_context`, `SC_bj16_denied`, `SC_bj17_list`, `SC_bj17_committed`, `SC_bj17_continue`, `SC_bj17_insufficient`, `SC_bj17_plan_conflict`, `SC_bj17_finish_conflict` (→ đổi tên `SC_bj17_sheet_conflict`, bỏ bước 082), `SC_bj17_context`, `SC_bj17_denied`, `SC_bj17_from_bj05`; thêm `SC_recon_list`, `SC_recon_home`, `SC_bj16_locked`, `SC_bj16_correction_return`, `SC_journey_5`.

### 0.9 Ước lượng C–E

~2,75 ngày: C1 078 chung + 079 BJ-16 (bảy loại) + sheet + 081 / 082 / 083 + Home ~1,25; C2 079 / 083 BJ-17 + K3 nguồn + bỏ 080 ~0,5; C3 `SC_journey_5` + D ~0,75; E ~0,25. (T7-P mục 8.2 ghi 2 khi còn chia thiết bị chính / phụ; thêm danh sách chung, lối về từ BJ-11 và kịch bản hết chặng.)

### 0.10 Đã chốt khi duyệt brief (2026-10-25): **mọi điểm theo cột "Đề xuất"**

| # | Điểm | Đề xuất | Phương án khác |
|---|---|---|---|
| a | Danh sách của BJ-16 và BJ-17 | **Một danh sách "Hồ sơ cần kiểm tra"**, chip "Sai lệch · Chưa rõ kết quả · Đang chờ" (cùng cách chặng 4 gộp 036) | Giữ hai danh sách trên cùng SCR-078 như hiện tại |
| b | Home "Cần chú ý" | **Một dòng** "Hồ sơ cần kiểm tra" "{a} sai lệch · {b} chưa rõ kết quả", số đọc từ dữ liệu | Giữ hai dòng, chỉ sửa số cố định |
| c | SCR-080 Phương án xử lý | **Bỏ**, thay bằng sheet xác nhận ở 079 (080 → RETIRED) | Giữ 080, viết lại chữ |
| d | 082 cho BJ-17 | **Bỏ** (sheet ở 079 → 083 thẳng); BJ-16 giữ 082 để kiểm lại số trước khi đóng | Giữ 082 cho cả hai |
| e | Nơi nhận khi nghi sổ kho sai / chưa đủ bằng chứng | **"Bộ phận hỗ trợ"** (ngoài app; không có vai Platform Admin — PLAN 3-E) | "Chủ cửa hàng tự liên hệ hỗ trợ" (chỉ ghi hồ sơ "Đang chờ", không có người nhận) |
| f | Nơi nhận khi phiếu nguồn lệch | **"Mua hàng"** (phiếu nhận / phiếu mua là của Mua hàng — Theme 10) | Giữ "Nghiệp vụ nguồn" (chung cho mọi Theme) |
| g | Hồ sơ "Cần sửa phiếu gốc" sau khi BJ-11 xong | **Về 079 "Đã sửa phiếu gốc" → "Kiểm lại" → 082 → "Đóng hồ sơ"** (UC-16-04: kiểm bằng chứng rồi mới đóng) | Tự đóng hồ sơ khi BJ-11 ghi xong |

---

## 1. Mục tiêu

1. Một danh sách hồ sơ, một dòng Home có số thật; mở hồ sơ nào cũng đúng luồng.
2. Mỗi hồ sơ nói bằng lời thường: lệch gì, bao nhiêu, hàng nào đang khoá, **một** việc tiếp theo.
3. Ít chạm: bỏ 080, bỏ 082 ở BJ-17, 081 tự sang 082.
4. Sửa phiếu gốc đi BJ-11 và quay về đúng hồ sơ để kiểm lại, đóng.
5. Hết chặng 5: `SC_journey_5` 0 lỗi ở cả hai khung; lối vào chặng 5 trên Home Kho nối xong.

## 2. Chuẩn bị

1. BJ-11 đã làm (plan BJ-11 mục 14). Rà lại plan này theo code BJ-11: `entry=correction-from-case`, `cr11ReturnCase`, cờ `correctionDone`, chữ "Về hồ sơ đối soát"; và theo code K5 chặng 4 (`k5Open` / chip là trạng thái chung) — ghi lệch vào mục 9.
2. Mốc = `tools/.golden-bj11-after` / `tools/.golden-bj11-web-after`; lệch so HEAD → chụp `tools/.golden-bj16-base` / `-web-base`.
3. GitNexus: `impact` hướng upstream cho `render078Shared`, `render079BJ16`, `render080BJ16`, `render081BJ16`, `render082BJ16`, `render083BJ16`, `render079BJ17`, `render080BJ17`, `render082BJ17`, `render083BJ17`, `bj17HandoffUnknown`, `bj17RecoveryCase`, `renderHubHome`, `crSwitchFlow`; báo mức rủi ro vào mục 9 (`bj17HandoffUnknown` được mọi K3 gọi — dự kiến HIGH, báo người dùng trước khi sửa).
4. Máy chủ `python3 -m http.server 8765 --bind 127.0.0.1 &` trong `html/`.

## 3. Fixture (`app/bj16.js`, `app/bj17.js`)

Theo bảng phân vai sản phẩm chặng 5 ([BJ-08 mục 3](T7-P-bj08-kiem-ke.md)). Mỗi hồ sơ thêm `conclusion` (tiêu đề dòng), `compare: [[nhãn, giá trị, lệch?]]`, `locked` (phạm vi khoá hay không), `signal` (nguồn tín hiệu), `openedAt`, `status` `OPEN | WAITING | CLOSED`.

| Hồ sơ | Hiện tại | Sau |
|---|---|---|
| REC-260907-03 · PROJECTION | Nobivac DH2507 · 118 / 118 / 116 | giữ sản phẩm (**Nobivac DHPPi · SP-000184 · DH2507**): Sổ kho 70 · Số trên app 68 hộp (lệch −2) — *sửa ở review R2, bản đầu ghi 118 / 116 theo fixture BJ-15 cũ*; khoá; "Kiểm soát tự động"; mở "16/09/2026 06:00" — câu chuyện `SC_journey_5` |
| REC-260907-04 · CORRECTION | Amox 500 · L2407-A · IO-260904-021 | **Amox 500 · SP-000066**: Phiếu gốc PN-260904-08 20 hộp · Hoá đơn NCC 18 hộp · Sổ kho 46 hộp (tồn Amox, khớp BJ-08 / BJ-11; sau sửa 44 — *review R2*); khoá; "Hoá đơn nhà cung cấp"; `correctionOperationId: "IO-260904-021"`, `invoiceQty: 18` (BJ-11 điền sẵn số đúng) — câu chuyện `SC_journey_5` |
| REC-260907-05 · NO_REAL | Găng tay M | **Găng tay khám Nitrile · SP-000271**: Báo cáo lúc 07:00 8 hộp · Sổ kho 10 · Số trên app 10 (nhận hàng PN-260916-03 ghi lúc 07:20); không khoá; "Báo cáo cuối ngày" |
| REC-260907-06 · LEDGER | Kho trung tâm · SP-00606 | **Dầu sát khuẩn · SP-00606 · L2406-T**: Phiếu gốc "Có chứng từ" · Sổ kho "Không nhất quán"; khoá; "Kiểm soát tự động" |
| REC-260907-07 · SOURCE | PN-260906-12 | giữ PN-260906-12 (**Tylosin 20% · TY2511**); không khoá; "Mua hàng" |
| **REC-260907-08 (mới)** · LOCKED | — | hồ sơ phạm vi Amox 500 trùng REC-260907-04 (mở sau) → 079 `k1Locked` "Phạm vi đang thuộc hồ sơ khác" — chỉ dùng cho `SC_bj16_locked` (không hiện ở danh sách: `status: "LINKED"`) |
| REC-UNKNOWN-01 · COMMITTED | IO-260906-031 · Vitamin C · L2310-C · 5 hộp | **Tiêu hủy TH-260906-02 · Găng tay khám Nitrile · 5 hộp** (khớp BJ-11 IO-260906-031); "Tiêu hủy — chưa rõ kết quả" |
| REC-UNKNOWN-02 · NO_COMMIT | IO-260906-044 · Amox 500 · L2407-A · 2 hộp | **Bàn giao hàng {mã đơn BJ-05} · Nobivac DHPPi · 2 hộp** (mã đơn lấy từ fixture BJ-05); "Bàn giao — chưa rõ kết quả" |
| REC-UNKNOWN-03 · INSUFFICIENT | IO-260906-052 · Kho trung tâm | **Nhận hàng PN-260906-15 · 1 phiếu**; "Nhận hàng — chưa rõ kết quả" |

- `bj17SourceEvidence` (mới): `{ "UIF-05": "NO_COMMIT" }` (ca K3 từ BJ-05 cho thấy nhánh "làm tiếp"); các luồng khác mặc định "INSUFFICIENT".
- Thời điểm cố định: đóng hồ sơ "17/09/2026 21:00", gửi hỗ trợ "17/09/2026 21:05", xác lập BJ-17 "17/09/2026 21:10".
- `bj16Seed(screen, state)` / `bj17Seed` như các BJ trước: trạng thái đặt từ ngoài dựng lại `cr16Cases` / `cr17Cases` gốc (gồm `correctionDone = false`).

## 4. Bước C1 — danh sách chung, hồ sơ BJ-16, Home (commit 1)

### 4.1 Dữ liệu và sự kiện

1. `render078Recon(state)` trong `bj16.js` (thay `render078Shared`, `bj16CaseRows`, `bj16CaseListLegacy`): gộp `cr16Cases` + `cr17Cases` thành dòng `{ key, kind:"DIFF" | "UNKNOWN", conclusion, scope, id, openedAt, status, badge }`; trạng thái chung `crListFilter` ("ALL" | "DIFF" | "UNKNOWN" | "WAITING"), `crControlQuery` (giữ). `flowRenderers["UIF-16" / "UIF-17"]["SCR-078"] = render078Recon`.
2. `crSetEntryFilter(flow, entry)`: Hub "Đối soát sai lệch" → "DIFF"; Home "Hồ sơ cần kiểm tra" → "ALL".
3. `render079BJ16` viết lại theo 0.4 điểm 7–11 (bảng ở điểm 8 là `cr16RouteView(c)` trả `{ state, conclusion, compare, primary }` — một nơi giữ chữ theo loại; BJ-17 có `cr17RouteView`). Sheet `crConfirmSheet({ kind })` dùng chung hai luồng (`k4Footer` trong hộp thoại, `aria-modal`, Esc đóng).
4. Kiểm `evidenceVersion` lúc bấm nút xác nhận trong sheet (thay chỗ kiểm ở 080 — `cr16-start-recovery`, `cr17-execute-plan`): lệch → đóng sheet, 079 `k1Stale`.
5. 081: `crRecoveryDone()` (QA `__VET45_QA__.finishCR16Recovery()`; prototype gọi bằng hẹn giờ 250 ms có kiểm `activeScreenId` như hiện tại) → 082 `READY`, hoặc `CONFLICT` nếu `recoveryEvidenceVersion` lệch.
6. Nhánh "đã sửa phiếu gốc": `c.correctionDone` (BJ-11 đặt) → 079 hiện dòng thứ ba của bảng điểm 8; "Kiểm lại" → 082 với bảng Sổ kho 18 · Số trên app 18 · Chênh lệch 0. Sửa sai đang chờ duyệt: đọc `cr11Requests` theo `c.correctionOperationId` → `k2Pending` + "Xem yêu cầu" (→ `applyEntry("UIF-11", …)` 053 `PENDING_APPROVAL`).
7. Đóng hồ sơ: `c.status = "CLOSED"`, `c.closedAt`, `c.done` (chữ "Đã làm"); dòng biến khỏi 078 và khỏi số Home.
8. Home (`hub.js` `renderHubHome`): bỏ hai `attentionRow` UIF-16 / UIF-17; thêm một dòng đọc số từ `window.__T7_RECON_COUNTS__()` (bj16.js đăng ký; `hub.js` không biết cấu trúc hồ sơ); `data-t462-attention="UIF-16"` giữ cho dòng mới để `SC_attention_UIF-16` còn chạy; `SC_attention_UIF-17` đổi sang chip "Chưa rõ kết quả" của 078 (ghi mục 9).
9. Sự kiện: `data-recon-filter`, `data-recon-search` (lọc tại chỗ như K6), `data-recon-row`; `data-bj16-action="recover" | "close" | "fix-source" | "recheck" | "view-correction" | "escalate" | "to-purchase" | "close-case" | "back-evidence" | "to-list" | "open-locking-case" | "reload"`; `data-recon-sheet="confirm" | "cancel"`.
10. Xoá mã chết (vấn đề 11): `render078Shared`, `bj16CaseRows`, `bj16CaseListLegacy`, `bj16EvidenceCard`, `bj16EvidenceSurface`, `bj16Denied` / `bj16Loading` (→ K1), `render080BJ16` (đăng ký `screenAliases["SCR-080"] → "SCR-079"`), `ac310SanitizeMarkup` / `ac310Return` ở BJ-16 / 17 (đo trước như BJ-08 — chữ đã viết lại), nhãn `data-v350-action="cr16-*"`, `data-cr16-*`, `data-cr-case`, `data-v360-action="fallback-exit"` → `data-recon-*` / `data-bj16-*`. `crFactCard` còn ai dùng thì giữ trong `shared-control.js`, không thì xoá. Sửa `tools/golden.mjs`.

### 4.2 Màn

| Màn | Việc |
|---|---|
| 078 | 0.4 điểm 1–6; `appShell({ extraClass:"k7-wide" })` |
| 079 (UIF-16) | 0.4 điểm 7–11 |
| 080 | xoá khỏi `screens` của UIF-16 / UIF-17 (bộ chọn trạng thái, inspector `core.js` dòng 45–46); `screenAliases` → 079 |
| 081 | 0.4 điểm 12 |
| 082 | 0.4 điểm 13–14 |
| 083 (UIF-16) | 0.4 điểm 16–17 |
| Hub / Home | 0.4 điểm 6; mục 4.1 điểm 8 |

## 5. Bước C2 — BJ-17, K3 nguồn (commit 2)

1. `render079BJ17` theo 0.4 điểm 8 (ba dòng cuối bảng) + điểm 9; sheet điểm 10; `render083BJ17` theo điểm 17–18. `render080BJ17`, `render082BJ17` xoá (082 bỏ khỏi UIF-17 — điểm 15); `cr17-finish-review` gộp vào nút xác nhận của sheet (kiểm `resolutionRecord` như cũ rồi đi 083).
2. `bj17HandoffUnknown` (0.4 điểm 19) — **rủi ro HIGH** (mọi K3 gọi): chỉ thêm đọc `bj17SourceEvidence`, không đổi chữ ký hàm; chạy lại mọi `SC_bj17_from_*` sau khi sửa.
3. Nhãn `data-v350-action="cr17-*"`, `data-cr17-*` → `data-bj17-*`. Giữ `data-v350-action="handoff-unknown"` (BJ nguồn phát; đổi ở đợt dọn cuối Giai đoạn 2 — ghi mục 9).

CSS (C1 + C2): gom luật BJ-16 / 17 (`[data-active-uif="UIF-16" / "UIF-17"]`, `.cr-*` còn lại, `.ac310-progress*` nếu chỉ 081 dùng) về khối "BJ-16 / BJ-17" trong `styles/screens.css`, bỏ `!important` không còn đối thủ; bỏ luật cột 402px cho UIF-16 / 17.

## 6. Golden và `SC_journey_5` (commit 3, cùng D)

### 6.1 Golden mở thẳng

Bộ chọn trạng thái: 078 bỏ `INVESTIGATING`, `ESCALATED`; 080 bỏ hết; 081 bỏ `READY` (tự sang 082); 083 bỏ `RESOLVED`; UIF-17 bỏ 082. Mỗi trạng thái 079 mở bằng hồ sơ đúng loại (`bj16Seed`: `PROJECTION_MISMATCH` = REC-03, `CORRECTION_REQUIRED` = REC-04, …). Ghi CHANGELOG mọi trạng thái bỏ.

### 6.2 Kịch bản BJ-16 / BJ-17 (`D = '?uif=UIF-16&screen='`, `U = '?uif=UIF-17&screen='` — có sẵn)

Sửa theo nhãn mới: `SC_bj16_list` (chip "Sai lệch" / "Chưa rõ kết quả" / "Đang chờ" / "Tất cả", tìm "DH2507"), `SC_bj16_recovery` (REC-03 → "Cập nhật số trên app" → "Cập nhật" → 081 → `finishCR16Recovery` → 082 → "Đóng hồ sơ" → 083), `SC_bj16_conflict` (mở sheet → `bumpCR16Evidence` → "Cập nhật" → 079 `k1Stale`), `SC_bj16_mismatch` (đến 082 `MISMATCH_REMAINS` → "Quay lại bằng chứng"), `SC_bj16_correction` (REC-04 → "Sửa phiếu gốc" → BJ-11 050 điền sẵn 18), `SC_bj16_no_real` (REC-05 → "Đóng hồ sơ" → sheet → 083), `SC_bj16_ledger` (REC-06 → "Gửi bộ phận hỗ trợ" → 083 → "Về hồ sơ cần kiểm tra"), `SC_bj16_source` (REC-07 → "Chuyển cho Mua hàng" → 083), `SC_bj16_back`, `SC_bj16_context`, `SC_bj16_denied`; `SC_bj17_list`, `SC_bj17_committed` (UNKNOWN-01 → "Xác nhận đã hoàn tất" → sheet → 083), `SC_bj17_continue` (UNKNOWN-02 → "Làm tiếp thao tác" → sheet → 083), `SC_bj17_insufficient` (UNKNOWN-03 → "Gửi bộ phận hỗ trợ" → 083), `SC_bj17_plan_conflict` (mở sheet → `bumpCR17Evidence` → xác nhận → 079 `k1Stale`), `SC_bj17_sheet_conflict` (thay `SC_bj17_finish_conflict`), `SC_bj17_context`, `SC_bj17_denied`, `SC_bj17_from_bj05` (→ 079 nhánh "chưa ghi" → "Làm tiếp thao tác").

| Kịch bản | Bắt đầu | Bước |
|---|---|---|
| `SC_recon_list` | `D + 'SCR-078'` | chip "Chưa rõ kết quả" → dòng UNKNOWN-01 (079 BJ-17) → quay lại (chip giữ) → chip "Sai lệch" → dòng REC-03 (079 BJ-16) |
| `SC_recon_home` | `T + 'inventory'` | Home "Hồ sơ cần kiểm tra" → 078 chip "Tất cả" → quay lại → workspace "control" → "Đối soát sai lệch" (chip "Sai lệch") |
| `SC_bj16_locked` | `D + 'SCR-079&state=…'` (REC-260907-08) | `k1Locked` → "Mở hồ sơ đó" → 079 REC-04 |
| `SC_bj16_correction_return` | `D + 'SCR-078'` | REC-04 → "Sửa phiếu gốc" → lý do → "Gửi phê duyệt" → 053 chờ duyệt → "Về hồ sơ đối soát" → 079 `k2Pending` → (vai `approver`) BJ-11 051 "Duyệt" → 053 → "Về hồ sơ đối soát" → 079 "Đã sửa phiếu gốc" → "Kiểm lại" → 082 → "Đóng hồ sơ" → 083 |

### 6.3 Web

`WEB_SCENARIOS` thêm `SC_recon_list`, `SC_bj16_recovery`, `SC_bj16_correction_return`, `SC_bj17_committed`, `SC_journey_5`. Chỉ dùng `data-recon-*` / `data-bj16-*` / `data-bj17-*` / `data-bj08-*` / `data-bj11-*` / `data-theme-*`, không chọn theo chữ.

### 6.4 `SC_journey_5` — hết chặng 5

Một mạch ở chế độ Toàn Theme 7 (`T + 'inventory'`), vai mặc định (nhân viên), bước duyệt đi qua Home "Chờ duyệt" (dòng gắn vai người duyệt), cả hai khung. Helper `home(…)`, `chain(…)` như `SC_journey_3` / `_4`.

| # | Bước (tên) | Thao tác | Thấy |
|---|---|---|---|
| 0 | (mở) | — | Home: "Chờ duyệt" có "1 kiểm kê · 1 sửa sai" (+ nguồn chặng trước nếu có); "Cần chú ý" có "Hồ sơ cần kiểm tra" "{a} sai lệch · {b} chưa rõ kết quả" (số theo fixture) |
| 1 | `count` | nút nhanh "Kiểm kê" | 042 |
| 2 | `new` → `group` → `scope` → `pick` → `open` → `confirm-open` | "Tạo phiên kiểm kê" → "Nhóm sản phẩm" → "Chọn phạm vi cụ thể" → "Thuốc kháng sinh" → "Mở phiên kiểm kê" → "Mở phiên" | 044 KK-260917-01, "Đã đếm 0/3 mặt hàng" |
| 3 | `oxy` → `ty2511` → `ty2408` → `submit` → `confirm-first` | gõ 10 → Enter → 4 → Enter → 11 → "Nộp kết quả đếm" → "Nộp kết quả" | 045: "2 mặt hàng lệch · 1 khớp" |
| 4 | `same-oxy` → `recount-ty` → `send` → `confirm-recount` | "Vẫn 10 chai" → 3 → "Gửi kết quả đếm lại" → "Gửi kết quả" | 046 chờ duyệt (K2, không tiền) + toast |
| 5 | `home-1` → `pending-1` → `case-1` → `approve-1` | về Home → "Chờ duyệt" → dòng "kiểm kê KK-260917-01" → "Duyệt và điều chỉnh" | 047 "Đã hoàn tất kiểm kê" · "Thiếu 1 · thừa 0 mặt hàng" · "−110.000 đ" |
| 6 | `home-2` → `recon` → `diff-chip` → `rec-04` | về Home → "Hồ sơ cần kiểm tra" → chip "Sai lệch" → REC-260907-04 | 079 "Phiếu PN-260904-08 ghi 20 hộp, hoá đơn chỉ 18 hộp…" |
| 7 | `fix` → `reason` → `send-fix` | "Sửa phiếu gốc" → lý do → "Gửi phê duyệt" | BJ-11 053 chờ duyệt |
| 8 | `home-3` → `pending-2` → `case-2` → `approve-2` | về Home → "Chờ duyệt" → dòng "sửa sai PN-260904-08" → "Duyệt" | BJ-11 053 "Đã hoàn tất sửa sai", nút "Về hồ sơ đối soát" |
| 9 | `back-case` → `recheck` → `close-1` | "Về hồ sơ đối soát" → "Kiểm lại" → "Đóng hồ sơ" | 083 "Đã xử lý sai lệch" · "Đã làm: Sửa phiếu PN-260904-08 · …" |
| 10 | `to-list` → `rec-03` → `recover` → `confirm-recover` → `finish` → `close-2` | "Về hồ sơ cần kiểm tra" → REC-260907-03 → "Cập nhật số trên app" → "Cập nhật" → (QA xong) → "Đóng hồ sơ" | 083 "Đã xử lý sai lệch" · "Đã làm: Cập nhật số trên app" |
| 11 | `to-list-2` → `unknown-chip` → `unknown-01` → `confirm-done` → `confirm-sheet` | "Về hồ sơ cần kiểm tra" → chip "Chưa rõ kết quả" → REC-UNKNOWN-01 → "Xác nhận đã hoàn tất" → xác nhận | 083 "Đã xác lập kết quả nghiệp vụ" |
| 12 | `home-end` | về Home | Home: "Hồ sơ cần kiểm tra" bớt 2 sai lệch, bớt 1 chưa rõ; "Chờ duyệt" không còn hai dòng vừa duyệt |

Kiểm: 0 lỗi JS, mỗi bước đổi màn đúng; nút quay lại / thanh bên không về nhầm màn con Hub (bẫy `SC_journey_2` / `_3`); đổi luồng UIF-08 → UIF-16 → UIF-11 → UIF-16 → UIF-17 không làm mất chip của 078.

## 7. Bước D — kiểm

1. Golden mobile / web so mốc mục 2: chỉ ca ở 0.8 khác; ghi mục 9. Mọi trạng thái 0.5 cho ảnh khác nhau, cả hai khung — đặc biệt bảy loại 079 BJ-16 và ba loại 079 BJ-17.
2. Bấm thử UIF-16, UIF-17 hai khung + Home "Hồ sơ cần kiểm tra" + Hub "Đối soát sai lệch" + K3 "Chuyển sang xác minh" của BJ-02 / 05 / 06 / 07 / 08 / 10 / 11: 0 lỗi JS; `node --check app/*.js harness/*.js tools/golden.mjs`.
3. **`/impeccable audit` phạm vi UIF-16 + UIF-17 — chặn commit E.** Chạy trên 078 (READY từng chip, EMPTY, FILTER_EMPTY), 079 (bảy loại BJ-16 + ba loại BJ-17 + bốn sheet + `k1Stale` + `k1Locked`), 081 (REBUILDING, CONFLICT), 082 (READY, MISMATCH_REMAINS), 083 (COMPLETED BJ-16 / BJ-17, ESCALATED ba loại, UNKNOWN), Home "Cần chú ý", ở cả hai khung. Đạt khi: chữ ≥ 4,5:1 (badge, phụ đề dòng, giá trị "lệch" trong bảng so sánh, dòng "Đang tạm khoá…"); vùng chạm ≥ 44 × 44 ở iPhone (chip cuộn ngang, dòng danh sách); dòng lệch không chỉ phân biệt bằng màu (có chữ "lệch {±d}"); **không còn chữ kỹ thuật** — `grep` HTML mọi trạng thái không có "Số liệu hiển thị", "Nguồn nghiệp vụ", "Bảo vệ phạm vi", "Vận hành nền tảng", "Định danh nghiệp vụ", "Lần xử lý", "projection", "ledger"; web đi được bằng bàn phím (Tab qua ô tìm → chip → bảng → nút chân; Enter mở / Esc đóng sheet, focus về nút đã mở, Tab không thoát `aria-modal`); web không còn cột 402px; iPhone không bảng ép nhỏ, số và ĐVT không gãy dòng. Lỗi trong phạm vi: sửa ngay; ngoài phạm vi: ghi mục 9.
4. **Audit dọc `SC_journey_5`** (bài học góp ý 2 chặng 3): mọi bước của 6.4, cả hai khung — tương phản, vùng chạm iPhone, tên nút, tràn ngang, nút quay lại, toast không che nút chân.
5. Gửi ảnh: 078 web + iPhone (Tất cả), 079 PROJECTION iPhone + web, 079 CORRECTION iPhone (chưa sửa + đã sửa), 079 BJ-17 đã ghi iPhone, sheet "Cập nhật số trên app theo sổ kho?" iPhone, 082 web, 083 ESCALATED iPhone, Home "Cần chú ý" hai khung, `SC_journey_5` bước 0 và 12 (Home).
6. Mốc hết chặng 5: `tools/.golden-chang5` / `tools/.golden-chang5-web`.

## 8. Bước E — ghi lại (commit 4)

1. `CHANGELOG.md` `[5.18.0] — BJ-16 / BJ-17 thiết kế lại; danh sách "Hồ sơ cần kiểm tra"; hết chặng 5 (SC_journey_5)`; phiên bản 5.18.0 (`manifest.json`, `harness/workbench.js`, badge `index.html`, nhãn inspector UIF-16 / UIF-17). Ghi các trạng thái / màn bỏ (080; 082 khỏi UIF-17; 078 `INVESTIGATING` / `ESCALATED`; 081 `READY`; 083 `RESOLVED`).
2. Viết lại theo `_TEMPLATE.md`: SCR-078 (một danh sách hai luồng), SCR-079 (bảng loại → kết luận → việc tiếp theo, bốn sheet), SCR-081, SCR-082, SCR-083; SCR-080 → `RETIRED.md` ("Bỏ từ v5.18.0", thay bằng sheet xác nhận ở SCR-079); UIF-16 (sơ đồ mới: danh sách chung, Home một dòng, lối đi / về BJ-11), UIF-17 (lối vào từ K3, 079 → sheet → 083).
3. T7-P mục 2 bảng "Vị trí trên Home Kho" (dòng "Cần chú ý": "Hồ sơ cần kiểm tra" thay "sai lệch (16), kết quả chưa rõ (17)"); mục 5 thêm ghi chú "danh sách nhiều luồng" (078 làm theo cách K5); mục 9 BJ-16 / 17: khuôn "K1, K3, K4, K6, K7".
4. `INDEX.md` 078…083; T7-P mục 13 (chữ mới; danh sách chung; Home một dòng; bỏ 080; "Bộ phận hỗ trợ" / "Mua hàng" là người nhận — 0.10 e, f; UC-16-01…04 / UC-17-01…04 mục "màn sử dụng" bỏ SCR-080 ở 7.3); mục 14: BJ-16 / 17 ✅, chặng 5 `SC_journey_5` ✅.
5. `python3 tools/sync-registry.py`.

## 9. Ghi chú khi làm

**Làm xong 2026-10-25, một lượt, chưa commit (để phiên review xem trước; cây làm việc còn thay đổi BJ-08 / BJ-11 chưa commit nên không tách 4 commit).** Phiên bản 5.18.0.

- **Mốc:** `tools/.golden-bj11-after` (1959 ca) / `-web-after` (1073 ca). Chụp lại ở HEAD làm việc = khớp, không cần `.golden-bj16-base`. Sau khi làm: mobile **2016 ca**, web **1134 ca**, 0 lỗi JS; hết chặng 5 = `tools/.golden-chang5` / `-web` (cùng `.golden-bj16-after` / `-web-after`).
- **GitNexus:** công cụ MCP (`impact`, `detect_changes`) **không có trong phiên làm việc này** nên không chạy được. Thay bằng `grep` mọi nơi gọi: `bj17HandoffUnknown` chỉ gọi từ trình nghe `handoff-unknown` (bj17.js) — chữ ký giữ nguyên, chỉ thêm đọc `bj17SourceEvidence`; `crSwitchFlow` giữ nguyên; `renderHubHome` chỉ đổi khối "Cần chú ý". Rủi ro `bj17HandoffUnknown` (HIGH theo dự kiến) được kiểm bằng golden: bước 0 của mọi `SC_bj0x_unknown` khớp mốc, chỉ từ bước "Chuyển sang xác minh" trở đi khác. **Cần chạy `detect_changes()` ở phiên có GitNexus trước khi commit.**
- **Kết quả D:** so mốc — chỉ các ca ở 0.8 khác (đã đối chiếu: ca ngoài BJ-16 / 17 chỉ khác vùng dòng Home "Cần chú ý" hoặc màn BJ-17 sau K3). Kiểm dọc (`AUDIT_JS`: tương phản ≥ 4,5:1, vùng chạm ≥ 44 × 44 ở iPhone, tràn ngang, chữ kỹ thuật bị cấm) trên 078…083, Home, mọi kịch bản `SC_bj16_*`, `SC_bj17_*`, `SC_recon_*`, `SC_journey_5`: **0 vi phạm** ở cả hai khung (mobile 1566 ca, web 675 ca). `node --check app/*.js harness/*.js tools/golden.mjs` đạt.
- **Audit `/impeccable audit` (2026-10-25):** đã chạy trên UIF-16 + UIF-17 (078, 079, 081, 082, 083, Home), cả hai khung. `impeccable detect` 0 phát hiện trong `bj16.js`, `bj17.js` và khối `v5.18.0` của `screens.css` (các ghi chú còn lại là dòng cũ). Kiểm dọc 0 vi phạm. Bàn phím (CDP, cả hai khung): Tab đi ô tìm → chip → dòng; web Enter trên `<tr>` mở hồ sơ; sheet `role="dialog"` `aria-modal="true"`, focus vào "Quay lại" khi mở, Tab / Shift+Tab xoay vòng trong sheet, Esc đóng và trả focus về đúng nút "Cập nhật số trên app". Phát hiện và xử lý: **P2** chip thiếu `aria-pressed` → đã thêm ở `ds24Chip` (khuôn dùng chung); **P2** iPhone phụ đề dòng danh sách bị cắt "…" mất mã hồ sơ → đã cho xuống dòng (tối đa 3 dòng, gạch nối không ngắt); mốc chặng 5 chụp lại sau sửa. Còn lại: **P3** `<tr data-recon-row>` focus được nhưng chưa có `role` / tên rõ ràng; **P3** UIF-16 / 17 còn trong luật chung `[data-active-uif]` có `!important` và độ rộng 370px của UIF-08…17. Chưa chụp bộ ảnh mục 7.5; chưa thử cử chỉ cảm ứng (không có cử chỉ tuỳ biến, chỉ dải chip cuộn ngang sẵn có).
- **Lệch so với plan:**
  1. Thêm hai trạng thái 079 `LOCKED` và `CONFLICT` vào bộ chọn (plan chỉ ghi `SC_bj16_locked` mở bằng `state=…`); hồ sơ REC-260907-08 (khoá) và REC-260907-09 ("Chưa rõ nguyên nhân", `UNKNOWN_EVIDENCE` / `INSUFFICIENT_EVIDENCE` của UIF-16) là hồ sơ `LINKED`, chỉ dựng trạng thái, không hiện ở danh sách và không vào số Home.
  2. Hồ sơ đã gửi (`WAITING`) mở lại ở 079 hiện banner "Đã gửi bộ phận hỗ trợ" / "Đã chuyển cho Mua hàng" và không còn nút (plan không nói); thêm biến thể PROJECTION sau khi cập nhật: "Đã cập nhật số trên app · chờ kiểm lại" + "Kiểm lại" (để quay lại từ 082 vẫn đúng).
  3. `k2Pending` thêm tham số `subject` (để ra "Chờ chủ cửa hàng duyệt sửa sai · gửi …"); `k4ReasonFooter` thêm `note` (dòng "Đóng xong, … mở khoá." luôn hiện khi nút bật). Cả hai mặc định không đổi — ca BJ khác không đổi.
  4. BJ-11: duyệt từ Home "Chờ duyệt" (`bj11-approval`) đặt `cr11ReturnCase = r.caseId` — nếu không, "Về hồ sơ đối soát" biến mất sau khi duyệt qua Home (bước 8 của `SC_journey_5`).
  5. Bảng so sánh dùng `crCompare` (khối riêng `.cr-compare__rows`) thay `ac310KeyValueSurface` vì luật cũ ép số sang chữ đơn cách; 081 / 082 / web "Hồ sơ" dùng cùng khối.
  6. Dọn CSS hẹp hơn plan: chỉ xoá luật chết của UIF-16 / 17 (`.cr-evidence*`, `.cr-case-list`, `.io-product-*` / `.cr-fact-card` gắn UIF-16 / 17, `.ac321-chip-wrap`, `.ac310-progress*`); UIF-16 / 17 **còn trong** danh sách chung `[data-active-uif=…]` của UIF-08…17 (ellipsis dòng, chip, hàng Compact) vì danh sách K6 của BJ-16 / 17 dùng chung luật đó với BJ-08 / 11; luật cột 402px không còn ảnh hưởng (web dùng `k7-wide`, đã xem ảnh).
  7. `data-v350-action="handoff-unknown"` giữ (đợt dọn cuối Giai đoạn 2). `crFactCard` giữ (BJ-12 / 15 còn dùng).
  8. `SC_bj17_sheet_conflict` mở sheet "Làm tiếp" của UNKNOWN-02 (khác `SC_bj17_plan_conflict` dùng "Xác nhận" của UNKNOWN-01) để hai ca không trùng.
- **Chưa làm / để review:** `detect_changes()` của GitNexus; ảnh gửi mục 7.5; mở lại hồ sơ đã đóng khi có bằng chứng mới (mục 11, không làm).

## 10. Thứ tự commit

1. C1 (078 chung, 079 / 081 / 082 / 083 BJ-16, sheet, Home, bỏ 080 phía UIF-16).
2. C2 (079 / 083 BJ-17, `bj17SourceEvidence`, bỏ 080 / 082 phía UIF-17).
3. C3 `SC_journey_5` + D (golden, sửa sau audit).
4. E (tài liệu, phiên bản, registry).

Nếu làm một lượt thì để chưa commit cho phiên review xem trước. `detect_changes()` trước mỗi commit.

## 11. Không làm

- Mở lại hồ sơ đã đóng khi có bằng chứng mới (UC-16 BR-05 — prototype chưa có tín hiệu mới sau khi đóng).
- Màn điều tra chi tiết (dòng thời gian bằng chứng, BJ-15 SCR-057) — chặng 6.
- Khoá phạm vi của hồ sơ hiện ở BJ-01 / BJ-09 (dòng "Đang tạm khoá" chỉ ở 079).
- Đổi chữ K3 ở các BJ nguồn; đổi nhãn `data-v350-action="handoff-unknown"` (đợt dọn cuối Giai đoạn 2).
- Màn / vai "Bộ phận hỗ trợ" trong app (chỉ là người nhận ghi ở hồ sơ — 0.10 e).

## 12. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| `bj17HandoffUnknown` được mọi K3 gọi — sửa làm gãy BJ nguồn | Chỉ thêm đọc `bj17SourceEvidence`; chạy lại mọi `SC_bj17_from_*`, bước 0 ở BJ nguồn phải khớp mốc; báo người dùng mức rủi ro ở mục 2 điểm 3 |
| Một danh sách cho hai luồng làm nút quay lại / Hub về nhầm luồng | Chip / tìm là trạng thái chung; `crReturnTo` + `data-keep-back`; kiểm `SC_recon_list`, `SC_recon_home` ở chế độ Toàn Theme 7, cả hai khung |
| Đi BJ-16 → BJ-11 → duyệt → BJ-16 qua ba lần đổi luồng, mất hồ sơ đang mở | `cr11ReturnCase` giữ mã hồ sơ; `SC_bj16_correction_return` và `SC_journey_5` bước 6–9 |
| `SC_journey_5` dài (≈ 45 bước) dễ gãy giữa chừng | Gộp thao tác bằng `chain`; mỗi bước kiểm màn đích; chạy riêng từng khung trước khi chụp mốc; 081 dùng `finishCR16Recovery` thay chờ mù |
| Bỏ 080 làm gãy link / golden cũ | `screenAliases` → 079; xoá ca golden 080 có ghi CHANGELOG |

## 13. Chữ trên màn

| Vị trí | Chữ |
|---|---|
| 078 | "Hồ sơ cần kiểm tra" · "Sai lệch số liệu và thao tác chưa rõ kết quả" · "Tìm hồ sơ, sản phẩm hoặc mã phiếu" · chip "Sai lệch", "Chưa rõ kết quả" · "{phạm vi} · {mã hồ sơ}" · badge "Cần làm", "Nghi sổ kho sai" · cột "Hồ sơ", "Loại", "Mở lúc", "Tình trạng" · rỗng "Không có hồ sơ cần kiểm tra" · "Bạn chưa có quyền đối soát" · tiêu đề dòng: "Số trên app lệch sổ kho", "Phiếu nhận ghi khác hoá đơn", "Đã sửa phiếu gốc · chờ kiểm lại", "Báo cáo khác số tồn", "Sổ kho có dấu hiệu sai", "Phiếu mua chưa khớp kho", "Chưa rõ nguyên nhân", "{nghiệp vụ} đã ghi vào kho", "{nghiệp vụ} chưa ghi vào kho", "Chưa biết đã ghi hay chưa" |
| Home | "Hồ sơ cần kiểm tra" · "{a} sai lệch · {b} chưa rõ kết quả" |
| 079 | "Kết luận" · "So sánh" · bảy câu kết luận ở 0.4 điểm 8 · "Số trên app" · "Phiếu gốc" · "Hoá đơn nhà cung cấp" · "Phiếu mua" · "Báo cáo lúc {giờ}" · "Phiếu sửa sai" · "Yêu cầu" · "Ghi vào kho" · "Đã có" / "Chưa có" / "Chưa rõ" · "lệch {±d} {ĐVT}" · "Đang tạm khoá {phạm vi}: chưa nhận, xuất hay bán được cho tới khi đóng hồ sơ." · "Không tạo thao tác mới, không ghi lại lần hai." · nút "Cập nhật số trên app", "Sửa phiếu gốc", "Kiểm lại", "Đóng hồ sơ", "Gửi bộ phận hỗ trợ", "Chuyển cho Mua hàng", "Xác nhận đã hoàn tất", "Làm tiếp thao tác" · "Chờ chủ cửa hàng duyệt sửa sai · gửi {lúc}" · "Nguồn tín hiệu" · "Mở lúc" · "Kiểm soát tự động", "Báo cáo cuối ngày", "{BJ nguồn} — chưa rõ kết quả" · "Có bằng chứng mới. Xem lại kết luận trước khi làm tiếp." · "Phạm vi đang thuộc hồ sơ khác" / "{mã hồ sơ} đang kiểm {phạm vi}. Mở hồ sơ đó để làm tiếp." / "Mở hồ sơ đó" |
| Sheet 079 | "Cập nhật số trên app theo sổ kho?" / "Sổ kho và phiếu gốc không đổi. {phạm vi} vẫn tạm khoá tới khi đóng hồ sơ." / "Cập nhật" · "Đóng hồ sơ?" / "Không có lệch thật; không cần sửa gì." · "Xác nhận {nghiệp vụ} {mã} đã hoàn tất?" · "Làm tiếp {nghiệp vụ} {mã}?" / "Dùng đúng thao tác cũ, không tạo thao tác mới." |
| 081 | "Đang cập nhật số trên app" · "Chưa cập nhật được số trên app" · "Về hồ sơ" |
| 082 | "Số trên app khớp sổ kho." · "Sổ kho đã theo phiếu sửa sai." · "Đóng hồ sơ" · "Đóng xong, {phạm vi} mở khoá." · "Hồ sơ vẫn mở, {phạm vi} vẫn tạm khoá. Quay lại bằng chứng để xem tiếp." |
| 083 | "Đã làm" · "Đóng lúc" · "Về hồ sơ cần kiểm tra" · "Đã gửi bộ phận hỗ trợ" · "Người nhận" · "Bộ phận hỗ trợ" · "Gửi lúc" · "Đã chuyển cho Mua hàng" / "Hồ sơ chờ Mua hàng kiểm lại phiếu {mã}; Kho không tự sửa." · "Đã làm tiếp, đã ghi" · "Từ" · K3 "Chuyển hồ sơ" |

## 14. Review

**Review chặng 5 (BJ-08 + BJ-11 + BJ-16 / 17):** (2026-10-25, phiên review) — **đạt có điều kiện**, **đạt hẳn sau R1–R3** (v5.18.1, xem "Đã sửa" cuối mục). Review của BJ-08 / BJ-11 trỏ về đây.

| Kiểm (chạy lại) | Kết quả |
|---|---|
| `node --check app/*.js harness/*.js tools/golden.mjs` | Sạch |
| Golden mobile / web chụp lại (tuần tự) | 2016 / 1134 ca, 0 lỗi JS; **"Khớp hoàn toàn"** với `tools/.golden-chang5` / `-web` (mốc tái lập được) |
| `.golden-bj08-base` → `.golden-chang5` | 1062 / 476 khác biệt. Ngoài UIF-08 / 11 / 16 / 17 còn 153 ca (Home, `SC_ws_*`, `SC_journey_1…4`, `SC_bj0x_owner_*`…): `diff` thân `.txt` **chỉ** khác "Chờ duyệt" (+ "1 kiểm kê", "1 sửa sai", số +2, hai dòng `KK-260915-02` / `PN-260901-07`), dòng "Cần chú ý" mới ("Hồ sơ cần kiểm tra" "5 sai lệch · 3 chưa rõ kết quả" thay hai dòng cũ) và màn BJ-17 sau K3 của BJ khác. Đúng 0.8 của ba plan. (`.golden-chang4` không dùng làm mốc được: chụp trước R1–R3 chặng 4.) |
| Đếm mù / tiền | `UIF-08_SCR-044_*` và bước 8–11 của `SC_journey_5` không có "Theo sổ / Chênh lệch / Thiếu / Thừa"; bước nhân viên (046 chờ duyệt, 050 / 053 sửa sai) không có "… đ"; bước chủ duyệt (047) có "−110.000 đ" |
| Tài liệu bước E | SCR-042…051, 053, 078, 079, 081…083: `IN_REVIEW`, không còn đoạn `### vX.Y`; SCR-052 / 080 → `RETIRED.md` + `INDEX.md`; liên kết UC / PROC / PAT-NAV tới hai tệp đã xoá đã sửa (sớm hơn 7.3, chấp nhận — tránh liên kết gãy); CHANGELOG `[5.16.0]`…`[5.18.0]`, phiên bản 5.18.0 ở manifest / harness / badge |
| Registry | `sync-registry.py` chạy lại: không đổi gì. Còn hai dòng trỏ tệp đã xoá — góp ý 6 |
| GitNexus (CLI `node .gitnexus/run.cjs … --repo erp-sales-inventory`) | `impact bj17HandoffUnknown` upstream: **LOW** (1 — trình nghe trong `bj17.js`; dự kiến HIGH ở mục 2 không đúng vì K3 gọi qua `data-v350-action`, không gọi hàm). `detect-changes`: 53 tệp, 455 symbol (phần lớn tiêu đề tài liệu), **0 quy trình, rủi ro thấp** — thay cho bước "chưa chạy" ở mục 9 |
| Ảnh | `SC_journey_5` bước 9, 13, 24, 26, 32, 33 (iPhone), 22, 36 (`@web`); `UIF-08_SCR-046_READY@web`, `UIF-11_SCR-050_READY@web` |

Lệch plan ở ghi chú (BJ-08 mục 10, BJ-11 mục 9, plan này mục 9): **chấp nhận**, trừ hai điểm thành R2 / R3 dưới đây (fixture và câu `DEPENDENCY_BLOCKED` mà người làm đã ghi là lệch).

**Cần sửa (chặn commit):**

- **R1. BJ-17 mở hồ sơ thứ hai cho cùng một thao tác.** BJ-11 049 phiếu `TH-260906-02` (`IO-260906-031`, "Đang xác minh") → "Chuyển sang xác minh" tạo `REC-11-IO260906031` "Chưa biết đã ghi hay chưa", trong khi `REC-UNKNOWN-01` của **cùng thao tác** nói "Tiêu hủy đã ghi vào kho" (`SC_bj11_unknown_2_handoff`, `SC_bj17_from_bj11_1_handoff`); 078 sau đó có hai hồ sơ kết luận ngược nhau. Trái UC-16 BR-01 (tín hiệu mới gắn vào hồ sơ đang mở) và UC-17 BR-02 (tra bằng đúng mã thao tác). Nguyên nhân: `bj17RecoveryCase` tìm theo `operation` **và** `sourceFlow` (`REC-UNKNOWN-01` có `sourceFlow: "UIF-17"`). Sửa: (a) tìm theo `operation` thôi, có thì mở hồ sơ đó (giữ `evidence`); (b) 053 `UNKNOWN` ("Ghi sửa sai") gửi `operation` = mã yêu cầu `r.id`, không phải `op.id` của phiếu gốc (nếu không, (a) sẽ gộp lần ghi sửa sai vào phiếu nhận); (c) `BJ17_KIND["UIF-11"]` "Sửa sai" thay "Phiếu kho" (dòng so sánh hiện "Phiếu kho: Chưa rõ"). Golden đổi: `SC_bj11_unknown_2`, `SC_bj17_from_bj11_1`, `UIF-11_SCR-053_UNKNOWN` (bước chuyển).
- **R2. Số tồn của fixture chung chặng 5 lệch nhau trong cùng `SC_journey_5`.** Nobivac DH2507 là **70 hộp** ở BJ-01 / chặng 4 / BJ-08 nhưng hồ sơ REC-260907-03 ghi "Sổ kho 118 · Số trên app 116" (bước 36). Amox 500: 050 ghi "Tồn Amox 500: 46 → 44 hộp" (bước 26) nhưng 079 ngay trước ghi "Sổ kho 20 hộp" (bước 24) và 082 sau khi sửa "Sổ kho 18 · Số trên app 18" (bước 33). "Sổ kho" ở 079 / 082 đang là số của **phiếu**, không phải tồn — người xem demo thấy hai số tồn khác nhau cho cùng sản phẩm. Lỗi gốc ở bảng fixture mục 3 (phiên review viết). Sửa: REC-03 so sánh "Sổ kho 70 · Số trên app 68 · lệch −2" (bỏ dòng "Phiếu gốc 118" — hồ sơ số trên app không có phiếu gốc riêng; câu kết luận giữ); REC-04 `ledger: 46` — so sánh "Phiếu gốc 20 · lệch +2" · "Hoá đơn nhà cung cấp 18" · "Sổ kho 46 hộp"; sau sửa 079 "Sổ kho 44", 082 "Sổ kho 44 · Số trên app 44 · Chênh lệch 0" (`book = ledger − (source − invoice)`). `MISMATCH_REMAINS` dùng cùng nguồn số (hiện `ledger − 1` = 19 ở hồ sơ sửa phiếu).
- **R3. Câu `DEPENDENCY_BLOCKED` của BJ-11 nói sai sự thật.** "Sau phiếu này đã bán 3 lọ; sửa bây giờ làm tồn âm" — với fixture (tồn TY2511 3, sửa 5 → 3) tồn sau sửa là 1, không âm (BJ-11 mục 9 đã ghi). UC-11 BR-04 có hai lý do chặn (tồn âm **hoặc** có nghiệp vụ phía sau phụ thuộc); fixture này là lý do thứ hai. Sửa chữ: **"Sau phiếu này đã bán 3 lọ; các phiếu bán đó dựa trên số đã nhận. Xử lý nghiệp vụ đó trước." (mới)** — ghi T7-P mục 13 (thay chữ ở dòng BJ-11 SCR-050); SCR-050 cập nhật bảng chữ.

**Góp ý nhỏ (không chặn):**

1. **079 web:** "Kết luận" + "So sánh" (nội dung chính) nằm cột hẹp 5fr, khối "Hồ sơ" ba dòng chiếm cột rộng 7fr (`SC_journey_5_36_rec-03@web`) — dùng `k7Split({ wideMain: true })` như 046 / 051.
2. **Tiêu đề "Kết luận" luôn màu cảnh báo**, kể cả câu thông tin ("Phiếu sửa sai … đã ghi", "Không có lệch thật", BJ-17 "đã ghi vào kho") — `SC_journey_5_32_back-case`. Tone tiêu đề theo tone câu, hoặc `.k2-attention--plain` khi `tone: "info"` (bài học R2 chặng 4).
3. **044 iPhone:** phụ đề dòng gãy giữa tên tình trạng "Bán / được" (`SC_journey_5_9_ty2511`) — nối tên tình trạng bằng NBSP trong `bj08LineSub` (như R3c chặng 4).
4. **Xác lập ở BJ-17 không trả kết quả về BJ nguồn:** sau bước 45 (`REC-UNKNOWN-01` "Đã xác lập"), BJ-11 048 vẫn "Tiêu hủy TH-260906-02 · Đang xác minh"; BJ-05 / 06 / 07 / 10 cũng không mở khoá. Cần móc ngược `onUnknownResolved[sourceFlow]` đối xứng `onUnknownHandoff` — ghi T7-P mục 13, làm ở đợt dọn cuối Giai đoạn 2 (cùng đổi nhãn `handoff-unknown`).
5. **`bj17ConfirmSheet`** dựng `resolutionRecord` từ chính `c` rồi so với `c` — phép kiểm luôn đúng (kiểm thật là `planEvidenceVersion` trong `crConfirmSheet`). Bỏ phép kiểm thừa, hoặc chụp bản ghi lúc mở sheet rồi so lúc bấm.
6. **Registry** còn dòng `SCR-052` / `SCR-080` trỏ tệp đã xoá (`sync-registry.py` chỉ bỏ đường dẫn mất trong `prototype/`); các màn RETIRED ở 7.1 đã không còn trong registry — xoá hai dòng (sửa tay, hoặc cho script bỏ mọi đường dẫn không tồn tại).
7. **"Kho trung tâm"** còn ở phạm vi `REC-UNKNOWN-03` ("1 phiếu · Kho trung tâm", 078) và phạm vi K3 của BJ-08 (`handoff.scope`) — app một kho, BJ-08 đã bỏ hàng "Kho".
8. **044:** gõ số xong dòng vẫn nằm dưới chip "Chưa đếm" tới lần dựng sau (chủ đích, giữ focus) — chấp nhận; nếu thấy rối khi demo thì ẩn dòng khi rời ô (`blur`), không dựng lại cả màn.
9. P3 audit còn mở (mục 9: `<tr data-recon-row>` chưa có `role` / tên; UIF-16 / 17 còn trong luật chung có `!important`) và toast `toast-close` 20 × 20 — đợt dọn chung cuối Giai đoạn 2.

**Đã sửa (2026-10-25, phiên review theo yêu cầu người dùng, v5.18.1) — review đạt:** R1 (`bj17RecoveryCase` tra theo mã thao tác; BJ-11 053 `UNKNOWN` gửi `r.id`; `BJ17_KIND["UIF-11"]` "Sửa sai"), R2 (`crBook(c)`; REC-03 70 / 68, bỏ dòng "Phiếu gốc"; REC-04 `ledger: 46` → 44 sau sửa; SCR-079 thêm câu "Sổ kho là tồn của cả phạm vi"; bảng mục 3 sửa), R3 (chữ mới ở `bj11.js`, SCR-050, T7-P mục 13). Kiểm: `node --check` sạch; golden 2016 / 1134 ca, 0 lỗi JS, chỉ các ca nêu ở CHANGELOG `[5.18.1]` khác mốc (94 / 46, đều thuộc UIF-11 / 16 / 17); chữ các bước 24, 32, 33, 36 của `SC_journey_5`, `SC_bj11_unknown_2`, `UIF-11_SCR-050_DEPENDENCY_BLOCKED`, `UIF-16_SCR-082_MISMATCH_REMAINS` đã đọc lại. GitNexus `impact` (upstream): `bj17RecoveryCase` LOW (1: `bj17HandoffUnknown`), `render082BJ16` / `render050BJ11` / `render053BJ11` LOW (0), `cr16RouteView` / `bj16InitialCases` chưa có trong chỉ mục. Mốc `tools/.golden-chang5*` chụp lại (v5.18.1). **Nguồn số 118 của Nobivac là fixture BJ-15** (`bj15.js` "P-NOB" 118, lô N2407-01…) — chặng 6 đổi theo DH2507 = 70 (ghi T7-P mục 9 BJ-15). Góp ý 1–9 để lại.

**Phạm vi commit:** cây làm việc chỉ có chặng 5 (v5.16.0 → v5.18.1). Sau R1–R3: không tách được theo commit của ba plan (một lượt, tệp dùng chung) → một commit BJ-08, một BJ-11, một BJ-16 / 17 nếu tách theo tệp được; không thì một commit chặng 5. Chạy lại `detect-changes` trước commit (CLAUDE.md); chụp lại mốc `tools/.golden-chang5*` sau R1–R3.
