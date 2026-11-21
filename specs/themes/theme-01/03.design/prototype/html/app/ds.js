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
export function button(label, { variant = 'primary', full = false, loading = false, disabled = false, attrs = '' } = {}) {
  const cls = ['t1-btn', `t1-btn--${variant}`, full ? 't1-btn--full' : ''].filter(Boolean).join(' ');
  return `<button type="button" class="${cls}"${disabled || loading ? ' disabled' : ''} ${attrs}>${loading ? spinner('t1-spin--btn') : ''}<span>${esc(label)}</span></button>`;
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
export function banner(status, title, description = '') {
  return `<div class="t1-banner t1-banner--${status}" role="${status === 'error' ? 'alert' : 'status'}">
    <div class="t1-banner__head">${icon(BANNER_ICON[status])}<b>${esc(title)}</b></div>
    ${description ? `<p>${esc(description)}</p>` : ''}
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

/** VAppBar: cao 56 + gạch 1 borderDefault, nền surface, tiêu đề headingH3 w700 trái; leading 56 (nút 48) khi có nút ←. */
export function appBar(title, { back = false, backDisabled = false } = {}) {
  return `<header class="t1-appbar">
    ${back ? `<button type="button" class="t1-appbar__back" aria-label="Quay lại"${backDisabled ? ' disabled' : ''}>${icon('chevronLeft')}</button>` : ''}
    <h1 class="t1-appbar__title">${esc(title)}</h1>
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
export function adaptiveSheet(width, body, label) {
  if (width >= DESKTOP) {
    return `<div class="sh-scrim sh-scrim--dialog"><section class="t1-dialog" role="dialog" aria-modal="true" aria-label="${esc(label)}">
      <div class="t1-dialog__body">${body}</div>
      <button type="button" class="t1-dialog__close" aria-label="Đóng">${icon('close')}</button>
    </section></div>`;
  }
  return `<div class="sh-scrim sh-scrim--sheet"><section class="t1-sheet" role="dialog" aria-modal="true" aria-label="${esc(label)}"><div class="sh-sheet__handle" aria-hidden="true"></div><div class="t1-sheet__body">${body}</div></section></div>`;
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
