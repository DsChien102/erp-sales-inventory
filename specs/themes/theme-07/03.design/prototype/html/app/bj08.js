/* BJ-08 — Kiểm kê và điều chỉnh chênh lệch (UIF-08). Màn: SCR-042…047.
 *
 * Thiết kế lại T7-P chặng 5 (v5.16.0): danh sách phiên theo K6, tạo phiên một biểu mẫu (nói rõ hàng nào bị tạm khoá), đếm mù
 * với ô số tại dòng + quét / tìm, đếm lại chỉ trên dòng lệch ("Vẫn {n}"), duyệt theo K2 (chủ cửa hàng thấy tiền, chủ đếm vẫn tự
 * duyệt được), kết quả theo K4 / K3. Dữ liệu là mảng phiên bj08Sessions (mỗi phiên giữ số đếm, các vòng đếm, kết quả): không còn
 * biến rời. Nhập số không dựng lại màn (giữ focus); số sổ chỉ được đọc trong hàm dựng 045 trở đi (đếm mù: không có trong DOM 044).
 * Dùng từ khuôn: K1, K2 (k2Decision, k2Pending, k2Attention, k2RejectSheet, nguồn "Chờ duyệt"), K3, K4, K6, K7, dsSegmented, dsChoiceRow, cf12Strip.
 * Fixture chung chặng 5 (mỗi sản phẩm một câu chuyện): xem BJ08_CATALOG và bj08Initial; plan T7-P-bj08-kiem-ke.md mục 3.
 */

{ const sc = screens.find((x) => x.id === "SCR-046"); if (sc) sc.states = [...new Set([...(sc.states || []), "APPROVAL_REVIEW"])]; }

const BJ08_STAFF = "Nguyễn Văn An";
const BJ08_OWNER = "Chủ cửa hàng";
const BJ08_MEMBERS = [BJ08_STAFF, "Trần Thị Bình", BJ08_OWNER];
const BJ08_OPENED_AT = "17/09/2026 18:30";
const BJ08_FIRST_AT = "17/09/2026 19:05";
const BJ08_RECOUNT_AT = "17/09/2026 19:20";
const BJ08_APPROVED_AT = "17/09/2026 20:10";
const BJ08_CANCELLED_AT = "17/09/2026 19:10";
const BJ08_SCOPE_KINDS = [["ALL", "Toàn kho"], ["GROUP", "Nhóm sản phẩm"], ["PRODUCT", "Sản phẩm"], ["LOT", "Lô"]];
const BJ08_UNEXPECTED_STATES = [["SELLABLE", "Bán được"], ["QUARANTINE", "Cách ly"], ["DAMAGED", "Hỏng"]];
const BJ08_STATUS = { COUNTING: ["Đang đếm", "Info"], RECOUNT: ["Đếm lại", "Warning"], PENDING: ["Chờ duyệt", "Warning"], DONE: ["Đã xong", "Success"], CANCELLED: ["Đã hủy", "Neutral"] };
const BJ08_FILTERS = {
  ALL: () => true,
  COUNTING: (s) => s.status === "COUNTING" || s.status === "RECOUNT",
  PENDING: (s) => s.status === "PENDING",
  DONE: (s) => s.status === "DONE" || s.status === "CANCELLED",
};

/* ---------- Fixture chung chặng 5 ---------- */

// Mã / lô / ĐVT khớp t7Lots và BJ-01; số sổ là của riêng BJ-08. Dầu sát khuẩn không có unitCost (chặng 4) → hàng thừa không có giá vốn.
const BJ08_CATALOG = [
  { key: "oxy", name: "Oxytetracycline LA", code: "SP-000147", lot: "", state: "SELLABLE", uom: "chai", book: 12, unitCost: 55000 },
  { key: "ty2511", name: "Tylosin 20%", code: "SP-000122", lot: "TY2511", state: "SELLABLE", uom: "lọ", book: 3, unitCost: 85000 },
  { key: "ty2408", name: "Tylosin 20%", code: "SP-000122", lot: "TY2408", state: "EXPIRED", uom: "lọ", book: 11, unitCost: 85000 },
  { key: "glove", name: "Găng tay khám Nitrile", code: "SP-000271", lot: "", state: "SELLABLE", uom: "hộp", book: 10, unitCost: 65000 },
  { key: "oil", name: "Dầu sát khuẩn", code: "SP-00606", lot: "L2406-T", state: "DEMO", uom: "chai", book: 2 },
  { key: "nob-dh2507", name: "Nobivac DHPPi", code: "SP-000184", lot: "DH2507", state: "SELLABLE", uom: "hộp", book: 70, unitCost: 118000 },
  { key: "nob-dh2509", name: "Nobivac DHPPi", code: "SP-000184", lot: "DH2509", state: "SELLABLE", uom: "hộp", book: 50, unitCost: 118000 },
  { key: "amox", name: "Amox 500", code: "SP-000066", lot: "", state: "SELLABLE", uom: "hộp", book: 46, unitCost: 42000 },
  { key: "amox-am2505", name: "Amox 500", code: "SP-000066", lot: "AM2505", state: "QUARANTINE", uom: "hộp", book: 2, unitCost: 42000 },
];
const BJ08_GROUPS = [
  ["antibiotic", "Thuốc kháng sinh", ["oxy", "ty2511", "ty2408"]],
  ["supplies", "Nhóm vật tư", ["glove", "oil"]],
  ["vaccine", "Nhóm vaccine", ["nob-dh2507", "nob-dh2509"]],
];
// "Thêm hàng thực tế": hàng có thật ngoài danh sách sổ. Dầu sát khuẩn chưa có giá vốn, Amox có.
const BJ08_EXTRAS = [
  { name: "Dầu sát khuẩn", code: "SP-00606", lot: "L2406-T", uom: "chai" },
  { name: "Amox 500", code: "SP-000066", lot: "", uom: "hộp", unitCost: 42000 },
];

const bj08Sessions = [];
let bj08Seq = 1;
let bj08SelectedId = "";
let bj08ListQuery = "", bj08ListFilter = "ALL";
let bj08Draft = null;
let bj08ConflictId = "";
let bj08Dialog = null;            // "open" | "first" | "recount" | "cancel" | "review" | "scope" | "add" | "scan" | "matched"
let bj08CancelReason = "", bj08ReviewReason = "";
let bj08CountFilter = "TODO", bj08Find = "", bj08ScopeFind = "", bj08FocusKey = "";

const bj08Num = (v) => Number(String(v ?? "").replace(",", ".")) || 0;
const bj08Filled = (v) => String(v ?? "").trim() !== "";
const bj08Valid = (v) => bj08Filled(v) && Number.isFinite(Number(String(v).replace(",", "."))) && Number(String(v).replace(",", ".")) >= 0;
const bj08Attr = (v) => escapeAttribute(String(v ?? ""));
function bj08CanDecide() { return ["approver", "owner"].includes(currentActor()); }
function bj08ShowMoney() { return t7ShowMoney(); }
function bj08ActorName() { return bj08CanDecide() ? BJ08_OWNER : BJ08_STAFF; }
function bj08FmtAbs(n) { return `${Math.round(Math.abs(n)).toLocaleString("vi-VN")} đ`; }
function bj08FmtSigned(n) { return `${n < 0 ? "−" : n > 0 ? "+" : ""}${bj08FmtAbs(n)}`; }
// Mọi chuỗi tiền dựng qua hàm này: người không xem được tiền nhận chuỗi rỗng (không có phần tử nào mang số tiền trong DOM).
function bj08Money(n, abs = false) { if (!bj08ShowMoney() || n == null) return ""; return abs ? bj08FmtAbs(n) : bj08FmtSigned(n); }
function bj08Session(id = bj08SelectedId) { return bj08Sessions.find((s) => s.id === id) || null; }
function bj08LotText(l) { return l.lot ? `Lô ${l.lot}` : "Không theo lô"; }
function bj08LineName(l) { return `${l.name}${l.lot ? ` · Lô ${l.lot}` : ""}`; }
function bj08StateLabel(l) { return l.state ? t7LotStateLabel(l.state) : "Chưa chọn tình trạng"; }
function bj08LineSub(l) { return `${l.code} · ${bj08LotText(l)} · ${bj08StateLabel(l)}`; }

/* ---------- Phạm vi ---------- */

function bj08ScopeKeys(kind, target) {
  if (kind === "ALL") return BJ08_CATALOG.map((c) => c.key);
  if (kind === "GROUP") return (BJ08_GROUPS.find((g) => g[0] === target) || [null, null, []])[2];
  if (kind === "PRODUCT") return BJ08_CATALOG.filter((c) => c.code === target).map((c) => c.key);
  return BJ08_CATALOG.filter((c) => c.key === target).map((c) => c.key);
}
function bj08ScopeLabel(kind, target) {
  if (kind === "ALL") return "Toàn kho";
  if (kind === "GROUP") return (BJ08_GROUPS.find((g) => g[0] === target) || [null, ""])[1];
  const c = BJ08_CATALOG.find((x) => (kind === "PRODUCT" ? x.code === target : x.key === target));
  if (!c) return "";
  return kind === "PRODUCT" ? c.name : bj08LineName(c);
}
function bj08ScopeOptions(kind) {
  if (kind === "GROUP") return BJ08_GROUPS.map(([key, title, keys]) => ({ key, title, subtitle: `${keys.length} mặt hàng` }));
  if (kind === "PRODUCT") {
    const codes = [...new Set(BJ08_CATALOG.map((c) => c.code))];
    return codes.map((code) => { const rows = BJ08_CATALOG.filter((c) => c.code === code); return { key: code, title: rows[0].name, subtitle: `${code} · ${rows.length} mặt hàng` }; });
  }
  return BJ08_CATALOG.map((c) => ({ key: c.key, title: bj08LineName(c), subtitle: c.code }));
}
function bj08DraftKeys() { return bj08ScopeKeys(bj08Draft.kind, bj08Draft.target); }
function bj08DraftScopeKnown() { return bj08Draft.kind === "ALL" || Boolean(bj08Draft.target); }

/* ---------- Phiên: dựng, tính chênh lệch ---------- */

function bj08Make({ id, scope, counter, openedAt, keys, reason }) {
  return { id, scope, counter, openedAt, reason: reason || "Kiểm kê định kỳ", status: "COUNTING", lines: keys.map((k) => structuredClone(BJ08_CATALOG.find((c) => c.key === k))), counts: {}, recounts: {}, rounds: [], contributors: [counter], reviews: [], result: null };
}
function bj08Initial() {
  const allKeys = BJ08_CATALOG.map((c) => c.key);
  const inProgress = bj08Make({ id: "KK-260916-01", scope: { kind: "ALL", label: "Toàn kho" }, counter: "Trần Thị Bình", openedAt: "16/09/2026 18:10", keys: allKeys });
  Object.assign(inProgress.counts, { "nob-dh2507": "70", "nob-dh2509": "50", amox: "46", "amox-am2505": "2" });
  const pending = bj08Make({ id: "KK-260915-02", scope: { kind: "GROUP", label: "Nhóm vật tư" }, counter: BJ08_STAFF, openedAt: "15/09/2026 16:30", keys: ["glove", "oil"] });
  pending.rounds = [
    { round: 1, type: "FIRST", actor: BJ08_STAFF, at: "15/09/2026 16:55", values: { glove: "8", oil: "2" } },
    { round: 2, type: "RECOUNT", actor: BJ08_STAFF, at: "15/09/2026 17:40", values: { glove: "9" } },
  ];
  pending.counts = { ...pending.rounds[0].values };
  pending.status = "PENDING"; pending.sentAt = "15/09/2026 17:40"; pending.sentBy = BJ08_STAFF;
  const done = bj08Make({ id: "KK-260830-01", scope: { kind: "ALL", label: "Toàn kho" }, counter: BJ08_STAFF, openedAt: "30/08/2026 18:00", keys: allKeys });
  done.rounds = [{ round: 1, type: "FIRST", actor: BJ08_STAFF, at: "30/08/2026 19:20", values: Object.fromEntries(done.lines.map((l) => [l.key, String(l.book)])) }];
  done.counts = { ...done.rounds[0].values };
  done.status = "DONE"; done.result = { type: "ZERO", committedAt: "30/08/2026 19:20" };
  return [inProgress, pending, done];
}
// Số đếm hiện hành của từng dòng = vòng đếm gần nhất có dòng đó.
function bj08Eff(s) { const eff = {}; s.rounds.forEach((r) => Object.assign(eff, r.values)); return eff; }
function bj08Variance(s, eff = bj08Eff(s)) {
  return s.lines.filter((l) => bj08Filled(eff[l.key]) && bj08Num(eff[l.key]) !== l.book).map((l) => {
    const count = bj08Num(eff[l.key]), variance = count - l.book;
    return { line: l, count, variance, value: l.unitCost ? variance * l.unitCost : null };
  });
}
function bj08MatchedLines(s, eff = bj08Eff(s)) { return s.lines.filter((l) => bj08Filled(eff[l.key]) && bj08Num(eff[l.key]) === l.book); }
function bj08Totals(s) {
  const v = bj08Variance(s);
  const money = v.filter((x) => x.value != null);
  return { lines: v.length, short: v.filter((x) => x.variance < 0).length, over: v.filter((x) => x.variance > 0).length, net: money.reduce((a, x) => a + x.value, 0), abs: money.reduce((a, x) => a + Math.abs(x.value), 0), hasMoney: money.length > 0 };
}
function bj08PriceMissing(s) { return bj08Variance(s).find((x) => x.variance > 0 && !x.line.unitCost) || null; }
function bj08CountedN(s) { return s.lines.filter((l) => bj08Filled(s.counts[l.key])).length; }
function bj08RecountN(s) { return s.rounds.filter((r) => r.type === "RECOUNT").length; }
function bj08ListSub(s) {
  const tail = s.status === "COUNTING" ? `Đã đếm ${bj08CountedN(s)}/${s.lines.length}` : `${bj08Variance(s).length} mặt hàng lệch`;
  return `${s.scope.label} · ${s.counter} · ${tail}`;
}
function bj08VarianceBadge(x) { return ds24Badge(`${x.variance < 0 ? "Thiếu" : "Thừa"} ${t7Qty(Math.abs(x.variance), x.line.uom)}`, "Warning"); }

/* ---------- Chuyển trạng thái phiên (hệ thống) ---------- */

function bj08Finish(s, result) { s.status = "DONE"; s.result = result; }
function bj08FirstBlocker(s) {
  const missing = s.lines.filter((l) => !bj08Valid(s.counts[l.key])).length;
  if (missing) return `Còn ${missing} mặt hàng chưa đếm`;
  if (s.lines.some((l) => l.unexpected && bj08Num(s.counts[l.key]) > 0 && !l.state)) return "Chọn tình trạng cho hàng thực tế";
  return "";
}
function bj08RecountBlocker(s) {
  const missing = bj08Variance(s).filter((x) => !bj08Valid(s.recounts[x.line.key])).length;
  return missing ? `Còn ${missing} mặt hàng chưa đếm lại` : "";
}
// Nộp lần đếm đầu: ghi một vòng, khớp hết → xong; còn lệch → đếm lại.
function bj08CommitFirst(s) {
  s.rounds.push({ round: 1, type: "FIRST", actor: s.counter, at: BJ08_FIRST_AT, values: { ...s.counts } });
  if (!bj08Variance(s).length) { bj08Finish(s, { type: "ZERO", committedAt: BJ08_FIRST_AT }); return "ZERO"; }
  s.status = "RECOUNT"; s.recounts = {};
  return "RECOUNT";
}
// Gửi đếm lại: chỉ ghi các dòng lệch; khớp hết → xong; còn lệch → chờ duyệt.
function bj08CommitRecount(s) {
  const values = {};
  bj08Variance(s).forEach((x) => { values[x.line.key] = s.recounts[x.line.key]; });
  s.rounds.push({ round: s.rounds.length + 1, type: "RECOUNT", actor: s.counter, at: BJ08_RECOUNT_AT, values });
  s.recounts = {};
  if (!bj08Variance(s).length) { bj08Finish(s, { type: "ZERO", committedAt: BJ08_RECOUNT_AT }); return "ZERO"; }
  s.status = "PENDING"; s.sentAt = BJ08_RECOUNT_AT; s.sentBy = s.counter;
  return "PENDING";
}
function bj08ApproveSession(s) {
  const t = bj08Totals(s);
  bj08Finish(s, { type: "ADJUSTED", lines: t.lines, short: t.short, over: t.over, net: t.net, hasMoney: t.hasMoney, approver: BJ08_OWNER, committedAt: BJ08_APPROVED_AT });
}
function bj08RequestRecount(s, reason) { s.reviews.push({ reason, at: BJ08_APPROVED_AT }); s.status = "RECOUNT"; s.recounts = {}; }
function bj08CancelSession(s, reason) { s.status = "CANCELLED"; s.result = { type: "CANCELLED", reason, committedAt: BJ08_CANCELLED_AT }; }
function bj08CreateFrom(draft) {
  const s = bj08Make({ id: `KK-260917-${String(bj08Seq++).padStart(2, "0")}`, scope: { kind: draft.kind, label: bj08ScopeLabel(draft.kind, draft.target) }, counter: draft.counter, openedAt: BJ08_OPENED_AT, keys: bj08ScopeKeys(draft.kind, draft.target), reason: draft.reason.trim() });
  bj08Sessions.unshift(s); bj08SelectedId = s.id;
  return s;
}
function bj08AddUnexpected(s, extra) {
  const key = `x-${extra.code}`;
  if (s.lines.some((l) => l.key === key)) return key;
  s.lines.push({ key, name: extra.name, code: extra.code, lot: extra.lot, state: "", uom: extra.uom, book: 0, unitCost: extra.unitCost, unexpected: true });
  s.counts[key] = "";
  return key;
}

/* ---------- Giao diện: nhớ tạm, dựng lại fixture khi trạng thái đặt từ ngoài ---------- */

function bj08NewDraft() { return { kind: "ALL", target: "", counter: bj08ActorName(), reason: "Kiểm kê định kỳ" }; }
function bj08ResetUi() { bj08Dialog = null; bj08CancelReason = ""; bj08ReviewReason = ""; bj08CountFilter = "TODO"; bj08Find = ""; bj08ScopeFind = ""; bj08FocusKey = ""; }
function bj08Restore() {
  bj08Sessions.splice(0, bj08Sessions.length, ...bj08Initial());
  bj08Seq = 1; bj08SelectedId = ""; bj08ListQuery = ""; bj08ListFilter = "ALL"; bj08ConflictId = ""; bj08Draft = bj08NewDraft(); bj08ResetUi();
}
const bj08Expected = {};
function bj08SetState(screenId, state) { stateByScreen[screenId] = state; bj08Expected[screenId] = state; }
const BJ08_SAMPLE_FIRST = { oxy: "10", ty2511: "4", ty2408: "11" };
const BJ08_SAMPLE_RECOUNT = { oxy: "10", ty2511: "3" };
// Phiên mẫu "Thuốc kháng sinh" đi tới bước stage: 0 mới mở · 1 đã nộp lần đầu · 2 đã gửi đếm lại (chờ duyệt) · 3 đã duyệt.
function bj08SeedSession(stage) {
  const s = bj08CreateFrom({ kind: "GROUP", target: "antibiotic", counter: BJ08_STAFF, reason: "Kiểm kê định kỳ" });
  if (stage >= 1) { s.counts = { ...BJ08_SAMPLE_FIRST }; bj08CommitFirst(s); }
  if (stage >= 2) { s.recounts = { ...BJ08_SAMPLE_RECOUNT }; bj08CommitRecount(s); }
  if (stage >= 3) bj08ApproveSession(s);
  return s;
}
function bj08Seed(screenId, state) {
  if (bj08Expected[screenId] === state) return;
  Object.keys(bj08Expected).forEach((k) => delete bj08Expected[k]);
  bj08Expected[screenId] = state;
  bj08Restore();
  if (screenId === "SCR-043") {
    if (state === "VALIDATION_ERROR") bj08Draft = { ...bj08NewDraft(), kind: "GROUP", reason: "" };
    if (state === "CONFLICT") bj08ConflictId = "KK-260916-01";
    return;
  }
  if (screenId === "SCR-044") {
    const s = bj08SeedSession(0);
    if (state === "VALIDATION_ERROR") s.counts.oxy = "10";
    return;
  }
  if (screenId === "SCR-045") {
    const s = bj08SeedSession(0);
    if (state === "PRICE_BASIS_REQUIRED") { const key = bj08AddUnexpected(s, BJ08_EXTRAS[0]); s.lines.find((l) => l.key === key).state = "SELLABLE"; s.counts = { ...BJ08_SAMPLE_FIRST, [key]: "1" }; }
    else s.counts = { ...BJ08_SAMPLE_FIRST };
    bj08CommitFirst(s);
    return;
  }
  if (screenId === "SCR-046") { bj08SelectedId = "KK-260915-02"; return; }
  if (screenId === "SCR-047") {
    if (state === "CANCELLED") { const s = bj08SeedSession(0); bj08CancelSession(s, "Sai phạm vi phiên"); return; }
    bj08SeedSession(state === "COMPLETED" ? 3 : 2);
  }
}
bj08Restore();

/* ---------- Khung dùng chung ---------- */

function bj08Shell(opts) { return appShell({ extraClass: "k7-wide", ...opts }); }
function bj08Denied(title, back = false) { return bj08Shell({ title, body: k1Denied({ what: "kiểm kê", next: "Liên hệ chủ cửa hàng để được cấp quyền.", exitAttr: k1ExitAttr("SCR-042") }), centered: true, back }); }
function bj08Loading(title, blocks, back = false) { return bj08Shell({ title, body: k1Loading({ blocks }), centered: true, back }); }
function bj08Lead(text) { return `<p class="bj08-lead">${esc(text)}</p>`; }
function bj08Progress(done, total) {
  if (!total) return "";
  return `<div class="bj02-progress-block bj08-progress" data-ds-component="VProgress"><div class="bj02-progress" role="progressbar" aria-label="Tiến độ đếm" aria-valuemin="0" aria-valuemax="${total}" aria-valuenow="${done}"><span style="width:${Math.round(done / total * 100)}%"></span></div><small data-bj08-progress-text>Đã đếm ${done}/${total} mặt hàng</small></div>`;
}
function bj08CancelLink() { return `<button class="bj08-cancel-link" type="button" data-bj08-action="cancel-open" data-action-contract="ACT-09-CANCEL">Hủy phiên</button>`; }
function bj08Subtitle(s, extra = "") { return `${s.id} · ${extra || `${s.scope.label} · ${s.counter}`}`; }
function bj08ToList() { return { label: "Về kiểm kê", attr: 'data-bj08-action="to-list"' }; }
function bj08ExitFooter(primary = true) { return k4Footer([{ ...bj08ToList(), primary }]); }
function bj08NoSession(title) { return bj08Shell({ title, body: k1Locked({ title: "Không có phiên kiểm kê", description: "Mở lại từ danh sách phiên kiểm kê." }), back: false, actions: bj08ExitFooter() }); }

/* ---------- SCR-042 · Kiểm kê kho (K6) ---------- */

function render042BJ08(state) {
  if (activeFlowId !== "UIF-08") return renderGeneric(screens.find((s) => s.id === "SCR-042"), state);
  const title = "Kiểm kê kho";
  bj08Seed("SCR-042", state);
  if (state === "PERMISSION_DENIED") return bj08Denied(title);
  if (state === "LOADING") return bj08Shell({ title, body: k1Loading({ blocks: ["search", "row", "row", "row"] }), back: false });
  const all = state === "EMPTY" ? [] : bj08Sessions;
  const q = ioNormalizeSearch(bj08ListQuery);
  const text = (s) => ioNormalizeSearch(`${s.id} ${s.scope.label} ${s.counter}`);
  const rows = state === "FILTER_EMPTY" ? [] : all.filter((s) => BJ08_FILTERS[bj08ListFilter](s) && (!q || text(s).includes(q))).map((s) => {
    const [label, tone] = BJ08_STATUS[s.status];
    return { id: s.id, title: s.id, subtitle: bj08ListSub(s), status: { label, tone }, scope: s.scope.label, counter: s.counter, progress: s.status === "COUNTING" ? `${bj08CountedN(s)}/${s.lines.length}` : `${bj08Variance(s).length} lệch`, openedAt: s.openedAt, statusHtml: ds24Badge(label, tone), searchText: text(s) };
  });
  const count = (key) => all.filter(BJ08_FILTERS[key]).length;
  const items = [["ALL", "Tất cả"], ["COUNTING", "Đang đếm"], ["PENDING", "Chờ duyệt"], ["DONE", "Đã xong"]].map(([k, l]) => [k, l, count(k)]);
  const columns = [{ key: "title", label: "Phiên", mono: true }, { key: "scope", label: "Phạm vi" }, { key: "counter", label: "Người đếm" }, { key: "progress", label: "Đã đếm", align: "end", mono: true }, { key: "openedAt", label: "Mở lúc", mono: true }, { key: "statusHtml", label: "Tình trạng", html: true }];
  const body = k6TaskList({
    search: { value: bj08ListQuery, attr: "data-bj08-search", placeholder: "Tìm phiên kiểm kê" },
    filters: { items, selected: bj08ListFilter, attrName: "data-bj08-filter" },
    columns, rows, total: all.length,
    rowAttr: (r) => `data-bj08-row="${bj08Attr(r.id)}" data-bj08-search-text="${bj08Attr(r.searchText)}"`,
    empty: { title: "Chưa có phiên kiểm kê", description: "Tạo phiên để đếm toàn kho hoặc một nhóm hàng." },
    filterEmpty: { title: "Không tìm thấy phiên kiểm kê", description: "Thử từ khóa hoặc bộ lọc khác.", actionLabel: "Xem tất cả", actionAttr: 'data-bj08-action="clear-filter"' },
    filterEmptyAttr: "data-bj08-filter-empty",
  });
  return bj08Shell({ title, body, back: false, centered: state === "EMPTY", actions: primaryFooter("Tạo phiên kiểm kê", 'data-bj08-action="create"') });
}

/* ---------- SCR-043 · Tạo phiên kiểm kê ---------- */

function bj08DraftBlocker() {
  if (!bj08DraftScopeKnown()) return "Chọn phạm vi cụ thể";
  if (!bj08Draft.reason.trim()) return "Nhập lý do kiểm kê";
  return "";
}
function bj08ScopeBlock(showError) {
  const known = bj08DraftScopeKnown(), n = bj08DraftKeys().length;
  const rows = BJ08_SCOPE_KINDS.map(([kind, label]) => dsChoiceRow({
    title: label,
    subtitle: kind === bj08Draft.kind && known ? `${n} mặt hàng` : kind === "ALL" ? `${BJ08_CATALOG.length} mặt hàng` : "",
    selected: bj08Draft.kind === kind, attrs: `data-bj08-scope="${kind}"`,
  })).join("");
  const targetName = bj08Draft.target ? bj08ScopeLabel(bj08Draft.kind, bj08Draft.target) : "";
  const pick = bj08Draft.kind === "ALL" ? "" : targetName
    ? `<button class="button button--secondary bj08-scope-pick" type="button" data-bj08-action="scope-open"><span>${esc(targetName)}</span><em>Đổi</em></button>`
    : `<button class="button button--secondary bj08-scope-pick" type="button" data-bj08-action="scope-open">Chọn phạm vi cụ thể</button>`;
  const err = showError && !known ? `<small class="field-error" role="alert">Chọn phạm vi cụ thể</small>` : "";
  return `<section class="bj06-section">${ds24SectionTitle("Phạm vi")}<div class="ds-choice-list" role="radiogroup" aria-label="Phạm vi">${rows}</div>${pick}${err}</section>`;
}
function bj08LockNotice() {
  if (!bj08DraftScopeKnown()) return "";
  return k2Attention([[`Tạm khoá ${bj08DraftKeys().length} mặt hàng: không nhận, xuất hay bán được cho tới khi kiểm xong.`, ""], ["Số theo sổ được chốt lúc mở phiên.", "", "info"]], { title: "Khi mở phiên" });
}
function bj08ScopeSummary() {
  const keys = bj08DraftKeys(), known = bj08DraftScopeKnown();
  const lines = keys.map((k) => BJ08_CATALOG.find((c) => c.key === k));
  const shown = lines.slice(0, 8).map((l) => `<li>${esc(bj08LineName(l))}</li>`).join("");
  const more = lines.length > 8 ? `<li class="bj08-scope-items__more">và ${lines.length - 8} mặt hàng khác</li>` : "";
  const list = known ? `<div class="bj08-scope-items"><h3>Mặt hàng trong phạm vi</h3><ul>${shown}${more}</ul></div>` : "";
  return `${ac310KeyValueSurface("Tóm tắt", [["Phạm vi", known ? bj08ScopeLabel(bj08Draft.kind, bj08Draft.target) : "—"], ["Người đếm", bj08Draft.counter]])}${list}`;
}
function render043BJ08(state) {
  if (activeFlowId !== "UIF-08") return renderGeneric(screens.find((s) => s.id === "SCR-043"), state);
  const title = "Tạo phiên kiểm kê";
  bj08Seed("SCR-043", state);
  if (state === "PERMISSION_DENIED") return bj08Denied(title, true);
  if (state === "COUNT_SCOPE_HAS_UNRESOLVED_VALUATION") {
    const body = vBanner("warning", "Chưa thể mở phiên", "Phạm vi còn hàng chờ xác nhận giá trị. Hoàn tất phần giá trị hàng nhận trước khi kiểm kê.");
    const back = { ...bj08ToList(), primary: !bj08CanDecide() };
    const actions = k4Footer(bj08CanDecide() ? [back, { label: "Mở hàng chờ xác lập giá trị", attr: 'data-bj08-action="to-valuation"', primary: true }] : [back]);
    return bj08Shell({ title, body, actions });
  }
  const showError = state === "VALIDATION_ERROR";
  const blocker = bj08DraftBlocker();
  const conflict = state === "CONFLICT" ? (() => { const c = bj08Session(bj08ConflictId); return k1Stale({ title: "Phạm vi đang có phiên khác", description: `${c ? c.id : bj08ConflictId} đang kiểm ${c ? c.scope.label : "phạm vi này"}. Mở phiên đó hoặc chọn phạm vi khác.`, actionLabel: "Mở phiên đang kiểm", actionAttr: 'data-bj08-action="open-conflict"' }); })() : "";
  const reasonError = showError && !bj08Draft.reason.trim() ? "Nhập lý do kiểm kê" : "";
  const form = `<div class="bj08-form">${conflict}${bj08ScopeBlock(showError)}${cfSelect("Người đếm", bj08Draft.counter, BJ08_MEMBERS.map((m) => [m, esc(m)]), 'data-bj08-counter aria-label="Người đếm"')}${cfField("Lý do kiểm kê", bj08Draft.reason, 'data-bj08-reason aria-label="Lý do kiểm kê"', "text", "", reasonError)}<div data-bj08-lock>${bj08LockNotice()}</div></div>`;
  const body = `${k7Split({ main: form, aside: bj08ScopeSummary(), asideWebOnly: true })}${bj08Overlays()}`;
  return bj08Shell({ title, body, actions: k4ReasonFooter({ label: "Mở phiên kiểm kê", attr: 'data-bj08-action="open"', disabled: Boolean(blocker), reason: blocker }) });
}

/* ---------- SCR-044 · Đếm mù ---------- */

function bj08EditCell(s, l, value, attr, error) {
  return k7EditCell({ value, attr: `${attr}="${bj08Attr(l.key)}" enterkeyhint="next"`, unit: l.uom, error, label: `Số lượng thực tế — ${bj08LineName(l)}` });
}
function bj08UnexpectedState(l) {
  return dsSegmented({ items: BJ08_UNEXPECTED_STATES, value: l.state, attr: `data-bj08-for="${bj08Attr(l.key)}" data-bj08-unexpected-state`, label: `Tình trạng — ${bj08LineName(l)}` });
}
function bj08CountVisible(s, forceAll = false) {
  const q = ioNormalizeSearch(bj08Find);
  return s.lines.filter((l) => {
    const done = bj08Filled(s.counts[l.key]);
    if (!forceAll && bj08CountFilter === "TODO" && done) return false;
    if (!forceAll && bj08CountFilter === "DONE" && !done) return false;
    return !q || ioNormalizeSearch(`${l.name} ${l.code} ${l.lot}`).includes(q);
  });
}
function bj08CountChips(s) {
  const a = bj08CountedN(s), b = s.lines.length;
  return k7FilterChips({ items: [["TODO", "Chưa đếm", b - a], ["DONE", "Đã đếm", a], ["ALL", "Tất cả", b]], selected: bj08CountFilter, attrName: "data-bj08-count-filter" });
}
function bj08ScanButton() { return `<button type="button" class="ds24-search__action" data-bj08-action="scan-open" aria-label="Quét mã vạch">${icon("scan", "icon--sm")}</button>`; }
function bj08LineCopy(name, sub, tag = "") { return `<div class="bj08-line__copy"><strong>${esc(name)}</strong><small>${esc(sub)}</small>${tag}</div>`; }
function bj08CountRow(s, l, showError) {
  const value = s.counts[l.key] ?? "", error = showError && !bj08Valid(value) ? "Nhập số đếm được" : "";
  const text = bj08Attr(ioNormalizeSearch(`${l.name} ${l.code} ${l.lot}`));
  const tag = l.unexpected ? ds24Badge("Hàng thực tế", "Info") : "";
  const state = l.unexpected ? `<div class="bj08-line__state"><span class="vet45-text-style-8">Tình trạng</span>${bj08UnexpectedState(l)}</div>` : "";
  const mobile = `<div class="bj08-line" data-bj08-line="${bj08Attr(l.key)}" data-bj08-line-text="${text}">${bj08LineCopy(l.name, bj08LineSub(l), tag)}<div class="bj08-line__field">${bj08EditCell(s, l, value, "data-bj08-count", error)}</div>${state}</div>`;
  return { key: l.key, text, mobile, product: `<strong>${esc(l.name)}</strong><small>${esc(l.code)}</small>${tag}`, lot: esc(bj08LotText(l)), stateHtml: l.unexpected ? bj08UnexpectedState(l) : esc(bj08StateLabel(l)), count: bj08EditCell(s, l, value, "data-bj08-count", error) };
}
function bj08CountFooter(s) {
  const blocker = bj08FirstBlocker(s);
  return k4ReasonFooter({ label: "Nộp kết quả đếm", attr: 'data-bj08-action="submit-first"', disabled: Boolean(blocker), reason: blocker });
}
function render044BJ08(state) {
  if (activeFlowId !== "UIF-08") return renderGeneric(screens.find((s) => s.id === "SCR-044"), state);
  const title = "Đếm mù";
  bj08Seed("SCR-044", state);
  if (state === "PERMISSION_DENIED") return bj08Denied(title);
  const s = bj08Session();
  if (!s) return bj08NoSession(title);
  const subtitle = bj08Subtitle(s);
  if (state === "LOCK_LOST") return bj08Shell({ title, subtitle, back: false, body: k1Stale({ title: "Phiên không còn hiệu lực", description: "Phiên đã bị hủy hoặc đã mở khoá. Số đã đếm vẫn được lưu.", actionLabel: "Về kiểm kê", actionAttr: 'data-bj08-action="to-list"' }) });
  if (state === "CONFLICT") return bj08Shell({ title, subtitle, back: false, body: k1Stale({ title: "Người khác vừa nộp phiên này", description: "Tải lại để xem bước hiện hành của phiên.", actionLabel: "Tải lại", actionAttr: 'data-bj08-action="reload"' }) });
  const showError = state === "VALIDATION_ERROR";
  if (showError) bj08CountFilter = "TODO";
  const rows = bj08CountVisible(s).map((l) => bj08CountRow(s, l, showError));
  const columns = [{ key: "product", label: "Sản phẩm", html: true }, { key: "lot", label: "Lô", html: true }, { key: "stateHtml", label: "Tình trạng", html: true }, { key: "count", label: "Đếm được", html: true, align: "end" }];
  const table = rows.length
    ? k7Table({ columns, rows, mobileRow: (r) => r.mobile, caption: "Hàng trong phạm vi", rowAttr: (r) => `data-bj08-line="${bj08Attr(r.key)}" data-bj08-line-text="${r.text}"` })
    : (s.lines.length && bj08CountFilter === "TODO" && !bj08Find ? `<p class="bj08-lead bj08-all-counted">Đã đếm hết các mặt hàng.</p>` : k1Empty({ title: "Không tìm thấy sản phẩm", description: "Thử mã, tên hoặc bộ lọc khác." }));
  const addBtn = `<button class="button button--secondary bj08-add" type="button" data-bj08-action="add-open">Thêm hàng thực tế</button>`;
  const main = `${bj08Lead("Số lượng theo sổ chỉ xuất hiện sau khi nộp lần đếm đầu.")}<div data-bj08-progress>${bj08Progress(bj08CountedN(s), s.lines.length)}</div>${ds24Search(bj08Find, "data-bj08-find", "Tìm hoặc quét sản phẩm trong phạm vi", bj08ScanButton())}<div data-bj08-chips>${bj08CountChips(s)}</div>${table}${addBtn}${bj08CancelLink()}`;
  return bj08Shell({ title, subtitle, body: `<div class="bj08-count">${main}</div>${bj08Overlays()}`, actions: bj08CountFooter(s) });
}

/* ---------- SCR-045 · Chênh lệch và đếm lại ---------- */

function bj08RecountRow(s, x, blocked, showError) {
  const l = x.line, value = s.recounts[l.key] ?? "", error = showError && !bj08Valid(value) ? "Nhập số đếm được" : "";
  const cell = k7EditCell({ value, attr: `data-bj08-recount="${bj08Attr(l.key)}" enterkeyhint="next"`, unit: l.uom, error, label: `Số lượng đếm lại — ${bj08LineName(l)}`, disabled: blocked });
  const same = `<button class="button button--secondary bj08-same" type="button" data-bj08-same="${bj08Attr(l.key)}"${blocked ? " disabled" : ""}>Vẫn ${t7Qty(x.count, l.uom)}</button>`;
  const mobile = `<div class="bj08-line bj08-line--recount" data-bj08-line="${bj08Attr(l.key)}">${bj08LineCopy(bj08LineName(l), `Theo sổ ${t7Qty(l.book, l.uom)} · Đếm đầu ${t7Qty(x.count, l.uom)}`)}<span class="bj08-line__badge">${bj08VarianceBadge(x)}</span><div class="bj08-recount-field">${cell}${same}</div></div>`;
  return { key: l.key, mobile, product: `<strong>${esc(l.name)}</strong><small>${esc(l.code)}</small>`, lot: esc(bj08LotText(l)), book: `${l.book} ${esc(l.uom)}`, first: `${x.count} ${esc(l.uom)}`, diff: bj08VarianceBadge(x), recount: `<div class="bj08-recount-cell">${cell}${same}</div>` };
}
function render045BJ08(state) {
  if (activeFlowId !== "UIF-08") return renderGeneric(screens.find((s) => s.id === "SCR-045"), state);
  const title = "Chênh lệch và đếm lại";
  bj08Seed("SCR-045", state);
  if (state === "PERMISSION_DENIED") return bj08Denied(title);
  const s = bj08Session();
  if (!s) return bj08NoSession(title);
  const subtitle = bj08Subtitle(s, `Đếm lại lần ${s.rounds.length || 1}`);
  if (state === "LOCK_LOST") return bj08Shell({ title, subtitle, back: false, body: k1Stale({ title: "Phiên không còn hiệu lực", description: "Phiên đã bị hủy hoặc đã mở khoá. Số đã đếm vẫn được lưu.", actionLabel: "Về kiểm kê", actionAttr: 'data-bj08-action="to-list"' }) });
  const blocked = state === "PRICE_BASIS_REQUIRED";
  const showError = state === "VALIDATION_ERROR";
  const variance = bj08Variance(s), matched = bj08MatchedLines(s);
  const missing = bj08PriceMissing(s);
  const banner = blocked ? vBanner("warning", "Hàng thừa chưa có giá vốn", `${esc(missing ? missing.line.name : "Hàng thừa")} chưa có giá vốn nên chưa duyệt được. Phiên vẫn khoá; chủ cửa hàng cần xác lập giá trị trước.`) : "";
  const strip = cf12Strip([[variance.length, "mặt hàng lệch"], [matched.length, "khớp"]]);
  const matchedBtn = matched.length ? `<button class="k7-row-link bj08-link" type="button" data-bj08-action="matched-open">Xem ${matched.length} mặt hàng khớp</button>` : "";
  const rows = variance.map((x) => bj08RecountRow(s, x, blocked, showError));
  const columns = [{ key: "product", label: "Sản phẩm", html: true }, { key: "lot", label: "Lô", html: true }, { key: "book", label: "Theo sổ", html: true, align: "end", mono: true }, { key: "first", label: "Đếm đầu", html: true, align: "end", mono: true }, { key: "diff", label: "Chênh lệch", html: true, align: "end" }, { key: "recount", label: "Đếm lại", html: true, align: "end" }];
  const table = k7Table({ columns, rows, mobileRow: (r) => r.mobile, caption: "Dòng cần đếm lại", rowAttr: (r) => `data-bj08-line="${bj08Attr(r.key)}"` });
  const main = `${banner}${bj08Lead("Kết quả vòng trước được giữ nguyên trong lịch sử.")}${strip}${table}${matchedBtn}${bj08CancelLink()}`;
  const blocker = blocked ? "Chờ giá vốn của hàng thừa" : bj08RecountBlocker(s);
  const actions = k4ReasonFooter({ label: "Gửi kết quả đếm lại", attr: 'data-bj08-action="submit-recount"', disabled: Boolean(blocker), reason: blocker });
  return bj08Shell({ title, subtitle, body: `<div class="bj08-count">${main}</div>${bj08Overlays()}`, actions });
}

/* ---------- SCR-046 · Duyệt kết quả kiểm kê (K2) ---------- */

function bj08ReviewTable(s, withMoney) {
  const v = bj08Variance(s);
  const rows = v.map((x) => ({ x, name: `<strong>${esc(x.line.name)}</strong><small>${esc(x.line.code)}</small>`, lot: esc(bj08LotText(x.line)), book: `${x.line.book} ${esc(x.line.uom)}`, count: `${x.count} ${esc(x.line.uom)}`, diff: bj08VarianceBadge(x), value: bj08Money(x.value) || "—" }));
  const columns = [{ key: "name", label: "Sản phẩm", html: true }, { key: "lot", label: "Lô", html: true }, { key: "book", label: "Theo sổ", html: true, align: "end", mono: true }, { key: "count", label: "Đếm lại", html: true, align: "end", mono: true }, { key: "diff", label: "Chênh lệch", html: true, align: "end" }, ...(withMoney ? [{ key: "value", label: "Giá trị", align: "end", mono: true }] : [])];
  const mobile = (r) => ds24ListRow({ title: bj08LineName(r.x.line), subtitle: `Theo sổ ${r.x.line.book} · Đếm lại ${t7Qty(r.x.count, r.x.line.uom)}`, trailing: `${bj08VarianceBadge(r.x)}${withMoney && bj08Money(r.x.value) ? `<small class="bj08-money">${esc(bj08Money(r.x.value))}</small>` : ""}`, leading: null, type: "Status", interactive: false, extraClass: "bj08-review-row" });
  return k7Table({ columns, rows, mobileRow: mobile, caption: "Chênh lệch theo dòng" });
}
function bj08ReviewAside(s, withMoney) {
  const t = bj08Totals(s);
  return ac310KeyValueSurface("Tóm tắt", [["Thiếu", `${t.short} mặt hàng`], ["Thừa", `${t.over} mặt hàng`], ...(withMoney && t.hasMoney ? [["Giá trị điều chỉnh", bj08Money(t.net), true]] : [])]);
}
function bj08ReviewFacts(s) {
  return [["Phạm vi", s.scope.label], ["Số lần đếm lại", String(bj08RecountN(s))], ["Người đã tham gia đếm", s.contributors.join(", ")]];
}
function render046BJ08(state) {
  if (activeFlowId !== "UIF-08") return renderGeneric(screens.find((s) => s.id === "SCR-046"), state);
  const title = "Duyệt kết quả kiểm kê";
  bj08Seed("SCR-046", state);
  if (state === "PERMISSION_DENIED") return bj08Denied(title);
  const s = bj08Session();
  if (!s) return bj08NoSession(title);
  const subtitle = `${s.id} · ${s.scope.label}`;
  const exit = bj08ExitFooter();
  if (state === "COUNT_APPROVAL_SNAPSHOT_STALE") return bj08Shell({ title, subtitle, back: false, body: k1Stale({ title: "Kết quả cần được lập lại", description: "Căn cứ giá hoặc dữ liệu kiểm kê đã thay đổi. Không thể điều chỉnh theo lần duyệt cũ.", actionLabel: "Về kiểm kê", actionAttr: 'data-bj08-action="to-list"' }) });
  if (state === "APPROVAL_ALREADY_DECIDED" || (["READY", "APPROVAL_REVIEW"].includes(state) && s.status !== "PENDING")) {
    return bj08Shell({ title, subtitle, back: false, body: k1Locked({ title: "Công việc đã có quyết định", description: "Mở kết quả phiên để xem trạng thái hiện hành." }), actions: primaryFooter("Xem kết quả", 'data-bj08-action="approval-result"') });
  }
  const reviewing = ["READY", "APPROVAL_REVIEW"].includes(state);
  if (state === "SELF_APPROVAL_NOT_ALLOWED" || (reviewing && !bj08CanDecide())) {
    const own = s.contributors.includes(bj08ActorName());
    return bj08Shell({ title, subtitle, back: false, body: vBanner("warning", "Không thể tự duyệt", own ? "Bạn đã đếm phiên này. Chủ cửa hàng sẽ duyệt." : "Chỉ chủ cửa hàng duyệt kết quả kiểm kê."), actions: exit });
  }
  if (state === "PENDING_APPROVAL") {
    const facts = [["Phiên", s.id], ["Phạm vi", s.scope.label], ["Mặt hàng lệch", String(bj08Variance(s).length)], ["Số lần đếm lại", String(bj08RecountN(s))]];
    const main = `${k2Pending({ approver: "chủ cửa hàng", sentAt: s.sentAt, facts })}${bj08ReviewTable(s, false)}`;
    return bj08Shell({ title, subtitle, back: false, body: k7Split({ main, aside: bj08ReviewAside(s, false), wideMain: true, asideWebOnly: true }), actions: exit });
  }
  const money = bj08ShowMoney(), v = bj08Variance(s), t = bj08Totals(s);
  const attention = [
    ...v.map((x) => [`${x.variance < 0 ? "Thiếu" : "Thừa"} ${t7Qty(Math.abs(x.variance), x.line.uom)} ${bj08LineName(x.line)}`, bj08Money(x.value)]),
    ...(money && t.hasMoney ? [["Tổng chênh lệch (không bù trừ)", bj08Money(t.abs, true)]] : []),
    ["Sau khi duyệt", "Tồn kho ghi theo số đếm lại, phạm vi mở khoá", "info"],
  ];
  const decision = k2Decision({ question: `Duyệt điều chỉnh ${v.length} mặt hàng lệch của phiên ${s.id}?`, maker: s.sentBy || s.counter, sentAt: s.sentAt, attention, facts: bj08ReviewFacts(s), detail: bj08ReviewTable(s, money) });
  const sheet = bj08DialogSheet();
  const actions = k4Footer([{ label: "Yêu cầu đếm lại", attr: 'data-bj08-action="review-open"' }, { label: "Duyệt và điều chỉnh", attr: 'data-bj08-action="approve"', primary: true }]);
  return bj08Shell({ title, subtitle, back: false, body: `${k7Split({ main: decision, aside: bj08ReviewAside(s, money), wideMain: true, asideWebOnly: true })}${sheet}`, actions });
}

/* ---------- SCR-047 · Kết quả kiểm kê (K4 / K3) ---------- */

function render047BJ08(state) {
  if (activeFlowId !== "UIF-08") return renderGeneric(screens.find((s) => s.id === "SCR-047"), state);
  const title = "Kết quả kiểm kê";
  bj08Seed("SCR-047", state);
  if (state === "PERMISSION_DENIED") return bj08Denied(title);
  if (state === "PROCESSING") return bj08Loading(title, ["heading", "card", "row"]);
  const s = bj08Session();
  if (!s) return bj08NoSession(title);
  const toList = bj08ToList(), toStock = { label: "Xem tồn kho", attr: 'data-bj08-action="to-stock"', primary: true };
  if (state === "UNKNOWN") {
    return k3Unknown({ operation: "Ghi điều chỉnh kiểm kê", scope: `${s.id} · ${s.scope.label}`, ref: `ADJ-${s.id.slice(3)}`, sentAt: BJ08_APPROVED_AT, sourceFlow: "UIF-08", exitAttr: k1ExitAttr("SCR-042"), handoff: { operation: s.id, scope: `Kho trung tâm · ${s.scope.label}` } });
  }
  const r = s.result;
  if (state === "REJECTED_EXECUTION") return k4Result({ screenTitle: title, kind: "warning", title: "Chưa thực hiện điều chỉnh", description: "Điều kiện nghiệp vụ không đạt; không có tác động tồn kho.", facts: [["Phiên", s.id], ["Tác động", "Không ghi nhận"]], next: [{ ...toList, primary: true }] });
  if (state === "CANCELLED" || r?.type === "CANCELLED") return k4Result({ screenTitle: title, kind: "warning", title: "Đã hủy phiên", description: "Không tạo điều chỉnh. Lịch sử đếm được giữ và phạm vi đã mở khóa.", facts: [["Phiên", s.id], ["Phạm vi", s.scope.label], ["Lý do", r?.reason || "—"], ["Thời điểm", r?.committedAt || BJ08_CANCELLED_AT]], next: [{ ...toList, primary: true }] });
  if (r?.type === "ZERO") return k4Result({ screenTitle: title, title: "Đã hoàn tất kiểm kê", description: "Kết quả thực tế khớp số sổ. Không cần tạo điều chỉnh và phạm vi đã mở khóa.", facts: [["Phiên", s.id], ["Phạm vi", s.scope.label], ["Hoàn tất lúc", r.committedAt]], next: [toList, toStock] });
  const facts = [["Phiên", s.id], ["Phạm vi", s.scope.label], ["Đã điều chỉnh", `${r?.lines ?? 0} dòng`], ["Thiếu / thừa", `Thiếu ${r?.short ?? 0} · thừa ${r?.over ?? 0} mặt hàng`], ...(bj08Money(r?.net) && r?.hasMoney ? [["Giá trị điều chỉnh", bj08Money(r.net)]] : []), ["Người duyệt", r?.approver || BJ08_OWNER], ["Ghi nhận lúc", r?.committedAt || BJ08_APPROVED_AT]];
  return k4Result({ screenTitle: title, title: "Đã hoàn tất kiểm kê", description: "Điều chỉnh chênh lệch đã được ghi và phạm vi đã mở khóa.", facts, next: [toList, toStock] });
}

/* ---------- Sheet / hộp thoại ---------- */

function bj08ScopeSheet() {
  const opts = bj08ScopeOptions(bj08Draft.kind);
  const rows = opts.map((o) => ds24ListRow({ title: o.title, subtitle: o.subtitle, leading: null, attrs: `data-bj08-scope-pick="${bj08Attr(o.key)}" data-bj08scope-search-text="${bj08Attr(ioNormalizeSearch(`${o.title} ${o.subtitle}`))}"`, theme: "Theme7ScopeResult" })).join("");
  const body = `${ds24Search(bj08ScopeFind, "data-bj08-scope-find", "Tìm kiếm")}<div class="ds24-list-stack">${rows}</div><div data-bj08scope-filter-empty hidden>${k1Empty({ title: "Không tìm thấy phạm vi", description: "Thử từ khóa khác." })}</div>`;
  return ds24Sheet({ title: "Chọn phạm vi", attrs: 'data-bj08-action="dialog-close"', body });
}
function bj08AddSheet(s) {
  const free = BJ08_EXTRAS.filter((e) => !s.lines.some((l) => l.code === e.code && l.lot === e.lot));
  const rows = free.map((e) => ds24ListRow({ title: e.name, subtitle: `${e.code} · ${bj08LotText(e)} · ${e.uom}`, leading: null, attrs: `data-bj08-add-pick="${bj08Attr(e.code)}" data-bj08add-search-text="${bj08Attr(ioNormalizeSearch(`${e.name} ${e.code} ${e.lot}`))}"`, theme: "Theme7UnexpectedItemResult" })).join("");
  const empty = k1Empty({ title: free.length ? "Không tìm thấy sản phẩm" : "Không còn sản phẩm để thêm", description: free.length ? "Thử mã hoặc tên khác." : "Mọi sản phẩm tìm được đã có trong phiên." });
  const body = `${ds24Search("", "data-bj08-add-find", "Tìm hoặc quét sản phẩm")}<div class="ds24-list-stack">${rows}</div><div data-bj08add-filter-empty${free.length ? " hidden" : ""}>${empty}</div>`;
  return ds24Sheet({ title: "Thêm hàng thực tế", attrs: 'data-bj08-action="dialog-close"', body });
}
function bj08ScanSheet(s) {
  const sample = s.lines.find((l) => !l.unexpected && !bj08Filled(s.counts[l.key])) || s.lines[0];
  const body = `<div class="bj01-scan-frame" aria-hidden="true">${icon("scan")}</div><p class="ds24-context vet45-text-style-7">Đưa mã vạch vào khung</p>${sample ? `<button class="ds24-button ds24-button--secondary" type="button" data-bj08-scan-sample="${bj08Attr(sample.code)}" data-ds-component="VButton">Quét thử: ${esc(sample.name)}</button>` : ""}`;
  return ds24Sheet({ title: "Quét mã vạch", attrs: 'data-bj08-action="dialog-close"', body });
}
function bj08MatchedSheet(s) {
  const eff = bj08Eff(s);
  const rows = bj08MatchedLines(s).map((l) => ds24ListRow({ title: bj08LineName(l), subtitle: `${l.code} · Theo sổ ${t7Qty(l.book, l.uom)} · Đếm được ${t7Qty(bj08Num(eff[l.key]), l.uom)}`, trailing: ds24Badge("Khớp", "Success"), leading: null, type: "Status", interactive: false })).join("");
  return ds24Sheet({ title: "Mặt hàng khớp", attrs: 'data-bj08-action="dialog-close"', body: `<div class="ds24-list-stack">${rows}</div><button class="ds24-button ds24-button--secondary" type="button" data-bj08-action="dialog-close" data-ds-component="VButton">Đóng</button>` });
}
// Sheet xác nhận / lý do dùng chung k2RejectSheet (K2): có lý do thì bắt buộc, không thì chỉ hai nút.
function bj08DialogSheet() {
  const s = bj08Session(), common = { open: true, closeAttr: 'data-bj08-action="dialog-close"', closeLabel: "Quay lại", withReason: false };
  const confirm = (name) => `data-bj08-action="${name}"`;
  if (bj08Dialog === "open") return k2RejectSheet({ ...common, title: "Mở phiên kiểm kê?", description: `Trong lúc kiểm, ${bj08DraftKeys().length} mặt hàng này tạm không nhận, xuất hay bán được.`, confirmAttr: confirm("confirm-open"), confirmLabel: "Mở phiên" });
  if (bj08Dialog === "first") return k2RejectSheet({ ...common, title: "Nộp lần đếm đầu?", description: "Sau khi nộp, số sổ và chênh lệch mới được hiển thị. Không sửa được lần đếm này.", confirmAttr: confirm("confirm-first"), confirmLabel: "Nộp kết quả" });
  if (bj08Dialog === "recount") return k2RejectSheet({ ...common, title: "Gửi kết quả đếm lại?", description: "Kết quả được lưu thành một lần đếm lại, không sửa được.", confirmAttr: confirm("confirm-recount"), confirmLabel: "Gửi kết quả" });
  if (bj08Dialog === "cancel") return k2RejectSheet({ ...common, withReason: true, title: "Hủy phiên kiểm kê?", description: "Không tạo điều chỉnh; toàn bộ lịch sử đếm được giữ và phạm vi được mở khóa.", reason: bj08CancelReason, reasonAttr: "data-bj08-cancel-reason", reasonLabel: "Lý do", placeholder: "Bắt buộc để lưu lịch sử quyết định.", confirmAttr: confirm("confirm-cancel"), confirmLabel: "Hủy phiên", tone: "danger" });
  if (bj08Dialog === "review") return k2RejectSheet({ ...common, withReason: true, title: "Yêu cầu đếm lại?", description: "Vòng đếm hiện tại được giữ nguyên. Một vòng đếm lại mới sẽ được mở.", reason: bj08ReviewReason, reasonAttr: "data-bj08-review-reason", reasonLabel: "Lý do", placeholder: "Bắt buộc để lưu lịch sử quyết định.", confirmAttr: confirm("confirm-review"), confirmLabel: "Yêu cầu đếm lại" });
  if (bj08Dialog === "scope") return bj08ScopeSheet();
  if (bj08Dialog === "add" && s) return bj08AddSheet(s);
  if (bj08Dialog === "scan" && s) return bj08ScanSheet(s);
  if (bj08Dialog === "matched" && s) return bj08MatchedSheet(s);
  return "";
}
function bj08Overlays() { return bj08Dialog ? bj08DialogSheet() : ""; }

/* ---------- Sự kiện ---------- */

function bj08Rerender(focusSelector = "") {
  const top = document.querySelector("#app-screen .app-content")?.scrollTop || 0;
  renderAppScreen();
  const content = document.querySelector("#app-screen .app-content"); if (content) content.scrollTop = top;
  if (focusSelector) bj08Focus(focusSelector);
}
function bj08Visible(el) { return el.offsetParent !== null; }
function bj08Focus(selector, scroll = false) {
  const el = [...document.querySelectorAll(selector)].find(bj08Visible);
  if (!el) return null;
  el.focus({ preventScroll: !scroll });
  if (scroll) el.scrollIntoView({ block: "center" });
  return el;
}
function bj08Go(screenId, state) { bj08ResetUi(); bj08SetState(screenId, state); return navigate(screenId); }
function bj08View(id, state) { bj08SelectedId = id; bj08ResetUi(); bj08SetState("SCR-046", state); }
function bj08Open(id) {
  const s = bj08Session(id); if (!s) return;
  bj08SelectedId = id;
  if (s.status === "COUNTING") return bj08Go("SCR-044", "BLIND_COUNT");
  if (s.status === "RECOUNT") return bj08Go("SCR-045", bj08PriceMissing(s) ? "PRICE_BASIS_REQUIRED" : "RECOUNT_REQUIRED");
  if (s.status === "PENDING") return bj08Go("SCR-046", bj08CanDecide() ? "APPROVAL_REVIEW" : "PENDING_APPROVAL");
  return bj08Go("SCR-047", s.status === "CANCELLED" ? "CANCELLED" : "COMPLETED");
}
function bj08ToListNav() { return bj08Go("SCR-042", "READY"); }

// Gõ số không dựng lại màn (giữ focus): chỉ cập nhật tiến độ, chip, chân và lỗi dưới ô.
function bj08SetCellError(el, message) {
  const box = el.closest(".k7-edit"); if (!box) return;
  box.classList.toggle("k7-edit--error", Boolean(message));
  if (message) el.setAttribute("aria-invalid", "true"); else el.removeAttribute("aria-invalid");
  let msg = box.querySelector(".field-error");
  if (message && !msg) { msg = document.createElement("small"); msg.className = "field-error"; msg.setAttribute("role", "alert"); box.appendChild(msg); }
  if (msg) { msg.textContent = message; msg.hidden = !message; }
}
function bj08SyncFooter(button, blocker) {
  document.querySelectorAll(button).forEach((b) => { b.disabled = Boolean(blocker); });
  document.querySelectorAll(".app-actions [data-k4-reason]").forEach((p) => { p.textContent = blocker; p.hidden = !blocker; });
}
function bj08SyncCount(s) {
  const done = bj08CountedN(s), total = s.lines.length;
  const prog = document.querySelector("[data-bj08-progress]"); if (prog) prog.innerHTML = bj08Progress(done, total);
  const chips = document.querySelector("[data-bj08-chips]"); if (chips) chips.innerHTML = bj08CountChips(s);
  bj08SyncFooter('[data-bj08-action="submit-first"]', bj08FirstBlocker(s));
}
function bj08SyncRecount(s) { bj08SyncFooter('[data-bj08-action="submit-recount"]', stateByScreen["SCR-045"] === "PRICE_BASIS_REQUIRED" ? "Chờ giá vốn của hàng thừa" : bj08RecountBlocker(s)); }
function bj08SyncDraft() {
  const blocker = bj08DraftBlocker();
  bj08SyncFooter('[data-bj08-action="open"]', blocker);
  const lock = document.querySelector("[data-bj08-lock]"); if (lock) lock.innerHTML = bj08LockNotice();
}
function bj08ApplyFind() {
  const q = ioNormalizeSearch(bj08Find);
  document.querySelectorAll("[data-bj08-line-text]").forEach((el) => { el.hidden = Boolean(q) && !el.dataset.bj08LineText.includes(q); });
}
function bj08SetValue(map, key, value, inputAttr) {
  map[key] = value;
  document.querySelectorAll(`[${inputAttr}="${CSS.escape(key)}"]`).forEach((el) => { if (el.value !== value) el.value = value; bj08SetCellError(el, ""); });
}
// Enter ở một ô số: sang ô của dòng chưa đếm kế tiếp (không có thì dòng kế tiếp; hết dòng thì xuống nút chân).
function bj08NextCell(input, attr) {
  const cells = [...document.querySelectorAll(`[${attr}]`)].filter((el) => bj08Visible(el) && !el.disabled && !el.closest("[hidden]"));
  const at = cells.findIndex((el) => el.getAttribute(attr) === input.getAttribute(attr));
  const after = cells.slice(at + 1);
  const next = after.find((el) => !bj08Filled(el.value)) || after[0];
  if (next) { next.focus(); next.select?.(); return; }
  const footer = [...document.querySelectorAll(".app-actions .button--primary")].find(bj08Visible);
  if (footer && !footer.disabled) footer.focus(); else input.blur();
}
// Quét / chọn kết quả → dòng chưa đếm của sản phẩm đó, đặt focus vào ô số.
function bj08ScanFind(code) {
  const s = bj08Session(); if (!s) return false;
  const c = String(code || "").trim().toLocaleLowerCase("vi");
  const hits = s.lines.filter((l) => l.code.toLocaleLowerCase("vi") === c || ioNormalizeSearch(l.name).includes(c));
  const line = hits.find((l) => !bj08Filled(s.counts[l.key])) || hits[0];
  if (!line) { showToast("Không có trong phạm vi kiểm kê", "warning"); return false; }
  bj08Dialog = null; bj08Find = "";
  if (bj08CountFilter !== "ALL" && (bj08CountFilter === "DONE") !== bj08Filled(s.counts[line.key])) bj08CountFilter = "ALL";
  bj08FocusKey = line.key;
  renderAppScreen();
  requestAnimationFrame(() => bj08Focus(`[data-bj08-count="${CSS.escape(line.key)}"]`, true));
  return true;
}

document.addEventListener("input", (event) => {
  if (activeFlowId !== "UIF-08") return;
  const t = event.target;
  if (t.matches("[data-bj08-search]")) { bj08ListQuery = t.value; ioFilterRows("bj08", t.value); return; }
  if (t.matches("[data-bj08-count]")) { const s = bj08Session(); if (!s) return; bj08SetValue(s.counts, t.dataset.bj08Count, t.value, "data-bj08-count"); return bj08SyncCount(s); }
  if (t.matches("[data-bj08-recount]")) { const s = bj08Session(); if (!s) return; bj08SetValue(s.recounts, t.dataset.bj08Recount, t.value, "data-bj08-recount"); return bj08SyncRecount(s); }
  if (t.matches("[data-bj08-find]")) { bj08Find = t.value; return bj08ApplyFind(); }
  if (t.matches("[data-bj08-reason]")) { bj08Draft.reason = t.value; t.closest(".cf-field")?.querySelector(".field-error")?.remove(); return bj08SyncDraft(); }
  if (t.matches("[data-bj08-scope-find]")) { bj08ScopeFind = t.value; return ioFilterRows("bj08scope", t.value); }
  if (t.matches("[data-bj08-add-find]")) return ioFilterRows("bj08add", t.value);
  if (t.matches("[data-bj08-cancel-reason]")) { bj08CancelReason = t.value; const b = document.querySelector('[data-bj08-action="confirm-cancel"]'); if (b) b.disabled = !bj08CancelReason.trim(); return; }
  if (t.matches("[data-bj08-review-reason]")) { bj08ReviewReason = t.value; const b = document.querySelector('[data-bj08-action="confirm-review"]'); if (b) b.disabled = !bj08ReviewReason.trim(); }
}, true);

document.addEventListener("change", (event) => {
  if (activeFlowId !== "UIF-08") return;
  if (event.target.matches("[data-bj08-counter]")) { bj08Draft.counter = event.target.value; }
}, true);

document.addEventListener("keydown", (event) => {
  if (activeFlowId !== "UIF-08") return;
  const t = event.target;
  if (event.key === "Enter" && t.matches?.("[data-bj08-count]")) { event.preventDefault(); return bj08NextCell(t, "data-bj08-count"); }
  if (event.key === "Enter" && t.matches?.("[data-bj08-recount]")) { event.preventDefault(); return bj08NextCell(t, "data-bj08-recount"); }
  if (event.key === "Enter" && t.matches?.("[data-bj08-find]")) { event.preventDefault(); const first = [...document.querySelectorAll("[data-bj08-count]")].find((el) => bj08Visible(el) && !el.closest("[hidden]")); return first?.focus(); }
}, true);

// Sheet / hộp thoại là modal: Esc đóng, Tab chỉ đi vòng trong hộp thoại.
window.addEventListener("keydown", (event) => {
  if (activeFlowId !== "UIF-08" || !bj08Dialog) return;
  if (event.key === "Escape") { event.preventDefault(); bj08Dialog = null; return renderAppScreen(); }
  const dialog = event.key === "Tab" && document.querySelector('#app-screen [role="dialog"]');
  if (!dialog) return;
  const items = [...dialog.querySelectorAll("button:not([disabled]), [href], input, textarea, select, [tabindex]:not([tabindex='-1'])")].filter(bj08Visible);
  if (!items.length) return;
  const first = items[0], last = items[items.length - 1], at = document.activeElement;
  if (event.shiftKey ? (at === first || !dialog.contains(at) || at === dialog) : (at === last || !dialog.contains(at))) { event.preventDefault(); (event.shiftKey ? last : first).focus(); }
}, true);

function bj08Create() {
  bj08Draft = bj08NewDraft(); bj08ConflictId = "";
  return bj08Go("SCR-043", "READY");
}
function bj08ConfirmOpen() {
  bj08Dialog = null;
  if (bj08DraftBlocker()) { bj08SetState("SCR-043", "VALIDATION_ERROR"); return renderAppScreen(); }
  const label = bj08ScopeLabel(bj08Draft.kind, bj08Draft.target);
  const clash = bj08Sessions.find((x) => ["COUNTING", "RECOUNT", "PENDING"].includes(x.status) && x.scope.kind === bj08Draft.kind && x.scope.label === label);
  if (clash) { bj08ConflictId = clash.id; bj08SetState("SCR-043", "CONFLICT"); return renderAppScreen(); }
  bj08CreateFrom(bj08Draft);
  return bj08Go("SCR-044", "BLIND_COUNT");
}
function bj08SubmitFirst() {
  const s = bj08Session(); if (!s) return;
  bj08Dialog = null;
  if (bj08FirstBlocker(s)) { bj08CountFilter = "TODO"; bj08SetState("SCR-044", "VALIDATION_ERROR"); return renderAppScreen(); }
  const next = bj08CommitFirst(s);
  if (next === "ZERO") return bj08Go("SCR-047", "COMPLETED");
  return bj08Go("SCR-045", bj08PriceMissing(s) ? "PRICE_BASIS_REQUIRED" : "RECOUNT_REQUIRED");
}
function bj08SubmitRecount() {
  const s = bj08Session(); if (!s) return;
  bj08Dialog = null;
  if (stateByScreen["SCR-045"] === "PRICE_BASIS_REQUIRED") return renderAppScreen();
  if (bj08RecountBlocker(s)) { bj08SetState("SCR-045", "VALIDATION_ERROR"); return renderAppScreen(); }
  const next = bj08CommitRecount(s);
  if (next === "ZERO") return bj08Go("SCR-047", "COMPLETED");
  bj08Go("SCR-046", "PENDING_APPROVAL");
  return showToast("Đã gửi chủ cửa hàng duyệt", "success");
}
function bj08Decide() {
  const s = bj08Session(); if (!s) return;
  if (!bj08CanDecide()) { bj08SetState("SCR-046", "SELF_APPROVAL_NOT_ALLOWED"); return renderAppScreen(); }
  if (s.status !== "PENDING") { bj08SetState("SCR-046", "APPROVAL_ALREADY_DECIDED"); return renderAppScreen(); }
  bj08ApproveSession(s);
  return bj08Go("SCR-047", "COMPLETED");
}

document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-08") return;
  const t = event.target, hit = (sel) => t.closest?.(sel);
  let el;
  if ((el = hit("[data-bj08-filter]"))) { event.preventDefault(); bj08ListFilter = el.dataset.bj08Filter; return renderAppScreen(); }
  if ((el = hit("[data-bj08-count-filter]"))) { event.preventDefault(); bj08CountFilter = el.dataset.bj08CountFilter; return bj08Rerender(); }
  if ((el = hit("[data-bj08-row]"))) { event.preventDefault(); return bj08Open(el.dataset.bj08Row); }
  if ((el = hit("[data-bj08-scope]"))) { event.preventDefault(); bj08Draft.kind = el.dataset.bj08Scope; bj08Draft.target = ""; return bj08Rerender(`[data-bj08-scope="${bj08Draft.kind}"]`); }
  if ((el = hit("[data-bj08-scope-pick]"))) { event.preventDefault(); bj08Draft.target = el.dataset.bj08ScopePick; bj08Dialog = null; bj08ScopeFind = ""; return bj08Rerender('[data-bj08-action="scope-open"]'); }
  if ((el = hit("[data-bj08-add-pick]"))) {
    event.preventDefault(); const s = bj08Session(), extra = BJ08_EXTRAS.find((e) => e.code === el.dataset.bj08AddPick); if (!s || !extra) return;
    const key = bj08AddUnexpected(s, extra); bj08Dialog = null; bj08CountFilter = "TODO";
    renderAppScreen(); return bj08Focus(`[data-bj08-for="${CSS.escape(key)}"]`, true);
  }
  if ((el = hit("[data-bj08-unexpected-state]"))) {
    event.preventDefault(); const s = bj08Session(), l = s?.lines.find((x) => x.key === el.dataset.bj08For); if (!l) return;
    l.state = el.dataset.bj08UnexpectedState; return bj08Rerender(`[data-bj08-for="${CSS.escape(l.key)}"][data-bj08-unexpected-state="${l.state}"]`);
  }
  if ((el = hit("[data-bj08-same]"))) {
    event.preventDefault(); const s = bj08Session(); if (!s || el.disabled) return;
    const x = bj08Variance(s).find((v) => v.line.key === el.dataset.bj08Same); if (!x) return;
    bj08SetValue(s.recounts, x.line.key, String(x.count), "data-bj08-recount"); bj08SyncRecount(s);
    return bj08NextCell(document.querySelector(`[data-bj08-recount="${CSS.escape(x.line.key)}"]`), "data-bj08-recount");
  }
  if ((el = hit("[data-bj08-scan-sample]"))) { event.preventDefault(); return bj08ScanFind(el.dataset.bj08ScanSample); }
  const a = hit("[data-bj08-action]"); if (!a) return;
  if (a.matches(".sheet-backdrop") && t !== a) return;
  event.preventDefault(); event.stopPropagation(); if (a.disabled) return;
  const k = a.dataset.bj08Action;
  if (k === "create") return bj08Create();
  if (k === "clear-filter") { bj08ListQuery = ""; bj08ListFilter = "ALL"; if (stateByScreen["SCR-042"] === "FILTER_EMPTY") bj08SetState("SCR-042", "READY"); return renderAppScreen(); }
  if (k === "to-list") return bj08ToListNav();
  if (k === "scope-open") { bj08Dialog = "scope"; bj08ScopeFind = ""; return renderAppScreen(); }
  if (k === "open") { bj08Dialog = "open"; return renderAppScreen(); }
  if (k === "confirm-open") return bj08ConfirmOpen();
  if (k === "open-conflict") return bj08Open(bj08ConflictId);
  if (k === "to-valuation") { activeFlowId = "UIF-03"; activeScreenId = "SCR-014"; stateByScreen["SCR-014"] = "READY"; syncReviewUrl(); return render(); }
  if (k === "dialog-close") { bj08Dialog = null; return renderAppScreen(); }
  if (k === "add-open") { bj08Dialog = "add"; return renderAppScreen(); }
  if (k === "scan-open") { bj08Dialog = "scan"; return renderAppScreen(); }
  if (k === "matched-open") { bj08Dialog = "matched"; return renderAppScreen(); }
  if (k === "submit-first") { bj08Dialog = "first"; return renderAppScreen(); }
  if (k === "confirm-first") return bj08SubmitFirst();
  if (k === "submit-recount") { bj08Dialog = "recount"; return renderAppScreen(); }
  if (k === "confirm-recount") return bj08SubmitRecount();
  if (k === "cancel-open") { bj08CancelReason = ""; bj08Dialog = "cancel"; return renderAppScreen(); }
  if (k === "confirm-cancel") {
    const s = bj08Session(); if (!s || !bj08CancelReason.trim()) return;
    bj08CancelSession(s, bj08CancelReason.trim()); return bj08Go("SCR-047", "CANCELLED");
  }
  if (k === "approve") return bj08Decide();
  if (k === "review-open") { if (!bj08CanDecide()) return bj08Decide(); bj08ReviewReason = ""; bj08Dialog = "review"; return renderAppScreen(); }
  if (k === "confirm-review") {
    const s = bj08Session(); if (!s || !bj08ReviewReason.trim()) return;
    if (!bj08CanDecide()) return bj08Decide();
    bj08RequestRecount(s, bj08ReviewReason.trim()); return bj08Go("SCR-045", "RECOUNT_REQUIRED");
  }
  if (k === "approval-result") { const s = bj08Session(); return bj08Go("SCR-047", s?.status === "CANCELLED" ? "CANCELLED" : "COMPLETED"); }
  if (k === "reload") { const s = bj08Session(); return s ? bj08Open(s.id) : bj08ToListNav(); }
  if (k === "to-stock") { activeFlowId = "UIF-01"; activeScreenId = "SCR-001"; stateByScreen["SCR-001"] = "READY"; syncReviewUrl(); return render(); }
}, true);

// Đi giữa các màn bằng navigate (kể cả nút quay lại) là đi trong luồng: trạng thái hiện tại là "đã biết", không dựng lại fixture.
["SCR-042", "SCR-043", "SCR-044", "SCR-045", "SCR-046", "SCR-047"].forEach((id) => { onScreenEnter[`UIF-08:${id}`] = () => { bj08Expected[id] = stateByScreen[id]; }; });
onPrevious["UIF-08"] = () => { if (activeScreenId === "SCR-042") return; bj08Dialog = null; bj08SetState("SCR-042", "READY"); return navigate("SCR-042"); };

/* ---------- Lối vào và QA ---------- */

Object.assign(window.__VET45_QA__, {
  bj08RoundHistory: () => (bj08Session()?.rounds || []).map((r) => ({ ...r, values: { ...r.values } })),
  bj08Result: () => { const r = bj08Session()?.result; return r ? { ...r } : null; },
  // Quét thử: tới dòng chưa đếm của sản phẩm có mã đó, đặt focus vào ô số.
  scanBJ08: (code) => bj08ScanFind(code),
  // Kịch bản khớp hết: đặt số đếm của phiên đang mở bằng đúng số sổ (người đếm không thấy số sổ trên màn).
  fillBJ08Book() { const s = bj08Session(); if (!s) return false; s.lines.forEach((l) => bj08SetValue(s.counts, l.key, String(l.book), "data-bj08-count")); bj08SyncCount(s); return true; },
});

flowRenderers["UIF-08"] = Object.assign(flowRenderers["UIF-08"] || {}, {
  "SCR-042": render042BJ08,
  "SCR-043": render043BJ08,
  "SCR-044": render044BJ08,
  "SCR-045": render045BJ08,
  "SCR-046": render046BJ08,
  "SCR-047": render047BJ08,
});
Object.assign(renderers, {
  "SCR-042": render042BJ08,
  "SCR-043": render043BJ08,
  "SCR-044": render044BJ08,
  "SCR-045": render045BJ08,
  "SCR-046": render046BJ08,
  "SCR-047": render047BJ08,
});

/* ---------- Nguồn "Chờ duyệt" của Home Kho (K2) ---------- */

(window.__T7_PENDING_SOURCES__ ||= []).push({
  id: "UIF-08",
  label: "kiểm kê",
  needsActivation: true,
  rows: () => bj08Sessions.filter((s) => s.status === "PENDING").map((s) => ({
    title: `${s.id} · ${s.scope.label}`,
    subtitle: `${bj08Variance(s).length} mặt hàng lệch · ${s.sentBy || s.counter} gửi ${s.sentAt}`,
    icon: "listCheck",
    attrs: `data-theme-entry-flow="UIF-08" data-t380-target-screen="SCR-046" data-t380-context="bj08-approval:${bj08Attr(s.id)}" data-theme-entry-actor="approver"`,
  })),
});
(window.__T7_DIRECT_CONTEXTS__ ||= {})["bj08-approval"] = (id) => { bj08View(id, "APPROVAL_REVIEW"); };
