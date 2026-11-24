// Câu trả lời mẫu theo đúng dạng AssistantReply (đã đọc từ JSON): { status, text, blocks: [{ title, columns: [{ key, name, kind }], rows: [{ cells, open }] }], remaining }.
// Câu cố định lấy nguyên văn supabase/functions/ai-assistant/messages.ts; tiêu đề / cột bảng lấy từ tools/{sales_stats, forecast, stock, search}.ts.
// Số liệu là dữ liệu mô phỏng (không phải số thật của Dev).

export const MSG = {
  ngoai_pham_vi: 'Mình chỉ giúp xem số liệu cửa hàng thôi. Bạn có thể hỏi như: "Hôm nay bán được bao nhiêu?", "Hàng nào sắp hết?"',
  chua_ho_tro: 'Mình chưa hỗ trợ câu này.',
  tu_choi: 'Mình chỉ xem được, không sửa hay xoá.',
  khong_quyen: 'Bạn không có quyền xem số liệu này. Hãy nhờ chủ cửa hàng.',
  het_luot: 'Cửa hàng đã dùng hết 100 câu hỏi hôm nay. Mai bạn quay lại nhé.',
  ban: 'Trợ lý đang bận, thử lại sau ít phút.',
  cham: 'Trợ lý phản hồi chậm, bạn thử lại nhé.',
  loi: 'Có lỗi khi trả lời. Bạn thử lại nhé.',
  qua_phuc_tap: 'Câu này phức tạp quá, bạn hỏi tách ra nhé.',
};

const reply = (status, text, blocks = [], remaining = 87) => ({ status, text, blocks, remaining });
const sp = (id) => ({ loai: 'san_pham', id });

/** forecast.ts — "Dự báo nhập hàng". */
const FORECAST = {
  title: 'Dự báo nhập hàng',
  columns: [
    { key: 'san_pham', name: 'Sản phẩm', kind: 'chu' },
    { key: 'ton', name: 'Tồn', kind: 'so' },
    { key: 'ban_moi_ngay', name: 'Bán/ngày', kind: 'so' },
    { key: 'con_ban_ngay', name: 'Còn bán (ngày)', kind: 'so' },
    { key: 'nen_nhap', name: 'Nên nhập', kind: 'so' },
  ],
  rows: [
    { cells: { san_pham: 'Sữa tươi Vinamilk hộp 1L', ton: 12, ban_moi_ngay: 6.4, con_ban_ngay: 1.9, nen_nhap: 78 }, open: sp('p-01') },
    { cells: { san_pham: 'Mì Hảo Hảo tôm chua cay gói 75g', ton: 40, ban_moi_ngay: 15.25, con_ban_ngay: 2.6, nen_nhap: 170 }, open: sp('p-02') },
    { cells: { san_pham: 'Nước mắm Nam Ngư chai 500ml', ton: 5, ban_moi_ngay: 1.3, con_ban_ngay: 3.8, nen_nhap: 15 }, open: sp('p-03') },
    { cells: { san_pham: 'Dầu ăn Neptune 1L', ton: 8, ban_moi_ngay: 1.8, con_ban_ngay: 4.4, nen_nhap: 14 }, open: sp('p-04') },
    { cells: { san_pham: 'Bánh quy Cosy 336g', ton: 3, ban_moi_ngay: 0.6, con_ban_ngay: 5, nen_nhap: null }, open: sp('p-05') },
  ],
};

/** sales_stats.ts — "Doanh thu theo sản phẩm" (cột "Nhóm" | chỉ số). */
const TOP5 = {
  title: 'Doanh thu theo sản phẩm',
  columns: [
    { key: 'nhom', name: 'Nhóm', kind: 'chu' },
    { key: 'gia_tri', name: 'Doanh thu', kind: 'tien' },
  ],
  rows: [
    { cells: { nhom: 'Sữa tươi Vinamilk hộp 1L', gia_tri: 18_720_000 }, open: sp('p-01') },
    { cells: { nhom: 'Bia Tiger lon 330ml (thùng 24)', gia_tri: 15_360_000 }, open: sp('p-06') },
    { cells: { nhom: 'Mì Hảo Hảo tôm chua cay gói 75g', gia_tri: 6_842_500 }, open: sp('p-02') },
    { cells: { nhom: 'Gạo ST25 túi 5kg', gia_tri: 5_950_000 }, open: sp('p-07') },
    { cells: { nhom: 'Dầu ăn Neptune 1L', gia_tri: 3_115_000 }, open: sp('p-04') },
  ],
};

/** search.ts — tìm đơn: Mã đơn | Khách | Tổng tiền | Ngày; mở don_ban. Đơn khách lẻ không có tên khách → null → "—". */
const ORDERS = {
  title: 'Đơn bán',
  columns: [
    { key: 'ma', name: 'Mã đơn', kind: 'chu' },
    { key: 'khach', name: 'Khách', kind: 'chu' },
    { key: 'tong_tien', name: 'Tổng tiền', kind: 'tien' },
    { key: 'ngay', name: 'Ngày', kind: 'ngay' },
  ],
  rows: [
    { cells: { ma: 'DH-000131', khach: 'Công ty TNHH Thực phẩm An Phát', tong_tien: 4_250_000, ngay: '2026-11-22T09:12:00+07:00' }, open: { loai: 'don_ban', id: 'o-131' } },
    { cells: { ma: 'DH-000130', khach: null, tong_tien: 186_000, ngay: '2026-11-22T08:47:00+07:00' }, open: { loai: 'don_ban', id: 'o-130' } },
    { cells: { ma: 'DH-000129', khach: 'Nguyễn Thị Lan', tong_tien: 1_245_000, ngay: '2026-11-21T17:30:00+07:00' }, open: { loai: 'don_ban', id: 'o-129' } },
  ],
};

/** stock.ts — "Tồn kho": Sản phẩm | Tồn | ĐVT. Dòng thứ ba thiếu id → không mở được (viền thường / chữ đen). */
const STOCK = {
  title: 'Tồn kho',
  columns: [
    { key: 'san_pham', name: 'Sản phẩm', kind: 'chu' },
    { key: 'ton', name: 'Tồn', kind: 'so' },
    { key: 'dvt', name: 'ĐVT', kind: 'chu' },
  ],
  rows: [
    { cells: { san_pham: 'Sữa tươi Vinamilk hộp 1L', ton: 12, dvt: 'Hộp' }, open: sp('p-01') },
    { cells: { san_pham: 'Sữa tươi Vinamilk hộp 180ml (lốc 4)', ton: 36.5, dvt: 'Lốc' }, open: sp('p-08') },
    { cells: { san_pham: 'Sữa đặc Ông Thọ lon 380g', ton: 0, dvt: 'Lon' }, open: null },
  ],
};

export const Q = {
  revenue: 'Hôm nay bán được bao nhiêu?',
  forecast: 'Hàng nào sắp hết, nên nhập bao nhiêu?',
  debt: 'Khách nào đang nợ?',
  top5: '5 mặt hàng bán chạy tháng này?',
};

export const R = {
  revenue: reply('ok', 'Hôm nay (22/11) cửa hàng bán được 8.420.000đ từ 23 đơn, trung bình 366.087đ mỗi đơn.'),
  forecast: reply('ok', 'Có 5 mặt hàng sẽ hết trong khoảng 5 ngày tới theo tốc độ bán 8 tuần gần nhất. Sữa tươi hộp 1L và mì Hảo Hảo cần nhập trước, chỉ còn khoảng 2–3 ngày hàng.', [FORECAST]),
  top5: reply('ok', 'Tháng 11 đến nay, sữa tươi hộp 1L dẫn đầu doanh thu, tiếp theo là bia Tiger thùng 24.', [TOP5]),
  orders: reply('ok', 'Có 3 đơn gần nhất từ hôm qua đến nay.', [ORDERS]),
  stock: reply('ok', 'Sữa đặc Ông Thọ đã hết hàng; hai loại sữa tươi còn hàng.', [STOCK]),
  twoTables: reply('ok', 'Sữa tươi hộp 1L đang bán chạy nhất tháng nhưng chỉ còn khoảng 2 ngày hàng.', [TOP5, FORECAST]),
  emptyTable: reply('ok', 'Chưa có hàng nào cần nhập thêm.', [{ ...FORECAST, rows: [] }]),
  chat: reply('tro_chuyen', 'Không có gì! Bạn cần xem thêm số liệu nào cứ hỏi mình nhé.'),
  outOfScope: reply('ngoai_pham_vi', MSG.ngoai_pham_vi),
  unsupported: reply('chua_ho_tro', MSG.chua_ho_tro),
  refuse: reply('tu_choi', MSG.tu_choi),
  noPermission: reply('khong_quyen', MSG.khong_quyen),
  busy: reply('ban', MSG.ban, [], null),
  slow: reply('loi', MSG.cham, [], null),
  backendError: reply('loi', MSG.loi, [], null),
  tooComplex: reply('ok', MSG.qua_phuc_tap),
  revenueLow: reply('ok', 'Hôm nay (22/11) cửa hàng bán được 8.420.000đ từ 23 đơn, trung bình 366.087đ mỗi đơn.', [], 3),
  limit: reply('het_luot', MSG.het_luot, [], 0),
};
