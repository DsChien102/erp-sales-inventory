// SG-01 Đơn nháp (/sales/drafts) + sheet xoá nháp. Nguồn Dart (apps/erp/lib/features/sales/presentation/):
//   pages/sales_draft_list_page.dart, widgets/{sales_draft_list_body, sales_draft_list_card, sales_draft_list_card_skeleton,
//   sales_draft_list_empty_state, sales_draft_list_error_state, sales_draft_list_no_result_state, sales_draft_list_search_bar,
//   sales_draft_discard_dialog}.dart, models/sales_order_draft/sales_draft_list_item_vm.dart.
// Route nằm trong TypedShellRoute riêng của Sales (SalesDraftListScope), KHÔNG thuộc StoreShell → không thanh bên / thanh dưới.
import {
  appBar, badge, button, buttonLg, cardContent, cardHeader, emptyDesc, emptyMedia, emptyState, emptyTitle, esc, fab, icon, gap,
  scaffold, searchBar, skeleton, tabs, toast,
} from './ds.js';
import { DRAFTS, draftTimestamp, money, phoneLabel } from './data.js';

const UUID = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
const PHONE = /^\+?[0-9\s.\-()]{8,15}$/;
/** SalesDraftListItemVm.creatorLabel: bỏ tên rỗng, dạng UUID hoặc dạng SĐT. */
export function creatorLabel(name) {
  const n = (name || '').trim();
  if (!n || UUID.test(n) || PHONE.test(n)) return null;
  return n;
}

/** Dòng mô tả dưới tên khách: SĐT (hoặc "Không có số điện thoại") + " · Tạo bởi: …" chỉ ở tab "Tất cả đơn nháp". */
export function phoneLine(d, showCreatedBy) {
  const creator = creatorLabel(d.creator);
  return showCreatedBy && creator ? `${phoneLabel(d.phone)} · Tạo bởi: ${creator}` : phoneLabel(d.phone);
}

/** "3 mặt hàng · 437.000đ" (caption textSecondary w600); mốc giờ bên phải caption w400. */
export const draftSummary = (d) => `${d.lines} mặt hàng · ${money(d.total)}`;

/**
 * SalesDraftListCard: VSwipeReveal (vuốt trái lộ 100: khe 8 + VButton primary danger "Xóa" cao cả thẻ) bọc VCard
 * (đệm 0, viền 1 borderDefault — không phải borderStrong mặc định của VCard, bo 12).
 * VCardHeader: tên khách (H4 14/20 w600) + mô tả phoneLine; action = badge nhỏ warning "Cần kiểm tra".
 * VCardContent: ghi chú (bodySmall textPrimary 1 dòng …) + khe 8, rồi hàng "N mặt hàng · tiền" | mốc giờ.
 */
export function draftCard(d, { showCreatedBy = false, open = false } = {}) {
  const note = (d.note || '').trim();
  const content = `${note ? `<p class="t5-dcard__note">${esc(note)}</p>${gap(8)}` : ''}<div class="t5-dcard__foot"><span>${esc(draftSummary(d))}</span><time>${esc(draftTimestamp(d.at))}</time></div>`;
  const card = `<div class="t5-card t5-dcard" role="button" aria-label="${esc(d.customer)}">${cardHeader({ title: d.customer, desc: phoneLine(d, showCreatedBy), action: d.needsCheck ? badge('Cần kiểm tra', { tone: 'warning', small: true }) : '' })}${cardContent(content)}</div>`;
  return `<div class="t5-swipe${open ? ' is-open' : ''}" style="--reveal:100px"><div class="t5-swipe__actions t5-swipe__actions--draft"><i class="t5-gap-h8"></i>${button('Xóa', { tone: 'danger', full: true })}</div><div class="t5-swipe__child">${card}</div></div>`;
}

/** SalesDraftListCardSkeleton: hộp đệm 16, bo 12, viền borderDefault; vạch 160×18 | 72×18; 90×12 + 72×12; 120×12; 120×12 | 40×12 (bo 4). */
const draftSkeleton = () => `<div class="t5-dskel">
  <div class="t5-dskel__row t5-dskel__row--between">${skeleton(18, { w: '160px', radius: 4 })}${skeleton(18, { w: '72px', radius: 4 })}</div>
  <div class="t5-dskel__row">${skeleton(12, { w: '90px', radius: 4 })}${skeleton(12, { w: '72px', radius: 4 })}</div>
  ${skeleton(12, { w: '120px', radius: 4 })}
  <div class="t5-dskel__row t5-dskel__row--between">${skeleton(12, { w: '120px', radius: 4 })}${skeleton(12, { w: '40px', radius: 4 })}</div></div>`;

/** VEmptyState(filled, nền surface, viền borderDefault, đệm 24) trong VPagePadding(vertical 16) — cao theo nội dung, không kéo hết thân. */
function boxedEmpty({ media, title, desc, action, tone = '', titleHtml = '' }) {
  const head = [emptyMedia(media), titleHtml || emptyTitle(title), emptyDesc(desc)];
  return `<div class="t5-boxpad">${emptyState({ header: head, content: action ? `${gap(4)}${action}` : '', tone, fill: false, cls: 't5-empty--boxed' })}</div>`;
}

export function draftListState(state) {
  const all = state === 'all' || state === 'all-swipe';
  return {
    tab: all ? 1 : 0,
    query: { 'no-result': 'xyz', search: 'hùng' }[state] || '',
    items: all ? DRAFTS : DRAFTS.filter((d) => d.mine),
  };
}

function listBody(state, st) {
  if (state === 'loading') return `<div class="t5-dlist">${Array.from({ length: 8 }, draftSkeleton).join('')}</div>`;
  if (state === 'error') {
    return boxedEmpty({
      media: 'close', tone: 'danger', titleHtml: '<h2 class="t5-empty__title t5-danger-title">Không thể tải đơn nháp</h2>', desc: 'Không thể tải danh sách đơn nháp',
      action: button('Thử lại', { variant: 'tertiary', tone: 'danger', cls: 't5-btn--fg-danger' }),
    });
  }
  if (state === 'blocked') {
    return emptyState({ header: [emptyMedia('lock'), emptyTitle('Không thể mở đơn nháp'), emptyDesc('Anh/chị không có quyền truy cập khu vực bán hàng.')] });
  }
  if (state === 'empty') {
    // onRetry không được truyền → nút "Tải lại" luôn mờ (không bấm được).
    return boxedEmpty({ media: 'info', title: 'Chưa có đơn nháp', desc: 'Các đơn được lưu nháp sẽ xuất hiện tại đây.', action: button('Tải lại', { variant: 'tertiary', disabled: true }) });
  }
  if (state === 'no-result') {
    return boxedEmpty({ media: 'search', title: 'Không tìm thấy đơn nháp', desc: `Không có đơn nháp phù hợp với '${st.query}'.`, action: button('Xóa tìm kiếm', { variant: 'tertiary' }) });
  }
  let items = st.items;
  if (state === 'search') items = items.filter((d) => d.customer.toLowerCase().includes('hùng'));
  const cards = items.map((d, i) => draftCard(d, { showCreatedBy: st.tab === 1, open: (state === 'swipe' || state === 'all-swipe') && i === 0 })).join('');
  let footer = '';
  if (state === 'more') footer = '<div class="t5-loadmore"><span class="t5-spin t5-spin--material"></span></div>';
  if (state === 'more-error') footer = `<div class="t5-loadmore t5-loadmore--8"><button type="button" class="t5-tbicon">${icon('refresh')}<span>Không thể tải thêm đơn nháp · Thử lại</span></button></div>`;
  return `<div class="t5-dlist"${state.startsWith('more') ? ' data-scroll-end' : ''}>${cards}${footer}</div>`;
}

/**
 * VPageScaffold "Đơn nháp" (← 48, tiêu đề trái), FAB xanh "+" (tone success, nền success).
 * Thân: khe 8, ô tìm (VPagePadding), khe 8, VTabs (danh sách tab trong VPagePadding) "Đơn của tôi" | "Tất cả đơn nháp", nội dung tab.
 */
export function draftListPage(state, v, { toastHtml = '' } = {}) {
  const st = draftListState(state);
  const body = `${gap(8)}<div class="t5-pad">${searchBar({ value: st.query, hint: 'Tìm theo khách hàng, SĐT, ghi chú', clear: !!st.query })}</div>${gap(8)}
    <div class="t5-pad">${tabs(['Đơn của tôi', 'Tất cả đơn nháp'], st.tab)}</div>
    <div class="t5-tabbody">${listBody(state, st)}</div>${toastHtml}`;
  return scaffold({
    appbar: appBar('Đơn nháp', { back: true }),
    body,
    fabHtml: fab('plus', 'Tạo đơn mới'),
    placeWidth: v.width,
    windowWidth: v.width,
  });
}

/** SnackBar floating đặt TRÊN nút nổi endFloat: đỉnh FAB = 16 + 56 (+ 34 vùng an toàn iPhone), cộng lề 14 của VToast. */
const bareToastBottom = (v) => 14 + 16 + 56 + (v.device === 'iphone' ? 34 : 0);
export const draftToast = (v, type, title, message) => toast(type, title, message, { bottom: bareToastBottom(v) });

/**
 * showSalesDraftDiscardDialog: showVBottomSheet không tiêu đề; VPagePadding: "Xóa đơn nháp?" H3 w700 chữ đỏ; khe 16; câu bodyDefault textSecondary;
 * khe 24; "Xóa" secondary danger large 52 đầy ngang (viền + chữ đỏ, không nền đỏ); khe 8; "Quay lại" secondary large. Tay kéo xám (tone mặc định).
 */
export function discardSheet(d) {
  return `<div class="t5-sheetbody16">
    <h2 class="t5-h3b t5-text-danger">Xóa đơn nháp?</h2>${gap(16)}
    <p class="t5-body2">Đơn nháp của ${esc(d.customer)} sẽ bị xóa và không thể khôi phục.</p>${gap(24)}
    ${buttonLg('Xóa', { variant: 'secondary', tone: 'danger', full: true, cls: 't5-btn--sec-danger' })}${gap(8)}
    ${buttonLg('Quay lại', { variant: 'secondary', full: true })}</div>`;
}
