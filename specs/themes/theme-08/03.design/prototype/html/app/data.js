// Dữ liệu mẫu Theme 8 (cửa hàng thú y như Theme 2 / 3 / 4). Chữ hiển thị chép từ Dart; số liệu chỉ để vẽ.

/** Hồ sơ pháp lý (MST lấy từ đây, chỉ đọc). */
export const LEGAL = { taxCode: '0312345678' };

/** Mẫu hóa đơn trả về từ list_provider_templates (ProviderTemplateDto: templateId là mã MISA dạng GUID, symbol, serial, name). */
export const TEMPLATES = [
  { templateId: '7f3c9a2e-41b8-4d0e-9c55-2a6e1f0b8d13', symbol: '1C26TAA', serial: 'C26TAA', name: 'Hóa đơn giá trị gia tăng' },
  { templateId: 'c1d84b07-93fa-4e2c-8b61-5f0a7d2e9c44', symbol: '2C26TBB', serial: 'C26TBB', name: 'Hóa đơn bán hàng' },
  { templateId: '0a9e6d35-2b7c-48f1-a3d2-6c8b4e1f7a90', symbol: '1C26TVE', serial: 'C26TVE', name: 'Hóa đơn giá trị gia tăng (máy tính tiền)' },
];

/** Kết nối MISA (ProviderConnectionSummaryDto). status: disconnected | connected | checkRequired | reconnectRequired. */
export const CONNECTION = {
  maskedAccount: 'ke***@anphat.vn',
  lastCheckedAt: new Date(2026, 9, 7, 9, 12), // 07/10/2026 09:12 (giờ máy)
};

/** Mốc "Đồng bộ gần nhất" của danh sách mẫu. */
export const LAST_SYNCED_AT = new Date(2026, 9, 7, 9, 15);

/** Đơn hàng mẫu cho hai màn Sales chủ (SG-06, SG-08). */
export const ORDER = {
  number: 'DH-000129',
  committedAt: '07/10/2026 · 14:32',
  soldAt: '07/10/2026 · 14:32',
  customer: 'Phòng khám thú y An Phát',
  phone: '0903 123 456',
  total: 5199232, // = tổng 4 dòng
  items: [
    { name: 'Vắc xin dại Rabisin', qty: 10, unit: 'Lọ', price: 95000 },
    { name: 'Thức ăn Royal Canin Mini Adult 2kg', qty: 6, unit: 'Túi', price: 389000 },
    { name: 'Thuốc nhỏ gáy Frontline Plus', qty: 12, unit: 'Hộp', price: 98000 },
    { name: 'Cát vệ sinh Me-O 5L', qty: 8, unit: 'Bao', price: 92404 },
  ],
};

/** Lịch sử gửi (InvoiceDeliveryItemDto): no, status processing|succeeded|failed|unknown, email, actor system|user, startedAt, completedAt. */
export const DELIVERIES = [
  { no: 1, status: 'succeeded', email: 'ketoan@thuyanphat.vn', actor: 'system', startedAt: new Date(2026, 9, 7, 14, 35), completedAt: new Date(2026, 9, 7, 14, 36) },
  { no: 2, status: 'failed', email: 'mua.hang@thuyanphat.vn', actor: 'user', startedAt: new Date(2026, 9, 8, 9, 2), completedAt: new Date(2026, 9, 8, 9, 3) },
  { no: 3, status: 'unknown', email: 'mua.hang@thuyanphat.vn', actor: 'user', startedAt: new Date(2026, 9, 8, 9, 10), completedAt: null },
];
