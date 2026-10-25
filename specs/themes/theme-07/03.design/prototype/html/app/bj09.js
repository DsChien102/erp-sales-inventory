/* BJ-09 — Tình trạng hàng (UIF-09). Màn: SCR-036 / SCR-037 (K5, shared-problem.js), SCR-038, SCR-041, SCR-056.
 *
 * Thiết kế lại T7-P chặng 4 (v5.13.0): danh sách chung "Hàng cần xử lý" + chi tiết hàng do K5 dựng; file này giữ
 * quy tắc đổi tình trạng (ma trận, căn cứ, ghi sổ), màn 038 (đổi / chờ duyệt / duyệt K2), 041 (K4 / K3), 056 (lịch sử),
 * nguồn dòng cho K5, nguồn "Chờ duyệt" của Home (K2).
 * Dùng từ khuôn: K1, K2, K3, K4, K6 (qua K5), K7, dsChoiceRow, k5LotCard, k5QtyField, k5Evidence.
 */

const BJ09_POLICY = {
  id: "STPOL-INVENTORY-STATE", versionId: "STPOL-V7-20260917-01", version: "7", fixtureHash: "fixture-sha256-policy-v7",
  transitions: {
    SELLABLE: {
      QUARANTINE: { label: "Cách ly", reason: true, evidence: false, approval: true, eligibility: "DECREASE" },
      DAMAGED: { label: "Hỏng", reason: true, evidence: true, approval: true, eligibility: "DECREASE" },
      DEMO: { label: "Dùng thử", reason: true, evidence: false, approval: false, eligibility: "DECREASE" },
    },
    QUARANTINE: {
      SELLABLE: { label: "Bán được", reason: true, evidence: true, approval: true, eligibility: "INCREASE" },
      DAMAGED: { label: "Hỏng", reason: true, evidence: false, approval: true, eligibility: "UNCHANGED" },
      DEMO: { label: "Dùng thử", reason: true, evidence: false, approval: false, eligibility: "UNCHANGED" },
    },
    DAMAGED: { QUARANTINE: { label: "Cách ly", reason: true, evidence: true, approval: true, eligibility: "UNCHANGED" } },
    DEMO: {
      SELLABLE: { label: "Bán được", reason: true, evidence: true, approval: true, eligibility: "INCREASE" },
      QUARANTINE: { label: "Cách ly", reason: true, evidence: false, approval: false, eligibility: "UNCHANGED" },
      DAMAGED: { label: "Hỏng", reason: true, evidence: true, approval: true, eligibility: "UNCHANGED" },
    },
    EXPIRED: {},
  },
};
// Slice định giá theo lô (id lô của t7Lots); một slice đã xác lập giá trị. nob-dh2507 có đơn đang giữ khớp BJ-01 (12 hộp).
const BJ09_SOURCE = {
  "tylo-ty2408": { slices: [{ balanceId: "BAL-TYLO-C", version: 3, valuationState: "VALUATION_CONFIRMED", qty: 11 }], reservationBefore: 0 },
  "amox-am2505": { slices: [{ balanceId: "BAL-AMOX-C", version: 7, valuationState: "VALUATION_CONFIRMED", qty: 2 }], reservationBefore: 0 },
  "glove-nitrile": { slices: [{ balanceId: "BAL-GLOVE-C", version: 3, valuationState: "VALUATION_CONFIRMED", qty: 3 }], reservationBefore: 0 },
  "oil-demo": { slices: [{ balanceId: "BAL-DEMO-C", version: 5, valuationState: "VALUATION_CONFIRMED", qty: 2 }], reservationBefore: 0 },
  "nob-dh2507": { slices: [{ balanceId: "BAL-NOB-C", version: 6, valuationState: "VALUATION_CONFIRMED", qty: 70 }], reservationBefore: 12 },
};
const BJ09_SOURCE_INITIAL = structuredClone(BJ09_SOURCE);
const BJ09_STAFF = "Nguyễn Văn An";
const BJ09_OWNER = "Chủ cửa hàng";
const BJ09_SENT_AT = "17/09/2026 15:02";
const BJ09_RECORDED_AT = "17/09/2026 15:04";

const bj09Requests = [];
let bj09Draft = { destination: "", quantity: "", reason: "", evidence: null };
let bj09Basis = null, bj09Movement = null, bj09Decision = null;
let bj09SelectedRequestId = "";
let bj09RejectOpen = false, bj09RejectReason = "";
let bj09Seq = 1, bj09ReqSeq = 1, bj09StaleOnExecute = false;
let bj09ReturnTo = ""; // màn đầu của luồng khi mở từ sheet lô BJ-01 (SCR-037 / SCR-038): quay lại về SCR-003

const bj09Num = (v) => Number(String(v ?? "").replace(",", ".")) || 0;
const bj09Attr = (v) => escapeAttribute(String(v ?? ""));
function bj09CanDecide() { return ["approver", "owner"].includes(currentActor()); }
function bj09MakerName() { return currentActor() === "owner" ? BJ09_OWNER : BJ09_STAFF; }
function bj09Lot() { return t7Lot(k5SelectedLotId); }
function bj09Transition(lot = bj09Lot(), dest = bj09Draft.destination) { return BJ09_POLICY.transitions[lot.state]?.[dest] || null; }
function bj09Request(id = bj09SelectedRequestId) { return bj09Requests.find((r) => r.id === id) || null; }
function bj09PendingFor(lotId) { return bj09Requests.find((r) => r.lotId === lotId && r.status === "PENDING") || null; }
function bj09UnknownFor(lotId) { return bj09Requests.find((r) => r.lotId === lotId && r.status === "UNKNOWN") || null; }
function bj09Display(lot) { return lot.lot ? `Lô ${lot.lot}` : "Không theo lô"; }

/* ---------- Căn cứ đổi tình trạng ---------- */

function bj09FixtureHash(payload) {
  // Băm xác định cho prototype; bản thật dùng SHA-256 chuẩn.
  const s = JSON.stringify(payload); let h = 2166136261;
  for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619); }
  return `fixture-${(h >>> 0).toString(16).padStart(8, "0")}`;
}
function bj09ResolveSlices(lot, qty) {
  const src = BJ09_SOURCE[lot.id]?.slices || []; let remaining = qty; const out = [];
  for (const slice of src) { if (remaining <= 0) break; const take = Math.min(remaining, slice.qty); if (take > 0) { out.push({ ...slice, quantity: take }); remaining -= take; } }
  return remaining > 0 ? null : out;
}
function bj09EligibleQty(lot) {
  if (lot.state !== "SELLABLE") return 0;
  return (BJ09_SOURCE[lot.id]?.slices || []).filter((x) => x.valuationState === "VALUATION_CONFIRMED").reduce((a, x) => a + x.qty, 0);
}
function bj09Blocker(lot = bj09Lot(), d = bj09Draft) {
  const t = bj09Transition(lot, d.destination), q = bj09Num(d.quantity);
  if (!t) return "Chọn tình trạng mới";
  if (q <= 0) return "Nhập số lượng";
  if (q > lot.qty) return `Tối đa ${t7Qty(lot.qty, lot.uom)}`;
  if (!String(d.reason || "").trim()) return "Nhập lý do";
  if (t.evidence && !d.evidence?.data) return "Thêm ảnh bằng chứng";
  if (!bj09ResolveSlices(lot, q)) return "Nhập số lượng";
  return "";
}
function bj09BuildBasis(lot, d, basisId) {
  const t = bj09Transition(lot, d.destination), q = bj09Num(d.quantity), slices = bj09ResolveSlices(lot, q);
  if (!t || !slices) return null;
  const src = BJ09_SOURCE[lot.id] || { reservationBefore: 0 };
  const beforeEligible = bj09EligibleQty(lot);
  const confirmedMoved = slices.filter((z) => z.valuationState === "VALUATION_CONFIRMED").reduce((a, z) => a + z.quantity, 0);
  const afterEligible = Math.max(0, beforeEligible - (lot.state === "SELLABLE" ? confirmedMoved : 0) + (d.destination === "SELLABLE" ? confirmedMoved : 0));
  const reservationAfter = Math.min(src.reservationBefore || 0, afterEligible);
  const payload = {
    basisId: basisId || `SCB-1709-${String(bj09Seq++).padStart(3, "0")}`, itemId: lot.id, product: lot.name, lot: lot.lot, from: lot.state, to: d.destination,
    quantity: q, uom: lot.uom, sourceSlices: slices, policyVersionId: BJ09_POLICY.versionId, policyHash: BJ09_POLICY.fixtureHash,
    reason: String(d.reason).trim(), evidence: d.evidence ? { file: d.evidence.file, data: d.evidence.data } : null, businessDate: T7_BUSINESS_DATE, expiry: lot.expiry,
    availability: { before: beforeEligible, after: afterEligible },
    reservationImpact: { before: src.reservationBefore || 0, after: reservationAfter, shortfall: Math.max(0, (src.reservationBefore || 0) - reservationAfter), allocationReviewRequired: (src.reservationBefore || 0) > reservationAfter },
  };
  payload.basisHash = bj09FixtureHash(payload);
  return Object.freeze(payload);
}
function bj09ResetDraft() { bj09Draft = { destination: "", quantity: "", reason: "", evidence: null }; bj09Basis = null; bj09Decision = null; bj09RejectOpen = false; bj09RejectReason = ""; bj09Movement = null; bj09StaleOnExecute = false; }
function bj09CreateRequest(lot, basis, maker, status = "PENDING") {
  const req = { id: `ST-260917-${String(bj09ReqSeq++).padStart(2, "0")}`, lotId: lot.id, from: basis.from, to: basis.to, qty: basis.quantity, uom: basis.uom, reason: basis.reason, evidence: basis.evidence, basis, maker, sentAt: BJ09_SENT_AT, status, decisionReason: "" };
  bj09Requests.push(req); return req;
}

/* ---------- Ghi sổ (hệ thống) ---------- */

function bj09Stale() { bj09SetState("SCR-041", "STATE_CHANGE_BASIS_STALE"); return false; }
function bj09Commit(basis, approver) {
  if (!basis || bj09StaleOnExecute) return bj09Stale();
  const x = t7Lots.find((z) => z.id === basis.itemId);
  if (!x || x.state !== basis.from || x.qty < basis.quantity || BJ09_POLICY.versionId !== basis.policyVersionId) return bj09Stale();
  const slices = bj09ResolveSlices(x, basis.quantity);
  if (!slices) return bj09Stale();
  const originalQty = x.qty;
  let movedLotId = x.id;
  if (basis.quantity === x.qty) x.state = basis.to;
  else {
    x.qty = Number((x.qty - basis.quantity).toFixed(6));
    movedLotId = `${x.id}-${basis.to.toLowerCase()}`;
    const moved = t7Lots.find((z) => z.id === movedLotId);
    const movedSlices = basis.sourceSlices.map((z) => ({ balanceId: `${z.balanceId}-to`, version: 1, valuationState: z.valuationState, qty: z.quantity }));
    if (moved) { moved.qty += basis.quantity; BJ09_SOURCE[movedLotId].slices.push(...movedSlices); }
    else { t7Lots.push({ id: movedLotId, name: x.name, code: x.code, lot: x.lot, expiry: x.expiry, qty: basis.quantity, uom: x.uom, state: basis.to, source: x.source, unitCost: x.unitCost }); BJ09_SOURCE[movedLotId] = { slices: movedSlices, reservationBefore: 0 }; }
  }
  const src = BJ09_SOURCE[basis.itemId];
  let rem = basis.quantity; for (const sl of src.slices) { if (rem <= 0) break; const take = Math.min(rem, sl.qty); sl.qty -= take; rem -= take; }
  src.reservationBefore = basis.reservationImpact.after;
  bj09Movement = { id: `MOV-STATE-${String(bj09Seq++).padStart(3, "0")}`, lotId: movedLotId, product: basis.product, lot: basis.lot, from: basis.from, to: basis.to, quantity: basis.quantity, uom: basis.uom, remainingSource: originalQty - basis.quantity, reservationImpact: basis.reservationImpact, approver, recordedAt: BJ09_RECORDED_AT };
  bj09SetState("SCR-041", "COMPLETED");
  return true;
}

/* ---------- Dựng lại fixture khi trạng thái đặt từ ngoài (bài học chặng 3: io06Seed) ---------- */

const bj09Expected = {};
let bj09Seeded = false;
function bj09SetState(screenId, state) { stateByScreen[screenId] = state; bj09Expected[screenId] = state; }
function bj09Restore() {
  t7Lots.splice(0, t7Lots.length, ...structuredClone(T7_LOTS_INITIAL));
  Object.keys(BJ09_SOURCE).forEach((k) => delete BJ09_SOURCE[k]);
  Object.assign(BJ09_SOURCE, structuredClone(BJ09_SOURCE_INITIAL));
  bj09Requests.splice(0, bj09Requests.length, ...bj09InitialRequests());
  bj09ResetDraft(); bj09Seq = 2; bj09ReqSeq = 1; bj09SelectedRequestId = "";
  k5Filter = "ALL"; k5Query = ""; k5SelectedLotId = "amox-am2505";
  // Yêu cầu trả (BJ-07) và đề nghị tiêu hủy (BJ-10) cũng dựng lại, để danh sách chung 036 không mang dữ liệu của ca trước.
  if (typeof bj07Restore === "function") bj07Restore();
  if (typeof bj10Restore === "function") bj10Restore();
}
function bj09InitialRequests() {
  const lot = structuredClone(T7_LOTS_INITIAL.find((l) => l.id === "oil-demo"));
  const draft = { destination: "SELLABLE", quantity: "2", reason: "Hết đợt trưng bày, hàng còn nguyên hộp", evidence: { file: "anh-hang-con-nguyen-hop.jpg", data: k5SampleEvidenceData("Còn nguyên hộp") } };
  const basis = bj09BuildBasis(lot, draft, "SCB-1709-001");
  return [{ id: "ST-260915-01", lotId: "oil-demo", from: "DEMO", to: "SELLABLE", qty: 2, uom: "chai", reason: draft.reason, evidence: draft.evidence, basis, maker: BJ09_STAFF, sentAt: "15/09/2026 16:20", status: "PENDING", decisionReason: "" }];
}
function bj09SampleDraft() { return { destination: "DAMAGED", quantity: "2", reason: "Bao bì rách, không còn dùng được", evidence: { file: "anh-hien-trang-hang.jpg", data: k5SampleEvidenceData("Bao bì rách") } }; }
function bj09Seed(screenId, state) {
  if (bj09Expected[screenId] === state) return;
  if (!bj09Seeded && screenId === "SCR-036" && state === "READY") { bj09Expected[screenId] = state; return; }
  bj09Seeded = true;
  Object.keys(bj09Expected).forEach((k) => delete bj09Expected[k]);
  bj09Expected[screenId] = state;
  bj09Restore();
  if (screenId === "SCR-036") { k5Query = state === "FILTER_EMPTY" ? "zzz" : ""; return; }
  if (screenId === "SCR-037") { k5SelectedLotId = state === "EXPIRED" ? "tylo-ty2408" : "amox-am2505"; return; }
  if (screenId === "SCR-038") {
    if (state === "APPROVAL_REVIEW" || state === "SELF_APPROVAL_NOT_ALLOWED") { bj09SelectedRequestId = "ST-260915-01"; k5SelectedLotId = "oil-demo"; return; }
    if (state === "PENDING_APPROVAL") { bj09Draft = bj09SampleDraft(); const req = bj09CreateRequest(bj09Lot(), bj09BuildBasis(bj09Lot(), bj09Draft), BJ09_STAFF); bj09SelectedRequestId = req.id; return; }
    if (state === "STATE_CHANGE_BASIS_STALE" || state === "CONFLICT") { bj09Draft = bj09SampleDraft(); bj09Basis = bj09BuildBasis(bj09Lot(), bj09Draft); }
    return;
  }
  if (screenId === "SCR-041") {
    if (state === "EXPIRED") { k5SelectedLotId = "tylo-ty2408"; return; }
    bj09Draft = bj09SampleDraft(); const lot = bj09Lot(), basis = bj09BuildBasis(lot, bj09Draft);
    const req = bj09CreateRequest(lot, basis, BJ09_STAFF); bj09SelectedRequestId = req.id; bj09Basis = basis;
    if (state === "COMPLETED") { req.status = "APPROVED"; bj09Commit(basis, BJ09_OWNER); bj09Expected[screenId] = state; stateByScreen[screenId] = state; }
    else if (state === "UNKNOWN") req.status = "PENDING";
    else if (state === "REJECTED_EXECUTION") { req.status = "REJECTED"; req.decisionReason = "Thiếu ảnh bằng chứng"; }
  }
}

/* ---------- Dùng chung ---------- */

function bj09Shell(opts) { return appShell({ extraClass: "k7-wide", ...opts }); }
function bj09Denied(title, back = false) { return bj09Shell({ title, body: k1Denied({ what: "xử lý hàng có vấn đề", next: "Liên hệ chủ cửa hàng để được cấp quyền.", exitAttr: k1ExitAttr("SCR-036") }), centered: true, back }); }
function bj09ExitFooter() { return k4Footer([{ label: "Về hàng cần xử lý", attr: 'data-k5-action="to-list"', primary: true }]); }
function bj09FromTo(basis) { return `${t7LotStateLabel(basis.from)} → ${t7LotStateLabel(basis.to)}`; }
function bj09AfterRows(basis) {
  const u = basis.uom, r = basis.reservationImpact;
  const rows = basis.availability.before === basis.availability.after ? [] : [["Khả dụng bán", `${basis.availability.before} → ${basis.availability.after} ${u}`, "info"]];
  if (r.shortfall > 0) rows.push(["Đơn đang giữ", `${r.shortfall} ${u} cần phân bổ lại`, "warning"]);
  rows.push(["Tổng tồn và giá trị không đổi.", "", "info"]);
  return rows;
}
function bj09EvidenceCard(ev) {
  if (!ev?.data) return `<div class="bj06-evidence-card bj06-evidence-card--empty">${icon("fileText", "icon--sm")}<span>Chưa có ảnh bằng chứng</span></div>`;
  return `<div class="bj06-evidence-card"><img src="${ev.data}" alt="Ảnh bằng chứng ${esc(ev.file)}"><span>${esc(ev.file)}</span></div>`;
}
function bj09RequestFacts(req) {
  const lot = t7Lot(req.lotId);
  return [["Sản phẩm", lot.name], ["Lô", lot.lot || "Không theo lô"], ["Đổi sang", t7LotStateLabel(req.to)], ["Số lượng", t7Qty(req.qty, req.uom)], ["Lý do", req.reason]];
}

/* ---------- SCR-038 Đổi tình trạng ---------- */

function bj09FieldErrors(lot, d, show) {
  if (!show) return {};
  const t = bj09Transition(lot, d.destination), q = bj09Num(d.quantity);
  return {
    destination: t ? "" : "Chọn tình trạng mới",
    quantity: q <= 0 ? "Nhập số lượng" : q > lot.qty ? `Tối đa ${t7Qty(lot.qty, lot.uom)}` : "",
    reason: String(d.reason || "").trim() ? "" : "Nhập lý do",
    evidence: t?.evidence && !d.evidence?.data ? "Thêm ảnh bằng chứng" : "",
  };
}
function bj09AfterHtml(lot = bj09Lot(), d = bj09Draft) {
  const q = bj09Num(d.quantity);
  if (!bj09Transition(lot, d.destination) || q <= 0 || q > lot.qty) return "";
  const basis = bj09BuildBasis(lot, d, "PREVIEW");
  return basis ? ds24SectionTitle("Sau khi đổi") + k2Attention(bj09AfterRows(basis), { title: "" }) : "";
}
function bj09FormMain(lot, errors) {
  const t = bj09Transition(lot);
  const dests = Object.entries(BJ09_POLICY.transitions[lot.state] || {});
  if (!dests.length) return vBanner("warning", "Lô đã hết hạn", `Hết hạn theo ngày nghiệp vụ ${T7_BUSINESS_DATE}; hệ thống tự loại khỏi khả dụng.`);
  const choices = dests.map(([code, cfg]) => dsChoiceRow({ title: cfg.label, subtitle: cfg.approval ? "Cần chủ cửa hàng duyệt" : "Ghi nhận ngay", selected: bj09Draft.destination === code, attrs: `data-bj09-destination="${code}"` })).join("");
  const dest = `<section class="bj06-section">${ds24SectionTitle("Đổi sang")}<div class="ds-choice-list" role="radiogroup" aria-label="Đổi sang">${choices}</div>${errors.destination ? `<small class="field-error" role="alert">${esc(errors.destination)}</small>` : ""}</section>`;
  const qty = k5QtyField({ value: bj09Draft.quantity, max: lot.qty, uom: lot.uom, attr: "data-bj09-qty", fillAttr: "data-bj09-qty-fill", error: errors.quantity });
  const reason = `${icTextarea("Lý do", bj09Draft.reason, "data-bj09-reason", "Nhập lý do")}${errors.reason ? `<small class="field-error" role="alert">${esc(errors.reason)}</small>` : ""}`;
  const evidence = t?.evidence ? k5Evidence({ owner: "bj09", evidence: bj09Draft.evidence, error: errors.evidence, hint: t.approval ? "Ảnh sẽ gửi kèm yêu cầu duyệt" : "" }) : "";
  return `<div class="bj09-form">${k5LotCard({ lot, compact: true })}${dest}${qty}${reason}${evidence}<div data-bj09-after>${bj09AfterHtml(lot)}</div></div>`;
}
function bj09SummaryAside(lot) {
  return ac310KeyValueSurface("Tóm tắt", [["Sản phẩm", lot.name], ["Mã", lot.code], ["Lô", lot.lot || "Không theo lô"], ["Tình trạng", t7LotStateLabel(lot.state)], ["Tồn vật lý", t7Qty(lot.qty, lot.uom)]]);
}
function render038BJ09(state) {
  bj09Seed("SCR-038", state);
  const title = "Đổi tình trạng", reviewTitle = "Duyệt đổi tình trạng";
  if (state === "PERMISSION_DENIED") return bj09Denied(title);
  if (state === "LOADING") return bj09Shell({ title, body: k1Loading({ blocks: ["heading", "card", "card"] }) });
  const lot = bj09Lot();
  const sub = `${lot.name} · ${bj09Display(lot)}`;
  if (state === "LOCKED") return bj09Shell({ title, subtitle: sub, body: `${k1Locked({ title: "Đang thuộc phạm vi kiểm kê", description: "Không thể đổi tình trạng khi phạm vi đang khóa." })}${k5LotCard({ lot })}` });
  if (state === "STATE_CHANGE_BASIS_STALE" || state === "CONFLICT") return bj09Shell({ title, subtitle: sub, body: `${k1Stale({ title: "Cần lập lại yêu cầu", description: "Dữ liệu đã thay đổi; quyết định cũ không còn hiệu lực.", actionLabel: "Lập lại yêu cầu", actionAttr: 'data-bj09-action="rebuild"' })}${k5LotCard({ lot, compact: true })}` });
  const req = bj09Request();
  if (state === "SELF_APPROVAL_NOT_ALLOWED") return bj09Shell({ title: reviewTitle, body: vBanner("warning", "Không thể tự duyệt", "Chỉ chủ cửa hàng duyệt đổi tình trạng."), back: false, actions: bj09ExitFooter() });
  if (state === "PENDING_APPROVAL") {
    if (!req) return bj09Shell({ title, subtitle: sub, body: k5LotCard({ lot }), back: false, actions: bj09ExitFooter() });
    const rlot = t7Lot(req.lotId);
    return bj09Shell({ title, subtitle: `${rlot.name} · ${bj09Display(rlot)}`, body: k2Pending({ approver: "chủ cửa hàng", sentAt: req.sentAt, facts: bj09RequestFacts(req) }), back: false, actions: bj09ExitFooter() });
  }
  if (state === "APPROVAL_REVIEW") {
    if (!req || req.status !== "PENDING") return bj09Shell({ title: reviewTitle, body: k1Locked({ title: "Công việc đã có quyết định", description: "Mở kết quả phiên để xem trạng thái hiện hành." }), back: false, actions: bj09ExitFooter() });
    const b = req.basis, rlot = t7Lot(req.lotId);
    const stateName = (s) => t7LotStateLabel(s).replace(/ /g, NBSP);
    const question = `Duyệt đổi ${t7Qty(req.qty, req.uom)} ${rlot.name}${rlot.lot ? ` lô ${rlot.lot}` : ""} từ ${stateName(req.from)} sang ${stateName(req.to)}?`;
    // "Cần chú ý" chỉ cho dòng cảnh báo (đơn đang giữ cần phân bổ lại); dòng thông tin vào khối "Sau khi đổi".
    const after = bj09AfterRows(b), warn = after.filter((r) => r[2] === "warning"), info = after.filter((r) => r[2] !== "warning");
    const detail = info.length ? ds24SectionTitle("Sau khi đổi") + k2Attention(info, { title: "" }) : "";
    const decision = k2Decision({ question, maker: req.maker, sentAt: req.sentAt, attention: warn, facts: [["Lý do", req.reason]], detail });
    const evidence = `<section class="bj06-section">${ds24SectionTitle("Ảnh bằng chứng")}${bj09EvidenceCard(req.evidence)}</section>`;
    const sheet = k2RejectSheet({ open: bj09RejectOpen, title: "Từ chối yêu cầu?", reason: bj09RejectReason, reasonAttr: "data-bj09-reject-reason", confirmAttr: 'data-bj09-action="reject-confirm"', closeAttr: 'data-bj09-action="reject-close"' });
    return bj09Shell({ title: reviewTitle, body: `${k7Split({ main: decision, aside: evidence })}${sheet}`, actions: ac310ApprovalFooter('data-bj09-action="reject-open"', 'data-bj09-action="approve"', "Duyệt") });
  }
  const errors = bj09FieldErrors(lot, bj09Draft, state === "VALIDATION_ERROR");
  const t = bj09Transition(lot), blocker = bj09Blocker(lot);
  const noForm = !Object.keys(BJ09_POLICY.transitions[lot.state] || {}).length;
  const body = k7Split({ main: bj09FormMain(lot, errors), aside: bj09SummaryAside(lot), asideWebOnly: true });
  return bj09Shell({ title, subtitle: sub, body, actions: noForm ? "" : k4ReasonFooter({ label: t?.approval ? "Gửi phê duyệt" : "Đổi tình trạng", attr: 'data-bj09-action="submit"', disabled: Boolean(blocker), reason: blocker }) });
}

/* ---------- SCR-041 Kết quả đổi tình trạng (K4 / K3) ---------- */

function render041BJ09(state) {
  bj09Seed("SCR-041", state);
  const title = "Kết quả thay đổi";
  if (state === "PERMISSION_DENIED") return bj09Denied(title);
  if (state === "PROCESSING") return bj09Shell({ title, body: k1Loading({ blocks: ["heading", "card", "card"] }), centered: true, back: false });
  const lot = bj09Lot(), toList = { label: "Về hàng cần xử lý", attr: 'data-k5-action="to-list"' };
  if (state === "PENDING_APPROVAL") {
    const req = bj09Request();
    return bj09Shell({ title, body: req ? k2Pending({ approver: "chủ cửa hàng", sentAt: req.sentAt, facts: bj09RequestFacts(req) }) : k5LotCard({ lot }), back: false, actions: bj09ExitFooter() });
  }
  if (state === "UNKNOWN") {
    const req = bj09Request();
    return k3Unknown({ operation: "Đổi tình trạng hàng", scope: `${lot.name} · ${bj09Display(lot)}`, ref: req?.id || "ST-260917-01", sentAt: "17/09/2026 15:04", sourceFlow: "UIF-09", exitAttr: k1ExitAttr("SCR-036") });
  }
  if (state === "STATE_CHANGE_BASIS_STALE" || state === "REJECTED_EXECUTION" || state === "REJECTED") {
    const req = bj09Request();
    const facts = [["Sản phẩm", lot.name], ...(req?.decisionReason ? [["Lý do từ chối", req.decisionReason]] : []), ["Tác động tồn kho", "Không có"]];
    return k4Result({ screenTitle: title, kind: "warning", title: "Yêu cầu chưa được thực hiện", description: "Tình trạng và tồn kho không thay đổi. Nếu căn cứ đã thay đổi, cần lập yêu cầu mới.", facts, next: [{ ...toList, primary: true }] });
  }
  if (state === "EXPIRED") {
    return k4Result({ screenTitle: title, kind: "warning", title: "Lô đã hết hạn", description: `Theo ngày nghiệp vụ ${T7_BUSINESS_DATE}, hệ thống đã loại lượng hàng này khỏi khả dụng bán.`, facts: [["Tồn vật lý", t7Qty(lot.qty, lot.uom)], ["Khả dụng bán", t7Qty(0, lot.uom)], ["Tác động giá trị", "Không đổi"]], next: [toList, { label: "Đề nghị tiêu hủy", attr: 'data-k5-action="request-disposal"', primary: true }] });
  }
  const m = bj09Movement;
  if (!m) return bj09Shell({ title, body: k1Loading({ blocks: ["heading", "card", "card"] }), centered: true, back: false });
  const r = m.reservationImpact;
  const facts = [["Sản phẩm", m.product], ...(m.lot ? [["Lô", m.lot]] : []), ["Đã chuyển", `${t7Qty(m.quantity, m.uom)} · ${t7LotStateLabel(m.from)} → ${t7LotStateLabel(m.to)}`], ["Còn ở trạng thái nguồn", t7Qty(m.remainingSource, m.uom)], ["Người duyệt", m.approver], ["Ghi nhận lúc", m.recordedAt]];
  if (r.shortfall > 0) facts.push(["Cần phân bổ lại", t7Qty(r.shortfall, m.uom)]);
  const toDamaged = m.to === "DAMAGED";
  k5SelectedLotId = toDamaged ? m.lotId : k5SelectedLotId;
  return k4Result({
    screenTitle: title, title: "Đã cập nhật tình trạng", description: "Cùng lượng hàng đã được phân loại lại; tổng tồn vật lý và giá trị không thay đổi.", facts,
    button: icSecondary("Xem biến động", 'data-bj09-action="history"'),
    next: toDamaged ? [toList, { label: "Đề nghị tiêu hủy", attr: 'data-k5-action="request-disposal"', primary: true }] : [{ ...toList, primary: true }],
  });
}

/* ---------- SCR-056 Lịch sử tình trạng ---------- */

function render056BJ09(state) {
  const back = "bj09-history-back";
  if (state === "PERMISSION_DENIED") return bj09Denied("Lịch sử tình trạng", true);
  if (state === "LOADING") return bj09Shell({ title: "Lịch sử tình trạng", body: k1Loading({ blocks: ["heading", "card", "card"] }), backAction: back });
  if (bj09Movement) {
    const m = bj09Movement;
    const body = `${icHeaderRows([["Sản phẩm", m.product, true], ["Lô", m.lot || "Không theo lô"], ["Biến động", `${t7LotStateLabel(m.from)} → ${t7LotStateLabel(m.to)}`], ["Số lượng", t7Qty(m.quantity, m.uom)], ["Ghi nhận lúc", m.recordedAt]])}<p class="io-footnote">Việc đổi tình trạng không làm thay đổi giá trị ghi sổ của lượng hàng này.</p>`;
    return bj09Shell({ title: "Chi tiết biến động", body, backAction: back });
  }
  const x = bj09Lot();
  const body = `${ac310ProductRow({ name: x.name, code: x.code, meta: bj09Display(x), badge: t7LotStateLabel(x.state), tone: t7LotTone(x.state), status: true })}${ac310AuditSurface("", [ac310AuditItem("Update", "Bán được → Cách ly", `07/09/2026 · 09:14 · ${BJ09_STAFF} · Bao bì có dấu hiệu bất thường`), ac310AuditItem("Create", "Nhận vào kho", "01/09/2026 · 08:00 · Tình trạng ban đầu: Bán được")])}`;
  return bj09Shell({ title: "Lịch sử tình trạng", body, backAction: back });
}

/* ---------- Sự kiện ---------- */

function bj09Rerender(focusSelector = "") {
  const top = document.querySelector("#app-screen .app-content")?.scrollTop || 0;
  renderAppScreen();
  const content = document.querySelector("#app-screen .app-content"); if (content) content.scrollTop = top;
  if (focusSelector) [...document.querySelectorAll(focusSelector)].find((el) => el.offsetParent !== null)?.focus({ preventScroll: true });
}
// Gõ vào ô không dựng lại màn (giữ focus): chỉ cập nhật khối "Sau khi đổi", lỗi vượt lượng và chân.
function bj09Sync() {
  if (activeScreenId !== "SCR-038") return;
  const lot = bj09Lot(), blocker = bj09Blocker(lot);
  document.querySelectorAll("[data-bj09-after]").forEach((el) => { el.innerHTML = bj09AfterHtml(lot); });
  document.querySelectorAll('[data-bj09-action="submit"]').forEach((b) => { b.disabled = Boolean(blocker); });
  document.querySelectorAll(".app-actions [data-k4-reason]").forEach((p) => { p.textContent = blocker; p.hidden = !blocker; });
  const q = bj09Num(bj09Draft.quantity), over = q > lot.qty;
  document.querySelectorAll(".k5-qty .k7-edit").forEach((el) => {
    el.classList.toggle("k7-edit--error", over);
    el.querySelector("input")?.toggleAttribute("aria-invalid", over);
    let msg = el.querySelector(".field-error");
    if (over && !msg) { msg = document.createElement("small"); msg.className = "field-error"; msg.setAttribute("role", "alert"); el.appendChild(msg); }
    if (msg) { msg.textContent = `Tối đa ${t7Qty(lot.qty, lot.uom)}`; msg.hidden = !over; }
  });
}

k5RegisterEvidence("bj09", { set(ev) { bj09Draft.evidence = ev; }, rerender() { bj09Rerender(); } });

document.addEventListener("input", (event) => {
  if (activeFlowId !== "UIF-09") return;
  const t = event.target;
  if (t.matches("[data-bj09-qty]")) { bj09Draft.quantity = t.value; return bj09Sync(); }
  if (t.matches("[data-bj09-reason]")) { bj09Draft.reason = t.value; return bj09Sync(); }
  if (t.matches("[data-bj09-reject-reason]")) { bj09RejectReason = t.value; const b = document.querySelector('[data-bj09-action="reject-confirm"]'); if (b) b.disabled = !bj09RejectReason.trim(); }
}, true);

// Sheet từ chối là modal: Esc đóng, Tab chỉ đi vòng trong hộp thoại.
window.addEventListener("keydown", (event) => {
  if (activeFlowId !== "UIF-09" || !bj09RejectOpen) return;
  if (event.key === "Escape") { event.preventDefault(); bj09RejectOpen = false; return renderAppScreen(); }
  const dialog = event.key === "Tab" && document.querySelector('#app-screen [role="dialog"]');
  if (!dialog) return;
  const items = [...dialog.querySelectorAll("button:not([disabled]), [href], input, textarea, [tabindex]:not([tabindex='-1'])")].filter((el) => el.offsetParent !== null);
  if (!items.length) return;
  const first = items[0], last = items[items.length - 1], at = document.activeElement;
  if (event.shiftKey ? (at === first || !dialog.contains(at) || at === dialog) : (at === last || !dialog.contains(at))) { event.preventDefault(); (event.shiftKey ? last : first).focus(); }
}, true);

function bj09Submit() {
  const lot = bj09Lot();
  if (bj09Blocker(lot)) return;
  const basis = bj09BuildBasis(lot, bj09Draft), t = bj09Transition(lot);
  bj09Basis = basis; bj09Decision = null;
  if (t.approval) {
    const req = bj09CreateRequest(lot, basis, bj09MakerName());
    bj09SelectedRequestId = req.id; bj09SetState("SCR-038", "PENDING_APPROVAL");
    renderAppScreen(); return showToast("Đã gửi chủ cửa hàng duyệt", "success");
  }
  bj09Commit(basis, "Không cần duyệt");
  return navigate("SCR-041");
}
function bj09Decide(approve) {
  const req = bj09Request();
  if (!bj09CanDecide()) { bj09RejectOpen = false; bj09SetState("SCR-038", "SELF_APPROVAL_NOT_ALLOWED"); return renderAppScreen(); }
  if (!req || req.status !== "PENDING") { bj09SetState("SCR-038", "APPROVAL_REVIEW"); return renderAppScreen(); }
  k5SelectedLotId = req.lotId;
  if (approve) {
    bj09Decision = { decision: "APPROVE", basisHash: req.basis.basisHash, actor: "approver", decidedAt: BJ09_RECORDED_AT };
    req.status = bj09Commit(req.basis, BJ09_OWNER) ? "APPROVED" : "STALE";
    return navigate("SCR-041");
  }
  if (!bj09RejectReason.trim()) return;
  req.status = "REJECTED"; req.decisionReason = bj09RejectReason.trim(); bj09RejectOpen = false;
  bj09Decision = { decision: "REJECT", basisHash: req.basis.basisHash, reason: req.decisionReason, actor: "approver", decidedAt: BJ09_RECORDED_AT };
  bj09SetState("SCR-041", "REJECTED_EXECUTION");
  return navigate("SCR-041");
}

// Nhóm "Đổi sang" là radiogroup: mũi tên đổi lựa chọn (Space / Enter chọn dòng đang focus).
document.addEventListener("keydown", (event) => {
  if (activeFlowId !== "UIF-09" || !["ArrowDown", "ArrowUp", "ArrowLeft", "ArrowRight"].includes(event.key)) return;
  const radio = event.target.closest?.('[role="radio"]'), group = radio?.closest('[role="radiogroup"]');
  if (!group) return;
  const items = [...group.querySelectorAll('[role="radio"]:not([disabled])')], i = items.indexOf(radio);
  if (i < 0) return;
  event.preventDefault();
  const next = items[(i + (event.key === "ArrowDown" || event.key === "ArrowRight" ? 1 : items.length - 1)) % items.length];
  next.focus(); next.click();
}, true);

// Ở pha capture: k2RejectSheet chặn nổi bọt (onclick stopPropagation) nên chỉ pha capture mới thấy nút trong sheet.
document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-09") return;
  const t = event.target, hit = (sel) => t.closest?.(sel);
  let el;
  if (hit('[data-action="bj09-history-back"]')) { event.preventDefault(); event.stopImmediatePropagation(); return navigate("SCR-037"); }
  if ((el = hit("[data-bj09-destination]"))) { event.preventDefault(); bj09Draft.destination = el.dataset.bj09Destination; if (!bj09Transition()?.evidence) bj09Draft.evidence = null; return bj09Rerender(`[data-bj09-destination="${el.dataset.bj09Destination}"]`); }
  if (hit("[data-bj09-qty-fill]")) { event.preventDefault(); bj09Draft.quantity = String(bj09Lot().qty); return bj09Rerender("[data-bj09-qty]"); }
  const a = hit("[data-bj09-action]"); if (!a) return;
  if (a.matches(".sheet-backdrop") && t !== a) return;
  event.preventDefault(); event.stopPropagation(); if (a.disabled) return;
  const k = a.dataset.bj09Action;
  if (k === "submit") return bj09Submit();
  if (k === "approve") return bj09Decide(true);
  if (k === "reject-open") { if (!bj09CanDecide()) return bj09Decide(false); bj09RejectOpen = true; bj09RejectReason = ""; return renderAppScreen(); }
  if (k === "reject-close") { bj09RejectOpen = false; return renderAppScreen(); }
  if (k === "reject-confirm") return bj09Decide(false);
  if (k === "rebuild") { bj09ResetDraft(); bj09SetState("SCR-038", "READY"); return renderAppScreen(); }
  if (k === "history") { bj09SetState("SCR-056", "READY"); return navigate("SCR-056"); }
}, true);

// Đi giữa các màn bằng navigate (kể cả nút quay lại) là đi trong luồng: trạng thái hiện tại là "đã biết", không dựng lại fixture.
K5_FLOWS.forEach((f) => ["SCR-036", "SCR-037", "SCR-038", "SCR-041", "SCR-056"].forEach((id) => { onScreenEnter[`${f}:${id}`] = () => { bj09Expected[id] = stateByScreen[id]; }; }));
// Màn 037 / 038 mở từ lô khác: bắt đầu bản nháp mới.
onScreenEnter["UIF-09:SCR-038"] = () => { bj09Expected["SCR-038"] = stateByScreen["SCR-038"]; if (stateByScreen["SCR-038"] === "READY") bj09ResetDraft(); };

onPrevious["UIF-09"] = () => {
  if (bj09ReturnTo && activeScreenId === bj09ReturnTo) { bj09ReturnTo = ""; activeFlowId = "UIF-01"; activeScreenId = "SCR-003"; syncReviewUrl(); return render(); }
  const list = activeFlow()?.screens || [], idx = list.indexOf(activeScreenId);
  if (idx > 0) return navigate(list[idx - 1]);
};
onUnknownHandoff["UIF-09"] = () => { const r = bj09Request(); if (r) r.status = "UNKNOWN"; };

/* ---------- Nguồn dòng cho K5 và "Chờ duyệt" (K2) ---------- */

function bj09ViewRequest(id) {
  const req = bj09Request(id); if (!req) return;
  bj09SelectedRequestId = id; k5SelectedLotId = req.lotId; bj09SetState("SCR-038", "PENDING_APPROVAL");
  return applyEntry("UIF-09", "request-view", true);
}
(window.__T7_PROBLEM_SOURCES__ ||= []).push({
  id: "UIF-09",
  rows: () => t7Lots.filter((l) => l.state !== "SELLABLE").map((l) => {
    const pending = bj09PendingFor(l.id), unknown = bj09UnknownFor(l.id);
    if (unknown) return k5LotRow(l, { job: "WAITING", task: "Đang xác minh", suffix: " · Đang xác minh kết quả", disabled: true, open() {} });
    if (pending) return k5LotRow(l, { job: "WAITING", task: "Chờ duyệt", suffix: ` · Chờ duyệt đổi sang ${t7LotStateLabel(pending.to)}`, pending: { approver: "chủ cửa hàng", sentAt: pending.sentAt, facts: bj09RequestFacts(pending) }, open: () => bj09ViewRequest(pending.id) });
    return k5LotRow(l, { open: () => k5ShowLot(l.id) });
  }),
});
(window.__T7_PENDING_SOURCES__ ||= []).push({
  id: "UIF-09",
  label: "đổi tình trạng",
  needsActivation: true,
  rows: () => bj09Requests.filter((r) => r.status === "PENDING").map((r) => {
    const lot = t7Lot(r.lotId);
    return { title: `${lot.name}${lot.lot ? ` · Lô ${lot.lot}` : ""}`, subtitle: `${t7Qty(r.qty, r.uom)} · ${t7LotStateLabel(r.from)} → ${t7LotStateLabel(r.to)} · ${r.maker} gửi ${r.sentAt}`, icon: "shield", attrs: `data-theme-entry-flow="UIF-09" data-t380-target-screen="SCR-038" data-t380-context="bj09-approval:${bj09Attr(r.id)}" data-theme-entry-actor="approver"` };
  }),
});
(window.__T7_DIRECT_CONTEXTS__ ||= {})["bj09-approval"] = (id) => {
  const req = bj09Request(id); if (!req) return;
  bj09SelectedRequestId = id; k5SelectedLotId = req.lotId; bj09RejectOpen = false; bj09RejectReason = "";
  bj09SetState("SCR-038", "APPROVAL_REVIEW");
};
// core đã áp lối vào trước khi file này nạp: ?uif=UIF-09&entry=approver mở ST-260915-01.
bj09Requests.push(...bj09InitialRequests());
if (activeFlowId === "UIF-09" && entryMode === "approver" && !requestedScreen) { bj09SelectedRequestId = "ST-260915-01"; k5SelectedLotId = "oil-demo"; bj09SetState("SCR-038", "APPROVAL_REVIEW"); }
onEntry["UIF-09:approver"] = () => { bj09SelectedRequestId = "ST-260915-01"; k5SelectedLotId = "oil-demo"; bj09SetState("SCR-038", "APPROVAL_REVIEW"); };

Object.assign(window.__VET45_QA__, {
  getIC09() { return { draft: { ...bj09Draft }, basis: bj09Basis, current: bj09Lot() }; },
  ic09BuildBasis() { bj09Basis = bj09BuildBasis(bj09Lot(), bj09Draft); return bj09Basis; },
  buildBasis() { bj09Basis = bj09BuildBasis(bj09Lot(), bj09Draft); return bj09Basis; },
  ic09GetDraft: () => ({ ...bj09Draft }), ic09GetBasis: () => bj09Basis, ic09GetDecision: () => bj09Decision, ic09GetMovement: () => bj09Movement,
  ic09GetSource: (id) => JSON.parse(JSON.stringify(BJ09_SOURCE[id || bj09Lot().id] || null)),
  ic09SetDraft(v = {}) { bj09Draft = { ...bj09Draft, ...v }; return { ...bj09Draft }; },
  ic09SetStaleOnExecute(v = true) { bj09StaleOnExecute = Boolean(v); return bj09StaleOnExecute; },
  ic09SystemCommit: () => bj09Commit(bj09Basis, BJ09_OWNER),
});

flowRenderers["UIF-09"] = Object.assign(flowRenderers["UIF-09"] || {}, {
  "SCR-038": render038BJ09,
  "SCR-041": render041BJ09,
  "SCR-056": render056BJ09,
});
