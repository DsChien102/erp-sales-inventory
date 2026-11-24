// Dữ liệu mẫu dùng chung cho các màn Theme 3. Không phải dữ liệu thật.
// Trường theo PartnerListItemDto (data/models/partner_list_item.dart): tên, loại, trạng thái, vai trò, SĐT, MST, ngày cập nhật.
// "Mua lẻ / khác" là đối tác hệ thống mỗi tenant (inventory._ensure_walk_in_supplier, G5-2b): tổ chức, vai trò NCC, không SĐT.

export const PARTNERS = [
  { id: 'p1', name: 'Công ty TNHH Thú y An Phát', type: 'organization', status: 'active', roles: ['customer', 'supplier'], phone: '0283 812 4567', taxCode: '0312345678', updated: '21/11/2026' },
  { id: 'p2', name: 'Nguyễn Văn Hùng', type: 'person', status: 'active', roles: ['customer'], phone: '0912 345 678', taxCode: '', updated: '20/11/2026' },
  { id: 'p3', name: 'Đại lý Thuốc thú y Minh Tâm', type: 'organization', status: 'active', roles: ['customer'], phone: '0292 373 1188', taxCode: '1801234567', updated: '18/11/2026' },
  { id: 'p4', name: 'Công ty CP Dược Thú y Sài Gòn', type: 'organization', status: 'active', roles: ['supplier'], phone: '0283 999 1234', taxCode: '0301122334-001', updated: '15/11/2026' },
  { id: 'p5', name: 'Trần Thị Mai', type: 'person', status: 'inactive', roles: ['customer'], phone: '0987 654 321', taxCode: '', updated: '02/11/2026' },
  { id: 'p6', name: 'Mua lẻ / khác', type: 'organization', status: 'active', roles: ['supplier'], phone: '', taxCode: '', updated: '13/11/2026' },
  { id: 'p7', name: 'Lê Hoàng Phúc', type: 'person', status: 'active', roles: ['customer', 'supplier'], phone: '0903 112 233', taxCode: '8012345678', updated: '28/10/2026' },
];
export const TOTAL = 48;

/** 34 tỉnh / thành + số xã (apps/erp/assets/data/vn_administrative_units.json, thứ tự gốc của tệp). */
export const UNITS = [['Thành phố Hà Nội', 126], ['Tỉnh Cao Bằng', 56], ['Tỉnh Tuyên Quang', 124], ['Tỉnh Điện Biên', 45], ['Tỉnh Lai Châu', 38], ['Tỉnh Sơn La', 75], ['Tỉnh Lào Cai', 99], ['Tỉnh Thái Nguyên', 92], ['Tỉnh Lạng Sơn', 65], ['Tỉnh Quảng Ninh', 54], ['Tỉnh Bắc Ninh', 99], ['Tỉnh Phú Thọ', 148], ['Thành phố Hải Phòng', 114], ['Tỉnh Hưng Yên', 104], ['Tỉnh Ninh Bình', 129], ['Tỉnh Thanh Hoá', 166], ['Tỉnh Nghệ An', 130], ['Tỉnh Hà Tĩnh', 69], ['Tỉnh Quảng Trị', 78], ['Thành phố Huế', 40], ['Thành phố Đà Nẵng', 94], ['Tỉnh Quảng Ngãi', 96], ['Tỉnh Gia Lai', 135], ['Tỉnh Khánh Hoà', 65], ['Tỉnh Đắk Lắk', 102], ['Tỉnh Lâm Đồng', 124], ['Thành phố Đồng Nai', 95], ['Thành phố Hồ Chí Minh', 168], ['Tỉnh Tây Ninh', 96], ['Tỉnh Đồng Tháp', 102], ['Tỉnh Vĩnh Long', 124], ['Tỉnh An Giang', 102], ['Thành phố Cần Thơ', 103], ['Tỉnh Cà Mau', 64]];

/** 16 xã / phường đầu của Thành phố Cần Thơ, đã sắp theo đơn vị mã UTF-16 (String.compareTo). */
export const CAN_THO_WARDS = ['Phường An Bình', 'Phường Bình Thuỷ', 'Phường Cái Khế', 'Phường Cái Răng', 'Phường Hưng Phú', 'Phường Khánh Hoà', 'Phường Long Bình', 'Phường Long Mỹ', 'Phường Long Phú 1', 'Phường Long Tuyền', 'Phường Mỹ Quới', 'Phường Mỹ Xuyên', 'Phường Ngã Bảy', 'Phường Ngã Năm', 'Phường Ninh Kiều', 'Phường Phú Lợi'];

/** So sánh như Dart String.compareTo (đơn vị mã UTF-16), không theo bảng chữ cái tiếng Việt. */
export const dartCompare = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

/** _foldVietnamese (partner_administrative_unit_picker_sheet.dart): hạ chữ thường + bỏ dấu (chỉ các nguyên âm có dấu và đ). */
export function foldVietnamese(input) {
  return input.toLowerCase()
    .replace(/[àáạảãâầấậẩẫăằắặẳẵ]/g, 'a').replace(/[èéẹẻẽêềếệểễ]/g, 'e').replace(/[ìíịỉĩ]/g, 'i')
    .replace(/[òóọỏõôồốộổỗơờớợởỡ]/g, 'o').replace(/[ùúụủũưừứựửữ]/g, 'u').replace(/[ỳýỵỷỹ]/g, 'y').replace(/đ/g, 'd');
}
