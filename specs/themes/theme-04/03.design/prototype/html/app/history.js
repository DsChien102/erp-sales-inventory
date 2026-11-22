// PR-10 Lịch sử giá riêng (+ sheet "Bộ lọc lịch sử", "Chi tiết hoạt động").
// Nguồn Flutter (apps/erp/lib/features/pricing/):
//   presentation/pages/pricing_history_page.dart
//   presentation/widgets/{price_rule_history_view, price_rule_history_timeline_tile, price_rule_history_states,
//     price_rule_history_filter_sheet, price_rule_activity_detail_sheet, price_rule_history_shared}.dart
//   logic/price_rule_history_{cubit,state}.dart (hasSensitivePermission không bao giờ bị đặt false)
// Tìm, chip "Sửa giá", bộ lọc và đảo thứ tự đều lọc CỤC BỘ trên các dòng đã tải (không gọi máy chủ).
import { appBar, badge, button, card, chip, esc, icon, iconBox, scaffold, searchBar, skeleton } from './ds.js';
import { ACTIVITIES, DETAIL, money } from './data.js';
import { ACT_LABEL, ACT_LABEL_DETAIL, SOURCE_LABEL, actIcon, summaryLine } from './detail.js';

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

/** _filtered: chip "Sửa giá" giữ cả "Tạo giá riêng"; tìm theo nhãn hoạt động + tên người (không theo lý do, giá); đảo thứ tự = đảo danh sách đã tải. */
export function filterActivities(items, { quick = 'all', type = 'Tất cả', actor = 'Tất cả', time = 'Tất cả', q = '', newestFirst = true, today = TODAY } = {}) {
  const query = q.trim().toLowerCase();
  let list = items.filter((a) => {
    if (quick === 'priceEdit' && !(a.type === 'updated' || a.type === 'created')) return false;
    if (type !== 'Tất cả' && ACT_LABEL[a.type] !== type) return false;
    if (actor !== 'Tất cả' && a.actor !== actor) return false;
    if (time !== 'Tất cả' && !withinDays(a.at, Number(time.split(' ')[0]), today)) return false;
    if (!query) return true;
    return ACT_LABEL[a.type].toLowerCase().includes(query) || a.actor.toLowerCase().includes(query);
  });
  if (!newestFirst) list = [...list].reverse();
  return list;
}

/** Ngày "hôm nay" của dữ liệu mẫu (matchesTimeRange dùng DateTime.now()). */
export const TODAY = new Date(2026, 10, 22, 9, 41);
/** matchesTimeRange: createdAt sau (bây giờ − n ngày). at dạng "dd/MM/yyyy HH:mm". */
export function withinDays(at, days, today = TODAY) {
  const [d, m, rest] = at.split('/');
  const [y, hm] = rest.split(' ');
  const [h, min] = hm.split(':');
  const t = new Date(Number(y), Number(m) - 1, Number(d), Number(h), Number(min));
  return t > new Date(today.getTime() - days * 86400000);
}

/** VDateTime.parseAndFormatCalendarDate: null / rỗng → "Không giới hạn" (kể cả ngày bắt đầu); "2026-07-01" → "01/07/2026". */
export function calendarDate(s) {
  if (!s) return 'Không giới hạn';
  const [y, m, d] = s.split('-');
  return `${d.padStart(2, '0')}/${m.padStart(2, '0')}/${y}`;
}

/** _formatDiffMoney (sheet hoạt động): null → "-" (gạch ngắn; nơi khác dùng "—"); có dấu +/- đúng. */
export const diffMoney = (n) => (n == null ? '-' : n > 0 ? `+${money(n)}` : n < 0 ? `-${money(-n)}` : money(n));

// ---------------------------------------------------------------- trạng thái

export function historyState(state) {
  const base = { kind: 'loaded', items: ACTIVITIES, quick: 'all', type: 'Tất cả', actor: 'Tất cả', time: 'Tất cả', q: '', newestFirst: true, hasMore: false, rule: DETAIL };
  switch (state) {
    case 'loading': return { ...base, kind: 'loading' };
    case 'quick-price': return { ...base, quick: 'priceEdit' };
    case 'search': return { ...base, q: 'đức' };
    case 'filtered': return { ...base, type: 'Sửa giá', time: '90 ngày gần đây' };
    case 'filtered-actor': return { ...base, actor: 'Trần Minh Đức' };
    case 'oldest': return { ...base, newestFirst: false };
    case 'more': return { ...base, hasMore: true, scrollEnd: true };
    case 'empty': return { ...base, items: [] };
    case 'no-result': return { ...base, q: 'giá sàn' };
    case 'error': return { ...base, kind: 'error' };
    case 'no-permission': return { ...base, kind: 'no-permission' };
    case 'long-name': return { ...base, rule: { ...DETAIL, product: 'Dầu tắm trị ve rận cho chó mèo 250ml', unit: 'Chai' } };
    default: return base;
  }
}

// ---------------------------------------------------------------- PR-10

/** Trạng thái hệ thống / rỗng của lịch sử: VIconBox tròn 64 (icon 32) | khe 16 | H4 w700 | khe 4 | bodySmall xám | khe 24 | nút viền. Đệm 24. */
function systemState({ ic, tone, title, desc, btn = '' }) {
  return `<div class="t4-hstate">${iconBox({ ic, size: 64, iconSize: 32, circle: true, cls: `t4-ibox--tone-${tone}` })}
    <i class="t4-gap" style="height:16px"></i><p class="t4-h4b t4-center">${esc(title)}</p><i class="t4-gap" style="height:4px"></i>
    <p class="t4-small2 t4-center">${esc(desc)}</p><i class="t4-gap" style="height:24px"></i>${btn ? button(btn, { variant: 'secondary' }) : ''}</div>`;
}

/** Khung tải: đệm 16; VSkeleton ∞×44, khe 16, ∞×32, khe 16, 4 × (∞×80, khe 12). Không có ô tìm thật. */
const historySkeleton = () => `<div class="t4-hskel">${skeleton(44, { radius: 4 })}${skeleton(32, { radius: 4 })}<div class="t4-hskel__list">${skeleton(80, { radius: 4 }).repeat(4)}</div></div>`;

/**
 * PriceRuleHistoryTimelineTile: cột trái VIconBox tròn 36 + gạch dọc 2 borderDefault (trừ dòng cuối) | khe 8 |
 * VCard đệm 16 (đệm dưới 12): [nhãn H4 w700 / "người · nguồn" bodySmall] [badge nguồn + ngày giờ bodySmall muted] + › 16; khe 4; tóm tắt.
 * Nguồn hiện hai lần (dòng người và badge).
 */
function timelineTile(a, last) {
  const srcTone = { manual: 'info', excelImport: 'success', salesOrder: 'info', migration: 'neutral' }[a.source];
  return `<div class="t4-tl">
    <div class="t4-tl__rail">${actIcon(a, 36, 18)}${last ? '' : '<i class="t4-tl__line"></i>'}</div>
    <div class="t4-tl__body">${card(`<div class="t4-tl__head">
        <div class="t4-tl__title"><b>${esc(ACT_LABEL[a.type])}</b><span>${esc(a.actor)} · ${esc(SOURCE_LABEL[a.source])}</span></div>
        <div class="t4-tl__meta">${badge(SOURCE_LABEL[a.source], { tone: srcTone, small: true })}<span>${esc(a.at)}</span></div>
        <i class="t4-tl__chev">${icon('chevronRight')}</i>
      </div>${summaryLine(a) ? `<i class="t4-gap" style="height:4px"></i>${summaryLine(a)}` : ''}`)}</div>
  </div>`;
}

/** Nút lọc lịch sử: như danh sách nhưng có chấm tròn 10 (viền trắng 1,5) ở góc thay vì số; sáng cả khi chỉ bật chip "Sửa giá". */
const filterDot = (on) => `<button type="button" class="t4-filterbtn${on ? ' is-active' : ''}" aria-label="Lọc lịch sử thay đổi">${icon('tune')}${on ? '<i class="t4-filterbtn__dot"></i>' : ''}</button>`;

export function historyBody(s) {
  if (s.kind === 'no-permission') return systemState({ ic: 'lock', tone: 'neutral', title: 'Bạn không có quyền xem lịch sử giá riêng', desc: 'Vui lòng liên hệ quản trị viên để được cấp quyền.', btn: 'Quay lại' });
  if (s.kind === 'error') return systemState({ ic: 'error', tone: 'danger', title: 'Không tải được lịch sử', desc: 'Không thể tải dữ liệu. Vui lòng thử lại.', btn: 'Thử lại' });
  if (s.kind === 'loading') return historySkeleton();
  const filtered = filterActivities(s.items, { quick: s.quick, type: s.type, actor: s.actor, time: s.time, q: s.q, newestFirst: s.newestFirst });
  const isFiltered = s.type !== 'Tất cả' || s.actor !== 'Tất cả' || s.time !== 'Tất cả';
  const anyFilter = isFiltered || s.quick !== 'all';
  // Hàng chip đang lọc: chỉ loại + thời gian (không có người thực hiện) — chip chữ "… ✕", rồi "Xóa lọc" chữ đỏ.
  const tags = isFiltered ? `<div class="t4-htags">${s.type !== 'Tất cả' ? chip(`${s.type} ✕`, { tone: 'primary' }) : ''}${s.time !== 'Tất cả' ? chip(`${s.time} ✕`, { tone: 'primary' }) : ''}${button('Xóa lọc', { variant: 'tertiary', size: 'small', fg: 'danger' })}</div>` : '';
  const ctx = `<div class="t4-hctx"><b>${esc(s.rule.customer)}</b><span>${esc(s.rule.product)} · ${esc(s.rule.unit)}</span></div>`;
  let list;
  if (!filtered.length) {
    list = anyFilter || s.q
      ? systemState({ ic: 'search', tone: 'neutral', title: 'Không tìm thấy lịch sử phù hợp', desc: 'Thử điều chỉnh bộ lọc hoặc xóa bớt điều kiện lọc.', btn: 'Đặt lại bộ lọc' })
      : systemState({ ic: 'history', tone: 'neutral', title: 'Chưa có lịch sử thay đổi', desc: 'Giá riêng này chưa phát sinh hoạt động nào.', btn: 'Quay lại chi tiết' });
    list = `<div class="t4-hlist t4-hlist--empty">${list}</div>`;
  } else {
    const more = s.hasMore ? `<div class="t4-loadmore">${skeleton(40, { w: '40px', radius: 4 })}</div>` : '';
    list = `<div class="t4-hlist"${s.scrollEnd ? ' data-scroll-end' : ''}>${filtered.map((a, i) => timelineTile(a, i === filtered.length - 1)).join('')}${more}</div>`;
  }
  return `<div class="t4-list">
    <div class="t4-searchrow">${searchBar({ value: s.q, hint: 'Tìm theo hành động, người thực hiện...', clear: !!s.q })}${filterDot(anyFilter)}</div>
    ${ctx}
    <div class="t4-chiprow">${chip('Tất cả', { tone: s.quick === 'all' ? 'primary' : 'neutral' })}${chip('Sửa giá', { tone: s.quick === 'priceEdit' ? 'primary' : 'neutral' })}</div>
    ${tags}
    <div class="t4-hsort"><span>${filtered.length} kết quả</span><button type="button">${s.newestFirst ? 'Mới nhất trước' : 'Cũ nhất trước'} ${icon('chevronDown')}</button></div>
    ${list}
  </div>`;
}

export function historyPage(state, v) {
  const s = historyState(state);
  const known = s.kind !== 'loading';
  return scaffold({
    appbar: appBar('Lịch sử giá riêng', { subtitle: known ? s.rule.customer : '', back: true }),
    body: historyBody(s),
    placeWidth: v.width, windowWidth: v.width,
  });
}

// ---------------------------------------------------------------- sheet

/** _openFilterSheet: {'Tất cả', …tên người}.toList()..sort() — sắp theo mã ký tự nên "Tất cả" (chữ "ấ") rơi về CUỐI. */
export const actorOptions = (items) => ['Tất cả', ...new Set(items.map((a) => a.actor))].sort();

/**
 * PriceRuleHistoryFilterSheet: sheet không tiêu đề; tự vẽ "Bộ lọc lịch sử" H3 w700 (không gạch, không ×); 3 nhóm (nhãn bodyDefault w600 + khe 4 + chip).
 * Chip theo selected (khác bộ lọc danh sách: có đổi màu). "Người thực hiện" lấy từ các dòng đã tải; "Thời gian" có 90 ngày (danh sách chỉ 7 / 30).
 */
export function historyFilterSheet({ type = 'Tất cả', actor = 'Tất cả', time = 'Tất cả' } = {}) {
  const actors = actorOptions(ACTIVITIES);
  const group = (title, opts, sel) => `<p class="t4-hf-title">${esc(title)}</p><div class="t4-fs-wrap">${opts.map((o) => chip(o, { tone: o === sel ? 'primary' : 'neutral' })).join('')}</div>`;
  return `<div class="t4-sheetpad t4-sheetpad--top8">
    <p class="t4-h3b">Bộ lọc lịch sử</p><i class="t4-gap" style="height:16px"></i>
    ${group('Loại hoạt động', ['Tất cả', 'Tạo giá riêng', 'Sửa giá', 'Tắt', 'Bật lại'], type)}<i class="t4-gap" style="height:16px"></i>
    ${group('Người thực hiện', actors, actor)}<i class="t4-gap" style="height:16px"></i>
    ${group('Thời gian', ['Tất cả', '7 ngày gần đây', '30 ngày gần đây', '90 ngày gần đây'], time)}<i class="t4-gap" style="height:24px"></i>
    <div class="t4-row2">${button('Đặt lại', { variant: 'secondary', full: true })}${button('Áp dụng', { full: true })}</div>
  </div>`;
}

/**
 * PriceRuleActivityDetailSheet: tiêu đề "Chi tiết hoạt động" + gạch. Thẻ đầu (VIconBox tròn 44 + nhãn chi tiết w700 / "ngày · người" caption / "Nguồn: …" caption muted);
 * thẻ "So sánh trước / sau" (bảng Trường | Trước | Sau, flex 3 / 4 / 4; luôn đủ 4 hàng kể cả không đổi); thẻ "Ghi chú / lý do" (không có → nghiêng);
 * "Xem chi tiết giá riêng >" nút viền đầy ngang (chữ ">" trong nhãn). Không có quyền nhạy cảm → banner "Quyền hạn chế" (không bao giờ xảy ra).
 */
export function activitySheet(a) {
  const drow = (label, before, after, hi = false) => `<div class="t4-diff"><span>${esc(label)}</span><b>${esc(before)}</b><b class="${hi ? 'is-hi' : ''}">${esc(after)}</b></div>`;
  const reason = a.reason ? `<p class="t4-small2">${esc(a.reason)}</p>` : `<p class="t4-small2"${a.reason == null ? ' style="font-style:italic"' : ''}>Không có ghi chú</p>`;
  return `<div class="t4-sheetpad t4-sheetpad--top8">
    ${card(`<div class="t4-acthead">${actIcon(a, 44, 22)}<div><b>${esc(ACT_LABEL_DETAIL[a.type])}</b><span>${esc(a.at)} · ${esc(a.actor)}</span><span class="is-muted">Nguồn: ${esc(SOURCE_LABEL[a.source])}</span></div></div>`)}
    <i class="t4-gap" style="height:16px"></i>
    ${card(`<b class="t4-cardtitle">So sánh trước / sau</b><i class="t4-gap" style="height:8px"></i><hr class="t4-divider"><i class="t4-gap" style="height:8px"></i>
      <div class="t4-diff t4-diff--head"><span>Trường</span><span>Trước</span><span>Sau</span></div><i class="t4-gap" style="height:4px"></i>
      ${drow('Giá riêng', a.oldPrice != null ? money(a.oldPrice) : '—', a.newPrice != null ? money(a.newPrice) : '—', true)}<i class="t4-gap" style="height:4px"></i>
      ${drow('Ngày bắt đầu', calendarDate(a.oldFrom), calendarDate(a.newFrom))}<i class="t4-gap" style="height:4px"></i>
      ${drow('Ngày kết thúc', calendarDate(a.oldTo), calendarDate(a.newTo), a.oldTo !== a.newTo)}<i class="t4-gap" style="height:4px"></i>
      ${drow('Chênh lệch giá sàn', diffMoney(a.oldFloorDiff), diffMoney(a.newFloorDiff), a.newFloorDiff != null)}`)}
    <i class="t4-gap" style="height:16px"></i>
    ${card(`<b class="t4-cardtitle">Ghi chú / lý do</b><i class="t4-gap" style="height:4px"></i>${reason}`)}
    <i class="t4-gap" style="height:24px"></i>
    ${button('Xem chi tiết giá riêng >', { variant: 'secondary', full: true })}
  </div>`;
}

