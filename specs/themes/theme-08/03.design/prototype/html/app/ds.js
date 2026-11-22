// Widget DS dùng chung cho mọi màn Theme 8 — chép từ theme-04/app/ds.js (đổi t4- → t8-; bản đó chép từ Theme 2 / 3, thêm bottom sheet M3, VRadio,
// VDatePicker, VSection). Phần "thêm cho Theme 8" ở cuối file: VPasswordField, VFieldDescription, VSelect có nhãn / mô tả, VLoading nhỏ. Số đo từ packages/c45_design_system/lib/src:
//   components/{v_button, v_input, v_text_field, v_text_area, v_search_bar, v_banner, v_card, v_app_bar, v_avatar,
//               v_empty_state, v_floating_action_button, v_checkbox, v_toast, v_adaptive_sheet, v_bottom_sheet}.dart
//   primitives/{v_chip, v_badge, v_icon_box, v_skeleton, v_divider}.dart, forms/{v_select, v_choice_list, v_phone_field}.dart
//   patterns/{v_field, v_page_scaffold, v_page_padding, v_list_detail_layout}.dart, theme/v_color_scheme.dart (tone → màu)
// Mỗi hàm trả về HTML; class tiền tố t8-, CSS ở styles/t4.css.
import { icon as sharedIcon } from '../shared/icons.js';
import { DESKTOP } from '../shared/shell.js';

export const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

/** Icon riêng Theme 8 chưa có ở shared/icons.js (VIcons.key = Lucide key, VIcons.fileCheck = Lucide file-check, VIcons.error = Lucide circle-x). Không sửa shared/ để tránh đụng phiên theme khác. */
const LOCAL_ICONS = {
  key: '<path d="m15.5 7.5 2.3 2.3a1 1 0 0 0 1.4 0l2.1-2.1a1 1 0 0 0 0-1.4L19 4"/><path d="m21 2-9.6 9.6"/><circle cx="7.5" cy="15.5" r="5.5"/>',
  fileCheck: '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="m9 15 2 2 4-4"/>',
  circleX: '<circle cx="12" cy="12" r="10"/><path d="m15 9-6 6"/><path d="m9 9 6 6"/>',
  refresh: '<path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M8 16H3v5"/>',
};
export const icon = (name, cls = '') => (LOCAL_ICONS[name]
  ? `<svg class="icon ${cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${LOCAL_ICONS[name]}</svg>`
  : sharedIcon(name, cls));

const spinner = (cls = '') => `<span class="t8-spin ${cls}" aria-hidden="true"></span>`;

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
  const c = ['t8-btn', `t8-btn--${variant}`, tone ? `t8-btn--${tone}` : '', size === 'small' ? 't8-btn--sm' : '', full ? 't8-btn--full' : '', fg ? `t8-btn--fg-${fg}` : '', cls].filter(Boolean).join(' ');
  return `<button type="button" class="${c}"${disabled || loading ? ' disabled' : ''} ${attrs}>${loading ? spinner('t8-spin--btn') : ''}<span>${esc(label)}</span></button>`;
}

/** VFieldLabel: headingH4 14/20 w600 textPrimary + " *" danger, khe 8 dưới. */
export const fieldLabel = (text, required = false) => `<span class="t8-label">${esc(text)}${required ? '<i aria-hidden="true"> *</i>' : ''}</span>`;
/** VFieldError: khe 8 + bodySmall danger. */
export const fieldError = (text) => `<span class="t8-error">${esc(text)}</span>`;

/** VTextField / VPhoneField (VInput): ô 44, đệm ngang 12, viền 1 borderInput, bo 8, nền surface; invalid → viền + chữ danger; tắt → borderDefault + mờ. */
export function input({ value = '', hint = '', invalid = false, disabled = false, prefix = '', suffix = '' } = {}) {
  const c = ['t8-input', invalid ? 'is-invalid' : '', disabled ? 'is-disabled' : ''].filter(Boolean).join(' ');
  return `<span class="${c}">${prefix}<input type="text" value="${esc(value)}" placeholder="${esc(hint)}"${disabled ? ' disabled' : ''} aria-invalid="${invalid}">${suffix}</span>`;
}

/**
 * VTextArea: cao = minLines × dòng + đệm dọc. Thường: đệm 8 ngang / 12 dọc, dòng 22 (bodyDefault).
 * isDense (PartnerCompactMultilineTextField): đệm 4 / 8, chữ 14 cao 1.2 → dòng 16.8.
 */
export function textArea({ value = '', hint = '', minLines = 3, dense = false, invalid = false } = {}) {
  const line = dense ? 16.8 : 22;
  const h = minLines * line + (dense ? 16 : 24);
  return `<span class="t8-textarea${dense ? ' t8-textarea--dense' : ''}${invalid ? ' is-invalid' : ''}" style="min-height:${h}px"><textarea placeholder="${esc(hint)}" rows="${minLines}">${esc(value)}</textarea></span>`;
}

/** VField(label + control + lỗi). */
export function field({ label, required = false, control, error = null }) {
  return `<div class="t8-field${error ? ' is-invalid' : ''}">${label ? fieldLabel(label, required) : ''}${control}${error ? fieldError(error) : ''}</div>`;
}

/** VSelect: 44, chữ bodyDefault (đệm trái 16), hộp mũi tên VIconBox 40 (arrowDropDown, textMuted) bên phải; viền borderInput. */
export function select({ value = '', hint = 'Chọn...' } = {}) {
  return `<button type="button" class="t8-select${value ? ' has-value' : ''}"><span>${esc(value || hint)}</span><i class="t8-select__arrow">${icon('chevronDown')}</i></button>`;
}

/**
 * VSearchBar (outlined) = VInput: 44, đệm 12, viền borderInput; tiền tố kính lúp 20 textSecondary + khe 1 + affixGap 4.
 * suffix: nút xoá (IconButton 48, VIcons.close 20 textSecondary) khi có chữ.
 */
export function searchBar({ value = '', hint = '', clear = false, focused = false } = {}) {
  const x = clear ? `<button type="button" class="t8-search__clear" aria-label="Xóa tìm kiếm">${icon('close')}</button>` : '';
  return `<label class="t8-search${focused ? ' is-focus' : ''}">${icon('search')}<input type="search" value="${esc(value)}" placeholder="${esc(hint)}">${x}</label>`;
}

/**
 * VChip: đệm 12 / 6 (onRemove → phải 4), bo pill, viền 1 theo tone, chữ bodySmall 13/20 w600.
 * tone → (nền, viền, chữ): neutral (surfaceAlt, borderStrong, textPrimary) · primary (surfaceBrand, borderBrand, textBrand) · success (successBg, success, success).
 * icon: cao ≤ dòng chữ (16), khe 8. onRemove: khe 4 + × cỡ dòng; ô bọc cao tối thiểu 44.
 */
export function chip(label, { tone = 'neutral', ic = '', remove = false, full = false } = {}) {
  const inner = `${ic ? `<i class="t8-chip__icon">${icon(ic)}</i>` : ''}<span>${esc(label)}</span>${remove ? `<i class="t8-chip__x">${icon('close')}</i>` : ''}`;
  return `<button type="button" class="t8-chip t8-chip--${tone}${remove ? ' t8-chip--remove' : ''}${full ? ' t8-chip--full' : ''}" aria-pressed="${tone === 'primary'}">${inner}</button>`;
}

/** VBadge (soft): nền + chữ theo tone; thường đệm 10 / 6 chữ bodySmall w600; isSmall đệm 8 / 2 chữ caption 12/18 w600. */
export const badge = (label, { tone = 'neutral', small = false } = {}) => `<span class="t8-badge t8-badge--${tone}${small ? ' t8-badge--sm' : ''}">${esc(label)}</span>`;

/**
 * VIconBox: hộp size (mặc định 40), icon iconSize (20), bo 12 (VRadius.iconBox) hoặc tròn.
 * Chữ (label) thay icon: size < 56 → bodyDefault w600 cỡ iconSize.
 */
export function iconBox({ ic = '', label = '', size = 40, iconSize = 20, cls = '', circle = false, radius = null } = {}) {
  const style = `width:${size}px;height:${size}px;font-size:${iconSize}px${radius != null ? `;border-radius:${radius}px` : ''}`;
  return `<span class="t8-ibox${circle ? ' t8-ibox--circle' : ''} ${cls}" style="${style}" aria-hidden="true">${label ? `<b>${esc(label)}</b>` : icon(ic)}</span>`;
}

/** VAvatar._initialsFrom: 1 từ → chữ đầu; nhiều từ → chữ đầu từ đầu + chữ đầu từ cuối, viết hoa. */
export function initials(name) {
  const words = String(name).trim().split(/\s+/);
  if (!words.length || !words[0]) return '?';
  if (words.length === 1) return words[0].slice(0, 1).toUpperCase();
  return `${words[0].slice(0, 1)}${words[words.length - 1].slice(0, 1)}`.toUpperCase();
}
/** VAvatar(name, textSize 14): VIconBox tròn 40, tone success → nền successBg, chữ success. */
export const avatar = (name) => iconBox({ label: initials(name), size: 40, iconSize: 14, circle: true, cls: 't8-ibox--success' });

/** VBanner: bo 12, viền 1 accent, đệm 16; icon 20 + khe 12 + tiêu đề labelDefault accent; mô tả bodySmall textPrimary lùi 32. */
const BANNER_ICON = { info: 'info', success: 'checkCircle', warning: 'alert', error: 'circleX' }; // VIcons.error = Lucide circle-x (shared 'error' là chấm than)
export function banner(status, title, description = '', { footer = '' } = {}) {
  return `<div class="t8-banner t8-banner--${status}" role="${status === 'error' ? 'alert' : 'status'}">
    <div class="t8-banner__head">${icon(BANNER_ICON[status])}<b>${esc(title)}</b></div>${description ? `<p>${esc(description).replace(/\n/g, '<br>')}</p>` : ''}${footer ? `<div class="t8-banner__footer">${footer}</div>` : ''}</div>`;
}

/** VCard (subtle): viền 1 borderStrong, bo 12, nền surface, đệm 16; isSelected → nền surfaceBrand, viền borderBrand. */
export const card = (inner, { selected = false, cls = '', pad = true } = {}) => `<div class="t8-card${pad ? ' t8-card--pad' : ''}${selected ? ' is-selected' : ''} ${cls}">${inner}</div>`;

/**
 * VEmptyState: đệm 24, nội dung canh giữa (cả dọc khi có chiều cao); VEmptyHeader tối đa 360, khe: sau phần tử 1 = 16, sau đó = 4.
 * VEmptyMedia: VIconBox 64 (icon 28), bo 16, nền surfaceAlt + icon textSecondary; tone danger → dangerBg + danger.
 * VEmptyTitle: headingH3 18/26 w700 canh giữa (tone danger → chữ danger). VEmptyDescription: bodyDefault textSecondary canh giữa.
 * header: mảng phần tử đã dựng (media / title / desc / gap(n)).
 */
export function emptyState({ header, content = '', tone = '', bg = '', fill = true, cls = '' }) {
  const items = header.map((h, i) => (i === 0 ? h : `<i class="t8-gap" style="height:${i === 1 ? 16 : 4}px"></i>${h}`)).join('');
  return `<div class="t8-empty${tone ? ` t8-empty--${tone}` : ''}${bg ? ` t8-empty--${bg}` : ''}${fill ? ' t8-empty--fill' : ''} ${cls}"><div class="t8-empty__inner"><div class="t8-empty__head">${items}</div>${content}</div></div>`;
}
export const emptyMedia = (ic) => iconBox({ ic, size: 64, iconSize: 28.16, radius: 16, cls: 't8-empty__media' });
export const emptyTitle = (text) => `<h2 class="t8-empty__title">${esc(text).replace(/\n/g, '<br>')}</h2>`;
export const emptyDesc = (text) => `<p class="t8-empty__desc">${esc(text).replace(/\n/g, '<br>')}</p>`;
export const gap = (h) => `<i class="t8-gap" style="height:${h}px"></i>`;

/** VSkeleton: khối màu (ở đây borderDefault) bo theo tham số, nhấp nháy độ mờ. */
export const skeleton = (h, { radius = 12, w = '100%' } = {}) => `<span class="t8-skel" style="height:${h}px;width:${w};border-radius:${radius}px" aria-hidden="true"></span>`;

/** VFloatingActionButton: tròn 56, nền (ở đây backgroundColor = success), bóng e2, icon 28 trắng. Vị trí: Scaffold endFloat (lề 16). */
export const fab = (ic, label, style = '') => `<button type="button" class="t8-fab" aria-label="${esc(label)}" style="${style}">${icon(ic)}</button>`;

/** VCheckbox(label): Checkbox Material 48 (ô 18, bo 4, viền 1 borderInput; bật → nền primary + dấu trắng) + khe 8 + bodyDefault textPrimary; đệm dọc 4. */
export const checkbox = (label, checked) => `<button type="button" class="t8-check" role="checkbox" aria-checked="${checked}"><span class="t8-check__hit"><span class="t8-check__box${checked ? ' is-on' : ''}">${checked ? icon('check') : ''}</span></span><span>${esc(label)}</span></button>`;

/** VChoiceListTile (một lựa chọn): Radio Material 48 (vòng 20) + nhãn bodyDefault w600; đệm dọc 8; khe dưới 12. */
export const radioList = (choices, selected) => `<div class="t8-choices" role="radiogroup">${choices.map((c) => `<button type="button" class="t8-choice" role="radio" aria-checked="${c === selected}"><span class="t8-choice__hit"><span class="t8-radio${c === selected ? ' is-on' : ''}"></span></span><span>${esc(c)}</span></button>`).join('')}</div>`;

/** VDivider: 1 borderDefault. */
export const divider = () => '<hr class="t8-divider">';

/**
 * VAppBar: toolbar 56 + gạch 1 borderDefault, nền surface, tiêu đề headingH3 w700 trái (khoảng giữa 16).
 * subtitle → preferredSize 64: tiêu đề + khe 2 + caption 12/18 textSecondary.
 * back: nút ← 48 (VIcons.chevronLeft 24); leading: HTML tự dựng (ô 56).
 */
export function appBar(title, { subtitle = '', back = false, leading = '', center = false, actions = '' } = {}) {
  const lead = leading ? `<span class="t8-appbar__lead">${leading}</span>` : back ? `<span class="t8-appbar__lead"><button type="button" class="t8-appbar__back" aria-label="Quay lại">${icon('chevronLeft')}</button></span>` : '';
  return `<header class="t8-appbar${subtitle ? ' t8-appbar--sub' : ''}${lead ? ' has-lead' : ''}${center ? ' t8-appbar--center' : ''}">
    ${lead}
    <div class="t8-appbar__titles"><h1 class="t8-appbar__title">${esc(title)}</h1>${subtitle ? `<p class="t8-appbar__sub">${esc(subtitle)}</p>` : ''}</div>
    ${actions ? `<span class="t8-appbar__actions">${actions}</span>` : ''}
  </header>`;
}

/**
 * VPageScaffold: nền background (canvas), VAppBar hết bề ngang, thân trong cột columnMax(chỗ đặt) canh giữa.
 * fab: HTML nút nổi đặt góc dưới phải (Scaffold endFloat: lề 16) + đệm phải = gutter theo cửa sổ.
 */
export function scaffold({ appbar, body, bottomBar = '', fabHtml = '', placeWidth, windowWidth, cls = '' }) {
  const max = columnMax(placeWidth);
  const col = Number.isFinite(max) ? `max-width:${max}px` : '';
  const fabWrap = fabHtml ? `<div class="t8-fabpos" style="right:${16 + fabGutter(windowWidth)}px">${fabHtml}</div>` : '';
  return `<div class="t8-page ${cls}">${appbar}
    <div class="t8-body"><div class="t8-col" style="${col}">${body}</div></div>
    ${bottomBar ? `<footer class="t8-bottombar"><div class="t8-col" style="${col}">${bottomBar}</div></footer>` : ''}
    ${fabWrap}
  </div>`;
}

/**
 * VToast trong SnackBar floating: lề SnackBar 15 + lề VToast 16 → kéo hết bề ngang chỗ có ScaffoldMessenger.
 * Chỉ hiện `message`. Nền toastSurface, bo 16, icon tròn 26, chữ bodyDefault w600 trắng, nút đóng 44.
 */
const TOAST_ICON = { success: 'check', danger: 'circleX', info: 'info', warning: 'alert' };
export function toast(type, title, message, { bottom = 14, left = 0, width = null } = {}) {
  const pos = width != null ? `left:${left + 31}px;width:${width - 62}px;right:auto` : '';
  return `<div class="t8-toast t8-toast--${type}" role="status" aria-label="${esc(title)}" style="bottom:${bottom}px;${pos}">
    <span class="t8-toast__icon">${icon(TOAST_ICON[type])}</span>
    <span class="t8-toast__msg">${esc(message || title)}</span>
    <button type="button" class="t8-toast__close" aria-label="Đóng">${icon('close')}</button>
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
      return `<div class="sh-scrim sh-scrim--dialog"><section class="t8-dialog" role="dialog" aria-modal="true" aria-label="${name}">
        <div class="t8-dialog__head"><h2>${esc(title)}</h2><button type="button" class="t8-icon-btn" aria-label="Đóng">${icon('close')}</button></div>${divider()}
        <div class="t8-dialog__scroll">${body}</div></section></div>`;
    }
    return `<div class="sh-scrim sh-scrim--dialog"><section class="t8-dialog" role="dialog" aria-modal="true" aria-label="${name}">
      <div class="t8-dialog__body">${body}</div>
      <button type="button" class="t8-dialog__close t8-icon-btn" aria-label="Đóng">${icon('close')}</button></section></div>`;
  }
  return `<div class="sh-scrim sh-scrim--sheet"><section class="t8-sheet" role="dialog" aria-modal="true" aria-label="${name}"><div class="sh-sheet__handle" aria-hidden="true"></div>
    ${title ? `<h2 class="t8-sheet__title">${esc(title)}</h2>${divider()}` : ''}<div class="t8-sheet__body">${body}</div></section></div>`;
}

/** Vòng tải giữa màn. material: CircularProgressIndicator (36, nét 4, primary); không: VLoading 40. */
export const centerLoading = ({ material = false } = {}) => `<div class="t8-center">${spinner(material ? 't8-spin--material' : 't8-spin--40')}</div>`;

// ---------------------------------------------------------------- thêm cho Theme 2 (giữ nguyên)

/**
 * VSwitch (Switch M3: rãnh 52 × 32, núm 16 tắt / 24 bật, trắng; tắt nền borderInput, bật nền primary; vùng chạm 60 × 48).
 * label: Row(spaceBetween)[Flexible(Text bodyDefault textPrimary), switch], đệm dọc 4. Tắt → vDisabledOpacity 0.4.
 */
export function vswitch(on, { disabled = false, label = '' } = {}) {
  const sw = `<span class="t8-switch-hit"><span class="t8-switch${on ? ' is-on' : ''}"><i></i></span></span>`;
  if (!label) return `<span class="t8-switch-wrap${disabled ? ' is-disabled' : ''}" role="switch" aria-checked="${on}">${sw}</span>`;
  return `<span class="t8-switch-row${disabled ? ' is-disabled' : ''}" role="switch" aria-checked="${on}"><span>${esc(label)}</span>${sw}</span>`;
}

/** Hậu tố chữ của InputDecoration (VMoneyField 'đ', VNumberField '%'): bodyDefault textSecondary. */
export const suffixText = (t) => `<span class="t8-input__suffix">${esc(t)}</span>`;

/**
 * VTextArea có maxLength + showCounter: đệm đáy cộng thêm 16, bộ đếm "n/max" bodySmall textSecondary ở (phải 12, đáy 8).
 * minLines (mặc định 2) / maxLines; dòng 22, đệm 8 ngang / 12 dọc.
 */
export function textAreaCounter({ value = '', hint = '', lines = 4, max = 500, invalid = false } = {}) {
  const h = lines * 22 + 24 + 16;
  return `<span class="t8-textarea t8-textarea--counter${invalid ? ' is-invalid' : ''}" style="min-height:${h}px"><textarea placeholder="${esc(hint)}" rows="${lines}">${esc(value)}</textarea><b class="t8-textarea__count">${value.length}/${max}</b></span>`;
}

// ---------------------------------------------------------------- thêm cho Theme 4 (giữ nguyên)

/**
 * showVBottomSheet (không phải showVAdaptiveSheet): showModalBottomSheet M3 → mọi khổ đều là sheet đáy;
 * BottomSheet M3 mặc định maxWidth 640 → web 1280: sheet 640 canh giữa đáy cửa sổ. VBottomSheet: tay kéo 36 × 4 lề dọc 8 (màu borderStrong),
 * bo trên 16, cao ≤ 95%; có title → H3 w700 đệm 16 / 8 + VDivider. Nội dung trong SafeArea(top: false) → iPhone thêm 34 đáy.
 * Route /more/einvoice/* nằm ngoài khung nên sheet phủ cả màn ở cả hai khổ.
 */
export function bottomSheet(body, { title = '', label = '' } = {}) {
  return `<div class="sh-scrim sh-scrim--sheet t8-m3scrim"><section class="t8-sheet t8-m3sheet" role="dialog" aria-modal="true" aria-label="${esc(label || title || 'Bottom sheet')}"><div class="sh-sheet__handle" aria-hidden="true"></div>
    ${title ? `<h2 class="t8-sheet__title">${esc(title)}</h2>${divider()}` : ''}<div class="t8-sheet__body">${body}</div></section></div>`;
}

/** VSection: tiêu đề headingH3 18/26 w600 (không ép w700) + khe 8 + nội dung. */
export const section = (title, inner) => `<section class="t8-section"><h2 class="t8-section__title">${esc(title)}</h2>${inner}</section>`;

/**
 * VDatePicker: VFieldLabel + ô 44 (đệm ngang 12, viền borderInput, bo 8, nền surface), icon lịch 20 textMuted bên TRÁI + khe 8,
 * chữ bodyDefault (có giá trị → textPrimary; trống → hint textMuted).
 */
export function datePicker({ label, value = '', hint = '', required = false }) {
  return `<div class="t8-field">${label ? fieldLabel(label, required) : ''}<button type="button" class="t8-date${value ? ' has-value' : ''}">${icon('calendar')}<span>${esc(value || hint)}</span></button></div>`;
}

/** VMoneyField: VFieldLabel + VInput 44, chữ monoNumeric 14/20 w600 canh trái, hậu tố "đ" textSecondary. */
export function moneyField({ label, value = '', required = false, hint = '' }) {
  return field({ label, required, control: `<span class="t8-input t8-input--mono"><input type="text" inputmode="numeric" value="${esc(value)}" placeholder="${esc(hint)}">${suffixText('đ')}</span>` });
}

/** VTextField có suffixIcon chevronRight 20 textMuted (ô chọn của form). Tắt → borderDefault + mờ 0.4. */
export function pickerField({ label, value = '', hint = '', required = false, disabled = false }) {
  const c = ['t8-input', 't8-input--picker', disabled ? 'is-disabled' : ''].filter(Boolean).join(' ');
  return `<div class="t8-field${disabled ? ' is-disabled' : ''}">${fieldLabel(label, required)}<span class="${c}"><input type="text" readonly value="${esc(value)}" placeholder="${esc(hint)}"${disabled ? ' disabled' : ''}><i class="t8-input__chev">${icon('chevronRight')}</i></span></div>`;
}

/** VRadio (Radio Material 48, vòng 20; chọn → primary). */
export const radio = (on) => `<span class="t8-choice__hit"><span class="t8-radio${on ? ' is-on' : ''}"></span></span>`;

/** Ô chữ có bộ đếm tự vẽ (sheet "Lưu thay đổi?"): VTextArea minLines 3 không maxLength + caption "n/200" textMuted canh phải dưới. */
export function textAreaPlain({ value = '', hint = '', lines = 3 } = {}) {
  const h = lines * 22 + 24;
  return `<span class="t8-textarea" style="min-height:${h}px"><textarea placeholder="${esc(hint)}" rows="${lines}">${esc(value)}</textarea></span>`;
}

// ---------------------------------------------------------------- thêm cho Theme 8

/** VFieldDescription: khe 8 + bodySmall textSecondary (VSelect / VTextField helperText cũ đi qua đây). */
export const fieldDesc = (text) => `<span class="t8-desc">${esc(text)}</span>`;

/**
 * VPasswordField (VInput): ô 44 như VTextField + nút mắt 44 (VIcons.visibility = Lucide eye, textMuted) ở hậu tố.
 * Có chữ → hiện chấm. Tắt (enabled false) → viền borderDefault + mờ 0.4.
 */
export function passwordInput({ value = '', hint = '', invalid = false, disabled = false } = {}) {
  const c = ['t8-input', invalid ? 'is-invalid' : '', disabled ? 'is-disabled' : ''].filter(Boolean).join(' ');
  return `<span class="${c}"><input type="password" value="${esc(value)}" placeholder="${esc(hint)}"${disabled ? ' disabled' : ''} aria-invalid="${invalid}"><button type="button" class="t8-input__eye" aria-label="Hiện mật khẩu"${disabled ? ' disabled' : ''}>${icon('eye')}</button></span>`;
}

/** VField có mô tả: label + control + (lỗi | mô tả). Lỗi thay mô tả (vFieldShell). */
export function fieldWithDesc({ label, required = false, control, error = null, desc = null, disabled = false }) {
  return `<div class="t8-field${error ? ' is-invalid' : ''}${disabled ? ' is-disabled' : ''}">${label ? fieldLabel(label, required) : ''}${control}${error ? fieldError(error) : desc ? fieldDesc(desc) : ''}</div>`;
}

/** VSelect đầy đủ (vFieldShell): nhãn + ô 44 + lỗi / mô tả; lỗi → viền danger; tắt → cả khối mờ 0.4 (vDisabledOpacity bọc cả shell). */
export function selectField({ label, value = '', hint = 'Chọn...', required = false, error = null, desc = null, disabled = false }) {
  const control = `<button type="button" class="t8-select${value ? ' has-value' : ''}${error ? ' is-invalid' : ''}"${disabled ? ' disabled' : ''}><span>${esc(value || hint)}</span><i class="t8-select__arrow">${icon('chevronDown')}</i></button>`;
  return fieldWithDesc({ label, required, control, error, desc, disabled });
}

/** VLoading cỡ tuỳ ý (size, nét strokeWidth, màu tone). */
export const loadingDot = (size, stroke, tone = 'info') => `<span class="t8-spin t8-spin--tone-${tone}" style="width:${size}px;height:${size}px;border-width:${stroke}px" aria-hidden="true"></span>`;
