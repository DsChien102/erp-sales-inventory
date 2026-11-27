// PT-11 Chuyển thành tổ chức — bố cục iPhone "Cùng mẫu form hồ sơ" (người dùng chọn qua /impeccable live, 2026-11-27).
// Khung lớp mfm- (form-mobile.css): đầu trang ‹ + tiêu đề theo bước + tên cá nhân; thanh tiến độ 3 đoạn + "Bước N/3 · …";
// bước 1: thẻ "Thông tin tổ chức (mới)" (Bắt buộc, 7 ô) + thẻ "Người liên hệ chính"; bước 2: Trước → Sau + người liên hệ chính + banner giữ lịch sử.
// Chân dính: "Cần có để tiếp tục: …" (bước 1, chỉ ô còn thiếu) + "Huỷ" | "Tiếp" / "Quay lại" | "Xác nhận".
// Chữ, lỗi, điều kiện theo transform.js. CSS: styles/transform-mobile.css (tiền tố mtf-).
import { icon } from '../shared/icons.js';
import { banner, button, esc, field, initials, input, select } from './ds.js';
import { ORG_DRAFT, PERSON, blockedState, stepOneErrors, transformTitle } from './transform.js';

const EMPTY = { type: '', name: '', shortName: '', intlName: '', phone: '', email: '', taxCode: '' };
const grp = (t, tag, body, cls = '') => `<section class="mfm-grp"><div class="mfm-gh"><h2>${t}</h2>${tag}</div><div class="mfm-card ${cls}">${body}</div></section>`;
const tf = (label, value, hint, { req = false, err = null } = {}) => field({ label, required: req, error: err, control: input({ value, hint, invalid: !!err }) });
const person = (name, sub) => `<div class="mtf-person"><span class="mtf-av" aria-hidden="true">${esc(initials(name))}</span><div><b>${esc(name)}</b><small>${esc(sub)}</small></div></div>`;

function progress(step, label) {
  return `<div class="mtf-prog"><div class="mtf-bars" aria-hidden="true">${[1, 2, 3].map((n) => `<i class="${n <= step ? 'is-on' : ''}"></i>`).join('')}</div><p><b>Bước ${step}/3</b> · ${esc(label)}</p></div>`;
}

function stepOne(d, errors, showBanner) {
  const e = errors || {};
  const form = [
    field({ label: 'Loại tổ chức', required: true, error: e.type, control: select({ value: d.type, hint: 'Chọn loại tổ chức' }).replace('class="t3-select', `class="t3-select${e.type ? ' is-invalid' : ''}`) }),
    tf('Tên tổ chức', d.name, 'Nhập tên tổ chức', { req: true, err: e.name }),
    tf('Tên viết tắt', d.shortName, 'Nhập tên viết tắt'),
    tf('Tên quốc tế', d.intlName, 'Nhập tên quốc tế'),
    tf('SĐT tổ chức', d.phone, 'Nhập số điện thoại', { req: true, err: e.phone }),
    tf('Email tổ chức', d.email, 'Nhập email'),
    tf('MST', d.taxCode, 'Nhập MST (10 số, 12 số hoặc 10-3 số)'),
  ].join('');
  const contact = `<p class="mtf-note">Cá nhân hiện tại sẽ được lưu làm người liên hệ chính</p>${person(PERSON.name, PERSON.phone)}`;
  const miss = [!d.type && 'loại tổ chức', !d.name.trim() && 'tên tổ chức', !d.phone.trim() && 'SĐT tổ chức'].filter(Boolean);
  const need = miss.length ? `<p class="mfm-need">${icon('info')}<span>Cần có để tiếp tục: ${esc(miss.join(', '))}</span></p>` : '';
  return {
    progress: progress(1, 'Thông tin tổ chức'),
    body: `${grp('Thông tin tổ chức (mới)', '<span class="mfm-tag is-req">Bắt buộc</span>', form)}${grp('Người liên hệ chính', '', contact)}${showBanner ? banner('warning', 'Không thể chuyển đổi khi thiếu thông tin bắt buộc hoặc dữ liệu bị trùng.') : ''}`,
    foot: `${need}<div class="mfm-btns">${button('Huỷ', { variant: 'secondary', full: true })}${button('Tiếp', { full: true, disabled: showBanner })}</div>`,
  };
}

function stepTwo(d, error) {
  // Thẻ "Sau khi chuyển" (tổ chức): ô icon toà nhà nền trắng viền brand — chữ tắt xanh trên nền xanh nhạt bị chìm.
  const card = (name, sub, phone, cls = '') => `<div class="mtf-pcard ${cls}"><span class="mtf-av mtf-av--lg${cls ? ' mtf-av--org' : ''}" aria-hidden="true">${cls ? icon('building') : esc(initials(name))}</span><div><b>${esc(name)}</b><small>${esc(sub)}</small><strong>${esc(phone)}</strong></div></div>`;
  return {
    progress: progress(2, 'Xem trước'),
    body: `${error ? banner('warning', error) : ''}
      <section class="mfm-grp"><div class="mfm-gh"><h2>Trước khi chuyển</h2></div>${card(PERSON.name, `Cá nhân  •  ${PERSON.roles}`, PERSON.phone)}</section>
      <i class="mtf-arrow" aria-hidden="true">${icon('arrowDown')}</i>
      <section class="mfm-grp"><div class="mfm-gh"><h2>Sau khi chuyển</h2></div>${card(d.name, `Tổ chức  •  ${PERSON.roles}`, d.phone, 'is-after')}</section>
      <section class="mfm-grp"><div class="mfm-gh"><h2>Người liên hệ chính (từ hồ sơ cá nhân)</h2></div>${card(PERSON.name, 'Người liên hệ chính', PERSON.phone)}</section>
      ${banner('info', 'Lịch sử giao dịch và dữ liệu liên quan sẽ được giữ nguyên.')}`,
    foot: `<div class="mfm-btns">${button('Quay lại', { variant: 'secondary', full: true })}${button('Xác nhận', { full: true })}</div>`,
  };
}

export function transformPageMobile(state) {
  let step = 1; let blocked = null; let v;
  if (state === 'blocked-permission' || state === 'blocked-stale') blocked = state;
  else if (state === 'step1') v = stepOne(EMPTY, null, false);
  else if (state === 'step1-errors') v = stepOne({ ...EMPTY, phone: '0912 34' }, stepOneErrors({ ...EMPTY, phone: '0912 34' }), true);
  else if (state === 'step1-duplicate') v = stepOne(ORG_DRAFT, { phone: 'Số điện thoại đã tồn tại trên hồ sơ khác.' }, false);
  else if (state === 'step1-filled') v = stepOne(ORG_DRAFT, null, false);
  else { step = 2; v = stepTwo(ORG_DRAFT, state === 'step2-error' ? 'Không thể chuyển đổi hồ sơ. Vui lòng thử lại.' : null); }
  const head = `<header class="mfm-bar"><button type="button" class="mfm-back" aria-label="Quay lại">${icon('chevronLeft')}</button><div class="mfm-titles"><h1>${esc(transformTitle({ blocked, step }))}</h1><p>${esc(PERSON.name)}</p></div></header>`;
  if (blocked) return `<div class="t3-page mfm">${head}<div class="t3-form">${blockedState(blocked === 'blocked-permission' ? 'no-permission' : 'stale')}</div></div>`;
  // Đang chuyển (chọn qua /impeccable live 2026-11-27): không phủ đen cả màn; nội dung mờ, không bấm được; "Quay lại" tắt,
  // nút chính quay vòng "Đang chuyển…" (lệch đặc tả: lớp phủ textPrimary đặc che thân).
  if (state === 'submitting') {
    v.foot = `<div class="mfm-btns">${button('Quay lại', { variant: 'secondary', full: true, disabled: true })}${button('Đang chuyển…', { full: true, loading: true, cls: 'mtf-busy' })}</div>`;
    return `<div class="t3-page mfm">${head}${v.progress}<div class="mfm-scroll mtf-dim" aria-busy="true">${v.body}</div><footer class="mfm-foot">${v.foot}</footer></div>`;
  }
  return `<div class="t3-page mfm">${head}${v.progress}<div class="mfm-scroll">${v.body}</div><footer class="mfm-foot">${v.foot}</footer></div>`;
}
