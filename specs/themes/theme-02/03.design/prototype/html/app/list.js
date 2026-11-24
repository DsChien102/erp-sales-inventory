// SP-01 Danh sách sản phẩm, SP-02 Lọc thông tin bổ sung (sheet), cột phải khi chưa chọn sản phẩm (web).
// Nguồn Flutter (apps/erp/lib/features/catalog/):
//   presentation/product_area_shell.dart (VListDetailLayout: đủ 840 → danh sách 360 | VDivider | PCC), core/router/app_router.dart ('/products/items' khi isSplitOf)
//   presentation/pages/product_catalog_tab_page.dart, widgets/{product_list_search_bar, product_catalog_filter_chips, product_list_filter,
//     product_catalog_list_body, product_list_item_tile, product_list_item_skeleton_tile, custom_field_filter_sheet}.dart
//   logic/product_list_cubit.dart (pageSize 20, số đếm chip), data/models/product_search.dart (ProductListItemReadRow)
import { icon } from '../shared/icons.js';
import { appBar, button, card, chip, emptyMedia, emptyState, emptyTitle, emptyDesc, esc, fab, gap, iconBox, scaffold, searchBar, skeleton } from './ds.js';
import { COUNTS, DELETED, PRODUCTS, money, photo } from './data.js';

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

/** ProductListFilter (product_list_filter.dart). */
export const FILTERS = [
  ['all', 'Tất cả'], ['readyToSell', 'Sẵn sàng bán'], ['incomplete', 'Thiếu dữ liệu'], ['inactive', 'Ngừng KD'],
  ['inStock', 'Còn hàng'], ['outOfStock', 'Hết hàng'], ['deleted', 'Đã xóa'],
];
export const filterLabel = (id) => FILTERS.find(([k]) => k === id)[1];

/**
 * ProductCatalogFilterChips: "Nhãn (n)" khi có số, không thì chỉ nhãn.
 * counts: all = globalTotalCount; readyToSell / incomplete / inactive ghi khi tải danh sách không lọc;
 * inStock / outOfStock chỉ khi danh sách không lọc đã tải hết (hasReachedMax); deleted chỉ khi đang ở chip "Đã xóa".
 */
export const chipLabel = (id, counts) => (counts[id] != null ? `${filterLabel(id)} (${counts[id]})` : filterLabel(id));

/**
 * Lọc tồn cục bộ (product_catalog_list_body.dart): chỉ lọc trên các dòng đã tải (không gọi máy chủ).
 * inStock: stockQuantity > 0; outOfStock: stockQuantity == 0.
 */
export function localStockFilter(items, filter) {
  if (filter === 'inStock') return items.filter((i) => i.stock != null && i.stock > 0);
  if (filter === 'outOfStock') return items.filter((i) => i.stock != null && i.stock === 0);
  return items;
}

/** _ProductCatalogEmptyState: [tiêu đề, mô tả | null, có nút "Tạo sản phẩm"]. Không xét từ khoá. */
export function emptyCopy(filter, hasProducts) {
  if (filter === 'deleted') return ['Không có sản phẩm đã xóa.', null, false];
  if (!hasProducts) return ['Chưa có sản phẩm nào được tạo', null, true];
  if (filter !== 'all') return [`Không có sản phẩm "${filterLabel(filter)}"`, null, false];
  return ['Không tìm thấy sản phẩm', 'Hãy thử tìm kiếm với từ khóa khác hoặc tạo sản phẩm mới.', false];
}

/** _buildStockInfo: stockQuantity null → "Chưa TL tồn"; có stockLabel (= số tồn dạng chuỗi) → "Hết" (warning w500) / số trơn (bodyDefault); còn lại không vẽ gì. */
export function stockText(item) {
  if (item.stock == null) return { text: 'Chưa TL tồn', kind: 'muted' };
  if (item.stockLabel) return item.stock === 0 ? { text: 'Hết', kind: 'out' } : { text: item.stockLabel, kind: 'normal' };
  return null;
}

/** Giá trị trường bổ sung kiểu số: VNumberValidator.format (nguyên → không phần thập phân). */
export function cfDisplay(value) {
  const n = Number(value);
  if (value === '' || Number.isNaN(n)) return value;
  return Number.isInteger(n) ? n.toLocaleString('de-DE') : n.toLocaleString('de-DE', { maximumFractionDigits: 6 });
}

// ---------------------------------------------------------------- phần màn

/**
 * ProductListSearchBar: Padding(16 / 8) Row[Expanded(VSearchBar outlined), khe 8, _FilterButton].
 * _FilterButton: Badge(số, nền success, lệch 4 / -4) quanh VIconBox 44 (icon tune 20, bo input 8):
 *   thường nền surface + viền borderDefault + icon textPrimary; có lọc → nền successBg + viền success + icon success.
 */
function searchRow(v) {
  const n = v.cfFilters;
  const btn = `<span class="t2-filterbtn${n ? ' is-active' : ''}">${iconBox({ ic: 'tune', size: 44, iconSize: 20, cls: 't2-filterbtn__box' })}${n ? `<b class="t2-filterbtn__badge">${n}</b>` : ''}</span>`;
  return `<div class="t2-searchrow">${searchBar({ value: v.query || '', hint: 'Tìm tên, SKU, barcode, thông tin bổ sung...', clear: !!v.query })}${btn}</div>`;
}

/** ProductCatalogFilterChips: cuộn ngang, đệm ngang 16, Wrap khe 8; VChip(selected) → tone primary. Mỗi chip có vùng chạm 44. */
const filterChips = (v) => `<div class="t2-hscroll"><div class="t2-pad t2-chiprow">${FILTERS.map(([id]) => chip(chipLabel(id, v.counts), { tone: v.filter === id ? 'primary' : 'neutral' })).join('')}</div></div>`;

/** Ảnh 60 × 60 bo 8: CatalogStorageImage (ảnh thật) hoặc khung surfaceAlt + VIcons.image 24 textSecondary. */
const thumb = (item) => (item.img != null
  ? `<img class="t2-thumb" src="${photo(item.img)}" alt="" width="60" height="60">`
  : `<span class="t2-thumb t2-thumb--empty">${icon('image')}</span>`);

/**
 * ProductListItemTile: VCard(đệm 16, isSelected) Row(start)[ảnh 60, khe 8, cột]:
 *   tên bodyDefault w600 1 dòng "…"; đã xoá → khe 4 + VBadge "Đã xóa" (locked → neutral, nhỏ);
 *   tên thương mại → khe 4 + bodySmall textSecondary; trường bổ sung → khe 8 + Wrap(6 / 4) ô "Tên: giá trị" (đệm 8 / 2, nền surfaceAlt, bo 4, chữ 11 textSecondary);
 *   khe 8 + Row[Expanded 3: giá (bodyDefault w700) | "_" textMuted; Expanded 1: ĐVT chữ thường bodySmall | "–"; Expanded 2 phải: tồn].
 */
export function itemTile(item, { selected = false } = {}) {
  const st = stockText(item);
  const lines = [
    `<b class="t2-item__name">${esc(item.name)}</b>`,
    item.status === 'deleted' ? `${gap(4)}<span class="t2-badge t2-badge--neutral t2-badge--sm">Đã xóa</span>` : '',
    item.tradeName ? `${gap(4)}<span class="t2-item__trade">${esc(item.tradeName)}</span>` : '',
    item.cf.length ? `${gap(8)}<span class="t2-cfwrap">${item.cf.map(([k, val]) => `<span class="t2-cf">${esc(k)}: ${esc(cfDisplay(val))}</span>`).join('')}</span>` : '',
    gap(8),
    `<span class="t2-item__meta">
      <span class="t2-item__price">${item.price != null ? `<b>${esc(money(item.price))}</b>` : '<i>_</i>'}</span>
      <span class="t2-item__unit">${item.unit ? esc(item.unit.toLowerCase()) : '<i>–</i>'}</span>
      <span class="t2-item__stock">${st ? `<span class="is-${st.kind}">${esc(st.text)}</span>` : ''}</span>
    </span>`,
  ].join('');
  return card(`<div class="t2-item">${thumb(item)}<i class="t2-gap-h8"></i><div class="t2-item__text">${lines}</div></div>`, { selected, cls: 't2-card--tap' });
}

/** ProductListItemSkeletonTile: VCard(16) [60 × 60 bo 8, khe 8, cột: 160 × 16, khe 4, 100 × 12, khe 8, Row(72 × 14 | 40 × 12 giữa | 36 × 14 phải)]. */
const skelTile = () => card(`<div class="t2-item">${skeleton(60, { w: '60px', radius: 8 })}<i class="t2-gap-h8"></i><div class="t2-item__text">
  ${skeleton(16, { w: '160px', radius: 4 })}${gap(4)}${skeleton(12, { w: '100px', radius: 4 })}${gap(8)}
  <span class="t2-skelrow"><span style="flex:2">${skeleton(14, { w: '72px', radius: 4 })}</span><span class="t2-skelrow__mid">${skeleton(12, { w: '40px', radius: 4 })}</span><span class="t2-skelrow__end">${skeleton(14, { w: '36px', radius: 4 })}</span></span>
</div></div>`);

/** ProductCatalogListBody: ListView đệm 16 / 16 / đáy 8, mỗi dòng đệm đáy 8. */
function listBody(v) {
  if (v.kind === 'loading') return `<div class="t2-listscroll">${Array.from({ length: 8 }, skelTile).join('')}</div>`;
  // ProductListError: Center(VText 'Lỗi: …' bodyDefault danger canh giữa). Không có nút thử lại; kéo để tải lại cũng không có (RefreshIndicator chỉ bọc danh sách).
  if (v.kind === 'error') return `<div class="t2-center"><p class="t2-errtext">Lỗi: ${esc(v.error)}</p></div>`;
  const items = localStockFilter(v.items, v.filter);
  if (!items.length && v.kind !== 'more') {
    const [title, desc, act] = emptyCopy(v.filter, v.hasProducts);
    // Legacy VEmptyState(icon inventory, title, description, actionLabel): Center; nút VButton medium có icon + trắng 18, cách đầu 32.
    const head = [emptyMedia('inventory'), emptyTitle(title), ...(desc ? [emptyDesc(desc)] : [])];
    return emptyState({ header: head, content: act ? `${gap(32)}${button('Tạo sản phẩm', { cls: 't2-btn--lead' })}` : '' });
  }
  const tiles = items.map((p) => itemTile(p, { selected: p.id === v.selectedId })).join('');
  const tail = v.kind === 'more' ? Array.from({ length: 3 }, skelTile).join('')
    : v.reachedMax ? '<p class="t2-endnote">Đã ở cuối danh sách</p>' : '';
  return `<div class="t2-listscroll"${v.scrollEnd ? ' data-scroll-end' : ''}>${tiles}${tail}</div>`;
}

/**
 * ProductCatalogTabPage: VPageScaffold(tiêu đề "Sản phẩm", subtitle "<globalTotalCount ?? 0> sản phẩm", không nút ←,
 *   actions [IconButton ⋮ (onPressed rỗng)], FAB + nền success luôn hiện). Thân: tìm, chip, khe 12, danh sách.
 */
export function listPage(v, placeWidth) {
  const more = `<button type="button" class="t2-icon-btn" aria-label="Thêm">${icon('moreVert')}</button>`;
  const body = `<div class="t2-list">${searchRow(v)}${filterChips(v)}${gap(12)}${listBody(v)}</div>`;
  return scaffold({
    appbar: appBar('Sản phẩm', { subtitle: `${v.counts.all ?? 0} sản phẩm`, actions: more }),
    body,
    fabHtml: fab('plus', 'Tạo sản phẩm'),
    placeWidth,
    windowWidth: v.width,
  });
}

/** Cột phải khi chưa chọn sản phẩm (app_router.dart): Scaffold nền surfaceAlt + Center(VEmptyState(media inventory, tiêu đề)). */
export const detailPlaceholder = () => `<div class="t2-page">${emptyState({ header: [emptyMedia('inventory'), emptyTitle('Chọn một sản phẩm để xem chi tiết.')] })}</div>`;

// ---------------------------------------------------------------- SP-02 sheet lọc

/** Tuỳ chọn lọc (list_custom_field_filter_options): trường chọn một + trường có / không. */
export const FILTER_OPTIONS = [
  { name: 'Dạng bào chế', type: 'singleSelect', options: ['Viên nén', 'Dung dịch', 'Bột', 'Thuốc mỡ'] },
  { name: 'Đối tượng dùng', type: 'singleSelect', options: ['Chó', 'Mèo', 'Chó & mèo', 'Gia cầm'] },
  { name: 'Kê đơn', type: 'boolean' },
];

/**
 * CustomFieldFilterSheet (showVAdaptiveSheet title "Lọc sản phẩm"): đệm 16 / 8; mỗi trường: khe 12, tên headingH4 w600, khe 8,
 * Wrap(8 / 6) VChip(selected, emphasis medium, **tone primary**) → tone đặt cứng thắng selected nên mọi chip đều xanh như đang chọn.
 * Cuối: khe 16, Row["Bỏ lọc" secondary | khe 12 | "Áp dụng" primary], khe 16. Rỗng: "Chưa có thuộc tính mở rộng nào." đệm dọc 32.
 * selected: { [tên trường]: lựa chọn } — chỉ để ghi chú; hình không đổi.
 */
export function filterSheet(options) {
  const fields = options.length
    ? options.map((o) => {
      const opts = o.type === 'boolean' ? ['Có', 'Không'] : o.options;
      return `${gap(12)}<h3 class="t2-h4">${esc(o.name)}</h3>${gap(8)}<div class="t2-wrap86">${opts.map((l) => chip(l, { tone: 'primary' })).join('')}</div>`;
    }).join('')
    : '<p class="t2-filter-empty">Chưa có thuộc tính mở rộng nào.</p>';
  return `<div class="t2-filter">${fields}${gap(16)}<div class="t2-btnrow12">${button('Bỏ lọc', { variant: 'secondary', full: true })}${button('Áp dụng', { full: true })}</div>${gap(16)}</div>`;
}

// ---------------------------------------------------------------- ca → trạng thái

const COUNTS_DEFAULT = { all: COUNTS.all, readyToSell: COUNTS.ready, incomplete: COUNTS.incomplete, inactive: COUNTS.inactive };

/** Trạng thái danh sách của từng ca (cũng là nền của SP-02 và của màn tạo khi quay về). */
export function listState(state) {
  const v = {
    kind: 'loaded', query: '', filter: 'all', cfFilters: 0, counts: { ...COUNTS_DEFAULT }, items: PRODUCTS,
    reachedMax: false, hasProducts: true, selectedId: null, scrollEnd: false, error: '',
  };
  switch (state) {
    case 'loading': Object.assign(v, { kind: 'loading', counts: {} }); break;
    case 'search': Object.assign(v, { query: 'amox', items: [PRODUCTS[0]], reachedMax: true }); break;
    case 'chip-ready': Object.assign(v, { filter: 'readyToSell', items: [PRODUCTS[0], PRODUCTS[1], PRODUCTS[3], PRODUCTS[7]] }); break;
    case 'chip-inactive': Object.assign(v, { filter: 'inactive', items: [PRODUCTS[5]], reachedMax: true }); break;
    case 'chip-in-stock': Object.assign(v, { filter: 'inStock' }); break;
    case 'chip-out-of-stock': Object.assign(v, { filter: 'outOfStock' }); break;
    case 'chip-deleted': Object.assign(v, { filter: 'deleted', items: DELETED, reachedMax: true, counts: { ...COUNTS_DEFAULT, deleted: 2 } }); break;
    case 'cf-filtered': Object.assign(v, { cfFilters: 2, items: [PRODUCTS[0], PRODUCTS[6]], reachedMax: true }); break;
    case 'end': Object.assign(v, { items: PRODUCTS.slice(2), reachedMax: true, scrollEnd: true, counts: { ...COUNTS_DEFAULT, inStock: 29, outOfStock: 19 } }); break;
    case 'more': Object.assign(v, { kind: 'more', items: PRODUCTS.slice(2), scrollEnd: true }); break;
    case 'empty': Object.assign(v, { items: [], hasProducts: false, counts: { all: 0, readyToSell: 0, incomplete: 0, inactive: 0 } }); break;
    case 'empty-filter': Object.assign(v, { filter: 'incomplete', items: [] }); break;
    case 'empty-deleted': Object.assign(v, { filter: 'deleted', items: [], reachedMax: true, counts: { ...COUNTS_DEFAULT, deleted: 0 } }); break;
    case 'no-result': Object.assign(v, { query: 'xyz', items: [], reachedMax: true }); break;
    case 'error': Object.assign(v, { kind: 'error', error: 'Đã xảy ra lỗi. Vui lòng thử lại.' }); break;
    case 'error-permission': Object.assign(v, { kind: 'error', error: 'Bạn không có quyền thực hiện thao tác này.', counts: {} }); break;
    default: break;
  }
  return v;
}
