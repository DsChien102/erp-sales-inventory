// PT-11 Chuyển thành tổ chức — bố cục web ≥ 1024 "Form + cột phải" (người dùng chọn qua /impeccable live, 2026-11-27).
// Cùng mẫu PT-05 / PT-09 web (form-web.css): đầu trang "‹ Hồ sơ KH & NCC" + tiêu đề theo bước + "Tên · Cá nhân • Vai trò"; thanh 3 bước ngang.
// Bước 1: thẻ form 2 cột | cột phải = thẻ người liên hệ chính + "Cần có để tiếp tục" (✓) + "Tiếp" / "Huỷ".
// Bước 2: thẻ xem trước Trước → Sau + người liên hệ chính + banner | cột phải = "Xác nhận" / "Quay lại". iPhone giữ transformPage.
import { icon } from '../shared/icons.js';
import { banner, button, centerLoading, esc, field, initials, input, select } from './ds.js';
import { ORG_DRAFT, PERSON, blockedState, stepOneErrors, transformTitle } from './transform.js';

const av = (n, s = 44) => `<span class="wtf-av" style="width:${s}px;height:${s}px">${esc(initials(n))}</span>`;

function steps(cur) {
  const li = (n, l) => `<li class="${n < cur ? 'is-done' : n === cur ? 'is-on' : ''}"><span>${n < cur ? icon('check') : n}</span>${esc(l)}</li>`;
  return `<div class="wtf-stepbar"><ol class="wtf-steps">${li(1, 'Thông tin tổ chức')}<li class="wtf-steps__line" aria-hidden="true"></li>${li(2, 'Xem trước')}<li class="wtf-steps__line" aria-hidden="true"></li>${li(3, 'Xác nhận')}</ol></div>`;
}

const head = (title) => `<header class="wtf-head"><nav class="wcn-crumb"><button type="button">${icon('chevronLeft')}Hồ sơ KH &amp; NCC</button></nav>
  <h1>${esc(title)}</h1><p>${esc(PERSON.name)} · Cá nhân • ${esc(PERSON.roles)}</p></header>`;

function stepOne(d, e, showBanner) {
  const f = (label, ctrl, { req = false, err = null } = {}) => field({ label, required: req, error: err, control: ctrl });
  const grid = `<div class="wfm-grid">
    ${f('Loại tổ chức', select({ value: d.type, hint: 'Chọn loại tổ chức' }).replace('class="t3-select', `class="t3-select${e.type ? ' is-invalid' : ''}`), { req: true, err: e.type })}
    ${f('Tên tổ chức', input({ value: d.name, hint: 'Nhập tên tổ chức', invalid: !!e.name }), { req: true, err: e.name })}
    ${f('Tên viết tắt', input({ value: d.shortName, hint: 'Nhập tên viết tắt' }))}
    ${f('Tên quốc tế', input({ value: d.intlName, hint: 'Nhập tên quốc tế' }))}
    ${f('SĐT tổ chức', input({ value: d.phone, hint: 'Nhập số điện thoại', invalid: !!e.phone }), { req: true, err: e.phone })}
    ${f('Email tổ chức', input({ value: d.email, hint: 'Nhập email' }))}
    <div class="wfm-wide">${f('MST', input({ value: d.taxCode, hint: 'Nhập MST (10 số, 12 số hoặc 10-3 số)' }))}</div></div>`;
  const need = [['Loại tổ chức', !!d.type && !e.type], ['Tên tổ chức', !!d.name.trim() && !e.name], ['SĐT tổ chức', !!d.phone.trim() && !e.phone]];
  const warn = showBanner ? banner('warning', 'Không thể chuyển đổi khi thiếu thông tin bắt buộc hoặc dữ liệu bị trùng.') : '';
  return `<div class="wfm-cols"><div class="wfm-stack">${warn}<section class="wfm-card"><header class="wfm-card__head"><h2>Thông tin tổ chức (mới)</h2></header>${grid}</section></div>
    <aside class="wfm-side wtf-side">
      <section class="wfm-sum wtf-contact"><h3>Cá nhân hiện tại sẽ được lưu làm người liên hệ chính</h3><div>${av(PERSON.name)}<span><b>${esc(PERSON.name)}</b><small class="wcn-mono">${esc(PERSON.phone)}</small></span></div></section>
      <section class="wfm-sum"><h3>Cần có để tiếp tục</h3><ul class="wfm-check">${need.map(([l, ok]) => `<li class="${ok ? 'is-ok' : ''}"><i>${ok ? icon('check') : ''}</i>${esc(l)}</li>`).join('')}</ul>
        <div class="wfm-sum__acts">${button('Tiếp', { full: true, disabled: showBanner }).replace('</span></button>', `</span>${icon('arrowRight')}</button>`)}${button('Huỷ', { variant: 'tertiary', full: true })}</div></section>
    </aside></div>`;
}

/** Bước 2 — Trước → Sau nằm ngang + cột phải "Sẽ thay đổi" (chọn qua /impeccable live, 2026-11-27). */
function stepTwo(d, error) {
  const pc = (name, sub, phone, cls = '') => `<div class="w2-pc ${cls}">${av(name, 48)}<span><b>${esc(name)}</b><small>${esc(sub)}</small><small class="wcn-mono">${esc(phone)}</small></span></div>`;
  const changes = [['Loại hồ sơ', 'Cá nhân', 'Tổ chức'], ['Tên', PERSON.name, d.name], ['SĐT chính', PERSON.phone, d.phone], ['Người liên hệ chính', '', PERSON.name]];
  return `<div class="wfm-cols"><div class="wfm-stack">${error ? banner('warning', error) : ''}<section class="wfm-card">
      <div class="w2-row"><div><p class="wtf-cap">Trước khi chuyển</p>${pc(PERSON.name, `Cá nhân  •  ${PERSON.roles}`, PERSON.phone)}</div><span class="w2-arrow">${icon('arrowRight')}</span><div><p class="wtf-cap">Sau khi chuyển</p>${pc(d.name, `Tổ chức  •  ${PERSON.roles}`, d.phone, 'is-new')}</div></div>
      <p class="wtf-cap w2-mt">Người liên hệ chính (từ hồ sơ cá nhân)</p>${pc(PERSON.name, 'Người liên hệ chính', PERSON.phone)}</section>
      ${banner('info', 'Lịch sử giao dịch và dữ liệu liên quan sẽ được giữ nguyên.')}</div>
    <aside class="wfm-side"><section class="wfm-sum"><h3>Sẽ thay đổi</h3><ul class="w2-list">${changes.map(([k, a, b]) => `<li><span>${esc(k)}</span><b>${a ? `<s>${esc(a)}</s> → ` : ''}${esc(b)}</b></li>`).join('')}</ul>
      <div class="wfm-sum__acts">${button('Xác nhận', { full: true })}${button('Quay lại', { variant: 'tertiary', full: true })}</div></section></aside></div>`;
}

export function transformPageWeb(state) {
  const EMPTY = { type: '', name: '', shortName: '', intlName: '', phone: '', email: '', taxCode: '' };
  if (state === 'blocked-permission' || state === 'blocked-stale') {
    return `<div class="t3-page wcn">${head('Chuyển thành tổ chức')}<div class="t3-form">${blockedState(state === 'blocked-permission' ? 'no-permission' : 'stale')}</div></div>`;
  }
  let step = 1; let body;
  if (state === 'step1') body = stepOne(EMPTY, {}, false);
  else if (state === 'step1-errors') { const d = { ...EMPTY, phone: '0912 34' }; body = stepOne(d, stepOneErrors(d), true); }
  else if (state === 'step1-duplicate') body = stepOne(ORG_DRAFT, { phone: 'Số điện thoại đã tồn tại trên hồ sơ khác.' }, false);
  else if (state === 'step1-filled') body = stepOne(ORG_DRAFT, {}, false);
  else { step = 2; body = stepTwo(ORG_DRAFT, state === 'step2-error' ? 'Không thể chuyển đổi hồ sơ. Vui lòng thử lại.' : null); }
  const submit = state === 'submitting' ? `<div class="t3-tsubmit">${centerLoading({ material: true })}</div>` : '';
  return `<div class="t3-page wcn wtf">${head(transformTitle({ blocked: null, step }))}${steps(step)}<div class="t3-body wfm t3-rel"><div class="wfm-scroll">${body}</div>${submit}</div></div>`;
}
