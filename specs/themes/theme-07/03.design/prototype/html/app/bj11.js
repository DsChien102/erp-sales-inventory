/* BJ-11 — Hủy và sửa sai nghiệp vụ kho (UIF-11). Màn: SCR-048, 049, 050, 051, 053 (SCR-052 đã gộp vào SCR-050 từ v5.17.0).
 *
 * Thiết kế lại T7-P chặng 5 (v5.17.0): danh sách phiếu theo K6 (tìm mã phiếu / sản phẩm), chi tiết nói bằng một câu phiếu này hủy được hay
 * phải sửa, hủy là sheet có lý do ngay ở chi tiết, sửa sai một màn (cách sửa + số đúng + lý do + "Sau khi sửa"), duyệt theo K2 đúng yêu cầu
 * đang chọn (chủ cửa hàng thấy tiền, chủ lập vẫn tự duyệt), kết quả theo K4 / K3. Vào từ hồ sơ đối soát (BJ-16) và quay về đúng hồ sơ.
 * Dữ liệu là hai mảng: cr11Operations (phiếu kho) và cr11Requests (yêu cầu sửa sai). Nhập số không dựng lại màn (giữ focus).
 * Dùng từ khuôn: K1, K2 (k2Decision, k2Pending, k2Attention, k2RejectSheet, nguồn "Chờ duyệt"), K3, K4, K6, K7, dsChoiceRow.
 * Fixture chung chặng 5: plan T7-P-bj11-sua-sai.md mục 3 (sản phẩm / lô khớp BJ-01…BJ-10, BJ-08).
 */

const BJ11_STAFF = "Nguyễn Văn An";
const BJ11_OWNER = "Chủ cửa hàng";
const BJ11_SENT_AT = "17/09/2026 20:30";
const BJ11_DECIDED_AT = "17/09/2026 20:40";
const BJ11_CANCELLED_AT = "17/09/2026 20:20";
const BJ11_TODAY = "17/09/2026";
const BJ11_OPEN_PERIOD = "09/2026";
const BJ11_STRATEGIES = [
  ["DELTA", "Sửa phần sai", "Giữ phần đúng, chỉ ghi thêm phần chênh."],
  ["FULL", "Hoàn nguyên và ghi lại đúng", "Dùng khi sai cả phiếu (nhầm sản phẩm, nhầm lô): hoàn nguyên rồi ghi lại."],
];
const BJ11_STATUS = {
  CANCEL: ["Có thể hủy", "Info"], CORRECT: ["Có thể sửa", "Info"], PENDING: ["Chờ duyệt sửa sai", "Warning"],
  UNKNOWN: ["Đang xác minh", "Warning"], RECORDED: ["Đã ghi", "Success"], HANDOVER: ["Đã giao khách", "Warning"], CANCELLED: ["Đã hủy", "Neutral"],
};
const BJ11_FILTERS = {
  ALL: () => true,
  CANCEL: (op) => bj11Kind(op) === "CANCEL",
  CORRECT: (op) => bj11Kind(op) === "CORRECT",
  WAITING: (op) => ["PENDING", "UNKNOWN"].includes(bj11Kind(op)),
};

/* ---------- Fixture chung chặng 5 ---------- */

// sign: chiều tác động của phiếu lên tồn (chỉ phiếu nhận hàng sửa được trong prototype). invoiceQty: số trên chứng từ (hồ sơ đối soát điền sẵn).
function bj11InitialOps() {
  return [
    { id: "IO-260906-022", type: "Đổi tình trạng", docCode: "ST-260906-04", docDate: "06/09/2026", product: "Amox 500", lot: "AM2505", uom: "hộp", qty: 2, route: "CANCEL", period: "09/2026", by: BJ11_STAFF },
    { id: "IO-260904-021", type: "Nhận hàng", docCode: "PN-260904-08", docDate: "04/09/2026", product: "Amox 500", lot: "", uom: "hộp", qty: 20, invoiceQty: 18, unitCost: 42000, stock: 46, sign: 1, route: "CORRECT", period: "09/2026", by: BJ11_STAFF },
    { id: "IO-260901-014", type: "Nhận hàng", docCode: "PN-260901-07", docDate: "01/09/2026", product: "Dầu sát khuẩn", lot: "L2406-T", uom: "chai", qty: 6, invoiceQty: 4, stock: 2, sign: 1, route: "CORRECT", period: "09/2026", by: "Trần Thị Bình" },
    { id: "IO-260906-031", type: "Tiêu hủy", docCode: "TH-260906-02", docDate: "06/09/2026", product: "Găng tay khám Nitrile", lot: "", uom: "hộp", qty: 5, route: "UNKNOWN", period: "09/2026", by: BJ11_STAFF },
    { id: "IO-260902-005", type: "Xuất bán", docCode: "SO-260902-19", docDate: "02/09/2026", product: "Oxytetracycline LA", lot: "", uom: "chai", qty: 3, route: "HANDOVER", period: "09/2026", by: BJ11_STAFF },
    { id: "IO-260903-017", type: "Nhận hàng", docCode: "PN-260903-05", docDate: "03/09/2026", product: "Tylosin 20%", lot: "TY2511", uom: "lọ", qty: 5, invoiceQty: 3, unitCost: 85000, stock: 3, sign: 1, route: "CORRECT", period: "09/2026", by: BJ11_STAFF, dependency: { verb: "bán", qty: 3 } },
  ].map((op) => ({ cancelled: null, correctedQty: null, corrections: [], ...op }));
}
function bj11InitialRequests() {
  return [{ id: "SS-260915-01", opId: "IO-260901-014", strategy: "DELTA", from: 6, to: 4, reason: "Phiếu giao chỉ có 4 chai", by: BJ11_STAFF, sentAt: "15/09/2026 16:45", status: "PENDING", caseId: "" }];
}

const cr11Operations = bj11InitialOps();
const cr11Requests = bj11InitialRequests();
let cr11Seq = 1, cr11RecordSeq = 1;
let cr11Filter = "ALL";
let cr11Query = "";
let cr11SelectedId = "IO-260904-021";
let cr11SelectedRequestId = "SS-260915-01";
let cr11Return = null;            // nơi đã mở màn sửa sai này: { kind: "case", id: mã hồ sơ BJ-16 } | { kind: "movement", id: mã biến động thẻ kho BJ-15 } | null (không từ nơi nào)
const cr11ReturnId = (kind) => (cr11Return?.kind === kind ? cr11Return.id : "");
let bj11Draft = { strategy: "DELTA", qty: "", reason: "" };
let bj11NoPeriod = false;         // PERIOD_POLICY_VIOLATION: không có kỳ mở
let bj11Dialog = null;            // "cancel" | "reject"
let bj11CancelReason = "", bj11RejectReason = "", bj11Opener = "";

const bj11Attr = (v) => escapeAttribute(String(v ?? ""));
const bj11Num = (v) => Number(String(v ?? "").replace(",", ".")) || 0;
const bj11Filled = (v) => String(v ?? "").trim() !== "";
const bj11Valid = (v) => bj11Filled(v) && Number.isFinite(Number(String(v).replace(",", "."))) && Number(String(v).replace(",", ".")) >= 0;
function bj11CanDecide() { return ["approver", "owner"].includes(currentActor()); }
function bj11ActorName() { return bj11CanDecide() ? BJ11_OWNER : BJ11_STAFF; }
// Mọi chuỗi tiền dựng qua hàm này: người không xem được tiền nhận chuỗi rỗng (không có phần tử nào mang số tiền trong DOM).
function bj11Money(n) { return !t7ShowMoney() || n == null ? "" : t7FmtMoney(n, true); }

function cr11Current() { return cr11Operations.find((x) => x.id === cr11SelectedId) || cr11Operations[1]; }
function cr11Request(id = cr11SelectedRequestId) { return cr11Requests.find((r) => r.id === id) || null; }
function bj11OpOf(r) { return cr11Operations.find((o) => o.id === r.opId); }
function bj11PendingFor(op) { return cr11Requests.find((r) => r.opId === op.id && r.status === "PENDING") || null; }
function bj11Kind(op) { return op.cancelled ? "CANCELLED" : bj11PendingFor(op) ? "PENDING" : op.route; }
function cr11StateFor(op) {
  if (op.cancelled) return "TERMINAL";
  if (bj11PendingFor(op)) return "PENDING_APPROVAL";
  if (op.route === "CANCEL") return "CANCELABLE";
  if (op.route === "UNKNOWN") return "UNKNOWN";
  if (op.route === "RECORDED") return "RECORDED";
  if (op.route === "HANDOVER") return "BLOCKED_PHYSICAL_HANDOVER";
  return "CORRECTABLE";
}
function bj11Base(op) { return op.correctedQty ?? op.qty; }
// Tiêu đề dòng danh sách dùng gạch nối không ngắt (U+2011) để mã phiếu không bị cắt đôi khi xuống dòng.
function bj11Title(op) { return `${op.type} ${op.docCode}`; }
function bj11LotText(op) { return op.lot ? `Lô ${op.lot}` : "Không theo lô"; }
function bj11Sub(op) { return `${op.product} · ${bj11LotText(op)}`; }
function bj11StrategyLabel(key) { return (BJ11_STRATEGIES.find((s) => s[0] === key) || [null, ""])[1]; }
function bj11Written(op) {
  if (op.route === "CANCEL") return "Chưa ghi";
  if (op.route === "UNKNOWN") return "Chưa xác định";
  return `${op.sign === 1 ? "+" : "−"}${t7Qty(op.qty, op.uom)} · ${op.docDate}`;
}
function bj11Signed(n, uom) { return `${n < 0 ? "−" : "+"}${t7Qty(Math.abs(n), uom)}`; }
function bj11PeriodText(op) { return op.period !== BJ11_OPEN_PERIOD ? `${BJ11_OPEN_PERIOD} · kỳ gốc ${op.period} đã khoá` : BJ11_OPEN_PERIOD; }
function bj11StockAfter(op, to) { return (op.stock ?? 0) + (to - bj11Base(op)) * (op.sign || 1); }
// Giá trị sửa = phần chênh × giá vốn; phiếu không có giá vốn thì không có giá trị.
function bj11Value(op, from, to) { return op.unitCost ? (to - from) * op.unitCost * (op.sign || 1) : null; }

/* ---------- Dựng lại fixture khi trạng thái đặt từ ngoài ---------- */

function bj11ResetDraft(op, fromCase = false) {
  bj11Draft = { strategy: "DELTA", qty: fromCase && op.invoiceQty != null ? String(op.invoiceQty) : "", reason: "" };
}
function bj11ResetUi() { bj11Dialog = null; bj11CancelReason = ""; bj11RejectReason = ""; bj11Opener = ""; }
function bj11Restore() {
  cr11Operations.splice(0, cr11Operations.length, ...bj11InitialOps());
  cr11Requests.splice(0, cr11Requests.length, ...bj11InitialRequests());
  cr11Seq = 1; cr11RecordSeq = 1; cr11Filter = "ALL"; cr11Query = ""; cr11SelectedId = "IO-260904-021"; cr11SelectedRequestId = "SS-260915-01";
  cr11Return = null; bj11NoPeriod = false; bj11ResetUi(); bj11ResetDraft(cr11Current());
}
const bj11Expected = {};
function bj11SetState(screenId, state) { stateByScreen[screenId] = state; bj11Expected[screenId] = state; }
function bj11Op(id) { return cr11Operations.find((o) => o.id === id); }

// Hệ thống: tạo yêu cầu, duyệt, từ chối, hủy.
function bj11Submit(op, d) {
  const r = { id: `SS-260917-${String(cr11Seq++).padStart(2, "0")}`, opId: op.id, strategy: d.strategy, from: bj11Base(op), to: bj11Num(d.qty), reason: d.reason.trim(), by: bj11ActorName(), sentAt: BJ11_SENT_AT, status: "PENDING", caseId: cr11ReturnId("case"), movementId: cr11ReturnId("movement") };
  cr11Requests.unshift(r); cr11SelectedRequestId = r.id;
  return r;
}
// Duyệt không tự ghi: hệ thống kiểm lại điều kiện rồi mới ghi. Trả "COMPLETED" hoặc "BLOCKED".
function bj11Approve(r) {
  const op = bj11OpOf(r);
  if (op.dependency && r.to < r.from) return "BLOCKED";
  r.status = "COMPLETED"; r.recordId = `IO-260917-${String(cr11RecordSeq++).padStart(3, "0")}`; r.decidedAt = BJ11_DECIDED_AT; r.approver = BJ11_OWNER;
  op.correctedQty = r.to; op.stock = (op.stock ?? 0) + (r.to - r.from) * (op.sign || 1); op.corrections.push({ code: r.recordId, date: BJ11_TODAY });
  // Sửa sai là phiếu liên kết ghi thêm phần chênh vào kho: ghi vào sổ chung (phiếu của hàng không có ở BJ-01 thì bỏ qua).
  if (r.to !== r.from && op.sign) t7Ledger.post({ key: `UIF-11:${r.id}`, productId: op.product, lot: op.lot, kind: "Sửa sai", doc: r.id, delta: (r.to - r.from) * op.sign, sourceFlow: "UIF-11", opId: op.id, note: `Sửa ${op.type} ${op.docCode}` });
  return "COMPLETED";
}
function bj11Reject(r, reason) { r.status = "REJECTED"; r.rejectReason = reason; r.decidedAt = BJ11_DECIDED_AT; }
function bj11CancelOp(op, reason) { op.cancelled = { reason, at: BJ11_CANCELLED_AT }; }

function bj11Seed(screenId, state) {
  if (bj11Expected[screenId] === state) return;
  Object.keys(bj11Expected).forEach((k) => delete bj11Expected[k]);
  bj11Expected[screenId] = state;
  bj11Restore();
  if (screenId === "SCR-049") {
    const byState = { UNKNOWN: "IO-260906-031", BLOCKED_PHYSICAL_HANDOVER: "IO-260902-005", PENDING_APPROVAL: "IO-260901-014", CANCELABLE: "IO-260906-022" };
    cr11SelectedId = byState[state] || "IO-260904-021";
    if (state === "TERMINAL") { cr11SelectedId = "IO-260906-022"; bj11CancelOp(cr11Current(), "Gửi nhầm"); }
    return;
  }
  if (screenId === "SCR-050") {
    cr11SelectedId = state === "DEPENDENCY_BLOCKED" ? "IO-260903-017" : state === "CONFLICT" ? "IO-260901-014" : "IO-260904-021";
    bj11ResetDraft(cr11Current());
    if (["SOURCE_VERSION_STALE", "CONFLICT"].includes(state)) bj11Draft = { strategy: "DELTA", qty: String(cr11Current().invoiceQty), reason: "Chứng từ nhà cung cấp ghi số khác" };
    if (state === "PERIOD_POLICY_VIOLATION") bj11NoPeriod = true;
    return;
  }
  if (screenId === "SCR-051") { cr11SelectedRequestId = "SS-260915-01"; return; }
  if (screenId === "SCR-053") {
    if (state === "CANCELLED") { cr11SelectedId = "IO-260906-022"; bj11CancelOp(cr11Current(), "Gửi nhầm"); return; }
    if (state === "COMPLETED") {
      cr11SelectedId = "IO-260904-021"; const op = cr11Current();
      bj11Submit(op, { strategy: "DELTA", qty: String(op.invoiceQty), reason: "Hóa đơn nhà cung cấp ghi 18 hộp" }); bj11Approve(cr11Request());
      return;
    }
    cr11SelectedRequestId = "SS-260915-01"; cr11SelectedId = "IO-260901-014";
    if (state === "REJECTED") bj11Reject(cr11Request(), "Thiếu chứng từ nhận hàng");
  }
}
bj11Restore();

/* ---------- Khung dùng chung ---------- */

function bj11Shell(opts) { return appShell({ extraClass: "k7-wide", ...opts }); }
function bj11Denied(title, back = false) { return bj11Shell({ title, body: k1Denied({ what: "hủy hoặc sửa sai", next: "Liên hệ chủ cửa hàng để được cấp quyền.", exitAttr: k1ExitAttr("SCR-048") }), centered: true, back }); }
function bj11Loading(title, blocks, back = false) { return bj11Shell({ title, body: k1Loading({ blocks }), centered: true, back }); }
function bj11ToList() { return { label: "Về danh sách", attr: 'data-bj11-action="to-list"' }; }
function bj11ExitFooter() { return k4Footer([{ ...bj11ToList(), primary: true }]); }
function bj11NoRequest(title) { return bj11Shell({ title, body: k1Locked({ title: "Không có yêu cầu sửa sai", description: "Mở lại từ danh sách chờ duyệt." }), back: false, actions: bj11ExitFooter() }); }
function bj11Original(op) {
  const last = op.corrections.at(-1);
  return ac310KeyValueSurface("Phiếu gốc", [["Mã phiếu", op.docCode], ["Mã nghiệp vụ", op.id], ["Số lượng", t7Qty(op.qty, op.uom)], ["Ghi vào kho", bj11Written(op)], ["Sửa sai trước đó", last ? `${last.code} · ${last.date}` : "Chưa có"]]);
}
function bj11Summary(op) {
  return ac310KeyValueSurface("Tóm tắt", [["Sản phẩm", op.product], ["Lô", bj11LotText(op)], ["Ngày", op.docDate], ["Người ghi", op.by]]);
}

/* ---------- SCR-048 · Hủy & sửa sai (K6) ---------- */

function render048BJ11(state) {
  if (activeFlowId !== "UIF-11") return renderGeneric(screens.find((s) => s.id === "SCR-048"), state);
  const title = "Hủy & sửa sai", subtitle = "Phiếu kho gần đây";
  bj11Seed("SCR-048", state);
  if (state === "PERMISSION_DENIED") return bj11Denied(title);
  if (state === "LOADING") return bj11Shell({ title, subtitle, body: k1Loading({ blocks: ["search", "row", "row", "row"] }), back: false });
  const all = state === "EMPTY" ? [] : cr11Operations;
  const text = (op) => ioNormalizeSearch(`${op.docCode} ${op.type} ${op.product} ${op.lot} ${op.id}`);
  const q = ioNormalizeSearch(cr11Query);
  const rows = state === "FILTER_EMPTY" ? [] : all.filter((op) => BJ11_FILTERS[cr11Filter](op) && (!q || text(op).includes(q))).map((op) => {
    const [label, tone] = BJ11_STATUS[bj11Kind(op)];
    return { id: op.id, title: bj11Title(op).replace(/-/g, "\u2011"), subtitle: `${op.product} · ${t7Qty(op.qty, op.uom)} · ${op.docDate}`, status: { label, tone }, docCode: op.docCode, typeName: op.type, product: op.product, qtyText: t7Qty(op.qty, op.uom), docDate: op.docDate, statusHtml: ds24Badge(label, tone), searchText: text(op) };
  });
  const count = (key) => all.filter(BJ11_FILTERS[key]).length;
  const items = [["ALL", "Tất cả"], ["CANCEL", "Hủy được"], ["CORRECT", "Sửa được"], ["WAITING", "Đang chờ"]].map(([k, l]) => [k, l, count(k)]);
  const columns = [{ key: "docCode", label: "Phiếu", mono: true }, { key: "typeName", label: "Loại" }, { key: "product", label: "Sản phẩm" }, { key: "qtyText", label: "Số lượng", align: "end", mono: true }, { key: "docDate", label: "Ngày", mono: true }, { key: "statusHtml", label: "Tình trạng", html: true }];
  const body = k6TaskList({
    search: { value: cr11Query, attr: "data-bj11-search", placeholder: "Tìm mã phiếu hoặc sản phẩm" },
    filters: { items, selected: cr11Filter, attrName: "data-bj11-filter" },
    columns, rows, total: all.length,
    rowAttr: (r) => `data-bj11-row="${bj11Attr(r.id)}" data-bj11-search-text="${bj11Attr(r.searchText)}"`,
    rowOpen: true,
    empty: { title: "Chưa có nghiệp vụ cần kiểm soát", description: "Các nghiệp vụ đủ điều kiện sẽ xuất hiện tại đây." },
    filterEmpty: { title: "Không có nghiệp vụ phù hợp", description: "Thử đổi bộ lọc hoặc từ khóa tìm kiếm.", actionLabel: "Xem tất cả", actionAttr: 'data-bj11-action="clear-filter"' },
    filterEmptyAttr: "data-bj11-filter-empty",
  });
  return bj11Shell({ title, subtitle, body, back: false, centered: state === "EMPTY" });
}

/* ---------- SCR-049 · Chi tiết phiếu kho ---------- */

// Khối "Việc tiếp theo": một câu theo trường hợp + nút ở chân. UNKNOWN dựng cả màn K3 ở render049BJ11.
function bj11NextBlock(op, kind) {
  const section = (inner) => `<section class="k5-next">${ds24SectionTitle("Việc tiếp theo")}${inner}</section>`;
  const note = (t) => `<p class="k5-note">${esc(t)}</p>`;
  if (kind === "CANCELABLE") return { block: section(note("Nghiệp vụ chưa thực thi nên có thể hủy mà không tạo biến động tồn kho.")), actions: primaryFooter("Hủy yêu cầu", 'data-bj11-action="cancel-open"', false, "danger") };
  if (kind === "CORRECTABLE") return { block: section(note("Phiếu đã ghi vào kho nên không sửa thẳng. Sửa sai sẽ ghi thêm một phiếu liên kết; phiếu này giữ nguyên.")), actions: primaryFooter("Sửa sai", 'data-bj11-action="correct"') };
  if (kind === "BLOCKED_PHYSICAL_HANDOVER") return { block: section(vBanner("warning", "Hàng đã được bàn giao thực tế", "Khách trả hàng phải qua nghiệp vụ Hàng khách trả; không xử lý bằng sửa sai.")), actions: primaryFooter("Mở hàng khách trả", 'data-bj11-action="to-return"') };
  if (kind === "RECORDED") return { block: section(vBanner("info", "Đã ghi vào kho", "Kết quả đã được xác minh; không cần sửa.")), actions: "" };
  if (kind === "TERMINAL") return { block: section(vBanner("info", "Không còn tác động cần sửa", "Nghiệp vụ đã dừng trước khi thực thi.")), actions: "" };
  const r = bj11PendingFor(op);
  return { block: section(k2Pending({ approver: "chủ cửa hàng", sentAt: r ? r.sentAt : BJ11_SENT_AT })), actions: primaryFooter("Xem yêu cầu", 'data-bj11-action="view-request"') };
}
function render049BJ11(state) {
  if (activeFlowId !== "UIF-11") return renderGeneric(screens.find((s) => s.id === "SCR-049"), state);
  bj11Seed("SCR-049", state);
  const op = cr11Current(), title = bj11Title(op);
  if (state === "PERMISSION_DENIED") return bj11Denied(title, true);
  if (state === "LOADING") return bj11Loading(title, ["heading", "card", "card"], true);
  const kind = state === "READY" ? cr11StateFor(op) : state;
  if (kind === "UNKNOWN") return k3Unknown({ operation: op.type, scope: bj11Sub(op), ref: op.docCode, sentAt: BJ11_SENT_AT, sourceFlow: "UIF-11", exitAttr: k1ExitAttr("SCR-048"), handoff: { operation: op.id, scope: `${bj11Sub(op)} · ${t7Qty(op.qty, op.uom)}` } });
  const next = bj11NextBlock(op, kind);
  const sheet = bj11Dialog === "cancel" ? bj11CancelSheet(op) : "";
  const main = `${next.block}${bj11Original(op)}`;
  return bj11Shell({ title, subtitle: bj11Sub(op), body: `${k7Split({ main, aside: bj11Summary(op), asideWebOnly: true })}${sheet}`, actions: next.actions });
}
function bj11CancelSheet(op) {
  return k2RejectSheet({ open: true, title: `Hủy yêu cầu ${op.docCode}?`, description: "Tồn kho và giá trị không thay đổi.", reason: bj11CancelReason, reasonAttr: "data-bj11-cancel-reason", reasonLabel: "Lý do hủy", placeholder: "Lý do được lưu trong lịch sử kiểm soát.", closeAttr: 'data-bj11-action="dialog-close"', closeLabel: "Quay lại", confirmAttr: 'data-bj11-action="cancel-confirm"', confirmLabel: "Hủy yêu cầu", tone: "danger" });
}

/* ---------- SCR-050 · Sửa sai ---------- */

function bj11Blocker(op, d) {
  if (!bj11Valid(d.qty)) return "Nhập số đúng";
  if (bj11Num(d.qty) === bj11Base(op)) return "Số đúng đang bằng số đã ghi";
  if (!d.reason.trim()) return "Nhập lý do sửa sai";
  return "";
}
// "Sau khi sửa": tồn, kỳ ghi, giá trị (chỉ chủ cửa hàng), và dòng cố định về phiếu gốc.
function bj11AfterBlock(op, d) {
  const rows = [], base = bj11Base(op), ready = bj11Valid(d.qty) && bj11Num(d.qty) !== base, to = bj11Num(d.qty);
  if (ready && op.stock != null) rows.push([`Tồn ${op.product}: ${op.stock} → ${t7Qty(bj11StockAfter(op, to), op.uom)}`, "", "info"]);
  rows.push([`Ghi vào kỳ ${bj11PeriodText(op)}`, "", "info"]);
  const money = ready ? bj11Money(bj11Value(op, base, to)) : "";
  if (money) rows.push([`Giá trị: ${money}`, "", "info"]);
  rows.push(["Phiếu gốc giữ nguyên; app ghi thêm phiếu sửa sai liên kết.", "", "info"]);
  return k2Attention(rows, { title: "Sau khi sửa" });
}
function bj11ReasonField(d, error) {
  const field = icTextarea("Lý do sửa sai", d.reason, "data-bj11-reason", "Mô tả ngắn điều đã sai và căn cứ sửa");
  return error ? field.replace("ic-textarea-field", "ic-textarea-field bj11-field--error").replace("<textarea", '<textarea aria-invalid="true"').replace(/<\/div>$/, `<small class="field-error" role="alert">${esc(error)}</small></div>`) : field;
}
function bj11FormFooter(op, d) {
  const blocker = bj11Blocker(op, d);
  return k4ReasonFooter({ label: "Gửi phê duyệt", attr: 'data-bj11-action="submit"', disabled: Boolean(blocker), reason: blocker });
}
function render050BJ11(state) {
  if (activeFlowId !== "UIF-11") return renderGeneric(screens.find((s) => s.id === "SCR-050"), state);
  const title = "Sửa sai";
  bj11Seed("SCR-050", state);
  if (state === "PERMISSION_DENIED") return bj11Denied(title, true);
  const op = cr11Current(), subtitle = `${bj11Title(op)} · ${op.product}`, d = bj11Draft;
  const toDetail = primaryFooter("Về chi tiết", 'data-bj11-action="to-detail"');
  if (state === "DEPENDENCY_BLOCKED") {
    const dep = op.dependency || { verb: "xuất", qty: 0 };
    return bj11Shell({ title, subtitle, body: k1Locked({ title: "Chưa thể sửa sai", description: `Sau phiếu này đã ${dep.verb} ${t7Qty(dep.qty, op.uom)}; các phiếu ${dep.verb} đó dựa trên số đã nhận. Xử lý nghiệp vụ đó trước.` }), actions: toDetail });
  }
  if (state === "PERIOD_POLICY_VIOLATION") return bj11Shell({ title, subtitle, body: k1Locked({ title: "Chưa có kỳ mở để ghi nhận sửa sai", description: "Cần có kỳ ghi nhận hiện hành hợp lệ trước khi tiếp tục." }), actions: toDetail });
  if (state === "SOURCE_VERSION_STALE") return bj11Shell({ title, subtitle, body: k1Stale({ title: "Nghiệp vụ nguồn đã thay đổi", description: "Hãy quay lại chi tiết để đối chiếu dữ liệu hiện hành trước khi gửi.", actionLabel: "Về chi tiết", actionAttr: 'data-bj11-action="to-detail"' }) });
  if (state === "CONFLICT") return bj11Shell({ title, subtitle, body: k1Stale({ title: "Đã có yêu cầu sửa sai khác", description: "Không tạo yêu cầu sửa sai song song. Mở yêu cầu đang hoạt động để tiếp tục.", actionLabel: "Mở yêu cầu đang chờ", actionAttr: 'data-bj11-action="view-request"' }) });
  const showError = state === "VALIDATION_ERROR", base = bj11Base(op);
  const qtyError = showError ? (!bj11Valid(d.qty) ? "Nhập số đúng" : bj11Num(d.qty) === base ? "Số đúng đang bằng số đã ghi" : "") : "";
  const reasonError = showError && !d.reason.trim() ? "Nhập lý do sửa sai" : "";
  const strategy = `<section class="bj06-section">${ds24SectionTitle("Cách sửa")}<div class="ds-choice-list" role="radiogroup" aria-label="Cách sửa">${BJ11_STRATEGIES.map(([key, label, detail]) => dsChoiceRow({ title: label, subtitle: detail, selected: d.strategy === key, attrs: `data-bj11-strategy="${key}"` })).join("")}</div></section>`;
  const qty = `<div class="k5-qty"><span class="c45-text-style-8">Số đúng <span class="required">*</span></span>${k7EditCell({ value: d.qty, attr: 'data-bj11-qty enterkeyhint="next"', unit: op.uom, error: qtyError, label: "Số đúng" })}<small class="bj11-hint">Đã ghi ${esc(t7Qty(base, op.uom))}</small></div>`;
  const form = `<div class="bj11-form">${strategy}${qty}${bj11ReasonField(d, reasonError)}<div class="bj11-after bj11-after--inline" data-bj11-after>${bj11AfterBlock(op, d)}</div></div>`;
  const short = ac310KeyValueSurface("Phiếu gốc", [["Mã phiếu", op.docCode], ["Số lượng", t7Qty(op.qty, op.uom)], ["Ghi vào kho", bj11Written(op)]]);
  const aside = `<div class="bj11-after" data-bj11-after>${bj11AfterBlock(op, d)}</div>${short}`;
  return bj11Shell({ title, subtitle, body: k7Split({ main: form, aside, asideWebOnly: true }), actions: bj11FormFooter(op, d) });
}

/* ---------- SCR-051 · Duyệt sửa sai (K2) ---------- */

function bj11RejectSheet(showError) {
  const sheet = k2RejectSheet({ open: bj11Dialog === "reject", title: "Từ chối sửa sai", reason: bj11RejectReason, reasonAttr: "data-bj11-reject-reason", closeAttr: 'data-bj11-action="dialog-close"', confirmAttr: 'data-bj11-action="confirm-reject"' });
  return showError ? sheet.replace("</textarea></div>", '</textarea><small class="field-error" role="alert">Nhập lý do từ chối</small></div>') : sheet;
}
function bj11Attention(op, r) {
  const diff = r.to - r.from, rows = [];
  rows.push([`${diff * (op.sign || 1) < 0 ? "Tồn giảm" : "Tồn tăng"} ${t7Qty(Math.abs(diff), op.uom)}`, ""]);
  const money = bj11Money(bj11Value(op, r.from, r.to));
  if (money) rows.push([`Giá trị: ${money}`, ""]);
  if (r.strategy === "FULL") rows.push(["Hoàn nguyên cả phiếu rồi ghi lại", ""]);
  return rows;
}
function render051BJ11(state) {
  if (activeFlowId !== "UIF-11") return renderGeneric(screens.find((s) => s.id === "SCR-051"), state);
  const title = "Duyệt sửa sai";
  bj11Seed("SCR-051", state);
  if (state === "PERMISSION_DENIED") return bj11Denied(title);
  const r = cr11Request();
  if (!r) return bj11NoRequest(title);
  const op = bj11OpOf(r), subtitle = `${bj11Title(op)} · ${op.product}`;
  if (state === "APPROVAL_ALREADY_DECIDED" || (["READY", "VALIDATION_ERROR"].includes(state) && r.status !== "PENDING")) {
    return bj11Shell({ title, subtitle, back: false, body: k1Locked({ title: "Yêu cầu đã có quyết định", description: "Mở kết quả sửa sai để xem trạng thái hiện hành." }), actions: primaryFooter("Xem kết quả", 'data-bj11-action="view-result"') });
  }
  const own = r.by === bj11ActorName();
  if (state === "SELF_APPROVAL_NOT_ALLOWED" || (["READY", "VALIDATION_ERROR"].includes(state) && !bj11CanDecide())) {
    return bj11Shell({ title, subtitle, back: false, body: vBanner("warning", "Bạn không thể tự duyệt yêu cầu này", own || state === "SELF_APPROVAL_NOT_ALLOWED" ? "Chủ cửa hàng sẽ duyệt yêu cầu bạn lập." : "Chỉ chủ cửa hàng duyệt yêu cầu sửa sai."), actions: bj11ExitFooter() });
  }
  const unit = op.uom, locked = bj11PeriodText(op);
  const facts = [["Lý do", r.reason], ["Cách sửa", bj11StrategyLabel(r.strategy)], ["Ghi vào kỳ", locked], ...(r.caseId ? [["Từ hồ sơ đối soát", r.caseId]] : [])];
  const diff = r.to - r.from;
  const detail = ac310KeyValueSurface("Trước và sau", [["Trước", t7Qty(r.from, unit)], ["Sau", t7Qty(r.to, unit)], ["Điều chỉnh", bj11Signed(diff, unit), true]]);
  const decision = k2Decision({ question: `Duyệt sửa ${bj11Title(op)}: ${op.product} từ ${r.from} thành ${t7Qty(r.to, unit)}?`, maker: r.by, sentAt: r.sentAt, attention: bj11Attention(op, r), facts, detail });
  const sheet = bj11RejectSheet(state === "VALIDATION_ERROR");
  const actions = ac310ApprovalFooter('data-bj11-action="reject-open"', 'data-bj11-action="approve"');
  return bj11Shell({ title, subtitle, back: false, body: `${k7Split({ main: decision, aside: bj11Original(op), wideMain: true, asideWebOnly: true })}${sheet}`, actions });
}

/* ---------- SCR-053 · Kết quả sửa sai (K4 / K3) ---------- */

// Lối về nơi đã mở màn sửa sai: hồ sơ đối soát (BJ-16) hoặc thẻ kho (BJ-15); không từ đâu thì null.
function bj11BackToCase() { return cr11ReturnId("case") ? { label: "Về hồ sơ đối soát", attr: 'data-bj11-action="to-case"' } : cr11ReturnId("movement") ? { label: "Về thẻ kho", attr: 'data-bj11-action="to-movement"' } : null; }
function render053BJ11(state) {
  if (activeFlowId !== "UIF-11") return renderGeneric(screens.find((s) => s.id === "SCR-053"), state);
  const title = "Kết quả sửa sai";
  bj11Seed("SCR-053", state);
  if (state === "PERMISSION_DENIED") return bj11Denied(title);
  if (state === "PROCESSING") return bj11Loading(title, ["heading", "card", "row"]);
  const toList = bj11ToList(), toCase = bj11BackToCase();
  if (state === "CANCELLED") {
    const op = cr11Current();
    return k4Result({ screenTitle: title, kind: "warning", title: "Đã hủy yêu cầu", description: "Yêu cầu dừng trước khi thực thi; không phát sinh biến động kho hoặc thay đổi giá trị tồn kho.", facts: [["Nghiệp vụ", bj11Title(op)], ["Tồn kho", "Không thay đổi"], ["Lý do", op.cancelled?.reason || "—"]], next: [{ ...toList, primary: true }] });
  }
  const r = cr11Request();
  if (!r) return bj11NoRequest(title);
  const op = bj11OpOf(r), source = ["Nghiệp vụ gốc", bj11Title(op)];
  // Thao tác chưa rõ là lần ghi sửa sai (mã yêu cầu), không phải phiếu gốc: BJ-17 tra theo mã này.
  if (state === "UNKNOWN") return k3Unknown({ operation: "Ghi sửa sai", scope: bj11Title(op), ref: r.id, sentAt: r.decidedAt || BJ11_DECIDED_AT, sourceFlow: "UIF-11", exitAttr: k1ExitAttr("SCR-048"), handoff: { operation: r.id, scope: `${bj11Title(op)} · ${r.from} → ${t7Qty(r.to, op.uom)}` } });
  if (state === "BLOCKED") return k4Result({ screenTitle: title, kind: "warning", title: "Chưa thể ghi sửa sai", description: "Điều kiện hiện hành không còn phù hợp. Nghiệp vụ gốc chưa bị thay đổi.", facts: [source, ["Tác động mới", "Không có"]], next: [{ ...toList, primary: true }] });
  if (state === "REJECTED") return k4Result({ screenTitle: title, kind: "warning", title: "Yêu cầu không được duyệt", description: "Nghiệp vụ gốc được giữ nguyên và không có tác động tồn kho mới.", facts: [source, ["Tồn kho", "Không thay đổi"], ["Lý do từ chối", r.rejectReason || "—"]], next: [toList, { label: "Sửa lại", attr: 'data-bj11-action="redo"', primary: true }] });
  if (state === "PENDING_APPROVAL") {
    const facts = [source, ["Trước và sau", `${r.from} → ${t7Qty(r.to, op.uom)}`], ["Lý do", r.reason]];
    return bj11Shell({ title, back: false, body: `<div class="k3-column">${k2Pending({ approver: "chủ cửa hàng", sentAt: r.sentAt, facts })}</div>`, actions: k4Footer([{ ...(toCase || toList), primary: true }]) });
  }
  const money = bj11Money(bj11Value(op, r.from, r.to));
  const facts = [source, ["Bản ghi sửa sai", r.recordId || "—"], ["Điều chỉnh", bj11Signed((r.to - r.from) * (op.sign || 1), op.uom)], ...(money ? [["Giá trị", money]] : []), ["Người duyệt", r.approver || BJ11_OWNER], ["Ghi nhận lúc", r.decidedAt || BJ11_DECIDED_AT]];
  return k4Result({ screenTitle: title, title: "Đã hoàn tất sửa sai", description: "Nghiệp vụ gốc được giữ nguyên; bản ghi sửa sai mới đã ghi phần điều chỉnh và liên kết đầy đủ.", facts, next: [toList, toCase ? { ...toCase, primary: true } : bj14ReturnAction() ? { ...bj14ReturnAction(), primary: true } : { label: "Xem tồn kho", attr: 'data-bj11-action="to-stock"', primary: true }] });
}

/* ---------- Sự kiện ---------- */

function bj11Rerender(focusSelector = "") {
  const top = document.querySelector("#app-screen .app-content")?.scrollTop || 0;
  renderAppScreen();
  const content = document.querySelector("#app-screen .app-content"); if (content) content.scrollTop = top;
  if (focusSelector) bj11Focus(focusSelector);
}
// getClientRects: phần tử position:fixed (sheet) có offsetParent = null nhưng vẫn hiển thị.
function bj11Visible(el) { return el.getClientRects().length > 0; }
function bj11Focus(selector) {
  const el = [...document.querySelectorAll(selector)].find(bj11Visible);
  if (el) el.focus({ preventScroll: true });
  return el || null;
}
function bj11Go(screenId, state) { bj11ResetUi(); bj11SetState(screenId, state); return navigate(screenId); }
function bj11ToListNav() { cr11Return = null; return bj11Go("SCR-048", "READY"); }
function bj11OpenDetail(op) { cr11SelectedId = op.id; return bj11Go("SCR-049", cr11StateFor(op)); }
// Một dòng ở danh sách mở đúng bước: yêu cầu đang chờ → chủ cửa hàng duyệt (051), người khác xem (053); còn lại chi tiết.
function bj11OpenRow(id) {
  const op = bj11Op(id); if (!op) return;
  cr11SelectedId = id; cr11Return = null;
  const pending = bj11PendingFor(op);
  if (pending) { cr11SelectedRequestId = pending.id; return bj11CanDecide() ? bj11Go("SCR-051", "READY") : bj11Go("SCR-053", "PENDING_APPROVAL"); }
  return bj11OpenDetail(op);
}
function bj11StartCorrection() {
  const op = cr11Current();
  if (bj11PendingFor(op)) return bj11Go("SCR-050", "CONFLICT");
  if (op.dependency) return bj11Go("SCR-050", "DEPENDENCY_BLOCKED");
  if (bj11NoPeriod) return bj11Go("SCR-050", "PERIOD_POLICY_VIOLATION");
  bj11ResetDraft(op);
  return bj11Go("SCR-050", "READY");
}
function bj11ViewRequest() {
  const pending = bj11PendingFor(cr11Current()); if (!pending) return;
  cr11SelectedRequestId = pending.id;
  return bj11CanDecide() ? bj11Go("SCR-051", "READY") : bj11Go("SCR-053", "PENDING_APPROVAL");
}
function bj11ViewResult() {
  const r = cr11Request(); if (!r) return;
  return bj11Go("SCR-053", { COMPLETED: "COMPLETED", REJECTED: "REJECTED" }[r.status] || "PENDING_APPROVAL");
}
function bj11SubmitCorrection() {
  const op = cr11Current();
  if (bj11PendingFor(op)) { bj11SetState("SCR-050", "CONFLICT"); return renderAppScreen(); }
  if (bj11Blocker(op, bj11Draft)) { bj11SetState("SCR-050", "VALIDATION_ERROR"); return renderAppScreen(); }
  bj11Submit(op, bj11Draft);
  bj11Go("SCR-053", "PENDING_APPROVAL");
  return showToast("Đã gửi yêu cầu sửa sai", "success");
}
function bj11Decide(approve) {
  const r = cr11Request(); if (!r) return;
  if (!bj11CanDecide()) { bj11SetState("SCR-051", "SELF_APPROVAL_NOT_ALLOWED"); return renderAppScreen(); }
  if (r.status !== "PENDING") { bj11SetState("SCR-051", "APPROVAL_ALREADY_DECIDED"); return renderAppScreen(); }
  if (!approve) { bj11Reject(r, bj11RejectReason.trim()); return bj11Go("SCR-053", "REJECTED"); }
  return bj11Go("SCR-053", bj11Approve(r) === "BLOCKED" ? "BLOCKED" : "COMPLETED");
}
// Dialog (sheet) là modal: mở thì focus vào ô đầu, đóng thì trả focus về nút đã mở.
function bj11OpenDialog(name, opener) {
  bj11Dialog = name; bj11Opener = opener;
  renderAppScreen();
  requestAnimationFrame(() => bj11Focus('#app-screen [role="dialog"] textarea, #app-screen [role="dialog"] button'));
}
function bj11CloseDialog() { const back = bj11Opener; bj11Dialog = null; bj11Rerender(back); }

// Gõ không dựng lại màn (giữ focus): chỉ cập nhật khối "Sau khi sửa", chân và lỗi dưới ô.
function bj11SyncFooter(button, blocker) {
  document.querySelectorAll(button).forEach((b) => { b.disabled = Boolean(blocker); });
  document.querySelectorAll(".app-actions [data-k4-reason]").forEach((p) => { p.textContent = blocker; p.hidden = !blocker; });
}
function bj11ClearError(el) {
  const box = el.closest(".k7-edit") || el.closest(".form-field"); if (!box) return;
  box.classList.remove("k7-edit--error", "bj11-field--error"); el.removeAttribute("aria-invalid"); box.querySelector(".field-error")?.remove();
}
function bj11SyncDraft() {
  const op = cr11Current();
  document.querySelectorAll("[data-bj11-after]").forEach((el) => { el.innerHTML = bj11AfterBlock(op, bj11Draft); });
  bj11SyncFooter('[data-bj11-action="submit"]', bj11Blocker(op, bj11Draft));
}

document.addEventListener("input", (event) => {
  if (activeFlowId !== "UIF-11") return;
  const t = event.target;
  if (t.matches("[data-bj11-search]")) { cr11Query = t.value; ioFilterRows("bj11", t.value); return; }
  if (t.matches("[data-bj11-qty]")) { bj11Draft.qty = t.value; bj11ClearError(t); return bj11SyncDraft(); }
  if (t.matches("[data-bj11-reason]")) { bj11Draft.reason = t.value; bj11ClearError(t); return bj11SyncDraft(); }
  if (t.matches("[data-bj11-cancel-reason]")) { bj11CancelReason = t.value; const b = document.querySelector('[data-bj11-action="cancel-confirm"]'); if (b) b.disabled = !bj11CancelReason.trim(); return; }
  if (t.matches("[data-bj11-reject-reason]")) { bj11RejectReason = t.value; const b = document.querySelector('[data-bj11-action="confirm-reject"]'); if (b) b.disabled = !bj11RejectReason.trim(); bj11ClearError(t); }
}, true);

document.addEventListener("keydown", (event) => {
  if (activeFlowId !== "UIF-11") return;
  const t = event.target;
  if (event.key === "Enter" && t.matches?.("[data-bj11-qty]")) { event.preventDefault(); bj11Focus("[data-bj11-reason]"); }
  // Thẻ chọn cách sửa là nhóm radio: mũi tên đổi lựa chọn và chuyển focus (Space / Enter chọn như bấm).
  if (/^Arrow(Down|Right|Up|Left)$/.test(event.key) && t.matches?.("[data-bj11-strategy]")) {
    event.preventDefault();
    const keys = BJ11_STRATEGIES.map((s) => s[0]), step = /Down|Right/.test(event.key) ? 1 : -1;
    bj11Draft.strategy = keys[(keys.indexOf(t.dataset.bj11Strategy) + step + keys.length) % keys.length];
    return bj11Rerender(`[data-bj11-strategy="${bj11Draft.strategy}"]`);
  }
}, true);

onDialogClose["UIF-11"] = () => {
  if (!(bj11Dialog)) return false;
  bj11CloseDialog(); return true;
};

document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-11") return;
  const t = event.target, hit = (sel) => t.closest?.(sel);
  let el;
  if ((el = hit("[data-bj11-filter]"))) { event.preventDefault(); cr11Filter = el.dataset.bj11Filter; return renderAppScreen(); }
  if ((el = hit("[data-bj11-row]"))) { event.preventDefault(); return bj11OpenRow(el.dataset.bj11Row); }
  if ((el = hit("[data-bj11-strategy]"))) { event.preventDefault(); bj11Draft.strategy = el.dataset.bj11Strategy; return bj11Rerender(`[data-bj11-strategy="${bj11Draft.strategy}"]`); }
  const a = hit("[data-bj11-action]"); if (!a) return;
  if (a.matches(".sheet-backdrop") && t !== a) return;
  event.preventDefault(); event.stopPropagation(); if (a.disabled) return;
  const k = a.dataset.bj11Action;
  if (k === "to-list") return bj11ToListNav();
  if (k === "clear-filter") { cr11Query = ""; cr11Filter = "ALL"; if (stateByScreen["SCR-048"] === "FILTER_EMPTY") bj11SetState("SCR-048", "READY"); return renderAppScreen(); }
  if (k === "to-detail") return bj11OpenDetail(cr11Current());
  if (k === "cancel-open") { bj11CancelReason = ""; return bj11OpenDialog("cancel", '[data-bj11-action="cancel-open"]'); }
  if (k === "dialog-close") return bj11CloseDialog();
  if (k === "cancel-confirm") {
    const op = cr11Current(); if (!bj11CancelReason.trim()) return;
    bj11CancelOp(op, bj11CancelReason.trim()); return bj11Go("SCR-053", "CANCELLED");
  }
  if (k === "correct") return bj11StartCorrection();
  if (k === "submit") return bj11SubmitCorrection();
  if (k === "view-request") return bj11ViewRequest();
  if (k === "view-result") return bj11ViewResult();
  if (k === "reject-open") { if (!bj11CanDecide()) return bj11Decide(false); bj11RejectReason = ""; return bj11OpenDialog("reject", '[data-bj11-action="reject-open"]'); }
  if (k === "confirm-reject") { if (!bj11RejectReason.trim()) return; return bj11Decide(false); }
  if (k === "approve") return bj11Decide(true);
  if (k === "redo") {
    const r = cr11Request(); if (!r) return;
    cr11SelectedId = r.opId; bj11Draft = { strategy: r.strategy, qty: String(r.to), reason: r.reason };
    return bj11Go("SCR-050", "READY");
  }
  if (k === "to-return") return crSwitchFlow("UIF-06", "SCR-030", "READY");
  if (k === "to-stock") return crSwitchFlow("UIF-01", "SCR-001", "READY");
  if (k === "to-case") {
    const c = cr16Cases.find((x) => x.id === cr11ReturnId("case")), r = cr11Request();
    if (!c) return bj11ToListNav();
    if (r && r.status === "COMPLETED") c.correctionDone = true;
    cr16SelectedId = c.id; cr11Return = null;
    return crSwitchFlow("UIF-16", "SCR-079", "CORRECTION_REQUIRED");
  }
  if (k === "to-movement") { cr11Return = null; return crSwitchFlow("UIF-15", "SCR-056", "READY"); }
}, true);

// Đi giữa các màn bằng navigate (kể cả nút quay lại) là đi trong luồng: trạng thái hiện tại là "đã biết", không dựng lại fixture.
["SCR-048", "SCR-049", "SCR-050", "SCR-051", "SCR-053"].forEach((id) => { onScreenEnter[`UIF-11:${id}`] = () => { bj11Expected[id] = stateByScreen[id]; }; });
// Quay lại: 050 → hồ sơ đối soát nếu vào từ đó, không thì chi tiết; chi tiết → danh sách.
onPrevious["UIF-11"] = () => {
  if (activeScreenId === "SCR-048") return;
  bj11Dialog = null;
  if (activeScreenId === "SCR-050") {
    if (cr11ReturnId("case")) { const id = cr11ReturnId("case"); cr11Return = null; cr16SelectedId = id; return crSwitchFlow("UIF-16", "SCR-079", "CORRECTION_REQUIRED"); }
    if (cr11ReturnId("movement")) { cr11Return = null; return crSwitchFlow("UIF-15", "SCR-056", "READY"); }
    return bj11OpenDetail(cr11Current());
  }
  return bj11ToListNav();
};

/* ---------- Lối vào ---------- */

onEntry["UIF-11:approver"] = () => { cr11SelectedRequestId = "SS-260915-01"; bj11ResetUi(); bj11SetState("SCR-051", "READY"); };
onUnknownResolved["UIF-11"] = ({ operationId, outcome }) => {
  const op = cr11Operations.find((o) => o.id === operationId);
  if (op && op.route === "UNKNOWN") op.route = outcome === "RECORDED" ? "RECORDED" : "CANCEL";
  // BJ-17 mở lại danh sách bằng crSwitchFlow (không qua onScreenEnter): đánh dấu 048 đã dựng để bj11Seed không dựng lại từ bản gốc.
  Object.keys(bj11Expected).forEach((k) => delete bj11Expected[k]); bj11Expected["SCR-048"] = "READY";
};
onEntry["UIF-11:operation-context"] = () => { cr11SelectedId = "IO-260904-021"; cr11Return = null; bj11ResetUi(); bj11SetState("SCR-049", "CORRECTABLE"); };
// Từ hồ sơ đối soát (BJ-16): mở thẳng màn sửa sai của đúng phiếu, "Số đúng" điền sẵn theo chứng từ, lý do trống.
onEntry["UIF-11:correction-from-case"] = () => {
  if (!cr11ReturnId("case")) { cr11SelectedId = "IO-260904-021"; cr11Return = { kind: "case", id: "REC-260907-04" }; }
  const op = cr11Current(); bj11ResetUi();
  if (bj11PendingFor(op)) return bj11SetState("SCR-050", "CONFLICT");
  bj11ResetDraft(op, true); bj11SetState("SCR-050", "READY");
};
// Từ thẻ kho (BJ-15 SCR-056 "Sửa sai"): mở thẳng màn sửa sai của đúng phiếu, "Số đúng" trống; quay lại về chi tiết biến động.
onEntry["UIF-11:correction-from-movement"] = () => {
  const op = cr11Current(); bj11ResetUi();
  if (bj11PendingFor(op)) return bj11SetState("SCR-050", "CONFLICT");
  bj11ResetDraft(op); bj11SetState("SCR-050", "READY");
};
if (activeFlowId === "UIF-11" && !requestedScreen && onEntry[`UIF-11:${entryMode}`]) onEntry[`UIF-11:${entryMode}`]();

// SCR-052 đã gộp vào SCR-050 (v5.17.0): đường cũ mở màn sửa sai.
screenAliases["UIF-11"] = Object.assign(screenAliases["UIF-11"] || {}, { "SCR-052": "SCR-050" });
{ const a = screenAliases[activeFlowId]?.[activeScreenId]; if (Array.isArray(a)) { activeFlowId = a[0]; activeScreenId = a[1]; } else if (a) activeScreenId = a; }

flowRenderers["UIF-11"] = Object.assign(flowRenderers["UIF-11"] || {}, {
  "SCR-048": render048BJ11,
  "SCR-049": render049BJ11,
  "SCR-050": render050BJ11,
  "SCR-051": render051BJ11,
  "SCR-053": render053BJ11,
});
Object.assign(renderers, {
  "SCR-048": render048BJ11,
  "SCR-049": render049BJ11,
  "SCR-050": render050BJ11,
  "SCR-051": render051BJ11,
  "SCR-053": render053BJ11,
});

/* ---------- Nguồn "Chờ duyệt" của Home Kho (K2) ---------- */

(window.__T7_PENDING_SOURCES__ ||= []).push({
  id: "UIF-11",
  label: "sửa sai",
  needsActivation: true,
  rows: () => cr11Requests.filter((r) => r.status === "PENDING").map((r) => {
    const op = bj11OpOf(r);
    return {
      title: `${bj11Title(op)} · ${op.product}`,
      subtitle: `${r.from} → ${t7Qty(r.to, op.uom)} · ${r.by} gửi ${r.sentAt}`,
      icon: "edit",
      attrs: `data-theme-entry-flow="UIF-11" data-t380-target-screen="SCR-051" data-t380-context="bj11-approval:${bj11Attr(r.id)}" data-theme-entry-actor="approver"`,
    };
  }),
});
(window.__T7_DIRECT_CONTEXTS__ ||= {})["bj11-approval"] = (id) => {
  const r = cr11Request(id); if (!r) return;
  cr11SelectedRequestId = id; cr11SelectedId = r.opId; cr11Return = r.caseId ? { kind: "case", id: r.caseId } : r.movementId ? { kind: "movement", id: r.movementId } : null; bj11ResetUi(); bj11SetState("SCR-051", "READY");
};
