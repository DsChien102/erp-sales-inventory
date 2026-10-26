/* BJ-16 — Điều tra và đối soát sai lệch (UIF-16). Màn: SCR-078, 079, 081, 082, 083 (SCR-080 đã gộp vào sheet xác nhận ở SCR-079 từ v5.18.0).
 *
 * Thiết kế lại T7-P chặng 5 (v5.18.0): một danh sách chung "Hồ sơ cần kiểm tra" cho BJ-16 và BJ-17 (SCR-078, chip / ô tìm là trạng thái chung),
 * mỗi hồ sơ nói bằng một câu kết luận + bảng so sánh + dòng "Đang tạm khoá" + một việc tiếp theo (SCR-079), xác nhận bằng sheet ngay tại 079,
 * cập nhật số trên app tự sang kiểm lại (081 → 082), kết quả theo K4 / K3 (083). Sửa phiếu gốc đi BJ-11 và quay về đúng hồ sơ để kiểm lại, đóng.
 * File này giữ phần dùng chung với BJ-17 (cr* — danh sách, khung, sheet, seed); bj17.js giữ dữ liệu và màn riêng của BJ-17.
 * Dùng từ khuôn: K1, K2 (k2Attention, k2Pending, k2RejectSheet), K3, K4, K6, K7.
 * Fixture: plan T7-P-bj16-bj17-doi-soat.md mục 3 (sản phẩm / phiếu khớp BJ-01…BJ-11).
 */

const BJ16_CLOSED_AT = "17/09/2026 21:00";
const BJ16_SENT_AT = "17/09/2026 21:05";
const CR_SUPPORT = "Bộ phận hỗ trợ";
const CR_PURCHASE = "Mua hàng";
const CR_FLOWS = ["UIF-16", "UIF-17"];
const CR_FILTERS = [["ALL", "Tất cả"], ["DIFF", "Sai lệch"], ["UNKNOWN", "Chưa rõ kết quả"], ["WAITING", "Đang chờ"]];

/* ---------- Fixture ---------- */

function bj16InitialCases() {
  const base = { evidenceVersion: 1, planEvidenceVersion: null, recoveryEvidenceVersion: null, status: "OPEN", correctionDone: false, appUpdated: false, done: "", closedAt: "", handedTo: "", sentAt: "", locked: false, lockedBy: "" };
  return [
    { ...base, id: "REC-260907-03", route: "PROJECTION", conclusion: "Số trên app lệch sổ kho", scope: "Nobivac DHPPi · Lô DH2507", lockName: "Nobivac DHPPi lô DH2507", uom: "hộp", ledger: 70, app: 68, locked: true, signal: "Kiểm soát tự động", openedAt: "16/09/2026 06:00" },
    { ...base, id: "REC-260907-04", route: "CORRECTION", conclusion: "Phiếu nhận ghi khác hoá đơn", scope: "Amox 500 · SP-000066", lockName: "Amox 500", uom: "hộp", docCode: "PN-260904-08", source: 20, invoice: 18, ledger: 46, locked: true, signal: "Hoá đơn nhà cung cấp", openedAt: "16/09/2026 09:15", correctionOperationId: "IO-260904-021", invoiceQty: 18 },
    { ...base, id: "REC-260907-05", route: "NO_REAL", conclusion: "Báo cáo khác số tồn", scope: "Găng tay khám Nitrile · SP-000271", lockName: "Găng tay khám Nitrile", uom: "hộp", report: 8, ledger: 10, app: 10, reportAt: "07:00", receiptCode: "PN-260916-03", signal: "Báo cáo cuối ngày", openedAt: "17/09/2026 07:30" },
    { ...base, id: "REC-260907-06", route: "LEDGER", conclusion: "Sổ kho có dấu hiệu sai", scope: "Dầu sát khuẩn · SP-00606 · L2406-T", lockName: "Dầu sát khuẩn lô L2406-T", uom: "chai", locked: true, signal: "Kiểm soát tự động", openedAt: "15/09/2026 22:10" },
    { ...base, id: "REC-260907-07", route: "SOURCE", conclusion: "Phiếu mua chưa khớp kho", scope: "Tylosin 20% · TY2511", lockName: "Tylosin 20% lô TY2511", uom: "lọ", docCode: "PN-260906-12", signal: "Mua hàng", openedAt: "16/09/2026 14:20" },
    // Hai hồ sơ chỉ để dựng trạng thái (không hiện ở danh sách): phạm vi do hồ sơ khác giữ, và "chưa đủ bằng chứng".
    { ...base, id: "REC-260907-08", route: "CORRECTION", status: "LINKED", conclusion: "Phiếu nhận ghi khác hoá đơn", scope: "Amox 500 · SP-000066", lockName: "Amox 500", uom: "hộp", docCode: "PN-260904-08", source: 20, invoice: 18, ledger: 46, locked: true, lockedBy: "REC-260907-04", signal: "Hoá đơn nhà cung cấp", openedAt: "17/09/2026 08:00" },
    { ...base, id: "REC-260907-09", route: "INSUFFICIENT", status: "LINKED", conclusion: "Chưa rõ nguyên nhân", scope: "Tylosin 20% · TY2408", lockName: "Tylosin 20% lô TY2408", uom: "lọ", locked: true, signal: "Kiểm soát tự động", openedAt: "17/09/2026 08:20" },
  ];
}

const cr16Cases = bj16InitialCases();
let cr16SelectedId = "REC-260907-03";
let crListFilter = "ALL";
let crQuery = "";
let crSheet = null;          // "update" | "close" | "confirm-done" | "continue" | null
let crSheetOpener = "";
const crExpected = {};

const bj16Num = (v) => Number(v ?? 0);
const crAttr = (v) => escapeAttribute(String(v ?? ""));
function cr16Current() { return cr16Cases.find((x) => x.id === cr16SelectedId) || cr16Cases[0]; }
const CR16_STATE = { PROJECTION: "PROJECTION_MISMATCH", CORRECTION: "CORRECTION_REQUIRED", NO_REAL: "NO_REAL_DIFFERENCE", LEDGER: "LEDGER_INTEGRITY_RISK", SOURCE: "SOURCE_MISMATCH", INSUFFICIENT: "INSUFFICIENT_EVIDENCE" };
function cr079StateFor16(c) { return c.status === "LINKED" && c.lockedBy ? "LOCKED" : CR16_STATE[c.route]; }
function cr079StateFor17(c) { return c.evidence === "INSUFFICIENT" ? "INSUFFICIENT_EVIDENCE" : "UNKNOWN_EVIDENCE"; }
function crCase(flow = activeFlowId) { return flow === "UIF-17" ? cr17Current() : cr16Current(); }
function crStateFor(flow = activeFlowId) { return flow === "UIF-17" ? cr079StateFor17(cr17Current()) : cr079StateFor16(cr16Current()); }

// Yêu cầu sửa sai của BJ-11 gắn với hồ sơ: đang chờ duyệt / đã ghi.
function cr16Pending(c) { return c.correctionOperationId ? cr11Requests.find((r) => r.opId === c.correctionOperationId && r.status === "PENDING") || null : null; }
function cr16Record(c) { return c.correctionOperationId ? cr11Requests.find((r) => r.opId === c.correctionOperationId && r.status === "COMPLETED") || null : null; }
// OPEN = cần làm; WAITING = đã chuyển hỗ trợ / Mua hàng hoặc chờ duyệt sửa sai; CLOSED / LINKED không hiện ở danh sách.
function cr16Status(c) {
  if (c.status === "CLOSED" || c.status === "LINKED") return c.status;
  return c.status === "WAITING" || cr16Pending(c) ? "WAITING" : "OPEN";
}

/* ---------- Mỗi loại hồ sơ nói gì (một nơi giữ chữ theo loại — plan 0.4 điểm 8) ---------- */

const crDiffText = (d, uom) => `lệch${NBSP}${d < 0 ? "−" : "+"}${t7Qty(Math.abs(d), uom)}`;
// "Sổ kho" là tồn của cả phạm vi (khớp BJ-01 / BJ-08 / BJ-11), không phải số của phiếu. Hồ sơ sửa phiếu: sau khi sửa, sổ kho bớt phần ghi thừa.
function crBook(c) { return c.route === "CORRECTION" && c.correctionDone ? c.ledger - (c.source - c.invoice) : c.ledger; }
function crHandedBanner(c) {
  const toPurchase = c.handedTo === CR_PURCHASE;
  return { tone: "info", title: toPurchase ? "Đã chuyển cho Mua hàng" : "Đã gửi bộ phận hỗ trợ", desc: toPurchase ? `Hồ sơ chờ Mua hàng kiểm lại phiếu ${c.docCode}; Kho không tự sửa.` : "Hồ sơ vẫn mở; phạm vi rủi ro tiếp tục được bảo vệ cho tới khi có bằng chứng mới." };
}
// Trả { conclusion, sentence, tone, compare: [[nhãn, giá trị, lệch?]], primary: { label, attr } | null, banner?, pending? }.
function cr16RouteView(c) {
  const u = c.uom, act = (key) => `data-bj16-action="${key}"`;
  const handed = c.status === "WAITING" ? crHandedBanner(c) : null;
  const pick = (v) => (handed ? { ...v, primary: null, banner: handed } : v);
  if (c.route === "PROJECTION") {
    const d = c.app - c.ledger;
    if (!d) return { conclusion: "Đã cập nhật số trên app · chờ kiểm lại", sentence: "Số trên app đã khớp sổ kho. Kiểm lại số rồi đóng hồ sơ.", tone: "info", compare: [["Sổ kho", t7Qty(c.ledger, u)], ["Số trên app", t7Qty(c.app, u)]], primary: { label: "Kiểm lại", attr: act("recheck") } };
    return { conclusion: c.conclusion, sentence: `Số trên app lệch ${t7Qty(Math.abs(d), u)} so với sổ kho. Sổ kho đúng; chỉ cần cập nhật số trên app.`, tone: "warning", compare: [["Sổ kho", t7Qty(c.ledger, u)], ["Số trên app", `${t7Qty(c.app, u)} · ${crDiffText(d, u)}`, true]], primary: { label: "Cập nhật số trên app", attr: act("recover") } };
  }
  if (c.route === "CORRECTION") {
    const rec = c.correctionDone ? cr16Record(c) : null, pending = cr16Pending(c);
    if (c.correctionDone) return { conclusion: "Đã sửa phiếu gốc · chờ kiểm lại", sentence: `Phiếu sửa sai ${rec?.recordId || "—"} đã ghi. Kiểm lại số rồi đóng hồ sơ.`, tone: "info", compare: [["Phiếu gốc", t7Qty(c.source, u)], ["Hoá đơn nhà cung cấp", t7Qty(c.invoice, u)], ["Sổ kho", t7Qty(crBook(c), u)], ["Phiếu sửa sai", `${rec?.recordId || "—"} · −${t7Qty(c.source - c.invoice, u)}`]], primary: { label: "Kiểm lại", attr: act("recheck") } };
    const v = { conclusion: c.conclusion, sentence: `Phiếu ${c.docCode} ghi ${t7Qty(c.source, u)}, hoá đơn chỉ ${t7Qty(c.invoice, u)}. Cần sửa phiếu gốc; không sửa thẳng số tồn.`, tone: "warning", compare: [["Phiếu gốc", `${t7Qty(c.source, u)} · ${crDiffText(c.source - c.invoice, u)}`, true], ["Hoá đơn nhà cung cấp", t7Qty(c.invoice, u)], ["Sổ kho", t7Qty(c.ledger, u)]] };
    return pending ? { ...v, pending, primary: { label: "Xem yêu cầu", attr: act("view-correction") } } : { ...v, primary: { label: "Sửa phiếu gốc", attr: act("fix-source") } };
  }
  if (c.route === "NO_REAL") return { conclusion: c.conclusion, sentence: `Không có lệch thật. Báo cáo lấy số lúc ${c.reportAt}, trước khi nhận hàng ${c.receiptCode} ghi vào kho.`, tone: "info", compare: [[`Báo cáo lúc ${c.reportAt}`, t7Qty(c.report, u)], ["Sổ kho", t7Qty(c.ledger, u)], ["Số trên app", t7Qty(c.app, u)]], primary: { label: "Đóng hồ sơ", attr: act("close") } };
  if (c.route === "LEDGER") return pick({ conclusion: c.conclusion, sentence: "Sổ kho có dấu hiệu sai. App dừng mọi cập nhật tự động cho phạm vi này; cần bộ phận hỗ trợ kiểm tra.", tone: "warning", compare: [["Phiếu gốc", "Có chứng từ"], ["Sổ kho", "Không nhất quán", true]], primary: { label: "Gửi bộ phận hỗ trợ", attr: act("escalate") } });
  if (c.route === "SOURCE") return pick({ conclusion: c.conclusion, sentence: `Phiếu ${c.docCode} chưa khớp dữ liệu kho. Mua hàng cần kiểm lại phiếu; Kho không tự sửa.`, tone: "warning", compare: [["Phiếu mua", c.docCode], ["Sổ kho", "Chưa khớp phiếu", true]], primary: { label: "Chuyển cho Mua hàng", attr: act("to-purchase") } });
  return { conclusion: c.conclusion, banner: { tone: "warning", title: "Chưa đủ bằng chứng kết luận", desc: "Giữ hồ sơ mở cho tới khi xác định được nguyên nhân." }, compare: [["Phiếu gốc", "Chưa xác định"], ["Sổ kho", "Chưa kết luận"]], primary: null };
}

/* ---------- Khung dùng chung ---------- */

function crShell(opts) { return appShell({ extraClass: "k7-wide", ...opts }); }
function crDenied(title, back = false) { return crShell({ title, body: k1Denied({ what: "đối soát", next: "Liên hệ chủ cửa hàng để được cấp quyền.", exitAttr: k1ExitAttr("SCR-078") }), centered: true, back }); }
function crLoading(title, blocks = ["heading", "card", "card"], back = false) { return crShell({ title, body: k1Loading({ blocks }), centered: true, back }); }
function crExit() { return { label: "Về Kho", attr: k1ExitAttr("SCR-078") }; }
function crCompare(rows, title = "So sánh") {
  return `<section class="ac310-surface cr-compare" data-layout-pattern="Grouped surface" data-composed-from="DS v2 / Key-value Row"><div class="ac310-surface__head"><h2>${esc(title)}</h2></div><div class="cr-compare__rows">${rows.map(([label, value, diff]) => ds24KeyValueRow(label, value, false, diff ? "data-cr-diff" : "")).join("")}</div></section>`;
}
function crLockLine(c) { return `<p class="cr-lock">${icon("lock", "icon--sm")}<span>Đang tạm khoá ${esc(c.lockName)}: chưa nhận, xuất hay bán được cho tới khi đóng hồ sơ.</span></p>`; }
function crConclusion(v) {
  return v.banner ? vBanner(v.banner.tone, esc(v.banner.title), esc(v.banner.desc)) : k2Attention([[v.sentence, "", v.tone]], { title: "Kết luận" });
}
function crAside(c) { return crCompare([["Mã", c.id], ["Nguồn tín hiệu", c.signal], ["Mở lúc", c.openedAt]], "Hồ sơ"); }

// Sheet xác nhận (thay SCR-080): mở thì ghi phiên bản bằng chứng đang xem; xác nhận kiểm lại phiên bản trước khi làm.
function crSheetHtml(c) {
  if (!crSheet) return "";
  const nv = String(c.kind || "").toLocaleLowerCase("vi");
  const spec = {
    update: { title: "Cập nhật số trên app theo sổ kho?", description: `Sổ kho và phiếu gốc không đổi. ${c.lockName} vẫn tạm khoá tới khi đóng hồ sơ.`, confirmLabel: "Cập nhật" },
    close: { title: "Đóng hồ sơ?", description: "Không có lệch thật; không cần sửa gì.", confirmLabel: "Đóng hồ sơ" },
    "confirm-done": { title: `Xác nhận ${nv} ${c.doc} đã hoàn tất?`, description: "Dùng tác động đã tồn tại để xác lập kết quả; không ghi lại biến động lần hai.", confirmLabel: "Xác nhận" },
    continue: { title: `Làm tiếp ${nv} ${c.doc}?`, description: "Dùng đúng thao tác cũ, không tạo thao tác mới.", confirmLabel: "Làm tiếp" },
  }[crSheet];
  return k2RejectSheet({ open: true, title: spec.title, description: spec.description, withReason: false, closeAttr: 'data-recon-sheet="cancel"', closeLabel: "Quay lại", confirmAttr: 'data-recon-sheet="confirm"', confirmLabel: spec.confirmLabel });
}

/* ---------- Dựng lại fixture khi trạng thái đặt từ ngoài ---------- */

function crSetState(screenId, state) { stateByScreen[screenId] = state; crExpected[screenId] = state; }
function crRestore() {
  cr16Cases.splice(0, cr16Cases.length, ...bj16InitialCases());
  cr17Cases.splice(0, cr17Cases.length, ...bj17InitialCases());
  cr16SelectedId = "REC-260907-03"; cr17SelectedId = "REC-UNKNOWN-01"; crSheet = null; crSheetOpener = "";
}
function crClose(c, done, at = BJ16_CLOSED_AT) { c.status = "CLOSED"; c.closedAt = at; c.done = done; }
function crHand(c, to) { c.status = "WAITING"; c.handedTo = to; c.sentAt = BJ16_SENT_AT; }
const CR16_PICK = { PROJECTION_MISMATCH: "REC-260907-03", CORRECTION_REQUIRED: "REC-260907-04", NO_REAL_DIFFERENCE: "REC-260907-05", LEDGER_INTEGRITY_RISK: "REC-260907-06", SOURCE_MISMATCH: "REC-260907-07", INSUFFICIENT_EVIDENCE: "REC-260907-09", UNKNOWN_EVIDENCE: "REC-260907-09", LOCKED: "REC-260907-08", CONFLICT: "REC-260907-03" };
const CR17_PICK = { UNKNOWN_EVIDENCE: "REC-UNKNOWN-01", INSUFFICIENT_EVIDENCE: "REC-UNKNOWN-03", CONFLICT: "REC-UNKNOWN-01" };
function crSeed(flow, screenId, state) {
  if (crExpected[screenId] === state) return;
  // Quay về từ BJ-11 / BJ-17 bằng crSwitchFlow: hồ sơ đang chọn đã đúng trạng thái này thì giữ nguyên dữ liệu (cờ correctionDone…).
  if (screenId === "SCR-079" && state === crStateFor(flow)) { crExpected[screenId] = state; return; }
  Object.keys(crExpected).forEach((k) => delete crExpected[k]);
  crExpected[screenId] = state;
  crRestore();
  if (screenId === "SCR-079") {
    const id = (flow === "UIF-17" ? CR17_PICK : CR16_PICK)[state];
    if (id) { if (flow === "UIF-17") cr17SelectedId = id; else cr16SelectedId = id; }
    return;
  }
  const c = cr16Current();
  if (screenId === "SCR-081") { c.planEvidenceVersion = c.recoveryEvidenceVersion = c.evidenceVersion; return; }
  if (screenId === "SCR-082") { c.recoveryEvidenceVersion = c.evidenceVersion; c.appUpdated = true; c.app = c.ledger; return; }
  if (screenId !== "SCR-083") return;
  if (flow === "UIF-17") {
    const k = cr17Cases.find((x) => x.id === (state === "ESCALATED" ? "REC-UNKNOWN-03" : "REC-UNKNOWN-01"));
    cr17SelectedId = k.id;
    if (state === "COMPLETED") bj17Complete(k, "COMMITTED"); else if (state === "ESCALATED") crHand(k, CR_SUPPORT);
    return;
  }
  if (state === "ESCALATED") { cr16SelectedId = "REC-260907-06"; crHand(cr16Current(), CR_SUPPORT); return; }
  if (state === "COMPLETED") { c.appUpdated = true; c.app = c.ledger; crClose(c, "Cập nhật số trên app"); }
}

/* ---------- SCR-078 · Hồ sơ cần kiểm tra (K6, dùng chung BJ-16 / BJ-17) ---------- */

function crListRows() {
  const rows = [];
  for (const c of cr16Cases) {
    const job = cr16Status(c); if (job !== "OPEN" && job !== "WAITING") continue;
    rows.push({ key: `DIFF:${c.id}`, kind: "DIFF", job, id: c.id, title: cr16RouteView(c).conclusion, scope: c.scope, openedAt: c.openedAt, typeName: "Sai lệch", status: crBadge(job, c.route === "LEDGER") });
  }
  for (const c of cr17Cases) {
    const job = cr17Status(c); if (job !== "OPEN" && job !== "WAITING") continue;
    rows.push({ key: `UNKNOWN:${c.id}`, kind: "UNKNOWN", job, id: c.id, title: cr17RouteView(c).conclusion, scope: c.scope, openedAt: c.openedAt, typeName: "Chưa rõ kết quả", status: crBadge(job, false) });
  }
  return rows.map((r, i) => ({ r, i })).sort((a, b) => (a.r.job === b.r.job ? 0 : a.r.job === "OPEN" ? -1 : 1) || a.i - b.i).map((x) => x.r);
}
function crBadge(job, risk) {
  if (job === "WAITING") return { label: "Đang chờ", tone: "Neutral" };
  return risk ? { label: "Nghi sổ kho sai", tone: "Danger" } : { label: "Cần làm", tone: "Warning" };
}
const CR_FILTER_TEST = {
  ALL: () => true,
  DIFF: (r) => r.kind === "DIFF" && r.job === "OPEN",
  UNKNOWN: (r) => r.kind === "UNKNOWN" && r.job === "OPEN",
  WAITING: (r) => r.job === "WAITING",
};
// Home "Cần chú ý": "{a} sai lệch · {b} chưa rõ kết quả"; số = số dòng "Cần làm" (vế bằng 0 thì bỏ vế).
function crAttentionSummary() {
  const open = crListRows().filter((r) => r.job === "OPEN");
  const a = open.filter((r) => r.kind === "DIFF").length, b = open.filter((r) => r.kind === "UNKNOWN").length;
  if (!a && !b) return null;
  return { count: a + b, text: [a ? `${a} sai lệch` : "", b ? `${b} chưa rõ kết quả` : ""].filter(Boolean).join(" · ") };
}
window.__T7_RECON_COUNTS__ = crAttentionSummary;
// Vào 078 từ Hub: "Đối soát sai lệch" → chip "Sai lệch"; Home "Hồ sơ cần kiểm tra" → "Tất cả" (data-cr-entry).
function crSetEntryFilter(flowId, explicit) {
  if (!CR_FLOWS.includes(flowId)) return;
  crQuery = ""; crSheet = null; crSetState("SCR-078", "READY");
  crListFilter = explicit || (flowId === "UIF-17" ? "UNKNOWN" : "DIFF");
}

function render078Recon(state) {
  const title = "Hồ sơ cần kiểm tra", subtitle = "Sai lệch số liệu và thao tác chưa rõ kết quả";
  crSeed(activeFlowId, "SCR-078", state);
  if (state === "PERMISSION_DENIED") return crDenied(title);
  if (state === "LOADING") return crShell({ title, subtitle, body: k1Loading({ blocks: ["search", "row", "row", "row"] }), back: false });
  const all = state === "EMPTY" ? [] : crListRows();
  const text = (r) => ioNormalizeSearch(`${r.id} ${r.title} ${r.scope} ${crSearchExtra(r)}`);
  const q = ioNormalizeSearch(crQuery);
  const rows = state === "FILTER_EMPTY" ? [] : all.filter((r) => CR_FILTER_TEST[crListFilter](r) && (!q || text(r).includes(q))).map((r) => ({
    ...r, subtitle: `${r.scope} · ${r.id}`.replace(/-/g, "\u2011"), searchText: text(r), statusHtml: ds24Badge(r.status.label, r.status.tone),
    itemHtml: `<span class="cr-item"><strong>${esc(r.title)}</strong><small>${esc(r.id)}</small></span>`,
  }));
  const items = CR_FILTERS.map(([k, l]) => [k, l, all.filter(CR_FILTER_TEST[k]).length]);
  const columns = [{ key: "itemHtml", label: "Hồ sơ", html: true }, { key: "typeName", label: "Loại" }, { key: "scope", label: "Phạm vi" }, { key: "openedAt", label: "Mở lúc", mono: true }, { key: "statusHtml", label: "Tình trạng", html: true }];
  const body = k6TaskList({
    search: { value: crQuery, attr: "data-recon-search", placeholder: "Tìm hồ sơ, sản phẩm hoặc mã phiếu" },
    filters: { items, selected: crListFilter, attrName: "data-recon-filter" },
    columns, rows, total: all.length,
    rowAttr: (r) => `data-recon-row="${crAttr(r.key)}" data-recon-search-text="${crAttr(r.searchText)}"`,
    rowOpen: true,
    empty: { title: "Không có hồ sơ cần kiểm tra", description: "Danh sách sẽ cập nhật khi có tín hiệu cần kiểm tra." },
    filterEmpty: { title: "Không có hồ sơ phù hợp", description: "Thử đổi bộ lọc hoặc từ khóa tìm kiếm.", actionLabel: "Xem tất cả", actionAttr: 'data-recon-action="clear-filter"' },
    filterEmptyAttr: "data-recon-filter-empty",
  });
  return crShell({ title, subtitle, body, back: false, centered: state === "EMPTY" });
}
// Mã nghiệp vụ / phiếu của hồ sơ chưa rõ kết quả cũng tìm được.
function crSearchExtra(r) {
  const c = r.kind === "UNKNOWN" ? cr17Cases.find((x) => x.id === r.id) : cr16Cases.find((x) => x.id === r.id);
  return c ? `${c.operation || ""} ${c.doc || ""} ${c.docCode || ""} ${c.kind || ""}` : "";
}

function crOpenRow(key) {
  const sep = key.indexOf(":"), kind = key.slice(0, sep), id = key.slice(sep + 1);
  crSheet = null;
  if (kind === "DIFF") { cr16SelectedId = id; return applyEntry("UIF-16", "case-context", true); }
  cr17SelectedId = id; return applyEntry("UIF-17", "unknown-context", true);
}
onEntry["UIF-16:case-context"] = () => crSetState("SCR-079", cr079StateFor16(cr16Current()));
if (activeFlowId === "UIF-16" && !requestedScreen && onEntry[`UIF-16:${entryMode}`]) onEntry[`UIF-16:${entryMode}`]();

/* ---------- SCR-079 · Bằng chứng & kết luận (BJ-16) ---------- */

function render079BJ16(state) {
  crSeed("UIF-16", "SCR-079", state);
  const title = "Bằng chứng & kết luận";
  if (state === "PERMISSION_DENIED") return crDenied(title);
  if (state === "LOADING") return crLoading(title);
  const c = cr16Current(), v = cr16RouteView(c), subtitle = `${c.id} · ${c.scope}`;
  if (state === "LOCKED") {
    const holder = cr16Cases.find((x) => x.id === c.lockedBy);
    return crShell({ title, subtitle, body: k1Locked({ title: "Phạm vi đang thuộc hồ sơ khác", description: `${c.lockedBy} đang kiểm ${holder?.lockName || c.lockName}. Mở hồ sơ đó để làm tiếp.` }), actions: primaryFooter("Mở hồ sơ đó", 'data-bj16-action="open-locking-case"') });
  }
  const stale = state === "CONFLICT" ? k1Stale({ title: "Kết luận đã thay đổi", description: "Có bằng chứng mới. Xem lại kết luận trước khi làm tiếp.", actionLabel: "Tải lại", actionAttr: 'data-bj16-action="reload"' }) : "";
  const pending = v.pending ? k2Pending({ approver: "chủ cửa hàng", sentAt: v.pending.sentAt, subject: "sửa sai" }) : "";
  const lock = c.locked ? crLockLine(c) : "";
  const main = `${stale}${crConclusion(v)}${pending}${crCompare(v.compare)}${lock}`;
  return crShell({ title, subtitle, body: `${k7Split({ main, aside: crAside(c), asideWebOnly: true })}${stale ? "" : crSheetHtml(c)}`, actions: v.primary && !stale ? primaryFooter(v.primary.label, v.primary.attr) : "" });
}

/* ---------- SCR-081 · Đang cập nhật số trên app ---------- */

function render081BJ16(state) {
  crSeed("UIF-16", "SCR-081", state);
  const title = "Đang cập nhật số trên app", c = cr16Current();
  if (state === "PERMISSION_DENIED") return crDenied(title);
  if (state === "VALIDATION_FAILED" || state === "CONFLICT") {
    return crShell({ title, subtitle: `${c.id} · ${c.scope}`, back: false, body: k1Stale({ title: "Chưa cập nhật được số trên app", description: "Bằng chứng hoặc phạm vi đã thay đổi. Hồ sơ vẫn được giữ mở và sổ kho không bị sửa.", actionLabel: "Về hồ sơ", actionAttr: 'data-bj16-action="to-case"' }) });
  }
  const body = `<div class="k3-column">${k1Loading({ blocks: ["heading", "card", "card"] })}<p class="ac310-note">Bạn có thể rời màn hình; hồ sơ tự cập nhật khi hoàn tất.</p>${crCompare([["Mã", c.id], ["Phạm vi", c.scope]], "Hồ sơ")}</div>`;
  return crShell({ title, back: false, body, actions: k4Footer([{ ...crExit(), primary: true }]) });
}

/* ---------- SCR-082 · Rà soát kết quả ---------- */

function render082BJ16(state) {
  crSeed("UIF-16", "SCR-082", state);
  const title = "Rà soát kết quả", c = cr16Current(), u = c.uom;
  if (state === "PERMISSION_DENIED") return crDenied(title);
  const subtitle = `${c.id} · ${c.scope}`;
  if (state === "MISMATCH_REMAINS") {
    const body = `${vBanner("warning", "Sai lệch vẫn còn", esc(`Hồ sơ vẫn mở, ${c.lockName} vẫn tạm khoá. Quay lại bằng chứng để xem tiếp.`))}${crCompare([["Sổ kho", t7Qty(crBook(c), u)], ["Số trên app", t7Qty(crBook(c) - 1, u)], ["Chênh lệch", `−${t7Qty(1, u)}`, true]])}`;
    return crShell({ title, subtitle, body, actions: primaryFooter("Quay lại bằng chứng", 'data-bj16-action="back-evidence"') });
  }
  const book = crBook(c);
  const body = `${vBanner("success", "Số liệu đã khớp", c.correctionDone ? "Sổ kho đã theo phiếu sửa sai." : "Số trên app khớp sổ kho.")}${crCompare([["Sổ kho", t7Qty(book, u)], ["Số trên app", t7Qty(book, u)], ["Chênh lệch", `0${NBSP}${u}`]])}`;
  return crShell({ title, subtitle, body, actions: k4ReasonFooter({ label: "Đóng hồ sơ", attr: 'data-bj16-action="close-case"', note: `Đóng xong, ${c.lockName} mở khoá.` }) });
}

/* ---------- SCR-083 · Kết quả xử lý (BJ-16) ---------- */

// Còn hồ sơ "Cần làm" thì chính = "Về hồ sơ cần kiểm tra"; hết thì một nút "Về Kho".
function crResultNext(listAttr) {
  const more = crListRows().some((r) => r.job === "OPEN");
  return more ? [{ ...crExit() }, { label: "Về hồ sơ cần kiểm tra", attr: listAttr, primary: true }] : [{ ...crExit(), primary: true }];
}
function render083BJ16(state) {
  crSeed("UIF-16", "SCR-083", state);
  const title = "Kết quả đối soát", c = cr16Current();
  if (state === "PERMISSION_DENIED") return crDenied(title);
  if (state === "PROCESSING") return crLoading(title, ["heading", "card", "row"]);
  const listAttr = 'data-bj16-action="to-list"';
  if (state === "UNKNOWN") {
    return k3Unknown({ title, operation: "Chuyển hồ sơ", scope: `${c.id} · ${c.scope}`, ref: c.id, sentAt: BJ16_SENT_AT, sourceFlow: "UIF-16", exitAttr: crExit().attr, handoff: { operation: c.id, scope: c.scope } });
  }
  if (state === "ESCALATED") {
    const toPurchase = c.route === "SOURCE" || c.handedTo === CR_PURCHASE, to = toPurchase ? CR_PURCHASE : CR_SUPPORT;
    const facts = [["Hồ sơ", c.id], ["Người nhận", to], ...(c.locked ? [["Phạm vi", "Chưa mở khóa"]] : []), ["Gửi lúc", c.sentAt || BJ16_SENT_AT]];
    return k4Result({ screenTitle: title, kind: "warning", title: toPurchase ? "Đã chuyển cho Mua hàng" : "Đã gửi bộ phận hỗ trợ", description: toPurchase ? `Hồ sơ chờ Mua hàng kiểm lại phiếu ${c.docCode}; Kho không tự sửa.` : "Hồ sơ vẫn mở; phạm vi rủi ro tiếp tục được bảo vệ cho tới khi có bằng chứng mới.", facts, next: crResultNext(listAttr) });
  }
  const facts = [["Hồ sơ", c.id], ["Kết luận", c.conclusion], ["Đã làm", c.done || "Không cần làm gì"], ...(c.locked ? [["Phạm vi", "Đã mở khóa"]] : []), ["Đóng lúc", c.closedAt || BJ16_CLOSED_AT]];
  return k4Result({ screenTitle: title, title: "Đã xử lý sai lệch", description: "Hồ sơ được đóng bằng bằng chứng và phạm vi liên quan đã được mở khóa.", facts, next: crResultNext(listAttr) });
}

flowRenderers["UIF-16"] = Object.assign(flowRenderers["UIF-16"] || {}, {
  "SCR-078": render078Recon,
  "SCR-079": render079BJ16,
  "SCR-081": render081BJ16,
  "SCR-082": render082BJ16,
  "SCR-083": render083BJ16,
});
["SCR-078", "SCR-079", "SCR-081", "SCR-082", "SCR-083"].forEach((id) => { renderers[id] = flowScreen(id); });

// SCR-080 đã gộp vào sheet xác nhận ở SCR-079 (v5.18.0); SCR-082 không còn ở UIF-17 (sheet → 083 thẳng): đường cũ mở bằng chứng của hồ sơ.
screenAliases["UIF-16"] = Object.assign(screenAliases["UIF-16"] || {}, { "SCR-080": "SCR-079" });
screenAliases["UIF-17"] = Object.assign(screenAliases["UIF-17"] || {}, { "SCR-080": "SCR-079", "SCR-082": "SCR-079" });
{ const a = screenAliases[activeFlowId]?.[activeScreenId]; if (Array.isArray(a)) { activeFlowId = a[0]; activeScreenId = a[1]; } else if (a) activeScreenId = a; }

/* ---------- Điều hướng ---------- */

function crGo(flow, screenId, state) { activeFlowId = flow; crSheet = null; crSetState(screenId, state); return navigate(screenId); }
function crRerender(focusSelector = "") {
  const top = document.querySelector("#app-screen .app-content")?.scrollTop || 0;
  renderAppScreen();
  const content = document.querySelector("#app-screen .app-content"); if (content) content.scrollTop = top;
  if (focusSelector) crFocus(focusSelector);
}
// getClientRects: phần tử position:fixed (sheet) có offsetParent = null nhưng vẫn hiển thị.
function crVisible(el) { return el.getClientRects().length > 0; }
function crFocus(selector) {
  const el = [...document.querySelectorAll(selector)].find(crVisible);
  if (el) el.focus({ preventScroll: true });
  return el || null;
}
function crToList() { crQuery = ""; return crGo(activeFlowId, "SCR-078", "READY"); }
function crToCase() { return crGo(activeFlowId, "SCR-079", crStateFor(activeFlowId)); }

// Sheet là hộp thoại modal: mở thì focus vào nút đầu, đóng thì trả focus về nút đã mở.
function crOpenSheet(kind, opener) {
  const c = crCase(); crSheet = kind; crSheetOpener = opener;
  c.planEvidenceVersion = c.evidenceVersion; c.planRecord = { operationId: c.operation, scope: c.scope };
  renderAppScreen();
  requestAnimationFrame(() => crFocus('#app-screen [role="dialog"] button'));
}
function crCloseSheet() { const back = crSheetOpener; crSheet = null; crRerender(back); }
// Bằng chứng đổi giữa lúc mở sheet và lúc bấm: đóng sheet, 079 báo "Kết luận đã thay đổi".
function crStale() { crSheet = null; crSetState("SCR-079", "CONFLICT"); return renderAppScreen(); }
function crReload() { const c = crCase(); c.planEvidenceVersion = null; c.planRecord = null; crSetState("SCR-079", crStateFor(activeFlowId)); return renderAppScreen(); }

function crConfirmSheet() {
  const kind = crSheet, c = crCase();
  if (!kind) return;
  if (bj16Num(c.planEvidenceVersion) !== bj16Num(c.evidenceVersion)) return crStale();
  crSheet = null;
  if (kind === "update") {
    c.recoveryEvidenceVersion = c.evidenceVersion;
    crSetState("SCR-081", "REBUILDING"); navigate("SCR-081");
    setTimeout(crRecoveryDone, 250);
    return;
  }
  if (kind === "close") { crClose(c, "Không cần làm gì"); return crGo("UIF-16", "SCR-083", "COMPLETED"); }
  return bj17ConfirmSheet(kind, c);
}
// 081 → 082 khi cập nhật xong (hẹn giờ của prototype, hoặc __VET45_QA__.finishCR16Recovery); chỉ chạy khi còn ở 081.
function crRecoveryDone() {
  if (activeFlowId !== "UIF-16" || activeScreenId !== "SCR-081" || stateByScreen["SCR-081"] !== "REBUILDING") return false;
  const c = cr16Current();
  if (bj16Num(c.recoveryEvidenceVersion) !== bj16Num(c.evidenceVersion)) { crSetState("SCR-081", "CONFLICT"); renderAppScreen(); return true; }
  c.app = c.ledger; c.appUpdated = true;
  crSetState("SCR-082", "READY"); navigate("SCR-082");
  return true;
}
function bj16Escalate(c, to) { crHand(c, to); return crGo("UIF-16", "SCR-083", "ESCALATED"); }
function bj16Close(c) {
  const snap = c.recoveryEvidenceVersion ?? c.planEvidenceVersion;
  if (bj16Num(snap) !== bj16Num(c.evidenceVersion)) { crSetState("SCR-082", "MISMATCH_REMAINS"); return renderAppScreen(); }
  crClose(c, c.route === "CORRECTION" ? `Sửa phiếu ${c.docCode} · ${cr16Record(c)?.recordId || "—"}` : "Cập nhật số trên app");
  return crGo("UIF-16", "SCR-083", "COMPLETED");
}
function bj16ViewCorrection(c) {
  const r = cr16Pending(c); if (!r) return;
  cr11SelectedRequestId = r.id; cr11SelectedId = r.opId; cr11Return = { kind: "case", id: c.id }; bj11ResetUi();
  const screen = bj11CanDecide() ? "SCR-051" : "SCR-053", st = bj11CanDecide() ? "READY" : "PENDING_APPROVAL";
  bj11SetState(screen, st);
  return crSwitchFlow("UIF-11", screen, st);
}

/* ---------- Sự kiện ---------- */

document.addEventListener("input", (event) => {
  if (!CR_FLOWS.includes(activeFlowId) || !event.target.matches("[data-recon-search]")) return;
  crQuery = event.target.value; ioFilterRows("recon", crQuery);
}, true);

CR_FLOWS.forEach((id) => { onDialogClose[id] = () => {
  if (!crSheet) return false;
  crCloseSheet(); return true;
}; });

document.addEventListener("click", (event) => {
  if (!CR_FLOWS.includes(activeFlowId)) return;
  const t = event.target, hit = (sel) => t.closest?.(sel);
  let el;
  if ((el = hit("[data-recon-filter]"))) { event.preventDefault(); crListFilter = el.dataset.reconFilter; return renderAppScreen(); }
  if ((el = hit("[data-recon-row]"))) { event.preventDefault(); return crOpenRow(el.dataset.reconRow); }
  if ((el = hit("[data-recon-sheet]"))) {
    if (el.matches(".sheet-backdrop") && t !== el) return;
    event.preventDefault(); event.stopPropagation();
    return el.dataset.reconSheet === "confirm" ? crConfirmSheet() : crCloseSheet();
  }
  if ((el = hit("[data-recon-action]"))) {
    event.preventDefault(); event.stopPropagation();
    if (el.dataset.reconAction === "clear-filter") { crQuery = ""; crListFilter = "ALL"; if (stateByScreen["SCR-078"] === "FILTER_EMPTY") crSetState("SCR-078", "READY"); return renderAppScreen(); }
    return;
  }
  const a = hit("[data-bj16-action]"); if (!a || a.disabled || activeFlowId !== "UIF-16") return;
  event.preventDefault(); event.stopPropagation();
  const k = a.dataset.bj16Action, c = cr16Current();
  if (k === "recover") return crOpenSheet("update", '[data-bj16-action="recover"]');
  if (k === "close") return crOpenSheet("close", '[data-bj16-action="close"]');
  if (k === "fix-source") { if (!c.correctionOperationId) return; cr11SelectedId = c.correctionOperationId; cr11Return = { kind: "case", id: c.id }; return applyEntry("UIF-11", "correction-from-case", true); }
  if (k === "view-correction") return bj16ViewCorrection(c);
  if (k === "recheck") { c.planEvidenceVersion = c.evidenceVersion; c.recoveryEvidenceVersion = null; return crGo("UIF-16", "SCR-082", "READY"); }
  if (k === "escalate") return bj16Escalate(c, CR_SUPPORT);
  if (k === "to-purchase") return bj16Escalate(c, CR_PURCHASE);
  if (k === "close-case") return bj16Close(c);
  if (k === "back-evidence" || k === "to-case") return crToCase();
  if (k === "to-list") return crToList();
  if (k === "reload") return crReload();
  if (k === "open-locking-case") { const holder = cr16Cases.find((x) => x.id === c.lockedBy); if (!holder) return; cr16SelectedId = holder.id; return crGo("UIF-16", "SCR-079", cr079StateFor16(holder)); }
}, true);

// Đi giữa các màn bằng navigate (kể cả nút quay lại) là đi trong luồng: trạng thái hiện tại là "đã biết", không dựng lại fixture.
CR_FLOWS.forEach((f) => ["SCR-078", "SCR-079", "SCR-081", "SCR-082", "SCR-083"].forEach((id) => {
  const prev = onScreenEnter[`${f}:${id}`];
  onScreenEnter[`${f}:${id}`] = () => { prev?.(); crExpected[id] = stateByScreen[id]; };
}));
// Quay lại: 079 → danh sách; 081 / 082 → bằng chứng của hồ sơ.
onPrevious["UIF-16"] = onPrevious["UIF-17"] = () => {
  crSheet = null;
  if (activeScreenId === "SCR-079") return crToList();
  if (activeScreenId === "SCR-081" || activeScreenId === "SCR-082") return crToCase();
  return crToList();
};

Object.assign(window.__VET45_QA__, {
  bumpCR16Evidence() { const c = cr16Current(); c.evidenceVersion = Number(c.evidenceVersion || 0) + 1; return c.evidenceVersion; },
  finishCR16Recovery() { return crRecoveryDone(); },
});
