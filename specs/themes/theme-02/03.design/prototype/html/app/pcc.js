// SP-04 Product Control Center (PCC) + sheet vòng đời / xoá / khôi phục + toast, SP-21 Checklist, SP-22 Lịch sử thay đổi.
// Nguồn Flutter (apps/erp/lib/features/catalog/):
//   presentation/pages/product_control_center_page.dart, widgets/{product_control_center_body, product_control_center_status_badge,
//     product_control_center_profile_card, product_control_center_readiness_banner, product_control_center_section_card,
//     product_control_center_identity_section, product_control_center_operational_section, product_control_center_custom_fields_section,
//     product_control_center_meta_section, product_control_center_danger_section, product_lifecycle_bottom_sheets,
//     product_delete_confirm_dialog, product_restore_confirm_dialog}.dart
//   logic/product_readiness.dart (ProductReadinessEvaluator, assembler thẻ PCC), data/models/product_readiness.dart (câu blocker)
//   pages/product_readiness_checklist_page.dart, widgets/product_readiness_checklist_body.dart
//   pages/product_change_history_page.dart, widgets/{product_change_history_item, product_price_band_history_change}.dart,
//   utils/product_change_history_formatters.dart
import { icon } from '../shared/icons.js';
import { appBar, badge, button, card, esc, gap, iconBox, scaffold, toast } from './ds.js';
import { money, photo } from './data.js';

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

/** ReadinessBlocker.* (data/models/product_readiness.dart). */
export const BLOCKER_MSG = {
  missing_base_unit: 'Thiếu đơn vị cơ sở', missing_image: 'Chưa có ảnh sản phẩm', missing_price: 'Thiếu giá',
  missing_price_band: 'Thiếu khung giá bán', missing_required_custom_fields: 'Thiếu thông tin bổ sung bắt buộc',
};

/**
 * ProductReadinessEvaluator.compute: blocker theo thứ tự đơn vị → ảnh → giá cơ sở → khung giá → trường bắt buộc.
 * Trạng thái "Sẵn sàng bán" bỏ qua blocker ảnh, nhưng danh sách blocker (và số trên banner "Cần bổ sung") vẫn đếm ảnh.
 */
export function evaluate(f) {
  const b = [];
  if (!f.unit) b.push('missing_base_unit');
  if (!f.images) b.push('missing_image');
  if (f.basePrice == null) b.push('missing_price');
  if (!f.band) b.push('missing_price_band');
  if (f.cfMissing) b.push('missing_required_custom_fields');
  return { ready: b.filter((c) => c !== 'missing_image').length === 0, blockers: b };
}

/** ProductControlCenterStatusBadge: đã xoá → "Đã xóa"; sẵn sàng → "Sẵn sàng bán"; còn lại (kể cả đang tải, ngừng KD) → "Thiếu dữ liệu". */
export function statusBadge({ deleted, ready }) {
  if (deleted) return ['Đã xóa', 'neutral'];
  return ready ? ['Sẵn sàng bán', 'success'] : ['Thiếu dữ liệu', 'danger'];
}

/** _priceBandSubtitle (operational section). */
export function priceBandSubtitle(band, unit) {
  if (!band) return 'Thiếu khung giá bán';
  const list = band.list != null ? `Niêm yết: ${money(band.list)}` : 'Niêm yết: --';
  const floor = band.floor != null ? `Sàn: ${money(band.floor)}` : 'Sàn: --';
  const u = unit ? ` · Đơn vị: ${unit}` : '';
  const meta = band.custom ? ' · Giá riêng' : band.rule ? ` · ${band.rule}` : '';
  return `${list} · ${floor}${u}${meta}`;
}

/** ProductControlCenterProfileCard: "Tồn (<đơn vị | cơ sở>): n" + " (Hết hàng)" khi 0. */
export const profileStockText = (stock, unit) => `Tồn (${unit || 'cơ sở'}): ${stock ?? 0}${stock === 0 ? ' (Hết hàng)' : ''}`;

/** formatProductChangeHistoryDateTime: "yyyy-MM-dd HH:mm" (giờ ICT). */
export const historyDate = (iso) => iso.replace('T', ' ').slice(0, 16);

/** ProductChangeHistoryItem: giá trị trước / sau nối bằng " — " (khung giá dùng " → "); ẩn → "***". */
export function valueLine(e) {
  const b = e.masked ? '***' : e.before;
  const a = e.masked ? '***' : e.after;
  if (b != null && a != null) return `${b} — ${a}`;
  return b ?? a ?? '';
}

// ---------------------------------------------------------------- dữ liệu PCC

const HIST = [
  { kind: 'band', summary: 'Cập nhật khung giá', title: 'Cập nhật khung giá — Hộp', at: '2026-11-20T15:42', rows: [['Cách tính', 'Nhập thủ công → Theo khung giá cửa hàng'], ['Giá niêm yết', '120.000 đ → 125.000 đ'], ['Giá sàn', '100.000 đ → 110.000 đ']], cause: 'Thao tác trực tiếp', actor: '3f9a2c1b' },
  { summary: 'Cập nhật giá cơ sở', at: '2026-11-20T15:40', actor: '3f9a2c1b' },
  { summary: 'Cập nhật hồ sơ sản phẩm', at: '2026-11-18T09:12', before: 'Amoxicillin', after: 'Amoxicillin 500mg', actor: '3f9a2c1b' },
  { kind: 'band', summary: 'Cập nhật khung giá', title: 'Cập nhật khung giá — Hộp', at: '2026-11-15T10:03', rows: [['Cách tính', 'Theo khung giá cửa hàng → Theo khung giá cửa hàng'], ['Giá niêm yết', '115.000 đ → 120.000 đ'], ['Giá sàn', '96.000 đ → 100.000 đ']], cause: 'Tự động do Giá cơ sở thay đổi', actor: '3f9a2c1b' },
  { summary: 'Thay đổi trạng thái kinh doanh', at: '2026-11-12T14:05', before: 'inactive', after: 'active', actor: 'a71d09e4' },
  { summary: 'Thay đổi trạng thái kinh doanh', at: '2026-11-10T08:30', before: 'active', after: 'inactive', actor: 'a71d09e4' },
  { summary: 'Cập nhật thuộc tính sản phẩm', at: '2026-11-05T11:20', masked: true, before: 'x', after: 'y', actor: '3f9a2c1b' },
  { summary: 'Tạo sản phẩm', at: '2026-11-01T08:00', actor: '3f9a2c1b' },
];

/** Sản phẩm trên PCC (ProductControlCenterDto rút gọn). */
export const PCC = {
  sp1: { id: 'sp1', name: 'Amoxicillin 500mg', img: 32, images: 3, sku: 'AMX500', barcode: '8936012345678', unit: 'Hộp', stock: 24, basePrice: 80000, band: { list: 125000, floor: 110000, rule: 'Khung giá mặc định' }, groups: [{ name: 'Thông tin dược', emoji: '💊', filled: 4, total: 4 }], note: 'Hàng nhập từ NCC Thú y Sài Gòn.', status: 'active', history: HIST[0] },
  sp3: { id: 'sp3', name: 'Vắc-xin 5 bệnh cho chó', img: null, images: 0, sku: 'VX5B', barcode: null, unit: 'Lọ', stock: 0, basePrice: null, band: null, groups: [{ name: 'Thông tin dược', emoji: '💊', filled: 1, total: 4, missing: true }], cfMissing: true, note: '', status: 'active', history: { summary: 'Tạo sản phẩm', at: '2026-11-19T10:15' } },
  sp5: { id: 'sp5', name: 'Men tiêu hoá Bio-Pet', img: null, images: 0, sku: null, barcode: null, unit: null, stock: 0, basePrice: null, band: null, groups: [], note: '', status: 'active', history: null },
  sp8: { id: 'sp8', name: 'Pate cho mèo vị cá ngừ 85g', img: null, images: 0, sku: 'PATE85', barcode: '8850006301234', unit: 'Lon', stock: 120, basePrice: 12000, band: { list: 18000, floor: 15000, custom: true }, groups: [], note: '', status: 'active', history: { summary: 'Cập nhật khung giá', at: '2026-11-17T16:02' } },
  sp6: { id: 'sp6', name: 'Cát vệ sinh cho mèo 10L', img: 50, images: 1, sku: 'CAT10', barcode: '8936099887766', unit: 'Bao', stock: 0, basePrice: 110000, band: { list: 145000, floor: 125000, rule: 'Khung giá mặc định' }, groups: [], note: '', status: 'inactive', history: { summary: 'Thay đổi trạng thái kinh doanh', at: '2026-11-10T08:30' } },
  sp9: { id: 'sp9', name: 'Vòng cổ chống ve (mẫu cũ)', img: 120, images: 2, sku: 'VC-OLD', barcode: null, unit: 'Cái', stock: 0, basePrice: 45000, band: { list: 65000, floor: 55000, rule: 'Khung giá mặc định' }, groups: [{ name: 'Thông tin dược', emoji: '💊', filled: 0, total: 4, missing: true }], cfMissing: true, note: 'Mẫu cũ, không nhập thêm.', status: 'deleted', history: { summary: 'Xóa mềm sản phẩm', at: '2026-11-08T17:45' } },
};
export const HISTORY = HIST;

// ---------------------------------------------------------------- PCC

/**
 * ProductControlCenterSectionCard: GestureDetector(VCard đệm 16 Row[hộp 40 (emoji 20 hoặc VIconBox icon 20; nền surfaceBrand + icon primary,
 * hasError → dangerBg + danger), khe 16, cột(tiêu đề bodyDefault bold, khe 4, phụ bodySmall textSecondary, [lỗi: khe 4 + "Thiếu thông tin bắt buộc"
 * caption w500 textSecondary]), VButton tertiary small (onEdit null → mờ)].
 */
function sectionCard({ ic = 'clipboard', emoji = '', title, sub, action = 'Sửa', error = false, disabled = false }) {
  const box = emoji ? `<span class="t2-secemoji${error ? ' is-error' : ''}">${emoji}</span>` : iconBox({ ic, cls: error ? 't2-ibox--danger' : 't2-ibox--brand' });
  return card(`<div class="t2-sec">${box}<span class="t2-sec__text"><b>${esc(title)}</b>${gap(4)}<span>${esc(sub)}</span>${error ? `${gap(4)}<em>Thiếu thông tin bắt buộc</em>` : ''}</span>${button(action, { variant: 'tertiary', size: 'small', disabled })}</div>`, { cls: 't2-card--tap' });
}

/** Ảnh 64 bo 8 hoặc VIconBox 64 (icon ảnh 32, nền surfaceAlt, icon textMuted). */
const bigThumb = (p) => (p.img != null ? `<img class="t2-thumb64" src="${photo(p.img)}" alt="">` : `<span class="t2-thumb64 t2-thumb64--empty">${icon('image')}</span>`);

/** Banner tự vẽ: đệm 16, warningBg, viền warning 30%, bo 12; icon error 24 + khe 8 + ["Cần bổ sung (n)" bold, khe 4, câu bodySmall] — cả hai chữ warning. */
const readinessBanner = (n) => `<div class="t2-readybanner">${icon('error')}<span><b>Cần bổ sung (${n})</b>${gap(4)}<span>Bấm để xem checklist và bổ sung từng mục.</span></span></div>`;

/** ProductControlCenterDangerSection: đầu (đệm 16, dangerBg, viền danger 30%, bo 12) + phần mở (nền surface, viền 3 cạnh) với dòng đệm 16: icon 20 + khe 16 + nhãn bodyDefault — tất cả chữ đỏ. */
function dangerSection(p, open) {
  const deleted = p.status === 'deleted';
  const sub = deleted ? 'Khôi phục sản phẩm' : 'Ngừng kinh doanh · Xoá sản phẩm';
  const item = (ic, l) => `<span class="t2-danger__item">${icon(ic)}<span>${esc(l)}</span></span>`;
  const items = deleted ? item('rotate', 'Khôi phục')
    : `${p.status === 'active' ? item('ban', 'Ngừng kinh doanh') : item('play', 'Kinh doanh lại')}<i class="t2-danger__div"></i>${item('trash', 'Xoá sản phẩm')}`;
  return `<div class="t2-danger${open ? ' is-open' : ''}"><button type="button" class="t2-danger__head">${iconBox({ ic: 'error', cls: 't2-ibox--dangerline' })}<span><b>Nâng cao</b>${gap(4)}<span>${esc(sub)}</span></span>${icon(open ? 'chevronUp' : 'chevronDown')}</button>${open ? `<div class="t2-danger__body">${items}</div>` : ''}</div>`;
}

/**
 * ProductControlCenterPage: VPageScaffold(tiêu đề = tên (H3 bold), leading: hẹp → IconButton(arrowBack), web 2 cột → không có;
 * actions: badge nhỏ + đệm phải 16). Thân: cuộn, VPagePadding dọc 16; thẻ tóm tắt, [banner], các thẻ mục cách 8, khu Nâng cao, SafeArea + khe 32.
 * o: { p, loading, error, dangerOpen, scrollEnd }
 */
export function pccPage(o, v, placeWidth, split) {
  const p = o.p;
  const r = evaluate({ unit: p.unit, images: p.images, basePrice: p.basePrice, band: p.band, cfMissing: p.cfMissing });
  const deleted = p.status === 'deleted';
  const [bl, bt] = statusBadge({ deleted, ready: !o.loading && !o.error && r.ready });
  const back = split ? '' : `<button type="button" class="t2-appbar__back" aria-label="Quay lại">${icon('arrowLeft')}</button>`;
  const bar = appBar(o.noTitle ? '' : p.name, { leading: back, actions: `<span class="t2-pccbadge">${badge(bl, { tone: bt, small: true })}</span>` });
  let body;
  if (o.error) {
    body = `<div class="t2-center"><p class="t2-centertext">${esc(o.error)}</p></div>`;
  } else if (o.loading) {
    body = `<div class="t2-pccscroll">${gap(48)}<div class="t2-pad32"><span class="t2-spin t2-spin--material"></span></div></div>`;
  } else {
    const listText = p.band ? `Giá niêm yết: ${money(p.band.list)}` : 'Giá niêm yết: --';
    const summary = card(`<div class="t2-sum">${bigThumb(p)}<span class="t2-sum__text"><span class="t2-sum__name">${esc(p.name)}</span>${gap(4)}<span>${esc(listText)}</span>${gap(4)}<small>${esc(profileStockText(p.stock, p.unit))}</small></span></div>`);
    const hist = p.history ? `${p.history.summary} · ${p.history.at.slice(0, 10)}` : 'Chưa có lịch sử';
    const cards = [
      sectionCard({ ic: 'clipboard', title: 'Hồ sơ sản phẩm', sub: `${p.sku ?? 'Chưa có mã SKU'} · ${p.barcode ?? 'Chưa có mã vạch'}`, disabled: deleted }),
      sectionCard({ ic: 'camera', title: 'Ảnh sản phẩm', sub: `${p.images} ảnh`, disabled: deleted }),
      sectionCard({ ic: 'ruler', title: 'Đơn vị đo lường', sub: p.unit || 'Thiếu đơn vị cơ sở', disabled: deleted }),
      sectionCard({ ic: 'inventory', title: 'Tồn kho', sub: `${p.stock ?? 0}${p.unit ? ` ${p.unit}` : ''}`, action: 'Xem tồn kho', disabled: deleted }),
      sectionCard({ ic: 'coins', title: 'Giá cơ sở', sub: p.basePrice != null ? money(p.basePrice) : 'Thiếu Giá cơ sở định giá', disabled: deleted }),
      sectionCard({ ic: 'tag', title: 'Khung giá', sub: priceBandSubtitle(p.band, p.unit), disabled: deleted }),
      ...p.groups.map((g) => sectionCard({ emoji: g.emoji, title: g.name, sub: `${g.filled}/${g.total} trường đã điền`, error: !!g.missing })),
      sectionCard({ ic: 'fileText', title: 'Ghi chú', sub: p.note ? 'Đã điền ghi chú' : 'Chưa có ghi chú' }),
      sectionCard({ ic: 'history', title: 'Lịch sử thay đổi', sub: hist, action: 'Xem' }),
    ].join(gap(8));
    body = `<div class="t2-pccscroll"${o.scrollEnd ? ' data-scroll-end' : ''}>${summary}${r.blockers.length ? `${gap(8)}${readinessBanner(r.blockers.length)}` : ''}${gap(8)}${cards}${gap(8)}${dangerSection(p, o.dangerOpen)}${gap(32)}</div>`;
  }
  return scaffold({ appbar: bar, body, placeWidth, windowWidth: v.width, cls: 't2-page--pcc' });
}

// ---------------------------------------------------------------- sheet

/** _VLifecycleBottomSheetContent: SafeArea + đệm 20; câu bodyDefault textSecondary; [hộp "Cần xác nhận"]; khe 24; "Huỷ" | khe 16 | nút chính (isDestructive → đỏ). */
const warnList = (title, items, bullet = true) => `${gap(16)}<div class="t2-sheetwarn"><span class="t2-sheetwarn__head">${icon('alert')}<b>${esc(title)}</b></span>${gap(8)}${items.map((m) => `<span class="t2-sheetwarn__row">${bullet ? '<i>• </i>' : ''}<span>${esc(m)}</span></span>`).join('')}</div>`;
const twoButtons = (primary, danger) => `${gap(24)}<div class="t2-btnrow16">${button('Huỷ', { variant: 'secondary', full: true })}${button(primary, { full: true, tone: danger ? 'danger' : '' })}</div>`;
const sheetText = (t) => `<p class="t2-sheettext">${esc(t)}</p>`;

export function deactivateSheet(warnings = []) {
  return `<div class="t2-lc">${sheetText('Sản phẩm sẽ không xuất hiện khi tạo đơn mới. Dữ liệu đơn cũ vẫn giữ nguyên. Bạn có thể mở lại bất cứ lúc nào.')}${warnings.length ? warnList('Cần xác nhận', warnings) : ''}${twoButtons('Ngừng kinh doanh', true)}</div>`;
}
/** Kinh doanh lại: cùng khuôn, isDestructive true → nút chính cũng đỏ. */
export const reactivateSheet = () => `<div class="t2-lc">${sheetText('Sản phẩm sẽ xuất hiện lại khi tạo đơn và nhập hàng.')}${twoButtons('Kinh doanh lại', true)}</div>`;

/** ProductDeleteConfirmDialog: đang kiểm tra / đang xoá → Row(min)[CircularProgressIndicator 36, khe 16, VText]; xác nhận → câu + [hộp "Lưu ý"] + "Huỷ" | "Xoá sản phẩm" đỏ. */
export const loadingRow = (label) => `<div class="t2-lc"><span class="t2-loadrow"><span class="t2-spin t2-spin--material"></span><span>${esc(label)}</span></span></div>`;
export function deleteSheet(warnings = []) {
  return `<div class="t2-lc">${sheetText('Sản phẩm sẽ được đánh dấu đã xoá và không xuất hiện trong danh sách. Đơn hàng cũ vẫn giữ nguyên dữ liệu tại thời điểm giao dịch.')}${warnings.length ? warnList('Lưu ý', warnings) : ''}${twoButtons('Xoá sản phẩm', true)}</div>`;
}
/** Không xoá được: câu + từng lý do (icon error 16 + bodySmall đỏ, đệm dọc 4) + khe 24 + "Đóng" secondary đầy ngang. */
export function deleteBlockedSheet(name, issues) {
  return `<div class="t2-lc">${sheetText(`Sản phẩm "${name}" không thể xóa vì:`)}${gap(12)}${issues.map((m) => `<span class="t2-issue">${icon('error')}<span>${esc(m)}</span></span>`).join('')}${gap(24)}${button('Đóng', { variant: 'secondary', full: true })}</div>`;
}
/** _RestoreContent: câu (có chữ "readiness") + [hộp "Readiness hiện tại" không icon, không gạch đầu dòng] + [lỗi bodySmall w600 đỏ] + "Huỷ" | "Khôi phục" (xanh). */
export function restoreSheet(name, blockers, error = '') {
  const box = blockers.length ? `${gap(16)}<div class="t2-sheetwarn"><b class="t2-sheetwarn__title">Readiness hiện tại</b>${gap(8)}${blockers.map((m) => `<span class="t2-sheetwarn__row"><span>${esc(m)}</span></span>`).join('')}</div>` : '';
  return `<div class="t2-lc">${sheetText(`Sản phẩm "${name}" sẽ được khôi phục ở trạng thái ngừng kinh doanh. Kiểm tra readiness trước khi kinh doanh lại.`)}${box}${error ? `${gap(16)}<p class="t2-sheeterr">${esc(error)}</p>` : ''}${twoButtons('Khôi phục', false)}</div>`;
}

// ---------------------------------------------------------------- SP-21 checklist

const CTA = { missing_base_unit: 'Thiết lập đơn vị', missing_image: 'Quản lý ảnh', missing_price: 'Thiết lập giá cơ sở', missing_price_band: 'Thiết lập giá', missing_required_custom_fields: 'Cập nhật trường' };
export const ctaLabel = (code) => CTA[code] ?? null;

/**
 * ProductReadinessChecklistPage: VPageScaffold("Sẵn sàng vận hành", ‹ mặc định). Chỉ liệt kê blocker (không liệt kê mục đã xong):
 * ô đệm 16, surface, bo 8, viền borderDefault; icon error_outline 20 warning, khe 12, câu bodyDefault, TextButton CTA bodySmall w600 primary. Cách 8.
 * Không blocker → "Sản phẩm đã sẵn sàng vận hành." canh giữa.
 */
export function checklistPage(blockers, v, toastMsg = '') {
  const body = blockers.length
    ? `<div class="t2-checklist">${blockers.map((c) => `<div class="t2-blocker">${icon('error')}<span>${esc(BLOCKER_MSG[c])}</span>${ctaLabel(c) ? `<button type="button" class="t2-ctabtn">${esc(ctaLabel(c))}</button>` : ''}</div>`).join(gap(8))}</div>`
    : '<div class="t2-center"><p class="t2-centertext">Sản phẩm đã sẵn sàng vận hành.</p></div>';
  const page = scaffold({ appbar: appBar('Sẵn sàng vận hành', { back: true }), body, placeWidth: v.width, windowWidth: v.width });
  const t = toastMsg ? toast('warning', 'Yêu cầu', toastMsg, { bottom: 14 + (v.device === 'iphone' ? 34 : 0) }) : '';
  return `<div class="t2-area">${page}${t}</div>`;
}

// ---------------------------------------------------------------- SP-22 lịch sử thay đổi

/** ProductChangeHistoryItem: margin đáy 12, đệm 16, surface, bo 12, viền borderDefault; [tóm tắt bold | ngày bodySmall], khe 4 giá trị, [khe 4 "Lý do: …" nghiêng], khe 4 "bởi <8 ký tự mã>". */
function historyItem(e) {
  if (e.kind === 'band') {
    return `<div class="t2-hist"><div class="t2-hist__head"><b>${esc(e.title)}</b><span>${esc(historyDate(e.at))}</span></div>${gap(12)}
      ${e.rows.map(([l, val]) => `<div class="t2-hist__row"><span>${esc(l)}</span><b>${esc(val)}</b></div>`).join(gap(8))}
      ${gap(12)}<small>Nguyên nhân: ${esc(e.cause)}</small>${gap(4)}<small>bởi ${esc(e.actor)}</small></div>`;
  }
  const val = valueLine(e);
  return `<div class="t2-hist"><div class="t2-hist__head"><b>${esc(e.summary)}</b><span>${esc(historyDate(e.at))}</span></div>
    ${val ? `${gap(4)}<p class="t2-hist__val">${esc(val)}</p>` : ''}${e.reason ? `${gap(4)}<p class="t2-hist__val"><i>Lý do: ${esc(e.reason)}</i></p>` : ''}${gap(4)}<small>bởi ${esc(e.actor)}</small></div>`;
}

/**
 * ProductChangeHistoryPage: VPageScaffold("Lịch sử thay đổi", subtitle tên sản phẩm, leading arrowBack). Đang tải: vòng Material giữa.
 * Lỗi (chưa có dòng): icon error 48 đỏ, khe 16, câu, khe 16, "Thử lại" secondary. Rỗng: icon history 48 textMuted + "Chưa có lịch sử thay đổi nào".
 * Danh sách đệm 16; chưa hết → thêm vòng xoay cuối (đệm 16).
 */
export function historyPage(kind, v) {
  let body;
  if (kind === 'loading') body = '<div class="t2-center"><span class="t2-spin t2-spin--material"></span></div>';
  else if (kind === 'error') body = `<div class="t2-center"><div class="t2-histstate">${icon('error')}${gap(16)}<p>Đã xảy ra lỗi. Vui lòng thử lại.</p>${gap(16)}${button('Thử lại', { variant: 'secondary' })}</div></div>`;
  else if (kind === 'empty') body = `<div class="t2-center"><div class="t2-histstate is-empty">${icon('history')}${gap(16)}<p>Chưa có lịch sử thay đổi nào</p></div></div>`;
  else {
    const more = kind === 'more' ? '<div class="t2-pad16c"><span class="t2-spin t2-spin--material"></span></div>' : '';
    body = `<div class="t2-histlist"${kind === 'more' ? ' data-scroll-end' : ''}>${HIST.map(historyItem).join('')}${more}</div>`;
  }
  const back = `<button type="button" class="t2-appbar__back" aria-label="Quay lại">${icon('arrowLeft')}</button>`;
  return scaffold({ appbar: appBar('Lịch sử thay đổi', { subtitle: 'Amoxicillin 500mg', leading: back }), body, placeWidth: v.width, windowWidth: v.width });
}
