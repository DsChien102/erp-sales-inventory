// PT-05 Tạo / chỉnh sửa hồ sơ — bố cục iPhone "Một trang cuộn" (người dùng chọn qua /impeccable live, 2026-11-27).
// Giống hướng web (form-web.js): mọi mục mở sẵn thành thẻ trắng, nhãn "Bắt buộc" / "Tùy chọn" cạnh tiêu đề nhóm; ô nhập một cột.
// Bỏ thẻ khoá "1. Loại hồ sơ" (đưa lên dưới tiêu đề: "Loại hồ sơ: Cá nhân"), bỏ số mục, bỏ đóng / mở từng mục và hàng "Bỏ qua" | "Tiếp".
// "Địa chỉ giao hàng" và "Ghi chú" thu gọn ở cuối (mở khi đang chọn hoặc đã có dữ liệu). Chân dính: dòng "Cần có để lưu: …"
// (chỉ các mục còn thiếu) + "Hủy" | "Lưu & Xem" / "Lưu thay đổi", chừa vùng an toàn đáy 34. Nút ← là chevron 44.
// Chữ, nhãn, gợi ý, lỗi lấy đúng form.js. CSS: styles/form-mobile.css (tiền tố mfm-).
import { icon } from '../shared/icons.js';
import { banner, button, centerLoading, checkbox, chip, esc, field, input, select, textArea } from './ds.js';
import { canSubmit, filterProvinces, formTitle, invoiceWarning, sectionTitle, sections } from './form.js';
import { CAN_THO_WARDS } from './data.js';

const tf = (label, value, hint, { req = false, err = null } = {}) => field({ label, required: req, error: err, control: input({ value, hint, invalid: !!err }) });
const ta = (label, value, hint, { req = false } = {}) => field({ label, required: req, control: textArea({ value, hint, minLines: 3 }) });

/** _AdministrativeUnitTouchField (giống form.js) kèm nhãn ô thường. */
function unit(label, value, hint, ic, enabled = true) {
  const trail = value ? `<span class="t3-unit__clear" aria-label="Xóa lựa chọn">${icon('close')}</span>` : `<i class="t3-unit__chev">${icon('chevronDown')}</i>`;
  return `<div class="t3-field"><span class="t3-label">${esc(label)}</span><button type="button" class="t3-unit${value ? ' has-value' : ''}${enabled ? '' : ' is-disabled'}"${enabled ? '' : ' disabled'}><i class="t3-unit__lead">${icon(ic)}</i><span class="t3-unit__text">${esc(value || hint)}</span>${trail}</button></div>`;
}

const BODY = {
  role: (s) => `<p class="mfm-desc">Chọn vai trò giao dịch của hồ sơ này.</p><div class="t3-wrap">${chip('Khách hàng', { tone: s.roles.includes('customer') ? 'primary' : 'neutral' })}${chip('Nhà cung cấp', { tone: s.roles.includes('supplier') ? 'primary' : 'neutral' })}</div>
    ${s.errors.roles ? `<p class="t3-small t3-small--danger mfm-err">${esc(s.errors.roles)}</p>` : ''}`,
  main: (s) => {
    const e = s.errors;
    return s.type === 'person'
      ? [tf('Danh xưng', s.personTitle, 'Nhập danh xưng'), tf('Họ và tên', s.fullName, 'Nhập họ và tên', { req: true, err: e.fullName }),
        tf('Tên thường gọi', s.nickname, 'Nhập tên thường gọi'), tf('SĐT chính', s.phone, 'Nhập SĐT chính', { req: true, err: e.phone }),
        tf('SĐT phụ', s.secondaryPhone, 'Nhập SĐT phụ', { err: e.secondaryPhone }), tf('Email', s.email, 'Nhập email', { err: e.email })].join('')
      : [field({ label: 'Loại tổ chức', control: select({ value: s.organizationTypeLabel, hint: 'Chọn loại tổ chức' }) }),
        tf('Tên tổ chức', s.organizationName, 'Nhập tên tổ chức', { req: true, err: e.organizationName }),
        tf('Tên viết tắt', s.shortName, 'Nhập tên viết tắt'), tf('Tên quốc tế', s.internationalName, 'Nhập tên quốc tế'),
        tf('SĐT chính', s.phone, 'Nhập SĐT chính', { req: true, err: e.phone }), tf('Email', s.email, 'Nhập email', { err: e.email })].join('');
  },
  primaryContact: (s) => {
    const e = s.errors;
    const fields = s.primaryContactEnabled ? [
      tf('Danh xưng', s.primaryContactTitle, 'Nhập danh xưng'), tf('Họ và tên', s.primaryContactName, 'Nhập họ và tên', { req: true, err: e.primaryContactName }),
      tf('SĐT chính', s.primaryContactPhone, 'Nhập SĐT chính', { req: true, err: e.primaryContactPhone }), tf('SĐT phụ', '', 'Nhập SĐT phụ'),
      tf('Email', s.primaryContactEmail, 'Nhập email', { err: e.primaryContactEmail })].join('') : '';
    return `${checkbox('Thêm người liên hệ chính', s.primaryContactEnabled)}${fields}`;
  },
  invoice: (s) => {
    const org = s.type === 'organization';
    const warn = invoiceWarning(s);
    return `${warn ? banner('warning', warn) : ''}${[
      tf('Mã số thuế', s.taxCode, 'Nhập MST (10 số, 12 số hoặc 10-3 số)', { req: org, err: s.errors.taxCode }),
      tf('Tên xuất hóa đơn', s.invoiceName, 'Nhập tên xuất hóa đơn', { req: org }),
      tf('Email nhận hóa đơn', s.invoiceEmail, 'Nhập email nhận hóa đơn', { err: s.errors.invoiceEmail }),
      ta('Địa chỉ xuất hóa đơn', s.invoiceAddress, 'Nhập địa chỉ xuất hóa đơn', { req: org })].join('')}`;
  },
  delivery: (s) => [
    unit('Tỉnh / Thành phố', s.deliveryProvince, 'Chọn tỉnh / thành phố', 'mapPin'),
    unit('Xã / Phường', s.deliveryCommune, s.deliveryProvince ? 'Chọn xã / phường' : 'Chọn tỉnh / thành phố trước', 'building', !!s.deliveryProvince),
    ta('Địa chỉ chi tiết', s.deliveryAddress, 'Số nhà, tên đường...')].join(''),
  note: (s) => `<div class="t3-field"><span class="t3-label">Ghi chú nội bộ</span><div class="t3-note">${textArea({ value: s.note, minLines: 4 })}<span class="t3-note__count">${s.note.length}/500</span></div></div>`,
};

/** Nhãn nhóm: vai trò + thông tin chính bắt buộc; người liên hệ, giao hàng, ghi chú tùy chọn; hóa đơn tùy chọn với cá nhân (tổ chức: không nhãn, có * từng ô). */
function tag(s, sec) {
  if (sec === 'role' || sec === 'main') return '<span class="mfm-tag is-req">Bắt buộc</span>';
  if (sec === 'invoice' && s.type === 'organization') return '';
  return '<span class="mfm-tag">Tùy chọn</span>';
}
const name = (s, sec) => sectionTitle(sec, s.type, s.edit).replace(/^\d+\.\s*/, '');
const COLLAPSIBLE = new Set(['delivery', 'note']);
const hasData = (s, sec) => (sec === 'delivery' ? !!(s.deliveryProvince || s.deliveryAddress.trim()) : !!s.note.trim());

function group(s, sec) {
  if (COLLAPSIBLE.has(sec) && s.active !== sec && !hasData(s, sec)) {
    return `<button type="button" class="mfm-more" aria-expanded="false"><span><b>${esc(name(s, sec))}</b><small>Tùy chọn</small></span>${icon('chevronDown')}</button>`;
  }
  return `<section class="mfm-grp"><div class="mfm-gh"><h2>${esc(name(s, sec))}</h2>${tag(s, sec)}</div><div class="mfm-card">${BODY[sec](s)}</div></section>`;
}

/** Dòng nhắc trên hàng nút: còn thiếu gì để lưu; sửa mà chưa đổi → "Chưa có thay đổi để lưu."; đủ → không hiện. */
function needLine(s) {
  if (s.blocked) return '';
  if (s.edit && !s.dirty) return `<p class="mfm-need">${icon('info')}<span>Chưa có thay đổi để lưu.</span></p>`;
  const person = s.type === 'person';
  const miss = [
    !s.roles.length && 'vai trò',
    !(person ? s.fullName : s.organizationName).trim() && (person ? 'họ và tên' : 'tên tổ chức'),
    !s.phone.trim() && 'SĐT chính',
  ].filter(Boolean);
  return miss.length ? `<p class="mfm-need">${icon('info')}<span>Cần có để lưu: ${esc(miss.join(', '))}</span></p>` : '';
}

/** PartnerCreatePage khổ iPhone. */
export function formPageMobile(s) {
  const head = `<header class="mfm-bar"><button type="button" class="mfm-back" aria-label="Quay lại">${icon('chevronLeft')}</button><div class="mfm-titles"><h1>${esc(formTitle(s))}</h1>${s.loading ? '' : `<p>Loại hồ sơ: ${s.type === 'person' ? 'Cá nhân' : 'Tổ chức'}</p>`}</div></header>`;
  if (s.loading) return `<div class="t3-page mfm">${head}<div class="t3-body">${centerLoading({ material: true })}</div></div>`;
  const canPress = canSubmit(s) && !s.blocked && !s.submitting;
  const secs = sections(s.type, s.edit);
  const open = secs.filter((sec) => !(COLLAPSIBLE.has(sec) && s.active !== sec && !hasData(s, sec))).map((sec) => group(s, sec)).join('');
  const folded = secs.filter((sec) => COLLAPSIBLE.has(sec) && s.active !== sec && !hasData(s, sec)).map((sec) => group(s, sec)).join('');
  return `<div class="t3-page mfm">${head}
    <div class="mfm-scroll"${s.scrollTo ? ` data-scroll-to="${s.scrollTo}"` : ''}>${s.generalError ? banner('error', s.generalError) : ''}${open}${folded ? `<div class="mfm-folded">${folded}</div>` : ''}</div>
    <footer class="mfm-foot">${needLine(s)}<div class="mfm-btns">${button('Hủy', { variant: 'secondary', full: true, disabled: s.submitting })}${button(s.edit ? 'Lưu thay đổi' : 'Lưu & Xem', { full: true, loading: s.submitting, disabled: !canPress })}</div></footer>
  </div>`;
}

/**
 * PT-06 Khu vực hành chính khổ iPhone "Hai tab + danh sách gọn" (chọn qua /impeccable live 2026-11-27). Cao 75% màn.
 * Đầu sheet tiêu đề 18/700 + nút Đóng 44; ô tìm; hai tab gạch chân "Tỉnh / thành phố" | "Xã / phường" (tab xã tắt tới khi có tỉnh;
 * tab đã chọn hiện tên dưới nhãn); danh sách dòng 52 không icon, kẻ mảnh, "N xã/phường" canh phải; dòng đang chọn nền brand + ✓.
 * Thứ tự và lọc giữ đúng filterProvinces (form.js). p: { tab, province, ward, query }.
 */
export function pickerSheetMobile(p, screenHeight) {
  const height = Math.round(screenHeight * 0.75);
  const hint = p.tab === 0 ? 'Tìm kiếm tỉnh, thành phố...' : `Tìm kiếm xã, phường tại ${p.province || ''}...`;
  const clear = p.query ? `<button type="button" class="mpk-clear" aria-label="Xóa từ khóa">${icon('close')}</button>` : '';
  const tab = (label, value, active, enabled) => `<button type="button" role="tab" aria-selected="${active}"${enabled ? '' : ' disabled'}><span>${esc(label)}</span>${value ? `<small>${esc(value)}</small>` : ''}</button>`;
  const row = (name, sub, sel) => `<li><button type="button" class="mpk-row${sel ? ' is-selected' : ''}"${sel ? ' aria-current="true"' : ''}><span>${esc(name)}</span>${sub ? `<small>${esc(sub)}</small>` : ''}${sel ? `<i>${icon('check')}</i>` : ''}</button></li>`;
  let list;
  if (p.tab === 0) {
    const items = filterProvinces(p.query);
    list = items.length
      ? `<ul class="mpk-list">${items.map(([n, c]) => row(n, `${c} xã/phường`, n === p.province)).join('')}</ul>`
      : `<div class="mpk-empty">${icon('searchOff')}<b>Không tìm thấy tỉnh / thành phố</b>${p.query ? `<span>Không có kết quả nào khớp với "${esc(p.query)}"</span>` : ''}</div>`;
  } else {
    list = `<ul class="mpk-list">${CAN_THO_WARDS.map((n) => row(n, '', n === p.ward)).join('')}</ul>`;
  }
  return `<div class="mpk" style="height:${height}px">
    <header class="mpk-head"><h2>Khu vực hành chính</h2><button type="button" class="mpk-x" aria-label="Đóng">${icon('close')}</button></header>
    <div class="mpk-searchrow"><label class="mpk-search">${icon('search')}<input type="search" value="${esc(p.query || '')}" placeholder="${esc(hint)}" aria-label="${esc(hint)}">${clear}</label></div>
    <div class="mpk-tabs" role="tablist">${tab('Tỉnh / thành phố', p.province, p.tab === 0, true)}${tab('Xã / phường', p.ward, p.tab === 1, !!p.province)}</div>
    ${list}
  </div>`;
}
