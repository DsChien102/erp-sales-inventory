// PT-11 Chuyển thành tổ chức. Route /partner/:id/transform khai báo ngoài ShellRoute → toàn màn (web không thanh bên, thân cột 720).
// Nguồn Flutter (apps/erp/lib/features/partner/presentation/):
//   pages/partner_transform_page.dart (tiêu đề theo bước, leading IconButton arrowBack, lớp phủ đang gửi, hộp thoại xác nhận showDialog)
//   widgets/{partner_transform_stepper, partner_transform_step_one_view, partner_transform_organization_form, partner_transform_field,
//     partner_transform_primary_contact_card, partner_transform_blocking_banner, partner_transform_preview_view, partner_transform_preview_card,
//     partner_transform_blocked_state, partner_transform_confirmation_dialog, partner_transform_primary_contact_blocked_sheet}.dart
//   widgets/partner_transform_step_one_validator.dart
import { icon } from '../shared/icons.js';
import { appBar, avatar, banner, button, card, centerLoading, esc, gap, iconBox, input, scaffold, select } from './ds.js';
import { DESKTOP } from '../shared/shell.js';
import { transformPageWeb } from './transform-web.js';
import { transformPageMobile } from './transform-mobile.js';

export const PERSON = { name: 'Nguyễn Văn Hùng', phone: '0912 345 678', roles: 'Khách hàng' };
export const ORG_DRAFT = { type: 'Công ty', name: 'Công ty TNHH Hùng Phát', shortName: 'Hùng Phát', intlName: '', phone: '0292 381 2233', email: 'lienhe@hungphat.vn', taxCode: '1801998877' };

/** PartnerTransformStepOneValidator (lỗi hiện sau lần bấm "Tiếp" đầu). */
export function stepOneErrors(d) {
  const e = {};
  if (!d.type) e.type = 'Vui lòng chọn loại tổ chức';
  if (!d.name.trim()) e.name = 'Vui lòng nhập tên tổ chức';
  const digits = d.phone.replace(/ /g, '');
  if (/[^0-9 ]/.test(d.phone)) e.phone = 'Số điện thoại không hợp lệ';
  else if (!digits) e.phone = 'Vui lòng nhập số điện thoại';
  else if (digits.length < 9 || digits.length > 11) e.phone = 'Số điện thoại không hợp lệ';
  return e;
}

/** Tiêu đề trang: bị chặn hoặc bước 1 → "Chuyển thành tổ chức"; bước 2 → "Xem trước chuyển đổi". */
export const transformTitle = ({ blocked, step }) => (blocked || step === 1 ? 'Chuyển thành tổ chức' : 'Xem trước chuyển đổi');

/** PartnerTransformStepper: Row(step, đường, step, đường, step) — 5 phần bằng nhau; vòng 32 viền 2; nhãn 11 (đậm khi đã / đang). Bước 3 "Xác nhận" không bao giờ sáng. */
function stepper(cur) {
  const step = (n, label) => {
    const on = n <= cur;
    return `<div class="t3-tstep${on ? ' is-on' : ''}"><span>${n}</span>${gap(8)}<small>${esc(label)}</small></div>`;
  };
  return `<div class="t3-tsteps">${step(1, 'Thông tin tổ chức')}<i></i>${step(2, 'Xem trước')}<i></i>${step(3, 'Xác nhận')}</div>`;
}

/** PartnerTransformFieldLabel: bodySmall 13 textSecondary cao 1.2 (không phải VFieldLabel) + khe 8. */
const tfield = (label, control, { req = false, err = null } = {}) => `<div class="t3-field${err ? ' is-invalid' : ''}"><span class="t3-tlabel">${esc(label)}${req ? '<i> *</i>' : ''}</span>${gap(8)}${control}${err ? `<span class="t3-error">${esc(err)}</span>` : ''}</div>`;

function stepOne(d, errors, showBanner) {
  const e = errors || {};
  const form = [
    tfield('Loại tổ chức', select({ value: d.type, hint: 'Chọn loại tổ chức' }).replace('class="t3-select', `class="t3-select${e.type ? ' is-invalid' : ''}`), { req: true, err: e.type }),
    tfield('Tên tổ chức', input({ value: d.name, hint: 'Nhập tên tổ chức', invalid: !!e.name }), { req: true, err: e.name }),
    tfield('Tên viết tắt', input({ value: d.shortName, hint: 'Nhập tên viết tắt' })),
    tfield('Tên quốc tế', input({ value: d.intlName, hint: 'Nhập tên quốc tế' })),
    tfield('SĐT tổ chức', input({ value: d.phone, hint: 'Nhập số điện thoại', invalid: !!e.phone }), { req: true, err: e.phone }),
    tfield('Email tổ chức', input({ value: d.email, hint: 'Nhập email' })),
    tfield('MST', input({ value: d.taxCode, hint: 'Nhập MST (10 số, 12 số hoặc 10-3 số)' })),
  ].join(gap(8));
  const contact = `<div class="t3-tcontact"><b>Cá nhân hiện tại sẽ được lưu làm người liên hệ chính</b><div>${iconBox({ label: avatar(PERSON.name).match(/<b>(.*?)<\/b>/)[1], size: 56, iconSize: 18, circle: true, cls: 't3-ibox--success' })}<div><strong>${esc(PERSON.name)}</strong>${gap(4)}<span>${esc(PERSON.phone)}</span></div></div></div>`;
  // canContinue = !_attemptedContinue || hợp lệ: lỗi máy chủ (trùng) quay về bước 1 với _attemptedContinue = false nên nút Tiếp vẫn bật.
  const blocked = showBanner;
  return `<div class="t3-tscroll">${stepper(1)}${gap(12)}<span class="t3-tbar" style="width:96px"></span>${gap(16)}<h2 class="t3-h4">Thông tin tổ chức (mới)</h2>${gap(12)}${form}${gap(16)}${contact}${showBanner ? `${gap(12)}${banner('warning', 'Không thể chuyển đổi khi thiếu thông tin bắt buộc hoặc dữ liệu bị trùng.')}` : ''}${gap(12)}<div class="t3-grid2 t3-tacts">${button('Huỷ', { variant: 'secondary', fg: 'success', full: true })}${button('Tiếp', { full: true, disabled: blocked })}</div></div>`;
}

/** PartnerTransformPreviewCard: VCard đệm 12; VAvatar 54 (chữ 18) | tên w700, khe 4, dòng phụ bodySmall, khe 4, SĐT bodyDefault w600. */
const previewCard = (name, sub, phone) => card(`<div class="t3-pcard">${iconBox({ label: avatar(name).match(/<b>(.*?)<\/b>/)[1], size: 54, iconSize: 18, circle: true, cls: 't3-ibox--success' })}<div><b>${esc(name)}</b>${gap(4)}<span>${esc(sub)}</span>${gap(4)}<strong>${esc(phone)}</strong></div></div>`, { pad: false, cls: 't3-card--p12' });
const section = (title, inner) => `<div class="t3-psec"><b>${esc(title)}</b>${gap(8)}${inner}</div>`;

function stepTwo(d, error) {
  return `<div class="t3-tscroll">${stepper(2)}${gap(12)}<span class="t3-tbar" style="width:44px"></span>${error ? `${gap(12)}${banner('warning', error)}` : ''}${gap(16)}
    ${section('Trước khi chuyển', previewCard(PERSON.name, `Cá nhân  •  ${PERSON.roles}`, PERSON.phone))}
    <i class="t3-parrow">${icon('arrowDown')}</i>
    ${section('Sau khi chuyển', previewCard(d.name, `Tổ chức  •  ${PERSON.roles}`, d.phone))}${gap(12)}
    <p class="t3-small t3-small--b">Người liên hệ chính (từ hồ sơ cá nhân)</p>${gap(8)}${previewCard(PERSON.name, 'Người liên hệ chính', PERSON.phone)}${gap(12)}
    ${banner('info', 'Lịch sử giao dịch và dữ liệu liên quan sẽ được giữ nguyên.')}${gap(16)}
    <div class="t3-grid2 t3-tacts">${button('Quay lại', { variant: 'secondary', fg: 'success', full: true })}${button('Xác nhận', { full: true })}</div></div>`;
}

/** PartnerTransformBlockedState: đệm 24 / 32; hình 140; khe 24; tiêu đề; khe 12; mô tả; khe 32; nút viền đầy ngang. */
export function blockedState(kind) {
  const np = kind === 'no-permission';
  const art = np ? `<div class="t3-tart">${icon('shield')}<i class="p">${icon('plus')}</i></div>` : `<div class="t3-tart t3-tart--cloud">${icon('cloud')}<i class="w">${icon('alert')}</i></div>`;
  return `<div class="t3-derr t3-derr--full">${art}${gap(24)}<h2>${np ? 'Không có quyền chuyển đổi' : 'Dữ liệu đã thay đổi'}</h2>${gap(12)}<p>${np ? 'Bạn không có quyền thực hiện chuyển đổi hồ sơ này.' : 'Hồ sơ đã được cập nhật ở nơi khác. Vui lòng tải lại để tiếp tục.'}</p>${gap(32)}${button(np ? 'Quay lại' : 'Tải lại', { variant: 'secondary', fg: 'success', full: true })}</div>`;
}

/** PartnerTransformConfirmationDialog: Dialog Material (không qua showVAdaptiveSheet; iPhone cũng là hộp thoại), lề ngang 20, đệm 20, tối đa 560 (M3). */
export const confirmDialog = () => `<div class="sh-scrim sh-scrim--dialog t3-scrim20"><section class="t3-mdialog" role="dialog" aria-modal="true" aria-label="Xác nhận chuyển thành tổ chức?">
  <div class="t3-center-row">${iconBox({ ic: 'alert', size: 58, iconSize: 32, circle: true, cls: 't3-ibox--warning t3-ibox--ring' })}</div>${gap(16)}
  <h2 class="t3-ctitle">Xác nhận chuyển thành tổ chức?</h2>${gap(16)}
  <p class="t3-body2">Hồ sơ hiện tại sẽ trở thành Tổ chức.</p>${gap(12)}<p class="t3-body2">Thông tin cá nhân hiện tại sẽ được lưu làm Người liên hệ chính.</p>${gap(12)}<p class="t3-body2">Lịch sử giao dịch, hóa đơn và công nợ vẫn được giữ nguyên.</p>${gap(20)}
  <div class="t3-grid2">${button('Quay lại', { variant: 'secondary', fg: 'success', full: true })}${button('Xác nhận chuyển', { full: true })}</div></section></div>`;

/** PartnerTransformPrimaryContactBlockedSheet (mở từ sheet thao tác PT-07): tay kéo tự vẽ 40 × 4 + icon tổ chức 44 vàng. */
export const transformPrimaryBlockedSheet = (org) => `<div class="t3-confirm t3-confirm--c"><span class="t3-ownhandle"></span>${gap(20)}<div class="t3-bigicon t3-bigicon--warning t3-bigicon--44">${icon('building')}</div>${gap(12)}<h2 class="t3-ctitle">Không thể chuyển thành tổ chức</h2>${gap(8)}<p class="t3-cdesc">Hồ sơ này đang là người liên hệ chính của “${esc(org)}”. Hãy đổi người liên hệ chính của tổ chức trước khi thực hiện chuyển đổi.</p>${gap(16)}<div class="t3-grid2">${button('Đóng', { variant: 'secondary', fg: 'success', full: true })}${button('Xem tổ chức', { full: true })}</div></div>`;

/** Trang PT-11 theo ca. */
export function transformPage(state, v) {
  if (v.width >= DESKTOP) return transformPageWeb(state); // Web: form + cột phải (transform-web.js)
  if (v.width < 840) return transformPageMobile(state); // iPhone: cùng mẫu form hồ sơ (transform-mobile.js)
  const EMPTY = { type: '', name: '', shortName: '', intlName: '', phone: '', email: '', taxCode: '' };
  let step = 1; let blocked = null; let body;
  if (state === 'blocked-permission' || state === 'blocked-stale') {
    blocked = state;
    body = blockedState(state === 'blocked-permission' ? 'no-permission' : 'stale');
  } else if (state === 'step1') body = stepOne(EMPTY, null, false);
  else if (state === 'step1-errors') body = stepOne({ ...EMPTY, phone: '0912 34' }, stepOneErrors({ ...EMPTY, phone: '0912 34' }), true);
  else if (state === 'step1-duplicate') body = stepOne(ORG_DRAFT, { phone: 'Số điện thoại đã tồn tại trên hồ sơ khác.' }, false);
  else if (state === 'step1-filled') body = stepOne(ORG_DRAFT, null, false);
  else {
    step = 2;
    body = stepTwo(ORG_DRAFT, state === 'step2-error' ? 'Không thể chuyển đổi hồ sơ. Vui lòng thử lại.' : null);
  }
  if (state === 'submitting') body += `<div class="t3-tsubmit">${centerLoading({ material: true })}</div>`;
  const leading = `<button type="button" class="t3-appbar__back" aria-label="Quay lại">${icon('arrowLeft')}</button>`;
  return scaffold({ appbar: appBar(transformTitle({ blocked, step }), { leading, center: true }), body: `<div class="t3-form t3-rel">${body}</div>`, placeWidth: v.width, windowWidth: v.width });
}
