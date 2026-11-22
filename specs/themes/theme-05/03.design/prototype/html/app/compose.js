// SG-02 Soạn đơn (/sales/compose?draftId=) + ô tìm sản phẩm (menu nổi), sheet rời màn, bàn phím số lượng, toast.
// Nguồn Dart (apps/erp/lib/features/sales/presentation/):
//   pages/sales_order_compose_page.dart, widgets/{sales_compose_form_body, sales_compose_customer_card, sales_compose_product_search_bar,
//   sales_compose_lines_section, sales_order_line_row, sales_order_line_quantity, sales_special_price_banner, sales_product_thumbnail,
//   sales_amount_highlight_row, sales_label_highlight_row, sales_compose_order_note_tile, sales_compose_summary_bar, sales_compose_leave_sheet}.dart,
//   support/sales_barcode_search_hint.dart, models/sales_order_draft/{sales_compose_line_vm, compose_line_stock_hint}.dart.
import {
  appBar, banner, button, cardHeader, emptyDesc, emptyMedia, emptyState, emptyTitle, esc, gap, icon, iconBox, keypadSheet, scaffold,
  searchBar, skeleton, smallLoading, textAreaCounter, toast,
} from './ds.js';
import { LINES, PRODUCTS, money, totals } from './data.js';

/** SalesStockWarning: null → không cảnh báo; ≤ 0 "Hết hàng" (đỏ); 1 "Chỉ còn 1 <đv>" (đỏ); 2 "Chỉ còn 2 <đv>" (vàng). */
export function stockWarning(stock, unit) {
  if (stock == null || stock > 2) return null;
  if (stock <= 0) return { text: 'Hết hàng', tone: 'danger' };
  return { text: `Chỉ còn ${stock} ${unit}`, tone: stock <= 1 ? 'danger' : 'warning' };
}

/** Dòng giá: "<giá áp dụng>/<đơn vị>" — không có giá niêm yết gạch ngang dù đã giảm. */
export const unitPriceLabel = (l) => `${money(l.price)}/${l.unit}`;

/**
 * SalesSpecialPriceBanner: dải chéo góc trên-trái màu success (như Flutter Banner, không bóng) + icon % trắng xoay -45°.
 * side = min(rộng, cao dòng); offset = 0.4·side; cao dải = max(10, 0.22·side); icon = 0.85·cao dải.
 */
export function ribbon(rowHeight) {
  const side = rowHeight;
  const off = side * 0.4;
  const h = Math.max(10, side * 0.22);
  const ic = h * 0.85;
  const mid = (off - h / 2) * Math.SQRT1_2;
  return `<span class="t5-ribbon" aria-hidden="true"><svg width="${side}" height="${side}" viewBox="0 0 ${side} ${side}"><rect x="${-off}" y="${off - h}" width="${off * 2}" height="${h}" transform="rotate(-45)" fill="var(--c45-v2-action-primary-default)"/></svg><i style="left:${mid - ic / 2}px;top:${mid - ic / 2}px;width:${ic}px;height:${ic}px;font-size:${ic}px">${icon('badgePercent')}</i></span>`;
}

/** SalesOrderLineQuantityControls: ô chạm 34 × 34; "−" (headingH4 16/22) và "+" (16) trong ô 24 nền surface bo 8 (không viền); ô số 30 × 20 viền borderDefault bo 8, bodySmallMono w600. */
const qtyControls = (q) => `<span class="t5-qty"><span class="t5-qty__hit"><i class="t5-qty__chip">−</i></span><span class="t5-qty__hit"><b class="t5-qty__box">${q}</b></span><span class="t5-qty__hit"><i class="t5-qty__chip">${icon('plus')}</i></span></span>`;

/**
 * SalesOrderLineRow: VSwipeReveal (lộ 116 = 2 × 58: "Chiết khấu" nền successBg icon tag textBrand | "Xóa" nền dangerBg icon thùng rác đỏ — chỉ icon, không chữ),
 * nội dung đệm 8: ảnh 40 (surfaceAlt, icon hộp 20 textSecondary, bo 8) + khe 8 + [tên bodyDefault w600 cao 20 (1 dòng …);
 * hàng: (giá bodySmall textSecondary + [khe 4 + cảnh báo labelSmall 11/16 w600]) | ô số lượng] — ô số lượng nằm dưới tên, không cạnh tên.
 */
export function lineRow(l, { open = false } = {}) {
  const w = stockWarning(l.stock, l.unit);
  const h = 8 + 20 + Math.max(w ? 40 : 20, 34) + 8;
  const actions = `<span class="t5-swipe__actions t5-swipe__actions--line"><span class="t5-swact t5-swact--tag">${icon('tag')}</span><span class="t5-swact t5-swact--del">${icon('trash')}</span></span>`;
  const row = `<div class="t5-line">
    ${iconBox({ ic: 'inventory', size: 40, iconSize: 20, radius: 8, cls: 't5-ibox--alt' })}
    <div class="t5-line__main"><b class="t5-line__name">${esc(l.name)}</b>
      <div class="t5-line__row"><div class="t5-line__price"><span>${esc(unitPriceLabel(l))}</span>${w ? `<em class="t5-line__warn t5-line__warn--${w.tone}">${esc(w.text)}</em>` : ''}</div>${qtyControls(l.qty)}</div>
    </div>${l.special ? ribbon(h) : ''}</div>`;
  return `<div class="t5-swipe${open ? ' is-open' : ''}" style="--reveal:116px">${actions}<div class="t5-swipe__child">${row}</div></div>`;
}

/** _KvRow: nhãn bodySmallMono (chữ MONO cho cả nhãn) textSecondary | giá trị bodyDefaultMono w600. */
const kv = (label, value, danger = false) => `<div class="t5-kvrow"><span>${esc(label)}</span><b${danger ? ' class="is-danger"' : ''}>${esc(value)}</b></div>`;

/**
 * Thẻ "Tóm tắt thanh toán" (VCard đệm 16, viền borderStrong): H4 bold; khe 16; "Tổng tiền hàng (N sản phẩm)" (N = số dòng, không phải tổng số lượng);
 * khe 4; "Giảm giá" (> 0 → "-…" đỏ); khe 16; SalesAmountHighlightRow "Thành tiền": nền surfaceBrand không viền, bo 8, đệm 12, nhãn labelDefault + số headingH4Mono màu textBrand.
 */
export function summaryCard(t) {
  return `<div class="t5-card t5-card--pad"><h3 class="t5-h4b">Tóm tắt thanh toán</h3>${gap(16)}
    ${kv(`Tổng tiền hàng (${t.count} sản phẩm)`, money(t.merchandise))}${gap(4)}
    ${kv('Giảm giá', t.discount > 0 ? `-${money(t.discount)}` : money(0), t.discount > 0)}${gap(16)}
    <div class="t5-hl"><span>Thành tiền</span><b>${esc(money(t.net))}</b></div></div>`;
}

/**
 * SalesComposeOrderNoteTile: VCard đệm 0; đầu thẻ (đệm 16) "Ghi chú đơn hàng" + mô tả (thu gọn: nội dung / "Chưa có ghi chú") + chevron ˅ 20 xoay khi mở;
 * mở: VDivider + khe 16 + VTextArea (3–5 dòng, bộ đếm "n/500", gợi ý "VD: Giao trước 16:00") — mô tả biến mất khi mở.
 */
export function noteTile(note, open) {
  const head = cardHeader({ title: 'Ghi chú đơn hàng', desc: open ? '' : (note || 'Chưa có ghi chú'), action: `<i class="t5-chev${open ? ' is-open' : ''}">${icon('chevronDown')}</i>`, pad: '16px' });
  return `<div class="t5-card t5-notecard">${head}${open ? `<hr class="t5-divider">${gap(16)}<div class="t5-ccontent">${textAreaCounter({ value: note, hint: 'VD: Giao trước 16:00', lines: 3, max: 500 })}</div>` : ''}</div>`;
}

/** SalesComposeCustomerCard: tên bodyDefault w700 + phụ đề bodySmall; "Chọn KH" / "Đổi KH" | gạch dọc 20 | "Tạo KH" (tertiary small, khe 4). */
function customerRow(c) {
  const sub = c.walkIn ? 'Không bắt buộc thông tin' : (c.phone || 'Chưa có số điện thoại');
  return `<div class="t5-custrow"><div class="t5-custrow__t"><b>${esc(c.name)}</b><span>${esc(sub)}</span></div>
    ${button(c.walkIn ? 'Chọn KH' : 'Đổi KH', { variant: 'tertiary', size: 'small' })}<i class="t5-gap-h4"></i><i class="t5-vrule"></i><i class="t5-gap-h4"></i>${button('Tạo KH', { variant: 'tertiary', size: 'small' })}</div>`;
}

/** _SuggestionTile: VCard đệm 12 không viền bo 8; ảnh 48 (icon ảnh 22 textMuted, surfaceAlt, bo 8); tên w700; khe 4; "tên TM · ĐV" bodySmall; khe 8; giá w700 … ĐV · khe 16 · tồn (chỉ con số). */
function suggestion(p) {
  return `<div class="t5-sugg">${iconBox({ ic: 'image', size: 48, iconSize: 22, radius: 8, cls: 't5-ibox--altmuted' })}
    <div class="t5-sugg__main"><b>${esc(p.name)}</b>${gap(4)}<span>${esc(p.trade ? `${p.trade} · ${p.unit}` : p.unit)}</span>${gap(8)}
      <div class="t5-sugg__foot"><b>${esc(money(p.price))}</b><span>${esc(p.unit)}</span><span class="t5-sugg__stock">${p.stock}</span></div></div></div>`;
}

/**
 * Menu nổi dưới ô tìm (MenuAnchor, lệch xuống 8): rộng = cả hàng (ô tìm + nút quét); viền borderStrong, bo 12, bóng e1, cao ≤ 350.
 * Kết quả: tối đa 4 thẻ, VDivider giữa, mỗi thẻ trong đệm 8. Rỗng / lỗi: VPagePadding dọc 40 + VEmptyState đệm 8.
 */
function searchMenu(kind) {
  let inner = '';
  if (kind === 'results') inner = PRODUCTS.map((p) => `<div class="t5-menu__item">${suggestion(p)}</div>`).join('<hr class="t5-divider">');
  if (kind === 'empty') inner = `<div class="t5-menu__pad">${emptyState({ header: [emptyMedia('search'), emptyTitle('Không tìm thấy sản phẩm'), emptyDesc('Thử tên, SKU hoặc barcode khác.')], fill: false, cls: 't5-empty--p8' })}</div>`;
  if (kind === 'error') {
    // Mô tả = error.toString() của lỗi tìm (chuỗi thô của exception), không phải câu cố định.
    inner = `<div class="t5-menu__pad">${emptyState({ header: [emptyMedia('alert'), emptyTitle('Không thể tìm sản phẩm'), emptyDesc('SalesExternalOperationException: Không thể tải sản phẩm. Vui lòng thử lại.')], tone: 'danger', fill: false, cls: 't5-empty--p8', content: `${gap(8)}<button type="button" class="t5-btn t5-btn--tertiary">${icon('refresh')}<span>Thử lại</span></button>` })}</div>`;
  }
  return `<div class="t5-menu${kind === 'results' ? ' t5-menu--scroll' : ''}">${inner}</div>`;
}

/** Ô tìm + nút quét: VSearchBar (hậu tố đang tải = VLoading 18 thay nút xoá) + khe 8 + VIconBox 44 (qrCode 22 textBrand, nền surface, viền borderDefault, bo 12). */
function searchRow(s) {
  const value = { results: '', loading: 'amox', empty: 'xyz', error: 'pate' }[s] ?? '';
  const sb = searchBar({ value, hint: 'Tìm tên, SKU hoặc barcode', clear: !!value && s !== 'loading', focused: !!s });
  const withLoad = s === 'loading' ? sb.replace('</label>', `<span class="t5-search__suffix">${smallLoading()}</span></label>`) : sb;
  return `<div class="t5-searchwrap"><div class="t5-row">${withLoad}<span class="t5-scanbtn" role="button" aria-label="Quét mã vạch">${icon('qrCode')}</span></div>${s && s !== 'loading' ? searchMenu(s) : ''}</div>`;
}

export const CUST = {
  walkIn: { walkIn: true, name: 'Khách lẻ' },
  hung: { name: 'Nguyễn Văn Hùng', phone: '0912345678' },
  org: { name: 'Công ty CP Dược Thú y Sài Gòn', phone: null, orgNoTax: true },
};

/** Trạng thái màn soạn đơn theo ca. */
export function composeState(state) {
  const base = { customer: CUST.hung, lines: LINES, draftCount: 3, note: '', noteOpen: false, search: '', refreshing: false, pricingMessage: '', swipe: false, countLoading: false };
  switch (state) {
    case 'new': return { ...base, customer: CUST.walkIn, lines: [] };
    case 'count-loading': return { ...base, customer: CUST.walkIn, lines: [], countLoading: true };
    case 'walk-in': return { ...base, customer: CUST.walkIn, lines: LINES.slice(0, 1) };
    case 'stock': return { ...base, lines: [{ ...LINES[0], stock: 0, qty: 1, name: 'Vắc-xin 5 bệnh cho chó' }, { ...LINES[2], stock: 1 }, LINES[2]] };
    case 'many': return { ...base, lines: [...LINES, { id: 'l4', name: 'Thức ăn hạt cho chó con 1,5kg', unit: 'Túi', price: 289000, list: 289000, qty: 1, stock: 15 }, { id: 'l5', name: 'Cát vệ sinh cho mèo 10L', unit: 'Bao', price: 132000, list: 145000, qty: 3, stock: 30, special: true }, { id: 'l6', name: 'Amoxicillin 500mg', unit: 'Vỉ', price: 13000, list: 13000, qty: 10, stock: 400 }] };
    case 'org-refreshing': return { ...base, customer: CUST.org, refreshing: true, pricingMessage: 'Đã đổi khách — đang làm mới giá' };
    case 'swipe': return { ...base, swipe: true };
    case 'note-open': return { ...base, noteOpen: true, note: 'Giao trước 16:00, gọi trước khi tới' };
    case 'note-filled': return { ...base, note: 'Giao trước 16:00, gọi trước khi tới' };
    case 'search-results': return { ...base, search: 'results' };
    case 'search-loading': return { ...base, search: 'loading' };
    case 'search-empty': return { ...base, search: 'empty' };
    case 'search-error': return { ...base, search: 'error' };
    default: return base;
  }
}

/** App bar SG-02: leading = VIconBox 40 (chevronLeft, nền trong) thay nút ← 48; actions: "Đơn nháp (N)" tertiary small (đệm phải 8) — đang đếm → khung 100 × 36. */
function composeAppBar(st) {
  const lead = `<span class="t5-iconbtn40" role="button" aria-label="Quay lại">${iconBox({ ic: 'chevronLeft', size: 40, iconSize: 20, cls: 't5-ibox--clear' })}</span>`;
  const act = st.countLoading ? `<span class="t5-appact">${skeleton(36, { w: '100px', radius: 12 })}</span>` : `<span class="t5-appact">${button(`Đơn nháp (${st.draftCount})`, { variant: 'tertiary', size: 'small' })}</span>`;
  return appBar('Tạo đơn hàng', { leading: lead, actions: act });
}

/**
 * SalesComposeSummaryBar (bottomBar, VPagePadding dọc 12): "Khách phải trả" bodyDefault textSecondary … tổng bodyDefaultMono w700
 * (đang làm mới giá → khung 96 × 18); khe 8; "Lưu nháp" (secondary tone success) | "Thanh toán" (primary; làm mới giá → vòng xoay). Không có dòng lý do khi nút mờ.
 */
function summaryBar(st, t) {
  const empty = st.lines.length === 0;
  const busy = st.refreshing;
  return `<div class="t5-sumbar"><div class="t5-sumbar__top"><span>Khách phải trả</span>${busy ? skeleton(18, { w: '96px', radius: 12 }) : `<b>${esc(money(t.net))}</b>`}</div>${gap(8)}
    <div class="t5-row2 t5-row2--8">${button('Lưu nháp', { variant: 'secondary', full: true, disabled: empty || busy, cls: 't5-btn--sec-success' })}${button('Thanh toán', { full: true, disabled: empty || busy, loading: busy })}</div></div>`;
}

/**
 * Thân: khe 12, hàng khách, [banner "Khách tổ chức chưa có mã số thuế"], [pricingMessage bodySmall warning], khe 8, ô tìm, khe 8,
 * Expanded(danh sách dòng + thẻ tóm tắt cuộn chung, hoặc VEmptyState có viền kéo hết chỗ), khe 8, thẻ ghi chú (luôn ghim dưới), khe 8.
 */
export function composePage(state, v, { toastHtml = '' } = {}) {
  if (state === 'loading') {
    return scaffold({ appbar: appBar('Tạo đơn hàng', { back: true }), body: '<div class="t5-center"><span class="t5-spin t5-spin--material"></span></div>', placeWidth: v.width, windowWidth: v.width });
  }
  const st = composeState(state);
  const t = totals(st.lines);
  const lines = st.lines.length === 0
    ? `<div class="t5-lines t5-lines--empty">${emptyState({ header: [emptyMedia('info'), emptyTitle('Chưa có sản phẩm trong đơn'), emptyDesc('Tìm hoặc quét mã để thêm sản phẩm.')], cls: 't5-empty--bordered' })}</div>`
    : `<div class="t5-lines"><div class="t5-card t5-linecard">${st.lines.map((l, i) => lineRow(l, { open: st.swipe && i === 1 })).join('<hr class="t5-divider">')}</div>${gap(8)}${summaryCard(t)}</div>`;
  const body = `${gap(12)}<div class="t5-pad">${customerRow(st.customer)}</div>
    ${st.customer.orgNoTax ? `${gap(8)}<div class="t5-pad">${banner('warning', 'Khách tổ chức chưa có mã số thuế', 'Vẫn có thể bán hàng nhưng chưa thể phát hành hóa đơn điện tử.')}</div>` : ''}
    ${st.pricingMessage ? `${gap(8)}<div class="t5-pad"><p class="t5-small t5-text-warning">${esc(st.pricingMessage)}</p></div>` : ''}
    ${gap(8)}<div class="t5-pad t5-pad--menu">${searchRow(st.search)}</div>${gap(8)}
    <div class="t5-pad t5-pad--grow">${lines}</div>${gap(8)}
    <div class="t5-pad">${noteTile(st.note, st.noteOpen)}</div>${gap(8)}${toastHtml}`;
  return scaffold({ appbar: composeAppBar(st), body, bottomBar: summaryBar(st, t), placeWidth: v.width, windowWidth: v.width, cls: 't5-page--compose' });
}

/** Toast nổi trên thanh tổng (SnackBar floating đặt trên bottomNavigationBar): thanh = 1 + 12 + 22 + 8 + 44 + 12 = 99 (+ 34 iPhone). */
export const composeToast = (v, type, title, message) => toast(type, title, message, { bottom: 14 + 99 + (v.device === 'iphone' ? 34 : 0) });

/**
 * showSalesComposeLeaveSheet: showVBottomSheet không tiêu đề; "Đơn có thay đổi chưa lưu" H4 w700; khe 16; 3 thẻ lựa chọn (VCard đệm 12):
 * icon 22 + khe 12 + (tiêu đề bodyDefault w600, khe 4, phụ bodySmall) + khe 8 + › 20. Thẻ huỷ: nền dangerBg, viền danger 30%, chữ đỏ, phụ đỏ 70%. Khe 8 giữa thẻ + 8 cuối.
 */
export function leaveSheet() {
  const opt = (ic, title, sub, danger = false) => `<div class="t5-leaveopt${danger ? ' is-danger' : ''}"><i class="t5-leaveopt__ic">${icon(ic)}</i><span class="t5-leaveopt__t"><b>${esc(title)}</b><span>${esc(sub)}</span></span><i class="t5-leaveopt__chev">${icon('chevronRight')}</i></div>`;
  return `<div class="t5-sheetbody16"><h2 class="t5-h4b">Đơn có thay đổi chưa lưu</h2>${gap(16)}
    ${opt('edit', 'Tiếp tục soạn đơn', 'Giữ nguyên dữ liệu và quay lại đơn')}${gap(8)}
    ${opt('save', 'Lưu nháp và đóng', 'Lưu thay đổi rồi thoát')}${gap(8)}
    ${opt('trash', 'Bỏ thay đổi và đóng', 'Không lưu các thay đổi', true)}${gap(8)}</div>`;
}

/** Chạm ô số lượng → showVNumericKeypadSheet(quantity, "Nhập số lượng", "Đơn vị: <đv>", không thập phân → phím trái dưới trống). */
export const qtyKeypad = () => keypadSheet({ title: 'Nhập số lượng', unit: 'Đơn vị: Lon', value: '6' });
