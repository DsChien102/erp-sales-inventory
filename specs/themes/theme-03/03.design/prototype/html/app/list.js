// PT-01 Danh sách KH & NCC, PT-02 Bộ lọc / Sắp xếp (sheet), PT-03 "Thêm KH & NCC mới" (sheet), không có quyền xem.
// Nguồn Flutter (apps/erp/lib/features/partner/):
//   presentation/partner_area_shell.dart (VListDetailLayout: đủ 840 → danh sách 360 | VDivider | hồ sơ), core/router/app_router.dart (cột phải khi chưa chọn)
//   presentation/pages/partner_list_page.dart, widgets/{partner_list_search_bar, partner_list_quick_filters, partner_list_header_row,
//     partner_list_body, partner_list_item_tile, partner_list_item_skeleton_tile, partner_filter_bottom_sheet, partner_sort_bottom_sheet,
//     partner_create_action_sheet, partner_no_permission_view}.dart
//   logic/partner_list_state.dart, logic/partner_list_cubit.dart
// widgets/partner_active_filters.dart (chip lọc đang áp + "Xóa lọc") không được trang nào dùng → không vẽ (README).
import { icon } from '../shared/icons.js';
import {
  adaptiveSheet, avatar, badge, button, card, chip, emptyDesc, emptyMedia, emptyState, emptyTitle, esc, fab, gap,
  iconBox, radioList, scaffold, appBar, searchBar, skeleton,
} from './ds.js';
import { PARTNERS, TOTAL } from './data.js';

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

/** PartnerListItemTile._roleLabel */
export function roleLabel(roles) {
  if (roles.includes('customer') && roles.includes('supplier')) return 'KH & NCC';
  if (roles.includes('customer')) return 'Khách hàng';
  if (roles.includes('supplier')) return 'Nhà cung cấp';
  return 'Chưa có vai trò';
}
/** PartnerListItemTile._subtitle */
export const itemSubtitle = (p) => `${p.type === 'person' ? 'Cá nhân' : 'Tổ chức'} · ${roleLabel(p.roles)}`;

/** Số trên nút lọc (partner_list_page.dart): loại + vai trò + trạng thái + thời gian cập nhật (vai trò cũng đếm dù đã có chip nhanh). */
export const filterCount = (f) => ['type', 'role', 'status', 'updated'].filter((k) => f[k]).length;

/** PartnerListHeaderRow: có từ khoá / lọc → "<total> kết quả phù hợp", không → "Danh sách đối tác". */
export const headerLabel = (f, total) => (f.query != null || f.type || f.role || f.status || f.updated ? `${total} kết quả phù hợp` : 'Danh sách đối tác');

/**
 * PartnerListBody khi danh sách rỗng: chỉ xét từ khoá. Có từ khoá → "Không tìm thấy kết quả";
 * không có từ khoá (kể cả khi đang lọc) → "Chưa có KH & NCC".
 */
export const emptyKind = (f) => (f.query ? 'no-result' : 'empty');

// ---------------------------------------------------------------- phần màn

const ROLE_CHIPS = [[null, 'Tất cả'], ['customer', 'Khách hàng'], ['supplier', 'Nhà cung cấp'], ['both', 'KH & NCC']];

/** VPagePadding(Row[Expanded(VSearchBar), khe 8, nút lọc VIconBox 44 viền + Badge số]). */
function searchRow(f) {
  const n = filterCount(f);
  const btn = `<span class="t3-filterbtn${n ? ' is-active' : ''}">${iconBox({ ic: 'tune', size: 44, iconSize: 20, cls: 't3-filterbtn__box' })}${n ? `<b class="t3-filterbtn__badge">${n}</b>` : ''}</span>`;
  return `<div class="t3-pad t3-row">${searchBar({ value: f.query || '', hint: 'Tìm tên, SĐT, email, MST...', clear: !!f.query })}${btn}</div>`;
}

const quickFilters = (role) => `<div class="t3-hscroll"><div class="t3-pad t3-chiprow">${ROLE_CHIPS.map(([v, l]) => chip(l, { tone: role === v ? 'primary' : 'neutral' })).join('')}</div></div>`;

const headerRow = (f, total) => `<div class="t3-pad t3-listhead"><b>${esc(headerLabel(f, total))}</b><button type="button" class="t3-sortbtn">${icon('swapVert')}<span>Sắp xếp</span></button></div>`;

/** PartnerListItemTile: VCard(Row start, khe 12: VAvatar 40 | cột chữ | VBadge). */
export function itemTile(p, { selected = false } = {}) {
  const lines = [
    `<b class="t3-item__name">${esc(p.name)}</b>`,
    `<span>${esc(itemSubtitle(p))}</span>`,
    p.phone ? `<span>${esc(p.phone)}</span>` : '',
    p.taxCode ? `<span>MST ${esc(p.taxCode)}</span>` : '',
    p.updated ? `<span class="is-muted">Cập nhật ${esc(p.updated)}</span>` : '',
  ].filter(Boolean).join('');
  const b = p.status === 'active' ? badge('Đang hoạt động', { tone: 'success' }) : badge('Ngừng hoạt động', { tone: 'warning', small: true });
  return card(`<div class="t3-item">${avatar(p.name)}<div class="t3-item__text">${lines}</div>${b}</div>`, { selected, cls: 't3-card--tap' });
}

function listBody(v) {
  const { kind, f } = v;
  if (kind === 'loading') {
    return `<div class="t3-listscroll t3-pad">${Array.from({ length: 8 }, () => skeleton(128)).join('')}</div>`;
  }
  if (kind === 'error') {
    return emptyState({
      tone: 'danger',
      header: [emptyMedia('cloudOff'), emptyTitle('Không tải được danh sách'), emptyDesc('Vui lòng kiểm tra kết nối internet\nhoặc thử lại sau.')],
      content: `${gap(32)}${button('Thử lại')}`,
    });
  }
  if (kind === 'empty' || kind === 'no-result') {
    const ek = kind === 'empty' ? emptyKind(f) : 'no-result';
    const head = ek === 'no-result'
      ? [emptyMedia('search'), emptyTitle('Không tìm thấy kết quả'), gap(8), emptyDesc(`Thử kiểm tra lại từ khóa "${f.query}"\nhoặc bộ lọc.`)]
      : [emptyMedia('users'), emptyTitle('Chưa có KH & NCC'), gap(8), emptyDesc('Thêm đối tác để bắt đầu bán hàng,\nnhập hàng và quản lý công nợ.')];
    const act = ek === 'no-result' ? button('Xóa từ khóa', { variant: 'tertiary' }) : v.canCreate ? button('Thêm KH & NCC', { variant: 'tertiary' }) : '';
    return `<div class="t3-pad">${emptyState({ bg: 'surface', fill: false, header: head, content: act ? `${gap(8)}${act}` : '' })}</div>`;
  }
  const items = v.items.map((p) => itemTile(p, { selected: p.id === v.selectedId })).join('');
  const tail = kind === 'more' ? Array.from({ length: 2 }, () => skeleton(128)).join('')
    : v.reachedMax ? '<p class="t3-endnote">Đã ở cuối danh sách</p>' : '';
  return `<div class="t3-listscroll t3-pad"${v.scrollEnd ? ' data-scroll-end' : ''}>${items}${tail}</div>`;
}

/** PartnerListPage: VPageScaffold("KH & NCC", subtitle "<total> đối tác", FAB khi có quyền tạo). */
export function listPage(v, placeWidth) {
  const total = v.kind === 'loading' ? 0 : v.total; // _lastTotal ?? 0 ở lần tải đầu
  const body = `<div class="t3-list">${gap(8)}${searchRow(v.f)}${gap(8)}${quickFilters(v.f.role)}${gap(8)}${headerRow(v.f, v.total)}${gap(8)}${listBody(v)}</div>`;
  return scaffold({
    appbar: appBar('KH & NCC', { subtitle: `${total} đối tác` }),
    body,
    fabHtml: v.canCreate ? fab('plus', 'Thêm KH & NCC') : '',
    placeWidth,
    windowWidth: v.width,
  });
}

/** PartnerNoPermissionView: VPageScaffold("KH & NCC") + Center(VEmptyState lock). Shell trả view này thay cả khu (không chia cột). */
export function noPermissionPage(v, placeWidth) {
  return scaffold({
    appbar: appBar('KH & NCC'),
    body: emptyState({ header: [emptyMedia('lock'), emptyTitle('Bạn không có quyền xem\nKH & NCC'), emptyDesc('Liên hệ quản trị viên để được cấp quyền.')] }),
    placeWidth,
    windowWidth: v.width,
  });
}

/** Cột phải khi chưa chọn hồ sơ (app_router.dart, '/partner' khi isSplitOf): Scaffold nền surfaceAlt + VEmptyState(info, tiêu đề). */
export const detailPlaceholder = () => `<div class="t3-page t3-page--alt">${emptyState({ header: [emptyMedia('info'), emptyTitle('Chọn một KH & NCC để xem chi tiết.')] })}</div>`;

// ---------------------------------------------------------------- sheet

const sectionTitle = (t) => `<p class="t3-sheet-sec">${esc(t)}</p>`;

/** PartnerFilterBottomSheet (showVAdaptiveSheet không tiêu đề). sel: {role, type, status, updated}. */
export function filterSheet(sel) {
  const wrap = (items) => `<div class="t3-wrap">${items.map(([on, l]) => chip(l, { tone: on ? 'primary' : 'neutral' })).join('')}</div>`;
  const time = `<div class="t3-timerow">${chip('7 ngày gần đây', { tone: sel.updated === 7 ? 'primary' : 'neutral', full: true })}${chip('30 ngày gần đây', { tone: sel.updated === 30 ? 'primary' : 'neutral', full: true })}${chip('Tùy chọn', { ic: 'calendar', full: true })}</div>`;
  return `<div class="t3-filter">
    <div class="t3-pad">
      ${gap(4)}<h2 class="t3-h4">Bộ lọc KH &amp; NCC</h2>${gap(16)}
      ${sectionTitle('Vai trò giao dịch')}${gap(12)}${wrap([[sel.role === 'customer', 'Khách hàng'], [sel.role === 'supplier', 'Nhà cung cấp'], [sel.role === 'both', 'KH & NCC']])}${gap(16)}
      ${sectionTitle('Loại hồ sơ')}${gap(12)}${wrap([[sel.type === 'person', 'Cá nhân'], [sel.type === 'organization', 'Tổ chức']])}${gap(16)}
      ${sectionTitle('Trạng thái')}${gap(12)}${wrap([[!sel.status, 'Tất cả'], [sel.status === 'active', 'Đang hoạt động'], [sel.status === 'inactive', 'Ngừng hoạt động']])}${gap(16)}
      ${sectionTitle('Thời gian cập nhật')}${gap(12)}${time}${gap(16)}
    </div>
    <div class="t3-sheet-actions t3-grid2">${button('Đặt lại', { variant: 'secondary', full: true })}${button('Áp dụng', { full: true })}</div>
  </div>`;
}

/** PartnerSortBottomSheet: VField(VFieldLabel "Sắp xếp danh sách" + VChoiceList 4 lựa chọn) + khe 8 + "Áp dụng". */
export const SORT_CHOICES = ['Cập nhật gần nhất', 'Cập nhật cũ nhất', 'Tên A-Z', 'Tên Z-A'];
export function sortSheet(selected) {
  return `<div class="t3-sort">
    <div class="t3-pad"><div class="t3-field"><span class="t3-label">Sắp xếp danh sách</span>${radioList(SORT_CHOICES, selected)}</div></div>
    ${gap(8)}<div class="t3-sheet-actions">${button('Áp dụng', { full: true })}</div>
  </div>`;
}

/** PartnerCreateActionSheet (showVAdaptiveSheet title "Thêm KH & NCC mới"): đệm 16, hai VCard bấm được, khe 12, khe 16 cuối. */
export function createTypeSheet() {
  const typeCard = (ic, title, desc) => card(`<div class="t3-typecard">${iconBox({ ic, cls: 't3-ibox--brand' })}<div><b>${esc(title)}</b>${gap(4)}<span>${esc(desc)}</span></div><i class="t3-typecard__chev">${icon('chevronRight')}</i></div>`, { cls: 't3-card--tap' });
  return `<div class="t3-createtype">${typeCard('user', 'Tạo cá nhân', 'Dành cho khách hàng hoặc cá nhân không có pháp nhân')}${gap(12)}${typeCard('building', 'Tạo tổ chức', 'Dành cho công ty, cửa hàng, đại lý, đơn vị kinh doanh')}${gap(16)}</div>`;
}

// ---------------------------------------------------------------- ca → trạng thái

const BASE_F = { query: null, role: null, type: null, status: null, updated: null };

/** Trạng thái màn danh sách của từng ca (dùng cho PT-01 và nền của PT-02 / PT-03). */
export function listState(state) {
  const v = { kind: 'loaded', f: { ...BASE_F }, items: PARTNERS, total: TOTAL, reachedMax: false, canCreate: true, selectedId: null, scrollEnd: false };
  switch (state) {
    case 'loading': v.kind = 'loading'; break;
    case 'search': Object.assign(v, { f: { ...BASE_F, query: 'thú y' }, items: [PARTNERS[0], PARTNERS[2], PARTNERS[3]], total: 3, reachedMax: true }); break;
    case 'quick-filter': Object.assign(v, { f: { ...BASE_F, role: 'customer' }, items: PARTNERS.filter((p) => p.roles.includes('customer')), total: 31 }); break;
    case 'filtered': Object.assign(v, { f: { ...BASE_F, role: 'customer', type: 'organization', status: 'active' }, items: [PARTNERS[0], PARTNERS[2]], total: 2, reachedMax: true }); break;
    case 'end': Object.assign(v, { items: PARTNERS.slice(3), reachedMax: true, scrollEnd: true }); break;
    case 'more': Object.assign(v, { kind: 'more', items: PARTNERS.slice(3), scrollEnd: true }); break;
    case 'empty': Object.assign(v, { kind: 'empty', items: [], total: 0 }); break;
    case 'empty-no-create': Object.assign(v, { kind: 'empty', items: [], total: 0, canCreate: false }); break;
    case 'filter-empty': Object.assign(v, { kind: 'empty', f: { ...BASE_F, type: 'person', status: 'inactive', updated: 7 }, items: [], total: 0 }); break;
    case 'no-result': Object.assign(v, { kind: 'no-result', f: { ...BASE_F, query: 'abc xyz' }, items: [], total: 0 }); break;
    case 'error': v.kind = 'error'; v.total = 0; break;
    case 'view-only': v.canCreate = false; break;
    default: break;
  }
  return v;
}
