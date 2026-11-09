/* BJ-12 — Khởi tạo tồn đầu kỳ (UIF-12). Màn: SCR-066, 067, 068, 071.
 *
 * Bản rút gọn v5.28.0 (docs/refactor/PLAN.md mục Theme 7 → "Rút gọn 2026-11-09"; G5-1):
 * chủ cửa hàng nhập tay từng dòng (sản phẩm, lô, hạn dùng, số lượng, giá gốc) → kiểm tra → ghi nhận thẳng.
 * Bỏ so với v5.27.0: nhập bằng tệp + số kiểm soát, gửi phê duyệt / SCR-070 (K2), tình trạng "Cách ly / Hư hỏng",
 * kết quả chưa xác định (K3). Bản cũ: git show <commit trước v5.28.0>:…/app/bj12.js.
 * Khuôn dùng chung K1, K4, K7 → app/shared-patterns.js. Helper ac310* / cfMoney / cfField / … → app/shared-control.js.
 */

let cf12Cutoff = "2026-08-31";
let cf12AddOpen = false;
let cf12Draft = { sku: "SP-000184", lot: "", expiry: "", qty: "", unitCost: "" };
let cf12DraftError = "";
const cf12Ref = "OB-2026-0001";

// Sản phẩm chọn được khi thêm dòng (khớp bj01Products: tên / mã / ĐVT / theo lô) để hành trình chặng 1 liền mạch.
const cf12Products = [
  { sku: "SP-000184", name: "Nobivac DHPPi", uom: "hộp", lot: true },
  { sku: "SP-000066", name: "Amox 500", uom: "hộp", lot: false },
  { sku: "SP-000122", name: "Tylosin 20%", uom: "lọ", lot: true },
  { sku: "SP-000147", name: "Oxytetracycline LA", uom: "chai", lot: false },
];
// Dòng đã nhập (fixture mở màn); "Thêm dòng" đẩy thêm vào đây.
const cf12Lines = [
  { sku: "SP-000184", name: "Nobivac DHPPi", uom: "hộp", lot: "DH2507", expiry: "30/11/2026", qty: 70, unitCost: 118000 },
  { sku: "SP-000184", name: "Nobivac DHPPi", uom: "hộp", lot: "DH2509", expiry: "30/09/2026", qty: 50, unitCost: 118000 },
  { sku: "SP-000066", name: "Amox 500", uom: "hộp", lot: "", expiry: "", qty: 48, unitCost: 86000 },
  { sku: "SP-000122", name: "Tylosin 20%", uom: "lọ", lot: "TY2511", expiry: "11/2027", qty: 18, unitCost: 72000 },
  { sku: "SP-000147", name: "Oxytetracycline LA", uom: "chai", lot: "", expiry: "", qty: 31, unitCost: 95000 },
];
// Lỗi kiểm tra (trạng thái VALIDATION_FAILED của 068): lỗi nhập tay, sửa ngay trên dòng.
const cf12Issues = [
  { row: 2, product: "Nobivac DHPPi", error: "Thiếu hạn dùng của lô DH2509", fix: "Điền hạn dùng cho dòng" },
  { row: 6, product: "Amox 500", error: "Trùng sản phẩm với dòng 3", fix: "Gộp hai dòng hoặc xoá một dòng" },
];

const cf12CutoffValid = () => /^\d{4}-\d{2}-\d{2}$/.test(cf12Cutoff);
const cf12Exit = () => k1ExitAttr("SCR-066");
function cf12Summary() {
  return {
    rows: cf12Lines.length,
    products: new Set(cf12Lines.map((r) => r.sku)).size,
    qty: cf12Lines.reduce((s, r) => s + r.qty, 0),
    value: cf12Lines.reduce((s, r) => s + r.qty * r.unitCost, 0),
  };
}

// Màn chỉ có banner + vài thẻ: giữ cột hẹp giữa khung web thay vì kéo giãn 1120px.
function cf12Narrow(html, size = "") { return `<div class="cf12-narrow${size ? ` cf12-narrow--${size}` : ""}">${html}</div>`; }
function cf12Out(html) { return ac310SanitizeMarkup(html); }
function cf12Shell(opts) { return appShell({ ...opts, extraClass: "k7-wide" }); }

/* ---------- Thành phần dùng ở nhiều màn ---------- */

// Dải số một hàng (BJ-04, BJ-08 dùng lại).
function cf12Strip(items) {
  return `<div class="cf12-strip" data-composed-from="DS v2 / Metric Card">${items.map(([n, label], i) => `${i ? '<span class="cf12-strip__dot" aria-hidden="true">·</span>' : ""}<span class="cf12-strip__item"><strong>${esc(n)}</strong> ${esc(label)}</span>`).join("")}</div>`;
}
function cf12SummaryRows() {
  const s = cf12Summary();
  return [["Kho", "Kho trung tâm"], ["Ngày chốt", cfDateVN(cf12Cutoff), true], ["Sản phẩm", `${cfNumber(s.products)} sản phẩm`], ["Dòng", `${cfNumber(s.rows)} dòng`], ["Tổng số lượng", cfNumber(s.qty)], ["Tổng giá trị", cfMoney(s.value), true]];
}
function cf12LineMobileRow(r) {
  const sub = [r.sku, r.lot ? `Lô ${r.lot}` : "Không theo lô", r.expiry ? `HSD ${r.expiry}` : "", `Giá gốc ${cfMoney(r.unitCost)}`].filter(Boolean).join(" · ");
  return ac310RecordRow({ title: `${r.name} · ${cfNumber(r.qty)} ${r.uom}`, subtitle: sub, leading: null });
}
// Bảng dòng đã nhập (067 nhập liệu, 068 rà soát).
function cf12LinesTable(caption = "Dòng tồn đầu kỳ") {
  const rows = cf12Lines.map((r, i) => ({ ...r, no: i + 1, product: `<strong>${esc(r.name)}</strong><small>${esc(r.sku)}</small>`, lotHtml: r.lot ? `${esc(r.lot)}<small>${esc(r.expiry)}</small>` : '<span class="k7-muted">—</span>', qtyText: `${cfNumber(r.qty)} ${r.uom}`, costText: cfMoney(r.unitCost), valueText: cfMoney(r.qty * r.unitCost) }));
  const columns = [{ key: "no", label: "Dòng", mono: true }, { key: "product", label: "Sản phẩm", html: true }, { key: "lotHtml", label: "Lô / hạn dùng", html: true }, { key: "qtyText", label: "Số lượng", align: "end", mono: true }, { key: "costText", label: "Giá gốc", align: "end", mono: true }, { key: "valueText", label: "Thành tiền", align: "end", mono: true }];
  return k7Table({ columns, rows, mobileRow: cf12LineMobileRow, caption, footer: `${rows.length} dòng`, empty: { title: "Chưa có dòng nào", description: "Thêm từng sản phẩm đang có trong kho.", actionLabel: "Thêm dòng", actionAttr: 'data-cf12-action="open-add"' } });
}
function cf12AddSheet() {
  if (!cf12AddOpen) return "";
  const close = 'data-cf12-action="close-add"';
  const p = cf12Products.find((x) => x.sku === cf12Draft.sku) || cf12Products[0];
  const options = cf12Products.map((x) => `<option value="${x.sku}" ${x.sku === p.sku ? "selected" : ""}>${esc(x.name)} · ${esc(x.sku)}</option>`).join("");
  const select = `<label class="cf-field"><span class="cf-field__label">Sản phẩm</span><select class="cf-field__input" data-cf12-draft="sku" aria-label="Sản phẩm">${options}</select></label>`;
  const lotFields = p.lot ? `${cfField("Mã lô", cf12Draft.lot, 'data-cf12-draft="lot" aria-label="Mã lô"', "text", "Sản phẩm quản lý theo lô.")}${cfField("Hạn dùng", cf12Draft.expiry, 'data-cf12-draft="expiry" aria-label="Hạn dùng"', "text", "dd/mm/yyyy, mm/yyyy hoặc yyyy.")}` : "";
  const error = cf12DraftError ? `<small class="field-error" role="alert">${esc(cf12DraftError)}</small>` : "";
  const body = `<div class="ac310-form-stack">${select}${lotFields}${cfField(`Số lượng (${p.uom})`, cf12Draft.qty, 'data-cf12-draft="qty" aria-label="Số lượng"', "number", "Số đang có thực tế.")}${cfField("Giá gốc một đơn vị", cf12Draft.unitCost, 'data-cf12-draft="unitCost" aria-label="Giá gốc một đơn vị"', "money", "Giá nhập đã gồm VAT và chi phí mua.")}</div>${error}`;
  return `<div class="sheet-backdrop" ${close}><section class="bottom-sheet cf12-add-sheet" role="dialog" aria-modal="true" aria-label="Thêm dòng tồn đầu kỳ" onclick="event.stopPropagation()" data-ds-component="VBottomSheet"><div class="sheet-handle"></div><div class="sheet-title"><h3>Thêm dòng</h3></div><div class="sheet-divider"></div><div class="sheet-content">${body}<div class="sheet-actions">${cfSecondary("Huỷ", close)}<button class="button button--primary" type="button" data-cf12-action="confirm-add" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.primary">Thêm</button></div></div></section></div>`;
}

/* ---------- SCR-066 Khởi tạo tồn kho ---------- */

function render066BJ12(state) {
  const title = "Khởi tạo tồn kho";
  if (state === "READY") {
    const prepare = `<section class="ac310-surface cf12-prepare" data-layout-pattern="Grouped surface"><div class="ac310-surface__head"><h2>Cần chuẩn bị</h2></div><ul class="cf12-prepare__list"><li>${icon("package", "icon--sm")}<span><strong>Danh sách hàng đang có: sản phẩm, lô, hạn dùng, số lượng</strong></span></li><li>${icon("layers", "icon--sm")}<span><strong>Giá gốc từng sản phẩm</strong></span></li><li>${icon("calendar", "icon--sm")}<span><strong>Ngày chốt số dư</strong></span></li></ul></section>`;
    return cf12Out(cf12Shell({ title, body: cf12Narrow(`<p class="cf12-lead">Nhập số tồn hiện có của cửa hàng một lần để bắt đầu dùng Kho.</p>${prepare}<p class="ac310-note">Sau khi ghi nhận, chênh lệch về sau được xử lý bằng kiểm kê.</p>`), actions: primaryFooter("Bắt đầu", 'data-cf12-action="start"'), back: false }));
  }
  if (state === "PREPARING") return cf12Out(cf12Shell({ title, body: cf12Narrow(`${vBanner("info", "Đang nhập số dư đầu kỳ", "Các dòng đã nhập được giữ lại. Tiếp tục nhập rồi kiểm tra trước khi ghi nhận.")}${ac310InfoSurface("Đã nhập", cf12SummaryRows())}`), actions: primaryFooter("Tiếp tục nhập", 'data-cf12-action="continue-prepare"'), back: false }));
  if (state === "ACTIVE_RECONCILED") return cf12Out(k4Result({ screenTitle: title, title: "Tồn kho đầu kỳ đã sẵn sàng", description: "Số dư đầu kỳ đã được ghi nhận.", facts: [["Ngày chốt", cfDateVN(cf12Cutoff)], ["Sản phẩm", `${cfNumber(cf12Summary().products)} sản phẩm`]], next: [{ label: "Xem tồn kho", attr: 'data-cf12-action="see-inventory"', primary: true }] }));
  if (state === "PERMISSION_DENIED") return cf12Out(cf12Shell({ title, body: k1Denied({ what: "khởi tạo tồn kho", next: "Chỉ chủ cửa hàng mới khởi tạo được tồn đầu kỳ.", exitAttr: cf12Exit() }), centered: true, back: false }));
  return cf12Out(cf12Shell({ title, body: cf12Narrow(k1Loading({ blocks: ["heading", "card", "row", "row"] })), back: false }));
}

/* ---------- SCR-067 Dữ liệu tồn kho đầu kỳ (nhập tay) ---------- */

function render067BJ12(state) {
  const title = "Dữ liệu tồn kho đầu kỳ";
  if (["READY", "VALIDATION_ERROR"].includes(state)) {
    const invalid = state === "VALIDATION_ERROR";
    const cutoffErr = invalid && !cf12CutoffValid() ? "Chọn ngày chốt số dư" : "";
    const emptyErr = invalid && !cf12Lines.length ? vBanner("error", "Chưa có dòng nào", "Thêm ít nhất một sản phẩm trước khi kiểm tra.") : "";
    const head = `<div class="ac310-form-stack">${cfField("Ngày chốt số dư", cf12Cutoff, 'data-cf12-cutoff aria-label="Ngày chốt số dư"', "date", "Ngày mà số tồn này có hiệu lực.", cutoffErr)}</div>`;
    const add = `<button class="button button--secondary" type="button" data-cf12-action="open-add" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary">Thêm dòng</button>`;
    const main = `${emptyErr}${head}${ac310SectionTitle("Hàng đang có")}${cf12LinesTable()}${add}`;
    const s = cf12Summary();
    const aside = `<div class="k7-web-only">${ac310InfoSurface("Tạm tính", [["Sản phẩm", `${cfNumber(s.products)} sản phẩm`], ["Tổng số lượng", cfNumber(s.qty)], ["Tổng giá trị", cfMoney(s.value), true]])}</div>`;
    return cf12Out(cf12Shell({ title, body: `${k7Split({ main, aside })}${cf12AddSheet()}`, actions: primaryFooter("Kiểm tra dữ liệu", 'data-bj12-action="cf12-check"', !cf12Lines.length) }));
  }
  if (state === "PERMISSION_DENIED") return cf12Out(cf12Shell({ title, body: k1Denied({ what: "khởi tạo tồn kho", next: "Chỉ chủ cửa hàng mới nhập được tồn đầu kỳ.", exitAttr: cf12Exit() }), centered: true }));
  if (state === "LOCKED") return cf12Out(cf12Shell({ title, body: cf12Narrow(`${k1Locked({ title: "Dữ liệu đang được ghi nhận", description: "Các dòng hiện chỉ đọc cho đến khi ghi nhận xong." })}${ac310InfoSurface("Đã nhập", cf12SummaryRows())}`) }));
  if (state === "CONFLICT") return cf12Out(cf12Shell({ title, body: cf12Narrow(`${k1Stale({ title: "Kho vừa có thay đổi", description: "Tải lại để nhập tiếp trên dữ liệu mới nhất.", actionAttr: 'data-cf12-action="reload"' })}`) }));
  return cf12Out(cf12Shell({ title, body: cf12Narrow(k1Denied({ what: "xem màn này", next: "Quay lại Kho và thử lại.", exitAttr: cf12Exit() })), centered: true }));
}

/* ---------- SCR-068 Kết quả kiểm tra dữ liệu (rà soát) ---------- */

function render068BJ12(state) {
  const title = "Kết quả kiểm tra dữ liệu";
  if (state === "VALIDATION_FAILED") {
    const table = k7Table({ columns: [{ key: "row", label: "Dòng", mono: true }, { key: "product", label: "Sản phẩm" }, { key: "error", label: "Lỗi" }, { key: "fix", label: "Cách sửa" }], rows: cf12Issues, mobileRow: cf12IssueCard, caption: "Dòng cần sửa" });
    const s = cf12Summary();
    const strip = cf12Strip([[cfNumber(s.rows + cf12Issues.length), "dòng"], [cfNumber(s.rows), "hợp lệ"], [String(cf12Issues.length), "cần sửa"]]);
    return cf12Out(cf12Shell({ title, body: cf12Narrow(`${vBanner("error", "Còn dòng chưa hợp lệ", "Chưa có gì được ghi nhận. Sửa các dòng dưới đây rồi kiểm tra lại.")}${strip}${ac310SectionTitle("Dòng cần sửa")}${table}`, "mid"), actions: primaryFooter("Sửa dữ liệu", 'data-cf12-action="back-file"') }));
  }
  if (state === "READY") {
    const summary = `<section class="ac310-surface cf12-ready-summary" data-layout-pattern="Grouped surface"><div class="ac310-surface__head"><h2>Số dư sẽ ghi nhận</h2></div><div class="ac310-info-rows">${cf12SummaryRows().map((r) => ds24InfoRow(r[0], r[1], r[2] ? "ac310-info-row--emphasis" : "")).join("")}</div></section>`;
    const actions = k4Footer([{ label: "Sửa dữ liệu", attr: 'data-cf12-action="back-file"' }, { label: "Ghi nhận", attr: 'data-bj12-action="cf12-commit"', primary: true }]);
    return cf12Out(cf12Shell({ title, body: `${vBanner("success", "Dữ liệu đã qua kiểm tra", "Ghi nhận một lần; giá gốc từng dòng thành giá vốn đầu tiên của sản phẩm.", "k7-banner--line")}${k7Split({ main: summary, aside: `${ac310SectionTitle("Dòng sẽ vào kho")}${cf12LinesTable("Dòng sẽ vào kho")}` })}`, actions }));
  }
  if (state === "PERMISSION_DENIED") return cf12Out(cf12Shell({ title, body: k1Denied({ what: "xem kết quả kiểm tra", next: "Chỉ chủ cửa hàng mới xem được kết quả kiểm tra tồn đầu kỳ.", exitAttr: cf12Exit() }), centered: true }));
  if (state === "CONFLICT") return cf12Out(cf12Shell({ title, body: cf12Narrow(`${k1Stale({ title: "Kho vừa có thay đổi", description: "Kết quả kiểm tra cũ không còn hiệu lực. Kiểm tra lại.", actionAttr: 'data-cf12-action="reload"' })}`), actions: primaryFooter("Quay lại dữ liệu", 'data-cf12-action="back-file"') }));
  return cf12Out(cf12Shell({ title, body: cf12Narrow(k1Loading({ blocks: ["heading", "card", "row", "row"] }), "mid") }));
}
// Thẻ lỗi trên iPhone: dòng "Cách sửa" nằm ngay dưới lỗi.
function cf12IssueCard(r) {
  return `<article class="cf12-issue" data-ds-component="DS v2 / List Row" data-ds-prop-type="Status"><div class="cf12-issue__head"><strong>Dòng ${esc(r.row)} · ${esc(r.product)}</strong>${ds24Badge("Cần sửa", "Warning")}</div><p class="cf12-issue__error">${esc(r.error)}</p><p class="cf12-issue__fix"><span>Cách sửa</span> ${esc(r.fix)}</p></article>`;
}

/* ---------- SCR-071 Kết quả khởi tạo tồn kho ---------- */

function render071BJ12(state) {
  const title = "Kết quả khởi tạo tồn kho";
  const s = cf12Summary();
  if (state === "PERMISSION_DENIED") return cf12Out(cf12Shell({ title, body: k1Denied({ what: "xem kết quả này", next: "Chỉ chủ cửa hàng mới xem được kết quả khởi tạo tồn kho.", exitAttr: cf12Exit() }), centered: true, back: false }));
  if (state === "PROCESSING") return cf12Out(cf12Shell({ title, body: cf12Narrow(`${loadingBody()}${vBanner("info", "Đang ghi nhận", "Không cần thực hiện thêm thao tác.")}`), centered: true, back: false }));
  if (state === "REJECTED_EXECUTION") return cf12Out(k4Result({ screenTitle: title, kind: "warning", title: "Chưa khởi tạo tồn kho", description: "Không có số dư nào được ghi nhận.", facts: [["Ngày chốt số dư", cfDateVN(cf12Cutoff)], ["Tác động tồn kho", "Không có"], ["Lý do", "Kho vừa có thay đổi trước khi ghi nhận"]], next: [{ label: "Tiếp tục nhập", attr: 'data-cf12-action="continue-prepare"', primary: true }] }));
  return cf12Out(k4Result({ screenTitle: title, title: "Đã khởi tạo tồn kho đầu kỳ", description: "Số dư đã được ghi nhận. Giá gốc từng dòng là giá vốn đầu tiên của sản phẩm.", facts: [["Mã", cf12Ref], ["Ngày chốt số dư", cfDateVN(cf12Cutoff)], ["Sản phẩm", `${cfNumber(s.products)} sản phẩm`], ["Tổng số lượng", cfNumber(s.qty)], ["Tổng giá trị", cfMoney(s.value)], ["Người ghi nhận", "Chủ cửa hàng"]], next: [{ label: "Xem tồn kho", attr: 'data-cf12-action="see-inventory"', primary: true }] }));
}

/* ---------- Xử lý sự kiện ---------- */

function cf12Commit() {
  stateByScreen["SCR-071"] = "PROCESSING"; navigate("SCR-071");
  setTimeout(() => {
    if (activeFlowId === "UIF-12" && activeScreenId === "SCR-071" && stateByScreen["SCR-071"] === "PROCESSING") {
      stateByScreen["SCR-071"] = "COMPLETED"; stateByScreen["SCR-066"] = "ACTIVE_RECONCILED";
      if (typeof ThemeApp !== "undefined") ThemeApp.setActivated(true);
      syncReviewUrl(); render();
    }
  }, 420);
}
function cf12AddDraft() {
  const p = cf12Products.find((x) => x.sku === cf12Draft.sku) || cf12Products[0];
  const qty = Number(cf12Draft.qty), cost = Number(String(cf12Draft.unitCost).replace(/[^0-9]/g, ""));
  if (p.lot && (!cf12Draft.lot.trim() || !cf12Draft.expiry.trim())) return "Nhập mã lô và hạn dùng";
  if (!(qty > 0)) return "Số lượng phải lớn hơn 0";
  if (!(cost > 0)) return "Nhập giá gốc";
  cf12Lines.push({ sku: p.sku, name: p.name, uom: p.uom, lot: p.lot ? cf12Draft.lot.trim() : "", expiry: p.lot ? cf12Draft.expiry.trim() : "", qty, unitCost: cost });
  return "";
}

document.addEventListener("input", (event) => {
  if (activeFlowId !== "UIF-12") return;
  const t = event.target;
  if (t.matches("[data-cf12-cutoff]")) { cf12Cutoff = cfDateKey(t.value); return; }
  if (t.matches("[data-cf12-draft]")) {
    const k = t.dataset.cf12Draft;
    cf12Draft[k] = k === "unitCost" ? String(t.value || "").replace(/[^0-9]/g, "") : t.value;
    if (k === "unitCost") t.value = cfMoneyInput(cf12Draft.unitCost);
    if (k === "sku") { cf12Draft.lot = ""; cf12Draft.expiry = ""; renderAppScreen(); }
  }
}, true);
onDialogClose["UIF-12"] = () => {
  if (!cf12AddOpen) return false;
  cf12AddOpen = false; renderAppScreen(); return true;
};
document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-12") return;
  const v = event.target.closest("[data-bj12-action]");
  if (v && !v.disabled) {
    event.preventDefault(); event.stopPropagation();
    const k = v.dataset.bj12Action;
    if (k === "cf12-check") {
      if (!cf12CutoffValid() || !cf12Lines.length) { stateByScreen["SCR-067"] = "VALIDATION_ERROR"; syncReviewUrl(); return renderAppScreen(); }
      stateByScreen["SCR-068"] = "READY"; return navigate("SCR-068");
    }
    if (k === "cf12-commit") return cf12Commit();
  }
  const a = event.target.closest("[data-cf12-action]");
  if (a && !a.disabled) {
    event.preventDefault(); event.stopPropagation(); const k = a.dataset.cf12Action;
    if (k === "start" || k === "continue-prepare" || k === "back-file") { stateByScreen["SCR-067"] = "READY"; return navigate("SCR-067"); }
    if (k === "open-add") { cf12AddOpen = true; cf12DraftError = ""; cf12Draft = { sku: cf12Products[0].sku, lot: "", expiry: "", qty: "", unitCost: "" }; return renderAppScreen(); }
    if (k === "close-add") { cf12AddOpen = false; return renderAppScreen(); }
    if (k === "confirm-add") { cf12DraftError = cf12AddDraft(); if (!cf12DraftError) cf12AddOpen = false; return renderAppScreen(); }
    if (k === "reload") { stateByScreen["SCR-067"] = "READY"; return navigate("SCR-067"); }
    if (k === "see-inventory") { activeFlowId = "UIF-01"; activeScreenId = "SCR-001"; stateByScreen["SCR-001"] = "READY"; syncReviewUrl(); return render(); }
  }
}, true);

// SCR-069 (gộp vào 068) và SCR-070 (duyệt, bỏ ở v5.28.0): link cũ mở 068.
screenAliases["UIF-12"] = Object.assign(screenAliases["UIF-12"] || {}, { "SCR-069": "SCR-068", "SCR-070": "SCR-068" });
{ const a = screenAliases[activeFlowId]?.[activeScreenId]; if (Array.isArray(a)) { activeFlowId = a[0]; activeScreenId = a[1]; } else if (a) activeScreenId = a; }

Object.assign(renderers, {
  "SCR-066": render066BJ12,
  "SCR-067": render067BJ12,
  "SCR-068": render068BJ12,
  "SCR-071": render071BJ12,
});

Object.assign(window.__VET45_QA__, {
  cf12LineCount() { return cf12Lines.length; },
});
