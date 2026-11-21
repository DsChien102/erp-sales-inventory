// PT-07 Hồ sơ KH & NCC + sheet thao tác / ngừng / kích hoạt / xoá / chặn xoá + toast.
// Nguồn Flutter (apps/erp/lib/features/partner/presentation/):
//   pages/partner_detail_page.dart (thứ tự khối, điều kiện, hàng nút đáy, toast)
//   widgets/{partner_detail_header, partner_detail_status_banners, partner_detail_expandable_card, partner_detail_main_info_card,
//     partner_detail_contacts_card, partner_detail_invoice_card, partner_detail_delivery_card, partner_detail_note_card,
//     partner_detail_system_card, partner_detail_loading_skeleton, partner_detail_error_state, partner_detail_action_sheet,
//     partner_deactivate_confirmation_sheet, partner_reactivate_confirmation_sheet, partner_soft_delete_confirmation_sheet,
//     partner_delete_blocked_sheet, partner_delete_primary_contact_blocked_sheet, partner_detail_soft_delete_flow,
//     partner_create_success_toast, partner_transform_success_toast}.dart
// Khối theme khác (gắn qua core/router/app_router.dart, vẽ đúng Flutter):
//   Công nợ  — features/receivable/presentation/widgets/customer_receivable_summary_card.dart (+ receivable_parts.dart ReceivableDueBadge)
//   Chương trình ưu đãi — features/inventory/presentation/supplier_program/supplier_programs_section.dart (+ K6TaskRow, VListRow, ProgramRowBelow)
//   Lịch sử nhập hàng — features/inventory/presentation/goods_receipt/receipt_history_section.dart
import { icon } from '../shared/icons.js';
import {
  appBar, avatar, banner, button, card, centerLoading, esc, gap, iconBox, scaffold, skeleton, textArea, toast,
} from './ds.js';

// ---------------------------------------------------------------- dữ liệu mẫu (PartnerDetailDto)

const ALL_ACTIONS = ['update', 'transform', 'deactivate', 'delete'];
export const DETAILS = {
  p1: {
    id: 'p1', name: 'Công ty TNHH Thú y An Phát', type: 'organization', status: 'active', roles: ['customer', 'supplier'], actions: ['update', 'deactivate', 'delete'],
    org: { type: 'Công ty', name: 'Công ty TNHH Thú y An Phát', shortName: 'An Phát', intlName: '', phone: '0283 812 4567', email: 'lienhe@anphat.vn' },
    taxCode: '0312345678', invoice: { name: 'CÔNG TY TNHH THÚ Y AN PHÁT', email: 'ketoan@anphat.vn', address: '12 Nguyễn Văn Cừ, Phường An Bình, Thành phố Cần Thơ' },
    delivery: { province: 'Thành phố Cần Thơ', commune: 'Phường An Bình', address: '12 Nguyễn Văn Cừ' }, note: 'Giao hàng buổi sáng.',
    contacts: [
      { name: 'Phạm Thu Hà', primary: true, role: 'Quản lý kinh doanh', phone: '0905 667 788', email: 'ha.pt@anphat.vn' },
      { name: 'Lê Văn Tâm', role: 'Kế toán', phone: '0918 223 344' },
    ],
    receivable: { owed: '18.000.000 ₫', orders: 3, overdue: 8 },
    programs: [
      { name: 'Giảm giá Vemedim quý IV', kind: 'Giảm theo bậc', status: ['Đang chạy', 'info'], summary: 'Từ 10 hộp giảm 5% · từ 50 giảm 8%' },
      { name: 'Thưởng doanh số 2026', kind: 'Chiết khấu đạt mốc', status: ['Đạt mốc', 'warning'], progress: [1, '1.200 / 1.000 hộp'] },
    ],
    receipts: [
      { no: 'PN-261118-01', date: '2026-11-18', lines: 3, lots: 4, total: '12.500.000 đ' },
      { no: 'PN-261105-02', date: '2026-11-05', lines: 1, lots: 1, total: '2.400.000 đ' },
    ],
  },
  p2: {
    id: 'p2', name: 'Nguyễn Văn Hùng', type: 'person', status: 'active', roles: ['customer'], actions: ALL_ACTIONS,
    person: { title: 'Anh', fullName: 'Nguyễn Văn Hùng', nickname: '', phone: '0912 345 678', phone2: '', email: 'hung.nv@gmail.com' },
    taxCode: '', invoice: {}, delivery: {}, note: '', contacts: [], receivable: { owed: null },
  },
  p4: {
    id: 'p4', name: 'Công ty CP Dược Thú y Sài Gòn', type: 'organization', status: 'active', roles: ['supplier'], actions: ['update', 'deactivate', 'delete'],
    org: { type: 'Công ty', name: 'Công ty CP Dược Thú y Sài Gòn', shortName: '', intlName: 'Saigon Vet Pharma JSC', phone: '0283 999 1234', email: '' },
    taxCode: '0301122334-001', invoice: { name: 'CÔNG TY CP DƯỢC THÚ Y SÀI GÒN', address: '45 Lê Lợi, Phường Bến Thành, Thành phố Hồ Chí Minh' },
    delivery: {}, note: '', contacts: [], programs: [], receipts: [],
  },
  p5: {
    id: 'p5', name: 'Trần Thị Mai', type: 'person', status: 'inactive', roles: ['customer'], actions: ['update', 'reactivate', 'delete'],
    person: { title: 'Chị', fullName: 'Trần Thị Mai', nickname: 'Chị Mai', phone: '0987 654 321', phone2: '', email: '' },
    taxCode: '', invoice: {}, delivery: { province: 'Tỉnh Vĩnh Long', commune: '', address: '' }, note: '', contacts: [], receivable: { owed: null },
  },
  p6: {
    id: 'p6', name: 'Mua lẻ / khác', type: 'organization', status: 'active', roles: ['supplier'], system: true, actions: [],
    org: { type: 'Khác', name: 'Mua lẻ / khác', shortName: '', intlName: '', phone: '', email: '' }, taxCode: '', invoice: {}, delivery: {}, note: '', contacts: [],
  },
  p7: {
    id: 'p7', name: 'Lê Hoàng Phúc', type: 'person', status: 'active', roles: ['customer', 'supplier'], actions: ALL_ACTIONS, primaryOf: 'Đại lý Thuốc thú y Minh Tâm',
    person: { title: 'Anh', fullName: 'Lê Hoàng Phúc', nickname: '', phone: '0903 112 233', phone2: '', email: 'phuc.lh@gmail.com' },
    taxCode: '8012345678', invoice: { name: 'LÊ HOÀNG PHÚC', address: '88 Trần Hưng Đạo, Phường Ninh Kiều, Thành phố Cần Thơ' }, delivery: {}, note: '', contacts: [],
    receivable: { owed: '2.350.000 ₫', orders: 1, overdue: 0 }, programs: [], receipts: [{ no: 'PN-261020-01', date: '2026-10-20', lines: 2, lots: 2, total: '4.800.000 đ' }],
  },
};

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

const joinLabels = (labels) => (labels.length === 1 ? labels[0] : labels.length === 2 ? `${labels[0]} và ${labels[1]}` : `${labels.slice(0, -1).join(', ')} và ${labels[labels.length - 1]}`);

/** partner_detail_page.dart missingRequired → mô tả banner "Hồ sơ còn thiếu thông tin" (có dấu cách cuối). */
export function missingDescription(d) {
  const missing = d.type === 'person'
    ? [!d.taxCode?.trim() && 'MST', !d.invoice?.address?.trim() && 'địa chỉ hóa đơn']
    : [!d.taxCode?.trim() && 'MST', !d.invoice?.name?.trim() && 'tên xuất hóa đơn', !d.invoice?.address?.trim() && 'địa chỉ hóa đơn'];
  const m = missing.filter(Boolean);
  return m.length ? `Thiếu ${joinLabels(m)}. ` : null;
}

/** _invoiceBadgeLabel (partner_detail_invoice_card.dart): nhãn rút gọn khác câu banner. */
export function invoiceBadge(d) {
  const m = [];
  if (!d.taxCode?.trim()) m.push('MST');
  if (d.type === 'person') { if (!d.invoice?.address?.trim()) m.push('địa chỉ'); } else {
    if (!d.invoice?.name?.trim()) m.push('tên HĐ');
    if (!d.invoice?.address?.trim()) m.push('địa chỉ');
  }
  return m.length ? `Thiếu ${joinLabels(m)}` : null;
}

/** Hàng liên hệ nhanh: SĐT + "MST …" nối bằng "  •  " (2 dấu cách mỗi bên). */
export function contactLine(d) {
  const phone = d.type === 'person' ? d.person.phone : d.org.phone;
  return [phone, d.taxCode && `MST ${d.taxCode}`].filter(Boolean).join('  •  ');
}

/** PartnerDetailActionSheet: các thao tác hiện. */
export function sheetActions(d) {
  const inactive = d.status === 'inactive';
  return {
    transform: d.type === 'person' && d.actions.includes('transform'),
    toggle: inactive ? d.actions.includes('reactivate') : d.actions.includes('deactivate'),
    del: d.actions.includes('delete'),
  };
}

// ---------------------------------------------------------------- phần màn

const roleText = (roles) => (roles.includes('customer') && roles.includes('supplier') ? 'KH & NCC' : roles.includes('customer') ? 'Khách hàng' : roles.includes('supplier') ? 'Nhà cung cấp' : 'Chưa có vai trò');

/** PartnerDetailHeader: VAvatar 64 (chữ 24) | khe 16 | tên H3 w700, khe 4, "Loại • Vai trò", khe 8, thẻ trạng thái (đệm 8 / 2, bo 4, 11 w600, nền 10%). */
function header(d) {
  const tag = d.status === 'active' ? '<span class="t3-stag t3-stag--success">Đang hoạt động</span>' : '<span class="t3-stag t3-stag--warning">Ngừng hoạt động</span>';
  return `<div class="t3-dhead">${iconBox({ label: avatarText(d.name), size: 64, iconSize: 24, circle: true, cls: 't3-ibox--success t3-ibox--h2' })}
    <div><h2>${esc(d.name)}</h2>${gap(4)}<p>${d.type === 'person' ? 'Cá nhân' : 'Tổ chức'} • ${esc(roleText(d.roles))}</p>${gap(8)}${tag}</div></div>`;
}
const avatarText = (name) => avatar(name).match(/<b>(.*?)<\/b>/)[1];

/** Nhãn nhỏ cạnh tiêu đề thẻ đóng: đệm 6 / 2, bo 8, 10 w600; nền màu 10%. */
const miniBadge = (text, tone) => `<span class="t3-mini t3-mini--${tone}">${esc(text)}</span>`;

/**
 * PartnerDetailExpandableCard: Material surface, viền borderDefault bo 12; ListTile dense (cao 48, đệm ngang 16):
 * icon 20 textSecondary | tiêu đề bodyDefault w500 | [nhãn + khe 4] + expandLess / chevronRight 24 textMuted. Mở: Divider + đệm 16 / 12.
 */
function expCard({ title, ic, badge = '', open = false, body = '' }) {
  return `<section class="t3-exp"><div class="t3-exp__head"><i class="t3-exp__icon">${icon(ic)}</i><b>${esc(title)}</b>${!open && badge ? `${badge}<i class="t3-gap-h4"></i>` : ''}<i class="t3-exp__chev">${icon(open ? 'chevronUp' : 'chevronRight')}</i></div>${open ? `<hr class="t3-divider"><div class="t3-exp__body">${body}</div>` : ''}</section>`;
}
const kv = (label, value) => `<div class="t3-kv"><span>${esc(label)}</span>${gap(4)}${value ? `<b>${esc(value)}</b>` : '<b class="is-empty">—</b>'}</div>`;
const kvs = (rows) => rows.map(([l, v]) => kv(l, v)).join(gap(12));

function mainInfo(d, open) {
  const p = d.person; const o = d.org;
  const rows = d.type === 'person'
    ? [['Danh xưng', p.title], ['Họ và tên', p.fullName], ['Tên thường gọi', p.nickname], ['SĐT chính', p.phone], ['SĐT phụ', p.phone2], ['Email', p.email]]
    : [['Loại tổ chức', o.type], ['Tên tổ chức', o.name], ['Tên viết tắt', o.shortName], ['Tên quốc tế', o.intlName], ['SĐT chính', o.phone], ['Email', o.email]];
  return expCard({ title: d.type === 'person' ? 'Thông tin cá nhân' : 'Thông tin tổ chức', ic: 'user', open, body: kvs(rows) });
}

function contactsCard(d, open) {
  const n = d.contacts.length;
  const list = n ? [...d.contacts].sort((a, b) => (b.primary ? 1 : 0) - (a.primary ? 1 : 0)).slice(0, 2).map((c) => `<div class="t3-dcontact">${avatar(c.name)}<div>
      <div class="t3-dcontact__name"><b>${esc(c.name)}</b>${c.primary ? '<span class="t3-stag t3-stag--success">Chính</span>' : ''}</div>
      ${c.role ? `${gap(4)}<span>${esc(c.role)}</span>` : ''}${c.phone ? `${gap(4)}<span>${esc(c.phone)}</span>` : ''}${c.email ? `${gap(4)}<span>${esc(c.email)}</span>` : ''}</div></div>`).join(gap(12))
    : `<p class="t3-small t3-mb8">Chưa có người liên hệ.</p>`;
  const body = `${list}${gap(12)}<hr class="t3-divider">${gap(12)}<div class="t3-dcontact__acts"><button type="button" class="t3-textbtn">${icon('plusCircle')}<span>Thêm người liên hệ</span></button><button type="button" class="t3-textbtn t3-textbtn--r"><span>${n ? `Xem tất cả (${n})` : 'Tất cả'}</span>${icon('chevronRight')}</button></div>`;
  return expCard({ title: 'Người liên hệ', ic: 'users', open, badge: n ? miniBadge(String(n), 'neutral') : miniBadge('Chưa có', 'warning'), body });
}

function invoiceCard(d, open) {
  const b = invoiceBadge(d);
  return expCard({ title: 'Hóa đơn / thuế', ic: 'receipt', open, badge: b ? miniBadge(b, 'danger') : '', body: kvs([['MST', d.taxCode], ['Tên xuất hóa đơn', d.invoice.name], ['Email nhận hóa đơn', d.invoice.email], ['Địa chỉ xuất hóa đơn', d.invoice.address]]) });
}
function deliveryCard(d, open) {
  const x = d.delivery;
  const empty = !x.province && !x.commune && !x.address;
  return expCard({ title: 'Địa chỉ giao hàng', ic: 'mapPin', open, badge: empty ? miniBadge('Chưa có', 'warning') : '', body: kvs([['Tỉnh / Thành phố', x.province], ['Xã / Phường', x.commune], ['Địa chỉ chi tiết', x.address]]) });
}
function noteCard(d, open) {
  return expCard({ title: 'Ghi chú', ic: 'stickyNote', open, badge: d.note ? '' : miniBadge('Chưa có', 'warning'), body: d.note ? `<p class="t3-dval">${esc(d.note)}</p>` : '<p class="t3-dval is-empty">—</p>' });
}
/** PartnerDetailSystemCard: tiêu đề 'Lịch sử thao tác ' (dấu cách cuối), icon settings; chạm → PT-12. */
const systemCard = () => expCard({ title: 'Lịch sử thao tác ', ic: 'settings' });

/** CustomerReceivableSummaryCard: viền borderDefault bo 12, đệm 16; "Công nợ" labelDefault w700, khe 2, dòng phụ bodySmall, [khe 2 + nhãn quá hạn]; chevron 20. Đang tải / lỗi → không vẽ gì. */
function receivableCard(r) {
  if (!r || r.loading) return '';
  const has = !!r.owed;
  const due = has && r.overdue > 0 ? `${gap(2)}<span class="t3-due">${icon('alert')}<span>Quá hạn ${r.overdue} ngày</span></span>` : '';
  return `<section class="t3-recv"><div><b>Công nợ</b>${gap(2)}<span>${has ? `Còn nợ ${esc(r.owed)} · ${r.orders} đơn` : 'Không còn nợ'}</span>${due}</div><i>${icon('chevronRight')}</i></section>`;
}

/** SupplierProgramsSection: VCard đệm 16; đầu "Chương trình ưu đãi" bodyDefault w600 | "Xem tất cả" bodySmall w500 primary + › 16; khe 12; dòng K6TaskRow (VListRow đệm 12 / 8) cách 8. */
function programsCard(list, { loading = false, error = false } = {}) {
  let body;
  if (loading) body = skeleton(44, { radius: 4 });
  else if (error) body = `<div class="t3-row"><p class="t3-small t3-grow">Không tải được chương trình ưu đãi.</p>${button('Thử lại', { variant: 'tertiary' })}</div>`;
  else if (!list.length) body = `<p class="t3-small">Chưa có chương trình đang chạy.</p>${gap(8)}<span>${button('Tạo chương trình', { variant: 'tertiary', cls: 't3-btn--lead' }).replace('<span>', `${icon('plus')}<span>`)}</span>`;
  else {
    body = list.map((p) => {
      const below = p.progress
        ? `<div class="t3-prog"><span class="t3-prog__bar"><i style="width:${Math.min(1, p.progress[0]) * 100}%"></i></span><span class="t3-mono">${esc(p.progress[1])}</span></div>`
        : `<span class="t3-small">${esc(p.summary)}</span>`;
      return `<div class="t3-lrow"><div class="t3-lrow__text"><b>${esc(p.name)}</b>${gap(2)}<span class="t3-small">${esc(p.kind)}</span>${gap(4)}${below}</div><span class="t3-badge t3-badge--${p.status[1]}">${esc(p.status[0])}</span><i class="t3-lrow__chev">${icon('chevronRight')}</i></div>`;
    }).join(gap(8));
  }
  return card(`<div class="t3-cardhead"><b>Chương trình ưu đãi</b><button type="button" class="t3-linksm"><span>Xem tất cả</span>${icon('chevronRight')}</button></div>${gap(12)}${body}`, { cls: 't3-progcard' });
}

/** ReceiptHistorySection: không có thẻ bọc; đầu "Lịch sử nhập hàng" headingH4 + nút link "Xem tất cả"; khe 8; mỗi phiếu một VCard + khe 4. Rỗng / lỗi: một dòng Text mặc định đệm 8. Đang tải: vòng Material. */
function receiptsBlock(list, { loading = false } = {}) {
  if (loading) return `<div class="t3-rload">${centerLoading({ material: true })}</div>`;
  if (!list.length) return '<p class="t3-plaintext">Chưa có lịch sử nhập hàng từ nhà cung cấp này.</p>';
  return `<div class="t3-rhead"><b>Lịch sử nhập hàng</b>${button('Xem tất cả', { variant: 'link' })}</div>${gap(8)}${list.map((r) => `${card(`<div class="t3-receipt"><div><b>${esc(r.no)}</b>${gap(4)}<span>${esc(r.date)} · ${r.lines} dòng (${r.lots} lô)</span></div><strong>${esc(r.total)}</strong><i>${icon('chevronRight')}</i></div>`, { cls: 't3-card--tap' })}${gap(4)}`).join('')}`;
}

/** Thân hồ sơ đã tải (SingleChildScrollView đệm 16) + hàng nút đáy (không có ở đối tác hệ thống). */
function loadedBody(d, o) {
  const desc = missingDescription(d);
  const parts = [header(d), gap(16)];
  if (d.status === 'inactive') parts.push(banner('warning', 'KH & NCC này sẽ không được chọn cho giao dịch mới.'), gap(16));
  const cl = contactLine(d);
  if (cl) parts.push(`<div class="t3-quick">${icon('phone')}<span>${esc(cl)}</span></div>`, gap(16));
  if (d.system) parts.push(banner('info', 'Đối tác hệ thống, dùng cho phiếu nhận mua lẻ. Không sửa hoặc xoá được.'), gap(16));
  else if (desc && d.status === 'active') parts.push(banner('warning', 'Hồ sơ còn thiếu thông tin', desc), gap(16));
  parts.push(mainInfo(d, o.open.includes('main')), gap(8));
  if (!d.system && d.roles.includes('customer')) { const rc = receivableCard(o.blocksLoading ? { loading: true } : d.receivable); parts.push(rc, gap(8)); }
  if (d.type === 'organization') parts.push(contactsCard(d, o.open.includes('contacts')), gap(8));
  parts.push(invoiceCard(d, o.open.includes('invoice')), gap(8), deliveryCard(d, o.open.includes('delivery')), gap(8), noteCard(d, o.open.includes('note')), gap(8));
  if (!d.system && d.roles.includes('supplier')) {
    parts.push(`<div class="t3-supplier">${programsCard(d.programs || [], { loading: o.blocksLoading, error: o.programsError })}${gap(16)}${receiptsBlock(d.receipts || [], { loading: o.blocksLoading })}</div>`, gap(8));
  }
  parts.push(systemCard());
  const bar = d.system ? '' : `<div class="t3-dbar">${button('Chỉnh sửa', { variant: 'secondary', fg: 'success', full: true, disabled: !d.actions.includes('update') })}${button('Thao tác', { full: true, cls: 't3-btn--trail' }).replace('</span></button>', `</span>${icon('chevronUp')}</button>`)}</div>`;
  return `<div class="t3-form"><div class="t3-dscroll"${o.scrollEnd ? ' data-scroll-end' : ''}>${parts.join('')}</div>${bar}</div>`;
}

/** PartnerDetailLoadingSkeleton */
function skeletonBody() {
  const row = `<div class="t3-skrow">${skeleton(18, { w: '18px', radius: 4 })}<i class="t3-gap-h8"></i><span class="t3-grow">${skeleton(16, { radius: 4 })}</span><i class="t3-gap-h8"></i>${skeleton(12, { w: '12px', radius: 4 })}</div>`;
  return `<div class="t3-dskel"><div class="t3-dskel__head">${skeleton(64, { w: '64px', radius: 32 })}<div>${skeleton(18, { w: '160px', radius: 4 })}${gap(8)}${skeleton(14, { w: '100px', radius: 4 })}${gap(8)}${skeleton(12, { w: '80px', radius: 4 })}</div></div>${gap(24)}${Array.from({ length: 5 }, () => row).join(gap(12))}</div>`;
}

/** PartnerDetailErrorState: đệm 24 / 32; hình; khe 24; tiêu đề H3 w700; khe 12; mô tả; khe 32; nút secondary rộng 220 chữ xanh. */
const ERRORS = {
  error: { kind: 'box', title: 'Không tải được hồ sơ', desc: 'Vui lòng kiểm tra kết nối internet hoặc thử lại sau.', action: 'Thử lại' },
  'not-found': { kind: 'search', title: 'Không tìm thấy hồ sơ', desc: 'Hồ sơ có thể đã bị xóa hoặc không tồn tại\nhoặc bạn không có quyền xem.', action: 'Quay lại' },
  'contact-only': { kind: 'search', title: 'Không phải hồ sơ đối tác', desc: 'Người liên hệ chỉ quản lý trong hồ sơ tổ chức.\nKhông mở như hồ sơ cá nhân độc lập.', action: 'Quay lại' },
  'no-permission': { kind: 'lock', title: 'Không có quyền xem hồ sơ', desc: 'Bạn không có quyền truy cập hồ sơ\nKhách hàng & Nhà cung cấp.', action: 'Quay lại' },
};
function errorBody(key) {
  const e = ERRORS[key];
  const art = e.kind === 'box' ? iconBox({ ic: 'cloudOff', size: 64, iconSize: 28, radius: 16, cls: 't3-empty__media' })
    : e.kind === 'lock' ? `<div class="t3-art-lock">${icon('shield')}<span>?</span></div>`
      : `<div class="t3-art-search"><i class="a">${icon('fileText')}</i><b>?</b><i class="c">${icon('search')}</i></div>`;
  return `<div class="t3-derr">${art}${gap(24)}<h2>${esc(e.title)}</h2>${gap(12)}<p>${esc(e.desc).replace(/\n/g, '<br>')}</p>${gap(32)}<span class="t3-derr__btn">${button(e.action, { variant: 'secondary', fg: 'success', full: true })}</span></div>`;
}

/** PartnerDetailPage: VPageScaffold("Hồ sơ KH & NCC", showBackButton: !isSplit). */
export function detailPage(o, v, placeWidth, split) {
  const d = DETAILS[o.id];
  let body;
  if (o.kind === 'loading') body = skeletonBody();
  else if (ERRORS[o.kind]) body = `<div class="t3-form t3-form--center">${errorBody(o.kind)}</div>`;
  else body = loadedBody(d, o);
  return scaffold({ appbar: appBar('Hồ sơ KH & NCC', { back: !split }), body, placeWidth, windowWidth: v.width });
}

// ---------------------------------------------------------------- sheet

/** PartnerDetailActionSheet (không tiêu đề sheet): "Thao tác hồ sơ" H3 w700 (đệm 16 / 16 / 16 / 8); thẻ thao tác (đệm 16 / 8); "Hủy" secondary đầy ngang. */
export function actionSheet(d) {
  const a = sheetActions(d);
  const inactive = d.status === 'inactive';
  const row = (ic, tone, title, sub) => `<div class="t3-actcard">${iconBox({ ic, size: 44, iconSize: 22, circle: true, cls: `t3-ibox--${tone}` })}<div><b>${esc(title)}</b>${gap(4)}<span>${esc(sub)}</span></div><i>${icon('chevronRight')}</i></div>`;
  return `<div class="t3-actsheet"><h2 class="t3-actsheet__title">Thao tác hồ sơ</h2>
    ${a.transform ? row('building', 'success', 'Chuyển thành tổ chức', 'Chuyển hồ sơ cá nhân hiện tại sang hồ sơ tổ chức.') : ''}
    ${a.toggle ? (inactive ? row('power', 'success', 'Kích hoạt lại', 'Cho phép sử dụng lại trong hệ thống.') : row('pause', 'warning', 'Ngừng hoạt động', 'Tạm ngừng sử dụng trong hệ thống.')) : ''}
    ${a.del ? row('trash', 'danger', 'Xóa hồ sơ', 'Xóa mềm, không hiển thị trong danh sách.') : ''}
    <div class="t3-actsheet__cancel">${button('Hủy', { variant: 'secondary', full: true })}</div></div>`;
}

const confirmHead = (ic, tone, title) => `<div class="t3-center-row">${iconBox({ ic, size: 64, iconSize: 32, circle: true, cls: `t3-ibox--${tone}a` })}</div>${gap(16)}<h2 class="t3-ctitle">${esc(title)}</h2>${gap(12)}`;
const reasonField = () => `${gap(20)}<p class="t3-reason">Lý do (không bắt buộc)</p>${gap(8)}${textArea({ hint: 'Nhập lý do (nếu có)', minLines: 3 })}${gap(4)}<p class="t3-count">0/200</p>`;
const closeSmall = () => `<div class="t3-close32"><button type="button" aria-label="Đóng">${icon('close')}</button></div>`;

/** PartnerDeactivateConfirmationSheet (đệm 16 / 8 / 16 / 16). */
export function deactivateSheet(primaryOf = null) {
  const warn = primaryOf ? `${gap(16)}${banner('warning', '', `Người này đang là liên hệ chính của “${primaryOf}”. Sau khi ngừng hoạt động, tổ chức sẽ không còn người liên hệ chính.`)}` : '';
  return `<div class="t3-confirm">${confirmHead('pause', 'warning', 'Ngừng hoạt động KH & NCC?')}<p class="t3-cdesc">KH &amp; NCC này sẽ không còn được chọn cho giao dịch mới.<br>Hồ sơ và lịch sử vẫn được giữ lại.</p>${warn}${reasonField()}${gap(20)}<div class="t3-grid2">${button('Hủy', { variant: 'secondary', fg: 'success', full: true })}${button('Ngừng hoạt động', { full: true })}</div></div>`;
}
/** PartnerReactivateConfirmationSheet */
export const reactivateSheet = () => `<div class="t3-confirm">${confirmHead('power', 'success', 'Kích hoạt lại KH & NCC?')}<p class="t3-cdesc">KH &amp; NCC này sẽ có thể được chọn lại cho giao dịch mới.</p>${gap(20)}<div class="t3-grid2">${button('Hủy', { variant: 'secondary', fg: 'success', full: true })}${button('Kích hoạt lại', { full: true })}</div></div>`;
/** PartnerSoftDeleteConfirmationSheet (đệm 16 / 4 / 16 / 16, nút đóng riêng 32). */
export const softDeleteSheet = () => `<div class="t3-confirm t3-confirm--x">${closeSmall()}${confirmHead('trash', 'danger', 'Xóa hồ sơ KH & NCC?')}<p class="t3-cdesc">Hồ sơ sẽ bị xóa khỏi danh sách làm việc và không còn được chọn cho giao dịch mới.</p>${gap(8)}<p class="t3-cdesc t3-cdesc--strong">Thao tác này không xóa giao dịch hoặc chứng từ đã phát sinh.</p>${reasonField()}${gap(20)}<div class="t3-grid2">${button('Hủy', { variant: 'secondary', full: true })}${button('Xóa hồ sơ', { tone: 'danger', full: true })}</div></div>`;
/** PartnerDeleteBlockedSheet: icon cảnh báo 56 (không hộp). showDeactivateAction false → chỉ "Quay lại". */
export function deleteBlockedSheet(canDeactivate) {
  const btns = canDeactivate ? `<div class="t3-grid2">${button('Quay lại', { variant: 'secondary', fg: 'success', full: true })}${button('Ngừng hoạt động', { full: true })}</div>` : button('Quay lại', { variant: 'secondary', fg: 'success', full: true });
  return `<div class="t3-confirm t3-confirm--x">${closeSmall()}<div class="t3-bigicon t3-bigicon--warning">${icon('alert')}</div>${gap(16)}<h2 class="t3-ctitle">Không thể xóa hồ sơ</h2>${gap(12)}<p class="t3-cdesc">KH &amp; NCC đã phát sinh giao dịch hoặc chứng từ liên quan nên không thể xóa.</p>${canDeactivate ? `${gap(8)}<p class="t3-cdesc">Bạn có thể ngừng hoạt động để tránh sử dụng trong giao dịch mới.</p>` : ''}${gap(20)}${btns}</div>`;
}
/** PartnerDeletePrimaryContactBlockedSheet: tự vẽ thêm tay kéo 40 × 4 (sheet đã có tay kéo 36 × 4). */
export const deletePrimaryBlockedSheet = (org) => `<div class="t3-confirm t3-confirm--c"><span class="t3-ownhandle"></span>${gap(20)}<div class="t3-bigicon t3-bigicon--danger t3-bigicon--44">${icon('trash')}</div>${gap(12)}<h2 class="t3-ctitle">Không thể xóa hồ sơ</h2>${gap(8)}<p class="t3-cdesc">Hồ sơ này đang là người liên hệ chính của “${esc(org)}”. Hãy đổi hoặc gỡ người liên hệ chính trước khi xóa hồ sơ.</p>${gap(16)}<div class="t3-grid2">${button('Đóng', { variant: 'secondary', fg: 'success', full: true })}${button('Xem tổ chức', { full: true })}</div></div>`;

// ---------------------------------------------------------------- toast

export const TOASTS = {
  created: ['success', 'Thành công', 'Đã tạo KH & NCC thành công'],
  updated: ['success', 'Thành công', 'Đã cập nhật hồ sơ KH & NCC'],
  deactivated: ['success', 'Thành công', 'Đã ngừng hoạt động KH & NCC.'],
  failed: ['danger', 'Không thành công', 'Hồ sơ đã được cập nhật bởi người khác. Vui lòng tải lại.'],
};
export const vtoast = (key) => toast(...TOASTS[key]);
/** _PartnerTransformSuccessToast: SnackBar trong suốt + Container riêng (lề 16 / 4, đệm 16 / 14, nền textPrimary, chấm 24 check 14, × 20 trắng 54%). */
export const transformToast = () => `<div class="t3-ttoast" role="status"><span class="t3-ttoast__dot">${icon('check')}</span><span>Đã chuyển đổi thành công.</span><i>${icon('close')}</i></div>`;

// ---------------------------------------------------------------- ca → trạng thái

/** Trạng thái hồ sơ của từng ca. o: { id, kind, open: [], scrollEnd, blocksLoading, programsError }. */
export function detailState(state) {
  const o = { id: 'p1', kind: 'loaded', open: [], scrollEnd: false, blocksLoading: false, programsError: false };
  const map = {
    'org-both': {}, 'org-both-end': { scrollEnd: true }, 'org-expanded': { open: ['main', 'contacts'] },
    'blocks-loading': { blocksLoading: true, scrollEnd: true }, 'programs-error': { programsError: true, scrollEnd: true },
    'person-missing': { id: 'p2' }, 'person-expanded': { id: 'p2', open: ['main', 'invoice', 'delivery', 'note'] },
    'supplier-empty': { id: 'p4', scrollEnd: true }, inactive: { id: 'p5' }, system: { id: 'p6' }, 'system-end': { id: 'p6', scrollEnd: true },
    'person-both': { id: 'p7', scrollEnd: true },
    loading: { kind: 'loading' }, error: { kind: 'error' }, 'not-found': { kind: 'not-found' }, 'contact-only': { kind: 'contact-only' }, 'no-permission': { kind: 'no-permission' },
  };
  return { ...o, ...(map[state] || {}) };
}
