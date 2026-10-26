/* shared-problem.js — Khuôn K5 "Hàng có vấn đề" (T7-P mục 5), dựng ở BJ-09 chặng 4.
 *
 * Một danh sách chung SCR-036 "Hàng cần xử lý" cho UIF-07 / 09 / 10 và một chi tiết hàng SCR-037 cho UIF-09 / 10:
 *   fixture lô     t7Lots, t7Lot, t7LotStateLabel, t7LotTone, t7LotSub
 *   nguồn dòng     window.__T7_PROBLEM_SOURCES__ — mỗi BJ đẩy { id, rows() }; k5LotRow dựng dòng lô chuẩn; k5Rows gộp (một lô một dòng)
 *   màn            render036K5, render037K5 (đăng ký flowRenderers cuối file)
 *   thành phần     k5LotCard, k5QtyField, k5Evidence (+ k5RegisterEvidence cho chủ của ảnh), k5ShowLot, k5SetEntryFilter, k5AttentionSummary
 * Nạp sau shared-patterns.js, trước bj07.js. Không đọc biến của BJ nào ngoài các móc bj09Seed / bj09SetState / bj10StartDraft (có kiểm typeof).
 */

const T7_BUSINESS_DATE = "17/09/2026";
const K5_FLOWS = ["UIF-07", "UIF-09", "UIF-10"];
const NBSP = " ";

/* ---------- Fixture lô (chặng 4) ---------- */

const t7Lots = [
  { id: "tylo-ty2408", name: "Tylosin 20%", code: "SP-000122", lot: "TY2408", expiry: "31/07/2026", qty: 11, uom: "lọ", state: "EXPIRED", source: "", unitCost: 85000 },
  { id: "amox-am2505", name: "Amox 500", code: "SP-000066", lot: "AM2505", expiry: "31/05/2027", qty: 2, uom: "hộp", state: "QUARANTINE", source: "Từ hàng khách trả RET-260827-03", unitCost: 42000 },
  { id: "glove-nitrile", name: "Găng tay khám Nitrile", code: "SP-000271", lot: "", expiry: "", qty: 3, uom: "hộp", state: "DAMAGED", source: "Từ nhận hàng PN-260905-02", unitCost: 65000 },
  // Hỏng, chưa có giá vốn, chưa có việc đang chạy: tiêu hủy từ danh sách gặp "Cần xác lập giá trị" (PRICE_BASIS_REQUIRED) bằng luồng thật.
  { id: "vitamin-ade", name: "Vitamin ADE", code: "SP-000099", lot: "", expiry: "", qty: 2, uom: "chai", state: "DAMAGED", source: "Từ nhận hàng PN-260909-04" },
  { id: "oil-demo", name: "Dầu sát khuẩn", code: "SP-00606", lot: "L2406-T", expiry: "31/12/2027", qty: 2, uom: "chai", state: "DEMO", source: "" },
  { id: "nob-dh2507", name: "Nobivac DHPPi", code: "SP-000184", lot: "DH2507", expiry: "30/11/2026", qty: 70, uom: "hộp", state: "SELLABLE", source: "" },
];
const T7_LOTS_INITIAL = structuredClone(t7Lots);

function t7Lot(id) { return t7Lots.find((x) => x.id === id) || t7Lots[0]; }
function t7LotStateLabel(state) { return { SELLABLE: "Bán được", QUARANTINE: "Cách ly", DAMAGED: "Hỏng", DEMO: "Dùng thử", EXPIRED: "Hết hạn" }[state] || state; }
function t7LotTone(state) { return state === "EXPIRED" || state === "DAMAGED" ? "Danger" : state === "QUARANTINE" ? "Warning" : state === "DEMO" ? "Info" : "Success"; }
function t7LotAvailable(lot) { return lot.state === "SELLABLE" ? lot.qty : 0; }
function t7Qty(n, uom) { return `${n}${NBSP}${uom}`; }
// "· {n} {ĐVT}" dính nhau (khoảng trắng không ngắt): khi gãy dòng, dấu "·" không treo cuối dòng trên.
function t7LotSub(lot) { return lot.lot ? `Lô ${lot.lot} · HSD ${lot.expiry} ·${NBSP}${t7Qty(lot.qty, lot.uom)}` : t7Qty(lot.qty, lot.uom); }

/* ---------- Trạng thái và nguồn dòng ---------- */

let k5Filter = "ALL";
let k5Query = "";
let k5SelectedLotId = "amox-am2505";
const k5Problem = (window.__T7_PROBLEM_SOURCES__ = window.__T7_PROBLEM_SOURCES__ || []);

// Dòng lô chuẩn cho mọi BJ; open() là bước tiếp do BJ quyết.
function k5LotRow(lot, { job = "OPEN", task = "Chưa xử lý", suffix = "", open, pending = null, banner = null, disabled = false } = {}) {
  return {
    key: `lot:${lot.id}`, kind: "LOT", lotId: lot.id, state: lot.state,
    title: lot.name, sub: `${t7LotSub(lot)}${suffix}`,
    ref: lot.lot || "Không theo lô", expiry: lot.expiry || "—", qty: t7Qty(lot.qty, lot.uom),
    badge: { label: t7LotStateLabel(lot.state), tone: t7LotTone(lot.state) },
    job, task, open, pending, banner, disabled,
  };
}

const K5_JOB_WEIGHT = { OPEN: 0, WAITING: 1, DISPOSAL: 2 };
const K5_STATE_ORDER = { EXPIRED: 0, DAMAGED: 1, QUARANTINE: 2, DEMO: 3 };
function k5Order(r) {
  if (r.job === "DISPOSAL") return 4;
  if (r.job === "RTV") return 5;
  if (r.job === "WAITING") return 6;
  return K5_STATE_ORDER[r.state] ?? 3;
}

// Một lô một dòng: dòng có việc đang chạy (DISPOSAL > WAITING > OPEN) thắng. Yêu cầu trả không gộp.
function k5Rows() {
  const lots = new Map(), requests = [];
  for (const src of k5Problem) for (const r of src.rows()) {
    if (r.kind !== "LOT") { requests.push(r); continue; }
    const prev = lots.get(r.lotId);
    if (!prev || (K5_JOB_WEIGHT[r.job] ?? 0) > (K5_JOB_WEIGHT[prev.job] ?? 0)) lots.set(r.lotId, r);
  }
  return [...lots.values(), ...requests].map((r, i) => ({ r, i })).sort((a, b) => k5Order(a.r) - k5Order(b.r) || a.i - b.i).map((x) => x.r);
}

// Home "Cần chú ý": "{a} lô hết hạn · {b} cách ly / hỏng"; số = số dòng chip "Cần xử lý" (không đếm "Dùng thử").
function k5AttentionSummary() {
  const open = k5Rows().filter((r) => r.kind === "LOT" && r.job === "OPEN");
  const a = open.filter((r) => r.state === "EXPIRED").length;
  const b = open.filter((r) => r.state === "QUARANTINE" || r.state === "DAMAGED").length;
  if (!a && !b) return null;
  return { count: a + b, text: [a ? `${a} lô hết hạn` : "", b ? `${b} cách ly / hỏng` : ""].filter(Boolean).join(" · ") };
}

// Vào 036 từ Hub: "Trả nhà cung cấp" → chip RTV; Home "Hàng cần xử lý" → OPEN; còn lại → Tất cả.
function k5SetEntryFilter(flowId, explicit) {
  if (!K5_FLOWS.includes(flowId)) return;
  k5Query = "";
  if (typeof bj09SetState === "function") bj09SetState("SCR-036", "READY");
  k5Filter = explicit || (flowId === "UIF-07" ? "RTV" : "ALL");
}

// returnTo: màn đầu của luồng khi mở từ BJ-01 (nút quay lại về SCR-003); rỗng khi mở từ danh sách.
function k5ShowLot(lotId, returnTo = "") {
  k5SelectedLotId = lotId;
  bj09ReturnTo = returnTo;
  if (typeof bj09SetState === "function") bj09SetState("SCR-037", "READY");
  return applyEntry("UIF-09", "product-context", true);
}

/* ---------- Thành phần ---------- */

function k5LotCard({ lot, compact = false }) {
  const label = t7LotStateLabel(lot.state), tone = t7LotTone(lot.state);
  if (compact) return `<p class="k5-lot-line">${ds24Badge(label, tone)} <span>${esc(lot.name)}${lot.lot ? ` · Lô ${esc(lot.lot)}` : ""} · ${esc(t7Qty(lot.qty, lot.uom))}</span></p>`;
  const strip = `<div class="cf12-strip" data-composed-from="DS v2 / Metric Card"><span class="cf12-strip__item"><strong>${esc(t7Qty(lot.qty, lot.uom))}</strong> ${esc(label)}</span><span class="cf12-strip__dot" aria-hidden="true">·</span><span class="cf12-strip__item">Khả dụng bán <strong>${esc(t7LotAvailable(lot))}</strong></span></div>`;
  return `<section class="k5-lot-card">${ds24Badge(label, tone)}${strip}${lot.source ? `<p class="k5-note">${esc(lot.source)}</p>` : ""}</section>`;
}

// Ô số + nút "Cả n ĐVT". attr / fillAttr là thuộc tính định danh của BJ.
function k5QtyField({ value, max, uom, attr, fillAttr, error = "", label = "Số lượng" }) {
  return `<div class="k5-qty"><span class="vet45-text-style-8">${esc(label)} <span class="required">*</span></span>${k7EditCell({ value, attr, unit: uom, error, label })}<button class="button button--secondary k5-fill-button" type="button" ${fillAttr} data-ds-component="VButton">Cả ${esc(t7Qty(max, uom))}</button></div>`;
}

const k5EvidenceOwners = {};
function k5RegisterEvidence(owner, handler) { k5EvidenceOwners[owner] = handler; }
function k5SampleEvidenceData(text, heading = "Ảnh hiện trạng hàng") {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="320" height="180"><rect width="100%" height="100%" rx="12" fill="#f6f7f8"/><rect x="22" y="22" width="276" height="136" rx="8" fill="#fff" stroke="#c7cdd3"/><text x="42" y="70" font-family="Arial" font-size="16" fill="#4b5563">${esc(heading)}</text><text x="42" y="112" font-family="Arial" font-size="24" font-weight="700" fill="#111827">${esc(text)}</text></svg>`;
  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`;
}

// evidence: { file, data } hoặc null. Chép vùng ảnh của BJ-06 (bj06EvidenceZone); BJ-02 / BJ-06 chưa đổi sang hàm này.
// emptyTitle: chữ đậm khi chưa có ảnh; hint: dòng dưới tên tệp khi đã có ảnh ("" = không có dòng).
function k5Evidence({ owner, evidence, required = true, label = "Ảnh bằng chứng", error = "", emptyTitle = "Ảnh hiện trạng hàng", hint = "Ảnh sẽ gửi kèm yêu cầu duyệt" }) {
  const own = `data-k5-evidence-file data-k5-evidence-owner="${escapeAttribute(owner)}"`;
  const pick = `<label class="button button--secondary bj02-pick-file"><input ${own} type="file" accept="image/*">Chọn tệp</label>`;
  const camera = `<label class="button button--secondary bj02-pick-file"><input ${own} type="file" accept="image/*" capture="environment">Chụp ảnh</label>`;
  const has = Boolean(evidence?.file);
  const copy = has ? `<strong>${esc(evidence.file)}</strong>${hint ? `<small>${esc(hint)}</small>` : ""}` : `<strong>${esc(emptyTitle)}</strong><small class="k7-web-only">Kéo tệp vào đây hoặc Chọn tệp</small><small class="k7-mobile-only">Chụp ảnh hoặc chọn tệp có sẵn</small>`;
  const preview = evidence?.data ? `<div class="bj06-evidence-preview"><img src="${evidence.data}" alt="Ảnh bằng chứng ${esc(evidence.file)}"><span>${esc(evidence.file)}</span><button class="button button--secondary k5-evidence-clear" type="button" data-k5-evidence-clear data-k5-evidence-owner="${escapeAttribute(owner)}">Xoá ảnh</button></div>` : "";
  return `<div class="form-field bj02-evidence bj06-evidence k5-evidence${error ? " k5-evidence--error" : ""}" data-ds-component="VFileDropZone" data-figma-node="522:7507"><span class="vet45-text-style-8">${esc(label)}${required ? ' <span class="required">*</span>' : ""}</span><div class="bj02-evidence__zone">${icon("cloudUpload", "icon--24")}<span class="bj02-evidence__copy">${copy}</span><div class="k7-mobile-only"><div class="bj02-evidence__actions">${camera}${pick}</div></div><div class="k7-web-only"><div class="bj02-evidence__actions">${pick}</div></div></div>${preview}${error ? `<small class="field-error" role="alert">${esc(error)}</small>` : ""}</div>`;
}

/* ---------- SCR-036 Hàng cần xử lý (K5 + K6) ---------- */

function k5Shell(opts) { return appShell({ title: "Hàng cần xử lý", subtitle: "Hàng không bán được và yêu cầu trả nhà cung cấp", back: false, extraClass: "k7-wide", ...opts }); }

function k5SearchText(r) { return ioNormalizeSearch(`${r.title} ${r.ref} ${r.sub} ${r.lotId || ""}`); }
function k5RowAttr(r) { return `data-k5-row="${escapeAttribute(r.key)}" data-k5-search-text="${escapeAttribute(k5SearchText(r))}"`; }

function render036K5(state) {
  if (typeof bj09Seed === "function") bj09Seed("SCR-036", state);
  if (state === "PERMISSION_DENIED") return k5Shell({ body: k1Denied({ what: "xử lý hàng có vấn đề", next: "Liên hệ chủ cửa hàng để được cấp quyền.", exitAttr: k1ExitAttr("SCR-036") }), centered: true });
  if (state === "LOADING") return k5Shell({ body: k1Loading({ blocks: ["search", "row", "row", "row"] }) });
  const source = k5Rows().map((r) => ({
    ...r,
    itemHtml: `<button class="k7-row-link" type="button"${r.disabled ? " disabled" : ""}>${esc(r.title)}</button>`,
    statusHtml: ds24Badge(r.badge.label, r.badge.tone),
  }));
  const count = (key) => (key === "ALL" ? source.length : source.filter((r) => r.job === key).length);
  const items = [["ALL", "Tất cả"], ["OPEN", "Cần xử lý"], ["RTV", "Trả nhà cung cấp"], ["DISPOSAL", "Tiêu hủy"], ["WAITING", "Đang chờ"]].map(([k, l]) => [k, l, count(k)]);
  const rows = source.filter((r) => (k5Filter === "ALL" || r.job === k5Filter) && ioMatchesSearch(k5Query, `${r.title} ${r.ref} ${r.sub} ${r.lotId || ""}`));
  const mobileRow = (r) => ds24ListRow({ title: r.title, subtitle: r.sub, trailing: r.statusHtml, attrs: k5RowAttr(r), type: "Navigation", state: r.disabled ? "Disabled" : "Default", disabled: r.disabled });
  const body = k6TaskList({
    search: { value: k5Query, attr: "data-k5-search", placeholder: "Tìm sản phẩm, lô hoặc mã yêu cầu" },
    filters: { items, selected: k5Filter, attrName: "data-k5-filter" },
    columns: [
      { key: "itemHtml", label: "Hàng", html: true }, { key: "ref", label: "Lô / yêu cầu", mono: true }, { key: "expiry", label: "HSD", mono: true },
      { key: "qty", label: "Số lượng", align: "end", mono: true }, { key: "task", label: "Việc" }, { key: "statusHtml", label: "Tình trạng", html: true },
    ],
    rows: state === "EMPTY" ? [] : rows, total: state === "EMPTY" ? 0 : source.length, mobileRow, rowAttr: k5RowAttr,
    empty: { title: "Không có hàng cần xử lý", description: "Hàng hết hạn, cách ly, hỏng và yêu cầu trả nhà cung cấp sẽ hiện ở đây." },
    filterEmpty: { title: "Không có hàng phù hợp", description: "Thử đổi bộ lọc hoặc từ khóa tìm kiếm.", actionLabel: "Xem tất cả", actionAttr: 'data-k5-action="clear-filter"' },
    filterEmptyAttr: "data-k5-filter-empty",
  });
  return k5Shell({ body, centered: state === "EMPTY" });
}

/* ---------- SCR-037 Chi tiết hàng (K5) ---------- */

function k5Detail037(lot) {
  const row = k5Rows().find((r) => r.kind === "LOT" && r.lotId === lot.id);
  const running = row && row.job !== "OPEN" ? row : null;
  const expired = lot.state === "EXPIRED";
  const next = running
    ? (running.pending ? k2Pending({ approver: running.pending.approver, sentAt: running.pending.sentAt, facts: running.pending.facts || [] }) : vBanner("success", running.banner?.title || "Đã duyệt · chờ tiêu hủy", running.banner?.description || ""))
    : "";
  const rtvNote = lot.state !== "SELLABLE" ? '<p class="k5-note">Trả nhà cung cấp do bộ phận Mua hàng lập yêu cầu. Khi có yêu cầu, hàng hiện ở mục Trả nhà cung cấp.</p>' : "";
  const nextBlock = next || rtvNote ? `<section class="k5-next">${ds24SectionTitle("Việc tiếp theo")}${next}${rtvNote}</section>` : "";
  const history = `<button class="k7-row-link bj06-link" type="button" data-k5-action="history">Xem lịch sử</button>`;
  let buttons;
  if (running) buttons = [{ label: "Xem yêu cầu", attr: 'data-k5-action="view-request"', primary: true }];
  else if (expired) buttons = [{ label: "Đề nghị tiêu hủy", attr: 'data-k5-action="request-disposal"', primary: true }];
  else if (lot.state === "SELLABLE") buttons = [{ label: "Đổi tình trạng", attr: 'data-k5-action="change-state"', primary: true }];
  else if (lot.state === "DAMAGED") buttons = [{ label: "Đổi tình trạng", attr: 'data-k5-action="change-state"' }, { label: "Đề nghị tiêu hủy", attr: 'data-k5-action="request-disposal"', primary: true }];
  else buttons = [{ label: "Đề nghị tiêu hủy", attr: 'data-k5-action="request-disposal"' }, { label: "Đổi tình trạng", attr: 'data-k5-action="change-state"', primary: true }];
  return { nextBlock, history, buttons, expired };
}

function render037K5(state) {
  if (typeof bj09Seed === "function") bj09Seed("SCR-037", state);
  const title = "Chi tiết hàng";
  const shell = (o) => appShell({ extraClass: "k7-wide", ...o });
  if (state === "PERMISSION_DENIED") return shell({ title, body: k1Denied({ what: "xử lý hàng có vấn đề", next: "Liên hệ chủ cửa hàng để được cấp quyền.", exitAttr: k1ExitAttr("SCR-036") }), centered: true });
  if (state === "LOADING") return shell({ title, body: k1Loading({ blocks: ["heading", "card", "card"] }) });
  const lot = t7Lot(k5SelectedLotId);
  const subtitle = lot.lot ? `Lô ${lot.lot} · HSD ${lot.expiry}` : "Không theo lô";
  const locked = state === "LOCKED";
  const d = k5Detail037(lot);
  const notice = locked ? k1Locked({ title: "Đang thuộc phạm vi kiểm kê", description: "Thông tin chỉ đọc cho đến khi phiên kiểm kê kết thúc." })
    : d.expired ? vBanner("warning", "Lô đã hết hạn", `Hết hạn theo ngày nghiệp vụ ${T7_BUSINESS_DATE}; hệ thống tự loại khỏi khả dụng.`) : "";
  const summary = ac310KeyValueSurface("Tóm tắt", [["Sản phẩm", lot.name], ["Mã", lot.code], ["Lô", lot.lot || "Không theo lô"], ["HSD", lot.expiry || "—"], ["Nguồn", lot.source || "—"], ["Khả dụng bán", t7Qty(t7LotAvailable(lot), lot.uom)]]);
  const main = `${notice}${k5LotCard({ lot })}${locked ? "" : d.nextBlock}${d.history}`;
  const body = k7Split({ main, aside: summary, asideWebOnly: true });
  return shell({ title: lot.name, subtitle, body, actions: locked ? "" : k4Footer(d.buttons) });
}

/* ---------- Sự kiện ---------- */

function k5OnList() { return K5_FLOWS.includes(activeFlowId) && activeScreenId === "SCR-036"; }

document.addEventListener("input", (event) => {
  if (k5OnList() && event.target.matches("[data-k5-search]")) { k5Query = event.target.value; ioFilterRows("k5", k5Query); }
}, true);

document.addEventListener("change", (event) => {
  const t = event.target;
  if (!t.matches?.("[data-k5-evidence-file]")) return;
  const owner = k5EvidenceOwners[t.dataset.k5EvidenceOwner], file = t.files?.[0];
  if (!owner || !file) return;
  const reader = new FileReader();
  reader.onload = () => { owner.set({ file: file.name, data: String(reader.result || "") }); owner.rerender(); };
  reader.readAsDataURL(file);
}, true);

document.addEventListener("click", (event) => {
  const t = event.target, hit = (sel) => t.closest?.(sel);
  const clear = hit("[data-k5-evidence-clear]");
  if (clear) { event.preventDefault(); const owner = k5EvidenceOwners[clear.dataset.k5EvidenceOwner]; if (owner) { owner.set(null); owner.rerender(); } return; }
  if (!K5_FLOWS.includes(activeFlowId)) return;
  let el;
  if (k5OnList() && (el = hit("[data-k5-filter]"))) { event.preventDefault(); k5Filter = el.dataset.k5Filter; return renderAppScreen(); }
  if (k5OnList() && (el = hit("[data-k5-row]"))) {
    event.preventDefault();
    if (el.closest("[aria-disabled='true']") || el.disabled) return;
    const row = k5Rows().find((r) => r.key === el.dataset.k5Row);
    if (row && !row.disabled) row.open();
    return;
  }
  const a = hit("[data-k5-action]");
  if (!a || a.disabled) return;
  event.preventDefault();
  const k = a.dataset.k5Action;
  if (k === "clear-filter") { k5Filter = "ALL"; k5Query = ""; if (typeof bj09SetState === "function") bj09SetState("SCR-036", "READY"); return renderAppScreen(); }
  if (k === "to-list") { if (typeof bj09SetState === "function") bj09SetState("SCR-036", "READY"); return navigate("SCR-036"); }
  if (k === "change-state") { if (typeof bj09SetState === "function") bj09SetState("SCR-038", "READY"); activeFlowId = "UIF-09"; return navigate("SCR-038"); }
  if (k === "request-disposal") {
    if (typeof bj10StartDraft === "function") bj10StartDraft();
    return applyEntry("UIF-10", "request", true);
  }
  if (k === "view-request") { const row = k5Rows().find((r) => r.kind === "LOT" && r.lotId === k5SelectedLotId); if (row) row.open(); return; }
  if (k === "history") { activeFlowId = "UIF-09"; stateByScreen["SCR-056"] = "READY"; return navigate("SCR-056"); }
}, true);

Object.assign(window.__VET45_QA__, {
  // Đặt ảnh bằng chứng mẫu cho chủ ảnh (mặc định BJ-09) thay cho việc chọn tệp thật.
  setK5Evidence(owner = "bj09") {
    const h = k5EvidenceOwners[owner]; if (!h) return false;
    // Bước xác nhận đã tiêu hủy (bj10c) dùng biên bản mẫu, còn lại ảnh hiện trạng.
    const sample = owner === "bj10c" ? { file: "bien-ban-tieu-huy.jpg", data: k5SampleEvidenceData("Đã tiêu hủy", "Biên bản tiêu hủy") } : { file: "anh-hien-trang-hang.jpg", data: k5SampleEvidenceData("Bao bì móp") };
    h.set(sample); h.rerender(); return true;
  },
});

["UIF-07", "UIF-09", "UIF-10"].forEach((f) => { flowRenderers[f] = Object.assign(flowRenderers[f] || {}, { "SCR-036": render036K5 }); });
["UIF-09", "UIF-10"].forEach((f) => { flowRenderers[f] = Object.assign(flowRenderers[f] || {}, { "SCR-037": render037K5 }); });
