// Widget DS dùng chung cho mọi màn Theme 3 — chép từ theme-01/app/ds.js (cách A, 10-8: mỗi theme tự đứng một mình) rồi thêm
// widget đối tác dùng. Số đo từ packages/c45_design_system/lib/src:
//   components/{v_button, v_input, v_text_field, v_text_area, v_search_bar, v_banner, v_card, v_app_bar, v_avatar,
//               v_empty_state, v_floating_action_button, v_checkbox, v_toast, v_adaptive_sheet, v_bottom_sheet}.dart
//   primitives/{v_chip, v_badge, v_icon_box, v_skeleton, v_divider}.dart, forms/{v_select, v_choice_list, v_phone_field}.dart
//   patterns/{v_field, v_page_scaffold, v_page_padding, v_list_detail_layout}.dart, theme/v_color_scheme.dart (tone → màu)
// Mỗi hàm trả về HTML; class tiền tố t3-, CSS ở styles/t3.css.
import { icon } from '../shared/icons.js';
import { DESKTOP } from '../shared/shell.js';

export const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

const spinner = (cls = '') => `<span class="t3-spin ${cls}" aria-hidden="true"></span>`;

/** VBreakpoints: < 600 mobile, < 1024 tablet, còn lại desktop. */
export const breakpoint = (w) => (w >= DESKTOP ? 'desktop' : w >= 600 ? 'tablet' : 'mobile');
/** VPageScaffold.defaultContentMaxWidth: mobile ∞, tablet 640, desktop 720 — tính theo bề ngang chỗ đặt (LayoutBuilder). */
export const columnMax = (w) => ({ mobile: Infinity, tablet: 640, desktop: 720 }[breakpoint(w)]);
/** VPageScaffold._gutter: tính theo MediaQuery (cửa sổ), không theo chỗ đặt — dùng đẩy nút nổi. */
export const fabGutter = (windowWidth) => {
  const max = columnMax(windowWidth);
  return max >= windowWidth ? 0 : (windowWidth - max) / 2;
};

/**
 * VButton. variant: primary | secondary | tertiary | link; tone 'danger' đổi màu (primary nền danger, tertiary chữ danger).
 * medium 44 (đệm ngang 16); small 36 (đệm 12) nhưng vùng chạm vẫn 44. Tắt → vDisabledOpacity 0.4. isLoading: vòng 20 + khe 8.
 * tertiary: nền trong, chữ textBrand (#26612F); foregroundColor ghi đè chữ (fg: 'primary').
 */
export function button(label, { variant = 'primary', tone = '', size = 'medium', full = false, loading = false, disabled = false, fg = '', attrs = '', cls = '' } = {}) {
  const c = ['t3-btn', `t3-btn--${variant}`, tone ? `t3-btn--${tone}` : '', size === 'small' ? 't3-btn--sm' : '', full ? 't3-btn--full' : '', fg ? `t3-btn--fg-${fg}` : '', cls].filter(Boolean).join(' ');
  return `<button type="button" class="${c}"${disabled || loading ? ' disabled' : ''} ${attrs}>${loading ? spinner('t3-spin--btn') : ''}<span>${esc(label)}</span></button>`;
}

/** VFieldLabel: headingH4 14/20 w600 textPrimary + " *" danger, khe 8 dưới. */
export const fieldLabel = (text, required = false) => `<span class="t3-label">${esc(text)}${required ? '<i aria-hidden="true"> *</i>' : ''}</span>`;
/** VFieldError: khe 8 + bodySmall danger. */
export const fieldError = (text) => `<span class="t3-error">${esc(text)}</span>`;

/** VTextField / VPhoneField (VInput): ô 44, đệm ngang 12, viền 1 borderInput, bo 8, nền surface; invalid → viền + chữ danger; tắt → borderDefault + mờ. */
export function input({ value = '', hint = '', invalid = false, disabled = false, prefix = '', suffix = '' } = {}) {
  const c = ['t3-input', invalid ? 'is-invalid' : '', disabled ? 'is-disabled' : ''].filter(Boolean).join(' ');
  return `<span class="${c}">${prefix}<input type="text" value="${esc(value)}" placeholder="${esc(hint)}"${disabled ? ' disabled' : ''} aria-invalid="${invalid}">${suffix}</span>`;
}

/**
 * VTextArea: cao = minLines × dòng + đệm dọc. Thường: đệm 8 ngang / 12 dọc, dòng 22 (bodyDefault).
 * isDense (PartnerCompactMultilineTextField): đệm 4 / 8, chữ 14 cao 1.2 → dòng 16.8.
 */
export function textArea({ value = '', hint = '', minLines = 3, dense = false, invalid = false } = {}) {
  const line = dense ? 16.8 : 22;
  const h = minLines * line + (dense ? 16 : 24);
  return `<span class="t3-textarea${dense ? ' t3-textarea--dense' : ''}${invalid ? ' is-invalid' : ''}" style="min-height:${h}px"><textarea placeholder="${esc(hint)}" rows="${minLines}">${esc(value)}</textarea></span>`;
}

/** VField(label + control + lỗi). */
export function field({ label, required = false, control, error = null }) {
  return `<div class="t3-field${error ? ' is-invalid' : ''}">${label ? fieldLabel(label, required) : ''}${control}${error ? fieldError(error) : ''}</div>`;
}

/** VSelect: 44, chữ bodyDefault (đệm trái 16), hộp mũi tên VIconBox 40 (arrowDropDown, textMuted) bên phải; viền borderInput. */
export function select({ value = '', hint = 'Chọn...' } = {}) {
  return `<button type="button" class="t3-select${value ? ' has-value' : ''}"><span>${esc(value || hint)}</span><i class="t3-select__arrow">${icon('chevronDown')}</i></button>`;
}

/**
 * VSearchBar (outlined) = VInput: 44, đệm 12, viền borderInput; tiền tố kính lúp 20 textSecondary + khe 1 + affixGap 4.
 * suffix: nút xoá (IconButton 48, VIcons.close 20 textSecondary) khi có chữ.
 */
export function searchBar({ value = '', hint = '', clear = false, focused = false } = {}) {
  const x = clear ? `<button type="button" class="t3-search__clear" aria-label="Xóa tìm kiếm">${icon('close')}</button>` : '';
  return `<label class="t3-search${focused ? ' is-focus' : ''}">${icon('search')}<input type="search" value="${esc(value)}" placeholder="${esc(hint)}">${x}</label>`;
}

/**
 * VChip: đệm 12 / 6 (onRemove → phải 4), bo pill, viền 1 theo tone, chữ bodySmall 13/20 w600.
 * tone → (nền, viền, chữ): neutral (surfaceAlt, borderStrong, textPrimary) · primary (surfaceBrand, borderBrand, textBrand) · success (successBg, success, success).
 * icon: cao ≤ dòng chữ (16), khe 8. onRemove: khe 4 + × cỡ dòng; ô bọc cao tối thiểu 44.
 */
export function chip(label, { tone = 'neutral', ic = '', remove = false, full = false } = {}) {
  const inner = `${ic ? `<i class="t3-chip__icon">${icon(ic)}</i>` : ''}<span>${esc(label)}</span>${remove ? `<i class="t3-chip__x">${icon('close')}</i>` : ''}`;
  return `<button type="button" class="t3-chip t3-chip--${tone}${remove ? ' t3-chip--remove' : ''}${full ? ' t3-chip--full' : ''}" aria-pressed="${tone === 'primary'}">${inner}</button>`;
}

/** VBadge (soft): nền + chữ theo tone; thường đệm 10 / 6 chữ bodySmall w600; isSmall đệm 8 / 2 chữ caption 12/18 w600. */
export const badge = (label, { tone = 'neutral', small = false } = {}) => `<span class="t3-badge t3-badge--${tone}${small ? ' t3-badge--sm' : ''}">${esc(label)}</span>`;

/**
 * VIconBox: hộp size (mặc định 40), icon iconSize (20), bo 12 (VRadius.iconBox) hoặc tròn.
 * Chữ (label) thay icon: size < 56 → bodyDefault w600 cỡ iconSize.
 */
export function iconBox({ ic = '', label = '', size = 40, iconSize = 20, cls = '', circle = false, radius = null } = {}) {
  const style = `width:${size}px;height:${size}px;font-size:${iconSize}px${radius != null ? `;border-radius:${radius}px` : ''}`;
  return `<span class="t3-ibox${circle ? ' t3-ibox--circle' : ''} ${cls}" style="${style}" aria-hidden="true">${label ? `<b>${esc(label)}</b>` : icon(ic)}</span>`;
}

/** VAvatar._initialsFrom: 1 từ → chữ đầu; nhiều từ → chữ đầu từ đầu + chữ đầu từ cuối, viết hoa. */
export function initials(name) {
  const words = String(name).trim().split(/\s+/);
  if (!words.length || !words[0]) return '?';
  if (words.length === 1) return words[0].slice(0, 1).toUpperCase();
  return `${words[0].slice(0, 1)}${words[words.length - 1].slice(0, 1)}`.toUpperCase();
}
/** VAvatar(name, textSize 14): VIconBox tròn 40, tone success → nền successBg, chữ success. */
export const avatar = (name) => iconBox({ label: initials(name), size: 40, iconSize: 14, circle: true, cls: 't3-ibox--success' });

/** VBanner: bo 12, viền 1 accent, đệm 16; icon 20 + khe 12 + tiêu đề labelDefault accent; mô tả bodySmall textPrimary lùi 32. */
const BANNER_ICON = { info: 'info', success: 'checkCircle', warning: 'alert', error: 'error' };
export function banner(status, title, description = '') {
  return `<div class="t3-banner t3-banner--${status}" role="${status === 'error' ? 'alert' : 'status'}">
    <div class="t3-banner__head">${icon(BANNER_ICON[status])}<b>${esc(title)}</b></div>${description ? `<p>${esc(description)}</p>` : ''}</div>`;
}

/** VCard (subtle): viền 1 borderStrong, bo 12, nền surface, đệm 16; isSelected → nền surfaceBrand, viền borderBrand. */
export const card = (inner, { selected = false, cls = '', pad = true } = {}) => `<div class="t3-card${pad ? ' t3-card--pad' : ''}${selected ? ' is-selected' : ''} ${cls}">${inner}</div>`;

/**
 * VEmptyState: đệm 24, nội dung canh giữa (cả dọc khi có chiều cao); VEmptyHeader tối đa 360, khe: sau phần tử 1 = 16, sau đó = 4.
 * VEmptyMedia: VIconBox 64 (icon 28), bo 16, nền surfaceAlt + icon textSecondary; tone danger → dangerBg + danger.
 * VEmptyTitle: headingH3 18/26 w700 canh giữa (tone danger → chữ danger). VEmptyDescription: bodyDefault textSecondary canh giữa.
 * header: mảng phần tử đã dựng (media / title / desc / gap(n)).
 */
export function emptyState({ header, content = '', tone = '', bg = '', fill = true, cls = '' }) {
  const items = header.map((h, i) => (i === 0 ? h : `<i class="t3-gap" style="height:${i === 1 ? 16 : 4}px"></i>${h}`)).join('');
  return `<div class="t3-empty${tone ? ` t3-empty--${tone}` : ''}${bg ? ` t3-empty--${bg}` : ''}${fill ? ' t3-empty--fill' : ''} ${cls}"><div class="t3-empty__inner"><div class="t3-empty__head">${items}</div>${content}</div></div>`;
}
export const emptyMedia = (ic) => iconBox({ ic, size: 64, iconSize: 28.16, radius: 16, cls: 't3-empty__media' });
export const emptyTitle = (text) => `<h2 class="t3-empty__title">${esc(text).replace(/\n/g, '<br>')}</h2>`;
export const emptyDesc = (text) => `<p class="t3-empty__desc">${esc(text).replace(/\n/g, '<br>')}</p>`;
export const gap = (h) => `<i class="t3-gap" style="height:${h}px"></i>`;

/** VSkeleton: khối màu (ở đây borderDefault) bo theo tham số, nhấp nháy độ mờ. */
export const skeleton = (h, { radius = 12, w = '100%' } = {}) => `<span class="t3-skel" style="height:${h}px;width:${w};border-radius:${radius}px" aria-hidden="true"></span>`;

/** VFloatingActionButton: tròn 56, nền (ở đây backgroundColor = success), bóng e2, icon 28 trắng. Vị trí: Scaffold endFloat (lề 16). */
export const fab = (ic, label, style = '') => `<button type="button" class="t3-fab" aria-label="${esc(label)}" style="${style}">${icon(ic)}</button>`;

/** VCheckbox(label): Checkbox Material 48 (ô 18, bo 4, viền 1 borderInput; bật → nền primary + dấu trắng) + khe 8 + bodyDefault textPrimary; đệm dọc 4. */
export const checkbox = (label, checked) => `<button type="button" class="t3-check" role="checkbox" aria-checked="${checked}"><span class="t3-check__hit"><span class="t3-check__box${checked ? ' is-on' : ''}">${checked ? icon('check') : ''}</span></span><span>${esc(label)}</span></button>`;

/** VChoiceListTile (một lựa chọn): Radio Material 48 (vòng 20) + nhãn bodyDefault w600; đệm dọc 8; khe dưới 12. */
export const radioList = (choices, selected) => `<div class="t3-choices" role="radiogroup">${choices.map((c) => `<button type="button" class="t3-choice" role="radio" aria-checked="${c === selected}"><span class="t3-choice__hit"><span class="t3-radio${c === selected ? ' is-on' : ''}"></span></span><span>${esc(c)}</span></button>`).join('')}</div>`;

/** VDivider: 1 borderDefault. */
export const divider = () => '<hr class="t3-divider">';

/**
 * VAppBar: toolbar 56 + gạch 1 borderDefault, nền surface, tiêu đề headingH3 w700 trái (khoảng giữa 16).
 * subtitle → preferredSize 64: tiêu đề + khe 2 + caption 12/18 textSecondary.
 * back: nút ← 48 (VIcons.chevronLeft 24); leading: HTML tự dựng (ô 56).
 */
export function appBar(title, { subtitle = '', back = false, leading = '' } = {}) {
  const lead = leading ? `<span class="t3-appbar__lead">${leading}</span>` : back ? `<span class="t3-appbar__lead"><button type="button" class="t3-appbar__back" aria-label="Quay lại">${icon('chevronLeft')}</button></span>` : '';
  return `<header class="t3-appbar${subtitle ? ' t3-appbar--sub' : ''}${lead ? ' has-lead' : ''}">
    ${lead}
    <div class="t3-appbar__titles"><h1 class="t3-appbar__title">${esc(title)}</h1>${subtitle ? `<p class="t3-appbar__sub">${esc(subtitle)}</p>` : ''}</div>
  </header>`;
}

/**
 * VPageScaffold: nền background (canvas), VAppBar hết bề ngang, thân trong cột columnMax(chỗ đặt) canh giữa.
 * fab: HTML nút nổi đặt góc dưới phải (Scaffold endFloat: lề 16) + đệm phải = gutter theo cửa sổ.
 */
export function scaffold({ appbar, body, bottomBar = '', fabHtml = '', placeWidth, windowWidth, cls = '' }) {
  const max = columnMax(placeWidth);
  const col = Number.isFinite(max) ? `max-width:${max}px` : '';
  const fabWrap = fabHtml ? `<div class="t3-fabpos" style="right:${16 + fabGutter(windowWidth)}px">${fabHtml}</div>` : '';
  return `<div class="t3-page ${cls}">${appbar}
    <div class="t3-body"><div class="t3-col" style="${col}">${body}</div></div>
    ${bottomBar ? `<footer class="t3-bottombar"><div class="t3-col" style="${col}">${bottomBar}</div></footer>` : ''}
    ${fabWrap}
  </div>`;
}

/**
 * VToast trong SnackBar floating: lề SnackBar 15 + lề VToast 16 → kéo hết bề ngang chỗ có ScaffoldMessenger.
 * Chỉ hiện `message`. Nền toastSurface, bo 16, icon tròn 26, chữ bodyDefault w600 trắng, nút đóng 44.
 */
const TOAST_ICON = { success: 'check', danger: 'error', info: 'info', warning: 'alert' };
export function toast(type, title, message, { bottom = 14, left = 0, width = null } = {}) {
  const pos = width != null ? `left:${left + 31}px;width:${width - 62}px;right:auto` : '';
  return `<div class="t3-toast t3-toast--${type}" role="status" aria-label="${esc(title)}" style="bottom:${bottom}px;${pos}">
    <span class="t3-toast__icon">${icon(TOAST_ICON[type])}</span>
    <span class="t3-toast__msg">${esc(message || title)}</span>
    <button type="button" class="t3-toast__close" aria-label="Đóng">${icon('close')}</button>
  </div>`;
}

/**
 * showVAdaptiveSheet: cửa sổ < 1024 → VBottomSheet (tay kéo 36 × 4 lề dọc 8, bo trên 16, cao tối đa 95%; có title: H3 w700 đệm 16 / 8 + VDivider;
 * nội dung trong SafeArea → iPhone thêm 34 đáy). ≥ 1024 → VSheetDialog (rộng ≤ 480, cao ≤ 85%):
 *   có title: hàng đệm 16 / 8 / 8 / 8 = tiêu đề H3 w700 + nút Đóng 48, VDivider, nội dung cuộn không đệm;
 *   không title: nội dung đệm 16 / 24 / 16 / 16 + nút Đóng 48 ở (8, 8).
 */
export function adaptiveSheet(windowWidth, body, { title = '', label = '' } = {}) {
  const name = esc(label || title);
  if (windowWidth >= DESKTOP) {
    if (title) {
      return `<div class="sh-scrim sh-scrim--dialog"><section class="t3-dialog" role="dialog" aria-modal="true" aria-label="${name}">
        <div class="t3-dialog__head"><h2>${esc(title)}</h2><button type="button" class="t3-icon-btn" aria-label="Đóng">${icon('close')}</button></div>${divider()}
        <div class="t3-dialog__scroll">${body}</div></section></div>`;
    }
    return `<div class="sh-scrim sh-scrim--dialog"><section class="t3-dialog" role="dialog" aria-modal="true" aria-label="${name}">
      <div class="t3-dialog__body">${body}</div>
      <button type="button" class="t3-dialog__close t3-icon-btn" aria-label="Đóng">${icon('close')}</button></section></div>`;
  }
  return `<div class="sh-scrim sh-scrim--sheet"><section class="t3-sheet" role="dialog" aria-modal="true" aria-label="${name}"><div class="sh-sheet__handle" aria-hidden="true"></div>
    ${title ? `<h2 class="t3-sheet__title">${esc(title)}</h2>${divider()}` : ''}<div class="t3-sheet__body">${body}</div></section></div>`;
}

/** Vòng tải giữa màn. material: CircularProgressIndicator (36, nét 4, primary); không: VLoading 40. */
export const centerLoading = ({ material = false } = {}) => `<div class="t3-center">${spinner(material ? 't3-spin--material' : 't3-spin--40')}</div>`;
