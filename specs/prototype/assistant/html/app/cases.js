// Danh sách ca dùng chung: main.js, viewer.js, tools/capture.mjs.
// Một màn thật (/ask), chia 3 nhóm để cột trái dễ đọc. Mỗi state: [mã, nhãn ngắn, điều cần nhìn]. Mỗi ca vẽ ở cả hai khổ (iPhone 390, Web 1280).
export const GROUPS = [
  { id: 'ask', title: 'Hỏi Mosaic Retail (AI-01)' },
];

const ROUTE = '/ask';

export const SCREENS = [
  {
    id: 'start', group: 'ask', code: 'AI-01', title: 'Mở màn, nhập, đang chờ', route: ROUTE, states: [
      ['empty', 'Màn trống', 'Route ngoài khung: không thanh bên / thanh dưới. App bar "Hỏi Mosaic Retail" + ←. Lời chào xám, 4 câu gợi ý là nút pill **hết bề ngang** (viền borderInput, cao 44), khe 8. Dưới: dải trắng ô nhập (hint "Hỏi về doanh thu, tồn kho, công nợ…") + nút gửi xanh 44; câu nhắc caption xám nhạt canh giữa. Không có gạch ngăn giữa danh sách và dải nhập. Web: cột 840 giữa nền xám, dải nhập cũng chỉ rộng 840.'],
      ['typing', 'Đang gõ câu hỏi', 'Ô nhập có chữ, viền xanh (focus). Nút gửi bật. Không có bộ đếm 500 ký tự (chỉ cắt ngầm bằng LengthLimitingTextInputFormatter).'],
      ['waiting', 'Đang trả lời', 'Gợi ý biến mất. Bong bóng hỏi xanh canh phải; bong bóng chờ trắng viền nhạt chỉ có chữ "Đang trả lời…" xám — không vòng xoay / chấm động. Nút gửi mờ 0.4; ô nhập vẫn gõ được.'],
      ['waiting-slow', 'Chờ quá 8 giây', 'Chữ chờ đổi "Vẫn đang xử lý, chờ chút nhé…".'],
      ['long-question', 'Câu hỏi dài', 'Bong bóng hỏi tối đa 80% bề ngang **cửa sổ** (MediaQuery): iPhone 312; web 1024 > cột 840 nên trên web giới hạn không có tác dụng, câu dài chạy gần hết cột.'],
    ],
  },
  {
    id: 'answer', group: 'ask', code: 'AI-01', title: 'Trả lời có số liệu', route: ROUTE, states: [
      ['revenue', 'Chỉ có chữ', '"Hôm nay bán được bao nhiêu?" → câu trả lời không bảng: bong bóng trắng canh trái, co theo chữ. Chữ không chọn / sao chép được (VText).'],
      ['forecast', 'Dự báo nhập hàng (5 cột)', 'Có bảng → bong bóng hết bề ngang. Tiêu đề bảng 14 w600. iPhone (khung bảng 332 < 600): mỗi dòng một thẻ viền xanh nhạt (mở được), tên sản phẩm 14 w600 cắt "…" một dòng, 4 hàng nhãn | giá trị 13. Web (khung 782 ≥ 600): VTable, đầu cột VIẾT HOA 12 w700 xám, cột đầu flex 3 (tên xanh = mở được), số canh phải 1 số lẻ dấu phẩy; ô "Nên nhập" null → "—". Không có nút "Tạo phiếu nhập" (AI-0 mục 8a).'],
      ['top5', 'Top 5 bán chạy (2 cột)', '"5 mặt hàng bán chạy tháng này?" → bảng "Doanh thu theo sản phẩm", cột đầu tên "Nhóm" (sales_stats.ts dùng chung cho mọi cách nhóm). Web: 2 cột flex 3 : 1. Tiền "18.720.000đ".'],
      ['orders', 'Danh sách đơn (bấm mở đơn)', 'Bảng đơn: Mã đơn | Khách | Tổng tiền | Ngày (dd/MM/yyyy, bỏ giờ). Đơn khách lẻ "Khách" = "—". Bấm dòng → push /sales/orders/:id (đây là chỗ màn đỏ `!keyReservation.contains(key)` của AI-5, prototype không tái hiện). Web: tên khách dài cắt "…".'],
      ['stock-mixed', 'Dòng mở được và không', 'Bảng "Tồn kho": dòng 3 không có `mo` → iPhone thẻ viền xám thường, không bấm được; web tên chữ đen thay vì xanh nhưng **vẫn có hiệu ứng bấm** (onRowTap gắn cho mọi dòng, chỉ bỏ qua khi không có đích). Tồn "36,5", "0".'],
      ['two-tables', 'Hai bảng trong một câu', 'Một bong bóng chứa chữ + hai bảng nối nhau, khe 12 trước mỗi bảng. iPhone: 10 thẻ liền → bong bóng rất dài, cuộn tới cuối nên đầu câu trả lời bị đẩy khỏi màn.'],
      ['empty-table', 'Bảng không có dòng', 'Khối bảng rỗng bị bỏ (_drawable) → chỉ còn chữ, bong bóng co lại canh trái.'],
      ['chat', 'Trò chuyện', '"Cảm ơn nhé" → trạng thái tro_chuyen: cùng màu bong bóng thường.'],
      ['too-complex', 'Câu quá phức tạp', 'Trạng thái ok nhưng chữ "Câu này phức tạp quá, bạn hỏi tách ra nhé." → bong bóng thường, không màu cảnh báo.'],
      ['remaining-low', 'Còn ít lượt', 'luot_con_lai 3 (≤ 10) → dòng "Còn 3 câu hỏi hôm nay." caption xám ngay trên câu nhắc.'],
    ],
  },
  {
    id: 'problem', group: 'ask', code: 'AI-01', title: 'Từ chối, giới hạn, lỗi', route: ROUTE, states: [
      ['out-of-scope', 'Ngoài phạm vi', '"Mai trời mưa không?" → ngoai_pham_vi: bong bóng nền vàng nhạt viền vàng, chữ đen. Hai câu gợi ý nằm trong chữ (không bấm được).'],
      ['unsupported', 'Chưa hỗ trợ', '"Khách nào đang nợ?" (câu gợi ý thứ 3) khi chưa có công cụ công nợ (`cong_no_phai_thu` hoãn tới Theme 6) và model không dùng `truy_van` → "Mình chưa hỗ trợ câu này." vàng.'],
      ['refuse', 'Từ chối sửa / xoá', '"Xoá đơn DH-000129 giúp tôi" → tu_choi, vàng.'],
      ['no-permission', 'Không có quyền', 'RPC báo PERMISSION_DENIED → khong_quyen, vàng. Cùng màu với ngoài phạm vi / chưa hỗ trợ / bận.'],
      ['busy', 'Trợ lý bận', 'Model bận → ban, vàng; **không có nút Thử lại** (chỉ lỗi mạng / HTTP mới có), phải gõ lại câu hỏi.'],
      ['slow', 'Phản hồi chậm', 'Edge Function hết giờ → trạng thái loi + "Trợ lý phản hồi chậm, bạn thử lại nhé." → bong bóng đỏ nhạt viền đỏ nhưng **không có nút Thử lại** dù chữ bảo thử lại.'],
      ['error', 'Lỗi gọi (có Thử lại)', 'Lỗi HTTP / ngoại lệ → ErrorMessage: đỏ nhạt viền đỏ "Có lỗi khi trả lời. Bạn thử lại nhé." + khe 8 + nút phụ "Thử lại" (co theo chữ, canh trái).'],
      ['offline', 'Mất mạng', '"Không có kết nối mạng." + "Thử lại". Không nói câu hỏi chưa được gửi.'],
      ['error-earlier', 'Lỗi cũ không còn nút', 'Gặp lỗi rồi gõ câu khác thay vì Thử lại: bong bóng lỗi cũ vẫn ở giữa hội thoại nhưng **mất nút Thử lại** (chỉ tin cuối mới có).'],
      ['limit', 'Hết lượt', 'het_luot (luot_con_lai 0) → bong bóng vàng "Cửa hàng đã dùng hết 100 câu hỏi hôm nay…"; ô nhập khoá (mờ, viền xám) hint "Đã hết lượt hôm nay"; nút gửi mờ; chân hiện "Còn 0 câu hỏi hôm nay." thừa với câu trong bong bóng. Câu gợi ý không hiện lại.'],
      ['conversation', 'Hội thoại dài', 'Nhiều lượt (chữ, bảng, cảnh báo) — màn cuộn sẵn tới cuối như Flutter (jumpTo maxScrollExtent sau mỗi tin). Khe 12 giữa các tin; không có giờ gửi, không có nhãn người nói.'],
    ],
  },
];

export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));
