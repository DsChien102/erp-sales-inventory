/* BJ-07 — Trả hàng cho nhà cung cấp (UIF-07). Màn: SCR-036 (K5, shared-problem.js), SCR-037, SCR-039, SCR-041.
 *
 * Thiết kế lại T7-P chặng 4 (v5.14.0): kiểm hàng một chạm ("Đúng hàng" ngay trên dòng), sheet chỉ khi cần nhập lô thực tế /
 * chia phần hàng / báo không khớp; 039 nói giao cho ai; 041 là K4 / K3. Danh sách yêu cầu trả là dòng của K5 (SCR-036 chung).
 * Dùng từ khuôn: K1, K3, K4 (k4Result, k4ReasonFooter), K7 (k7Split, k7Table), dsSegmented, ds24Sheet.
 * Handoff UNKNOWN: onUnknownHandoff["UIF-07"]; nút `data-k3-action="handoff"` do k3Unknown dựng → bj17.js.
 * Trạng thái đặt từ ngoài (bộ chọn golden) dựng lại yêu cầu từ bản gốc: xem io07Seed.
 */

const IO07_ACTOR = { id: "USR-WH-021", name: "Trần Huy · Thủ kho" };
const IO07_CONFIRMED_AT = "17/09/2026 16:05";
const IO07_STOCK_LABELS = { SELLABLE: "Bán được", QUARANTINE: "Cách ly", DAMAGED: "Hỏng", EXPIRED: "Hết hạn" };
const IO07_RECIPIENTS = [["SUPPLIER", "Nhà cung cấp nhận"], ["CARRIER", "Đơn vị vận chuyển"]];
const IO07_DENIED = { what: "trả hàng nhà cung cấp", next: "Liên hệ chủ cửa hàng để được cấp quyền." };

function io07InitialRequests() {
  const line = (id, lot, expiry, qty, extra = {}) => ({ id, lot, expiry, qty, verified: false, physicalMismatch: false, affectedByChange: false, ...extra });
  return [
    { id: "RTV-260827-02", supplier: "Minh Dũng", source: "YCTN-260827-02", sourceVersion: 3, warehouse: "Kho chính", lifecycle: "Chờ bàn giao", queue: "ACTIONABLE", changed: false, sourceChanges: [], groups: [
      { id: "RTV-G1", name: "Nobivac DHPPi", code: "SP-000184", uom: "hộp", tracking: "LOT", allocations: [line("RTV-A1", "DH2507", "30/11/2026", 4), line("RTV-A2", "DH2511", "31/03/2027", 2)] },
      { id: "RTV-G2", name: "Tylosin 20%", code: "SP-000122", uom: "lọ", tracking: "LOT", allocations: [line("RTV-A3", "TY2511", "30/11/2027", 3)] },
      { id: "RTV-G3", name: "Găng tay khám Nitrile", code: "SP-000271", uom: "hộp", tracking: "NONE", allocations: [line("RTV-A4", null, null, 5)] },
    ] },
    { id: "RTV-260827-04", supplier: "An Việt", source: "YCTN-260827-04", sourceVersion: 5, warehouse: "Kho chính", lifecycle: "Chờ bàn giao", queue: "ACTIONABLE", changed: true, sourceChanges: ["Găng tay khám Nitrile · hộp: 8 → 5; 3 hộp được bỏ khỏi lượng chờ trả."], groups: [
      { id: "RTV-G4", name: "Găng tay khám Nitrile", code: "SP-000271", uom: "hộp", tracking: "NONE", allocations: [line("RTV-A5", null, null, 5, { previousQty: 8, affectedByChange: true })] },
      { id: "RTV-G5", name: "Băng cuộn y tế", code: "SP-00307", uom: "cuộn", tracking: "NONE", allocations: [line("RTV-A6", null, null, 2, { verified: true, verifyMethod: "VISUAL" })] },
    ] },
    { id: "RTV-260903-03", supplier: "Thú Y Hoàng Gia", source: "YCTN-260903-03", sourceVersion: 2, warehouse: "Kho chính", lifecycle: "Chờ bàn giao", queue: "ACTIONABLE", changed: false, sourceChanges: [], groups: [
      { id: "RTV-G6", name: "Oxytetracycline LA", code: "SP-000147", uom: "chai", tracking: "NONE", allocations: [line("RTV-A7", null, null, 4)] },
    ] },
    { id: "RTV-260903-05", supplier: "Phú Nông", source: "YCTN-260903-05", sourceVersion: 1, warehouse: "Kho chính", lifecycle: "Chờ bàn giao", queue: "WAITING", waitingReason: "Bộ phận Mua hàng đang cập nhật yêu cầu trả. Kho chỉ xem, chưa tiếp tục chuẩn bị.", changed: false, sourceChanges: [], groups: [
      { id: "RTV-G7", name: "Vitamin ADE", code: "SP-00511", uom: "chai", tracking: "LOT", allocations: [line("RTV-A8", "VA2508", "31/08/2027", 3)] },
    ] },
    { id: "RTV-260903-06", supplier: "Nam Việt", source: "YCTN-260903-06", sourceVersion: 4, warehouse: "Kho chính", lifecycle: "Đã hủy từ nguồn", queue: "CLOSED", sourceCancelled: true, closed: true, changed: true, sourceChanges: ["Bộ phận Mua hàng đã hủy yêu cầu trước bàn giao; lượng chờ trả được hệ thống giải phóng."], groups: [] },
  ];
}

const io07Requests = [];
let io07Selected = "RTV-260827-02", io07ActiveAllocationId = "", io07VerifySheetOpen = false, io07ScanLot = "", io07LastResult = null;
let io07Recipient = "SUPPLIER", io07ResultSheetOpen = false;
let io07MismatchOpen = false, io07MismatchType = "", io07MismatchQty = "", io07MismatchLot = "", io07MismatchNote = "";

const io07Num = (v) => (Number.isFinite(Number(v)) ? Number(v) : 0);
const io07Attr = (v) => escapeAttribute(String(v ?? ""));
function io07StableHash(input) {
  let h1 = 2166136261 >>> 0, h2 = 2246822519 >>> 0;
  const s = typeof input === "string" ? input : JSON.stringify(input);
  for (let i = 0; i < s.length; i++) { const c = s.charCodeAt(i); h1 = Math.imul(h1 ^ c, 16777619) >>> 0; h2 = Math.imul(h2 ^ c, 3266489917) >>> 0; }
  const base = h1.toString(16).padStart(8, "0") + h2.toString(16).padStart(8, "0");
  return (base + base + base + base).slice(0, 64);
}

/* ---------- Dữ liệu: yêu cầu, dòng, phần hàng ---------- */

function io07Current() { return io07Requests.find((r) => r.id === io07Selected) || io07Requests.find((r) => !r.closed && !r.completed) || io07Requests[0]; }
function io07ActiveRequests() { return io07Requests.filter((r) => !r.closed && !r.completed && !r.sourceCancelled && !r.unknownLocked); }
function io07Allocations(req = io07Current()) { return (req.groups || []).flatMap((group) => (group.allocations || []).map((allocation) => ({ group, allocation }))); }
function io07FindAllocation(id, req = io07Current()) { return io07Allocations(req).find((x) => x.allocation.id === id) || null; }
function io07ActiveFound() { return io07FindAllocation(io07ActiveAllocationId, io07Current()); }
function io07HasMismatch(req = io07Current()) { return io07Allocations(req).some(({ allocation }) => allocation.physicalMismatch); }
function io07VerifiedCount(req = io07Current()) { return io07Allocations(req).filter(({ allocation }) => allocation.verified && !allocation.physicalMismatch).length; }
function io07Waiting(req) { return req.queue === "WAITING" || Boolean(req.awaitingSourceAmendment); }
function io07LabelOf(group, a) { return group.tracking === "LOT" ? `Lô ${a.lot}` : "Không theo lô"; }

function io07SourceId(a, state) { return `BAL-${String(a.sourceAllocationId || a.id).replace(/[^A-Z0-9]/gi, "")}-${state}`; }
function io07DefaultState(a) { return a.id === "RTV-A2" ? "DAMAGED" : a.id === "RTV-A8" ? "QUARANTINE" : "SELLABLE"; }
function io07SeedCandidates(group, a, force = false) {
  if (!force && Array.isArray(a.sourceStateCandidates) && a.sourceStateCandidates.length) return;
  if (a.id === "RTV-A1") {
    a.sourceStateCandidates = [
      { state: "SELLABLE", available: 3, balanceId: io07SourceId(a, "SELLABLE"), balanceVersion: 12 },
      { state: "DAMAGED", available: 2, balanceId: io07SourceId(a, "DAMAGED"), balanceVersion: 7 },
    ];
    a.sourceSlices = []; a.sourceSliceUserResolved = false;
    return;
  }
  const state = io07DefaultState(a);
  a.sourceStateCandidates = [{ state, available: Math.max(io07Num(a.qty), 1), balanceId: io07SourceId(a, state), balanceVersion: 5 }];
  a.sourceSlices = [{ state, qty: io07Num(a.qty), balanceId: io07SourceId(a, state), balanceVersion: 5 }];
  a.sourceSliceUserResolved = false;
}
function io07SeedAllocation(req, group, a, force = false) {
  req.sourceRequestId = req.sourceRequestId || req.source;
  req.warehouseId = req.warehouseId || "WH-MAIN";
  req.operationId = req.operationId || `IO-RTV-${String(req.id).replace(/^RTV-/, "")}`;
  group.sourceLineId = group.sourceLineId || `SRC-LINE-${group.id}`;
  a.sourceAllocationId = a.sourceAllocationId || a.id;
  a.sourceLineId = a.sourceLineId || group.sourceLineId;
  a.sourceRequestId = req.sourceRequestId;
  a.sourceVersion = req.sourceVersion;
  io07SeedCandidates(group, a, force);
  if (!a.physicalObservation) a.physicalObservation = null;
}
function io07SeedRequest(req) { req.unknownLocked ??= false; for (const group of req.groups || []) for (const a of group.allocations || []) io07SeedAllocation(req, group, a, false); }

function io07SliceTotal(a) { return (a.sourceSlices || []).reduce((s, x) => s + io07Num(x.qty), 0); }
function io07SlicesResolved(a) { return io07Num(a.qty) >= 0 && Math.abs(io07SliceTotal(a) - io07Num(a.qty)) < 0.000001 && (a.sourceSlices || []).every((x) => io07Num(x.qty) >= 0); }
function io07NeedsSlices(a) { return (a.sourceStateCandidates || []).length > 1 && !io07SlicesResolved(a); }
function io07SliceText(slices) { return (slices || []).filter((x) => io07Num(x.qty) > 0).map((x) => `${IO07_STOCK_LABELS[x.state] || x.state} ${io07Num(x.qty)}`).join(" · "); }
function io07ShowSlices(a) { return a.sourceSliceUserResolved || (a.sourceSlices || []).length > 1; }

function io07AllVerified(req = io07Current()) {
  const lines = io07Allocations(req);
  return lines.length > 0 && lines.every(({ allocation }) => allocation.verified && !allocation.physicalMismatch && io07SlicesResolved(allocation));
}
function io07Stage(req) { if (req.queue === "WAITING") return "WAITING"; return io07AllVerified(req) ? "READY" : "ACTIONABLE"; }
function io07StageMeta(req) { const stage = io07Stage(req); if (stage === "WAITING") return ["Chờ cập nhật", "info"]; if (stage === "READY") return ["Sẵn sàng", "success"]; if (req.changed) return ["Cần kiểm lại", "warning"]; return ["Cần chuẩn bị", "warning"]; }
function io07RecipientLabel(key) { return (IO07_RECIPIENTS.find(([k]) => k === key) || IO07_RECIPIENTS[0])[1]; }
function io07NextActionableRequest() { const last = io07LastResult?.requestId; return io07ActiveRequests().find((r) => r.id !== last && r.queue !== "WAITING") || null; }
function io07PendingLines(req) { return io07Allocations(req).filter(({ allocation }) => !(allocation.verified && !allocation.physicalMismatch)).length; }
function io07ReviewReason(req) {
  if (io07HasMismatch(req)) return "Có dòng không khớp · chờ Mua hàng cập nhật";
  const n = io07PendingLines(req);
  return n ? `Còn ${n} dòng chưa kiểm` : "";
}

function io07CancelSource(reqId) {
  const req = io07Requests.find((r) => r.id === reqId);
  if (!req || req.completed) return false;
  req.sourceVersion = Number(req.sourceVersion || 0) + 1; req.sourceCancelled = true; req.closed = true; req.queue = "CLOSED"; req.lifecycle = "Đã hủy từ nguồn"; req.changed = true;
  req.sourceChanges = ["Bộ phận Mua hàng đã hủy yêu cầu trước bàn giao; lượng chờ trả được hệ thống giải phóng."];
  return true;
}

function io07ApplySourceUpdate(reqId, changes = []) {
  const req = io07Requests.find((r) => r.id === reqId);
  if (!req || req.completed || req.closed) return false;
  req.sourceVersion = Number(req.sourceVersion || 0) + 1; req.changed = true;
  const notes = [], affected = new Set();
  for (const change of changes) {
    if (change.type === "QTY") {
      const f = io07FindAllocation(change.allocationId, req); if (!f) continue;
      const a = f.allocation; a.previousQty = a.qty; a.qty = change.newQty; a.verified = false; a.physicalMismatch = false; a.affectedByChange = true; a.sourceVersion = req.sourceVersion; affected.add(a.id);
      if (!io07SlicesResolved(a)) io07SeedCandidates(f.group, a, true); else if ((a.sourceStateCandidates || []).length === 1) a.sourceSlices[0].qty = io07Num(a.qty);
      notes.push(change.note || `${f.group.name} · ${f.group.uom}: ${a.previousQty} → ${change.newQty} ${f.group.uom}.`);
    } else if (change.type === "LOT") {
      const f = io07FindAllocation(change.allocationId, req); if (!f) continue;
      const a = f.allocation; a.previousLot = a.lot; a.lot = change.newLot; a.verified = false; a.physicalMismatch = false; a.affectedByChange = true; a.sourceVersion = req.sourceVersion; affected.add(a.id); io07SeedCandidates(f.group, a, true);
      notes.push(change.note || `${f.group.name} · ${f.group.uom}: lô ${a.previousLot} → ${change.newLot}.`);
    } else if (change.type === "REMOVE") {
      for (const group of req.groups || []) {
        const idx = (group.allocations || []).findIndex((a) => a.id === change.allocationId);
        if (idx >= 0) { const old = group.allocations[idx]; group.allocations.splice(idx, 1); affected.add(old.id); notes.push(change.note || `${group.name} · ${group.uom}${old.lot ? ` · lô ${old.lot}` : ""}: bỏ khỏi yêu cầu; lượng chờ trả được trả về đúng trạng thái nguồn.`); break; }
      }
      req.groups = req.groups.filter((g) => (g.allocations || []).length);
    } else if (change.type === "ADD") {
      let group = req.groups.find((g) => g.id === change.groupId);
      if (!group && change.group) { group = { ...change.group, allocations: [] }; req.groups.push(group); }
      if (!group) continue;
      const a = { ...change.allocation, verified: false, physicalMismatch: false, affectedByChange: true };
      io07SeedAllocation(req, group, a, true); group.allocations.push(a); affected.add(a.id);
      notes.push(change.note || `${group.name} · ${group.uom}${a.lot ? ` · lô ${a.lot}` : ""}: thêm ${a.qty} ${group.uom} cần kiểm.`);
    }
  }
  for (const { allocation: a } of io07Allocations(req)) {
    if (a.physicalObservation && affected.has(a.id)) { a.physicalObservation.status = "RESOLVED_BY_SOURCE_VERSION"; a.physicalObservation.resolvedSourceVersion = req.sourceVersion; }
    a.sourceVersion = req.sourceVersion;
  }
  req.sourceChanges = notes.length ? notes : ["Yêu cầu nguồn đã được cập nhật."]; req.awaitingSourceAmendment = false; req.queue = "ACTIONABLE";
  return true;
}

function io07LinesOf(req) {
  return io07Allocations(req).map(({ group, allocation: a }) => ({ groupId: group.id, sourceLineId: a.sourceLineId, sourceAllocationId: a.sourceAllocationId, name: group.name, code: group.code, uom: group.uom, lot: a.lot, expiry: a.expiry, qty: a.qty, sourceSlices: (a.sourceSlices || []).map((s) => ({ ...s })), sourceSliceUserResolved: !!a.sourceSliceUserResolved }));
}
function io07CreateResult(req) {
  const op = req.operationId || `IO-RTV-${String(req.id).replace(/^RTV-/, "")}`; req.operationId = op;
  const lines = io07LinesOf(req);
  // Bàn giao cho nhà cung cấp là lúc tồn vật lý giảm, theo từng tình trạng của phần hàng trả: ghi vào sổ chung.
  lines.forEach((l) => (l.sourceSlices || []).forEach((sl) => {
    const state = t7Ledger.STATE_LABEL[sl.state];
    if (state && sl.qty > 0) t7Ledger.post({ key: `UIF-07:${req.id}:${l.sourceAllocationId || l.groupId}:${sl.state}`, productId: l.code, lot: l.lot, kind: "Trả nhà cung cấp", doc: req.id, delta: -sl.qty, state, sourceFlow: "UIF-07", opId: op });
  }));
  const evidence = { handoverEvidenceId: `HE-${op}`, operationId: op, sourceType: "SUPPLIER_RETURN", sourceDocumentId: req.source, sourceVersion: req.sourceVersion, sourceContext: { sourceRequestId: req.sourceRequestId, inventoryRequestId: req.id }, warehouseId: req.warehouseId, actorId: IO07_ACTOR.id, actor: IO07_ACTOR.name, recipient: io07Recipient, confirmedAt: IO07_CONFIRMED_AT, lineEvidence: lines.map((l) => ({ sourceLineId: l.sourceLineId, sourceAllocationId: l.sourceAllocationId, productCode: l.code, uom: l.uom, lot: l.lot, quantity: l.qty, sourceSlices: l.sourceSlices })) };
  evidence.evidenceHash = io07StableHash(evidence);
  io07LastResult = { operationId: op, requestId: req.id, sourceRequestId: req.sourceRequestId, supplier: req.supplier, source: req.source, sourceVersion: req.sourceVersion, warehouse: req.warehouse, actorId: IO07_ACTOR.id, actor: IO07_ACTOR.name, recipient: io07Recipient, confirmedAt: IO07_CONFIRMED_AT, lines, handoverEvidence: evidence };
  req.handoverEvidence = evidence; req.confirmedAt = IO07_CONFIRMED_AT;
  return io07LastResult;
}
function io07ResultSnapshot() {
  if (io07LastResult) return io07LastResult;
  const req = io07Current();
  return { operationId: req.operationId, requestId: req.id, sourceRequestId: req.sourceRequestId, supplier: req.supplier, source: req.source, sourceVersion: req.sourceVersion, warehouse: req.warehouse, actorId: IO07_ACTOR.id, actor: IO07_ACTOR.name, recipient: io07Recipient, confirmedAt: req.confirmedAt || IO07_CONFIRMED_AT, lines: io07LinesOf(req) };
}

function io07MarkVerified(a, method = "VISUAL") {
  a.verified = true; a.physicalMismatch = false; a.affectedByChange = false; a.verifyMethod = method;
  a.verifiedSourceVersion = io07Current().sourceVersion; a.verifiedAt = IO07_CONFIRMED_AT;
}
// "Đúng hàng" một chạm trên dòng: không áp cho dòng còn phải chọn phần hàng hoặc đang không khớp.
function io07VerifyQuick(allocationId) {
  const found = io07FindAllocation(allocationId); if (!found) return false;
  const a = found.allocation;
  if (!io07SlicesResolved(a) || a.physicalMismatch) return false;
  io07MarkVerified(a, "VISUAL");
  return true;
}
function io07RecordObservation(req) {
  const found = io07ActiveFound(); if (!found) return false;
  const { allocation: a } = found;
  if (!io07MismatchValid()) return false;
  const observation = {
    observationId: `OBS-${a.sourceAllocationId}-${String((a.observationSeq || 0) + 1).padStart(3, "0")}`,
    sourceRequestId: req.sourceRequestId, sourceVersion: req.sourceVersion, sourceLineId: a.sourceLineId, sourceAllocationId: a.sourceAllocationId,
    mismatchType: io07MismatchType, expectedQuantity: a.qty, actualQuantity: io07MismatchType === "QUANTITY" ? io07Num(io07MismatchQty) : null, expectedLot: a.lot || null, actualLot: io07MismatchType === "LOT" ? String(io07MismatchLot).trim() : null, note: io07MismatchType === "OTHER" ? String(io07MismatchNote).trim() : "",
    actorId: IO07_ACTOR.id, actor: IO07_ACTOR.name, observedAt: IO07_CONFIRMED_AT, stockEffect: "NONE", status: "OPEN",
  };
  observation.observationHash = io07StableHash(observation);
  a.observationSeq = Number(a.observationSeq || 0) + 1; a.physicalObservation = observation; a.verified = false; a.physicalMismatch = true; a.affectedByChange = false;
  req.queue = "WAITING"; req.awaitingSourceAmendment = true; req.waitingReason = "Đã gửi chênh lệch thực tế. Đang chờ Mua hàng cập nhật yêu cầu.";
  io07MismatchOpen = false; io07VerifySheetOpen = false; io07ScanLot = "";
  io07SetState("SCR-037", "WAITING");
  return true;
}
function io07MismatchValid() {
  return Boolean(io07MismatchType && (io07MismatchType !== "QUANTITY" || String(io07MismatchQty).trim() !== "") && (io07MismatchType !== "LOT" || String(io07MismatchLot).trim()) && (io07MismatchType !== "OTHER" || String(io07MismatchNote).trim()));
}

/* ---------- Trạng thái trong luồng và trạng thái đặt từ bộ kiểm ----------
 * Đi bằng nút trong màn thì đặt trạng thái qua io07SetState (đánh dấu "đã biết"). Trạng thái khác với dấu đã biết nghĩa là
 * bộ kiểm / đường dẫn đặt từ ngoài: dựng lại yêu cầu từ bản gốc rồi chuẩn bị đúng yêu cầu cho trạng thái đó. */
const io07Expected = {};
function io07SetState(screenId, state) { stateByScreen[screenId] = state; io07Expected[screenId] = state; }
function io07ResetUi() { io07ActiveAllocationId = ""; io07VerifySheetOpen = false; io07ScanLot = ""; io07ResultSheetOpen = false; io07MismatchOpen = false; io07MismatchType = ""; io07MismatchQty = ""; io07MismatchLot = ""; io07MismatchNote = ""; }
function io07Restore() {
  io07Requests.splice(0, io07Requests.length, ...io07InitialRequests());
  io07Requests.forEach(io07SeedRequest);
  io07LastResult = null; io07Recipient = "SUPPLIER"; io07Selected = "RTV-260827-02"; io07ResetUi();
}
// Đủ "Đã kiểm" cho yêu cầu mẫu (039 / 041 mở thẳng): DH2507 chia 2 Bán được + 2 Hỏng.
function io07PrepareVerified(req) {
  io07Allocations(req).forEach(({ allocation: a }) => {
    if (a.id === "RTV-A1") a.sourceSlices = [{ state: "SELLABLE", qty: 2, balanceId: io07SourceId(a, "SELLABLE"), balanceVersion: 12 }, { state: "DAMAGED", qty: 2, balanceId: io07SourceId(a, "DAMAGED"), balanceVersion: 7 }];
    if (a.id === "RTV-A1") a.sourceSliceUserResolved = true;
    io07MarkVerified(a);
  });
  req.reviewSourceVersion = req.sourceVersion;
}
function bj07Seed(screenId, state) {
  if (io07Expected[screenId] === state) return;
  io07Expected[screenId] = state;
  io07Restore();
  if (screenId === "SCR-037") {
    if (state === "SOURCE_UPDATED") io07Selected = "RTV-260827-04";
    if (state === "WAITING") io07Selected = "RTV-260903-05";
    return;
  }
  const req = io07Current();
  if (screenId === "SCR-039") {
    io07PrepareVerified(req);
    if (state === "SOURCE_CHANGED") req.reviewSourceVersion = Number(req.sourceVersion) - 1;
    if (state === "PHYSICAL_MISMATCH" || state === "VALIDATION_ERROR") io07Allocations(req)[1].allocation.physicalMismatch = true;
    return;
  }
  if (screenId === "SCR-041" && !["UNKNOWN", "REJECTED_EXECUTION", "PERMISSION_DENIED", "PROCESSING"].includes(state)) {
    io07PrepareVerified(req); io07CreateResult(req); req.completed = true; req.queue = "CLOSED";
  }
}
function bj07Restore() { io07Restore(); Object.keys(io07Expected).forEach((k) => delete io07Expected[k]); }
io07Restore();

/* ---------- Dựng phần dùng chung ---------- */

function io07Shell(opts) { return appShell({ extraClass: "k7-wide", ...opts }); }
function io07Denied(title, back = true) { return io07Shell({ title, body: k1Denied({ ...IO07_DENIED, exitAttr: k1ExitAttr("SCR-036") }), centered: true, back }); }
function io07Tone(tone) { return { success: "Success", warning: "Warning", danger: "Danger", info: "Info" }[tone] || "Neutral"; }
function io07Progress(done, total) {
  if (!total) return "";
  return `<div class="bj02-progress-block bj07-progress" data-ds-component="VProgress"><div class="bj02-progress" role="progressbar" aria-label="Tiến độ kiểm hàng trả" aria-valuemin="0" aria-valuemax="${total}" aria-valuenow="${done}"><span style="width:${Math.round(done / total * 100)}%"></span></div><small>Đã kiểm ${done}/${total} dòng</small></div>`;
}
function io07Link(label, attrs = "") { return `<button class="k7-row-link bj07-link" type="button" ${attrs}>${esc(label)}</button>`; }
function io07SmallButton(label, attrs = "", disabled = false) { return `<button class="button button--secondary bj07-small-button" type="button" ${attrs}${disabled ? " disabled" : ""} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.small">${esc(label)}</button>`; }
function io07Summary(req) { return ac310KeyValueSurface("Tóm tắt", [["Nhà cung cấp", req.supplier], ["Yêu cầu trả", req.id], ["Chứng từ nguồn", req.source], ["Kho", req.warehouse]]); }

/* ---------- Sheet kiểm hàng / chênh lệch / dòng hàng ---------- */

function io07SliceInputs(group, a) {
  const candidates = a.sourceStateCandidates || [];
  if (candidates.length <= 1) return "";
  const current = new Map((a.sourceSlices || []).map((s) => [s.state, io07Num(s.qty)]));
  const fields = candidates.map((c) => `<label class="ds24-field v395-source-slice-field" data-ds-component="VNumberField"><span class="c45-text-style-8">${esc(IO07_STOCK_LABELS[c.state] || c.state)}</span><div class="v395-source-slice-control"><input class="ds24-field__control c45-text-style-6" type="number" min="0" max="${c.available}" step="1" inputmode="decimal" value="${io07Attr(current.get(c.state) || "")}" data-io07-source-slice="${io07Attr(c.state)}" aria-label="${io07Attr(`${IO07_STOCK_LABELS[c.state] || c.state} — số ${group.uom} trả`)}"><small class="c45-text-style-11">Tối đa ${c.available} ${esc(group.uom)}</small></div></label>`).join("");
  return `<section class="v395-source-slices" data-composed-from="VNumberField,DS v2 / Key-value Row">${ds24SectionTitle("Trả từ phần hàng nào", `${io07SliceTotal(a)}/${a.qty} ${group.uom}`)}<p class="c45-text-style-11 v395-source-help">Lô này có hàng ở nhiều tình trạng. Ghi số lượng trả từ từng phần.</p>${fields}<div data-bj07-source-feedback>${io07SliceFeedback(group, a)}</div></section>`;
}
function io07SliceFeedback(group, a) { return io07SlicesResolved(a) ? "" : vBanner("warning", `Cần chia đủ ${t7Qty(a.qty, group.uom)}`, "", ""); }
function io07ScanMatches(group, a) {
  if (group.tracking !== "LOT") return true;
  const scanned = String(io07ScanLot || "").trim();
  return !scanned || scanned.toLocaleUpperCase("vi") === String(a.lot || "").trim().toLocaleUpperCase("vi");
}
function io07VerifyDisabled(group, a) { return !io07ScanMatches(group, a) || !io07SlicesResolved(a); }
function io07VerificationSheet(req) {
  if (!io07VerifySheetOpen) return "";
  const found = io07FindAllocation(io07ActiveAllocationId, req); if (!found) return "";
  const { group, allocation: a } = found;
  const expectedLot = group.tracking === "LOT" ? String(a.lot || "") : "";
  const mismatch = Boolean(expectedLot && String(io07ScanLot || "").trim() && String(io07ScanLot).trim().toLocaleUpperCase("vi") !== expectedLot.toLocaleUpperCase("vi"));
  const product = ds24ContextStatusRow({ title: group.name, subtitle: `${group.code} · ${group.uom}`, label: a.verified ? "Đã kiểm" : "Cần kiểm", tone: a.verified ? "Success" : "Neutral", leading: "package", attrs: 'data-layout-role="rtv-verify-product"' });
  const facts = ds24InfoGroup("", `${ds24InfoRow("Cần chuẩn bị", t7Qty(a.qty, group.uom))}${group.tracking === "LOT" ? ds24InfoRow("Lô theo yêu cầu", a.lot) : ""}${a.expiry ? ds24InfoRow("Hạn dùng", a.expiry) : ""}`, "ds24-info-group--untitled io07-sheet-facts");
  const lotInput = group.tracking === "LOT" ? `${ds24TextField("Lô thực tế (không bắt buộc)", io07ScanLot, "data-io07-scan-lot autocomplete=\"off\"", "Chỉ đối chiếu với lô theo yêu cầu.")}<div data-io07-scan-feedback>${mismatch ? io07LotMismatchBanner(expectedLot) : ""}</div>` : "";
  return `<div class="sheet-backdrop io07-verify-backdrop" data-io07-verify-backdrop><section class="bottom-sheet io-bottom-sheet io07-verification-sheet v395-verification-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="Kiểm hàng thực tế"><div class="sheet-handle"></div><div class="sheet-title"><h3>Kiểm hàng thực tế</h3></div><div class="io07-verification-content">${product}${facts}${lotInput}${io07SliceInputs(group, a)}<div class="io07-sheet-actions"><button class="button button--secondary" data-io07-action="mark-mismatch" type="button">Không khớp</button><button class="button button--primary" data-io07-action="confirm-allocation" type="button" ${io07VerifyDisabled(group, a) ? "disabled" : ""}>Đúng hàng</button></div></div></section></div>`;
}
function io07LotMismatchBanner(expectedLot) { return vBanner("error", "Lô không khớp", `Theo yêu cầu là lô ${expectedLot}. Hãy ghi nhận chênh lệch để Mua hàng cập nhật.`, ""); }
function io07MismatchSheet(req) {
  if (!io07MismatchOpen) return "";
  const found = io07FindAllocation(io07ActiveAllocationId, req); if (!found) return "";
  const { group, allocation: a } = found;
  const options = [["QUANTITY", "Sai số lượng"], ["LOT", "Sai lô"], ["ITEM_NOT_FOUND", "Không thấy hàng"], ["OTHER", "Khác"]].map(([v, l]) => `<button type="button" class="v395-mismatch-choice${io07MismatchType === v ? " is-selected" : ""}" data-io07-action="select-mismatch" data-io07-mismatch-type="${v}" aria-pressed="${io07MismatchType === v ? "true" : "false"}">${l}</button>`).join("");
  const qty = io07MismatchType === "QUANTITY" ? ds24TextField("Số lượng thực tế", io07MismatchQty, 'data-io07-mismatch-qty type="number" min="0" step="1" inputmode="decimal"', `Theo yêu cầu: ${t7Qty(a.qty, group.uom)}`) : "";
  const lot = io07MismatchType === "LOT" ? ds24TextField("Lô thực tế", io07MismatchLot, "data-io07-mismatch-lot autocomplete=\"off\"", `Theo yêu cầu: ${a.lot || "—"}`) : "";
  const note = io07MismatchType === "OTHER" ? ds24TextField("Mô tả chênh lệch", io07MismatchNote, "data-io07-mismatch-note autocomplete=\"off\"", "Bắt buộc khi chọn Khác.") : "";
  return `<div class="sheet-backdrop v395-mismatch-backdrop" data-io07-mismatch-backdrop><section class="bottom-sheet io-bottom-sheet v395-mismatch-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="Ghi nhận chênh lệch thực tế"><div class="sheet-handle"></div><div class="sheet-title"><h3>Ghi nhận chênh lệch</h3></div><div class="sheet-content"><p class="c45-text-style-11 v395-source-help">Chỉ ghi nhận điều nhìn thấy thực tế. Kho không tự sửa yêu cầu trả hoặc thay lô.</p><div class="v395-mismatch-choices">${options}</div>${qty}${lot}${note}<div class="io07-sheet-actions"><button class="button button--secondary" data-io07-action="close-mismatch" type="button">Hủy</button><button class="button button--primary" data-io07-action="record-mismatch-observation" type="button" ${io07MismatchValid() ? "" : "disabled"}>Gửi chênh lệch</button></div></div></section></div>`;
}

// Hàng của một lần bàn giao, gộp theo sản phẩm (đầu nhóm + từng lô). lines: { name, code, uom, lot, expiry, qty, sourceSlices, sourceSliceUserResolved }.
function io07ReviewRows(lines) {
  const map = new Map();
  for (const l of lines || []) { const key = `${l.name}|${l.code || ""}|${l.uom}`; if (!map.has(key)) map.set(key, []); map.get(key).push(l); }
  return [...map.values()].flatMap((group) => { const total = group.reduce((s, l) => s + io07Num(l.qty), 0); return group.map((l, i) => ({ ...l, first: i === 0, total })); });
}
function io07LineSub(l) { return [l.expiry ? `HSD ${l.expiry}` : "", io07ShowSlices(l) ? `Trả từ ${io07SliceText(l.sourceSlices)}` : ""].filter(Boolean).join(" · "); }
function io07ProductHead(l, trailing = "") { return ds24ListRow({ title: l.name, subtitle: `${l.code} · Trả ${t7Qty(l.total, l.uom)}`, trailing, leading: "package", type: "Status", density: "Compact", interactive: false, extraClass: "bj07-lot-head" }); }
function io07ReviewMobileRow(l) {
  const head = l.first ? io07ProductHead(l) : "";
  const row = ds24ListRow({ title: l.lot ? `Lô ${l.lot}` : "Không theo lô", subtitle: io07LineSub(l), trailing: `<strong class="bj07-row-quantity">${esc(t7Qty(l.qty, l.uom))}</strong>`, leading: null, type: "Status", density: "Default", interactive: false, extraClass: "bj07-review-row" });
  return `${head}${row}`;
}
function io07ReviewTable(lines, caption) {
  const rows = io07ReviewRows(lines).map((l) => ({ ...l, productHtml: l.first ? `<strong>${esc(l.name)}</strong><small>${esc(l.code)}</small>` : `<span class="k7-sr">${esc(l.name)}</span>`, lotText: l.lot ? `Lô ${l.lot}` : "Không theo lô", expiryText: l.expiry || "—", fromText: io07ShowSlices(l) ? io07SliceText(l.sourceSlices) : "—", qtyText: t7Qty(l.qty, l.uom) }));
  const columns = [{ key: "productHtml", label: "Sản phẩm", html: true }, { key: "lotText", label: "Lô" }, { key: "expiryText", label: "HSD", mono: true }, { key: "fromText", label: "Trả từ" }, { key: "qtyText", label: "Trả", align: "end", mono: true }];
  return k7Table({ columns, rows, mobileRow: io07ReviewMobileRow, caption });
}
function io07LineCount(lines) { return (lines || []).length; }
function io07GroupCount(lines) { return new Set((lines || []).map((l) => `${l.name}|${l.code || ""}|${l.uom}`)).size; }
function io07ResultSheet(result) {
  if (!io07ResultSheetOpen || !result) return "";
  const rows = io07ReviewRows(result.lines).map((l) => ds24ListRow({ title: l.name, subtitle: [l.code, l.lot ? `Lô ${l.lot}` : "Không theo lô", io07ShowSlices(l) ? `Trả từ ${io07SliceText(l.sourceSlices)}` : ""].filter(Boolean).join(" · "), trailing: `<strong class="bj07-row-quantity">${esc(t7Qty(l.qty, l.uom))}</strong>`, leading: null, type: "Status", interactive: false, density: "Compact" })).join("");
  const body = `<section class="bj06-section">${ds24SectionTitle("Hàng đã bàn giao", `${io07GroupCount(result.lines)} mặt hàng · ${io07LineCount(result.lines)} dòng`)}<div class="ds24-list-stack">${rows}</div></section><button class="button button--primary button--full" type="button" data-io07-sheet-close data-ds-component="VButton">Đóng</button>`;
  return ds24Sheet({ title: `Chi tiết ${io07LineCount(result.lines)} dòng hàng`, body, attrs: "data-io07-sheet-close-backdrop" });
}

/* ---------- SCR-037 Chuẩn bị hàng trả ---------- */

function io07LotRows(req) {
  return (req.groups || []).flatMap((group) => {
    const allocs = group.allocations || [], total = allocs.reduce((s, a) => s + io07Num(a.qty), 0);
    return allocs.map((allocation, i) => ({ group, allocation, first: i === 0, total }));
  });
}
function io07LotSub(group, a) {
  const bits = [];
  if (a.expiry) bits.push(`HSD ${a.expiry}`);
  bits.push(`Trả ${t7Qty(a.qty, group.uom)}`);
  if (a.previousQty != null && a.affectedByChange) bits.push(`Trước ${t7Qty(a.previousQty, group.uom)}`);
  if (io07NeedsSlices(a)) bits.push("Cần chọn phần hàng");
  return bits.join(" · ");
}
// Bên phải một dòng lô: nút "Đúng hàng" / badge. readOnly: yêu cầu đang chờ Mua hàng cập nhật.
function io07LotAction(group, a, readOnly) {
  if (a.physicalMismatch) return ds24Badge("Không khớp", "Danger");
  if (a.verified && !a.affectedByChange) return ds24Badge("Đã kiểm", "Success");
  if (readOnly) return "";
  // Dòng còn phải chọn phần hàng thì nút mở dòng đó để chọn (không còn nút "Đúng hàng" xám).
  if (io07NeedsSlices(a)) return io07SmallButton("Chọn phần hàng", `data-io07-allocation="${io07Attr(a.id)}" aria-label="${io07Attr(`Chọn phần hàng ${io07LabelOf(group, a)} ${group.name}`)}"`);
  const label = `Đúng hàng ${io07LabelOf(group, a)} ${group.name}`;
  return io07SmallButton("Đúng hàng", `data-io07-verify-quick="${io07Attr(a.id)}" aria-label="${io07Attr(label)}"`);
}
function io07MobileLotRow(r, readOnly) {
  const { group, allocation: a } = r;
  const head = r.first ? io07ProductHead({ ...group, total: r.total }) : "";
  const copy = `<span class="ds24-list-row__copy"><strong>${esc(io07LabelOf(group, a))}</strong><small>${esc(io07LotSub(group, a))}</small></span>`;
  const main = readOnly ? `<span class="bj07-lot__main">${copy}</span>` : `<button class="bj07-lot__main" type="button" data-io07-allocation="${io07Attr(a.id)}">${copy}</button>`;
  return `${head}<div class="bj07-lot ds24-list-row ds24-list-row--no-leading" data-ds-component="DS v2 / List Row" data-ds-prop-type="Status" data-ds-prop-state="Default" data-ds-prop-density="Default" data-ds-prop-leading="Hidden" data-io07-lot-row="${io07Attr(a.id)}">${main}<span class="bj07-lot__action">${io07LotAction(group, a, readOnly)}</span></div>`;
}
function io07WebCells(r, readOnly) {
  const { group, allocation: a } = r;
  const product = r.first ? `<strong>${esc(group.name)}</strong><small>${esc(group.code)}</small>` : `<span class="k7-sr">${esc(group.name)}</span>`;
  const label = esc(io07LabelOf(group, a));
  const lot = readOnly ? label : `<button class="k7-row-link bj07-line-link" type="button" data-io07-allocation="${io07Attr(a.id)}">${label}</button>`;
  const note = io07NeedsSlices(a) ? '<small class="bj07-cell-note">Cần chọn phần hàng</small>' : "";
  const before = a.previousQty != null && a.affectedByChange ? `<small class="bj07-cell-note">Trước ${esc(t7Qty(a.previousQty, group.uom))}</small>` : "";
  return { product, lot: `${lot}${note}`, expiry: a.expiry ? esc(a.expiry) : '<span class="k7-muted">—</span>', qty: `${esc(t7Qty(a.qty, group.uom))}${before}`, check: io07LotAction(group, a, readOnly) };
}
function render037BJ07(state) {
  const title = "Chuẩn bị hàng trả";
  bj07Seed("SCR-037", state);
  if (state === "PERMISSION_DENIED") return io07Denied(title);
  const req = io07Current(), subtitle = `${req.id} · ${req.supplier}`;
  if (state === "LOADING") return io07Shell({ title, subtitle, body: k1Loading({ blocks: ["heading", "row", "card", "card"] }) });
  if (req.sourceCancelled || req.closed) {
    return io07Shell({ title, subtitle, body: vBanner("info", "Yêu cầu đã được hủy", "Phần chờ trả đã được hệ thống trả về đúng trạng thái nguồn; Kho không cần thao tác thêm."), actions: k4Footer([{ label: "Về hàng cần xử lý", attr: 'data-k5-action="to-list"', primary: true }]) });
  }
  const waiting = io07Waiting(req), total = io07Allocations(req).length, done = io07VerifiedCount(req);
  const note = `<p class="bj06-note">Yêu cầu do Mua hàng chuyển sang Kho · ${esc(req.source)}</p>`;
  const delta = (() => {
    const notes = (req.sourceChanges || []).filter(Boolean);
    if (!req.changed && !notes.length) return "";
    return vBanner("warning", "Yêu cầu đã cập nhật", esc(notes.length ? notes.join(" ") : "Yêu cầu nguồn đã thay đổi. Chỉ phần bị ảnh hưởng cần kiểm lại."), "");
  })();
  const locked = state === "LOCKED" ? k1Locked({ title: "Đang thuộc phạm vi kiểm kê", description: "Thông tin chỉ đọc cho đến khi phiên kiểm kê kết thúc." }) : "";
  const readOnly = waiting || state === "LOCKED";
  const waitBanner = waiting ? vBanner("info", "Chờ cập nhật yêu cầu", esc(req.waitingReason || "Kho chỉ xem trong lúc Mua hàng cập nhật yêu cầu theo chênh lệch thực tế."), "") : "";
  const rows = io07LotRows(req).map((r) => ({ ...r, ...io07WebCells(r, readOnly) }));
  const columns = [{ key: "product", label: "Sản phẩm", html: true }, { key: "lot", label: "Lô", html: true }, { key: "expiry", label: "HSD", html: true, mono: true }, { key: "qty", label: "Trả", html: true, align: "end", mono: true }, { key: "check", label: "Kiểm", html: true, align: "end" }];
  const table = k7Table({ columns, rows, mobileRow: (r) => io07MobileLotRow(r, readOnly), caption: "Hàng trả theo lô", rowAttr: (r) => (readOnly ? "" : `data-io07-row="${io07Attr(r.allocation.id)}"`) });
  const main = `${note}${locked}${delta}${waitBanner}${waiting ? "" : io07Progress(done, total)}${table}`;
  const body = `<div class="bj07-prepare">${k7Split({ main, aside: io07Summary(req), wideMain: true, asideWebOnly: true })}</div>${readOnly ? "" : io07VerificationSheet(req)}${readOnly ? "" : io07MismatchSheet(req)}`;
  const blocked = !io07AllVerified(req) || io07HasMismatch(req);
  return io07Shell({ title, subtitle, body, actions: readOnly ? "" : k4ReasonFooter({ label: "Rà soát bàn giao", attr: 'data-io07-action="review-handover"', disabled: blocked, reason: io07ReviewReason(req) }) });
}

/* ---------- SCR-039 Bàn giao trả nhà cung cấp ---------- */

function render039BJ07(state) {
  const title = "Bàn giao trả nhà cung cấp";
  bj07Seed("SCR-039", state);
  if (state === "PERMISSION_DENIED") return io07Denied(title);
  const req = io07Current(), subtitle = `${req.id} · ${req.supplier}`;
  const sourceChanged = state === "SOURCE_CHANGED" || Number(req.reviewSourceVersion ?? req.sourceVersion) !== Number(req.sourceVersion);
  if (sourceChanged) {
    return io07Shell({ title, subtitle, body: k1Stale({ title: "Cần kiểm lại trước khi bàn giao", description: "Yêu cầu nguồn đã đổi. Chỉ phần bị ảnh hưởng cần kiểm lại.", actionLabel: "Kiểm lại hàng", actionAttr: 'data-io07-action="back-to-preparation"' }) });
  }
  const mismatch = io07HasMismatch(req) || state === "PHYSICAL_MISMATCH" || state === "VALIDATION_ERROR";
  const ready = io07AllVerified(req) && !mismatch && req.queue !== "WAITING";
  const lines = io07LinesOf(req);
  const banner = ready ? "" : vBanner("warning", "Cần kiểm lại trước khi bàn giao", "Một số hàng chưa đủ điều kiện bàn giao. Hãy kiểm lại.");
  const recipient = `<section class="bj06-section">${ds24SectionTitle("Giao cho")}${dsSegmented({ items: IO07_RECIPIENTS, value: io07Recipient, attr: "data-io07-recipient", label: "Giao cho" })}</section>`;
  const aside = `${recipient}<div class="k7-web-only">${io07Summary(req)}</div>`;
  const main = `${banner}<section class="bj06-section">${ds24SectionTitle("Hàng sẽ bàn giao", `${io07GroupCount(lines)} mặt hàng · ${io07LineCount(lines)} dòng`)}${io07ReviewTable(lines, "Hàng sẽ bàn giao theo lô")}</section><p class="bj06-note">Xác nhận khi hàng đã giao thực tế. Tồn vật lý và giá trị chỉ giảm sau bước này.</p>`;
  const body = `<div class="bj07-handover"><div class="k7-split k7-split--wide-main"><aside class="k7-split__aside">${aside}</aside><div class="k7-split__main">${main}</div></div></div>`;
  const actions = ready ? k4Footer([{ label: "Xác nhận đã bàn giao", attr: 'data-io07-action="confirm-handover"', primary: true }]) : k4Footer([{ label: "Kiểm lại hàng", attr: 'data-io07-action="back-to-preparation"', primary: true }]);
  return io07Shell({ title, subtitle, body, actions });
}

/* ---------- SCR-041 Kết quả trả nhà cung cấp (K4 / K3) ---------- */

function render041BJ07(state) {
  const title = "Kết quả trả nhà cung cấp";
  bj07Seed("SCR-041", state);
  if (state === "PERMISSION_DENIED") return io07Denied(title, false);
  if (state === "PROCESSING") return io07Shell({ title, body: k1Loading({ blocks: ["heading", "card", "row"] }), centered: true, back: false });
  const result = io07ResultSnapshot(), req = io07Requests.find((r) => r.id === result.requestId) || io07Current();
  const toList = { label: "Về hàng cần xử lý", attr: 'data-k5-action="to-list"' };
  if (state === "UNKNOWN" || state === "COMMIT_UNKNOWN") {
    return k3Unknown({ operation: "Bàn giao trả nhà cung cấp", scope: `${result.requestId} · ${result.supplier}`, ref: result.operationId || req.operationId, sentAt: IO07_CONFIRMED_AT, sourceFlow: "UIF-07", exitAttr: k1ExitAttr("SCR-036"), handoff: { operation: result.operationId || req.operationId, scope: `${result.requestId} · ${result.source}` } });
  }
  if (state === "REJECTED_EXECUTION" || state === "REJECTED") {
    const open = req && !req.closed && !req.completed;
    return k4Result({ screenTitle: title, kind: "warning", title: "Chưa ghi nhận bàn giao", description: "Không có tác động tồn kho mới. Xem lại yêu cầu hiện hành trước khi tiếp tục.", facts: [["Yêu cầu", result.requestId], ["Tồn kho", "Không thay đổi"]], next: open ? [toList, { label: "Xem yêu cầu hiện tại", attr: 'data-io07-action="back-to-rtv-request"', primary: true }] : [{ ...toList, primary: true }] });
  }
  // COMPLETED; PENDING_APPROVAL / EXPIRED (trạng thái chung của 041, không có ở BJ-07) dựng như COMPLETED.
  const facts = [["Nhà cung cấp", result.supplier], ["Yêu cầu trả", result.requestId], ["Chứng từ nguồn", result.source], ["Giao cho", io07RecipientLabel(result.recipient)], ["Người bàn giao", result.actor], ["Bàn giao lúc", result.confirmedAt || IO07_CONFIRMED_AT]];
  const button = `${io07Link(`Xem ${io07LineCount(result.lines)} dòng hàng`, "data-io07-result-detail")}${io07ResultSheet(result)}`;
  const nextReq = io07NextActionableRequest();
  const next = nextReq ? [toList, { label: "Yêu cầu tiếp theo", attr: "data-io07-next-request", primary: true }] : [{ ...toList, primary: true }];
  return k4Result({ screenTitle: title, title: "Đã bàn giao cho nhà cung cấp", description: "Tồn vật lý và giá trị đã giảm theo đúng hàng bàn giao.", facts, button, next });
}

/* ---------- Sự kiện (một khối, chỉ khi đang ở UIF-07) ---------- */

function io07Rerender(focusSelector = "") {
  const top = document.querySelector("#app-screen .app-content")?.scrollTop || 0;
  renderAppScreen();
  const content = document.querySelector("#app-screen .app-content"); if (content) content.scrollTop = top;
  if (focusSelector) [...document.querySelectorAll(focusSelector)].find((el) => el.offsetParent !== null)?.focus({ preventScroll: true });
}
function io07Open(reqId) {
  io07Selected = reqId; io07ResetUi(); io07Recipient = "SUPPLIER";
  io07SetState("SCR-037", io07Current().changed ? "SOURCE_UPDATED" : "READY");
}
function io07SyncVerifyButton() {
  const found = io07ActiveFound(); if (!found) return;
  const { group, allocation: a } = found;
  const b = document.querySelector('[data-io07-action="confirm-allocation"]'); if (b) b.disabled = io07VerifyDisabled(group, a);
  const fb = document.querySelector("[data-bj07-source-feedback]"); if (fb) fb.innerHTML = io07SliceFeedback(group, a);
  const t = document.querySelector(".v395-source-slices .ds24-section-title span"); if (t) t.textContent = `${io07SliceTotal(a)}/${a.qty} ${group.uom}`;
}
function io07SyncMismatchButton() { const b = document.querySelector('[data-io07-action="record-mismatch-observation"]'); if (b) b.disabled = !io07MismatchValid(); }

document.addEventListener("input", (event) => {
  if (activeFlowId !== "UIF-07") return;
  const t = event.target;
  if (t.matches("[data-io07-scan-lot]")) {
    io07ScanLot = t.value;
    const found = io07ActiveFound();
    if (found) { const fb = document.querySelector("[data-io07-scan-feedback]"); if (fb) fb.innerHTML = io07ScanMatches(found.group, found.allocation) ? "" : io07LotMismatchBanner(String(found.allocation.lot || "")); io07SyncVerifyButton(); }
    return;
  }
  if (t.matches("[data-io07-source-slice]")) {
    const found = io07ActiveFound(); if (!found) return;
    const a = found.allocation, state = t.dataset.io07SourceSlice, c = (a.sourceStateCandidates || []).find((x) => x.state === state); if (!c) return;
    const q = Math.max(0, Math.min(io07Num(t.value), io07Num(c.available)));
    const map = new Map((a.sourceSlices || []).map((s) => [s.state, { ...s }]));
    if (q > 0) map.set(state, { state, qty: q, balanceId: c.balanceId, balanceVersion: c.balanceVersion }); else map.delete(state);
    a.sourceSlices = [...map.values()]; a.sourceSliceUserResolved = true; a.verified = false; io07SyncVerifyButton();
    return;
  }
  if (t.matches("[data-io07-mismatch-qty]")) { io07MismatchQty = t.value; return io07SyncMismatchButton(); }
  if (t.matches("[data-io07-mismatch-lot]")) { io07MismatchLot = t.value; return io07SyncMismatchButton(); }
  if (t.matches("[data-io07-mismatch-note]")) { io07MismatchNote = t.value; return io07SyncMismatchButton(); }
}, true);

onDialogClose["UIF-07"] = () => {
  if (!(io07VerifySheetOpen || io07MismatchOpen || io07ResultSheetOpen)) return false;
  if (io07MismatchOpen) { io07MismatchOpen = false; io07MismatchType = ""; } else { io07VerifySheetOpen = false; io07ScanLot = ""; io07ResultSheetOpen = false; }
  renderAppScreen(); return true;
};

document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-07") return;
  const t = event.target, hit = (sel) => t.closest?.(sel);
  let el;
  if ((el = hit("[data-io07-verify-quick]"))) {
    event.preventDefault(); event.stopPropagation();
    const id = el.dataset.io07VerifyQuick;
    if (el.disabled || !io07VerifyQuick(id)) return;
    return io07Rerender(`[data-io07-allocation="${CSS.escape(id)}"]`);
  }
  if ((el = hit("[data-io07-recipient]"))) { event.preventDefault(); io07Recipient = el.dataset.io07Recipient; return io07Rerender(`[data-io07-recipient="${el.dataset.io07Recipient}"]`); }
  if (t.matches?.("[data-io07-verify-backdrop]")) { event.preventDefault(); io07VerifySheetOpen = false; io07ScanLot = ""; return renderAppScreen(); }
  if (t.matches?.("[data-io07-mismatch-backdrop]")) { event.preventDefault(); io07MismatchOpen = false; io07MismatchType = ""; return renderAppScreen(); }
  if (hit("[data-io07-result-detail]")) { event.preventDefault(); io07ResultSheetOpen = true; return renderAppScreen(); }
  if (hit("[data-io07-sheet-close]") || t.matches?.("[data-io07-sheet-close-backdrop]")) { event.preventDefault(); io07ResultSheetOpen = false; return renderAppScreen(); }
  if (hit("[data-io07-next-request]")) {
    event.preventDefault(); const next = io07NextActionableRequest(); if (!next) return;
    io07Open(next.id); return navigate("SCR-037");
  }
  if ((el = hit("[data-io07-allocation], [data-io07-row]")) && activeScreenId === "SCR-037") {
    event.preventDefault();
    if (io07Waiting(io07Current())) return;
    io07ActiveAllocationId = el.dataset.io07Allocation || el.dataset.io07Row; io07ScanLot = ""; io07VerifySheetOpen = true;
    return renderAppScreen();
  }
  const a = hit("[data-io07-action]"); if (!a) return;
  event.preventDefault(); event.stopPropagation();
  if (a.disabled) return;
  const k = a.dataset.io07Action, req = io07Current();
  if (k === "mark-mismatch") { if (!io07ActiveFound()) return; io07MismatchOpen = true; io07VerifySheetOpen = false; io07MismatchType = ""; io07MismatchQty = ""; io07MismatchLot = String(io07ScanLot || "").trim(); io07MismatchNote = ""; return renderAppScreen(); }
  if (k === "select-mismatch") { io07MismatchType = a.dataset.io07MismatchType || ""; if (io07MismatchType === "LOT" && !io07MismatchLot) io07MismatchLot = String(io07ScanLot || "").trim(); return renderAppScreen(); }
  if (k === "close-mismatch") { io07MismatchOpen = false; io07MismatchType = ""; return renderAppScreen(); }
  if (k === "record-mismatch-observation") { if (io07RecordObservation(req)) return renderAppScreen(); return; }
  if (k === "confirm-allocation") {
    const found = io07ActiveFound(); if (!found || io07VerifyDisabled(found.group, found.allocation)) return;
    io07MarkVerified(found.allocation, String(io07ScanLot || "").trim() ? "SCAN_OR_TYPED_MATCH" : "VISUAL");
    const id = found.allocation.id; io07VerifySheetOpen = false; io07ScanLot = "";
    return io07Rerender(`[data-io07-allocation="${CSS.escape(id)}"]`);
  }
  if (k === "review-handover") {
    if (!io07AllVerified(req) || io07HasMismatch(req)) return;
    req.reviewSourceVersion = req.sourceVersion; io07Recipient = "SUPPLIER"; io07SetState("SCR-039", "READY"); return navigate("SCR-039");
  }
  if (k === "back-to-preparation") { io07VerifySheetOpen = false; io07SetState("SCR-037", req.changed ? "SOURCE_UPDATED" : "READY"); return navigate("SCR-037"); }
  if (k === "back-to-rtv-request") { if (req.closed || req.completed) return navigate("SCR-036"); io07SetState("SCR-037", req.changed ? "SOURCE_UPDATED" : "READY"); return navigate("SCR-037"); }
  if (k === "confirm-handover") {
    if (Number(req.reviewSourceVersion ?? req.sourceVersion) !== Number(req.sourceVersion)) { io07SetState("SCR-039", "SOURCE_CHANGED"); return renderAppScreen(); }
    if (!io07AllVerified(req) || io07HasMismatch(req) || req.queue === "WAITING") return;
    io07CreateResult(req); req.completed = true; req.queue = "CLOSED"; io07SetState("SCR-041", "COMPLETED"); return navigate("SCR-041");
  }
}, true);

// Đi giữa các màn bằng navigate (kể cả nút quay lại) là đi trong luồng: trạng thái hiện tại là "đã biết", không dựng lại yêu cầu.
["SCR-036", "SCR-037", "SCR-039", "SCR-041"].forEach((id) => { onScreenEnter[`UIF-07:${id}`] = () => { io07Expected[id] = stateByScreen[id]; }; });
onEntry["UIF-07:return-task"] = () => { io07ResetUi(); io07SetState("SCR-037", io07Current().changed ? "SOURCE_UPDATED" : "READY"); };

onUnknownHandoff["UIF-07"] = () => {
  const r = io07Current();
  if (r) { r.unknownLocked = true; r.queue = "WAITING"; r.lifecycle = "Đang xác minh kết quả"; }
};
onUnknownResolved["UIF-07"] = ({ operationId, outcome }) => {
  const r = io07Requests.find((x) => x.operationId === operationId) || io07Requests.find((x) => x.unknownLocked) || io07Current();
  if (!r) return;
  r.unknownLocked = false;
  if (outcome === "RECORDED") { r.completed = true; r.closed = true; r.queue = "CLOSED"; r.lifecycle = "Đã bàn giao"; io07Selected = r.id; }
  else { r.queue = "ACTIONABLE"; r.lifecycle = "Cần làm lại"; }
};

flowRenderers["UIF-07"] = Object.assign(flowRenderers["UIF-07"] || {}, {
  "SCR-037": render037BJ07,
  "SCR-039": render039BJ07,
  "SCR-041": render041BJ07,
});

/* ---------- Nguồn dòng cho K5 "Hàng cần xử lý" (SCR-036 chung với BJ-09 / BJ-10) ---------- */

(window.__T7_PROBLEM_SOURCES__ ||= []).push({
  id: "UIF-07",
  rows: () => io07Requests.filter((r) => !r.closed && !r.completed && !r.sourceCancelled).map((r) => {
    const waiting = r.queue === "WAITING" || Boolean(r.unknownLocked);
    const meta = io07StageMeta(r), stage = io07Stage(r);
    const label = r.unknownLocked ? "Đang xác minh kết quả" : r.changed && stage === "ACTIONABLE" ? "Cần kiểm lại" : meta[0];
    const n = (r.groups || []).length;
    return {
      key: `req:${r.id}`, kind: "REQUEST", title: r.id, sub: `${r.supplier} · ${n} mặt hàng`, ref: r.id, expiry: "—", qty: `${n} mặt hàng`,
      badge: { label, tone: ac310Tone(meta[1]) }, job: waiting ? "WAITING" : "RTV", task: `Trả ${r.supplier}`, disabled: waiting,
      open() { io07Open(r.id); return applyEntry("UIF-07", "return-task", true); },
    };
  }),
});
