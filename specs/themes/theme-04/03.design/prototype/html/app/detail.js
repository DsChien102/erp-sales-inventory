// PR-08 Chi tiết giá riêng (+ sheet Thao tác, Tắt giá riêng, Bật lại giá riêng; toast).
// Nguồn Flutter (apps/erp/lib/features/pricing/):
//   presentation/pages/pricing_detail_page.dart (VPageScaffold, _PriceRuleDetailBody, _BottomBar "Thao tác")
//   presentation/widgets/{price_rule_detail_content, price_rule_detail_rows, price_rule_status_badge, price_rule_warning_banner,
//     price_rule_history_shared, price_rule_action_sheet, price_rule_disable_sheet, price_rule_reenable_sheet}.dart
//   logic/price_rule_detail_cubit.dart (messageForPrecheckBlocked, recentActivities = trang đầu lịch sử)
import {
  appBar, badge, banner, button, card, checkbox, esc, field, icon, iconBox, scaffold, skeleton, textAreaPlain, toast,
} from './ds.js';
import { legacyEmpty } from './list.js';
import { ACTIVITIES, DETAIL, STATUS, money } from './data.js';

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

/**
 * PriceRuleDetailContent._formatDiff: cùng lỗi với form — số tiền lấy trị tuyệt đối, dấu "+" chỉ khi dương;
 * phần % dùng lại `sign` ('' khi âm) + toStringAsFixed (đã có "-"). Không có giá niêm yết → "—".
 */
export function detailDiff(diff, list) {
  const sign = diff > 0 ? '+' : '';
  const amount = `${sign}${money(Math.abs(diff))}`;
  if (list == null || list === 0) return amount;
  return `${amount} (${sign}${((diff / list) * 100).toFixed(1).replace('.', ',')}%)`;
}

/** PriceRuleHistoryShared.activityLabel (danh sách lịch sử, sheet lọc) và activityLabelDetail (chi tiết, sheet hoạt động). */
export const ACT_LABEL = { created: 'Tạo giá riêng', updated: 'Sửa giá', disabled: 'Tắt', reenabled: 'Bật lại', deleted: 'Xóa' };
export const ACT_LABEL_DETAIL = { created: 'Tạo giá riêng', updated: 'Sửa giá riêng', disabled: 'Tắt giá riêng', reenabled: 'Bật lại giá riêng', deleted: 'Xóa giá riêng' };
/** activityIcon / activityTone (VIconBox tone: primary → nền trắng icon xanh; info → nền xanh dương nhạt; danger; success). */
export const ACT_ICON = { created: 'plusCircle', updated: 'edit', disabled: 'powerOff', reenabled: 'power', deleted: 'trash' };
export const ACT_TONE = { created: 'info', updated: 'primary', disabled: 'danger', reenabled: 'success', deleted: 'danger' };
export const SOURCE_LABEL = { manual: 'Tạo thủ công', excelImport: 'Nhập Excel', salesOrder: 'Từ đơn hàng', migration: 'Hệ thống' };

/** activitySummary: sửa có giá cũ + mới → "Giá đổi từ A → B"; có lý do → "Lý do: …"; có giá mới → "Giá áp dụng: …"; còn lại null. */
export function activitySummary(a) {
  if (a.type === 'updated' && a.oldPrice != null && a.newPrice != null) return `Giá đổi từ ${money(a.oldPrice)} → ${money(a.newPrice)}`;
  if (a.reason) return `Lý do: ${a.reason}`;
  if (a.newPrice != null) return `Giá áp dụng: ${money(a.newPrice)}`;
  return null;
}

/** Hàng "Giá đổi từ A → B" (Wrap: chữ xám, A đậm, mũi tên + B xanh đậm) hoặc câu tóm tắt xám. */
export function summaryLine(a) {
  if (a.type === 'updated' && a.oldPrice != null && a.newPrice != null) {
    return `<p class="t4-hsum">Giá đổi từ <b>${money(a.oldPrice)}</b><em> → ${money(a.newPrice)}</em></p>`;
  }
  const s = activitySummary(a);
  return s ? `<p class="t4-hsum">${esc(s)}</p>` : '';
}

/** VIconBox tròn theo tone hoạt động. */
export const actIcon = (a, size, iconSize) => iconBox({ ic: ACT_ICON[a.type], size, iconSize, circle: true, cls: `t4-ibox--tone-${ACT_TONE[a.type]}` });

// ---------------------------------------------------------------- trạng thái

export function detailState(state) {
  const d = DETAIL;
  switch (state) {
    case 'below-floor': return { ...d, price: 92000, below: true };
    case 'needs-review': return { ...d, customer: 'Công ty CP Dược Thú y Sài Gòn', phone: null, product: 'Vắc-xin 5 bệnh cho chó', unit: 'Lọ', price: 82000, list: null, floor: null, status: 'needsReview', issues: ['product_unit_reference_inactive'], from: '10/10/2026' };
    case 'disabled': case 'toast-disabled': return { ...d, status: 'disabled', persisted: 'disabled', actions: ['reenable', 'history'], disabledBy: 'Trần Minh Đức', disabledAt: '02/09/2026 16:40', disabledReason: 'Khách tạm ngưng nhập hàng' };
    case 'disabled-no-reason': return { ...d, status: 'disabled', persisted: 'disabled', actions: ['reenable', 'history'], disabledBy: null, disabledAt: '02/09/2026 16:40', disabledReason: null };
    case 'not-yet': return { ...d, status: 'notYetEffective', from: '01/12/2026', to: '31/03/2027' };
    case 'expired': return { ...d, status: 'expired', from: '01/03/2026', to: '30/09/2026', actions: ['history'] };
    case 'floor-hidden': return { ...d, floorHidden: true };
    case 'no-actions': return { ...d, actions: [] };
    case 'no-history': return { ...d, recent: [] };
    default: return d;
  }
}

// ---------------------------------------------------------------- PR-08

/** PriceRuleIconDetailRow: icon 18 xanh trong ô 20 | khe 8 | nhãn 128 bodySmall xám | giá trị canh phải bodySmall (số → bodySmallMono); đệm dưới 16 (trừ hàng cuối). */
const row = (ic, label, value, { mono = false, tone = '', weight = 0, raw = false } = {}) => `<div class="t4-drow"><i class="t4-drow__icon">${icon(ic)}</i><span class="t4-drow__label">${esc(label)}</span><span class="t4-drow__val${mono ? ' t4-mono' : ''}${tone ? ` is-${tone}` : ''}"${weight ? ` style="font-weight:${weight}"` : ''}>${raw ? value : esc(value)}</span></div>`;

/** PriceRuleDetailSectionCard: VCard đệm 16; tiêu đề H4 w700, khe 16, gạch, khe 16, các hàng. */
const sectionCard = (title, inner) => card(`<h3 class="t4-dsec__title">${esc(title)}</h3><i class="t4-gap" style="height:16px"></i><hr class="t4-divider"><i class="t4-gap" style="height:16px"></i>${inner}`, { cls: 't4-dsec' });

/** PriceRuleRecentHistoryItem: VIconBox tròn 32 | khe 8 | [nhãn chi tiết w600 … ngày bodySmall muted] / "người · nguồn" / tóm tắt. */
function recentItem(a) {
  return `<div class="t4-recent">${actIcon(a, 32, 16)}<div class="t4-recent__text">
    <div class="t4-recent__head"><b>${esc(ACT_LABEL_DETAIL[a.type])}</b><span>${esc(a.at)}</span></div>
    <span class="t4-recent__who">${esc(a.actor)} · ${esc(SOURCE_LABEL[a.source])}</span>
    ${summaryLine(a) || `<p class="t4-hsum">Giá áp dụng: ${a.newPrice != null ? money(a.newPrice) : '—'}</p>`}
  </div></div>`;
}

export function detailContent(r) {
  const below = r.below;
  const diff = r.list == null ? null : r.price - r.list;
  const banners = [];
  if (r.status === 'needsReview' || below) {
    const issues = [...(below ? ['Giá riêng đang thấp hơn giá sàn hiện tại'] : []), ...r.issues];
    banners.push(banner('warning', 'Cần kiểm tra', issues.map((i) => `• ${i}`).join('\n')));
  }
  if (r.persisted === 'disabled') banners.push(banner('info', 'Giá riêng đã tắt', 'Không áp dụng cho đơn hàng mới.'));
  const [stLabel, stTone] = STATUS[r.status];
  const recent = r.recent ?? ACTIVITIES.slice(0, 3);
  const head = card(`
    ${row('users', 'Khách hàng', r.customer)}
    ${row('phone', 'Số điện thoại', r.phone ?? '—', { mono: true })}
    ${row('inventory', 'Sản phẩm', r.product)}
    ${row('store', 'Đơn vị bán', r.unit)}
    <div class="t4-drow t4-drow--last t4-drow--center"><i class="t4-drow__icon">${icon('info')}</i><span class="t4-drow__label">Trạng thái</span><span class="t4-drow__val">${badge(stLabel, { tone: stTone, small: true })}</span></div>`, { cls: 't4-dsec' });
  const floorShown = !r.floorHidden && r.floor != null;
  const price = sectionCard('Thông tin giá', `
    ${row('tag', 'Giá riêng', money(r.price), { mono: true, tone: below ? 'danger' : '', weight: 700 })}
    ${row('receipt', 'Giá niêm yết', r.list != null ? money(r.list) : '—', { mono: true })}
    ${row('shield', 'Giá sàn', floorShown ? money(r.floor) : 'Ẩn theo quyền', { mono: floorShown })}
    <div class="t4-drow--last">${row('swapVert', 'Chênh lệch', diff == null ? '—' : detailDiff(diff, r.list), { mono: diff != null, tone: diff == null ? '' : diff < 0 ? 'danger' : 'success', weight: 600 })}</div>`);
  const eff = sectionCard('Hiệu lực & nguồn', `
    ${row('calendar', 'Từ ngày', r.from, { mono: true })}
    ${row('calendar', 'Đến ngày', r.to ?? 'Không giới hạn', { mono: r.to != null })}
    <div class="t4-drow--last">${row('download', 'Nguồn tạo', SOURCE_LABEL[r.source])}</div>`);
  const off = r.persisted === 'disabled' ? sectionCard('Thông tin tắt', `
    ${row('user', 'Người tắt', r.disabledBy ?? '—')}
    ${row('calendar', 'Thời gian', r.disabledAt ?? '—', { mono: r.disabledAt != null })}
    <div class="t4-drow--last">${row('edit', 'Lý do', r.disabledReason || 'Không có')}</div>`) : '';
  const recentHtml = recent.length
    ? `${recent.map((a, i) => `${recentItem(a)}<i class="t4-gap" style="height:16px"></i>${i < recent.length - 1 ? '<hr class="t4-divider"><i class="t4-gap" style="height:16px"></i>' : ''}`).join('')}<hr class="t4-divider"><i class="t4-gap" style="height:16px"></i>`
    : '';
  const hist = sectionCard('Lịch sử gần đây', `${recentHtml}<button type="button" class="t4-viewall">Xem tất cả lịch sử ${icon('chevronRight')}</button>`);
  const gap16 = '<i class="t4-gap" style="height:16px"></i>';
  return `<div class="t4-formscroll">
    ${banners.map((b) => `${b}<i class="t4-gap" style="height:8px"></i>`).join('')}
    ${head}${gap16}${price}${gap16}${eff}${off ? gap16 + off : ''}${gap16}${hist}
    <i class="t4-gap" style="height:32px"></i>
  </div>`;
}

/** Nút ← của chi tiết: IconButton(arrowBack) 48 (form dùng VIconBox 40; màn chọn dùng ‹). */
const backBtn = () => `<button type="button" class="t4-icon-btn" aria-label="Quay lại">${icon('arrowLeft')}</button>`;

/** Khung tải: đệm 16, 3 VSkeleton ∞ × 120 / 160 / 100 bo 4, khe 16. */
const detailSkeleton = () => `<div class="t4-pickskel t4-pickskel--16">${skeleton(120, { radius: 4 })}${skeleton(160, { radius: 4 })}${skeleton(100, { radius: 4 })}</div>`;

export function detailPage(state, v, { toastHtml = '' } = {}) {
  const loaded = !['loading', 'not-found', 'no-permission', 'error'].includes(state);
  const r = loaded ? detailState(state) : null;
  let body;
  if (state === 'loading') body = detailSkeleton();
  else if (state === 'not-found') body = legacyEmpty({ ic: 'search', title: 'Không tìm thấy', desc: 'Mức giá riêng này không tồn tại hoặc đã bị xóa.' });
  else if (state === 'no-permission') body = legacyEmpty({ ic: 'lock', title: 'Không có quyền truy cập', desc: 'Bạn không có quyền xem mức giá riêng này.' });
  else if (state === 'error') body = legacyEmpty({ ic: 'error', title: 'Đã xảy ra lỗi', desc: 'Không thể tải dữ liệu. Vui lòng thử lại.', action: 'Thử lại' });
  else body = detailContent(r);
  const page = scaffold({
    appbar: appBar('Chi tiết giá riêng', { subtitle: r ? r.customer : '', leading: backBtn() }),
    body,
    bottomBar: r && r.actions.length ? button('Thao tác', { full: true }) : '',
    placeWidth: v.width, windowWidth: v.width, cls: 't4-detailpage',
  });
  return toastHtml ? page.replace(/<\/div>\s*$/, `${toastHtml}</div>`) : page;
}

/** Toast nổi trên thanh "Thao tác" (bottomNavigationBar cao 77, iPhone thêm 34). Chỉ hiện message, không hiện title. */
export const detailToast = (v, type, message, { bar = true } = {}) => toast(type, '', message, { bottom: 14 + (bar ? 77 : 0) + (v.device === 'iphone' ? 34 : 0) });

// ---------------------------------------------------------------- sheet

/** PriceRuleActionSheet: tiêu đề "Thao tác" + gạch; mỗi hàng đệm 16 / 12: VIconBox 40 bo 12 (nền màu 10%, icon 18) | khe 16 | nhãn w600 | › 20 muted. Hàng tắt chữ đỏ, bật lại chữ xanh. Khe 16 cuối. */
export function actionSheet(actions) {
  const item = (ic, label, tone = '') => `<button type="button" class="t4-action${tone ? ` t4-action--${tone}` : ''}"><span class="t4-action__box">${icon(ic)}</span><span class="t4-action__label">${esc(label)}</span>${icon('chevronRight')}</button>`;
  const rows = [];
  if (actions.includes('edit')) rows.push(item('edit', 'Sửa giá riêng'));
  if (actions.includes('disable')) rows.push(item('powerOff', 'Tắt giá riêng', 'danger'));
  if (actions.includes('reenable')) rows.push(item('power', 'Bật lại giá riêng', 'success'));
  if (actions.includes('history')) rows.push(item('history', 'Lịch sử áp dụng & thay đổi'));
  return `<div class="t4-actions">${rows.join('')}</div><i class="t4-gap" style="height:16px"></i>`;
}

/** Thẻ tóm tắt trong sheet tắt / bật lại: VCard (đệm 16): tên KH w600 / "SP · ĐV" bodySmall xám / … */
const ruleSummary = (r, extra) => card(`<b class="t4-rsum__name">${esc(r.customer)}</b><span class="t4-rsum__sub">${esc(r.product)} · ${esc(r.unit)}</span>${extra}`, { cls: 't4-rsum' });

/**
 * PriceRuleDisableSheet: sheet có tiêu đề "Tắt giá riêng" + gạch, rồi bên trong lại có icon cảnh báo tròn 56 đỏ + "Tắt giá riêng?" H3 (hai tiêu đề gần trùng).
 * Thẻ tóm tắt có "105.000đ / Hộp"; ô lý do (VTextArea 2 dòng, không bộ đếm); "Giữ giá riêng" | "Tắt giá riêng" (đỏ) / "Đang tắt...".
 */
export function disableSheet(r, { submitting = false, reason = '' } = {}) {
  return `<div class="t4-sheetpad t4-sheetpad--top8">
    <div class="t4-center-box">${iconBox({ ic: 'alert', size: 56, iconSize: 28, circle: true, cls: 't4-ibox--danger' })}</div>
    <i class="t4-gap" style="height:16px"></i><p class="t4-h3 t4-center">Tắt giá riêng?</p><i class="t4-gap" style="height:4px"></i>
    <p class="t4-small2 t4-center">Giá riêng sẽ không còn áp dụng cho đơn hàng mới. Lịch sử vẫn được giữ lại.</p>
    <i class="t4-gap" style="height:16px"></i>
    ${ruleSummary(r, `<b class="t4-rsum__price t4-mono">${money(r.price)} / ${esc(r.unit)}</b>`)}
    <i class="t4-gap" style="height:16px"></i>
    ${field({ label: 'Lý do tắt (không bắt buộc)', control: textAreaPlain({ value: reason, lines: 2 }) })}
    <i class="t4-gap" style="height:16px"></i>
    <div class="t4-row2">${button('Giữ giá riêng', { variant: 'secondary', full: true, disabled: submitting })}${button(submitting ? 'Đang tắt...' : 'Tắt giá riêng', { tone: 'danger', full: true, disabled: submitting })}</div>
  </div>`;
}

/** Khung tải kiểm tra trước khi bật lại: đệm 16, VSkeleton ∞ × 56 + khe 16 + ∞ × 120. */
export const reenableLoading = () => `<div class="t4-pickskel t4-pickskel--16">${skeleton(56, { radius: 4 })}${skeleton(120, { radius: 4 })}</div>`;
/** Lỗi kiểm tra: VEmptyState (đệm 16) "Không thể kiểm tra" + câu + "Thử lại". */
export const reenableError = () => `<div class="t4-sheetpad">${legacyEmpty({ ic: 'error', title: 'Không thể kiểm tra', desc: 'Không thể kiểm tra điều kiện bật lại.', action: 'Thử lại' }).replace('t4-empty--fill', '')}</div>`;

/**
 * PriceRuleReenableSheet (kiểm tra xong): icon tròn 56 (checkCircle xanh / alert đỏ khi bị chặn) + "Bật lại giá riêng?" / "Không thể bật lại";
 * thẻ tóm tắt + "Hiệu lực từ" / "Đến ngày" (caption muted | monoNumeric). Dưới sàn → banner vàng + ô xác nhận (nút Bật lại mờ tới khi tích);
 * bình thường → banner "Lưu ý" ghi đè (xoá). Bị chặn → chỉ còn "Giữ đã tắt" (nút viền đầy ngang, không có nút chính). Đệm đáy 20.
 */
export function reenableSheet(r, { mode = 'ok', ack = false } = {}) {
  const blocked = mode === 'blocked';
  const meta = `<i class="t4-gap" style="height:8px"></i><div class="t4-meta"><span>Hiệu lực từ</span><b class="t4-mono">${esc(r.from)}</b></div><div class="t4-meta"><span>Đến ngày</span><b class="t4-mono">${esc(r.to ?? 'Không giới hạn')}</b></div>`;
  let extra = '';
  if (mode === 'below') {
    extra = `<i class="t4-gap" style="height:16px"></i>${banner('warning', 'Giá dưới giá sàn', 'Giá riêng thấp hơn giá sàn hiện tại. Bạn cần xác nhận trước khi bật lại.')}<i class="t4-gap" style="height:8px"></i>${checkbox('Tôi xác nhận bật lại giá dưới giá sàn', ack)}`;
  } else if (!blocked) {
    extra = `<i class="t4-gap" style="height:16px"></i>${banner('info', 'Lưu ý', 'Bật lại giá riêng này sẽ tự động ghi đè (xoá) giá riêng trùng (nếu có).')}`;
  }
  const canConfirm = mode === 'ok' || (mode === 'below' && ack);
  const buttons = blocked
    ? `<div class="t4-row2">${button('Giữ đã tắt', { variant: 'secondary', full: true })}</div>`
    : `<div class="t4-row2">${button('Giữ đã tắt', { variant: 'secondary', full: true })}${button('Bật lại giá riêng', { full: true, disabled: !canConfirm })}</div>`;
  return `<div class="t4-sheetpad t4-sheetpad--top8 t4-sheetpad--bottom20">
    <div class="t4-center-box">${iconBox({ ic: blocked ? 'alert' : 'checkCircle', size: 56, iconSize: 28, circle: true, cls: blocked ? 't4-ibox--danger' : 't4-ibox--success' })}</div>
    <i class="t4-gap" style="height:16px"></i><p class="t4-h3 t4-center">${blocked ? 'Không thể bật lại' : 'Bật lại giá riêng?'}</p><i class="t4-gap" style="height:4px"></i>
    <p class="t4-small2 t4-center">${blocked ? 'Đã có giá riêng khác đang áp dụng cho cùng khách hàng và sản phẩm.' : 'Giá riêng sẽ được áp dụng lại nếu còn trong thời gian hiệu lực.'}</p>
    <i class="t4-gap" style="height:16px"></i>
    ${ruleSummary(r, meta)}${extra}
    <i class="t4-gap" style="height:16px"></i>${buttons}
  </div>`;
}
