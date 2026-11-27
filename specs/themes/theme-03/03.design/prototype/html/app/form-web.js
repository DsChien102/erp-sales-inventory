// PT-05 Tạo / chỉnh sửa hồ sơ — bố cục web ≥ 1024 "Form + cột tóm tắt" (người dùng chọn qua /impeccable live, 2026-11-27).
// Mọi mục mở sẵn thành thẻ trắng, ô nhập xếp 2 cột; cột phải 300 dính: tên hồ sơ + vai trò, "Cần có để lưu" (✓ khi đã đủ),
// nút "Lưu & Xem" / "Lưu thay đổi" + "Hủy". Lệch so với Flutter: bỏ đóng / mở từng mục và hàng "Bỏ qua" | "Tiếp".
// Chữ, nhãn, gợi ý, lỗi lấy đúng form.js. iPhone giữ formPage của form.js. CSS: styles/form-web.css (tiền tố wfm-).
import { icon } from '../shared/icons.js';
import {
  appBar, banner, button, centerLoading, checkbox, chip, esc, field, iconBox, input, select, textArea,
} from './ds.js';
import { canSubmit, filterProvinces, formTitle, invoiceWarning, sectionTitle, sections } from './form.js';
import { CAN_THO_WARDS } from './data.js';

const tf = (label, value, hint, { req = false, err = null } = {}) => field({ label, required: req, error: err, control: input({ value, hint, invalid: !!err }) });
const ta = (label, value, hint, { req = false } = {}) => field({ label, required: req, control: textArea({ value, hint, minLines: 3 }) });
const grid = (...cells) => `<div class="wfm-grid">${cells.join('')}</div>`;
const wide = (x) => `<div class="wfm-wide">${x}</div>`;

function unit(label, value, hint, ic, enabled = true) {
  const trail = value ? `<span class="t3-unit__clear" aria-label="Xóa lựa chọn">${icon('close')}</span>` : `<i class="t3-unit__chev">${icon('chevronDown')}</i>`;
  return `<div class="t3-field"><span class="t3-label">${esc(label)}</span><button type="button" class="t3-unit${value ? ' has-value' : ''}${enabled ? '' : ' is-disabled'}"${enabled ? '' : ' disabled'}><i class="t3-unit__lead">${icon(ic)}</i><span class="t3-unit__text">${esc(value || hint)}</span>${trail}</button></div>`;
}

// ---------------------------------------------------------------- thân từng mục

const BODY = {
  role: (s) => `<div class="t3-wrap">${chip('Khách hàng', { tone: s.roles.includes('customer') ? 'primary' : 'neutral' })}${chip('Nhà cung cấp', { tone: s.roles.includes('supplier') ? 'primary' : 'neutral' })}</div>
    ${s.errors.roles ? `<p class="t3-small t3-small--danger wfm-err">${esc(s.errors.roles)}</p>` : ''}`,
  main: (s) => {
    const e = s.errors;
    return s.type === 'person'
      ? grid(tf('Danh xưng', s.personTitle, 'Nhập danh xưng'), tf('Họ và tên', s.fullName, 'Nhập họ và tên', { req: true, err: e.fullName }),
        tf('Tên thường gọi', s.nickname, 'Nhập tên thường gọi'), tf('SĐT chính', s.phone, 'Nhập SĐT chính', { req: true, err: e.phone }),
        tf('SĐT phụ', s.secondaryPhone, 'Nhập SĐT phụ', { err: e.secondaryPhone }), tf('Email', s.email, 'Nhập email', { err: e.email }))
      : grid(field({ label: 'Loại tổ chức', control: select({ value: s.organizationTypeLabel, hint: 'Chọn loại tổ chức' }) }),
        tf('Tên tổ chức', s.organizationName, 'Nhập tên tổ chức', { req: true, err: e.organizationName }),
        tf('Tên viết tắt', s.shortName, 'Nhập tên viết tắt'), tf('Tên quốc tế', s.internationalName, 'Nhập tên quốc tế'),
        tf('SĐT chính', s.phone, 'Nhập SĐT chính', { req: true, err: e.phone }), tf('Email', s.email, 'Nhập email', { err: e.email }));
  },
  primaryContact: (s) => {
    const e = s.errors;
    const fields = s.primaryContactEnabled ? `<div class="wfm-sub">${grid(
      tf('Danh xưng', s.primaryContactTitle, 'Nhập danh xưng'), tf('Họ và tên', s.primaryContactName, 'Nhập họ và tên', { req: true, err: e.primaryContactName }),
      tf('SĐT chính', s.primaryContactPhone, 'Nhập SĐT chính', { req: true, err: e.primaryContactPhone }), tf('SĐT phụ', '', 'Nhập SĐT phụ'),
      wide(tf('Email', s.primaryContactEmail, 'Nhập email', { err: e.primaryContactEmail })),
    )}</div>` : '';
    return `${checkbox('Thêm người liên hệ chính', s.primaryContactEnabled)}${fields}`;
  },
  invoice: (s) => {
    const org = s.type === 'organization';
    const warn = invoiceWarning(s);
    return `${warn ? `<div class="wfm-warn">${banner('warning', warn)}</div>` : ''}${grid(
      tf('Mã số thuế', s.taxCode, 'Nhập MST (10 số, 12 số hoặc 10-3 số)', { req: org, err: s.errors.taxCode }),
      tf('Tên xuất hóa đơn', s.invoiceName, 'Nhập tên xuất hóa đơn', { req: org }),
      wide(tf('Email nhận hóa đơn', s.invoiceEmail, 'Nhập email nhận hóa đơn', { err: s.errors.invoiceEmail })),
      wide(ta('Địa chỉ xuất hóa đơn', s.invoiceAddress, 'Nhập địa chỉ xuất hóa đơn', { req: org })),
    )}`;
  },
  delivery: (s) => grid(
    unit('Tỉnh / Thành phố', s.deliveryProvince, 'Chọn tỉnh / thành phố', 'mapPin'),
    unit('Xã / Phường', s.deliveryCommune, s.deliveryProvince ? 'Chọn xã / phường' : 'Chọn tỉnh / thành phố trước', 'building', !!s.deliveryProvince),
    wide(ta('Địa chỉ chi tiết', s.deliveryAddress, 'Số nhà, tên đường...')),
  ),
  note: (s) => `<div class="t3-field"><span class="t3-label">Ghi chú nội bộ</span><div class="t3-note">${textArea({ value: s.note, minLines: 4 })}<span class="t3-note__count">${s.note.length}/500</span></div></div>`,
};
const DESC = { role: 'Chọn vai trò giao dịch của hồ sơ này.' };
const REQ = new Set(['role', 'main']);
const OPT = new Set(['primaryContact', 'delivery', 'note']);

function card(s, sec) {
  const [n, ...rest] = sectionTitle(sec, s.type, s.edit).split('. ');
  const tag = REQ.has(sec) ? '<span class="wfm-req">Bắt buộc</span>' : OPT.has(sec) ? '<span class="wfm-opt">Tùy chọn</span>' : '';
  return `<section class="wfm-card"><header class="wfm-card__head"><h2><span class="wfm-n">${esc(n)}</span>${esc(rest.join('. '))}</h2>${tag}</header>
    ${DESC[sec] ? `<p class="wfm-desc">${esc(DESC[sec])}</p>` : ''}${BODY[sec](s)}</section>`;
}

// ---------------------------------------------------------------- cột tóm tắt

const roleText = (r) => (r.length === 2 ? 'KH & NCC' : r.includes('customer') ? 'Khách hàng' : r.includes('supplier') ? 'Nhà cung cấp' : 'Chưa có vai trò');

function summary(s) {
  const person = s.type === 'person';
  const name = (person ? s.fullName : s.organizationName).trim() || (person ? 'Cá nhân mới' : 'Tổ chức mới');
  const need = [
    ['Vai trò giao dịch', s.roles.length > 0],
    [person ? 'Họ và tên' : 'Tên tổ chức', !!(person ? s.fullName : s.organizationName).trim()],
    ['SĐT chính', !!s.phone.trim()],
  ];
  const canPress = canSubmit(s) && !s.blocked && !s.submitting;
  const unchanged = s.edit && !s.dirty ? '<p class="wfm-sum__note">Chưa có thay đổi để lưu.</p>' : '';
  return `<aside class="wfm-side"><div class="wfm-sum">
    <div class="wfm-sum__who"><span class="wfm-av">${icon(person ? 'user' : 'building')}</span><div><b>${esc(name)}</b><small>${esc(roleText(s.roles))}</small></div></div>
    <h3>Cần có để lưu</h3>
    <ul class="wfm-check">${need.map(([l, ok]) => `<li class="${ok ? 'is-ok' : ''}"><i>${ok ? icon('check') : ''}</i>${esc(l)}</li>`).join('')}</ul>
    ${unchanged}
    <div class="wfm-sum__acts">${button(s.edit ? 'Lưu thay đổi' : 'Lưu & Xem', { full: true, loading: s.submitting, disabled: !canPress })}${button('Hủy', { variant: 'tertiary', full: true, disabled: s.submitting })}</div>
  </div></aside>`;
}

// ---------------------------------------------------------------- trang

export function formPageWeb(s) {
  const leading = `<span class="t3-iconbtn40">${iconBox({ ic: 'arrowLeft', size: 40, iconSize: 20, cls: 't3-ibox--clear' })}</span>`;
  const head = appBar(formTitle(s), { leading });
  if (s.loading) return `<div class="t3-page">${head}<div class="t3-body">${centerLoading({ material: true })}</div></div>`;
  const locked = `<section class="wfm-card wfm-card--lock"><header class="wfm-card__head"><h2><span class="wfm-n">1</span>Loại hồ sơ</h2><span class="wfm-locktag">${icon('lock')}${s.type === 'person' ? 'Cá nhân' : 'Tổ chức'}</span></header></section>`;
  const err = s.generalError ? banner('error', s.generalError) : '';
  const cards = sections(s.type, s.edit).map((sec) => card(s, sec)).join('');
  return `<div class="t3-page">${head}
    <div class="t3-body wfm"><div class="wfm-scroll"${s.scrollTo ? ` data-scroll-to="${s.scrollTo}"` : ''}><div class="wfm-cols">
      <div class="wfm-stack">${err}${locked}${cards}</div>
      ${summary(s)}
    </div></div></div>
  </div>`;
}

// ---------------------------------------------------------------- PT-04 Trùng hồ sơ (hộp thoại web) — so sánh "Bạn đang nhập" | "Hồ sơ đã có"
// (chọn qua /impeccable live, 2026-11-27). Hộp 600; trường trùng tô đỏ + nhãn "Trùng"; nút canh phải.
// Thêm so với Flutter: cột "Bạn đang nhập" (lấy từ form đang nhập). iPhone giữ duplicateSheet (form.js).
const HIT_KEY = { SĐT: 'phone', Tên: 'name', Email: 'email' };

export function duplicateDialogWeb(level, matches, s) {
  const exact = level === 'exact';
  const person = s.type === 'person';
  const mine = [['name', person ? 'Họ và tên' : 'Tên tổ chức', person ? s.fullName : s.organizationName], ['phone', 'SĐT chính', s.phone], ['email', 'Email', s.email]];
  const hits = new Set(matches.map((m) => HIT_KEY[m.value.split(':')[0]]));
  const kv = (label, value, hit, mono = false) => `<div class="wdp-kv${hit ? ' is-hit' : ''}"><dt>${esc(label)}</dt><dd>${value ? (mono ? `<span class="wdp-mono">${esc(value)}</span>` : esc(value)) : '<span class="wdp-dash">—</span>'}${hit ? `<em>${icon('alert')}Trùng</em>` : ''}</dd></div>`;
  const left = mine.map(([k, l, v]) => kv(l, v, hits.has(k), k === 'phone')).join('');
  const have = matches.map((m) => {
    const [f, ...rest] = m.value.split(': ');
    const key = HIT_KEY[f];
    const label = key === 'name' ? (m.type === 'person' ? 'Họ và tên' : 'Tên tổ chức') : key === 'phone' ? 'SĐT chính' : f;
    return `<div class="wdp-rec"><b>${icon(m.type === 'person' ? 'user' : 'building')}${esc(m.name)}</b><dl>${kv(label, rest.join(': '), true, key === 'phone')}</dl></div>`;
  }).join('');
  const btns = exact
    ? `${button('Quay lại', { variant: 'secondary' })}${button('Đi đến hồ sơ')}`
    : `${button('Xem chi tiết', { variant: 'secondary' })}${button('Tiếp tục tạo mới')}`;
  const title = exact ? 'Trùng khớp hoàn toàn' : 'Có thể là hồ sơ trùng';
  return `<div class="sh-scrim sh-scrim--dialog"><section class="t3-dialog wdp" role="dialog" aria-modal="true" aria-label="${title}">
    <header class="wdp-head"><span class="wdp-ic${exact ? '' : ' wdp-ic--warn'}">${icon('alert')}</span><div><h2>${title}</h2>
      <p>${exact ? 'Đã tồn tại hồ sơ trùng khớp hoàn toàn. Không thể tạo mới.' : 'Tìm thấy các hồ sơ có thông tin tương tự. Vui lòng kiểm tra trước khi tạo mới.'}</p></div>
      <button type="button" class="wpc-x" aria-label="Đóng">${icon('close')}</button></header>
    <div class="wdp-cmp">
      <section><h3>Bạn đang nhập</h3><dl>${left}</dl></section>
      <section class="wdp-cmp__have"><h3>Hồ sơ đã có${matches.length > 1 ? ` (${matches.length})` : ''}</h3>${have}</section>
    </div>
    <footer class="wdp-foot">${btns}</footer>
  </section></div>`;
}

// ---------------------------------------------------------------- PT-06 Khu vực hành chính (hộp thoại web) — lưới 2 cột gọn
// (chọn qua /impeccable live, 2026-11-27). Hộp 640, cao 600; một nút Đóng (sửa lỗi hai nút chồng); ô tìm + hai bước trên cùng;
// danh sách tỉnh / xã xếp 2 cột. p: { tab, province, ward, query }. iPhone giữ pickerSheet (form.js).
export function pickerDialogWeb(p) {
  const step = (n, title, sub, { active, done, enabled = true }) => `<button type="button" role="tab" aria-selected="${active}"${enabled ? '' : ' disabled'} class="${done && !active ? 'is-done' : ''}"><span>${done && !active ? icon('check') : n}</span><b>${esc(title)}</b>${sub ? `<small>${esc(sub)}</small>` : ''}</button>`;
  const hint = p.tab === 0 ? 'Tìm kiếm tỉnh, thành phố...' : `Tìm kiếm xã, phường tại ${p.province || ''}...`;
  const cell = (name, sub, sel) => `<li><button type="button" class="wpk-cell${sel ? ' is-selected' : ''}"${sel ? ' aria-current="true"' : ''}><span>${esc(name)}</span>${sub ? `<small>${esc(sub)}</small>` : ''}${sel ? `<i>${icon('checkCircle')}</i>` : ''}</button></li>`;
  let list;
  if (p.tab === 0) {
    const items = filterProvinces(p.query);
    list = items.length
      ? `<ul class="wpk-grid">${items.map(([n, c]) => cell(n, `${c} xã/phường`, n === p.province)).join('')}</ul>`
      : `<div class="wpk-empty">${icon('searchOff')}<b>Không tìm thấy tỉnh / thành phố</b>${p.query ? `<span>Không có kết quả nào khớp với "${esc(p.query)}"</span>` : ''}</div>`;
  } else {
    list = `<ul class="wpk-grid">${CAN_THO_WARDS.map((n) => cell(n, '', n === p.ward)).join('')}</ul>`;
  }
  const clear = p.query ? `<button type="button" class="wpk-clear" aria-label="Xóa từ khóa">${icon('close')}</button>` : '';
  return `<div class="sh-scrim sh-scrim--dialog"><section class="t3-dialog wpk" role="dialog" aria-modal="true" aria-label="Khu vực hành chính">
    <header class="wpk-head"><h2>Khu vực hành chính</h2><button type="button" class="wpc-x" aria-label="Đóng">${icon('close')}</button></header>
    <div class="wpk-top">
      <label class="wpk-search">${icon('search')}<input type="search" value="${esc(p.query || '')}" placeholder="${esc(hint)}" aria-label="${esc(hint)}">${clear}</label>
      <div class="wpk-steps" role="tablist">${step(1, 'Tỉnh / thành phố', p.province, { active: p.tab === 0, done: !!p.province })}${icon('chevronRight')}${step(2, 'Xã / phường', p.ward, { active: p.tab === 1, done: !!p.ward, enabled: !!p.province })}</div>
    </div>
    ${list}
  </section></div>`;
}
