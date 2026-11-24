// PR-01 Danh sách giá riêng, PR-02 Bộ lọc / Sắp xếp (sheet).
// Nguồn Flutter (apps/erp/lib/features/pricing/):
//   presentation/pages/pricing_list_page.dart (VPageScaffold, _PricingListErrorState, _PriceRuleListBody, _PriceRuleListSkeleton)
//   presentation/widgets/{price_rule_list_search_and_filter, price_rule_list_view, price_rule_card, price_rule_status_badge,
//     price_rule_filter_bottom_sheet, price_rule_sort_bottom_sheet}.dart
//   logic/{price_rule_list_cubit, price_rule_list_state, price_rule_list_filters}.dart
// Route /pricing nằm ngoài ShellRoute(StoreShell) → không thanh bên / thanh dưới; web: app bar hết ngang, thân cột 720 canh giữa.
import { appBar, icon, avatar, badge, button, card, chip, emptyMedia, emptyState, emptyTitle, emptyDesc, esc, fab, gap, radioList, scaffold, searchBar, skeleton } from './ds.js';
import { RULES, STATUS, money } from './data.js';

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

/** PriceRuleSortOptionLabel. */
export const SORTS = [
  ['updatedAtDesc', 'Cập nhật gần nhất'], ['updatedAtAsc', 'Cập nhật cũ nhất'], ['customerNameAsc', 'Tên khách hàng A-Z'],
  ['customerNameDesc', 'Tên khách hàng Z-A'], ['priceDesc', 'Giá riêng cao → thấp'], ['priceAsc', 'Giá riêng thấp → cao'],
  ['warningsFirst', 'Cảnh báo cần xử lý trước'],
];
export const sortLabel = (id) => SORTS.find(([k]) => k === id)[1];

/** PriceRuleAdvancedFilter.activeCount: đếm số nhóm khác null. */
export const activeCount = (f) => ['status', 'warning', 'source', 'updatedWithin'].filter((k) => f[k] != null).length;

/** PriceRuleCard._formatEffective: "từ – đến", không có ngày đến → "Không giới hạn". */
export const effectiveText = (from, to) => `${from} – ${to ?? 'Không giới hạn'}`;

/**
 * _PriceRuleListBody: thứ tự nhánh. Trả mã nhánh để test.
 * Nhánh "Không thể tải dữ liệu" không bao giờ tới: page đã thay cả thân bằng _PricingListErrorState khi Error + items rỗng.
 * Rỗng sau tìm / lọc vẫn rơi vào "Chưa có giá riêng nào" (không có L-04).
 */
export function bodyBranch({ kind, items }) {
  if (kind === 'error' && items === 0) return 'page-error';
  if (kind === 'loading-first') return 'skeleton';
  if (kind === 'no-permission') return 'no-permission';
  if (items === 0 && kind === 'loaded') return 'empty';
  return 'list';
}

// ---------------------------------------------------------------- phần màn

const DEFAULT_FILTER = { status: null, warning: null, source: null, updatedWithin: null };

/** Trạng thái từng ca của PR-01. */
export function listState(state) {
  const base = { kind: 'loaded', items: RULES, total: 24, query: '', quick: 'all', filter: DEFAULT_FILTER, sort: 'updatedAtDesc', reachedMax: false, canCreate: true, scrollEnd: false };
  switch (state) {
    case 'loading': return { ...base, kind: 'loading-first', items: [], total: 0, canCreate: false };
    case 'search': return { ...base, query: 'an phát', items: RULES.filter((r) => r.customer.includes('An Phát')), total: 2, reachedMax: true };
    case 'search-loading': return { ...base, kind: 'loading-first', query: 'an ph', items: [] };
    case 'chip-applying': return { ...base, quick: 'applying', items: RULES.filter((r) => r.status === 'applying'), total: 15, reachedMax: true };
    case 'chip-below': return { ...base, quick: 'belowFloor', items: RULES.filter((r) => r.below), total: 1, reachedMax: true };
    case 'filtered': return { ...base, filter: { status: 'disabled', warning: null, source: 'manual', updatedWithin: null }, items: RULES.filter((r) => r.status === 'disabled'), total: 1, reachedMax: true };
    case 'sorted': return { ...base, sort: 'warningsFirst', items: [RULES[1], RULES[5], ...RULES.filter((_, i) => i !== 1 && i !== 5)] };
    case 'more': return { ...base, scrollEnd: true };
    case 'end': return { ...base, reachedMax: true, scrollEnd: true };
    case 'empty': return { ...base, items: [], total: 0, reachedMax: true };
    case 'no-result': return { ...base, query: 'xyz', items: [], total: 0, reachedMax: true };
    case 'error': return { ...base, kind: 'error', items: [], total: 0, canCreate: false };
    case 'error-more': return { ...base, kind: 'error', scrollEnd: true };
    case 'no-permission': return { ...base, kind: 'no-permission', items: [], total: 0, canCreate: false };
    case 'no-create': return { ...base, canCreate: false };
    default: return base;
  }
}

/** _FilterButton: VIconBox 44 (tune 20) bo 8; đang lọc → nền primary 10%, viền + icon primary; Badge Material số đếm lệch (4, −4). */
function filterButton(count) {
  const on = count > 0;
  return `<button type="button" class="t4-filterbtn${on ? ' is-active' : ''}" aria-label="Lọc quy tắc giá">${icon('tune')}${on ? `<b class="t4-filterbtn__badge">${count}</b>` : ''}</button>`;
}

/** PriceRuleListSearchAndFilter: hàng tìm (đệm 16/12/16/8), chip cuộn ngang (khe 8), khe 8, hàng "Sắp xếp: …" canh phải, khe 8. */
function searchAndFilter(s) {
  const chips = [['all', 'Tất cả'], ['applying', 'Đang áp dụng'], ['belowFloor', 'Dưới giá sàn']]
    .map(([id, label]) => chip(label, { tone: s.quick === id ? 'primary' : 'neutral' })).join('');
  return `<div class="t4-searchblock">
    <div class="t4-searchrow">${searchBar({ value: s.query, hint: 'Tìm theo khách hàng, SĐT, sản phẩm...', clear: !!s.query })}${filterButton(activeCount(s.filter))}</div>
    <div class="t4-chiprow">${chips}</div>
    <div class="t4-sortrow"><button type="button" class="t4-sortbtn"><span>Sắp xếp: ${esc(sortLabel(s.sort))}</span>${icon('chevronRight')}</button></div>
  </div>`;
}

/**
 * PriceRuleCard: VCard đệm 16 / 12. Avatar 40 | cột: [tên KH (w600, 2 dòng) / tên SP (w600, 2 dòng) / "Đơn vị: …" bodySmall] + cột badge (IntrinsicWidth),
 * khe 8, hàng giá (Giá riêng flex 3 | khe 16 | Giá niêm yết flex 2: caption muted + monoNumeric w700; dưới sàn → giá riêng đỏ), khe 8,
 * "Hiệu lực: …" bodySmall muted + chevronRight 18 muted.
 */
export function ruleCard(r) {
  const [label, tone] = STATUS[r.status];
  const badges = `<span class="t4-rcard__badges">${badge(label, { tone, small: true })}${r.below ? badge('Dưới giá sàn', { tone: 'danger', small: true }) : ''}</span>`;
  return card(`<div class="t4-rcard">
    ${avatar(r.customer)}
    <div class="t4-rcard__main">
      <div class="t4-rcard__top">
        <div class="t4-rcard__names"><b>${esc(r.customer)}</b><b>${esc(r.product)}</b><span>Đơn vị: ${esc(r.unit)}</span></div>
        ${badges}
      </div>
      <div class="t4-rcard__prices">
        <div class="t4-pricecol" style="flex:3"><small>Giá riêng</small><b class="${r.below ? 'is-danger' : ''}">${money(r.price)}</b></div>
        <div class="t4-pricecol" style="flex:2"><small>Giá niêm yết</small><b>${r.list != null ? money(r.list) : '—'}</b></div>
      </div>
      <div class="t4-rcard__eff"><span>Hiệu lực: ${esc(effectiveText(r.from, r.to))}</span>${icon('chevronRight')}</div>
    </div>
  </div>`, { cls: 't4-rcard-wrap', pad: false });
}

/** _PriceRuleListSkeleton: 6 VCard (đệm 12): tròn 40 | khe 16 | vạch 160×14, 120×12, ∞×14, 100×12 (khe 8). */
function listSkeleton() {
  const one = card(`<div class="t4-skelcard">${skeleton(40, { radius: 20, w: '40px' })}<div class="t4-skelcard__lines">${skeleton(14, { w: '160px', radius: 4 })}${skeleton(12, { w: '120px', radius: 4 })}${skeleton(14, { radius: 4 })}${skeleton(12, { w: '100px', radius: 4 })}</div></div>`, { pad: false, cls: 't4-skelcard-wrap' });
  return `<div class="t4-listscroll">${one.repeat(6)}</div>`;
}

/** Legacy VEmptyState (icon, title, description, actionLabel): canh giữa; nút VButton medium cách 32. tone primary / warning / danger đổi hộp icon. */
export function legacyEmpty({ ic, title, desc = '', action = '', tone = '' }) {
  const head = [emptyMedia(ic), emptyTitle(title)];
  if (desc) head.push(emptyDesc(desc));
  return emptyState({ header: head, tone, content: action ? `${gap(32)}${button(action)}` : '' });
}

function listBody(s) {
  const branch = bodyBranch({ kind: s.kind, items: s.items.length });
  if (branch === 'skeleton') return listSkeleton();
  if (branch === 'no-permission') return legacyEmpty({ ic: 'lock', title: 'Không có quyền truy cập', desc: 'Bạn không có quyền xem danh sách giá riêng.' });
  if (branch === 'empty') return legacyEmpty({ ic: 'tag', title: 'Chưa có giá riêng nào', desc: 'Tạo giá riêng để bắt đầu.', action: s.canCreate ? 'Thêm giá riêng' : '' });
  // PriceRuleListView: đệm 16 / 8, khe 8; chưa hết trang → ô VSkeleton 120×12 giữa (đệm 16) cuối danh sách.
  const loader = s.reachedMax ? '' : `<div class="t4-loadmore">${skeleton(12, { w: '120px', radius: 4 })}</div>`;
  return `<div class="t4-listscroll"${s.scrollEnd ? ' data-scroll-end' : ''}>${s.items.map(ruleCard).join('')}${loader}</div>`;
}

export function listPage(s, v) {
  const isInitialError = s.kind === 'error' && s.items.length === 0;
  const body = isInitialError
    ? legacyEmpty({ ic: 'cloudOff', tone: 'danger', title: 'Không tải được danh sách', desc: 'Vui lòng kiểm tra kết nối internet\nhoặc thử lại sau.', action: 'Thử lại' })
    : `<div class="t4-list">${searchAndFilter(s)}${listBody(s)}</div>`;
  const showFab = !isInitialError && s.canCreate;
  return scaffold({
    appbar: appBar('Giá riêng', { subtitle: `${s.total} giá riêng` }),
    body,
    fabHtml: showFab ? fab('plus', 'Thêm giá riêng') : '',
    placeWidth: v.width, windowWidth: v.width,
  });
}

// ---------------------------------------------------------------- PR-02 sheet

/** PriceRuleFilterBottomSheet: chip đặt cứng tone primary → mọi chip xanh như đang chọn, kể cả chip không chọn. */
export function filterSheet(f = DEFAULT_FILTER) {
  const group = (title, items) => `<p class="t4-fs-title">${esc(title)}</p><div class="t4-fs-wrap">${items.map(([label]) => chip(label, { tone: 'primary' })).join('')}</div>`;
  return `<div class="t4-fs">
    ${group('Trạng thái', [['Tất cả', f.status == null], ['Đang áp dụng', f.status === 'applying'], ['Đã tắt', f.status === 'disabled'], ['Hết hiệu lực', f.status === 'expired'], ['Cần kiểm tra', f.status === 'needsReview']])}
    ${group('Cảnh báo', [['Tất cả', f.warning == null], ['Dưới giá sàn', f.warning === 'belowFloor']])}
    ${group('Nguồn tạo', [['Tất cả', f.source == null], ['Tạo thủ công', f.source === 'manual'], ['Nhập Excel', f.source === 'excelImport']])}
    ${group('Thời gian cập nhật', [['7 ngày gần đây', f.updatedWithin === 'last7Days'], ['30 ngày gần đây', f.updatedWithin === 'last30Days']])}
    <p class="t4-fs-count">Đang chọn ${activeCount(f)} bộ lọc</p>
  </div>
  <div class="t4-sheet-actions t4-row2">${button('Đặt lại', { variant: 'secondary', full: true })}${button('Áp dụng', { full: true })}</div>`;
}

/** PriceRuleSortBottomSheet: không tiêu đề sheet; VChoiceList title (VFieldLabel) "Sắp xếp danh sách" + 7 lựa chọn; khe 8; "Áp dụng" đầy ngang (đệm 16). */
export function sortSheet(sel = 'updatedAtDesc') {
  return `<div class="t4-pad"><span class="t4-label">Sắp xếp danh sách</span>${radioList(SORTS.map(([, l]) => l), sortLabel(sel))}</div>
    <div class="t4-gap" style="height:8px"></div>
    <div class="t4-sheet-actions">${button('Áp dụng', { full: true })}</div>`;
}

export const filterSheetState = (state) => (state === 'selected' ? { status: 'disabled', warning: null, source: 'manual', updatedWithin: 'last30Days' } : DEFAULT_FILTER);
