# Prototype Tích hợp AI: "Hỏi Mosaic Retail" (10-8)

Prototype viết bằng HTML/CSS/JS thuần (ES module, không cần build). Nó vẽ **đúng Flutter hiện tại** của màn trợ lý `/ask` (AI-01) ở cả iPhone 390 và Web 1280, để người dùng rà bằng impeccable (bước 3 của 10-8). Chữ, thứ tự và số đo DS chép y nguyên, **không thiết kế lại**. Câu cố định lấy nguyên văn từ `supabase/functions/ai-assistant/messages.ts`; tiêu đề và cột bảng lấy từ các công cụ trong `tools/*.ts`. Số liệu trong bảng là dữ liệu mô phỏng.

`/ask` là GoRoute cấp gốc, **nằm ngoài `StoreShell`**. Vì vậy cả hai khổ đều không có thanh bên hay thanh dưới. Trên web, danh sách tin và dải nhập nằm trong một cột 840 giữa nền xám, còn app bar thì hết bề ngang. Lối vào ở Trang chủ (nút "Hỏi Mosaic Retail") đã có trong [prototype Trang chủ](../../home/html/README.md). Các màn mở từ dòng bảng (sản phẩm, đối tác, đơn bán) thuộc theme của chúng nên không vẽ ở đây.

Có 26 ca × 2 khổ, chia 3 nhóm trong cột trái: mở màn / nhập / đang chờ (5), trả lời có số liệu (10), từ chối / giới hạn / lỗi (11).

## Chạy

```bash
# xem chung với các prototype khác: python3 specs/prototype/serve.py → http://127.0.0.1:8760/ (mục lục)
cd specs/prototype/assistant/html
python3 tools/serve.py &    # cổng 8779, tắt cache
# trang xem: http://127.0.0.1:8779/   (cột trái chọn ca; iPhone / Web / Cả hai; Từng ca / Cả màn / Sửa trực tiếp)
# một ca trần (URL chụp ảnh): index.html?screen=answer&state=forecast&device=web
node --test                 # hàm thuần đối chiếu Dart + mọi ca vẽ được
node tools/capture.mjs      # 26 ca × 2 khổ → tools/proto-final/{iphone,web}/<màn>__<ca>.png (không vào git)
```

Ca trần không bấm được gì: gửi câu hỏi, gợi ý, Thử lại, mở dòng đều là hành vi của cubit / router.

## Tệp

| Tệp | Vai trò |
|---|---|
| `app/ask.js` | Màn `/ask` (`askPage`) + hàm thuần đối chiếu Dart: `formatCell`, `isNumeric`, `openLocation`, `drawable`, `replyTone`, `showRemaining`, `isLocked`, `remainingOf`, `tableWidth` |
| `app/ds.js` | Widget DS. `esc`, `icon`, `button`, `input`, `appBar` chép từ Theme 8 (`theme-08/app/ds.js`, đổi `t8-` → `ai-`); thêm `iconButton` (VButton.icon) và `table` (VTable) |
| `app/data.js` | Câu cố định của Edge Function; 4 bảng mẫu (dự báo nhập hàng, doanh thu theo sản phẩm, đơn bán, tồn kho); các câu trả lời theo trạng thái |
| `app/cases.js` | Nhóm, màn, ca, kèm điều cần nhìn của từng ca |
| `app/main.js` | Ca → hội thoại; màn vẽ ngoài khung (`insideShell('/ask') = false`); ca trần cuộn sẵn tới cuối như `jumpTo(maxScrollExtent)` |
| `styles/ai.css` | Rule của màn, tiền tố `ai-`, token `--c45-v2-*`; đầu file có bảng màu Flutter → token |
| `app/viewer.js`, `styles/viewer.css`, `styles/stage.css`, `tools/` | Trang xem và chụp ảnh, chép khuôn Theme 8 (cổng 8779) |

## Nguồn Flutter

| Phần | Flutter (`apps/erp/lib/features/assistant/`) |
|---|---|
| Khung màn | `presentation/pages/ask_assistant_page.dart`: `VAppBar`, `ListView` đệm 16 trong `ConstrainedBox(840)`, ô nhập + chân trong `SafeArea(top: false)` |
| Lời chào, câu gợi ý | `presentation/widgets/assistant_suggestions.dart` |
| Bong bóng hỏi / trả lời / lỗi / chờ | `presentation/widgets/assistant_message_bubble.dart` |
| Bảng kết quả | `presentation/widgets/assistant_result_table.dart` (`VTable` khi khung bảng ≥ `VBreakpoints.tablet` 600, hẹp hơn thì `_RowCard`), `presentation/assistant_cell_format.dart`, `presentation/assistant_open_target.dart` |
| Ô nhập, chân | `presentation/widgets/{assistant_composer, assistant_footer}.dart` |
| Trạng thái | `logic/ask_assistant_{cubit,state}.dart`, `data/models/assistant_reply.dart` |
| Khung | `core/router/app_router.dart` (GoRoute `/ask` cấp gốc, mở bằng `context.push('/ask')` ở `features/dashboard/presentation/home_tab_page.dart`) |

## Hiện trạng Flutter (để rà)

**Khung và dải nhập**

1. Web: app bar hết bề ngang 1280, nhưng danh sách và dải nhập chỉ rộng 840. Dải nhập là một khối trắng 840 nằm lơ lửng giữa nền xám, hai bên không có gì.
2. Giữa danh sách và dải nhập không có gạch hay bóng, nên khi cuộn, tin nhắn chạy sát mép trên dải trắng.
3. iPhone: phần đệm 34 của `SafeArea` nằm **ngoài** dải trắng, nên dưới câu nhắc có một dải xám.
4. Ô nhập chỉ một dòng, câu dài bị cuộn ngang. Giới hạn 500 ký tự cắt ngầm, không có bộ đếm.
5. Khi đang chờ trả lời, ô nhập vẫn gõ được nhưng nút gửi bị tắt. Nếu bấm Enter, `_send` **xoá chữ trong ô trước**, rồi `cubit.send` mới bỏ qua vì đang chờ, nên câu vừa gõ mất mà không có báo gì.

**Màn trống**

6. Bốn câu gợi ý là nút pill **hết bề ngang** (`Container` có `alignment` nên giãn đủ chỗ), cao 44, viền đậm `borderInput`. Trông giống bốn ô nhập. Màn không có tiêu đề, biểu tượng hay mô tả nào khác ngoài một dòng lời chào xám.
7. Câu gợi ý thứ ba "Khách nào đang nợ?" cần công cụ `cong_no_phai_thu`, mà công cụ này hoãn tới Theme 6. Nếu model không tự dùng `truy_van` thì câu gợi ý mặc định nhận "Mình chưa hỗ trợ câu này." (ca `problem/unsupported`).

**Hội thoại**

8. Tin không có nhãn người nói, giờ gửi hay biểu tượng trợ lý; chỉ phân biệt nhờ màu và việc canh trái / phải.
9. Bong bóng hỏi tối đa 80% bề ngang **cửa sổ** (`MediaQuery`), không theo cột: iPhone 312, còn web là 1024 > 840 nên giới hạn này không có tác dụng.
10. Đang chờ chỉ hiện chữ "Đang trả lời…" màu xám; không có vòng xoay hay chấm động. Sau 8 giây chữ đổi thành "Vẫn đang xử lý, chờ chút nhé…".
11. Bong bóng không có bảng thì co theo chữ và canh trái; có bảng thì giãn hết cột. Trong cùng một hội thoại, các bong bóng trả lời vì thế rộng hẹp khác nhau.
12. Chữ trả lời là `VText` nên không chọn hay sao chép được; không có `liveRegion` để trình đọc màn hình đọc câu trả lời mới. Đây là nợ audit của AI-2.
13. Màn tự nhảy tới cuối sau mỗi tin. Câu trả lời dài (nhất là iPhone có nhiều thẻ, ca `two-tables`) vì thế bị đẩy mất phần đầu; người dùng phải cuộn ngược lên đọc. Cũng là nợ của AI-2.

**Bảng kết quả**

14. Web: cột đầu luôn chiếm flex 3, các cột khác flex 1, **bất kể nội dung**. Ở bảng đơn, cột "Mã đơn" rộng thừa trong khi tên khách bị cắt "Công ty TNHH …" (ca `orders`).
15. Ô bảng chỉ một dòng, cắt "…", không có cách nào đọc hết (không tooltip, không xuống dòng).
16. Đầu cột viết hoa (VTable). "CÒN BÁN (NGÀY)" xuống hai dòng, làm hàng đầu cao hơn.
17. Dòng mở được chỉ nhận ra nhờ chữ xanh ở cột đầu (web) hoặc viền xanh nhạt (iPhone); không có chevron. Trên web, `onRowTap` gắn cho **mọi** dòng, nên dòng không mở được vẫn có hiệu ứng bấm (ca `stock-mixed`).
18. iPhone: mỗi dòng là một thẻ có viền, nằm trong bong bóng cũng có viền (viền lồng viền). Thẻ cuối còn thêm khe 8, nên đáy bong bóng dày hơn đỉnh.
19. Bảng "5 mặt hàng bán chạy" có cột đầu tên "Nhóm", vì `sales_stats.ts` dùng chung một tên cột cho mọi cách nhóm (ca `top5`).
20. Bảng dự báo không có nút "Tạo phiếu nhập" (AI-0 mục 8a), cũng không có lối sang phiếu nhập hàng.
21. Bấm một dòng đơn ở `/ask` làm màn đỏ (`!keyReservation.contains(key)` / GlobalKey `root` trùng, AI-5). Đây là lỗi lúc chạy nên prototype không tái hiện; chỉ ghi chú ở ca `orders`.

**Từ chối, giới hạn, lỗi**

22. Sáu trạng thái (ngoài phạm vi, chưa hỗ trợ, từ chối, không quyền, bận, hết lượt) dùng cùng một kiểu: nền vàng nhạt viền vàng, chữ đen, không icon. Người dùng không phân biệt được "hỏi sai chỗ" với "hệ thống đang bận".
23. Chỉ lỗi gọi (HTTP / mạng) mới có nút "Thử lại". Hai trường hợp dưới đây chữ bảo thử lại nhưng **không có nút**, phải gõ lại câu hỏi:
    - "bận": bong bóng vàng.
    - "phản hồi chậm": trạng thái `loi`, bong bóng đỏ.
24. "Thử lại" chỉ có ở tin cuối. Nếu người dùng gặp lỗi rồi hỏi câu khác, bong bóng lỗi cũ vẫn nằm giữa hội thoại nhưng không còn nút (ca `error-earlier`).
25. "Câu này phức tạp quá, bạn hỏi tách ra nhé." đi với trạng thái `ok`, nên hiện như câu trả lời thường, không có màu cảnh báo.
26. Hết lượt: bong bóng đã nói "dùng hết 100 câu hỏi", chân màn lại thêm "Còn 0 câu hỏi hôm nay.", hai câu trùng ý. Ô nhập mờ, hint "Đã hết lượt hôm nay", nút gửi xanh nhạt; câu gợi ý không hiện lại. Khoá chỉ giữ trong phiên màn: rời màn rồi vào lại thì ô nhập mở, hỏi một câu mới nhận lại "hết lượt".
27. Hai thông báo "Có lỗi khi trả lời…" và "Không có kết nối mạng." không nói câu hỏi đã gửi được hay chưa; bấm "Thử lại" gửi lại đúng câu cuối.
