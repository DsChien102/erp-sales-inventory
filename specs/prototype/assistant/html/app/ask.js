// AI-01 "Hỏi Mosaic Retail" (/ask) — vẽ y nguyên Flutter, không thiết kế lại. Nguồn (apps/erp/lib/features/assistant/):
//   presentation/pages/ask_assistant_page.dart            khung màn: VAppBar, ListView(đệm 16) trong cột ≤ 840, ô nhập + chân trong SafeArea(top: false) cột ≤ 840
//   presentation/widgets/assistant_suggestions.dart       lời chào + 4 câu gợi ý (pill, viền borderInput, cao ≥ 44)
//   presentation/widgets/assistant_message_bubble.dart    bong bóng hỏi / trả lời / lỗi / đang chờ
//   presentation/widgets/assistant_result_table.dart      bảng: lưới VTable khi khung bảng ≥ 600, hẹp hơn thì từng thẻ
//   presentation/widgets/assistant_composer.dart          VTextField + VButton.icon(send)
//   presentation/widgets/assistant_footer.dart            "Còn N câu hỏi hôm nay." (≤ 10) + câu nhắc
//   presentation/assistant_cell_format.dart, assistant_open_target.dart, data/models/assistant_reply.dart, logic/ask_assistant_{cubit,state}.dart
import { appBar, button, esc, iconButton, input, table, TABLET } from './ds.js';

// ---------------------------------------------------------------- chữ (nguyên văn Dart)
export const GREETING = 'Chào bạn! Mình giúp bạn xem nhanh số liệu cửa hàng. Thử hỏi:';
export const SUGGESTIONS = [
  'Hôm nay bán được bao nhiêu?',
  'Hàng nào sắp hết, nên nhập bao nhiêu?',
  'Khách nào đang nợ?',
  '5 mặt hàng bán chạy tháng này?',
];
export const HINT = 'Hỏi về doanh thu, tồn kho, công nợ…';
export const LOCKED_HINT = 'Đã hết lượt hôm nay';
export const FOOTER = 'Trợ lý AI có thể hiểu nhầm câu hỏi. Số liệu trong bảng lấy trực tiếp từ dữ liệu cửa hàng.';
export const ERROR_TEXT = 'Có lỗi khi trả lời. Bạn thử lại nhé.';
export const OFFLINE_TEXT = 'Không có kết nối mạng.';
export const WAITING_TEXT = 'Đang trả lời…';
export const WAITING_SLOW_TEXT = 'Vẫn đang xử lý, chờ chút nhé…';
/** AskAssistantCubit.maxQuestionLength; AssistantFooter.remainingThreshold. */
export const MAX_QUESTION = 500;
export const REMAINING_THRESHOLD = 10;
/** Cột nội dung: ConstrainedBox(maxWidth: 840) cho cả danh sách lẫn ô nhập. */
export const COLUMN_MAX = 840;

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

/** int.round() của Dart: nửa ra xa số 0 (JS Math.round làm tròn nửa lên). */
const dartRound = (n) => Math.sign(n) * Math.round(Math.abs(n));

/** MoneyFormatter.formatMinorPlain: nhóm nghìn bằng dấu chấm. */
export function groupDigits(n) {
  const neg = n < 0;
  const digits = String(Math.abs(Math.trunc(n)));
  return `${neg ? '-' : ''}${digits.replace(/\B(?=(\d{3})+(?!\d))/g, '.')}`;
}

/** _decimal: tối đa 1 số lẻ, nghìn bằng dấu chấm, thập phân bằng dấu phẩy. */
function decimal(value) {
  const rounded = Number(value.toFixed(1));
  const whole = Math.trunc(rounded);
  const fraction = Math.round((Math.abs(rounded) - Math.abs(whole)) * 10);
  const sign = rounded < 0 ? '-' : '';
  const grouped = groupDigits(Math.abs(whole));
  return fraction === 0 ? `${sign}${grouped}` : `${sign}${grouped},${fraction}`;
}

/** formatAssistantCell(kind, value). kind: chu | tien | so | ngay | phan_tram (kiểu khác → chu như _kindFrom). */
export function formatCell(kind, value) {
  if (value == null) return '—';
  const num = typeof value === 'number' && Number.isFinite(value);
  switch (kind) {
    case 'tien': return num ? `${groupDigits(dartRound(value))}đ` : String(value);
    case 'so': return num ? decimal(value) : String(value);
    case 'phan_tram': return num ? `${decimal(value)}%` : String(value);
    case 'ngay': {
      const m = typeof value === 'string' ? /^(\d{4})-(\d{2})-(\d{2})/.exec(value) : null;
      return m ? `${m[3]}/${m[2]}/${m[1]}` : String(value);
    }
    default: return String(value);
  }
}

/** _isNumeric: tien / so / phan_tram canh phải. */
export const isNumeric = (kind) => kind === 'tien' || kind === 'so' || kind === 'phan_tram';

/** assistantOpenLocation: san_pham / khach_hang / don_ban → route; id rỗng hoặc loại lạ → null. */
export function openLocation(target) {
  if (!target) return null;
  const id = String(target.id ?? '').trim();
  if (!id) return null;
  const enc = encodeURIComponent(id);
  return { san_pham: `/products/items/${enc}/view`, khach_hang: `/partner/${enc}`, don_ban: `/sales/orders/${enc}` }[target.loai] ?? null;
}

/** _drawable: có cột và có dòng. */
export const drawable = (block) => block.columns.length > 0 && block.rows.length > 0;

/**
 * Màu bong bóng trả lời: loi → (dangerBg, danger); ok / tro_chuyen → (surface, borderDefault); còn lại → (warningBg, warning).
 * Viền màu chỉ khi là "vấn đề" (khác ok / tro_chuyen). Trạng thái lạ từ server → loi (_statusFrom).
 */
const STATUSES = ['ok', 'tro_chuyen', 'ngoai_pham_vi', 'chua_ho_tro', 'tu_choi', 'khong_quyen', 'loi', 'het_luot', 'ban'];
export function replyTone(status) {
  const s = STATUSES.includes(status) ? status : 'loi';
  if (s === 'ok' || s === 'tro_chuyen') return 'plain';
  return s === 'loi' ? 'danger' : 'warning';
}

/** AssistantFooter: hiện số lượt khi remaining != null và ≤ 10. */
export const showRemaining = (remaining) => remaining != null && remaining <= REMAINING_THRESHOLD;

/** Cubit: locked khi đã nhận het_luot (giữ khoá suốt phiên màn). */
export const isLocked = (messages) => messages.some((m) => m.kind === 'assistant' && m.reply.status === 'het_luot');

/** remaining = luot_con_lai của câu trả lời gần nhất có giá trị (reply.remaining ?? state.remaining). */
export function remainingOf(messages) {
  let r = null;
  for (const m of messages) if (m.kind === 'assistant' && m.reply.remaining != null) r = m.reply.remaining;
  return r;
}

/** Bề ngang khung bảng trong bong bóng: cột (≤ 840) − đệm ListView 2 × 16 − đệm bong bóng 2 × 12 − viền 2 × 1. */
export const tableWidth = (windowWidth) => Math.min(windowWidth, COLUMN_MAX) - 32 - 24 - 2;

// ---------------------------------------------------------------- vẽ

/** AssistantResultTable: tiêu đề headingH4 + khe 8, rồi lưới (≥ 600) hoặc thẻ. */
function resultTable(block, windowWidth) {
  const title = block.title ? `<h3 class="ai-table-title">${esc(block.title)}</h3>` : '';
  return `<div class="ai-result">${title}${tableWidth(windowWidth) >= TABLET ? grid(block) : cards(block)}</div>`;
}

/** _Grid: VTable, cột đầu flex 3, các cột khác flex 1; ô VText 1 dòng "…"; ô đầu chữ textBrand khi dòng mở được. onRowTap luôn gắn. */
function grid(block) {
  return table({
    headers: block.columns.map((c) => ({ title: c.name, numeric: isNumeric(c.kind) })),
    widths: block.columns.map((_, i) => (i === 0 ? 3 : 1)),
    tappable: true,
    rows: block.rows.map((row) => block.columns.map((c, i) => {
      const brand = i === 0 && openLocation(row.open) != null;
      return `<span class="ai-cell${brand ? ' is-brand' : ''}">${esc(formatCell(c.kind, row.cells[c.key]))}</span>`;
    })),
  });
}

/** _Cards / _RowCard: thẻ đệm 12, bo 12, viền borderBrand khi mở được (không thì borderDefault); khe 8 sau MỖI thẻ (cả thẻ cuối). */
function cards(block) {
  const [first, ...rest] = block.columns;
  return `<div class="ai-cards">${block.rows.map((row) => {
    const open = openLocation(row.open) != null;
    const lines = rest.map((c) => `<div class="ai-card__line"><span class="ai-card__name">${esc(c.name)}</span><span class="ai-card__value">${esc(formatCell(c.kind, row.cells[c.key]))}</span></div>`).join('');
    const tag = open ? 'button type="button"' : 'div';
    return `<${tag} class="ai-card${open ? ' is-open' : ''}"><b class="ai-card__title">${esc(formatCell(first.kind, row.cells[first.key]))}</b>${lines}</${open ? 'button' : 'div'}>`;
  }).join('')}</div>`;
}

/** _Bubble: đệm 12, viền 1, bo 12. */
const bubble = (tone, inner, { full = false } = {}) => `<div class="ai-bubble ai-bubble--${tone}${full ? ' is-full' : ''}">${inner}</div>`;

function message(m, { isLast, windowWidth }) {
  switch (m.kind) {
    case 'user':
      // ConstrainedBox(maxWidth: MediaQuery.width × 0.8) — theo CỬA SỔ, không theo cột 840.
      return `<div class="ai-row ai-row--end"><div class="ai-user" style="max-width:${windowWidth * 0.8}px">${esc(m.text)}</div></div>`;
    case 'error':
      return `<div class="ai-row">${bubble('danger', `<p class="ai-text">${esc(m.offline ? OFFLINE_TEXT : ERROR_TEXT)}</p>${isLast ? `<div class="ai-retry">${button('Thử lại', { variant: 'secondary' })}</div>` : ''}`)}</div>`;
    case 'assistant': {
      const blocks = m.reply.blocks.filter(drawable);
      const inner = `${m.reply.text ? `<p class="ai-text">${esc(m.reply.text)}</p>` : ''}${blocks.map((b) => resultTable(b, windowWidth)).join('')}`;
      // Không có bảng → Align trái (co theo chữ); có bảng → bong bóng hết bề ngang cột.
      return blocks.length ? bubble(replyTone(m.reply.status), inner, { full: true }) : `<div class="ai-row">${bubble(replyTone(m.reply.status), inner)}</div>`;
    }
    default: return '';
  }
}

/** AssistantSuggestions: lời chào textSecondary, khe 12, 4 nút pill hết bề ngang (Container có alignment ⇒ giãn đủ chỗ), khe 8 dưới mỗi nút. */
function suggestions() {
  return `<div class="ai-suggest"><p class="ai-greeting">${esc(GREETING)}</p>${SUGGESTIONS.map((s) => `<button type="button" class="ai-chip" data-ask="${esc(s)}">${esc(s)}</button>`).join('')}</div>`;
}

/**
 * Màn /ask. v: { width, messages, waiting, slow, draft, focused }.
 * messages: [{ kind: 'user', text } | { kind: 'assistant', reply: { status, text, blocks, remaining } } | { kind: 'error', offline }].
 */
export function askPage(v) {
  const { messages, waiting } = v;
  const locked = isLocked(messages);
  const remaining = remainingOf(messages);
  const list = [
    messages.length === 0 && !waiting ? suggestions() : '',
    ...messages.map((m, i) => `<div class="ai-item">${message(m, { isLast: i === messages.length - 1, windowWidth: v.width })}</div>`),
    waiting ? `<div class="ai-row">${bubble('plain', `<p class="ai-text ai-text--secondary">${esc(v.slow ? WAITING_SLOW_TEXT : WAITING_TEXT)}</p>`)}</div>` : '',
  ].join('');
  const footer = `${showRemaining(remaining) ? `<p class="ai-footer__remaining">Còn ${remaining} câu hỏi hôm nay.</p>` : ''}<p class="ai-footer__note">${esc(FOOTER)}</p>`;
  return `<div class="ai-page">
    ${appBar('Hỏi Mosaic Retail')}
    <div class="ai-scroll" data-scroll-end><div class="ai-col ai-list">${list}</div></div>
    <div class="ai-bottom"><div class="ai-col">
      <div class="ai-composer">${input({ value: v.draft || '', hint: locked ? LOCKED_HINT : HINT, disabled: locked, focused: v.focused })}${iconButton('send', 'Gửi', { disabled: waiting || locked })}</div>
      <div class="ai-footer">${footer}</div>
    </div></div>
  </div>`;
}
