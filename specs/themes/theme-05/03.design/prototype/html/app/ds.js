// Widget DS dùng chung cho mọi màn Theme 5 — chép từ theme-04/app/ds.js (đổi t4- → t5-; bản đó chép từ Theme 2 / 3) rồi thêm widget Bán hàng dùng
// (VTabs, VCardHeader / VCardContent, VSegmentedControl, VNumericKeypadSheet, VSwipeReveal, sheet M3 có tone). Số đo từ packages/c45_design_system/lib/src:
//   components/{v_button, v_input, v_text_field, v_text_area, v_search_bar, v_banner, v_card, v_app_bar, v_avatar,
//               v_empty_state, v_floating_action_button, v_checkbox, v_toast, v_adaptive_sheet, v_bottom_sheet}.dart
//   primitives/{v_chip, v_badge, v_icon_box, v_skeleton, v_divider}.dart, forms/{v_select, v_choice_list, v_phone_field}.dart
//   patterns/{v_field, v_page_scaffold, v_page_padding, v_list_detail_layout}.dart, theme/v_color_scheme.dart (tone → màu)
// Mỗi hàm trả về HTML; class tiền tố t5-, CSS ở styles/t5.css.
import { icon as sharedIcon } from '../shared/icons.js';
import { DESKTOP } from '../shared/shell.js';

export const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

/** Icon riêng chưa có ở shared/icons.js (VIcons.straighten, refresh, powerOff, badgePercent, qrCode). Không sửa shared/ để tránh đụng phiên khác. */
const LOCAL_ICONS = {
  ruler: '<path d="M21.3 15.3a2.4 2.4 0 0 1 0 3.4l-2.6 2.6a2.4 2.4 0 0 1-3.4 0L2.7 8.7a2.41 2.41 0 0 1 0-3.4l2.6-2.6a2.41 2.41 0 0 1 3.4 0Z"/><path d="m14.5 12.5 2-2"/><path d="m11.5 9.5 2-2"/><path d="m8.5 6.5 2-2"/><path d="m17.5 15.5 2-2"/>',
  powerOff: '<path d="M18.36 6.64A9 9 0 0 1 20.77 15"/><path d="M6.16 6.16a9 9 0 1 0 12.68 12.68"/><path d="M12 2v4"/><path d="m2 2 20 20"/>',
  badgePercent: '<path d="M3.85 8.62a4 4 0 0 1 4.78-4.77 4 4 0 0 1 6.74 0 4 4 0 0 1 4.78 4.78 4 4 0 0 1 0 6.74 4 4 0 0 1-4.77 4.78 4 4 0 0 1-6.75 0 4 4 0 0 1-4.78-4.77 4 4 0 0 1 0-6.76Z"/><path d="m15 9-6 6"/><path d="M9 9h.01"/><path d="M15 15h.01"/>',
  qrCode: '<rect width="5" height="5" x="3" y="3" rx="1"/><rect width="5" height="5" x="16" y="3" rx="1"/><rect width="5" height="5" x="3" y="16" rx="1"/><path d="M21 16h-3a2 2 0 0 0-2 2v3"/><path d="M21 21v.01"/><path d="M12 7v3a2 2 0 0 1-2 2H7"/><path d="M3 12h.01"/><path d="M12 3h.01"/><path d="M12 16v.01"/><path d="M16 12h1"/><path d="M21 12v.01"/><path d="M12 21v-1"/>',
  refresh: '<path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M8 16H3v5"/>',
};
export const icon = (name, cls = '') => (LOCAL_ICONS[name]
  ? `<svg class="icon ${cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${LOCAL_ICONS[name]}</svg>`
  : sharedIcon(name, cls));

const spinner = (cls = '') => `<span class="t5-spin ${cls}" aria-hidden="true"></span>`;

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
  const c = ['t5-btn', `t5-btn--${variant}`, tone ? `t5-btn--${tone}` : '', size === 'small' ? 't5-btn--sm' : '', full ? 't5-btn--full' : '', fg ? `t5-btn--fg-${fg}` : '', cls].filter(Boolean).join(' ');
  return `<button type="button" class="${c}"${disabled || loading ? ' disabled' : ''} ${attrs}>${loading ? spinner('t5-spin--btn') : ''}<span>${esc(label)}</span></button>`;
}

/** VFieldLabel: headingH4 14/20 w600 textPrimary + " *" danger, khe 8 dưới. */
export const fieldLabel = (text, required = false) => `<span class="t5-label">${esc(text)}${required ? '<i aria-hidden="true"> *</i>' : ''}</span>`;
/** VFieldError: khe 8 + bodySmall danger. */
export const fieldError = (text) => `<span class="t5-error">${esc(text)}</span>`;

/** VTextField / VPhoneField (VInput): ô 44, đệm ngang 12, viền 1 borderInput, bo 8, nền surface; invalid → viền + chữ danger; tắt → borderDefault + mờ. */
export function input({ value = '', hint = '', invalid = false, disabled = false, prefix = '', suffix = '' } = {}) {
  const c = ['t5-input', invalid ? 'is-invalid' : '', disabled ? 'is-disabled' : ''].filter(Boolean).join(' ');
  return `<span class="${c}">${prefix}<input type="text" value="${esc(value)}" placeholder="${esc(hint)}"${disabled ? ' disabled' : ''} aria-invalid="${invalid}">${suffix}</span>`;
}

/**
 * VTextArea: cao = minLines × dòng + đệm dọc. Thường: đệm 8 ngang / 12 dọc, dòng 22 (bodyDefault).
 * isDense (PartnerCompactMultilineTextField): đệm 4 / 8, chữ 14 cao 1.2 → dòng 16.8.
 */
export function textArea({ value = '', hint = '', minLines = 3, dense = false, invalid = false } = {}) {
  const line = dense ? 16.8 : 22;
  const h = minLines * line + (dense ? 16 : 24);
  return `<span class="t5-textarea${dense ? ' t5-textarea--dense' : ''}${invalid ? ' is-invalid' : ''}" style="min-height:${h}px"><textarea placeholder="${esc(hint)}" rows="${minLines}">${esc(value)}</textarea></span>`;
}

/** VField(label + control + lỗi). */
export function field({ label, required = false, control, error = null }) {
  return `<div class="t5-field${error ? ' is-invalid' : ''}">${label ? fieldLabel(label, required) : ''}${control}${error ? fieldError(error) : ''}</div>`;
}

/** VSelect: 44, chữ bodyDefault (đệm trái 16), hộp mũi tên VIconBox 40 (arrowDropDown, textMuted) bên phải; viền borderInput. */
export function select({ value = '', hint = 'Chọn...' } = {}) {
  return `<button type="button" class="t5-select${value ? ' has-value' : ''}"><span>${esc(value || hint)}</span><i class="t5-select__arrow">${icon('chevronDown')}</i></button>`;
}

/**
 * VSearchBar (outlined) = VInput: 44, đệm 12, viền borderInput; tiền tố kính lúp 20 textSecondary + khe 1 + affixGap 4.
 * suffix: nút xoá (IconButton 48, VIcons.close 20 textSecondary) khi có chữ.
 */
export function searchBar({ value = '', hint = '', clear = false, focused = false } = {}) {
  const x = clear ? `<button type="button" class="t5-search__clear" aria-label="Xóa tìm kiếm">${icon('close')}</button>` : '';
  return `<label class="t5-search${focused ? ' is-focus' : ''}">${icon('search')}<input type="search" value="${esc(value)}" placeholder="${esc(hint)}">${x}</label>`;
}

/**
 * VChip: đệm 12 / 6 (onRemove → phải 4), bo pill, viền 1 theo tone, chữ bodySmall 13/20 w600.
 * tone → (nền, viền, chữ): neutral (surfaceAlt, borderStrong, textPrimary) · primary (surfaceBrand, borderBrand, textBrand) · success (successBg, success, success).
 * icon: cao ≤ dòng chữ (16), khe 8. onRemove: khe 4 + × cỡ dòng; ô bọc cao tối thiểu 44.
 */
export function chip(label, { tone = 'neutral', ic = '', remove = false, full = false } = {}) {
  const inner = `${ic ? `<i class="t5-chip__icon">${icon(ic)}</i>` : ''}<span>${esc(label)}</span>${remove ? `<i class="t5-chip__x">${icon('close')}</i>` : ''}`;
  return `<button type="button" class="t5-chip t5-chip--${tone}${remove ? ' t5-chip--remove' : ''}${full ? ' t5-chip--full' : ''}" aria-pressed="${tone === 'primary'}">${inner}</button>`;
}

/** VBadge (soft): nền + chữ theo tone; thường đệm 10 / 6 chữ bodySmall w600; isSmall đệm 8 / 2 chữ caption 12/18 w600. */
export const badge = (label, { tone = 'neutral', small = false } = {}) => `<span class="t5-badge t5-badge--${tone}${small ? ' t5-badge--sm' : ''}">${esc(label)}</span>`;

/**
 * VIconBox: hộp size (mặc định 40), icon iconSize (20), bo 12 (VRadius.iconBox) hoặc tròn.
 * Chữ (label) thay icon: size < 56 → bodyDefault w600 cỡ iconSize.
 */
export function iconBox({ ic = '', label = '', size = 40, iconSize = 20, cls = '', circle = false, radius = null } = {}) {
  const style = `width:${size}px;height:${size}px;font-size:${iconSize}px${radius != null ? `;border-radius:${radius}px` : ''}`;
  return `<span class="t5-ibox${circle ? ' t5-ibox--circle' : ''} ${cls}" style="${style}" aria-hidden="true">${label ? `<b>${esc(label)}</b>` : icon(ic)}</span>`;
}

/** VAvatar._initialsFrom: 1 từ → chữ đầu; nhiều từ → chữ đầu từ đầu + chữ đầu từ cuối, viết hoa. */
export function initials(name) {
  const words = String(name).trim().split(/\s+/);
  if (!words.length || !words[0]) return '?';
  if (words.length === 1) return words[0].slice(0, 1).toUpperCase();
  return `${words[0].slice(0, 1)}${words[words.length - 1].slice(0, 1)}`.toUpperCase();
}
/** VAvatar(name, textSize 14): VIconBox tròn 40, tone success → nền successBg, chữ success. */
export const avatar = (name) => iconBox({ label: initials(name), size: 40, iconSize: 14, circle: true, cls: 't5-ibox--success' });

/** VBanner: bo 12, viền 1 accent, đệm 16; icon 20 + khe 12 + tiêu đề labelDefault accent; mô tả bodySmall textPrimary lùi 32. */
const BANNER_ICON = { info: 'info', success: 'checkCircle', warning: 'alert', error: 'error' };
export function banner(status, title, description = '', { footer = '' } = {}) {
  return `<div class="t5-banner t5-banner--${status}" role="${status === 'error' ? 'alert' : 'status'}">
    <div class="t5-banner__head">${icon(BANNER_ICON[status])}<b>${esc(title)}</b></div>${description ? `<p>${esc(description).replace(/\n/g, '<br>')}</p>` : ''}${footer ? `<div class="t5-banner__footer">${footer}</div>` : ''}</div>`;
}

/** VCard (subtle): viền 1 borderStrong, bo 12, nền surface, đệm 16; isSelected → nền surfaceBrand, viền borderBrand. */
export const card = (inner, { selected = false, cls = '', pad = true } = {}) => `<div class="t5-card${pad ? ' t5-card--pad' : ''}${selected ? ' is-selected' : ''} ${cls}">${inner}</div>`;

/**
 * VEmptyState: đệm 24, nội dung canh giữa (cả dọc khi có chiều cao); VEmptyHeader tối đa 360, khe: sau phần tử 1 = 16, sau đó = 4.
 * VEmptyMedia: VIconBox 64 (icon 28), bo 16, nền surfaceAlt + icon textSecondary; tone danger → dangerBg + danger.
 * VEmptyTitle: headingH3 18/26 w700 canh giữa (tone danger → chữ danger). VEmptyDescription: bodyDefault textSecondary canh giữa.
 * header: mảng phần tử đã dựng (media / title / desc / gap(n)).
 */
export function emptyState({ header, content = '', tone = '', bg = '', fill = true, cls = '' }) {
  const items = header.map((h, i) => (i === 0 ? h : `<i class="t5-gap" style="height:${i === 1 ? 16 : 4}px"></i>${h}`)).join('');
  return `<div class="t5-empty${tone ? ` t5-empty--${tone}` : ''}${bg ? ` t5-empty--${bg}` : ''}${fill ? ' t5-empty--fill' : ''} ${cls}"><div class="t5-empty__inner"><div class="t5-empty__head">${items}</div>${content}</div></div>`;
}
export const emptyMedia = (ic) => iconBox({ ic, size: 64, iconSize: 28.16, radius: 16, cls: 't5-empty__media' });
export const emptyTitle = (text) => `<h2 class="t5-empty__title">${esc(text).replace(/\n/g, '<br>')}</h2>`;
export const emptyDesc = (text) => `<p class="t5-empty__desc">${esc(text).replace(/\n/g, '<br>')}</p>`;
export const gap = (h) => `<i class="t5-gap" style="height:${h}px"></i>`;

/** VSkeleton: khối màu (ở đây borderDefault) bo theo tham số, nhấp nháy độ mờ. */
export const skeleton = (h, { radius = 12, w = '100%' } = {}) => `<span class="t5-skel" style="height:${h}px;width:${w};border-radius:${radius}px" aria-hidden="true"></span>`;

/** VFloatingActionButton: tròn 56, nền (ở đây backgroundColor = success), bóng e2, icon 28 trắng. Vị trí: Scaffold endFloat (lề 16). */
export const fab = (ic, label, style = '') => `<button type="button" class="t5-fab" aria-label="${esc(label)}" style="${style}">${icon(ic)}</button>`;

/** VCheckbox(label): Checkbox Material 48 (ô 18, bo 4, viền 1 borderInput; bật → nền primary + dấu trắng) + khe 8 + bodyDefault textPrimary; đệm dọc 4. */
export const checkbox = (label, checked) => `<button type="button" class="t5-check" role="checkbox" aria-checked="${checked}"><span class="t5-check__hit"><span class="t5-check__box${checked ? ' is-on' : ''}">${checked ? icon('check') : ''}</span></span><span>${esc(label)}</span></button>`;

/** VChoiceListTile (một lựa chọn): Radio Material 48 (vòng 20) + nhãn bodyDefault w600; đệm dọc 8; khe dưới 12. */
export const radioList = (choices, selected) => `<div class="t5-choices" role="radiogroup">${choices.map((c) => `<button type="button" class="t5-choice" role="radio" aria-checked="${c === selected}"><span class="t5-choice__hit"><span class="t5-radio${c === selected ? ' is-on' : ''}"></span></span><span>${esc(c)}</span></button>`).join('')}</div>`;

/** VDivider: 1 borderDefault. */
export const divider = () => '<hr class="t5-divider">';

/**
 * VAppBar: toolbar 56 + gạch 1 borderDefault, nền surface, tiêu đề headingH3 w700 trái (khoảng giữa 16).
 * subtitle → preferredSize 64: tiêu đề + khe 2 + caption 12/18 textSecondary.
 * back: nút ← 48 (VIcons.chevronLeft 24); leading: HTML tự dựng (ô 56).
 */
export function appBar(title, { subtitle = '', back = false, leading = '', center = false, actions = '' } = {}) {
  const lead = leading ? `<span class="t5-appbar__lead">${leading}</span>` : back ? `<span class="t5-appbar__lead"><button type="button" class="t5-appbar__back" aria-label="Quay lại">${icon('chevronLeft')}</button></span>` : '';
  return `<header class="t5-appbar${subtitle ? ' t5-appbar--sub' : ''}${lead ? ' has-lead' : ''}${center ? ' t5-appbar--center' : ''}">
    ${lead}
    <div class="t5-appbar__titles"><h1 class="t5-appbar__title">${esc(title)}</h1>${subtitle ? `<p class="t5-appbar__sub">${esc(subtitle)}</p>` : ''}</div>
    ${actions ? `<span class="t5-appbar__actions">${actions}</span>` : ''}
  </header>`;
}

/**
 * VPageScaffold: nền background (canvas), VAppBar hết bề ngang, thân trong cột columnMax(chỗ đặt) canh giữa.
 * fab: HTML nút nổi đặt góc dưới phải (Scaffold endFloat: lề 16) + đệm phải = gutter theo cửa sổ.
 */
export function scaffold({ appbar, body, bottomBar = '', fabHtml = '', placeWidth, windowWidth, cls = '' }) {
  const max = columnMax(placeWidth);
  const col = Number.isFinite(max) ? `max-width:${max}px` : '';
  const fabWrap = fabHtml ? `<div class="t5-fabpos" style="right:${16 + fabGutter(windowWidth)}px">${fabHtml}</div>` : '';
  return `<div class="t5-page ${cls}">${appbar}
    <div class="t5-body"><div class="t5-col" style="${col}">${body}</div></div>
    ${bottomBar ? `<footer class="t5-bottombar"><div class="t5-col" style="${col}">${bottomBar}</div></footer>` : ''}
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
  return `<div class="t5-toast t5-toast--${type}" role="status" aria-label="${esc(title)}" style="bottom:${bottom}px;${pos}">
    <span class="t5-toast__icon">${icon(TOAST_ICON[type])}</span>
    <span class="t5-toast__msg">${esc(message || title)}</span>
    <button type="button" class="t5-toast__close" aria-label="Đóng">${icon('close')}</button>
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
      return `<div class="sh-scrim sh-scrim--dialog"><section class="t5-dialog" role="dialog" aria-modal="true" aria-label="${name}">
        <div class="t5-dialog__head"><h2>${esc(title)}</h2><button type="button" class="t5-icon-btn" aria-label="Đóng">${icon('close')}</button></div>${divider()}
        <div class="t5-dialog__scroll">${body}</div></section></div>`;
    }
    return `<div class="sh-scrim sh-scrim--dialog"><section class="t5-dialog" role="dialog" aria-modal="true" aria-label="${name}">
      <div class="t5-dialog__body">${body}</div>
      <button type="button" class="t5-dialog__close t5-icon-btn" aria-label="Đóng">${icon('close')}</button></section></div>`;
  }
  return `<div class="sh-scrim sh-scrim--sheet"><section class="t5-sheet" role="dialog" aria-modal="true" aria-label="${name}"><div class="sh-sheet__handle" aria-hidden="true"></div>
    ${title ? `<h2 class="t5-sheet__title">${esc(title)}</h2>${divider()}` : ''}<div class="t5-sheet__body">${body}</div></section></div>`;
}

/** Vòng tải giữa màn. material: CircularProgressIndicator (36, nét 4, primary); không: VLoading 40. */
export const centerLoading = ({ material = false } = {}) => `<div class="t5-center">${spinner(material ? 't5-spin--material' : 't5-spin--40')}</div>`;

// ---------------------------------------------------------------- thêm cho Theme 2 (giữ nguyên)

/**
 * VSwitch (Switch M3: rãnh 52 × 32, núm 16 tắt / 24 bật, trắng; tắt nền borderInput, bật nền primary; vùng chạm 60 × 48).
 * label: Row(spaceBetween)[Flexible(Text bodyDefault textPrimary), switch], đệm dọc 4. Tắt → vDisabledOpacity 0.4.
 */
export function vswitch(on, { disabled = false, label = '' } = {}) {
  const sw = `<span class="t5-switch-hit"><span class="t5-switch${on ? ' is-on' : ''}"><i></i></span></span>`;
  if (!label) return `<span class="t5-switch-wrap${disabled ? ' is-disabled' : ''}" role="switch" aria-checked="${on}">${sw}</span>`;
  return `<span class="t5-switch-row${disabled ? ' is-disabled' : ''}" role="switch" aria-checked="${on}"><span>${esc(label)}</span>${sw}</span>`;
}

/** Hậu tố chữ của InputDecoration (VMoneyField 'đ', VNumberField '%'): bodyDefault textSecondary. */
export const suffixText = (t) => `<span class="t5-input__suffix">${esc(t)}</span>`;

/**
 * VTextArea có maxLength + showCounter: đệm đáy cộng thêm 16, bộ đếm "n/max" bodySmall textSecondary ở (phải 12, đáy 8).
 * minLines (mặc định 2) / maxLines; dòng 22, đệm 8 ngang / 12 dọc.
 */
export function textAreaCounter({ value = '', hint = '', lines = 4, max = 500, invalid = false } = {}) {
  const h = lines * 22 + 24 + 16;
  return `<span class="t5-textarea t5-textarea--counter${invalid ? ' is-invalid' : ''}" style="min-height:${h}px"><textarea placeholder="${esc(hint)}" rows="${lines}">${esc(value)}</textarea><b class="t5-textarea__count">${value.length}/${max}</b></span>`;
}

// ---------------------------------------------------------------- thêm cho Theme 4 (giữ nguyên)

/**
 * showVBottomSheet (không phải showVAdaptiveSheet): showModalBottomSheet M3 → mọi khổ đều là sheet đáy;
 * BottomSheet M3 mặc định maxWidth 640 → web 1280: sheet 640 canh giữa đáy cửa sổ. VBottomSheet: tay kéo 36 × 4 lề dọc 8 (màu borderStrong;
 * tone danger → danger, primary → primary, tone khác giữ borderStrong), bo trên 16, cao ≤ 95%; có title → H3 w700 đệm 16 / 8 + VDivider.
 * Nội dung trong SafeArea(top: false) → iPhone thêm 34 đáy. Route /sales/* (trừ /orders) nằm ngoài khung nên sheet phủ cả màn ở cả hai khổ.
 * height: SizedBox cố định của nội dung (SG-03 = 1/3 màn, SG-04 = 72% màn).
 */
export function bottomSheet(body, { title = '', label = '', tone = '', height = null } = {}) {
  const h = height != null ? ` style="height:${Math.round(height)}px"` : '';
  return `<div class="sh-scrim sh-scrim--sheet t5-m3scrim"><section class="t5-sheet t5-m3sheet" role="dialog" aria-modal="true" aria-label="${esc(label || title || 'Bottom sheet')}"><div class="sh-sheet__handle${tone ? ` t5-handle--${tone}` : ''}" aria-hidden="true"></div>
    ${title ? `<h2 class="t5-sheet__title">${esc(title)}</h2>${divider()}` : ''}<div class="t5-sheet__body${height != null ? ' t5-sheet__body--fixed' : ''}"${h}>${body}</div></section></div>`;
}

/** VSection: tiêu đề headingH3 18/26 w600 (không ép w700) + khe 8 + nội dung. */
export const section = (title, inner) => `<section class="t5-section"><h2 class="t5-section__title">${esc(title)}</h2>${inner}</section>`;

/**
 * VDatePicker: VFieldLabel + ô 44 (đệm ngang 12, viền borderInput, bo 8, nền surface), icon lịch 20 textMuted bên TRÁI + khe 8,
 * chữ bodyDefault (có giá trị → textPrimary; trống → hint textMuted).
 */
export function datePicker({ label, value = '', hint = '', required = false }) {
  return `<div class="t5-field">${label ? fieldLabel(label, required) : ''}<button type="button" class="t5-date${value ? ' has-value' : ''}">${icon('calendar')}<span>${esc(value || hint)}</span></button></div>`;
}

/** VMoneyField: VFieldLabel + VInput 44, chữ monoNumeric 14/20 w600 canh trái, hậu tố "đ" textSecondary. */
export function moneyField({ label, value = '', required = false, hint = '' }) {
  return field({ label, required, control: `<span class="t5-input t5-input--mono"><input type="text" inputmode="numeric" value="${esc(value)}" placeholder="${esc(hint)}">${suffixText('đ')}</span>` });
}

/** VTextField có suffixIcon chevronRight 20 textMuted (ô chọn của form). Tắt → borderDefault + mờ 0.4. */
export function pickerField({ label, value = '', hint = '', required = false, disabled = false }) {
  const c = ['t5-input', 't5-input--picker', disabled ? 'is-disabled' : ''].filter(Boolean).join(' ');
  return `<div class="t5-field${disabled ? ' is-disabled' : ''}">${fieldLabel(label, required)}<span class="${c}"><input type="text" readonly value="${esc(value)}" placeholder="${esc(hint)}"${disabled ? ' disabled' : ''}><i class="t5-input__chev">${icon('chevronRight')}</i></span></div>`;
}

/** VRadio (Radio Material 48, vòng 20; chọn → primary). */
export const radio = (on) => `<span class="t5-choice__hit"><span class="t5-radio${on ? ' is-on' : ''}"></span></span>`;

/** Ô chữ có bộ đếm tự vẽ (sheet "Lưu thay đổi?"): VTextArea minLines 3 không maxLength + caption "n/200" textMuted canh phải dưới. */
export function textAreaPlain({ value = '', hint = '', lines = 3 } = {}) {
  const h = lines * 22 + 24;
  return `<span class="t5-textarea" style="min-height:${h}px"><textarea placeholder="${esc(hint)}" rows="${lines}">${esc(value)}</textarea></span>`;
}

// ---------------------------------------------------------------- thêm cho Theme 5 (Bán hàng)

/** VButton size large: controlHeightLarge 52, đệm ngang 24 (VSpacing.space6). Dùng ở sheet xoá nháp (mật độ thường) và bàn phím số. */
export const buttonLg = (label, opts = {}) => button(label, { ...opts, cls: `t5-btn--lg ${opts.cls || ''}` });

/**
 * VTabs + VTabsList(line) + VTabsTrigger: hàng Expanded chia đều, gạch đáy 1 borderDefault; trigger đệm 16 / 12, chữ bodyDefault 14/22 w600;
 * chọn → màu tone (success = primary xanh) + gạch chỉ báo 2; chưa chọn → textSecondary, gạch trong suốt.
 */
export function tabs(labels, selected) {
  return `<div class="t5-tabs" role="tablist">${labels.map((l, i) => `<button type="button" role="tab" class="t5-tab${i === selected ? ' is-on' : ''}" aria-selected="${i === selected}">${esc(l)}</button>`).join('')}</div>`;
}

/**
 * VCardHeader(title: VCardTitle, action): đệm 16 / 16 / 16 / 8; VCardTitle = headingH4 14/20 w600 + (khe 4 + mô tả bodySmall textSecondary);
 * action canh phải giữa, khe 8. VCardContent: đệm 16 hai bên + đáy, đỉnh 0.
 */
export function cardHeader({ title, desc = '', action = '', pad = '' }) {
  return `<div class="t5-chead"${pad ? ` style="padding:${pad}"` : ''}><div class="t5-chead__t"><b>${esc(title)}</b>${desc ? `<span>${esc(desc)}</span>` : ''}</div>${action ? `<span class="t5-chead__a">${action}</span>` : ''}</div>`;
}
export const cardContent = (inner) => `<div class="t5-ccontent">${inner}</div>`;

/**
 * VSegmentedControl: cao 44 (controlHeightMedium), nền surfaceAlt, viền 1 borderDefault, bo 8 + 4; thumb lùi 4;
 * mỗi đoạn đệm ngang 8, chọn → nền surface, viền borderStrong, bóng e1, chữ màu tone (success); chưa chọn chữ textSecondary. Chữ actionDefault 14/20 w600.
 */
export function segmented(labels, selected) {
  return `<div class="t5-seg" role="radiogroup">${labels.map((l, i) => `<button type="button" role="radio" class="t5-seg__item${i === selected ? ' is-on' : ''}" aria-checked="${i === selected}"><span>${esc(l)}</span></button>`).join('')}</div>`;
}

/** VFieldDescription: khe 8 + bodySmall textSecondary. */
export const fieldDesc = (text) => `<span class="t5-fdesc">${esc(text)}</span>`;

/** VRadio(label): Radio Material 48 + khe 8 + bodyDefault (14/22 w500) textPrimary. */
export const radioLabel = (label, on) => `<span class="t5-radiol" role="radio" aria-checked="${on}">${radio(on)}<span>${esc(label)}</span></span>`;

/**
 * showVNumericKeypadSheet: showModalBottomSheet (M3, web rộng ≤ 640) với nội dung tự vẽ — KHÔNG phải VBottomSheet:
 * nền surface bo trên 16, đệm 16 / 12 / 16 / 16 (+ vùng an toàn đáy); tay kéo 48 × 4 màu borderDefault (sheet khác 36 × 4 borderStrong);
 * khe 8; tiêu đề headingH3 (w600, không ép w700); đơn vị bodySmall textSecondary; khe 8; ô hiển thị VInput đệm 16 / 20, chữ headingH1 canh giữa
 * (tiền có hậu tố "đ" headingH2 textMuted, nhóm nghìn bằng dấu phẩy); khe 8; lưới 4 × 3 phím VCard cao 52 viền borderDefault, khe 8;
 * phím trái dưới: tiền "000", số lượng không thập phân → trống; khe 8; "Hủy" | "Lưu" large 52.
 */
export function keypadSheet({ title, unit, value, money = false, decimal = false }) {
  const bl = money ? '000' : decimal ? '.' : '';
  const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', bl, '0', '⌫'];
  const grid = keys.map((k) => `<span class="t5-key${k === '' ? ' is-blank' : ''}${['000', '⌫', '.'].includes(k) ? ' is-special' : ''}">${esc(k)}</span>`).join('');
  return `<div class="sh-scrim sh-scrim--sheet t5-m3scrim"><section class="t5-keypad t5-m3sheet" role="dialog" aria-modal="true" aria-label="${esc(title)}">
    <i class="t5-keypad__handle" aria-hidden="true"></i>
    <h2 class="t5-keypad__title">${esc(title)}</h2><p class="t5-keypad__unit">${esc(unit)}</p>
    <div class="t5-keypad__display"><span>${esc(value)}</span>${money ? '<em>đ</em>' : ''}</div>
    <div class="t5-keypad__grid">${grid}</div>
    <div class="t5-row2 t5-row2--8">${buttonLg('Hủy', { variant: 'secondary', full: true })}${buttonLg('Lưu', { full: true })}</div>
  </section></div>`;
}

/** VLoading cỡ 18 nét 2 (hậu tố ô tìm khi đang tải). */
export const smallLoading = () => '<span class="t5-spin t5-spin--18" aria-label="Đang tải"></span>';
