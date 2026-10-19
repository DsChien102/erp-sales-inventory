/* BJ-02 — Nhận hàng mua (UIF-02). Màn: SCR-006, SCR-007, SCR-008, SCR-009, SCR-084, SCR-010, SCR-011, SCR-012, SCR-013.
 *
 * Đã viết lại sạch (T7-P gói A4, 2026-10-17): mọi fixture, trạng thái, helper, hàm dựng và xử lý sự kiện của BJ-02
 * nằm ở đây. Sửa BJ-02: sửa thẳng file này.
 * Dùng chung từ app/core.js: appShell, stateBanner, deniedBody, loadingBody, emptyBody, vBanner, vBadge, resultHero,
 * icon, primaryFooter, esc, escapeAttribute, navigate, renderAppScreen, showToast, onPrevious, ownedFlows, flowMode.
 * UNKNOWN: listener bj02-verify-unknown / bj02-handoff-unknown ở file này (A10); handoff gọi bj17HandoffUnknown.
 * Còn ở hub: addPendingReviewExit / "Về Kho" (Giai đoạn 2); SCR-011/012/013 trong v360ExitTargets; v470 (A11).
 */

const supplierCatalog = [
  { id: "SUP-MINH-DUNG", name: "Minh Dũng", code: "NCC-0018" },
  { id: "SUP-AN-VIET", name: "An Việt", code: "NCC-0042" },
  { id: "SUP-PHUONG-NAM", name: "Phương Nam", code: "NCC-0067" },
];
const quickProductCatalog = [
  { id: "P-NOB-DHPP", name: "Nobivac DHPPi", sku: "NOB-DHPP", barcode: "8938500001012", baseUomId: "UOM-VIAL", baseUom: "lọ", uoms: [
      { id: "UOM-BOX", label: "hộp", conversionRatio: 10 },
      { id: "UOM-VIAL", label: "lọ", conversionRatio: 1 },
    ], trackingPolicy: "LOT", expiryRequired: true,
    priceBasisSnapshot: { kind: "OFFICIAL_COST", unitPriceVndPerBase: 8500, priceVersion: "COST-2026-09-v12", currency: "VND", fxVersion: "FX-VND-1" } },
  { id: "P-AMX-LA", name: "Amoxicillin LA", sku: "AMX-LA", barcode: "8938500002026", baseUomId: "UOM-BOTTLE", baseUom: "chai", uoms: [
      { id: "UOM-BOTTLE", label: "chai", conversionRatio: 1 },
    ], trackingPolicy: "LOT", expiryRequired: false,
    priceBasisSnapshot: { kind: "OFFICIAL_COST", unitPriceVndPerBase: 120000, priceVersion: "COST-2026-09-v21", currency: "VND", fxVersion: "FX-VND-1" } },
  { id: "P-GLOVE-N", name: "Găng tay khám Nitrile", sku: "GLOVE-N", barcode: "8938500003033", baseUomId: "UOM-BOX", baseUom: "hộp", uoms: [
      { id: "UOM-BOX", label: "hộp", conversionRatio: 1 },
    ], trackingPolicy: "NONE", expiryRequired: false,
    priceBasisSnapshot: { kind: "OFFICIAL_COST", unitPriceVndPerBase: 135000, priceVersion: "COST-2026-09-v8", currency: "VND", fxVersion: "FX-VND-1" } },
];
const documentReceiptCatalog = {
  "PN-260816-04": {
    supplier: "Minh Dũng",
    documentDate: "16/08/2026",
    sourceDocumentVersion: "PO-v7",
    sourceDocumentRef: "PN-260816-04",
    lines: [
      { id: "DOC-04-01", sourceLineId: "PO-04-01", sourceLineVersion: "v7.3", productId: "P-NOB-DHPP", uomId: "UOM-BOX", uom: "hộp", remainingReceivableQty: 120, conversionRatioSnapshot: 10, trackingPolicy: "LOT", expiryRequired: true, priceBasisSnapshot: { kind: "SOURCE_PRICE_FX", unitPriceVndPerBase: 8500, sourceRef: "PO-04-01", priceVersion: "PO-v7.3", currency: "VND", fxVersion: "FX-VND-1" } },
      { id: "DOC-04-02", sourceLineId: "PO-04-02", sourceLineVersion: "v7.1", productId: "P-AMX-LA", uomId: "UOM-BOTTLE", uom: "chai", remainingReceivableQty: 24, conversionRatioSnapshot: 1, trackingPolicy: "LOT", expiryRequired: false, priceBasisSnapshot: { kind: "SOURCE_PRICE_FX", unitPriceVndPerBase: 120000, sourceRef: "PO-04-02", priceVersion: "PO-v7.1", currency: "VND", fxVersion: "FX-VND-1" } },
    ],
  },
  "PN-260816-05": {
    supplier: "An Việt",
    documentDate: "16/08/2026",
    sourceDocumentVersion: "PO-v4",
    sourceDocumentRef: "PN-260816-05",
    partial: true,
    lines: [
      { id: "DOC-05-01", sourceLineId: "PO-05-01", sourceLineVersion: "v4.2", productId: "P-GLOVE-N", uomId: "UOM-BOX", uom: "hộp", remainingReceivableQty: 34, conversionRatioSnapshot: 1, trackingPolicy: "NONE", expiryRequired: false, priceBasisSnapshot: { kind: "SOURCE_PRICE_FX", unitPriceVndPerBase: 135000, sourceRef: "PO-05-01", priceVersion: "PO-v4.2", currency: "VND", fxVersion: "FX-VND-1" } },
    ],
  },
};
let selectedDocumentId = "PN-260816-04";
let approvalRejectReason = "";
function localDateIso(date = new Date()) {
  const y=date.getFullYear(), m=String(date.getMonth()+1).padStart(2,"0"), d=String(date.getDate()).padStart(2,"0");
  return `${y}-${m}-${d}`;
}
function formatIsoDate(value) {
  const m=String(value||"").match(/^(\d{4})-(\d{2})-(\d{2})$/);
  return m ? `${m[3]}/${m[2]}/${m[1]}` : String(value||"");
}
const BJ02_TENANT_BUSINESS_DATE = "2026-09-16";
function quickReceiptDateValid(value) { return value === BJ02_TENANT_BUSINESS_DATE; }
let bj02Header = { supplierId: null, supplier: "", businessDate: BJ02_TENANT_BUSINESS_DATE, evidence: "", evidenceRefs: [], ownershipAssertion: null };
let bj02Lines = [];
let activeReceiptLineId = null;
let lineEditorDraft = null;
let activeLotDraftId = null;
let lineClassificationExpanded = false; // legacy runtime flag; classification fields are always visible from v0.3.4
let lotClassificationExpanded = false; // legacy runtime flag; classification fields are always visible from v0.3.4
let lotManufactureExpanded = false;
let lineProductMenuOpen = false;
let quickOverviewProductQuery = "";
let quickOverviewProductMenuOpen = false;
let quickOverviewPendingProductId = null;
let quickOverviewDuplicateLineId = null;
let quickLineSequence = 1;
let supplierMenuOpen = false;
let supplierSearchQuery = "";
let bj02NumericPad = null;
let bj02ReviewOpenLineId = null;
let pendingRemoveLotId = null;
let pendingRemoveLineId = null;
let documentSearchQuery = "";
let supplierValidationVisible = false;
let lineEditorReadOnly = false;
let lineEditorDirty = false;

const BJ02_CONTEXT = {
    version: 'bj02',
    warehouse: { id: 'WH-CENTRAL', name: 'Kho trung tâm' },
    tenantBusinessDate: typeof BJ02_TENANT_BUSINESS_DATE !== 'undefined' ? BJ02_TENANT_BUSINESS_DATE : '2026-09-16',
    capabilities: {
      quickReceipt: true,
      assertOwnership: true,
      viewApprovalRiskTotal: true,
    },
    quickBlocker: null,
    submitted: {
      maker: 'Nguyễn Văn An',
      submittedAt: '16/09/2026 · 09:41',
      receiptRef: 'REC-260916-04',
    },
    recoveryEvidence: {
      checkedAt: '16/09/2026 · 09:45:18',
      submitted: { proven: true, at: '16/09/2026 · 09:41:06', actor: 'Nguyễn Văn An' },
      approval: { proven: true, at: '16/09/2026 · 09:43:22', actor: 'Trần Minh Hòa' },
      operationResult: { proven: true, at: '16/09/2026 · 09:45:02' },
      inventoryMovement: { proven: true, at: '16/09/2026 · 09:45:03', ledgerSequence: 281044 },
    },
    evidenceSheetOpen: false,
    changeSourceConfirmOpen: false,
  };

// Ensure every live document line carries source authority + conversion + price basis snapshot.
  Object.values(documentReceiptCatalog).forEach((doc)=>{
    doc.documentDate ||= doc.businessDate || '16/08/2026';
    doc.sourceDocumentVersion ||= 'v1';
    (doc.lines||[]).forEach((line)=>{
      const product=productById(line.productId);
      const uom=product?.uoms?.find((x)=>x.id===line.uomId);
      line.sourceLineVersion ||= 'v1';
      line.conversionRatioSnapshot ||= uom?.conversionRatio || 1;
      line.priceBasisSnapshot ||= product?.priceBasisSnapshot ? cloneBj02(product.priceBasisSnapshot) : null;
    });
  });
  bj02Header.businessDate=BJ02_CONTEXT.tenantBusinessDate;
  bj02Header.evidenceRefs ||= [];
  if('note' in bj02Header) delete bj02Header.note;

function bj02AcceptedPhysical(line) {
 return lineTotals(line).physicalIncrease; 
}
function bj02AcceptedPhysicalTotal() {
 return bj02Lines.reduce((n,line)=>n+bj02AcceptedPhysical(line),0); 
}
function bj02SourceRemaining(line) {
 return Math.max(0,Number(line?.remainingReceivableQty)||0); 
}
function bj02ValidPrecisionValue(value,precision='DAY') {

    const v=String(value||'').trim();
    if(!v) return false;
    if(precision==='YEAR') return /^\d{4}$/.test(v);
    if(precision==='MONTH') return /^(0?[1-9]|1[0-2])[\/\-]\d{4}$/.test(v);
    return /^(0?[1-9]|[12]\d|3[01])[\/\-](0?[1-9]|1[0-2])[\/\-]\d{4}$/.test(v);
  
}
function bj02EvidenceRefs() {

    const refs=Array.isArray(bj02Header.evidenceRefs)?bj02Header.evidenceRefs:[];
    if(refs.length) return refs;
    return bj02Header.evidence ? [{id:'EV-LEGACY-1',name:bj02Header.evidence,type:'DELIVERY_DOCUMENT'}] : [];
  
}
function bj02EvidenceLabel() {

    const refs=bj02EvidenceRefs();
    if(!refs.length) return 'Chưa có';
    if(refs.length===1) return refs[0].name;
    return `${refs.length} tệp chứng từ`;
  
}
function bj02OwnershipReady() {
 return Boolean(bj02Header.ownershipAssertion?.status==='ASSERTED'); 
}
function bj02MakeOwnershipAssertion() {

    bj02Header.ownershipAssertion={
      status:'ASSERTED',
      actorId:'USR-NVA',
      actorName:'Nguyễn Văn An',
      assertedAt:'2026-09-16T10:34:00+07:00',
      evidenceRefs:bj02EvidenceRefs().map((x)=>x.id),
      assertionVersion:'OWN-v1',
    };
  
}
function bj02EvidencePreviewSheet() {

    if(!BJ02_CONTEXT.evidenceSheetOpen) return '';
    const refs=flowMode==='quick'?bj02EvidenceRefs():[{id:documentContext().sourceDocumentRef||selectedDocumentId,name:selectedDocumentId,type:'SOURCE_DOCUMENT'}];
    return `<div class="sheet-backdrop v392-evidence-backdrop" data-v392-close-evidence><section class="bj02-review-detail-sheet v392-evidence-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="Chứng từ giao nhận" onclick="event.stopPropagation()"><div class="bj02-review-sheet-handle"></div><h2>Chứng từ giao nhận</h2><p class="bj02-review-sheet-context">Bằng chứng đã khóa theo phiên bản yêu cầu gửi duyệt.</p><div class="v392-evidence-list">${refs.map((ref)=>`<div class="v392-evidence-item" data-composed-from="VIconBox,VText"><span>${icon('fileText','icon--sm')}</span><div><strong>${esc(ref.name)}</strong><small>${ref.type==='SOURCE_DOCUMENT'?'Chứng từ nguồn':'Chứng từ giao nhận'}</small></div><button type="button" class="button button--tertiary" data-v392-preview-file>Xem</button></div>`).join('')}</div><button class="button button--secondary button--full" data-v392-close-evidence type="button" data-ds-component="VButton">Đóng</button></section></div>`;
  
}
function bj02ChangeSourceSheet() {

    if(!BJ02_CONTEXT.changeSourceConfirmOpen) return '';
    return `<div class="confirm-backdrop" data-v392-cancel-source-change><section class="confirm-dialog" data-ds-component="DS v2 / Confirmation Sheet" data-figma-node="550:1058" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><h3>Đổi chứng từ?</h3><p>Đổi chứng từ sẽ xóa dữ liệu nhận hàng đang nhập để tránh giữ lại số lượng, lô hoặc phiên bản chứng từ không còn đúng.</p><div class="confirm-dialog-actions"><button class="button button--secondary" data-v392-cancel-source-change type="button">Giữ chứng từ</button><button class="button button--primary" data-v392-confirm-source-change type="button">Đổi chứng từ</button></div></section></div>`;
  
}

function bj02SeedDocumentLines(forceApproval=false){
  flowMode="document"; selectedDocumentId="PN-260816-04";
  if(!bj02Lines.length) bj02Lines=createDocumentReceiptLines(selectedDocumentId);
  bj02Lines.forEach((line,idx)=>{
    const expected=Math.max(1,Number(line.remainingReceivableQty)||1);
    const received=expected+((forceApproval&&idx===0)?1:0);
    line.status="COMPLETED";
    line.accepted=received; line.quarantine=0; line.damaged=0; line.rejected=0; line.totalReceived=received;
    if(line.trackingPolicy==="LOT"){
      line.lots=[{id:`V360-L${idx+1}`,code:idx===0?"DH2507":"AM2507",expiry:line.expiryRequired?(idx===0?"30/11/2026":"31/12/2027"):"",manufactureDate:"",accepted:received,totalReceived:received,quarantine:0,damaged:0,rejected:0}];
    }
  });
}
function bj02HasExplicitDraftData(){
  return Array.isArray(bj02Lines) && bj02Lines.some(line=>{
    if(!line) return false;
    if(["COMPLETED","NOT_RECEIVED"].includes(line.status)) return true;
    const direct=[line.accepted,line.quarantine,line.damaged,line.rejected,line.totalReceived].some(v=>Number(v||0)>0);
    const lots=Array.isArray(line.lots) && line.lots.some(l=>[l.accepted,l.quarantine,l.damaged,l.rejected,l.totalReceived].some(v=>Number(v||0)>0) || String(l.code||"").trim());
    return direct || lots;
  });
}
function ensureBj02ReviewFixture(){
  if(activeFlowId!=="UIF-02") return;
  const st=stateByScreen[activeScreenId];
  if(activeScreenId==="SCR-084" && st==="READY" && !lineEditorDraft){
    if(!bj02Lines.length) bj02SeedDocumentLines(false);
    const line=bj02Lines[0];
    activeReceiptLineId=line?.id||null;
    lineEditorDraft=line?cloneBj02(line):null;
    activeLotDraftId=lineEditorDraft?.lots?.[0]?.id||null;
    lineEditorDirty=false; lineEditorReadOnly=false; lineProductMenuOpen=false;
    lineClassificationExpanded=false; lotClassificationExpanded=false; lotManufactureExpanded=Boolean(lineEditorDraft?.lots?.[0]?.manufactureDate);
    return;
  }
  if(activeScreenId==="SCR-010" && st==="READY"){
    // Direct Inspector entry needs a representative fixture, but an explicit
    // in-progress/user-prepared receipt must never be overwritten by review seeding.
    if(!bj02Lines.length || (!allReceiptLinesHandled() && !bj02HasExplicitDraftData())) bj02SeedDocumentLines(false);
    return;
  }
  if(activeScreenId==="SCR-011" && ["READY","APPROVAL_REQUIRED","APPROVAL_REVIEW"].includes(st)){
    if(!bj02Lines.length || !allReceiptLinesHandled() || !bj02RequiresApproval()) bj02SeedDocumentLines(true);
    return;
  }
  if(activeScreenId==="SCR-012" && ["COMPLETED","VALUATION_PENDING_RESULT"].includes(st)){
    if(!bj02Lines.length || !allReceiptLinesHandled()) bj02SeedDocumentLines(false);
  }
}

function cloneBj02(value) { return JSON.parse(JSON.stringify(value)); }
function productById(productId) { return quickProductCatalog.find((p) => p.id === productId) || null; }
function emptyLot(id = `LOT-DRAFT-${Date.now()}`) { return { id, code: "", expiry: "", expiryPrecision: "DAY", manufactureDate: "", manufacturePrecision: "DAY", accepted: 0, totalReceived: 0, quarantine: 0, damaged: 0, rejected: 0 }; }
function hydrateReceiptLine(raw) {
  const product = productById(raw.productId) || { name: "Sản phẩm", sku: "", uoms: [] };
  const quarantine = Math.max(0, Number(raw.quarantine) || 0);
  const damaged = Math.max(0, Number(raw.damaged) || 0);
  const rejected = Math.max(0, Number(raw.rejected) || 0);
  const legacyTotal = Math.max(0, Number(raw.totalReceived) || 0);
  const accepted = raw.accepted != null ? Math.max(0, Number(raw.accepted) || 0) : Math.max(0, legacyTotal - quarantine - damaged - rejected);
  const lots = cloneBj02(raw.lots || []).map((lot) => {
    const q=Math.max(0,Number(lot.quarantine)||0), d=Math.max(0,Number(lot.damaged)||0), r=Math.max(0,Number(lot.rejected)||0), legacy=Math.max(0,Number(lot.totalReceived)||0);
    return {...lot, accepted: lot.accepted != null ? Math.max(0,Number(lot.accepted)||0) : Math.max(0,legacy-q-d-r)};
  });
  return {
    ...cloneBj02(raw),
    name: raw.name || product.name,
    sku: raw.sku || product.sku,
    status: raw.status || "PENDING",
    accepted,
    totalReceived: accepted + quarantine + damaged + rejected,
    quarantine,
    damaged,
    rejected,
    lots,
  };
}
function createDocumentReceiptLines(documentId) {
  return (documentReceiptCatalog[documentId]?.lines || []).map((line) => hydrateReceiptLine(line));
}
function resetBj02Receipt(mode = flowMode) {
  activeReceiptLineId = null;
  lineEditorDraft = null;
  activeLotDraftId = null;
  lineClassificationExpanded = false;
  lotClassificationExpanded = false;
  lotManufactureExpanded = false;
  lineProductMenuOpen = false;
  quickOverviewProductQuery = "";
  quickOverviewProductMenuOpen = false;
  quickOverviewPendingProductId = null;
  quickOverviewDuplicateLineId = null;
  quickLineSequence = 1;
  supplierMenuOpen = false;
  supplierSearchQuery = "";
  bj02NumericPad = null;
  bj02ReviewOpenLineId = null;
  supplierValidationVisible = false;
  lineEditorReadOnly = false;
  lineEditorDirty = false;
  if (mode === "document") {
    documentSearchQuery = "";
    bj02Lines = createDocumentReceiptLines(selectedDocumentId);
  } else {
    bj02Lines = [];
    bj02Header = { supplierId: null, supplier: "", businessDate: BJ02_TENANT_BUSINESS_DATE, evidence: "", evidenceRefs: [], ownershipAssertion: null };
  }
}
resetBj02Receipt(flowMode);

function bj02ListRow({title, subtitle, attr="", type="Navigation", disabled=false, iconName="package"}) {
  return `<button class="bj02-ds-list-row" ${attr} data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="${type}" data-ds-prop-density="Default" data-ds-prop-state="Default" type="button" ${disabled ? "disabled" : ""}>
    <span class="bj02-ds-list-leading" data-ds-internal="DS v2 / List Row.leading">${icon(iconName, "icon--sm")}</span>
    <span class="bj02-ds-list-copy"><strong>${title}</strong><span>${subtitle}</span></span>
    <span class="bj02-ds-list-trailing" data-ds-internal="DS v2 / List Row.trailing">${type === "Selection" ? '<span class="bj02-radio-control" aria-hidden="true"></span>' : navChevron()}</span>
  </button>`;
}
function bj02RecordCard({title,supporting1,supporting2,summary,timestamp="",attr="",status=""}) {
  return `<button class="bj02-record-card" ${attr} data-ds-component="DS v2 / Record Card" data-figma-node="1001:7201" data-ds-prop-status="${status ? 'Visible':'Hidden'}" type="button">
    <span class="bj02-record-head"><strong>${title}</strong>${status ? vBadge(status,'info') : ''}</span>
    <span class="bj02-record-support secondary">${supporting1}</span>
    <span class="bj02-record-support primary">${supporting2}</span>
    <span class="bj02-record-meta"><span>${summary}</span><span>${timestamp}</span></span>
  </button>`;
}
function bj02InfoRow(label, value) {
  return `<div class="bj02-info-row" data-ds-component="DS v2 / Info Row" data-figma-node="525:351" data-ds-prop-state="Default"><span>${escapeAttribute(label)}</span><strong>${escapeAttribute(value)}</strong></div>`;
}
function bj02ReadOnlyDetail(label, value) {
  return `<div class="bj02-readonly-detail" data-composed-from="VText"><span data-ds-component="VText" data-ds-prop-style="Body/Small">${escapeAttribute(label)}</span><p data-ds-component="VText" data-ds-prop-style="Body/Default">${escapeAttribute(value)}</p></div>`;
}
function bj02KeyValueRow(label, value, emphasis = false, extraClass = "") {
  const risk = /rủi ro/i.test(String(label || ""));
  let display = value;
  if (typeof display === "string" && /^-\d/.test(display)) display = "−" + display.slice(1);
  const classes = ["bj02-key-value-row", emphasis ? "is-emphasis" : "", extraClass, risk ? "v470-kv--warning" : ""].filter(Boolean).join(" ");
  return `<div class="${classes}" data-ds-component="DS v2 / Key-value Row" data-figma-node="525:358" data-ds-prop-state="${emphasis ? "Emphasis" : "Default"}"><span>${escapeAttribute(label)}</span><strong>${escapeAttribute(display)}</strong></div>`;
}
function bj02SupplierSelectSheet(locked=false) {

    if(!supplierMenuOpen||locked) return '';
    const options=supplierCatalog.map((supplier)=>{
      const selected=supplier.id===bj02Header.supplierId;
      return `<button class="bj02-sheet-list-row${selected?' is-selected':''}" data-bj02-supplier-option="${supplier.id}" data-bj02-supplier-search-text="${escapeAttribute(`${supplier.name} ${supplier.code}`.toLowerCase())}" data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="Selection" data-ds-prop-density="Default" data-ds-prop-state="${selected?'Selected':'Default'}" type="button" role="option" aria-selected="${selected}"><span class="bj02-ds-list-leading">${icon('user','icon--sm')}</span><span class="bj02-ds-list-copy"><strong>${esc(supplier.name)}</strong><span>${esc(supplier.code)}</span></span><span class="bj02-radio-control" aria-hidden="true"></span></button>`;
    }).join('');
    return `<div class="bj02-select-backdrop" data-bj02-supplier-backdrop><section class="bj02-select-sheet" data-ds-component="DS v2 / Select Sheet" data-figma-node="550:1148" role="dialog" aria-modal="true" aria-label="Chọn nhà cung cấp"><div class="bj02-sheet-handle"></div><h2>Chọn nhà cung cấp</h2><div class="bj02-sheet-search" data-ds-component="VSearchBar" data-figma-node="522:7245"><span>${icon('search','icon--sm')}</span><input data-bj02-supplier-search value="${escapeAttribute(supplierSearchQuery)}" placeholder="Tìm tên hoặc mã nhà cung cấp" autocomplete="off" aria-label="Tìm nhà cung cấp" /></div><div class="bj02-sheet-list" data-bj02-supplier-menu role="listbox">${options}<div class="combobox-empty" data-bj02-supplier-empty hidden>Không có nhà cung cấp phù hợp. Nhà cung cấp phải được tạo trước ở Theme 3.</div></div></section></div>`;
  
}
function bj02ReceiptContext() {

    const handled=receiptHandledCount(), total=bj02Lines.length;
    const progress=total?`${handled}/${total} đã xử lý`:'Chưa có mặt hàng';
    if(flowMode==='quick') return `<section class="bj02-context-section" data-ds-component="VSection"><div class="bj02-section-heading"><strong>Thông tin lần nhận</strong><span>${progress}</span></div><div class="bj02-info-stack">${bj02InfoRow('Nhà cung cấp',currentReceiptSupplier())}${bj02InfoRow('Kho nhận',BJ02_CONTEXT.warehouse.name)}${bj02InfoRow('Ngày nhận',formatIsoDate(bj02Header.businessDate))}</div></section>`;
    return `<section class="bj02-context-section" data-ds-component="VSection"><div class="bj02-section-heading"><strong>Thông tin lần nhận</strong><span>${progress}</span></div><div class="bj02-info-stack">${bj02InfoRow('Chứng từ',selectedDocumentId)}${bj02InfoRow('Nhà cung cấp',currentReceiptSupplier())}${bj02InfoRow('Kho nhận',BJ02_CONTEXT.warehouse.name)}${bj02InfoRow('Ngày nhận',formatIsoDate(bj02Header.businessDate||BJ02_CONTEXT.tenantBusinessDate))}</div></section>`;
  
}
function bj02SourceRows() {

    if(flowMode==='quick'){
      const own=bj02OwnershipReady()?'Đã xác nhận':'Chưa xác nhận';
      return `${bj02InfoRow('Nhà cung cấp',bj02Header.supplier||'—')}${bj02InfoRow('Kho nhận',BJ02_CONTEXT.warehouse.name)}${bj02InfoRow('Ngày nhận',formatIsoDate(bj02Header.businessDate))}${bj02ReadOnlyDetail('Chứng từ giao nhận',bj02EvidenceLabel())}${bj02InfoRow('Quyền sở hữu',own)}`;
    }
    const doc=documentContext();
    return `${bj02InfoRow('Chứng từ',selectedDocumentId)}${bj02InfoRow('Nhà cung cấp',doc.supplier)}${bj02InfoRow('Kho nhận',BJ02_CONTEXT.warehouse.name)}${bj02InfoRow('Ngày chứng từ',doc.documentDate)}${bj02InfoRow('Ngày nhận',formatIsoDate(bj02Header.businessDate||BJ02_CONTEXT.tenantBusinessDate))}`;
  
}
function bj02ReviewIssue(line) {

    const t=lineTotals(line);
    if(line?.status==='NOT_RECEIVED') return {label:'Chưa nhận',tone:'warning'};
    if(line?.status!=='COMPLETED') return {label:'Chưa xong',tone:'warning'};
    if(t.rejected>0) return {label:'Có từ chối',tone:'error'};
    if(t.damaged>0) return {label:'Có hàng hỏng',tone:'error'};
    if(t.quarantine>0) return {label:'Có cách ly',tone:'warning'};
    if(flowMode==='document'&&line.remainingReceivableQty!=null&&t.physicalIncrease>bj02SourceRemaining(line)) return {label:'Vượt chứng từ',tone:'warning'};
    if(flowMode==='document'&&line.remainingReceivableQty!=null&&t.physicalIncrease<bj02SourceRemaining(line)) return {label:'Nhận một phần',tone:'info'};
    return null;
  
}
function bj02ReviewProductCount() {
  return new Set(bj02Lines.map((line) => line.productId)).size;
}
function bj02ReviewSubtitle(line) {
  const t = lineTotals(line);
  const lotCount = line.trackingPolicy === "LOT" ? (line.lots || []).filter((lot) => lotDraftTotals(lot).totalReceived > 0).length : 0;
  const issue = bj02ReviewIssue(line);
  return [line.sku || line.productId, line.uom, lotCount ? `${lotCount} lô` : "", `${t.totalReceived} ${line.uom}`].filter(Boolean).join(" · ");
}
function bj02ReviewProductBlocks(opts = {}) {
  const interactive = opts.interactive !== false;
  const e = (v) => escapeAttribute(v == null ? "" : String(v));
  function lotLines(line) {
    if (line.trackingPolicy !== "LOT") return "";
    const lots = (line.lots || []).filter((lot) => lotDraftTotals(lot).totalReceived > 0);
    if (!lots.length) return "";
    return `<span class="v471-lot-list">${lots.map((lot) => {
      const lt = lotDraftTotals(lot);
      const hsd = lot.expiry ? `<span>HSD ${e(lot.expiry)}</span>` : "";
      return `<span class="v471-lot"><b>Lô ${e(lot.code || "—")}</b><span class="v471-qty">${e(lt.totalReceived)} ${e(line.uom)}</span>${hsd}</span>`;
    }).join("")}</span>`;
  }
  if (!bj02Lines.length) return `<div class="empty-state bj02-review-empty" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("package","icon--empty-media")}</div><h3 data-ds-component="VEmptyTitle">Chưa có hàng để rà soát</h3><p data-ds-component="VEmptyDescription">Hoàn tất hàng thực nhận trước khi sang bước rà soát.</p></div>`;
  // Base row HTML (pre-v471), then apply the same DOM rewrite v471 used so innerHTML matches golden.
  const html = `<div class="bj02-review-summary-list" data-composed-from="DS v2 / List Row,VBadge">${bj02Lines.map((line) => {
    let issue = bj02ReviewIssue(line);
    if (opts.resultMode && issue && issue.label === "Vượt chứng từ") issue = { label: "Đã duyệt vượt", tone: "success" };
    const attrs = interactive ? `data-bj02-review-line="${line.id}" type="button"` : `type="button" disabled`;
    const badge = issue ? vBadge(issue.label, issue.tone === "error" ? "danger" : issue.tone) : vBadge("Đã xong", "success");
    return `<button class="bj02-review-summary-row" ${attrs} data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="Status" data-ds-prop-density="Compact" data-ds-prop-state="Default"><span class="bj02-review-summary-icon">${icon("package","icon--sm")}</span><span class="bj02-review-summary-copy"><strong>${escapeAttribute(line.name)}</strong><span>${escapeAttribute(bj02ReviewSubtitle(line))}</span></span><span class="bj02-review-summary-status">${badge}</span></button>`;
  }).join("")}</div>`;
  if (!bj02Lines.length) return html;
  const host = document.createElement("div");
  host.innerHTML = html;
  host.querySelectorAll(".bj02-review-summary-row").forEach((row, index) => {
    const line = bj02Lines[index];
    const copy = row.querySelector(".bj02-review-summary-copy");
    if (!line || !copy) return;
    const t = lineTotals(line);
    const sub = copy.querySelector(":scope > span");
    if (sub) sub.textContent = [line.sku || line.productId, `${t.totalReceived} ${line.uom}`].filter(Boolean).join(" · ");
    copy.insertAdjacentHTML("beforeend", lotLines(line));
    if (opts.resultMode) {
      const badgeEl = row.querySelector(".bj02-review-summary-status .status-badge, .bj02-review-summary-status [data-ds-component]");
      // badge already set via resultMode on issue above
    }
  });
  return host.innerHTML;
}
function bj02ReviewDetailSheet() {
  if (!bj02ReviewOpenLineId) return "";
  const line = bj02Lines.find((item) => item.id === bj02ReviewOpenLineId);
  if (!line) return "";
  const t = lineTotals(line);
  const quantityRows = [
    ["Đạt", t.accepted], ["Cách ly", t.quarantine], ["Hỏng", t.damaged], ["Từ chối", t.rejected],
  ].filter(([, value]) => Number(value) > 0).map(([label, value]) => bj02InfoRow(label, `${value} ${line.uom}`)).join("");
  const lotRows = line.trackingPolicy === "LOT" ? (line.lots || []).filter((lot) => lotDraftTotals(lot).totalReceived > 0).map((lot) => {
    const lt = lotDraftTotals(lot);
    return `<div class="bj02-review-lot-group"><div class="bj02-review-lot-title"><strong>Lô ${escapeAttribute(lot.code || "—")}</strong>${lot.expiry ? `<span>HSD ${escapeAttribute(lot.expiry)}</span>` : ""}</div>${bj02InfoRow("Số lượng", `${lt.totalReceived} ${line.uom}`)}</div>`;
  }).join("") : "";
  const issue = bj02ReviewIssue(line);
  const issueBanner = issue ? vBanner(issue.tone === "error" ? "error" : issue.tone, issue.label, "Kiểm tra lại dòng hàng này trước khi xác nhận hồ sơ.", "", "Compact") : "";
  return `<div class="sheet-backdrop bj02-review-detail-backdrop" data-bj02-review-close><section class="bj02-review-detail-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" data-ds-prop-show-title="true" role="dialog" aria-modal="true" aria-label="Chi tiết ${escapeAttribute(line.name)}" onclick="event.stopPropagation()"><div class="bj02-review-sheet-handle"></div><h2>${escapeAttribute(line.name)}</h2><p class="bj02-review-sheet-context">${escapeAttribute(line.sku || line.productId)} · ${escapeAttribute(line.uom)}</p>${issueBanner}<section class="bj02-review-detail-section" data-ds-component="VSection"><div class="bj02-review-detail-heading"><strong>Phân loại số lượng</strong><span>${t.totalReceived} ${line.uom}</span></div><div class="bj02-review-detail-rows">${quantityRows || bj02InfoRow("Tổng kiểm nhận", `${t.totalReceived} ${line.uom}`)}</div></section>${lotRows ? `<section class="bj02-review-detail-section" data-ds-component="VSection"><div class="bj02-review-detail-heading"><strong>Lô và hạn dùng</strong><span>${(line.lots || []).filter((lot) => lotDraftTotals(lot).totalReceived > 0).length} lô</span></div><div class="bj02-review-lot-list">${lotRows}</div></section>` : ""}<button class="button button--secondary button--full bj02-review-close-button" data-bj02-review-close type="button" data-ds-component="VButton">Đóng</button></section></div>`;
}
function bj02NumericValue(target, key, lotId = null) {
  if (!lineEditorDraft) return 0;
  if (target === "lot") {
    const lot = (lineEditorDraft.lots || []).find((item) => item.id === (lotId || activeLotDraftId));
    return Math.max(0, Number(lot?.[key]) || 0);
  }
  return Math.max(0, Number(lineEditorDraft[key]) || 0);
}
function openBj02NumericPad(target, key, lotId = null) {
  if (lineEditorIsReadOnly() || !lineEditorDraft) return;
  const value = bj02NumericValue(target, key, lotId);
  bj02NumericPad = { target, key, lotId: lotId || null, draft: String(value), unit: lineEditorDraft.uom || "" };
  renderAppScreen();
}
function updateBj02NumericPad(key) {
  if (!bj02NumericPad) return;
  let v = String(bj02NumericPad.draft || "0");
  if (key === "backspace") v = v.length <= 1 ? "0" : v.slice(0, -1);
  else if (/^\d$/.test(key)) v = v === "0" ? key : `${v}${key}`;
  bj02NumericPad.draft = v.replace(/^0+(?=\d)/, "") || "0";
  renderAppScreen();
}
function closeBj02NumericPad() { bj02NumericPad = null; renderAppScreen(); }
function saveBj02NumericPad() {
  if (!bj02NumericPad || !lineEditorDraft) return;
  const value = Math.max(0, Number(bj02NumericPad.draft) || 0);
  if (bj02NumericPad.target === "lot") {
    const lot = (lineEditorDraft.lots || []).find((item) => item.id === (bj02NumericPad.lotId || activeLotDraftId));
    if (lot) { lot[bj02NumericPad.key] = value; lot.totalReceived = lotDraftTotals(lot).totalReceived; }
  } else {
    lineEditorDraft[bj02NumericPad.key] = value;
    lineEditorDraft.totalReceived = lineTotals(lineEditorDraft).totalReceived;
  }
  lineEditorDirty = true;
  bj02NumericPad = null;
  renderAppScreen();
}
function bj02NumericKeypadOverlay() {
  if (!bj02NumericPad) return "";
  const labels = { accepted:"Đạt", quarantine:"Cách ly", damaged:"Hỏng", rejected:"Từ chối" };
  const keys = [["1","2","3"],["4","5","6"],["7","8","9"],["decimal","0","backspace"]];
  return `<div class="bj02-numeric-backdrop"><section class="bj02-numeric-sheet" data-ds-component="VNumericKeypadSheet" data-figma-node="1829:16196" data-ds-prop-mode="Quantity" role="dialog" aria-modal="true"><div class="bj02-numeric-handle"></div><div class="bj02-numeric-head"><div><h2>Nhập ${labels[bj02NumericPad.key] || "số lượng"}</h2><span>Đơn vị: ${escapeAttribute(bj02NumericPad.unit)}</span></div></div><div class="bj02-numeric-display">${escapeAttribute(bj02NumericPad.draft || "0")}</div><div class="bj02-keypad-grid">${keys.map((row) => `<div class="bj02-keypad-row">${row.map((key) => key === "decimal" ? `<button class="bj02-keypad-key" type="button" disabled aria-label="Đơn vị hiện tại không cho phép số lẻ">.</button>` : `<button class="bj02-keypad-key" data-bj02-numeric-key="${key}" type="button" aria-label="${key === "backspace" ? "Xóa một số" : key}">${key === "backspace" ? "⌫" : key}</button>`).join("")}</div>`).join("")}</div><div class="bj02-numeric-actions"><button class="button button--secondary" data-bj02-action="numeric-cancel" data-ds-component="VButton" type="button">Hủy</button><button class="button button--primary" data-bj02-action="numeric-save" data-ds-component="VButton" type="button">Lưu</button></div></section></div>`;
}
function render006BJ02(state) {
  if (state === "PERMISSION_DENIED") return appShell({ title: "Nhận hàng", body: deniedBody(), centered: true, back: false });
  if (state === "LOADING") return appShell({ title: "Nhận hàng", body: loadingBody(), back: false });
const doc=bj02ListRow({title:'Nhận theo chứng từ',subtitle:'Đã có chứng từ mua để đối chiếu.',attr:'data-flow="document"',disabled:state==='LOCKED',iconName:'fileText'});
    const quick=!BJ02_CONTEXT.capabilities.quickReceipt?'':bj02ListRow({title:'Nhập hàng nhanh',subtitle:BJ02_CONTEXT.quickBlocker||'Hàng đã đến, chưa có chứng từ mua.',attr:'data-flow="quick"',disabled:state==='LOCKED'||Boolean(BJ02_CONTEXT.quickBlocker),iconName:'zap'});
    return appShell({title:'Nhận hàng',body:`${stateBanner(state)}<div class="bj02-choice-stack">${doc}${quick}</div>`,back:false});
}
function render007BJ02(state) {
  if (state === "LOADING") return appShell({ title: "Chứng từ chờ nhận", body: loadingBody() });
  if (state === "PERMISSION_DENIED") return appShell({ title: "Chứng từ chờ nhận", body: deniedBody(), centered: true });
  if (state === "EMPTY") return appShell({ title: "Chứng từ chờ nhận", body: emptyBody(false), centered: true });
  const forcedFilterEmpty = state === "FILTER_EMPTY";
  const searchValue = forcedFilterEmpty ? "Không có kết quả" : documentSearchQuery;
  const search = `<div class="bj02-search" data-ds-component="VSearchBar" data-figma-node="522:7245"><span>${icon("search","icon--sm")}</span><input data-bj02-document-search value="${escapeAttribute(searchValue)}" placeholder="Tìm mã chứng từ hoặc nhà cung cấp" aria-label="Tìm chứng từ"/></div>`;
  const cards=[
    {id:"PN-260816-04",supplier:"Minh Dũng",date:"16/08/2026",summary:"2 mặt hàng đang chờ nhận",status:""},
    {id:"PN-260816-05",supplier:"An Việt",date:"16/08/2026",summary:"1 mặt hàng",status:"Đã nhận một phần"}
  ];
  const list=cards.map(x=>bj02RecordCard({title:x.id,supporting1:x.supplier,supporting2:x.summary,summary:x.status||"",timestamp:x.date,attr:`data-bj02-document-id="${x.id}" data-bj02-document-search-text="${escapeAttribute(`${x.id} ${x.supplier}`.toLowerCase())}" ${forcedFilterEmpty?'hidden':''}`})).join("");
  const noResult=`<div class="empty-state document-filter-empty" data-bj02-document-filter-empty data-ds-component="VEmptyState" ${forcedFilterEmpty?"":"hidden"}><div class="icon-box" data-ds-component="VEmptyMedia">${icon("search","icon--empty-media")}</div><h3 data-ds-component="VEmptyTitle">Không có kết quả phù hợp</h3><p data-ds-component="VEmptyDescription">Thử mã chứng từ hoặc tên nhà cung cấp khác.</p></div>`;
  return appShell({title:"Chứng từ chờ nhận",body:`${stateBanner(state)}${search}<div class="bj02-record-stack">${list}</div>${noResult}`});
}
function render008BJ02(state) {

    if(state==='PERMISSION_DENIED') return appShell({title:'Nhập hàng nhanh',body:deniedBody(),centered:true});
    const locked=state==='LOCKED', hasError=state==='VALIDATION_ERROR';
    const supplierValid=supplierCatalog.some((x)=>x.id===bj02Header.supplierId&&x.name===bj02Header.supplier.trim());
    const evidence=bj02EvidenceRefs(), evidenceReady=evidence.length>0;
    const supplierValue=supplierValid?bj02Header.supplier:'Chọn nhà cung cấp';
    const body=`${stateBanner(state)}<section class="v-section compact-section-heading" data-ds-component="VSection"><div class="v-section-copy"><h2 data-ds-component="VText">Thông tin lần nhận</h2><p data-ds-component="VText">Xác định nhà cung cấp, phạm vi nhận và chứng từ giao nhận.</p></div></section><div class="form-stack quick-source-form">
      <div class="form-field supplier-field${locked?' is-disabled':''}" data-ds-component="VSelect" data-figma-node="522:7291"><label>Nhà cung cấp <span class="required">*</span></label><button class="bj02-vselect-trigger${supplierValid?' is-filled':''}${hasError&&!supplierValid?' is-error':''}" data-bj02-open-supplier-sheet type="button" ${locked?'disabled':''}><span>${esc(supplierValue)}</span>${icon('chevronDown','icon--sm')}</button>${hasError&&!supplierValid?'<span class="field-error" data-bj02-supplier-error>Chọn nhà cung cấp trong danh sách.</span>':'<span class="field-error" data-bj02-supplier-error hidden>Chọn nhà cung cấp trong danh sách.</span>'}</div>
      <div class="form-field" data-ds-component="VTextField" data-figma-node="522:7186" data-ds-prop-state="Filled"><label>Kho nhận</label><span class="input-shell is-readonly"><input value="${esc(BJ02_CONTEXT.warehouse.name)}" disabled aria-disabled="true"/></span></div>
      <div class="form-field" data-ds-component="VTextField" data-figma-node="522:7186" data-ds-prop-state="Filled"><label>Ngày nhận</label><span class="input-shell is-readonly"><span class="bj02-date-leading">${icon('calendar','icon--sm')}</span><input value="${formatIsoDate(bj02Header.businessDate)}" disabled aria-disabled="true"/></span></div>
      <div class="form-field" data-ds-component="VFileDropZone" data-figma-node="522:7507"><label>Chứng từ giao nhận <span class="required">*</span></label><label class="file-drop-zone"><input data-bj02-evidence-file type="file" multiple ${locked?'disabled':''}/><span class="file-drop-icon">${icon('cloudUpload','icon--24')}</span><span class="file-drop-copy"><strong>${evidenceReady?'Đã chọn chứng từ':'Chọn hoặc kéo tệp'}</strong><small>${evidenceReady?'Có thể chọn lại để thay bộ chứng từ':'Phiếu giao hàng, biên bản bàn giao, vận đơn hoặc bản scan/ảnh rõ nội dung'}</small></span></label>${evidenceReady?`<div class="v392-evidence-chips">${evidence.map((x)=>`<span>${esc(x.name)}</span>`).join('')}</div>`:''}</div>
      ${vBanner('info','Xác nhận quyền sở hữu','Hệ thống lưu người xác nhận, thời điểm và chứng từ giao nhận.','','Default')}
    </div>${bj02SupplierSelectSheet(locked)}`;
    const disabled=locked||!supplierValid||!evidenceReady||!BJ02_CONTEXT.capabilities.assertOwnership;
    return appShell({title:'Nhập hàng nhanh',body,actions:primaryFooter('Xác nhận & tiếp tục','data-v392-quick-continue',disabled)});
  
}
function render010BJ02(state) {
  ensureBj02ReviewFixture();

    if(state==='PERMISSION_DENIED') return appShell({title:'Rà soát nhận hàng',body:deniedBody(),centered:true});
    const pending=state==='PENDING_APPROVAL', approverBlocked=state==='APPROVER_CONFIGURATION_MISSING';
    const requiresApproval=bj02RequiresApproval(), noLines=bj02Lines.length===0, incomplete=!noLines&&!allReceiptLinesHandled();
    const quickZero=flowMode==='quick'&&bj02AcceptedPhysicalTotal()===0;
    const disabled=pending||approverBlocked||noLines||incomplete||quickZero||(flowMode==='quick'&&!bj02OwnershipReady());
    const routeNotice=pending?vBanner('info','Đã gửi phê duyệt','Đang chờ người duyệt; tồn kho chưa thay đổi.','','Compact'):
      approverBlocked?vBanner('error','Chưa có người duyệt phù hợp','Chưa thể tạo phiếu. Cần cấu hình người duyệt đủ quyền và phạm vi rồi gửi lại trong phiên hiện tại.'):
      quickZero?vBanner('error','Chưa có hàng vào tồn','Nhập hàng nhanh chỉ gửi được khi Đạt + Cách ly + Hỏng lớn hơn 0.'):
      requiresApproval?(flowMode==='quick'?vBanner('info','Cần phê duyệt trước khi ghi nhận','Nhập hàng nhanh luôn cần người duyệt độc lập. Tồn kho chưa thay đổi.','','Compact'):vBanner('warning','Lượng vào tồn vượt chứng từ','Đạt + Cách ly + Hỏng vượt lượng còn được nhận. Hồ sơ cần phê duyệt.')):'';
    const stateNotice=['PENDING_APPROVAL','APPROVAL_REQUIRED'].includes(state)?'':stateBanner(state);
    const readiness=noLines?`<div class="empty-state bj02-review-empty" data-ds-component="VEmptyState"><div class="icon-box">${icon('package','icon--empty-media')}</div><h3>Chưa có hàng để rà soát</h3><p>Thêm và hoàn tất hàng thực nhận trước khi tiếp tục.</p></div>`:incomplete?vBanner('warning','Còn mặt hàng chưa hoàn tất','Quay lại Hàng thực nhận để hoàn tất từng mặt hàng.') : '';
    // Không cộng chéo transaction-UOM trên Review. Quantity authority vẫn ở từng Product+UOM line;
    // aggregate toàn hồ sơ chỉ dùng cho money risk sau khi normalize về base UOM.
    const physicalSummary=!noLines?`<div class="v392-quantity-summary v440-grouped-surface" data-composed-from="DS v2 / Key-value Row" data-layout-pattern="Grouped surface" data-v440-grouped-surface="auto">${bj02KeyValueRow('Mặt hàng đã xử lý',`${bj02ReviewProductCount()} mặt hàng`)}${bj02KeyValueRow('Dòng nhận hàng',`${bj02Lines.length} dòng`,true)}</div>`:'';
    const content=noLines?readiness:`<section class="bj02-review-section" data-ds-component="VSection"><div class="bj02-section-heading"><strong>Thông tin lần nhận</strong>${pending?'':`<button class="inline-edit" ${flowMode==='quick'?'data-next="SCR-008"':'data-v392-change-source'} data-ds-component="VButton" type="button">${flowMode==='quick'?'Sửa':'Đổi chứng từ'}</button>`}</div><div class="bj02-info-stack">${bj02SourceRows()}</div></section><section class="bj02-review-section" data-ds-component="VSection"><div class="bj02-section-heading"><div><strong>Hàng thực nhận</strong><span>${bj02ReviewProductCount()} mặt hàng · ${bj02Lines.length} dòng</span></div>${pending?'':'<button class="inline-edit" data-next="SCR-009" data-ds-component="VButton" type="button">Sửa</button>'}</div>${physicalSummary}<div class="bj02-review-products">${bj02ReviewProductBlocks()}</div></section>${incomplete?readiness:''}`;
    const footer=pending?'':primaryFooter(requiresApproval?'Gửi phê duyệt':'Xác nhận nhận hàng','data-action="submit"',disabled);
    return appShell({title:'Rà soát nhận hàng',body:`${stateNotice}${routeNotice}${content}${bj02ReviewDetailSheet()}${bj02ChangeSourceSheet()}`,actions:footer});
  
}
function render011BJ02(state) {
  ensureBj02ReviewFixture();

    if(state==='PERMISSION_DENIED') return appShell({title:'Phê duyệt yêu cầu nhận hàng',subtitle:'Việc dành cho người phê duyệt',body:deniedBody(),centered:true,backAction:'exit-approval'});
    const disabled=['SELF_APPROVAL_NOT_ALLOWED','APPROVAL_ALREADY_DECIDED','PROCESSING'].includes(state), decided=state==='APPROVAL_ALREADY_DECIDED';
    if(!bj02Lines.length) return appShell({title:'Phê duyệt yêu cầu nhận hàng',subtitle:'Việc dành cho người phê duyệt',body:`<div class="empty-state" data-ds-component="VEmptyState"><h3>Không có yêu cầu để duyệt</h3><p>Yêu cầu chỉ xuất hiện sau khi người lập gửi hồ sơ hợp lệ.</p></div>`,centered:true,backAction:'exit-approval'});
    const over=bj02Lines.some((line)=>flowMode==='document'&&lineAcceptedBase(line)>documentLineAllowanceBase(line));
    const reason=!decided?vBanner(flowMode==='quick'?'info':'warning','Lý do cần duyệt',flowMode==='quick'?'Nhập hàng nhanh bắt buộc phê duyệt.':over?'Lượng vào tồn vật lý vượt chứng từ nguồn.':'Hồ sơ được định tuyến theo chính sách phê duyệt.','','Compact'):approvalRejectReason?vBanner('error','Đã từ chối',approvalRejectReason):'';
    const risk=receiptRiskValue();
    const riskRow=flowMode==='quick'?'':(BJ02_CONTEXT.capabilities.viewApprovalRiskTotal&&state!=='FINANCIAL_MASKED'?bj02KeyValueRow('Tổng giá trị rủi ro',`${risk.toLocaleString('vi-VN')} đ`,true):bj02InfoRow('Tổng giá trị rủi ro','Không có quyền xem'));
    const facts=`${bj02InfoRow('Người gửi',BJ02_CONTEXT.submitted.maker)}${bj02InfoRow('Gửi lúc',BJ02_CONTEXT.submitted.submittedAt)}${riskRow}`;
    const evidenceAction=`<button class="button button--secondary button--full v392-evidence-preview" data-v392-open-evidence type="button" data-ds-component="VButton">${icon('fileText','icon--sm')} Xem chứng từ giao nhận</button>`;
    const body=`${state==='APPROVAL_REQUIRED'?'':stateBanner(state)}${reason}<section class="bj02-review-section" data-ds-component="VSection"><div class="bj02-section-heading"><strong>Thông tin lần nhận</strong></div><div class="bj02-info-stack">${bj02SourceRows()}</div>${evidenceAction}</section><section class="bj02-review-section"><div class="bj02-section-heading"><strong>Thông tin yêu cầu</strong></div><div class="bj02-info-stack">${facts}</div></section><section class="bj02-review-section"><div class="bj02-section-heading"><strong>Hàng thực nhận</strong><span>${bj02ReviewProductCount()} mặt hàng · ${bj02Lines.length} dòng</span></div><div class="bj02-review-products">${bj02ReviewProductBlocks()}</div></section>${bj02ReviewDetailSheet()}${bj02EvidencePreviewSheet()}`;
    const footer=decided?'':`<footer class="app-actions is-split approval-actions figma-sticky-footer v361-dual-footer v361-dual-footer--danger" data-ds-component="DS v2 / Sticky Footer" data-ds-prop-layout="Dual" data-figma-node="549:927" data-ds-prop-tone="Danger"><button class="button button--secondary" data-action="open-reject" data-ds-prop-tone="VComponentTone.danger" data-ds-profile="button.destructiveSecondary" type="button" ${disabled?'disabled':''}>Từ chối</button><button class="button button--primary" data-action="approve" type="button" ${disabled?'disabled':''}>Duyệt</button></footer>`;
    return appShell({title:'Phê duyệt yêu cầu nhận hàng',subtitle:`Việc dành cho người phê duyệt · ${BJ02_CONTEXT.submitted.maker} gửi`,body,actions:footer,backAction:'exit-approval'});
  
}
function render012BJ02(state) {
  ensureBj02ReviewFixture();

    if(state==='PERMISSION_DENIED') return appShell({title:'Kết quả nhận hàng',body:deniedBody(),centered:true});
    if(state==='PROCESSING') return appShell({title:'Kết quả nhận hàng',body:`<div class="loading-state" data-ds-component="VLoading"><span class="v-loading-spinner"></span><strong>Đang ghi nhận hàng</strong><p>Hệ thống đang xử lý. Bạn không cần thực hiện lại.</p></div>`});
    if(['UNKNOWN','COMMIT_UNKNOWN'].includes(state)) return appShell({title:'Kết quả nhận hàng',body:`<div class="loading-state" data-ds-component="VLoading"><span class="v-loading-spinner"></span><strong>Đang xác minh kết quả</strong><p>Không thực hiện lại thao tác nhận hàng.</p></div>${vBanner('warning','Giữ nguyên lần nhận hiện tại','Hệ thống tiếp tục đối soát kết quả của lần nhận này.')}`,actions:primaryFooter('Xác minh kết quả','data-v350-action="bj02-verify-unknown"'),centered:true,back:false});
    if(state==='REJECTED_EXECUTION') return appShell({title:'Kết quả nhận hàng',body:`<div class="empty-state result-empty" data-ds-component="VEmptyState"><h2>Chưa ghi nhận hàng</h2><p>Yêu cầu bị chặn trước khi tồn kho thay đổi.</p></div>`,centered:true});
    const physical=bj02AcceptedPhysicalTotal(), zeroImpact=physical===0;
    const hero=zeroImpact?resultHero('Đã ghi nhận kết quả lần nhận','Không có hàng vào tồn vật lý trong lần nhận này.'):resultHero('Đã ghi nhận hàng',`Đã tăng tồn vật lý theo ${bj02Lines.length} dòng hàng được xử lý.`);
    const valuation=state==='VALUATION_PENDING_RESULT'&&physical>0?vBanner('info','Đang chờ xác nhận giá','Phần Đạt chờ xác nhận giá; Cách ly/Hỏng giữ nguyên trạng thái.') : '';
    const body=`${hero}<section class="bj02-review-section result-lines-card"><div class="bj02-section-heading"><strong>Kết quả theo dòng hàng</strong></div><div class="bj02-review-products">${bj02ReviewProductBlocks({interactive:false, resultMode:true})}</div></section>${valuation}`;
    return appShell({title:'Kết quả nhận hàng',body,actions:primaryFooter('Xong','data-action="exit-flow"')});
  
}
function render013BJ02(state) {

    if(state==='LOADING') return appShell({title:'Đối soát nhận hàng',subtitle:'Tự mở khi kết quả lần nhận chưa xác định',body:loadingBody()});
    if(state==='PERMISSION_DENIED') return appShell({title:'Đối soát nhận hàng',subtitle:'Tự mở khi kết quả lần nhận chưa xác định',body:deniedBody(),centered:true});
    if(state==='EMPTY') return appShell({title:'Đối soát nhận hàng',subtitle:'Tự mở khi kết quả lần nhận chưa xác định',body:`<div class="empty-state" data-ds-component="VEmptyState"><h3>Chưa có kết quả mới</h3><p>Hệ thống vẫn đang theo dõi lần nhận này. Bạn không cần tạo lại thao tác.</p></div>`,centered:true});
    const uncertain=['PROCESSING_OR_UNKNOWN','STALE'].includes(state), ev=BJ02_CONTEXT.recoveryEvidence;
    const item=(tone,ico,title,desc,meta)=>`<div class="timeline-item ${tone==='warning'?'is-warning':''}" data-ds-component="DS v2 / Timeline Item" data-figma-node="525:587"><span class="timeline-marker" data-ds-component="VIconBox" data-ds-prop-tone="VComponentTone.${tone}">${icon(ico,'icon--sm')}</span><div class="timeline-content"><strong>${title}</strong><span>${desc}</span><small>${meta}</small></div></div>`;
    let timeline='';
    if(ev.submitted.proven) timeline+=item('neutral','fileText','Hồ sơ nhận đã được khóa',BJ02_CONTEXT.submitted.receiptRef,`${ev.submitted.at} · ${ev.submitted.actor}`);
    if((flowMode==='quick'||bj02RequiresApproval())&&ev.approval.proven) timeline+=item('success','shield','Yêu cầu đã được duyệt',`Người duyệt: ${ev.approval.actor}`,ev.approval.at);
    timeline+=uncertain?item('warning','clock','Đang xác lập kết quả cuối cùng','Kết quả của lần nhận hiện tại','Đang tiếp tục kiểm tra'):ev.operationResult.proven?item('success','check','Kết quả ghi nhận đã được xác lập','Kết quả của lần nhận hiện tại',ev.operationResult.at):'';
    timeline+=uncertain?item('warning','clock','Đang kiểm tra biến động tồn kho','Chưa có bằng chứng xác nhận biến động tồn kho đã được ghi','Không cần tạo lần nhận mới'):ev.inventoryMovement.proven?item('success','package','Biến động tồn kho đã được ghi',`${bj02Lines.length} dòng hàng · mốc sổ ${ev.inventoryMovement.ledgerSequence}`,ev.inventoryMovement.at):'';
    const status=state==='TERMINAL'?vBanner('success','Đã xác lập kết quả','Kết quả cuối cùng đã có; hệ thống sẽ đưa bạn về màn kết quả.'):`<div class="loading-state loading-state--compact" data-ds-component="VLoading"><span class="v-loading-spinner"></span><strong>Đang xác minh kết quả nhận hàng</strong><p>Chưa cần thực hiện lại lần nhận.</p></div>`;
    const body=`${status}${state==='STALE'?stateBanner('STALE'):''}<div class="as-of"><span>Lần kiểm tra gần nhất</span><strong class="mono">${ev.checkedAt}</strong></div><section class="timeline-card" data-ds-component="VSection"><div class="timeline">${timeline}</div></section>${uncertain?`<button class="button button--secondary manual-refresh" data-action="refresh" type="button">${icon('rotate','icon--sm')} Làm mới</button>`:''}`;
    return appShell({title:'Đối soát nhận hàng',subtitle:'Tự mở khi kết quả lần nhận chưa xác định',body,actions:state==='PROCESSING_OR_UNKNOWN'?primaryFooter('Xem hỗ trợ xử lý','data-v350-action="bj02-handoff-unknown"'):''});
  
}
function lineTotals(line) {
  if (!line) return { totalReceived: 0, accepted: 0, quarantine: 0, damaged: 0, rejected: 0, physicalIncrease: 0 };
  if (line.trackingPolicy === "LOT") {
    const totals = (line.lots || []).reduce((a, lot) => {
      const t = lotDraftTotals(lot);
      a.accepted += t.accepted;
      a.quarantine += t.quarantine;
      a.damaged += t.damaged;
      a.rejected += t.rejected;
      a.totalReceived += t.totalReceived;
      return a;
    }, { totalReceived: 0, accepted: 0, quarantine: 0, damaged: 0, rejected: 0 });
    totals.physicalIncrease = totals.accepted + totals.quarantine + totals.damaged;
    return totals;
  }
  const accepted = Math.max(0, Number(line.accepted) || 0);
  const quarantine = Math.max(0, Number(line.quarantine) || 0);
  const damaged = Math.max(0, Number(line.damaged) || 0);
  const rejected = Math.max(0, Number(line.rejected) || 0);
  const totalReceived = accepted + quarantine + damaged + rejected;
  return { totalReceived, accepted, quarantine, damaged, rejected, physicalIncrease: accepted + quarantine + damaged };
}
function documentLineVariance(line) {

    if(flowMode!=='document'||!line||line.remainingReceivableQty==null) return null;
    const t=lineTotals(line), allowed=bj02SourceRemaining(line);
    return {
      allowed,
      totalInspected:t.totalReceived,
      acceptedPhysical:t.physicalIncrease,
      rejected:t.rejected,
      remainingAfterAccepted:Math.max(0,allowed-t.physicalIncrease),
      inspectedOver:Math.max(0,t.totalReceived-allowed),
      acceptedPhysicalOver:Math.max(0,t.physicalIncrease-allowed),
    };
  
}
function documentVarianceFeedback(line) {

    const v=documentLineVariance(line); if(!v||v.totalInspected<=0) return '';
    if(v.acceptedPhysicalOver>0) return vBanner('warning','Lượng vào tồn vượt chứng từ',`Vào tồn vật lý ${v.acceptedPhysical} ${line.uom}, vượt ${v.acceptedPhysicalOver} ${line.uom} so với lượng còn được nhận. Hồ sơ sẽ cần phê duyệt.`,'','Compact');
    if(v.acceptedPhysical<v.allowed) return vBanner('info','Còn hàng chưa nhận',`Vào tồn vật lý ${v.acceptedPhysical} ${line.uom}; còn ${v.remainingAfterAccepted} ${line.uom} theo chứng từ nguồn.`,'','Compact');
    if(v.inspectedOver>0) return vBanner('info','Có lượng từ chối ngoài số vào tồn',`Tổng kiểm nhận ${v.totalInspected} ${line.uom}; vào tồn vật lý ${v.acceptedPhysical} ${line.uom}. Lượng từ chối không làm tăng tồn.`,'','Compact');
    return '';
  
}
function quantityFeedback(totals) {
  if (!totals || totals.totalReceived > 0) return "";
  return `<p class="balance-status-text">Nhập ít nhất một phân loại số lượng để tiếp tục.</p>`;
}
function duplicateLotDraft(lotId, code) {
  const normalized = String(code || "").trim().toUpperCase();
  if (!normalized || !lineEditorDraft?.lots) return null;
  return lineEditorDraft.lots.find((lot) => lot.id !== lotId && String(lot.code || "").trim().toUpperCase() === normalized) || null;
}
function lotIdentityFeedback(lot) {
  const duplicate = duplicateLotDraft(lot?.id, lot?.code);
  if (!duplicate) return "";
  const label = duplicate.code || "lô đã có";
  return `${vBanner("warning", "Lô này đã được thêm", `Mã lô ${escapeAttribute(label)} đã có trong dòng hàng. Cập nhật số lượng ở lô hiện có thay vì tạo lô trùng.`)}<button class="button button--secondary button--full" data-bj02-action="open-existing-lot" data-bj02-lot-id="${duplicate.id}" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.small" type="button">Mở lô đã có</button>`;
}
function lineHandled(line) { return line?.status === "COMPLETED" || line?.status === "NOT_RECEIVED"; }
function receiptHandledCount() { return bj02Lines.filter(lineHandled).length; }
function allReceiptLinesHandled() { return bj02Lines.length > 0 && bj02Lines.every(lineHandled); }
function documentContext() { return documentReceiptCatalog[selectedDocumentId] || documentReceiptCatalog["PN-260816-04"]; }
function currentReceiptSupplier() { return flowMode === "quick" ? bj02Header.supplier : documentContext().supplier; }
function currentReceiptEvidence() { return flowMode === "quick" ? bj02Header.evidence : selectedDocumentId; }
function classificationText(line) {
  const t = lineTotals(line);
  if (line?.status === "NOT_RECEIVED") return "Chưa nhận lần này";
  if (!t.totalReceived) return "Chưa ghi nhận";
  return [`${t.accepted} đạt`, t.quarantine ? `${t.quarantine} cách ly` : "", t.damaged ? `${t.damaged} hỏng` : "", t.rejected ? `${t.rejected} từ chối` : ""].filter(Boolean).join(" · ");
}
function lineMetaText(line) {
  const t = lineTotals(line);
  if (line.status === "NOT_RECEIVED") return "Chưa nhận lần này";
  if (line.status !== "COMPLETED") return "Chưa ghi nhận";
  const lotCount = line.trackingPolicy === "LOT" ? (line.lots || []).filter((lot) => Number(lot.totalReceived) > 0).length : 0;
  const lotText = lotCount ? `${lotCount} lô · ` : "";
  return `${lotText}${classificationText(line)}`;
}
function linePrimaryText(line) {
  const t = lineTotals(line);
  if (line.status === "NOT_RECEIVED") return flowMode === "document" ? `${line.remainingReceivableQty} ${line.uom} theo chứng từ` : "Chưa nhận";
  if (line.status !== "COMPLETED") return flowMode === "document" && line.remainingReceivableQty != null ? `Còn chờ nhận ${line.remainingReceivableQty} ${line.uom}` : `Đơn vị: ${line.uom || "—"}`;
  if (flowMode === "document" && line.remainingReceivableQty != null) {
    const expected = Math.max(0, Number(line.remainingReceivableQty) || 0);
    const delta = t.totalReceived - expected;
    if (delta < 0) return `${t.totalReceived} / ${expected} ${line.uom} · còn ${Math.abs(delta)}`;
    if (delta > 0) return `${t.totalReceived} / ${expected} ${line.uom} · vượt ${delta}`;
    return `${t.totalReceived} / ${expected} ${line.uom}`;
  }
  return `${t.totalReceived} ${line.uom}`;
}
function lineLotReviewDetails(line) {
  if (line?.trackingPolicy !== "LOT" || line?.status === "NOT_RECEIVED") return "";
  const rows = (line.lots || []).filter((lot) => Number(lot.totalReceived) > 0 || String(lot.code || "").trim()).map((lot) => {
    const t = lotDraftTotals(lot);
    const expiry = String(lot.expiry || "").trim();
    const right = [`${t.totalReceived} ${line.uom}`, expiry ? `HSD ${expiry}` : ""].filter(Boolean).join(" · ");
    return `<div class="receipt-lot-review"><span><small class="io-object-kicker">Lô</small><strong>${escapeAttribute(lot.code || "Chưa có mã lô")}</strong></span><strong>${right}</strong></div>`;
  }).join("");
  return rows ? `<div class="receipt-lot-review-list">${rows}</div>` : "";
}
function lineAcceptedBase(line) {

    const product=productById(line.productId); const uom=product?.uoms?.find((x)=>x.id===line.uomId);
    const ratio=Number(line.conversionRatioSnapshot ?? uom?.conversionRatio ?? 1)||1;
    return bj02AcceptedPhysical(line)*ratio;
  
}
function documentLineAllowanceBase(line) {

    const product=productById(line.productId); const uom=product?.uoms?.find((x)=>x.id===line.uomId);
    const ratio=Number(line.conversionRatioSnapshot ?? uom?.conversionRatio ?? 1)||1;
    return bj02SourceRemaining(line)*ratio;
  
}
function bj02RequiresApproval() {

    if(flowMode==='quick') return true;
    return bj02Lines.some((line)=>lineAcceptedBase(line)>documentLineAllowanceBase(line));
  
}
function receiptRiskValue() {

    return bj02Lines.reduce((sum,line)=>{
      const basis=line.priceBasisSnapshot || productById(line.productId)?.priceBasisSnapshot;
      return sum + lineAcceptedBase(line)*(Number(basis?.unitPriceVndPerBase)||0);
    },0);
  
}
function receiptLineCards({ review = false, includeLotDetails = review } = {}) {
  return `<div class="bj02-record-stack receipt-line-list">${bj02Lines.map((line) => {
    const t=lineTotals(line);
    const lotText=includeLotDetails && line.trackingPolicy==="LOT" ? (line.lots||[]).map(l=>`Lô ${escapeAttribute(l.code||"—")} · ${lotDraftTotals(l).totalReceived} ${line.uom}${l.expiry?` · HSD ${escapeAttribute(l.expiry)}`:""}`).join("; ") : lineMetaText(line);
    const cls=classificationText(line);
    const primary=review ? `${t.totalReceived} ${line.uom} · ${cls}` : linePrimaryText(line);
    const tag=review?'article':'button';
    return `<${tag} class="bj02-record-card receipt-line-card" ${review?'':`data-bj02-line-id="${line.id}" type="button"`} data-ds-component="DS v2 / Record Card" data-figma-node="1001:7201" data-ds-prop-status="Hidden"><span class="bj02-record-head"><strong>${line.name}</strong></span><span class="bj02-record-support secondary">${line.uom} · ${line.sku||line.productId}</span><span class="bj02-record-support primary">${primary}</span><span class="bj02-record-meta"><span>${lotText}</span><span></span></span></${tag}>`;
  }).join("")}</div>`;
}
function quickOverviewProductSearch() {
  if (flowMode !== "quick") return "";
  const options = quickProductCatalog.map((product) => {
    const uomSummary = (product.uoms || []).map((uom) => uom.label).join(", " );
    const searchText = `${product.name} ${product.sku} ${product.barcode || ""} ${uomSummary}`.toLowerCase();
    return `<button class="combobox-option bj02-search-option product-search-option quick-overview-product-option" data-bj02-overview-product-option="${product.id}" data-bj02-overview-product-search-text="${escapeAttribute(searchText)}" data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="Selection" data-ds-prop-density="Default" data-ds-prop-state="Default" type="button" role="option"><span class="bj02-search-option-leading">${icon("package","icon--sm")}</span><span class="combobox-option-copy"><strong>${escapeAttribute(product.name)}</strong><small>${escapeAttribute(product.sku)} · ${escapeAttribute(uomSummary)}</small></span><span class="bj02-radio-control" aria-hidden="true"></span></button>`;
  }).join("");
  const pendingProduct = productById(quickOverviewPendingProductId);
  const uomPicker = pendingProduct ? `<section class="quick-overview-uom-picker" data-ds-role="uom-selection-composition" data-composed-from="DS v2 / List Row"><div class="quick-overview-uom-copy"><div><strong data-ds-component="VText">${escapeAttribute(pendingProduct.name)}</strong><span data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall">${escapeAttribute(pendingProduct.sku)}</span></div><button class="inline-edit" data-bj02-action="change-overview-product" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.link" type="button">Đổi</button></div><div class="quick-uom-choice-group" role="radiogroup" aria-label="Đơn vị nhập"><span class="quick-uom-label">Đơn vị nhập <span class="required">*</span></span>${(pendingProduct.uoms || []).map((uom) => { const duplicate = duplicateQuickLine(pendingProduct.id, uom.id); return `<button class="quick-uom-choice" data-bj02-overview-uom-choice="${uom.id}" data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="Selection" data-ds-prop-density="Default" data-ds-prop-state="Default" type="button" role="radio" aria-checked="false"><span class="quick-uom-choice-copy"><strong>${escapeAttribute(uom.label)}</strong>${duplicate ? '<small>Đã có trong lần nhận</small>' : ''}</span><span class="bj02-radio-control" aria-hidden="true"></span></button>`; }).join("")}</div></section>` : "";
  return `<section class="quick-overview-add" data-ds-role="product-search-composition" data-composed-from="VSearchBar,DS v2 / List Row"><div class="quick-overview-search-wrap"><div class="search-box quick-overview-search" data-ds-component="VSearchBar" data-figma-node="522:7245" data-ds-profile="search.standard" data-ds-prop-hint-text="Tìm tên, mã sản phẩm hoặc mã vạch"><span class="search-leading">${icon("search", "icon--sm")}</span><input data-bj02-overview-product-search value="${escapeAttribute(quickOverviewProductQuery)}" placeholder="Tìm tên, mã sản phẩm hoặc mã vạch" aria-label="Tìm sản phẩm" aria-expanded="${quickOverviewProductMenuOpen}"/><span></span></div><div class="combobox-menu quick-overview-product-menu ${quickOverviewProductMenuOpen ? "is-open" : ""}" data-bj02-overview-product-menu role="listbox" ${quickOverviewProductMenuOpen ? "" : "hidden"}>${options}<div class="combobox-empty" data-bj02-overview-product-empty hidden>Sản phẩm chưa có trong danh mục. Hãy bổ sung sản phẩm trước khi quay lại nhận hàng.</div></div></div>${uomPicker}</section>`;
}
function filterQuickOverviewProductOptions(query) {
  const normalized = String(query || "").trim().toLowerCase();
  let visible = 0;
  document.querySelectorAll("[data-bj02-overview-product-search-text]").forEach((option) => {
    const show = !normalized || option.dataset.bj02OverviewProductSearchText.includes(normalized);
    option.hidden = !show;
    if (show) visible += 1;
  });
  const empty = document.querySelector("[data-bj02-overview-product-empty]");
  if (empty) empty.hidden = visible !== 0;
}
function addQuickOverviewLine(productId, uomId) {
  const product = productById(productId);
  const uom = product?.uoms?.find((item) => item.id === uomId);
  if (!product || !uom) return;
  const duplicate = duplicateQuickLine(product.id, uom.id);
  quickOverviewProductQuery = "";
  quickOverviewProductMenuOpen = false;
  quickOverviewPendingProductId = null;
  quickOverviewDuplicateLineId = null;
  if (duplicate) return beginLineEditor(duplicate.id);
  const newLine = hydrateReceiptLine({
    id: `QUICK-${quickLineSequence++}`,
    productId: product.id,
    uomId: uom.id,
    uom: uom.label,
    trackingPolicy: product.trackingPolicy,
    expiryRequired: product.expiryRequired,
    priceBasisSnapshot: cloneBj02(product.priceBasisSnapshot || null),
    remainingReceivableQty: null,
    lots: [],
  });
  bj02Lines.push(newLine);
  return beginLineEditor(newLine.id);
}
function selectQuickOverviewProduct(productId) {
  const product = productById(productId);
  if (!product) return;
  quickOverviewDuplicateLineId = null;
  quickOverviewProductMenuOpen = false;
  const uoms = product.uoms || [];
  if (uoms.length === 1) return addQuickOverviewLine(product.id, uoms[0].id);
  quickOverviewPendingProductId = product.id;
  quickOverviewProductQuery = "";
  return renderAppScreen();
}
function chooseQuickOverviewUom(uomId) {
  if (!quickOverviewPendingProductId || !uomId) return;
  return addQuickOverviewLine(quickOverviewPendingProductId, uomId);
}
function render009BJ02(state) {
  // chữ của v392, gộp ở Giai đoạn 2
  const __html = (() => {
  const entrySubtitle = entryMode === "document-context" ? `Từ chứng từ ${selectedDocumentId}` : null;
  if (state === "PERMISSION_DENIED") return appShell({ title: "Hàng thực nhận", subtitle: entrySubtitle, body: deniedBody(), centered: true });
  if (state === "EMPTY") return appShell({ title: "Hàng thực nhận", subtitle: entrySubtitle, body: `<div class="empty-state" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("package", "icon--empty-media")}</div><h3 data-ds-component="VEmptyTitle">Không có sản phẩm cần nhận</h3><p data-ds-component="VEmptyDescription">Không có dòng hàng phù hợp trong lần nhận hiện tại.</p></div>`, centered: true });
  const locked = ["LOCKED", "READ_ONLY"].includes(state);
  const empty = flowMode === "quick" && bj02Lines.length === 0 && !quickOverviewPendingProductId ? `<div class="empty-state receipt-lines-empty" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("package", "icon--empty-media")}</div><h3 data-ds-component="VEmptyTitle">Chưa có sản phẩm trong lần nhận</h3><p data-ds-component="VEmptyDescription">Tìm sản phẩm ở trên để thêm. Sản phẩm phải có sẵn trong danh mục.</p></div>` : receiptLineCards();
  const body = `
    ${stateBanner(state)}
    ${bj02ReceiptContext()}
    ${quickOverviewDuplicateLineId ? `${vBanner("warning", "Sản phẩm và đơn vị này đã có", "Dòng hàng hiện có được giữ nguyên để tránh ghi trùng trong cùng lần nhận.")}<button class="button button--secondary button--full" data-bj02-action="open-existing-overview-line" data-bj02-line-id="${quickOverviewDuplicateLineId}" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" type="button">Mở dòng hàng hiện có</button>` : ""}
    ${flowMode === "quick" && !locked ? quickOverviewProductSearch() : ""}
    ${empty}`;
  const reviewDisabled = locked || !allReceiptLinesHandled();
  return appShell({ title: "Hàng thực nhận", subtitle: entrySubtitle, body, actions: primaryFooter("Rà soát", 'data-next="SCR-010"', reviewDisabled), backAction: entryMode === "document-context" ? "exit-receipt-document-context" : "" });
  })();
  return String(__html).replaceAll('sản phẩm','mặt hàng');
}
function beginLineEditor(lineId = null) {
  activeReceiptLineId = lineId;
  lineEditorDirty = false;
  lineEditorReadOnly = ["LOCKED", "READ_ONLY"].includes(stateByScreen["SCR-009"]);
  const existing = lineId ? bj02Lines.find((line) => line.id === lineId) : null;
  if (existing) {
    lineEditorDraft = cloneBj02(existing);
  } else {
    lineEditorDraft = hydrateReceiptLine({ id: `QUICK-${Date.now()}`, productId: null, uomId: null, uom: null, trackingPolicy: null, expiryRequired: false, remainingReceivableQty: null, lots: [] });
  }
  if (lineEditorDraft?.trackingPolicy === "LOT" && !lineEditorDraft.lots.length) lineEditorDraft.lots = [emptyLot()];
  activeLotDraftId = lineEditorDraft?.lots?.[0]?.id || null;
  const lineTotalsNow = lineTotals(lineEditorDraft || {});
  lineClassificationExpanded = Boolean(lineTotalsNow.quarantine || lineTotalsNow.damaged || lineTotalsNow.rejected);
  const firstLot = lineEditorDraft?.lots?.find((lot) => lot.id === activeLotDraftId);
  const firstLotTotals = firstLot ? lotDraftTotals(firstLot) : null;
  lotClassificationExpanded = Boolean(firstLotTotals && (firstLotTotals.quarantine || firstLotTotals.damaged || firstLotTotals.rejected));
  lotManufactureExpanded = Boolean(firstLot?.manufactureDate);
  lineProductMenuOpen = !existing && flowMode === "quick";
  navigate("SCR-084");
}
function duplicateQuickLine(productId, uomId, excludingId = null) {
  return bj02Lines.find((line) => line.id !== excludingId && line.productId === productId && line.uomId === uomId) || null;
}
function lineEditorIsReadOnly() { return lineEditorReadOnly || stateByScreen["SCR-084"] === "READ_ONLY"; }
function renderLineProductPicker() {
  const selectedProduct = productById(lineEditorDraft?.productId);
  const locked = lineEditorIsReadOnly();
  const options = quickProductCatalog.map((product) => {
    const uomSummary = (product.uoms || []).map((uom) => uom.label).join(", ");
    const searchText = `${product.name} ${product.sku} ${product.barcode || ""} ${uomSummary}`.toLowerCase();
    return `<button class="combobox-option bj02-search-option product-search-option" data-bj02-product-option="${product.id}" data-bj02-product-search-text="${escapeAttribute(searchText)}" data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="Selection" data-ds-prop-density="Default" data-ds-prop-state="Default" type="button" role="option"><span class="bj02-search-option-leading">${icon("package","icon--sm")}</span><span class="combobox-option-copy"><strong>${product.name}</strong><small>${product.sku} · ${uomSummary}</small></span><span class="bj02-radio-control" aria-hidden="true"></span></button>`;
  }).join("");
  if (!selectedProduct) {
    if (locked) return `<div class="empty-state" data-ds-component="VEmptyState"><h3 data-ds-component="VEmptyTitle">Chưa có sản phẩm</h3><p data-ds-component="VEmptyDescription">Không có dữ liệu sản phẩm để hiển thị.</p></div>`;
    return `<div class="form-field combobox-html-renderer" data-ds-component="DS v2 / Search Results Dropdown" data-figma-node="1280:6272" data-ds-prop-label="Sản phẩm" data-ds-prop-hint-text="Tìm tên, mã sản phẩm hoặc mã vạch"><label>Sản phẩm <span class="required">*</span></label><div class="combobox-anchor is-open"><input data-bj02-product-search placeholder="Tìm tên, mã sản phẩm hoặc mã vạch" aria-label="Sản phẩm" aria-expanded="true"/><span class="combobox-trailing">${icon("chevronDown", "icon--sm")}</span></div><div class="combobox-menu is-open" data-bj02-product-menu role="listbox">${options}<div class="combobox-empty" data-bj02-product-empty hidden>Sản phẩm chưa có trong danh mục. Hãy bổ sung sản phẩm trước khi quay lại nhận hàng.</div></div></div>`;
  }
  const uoms = selectedProduct.uoms || [];
  const isNewQuickLine = flowMode === "quick" && !activeReceiptLineId;
  const needsUomChoice = !locked && isNewQuickLine && uoms.length > 1 && !lineEditorDraft.uomId;
  const identityMeta = [selectedProduct.sku, lineEditorDraft.uom || null].filter(Boolean).join(" · ");
  const contextLabel = flowMode === "document" && lineEditorDraft.remainingReceivableQty != null
    ? `Còn ${lineEditorDraft.remainingReceivableQty} ${lineEditorDraft.uom || ""}`.trim()
    : needsUomChoice ? "Chọn đơn vị" : "Đã chọn";
  const identityRow = ds24ContextStatusRow({
    title:selectedProduct.name,
    subtitle:identityMeta,
    label:contextLabel,
    tone:"Neutral",
    attrs:'data-ds-role="receiving-line-product-summary"'
  });
  const change = isNewQuickLine && !locked ? `<button class="inline-edit product-change-action" data-bj02-action="change-new-line-product" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.link" type="button">Đổi</button>` : "";
  const identity = change ? `<section class="bj02-product-summary-composition" data-ds-component="VSection" data-composed-from="DS v2 / List Row,VButton" data-layout-pattern="Compact context row + change action">${identityRow}${change}</section>` : identityRow;
  const uomControl = needsUomChoice ? `<div class="form-field line-uom-picker" data-ds-component="VSelect" data-figma-node="522:7291" data-ds-prop-state="Default"><label>Đơn vị nhập <span class="required">*</span></label><span class="bj02-native-select-shell"><select data-bj02-line-uom-select aria-label="Đơn vị nhập"><option value="">Chọn đơn vị</option>${uoms.map((uom) => `<option value="${uom.id}">${uom.label}</option>`).join("")}</select>${icon("chevronDown","icon--sm")}</span></div>` : "";
  return `${identity}${uomControl}`;
}
function exceptionQuantitiesEditor(target, totals, locked = false) {
  const fields = [
    { key: "accepted", label: "Đạt", value: totals.accepted || 0 },
    { key: "quarantine", label: "Cách ly", value: totals.quarantine || 0 },
    { key: "damaged", label: "Hỏng", value: totals.damaged || 0 },
    { key: "rejected", label: "Từ chối", value: totals.rejected || 0 },
  ];
  const unit = lineEditorDraft?.uom || "";
  return `<div class="exception-quantities classification-quantities" data-ds-role="quantity-input-composition" data-composed-from="VTextField input anatomy,VNumericKeypadSheet"><div class="bj02-quantity-input-stack">${fields.map((field) => `<div class="bj02-quantity-input-row"><span class="bj02-quantity-input-label">${field.label}</span><button class="bj02-quantity-input-trigger" data-bj02-quantity-target="${target}" data-bj02-quantity-key="${field.key}" ${target === "lot" && activeLotDraftId ? `data-bj02-quantity-lot-id="${activeLotDraftId}"` : ""} type="button" ${locked ? "disabled" : ""} aria-label="Nhập ${field.label.toLowerCase()}: ${field.value} ${unit}"><span class="bj02-quantity-input-value">${field.value}</span><span class="bj02-quantity-input-unit">${unit}</span></button></div>`).join("")}</div></div>`;
}
function documentSourceContextHtml() {
  if (flowMode !== "document" || lineEditorDraft?.remainingReceivableQty == null) return "";
  return bj02KeyValueRow("Còn chờ nhận", `${lineEditorDraft.remainingReceivableQty} ${lineEditorDraft.uom}`);
}
function lineTotalSummaryHtml(line) {
  const t = lineTotals(line);
  const value = flowMode === "document" && line.remainingReceivableQty != null ? `${t.totalReceived} / ${line.remainingReceivableQty} ${line.uom}` : `${t.totalReceived} ${line.uom || ""}`.trim();
  return bj02KeyValueRow("Tổng kiểm nhận", value, true, "bj02-derived-total");
}
function renderNonLotLineEditor() {
  const t = lineTotals(lineEditorDraft);
  const locked = lineEditorIsReadOnly();
  return `<section class="line-entry-section">${documentSourceContextHtml()}<div class="section-label section-label--first"><span>Phân loại số lượng</span></div>${exceptionQuantitiesEditor("line", t, locked)}${lineTotalSummaryHtml(lineEditorDraft)}<div class="editor-feedback" data-bj02-quantity-feedback>${quantityFeedback(t)}</div><div class="line-result-summary" data-bj02-line-result ${t.totalReceived ? "" : "hidden"}><span>Kết quả</span><strong>${classificationText(lineEditorDraft)}</strong></div><div class="editor-feedback document-variance-feedback" data-bj02-document-variance>${documentVarianceFeedback(lineEditorDraft)}</div></section>`;
}
function lotDraftTotals(lot) {
  const accepted = Math.max(0, Number(lot?.accepted) || 0);
  const quarantine = Math.max(0, Number(lot?.quarantine) || 0);
  const damaged = Math.max(0, Number(lot?.damaged) || 0);
  const rejected = Math.max(0, Number(lot?.rejected) || 0);
  return { totalReceived: accepted + quarantine + damaged + rejected, accepted, quarantine, damaged, rejected };
}
function renderLotCompact(lot, index, expanded = false) {
  const t = lotDraftTotals(lot);
  const label = lot.code || `Lô ${index + 1}`;
  const detail = t.totalReceived ? `${t.totalReceived} ${lineEditorDraft.uom} · ${t.accepted} đạt${t.quarantine ? ` · ${t.quarantine} cách ly` : ""}${t.damaged ? ` · ${t.damaged} hỏng` : ""}${t.rejected ? ` · ${t.rejected} từ chối` : ""}` : "Chưa hoàn tất";
  const canRemove = (lineEditorDraft.lots || []).length > 1;
  return `<section class="lot-accordion-item ${expanded ? "is-expanded" : ""}" data-bj02-lot-item="${lot.id}"><div class="lot-accordion-header"><button class="lot-accordion-toggle" data-bj02-action="toggle-lot" data-bj02-lot-id="${lot.id}" data-ds-component="VSection" data-composed-from="VText,DS v2 / Icon Button" type="button" aria-expanded="${expanded}"><span class="lot-accordion-copy"><strong>${label}</strong><span>${detail}</span></span><span class="lot-accordion-chevron ${expanded ? "is-expanded" : ""}">${icon("chevronDown", "icon--sm")}</span></button></div>${expanded ? renderActiveLotEditor(lot, index, canRemove) : ""}</section>`;
}
function renderActiveLotEditor(lot,index,canRemove=false) {

    const t=lotDraftTotals(lot), expiryRequired=Boolean(lineEditorDraft.expiryRequired), locked=lineEditorIsReadOnly(), disabled=locked?'disabled':'';
    lot.expiryPrecision ||= 'DAY'; lot.manufacturePrecision ||= 'DAY';
    const precisionOptions=(value)=>['DAY','MONTH','YEAR'].map((p)=>`<option value="${p}" ${p===value?'selected':''}>${p==='DAY'?'Ngày / tháng / năm':p==='MONTH'?'Tháng / năm':'Năm'}</option>`).join('');
    const expiryPlaceholder=lot.expiryPrecision==='MONTH'?'mm/yyyy':lot.expiryPrecision==='YEAR'?'yyyy':'dd/mm/yyyy';
    const manufacturePlaceholder=lot.manufacturePrecision==='MONTH'?'mm/yyyy':lot.manufacturePrecision==='YEAR'?'yyyy':'dd/mm/yyyy';
    return `<div class="active-lot-editor v392-lot-editor" data-ds-role="lot-editor-composition" data-composed-from="VTextField,VSelect,VButton"><div class="form-stack lot-fields-compact">
      <div class="form-field" data-ds-component="VTextField" data-figma-node="522:7186"><label>Mã lô <span class="required">*</span></label><span class="input-shell"><input data-bj02-lot-field="code" value="${escapeAttribute(lot.code)}" placeholder="Nhập mã trên bao bì" ${disabled}/></span></div>
      <div class="v392-date-precision"><div class="form-field" data-ds-component="VSelect" data-figma-node="522:7291"><label>Cách ghi hạn dùng</label><span class="bj02-native-select-shell"><select data-v392-lot-precision="expiryPrecision" ${disabled}>${precisionOptions(lot.expiryPrecision)}</select>${icon('chevronDown','icon--sm')}</span></div><div class="form-field" data-ds-component="VTextField" data-figma-node="522:7186"><label>Hạn dùng ${expiryRequired?'<span class="required">*</span>':''}</label><span class="input-shell bj02-date-shell"><span class="bj02-date-leading">${icon('calendar','icon--sm')}</span><input data-bj02-lot-field="expiry" value="${escapeAttribute(lot.expiry)}" placeholder="${expiryPlaceholder}" inputmode="numeric" ${disabled}/></span><small>Nhập đúng định dạng trên bao bì.</small></div></div>
      ${lotManufactureExpanded||lot.manufactureDate?`<div class="v392-date-precision"><div class="form-field" data-ds-component="VSelect" data-figma-node="522:7291"><label>Cách ghi ngày sản xuất</label><span class="bj02-native-select-shell"><select data-v392-lot-precision="manufacturePrecision" ${disabled}>${precisionOptions(lot.manufacturePrecision)}</select>${icon('chevronDown','icon--sm')}</span></div><div class="form-field" data-ds-component="VTextField" data-figma-node="522:7186"><label>Ngày sản xuất</label><span class="input-shell bj02-date-shell"><span class="bj02-date-leading">${icon('calendar','icon--sm')}</span><input data-bj02-lot-field="manufactureDate" value="${escapeAttribute(lot.manufactureDate)}" placeholder="${manufacturePlaceholder}" inputmode="numeric" ${disabled}/></span></div></div>`:(!locked?`<button class="button button--tertiary lot-extra-action" data-bj02-action="show-manufacture-date" data-ds-component="VButton" type="button">Thêm ngày sản xuất</button>`:'')}
      <div class="section-label"><span>Phân loại số lượng</span></div>${exceptionQuantitiesEditor('lot',t,locked)}${bj02KeyValueRow('Tổng kiểm nhận',`${t.totalReceived} ${lineEditorDraft.uom||''}`,true,'bj02-derived-total')}${t.rejected>0?`<p class="v392-rejected-helper">${t.rejected} ${esc(lineEditorDraft.uom)} từ chối · không vào tồn</p>`:''}<div class="editor-feedback" data-bj02-quantity-feedback>${quantityFeedback(t)}</div><div class="editor-feedback" data-bj02-lot-identity-feedback>${lotIdentityFeedback(lot)}</div>${canRemove&&!locked?`<button class="button button--tertiary lot-delete-action-inline" data-bj02-action="remove-editor-lot" data-bj02-lot-id="${lot.id}" data-ds-component="VButton" type="button">Xóa lô</button>`:''}
    </div></div>`;
  
}
function renderLotLineEditor() {
  if (!lineEditorDraft.lots.length) lineEditorDraft.lots = [emptyLot()];
  const locked = lineEditorIsReadOnly();
  const rows = lineEditorDraft.lots.map((lot, index) => renderLotCompact(lot, index, lot.id === activeLotDraftId)).join("");
  return `<section class="lot-line-editor"><div class="section-label section-label--first lot-section-heading"><span>Các lô thực nhận</span>${flowMode === "document" && lineEditorDraft.remainingReceivableQty != null ? `<small>Còn chờ nhận <strong>${lineEditorDraft.remainingReceivableQty} ${lineEditorDraft.uom}</strong></small>` : ""}</div><div class="lot-accordion-list">${rows}</div>${!locked ? `<button class="button button--secondary button--full add-lot-button" data-bj02-action="add-editor-lot" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.small" type="button">Thêm lô khác</button>` : ""}${lineTotalSummaryHtml(lineEditorDraft)}<div class="editor-feedback document-variance-feedback" data-bj02-document-variance>${documentVarianceFeedback(lineEditorDraft)}</div></section>`;
}
function lineEditorValid() {
  const __bj02BaseValid = (() => {

  if (!lineEditorDraft?.productId || !lineEditorDraft?.uomId) return false;
  const duplicate = flowMode === "quick" ? duplicateQuickLine(lineEditorDraft.productId, lineEditorDraft.uomId, activeReceiptLineId) : null;
  if (duplicate) return false;
  if (lineEditorDraft.trackingPolicy === "LOT") {
    const lots = lineEditorDraft.lots || [];
    if (!lots.length) return false;
    return lots.every((lot) => {
      const totals = lotDraftTotals(lot);
      return lot.code.trim() && (!lineEditorDraft.expiryRequired || lot.expiry.trim()) && totals.totalReceived > 0 && !duplicateLotDraft(lot.id, lot.code);
    });
  }
  return lineTotals(lineEditorDraft).totalReceived > 0;

  })();
  if (!__bj02BaseValid) return false;
  if (lineEditorDraft?.trackingPolicy === 'LOT') return (lineEditorDraft.lots || []).every((lot) => !lineEditorDraft.expiryRequired || bj02ValidPrecisionValue(lot.expiry, lot.expiryPrecision || 'DAY'));
  return true;
}
function render084BJ02(state) {
  ensureBj02ReviewFixture();
  if (state === "PERMISSION_DENIED") return appShell({ title: "Chi tiết hàng thực nhận", body: deniedBody(), centered: true });
  if (!lineEditorDraft) return appShell({ title: "Chi tiết hàng thực nhận", body: `<div class="empty-state" data-ds-component="VEmptyState"><h3 data-ds-component="VEmptyTitle">Chưa chọn sản phẩm</h3><p data-ds-component="VEmptyDescription">Quay lại Hàng thực nhận để chọn sản phẩm cần xử lý.</p></div>` });
  const locked = lineEditorIsReadOnly();
  const product = productById(lineEditorDraft.productId);
  const duplicate = product && lineEditorDraft.uomId && flowMode === "quick" ? duplicateQuickLine(lineEditorDraft.productId, lineEditorDraft.uomId, activeReceiptLineId) : null;
  const productPicker = renderLineProductPicker();
  const duplicateNotice = duplicate ? `${vBanner("warning", "Sản phẩm và đơn vị này đã có", "Mở dòng hàng hiện có để tiếp tục, tránh ghi trùng trong cùng lần nhận.")}<button class="button button--secondary button--full" data-bj02-action="open-duplicate-line" data-bj02-line-id="${duplicate.id}" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" type="button">Mở sản phẩm đã có</button>` : "";
  const readOnlyNotice = locked && state !== "READ_ONLY" ? vBanner("info", "Chế độ chỉ xem", "Bạn có thể xem chi tiết nhưng không thể thay đổi lần nhận này.") : stateBanner(state);
  if (duplicate) return appShell({ title: "Chi tiết hàng thực nhận", body: `${readOnlyNotice}${productPicker}${duplicateNotice}`, actions: "" });
  const editor = product && lineEditorDraft.uomId ? (lineEditorDraft.trackingPolicy === "LOT" ? renderLotLineEditor() : renderNonLotLineEditor()) : "";
  const notReceived = flowMode === "document" && lineEditorDraft.remainingReceivableQty != null && !locked ? `<button class="button button--tertiary bj02-danger-link-action not-received-action" data-bj02-action="not-received" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.link" data-ds-prop-tone="VComponentTone.danger" type="button">Chưa nhận lần này</button>` : "";
  const removeQuickLine = flowMode === "quick" && activeReceiptLineId && !locked ? `<button class="button button--tertiary bj02-danger-link-action remove-line-action" data-bj02-action="remove-quick-line" data-bj02-line-id="${activeReceiptLineId}" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.link" data-ds-prop-tone="VComponentTone.danger" type="button">Xóa khỏi lần nhận</button>` : "";
  const body = `${readOnlyNotice}${productPicker}${editor}${notReceived}${removeQuickLine}${bj02NumericKeypadOverlay()}`;
  return appShell({ title: "Chi tiết hàng thực nhận", body, actions: locked ? "" : primaryFooter("Xong", 'data-bj02-action="save-line"', !lineEditorValid()) });
}
function syncEditorDraftFromDom() {
  if (activeScreenId !== "SCR-084" || !lineEditorDraft) return;
  document.querySelectorAll("[data-bj02-line-qty]").forEach((input) => { lineEditorDraft[input.dataset.bj02LineQty] = Math.max(0, Number(input.value) || 0); });
  const lt=lineTotals(lineEditorDraft); lineEditorDraft.totalReceived=lt.totalReceived;
  const activeLot = lineEditorDraft.lots?.find((lot) => lot.id === activeLotDraftId);
  if (activeLot) {
    document.querySelectorAll("[data-bj02-lot-qty]").forEach((input) => { activeLot[input.dataset.bj02LotQty] = Math.max(0, Number(input.value) || 0); });
    document.querySelectorAll("[data-bj02-lot-field]").forEach((input) => { activeLot[input.dataset.bj02LotField] = input.value.trim(); });
    activeLot.totalReceived=lotDraftTotals(activeLot).totalReceived;
  }
}
function persistLineEditorDraft(markCompleted) {
  if (!lineEditorDraft?.productId || !lineEditorDraft?.uomId) return;
  syncEditorDraftFromDom();
  const copy = cloneBj02(lineEditorDraft);
  copy.status = markCompleted ? "COMPLETED" : (copy.status === "NOT_RECEIVED" ? "NOT_RECEIVED" : (lineEditorDirty ? "PENDING" : (copy.status || "PENDING")));
  const idx = activeReceiptLineId ? bj02Lines.findIndex((line) => line.id === activeReceiptLineId) : -1;
  if (idx >= 0) bj02Lines[idx] = copy;
  else if (!duplicateQuickLine(copy.productId, copy.uomId)) { bj02Lines.push(copy); activeReceiptLineId = copy.id; }
}
function selectLineProduct(productId) {
  const product = productById(productId); if (!product || !lineEditorDraft) return;
  lineEditorDraft.productId = product.id; lineEditorDraft.name = product.name; lineEditorDraft.sku = product.sku;
  lineEditorDraft.trackingPolicy = product.trackingPolicy; lineEditorDraft.expiryRequired = product.expiryRequired; lineEditorDraft.priceBasisSnapshot = cloneBj02(product.priceBasisSnapshot || null);
  if (product.uoms.length === 1) { lineEditorDraft.uomId = product.uoms[0].id; lineEditorDraft.uom = product.uoms[0].label; }
  else { lineEditorDraft.uomId = null; lineEditorDraft.uom = null; }
  lineEditorDraft.accepted = 0; lineEditorDraft.totalReceived = 0; lineEditorDraft.quarantine = 0; lineEditorDraft.damaged = 0; lineEditorDraft.rejected = 0;
  lineEditorDraft.lots = product.trackingPolicy === "LOT" ? [emptyLot()] : [];
  activeLotDraftId = lineEditorDraft.lots[0]?.id || null;
  lineProductMenuOpen = false; renderAppScreen();
}
function chooseLineUom(uomId) {
  lineEditorDirty = true;
  const product = productById(lineEditorDraft?.productId); if (!product) return;
  const uom = product.uoms.find((item) => item.id === uomId); if (!uom) { lineEditorDraft.uomId = null; lineEditorDraft.uom = null; } else { lineEditorDraft.uomId = uom.id; lineEditorDraft.uom = uom.label; }
  renderAppScreen();
}
function addEditorLot() {
  syncEditorDraftFromDom();
  lineEditorDirty = true;
  const lot = emptyLot();
  lineEditorDraft.lots.push(lot);
  activeLotDraftId = lot.id;
  lotClassificationExpanded = false;
  lotManufactureExpanded = false;
  renderAppScreen();
}
function lotHasData(lot) {
  const t = lotDraftTotals(lot || {});
  return Boolean(lot?.code || lot?.expiry || lot?.manufactureDate || t.totalReceived || t.quarantine || t.damaged || t.rejected);
}
function removeEditorLotNow(lotId) {
  if (!lineEditorDraft?.lots || lineEditorDraft.lots.length <= 1) return;
  const index = lineEditorDraft.lots.findIndex((lot) => lot.id === lotId);
  if (index < 0) return;
  lineEditorDraft.lots.splice(index, 1);
  if (activeLotDraftId === lotId) activeLotDraftId = lineEditorDraft.lots[Math.min(index, lineEditorDraft.lots.length - 1)]?.id || null;
  pendingRemoveLotId = null;
  renderAppScreen();
}
function openRemoveLotDialog(lotId) {
  const lot = lineEditorDraft?.lots?.find((item) => item.id === lotId);
  if (!lot || lineEditorDraft.lots.length <= 1) return;
  if (!lotHasData(lot)) return removeEditorLotNow(lotId);
  pendingRemoveLotId = lotId;
  const screen = document.getElementById("app-screen");
  screen.querySelector('.confirm-backdrop[data-dialog-kind="remove-lot"]')?.remove();
  screen.insertAdjacentHTML("beforeend", `<div class="confirm-backdrop" data-dialog-kind="remove-lot" data-ds-launcher="DS v2 / Confirmation Sheet"><section class="confirm-dialog" data-ds-component="DS v2 / Confirmation Sheet" data-figma-node="550:1058" data-ds-prop-content="Plain" data-ds-prop-title="Xóa lô này?" data-ds-prop-cancel-label="Giữ lô" data-ds-prop-action-label="Xóa lô" data-ds-prop-is-destructive="true" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><h3>Xóa lô này?</h3><p>Số lượng và thông tin đã nhập cho lô sẽ bị xóa khỏi dòng hàng.</p><div class="confirm-dialog-actions"><button class="button button--secondary" data-bj02-action="close-remove-lot" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.tertiary" type="button">Giữ lô</button><button class="button button--primary" data-bj02-action="confirm-remove-lot" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.primary" data-ds-prop-tone="VComponentTone.danger" type="button">Xóa lô</button></div></section></div>`);
}
function closeRemoveLotDialog() {
  document.querySelector('.confirm-backdrop[data-dialog-kind="remove-lot"]')?.remove();
  pendingRemoveLotId = null;
}
function confirmRemoveLot() {
  const lotId = pendingRemoveLotId;
  document.querySelector('.confirm-backdrop[data-dialog-kind="remove-lot"]')?.remove();
  pendingRemoveLotId = null;
  if (lotId) removeEditorLotNow(lotId);
}
function lineHasData(line) {
  if (!line) return false;
  const t = lineTotals(line);
  return Boolean(t.totalReceived || t.quarantine || t.damaged || t.rejected || (line.lots || []).some(lotHasData));
}
function removeQuickLineNow(lineId) {
  if (flowMode !== "quick") return;
  bj02Lines = bj02Lines.filter((line) => line.id !== lineId);
  if (activeReceiptLineId === lineId) { activeReceiptLineId = null; lineEditorDraft = null; activeLotDraftId = null; }
  pendingRemoveLineId = null;
  navigate("SCR-009");
}
function openRemoveQuickLineDialog(lineId) {
  const line = bj02Lines.find((item) => item.id === lineId);
  if (!line || flowMode !== "quick") return;
  if (!lineHasData(line)) return removeQuickLineNow(lineId);
  pendingRemoveLineId = lineId;
  const screen = document.getElementById("app-screen");
  screen.insertAdjacentHTML("beforeend", `<div class="confirm-backdrop" data-dialog-kind="remove-line" data-ds-launcher="DS v2 / Confirmation Sheet"><section class="confirm-dialog" data-ds-component="DS v2 / Confirmation Sheet" data-figma-node="550:1058" data-ds-prop-content="Plain" data-ds-prop-title="Xóa sản phẩm khỏi lần nhận?" data-ds-prop-cancel-label="Giữ lại" data-ds-prop-action-label="Xóa" data-ds-prop-is-destructive="true" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><h3>Xóa khỏi lần nhận?</h3><p>Toàn bộ số lượng và thông tin lô của dòng hàng này sẽ bị xóa.</p><div class="confirm-dialog-actions"><button class="button button--secondary" data-bj02-action="close-remove-line" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.tertiary" type="button">Giữ lại</button><button class="button button--primary" data-bj02-action="confirm-remove-line" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.primary" data-ds-prop-tone="VComponentTone.danger" type="button">Xóa</button></div></section></div>`);
}
function closeRemoveQuickLineDialog() {
  document.querySelector('.confirm-backdrop[data-dialog-kind="remove-line"]')?.remove();
  pendingRemoveLineId = null;
}
function confirmRemoveQuickLine() {
  const lineId = pendingRemoveLineId;
  document.querySelector('.confirm-backdrop[data-dialog-kind="remove-line"]')?.remove();
  pendingRemoveLineId = null;
  if (lineId) removeQuickLineNow(lineId);
}
function updateBj02EditorLiveFeedback() {
  if (activeScreenId !== "SCR-084" || !lineEditorDraft) return;
  const saveButton = document.querySelector('[data-bj02-action="save-line"]');
  if (saveButton) saveButton.disabled = !lineEditorValid();
  const activeLot = lineEditorDraft.lots?.find((lot) => lot.id === activeLotDraftId);
  const targetTotals = activeLot ? lotDraftTotals(activeLot) : lineTotals(lineEditorDraft);
  const quantityTarget = document.querySelector("[data-bj02-quantity-feedback]");
  if (quantityTarget) quantityTarget.innerHTML = quantityFeedback(targetTotals);
  const lotTarget = document.querySelector("[data-bj02-lot-identity-feedback]");
  if (lotTarget) lotTarget.innerHTML = activeLot ? lotIdentityFeedback(activeLot) : "";
  const varianceTarget = document.querySelector("[data-bj02-document-variance]");
  if (varianceTarget) varianceTarget.innerHTML = documentVarianceFeedback(lineEditorDraft);
  const totalSummary = document.querySelector("[data-bj02-editor-total-summary] strong");
  if (totalSummary) {
    const t = lineTotals(lineEditorDraft);
    totalSummary.textContent = flowMode === "document" && lineEditorDraft.remainingReceivableQty != null ? `${t.totalReceived} / ${lineEditorDraft.remainingReceivableQty} ${lineEditorDraft.uom}` : `${t.totalReceived} ${lineEditorDraft.uom || ""}`.trim();
  }
  const activeLotSummary = document.querySelector("[data-bj02-lot-total-summary] strong");
  if (activeLotSummary && activeLot) activeLotSummary.textContent = `${lotDraftTotals(activeLot).totalReceived} ${lineEditorDraft.uom || ""}`.trim();
  const result = document.querySelector("[data-bj02-line-result]");
  if (result) {
    const t = lineTotals(lineEditorDraft);
    result.hidden = t.totalReceived <= 0;
    const strong = result.querySelector("strong");
    if (strong) strong.textContent = classificationText(lineEditorDraft);
  }
}
function saveEditorLine() {
  syncEditorDraftFromDom();
  if (!lineEditorValid()) return showToast("Kiểm tra thông tin còn thiếu trước khi hoàn tất.", "warning");
  persistLineEditorDraft(true); lineEditorDirty = false; showToast("Đã cập nhật hàng thực nhận"); navigate("SCR-009");
}
function markLineNotReceived() {
  if (!lineEditorDraft || flowMode !== "document") return;
  lineEditorDraft.status = "NOT_RECEIVED"; lineEditorDraft.accepted = 0; lineEditorDraft.totalReceived = 0; lineEditorDraft.quarantine = 0; lineEditorDraft.damaged = 0; lineEditorDraft.rejected = 0; lineEditorDraft.lots = [];
  const idx = bj02Lines.findIndex((line) => line.id === activeReceiptLineId); if (idx >= 0) bj02Lines[idx] = cloneBj02(lineEditorDraft);
  navigate("SCR-009");
}
function requestMarkLineNotReceived() {
  if (!lineEditorDraft || flowMode !== "document") return;
  syncEditorDraftFromDom();
  if (!lineHasData(lineEditorDraft)) return markLineNotReceived();
  const screen = document.getElementById("app-screen");
  screen.querySelector('.confirm-backdrop[data-dialog-kind="not-received"]')?.remove();
  screen.insertAdjacentHTML("beforeend", `<div class="confirm-backdrop" data-dialog-kind="not-received" data-ds-launcher="DS v2 / Confirmation Sheet"><section class="confirm-dialog" data-ds-component="DS v2 / Confirmation Sheet" data-figma-node="550:1058" data-ds-prop-content="Plain" data-ds-prop-title="Đánh dấu chưa nhận lần này?" data-ds-prop-cancel-label="Giữ dữ liệu" data-ds-prop-action-label="Chưa nhận lần này" data-ds-prop-is-destructive="true" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><h3>Đánh dấu chưa nhận lần này?</h3><p>Số lượng và thông tin lô đã nhập cho dòng hàng này sẽ được xóa. Phần còn lại trên chứng từ vẫn được giữ.</p><div class="confirm-dialog-actions"><button class="button button--secondary" data-bj02-action="close-not-received" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.tertiary" type="button">Giữ dữ liệu</button><button class="button button--primary" data-bj02-action="confirm-not-received" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.primary" data-ds-prop-tone="VComponentTone.danger" type="button">Chưa nhận lần này</button></div></section></div>`);
}
function closeNotReceivedDialog() { document.querySelector('.confirm-backdrop[data-dialog-kind="not-received"]')?.remove(); }
function filterLineProductOptions(query) {
  const menu=document.querySelector("[data-bj02-product-menu]"); if(!menu) return;
  const q=query.trim().toLowerCase(); let visible=0;
  menu.querySelectorAll("[data-bj02-product-option]").forEach((option)=>{ const match=!q || (option.dataset.bj02ProductSearchText || "").includes(q); option.hidden=!match; if(match) visible+=1; });
  const empty=menu.querySelector("[data-bj02-product-empty]"); if(empty) empty.hidden=visible>0;
}
function filterDocumentCards(query) {
  documentSearchQuery = query;
  const normalized = query.trim().toLowerCase();
  let visible = 0;
  document.querySelectorAll("[data-bj02-document-search-text]").forEach((card) => {
    const match = !normalized || (card.dataset.bj02DocumentSearchText || "").includes(normalized);
    card.hidden = !match;
    if (match) visible += 1;
  });
  const empty = document.querySelector("[data-bj02-document-filter-empty]");
  if (empty) empty.hidden = visible > 0;
}
function filterSupplierOptions(query) {
  supplierSearchQuery = query;
  const menu = document.querySelector("[data-bj02-supplier-menu]"); if (!menu) return;
  const q = query.trim().toLowerCase(); let visible = 0;
  menu.querySelectorAll("[data-bj02-supplier-option]").forEach((option) => {
    const searchable = option.dataset.bj02SupplierSearchText || "";
    const match = !q || searchable.includes(q);
    option.hidden = !match; if (match) visible += 1;
  });
  const empty = menu.querySelector("[data-bj02-supplier-empty]"); if (empty) empty.hidden = visible > 0;
}
function selectSupplier(supplierId) {
  const changed = bj02Header.supplierId && bj02Header.supplierId !== supplierId;
  if (changed) {
    bj02Header.evidence = ''; bj02Header.evidenceRefs = []; bj02Header.ownershipAssertion = null;
    bj02Lines.forEach((line) => { line.priceBasisVerified = false; });
  }

  const supplier = supplierCatalog.find((item) => item.id === supplierId); if (!supplier) return;
  bj02Header.supplierId = supplier.id; bj02Header.supplier = supplier.name; supplierMenuOpen = false; supplierSearchQuery = ""; supplierValidationVisible = false; renderAppScreen();
  if (changed) showToast('Đã đổi nhà cung cấp; cần kiểm tra lại chứng từ và quyền sở hữu.', 'info');
}
let executionTimer = null;
function startAutoExecution() {
  window.clearTimeout(executionTimer);
  stateByScreen["SCR-012"] = "PROCESSING";
  navigate("SCR-012");
  executionTimer = window.setTimeout(() => {
    if (activeScreenId !== "SCR-012" || stateByScreen["SCR-012"] !== "PROCESSING") return;
    stateByScreen["SCR-012"] = "VALUATION_PENDING_RESULT";
    render();
  }, 1400);
}
function openRejectSheet() {
  const screen = document.getElementById("app-screen");
  if (screen.querySelector(".sheet-backdrop")) return;
  screen.insertAdjacentHTML("beforeend", `
    <div class="sheet-backdrop" data-action="close-reject" data-ds-launcher="showVBottomSheet" data-ds-launcher-prop-is-dismissible="true" data-ds-launcher-prop-enable-drag="true">
      <section class="bottom-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" data-ds-profile="approval.reject" data-ds-prop-title="Từ chối yêu cầu" data-ds-prop-tone="VComponentTone.danger" data-ds-prop-max-height-fraction="0.95" role="dialog" aria-modal="true" aria-labelledby="reject-title" onclick="event.stopPropagation()">
        <div class="sheet-handle" data-ds-internal="VBottomSheet.handle"></div>
        <div class="sheet-title" data-ds-internal="VBottomSheet.title"><h3 id="reject-title">Từ chối yêu cầu</h3></div>
        <div class="sheet-divider" data-ds-internal="VBottomSheet.divider"></div>
        <div class="sheet-safe-area" data-ds-internal="showVBottomSheet.SafeArea">
          <div class="sheet-content">
            <div class="form-field" data-ds-component="VTextarea" data-figma-node="522:7212" data-ds-prop-label="Lý do từ chối" data-ds-prop-is-required="true" data-ds-prop-min-lines="3" data-ds-prop-max-lines="5"><label for="reject-reason">Lý do từ chối <span class="required">*</span></label><span class="input-shell input-shell--textarea"><textarea id="reject-reason" data-reject-reason rows="4" placeholder="Nêu lý do để người lập hiểu và xử lý"></textarea></span></div>
            <div class="sheet-actions"><button class="button button--secondary" data-action="close-reject" data-ds-component="VButton" data-ds-prop-label="Hủy" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.medium" type="button">Hủy</button><button class="button button--primary" data-action="confirm-reject" data-ds-component="VButton" data-ds-prop-label="Xác nhận từ chối" data-ds-prop-variant="VButtonVariant.primary" data-ds-prop-size="VButtonSize.medium" data-ds-prop-tone="VComponentTone.danger" type="button" disabled>Xác nhận từ chối</button></div>
          </div>
        </div>
      </section>
    </div>`);
  screen.querySelector("[data-reject-reason]")?.focus();
}
function closeRejectSheet() { document.querySelector(".sheet-backdrop")?.remove(); }
function confirmReject() {
  const reason = document.querySelector("[data-reject-reason]")?.value.trim() || "";
  if (!reason) return;
  approvalRejectReason = reason;
  closeRejectSheet();
  stateByScreen["SCR-011"] = "APPROVAL_ALREADY_DECIDED";
  render();
}

if (window.__VET45_PROTOTYPE__) {
  window.__VET45_PROTOTYPE__.scenarios = [...new Set([...(window.__VET45_PROTOTYPE__.scenarios || []), 'bj02-quick-receipt-no-draft', 'bj02-quick-approval-no-price-basis', 'bj02-design-state-cleanup'])];
  window.__VET45_PROTOTYPE__.bj02QuickReceipt = { draftPersistence: false, firstPersistedState: 'PENDING_APPROVAL', receiptIdCreatedOnSuccessfulSubmit: true, priceFxRequiredAtBj02Submit: false, designStateRegistryClean: true };
}


Object.assign(renderers, {
  "SCR-006": render006BJ02,
  "SCR-007": render007BJ02,
  "SCR-008": render008BJ02,
  "SCR-009": render009BJ02,
  "SCR-084": render084BJ02,
  "SCR-010": render010BJ02,
  "SCR-011": render011BJ02,
  "SCR-012": render012BJ02,
  "SCR-013": render013BJ02,
});
ownedFlows.add("UIF-02");

document.addEventListener("click", (event) => {
  const a = event.target.closest("[data-v350-action]");
  if (!a || a.disabled) return;
  const k = a.dataset.v350Action;
  if (k !== "bj02-verify-unknown" && k !== "bj02-handoff-unknown") return;
  event.preventDefault();
  event.stopPropagation();
  if (k === "bj02-verify-unknown") {
    stateByScreen["SCR-013"] = "PROCESSING_OR_UNKNOWN";
    return navigate("SCR-013");
  }
  return bj17HandoffUnknown({
    sourceFlow: "UIF-02",
    operation: "Nhận hàng",
    scope: "Yêu cầu nhận hàng hiện tại",
    evidence: "INSUFFICIENT",
  });
}, true);

onPrevious["UIF-02"] = () => {
  if (activeScreenId === "SCR-009") return navigate(flowMode === "quick" ? "SCR-008" : "SCR-007");
  if (activeScreenId === "SCR-084") {
    if (!lineEditorIsReadOnly()) persistLineEditorDraft(false);
    lineEditorReadOnly = false;
    lineEditorDirty = false;
    return navigate("SCR-009");
  }
};

document.addEventListener('click', (event) => {
    if (activeFlowId !== "UIF-02") return;
    const quick=event.target.closest('[data-v392-quick-continue]');
    if(quick){
      event.preventDefault(); 
      const supplierValid=supplierCatalog.some((x)=>x.id===bj02Header.supplierId&&x.name===bj02Header.supplier.trim());
      if(!supplierValid||!bj02EvidenceRefs().length||!BJ02_CONTEXT.capabilities.assertOwnership) return;
      bj02MakeOwnershipAssertion(); return navigate('SCR-009');
    }
    if(event.target.closest('[data-v392-open-evidence]')){event.preventDefault();BJ02_CONTEXT.evidenceSheetOpen=true;return renderAppScreen();}
    if(event.target.closest('[data-v392-close-evidence]')){event.preventDefault();BJ02_CONTEXT.evidenceSheetOpen=false;return renderAppScreen();}
    if(event.target.closest('[data-v392-preview-file]')){event.preventDefault();return showToast('Đã mở bản xem trước chứng từ trong chế độ prototype.','info');}
    if(event.target.closest('[data-v392-change-source]')){event.preventDefault();BJ02_CONTEXT.changeSourceConfirmOpen=true;return renderAppScreen();}
    if(event.target.closest('[data-v392-cancel-source-change]')){event.preventDefault();BJ02_CONTEXT.changeSourceConfirmOpen=false;return renderAppScreen();}
    if(event.target.closest('[data-v392-confirm-source-change]')){event.preventDefault();BJ02_CONTEXT.changeSourceConfirmOpen=false;resetBj02Receipt('document');return navigate('SCR-007');}
  }, true);

document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-02") return;
  const documentCard = event.target.closest("[data-bj02-document-id]");
  if (documentCard) {
    event.preventDefault(); selectedDocumentId = documentCard.dataset.bj02DocumentId; flowMode = "document"; resetBj02Receipt("document"); return navigate("SCR-009");
  }
  const flowButton = event.target.closest("[data-flow]");
  if (flowButton) {
    event.preventDefault();
    event.stopPropagation();
    const nextFlow = flowButton.dataset.flow;
    if (nextFlow !== flowMode) {
      flowMode = nextFlow;
      resetBj02Receipt(flowMode);
    }
    syncReviewUrl();
    if (flowButton.dataset.next) return navigate(flowButton.dataset.next);
    return navigate(flowMode === "quick" ? "SCR-008" : "SCR-007");
  }
  if (event.target.matches("[data-bj02-supplier-backdrop]")) { event.preventDefault(); supplierMenuOpen=false; supplierSearchQuery=""; return renderAppScreen(); }
  const supplierTrigger = event.target.closest("[data-bj02-open-supplier-sheet]");
  if (supplierTrigger) { event.preventDefault(); supplierMenuOpen=true; supplierSearchQuery=""; return renderAppScreen(); }
  const quantityTrigger = event.target.closest("[data-bj02-quantity-target]");
  if (quantityTrigger) { event.preventDefault(); return openBj02NumericPad(quantityTrigger.dataset.bj02QuantityTarget, quantityTrigger.dataset.bj02QuantityKey, quantityTrigger.dataset.bj02QuantityLotId || null); }
  const numericKey = event.target.closest("[data-bj02-numeric-key]");
  if (numericKey) { event.preventDefault(); return updateBj02NumericPad(numericKey.dataset.bj02NumericKey); }
  const lineCard = event.target.closest("[data-bj02-line-id]");
  if (lineCard && !event.target.closest("[data-bj02-action]")) { event.preventDefault(); return beginLineEditor(lineCard.dataset.bj02LineId); }
  const supplierOption = event.target.closest("[data-bj02-supplier-option]");
  if (supplierOption) { event.preventDefault(); return selectSupplier(supplierOption.dataset.bj02SupplierOption); }
  const overviewProductOption = event.target.closest("[data-bj02-overview-product-option]");
  if (overviewProductOption) { event.preventDefault(); return selectQuickOverviewProduct(overviewProductOption.dataset.bj02OverviewProductOption); }
  const overviewUomChoice = event.target.closest("[data-bj02-overview-uom-choice]");
  if (overviewUomChoice) { event.preventDefault(); return chooseQuickOverviewUom(overviewUomChoice.dataset.bj02OverviewUomChoice); }
  const lineUomChoice = event.target.closest("[data-bj02-line-uom-choice]");
  if (lineUomChoice) { event.preventDefault(); if (lineEditorIsReadOnly()) return; return chooseLineUom(lineUomChoice.dataset.bj02LineUomChoice); }
  const productOption = event.target.closest("[data-bj02-product-option]");
  if (productOption) { event.preventDefault(); if (lineEditorIsReadOnly()) return; return selectLineProduct(productOption.dataset.bj02ProductOption); }
  const reviewLine = event.target.closest("[data-bj02-review-line]");
  if (reviewLine) { event.preventDefault(); bj02ReviewOpenLineId = reviewLine.dataset.bj02ReviewLine; return renderAppScreen(); }
  const reviewClose = event.target.closest("[data-bj02-review-close]");
  if (reviewClose) { event.preventDefault(); bj02ReviewOpenLineId = null; return renderAppScreen(); }
  const actionButton = event.target.closest("[data-bj02-action]");
  if (!actionButton) return;
  event.preventDefault(); event.stopPropagation();
  const action = actionButton.dataset.bj02Action;
  if (action === "numeric-cancel") return closeBj02NumericPad();
  if (action === "change-overview-product") { quickOverviewPendingProductId=null; quickOverviewProductQuery=""; quickOverviewProductMenuOpen=false; return renderAppScreen(); }
  if (action === "numeric-save") return saveBj02NumericPad();
  if (action === "change-new-line-product") { lineEditorDirty=true; lineEditorDraft.productId=null; lineEditorDraft.uomId=null; lineEditorDraft.uom=null; lineEditorDraft.lots=[]; lineProductMenuOpen=true; return renderAppScreen(); }
  if (action === "show-manufacture-date") { syncEditorDraftFromDom(); lotManufactureExpanded=true; return renderAppScreen(); }
  if (action === "add-editor-lot") return addEditorLot();
  if (action === "toggle-lot") { syncEditorDraftFromDom(); const lotId=actionButton.dataset.bj02LotId; activeLotDraftId = activeLotDraftId === lotId ? null : lotId; lotClassificationExpanded=false; lotManufactureExpanded=Boolean(lineEditorDraft.lots.find((lot)=>lot.id===activeLotDraftId)?.manufactureDate); return renderAppScreen(); }
  if (action === "remove-editor-lot") { syncEditorDraftFromDom(); return openRemoveLotDialog(actionButton.dataset.bj02LotId); }
  if (action === "close-remove-lot") return closeRemoveLotDialog();
  if (action === "confirm-remove-lot") return confirmRemoveLot();
  if (action === "open-existing-lot") { syncEditorDraftFromDom(); activeLotDraftId=actionButton.dataset.bj02LotId; lotClassificationExpanded=false; lotManufactureExpanded=Boolean(lineEditorDraft.lots.find((lot)=>lot.id===activeLotDraftId)?.manufactureDate); return renderAppScreen(); }
  if (action === "remove-quick-line") { syncEditorDraftFromDom(); return openRemoveQuickLineDialog(actionButton.dataset.bj02LineId); }
  if (action === "close-remove-line") return closeRemoveQuickLineDialog();
  if (action === "confirm-remove-line") return confirmRemoveQuickLine();
  if (action === "save-line") return saveEditorLine();
  if (action === "not-received") return requestMarkLineNotReceived();
  if (action === "close-not-received") return closeNotReceivedDialog();
  if (action === "confirm-not-received") { closeNotReceivedDialog(); return markLineNotReceived(); }
  if (action === "open-duplicate-line") return beginLineEditor(actionButton.dataset.bj02LineId);
  if (action === "open-existing-overview-line") { quickOverviewDuplicateLineId=null; return beginLineEditor(actionButton.dataset.bj02LineId); }
}, true);

document.addEventListener("focusin", (event) => {
  if (activeFlowId !== "UIF-02") return;
  if (event.target.matches("[data-bj02-overview-product-search]")) {
    quickOverviewProductMenuOpen = true;
    const menu = document.querySelector("[data-bj02-overview-product-menu]");
    if (menu) { menu.hidden = false; menu.classList.add("is-open"); }
    event.target.setAttribute("aria-expanded", "true");
    filterQuickOverviewProductOptions(event.target.value);
    return;
  }
  if (event.target.matches("[data-bj02-supplier-search]")) {
    supplierMenuOpen = true;
    const menu = document.querySelector("[data-bj02-supplier-menu]");
    if (menu) { menu.hidden = false; menu.classList.add("is-open"); }
    event.target.setAttribute("aria-expanded", "true");
    filterSupplierOptions(event.target.value);
    return;
  }
});

document.addEventListener("focusout", (event) => {
  if (activeFlowId !== "UIF-02") return;
  if (!event.target.matches("[data-bj02-supplier-search]")) return;
  supplierValidationVisible = true;
  const valid = supplierCatalog.some((supplier) => supplier.id === bj02Header.supplierId && supplier.name === bj02Header.supplier.trim());
  const error = document.querySelector("[data-bj02-supplier-error]");
  if (error) error.hidden = valid;
});

document.addEventListener("pointerdown", (event) => {
  if (activeFlowId !== "UIF-02") return;
  if (!event.target.closest(".quick-overview-search-wrap")) {
    const overviewMenu = document.querySelector("[data-bj02-overview-product-menu]");
    const overviewInput = document.querySelector("[data-bj02-overview-product-search]");
    if (overviewMenu) { overviewMenu.hidden = true; overviewMenu.classList.remove("is-open"); }
    if (overviewInput) overviewInput.setAttribute("aria-expanded", "false");
    quickOverviewProductMenuOpen = false;
  }
  if (event.target.closest(".bj02-select-sheet")) return;
  const supplierMenu = document.querySelector("[data-bj02-supplier-menu]");
  const supplierInput = document.querySelector("[data-bj02-supplier-search]");
  if (supplierMenu) { supplierMenu.hidden = true; supplierMenu.classList.remove("is-open"); }
  if (supplierInput) supplierInput.setAttribute("aria-expanded", "false");
  supplierMenuOpen = false;
});

document.addEventListener("change", (event) => {
  if (activeFlowId !== "UIF-02") return;
  if (event.target.matches("[data-bj02-evidence-file]")) {
    const files = [...(event.target.files || [])];
    bj02Header.evidenceRefs = files.map((f, i) => ({ id: `EV-${Date.now()}-${i + 1}`, name: f.name, type: 'DELIVERY_DOCUMENT' }));
    bj02Header.evidence = bj02Header.evidenceRefs[0]?.name || '';
    bj02Header.ownershipAssertion = null;
    return renderAppScreen();
  }
  if (event.target.matches("[data-v392-lot-precision]") && lineEditorDraft) {
    const lot = lineEditorDraft.lots?.find((x) => x.id === activeLotDraftId);
    if (lot) { lot[event.target.dataset.v392LotPrecision] = event.target.value; lineEditorDirty = true; }
  }
  if (event.target.matches("[data-bj02-line-uom-select]")) { if (lineEditorIsReadOnly() || !event.target.value) return; return chooseLineUom(event.target.value); }
  if (event.target.matches("[data-bj02-uom]")) { if (lineEditorIsReadOnly()) return; return chooseLineUom(event.target.value); }
});


document.addEventListener("input", (event) => {
  if (activeFlowId !== "UIF-02") return;
  if (event.target.matches("[data-bj02-overview-product-search]")) {
    quickOverviewProductQuery = event.target.value;
    quickOverviewProductMenuOpen = true;
    const menu=document.querySelector("[data-bj02-overview-product-menu]");
    if(menu){menu.hidden=false;menu.classList.add("is-open");}
    event.target.setAttribute("aria-expanded","true");
    filterQuickOverviewProductOptions(event.target.value);
    return;
  }
  if (event.target.matches("[data-bj02-document-search]")) { filterDocumentCards(event.target.value); return; }
  if (event.target.matches("[data-bj02-supplier-search]")) { filterSupplierOptions(event.target.value); return; }
  if (event.target.matches("[data-bj02-header]")) {
    bj02Header[event.target.dataset.bj02Header] = event.target.value;
    if (event.target.matches("[data-bj02-supplier-search]")) { bj02Header.supplierId = null; supplierMenuOpen = true; supplierValidationVisible = false; filterSupplierOptions(event.target.value); const err=document.querySelector("[data-bj02-supplier-error]"); if(err) err.hidden=true; }
    const continueButton = document.querySelector('[data-next="SCR-009"]');
    if (continueButton && activeScreenId === "SCR-008") {
      const supplierValid = supplierCatalog.some((supplier) => supplier.id === bj02Header.supplierId && supplier.name === bj02Header.supplier.trim());
      continueButton.disabled = !(supplierValid && quickReceiptDateValid(bj02Header.businessDate) && bj02Header.evidence.trim());
    }
    return;
  }
  if (event.target.matches("[data-bj02-product-search]")) { filterLineProductOptions(event.target.value); return; }
  if (event.target.matches("[data-bj02-lot-field]")) {
    lineEditorDirty = true;
    syncEditorDraftFromDom();
    updateBj02EditorLiveFeedback();
    return;
  }
});

document.addEventListener("input", (event) => {
  if (activeFlowId !== "UIF-02") return;
  if (event.target.matches("[data-reject-reason]")) {
    const confirm = document.querySelector('[data-action="confirm-reject"]');
    if (confirm) confirm.disabled = event.target.value.trim().length === 0;
  }
});

document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-02") return;
  const actionButton = event.target.closest("[data-action]");
  if (!actionButton) return;
  const action = actionButton.dataset.action;
  if (!["close-reject","exit-flow","exit-approval","exit-receipt-document-context","submit","approve","open-reject","confirm-reject","refresh","handoff"].includes(action)) return;
  event.preventDefault();
  event.stopPropagation();
  if (action === "close-reject") return closeRejectSheet();
  if (action === "exit-flow") { flowMode = "document"; selectedDocumentId = "PN-260816-04"; resetBj02Receipt("document"); return navigate("SCR-006"); }
  if (action === "exit-approval") return showToast("Quay về danh sách việc cần duyệt của người phê duyệt", "info");
  if (action === "exit-receipt-document-context") return showToast(`Quay về chứng từ ${selectedDocumentId}`, "info");
  if (action === "submit") {
    if (bj02RequiresApproval()) {
      stateByScreen["SCR-010"] = "PENDING_APPROVAL";
      stateByScreen["SCR-011"] = "READY";
      render();
      return;
    }
    return startAutoExecution();
  }
  if (action === "approve") return startAutoExecution();
  if (action === "open-reject") return openRejectSheet();
  if (action === "confirm-reject") return confirmReject();
  if (action === "refresh") return showToast("Đã làm mới kết quả nhận hàng", "info");
  if (action === "handoff") return showToast("Đã chuẩn bị bàn giao xử lý tiếp theo", "info");
}, false);
