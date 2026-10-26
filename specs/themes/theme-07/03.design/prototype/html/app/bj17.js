/* BJ-17 — Phục hồi nghiệp vụ có kết quả chưa xác định (UIF-17). Màn: SCR-078 (danh sách chung ở bj16.js), 079, 083.
 *
 * Thiết kế lại T7-P chặng 5 (v5.18.0): hồ sơ nói thẳng thao tác đã ghi vào kho hay chưa ("Xác nhận đã hoàn tất" / "Làm tiếp thao tác" / "Gửi bộ phận hỗ trợ"),
 * xác nhận bằng sheet ở 079 rồi sang 083 thẳng (SCR-080 và SCR-082 không còn ở luồng này). Không tạo thao tác mới, không ghi lại lần hai (resolutionRecord).
 * Cơ chế K3 handoff (`data-k3-action="handoff"`) + bj17RecoveryCase ở đây; khoá nguồn qua móc onUnknownHandoff (bj05/06/07/09/10 đăng ký).
 * Phần chung (khung, danh sách, sheet, seed) dùng hàm cr* của bj16.js.
 */

const BJ17_DONE_AT = "17/09/2026 21:10";
const BJ17_OPENED_AT = "17/09/2026 09:30";
// Bằng chứng mặc định cho ca K3 của BJ nguồn: BJ-05 cho thấy nhánh "chưa ghi → làm tiếp"; còn lại "chưa đủ bằng chứng".
const bj17SourceEvidence = { "UIF-05": "NO_COMMIT" };
// Màn của BJ nguồn mở lại sau khi xác lập (không có = màn đầu của luồng).
const BJ17_OPEN_SCREEN = { "UIF-05": "SCR-026" };
const BJ17_KIND = { "UIF-02": "Nhận hàng", "UIF-03": "Xác lập giá trị", "UIF-05": "Bàn giao hàng", "UIF-06": "Nhận hàng khách trả", "UIF-07": "Trả nhà cung cấp", "UIF-08": "Điều chỉnh kiểm kê", "UIF-09": "Đổi tình trạng", "UIF-10": "Tiêu hủy", "UIF-11": "Sửa sai", "UIF-12": "Khởi tạo tồn", "UIF-13": "Điều chỉnh giá trị", "UIF-14": "Công bố giá vốn", "UIF-16": "Chuyển hồ sơ", "CAP-01": "Chính sách tồn" };
const BJ17_SOURCE = { "UIF-02": "Nhận hàng", "UIF-03": "Xác lập giá trị nhập", "UIF-05": "Lấy hàng & bàn giao", "UIF-06": "Hàng khách trả", "UIF-07": "Trả nhà cung cấp", "UIF-08": "Kiểm kê kho", "UIF-09": "Tình trạng hàng", "UIF-10": "Tiêu hủy hàng", "UIF-11": "Hủy & sửa sai", "UIF-12": "Khởi tạo tồn đầu kỳ", "UIF-13": "Điều chỉnh giá trị hàng nhập", "UIF-14": "Giá vốn", "UIF-16": "Đối soát sai lệch", "CAP-01": "Chính sách tồn" };

/* ---------- Fixture ---------- */

function bj17InitialCases() {
  const base = { sourceFlow: "UIF-17", fixture: true, evidenceVersion: 1, planEvidenceVersion: null, resolutionRecord: null, status: "OPEN", result: "", closedAt: "", handedTo: "", sentAt: "" };
  return [
    { ...base, id: "REC-UNKNOWN-01", operation: "IO-260906-031", kind: "Tiêu hủy", doc: "TH-260906-02", scope: "Găng tay khám Nitrile · 5 hộp", evidence: "COMMITTED", signal: "Tiêu hủy — chưa rõ kết quả", openedAt: "17/09/2026 07:05" },
    { ...base, id: "REC-UNKNOWN-02", operation: "IO-260906-044", kind: "Bàn giao hàng", doc: "SO-260827-21", scope: "Nobivac DHPPi · 2 hộp", evidence: "NO_COMMIT", signal: "Bàn giao — chưa rõ kết quả", openedAt: "17/09/2026 07:40" },
    { ...base, id: "REC-UNKNOWN-03", operation: "IO-260906-052", kind: "Nhận hàng", doc: "PN-260906-15", scope: "1 phiếu nhận hàng", evidence: "INSUFFICIENT", signal: "Nhận hàng — chưa rõ kết quả", openedAt: "17/09/2026 08:10" },
  ];
}

const cr17Cases = bj17InitialCases();
let cr17SelectedId = "REC-UNKNOWN-01";
const bj17Num = (v) => Number(v ?? 0);
const bj17Same = (a, b) => String(a ?? "") === String(b ?? "");
function cr17Current() { return cr17Cases.find((x) => x.id === cr17SelectedId) || cr17Cases[0]; }
function cr17Status(c) { return c.status === "CLOSED" || c.status === "LINKED" ? c.status : c.status === "WAITING" ? "WAITING" : "OPEN"; }

// Mỗi loại hồ sơ nói gì (plan 0.4 điểm 8, ba dòng cuối): trả cùng dạng với cr16RouteView.
function cr17RouteView(c) {
  const nm = c.kind, act = (key) => `data-bj17-action="${key}"`;
  const write = { COMMITTED: "Đã có", NO_COMMIT: "Chưa có", INSUFFICIENT: "Chưa rõ" }[c.evidence];
  const third = { COMMITTED: "Vẫn đang chờ kết quả", NO_COMMIT: "Chưa có phần ghi dở", INSUFFICIENT: "Chưa rõ" }[c.evidence];
  const compare = [["Yêu cầu", "Đã được tiếp nhận"], ["Ghi vào kho", write], [nm, third]];
  const handed = c.status === "WAITING" ? { tone: "info", title: "Đã gửi bộ phận hỗ trợ", desc: "Hệ thống chưa đoán kết quả. Phạm vi tiếp tục được bảo vệ và người có trách nhiệm đã nhận hồ sơ." } : null;
  if (c.evidence === "COMMITTED") return { conclusion: `${nm} đã ghi vào kho`, sentence: "Thao tác đã ghi vào kho. Chỉ cần xác nhận kết quả; không ghi lại lần hai.", tone: "info", compare, primary: { label: "Xác nhận đã hoàn tất", attr: act("confirm-done") } };
  if (c.evidence === "NO_COMMIT") return { conclusion: `${nm} chưa ghi vào kho`, sentence: "Thao tác chưa ghi vào kho và không có phần ghi dở. Có thể làm tiếp đúng thao tác này.", tone: "info", compare, primary: { label: "Làm tiếp thao tác", attr: act("continue") } };
  const v = { conclusion: "Chưa biết đã ghi hay chưa", sentence: "Chưa biết thao tác đã ghi vào kho hay chưa. Giữ nguyên, không làm lại; cần bộ phận hỗ trợ kiểm tra.", tone: "warning", compare, primary: { label: "Gửi bộ phận hỗ trợ", attr: act("escalate") } };
  return handed ? { ...v, primary: null, banner: handed } : v;
}

/* ---------- K3 của các BJ khác ---------- */

function bj17RecoveryCase({ sourceFlow, operation, scope, evidence = "INSUFFICIENT" } = {}) {
  const op = operation || `${sourceFlow}-UNKNOWN`;
  // Một thao tác một hồ sơ (UC-16 BR-01, UC-17 BR-02): tra theo đúng mã thao tác, không theo luồng đã chuyển sang.
  let c = cr17Cases.find((x) => x.operation === op);
  if (!c) {
    const kind = BJ17_KIND[sourceFlow] || "Thao tác";
    c = {
      id: `REC-${String(sourceFlow || "").replace("UIF-", "")}-${String(op).replace(/[^A-Za-z0-9]/g, "").slice(-12)}`,
      operation: op, kind, doc: op, scope: scope || "Phạm vi của lần xử lý hiện tại", evidence, signal: `${kind} — chưa rõ kết quả`, openedAt: BJ17_OPENED_AT,
      sourceFlow, evidenceVersion: 1, planEvidenceVersion: null, resolutionRecord: null, status: "OPEN", result: "", closedAt: "", handedTo: "", sentAt: "",
    };
    cr17Cases.unshift(c);
  }
  return c;
}
function bj17HandoffUnknown(meta) {
  onUnknownHandoff[meta.sourceFlow]?.();
  const c = bj17RecoveryCase({ ...meta, evidence: meta.evidence || bj17SourceEvidence[meta.sourceFlow] || "INSUFFICIENT" });
  if (meta.sourceFlow !== "UIF-17") c.sourceFlow = meta.sourceFlow;
  cr17SelectedId = c.id; crSheet = null;
  const state = cr079StateFor17(c);
  crSetState("SCR-079", state);
  return crSwitchFlow("UIF-17", "SCR-079", state);
}

/* ---------- SCR-079 · Bằng chứng kết quả (BJ-17) ---------- */

function render079BJ17(state) {
  crSeed("UIF-17", "SCR-079", state);
  const title = "Bằng chứng kết quả";
  if (state === "PERMISSION_DENIED") return crDenied(title);
  if (state === "LOADING") return crLoading(title);
  const c = cr17Current(), v = cr17RouteView(c), subtitle = `${c.id} · ${c.scope}`;
  const stale = state === "CONFLICT" ? k1Stale({ title: "Kết luận đã thay đổi", description: "Có bằng chứng mới. Xem lại kết luận trước khi làm tiếp.", actionLabel: "Tải lại", actionAttr: 'data-bj17-action="reload"' }) : "";
  const note = `<p class="ac310-note">Không tạo thao tác mới, không ghi lại lần hai.</p>`;
  const main = `${stale}${crConclusion(v)}${crCompare(v.compare)}${note}`;
  return crShell({ title, subtitle, body: `${k7Split({ main, aside: crAside(c), asideWebOnly: true })}${stale ? "" : crSheetHtml(c)}`, actions: v.primary && !stale ? primaryFooter(v.primary.label, v.primary.attr) : "" });
}

/* ---------- SCR-083 · Kết quả xác minh (BJ-17) ---------- */

function bj17Complete(c, mode) {
  c.result = mode;
  // Cả "Xác nhận đã hoàn tất" và "Làm tiếp thao tác" kết thúc bằng thao tác đã ghi; NOT_RECORDED chưa có lối nào dẫn tới (BJ nguồn đã hỗ trợ sẵn).
  if (c.sourceFlow !== "UIF-17") onUnknownResolved[c.sourceFlow]?.({ operationId: c.operation, outcome: "RECORDED" });
  c.resolutionRecord = { operationId: c.operation, scope: c.scope, evidenceVersion: c.evidenceVersion, newOperationCreated: false, duplicateEffect: false, mode };
  c.status = "CLOSED"; c.closedAt = BJ17_DONE_AT;
}
function render083BJ17(state) {
  crSeed("UIF-17", "SCR-083", state);
  const title = "Kết quả xác minh", c = cr17Current(), listAttr = 'data-bj17-action="to-list"';
  if (state === "PERMISSION_DENIED") return crDenied(title);
  if (state === "PROCESSING") return crLoading(title, ["heading", "card", "row"]);
  if (state === "UNKNOWN") {
    return k3Unknown({ title, operation: "Chuyển hồ sơ", scope: `${c.kind} ${c.doc}`, ref: c.id, sentAt: BJ16_SENT_AT, sourceFlow: "UIF-17", exitAttr: crExit().attr, handoff: { operation: c.operation, scope: c.scope } });
  }
  if (state === "ESCALATED") {
    const facts = [["Nghiệp vụ", `${c.kind} ${c.doc}`], ["Người nhận", CR_SUPPORT], ["Phạm vi", "Tiếp tục được bảo vệ"], ["Gửi lúc", c.sentAt || BJ16_SENT_AT]];
    return k4Result({ screenTitle: title, kind: "warning", title: "Chưa xác định — đã chuyển xử lý", description: "Hệ thống chưa đoán kết quả. Phạm vi tiếp tục được bảo vệ và người có trách nhiệm đã nhận hồ sơ.", facts, next: crResultNext(listAttr) });
  }
  const facts = [["Nghiệp vụ", `${c.kind} ${c.doc}`], ["Kết quả", c.result === "CONTINUED" ? "Đã làm tiếp, đã ghi" : "Đã hoàn tất"], ...(c.sourceFlow !== "UIF-17" ? [["Từ", BJ17_SOURCE[c.sourceFlow] || c.sourceFlow]] : [])];
  // Vào từ màn K3 của BJ khác: bước tiếp là mở lại đúng thao tác ở BJ đó (đã được onUnknownResolved cập nhật).
  const next = c.sourceFlow !== "UIF-17" ? [{ ...crExit() }, { label: `Mở ${c.kind} ${c.doc}`, attr: 'data-bj17-action="open-source"', primary: true }] : crResultNext(listAttr);
  return k4Result({ screenTitle: title, title: "Đã xác lập kết quả nghiệp vụ", description: "Kết quả chính thức đã được ghi cho đúng nghiệp vụ; không tạo nghiệp vụ mới hoặc ghi tác động trùng.", facts, next });
}

flowRenderers["UIF-17"] = Object.assign(flowRenderers["UIF-17"] || {}, {
  "SCR-078": render078Recon,
  "SCR-079": render079BJ17,
  "SCR-083": render083BJ17,
});

/* ---------- Sự kiện ---------- */

// Xác nhận trong sheet của 079: kiểm resolutionRecord (không tạo thao tác mới, không ghi trùng) rồi sang 083.
function bj17ConfirmSheet(kind, c) {
  const mode = kind === "confirm-done" ? "COMMITTED" : "CONTINUED";
  // Bản ghi lấy từ lúc mở sheet (crOpenSheet chụp operation / scope / bằng chứng), so với hồ sơ lúc bấm: khác → 079 báo "Kết luận đã thay đổi".
  const plan = c.planRecord || { operationId: c.operation, scope: c.scope };
  const r = { operationId: plan.operationId, scope: plan.scope, evidenceVersion: c.planEvidenceVersion, newOperationCreated: false, duplicateEffect: false, mode };
  if (!bj17Same(r.operationId, c.operation) || !bj17Same(r.scope, c.scope) || bj17Num(r.evidenceVersion) !== bj17Num(c.evidenceVersion) || r.newOperationCreated || r.duplicateEffect) return crStale();
  c.resolutionRecord = r;
  bj17Complete(c, mode);
  return crGo("UIF-17", "SCR-083", "COMPLETED");
}

document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-17") return;
  const a = event.target.closest?.("[data-bj17-action]"); if (!a || a.disabled) return;
  event.preventDefault(); event.stopPropagation();
  const k = a.dataset.bj17Action, c = cr17Current();
  if (k === "confirm-done") return crOpenSheet("confirm-done", '[data-bj17-action="confirm-done"]');
  if (k === "continue") return crOpenSheet("continue", '[data-bj17-action="continue"]');
  if (k === "escalate") { crHand(c, CR_SUPPORT); return crGo("UIF-17", "SCR-083", "ESCALATED"); }
  if (k === "to-list") return crToList();
  if (k === "open-source") return crSwitchFlow(c.sourceFlow, BJ17_OPEN_SCREEN[c.sourceFlow] || flowCatalog.find((f) => f.id === c.sourceFlow).screens[0], "READY");
  if (k === "reload") return crReload();
}, true);

/* K3 handoff: mọi luồng (nút nằm ở màn BJ khác) — không kiểm activeFlowId */
document.addEventListener("click", (event) => {
  const a = event.target.closest('[data-k3-action="handoff"]'); if (!a || a.disabled) return;
  event.preventDefault(); event.stopPropagation();
  return bj17HandoffUnknown({ sourceFlow: a.dataset.sourceFlow, operation: a.dataset.operation, scope: a.dataset.scope });
}, true);

onEntry["UIF-17:unknown-context"] = () => crSetState("SCR-079", cr079StateFor17(cr17Current()));
if (activeFlowId === "UIF-17" && !requestedScreen && onEntry[`UIF-17:${entryMode}`]) onEntry[`UIF-17:${entryMode}`]();

Object.assign(window.__VET45_QA__, {
  bumpCR17Evidence() { const c = cr17Current(); c.evidenceVersion = Number(c.evidenceVersion || 0) + 1; return c.evidenceVersion; },
  getBJ17() { const c = cr17Current(); return { id: c.id, operation: c.operation, evidenceVersion: c.evidenceVersion, record: c.resolutionRecord }; },
});
