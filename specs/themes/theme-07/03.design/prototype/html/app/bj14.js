/* BJ-14 — Tính và công bố giá vốn (UIF-14). Màn: SCR-072, SCR-074, SCR-077 (SCR-073 / 075 / 076 là đường cũ, có alias về 074).
 *
 * Thiết kế lại T7-P chặng 6 (v5.19.0): chỉ chủ cửa hàng vào được. 072 "Giá vốn" theo K6 (chip "Cần làm" / "Đã công bố", không ô tìm; web là bảng);
 * 074 là một câu chuyện cho mọi trạng thái, khối theo thứ tự cố định: việc chặn → kết quả → thay đổi sẽ ghi → theo sản phẩm → phương pháp;
 * việc chặn đọc từ dữ liệu thật của BJ-03 / BJ-11 / BJ-16 và có nút sang nơi xử lý; 077 theo K4 / K3, có bước tiếp sang báo cáo tồn (BJ-15).
 * Lần tính bất biến: dữ liệu đổi (hoặc hết việc chặn) thì tạo lần tính kế tiếp `{mã gốc}-R{n}`, lần cũ giữ để truy vết.
 * Tiền không có hằng số gõ tay cho tổng: bj14Totals(run) cộng từ dòng sản phẩm (số lượng × giá).
 * Dùng từ khuôn: K1, K3 (k3Unknown), K4 (k4Result, k4ReasonFooter), K6 (k6TaskList không ô tìm), K7 (k7Split, k7Table), dsChoiceRow.
 * Fixture: plan T7-P-bj14-gia-von.md mục 3 (sản phẩm / ĐVT từ bj01Products, giá vốn từ BJ08_CATALOG; số liệu khớp BJ-01…BJ-16 chặng 1–5).
 */

const BJ14_POLICY = window.__C45_TENANT_COST_POLICY__ || { version: "MISSING", method: null, label: "Chưa cấu hình", periodCloseScopes: [] };
const BJ14_METHODS = {
  PERIODIC: ["Bình quân cuối kỳ", "giá vốn mỗi sản phẩm là giá trung bình của tồn đầu kỳ và hàng nhập cả kỳ."],
  MOVING: ["Bình quân liên hoàn", "giá vốn tính lại sau mỗi lần nhập."],
};
const BJ14_METHOD = BJ14_POLICY.method === "MOVING" ? "MOVING" : "PERIODIC";
const BJ14_OTHER_METHOD = BJ14_METHOD === "MOVING" ? "PERIODIC" : "MOVING";
const BJ14_AT = "17/09/2026 · 21:20";
const BJ14_CALC_MS = 1500;
const BJ14_ENDED_PERIODS = ["07/2026", "08/2026"];
const BJ14_VALUE_ROUTES = ["CORRECTION", "LEDGER", "SOURCE"];
const BJ14_CAUSE = { PRICE: "Xác lập giá nhập", CORRECTION: "Sửa sai", ADJUST: "Điều chỉnh giá trị" };
const BJ14_CAUSE_SHORT = { PRICE: "xác lập giá nhập", CORRECTION: "sửa sai", ADJUST: "điều chỉnh giá trị" };
const BJ14_STATE = { NOT_CALCULATED: "NOT_CALCULATED", BLOCKED: "BLOCKED", CALCULATING: "CALCULATING", INPUT_CHANGED: "INPUT_CHANGED", READY_FOR_REVIEW: "READY_FOR_REVIEW", PUBLISHED: "READY_FOR_REVIEW" };

/* ---------- Fixture ---------- */

// Sản phẩm không có trong BJ08_CATALOG (Enrofloxacin 10%) đặt giá vốn ở đây.
const BJ14_EXTRA_COST = { "SP-000091": 96000 };
function bj14BaseCost(code) { return BJ08_CATALOG.find((c) => c.code === code)?.unitCost ?? BJ14_EXTRA_COST[code]; }
// [mã, giá vốn cũ, giá mới (bình quân cuối kỳ), giá mới (bình quân liên hoàn), tồn cuối kỳ, xuất trong kỳ]
const BJ14_T_0807 = [
  ["SP-000184", 116500, 118000, 117800, 118, 30],
  ["SP-000066", 41000, 42000, 41900, 30, 20],
  ["SP-000091", 94000, 96000, 95800, 6, 8],
  ["SP-000122", 84000, 85000, 84800, 14, 7],
  ["SP-000147", 56000, 55000, 55200, 17, 9],
];
// Tồn cuối 31/08 khớp tồn BJ-01 sau các biến động tháng 09 (nhận PN-260904-08 +20, bán / bàn giao tháng 09…).
const BJ14_T_0826 = [
  ["SP-000184", 119500, 119200, 122, 38],
  ["SP-000066", 41500, 41600, 28, 22],
  ["SP-000091", 96000, 96000, 0, 6],
  ["SP-000122", 86200, 86000, 12, 9],
  ["SP-000147", 54200, 54400, 15, 8],
];
// [mã, giá mới (cuối kỳ), giá mới (liên hoàn), tồn hiện tại, xuất trong tháng, nguyên nhân] — nguyên nhân là mã thật của BJ-03 / BJ-11 / BJ-13.
// Xuất trong tháng khớp sổ kho tháng 09 của BJ-15 (bj15Check kiểm).
const BJ14_T_U1 = [
  ["SP-000184", 120100, 119900, 120, 12, { kind: "ADJUST", ref: "LC13-ADJ-001-1" }],
  ["SP-000066", 41800, 41900, 48, 0, { kind: "CORRECTION", ref: "PN-260904-08" }],
  ["SP-000147", 55300, 55200, 12, 3, { kind: "PRICE", ref: "PN-260816-04" }],
];

function bj14Line(code, oldCost, costPeriodic, costMoving, qtyEnd, qtyOut, cause = null) {
  const p = bj01Products.find((x) => x.code === code);
  return { code, name: p.name, uom: p.stockUom, oldCost, costPeriodic, costMoving, qtyEnd, qtyOut, cause: cause ? { ...cause } : null };
}
function bj14CloseLines(codes) { return BJ14_T_0826.filter((t) => !codes || codes.includes(t[0])).map(([code, per, mov, end, out]) => bj14Line(code, bj14BaseCost(code), per, mov, end, out)); }
function bj14NewRun(r) { return { supersedes: null, inputVersion: 1, publishedAt: "", scopeLabel: "Toàn bộ sản phẩm", ...r }; }
function bj14InitialRuns() {
  return [
    bj14NewRun({ id: "COST-2608", kind: "PERIOD_CLOSE", period: "08/2026", cutoff: "31/08/2026 · 23:59", status: "READY_FOR_REVIEW", lines: bj14CloseLines() }),
    bj14NewRun({ id: "COST-2609-U1", kind: "AD_HOC", period: "09/2026", cutoff: BJ14_AT, status: "NOT_CALCULATED", scopeLabel: "Sản phẩm cần tính lại", lines: BJ14_T_U1.map(([code, per, mov, end, out, cause]) => bj14Line(code, bj14BaseCost(code), per, mov, end, out, cause)) }),
    bj14NewRun({ id: "COST-2607", kind: "PERIOD_CLOSE", period: "07/2026", cutoff: "31/07/2026 · 23:59", status: "PUBLISHED", publishedAt: "05/08/2026 · 09:20", lines: BJ14_T_0807.map(([code, old, per, mov, end, out]) => bj14Line(code, old, per, mov, end, out)) }),
  ];
}

const bj14Runs = bj14InitialRuns();
let bj14Official = {};           // giá vốn chính thức hiện hành theo mã sản phẩm
let bj14SelectedId = "COST-2608";
let bj14Filter = "TODO";
let bj14Draft = null;            // chốt kỳ chưa tính: { kind, period, cutoff, scopeId, lines: [] }
let bj14Ui = { sheet: null, opener: "", reviewVersion: null };
let bj14Timer = null;
const bj14Expected = {};

const bj14Attr = (v) => escapeAttribute(String(v ?? ""));
// NBSP giữa số và "đ" để số tiền không gãy dòng; dấu "+" / "−" dính số.
function bj14Unit(cost, uom) { return `${t7FmtMoney(cost)}/${uom}`; }
function bj14CanView() { return ["owner", "approver"].includes(currentActor()); }

/* ---------- Tính tiền: mọi tổng cộng từ dòng sản phẩm ---------- */

function bj14CostOf(line, alt = false) { return (BJ14_METHOD === "MOVING") !== alt ? line.costMoving : line.costPeriodic; }
function bj14LineDiff(line) { return (line.qtyEnd + line.qtyOut) * (bj14CostOf(line) - line.oldCost); }
function bj14Totals(run, alt = false) {
  const t = { end: 0, cogs: 0, endAdj: 0, cogsAdj: 0, changed: 0 };
  for (const l of run.lines) {
    const c = bj14CostOf(l, alt);
    t.end += l.qtyEnd * c; t.cogs += l.qtyOut * c;
    t.endAdj += l.qtyEnd * (c - l.oldCost); t.cogsAdj += l.qtyOut * (c - l.oldCost);
    if (c !== l.oldCost) t.changed++;
  }
  t.net = t.endAdj + t.cogsAdj;
  return t;
}
const bj14HasResult = (run) => run.status === "READY_FOR_REVIEW" || run.status === "PUBLISHED";

/* ---------- Lần tính ---------- */

const bj14Find = (id) => bj14Runs.find((r) => r.id === id) || null;
const bj14Superseded = (run) => bj14Runs.some((x) => x.supersedes === run.id);
// Màn đang xem: bản nháp "Chốt kỳ" chưa tính, hoặc lần tính được chọn.
function bj14Current() { return bj14Draft || bj14Find(bj14SelectedId) || bj14Runs[0]; }
function bj14Title(run) { return `${run.kind === "PERIOD_CLOSE" ? "Chốt kỳ" : "Cập nhật giá vốn"} ${run.period}`; }
function bj14Subtitle(run) { return `${run.lines.length ? `${run.lines.length} sản phẩm · ` : ""}Thời điểm chốt ${run.cutoff}`; }
function bj14CauseText(c) { return c ? `${BJ14_CAUSE[c.kind]} ${c.ref}` : ""; }
function bj14PeriodKey(p) { return Number(`${p.slice(3, 7)}${p.slice(0, 2)}`); }
function bj14LastDay(period) { const [m, y] = period.split("/").map(Number); return String(new Date(y, m, 0).getDate()).padStart(2, "0"); }
// Kỳ đã kết thúc mà chưa có lần tính chốt kỳ (fixture không có; trạng thái NEEDS_PERIOD_CLOSE bỏ COST-2608 để dựng).
function bj14PeriodToClose() { return [...BJ14_ENDED_PERIODS].reverse().find((p) => !bj14Runs.some((r) => r.kind === "PERIOD_CLOSE" && r.period === p)) || null; }

function bj14Restore() {
  bj14Runs.splice(0, bj14Runs.length, ...bj14InitialRuns());
  bj14Official = Object.fromEntries(bj01Products.map((p) => [p.code, bj14BaseCost(p.code)]));
  bj14SelectedId = "COST-2608"; bj14Filter = "TODO"; bj14Draft = null;
  bj14Ui = { sheet: null, opener: "", reviewVersion: null };
  clearTimeout(bj14Timer);
}
function bj14SetState(screenId, state) { stateByScreen[screenId] = state; bj14Expected[screenId] = state; }
// Vào bằng lối khác (BJ-03 / BJ-13 / Hub) mà không đặt trạng thái từ ngoài: màn hiện tại là "đã biết", không dựng lại fixture.
function bj14Known(screenId, state) { bj14Expected[screenId] = state; stateByScreen[screenId] = state; }

/* ---------- Việc chặn: đọc từ dữ liệu thật của BJ-03 / BJ-11 / BJ-16 ---------- */

// Chỉ việc thuộc kỳ của lần tính hoặc trước đó mới chặn; hồ sơ chỉ chặn khi loại hồ sơ ảnh hưởng giá trị
// (sai lệch app / báo cáo khác số tồn không đổi sổ kho nên không chặn); dòng hàng chưa có giá nhập chỉ chặn sản phẩm chưa có giá vốn chính thức.
function bj14Blockers(run) {
  const rows = [], key = bj14PeriodKey(run.period);
  for (const l of run.lines) {
    for (const r of cr11Requests) {
      const op = r.status === "PENDING" ? bj11OpOf(r) : null;
      if (!op || op.product !== l.name || bj14PeriodKey(op.period) > key) continue;
      rows.push({ id: `corr:${r.id}`, title: `Sửa sai ${op.docCode} đang chờ duyệt`, detail: l.name, label: "Mở yêu cầu sửa sai", action: "to-correction", ref: r.id });
    }
    for (const c of cr16Cases) {
      if (!["OPEN", "WAITING"].includes(cr16Status(c)) || !BJ14_VALUE_ROUTES.includes(c.route)) continue;
      if (!c.scope.includes(l.name) && !c.scope.includes(l.code)) continue;
      if (bj14PeriodKey(c.openedAt.slice(3, 10)) > key) continue;
      rows.push({ id: `case:${c.id}`, title: `Hồ sơ ${c.id} chưa đóng`, detail: `${l.name} · ${cr16RouteView(c).conclusion}`, label: "Mở hồ sơ", action: "to-case", ref: c.id });
    }
    if (bj14Official[l.code] == null) {
      const pending = val03PendingLines(l.code);
      if (pending.length) rows.push({ id: `price:${l.code}`, title: `${pending.length} dòng hàng chưa có giá nhập`, detail: l.name, label: "Mở hàng chờ xác lập giá trị", action: "to-valuation", ref: l.code });
    }
  }
  return rows.filter((b, i) => rows.findIndex((x) => x.id === b.id) === i);
}

/* ---------- Tính và công bố ---------- */

// Có việc chặn thì lần tính chưa chạy (BLOCKED); không thì chạy (CALCULATING → READY_FOR_REVIEW sau BJ14_CALC_MS hoặc __C45_QA__.finishBJ14Calc).
function bj14Calculate(run) {
  if (bj14Blockers(run).length) { run.status = "BLOCKED"; return run.status; }
  run.lines.forEach((l) => { l.oldCost = bj14Official[l.code] ?? l.oldCost; });
  run.status = "CALCULATING";
  clearTimeout(bj14Timer);
  bj14Timer = setTimeout(() => bj14FinishCalc(run.id), BJ14_CALC_MS);
  return run.status;
}
function bj14FinishCalc(id = bj14SelectedId) {
  const run = bj14Find(id);
  if (!run || run.status !== "CALCULATING") return false;
  clearTimeout(bj14Timer);
  run.status = "READY_FOR_REVIEW";
  if (bj14SelectedId === run.id) bj14SetState("SCR-074", "READY_FOR_REVIEW");
  if (activeFlowId === "UIF-14" && activeScreenId === "SCR-074" && bj14SelectedId === run.id) renderAppScreen();
  return true;
}
// Lần tính kế tiếp (BR-03): bản sao dòng của lần cũ, mã `{gốc}-R{n}`, lần cũ giữ nguyên để truy vết.
function bj14Successor(run) {
  const base = run.id.replace(/-R\d+$/, ""), n = bj14Runs.filter((x) => x.id.startsWith(`${base}-R`)).length + 1;
  const next = bj14NewRun({ ...run, id: `${base}-R${n}`, status: "NOT_CALCULATED", supersedes: run.id, inputVersion: run.inputVersion, publishedAt: "", lines: run.lines.map((l) => ({ ...l, cause: l.cause ? { ...l.cause } : null })) });
  bj14Runs.splice(Math.max(0, bj14Runs.indexOf(run)), 0, next);
  bj14SelectedId = next.id;
  return next;
}
// "Tính giá vốn" ở bản nháp chốt kỳ: phạm vi do chính sách (toàn bộ sản phẩm, hoặc chỉ sản phẩm hệ thống đã đánh dấu cần tính lại).
function bj14CreateClose(draft) {
  const scope = (BJ14_POLICY.periodCloseScopes || []).find((s) => s.id === draft.scopeId);
  const dirty = bj14Runs.find((r) => r.kind === "AD_HOC" && r.status !== "PUBLISHED" && !bj14Superseded(r));
  const codes = scope?.id === "DIRTY_PRODUCTS_ONLY" && dirty ? dirty.lines.map((l) => l.code) : null;
  const base = `COST-26${draft.period.slice(0, 2)}`, n = bj14Runs.filter((x) => x.id === base || x.id.startsWith(`${base}-R`)).length;
  const run = bj14NewRun({ id: n ? `${base}-R${n}` : base, kind: "PERIOD_CLOSE", period: draft.period, cutoff: draft.cutoff, status: "NOT_CALCULATED", scopeLabel: scope?.label || "Toàn bộ sản phẩm", lines: bj14CloseLines(codes) });
  bj14Runs.unshift(run);
  bj14SelectedId = run.id; bj14Draft = null;
  return run;
}
function bj14Commit(run) {
  run.status = "PUBLISHED"; run.publishedAt = BJ14_AT;
  run.lines.forEach((l) => { bj14Official[l.code] = bj14CostOf(l); });
}

/* ---------- Dựng lại fixture khi trạng thái đặt từ ngoài ---------- */

function bj14Seed(screenId, state) {
  if (bj14Expected[screenId] === state) return;
  Object.keys(bj14Expected).forEach((k) => delete bj14Expected[k]);
  bj14Expected[screenId] = state;
  bj14Restore();
  const pick = (id, status) => { bj14SelectedId = id; const r = bj14Find(id); if (status) r.status = status; return r; };
  if (screenId === "SCR-072") {
    if (state === "NEEDS_PERIOD_CLOSE") bj14Runs.splice(bj14Runs.findIndex((r) => r.id === "COST-2608"), 1);
    return;
  }
  if (screenId === "SCR-074") {
    if (state === "BLOCKED") { bj11Restore(); crRestore(); pick("COST-2609-U1", "BLOCKED"); }
    else if (state === "NOT_CALCULATED") pick("COST-2609-U1");
    else if (state === "CALCULATING") { pick("COST-2609-U1", "CALCULATING").lines.forEach((l) => { l.oldCost = bj14Official[l.code]; }); }
    else if (state === "INPUT_CHANGED") { const r = pick("COST-2608"); r.inputVersion += 1; r.status = "INPUT_CHANGED"; }
    else pick("COST-2608");
    return;
  }
  if (screenId === "SCR-077") { const r = pick("COST-2608"); if (state === "COMPLETED") bj14Commit(r); }
}
bj14Restore();

/* ---------- Khung dùng chung ---------- */

function bj14Shell(opts) { return appShell({ extraClass: "k7-wide", ...opts }); }
function bj14Denied(title, back = false) {
  return bj14Shell({ title, body: k1Denied({ what: "xem giá vốn", next: "Chỉ chủ cửa hàng xem và công bố giá vốn.", exitAttr: k1ExitAttr("SCR-072") }), centered: true, back });
}
function bj14StatusMeta(run) {
  const n = run.lines.length;
  if (run.status === "READY_FOR_REVIEW") return { label: "Sẵn sàng công bố", tone: "Success", sub: `${n} sản phẩm · đã tính, chờ công bố` };
  if (run.status === "PUBLISHED") return { label: "Đã công bố", tone: "Success", sub: `Công bố ${run.publishedAt.split(" · ")[0]}` };
  if (run.status === "CALCULATING") return { label: "Đang tính", tone: "Info", sub: `${n} sản phẩm · đang tính` };
  if (run.status === "INPUT_CHANGED") return { label: "Cần tính lại", tone: "Warning", sub: `${n} sản phẩm · dữ liệu đã đổi` };
  if (run.status === "BLOCKED") {
    const k = bj14Blockers(run).length;
    return k ? { label: "Cần xử lý", tone: "Warning", sub: `${k} việc cần xử lý` } : { label: "Cần tính lại", tone: "Warning", sub: "Đã xử lý xong việc chặn" };
  }
  if (run.kind === "AD_HOC") return { label: "Cần tính lại", tone: "Warning", sub: `${n} sản phẩm · ${[...new Set(run.lines.map((l) => l.cause && BJ14_CAUSE_SHORT[l.cause.kind]).filter(Boolean))].join(", ")}` };
  return { label: "Chưa tính", tone: "Neutral", sub: `${n} sản phẩm` };
}
function bj14Method(alt = false) { return BJ14_METHODS[alt ? BJ14_OTHER_METHOD : BJ14_METHOD]; }

/* ---------- SCR-072 · Giá vốn (K6) ---------- */

function bj14ListRows() { return bj14Runs.filter((r) => !bj14Superseded(r)); }
function bj14RowView(run) {
  const m = bj14StatusMeta(run);
  return { id: run.id, title: bj14Title(run), subtitle: m.sub, status: { label: m.label, tone: m.tone }, period: run.period, scope: run.scopeLabel, adj: bj14HasResult(run) ? t7FmtMoney(bj14Totals(run).net, true) : "—", statusHtml: ds24Badge(m.label, m.tone) };
}
function render072BJ14(state) {
  if (activeFlowId !== "UIF-14") return renderGeneric(screens.find((s) => s.id === "SCR-072"), state);
  const title = "Giá vốn", subtitle = `Chính sách: ${BJ14_POLICY.label}`;
  bj14Seed("SCR-072", state);
  if (state === "PERMISSION_DENIED" || !bj14CanView()) return bj14Denied(title);
  if (state === "LOADING") return bj14Shell({ title, subtitle, body: k1Loading({ blocks: ["row", "row", "row"] }), back: false });
  const all = state === "EMPTY" ? [] : bj14ListRows();
  const todo = all.filter((r) => r.status !== "PUBLISHED"), done = all.filter((r) => r.status === "PUBLISHED");
  const rows = (bj14Filter === "DONE" ? done : todo).map(bj14RowView);
  const columns = [{ key: "title", label: "Lần tính" }, { key: "period", label: "Kỳ", mono: true }, { key: "scope", label: "Phạm vi" }, { key: "adj", label: "Chênh lệch sẽ ghi", align: "end", mono: true }, { key: "statusHtml", label: "Tình trạng", html: true }];
  const body = k6TaskList({
    search: null, caption: "Công việc giá vốn",
    filters: { items: [["TODO", "Cần làm", todo.length], ["DONE", "Đã công bố", done.length]], selected: bj14Filter, attrName: "data-bj14-filter" },
    columns, rows, total: all.length,
    rowAttr: (r) => `data-bj14-row="${bj14Attr(r.id)}"`,
    rowOpen: true,
    empty: { title: "Không có công việc giá vốn", description: "Chưa có phạm vi cần cập nhật hoặc chốt kỳ." },
    filterEmpty: { title: bj14Filter === "DONE" ? "Chưa có kỳ nào được công bố" : "Không còn việc cần làm", description: "Chọn mục khác để xem thêm.", actionLabel: "Xem tất cả", actionAttr: 'data-bj14-action="clear-filter"' },
    filterEmptyAttr: "data-bj14-filter-empty",
  });
  const close = state === "EMPTY" ? null : bj14PeriodToClose();
  return bj14Shell({ title, subtitle, body, back: false, centered: state === "EMPTY", actions: close ? primaryFooter(`Chốt kỳ ${close}`, 'data-bj14-action="close-period"') : "" });
}

/* ---------- SCR-074 · Giá vốn {kỳ}: một câu chuyện ---------- */

function bj14BlockerRow(b) {
  return `<div class="bj14-blocker" data-bj14-blocker="${bj14Attr(b.id)}"><span class="bj14-blocker__icon" aria-hidden="true">${icon("alert", "icon--sm")}</span><span class="bj14-blocker__copy"><strong>${esc(b.title)}</strong><small>${esc(b.detail)}</small></span><button type="button" class="button button--secondary bj14-blocker__action" data-bj14-action="${b.action}" data-bj14-ref="${bj14Attr(b.ref)}" data-ds-component="VButton">${esc(b.label)}</button></div>`;
}
function bj14MethodBlock(run, withCompare) {
  const [label, sentence] = bj14Method();
  const compare = withCompare ? `<button type="button" class="button button--secondary bj14-method__compare" data-bj14-action="compare-open" data-ds-component="VButton">${esc(`Xem đối chiếu theo ${bj14Method(true)[0]}`)}</button>` : "";
  return `<section class="bj14-method" data-composed-from="VText">${ds24SectionTitle("Phương pháp")}<p class="bj14-method__line"><strong>${esc(label)}</strong> — ${esc(sentence)}</p><p class="bj14-note">Theo chính sách của cửa hàng; không đổi theo lần tính.</p>${compare}</section>`;
}
function bj14ProductRows(run) {
  return run.lines.map((l, i) => ({ ...l, i, diff: bj14LineDiff(l), changed: bj14CostOf(l) !== l.oldCost })).sort((a, b) => Math.abs(b.diff) - Math.abs(a.diff) || a.i - b.i);
}
function bj14ProductMobileRow(r) {
  const c = bj14CostOf(r);
  const sub = r.changed ? `${t7FmtMoney(r.oldCost)} → ${bj14Unit(c, r.uom)}` : `Giữ ${bj14Unit(r.oldCost, r.uom)}`;
  const trailing = r.changed ? `<strong class="bj14-diff">${esc(t7FmtMoney(r.diff, true))}</strong>` : ds24Badge("Không đổi", "Neutral");
  return ds24ListRow({ title: r.name, subtitle: sub, trailing, leading: null, type: "Status", density: "Compact", interactive: false });
}
function bj14ProductsBlock(run) {
  const rows = bj14ProductRows(run).map((r) => ({ ...r, product: `<strong>${esc(r.name)}</strong><small>${esc(r.code)}</small>`, oldText: bj14Unit(r.oldCost, r.uom), newText: r.changed ? bj14Unit(bj14CostOf(r), r.uom) : "—", diffHtml: r.changed ? esc(t7FmtMoney(r.diff, true)) : ds24Badge("Không đổi", "Neutral") }));
  const columns = [{ key: "product", label: "Sản phẩm", html: true }, { key: "oldText", label: "Giá vốn cũ", align: "end", mono: true }, { key: "newText", label: "Giá vốn mới", align: "end", mono: true }, { key: "diffHtml", label: "Chênh lệch", align: "end", mono: true, html: true }];
  const table = k7Table({ columns, rows, mobileRow: (r) => (rows.indexOf(r) >= 3 ? "" : bj14ProductMobileRow(r)), caption: "Theo sản phẩm" });
  const more = `<button type="button" class="button button--secondary bj14-more" data-bj14-action="products-open" data-ds-component="VButton">${esc(`Xem ${rows.length} sản phẩm`)}</button>`;
  return `<section class="bj14-products">${ds24SectionTitle("Theo sản phẩm")}${table}${more}</section>`;
}
function bj14ResultMain(run, t) {
  const metrics = ac310SummaryMetrics([["Giá trị tồn cuối", t7FmtMoney(t.end)], ["Giá vốn xuất", t7FmtMoney(t.cogs)]]);
  const writes = `<section class="bj14-writes">${ds24SectionTitle("Thay đổi sẽ ghi khi công bố")}<p class="bj14-note">Chỉ phần chênh lệch dưới đây được ghi; chứng từ lịch sử không bị sửa.</p>${ac310KeyValueSurface("", [["Điều chỉnh giá vốn xuất", t7FmtMoney(t.cogsAdj, true), true], ["Điều chỉnh giá trị tồn", t7FmtMoney(t.endAdj, true), true]])}</section>`;
  return `${metrics}${writes}${bj14ProductsBlock(run)}${bj14MethodBlock(run, true)}`;
}
function bj14Summary(run, t) {
  return ac310KeyValueSurface("Tóm tắt", [["Kỳ", run.period], ["Phạm vi", run.scopeLabel], ["Thời điểm chốt", run.cutoff], ["Phương pháp", BJ14_POLICY.label], ["Điều chỉnh giá vốn xuất", t7FmtMoney(t.cogsAdj, true), true], ["Điều chỉnh giá trị tồn", t7FmtMoney(t.endAdj, true), true]]);
}
function bj14ScopeChoice(draft) {
  const scopes = BJ14_POLICY.periodCloseScopes || [];
  if (scopes.length <= 1) return `<section class="bj14-section">${ds24InfoGroup("", ds24InfoRow("Phạm vi", scopes[0]?.label || "Toàn bộ sản phẩm"))}</section>`;
  return `<section class="bj14-section">${ds24SectionTitle("Phạm vi")}<div class="ds-choice-list" role="radiogroup" aria-label="Phạm vi">${scopes.map((s) => dsChoiceRow({ title: s.label, selected: draft.scopeId === s.id, attrs: `data-bj14-scope="${bj14Attr(s.id)}"` })).join("")}</div></section>`;
}
function bj14SetupBody(run) {
  if (run === bj14Draft) return { body: `${ds24InfoGroup("", ds24InfoRow("Kỳ", run.period))}${bj14ScopeChoice(run)}${bj14MethodBlock(run, false)}`, actions: k4ReasonFooter({ label: "Tính giá vốn", attr: 'data-bj14-action="calculate"', disabled: !run.scopeId && (BJ14_POLICY.periodCloseScopes || []).length > 1, reason: "Chọn phạm vi" }) };
  const rows = run.lines.map((l) => ds24ListRow({ title: l.name, subtitle: bj14CauseText(l.cause), leading: null, type: "Status", density: "Compact", interactive: false })).join("");
  const body = run.kind === "AD_HOC"
    ? `<section class="bj14-scope">${ds24SectionTitle("Sản phẩm cần tính lại")}${ds24GroupedCollection(rows, "bj14-scope-list")}</section>${bj14MethodBlock(run, false)}`
    : `${ds24InfoGroup("", ds24InfoRow("Kỳ", run.period) + ds24InfoRow("Phạm vi", run.scopeLabel))}${bj14MethodBlock(run, false)}`;
  return { body, actions: primaryFooter("Tính giá vốn", 'data-bj14-action="calculate"') };
}
function bj14BlockedBody(run) {
  const blockers = bj14Blockers(run), k = blockers.length;
  const banner = k ? vBanner("warning", "Chưa công bố được", `Xử lý ${k} việc dưới đây rồi tính lại.`) : vBanner("info", "Đã xử lý hết việc chặn", "Tính lại để có kết quả mới.");
  const list = k ? ds24GroupedCollection(blockers.map(bj14BlockerRow).join(""), "bj14-blockers") : "";
  return { body: `${banner}${list}${bj14MethodBlock(run, false)}`, actions: k4ReasonFooter({ label: "Tính lại", attr: 'data-bj14-action="recalculate"', disabled: k > 0, reason: `Còn ${k} việc cần xử lý` }) };
}
function bj14PublishSheet(run, t) {
  const facts = `<div class="bj14-sheet-facts">${ds24InfoRow("Kỳ ghi nhận", run.period)}${ds24InfoRow("Phạm vi", run.scopeLabel)}${ds24InfoRow("Phương pháp", BJ14_POLICY.label)}${ds24KeyValueRow("Điều chỉnh giá vốn xuất", t7FmtMoney(t.cogsAdj, true), true)}${ds24KeyValueRow("Điều chỉnh giá trị tồn", t7FmtMoney(t.endAdj, true), true)}</div>`;
  const sheet = k2RejectSheet({ open: true, title: "Công bố giá vốn?", description: "Kết quả đã rà soát sẽ có hiệu lực. Hệ thống chỉ ghi phần chênh lệch, không sửa chứng từ lịch sử.", withReason: false, closeAttr: 'data-bj14-action="dialog-close"', closeLabel: "Quay lại", confirmAttr: 'data-bj14-action="publish"', confirmLabel: "Công bố giá vốn" });
  return sheet.replace('<div class="sheet-actions">', `${facts}<div class="sheet-actions">`);
}
function bj14InfoSheet(title, body) {
  return ds24Sheet({ title, attrs: 'data-bj14-action="dialog-close"', body: `${body}${cfSecondary("Đóng", 'data-bj14-action="dialog-close"')}` });
}
function bj14CompareSheet(run) {
  const t = bj14Totals(run, true), [label] = bj14Method(true);
  return bj14InfoSheet(`Đối chiếu theo ${label}`, `<p class="bj14-note">Chỉ để đối chiếu; không dùng để công bố.</p>${ac310KeyValueSurface("", [["Giá trị tồn cuối", t7FmtMoney(t.end)], ["Giá vốn xuất", t7FmtMoney(t.cogs)]])}`);
}
function bj14ProductsSheet(run) {
  return bj14InfoSheet("Theo sản phẩm", ds24GroupedCollection(bj14ProductRows(run).map(bj14ProductMobileRow).join(""), "bj14-products-sheet"));
}
function render074BJ14(state) {
  if (activeFlowId !== "UIF-14") return renderGeneric(screens.find((s) => s.id === "SCR-074"), state);
  bj14Seed("SCR-074", state);
  if (state === "PERMISSION_DENIED" || !bj14CanView()) return bj14Denied("Giá vốn", true);
  const run = bj14Current(), title = bj14Title(run), subtitle = bj14Subtitle(run);
  if (run.status === "CALCULATING") return bj14Shell({ title, subtitle, body: `${k1Loading({ blocks: ["heading", "card", "card"] })}<p class="bj14-note">Có thể rời màn hình. Kết quả được lưu trong cùng lần tính.</p>` });
  if (run.status === "INPUT_CHANGED") return bj14Shell({ title, subtitle, body: `${k1Stale({ title: "Dữ liệu đầu vào đã thay đổi", description: "Kết quả cũ được giữ để truy vết nhưng không còn đủ điều kiện công bố.", actionLabel: "Tạo lần tính kế tiếp", actionAttr: 'data-bj14-action="successor"' })}${bj14MethodBlock(run, false)}` });
  if (run.status === "BLOCKED" || run.status === "NOT_CALCULATED") {
    const v = run.status === "BLOCKED" ? bj14BlockedBody(run) : bj14SetupBody(run);
    return bj14Shell({ title, subtitle, body: v.body, actions: v.actions });
  }
  const t = bj14Totals(run);
  const body = `${k7Split({ main: bj14ResultMain(run, t), aside: bj14Summary(run, t), wideMain: true, asideWebOnly: true })}${bj14SheetHtml(run, t)}`;
  return bj14Shell({ title, subtitle, body, actions: run.status === "READY_FOR_REVIEW" ? primaryFooter("Công bố giá vốn", 'data-bj14-action="open-publish"') : "" });
}
function bj14SheetHtml(run, t) {
  if (bj14Ui.sheet === "publish" && t) return bj14PublishSheet(run, t);
  if (bj14Ui.sheet === "compare" && t) return bj14CompareSheet(run);
  if (bj14Ui.sheet === "products" && t) return bj14ProductsSheet(run);
  return "";
}

/* ---------- SCR-077 · Kết quả công bố (K4 / K3) ---------- */

function render077BJ14(state) {
  if (activeFlowId !== "UIF-14") return renderGeneric(screens.find((s) => s.id === "SCR-077"), state);
  const title = "Kết quả công bố giá vốn";
  bj14Seed("SCR-077", state);
  if (state === "PERMISSION_DENIED" || !bj14CanView()) return bj14Denied(title);
  if (state === "PROCESSING") return bj14Shell({ title, body: k1Loading({ blocks: ["heading", "card", "row"] }), centered: true, back: false });
  const run = bj14Current(), toList = { label: "Về giá vốn", attr: 'data-bj14-action="to-list"' };
  if (state === "UNKNOWN") return k3Unknown({ operation: "Công bố giá vốn", scope: bj14Title(run), ref: run.id, sentAt: BJ14_AT, sourceFlow: "UIF-14", exitAttr: k1ExitAttr("SCR-072"), handoff: { operation: run.id, scope: bj14Title(run) } });
  if (state === "REJECTED_EXECUTION") return k4Result({ screenTitle: title, kind: "warning", title: "Chưa công bố giá vốn", description: "Không có điều chỉnh hoặc phiên bản giá vốn mới.", facts: [["Kỳ ghi nhận", run.period]], next: [{ ...toList, primary: true }] });
  const t = bj14Totals(run);
  const facts = [["Kỳ ghi nhận", run.period], ["Phương pháp", BJ14_POLICY.label], ["Sản phẩm có giá vốn mới", String(t.changed)], ["Điều chỉnh giá vốn xuất", t7FmtMoney(t.cogsAdj, true)], ["Điều chỉnh giá trị tồn", t7FmtMoney(t.endAdj, true)], ["Công bố lúc", run.publishedAt || BJ14_AT]];
  return k4Result({ screenTitle: title, title: `Đã công bố giá vốn ${run.period}`, description: "Phần chênh lệch đã được ghi và giá vốn chính thức mới đã có hiệu lực.", facts, next: [toList, { label: "Xem báo cáo tồn", attr: 'data-bj14-action="to-report"', primary: true }] });
}

/* ---------- Sự kiện ---------- */

function bj14Rerender(focusSelector = "") {
  const top = document.querySelector("#app-screen .app-content")?.scrollTop || 0;
  renderAppScreen();
  const content = document.querySelector("#app-screen .app-content"); if (content) content.scrollTop = top;
  if (focusSelector) bj14Focus(focusSelector);
}
// getClientRects: phần tử position:fixed (sheet) có offsetParent = null nhưng vẫn hiển thị.
function bj14Visible(el) { return el.getClientRects().length > 0; }
function bj14Focus(selector) {
  const el = [...document.querySelectorAll(selector)].find(bj14Visible);
  if (el) el.focus({ preventScroll: true });
  return el || null;
}
function bj14Go(screenId, state) { bj14Ui.sheet = null; bj14SetState(screenId, state); return navigate(screenId); }
function bj14ToList() { bj14Draft = null; bj14ReturnRunId = ""; return bj14Go("SCR-072", "READY"); }
// Sau mỗi bước làm đổi trạng thái lần tính, nhãn trạng thái ở bộ chọn đi theo.
function bj14Sync(run) { bj14SetState("SCR-074", BJ14_STATE[run.status] || run.status); }
function bj14OpenRun(id) {
  const run = bj14Find(id); if (!run) return;
  bj14SelectedId = id; bj14Draft = null;
  if (run.status === "PUBLISHED") return bj14Go("SCR-077", "COMPLETED");
  return bj14Go("SCR-074", BJ14_STATE[run.status]);
}
function bj14StartClose() {
  const period = bj14PeriodToClose(); if (!period) return;
  const scopes = BJ14_POLICY.periodCloseScopes || [];
  bj14Draft = { id: "", kind: "PERIOD_CLOSE", period, cutoff: `${bj14LastDay(period)}/${period} · 23:59`, status: "NOT_CALCULATED", scopeLabel: "", scopeId: scopes.length === 1 ? scopes[0].id : "", lines: [] };
  return bj14Go("SCR-074", "NOT_CALCULATED");
}
function bj14DoCalculate() {
  let run = bj14Current();
  if (run === bj14Draft) { if (!run.scopeId && (BJ14_POLICY.periodCloseScopes || []).length > 1) return; run = bj14CreateClose(run); }
  bj14Calculate(run); bj14Sync(run);
  return bj14Rerender();
}
function bj14DoRecalculate() {
  const run = bj14Current(); if (bj14Blockers(run).length) return;
  const next = bj14Successor(run); bj14Calculate(next); bj14Sync(next);
  return bj14Rerender();
}
function bj14DoSuccessor() {
  const next = bj14Successor(bj14Current()); bj14Calculate(next); bj14Sync(next);
  return bj14Rerender();
}
function bj14OpenSheet(name, opener) {
  bj14Ui.sheet = name; bj14Ui.opener = opener;
  if (name === "publish") { const run = bj14Current(); if (run.status !== "READY_FOR_REVIEW") { bj14Ui.sheet = null; return; } bj14Ui.reviewVersion = run.inputVersion; }
  renderAppScreen();
  requestAnimationFrame(() => bj14Focus('#app-screen [role="dialog"] button'));
}
function bj14CloseSheet() { const back = bj14Ui.opener; bj14Ui.sheet = null; bj14Rerender(back); }
// Công bố kiểm lại đầu vào lúc bấm, không chỉ lúc mở sheet: đổi giữa chừng thì đóng sheet, kết quả cũ không còn công bố được.
function bj14Publish() {
  const run = bj14Current();
  if (bj14Ui.reviewVersion !== run.inputVersion) { run.status = "INPUT_CHANGED"; bj14Ui.sheet = null; bj14Sync(run); return renderAppScreen(); }
  bj14Commit(run);
  return bj14Go("SCR-077", "COMPLETED");
}
// Việc chặn xử lý ở BJ khác (BJ-03 / 11 / 16): nhớ lần tính để màn kết quả của BJ đó có "Về giá vốn" (lần kế tiếp nếu lần này đã bị thay).
let bj14ReturnRunId = "";
const bj14ReturnAction = () => (bj14ReturnRunId ? { label: "Về giá vốn", attr: "data-bj14-back-to-cost" } : null);
function bj14BackToCost() {
  let run = bj14Find(bj14ReturnRunId); bj14ReturnRunId = "";
  if (!run) return;
  for (let n = bj14Runs.find((x) => x.supersedes === run.id); n; n = bj14Runs.find((x) => x.supersedes === run.id)) run = n;
  bj14SelectedId = run.id; bj14Draft = null;
  if (run.status === "PUBLISHED") { bj14Known("SCR-077", "COMPLETED"); return crSwitchFlow("UIF-14", "SCR-077", "COMPLETED"); }
  const state = BJ14_STATE[run.status] || "READY";
  bj14Known("SCR-074", state); return crSwitchFlow("UIF-14", "SCR-074", state);
}
document.addEventListener("click", (event) => {
  if (!event.target.closest?.("[data-bj14-back-to-cost]")) return;
  event.preventDefault(); event.stopPropagation(); bj14BackToCost();
}, true);
function bj14ToCorrection(id) {
  const direct = window.__T7_DIRECT_CONTEXTS__?.["bj11-approval"]; if (!direct) return;
  direct(id);
  return crSwitchFlow("UIF-11", "SCR-051", "READY");
}
function bj14ToCase(id) {
  const c = cr16Cases.find((x) => x.id === id); if (!c) return;
  cr16SelectedId = id;
  return crSwitchFlow("UIF-16", "SCR-079", cr079StateFor16(c));
}

document.addEventListener("keydown", (event) => {
  if (activeFlowId !== "UIF-14") return;
  const t = event.target;
  // Thẻ chọn phạm vi là nhóm radio: mũi tên đổi lựa chọn và chuyển focus.
  if (/^Arrow(Down|Right|Up|Left)$/.test(event.key) && t.matches?.("[data-bj14-scope]") && bj14Draft) {
    event.preventDefault();
    const keys = (BJ14_POLICY.periodCloseScopes || []).map((s) => s.id), step = /Down|Right/.test(event.key) ? 1 : -1;
    bj14Draft.scopeId = keys[(keys.indexOf(t.dataset.bj14Scope) + step + keys.length) % keys.length];
    return bj14Rerender(`[data-bj14-scope="${bj14Draft.scopeId}"]`);
  }
}, true);

onDialogClose["UIF-14"] = () => {
  if (!(bj14Ui.sheet)) return false;
  bj14CloseSheet(); return true;
};

document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-14") return;
  const t = event.target, hit = (sel) => t.closest?.(sel);
  let el;
  if ((el = hit("[data-bj14-filter]"))) { event.preventDefault(); bj14Filter = el.dataset.bj14Filter; return bj14Rerender(`[data-bj14-filter="${bj14Filter}"]`); }
  if ((el = hit("[data-bj14-row]"))) { event.preventDefault(); return bj14OpenRun(el.dataset.bj14Row); }
  if ((el = hit("[data-bj14-scope]"))) { event.preventDefault(); if (bj14Draft) bj14Draft.scopeId = el.dataset.bj14Scope; return bj14Rerender(`[data-bj14-scope="${el.dataset.bj14Scope}"]`); }
  const a = hit("[data-bj14-action]"); if (!a) return;
  if (a.matches(".sheet-backdrop") && t !== a) return;
  event.preventDefault(); event.stopPropagation(); if (a.disabled) return;
  const k = a.dataset.bj14Action, ref = a.dataset.bj14Ref;
  if (k === "clear-filter") { bj14Filter = "TODO"; return bj14Rerender(); }
  if (k === "close-period") return bj14StartClose();
  if (k === "calculate") return bj14DoCalculate();
  if (k === "recalculate") return bj14DoRecalculate();
  if (k === "successor") return bj14DoSuccessor();
  if (k === "open-publish") return bj14OpenSheet("publish", '[data-bj14-action="open-publish"]');
  if (k === "compare-open") return bj14OpenSheet("compare", '[data-bj14-action="compare-open"]');
  if (k === "products-open") return bj14OpenSheet("products", '[data-bj14-action="products-open"]');
  if (k === "dialog-close") return bj14CloseSheet();
  if (k === "publish") return bj14Publish();
  if (k === "to-list") return bj14ToList();
  if (k === "to-report") return bj15OpenReport({ period: bj14Current().period, entry: "bj14" });
  if (k === "to-valuation") { bj14ReturnRunId = bj14Current().id; return crSwitchFlow("UIF-03", "SCR-014", "READY"); }
  if (k === "to-correction") { bj14ReturnRunId = bj14Current().id; return bj14ToCorrection(ref); }
  if (k === "to-case") { bj14ReturnRunId = bj14Current().id; return bj14ToCase(ref); }
}, true);

// Đi giữa các màn bằng navigate (kể cả nút quay lại) là đi trong luồng: trạng thái hiện tại là "đã biết", không dựng lại fixture.
["SCR-072", "SCR-074", "SCR-077"].forEach((id) => { onScreenEnter[`UIF-14:${id}`] = () => { bj14Ui.sheet = null; bj14Expected[id] = stateByScreen[id]; }; });
// Quay lại: 074 / 077 → danh sách (bản nháp chốt kỳ chưa tính thì bỏ).
onPrevious["UIF-14"] = () => {
  bj14Ui.sheet = null;
  if (activeScreenId === "SCR-072") return;
  return bj14ToList();
};

/* ---------- Lối vào ---------- */

// BJ-03 / BJ-13 "Cập nhật giá vốn": mở lần tính cập nhật trong kỳ đang chờ đúng trạng thái hiện tại (không dựng lại fixture).
// Người bấm là chủ cửa hàng (BJ-03 / BJ-13 mở bằng vai chung): vai chung thành chủ cửa hàng, nhân viên vẫn bị chặn.
onEntry["UIF-14:dirty-scope"] = () => {
  if (!["staff", "owner", "approver"].includes(currentActor())) window.__C45_QA__.setActor("owner");
  const run = bj14Runs.find((r) => r.kind === "AD_HOC" && r.status !== "PUBLISHED" && !bj14Superseded(r));
  bj14Ui.sheet = null; bj14Draft = null;
  bj14Known("SCR-072", "READY");
  if (!run) { activeScreenId = "SCR-072"; return; }
  bj14SelectedId = run.id;
  bj14Known("SCR-074", BJ14_STATE[run.status]);
};
if (activeFlowId === "UIF-14" && !requestedScreen && onEntry[`UIF-14:${entryMode}`]) onEntry[`UIF-14:${entryMode}`]();

screenAliases["UIF-14"] = Object.assign(screenAliases["UIF-14"] || {}, { "SCR-073": "SCR-074", "SCR-075": "SCR-074", "SCR-076": "SCR-074" });
{ const a = screenAliases[activeFlowId]?.[activeScreenId]; if (Array.isArray(a)) { activeFlowId = a[0]; activeScreenId = a[1]; } else if (a) activeScreenId = a; }

flowRenderers["UIF-14"] = Object.assign(flowRenderers["UIF-14"] || {}, { "SCR-072": render072BJ14, "SCR-074": render074BJ14, "SCR-077": render077BJ14 });
Object.assign(renderers, { "SCR-072": render072BJ14, "SCR-074": render074BJ14, "SCR-077": render077BJ14 });

Object.assign(window.__C45_QA__, {
  finishBJ14Calc() { return bj14FinishCalc(); },
  // Dữ liệu vào lần tính đổi (hoá đơn, giá nhập…): lần đang xem không còn công bố được.
  bumpBJ14Input() { const r = bj14Current(); r.inputVersion += 1; return r.inputVersion; },
  getBJ14() {
    const r = bj14Current(), t = bj14Totals(r);
    return { id: r.id, status: r.status, period: r.period, inputVersion: r.inputVersion, totals: { end: t.end, cogs: t.cogs, endAdj: t.endAdj, cogsAdj: t.cogsAdj }, lines: r.lines.map((l) => ({ name: l.name, end: l.qtyEnd * bj14CostOf(l), cogs: l.qtyOut * bj14CostOf(l), endAdj: l.qtyEnd * (bj14CostOf(l) - l.oldCost), cogsAdj: l.qtyOut * (bj14CostOf(l) - l.oldCost) })), official: { ...bj14Official } };
  },
});
