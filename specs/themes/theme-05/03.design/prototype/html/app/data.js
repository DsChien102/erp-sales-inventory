// Dữ liệu mẫu Theme 5 (cửa hàng thuốc thú y, cùng khách và sản phẩm với Theme 2 / 3 / 4). Chỉ để vẽ; số liệu không lấy từ DB.

/** MoneyFormatter.format / formatMinor (core/formatting/money_formatter.dart): "125.000đ", không dấu cách. Dòng hàng SG-02 tự định dạng cùng kết quả. */
export function money(minor) {
  const neg = minor < 0;
  const digits = String(Math.abs(Math.round(minor)));
  let out = '';
  for (let i = 0; i < digits.length; i++) {
    const fromEnd = digits.length - i;
    out += digits[i];
    if (fromEnd > 1 && fromEnd % 3 === 1) out += '.';
  }
  return `${neg ? '-' : ''}${out}đ`;
}

/** VMoneyValidator.format: nhóm nghìn bằng dấu PHẨY "125,000" (ô nhập giá SG-05, bàn phím số). */
export function moneyComma(n) {
  const neg = n < 0;
  const digits = String(Math.abs(n));
  let out = '';
  for (let i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 === 0) out += ',';
    out += digits[i];
  }
  return neg ? `-${out}` : out;
}

/**
 * SalesDraftListCard._timestampLabel: hôm nay → "HH:mm"; hôm qua → "Hôm qua"; còn lại "dd/MM" (không năm).
 * now / value: { day: 'yyyy-mm-dd', time: 'HH:mm' } (giờ ICT).
 */
export function draftTimestamp(value, nowDay = '2026-11-22') {
  if (value.day === nowDay) return value.time;
  const prev = new Date(`${nowDay}T00:00:00Z`);
  prev.setUTCDate(prev.getUTCDate() - 1);
  if (value.day === prev.toISOString().slice(0, 10)) return 'Hôm qua';
  const [, m, d] = value.day.split('-');
  return `${d}/${m}`;
}

/** SalesDraftListItemVm.phoneLabel. */
export const phoneLabel = (p) => (p && p.trim() ? p.trim() : 'Không có số điện thoại');

/**
 * Thẻ nháp: phoneLine = phoneLabel (+ " · Tạo bởi: <tên>" chỉ ở tab "Tất cả đơn nháp" và khi tên không phải UUID / SĐT).
 * Badge "Cần kiểm tra" (warning, nhỏ) chỉ khi needsCheck; "Đang soạn" không bao giờ hiện.
 */
export const DRAFTS = [
  { id: 'd1', customer: 'Nguyễn Văn Hùng', phone: '0912345678', note: 'Giao trước 16:00, gọi trước khi tới', lines: 3, total: 437000, at: { day: '2026-11-22', time: '10:24' }, creator: 'Phạm Thu Hà', mine: true },
  { id: 'd2', customer: 'Khách lẻ', phone: null, note: '', lines: 1, total: 125000, at: { day: '2026-11-22', time: '09:05' }, creator: 'Phạm Thu Hà', mine: true },
  { id: 'd3', customer: 'Công ty TNHH Thú y An Phát', phone: '0283 822 4567', note: 'Báo giá lại pate trước khi chốt', lines: 5, total: 2350000, at: { day: '2026-11-21', time: '17:40' }, creator: 'Phạm Thu Hà', mine: true, needsCheck: true },
  { id: 'd4', customer: 'Trần Thị Mai', phone: '0987654321', note: '', lines: 2, total: 36000, at: { day: '2026-11-18', time: '15:12' }, creator: 'Phạm Thu Hà', mine: true },
  { id: 'd5', customer: 'Đại lý Thuốc thú y Minh Tâm', phone: '0905112233', note: 'Chờ khách xác nhận số lượng', lines: 8, total: 6840000, at: { day: '2026-11-21', time: '08:30' }, creator: 'Lê Quốc Bảo', mine: false },
  { id: 'd6', customer: 'Khách lẻ', phone: null, note: '', lines: 2, total: 307000, at: { day: '2026-11-12', time: '11:02' }, creator: '0909123456', mine: false },
];

/** Sản phẩm bán được (search_sellable_products): giá tham chiếu theo đơn vị cơ sở, tồn khả dụng, tên thương mại. */
export const PRODUCTS = [
  { id: 'p1', name: 'Amoxicillin 500mg', trade: 'Amoxinject', unit: 'Hộp', price: 125000, stock: 42, units: [{ id: 'u1', name: 'Hộp', price: 125000, stock: 42 }, { id: 'u2', name: 'Vỉ', price: 13000, stock: 420 }] },
  { id: 'p2', name: 'Dầu tắm trị ve rận cho chó mèo 250ml', trade: '', unit: 'Chai', price: 95000, stock: 2 },
  { id: 'p3', name: 'Thức ăn hạt cho chó con 1,5kg', trade: 'Puppy Gold', unit: 'Túi', price: 289000, stock: 15 },
  { id: 'p4', name: 'Pate cho mèo vị cá ngừ 85g', trade: '', unit: 'Lon', price: 18000, stock: 120, units: [{ id: 'u4', name: 'Lon', price: 18000, stock: 120 }, { id: 'u5', name: 'Lốc 6 lon', price: 102000, stock: 20 }, { id: 'u6', name: 'Thùng 24 lon', price: 410000, stock: 5 }] },
];

/**
 * Dòng đơn đang soạn. stock → cảnh báo (SalesStockWarning: ≤ 0 "Hết hàng" đỏ; 1 "Chỉ còn 1 <đv>" đỏ; 2 "Chỉ còn 2 <đv>" vàng; > 2 không ghi).
 * special → dải chéo "%" (giá riêng / chỉnh tay / giá áp dụng ≠ niêm yết).
 */
export const LINES = [
  { id: 'l1', name: 'Amoxicillin 500mg', unit: 'Hộp', price: 125000, list: 125000, floor: 98000, qty: 2, stock: 42 },
  { id: 'l2', name: 'Pate cho mèo vị cá ngừ 85g', unit: 'Lon', price: 16000, list: 18000, floor: 15000, qty: 6, stock: 120, special: true },
  { id: 'l3', name: 'Dầu tắm trị ve rận cho chó mèo 250ml', unit: 'Chai', price: 95000, list: 95000, floor: 82000, qty: 1, stock: 2 },
];

/** SalesComposeTotals từ pricing preview: tổng niêm yết, giảm giá, thành tiền. */
export function totals(lines) {
  const merchandise = lines.reduce((s, l) => s + l.list * l.qty, 0);
  const net = lines.reduce((s, l) => s + l.price * l.qty, 0);
  return { count: lines.length, merchandise, discount: merchandise - net, net };
}

/**
 * Khách (search_partners): subtitle = "Khách hàng" (nếu có vai trò) · "MST …" · "Không hoạt động". Thẻ chọn: "SĐT · subtitle", thiếu cả hai → "—".
 */
export const CUSTOMERS = [
  { id: 'c1', name: 'Công ty TNHH Thú y An Phát', phone: '0283 822 4567', roles: ['customer'], tax: '0312345678' },
  { id: 'c2', name: 'Nguyễn Văn Hùng', phone: '0912345678', roles: ['customer'] },
  { id: 'c3', name: 'Đại lý Thuốc thú y Minh Tâm', phone: '0905112233', roles: ['customer', 'supplier'], tax: '0401234567' },
  { id: 'c4', name: 'Trần Thị Mai', phone: '0987654321', roles: ['customer'] },
  { id: 'c5', name: 'Phòng khám thú y Bình An', phone: null, roles: ['supplier'] },
  { id: 'c6', name: 'Lê Hoàng Phúc', phone: '0933445566', roles: ['customer'], inactive: true },
];

/** SalesPartnerCustomerLookup._mapItem → subtitle; SalesCustomerPickerCard.fromItem → dòng phụ. */
export function customerSubtitle(c) {
  const parts = [];
  if (c.roles.includes('customer')) parts.push('Khách hàng');
  if (c.tax) parts.push(`MST ${c.tax}`);
  if (c.inactive) parts.push('Không hoạt động');
  const sub = parts.length ? parts.join(' · ') : null;
  const line = [c.phone && c.phone.trim() ? c.phone.trim() : null, sub].filter(Boolean);
  return line.length ? line.join(' · ') : '—';
}
