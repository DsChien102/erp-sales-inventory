// Widget DS cho màn "Hỏi Mosaic Retail" — chép phần cần dùng từ theme-08/app/ds.js (đổi t8- → ai-): esc, icon, button, input, appBar.
// Thêm cho màn này: iconButton (VButton.icon), table (VTable). Số đo từ packages/c45_design_system/lib/src:
//   components/{v_button, v_input, v_text_field, v_app_bar, v_table}.dart, tokens/{v_spacing, v_radius, v_breakpoints, v_typography, v_borders}.dart
// Mỗi hàm trả về HTML; class tiền tố ai-, CSS ở styles/ai.css.
import { icon as sharedIcon } from '../shared/icons.js';

export const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

export const icon = (name, cls = '') => sharedIcon(name, cls);

/** VBreakpoints.tablet = 600 (AssistantResultTable đổi lưới / thẻ theo bề ngang khung bảng). */
export const TABLET = 600;

/**
 * VButton. variant: primary | secondary. medium 44 (đệm ngang 16). Tắt → vDisabledOpacity 0.4.
 * secondary: nền surface, viền borderInput, chữ textPrimary.
 */
export function button(label, { variant = 'primary', disabled = false, attrs = '' } = {}) {
  return `<button type="button" class="ai-btn ai-btn--${variant}"${disabled ? ' disabled' : ''} ${attrs}><span>${esc(label)}</span></button>`;
}

/** VButton.icon (primary, medium): ô 44 × 44, đệm ngang 12, icon 20 trắng trên nền primary, bo 8. Tắt (onPressed null) → mờ 0.4. */
export function iconButton(ic, label, { disabled = false } = {}) {
  return `<button type="button" class="ai-btn ai-btn--primary ai-btn--icon" aria-label="${esc(label)}"${disabled ? ' disabled' : ''}>${icon(ic)}</button>`;
}

/** VTextField (VInput): ô 44, đệm ngang 12, viền 1 borderInput, bo 8, nền surface; tắt → viền borderDefault + mờ 0.4. */
export function input({ value = '', hint = '', disabled = false, focused = false } = {}) {
  const c = ['ai-input', disabled ? 'is-disabled' : '', focused ? 'is-focus' : ''].filter(Boolean).join(' ');
  return `<span class="${c}"><input type="text" value="${esc(value)}" placeholder="${esc(hint)}" maxlength="500"${disabled ? ' disabled' : ''} enterkeyhint="send"></span>`;
}

/**
 * VAppBar: toolbar 56 + gạch 1 borderDefault, nền surface, tiêu đề headingH3 w700 trái.
 * back: nút ← 48 (VIcons.chevronLeft 24) — /ask mở bằng context.push từ Home nên luôn pop được.
 */
export function appBar(title, { back = true } = {}) {
  const lead = back ? `<span class="ai-appbar__lead"><button type="button" class="ai-appbar__back" aria-label="Quay lại">${icon('chevronLeft')}</button></span>` : '';
  return `<header class="ai-appbar${back ? ' has-lead' : ''}">${lead}<div class="ai-appbar__titles"><h1 class="ai-appbar__title">${esc(title)}</h1></div></header>`;
}

/**
 * VTable (emphasis medium, tone neutral): Table Flutter, viền dưới + giữa các dòng borderDefault 1;
 * dòng đầu: viền dưới borderStrong 1, chữ caption 12/18 w700 textSecondary VIẾT HOA, đệm 12 / 8; số canh phải.
 * Ô: đệm 12 / 8; cột số Align phải. onRowTap → mọi ô là InkWell. widths: mảng flex theo cột (FlexColumnWidth).
 * headers: [{ title, numeric }]; rows: [[html ô]].
 */
export function table({ headers, rows, widths, tappable = false }) {
  const cols = widths.map((f) => `<col style="width:${(100 * f) / widths.reduce((a, b) => a + b, 0)}%">`).join('');
  const th = headers.map((h) => `<th class="${h.numeric ? 'is-num' : ''}">${esc(h.title.toUpperCase())}</th>`).join('');
  const tr = rows.map((r) => `<tr${tappable ? ' class="is-tap"' : ''}>${r.map((cell, i) => `<td class="${headers[i].numeric ? 'is-num' : ''}">${cell}</td>`).join('')}</tr>`).join('');
  return `<table class="ai-table"><colgroup>${cols}</colgroup><thead><tr>${th}</tr></thead><tbody>${tr}</tbody></table>`;
}
