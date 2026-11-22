// Dữ liệu mẫu Theme 2 (cửa hàng thuốc thú y, khớp dữ liệu mẫu Theme 3). Chỉ để vẽ; số liệu không lấy từ DB.
// Ảnh sản phẩm: Flutter tải ảnh thật từ Storage (CatalogStorageImage). Prototype không có ảnh thật nên dùng ảnh minh hoạ SVG (`photo`) cùng khổ.

/** VMoneyValidator.format(round) + " đ" (formatCatalogCurrency). */
export const money = (n) => `${Math.round(n).toLocaleString('de-DE')} đ`;

/** Ảnh minh hoạ thay ảnh Storage: nền màu + hình hộp đơn giản. */
export function photo(hue) {
  const svg = `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 60 60'><rect width='60' height='60' fill='hsl(${hue} 45% 86%)'/><rect x='17' y='14' width='26' height='34' rx='4' fill='hsl(${hue} 40% 58%)'/><rect x='21' y='22' width='18' height='9' rx='2' fill='hsl(${hue} 50% 94%)'/></svg>`;
  return `data:image/svg+xml,${encodeURIComponent(svg)}`;
}

/**
 * ProductListItemDto: name, tradeName, primaryImageUrl, businessStatus, listAfterVat, baseUnit, stockQuantity, stockLabel, customFieldValues.
 * stockLabel: ProductListItemAssembler gán stockQuantity.toString() → số trơn, không đơn vị.
 * stockQuantity: search_products trả coalesce(available, 0) → không bao giờ null.
 */
const withLabel = (p) => ({ ...p, stockLabel: p.stock == null ? null : String(p.stock) });
export const PRODUCTS = [
  { id: 'sp1', name: 'Amoxicillin 500mg', tradeName: 'Amoxi-Vet 500', img: 32, status: 'active', price: 125000, unit: 'hộp', stock: 24, cf: [['Dạng bào chế', 'Viên nén'], ['Hàm lượng (mg)', '500']] },
  { id: 'sp2', name: 'Thức ăn hạt cho chó con 1,5kg', tradeName: 'Puppy Mini', img: 24, status: 'active', price: 289000, unit: 'túi', stock: 12, cf: [['Khối lượng (g)', '1500']] },
  { id: 'sp3', name: 'Vắc-xin 5 bệnh cho chó', tradeName: '', img: 200, status: 'active', price: null, unit: 'lọ', stock: 0, cf: [] },
  { id: 'sp4', name: 'Dầu tắm trị ve rận cho chó mèo 250ml', tradeName: 'Fleaway', img: 160, status: 'active', price: 95000, unit: 'chai', stock: 40, cf: [['Dung tích (ml)', '250'], ['Có mùi', 'Có']] },
  { id: 'sp5', name: 'Men tiêu hoá Bio-Pet', tradeName: '', img: null, status: 'active', price: null, unit: null, stock: 0, cf: [] },
  { id: 'sp6', name: 'Cát vệ sinh cho mèo 10L', tradeName: 'Cát đậu nành', img: 50, status: 'inactive', price: 145000, unit: 'bao', stock: 0, cf: [] },
  { id: 'sp7', name: 'Thuốc nhỏ gáy trị ve mèo dưới 4kg', tradeName: 'Spot-on Cat', img: 280, status: 'active', price: 1250000, unit: 'hộp', stock: 3, cf: [['Cân nặng áp dụng', 'Dưới 4kg']] },
  { id: 'sp8', name: 'Pate cho mèo vị cá ngừ 85g', tradeName: '', img: 12, status: 'active', price: 18000, unit: 'lon', stock: 120, cf: [] },
].map(withLabel);
export const DELETED = [
  { id: 'sp9', name: 'Vòng cổ chống ve (mẫu cũ)', tradeName: '', img: 120, status: 'deleted', price: 65000, unit: 'cái', stock: 0, cf: [] },
  { id: 'sp10', name: 'Sữa tắm cho chó lông trắng', tradeName: 'White Coat', img: 300, status: 'deleted', price: 110000, unit: 'chai', stock: 0, cf: [] },
].map(withLabel);

/** Số trên chip (ProductListCubit): tổng, sẵn sàng, thiếu dữ liệu, ngừng KD — chỉ ghi khi tải danh sách không lọc. */
export const COUNTS = { all: 48, ready: 31, incomplete: 17, inactive: 3 };

/** Đơn vị của tenant (TenantMeasurementUnitSearchField). */
export const TENANT_UNITS = ['hộp', 'hũ', 'chai', 'lọ', 'túi', 'gói', 'viên', 'vỉ'];

/** Nhóm thông tin bổ sung (CustomFieldGroupConfigDto) dùng ở bước tạo. */
export const CF_GROUPS = [
  {
    name: 'Thông tin dược', fields: [
      { name: 'Dạng bào chế', type: 'singleSelect', required: true, options: ['Viên nén', 'Dung dịch', 'Bột'] },
      { name: 'Hàm lượng (mg)', type: 'number', required: false },
      { name: 'Kê đơn', type: 'boolean', required: false },
      { name: 'Ngày được cấp phép', type: 'date', required: false },
    ],
  },
];
