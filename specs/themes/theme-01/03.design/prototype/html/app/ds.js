// Widget DS dùng chung cho mọi màn Theme 1 — chép số đo từ packages/c45_design_system/lib/src:
//   components/{v_button, v_input, v_text_field, v_text_field_focus_ring, v_banner, v_steps, v_verification_code_field,
//               v_toast, v_app_bar, v_card, v_adaptive_sheet, v_bottom_sheet, v_loading}.dart
//   patterns/{v_field, v_page_scaffold, v_content_width}.dart, forms/v_password_field.dart
// Mỗi hàm trả về HTML; class tiền tố t1-, CSS ở styles/t1.css.
import { icon } from '../shared/icons.js';
import { DESKTOP, DEVICE, renderShell } from '../shared/shell.js';

export const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

/** authMaxWidth (features/auth/presentation/auth_layout.dart): mobile ∞, tablet / desktop 480. */
export const AUTH_MAX = 480;
export const authColumn = (width) => (width >= 600 ? `${AUTH_MAX}px` : '100%');

const spinner = (cls = '') => `<span class="t1-spin ${cls}" aria-hidden="true"></span>`;

/**
 * VButton. variant: primary | secondary | link. size medium = 44 (comfortable).
 * Tắt → vDisabledOpacity (0.4) cả nút. isLoading: vòng 20 + khe 8 trước chữ (nhãn vẫn hiện).
 */
export function button(label, { variant = 'primary', full = false, loading = false, disabled = false, attrs = '', cls: extra = '', trailing = '' } = {}) {
  const cls = ['t1-btn', `t1-btn--${variant}`, full ? 't1-btn--full' : '', extra].filter(Boolean).join(' ');
  // trailing: icon 18 sau chữ (ẩn khi đang tải).
  return `<button type="button" class="${cls}"${disabled || loading ? ' disabled' : ''} ${attrs}>${loading ? spinner('t1-spin--btn') : ''}<span>${esc(label)}</span>${trailing && !loading ? icon(trailing, 't1-btn__trail') : ''}</button>`;
}

/** VFieldLabel: headingH4 14/20 textPrimary + " *" danger, khe 8 dưới. */
export const fieldLabel = (text, required = false) => `<span class="t1-label">${esc(text)}${required ? '<i aria-hidden="true"> *</i>' : ''}</span>`;
/** VFieldError: khe 8 + bodySmall danger. VFieldDescription: khe 8 + bodySmall textSecondary. */
export const fieldError = (text) => `<span class="t1-error">${esc(text)}</span>`;
export const fieldDesc = (text) => `<span class="t1-desc">${esc(text)}</span>`;

/**
 * VTextField / VEmailField / VPhoneField / VPasswordField: ô 44, đệm ngang 12, viền 1 borderInput, bo 8, nền surface.
 * invalid → viền danger, chữ danger. Tắt → viền borderDefault + mờ 0.4.
 * password: nút mắt 44 (VIcons.visibility, màu muted) ở hậu tố.
 */
export function input({ value = '', hint = '', invalid = false, disabled = false, password = false, prefix = '', suffix = '' } = {}) {
  const cls = ['t1-input', invalid ? 'is-invalid' : '', disabled ? 'is-disabled' : ''].filter(Boolean).join(' ');
  const shown = password && value ? '•'.repeat(value.length) : value;
  const eye = password ? `<button type="button" class="t1-input__eye" aria-label="Hiện mật khẩu"${disabled ? ' disabled' : ''}>${icon('eye')}</button>` : '';
  return `<span class="${cls}">${prefix}<input type="${password ? 'password' : 'text'}" value="${esc(password ? value : shown)}" placeholder="${esc(hint)}"${disabled ? ' disabled' : ''} aria-invalid="${invalid}">${suffix}${eye}</span>`;
}

/** VField(label + control + lỗi | mô tả). */
export function field({ label, required = false, control, error = null, desc = null }) {
  return `<div class="t1-field${error ? ' is-invalid' : ''}">${label ? fieldLabel(label, required) : ''}${control}${error ? fieldError(error) : desc ? fieldDesc(desc) : ''}</div>`;
}

/**
 * VVerificationCodeField: ô 48 × 56, khe 8; hẹp hơn thì ô co lại (cao max(48, rộng + 8), chữ headingH4).
 * Viền: borderInput; ô đang nhập (con trỏ) → primary + vòng 3 successBg.
 * VField(invalid): chỉ ô đang focus đổi viền danger + vòng dangerBg; các ô khác giữ borderInput (viền nghỉ chỉ đỏ khi có errorText kiểu cũ), chữ số không đỏ.
 */
export function codeField({ length = 6, value = '', columnWidth, invalid = false, disabled = false, focus = true }) {
  const gap = 8;
  const cellW = Math.min(48, (columnWidth - gap * (length - 1)) / length);
  const cellH = cellW < 48 ? Math.max(48, cellW + 8) : 56;
  const at = Math.min(value.length, length - 1);
  const cells = Array.from({ length }, (_, i) => {
    const ch = value[i] || '';
    const isFocus = focus && !disabled && i === at;
    return `<span class="t1-code__cell${isFocus ? ' is-focus' : ''}${isFocus && invalid ? ' is-danger' : ''}" style="width:${cellW}px;height:${cellH}px;font-size:${cellW < 48 ? 14 : 18}px">${esc(ch)}${isFocus && !ch ? '<i class="t1-code__caret"></i>' : ''}</span>`;
  }).join('');
  return `<div class="t1-code${disabled ? ' is-disabled' : ''}" role="group" aria-label="Mã ${length} ký tự">${cells}</div>`;
}

/** VBanner: bo 12, viền 1 accent, đệm 16; icon 20 + khe 12 + tiêu đề labelDefault accent; mô tả bodySmall textPrimary lùi 32. */
const BANNER_ICON = { info: 'info', success: 'checkCircle', warning: 'alert', error: 'error' };
export function banner(status, title, description = '', footer = '') {
  return `<div class="t1-banner t1-banner--${status}" role="${status === 'error' ? 'alert' : 'status'}">
    <div class="t1-banner__head">${icon(BANNER_ICON[status])}<b>${esc(title)}</b></div>
    ${description ? `<p>${esc(description)}</p>` : ''}${footer ? `<div class="t1-banner__foot">${footer}</div>` : ''}
  </div>`;
}

/** VSteps ngang: vòng 32 (xong: nền successBg + viền success + dấu check 16; đang: nền success + số trắng; chưa: nền surfaceAlt + viền borderStrong), vạch 2, khe 8, tiêu đề labelDefault. */
export function steps(titles, current) {
  return `<ol class="t1-steps" aria-label="${esc(`${current + 1}/${titles.length} · ${titles[current]}`)}">${titles.map((t, i) => {
    const st = i < current ? 'done' : i === current ? 'active' : 'todo';
    const before = i === 0 ? 'none' : i <= current ? 'on' : 'off';
    const after = i === titles.length - 1 ? 'none' : i < current ? 'on' : 'off';
    return `<li class="t1-step t1-step--${st}">
      <span class="t1-step__track"><i class="t1-step__line is-${before}"></i><span class="t1-step__dot">${st === 'done' ? icon('check') : i + 1}</span><i class="t1-step__line is-${after}"></i></span>
      <span class="t1-step__title">${esc(t)}</span>
    </li>`;
  }).join('')}</ol>`;
}

/** VCard (subtle): viền 1 borderStrong, bo 12, nền surface. */
export const card = (inner, cls = '') => `<div class="t1-card ${cls}">${inner}</div>`;

/**
 * VAppBar: cao 56 + gạch 1 borderDefault, nền surface, tiêu đề headingH3 w700 trái; leading 56 (nút 48) khi có nút ←.
 * subtitle → cao 64: tiêu đề + khe 2 + caption 12/18 textSecondary. actions: IconButton 48 bên phải.
 */
export function appBar(title, { back = false, backDisabled = false, subtitle = '', actions = '' } = {}) {
  return `<header class="t1-appbar${subtitle ? ' t1-appbar--sub' : ''}">
    ${back ? `<button type="button" class="t1-appbar__back" aria-label="Quay lại"${backDisabled ? ' disabled' : ''}>${icon('chevronLeft')}</button>` : ''}
    <div class="t1-appbar__titles"><h1 class="t1-appbar__title">${esc(title)}</h1>${subtitle ? `<p class="t1-appbar__sub">${esc(subtitle)}</p>` : ''}</div>
    ${actions ? `<span class="t1-appbar__actions">${actions}</span>` : ''}
  </header>`;
}

/**
 * VToast trong SnackBar floating (không có snackBarTheme): lề SnackBar 15 / 10 dưới + lề VToast 16 / 4
 * → toast kéo hết bề ngang cửa sổ (cả web 1280). Chỉ hiện `message` (title bị bỏ khi message khác rỗng).
 * Nền toastSurface, bo 16, icon tròn 26 nền theo loại, chữ bodyDefault w600 trắng, nút đóng 44.
 */
const TOAST_ICON = { success: 'check', danger: 'error', info: 'info', warning: 'alert' };
export function toast(type, title, message, { above = 0, device = 'iphone' } = {}) {
  // Scaffold có bottomNavigationBar → SnackBar nổi trên thanh đó (đáy = cao thanh + 14); không có → trên SafeArea (iPhone 34 + 14).
  const bottom = above ? above + (device === 'iphone' ? 34 : 0) + 14 : device === 'iphone' ? 48 : 14;
  return `<div class="t1-toast t1-toast--${type}" role="status" aria-label="${esc(title)}" style="bottom:${bottom}px">
    <span class="t1-toast__icon">${icon(TOAST_ICON[type])}</span>
    <span class="t1-toast__msg">${esc(message || title)}</span>
    <button type="button" class="t1-toast__close" aria-label="Đóng">${icon('close')}</button>
  </div>`;
}

/**
 * showVAdaptiveSheet: < 1024 → showVBottomSheet (tay kéo 36 × 4, bo trên 16, cao tối đa 95%);
 * ≥ 1024 → VSheetDialog không tiêu đề: rộng tối đa 480, cao tối đa 85%, đệm 16 / 24 / 16 / 16 bọc nội dung + nút Đóng 48 góc trên phải.
 */
export function adaptiveSheet(width, body, label, { title = '' } = {}) {
  if (width >= DESKTOP) {
    if (title) {
      // VSheetDialog có title: hàng đệm 16 / 8 / 8 / 8 = tiêu đề H3 w700 + nút Đóng 48, VDivider, nội dung cuộn không đệm.
      return `<div class="sh-scrim sh-scrim--dialog"><section class="t1-dialog" role="dialog" aria-modal="true" aria-label="${esc(label || title)}">
        <div class="t1-dialog__head"><h2>${esc(title)}</h2><button type="button" class="t1-icon-btn" aria-label="Đóng">${icon('close')}</button></div><hr class="t1-divider">
        <div class="t1-dialog__scroll">${body}</div></section></div>`;
    }
    return `<div class="sh-scrim sh-scrim--dialog"><section class="t1-dialog" role="dialog" aria-modal="true" aria-label="${esc(label)}">
      <div class="t1-dialog__body">${body}</div>
      <button type="button" class="t1-dialog__close" aria-label="Đóng">${icon('close')}</button>
    </section></div>`;
  }
  // VBottomSheet có title: H3 w700 đệm 16 / 8 + VDivider.
  return `<div class="sh-scrim sh-scrim--sheet"><section class="t1-sheet" role="dialog" aria-modal="true" aria-label="${esc(label || title)}"><div class="sh-sheet__handle" aria-hidden="true"></div>${title ? `<h2 class="t1-sheet__title">${esc(title)}</h2><hr class="t1-divider">` : ''}<div class="t1-sheet__body">${body}</div></section></div>`;
}

/** Lớp phủ đang xử lý của ResetPasswordPage: surface 50% + VLoading 40. */
export const busyOverlay = () => `<div class="t1-busy" role="progressbar" aria-label="Đang xử lý">${spinner('t1-spin--40')}</div>`;
export const centerLoading = () => `<div class="t1-center">${spinner('t1-spin--40')}</div>`;

/**
 * Scaffold màn công khai: nền surface (trắng), thân trong VContentWidth(authMaxWidth) canh trên.
 * appBar (nếu có) kéo hết bề ngang cửa sổ.
 */
export function plainScaffold({ appbar = '', body, width, cls = '' }) {
  return `<div class="t1-page t1-page--surface ${cls}">${appbar}<div class="t1-scroll"><div class="t1-col" style="max-width:${authColumn(width)}">${body}</div></div></div>`;
}

/**
 * VPageScaffold(contentMaxWidth: authMaxWidth): nền background (xám canvas), VAppBar hết bề ngang,
 * thân cột 480; bottomBar nền surface + gạch trên 1 borderDefault, cùng cột 480.
 */
export function pageScaffold({ title, back = true, backDisabled = false, body, bottomBar = '', width }) {
  const col = authColumn(width);
  return `<div class="t1-page t1-page--canvas">${appBar(title, { back, backDisabled })}
    <div class="t1-scroll"><div class="t1-col" style="max-width:${col}">${body}</div></div>
    ${bottomBar ? `<footer class="t1-bottombar"><div class="t1-col" style="max-width:${col}">${bottomBar}</div></footer>` : ''}
  </div>`;
}

/** Bọc màn ngoài ShellRoute (mọi màn công khai): thanh trạng thái iPhone + màn, không thanh bên / dưới. */
export function bare(v, page, overlay = '') {
  return renderShell({ device: v.device, width: v.width, height: DEVICE[v.device].h, location: v.location, overlay }, page);
}

// ================================================================ đợt 2 — widget màn quản trị
// Thêm từ c45_design_system: primitives/{v_chip, v_badge, v_icon_box}.dart, components/{v_tabs, v_search_bar, v_text_area, v_radio, v_modal,
// v_empty_state, v_card}.dart, forms/v_select.dart, patterns/{v_page_scaffold, v_list_detail_layout}.dart; app: iam_action_tile.dart.

/** VBreakpoints: < 600 mobile, < 1024 tablet, còn lại desktop. */
export const breakpoint = (w) => (w >= DESKTOP ? 'desktop' : w >= 600 ? 'tablet' : 'mobile');
/** VPageScaffold.defaultContentMaxWidth: mobile ∞, tablet 640, desktop 720 — theo bề ngang chỗ đặt (LayoutBuilder). */
export const columnMax = (w) => ({ mobile: Infinity, tablet: 640, desktop: 720 }[breakpoint(w)]);
const colStyle = (w) => (Number.isFinite(columnMax(w)) ? `max-width:${columnMax(w)}px` : '');

/** VListDetailLayout: listWidth 360, minSplitWidth 840 (bề ngang chỗ đặt = cả cửa sổ vì màn quản trị nằm ngoài StoreShell). */
export const LIST_WIDTH = 360;
export const isSplit = (w) => w >= 840;
export const detailWidth = (w) => (isSplit(w) ? w - LIST_WIDTH - 1 : w);

/**
 * VPageScaffold mặc định (không authMaxWidth): nền background, VAppBar hết bề ngang, thân trong cột columnMax(chỗ đặt).
 * fixed: thân không tự cuộn (màn có phần đầu cố định + danh sách cuộn riêng). bottomBar: nền surface + gạch trên, cùng cột.
 * toastHtml: toast của Scaffold này (SnackBar nằm trong Scaffold → đặt trong trang).
 */
export function vScaffold({ title, subtitle = '', back = true, actions = '', body, bottomBar = '', placeWidth, fixed = false, toastHtml = '' }) {
  const st = colStyle(placeWidth);
  const inner = fixed ? `<div class="t1-fixed"><div class="t1-col t1-col--fill" style="${st}">${body}</div></div>` : `<div class="t1-scroll"><div class="t1-col" style="${st}">${body}</div></div>`;
  return `<div class="t1-page t1-page--canvas">${appBar(title, { back, subtitle, actions })}${inner}
    ${bottomBar ? `<footer class="t1-bottombar"><div class="t1-col" style="${st}">${bottomBar}</div></footer>` : ''}${toastHtml}</div>`;
}

/** Hai cột web (VListDetailLayout) hoặc một màn (hẹp). list / detail: HTML; detail đặt trong cột phải có position để toast nằm trong cột. */
export function listDetail(width, list, detail) {
  if (!isSplit(width)) return detail;
  return `<div class="t1-split"><div class="t1-split__list" style="width:${LIST_WIDTH}px">${list}</div><i class="t1-vdivider"></i><div class="t1-split__detail">${detail}</div></div>`;
}

/** Cột phải khi chưa chọn (app_router): Scaffold nền surfaceAlt + VEmptyState giữa (VEmptyMedia info 64 + VEmptyTitle H3 w700). */
export const splitPlaceholder = (text, toastHtml = '') => `<div class="t1-page t1-page--canvas"><div class="t1-empty"><span class="t1-empty__media">${icon('info')}</span><h2 class="t1-empty__title">${esc(text)}</h2></div>${toastHtml}</div>`;

/** IconButton 48 (icon 24, hoặc size). dot: chấm 8 primary ở (6, 6) góc trên phải (bộ lọc đang áp dụng). */
export const iconButton = (ic, label, { size = 24, dot = false, cls = '' } = {}) => `<button type="button" class="t1-icon-btn ${cls}" aria-label="${esc(label)}" style="font-size:${size}px">${icon(ic)}${dot ? '<i class="t1-dot" aria-hidden="true"></i>' : ''}</button>`;

/** VSearchBar (outlined) = VInput 44, viền borderInput, kính lúp 20 textSecondary + khe 5. */
export const searchBar = (hint, value = '') => `<label class="t1-vsearch">${icon('search')}<input type="search" value="${esc(value)}" placeholder="${esc(hint)}"></label>`;

/**
 * VChip: đệm 12 / 6, bo pill, viền 1 theo tone, chữ bodySmall 13/20 w600.
 * neutral (surfaceAlt, borderStrong, textPrimary) · primary (surfaceBrand, borderBrand, textBrand).
 */
export const chip = (label, { tone = 'neutral' } = {}) => `<button type="button" class="t1-chip t1-chip--${tone}" aria-pressed="${tone === 'primary'}">${esc(label)}</button>`;
export const chipRow = (labels, selected) => `<div class="t1-hscroll"><div class="t1-chiprow">${labels.map((l) => chip(l, { tone: l === selected ? 'primary' : 'neutral' })).join('')}</div></div>`;

/** _SelectableFilterChip (bộ lọc thành viên / lời mời): đệm 16 / 8, bo pill; chọn → successBg + viền success + chữ success w600; không → surface + borderDefault, w400. */
export const filterChip = (label, on) => `<button type="button" class="t1-fchip${on ? ' is-on' : ''}" aria-pressed="${on}">${esc(label)}</button>`;

/** VBadge soft isSmall: đệm 8 / 2, caption 12/18 w600; nền backgroundForTone, chữ foregroundForTone. */
export const badge = (label, tone = 'neutral') => `<span class="t1-badge t1-badge--${tone}">${esc(label)}</span>`;

/** VCard: viền 1 borderStrong, bo 12, nền surface (hoặc backgroundColor); isSelected → viền borderBrand + nền surfaceBrand (trừ khi có backgroundColor). */
export const vcard = (inner, { selected = false, keepBg = false, cls = '' } = {}) => `<div class="t1-card t1-card--pad${selected ? (keepBg ? ' is-selected-border' : ' is-selected') : ''} ${cls}">${inner}</div>`;

/**
 * VTabs (line): hàng Expanded, mỗi tab đệm 16 / 12 + gạch dưới 2 (chọn: primary, không: trong) → cao 48; chữ bodyDefault w600
 * (chọn: primary, không: textSecondary); cả hàng gạch dưới 1 borderDefault. Nền trong suốt (thấy nền Scaffold).
 */
export const tabs = (labels, current) => `<div class="t1-tabs" role="tablist">${labels.map((l, i) => `<button type="button" role="tab" class="t1-tab${i === current ? ' is-on' : ''}" aria-selected="${i === current}">${esc(l)}</button>`).join('')}</div>`;

/** VSelect: 44, chữ bodyDefault đệm trái 16, hộp mũi tên 40 bên phải; viền borderInput (tone danger → viền danger). */
export const select = ({ value = '', hint = 'Chọn...', invalid = false } = {}) => `<button type="button" class="t1-select${value ? ' has-value' : ''}${invalid ? ' is-invalid' : ''}"><span>${esc(value || hint)}</span><i class="t1-select__arrow">${icon('chevronDown')}</i></button>`;

/** VTextFormField maxLines 3: đệm 12 / 12, dòng 22 → cao 3 × 22 + 24 + 2. */
export const textArea = ({ value = '', hint = '', invalid = false, disabled = false } = {}) => `<span class="t1-textarea${invalid ? ' is-invalid' : ''}${disabled ? ' is-disabled' : ''}"><textarea rows="3" placeholder="${esc(hint)}"${disabled ? ' disabled' : ''}>${esc(value)}</textarea></span>`;

/** VRadio (Radio Material 48, vòng 20). */
export const radio = (on) => `<span class="t1-radio-hit" aria-hidden="true"><span class="t1-radio${on ? ' is-on' : ''}"></span></span>`;

/** IamActionTile: đệm 16, bo 12, viền 1 borderDefault, nền surface (danger: dangerBg + viền danger); icon 24 + khe 16 + tiêu đề w700 / phụ đề bodySmall + mũi tên 20. */
export const actionTile = (ic, title, sub, danger = false) => `<button type="button" class="t1-atile${danger ? ' is-danger' : ''}">${icon(ic, 't1-atile__ic')}<span class="t1-atile__text"><b>${esc(title)}</b><span>${esc(sub)}</span></span>${icon('chevronRight', 't1-atile__chev')}</button>`;

/**
 * showVConfirmDialog → Dialog Material (insetPadding 40 / 24, chỉ minWidth 280, không maxWidth) bo 16, đệm 20;
 * tiêu đề H3 w700, khe 8, mô tả bodyDefault textSecondary, khe 24, Align(phải) Wrap [secondary, primary(danger)] khe 8.
 * Align giãn hết bề ngang được phép → hộp thoại rộng = cửa sổ − 80 (web 1200).
 */
export const confirmDialog = ({ title, message, cancel, action, destructive = false }) => `<div class="sh-scrim sh-scrim--dialog t1-scrim-dialog"><section class="t1-mdialog" role="alertdialog" aria-modal="true" aria-label="${esc(title)}">
  <h2 class="t1-h3">${esc(title)}</h2><div class="t1-gap-sm"></div><p class="t1-body2">${esc(message)}</p><div class="t1-gap-lg"></div>
  <div class="t1-mdialog__acts">${button(cancel, { variant: 'secondary' })}${button(action, { cls: destructive ? 't1-btn--danger' : '' })}</div></section></div>`;

/** Hàng nhãn — giá trị hai đầu (Row spaceBetween). */
export const kv = (label, value, cls = '') => `<div class="t1-kv ${cls}"><span>${esc(label)}</span><b>${esc(value)}</b></div>`;
