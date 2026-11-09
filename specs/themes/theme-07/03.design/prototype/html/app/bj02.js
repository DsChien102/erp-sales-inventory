/* BJ-02 — Nhận hàng mua (UIF-02). Màn: SCR-007 (gồm lối nhập nhanh; SCR-006 đã gộp vào), 008, 009, 084, 010, 011, 012, 013.
 * v5.28.0 rút gọn (PLAN.md Theme 7 → G5-3): chỉ còn phiếu nhận theo NCC (chế độ quick), NCC bắt buộc + số chứng từ NCC, giá mua (gồm VAT) trên từng dòng, một ô "Số lượng nhận", ghi nhận thẳng. Bỏ: nhận theo chứng từ mua (PO), chứng từ giao nhận + xác nhận sở hữu, Cách ly / Hỏng / Từ chối, duyệt (SCR-011 chỉ còn RECORDED), đối soát SCR-013, kết quả chưa xác định.
 *
 * Thiết kế lại (T7-P BJ-02, v5.8.0): nhân viên lập trên iPhone, chủ cửa hàng duyệt trên web (K2). Cửa hàng chỉ có một chủ; chủ lập phiếu
 * cũng phải gửi duyệt rồi tự vào SCR-011 duyệt một lần nữa (như phiếu của thủ kho) — không có đường ghi nhận thẳng.
 * Mọi fixture, trạng thái, hàm dựng và xử lý sự kiện của BJ-02 nằm ở đây. Sửa BJ-02: sửa thẳng file này.
 * Khuôn dùng chung K1–K4, K7 → app/shared-patterns.js. Dùng chung từ app/core.js: appShell, vBanner, ds24*, icon, primaryFooter,
 * esc, escapeAttribute, navigate, renderAppScreen, showToast, onPrevious, flowMode.
 *
 * Fixture chung chặng 2 — BJ-03 / BJ-13 đọc cùng tên, mã (Nobivac DHPPi SP-000184, Oxytetracycline LA SP-000147, phiếu PN-260816-04).
 * `productRef` = mã sản phẩm của BJ-01: nhận xong thì BJ-02 cộng tồn vào đó (bj01ApplyReceipt).
 * Nguồn "Chờ duyệt" của nhận hàng ở lại hub.js (cần `inventoryActivated` trong IIFE của Hub); ba dòng mở cùng fixture 011.
 */

const supplierCatalog = [
  { id: "SUP-MINH-DUNG", name: "Minh Dũng", code: "NCC-0018" },
  { id: "SUP-AN-VIET", name: "An Việt", code: "NCC-0042" },
  { id: "SUP-PHUONG-NAM", name: "Phương Nam", code: "NCC-0067" },
];
const quickProductCatalog = [
  { id: "P-NOB-DHPP", productRef: "INV-NOB", name: "Nobivac DHPPi", sku: "SP-000184", barcode: "8938500001012", baseUomId: "UOM-VIAL", baseUom: "lọ", uoms: [
      { id: "UOM-BOX", label: "hộp", conversionRatio: 10 },
      { id: "UOM-VIAL", label: "lọ", conversionRatio: 1 },
    ], trackingPolicy: "LOT", expiryRequired: true,
    priceBasisSnapshot: { kind: "OFFICIAL_COST", unitPriceVndPerBase: 8500, priceVersion: "COST-2026-09-v12", currency: "VND", fxVersion: "FX-VND-1" } },
  { id: "P-OXY-LA", productRef: "INV-OXY", name: "Oxytetracycline LA", sku: "SP-000147", barcode: "8938500007144", baseUomId: "UOM-BOTTLE", baseUom: "chai", uoms: [
      { id: "UOM-BOTTLE", label: "chai", conversionRatio: 1 },
    ], trackingPolicy: "NONE", expiryRequired: false,
    priceBasisSnapshot: { kind: "OFFICIAL_COST", unitPriceVndPerBase: 120000, priceVersion: "COST-2026-09-v21", currency: "VND", fxVersion: "FX-VND-1" } },
  { id: "P-GLOVE-N", productRef: null, name: "Găng tay khám Nitrile", sku: "GLOVE-N", barcode: "8938500003033", baseUomId: "UOM-BOX", baseUom: "hộp", uoms: [
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
      { id: "DOC-04-02", sourceLineId: "PO-04-02", sourceLineVersion: "v7.1", productId: "P-OXY-LA", uomId: "UOM-BOTTLE", uom: "chai", remainingReceivableQty: 24, conversionRatioSnapshot: 1, trackingPolicy: "NONE", expiryRequired: false, priceBasisSnapshot: { kind: "SOURCE_PRICE_FX", unitPriceVndPerBase: 120000, sourceRef: "PO-04-02", priceVersion: "PO-v7.1", currency: "VND", fxVersion: "FX-VND-1" } },
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
let bj02WebLineId = null; // dòng đang chọn ở SCR-009 khung web (editor bên phải); iPhone bỏ qua
let bj02EditorForce = false; // đồng bộ nháp từ DOM khi đổi khung (viewport đã đổi nhưng DOM còn của khung cũ)
let lineEditorDraft = null;
let activeLotDraftId = null;
let lotManufactureExpanded = false;
let lineProductMenuOpen = false;
let quickOverviewProductQuery = "";
let quickOverviewProductMenuOpen = false;
let quickOverviewPendingProductId = null;
let quickOverviewDuplicateLineId = null;
let quickLineSequence = 1;
let supplierMenuOpen = false;
let supplierSearchQuery = "";
let bj02ReviewOpenLineId = null;
let documentSearchQuery = "";
let lineSearchQuery = "";
let supplierValidationVisible = false;
let lineEditorReadOnly = false;
let lineEditorDirty = false;
// Sheet / hộp thoại do trạng thái điều khiển (dựng lại cùng màn, nhận focus qua syncDialogFocus).
let bj02ScanOpen = false;
let bj02RejectOpen = false;
let bj02LinesSheetOpen = false;
let bj02Confirm = null; // { kind: "remove-lot" | "remove-line" | "not-received", id }
let bj02PendingSubmitted = false; // phiếu của chính phiên này đang chờ duyệt: Hub mở đúng phiếu đó ở "Chờ duyệt"
let bj02ReviewReceiptId = null; // phiếu chờ duyệt đang mở từ "Chờ duyệt" (Hub đặt)
const bj02DecidedReceipts = new Set(); // phiếu đã duyệt / từ chối: rời "Chờ duyệt" của Home Kho
let bj02Approver = null; // null (không cần duyệt) | { name }
let bj02LastCommitted = null; // { ref, mode, lines } — BJ-03 đọc biến này
const bj02AppliedRefs = new Set(); // số thứ tự lần ghi nhận đã cộng vào tồn BJ-01 (một lần mỗi phiếu)
let bj02CommitSeq = 0;
let bj02CameraShots = 0;
let bj02RejectedBy = "Chủ cửa hàng";

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
      rejectedAt: '16/09/2026 · 09:52',
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

/* ---------- Vai, lối ra, trạng thái chung ---------- */

const bj02IsApprover = () => ["owner", "approver"].includes(currentActor());
const bj02Exit = () => k1ExitAttr("SCR-007");
function bj02Denied(what, next = "Nhờ chủ cửa hàng cấp quyền rồi quay lại.") { return k1Denied({ what, next, exitAttr: bj02Exit() }); }
// Stale / khoá dùng chung K1 (chữ của stateBanner giữ nguyên).
function bj02StateNotice(state) {
  if (state === "CONFLICT") return k1Stale({ title: "Dữ liệu vừa thay đổi", description: "Tải phiên bản hiện hành trước khi tiếp tục; hệ thống không ghi đè im lặng.", actionAttr: 'data-bj02-action="reload"' });
  if (state === "LOCKED") return k1Locked({ title: "Kho đang được khóa", description: "Chỉ có thể xem dữ liệu. Mở công việc đang giữ khóa để biết thêm chi tiết." });
  if (state === "READ_ONLY") return k1Locked({ title: "Chế độ chỉ xem", description: "Dữ liệu vẫn hiển thị nhưng mọi thao tác thay đổi đã bị khóa." });
  return stateBanner(state);
}
// Chân màn có dòng lý do ngay trên nút (hiện khi nút tắt).
function bj02Footer(label, attr, disabled = false, reason = "") {
  return k4ReasonFooter({ label, attr, disabled, reason });
}

/* ---------- Số liệu và quy tắc (không đổi) ---------- */

function bj02AcceptedPhysical(line) {
 return lineTotals(line).physicalIncrease;
}
function bj02AcceptedPhysicalTotal() {
 return bj02Lines.reduce((n,line)=>n+bj02AcceptedPhysical(line),0);
}
function bj02SourceRemaining(line) {
 return Math.max(0,Number(line?.remainingReceivableQty)||0);
}
// Một ô hạn dùng / ngày sản xuất: "30/11/2026", "11/2026" hoặc "2026"; độ chính xác tự suy.
function bj02ExpiryParse(text) {
  const v = String(text || "").trim();
  if (/^\d{4}$/.test(v)) return { precision: "YEAR", valid: Number(v) >= 1900 && Number(v) <= 2200 };
  if (/^(0?[1-9]|1[0-2])[\/\-]\d{4}$/.test(v)) return { precision: "MONTH", valid: true };
  const m = v.match(/^(0?[1-9]|[12]\d|3[01])[\/\-](0?[1-9]|1[0-2])[\/\-](\d{4})$/);
  if (m) return { precision: "DAY", valid: Number(m[1]) <= new Date(Number(m[3]), Number(m[2]), 0).getDate() };
  return { precision: "DAY", valid: false };
}
function bj02EvidenceRefs() {
  const refs=Array.isArray(bj02Header.evidenceRefs)?bj02Header.evidenceRefs:[];
  if(refs.length) return refs;
  return bj02Header.evidence ? [{id:'EV-LEGACY-1',name:bj02Header.evidence,type:'DELIVERY_DOCUMENT'}] : [];
}
function bj02OwnershipReady() { return true; } // v5.28.0: bỏ chứng từ giao nhận + xác nhận sở hữu
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
// Đổi bộ chứng từ: lời xác nhận đã tick theo bộ mới nếu còn tệp, mất nếu hết tệp.
function bj02RefreshOwnership() {
  if (!bj02OwnershipReady()) return;
  if (bj02EvidenceRefs().length) bj02MakeOwnershipAssertion(); else bj02Header.ownershipAssertion = null;
}
function bj02SupplierValid() {
  return supplierCatalog.some((x)=>x.id===bj02Header.supplierId&&x.name===bj02Header.supplier.trim());
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
    productRef: raw.productRef !== undefined ? raw.productRef : (product.productRef ?? null),
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
  bj02WebLineId = null;
  lineEditorDraft = null;
  activeLotDraftId = null;
  lotManufactureExpanded = false;
  lineProductMenuOpen = false;
  quickOverviewProductQuery = "";
  quickOverviewProductMenuOpen = false;
  quickOverviewPendingProductId = null;
  quickOverviewDuplicateLineId = null;
  quickLineSequence = 1;
  supplierMenuOpen = false;
  supplierSearchQuery = "";
  bj02ReviewOpenLineId = null;
  bj02ScanOpen = false; bj02RejectOpen = false; bj02LinesSheetOpen = false; bj02Confirm = null;
  BJ02_CONTEXT.evidenceSheetOpen = false; BJ02_CONTEXT.changeSourceConfirmOpen = false;
  bj02Approver = null;
  lineSearchQuery = "";
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
// Bắt đầu một lần nhận mới do người dùng: các màn sau 009 về trạng thái mặc định (URL ?state= vẫn giữ ở lần nạp đầu).
function bj02ResetFlowStates() {
  stateByScreen["SCR-010"] = "READY"; stateByScreen["SCR-011"] = "READY"; stateByScreen["SCR-012"] = "COMPLETED"; stateByScreen["SCR-013"] = "PROCESSING_OR_UNKNOWN";
}
resetBj02Receipt(flowMode);

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
function lotDraftTotals(lot) {
  const accepted = Math.max(0, Number(lot?.accepted) || 0);
  const quarantine = Math.max(0, Number(lot?.quarantine) || 0);
  const damaged = Math.max(0, Number(lot?.damaged) || 0);
  const rejected = Math.max(0, Number(lot?.rejected) || 0);
  return { totalReceived: accepted + quarantine + damaged + rejected, accepted, quarantine, damaged, rejected };
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
function bj02LineOver(line) { return flowMode==='document' && lineAcceptedBase(line)>documentLineAllowanceBase(line); }
function bj02RequiresApproval() { return false; } // v5.28.0: không còn duyệt (K2)
function receiptRiskValue() {
  return bj02Lines.reduce((sum,line)=>{
    const basis=line.priceBasisSnapshot || productById(line.productId)?.priceBasisSnapshot;
    return sum + lineAcceptedBase(line)*(Number(basis?.unitPriceVndPerBase)||0);
  },0);
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
function bj02LineValue(line) { return lineTotals(line).accepted * (Number(line?.unitPrice) || 0); }
function bj02ReceiptValue() { return bj02Lines.reduce((n, line) => n + bj02LineValue(line), 0); }
function bj02ReviewProductCount() {
  return new Set(bj02Lines.map((line) => line.productId)).size;
}

/* ---------- Fixture xem trước ---------- */

function bj02SeedDocumentLines(forceApproval=false){
  // v5.28.0: fixture là một phiếu nhận theo NCC (không còn chứng từ mua).
  flowMode="quick";
  if(!bj02Header.supplierId){ bj02Header={...bj02Header,supplierId:"SUP-MINH-DUNG",supplier:"Minh Dũng",supplierDocNo:"HĐ 0001523"}; }
  if(!bj02Lines.length) bj02Lines=[
    hydrateReceiptLine({id:"QUICK-S1",productId:"P-NOB-DHPP",uomId:"UOM-BOX",uom:"hộp",trackingPolicy:"LOT",expiryRequired:true,remainingReceivableQty:20,unitPrice:118000,lots:[]}),
    hydrateReceiptLine({id:"QUICK-S2",productId:"P-OXY-LA",uomId:"UOM-BOTTLE",uom:"chai",trackingPolicy:"NONE",expiryRequired:false,remainingReceivableQty:24,unitPrice:95000,lots:[]}),
  ];
  bj02Lines.forEach((line,idx)=>{
    const expected=Math.max(1,Number(line.remainingReceivableQty)||1);
    const received=expected; line.remainingReceivableQty=null;
    line.status="COMPLETED";
    line.accepted=received; line.quarantine=0; line.damaged=0; line.rejected=0; line.totalReceived=received;
    if(line.trackingPolicy==="LOT"){
      line.lots=[{id:`V360-L${idx+1}`,code:"DH2507",expiry:"30/11/2026",expiryPrecision:"DAY",manufactureDate:"",manufacturePrecision:"DAY",accepted:received,totalReceived:received,quarantine:0,damaged:0,rejected:0}];
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
    lotManufactureExpanded=Boolean(lineEditorDraft?.lots?.[0]?.manufactureDate);
    return;
  }
  if(activeScreenId==="SCR-010" && ["READY","APPROVAL_REQUIRED","PENDING_APPROVAL","REJECTED"].includes(st)){
    // Vào thẳng rà soát cần fixture mẫu, nhưng lần nhận người dùng đang làm dở không bao giờ bị ghi đè.
    if(!bj02Lines.length || (!allReceiptLinesHandled() && !bj02HasExplicitDraftData())) bj02SeedDocumentLines(false);
    return;
  }
  if(activeScreenId==="SCR-011" && ["READY","APPROVAL_REQUIRED","APPROVAL_REVIEW","REJECTED_DONE"].includes(st)){
    if(!bj02Lines.length || !allReceiptLinesHandled() || !bj02RequiresApproval()) bj02SeedDocumentLines(true);
    return;
  }
  if(activeScreenId==="SCR-012" && ["COMPLETED","VALUATION_PENDING_RESULT"].includes(st)){
    if(!bj02Lines.length || !allReceiptLinesHandled()) bj02SeedDocumentLines(false);
  }
}

/* ---------- Thành phần dùng ở nhiều màn ---------- */

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
function bj02KeyValueRow(label, value, emphasis = false, extraClass = "", valueAttr = "") {
  let display = value;
  if (typeof display === "string" && /^-\d/.test(display)) display = "−" + display.slice(1);
  const classes = ["bj02-key-value-row", emphasis ? "is-emphasis" : "", extraClass].filter(Boolean).join(" ");
  return `<div class="${classes}" data-ds-component="DS v2 / Key-value Row" data-figma-node="525:358" data-ds-prop-state="${emphasis ? "Emphasis" : "Default"}"><span>${escapeAttribute(label)}</span><strong ${valueAttr}>${escapeAttribute(display)}</strong></div>`;
}
function bj02ReceiptDate() { return formatIsoDate(bj02Header.businessDate||BJ02_CONTEXT.tenantBusinessDate); }
// Một dòng ngữ cảnh lần nhận (009, 010): "PN-260816-04 · Minh Dũng" / "Nhập nhanh · {NCC}" + kho, ngày; edit = { label, attr } cho liên kết bên phải.
function bj02ContextRow(edit = null) {
  const quick = flowMode === "quick";
  const title = `${currentReceiptSupplier() || "Chưa chọn nhà cung cấp"}${bj02Header.supplierDocNo ? ` · ${bj02Header.supplierDocNo}` : ""}`;
  const trailing = edit ? `<button class="inline-edit bj02-context-edit" type="button" ${edit.attr} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.link">${esc(edit.label)}</button>` : "";
  return ds24ListRow({ title, subtitle: `${BJ02_CONTEXT.warehouse.name} · nhận ${bj02ReceiptDate()}`, trailing, leading: "warehouse", type: "Status", density: "Compact", interactive: false, extraClass: "bj02-context-row" });
}
function bj02Progress() {
  const done = receiptHandledCount(), total = bj02Lines.length;
  if (!total) return "";
  return `<div class="bj02-progress-block" data-ds-component="VProgress"><div class="bj02-progress" role="progressbar" aria-label="Tiến độ xử lý" aria-valuemin="0" aria-valuemax="${total}" aria-valuenow="${done}"><span style="width:${Math.round(done / total * 100)}%"></span></div><small>Đã xử lý ${done}/${total} mặt hàng</small></div>`;
}
function bj02IssueBadge(line) {
  if (!lineHandled(line)) return "";
  const issue = bj02ReviewIssue(line);
  if (!issue) return ds24Badge("Đã xong", "Success");
  return ds24Badge(issue.label, { warning: "Warning", error: "Danger", info: "Info" }[issue.tone] || "Neutral");
}
// Số bên phải dòng: "{nhận} / {chứng từ}" theo chứng từ, "{nhận} {ĐVT}" khi nhập nhanh; chưa xử lý thì "—".
function bj02LineQuantity(line) {
  const docLine = flowMode === "document" && line.remainingReceivableQty != null;
  const received = line.status === "NOT_RECEIVED" ? 0 : lineTotals(line).physicalIncrease;
  const shown = lineHandled(line) ? String(received) : "—";
  return docLine ? `${shown} / ${bj02SourceRemaining(line)}` : (lineHandled(line) ? `${shown} ${line.uom || ""}`.trim() : shown);
}
function bj02LineSubtitle(line) {
  if (flowMode === "document" && line.remainingReceivableQty != null && !lineHandled(line)) return `Còn chờ nhận ${line.remainingReceivableQty} ${line.uom}`;
  return [line.sku || line.productId, line.unitPrice ? `${cfMoney(line.unitPrice)}/${line.uom}` : line.uom].filter(Boolean).join(" · ");
}
function bj02LineRow(line, attrs) {
  return ds24StockRow({ title: line.name, subtitle: bj02LineSubtitle(line), quantity: bj02LineQuantity(line), badge: bj02IssueBadge(line), attrs });
}
// Dòng chỉ đọc (sheet "Xem n dòng hàng", thẻ trên iPhone của bảng duyệt).
function bj02ReadOnlyLine(line) {
  const lots = line.trackingPolicy === "LOT" ? (line.lots || []).filter((lot) => lotDraftTotals(lot).totalReceived > 0).map((lot) => [lot.code || "—", lot.expiry ? `HSD ${lot.expiry}` : ""].filter(Boolean).join(" · ")).join("; ") : "";
  const subtitle = [bj02LineSubtitle(line), lots].filter(Boolean).join(" · ");
  return ds24ListRow({ title: line.name, subtitle, trailing: `<span class="bj02-line-qty">${esc(bj02LineQuantity(line))}</span>${bj02IssueBadge(line)}`, leading: null, type: "Status", density: "Compact", interactive: false, extraClass: "bj02-readonly-line" });
}
function bj02ConfirmSheet() {
  if (!bj02Confirm) return "";
  const cfg = {
    "remove-lot": { title: "Xóa lô này?", text: "Số lượng và thông tin đã nhập cho lô sẽ bị xóa khỏi dòng hàng.", cancel: "Giữ lô", ok: "Xóa lô", danger: true },
    "remove-line": { title: "Xóa khỏi lần nhận?", text: "Toàn bộ số lượng và thông tin lô của dòng hàng này sẽ bị xóa.", cancel: "Giữ lại", ok: "Xóa", danger: true },
    "not-received": { title: "Đánh dấu chưa nhận lần này?", text: "Số lượng và thông tin lô đã nhập cho dòng hàng này sẽ được xóa. Phần còn lại trên chứng từ vẫn được giữ.", cancel: "Giữ dữ liệu", ok: "Chưa nhận lần này", danger: true },
    "change-source": { title: "Đổi chứng từ?", text: "Đổi chứng từ sẽ xóa dữ liệu nhận hàng đang nhập để tránh giữ lại số lượng, lô hoặc phiên bản chứng từ không còn đúng.", cancel: "Giữ chứng từ", ok: "Đổi chứng từ", danger: false },
  }[bj02Confirm.kind];
  return `<div class="confirm-backdrop" data-bj02-action="confirm-close"><section class="confirm-dialog" data-ds-component="DS v2 / Confirmation Sheet" data-figma-node="550:1058" data-ds-prop-is-destructive="${cfg.danger}" role="dialog" aria-modal="true" aria-label="${escapeAttribute(cfg.title)}" onclick="event.stopPropagation()"><h3>${esc(cfg.title)}</h3><p>${esc(cfg.text)}</p><div class="confirm-dialog-actions"><button class="button button--secondary" data-bj02-action="confirm-close" type="button">${esc(cfg.cancel)}</button><button class="button button--primary" data-bj02-action="confirm-ok" data-ds-prop-tone="VComponentTone.${cfg.danger ? "danger" : "primary"}" type="button">${esc(cfg.ok)}</button></div></section></div>`;
}
function bj02ReviewDetailSheet() {
  if (!bj02ReviewOpenLineId) return "";
  const line = bj02Lines.find((item) => item.id === bj02ReviewOpenLineId);
  if (!line) return "";
  const t = lineTotals(line);
  const quantityRows = [
    ["Số lượng nhận", `${t.accepted} ${line.uom}`], ["Giá mua", line.unitPrice ? `${cfMoney(line.unitPrice)}/${line.uom}` : "—"], ["Thành tiền", cfMoney(bj02LineValue(line))],
  ].map(([label, value]) => bj02InfoRow(label, value)).join("");
  const lotRows = line.trackingPolicy === "LOT" ? (line.lots || []).filter((lot) => lotDraftTotals(lot).totalReceived > 0).map((lot) => {
    const lt = lotDraftTotals(lot);
    return `<div class="bj02-review-lot-group"><div class="bj02-review-lot-title"><strong>Lô ${escapeAttribute(lot.code || "—")}</strong>${lot.expiry ? `<span>HSD ${escapeAttribute(lot.expiry)}</span>` : ""}</div>${bj02InfoRow("Số lượng", `${lt.totalReceived} ${line.uom}`)}</div>`;
  }).join("") : "";
  const issue = bj02ReviewIssue(line);
  const issueBanner = issue ? vBanner(issue.tone === "error" ? "error" : issue.tone, issue.label, "Kiểm tra lại dòng hàng này trước khi xác nhận hồ sơ.", "", "Compact") : "";
  return `<div class="sheet-backdrop bj02-review-detail-backdrop" data-bj02-review-close><section class="bj02-review-detail-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" data-ds-prop-show-title="true" role="dialog" aria-modal="true" aria-label="Chi tiết ${escapeAttribute(line.name)}" onclick="event.stopPropagation()"><div class="bj02-review-sheet-handle"></div><h2>${escapeAttribute(line.name)}</h2><p class="bj02-review-sheet-context">${escapeAttribute(line.sku || line.productId)} · ${escapeAttribute(line.uom)}</p>${issueBanner}<section class="bj02-review-detail-section" data-ds-component="VSection"><div class="bj02-review-detail-heading"><strong>Số lượng và giá</strong><span>${t.totalReceived} ${line.uom}</span></div><div class="bj02-review-detail-rows">${quantityRows || bj02InfoRow("Tổng kiểm nhận", `${t.totalReceived} ${line.uom}`)}</div></section>${lotRows ? `<section class="bj02-review-detail-section" data-ds-component="VSection"><div class="bj02-review-detail-heading"><strong>Lô và hạn dùng</strong><span>${(line.lots || []).filter((lot) => lotDraftTotals(lot).totalReceived > 0).length} lô</span></div><div class="bj02-review-lot-list">${lotRows}</div></section>` : ""}<button class="button button--secondary button--full bj02-review-close-button" data-bj02-review-close type="button" data-ds-component="VButton">Đóng</button></section></div>`;
}
function bj02LinesSheet() {
  if (!bj02LinesSheetOpen) return "";
  return ds24Sheet({ title: "Hàng thực nhận", attrs: 'data-bj02-action="close-lines"', body: `<div class="ds24-list-stack bj02-lines-sheet">${bj02Lines.map(bj02ReadOnlyLine).join("")}</div><button class="ds24-button ds24-button--secondary" data-bj02-action="close-lines" type="button" data-ds-component="VButton" data-figma-node="521:529">Đóng</button>` });
}
function bj02EvidenceSheet() {
  if (!BJ02_CONTEXT.evidenceSheetOpen) return "";
  const refs = flowMode === "quick" ? bj02EvidenceRefs() : [{ id: documentContext().sourceDocumentRef || selectedDocumentId, name: selectedDocumentId, type: "SOURCE_DOCUMENT" }];
  const rows = refs.map((ref) => ds24ListRow({ title: ref.name, subtitle: ref.type === "SOURCE_DOCUMENT" ? "Chứng từ nguồn" : "Chứng từ giao nhận", leading: "fileText", type: "Status", density: "Compact", interactive: false, trailing: `<button class="button button--tertiary" type="button" data-bj02-action="preview-file" data-ds-component="VButton">Xem</button>` })).join("");
  return ds24Sheet({ title: "Chứng từ giao nhận", attrs: 'data-bj02-action="close-evidence"', body: `<p class="ds24-context vet45-text-style-7">Bằng chứng đã khóa theo phiên bản yêu cầu gửi duyệt.</p><div class="ds24-list-stack">${rows}</div><button class="ds24-button ds24-button--secondary" data-bj02-action="close-evidence" type="button" data-ds-component="VButton" data-figma-node="521:529">Đóng</button>` });
}
function bj02ScanSheet() {
  if (!bj02ScanOpen) return "";
  const sample = productById("P-OXY-LA");
  return ds24Sheet({ title: "Quét mã vạch", attrs: 'data-bj02-action="scan-close"', body: `<div class="bj01-scan-frame" aria-hidden="true">${icon("scan")}</div><p class="ds24-context vet45-text-style-7">Đưa mã vạch vào khung</p><button class="ds24-button ds24-button--secondary" data-bj02-scan-sample="${sample.id}" type="button" data-ds-component="VButton" data-figma-node="521:529">Quét thử: ${esc(sample.name)}</button>` });
}
function bj02SupplierSelectSheet(locked=false) {
  if(!supplierMenuOpen||locked) return '';
  const options=supplierCatalog.map((supplier)=>{
    const selected=supplier.id===bj02Header.supplierId;
    return `<button class="bj02-sheet-list-row${selected?' is-selected':''}" data-bj02-supplier-option="${supplier.id}" data-bj02-supplier-search-text="${escapeAttribute(`${supplier.name} ${supplier.code}`.toLowerCase())}" data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="Selection" data-ds-prop-density="Default" data-ds-prop-state="${selected?'Selected':'Default'}" type="button" role="option" aria-selected="${selected}"><span class="bj02-ds-list-leading">${icon('user','icon--sm')}</span><span class="bj02-ds-list-copy"><strong>${esc(supplier.name)}</strong><span>${esc(supplier.code)}</span></span><span class="bj02-radio-control" aria-hidden="true"></span></button>`;
  }).join('');
  return `<div class="bj02-select-backdrop" data-bj02-supplier-backdrop><section class="bj02-select-sheet" data-ds-component="DS v2 / Select Sheet" data-figma-node="550:1148" role="dialog" aria-modal="true" aria-label="Chọn nhà cung cấp"><div class="bj02-sheet-handle"></div><h2>Chọn nhà cung cấp</h2><div class="bj02-sheet-search" data-ds-component="VSearchBar" data-figma-node="522:7245"><span>${icon('search','icon--sm')}</span><input data-bj02-supplier-search value="${escapeAttribute(supplierSearchQuery)}" placeholder="Tìm tên hoặc mã nhà cung cấp" autocomplete="off" aria-label="Tìm nhà cung cấp" /></div><div class="bj02-sheet-list" data-bj02-supplier-menu role="listbox">${options}<div class="combobox-empty" data-bj02-supplier-empty hidden>Không có nhà cung cấp phù hợp. Nhà cung cấp phải được tạo trước ở Theme 3.</div></div></section></div>`;
}

/* ---------- SCR-007 Nhận hàng (chứng từ chờ nhận + hàng đến chưa có chứng từ) ---------- */

function bj02DocumentRows() {
  return Object.entries(documentReceiptCatalog).map(([id, doc]) => {
    const names = doc.lines.map((l) => productById(l.productId)?.name).filter(Boolean);
    const itemsText = names.length > 2 ? `${names.slice(0, 2).join(", ")} +${names.length - 2}` : names.join(", ");
    const searchText = [id, doc.supplier, ...doc.lines.flatMap((l) => { const p = productById(l.productId); return [p?.name, p?.sku, p?.barcode]; })].filter(Boolean).join(" ").toLowerCase();
    return { id, supplier: doc.supplier, date: doc.documentDate, itemsText, count: doc.lines.length, status: doc.partial ? "Đã nhận một phần" : "", searchText };
  });
}
function bj02QuickEntry(state) {
  if (!BJ02_CONTEXT.capabilities.quickReceipt) return "";
  const blocker = BJ02_CONTEXT.quickBlocker;
  const disabled = state === "LOCKED" || Boolean(blocker);
  const row = ds24ListRow({ title: "Hàng đến chưa có chứng từ", subtitle: blocker || "Nhập hàng nhanh · cần chủ cửa hàng duyệt", leading: "zap", attrs: 'data-flow="quick"', disabled });
  return `<div class="k7-mobile-only"><section class="ds24-list-stack bj02-quick-entry" data-composed-from="DS v2 / List Row">${row}</section></div><div class="k7-web-only"><button class="button button--secondary bj02-quick-button" type="button" data-flow="quick" data-ds-component="VButton" ${disabled ? "disabled" : ""}>Hàng đến chưa có chứng từ</button></div>`;
}
// Phiếu nhận gần đây (fixture xem trước; app đọc từ phiếu đã ghi).
const BJ02_RECENT = [
  { ref: "REC-260915-02", supplier: "An Việt", doc: "HĐ 0004411", date: "15/09/2026", items: 3, value: 4850000 },
  { ref: "REC-260912-01", supplier: "Minh Dũng", doc: "HĐ 0001498", date: "12/09/2026", items: 2, value: 7460000 },
  { ref: "REC-260908-03", supplier: "Phương Nam", doc: "", date: "08/09/2026", items: 1, value: 1620000 },
];
function render007BJ02(state) {
  const title = "Nhận hàng";
  if (state === "PERMISSION_DENIED") return appShell({ title, body: bj02Denied("nhận hàng"), centered: true, back: false });
  if (state === "LOADING") return appShell({ title, body: k1Loading({ blocks: ["search", "row", "row", "row"] }), back: false });
  const start = primaryFooter("Lập phiếu nhận", 'data-flow="quick"', state === "LOCKED");
  if (state === "EMPTY") return appShell({ title, body: k1Empty({ title: "Chưa có phiếu nhận nào", description: "Lập phiếu khi hàng của nhà cung cấp về kho." }), actions: start, back: false, extraClass: "k7-wide" });
  const query = state === "FILTER_EMPTY" ? "Không có kết quả" : documentSearchQuery;
  const q = ioNormalizeSearch(query);
  const search = ds24Search(query, 'data-bj02-document-search', 'Tìm phiếu, nhà cung cấp hoặc số chứng từ');
  const rows = BJ02_RECENT.map((r) => { const searchText = [r.ref, r.supplier, r.doc].join(" ").toLowerCase(); return { ...r, searchText, hidden: Boolean(q) && !searchText.includes(q) }; });
  const visible = rows.filter((r) => !r.hidden).length;
  const rowAttr = (r) => `data-bj02-document-search-text="${escapeAttribute(r.searchText)}"${r.hidden ? " hidden" : ""}`;
  const columns = [{ key: "ref", label: "Phiếu nhận", mono: true }, { key: "supplier", label: "Nhà cung cấp" }, { key: "docText", label: "Số chứng từ NCC" }, { key: "date", label: "Ngày", mono: true }, { key: "itemsText", label: "Mặt hàng", align: "end" }, { key: "valueText", label: "Giá trị", align: "end", mono: true }];
  const tableRows = rows.map((r) => ({ ...r, docText: r.doc || "—", itemsText: `${r.items}`, valueText: cfMoney(r.value) }));
  const mobileRow = (r) => bj02RecordCard({ title: r.ref, supporting1: esc(r.supplier), supporting2: esc(r.doc || "Không có số chứng từ"), summary: `${r.items} mặt hàng · ${cfMoney(r.value)}`, timestamp: r.date, status: "Đã ghi nhận", attr: rowAttr(r) });
  const list = `${ac310SectionTitle("Phiếu nhận gần đây")}${k7Table({ columns, rows: tableRows, mobileRow, caption: "Phiếu nhận gần đây", rowAttr })}`;
  const noResult = `<div class="document-filter-empty" data-bj02-document-filter-empty ${visible ? "hidden" : ""}>${k1Empty({ title: "Không có kết quả phù hợp", description: "Thử mã phiếu, nhà cung cấp hoặc số chứng từ khác." })}</div>`;
  return appShell({ title, body: `${bj02StateNotice(state)}${search}${list}${noResult}`, actions: start, back: false, extraClass: "k7-wide" });
}

/* ---------- SCR-008 Thông tin nhập hàng nhanh ---------- */

function bj02EvidenceZone(locked) {
  const refs = bj02EvidenceRefs();
  const files = refs.length ? `<ul class="bj02-files" aria-label="Tệp đã chọn">${refs.map((x) => `<li>${icon("fileText", "icon--sm")}<span>${esc(x.name)}</span><button class="button button--tertiary" type="button" data-bj02-evidence-remove="${escapeAttribute(x.id)}" aria-label="Xoá ${escapeAttribute(x.name)}" ${locked ? "disabled" : ""}>Xoá</button></li>`).join("")}</ul>` : "";
  const pick = `<label class="button button--secondary bj02-pick-file${locked ? " is-disabled" : ""}"><input data-bj02-evidence-file type="file" multiple ${locked ? "disabled" : ""}>Chọn tệp</label>`;
  const camera = `<button class="button button--secondary" type="button" data-bj02-evidence-camera ${locked ? "disabled" : ""}>Chụp ảnh</button>`;
  return `<div class="form-field bj02-evidence" data-ds-component="VFileDropZone" data-figma-node="522:7507"><label>Chứng từ giao nhận <span class="required">*</span></label><div class="bj02-evidence__zone">${icon("cloudUpload", "icon--24")}<span class="bj02-evidence__copy"><strong>${refs.length ? "Đã chọn chứng từ" : "Phiếu giao hàng hoặc biên bản bàn giao"}</strong><small class="k7-web-only">Kéo tệp vào đây hoặc Chọn tệp</small><small class="k7-mobile-only">Chụp ảnh phiếu giao hoặc chọn tệp có sẵn</small></span><div class="k7-mobile-only"><div class="bj02-evidence__actions">${camera}${pick}</div></div><div class="k7-web-only"><div class="bj02-evidence__actions">${pick}</div></div></div>${files}</div>`;
}
function bj02OwnershipCheck(locked) {
  const on = bj02OwnershipReady();
  return `<button class="bj02-check${on ? " is-checked" : ""}" type="button" role="checkbox" aria-checked="${on}" data-bj02-ownership ${locked ? "disabled" : ""}><span class="bj02-check__box" aria-hidden="true">${on ? icon("check", "icon--sm") : ""}</span><span class="bj02-check__copy"><strong>Tôi xác nhận hàng này thuộc sở hữu của cửa hàng</strong><small>Hệ thống lưu người xác nhận, thời điểm và chứng từ giao nhận.</small></span></button>`;
}
function bj02QuickBlockedReason() {
  if (!bj02SupplierValid()) return "Chọn nhà cung cấp trong danh sách.";
  return "";
}
function render008BJ02(state) {
  const title = "Phiếu nhận hàng";
  if (state === "PERMISSION_DENIED") return appShell({ title, body: bj02Denied("nhận hàng"), centered: true, extraClass: "k7-wide" });
  const locked = state === "LOCKED", hasError = state === "VALIDATION_ERROR";
  const supplierValid = bj02SupplierValid();
  const supplierValue = supplierValid ? bj02Header.supplier : "Chọn nhà cung cấp";
  const body = `${bj02StateNotice(state === "VALIDATION_ERROR" ? "" : state)}<div class="form-stack quick-source-form bj02-quick-grid">
      <div class="form-field supplier-field${locked ? " is-disabled" : ""}" data-ds-component="VSelect" data-figma-node="522:7291"><label>Nhà cung cấp <span class="required">*</span></label><button class="bj02-vselect-trigger${supplierValid ? " is-filled" : ""}${hasError && !supplierValid ? " is-error" : ""}" data-bj02-open-supplier-sheet type="button" ${locked ? "disabled" : ""}><span>${esc(supplierValue)}</span>${icon("chevronDown", "icon--sm")}</button>${hasError && !supplierValid ? '<span class="field-error" data-bj02-supplier-error>Chọn nhà cung cấp trong danh sách.</span>' : '<span class="field-error" data-bj02-supplier-error hidden>Chọn nhà cung cấp trong danh sách.</span>'}</div>
      <div class="form-field" data-ds-component="VTextField" data-figma-node="522:7186" data-ds-prop-state="Filled"><label>Kho và ngày nhận</label><span class="input-shell is-readonly"><input value="${escapeAttribute(`${BJ02_CONTEXT.warehouse.name} · ${bj02ReceiptDate()}`)}" disabled aria-disabled="true" aria-label="Kho và ngày nhận"/></span></div>
      <div class="form-field" data-ds-component="VTextField" data-figma-node="522:7186"><label>Số chứng từ của nhà cung cấp</label><span class="input-shell"><input data-bj02-supplier-doc value="${escapeAttribute(bj02Header.supplierDocNo || "")}" placeholder="Ví dụ: HĐ 0001523" autocomplete="off" aria-label="Số chứng từ của nhà cung cấp" ${locked ? "disabled" : ""}/></span><small class="field-help">Số hoá đơn hoặc phiếu giao hàng, nếu có.</small></div>
    </div>${bj02SupplierSelectSheet(locked)}`;
  const reason = locked ? "" : bj02QuickBlockedReason();
  const disabled = locked || Boolean(reason) || !BJ02_CONTEXT.capabilities.assertOwnership;
  return appShell({ title, body, actions: bj02Footer("Tiếp tục", "data-bj02-quick-continue", disabled, reason), extraClass: "k7-wide" });
}

/* ---------- SCR-009 Hàng thực nhận ---------- */

function receiptLineList() {
  const q = ioNormalizeSearch(lineSearchQuery);
  const web = viewport === "web";
  return `<section class="ds24-list-stack receipt-line-list" data-composed-from="DS v2 / List Row">${bj02Lines.map((line) => {
    const text = `${line.name} ${line.sku || ""} ${productById(line.productId)?.barcode || ""}`.toLowerCase();
    return bj02LineRow(line, `data-bj02-line-id="${line.id}" data-bj02-line-search-text="${escapeAttribute(text)}"${web && line.id === bj02WebLineId ? ' aria-current="true"' : ""}${q && !text.includes(q) ? " hidden" : ""}`);
  }).join("")}</section><div data-bj02-line-filter-empty hidden>${k1Empty({ title: "Không có kết quả phù hợp", description: "Thử tên hoặc mã mặt hàng khác." })}</div>`;
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
  const scan = `<button type="button" class="ds24-search__action" data-bj02-action="scan-open" aria-label="Quét mã vạch">${icon("scan", "icon--sm")}</button>`;
  return `<section class="quick-overview-add" data-ds-role="product-search-composition" data-composed-from="VSearchBar,DS v2 / List Row"><div class="quick-overview-search-wrap"><div class="search-box quick-overview-search" data-ds-component="VSearchBar" data-figma-node="522:7245" data-ds-profile="search.standard" data-ds-prop-hint-text="Tìm tên, mã mặt hàng hoặc mã vạch"><span class="search-leading">${icon("search", "icon--sm")}</span><input data-bj02-overview-product-search value="${escapeAttribute(quickOverviewProductQuery)}" placeholder="Tìm tên, mã mặt hàng hoặc mã vạch" aria-label="Tìm mặt hàng" aria-expanded="${quickOverviewProductMenuOpen}"/>${scan}</div><div class="combobox-menu quick-overview-product-menu ${quickOverviewProductMenuOpen ? "is-open" : ""}" data-bj02-overview-product-menu role="listbox" ${quickOverviewProductMenuOpen ? "" : "hidden"}>${options}<div class="combobox-empty" data-bj02-overview-product-empty hidden>Sản phẩm chưa có trong danh mục. Hãy bổ sung sản phẩm trước khi quay lại nhận hàng.</div></div></div>${uomPicker}</section>`;
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
function duplicateQuickLine(productId, uomId, excludingId = null) {
  return bj02Lines.find((line) => line.id !== excludingId && line.productId === productId && line.uomId === uomId) || null;
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
// Quét (hoặc gõ đúng mã vạch / SKU) một mặt hàng: theo chứng từ mở thẳng dòng đó; nhập nhanh thêm dòng.
function bj02ScanProduct(productId) {
  const product = productById(productId);
  if (!product) return;
  if (flowMode === "quick") return selectQuickOverviewProduct(product.id);
  const line = bj02Lines.find((item) => item.productId === product.id);
  if (!line) return showToast(`Không có ${product.name} trong chứng từ này`, "warning");
  lineSearchQuery = "";
  return beginLineEditor(line.id);
}
function bj02ExactProduct(text) {
  const v = String(text || "").trim().toLowerCase();
  if (!v) return null;
  const matches = bj02Lines.filter((line) => { const p = productById(line.productId); return p && (String(p.barcode).toLowerCase() === v || String(p.sku).toLowerCase() === v); });
  return matches.length === 1 ? matches[0] : null;
}
function filterLineRows(query) {
  lineSearchQuery = query;
  const normalized = ioNormalizeSearch(query);
  let visible = 0;
  document.querySelectorAll("[data-bj02-line-search-text]").forEach((row) => {
    const show = !normalized || row.dataset.bj02LineSearchText.includes(normalized);
    row.hidden = !show;
    if (show) visible += 1;
  });
  const empty = document.querySelector("[data-bj02-line-filter-empty]");
  if (empty) empty.hidden = visible > 0;
}
// Khung web: 009 và 084 là một màn hai cột — trái ngữ cảnh + danh sách mặt hàng, phải editor của dòng đang chọn.
// Dòng chọn mặc định = dòng chưa xử lý đầu tiên; đổi dòng thì nháp dòng cũ được giữ như nút quay lại của 084.
function bj02WebEnsureEditor() {
  if (!bj02Lines.length) return;
  let id = bj02WebLineId;
  if (!bj02Lines.some((line) => line.id === id)) id = (bj02Lines.find((line) => !lineHandled(line)) || bj02Lines[0]).id;
  bj02WebLineId = id;
  if (activeReceiptLineId !== id || !lineEditorDraft) bj02LoadLineEditor(id);
}
function render009BJ02(state, opts = {}) {
  const entrySubtitle = entryMode === "document-context" ? `Từ chứng từ ${selectedDocumentId}` : null;
  const title = "Hàng thực nhận";
  const wide = "k7-wide";
  if (state === "PERMISSION_DENIED") return appShell({ title, subtitle: entrySubtitle, body: bj02Denied("nhận hàng"), centered: true, extraClass: wide });
  if (state === "EMPTY") return appShell({ title, subtitle: entrySubtitle, body: `<div class="empty-state" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("package", "icon--empty-media")}</div><h3 data-ds-component="VEmptyTitle">Không có mặt hàng cần nhận</h3><p data-ds-component="VEmptyDescription">Không có dòng hàng phù hợp trong lần nhận hiện tại.</p></div>`, centered: true, extraClass: wide });
  const locked = ["LOCKED", "READ_ONLY"].includes(state);
  const quick = flowMode === "quick";
  const web = viewport === "web";
  if (web) bj02WebEnsureEditor();
  const empty = quick && bj02Lines.length === 0 && !quickOverviewPendingProductId ? `<div class="empty-state receipt-lines-empty" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("package", "icon--empty-media")}</div><h3 data-ds-component="VEmptyTitle">Chưa có mặt hàng trong lần nhận</h3><p data-ds-component="VEmptyDescription">Tìm mặt hàng ở trên để thêm. Sản phẩm phải có sẵn trong danh mục.</p></div>` : receiptLineList();
  const scan = `<button type="button" class="ds24-search__action" data-bj02-action="scan-open" aria-label="Quét mã vạch">${icon("scan", "icon--sm")}</button>`;
  const search = quick ? (locked ? "" : quickOverviewProductSearch()) : ds24Search(lineSearchQuery, 'data-bj02-line-search', 'Tìm mặt hàng hoặc quét mã vạch', locked ? "" : scan);
  const unhandled = bj02Lines.filter((line) => !lineHandled(line)).length;
  const reason = !bj02Lines.length ? "Thêm ít nhất một mặt hàng" : unhandled ? `Còn ${unhandled} mặt hàng chưa xử lý` : "";
  const main = `${bj02StateNotice(state)}${bj02ContextRow(quick && !locked ? { label: "Sửa", attr: 'data-next="SCR-008"' } : null)}${bj02Progress()}${quickOverviewDuplicateLineId ? `${vBanner("warning", "Sản phẩm và đơn vị này đã có", "Dòng hàng hiện có được giữ nguyên để tránh ghi trùng trong cùng lần nhận.")}<button class="button button--secondary button--full" data-bj02-action="open-existing-overview-line" data-bj02-line-id="${quickOverviewDuplicateLineId}" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" type="button">Mở dòng hàng hiện có</button>` : ""}${search}${empty}${bj02ScanSheet()}`;
  let body = main;
  if (web && lineEditorDraft && bj02Lines.length) {
    const editor = bj02LineEditorBody(opts.editorState || "READY");
    const save = editor.duplicate || editor.locked ? "" : bj02EditorSaveRow(editor.invalid, editor.reason);
    body = `<div class="bj02-linesplit">${k7Split({ main, aside: `${ac310SectionTitle("Chi tiết hàng thực nhận")}${editor.body}${save}`, asideWebOnly: true })}</div>${editor.duplicate ? "" : bj02ConfirmSheet()}`;
  }
  const disabled = locked || !allReceiptLinesHandled();
  return appShell({ title, subtitle: entrySubtitle, body, actions: bj02Footer("Rà soát", 'data-next="SCR-010"', disabled, locked ? "" : reason), backAction: entryMode === "document-context" ? "exit-receipt-document-context" : "", extraClass: wide });
}

/* ---------- SCR-084 Chi tiết hàng thực nhận ---------- */

// Nạp nháp của một dòng vào editor (không đổi màn). iPhone: beginLineEditor rồi sang SCR-084; web: editor nằm ngay ở SCR-009.
function bj02LoadLineEditor(lineId = null) {
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
  // Một lô mở một lúc: lô đầu chưa đủ thông tin (hoặc lô duy nhất) mở sẵn.
  activeLotDraftId = lineEditorDraft?.lots?.[0]?.id || null;
  const firstLot = lineEditorDraft?.lots?.find((lot) => lot.id === activeLotDraftId);
  lotManufactureExpanded = Boolean(firstLot?.manufactureDate);
  lineProductMenuOpen = !existing && flowMode === "quick";
}
const bj02EditorShown = () => bj02EditorForce || activeScreenId === "SCR-084" || (activeScreenId === "SCR-009" && viewport === "web");
function beginLineEditor(lineId = null) {
  if (viewport === "web" && lineId) {
    if (lineId === activeReceiptLineId && lineEditorDraft && activeScreenId === "SCR-009") { bj02WebLineId = lineId; return; }
    if (lineEditorDraft && activeReceiptLineId && activeReceiptLineId !== lineId && !lineEditorIsReadOnly() && bj02EditorShown()) persistLineEditorDraft(false);
    bj02LoadLineEditor(lineId); bj02WebLineId = lineId;
    return navigate("SCR-009");
  }
  bj02LoadLineEditor(lineId);
  navigate("SCR-084");
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
    ? `Còn chờ nhận ${lineEditorDraft.remainingReceivableQty} ${lineEditorDraft.uom || ""}`.trim()
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
// "Đạt" là ô số lớn nhập thẳng; Cách ly / Hỏng / Từ chối là ba ô nhỏ trên một hàng dưới nhãn "Hàng không đạt".
function bj02QtyInput(key, label, value, unit, locked, large) {
  return `<label class="bj02-qty${large ? " bj02-qty--main" : ""}"><span class="bj02-qty__label">${esc(label)}</span><span class="bj02-qty__box"><input type="text" inputmode="numeric" pattern="[0-9]*" autocomplete="off" data-bj02-qty="${key}" value="${value > 0 ? value : ""}" placeholder="0" aria-label="${escapeAttribute(label)}" ${locked ? "disabled" : ""}><em class="bj02-qty__unit" aria-hidden="true">${esc(unit)}</em></span></label>`;
}
function exceptionQuantitiesEditor(totals, locked = false) {
  const unit = lineEditorDraft?.uom || "";
  return `<div class="bj02-qty-editor" data-ds-role="quantity-input-composition" data-composed-from="VNumberField">${bj02QtyInput("accepted", "Số lượng nhận", totals.accepted || 0, unit, locked, true)}</div>`;
}
// Giá mua một đơn vị nhập (theo hoá đơn, gồm VAT — hộ kinh doanh không khấu trừ); một giá cho cả dòng.
function bj02PriceField() {
  const d = lineEditorDraft, locked = lineEditorIsReadOnly();
  return `<div class="form-field bj02-price-field" data-ds-component="VMoneyField"><label>Giá mua / ${esc(d?.uom || "đơn vị")} <span class="required">*</span></label><span class="input-shell"><input data-bj02-unit-price inputmode="numeric" value="${d?.unitPrice ? cfMoneyInput(String(d.unitPrice)) : ""}" placeholder="0" autocomplete="off" aria-label="Giá mua" ${locked ? "disabled" : ""}/><em class="bj02-qty__unit" aria-hidden="true">đ</em></span><small class="field-help">Theo hoá đơn, đã gồm VAT.</small></div>`;
}
function lineTotalSummaryHtml(line) {
  const t = lineTotals(line);
  const value = flowMode === "document" && line.remainingReceivableQty != null ? `${t.totalReceived} / ${line.remainingReceivableQty} ${line.uom}` : `${t.totalReceived} ${line.uom || ""}`.trim();
  return `${bj02KeyValueRow("Tổng nhận", value, false, "bj02-derived-total", "data-bj02-total")}${bj02KeyValueRow("Thành tiền", cfMoney(bj02LineValue(line)), true, "bj02-derived-total")}`;
}
function bj02FillButton() {
  const d = lineEditorDraft;
  if (flowMode !== "document" || d?.remainingReceivableQty == null || lineEditorIsReadOnly()) return "";
  return `<button class="button button--secondary bj02-fill-button" type="button" data-bj02-action="fill-remaining" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary">Nhận đủ ${d.remainingReceivableQty} ${esc(d.uom)}</button>`;
}
function renderNonLotLineEditor() {
  const t = lineTotals(lineEditorDraft);
  const locked = lineEditorIsReadOnly();
  return `<section class="line-entry-section">${bj02FillButton()}${exceptionQuantitiesEditor(t, locked)}${bj02PriceField()}${lineTotalSummaryHtml(lineEditorDraft)}<div class="editor-feedback document-variance-feedback" data-bj02-document-variance>${documentVarianceFeedback(lineEditorDraft)}</div></section>`;
}
function bj02DateField(label, field, value, { required = false, hint = "", locked = false } = {}) {
  const parsed = bj02ExpiryParse(value);
  const invalid = Boolean(String(value || "").trim()) && !parsed.valid;
  const errorText = field === "expiry" ? "Hạn dùng chưa đúng dạng" : "Ngày sản xuất chưa đúng dạng";
  return `<div class="form-field" data-ds-component="VTextField" data-figma-node="522:7186"><label>${label}${required ? ' <span class="required">*</span>' : ""}</label><span class="input-shell bj02-date-shell"><span class="bj02-date-leading">${icon("calendar", "icon--sm")}</span><input data-bj02-lot-field="${field}" value="${escapeAttribute(value)}" placeholder="dd/mm/yyyy" autocomplete="off" aria-label="${escapeAttribute(label)}" ${invalid ? 'aria-invalid="true"' : ""} ${locked ? "disabled" : ""}/></span><small class="field-error" data-bj02-date-error="${field}" role="alert" ${invalid ? "" : "hidden"}>${errorText}</small>${hint ? `<small class="field-help" data-bj02-date-help="${field}" ${invalid ? "hidden" : ""}>${hint}</small>` : ""}</div>`;
}
function renderLotCompact(lot, index, expanded = false) {
  const t = lotDraftTotals(lot);
  const canRemove = (lineEditorDraft.lots || []).length > 1;
  const label = [lot.code || `Lô ${index + 1}`, lot.expiry ? `HSD ${lot.expiry}` : "", t.totalReceived ? `${t.totalReceived} ${lineEditorDraft.uom}` : "Chưa hoàn tất"].filter(Boolean).join(" · ");
  return `<section class="lot-accordion-item bj02-lot ${expanded ? "is-expanded" : ""}" data-bj02-lot-item="${lot.id}"><div class="lot-accordion-header"><button class="lot-accordion-toggle" data-bj02-action="toggle-lot" data-bj02-lot-id="${lot.id}" data-ds-component="VSection" data-composed-from="VText,DS v2 / Icon Button" type="button" aria-expanded="${expanded}"><span class="lot-accordion-copy"><strong>${esc(label)}</strong></span><span class="lot-accordion-chevron ${expanded ? "is-expanded" : ""}">${icon("chevronDown", "icon--sm")}</span></button></div>${expanded ? renderActiveLotEditor(lot, canRemove) : ""}</section>`;
}
function renderActiveLotEditor(lot, canRemove = false) {
  const t = lotDraftTotals(lot), expiryRequired = Boolean(lineEditorDraft.expiryRequired), locked = lineEditorIsReadOnly();
  const manufacture = lotManufactureExpanded || lot.manufactureDate
    ? bj02DateField("Ngày sản xuất", "manufactureDate", lot.manufactureDate, { locked })
    : (!locked ? `<button class="button button--tertiary lot-extra-action" data-bj02-action="show-manufacture-date" data-ds-component="VButton" type="button">Thêm ngày sản xuất</button>` : "");
  return `<div class="active-lot-editor bj02-lot-editor" data-ds-role="lot-editor-composition" data-composed-from="VTextField,VButton"><div class="form-stack lot-fields-compact">
      <div class="form-field" data-ds-component="VTextField" data-figma-node="522:7186"><label>Mã lô <span class="required">*</span></label><span class="input-shell"><input data-bj02-lot-field="code" value="${escapeAttribute(lot.code)}" placeholder="Nhập mã trên bao bì" autocomplete="off" aria-label="Mã lô" ${locked ? "disabled" : ""}/></span></div>
      ${bj02DateField("Hạn dùng", "expiry", lot.expiry, { required: expiryRequired, hint: "Ghi như trên bao bì: ngày/tháng/năm, tháng/năm hoặc năm", locked })}
      ${manufacture}
      ${exceptionQuantitiesEditor(t, locked)}<div class="editor-feedback" data-bj02-lot-identity-feedback>${lotIdentityFeedback(lot)}</div>${canRemove && !locked ? `<button class="button button--tertiary lot-delete-action-inline" data-bj02-action="remove-editor-lot" data-bj02-lot-id="${lot.id}" data-ds-component="VButton" type="button">Xóa lô</button>` : ""}
    </div></div>`;
}
function renderLotLineEditor() {
  if (!lineEditorDraft.lots.length) lineEditorDraft.lots = [emptyLot()];
  const locked = lineEditorIsReadOnly();
  const rows = lineEditorDraft.lots.map((lot, index) => renderLotCompact(lot, index, lot.id === activeLotDraftId)).join("");
  return `<section class="lot-line-editor">${bj02FillButton()}<div class="section-label section-label--first lot-section-heading"><span>Các lô thực nhận</span></div><div class="lot-accordion-list">${rows}</div>${!locked ? `<button class="button button--secondary button--full add-lot-button" data-bj02-action="add-editor-lot" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.small" type="button">Thêm lô khác</button>` : ""}${bj02PriceField()}${lineTotalSummaryHtml(lineEditorDraft)}<div class="editor-feedback document-variance-feedback" data-bj02-document-variance>${documentVarianceFeedback(lineEditorDraft)}</div></section>`;
}
// Câu đầu tiên còn thiếu để bấm "Xong"; rỗng khi hợp lệ (hoặc chưa có gì để nhập).
function lineEditorInvalidReason() {
  const d = lineEditorDraft;
  if (!d?.productId || !d?.uomId) return "";
  if (flowMode === "quick" && duplicateQuickLine(d.productId, d.uomId, activeReceiptLineId)) return "";
  if (d.trackingPolicy === "LOT") {
    const lots = d.lots || [];
    if (!lots.length) return "Nhập mã lô";
    for (const lot of lots) {
      if (!String(lot.code || "").trim()) return "Nhập mã lô";
      if (duplicateLotDraft(lot.id, lot.code)) return "Lô này đã được thêm";
      const expiry = String(lot.expiry || "").trim(), manufacture = String(lot.manufactureDate || "").trim();
      if (d.expiryRequired && !expiry) return "Nhập hạn dùng";
      if (expiry && !bj02ExpiryParse(expiry).valid) return "Hạn dùng chưa đúng dạng";
      if (manufacture && !bj02ExpiryParse(manufacture).valid) return "Ngày sản xuất chưa đúng dạng";
      if (lotDraftTotals(lot).totalReceived <= 0) return "Nhập số lượng nhận.";
    }
    return Number(d.unitPrice) > 0 ? "" : "Nhập giá mua.";
  }
  if (lineTotals(d).totalReceived <= 0) return "Nhập số lượng nhận.";
  return Number(d.unitPrice) > 0 ? "" : "Nhập giá mua.";
}
function lineEditorValid() {
  if (!lineEditorDraft?.productId || !lineEditorDraft?.uomId) return false;
  if (flowMode === "quick" && duplicateQuickLine(lineEditorDraft.productId, lineEditorDraft.uomId, activeReceiptLineId)) return false;
  return lineEditorInvalidReason() === "";
}
// Thân editor của một dòng (SCR-084 trên iPhone, cột phải của SCR-009 trên web). Nút "Xong": chân màn iPhone / hàng nút trong cột phải web.
function bj02LineEditorBody(state) {
  const locked = lineEditorIsReadOnly();
  const product = productById(lineEditorDraft.productId);
  const duplicate = product && lineEditorDraft.uomId && flowMode === "quick" ? duplicateQuickLine(lineEditorDraft.productId, lineEditorDraft.uomId, activeReceiptLineId) : null;
  const productPicker = renderLineProductPicker();
  const duplicateNotice = duplicate ? `${vBanner("warning", "Sản phẩm và đơn vị này đã có", "Mở dòng hàng hiện có để tiếp tục, tránh ghi trùng trong cùng lần nhận.")}<button class="button button--secondary button--full" data-bj02-action="open-duplicate-line" data-bj02-line-id="${duplicate.id}" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" type="button">Mở sản phẩm đã có</button>` : "";
  const readOnlyNotice = locked && state !== "READ_ONLY" ? k1Locked({ title: "Chế độ chỉ xem", description: "Bạn có thể xem chi tiết nhưng không thể thay đổi lần nhận này." }) : bj02StateNotice(state);
  if (duplicate) return { body: `${readOnlyNotice}${productPicker}${duplicateNotice}`, duplicate: true, locked };
  const editor = product && lineEditorDraft.uomId ? (lineEditorDraft.trackingPolicy === "LOT" ? renderLotLineEditor() : renderNonLotLineEditor()) : "";
  const notReceived = flowMode === "document" && lineEditorDraft.remainingReceivableQty != null && !locked ? `<button class="button button--tertiary bj02-danger-link-action not-received-action" data-bj02-action="not-received" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.link" data-ds-prop-tone="VComponentTone.danger" type="button">Chưa nhận lần này</button>` : "";
  const removeQuickLine = flowMode === "quick" && activeReceiptLineId && !locked ? `<button class="button button--tertiary bj02-danger-link-action remove-line-action" data-bj02-action="remove-quick-line" data-bj02-line-id="${activeReceiptLineId}" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.link" data-ds-prop-tone="VComponentTone.danger" type="button">Xóa khỏi lần nhận</button>` : "";
  return { body: `${readOnlyNotice}${productPicker}${editor}${notReceived}${removeQuickLine}`, duplicate: false, locked, invalid: !lineEditorValid(), reason: lineEditorInvalidReason() };
}
function bj02EditorSaveRow(invalid, reason) {
  return `<div class="bj02-editor-actions"><p class="k4-reason-footer__reason" data-bj02-editor-reason${invalid && reason ? "" : " hidden"}>${esc(invalid ? reason : "")}</p><button class="button button--primary" type="button" data-bj02-action="save-line" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.primary" data-ds-prop-size="VButtonSize.medium"${invalid ? " disabled" : ""}>Xong</button></div>`;
}
function render084BJ02(state) {
  ensureBj02ReviewFixture();
  const title = "Chi tiết hàng thực nhận";
  if (state === "PERMISSION_DENIED") return appShell({ title, body: bj02Denied("nhận hàng"), centered: true, extraClass: "k7-wide" });
  // Web: không có màn riêng, là SCR-009 với dòng đang sửa được chọn.
  if (viewport === "web") return render009BJ02(stateByScreen["SCR-009"], { editorState: state });
  if (!lineEditorDraft) return appShell({ title, body: `<div class="empty-state" data-ds-component="VEmptyState"><h3 data-ds-component="VEmptyTitle">Chưa chọn sản phẩm</h3><p data-ds-component="VEmptyDescription">Quay lại Hàng thực nhận để chọn sản phẩm cần xử lý.</p></div>` });
  const parts = bj02LineEditorBody(state);
  if (parts.duplicate) return appShell({ title, body: parts.body, actions: "" });
  return appShell({ title, body: `${parts.body}${bj02ConfirmSheet()}`, actions: parts.locked ? "" : bj02Footer("Xong", 'data-bj02-action="save-line"', parts.invalid, parts.reason) });
}
function syncEditorDraftFromDom() {
  if (!bj02EditorShown() || !lineEditorDraft) return;
  const isLot = lineEditorDraft.trackingPolicy === "LOT";
  const lot = isLot ? lineEditorDraft.lots?.find((item) => item.id === activeLotDraftId) : null;
  const target = isLot ? lot : lineEditorDraft;
  if (target) document.querySelectorAll("[data-bj02-qty]").forEach((input) => { target[input.dataset.bj02Qty] = Math.max(0, parseInt(String(input.value).replace(/\D/g, ""), 10) || 0); });
  lineEditorDraft.totalReceived = lineTotals(lineEditorDraft).totalReceived;
  const price = document.querySelector("[data-bj02-unit-price]");
  if (price) lineEditorDraft.unitPrice = parseInt(String(price.value).replace(/\D/g, ""), 10) || 0;
  if (lot) {
    document.querySelectorAll("[data-bj02-lot-field]").forEach((input) => {
      const field = input.dataset.bj02LotField;
      lot[field] = input.value.trim();
      if (field === "expiry") { const p = bj02ExpiryParse(lot.expiry); if (p.valid) lot.expiryPrecision = p.precision; }
      if (field === "manufactureDate") { const p = bj02ExpiryParse(lot.manufactureDate); if (p.valid) lot.manufacturePrecision = p.precision; }
    });
    lot.totalReceived = lotDraftTotals(lot).totalReceived;
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
  lineEditorDraft.productId = product.id; lineEditorDraft.name = product.name; lineEditorDraft.sku = product.sku; lineEditorDraft.productRef = product.productRef ?? null;
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
// "Nhận đủ": Đạt = lượng còn chờ nhận (theo lô: lô đang mở, trừ phần các lô khác và hàng không đạt đã nhập). Vẫn phải bấm "Xong".
function bj02FillRemaining() {
  syncEditorDraftFromDom();
  const d = lineEditorDraft;
  if (!d || d.remainingReceivableQty == null) return;
  const remaining = bj02SourceRemaining(d);
  if (d.trackingPolicy === "LOT") {
    const lot = d.lots.find((item) => item.id === activeLotDraftId) || d.lots[0];
    if (!lot) return;
    const others = d.lots.filter((item) => item !== lot).reduce((n, item) => n + lotDraftTotals(item).accepted + lotDraftTotals(item).quarantine + lotDraftTotals(item).damaged, 0);
    lot.accepted = Math.max(0, remaining - others - (Number(lot.quarantine) || 0) - (Number(lot.damaged) || 0));
    lot.totalReceived = lotDraftTotals(lot).totalReceived;
    activeLotDraftId = lot.id;
  } else {
    d.accepted = Math.max(0, remaining - (Number(d.quarantine) || 0) - (Number(d.damaged) || 0));
  }
  lineEditorDraft.totalReceived = lineTotals(lineEditorDraft).totalReceived;
  lineEditorDirty = true;
  renderAppScreen();
}
function addEditorLot() {
  syncEditorDraftFromDom();
  lineEditorDirty = true;
  const lot = emptyLot();
  lineEditorDraft.lots.push(lot);
  activeLotDraftId = lot.id;
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
  bj02Confirm = null;
  renderAppScreen();
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
  if (bj02WebLineId === lineId) bj02WebLineId = null;
  bj02Confirm = null;
  navigate("SCR-009");
}
function markLineNotReceived() {
  if (!lineEditorDraft || flowMode !== "document") return;
  lineEditorDraft.status = "NOT_RECEIVED"; lineEditorDraft.accepted = 0; lineEditorDraft.totalReceived = 0; lineEditorDraft.quarantine = 0; lineEditorDraft.damaged = 0; lineEditorDraft.rejected = 0; lineEditorDraft.lots = [];
  const idx = bj02Lines.findIndex((line) => line.id === activeReceiptLineId); if (idx >= 0) bj02Lines[idx] = cloneBj02(lineEditorDraft);
  bj02Confirm = null;
  if (viewport === "web") return bj02WebAfterLine();
  navigate("SCR-009");
}
function filterLineProductOptions(query) {
  const menu=document.querySelector("[data-bj02-product-menu]"); if(!menu) return;
  const q=query.trim().toLowerCase(); let visible=0;
  menu.querySelectorAll("[data-bj02-product-option]").forEach((option)=>{ const match=!q || (option.dataset.bj02ProductSearchText || "").includes(q); option.hidden=!match; if(match) visible+=1; });
  const empty=menu.querySelector("[data-bj02-product-empty]"); if(empty) empty.hidden=visible>0;
}
// Gõ số / mã lô / hạn dùng không dựng lại màn (giữ con trỏ): chỉ cập nhật chỗ cần đổi.
function updateBj02EditorLiveFeedback() {
  if (!bj02EditorShown() || !lineEditorDraft) return;
  const valid = lineEditorValid();
  const saveButton = document.querySelector('[data-bj02-action="save-line"]');
  if (saveButton) saveButton.disabled = !valid;
  const reasonLine = document.querySelector("[data-bj02-editor-reason], [data-k4-reason]");
  if (reasonLine) { const reason = valid ? "" : lineEditorInvalidReason(); reasonLine.textContent = reason; reasonLine.hidden = !reason; }
  const activeLot = lineEditorDraft.lots?.find((lot) => lot.id === activeLotDraftId);
  const lotTarget = document.querySelector("[data-bj02-lot-identity-feedback]");
  if (lotTarget) lotTarget.innerHTML = activeLot ? lotIdentityFeedback(activeLot) : "";
  const varianceTarget = document.querySelector("[data-bj02-document-variance]");
  if (varianceTarget) varianceTarget.innerHTML = documentVarianceFeedback(lineEditorDraft);
  const totalSummary = document.querySelector("[data-bj02-total]");
  if (totalSummary) {
    const t = lineTotals(lineEditorDraft);
    totalSummary.textContent = `${t.totalReceived} ${lineEditorDraft.uom || ""}`.trim();
    const valueRow = totalSummary.closest(".bj02-derived-total")?.nextElementSibling?.querySelector("strong");
    if (valueRow) valueRow.textContent = cfMoney(bj02LineValue(lineEditorDraft));
  }
  ["expiry", "manufactureDate"].forEach((field) => {
    const input = document.querySelector(`[data-bj02-lot-field="${field}"]`);
    if (!input) return;
    const invalid = Boolean(input.value.trim()) && !bj02ExpiryParse(input.value).valid;
    const error = document.querySelector(`[data-bj02-date-error="${field}"]`), help = document.querySelector(`[data-bj02-date-help="${field}"]`);
    if (error) error.hidden = !invalid;
    if (help) help.hidden = invalid;
    if (invalid) input.setAttribute("aria-invalid", "true"); else input.removeAttribute("aria-invalid");
  });
  const compact = document.querySelector(".bj02-lot.is-expanded .lot-accordion-copy strong");
  if (compact && activeLot) {
    const index = lineEditorDraft.lots.indexOf(activeLot), t = lotDraftTotals(activeLot);
    compact.textContent = [activeLot.code || `Lô ${index + 1}`, activeLot.expiry ? `HSD ${activeLot.expiry}` : "", t.totalReceived ? `${t.totalReceived} ${lineEditorDraft.uom}` : "Chưa hoàn tất"].filter(Boolean).join(" · ");
  }
}
function saveEditorLine() {
  syncEditorDraftFromDom();
  if (!lineEditorValid()) return showToast("Kiểm tra thông tin còn thiếu trước khi hoàn tất.", "warning");
  persistLineEditorDraft(true); lineEditorDirty = false; showToast("Đã cập nhật hàng thực nhận");
  if (viewport === "web") return bj02WebAfterLine();
  navigate("SCR-009");
}
// Web: sau khi lưu / đánh dấu chưa nhận một dòng, ở lại SCR-009 và chọn dòng chưa xử lý kế tiếp (hết thì giữ dòng vừa lưu).
function bj02WebAfterLine() {
  const index = bj02Lines.findIndex((line) => line.id === activeReceiptLineId);
  const next = bj02Lines.slice(index + 1).find((line) => !lineHandled(line)) || bj02Lines.find((line) => !lineHandled(line));
  bj02WebLineId = next ? next.id : activeReceiptLineId;
  if (bj02WebLineId) bj02LoadLineEditor(bj02WebLineId);
  navigate("SCR-009");
}

/* ---------- SCR-008 → nhà cung cấp ---------- */

function filterDocumentCards(query) {
  documentSearchQuery = query;
  const normalized = ioNormalizeSearch(query);
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

/* ---------- SCR-010 Rà soát nhận hàng ---------- */

// "Cần chú ý": vượt chứng từ, hàng không đạt, chưa nhận, nhập nhanh.
function bj02AttentionRows() {
  // v5.28.0: không còn vượt chứng từ / hàng không đạt / nhập nhanh; chỉ còn dòng chưa có giá.
  return bj02Lines.filter((line) => line.status === "COMPLETED" && !(Number(line.unitPrice) > 0)).map((line) => ["Chưa có giá mua", line.name]);
}
// Khung web, SCR-010: bảng "Hàng thực nhận" bên trái, khối tóm tắt + nút xác nhận bên phải (như SCR-015 của BJ-03).
function bj02ReviewRows() {
  return bj02Lines.map((line) => {
    const handled = lineHandled(line), quick = flowMode === "quick" || line.remainingReceivableQty == null;
    const received = line.status === "NOT_RECEIVED" ? 0 : lineTotals(line).physicalIncrease;
    return {
      line, product: `<strong>${esc(line.name)}</strong><small>${esc(line.sku || "")}</small>`,
      received: handled ? `${received} ${line.uom}` : "—", price: line.unitPrice ? cfMoney(line.unitPrice) : "—", value: handled ? cfMoney(bj02LineValue(line)) : "—",
      lots: bj02LotCell(line), status: bj02IssueBadge(line) || '<span class="k7-muted">—</span>',
    };
  });
}
function bj02ReviewSummary(label, disabled) {
  const quick = flowMode === "quick";
  const facts = [["Nhà cung cấp", currentReceiptSupplier()], ["Số chứng từ", bj02Header.supplierDocNo || "—"], ["Kho nhận", BJ02_CONTEXT.warehouse.name], ["Ngày nhận", bj02ReceiptDate()], ["Mặt hàng", `${bj02ReviewProductCount()} mặt hàng`], ["Giá trị nhập", cfMoney(bj02ReceiptValue()), true]];
  return `${ac310InfoSurface("Tóm tắt", facts)}<button class="button button--primary bj02-cta" type="button" data-action="submit" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.primary" data-ds-prop-size="VButtonSize.medium"${disabled ? " disabled" : ""}>${esc(label)}</button>`;
}
function render010BJ02(state) {
  ensureBj02ReviewFixture();
  const title = "Rà soát nhận hàng";
  const wide = "k7-wide";
  if (state === "PERMISSION_DENIED") return appShell({ title, body: bj02Denied("rà soát nhận hàng"), centered: true, extraClass: wide });
  if (state === "PENDING_APPROVAL") {
    const quick = flowMode === "quick";
    const facts = [[quick ? "Nhập nhanh" : "Chứng từ", quick ? currentReceiptSupplier() : `${selectedDocumentId} · ${currentReceiptSupplier()}`], ["Mặt hàng", `${bj02ReviewProductCount()} mặt hàng`]];
    return appShell({ title, body: `<div class="k3-column">${k2Pending({ approver: "chủ cửa hàng", sentAt: BJ02_CONTEXT.submitted.submittedAt, facts })}</div>`, actions: k4Footer([{ label: "Về Kho", attr: bj02Exit(), primary: true }]), back: false, extraClass: wide });
  }
  if (state === "REJECTED") {
    const reason = approvalRejectReason || "Cần kiểm tra lại số liệu trước khi gửi lại.";
    return appShell({ title, body: `<div class="k3-column">${vBanner("error", "Yêu cầu bị từ chối", `${esc(bj02RejectedBy)} · ${esc(BJ02_CONTEXT.submitted.rejectedAt)}`)}${ac310InfoSurface("Yêu cầu", [["Lý do", reason]])}</div>`, actions: k4Footer([{ label: "Nhận lại", attr: 'data-bj02-action="redo"', primary: true }]), back: false, extraClass: wide });
  }
  const requiresApproval = bj02RequiresApproval(), noLines = bj02Lines.length === 0, incomplete = !noLines && !allReceiptLinesHandled();
  const quickZero = flowMode === "quick" && bj02AcceptedPhysicalTotal() === 0;
  const disabled = noLines || incomplete || quickZero || bj02AttentionRows().length > 0;
  const notice = state === "VALIDATION_ERROR" ? stateBanner(state) : "";
  const zeroNotice = quickZero ? vBanner("error", "Chưa có hàng vào tồn", "Phiếu nhận cần ít nhất một mặt hàng có số lượng lớn hơn 0.") : "";
  const readiness = noLines
    ? `<div class="empty-state bj02-review-empty" data-ds-component="VEmptyState"><div class="icon-box">${icon("package", "icon--empty-media")}</div><h3>Chưa có hàng để rà soát</h3><p>Thêm và hoàn tất hàng thực nhận trước khi tiếp tục.</p></div>`
    : incomplete ? vBanner("warning", "Còn mặt hàng chưa hoàn tất", "Quay lại Hàng thực nhận để hoàn tất từng mặt hàng.") : "";
  const label = "Ghi nhận";
  const web = viewport === "web";
  let content;
  if (noLines) content = readiness;
  else {
    const attention = incomplete ? "" : k2Attention(bj02AttentionRows());
    const edit = { label: "Sửa", attr: 'data-next="SCR-008"' };
    const heading = ac310SectionTitle("Hàng thực nhận", `${bj02ReviewProductCount()} mặt hàng · ${bj02Lines.length} dòng`);
    const lines = web
      ? k7Table({ columns: [{ key: "product", label: "Mặt hàng", html: true }, { key: "lots", label: "Lô", html: true }, { key: "received", label: "Số lượng", align: "end", mono: true }, { key: "price", label: "Giá mua", align: "end", mono: true }, { key: "value", label: "Thành tiền", align: "end", mono: true }, { key: "status", label: "Tình trạng", html: true }], rows: bj02ReviewRows(), caption: "Hàng thực nhận", mobileRow: (r) => bj02LineRow(r.line, `data-bj02-review-line="${r.line.id}"`), rowAttr: (r) => `data-bj02-review-line="${r.line.id}"`, rowOpen: true })
      : `<section class="ds24-list-stack receipt-line-list bj02-review-lines" data-composed-from="DS v2 / List Row">${bj02Lines.map((line) => bj02LineRow(line, `data-bj02-review-line="${line.id}"`)).join("")}</section>`;
    const total = web ? "" : ac310InfoSurface("Tổng phiếu", [["Mặt hàng", `${bj02ReviewProductCount()} mặt hàng`], ["Giá trị nhập", cfMoney(bj02ReceiptValue()), true]]);
    content = `${readiness}${attention}${heading}${lines}${total}${ac310SectionTitle("Thông tin phiếu")}${bj02ContextRow(edit)}`;
  }
  const overlays = `${bj02ReviewDetailSheet()}${bj02ConfirmSheet()}`;
  if (web && !noLines) return appShell({ title, body: `<div class="bj02-review">${notice}${zeroNotice}${k7Split({ main: content, aside: bj02ReviewSummary(label, disabled), wideMain: true, asideWebOnly: true })}</div>${overlays}`, extraClass: wide });
  const footer = primaryFooter(label, 'data-action="submit"', disabled);
  return appShell({ title, body: `${notice}${zeroNotice}${content}${overlays}`, actions: footer, extraClass: wide });
}

/* ---------- SCR-011 Phê duyệt yêu cầu nhận hàng ---------- */

function bj02LotCell(line) {
  if (line.trackingPolicy !== "LOT") return '<span class="k7-muted">—</span>';
  const lots = (line.lots || []).filter((lot) => lotDraftTotals(lot).totalReceived > 0);
  return lots.length ? lots.map((lot) => `<div>${esc(lot.code || "—")}${lot.expiry ? `<small>${esc(lot.expiry)}</small>` : ""}</div>`).join("") : '<span class="k7-muted">—</span>';
}
function bj02ApprovalRows() {
  return bj02Lines.map((line) => {
    const received = lineTotals(line).physicalIncrease, quick = flowMode === "quick" || line.remainingReceivableQty == null;
    const diff = quick ? null : received - bj02SourceRemaining(line);
    const issue = bj02ReviewIssue(line);
    return {
      product: `<strong>${esc(line.name)}</strong><small>${esc(line.sku || "")}</small>`, lots: bj02LotCell(line),
      expected: quick ? "—" : `${bj02SourceRemaining(line)} ${line.uom}`, received: `${received} ${line.uom}`,
      diff: diff == null ? "—" : `${diff > 0 ? "+" : diff < 0 ? "−" : ""}${Math.abs(diff)} ${line.uom}`, over: diff > 0,
      status: issue ? ds24Badge(issue.label, { warning: "Warning", error: "Danger", info: "Info" }[issue.tone] || "Neutral") : ds24Badge("Đã xong", "Success"), line,
    };
  });
}
/* ---------- SCR-011 · Phiếu nhận đã ghi (RECORDED, chỉ đọc) ----------
 * Cùng bảng "Theo chứng từ · Thực nhận · Chênh lệch" của màn duyệt, không chân duyệt. Mở từ thẻ kho BJ-15 (056 "Mở phiếu gốc") và từ sheet nguồn của BJ-01;
 * dòng lấy từ sổ kho (BJ15_MOVES) theo mã phiếu nhận / chứng từ, "Theo chứng từ" lấy từ lần nhận vừa ghi nếu có (không có thì bằng thực nhận). */
let bj02Recorded = { ref: "PN-260816-04", back: null }; // back: { flow, screen } nơi đã mở màn này
function bj02OpenRecorded(ref, back) { bj02Recorded = { ref, back }; return crSwitchFlow("UIF-02", "SCR-011", "RECORDED"); }
function bj02RecordedRows(ref) {
  const moves = BJ15_MOVES.filter((m) => m.doc === ref && m.sourceFlow === "UIF-02" && m.delta > 0);
  const justNow = typeof bj02LastCommitted !== "undefined" && bj02LastCommitted && BJ02_CONTEXT.submitted.receiptRef === ref ? bj02LastCommitted.lines : [];
  const groups = new Map();
  moves.forEach((m) => {
    const k = `${m.productId}|${m.lot}`, g = groups.get(k) || { productId: m.productId, lot: m.lot, received: 0, states: new Set(), recorded: m.recorded };
    g.received += m.delta; g.states.add(m.state); groups.set(k, g);
  });
  return [...groups.values()].map((g) => {
    const p = bj01ProductById(g.productId);
    const lines = justNow.filter((l) => l.productRef === g.productId && l.remainingReceivableQty != null);
    const expected = lines.length ? lines.reduce((a, l) => a + bj02SourceRemaining(l), 0) : g.received;
    const diff = g.received - expected;
    return { p, lot: g.lot, expected, received: g.received, diff, states: [...g.states], recorded: g.recorded };
  });
}
function render011Recorded() {
  const ref = bj02Recorded.ref, rows = bj02RecordedRows(ref), title = `Phiếu nhận ${ref}`;
  const supplier = documentReceiptCatalog[ref]?.supplier || (BJ02_CONTEXT.submitted.receiptRef === ref ? currentReceiptSupplier() : "");
  const date = rows[0]?.recorded.split(" · ")[0] || "";
  const subtitle = `${supplier ? `${supplier} · ` : ""}Đã ghi ${date}`;
  const fmt = (r, n) => `${n} ${r.p.stockUom}`, signed = (r) => (r.diff ? `${r.diff > 0 ? "+" : "−"}${Math.abs(r.diff)} ${r.p.stockUom}` : "0");
  const tone = (s) => (s === "Bán được" ? "Success" : "Warning");
  const view = rows.map((r) => ({ ...r, product: `<strong>${esc(r.p.name)}</strong><small>${esc(r.p.code)}</small>`, lots: r.p.tracking === "LOT" && r.lot ? `Lô ${esc(r.lot)}` : "Không theo lô", expectedText: fmt(r, r.expected), receivedText: fmt(r, r.received), diffText: signed(r), status: r.states.map((s) => ds24Badge(s, tone(s))).join(" ") }));
  const columns = [
    { key: "product", label: "Sản phẩm", html: true }, { key: "lots", label: "Lô", html: true },
    { key: "expectedText", label: "Theo chứng từ", align: "end", mono: true }, { key: "receivedText", label: "Thực nhận", align: "end", mono: true },
    { key: "diffText", label: "Chênh lệch", align: "end", mono: true, cls: (r) => (r.diff > 0 ? "k7-cell--warn" : "") }, { key: "status", label: "Tình trạng", html: true },
  ];
  const mobileRow = (r) => ds24ListRow({ title: r.p.name, subtitle: `${r.lots.replace(/<[^>]+>/g, "")} · Theo chứng từ ${r.expectedText}`, trailing: `<strong>${esc(r.receivedText)}</strong>`, leading: null, type: "Status" });
  const body = rows.length ? `${ac310SectionTitle("Hàng thực nhận", `${rows.length} dòng`)}${k7Table({ columns, rows: view, mobileRow, caption: "Hàng thực nhận" })}` : k1Empty({ title: "Không có dòng nhận hàng", description: "Phiếu này chưa có dòng nào trong sổ kho.", action: null });
  return appShell({ title, subtitle, body, extraClass: "k7-wide" });
}
function render011BJ02(state) {
  if (state === "RECORDED") return render011Recorded();
  ensureBj02ReviewFixture();
  const title = "Phê duyệt yêu cầu nhận hàng";
  const shell = (opts) => appShell({ title, extraClass: "k7-wide", ...opts });
  if (state === "PERMISSION_DENIED") return shell({ body: bj02Denied("duyệt nhận hàng", "Chỉ chủ cửa hàng mới duyệt được. Nhờ họ cấp quyền rồi quay lại."), centered: true, backAction: "exit-approval" });
  if (!bj02Lines.length) return shell({ body: `<div class="empty-state" data-ds-component="VEmptyState"><h3>Không có yêu cầu để duyệt</h3><p>Yêu cầu chỉ xuất hiện sau khi người lập gửi hồ sơ hợp lệ.</p></div>`, centered: true, backAction: "exit-approval" });
  const quick = flowMode === "quick", supplier = currentReceiptSupplier();
  if (state === "REJECTED_DONE") {
    return k4Result({ screenTitle: title, kind: "warning", title: "Đã từ chối nhận hàng", description: "Người lập sẽ thấy lý do và có thể nhận lại. Tồn kho không thay đổi.", facts: [["Lý do", esc(approvalRejectReason)], ["Người gửi", esc(BJ02_CONTEXT.submitted.maker)]], next: [{ label: "Về danh sách", attr: 'data-action="exit-approval"', primary: true }] });
  }
  const notice = ["SELF_APPROVAL_NOT_ALLOWED", "APPROVAL_ALREADY_DECIDED", "VALIDATION_ERROR"].includes(state) ? bj02ApprovalStateNotice(state) : "";
  if (state === "APPROVAL_ALREADY_DECIDED") return shell({ body: `${notice}${approvalRejectReason ? vBanner("error", "Đã từ chối", esc(approvalRejectReason)) : ""}`, actions: k4Footer([{ label: "Về danh sách", attr: 'data-action="exit-approval"', primary: true }]), backAction: "exit-approval" });
  const attention = [];
  bj02Lines.filter(bj02LineOver).forEach((line) => { const b = lineTotals(line).physicalIncrease, a = bj02SourceRemaining(line); attention.push([`${line.name}:`, `chứng từ ${a} · thực nhận ${b} ${line.uom} (+${b - a})`]); });
  if (quick) attention.push(["Nhập nhanh", "chưa có chứng từ mua", "info"]);
  bj02Lines.filter((line) => line.status === "COMPLETED").forEach((line) => {
    const t = lineTotals(line);
    const parts = [t.quarantine ? `${t.quarantine} cách ly` : "", t.damaged ? `${t.damaged} hỏng` : "", t.rejected ? `${t.rejected} từ chối` : ""].filter(Boolean);
    if (parts.length) attention.push(["Hàng không đạt", `${line.name} ${parts.join(" · ")}`, "info"]);
  });
  const risk = receiptRiskValue();
  const riskRow = quick ? null : ["Tổng giá trị rủi ro", BJ02_CONTEXT.capabilities.viewApprovalRiskTotal && state !== "FINANCIAL_MASKED" ? t7FmtMoney(risk) : "Không có quyền xem"];
  const facts = [["Nhà cung cấp", supplier], ["Kho nhận", BJ02_CONTEXT.warehouse.name], ["Ngày nhận", bj02ReceiptDate()]];
  if (quick) facts.push(["Quyền sở hữu", bj02OwnershipReady() ? "Đã xác nhận" : "Chưa xác nhận"]);
  if (riskRow) facts.push(riskRow);
  const evidenceAction = `<button class="button button--secondary button--full bj02-evidence-preview" data-bj02-action="open-evidence" type="button" data-ds-component="VButton">${icon("fileText", "icon--sm")} Xem chứng từ giao nhận</button>`;
  const decision = k2Decision({ question: quick ? `Duyệt nhập hàng nhanh của ${supplier}?` : `Duyệt nhận hàng ${selectedDocumentId} của ${supplier}?`, maker: BJ02_CONTEXT.submitted.maker, sentAt: BJ02_CONTEXT.submitted.submittedAt, attention, facts, detail: evidenceAction });
  const columns = [
    { key: "product", label: "Sản phẩm", html: true }, { key: "lots", label: "Lô / HSD", html: true },
    { key: "expected", label: "Theo chứng từ", align: "end", mono: true }, { key: "received", label: "Thực nhận", align: "end", mono: true },
    { key: "diff", label: "Chênh lệch", align: "end", mono: true, cls: (r) => (r.over ? "k7-cell--warn" : "") }, { key: "status", label: "Tình trạng", html: true },
  ];
  const table = k7Table({ columns, rows: bj02ApprovalRows(), mobileRow: (r) => bj02ReadOnlyLine(r.line), caption: "Hàng thực nhận" });
  const body = `${notice}<div class="bj02-approval">${k7Split({ main: decision, aside: `${ac310SectionTitle("Hàng thực nhận", `${bj02ReviewProductCount()} mặt hàng · ${bj02Lines.length} dòng`)}${table}` })}</div>${bj02ReviewDetailSheet()}${bj02EvidenceSheet()}${k2RejectSheet({ open: bj02RejectOpen, title: "Từ chối yêu cầu", reason: approvalRejectReason, reasonAttr: "data-bj02-reject-reason", confirmAttr: 'data-bj02-action="confirm-reject"', closeAttr: 'data-bj02-action="close-reject"' })}`;
  const disabled = ["SELF_APPROVAL_NOT_ALLOWED", "PROCESSING"].includes(state);
  const off = disabled ? " disabled" : "";
  const footer = ac310ApprovalFooter(`data-bj02-action="open-reject"${off}`, `data-bj02-action="approve"${off}`);
  return shell({ body, actions: footer, backAction: "exit-approval" });
}
function bj02ApprovalStateNotice(state) {
  if (state === "SELF_APPROVAL_NOT_ALLOWED") return vBanner("error", "Không được tự phê duyệt", "Người lập không thể đồng thời là người quyết định yêu cầu này.");
  if (state === "APPROVAL_ALREADY_DECIDED") return k1Locked({ title: "Yêu cầu đã có quyết định", description: "Quyết định hợp lệ đầu tiên có hiệu lực; các thao tác quyết định đã được khóa." });
  return stateBanner(state);
}

/* ---------- SCR-012 Kết quả nhận hàng ---------- */

function bj02LotCount() {
  return bj02Lines.reduce((n, line) => n + (line.trackingPolicy === "LOT" ? (line.lots || []).filter((lot) => lotDraftTotals(lot).totalReceived > 0).length : 0), 0);
}
// Quy số lượng dòng về ĐVT tồn của BJ-01 để cộng vào tồn.
function bj02ToStockUom(line, qty, stockUom) {
  const product = productById(line.productId);
  const ratio = Number(line.conversionRatioSnapshot ?? product?.uoms?.find((u) => u.id === line.uomId)?.conversionRatio ?? 1) || 1;
  const stockRatio = Number(product?.uoms?.find((u) => u.label === stockUom)?.conversionRatio) || ratio;
  return Math.round(qty * ratio / stockRatio);
}
function bj02StockLines() {
  return bj02Lines.filter((line) => line.productRef).map((line) => {
    const stockUom = typeof bj01ProductById === "function" ? bj01ProductById(line.productRef)?.stockUom : line.uom;
    const conv = (n) => bj02ToStockUom(line, n, stockUom);
    const t = lineTotals(line);
    return { productRef: line.productRef, accepted: conv(t.accepted), quarantine: conv(t.quarantine), damaged: conv(t.damaged),
      lots: line.trackingPolicy === "LOT" ? (line.lots || []).map((lot) => { const lt = lotDraftTotals(lot); return { code: lot.code, expiry: lot.expiry, expiryPrecision: lot.expiryPrecision, accepted: conv(lt.accepted), quarantine: conv(lt.quarantine), damaged: conv(lt.damaged) }; }) : [] };
  });
}
// Hệ thống ghi nhận xong: ghi mốc cho BJ-03 và cộng tồn vào BJ-01, một lần mỗi phiếu.
function bj02Commit(seq) {
  const ref = flowMode === "quick" ? BJ02_CONTEXT.submitted.receiptRef : selectedDocumentId;
  bj02LastCommitted = { ref, mode: flowMode, lines: cloneBj02(bj02Lines) };
  if (bj02AppliedRefs.has(seq)) return;
  bj02AppliedRefs.add(seq);
  // Sổ kho ghi theo phiếu nhận (REC-…); chứng từ nguồn (PN-…) ở ghi chú — chứng từ cũ có thể đã nhận một lần trước đó.
  if (typeof bj01ApplyReceipt === "function") bj01ApplyReceipt(bj02StockLines(), BJ02_CONTEXT.submitted.receiptRef, flowMode === "quick" ? "Nhập nhanh" : `Chứng từ ${ref}`, bj02Header.businessDate || BJ02_CONTEXT.tenantBusinessDate);
}
function render012BJ02(state) {
  ensureBj02ReviewFixture();
  const title = "Kết quả nhận hàng";
  if (state === "PERMISSION_DENIED") return appShell({ title, body: bj02Denied("xem kết quả nhận hàng"), centered: true });
  if (state === "PROCESSING") return appShell({ title, body: `<div class="loading-state" data-ds-component="VLoading"><span class="v-loading-spinner"></span><strong>Đang ghi nhận hàng</strong><p>Hệ thống đang xử lý. Bạn không cần thực hiện lại.</p></div>` });
  if (state === "REJECTED_EXECUTION") return k4Result({ screenTitle: title, kind: "warning", title: "Chưa ghi nhận hàng", description: "Yêu cầu bị chặn trước khi tồn kho thay đổi.", facts: [["Tác động tồn kho", "Không có"]], next: [{ label: "Quay lại rà soát", attr: 'data-next="SCR-010"', primary: true }] });
  const mode = bj02LastCommitted?.mode ?? flowMode, owner = bj02IsApprover();
  const physical = bj02AcceptedPhysicalTotal(), zeroImpact = physical === 0;
  const stocked = bj02Lines.filter((line) => bj02AcceptedPhysical(line) > 0).length, lots = bj02LotCount();
  const facts = [["Phiếu nhận", BJ02_CONTEXT.submitted.receiptRef], ["Nhà cung cấp", esc(currentReceiptSupplier())], ["Số chứng từ", esc(bj02Header.supplierDocNo || "—")], ["Người nhận", esc(BJ02_CONTEXT.submitted.maker)]];
  if (!zeroImpact) facts.push(["Vào tồn", `${stocked} mặt hàng${lots ? ` · ${lots} lô` : ""}`]);
  if (owner && !zeroImpact) facts.push(["Giá trị nhập", cfMoney(bj02ReceiptValue())]);
  const next = [{ label: "Xem tồn kho", attr: 'data-bj02-action="see-inventory"' }, { label: "Nhận tiếp", attr: 'data-bj02-action="receive-more"', primary: true }];
  const detail = `<button class="inline-edit bj02-lines-link" type="button" data-bj02-action="open-lines" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.link">Xem ${bj02Lines.length} dòng hàng</button>`;
  return k4Result({ screenTitle: title, title: zeroImpact ? "Đã ghi nhận phiếu nhận" : "Đã ghi nhận hàng", description: zeroImpact ? "Không có hàng vào tồn trong phiếu này." : `Đã tăng tồn theo ${bj02Lines.length} dòng hàng; giá vốn bình quân được tính lại theo giá mua.`, facts, next, button: detail + bj02LinesSheet() });
}

/* ---------- SCR-013 Đối soát nhận hàng (phục hồi ngắn) ---------- */

function render013BJ02(state) {
  const title = "Đối soát nhận hàng";
  if (state === "LOADING") return appShell({ title, subtitle: "Tự mở khi kết quả lần nhận chưa xác định", body: k1Loading({ blocks: ["heading", "card", "row", "row"] }) });
  if (state === "PERMISSION_DENIED") return appShell({ title, subtitle: "Tự mở khi kết quả lần nhận chưa xác định", body: bj02Denied("xem đối soát nhận hàng"), centered: true });
  if (state === "EMPTY") return appShell({ title, subtitle: "Tự mở khi kết quả lần nhận chưa xác định", body: `<div class="empty-state" data-ds-component="VEmptyState"><h3>Chưa có kết quả mới</h3><p>Hệ thống vẫn đang theo dõi lần nhận này. Bạn không cần tạo lại thao tác.</p></div>`, centered: true });
  const ev = BJ02_CONTEXT.recoveryEvidence;
  const item = (tone, ico, head, desc, meta) => `<div class="timeline-item ${tone === "warning" ? "is-warning" : ""}" data-ds-component="DS v2 / Timeline Item" data-figma-node="525:587"><span class="timeline-marker" data-ds-component="VIconBox" data-ds-prop-tone="VComponentTone.${tone}">${icon(ico, "icon--sm")}</span><div class="timeline-content"><strong>${head}</strong><span>${desc}</span><small>${meta}</small></div></div>`;
  if (state === "TERMINAL") {
    const timeline = item("neutral", "fileText", "Hồ sơ nhận đã được khóa", BJ02_CONTEXT.submitted.receiptRef, `${ev.submitted.at} · ${ev.submitted.actor}`) + item("success", "check", "Kết quả ghi nhận đã được xác lập", "Kết quả của lần nhận hiện tại", ev.operationResult.at) + item("success", "package", "Biến động tồn kho đã được ghi", `${bj02Lines.length} dòng hàng · mốc sổ ${ev.inventoryMovement.ledgerSequence}`, ev.inventoryMovement.at);
    return appShell({ title, subtitle: "Tự mở khi kết quả lần nhận chưa xác định", body: `${vBanner("success", "Đã xác lập kết quả", "Kết quả cuối cùng đã có; hệ thống sẽ đưa bạn về màn kết quả.")}<div class="as-of"><span>Lần kiểm tra gần nhất</span><strong class="mono">${ev.checkedAt}</strong></div><section class="timeline-card" data-ds-component="VSection"><div class="timeline">${timeline}</div></section>` });
  }
  let timeline = item("neutral", "fileText", "Hồ sơ nhận đã được khóa", BJ02_CONTEXT.submitted.receiptRef, `${ev.submitted.at} · ${ev.submitted.actor}`);
  if ((flowMode === "quick" || bj02RequiresApproval()) && ev.approval.proven) timeline += item("success", "shield", "Yêu cầu đã được duyệt", `Người duyệt: ${ev.approval.actor}`, ev.approval.at);
  timeline += item("warning", "clock", "Đang xác lập kết quả cuối cùng", "Kết quả của lần nhận hiện tại", "Đang tiếp tục kiểm tra");
  timeline += item("warning", "clock", "Đang kiểm tra biến động tồn kho", "Chưa có bằng chứng xác nhận biến động tồn kho đã được ghi", "Không cần tạo lần nhận mới");
  const detail = `${state === "STALE" ? stateBanner("STALE") : ""}<div class="as-of"><span>Lần kiểm tra gần nhất</span><strong class="mono">${ev.checkedAt}</strong></div><section class="timeline-card" data-ds-component="VSection"><div class="timeline">${timeline}</div></section><button class="button button--secondary manual-refresh" data-action="refresh" type="button">${icon("rotate", "icon--sm")} Làm mới</button>`;
  const ref = flowMode === "quick" ? "Nhập nhanh" : selectedDocumentId;
  return k3Unknown({ title, operation: "Nhận hàng", scope: `${ref} · ${bj02Lines.length} dòng`, ref: BJ02_CONTEXT.submitted.receiptRef, sentAt: BJ02_CONTEXT.submitted.submittedAt, sourceFlow: "UIF-02", exitAttr: bj02Exit(), detail });
}

/* ---------- Đăng ký màn, lối vào cũ ---------- */

// SCR-006 (chọn cách nhận) đã gộp vào SCR-007: link cũ mở 007 ở trạng thái mặc định.
screenAliases["UIF-02"] = Object.assign(screenAliases["UIF-02"] || {}, { "SCR-006": "SCR-007" });
{ const a = screenAliases[activeFlowId]?.[activeScreenId]; if (Array.isArray(a)) { activeFlowId = a[0]; activeScreenId = a[1]; } else if (a) activeScreenId = a; }

Object.assign(renderers, {
  "SCR-007": render007BJ02,
  "SCR-008": render008BJ02,
  "SCR-009": render009BJ02,
  "SCR-084": render084BJ02,
  "SCR-010": render010BJ02,
  "SCR-011": render011BJ02,
  "SCR-012": render012BJ02,
  "SCR-013": render013BJ02,
});

if (window.__VET45_PROTOTYPE__) {
  window.__VET45_PROTOTYPE__.scenarios = [...new Set([...(window.__VET45_PROTOTYPE__.scenarios || []), 'bj02-quick-receipt-no-draft', 'bj02-quick-approval-no-price-basis', 'bj02-design-state-cleanup'])];
  window.__VET45_PROTOTYPE__.bj02QuickReceipt = { draftPersistence: false, firstPersistedState: 'PENDING_APPROVAL', receiptIdCreatedOnSuccessfulSubmit: true, priceFxRequiredAtBj02Submit: false, designStateRegistryClean: true };
}

/* ---------- Xử lý sự kiện ---------- */

// Ghi nhận do hệ thống: PROCESSING rồi kết quả (một lần mỗi phiếu: ghi mốc cho BJ-03, cộng tồn vào BJ-01).
let executionTimer = null;
function startAutoExecution() {
  window.clearTimeout(executionTimer);
  const seq = ++bj02CommitSeq;
  stateByScreen["SCR-012"] = "PROCESSING";
  navigate("SCR-012");
  executionTimer = window.setTimeout(() => {
    if (activeFlowId !== "UIF-02" || activeScreenId !== "SCR-012" || stateByScreen["SCR-012"] !== "PROCESSING") return;
    bj02Commit(seq);
    if (typeof ThemeApp !== "undefined" && typeof ThemeApp.setActivated === "function") ThemeApp.setActivated(true); // phiếu nhận đầu tiên = kho bắt đầu có hàng
    stateByScreen["SCR-012"] = "COMPLETED";
    syncReviewUrl();
    render();
  }, 1400);
}
// Đóng sheet / hộp thoại đang mở; trả true nếu có gì để đóng.
function bj02CloseOverlays() {
  const open = supplierMenuOpen || bj02ScanOpen || bj02RejectOpen || bj02LinesSheetOpen || bj02Confirm || bj02ReviewOpenLineId || BJ02_CONTEXT.evidenceSheetOpen;
  supplierMenuOpen = false; supplierSearchQuery = ""; bj02ScanOpen = false; bj02RejectOpen = false; bj02LinesSheetOpen = false;
  bj02Confirm = null; bj02ReviewOpenLineId = null; BJ02_CONTEXT.evidenceSheetOpen = false;
  return Boolean(open);
}
function bj02StartNew(mode) {
  bj02PendingSubmitted = false;
  if (mode !== flowMode) flowMode = mode;
  resetBj02Receipt(mode); bj02ResetFlowStates();
}

// Web: rời SCR-009 sang Rà soát thì giữ phần đang sửa dở của dòng đang chọn (màn còn trên DOM lúc móc chạy).
onScreenEnter["UIF-02:SCR-010"] = () => { bj02CloseOverlays(); if (viewport === "web" && activeScreenId === "SCR-009" && lineEditorDirty && lineEditorDraft && !lineEditorIsReadOnly()) persistLineEditorDraft(false); };

// Đổi khung giữa chừng: SCR-084 trên web là SCR-009; về iPhone thì giữ nháp dòng đang sửa (DOM còn của khung cũ).
onViewportChange.push((vp) => {
  if (activeFlowId !== "UIF-02") return;
  if (vp === "web" && activeScreenId === "SCR-084") {
    if (activeReceiptLineId) bj02WebLineId = activeReceiptLineId;
    activeScreenId = "SCR-009"; syncReviewUrl();
  } else if (vp === "mobile" && activeScreenId === "SCR-009" && lineEditorDirty && lineEditorDraft && !lineEditorIsReadOnly()) {
    bj02EditorForce = true;
    try { persistLineEditorDraft(false); } finally { bj02EditorForce = false; }
    lineEditorDirty = false;
  }
});

// Vào màn nào cũng đóng sheet / hộp thoại còn mở của màn trước.
["SCR-007", "SCR-008", "SCR-009", "SCR-084", "SCR-011", "SCR-012", "SCR-013"].forEach((id) => { onScreenEnter[`UIF-02:${id}`] = () => { bj02CloseOverlays(); }; });

onPrevious["UIF-02"] = () => {
  if (activeScreenId === "SCR-011" && stateByScreen["SCR-011"] === "RECORDED") { const b = bj02Recorded.back; return b ? crSwitchFlow(b.flow, b.screen, "READY") : navigate("SCR-007"); }
  if (activeScreenId === "SCR-008") return navigate("SCR-007");
  // Web: SCR-084 chỉ là SCR-009 với một dòng được chọn; rời màn thì giữ nháp dòng đang sửa như nút quay lại của 084.
  if (viewport === "web" && ["SCR-009", "SCR-084"].includes(activeScreenId)) {
    if (lineEditorDraft && !lineEditorIsReadOnly()) persistLineEditorDraft(false);
    lineEditorReadOnly = false; lineEditorDirty = false;
    return navigate(flowMode === "quick" ? "SCR-008" : "SCR-007");
  }
  if (activeScreenId === "SCR-009") return navigate(flowMode === "quick" ? "SCR-008" : "SCR-007");
  if (activeScreenId === "SCR-084") {
    if (!lineEditorIsReadOnly()) persistLineEditorDraft(false);
    lineEditorReadOnly = false;
    lineEditorDirty = false;
    return navigate("SCR-009");
  }
  if (activeScreenId === "SCR-010") return navigate("SCR-009");
};

onDialogClose["UIF-02"] = () => {
  if (!bj02CloseOverlays()) return false;
  renderAppScreen(); return true;
};

document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-02") return;
  // Phần tử nền (backdrop) chỉ nhận chạm vào chính nó, không nhận chạm vào nội dung sheet bên trong.
  const hit = (selector) => {
    const el = event.target.closest(selector);
    if (!el) return null;
    if (el.matches(".sheet-backdrop,.confirm-backdrop,.bj02-select-backdrop") && event.target !== el) return null;
    return el;
  };
  const documentCard = hit("[data-bj02-document-id]");
  if (documentCard && !documentCard.disabled) {
    event.preventDefault(); selectedDocumentId = documentCard.dataset.bj02DocumentId; bj02StartNew("document"); return navigate("SCR-009");
  }
  const flowButton = hit("[data-flow]");
  if (flowButton) {
    event.preventDefault(); event.stopPropagation();
    if (flowButton.disabled) return;
    bj02StartNew(flowButton.dataset.flow === "quick" ? "quick" : "document");
    syncReviewUrl();
    return navigate(flowMode === "quick" ? "SCR-008" : "SCR-007");
  }
  if (event.target.matches("[data-bj02-supplier-backdrop]")) { event.preventDefault(); supplierMenuOpen = false; supplierSearchQuery = ""; return renderAppScreen(); }
  if (hit("[data-bj02-open-supplier-sheet]")) { event.preventDefault(); supplierMenuOpen = true; supplierSearchQuery = ""; return renderAppScreen(); }
  const quickContinue = hit("[data-bj02-quick-continue]");
  if (quickContinue) {
    event.preventDefault();
    if (quickContinue.disabled || bj02QuickBlockedReason() || !BJ02_CONTEXT.capabilities.assertOwnership) return;
    return navigate("SCR-009");
  }
  if (hit("[data-bj02-evidence-camera]")) {
    event.preventDefault();
    bj02Header.evidenceRefs = [...bj02EvidenceRefs(), { id: `EV-CAM-${++bj02CameraShots}`, name: `Anh-phieu-giao-${bj02CameraShots}.jpg`, type: "DELIVERY_DOCUMENT" }];
    bj02Header.evidence = bj02Header.evidenceRefs[0].name; bj02RefreshOwnership();
    return renderAppScreen();
  }
  const evidenceRemove = hit("[data-bj02-evidence-remove]");
  if (evidenceRemove) {
    event.preventDefault();
    bj02Header.evidenceRefs = bj02EvidenceRefs().filter((x) => x.id !== evidenceRemove.dataset.bj02EvidenceRemove);
    bj02Header.evidence = bj02Header.evidenceRefs[0]?.name || ""; bj02RefreshOwnership();
    return renderAppScreen();
  }
  const ownership = hit("[data-bj02-ownership]");
  if (ownership) {
    event.preventDefault();
    if (ownership.disabled) return;
    if (bj02OwnershipReady()) bj02Header.ownershipAssertion = null; else bj02MakeOwnershipAssertion();
    return renderAppScreen();
  }
  const scanSample = hit("[data-bj02-scan-sample]");
  if (scanSample) { event.preventDefault(); bj02ScanOpen = false; return bj02ScanProduct(scanSample.dataset.bj02ScanSample); }
  const lineCard = hit("[data-bj02-line-id]");
  if (lineCard && !event.target.closest("[data-bj02-action]")) { event.preventDefault(); return beginLineEditor(lineCard.dataset.bj02LineId); }
  const supplierOption = hit("[data-bj02-supplier-option]");
  if (supplierOption) { event.preventDefault(); return selectSupplier(supplierOption.dataset.bj02SupplierOption); }
  const overviewProductOption = hit("[data-bj02-overview-product-option]");
  if (overviewProductOption) { event.preventDefault(); return selectQuickOverviewProduct(overviewProductOption.dataset.bj02OverviewProductOption); }
  const overviewUomChoice = hit("[data-bj02-overview-uom-choice]");
  if (overviewUomChoice) { event.preventDefault(); return chooseQuickOverviewUom(overviewUomChoice.dataset.bj02OverviewUomChoice); }
  const productOption = hit("[data-bj02-product-option]");
  if (productOption) { event.preventDefault(); if (lineEditorIsReadOnly()) return; return selectLineProduct(productOption.dataset.bj02ProductOption); }
  const reviewLine = hit("[data-bj02-review-line]");
  if (reviewLine) { event.preventDefault(); bj02ReviewOpenLineId = reviewLine.dataset.bj02ReviewLine; return renderAppScreen(); }
  if (hit("[data-bj02-review-close]")) { event.preventDefault(); bj02ReviewOpenLineId = null; return renderAppScreen(); }
  const actionButton = hit("[data-bj02-action]");
  if (actionButton) {
    event.preventDefault(); event.stopPropagation();
    if (actionButton.disabled) return;
    const action = actionButton.dataset.bj02Action;
    const lotId = actionButton.dataset.bj02LotId;
    switch (action) {
      case "reload": stateByScreen[activeScreenId] = "READY"; syncReviewUrl(); return renderAppScreen();
      case "scan-open": bj02ScanOpen = true; return renderAppScreen();
      case "scan-close": bj02ScanOpen = false; return renderAppScreen();
      case "change-overview-product": quickOverviewPendingProductId = null; quickOverviewProductQuery = ""; quickOverviewProductMenuOpen = false; return renderAppScreen();
      case "change-new-line-product": lineEditorDirty = true; lineEditorDraft.productId = null; lineEditorDraft.uomId = null; lineEditorDraft.uom = null; lineEditorDraft.lots = []; lineProductMenuOpen = true; return renderAppScreen();
      case "fill-remaining": return bj02FillRemaining();
      case "show-manufacture-date": syncEditorDraftFromDom(); lotManufactureExpanded = true; return renderAppScreen();
      case "add-editor-lot": return addEditorLot();
      case "toggle-lot": syncEditorDraftFromDom(); activeLotDraftId = activeLotDraftId === lotId ? null : lotId; lotManufactureExpanded = Boolean(lineEditorDraft.lots.find((lot) => lot.id === activeLotDraftId)?.manufactureDate); return renderAppScreen();
      case "open-existing-lot": syncEditorDraftFromDom(); activeLotDraftId = lotId; lotManufactureExpanded = Boolean(lineEditorDraft.lots.find((lot) => lot.id === activeLotDraftId)?.manufactureDate); return renderAppScreen();
      case "remove-editor-lot": {
        syncEditorDraftFromDom();
        const lot = lineEditorDraft?.lots?.find((item) => item.id === lotId);
        if (!lot || lineEditorDraft.lots.length <= 1) return;
        if (!lotHasData(lot)) return removeEditorLotNow(lotId);
        bj02Confirm = { kind: "remove-lot", id: lotId }; return renderAppScreen();
      }
      case "remove-quick-line": {
        syncEditorDraftFromDom();
        const line = bj02Lines.find((item) => item.id === actionButton.dataset.bj02LineId);
        if (!line || flowMode !== "quick") return;
        if (!lineHasData(line)) return removeQuickLineNow(line.id);
        bj02Confirm = { kind: "remove-line", id: line.id }; return renderAppScreen();
      }
      case "not-received": {
        if (!lineEditorDraft || flowMode !== "document") return;
        syncEditorDraftFromDom();
        if (!lineHasData(lineEditorDraft)) return markLineNotReceived();
        bj02Confirm = { kind: "not-received" }; return renderAppScreen();
      }
      case "change-source": bj02Confirm = { kind: "change-source" }; return renderAppScreen();
      case "confirm-close": bj02Confirm = null; return renderAppScreen();
      case "confirm-ok": {
        const confirm = bj02Confirm; bj02Confirm = null;
        if (confirm?.kind === "remove-lot") return removeEditorLotNow(confirm.id);
        if (confirm?.kind === "remove-line") return removeQuickLineNow(confirm.id);
        if (confirm?.kind === "not-received") return markLineNotReceived();
        if (confirm?.kind === "change-source") { bj02StartNew("document"); return navigate("SCR-007"); }
        return renderAppScreen();
      }
      case "save-line": return saveEditorLine();
      case "open-duplicate-line": return beginLineEditor(actionButton.dataset.bj02LineId);
      case "open-existing-overview-line": quickOverviewDuplicateLineId = null; return beginLineEditor(actionButton.dataset.bj02LineId);
      case "approve": bj02Approver = { name: "Chủ cửa hàng" }; bj02PendingSubmitted = false; if (bj02ReviewReceiptId) bj02DecidedReceipts.add(bj02ReviewReceiptId); return startAutoExecution();
      case "open-reject": bj02RejectOpen = true; approvalRejectReason = ""; return renderAppScreen();
      case "close-reject": bj02RejectOpen = false; approvalRejectReason = ""; return renderAppScreen();
      case "confirm-reject":
        if (!approvalRejectReason.trim()) return;
        bj02RejectOpen = false; bj02PendingSubmitted = false; if (bj02ReviewReceiptId) bj02DecidedReceipts.add(bj02ReviewReceiptId); stateByScreen["SCR-011"] = "REJECTED_DONE"; stateByScreen["SCR-010"] = "REJECTED"; bj02RejectedBy = "Chủ cửa hàng"; syncReviewUrl(); return renderAppScreen();
      case "open-evidence": BJ02_CONTEXT.evidenceSheetOpen = true; return renderAppScreen();
      case "close-evidence": BJ02_CONTEXT.evidenceSheetOpen = false; return renderAppScreen();
      case "preview-file": return showToast("Đã mở bản xem trước chứng từ trong chế độ prototype.", "info");
      case "redo": bj02StartNew(flowMode); return navigate("SCR-007");
      case "open-lines": bj02LinesSheetOpen = true; return renderAppScreen();
      case "close-lines": bj02LinesSheetOpen = false; return renderAppScreen();
      case "receive-more": selectedDocumentId = "PN-260816-04"; bj02StartNew("document"); return navigate("SCR-007");
      case "see-inventory": activeFlowId = "UIF-01"; activeScreenId = "SCR-001"; stateByScreen["SCR-001"] = "READY"; syncReviewUrl(); return render();
      case "go-valuation":
        return val03OpenForReceipt(bj02LastCommitted?.ref || selectedDocumentId);
    }
    return;
  }
  const actionEl = event.target.closest("[data-action]");
  if (!actionEl) return;
  const action = actionEl.dataset.action;
  if (!["exit-flow", "exit-approval", "exit-receipt-document-context", "submit", "refresh"].includes(action)) return;
  event.preventDefault(); event.stopPropagation();
  if (actionEl.disabled) return;
  if (action === "exit-flow") { bj02StartNew("quick"); return navigate("SCR-007"); }
  if (action === "exit-approval") return showToast("Quay về danh sách việc cần duyệt của người phê duyệt", "info");
  if (action === "exit-receipt-document-context") return showToast(`Quay về chứng từ ${selectedDocumentId}`, "info");
  if (action === "submit") {
    if (bj02RequiresApproval()) {
      bj02Approver = null; bj02PendingSubmitted = true;
      stateByScreen["SCR-010"] = "PENDING_APPROVAL";
      stateByScreen["SCR-011"] = "READY";
      syncReviewUrl(); render();
      return;
    }
    bj02Approver = null;
    return startAutoExecution();
  }
  if (action === "refresh") return showToast("Đã làm mới kết quả nhận hàng", "info");
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
  const error = document.querySelector("[data-bj02-supplier-error]");
  if (error) error.hidden = bj02SupplierValid();
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
    if (!files.length) return;
    bj02Header.evidenceRefs = [...bj02EvidenceRefs(), ...files.map((f, i) => ({ id: `EV-${Date.now()}-${i + 1}`, name: f.name, type: "DELIVERY_DOCUMENT" }))];
    bj02Header.evidence = bj02Header.evidenceRefs[0]?.name || "";
    bj02RefreshOwnership();
    return renderAppScreen();
  }
  if (event.target.matches("[data-bj02-line-uom-select]")) { if (lineEditorIsReadOnly() || !event.target.value) return; return chooseLineUom(event.target.value); }
});

document.addEventListener("input", (event) => {
  if (activeFlowId !== "UIF-02") return;
  const t = event.target;
  if (t.matches("[data-bj02-overview-product-search]")) {
    quickOverviewProductQuery = t.value;
    quickOverviewProductMenuOpen = true;
    const menu = document.querySelector("[data-bj02-overview-product-menu]");
    if (menu) { menu.hidden = false; menu.classList.add("is-open"); }
    t.setAttribute("aria-expanded", "true");
    filterQuickOverviewProductOptions(t.value);
    return;
  }
  if (t.matches("[data-bj02-document-search]")) { filterDocumentCards(t.value); return; }
  if (t.matches("[data-bj02-line-search]")) {
    filterLineRows(t.value);
    const exact = bj02ExactProduct(t.value);
    if (exact) { lineSearchQuery = ""; return beginLineEditor(exact.id); }
    return;
  }
  if (t.matches("[data-bj02-supplier-search]")) { filterSupplierOptions(t.value); return; }
  if (t.matches("[data-bj02-product-search]")) { filterLineProductOptions(t.value); return; }
  if (t.matches("[data-bj02-qty]")) {
    const digits = t.value.replace(/\D/g, "");
    if (digits !== t.value) t.value = digits;
    lineEditorDirty = true;
    syncEditorDraftFromDom();
    updateBj02EditorLiveFeedback();
    return;
  }
  if (t.matches("[data-bj02-unit-price]")) {
    const digits = t.value.replace(/\D/g, "");
    t.value = digits ? cfMoneyInput(digits) : "";
    lineEditorDirty = true;
    syncEditorDraftFromDom();
    updateBj02EditorLiveFeedback();
    return;
  }
  if (t.matches("[data-bj02-supplier-doc]")) { bj02Header.supplierDocNo = t.value; return; }
  if (t.matches("[data-bj02-lot-field]")) {
    lineEditorDirty = true;
    syncEditorDraftFromDom();
    updateBj02EditorLiveFeedback();
    return;
  }
  if (t.matches("[data-bj02-reject-reason]")) {
    approvalRejectReason = t.value;
    const confirm = document.querySelector('[data-bj02-action="confirm-reject"]');
    if (confirm) confirm.disabled = !approvalRejectReason.trim();
  }
});
