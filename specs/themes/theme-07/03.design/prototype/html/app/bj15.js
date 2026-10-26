/* BJ-15 — Báo cáo nhập – xuất – tồn và thẻ kho (UIF-15). Màn: SCR-055 (báo cáo và thẻ kho — hai chế độ của một màn), SCR-056, SCR-059.
 *
 * Thiết kế lại T7-P chặng 6 (v5.20.0): bỏ biểu mẫu tra cứu trước khi thấy số (SCR-054), gộp nguồn nghiệp vụ vào chi tiết biến động (SCR-057),
 * xuất báo cáo là sheet ở 055 (SCR-058). Mọi lối vào mở thẳng 055 với kỳ mặc định "Tháng 09/2026"; kỳ và cách hiểu ngày nằm ở thanh lọc đầu màn.
 * Một nguồn số: bj15Ledger(productId, { from, to, dateMode, lot }) tính đầu kỳ / nhập / xuất / cuối kỳ và tồn sau từng dòng cho báo cáo, thẻ kho
 * và tệp xuất; cuối kỳ phải bằng tồn của BJ-01 (bj15Check, lỗi thì console.error để golden bắt).
 * Tiền theo vai: t7ShowMoney() — nhân viên không có cột / dòng giá trị và không có chuỗi tiền trong DOM (BR-04). Chỉ đọc: không sửa số dư từ báo cáo.
 * Dùng từ khuôn: K1, K4 (k4Result, k4Footer), K6 (k6TaskList: ô tìm + bảng, không chip), K7 (k7Table, k7Split, k7FilterChips), dsSegmented.
 * Fixture: plan T7-P-bj15-bao-cao-the-kho.md mục 3 (sản phẩm / lô / tồn từ bj01Products; chứng từ thật của chặng 1–5; tháng 08 khớp BJ-14).
 * SCR-056 dùng chung với BJ-09 ("Lịch sử tình trạng") qua flowRenderers.
 */

const BJ15_TODAY = "2026-09-17";
const BJ15_AS_OF = "17/09/2026 · 21:30";
const BJ15_DATA_START = "2026-08-01";
const BJ15_ARCHIVED_AT = "05/09/2026";
const BJ15_EXPORT_MS = 1500;
const BJ15_PERIOD_THIS = { from: "2026-09-01", to: BJ15_TODAY };
const BJ15_PERIOD_LAST = { from: "2026-08-01", to: "2026-08-31" };
const BJ15_AN = "Nguyễn Văn An", BJ15_BINH = "Trần Thị Bình";

/* ---------- Fixture: sổ kho tháng 08 và 09/2026 ---------- */

// Tồn đầu 01/08 (= cuối tháng 07 của BJ-14) theo sản phẩm và lô; "" = sản phẩm không theo lô.
const BJ15_BASE = {
  "INV-NOB": { DH2507: 30, DH2509: 88 },
  "INV-AMX": { "": 30 },
  "INV-ENRO": { "": 6 },
  "INV-TYLO": { TY2408: 11, TY2511: 3 },
  "INV-OXY": { "": 17 },
};
// [sản phẩm, lô, loại, chứng từ, ngày nghiệp vụ, ghi nhận, người, biến động, tình trạng, luồng nguồn, mã phiếu BJ-11, ghi chú]
// Tháng 08: nhập / xuất khớp BJ14_T_0826 (cuối 31/08 = 122 / 28 / 0 / 12 / 15). Tháng 09: cuối kỳ khớp tồn BJ-01 (120 / 48 / 0 / 14 / 12).
const BJ15_RAW = [
  ["INV-TYLO", "TY2511", "Nhận hàng", "PN-260803-04", "03/08", "03/08 09:20", BJ15_BINH, 7, "Bán được", "UIF-02"],
  ["INV-TYLO", "TY2511", "Xuất bán", "SO-260805-08", "05/08", "05/08 13:40", BJ15_AN, -5, "Bán được", "UIF-05"],
  ["INV-NOB", "DH2509", "Xuất bán", "SO-260806-02", "06/08", "06/08 10:12", BJ15_AN, -18, "Bán được", "UIF-05"],
  ["INV-AMX", "", "Xuất bán", "SO-260807-06", "07/08", "07/08 11:20", BJ15_AN, -12, "Bán được", "UIF-05"],
  ["INV-OXY", "", "Xuất bán", "SO-260809-04", "09/08", "09/08 10:50", BJ15_AN, -5, "Bán được", "UIF-05"],
  ["INV-NOB", "DH2509", "Xuất bán", "SO-260811-05", "11/08", "11/08 14:30", BJ15_BINH, -10, "Bán được", "UIF-05"],
  ["INV-NOB", "DH2507", "Nhận hàng", "PN-260816-04", "16/08", "16/08 15:40", BJ15_BINH, 42, "Bán được", "UIF-02"],
  ["INV-OXY", "", "Nhận hàng", "PN-260816-04", "16/08", "16/08 15:42", BJ15_BINH, 6, "Bán được", "UIF-02"],
  ["INV-TYLO", "TY2511", "Xuất bán", "SO-260818-03", "18/08", "18/08 17:10", BJ15_AN, -4, "Bán được", "UIF-05"],
  ["INV-AMX", "", "Xuất bán", "SO-260819-11", "19/08", "19/08 16:45", BJ15_BINH, -10, "Bán được", "UIF-05"],
  ["INV-NOB", "DH2507", "Xuất bán", "SO-260821-09", "21/08", "21/08 09:05", BJ15_AN, -10, "Bán được", "UIF-05"],
  ["INV-OXY", "", "Xuất bán", "SO-260823-12", "23/08", "23/08 12:25", BJ15_BINH, -3, "Bán được", "UIF-05"],
  ["INV-AMX", "", "Nhận hàng", "PN-260825-02", "25/08", "25/08 10:10", BJ15_BINH, 20, "Bán được", "UIF-02"],
  ["INV-ENRO", "", "Xuất bán", "SO-260826-11", "26/08", "26/08 15:00", BJ15_AN, -6, "Bán được", "UIF-05"],
  ["INV-OXY", "", "Xuất bán", "SO-260902-19", "02/09", "02/09 13:15", BJ15_BINH, -3, "Bán được", "UIF-11", "IO-260902-005"],
  ["INV-NOB", "DH2507", "Nhận hàng", "PN-260903-02", "03/09", "03/09 09:30", BJ15_BINH, 10, "Bán được", "UIF-02"],
  ["INV-TYLO", "TY2511", "Nhận hàng", "PN-260903-05", "03/09", "04/09 08:40", BJ15_AN, 5, "Bán được", "UIF-11", "IO-260903-017"],
  ["INV-AMX", "", "Nhận hàng", "PN-260904-08", "04/09", "04/09 16:22", BJ15_AN, 20, "Bán được", "UIF-11", "IO-260904-021"],
  ["INV-NOB", "DH2509", "Xuất bán", "SO-260905-07", "05/09", "05/09 11:05", BJ15_AN, -10, "Bán được", "UIF-05"],
  ["INV-TYLO", "TY2511", "Xuất bán", "SO-260905-11", "05/09", "05/09 15:20", BJ15_BINH, -3, "Bán được", "UIF-05"],
  ["INV-AMX", "", "Đổi tình trạng", "ST-260906-04", "06/09", "06/09 14:05", BJ15_AN, 0, "Cách ly", "UIF-11", "IO-260906-022", "2 hộp chuyển sang Cách ly"],
  ["INV-NOB", "DH2507", "Bàn giao hàng", "SO-260827-21", "08/09", "09/09 08:50", BJ15_AN, -2, "Bán được", "UIF-05"],
];
const bj15Iso = (dm) => `2026-${dm.slice(3, 5)}-${dm.slice(0, 2)}`;
const BJ15_MOVES = BJ15_RAW.map(([productId, lot, kind, doc, business, recorded, actor, delta, state, sourceFlow, opId = "", note = ""], i) => {
  const code = bj01Products.find((p) => p.id === productId).code;
  return {
    id: `${doc}/${code}`, seq: i, productId, lot, kind, doc, actor, delta, state, sourceFlow, opId, note,
    business: `${business}/2026`, recorded: `${recorded.slice(0, 5)}/2026 · ${recorded.slice(6)}`,
    bIso: bj15Iso(business), rIso: bj15Iso(recorded.slice(0, 5)), rKey: `${bj15Iso(recorded.slice(0, 5))} ${recorded.slice(6)}`,
  };
});

/* ---------- Trạng thái màn ---------- */

let cf15Mode = "REPORT";               // "REPORT" | "CARD"
let cf15Period = { ...BJ15_PERIOD_THIS };
let cf15DateMode = "BUSINESS";         // "BUSINESS" | "RECORDED"
let cf15Query = "";
let cf15Lot = "ALL";
let cf15SelectedProduct = "INV-NOB";
let cf15SelectedMovement = "PN-260904-08/SP-000066";
let cf15Entry = "hub";                 // "hub" | "bj01" | "bj14" — nơi nút quay lại của thẻ kho về
let bj15Ui = { sheet: null, opener: "", custom: null, withValue: true, exportScope: "REPORT" };
let bj15Timer = null;
let bj15Pending = null;
const bj15Expected = {};

const bj15Attr = (v) => escapeAttribute(String(v ?? ""));
const bj15Number = (n) => cfNumber(n);
const bj15Signed = (n) => `${n > 0 ? "+" : n < 0 ? "−" : ""}${cfNumber(Math.abs(n))}`;
// NBSP giữa số và "đ" để số tiền không gãy dòng.
const bj15Money = (n, signed = false) => t7FmtMoney(n, signed).replace(" đ", " đ");
const bj15ShowMoney = (state) => t7ShowMoney() && state !== "FINANCIAL_RESTRICTED";
const bj15Dmy = (iso) => `${iso.slice(8, 10)}/${iso.slice(5, 7)}/${iso.slice(0, 4)}`;
const bj15Dm = (iso) => `${iso.slice(8, 10)}/${iso.slice(5, 7)}`;
const bj15LastDay = (y, m) => new Date(y, m, 0).getDate();

function cf15ProductById(id) { return bj01Products.find((p) => p.id === id) || bj01Products[0]; }
function cf15Movement(id = cf15SelectedMovement) { return BJ15_MOVES.find((m) => m.id === id) || BJ15_MOVES[0]; }
function cf15DateLabel(mode = cf15DateMode) { return mode === "RECORDED" ? "Ngày ghi nhận" : "Ngày nghiệp vụ"; }
function bj15UnitCost(code) {
  if (typeof bj14Official !== "undefined" && bj14Official[code] != null) return bj14Official[code];
  return typeof bj14BaseCost === "function" ? bj14BaseCost(code) || 0 : 0;
}

/* ---------- Kỳ ---------- */

function bj15PeriodKind(p = cf15Period) {
  if (p.from === BJ15_PERIOD_THIS.from && p.to === BJ15_PERIOD_THIS.to) return "THIS";
  if (p.from === BJ15_PERIOD_LAST.from && p.to === BJ15_PERIOD_LAST.to) return "LAST";
  return "CUSTOM";
}
// "Tháng 09/2026" khi kỳ bắt đầu từ ngày 1 và nằm trong một tháng; còn lại "dd/mm – dd/mm/yyyy".
function bj15PeriodLabel(p = cf15Period) {
  if (p.from.slice(0, 7) === p.to.slice(0, 7) && p.from.slice(8) === "01") return `Tháng ${p.from.slice(5, 7)}/${p.from.slice(0, 4)}`;
  return `${bj15Dm(p.from)} – ${bj15Dmy(p.to)}`;
}
function bj15PeriodRange(p = cf15Period) { return `${bj15Dm(p.from)} – ${bj15Dmy(p.to)}`; }
// "08/2026" (kỳ của lần tính giá vốn) → kỳ báo cáo; kỳ đang diễn ra chỉ tính đến hôm nay.
function bj15PeriodOf(mm) {
  const [m, y] = String(mm).split("/").map(Number);
  if (!m || !y) return { ...BJ15_PERIOD_THIS };
  const from = `${y}-${String(m).padStart(2, "0")}-01`, to = `${y}-${String(m).padStart(2, "0")}-${bj15LastDay(y, m)}`;
  return to > BJ15_TODAY ? { from, to: BJ15_TODAY } : { from, to };
}

/* ---------- Sổ kho: một nguồn số ---------- */

function bj15SortKey(m, mode) { return mode === "RECORDED" ? m.rKey : m.bIso; }
function bj15Sorted(rows, mode) { return [...rows].sort((a, b) => (bj15SortKey(a, mode) < bj15SortKey(b, mode) ? -1 : bj15SortKey(a, mode) > bj15SortKey(b, mode) ? 1 : a.seq - b.seq)); }
function bj15BaseOf(productId, lot) {
  const base = BJ15_BASE[productId] || {};
  return !lot || lot === "ALL" ? Object.values(base).reduce((a, n) => a + n, 0) : base[lot] || 0;
}
function bj15Lots(p) {
  const codes = new Set([...(p.lots || []).map((l) => l.code), ...BJ15_MOVES.filter((m) => m.productId === p.id && m.lot).map((m) => m.lot)]);
  return p.tracking === "LOT" ? [...codes].sort() : [];
}
// Đầu kỳ = tồn đầu 01/08 + biến động trước kỳ; mỗi dòng trong kỳ có tồn sau. Sắp theo loại ngày đang đọc (không trộn âm thầm — BR-03).
function bj15Ledger(productId, { from = BJ15_PERIOD_THIS.from, to = BJ15_PERIOD_THIS.to, dateMode = "BUSINESS", lot = "ALL" } = {}) {
  const rows = bj15Sorted(BJ15_MOVES.filter((m) => m.productId === productId && (lot === "ALL" || m.lot === lot)), dateMode);
  const dateOf = (m) => (dateMode === "RECORDED" ? m.rIso : m.bIso);
  let opening = bj15BaseOf(productId, lot);
  rows.forEach((m) => { if (dateOf(m) < from) opening += m.delta; });
  let balance = opening, inQty = 0, outQty = 0;
  const inRange = rows.filter((m) => dateOf(m) >= from && dateOf(m) <= to).map((m) => {
    balance += m.delta;
    if (m.delta > 0) inQty += m.delta; else outQty -= m.delta;
    return { ...m, balance };
  });
  return { opening, inQty, outQty, closing: balance, rows: inRange };
}
// Tồn trước / sau của từng biến động theo toàn bộ lịch sử của sản phẩm (cho 056).
function bj15Balances(productId, dateMode) {
  const out = {}; let balance = bj15BaseOf(productId, "ALL");
  bj15Sorted(BJ15_MOVES.filter((m) => m.productId === productId), dateMode).forEach((m) => { out[m.id] = { before: balance, after: balance + m.delta }; balance += m.delta; });
  return out;
}
function bj15Period() { return { from: cf15Period.from, to: cf15Period.to, dateMode: cf15DateMode }; }
// Cuối kỳ tại 17/09 phải bằng tồn BJ-01; tháng 08 (cuối kỳ, xuất) và tháng 09 (tồn, xuất) phải bằng BJ-14 (nếu có). Sai thì console.error để golden bắt.
function bj15Check() {
  const errors = [];
  bj01Products.forEach((p) => {
    const end = bj15Ledger(p.id, { from: BJ15_DATA_START, to: BJ15_TODAY }).closing;
    if (end !== p.physical) errors.push(`${p.name}: thẻ kho cuối kỳ ${end} ≠ tồn BJ-01 ${p.physical}`);
    if (typeof BJ14_T_0826 !== "undefined") {
      const t = BJ14_T_0826.find((x) => x[0] === p.code);
      const aug = bj15Ledger(p.id, { from: "2026-08-01", to: "2026-08-31" });
      if (t && (aug.closing !== t[3] || aug.outQty !== t[4])) errors.push(`${p.name}: tháng 08 cuối ${aug.closing} / xuất ${aug.outQty} ≠ BJ-14 ${t[3]} / ${t[4]}`);
    }
    if (typeof BJ14_T_U1 !== "undefined") {
      const t = BJ14_T_U1.find((x) => x[0] === p.code);
      const sep = bj15Ledger(p.id, BJ15_PERIOD_THIS);
      if (t && (sep.closing !== t[3] || sep.outQty !== t[4])) errors.push(`${p.name}: tháng 09 tồn ${sep.closing} / xuất ${sep.outQty} ≠ BJ-14 ${t[3]} / ${t[4]}`);
    }
  });
  errors.forEach((e) => console.error(`BJ-15 sổ kho lệch: ${e}`));
  return errors;
}
bj15Check();

function bj15Report(state) {
  const q = cf15Query.trim().toLocaleLowerCase("vi");
  return bj01Products.filter((p) => !q || `${p.name} ${p.code}`.toLocaleLowerCase("vi").includes(q)).map((p) => {
    const l = bj15Ledger(p.id, bj15Period());
    return { id: p.id, name: p.name, code: p.code, uom: p.stockUom, opening: l.opening, inQty: l.inQty, outQty: l.outQty, closing: l.closing, available: p.available, value: l.closing * bj15UnitCost(p.code) };
  });
}

/* ---------- Dựng lại khi trạng thái đặt từ ngoài ---------- */

function bj15ResetView() {
  cf15Mode = "REPORT"; cf15Period = { ...BJ15_PERIOD_THIS }; cf15DateMode = "BUSINESS"; cf15Query = ""; cf15Lot = "ALL";
  cf15SelectedProduct = "INV-NOB"; cf15SelectedMovement = "PN-260904-08/SP-000066"; cf15Entry = "hub";
  bj15Ui = { sheet: null, opener: "", custom: null, withValue: true, exportScope: "REPORT" };
  clearTimeout(bj15Timer);
}
function bj15SetState(screenId, state) { stateByScreen[screenId] = state; bj15Expected[screenId] = state; }
function bj15Seed(screenId, state) {
  if (bj15Expected[screenId] === state) return;
  Object.keys(bj15Expected).forEach((k) => delete bj15Expected[k]);
  bj15Expected[screenId] = state;
  bj15ResetView();
  if (screenId === "SCR-055") {
    if (state === "RECORDED_DATE_VIEW") cf15DateMode = "RECORDED";
    if (state === "EMPTY") { cf15Mode = "CARD"; cf15SelectedProduct = "INV-ENRO"; }
    if (state === "FILTER_EMPTY") cf15Query = "zzz";
    if (state === "ARCHIVED_DATA") cf15Period = { ...BJ15_PERIOD_LAST };
    return;
  }
  if (screenId === "SCR-056") { cf15Mode = "CARD"; cf15SelectedProduct = "INV-AMX"; return; }
  if (screenId === "SCR-059") { bj15Ui.exportScope = "REPORT"; }
}
// Người dùng đổi bộ lọc: trạng thái đặt sẵn để xem (rỗng, theo loại ngày) trở về READY; STALE / lưu trữ / hạn chế tiền giữ nguyên.
function bj15Touch() {
  if (["EMPTY", "FILTER_EMPTY", "RECORDED_DATE_VIEW", "BUSINESS_DATE_VIEW"].includes(stateByScreen["SCR-055"])) bj15SetState("SCR-055", "READY");
}

/* ---------- Khung dùng chung ---------- */

function bj15Shell(opts) {
  const { keepBack = false, ...rest } = opts;
  const html = appShell({ extraClass: "k7-wide", ...rest });
  return keepBack ? html.replace('class="app-icon-button app-back-button"', 'class="app-icon-button app-back-button" data-keep-back') : html;
}
function bj15Denied(title, back = false, what = "xem báo cáo kho") {
  return bj15Shell({ title, body: k1Denied({ what, next: "Liên hệ chủ cửa hàng để được cấp quyền.", exitAttr: k1ExitAttr("SCR-055") }), centered: true, back });
}
function bj15Empty(state) {
  const filtered = state === "FILTER_EMPTY" || cf15Query.trim() || (cf15Mode === "CARD" && cf15Lot !== "ALL");
  return k1Empty({
    title: "Không có biến động trong kỳ", description: "Đổi khoảng ngày hoặc sản phẩm để xem dữ liệu khác.",
    actionLabel: filtered ? "Xem tất cả" : "Xem tháng trước", actionAttr: `data-bj15-action="${filtered ? "clear-filter" : "prev-month"}"`,
  });
}

/* ---------- Thanh lọc (chung báo cáo và thẻ kho) ---------- */

function bj15Toolbar() {
  const seg = dsSegmented({ items: [["BUSINESS", "Ngày nghiệp vụ"], ["RECORDED", "Ngày ghi nhận"]], value: cf15DateMode, attr: "data-bj15-date-mode", label: "Cách hiểu thời gian" });
  const period = `<button type="button" class="button button--secondary bj15-period" data-bj15-action="period-open" aria-haspopup="dialog" data-ds-component="VButton">${icon("calendar", "icon--sm")}<span>${esc(bj15PeriodLabel())}</span>${icon("chevronDown", "icon--sm")}</button>`;
  const exportBtn = `<button type="button" class="button button--secondary bj15-export" data-bj15-action="export-open" aria-haspopup="dialog" data-ds-component="VButton">Xuất tệp</button>`;
  return `<section class="bj15-toolbar" data-composed-from="VButton,VSegmentedControl,VText"><div class="bj15-toolbar__row">${period}${seg}${exportBtn}</div><p class="bj15-asof" data-ds-component="VText">${esc(bj15PeriodRange())} · Số liệu đến ${esc(BJ15_AS_OF)}</p></section>`;
}

/* ---------- SCR-055 · Báo cáo nhập – xuất – tồn ---------- */

const BJ15_NO_DATA = () => cf15Period.to < BJ15_DATA_START;

function bj15ReportMobileRow(r) {
  return ds24ListRow({ title: r.name, subtitle: `Đầu ${bj15Number(r.opening)} · Nhập ${bj15Number(r.inQty)} · Xuất ${bj15Number(r.outQty)}`, trailing: `<span class="bj15-end">${esc(t7Qty(bj15Number(r.closing), r.uom))}</span>`, leading: null, attrs: `data-bj15-product="${bj15Attr(r.id)}"` });
}
function bj15ReportBody(state) {
  const money = bj15ShowMoney(state), rows = bj15Report(state);
  const showAvail = cf15Period.to >= BJ15_TODAY;
  const search = { value: cf15Query, attr: "data-bj15-search", placeholder: "Tìm sản phẩm" };
  const columns = [
    { key: "product", label: "Sản phẩm", html: true },
    { key: "opening", label: "Đầu kỳ", align: "end", mono: true },
    { key: "inQty", label: "Nhập", align: "end", mono: true },
    { key: "outQty", label: "Xuất", align: "end", mono: true },
    { key: "closing", label: "Cuối kỳ", align: "end", mono: true },
    ...(showAvail ? [{ key: "avail", label: "Khả dụng", align: "end", mono: true }] : []),
    ...(money ? [{ key: "valueText", label: "Giá trị cuối kỳ", align: "end", mono: true }] : []),
  ];
  const view = rows.map((r) => ({ ...r, product: `<strong>${esc(r.name)}</strong><small>${esc(r.code)} · ${esc(r.uom)}</small>`, opening: bj15Number(r.opening), inQty: bj15Number(r.inQty), outQty: bj15Number(r.outQty), closing: bj15Number(r.closing), avail: bj15Number(r.available), valueText: money ? bj15Money(r.value) : "" }));
  const total = rows.reduce((a, r) => a + r.value, 0);
  const list = k6TaskList({
    search, filters: null, columns, rows: view, total: rows.length || 1, mobileRow: (r) => bj15ReportMobileRow(rows.find((x) => x.id === r.id)),
    rowAttr: (r) => `data-bj15-product="${bj15Attr(r.id)}" tabindex="0"`,
    empty: { title: "Không có biến động trong kỳ", description: "Đổi khoảng ngày hoặc sản phẩm để xem dữ liệu khác." },
    filterEmpty: { title: "Không có biến động trong kỳ", description: "Đổi khoảng ngày hoặc sản phẩm để xem dữ liệu khác.", actionLabel: "Xem tất cả", actionAttr: 'data-bj15-action="clear-filter"' },
    filterEmptyAttr: "data-bj15-filter-empty", caption: "Báo cáo nhập – xuất – tồn",
  });
  const totalLine = money ? `<p class="bj15-total" data-ds-component="VText">Tổng giá trị cuối kỳ <strong>${esc(bj15Money(total))}</strong></p>` : "";
  const note = `<p class="bj15-note">Không cộng các số lượng khác đơn vị thành một tổng giả.</p>`;
  return { rows, html: rows.length ? `${list}${totalLine}${note}` : `${ds24Search(cf15Query, "data-bj15-search", "Tìm sản phẩm")}${bj15Empty("FILTER_EMPTY")}` };
}

/* ---------- SCR-055 · Thẻ kho ---------- */

function bj15Strip(l) {
  const item = (label, n) => `<span class="cf12-strip__item">${esc(label)} <strong>${bj15Number(n)}</strong></span>`;
  const dot = '<span class="cf12-strip__dot" aria-hidden="true">·</span>';
  return `<div class="cf12-strip bj15-strip" data-composed-from="DS v2 / Metric Card">${[item("Đầu kỳ", l.opening), item("Nhập", l.inQty), item("Xuất", l.outQty), item("Cuối kỳ", l.closing)].join(dot)}</div>`;
}
function bj15LotChips(p) {
  const lots = bj15Lots(p);
  if (!lots.length) return `<p class="bj15-note">Sản phẩm không quản lý theo lô.</p>`;
  const end = (lot) => bj15Ledger(p.id, { ...bj15Period(), lot }).closing;
  return k7FilterChips({ items: [["ALL", "Tất cả lô", end("ALL")], ...lots.map((l) => [l, `Lô ${l}`, end(l)])], selected: cf15Lot, attrName: "data-bj15-lot" });
}
function bj15DateOf(m, mode = cf15DateMode) { return mode === "RECORDED" ? m.recorded : m.business; }
function bj15OtherDate(m, mode = cf15DateMode) {
  if (m.bIso === m.rIso) return "";
  return mode === "RECORDED" ? `Nghiệp vụ ${bj15Dm(m.bIso)}` : `Ghi nhận ${bj15Dm(m.rIso)}`;
}
function bj15CardRows(p, l) {
  const lotCol = p.tracking === "LOT";
  const edge = (label, n) => ({ edge: true, date: "", doc: "", desc: label, lot: "", inQty: "", outQty: "", stock: bj15Number(n), mobileLabel: label, mobileValue: t7Qty(bj15Number(n), p.stockUom) });
  const body = l.rows.map((m) => ({
    edge: false, id: m.id, date: bj15DateOf(m).split(" · ")[0], doc: m.doc,
    desc: `${m.kind}${m.note ? ` — ${m.note}` : ""}`, lot: m.lot || "—",
    inQty: m.delta > 0 ? bj15Number(m.delta) : "", outQty: m.delta < 0 ? bj15Number(-m.delta) : "", stock: bj15Number(m.balance), m,
  }));
  return { lotCol, rows: [edge("Tồn đầu kỳ", l.opening), ...body, edge("Tồn cuối kỳ", l.closing)] };
}
function bj15CardMobileRow(r, p) {
  if (r.edge) return `<div class="bj15-balance" data-composed-from="VText"><span>${esc(r.mobileLabel)}</span><strong>${esc(r.mobileValue)}</strong></div>`;
  const m = r.m;
  const sub = [bj15DateOf(m), p.tracking === "LOT" && m.lot ? `Lô ${m.lot}` : "", m.actor, bj15OtherDate(m), m.note].filter(Boolean).join(" · ");
  const trailing = `<span class="bj15-mv"><strong class="bj15-mv__delta">${esc(bj15Signed(m.delta))}</strong><small>Tồn ${esc(bj15Number(m.balance))}</small></span>`;
  return ds24ListRow({ title: `${m.kind} ${m.doc}`, subtitle: sub, trailing, leading: null, attrs: `data-bj15-movement="${bj15Attr(m.id)}"` });
}
function bj15CardBody(state) {
  const p = cf15ProductById(cf15SelectedProduct), money = bj15ShowMoney(state);
  const l = bj15Ledger(p.id, { ...bj15Period(), lot: cf15Lot });
  const chips = bj15LotChips(p);
  const strip = bj15Strip(l);
  const value = money ? `<p class="bj15-total" data-ds-component="VText">Giá trị cuối kỳ <strong>${esc(bj15Money(l.closing * bj15UnitCost(p.code)))}</strong></p>` : "";
  if (!l.rows.length) return { empty: true, html: `${chips}${strip}${value}${bj15Empty(state)}` };
  const { lotCol, rows } = bj15CardRows(p, l);
  const dateLabel = cf15DateLabel();
  const columns = [
    { key: "date", label: dateLabel, mono: true }, { key: "doc", label: "Chứng từ", mono: true }, { key: "desc", label: "Diễn giải" },
    ...(lotCol ? [{ key: "lot", label: "Lô" }] : []),
    { key: "inQty", label: "Nhập", align: "end", mono: true }, { key: "outQty", label: "Xuất", align: "end", mono: true }, { key: "stock", label: "Tồn", align: "end", mono: true },
  ].map((c) => ({ ...c, cls: (r) => (r.edge ? "bj15-edge" : "") }));
  const table = k7Table({ columns, rows, mobileRow: (r) => bj15CardMobileRow(r, p), caption: `Thẻ kho ${p.name}`, rowAttr: (r) => (r.edge ? 'class="bj15-edge-row"' : `data-bj15-movement="${bj15Attr(r.id)}" tabindex="0"`) });
  return { empty: false, html: `${chips}${strip}${value}${table}` };
}

/* ---------- Sheet kỳ và sheet xuất ---------- */

function bj15PeriodSheet() {
  const kind = bj15Ui.custom ? "CUSTOM" : bj15PeriodKind();
  const chips = k7FilterChips({ items: [["THIS", "Tháng này"], ["LAST", "Tháng trước"], ["CUSTOM", "Tùy chọn"]], selected: kind, attrName: "data-bj15-period" });
  const c = bj15Ui.custom;
  const fields = c ? `<div class="bj15-dates">${cfField("Từ ngày", c.from, 'data-bj15-from', "date", "", c.fromError ? esc(c.fromError) : "")}${cfField("Đến ngày", c.to, 'data-bj15-to', "date", "", c.toError ? esc(c.toError) : "")}</div>` : "";
  const actions = `<div class="sheet-actions">${cfSecondary("Quay lại", 'data-bj15-action="dialog-close"')}${c ? `<button class="button button--primary" type="button" data-bj15-action="apply-period" data-ds-component="VButton">Áp dụng</button>` : ""}</div>`;
  return ds24Sheet({ title: "Chọn kỳ", attrs: 'data-bj15-action="dialog-close"', body: `${chips}${fields}${actions}` });
}
function bj15ExportSheet(state) {
  const card = bj15Ui.exportScope === "CARD";
  const p = cf15ProductById(cf15SelectedProduct), money = t7ShowMoney() && state !== "FINANCIAL_RESTRICTED";
  const rows = `<div class="bj15-sheet-facts">${ds24InfoRow("Nội dung", card ? `Thẻ kho ${p.name}` : "Báo cáo nhập – xuất – tồn")}${ds24InfoRow("Kỳ", bj15PeriodRange())}${ds24InfoRow("Cách hiểu thời gian", cf15DateLabel())}${ds24InfoRow("Số liệu đến", BJ15_AS_OF)}${ds24InfoRow("Tệp", "CSV")}</div>`;
  const toggle = money ? `<button type="button" class="bj15-check-row" role="checkbox" aria-checked="${bj15Ui.withValue}" data-bj15-action="toggle-value">${k7CheckMark(bj15Ui.withValue)}<span>Kèm giá trị</span></button>` : "";
  const stale = state === "STALE" ? vBanner("warning", "Kết quả đang cập nhật", "Không xuất một file được hiểu nhầm là số liệu mới hơn mốc đang hiển thị.") : "";
  const actions = `<div class="sheet-actions">${cfSecondary("Quay lại", 'data-bj15-action="dialog-close"')}<button class="button button--primary" type="button" data-bj15-action="confirm-export" data-ds-component="VButton">Xuất báo cáo</button></div>`;
  return ds24Sheet({ title: "Xuất báo cáo", attrs: 'data-bj15-action="dialog-close"', body: `${stale}${rows}${toggle}<p class="bj15-note">Tệp xuất giữ đúng bộ lọc, khoảng ngày, quyền và mốc dữ liệu của kết quả đang xem.</p>${actions}` });
}
function bj15SheetHtml(state) {
  if (bj15Ui.sheet === "period") return bj15PeriodSheet();
  if (bj15Ui.sheet === "export") return bj15ExportSheet(state);
  return "";
}

/* ---------- SCR-055 ---------- */

function render055BJ15(state) {
  bj15Seed("SCR-055", state);
  const card = cf15Mode === "CARD", p = cf15ProductById(cf15SelectedProduct);
  const title = card ? "Thẻ kho" : "Báo cáo nhập – xuất – tồn";
  if (state === "PERMISSION_DENIED") return bj15Denied(title);
  const shell = { title: esc(title), subtitle: card ? `${esc(p.name)} · ${esc(p.code)} · ${esc(p.stockUom)}` : null, back: card, backAction: card ? "bj15-card-back" : "", keepBack: card };
  if (state === "LOADING") return bj15Shell({ ...shell, body: k1Loading({ blocks: ["search", "row", "row", "row"] }) });
  const stale = state === "STALE" ? k1Stale({ title: "Dữ liệu đang cập nhật", description: "Dùng mốc dữ liệu bên dưới; không sửa tồn kho từ số liệu chưa cập nhật.", actionLabel: "Tải lại", actionAttr: 'data-bj15-action="reload"' }) : "";
  const archived = state === "ARCHIVED_DATA" ? vBanner("info", "Kỳ đã lưu trữ", `Số liệu chỉ đọc, đến lúc lưu trữ ${BJ15_ARCHIVED_AT}.`) : "";
  const head = `${bj15Toolbar()}${stale}${archived}`;
  let main;
  if (state === "EMPTY" || BJ15_NO_DATA()) main = card ? `${bj15LotChips(p)}${bj15Empty("EMPTY")}` : bj15Empty("EMPTY");
  else main = card ? bj15CardBody(state).html : bj15ReportBody(state).html;
  return bj15Shell({ ...shell, body: `<div class="bj15-screen" data-bj15-mode="${card ? "card" : "report"}">${head}${main}${bj15SheetHtml(state)}</div>` });
}

/* ---------- SCR-056 · {loại} {chứng từ} (gộp nguồn nghiệp vụ) ---------- */

// Nguồn mở được từ chứng từ: phiếu BJ-11 (chi tiết phiếu) và đơn của BJ-05 (chi tiết đơn). Nhận hàng BJ-02 chưa có màn xem chứng từ đã nhận.
function bj15SourceOf(m) {
  if (typeof cr11Operations !== "undefined" && m.opId && cr11Operations.some((o) => o.id === m.opId)) return "UIF-11";
  if (m.sourceFlow === "UIF-05" && typeof io05Orders !== "undefined" && io05Orders.some((o) => o.id === m.doc)) return "UIF-05";
  return null;
}
function bj15CanCorrect(m) {
  const op = typeof cr11Operations !== "undefined" && m.opId ? cr11Operations.find((o) => o.id === m.opId) : null;
  return Boolean(op && op.route === "CORRECT" && !op.dependency && bj11Kind(op) === "CORRECT");
}
// Khối "nhãn — giá trị": số mono căn phải; giá trị chữ (tình trạng, ngày, người) dùng chữ thường. rows: [nhãn, giá trị, là chữ].
function bj15Facts(title, rows) {
  return `<section class="ac310-surface" data-layout-pattern="Grouped surface" data-composed-from="DS v2 / Key-value Row"><div class="ac310-surface__head"><h2>${esc(title)}</h2></div><div class="ac310-key-value-stack">${rows.map(([label, value, text]) => ds24KeyValueRow(label, value, false, text ? 'class="bj15-text"' : "")).join("")}</div></section>`;
}
function bj15Timeline(m, p, after) {
  const move = m.delta === 0 ? "Tồn không đổi" : `${m.delta > 0 ? "Tồn tăng" : "Tồn giảm"} ${t7Qty(bj15Number(Math.abs(m.delta)), p.stockUom)}`;
  return ac310AuditSurface("Nguồn", [ac310AuditItem("Create", m.doc, "Giao dịch nguồn được hoàn tất"), ac310AuditItem("System", "Đã ghi nhận kho", m.recorded), ac310AuditItem("Update", move, `Số dư sau biến động: ${t7Qty(bj15Number(after), p.stockUom)}`)]);
}
function render056BJ15(state) {
  const title = "Chi tiết biến động", back = "bj15-movement-back";
  bj15Seed("SCR-056", state);
  if (state === "PERMISSION_DENIED") return bj15Denied(title, true, "xem chi tiết biến động");
  const m = cf15Movement(), p = cf15ProductById(m.productId), money = bj15ShowMoney(state);
  const head = { title: esc(`${m.kind} ${m.doc}`), subtitle: esc(`${p.name}${p.tracking === "LOT" && m.lot ? ` · Lô ${m.lot}` : ""}`), back: true, backAction: back };
  if (state === "LOADING") return bj15Shell({ ...head, title: esc(title), subtitle: null, body: k1Loading({ blocks: ["heading", "card", "card"] }) });
  if (state === "CONFLICT") return bj15Shell({ ...head, body: k1Stale({ title: "Nguồn nghiệp vụ vừa thay đổi", description: "Tải lại dữ liệu trước khi dựa vào chi tiết đang xem.", actionLabel: "Tải lại", actionAttr: 'data-bj15-action="reload-movement"' }) });
  const bal = bj15Balances(p.id, cf15DateMode)[m.id], u = p.stockUom;
  const locked = state === "LOCKED" ? k1Locked({ title: "Dữ liệu đang ở chế độ chỉ đọc", description: "Bạn có thể xem nguồn và truy vết; màn này không thay đổi dữ liệu." }) : "";
  const quantity = bj15Facts("Số lượng", [["Trước", t7Qty(bj15Number(bal.before), u)], ["Biến động", m.delta === 0 ? t7Qty(0, u) : `${bj15Signed(m.delta)} ${u}`], ["Sau", t7Qty(bj15Number(bal.after), u)], ...(p.tracking === "LOT" && m.lot ? [["Lô", m.lot]] : []), ["Tình trạng", m.state, true]]);
  const who = bj15Facts("Thời gian và người thực hiện", [["Ngày nghiệp vụ", m.business], ["Ngày ghi nhận", m.recorded], ["Người thực hiện", m.actor, true]]);
  const value = money ? bj15Facts("Giá trị", [["Tác động", bj15Money(m.delta * bj15UnitCost(p.code), true)]]) : "";
  const buttons = [];
  if (state !== "LOCKED" && bj15SourceOf(m)) buttons.push({ label: "Mở phiếu gốc", attr: 'data-bj15-action="open-source"' });
  if (state !== "LOCKED" && bj15CanCorrect(m)) buttons.push({ label: "Sửa sai", attr: 'data-bj15-action="correct"', primary: true });
  return bj15Shell({ ...head, body: `${locked}${k7Split({ main: `${quantity}${who}${value}`, aside: bj15Timeline(m, p, bal.after) })}`, actions: buttons.length ? k4Footer(buttons) : "" });
}

/* ---------- SCR-059 · Kết quả xuất báo cáo (K4) ---------- */

function bj15FileName() {
  const k = bj15PeriodKind(), tail = k === "CUSTOM" && bj15PeriodLabel().startsWith("Tháng") ? `${cf15Period.from.slice(5, 7)}${cf15Period.from.slice(0, 4)}` : k === "CUSTOM" ? `${cf15Period.from.replaceAll("-", "")}-${cf15Period.to.replaceAll("-", "")}` : `${cf15Period.from.slice(5, 7)}${cf15Period.from.slice(0, 4)}`;
  return bj15Ui.exportScope === "CARD" ? `the-kho-${cf15ProductById(cf15SelectedProduct).code}-${tail}.csv` : `bao-cao-nhap-xuat-ton-${tail}.csv`;
}
function render059BJ15(state) {
  const title = "Kết quả xuất báo cáo";
  bj15Seed("SCR-059", state);
  if (state === "PERMISSION_DENIED") return bj15Denied(title, false, "xuất báo cáo kho");
  if (state === "PROCESSING") return bj15Shell({ title, body: k1Loading({ blocks: ["heading", "card", "row"] }), back: false });
  const toReport = [{ label: "Về báo cáo", attr: 'data-bj15-action="to-report"', primary: true }];
  if (state === "SOURCE_STALE") return k4Result({ screenTitle: title, kind: "warning", title: "Nguồn dữ liệu đã thay đổi", description: "Không tạo tệp từ kết quả chưa cập nhật. Quay lại báo cáo và tải mốc hiện hành trước khi xuất lại.", facts: [["Tệp", "Chưa tạo"], ["Dữ liệu", "Không bị thay đổi"]], next: toReport });
  if (state === "REJECTED_EXECUTION") return k4Result({ screenTitle: title, kind: "warning", title: "Chưa tạo được tệp", description: "Chưa tạo được tệp nhưng dữ liệu tồn kho không thay đổi.", facts: [["Dữ liệu kho", "Không thay đổi"], ["Có thể thử lại", "Từ cùng báo cáo hiện hành"]], next: toReport });
  return k4Result({ screenTitle: title, title: "Đã tạo tệp báo cáo", description: "Tệp giữ đúng phạm vi, quyền và mốc dữ liệu của kết quả đã xem.", facts: [["Tệp", bj15FileName()], ["Số liệu đến", BJ15_AS_OF], ["Giá trị tài chính", bj15Ui.withValue && t7ShowMoney() ? "Có" : "Không"]], next: toReport });
}

/* ---------- Sự kiện ---------- */

function bj15Rerender(focusSelector = "", { top = false } = {}) {
  const keep = document.querySelector("#app-screen .app-content")?.scrollTop || 0;
  renderAppScreen();
  const content = document.querySelector("#app-screen .app-content"); if (content) content.scrollTop = top ? 0 : keep;
  if (focusSelector) bj15Focus(focusSelector);
}
// getClientRects: phần tử position:fixed (sheet) có offsetParent = null nhưng vẫn hiển thị.
function bj15Visible(el) { return el.getClientRects().length > 0; }
function bj15Focus(selector) {
  const el = [...document.querySelectorAll(selector)].find(bj15Visible);
  if (el) el.focus({ preventScroll: true });
  return el || null;
}
function bj15Go(screenId, state = "READY") { bj15Ui.sheet = null; bj15SetState(screenId, state); return navigate(screenId); }
function bj15OpenSheet(name, opener) {
  bj15Ui.sheet = name; bj15Ui.opener = opener; bj15Ui.custom = null;
  if (name === "export") bj15Ui.exportScope = cf15Mode === "CARD" ? "CARD" : "REPORT";
  renderAppScreen();
  requestAnimationFrame(() => bj15Focus('#app-screen [role="dialog"] button'));
}
function bj15CloseSheet() { const back = bj15Ui.opener; bj15Ui.sheet = null; bj15Ui.custom = null; bj15Rerender(back); }
function bj15SetPeriod(p) { cf15Period = { from: p.from, to: p.to }; bj15Ui.sheet = null; bj15Ui.custom = null; bj15Touch(); bj15Rerender('[data-bj15-action="period-open"]'); }
// Ngày gõ dạng dd/mm/yyyy (hoặc yyyy-mm-dd): trả ISO, hoặc "" khi không đọc được.
function bj15ParseDate(v) {
  const s = String(v || "").trim();
  let m = s.match(/^(\d{2})\/(\d{2})\/(\d{4})$/); if (m) { const iso = `${m[3]}-${m[2]}-${m[1]}`; return new Date(`${iso}T00:00:00`).getDate() === Number(m[1]) ? iso : ""; }
  m = s.match(/^\d{4}-\d{2}-\d{2}$/); return m ? s : "";
}
function bj15ApplyCustom() {
  const c = bj15Ui.custom; if (!c) return;
  const from = bj15ParseDate(c.from), to = bj15ParseDate(c.to);
  c.fromError = from ? "" : "Nhập ngày theo dạng dd/mm/yyyy";
  c.toError = to ? "" : "Nhập ngày theo dạng dd/mm/yyyy";
  if (from && to && from > to) c.fromError = "Ngày bắt đầu phải trước ngày kết thúc";
  if (c.fromError || c.toError) { renderAppScreen(); return bj15Focus(c.fromError ? "[data-bj15-from]" : "[data-bj15-to]"); }
  return bj15SetPeriod({ from, to });
}
function bj15ExportStart() {
  const p = cf15Period; clearTimeout(bj15Timer);
  const stale = stateByScreen["SCR-055"] === "STALE";
  bj15Ui.sheet = null;
  if (stale) return bj15Go("SCR-059", "SOURCE_STALE");
  bj15Go("SCR-059", "PROCESSING");
  bj15Timer = setTimeout(() => bj15FinishExport(), BJ15_EXPORT_MS);
  return p;
}
function bj15FinishExport() {
  clearTimeout(bj15Timer);
  if (activeFlowId !== "UIF-15" || activeScreenId !== "SCR-059" || stateByScreen["SCR-059"] !== "PROCESSING") return false;
  bj15SetState("SCR-059", "COMPLETED"); renderAppScreen(); return true;
}
function bj15OpenProduct(id) {
  cf15Mode = "CARD"; cf15SelectedProduct = id; cf15Lot = "ALL"; bj15Touch();
  bj15Rerender("", { top: true });
}
function bj15CardBack() {
  if (cf15Mode !== "CARD") return;
  if (cf15Entry === "bj01") { bj01SelectedProductId = cf15SelectedProduct; bj01LotOpen = false; bj01ProvenanceOpen = false; return crSwitchFlow("UIF-01", "SCR-003", "READY"); }
  cf15Mode = "REPORT"; cf15Lot = "ALL"; bj15Touch();
  bj15Rerender(`[data-bj15-product="${cf15SelectedProduct}"]`, { top: true });
}
function bj15OpenSource() {
  const m = cf15Movement(), kind = bj15SourceOf(m);
  if (kind === "UIF-11") {
    cr11SelectedId = m.opId; cr11ReturnCase = ""; cr11ReturnMovement = ""; bj11ResetUi();
    bj11SetState("SCR-049", cr11StateFor(cr11Current()));
    return crSwitchFlow("UIF-11", "SCR-049");
  }
  if (kind === "UIF-05") { io05SelectedOrderId = m.doc; return applyEntry("UIF-05", "order-task", true); }
}
function bj15Correct() {
  const m = cf15Movement(); if (!bj15CanCorrect(m)) return;
  cr11SelectedId = m.opId; cr11ReturnMovement = m.id; cr11ReturnCase = "";
  return applyEntry("UIF-11", "correction-from-movement", true);
}

document.addEventListener("keydown", (event) => {
  if (activeFlowId !== "UIF-15") return;
  const t = event.target;
  // Dòng của bảng (khung web) là <tr>: Enter / Space mở như bấm chuột.
  if ((event.key === "Enter" || event.key === " ") && t.matches?.("tr[data-bj15-product], tr[data-bj15-movement]")) { event.preventDefault(); t.click(); }
}, true);

// Sheet là modal: Esc đóng, Tab chỉ đi vòng trong hộp thoại.
window.addEventListener("keydown", (event) => {
  if (activeFlowId !== "UIF-15" || !bj15Ui.sheet) return;
  if (event.key === "Escape") { event.preventDefault(); return bj15CloseSheet(); }
  const dialog = event.key === "Tab" && document.querySelector('#app-screen [role="dialog"]');
  if (!dialog) return;
  const items = [...dialog.querySelectorAll("button:not([disabled]), [href], input, textarea, select, [tabindex]:not([tabindex='-1'])")].filter(bj15Visible);
  if (!items.length) return;
  const first = items[0], last = items[items.length - 1], at = document.activeElement;
  if (event.shiftKey ? (at === first || !dialog.contains(at) || at === dialog) : (at === last || !dialog.contains(at))) { event.preventDefault(); (event.shiftKey ? last : first).focus(); }
}, true);

// Gõ trong ô tìm: dựng lại bảng và giữ con trỏ (không dựng giữa lúc đang gõ bằng bộ gõ tiếng Việt).
function bj15OnSearch(input) {
  cf15Query = input.value; bj15Touch();
  const at = input.selectionStart;
  bj15Rerender("[data-bj15-search]");
  const el = document.querySelector("[data-bj15-search]"); if (el) el.setSelectionRange(at, at);
}
document.addEventListener("input", (event) => {
  if (activeFlowId !== "UIF-15") return;
  const t = event.target;
  if (t.matches?.("[data-bj15-search]")) { if (!event.isComposing) bj15OnSearch(t); return; }
  if (bj15Ui.custom && t.matches?.("[data-bj15-from]")) { bj15Ui.custom.from = t.value; return; }
  if (bj15Ui.custom && t.matches?.("[data-bj15-to]")) { bj15Ui.custom.to = t.value; return; }
}, true);
document.addEventListener("compositionend", (event) => { if (activeFlowId === "UIF-15" && event.target.matches?.("[data-bj15-search]")) bj15OnSearch(event.target); }, true);

document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-15") return;
  const t = event.target, hit = (sel) => t.closest?.(sel);
  let el;
  if ((el = hit("[data-bj15-date-mode]"))) { event.preventDefault(); cf15DateMode = el.dataset.bj15DateMode; bj15Touch(); return bj15Rerender(`[data-bj15-date-mode="${cf15DateMode}"]`); }
  if ((el = hit("[data-bj15-lot]"))) { event.preventDefault(); cf15Lot = el.dataset.bj15Lot; bj15Touch(); return bj15Rerender(`[data-bj15-lot="${cf15Lot}"]`); }
  if ((el = hit("[data-bj15-period]"))) {
    event.preventDefault(); const k = el.dataset.bj15Period;
    if (k === "CUSTOM") { bj15Ui.custom = { from: bj15Dmy(cf15Period.from), to: bj15Dmy(cf15Period.to), fromError: "", toError: "" }; renderAppScreen(); return bj15Focus('[data-bj15-period="CUSTOM"]'); }
    return bj15SetPeriod(k === "LAST" ? BJ15_PERIOD_LAST : BJ15_PERIOD_THIS);
  }
  if ((el = hit("[data-bj15-movement]"))) { event.preventDefault(); cf15SelectedMovement = el.dataset.bj15Movement; return bj15Go("SCR-056", "READY"); }
  if ((el = hit("[data-bj15-product]")) && cf15Mode === "REPORT") { event.preventDefault(); return bj15OpenProduct(el.dataset.bj15Product); }
  if (hit('[data-action="bj15-card-back"]')) { event.preventDefault(); event.stopPropagation(); return bj15CardBack(); }
  if (hit('[data-action="bj15-movement-back"]')) { event.preventDefault(); event.stopPropagation(); return bj15Go("SCR-055", "READY"); }
  const a = hit("[data-bj15-action]"); if (!a) return;
  if (a.matches(".sheet-backdrop") && t !== a) return;
  event.preventDefault(); event.stopPropagation(); if (a.disabled) return;
  const k = a.dataset.bj15Action;
  if (k === "period-open") return bj15OpenSheet("period", '[data-bj15-action="period-open"]');
  if (k === "export-open") return bj15OpenSheet("export", '[data-bj15-action="export-open"]');
  if (k === "dialog-close") return bj15CloseSheet();
  if (k === "apply-period") return bj15ApplyCustom();
  if (k === "toggle-value") { bj15Ui.withValue = !bj15Ui.withValue; renderAppScreen(); return bj15Focus('[data-bj15-action="toggle-value"]'); }
  if (k === "confirm-export") return bj15ExportStart();
  if (k === "to-report") return bj15Go("SCR-055", "READY");
  if (k === "clear-filter") { cf15Query = ""; cf15Lot = "ALL"; bj15Touch(); return bj15Rerender("", { top: true }); }
  if (k === "prev-month") { cf15Period = { ...BJ15_PERIOD_LAST }; bj15Touch(); return bj15Rerender("", { top: true }); }
  if (k === "reload") { bj15SetState("SCR-055", "READY"); bj15Rerender(); return showToast("Đã tải lại số liệu", "info"); }
  if (k === "reload-movement") { bj15SetState("SCR-056", "READY"); bj15Rerender(); return showToast("Đã tải lại số liệu", "info"); }
  if (k === "open-source") return bj15OpenSource();
  if (k === "correct") return bj15Correct();
}, true);

// Đi giữa các màn bằng navigate (kể cả nút quay lại) là đi trong luồng: trạng thái hiện tại là "đã biết", không dựng lại fixture.
["SCR-055", "SCR-056", "SCR-059"].forEach((id) => { onScreenEnter[`UIF-15:${id}`] = () => { bj15Ui.sheet = null; bj15Ui.custom = null; bj15Expected[id] = stateByScreen[id]; }; });
// Quay lại: 056 → thẻ kho; thẻ kho → báo cáo (hoặc BJ-01 khi vào từ đó).
onPrevious["UIF-15"] = () => {
  bj15Ui.sheet = null; bj15Ui.custom = null;
  if (activeScreenId === "SCR-056" || activeScreenId === "SCR-059") return bj15Go("SCR-055", "READY");
  return bj15CardBack();
};

/* ---------- Lối vào ---------- */

// Mở thẻ kho của một sản phẩm (BJ-01 "Xem thẻ kho và lịch sử"); lô đang xem chọn sẵn chip lô.
function bj15OpenCard({ product, lot = "ALL", entry = "bj01" }) { bj15Pending = { mode: "CARD", product, lot, entry }; return applyEntry("UIF-15", "stock-card", true); }
// Mở báo cáo của một kỳ (BJ-14 077 "Xem báo cáo tồn", kỳ "MM/YYYY" của lần tính).
function bj15OpenReport({ period, entry = "bj14" }) { bj15Pending = { mode: "REPORT", period: bj15PeriodOf(period), entry }; return applyEntry("UIF-15", "report", true); }
function bj15ApplyPending() {
  const c = bj15Pending || {}; bj15Pending = null;
  bj15ResetView();
  cf15Mode = c.mode || "REPORT"; cf15Entry = c.entry || "hub";
  if (c.period) cf15Period = c.period;
  if (c.product) cf15SelectedProduct = c.product;
  if (c.lot) cf15Lot = c.lot;
  bj15SetState("SCR-055", "READY");
}
onEntry["UIF-15:stock-card"] = bj15ApplyPending;
onEntry["UIF-15:report"] = bj15ApplyPending;
if (activeFlowId === "UIF-15" && !requestedScreen && onEntry[`UIF-15:${entryMode}`]) onEntry[`UIF-15:${entryMode}`]();
// Hub "Báo cáo tồn & thẻ kho" luôn mở báo cáo của tháng này, không giữ thẻ kho đã xem lần trước.
window.addEventListener("click", (event) => {
  if (event.target.closest?.('[data-theme-entry-flow="UIF-15"]')) { bj15ResetView(); bj15SetState("SCR-055", "READY"); }
}, true);

// 054 / 057 / 058 đã gộp (v5.20.0): đường cũ mở 055 / 056 (058 mở sẵn sheet xuất).
screenAliases["UIF-15"] = Object.assign(screenAliases["UIF-15"] || {}, { "SCR-054": "SCR-055", "SCR-057": "SCR-056", "SCR-058": "SCR-055" });
{
  const old = activeFlowId === "UIF-15" ? activeScreenId : "";
  const a = screenAliases[activeFlowId]?.[activeScreenId]; if (Array.isArray(a)) { activeFlowId = a[0]; activeScreenId = a[1]; } else if (a) activeScreenId = a;
  if (old === "SCR-058") bj15Ui.sheet = "export";
}

Object.assign(renderers, { "SCR-055": render055BJ15, "SCR-059": render059BJ15 });
flowRenderers["UIF-15"] = Object.assign(flowRenderers["UIF-15"] || {}, { "SCR-055": render055BJ15, "SCR-056": render056BJ15, "SCR-059": render059BJ15 });
renderers["SCR-056"] = flowScreen("SCR-056");

Object.assign(window.__VET45_QA__, {
  finishBJ15Export() { return bj15FinishExport(); },
  // Sổ kho theo sản phẩm tại hôm nay và so với tồn BJ-01 hiện tại (golden kiểm bằng một ca).
  getBJ15Ledger() {
    return {
      mode: cf15Mode, period: { ...cf15Period }, dateMode: cf15DateMode, product: cf15SelectedProduct, lot: cf15Lot,
      products: bj01Products.map((p) => { const l = bj15Ledger(p.id, { from: BJ15_DATA_START, to: BJ15_TODAY }); return { name: p.name, code: p.code, closing: l.closing, bj01: p.physical }; }),
      view: bj01Products.map((p) => { const l = bj15Ledger(p.id, bj15Period()); return { name: p.name, opening: l.opening, inQty: l.inQty, outQty: l.outQty, closing: l.closing, balanced: l.opening + l.inQty - l.outQty === l.closing }; }),
    };
  },
});
