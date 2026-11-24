import { TODAY, sg13Cases } from './data.js';
import { planReturnSettlement } from './allocate.js';
import { formatVnd, dueLabel } from './format.js';
import { k7CheckMark } from './icon.js';
import { esc, page, dueBadge, btn, sheet, dialog } from './ui.js';

const CASE_OF = { 'all-selected': 'base', 'one-unchecked': 'base', 'none-selected': 'base', confirm: 'base', stale: 'base', mixed: 'mixed', 'source-has-debt': 'source-has-debt', 'no-other-debt': 'no-other-debt' };
const SELECTED = { 'one-unchecked': ['DH-003'], 'none-selected': [] };

export function sg13Model(state, selectedOverride) {
  const c = sg13Cases[CASE_OF[state]];
  const selectedIds = selectedOverride ?? SELECTED[state] ?? c.candidates.map((x) => x.id);
  const plan = planReturnSettlement({ entitled: c.entitled, sourceOutstanding: c.sourceOutstanding, candidates: c.candidates, selectedIds });
  return { c, selectedIds, plan };
}

const bare = (n) => formatVnd(n).replace(' ₫', '');

function offsetRow(c, cand, amountMinor, on) {
  return `<button class="rc-offset" type="button" role="checkbox" aria-checked="${on}" data-offset="${esc(cand.id)}">${k7CheckMark(on)}<span class="rc-offset__main"><span class="rc-offset__title">${esc(cand.code)} · còn nợ ${formatVnd(cand.outstandingMinor)}</span>${dueBadge(dueLabel(cand.dueDate, TODAY))}</span><span class="rc-offset__amt rc-money${amountMinor === 0 ? ' is-zero' : ''}">Trừ ${bare(amountMinor)}</span></button>`;
}

export function sg13Body(m) {
  const { c, plan, selectedIds } = m;
  const diff = c.returnValue - c.exchangeValue;
  const seg = '<div class="ds-segmented" role="group" aria-label="Phương thức hoàn"><button type="button" class="ds-segment is-selected" aria-pressed="true">Tiền mặt</button><button type="button" class="ds-segment" aria-pressed="false">CK</button></div>';
  const offsetSum = plan.offsets.reduce((x, o) => x + o.amountMinor, 0);
  const segs = [['own', plan.reduceOwnDebt], ['offset', offsetSum], ['refund', plan.refund]].filter(([, v]) => v > 0);
  const bar = segs.length ? `<div class="rs-bar" aria-hidden="true">${segs.map(([k, v]) => `<span class="rs-bar__${k}" style="flex:${v}"></span>`).join('')}</div>` : '';
  const flowRow = (k, label, value, note = '') => `<div class="rs-flow__row" role="listitem"><span class="rs-dot rs-dot--${k}"></span><span>${label}${note ? `<small class="rs-flow__note">${note}</small>` : ''}</span><b class="rc-money">${value}</b></div>`;
  return `<p class="rc-sub rc-sub--pad">${esc(c.orderCode)} · ${esc(c.customer)}</p>
  <div class="rs-hero"><span class="rs-hero__label">Khách được hưởng</span><span class="rs-hero__amt rc-money">${formatVnd(c.entitled)}</span><span class="rs-hero__meta">Chênh lệch −${formatVnd(diff)} · Hàng trả ${bare(c.returnValue)} · Hàng đổi ${bare(c.exchangeValue)}</span></div>
  <div data-region="sg13-plan">
  <div class="rs-flow" role="list" aria-label="Tiền được chia">${bar}
    ${plan.reduceOwnDebt > 0 ? flowRow('own', 'Giảm nợ đơn này', formatVnd(plan.reduceOwnDebt), 'Trừ vào nợ của chính đơn này') : ''}
    ${plan.showOffsetBlock ? flowRow('offset', 'Cấn trừ vào đơn khác', formatVnd(offsetSum)) : ''}
    ${flowRow('refund', 'Hoàn cho khách', formatVnd(plan.refund))}
    ${plan.refund > 0 ? `<div class="rc-method"><span class="rc-method__label">Phương thức hoàn</span>${seg}</div>` : ''}
  </div>
  ${plan.showOffsetBlock ? `<h4 class="rc-section">CẤN TRỪ VÀO ĐƠN KHÁC</h4><p class="rc-note rc-note--tight rc-note--pad">Trừ vào nợ đơn khác của khách thay vì hoàn tiền.</p>${c.candidates.map((cd) => offsetRow(c, cd, plan.offsets.find((o) => o.id === cd.id).amountMinor, selectedIds.includes(cd.id))).join('')}` : ''}
  </div>`;
}

function confirmBody(m) {
  const { c, plan } = m;
  const rows = [];
  if (plan.reduceOwnDebt > 0) rows.push(`Giảm nợ đơn này ${formatVnd(plan.reduceOwnDebt)}`);
  for (const o of plan.offsets.filter((x) => x.amountMinor > 0)) rows.push(`Cấn trừ ${formatVnd(o.amountMinor)} vào đơn ${esc(c.candidates.find((x) => x.id === o.id).code)}`);
  if (plan.refund > 0) rows.push(`Hoàn ${formatVnd(plan.refund)} cho khách`);
  return `<ul class="rc-confirm-list">${rows.map((r) => `<li>${r}</li>`).join('')}</ul>`;
}

export function renderSg13(state, device, opts = {}) {
  const m = sg13Model(state, opts.selectedIds);
  const view = page({ title: 'Quyết toán đổi/trả', back: device === 'iphone', device, body: `<div class="rc-scroll rc-sg13">${sg13Body(m)}</div>`, footer: btn('Xác nhận đổi/trả', { full: true, attrs: 'data-confirm' }) });
  const wrapped = device === 'web' ? `<div class="rc-center">${view}</div>` : view;
  let over = '';
  if (state === 'confirm') over = sheet({ title: 'Xác nhận đổi/trả?', body: confirmBody(m), actions: `${btn('Quay lại', { kind: 'secondary' })}${btn('Xác nhận đổi/trả')}`, device });
  if (state === 'stale') over = dialog({ title: 'Công nợ của khách vừa thay đổi. Hãy tải lại quyết toán.', actions: btn('Tải lại') });
  return wrapped + over;
}
