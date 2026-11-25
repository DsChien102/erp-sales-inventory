// Bố cục WEB (khung ≥ 840), chọn qua impeccable live 2026-11-24. iPhone giữ bản chép Flutter ở ../org.js; trạng thái mẫu, hàm kiểm, sheet dùng chung lấy từ đó.
import { icon } from '../../shared/icons.js';
import { LEGAL, LEGAL_NOTICE, ORG } from '../admin-data.js';
import { adaptiveSheet, button, centerLoading, confirmDialog, esc, field, iconButton, input, select, toast, vScaffold } from '../ds.js';
import { BAR_H, DISCARD, duplicateSheet, EDIT_STATES, info, LEGAL_STATES, loadFailed, orgUnauthorized, PROFILE_STATES, twoBar, warnBox } from '../org.js';
import { unitSection } from '../signup.js';

/**
 * Hồ sơ tổ chức (chọn qua impeccable live 2026-11-24): đầu trang (ô toà nhà 48 + tên H2 + email · điện thoại) → khối "Thông tin tổ chức"
 * (nút bút chì "Chỉnh sửa thông tin tổ chức") → khối "Hồ sơ pháp lý": chưa có → hộp vàng + "Thêm hồ sơ pháp lý"; đã có → 4 dòng + nút bút chì.
 * Thao tác nằm ngay ở từng khối, không còn nút "Thao tác ⌃" / sheet; bỏ banner info (trùng ý hộp vàng).
 */
function profileBody(hasLegal) {
  const orgRows = [info('Tên hiển thị', ORG.name), info('Điện thoại', ORG.phone), info('Email', ORG.email), info('Địa chỉ', ORG.address)].join('');
  const legal = hasLegal
    ? `<div class="t1-stack12">${[info('Loại chủ thể', LEGAL.entityType), info('Tên pháp lý', LEGAL.legalName), info('Mã số thuế', LEGAL.taxCode), info('Địa chỉ đăng ký', LEGAL.registeredAddress)].join('')}</div>`
    : `${warnBox(LEGAL_NOTICE.title, LEGAL_NOTICE.message)}<div class="t1-gap-md"></div>${button('Thêm hồ sơ pháp lý', { full: true })}`;
  const sec = (title, action, inner) => `<section class="t1-orgsec"><div class="t1-orgsec__head"><h2>${esc(title)}</h2>${action}</div>${inner}</section>`;
  return `<div class="t1-orgp">
    <div class="t1-orgp__head"><div class="t1-mailbox" aria-hidden="true">${icon('building')}</div><div><h1>${esc(ORG.name)}</h1><p>${esc(ORG.email)} · ${esc(ORG.phone)}</p></div></div>
    ${sec('Thông tin tổ chức', iconButton('edit', 'Chỉnh sửa thông tin tổ chức', { size: 20 }), `<div class="t1-stack12">${orgRows}</div>`)}
    ${sec('Hồ sơ pháp lý', hasLegal ? iconButton('edit', 'Chỉnh sửa hồ sơ pháp lý', { size: 20 }) : '', legal)}
  </div>`;
}

export function profilePage(v) {
  const s = PROFILE_STATES[v.state];
  const base = { title: 'Hồ sơ tổ chức', placeWidth: v.width };
  let page;
  if (s.loading) page = vScaffold({ ...base, body: centerLoading(), fixed: true });
  else if (s.forbidden) page = vScaffold({ ...base, body: orgUnauthorized() });
  else if (s.error) page = vScaffold({ ...base, body: loadFailed('Không tải được hồ sơ', 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'), fixed: true });
  else {
    page = vScaffold({
      ...base, body: profileBody(!!s.legal),
      toastHtml: s.toast ? toast(...s.toast, { device: v.device, above: 0 }) : '',
    });
  }
  return { page };
}

export function editPage(v) {
  const s = EDIT_STATES[v.state];
  const base = { title: 'Chỉnh thông tin tổ chức', placeWidth: v.width };
  if (s.loading) return { page: vScaffold({ ...base, body: centerLoading(), fixed: true }) };
  const x = { name: ORG.name, phone: ORG.phone, email: ORG.email, address: ORG.address, ...s.values };
  const e = s.errors || {};
  // Câu dẫn → thẻ trắng lưới 2 cột (≥ 600): Tên và Địa chỉ trải hết ngang; Điện thoại | Email; Tỉnh | Xã. Chọn qua impeccable live (2026-11-24).
  const body = `<div class="t1-formpage">
    <p class="t1-small">Thông tin liên hệ này độc lập với hồ sơ pháp lý và chứng từ đã phát hành.</p>
    <div class="t1-formcard"><div class="t1-grid2">
      <div class="t1-grid2__wide">${field({ label: 'Tên tổ chức', required: true, control: input({ value: x.name, invalid: !!e.name }), error: e.name, desc: 'Tên hiển thị.' })}</div>
      ${field({ label: 'Số điện thoại', required: true, control: input({ value: x.phone, invalid: !!e.phone }), error: e.phone })}
      ${field({ label: 'Email liên hệ', required: true, control: input({ value: x.email, invalid: !!e.email }), error: e.email })}
      <div class="t1-grid2__wide">${field({ label: 'Địa chỉ liên hệ', required: true, control: input({ value: x.address, invalid: !!e.address }), error: e.address })}</div>
      ${unitSection({ province: ORG.province, commune: ORG.commune, required: false })}
    </div></div>
  </div>`;
  const page = vScaffold({ ...base, body, bottomBar: twoBar('Lưu thay đổi', !!s.busy), toastHtml: s.toast ? toast(...s.toast, { device: v.device, above: BAR_H }) : '' });
  return { page, overlay: s.dialog ? confirmDialog(DISCARD) : '' };
}

export function legalPage(v) {
  const s = LEGAL_STATES[v.state];
  const title = s.edit ? 'Chỉnh hồ sơ pháp lý' : 'Thêm hồ sơ pháp lý';
  const base = { title, placeWidth: v.width };
  if (s.loading) return { page: vScaffold({ ...base, body: centerLoading(), fixed: true }) };
  const x = s.edit ? { type: LEGAL.entityType, name: LEGAL.legalName, tax: LEGAL.taxCode, address: LEGAL.registeredAddress, ...s.values } : { type: '', name: '', tax: '', address: '', ...s.values };
  const e = s.errors || {};
  // Cùng bố cục với ID-12 (câu dẫn → thẻ trắng lưới 2 cột ≥ 600): Tên pháp lý và Địa chỉ đăng ký trải hết ngang; Loại chủ thể | Mã số thuế; Tỉnh | Xã.
  const body = `<div class="t1-formpage">
    <p class="t1-small">Thay đổi hiện tại không làm thay đổi chứng từ lịch sử.</p>
    <div class="t1-formcard"><div class="t1-grid2">
      <div class="t1-grid2__wide">${field({ label: 'Tên pháp lý', required: true, control: input({ value: x.name, hint: 'Nhập tên pháp lý', invalid: !!e.name }), error: e.name })}</div>
      ${field({ label: 'Loại chủ thể', control: select({ value: x.type, hint: 'Chọn loại chủ thể', invalid: !!e.type }), error: e.type })}
      ${field({ label: 'Mã số thuế', required: true, control: input({ value: x.tax, hint: 'Nhập mã số thuế', invalid: !!e.tax }), error: e.tax })}
      <div class="t1-grid2__wide">${field({ label: 'Địa chỉ đăng ký', control: input({ value: x.address, hint: 'Nhập địa chỉ đăng ký' }) })}</div>
      ${unitSection(s.edit ? { province: ORG.province, commune: ORG.commune, required: false } : { required: false })}
    </div></div>
  </div>`;
  const page = vScaffold({ ...base, body, bottomBar: twoBar('Lưu hồ sơ', !!s.busy), toastHtml: s.toast ? toast(...s.toast, { device: v.device, above: BAR_H }) : '' });
  const overlay = s.sheet ? adaptiveSheet(v.width, duplicateSheet(), 'Mã số thuế đã được ghi nhận') : s.dialog ? confirmDialog(DISCARD) : '';
  return { page, overlay };
}
