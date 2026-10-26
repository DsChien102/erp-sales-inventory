/* BJ-10 — Tiêu hủy hàng (UIF-10). Màn: SCR-036 / SCR-037 (K5, shared-problem.js), SCR-040, SCR-041.
 *
 * Thiết kế lại T7-P chặng 4 (v5.15.0): SCR-040 là một mã màn, bốn chế độ dựng khác hẳn (bj10Mode): đề nghị → chờ duyệt (K2) →
 * duyệt (K2) → đã duyệt, chờ tiêu hủy → xác nhận đã tiêu hủy; không còn ngõ cụt. Duyệt chưa giảm tồn, chỉ xác nhận (kèm ảnh /
 * biên bản) mới ghi giảm lô. Tiền chỉ hiện cho chủ cửa hàng / người duyệt (bj10CanSeeMoney).
 * Dùng từ khuôn: K1, K2, K3, K4, K5 (k5LotCard, k5QtyField, k5Evidence), K7, dsSegmented.
 */

const BJ10_STAFF = "Nguyễn Văn An";
const BJ10_OWNER = "Chủ cửa hàng";
const BJ10_SENT_AT = "17/09/2026 15:20";
const BJ10_APPROVED_AT = "17/09/2026 15:22";
const BJ10_COMPLETED_AT = "17/09/2026 15:40";
const BJ10_METHODS = [["SELF", "Cửa hàng tự tiêu hủy"], ["HIRE", "Thuê đơn vị xử lý"]];

const bj10Requests = [];
let bj10SelectedId = "";
let bj10Draft = { qty: "", reason: "", method: "", evidence: null };
let bj10Completion = { actual: "", evidence: null };
let bj10Result = null;
let bj10RejectOpen = false, bj10RejectReason = "";
let bj10Seq = 1;

const bj10Num = (v) => Number(String(v ?? "").replace(",", ".")) || 0;
const bj10Attr = (v) => escapeAttribute(String(v ?? ""));
function bj10CanDecide() { return ["approver", "owner"].includes(currentActor()); }
function bj10CanSeeMoney() { return ["approver", "owner"].includes(currentActor()); }
function bj10MakerName() { return currentActor() === "owner" ? BJ10_OWNER : BJ10_STAFF; }
function bj10Money(n) { return t7FmtMoney(n); }
function bj10Display(lot) { return lot.lot ? `Lô ${lot.lot}` : "Không theo lô"; }
function bj10MethodLabel(key) { return (BJ10_METHODS.find(([k]) => k === key) || ["", "—"])[1]; }
function bj10Request(id = bj10SelectedId) { return bj10Requests.find((r) => r.id === id) || null; }
function bj10Running(lotId) { return bj10Requests.find((r) => r.lotId === lotId && ["PENDING", "APPROVED", "UNKNOWN"].includes(r.status)) || null; }
function bj10Value(lot, qty) { return lot.unitCost ? bj10Num(qty) * lot.unitCost : 0; }
// Gợi ý lý do theo tình trạng lô: hết hạn → "Hết hạn dùng"; hỏng → lý do đã ghi khi đổi sang Hỏng (BJ-09), nếu có.
function bj10ReasonHint(lot) {
  if (lot.state === "EXPIRED") return "Hết hạn dùng";
  if (lot.state !== "DAMAGED" || typeof bj09Requests === "undefined") return "";
  const r = [...bj09Requests].reverse().find((x) => x.to === "DAMAGED" && x.status === "APPROVED" && (x.lotId === lot.id || `${x.lotId}-damaged` === lot.id));
  return r?.reason || "";
}

/* ---------- Dữ liệu mẫu và trạng thái đặt từ ngoài ---------- */

function bj10InitialRequests() {
  return [{
    id: "TH-260910-01", lotId: "glove-nitrile", qty: 3, uom: "hộp", reason: "Rách bao bì, không dùng được", method: "HIRE",
    evidence: { file: "anh-hien-trang-hang.jpg", data: k5SampleEvidenceData("Bao bì rách") }, maker: BJ10_STAFF, sentAt: "12/09/2026 09:50",
    status: "APPROVED", approver: BJ10_OWNER, approvedAt: "12/09/2026 10:15", decisionReason: "",
  }];
}
function bj10NewRequest(lot, draft, maker, status = "PENDING") {
  const req = { id: `TH-260917-${String(bj10Seq++).padStart(2, "0")}`, lotId: lot.id, qty: bj10Num(draft.qty), uom: lot.uom, reason: String(draft.reason).trim(), method: draft.method, evidence: draft.evidence, maker, sentAt: BJ10_SENT_AT, status, decisionReason: "" };
  bj10Requests.push(req); return req;
}
function bj10SampleDraft(lot) { return { qty: String(lot.qty), reason: bj10ReasonHint(lot) || "Hàng không còn dùng được", method: "SELF", evidence: { file: "anh-hien-trang-hang.jpg", data: k5SampleEvidenceData("Hết hạn dùng") } }; }
function bj10ResetUi() { bj10Draft = { qty: "", reason: "", method: "", evidence: null }; bj10Completion = { actual: "", evidence: null }; bj10RejectOpen = false; bj10RejectReason = ""; }
function bj10Restore() {
  bj10Requests.splice(0, bj10Requests.length, ...bj10InitialRequests());
  bj10ResetUi(); bj10SelectedId = ""; bj10Result = null; bj10Seq = 1;
}
// Bản nháp mới cho lô đang chọn (gợi ý lý do theo tình trạng lô).
function bj10StartDraft() {
  bj10ResetUi(); bj10SelectedId = "";
  bj10Draft.reason = bj10ReasonHint(t7Lot(k5SelectedLotId));
}
function bj10Pending() { return bj10Requests.filter((r) => r.status === "PENDING"); }

const bj10Expected = {};
function bj10SetState(screenId, state) { stateByScreen[screenId] = state; bj10Expected[screenId] = state; }
function bj10Seed(screenId, state) {
  if (bj10Expected[screenId] === state) return;
  Object.keys(bj10Expected).forEach((k) => delete bj10Expected[k]);
  bj10Expected[screenId] = state;
  bj09Restore();
  if (screenId === "SCR-040") {
    if (state === "READY" || state === "VALIDATION_ERROR") { k5SelectedLotId = "tylo-ty2408"; bj10StartDraft(); return; }
    if (state === "PRICE_BASIS_REQUIRED") { k5SelectedLotId = "oil-demo"; bj10StartDraft(); return; }
    if (["PENDING_APPROVAL", "APPROVAL_REVIEW", "SELF_APPROVAL_NOT_ALLOWED"].includes(state)) { bj10SeedPending(); return; }
    bj10SelectedId = "TH-260910-01"; k5SelectedLotId = "glove-nitrile";
    if (state === "COMPLETION_QTY_BLOCKED") bj10Completion.actual = "5";
    return;
  }
  if (screenId === "SCR-041") {
    if (state === "COMPLETED") { bj10SelectedId = "TH-260910-01"; bj10Complete(bj10Request(), 3, bj10SampleCompletion()); bj10Expected[screenId] = state; stateByScreen[screenId] = state; return; }
    if (state === "REJECTED") { bj10SeedPending(); const r = bj10Request(); r.status = "REJECTED"; r.decisionReason = "Thiếu ảnh hiện trạng"; return; }
    if (state === "REJECTED_EXECUTION") { bj10SeedPending(); return; }
    bj10SelectedId = "TH-260910-01"; k5SelectedLotId = "glove-nitrile";
  }
}
function bj10SeedPending() {
  const lot = t7Lot("tylo-ty2408"); k5SelectedLotId = lot.id;
  const req = bj10NewRequest(lot, bj10SampleDraft(lot), BJ10_STAFF); bj10SelectedId = req.id; return req;
}
function bj10SampleCompletion() { return { actual: "3", evidence: { file: "bien-ban-tieu-huy.jpg", data: k5SampleEvidenceData("Biên bản tiêu hủy") } }; }

/* ---------- Ghi giảm (hệ thống) ---------- */

function bj10Complete(req, actual, proof) {
  const lot = t7Lots.find((z) => z.id === req.lotId);
  if (!lot || actual <= 0 || actual > req.qty) return false;
  const value = bj10Value(lot, actual);
  lot.qty = Number((lot.qty - actual).toFixed(6));
  const slices = (typeof BJ09_SOURCE !== "undefined" ? BJ09_SOURCE[lot.id]?.slices : null) || [];
  let rem = actual; for (const sl of slices) { if (rem <= 0) break; const take = Math.min(rem, sl.qty); sl.qty -= take; rem -= take; }
  req.status = "COMPLETED"; req.actual = actual; req.proof = proof?.evidence || null; req.completedBy = currentActor() === "owner" || currentActor() === "approver" ? BJ10_OWNER : BJ10_STAFF; req.completedAt = BJ10_COMPLETED_AT;
  bj10Result = { requestId: req.id, name: lot.name, lot: lot.lot, uom: lot.uom, actual, remaining: lot.qty, value, by: req.completedBy, at: req.completedAt, hasCost: Boolean(lot.unitCost) };
  // Tiêu hủy xong là lúc tồn vật lý giảm: ghi vào sổ chung (phần hàng này vốn không nằm trong khả dụng nếu không phải "Bán được").
  if (t7Ledger.STATE_LABEL[lot.state]) t7Ledger.post({ key: `UIF-10:${req.id}`, productId: lot.code, lot: lot.lot, kind: "Tiêu hủy", doc: req.id, delta: -actual, state: t7Ledger.STATE_LABEL[lot.state], sourceFlow: "UIF-10", opId: req.id });
  if (lot.qty <= 0) t7Lots.splice(t7Lots.indexOf(lot), 1);
  return true;
}

/* ---------- Chế độ của SCR-040 ---------- */

function bj10Mode(state) {
  if (state === "APPROVAL_REVIEW" || state === "SELF_APPROVAL_NOT_ALLOWED") return "REVIEW";
  if (state === "PENDING_APPROVAL") return "PENDING";
  if (state === "APPROVED_PENDING_DISPOSAL") return "APPROVED";
  if (state === "COMPLETION" || state === "COMPLETION_QTY_BLOCKED") return "COMPLETION";
  return "PREPARE";
}

function bj10Shell(opts) { return appShell({ extraClass: "k7-wide", ...opts }); }
function bj10Denied(title, back = false) { return bj10Shell({ title, body: k1Denied({ what: "tiêu hủy hàng", next: "Liên hệ chủ cửa hàng để được cấp quyền.", exitAttr: k1ExitAttr("SCR-036") }), centered: true, back }); }
function bj10Summary(lot) { return ac310KeyValueSurface("Tóm tắt", [["Sản phẩm", lot.name], ["Mã", lot.code], ["Lô", lot.lot || "Không theo lô"], ["Tình trạng", t7LotStateLabel(lot.state)], ["Tồn vật lý", t7Qty(lot.qty, lot.uom)]]); }
function bj10EvidenceSection(title, ev) { return `<section class="bj06-section">${ds24SectionTitle(title)}${bj09EvidenceCard(ev)}</section>`; }
function bj10Facts(req) { const lot = t7Lot(req.lotId); return [["Sản phẩm", lot.name], ["Lô", lot.lot || "Không theo lô"], ["Số lượng", t7Qty(req.qty, req.uom)], ["Lý do", req.reason], ["Cách xử lý", bj10MethodLabel(req.method)]]; }
function bj10Lead(text) { return `<p class="bj10-lead">${esc(text)}</p>`; }

/* ---------- 040 · Đề nghị ---------- */

function bj10Blocker(lot, d = bj10Draft) {
  const q = bj10Num(d.qty);
  if (q <= 0) return "Nhập số lượng";
  if (q > lot.qty) return `Tối đa ${t7Qty(lot.qty, lot.uom)}`;
  if (!String(d.reason || "").trim()) return "Nhập lý do";
  if (!d.method) return "Chọn cách xử lý";
  if (!d.evidence?.data) return "Thêm ảnh hiện trạng";
  return "";
}
function bj10Errors(lot, d, show) {
  const q = bj10Num(d.qty);
  return {
    qty: q > lot.qty ? `Tối đa ${t7Qty(lot.qty, lot.uom)}` : show && q <= 0 ? "Nhập số lượng" : "",
    reason: show && !String(d.reason || "").trim() ? "Nhập lý do" : "",
    method: show && !d.method ? "Chọn cách xử lý" : "",
    evidence: show && !d.evidence?.data ? "Thêm ảnh hiện trạng" : "",
  };
}
function bj10ValueRow(lot) {
  if (!bj10CanSeeMoney()) return "";
  const q = bj10Num(bj10Draft.qty);
  return q > 0 && q <= lot.qty && lot.unitCost ? ds24KeyValueRow("Giá trị ghi giảm dự kiến", bj10Money(bj10Value(lot, q)), true) : "";
}
function bj10PrepareForm(lot, errors, priceMissing) {
  const qty = k5QtyField({ value: bj10Draft.qty, max: lot.qty, uom: lot.uom, attr: "data-bj10-qty", fillAttr: "data-bj10-qty-fill", error: errors.qty, label: "Số lượng đề nghị" });
  const reason = `${icTextarea("Lý do", bj10Draft.reason, "data-bj10-reason", "Nhập lý do")}${errors.reason ? `<small class="field-error" role="alert">${esc(errors.reason)}</small>` : ""}`;
  const method = `<section class="bj06-section">${ds24SectionTitle("Cách xử lý")}${dsSegmented({ items: BJ10_METHODS, value: bj10Draft.method, attr: "data-bj10-method", label: "Cách xử lý" })}${errors.method ? `<small class="field-error" role="alert">${esc(errors.method)}</small>` : ""}</section>`;
  const evidence = k5Evidence({ owner: "bj10", evidence: bj10Draft.evidence, label: "Ảnh hiện trạng", error: errors.evidence });
  const banner = priceMissing ? vBanner("error", "Chưa có căn cứ giá hợp lệ", "Không thể gửi yêu cầu cho đến khi có căn cứ giá chính thức.") : "";
  return `<div class="bj10-form">${banner}${k5LotCard({ lot, compact: true })}${qty}${reason}${method}${evidence}<div data-bj10-value>${bj10ValueRow(lot)}</div></div>`;
}
function bj10RenderPrepare(state) {
  const title = "Yêu cầu tiêu hủy", lot = t7Lot(k5SelectedLotId), sub = `${lot.name} · ${bj10Display(lot)}`;
  const priceMissing = !lot.unitCost || state === "PRICE_BASIS_REQUIRED";
  const errors = bj10Errors(lot, bj10Draft, state === "VALIDATION_ERROR");
  const blocker = priceMissing ? "Lô này chưa có giá vốn" : bj10Blocker(lot);
  const body = k7Split({ main: bj10PrepareForm(lot, errors, priceMissing), aside: bj10Summary(lot), asideWebOnly: true });
  return bj10Shell({ title, subtitle: sub, body, actions: k4ReasonFooter({ label: "Gửi phê duyệt", attr: 'data-bj10-action="submit"', disabled: Boolean(blocker), reason: blocker }) });
}

/* ---------- 040 · Chờ duyệt / Duyệt / Đã duyệt / Xác nhận ---------- */

function bj10ExitFooter() { return k4Footer([{ label: "Về hàng cần xử lý", attr: 'data-k5-action="to-list"', primary: true }]); }
function bj10RenderPending() {
  const title = "Yêu cầu tiêu hủy", req = bj10Request();
  if (!req) return bj10Shell({ title, body: k1Locked({ title: "Không có đề nghị", description: "Mở lại từ danh sách hàng cần xử lý." }), back: false, actions: bj10ExitFooter() });
  const lot = t7Lot(req.lotId);
  const main = `${k2Pending({ approver: "chủ cửa hàng", sentAt: req.sentAt, facts: bj10Facts(req) })}`;
  return bj10Shell({ title, subtitle: `${lot.name} · ${bj10Display(lot)}`, body: k7Split({ main, aside: bj10EvidenceSection("Ảnh hiện trạng", req.evidence) }), back: false, actions: bj10ExitFooter() });
}
function bj10RenderReview(state) {
  const title = "Duyệt tiêu hủy";
  if (state === "SELF_APPROVAL_NOT_ALLOWED") return bj10Shell({ title, body: vBanner("warning", "Không thể tự duyệt", "Chỉ chủ cửa hàng duyệt tiêu hủy."), back: false, actions: bj10ExitFooter() });
  const req = bj10Request();
  if (!req || req.status !== "PENDING") return bj10Shell({ title, body: k1Locked({ title: "Không có đề nghị chờ duyệt", description: "Khi có đề nghị tiêu hủy gửi lên, bạn sẽ thấy tại mục Chờ duyệt." }), back: false, actions: bj10ExitFooter() });
  const lot = t7Lot(req.lotId);
  const question = `Duyệt tiêu hủy ${t7Qty(req.qty, req.uom)} ${lot.name}${lot.lot ? ` lô ${lot.lot}` : ""}?`;
  const attention = [...(lot.unitCost && bj10CanSeeMoney() ? [["Giá trị ghi giảm dự kiến", bj10Money(bj10Value(lot, req.qty))]] : []), ["Sau khi duyệt", "Tồn chưa giảm — giảm khi xác nhận đã tiêu hủy", "info"]];
  const decision = k2Decision({ question, maker: req.maker, sentAt: req.sentAt, attention, facts: [["Lý do", req.reason], ["Cách xử lý", bj10MethodLabel(req.method)]] });
  const sheet = k2RejectSheet({ open: bj10RejectOpen, title: "Từ chối đề nghị tiêu hủy?", reason: bj10RejectReason, reasonAttr: "data-bj10-reject-reason", confirmAttr: 'data-bj10-action="reject-confirm"', closeAttr: 'data-bj10-action="reject-close"' });
  return bj10Shell({ title, subtitle: `${lot.name} · ${bj10Display(lot)}`, body: `${k7Split({ main: decision, aside: bj10EvidenceSection("Ảnh hiện trạng", req.evidence) })}${sheet}`, back: false, actions: ac310ApprovalFooter('data-bj10-action="reject-open"', 'data-bj10-action="approve"', "Duyệt") });
}
function bj10RenderApproved() {
  const title = "Yêu cầu tiêu hủy", req = bj10Request();
  if (!req) return bj10Shell({ title, body: k1Locked({ title: "Không có đề nghị", description: "Mở lại từ danh sách hàng cần xử lý." }), back: false, actions: bj10ExitFooter() });
  const lot = t7Lot(req.lotId);
  const banner = vBanner("success", "Đã duyệt — chờ xử lý thực tế", "Tồn chưa giảm. Tiêu hủy xong thì chụp ảnh hoặc biên bản và xác nhận.");
  const facts = ac310InfoSurface("", [["Đã duyệt", t7Qty(req.qty, req.uom), true], ["Người duyệt", `${req.approver} · ${req.approvedAt}`], ["Cách xử lý", bj10MethodLabel(req.method)]]);
  const main = `${banner}${k5LotCard({ lot, compact: true })}${facts}`;
  const footer = k4Footer([{ label: "Về hàng cần xử lý", attr: 'data-k5-action="to-list"' }, { label: "Xác nhận đã tiêu hủy", attr: 'data-bj10-action="to-completion"', primary: true }]);
  return bj10Shell({ title, subtitle: `${lot.name} · ${bj10Display(lot)}`, body: k7Split({ main, aside: bj10EvidenceSection("Ảnh hiện trạng", req.evidence) }), back: false, actions: footer });
}
function bj10CompletionBlocker(req) {
  const q = bj10Num(bj10Completion.actual);
  if (q <= 0) return "Nhập số lượng đã tiêu hủy";
  if (q > req.qty) return `Tối đa ${t7Qty(req.qty, req.uom)} đã duyệt`;
  if (!bj10Completion.evidence?.data) return "Thêm ảnh hoặc biên bản";
  return "";
}
function bj10CompletionError(req) {
  return bj10Num(bj10Completion.actual) > req.qty ? `Tối đa ${t7Qty(req.qty, req.uom)} đã duyệt. Phần vượt cần đề nghị mới.` : "";
}
function bj10RenderCompletion() {
  const title = "Xác nhận đã tiêu hủy", req = bj10Request();
  if (!req) return bj10Shell({ title, body: k1Locked({ title: "Không có đề nghị", description: "Mở lại từ danh sách hàng cần xử lý." }), back: false, actions: bj10ExitFooter() });
  const lot = t7Lot(req.lotId);
  const qty = k5QtyField({ value: bj10Completion.actual, max: req.qty, uom: req.uom, attr: "data-bj10-actual", fillAttr: "data-bj10-actual-fill", error: bj10CompletionError(req), label: "Đã tiêu hủy thực tế" });
  const evidence = k5Evidence({ owner: "bj10c", evidence: bj10Completion.evidence, label: "Ảnh hoặc biên bản tiêu hủy", emptyTitle: "Ảnh hoặc biên bản sau khi tiêu hủy", hint: "Lưu cùng ghi nhận tiêu hủy" });
  const main = `<div class="bj10-form">${bj10Lead("Chỉ xác nhận sau khi đã xử lý thực tế")}${k5LotCard({ lot, compact: true })}${qty}${evidence}</div>`;
  const blocker = bj10CompletionBlocker(req);
  return bj10Shell({ title, subtitle: `${lot.name} · ${bj10Display(lot)}`, body: k7Split({ main, aside: bj10Summary(lot), asideWebOnly: true }), back: false, actions: k4ReasonFooter({ label: "Xác nhận đã tiêu hủy", attr: 'data-bj10-action="complete"', disabled: Boolean(blocker), reason: blocker, tone: "danger" }) });
}

function render040BJ10(state) {
  bj10Seed("SCR-040", state);
  if (state === "PERMISSION_DENIED") return bj10Denied("Yêu cầu tiêu hủy");
  const mode = bj10Mode(state);
  if (mode === "PENDING") return bj10RenderPending();
  if (mode === "REVIEW") return bj10RenderReview(state);
  if (mode === "APPROVED") return bj10RenderApproved();
  if (mode === "COMPLETION") return bj10RenderCompletion();
  return bj10RenderPrepare(state);
}

/* ---------- 041 · Kết quả tiêu hủy (K4 / K3) ---------- */

function render041BJ10(state) {
  const title = "Kết quả tiêu hủy";
  bj10Seed("SCR-041", state);
  if (state === "PERMISSION_DENIED") return bj10Denied(title);
  if (state === "PROCESSING") return bj10Shell({ title, body: k1Loading({ blocks: ["heading", "card", "row"] }), centered: true, back: false });
  const req = bj10Request() || bj10Requests.find((r) => r.id === bj10Result?.requestId), toList = { label: "Về hàng cần xử lý", attr: 'data-k5-action="to-list"', primary: true };
  const lot = req ? t7Lots.find((z) => z.id === req.lotId) || { name: bj10Result?.name || "", lot: bj10Result?.lot || "" } : { name: "", lot: "" };
  const scope = `${lot.name} · ${lot.lot ? `Lô ${lot.lot}` : "Không theo lô"}`;
  if (state === "UNKNOWN" || state === "COMMIT_UNKNOWN") {
    return k3Unknown({ operation: "Tiêu hủy hàng", scope, ref: req?.id || "TH-260917-01", sentAt: BJ10_COMPLETED_AT, sourceFlow: "UIF-10", exitAttr: k1ExitAttr("SCR-036"), handoff: { operation: req?.id || "TH-260917-01", scope } });
  }
  if (state === "REJECTED") {
    return k4Result({ screenTitle: title, kind: "warning", title: "Đã từ chối đề nghị tiêu hủy", description: `Lý do: ${req?.decisionReason || "—"}. Tồn kho không thay đổi.`, facts: [["Đề nghị", req?.id || "—"], ["Sản phẩm", lot.name]], next: [toList] });
  }
  if (state === "REJECTED_EXECUTION") {
    return k4Result({ screenTitle: title, kind: "warning", title: "Chưa ghi giảm", description: "Không có tác động tồn kho mới. Xem lại yêu cầu hiện hành trước khi tiếp tục.", facts: [["Đề nghị", req?.id || "—"], ["Tồn vật lý", "Không thay đổi"]], next: [toList] });
  }
  const r = bj10Result;
  if (!r) return bj10Shell({ title, body: k1Loading({ blocks: ["heading", "card", "row"] }), centered: true, back: false });
  const facts = [["Sản phẩm", r.name], ["Lô", r.lot || "Không theo lô"], ["Đã tiêu hủy", t7Qty(r.actual, r.uom)], ["Còn lại ở lô", t7Qty(r.remaining, r.uom)], ["Người xác nhận", r.by], ["Xác nhận lúc", r.at], ...(bj10CanSeeMoney() && r.hasCost ? [["Giá trị ghi giảm", bj10Money(r.value)]] : [])];
  return k4Result({ screenTitle: title, title: "Đã ghi nhận tiêu hủy", description: "Tồn vật lý và giá trị đã giảm theo đúng số lượng thực tế được xác nhận.", facts, next: [toList] });
}

/* ---------- Sự kiện (một khối, chỉ khi đang ở UIF-10) ---------- */

function bj10Rerender(focusSelector = "") {
  const top = document.querySelector("#app-screen .app-content")?.scrollTop || 0;
  renderAppScreen();
  const content = document.querySelector("#app-screen .app-content"); if (content) content.scrollTop = top;
  if (focusSelector) [...document.querySelectorAll(focusSelector)].find((el) => el.offsetParent !== null)?.focus({ preventScroll: true });
}
function bj10SetError(box, message) {
  if (!box) return;
  box.classList.toggle("k7-edit--error", Boolean(message));
  box.querySelector("input")?.toggleAttribute("aria-invalid", Boolean(message));
  let msg = box.querySelector(".field-error");
  if (message && !msg) { msg = document.createElement("small"); msg.className = "field-error"; msg.setAttribute("role", "alert"); box.appendChild(msg); }
  if (msg) { msg.textContent = message; msg.hidden = !message; }
}
// Gõ vào ô không dựng lại màn (giữ focus): chỉ cập nhật chân, lỗi dưới ô số lượng và dòng giá trị.
function bj10Sync() {
  const mode = bj10Mode(stateByScreen["SCR-040"]);
  let blocker = "", error = "";
  if (mode === "PREPARE") {
    const lot = t7Lot(k5SelectedLotId); blocker = !lot.unitCost ? "Lô này chưa có giá vốn" : bj10Blocker(lot);
    error = bj10Num(bj10Draft.qty) > lot.qty ? `Tối đa ${t7Qty(lot.qty, lot.uom)}` : "";
    document.querySelectorAll("[data-bj10-value]").forEach((el) => { el.innerHTML = bj10ValueRow(lot); });
  } else if (mode === "COMPLETION") {
    const req = bj10Request(); if (!req) return;
    blocker = bj10CompletionBlocker(req); error = bj10CompletionError(req);
  } else return;
  document.querySelectorAll('[data-bj10-action="submit"], [data-bj10-action="complete"]').forEach((b) => { b.disabled = Boolean(blocker); });
  document.querySelectorAll(".app-actions [data-k4-reason]").forEach((p) => { p.textContent = blocker; p.hidden = !blocker; });
  document.querySelectorAll(".k5-qty .k7-edit").forEach((el) => bj10SetError(el, error));
}

k5RegisterEvidence("bj10", { set(ev) { bj10Draft.evidence = ev; }, rerender() { bj10Rerender(); } });
k5RegisterEvidence("bj10c", { set(ev) { bj10Completion.evidence = ev; }, rerender() { bj10Rerender(); } });

document.addEventListener("input", (event) => {
  if (activeFlowId !== "UIF-10") return;
  const t = event.target;
  if (t.matches("[data-bj10-qty]")) { bj10Draft.qty = t.value; return bj10Sync(); }
  if (t.matches("[data-bj10-reason]")) { bj10Draft.reason = t.value; return bj10Sync(); }
  if (t.matches("[data-bj10-actual]")) { bj10Completion.actual = t.value; return bj10Sync(); }
  if (t.matches("[data-bj10-reject-reason]")) { bj10RejectReason = t.value; const b = document.querySelector('[data-bj10-action="reject-confirm"]'); if (b) b.disabled = !bj10RejectReason.trim(); }
}, true);

onDialogClose["UIF-10"] = () => {
  if (!(bj10RejectOpen)) return false;
  bj10RejectOpen = false;
  renderAppScreen(); return true;
};

function bj10Submit() {
  const lot = t7Lot(k5SelectedLotId);
  if (!lot.unitCost) { bj10SetState("SCR-040", "PRICE_BASIS_REQUIRED"); return renderAppScreen(); }
  if (bj10Blocker(lot)) { bj10SetState("SCR-040", "VALIDATION_ERROR"); return renderAppScreen(); }
  const req = bj10NewRequest(lot, bj10Draft, bj10MakerName());
  bj10SelectedId = req.id; bj10SetState("SCR-040", "PENDING_APPROVAL");
  renderAppScreen(); return showToast("Đã gửi yêu cầu tiêu hủy", "success");
}
function bj10Decide(approve) {
  const req = bj10Request();
  if (!bj10CanDecide()) { bj10RejectOpen = false; bj10SetState("SCR-040", "SELF_APPROVAL_NOT_ALLOWED"); return renderAppScreen(); }
  if (!req || req.status !== "PENDING") return renderAppScreen();
  k5SelectedLotId = req.lotId;
  if (approve) { req.status = "APPROVED"; req.approver = BJ10_OWNER; req.approvedAt = BJ10_APPROVED_AT; bj10SetState("SCR-040", "APPROVED_PENDING_DISPOSAL"); return renderAppScreen(); }
  if (!bj10RejectReason.trim()) return;
  req.status = "REJECTED"; req.decisionReason = bj10RejectReason.trim(); bj10RejectOpen = false;
  bj10SetState("SCR-041", "REJECTED"); return navigate("SCR-041");
}
function bj10Finish() {
  const req = bj10Request();
  if (!req || bj10CompletionBlocker(req)) { bj10SetState("SCR-040", "COMPLETION_QTY_BLOCKED"); return renderAppScreen(); }
  if (!bj10Complete(req, bj10Num(bj10Completion.actual), { evidence: bj10Completion.evidence })) { bj10SetState("SCR-041", "REJECTED_EXECUTION"); return navigate("SCR-041"); }
  bj10SetState("SCR-041", "COMPLETED"); return navigate("SCR-041");
}

document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-10") return;
  const t = event.target, hit = (sel) => t.closest?.(sel);
  let el;
  if ((el = hit("[data-bj10-method]"))) { event.preventDefault(); bj10Draft.method = el.dataset.bj10Method; return bj10Rerender(`[data-bj10-method="${el.dataset.bj10Method}"]`); }
  if (hit("[data-bj10-qty-fill]")) { event.preventDefault(); bj10Draft.qty = String(t7Lot(k5SelectedLotId).qty); return bj10Rerender("[data-bj10-qty]"); }
  if (hit("[data-bj10-actual-fill]")) { event.preventDefault(); const req = bj10Request(); if (req) bj10Completion.actual = String(req.qty); return bj10Rerender("[data-bj10-actual]"); }
  const a = hit("[data-bj10-action]"); if (!a) return;
  if (a.matches(".sheet-backdrop") && t !== a) return;
  event.preventDefault(); event.stopPropagation(); if (a.disabled) return;
  const k = a.dataset.bj10Action;
  if (k === "submit") return bj10Submit();
  if (k === "approve") return bj10Decide(true);
  if (k === "reject-open") { if (!bj10CanDecide()) return bj10Decide(false); bj10RejectOpen = true; bj10RejectReason = ""; return renderAppScreen(); }
  if (k === "reject-close") { bj10RejectOpen = false; return renderAppScreen(); }
  if (k === "reject-confirm") return bj10Decide(false);
  if (k === "to-completion") { bj10Completion = { actual: "", evidence: null }; bj10SetState("SCR-040", "COMPLETION"); return renderAppScreen(); }
  if (k === "complete") return bj10Finish();
}, true);

// Đi giữa các màn bằng navigate (kể cả nút quay lại) là đi trong luồng: trạng thái hiện tại là "đã biết", không dựng lại fixture.
["SCR-036", "SCR-037", "SCR-040", "SCR-041"].forEach((id) => { onScreenEnter[`UIF-10:${id}`] = () => { bj10Expected[id] = stateByScreen[id]; }; });

/* ---------- Lối vào ---------- */

function bj10View(id, state) {
  const req = bj10Request(id); if (!req) return;
  bj10SelectedId = id; k5SelectedLotId = req.lotId; bj10RejectOpen = false; bj10RejectReason = "";
  bj10SetState("SCR-040", state);
}
onEntry["UIF-10:request"] = () => { bj10SetState("SCR-040", "READY"); };
onEntry["UIF-10:approver"] = () => { const r = bj10Pending().at(-1); bj10SelectedId = r?.id || ""; if (r) k5SelectedLotId = r.lotId; bj10RejectOpen = false; bj10RejectReason = ""; bj10SetState("SCR-040", "APPROVAL_REVIEW"); };
onEntry["UIF-10:completion-operator"] = () => { bj10Completion = { actual: "", evidence: null }; bj10View("TH-260910-01", "APPROVED_PENDING_DISPOSAL"); };
// core đã áp lối vào trước khi file này nạp: nạp fixture rồi áp lại cho các lối vào trực tiếp.
bj10Restore();
if (activeFlowId === "UIF-10" && !requestedScreen && onEntry[`UIF-10:${entryMode}`]) onEntry[`UIF-10:${entryMode}`]();

onUnknownHandoff["UIF-10"] = () => { const r = bj10Request(); if (r) r.status = "UNKNOWN"; };
onUnknownResolved["UIF-10"] = ({ outcome }) => { const r = bj10Requests.find((x) => x.status === "UNKNOWN"); if (r) r.status = outcome === "RECORDED" ? "COMPLETED" : "APPROVED"; };

Object.assign(window.__VET45_QA__, {
  // Đề nghị chờ duyệt mẫu (Tylosin TY2408, 11 lọ) cho kịch bản duyệt / từ chối từ lối vào ?entry=approver.
  seedBJ10Pending() { const r = bj10SeedPending(); bj10View(r.id, "APPROVAL_REVIEW"); renderAppScreen(); return r.id; },
  getBJ10() { return { draft: { ...bj10Draft }, completion: { ...bj10Completion }, requests: bj10Requests.map((r) => ({ id: r.id, status: r.status })), result: bj10Result }; },
});

flowRenderers["UIF-10"] = Object.assign(flowRenderers["UIF-10"] || {}, {
  "SCR-040": render040BJ10,
  "SCR-041": render041BJ10,
});

/* ---------- Nguồn dòng cho K5 và "Chờ duyệt" (K2) ---------- */

(window.__T7_PROBLEM_SOURCES__ ||= []).push({
  id: "UIF-10",
  rows: () => bj10Requests.filter((r) => ["PENDING", "APPROVED", "UNKNOWN"].includes(r.status) && t7Lots.some((l) => l.id === r.lotId)).map((r) => {
    const lot = t7Lot(r.lotId);
    if (r.status === "UNKNOWN") return k5LotRow(lot, { job: "WAITING", task: "Đang xác minh", suffix: " · Đang xác minh kết quả", disabled: true, open() {} });
    if (r.status === "PENDING") return k5LotRow(lot, { job: "WAITING", task: "Chờ duyệt", suffix: " · Chờ duyệt tiêu hủy", pending: { approver: "chủ cửa hàng", sentAt: r.sentAt, facts: bj10Facts(r) }, open: () => { bj10View(r.id, "PENDING_APPROVAL"); return applyEntry("UIF-10", "request-view", true); } });
    return k5LotRow(lot, {
      job: "DISPOSAL", task: "Chờ tiêu hủy", suffix: " · Chờ tiêu hủy",
      banner: { title: "Đã duyệt · chờ tiêu hủy", description: "Tồn kho chưa giảm cho tới khi xác nhận đã tiêu hủy thực tế." },
      open: () => { bj10Completion = { actual: "", evidence: null }; bj10View(r.id, "APPROVED_PENDING_DISPOSAL"); return applyEntry("UIF-10", "request-view", true); },
    });
  }),
});
(window.__T7_PENDING_SOURCES__ ||= []).push({
  id: "UIF-10",
  label: "tiêu hủy",
  needsActivation: true,
  rows: () => bj10Pending().map((r) => {
    const lot = t7Lot(r.lotId);
    return { title: `${lot.name}${lot.lot ? ` · Lô ${lot.lot}` : ""}`, subtitle: `${t7Qty(r.qty, r.uom)} · ${r.maker} gửi ${r.sentAt}`, icon: "shield", attrs: `data-theme-entry-flow="UIF-10" data-t380-target-screen="SCR-040" data-t380-context="bj10-approval:${bj10Attr(r.id)}" data-theme-entry-actor="approver"` };
  }),
});
(window.__T7_DIRECT_CONTEXTS__ ||= {})["bj10-approval"] = (id) => { bj10View(id, "APPROVAL_REVIEW"); };
