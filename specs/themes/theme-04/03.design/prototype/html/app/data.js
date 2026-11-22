// Dữ liệu mẫu Theme 4 (cửa hàng thuốc thú y, cùng khách và sản phẩm với Theme 2 / 3). Chỉ để vẽ; số liệu không lấy từ DB.

/** MoneyFormatter.formatMinor (core/formatting/money_formatter.dart): "95.000đ" — không có dấu cách (Theme 2 dùng "125.000 đ"). */
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

/** Màn chọn sản phẩm / đơn vị tự định dạng: regex nhóm nghìn + "đ" (cùng kết quả với money cho số dương). */
export const dong = (n) => `${String(n).replace(/\B(?=(\d{3})+(?!\d))/g, '.')}đ`;

/**
 * CustomerPriceRuleListItemDto: customer.displayName, productUnit.productName / unitName, price, validationOutcome.listPrice,
 * warningCodes (below_floor_price), derivedStatus, effectivePeriod. Thẻ không có SĐT khách.
 */
export const RULES = [
  { id: 'r1', customer: 'Công ty TNHH Thú y An Phát', product: 'Amoxicillin 500mg', unit: 'Hộp', price: 105000, list: 125000, floor: 98000, status: 'applying', below: false, from: '01/07/2026', to: null },
  { id: 'r2', customer: 'Đại lý Thuốc thú y Minh Tâm', product: 'Dầu tắm trị ve rận cho chó mèo 250ml', unit: 'Chai', price: 78000, list: 95000, floor: 82000, status: 'applying', below: true, from: '15/09/2026', to: '31/12/2026' },
  { id: 'r3', customer: 'Nguyễn Văn Hùng', product: 'Thức ăn hạt cho chó con 1,5kg', unit: 'Túi', price: 270000, list: 289000, floor: 250000, status: 'notYetEffective', below: false, from: '01/12/2026', to: null },
  { id: 'r4', customer: 'Trần Thị Mai', product: 'Pate cho mèo vị cá ngừ 85g', unit: 'Lon', price: 16000, list: 18000, floor: 15000, status: 'disabled', below: false, from: '01/06/2026', to: null },
  { id: 'r5', customer: 'Lê Hoàng Phúc', product: 'Thuốc nhỏ gáy trị ve mèo dưới 4kg', unit: 'Hộp', price: 1150000, list: 1250000, floor: 1100000, status: 'expired', below: false, from: '01/03/2026', to: '30/09/2026' },
  { id: 'r6', customer: 'Công ty CP Dược Thú y Sài Gòn', product: 'Vắc-xin 5 bệnh cho chó', unit: 'Lọ', price: 82000, list: null, floor: null, status: 'needsReview', below: false, from: '10/10/2026', to: null },
  { id: 'r7', customer: 'Công ty TNHH Thú y An Phát', product: 'Cát vệ sinh cho mèo 10L', unit: 'Bao', price: 132000, list: 145000, floor: 120000, status: 'applying', below: false, from: '20/08/2026', to: null },
];

/** PriceRuleStatusBadge: nhãn + VBadgeStatus → tone. draft / cancelled đều ra neutral → "Đã tắt" và "Hết hiệu lực" cùng màu. */
export const STATUS = {
  applying: ['Đang áp dụng', 'success'],
  notYetEffective: ['Chưa hiệu lực', 'info'],
  disabled: ['Đã tắt', 'neutral'],
  expired: ['Hết hiệu lực', 'neutral'],
  needsReview: ['Cần kiểm tra', 'warning'],
  deleted: ['Đã xóa', 'neutral'],
};

/** Màn chọn khách: PartnerRepository.search(role customer, active, limit 30). Thẻ: tên, email ?? SĐT, nhãn vai trò. */
export const CUSTOMERS = [
  { id: 'c1', name: 'Công ty TNHH Thú y An Phát', sub: 'muahang@anphatvet.vn', role: 'KH & NCC' },
  { id: 'c2', name: 'Nguyễn Văn Hùng', sub: '0912 345 678', role: 'Khách hàng' },
  { id: 'c3', name: 'Đại lý Thuốc thú y Minh Tâm', sub: '0292 373 1188', role: 'Khách hàng' },
  { id: 'c4', name: 'Trần Thị Mai', sub: '0987 654 321', role: 'Khách hàng' },
  { id: 'c5', name: 'Lê Hoàng Phúc', sub: '0903 112 233', role: 'Khách hàng' },
];

/** Màn chọn sản phẩm: ProductListItemDto — "Giá hiện tại" là listBeforeVat (trước VAT; danh sách sản phẩm Theme 2 hiện giá sau VAT). */
export const PRODUCTS = [
  { id: 'sp1', name: 'Amoxicillin 500mg', listBeforeVat: 115741, baseUnit: 'Hộp' },
  { id: 'sp2', name: 'Thức ăn hạt cho chó con 1,5kg', listBeforeVat: 267593, baseUnit: 'Túi' },
  { id: 'sp3', name: 'Vắc-xin 5 bệnh cho chó', listBeforeVat: null, baseUnit: 'Lọ' },
  { id: 'sp4', name: 'Dầu tắm trị ve rận cho chó mèo 250ml', listBeforeVat: 87963, baseUnit: 'Chai' },
  { id: 'sp5', name: 'Men tiêu hoá Bio-Pet', listBeforeVat: null, baseUnit: null },
  { id: 'sp8', name: 'Pate cho mèo vị cá ngừ 85g', listBeforeVat: 16667, baseUnit: 'Lon' },
];

/** Màn chọn đơn vị: ProductUnitDto + ProductPriceBandSnapshotItemDto (trước VAT). */
export const UNITS = [
  { id: 'u1', name: 'Hộp', base: true, list: 115741, floor: 90741, floorHidden: false },
  { id: 'u2', name: 'Vỉ', base: false, list: 12500, floor: null, floorHidden: false },
  { id: 'u3', name: 'Viên', base: false, list: null, floor: 4000, floorHidden: false },
  { id: 'u5', name: 'Gói dùng thử', base: false, list: null, floor: null, floorHidden: false },
  { id: 'u4', name: 'Thùng (20 hộp)', base: false, list: 2200000, floor: 1800000, floorHidden: true },
];
