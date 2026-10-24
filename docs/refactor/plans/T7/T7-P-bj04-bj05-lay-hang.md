# T7-P · BJ-04 Giữ hàng + BJ-05 Lấy hàng & bàn giao — thiết kế lại (bước B–E) + dựng K6

> Theme: Theme 7 Inventory · Trạng thái: Brief ✅ (duyệt 2026-10-24 — mục 0.10, mọi điểm theo đề xuất) | Plan C–E 📝 | Làm ✅ 2026-10-24 (v5.11.0, chưa commit) | Review ⬜
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) mục 8.2 **chặng 3 "Bán và giao"**, BJ thứ nhất và thứ hai (làm chung một plan như gói A1). Làm **sau** chặng 2 ([BJ-13](T7-P-bj13-dieu-chinh-gia-tri.md) — `SC_journey_2`) đã review. BJ sau: [BJ-06](T7-P-bj06-hang-khach-tra.md) (cuối chặng, có `SC_journey_3`).
> **Dựng K6** (danh sách công việc — T7-P mục 5) ở SCR-025; BJ-06 (SCR-030) dùng lại ngay trong chặng này. Dùng lại K1, K3, K4, K7. **Không K2** (UC-05-0x không có bước duyệt; đổi lô cần quyền + lý do, không cần người duyệt). Kèm **bước C0 — fixture chung chặng 3** (mục 3).
> Thiết bị: **cả iPhone và web đều là thiết bị chính** (T7-P mục 2). Nhân viên lấy hàng tại kệ bằng iPhone, đóng gói / bàn giao ở quầy có máy tính — hai bố cục thiết kế và kiểm như nhau.
> Ước lượng: **~2 ngày, 3 commit** (C0 + C1 BJ-05 + K6; C2 BJ-04 + D; E). Người làm: bạn. Review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị, chép nguyên văn; **(mới)** = chữ mới, vào T7-P mục 13 ở bước E.

## 0. Brief (bước B, đã duyệt 2026-10-24)

### 0.1 Việc thật

- **BJ-05 — ai, lúc nào:** nhân viên (1–3 người), **nhiều lần / ngày**, khi đơn bán sỉ / online đã sẵn sàng xuất kho. Cầm iPhone đi lấy ở kệ; đóng gói và giao cho khách / đơn vị vận chuyển ở quầy (thường có máy tính).
- **Cần biết / làm gì:** đơn nào cần lấy trước; mỗi mặt hàng lấy **lô nào, bao nhiêu** (lô gần hạn trước — FEFO, hệ thống gợi ý sẵn); đánh dấu đã lấy nhanh, chỉ gõ số khi lấy thiếu; lô gợi ý không lấy được thì đổi lô có lý do; giao đủ (hoặc một phần nếu đơn cho phép); **tồn chỉ giảm lúc xác nhận bàn giao**.
- **BJ-04 — ai, lúc nào:** không ai "làm" BJ-04: giữ hàng do đơn bán (Theme 5) tạo / sửa / giải phóng. Nhân viên / Owner chỉ **xem** đơn này đang được giữ bao nhiêu, thiếu bao nhiêu — từ chi tiết đơn, hoặc khi đang lấy hàng mà thấy thiếu.
- **Quy tắc giữ** (BJ-04, BJ-05, UC-05-02…05 BR-01…06, UIF-04 / 05): giữ hàng chỉ phản ánh, không có nút sửa ở Kho; một phiên bản phân bổ đang hiệu lực, bàn giao phải mang đúng phiên bản; lấy hàng **không** giảm tồn vật lý; bàn giao một phần chỉ khi đơn cho phép (`partialHandoverAllowed`), không cho thì chưa đủ là chặn cả lần; phân bổ cũ → phân bổ lại **trong cùng kho**, không tìm kho khác, không tự đổi đơn; đổi lô phải là lô đủ điều kiện, cần lý do; đổi / lô cũ sau khi đã cầm hàng → xác nhận đã trả lô cũ và lấy lại trước khi bàn giao; combo xuất trọn theo số nguyên combo; `UNKNOWN` không gửi lại, chuyển BJ-17.

### 0.2 Luồng hiện tại

Ảnh: `tools/.golden-chang2/UIF-05_*`, `SC_bj05_*`, `UIF-04_*`, `SC_bj04_*`; web `tools/.golden-chang2-web/UIF-05_*@web`, `UIF-04_*@web`.

```text
Hub → nút nhanh "Lấy hàng" → 025 Đơn cần lấy hàng ─đơn→ 026 Hàng cần lấy (Thông tin đơn 3 dòng + danh sách mặt hàng "12/20 hộp")
  ─mặt hàng→ 027 Chi tiết lấy hàng (danh sách lô) ─lô→ sheet "Đã lấy" (gõ số → "Cập nhật"; "Đổi lô" → sheet "Chọn lô thay thế")
  ─"Lưu lượng đã lấy"→ 026 ─"Rà soát bàn giao"→ 028 (gõ "Lượng thực giao" từng lô) ─"Xác nhận đã bàn giao"→ 029 Kết quả ─→ 025
BJ-04: chỉ mở được bằng ?uif=UIF-04 (giả lập "Chi tiết đơn > Tình trạng giữ hàng" của Theme 5) → 021 (chỉ xem); không nối với BJ-05.
```

### 0.3 Vấn đề

| # | Màn | Vấn đề |
|---|---|---|
| 1 | 026 → 027 → sheet | Lấy đủ một lô mất **5 chạm** (mặt hàng → lô → gõ số → "Cập nhật" → "Lưu lượng đã lấy"); không có "lấy đủ" một chạm; HSD lô không hiện ở 027 (chỉ trong sheet) nên không thấy vì sao lô này trước |
| 2 | 026 | "12/20 hộp" không rõ là đã lấy / cần lấy; khối "Thông tin đơn" ba dòng (Đơn, Khách hàng, Kho) chiếm nửa màn iPhone; ghi chú "Có thể bàn giao phần đã lấy…" và "Tồn vật lý chỉ giảm…" là hai đoạn chữ rời dưới danh sách |
| 3 | 027 | "Lưu lượng đã lấy" tắt **không nói lý do** (đang chờ xác nhận điều chỉnh lô); ảnh `READY` hiện "Lô DH2511 · Đã đổi" — trạng thái `STALE_RECOVERED` sửa thẳng fixture (`io05ApplyStaleRecovery`) và rò sang các ảnh sau; golden `027_STALE_RECOVERED` = `READY` |
| 4 | 028 | "Trong lần này 1 dòng hàng" / "Chưa hoàn tất 2 dòng hàng" khó hiểu ("dòng hàng" là chữ hệ thống); **không có người / đơn vị nhận** (UC-05-03 BF-03 "xác nhận lượng thực tế bàn giao và người/đơn vị nhận"); golden `READY` = `PARTIAL_ALLOWED` (đơn không cho giao một phần vẫn hiện ô sửa) |
| 5 | 029 | "Bàn giao lúc —" (giá trị trống); không có bước tiếp ngoài "Về danh sách"; `UNKNOWN` không theo K3 (không mã tham chiếu dạng người đọc, không thời điểm, không "Về Kho"); `PERMISSION_DENIED` là màn kết quả đỏ "Không có quyền bàn giao" thay vì K1 |
| 6 | 025 | Không phân biệt "đang lấy" và "chờ bàn giao" (master T7-P mục 9: K6 "đang lấy / chờ bàn giao"); chip không có số; golden `FILTER_EMPTY` = `READY` |
| 7 | Web | Mọi màn là cột iPhone 402px giữa khung (ảnh `UIF-05_SCR-026_READY@web`), chân là nút kéo dài hết cột |
| 8 | 021 | Hai tầng chữ trong một dòng ("Cần giữ còn lại 50 hộp · Đang giữ 42 hộp"); tiêu đề dòng "Nobivac DHPPi · SP-000184"; khối "Thông tin đơn" chỉ có Kho + "Đã xác nhận · Có giữ hàng"; **ngõ cụt**: không sang lấy hàng, nút quay lại chỉ hiện toast |
| 9 | 021 / 025 | Fixture BJ-04 (đơn SO-260827-18) không trùng đơn nào của BJ-05 (SO-260827-21 / -24) → không đi được "đơn → giữ → lấy" cho `SC_journey_3`; HSD lô DH2507 ở BJ-05 "30/06/2027", ở BJ-02 (chặng 2) "30/11/2026" |
| 10 | Mã | 029 `UNKNOWN` tự dựng nút handoff thay vì gọi `k3Unknown`; `deniedBody` / `loadingBody` / `ds24Result` riêng thay K1 / K4; `bj05ReadOnlyListRow`, `bj05Link` không còn chỗ dùng sau khi gộp 027 |

### 0.4 Đề xuất

**Luồng mới**

```text
Hub → "Lấy hàng" → 025 Đơn cần lấy hàng (K6: chip có số "Cần lấy · Chờ bàn giao · Đang chờ"; web bảng)
  ─đơn đang lấy→ 026 Hàng cần lấy (gộp 027): mỗi lô một dòng "Lô · HSD · cần lấy", nút "Lấy đủ"; sheet chỉ khi lấy thiếu / đổi lô
      ─"Xem giữ hàng"→ 021 (BJ-04, chỉ xem) ─"Lấy hàng"/quay lại→ 026
      ─"Rà soát bàn giao"→ 028 (giao cho ai; giao lần này / còn lại; sửa lượng chỉ khi đơn cho giao một phần)
          ─"Xác nhận đã bàn giao"→ 029 (K4) → "Lấy đơn tiếp theo" / "Tiếp tục phần còn lại" / "Về danh sách đơn cần lấy"
  ─đơn chờ bàn giao→ 028 thẳng (K6 "mở đúng bước đang dở"); quay lại → 026
  ─đơn đang chờ / đang xác minh→ dòng tắt (giữ quy tắc SCR-025 v2.7.3)
```

*SCR-025 Đơn cần lấy hàng* — **dựng K6** (mục 4.1)

1. Tiêu đề "Đơn cần lấy hàng" + phụ "Từ đơn bán đã sẵn sàng xuất kho" (giữ). Ô tìm "Tìm mã đơn hoặc khách hàng" (giữ).
2. Chip có số: "Tất cả" · "Cần lấy" (giữ) · **"Chờ bàn giao" (mới)** · "Đang chờ" (giữ). "Cần lấy" = chưa lấy + đang lấy; "Chờ bàn giao" = đã lấy đủ phần cần giao (badge "Chờ bàn giao" giữ chữ); "Đang chờ" = chờ đơn bán. Đơn "Đang xác minh bàn giao" chỉ ở "Tất cả" (SCR-025 v3.9.3).
3. Dòng iPhone: tiêu đề mã đơn; phụ "{khách} · {n} mặt hàng" **(mới — thay "· Kho chính": một kho thì kho không giúp chọn)**; bên phải badge tình trạng (giữ chữ `io05OrderStatus`). Dòng chờ / đang xác minh: cùng hình, `Disabled` (giữ).
4. Web (K7): bảng Đơn · Khách hàng · Mặt hàng · "Đã lấy" ("{a}/{b} mặt hàng", **mới**) · Tình trạng.
5. `EMPTY` → `k1Empty` "Chưa có đơn cần xử lý" / "Các đơn cần lấy hoặc đang chờ đơn bán xử lý sẽ xuất hiện tại đây." (giữ); `FILTER_EMPTY` → `k1Empty` "Không tìm thấy đơn phù hợp" / "Thử mã đơn, tên khách hàng hoặc đổi bộ lọc." (giữ) + "Xem tất cả" (chữ CAP-01); `LOADING` → `k1Loading`; `PERMISSION_DENIED` → `k1Denied({ what:"Bạn chưa có quyền lấy và bàn giao hàng" (mới), next:"Liên hệ chủ cửa hàng để được cấp quyền." (mới) })` — dùng cho mọi màn 025…029.

*SCR-026 Hàng cần lấy* (gộp SCR-027 — vấn đề 1, 2, 3)

6. Tiêu đề "Hàng cần lấy" (giữ); phụ "{đơn} · {khách}" (thay khối "Thông tin đơn" — kho và chính sách giao một phần chuyển xuống khối "Tóm tắt" ở web / một dòng ngữ cảnh ở iPhone).
7. Thanh tiến độ mảnh (`.bj02-progress` của BJ-02) **"Đã lấy đủ {a}/{b} mặt hàng" (mới, theo mẫu BJ-02 "Đã xử lý {a}/{b} mặt hàng")**.
8. iPhone: mỗi mặt hàng một nhóm — dòng đầu tên + "{mã} · Cần {n} {ĐVT}" **(mới)**; dưới là **mỗi lô phân bổ một dòng**: "Lô {mã}" (giữ) · phụ "HSD {hsd} · Lấy {n} {ĐVT}" **(mới; HSD theo độ chính xác của lô: "30/11/2026" / "09/2027" / "2027")**; bên phải: chưa đủ → nút **"Lấy đủ" (mới)** (đặt `pickedQty = allocatedQty`, một chạm, toast không cần); đủ → badge "Đã lấy đủ" (giữ); thiếu → "Đã lấy {p}/{n}" **(mới)** + badge "Đã lấy một phần" (giữ). Mặt hàng không theo lô: một dòng "Không theo lô" (giữ). Chạm vào dòng (ngoài nút) → sheet hiện có: tiêu đề "Lô {mã}", "Đã lấy" (giữ), "Tối đa {n} {ĐVT}" (giữ), "Đổi lô" (giữ), "Cập nhật" (giữ) — **lưu ngay**, bỏ bước "Lưu lượng đã lấy".
9. Web (K7, `k7Split({ wideMain:true })`): trái bảng Sản phẩm · Lô · HSD · Cần lấy · Đã lấy (`k7EditCell`, sửa tại dòng) · cột nút ("Lấy đủ" / badge); liên kết "Đổi lô" (giữ) cuối dòng mở hộp thoại "Chọn lô thay thế" (giữ). Phải: khối "Tóm tắt" (chữ BJ-03) — Khách hàng · Kho · "Giao một phần" **(mới)** "Được" / "Không" **(mới)** + liên kết "Xem giữ hàng" (mục 13).
10. Đổi lô (sheet / hộp thoại "Chọn lô thay thế", giữ chữ): mỗi lô thay thế là `dsChoiceRow` "Lô {mã}" + "HSD {hsd} · Có thể lấy {n} {ĐVT}" (giữ); "Lý do đổi lô *" (giữ); "Dùng lô này" (giữ). Đã cầm hàng lô cũ → dòng lô hiện banner nhỏ "Cần điều chỉnh hàng đang cầm" + "Trả {n} {ĐVT} lô {cũ}; lấy lại {n} {ĐVT} lô {mới}." (giữ) và nút "Xác nhận đã điều chỉnh hàng" (giữ) ngay trên dòng (không phải mở sheet).
11. Chân "Rà soát bàn giao" (giữ) + **dòng lý do khi tắt** (khuôn chân có lý do của BJ-02, mục 4.1): "Lấy ít nhất một mặt hàng" **(mới)**; đơn không cho giao một phần: "Đơn này yêu cầu giao đủ · còn {n} mặt hàng chưa lấy đủ" **(mới; vế đầu là chữ banner giữ)**; chờ điều chỉnh lô: "Xác nhận điều chỉnh lô trước khi bàn giao" **(mới)**. Bỏ hai đoạn ghi chú rời; giữ một dòng "Tồn vật lý chỉ giảm khi xác nhận bàn giao." (giữ) dưới bảng.
12. `SHORTAGE` / đơn chờ: banner "Chờ đơn bán xử lý" + "Đơn chưa đủ hàng để tiếp tục. Kho không tự đổi kho hoặc giảm lượng của đơn." (giữ); dòng chỉ đọc, không nút "Lấy đủ", không chân. `VERIFYING`: banner "Đang xác minh bàn giao" (giữ), như trên. `STALE_RECOVERED`: banner "Danh sách lô đã thay đổi" / "Kiểm lại lô hiện hành trước khi lưu lượng đã lấy." (giữ, chuyển từ 027) + dòng điều chỉnh như điểm 10. `LOADING` / `PERMISSION_DENIED` → K1.
13. SCR-027 → **RETIRED** ("Bỏ từ v5.11.0", gộp vào SCR-026); alias `screenAliases` 027 → 026 (link cũ mở 026 của đơn hiện tại).

*SCR-028 Rà soát bàn giao* (vấn đề 4)

14. Thứ tự: banner chặn (nếu có) → **"Giao cho" (mới)** `dsSegmented` **"Khách nhận tại quầy" (mới)** | **"Đơn vị vận chuyển" (mới)** (mặc định "Khách nhận tại quầy"; ghi vào bằng chứng bàn giao — UC-05-03 BF-03) → "Bàn giao lần này" (giữ): **"Giao lần này" (mới) "{n} mặt hàng"**, **"Còn lại sau lần này" (mới) "{m} mặt hàng"** (thay "Trong lần này" / "Chưa hoàn tất" / "dòng hàng") → bảng Sản phẩm · Lô · Đã lấy · "Lượng thực giao" (giữ) → "Xác nhận khi hàng đã giao thực tế. Tồn vật lý chỉ giảm sau bước này." (giữ).
15. `READY` (đơn **không** cho giao một phần, đã lấy đủ): cột "Lượng thực giao" chỉ đọc = đã lấy. `PARTIAL_ALLOWED`: ô sửa `k7EditCell` "Tối đa {n} {ĐVT}" (giữ), lỗi "Lượng bàn giao không được vượt lượng đã lấy nhưng chưa bàn giao của từng lô." (giữ). `PARTIAL_BLOCKED`: banner lỗi "Đơn này yêu cầu giao đủ" + "Chưa thể bàn giao một phần. Phần thiếu phải được đơn bán xử lý trước." (giữ), chân tắt kèm lý do. `SOURCE_CHANGED` → `k1Stale({ title:"Thông tin lấy hàng đã thay đổi", description:"Không thể dùng bản rà soát hiện tại. Hãy xem lại hàng cần lấy đã được cập nhật.", actionLabel:"Xem hàng cần lấy đã cập nhật" })` (giữ cả ba chữ).
16. Web: `k7Split` — trái bảng; phải "Giao cho" + khối "Bàn giao lần này"; chân là thanh nút bên phải "Xác nhận đã bàn giao" (giữ). iPhone: xếp dọc theo điểm 14, bảng thành thẻ.

*SCR-029 Kết quả bàn giao* (K4 — vấn đề 5)

17. `COMPLETED` / `PARTIAL_COMPLETED`: `k4Result({ screenTitle:"Kết quả bàn giao", title:"Đã bàn giao toàn bộ" | "Đã bàn giao một phần", description: giữ hai câu hiện có })`; `facts`: Đơn · Khách hàng · "Giao cho" · "Bàn giao lúc" (**điền thật**, `confirmedAt`) · **"Người bàn giao" (mới)**; liên kết "Xem {n} dòng hàng" (chữ BJ-02) mở sheet hai phần "Bàn giao thực tế" / "Còn lại" (giữ).
18. Bước tiếp: toàn bộ — phụ "Về danh sách đơn cần lấy" (giữ) | chính **"Lấy đơn tiếp theo" (mới)** (mở 026 của đơn "Cần lấy" kế tiếp; không còn đơn → chỉ một nút "Về danh sách đơn cần lấy"); một phần — phụ "Về danh sách đơn cần lấy" | chính "Tiếp tục phần còn lại" (giữ).
19. `UNKNOWN` / `COMMIT_UNKNOWN` → `k3Unknown({ operation:"Bàn giao hàng" (mới), scope:"{đơn} · {khách}", ref: operationId, sentAt, safe:"Không gửi lại bàn giao. Chuyển đúng lần bàn giao này sang xác minh." (mới, rút từ câu cũ), sourceFlow:"UIF-05" })`; giữ hành vi khoá đơn (`io05MarkUnknown`, `onUnknownHandoff["UIF-05"]`). `REJECTED_EXECUTION` → K4 cảnh báo "Chưa thể bàn giao" + câu giữ + "Xem hàng cần lấy đã cập nhật" (giữ). `PERMISSION_DENIED` → `k1Denied` (điểm 5).

*SCR-021 Giữ hàng theo đơn* (BJ-04 — vấn đề 8, 9)

20. Tiêu đề "Giữ hàng theo đơn" (giữ); phụ "Đơn {mã} · {khách}" (thay "Đơn {mã}"). Bỏ khối "Thông tin đơn": iPhone một dòng ngữ cảnh "{kho} · Đã xác nhận · Có giữ hàng" (giữ chữ), web vào khối "Tóm tắt".
21. Dải số một hàng (`cf12Strip` của BJ-12): **"{a} đang giữ · {b} thiếu · {c} đã xong" (mới)**. Banner "Chưa giữ đủ" / "{n} dòng còn thiếu. Đơn bán sẽ quyết định bước tiếp theo." (giữ) và "Không còn hàng đang giữ cho đơn này." (giữ) như hiện có.
22. Web: `k7Table` Sản phẩm · **"Cần giữ" (mới)** · "Đang giữ" (giữ) · "Đã bàn giao" (giữ) · **"Thiếu" (mới)** · Tình trạng. iPhone: dòng tiêu đề = tên sản phẩm (bỏ "· mã"), phụ "{mã} · Đang giữ {h}/{r} {ĐVT}" **(mới, thay "Cần giữ còn lại … · Đang giữ …")**, combo thêm "· {n} {ĐVT} theo combo" (giữ); bên phải badge "Thiếu {n} {ĐVT}" / "Đã bàn giao" / "Đã giải phóng" (giữ) hoặc **"Giữ đủ" (mới)**.
23. Lối ra: đơn có trong hàng đợi lấy hàng và đang "Cần lấy" → chân **"Lấy hàng" (chữ nút nhanh Hub)** → `applyEntry("UIF-05", "order-task")` mở 026 của đúng đơn. Vào từ 026 ("Xem giữ hàng") → quay lại về 026. Vào từ ngữ cảnh đơn (Theme 5, `entry=order-context`) → quay lại giữ toast "Quay về đơn bán {mã}" (giữ).
24. `LOADING` → `k1Loading`; `PERMISSION_DENIED` → `k1Denied({ what:"Bạn chưa có quyền xem giữ hàng" (mới), next:"Liên hệ chủ cửa hàng để được cấp quyền." })`.
25. **Số liệu lấy từ BJ-05** cho đơn có trong hàng đợi (mục 3): cần giữ = lượng đơn; đã bàn giao = `deliveredQty`; đang giữ = phân bổ − đã bàn giao; thiếu = cần − đã bàn giao − đang giữ. Bàn giao xong ở 029 → mở lại 021 thấy ngay "Đã bàn giao".

### 0.5 Trạng thái (sau thiết kế lại)

| Màn | Trạng thái | Hiện gì | Làm được gì | Lối ra |
|---|---|---|---|---|
| 025 | READY | K6: chip có số, danh sách / bảng | lọc, tìm, mở đơn (đúng bước) | Về Kho |
| 025 | EMPTY / FILTER_EMPTY | `k1Empty` | "Xem tất cả" (FILTER_EMPTY) | Về Kho |
| 025…029 | LOADING | `k1Loading` | — | — |
| 025…029 | PERMISSION_DENIED | `k1Denied` | — | "Về Kho" |
| 026 | READY | tiến độ, mặt hàng → lô (HSD, cần lấy) | "Lấy đủ", sửa lượng, đổi lô, "Xem giữ hàng", "Rà soát bàn giao" | Quay lại |
| 026 | STALE_RECOVERED | banner lô đã thay đổi + dòng điều chỉnh | "Xác nhận đã điều chỉnh hàng" | Quay lại |
| 026 | SHORTAGE (đơn chờ) / VERIFYING | banner, dòng chỉ đọc | "Xem giữ hàng" | Quay lại |
| 028 | READY | giao cho, lần này / còn lại, bảng chỉ đọc | chọn "Giao cho", "Xác nhận đã bàn giao" | Quay lại |
| 028 | PARTIAL_ALLOWED | như READY + ô sửa lượng | sửa lượng thực giao | Quay lại |
| 028 | PARTIAL_BLOCKED | banner lỗi, chân tắt có lý do | — | Quay lại |
| 028 | SOURCE_CHANGED | `k1Stale` | "Xem hàng cần lấy đã cập nhật" | Quay lại |
| 029 | COMPLETED / PARTIAL_COMPLETED | K4 | "Lấy đơn tiếp theo" / "Tiếp tục phần còn lại", "Về danh sách đơn cần lấy" | Về Kho |
| 029 | REJECTED_EXECUTION | K4 cảnh báo | "Xem hàng cần lấy đã cập nhật" | Về Kho |
| 029 | UNKNOWN / COMMIT_UNKNOWN | K3 | "Chuyển sang xác minh" | "Về Kho" |
| 021 | READY | dải số, banner, bảng / danh sách | "Lấy hàng" (khi có) | Quay lại / về đơn bán |
| 021 | LOADING / PERMISSION_DENIED | K1 | — | Quay lại |

Alias: 027 → 026.

### 0.6 Khuôn dùng lại và khuôn dựng mới

- **Dựng K6** `k6TaskList` (mục 4.1) — BJ-06 (030), BJ-07, 08, 11, 12, 14, 16 dùng lại.
- Dùng lại: K1 (`k1Loading`, `k1Denied`, `k1Empty`, `k1Stale`, `k1ExitAttr`), K3 (`k3Unknown`), K4 (`k4Result`, `k4Footer`), K7 (`k7Split`, `k7Table`, `k7EditCell`, `k7FilterChips`, lớp `k7-wide`), `dsSegmented` ("Giao cho"), `dsChoiceRow` (lô thay thế), `cf12Strip` (021), thanh tiến độ mảnh của BJ-02, sheet / hộp thoại của BJ-12.
- **Chuyển sang dùng chung:** chân có dòng lý do (`bj02Footer`) → `shared-patterns.js` `k4ReasonFooter({ label, attr, disabled, reason })`; `bj02Footer` gọi lại hàm này (HTML BJ-02 không đổi).
- Không thành phần DS mới ngoài K6.

### 0.7 Không đổi

Quy tắc ở 0.1; cách tính `io05LinePicked`, `io05LineRemaining`, `io05CanReview`, `io05HandoverInvalid`, `io05ApplyHandover` (gồm bằng chứng bàn giao, phiên bản nguồn / phân bổ), `io05ApplyStaleRecovery` (chỉ đổi chỗ gọi — mục 4.2), `onUnknownHandoff["UIF-05"]`, `bumpIO05Source`. Chữ giữ: tiêu đề 021 / 025 / 026 / 028 / 029, chip "Tất cả" / "Cần lấy" / "Đang chờ", badge `io05OrderStatus` / `io05LineStatus`, "Chọn lô thay thế", "Lý do đổi lô *", "Dùng lô này", "Đổi lô", "Đã lấy", "Cập nhật", "Cần điều chỉnh hàng đang cầm", "Xác nhận đã điều chỉnh hàng", "Rà soát bàn giao", "Lượng thực giao", "Xác nhận đã bàn giao", "Đã bàn giao toàn bộ", "Đã bàn giao một phần", "Tiếp tục phần còn lại", "Về danh sách đơn cần lấy", "Chưa thể bàn giao", "Chờ đơn bán xử lý", "Đang xác minh bàn giao", "Chưa giữ đủ", "Thiếu {n} {ĐVT}".

### 0.8 Kiểm (bước D)

- Golden **mobile** được khác: `UIF-04_*`, `UIF-05_*`, `SC_bj04*`, `SC_bj05_*`, `SC_quick_UIF-05_*`, `SC_entry_UIF-04_*`, `SC_entry_UIF-05_*`, `SC_bj17_from_bj05_*` (bước 0 là 029 `UNKNOWN` theo K3; bước sau ở BJ-17 **phải khớp**). Ca BJ-02 phải khớp (đổi `bj02Footer` chỉ là gọi lại). Ca khác khớp mốc `tools/.golden-chang2`.
- Golden **web** được khác: `UIF-04_*@web`, `UIF-05_*@web` + kịch bản web mới; ca khác khớp `tools/.golden-chang2-web`.
- Kịch bản (mục 5.3): sửa `SC_bj05_list`, `SC_bj05_pick`, `SC_bj05_override`, `SC_bj05_handover`, `SC_bj05_waiting`, `SC_bj04`; thêm `SC_bj05_quick_pick`, `SC_bj05_ready_handover`, `SC_bj05_blocked`, `SC_bj05_stale`, `SC_bj05_next_order`, `SC_bj04_from_pick`, `SC_bj04_after_handover`.

### 0.9 Ước lượng C–E

~2 ngày: C0 fixture ~0,2; C1 025 (K6) / 026 (gộp 027) / 028 / 029 ~1,1; C2 021 + liên kết ~0,3; D ~0,2; E ~0,25. (T7-P mục 8.2 ghi 1,5 khi còn chia thiết bị chính / phụ; thêm K6 và bố cục web cho 5 màn.)

### 0.10 Đã chốt khi duyệt brief (2026-10-24): **mọi điểm theo cột "Đề xuất"**

| # | Điểm | Đề xuất | Phương án khác |
|---|---|---|---|
| a | Gộp 027 vào 026 | **Gộp**: mỗi lô một dòng có "Lấy đủ"; sheet chỉ khi lấy thiếu / đổi lô; bỏ "Lưu lượng đã lấy" (lưu ngay từng lô) | Giữ 027 riêng, chỉ thêm "Lấy đủ" và HSD ở 027 |
| b | "Giao cho" ở 028 | **Thêm** thanh chọn "Khách nhận tại quầy" \| "Đơn vị vận chuyển" (UC-05-03 BF-03 có "người/đơn vị nhận"; prototype đang thiếu) | Không thêm; ghi lệch spec vào mục 13 để chốt ở 7.3 |
| c | Lối 026 ↔ 021 | **Có**: "Xem giữ hàng" ở 026 (khối "Tóm tắt" web / liên kết dưới tiến độ iPhone) và "Lấy hàng" ở 021 — nhân viên thấy vì sao đơn thiếu ngay lúc lấy; là đường duy nhất tới BJ-04 trong prototype (Theme 5 chưa có) | 021 chỉ mở từ ngữ cảnh đơn (Theme 5); `SC_journey_3` mở 021 bằng `entry=order-context` |
| d | Đơn "Chờ bàn giao" bấm vào | **Mở thẳng 028** (K6: mở đúng bước đang dở); quay lại về 026 | Luôn mở 026 |
| e | Quét mã khi lấy hàng | **Không làm ở chặng này** (đơn mẫu 2 mặt hàng; BJ-01 / BJ-02 đã có quét để tìm) — ghi mục 9 | Thêm nút quét ở 026: quét bao bì → nhảy tới dòng lô, sai sản phẩm thì báo |
| f | "Lấy đơn tiếp theo" ở 029 | **Có** (nhân viên lấy nhiều đơn liền) | Chỉ "Về danh sách đơn cần lấy" |

---

## 1. Mục tiêu

1. Lấy đủ một lô là **một chạm**, thấy HSD và lô gợi ý ngay trên danh sách; chỉ gõ số khi lấy thiếu.
2. Rà soát bàn giao nói rõ giao cho ai, giao bao nhiêu, còn lại bao nhiêu; kết quả có thời điểm và bước tiếp.
3. BJ-04 không còn ngõ cụt: đi được đơn → giữ hàng → lấy hàng và ngược lại.
4. K6 dựng xong, mô tả ở T7-P mục 5, BJ-06 dùng được ngay.
5. Mọi trạng thái 0.5 dựng khác nhau và có lối ra, ở cả hai khung.

## 2. Chuẩn bị

1. Chặng 2 đã review và commit (T7-P mục 14). Nếu review chốt đề xuất "lối về Kho ở K4" / "bẫy focus cho mọi sheet trong `core.js`" (T7-P mục 13, dòng cuối) thì làm theo cách đã chốt ở đây, không làm riêng cho BJ-05.
2. Mốc = `tools/.golden-chang2` / `tools/.golden-chang2-web`. Nếu review chặng 2 sửa code sau khi chụp mốc → chụp lại ở HEAD, so khớp, đặt tên `tools/.golden-bj05-base` / `-web-base`.
3. GitNexus (CLAUDE.md): `impact` hướng upstream cho `render025BJ05`…`render029BJ05`, `render021BJ04`, `io05ApplyStaleRecovery`, `io05ApplyHandover`, `bj02Footer`, `enterFlow` / `applyEntry` (nếu sửa); báo mức rủi ro vào mục 11. Chỉ mục cũ thì `node .gitnexus/run.cjs analyze` trước; trả lại `CLAUDE.md` / `AGENTS.md` nếu `analyze` ghi đè số ký hiệu.
4. Máy chủ `python3 -m http.server 8765 --bind 127.0.0.1 &` trong `html/`.

## 3. Bước C0 — fixture chung chặng 3 (commit 1, cùng C1)

Mục đích: `SC_journey_3` đi "đơn → giữ → lấy → bàn giao → khách trả" trên cùng sản phẩm / lô với chặng 2; BJ-06 (plan sau) đọc lại cùng tên lô và HSD.

| Fixture | Hiện tại | Sau C0 |
|---|---|---|
| HSD lô Nobivac DHPPi (`bj05.js` `eligibleLots`) | DH2507 "30/06/2027" (DAY) | DH2507 **"30/11/2026"** (DAY — như BJ-02 chặng 2); DH2509 "09/2027" (MONTH), DH2511 "2027" (YEAR) giữ |
| Đơn của BJ-04 (`bj04.js`) | Một đơn tĩnh SO-260827-18 | `bj04OrderModel(orderId)`: đơn có trong `io05Orders` → dựng từ BJ-05 (0.4 điểm 25); SO-260827-18 giữ làm đơn tĩnh (đủ ca combo, đã bàn giao, đã giải phóng) cho `?uif=UIF-04` mặc định |
| Đơn "Chờ bàn giao" | Không có | Thêm **SO-260827-22** · "Trang trại Phú Lợi" · Kho chính · `partialHandoverAllowed:false` · một dòng Vitamin ADE (SP-000099, chai) 6, không theo lô, đã lấy 6 — để chip "Chờ bàn giao" có dòng và kiểm `READY` của 028 (giao đủ, chỉ đọc) |
| Người bàn giao | `IO05_ACTOR` "Nguyễn Văn An" | giữ (cùng người lập phiếu nhận ở chặng 2) |
| Thời điểm bàn giao | "16/09/2026 13:08" chỉ trong kết quả | giữ; 029 đọc `io05LastResult.confirmedAt`, ảnh trạng thái mở thẳng dùng cùng giá trị (hết "—") |

Không sửa BJ-01 (SCR-003 vẫn ghi giữ hàng 12 hộp của SO-260817-08 — lệch nhỏ, ghi mục 11; sửa ở Giai đoạn 3 nếu cần).

## 4. Bước C1 — BJ-05 + K6 (commit 1)

### 4.1 Khuôn dùng chung (`app/shared-patterns.js`)

1. **K6** `k6TaskList({ search, filters, columns, rows, mobileRow, rowAttr, empty, filterEmpty })` → HTML thân màn:
   - `search: { value, attr, placeholder }` → `ds24Search`; `filters: { items:[[id, label, count]], selected, attrName }` → `k7FilterChips`.
   - `rows`: mảng đã lọc; mỗi dòng có `status: { label, tone }`, `disabled` (dòng chờ / đang xác minh: cùng hình, `aria-disabled="true"`, không mở). `columns` / `mobileRow` / `rowAttr` truyền thẳng `k7Table`; `mobileRow` mặc định = `ds24ListRow` Navigation, bên phải badge `status`.
   - `empty` (không có việc nào) → `k1Empty`; `filterEmpty` (lọc / tìm ra rỗng) → `k1Empty` + "Xem tất cả" (`actionAttr` do BJ truyền).
   - Quy tắc: BJ quyết bước mở tiếp của từng dòng qua `rowAttr` (K6 "mở tiếp đúng bước đang dở"); K6 không biết màn đích.
2. `k4ReasonFooter({ label, attr, disabled, reason })`: chép HTML của `bj02Footer`, `bj02Footer(label, attr, disabled, reason)` gọi lại (kiểm golden BJ-02 khớp).

### 4.2 Dữ liệu và trạng thái (`app/bj05.js`)

1. C0 (mục 3).
2. `io05OrderStatus` thêm phân nhóm chip: `io05Queue(order)` → `"PICK"` (Cần lấy hàng / Đang lấy hàng) · `"HANDOVER"` (Chờ bàn giao) · `"WAITING"` · `"VERIFYING"`. Chip "Cần lấy" = `PICK`, "Chờ bàn giao" = `HANDOVER`, "Đang chờ" = `WAITING`; đếm theo cùng hàm.
3. **Rò trạng thái (vấn đề 3):** tìm vì sao ảnh `027_READY` thấy "Lô DH2511 · Đã đổi" (mở `?uif=UIF-05&screen=SCR-026&state=STALE_RECOVERED` rồi `READY` trong cùng trang?). Sửa để mỗi trạng thái dựng từ fixture gốc: giữ `io05InitialOrders = structuredClone(io05Orders)` lúc nạp; `io05ApplyStaleRecovery` chỉ chạy khi trạng thái là `STALE_RECOVERED`; đổi sang trạng thái khác bằng bộ chọn trạng thái của harness → khôi phục đơn từ bản gốc (không khôi phục khi đang đi trong luồng thật).
4. `io05PickFull(allocationId)`: `pickedQty = allocatedQty` (không vượt, không áp khi `io05CorrectionPending`), `io05HandoverByAllocation[id]` cập nhật như `update-pick-allocation`.
5. Người nhận: `io05Recipient = "COUNTER" | "CARRIER"` (mặc định `COUNTER`), ghi vào `evidence.recipient` trong `io05ApplyHandover` (thêm trường, không đổi trường cũ).
6. `io05NextActionableOrder()`: đơn `PICK` đầu tiên khác đơn vừa giao.

### 4.3 Màn

| Màn | Việc |
|---|---|
| Chung | `appShell({ …, extraClass:"k7-wide" })`; K1 cho `LOADING` / `PERMISSION_DENIED` (thay `deniedBody` / `loadingBody`); nhãn sự kiện `data-io05-*` giữ, thêm `data-io05-pick-full`, `data-io05-recipient`, `data-io05-go-reservation`, `data-io05-next-order`; nút "Chuyển sang xác minh" do `k3Unknown` dựng (vẫn `data-v350-action="handoff-unknown"` mà `bj17.js:142` nghe — không đổi nhãn, kiểm `SC_bj17_from_bj05`) |
| 025 | `k6TaskList` theo 0.4 điểm 1–5; `rowAttr`: đơn `HANDOVER` → `data-io05-order` + `data-io05-target="SCR-028"`, còn lại `SCR-026` |
| 026 | 0.4 điểm 6–13: nhóm mặt hàng → dòng lô (iPhone), `k7Split({ wideMain:true })` + `k7Table` + `k7EditCell` (web); sheet sửa lượng / đổi lô (sheet hiện có, sửa chữ theo 0.4) thành hộp thoại giữa màn ở web; chân `k4ReasonFooter` |
| 027 | Xoá `render027BJ05`, `bj05ReadOnlyListRow`, `bj05Link` (nếu hết chỗ dùng); `screenAliases["UIF-05"] = Object.assign(screenAliases["UIF-05"] \|\| {}, { "SCR-027": "SCR-026" })` + dòng áp alias lúc nạp như `bj13.js:177–181`; xoá khỏi bảng màn của UIF-05 trong `core.js` (dòng 34) và `manifest.json` (đánh dấu retired như SCR-017 / 064) |
| 028 | 0.4 điểm 14–16; `READY` khác `PARTIAL_ALLOWED` (ô sửa chỉ khi đơn cho giao một phần) |
| 029 | 0.4 điểm 17–19; `k4Result` / `k3Unknown`; sheet "Xem {n} dòng hàng" dùng khuôn sheet BJ-03 019 |
| Hub | `WORKSPACES.movement` UIF-05 giữ; không đổi Home |

### 4.4 Sự kiện

1. `data-io05-pick-full` → `io05PickFull`, `renderAppScreen()`; focus giữ ở dòng (không nhảy đầu trang).
2. Ô `k7EditCell` "Đã lấy" (web) → như `update-pick-allocation` (kiểm 0…`allocatedQty`, lỗi dưới ô "Số lượng đã lấy không được vượt {n} {ĐVT}." giữ chữ).
3. `data-io05-order` với `data-io05-target="SCR-028"` → `io05ResetHandover`, đặt trạng thái 028 như `review-handover`, `navigate("SCR-028")`; `onPrevious["UIF-05"]` từ 028 → 026.
4. `data-io05-recipient` → `io05Recipient`, render.
5. `data-io05-go-reservation` → `applyEntry("UIF-04", "order-context")` với `bj04OrderId = io05SelectedOrderId`, đánh dấu `bj04ReturnTo = "UIF-05"` (mục 5.2).
6. `data-io05-next-order` → chọn `io05NextActionableOrder()`, `navigate("SCR-026")`.
7. Sau mọi thay đổi lượng: không toast (thấy ngay trên dòng); đổi lô giữ toast "Đã cập nhật lô lấy hàng".

## 5. Bước C2 — BJ-04, liên kết, golden (commit 2, cùng D)

### 5.1 SCR-021 (`app/bj04.js`)

1. `bj04OrderModel(orderId)` (mục 3); `bj04OrderId` mặc định SO-260827-18; `entry=order-context` không có đơn chọn trước thì giữ SO-260827-18.
2. Dựng theo 0.4 điểm 20–24: `cf12Strip`, `k7Table` (`mobileRow` = `ds24ListRow` Status), banner giữ, chân "Lấy hàng" khi đơn có trong `io05Orders` và `io05Queue` = `PICK` / `HANDOVER`.
3. Gộp CSS `v396-reservation-*` về khối BJ-04 trong `styles/screens.css`, bỏ `!important` không còn đối thủ (T7-P mục 4.4); đổi `data-v396-reservation-line` → `data-bj04-line` (sửa `tools/golden.mjs` nếu có dùng).

### 5.2 Sự kiện và điều hướng

1. "Lấy hàng" (`data-bj04-go-pick`) → `io05SelectedOrderId = bj04OrderId`; `applyEntry("UIF-05", "order-task")`.
2. Quay lại: `bj04ReturnTo === "UIF-05"` → `applyEntry("UIF-05", "order-task")` về 026 của đơn đó; còn lại giữ toast "Quay về đơn bán {mã}".
3. Ở chế độ Toàn Theme 7, `applyEntry` giữ thanh bên / nút quay lại như BJ-03 → BJ-14 (`data-bj03-go-cost`); kiểm không quay về nhầm màn con Hub (bẫy đã gặp ở `SC_journey_2`, T7-P mục 13 dòng cuối).

### 5.3 Golden (`tools/golden.mjs`)

Sửa selector của các kịch bản hiện có (027 đã gộp: `SC_bj05_pick`, `SC_bj05_override` bỏ bước `line`, mở sheet từ dòng lô ở 026). Thêm (`V5` = `'?uif=UIF-05&screen='`):

| Kịch bản | Bắt đầu | Bước |
|---|---|---|
| `SC_bj05_quick_pick` | `V5 + 'SCR-025'` | SO-260827-21 → "Lấy đủ" DH2509 → "Lấy đủ" Găng tay → "Rà soát bàn giao" |
| `SC_bj05_ready_handover` | `V5 + 'SCR-025'` | chip "Chờ bàn giao" → SO-260827-22 → 028 (chỉ đọc) → "Đơn vị vận chuyển" → "Xác nhận đã bàn giao" → 029 |
| `SC_bj05_blocked` | `V5 + 'SCR-028&state=PARTIAL_BLOCKED'` | — (chân tắt, dòng lý do) |
| `SC_bj05_stale` | `V5 + 'SCR-026&state=STALE_RECOVERED'` | dòng DH2511 → "Đã lấy" 4 → "Cập nhật" → "Xác nhận đã điều chỉnh hàng" |
| `SC_bj05_next_order` | `V5 + 'SCR-025'` | SO-260827-22 → xác nhận → 029 → "Lấy đơn tiếp theo" → 026 SO-260827-21 |
| `SC_bj04_from_pick` | `V5 + 'SCR-025'` | SO-260827-21 → "Xem giữ hàng" → 021 → "Lấy hàng" → 026 |
| `SC_bj04_after_handover` | `V5 + 'SCR-025'` | SO-260827-22 → bàn giao → "Về danh sách đơn cần lấy" → (gọi `applyEntry` 021 cho SO-260827-22) → "Không còn hàng đang giữ cho đơn này." |

`WEB_SCENARIOS` thêm `SC_bj05_quick_pick`, `SC_bj05_ready_handover`, `SC_bj05_override`, `SC_bj04_from_pick`. Chỉ dùng `data-io05-*` / `data-bj04-*` / `data-theme-*`, không chọn theo chữ.

## 6. Bước D — kiểm

1. Golden mobile / web so mốc mục 2: chỉ ca ở 0.8 khác; ghi mục 11. Mọi trạng thái 0.5 cho ảnh khác nhau (`diff` thân `.txt` trước dòng `@inspector`) — đặc biệt các cặp đang trùng: `028 READY` / `PARTIAL_ALLOWED`, `025 FILTER_EMPTY` / `READY`, và `026 STALE_RECOVERED` (thay `027`).
2. Bấm thử UIF-04, UIF-05 hai khung + Hub "Lấy hàng": 0 lỗi JS; `node --check app/*.js harness/*.js`.
3. **`/impeccable audit` phạm vi UIF-04 + UIF-05 — chặn commit E.** Chạy trên 025 (READY, FILTER_EMPTY), 026 (READY, STALE_RECOVERED, SHORTAGE, sheet sửa lượng, hộp thoại đổi lô), 028 (READY, PARTIAL_ALLOWED, PARTIAL_BLOCKED), 029 (COMPLETED, PARTIAL_COMPLETED, UNKNOWN), 021 (READY), ở cả hai khung. Đạt khi: chữ ≥ 4,5:1 (badge, chữ phụ HSD, dòng lý do ở chân); vùng chạm ≥ 44 × 44 ở iPhone (**nút "Lấy đủ" trong dòng** và `k7EditCell`); trạng thái "đã lấy đủ / thiếu" không chỉ phân biệt bằng màu (có chữ); web đi được bằng bàn phím (Tab qua chip → bảng → ô "Đã lấy" → "Lấy đủ" → "Đổi lô"; Enter mở / Esc đóng hộp thoại, focus về nút đã mở; Tab không thoát khỏi hộp thoại `aria-modal`); web không còn cột 402px; iPhone không bảng ép nhỏ, số không gãy dòng. Lỗi trong phạm vi: sửa ngay; ngoài phạm vi: ghi mục 11.
4. Gửi ảnh: 025 web + iPhone, 026 web + iPhone (READY, sau "Lấy đủ"), hộp thoại đổi lô web, 028 web, 029, 021 web + iPhone.
5. Mốc cho BJ-06: `tools/.golden-bj05-after` / `tools/.golden-bj05-web-after`.

## 7. Bước E — ghi lại (commit 3)

1. `CHANGELOG.md` `[5.11.0] — BJ-04 / BJ-05 thiết kế lại; K6`; phiên bản 5.11.0 (`manifest.json`, `harness/workbench.js`, badge `index.html`, nhãn inspector UIF-04 / UIF-05).
2. Viết lại theo `_TEMPLATE.md`: SCR-025, SCR-026 (gồm phần gộp từ 027, sheet sửa lượng, hộp thoại đổi lô), SCR-028, SCR-029, SCR-021; UIF-05 (sơ đồ mới: bỏ 027, lối 026 ↔ 021, "Chờ bàn giao" → 028), UIF-04 (lối vào từ 026, lối ra "Lấy hàng"). SCR-027 → `RETIRED.md` ("Bỏ từ v5.11.0", thay bằng SCR-026). Ghi chú SCR-020, 022–024 trong `INDEX.md` giữ "Chưa dựng".
3. T7-P mục 5: thêm dòng **K6 đã dựng** (hàm, tham số, quy tắc) vào bảng "Đã dựng ở …"; mục 6 nếu có thành phần mới; mục 9 BJ-04 / 05: khuôn "dựng K6; K1, K3, K4, K7" (thêm K1, K7).
4. `INDEX.md` 021, 025–029; T7-P mục 13 (chữ mới, gộp 027, "Giao cho"), mục 14: BJ-04 / 05 ✅.
5. `python3 tools/sync-registry.py`.

## 8. Thứ tự commit

1. C0 + C1 (fixture chung, K6, 025 / 026 / 028 / 029, `k4ReasonFooter`) — golden chỉ khác UIF-05 + `SC_quick_UIF-05` + `SC_bj17_from_bj05` bước 0.
2. C2 + D (021, liên kết 026 ↔ 021, golden mới, sửa sau audit).
3. E (tài liệu, phiên bản, registry).

Như chặng 2: nếu làm một lượt thì để chưa commit cho phiên review xem trước, chia commit sau review.

## 9. Không làm

- Sửa / giải phóng giữ hàng ở Kho (BJ-04 chỉ xem — spec).
- Quét mã khi lấy hàng (0.10 e).
- Màn SCR-020, 022–024 (giữ "Chưa dựng" trong `INDEX.md`).
- Chi tiết đơn bán của Theme 5 (021 vẫn giả lập lối vào `order-context`).
- Sửa BJ-01 cho khớp số giữ hàng (mục 3).

## 10. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| Gộp 027 làm vỡ kịch bản `SC_bj05_*` và `SC_bj17_from_bj05` | Sửa selector trước khi chụp; `SC_bj17_from_bj05` chỉ bước 0 được khác, bước BJ-17 phải khớp |
| "Lấy đủ" một chạm làm nhân viên bấm nhầm | Lượng đổi thấy ngay trên dòng, sửa lại bằng sheet; tồn không đổi tới khi bàn giao (BR-02) |
| Khôi phục fixture khi đổi trạng thái làm mất dữ liệu đang đi trong luồng | Chỉ khôi phục khi đổi bằng bộ chọn trạng thái của harness, không khi đi bằng nút trong màn |
| `applyEntry` giữa UIF-05 và UIF-04 về nhầm màn con Hub | Kiểm ở D bằng `SC_bj04_from_pick` cả hai khung, trong chế độ Toàn Theme 7 (`SC_journey_3` ở plan BJ-06) |
| K6 dựng theo nhu cầu BJ-05, chưa hợp BJ-06 (mở được dòng chờ) | Để `disabled` / `rowAttr` do BJ quyết; BJ-06 được chỉnh K6 (ghi CHANGELOG, chạy lại golden BJ-05) |

## 11. Ghi chú khi làm

**Làm xong 2026-10-24 (v5.11.0), chưa commit — để phiên review xem trước, chia commit sau review.** Mốc chặng 2 chưa commit nên dùng thẳng `tools/.golden-chang2` / `-web` (chụp 13:06, sau mọi sửa của chặng 2), không cần `-base`.

**GitNexus (CLI `node .gitnexus/run.cjs … --repo erp-sales-inventory`; MCP không có trong phiên này):** `impact` upstream — `render025BJ05`, `render026BJ05`, `render027BJ05`, `render028BJ05`, `render029BJ05`, `render021BJ04`, `io05ApplyStaleRecovery`, `io05ApplyHandover`, `bj02Footer`, `applyEntry`, `afterFlowRender`: **LOW**, 0 tiến trình ảnh hưởng (hàm prototype tĩnh, chỉ gọi qua `renderers[]` / sự kiện). `detect_changes` cả cây: 37 tệp, 239 ký hiệu (gồm cả phần chặng 2 chưa commit), 0 tiến trình, **low**; `CLAUDE.md` / `AGENTS.md` không đổi.

**Kết quả D:** golden mobile 1640 ca (mốc 1607), web 789 (mốc 762), 0 lỗi JS. Khác mốc **chỉ** ở: `UIF-04_*`, `UIF-05_*`, `SC_bj04*`, `SC_bj05_*`, `SC_quick_UIF-05_*`, `SC_entry_UIF-0[45]_*`, `SC_bj17_from_bj05_0` (bước 0; các bước BJ-17 khớp), **và `SC_ws_movement_1_2_item`** (plan 0.8 chưa liệt kê: dòng thứ 3 của workspace "movement" ở Hub là "Lấy hàng", mở cùng màn 025 mới). Ca BJ-02 khớp. Mọi cặp trạng thái trước đây trùng ảnh nay khác nhau (kiểm hash PNG + thân `.txt`, cả hai khung). Mốc cho BJ-06: `tools/.golden-bj05-after` / `tools/.golden-bj05-web-after`. Bấm thử bằng phím thật (CDP): Hub → "Lấy hàng" → đơn → "Xem giữ hàng" → quay lại → "Lấy hàng" → quay lại → về Kho đúng nơi (`SC_bj05_theme`, cả hai khung).

**Audit (`/impeccable audit`):** detector 0 phát hiện; đạt cả bảy tiêu chí mục 6.3 — chi tiết ở CHANGELOG 5.11.0. Lưu ý: nút web cao 40px theo quy ước K7 chung (chân 40px, nút bảng 40px), chỉ iPhone ép ≥ 44.

**Lệch so với plan / quyết định khi làm:**
1. **Chống rò trạng thái (4.2.3) làm ở `io05Seed`, không ở bộ chọn trạng thái của harness:** golden đặt trạng thái bằng `stateByScreen[...] = …; render()` (không qua nút harness), nên "khôi phục khi đổi bằng bộ chọn" không bắt được ca golden. Thay bằng: trạng thái màn khác với dấu "đã biết" (`io05ExpectedState`) = đặt từ ngoài → dựng lại đơn từ bản gốc + chuẩn bị đúng đơn cho trạng thái (026 `SHORTAGE` = SO-260827-24; 028 `READY` = SO-260827-22 không cho giao một phần; 029 `COMPLETED` / `PARTIAL_COMPLETED` = bàn giao mẫu). Đi bằng nút hoặc `navigate` (kể cả nút quay lại — đã sửa một lỗi mất dữ liệu khi mở 026 bằng `entry=order-task` rồi quay lại 025) không dựng lại.
2. **Nút quay lại ở 021 trong chế độ Toàn Theme 7:** `hub.js` `afterFlowRender` thay nút quay lại của màn đầu luồng bằng "Quay về Kho", nên 021 mở từ 026 vẫn về Hub. Thêm dấu `data-keep-back` (BJ-04 tự gắn khi `bj04ReturnTo` có giá trị) để Hub giữ nguyên nút.
3. **`k3Unknown` thêm `handoff: { operation, scope }`** (tùy chọn): chữ hiển thị theo plan ("Bàn giao hàng", "{đơn} · {khách}") nhưng giá trị gửi BJ-17 giữ mã nghiệp vụ và phạm vi cũ, để `SC_bj17_from_bj05` chỉ khác bước 0 như plan 0.8.
4. **"Xác nhận đã điều chỉnh hàng":** giữ quy tắc cũ (chỉ hiện khi đã nhập lại đủ lượng lấy lại); "Lấy đủ" không áp khi đang chờ điều chỉnh (4.2.4), nên lấy lại lô mới đi qua sheet "Đã lấy" như `SC_bj05_stale`. Có thể làm gọn hơn (một nút "Xác nhận đã điều chỉnh hàng" tự điền lượng) — để review quyết.
5. **Sheet "Đã lấy" đổi nghĩa lượng:** gõ số đã lấy **chưa bàn giao** (0…cần lấy còn lại), không phải số tích lũy như 027 cũ — cùng ý với cột "Cần lấy" sau bàn giao một phần.
6. **Web 026:** khối "Tóm tắt" hẹp 240px (không phải 320px của `k7-split--wide-main`) để bảng sáu cột vừa; trong bảng, "Đổi lô" và nút trạng thái xuống dòng trong ô cuối khi hẹp. Banner "Cần điều chỉnh hàng đang cầm" ở web nằm trên bảng (`k7-web-only`), ở iPhone nằm trên dòng lô.
7. **Fixture:** khách của SO-260827-18 (đơn tĩnh của BJ-04) thêm "Cửa hàng Thú y Hòa Bình" để có phụ "Đơn {mã} · {khách}".
8. **Không làm (đúng plan):** quét mã khi lấy hàng; sửa giữ hàng ở Kho; BJ-01 vẫn ghi giữ hàng 12 hộp cho SO-260817-08 (lệch nhỏ, sửa ở Giai đoạn 3 nếu cần).
9. **Chưa dọn:** các luật CSS `bj05-*` của 027 cũ không còn dùng (`.bj05-radio`, `.bj05-selection-row`, `.bj05-pick-lot-*`…) — chỉ bỏ `.v396-reservation-*` và `.bj04-context` / `.bj04-list-stack` theo plan 5.1; dọn phần còn lại cùng đợt rà CSS cuối Giai đoạn 2 (`golden usage`).
10. **Tài liệu spec còn nhắc SCR-027:** `UC-05-02`, `UC-05-04`, `00-use-case-map.md` (đã ghi vào T7-P mục 13, chốt ở 7.3); `PAT-NAV.md` đã sửa.


## 12. Chữ trên màn

| Vị trí | Chữ |
|---|---|
| 025 | chip "Chờ bàn giao" · "{khách} · {n} mặt hàng" · cột "Đơn", "Khách hàng", "Mặt hàng", "Đã lấy" ("{a}/{b} mặt hàng"), "Tình trạng" |
| 026 | "Đã lấy đủ {a}/{b} mặt hàng" · "{mã} · Cần {n} {ĐVT}" · "HSD {hsd} · Lấy {n} {ĐVT}" · "Lấy đủ" · "Đã lấy {p}/{n}" · "Giao một phần" "Được" / "Không" · "Xem giữ hàng" · cột "Sản phẩm", "Lô", "HSD", "Cần lấy", "Đã lấy" · lý do: "Lấy ít nhất một mặt hàng", "Đơn này yêu cầu giao đủ · còn {n} mặt hàng chưa lấy đủ", "Xác nhận điều chỉnh lô trước khi bàn giao" |
| 028 | "Giao cho" · "Khách nhận tại quầy" · "Đơn vị vận chuyển" · "Giao lần này" · "Còn lại sau lần này" · "{n} mặt hàng" |
| 029 | "Người bàn giao" · "Lấy đơn tiếp theo" · K3: "Bàn giao hàng" · "Không gửi lại bàn giao. Chuyển đúng lần bàn giao này sang xác minh." |
| 021 | "Đơn {mã} · {khách}" · "{a} đang giữ · {b} thiếu · {c} đã xong" · cột "Cần giữ", "Thiếu" · "{mã} · Đang giữ {h}/{r} {ĐVT}" · "Giữ đủ" · "Lấy hàng" (chữ Hub) |
| Không có quyền | "Bạn chưa có quyền lấy và bàn giao hàng" · "Bạn chưa có quyền xem giữ hàng" · "Liên hệ chủ cửa hàng để được cấp quyền." |

## 13. Review

Review chung chặng 3 (2026-10-24): **đạt có điều kiện** — xem [plan BJ-06 mục 12](T7-P-bj06-hang-khach-tra.md#12-review). Phần BJ-04 / 05: **R1** (dòng lô lấy một phần tràn thẻ ở iPhone 026) và **R3** (K3 029 lặp câu "Không gửi lại thao tác").
