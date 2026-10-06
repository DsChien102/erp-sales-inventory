const HARNESS = window.VET45_HARNESS_DATA || { flows: [], screens: [], runOrder: [] };
const FIGMA_DS_MAP = window.VET45_FIGMA_DS_MAP || { componentMappings:{}, profileMappings:{}, themeComponentMappings:{}, internalMappings:{} };
// v4.6.1 review fixtures. These are runtime inputs, not business decisions.
window.__VET45_MONEY_CURRENCY_CATALOG__ = window.__VET45_MONEY_CURRENCY_CATALOG__ || [{id:"VND",label:"VND"},{id:"USD",label:"USD"}];
window.__VET45_FX_SOURCE_FIXTURE__ = window.__VET45_FX_SOURCE_FIXTURE__ || {VND:{rate:1,version:"LOCAL-VND"},USD:{rate:24450,version:"FX-DEMO-USD-202609"}};
window.__VET45_TAX_TREATMENT_POLICY__ = window.__VET45_TAX_TREATMENT_POLICY__ || {version:"TAX-HKD-DEMO-v1",recoverableRate:0};
window.__VET45_TENANT_COST_POLICY__ = window.__VET45_TENANT_COST_POLICY__ || {version:"COST-POLICY-DEMO-v1",method:"PERIODIC",label:"Bình quân cuối kỳ",periodCloseScopes:[{id:"ALL_PRODUCTS",label:"Toàn bộ sản phẩm"},{id:"DIRTY_PRODUCTS_ONLY",label:"Sản phẩm cần tính lại"}],fixture:true};
// v2.7.1 — live Figma DS correction: List Row density/affordance, grouped Info Row surfaces, VToast, and Key-value Row fidelity; BJ05 business behavior unchanged.
// Figma DS v2.0.3 is UI authority; business authority remains in BJ/UC/decision/contracts.
const FIGMA_MIGRATED_FLOWS = new Set([
  "UIF-01","UIF-02","UIF-03","UIF-04","UIF-05","UIF-06","UIF-07","UIF-08","UIF-09",
  "UIF-10","UIF-11","UIF-12","UIF-13","UIF-14","UIF-15","UIF-16","UIF-17"
]);
const FIGMA_TEMPLATE_NODES = {
  "Mobile / Root List":"551:549", "Mobile / Nested List":"551:1277", "Mobile / Detail":"551:1396",
  "Mobile / Form":"551:1452", "Mobile / Wizard":"551:1530", "Mobile / Search & Select":"551:1621", "Mobile / State":"551:1746"
};
const FIGMA_TEMPLATE_BY_FLOW_SCREEN = {
  "UIF-01":{"SCR-001":"Mobile / Root List","SCR-003":"Mobile / Detail"},
  "UIF-02":{"SCR-006":"Mobile / Nested List","SCR-007":"Mobile / Nested List","SCR-008":"Mobile / Form","SCR-009":"Mobile / Nested List","SCR-084":"Mobile / Form","SCR-010":"Mobile / Detail","SCR-011":"Mobile / Detail","SCR-012":"Mobile / Detail","SCR-013":"Mobile / Detail"},
  "UIF-03":{"SCR-014":"Mobile / Root List","SCR-015":"Mobile / Form","SCR-017":"Mobile / Detail","SCR-019":"Mobile / Detail"},
  "UIF-04":{"SCR-021":"Mobile / Detail"},
  "UIF-05":{"SCR-025":"Mobile / Root List","SCR-026":"Mobile / Detail","SCR-027":"Mobile / Form","SCR-028":"Mobile / Detail","SCR-029":"Mobile / Detail"},
  "UIF-06":{"SCR-030":"Mobile / Root List","SCR-031":"Mobile / Detail","SCR-032":"Mobile / Form","SCR-034":"Mobile / Detail","SCR-033":"Mobile / Form","SCR-035":"Mobile / Detail"},
  "UIF-07":{"SCR-036":"Mobile / Root List","SCR-037":"Mobile / Detail","SCR-039":"Mobile / Detail","SCR-041":"Mobile / Detail"},
  "UIF-08":{"SCR-042":"Mobile / Nested List","SCR-043":"Mobile / Form","SCR-044":"Mobile / Form","SCR-045":"Mobile / Form","SCR-046":"Mobile / Detail","SCR-047":"Mobile / Detail"},
  "UIF-09":{"SCR-036":"Mobile / Root List","SCR-037":"Mobile / Detail","SCR-038":"Mobile / Form","SCR-041":"Mobile / Detail","SCR-056":"Mobile / Detail"},
  "UIF-10":{"SCR-036":"Mobile / Root List","SCR-037":"Mobile / Detail","SCR-040":"Mobile / Form","SCR-041":"Mobile / Detail"},
  "UIF-11":{"SCR-048":"Mobile / Root List","SCR-049":"Mobile / Detail","SCR-052":"Mobile / Form","SCR-050":"Mobile / Form","SCR-053":"Mobile / Detail","SCR-051":"Mobile / Detail"},
  "UIF-12":{"SCR-066":"Mobile / Detail","SCR-067":"Mobile / Form","SCR-068":"Mobile / Detail","SCR-069":"Mobile / Detail","SCR-070":"Mobile / Detail","SCR-071":"Mobile / Detail"},
  "UIF-13":{"SCR-085":"Mobile / Root List","SCR-086":"Mobile / Form","SCR-087":"Mobile / Form","SCR-088":"Mobile / Detail","SCR-089":"Mobile / Detail"},
  "UIF-14":{"SCR-072":"Mobile / Root List","SCR-073":"Mobile / Form","SCR-074":"Mobile / Detail","SCR-076":"Mobile / Detail","SCR-077":"Mobile / Detail"},
  "UIF-15":{"SCR-054":"Mobile / Form","SCR-055":"Mobile / Detail","SCR-056":"Mobile / Detail","SCR-057":"Mobile / Detail","SCR-058":"Mobile / Detail","SCR-059":"Mobile / Detail"},
  "UIF-16":{"SCR-078":"Mobile / Root List","SCR-079":"Mobile / Detail","SCR-080":"Mobile / Form","SCR-081":"Mobile / Detail","SCR-082":"Mobile / Detail","SCR-083":"Mobile / Detail"},
  "UIF-17":{"SCR-078":"Mobile / Root List","SCR-079":"Mobile / Detail","SCR-080":"Mobile / Form","SCR-082":"Mobile / Detail","SCR-083":"Mobile / Detail"}
};
function figmaScreenTemplate(){ return FIGMA_TEMPLATE_BY_FLOW_SCREEN[activeFlowId]?.[activeScreenId] || null; }
const screens = HARNESS.screens;
const flowCatalog = HARNESS.flows;
let activeFlowId = new URLSearchParams(window.location.search).get("uif") || "UIF-02";
if (!flowCatalog.some((f) => f.id === activeFlowId)) activeFlowId = "UIF-02";
const groups = ["Screens"];
const FLOW_GROUPS = [
  { id: "inventory-operations", label: "Inventory operations", bjs: ["BJ-01", "BJ-02", "BJ-04", "BJ-05", "BJ-06", "BJ-07"] },
  { id: "inventory-valuation", label: "Inventory valuation", bjs: ["BJ-03", "BJ-13", "BJ-14"] },
  { id: "inventory-audit-control", label: "Inventory audit & control", bjs: ["BJ-08", "BJ-09", "BJ-10", "BJ-11", "BJ-12", "BJ-15", "BJ-16", "BJ-17"] },
];

function flowGroupLabel(flow) {
  const match = FLOW_GROUPS.find((group) => group.bjs.includes(flow.bj));
  return match ? match.label : "Other";
}

const stateByScreen = Object.fromEntries(screens.map((screen) => [screen.id, screen.defaultState]));

const initialParams = new URLSearchParams(window.location.search);
const initialFlow = flowCatalog.find((f) => f.id === activeFlowId);
const entryMode = initialParams.get("entry") || "module";
let activeScreenId = screens.some((s) => s.id === initialParams.get("screen") && initialFlow?.screens.includes(s.id)) ? initialParams.get("screen") : (initialFlow?.screens[0] || "SCR-006");
let viewport = initialParams.get("viewport") === "wide" ? "wide" : "mobile";
let flowMode = initialParams.get("flow") === "quick" ? "quick" : "document";
if (!initialParams.get("screen")) {
  if (activeFlowId === "UIF-01" && entryMode === "product-context") activeScreenId = "SCR-003";
  else if (activeFlowId === "UIF-02" && entryMode === "document-context") { flowMode = "document"; activeScreenId = "SCR-009"; }
  else if (activeFlowId === "UIF-02" && entryMode === "approver") activeScreenId = "SCR-011";
  else if (activeFlowId === "UIF-03" && entryMode === "receipt-task") activeScreenId = "SCR-015";
  else if (activeFlowId === "UIF-04" && entryMode === "order-context") activeScreenId = "SCR-021";
  else if (activeFlowId === "UIF-05" && entryMode === "order-task") activeScreenId = "SCR-026";
  else if (activeFlowId === "UIF-06" && entryMode === "return-task") activeScreenId = "SCR-031";
  else if (activeFlowId === "UIF-06" && entryMode === "approver") activeScreenId = "SCR-034";
  else if (activeFlowId === "UIF-07" && entryMode === "return-task") activeScreenId = "SCR-037";
  else if (activeFlowId === "UIF-13" && entryMode === "source-task") activeScreenId = "SCR-086";
  else if (activeFlowId === "UIF-11" && entryMode === "operation-context") activeScreenId = "SCR-049";
  else if (activeFlowId === "UIF-11" && entryMode === "approver") activeScreenId = "SCR-051";
  else if (activeFlowId === "UIF-16" && entryMode === "case-context") activeScreenId = "SCR-079";
  else if (activeFlowId === "UIF-17" && entryMode === "unknown-context") activeScreenId = "SCR-079";
  else if (activeFlowId === "UIF-12" && entryMode === "approver") activeScreenId = "SCR-070";
}
const initialState = initialParams.get("state");
if (initialState && screens.find((s) => s.id === activeScreenId)?.states.includes(initialState)) stateByScreen[activeScreenId] = initialState;
let lotSequence = 1;
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
let selectedQuickProductId = null;
let quickProductMenuOpen = false;
let receiptDraft = { lots: [] }; // retained for legacy helper compatibility outside the new BJ-02 line editor.
let toastTimer = null;
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


// ==========================================================================
// UIF-01 / BJ-01 v1.3.4 (unchanged from v0.3.4) — scoped renderer state.
// IMPORTANT: only UIF-01 may change here. BJ-02 v0.2.9 remains protected.
// ==========================================================================
const bj01Products = [
  { id:"INV-NOB", name:"Nobivac DHPPi", code:"SP-000184", barcode:"8938500001012", stockUom:"hộp", tracking:"LOT", physical:120, eligible:118, reserved:12, available:106, threshold:30, target:80, monitoringConfigStatus:"CONFIGURED", eligibilityBreakdown:[{reason:"Cách ly",quantity:2}], latestPhysicalMovement:{label:"Nhận hàng",source:"PN-260816-04",delta:118}, reservationSummary:{quantity:12,source:"SO-260817-08"}, lots:[
    { code:"DH2507", expiryDisplay:"30/11/2026", expiryPrecision:"DAY", physical:70, eligible:70, stockState:"SELLABLE", expiryIndicator:"NONE", nearExpiryAction:null },
    { code:"DH2509", expiryDisplay:"15/09/2026", expiryPrecision:"DAY", physical:50, eligible:48, stockState:"SELLABLE", expiryIndicator:"NEAR_EXPIRY", nearExpiryAction:"WARN", daysToExpiry:19 },
  ]},
  { id:"INV-AMX", name:"Amox 500", code:"SP-000066", barcode:"8938500004068", stockUom:"hộp", tracking:"NONE", physical:48, eligible:47, reserved:5, available:42, threshold:50, target:80, monitoringConfigStatus:"CONFIGURED", eligibilityBreakdown:[{reason:"Cách ly",quantity:1}], latestPhysicalMovement:{label:"Nhận hàng",source:"PN-260825-02",delta:48}, reservationSummary:{quantity:5,source:"SO-260827-18"}, lots:[] },
  { id:"INV-ENRO", name:"Enrofloxacin 10%", code:"SP-000091", barcode:"8938500005096", stockUom:"chai", tracking:"NONE", physical:0, eligible:0, reserved:0, available:0, threshold:10, target:30, monitoringConfigStatus:"CONFIGURED", eligibilityBreakdown:[], latestPhysicalMovement:{label:"Xuất bán",source:"SO-260826-11",delta:-6}, reservationSummary:{quantity:0,source:null}, lots:[] },
  { id:"INV-TYLO", name:"Tylosin 20%", code:"SP-000122", barcode:"8938500006123", stockUom:"lọ", tracking:"LOT", physical:18, eligible:7, reserved:3, available:4, threshold:8, target:24, monitoringConfigStatus:"CONFIGURED", eligibilityBreakdown:[{reason:"Hết hạn",quantity:11}], latestPhysicalMovement:{label:"Nhận hàng",source:"PN-260701-07",delta:18}, reservationSummary:{quantity:3,source:"SO-260826-09"}, lots:[
    { code:"TY2408", expiryDisplay:"31/07/2026", expiryPrecision:"DAY", physical:11, eligible:0, stockState:"EXPIRED", expiryIndicator:"EXPIRED", nearExpiryAction:null },
    { code:"TY2511", expiryDisplay:"11/2027", expiryPrecision:"MONTH", physical:7, eligible:7, stockState:"SELLABLE", expiryIndicator:"NONE", nearExpiryAction:null },
  ]},
  { id:"INV-OXY", name:"Oxytetracycline LA", code:"SP-000147", barcode:"8938500007144", stockUom:"chai", tracking:"NONE", physical:31, eligible:30, reserved:4, available:26, threshold:null, target:null, monitoringConfigStatus:"NOT_CONFIGURED", eligibilityBreakdown:[{reason:"Cách ly",quantity:1}], latestPhysicalMovement:{label:"Nhận hàng",source:"PN-260824-05",delta:31}, reservationSummary:{quantity:4,source:"SO-260827-03"}, lots:[] },
];
let bj01Filter = "ALL";
let bj01Query = "";
let bj01SelectedProductId = "INV-NOB";
let bj01SelectedLotCode = "DH2507";
let bj01LotOpen = false;
let bj01ProvenanceOpen = false;
let bj01QueryAsOf = "09:42 · 27/08/2026";
let bj01RefreshSequence = ["09:47 · 27/08/2026", "09:51 · 27/08/2026"];
let bj01RefreshIndex = 0;

// ============================================================================
// UIF-03 / BJ-03 v1.4.4 — Inventory Valuation foundation correction.
// Preview is non-mutating; final commit is owned by BC-IV-01/API-C-20.
// ============================================================================
const val03Receipts = [
  {id:"VAL03-R1",receipt:"PN-260816-04",supplier:"Minh Dũng",warehouse:"Kho chính",receivedAt:"16/08/2026",sourceVersion:3,ageDays:19,waitingOwner:"",groups:[
    {id:"VAL03-G1",name:"Nobivac DHPPi",code:"SP-00142",uom:"hộp",tracking:"LOT",officialCostStatus:"EXISTS",sources:[
      {id:"PO",label:"Đơn mua PO-2608-041",version:"v3",unitPrice:83000,currency:"VND",fxRate:1,fxLabel:"VND",unitLineDiscount:1000,unitDocDiscount:500,unitKnownCost:200,unitNonDeductibleVat:0,provenance:["Giá mua · PO-2608-041 v3","CK dòng · PO-2608-041 v3","CK phiếu · phân bổ theo giá trị dòng","Chi phí đã có · CTCP-2608-12 v1"]},
      {id:"SUP",label:"Xác nhận nhà cung cấp 02/09",version:"v1",unitPrice:83000,currency:"VND",fxRate:1,fxLabel:"VND",unitLineDiscount:1000,unitDocDiscount:500,unitKnownCost:200,unitNonDeductibleVat:0,provenance:["Giá mua · Xác nhận NCC 02/09 v1","CK dòng · theo PO v3","CK phiếu · phân bổ theo giá trị dòng","Chi phí đã có · CTCP-2608-12 v1"]}
    ],selectedSource:"PO",reason:"",slices:[
      {id:"VAL03-S1",scopeKey:"ROL-401|LOT-DH2507|SELLABLE",scopeVersion:1,lineId:"ROL-401",lot:"DH2507",physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:50,selected:false,selectedQty:50,partialOpen:false,availabilityDelta:50,availabilityNote:"Sẽ tăng khả dụng"},
      {id:"VAL03-S2",scopeKey:"ROL-402|LOT-DH2509|SELLABLE",scopeVersion:1,lineId:"ROL-402",lot:"DH2509",physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:46,selected:false,selectedQty:46,partialOpen:false,availabilityDelta:0,availabilityNote:"Chưa tăng khả dụng · còn vướng kiểm soát chất lượng"},
      {id:"VAL03-S3",scopeKey:"ROL-403|LOT-DH2509|QUARANTINE",scopeVersion:1,lineId:"ROL-403",lot:"DH2509",physicalState:"QUARANTINE",stateLabel:"Cách ly",pendingQty:4,selected:false,selectedQty:4,partialOpen:false,availabilityDelta:0,availabilityNote:"Giữ cách ly"}
    ]},
    {id:"VAL03-G2",name:"Amoxicillin LA",code:"SP-00088",uom:"chai",tracking:"NONE",officialCostStatus:"NONE",sources:[
      {id:"PO",label:"Đơn mua PO-2608-041",version:"v3",unitPrice:120000,currency:"VND",fxRate:1,fxLabel:"VND",unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:0,provenance:["Giá mua · PO-2608-041 v3"]},
      {id:"SUP",label:"Xác nhận nhà cung cấp 02/09",version:"v2",unitPrice:121000,currency:"VND",fxRate:1,fxLabel:"VND",unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:0,provenance:["Giá mua · Xác nhận NCC 02/09 v2"]}
    ],selectedSource:"",reason:"",slices:[{id:"VAL03-S4",scopeKey:"ROL-404|NOLOT|SELLABLE",scopeVersion:1,lineId:"ROL-404",lot:null,physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:24,selected:false,selectedQty:24,partialOpen:false,availabilityDelta:24,availabilityNote:"Sẽ tăng khả dụng"}]}
  ]},
  {id:"VAL03-R2",receipt:"PN-260816-02",supplier:"An Việt",warehouse:"Kho chính",receivedAt:"16/08/2026",sourceVersion:1,ageDays:19,waitingOwner:"Chờ chứng từ mua",groups:[
    {id:"VAL03-G3",name:"Găng tay khám Nitrile",code:"SP-00310",uom:"hộp",tracking:"NONE",officialCostStatus:"EXISTS",sources:[],selectedSource:"",reason:"",slices:[{id:"VAL03-S5",scopeKey:"ROL-405|NOLOT|SELLABLE",scopeVersion:1,lineId:"ROL-405",lot:null,physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:50,selected:false,selectedQty:50,partialOpen:false,availabilityDelta:50,availabilityNote:"Sẽ tăng khả dụng"}]}
  ]},
  {id:"VAL03-R3",receipt:"PN-260901-03",supplier:"Phương Nam",warehouse:"Kho chính",receivedAt:"01/09/2026",sourceVersion:2,ageDays:3,waitingOwner:"",groups:[
    {id:"VAL03-G4",name:"Vaccine Canine X",code:"SP-00421",uom:"lọ",tracking:"LOT",officialCostStatus:"NONE",sources:[
      {id:"SUP",label:"Xác nhận nhà cung cấp 01/09",version:"v2",unitPrice:4.1,currency:"USD",fxRate:24450,fxLabel:"FX authoritative",unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:0,provenance:["Giá mua · Xác nhận NCC 01/09","FX authoritative · provenance kỹ thuật"]}
    ],selectedSource:"SUP",reason:"",slices:[{id:"VAL03-S6",scopeKey:"ROL-406|LOT-CX2609|SELLABLE",scopeVersion:1,lineId:"ROL-406",lot:"CX2609",physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:10,selected:false,selectedQty:10,partialOpen:false,availabilityDelta:10,availabilityNote:"Sẽ tăng khả dụng"}]}
  ]},
  {id:"VAL03-R4",receipt:"PN-260902-07",supplier:"VietVet",warehouse:"Kho chính",receivedAt:"02/09/2026",sourceVersion:1,ageDays:2,waitingOwner:"",groups:[
    {id:"VAL03-G5",name:"Dung dịch sát khuẩn",code:"SP-00510",uom:"chai",tracking:"NONE",officialCostStatus:"EXISTS",sources:[{id:"PO",label:"Đơn mua PO-2609-008",version:"v1",unitPrice:46000,currency:"VND",fxRate:1,fxLabel:"VND",unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:0,provenance:["Giá mua · PO-2609-008 v1"]}],selectedSource:"PO",reason:"",slices:[{id:"VAL03-S7",scopeKey:"ROL-407|NOLOT|SELLABLE",scopeVersion:1,lineId:"ROL-407",lot:null,physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:12,selected:false,selectedQty:12,partialOpen:false,availabilityDelta:12,availabilityNote:"Sẽ tăng khả dụng"}]},
    {id:"VAL03-G6",name:"Bơm tiêm 5ml",code:"SP-00511",uom:"hộp",tracking:"NONE",officialCostStatus:"EXISTS",sources:[],selectedSource:"",reason:"",slices:[{id:"VAL03-S8",scopeKey:"ROL-408|NOLOT|SELLABLE",scopeVersion:1,lineId:"ROL-408",lot:null,physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:8,selected:false,selectedQty:8,partialOpen:false,availabilityDelta:8,availabilityNote:"Sẽ tăng khả dụng"}]}
  ]}
];
let val03SelectedReceiptId="VAL03-R1", val03Query="", val03Filter="ALL", val03ReviewSourceVersion=null, val03LastResult=null, val03LastSourceChange=null, val03OperationSeq=1, val03EvidenceSheetOpen=false, val03EvidenceSheetMode="scope";
function val03Current(){return val03Receipts.find(r=>r.id===val03SelectedReceiptId)||val03Receipts[0];}
function val03PendingSlices(r=val03Current()){return r.groups.flatMap(g=>g.slices.map(s=>({group:g,slice:s}))).filter(x=>x.slice.pendingQty>0);}
function val03EvidenceState(group){if(!group.sources.length)return "MISSING";const sig=new Set(group.sources.map(s=>`${s.currency}:${s.unitPrice}:${s.fxRate}`));return sig.size>1?"CONFLICT":"READY";}
function val03ActionablePairs(r=val03Current()){return val03PendingSlices(r).filter(x=>val03EvidenceState(x.group)!=="MISSING");}
function val03WaitingPairs(r=val03Current()){return val03PendingSlices(r).filter(x=>val03EvidenceState(x.group)==="MISSING");}
function val03ReceiptState(r){const a=val03ActionablePairs(r);if(!a.length)return "WAITING";return a.some(x=>val03EvidenceState(x.group)==="CONFLICT")?"CONFLICT":"READY";}
function val03SelectedSlices(r=val03Current()){return val03PendingSlices(r).filter(x=>x.slice.selected&&Number(x.slice.selectedQty)>0);}
function val03Source(group){return group.sources.find(s=>s.id===group.selectedSource)||null;}
function val03GroupSelectedQty(group){return group.slices.filter(s=>s.selected&&s.pendingQty>0).reduce((n,s)=>n+Math.min(Number(s.selectedQty)||0,s.pendingQty),0);}
function val03GroupReady(group){if(val03GroupSelectedQty(group)<=0)return true;const st=val03EvidenceState(group);if(st==="MISSING")return false;if(st==="CONFLICT"&&(!group.selectedSource||!group.reason.trim()))return false;return Boolean(val03Source(group));}
function val03HasSelectedConflict(r=val03Current()){return r.groups.some(g=>val03GroupSelectedQty(g)>0&&val03EvidenceState(g)==="CONFLICT"&&!val03GroupReady(g));}
function val03ScopeReady(r=val03Current()){const sel=val03SelectedSlices(r);return sel.length>0&&r.groups.every(val03GroupReady);}
function val03FmtMoney(n){return `${Math.round(Number(n)||0).toLocaleString("vi-VN")} đ`;}
function val03Calc(group){const src=val03Source(group);const qty=val03GroupSelectedQty(group);if(!src||qty<=0)return null;const baseVnd=src.unitPrice*src.fxRate;const unitActual=baseVnd-(src.unitLineDiscount||0)-(src.unitDocDiscount||0)+(src.unitKnownCost||0)+(src.unitNonDeductibleVat||0);return {qty,baseVnd,unitActual,value:Math.round(unitActual*qty),src};}
function val03SourceDetail(group){const src=val03Source(group);return src?src.label:"Chưa chọn";}
function val03SourcePriceText(src,uom){return src.currency==="VND"?`${val03FmtMoney(src.unitPrice)}/${uom}`:`${src.unitPrice.toLocaleString("vi-VN")} ${src.currency}/${uom}`;}
function val03ScopeLabel(g,s){return g.tracking==="LOT"?`Lô ${s.lot}`:"Không theo lô";}
function val03TotalValue(r=val03Current()){return r.groups.reduce((n,g)=>n+(val03Calc(g)?.value||0),0);}
function val03SelectedGroupCount(r=val03Current()){return r.groups.filter(g=>val03GroupSelectedQty(g)>0).length;}
function val03FilterMatch(r){const st=val03ReceiptState(r);if(val03Filter==="READY")return st!=="WAITING";if(val03Filter==="WAITING")return st==="WAITING";return true;}
function val03ReceiptBadge(r){const st=val03ReceiptState(r);return st==="WAITING"?["Chờ căn cứ","neutral"]:st==="CONFLICT"?["Cần đối chiếu","warning"]:["Có thể xử lý","success"];}
function val03ApplySourceUpdate(groupId,newPrice){const r=val03Current(),g=r.groups.find(x=>x.id===groupId);if(!g||!g.sources.length)return false;const src=g.sources[0],before=val03SourcePriceText(src,g.uom);r.sourceVersion+=1;src.unitPrice=newPrice;src.version=`v${Number(String(src.version).replace(/\D/g,"")||0)+1}`;val03LastSourceChange={name:g.name,source:src.label,from:before,to:val03SourcePriceText(src,g.uom)};if(val03EvidenceState(g)==="CONFLICT"){g.selectedSource="";g.reason="";}return true;}
function val03SelectedAvailability(g,s){const q=Math.min(Number(s.selectedQty)||0,s.pendingQty);const ratio=s.pendingQty?Math.min(1,q/s.pendingQty):0;return Math.round((s.availabilityDelta||0)*ratio*1000)/1000;}
function val03Commit(){const r=val03Current();const selected=val03SelectedSlices(r);const groups=r.groups.filter(g=>val03GroupSelectedQty(g)>0).map(g=>{const c=val03Calc(g);return {name:g.name,code:g.code,uom:g.uom,tracking:g.tracking,qty:c.qty,value:c.value,unitActual:c.unitActual,source:val03SourceDetail(g),officialCostInitialized:g.officialCostStatus==="NONE",slices:g.slices.filter(s=>s.selected&&s.pendingQty>0).map(s=>({scopeKey:s.scopeKey,lot:s.lot,state:s.stateLabel,qty:Math.min(Number(s.selectedQty)||0,s.pendingQty),availabilityDelta:val03SelectedAvailability(g,s),availabilityNote:s.availabilityNote}))};});val03LastResult={operationId:`VAL-260904-${String(val03OperationSeq++).padStart(3,"0")}`,receipt:r.receipt,supplier:r.supplier,groups,totalValue:groups.reduce((n,g)=>n+g.value,0)};for(const {group,slice} of selected){const q=Math.min(Number(slice.selectedQty)||0,slice.pendingQty);slice.pendingQty-=q;slice.scopeVersion+=1;slice.selected=false;slice.partialOpen=false;slice.selectedQty=slice.pendingQty;if(group.officialCostStatus==="NONE")group.officialCostStatus="EXISTS";}val03ReviewSourceVersion=null;return val03LastResult;}
function val03ResultSnapshot(){return val03LastResult||{receipt:val03Current().receipt,supplier:val03Current().supplier,groups:[],totalValue:0};}
function valuationDsTone(tone){const t=String(tone||"Neutral").toLowerCase();return ({success:"Success",warning:"Warning",danger:"Danger",error:"Danger",info:"Info",neutral:"Neutral",brand:"Brand"})[t]||"Neutral";}
function valuationProductHeader({name,code,uom,status="",tone="Neutral",value="",meta=""}){
  const trailing=value?`<span class="valuation-product-value"><small>Giá trị</small><strong>${esc(value)}</strong></span>`:(status?ds24Badge(status,valuationDsTone(tone)):"");
  const subtitle=`${code} · ${uom}${meta?` · ${meta}`:""}`;
  return ds24ListRow({title:name,subtitle,trailing,leading:"package",attrs:'data-layout-role="valuation-product-header" data-ds-role="valuation-product-summary"',type:"Status",density:"Compact",interactive:false});
}
function valuationReadOnlyChild({title,subtitle,trailing=""}){
  return `<div class="valuation-readonly-child" data-composed-from="VText"><span class="valuation-child-branch" aria-hidden="true"></span><span class="valuation-child-copy"><strong>${esc(title)}</strong><small>${esc(subtitle)}</small></span>${trailing?`<span class="valuation-child-trailing">${trailing}</span>`:""}</div>`;
}
function val03ScopeGroupsHtml(r){
  const content=r.groups.filter(g=>g.slices.some(s=>s.pendingQty>0)).map(g=>{
    const st=val03EvidenceState(g);const badge=st==="MISSING"?["Chờ căn cứ","Neutral"]:st==="CONFLICT"?["Cần đối chiếu","Warning"]:["Đủ căn cứ","Success"];
    const rows=g.slices.filter(s=>s.pendingQty>0).map(s=>{
      const disabled=st==="MISSING",qty=Math.min(Number(s.selectedQty)||0,s.pendingQty);
      const selectedClass=s.selected?' is-selected':'';
      const disabledClass=disabled?' is-disabled':'';
      const partial=s.selected?`<div class="val03-partial-controls"><button class="val03-partial-link" type="button" data-val03-partial="${s.id}" data-ds-component="DS v2 / Link" data-figma-node="4431:10396">${s.partialOpen?'Dùng toàn bộ':'Xác nhận một phần'}</button>${s.partialOpen?`<label class="val03-qty" data-ds-component="VTextField" data-figma-node="522:7186"><span>Số lượng lần này</span><input type="number" min="1" max="${s.pendingQty}" value="${qty}" data-val03-qty="${s.id}"/><small>Tối đa ${s.pendingQty} ${esc(g.uom)}</small></label>`:""}</div>`:"";
      return `<div class="valuation-child-item val03-scope-item${selectedClass}${disabledClass}"><button type="button" class="valuation-child-row val03-check" data-val03-slice="${s.id}" aria-pressed="${s.selected}" ${disabled?'disabled aria-disabled="true"':''} data-composed-from="VCheckbox,VText" data-ds-migration-state="COMPOSED_FROM_CANONICAL_PRIMITIVES"><span class="valuation-child-branch" aria-hidden="true"></span><span class="valuation-selection-control val03-check-mark" aria-hidden="true" data-ds-component="VCheckbox" data-ds-prop-state="${disabled?'Disabled':s.selected?'Checked':'Unchecked'}">${s.selected?icon("check","icon--xs"):""}</span><span class="valuation-child-copy"><strong>${esc(val03ScopeLabel(g,s))}</strong><small>${esc(s.stateLabel)} · Chờ giá ${s.pendingQty} ${esc(g.uom)}</small></span></button>${partial}</div>`;
    }).join("");
    return `<div class="valuation-product-group">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,status:badge[0],tone:badge[1]})}<div class="valuation-child-list">${rows}</div></div>`;
  }).join("");
  return ds24GroupedCollection(content,"valuation-product-collection val03-product-collection","DS v2 / Icon,VBadge,VCheckbox,VText,VTextField");
}
function val03CalculationGroupsHtml(r){
  return r.groups.filter(g=>val03GroupSelectedQty(g)>0).map(g=>{
    const st=val03EvidenceState(g);let sourceUI="";
    if(st==="CONFLICT"){
      sourceUI=`${vBanner("warning","Căn cứ giá đang mâu thuẫn","Hệ thống không tự chọn. Chọn căn cứ có thẩm quyền và ghi lý do.")}<div class="valuation-source-list" data-composed-from="DS v2 / List Row,VRadio">${g.sources.map(src=>`<button type="button" class="val03-source-option ${g.selectedSource===src.id?'is-selected':''}" data-val03-source="${g.id}" data-val03-source-id="${src.id}" aria-pressed="${g.selectedSource===src.id}" data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="Selection" data-ds-prop-density="Default"><span class="valuation-radio-control" aria-hidden="true"><span></span></span><span><strong>${esc(src.label)}</strong><small>${esc(val03SourcePriceText(src,g.uom))}</small></span></button>`).join("")}</div><label class="val03-reason" data-ds-component="VTextarea" data-figma-node="522:7212"><span>Lý do chọn nguồn <b>*</b></span><textarea rows="3" data-val03-reason="${g.id}" placeholder="Nêu căn cứ để truy vết">${esc(g.reason||"")}</textarea></label>`;
    }else if(st==="MISSING"){
      sourceUI=vBanner("warning","Chưa đủ căn cứ","Phần này đang chờ căn cứ có thẩm quyền; không nhập giá tạm để đi tiếp.");
    }else{
      const src=g.sources[0];g.selectedSource=g.selectedSource||src.id;
      sourceUI=`${ds24InfoGroup("Căn cứ",ds24InfoRow("Nguồn giá",src.label),"valuation-info-group valuation-info-group--wrap")}${src.provenance?.length?`<div class="valuation-provenance" data-composed-from="VText"><strong>Thành phần nguồn</strong>${src.provenance.map(x=>`<p>${esc(String(x).replace(/\s+v\d+\b/gi,"").replace(/\bFX\b/g,"Tỷ giá"))}</p>`).join("")}</div>`:""}`;
    }
    const c=val03Calc(g);
    const breakdown=c?`<div class="valuation-kv-stack" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow("Giá nguồn quy đổi",`${val03FmtMoney(c.baseVnd)}/${g.uom}`)}${c.src.unitLineDiscount?ds24KeyValueRow("Chiết khấu dòng",`− ${val03FmtMoney(c.src.unitLineDiscount)}/${g.uom}`):""}${c.src.unitDocDiscount?ds24KeyValueRow("Chiết khấu phiếu",`− ${val03FmtMoney(c.src.unitDocDiscount)}/${g.uom}`):""}${c.src.unitKnownCost?ds24KeyValueRow("Chi phí mua đã có",`+ ${val03FmtMoney(c.src.unitKnownCost)}/${g.uom}`):""}${c.src.unitNonDeductibleVat?ds24KeyValueRow("Thuế không khấu trừ",`+ ${val03FmtMoney(c.src.unitNonDeductibleVat)}/${g.uom}`):""}${ds24KeyValueRow("Giá nhập thực tế",`${val03FmtMoney(c.unitActual)}/${g.uom}`,true)}${ds24KeyValueRow("Giá trị dự kiến",val03FmtMoney(c.value),true)}</div>`:"";
    return `<section class="valuation-evidence-group">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom})}<div class="valuation-evidence-body">${sourceUI}${breakdown}</div></section>`;
  }).join("");
}
function val03EvidenceSheet(r=val03Current()){
  if(!val03EvidenceSheetOpen)return "";
  const invalid=!val03ScopeReady(r),title=val03HasSelectedConflict(r)?"Đối chiếu căn cứ":"Căn cứ và cách tính";
  const feedback=val03LastSourceChange?vBanner("warning","Căn cứ vừa thay đổi",`${val03LastSourceChange.name}: ${val03LastSourceChange.from} → ${val03LastSourceChange.to}`):invalid&&val03HasSelectedConflict(r)?vBanner("error","Cần hoàn tất căn cứ","Chọn nguồn có thẩm quyền và ghi lý do cho phần đang mâu thuẫn."):"";
  const calculation=val03CalculationGroupsHtml(r);
  const sheetBody=calculation||ioEmpty("Chưa có phạm vi để xem căn cứ","Chọn ít nhất một lô hoặc phạm vi hàng trước khi xem căn cứ và cách tính.");
  const doneLabel=val03HasSelectedConflict(r)?"Xong":"Đóng";
  return `<div class="sheet-backdrop valuation-sheet-backdrop" data-val03-action="close-evidence-sheet"><section class="bottom-sheet val03-evidence-sheet valuation-evidence-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}" onclick="event.stopPropagation()"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(title)}</h3></div><div class="sheet-divider"></div><div class="sheet-content">${feedback}${sheetBody}<div class="sheet-actions"><button class="button button--primary" type="button" data-val03-action="close-evidence-sheet" ${val03HasSelectedConflict(r)&&!val03ScopeReady(r)?"disabled":""} data-ds-component="VButton" data-figma-node="521:529">${esc(doneLabel)}</button></div></div></section></div>`;
}
function val03ReviewGroupsHtml(r){
  const content=r.groups.filter(g=>val03GroupSelectedQty(g)>0).map(g=>{
    const c=val03Calc(g);
    const facts=`<div class="valuation-product-facts" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow("Giá nhập thực tế",c?`${val03FmtMoney(c.unitActual)}/${g.uom}`:"—")}${ds24KeyValueRow("Nguồn",val03SourceDetail(g))}${g.officialCostStatus==="NONE"?ds24KeyValueRow("Đơn giá chính thức",`Sẽ khởi tạo sau xác nhận`):""}</div>`;
    const slices=g.slices.filter(s=>s.selected&&s.pendingQty>0).map(s=>{const q=Math.min(Number(s.selectedQty)||0,s.pendingQty),ad=val03SelectedAvailability(g,s);const effect=ad>0?`+${ad} ${g.uom}`:s.availabilityNote;return valuationReadOnlyChild({title:val03ScopeLabel(g,s),subtitle:`${s.stateLabel} · ${q} ${g.uom}`,trailing:`<span class="valuation-child-value"><small>Khả dụng</small><strong>${esc(effect)}</strong></span>`});}).join("");
    return `<div class="valuation-product-group">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,value:c?val03FmtMoney(c.value):"—"})}${facts}<div class="valuation-child-list">${slices}</div></div>`;
  }).join("");
  return ds24GroupedCollection(content,"valuation-product-collection valuation-review-collection","DS v2 / Icon,DS v2 / Key-value Row,VText");
}
function val03ResultGroupsHtml(res){
  const content=(res.groups||[]).map(g=>{
    const facts=`<div class="valuation-product-facts" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow("Giá nhập thực tế",`${val03FmtMoney(g.unitActual)}/${g.uom}`)}${g.officialCostInitialized?ds24KeyValueRow("Đơn giá chính thức","Đã khởi tạo"):""}</div>`;
    const slices=g.slices.map(s=>valuationReadOnlyChild({title:s.lot?`Lô ${s.lot}`:"Không theo lô",subtitle:`${s.state} · ${s.qty} ${g.uom}`,trailing:`<span class="valuation-child-value"><small>Khả dụng</small><strong>${esc(s.availabilityDelta>0?`+${s.availabilityDelta} ${g.uom}`:s.availabilityNote)}</strong></span>`})).join("");
    return `<div class="valuation-product-group">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,value:val03FmtMoney(g.value)})}${facts}<div class="valuation-child-list">${slices}</div></div>`;
  }).join("");
  return ds24GroupedCollection(content,"valuation-product-collection valuation-result-collection","DS v2 / Icon,DS v2 / Key-value Row,VText");
}
function render014IV03(state){
  if(activeFlowId!=="UIF-03")return renderGeneric(screens.find(s=>s.id==="SCR-014"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Hàng chờ xác nhận giá nhập",body:deniedBody(),centered:true,back:false});
  const rows=val03Receipts.filter(r=>val03PendingSlices(r).length&&val03FilterMatch(r)&&ioMatchesSearch(val03Query,`${r.receipt} ${r.supplier}`));
  const list=rows.map(r=>{const st=val03ReceiptState(r),[label,tone]=val03ReceiptBadge(r),products=new Set(val03PendingSlices(r).map(x=>`${x.group.code}|${x.group.uom}`)).size;const subtitle=`${r.supplier} · ${products} dòng hàng · Chờ ${r.ageDays} ngày`;return ds24ListRow({title:r.receipt,subtitle,trailing:ds24Badge(label,valuationDsTone(tone)),leading:null,attrs:`data-val03-receipt="${r.id}"`,type:"Navigation",state:st==="WAITING"?"Disabled":"Default",disabled:st==="WAITING",density:"Default"});}).join("");
  const body=`${ds24Search(val03Query,'data-val03-search','Phiếu nhận hoặc nhà cung cấp')}<div class="ds24-chip-scroll" aria-label="Lọc công việc">${[["ALL","Tất cả"],["READY","Có thể xử lý"],["WAITING","Đang chờ"]].map(([k,l])=>ds24Chip(k,l,val03Filter===k,'data-val03-filter')).join("")}</div>${rows.length?`<section class="ds24-list-stack valuation-work-list" data-composed-from="DS v2 / List Row,VBadge">${list}</section>`:ioEmpty("Không tìm thấy phiếu phù hợp","Đổi từ khóa hoặc bộ lọc để xem công việc khác.")}`;
  return appShell({title:"Hàng chờ xác nhận giá nhập",body,back:false});
}

function render015IV03(state){
  if(activeFlowId!=="UIF-03")return renderGeneric(screens.find(s=>s.id==="SCR-015"),state);
  const r=val03Current();
  if(state==="PERMISSION_DENIED")return appShell({title:"Chọn hàng cần xác nhận giá",body:deniedBody(),centered:true});
  const selected=val03SelectedSlices(r),hasConflict=val03HasSelectedConflict(r),[statusLabel,statusTone]=val03ReceiptBadge(r);
  const notice=state==="ALREADY_CONFIRMED"?vBanner("info","Đã ghi một phần","Chỉ phần còn chờ giá được hiển thị."):"";
  const waiting=val03WaitingPairs(r).length?vBanner("info","Có phần đang chờ căn cứ","Bạn vẫn có thể xử lý phần đã đủ căn cứ."):"";
  const context=ds24ContextStatusRow({title:r.receipt,subtitle:`${r.supplier} · ${r.warehouse} · Nhận ${r.receivedAt}`,label:statusLabel,tone:valuationDsTone(statusTone),leading:null});
  const body=`${context}${notice}${waiting}${ds24SectionTitle("Hàng cần xác nhận giá",`${val03PendingSlices(r).length} phạm vi đang chờ`)}${val03ScopeGroupsHtml(r)}${selected.length?`<button type="button" class="io-text-action valuation-text-action" data-val03-action="open-evidence-sheet" data-ds-component="DS v2 / Link" data-figma-node="4431:10396">${hasConflict?"Đối chiếu căn cứ":"Xem căn cứ và cách tính"}</button>`:""}${val03EvidenceSheet(r)}`;
  return appShell({title:"Chọn hàng cần xác nhận giá",body,actions:primaryFooter(hasConflict?"Đối chiếu căn cứ":"Rà soát xác nhận",hasConflict?'data-val03-action="open-evidence-sheet"':'data-val03-action="open-review"',selected.length===0)});
}

function render016IV03(state){
  if(activeFlowId!=="UIF-03")return renderGeneric(screens.find(s=>s.id==="SCR-016"),state);
  const r=val03Current();
  const body=`${vBanner("info","Nội dung hỗ trợ","Căn cứ và cách tính được mở ngay trong màn đang làm việc, không còn là một bước điều hướng riêng.")}${val03CalculationGroupsHtml(r)}`;
  return appShell({title:"Căn cứ và cách tính",body,actions:primaryFooter("Về hàng cần xác nhận",'data-val03-action="retired-to-scope"')});
}

function render017IV03(state){
  if(activeFlowId!=="UIF-03")return renderGeneric(screens.find(s=>s.id==="SCR-017"),state);
  const r=val03Current();
  if(state==="PERMISSION_DENIED")return appShell({title:"Rà soát xác nhận giá",body:deniedBody(),centered:true});
  const stale=state==="SOURCE_CHANGED"||(val03ReviewSourceVersion!=null&&Number(val03ReviewSourceVersion)!==Number(r.sourceVersion));
  const summary=`${ds24ContextStatusRow({title:r.receipt,subtitle:`${r.supplier} · ${val03SelectedGroupCount(r)} dòng hàng`,label:"Sẵn sàng",tone:"Success",leading:null})}<div class="valuation-total-strip" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow("Tổng giá trị sẽ ghi",val03FmtMoney(val03TotalValue(r)),true)}</div>`;
  if(stale){val03EvidenceSheetOpen=true;return appShell({title:"Rà soát xác nhận giá",body:`${vBanner("warning","Căn cứ giá đã thay đổi","Không thể xác nhận trên dữ liệu cũ. Đối chiếu căn cứ hiện hành trước khi tiếp tục.")}${summary}${ds24SectionTitle("Nội dung sẽ xác nhận",`${val03SelectedGroupCount(r)} dòng hàng`)}${val03ReviewGroupsHtml(r)}${val03EvidenceSheet(r)}`});}
  const body=`${summary}${ds24SectionTitle("Nội dung sẽ xác nhận",`${val03SelectedGroupCount(r)} dòng hàng`)}${val03ReviewGroupsHtml(r)}<button type="button" class="io-text-action valuation-text-action" data-val03-action="open-evidence-sheet" data-ds-component="DS v2 / Link" data-figma-node="4431:10396">Xem căn cứ và cách tính</button>${val03EvidenceSheet(r)}`;
  return appShell({title:"Rà soát xác nhận giá",body,actions:primaryFooter("Xác nhận giá trị",'data-val03-action="confirm-value"',!val03ScopeReady(r))});
}

function render019IV03(state){
  if(activeFlowId!=="UIF-03")return renderGeneric(screens.find(s=>s.id==="SCR-019"),state);
  const res=val03ResultSnapshot();
  if(state==="PROCESSING")return appShell({title:"Kết quả xác nhận giá",body:loadingBody(),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Đang xác minh kết quả",body:ioResult("Chưa xác định thao tác đã ghi hay chưa","Không gửi lại xác nhận. Công việc tạm thời không thể thao tác lại cho đến khi có kết quả.",[["Phiếu nhận",res.receipt],["Trạng thái","Đang xác minh"]],"warning"),centered:true,back:false,actions:primaryFooter("Về danh sách",'data-val03-action="result-to-queue"')});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả xác nhận giá",body:ioResult("Chưa ghi nhận giá trị","Không có thay đổi. Kiểm tra lại phạm vi và căn cứ hiện hành.",[["Phiếu nhận",res.receipt],["Tác động","Không thay đổi"]],"warning"),centered:true,back:false,actions:primaryFooter("Xem lại hàng cần xác nhận",'data-val03-action="result-to-scope"')});
  const actionable=val03ActionablePairs(val03Current()).length,waiting=val03WaitingPairs(val03Current()).length;
  const waitingNote=waiting&&!actionable?vBanner("info","Phần còn lại đang chờ căn cứ","Bạn đã hoàn tất phần có thể xử lý."):"";
  const overview=ds24InfoGroup("Kết quả",`${ds24InfoRow("Phiếu nhận",res.receipt)}${ds24KeyValueRow("Giá trị đã ghi",val03FmtMoney(res.totalValue),true)}`,"valuation-info-group valuation-result-overview");
  const body=`<div class="io-result val03-result">${resultHero("Đã xác nhận giá","Giá trị đã được ghi cho đúng phạm vi đã chọn.")}${overview}${ds24SectionTitle("Phạm vi đã ghi")}${val03ResultGroupsHtml(res)}${waitingNote}</div>`;
  return appShell({title:"Kết quả xác nhận giá",body,centered:true,back:false,actions:primaryFooter(actionable?"Tiếp tục xác nhận":"Về danh sách",actionable?'data-val03-action="continue-remaining"':'data-val03-action="result-to-queue"')});
}

// ============================================================================
// UIF-13 / BJ-13 v1.4.5 — Late landed cost deep Product correction.
// Allocation-method labels below are runtime fixtures returned by the preview
// model. They are not a canonical business enum; BC-IV-06/API-Q-12 owns the
// authoritative allowed set and calculation in production.
// ============================================================================
const val13Tasks = [
  {id:"LC13-001",sourceRef:"Hóa đơn vận chuyển VC-8842 · dòng 1",sourceVersion:2,evidence:"VC-8842.pdf",supplier:"Vận tải An Phát",component:"Chi phí vận chuyển",sourceAmount:1200000,currency:"VND",normalizedAmount:1200000,fxLabel:"VND",ageDays:4,status:"ACTIONABLE",waitingOwner:"",originalPeriod:"08/2026",postingPeriod:"09/2026",periodReason:"Kỳ gốc đã khóa; ghi điều chỉnh ở kỳ mở hiện tại",policyVersion:"ALC-POL-v5",allowedMethods:[{id:"FIXTURE_VALUE",label:"Theo giá trị nhập ban đầu"}],selectedMethod:"FIXTURE_VALUE",targets:[
    {id:"LC13-T1",receipt:"PN-260816-04",lineId:"ROL-401",product:"Nobivac DHPPi",code:"SP-00142",uom:"hộp",lot:"DH2507",qty:50,receivedValue:4085000,selected:true},
    {id:"LC13-T2",receipt:"PN-260816-04",lineId:"ROL-404",product:"Amoxicillin LA",code:"SP-00088",uom:"chai",lot:null,qty:24,receivedValue:2880000,selected:true},
    {id:"LC13-T3",receipt:"PN-260821-03",lineId:"ROL-512",product:"Vaccine Canine X",code:"SP-00421",uom:"lọ",lot:"CX2608",qty:40,receivedValue:4010000,selected:true}
  ]},
  {id:"LC13-002",sourceRef:"Phí bảo hiểm INS-2609-17 · dòng 2",sourceVersion:1,evidence:"INS-2609-17.pdf",supplier:"Bảo hiểm Minh Thành",component:"Phí bảo hiểm hàng mua",sourceAmount:250,currency:"USD",normalizedAmount:6125000,fxRate:24500,fxLabel:"Tỷ giá kế toán 24.500 VND/USD",ageDays:2,status:"ACTIONABLE",waitingOwner:"",originalPeriod:"09/2026",postingPeriod:"09/2026",periodReason:"Kỳ gốc đang mở",policyVersion:"ALC-POL-v5",allowedMethods:[{id:"FIXTURE_VALUE",label:"Theo giá trị nhập ban đầu"}],selectedMethod:"FIXTURE_VALUE",targets:[
    {id:"LC13-T4",receipt:"PN-260901-03",lineId:"ROL-601",product:"Vaccine Canine X",code:"SP-00421",uom:"lọ",lot:"CX2609",qty:10,receivedValue:1002450,selected:true},
    {id:"LC13-T5",receipt:"PN-260901-08",lineId:"ROL-633",product:"Doxycycline 100mg",code:"SP-00611",uom:"hộp",lot:null,qty:60,receivedValue:7200000,selected:true}
  ]},
  {id:"LC13-003",sourceRef:"Hóa đơn vận chuyển VC-8890 · dòng 1",sourceVersion:1,evidence:"VC-8890.pdf",supplier:"Logistics Đông Dương",component:"Chi phí vận chuyển",sourceAmount:180,currency:"USD",normalizedAmount:null,fxLabel:"",ageDays:6,status:"WAITING",waitingOwner:"Chờ nguồn hoàn tất quy đổi giá trị",originalPeriod:"08/2026",postingPeriod:"",periodReason:"",policyVersion:"",allowedMethods:[],selectedMethod:"",targets:[]},
  {id:"LC13-004",sourceRef:"Điều chỉnh chiết khấu CK-2609-06 · dòng 1",sourceVersion:3,evidence:"CK-2609-06.pdf",supplier:"Minh Dũng",component:"Điều chỉnh chiết khấu mua",sourceAmount:-350000,currency:"VND",normalizedAmount:-350000,fxLabel:"VND",ageDays:1,status:"ACTIONABLE",waitingOwner:"",originalPeriod:"09/2026",postingPeriod:"09/2026",periodReason:"Kỳ gốc đang mở",policyVersion:"ALC-POL-v5",allowedMethods:[{id:"FIXTURE_VALUE",label:"Theo giá trị nhập ban đầu"}],selectedMethod:"FIXTURE_VALUE",targets:[
    {id:"LC13-T6",receipt:"PN-260902-07",lineId:"ROL-407",product:"Dung dịch sát khuẩn",code:"SP-00510",uom:"chai",lot:null,qty:12,receivedValue:552000,selected:true},
    {id:"LC13-T7",receipt:"PN-260902-07",lineId:"ROL-408",product:"Bơm tiêm 5ml",code:"SP-00511",uom:"hộp",lot:null,qty:8,receivedValue:640000,selected:true}
  ]}
];
let val13SelectedTaskId="LC13-001", val13Query="", val13Filter="ALL", val13ReviewSourceVersion=null, val13PreviewHash=null, val13LastSourceChange=null, val13LastResult=null, val13OperationSeq=1;
function val13Current(){return val13Tasks.find(t=>t.id===val13SelectedTaskId)||val13Tasks[0];}
function val13FmtMoney(value){const n=Number(value||0);return `${new Intl.NumberFormat('vi-VN').format(n)} đ`;}
function val13FmtSourceAmount(t){const amount=new Intl.NumberFormat('vi-VN',{maximumFractionDigits:2}).format(Number(t.sourceAmount||0));return `${amount} ${t.currency}`;}
function val13SelectedTargets(t=val13Current()){return (t.targets||[]).filter(x=>x.selected);}
function val13TaskSearchText(t){return ioNormalizeSearch(`${t.id} ${t.sourceRef} ${t.supplier} ${t.component}`);}
function val13QueueTitle(t){return String(t.sourceRef||"").replace(/^(Hóa đơn vận chuyển|Phí bảo hiểm|Điều chỉnh chiết khấu)\s+/i,"");}
function val13AllocationWeight(target,method){return method==="FIXTURE_QTY"?Math.max(0,Number(target.qty)||0):Math.max(0,Number(target.receivedValue)||0);}
function val13Preview(t=val13Current()){
  const targets=val13SelectedTargets(t);const total=Number(t.normalizedAmount||0);if(!targets.length||t.normalizedAmount==null)return [];
  const weights=targets.map(x=>val13AllocationWeight(x,t.selectedMethod));const weightTotal=weights.reduce((a,b)=>a+b,0)||targets.length;
  let used=0;return targets.map((target,index)=>{let amount;if(index===targets.length-1)amount=total-used;else{const weight=weightTotal?weights[index]:1;amount=Math.round(total*(weight/weightTotal));used+=amount;}return {...target,allocatedAmount:amount,roundingAdjustment:index===targets.length-1?total-used-amount:0};});
}
function val13PreviewHashOf(t=val13Current()){return `${t.id}|v${t.sourceVersion}|${t.selectedMethod}|${val13SelectedTargets(t).map(x=>x.id).sort().join(',')}|${t.normalizedAmount}`;}
function val13CanOpenAllocation(t=val13Current()){return t.status==="ACTIONABLE"&&t.normalizedAmount!=null&&val13SelectedTargets(t).length>0;}
function val13CanPreview(t=val13Current()){return val13CanOpenAllocation(t)&&t.allowedMethods.some(m=>m.id===t.selectedMethod);}
function val13StatusMeta(t){if(t.status==="WAITING")return [t.waitingOwner||"Đang chờ","neutral"];return ["Có thể xử lý","success"];}
function val13ResetTaskDraft(t){for(const target of (t.targets||[]))target.selected=true;t.selectedMethod=t.allowedMethods?.length===1?t.allowedMethods[0].id:"";val13ReviewSourceVersion=null;val13PreviewHash=null;val13LastSourceChange=null;}
function val13SourceCard(t){
  const [rawLabel,rawTone]=val13StatusMeta(t);const label=t.status==="WAITING"?"Đang chờ":rawLabel;
  const context=ds24ContextStatusRow({title:t.sourceRef,subtitle:`${t.component} · ${t.supplier}`,label,tone:valuationDsTone(rawTone),leading:null});
  const facts=`${ds24InfoRow("Giá trị nguồn",val13FmtSourceAmount(t))}${t.currency!=="VND"&&t.fxLabel?ds24InfoRow("Tỷ giá",t.fxLabel):""}${t.normalizedAmount!=null?ds24KeyValueRow("Sau chuẩn hóa",val13FmtMoney(t.normalizedAmount),true):""}${ds24InfoRow("Lần cập nhật nguồn",`Lần ${t.sourceVersion}`)}${ds24InfoRow("Bằng chứng",t.evidence)}`;
  return `${context}${ds24InfoGroup("Chi tiết nguồn",facts,"valuation-info-group valuation-info-group--wrap val13-source-card")}`;
}
function val13TargetHtml(t){
  return (t.targets||[]).map(target=>`<button type="button" class="val13-target-row ${target.selected?'is-selected':''}" data-val13-target="${target.id}" aria-pressed="${target.selected}" data-composed-from="VCheckbox,VText"><span class="valuation-selection-control val13-check-mark" aria-hidden="true">${target.selected?icon('check','icon--xs'):''}</span><span class="val13-target-copy"><strong>${esc(target.product)}</strong><small>${esc(target.receipt)} · ${esc(target.code)} · ${target.qty} ${esc(target.uom)}${target.lot?` · Lô ${esc(target.lot)}`:""}</small></span></button>`).join('');
}
function val13AllocationRows(t=val13Current()){
  const rows=val13Preview(t);return rows.map(row=>`<div class="val13-allocation-row valuation-allocation-row" data-composed-from="VText"><span><strong>${esc(row.product)}</strong><small>${esc(row.receipt)} · ${row.qty} ${esc(row.uom)}${row.lot?` · Lô ${esc(row.lot)}`:""}</small></span><strong class="valuation-amount">${esc(val13FmtMoney(row.allocatedAmount))}</strong></div>`).join('');
}
function val13DirtyScope(t=val13Current()){return [...new Map(val13Preview(t).map(x=>[`${x.product}|${x.uom}`,`${x.product} · ${x.uom}`])).values()];}
function val13PeriodCard(t){
  const differs=t.originalPeriod&&t.postingPeriod&&t.originalPeriod!==t.postingPeriod;
  return `${differs?vBanner("info","Ghi nhận ở kỳ mở hiện tại",t.periodReason||"Kỳ gốc đã khóa; điều chỉnh vẫn liên kết về kỳ gốc."):""}${ds24InfoGroup("Kỳ ghi nhận",`${ds24InfoRow("Kỳ gốc",t.originalPeriod||"—")}${ds24InfoRow("Kỳ ghi nhận",t.postingPeriod||"—")}`,"valuation-info-group")}`;
}
function val13ReviewBody(t){
  const allocations=val13Preview(t),method=t.allowedMethods.find(m=>m.id===t.selectedMethod)?.label||"—",total=allocations.reduce((sum,x)=>sum+x.allocatedAmount,0);
  const allocation=`${ds24SectionTitle("Phân bổ sẽ ghi",`${allocations.length} dòng đích`)}${ds24GroupedCollection(`${val13AllocationRows(t)}<div class="valuation-total-strip valuation-total-strip--inside">${ds24KeyValueRow("Tổng phân bổ",val13FmtMoney(total),true)}</div>`,"valuation-allocation-collection val13-review-group","VText,DS v2 / Key-value Row")}`;
  const methodInfo=ds24InfoGroup("Căn cứ phân bổ",`${ds24KeyValueRow("Giá trị sau chuẩn hóa",val13FmtMoney(t.normalizedAmount),true)}${ds24InfoRow("Phương pháp",method)}`,"valuation-info-group");
  const effects=ds24InfoGroup("Tác động sau ghi",`${ds24InfoRow("Số lượng tồn kho","Không thay đổi")}${ds24InfoRow("Giá vốn chính thức","Chưa tự công bố lại")}${ds24InfoRow("Cần tính lại",val13DirtyScope(t).join("; ")||"—")}`,"valuation-info-group valuation-info-group--wrap");
  return `${val13SourceCard(t)}${methodInfo}${allocation}${val13PeriodCard(t)}${effects}`;
}
function val13Commit(){const t=val13Current();const allocations=val13Preview(t);val13LastResult={operationId:`LC13-OP-${String(val13OperationSeq++).padStart(3,'0')}`,taskId:t.id,sourceRef:t.sourceRef,component:t.component,normalizedAmount:t.normalizedAmount,postingPeriod:t.postingPeriod,originalPeriod:t.originalPeriod,allocations:allocations.map(x=>({...x})),dirtyScope:val13DirtyScope(t)};t.status="COMPLETED";return val13LastResult;}
function val13Result(){return val13LastResult||{operationId:"LC13-OP-PREVIEW",taskId:val13Current().id,sourceRef:val13Current().sourceRef,component:val13Current().component,normalizedAmount:val13Current().normalizedAmount,postingPeriod:val13Current().postingPeriod,originalPeriod:val13Current().originalPeriod,allocations:val13Preview(),dirtyScope:val13DirtyScope()};}
function val13ApplySourceUpdate(){const t=val13Current();if(t.status!=="ACTIONABLE")return;t.sourceVersion+=1;const before=t.normalizedAmount;t.normalizedAmount=Number(t.normalizedAmount||0)+100000;val13LastSourceChange={from:val13FmtMoney(before),to:val13FmtMoney(t.normalizedAmount),version:t.sourceVersion};if(activeScreenId==="SCR-088")stateByScreen["SCR-088"]="SOURCE_CHANGED";render();}
window.val13ApplySourceUpdate=val13ApplySourceUpdate;

function render085IV13(state){
  if(activeFlowId!=="UIF-13")return renderGeneric(screens.find(s=>s.id==="SCR-085"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Chi phí mua bổ sung",body:deniedBody(),centered:true,back:false});
  const all=val13Tasks.filter(t=>t.status!=="COMPLETED");const filtered=all.filter(t=>{const filterOk=val13Filter==="ALL"||(val13Filter==="ACTIONABLE"&&t.status==="ACTIONABLE")||(val13Filter==="WAITING"&&t.status==="WAITING");const queryOk=!val13Query||val13TaskSearchText(t).includes(ioNormalizeSearch(val13Query));return filterOk&&queryOk;});
  if(state==="EMPTY"&&!all.length)return appShell({title:"Chi phí mua bổ sung",body:ioEmpty("Không có chi phí mua bổ sung","Các chứng từ cần xử lý sẽ xuất hiện tại đây."),centered:true,back:false});
  const rows=filtered.map(t=>{const [label,tone]=val13StatusMeta(t),subtitle=`${t.component} · ${t.supplier} · Chờ ${t.ageDays} ngày`;return ds24ListRow({title:val13QueueTitle(t),subtitle,trailing:ds24Badge(t.status==="WAITING"?"Đang chờ":label,valuationDsTone(tone)),leading:null,attrs:`data-val13-task="${t.id}"`,type:"Navigation",state:t.status==="WAITING"?"Disabled":"Default",disabled:t.status==="WAITING"});}).join('');
  const empty=filtered.length?"":ioEmpty("Không tìm thấy công việc phù hợp","Đổi từ khóa hoặc bộ lọc để xem công việc khác.");
  const body=`${ds24Search(val13Query,'data-val13-search','Chứng từ chi phí hoặc nhà cung cấp')}<div class="ds24-chip-scroll" aria-label="Lọc chi phí mua bổ sung">${[["ALL","Tất cả"],["ACTIONABLE","Có thể xử lý"],["WAITING","Đang chờ"]].map(([k,l])=>ds24Chip(k,l,val13Filter===k,'data-val13-filter')).join("")}</div>${filtered.length?`<section class="ds24-list-stack valuation-work-list" data-composed-from="DS v2 / List Row,VBadge">${rows}</section>`:empty}`;
  return appShell({title:"Chi phí mua bổ sung",body,back:false});
}

function render086IV13(state){
  if(activeFlowId!=="UIF-13")return renderGeneric(screens.find(s=>s.id==="SCR-086"),state);const t=val13Current();
  if(state==="LOADING")return appShell({title:"Nguồn và phạm vi chi phí",body:loadingBody(),centered:true});
  if(state==="PERMISSION_DENIED")return appShell({title:"Nguồn và phạm vi chi phí",body:deniedBody(),centered:true});
  if(t.status==="WAITING")return appShell({title:"Nguồn và phạm vi chi phí",body:`${vBanner("info","Chưa thể xử lý",t.waitingOwner||"Đang chờ căn cứ cần thiết.")}${val13SourceCard(t)}`});
  const changed=state==="SOURCE_CHANGED"||Boolean(val13LastSourceChange),selected=val13SelectedTargets(t).length;
  const body=`${changed?vBanner("warning","Nguồn chi phí vừa thay đổi",val13LastSourceChange?`Giá trị chuẩn hóa ${val13LastSourceChange.from} → ${val13LastSourceChange.to}. Chọn lại phạm vi trước khi tiếp tục.`:"Tải lại nguồn hiện hành trước khi tiếp tục."):""}${val13SourceCard(t)}${ds24SectionTitle("Phạm vi liên quan",`${selected}/${t.targets.length} dòng đã chọn`)}${ds24GroupedCollection(val13TargetHtml(t),"valuation-selection-collection val13-target-list","VCheckbox,VText")}`;
  return appShell({title:"Nguồn và phạm vi chi phí",body,actions:primaryFooter("Tiếp tục phân bổ",'data-val13-action="scope-to-allocation"',selected===0)});
}

function render087IV13(state){
  if(activeFlowId!=="UIF-13")return renderGeneric(screens.find(s=>s.id==="SCR-087"),state);const t=val13Current();
  if(state==="LOADING")return appShell({title:"Phân bổ chi phí",body:loadingBody(),centered:true});
  if(state==="PERMISSION_DENIED")return appShell({title:"Phân bổ chi phí",body:deniedBody(),centered:true});
  if(state==="SOURCE_CHANGED")return appShell({title:"Phân bổ chi phí",body:`${vBanner("warning","Nguồn chi phí đã thay đổi","Phân bổ cũ không còn hợp lệ.")}${val13SourceCard(t)}`,actions:primaryFooter("Kiểm tra lại phạm vi",'data-val13-action="back-scope"')});
  const preview=val13Preview(t),total=preview.reduce((sum,x)=>sum+x.allocatedAmount,0),methodOptions=`<option value="">Chọn căn cứ phân bổ</option>`+t.allowedMethods.map(m=>`<option value="${m.id}" ${m.id===t.selectedMethod?'selected':''}>${esc(m.label)}</option>`).join('');
  const normalizedRows=`${ds24InfoRow("Giá trị nguồn",val13FmtSourceAmount(t))}${t.currency!=="VND"?ds24InfoRow("Tỷ giá",t.fxLabel):""}${ds24KeyValueRow("Sau chuẩn hóa",val13FmtMoney(t.normalizedAmount),true)}`;
  const normalized=ds24InfoGroup("Chi phí cần phân bổ",normalizedRows,"valuation-info-group");
  const allocationBody=val13CanPreview(t)?`${ds24SectionTitle("Kết quả phân bổ",`${preview.length} dòng đích`)}${ds24GroupedCollection(`${val13AllocationRows(t)}<div class="valuation-total-strip valuation-total-strip--inside">${ds24KeyValueRow("Tổng phân bổ",val13FmtMoney(total),true)}</div>`,"valuation-allocation-collection val13-allocation-list","VText,DS v2 / Key-value Row")}${val13PeriodCard(t)}`:vBanner("info","Chọn căn cứ phân bổ","Chọn một căn cứ được phép để xem phân bổ trước khi rà soát.","", "Compact");
  const body=`${normalized}${ds24SectionTitle("Căn cứ phân bổ")}<label class="val13-select-field valuation-field" data-ds-component="VField"><span>Căn cứ phân bổ</span><select data-val13-method data-ds-component="VSelect" data-figma-node="522:7291">${methodOptions}</select><small>Áp dụng chính sách phân bổ hiện hành</small></label>${allocationBody}`;
  return appShell({title:"Phân bổ chi phí",body,actions:primaryFooter("Rà soát ghi chi phí",'data-val13-action="open-review"',!val13CanPreview(t))});
}

function render088IV13(state){
  if(activeFlowId!=="UIF-13")return renderGeneric(screens.find(s=>s.id==="SCR-088"),state);const t=val13Current();
  if(state==="PERMISSION_DENIED")return appShell({title:"Rà soát ghi chi phí",body:deniedBody(),centered:true});
  const stale=state==="SOURCE_CHANGED"||val13ReviewSourceVersion==null||Number(val13ReviewSourceVersion)!==Number(t.sourceVersion)||val13PreviewHash!==val13PreviewHashOf(t);
  if(stale){const delta=val13LastSourceChange?ds24InfoGroup("Giá trị nguồn",`${ds24InfoRow("Trước thay đổi",val13LastSourceChange.from)}${ds24InfoRow("Hiện hành",val13LastSourceChange.to)}`,"valuation-info-group"):"";return appShell({title:"Rà soát ghi chi phí",body:`${vBanner("warning","Nguồn hoặc phân bổ đã thay đổi","Tạo lại phân bổ trước khi ghi chi phí.")}${val13SourceCard(t)}${delta}`,actions:primaryFooter("Tạo lại phân bổ",'data-val13-action="back-allocation"')});}
  const body=`${val13ReviewBody(t)}<button type="button" class="io-text-action valuation-text-action" data-val13-action="back-allocation" data-ds-component="DS v2 / Link" data-figma-node="4431:10396">Chỉnh sửa phân bổ</button>`;
  return appShell({title:"Rà soát ghi chi phí",body,actions:primaryFooter("Ghi chi phí mua bổ sung",'data-val13-action="confirm-late-cost"')});
}

function render089IV13(state){
  if(activeFlowId!=="UIF-13")return renderGeneric(screens.find(s=>s.id==="SCR-089"),state);const res=val13Result();
  if(state==="PROCESSING")return appShell({title:"Kết quả ghi chi phí",body:loadingBody(),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Đang xác minh kết quả",body:ioResult("Chưa xác định thao tác đã ghi hay chưa","Không gửi lại chi phí. Công việc tạm thời không thể thao tác lại cho đến khi có kết quả.",[["Chứng từ chi phí",res.sourceRef],["Trạng thái","Đang xác minh"]],"warning"),centered:true,back:false,actions:primaryFooter("Về chi phí mua bổ sung",'data-val13-action="result-to-queue"')});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả ghi chi phí",body:ioResult("Chưa ghi chi phí mua bổ sung","Không có thay đổi. Kiểm tra lại phân bổ hiện hành.",[["Chứng từ chi phí",res.sourceRef],["Tác động","Không thay đổi"]],"warning"),centered:true,back:false,actions:primaryFooter("Xem lại phân bổ",'data-val13-action="back-allocation"')});
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả ghi chi phí",body:deniedBody(),centered:true,back:false,actions:primaryFooter("Về chi phí mua bổ sung",'data-val13-action="result-to-queue"')});
  const allocationSummary=(res.allocations||[]).map(x=>`<div class="val13-result-line valuation-allocation-row"><span><strong>${esc(x.product)}</strong><small>${esc(x.receipt)} · ${x.qty} ${esc(x.uom)}${x.lot?` · Lô ${esc(x.lot)}`:""}</small></span><strong class="valuation-amount">${esc(val13FmtMoney(x.allocatedAmount))}</strong></div>`).join('');
  const overview=ds24InfoGroup("Kết quả",`${ds24InfoRow("Chứng từ",res.sourceRef)}${ds24KeyValueRow("Chi phí đã ghi",val13FmtMoney(res.normalizedAmount),true)}${ds24InfoRow("Kỳ ghi nhận",res.postingPeriod)}${ds24InfoRow("Giá vốn","Cần tính lại")}`,"valuation-info-group valuation-info-group--wrap");
  const body=`<div class="io-result val13-result">${resultHero("Đã ghi chi phí mua bổ sung","Chi phí đã được ghi theo phạm vi phân bổ đã xác nhận.")}${overview}${ds24SectionTitle("Phân bổ đã ghi")}${ds24GroupedCollection(allocationSummary,"valuation-allocation-collection val13-result-lines","VText")}</div>`;
  return appShell({title:"Kết quả ghi chi phí",body,centered:true,back:false,actions:primaryFooter("Về chi phí mua bổ sung",'data-val13-action="result-to-queue"')});
}

// ============================================================================
// UIF-14 / BJ-14 v1.5.0 — Cost run calculation and publication.
// Run is immutable once created; blockers/calculating are states of SCR-074.
// ============================================================================
const val14Runs=[
  {id:"COST-0826",label:"Tháng 08/2026",kind:"PERIOD_CLOSE",status:"READY_FOR_REVIEW",period:"08/2026",scope:"184 sản phẩm",cutoff:"31/08/2026 · 23:59",policyMethod:"PERIODIC",policyLabel:"Bình quân cuối kỳ",policyVersion:"Chính sách giá vốn",moving:{inventory:1242800000,cogs:488120000},periodic:{inventory:1245920000,cogs:486300000},cogsTrueUp:-1820000,endingAdjustment:3120000,effectiveAt:"01/09/2026 · 00:00",blockers:[],inputVersion:7,runVersion:3,supersedes:null},
  {id:"COST-0903",label:"Cập nhật 03/09/2026",kind:"AD_HOC",status:"DIRTY",period:"09/2026",scope:"3 sản phẩm",cutoff:"04/09/2026 · 10:00",policyMethod:"PERIODIC",policyLabel:"Bình quân cuối kỳ",policyVersion:"Chính sách giá vốn",moving:{inventory:186400000,cogs:52700000},periodic:{inventory:186180000,cogs:52920000},cogsTrueUp:220000,endingAdjustment:-220000,effectiveAt:"04/09/2026 · 10:00",blockers:[],inputVersion:4,runVersion:0,supersedes:"COST-0902"},
  {id:"COST-0901-B",label:"Tháng 09/2026",kind:"PERIOD_CLOSE",status:"BLOCKED",period:"09/2026",scope:"Toàn bộ sản phẩm",cutoff:"30/09/2026 · 23:59",policyMethod:"PERIODIC",policyLabel:"Bình quân cuối kỳ",policyVersion:"Chính sách giá vốn",moving:null,periodic:null,cogsTrueUp:0,endingAdjustment:0,effectiveAt:"01/10/2026 · 00:00",blockers:[{title:"2 dòng hàng còn chờ xác nhận giá",owner:"Định giá tồn kho"},{title:"1 đối soát chưa có kết quả cuối",owner:"Kiểm soát tồn kho"}],inputVersion:2,runVersion:1,supersedes:null}
];
let val14SelectedRunId="COST-0826",val14SetupKind="PERIOD_CLOSE",val14SetupPeriod="08/2026",val14SetupScope="Toàn bộ sản phẩm",val14SuccessorOf=null,val14PublishReviewVersion=null,val14LastResult=null,val14CalcTimer=null;
function val14Current(){return val14Runs.find(r=>r.id===val14SelectedRunId)||val14Runs[0];}
function val14Money(n){const v=Math.round(Number(n)||0);return `${v<0?"− ":""}${Math.abs(v).toLocaleString("vi-VN")} đ`;}
function val14StatusMeta(r){if(r.status==="READY_FOR_REVIEW")return ["Sẵn sàng công bố","success"];if(r.status==="BLOCKED")return ["Bị chặn","warning"];if(r.status==="DIRTY")return ["Cần tính lại","warning"];if(r.status==="CALCULATING")return ["Đang tính","info"];if(r.status==="PUBLISHED")return ["Đã công bố","success"];return ["Chưa tính","neutral"];}
function val14MethodCard(r){
  const selected=r.policyMethod;
  const rows=[["MOVING","Bình quân liên hoàn",r.moving],["PERIODIC","Bình quân cuối kỳ",r.periodic]].map(([id,label,x])=>`<div class="val14-method-row ${selected===id?'is-policy':''}" data-composed-from="VText,VBadge"><span class="val14-method-copy"><strong>${esc(label)}</strong><small>${selected===id?'Dùng để công bố theo chính sách':'Giữ để đối chiếu'}</small>${selected===id?`<span class="val14-policy-badge">${ds24Badge("Theo chính sách","Success")}</span>`:""}</span><span class="val14-method-values"><strong>${x?esc(val14Money(x.inventory)):"—"}</strong><small>Giá trị tồn cuối</small><small>Giá vốn xuất ${x?esc(val14Money(x.cogs)):"—"}</small></span></div>`).join("");
  return ds24GroupedCollection(rows,"valuation-method-collection val14-method-card","VText,VBadge");
}
function val14Blockers(r){
  const rows=r.blockers.map(b=>`<div class="val14-blocker-row" data-composed-from="DS v2 / Icon,VText"><span class="val14-blocker-icon">${icon("alertTriangle","icon--sm")}</span><span><strong>${esc(b.title)}</strong><small>Đang chờ: ${esc(b.owner)}</small></span></div>`).join("");
  return ds24GroupedCollection(rows,"valuation-blocker-collection val14-blocker-card","DS v2 / Icon,VText");
}
function val14RunSummary(r){
  const [label,tone]=val14StatusMeta(r);
  const context=ds24ContextStatusRow({title:r.label,subtitle:`Kỳ ${r.period} · ${r.scope}`,label,tone:valuationDsTone(tone),leading:null});
  const facts=ds24InfoGroup("Thông tin lần tính",`${ds24InfoRow("Thời điểm chốt",r.cutoff)}${ds24InfoRow("Phương pháp công bố",r.policyLabel)}${ds24InfoRow("Chính sách",r.policyVersion)}`,"valuation-info-group valuation-info-group--wrap val14-summary");
  return `${context}${facts}`;
}
function val14AdjustmentCard(r,title="Điều chỉnh dự kiến"){
  return ds24InfoGroup(title,`${ds24KeyValueRow("Giá vốn xuất",val14Money(r.cogsTrueUp),true)}${ds24KeyValueRow("Giá trị tồn cuối",val14Money(r.endingAdjustment),true)}${ds24InfoRow("Hiệu lực",r.effectiveAt)}`,"valuation-info-group val14-adjustment");
}
function val14KindChoices(){
  const periodClose=val14SetupKind==="PERIOD_CLOSE";
  const row=(kind,title,desc,selected)=>`<button type="button" class="val14-choice-row${selected?' is-selected':''}" data-val14-kind="${kind}" data-ds-component="VRadio" data-figma-node="522:7410" data-ds-prop-state="${selected?'On':'Off'}" aria-pressed="${selected}"><span class="val14-radio-control" aria-hidden="true"><span></span></span><span class="val14-choice-copy"><strong>${esc(title)}</strong><small>${esc(desc)}</small></span></button>`;
  return `<div class="val14-choice-list" data-composed-from="VRadio">${row("PERIOD_CLOSE","Chốt kỳ","Tính toàn kỳ theo thời điểm chốt kế toán",periodClose)}${row("AD_HOC","Cập nhật trong kỳ","Chỉ tính phạm vi cần cập nhật",!periodClose)}</div>`;
}
function val14CreateRun(){const id=`COST-${Date.now()}`;const base=val14SuccessorOf?val14Runs.find(x=>x.id===val14SuccessorOf):null;const run={id,label:val14SetupKind==="PERIOD_CLOSE"?`Tháng ${val14SetupPeriod}`:`Cập nhật ${new Date().toLocaleDateString("vi-VN")}`,kind:val14SetupKind,status:"CALCULATING",period:val14SetupPeriod,scope:val14SetupScope,cutoff:val14SetupKind==="PERIOD_CLOSE"?`Cuối kỳ ${val14SetupPeriod}`:"04/09/2026 · 14:30",policyMethod:base?.policyMethod||"PERIODIC",policyLabel:base?.policyLabel||"Bình quân cuối kỳ",policyVersion:base?.policyVersion||"Chính sách giá vốn",moving:{inventory:1243100000,cogs:488000000},periodic:{inventory:1246150000,cogs:486150000},cogsTrueUp:-1850000,endingAdjustment:3050000,effectiveAt:val14SetupKind==="PERIOD_CLOSE"?"01/09/2026 · 00:00":"04/09/2026 · 14:30",blockers:[],inputVersion:(base?.inputVersion||7)+1,runVersion:1,supersedes:base?.id||val14SuccessorOf};val14Runs.unshift(run);val14SelectedRunId=id;val14PublishReviewVersion=null;if(val14CalcTimer)clearTimeout(val14CalcTimer);val14CalcTimer=setTimeout(()=>{run.status="READY_FOR_REVIEW";if(activeFlowId==="UIF-14"&&activeScreenId==="SCR-074")renderAppScreen();},120);return run;}
function val14Commit(){const r=val14Current();r.status="PUBLISHED";r.runVersion+=1;val14LastResult={period:r.period,scope:r.scope,method:r.policyLabel,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment};return val14LastResult;}
function val14ApplyInputChange(){const r=val14Current();r.inputVersion+=1;if(r.status==="READY_FOR_REVIEW")r.status="INPUT_CHANGED";return r.inputVersion;}
function render072IV14(state){
  if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-072"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Giá vốn",body:deniedBody(),centered:true,back:false});
  const active=val14Runs.filter(r=>r.status!=="PUBLISHED");
  const rows=active.map(r=>{const [label,tone]=val14StatusMeta(r);return ds24ListRow({title:r.label,subtitle:`${r.scope} · ${r.policyLabel}`,trailing:ds24Badge(label,valuationDsTone(tone)),leading:null,attrs:`data-val14-run="${r.id}"`,type:"Navigation"});}).join("");
  const body=`${rows?`<section class="ds24-list-stack valuation-work-list" data-composed-from="DS v2 / List Row,VBadge">${rows}</section>`:ioEmpty("Chưa có lần tính giá vốn","Tạo một lần tính để bắt đầu.")}`;
  return appShell({title:"Giá vốn",body,back:false,actions:primaryFooter("Tạo lần tính",'data-val14-action="new-run"')});
}
function render073IV14(state){
  if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-073"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Thiết lập lần tính",body:deniedBody(),centered:true});
  const periodClose=val14SetupKind==="PERIOD_CLOSE";
  const setupFacts=ds24InfoGroup("Chính sách áp dụng",`${ds24InfoRow("Thời điểm chốt",periodClose?`Cuối kỳ ${val14SetupPeriod}`:"04/09/2026 · 14:30")}${ds24InfoRow("Phương pháp công bố","Bình quân cuối kỳ")}${ds24InfoRow("Chính sách","Chính sách giá vốn")}`,"valuation-info-group");
  const body=`${val14SuccessorOf?vBanner("warning","Dữ liệu đã thay đổi","Lần tính mới sẽ thay thế lần trước; lần tính cũ được giữ nguyên để truy vết."):""}${ds24SectionTitle("Loại lần tính")}${val14KindChoices()}<label class="val14-field valuation-field" data-ds-component="VField"><span>Kỳ</span><select data-val14-period data-ds-component="VSelect" data-figma-node="522:7291"><option ${val14SetupPeriod==="08/2026"?'selected':''}>08/2026</option><option ${val14SetupPeriod==="09/2026"?'selected':''}>09/2026</option></select></label><label class="val14-field valuation-field" data-ds-component="VField"><span>Phạm vi</span><select data-val14-scope data-ds-component="VSelect" data-figma-node="522:7291"><option ${val14SetupScope==="Toàn bộ sản phẩm"?'selected':''}>Toàn bộ sản phẩm</option><option ${val14SetupScope==="Sản phẩm cần tính lại"?'selected':''}>Sản phẩm cần tính lại</option></select></label>${setupFacts}`;
  return appShell({title:"Thiết lập lần tính",body,actions:primaryFooter("Tính giá vốn",'data-val14-action="calculate"')});
}
function render074IV14(state){
  if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-074"),state);const r=val14Current();
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả lần tính",body:deniedBody(),centered:true});
  if(state==="INPUT_CHANGED")return appShell({title:"Kết quả lần tính",body:`${vBanner("warning","Dữ liệu đầu vào đã thay đổi","Lần tính hiện tại được giữ nguyên và không còn đủ điều kiện công bố.")}${val14RunSummary(r)}`,actions:primaryFooter("Tạo lần tính kế tiếp",'data-val14-action="successor"')});
  if(r.status==="CALCULATING"||state==="PROCESSING")return appShell({title:"Kết quả lần tính",body:ioResult("Đang tính giá vốn","Có thể rời màn hình; kết quả sẽ được lưu trong cùng lần tính.",[["Kỳ",r.period],["Phạm vi",r.scope]],"info"),centered:true});
  if(r.status==="BLOCKED"||state==="BLOCKED")return appShell({title:"Kết quả lần tính",body:`${vBanner("warning","Chưa thể công bố","Các vấn đề dưới đây cần được xử lý trước khi tạo lần tính mới.")}${val14RunSummary(r)}${ds24SectionTitle("Đang bị chặn",`${r.blockers.length} vấn đề`)}${val14Blockers(r)}`});
  const body=`${val14RunSummary(r)}${ds24SectionTitle("Đối chiếu hai phương pháp")}${val14MethodCard(r)}${val14AdjustmentCard(r)}`;
  return appShell({title:"Kết quả lần tính",body,actions:primaryFooter("Rà soát công bố",'data-val14-action="review-publish"',r.status!=="READY_FOR_REVIEW")});
}
function render075IV14(state){
  if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-075"),state);
  return appShell({title:"Trạng thái lần tính",body:vBanner("info","Đã gộp vào kết quả lần tính","Blocker và trạng thái xử lý được hiển thị trực tiếp tại Kết quả lần tính."),actions:primaryFooter("Về kết quả lần tính",'data-val14-action="retired-to-result"')});
}
function render076IV14(state){
  if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-076"),state);const r=val14Current();
  if(state==="PERMISSION_DENIED")return appShell({title:"Rà soát công bố",body:deniedBody(),centered:true});
  const stale=state==="SOURCE_CHANGED"||val14PublishReviewVersion==null||Number(val14PublishReviewVersion)!==Number(r.inputVersion);
  if(stale)return appShell({title:"Rà soát công bố",body:`${vBanner("warning","Dữ liệu đầu vào đã thay đổi","Không thể công bố lần tính cũ. Tạo một lần tính kế tiếp từ dữ liệu hiện hành.")}${val14RunSummary(r)}`,actions:primaryFooter("Tạo lần tính kế tiếp",'data-val14-action="successor"')});
  const after=ds24InfoGroup("Sau công bố",`${ds24InfoRow("Phiên bản giá vốn","Tạo phiên bản mới")}${ds24InfoRow("Giá bán","Không thay đổi")}`,"valuation-info-group");
  const body=`${val14RunSummary(r)}${val14AdjustmentCard(r,"Tác động khi công bố")}${after}`;
  return appShell({title:"Rà soát công bố",body,actions:primaryFooter("Công bố giá vốn",'data-val14-action="publish"',r.status!=="READY_FOR_REVIEW")});
}
function render077IV14(state){
  if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-077"),state);const r=val14Current(),res=val14LastResult||{period:r.period,scope:r.scope,method:r.policyLabel,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment};
  if(state==="PROCESSING")return appShell({title:"Kết quả công bố",body:loadingBody(),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Đang xác minh kết quả",body:ioResult("Chưa xác định giá vốn đã được công bố hay chưa","Không gửi lại lệnh công bố. Lần tính tạm thời không thể thao tác lại cho đến khi có kết quả.",[["Kỳ",res.period],["Trạng thái","Đang xác minh"]],"warning"),centered:true,back:false,actions:primaryFooter("Về giá vốn",'data-val14-action="result-to-list"')});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả công bố",body:ioResult("Chưa công bố giá vốn","Không có điều chỉnh hoặc phiên bản giá vốn mới.",[["Kỳ",res.period],["Tác động","Không thay đổi"]],"warning"),centered:true,back:false,actions:primaryFooter("Về kết quả lần tính",'data-val14-action="result-to-run"')});
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả công bố",body:deniedBody(),centered:true,back:false,actions:primaryFooter("Về giá vốn",'data-val14-action="result-to-list"')});
  const overview=ds24InfoGroup("Kết quả",`${ds24InfoRow("Kỳ",res.period)}${ds24InfoRow("Phương pháp",res.method)}${ds24InfoRow("Hiệu lực",res.effectiveAt)}${ds24KeyValueRow("Giá vốn xuất",val14Money(res.cogsTrueUp),true)}${ds24KeyValueRow("Giá trị tồn cuối",val14Money(res.endingAdjustment),true)}${ds24InfoRow("Giá bán","Không thay đổi")}`,"valuation-info-group valuation-info-group--wrap");
  const body=`<div class="io-result val14-result">${resultHero("Đã công bố giá vốn","Giá vốn và các điều chỉnh liên quan đã được ghi cho phạm vi đã rà soát.")}${overview}</div>`;
  return appShell({title:"Kết quả công bố",body,centered:true,back:false,actions:primaryFooter("Về giá vốn",'data-val14-action="result-to-list"')});
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
  selectedQuickProductId = null;
  quickProductMenuOpen = false;
  if (mode === "document") {
    documentSearchQuery = "";
    bj02Lines = createDocumentReceiptLines(selectedDocumentId);
  } else {
    bj02Lines = [];
    bj02Header = { supplierId: null, supplier: "", businessDate: BJ02_TENANT_BUSINESS_DATE, evidence: "", evidenceRefs: [], ownershipAssertion: null };
  }
}
resetBj02Receipt(flowMode);

const icons = {
  arrowLeft: '<path d="m15 18-6-6 6-6"/><path d="M9 12h10"/>',
  chevronLeft: '<path d="m15 18-6-6 6-6"/>',
  close: '<path d="m18 6-12 12"/><path d="m6 6 12 12"/>',
  arrowRight: '<path d="M5 12h14"/><path d="m13 6 6 6-6 6"/>',
  chevronRight: '<path d="m9 18 6-6-6-6"/>',
  chevronDown: '<path d="m6 9 6 6 6-6"/>',
  fileText: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/><path d="M8 13h8"/><path d="M8 17h6"/>',
  cloudUpload: '<path d="M12 13v8"/><path d="m16 16-4-4-4 4"/><path d="M4.393 15.269A5 5 0 0 1 6.5 5.5a7 7 0 0 1 13.33 3.4A4.5 4.5 0 0 1 18.5 17H17"/>',
  zap: '<path d="M13 2 3 14h9l-1 8 10-12h-9z"/>',
  info: '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>',
  alert: '<path d="M10.3 2.9 1.8 17a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 2.9a2 2 0 0 0-3.4 0z"/><path d="M12 9v4"/><path d="M12 17h.01"/>',
  search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>',
  filter: '<path d="M4 5h16"/><path d="M7 12h10"/><path d="M10 19h4"/>',
  warehouse: '<path d="M3 21V8l9-5 9 5v13"/><path d="M7 21v-8h10v8"/><path d="M7 17h10"/>',
  calendar: '<rect width="18" height="18" x="3" y="4" rx="2"/><path d="M16 2v4"/><path d="M8 2v4"/><path d="M3 10h18"/>',
  save: '<path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><path d="M17 21v-8H7v8"/><path d="M7 3v5h8"/>',
  package: '<path d="m7.5 4.27 9 5.15"/><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/>',
  layers: '<path d="m12.83 2.18 8 4a2 2 0 0 1 0 3.58l-8 4a2 2 0 0 1-1.66 0l-8-4a2 2 0 0 1 0-3.58l8-4a2 2 0 0 1 1.66 0Z"/><path d="m22 12.5-9.17 4.59a2 2 0 0 1-1.66 0L2 12.5"/><path d="m22 17.5-9.17 4.59a2 2 0 0 1-1.66 0L2 17.5"/>',
  check: '<path d="M20 6 9 17l-5-5"/>',
  checkCircle: '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>',
  xCircle: '<circle cx="12" cy="12" r="10"/><path d="M12 8v4"/><path d="M12 16h.01"/>',
  shield: '<path d="M20 13c0 5-3.5 7.5-8 9-4.5-1.5-8-4-8-9V5l8-3 8 3z"/><path d="m9 12 2 2 4-4"/>',
  user: '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
  clock: '<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>',
  history: '<path d="M3 12a9 9 0 1 0 3-6.7"/><path d="M3 3v6h6"/><path d="M12 7v5l3 2"/>',
  edit: '<path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L8 18l-4 1 1-4Z"/>',
  rotate: '<path d="M3 12a9 9 0 0 1 15-6.7L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-15 6.7L3 16"/><path d="M8 16H3v5"/>',
  lock: '<rect width="18" height="11" x="3" y="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
  inbox: '<path d="M4 4h16v16H4z"/><path d="M4 14h4l2 3h4l2-3h4"/>',
  listCheck: '<path d="m3 17 2 2 4-4"/><path d="m3 7 2 2 4-4"/><path d="M13 6h8"/><path d="M13 12h8"/><path d="M13 18h8"/>',
  more: '<circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/><circle cx="5" cy="12" r="1"/>',
};

const dsIconMap = {
  arrowLeft: "VIcons.arrowLeft", arrowRight: "VIcons.arrowRight", chevronLeft: "VIcons.chevronLeft", chevronRight: "VIcons.chevronRight", chevronDown: "VIcons.arrowDropDown",
  fileText: "VIcons.description", cloudUpload: "li:cloud-upload", zap: "VIcons.bolt", info: "VIcons.info", alert: "VIcons.warning", search: "VIcons.search",
  filter: "VIcons.tune", warehouse: "VIcons.warehouse", calendar: "VIcons.calendar", save: "VIcons.save", package: "VIcons.inventory",
  layers: "VIcons.inventory", check: "VIcons.check", checkCircle: "VIcons.success", xCircle: "VIcons.error", close: "VIcons.close",
  shield: "VIcons.shield", user: "VIcons.person", clock: "VIcons.clock", rotate: "VIcons.refresh", lock: "VIcons.lock", inbox: "VIcons.inbox",
  listCheck: "VIcons.checkList", more: "VIcons.moreHoriz", history: "VIcons.history", edit: "VIcons.edit"
};
function icon(name, className = "") {
  const semantic = dsIconMap[name] || "VIcons.info";
  return `<svg class="icon ${className}" data-ds-component="VIcon" data-ds-icon="${semantic}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${icons[name] || icons.info}</svg>`;
}
function navChevron() {
  return icon("chevronRight", "icon--sm nav-action-chevron");
}

function documentReceivingProduct() {
  const line = bj02Lines.find((item) => item.id === activeReceiptLineId) || bj02Lines[0];
  if (!line) return null;
  const product = productById(line.productId);
  return product ? { ...product, uom: line.uom, uomId: line.uomId } : null;
}

function activeReceivingProduct() {
  if (activeScreenId === "SCR-084" && lineEditorDraft?.productId) {
    const product = productById(lineEditorDraft.productId);
    return product ? { ...product, uom: lineEditorDraft.uom, uomId: lineEditorDraft.uomId } : null;
  }
  const line = bj02Lines.find((item) => item.id === activeReceiptLineId) || bj02Lines[0];
  if (!line) return null;
  const product = productById(line.productId);
  return product ? { ...product, uom: line.uom, uomId: line.uomId } : null;
}


function currentScreen() {
  return screens.find((screen) => screen.id === activeScreenId);
}

function activeFlow() { return flowCatalog.find((f) => f.id === activeFlowId) || flowCatalog[0]; }
function flowScreens() { const f=activeFlow(); return (f?.screens || []).map((id)=>screens.find((s)=>s.id===id)).filter(Boolean); }
function renderFlowSelector() {
  const sel=document.getElementById("flow-selector"); if(!sel) return;
  const grouped = FLOW_GROUPS.map((group) => ({
    label: group.label,
    flows: flowCatalog.filter((flow) => group.bjs.includes(flow.bj)),
  })).filter((group) => group.flows.length > 0);
  const ungrouped = flowCatalog.filter((flow) => !FLOW_GROUPS.some((group) => group.bjs.includes(flow.bj)));
  if (ungrouped.length) grouped.push({ label: "Other", flows: ungrouped });
  sel.innerHTML = grouped.map((group) => `
    <optgroup label="${group.label}">
      ${group.flows.map((f) => `<option value="${f.id}" ${f.id===activeFlowId?"selected":""}>${f.id} · ${f.bj} · ${f.name}</option>`).join("")}
    </optgroup>
  `).join("");
  const f=activeFlow();
  document.body.dataset.activeUif = f.id;
  document.getElementById("sidebar-flow-title").textContent=`${f.id} · ${f.name}`;
  document.getElementById("sidebar-flow-intent").textContent=f.intent || "";
  document.getElementById("workbench-title").textContent=`${f.bj} · ${f.name}`;
  document.getElementById("workbench-count").textContent=`${f.screens.length} màn · ${f.id}`;
}
function renderNavigation() {
  const navigation=document.getElementById("screen-navigation");
  navigation.innerHTML=`<div class="nav-group"><span class="nav-group-label">Screens</span>${flowScreens().map((screen)=>`<button class="screen-nav-item ${screen.id===activeScreenId?"is-active":""}" data-screen="${screen.id}" type="button"><span class="screen-nav-number">${screen.short}</span><span class="screen-nav-copy"><strong>${screen.name}</strong><span>${screen.surface}</span></span><span class="nav-chevron">›</span></button>`).join("")}</div>`;
}
function renderInspector() {
  const screen=currentScreen(); const state=stateByScreen[screen.id]; const f=activeFlow();
  document.getElementById("current-screen-id").textContent=`${screen.id} · ${screen.surface}`;
  document.getElementById("current-screen-name").textContent=screen.name;
  document.getElementById("state-switcher").innerHTML=screen.states.map((item)=>`<button class="state-chip ${item===state?"is-active":""}" data-state="${item}" type="button">${item}</button>`).join("");
  const actions=(screen.actions||[]).map((a)=>a.id).join(" · ") || (screen.traceActions?.length ? `System: ${screen.traceActions.join(" · ")}` : "Navigation / query");
  const figmaMigrationLabel = ({
    "UIF-01":"v3.0.1 · BJ01 migrated + DS hard-gated",
    "UIF-02":"v3.0.1 · BJ02 migrated + DS hard-gated",
    "UIF-03":"v3.0.1 · BJ03 valuation hierarchy + evidence",
    "UIF-13":"v3.0.1 · BJ13 late-cost allocation + review",
    "UIF-14":"v3.0.1 · BJ14 costing run + publish",
    "UIF-04":"v3.0.1 · BJ04 migrated + DS hard-gated",
    "UIF-05":"v3.0.1 · BJ05 migrated + VBottomSheet corrected",
    "UIF-06":"v3.0.1 · BJ06 UX/navigation corrected",
    "UIF-07":"v3.0.1 · BJ07 danh sách gọn + phân cấp sản phẩm/lô",
    "UIF-08":"v3.2.0 · BJ08 kiểm kê + DS aligned",
    "UIF-09":"v3.2.0 · BJ09 tình trạng hàng + audit history",
    "UIF-10":"v3.2.0 · BJ10 tiêu hủy + controlled completion",
    "UIF-11":"v3.2.0 · BJ11 hủy/sửa sai + DS aligned",
    "UIF-12":"v3.2.0 · BJ12 số dư đầu kỳ + control foundation",
    "UIF-15":"v3.2.0 · BJ15 báo cáo/thẻ kho + DS aligned",
    "UIF-16":"v3.2.0 · BJ16 đối soát sai lệch + evidence",
    "UIF-17":"v3.2.0 · BJ17 xác minh kết quả + recovery"
  })[activeFlowId] || "Calibrated shell · structural migration pending";
  document.getElementById("traceability").innerHTML=`<div class="trace-row"><span>BJ / UIF</span><strong>${f.bj} · ${f.id}</strong></div><div class="trace-row"><span>UC</span><strong>${(screen.uc||[]).join(" · ")||"—"}</strong></div><div class="trace-row"><span>Purpose</span><strong>${screen.purpose||"—"}</strong></div><div class="trace-row"><span>Action</span><strong>${actions}</strong></div><div class="trace-row"><span>Figma DS</span><strong>${figmaMigrationLabel}</strong></div><div class="trace-row"><span>DS annotations</span><strong>VPageScaffold → VAppBar · ${(screen.components||[]).join(" · ")}</strong></div><div class="trace-row"><span>Composition</span><strong>${screen.themeComposition||"—"}</strong></div>`;
  document.getElementById("design-rationale").textContent=f.intent || screen.purpose;
}

function statusBar() {
  if (FIGMA_MIGRATED_FLOWS.has(activeFlowId)) {
    return `<div class="app-statusbar" data-figma-slot="Status Bar"><span>9:41</span><span>LTE&nbsp;&nbsp;100%</span></div>`;
  }
  return `
    <div class="app-statusbar">
      <span>09:45</span>
      <span class="app-status-icons">
        <span class="signal-bars"><i></i><i></i><i></i><i></i></span>
        <span>5G</span>
        <span class="battery"></span>
      </span>
    </div>`;
}

function progress(step) {
  if (!step) return "";
  return `<div class="progress-track" aria-label="Tiến độ ${step} trên 5">${[1, 2, 3, 4, 5]
    .map((item) => `<span class="${item < step ? "is-done" : item === step ? "is-current" : ""}"></span>`)
    .join("")}</div>`;
}

function appShell({ title, subtitle = null, body, actions = "", centered = false, back = true, backAction = "" }) {
  const hasSubtitle = Boolean(subtitle);
  const baseFigmaTemplate = FIGMA_MIGRATED_FLOWS.has(activeFlowId) ? figmaScreenTemplate() : null;
  // Mobile / State is reserved for actual full-content empty/error/permission/blocked/no-result surfaces.
  // Result screens keep their business-detail archetype instead of mechanically becoming State pages.
  const isFullContentState = centered && /data-ds-component=["']VEmptyState["']/.test(String(body || ""));
  const figmaTemplate = isFullContentState ? "Mobile / State" : baseFigmaTemplate;
  const shellAttrs = `data-ds-component="VPageScaffold" data-ds-profile="screen.shell.standard" data-ds-prop-title="${escapeAttribute(title)}" data-ds-prop-subtitle="${subtitle == null ? 'null' : escapeAttribute(subtitle)}" data-ds-prop-show-back-button="${back}" data-ds-prop-center-title="false" data-ds-prop-actions="null"${figmaTemplate ? ` data-figma-template="${figmaTemplate}" data-figma-template-node="${FIGMA_TEMPLATE_NODES[figmaTemplate]}" data-figma-migrated="true"` : ''}`;
  return `
    <div class="v-page-scaffold ${figmaTemplate ? 'figma-calibrated-shell' : ''}" data-mobile-product data-product-app data-inspectable="true" ${shellAttrs}>
      ${statusBar()}
      <header class="app-header">
        <div class="app-appbar ${back ? 'has-back' : 'no-back'} ${hasSubtitle ? 'has-subtitle' : ''}" data-ds-component="VAppBar" data-ds-prop-center-title="false" data-ds-prop-actions="null" data-ds-prop-show-back-button="${back}">
          ${back ? `<button class="app-icon-button app-back-button" ${backAction ? `data-action="${backAction}"` : "data-back"} type="button" aria-label="Quay lại" data-ds-internal="VAppBar.leading">${icon("chevronLeft", "icon--24")}</button>` : ``}
          <div class="app-appbar-copy" data-ds-component="VAppBarTitle"><h3>${title}</h3>${hasSubtitle ? `<span data-ds-component="VAppBarSubtitle">${subtitle}</span>` : ""}</div>
        </div>
      </header>
      <div class="app-content ${centered ? "app-content--centered" : ""}" data-ds-component="VPagePadding" data-ds-profile="screen.body.standard" data-ds-prop-horizontal="null" data-ds-prop-vertical="null" data-ds-prop-apply-bottom-safe-area="false"><div class="body-stack">${body}</div></div>
      ${actions}
    </div>`;
}

function vBanner(status, title, description, extraClass = "", density = "Default") {
  const tone = status === "error" ? "Danger" : status === "success" ? "Success" : status === "warning" ? "Warning" : "Info";
  const iconName = status === "error" ? "xCircle" : status === "success" ? "checkCircle" : status === "warning" ? "alert" : "info";
  const semanticIcon = status === "error" ? "VIcons.error" : status === "success" ? "VIcons.success" : status === "warning" ? "VIcons.warning" : "VIcons.info";
  return `<div class="v-banner v-banner--${status} ${extraClass}" data-ds-component="VBanner" data-figma-node="526:4215" data-ds-prop-tone="${tone}" data-ds-prop-density="${density}" data-ds-default-icon="${semanticIcon}">
    <span class="v-banner-icon" data-ds-internal="VBanner.icon">${icon(iconName)}</span>
    <div class="v-banner-copy" data-ds-internal="VBanner.copy"><strong>${title}</strong>${description ? `<span>${description}</span>` : ""}</div>
  </div>`;
}

function vBadge(label, status = "info", extraClass = "") {
  return `<span class="status-badge status-badge--${status} ${extraClass}" data-ds-component="VBadge" data-ds-prop-status="VBadgeStatus.${status}">${label}</span>`;
}

function stateBanner(state) {
  const mapping = {
    CONFLICT: ["warning", "Dữ liệu vừa thay đổi", "Tải phiên bản hiện hành trước khi tiếp tục; hệ thống không ghi đè im lặng."],
    LOCKED: ["warning", "Kho đang được khóa", "Chỉ có thể xem dữ liệu. Mở công việc đang giữ khóa để biết thêm chi tiết."],
    VALIDATION_ERROR: ["error", "Cần kiểm tra dữ liệu", "Dữ liệu đã nhập được giữ lại. Sửa trường được đánh dấu trước khi tiếp tục."],
    VALIDATION_FAILED: ["error", "Kiểm tra dữ liệu chưa đạt", "Không có dữ liệu nào được ghi nhận; sửa lỗi theo từng dòng hàng."],
    LOT_CONFLICT: ["error", "Thông tin lô không khớp", "Mã lô ND2408 đã tồn tại với hạn dùng khác. Hãy đối chiếu nhãn nhà sản xuất."],
    SOURCE_VERSION_STALE: ["warning", "Chứng từ nguồn đã đổi", "Lượng còn được phép nhận vừa thay đổi. Mở phiên bản hiện hành để đối chiếu."],
    PARTIAL_RECEIPT: ["info", "Có chứng từ đã nhận một phần", "Số còn lại vẫn bám theo chứng từ nguồn và được kiểm tra lũy kế."],
    APPROVAL_REQUIRED: ["warning", "Cần phê duyệt", "Yêu cầu chưa tạo tác động tồn vật lý cho đến khi có quyết định hợp lệ."],
    PENDING_APPROVAL: ["info", "Đã gửi cho người duyệt", "Bạn có thể rời màn hình này. Tồn kho chưa thay đổi; yêu cầu sẽ tự cập nhật khi có quyết định."],
    SELF_APPROVAL_NOT_ALLOWED: ["error", "Không được tự phê duyệt", "Người lập không thể đồng thời là người quyết định yêu cầu này."],
    APPROVAL_ALREADY_DECIDED: ["info", "Yêu cầu đã có quyết định", "Quyết định hợp lệ đầu tiên có hiệu lực; các thao tác quyết định đã được khóa."],
    STALE: ["warning", "Dữ liệu có thể đã cũ", "Làm mới lịch sử trước khi dựa vào trạng thái hiện tại."],
    PROCESSING_OR_UNKNOWN: ["warning", "Kết quả chưa xác định", "Không cần tạo lần nhận mới. Hệ thống tiếp tục xác minh cùng lần nhận hiện tại."],
    TERMINAL: ["success", "Đã xác lập kết quả", "Kết quả đã rõ; hệ thống sẽ đưa bạn về màn kết quả."],
    READ_ONLY: ["info", "Chế độ chỉ xem", "Dữ liệu vẫn hiển thị nhưng mọi thao tác thay đổi đã bị khóa."],
  };
  if (!mapping[state]) return "";
  const [status, title, message] = mapping[state];
  return vBanner(status, title, message);
}

function loadingBody() {
  return `<div class="skeleton-stack" data-ds-component="VSkeleton"><div class="skeleton skeleton--heading"></div><div class="skeleton skeleton--text"></div><div class="skeleton skeleton--card"></div><div class="skeleton skeleton--card"></div><div class="skeleton skeleton--text"></div></div>`;
}

function deniedBody() {
  return `<div class="empty-state permission-denied-state" data-ds-component="VEmptyState" data-theme-component="PermissionDeniedState" data-composed-from="VEmptyState,VEmptyMedia,VText"><div class="icon-box icon-box--danger" data-ds-component="VEmptyMedia" data-ds-prop-tone="VComponentTone.danger">${icon("lock", "icon--empty-media")}</div><h3 data-ds-component="VEmptyTitle">Không có quyền truy cập</h3><p data-ds-component="VEmptyDescription">Dữ liệu nghiệp vụ không được tải vào màn hình này. Liên hệ quản trị viên nếu cần cấp quyền.</p></div>`;
}

function emptyBody(filtered = false) {
  return `<div class="empty-state" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("inbox")}</div><h3 data-ds-component="VEmptyTitle">${filtered ? "Không có kết quả phù hợp" : "Không có chứng từ đang chờ nhận"}</h3><p data-ds-component="VEmptyDescription">${filtered ? "Xóa bớt điều kiện tìm kiếm để xem thêm kết quả." : "Quay lại để chọn cách nhận hàng khác nếu phù hợp."}</p></div>`;
}

function primaryFooter(label, actionAttr, disabled = false, tone = "primary") {
  const calibrated = FIGMA_MIGRATED_FLOWS.has(activeFlowId);
  return `<footer class="app-actions${calibrated ? ' figma-sticky-footer' : ''}" data-ds-component="${calibrated ? 'DS v2 / Sticky Footer' : 'VPagePadding'}" ${calibrated ? 'data-ds-prop-layout="Single" data-ds-prop-tone="Default" data-figma-node="549:927"' : 'data-ds-slot="VPageScaffold.bottomBar"'}><button class="button button--primary" ${actionAttr} data-ds-component="VButton" data-ds-profile="button.primaryFooter" data-ds-prop-variant="VButtonVariant.primary" data-ds-prop-size="VButtonSize.medium" data-ds-prop-full-width="true" data-ds-prop-tone="VComponentTone.${tone}" type="button" ${disabled ? "disabled" : ""}>${label}</button></footer>`;
}


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
  return `<div class="bj02-key-value-row${emphasis ? " is-emphasis" : ""} ${extraClass}" data-ds-component="DS v2 / Key-value Row" data-figma-node="525:358" data-ds-prop-state="${emphasis ? "Emphasis" : "Default"}"><span>${escapeAttribute(label)}</span><strong>${escapeAttribute(value)}</strong></div>`;
}
function bj02SupplierSelectSheet(locked = false) {
  if (!supplierMenuOpen || locked) return "";
  const options = supplierCatalog.map((supplier) => {
    const selected = supplier.id === bj02Header.supplierId;
    return `<button class="bj02-sheet-list-row${selected ? " is-selected" : ""}" data-bj02-supplier-option="${supplier.id}" data-bj02-supplier-search-text="${escapeAttribute(`${supplier.name} ${supplier.code}`.toLowerCase())}" data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="Selection" data-ds-prop-density="Default" data-ds-prop-state="${selected ? "Selected" : "Default"}" type="button" role="option" aria-selected="${selected}"><span class="bj02-ds-list-leading">${icon("user","icon--sm")}</span><span class="bj02-ds-list-copy"><strong>${supplier.name}</strong><span>${supplier.code}</span></span><span class="bj02-radio-control" aria-hidden="true"></span></button>`;
  }).join("");
  return `<div class="bj02-select-backdrop" data-bj02-supplier-backdrop><section class="bj02-select-sheet" data-ds-component="DS v2 / Select Sheet" data-figma-node="550:1148" role="dialog" aria-modal="true" aria-label="Chọn nhà cung cấp"><div class="bj02-sheet-handle"></div><h2>Chọn nhà cung cấp</h2><div class="bj02-sheet-search" data-ds-component="VSearchBar" data-figma-node="522:7245"><span>${icon("search","icon--sm")}</span><input data-bj02-supplier-search value="${escapeAttribute(supplierSearchQuery)}" placeholder="Tìm kiếm" autocomplete="off" aria-label="Tìm nhà cung cấp" /></div><div class="bj02-sheet-list" data-bj02-supplier-menu role="listbox">${options}<div class="combobox-empty" data-bj02-supplier-empty hidden>Không có nhà cung cấp phù hợp. Nhà cung cấp phải được tạo trước ở Theme 3.</div></div></section></div>`;
}
function bj02ReceiptContext() {
  const handled = receiptHandledCount();
  const total = bj02Lines.length;
  const progress = total ? `${handled}/${total} đã xử lý` : "Chưa có dòng hàng";
  if (flowMode === "quick") {
    return `<section class="bj02-context-section" data-ds-component="VSection"><div class="bj02-section-heading"><strong>Thông tin lần nhận</strong><span>${progress}</span></div><div class="bj02-info-stack">${bj02InfoRow("Nhà cung cấp", currentReceiptSupplier())}${bj02InfoRow("Kho nhận", "Kho trung tâm")}</div></section>`;
  }
  return `<section class="bj02-context-section" data-ds-component="VSection"><div class="bj02-section-heading"><strong>Thông tin lần nhận</strong><span>${progress}</span></div><div class="bj02-info-stack">${bj02InfoRow("Chứng từ", selectedDocumentId)}${bj02InfoRow("Nhà cung cấp", currentReceiptSupplier())}</div></section>`;
}
function bj02SourceRows() {
  if (flowMode === "quick") {
    return `${bj02InfoRow("Nhà cung cấp", bj02Header.supplier)}${bj02InfoRow("Kho nhận", "Kho trung tâm")}${bj02InfoRow("Ngày nhận", formatIsoDate(bj02Header.businessDate))}${bj02ReadOnlyDetail("Chứng từ giao nhận", bj02Header.evidence)}`;
  }
  return `${bj02InfoRow("Chứng từ", selectedDocumentId)}${bj02InfoRow("Nhà cung cấp", documentContext().supplier)}${bj02InfoRow("Kho nhận", "Kho trung tâm")}${bj02InfoRow("Ngày chứng từ", documentContext().documentDate)}${bj02InfoRow("Ngày nhận", formatIsoDate(bj02Header.businessDate))}`;
}
function bj02ReviewIssue(line) {
  const t = lineTotals(line);
  if (line?.status === "NOT_RECEIVED") return { label: "Chưa nhận", tone: "warning" };
  if (line?.status !== "COMPLETED") return { label: "Chưa xong", tone: "warning" };
  if (t.rejected > 0) return { label: "Có từ chối", tone: "error" };
  if (t.damaged > 0) return { label: "Có hàng hỏng", tone: "error" };
  if (t.quarantine > 0) return { label: "Có cách ly", tone: "warning" };
  if (flowMode === "document" && line.remainingReceivableQty != null && t.physicalIncrease > Number(line.remainingReceivableQty || 0)) return { label: "Vượt chứng từ", tone: "warning" };
  if (flowMode === "document" && line.remainingReceivableQty != null && t.physicalIncrease < Number(line.remainingReceivableQty || 0)) return { label: "Nhận một phần", tone: "info" };
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
function bj02ReviewProductBlocks({ interactive = true } = {}) {
  if (!bj02Lines.length) return `<div class="empty-state bj02-review-empty" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("package","icon--empty-media")}</div><h3 data-ds-component="VEmptyTitle">Chưa có hàng để rà soát</h3><p data-ds-component="VEmptyDescription">Hoàn tất hàng thực nhận trước khi sang bước rà soát.</p></div>`;
  return `<div class="bj02-review-summary-list" data-composed-from="DS v2 / List Row,VBadge">${bj02Lines.map((line) => {
    const issue = bj02ReviewIssue(line);
    const attrs = interactive ? `data-bj02-review-line="${line.id}" type="button"` : `type="button" disabled`;
    const badge = issue ? vBadge(issue.label, issue.tone === "error" ? "danger" : issue.tone) : vBadge("Đã xong", "success");
    return `<button class="bj02-review-summary-row" ${attrs} data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="Status" data-ds-prop-density="Compact" data-ds-prop-state="Default"><span class="bj02-review-summary-icon">${icon("package","icon--sm")}</span><span class="bj02-review-summary-copy"><strong>${escapeAttribute(line.name)}</strong><span>${escapeAttribute(bj02ReviewSubtitle(line))}</span></span><span class="bj02-review-summary-status">${badge}</span></button>`;
  }).join("")}</div>`;
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
function render006(state) {
  if (state === "PERMISSION_DENIED") return appShell({ title: "Nhận hàng", body: deniedBody(), centered: true, back: false });
  const body = state === "LOADING" ? loadingBody() : `${stateBanner(state)}<div class="bj02-choice-stack">${bj02ListRow({title:"Nhận theo chứng từ",subtitle:"Đã có chứng từ mua để đối chiếu.",attr:'data-flow="document"',disabled:state==="LOCKED",iconName:"fileText"})}${bj02ListRow({title:"Nhập hàng nhanh",subtitle:"Hàng đã đến, chưa có chứng từ mua.",attr:'data-flow="quick"',disabled:state==="LOCKED",iconName:"zap"})}</div>`;
  return appShell({ title: "Nhận hàng", body, back: false });
}
function render007(state) {
  if (state === "LOADING") return appShell({ title: "Chứng từ chờ nhận", body: loadingBody() });
  if (state === "PERMISSION_DENIED") return appShell({ title: "Chứng từ chờ nhận", body: deniedBody(), centered: true });
  if (state === "EMPTY") return appShell({ title: "Chứng từ chờ nhận", body: emptyBody(false), centered: true });
  const forcedFilterEmpty = state === "FILTER_EMPTY";
  const searchValue = forcedFilterEmpty ? "Không có kết quả" : documentSearchQuery;
  const search = `<div class="bj02-search" data-ds-component="VSearchBar" data-figma-node="522:7245"><span>${icon("search","icon--sm")}</span><input data-bj02-document-search value="${escapeAttribute(searchValue)}" placeholder="Tìm mã chứng từ hoặc nhà cung cấp" aria-label="Tìm chứng từ"/></div>`;
  const cards=[
    {id:"PN-260816-04",supplier:"Minh Dũng",date:"16/08/2026",summary:"2 sản phẩm đang chờ nhận",status:""},
    {id:"PN-260816-05",supplier:"An Việt",date:"16/08/2026",summary:"1 sản phẩm",status:"Đã nhận một phần"}
  ];
  const list=cards.map(x=>bj02RecordCard({title:x.id,supporting1:x.supplier,supporting2:x.summary,summary:x.status||"",timestamp:x.date,attr:`data-bj02-document-id="${x.id}" data-bj02-document-search-text="${escapeAttribute(`${x.id} ${x.supplier}`.toLowerCase())}" ${forcedFilterEmpty?'hidden':''}`})).join("");
  const noResult=`<div class="empty-state document-filter-empty" data-bj02-document-filter-empty data-ds-component="VEmptyState" ${forcedFilterEmpty?"":"hidden"}><div class="icon-box" data-ds-component="VEmptyMedia">${icon("search","icon--empty-media")}</div><h3 data-ds-component="VEmptyTitle">Không có kết quả phù hợp</h3><p data-ds-component="VEmptyDescription">Thử mã chứng từ hoặc tên nhà cung cấp khác.</p></div>`;
  return appShell({title:"Chứng từ chờ nhận",body:`${stateBanner(state)}${search}<div class="bj02-record-stack">${list}</div>${noResult}`});
}
function render008(state) {
  // v3.9.2 semantic baseline. The current product expression is refined by v392-bj02-semantic-hardening.js.
  if (state === "PERMISSION_DENIED") return appShell({ title: "Nhập hàng nhanh", body: deniedBody(), centered: true });
  const locked = state === "LOCKED";
  const supplierValid = supplierCatalog.some((supplier) => supplier.id === bj02Header.supplierId && supplier.name === bj02Header.supplier.trim());
  const evidenceUploaded = Boolean(String(bj02Header.evidence || "").trim());
  const supplierValue = supplierValid ? bj02Header.supplier : "Chọn nhà cung cấp";
  const body = `${stateBanner(state)}<section class="v-section compact-section-heading" data-ds-component="VSection"><div class="v-section-copy"><h2 data-ds-component="VText">Thông tin lần nhận</h2><p data-ds-component="VText">Xác định nhà cung cấp, phạm vi nhận và chứng từ giao nhận.</p></div></section><div class="form-stack quick-source-form">
    <div class="form-field supplier-field${locked ? " is-disabled" : ""}" data-ds-component="VSelect"><label>Nhà cung cấp <span class="required">*</span></label><button class="bj02-vselect-trigger${supplierValid ? " is-filled" : ""}" data-bj02-open-supplier-sheet type="button" ${locked ? "disabled" : ""}><span>${escapeAttribute(supplierValue)}</span>${icon("chevronDown","icon--sm")}</button></div>
    <div class="form-field" data-ds-component="VTextField"><label>Kho nhận</label><span class="input-shell is-readonly"><input value="Kho trung tâm" readonly aria-readonly="true"/></span></div>
    <div class="form-field" data-ds-component="VTextField"><label>Ngày nhận</label><span class="input-shell is-readonly"><input value="${formatIsoDate(bj02Header.businessDate)}" readonly aria-readonly="true"/></span></div>
    <div class="form-field" data-ds-component="VFileDropZone"><label>Chứng từ giao nhận <span class="required">*</span></label><label class="file-drop-zone"><input data-bj02-evidence-file type="file" multiple ${locked ? "disabled" : ""}/><span class="file-drop-icon">${icon("cloudUpload","icon--24")}</span><span class="file-drop-copy"><strong>${evidenceUploaded ? "Đã chọn chứng từ" : "Chọn hoặc kéo tệp"}</strong><small>Phiếu giao hàng, biên bản bàn giao, vận đơn hoặc scan/ảnh rõ nội dung</small></span></label></div>
    ${vBanner("info","Xác nhận quyền sở hữu","Khi tiếp tục, hệ thống lưu ownership assertion theo capability và evidence của lần nhận.","","Compact")}
  </div>${bj02SupplierSelectSheet(locked)}`;
  const disabled = locked || !supplierValid || !evidenceUploaded;
  return appShell({ title: "Nhập hàng nhanh", body, actions: primaryFooter("Xác nhận & tiếp tục", 'data-next="SCR-009"', disabled) });
}

function escapeAttribute(value) {
  return String(value).replaceAll("&", "&amp;").replaceAll('"', "&quot;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
}

function quantitySelector(kind, label, value, disabled = false) {
  return `<label class="quantity-field quantity-field--neutral" data-ds-component="VTextField" data-ds-prop-input-mode="numeric"><span class="quantity-label"><strong>${label}</strong></span><span class="quantity-control"><input data-qty="${kind}" type="number" min="0" step="1" inputmode="numeric" value="${value}" ${disabled ? "disabled" : ""}/></span></label>`;
}

function lotEntry(index, values = {}, { product = documentReceivingProduct(), locked = false, hasLotError = false } = {}) {
  const lotId = values.id || index;
  const defaults = { code: "", expiry: "", accepted: 0, quarantine: 0, damaged: 0, rejected: 0, ...values };
  const disabled = locked ? "disabled" : "";
  const allocated = defaults.accepted + defaults.quarantine + defaults.damaged + defaults.rejected;
  const trackedByLot = product.trackingPolicy === "LOT";
  const revealLotIdentity = trackedByLot && allocated > 0;
  const lotFields = trackedByLot ? `
        <div class="lot-identity-progressive ${revealLotIdentity ? "is-visible" : ""}" data-lot-identity ${revealLotIdentity ? "" : "hidden"}>
          <div class="progressive-divider"></div>
          <p class="progressive-helper">Sản phẩm quản lý theo lô. Bổ sung mã lô${product.expiryRequired ? " và hạn dùng" : ""} cho lượng vừa nhập.</p>
          <div class="lot-meta-grid">
            <div class="form-field" data-ds-component="VTextField" data-figma-node="522:7186" data-ds-prop-label="Mã lô" data-ds-prop-is-required="true"><label for="lot-code-${lotId}">Mã lô <span class="required">*</span></label><span class="input-shell ${hasLotError ? "is-error" : ""}"><input id="lot-code-${lotId}" data-lot-code class="mono" value="${escapeAttribute(defaults.code)}" placeholder="VD: ND2408" ${disabled}/></span></div>
            ${product.expiryRequired ? `<div class="form-field expiry-field" data-ds-component="VDatePicker" data-ds-prop-label="Hạn dùng" data-ds-prop-required="true"><label for="lot-expiry-${lotId}">Hạn dùng <span class="required">*</span></label><span class="input-shell ${hasLotError ? "is-error" : ""}"><input id="lot-expiry-${lotId}" data-lot-expiry class="mono" value="${escapeAttribute(defaults.expiry)}" placeholder="dd/mm/yyyy" inputmode="numeric" ${disabled}/></span></div>` : ""}
          </div>
        </div>` : "";
  return `
    <section class="lot-entry lot-entry--compact" data-lot-entry data-lot-id="${lotId}" data-ds-role="lot-allocation-composition" data-composed-from="VTextField,VDatePicker,VButton">
      <div class="lot-entry-header"><strong>${trackedByLot ? `Phân bổ lô ${index}` : "Số lượng thực nhận"}</strong>${index > 1 && !locked ? `<button class="app-icon-button compact-icon-button" data-action="remove-lot" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.tertiary" data-ds-prop-tone="VComponentTone.danger" type="button" aria-label="Xóa phân bổ lô ${index}">${icon("close", "icon--sm")}</button>` : ""}</div>
      <div class="lot-entry-body">
        <div class="section-label section-label--compact section-label--first"><span>Số lượng & tình trạng</span><span>Đơn vị: ${product.uom}</span></div>
        <div class="quantity-grid">
          ${quantitySelector("accepted", "Đạt", defaults.accepted, locked)}
          ${quantitySelector("quarantine", "Cách ly", defaults.quarantine, locked)}
          ${quantitySelector("damaged", "Hỏng", defaults.damaged, locked)}
          ${quantitySelector("rejected", "Từ chối nhận", defaults.rejected, locked)}
        </div>
        ${lotFields}
        ${hasLotError ? '<span class="field-error">Lô ND2408 đang tồn tại với hạn dùng khác. Đối chiếu nhãn nhà sản xuất trước khi tiếp tục.</span>' : ""}
      </div>
    </section>`;
}

function quickProductById(id) {
  return quickProductCatalog.find((product) => product.id === id) || null;
}

function renderQuickProductDiscovery(locked) {
  const options = quickProductCatalog.map((product) => `
    <button class="combobox-option bj02-search-option" data-product-option="${product.id}" data-product-search-text="${escapeAttribute(`${product.name} ${product.sku}`.toLowerCase())}" data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="Selection" data-ds-prop-density="Default" data-ds-prop-state="Default" type="button" role="option">
      <span class="bj02-search-option-leading">${icon("package", "icon--sm")}</span>
      <span class="combobox-option-copy"><strong>${product.name}</strong><small>${product.sku} · ${product.uom}</small></span><span class="bj02-radio-control" aria-hidden="true"></span>
    </button>`).join("");
  return `
    <section class="product-discovery" data-interaction-phase="PRODUCT_REQUIRED">
      <div class="form-field quick-product-picker combobox-html-renderer" data-ds-component="DS v2 / Search Results Dropdown" data-figma-node="1280:6272" data-ds-prop-value="null" data-ds-prop-label="Sản phẩm" data-ds-prop-hint-text="Tìm tên, SKU hoặc mã vạch" data-ds-prop-tone="VComponentTone.neutral" data-ds-prop-emphasis="VComponentEmphasis.medium" data-ds-prop-state="VComponentState.enabled">
        <label for="quick-product-search">Sản phẩm <span class="required">*</span></label>
        <div class="combobox-anchor ${quickProductMenuOpen ? "is-open" : ""}">
          <input id="quick-product-search" data-product-search autocomplete="off" placeholder="Tìm tên, SKU hoặc mã vạch" aria-label="Sản phẩm" aria-expanded="${quickProductMenuOpen ? "true" : "false"}" ${locked ? "disabled" : ""}/>
          <span class="combobox-trailing">${icon("chevronDown", "icon--sm")}</span>
        </div>
        <div class="combobox-menu ${quickProductMenuOpen ? "is-open" : ""}" data-vcombobox-menu role="listbox" ${quickProductMenuOpen ? "" : "hidden"}>
          ${options}
          <div class="combobox-empty" data-product-empty hidden>Không tìm thấy sản phẩm phù hợp.</div>
        </div>
      </div>
    </section>`;
}

function selectedProductSummary(product, { locked = false, remainingReceivableQty = null } = {}) {
  const productMeta = `${product.sku} · ${product.uom}`;
  const change = flowMode === "quick" && !locked
    ? '<button class="inline-edit product-change-action" data-action="change-product" data-ds-component="VButton" data-ds-prop-label="Đổi" data-ds-prop-variant="VButtonVariant.link" data-ds-prop-size="VButtonSize.small" type="button">Đổi</button>'
    : '';
  const contextLabel = remainingReceivableQty != null ? `Còn ${remainingReceivableQty} ${product.uom}` : 'Đã chọn';
  const row=ds24ContextStatusRow({title:product.name,subtitle:productMeta,label:contextLabel,tone:'Neutral',attrs:'data-ds-role="receiving-product-summary" data-interaction-phase="PRODUCT_CONFIRMED"'});
  return change ? `<section class="bj02-product-summary-composition" data-ds-component="VSection" data-composed-from="DS v2 / List Row,VButton" data-layout-pattern="Compact context row + change action" data-interaction-phase="PRODUCT_CONFIRMED">${row}${change}</section>` : row;
}
function balanceStatusHtml(product, expected = null) {
  const receipt = receiptSummary();
  if (receipt.totalDelivered <= 0) return `<p class="balance-status-text">Nhập số lượng kiểm nhận để tiếp tục.</p>`;
  if (expected != null && receipt.accepted > expected) return vBanner("warning", "Lượng đạt vượt chứng từ", `Lượng đạt ${receipt.accepted} ${product.uom}, vượt ${receipt.accepted - expected} ${product.uom} so với lượng còn được phép nhận. Hồ sơ sẽ được định tuyến phê duyệt.`);
  if (expected != null && receipt.totalDelivered < expected) return `<p class="balance-status-text">Nhận từng phần · đã phân loại ${receipt.totalDelivered} / ${expected} ${product.uom}.</p>`;
  return `<p class="balance-status-text balance-status-text--success">Đã phân loại ${receipt.totalDelivered} ${product.uom} kiểm nhận.</p>`;
}

function renderReceiptBalance(product, expected = null) {
  const receipt = receiptSummary();
  return `<div id="receipt-balance" class="balance-bar balance-bar--interactive" data-ds-role="receiving-balance-summary" data-composed-from="VText,VBanner">
    <div class="summary-row"><span>Tổng kiểm nhận</span><strong data-total-delivered>${receipt.totalDelivered}</strong></div>
    <div class="summary-row"><span>Tăng tồn vật lý</span><strong data-physical-increase>${receipt.physicalIncrease}</strong></div>
    <div class="summary-row"><span>Từ chối nhận</span><strong data-rejected-total>${receipt.rejected}</strong></div>
    <div class="balance-feedback" data-balance-feedback>${balanceStatusHtml(product, expected)}</div>
  </div>`;
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
  if (flowMode !== "document" || !line || line.remainingReceivableQty == null) return null;
  const t = lineTotals(line);
  const allowed = Math.max(0, Number(line.remainingReceivableQty) || 0);
  return {
    allowed,
    totalInspected: t.totalReceived,
    acceptedPhysical: t.physicalIncrease,
    rejected: t.rejected,
    remainingAfterAccepted: Math.max(0, allowed - t.physicalIncrease),
    inspectedOver: Math.max(0, t.totalReceived - allowed),
    acceptedPhysicalOver: Math.max(0, t.physicalIncrease - allowed),
  };
}
function documentVarianceFeedback(line) {
  const v = documentLineVariance(line);
  if (!v || v.totalInspected <= 0) return "";
  if (v.acceptedPhysicalOver > 0) return vBanner("warning", "Lượng vào tồn vượt chứng từ", `Vào tồn vật lý ${v.acceptedPhysical} ${line.uom}, vượt ${v.acceptedPhysicalOver} ${line.uom} so với lượng còn được nhận. Hồ sơ sẽ cần phê duyệt.`);
  if (v.acceptedPhysical < v.allowed) return vBanner("info", "Còn hàng chưa nhận", `Vào tồn vật lý ${v.acceptedPhysical} ${line.uom}; còn ${v.remainingAfterAccepted} ${line.uom} theo chứng từ nguồn.`);
  if (v.inspectedOver > 0 && v.acceptedPhysical <= v.allowed) return vBanner("info", "Có lượng từ chối ngoài số vào tồn", `Tổng kiểm nhận ${v.totalInspected} ${line.uom}; vào tồn vật lý ${v.acceptedPhysical} ${line.uom}. Lượng từ chối không làm tăng tồn.`);
  return "";
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
  const t = lineTotals(line);
  const product = productById(line.productId);
  const uom = product?.uoms?.find((item) => item.id === line.uomId);
  const ratio = Number(line.conversionRatioSnapshot ?? uom?.conversionRatio ?? 1) || 1;
  return t.physicalIncrease * ratio;
}
function documentLineAllowanceBase(line) {
  const product = productById(line.productId);
  const uom = product?.uoms?.find((item) => item.id === line.uomId);
  const ratio = Number(line.conversionRatioSnapshot ?? uom?.conversionRatio ?? 1) || 1;
  return (Number(line.remainingReceivableQty) || 0) * ratio;
}
function bj02RequiresApproval() {
  if (flowMode === "quick") return true;
  return bj02Lines.some((line) => lineAcceptedBase(line) > documentLineAllowanceBase(line));
}
function receiptRiskValue() {
  return bj02Lines.reduce((sum, line) => {
    const acceptedBaseQty = lineAcceptedBase(line);
    const basis = line.priceBasisSnapshot || productById(line.productId)?.priceBasisSnapshot || null;
    const unitPriceVndPerBase = Number(basis?.unitPriceVndPerBase) || 0;
    return sum + acceptedBaseQty * unitPriceVndPerBase;
  }, 0);
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

function render009(state) {
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
function renderActiveLotEditor(lot, index, canRemove = false) {
  const t = lotDraftTotals(lot);
  const expiryRequired = Boolean(lineEditorDraft.expiryRequired);
  const locked = lineEditorIsReadOnly();
  const disabled = locked ? "disabled" : "";
  return `<div class="active-lot-editor" data-ds-role="lot-editor-composition" data-composed-from="VTextField,VDatePicker,VButton">
    <div class="form-stack lot-fields-compact">
      <div class="form-field" data-ds-component="VTextField" data-figma-node="522:7186" data-ds-prop-label="Mã lô" data-ds-prop-is-required="true"><label>Mã lô <span class="required">*</span></label><span class="input-shell"><input data-bj02-lot-field="code" value="${escapeAttribute(lot.code)}" placeholder="Nhập mã trên bao bì" ${disabled}/></span></div>
      <div class="form-field" data-ds-component="VDatePicker" data-ds-prop-label="Hạn dùng" data-ds-prop-required="${expiryRequired}"><label>Hạn dùng ${expiryRequired ? '<span class="required">*</span>' : ""}</label><span class="input-shell bj02-date-shell"><span class="bj02-date-leading">${icon("calendar","icon--sm")}</span><input data-bj02-lot-field="expiry" value="${escapeAttribute(lot.expiry)}" placeholder="dd/mm/yyyy" inputmode="numeric" ${disabled}/></span></div>
      ${lotManufactureExpanded || lot.manufactureDate ? `<div class="form-field" data-ds-component="VDatePicker" data-ds-prop-label="Ngày sản xuất" data-ds-prop-required="false"><label>Ngày sản xuất</label><span class="input-shell bj02-date-shell"><span class="bj02-date-leading">${icon("calendar","icon--sm")}</span><input data-bj02-lot-field="manufactureDate" value="${escapeAttribute(lot.manufactureDate)}" placeholder="dd/mm/yyyy" inputmode="numeric" ${disabled}/></span></div>` : (!locked ? `<button class="button button--tertiary lot-extra-action" data-bj02-action="show-manufacture-date" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.tertiary" data-ds-prop-size="VButtonSize.small" type="button">Thêm ngày sản xuất</button>` : "")}
      <div class="section-label"><span>Phân loại số lượng</span></div>
      ${exceptionQuantitiesEditor("lot", t, locked)}
      ${bj02KeyValueRow("Tổng lô", `${t.totalReceived} ${lineEditorDraft.uom || ""}`, true, "bj02-derived-total")}
      <div class="editor-feedback" data-bj02-quantity-feedback>${quantityFeedback(t)}</div>
      <div class="editor-feedback" data-bj02-lot-identity-feedback>${lotIdentityFeedback(lot)}</div>
      ${canRemove && !locked ? `<button class="button button--tertiary lot-delete-action-inline" data-bj02-action="remove-editor-lot" data-bj02-lot-id="${lot.id}" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.tertiary" data-ds-prop-tone="VComponentTone.danger" data-ds-prop-size="VButtonSize.small" type="button">Xóa lô</button>` : ""}
    </div>
  </div>`;
}
function renderLotLineEditor() {
  if (!lineEditorDraft.lots.length) lineEditorDraft.lots = [emptyLot()];
  const locked = lineEditorIsReadOnly();
  const rows = lineEditorDraft.lots.map((lot, index) => renderLotCompact(lot, index, lot.id === activeLotDraftId)).join("");
  return `<section class="lot-line-editor"><div class="section-label section-label--first lot-section-heading"><span>Các lô thực nhận</span>${flowMode === "document" && lineEditorDraft.remainingReceivableQty != null ? `<small>Còn chờ nhận <strong>${lineEditorDraft.remainingReceivableQty} ${lineEditorDraft.uom}</strong></small>` : ""}</div><div class="lot-accordion-list">${rows}</div>${!locked ? `<button class="button button--secondary button--full add-lot-button" data-bj02-action="add-editor-lot" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.small" type="button">Thêm lô khác</button>` : ""}${lineTotalSummaryHtml(lineEditorDraft)}<div class="editor-feedback document-variance-feedback" data-bj02-document-variance>${documentVarianceFeedback(lineEditorDraft)}</div></section>`;
}
function lineEditorValid() {
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
}

function render084(state) {
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
function render010(state) {
  if (state === "PERMISSION_DENIED") return appShell({ title: "Rà soát nhận hàng", body: deniedBody(), centered: true });
  const pending = state === "PENDING_APPROVAL";
  const approverBlocked = state === "APPROVER_CONFIGURATION_MISSING";
  const requiresApproval = bj02RequiresApproval();
  const noLines = bj02Lines.length === 0;
  const incomplete = !noLines && !allReceiptLinesHandled();
  const disabled = pending || approverBlocked || noLines || incomplete;
  const routeNotice = pending
    ? vBanner("info", "Đã gửi phê duyệt", "Đang chờ người duyệt; tồn kho chưa thay đổi.", "", "Compact")
    : approverBlocked
        ? vBanner("error", "Chưa có người duyệt phù hợp", "Chưa thể tạo phiếu. Cần cấu hình người duyệt đủ quyền và phạm vi rồi gửi lại trong phiên hiện tại.")
        : requiresApproval
          ? flowMode === "quick" ? vBanner("info", "Cần phê duyệt trước khi ghi nhận", "Gửi hồ sơ duyệt; tồn kho chưa thay đổi.", "", "Compact") : vBanner("warning", "Có lượng nhận vượt chứng từ", "Gửi hồ sơ để người có thẩm quyền xem xét. Tồn kho chưa thay đổi.")
          : "";
  const stateNotice = ["PENDING_APPROVAL", "APPROVAL_REQUIRED"].includes(state) ? "" : stateBanner(state);
  const readinessNotice = noLines ? `<div class="empty-state bj02-review-empty" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("package","icon--empty-media")}</div><h3 data-ds-component="VEmptyTitle">Chưa có hàng để rà soát</h3><p data-ds-component="VEmptyDescription">Thêm và hoàn tất hàng thực nhận trước khi tiếp tục.</p></div>` : incomplete ? vBanner("warning", "Còn dòng hàng chưa hoàn tất", "Quay lại Hàng thực nhận để hoàn tất từng sản phẩm.") : "";
  const content = noLines ? readinessNotice : `<section class="bj02-review-section" data-ds-component="VSection"><div class="bj02-section-heading"><strong>Thông tin lần nhận</strong>${pending ? "" : `<button class="inline-edit" data-next="${flowMode === "quick" ? "SCR-008" : "SCR-007"}" data-ds-component="VButton" type="button">Sửa</button>`}</div><div class="bj02-info-stack">${bj02SourceRows()}</div></section><section class="bj02-review-section" data-ds-component="VSection"><div class="bj02-section-heading"><div><strong>Hàng thực nhận</strong><span>${bj02ReviewProductCount()} sản phẩm · ${bj02Lines.length} dòng</span></div>${pending ? "" : '<button class="inline-edit" data-next="SCR-009" data-ds-component="VButton" type="button">Sửa</button>'}</div><div class="bj02-review-products">${bj02ReviewProductBlocks()}</div></section>${incomplete ? readinessNotice : ""}`;
  const body = `${stateNotice}${routeNotice}${content}${bj02ReviewDetailSheet()}`;
  const footer = pending ? "" : primaryFooter(requiresApproval ? "Gửi phê duyệt" : "Xác nhận nhận hàng", 'data-action="submit"', disabled);
  return appShell({ title: "Rà soát nhận hàng", body, actions: footer });
}
function render011(state) {
  if (state === "PERMISSION_DENIED") return appShell({ title: "Phê duyệt yêu cầu nhận hàng", subtitle: "Việc dành cho người phê duyệt", body: deniedBody(), centered: true, backAction: "exit-approval" });
  const disabled = ["SELF_APPROVAL_NOT_ALLOWED", "APPROVAL_ALREADY_DECIDED", "PROCESSING"].includes(state);
  const decided = state === "APPROVAL_ALREADY_DECIDED";
  const financialMasked = state === "FINANCIAL_MASKED";
  const riskValue = receiptRiskValue();
  const noRequest = bj02Lines.length === 0;
  const stateNotice = state === "APPROVAL_REQUIRED" ? "" : stateBanner(state);
  if (noRequest) {
    return appShell({ title: "Phê duyệt yêu cầu nhận hàng", subtitle: "Việc dành cho người phê duyệt", body: `<div class="empty-state" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("inbox","icon--empty-media")}</div><h3 data-ds-component="VEmptyTitle">Không có yêu cầu để duyệt</h3><p data-ds-component="VEmptyDescription">Yêu cầu chỉ xuất hiện sau khi người lập gửi hồ sơ hợp lệ.</p></div>`, centered: true, backAction: "exit-approval" });
  }
  const reasonNotice = !decided ? vBanner(flowMode === "quick" ? "info" : "warning", "Lý do cần duyệt", flowMode === "quick" ? "Nhập hàng nhanh bắt buộc phê duyệt." : "Có lượng Đạt vượt chứng từ nguồn.", "", "Compact") : approvalRejectReason ? vBanner("error", "Đã từ chối", approvalRejectReason) : "";
  const requestFacts = flowMode === "quick" ? `${bj02InfoRow("Người lập", "Nguyễn Văn An · 09:41")}` : `${bj02InfoRow("Người lập", "Nguyễn Văn An · 09:41")}${financialMasked ? bj02InfoRow("Giá trị làm căn cứ duyệt", "Không có quyền xem") : bj02KeyValueRow("Giá trị làm căn cứ duyệt", `${riskValue.toLocaleString("vi-VN")} đ`)}`;
  const body = `${stateNotice}${reasonNotice}<section class="bj02-review-section" data-ds-component="VSection"><div class="bj02-section-heading"><strong>Thông tin lần nhận</strong></div><div class="bj02-info-stack">${bj02SourceRows()}</div></section><section class="bj02-review-section" data-ds-component="VSection"><div class="bj02-section-heading"><strong>Thông tin yêu cầu</strong></div><div class="bj02-info-stack">${requestFacts}</div></section><section class="bj02-review-section" data-ds-component="VSection"><div class="bj02-section-heading"><strong>Hàng thực nhận</strong><span>${bj02ReviewProductCount()} sản phẩm · ${bj02Lines.length} dòng</span></div><div class="bj02-review-products">${bj02ReviewProductBlocks()}</div></section>${bj02ReviewDetailSheet()}`;
  const footer = decided ? "" : `<footer class="app-actions is-split approval-actions figma-sticky-footer" data-ds-component="DS v2 / Sticky Footer" data-ds-prop-layout="Dual" data-ds-prop-tone="Default" data-figma-node="549:927"><button class="button button--secondary" data-action="open-reject" data-ds-component="VButton" type="button" ${disabled ? "disabled" : ""}>Từ chối</button><button class="button button--primary" data-action="approve" data-ds-component="VButton" type="button" ${disabled ? "disabled" : ""}>Duyệt</button></footer>`;
  return appShell({ title: "Phê duyệt yêu cầu nhận hàng", subtitle: "Việc dành cho người phê duyệt · Nguyễn Văn An gửi", body, actions: footer, backAction: "exit-approval" });
}
function render012(state) {
  if (state === "PERMISSION_DENIED") return appShell({ title: "Kết quả nhận hàng", body: deniedBody(), centered: true });
  const processing = state === "PROCESSING";
  const unknown = ["UNKNOWN", "COMMIT_UNKNOWN"].includes(state);
  const rejected = state === "REJECTED_EXECUTION";
  let body = "", footer = "";
  if (processing) {
    body = `<div class="loading-state" data-ds-component="VLoading"><span class="v-loading-spinner"></span><strong>Đang ghi nhận hàng</strong><p>Hệ thống đang xử lý. Bạn không cần thực hiện lại.</p></div>`;
  } else if (unknown) {
    body = `<div class="loading-state" data-ds-component="VLoading"><span class="v-loading-spinner"></span><strong>Đang xác minh kết quả</strong><p>Không thực hiện lại thao tác nhận hàng.</p></div>${vBanner("warning", "Giữ nguyên lần nhận hiện tại", "Hệ thống tiếp tục đối soát kết quả của lần nhận này.")}`;
  } else if (rejected) {
    body = `<div class="empty-state result-empty" data-ds-component="VEmptyState" data-ds-prop-tone="VComponentTone.danger"><div class="result-icon result-icon--danger" data-ds-component="VEmptyMedia" data-ds-prop-icon="VIcons.error">${icon("xCircle", "icon--empty-media")}</div><h2 data-ds-component="VEmptyTitle">Chưa ghi nhận hàng</h2><p data-ds-component="VEmptyDescription">Yêu cầu bị chặn trước khi tồn kho thay đổi.</p></div>`;
  } else {
    const valuationNotice = state === "VALUATION_PENDING_RESULT" ? vBanner("info", "Đang chờ xác nhận giá", "Hàng đạt chưa trở thành khả dụng cho đến khi hoàn tất bước xác nhận giá theo quy định.") : "";
    body = `${resultHero("Đã ghi nhận hàng","Tồn vật lý và thông tin lô đã được cập nhật theo từng sản phẩm.")}<section class="bj02-review-section result-lines-card" data-ds-component="VSection"><div class="bj02-section-heading"><strong>Kết quả theo dòng hàng</strong></div><div class="bj02-review-products">${bj02ReviewProductBlocks({ interactive: false })}</div></section>${valuationNotice}`;
    footer = primaryFooter("Xong", 'data-action="exit-flow"');
  }
  return appShell({ title: "Kết quả nhận hàng", body, actions: footer, centered: rejected });
}
function render013(state) {
  if (state === "LOADING") return appShell({ title: "Đối soát nhận hàng", subtitle: "Tự mở khi kết quả lần nhận chưa xác định", body: loadingBody() });
  if (state === "PERMISSION_DENIED") return appShell({ title: "Đối soát nhận hàng", subtitle: "Tự mở khi kết quả lần nhận chưa xác định", body: deniedBody(), centered: true });
  if (state === "EMPTY") return appShell({ title: "Đối soát nhận hàng", subtitle: "Tự mở khi kết quả lần nhận chưa xác định", body: `<div class="empty-state" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("history", "icon--empty-media")}</div><h3 data-ds-component="VEmptyTitle">Chưa có kết quả mới</h3><p data-ds-component="VEmptyDescription">Hệ thống vẫn đang theo dõi lần nhận này. Bạn không cần tạo lại thao tác.</p></div>`, centered: true });
  const processingUnknown = state === "PROCESSING_OR_UNKNOWN";
  const stale = state === "STALE";
  const terminal = state === "TERMINAL";
  const statusBlock = terminal
    ? vBanner("success", "Đã xác lập kết quả", "Kết quả cuối cùng đã có; hệ thống sẽ đưa bạn về màn kết quả.")
    : `<div class="loading-state loading-state--compact" data-ds-component="VLoading" data-ds-prop-title="Đang xác minh kết quả nhận hàng" data-ds-prop-description="Chưa cần thực hiện lại lần nhận."><span class="v-loading-spinner" data-ds-internal="VLoading.CircularProgressIndicator"></span><strong>Đang xác minh kết quả nhận hàng</strong><p>Chưa cần thực hiện lại lần nhận.</p></div>`;
  const stateNotice = stale ? stateBanner(state) : "";
  const uncertain = processingUnknown || stale;
  const body = `
    ${statusBlock}
    ${stateNotice}
    <div class="as-of" data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall"><span>Lần kiểm tra gần nhất</span><strong class="mono">09:45:18</strong></div>
    <section class="timeline-card" data-ds-component="VSection" data-composed-from="DS v2 / Timeline Item" data-ds-authority="Figma DS v2.0.3">
      <div class="timeline">
        <div class="timeline-item" data-ds-component="DS v2 / Timeline Item" data-figma-node="525:587"><span class="timeline-marker" data-ds-component="VIconBox" data-ds-prop-tone="VComponentTone.neutral">${icon("fileText", "icon--sm")}</span><div class="timeline-content"><strong data-ds-component="VText">Hồ sơ nhận đã được khóa</strong><span>Mã lần nhận REC-260817-04</span><small data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall">09:41:06 · Nguyễn Văn An</small></div></div>
        ${(flowMode === "quick" || bj02RequiresApproval()) ? `<div class="timeline-item" data-ds-component="DS v2 / Timeline Item" data-figma-node="525:587"><span class="timeline-marker" data-ds-component="VIconBox" data-ds-prop-tone="VComponentTone.success">${icon("shield", "icon--sm")}</span><div class="timeline-content"><strong>Yêu cầu đã được duyệt</strong><span>Người duyệt: Trần Minh Hòa</span><small>09:43:22</small></div></div>` : ""}
        <div class="timeline-item ${uncertain ? "is-warning" : ""}" data-ds-component="DS v2 / Timeline Item" data-figma-node="525:587"><span class="timeline-marker" data-ds-component="VIconBox" data-ds-prop-tone="VComponentTone.${uncertain ? "warning" : "success"}">${icon(uncertain ? "clock" : "check", "icon--sm")}</span><div class="timeline-content"><strong>${uncertain ? "Đang xác lập kết quả cuối cùng" : "Kết quả ghi nhận đã được xác lập"}</strong><span>Kết quả của lần nhận hiện tại</span><small>${uncertain ? "Đang tiếp tục kiểm tra" : "09:45:02"}</small></div></div>
        <div class="timeline-item ${uncertain ? "is-warning" : ""}" data-ds-component="DS v2 / Timeline Item" data-figma-node="525:587"><span class="timeline-marker" data-ds-component="VIconBox" data-ds-prop-tone="VComponentTone.${uncertain ? "warning" : "success"}">${icon(uncertain ? "clock" : "package", "icon--sm")}</span><div class="timeline-content"><strong>${uncertain ? "Đang kiểm tra biến động tồn kho" : "Biến động tồn kho đã được ghi"}</strong><span>${bj02Lines.length} dòng hàng trong lần nhận</span><small>${uncertain ? "Không cần tạo lần nhận mới" : "Đã cập nhật tồn"}</small></div></div>
      </div>
    </section>
    ${uncertain ? `<button class="button button--secondary manual-refresh" data-action="refresh" data-ds-component="VButton" data-ds-profile="button.secondary" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.medium" type="button">${icon("rotate", "icon--sm")} Làm mới</button>` : ""}`;
  const footer = processingUnknown ? primaryFooter("Xem hỗ trợ xử lý", 'data-action="handoff"') : "";
  return appShell({ title: "Đối soát nhận hàng", subtitle: "Tự mở khi kết quả lần nhận chưa xác định", body, actions: footer });
}
function esc(v){return String(v??"").replace(/[&<>\"]/g,(m)=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[m]));}
function dsIconForSurface(surface){return {list:"listCheck",form:"edit",detail:"fileText",review:"shield",result:"checkCircle",timeline:"history",dashboard:"layers",choice:"listCheck"}[surface]||"info";}
function genericFieldRows(screen){
  const rows=(screen.dataRows?.length?screen.dataRows:(screen.fields||[]).map((x)=>({label:x[0],example:x[1],ownership:"DERIVED"})));
  if(!rows.length) return "";
  if(screen.surface==="form") return `<section class="generic-form-section v-section" data-ds-component="VSection">${rows.map((r,i)=>{const comp=(r.component||(/(ngày|hạn|cut-off|kỳ)/i.test(r.label)?"VDatePicker":/(số tiền|giá trị|giá trước)/i.test(r.label)?"VMoneyField":/(số lượng|lượng |ngưỡng|mức tồn|số ngày)/i.test(r.label)?"VNumberField":/(trạng thái|loại|hành động|lý do|nguồn|phạm vi|định dạng|kho)/i.test(r.label)?"VSelect":"VTextFormField")); return `<label class="generic-field" data-ds-component="${comp}" data-ds-prop-label="${esc(r.label)}"><span>${esc(r.label)}</span><div class="generic-input">${esc(r.example||"Nhập dữ liệu")}</div></label>`}).join("")}</section>`;
  return `<div class="generic-kv-card" data-ds-component="VSection" data-composed-from="DS v2 / Info Row">${rows.map((r)=>`<div class="generic-kv-row" data-ds-component="DS v2 / Info Row" data-figma-node="525:351"><span data-ds-component="VText">${esc(r.label)}</span><strong data-ds-component="VText">${esc(r.example||"—")}</strong></div>`).join("")}</div>`;
}
function genericCards(screen){
  const cards=screen.cards||[]; if(!cards.length) return "";
  if(screen.surface==="timeline") return `<div class="generic-timeline" data-theme-component="Theme7EvidenceTimeline" data-composed-from="VCard,VIconBox,VText,VBadge">${cards.map((c,i)=>`<div class="timeline-event"><span class="timeline-dot" data-ds-component="VIconBox">${icon(i===cards.length-1?"checkCircle":"fileText","icon--sm")}</span><div class="timeline-copy"><strong data-ds-component="VText">${esc(c[0])}</strong><span data-ds-component="VText">${esc(c[1]||"")}</span>${c[2]?vBadge(esc(c[2]),i===cards.length-1?"success":"info"):""}</div></div>`).join("")}</div>`;
  return `<div class="generic-card-list">${cards.map((c)=>`<article class="generic-data-card" data-ds-component="${screen.surface==="list"?"DS v2 / List Row":"VSection"}" ${screen.surface==="list"?'data-figma-node="525:519" data-ds-prop-type="Navigation"':'data-composed-from="DS v2 / Info Row,VBadge"'}><div class="generic-card-icon" data-ds-component="VCardIcon">${icon(dsIconForSurface(screen.surface),"icon--sm")}</div><div class="generic-card-copy"><strong data-ds-component="VCardTitle">${esc(c[0])}</strong><span data-ds-component="VText">${esc(c[1]||"")}</span></div>${c[2]?vBadge(esc(c[2]),/lỗi|block|thiếu|unknown|hết/i.test(c[2])?"warning":"info"):""}${screen.surface==="list"?icon("chevronRight","icon--sm"):""}</article>`).join("")}</div>`;
}
function genericPrimaryActions(screen,state){
  if(state==="PERMISSION_DENIED") return "";
  const acts=screen.actions||[]; if(!acts.length){
    if(screen.surface==="result") return primaryFooter("Xong",'data-generic-next',false);
    return "";
  }
  const primary=acts[0]; return primaryFooter(esc(primary.label),'data-generic-action="'+esc(primary.id)+'"',false,primary.tone==="danger"?"danger":"primary");
}
function genericStateContent(screen,state){
  if(state==="PERMISSION_DENIED") return deniedBody();
  if(state==="LOADING"||state==="CALCULATING"||state==="REBUILDING"||state==="PREPARING"||state==="PROCESSING"){
    if(screen.surface==="result") return `<div class="generic-result-center" data-theme-component="Theme7OperationResult"><div class="generic-spinner" data-ds-component="VLoading"></div><h3 data-ds-component="VText">Đang xử lý</h3><p data-ds-component="VText">Giữ nguyên ngữ cảnh. Bạn không cần gửi lại thao tác.</p></div>`;
    return loadingBody();
  }
  if(state.includes("EMPTY")) return `<div class="empty-state" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("inbox")}</div><h3 data-ds-component="VEmptyTitle">Chưa có dữ liệu</h3><p data-ds-component="VEmptyDescription">Không có mục phù hợp trong phạm vi hiện tại.</p></div>`;
  if(screen.surface==="result" && /(COMPLETED|PUBLISHED|RESOLVED|ACTIVE_RECONCILED)/.test(state)) return `<div class="generic-result-center" data-theme-component="Theme7OperationResult" data-ds-component="VSection" data-composed-from="VIcon,VText,DS v2 / Info Row,VBanner">${resultHero("Đã xác lập kết quả","Kết quả chính thức đã sẵn sàng.")}${genericFieldRows(screen)}${genericCards(screen)}</div>`;
  if(screen.surface==="result" && /(UNKNOWN|COMMIT_UNKNOWN)/.test(state)) return `<div class="generic-result-center" data-theme-component="Theme7OperationResult">${vBanner("warning","Kết quả chưa xác định","Hệ thống tiếp tục xác minh chính lần xử lý này; không tạo thao tác mới.")}${genericFieldRows(screen)}</div>`;
  let notice=screen.notice? vBanner("info","Lưu ý",esc(screen.notice)):"";
  let stateNote="";
  if(/ERROR|FAILED|CONFLICT|BLOCK|LOCKED|STALE|MISSING|EXPIRED/.test(state)) stateNote=stateBanner(state)||vBanner("warning","Cần kiểm tra",`Cần xử lý điều kiện hiện tại trước khi tiếp tục.`);
  if(/APPROVAL/.test(state)) stateNote=stateBanner(state)||vBanner("info","Đang chờ phê duyệt","Chưa có tác động cuối cho đến khi có quyết định hợp lệ.");
  const intro=`<section class="v-section generic-intro" data-ds-component="VSection"><span class="eyebrow">${esc(activeFlowId)} · ${esc(screen.surface)}</span><h2 data-ds-component="VText">${esc(screen.name)}</h2><p data-ds-component="VText">${esc(screen.purpose)}</p></section>`;
  return intro+stateNote+notice+genericCards(screen)+genericFieldRows(screen);
}
function renderGeneric(screen,state){
  let body=genericStateContent(screen,state);
  if(screen.id==="SCR-044") body=`${vBanner("info","Đếm mù đang bật","Số lượng sổ sách không được tải vào DOM trước khi bạn gửi lần đếm đầu tiên.")}${body}`;
  return appShell({title:screen.name,body,actions:genericPrimaryActions(screen,state),back:!activeFlow()?.entry.includes(screen.id),centered:state==="PERMISSION_DENIED"});
}

function bj01ProductById(id) { return bj01Products.find((p)=>p.id===id) || bj01Products[0]; }
function bj01Indicators(p) {
  const out=[];
  const configured=p.monitoringConfigStatus!=="NOT_CONFIGURED";
  if(p.available===0) out.push({key:"OUT",label:"Hết hàng",scope:"PRODUCT"});
  if((p.lots||[]).some((l)=>l.expiryIndicator==="EXPIRED")) out.push({key:"EXPIRED",label:"Có lô hết hạn",scope:"LOT"});
  if(configured && p.available>0 && p.threshold!=null && p.available<=p.threshold) out.push({key:"LOW",label:"Tồn thấp",scope:"PRODUCT"});
  if((p.lots||[]).some((l)=>l.expiryIndicator==="NEAR_EXPIRY")) out.push({key:"NEAR",label:"Có lô cận hạn",scope:"LOT"});
  if(!configured) out.push({key:"NOT_CONFIGURED",label:"Chưa có ngưỡng tồn",scope:"MONITORING"});
  return out;
}
function bj01MatchesFilter(p) { return bj01Filter==="ALL" || bj01Indicators(p).some((x)=>x.key===bj01Filter); }
function bj01SearchText(p) { return `${p.name} ${p.code} ${p.barcode || ""}`.toLocaleLowerCase("vi"); }
function bj01MatchesSearch(p) { const q=bj01Query.trim().toLocaleLowerCase("vi"); return !q || bj01SearchText(p).includes(q); }
function bj01AsOf() { return bj01QueryAsOf; }
function ds24Badge(label,tone="Neutral") {
  const t=String(tone).toLowerCase();
  return `<span class="ds24-badge ds24-badge--${t}" data-ds-component="VBadge" data-figma-node="525:309" data-ds-prop-style="Soft" data-ds-prop-tone="${tone}">${esc(label)}</span>`;
}
function ds24Chip(key,label,selected,attrName) {
  return `<button class="ds24-chip${selected?' is-selected':''}" type="button" ${attrName}="${escapeAttribute(key)}" data-ds-component="VChip" data-figma-node="522:7449" data-ds-prop-state="Default" data-ds-prop-tone="${selected?'Brand':'Neutral'}">${esc(label)}</button>`;
}
function ds24Search(value,attrs,placeholder="Tìm kiếm") {
  return `<div class="ds24-search-header" data-ds-component="DS v2 / Search & Filter Header" data-figma-node="547:2306" data-ds-prop-layout="Search"><label class="ds24-search" data-ds-component="VSearchBar" data-figma-node="522:7245" data-ds-prop-state="Default">${icon("search")}<input ${attrs} value="${escapeAttribute(value)}" placeholder="${escapeAttribute(placeholder)}" aria-label="${escapeAttribute(placeholder)}"></label></div>`;
}
function ds24ListRow({title,subtitle="",trailing="",leading="package",attrs="",type="Navigation",theme="",state="Default",density="Default",interactive=null,disabled=false,extraClass=""}) {
  const isInteractive=interactive==null ? type!=="Status" : Boolean(interactive);
  const tag=isInteractive?"button":"div";
  const effectiveState=disabled||state==="Disabled"?"Disabled":state;
  const disabledAttrs=effectiveState==="Disabled" ? (isInteractive?' disabled aria-disabled="true"':' aria-disabled="true"') : "";
  const buttonType=isInteractive?' type="button"':'';
  const hasLeading=Boolean(leading);
  const leadingHtml=hasLeading?icon(leading,"ds24-list-row__leading"):"";
  return `<${tag} class="ds24-list-row${hasLeading?'':' ds24-list-row--no-leading'}${extraClass?` ${extraClass}`:''}"${buttonType} ${attrs}${disabledAttrs} data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="${type}" data-ds-prop-state="${effectiveState}" data-ds-prop-density="${density}" data-ds-prop-leading="${hasLeading?'Visible':'Hidden'}" ${theme?`data-theme-component="${theme}"`:''}>${leadingHtml}<span class="ds24-list-row__copy"><strong>${esc(title)}</strong><small>${esc(subtitle)}</small></span><span class="ds24-list-row__trailing">${trailing}${type==="Navigation"?icon("chevronRight","icon--sm"):''}</span></${tag}>`;
}
function ds24ContextStatusRow({title,subtitle="",label,tone="Neutral",leading="package",attrs=""}) {
  return ds24ListRow({title,subtitle,trailing:ds24Badge(label,tone),leading,attrs,type:"Status",density:"Compact",state:"Default",interactive:false});
}
function ds24InfoRow(label,value,extra="") {
  return `<div class="ds24-info-row ${extra}" data-ds-component="DS v2 / Info Row" data-figma-node="525:351"><span>${esc(label)}</span><strong>${esc(value)}</strong></div>`;
}
function ds24KeyValueRow(label,value,emphasis=false,valueAttrs="") {
  return `<div class="ds24-key-value-row${emphasis?' ds24-key-value-row--emphasis':''}" data-ds-component="DS v2 / Key-value Row" data-figma-node="525:358" data-ds-prop-state="${emphasis?'Emphasis':'Default'}"><span>${esc(label)}</span><strong ${valueAttrs}>${esc(value)}</strong></div>`;
}
function ds24InfoGroup(title,rows,extraClass="") {
  return `<section class="ds24-info-group ${extraClass}" data-composed-from="DS v2 / Info Row">${title?`<h2 class="ds24-info-group__title">${esc(title)}</h2>`:""}<div class="ds24-info-group__rows">${rows}</div></section>`;
}
function ds24GroupedCollection(content,extraClass="",composedFrom="") {
  const from=composedFrom||"DS v2 / List Row";
  return `<section class="ds24-grouped-collection ${extraClass}" data-layout-pattern="Grouped surface" data-figma-reference="4518:1545" data-composed-from="${escapeAttribute(from)}">${content}</section>`;
}
function ds24SummaryCard(title,body,extra="") {
  return `<section class="ds24-summary-card" data-ds-component="DS v2 / Summary Card" data-figma-node="525:552" data-ds-prop-tone="Neutral" ${extra}><h2 class="ds24-summary-card__title">${esc(title)}</h2><p class="ds24-summary-card__body">${esc(body)}</p></section>`;
}
function bj01AvailabilityRows(p,{showAvailable=true}={}) {
  const unit=esc(p.stockUom);
  const reasons=(p.eligibilityBreakdown||[]).filter((x)=>Number(x.quantity)>0);
  const reasonRows=reasons.length?`<div class="bj01-eligibility-reasons" data-composed-from="DS v2 / Key-value Row">${reasons.map((x)=>ds24KeyValueRow(x.reason,`${x.quantity} ${unit}`)).join('')}</div>`:"";
  return `<section class="ds24-availability${showAvailable?'':' ds24-availability--supporting'}" data-composed-from="DS v2 / Key-value Row">${showAvailable?ds24KeyValueRow('Khả dụng',`${p.available} ${unit}`,true):''}<div class="ds24-key-value-stack">${ds24KeyValueRow('Tồn vật lý',`${p.physical} ${unit}`)}${ds24KeyValueRow('Đủ điều kiện bán',`${p.eligible} ${unit}`)}${ds24KeyValueRow('Đã giữ',`${p.reserved} ${unit}`)}</div>${reasons.length?`${ds24SectionTitle('Không đủ điều kiện bán')}${reasonRows}`:''}</section>`;
}
function bj01LotQuantityRows(lot,p) {
  const unit=esc(p.stockUom);
  return `<section class="ds24-availability ds24-availability--supporting" data-composed-from="DS v2 / Key-value Row"><div class="ds24-key-value-stack">${ds24KeyValueRow('Tồn vật lý',`${lot.physical} ${unit}`)}${ds24KeyValueRow('Đủ điều kiện bán',`${lot.eligible} ${unit}`)}</div></section>`;
}
function ds24SectionTitle(title,meta="") { return `<div class="ds24-section-title"><h2 class="vet45-text-style-5">${esc(title)}</h2>${meta?`<span class="vet45-text-style-11">${esc(meta)}</span>`:''}</div>`; }
function bj01Context() { return `<p class="ds24-context vet45-text-style-7" data-ds-component="VText" data-ds-prop-style="Body/Small">Kho trung tâm · Dữ liệu đến ${esc(bj01AsOf()).replace(" · ", ", ")}</p>`; }
function bj01PrimaryAttention(p) {
  const all=bj01Indicators(p);
  if(bj01Filter!=="ALL") return all.find((x)=>x.key===bj01Filter) || all.find((x)=>x.key==="NOT_CONFIGURED") || null;
  const priority=["OUT","EXPIRED","LOW","NEAR","NOT_CONFIGURED"];
  return priority.map((k)=>all.find((x)=>x.key===k)).find(Boolean)||null;
}
function bj01RowSubtitle(p) {
  const issue=bj01PrimaryAttention(p);
  return `${p.available} ${p.stockUom} khả dụng${issue ? ` · ${issue.label}` : ""}`;
}
function bj01SearchAndFilters() {
  const filters=[['ALL','Tất cả'],['OUT','Hết hàng'],['LOW','Tồn thấp'],['NEAR','Cận hạn'],['EXPIRED','Hết hạn']];
  return `${ds24Search(bj01Query,'data-bj01-search','Tên, mã sản phẩm hoặc mã vạch')}<div class="ds24-chip-scroll" aria-label="Lọc tồn kho" data-composed-from="VChip">${filters.map(([k,l])=>ds24Chip(k,l,bj01Filter===k,'data-bj01-filter')).join('')}</div>`;
}
function bj01Empty(filtered=true) {
  return `<div class="ds24-empty" data-ds-component="VEmptyState"><div class="ds24-empty__media" data-ds-component="VEmptyMedia">${icon(filtered?'search':'inbox')}</div><h3 class="vet45-text-style-5" data-ds-component="VEmptyTitle">${filtered?'Không có kết quả phù hợp':'Chưa có dữ liệu tồn kho'}</h3><p class="vet45-text-style-6" data-ds-component="VEmptyDescription">${filtered?'Thử tên, mã sản phẩm hoặc chọn bộ lọc khác.':'Không có dữ liệu trong kho hiện tại.'}</p>${filtered?`<button class="ds24-button ds24-button--secondary" data-bj01-clear type="button" data-ds-component="VButton" data-figma-node="521:529">Xóa tìm kiếm và bộ lọc</button>`:''}</div>`;
}
function render001BJ01(state) {
  if(state==="PERMISSION_DENIED") return appShell({title:"Tồn kho",body:deniedBody(),centered:true,back:false});
  if(state==="LOADING") return appShell({title:"Tồn kho",body:bj01Context()+loadingBody(),back:false});
  const stale=state==="STALE"?`${vBanner("warning","Dữ liệu có thể đã cũ","Hãy làm mới trước khi sử dụng.")}<button class="ds24-button ds24-button--secondary ds24-inline-action" data-bj01-refresh type="button" data-ds-component="VButton" data-figma-node="521:529">${icon('rotate','icon--sm')}Làm mới</button>`:"";
  const visible=state==="EMPTY"||state==="FILTER_EMPTY"?[]:bj01Products.filter((p)=>bj01MatchesFilter(p)&&bj01MatchesSearch(p));
  const empty=state==="EMPTY"?bj01Empty(false):(!visible.length?bj01Empty(true):"");
  const rows=visible.map((p)=>ds24ListRow({title:`${p.name} · ${p.code}`,subtitle:bj01RowSubtitle(p),attrs:`data-bj01-product="${p.id}" data-bj01-search-text="${escapeAttribute(bj01SearchText(p))}"`,})).join('');
  const body=`${bj01Context()}${stale}${bj01SearchAndFilters()}${rows?`<section class="ds24-list-stack" data-composed-from="DS v2 / List Row">${rows}</section>`:''}${empty}`;
  return appShell({title:"Tồn kho",body,back:false});
}
function bj01AttentionBanner(p) {
  const item=bj01Indicators(p).find((x)=>x.key==="OUT") || bj01Indicators(p).find((x)=>x.key==="LOW");
  if(!item) return "";
  if(item.key==="OUT") {
    const desc=p.target!=null?`Khả dụng 0 ${esc(p.stockUom)}. Gợi ý bổ sung: ${Math.max(0,p.target-p.available)} ${esc(p.stockUom)} để đạt mức mục tiêu ${p.target} ${esc(p.stockUom)}.`:`Khả dụng 0 ${esc(p.stockUom)}${p.threshold!=null?` · Ngưỡng ${p.threshold} ${esc(p.stockUom)}.`:''}`;
    return vBanner("error","Hết hàng",desc);
  }
  const parts=[`Khả dụng ${p.available} ${esc(p.stockUom)}${p.threshold!=null?` · Ngưỡng ${p.threshold} ${esc(p.stockUom)}.`:''}`];
  if(p.target!=null&&p.target>p.available) parts.push(`Gợi ý bổ sung: ${p.target-p.available} ${esc(p.stockUom)} để đạt mức mục tiêu ${p.target} ${esc(p.stockUom)}.`);
  return vBanner("warning","Tồn thấp",parts.join(' '));
}
function bj01LotBadge(lot) { return lot.expiryIndicator==='NEAR_EXPIRY'?ds24Badge('Cận hạn','Warning'):lot.expiryIndicator==='EXPIRED'?ds24Badge('Hết hạn','Danger'):''; }
function ds24Sheet({title,body,attrs=""}) {
  return `<div class="sheet-backdrop ds24-overlay" ${attrs}><section class="ds24-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" data-ds-prop-show-title="true" data-ds-prop-title="${escapeAttribute(title)}" role="dialog" aria-modal="true"><div class="ds24-sheet__handle" data-ds-internal="VBottomSheet.handle"></div><h3 class="vet45-text-style-4" data-ds-internal="VBottomSheet.title">${esc(title)}</h3><div class="ds24-sheet__body" data-ds-internal="VBottomSheet.content">${body}</div></section></div>`;
}
function bj01LotSheet(p) {
  if(!bj01LotOpen) return ""; const lot=(p.lots||[]).find((x)=>x.code===bj01SelectedLotCode)||p.lots?.[0]; if(!lot)return "";
  let status="";
  if(lot.expiryIndicator==='EXPIRED') status=vBanner('error','Hết hạn','Lượng của lô này không đủ điều kiện bán.');
  else if(lot.expiryIndicator==='NEAR_EXPIRY'&&lot.nearExpiryAction==='BLOCK_SALE') status=vBanner('warning','Cận hạn · Đã chặn bán','Lượng của lô này không tính vào khả dụng theo chính sách hiện tại.');
  else if(lot.expiryIndicator==='NEAR_EXPIRY') status=vBanner('warning','Cận hạn',`${lot.daysToExpiry!=null?`Còn ${lot.daysToExpiry} ngày · `:''}vẫn đủ điều kiện bán theo chính sách hiện tại.`);
  return ds24Sheet({title:`Lô ${lot.code}`,attrs:'data-bj01-close-lot',body:`<p class="ds24-context vet45-text-style-7">${esc(p.name)} · HSD ${esc(lot.expiryDisplay)}</p>${bj01LotQuantityRows(lot,p)}${status}`});
}
function bj01ProvenanceSheet(p) {
  if(!bj01ProvenanceOpen)return "";
  const mv=p.latestPhysicalMovement||{}; const rs=p.reservationSummary||{};
  const movementValue=mv.source?`${mv.source} · ${Number(mv.delta)>0?'+':''}${mv.delta} ${p.stockUom}`:'Chưa có biến động';
  const reservationValue=Number(rs.quantity)>0?`${rs.quantity} ${p.stockUom}${rs.source?` · ${rs.source}`:''}`:`0 ${p.stockUom}`;
  return ds24Sheet({title:'Nguồn và thời điểm cập nhật',attrs:'data-bj01-close-provenance',body:`<p class="ds24-context vet45-text-style-7">${esc(p.name)} · Kho trung tâm</p><div class="ds24-info-stack">${ds24InfoRow('Dữ liệu đến',bj01AsOf())}${ds24InfoRow(mv.label?`${mv.label} gần nhất`:'Biến động gần nhất',movementValue)}${ds24InfoRow('Đang giữ',reservationValue)}</div><button class="ds24-button ds24-button--secondary" data-bj01-handoff type="button" data-ds-component="VButton" data-figma-node="521:529">${icon('history','icon--sm')}Xem thẻ kho và lịch sử</button>`});
}
function render003BJ01(state) {
  const entrySubtitle=entryMode==="product-context"?"Từ ngữ cảnh sản phẩm · Kho trung tâm":null;
  const entryBack=entryMode==="product-context"?"exit-inventory-product-context":"";
  if(state==="PERMISSION_DENIED") return appShell({title:"Chi tiết tồn kho",subtitle:entrySubtitle,body:deniedBody(),centered:true,back:true,backAction:entryBack});
  if(state==="LOADING") return appShell({title:"Chi tiết tồn kho",subtitle:entrySubtitle,body:loadingBody(),back:true,backAction:entryBack});
  const p=bj01ProductById(bj01SelectedProductId);
  const stale=state==="STALE"?`${vBanner("warning","Dữ liệu có thể đã cũ",`Dữ liệu đến ${esc(bj01AsOf())}. Hãy làm mới trước khi sử dụng.`)}<button class="ds24-button ds24-button--secondary ds24-inline-action" data-bj01-refresh type="button" data-ds-component="VButton" data-figma-node="521:529">${icon('rotate','icon--sm')}Làm mới</button>`:"";
  const productContext=ds24ListRow({title:p.name,subtitle:`${p.code} · ${p.stockUom}`,leading:'package',type:'Status',interactive:false,density:'Compact',attrs:'data-ds-role="inventory-product-summary"'});
  const configNote=p.monitoringConfigStatus==='NOT_CONFIGURED'?`<p class="ds24-context bj01-config-note" data-ds-component="VText">Chưa cấu hình ngưỡng tồn; chưa thể xác định trạng thái tồn thấp/bình thường.</p>`:"";
  let body=`${bj01Context()}${stale}${productContext}${bj01AvailabilityRows(p)}${configNote}${bj01AttentionBanner(p)}`;
  if(p.tracking==='LOT') {
    const lots=p.lots.map((lot)=>{const issue=lot.expiryIndicator==='NEAR_EXPIRY'?' · Cận hạn':lot.expiryIndicator==='EXPIRED'?' · Hết hạn':'';return ds24ListRow({title:`Lô ${lot.code}`,subtitle:`HSD ${lot.expiryDisplay} · Tồn ${lot.physical} ${p.stockUom}${issue}`,leading:null,attrs:`data-bj01-lot="${escapeAttribute(lot.code)}"`,});}).join('');
    body+=`<section class="ds24-section">${ds24SectionTitle('Lô và hạn dùng',`${p.lots.length} lô`)}<div class="ds24-list-stack">${lots}</div></section>`;
  }
  body+=`<section class="ds24-section">${ds24ListRow({title:'Nguồn và thời điểm cập nhật',subtitle:'Xem nguồn số liệu và lịch sử',leading:'history',attrs:'data-bj01-provenance',})}</section>${bj01LotSheet(p)}${bj01ProvenanceSheet(p)}`;
  return appShell({title:"Chi tiết tồn kho",subtitle:entrySubtitle,body,back:true,backAction:entryBack});
}
function render004BJ01(state) { bj01LotOpen=true; return render003BJ01(state==="PERMISSION_DENIED"?state:state==="LOADING"?state:"READY"); }


// ============================================================================
// Inventory Operations legacy renderers under Figma-DS migration — UIF-05 deep-corrected in v1.3.7; UIF-06 deep-corrected in v1.3.8; other Inventory Operations renderers retain their prior baseline.
// These renderers apply Phase-A readiness decisions and stay isolated by active UIF.
// ============================================================================
const io04Fixture={order:"SO-260827-18",warehouse:"Kho chính",source:"Đơn bán đã xác nhận",lines:[
  {name:"Nobivac DHPPi",code:"SP-000184",uom:"hộp",need:20,reserved:20,shortage:0},
  {name:"Amox 500",code:"SP-000066",uom:"hộp",need:50,reserved:42,shortage:8},
]};
const IO05_ACTOR={id:"USR-WH-001",name:"Nguyễn Văn An"};
const io05Orders=[
  {id:"SO-260827-21",customer:"Đại lý An Phú",warehouse:"Kho chính",queue:"ACTIONABLE",partialHandoverAllowed:true,partialPolicyVersion:"FUL-POL-v3",fulfillmentVersion:7,sourceVersion:7,allocationSetId:"AS-21",allocationVersion:4,closed:false,status:"Cần lấy hàng",shortage:0,operationId:"IO-HO-SO26082721-01",lines:[
    {id:"PK-21-01",name:"Nobivac DHPPi",code:"SP-000184",uom:"hộp",baseUom:"hộp",conversionToBase:1,conversionVersion:"UOM-SP000184-v2",quantityStep:1,requestedQty:20,deliveredQty:0,allocations:[
      {id:"AL-21-01",allocatedQty:4,allocatedBaseQty:4,pickedQty:4,consumedQty:0,suggestedLot:"DH2507",lot:"DH2507",overrideReason:"",physicalCorrection:null,eligibleLots:[
        {code:"DH2507",expiryDisplay:"30/06/2027",expiryPrecision:"DAY",pickableQty:4,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v12",recommended:true},
        {code:"DH2509",expiryDisplay:"09/2027",expiryPrecision:"MONTH",pickableQty:18,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v12",recommended:false},
        {code:"DH2511",expiryDisplay:"2027",expiryPrecision:"YEAR",pickableQty:22,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v12",recommended:false}
      ]},
      {id:"AL-21-02",allocatedQty:16,allocatedBaseQty:16,pickedQty:8,consumedQty:0,suggestedLot:"DH2509",lot:"DH2509",overrideReason:"",physicalCorrection:null,eligibleLots:[
        {code:"DH2509",expiryDisplay:"09/2027",expiryPrecision:"MONTH",pickableQty:18,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v12",recommended:true},
        {code:"DH2511",expiryDisplay:"2027",expiryPrecision:"YEAR",pickableQty:22,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v12",recommended:false}
      ]}
    ]},
    {id:"PK-21-02",name:"Găng tay khám Nitrile",code:"SP-000271",uom:"hộp",baseUom:"hộp",conversionToBase:1,conversionVersion:"UOM-SP000271-v1",quantityStep:1,requestedQty:6,deliveredQty:0,allocations:[
      {id:"AL-21-03",allocatedQty:6,allocatedBaseQty:6,pickedQty:0,consumedQty:0,suggestedLot:null,lot:null,overrideReason:"",physicalCorrection:null,eligibleLots:[]}
    ]}
  ]},
  {id:"SO-260827-24",customer:"Phòng khám Minh Tâm",warehouse:"Kho chính",queue:"WAITING",partialHandoverAllowed:false,partialPolicyVersion:"FUL-POL-v3",fulfillmentVersion:3,sourceVersion:3,allocationSetId:"AS-24",allocationVersion:2,closed:false,status:"Chờ đơn bán xử lý",shortage:8,operationId:"IO-HO-SO26082724-01",lines:[
    {id:"PK-24-01",name:"Amox 500",code:"SP-000066",uom:"hộp",baseUom:"hộp",conversionToBase:1,conversionVersion:"UOM-SP000066-v1",quantityStep:1,requestedQty:50,deliveredQty:0,allocations:[
      {id:"AL-24-01",allocatedQty:42,allocatedBaseQty:42,pickedQty:0,consumedQty:0,suggestedLot:"AM2508",lot:"AM2508",overrideReason:"",physicalCorrection:null,eligibleLots:[{code:"AM2508",expiryDisplay:"08/2027",expiryPrecision:"MONTH",pickableQty:42,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v9",recommended:true}]}
    ]},
    {id:"PK-24-02",name:"Vitamin ADE",code:"SP-000099",uom:"chai",baseUom:"chai",conversionToBase:1,conversionVersion:"UOM-SP000099-v1",quantityStep:0.5,requestedQty:10,deliveredQty:0,allocations:[
      {id:"AL-24-02",allocatedQty:10,allocatedBaseQty:10,pickedQty:0,consumedQty:0,suggestedLot:null,lot:null,overrideReason:"",physicalCorrection:null,eligibleLots:[]}
    ]}
  ]}
];
let io05SelectedOrderId="SO-260827-21", io05QueueFilter="ALL", io05Query="";
let io05ActiveLineId="PK-21-01", io05ActiveAllocationId="AL-21-01", io05OverrideOpen=false, io05OverrideLot="", io05OverrideReason="";
let io05PickEditorOpen=false, io05PickDraft="";
let io05HandoverByAllocation={}, io05LastResult=null, io05StaleAppliedForOrder={};
function io05CurrentOrder(){return io05Orders.find(o=>o.id===io05SelectedOrderId)||io05Orders.find(o=>!o.closed)||io05Orders[0];}
function io05CurrentLines(){return io05CurrentOrder()?.lines||[];}
function io05LineRequested(line){return Number(line?.requestedQty||0);}
function io05LineDelivered(line){return Number(line?.deliveredQty||0);}
function io05LineRemaining(line){return Math.max(0,io05LineRequested(line)-io05LineDelivered(line));}
function io05AllocationRemainingPicked(a){return Math.max(0,Number(a?.pickedQty||0)-Number(a?.consumedQty||0));}
function io05LinePicked(line){return (line.allocations||[]).reduce((sum,a)=>sum+io05AllocationRemainingPicked(a),0);}
function io05LinePickedCumulative(line){return (line.allocations||[]).reduce((sum,a)=>sum+Number(a.pickedQty||0),0);}
function io05LineAllocated(line){return (line.allocations||[]).reduce((sum,a)=>sum+Number(a.allocatedQty||0),0);}
function io05OrderPickedTotal(order=io05CurrentOrder()){return (order?.lines||[]).reduce((s,l)=>s+io05LinePicked(l),0);}
function io05OrderRemainingTotal(order=io05CurrentOrder()){return (order?.lines||[]).reduce((s,l)=>s+io05LineRemaining(l),0);}
function io05LineStatus(line){const ready=io05LinePicked(line),remaining=io05LineRemaining(line);if(remaining<=0)return {label:"Đã bàn giao",tone:"success"};return ready<=0?{label:"Chưa lấy",tone:"neutral"}:ready<remaining?{label:"Đã lấy một phần",tone:"warning"}:{label:"Đã lấy đủ",tone:"success"};}
function io05OrderStatus(order){
  if(order.closed)return {label:"Đã bàn giao",tone:"success"};
  if(order.queue==="VERIFYING")return {label:"Đang xác minh bàn giao",tone:"warning"};
  if(order.queue==="WAITING")return {label:"Chờ đơn bán",tone:"warning"};
  const picked=io05OrderPickedTotal(order), remaining=io05OrderRemainingTotal(order);
  if(picked<=0)return {label:"Cần lấy hàng",tone:"neutral"};
  if(picked>=remaining)return {label:"Chờ bàn giao",tone:"info"};
  return {label:"Đang lấy hàng",tone:"info"};
}
function io05VisibleOrders(){return io05Orders.filter(o=>!o.closed);}
function io05AllAllocations(order=io05CurrentOrder()){return (order?.lines||[]).flatMap(l=>(l.allocations||[]).map(a=>({line:l,allocation:a})));}
function io05ResetHandover(order=io05CurrentOrder()){io05HandoverByAllocation={};io05AllAllocations(order).forEach(({allocation})=>{const available=io05AllocationRemainingPicked(allocation);if(available>0)io05HandoverByAllocation[allocation.id]=available;});}
function io05SyncHandover(){io05AllAllocations().forEach(({allocation})=>{const available=io05AllocationRemainingPicked(allocation);if(available>0&&io05HandoverByAllocation[allocation.id]==null)io05HandoverByAllocation[allocation.id]=available;});}
io05ResetHandover();
function io05CurrentLine(){return io05CurrentLines().find(l=>l.id===io05ActiveLineId)||io05CurrentLines()[0];}
function io05CurrentAllocation(){const line=io05CurrentLine();return line?.allocations.find(a=>a.id===io05ActiveAllocationId)||line?.allocations?.[0];}
function io05CorrectionPending(a){return Boolean(a?.physicalCorrection&&a.physicalCorrection.status!=="CONFIRMED");}
function io05CanReview(){const order=io05CurrentOrder();const picked=io05OrderPickedTotal(order);const correctionPending=io05AllAllocations(order).some(({allocation})=>io05CorrectionPending(allocation));if(!order||order.queue==="WAITING"||order.queue==="VERIFYING"||picked<=0||correctionPending)return false;return order.partialHandoverAllowed?true:(order.lines||[]).every(l=>io05LinePicked(l)>=io05LineRemaining(l));}
function io05HandoverInvalid(){return io05AllAllocations().some(({allocation})=>{const available=io05AllocationRemainingPicked(allocation);if(available<=0)return false;const q=Number(io05HandoverByAllocation[allocation.id]||0);return q<0||q>available;});}
function io05HandoverTotal(){return io05AllAllocations().reduce((sum,{allocation})=>sum+Number(io05HandoverByAllocation[allocation.id]||0),0);}
function io05PickedTotal(){return io05OrderPickedTotal();}
function io05RemainingAfterHandover(){return Math.max(0,io05OrderRemainingTotal()-io05HandoverTotal());}
function io05HandoverByLine(){const m=new Map();io05AllAllocations().forEach(({line,allocation})=>{const q=Number(io05HandoverByAllocation[allocation.id]||0);if(q>0)m.set(line.id,(m.get(line.id)||0)+q);});return m;}
function io05HandoverProductCount(){return io05HandoverByLine().size;}
function io05RemainingProductCountAfterHandover(){const h=io05HandoverByLine();return io05CurrentLines().filter(line=>Math.max(0,io05LineRemaining(line)-Number(h.get(line.id)||0))>0).length;}
function io05ResultRows(result){
  if(!result)return [];
  const grouped=new Map();
  (result.detail||[]).forEach(d=>{const key=`${d.product}|${d.code}|${d.uom}|${d.lot||''}`;const prev=grouped.get(key)||{product:d.product,code:d.code,uom:d.uom,lot:d.lot||null,qty:0};prev.qty+=Number(d.qty||0);grouped.set(key,prev);});
  return [...grouped.values()];
}
function io05EligibleLotMeta(allocation,code){return (allocation?.eligibleLots||[]).find(x=>(typeof x==='string'?x:x.code)===code);}
function io05ExpiryDisplay(meta){return meta?.expiryDisplay||meta?.expiry||'—';}
function io05ApplyStaleRecovery(){
  const order=io05CurrentOrder(); if(!order||order.id!=="SO-260827-21"||io05StaleAppliedForOrder[order.id])return;
  const line=order.lines.find(l=>l.id==="PK-21-01"); const a=line?.allocations.find(x=>x.id==="AL-21-01"); if(!a)return;
  const oldLot=a.lot, unconsumed=io05AllocationRemainingPicked(a); a.lot="DH2511"; a.pickedQty=Number(a.consumedQty||0);
  if(unconsumed>0)a.physicalCorrection={kind:"STALE",status:"PENDING",oldLot,returnQty:unconsumed,newLot:"DH2511",repickQty:unconsumed,actor:null,confirmedAt:null};
  order.allocationVersion=Number(order.allocationVersion||0)+1; io05StaleAppliedForOrder[order.id]=true;io05ResetHandover(order);
}
function io05CorrectionText(line,a){const c=a?.physicalCorrection;if(!c||c.status==="CONFIRMED")return "";return `Trả ${c.returnQty} ${line.uom} lô ${c.oldLot}; lấy lại ${c.repickQty} ${line.uom} lô ${c.newLot}.`;}
function io05MarkUnknown(order=io05CurrentOrder()){if(!order)return;order.queue="VERIFYING";order.status="Đang xác minh bàn giao";order.verificationOperationId=order.operationId;}
function io05ApplyHandover(){
  const order=io05CurrentOrder(); const handed=io05HandoverTotal(); if(!order||handed<=0||order.queue==="VERIFYING")return null;
  const detail=[]; const handoverLines=[];
  io05AllAllocations(order).forEach(({line,allocation})=>{
    const available=io05AllocationRemainingPicked(allocation);const q=Math.min(Number(io05HandoverByAllocation[allocation.id]||0),available);if(q<=0)return;
    detail.push({product:line.name,code:line.code,uom:line.uom,lot:allocation.lot,qty:q});
    handoverLines.push({allocationId:allocation.id,productId:line.code,uom:line.uom,baseUom:line.baseUom,sourceQty:q,actualBaseQty:q*Number(line.conversionToBase||1),lot:allocation.lot,conversionVersion:line.conversionVersion});
    allocation.consumedQty=Number(allocation.consumedQty||0)+q; line.deliveredQty=Number(line.deliveredQty||0)+q;
  });
  const remaining=io05OrderRemainingTotal(order); const full=remaining<=0; const confirmedAt="16/09/2026 13:08";
  const evidence={handoverId:`HO-${order.id}-${String((order.handoverCount||0)+1).padStart(2,'0')}`,operationId:order.operationId,sourceId:order.id,sourceVersion:(order.sourceVersion??order.fulfillmentVersion),warehouse:order.warehouse,actorId:IO05_ACTOR.id,actorName:IO05_ACTOR.name,confirmedAt,allocationSetId:order.allocationSetId,allocationVersion:order.allocationVersion,lines:handoverLines,evidenceHash:`sha256:${order.id}:${order.allocationVersion}:${handoverLines.length}`};
  order.handoverCount=Number(order.handoverCount||0)+1;order.lastHandoverEvidence=evidence;
  if(full){order.closed=true;order.status="Đã bàn giao";}else{order.queue="ACTIONABLE";order.status="Cần tiếp tục";}
  const result={orderId:order.id,customer:order.customer,handed,remaining,full,detail,confirmedAt,evidence};io05LastResult=result;io05ResetHandover(order);return result;
}

function io06EvidenceSvg(lot){const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="320" height="180"><rect width="100%" height="100%" rx="12" fill="#f6f7f8"/><rect x="22" y="22" width="276" height="136" rx="8" fill="#fff" stroke="#c7cdd3"/><text x="42" y="70" font-family="Arial" font-size="16" fill="#4b5563">Ảnh nhãn lô thực nhận</text><text x="42" y="112" font-family="Arial" font-size="30" font-weight="700" fill="#111827">LOT ${lot}</text></svg>`;return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`;}
const io06Requests=[
  {id:"RET-260827-03",source:"SO-260812-44",sourceVersion:5,customer:"Phòng khám Minh Tâm",status:"Cần nhận",queue:"ACTIONABLE",phase:"RECEIPT",receiptCommitted:false,classified:false,closed:false},
  {id:"RET-260827-05",source:"SO-260815-19",sourceVersion:3,customer:"Đại lý Nam Việt",status:"Cần phân loại",queue:"ACTIONABLE",phase:"CLASSIFICATION",receiptCommitted:true,classified:false,closed:false},
  {id:"RET-260827-07",source:"SO-260820-08",sourceVersion:7,customer:"Nhà thuốc thú y Hòa Bình",status:"Đang chờ duyệt lô",queue:"WAITING",phase:"RECEIPT",receiptCommitted:false,classified:false,closed:false}
];
const io06LinesByRequest={
  "RET-260827-03":[
    {id:"RET-L1A",name:"Nobivac DHPPi",code:"SP-000184",uom:"hộp",shipped:6,returnedBefore:2,remaining:4,expectedLot:"DH2507",qty:null,actualLot:"",actualLotMode:"",verified:false,reasonCode:"",reasonDetail:"",evidenceFile:"",evidenceData:"",exceptionCaseId:null,knownExpired:0,classification:{sellable:0,quarantine:0,damaged:0,expired:0}},
    {id:"RET-L1B",name:"Nobivac DHPPi",code:"SP-000184",uom:"hộp",shipped:4,returnedBefore:0,remaining:4,expectedLot:"DH2509",qty:null,actualLot:"",actualLotMode:"",verified:false,reasonCode:"",reasonDetail:"",evidenceFile:"",evidenceData:"",exceptionCaseId:null,knownExpired:0,classification:{sellable:0,quarantine:0,damaged:0,expired:0}},
    {id:"RET-L2",name:"Amox 500",code:"SP-000066",uom:"hộp",shipped:6,returnedBefore:1,remaining:5,expectedLot:"AM2505",qty:null,actualLot:"",actualLotMode:"",verified:false,reasonCode:"",reasonDetail:"",evidenceFile:"",evidenceData:"",exceptionCaseId:null,knownExpired:0,classification:{sellable:0,quarantine:0,damaged:0,expired:0}},
    {id:"RET-L3",name:"Băng cuộn y tế",code:"SP-000351",uom:"cuộn",shipped:3,returnedBefore:0,remaining:3,expectedLot:null,qty:null,actualLot:null,actualLotMode:"",verified:false,comboName:"Combo chăm sóc hậu phẫu",reasonCode:"",reasonDetail:"",evidenceFile:"",evidenceData:"",exceptionCaseId:null,knownExpired:0,classification:{sellable:0,quarantine:0,damaged:0,expired:0}}
  ],
  "RET-260827-05":[
    {id:"RET-L4",name:"Nobivac DHPPi",code:"SP-000184",uom:"hộp",shipped:8,returnedBefore:0,remaining:8,expectedLot:"DH2509",qty:4,actualLot:"DH2509",actualLotMode:"EXPECTED",verified:true,reasonCode:"",reasonDetail:"",evidenceFile:"",evidenceData:"",exceptionCaseId:null,knownExpired:2,classification:{sellable:0,quarantine:0,damaged:0,expired:0}},
    {id:"RET-L5",name:"Găng tay khám Nitrile",code:"SP-000271",uom:"hộp",shipped:10,returnedBefore:0,remaining:10,expectedLot:null,qty:5,actualLot:null,actualLotMode:"",verified:true,reasonCode:"",reasonDetail:"",evidenceFile:"",evidenceData:"",exceptionCaseId:null,knownExpired:0,classification:{sellable:0,quarantine:0,damaged:0,expired:0}}
  ],
  "RET-260827-07":[
    {id:"RET-L6",name:"Nobivac DHPPi",code:"SP-000184",uom:"hộp",shipped:10,returnedBefore:2,remaining:8,expectedLot:"DH2507",qty:3,actualLot:"DH2509",actualLotMode:"OTHER",verified:true,reasonCode:"ACTUAL_DIFF",reasonDetail:"",evidenceFile:"anh-nhan-lo-DH2509.jpg",evidenceData:io06EvidenceSvg("DH2509"),exceptionCaseId:"EX-06-001",knownExpired:0,classification:{sellable:0,quarantine:0,damaged:0,expired:0}}
  ]
};
let io06ApprovalSeq=2;
const io06ApprovalCases=[
  {id:"EX-06-001",requestId:"RET-260827-07",lineId:"RET-L6",status:"PENDING",maker:"Nguyễn Minh · Thủ kho",createdAt:"03/09/2026 09:18",decisionReason:"",snapshot:{requestId:"RET-260827-07",source:"SO-260820-08",sourceVersion:7,lineId:"RET-L6",qty:3,uom:"hộp",expectedLot:"DH2507",actualLot:"DH2509",reasonCode:"ACTUAL_DIFF",reasonDetail:"",evidenceFile:"anh-nhan-lo-DH2509.jpg",evidenceData:io06EvidenceSvg("DH2509")}}
];
let io06SelectedRequestId="RET-260827-03", io06ActiveLineId="RET-L1A", io06Query="", io06QueueFilter="ALL", io06RejectOpen=false, io06RejectReason="", io06ClassificationOpen=false, io06ClassificationDraft=null, io06SelectedApprovalCaseId="EX-06-001", io06ApproverListMode=true;
function io06CurrentRequest(){return io06Requests.find(r=>r.id===io06SelectedRequestId)||io06Requests.find(r=>!r.closed)||io06Requests[0];}
function io06LinesForRequest(id){return io06LinesByRequest[id]||[];}
function io06CurrentLines(){return io06LinesForRequest(io06SelectedRequestId);}
function io06FindLine(id){for(const lines of Object.values(io06LinesByRequest)){const l=lines.find(x=>x.id===id);if(l)return l;}return null;}
function io06ActiveLine(){return io06FindLine(io06ActiveLineId)||io06CurrentLines()[0];}
function io06LineCase(line){return line?.exceptionCaseId?io06ApprovalCases.find(c=>c.id===line.exceptionCaseId):null;}
function io06PendingCasesForRequest(id){return io06ApprovalCases.filter(c=>c.requestId===id&&c.status==="PENDING");}
function io06CasesForRequest(id){return io06ApprovalCases.filter(c=>c.requestId===id&&!['INVALIDATED','SUPERSEDED'].includes(c.status));}
function io06CaseSnapshot(req,line){return {requestId:req.id,source:req.source,sourceVersion:req.sourceVersion,lineId:line.id,qty:Number(line.qty||0),uom:line.uom,expectedLot:line.expectedLot||null,actualLot:line.actualLot||null,reasonCode:line.reasonCode||"",reasonDetail:(line.reasonDetail||"").trim(),evidenceFile:line.evidenceFile||"",evidenceData:line.evidenceData||""};}
function io06SnapshotMatches(line,caseObj){if(!line||!caseObj)return false;const req=io06Requests.find(r=>r.id===caseObj.requestId);if(!req)return false;const a=io06CaseSnapshot(req,line),b=caseObj.snapshot||{};return ["requestId","source","sourceVersion","lineId","qty","uom","expectedLot","actualLot","reasonCode","reasonDetail","evidenceFile"].every(k=>String(a[k]??"")===String(b[k]??""));}
function io06InvalidateCaseIfChanged(line){const c=io06LineCase(line);if(!c||c.status==="PENDING"||io06SnapshotMatches(line,c))return;if(["APPROVED","REJECTED"].includes(c.status)){c.status="INVALIDATED";line.exceptionCaseId=null;}}
function io06Mismatch(line=io06ActiveLine()){return Boolean(line?.expectedLot)&&Boolean(String(line.actualLot||"").trim())&&String(line.actualLot||"").trim().toUpperCase()!==String(line.expectedLot||"").trim().toUpperCase();}
function io06LinePhysicalValid(line){if(!line||!line.verified||Number(line.qty||0)<=0||Number(line.qty||0)>Number(line.remaining||0))return false;if(line.expectedLot&&!String(line.actualLot||"").trim())return false;return true;}
function io06LineEvidenceReady(line){return !io06Mismatch(line)||(Boolean(line.reasonCode)&&Boolean(line.evidenceFile)&&(line.reasonCode!=="OTHER"||Boolean((line.reasonDetail||"").trim())));}
function io06LineApprovalState(line){if(!io06Mismatch(line))return "NOT_REQUIRED";const c=io06LineCase(line);if(c&&io06SnapshotMatches(line,c))return c.status;if(c&&!io06SnapshotMatches(line,c))return "INVALIDATED";return io06LineEvidenceReady(line)&&line.verified?"DRAFT":"NEEDS_EVIDENCE";}
function io06RequestAllVerified(req=io06CurrentRequest()){const lines=io06LinesForRequest(req.id);return lines.length>0&&lines.every(io06LinePhysicalValid);}
function io06RequestHasMismatch(req=io06CurrentRequest()){return io06LinesForRequest(req.id).some(io06Mismatch);}
function io06RequestCanSubmitExceptions(req=io06CurrentRequest()){const lines=io06LinesForRequest(req.id);return io06RequestAllVerified(req)&&lines.some(l=>io06Mismatch(l)&&!["PENDING","APPROVED"].includes(io06LineApprovalState(l)))&&lines.filter(io06Mismatch).every(l=>io06LineEvidenceReady(l));}
function io06ReceiptReady(req=io06CurrentRequest()){const lines=io06LinesForRequest(req.id);return io06RequestAllVerified(req)&&lines.every(l=>!io06Mismatch(l)||(io06LineApprovalState(l)==="APPROVED"));}
function io06RefreshRequestState(req=io06CurrentRequest()){
  if(req.closed){req.queue="CLOSED";return;}
  if(req.receiptCommitted&&!req.classified){req.phase="CLASSIFICATION";req.queue="ACTIONABLE";req.status="Cần phân loại";return;}
  const cases=io06CasesForRequest(req.id);if(cases.some(c=>c.status==="PENDING")){req.queue="WAITING";req.status="Đang chờ duyệt lô";return;}
  if(cases.some(c=>c.status==="REJECTED")){req.queue="ACTIONABLE";req.status="Cần xử lý ngoại lệ";return;}
  req.phase="RECEIPT";req.queue="ACTIONABLE";req.status=io06ReceiptReady(req)?"Sẵn sàng ghi nhận":"Cần nhận";
}
function io06ClassTotal(line,c=line.classification||{}){return [c.sellable,c.quarantine,c.damaged,c.expired].reduce((a,b)=>a+Number(b||0),0);}
function io06ClassValid(line,state="READY",c=line.classification||{}){const qty=Number(line?.qty);const requiredExpired=Math.max(Number(line?.knownExpired||0),state==="EXPIRED_GUARD"?2:0);return line?.qty!=null&&line.qty!==""&&Number.isFinite(qty)&&qty>0&&io06ClassTotal(line,c)===qty&&Number(c.expired||0)>=requiredExpired;}
function io06AllClassValid(state="READY"){const lines=io06CurrentLines();return lines.length>0&&lines.every(l=>io06ClassValid(l,state));}
function io06SelectedApprovalCase(){const exact=io06ApprovalCases.find(c=>c.id===io06SelectedApprovalCaseId&&c.status!=="INVALIDATED");if(exact)return exact;const pending=io06ApprovalCases.find(c=>c.status==="PENDING");if(pending){io06SelectedApprovalCaseId=pending.id;return pending;}return null;}
function io06ApprovalCaseLine(c=io06SelectedApprovalCase()){return c?io06FindLine(c.lineId):null;}
function io06CreateCase(req,line){const prev=io06LineCase(line);if(prev&&prev.status!=="PENDING")prev.status="SUPERSEDED";const snap=io06CaseSnapshot(req,line);const c={id:`EX-06-${String(io06ApprovalSeq++).padStart(3,"0")}`,requestId:req.id,lineId:line.id,status:"PENDING",maker:"Nguyễn Minh · Thủ kho",createdAt:"03/09/2026 10:00",decisionReason:"",snapshot:snap};io06ApprovalCases.push(c);line.exceptionCaseId=c.id;return c;}
function io06SubmitDraftExceptions(req=io06CurrentRequest()){
  if(!io06RequestCanSubmitExceptions(req))return false;
  io06LinesForRequest(req.id).filter(io06Mismatch).forEach(line=>{const st=io06LineApprovalState(line);if(st!=="APPROVED"&&st!=="PENDING")io06CreateCase(req,line);});io06RefreshRequestState(req);return true;
}
function io06AfterApprovalDecision(caseObj){const req=io06Requests.find(r=>r.id===caseObj.requestId);if(!req)return;io06RefreshRequestState(req);}
function io06SetLineDirty(line){line.verified=false;io06InvalidateCaseIfChanged(line);}
function io06ClassificationDraftFor(line){if(!line)return null;if(!io06ClassificationDraft||io06ClassificationDraft.lineId!==line.id)io06ClassificationDraft={lineId:line.id,...line.classification};return io06ClassificationDraft;}
function io06ResultLineLabel(line){return `${line.name}${line.actualLot?` · lô ${line.actualLot}`:""}`;}
function io06ClassificationSummary(line){const c=line.classification;return `Bán được ${c.sellable} · Cách ly ${c.quarantine} · Hỏng ${c.damaged} · Hết hạn ${c.expired} ${line.uom}`;}

const io07Requests=[
  {id:"RTV-260827-02",supplier:"Minh Dũng",source:"YCTN-260827-02",sourceVersion:3,warehouse:"Kho chính",lifecycle:"Chờ bàn giao",queue:"ACTIONABLE",changed:false,sourceChanges:[],groups:[
    {id:"RTV-G1",name:"Nobivac DHPPi",code:"SP-00142",uom:"hộp",tracking:"LOT",allocations:[
      {id:"RTV-A1",lot:"DH2507",expiry:"30/11/2026",qty:4,verified:false,physicalMismatch:false,affectedByChange:false},
      {id:"RTV-A2",lot:"DH2511",expiry:"31/03/2027",qty:2,verified:false,physicalMismatch:false,affectedByChange:false}
    ]},
    {id:"RTV-G2",name:"Nobivac DHPPi",code:"SP-00142",uom:"lọ",tracking:"LOT",allocations:[
      {id:"RTV-A3",lot:"DH2507",expiry:"30/11/2026",qty:6,verified:false,physicalMismatch:false,affectedByChange:false}
    ]},
    {id:"RTV-G3",name:"Găng tay khám Nitrile",code:"SP-00618",uom:"hộp",tracking:"NONE",allocations:[
      {id:"RTV-A4",lot:null,expiry:null,qty:5,verified:false,physicalMismatch:false,affectedByChange:false}
    ]}
  ]},
  {id:"RTV-260827-04",supplier:"An Việt",source:"YCTN-260827-04",sourceVersion:5,warehouse:"Kho chính",lifecycle:"Chờ bàn giao",queue:"ACTIONABLE",changed:true,sourceChanges:["Găng tay khám Nitrile · hộp: 8 → 5; 3 hộp được bỏ khỏi lượng chờ trả."],groups:[
    {id:"RTV-G4",name:"Găng tay khám Nitrile",code:"SP-00618",uom:"hộp",tracking:"NONE",allocations:[
      {id:"RTV-A5",lot:null,expiry:null,qty:5,previousQty:8,verified:false,physicalMismatch:false,affectedByChange:true}
    ]},
    {id:"RTV-G5",name:"Băng cuộn y tế",code:"SP-00307",uom:"cuộn",tracking:"NONE",allocations:[
      {id:"RTV-A6",lot:null,expiry:null,qty:2,verified:true,verifyMethod:"VISUAL",physicalMismatch:false,affectedByChange:false}
    ]}
  ]},
  {id:"RTV-260903-03",supplier:"Thú Y Hoàng Gia",source:"YCTN-260903-03",sourceVersion:2,warehouse:"Kho chính",lifecycle:"Chờ bàn giao",queue:"ACTIONABLE",changed:false,sourceChanges:[],groups:[
    {id:"RTV-G6",name:"Amox 500",code:"SP-00205",uom:"hộp",tracking:"LOT",allocations:[
      {id:"RTV-A7",lot:"AM2505",expiry:"31/05/2027",qty:2,verified:true,verifyMethod:"VISUAL",physicalMismatch:false,affectedByChange:false}
    ]}
  ]},
  {id:"RTV-260903-05",supplier:"Phú Nông",source:"YCTN-260903-05",sourceVersion:1,warehouse:"Kho chính",lifecycle:"Chờ bàn giao",queue:"WAITING",waitingReason:"Bộ phận Mua hàng đang cập nhật yêu cầu trả. Kho chỉ xem, chưa tiếp tục chuẩn bị.",changed:false,sourceChanges:[],groups:[
    {id:"RTV-G7",name:"Vitamin ADE",code:"SP-00511",uom:"chai",tracking:"LOT",allocations:[
      {id:"RTV-A8",lot:"VA2508",expiry:"31/08/2027",qty:3,verified:false,physicalMismatch:false,affectedByChange:false}
    ]}
  ]},
  {id:"RTV-260903-06",supplier:"Nam Việt",source:"YCTN-260903-06",sourceVersion:4,warehouse:"Kho chính",lifecycle:"Đã hủy từ nguồn",queue:"CLOSED",sourceCancelled:true,closed:true,changed:true,sourceChanges:["Bộ phận Mua hàng đã hủy yêu cầu trước bàn giao; lượng chờ trả được hệ thống giải phóng."],groups:[]}
];
let io07Selected="RTV-260827-02", io07Query="", io07QueueFilter="ALL", io07ActiveAllocationId="", io07VerifySheetOpen=false, io07ScanLot="", io07LastResult=null, io07OperationSeq=1;
function io07Current(){return io07Requests.find(r=>r.id===io07Selected)||io07Requests.find(r=>!r.closed&&!r.completed)||io07Requests[0];}
function io07ActiveRequests(){return io07Requests.filter(r=>!r.closed&&!r.completed&&!r.sourceCancelled);}
function io07Allocations(req=io07Current()){return (req.groups||[]).flatMap(group=>(group.allocations||[]).map(allocation=>({group,allocation})));}
function io07FindAllocation(id,req=io07Current()){return io07Allocations(req).find(x=>x.allocation.id===id)||null;}
function io07AllVerified(req=io07Current()){const lines=io07Allocations(req);return lines.length>0&&lines.every(({allocation})=>allocation.verified&&!allocation.physicalMismatch);}
function io07HasMismatch(req=io07Current()){return io07Allocations(req).some(({allocation})=>allocation.physicalMismatch);}
function io07VerifiedCount(req=io07Current()){return io07Allocations(req).filter(({allocation})=>allocation.verified&&!allocation.physicalMismatch).length;}
function io07Stage(req){if(req.queue==="WAITING")return "WAITING";return io07AllVerified(req)?"READY":"ACTIONABLE";}
function io07StageMeta(req){const stage=io07Stage(req);if(stage==="WAITING")return ["Chờ cập nhật","info"];if(stage==="READY")return ["Sẵn sàng","success"];if(req.changed)return ["Cần kiểm lại","warning"];return ["Cần chuẩn bị","warning"];}
function io07MatchesQueue(req){return io07QueueFilter==="ALL"||io07Stage(req)===io07QueueFilter;}
function io07AllocationLabel(group,a){return group.tracking==="LOT"?`Lô ${a.lot}`:"Không theo lô";}
function io07AllocationSecondary(group,a){
  if(a.previousQty!=null&&a.affectedByChange)return `Cần kiểm lại · Trước ${a.previousQty} → nay ${a.qty} ${group.uom}`;
  const status=a.physicalMismatch?"Không khớp":a.verified?"Đã kiểm":"Cần trả";
  const bits=[status,`${a.qty} ${group.uom}`];
  if(a.expiry)bits.push(`HSD ${a.expiry}`);
  return bits.join(" · ");
}
function io07AllocationStatus(a){if(a.physicalMismatch)return ["Không khớp","Danger"];if(a.verified)return ["Đã kiểm","Success"];if(a.affectedByChange)return ["Cần kiểm lại","Warning"];return ["Chưa kiểm","Neutral"];}
function io07ProductProgress(group){
  const all=group.allocations||[], verified=all.filter(a=>a.verified&&!a.physicalMismatch).length;
  const mismatch=all.some(a=>a.physicalMismatch), changed=all.some(a=>a.affectedByChange);
  return {verified,total:all.length,label:`${verified}/${all.length}`,tone:mismatch?"Danger":changed?"Warning":verified===all.length&&all.length?"Success":"Neutral"};
}
function io07QueueList(requests){
  const rows=(requests||[]).map(r=>{
    const stage=io07Stage(r);
    const meta=io07StageMeta(r);
    const tone=meta[1]==="success"?"Success":meta[1]==="warning"?"Warning":meta[1]==="danger"?"Danger":meta[1]==="info"?"Info":"Neutral";
    const label=r.changed&&stage==="ACTIONABLE"?"Cần kiểm lại":meta[0];
    const search=`data-io07-search-text="${escapeAttribute(ioNormalizeSearch(`${r.id} ${r.supplier} ${r.source}`))}"`;
    const attrs=`data-io07-request="${escapeAttribute(r.id)}" ${search}`;
    const waiting=stage==="WAITING";
    return ds24ListRow({
      title:r.id,
      subtitle:`${r.supplier} · ${r.source}`,
      trailing:ds24Badge(label,tone),
      leading:null,
      attrs,
      type:"Navigation",
      state:waiting?"Disabled":"Default",
      density:"Default",
      interactive:true,
      disabled:waiting
    });
  }).join("");
  return rows?`<section class="ds24-list-stack io07-queue" data-composed-from="DS v2 / List Row,VBadge">${rows}</section>`:"";
}
function io07ProductGroupHeader(group,{label="",tone="Neutral",role="rtv-product-summary"}={}){
  const subtitle=`${group.code||""}${group.code?" · ":""}${group.uom||""}`;
  return ds24ListRow({
    title:group.name,
    subtitle,
    trailing:label?ds24Badge(label,tone):"",
    leading:"package",
    attrs:`data-layout-role="${escapeAttribute(role)}" data-ds-role="rtv-product-group-header"`,
    type:"Status",
    density:"Compact",
    interactive:false
  });
}
function io07AllocationActionRow(group,a){
  const status=a.physicalMismatch?"Không khớp":a.affectedByChange?"Cần kiểm lại":a.verified?"Đã kiểm":"";
  let subtitle=`${a.qty} ${group.uom}`;
  if(a.expiry) subtitle+=` · HSD ${a.expiry}`;
  if(status) subtitle+=` · ${status}`;
  if(a.previousQty!=null&&a.affectedByChange) subtitle+=` · trước ${a.previousQty} ${group.uom}`;
  return ds24ListRow({
    title:io07AllocationLabel(group,a),
    subtitle,
    leading:null,
    attrs:`data-io07-allocation="${escapeAttribute(a.id)}" data-layout-role="rtv-allocation-row"`,
    type:"Navigation",
    density:"Default"
  });
}
function io07PreparationGroups(req){
  return (req.groups||[]).map(group=>{
    const progress=io07ProductProgress(group);
    const heading=io07ProductGroupHeader(group,{label:`${progress.verified}/${progress.total} đã kiểm`,tone:progress.tone,role:"rtv-product-summary"});
    const rows=(group.allocations||[]).map(a=>io07AllocationActionRow(group,a)).join("");
    return `<div class="io07-product-group ds24-grouped-subgroup" data-layout-role="product-allocation-subgroup" data-composed-from="DS v2 / List Row,VBadge">${heading}<div class="io07-allocation-list">${rows}</div></div>`;
  }).join("");
}
function io07ReviewGroups(reqOrLines,{statusLabel="Đã kiểm",statusTone="Success"}={}){
  let groups=[];
  if(Array.isArray(reqOrLines)){
    const map=new Map();
    for(const line of reqOrLines||[]){const key=`${line.name}|${line.code||""}|${line.uom}`;if(!map.has(key))map.set(key,{name:line.name,code:line.code||"",uom:line.uom,tracking:line.lot?"LOT":"NONE",allocations:[]});map.get(key).allocations.push({lot:line.lot,expiry:line.expiry,qty:line.qty});}
    groups=[...map.values()];
  } else groups=(reqOrLines?.groups||[]);
  const subgroups=groups.map(group=>{
    const allocations=group.allocations||[];
    const heading=io07ProductGroupHeader(group,{label:statusLabel,tone:statusTone,role:"rtv-review-product"});
    const rows=allocations.map(a=>{
      const left=a.lot?`Lô ${a.lot}${a.expiry?` · HSD ${a.expiry}`:""}`:"Không theo lô";
      return ds24KeyValueRow(left,`${a.qty} ${group.uom}`);
    }).join("");
    return `<div class="io07-review-product ds24-grouped-subgroup" data-layout-role="product-fact-subgroup" data-composed-from="VIcon,VText,VBadge,DS v2 / Key-value Row">${heading}<div class="io07-review-kv">${rows}</div></div>`;
  }).join("");
  return ds24GroupedCollection(subgroups,"io07-review-products io07-grouped-collection io07-grouped-collection--facts","DS v2 / List Row,DS v2 / Key-value Row");
}
function io07SourceDelta(req){
  const affected=io07Allocations(req).some(({allocation})=>allocation.affectedByChange);
  return affected?vBanner("warning","Yêu cầu đã thay đổi","Phần bị ảnh hưởng cần kiểm lại theo phiên bản mới.","","Compact"):"";
}
function io07VerificationSheet(req){
  if(!io07VerifySheetOpen)return "";const found=io07FindAllocation(io07ActiveAllocationId,req);if(!found)return "";const {group,allocation:a}=found;
  const expectedLot=group.tracking==="LOT"?String(a.lot||""):"";const mismatch=Boolean(expectedLot&&io07ScanLot.trim()&&io07ScanLot.trim().toLocaleUpperCase("vi")!==expectedLot.toLocaleUpperCase("vi"));
  const product=ds24ContextStatusRow({title:group.name,subtitle:`${group.code} · ${group.uom}`,label:a.verified?"Đã kiểm":"Cần kiểm",tone:a.verified?"Success":"Neutral",leading:"package",attrs:'data-layout-role="rtv-verify-product"'});
  const facts=ds24InfoGroup("",`${ds24InfoRow("Cần chuẩn bị",`${a.qty} ${group.uom}`)}${group.tracking==="LOT"?ds24InfoRow("Lô cần khớp",a.lot):""}${a.expiry?ds24InfoRow("Hạn dùng",a.expiry):""}`,"ds24-info-group--untitled io07-sheet-facts");
  const lotInput=group.tracking==="LOT"?`${ds24TextField("Lô thực tế (không bắt buộc)",io07ScanLot,'data-io07-scan-lot autocomplete="off"',"Chỉ đối chiếu, không thay lô.")}<div data-io07-scan-feedback>${mismatch?vBanner("error","Lô không khớp",`Cần lô ${expectedLot}. Kho không thay lô tại đây.`,"","Compact"):""}</div>`:"";
  return `<div class="sheet-backdrop io07-verify-backdrop" data-io07-verify-backdrop><section class="bottom-sheet io-bottom-sheet io07-verification-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="Kiểm hàng thực tế"><div class="sheet-handle"></div><div class="sheet-title"><h3>Kiểm hàng thực tế</h3></div><div class="io07-verification-content">${product}${facts}${lotInput}<div class="io07-sheet-actions"><button class="button button--secondary" data-io07-action="mark-mismatch" type="button">Không khớp</button><button class="button button--primary" data-io07-action="confirm-allocation" type="button" ${mismatch?'disabled':''}>Đúng hàng</button></div></div></section></div>`;
}
function io07OpenVerification(id){io07ActiveAllocationId=id;io07ScanLot="";io07VerifySheetOpen=true;}
function io07ApplySourceUpdate(reqId,changes=[]){const req=io07Requests.find(r=>r.id===reqId);if(!req||req.completed||req.closed)return false;req.sourceVersion=Number(req.sourceVersion||0)+1;req.changed=true;const notes=[];for(const change of changes){if(change.type==="QTY"){const f=io07FindAllocation(change.allocationId,req);if(!f)continue;f.allocation.previousQty=f.allocation.qty;f.allocation.qty=change.newQty;f.allocation.verified=false;f.allocation.physicalMismatch=false;f.allocation.affectedByChange=true;notes.push(change.note||`${f.group.name} · ${f.group.uom}: ${f.allocation.previousQty} → ${change.newQty}.`);}else if(change.type==="LOT"){const f=io07FindAllocation(change.allocationId,req);if(!f)continue;f.allocation.previousLot=f.allocation.lot;f.allocation.lot=change.newLot;f.allocation.verified=false;f.allocation.physicalMismatch=false;f.allocation.affectedByChange=true;notes.push(change.note||`${f.group.name} · ${f.group.uom}: Lô ${f.allocation.previousLot} → ${change.newLot}.`);}else if(change.type==="REMOVE"){for(const group of req.groups||[]){const idx=(group.allocations||[]).findIndex(a=>a.id===change.allocationId);if(idx>=0){const old=group.allocations[idx];group.allocations.splice(idx,1);notes.push(change.note||`${group.name} · ${group.uom}${old.lot?` · Lô ${old.lot}`:""}: bỏ khỏi yêu cầu; lượng chờ trả được hệ thống giải phóng.`);break;}}req.groups=req.groups.filter(g=>(g.allocations||[]).length);}else if(change.type==="ADD"){let group=req.groups.find(g=>g.id===change.groupId);if(!group&&change.group){group={...change.group,allocations:[]};req.groups.push(group);}if(!group)continue;const allocation={...change.allocation,verified:false,physicalMismatch:false,affectedByChange:true};group.allocations.push(allocation);notes.push(change.note||`${group.name} · ${group.uom}${allocation.lot?` · Lô ${allocation.lot}`:""}: thêm ${allocation.qty} ${group.uom} cần kiểm.`);}}
  if(notes.length)req.sourceChanges=[...notes];req.queue="ACTIONABLE";return true;}
function io07CancelSource(reqId){const req=io07Requests.find(r=>r.id===reqId);if(!req||req.completed)return false;req.sourceVersion=Number(req.sourceVersion||0)+1;req.sourceCancelled=true;req.closed=true;req.queue="CLOSED";req.lifecycle="Đã hủy từ nguồn";req.changed=true;req.sourceChanges=["Bộ phận Mua hàng đã hủy yêu cầu trước bàn giao; lượng chờ trả được hệ thống giải phóng."];return true;}
function io07CreateResult(req){const op=`IO-RTV-260903-${String(io07OperationSeq++).padStart(3,"0")}`;const lines=io07Allocations(req).map(({group,allocation:a})=>({groupId:group.id,name:group.name,code:group.code,uom:group.uom,lot:a.lot,expiry:a.expiry,qty:a.qty}));io07LastResult={operationId:op,requestId:req.id,supplier:req.supplier,source:req.source,sourceVersion:req.sourceVersion,warehouse:req.warehouse,lines};return io07LastResult;}
function io07ResultSnapshot(){if(io07LastResult)return io07LastResult;const req=io07Current();return {operationId:"IO-RTV-ĐANG-XỬ-LÝ",requestId:req.id,supplier:req.supplier,source:req.source,sourceVersion:req.sourceVersion,warehouse:req.warehouse,lines:io07Allocations(req).map(({group,allocation:a})=>({name:group.name,code:group.code,uom:group.uom,lot:a.lot,expiry:a.expiry,qty:a.qty}))};}

function ioSearchBar(placeholder,attr,value=""){return `<div class="search-box io-search" data-ds-component="VSearchBar" data-ds-profile="search.standard" data-ds-prop-variant="VSearchBarVariant.outlined" data-ds-prop-tone="VComponentTone.neutral" data-ds-prop-hint-text="${escapeAttribute(placeholder)}"><span class="search-leading">${icon("search","icon--sm")}</span><input ${attr} value="${escapeAttribute(value)}" placeholder="${escapeAttribute(placeholder)}" aria-label="${escapeAttribute(placeholder)}"/><span></span></div>`;}
function ioNormalizeSearch(value){return String(value||"").trim().toLocaleLowerCase("vi");}
function ioMatchesSearch(query,text){const q=ioNormalizeSearch(query);return !q||ioNormalizeSearch(text).includes(q);}
function ioFilterRows(scope,query){
  const q=ioNormalizeSearch(query); let visible=0;
  document.querySelectorAll(`[data-${scope}-search-text]`).forEach((row)=>{const show=!q||String(row.dataset[`${scope}SearchText`]||"").includes(q);row.hidden=!show;if(show)visible+=1;});
  const empty=document.querySelector(`[data-${scope}-filter-empty]`); if(empty)empty.hidden=visible!==0;
}
function ioSectionTitle(title,meta=""){return `<div class="io-section-title" data-ds-component="VSection"><h2 data-ds-component="VText">${title}</h2>${meta?`<span data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall">${meta}</span>`:""}</div>`;}
function ioMetaText(v){return String(v??"").replace(/<[^>]*>/g,"").replace(/&[a-zA-Z0-9#]+;/g," ").trim();}
function ioMetaDetail(label,value,strong=false){return `<div class="io-meta-detail" data-composed-from="VText"><span data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall">${label}</span><${strong?'strong':'p'} data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodyDefault">${value}</${strong?'strong':'p'}></div>`;}
function ioMetaRow(label,value,strong=false){
  const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);
  const labelText=ioMetaText(label), valueText=ioMetaText(value);
  const needsMultiline=calibrated && (labelText.length>22 || valueText.length>30 || (labelText.length+valueText.length)>44);
  if(needsMultiline) return ioMetaDetail(label,value,strong);
  return `<div class="io-meta-row" ${calibrated?'data-ds-component="DS v2 / Info Row" data-figma-node="525:351" data-ds-prop-state="Default"':'data-ds-component="VSection"'}><span data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall">${label}</span><${strong?'strong':'span'} data-ds-component="VText">${value}</${strong?'strong':'span'}></div>`;
}
function ioProductRow({name,code,primary,secondary="",badge="",badgeStatus="info",attr="",interactive=true}){const tag=interactive?"button":"div";const typeAttr=interactive?' type="button"':"";const composed=interactive?"VText,VBadge,VIcon":"VText,VBadge";return `<${tag} class="io-product-row ${interactive?"":"is-readonly"}" ${attr}${typeAttr} data-theme-component="InventoryOperationItemRow" data-ds-migration-state="LEGACY_COMPOSITE_NOT_LIST_ROW" data-composed-from="${composed}"><span class="io-product-copy"><strong data-ds-component="VText">${name}</strong><small data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall">${code}${secondary?` · ${secondary}`:""}</small>${badge?vBadge(badge,badgeStatus):""}</span><span class="io-product-value"><strong data-ds-component="VText">${primary}</strong>${interactive?icon("chevronRight","icon--sm"):""}</span></${tag}>`;}
function ioReadCard(body,extra=""){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<section class="review-card io-read-card ${extra}" data-ds-component="${calibrated?'VSection':'VCard'}" ${calibrated?'data-composed-from="DS v2 / Info Row"':'data-ds-profile="card.readOnly"'}><div class="review-card-body">${body}</div></section>`;}
function ioSecondary(label,attr){return `<button class="button button--secondary button--full" ${attr} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.medium" type="button">${label}</button>`;}
function ioEmpty(title,desc){return `<div class="empty-state" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("inbox")}</div><h3 data-ds-component="VEmptyTitle">${title}</h3><p data-ds-component="VEmptyDescription">${desc}</p></div>`;}
function resultHero(title,desc,kind="success"){const iconName=kind==="success"?"checkCircle":kind==="danger"?"xCircle":"clock";const toneClass=kind==="success"?"icon-box--success":kind==="danger"?"icon-box--danger":"icon-box--warning";return `<div class="result-hero result-hero--${kind}" data-ds-component="VSection" data-composed-from="VIcon,VText"><div class="icon-box ${toneClass}" data-ds-component="VIcon">${icon(iconName,"icon--empty-media")}</div><h2 data-ds-component="VText" data-ds-prop-variant="VTextVariant.headingH3">${title}</h2><p data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodyDefault">${desc}</p></div>`;}
function ioResult(title,desc,rows,kind="success",button=""){return `<div class="io-result">${resultHero(title,desc,kind)}${ioReadCard(rows.map(r=>ioMetaRow(r[0],r[1],true)).join(''))}${button}</div>`;}
function ioFilterChips(active,items,attr){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<div class="filter-row io-task-filters" ${calibrated?'data-ds-component="VSection"':'data-theme-component="InventoryTaskFilterRow"'} data-composed-from="VChip">${items.map(([key,label])=>`<button type="button" class="filter-chip ${active===key?'is-active':''}" ${attr}="${key}" data-ds-component="VChip" data-ds-prop-selected="${active===key}">${label}</button>`).join('')}</div>`;}
function ac321CanonicalChips(active,items,attr){return `<div class="ac321-chip-wrap" data-composed-from="VChip" aria-label="Bộ lọc">${items.map(([key,label])=>ds24Chip(key,label,active===key,attr)).join('')}</div>`;}

function updateIO05AllocationValidation(input){
  const line=io05CurrentLine(); const allocation=line?.allocations.find(a=>a.id===input?.dataset.io05PickedAllocation); if(!allocation)return;
  allocation.pickedQty=Math.max(Number(allocation.consumedQty||0),Number(input.value)||0);
  const invalid=allocation.pickedQty>Number(allocation.allocatedQty||0);
  const err=document.querySelector(`[data-io05-picked-error="${allocation.id}"]`); if(err){err.hidden=!invalid;err.textContent=`Số lượng đã lấy không được vượt ${allocation.allocatedQty} ${line.uom}.`;}
  const btn=document.querySelector('[data-io05-action="save-pick"]'); if(btn)btn.disabled=line.allocations.some(a=>Number(a.pickedQty||0)>Number(a.allocatedQty||0));
}
function updateIO05HandoverValidation(input){
  const id=input.dataset.io05HandoverAllocation;io05HandoverByAllocation[id]=Math.max(0,Number(input.value)||0);
  const invalid=io05HandoverInvalid();const total=io05HandoverTotal();
  const err=document.querySelector('[data-io05-handover-error]');if(err){err.hidden=!invalid;err.textContent='Lượng bàn giao không được vượt lượng đã lấy nhưng chưa bàn giao của từng lô.';}
  const inThis=document.querySelector('[data-io05-summary-in-this]');if(inThis)inThis.textContent=`${io05HandoverProductCount()} dòng hàng`;
  const remaining=document.querySelector('[data-io05-summary-remaining]');if(remaining)remaining.textContent=`${io05RemainingProductCountAfterHandover()} dòng hàng`;
  const btn=document.querySelector('[data-io05-action="confirm-handover"]');if(btn)btn.disabled=invalid||total<=0;
}

function updateIO06LineValidation(){
  const line=io06ActiveLine();if(!line)return;
  const capInvalid=Number(line.qty||0)>Number(line.remaining||0);const mismatch=io06Mismatch(line);const evidenceValid=io06LineEvidenceReady(line);
  const err=document.querySelector('[data-io06-cap-error]');if(err){err.hidden=!capInvalid;err.textContent=`Không thể nhận vượt ${line.remaining} ${line.uom} còn được phép trả.`;}
  const btn=document.querySelector('.app-actions [data-io06-action]');if(btn){if(mismatch&&io06LineApprovalState(line)!=="APPROVED")btn.disabled=Number(line.qty||0)<=0||capInvalid||!evidenceValid;else btn.disabled=Number(line.qty||0)<=0||capInvalid||Boolean(line.expectedLot&&!line.actualLot);}
}
function updateIO06ClassificationLive(){
  const line=io06ActiveLine();if(!line)return;const draft=io06ClassificationDraftFor(line);
  document.querySelectorAll('[data-io06-class]').forEach((input)=>{draft[input.dataset.io06Class]=Math.max(0,Number(input.value)||0);});
  const total=io06ClassTotal(line,draft);const requiredExpired=Math.max(Number(line.knownExpired||0),stateByScreen['SCR-033']==='EXPIRED_GUARD'?2:0);const expiredGuard=Number(draft.expired||0)<requiredExpired;
  const progress=document.querySelector('[data-io06-class-progress]');if(progress)progress.textContent=`${total}/${io06QtyDisplay(line.qty)} ${line.uom}`;
  const feedback=document.querySelector('[data-io06-class-feedback]');if(feedback){feedback.innerHTML=expiredGuard?vBanner('warning','Có hàng hết hạn',`Ít nhất ${requiredExpired} ${line.uom} phải vào nhóm Hết hạn.`,"","Compact"):total>Number(line.qty||0)?vBanner('error','Vượt lượng cần phân loại',`Đang phân loại ${total}/${io06QtyDisplay(line.qty)} ${line.uom}.`,"","Compact"):'';}
  const done=document.querySelector('[data-io06-action="close-classification-item"]');if(done)done.disabled=!io06ClassValid(line,stateByScreen['SCR-033'],draft);
}

function bj04ReservationRow(line,reserved,released=false){
  const shortage=released?0:Math.max(0,line.need-reserved);
  const summary=released?`Cần trước đó ${line.need} ${line.uom} · Đã giữ 0 ${line.uom}`:`Cần ${line.need} ${line.uom} · Đã giữ ${reserved} ${line.uom}`;
  const shortageBadge=shortage?ds24Badge(`Thiếu ${shortage} ${line.uom}`,"Warning"):"";
  return ds24ListRow({title:`${line.name} · ${line.code}`,subtitle:summary,trailing:shortageBadge,leading:"package",type:"Status",interactive:false,extraClass:"bj04-reservation-row"});
}

function render021IO04(state){
  if(activeFlowId!=="UIF-04") return renderGeneric(screens.find(s=>s.id==="SCR-021"),state);
  const title="Giữ hàng theo đơn";
  const subtitle=`Đơn ${io04Fixture.order}`;
  if(state==="PERMISSION_DENIED") return appShell({title,subtitle,body:deniedBody(),centered:true,back:true,backAction:"exit-reservation-context"});
  if(state==="LOADING") return appShell({title,subtitle,body:loadingBody(),back:true,backAction:"exit-reservation-context"});

  const full=state==="FULL";
  const released=state==="RELEASED";
  const short=state==="SHORT"||state==="PARTIAL"||state==="READY";
  const projected=io04Fixture.lines.map((line)=>({line,reserved:full?line.need:(released?0:line.reserved)}));
  const shortageProducts=projected.filter((item)=>!released&&item.line.need>item.reserved).length;
  const orderStatus=released?"Đã kết thúc":"Đã xác nhận";

  let banner="";
  if(state==="STALE") banner=vBanner("info","Tình trạng đã được cập nhật","Đang hiển thị kết quả mới nhất của đơn.","","Compact");
  else if(released) banner=vBanner("info","Đã nhả lượng giữ","Lượng giữ còn lại đã được giải phóng.","","Compact");
  else if(short&&!full&&shortageProducts>0) banner=vBanner("warning","Chưa giữ đủ toàn bộ đơn",`${shortageProducts} sản phẩm thiếu; xử lý tiếp ở đơn bán.`,"","Compact");

  const context=ds24InfoGroup("Thông tin đơn",`${ds24InfoRow("Kho",io04Fixture.warehouse)}${ds24InfoRow("Trạng thái đơn",orderStatus)}`,"bj04-context");
  const rows=projected.map(({line,reserved})=>bj04ReservationRow(line,reserved,released)).join("");
  const body=`${context}${banner}<section class="bj04-section" data-ds-component="VSection" data-composed-from="DS v2 / List Row,VBadge">${ds24SectionTitle(released?"Sản phẩm đã nhả":"Sản phẩm đang giữ",`${projected.length} sản phẩm`)}<div class="bj04-list-stack">${rows}</div></section><p class="bj04-business-note" data-ds-component="VText" data-ds-prop-style="Body/Small">Giữ hàng làm giảm khả dụng, không làm giảm tồn vật lý.</p>`;
  return appShell({title,subtitle,body,back:true,backAction:"exit-reservation-context"});
}


function bj05DsTone(tone="neutral") {
  const t=String(tone||"neutral").toLowerCase();
  return t==="success"?"Success":t==="warning"?"Warning":t==="danger"?"Danger":t==="info"?"Info":"Neutral";
}
function bj05ReadOnlyListRow({title,subtitle="",trailing="",leading="package",attrs="",state="Default",density="Default",extraClass=""}) {
  return ds24ListRow({title,subtitle,trailing,leading,attrs,type:"Status",state,density,interactive:false,extraClass:`bj05-readonly-row${extraClass?` ${extraClass}`:""}`});
}
function bj05TextArea(label,value,attrs="",helper="") {
  return `<label class="bj05-textarea" data-ds-component="VTextarea" data-figma-node="522:7212" data-ds-prop-state="Filled"><span class="vet45-text-style-8">${esc(label)}</span><textarea class="bj05-textarea__control vet45-text-style-6" rows="3" ${attrs}>${esc(value)}</textarea>${helper?`<small class="vet45-text-style-11">${esc(helper)}</small>`:""}</label>`;
}
function bj05Link(label,attrs="") {
  return `<button class="bj05-link" type="button" ${attrs} data-ds-component="DS v2 / Link" data-figma-node="4431:10396" data-ds-prop-tone="Default" data-ds-prop-state="Default">${esc(label)}</button>`;
}
function bj05SelectionRow(meta,line) {
  const selected=io05OverrideLot===meta.code;
  const trailing=`<span class="bj05-radio${selected?' is-selected':''}" data-ds-component="VRadio" data-figma-node="522:7410" data-ds-prop-state="${selected?'On':'Off'}" aria-hidden="true"></span>`;
  return ds24ListRow({title:`Lô ${meta.code}`,subtitle:`HSD ${io05ExpiryDisplay(meta)} · Có thể lấy ${meta.pickableQty} ${line.uom}`,trailing,leading:null,attrs:`data-io05-select-lot="${escapeAttribute(meta.code)}" aria-pressed="${selected}" data-selection-value="${selected?'selected':'unselected'}"`,type:"Selection",state:selected?"Selected":"Default",interactive:true,extraClass:`bj05-selection-row${selected?' is-selected':''}`});
}
function bj05OverrideSheet(line,allocation) {
  if(!io05OverrideOpen||!allocation)return "";
  const alternatives=(allocation.eligibleLots||[]).filter(x=>(typeof x==='string'?x:x.code)!==allocation.lot).map(x=>typeof x==='string'?{code:x,expiry:'—',available:'—'}:x);
  const selectedRows=alternatives.map(m=>bj05SelectionRow(m,line)).join('');
  const desc=io05AllocationRemainingPicked(allocation)>0?`Đổi lô cần xác nhận đã trả lô cũ và lấy lại đúng lô mới trước khi bàn giao.`:`Chọn một lô đủ điều kiện trong ${io05CurrentOrder().warehouse}.`;
  const textarea=bj05TextArea('Lý do đổi lô *',io05OverrideReason,'data-io05-override-reason placeholder="Nhập lý do"','Bắt buộc để lưu vết thay đổi.');
  return `<div class="sheet-backdrop bj05-lot-sheet-backdrop" data-io05-override-backdrop><section class="bottom-sheet bj05-lot-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" data-ds-prop-show-title="true" data-ds-prop-title="Chọn lô thay thế" data-composed-from="VBottomSheet,DS v2 / List Row,VRadio,VTextarea,VButton" role="dialog" aria-modal="true" aria-label="Chọn lô thay thế"><div class="sheet-handle" data-ds-internal="VBottomSheet.handle"></div><div class="sheet-title" data-ds-internal="VBottomSheet.title"><h3>Chọn lô thay thế</h3></div><div class="sheet-content bj05-lot-sheet__content" data-ds-internal="VBottomSheet.content"><p class="bj05-lot-sheet__intro">${esc(desc)}</p><div class="bj05-selection-list" data-composed-from="DS v2 / List Row,VRadio">${selectedRows}</div>${textarea}<button class="button button--primary bj05-lot-sheet__cta" data-io05-action="confirm-lot-override" data-ds-component="VButton" data-figma-node="521:529" data-ds-prop-hierarchy="Primary" data-ds-prop-state="${io05OverrideReason.trim()&&io05OverrideLot?'Default':'Disabled'}" data-ds-prop-size="Default" data-ds-prop-leading-icon="false" type="button" ${io05OverrideReason.trim()&&io05OverrideLot?'':'disabled'}>Dùng lô này</button></div></section></div>`;
}
function bj05ResultDetails(result) {
  if(!result)return "";
  const actual=io05ResultRows(result);
  const actualRows=actual.map(x=>bj05ReadOnlyListRow({title:x.product,subtitle:`${x.code} · ${x.lot?`Lô ${x.lot}`:'Không theo lô'}`,trailing:`<strong class="bj05-row-quantity">${x.qty} ${esc(x.uom)}</strong>`})).join('');
  const remaining=io05CurrentLines().filter(l=>io05LineRemaining(l)>0);
  const remainingRows=remaining.map(l=>bj05ReadOnlyListRow({title:l.name,subtitle:`${l.code} · Còn cần lấy`,trailing:`<strong class="bj05-row-quantity">${io05LineRemaining(l)} ${esc(l.uom)}</strong>`})).join('');
  return `${actualRows?`<section class="bj05-section" data-ds-component="VSection" data-composed-from="DS v2 / List Row">${ds24SectionTitle('Bàn giao thực tế',`${actual.length} phần hàng`)}<div class="ds24-list-stack">${actualRows}</div></section>`:''}${remainingRows?`<section class="bj05-section" data-ds-component="VSection" data-composed-from="DS v2 / List Row">${ds24SectionTitle('Còn lại',`${remaining.length} dòng hàng`)}<div class="ds24-list-stack">${remainingRows}</div></section>`:''}`;
}

function render025IO05(state){
  if(activeFlowId!=="UIF-05") return renderGeneric(screens.find(s=>s.id==="SCR-025"),state);
  const subtitle="Từ đơn bán đã sẵn sàng xuất kho";
  if(state==="PERMISSION_DENIED") return appShell({title:"Đơn cần lấy hàng",subtitle,body:deniedBody(),centered:true,back:false});
  if(state==="LOADING") return appShell({title:"Đơn cần lấy hàng",subtitle,body:loadingBody(),back:false});
  const filters=[["ALL","Tất cả"],["ACTIONABLE","Cần lấy"],["WAITING","Đang chờ"]];
  if(state==="EMPTY") return appShell({title:"Đơn cần lấy hàng",subtitle,body:`<div class="bj05-chip-scroll">${filters.map(([k,l])=>ds24Chip(k,l,io05QueueFilter===k,'data-io05-filter')).join('')}</div>${ioEmpty("Chưa có đơn cần xử lý","Các đơn cần lấy hoặc đang chờ đơn bán xử lý sẽ xuất hiện tại đây.")}`,centered:true,back:false});
  const source=io05VisibleOrders();
  const filtered=source.filter(o=>(io05QueueFilter==="ALL"||o.queue===io05QueueFilter)&&ioMatchesSearch(io05Query,`${o.id} ${o.customer}`));
  const rows=filtered.map(o=>{const st=io05OrderStatus(o);const status=ds24Badge(st.label,bj05DsTone(st.tone));const attrs=`data-io05-search-text="${escapeAttribute(ioNormalizeSearch(`${o.id} ${o.customer}`))}"`;const disabled=o.queue==="WAITING"||o.queue==="VERIFYING";return ds24ListRow({title:o.id,subtitle:`${o.customer} · ${o.warehouse}`,trailing:status,attrs:`data-io05-order="${escapeAttribute(o.id)}" ${attrs}`,type:'Navigation',state:disabled?'Disabled':'Default',disabled});}).join('');
  const search=ds24Search(io05Query,'data-io05-search','Tìm mã đơn hoặc khách hàng');
  const chips=`<div class="bj05-chip-scroll" aria-label="Lọc đơn cần lấy" data-composed-from="VChip">${filters.map(([k,l])=>ds24Chip(k,l,io05QueueFilter===k,'data-io05-filter')).join('')}</div>`;
  const body=`${search}${chips}${rows?`<section class="ds24-list-stack bj05-queue" data-composed-from="DS v2 / List Row,VBadge">${rows}</section>`:''}<div data-io05-filter-empty ${filtered.length?'hidden':''}>${ioEmpty("Không tìm thấy đơn phù hợp","Thử mã đơn, tên khách hàng hoặc đổi bộ lọc.")}</div>`;
  return appShell({title:"Đơn cần lấy hàng",subtitle,body,back:false});
}
function render026IO05(state){
  if(activeFlowId!=="UIF-05") return renderGeneric(screens.find(s=>s.id==="SCR-026"),state);
  if(state==="PERMISSION_DENIED") return appShell({title:"Hàng cần lấy",body:deniedBody(),centered:true});
  if(state==="LOADING") return appShell({title:"Hàng cần lấy",body:loadingBody()});
  if(state==="STALE_RECOVERED") io05ApplyStaleRecovery();
  const order=io05CurrentOrder(); const lines=io05CurrentLines(); const waiting=order.queue==="WAITING"||state==="SHORTAGE";const verifying=order.queue==="VERIFYING";
  const context=ds24InfoGroup('Thông tin đơn',`${ds24InfoRow('Đơn',order.id)}${ds24InfoRow('Khách hàng',order.customer)}${ds24InfoRow('Kho',order.warehouse)}`,'bj05-context');
  const corrections=io05AllAllocations(order).filter(({allocation})=>io05CorrectionPending(allocation)).map(({line,allocation})=>io05CorrectionText(line,allocation)).filter(Boolean);
  const stale=corrections.length?vBanner("warning","Cần điều chỉnh hàng đang cầm",corrections.join(' ')):"";
  const shortage=waiting?vBanner("warning","Chờ đơn bán xử lý","Đơn chưa đủ hàng để tiếp tục. Kho không tự đổi kho hoặc giảm lượng của đơn."):"";
  const verification=verifying?vBanner("warning","Đang xác minh bàn giao","Không lấy hoặc bàn giao lại đơn này cho tới khi kết quả lần bàn giao trước được xác minh."):"";
  const rows=lines.map(l=>{const lotItems=l.allocations.filter(a=>a.lot);const lots=lotItems.length===1?`Lô ${lotItems[0].lot}`:(lotItems.length>1?`${lotItems.length} lô`:"Không theo lô");const progress=`${io05LinePicked(l)}/${io05LineRemaining(l)} ${l.uom}`;const disabled=waiting||verifying||io05LineRemaining(l)<=0;return ds24ListRow({title:l.name,subtitle:`${l.code} · ${lots}`,trailing:`<strong class="bj05-row-quantity">${io05LineRemaining(l)<=0?'Đã bàn giao':progress}</strong>`,leading:'package',attrs:`data-io05-line="${escapeAttribute(l.id)}"`,type:'Navigation',state:disabled?'Disabled':'Default',disabled});}).join('');
  const activeLines=lines.filter(l=>io05LineRemaining(l)>0);const done=activeLines.filter(l=>io05LinePicked(l)>=io05LineRemaining(l)).length;const partialReady=!waiting&&!verifying&&order.partialHandoverAllowed&&io05OrderPickedTotal(order)>0&&done<activeLines.length;const partialHint=partialReady?`<p class="bj05-decision-note" data-ds-component="VText"><strong>Có thể bàn giao phần đã lấy.</strong> Phần còn lại tiếp tục ở đơn này.</p>`:"";
  const body=`${context}${stale}${shortage}${verification}<section class="bj05-section" data-ds-component="VSection" data-composed-from="DS v2 / List Row">${ds24SectionTitle("Hàng cần lấy",verifying?'Đang xác minh':waiting?'Chờ đơn bán xử lý':`${done}/${activeLines.length} dòng đã lấy đủ`)}<div class="ds24-list-stack">${rows}</div></section>${partialHint}<p class="bj05-business-note" data-ds-component="VText">Tồn vật lý chỉ giảm khi xác nhận bàn giao.</p>`;
  return appShell({title:"Hàng cần lấy",body,actions:waiting||verifying?"":primaryFooter("Rà soát bàn giao",'data-io05-action="review-handover"',!io05CanReview())});
}
function bj05PickEditorSheet(line,allocation){
  if(!io05PickEditorOpen||!allocation)return "";
  const meta=allocation.lot?io05EligibleLotMeta(allocation,allocation.lot):null;const label=allocation.lot?`Lô ${allocation.lot}`:"Không theo lô";const step=Number(line.quantityStep||1);const helper=`Tối đa ${allocation.allocatedQty} ${line.uom}`;const canChange=Number(allocation.consumedQty||0)<=0&&allocation.suggestedLot&&allocation.eligibleLots?.some(x=>(typeof x==='string'?x:x.code)!==allocation.lot);
  const c=allocation.physicalCorrection;const correction=io05CorrectionPending(allocation)?`${vBanner("warning","Cần xác nhận điều chỉnh vật lý",io05CorrectionText(line,allocation),"","Compact")}${Number(allocation.pickedQty||0)>=Number(c.repickQty||0)?`<button class="button button--secondary button--full" data-io05-action="confirm-physical-correction" type="button" data-ds-component="VButton">Xác nhận đã điều chỉnh hàng</button>`:''}`:"";
  return `<div class="sheet-backdrop bj05-pick-editor-backdrop" data-io05-pick-editor-backdrop><section class="bottom-sheet bj05-pick-editor-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="Cập nhật lượng đã lấy"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(label)}</h3></div><div class="sheet-content bj05-pick-editor-sheet__content"><p class="bj05-pick-editor-sheet__meta">${[meta?`HSD ${io05ExpiryDisplay(meta)}`:"",`Cần lấy ${allocation.allocatedQty} ${line.uom}`].filter(Boolean).map(esc).join(' · ')}</p>${correction}${ds24TextField('Đã lấy',io05PickDraft,`data-io05-pick-draft type="number" min="${allocation.consumedQty||0}" max="${allocation.allocatedQty}" step="${step}" inputmode="decimal"`,helper)}${canChange?`<button class="button button--secondary bj05-pick-editor-sheet__change" data-io05-open-override="${escapeAttribute(allocation.id)}" type="button" data-ds-component="VButton">Đổi lô</button>`:""}<button class="button button--primary bj05-pick-editor-sheet__save" data-io05-action="update-pick-allocation" type="button" data-ds-component="VButton" ${Number(io05PickDraft)<Number(allocation.consumedQty||0)||Number(io05PickDraft)>Number(allocation.allocatedQty)?'disabled':''}>Cập nhật</button></div></section></div>`;
}
function render027IO05(state){
  if(activeFlowId!=="UIF-05") return renderGeneric(screens.find(s=>s.id==="SCR-027"),state);
  if(state==="PERMISSION_DENIED") return appShell({title:"Chi tiết lấy hàng",body:deniedBody(),centered:true});
  const line=io05CurrentLine(); if(!line) return appShell({title:"Chi tiết lấy hàng",body:ioEmpty("Không còn hàng cần lấy","Quay lại danh sách để chọn đơn khác."),centered:true});
  const productHead=bj05ReadOnlyListRow({title:line.name,subtitle:`${line.code} · ${line.uom}`,leading:'package',attrs:'data-ds-role="picking-product-summary" data-layout-role="product-context"',density:'Compact',extraClass:'bj05-pick-product-row'});
  const remainingFact=`<section class="bj05-section bj05-remaining-fact" data-ds-component="VSection" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow('Còn cần lấy',`${io05LineRemaining(line)} ${line.uom}`,true)}</section>`;
  const rows=line.allocations.map(a=>{const changed=a.lot!==a.suggestedLot;const label=a.lot?`Lô ${a.lot}`:"Không theo lô";const progress=`Cần ${a.allocatedQty} ${line.uom} · Đã lấy ${Number(a.pickedQty||0)} ${line.uom}${Number(a.consumedQty||0)>0?` · Đã bàn giao ${a.consumedQty}`:''}`;return ds24ListRow({title:label,subtitle:`${changed?'Đã đổi · ':''}${progress}`,attrs:`data-io05-pick-allocation="${escapeAttribute(a.id)}"`,type:'Navigation',state:'Default',density:'Default'});}).join('');
  const allocation=io05CurrentAllocation();const hasCorrection=line.allocations.some(a=>io05CorrectionPending(a));const stateNotice=state==="STALE_RECOVERED"&&!hasCorrection?vBanner("warning","Danh sách lô đã thay đổi","Kiểm lại lô hiện hành trước khi lưu lượng đã lấy."):"";const invalid=line.allocations.some(a=>Number(a.pickedQty||0)>Number(a.allocatedQty||0));
  const body=`${productHead}${remainingFact}${stateNotice}<section class="bj05-section bj05-pick-lot-group" data-ds-component="VSection">${ds24SectionTitle("Lấy theo lô",`${line.allocations.length} lô`)}<div class="ds24-list-stack bj05-pick-lot-list">${rows}</div></section><p class="bj05-pick-note" data-ds-component="VText">Chọn từng lô để cập nhật lượng đã lấy. Tồn vật lý chỉ giảm sau khi xác nhận bàn giao.</p>${bj05PickEditorSheet(line,allocation)}${bj05OverrideSheet(line,allocation)}`;
  return appShell({title:"Chi tiết lấy hàng",body,actions:primaryFooter("Lưu lượng đã lấy",'data-io05-action="save-pick"',invalid||hasCorrection)});
}
function render028IO05(state){
  if(activeFlowId!=="UIF-05") return renderGeneric(screens.find(s=>s.id==="SCR-028"),state);
  if(state==="PERMISSION_DENIED") return appShell({title:"Rà soát bàn giao",body:deniedBody(),centered:true});
  const order=io05CurrentOrder();const context=ds24InfoGroup('Thông tin đơn',`${ds24InfoRow('Đơn',order.id)}${ds24InfoRow('Khách hàng',order.customer)}${ds24InfoRow('Kho',order.warehouse)}`,'bj05-context');
  if(state==="SOURCE_CHANGED") return appShell({title:"Rà soát bàn giao",body:`${vBanner("warning","Thông tin lấy hàng đã thay đổi","Không thể dùng bản rà soát hiện tại. Hãy xem lại hàng cần lấy đã được cập nhật.")}${context}`,actions:primaryFooter("Xem hàng cần lấy đã cập nhật",'data-io05-action="back-to-pick"')});
  io05SyncHandover();const partial=state==="PARTIAL_ALLOWED"||order.partialHandoverAllowed;const blocked=state==="PARTIAL_BLOCKED";const pickedRows=io05AllAllocations(order).filter(({allocation})=>io05AllocationRemainingPicked(allocation)>0&&!io05CorrectionPending(allocation));
  const byLine=new Map();pickedRows.forEach(({line,allocation})=>{if(!byLine.has(line.id))byLine.set(line.id,{line,allocations:[]});byLine.get(line.id).allocations.push(allocation);});
  const lines=[...byLine.values()].map(({line,allocations})=>{const allocationRows=allocations.map(a=>{const available=io05AllocationRemainingPicked(a);const qty=Number(io05HandoverByAllocation[a.id]??available);const label=a.lot?`Lô ${a.lot}`:'Không theo lô';const step=Number(line.quantityStep||1);const control=partial&&!blocked?ds24TextField('Lượng thực giao',qty,`data-io05-handover-allocation="${escapeAttribute(a.id)}" type="number" min="0" max="${available}" step="${step}" inputmode="decimal" aria-label="Lượng thực giao ${escapeAttribute(label)}"`,`Tối đa ${available} ${line.uom}`):'';return `<div class="bj05-handover-allocation">${ds24KeyValueRow(label,`${available} ${line.uom}`)}${control}</div>`;}).join('');const productSummary=ds24ContextStatusRow({title:line.name,subtitle:`${line.code} · ${line.uom}`,label:'Đã lấy',tone:'Success',leading:'package'});return `<div class="bj05-handover-product ds24-grouped-subgroup">${productSummary}<div class="bj05-handover-allocation-list">${allocationRows}</div></div>`;}).join('');
  const summary=`<section class="bj05-summary" data-io05-handover-summary>${ds24KeyValueRow('Trong lần này',`${io05HandoverProductCount()} dòng hàng`,true,'data-io05-summary-in-this')}${ds24KeyValueRow('Chưa hoàn tất',`${io05RemainingProductCountAfterHandover()} dòng hàng`,false,'data-io05-summary-remaining')}</section>`;const banner=blocked?vBanner("error","Đơn này yêu cầu giao đủ","Chưa thể bàn giao một phần. Phần thiếu phải được đơn bán xử lý trước."):"";const collection=ds24GroupedCollection(lines,"bj05-handover-list bj05-grouped-collection bj05-grouped-collection--handover","DS v2 / List Row,DS v2 / Key-value Row,VTextField");const content=pickedRows.length?`<section class="bj05-section">${ds24SectionTitle("Xác nhận hàng đã giao",partial&&!blocked?"Nhập lượng thực tế theo từng lô":"Đối chiếu theo lượng đã lấy")}${collection}</section>`:ioEmpty("Chưa có hàng đã lấy","Quay lại Hàng cần lấy để xác nhận lượng đã lấy trước khi bàn giao.");const body=`${banner}${context}<section class="bj05-section">${ds24SectionTitle("Bàn giao lần này")}${summary}</section>${content}<p class="field-error bj05-field-error" data-io05-handover-error hidden></p><p class="bj05-business-note" data-ds-component="VText">Xác nhận khi hàng đã giao thực tế. Tồn vật lý chỉ giảm sau bước này.</p>`;
  return appShell({title:"Rà soát bàn giao",body,actions:primaryFooter("Xác nhận đã bàn giao",'data-io05-action="confirm-handover"',blocked||io05HandoverInvalid()||io05HandoverTotal()<=0)});
}
function render029IO05(state){
  if(activeFlowId!=="UIF-05") return renderGeneric(screens.find(s=>s.id==="SCR-029"),state);
  const order=io05CurrentOrder();const r=io05LastResult;const orderId=r?.orderId||io05SelectedOrderId;const customer=r?.customer||order.customer;
  if(state==="UNKNOWN"){io05MarkUnknown(order);return appShell({title:"Kết quả bàn giao",body:ds24Result("Đang xác minh kết quả","Không gửi lại bàn giao. Đơn được khóa khỏi lấy/bàn giao lại cho tới khi kết quả này được xác minh.",[["Đơn",orderId],["Trạng thái","Đang xác minh bàn giao"],["Tồn vật lý","Chưa kết luận"]],"warning"),centered:true,back:false,actions:primaryFooter("Về danh sách đơn cần lấy",'data-io05-action="result-to-queue"')});}
  if(state==="REJECTED_EXECUTION") return appShell({title:"Kết quả bàn giao",body:ds24Result("Chưa thể bàn giao","Dữ liệu hiện hành đã thay đổi nên chưa ghi giảm tồn. Hãy xem lại hàng cần lấy trước khi xác nhận lần nữa.",[["Đơn",orderId],["Tồn vật lý","Không thay đổi"]],"warning"),centered:true,back:false,actions:primaryFooter("Xem hàng cần lấy đã cập nhật",'data-io05-action="back-to-pick"')});
  if(state==="PERMISSION_DENIED") return appShell({title:"Kết quả bàn giao",body:ds24Result("Không có quyền bàn giao","Tồn kho không thay đổi. Liên hệ người có quyền phù hợp nếu cần tiếp tục.",[["Đơn",orderId],["Tồn vật lý","Không thay đổi"]],"danger"),centered:true,back:false,actions:primaryFooter("Về danh sách đơn cần lấy",'data-io05-action="result-to-queue"')});
  const partial=state==="PARTIAL_COMPLETED"||(r&&!r.full);const title=partial?"Đã bàn giao một phần":"Đã bàn giao toàn bộ";const desc=partial?"Đã ghi giảm tồn theo đúng lượng thực bàn giao. Phần còn lại tiếp tục ở đơn này.":"Tồn vật lý đã giảm theo đúng lượng và lô thực tế bàn giao.";const summary=ds24Result(title,desc,[["Đơn",orderId],["Khách hàng",customer],["Bàn giao lúc",r?.confirmedAt||"—"]],"success");
  return appShell({title:"Kết quả bàn giao",body:`${summary}${bj05ResultDetails(r)}`,centered:false,back:false,actions:primaryFooter(partial?"Tiếp tục phần còn lại":"Về danh sách đơn cần lấy",partial?'data-io05-action="continue-remaining"':'data-io05-action="result-to-queue"')});
}

function io06DsTone(tone="neutral"){
  const t=String(tone||"neutral").toLowerCase();
  return t==="success"?"Success":t==="warning"?"Warning":t==="danger"||t==="error"?"Danger":t==="info"?"Info":"Neutral";
}
function io06TextField(label,value,attrs="",helper="",state="Default"){
  const display=value===null||value===undefined?"":value;
  return `<label class="io06-field" data-ds-component="VTextField" data-figma-node="522:7186" data-ds-prop-state="${state}"><span class="io06-field__label">${esc(label)}</span><span class="io06-field__control"><input value="${escapeAttribute(display)}" ${attrs}></span>${helper?`<small class="io06-field__helper">${esc(helper)}</small>`:""}</label>`;
}
function io06Textarea(label,value,attrs="",helper=""){
  return `<label class="io06-textarea" data-ds-component="VTextarea" data-figma-node="522:7212" data-ds-prop-state="${value?'Filled':'Default'}"><span class="io06-field__label">${esc(label)}</span><textarea class="io06-textarea__control" rows="3" ${attrs}>${esc(value||"")}</textarea>${helper?`<small class="io06-field__helper">${esc(helper)}</small>`:""}</label>`;
}
function io06SelectionRow({title,subtitle="",selected=false,attrs="",disabled=false,leading=null}){
  const trailing=`<span class="io06-radio${selected?' is-selected':''}" aria-hidden="true"></span>`;
  return ds24ListRow({title,subtitle,trailing,leading,attrs,type:"Selection",state:disabled?"Disabled":selected?"Selected":"Default",interactive:true,disabled,extraClass:`io06-selection-row${selected?' is-selected':''}`});
}
function io06RequestRow(r){
  const target=r.phase==="CLASSIFICATION"?"SCR-033":"SCR-031";
  const tone=r.queue==="WAITING"?'Warning':r.status.includes('phân loại')?'Info':r.status.includes('ngoại lệ')?'Warning':'Neutral';
  const label=r.queue==="WAITING"?"Chờ duyệt lô":r.status;
  return ds24ListRow({title:r.id,subtitle:`${r.customer} · ${r.source}`,trailing:ds24Badge(label,tone),leading:null,attrs:`data-io06-request="${escapeAttribute(r.id)}" data-io06-target="${target}" data-io06-search-text="${escapeAttribute(ioNormalizeSearch(`${r.id} ${r.source} ${r.customer}`))}"`,type:'Navigation',state:'Default'});
}
function render030IO06(state){
  if(activeFlowId!=="UIF-06") return renderGeneric(screens.find(s=>s.id==="SCR-030"),state);
  const subtitle="Yêu cầu trả đủ điều kiện để Kho xử lý";
  if(state==="PERMISSION_DENIED") return appShell({title:"Hàng khách trả",subtitle,body:deniedBody(),centered:true,back:false});
  if(state==="LOADING") return appShell({title:"Hàng khách trả",subtitle,body:loadingBody(),back:false});
  io06Requests.forEach(io06RefreshRequestState);
  const active=io06Requests.filter(r=>!r.closed);
  const filtered=active.filter(r=>(io06QueueFilter==="ALL"||r.queue===io06QueueFilter)&&ioMatchesSearch(io06Query,`${r.id} ${r.source} ${r.customer}`));
  const rows=filtered.map(io06RequestRow).join('');
  const filters=[["ALL","Tất cả"],["ACTIONABLE","Cần xử lý"],["WAITING","Đang chờ"]];
  const body=`${ds24Search(io06Query,'data-io06-search','Tìm yêu cầu, đơn bán hoặc khách hàng')}<div class="io06-chip-scroll" aria-label="Lọc hàng khách trả" data-composed-from="VChip">${filters.map(([k,l])=>ds24Chip(k,l,io06QueueFilter===k,'data-io06-filter')).join('')}</div>${rows?`<section class="ds24-list-stack io06-queue" data-composed-from="DS v2 / List Row,VBadge">${rows}</section>`:''}<div data-io06-filter-empty ${filtered.length?'hidden':''}>${ioEmpty("Không tìm thấy yêu cầu phù hợp","Thử từ khóa khác hoặc đổi bộ lọc.")}</div>`;
  return appShell({title:"Hàng khách trả",subtitle,body,back:false});
}
function io06ReturnLineRow(line,waiting=false){
  const approval=io06LineApprovalState(line);let badge="",tone="Neutral";
  if(approval==="PENDING"){badge="Chờ duyệt lô";tone="Warning";}else if(approval==="REJECTED"){badge="Bị từ chối";tone="Danger";}else if(approval==="APPROVED"){badge="Đã duyệt";tone="Success";}else if(approval==="DRAFT"){badge="Chờ gửi duyệt";tone="Warning";}else if(line.verified){badge="Đã kiểm";tone="Success";}
  const sourceLot=line.expectedLot?`Lô giao ${line.expectedLot}`:"Không theo lô";
  const actual=line.verified&&line.actualLot&&line.actualLot!==line.expectedLot?` · Thực nhận ${line.actualLot}`:"";
  const qty=line.verified?`${line.qty} ${line.uom}`:`Tối đa ${line.remaining} ${line.uom}`;
  return ds24ListRow({title:line.name,subtitle:`${line.code} · ${sourceLot}${actual}`,trailing:`<span class="io06-row-trailing"><strong>${esc(qty)}</strong>${badge?ds24Badge(badge,tone):''}</span>`,leading:'package',attrs:`data-io06-line="${escapeAttribute(line.id)}"`,type:'Navigation',state:waiting?'Disabled':'Default',disabled:waiting});
}
function io06QtyDisplay(qty){return qty==null||qty===""||!Number.isFinite(Number(qty))?"—":Number(qty).toLocaleString("vi-VN");}
function io06ResultGroupsHtml(lines,{classified=false}={}){
  const groups=new Map();
  for(const line of lines){const key=`${line.name}|${line.code}|${line.uom}`;if(!groups.has(key))groups.set(key,{name:line.name,code:line.code,uom:line.uom,lines:[]});groups.get(key).lines.push(line);}
  const statusLabel=classified?'Đã phân loại':'Đã nhận';
  const statusTone=classified?'Success':'Info';
  const subgroups=[...groups.values()].map(g=>{const productSummary=ds24ContextStatusRow({title:g.name,subtitle:`${g.code} · ${g.uom}`,label:statusLabel,tone:statusTone,leading:'package',attrs:'data-layout-role="io06-result-product-summary" data-ds-role="return-result-product-summary"'});const rows=g.lines.map(line=>{const lot=line.actualLot?`Lô ${line.actualLot}`:"Không theo lô";if(!classified)return ds24InfoRow(lot,`${io06QtyDisplay(line.qty)} ${line.uom}`);const c=line.classification||{};const states=[["Bán được",c.sellable],["Cách ly",c.quarantine],["Hỏng",c.damaged],["Hết hạn",c.expired]].filter(([,q])=>Number(q)>0).map(([label,q])=>ds24InfoRow(`${lot} · ${label}`,`${q} ${line.uom}`)).join("");return states||ds24InfoRow(lot,`0 ${line.uom}`);}).join("");return `<div class="io06-result-group ds24-grouped-subgroup" data-layout-role="return-result-product-subgroup" data-composed-from="DS v2 / List Row,DS v2 / Info Row">${productSummary}<div class="io06-result-rows">${rows}</div></div>`;}).join("");
  return ds24GroupedCollection(subgroups,"io06-result-groups io06-grouped-collection io06-grouped-collection--results","DS v2 / List Row,DS v2 / Info Row");
}
function render031IO06(state){
  if(activeFlowId!=="UIF-06") return renderGeneric(screens.find(s=>s.id==="SCR-031"),state);
  const entrySubtitle=entryMode==="return-task"?"Yêu cầu được giao cho Kho":null;
  if(state==="PERMISSION_DENIED") return appShell({title:"Hàng khách trả",subtitle:entrySubtitle,body:deniedBody(),centered:true});
  if(state==="LOADING") return appShell({title:"Hàng khách trả",subtitle:entrySubtitle,body:loadingBody()});
  const req=io06CurrentRequest();io06RefreshRequestState(req);const lines=io06CurrentLines();const waiting=req.queue==="WAITING";
  const blocker=["CONFLICT","LOCKED","RETURN_CAP_CHANGED","SOURCE_CHANGED"].includes(state)?vBanner("warning",state==="RETURN_CAP_CHANGED"?"Lượng được nhận đã thay đổi":"Yêu cầu đã thay đổi",state==="RETURN_CAP_CHANGED"?"Làm mới và kiểm lại từng dòng trước khi tiếp tục.":"Làm mới để dùng dữ liệu hiện hành.","",state==="RETURN_CAP_CHANGED"?"Default":"Compact"):"";
  const pending=io06PendingCasesForRequest(req.id).length;
  const waitBanner=waiting?vBanner("warning",`Đang chờ duyệt ${pending} ngoại lệ lô`,`Các dòng đã kiểm được giữ nguyên; hiện chưa thể ghi nhận.`,"","Compact"):"";
  const verifiedCount=lines.filter(io06LinePhysicalValid).length;
  const context=ds24ContextStatusRow({title:req.id,subtitle:`${req.customer} · ${req.source}`,label:`${verifiedCount}/${lines.length} đã kiểm`,tone:'Neutral',leading:null,attrs:'data-layout-role="return-request-context"'});
  const rows=lines.map(line=>io06ReturnLineRow(line,waiting)).join('');
  const rejected=lines.some(l=>io06LineApprovalState(l)==="REJECTED");
  const body=`${context}${blocker}${waitBanner}<section class="io06-section" data-ds-component="VSection">${ds24SectionTitle("Hàng thực nhận")}<div class="ds24-list-stack io06-return-list">${rows}</div></section>${rejected?`<p class="io06-note">Mở dòng bị từ chối để sửa trước khi gửi lại.</p>`:""}<p class="io06-note">Chỉ ghi nhận khi tất cả dòng hợp lệ; tồn kho chưa đổi trong lúc kiểm.</p>`;
  let actions="";
  if(["CONFLICT","LOCKED","RETURN_CAP_CHANGED","SOURCE_CHANGED"].includes(state)) actions=primaryFooter("Làm mới yêu cầu",'data-io06-action="refresh-return-request"');
  else if(!waiting&&io06RequestCanSubmitExceptions(req)) actions=primaryFooter("Gửi ngoại lệ duyệt",'data-io06-action="submit-return-exceptions"');
  else if(!waiting) actions=primaryFooter("Ghi nhận hàng trả",'data-io06-action="commit-receipt"',!io06ReceiptReady(req));
  return appShell({title:"Hàng khách trả",subtitle:entrySubtitle,body,actions});
}
function render032IO06(state){
  if(activeFlowId!=="UIF-06") return renderGeneric(screens.find(s=>s.id==="SCR-032"),state);
  const line=io06ActiveLine();if(!line)return appShell({title:"Chi tiết hàng trả",body:ioEmpty("Không có dòng hàng","Quay lại yêu cầu để chọn dòng hàng."),centered:true});
  if(state==="PERMISSION_DENIED") return appShell({title:"Chi tiết hàng trả",body:deniedBody(),centered:true});
  const caseState=io06LineApprovalState(line);const pending=caseState==="PENDING";const approved=caseState==="APPROVED";const rejected=caseState==="REJECTED";const capInvalid=Number(line.qty||0)>Number(line.remaining||0);const mismatch=io06Mismatch(line);
  const status=pending?vBanner("warning","Ngoại lệ đang chờ duyệt","Dữ liệu đã gửi duyệt đang được khóa.","","Compact"):approved?vBanner("success","Ngoại lệ lô đã được duyệt","Thay đổi dữ liệu sẽ cần duyệt lại.","","Compact"):rejected?vBanner("error","Ngoại lệ lô bị từ chối","Cập nhật lô hoặc bằng chứng rồi gửi lại.","","Compact"):"";
  const identity=ds24ContextStatusRow({title:line.name,subtitle:`${line.code} · ${line.uom}`,label:`Còn ${line.remaining} ${line.uom}`,tone:'Neutral',attrs:'data-layout-role="return-line-context"'});
  const facts=ds24InfoGroup('',`${line.comboName?ds24InfoRow('Thuộc',line.comboName):''}${ds24InfoRow('Đã giao',`${line.shipped} ${line.uom}`)}${line.expectedLot?ds24InfoRow('Lô giao',line.expectedLot):''}${ds24InfoRow('Đã nhận trả trước',`${line.returnedBefore} ${line.uom}`)}`,'io06-source-facts');
  const qty=io06TextField('Số lượng thực nhận *',line.qty===null||line.qty===undefined?'':line.qty,`data-io06-qty type="number" min="0" max="${line.remaining}" placeholder="0" inputmode="numeric" ${pending?'disabled':''}`,`Tối đa ${line.remaining} ${line.uom}`,pending?'Disabled':'Default');
  let lotControl="";
  if(line.expectedLot){
    const otherSelected=line.actualLotMode==="OTHER"||Boolean(line.actualLot&&String(line.actualLot).toUpperCase()!==String(line.expectedLot).toUpperCase());
    lotControl=`<section class="io06-section">${ds24SectionTitle('Lô thực nhận')}<div class="io06-selection-list">${io06SelectionRow({title:`Lô ${line.expectedLot}`,subtitle:'Đúng lô đã giao',selected:!otherSelected&&line.actualLot===line.expectedLot,attrs:`data-io06-select-actual-lot="${escapeAttribute(line.expectedLot)}"`,disabled:pending})}${io06SelectionRow({title:'Lô khác',subtitle:'Thực nhận khác lô đã giao',selected:otherSelected,attrs:'data-io06-select-other-lot',disabled:pending})}</div></section>${otherSelected?io06TextField('Mã lô thực nhận *',line.actualLot||'',`data-io06-actual-lot placeholder="Nhập hoặc quét mã lô" ${pending?'disabled':''}`,'',pending?'Disabled':'Default'):''}`;
  }
  const reasonLabels=[["ACTUAL_DIFF","Hàng thực tế khác thông tin giao"],["ORIGINAL_UNKNOWN","Không xác định được lô gốc"],["HISTORY_MISMATCH","Chứng từ/lịch sử lô không khớp"],["OTHER","Khác"]];
  const evidence=mismatch?`${vBanner("warning","Lô thực nhận khác lô đã giao",`Cần lý do, ảnh nhãn lô và phê duyệt trước khi ghi nhận.`,"","Compact")}<section class="io06-section">${ds24SectionTitle('Lý do ngoại lệ')}<div class="io06-selection-list io06-reason-list">${reasonLabels.map(([k,l])=>io06SelectionRow({title:l,subtitle:'',selected:line.reasonCode===k,attrs:`data-io06-reason="${k}"`,disabled:pending,leading:'circleAlert'})).join('')}</div></section>${line.reasonCode==='OTHER'?io06Textarea('Mô tả thêm *',line.reasonDetail||'',`data-io06-reason-detail ${pending?'disabled':''}`,'Nêu ngắn gọn chênh lệch thực tế.'):''}<label class="io06-file-field" data-ds-component="VFileDropZone"><span class="io06-field__label">Ảnh nhãn lô thực nhận *</span><span class="io06-file-control">${icon('fileText','icon--sm')}<span><strong>${esc(line.evidenceFile||'Chọn ảnh nhãn lô')}</strong><small>${line.evidenceFile?'Nhấn để thay ảnh':'Ảnh rõ mã lô'}</small></span><input data-io06-evidence-file type="file" accept="image/*" ${pending?'disabled':''}/></span></label>${line.evidenceData?`<div class="io-evidence-preview"><img src="${line.evidenceData}" alt="Ảnh nhãn lô thực nhận"/><span>${esc(line.evidenceFile||'Ảnh nhãn lô')}</span></div>`:""}`:"";
  const body=`${identity}${facts}${status}${qty}<p class="field-error" data-io06-cap-error ${capInvalid?'':'hidden'}>Không thể nhận vượt ${line.remaining} ${line.uom}.</p>${lotControl}${evidence}`;
  let action="";const evidenceValid=io06LineEvidenceReady(line);if(!pending){if(mismatch&&!approved)action=primaryFooter("Lưu ngoại lệ",'data-io06-action="save-return-exception"',Number(line.qty||0)<=0||capInvalid||!evidenceValid);else action=primaryFooter("Xong",'data-io06-action="save-return-line"',Number(line.qty||0)<=0||capInvalid||Boolean(line.expectedLot&&!line.actualLot));}
  return appShell({title:"Chi tiết hàng trả",body,actions:action});
}
function render034IO06(state){
  if(activeFlowId!=="UIF-06") return renderGeneric(screens.find(s=>s.id==="SCR-034"),state);
  if(state==="PERMISSION_DENIED") return appShell({title:"Ngoại lệ lô cần duyệt",subtitle:"Việc dành cho người phê duyệt",body:deniedBody(),centered:true,back:false});
  const pendingCases=io06ApprovalCases.filter(c=>c.status==="PENDING");
  if(io06ApproverListMode||state==="TASK_LIST"||!io06SelectedApprovalCase()){
    const rows=pendingCases.map(c=>{const l=io06ApprovalCaseLine(c);const req=io06Requests.find(r=>r.id===c.requestId);return ds24ListRow({title:l?.name||'Mặt hàng',subtitle:`${req?.id||c.requestId} · ${req?.customer||''}`,trailing:ds24Badge('Chờ quyết định','Warning'),leading:'package',attrs:`data-io06-approval-case="${escapeAttribute(c.id)}"`,type:'Navigation'});}).join('');
    const body=`<section class="io06-section">${ds24SectionTitle("Cần bạn quyết định",`${pendingCases.length} ngoại lệ`)}${rows?`<div class="ds24-list-stack">${rows}</div>`:ioEmpty("Không còn ngoại lệ chờ duyệt","Các quyết định đã hoàn tất hoặc chưa có yêu cầu mới.")}</section>`;
    return appShell({title:"Ngoại lệ lô cần duyệt",subtitle:"Việc dành cho người phê duyệt",body,back:false});
  }
  const c=io06SelectedApprovalCase();const line=io06ApprovalCaseLine(c);const req=io06Requests.find(r=>r.id===c?.requestId);if(!c||!line)return appShell({title:"Duyệt ngoại lệ lô",body:ioEmpty("Không tìm thấy ngoại lệ","Quay lại danh sách phê duyệt."),centered:true,backAction:"exit-io06-approval"});
  const labels={ACTUAL_DIFF:"Hàng thực tế khác thông tin giao",ORIGINAL_UNKNOWN:"Không xác định được lô gốc",HISTORY_MISMATCH:"Chứng từ/lịch sử lô không khớp",OTHER:"Khác"};const snap=c.snapshot;
  const rejectSheet=io06RejectOpen?`<div class="sheet-backdrop io06-sheet-backdrop" data-io06-reject-backdrop><section class="bottom-sheet io06-bottom-sheet io06-reject-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true"><div class="sheet-handle"></div><div class="sheet-title"><h3>Từ chối ngoại lệ</h3></div><div class="sheet-content io06-sheet-content">${io06Textarea('Lý do từ chối *',io06RejectReason,'data-io06-reject-reason placeholder="Nhập lý do"','Bắt buộc để lưu quyết định.')}<div class="io06-sheet-actions"><button class="button button--secondary" data-io06-action="close-reject" type="button">Hủy</button><button class="button button--primary" data-io06-action="confirm-reject" type="button" ${io06RejectReason.trim()?'':'disabled'}>Xác nhận từ chối</button></div></div></section></div>`:"";
  const final=c.status!=="PENDING";const decisionBanner=c.status==="APPROVED"?vBanner("success","Đã duyệt ngoại lệ","Quyết định đã được khóa theo snapshot.","","Compact"):c.status==="REJECTED"?vBanner("error","Đã từ chối ngoại lệ",`Lý do: ${c.decisionReason||'—'}`,"","Compact"):"";
  const identity=ds24ContextStatusRow({title:line.name,subtitle:`${line.code} · ${snap.uom}`,label:`${snap.qty} ${snap.uom}`,tone:'Neutral'});
  const facts=ds24InfoGroup('Thông tin ngoại lệ',`${ds24InfoRow('Yêu cầu',req?.id||c.requestId)}${ds24InfoRow('Khách hàng',req?.customer||'—')}${ds24InfoRow('Lô đã giao',snap.expectedLot||'—')}${ds24InfoRow('Lô thực nhận',snap.actualLot||'—')}`,'io06-approval-facts');
  const reason=ds24InfoGroup('Căn cứ quyết định',`${ds24InfoRow('Lý do',labels[snap.reasonCode]||'—')}${snap.reasonCode==='OTHER'&&snap.reasonDetail?ds24InfoRow('Mô tả',snap.reasonDetail):''}`,'io06-approval-reason');
  const evidence=snap.evidenceData?`<div class="io06-evidence-card"><img src="${snap.evidenceData}" alt="Ảnh nhãn lô thực nhận"><span>${esc(snap.evidenceFile||'Ảnh nhãn lô')}</span></div>`:`<div class="io06-file-summary">${icon('fileText','icon--sm')}<span>${esc(snap.evidenceFile||'Không có ảnh')}</span></div>`;
  const body=`${decisionBanner}${identity}${facts}${reason}<section class="io06-section">${ds24SectionTitle('Ảnh nhãn lô thực nhận')} ${evidence}</section>${final?'':ioSecondary("Từ chối",'data-io06-action="open-reject"')}${rejectSheet}`;
  return appShell({title:"Duyệt ngoại lệ lô",body,back:true,backAction:"exit-io06-approval",actions:final?primaryFooter("Về danh sách phê duyệt",'data-io06-action="exit-approval-detail"'):primaryFooter("Duyệt ngoại lệ",'data-io06-action="approve-exception"')});
}
function render033IO06(state){
  if(activeFlowId!=="UIF-06") return renderGeneric(screens.find(s=>s.id==="SCR-033"),state);
  if(state==="PERMISSION_DENIED") return appShell({title:"Phân loại hàng trả",body:deniedBody(),centered:true});
  const req=io06CurrentRequest();const lines=io06CurrentLines();const active=io06ActiveLine();
  if(["CONFLICT","LOCKED","SOURCE_CHANGED"].includes(state))return appShell({title:"Phân loại hàng trả",body:`${vBanner("warning","Dữ liệu hàng trả đã thay đổi","Về danh sách để mở lại dữ liệu hiện hành.","","Compact")}${ds24InfoGroup('',`${ds24InfoRow('Yêu cầu',req.id)}${ds24InfoRow('Đơn bán',req.source)}`,'io06-context')}`,actions:primaryFooter("Về Hàng khách trả",'data-io06-action="result-to-return-queue"')});
  const rows=lines.map(line=>{const valid=io06ClassValid(line,state);const lot=line.actualLot?`Lô ${line.actualLot}`:"Không theo lô";return ds24ListRow({title:line.name,subtitle:`${line.code} · ${lot}`,trailing:`<span class="io06-row-trailing"><strong>${io06ClassTotal(line)}/${io06QtyDisplay(line.qty)} ${line.uom}</strong>${valid?ds24Badge('Đã xong','Success'):''}</span>`,leading:'package',attrs:`data-io06-class-line="${escapeAttribute(line.id)}"`,type:'Navigation'});}).join('');
  let sheet="";if(io06ClassificationOpen&&active){const draft=io06ClassificationDraftFor(active);const total=io06ClassTotal(active,draft);const requiredExpired=Math.max(Number(active.knownExpired||0),state==="EXPIRED_GUARD"?2:0);const expiredGuard=Number(draft.expired||0)<requiredExpired;const feedback=expiredGuard?vBanner("warning","Có hàng hết hạn",`Ít nhất ${requiredExpired} ${active.uom} phải vào nhóm Hết hạn.`,"","Compact"):total>Number(active.qty||0)?vBanner("error","Vượt lượng cần phân loại",`Đang phân loại ${total}/${io06QtyDisplay(active.qty)} ${active.uom}.`,"","Compact"):"";const fields=[["sellable","Bán được"],["quarantine","Cách ly"],["damaged","Hỏng"],["expired","Hết hạn"]].map(([k,l])=>io06TextField(l,draft[k],`data-io06-class="${k}" type="number" min="0" inputmode="numeric"`,'')).join('');const progress=ds24KeyValueRow('Đã phân loại',`${total}/${io06QtyDisplay(active.qty)} ${active.uom}`,false,'data-io06-class-progress');sheet=`<div class="sheet-backdrop io06-sheet-backdrop"><section class="bottom-sheet io06-bottom-sheet io06-classification-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(active.name)}</h3></div><div class="sheet-content io06-sheet-content"><p class="io06-sheet-intro">${active.actualLot?`Lô ${esc(active.actualLot)} · `:""}Phân bổ toàn bộ ${io06QtyDisplay(active.qty)} ${esc(active.uom)} theo tình trạng.</p>${progress}<div class="io06-class-fields">${fields}</div><div data-io06-class-feedback>${feedback}</div><div class="io06-sheet-actions"><button class="button button--secondary" data-io06-action="cancel-classification-item" type="button">Hủy</button><button class="button button--primary" data-io06-action="close-classification-item" type="button" ${io06ClassValid(active,state,draft)?'':'disabled'}>Xong</button></div></div></section></div>`;}
  const doneCount=lines.filter(l=>io06ClassValid(l,state)).length;
  const context=ds24ContextStatusRow({title:req.id,subtitle:`${req.customer} · ${req.source}`,label:`${doneCount}/${lines.length} đã xong`,tone:'Neutral',leading:null,attrs:'data-layout-role="classification-request-context"'});
  const body=`${context}<section class="io06-section">${ds24SectionTitle("Hàng cần phân loại")}<div class="ds24-list-stack">${rows}</div></section>${sheet}`;
  return appShell({title:"Phân loại hàng trả",body,actions:primaryFooter("Hoàn tất phân loại",'data-io06-action="confirm-classification"',!io06AllClassValid(state))});
}
function render035IO06(state){
  if(activeFlowId!=="UIF-06") return renderGeneric(screens.find(s=>s.id==="SCR-035"),state);
  const req=io06CurrentRequest();const lines=io06CurrentLines();
  if(state==="UNKNOWN")return appShell({title:"Kết quả hàng trả",body:ioResult("Đang xác minh kết quả","Không gửi lại thao tác. Hệ thống đang xác minh lần ghi nhận này.",[["Yêu cầu",req.id],["Tồn kho","Chưa kết luận"]],"warning"),centered:true,back:false,actions:primaryFooter("Về Hàng khách trả",'data-io06-action="result-to-return-queue"')});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả hàng trả",body:ioResult("Chưa thể ghi nhận","Dữ liệu hiện hành đã thay đổi; tồn kho chưa bị tác động.",[["Yêu cầu",req.id],["Tồn kho","Không thay đổi"]],"warning"),centered:true,back:false,actions:primaryFooter(req.receiptCommitted?"Xem phần phân loại đã cập nhật":"Xem yêu cầu đã cập nhật",req.receiptCommitted?'data-io06-action="open-classification"':'data-io06-action="back-to-return-request"')});
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả hàng trả",body:ioResult("Không có quyền thực hiện","Tồn kho không thay đổi.",[["Yêu cầu",req.id],["Tồn kho","Không thay đổi"]],"warning"),centered:true,back:false,actions:primaryFooter("Về Hàng khách trả",'data-io06-action="result-to-return-queue"')});
  if(state==="COMPLETED"||req.classified){const body=`<div class="io-result io06-result">${resultHero("Đã phân loại hàng trả","Chỉ phần đủ điều kiện mới trở lại khả dụng.")}${ds24InfoGroup('',`${ds24InfoRow('Yêu cầu',req.id)}${ds24InfoRow('Dòng đã phân loại',`${lines.length}`)}`,'io06-result-summary')}<section class="io06-section">${ds24SectionTitle("Kết quả theo sản phẩm và lô")}${io06ResultGroupsHtml(lines,{classified:true})}</section></div>`;return appShell({title:"Kết quả phân loại hàng trả",body,centered:false,back:false,actions:primaryFooter("Về Hàng khách trả",'data-io06-action="result-to-return-queue"')});}
  const body=`<div class="io-result io06-result">${resultHero("Đã nhận hàng khách trả","Hàng đang chờ phân loại; chưa tự trở lại bán được.")}${ds24InfoGroup('',`${ds24InfoRow('Yêu cầu',req.id)}${ds24InfoRow('Dòng đã nhận',`${lines.length}`)}`,'io06-result-summary')}<section class="io06-section">${ds24SectionTitle("Hàng đã nhận")}${io06ResultGroupsHtml(lines)}</section>${ioSecondary("Để sau",'data-io06-action="result-to-return-queue"')}</div>`;
  return appShell({title:"Đã nhận hàng khách trả",subtitle:"Còn bước phân loại trước khi hoàn tất",body,centered:false,back:false,actions:primaryFooter("Phân loại ngay",'data-io06-action="open-classification"')});
}


// v1.6.0 — Inventory Audit & Control Product correction (UIF-08/UIF-09/UIF-10)
let ic09Filter="ALL";
let ic09Query="";
let ic09Selected="amox";
let ic09Destination="QUARANTINE";
let ic10Selected="amox-l2407";
let ic08ConfirmKind=null;
let ic08Scope="ALL";
let ic08ScopeTarget="";
let ic08ScopeSheetOpen=false;
let ic08ProductSheetOpen=false;
let ic08CutoffDate="2026-09-09";
let ic08CutoffTime="08:00";
let ic08Reason="Kiểm kê định kỳ";
let ic08AssignedCounter="Nguyễn An";
let ic08CancelReason="";
let ic08ReviewReason="";
let ic08KeypadTarget=null;
let ic08KeypadDraft="";
let ic08Counts={amox:"18",glove:"7"};
let ic08Recounts={amox:"18",glove:"7"};
let ic08Evidence={amox:"Kiểm lại kệ, thiếu 2 hộp",glove:"Phát hiện 1 hộp chưa ghi nhận"};
let ic08UnexpectedLine=null;
const ic09Items=[
  {id:"amox",name:"Amox 500",code:"SP-00128",lot:"L2407-A",qty:18,uom:"hộp",state:"SELLABLE",label:"Bán được",expiry:"30/11/2026"},
  {id:"găng",name:"Găng tay M",code:"SP-00410",lot:"L2405-M",qty:6,uom:"hộp",state:"QUARANTINE",label:"Cách ly",expiry:"—"},
  {id:"vitc",name:"Vitamin C",code:"SP-00231",lot:"L2310-C",qty:4,uom:"hộp",state:"EXPIRED",label:"Hết hạn",expiry:"31/08/2026"},
  {id:"dungthu",name:"Dầu sát khuẩn",code:"SP-00606",lot:"L2406-T",qty:2,uom:"chai",state:"DEMO",label:"Dùng thử",expiry:"31/12/2027"}
];
function icCard(title,body){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<section class="review-card" data-ds-component="${calibrated?'VSection':'VCard'}" ${calibrated?'data-composed-from="VText,DS v2 / Info Row,VTextField"':'data-ds-profile="card.readOnly"'}><div class="review-card-header"><strong>${title}</strong></div><div class="review-card-body">${body}</div></section>`;}
function icField(label,value,attr="",type="text",hint=""){return `<div class="form-field" data-ds-component="${type==='number'?'VNumberField':'VTextField'}"><label>${label}</label><div class="input-shell"><input type="${type}" value="${escapeAttribute(value)}" ${attr}></div>${hint?`<small class="helper-text">${hint}</small>`:""}</div>`;}
function icTextarea(label,value,attr="",placeholder=""){return `<div class="form-field ic-textarea-field" data-ds-component="VTextarea" data-figma-node="522:7212"><label>${label}</label><textarea class="textarea" ${attr} placeholder="${escapeAttribute(placeholder)}">${esc(value)}</textarea></div>`;}
function icChoice(value,label,detail,checked=false){return `<label class="v364-radio-option" data-ds-component="VRadio" data-figma-node="522:7410" data-ds-prop-state="${checked?'On':'Off'}"><input type="radio" name="ic-state" value="${escapeAttribute(value)}" data-ic09-destination ${checked?'checked':''}><span class="v364-radio-control" aria-hidden="true"></span><span class="v364-radio-copy"><strong>${esc(label)}</strong>${detail?`<small>${esc(detail)}</small>`:''}</span></label>`;}
function icHeaderRows(rows){return ioReadCard(rows.map(([a,b,strong])=>ioMetaRow(a,b,!!strong)).join(''));}
function icSecondary(label,action,tone="secondary"){const c=tone==='danger'?'button button--danger button--full':'button button--secondary button--full';return `<button class="${c}" type="button" ${action}>${label}</button>`;}
function icApprovalButtons(prefix){return `<div class="ic-action-stack">${icSecondary("Từ chối",`data-${prefix}-action="reject"`,'danger')}${primaryFooter("Duyệt",`data-${prefix}-action="approve"`)}</div>`;}

function ic08Section(title,body,extra="") { return `<section class="ds24-section ${extra}" data-theme-component="Theme7StockCountSection">${ds24SectionTitle(title)}${body}</section>`; }
function ds24SelectField(label,value,options,attr="") {
  return `<label class="ds24-field" data-ds-component="VSelect" data-figma-node="522:7291"><span class="vet45-text-style-8">${esc(label)}</span><select ${attr} class="ds24-field__control vet45-text-style-6">${options.map(([v,l])=>`<option value="${v}" ${v===value?'selected':''}>${esc(l)}</option>`).join('')}</select></label>`;
}
function ds24TextField(label,value,attrs="",helper="") {
  return `<label class="ds24-field" data-ds-component="VTextField" data-figma-node="522:7186"><span class="vet45-text-style-8">${esc(label)}</span><input class="ds24-field__control vet45-text-style-6" value="${escapeAttribute(value)}" ${attrs}>${helper?`<small class="vet45-text-style-11">${esc(helper)}</small>`:''}</label>`;
}
function ic08QuantityTrigger(label,value,target,unit,disabled=false) {
  return `<div class="ds24-field" data-theme-component="Theme7QuantityEntry" data-composed-from="VText,VNumericKeypadSheet"><span class="vet45-text-style-8">${esc(label)}</span><button type="button" class="ds24-field__control ds24-quantity-trigger" data-ic08-keypad-open="${target}" data-unit="${escapeAttribute(unit)}" ${disabled?'disabled':''}><span class="vet45-text-style-6">${esc(value||'0')}</span><small class="vet45-text-style-11">${esc(unit)}</small></button></div>`;
}
function ic08ContextRows(rows) { return ds24InfoGroup('',rows.map(([k,v])=>ds24InfoRow(k,v)).join(''),'ds24-info-group--untitled ic08-info-group'); }
function ic08ProductInputGroup({keyId,code,name,lot,uom,value,label="Số lượng thực tế",targetPrefix="count",badge="",badgeTone="Neutral",unexpected=false,disabled=false,facts=""}) {
  const meta=`${code?`${code} · `:""}${lot?`Lô ${lot} · `:""}${uom}`;
  const head=ds24ListRow({title:name,subtitle:meta,trailing:badge?ds24Badge(badge,badgeTone):"",leading:"package",type:"Status",density:"Compact",interactive:false,attrs:`data-layout-role="stock-count-product" ${unexpected?'data-product-flag="is_unexpected_key"':''}`});
  const qty=ic08QuantityTrigger(label,value,`${targetPrefix}:${unexpected?'unexpected':keyId}`,uom,disabled);
  return `<div class="ac321-product-input-group" data-layout-pattern="Sectioned form composition" data-composed-from="DS v2 / List Row,DS v2 / Key-value Row,VTextField">${head}${facts?`<div class="ac321-product-facts">${facts}</div>`:""}<div class="ac321-product-field">${qty}</div></div>`;
}
function ic08CountRow({id,name,lot,uom,value,unexpected=false,disabled=false}) {
  const code=id==='amox'?'SP-00128':id==='glove'?'SP-00410':unexpected?'':'';
  // v3.4.0: counting is already the screen task; do not repeat a generic "Cần đếm" badge on every product.
  return ic08ProductInputGroup({keyId:id,code,name,lot,uom,value,unexpected,disabled,badge:unexpected?'Bổ sung thực tế':'',badgeTone:'Info',targetPrefix:'count'});
}
function ic08RecountRow({id,name,lot,uom,book,first,variance,value,disabled=false}) {
  const code=id==='amox'?'SP-00128':'SP-00410';
  // v3.4.0: variance is a product fact, not a status badge. Keep the identity row quiet and put all numeric evidence in one aligned fact region.
  const facts=`${ds24KeyValueRow('Theo sổ',`${book} ${uom}`)}${ds24KeyValueRow('Lần đếm đầu',`${first} ${uom}`)}${ds24KeyValueRow('Chênh lệch',`${variance} ${uom}`)}`;
  return ic08ProductInputGroup({keyId:id,code,name,lot,uom,value,label:'Số lượng đếm lại',targetPrefix:'recount',disabled,facts});
}
function ic08NumericSheet() {
  if(!ic08KeypadTarget)return ""; const [mode,id]=ic08KeypadTarget.split(':'); const unit=id==='unexpected'?(ic08UnexpectedLine?.uom||'hộp'):'hộp'; const title=mode==='recount'?'Nhập số lượng đếm lại':'Nhập số lượng'; const keys=['1','2','3','4','5','6','7','8','9','.','0','⌫'];
  return `<div class="sheet-backdrop ds24-overlay" data-ic08-action="keypad-cancel"><section class="ds24-keypad" data-ds-component="VNumericKeypadSheet" data-figma-node="1829:6657" data-ds-prop-mode="Quantity" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><div class="ds24-keypad__handle"></div><header><h3 class="vet45-text-style-4">${title}</h3><p class="vet45-text-style-7">Đơn vị: ${esc(unit)}</p></header><div class="ds24-keypad__value vet45-text-style-2">${esc(ic08KeypadDraft||'0')}</div><div class="ds24-keypad__grid">${keys.map(k=>`<button type="button" data-ic08-key="${escapeAttribute(k)}" aria-label="${k==='⌫'?'Xóa một số':k}" class="vet45-text-style-3">${k}</button>`).join('')}</div><div class="ds24-keypad__actions"><button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="keypad-cancel" data-ds-component="VButton" data-figma-node="521:529">Hủy</button><button class="ds24-button ds24-button--primary" type="button" data-ic08-action="keypad-save" data-ds-component="VButton" data-figma-node="521:529">Lưu</button></div></section></div>`;
}
function ic08ConfirmationSheet() {
  if(!ic08ConfirmKind)return "";
  const cfg={
    'open-session':['Mở phiên kiểm kê?','Phạm vi sẽ được khóa theo thời điểm chốt của phiên.','Mở phiên','default',false],
    'submit-first':['Nộp lần đếm đầu?','Sau khi nộp, hệ thống mới hiển thị số sổ và chênh lệch.','Nộp kết quả','default',false],
    'submit-recount':['Gửi kết quả kiểm kê?','Kết quả đếm lại sẽ được chuyển sang công việc duyệt độc lập.','Gửi chờ duyệt','default',false],
    'approve':['Duyệt và điều chỉnh?','Hệ thống sẽ ghi điều chỉnh tồn kho và hoàn tất phiên nếu các guard vẫn hợp lệ.','Duyệt và điều chỉnh','default',false],
    'request-review':['Yêu cầu xem lại?','Phiên giữ nguyên khóa và quay lại bước đếm lại. Lý do được lưu cùng quyết định.','Yêu cầu xem lại','default',true],
    'cancel':['Hủy phiên kiểm kê?','Không tạo điều chỉnh. Lịch sử kiểm đếm được giữ và phạm vi được mở khóa.','Hủy phiên','danger',true]
  }[ic08ConfirmKind]; if(!cfg)return "";
  const [title,desc,action,tone,needsReason]=cfg; const val=ic08ConfirmKind==='cancel'?ic08CancelReason:ic08ReviewReason; const attr=ic08ConfirmKind==='cancel'?'data-ic08-cancel-reason':'data-ic08-review-reason';
  const reason=needsReason?ds24TextField('Lý do',val,attr,'Lý do được lưu trong lịch sử quản trị.'):'';
  return `<div class="sheet-backdrop ds24-overlay" data-ic08-action="confirm-close"><section class="ds24-confirmation ds24-confirmation--${tone}" data-ds-component="DS v2 / Confirmation Sheet" data-figma-node="550:1058" data-ds-prop-content="${needsReason?'Reason':'Plain'}" data-ds-prop-tone="${tone==='danger'?'Danger':'Default'}" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><div class="ds24-confirmation__handle"></div><h3 class="vet45-text-style-4">${esc(title)}</h3><p class="vet45-text-style-6">${esc(desc)}</p>${reason}<div class="ds24-confirmation__actions"><button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="confirm-close" data-ds-component="VButton">Quay lại</button><button class="ds24-button ${tone==='danger'?'ds24-button--danger':'ds24-button--primary'}" type="button" data-ic08-action="confirm-${ic08ConfirmKind}" data-ds-component="VButton" ${needsReason&&!val.trim()?'disabled':''}>${esc(action)}</button></div></section></div>`;
}
function ic08SelectSheet() {
  if(!ic08ScopeSheetOpen&&!ic08ProductSheetOpen)return ""; const productMode=ic08ProductSheetOpen;
  const rows=productMode?[["vitc","Vitamin C","SP-00231 · Lô L2501-C · hộp"],["amox-new","Amox 500","SP-00128 · Lô L2501-A · hộp"]]:ic08Scope==='PRODUCT'?[["amox","Amox 500","SP-00128"],["glove","Găng tay M","SP-00410"]]:ic08Scope==='GROUP'?[["group-vaccine","Nhóm vaccine","Nhóm sản phẩm"],["group-medicine","Nhóm thuốc","Nhóm sản phẩm"]]:[["lot-l2407","Lô L2407-A","Amox 500"],["lot-l2405","Lô L2405-M","Găng tay M"]];
  return `<div class="sheet-backdrop ds24-overlay" data-ic08-action="select-close"><section class="ds24-select-sheet" data-ds-pattern="Select Sheet" data-theme-component="Theme7SearchSelectSheet" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><div class="ds24-sheet__handle"></div><h3 class="vet45-text-style-4">${productMode?'Thêm hàng thực tế':'Chọn phạm vi'}</h3>${ds24Search('','','Tìm kiếm')}<div class="ds24-list-stack">${rows.map(([id,name,meta])=>ds24ListRow({title:name,subtitle:meta,attrs:`data-ic08-${productMode?'product':'scope-target'}="${id}" data-name="${escapeAttribute(name)}" data-meta="${escapeAttribute(meta)}"`,theme:productMode?'Theme7UnexpectedItemResult':'Theme7ScopeResult'})).join('')}</div><button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="select-close" data-ds-component="VButton">Đóng</button></section></div>`;
}
function ic08Overlays(){return `${ic08NumericSheet()}${ic08ConfirmationSheet()}${ic08SelectSheet()}`;}
function ic08SessionRow() {
  return `<section class="ds24-session-block" data-theme-component="Theme7StockCountSession"><div class="ds24-session-main">${ds24ListRow({title:'KK-0709-03',subtitle:'Kho trung tâm · Toàn kho',trailing:`${ds24Badge('Đang đếm','Info')}<small class="vet45-text-style-11">12/38</small>`,attrs:'data-ic08-action="resume"',leading:'listCheck',theme:'Theme7StockCountSessionRow'})}</div><button class="ds24-button ds24-button--danger ds24-session-cancel" type="button" data-ic08-action="cancel-open" data-action-contract="ACT-09-CANCEL" data-ds-component="VButton" data-figma-node="521:529">Hủy phiên</button></section>`;
}
function render042IC08(state) {
  if(state==="PERMISSION_DENIED")return appShell({title:"Kiểm kê kho",body:deniedBody(),centered:true,back:false});
  if(state==="LOADING")return appShell({title:"Kiểm kê kho",body:loadingBody(),back:false});
  if(state==="EMPTY")return appShell({title:"Kiểm kê kho",body:`${bj01Empty(false)}${ic08Overlays()}`,actions:primaryFooter("Tạo phiên kiểm kê",'data-ic08-action="create"'),back:false});
  if(state==="FILTER_EMPTY")return appShell({title:"Kiểm kê kho",body:`${ds24Search('','','Tìm phiên kiểm kê')}${bj01Empty(true)}${ic08Overlays()}`,back:false});
  if(state==="PENDING_APPROVAL")return appShell({title:"Kiểm kê kho",body:`${vBanner('info','Đã gửi chờ duyệt','Bạn đã hoàn tất phần việc của mình. Quyết định duyệt nằm trong công việc riêng của người duyệt.')}${ic08ContextRows([['Phiên','KK-0709-03'],['Phạm vi','Kho trung tâm'],['Trạng thái','Chờ duyệt']])}`,back:false});
  const chips=ac321CanonicalChips('ALL',[["ALL","Tất cả"],["COUNTING","Đang đếm"],["APPROVAL","Chờ duyệt"]],'data-ic08-filter');
  return appShell({title:"Kiểm kê kho",body:`${ds24Search('','','Tìm phiên kiểm kê')}${chips}${ic08SessionRow()}${ic08Overlays()}`,actions:primaryFooter("Tạo phiên kiểm kê",'data-ic08-action="create"'),back:false});
}
function render043IC08(state) {
  if(state==="PERMISSION_DENIED")return appShell({title:"Tạo phiên kiểm kê",body:deniedBody(),centered:true});
  if(["CONFLICT","LOCKED"].includes(state))return appShell({title:"Tạo phiên kiểm kê",body:`${vBanner('warning','Phạm vi đang được kiểm kê','Không thể mở thêm phiên chồng lên phạm vi đang khóa.')}${ic08ContextRows([['Kho','Kho trung tâm'],['Thời điểm chốt','09/09/2026 · 08:00']])}`});
  const validation=state==="VALIDATION_ERROR"?vBanner('error','Chưa đủ thông tin','Chọn phạm vi và nhập lý do kiểm kê trước khi mở phiên.'):'';
  const scopeOptions=[["ALL","Toàn kho"],["PRODUCT","Sản phẩm"],["GROUP","Nhóm sản phẩm"],["LOT","Lô"]];
  const target=ic08Scope!=="ALL"?`<div class="ds24-field" data-theme-component="Theme7ScopeTarget" data-composed-from="VText,Search & Select"><span class="vet45-text-style-8">${ic08Scope==='PRODUCT'?'Sản phẩm':ic08Scope==='GROUP'?'Nhóm sản phẩm':'Lô'}</span><button type="button" class="ds24-field__control ds24-select-trigger" data-ic08-action="scope-select-open"><span>${esc(ic08ScopeTarget||'Chọn phạm vi')}</span>${icon('chevronRight','icon--sm')}</button></div>`:'';
  const body=`${validation}${ic08ContextRows([['Kho','Kho trung tâm'],['Thời điểm chốt','09/09/2026 · 08:00'],['Người đếm','Nguyễn An']])}${ds24SectionTitle('Thiết lập phiên')}${ds24SelectField('Phạm vi',ic08Scope,scopeOptions,'data-ic08-scope')}${target}${ds24TextField('Lý do kiểm kê',ic08Reason,'data-ic08-reason','Thông tin này được gửi cùng yêu cầu mở phiên.')}${vBanner('info','Phạm vi sẽ được khóa','Sau khi mở phiên, phạm vi và thời điểm chốt không tự thay đổi theo dữ liệu mới.')}${ic08Overlays()}`;
  return appShell({title:"Tạo phiên kiểm kê",body,actions:primaryFooter("Mở phiên kiểm kê",'data-ic08-action="open-session"',ic08Scope!=="ALL"&&!ic08ScopeTarget)});
}
function render044IC08(state) {
  if(state==="PERMISSION_DENIED")return appShell({title:"Đếm mù",body:deniedBody(),centered:true});
  if(state==="NO_RESULT")return appShell({title:"Đếm mù",body:bj01Empty(false),actions:primaryFooter("Về danh sách",'data-ic08-action="to-list"')});
  const lost=state==="LOCK_LOST"; const error=state==="VALIDATION_ERROR"?vBanner('error','Chưa nhập đủ kết quả','Nhập số đếm thực tế cho tất cả dòng trước khi nộp.'):'';
  const notice=lost?vBanner('warning','Phiên không còn giữ khóa','Số đã nhập được giữ trên thiết bị. Quay về phiên kiểm kê để tải lại trạng thái authoritative trước khi tiếp tục.'):'';
  const unexpected=ic08UnexpectedLine?ic08CountRow({id:'unexpected',name:ic08UnexpectedLine.name,lot:ic08UnexpectedLine.lot,uom:ic08UnexpectedLine.uom,value:ic08UnexpectedLine.value,unexpected:true,disabled:lost}):'';
  const body=`${error}${notice}${vBanner('info','Đếm mù đang bật','Chỉ ghi nhận số lượng thực tế. Số sổ và chênh lệch không có trong DOM trước lần nộp đầu.')}${ic08ContextRows([['Phiên','KK-0709-03'],['Kho','Kho trung tâm'],['Thời điểm chốt','09/09/2026 · 08:00']])}<div class="ac321-list-meta">2 dòng cần đếm</div><div class="ds24-count-list ac321-count-collection">${ic08CountRow({id:'amox',name:'Amox 500',lot:'L2407-A',uom:'hộp',value:ic08Counts.amox,disabled:lost})}${ic08CountRow({id:'glove',name:'Găng tay M',lot:'L2405-M',uom:'hộp',value:ic08Counts.glove,disabled:lost})}${unexpected}</div>${!lost?`<button class="ds24-button ds24-button--secondary ds24-inline-action" type="button" data-ic08-action="add-actual-open" data-theme-component="Theme7UnexpectedPhysicalItemAction">${icon('package','icon--sm')}Thêm hàng thực tế</button>`:''}${ic08Overlays()}`;
  return appShell({title:"Đếm mù",body,actions:lost?primaryFooter("Về phiên kiểm kê",'data-ic08-action="to-list"'):primaryFooter("Nộp kết quả đếm",'data-ic08-action="submit-first"')});
}
function render045IC08(state) {
  if(state==="PERMISSION_DENIED")return appShell({title:"Chênh lệch và đếm lại",body:deniedBody(),centered:true});
  const locked=state==="LOCKED", price=state==="PRICE_BASIS_REQUIRED", evidence=state==="EVIDENCE_REQUIRED", validation=state==="VALIDATION_ERROR";
  const notice=locked?vBanner('warning','Phiên đang chỉ đọc','Không thể sửa kết quả đếm trong trạng thái hiện hành.'):price?vBanner('error','Chưa đủ căn cứ giá','Dòng thừa chưa có căn cứ giá hợp lệ. Phiên tiếp tục giữ khóa; không nhập giá tạm để đi tiếp.'):evidence?vBanner('warning','Chưa đủ bằng chứng','Bằng chứng authoritative chưa đủ để gửi duyệt. Phiên tiếp tục giữ khóa.'):validation?vBanner('error','Kết quả đếm lại chưa hợp lệ','Kiểm tra các số lượng đếm lại trước khi gửi.'):'';
  const evidenceStatus=`<section class="ds24-section" data-theme-component="Theme7CountEvidenceStatus">${ds24SectionTitle('Căn cứ và bằng chứng')}${ic08ContextRows([['Amox 500','Đã có bằng chứng'],['Găng tay M',price?'Thiếu căn cứ giá':'Đã có căn cứ']])}${price||evidence?vBanner('warning','Chưa thể gửi duyệt','Hệ thống chỉ cho gửi khi nguồn có thẩm quyền xác nhận đủ căn cứ.'):''}</section>`;
  const body=`${notice}${vBanner('info','Chỉ xử lý dòng có chênh lệch','Số sổ được lộ sau lần đếm đầu. Người đếm chỉ nhập lại số thực tế của các dòng lệch.')}<div class="ds24-count-list ac321-count-collection">${ic08RecountRow({id:'amox',name:'Amox 500',lot:'L2407-A',uom:'hộp',book:20,first:18,variance:'−2 hộp',value:ic08Recounts.amox,disabled:locked})}${ic08RecountRow({id:'glove',name:'Găng tay M',lot:'L2405-M',uom:'hộp',book:6,first:7,variance:'+1 hộp',value:ic08Recounts.glove,disabled:locked})}</div>${evidenceStatus}${ic08Overlays()}`;
  let actions=''; if(!locked) actions=`<footer class="app-actions figma-sticky-footer ds24-footer-stack" data-ds-pattern="Sticky Footer"><button class="ds24-button ds24-button--primary" type="button" data-ic08-action="submit-recount" data-ds-component="VButton" ${price||evidence?'disabled':''}>Gửi chờ duyệt</button>${price||evidence?`<button class="ds24-button ds24-button--danger" type="button" data-ic08-action="cancel-open" data-action-contract="ACT-09-CANCEL" data-ds-component="VButton">Hủy phiên</button>`:''}</footer>`;
  return appShell({title:"Chênh lệch và đếm lại",body,actions});
}
function render046IC08(state) {
  if(state==="PERMISSION_DENIED")return appShell({title:"Duyệt kết quả kiểm kê",body:deniedBody(),centered:true,back:false});
  if(state==="SELF_APPROVAL_NOT_ALLOWED")return appShell({title:"Duyệt kết quả kiểm kê",body:vBanner('warning','Không thể tự duyệt','Người thực hiện kiểm kê không được duyệt chính kết quả của mình.'),back:false});
  if(state==="APPROVAL_ALREADY_DECIDED")return appShell({title:"Duyệt kết quả kiểm kê",body:vBanner('info','Công việc đã có quyết định','Mở kết quả kiểm kê để xem trạng thái authoritative.'),actions:primaryFooter("Xem kết quả",'data-ic08-action="approval-result"'),back:false});
  const body=`${vBanner('info','Cần quyết định độc lập','Người duyệt chỉ rà soát bằng chứng và quyết định; không sửa số đếm.')}${ic08ContextRows([['Phiên','KK-0709-03'],['Người thực hiện','Nguyễn An'],['Kho','Kho trung tâm'],['Tổng dòng lệch','2 dòng']])}${ic08Section('Amox 500 · L2407-A',`${ic08ContextRows([['Chênh lệch','−2 hộp'],['Đếm lại','18 hộp'],['Bằng chứng','Đã đủ']])}`)}${ic08Section('Găng tay M · L2405-M',`${ic08ContextRows([['Chênh lệch','+1 hộp'],['Đếm lại','7 hộp'],['Căn cứ giá','Đã đủ'],['Bằng chứng','Đã đủ']])}`)}${ic08Overlays()}`;
  const actions=`<footer class="app-actions figma-sticky-footer ds24-footer-stack" data-ds-pattern="Sticky Footer"><button class="ds24-button ds24-button--primary" type="button" data-ic08-action="approve" data-action-contract="ACT-09-APPROVE" data-decision-role="approve" data-ds-component="VButton">Duyệt và điều chỉnh</button><button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="request-review" data-action-contract="ACT-09-APPROVE" data-decision-role="request-review" data-ds-component="VButton">Yêu cầu xem lại</button></footer>`;
  return appShell({title:"Duyệt kết quả kiểm kê",body,actions,back:false});
}
function ds24Result(title,description,rows,tone='success') {
  const iconName=tone==='success'?'checkCircle':tone==='danger'?'xCircle':'alert';
  return `<section class="ds24-result" data-theme-component="Theme7OperationResult" data-composed-from="VIcon,VText,DS v2 / Info Row,State Pattern"><div class="ds24-result__icon ds24-result__icon--${tone}">${icon(iconName)}</div><h2 class="vet45-text-style-3">${esc(title)}</h2><p class="vet45-text-style-6">${esc(description)}</p><div class="ds24-info-stack">${rows.map(([k,v])=>ds24InfoRow(k,v)).join('')}</div></section>`;
}
function render047IC08(state) {
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả kiểm kê",body:deniedBody(),centered:true,back:false});
  if(state==="PROCESSING")return appShell({title:"Kết quả kiểm kê",body:loadingBody(),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Kết quả kiểm kê",body:ds24Result('Đang xác minh kết quả','Không gửi lại điều chỉnh. Hệ thống đang xác minh đúng lần xử lý này.',[['Phiên','KK-0709-03'],['Định danh xử lý','Giữ nguyên'],['Tồn kho','Chưa kết luận']],'warning'),actions:primaryFooter("Tiếp tục xác minh",'data-ic08-action="verify-result"'),centered:true,back:false});
  if(state==="CANCELLED")return appShell({title:"Kết quả kiểm kê",body:ds24Result('Đã hủy phiên','Không tạo điều chỉnh; lịch sử kiểm đếm được giữ và phạm vi đã mở khóa.',[['Phiên','KK-0709-03'],['Điều chỉnh','Không tạo'],['Khóa phạm vi','Đã mở']],'warning'),actions:primaryFooter("Về kiểm kê",'data-ic08-action="to-list"'),centered:true,back:false});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả kiểm kê",body:ds24Result('Điều chỉnh chưa được thực thi','Guard nghiệp vụ không đạt; không có tác động tồn kho.',[['Phiên','KK-0709-03'],['Tác động','Không ghi nhận'],['Khóa phạm vi','Theo trạng thái phiên']],'warning'),actions:primaryFooter("Về kiểm kê",'data-ic08-action="to-list"'),centered:true,back:false});
  return appShell({title:"Kết quả kiểm kê",body:ds24Result('Đã hoàn tất kiểm kê','Điều chỉnh tồn kho đã được ghi theo quyết định duyệt và phạm vi đã mở khóa.',[['Phiên','KK-0709-03'],['Điều chỉnh','ADJ-0709-03'],['Đã điều chỉnh','2 dòng'],['Khóa phạm vi','Đã mở']]),actions:primaryFooter("Về kiểm kê",'data-ic08-action="to-list"'),centered:true,back:false});
}

function ic09StatusTone(s){return s==="EXPIRED"||s==="DAMAGED"?"danger":s==="QUARANTINE"?"warning":s==="DEMO"?"info":"success";}
function ic09Current(){return ic09Items.find(x=>x.id===ic09Selected)||ic09Items[0];}
function render036IC09(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Tình trạng hàng",body:deniedBody(),centered:true,back:false});
  if(state==="LOADING")return appShell({title:"Tình trạng hàng",body:loadingBody(),back:false});
  const labels=[["ALL","Tất cả"],["SELLABLE","Bán được"],["QUARANTINE","Cách ly"],["DAMAGED","Hỏng"],["DEMO","Dùng thử"],["EXPIRED","Hết hạn"]];
  const q=ic09Query.trim().toLowerCase();
  const items=ic09Items.filter(x=>(ic09Filter==="ALL"||x.state===ic09Filter)&&(!q||`${x.name} ${x.code} ${x.lot}`.toLowerCase().includes(q)));
  if(state==="EMPTY")return appShell({title:"Tình trạng hàng",body:ioEmpty("Chưa có hàng trong kho","Khi có tồn kho, tình trạng hàng sẽ xuất hiện tại đây."),back:false});
  const rows=items.map(x=>ioProductRow({name:x.name,code:x.code,primary:`${x.qty} ${x.uom}`,secondary:`Lô ${x.lot}`,badge:x.label,badgeStatus:ic09StatusTone(x.state),attr:`data-ic09-item="${x.id}"`})).join('');
  const statusChips=`<div class="ac321-chip-wrap" data-composed-from="VChip">${labels.map(([k,l])=>ds24Chip(k,l,ic09Filter===k,'data-ic09-filter')).join('')}</div>`;
  const body=`${ds24Search(ic09Query,'data-ic09-search','Tìm sản phẩm hoặc lô')}${statusChips}${rows?`<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row,VBadge"><div class="io-product-list">${rows}</div></div>`:ioEmpty("Không có hàng phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`;
  return appShell({title:"Tình trạng hàng",body,back:false});
}
function render037IC09(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Chi tiết tình trạng hàng",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Chi tiết tình trạng hàng",body:loadingBody()});
  const x=ic09Current(); const expired=state==="EXPIRED"||x.state==="EXPIRED";
  const locked=state==="LOCKED";
  const notice=expired?vBanner("warning","Lô đã hết hạn","Hạn dùng đã qua theo ngày nghiệp vụ. Hệ thống tự loại phần này khỏi khả dụng bán; không cần thao tác đánh dấu."):locked?vBanner("info","Đang thuộc phạm vi kiểm kê","Thông tin chỉ đọc cho đến khi phiên kiểm kê kết thúc."):"";
  const body=`${notice}${icHeaderRows([["Sản phẩm",x.name,true],["Mã",x.code],["Lô",x.lot],["Hạn dùng",x.expiry],["Tình trạng",expired?"Hết hạn":x.label],["Tồn vật lý",`${x.qty} ${x.uom}`],["Khả dụng bán",expired?`0 ${x.uom}`:(x.state==="SELLABLE"?`${x.qty} ${x.uom}`:`0 ${x.uom}`)]])}${ioSectionTitle("Tác động")}<p class="io-footnote">Thay đổi tình trạng chỉ phân loại lại cùng lượng hàng; tổng tồn vật lý và giá trị không đổi.</p>${icSecondary("Xem lịch sử",'data-ic09-action="history"')}`;
  return appShell({title:"Chi tiết tình trạng hàng",body,actions:locked||expired?"":primaryFooter("Thay đổi tình trạng",'data-ic09-action="change"')});
}
function render038IC09(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Chuyển tình trạng hàng",body:deniedBody(),centered:true,back:false});
  const x=ic09Current();
  if(state==="LOCKED")return appShell({title:"Chuyển tình trạng hàng",body:`${vBanner("info","Đang thuộc phạm vi kiểm kê","Không thể thay đổi tình trạng trong khi phạm vi đang khóa.")}${icHeaderRows([["Sản phẩm",x.name,true],["Lô",x.lot],["Tình trạng hiện tại",x.label]])}`,back:false});
  if(state==="PENDING_APPROVAL")return appShell({title:"Chuyển tình trạng hàng",body:`${vBanner("info","Đã gửi chờ duyệt","Bạn đã hoàn tất phần việc của mình. Người duyệt nhận một công việc riêng; hàng chưa đổi tình trạng cho đến khi quyết định được ghi nhận.")}${icHeaderRows([["Sản phẩm",x.name,true],["Từ",x.label],["Sang",ic09Destination==="QUARANTINE"?"Cách ly":ic09Destination==="DAMAGED"?"Hỏng":ic09Destination==="DEMO"?"Dùng thử":"Bán được"]])}`,back:false});
  if(state==="SELF_APPROVAL_NOT_ALLOWED")return appShell({title:"Chuyển tình trạng hàng",body:vBanner("warning","Không thể tự duyệt","Người lập yêu cầu không được tự duyệt yêu cầu này."),back:false});
  if(state==="APPROVAL_REVIEW"){
    const body=`${vBanner("info","Yêu cầu thay đổi tình trạng","Kiểm tra lý do và phạm vi trước khi quyết định. Việc duyệt chỉ thay đổi phân loại; tổng tồn vật lý và giá trị không đổi.")}${icHeaderRows([["Sản phẩm",x.name,true],["Lô",x.lot],["Từ",x.label],["Sang",ic09Destination==="QUARANTINE"?"Cách ly":"Hỏng"],["Số lượng",`${x.qty} ${x.uom}`],["Lý do","Bao bì có dấu hiệu bất thường"]])}`;
    return appShell({title:"Duyệt thay đổi tình trạng",body,actions:icApprovalButtons("ic09"),back:false});
  }
  const error=state==="VALIDATION_ERROR"?vBanner("error","Chưa đủ thông tin","Chọn tình trạng đích và nhập lý do phù hợp."):"";
  const choices=[icChoice("QUARANTINE","Cách ly","Tạm thời không bán",ic09Destination==="QUARANTINE"),icChoice("DAMAGED","Hỏng","Không còn đủ điều kiện bán",ic09Destination==="DAMAGED"),icChoice("DEMO","Dùng thử","Chuyển sang mục đích dùng thử",ic09Destination==="DEMO")];
  if(x.state!=="SELLABLE")choices.push(icChoice("SELLABLE","Bán được","Chỉ khi hàng đủ điều kiện trở lại bán",ic09Destination==="SELLABLE"));
  const body=`${error}${icHeaderRows([["Sản phẩm",x.name,true],["Lô",x.lot],["Hiện tại",x.label],["Số lượng",`${x.qty} ${x.uom}`]])}${ioSectionTitle("Tình trạng mới")}<div class="choice-list">${choices.join('')}</div>${icTextarea("Lý do","Bao bì có dấu hiệu bất thường",'data-ic09-reason')}`;
  return appShell({title:"Chuyển tình trạng hàng",body,actions:primaryFooter("Gửi xử lý",'data-ic09-action="submit"')});
}
function render041IC09(state){
  if(state==="PROCESSING")return appShell({title:"Kết quả thay đổi",body:loadingBody(),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Kết quả thay đổi",body:ioResult("Đang xác minh kết quả","Không gửi một yêu cầu mới. Hệ thống đang kiểm tra cùng lần xử lý này.",[["Sản phẩm",ic09Current().name],["Tình trạng","Chưa kết luận"]],"warning"),actions:primaryFooter("Kiểm tra kết quả",'data-ic09-action="verify"'),centered:true,back:false});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả thay đổi",body:ioResult("Yêu cầu không được thực hiện","Tình trạng và tồn kho không thay đổi.",[["Sản phẩm",ic09Current().name],["Tồn vật lý","Không đổi"]],"warning"),actions:primaryFooter("Về tình trạng hàng",'data-ic09-action="to-list"'),centered:true,back:false});
  if(state==="EXPIRED")return appShell({title:"Tình trạng hàng",body:ioResult("Lô đã hết hạn","Hệ thống đã loại lượng hàng này khỏi khả dụng bán theo hạn dùng; tồn vật lý vẫn được giữ để tiếp tục xử lý.",[["Tồn vật lý","4 hộp"],["Khả dụng bán","0 hộp"]],"warning"),actions:primaryFooter("Về tình trạng hàng",'data-ic09-action="to-list"'),centered:true,back:false});
  return appShell({title:"Kết quả thay đổi",body:ioResult("Đã cập nhật tình trạng","Cùng lượng hàng đã được phân loại lại; tổng tồn vật lý và giá trị không thay đổi.",[["Sản phẩm",ic09Current().name],["Tình trạng mới",ic09Destination==="QUARANTINE"?"Cách ly":ic09Destination==="DAMAGED"?"Hỏng":ic09Destination==="DEMO"?"Dùng thử":"Bán được"],["Tồn vật lý",`${ic09Current().qty} ${ic09Current().uom} · không đổi`]]),actions:primaryFooter("Về tình trạng hàng",'data-ic09-action="to-list"'),centered:true,back:false});
}
function render056IC09(state){
  if(activeFlowId!=="UIF-09") return renderGeneric(screens.find(s=>s.id==="SCR-056"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Lịch sử tình trạng",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Lịch sử tình trạng",body:loadingBody()});
  const x=ic09Current();
  const body=`${icHeaderRows([["Sản phẩm",x.name,true],["Lô",x.lot]])}<div class="timeline"><div class="timeline-card">${ioMetaRow("07/09/2026 · 09:14","Bán được → Cách ly",true)}<small>Nguyễn An · Bao bì có dấu hiệu bất thường</small></div><div class="timeline-card">${ioMetaRow("01/09/2026 · 08:00","Nhận vào kho",true)}<small>Tình trạng ban đầu: Bán được</small></div></div>`;
  return appShell({title:"Lịch sử tình trạng",body});
}

function render036IC10(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Hàng có thể xử lý",body:deniedBody(),centered:true,back:false});
  if(state==="LOADING")return appShell({title:"Hàng có thể xử lý",body:loadingBody(),back:false});
  if(state==="EMPTY")return appShell({title:"Hàng có thể xử lý",body:ioEmpty("Chưa có hàng cần xử lý","Chỉ hàng không bán được và thuộc quyền sở hữu của tổ chức mới xuất hiện tại đây."),back:false});
  const body=`${vBanner("info","Chỉ hiển thị hàng đủ điều kiện","Hàng đang bán được cần đổi tình trạng trước khi có thể lập yêu cầu tiêu hủy.")}<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row"><div class="io-product-list">${ioProductRow({name:"Amox 500",code:"SP-00128",primary:"6 hộp",secondary:"Lô L2407-A",badge:"Cách ly",badgeStatus:"warning",attr:'data-ic10-item="amox-l2407"'})}${ioProductRow({name:"Vitamin C",code:"SP-00231",primary:"4 hộp",secondary:"Lô L2310-C",badge:"Hết hạn",badgeStatus:"danger",attr:'data-ic10-item="vitc-l2310"'})}</div></div>`;
  return appShell({title:"Hàng có thể xử lý",body,back:false});
}
function render037IC10(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Chi tiết hàng",body:deniedBody(),centered:true});
  if(state==="LOCKED")return appShell({title:"Chi tiết hàng",body:`${vBanner("info","Đang thuộc phạm vi kiểm kê","Thông tin chỉ đọc cho đến khi phiên kiểm kê kết thúc.")}${icHeaderRows([["Sản phẩm","Amox 500",true],["Lô","L2407-A"],["Tình trạng","Cách ly"],["Tồn vật lý","6 hộp"]])}`});
  const body=`${icHeaderRows([["Sản phẩm","Amox 500",true],["Mã","SP-00128"],["Lô","L2407-A"],["Tình trạng","Cách ly"],["Tồn vật lý","6 hộp"],["Quyền sở hữu","Hàng của tổ chức"]])}${ioSectionTitle("Xử lý")}<p class="io-footnote">Phê duyệt yêu cầu không làm giảm tồn. Chỉ xác nhận đã tiêu hủy thực tế mới cho phép ghi giảm.</p>`;
  return appShell({title:"Chi tiết hàng",body,actions:primaryFooter("Đề nghị tiêu hủy",'data-ic10-action="request"')});
}
function render040IC10(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Yêu cầu tiêu hủy",body:deniedBody(),centered:true,back:false});
  const base=icHeaderRows([["Sản phẩm","Amox 500",true],["Lô","L2407-A"],["Tình trạng","Cách ly"],["Có thể xử lý","6 hộp"]]);
  if(state==="PRICE_BASIS_REQUIRED")return appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("error","Chưa có căn cứ giá hợp lệ","Không thể gửi yêu cầu vì chưa xác định được căn cứ giá chính thức cho lượng hàng này. Không nhập giá thủ công để bỏ qua kiểm soát.")}${base}${icField("Số lượng đề nghị","6",'data-ic10-qty','number')}${icTextarea("Lý do","Hàng không còn đủ điều kiện sử dụng",'data-ic10-reason')}`,actions:primaryFooter("Gửi yêu cầu tiêu hủy",'data-ic10-action="submit"',true)});
  if(state==="PENDING_APPROVAL")return appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("info","Đã gửi chờ duyệt","Bạn đã hoàn tất phần việc lập yêu cầu. Tồn kho chưa thay đổi; người duyệt nhận công việc riêng.")}${base}${icHeaderRows([["Số lượng đề nghị","6 hộp",true],["Tác động tồn kho","Chưa có"]])}`,back:false});
  if(state==="APPROVAL_REVIEW")return appShell({title:"Duyệt tiêu hủy",body:`${vBanner("info","Phê duyệt chưa phải tiêu hủy","Duyệt chỉ cho phép chuyển yêu cầu sang chờ xử lý thực tế. Tồn vật lý chưa giảm ở bước này.")}${base}${icHeaderRows([["Số lượng đề nghị","6 hộp",true],["Căn cứ giá","Giá vốn hiện hành"],["Lý do","Hàng không còn đủ điều kiện sử dụng"]])}`,actions:icApprovalButtons("ic10"),back:false});
  if(state==="APPROVED_PENDING_DISPOSAL")return appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("success","Đã duyệt — chờ xử lý thực tế","Yêu cầu đã được duyệt nhưng tồn kho vẫn giữ nguyên. Công việc xác nhận tiêu hủy sẽ được giao cho người thực hiện phù hợp.")}${base}${icHeaderRows([["Đã duyệt","6 hộp",true],["Tồn vật lý hiện tại","6 hộp · chưa giảm"]])}`,back:false});
  if(state==="COMPLETION_QTY_BLOCKED")return appShell({title:"Xác nhận đã tiêu hủy",body:`${vBanner("error","Số lượng thực tế vượt phạm vi được duyệt","Không thể ghi giảm. Cần lập yêu cầu và phê duyệt mới cho phần vượt chính sách.")}${base}${icField("Đã tiêu hủy thực tế","7",'data-ic10-actual','number')}${icTextarea("Bằng chứng","Biên bản tiêu hủy #TH-0709",'data-ic10-proof')}`,actions:primaryFooter("Xác nhận đã tiêu hủy",'data-ic10-action="complete"',true,"danger"),back:false});
  if(state==="COMPLETION")return appShell({title:"Xác nhận đã tiêu hủy",body:`${vBanner("warning","Chỉ xác nhận sau khi đã xử lý thực tế","Số lượng ở đây là lượng thực tế đã tiêu hủy và sẽ là căn cứ ghi giảm tồn.")}${base}${icField("Đã tiêu hủy thực tế","6",'data-ic10-actual','number')}${icTextarea("Bằng chứng","Biên bản tiêu hủy #TH-0709",'data-ic10-proof')}`,actions:primaryFooter("Xác nhận đã tiêu hủy",'data-ic10-action="complete"',false,"danger"),back:false});
  const body=`${base}${icField("Số lượng đề nghị","6",'data-ic10-qty','number')}${icTextarea("Lý do","Hàng không còn đủ điều kiện sử dụng",'data-ic10-reason')}${icTextarea("Bằng chứng","Ảnh hiện trạng và biên bản kiểm tra",'data-ic10-evidence')}${icHeaderRows([["Căn cứ giá","Giá vốn hiện hành"]])}`;
  return appShell({title:"Yêu cầu tiêu hủy",body,actions:primaryFooter("Gửi yêu cầu tiêu hủy",'data-ic10-action="submit"')});
}
function render041IC10(state){
  if(state==="PROCESSING")return appShell({title:"Kết quả tiêu hủy",body:loadingBody(),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Kết quả tiêu hủy",body:ioResult("Đang xác minh kết quả","Không tạo lần tiêu hủy mới. Hệ thống đang kiểm tra chính lần xác nhận này.",[["Yêu cầu","TH-0709-04"],["Tồn vật lý","Chưa kết luận"]],"warning"),actions:primaryFooter("Kiểm tra kết quả",'data-ic10-action="verify"'),centered:true,back:false});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả tiêu hủy",body:ioResult("Chưa ghi giảm","Không có tác động tồn kho mới. Xem lại yêu cầu hiện hành trước khi tiếp tục.",[["Yêu cầu","TH-0709-04"],["Tồn vật lý","Không thay đổi"]],"warning"),actions:primaryFooter("Về hàng có thể xử lý",'data-ic10-action="to-list"'),centered:true,back:false});
  return appShell({title:"Kết quả tiêu hủy",body:ioResult("Đã ghi nhận tiêu hủy","Tồn vật lý và giá trị đã giảm theo đúng số lượng thực tế được xác nhận.",[["Yêu cầu","TH-0709-04"],["Đã tiêu hủy","6 hộp"],["Tồn vật lý còn lại","0 hộp"]]),actions:primaryFooter("Về hàng có thể xử lý",'data-ic10-action="to-list"'),centered:true,back:false});
}

function render036IO07(state){
  if(activeFlowId==="UIF-09") return render036IC09(state);
  if(activeFlowId==="UIF-10") return render036IC10(state);
  if(activeFlowId!=="UIF-07") return renderGeneric(screens.find(s=>s.id==="SCR-036"),state);
  if(state==="PERMISSION_DENIED") return appShell({title:"Hàng chờ trả nhà cung cấp",body:deniedBody(),centered:true,back:false});
  if(state==="LOADING") return appShell({title:"Hàng chờ trả nhà cung cấp",body:loadingBody(),back:false});
  const all=io07ActiveRequests().filter(r=>io07MatchesQueue(r));
  const candidates=all.filter(r=>ioMatchesSearch(io07Query,`${r.id} ${r.supplier} ${r.source}`));
  const search=ds24Search(io07Query,"data-io07-search", "Tìm mã yêu cầu hoặc nhà cung cấp");
  const filters=`<div class="io07-chip-scroll" data-composed-from="VChip">${[["ALL","Tất cả"],["ACTIONABLE","Cần chuẩn bị"],["READY","Sẵn sàng"],["WAITING","Đang chờ"]].map(([k,l])=>ds24Chip(k,l,io07QueueFilter===k,"data-io07-filter")).join("")}</div>`;
  if(state==="EMPTY") return appShell({title:"Hàng chờ trả nhà cung cấp",body:`${search}${filters}${ioEmpty("Chưa có hàng chờ trả","Khi có yêu cầu trả đang hiệu lực, công việc sẽ xuất hiện tại đây.")}`,back:false});
  const queue=io07QueueList(candidates);
  const empty=`<div data-io07-filter-empty ${candidates.length?'hidden':''}>${ioEmpty("Không tìm thấy yêu cầu phù hợp","Đổi từ khóa hoặc bộ lọc để xem công việc khác.")}</div>`;
  return appShell({title:"Hàng chờ trả nhà cung cấp",body:`${search}${filters}${queue}${empty}`,back:false});
}
function render037IO07(state){
  if(activeFlowId==="UIF-09") return render037IC09(state);
  if(activeFlowId==="UIF-10") return render037IC10(state);
  if(activeFlowId!=="UIF-07") return renderGeneric(screens.find(s=>s.id==="SCR-037"),state);
  if(state==="PERMISSION_DENIED") return appShell({title:"Chuẩn bị hàng trả",body:deniedBody(),centered:true});
  if(state==="LOADING") return appShell({title:"Chuẩn bị hàng trả",body:loadingBody()});
  const req=io07Current();
  const total=io07Allocations(req).length,verified=io07VerifiedCount(req);
  const requestContext=ds24ContextStatusRow({title:req.id,subtitle:`${req.supplier} · ${req.source}`,label:`${verified}/${total}`,tone:io07HasMismatch(req)?"Danger":verified===total&&total?"Success":"Neutral",leading:null,attrs:'data-layout-role="rtv-request-context"'});
  if(req.sourceCancelled||req.closed)return appShell({title:"Chuẩn bị hàng trả",body:`${requestContext}${vBanner("info","Yêu cầu đã được hủy","Phần chờ trả đã được hệ thống giải phóng; Kho không cần thao tác thêm.","","Compact")}`,actions:primaryFooter("Về hàng chờ trả",'data-io07-action="result-to-rtv-queue"')});
  const mismatch=io07HasMismatch(req)||state==="PHYSICAL_MISMATCH";
  const mismatchBanner=mismatch?vBanner("warning","Chờ cập nhật yêu cầu","Hàng thực tế không khớp. Kho không sửa số lượng hoặc lô tại đây.","","Compact"):"";
  const groups=io07PreparationGroups(req);
  const collection=ds24GroupedCollection(groups,"io07-product-list io07-grouped-collection io07-grouped-collection--preparation","Product group header,Nested navigation row");
  const body=`${requestContext}${io07SourceDelta(req)}${mismatchBanner}${ds24SectionTitle("Hàng cần chuẩn bị",`${req.groups.length} nhóm sản phẩm`)}${collection}${io07VerificationSheet(req)}`;
  return appShell({title:"Chuẩn bị hàng trả",body,actions:primaryFooter("Rà soát bàn giao",'data-io07-action="review-handover"',!io07AllVerified(req)||mismatch)});
}
function render039IO07(state){
  if(activeFlowId!=="UIF-07") return renderGeneric(screens.find(s=>s.id==="SCR-039"),state);
  if(state==="PERMISSION_DENIED") return appShell({title:"Bàn giao trả nhà cung cấp",body:deniedBody(),centered:true});
  const req=io07Current();const sourceChanged=state==="SOURCE_CHANGED"||Number(req.reviewSourceVersion||req.sourceVersion)!==Number(req.sourceVersion);const mismatch=io07HasMismatch(req)||state==="PHYSICAL_MISMATCH";const ready=io07AllVerified(req)&&!sourceChanged&&!mismatch;
  const context=ds24InfoGroup("Thông tin bàn giao",`${ds24InfoRow("Nhà cung cấp",req.supplier)}${ds24InfoRow("Yêu cầu trả",req.id)}${ds24InfoRow("Kho",req.warehouse)}`,"io07-handover-context");
  const review=`${ds24SectionTitle("Hàng sẽ bàn giao",`${req.groups.length} nhóm sản phẩm`)}${io07ReviewGroups(req,{statusLabel:"Đã kiểm",statusTone:"Success"})}`;
  if(!ready){const why=sourceChanged?"Yêu cầu đã thay đổi sau khi mở rà soát. Kiểm lại phần bị ảnh hưởng.":"Có phần hàng chưa khớp yêu cầu hiện hành.";return appShell({title:"Bàn giao trả nhà cung cấp",body:`${context}${vBanner("warning","Cần kiểm lại trước khi bàn giao",why,"","Compact")}${review}`,actions:primaryFooter("Kiểm lại hàng",'data-io07-action="back-to-preparation"')});}
  return appShell({title:"Bàn giao trả nhà cung cấp",body:`${context}${review}`,actions:primaryFooter("Xác nhận đã bàn giao",'data-io07-action="confirm-handover"')});
}
function render041IO07(state){
  if(activeFlowId==="UIF-09") return render041IC09(state);
  if(activeFlowId==="UIF-10") return render041IC10(state);
  if(activeFlowId!=="UIF-07") return renderGeneric(screens.find(s=>s.id==="SCR-041"),state);
  const result=io07ResultSnapshot();const req=io07Requests.find(r=>r.id===result.requestId)||io07Current();
  if(state==="PROCESSING")return appShell({title:"Kết quả trả nhà cung cấp",body:loadingBody(),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Kết quả trả nhà cung cấp",body:ioResult("Đang xác minh kết quả","Không gửi lại bàn giao. Hệ thống đang kiểm tra chính lần xác nhận này.",[["Yêu cầu",result.requestId],["Tồn vật lý","Chưa kết luận"]],"warning"),centered:true,back:false,actions:primaryFooter("Về hàng chờ trả",'data-io07-action="result-to-rtv-queue"')});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả trả nhà cung cấp",body:ioResult("Chưa ghi nhận bàn giao","Không có tác động tồn kho mới. Xem lại yêu cầu hiện hành trước khi tiếp tục.",[["Yêu cầu",result.requestId],["Tồn kho","Không thay đổi"]],"warning"),centered:true,back:false,actions:primaryFooter(req&&!req.closed&&!req.completed?"Xem yêu cầu hiện tại":"Về hàng chờ trả",req&&!req.closed&&!req.completed?'data-io07-action="back-to-rtv-request"':'data-io07-action="result-to-rtv-queue"')});
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả trả nhà cung cấp",body:ioResult("Không có quyền thực hiện","Tồn kho không thay đổi. Chi tiết nghiệp vụ được giới hạn theo quyền hiện hành.",[["Kết quả","Không ghi nhận bàn giao"],["Tồn kho","Không thay đổi"]],"warning"),centered:true,back:false,actions:primaryFooter("Về hàng chờ trả",'data-io07-action="result-to-rtv-queue"')});
  const resultGroupCount=new Set((result.lines||[]).map(line=>`${line.name}|${line.code||""}|${line.uom}`)).size;
  const context=ds24InfoGroup("Thông tin trả hàng",`${ds24InfoRow("Nhà cung cấp",result.supplier)}${ds24InfoRow("Yêu cầu trả",result.requestId)}`,"io07-result-context");
  const body=`<div class="io-result io07-result">${resultHero("Đã bàn giao cho nhà cung cấp","Tồn vật lý và giá trị đã giảm theo đúng hàng bàn giao.")}${context}${ds24SectionTitle("Hàng đã bàn giao",`${resultGroupCount} nhóm sản phẩm`)}${io07ReviewGroups(result.lines||[],{statusLabel:"Đã bàn giao",statusTone:"Success"})}</div>`;
  return appShell({title:"Kết quả trả nhà cung cấp",body,centered:false,back:false,actions:primaryFooter("Về hàng chờ trả",'data-io07-action="result-to-rtv-queue"')});
}

// ============================================================================
// v1.7.0 — Correction & Recovery Product correction (UIF-11/UIF-16/UIF-17)
// Product UI exposes business facts, decisions and authoritative finality only.
// Technical identifiers/replay/rebuild/hash/polling remain contracts/Inspect concerns.
// ============================================================================
let cr11Filter="ALL";
let cr11Query="";
let cr11SelectedId="IO-260901-014";
let cr11Strategy="DELTA";
let cr11CorrectQty=118;
let cr11CorrectionReason="Ghi nhận thừa 2 hộp khi nhận hàng";
let cr11CancelReason="";
let cr11ApprovalRejectOpen=false;
let cr11ApprovalRejectReason="";
const cr11Operations=[
  {id:"IO-260906-022",type:"Thay đổi tình trạng hàng",source:"ST-260906-04",status:"READY",statusLabel:"Có thể hủy",route:"CANCEL",warehouse:"Kho trung tâm",product:"Amox 500 · Lô L2407-A",qty:12,uom:"hộp",impact:"Chưa phát sinh thay đổi tồn kho"},
  {id:"IO-260901-014",type:"Nhận hàng",source:"PN-260901-07",status:"COMPLETED",statusLabel:"Có thể sửa",route:"CORRECT",warehouse:"Kho trung tâm",product:"Nobivac DHPPi · Lô DH2507",qty:120,uom:"hộp",correctQty:118,impact:"Đã tăng tồn 120 hộp"},
  {id:"IO-260906-031",type:"Tiêu hủy",source:"DSP-260906-02",status:"UNKNOWN",statusLabel:"Đang xác minh",route:"UNKNOWN",warehouse:"Kho trung tâm",product:"Vitamin C · Lô L2310-C",qty:5,uom:"hộp",impact:"Chưa thể kết luận tác động tồn kho"},
  {id:"IO-260902-005",type:"Xuất bán",source:"SO-260902-19",status:"COMPLETED",statusLabel:"Cần xử lý đúng luồng",route:"PHYSICAL_RETURN_BLOCKED",warehouse:"Kho trung tâm",product:"Oxytetracycline LA",qty:3,uom:"chai",impact:"Hàng đã bàn giao thực tế cho khách"}
];
function cr11Current(){return cr11Operations.find(x=>x.id===cr11SelectedId)||cr11Operations[1];}
function cr11StateFor(op){if(op.route==="CANCEL")return "CANCELABLE";if(op.route==="UNKNOWN")return "UNKNOWN";if(op.route==="PHYSICAL_RETURN_BLOCKED")return "BLOCKED_PHYSICAL_HANDOVER";return "CORRECTABLE";}
function crChoice(name,value,label,detail,checked,attr){return `<label class="cr-choice" data-ds-component="VRadio"><input type="radio" name="${name}" value="${value}" ${attr} ${checked?'checked':''}><span><strong data-ds-component="VText">${label}</strong><small data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall">${detail}</small></span></label>`;}
function crFactCard(title,rows,badge="",tone="info"){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<section class="review-card cr-fact-card" data-ds-component="${calibrated?'VSection':'VCard'}" ${calibrated?'data-composed-from="VText,VBadge,DS v2 / Info Row"':'data-ds-profile="card.readOnly"'}><div class="review-card-header"><strong data-ds-component="VText">${title}</strong>${badge?vBadge(badge,tone):""}</div><div class="review-card-body">${rows.map(r=>ioMetaRow(r[0],r[1],!!r[2])).join("")}</div></section>`;}
function crTextAction(label,attr){return `<button type="button" class="button button--secondary button--full" ${attr} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary">${label}</button>`;}
function crSwitchFlow(flowId,screenId,state){activeFlowId=flowId;activeScreenId=screenId;if(state&&stateByScreen[screenId]!==undefined)stateByScreen[screenId]=state;syncReviewUrl();render();}
function cr11ListRows(){
  const labels={ALL:"Tất cả",CANCEL:"Có thể hủy",CORRECT:"Có thể sửa",UNKNOWN:"Đang xác minh"};
  const rows=cr11Operations.filter(op=>cr11Filter==="ALL"||op.route===cr11Filter).filter(op=>ioMatchesSearch(cr11Query,`${op.id} ${op.type} ${op.source} ${op.product}`));
  const list=rows.map(op=>ioProductRow({name:op.type,code:`${op.id} · ${op.source}`,primary:`${op.qty} ${op.uom}`,secondary:op.product,badge:op.statusLabel,badgeStatus:op.route==="UNKNOWN"?"warning":op.route==="PHYSICAL_RETURN_BLOCKED"?"warning":"info",attr:`data-cr11-operation="${op.id}"`})).join("");
  return `${ioSearchBar("Tìm mã nghiệp vụ, chứng từ hoặc hàng",'data-cr11-search',cr11Query)}${ac321CanonicalChips(cr11Filter,Object.entries(labels),'data-cr11-filter')}${list?`<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row,VBadge"><div class="io-product-list">${list}</div></div>`:ioEmpty("Không có nghiệp vụ phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`;
}
function render048CR11(state){
  if(activeFlowId!=="UIF-11")return renderGeneric(screens.find(s=>s.id==="SCR-048"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Kiểm soát nghiệp vụ kho",body:deniedBody(),centered:true,back:false});
  if(state==="LOADING")return appShell({title:"Kiểm soát nghiệp vụ kho",body:loadingBody(),back:false});
  if(state==="EMPTY")return appShell({title:"Kiểm soát nghiệp vụ kho",body:ioEmpty("Chưa có nghiệp vụ cần kiểm soát","Các nghiệp vụ đủ điều kiện sẽ xuất hiện tại đây."),back:false});
  return appShell({title:"Kiểm soát nghiệp vụ kho",body:cr11ListRows(),back:false});
}
function render049CR11(state){
  if(activeFlowId!=="UIF-11")return renderGeneric(screens.find(s=>s.id==="SCR-049"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Chi tiết nghiệp vụ kho",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Chi tiết nghiệp vụ kho",body:loadingBody()});
  const op=cr11Current();const routeState=state==="READY"?cr11StateFor(op):state;
  const context=crFactCard(op.id,[["Nghiệp vụ",op.type,true],["Chứng từ nguồn",op.source],["Kho",op.warehouse],["Hàng",op.product],["Số lượng",`${op.qty} ${op.uom}`],["Tác động",op.impact]],op.statusLabel,routeState==="UNKNOWN"?"warning":"info");
  if(routeState==="UNKNOWN")return appShell({title:"Chi tiết nghiệp vụ kho",body:`${vBanner("warning","Kết quả chưa xác định","Chưa được hủy, đảo hoặc tạo sửa sai cho tới khi kết quả của đúng lần xử lý này được xác lập.")}${context}`,actions:primaryFooter("Xác minh kết quả",'data-cr11-action="handoff-unknown"')});
  if(routeState==="BLOCKED_PHYSICAL_HANDOVER")return appShell({title:"Chi tiết nghiệp vụ kho",body:`${vBanner("warning","Không sửa bằng cách đưa hàng về kho","Hàng đã được bàn giao thực tế. Nếu khách trả hàng, phải ghi nhận đúng nghiệp vụ Hàng khách trả; sửa sai không thay thế việc nhận hàng thực tế.")}${context}`,actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"')});
  if(routeState==="TERMINAL")return appShell({title:"Chi tiết nghiệp vụ kho",body:`${vBanner("info","Không còn tác động để đảo","Nghiệp vụ đã bị hủy hoặc từ chối trước khi thực thi. Không có thay đổi tồn kho cần sửa.")}${context}`,actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"')});
  if(routeState==="CANCELABLE")return appShell({title:"Chi tiết nghiệp vụ kho",body:`${context}<p class="cr-footnote" data-ds-component="VText">Nghiệp vụ chưa thực thi nên có thể hủy mà không tạo biến động tồn kho.</p>`,actions:primaryFooter("Hủy yêu cầu",'data-cr11-action="open-cancel"',false,"danger")});
  return appShell({title:"Chi tiết nghiệp vụ kho",body:`${context}${ioSectionTitle("Dấu vết liên quan")}${crFactCard("Nghiệp vụ gốc",[["Ngày nghiệp vụ","01/09/2026"],["Trạng thái","Đã hoàn tất"],["Sửa sai trước đó","Không"]])}`,actions:primaryFooter("Sửa sai",'data-cr11-action="open-correction"')});
}
function render052CR11(state){
  if(activeFlowId!=="UIF-11")return renderGeneric(screens.find(s=>s.id==="SCR-052"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Kiểm soát nghiệp vụ",body:deniedBody(),centered:true});
  const op=cr11Current();
  if(state==="DEPENDENCY_BLOCKED")return appShell({title:"Chọn cách sửa",body:`${vBanner("warning","Chưa thể sửa sai","Có nghiệp vụ phía sau đang phụ thuộc. Hãy xử lý nghiệp vụ đó trước.")}${crFactCard(op.id,[["Nghiệp vụ",op.type,true],["Hàng",op.product],["Tác động hiện tại",op.impact]])}`,actions:primaryFooter("Về chi tiết",'data-cr11-action="back-detail"')});
  if(state==="PERIOD_POLICY_VIOLATION")return appShell({title:"Chọn cách sửa",body:`${vBanner("warning","Chưa có kỳ mở để ghi nhận sửa sai","Cần có kỳ ghi nhận hiện hành hợp lệ trước khi tiếp tục.")}${crFactCard(op.id,[["Ngày nghiệp vụ gốc","01/09/2026"],["Kỳ gốc","Đã khóa"]])}`,actions:primaryFooter("Về chi tiết",'data-cr11-action="back-detail"')});
  const cancelMode=state==="CANCEL_UNEXECUTED"||op.route==="CANCEL";
  if(cancelMode){
    const err=state==="VALIDATION_ERROR"&&!cr11CancelReason.trim()?vBanner("error","Cần nhập lý do hủy","Lý do giúp truy vết vì sao yêu cầu dừng trước khi thực thi."):"";
    const body=`${err}${vBanner("info","Hủy trước khi thực thi","Nghiệp vụ sẽ chuyển sang Đã hủy; tồn kho và giá trị không thay đổi.")}${crFactCard(op.id,[["Nghiệp vụ",op.type,true],["Chứng từ nguồn",op.source],["Tác động tồn kho","Không thay đổi"]])}${icTextarea("Lý do hủy",cr11CancelReason,'data-cr11-cancel-reason','Nhập lý do hủy')}`;
    return appShell({title:"Hủy yêu cầu kho",body,actions:primaryFooter("Hủy yêu cầu",'data-cr11-action="confirm-cancel"',!cr11CancelReason.trim(),"danger")});
  }
  const body=`${vBanner("info","Nghiệp vụ gốc luôn được giữ nguyên","Hệ thống sẽ tạo một nghiệp vụ sửa sai có liên kết; không sửa hoặc xóa lịch sử đã hoàn tất.")}${crFactCard(op.id,[["Nghiệp vụ",op.type,true],["Đã ghi nhận",`${op.qty} ${op.uom}`],["Kỳ gốc","Đã khóa · tác động sửa sai ghi ở kỳ mở hiện hành"]])}${ioSectionTitle("Chọn cách sửa")}<div class="cr-choice-list">${crChoice("cr11-strategy","DELTA","Sửa phần sai","Dùng khi phần sai có thể điều chỉnh độc lập và vẫn giữ đúng ý nghĩa chứng từ.",cr11Strategy==="DELTA",'data-cr11-strategy')}${crChoice("cr11-strategy","FULL","Hoàn nguyên và ghi lại đúng","Dùng khi toàn bộ nghiệp vụ không còn đúng hoặc phải xác lập lại nguyên khối.",cr11Strategy==="FULL",'data-cr11-strategy')}</div>`;
  return appShell({title:"Chọn cách sửa",body,actions:primaryFooter("Tiếp tục",'data-cr11-action="edit-correction"')});
}
function render050CR11(state){
  if(activeFlowId!=="UIF-11")return renderGeneric(screens.find(s=>s.id==="SCR-050"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Nội dung sửa sai",body:deniedBody(),centered:true});
  const op=cr11Current();const delta=Number(cr11CorrectQty)-Number(op.qty);
  const validation=state==="VALIDATION_ERROR"?vBanner("error","Kiểm tra nội dung sửa sai","Số đúng phải lớn hơn hoặc bằng 0 và cần có lý do."):state==="SOURCE_VERSION_STALE"?vBanner("warning","Nghiệp vụ nguồn đã thay đổi","Hãy quay lại chi tiết để đối chiếu dữ liệu hiện hành trước khi gửi."):state==="CONFLICT"?vBanner("warning","Đã có yêu cầu sửa sai khác","Không tạo yêu cầu sửa sai song song. Mở yêu cầu đang hoạt động để tiếp tục."):"";
  const body=`${validation}${crFactCard("Trước và sau",[["Nghiệp vụ gốc",op.id,true],["Số đã ghi nhận",`${op.qty} ${op.uom}`],["Cách sửa",cr11Strategy==="DELTA"?"Sửa phần sai":"Hoàn nguyên và ghi lại đúng"]])}<div class="form-field" data-ds-component="VNumberField"><label>Số đúng <span class="required">*</span></label><div class="input-shell"><input type="number" min="0" inputmode="decimal" value="${cr11CorrectQty}" data-cr11-correct-qty></div></div>${crFactCard("Hệ thống tự tính",[["Điều chỉnh",`${delta>0?"+":""}${delta} ${op.uom}`,true]])}${icTextarea("Lý do sửa sai",cr11CorrectionReason,'data-cr11-correction-reason','Mô tả ngắn điều đã sai và căn cứ sửa')}`;
  const disabled=Number(cr11CorrectQty)<0||!cr11CorrectionReason.trim()||state==="SOURCE_VERSION_STALE"||state==="CONFLICT";
  return appShell({title:"Nội dung sửa sai",body,actions:primaryFooter("Gửi phê duyệt",'data-cr11-action="submit-correction"',disabled)});
}
function render051CR11(state){
  if(activeFlowId!=="UIF-11")return renderGeneric(screens.find(s=>s.id==="SCR-051"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Duyệt sửa sai",body:deniedBody(),centered:true,back:false});
  if(state==="SELF_APPROVAL_NOT_ALLOWED")return appShell({title:"Duyệt sửa sai",body:`${vBanner("warning","Bạn không thể tự duyệt yêu cầu này","Người lập và người duyệt phải độc lập theo chính sách kiểm soát.")}`,back:false});
  if(state==="APPROVAL_ALREADY_DECIDED")return appShell({title:"Duyệt sửa sai",body:vBanner("info","Yêu cầu đã có quyết định","Mở kết quả sửa sai để xem trạng thái hiện hành."),actions:primaryFooter("Xem kết quả",'data-cr11-action="approval-result"'),back:false});
  const op=cr11Operations[1];const delta=Number(cr11CorrectQty)-Number(op.qty);
  const rejectError=state==="VALIDATION_ERROR"&&cr11ApprovalRejectOpen&&!cr11ApprovalRejectReason.trim()?vBanner("error","Cần nhập lý do từ chối","Lý do được lưu cùng quyết định phê duyệt."):"";
  const sheet=cr11ApprovalRejectOpen?`<div class="sheet-backdrop"><section class="bottom-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true"><div class="sheet-handle"></div><div class="sheet-title"><h3>Từ chối sửa sai</h3></div><div class="sheet-content">${rejectError}${icTextarea("Lý do từ chối",cr11ApprovalRejectReason,'data-cr11-approval-reason','Nhập lý do')}<div class="sheet-actions">${crTextAction("Đóng",'data-cr11-action="reject-close"')}<button class="button button--danger" type="button" data-cr11-action="reject-confirm" ${cr11ApprovalRejectReason.trim()?'':'disabled'}>Từ chối</button></div></div></section></div>`:"";
  const body=`${vBanner("info","Công việc phê duyệt độc lập","Quyết định chỉ duyệt phương án. Sau khi duyệt, hệ thống tự ghi nhận phần sửa sai nếu điều kiện vẫn hợp lệ.")}${crFactCard("Yêu cầu sửa sai",[["Nghiệp vụ gốc",op.id,true],["Người lập","Nguyễn An"],["Lý do",cr11CorrectionReason]])}${ioSectionTitle("Trước / sau")}${crFactCard("Số lượng",[["Trước",`${op.qty} ${op.uom}`],["Sau",`${cr11CorrectQty} ${op.uom}`],["Điều chỉnh",`${delta>0?"+":""}${delta} ${op.uom}`,true]])}${sheet}`;
  const actions=`<div class="cr-two-actions">${crTextAction("Từ chối",'data-cr11-action="reject-open"')}<button class="button button--primary button--full" type="button" data-cr11-action="approve" data-ds-component="VButton">Duyệt</button></div>`;
  return appShell({title:"Duyệt sửa sai",body,actions,back:false});
}
function render053CR11(state){
  if(activeFlowId!=="UIF-11")return renderGeneric(screens.find(s=>s.id==="SCR-053"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả sửa sai",body:deniedBody(),centered:true,back:false});
  if(state==="PROCESSING")return appShell({title:"Kết quả sửa sai",body:`${loadingBody()}${vBanner("info","Đang ghi nhận sửa sai","Hệ thống đang kiểm lại điều kiện và ghi nhận phần sửa sai theo quyết định đã duyệt.")}`,centered:true,back:false});
  if(state==="PENDING_APPROVAL")return appShell({title:"Kết quả sửa sai",body:ioResult("Đã gửi chờ duyệt","Bạn đã hoàn tất phần việc của mình. Người có quyền duyệt sẽ nhận một công việc riêng.",[["Nghiệp vụ gốc",cr11Current().id],["Tác động tồn kho","Chưa thay đổi"]],"warning"),actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"'),centered:true,back:false});
  if(state==="CANCELLED")return appShell({title:"Kết quả kiểm soát",body:ioResult("Đã hủy yêu cầu","Yêu cầu dừng trước khi thực thi; không phát sinh biến động kho hoặc thay đổi giá trị tồn kho.",[["Nghiệp vụ",cr11Current().id],["Tồn kho","Không thay đổi"]]),actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"'),centered:true,back:false});
  if(state==="REJECTED")return appShell({title:"Kết quả sửa sai",body:ioResult("Yêu cầu không được duyệt","Nghiệp vụ gốc được giữ nguyên và không có tác động tồn kho mới.",[["Nghiệp vụ gốc","IO-260901-014"],["Tồn kho","Không thay đổi"]],"warning"),actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"'),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Kết quả sửa sai",body:ioResult("Đang xác minh kết quả","Không tạo hoặc gửi lại yêu cầu sửa sai. Hệ thống đang xác minh đúng lần xử lý này.",[["Nghiệp vụ gốc","IO-260901-014"],["Kết quả","Chưa xác định"]],"warning"),actions:primaryFooter("Xác minh kết quả",'data-cr11-action="handoff-unknown"'),centered:true,back:false});
  if(state==="BLOCKED")return appShell({title:"Kết quả sửa sai",body:ioResult("Chưa thể ghi sửa sai","Điều kiện hiện hành không còn phù hợp. Nghiệp vụ gốc chưa bị thay đổi.",[["Nghiệp vụ gốc","IO-260901-014"],["Tác động mới","Không có"]],"warning"),actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"'),centered:true,back:false});
  return appShell({title:"Kết quả sửa sai",body:ioResult("Đã hoàn tất sửa sai","Nghiệp vụ gốc được giữ nguyên; bản ghi sửa sai mới đã ghi phần điều chỉnh và liên kết đầy đủ.",[["Nghiệp vụ gốc","IO-260901-014"],["Bản ghi sửa sai","IO-260907-109"],["Điều chỉnh",`${Number(cr11CorrectQty)-120} hộp`]]),actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"'),centered:true,back:false});
}

let crControlQuery="";
let cr16Filter="ALL";
let cr17Filter="ALL";
let cr16SelectedId="REC-260907-03";
let cr17SelectedId="REC-UNKNOWN-01";
let cr17ResolutionMode="";
const cr16Cases=[
  {id:"REC-260907-03",title:"Số liệu hiển thị lệch sổ kho",scope:"Nobivac DHPPi · Lô DH2507",severity:"Cần xử lý",tone:"warning",route:"PROJECTION",owner:"Kiểm soát kho"},
  {id:"REC-260907-04",title:"Cần sửa nghiệp vụ nguồn",scope:"Amox 500 · Lô L2407-A",severity:"Đang chờ",tone:"info",route:"CORRECTION",owner:"Kiểm soát kho"},
  {id:"REC-260907-05",title:"Chênh lệch do thời điểm ghi nhận",scope:"Găng tay M",severity:"Có thể đóng",tone:"info",route:"NO_REAL",owner:"Kiểm soát kho"},
  {id:"REC-260907-06",title:"Cần kiểm tra toàn vẹn sổ kho",scope:"Kho trung tâm · SP-00606",severity:"Ưu tiên cao",tone:"warning",route:"LEDGER",owner:"Vận hành nền tảng"},
  {id:"REC-260907-07",title:"Thông tin chứng từ nguồn chưa khớp",scope:"PN-260906-12",severity:"Đang chờ",tone:"info",route:"SOURCE",owner:"Nghiệp vụ nguồn"}
];
const cr17Cases=[
  {id:"REC-UNKNOWN-01",operation:"IO-260906-031",title:"Có bằng chứng đã phát sinh tác động",scope:"Vitamin C · Lô L2310-C · 5 hộp",evidence:"COMMITTED",severity:"Ưu tiên cao",tone:"warning",owner:"Kiểm soát kho"},
  {id:"REC-UNKNOWN-02",operation:"IO-260906-044",title:"Chưa phát hiện tác động tồn kho",scope:"Amox 500 · Lô L2407-A · 2 hộp",evidence:"NO_COMMIT",severity:"Cần xử lý",tone:"info",owner:"Kiểm soát kho"},
  {id:"REC-UNKNOWN-03",operation:"IO-260906-052",title:"Chưa đủ bằng chứng kết luận",scope:"Kho trung tâm · 1 lần xử lý",evidence:"INSUFFICIENT",severity:"Cần chuyên sâu",tone:"warning",owner:"Vận hành nền tảng"}
];
function cr16Current(){return cr16Cases.find(x=>x.id===cr16SelectedId)||cr16Cases[0];}
function cr17Current(){return cr17Cases.find(x=>x.id===cr17SelectedId)||cr17Cases[0];}
function cr079StateFor16(c){return c.route==="PROJECTION"?"PROJECTION_MISMATCH":c.route==="CORRECTION"?"CORRECTION_REQUIRED":c.route==="NO_REAL"?"NO_REAL_DIFFERENCE":c.route==="LEDGER"?"LEDGER_INTEGRITY_RISK":"SOURCE_MISMATCH";}
function cr079StateFor17(c){return c.evidence==="COMMITTED"?"UNKNOWN_EVIDENCE":c.evidence==="NO_COMMIT"?"UNKNOWN_EVIDENCE":"INSUFFICIENT_EVIDENCE";}
function crCaseList(active){
  const is17=activeFlowId==="UIF-17";const cases=is17?cr17Cases:cr16Cases;const filter=is17?cr17Filter:cr16Filter;
  const chipItems=is17?[["ALL","Tất cả"],["COMMITTED","Đã có tác động"],["NO_COMMIT","Chưa có tác động"],["INSUFFICIENT","Cần chuyên sâu"]]:[["ALL","Tất cả"],["ACTION","Cần xử lý"],["WAITING","Đang chờ"],["HIGH","Ưu tiên cao"]];
  const filtered=cases.filter(c=>{if(filter==="ALL")return true;if(is17)return c.evidence===filter;if(filter==="ACTION")return ["PROJECTION","CORRECTION"].includes(c.route);if(filter==="WAITING")return ["SOURCE"].includes(c.route);if(filter==="HIGH")return c.route==="LEDGER";return true;}).filter(c=>ioMatchesSearch(crControlQuery,`${c.id} ${c.title} ${c.scope} ${c.operation||""}`));
  const rows=filtered.map(c=>ioProductRow({name:c.title,code:is17?(c.operation||""):c.id,primary:is17?"":"",secondary:c.scope,badge:c.severity,badgeStatus:c.tone,attr:`data-cr-case="${c.id}"`})).join("");
  return `${ioSearchBar(is17?"Tìm mã nghiệp vụ hoặc hàng":"Tìm hồ sơ, sản phẩm hoặc chứng từ",'data-cr-control-search',crControlQuery)}${ac321CanonicalChips(filter,chipItems,is17?'data-cr17-filter':'data-cr16-filter')}${rows?`<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row,VBadge"><div class="io-product-list cr-case-list">${rows}</div></div>`:ioEmpty("Không có hồ sơ phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`;
}
function render078CR(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId))return renderGeneric(screens.find(s=>s.id==="SCR-078"),state);
  const title=activeFlowId==="UIF-17"?"Nghiệp vụ cần xác minh":"Đối soát sai lệch";
  if(state==="PERMISSION_DENIED")return appShell({title,body:deniedBody(),centered:true,back:false});
  if(state==="LOADING")return appShell({title,body:loadingBody(),back:false});
  if(state==="EMPTY")return appShell({title,body:ioEmpty(activeFlowId==="UIF-17"?"Không có nghiệp vụ cần xác minh":"Không có hồ sơ đối soát","Danh sách sẽ cập nhật khi có tín hiệu cần kiểm tra."),back:false});
  return appShell({title,body:crCaseList(),back:false});
}
function cr16EvidenceRows(c){
  if(c.route==="PROJECTION")return [["Nguồn nghiệp vụ","118 hộp · đã xác nhận"],["Sổ kho","118 hộp · khớp nguồn"],["Số liệu hiển thị","116 hộp · lệch −2"]];
  if(c.route==="CORRECTION")return [["Nguồn nghiệp vụ","120 hộp"],["Sổ kho","120 hộp"],["Kiểm tra thực tế","118 hộp · cần sửa nghiệp vụ"]];
  if(c.route==="NO_REAL")return [["Nguồn nghiệp vụ","118 hộp"],["Sổ kho","118 hộp"],["Báo cáo tại thời điểm cũ","116 hộp · khác do mốc thời gian"]];
  if(c.route==="LEDGER")return [["Nguồn nghiệp vụ","Có chứng từ"],["Sổ kho","Có dấu hiệu không nhất quán"],["Số liệu hiển thị","Không dùng để dựng lại sổ kho"]];
  return [["Chứng từ nguồn","Chưa khớp dữ liệu kho"],["Sổ kho","Chưa kết luận"],["Trạng thái","Đang chờ nghiệp vụ nguồn xác minh"]];
}
function cr17EvidenceRows(c){
  if(c.evidence==="COMMITTED")return [["Yêu cầu","Đã được tiếp nhận"],["Tác động tồn kho","Đã tìm thấy đúng phạm vi"],["Nghiệp vụ nguồn","Vẫn đang chờ kết quả"]];
  if(c.evidence==="NO_COMMIT")return [["Yêu cầu","Đã được tiếp nhận"],["Tác động tồn kho","Chưa phát hiện"],["Tác động dở dang","Không phát hiện"]];
  return [["Yêu cầu","Đã được tiếp nhận"],["Tác động tồn kho","Chưa đủ bằng chứng"],["Bằng chứng còn thiếu","Kết quả ghi nhận cuối cùng"]];
}
function crEvidenceCard(rows){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<section class="review-card cr-evidence" data-ds-component="${calibrated?'VSection':'VCard'}" ${calibrated?'data-composed-from="DS v2 / Info Row"':'data-ds-profile="card.readOnly"'}><div class="review-card-body">${rows.map(r=>`<div class="cr-evidence-row" ${calibrated?'data-ds-component="DS v2 / Info Row" data-figma-node="525:351"':''}><span data-ds-component="VText">${r[0]}</span><strong data-ds-component="VText">${r[1]}</strong></div>`).join("")}</div></section>`;}
function render079CR(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId))return renderGeneric(screens.find(s=>s.id==="SCR-079"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Bằng chứng & kết luận",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Bằng chứng & kết luận",body:loadingBody()});
  if(activeFlowId==="UIF-17"){
    const c=cr17Current();const actualState=state==="READY"?cr079StateFor17(c):state;let banner="",actions="";
    if(actualState==="INSUFFICIENT_EVIDENCE"){banner=vBanner("warning","Chưa đủ bằng chứng để kết luận","Nghiệp vụ vẫn ở trạng thái chưa xác định, phạm vi tiếp tục được bảo vệ và hồ sơ đã chuyển người có trách nhiệm xử lý.");actions=primaryFooter("Xem trạng thái xử lý",'data-cr17-action="show-escalated"');}
    else if(c.evidence==="COMMITTED"){banner=vBanner("info","Có bằng chứng nghiệp vụ đã hoàn tất","Tác động tồn kho đã tồn tại. Bước tiếp theo chỉ xác lập kết quả; không ghi lại tác động lần hai.");actions=primaryFooter("Xem phương án xác lập",'data-cr17-action="open-plan"');}
    else{banner=vBanner("info","Có bằng chứng chưa ghi nhận tác động","Không phát hiện tác động tồn kho hoặc phần tác động dở dang. Có thể tiếp tục đúng lần xử lý này, giữ nguyên định danh và nội dung đã xác nhận.");actions=primaryFooter("Xem phương án tiếp tục",'data-cr17-action="open-plan"');}
    const body=`${banner}${crFactCard("Phạm vi cần xác minh",[["Nghiệp vụ",c.operation,true],["Phạm vi",c.scope],["Người xử lý",c.owner]])}${ioSectionTitle("Bằng chứng")}${crEvidenceCard(cr17EvidenceRows(c))}`;
    return appShell({title:"Bằng chứng kết quả",body,actions});
  }
  const c=cr16Current();const actualState=state==="READY"?cr079StateFor16(c):state;let banner="",actions="";
  if(actualState==="PROJECTION_MISMATCH"){banner=vBanner("info","Sổ kho đúng, số liệu hiển thị sai","Chỉ dữ liệu dẫn xuất cần được khôi phục. Không thay đổi sổ kho hoặc nghiệp vụ nguồn.");actions=primaryFooter("Khôi phục số liệu hiển thị",'data-cr16-action="open-plan"');}
  else if(actualState==="CORRECTION_REQUIRED"){banner=vBanner("warning","Cần sửa nghiệp vụ đã hoàn tất","Sai lệch nằm ở nghiệp vụ nguồn. Hệ thống không chỉnh số dư trực tiếp để làm cho số liệu khớp.");actions=primaryFooter("Mở yêu cầu sửa sai",'data-cr16-action="handoff-correction"');}
  else if(actualState==="NO_REAL_DIFFERENCE"){banner=vBanner("info","Không có sai lệch tồn kho thực","Khác biệt đến từ thời điểm lấy số liệu. Có thể rà soát để đóng hồ sơ.");actions=primaryFooter("Rà soát đóng hồ sơ",'data-cr16-action="review-close"');}
  else if(actualState==="LEDGER_INTEGRITY_RISK"){banner=vBanner("warning","Cần kiểm tra toàn vẹn sổ kho","Tạm dừng khôi phục tự động và sửa sai. Không dùng báo cáo hoặc chứng từ nguồn để dựng lại sổ kho.");actions=primaryFooter("Xem trạng thái chuyển xử lý",'data-cr16-action="show-escalated"');}
  else if(actualState==="SOURCE_MISMATCH"){banner=vBanner("info","Đang chờ nghiệp vụ nguồn xác minh","Hồ sơ được giữ mở. Phân hệ kho không tự sửa dữ liệu nguồn hoặc sổ kho.");}
  else if(actualState==="INSUFFICIENT_EVIDENCE"){banner=vBanner("warning","Chưa đủ bằng chứng kết luận","Giữ hồ sơ mở và tiếp tục thu thập bằng chứng; không khôi phục hoặc sửa sai khi chưa xác định nguyên nhân.");}
  const body=`${banner}${crFactCard(c.id,[["Phạm vi",c.scope,true],["Người xử lý",c.owner],["Bảo vệ phạm vi",c.route==="NO_REAL"?"Không cần khóa":"Đang áp dụng đúng phạm vi"]])}${ioSectionTitle("Đối chiếu")}${crEvidenceCard(cr16EvidenceRows(c))}`;
  return appShell({title:"Bằng chứng & kết luận",body,actions});
}
function render080CR(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId))return renderGeneric(screens.find(s=>s.id==="SCR-080"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Phương án xử lý",body:deniedBody(),centered:true});
  if(state==="LOCKED")return appShell({title:"Phương án xử lý",body:vBanner("warning","Phạm vi đang do hồ sơ khác bảo vệ","Không xử lý song song cùng phạm vi. Mở hồ sơ đang bảo vệ để tiếp tục.")});
  if(state==="CONFLICT")return appShell({title:"Phương án xử lý",body:vBanner("warning","Kết luận đã thay đổi","Bằng chứng mới làm thay đổi phương án. Quay lại bước bằng chứng để rà soát.")});
  if(activeFlowId==="UIF-17"){
    const c=cr17Current();
    if(c.evidence==="INSUFFICIENT"||state==="INSUFFICIENT_EVIDENCE")return appShell({title:"Phương án xử lý",body:`${vBanner("warning","Chưa có phương án xử lý an toàn","Giữ nguyên trạng thái chưa xác định và phạm vi được bảo vệ; hồ sơ đã chuyển người có trách nhiệm.")}${crFactCard("Phạm vi xử lý",[["Nghiệp vụ",c.operation,true],["Người xử lý",c.owner],["Định danh","Giữ nguyên"]])}`,actions:primaryFooter("Xem trạng thái xử lý",'data-cr17-action="show-escalated"')});
    const committed=c.evidence==="COMMITTED";const title=committed?"Xác lập đã hoàn tất":"Tiếp tục lần xử lý này";
    const desc=committed?"Dùng tác động đã tồn tại để xác lập kết quả. Không ghi lại biến động kho, số dư hoặc tác động liên quan lần hai.":"Chỉ tiếp tục sau khi đã chứng minh chưa có tác động bán phần. Giữ nguyên nghiệp vụ và nội dung đã xác nhận.";
    const body=`${vBanner("info",title,desc)}${crFactCard("Phạm vi xử lý",[["Nghiệp vụ",c.operation,true],["Phạm vi",c.scope],["Định danh","Giữ nguyên"]])}${crFactCard("Sẽ không thực hiện",[["Tạo nghiệp vụ mới","Không"],["Tự hoàn nguyên","Không"],["Thay đổi nội dung đã xác nhận","Không"]])}`;
    return appShell({title:"Phương án xử lý",body,actions:primaryFooter(title,`data-cr17-action="execute-plan"`)});
  }
  const c=cr16Current();const body=`${vBanner("info","Khôi phục số liệu hiển thị","Bằng chứng đã xác nhận sổ kho đúng và dữ liệu hiển thị sai. Hệ thống chỉ khôi phục phần dữ liệu dẫn xuất trong phạm vi này.")}${crFactCard("Phạm vi",[["Hồ sơ",c.id,true],["Hàng",c.scope],["Bảo vệ phạm vi","Đang áp dụng"]])}${crFactCard("Tác động",[["Sổ kho","Không thay đổi"],["Nghiệp vụ nguồn","Không thay đổi"],["Số liệu hiển thị","Được khôi phục theo sổ kho đã xác nhận"]])}`;
  return appShell({title:"Phương án xử lý",body,actions:primaryFooter("Bắt đầu khôi phục",'data-cr16-action="start-recovery"')});
}
function render081CR(state){
  if(activeFlowId!=="UIF-16")return renderGeneric(screens.find(s=>s.id==="SCR-081"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Khôi phục số liệu",body:deniedBody(),centered:true});
  const c=cr16Current();
  if(state==="VALIDATION_FAILED"||state==="CONFLICT")return appShell({title:"Khôi phục số liệu",body:`${vBanner("warning","Chưa thể hoàn tất khôi phục","Bằng chứng hoặc phạm vi đã thay đổi. Hồ sơ vẫn được giữ mở và sổ kho không bị sửa.")}${crFactCard(c.id,[["Phạm vi",c.scope,true],["Sổ kho","Không thay đổi"]])}`});
  if(state==="READY")return appShell({title:"Khôi phục số liệu",body:`${vBanner("success","Đã khôi phục số liệu hiển thị","Kết quả đã sẵn sàng để rà soát trước khi đóng hồ sơ và mở khóa.")}${crFactCard(c.id,[["Phạm vi",c.scope,true],["Sổ kho","Không thay đổi"],["Số liệu hiển thị","Đã cập nhật"]])}`,actions:primaryFooter("Rà soát kết quả",'data-cr16-action="review-result"')});
  return appShell({title:"Đang khôi phục số liệu",body:`${loadingBody()}${vBanner("info","Hệ thống đang xử lý","Bạn có thể rời màn hình. Hồ sơ sẽ cập nhật khi dữ liệu hiển thị đã được khôi phục.")}${crFactCard(c.id,[["Phạm vi",c.scope,true],["Sổ kho","Không thay đổi"]])}`});
}
function render082CR(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId))return renderGeneric(screens.find(s=>s.id==="SCR-082"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Rà soát kết quả",body:deniedBody(),centered:true});
  if(activeFlowId==="UIF-17"){
    const c=cr17Current();const committed=(cr17ResolutionMode||c.evidence)==="COMMITTED";const continued=(cr17ResolutionMode||"")==="CONTINUED";
    const rows=committed?[["Nghiệp vụ",c.operation,true],["Kết quả","Đã hoàn tất"],["Tác động tồn kho","Giữ nguyên tác động đã có"],["Định danh","Không thay đổi"]]:[["Nghiệp vụ",c.operation,true],["Kết quả",continued?"Đã hoàn tất":"Đã có kết quả mới"],["Định danh","Không thay đổi"],["Nghiệp vụ mới","Không tạo"]];
    const body=`${vBanner("info","Kết quả đã được xác lập","Hệ thống đã giữ đúng nghiệp vụ ban đầu và không tạo tác động trùng.")}${crFactCard("Rà soát kết quả cuối",rows)}`;
    return appShell({title:"Rà soát kết quả",body,actions:primaryFooter("Hoàn tất xác minh",'data-cr17-action="finish-review"')});
  }
  const c=cr16Current();
  if(state==="MISMATCH_REMAINS")return appShell({title:"Rà soát kết quả",body:`${vBanner("warning","Sai lệch vẫn còn","Giữ hồ sơ mở và phạm vi được bảo vệ. Không đóng hồ sơ cho tới khi có đủ bằng chứng xác nhận kết quả.")}${crFactCard(c.id,[["Sổ kho","118 hộp"],["Số liệu hiển thị","117 hộp"],["Chênh lệch","−1 hộp",true]])}`});
  const noReal=c.route==="NO_REAL";const body=`${vBanner("info",noReal?"Không có sai lệch thực":"Số liệu đã khớp",noReal?"Khác biệt trước đó được giải thích bằng mốc thời gian và đã có đủ bằng chứng để đóng hồ sơ.":"Kết quả hiển thị hiện khớp với sổ kho đã được xác nhận.")}${crFactCard(c.id,[["Sổ kho","118 hộp"],["Số liệu hiển thị","118 hộp"],["Chênh lệch","0 hộp",true],["Phạm vi",noReal?"Không khóa":"Sẵn sàng mở khóa"]])}`;
  return appShell({title:"Rà soát kết quả",body,actions:primaryFooter("Đóng hồ sơ & mở khóa",'data-cr16-action="close-case"')});
}
function render083CR(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId))return renderGeneric(screens.find(s=>s.id==="SCR-083"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả xử lý",body:deniedBody(),centered:true,back:false});
  if(state==="PROCESSING")return appShell({title:"Kết quả xử lý",body:loadingBody(),centered:true,back:false});
  if(activeFlowId==="UIF-17"){
    const c=cr17Current();
    if(state==="UNKNOWN"||state==="ESCALATED")return appShell({title:"Kết quả xác minh",body:ioResult("Chưa xác định — đã chuyển xử lý","Hệ thống chưa đoán kết quả. Phạm vi tiếp tục được bảo vệ và người có trách nhiệm đã nhận hồ sơ.",[["Nghiệp vụ",c.operation],["Người xử lý",c.owner],["Phạm vi","Tiếp tục được bảo vệ"]],"warning"),actions:primaryFooter("Về danh sách xác minh",'data-cr17-action="to-list"'),centered:true,back:false});
    return appShell({title:"Kết quả xác minh",body:ioResult("Đã xác lập kết quả nghiệp vụ","Kết quả chính thức đã được ghi cho đúng nghiệp vụ; không tạo nghiệp vụ mới hoặc ghi tác động trùng.",[["Nghiệp vụ",c.operation],["Định danh","Giữ nguyên"],["Trạng thái","Đã hoàn tất"]]),actions:primaryFooter("Về danh sách xác minh",'data-cr17-action="to-list"'),centered:true,back:false});
  }
  const c=cr16Current();
  if(state==="UNKNOWN"||state==="ESCALATED")return appShell({title:"Kết quả đối soát",body:ioResult("Đã chuyển xử lý chuyên sâu","Hồ sơ vẫn mở; phạm vi rủi ro tiếp tục được bảo vệ cho tới khi có bằng chứng mới.",[["Hồ sơ",c.id],["Người xử lý",c.owner],["Phạm vi","Chưa mở khóa"]],"warning"),actions:primaryFooter("Về danh sách đối soát",'data-cr16-action="to-list"'),centered:true,back:false});
  return appShell({title:"Kết quả đối soát",body:ioResult("Đã xử lý sai lệch","Hồ sơ được đóng bằng bằng chứng và phạm vi liên quan đã được mở khóa.",[["Hồ sơ",c.id],["Kết luận",c.route==="NO_REAL"?"Không có sai lệch thực":"Số liệu đã khớp"],["Phạm vi","Đã mở khóa"]]),actions:primaryFooter("Về danh sách đối soát",'data-cr16-action="to-list"'),centered:true,back:false});
}


// v1.8.0 — Control Foundation & Inquiry · BJ12 / UIF12 + BJ15 / UIF15
// Product UI keeps migration controls and read-only inquiry separate from architecture/recovery mechanics.
let cf12FileName = "ton-kho-dau-ky-2026.xlsx";
let cf12Cutoff = "2026-08-31";
let cf12ControlQty = "4820";
let cf12ControlValue = "386240000";
let cf12RejectOpen = false;
let cf12RejectReason = "";
const cf12Summary = { rows: 82, products: 36, parsedQty: 4820, parsedValue: 386240000, sellableRows: 74, nonSellableRows: 8 };
const cfMoney = (n) => `${Number(n || 0).toLocaleString("vi-VN")} ₫`;
const cfMoneyInput = (n) => n === "" || n == null ? "" : Number(String(n).replace(/[^0-9-]/g, "") || 0).toLocaleString("vi-VN");
const cfNumber = (n) => Number(n || 0).toLocaleString("vi-VN");
function cfDateVN(value){const v=String(value||"");const m=v.match(/^(\d{4})-(\d{2})-(\d{2})$/);return m?`${m[3]}/${m[2]}/${m[1]}`:v;}
function cfDateKey(value){const v=String(value||"");const m=v.match(/^(\d{2})\/(\d{2})\/(\d{4})$/);return m?`${m[3]}-${m[2]}-${m[1]}`:v;}
function cfField(label,value,attr,type="text",hint=""){
  const isDate=type==="date", isMoney=type==="money", htmlType=(isDate||isMoney)?"text":type, shown=isDate?cfDateVN(value):isMoney?cfMoneyInput(value):value;
  const extra=isDate?' inputmode="numeric" placeholder="dd/mm/yyyy"':isMoney?' inputmode="numeric"':"";
  const component=isDate?"VDatePickerField":isMoney?"VMoneyField":type==="number"?"VNumberField":"VTextField";
  const figmaNode=isMoney?' data-figma-node="522:7322"':'';
  const stateAttr=isMoney?` data-ds-prop-state="${shown!==""?"Filled":"Default"}"`:"";
  const moneySuffix=isMoney?'<span class="money-suffix" aria-hidden="true">₫</span>':"";
  return `<div class="form-field cf-field" data-ds-component="${component}"${figmaNode}${stateAttr}><label>${label}</label><div class="input-shell"><input type="${htmlType}" value="${escapeAttribute(shown)}" ${attr}${extra}>${moneySuffix}</div>${hint?`<small class="field-help">${hint}</small>`:""}</div>`;
}
function cfSelect(label,value,options,attr,hint=""){
  return `<div class="form-field cf-field" data-ds-component="VSelect"><label>${label}</label><div class="input-shell"><select ${attr}>${options.map(([v,l])=>`<option value="${escapeAttribute(v)}" ${String(v)===String(value)?"selected":""}>${l}</option>`).join("")}</select><span>${icon("chevronDown","icon--sm")}</span></div>${hint?`<small class="field-help">${hint}</small>`:""}</div>`;
}
function cfSummaryGrid(items){return `<div class="cf-summary-grid">${items.map(([l,v])=>`<div class="cf-summary-tile"><small>${l}</small><strong>${v}</strong></div>`).join("")}</div>`;}
function cfSecondary(label,attr,tone="neutral"){return `<button class="button button--secondary cf-secondary" type="button" ${attr} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.medium" data-ds-prop-tone="VComponentTone.${tone}">${label}</button>`;}
function cf12ReviewCard(){
  return `${crFactCard("Phạm vi khởi tạo",[["Kho","Kho trung tâm",true],["Ngày chốt số dư",cfDateVN(cf12Cutoff)],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`],["Dòng dữ liệu",`${cfNumber(cf12Summary.rows)} dòng`]])}${crFactCard("Số kiểm soát",[["Tổng số lượng",cfNumber(cf12ControlQty),true],["Tổng giá trị",cfMoney(cf12ControlValue),true],["Đối chiếu tệp","Khớp số kiểm soát"]])}`;
}
function render066CF12(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Khởi tạo tồn kho",body:deniedBody(),centered:true,back:false});
  if(state==="LOADING")return appShell({title:"Khởi tạo tồn kho",body:loadingBody(),back:false});
  if(state==="PREPARING")return appShell({title:"Khởi tạo tồn kho",body:`${vBanner("info","Đang chuẩn bị số dư đầu kỳ","Tệp và số kiểm soát đã được giữ lại. Tiếp tục rà soát dữ liệu trước khi gửi phê duyệt.")}${cf12ReviewCard()}`,actions:primaryFooter("Tiếp tục chuẩn bị",'data-cf12-action="continue-prepare"'),back:false});
  if(state==="PENDING_APPROVAL")return appShell({title:"Khởi tạo tồn kho",body:`${vBanner("info","Đã gửi chờ duyệt","Bạn đã hoàn tất phần chuẩn bị. Tồn kho chưa được khởi tạo ở bước này.")}${cf12ReviewCard()}`,back:false});
  if(state==="REJECTED")return appShell({title:"Khởi tạo tồn kho",body:`${vBanner("warning","Cần sửa trước khi gửi lại","Người duyệt đã từ chối số dư đầu kỳ. Tồn kho chưa được khởi tạo.")}${crFactCard("Lý do",[["Nội dung","Đối chiếu lại số lượng của nhóm Vaccine",true],["Tác động tồn kho","Chưa có"]])}`,actions:primaryFooter("Sửa dữ liệu",'data-cf12-action="fix-rejected"'),back:false});
  if(state==="UNKNOWN")return appShell({title:"Khởi tạo tồn kho",body:`${vBanner("warning","Đang xác minh kết quả","Không tạo một lần khởi tạo khác. Hệ thống đang xác minh đúng lần xử lý hiện tại trước khi mở nghiệp vụ kho bình thường.")}${crFactCard("Trạng thái",[["Ngày chốt số dư",cfDateVN(cf12Cutoff),true],["Khởi tạo mới","Bị khóa cho đến khi có kết luận"]])}`,back:false});
  if(state==="ACTIVE_RECONCILED")return appShell({title:"Khởi tạo tồn kho",body:ioResult("Tồn kho đầu kỳ đã sẵn sàng","Số dư đầu kỳ đã được ghi nhận và đối chiếu. Nghiệp vụ kho bình thường có thể bắt đầu.",[["Ngày chốt số dư",cfDateVN(cf12Cutoff)],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`],["Đối soát","Đã khớp"]]),actions:primaryFooter("Xem tồn kho",'data-cf12-action="see-inventory"'),centered:true,back:false});
  const body=`${crFactCard("Khởi tạo lần đầu",[["Kho","Kho trung tâm",true],["Trạng thái","Chưa thiết lập"],["Quy tắc","Chỉ có một số dư đầu kỳ chính thức"]])}<p class="io-footnote">Sau khi hoàn tất, mọi sửa sai phát sinh được xử lý bằng nghiệp vụ điều chỉnh có kiểm soát; không mở lại số dư đầu kỳ.</p>`;
  return appShell({title:"Khởi tạo tồn kho",body,actions:primaryFooter("Bắt đầu",'data-cf12-action="start"'),back:false});
}
function render067CF12(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Dữ liệu tồn kho đầu kỳ",body:deniedBody(),centered:true});
  if(state==="LOCKED")return appShell({title:"Dữ liệu tồn kho đầu kỳ",body:`${vBanner("info","Dữ liệu đang được xử lý","Tệp nguồn và số kiểm soát hiện chỉ đọc.")}${cf12ReviewCard()}`});
  if(state==="CONFLICT")return appShell({title:"Dữ liệu tồn kho đầu kỳ",body:`${vBanner("warning","Phạm vi vừa thay đổi","Không tiếp tục trên dữ liệu cũ. Tải lại thông tin hiện hành trước khi kiểm tra tệp.")}${cf12ReviewCard()}`});
  const invalid=state==="VALIDATION_ERROR";
  const body=`${invalid?vBanner("error","Chưa đủ dữ liệu kiểm soát","Chọn tệp, ngày chốt và nhập cả tổng số lượng lẫn tổng giá trị độc lập trước khi kiểm tra."):""}<section class="review-card cf-file-card" data-ds-component="VFileDropZone"><div class="review-card-body"><div class="cf-file-icon">${icon("fileText")}</div><div class="cf-file-copy"><strong>Tệp số dư đầu kỳ</strong><small>${esc(cf12FileName||"Chưa chọn tệp")}</small></div>${cfSecondary("Chọn tệp",'data-cf12-action="choose-file"')}</div></section><div class="form-stack">${cfField("Ngày chốt số dư",cf12Cutoff,'data-cf12-cutoff','date','Dùng đúng ngày nghiệp vụ mà số dư đầu kỳ có hiệu lực.')}${cfField("Tổng số lượng kiểm soát",cf12ControlQty,'data-cf12-control-qty','number','Nhập từ nguồn kiểm soát độc lập với tệp chi tiết.')}${cfField("Tổng giá trị kiểm soát",cf12ControlValue,'data-cf12-control-value','money','Giá trị tồn kho đầu kỳ theo nguồn kiểm soát.')}</div>`;
  const disabled=!cf12FileName||!cf12Cutoff||!(Number(cf12ControlQty)>=0)||!(Number(cf12ControlValue)>=0);
  return appShell({title:"Dữ liệu tồn kho đầu kỳ",body,actions:primaryFooter("Kiểm tra dữ liệu",'data-cf12-action="check"',disabled)});
}
function render068CF12(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả kiểm tra dữ liệu",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Kết quả kiểm tra dữ liệu",body:loadingBody()});
  if(state==="CONFLICT")return appShell({title:"Kết quả kiểm tra dữ liệu",body:`${vBanner("warning","Nguồn dữ liệu đã thay đổi","Kết quả kiểm tra cũ không còn hiệu lực. Chọn lại tệp hoặc tải lại phạm vi.")}${cf12ReviewCard()}`,actions:primaryFooter("Quay lại dữ liệu",'data-cf12-action="back-file"')});
  if(state==="VALIDATION_FAILED"){
    const body=`${vBanner("error","Còn dòng chưa hợp lệ","Không có dữ liệu nào được ghi nhận. Sửa các dòng lỗi trong nguồn rồi kiểm tra lại.")}${cfSummaryGrid([["Dòng đọc được",cfNumber(cf12Summary.rows)],["Sản phẩm",cfNumber(cf12Summary.products)],["Lỗi cần sửa","3"]])}${crFactCard("Dòng 18 · Vaccine Newcastle",[["Vấn đề","Chưa xác định sản phẩm trong VET45",true],["Cách xử lý","Sửa dữ liệu nguồn; không tạo sản phẩm trong luồng này"]])}${crFactCard("Dòng 44 · Amox 500",[["Vấn đề","Trùng cùng sản phẩm + kho + tình trạng + lô",true],["Cách xử lý","Giữ một dòng dữ liệu chính thức; không tự cộng gộp"]])}${crFactCard("Dòng 61 · Nobivac DHPPi",[["Vấn đề","Thiếu hạn dùng bắt buộc của lô",true],["Cách xử lý","Bổ sung hạn dùng đúng theo nhãn lô"]])}`;
    return appShell({title:"Kết quả kiểm tra dữ liệu",body,actions:primaryFooter("Chọn lại tệp",'data-cf12-action="back-file"')});
  }
  if(state==="CONTROL_TOTAL_MISMATCH"){
    const body=`${vBanner("warning","Số kiểm soát không khớp","Không gửi phê duyệt cho đến khi số trong tệp khớp nguồn kiểm soát độc lập.")}${crFactCard("Đối chiếu số lượng",[["Theo tệp",cfNumber(cf12Summary.parsedQty),true],["Số kiểm soát",cfNumber(Number(cf12ControlQty)+12),true],["Chênh lệch","−12"]])}${crFactCard("Đối chiếu giá trị",[["Theo tệp",cfMoney(cf12Summary.parsedValue),true],["Số kiểm soát",cfMoney(cf12ControlValue),true]])}`;
    return appShell({title:"Kết quả kiểm tra dữ liệu",body,actions:primaryFooter("Quay lại dữ liệu",'data-cf12-action="back-file"')});
  }
  const body=`${vBanner("success","Dữ liệu đã qua kiểm tra","Tệp chi tiết khớp số kiểm soát và không còn blocker dữ liệu trong phạm vi này.")}${cfSummaryGrid([["Dòng dữ liệu",cfNumber(cf12Summary.rows)],["Sản phẩm",cfNumber(cf12Summary.products)],["Tổng số lượng",cfNumber(cf12Summary.parsedQty)],["Tổng giá trị",cfMoney(cf12Summary.parsedValue)]])}${crFactCard("Kiểm tra chính",[["Số âm","Không có"],["Dòng trùng khóa nghiệp vụ","Không có"],["Lô / hạn dùng","Hợp lệ"],["Số kiểm soát","Đã khớp",true]])}`;
  return appShell({title:"Kết quả kiểm tra dữ liệu",body,actions:primaryFooter("Rà soát số dư",'data-cf12-action="review"')});
}
function render069CF12(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Rà soát số dư đầu kỳ",body:deniedBody(),centered:true});
  if(state==="CONFLICT")return appShell({title:"Rà soát số dư đầu kỳ",body:`${vBanner("warning","Dữ liệu vừa thay đổi","Quay lại kiểm tra nguồn hiện hành trước khi gửi phê duyệt.")}${cf12ReviewCard()}`,actions:primaryFooter("Quay lại dữ liệu",'data-cf12-action="back-file"')});
  if(state==="VALIDATION_ERROR")return appShell({title:"Rà soát số dư đầu kỳ",body:`${vBanner("error","Chưa thể gửi phê duyệt","Dữ liệu không còn thỏa điều kiện đã kiểm tra. Quay lại bước kiểm tra.")}${cf12ReviewCard()}`,actions:primaryFooter("Kiểm tra lại",'data-cf12-action="back-check"')});
  if(state==="PENDING_APPROVAL")return appShell({title:"Rà soát số dư đầu kỳ",body:`${vBanner("info","Đã gửi chờ duyệt","Bạn đã hoàn tất phần việc chuẩn bị. Tồn kho chưa thay đổi.")}${cf12ReviewCard()}`});
  const body=`${cf12ReviewCard()}${crFactCard("Phân bố dữ liệu",[["Bán được",`${cfNumber(cf12Summary.sellableRows)} dòng`,true],["Không bán được",`${cfNumber(cf12Summary.nonSellableRows)} dòng`],["Lô / hạn dùng","Giữ theo dữ liệu sản phẩm"]])}`;
  return appShell({title:"Rà soát số dư đầu kỳ",body,actions:primaryFooter("Gửi phê duyệt",'data-cf12-action="send-approval"')});
}
function cf12ApprovalFooter(){return `<div class="ic-action-stack cf12-approval-actions">${cfSecondary("Từ chối",'data-cf12-action="open-reject"',"danger")}${primaryFooter("Duyệt",'data-cf12-action="approve"')}</div>`;}
function cf12RejectSheet(){
  if(!cf12RejectOpen)return "";
  return `<div class="sheet-backdrop" data-cf12-action="close-reject"><section class="bottom-sheet cf12-reject-sheet" role="dialog" aria-modal="true" aria-label="Từ chối số dư đầu kỳ" onclick="event.stopPropagation()" data-ds-component="VBottomSheet" data-figma-node="4695:6353"><div class="sheet-handle"></div><div class="sheet-title"><h3>Từ chối số dư đầu kỳ</h3></div><div class="sheet-divider"></div><div class="sheet-content">${icTextarea("Lý do từ chối",cf12RejectReason,'data-cf12-reject-reason','Nhập nội dung người lập cần sửa')}<div class="sheet-actions">${cfSecondary("Hủy",'data-cf12-action="close-reject"')}<button class="button button--primary" type="button" data-cf12-action="confirm-reject" data-ds-component="VButton" ${cf12RejectReason.trim()?"":"disabled"}>Xác nhận từ chối</button></div></div></section></div>`;
}
function render070CF12(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Duyệt số dư đầu kỳ",body:deniedBody(),centered:true,back:false});
  if(state==="SELF_APPROVAL_NOT_ALLOWED")return appShell({title:"Duyệt số dư đầu kỳ",body:`${vBanner("warning","Không thể tự duyệt","Người chuẩn bị số dư đầu kỳ không được đồng thời là người quyết định.")}${cf12ReviewCard()}`,back:false});
  if(state==="APPROVAL_ALREADY_DECIDED")return appShell({title:"Duyệt số dư đầu kỳ",body:`${vBanner("info","Công việc đã có quyết định","Quyết định hợp lệ đầu tiên có hiệu lực. Màn này chỉ còn để xem bằng chứng đã dùng.")}${cf12ReviewCard()}`,back:false});
  if(state==="VALIDATION_ERROR")return appShell({title:"Duyệt số dư đầu kỳ",body:`${vBanner("error","Không thể quyết định","Dữ liệu nền không còn hợp lệ. Không ghi nhận số dư từ bằng chứng đã thay đổi.")}${cf12ReviewCard()}`,back:false});
  const body=`${vBanner("info","Kiểm tra trước khi duyệt","Đối chiếu ngày chốt, số kiểm soát và phạm vi. Nếu duyệt, hệ thống sẽ ghi nhận số dư sau khi kiểm tra lại điều kiện.")}${crFactCard("Người chuẩn bị",[["Người lập","Nguyễn An",true],["Ngày gửi","07/09/2026 · 10:32"]])}${cf12ReviewCard()}${cf12RejectSheet()}`;
  return appShell({title:"Duyệt số dư đầu kỳ",body,actions:cf12ApprovalFooter(),back:false});
}
function render071CF12(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả khởi tạo tồn kho",body:deniedBody(),centered:true,back:false});
  if(state==="PROCESSING")return appShell({title:"Kết quả khởi tạo tồn kho",body:`${loadingBody()}${vBanner("info","Đang ghi nhận và đối soát","Hệ thống đang xử lý số dư được duyệt. Không cần thực hiện thêm thao tác.")}`,centered:true,back:false});
  if(state==="UNKNOWN"||state==="COMMIT_UNKNOWN")return appShell({title:"Kết quả khởi tạo tồn kho",body:ioResult("Đang xác minh kết quả","Chưa thể kết luận lần khởi tạo đã được ghi nhận hay chưa. Không tạo lần mới hoặc nhập lại số dư.",[["Ngày chốt số dư",cfDateVN(cf12Cutoff)],["Khởi tạo mới","Đang bị khóa"]],"warning"),centered:true,back:false});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả khởi tạo tồn kho",body:ioResult("Chưa khởi tạo tồn kho","Yêu cầu không được thực hiện. Không có số dư đầu kỳ nào được ghi nhận.",[["Ngày chốt số dư",cfDateVN(cf12Cutoff)],["Tác động tồn kho","Không có"]],"warning"),actions:primaryFooter("Về trạng thái khởi tạo",'data-cf12-action="result-home"'),centered:true,back:false});
  const body=ioResult("Đã khởi tạo tồn kho đầu kỳ","Số dư đã được ghi nhận nguyên khối và đối soát thành công. Mọi sửa sai tiếp theo đi qua nghiệp vụ điều chỉnh có kiểm soát.",[["Ngày chốt số dư",cfDateVN(cf12Cutoff)],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`],["Tổng giá trị",cfMoney(cf12Summary.parsedValue)],["Đối soát","Đã khớp"]]);
  return appShell({title:"Kết quả khởi tạo tồn kho",body,actions:primaryFooter("Xem tồn kho",'data-cf12-action="see-inventory"'),centered:true,back:false});
}

let cf15ReportType = "INVENTORY";
let cf15DateMode = "BUSINESS";
let cf15Warehouse = "MAIN";
let cf15Product = "ALL";
let cf15From = "2026-09-01";
let cf15To = "2026-09-07";
let cf15SelectedProduct = "P-NOB";
let cf15SelectedMovement = "M-RECEIPT";
let cf15ProductSheetOpen = false;
let cf15ExportFrom = "REPORT";
let cf15FinanceIncluded = true;
const cf15Products = [
 {id:"P-NOB",name:"Nobivac DHPPi",code:"SP-00418",qty:118,uom:"hộp",available:106,value:10030000,tracking:"LOT",lots:[{lot:"N2407-01",qty:70,state:"Bán được"},{lot:"N2408-02",qty:36,state:"Bán được"},{lot:"N2407-Q",qty:12,state:"Cách ly"}]},
 {id:"P-AMX",name:"Amox 500",code:"SP-00128",qty:24,uom:"hộp",available:18,value:3480000,tracking:"LOT",lots:[{lot:"L2407-A",qty:18,state:"Bán được"},{lot:"L2407-Q",qty:6,state:"Cách ly"}]},
 {id:"P-GLV",name:"Găng tay M",code:"SP-00602",qty:34,uom:"hộp",available:34,value:2550000,tracking:"NONE",lots:[]}
];
const cf15Movements = [
 {id:"M-RECEIPT",time:"07/09/2026 · 09:14",business:"07/09/2026",recorded:"07/09/2026 · 09:16",label:"Nhận hàng",source:"Phiếu nhận PN-260907-04",delta:20,before:98,after:118,uom:"hộp",lot:"N2408-02",state:"Bán được",actor:"Nguyễn An",value:1700000},
 {id:"M-SALE",time:"06/09/2026 · 15:40",business:"06/09/2026",recorded:"06/09/2026 · 15:42",label:"Bán hàng",source:"Đơn bán DH-260906-118",delta:-4,before:102,after:98,uom:"hộp",lot:"N2407-01",state:"Bán được",actor:"Trần Minh",value:-340000},
 {id:"M-STATUS",time:"05/09/2026 · 10:05",business:"05/09/2026",recorded:"05/09/2026 · 10:05",label:"Chuyển tình trạng",source:"Yêu cầu trạng thái TT-260905-03",delta:0,before:102,after:102,uom:"hộp",lot:"N2407-Q",state:"Cách ly",actor:"Lê Hoa",value:0}
];
function cf15ProductById(id){return cf15Products.find(x=>x.id===id)||cf15Products[0];}
function cf15Movement(){return cf15Movements.find(x=>x.id===cf15SelectedMovement)||cf15Movements[0];}
function cf15DateLabel(mode=cf15DateMode){return mode==="RECORDED"?"Ngày ghi nhận":"Ngày nghiệp vụ";}
function cf15Segmented(value,items,attr){return `<div class="cf-segmented" data-ds-component="VSegmentedControl">${items.map(([v,l])=>`<button type="button" class="cf-segment ${value===v?"is-selected":""}" ${attr}="${v}" data-ds-component="VSegmentedControlItem">${l}</button>`).join("")}</div>`;}
function render054CF15(state){
  if(activeFlowId!=="UIF-15")return renderGeneric(screens.find(s=>s.id==="SCR-054"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Tra cứu kho",body:deniedBody(),centered:true,back:false});
  if(state==="CONFLICT")return appShell({title:"Tra cứu kho",body:vBanner("warning","Phạm vi vừa thay đổi","Tải lại phạm vi tra cứu trước khi xem báo cáo."),back:false});
  const invalid=state==="VALIDATION_ERROR";
  const productOptions=[["ALL","Tất cả sản phẩm"],...cf15Products.map(x=>[x.id,`${x.name} · ${x.code}`])];
  const body=`${invalid?vBanner("error","Chưa đủ điều kiện tra cứu",cf15ReportType==="STOCK_CARD"?"Chọn một sản phẩm cụ thể để xem thẻ kho.":"Kiểm tra lại phạm vi và kỳ báo cáo."):""}${ioSectionTitle("Loại tra cứu")}${cf15Segmented(cf15ReportType,[["INVENTORY","Tồn kho"],["STOCK_CARD","Thẻ kho"]],"data-cf15-report-type")}${ioSectionTitle("Phạm vi")}<div class="form-stack">${cfSelect("Kho",cf15Warehouse,[["MAIN","Kho trung tâm"]],"data-cf15-warehouse","Nếu tổ chức chỉ có một kho hợp lệ, hệ thống giữ sẵn kho đó.")}${cfSelect("Sản phẩm",cf15Product,productOptions,"data-cf15-product",cf15ReportType==="STOCK_CARD"?"Bắt buộc khi xem thẻ kho.":"Có thể để tất cả khi xem báo cáo tồn.")}</div>${ioSectionTitle("Cách hiểu thời gian")}${cf15Segmented(cf15DateMode,[["BUSINESS","Ngày nghiệp vụ"],["RECORDED","Ngày ghi nhận"]],"data-cf15-date-mode")}<p class="io-footnote">Hai mốc thời gian có ý nghĩa khác nhau và không được trộn âm thầm trong cùng một kết quả.</p><div class="form-stack cf-date-grid">${cfField("Từ ngày",cf15From,'data-cf15-from','date')}${cfField("Đến ngày",cf15To,'data-cf15-to','date')}</div>`;
  return appShell({title:"Tra cứu kho",body,actions:primaryFooter("Xem báo cáo",'data-cf15-action="query"'),back:false});
}
function cf15ContextBanner(state,mode){
  const stale=state==="STALE"?vBanner("warning","Dữ liệu đang cập nhật","Dùng mốc dữ liệu bên dưới; không sửa tồn kho từ số liệu chưa cập nhật."):"";
  return `${stale}<div class="cf-context-row"><span>${cf15DateLabel(mode)} · ${cfDateVN(cf15From)} → ${cfDateVN(cf15To)}</span><strong>Đến 07/09/2026 · 11:00</strong></div>`;
}
function cf15ProductSheet(product,financeAllowed){
  if(!cf15ProductSheetOpen)return "";
  const stateRows=[...new Set(product.lots.map(x=>x.state))].map(st=>[st,`${cfNumber(product.lots.filter(x=>x.state===st).reduce((a,x)=>a+x.qty,0))} ${product.uom}`]);
  const lotBlock=product.tracking==="LOT"?`${ioSectionTitle("Theo lô")}<div class="cf-sheet-list">${product.lots.map(x=>ioMetaRow(`Lô ${x.lot}`,`${cfNumber(x.qty)} ${product.uom} · ${x.state}`,true)).join("")}</div>`:"";
  const stateBlock=stateRows.length?`${ioSectionTitle("Theo tình trạng")}<div class="cf-sheet-list">${stateRows.map(r=>ioMetaRow(r[0],r[1],true)).join("")}</div>`:"";
  return `<div class="sheet-backdrop" data-cf15-action="close-product-sheet"><section class="bottom-sheet cf15-sheet" role="dialog" aria-modal="true" aria-label="Chi tiết ${product.name}" onclick="event.stopPropagation()" data-ds-component="VBottomSheet" data-figma-node="4695:6353"><div class="sheet-handle"></div><div class="sheet-title"><h3>${product.name}</h3><small>${product.code}</small></div><div class="sheet-divider"></div><div class="sheet-content">${crFactCard("Số lượng",[["Tồn vật lý",`${cfNumber(product.qty)} ${product.uom}`,true],["Khả dụng bán",`${cfNumber(product.available)} ${product.uom}`,true],...(financeAllowed?[["Giá trị tồn",cfMoney(product.value)]]:[])])}${stateBlock}${lotBlock}${product.tracking!=="LOT"?'<p class="io-footnote">Sản phẩm không quản lý theo lô; báo cáo không tạo một “lô mặc định” giả.</p>':""}<div class="sheet-actions">${cfSecondary("Đóng",'data-cf15-action="close-product-sheet"')}<button class="button button--primary" type="button" data-cf15-action="product-stock-card" data-cf15-product-id="${product.id}" data-ds-component="VButton">Xem thẻ kho</button></div></div></section></div>`;
}
function cf15InventoryResult(state,mode){
  const financeAllowed=state!=="FINANCIAL_RESTRICTED";
  const rows=cf15Products.map(p=>ioProductRow({name:p.name,code:p.code,primary:`${cfNumber(p.qty)} ${p.uom}`,secondary:`Khả dụng ${cfNumber(p.available)} ${p.uom}`,attr:`data-cf15-product-row="${p.id}"`})).join("");
  const totalValue=cf15Products.reduce((a,x)=>a+x.value,0);
  return `${cf15ContextBanner(state,mode)}${cfSummaryGrid([["Sản phẩm",cf15Products.length],["Kho","Kho trung tâm"],...(financeAllowed?[["Tổng giá trị",cfMoney(totalValue)]]:[])])}${financeAllowed?"":vBanner("info","Giá trị tài chính đã được ẩn","Bạn vẫn có thể xem số lượng trong phạm vi được cấp quyền.")}${ioSectionTitle("Sản phẩm")}<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row"><div class="io-product-list">${rows}</div></div><p class="io-footnote">Không cộng các số lượng khác đơn vị thành một tổng giả.</p><div class="cf-inline-actions">${cfSecondary("Xuất báo cáo",'data-cf15-action="export"')}</div>${cf15ProductSheet(cf15ProductById(cf15SelectedProduct),financeAllowed)}`;
}
function cf15StockCardResult(state,mode){
  const financeAllowed=state!=="FINANCIAL_RESTRICTED"; const p=cf15ProductById(cf15Product==="ALL"?cf15SelectedProduct:cf15Product);
  const movRows=cf15Movements.map(m=>`<button class="cf-movement-row" type="button" data-cf15-movement="${m.id}" data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="Navigation" data-ds-prop-density="Default" data-ds-prop-state="Default"><span><strong>${m.label}</strong><small>${mode==="RECORDED"?m.recorded:m.business} · ${m.source}</small></span><span class="cf-movement-values"><strong>${m.delta>0?"+":""}${m.delta} ${m.uom}</strong><small>Còn ${m.after} ${m.uom}</small></span>${navChevron()}</button>`).join("");
  return `${cf15ContextBanner(state,mode)}${crFactCard(p.name,[["Mã",p.code,true],["Tồn hiện tại",`${cfNumber(p.qty)} ${p.uom}`],["Khả dụng bán",`${cfNumber(p.available)} ${p.uom}`],...(financeAllowed?[["Giá trị tồn",cfMoney(p.value)]]:[])])}${financeAllowed?"":vBanner("info","Giá trị tài chính đã được ẩn","Thẻ kho vẫn hiển thị số lượng và nguồn nghiệp vụ trong phạm vi quyền.")}${ioSectionTitle("Biến động")}<div class="cf-movement-list">${movRows}</div><div class="cf-inline-actions">${cfSecondary("Xuất thẻ kho",'data-cf15-action="export"')}</div>`;
}
function render055CF15(state){
  if(activeFlowId!=="UIF-15")return renderGeneric(screens.find(s=>s.id==="SCR-055"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả tra cứu",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Kết quả tra cứu",body:loadingBody()});
  if(state==="EMPTY"||state==="FILTER_EMPTY")return appShell({title:"Kết quả tra cứu",body:ioEmpty(state==="FILTER_EMPTY"?"Không có dữ liệu phù hợp":"Chưa có dữ liệu tồn kho","Đổi phạm vi hoặc kỳ báo cáo để kiểm tra lại.")});
  const mode=state==="RECORDED_DATE_VIEW"?"RECORDED":state==="BUSINESS_DATE_VIEW"?"BUSINESS":cf15DateMode;
  const body=cf15ReportType==="STOCK_CARD"?cf15StockCardResult(state,mode):cf15InventoryResult(state,mode);
  return appShell({title:cf15ReportType==="STOCK_CARD"?"Thẻ kho":"Báo cáo tồn kho",subtitle:`Kho trung tâm · ${cf15DateLabel(mode)}`,body});
}
function render056CF15(state){
  if(activeFlowId!=="UIF-15")return render056IC09(state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Chi tiết biến động",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Chi tiết biến động",body:loadingBody()});
  if(state==="CONFLICT")return appShell({title:"Chi tiết biến động",body:vBanner("warning","Nguồn nghiệp vụ vừa thay đổi","Tải lại dữ liệu trước khi dựa vào chi tiết đang xem.")});
  const m=cf15Movement(); const financeAllowed=state!=="FINANCIAL_RESTRICTED";
  const body=`${crFactCard(m.label,[["Nguồn",m.source,true],["Ngày nghiệp vụ",m.business],["Ngày ghi nhận",m.recorded],["Người thực hiện",m.actor]])}${crFactCard("Số lượng",[["Trước",`${m.before} ${m.uom}`],["Biến động",`${m.delta>0?"+":""}${m.delta} ${m.uom}`,true],["Sau",`${m.after} ${m.uom}`],["Lô",m.lot],["Tình trạng",m.state]])}${financeAllowed?crFactCard("Giá trị",[["Tác động",cfMoney(m.value),true],["Nguồn giá","Giá trị chính thức của giao dịch"]]):vBanner("info","Giá trị tài chính đã được ẩn","Bạn có thể truy vết nguồn và số lượng nhưng không xem giá trị.")}${cfSecondary("Xem nguồn",'data-cf15-action="source"')}`;
  return appShell({title:"Chi tiết biến động",body});
}
function render057CF15(state){
  if(activeFlowId!=="UIF-15")return renderGeneric(screens.find(s=>s.id==="SCR-057"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Nguồn nghiệp vụ",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Nguồn nghiệp vụ",body:loadingBody()});
  if(state==="EMPTY")return appShell({title:"Nguồn nghiệp vụ",body:ioEmpty("Chưa có bằng chứng nguồn","Không có chuỗi nguồn phù hợp với biến động đang xem.")});
  const m=cf15Movement(); const stale=state==="STALE"?vBanner("warning","Dữ liệu nguồn đang cập nhật","Giữ mốc hiển thị hiện tại; không dùng dữ liệu chưa cập nhật làm căn cứ để thay đổi tồn kho."):"";
  const body=`${stale}${crFactCard("Biến động đang xem",[["Nguồn",m.source,true],["Sản phẩm",cf15ProductById(cf15Product==="ALL"?cf15SelectedProduct:cf15Product).name],["Số lượng",`${m.delta>0?"+":""}${m.delta} ${m.uom}`]])}${ioSectionTitle("Dòng thời gian nghiệp vụ")}<div class="timeline cf-business-timeline"><div class="timeline-card"><strong>${m.source}</strong><small>Giao dịch nguồn được hoàn tất</small></div><div class="timeline-card"><strong>Đã ghi nhận kho</strong><small>${m.recorded}</small></div><div class="timeline-card"><strong>${m.delta>=0?"Tồn tăng":"Tồn giảm"} ${Math.abs(m.delta)} ${m.uom}</strong><small>Số dư sau biến động: ${m.after} ${m.uom}</small></div></div><div class="cf-inline-actions">${cfSecondary("Xuất bằng chứng",'data-cf15-action="export-source"')}</div>`;
  return appShell({title:"Nguồn nghiệp vụ",body});
}
function render058CF15(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Xuất báo cáo",body:deniedBody(),centered:true,back:false});
  if(state==="EXPORT_RUNNING")return appShell({title:"Xuất báo cáo",body:loadingBody(),centered:true,back:false});
  if(state==="VALIDATION_ERROR")return appShell({title:"Xuất báo cáo",body:vBanner("error","Chưa thể xuất","Phạm vi hoặc mốc dữ liệu không còn hợp lệ. Quay lại kết quả tra cứu để kiểm tra."),backAction:"cf15-back-export"});
  if(state==="STALE")return appShell({title:"Xuất báo cáo",body:`${vBanner("warning","Kết quả đang cập nhật","Không xuất một file được hiểu nhầm là số liệu mới hơn mốc đang hiển thị.")}${crFactCard("Mốc dữ liệu",[["Đến","07/09/2026 · 11:00",true],["Cách hiểu thời gian",cf15DateLabel()]])}`,backAction:"cf15-back-export"});
  const sourceLabel=cf15ExportFrom==="SOURCE"?"Bằng chứng biến động":cf15ReportType==="STOCK_CARD"?"Thẻ kho":"Báo cáo tồn kho";
  const body=`${crFactCard("Phạm vi xuất",[["Nội dung",sourceLabel,true],["Kho","Kho trung tâm"],["Kỳ",`${cfDateVN(cf15From)} → ${cfDateVN(cf15To)}`],["Cách hiểu thời gian",cf15DateLabel()],["Dữ liệu đến","07/09/2026 · 11:00"],["Giá trị tài chính",cf15FinanceIncluded?"Có":"Không"]])}${crFactCard("Định dạng",[["Tệp","CSV",true],["Quyền dữ liệu","Giữ đúng như màn đang xem"]])}<p class="io-footnote">Tệp xuất giữ cùng phạm vi, quyền và mốc dữ liệu với kết quả đang xem.</p>`;
  return appShell({title:"Xuất báo cáo",body,actions:primaryFooter("Xuất báo cáo",'data-cf15-action="confirm-export"'),backAction:"cf15-back-export"});
}
function render059CF15(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả xuất báo cáo",body:deniedBody(),centered:true,back:false});
  if(state==="PROCESSING")return appShell({title:"Kết quả xuất báo cáo",body:loadingBody(),centered:true,back:false});
  if(state==="SOURCE_STALE")return appShell({title:"Kết quả xuất báo cáo",body:ioResult("Nguồn dữ liệu đã thay đổi","Không tạo tệp từ kết quả chưa cập nhật. Quay lại báo cáo và tải mốc hiện hành trước khi xuất lại.",[["Tệp","Chưa tạo"],["Dữ liệu","Không bị thay đổi"]],"warning"),actions:primaryFooter("Quay lại báo cáo",'data-cf15-action="done-export"'),centered:true,back:false});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả xuất báo cáo",body:ioResult("Chưa tạo được tệp","Chưa tạo được tệp nhưng dữ liệu tồn kho không thay đổi.",[["Dữ liệu kho","Không thay đổi"],["Có thể thử lại","Từ cùng báo cáo hiện hành"]],"warning"),actions:primaryFooter("Quay lại báo cáo",'data-cf15-action="done-export"'),centered:true,back:false});
  const filename=cf15ExportFrom==="SOURCE"?"bang-chung-bien-dong-07092026.csv":cf15ReportType==="STOCK_CARD"?"the-kho-07092026.csv":"bao-cao-ton-kho-07092026.csv";
  const body=ioResult("Đã tạo tệp báo cáo","Tệp giữ đúng phạm vi, quyền và mốc dữ liệu của kết quả đã xem.",[["Tệp",filename],["Dữ liệu đến","07/09/2026 · 11:00"],["Giá trị tài chính",cf15FinanceIncluded?"Có":"Không"]]);
  return appShell({title:"Kết quả xuất báo cáo",body,actions:primaryFooter("Xong",'data-cf15-action="done-export"'),centered:true,back:false});
}

const renderers = {"SCR-048":render048CR11,"SCR-049":render049CR11,"SCR-050":render050CR11,"SCR-051":render051CR11,"SCR-052":render052CR11,"SCR-053":render053CR11,"SCR-078":render078CR,"SCR-079":render079CR,"SCR-080":render080CR,"SCR-081":render081CR,"SCR-082":render082CR,"SCR-083":render083CR,"SCR-001":render001BJ01,"SCR-003":render003BJ01,"SCR-004":render004BJ01,"SCR-014":render014IV03,"SCR-015":render015IV03,"SCR-016":render016IV03,"SCR-017":render017IV03,"SCR-019":render019IV03,"SCR-006":render006,"SCR-007":render007,"SCR-008":render008,"SCR-009":render009,"SCR-084":render084,"SCR-010":render010,"SCR-011":render011,"SCR-012":render012,"SCR-013":render013,"SCR-021":render021IO04,"SCR-025":render025IO05,"SCR-026":render026IO05,"SCR-027":render027IO05,"SCR-028":render028IO05,"SCR-029":render029IO05,"SCR-030":render030IO06,"SCR-031":render031IO06,"SCR-032":render032IO06,"SCR-033":render033IO06,"SCR-034":render034IO06,"SCR-035":render035IO06,"SCR-036":render036IO07,"SCR-037":render037IO07,"SCR-039":render039IO07,"SCR-041":render041IO07,"SCR-038":render038IC09,"SCR-040":render040IC10,"SCR-042":render042IC08,"SCR-043":render043IC08,"SCR-044":render044IC08,"SCR-045":render045IC08,"SCR-046":render046IC08,"SCR-047":render047IC08,"SCR-054":render054CF15,"SCR-055":render055CF15,"SCR-056":render056CF15,"SCR-057":render057CF15,"SCR-058":render058CF15,"SCR-059":render059CF15,"SCR-066":render066CF12,"SCR-067":render067CF12,"SCR-068":render068CF12,"SCR-069":render069CF12,"SCR-070":render070CF12,"SCR-071":render071CF12,"SCR-085":render085IV13,"SCR-086":render086IV13,"SCR-087":render087IV13,"SCR-088":render088IV13,"SCR-089":render089IV13,"SCR-072":render072IV14,"SCR-073":render073IV14,"SCR-074":render074IV14,"SCR-075":render075IV14,"SCR-076":render076IV14,"SCR-077":render077IV14};
for (const screen of screens) if (!renderers[screen.id]) renderers[screen.id]=(state)=>renderGeneric(screen,state);

function collectReceiptDraft() {
  const entries = [...document.querySelectorAll("[data-lot-entry]")];
  if (!entries.length) return;
  receiptDraft = {
    lots: entries.map((entry) => ({
      id: Number(entry.dataset.lotId),
      code: entry.querySelector("[data-lot-code]")?.value.trim() || "",
      expiry: entry.querySelector("[data-lot-expiry]")?.value.trim() || "",
      accepted: Math.max(0, Number(entry.querySelector('[data-qty="accepted"]')?.value) || 0),
      quarantine: Math.max(0, Number(entry.querySelector('[data-qty="quarantine"]')?.value) || 0),
      damaged: Math.max(0, Number(entry.querySelector('[data-qty="damaged"]')?.value) || 0),
      rejected: Math.max(0, Number(entry.querySelector('[data-qty="rejected"]')?.value) || 0),
    })),
  };
}

function receiptTotals() {
  return receiptDraft.lots.reduce(
    (totals, lot) => {
      totals.accepted += lot.accepted;
      totals.quarantine += lot.quarantine;
      totals.damaged += lot.damaged;
      totals.rejected += lot.rejected;
      return totals;
    },
    { accepted: 0, quarantine: 0, damaged: 0, rejected: 0 },
  );
}

function receiptSummary() {
  return bj02Lines.reduce((totals, line) => {
    const t = lineTotals(line);
    totals.accepted += t.accepted;
    totals.quarantine += t.quarantine;
    totals.damaged += t.damaged;
    totals.rejected += t.rejected;
    totals.physicalIncrease += t.physicalIncrease;
    totals.totalDelivered += t.totalReceived;
    return totals;
  }, { accepted: 0, quarantine: 0, damaged: 0, rejected: 0, nonSellable: 0, physicalIncrease: 0, totalDelivered: 0 });
}

function quantityTotal(name) {
  return [...document.querySelectorAll(`[data-qty="${name}"]`)].reduce((total, input) => {
    const value = Math.max(0, Number(input.value) || 0);
    return total + value;
  }, 0);
}

function updateReceiptBalance() {
  if (!["SCR-008", "SCR-009"].includes(activeScreenId)) return;
  const balance = document.getElementById("receipt-balance");
  if (!balance) return;

  const product = activeReceivingProduct();
  if (!product) return;
  const expected = activeScreenId === "SCR-009" ? 120 : null;
  const accepted = quantityTotal("accepted");
  const quarantine = quantityTotal("quarantine");
  const damaged = quantityTotal("damaged");
  const rejected = quantityTotal("rejected");
  const physicalIncrease = accepted + quarantine + damaged;
  const totalDelivered = physicalIncrease + rejected;

  balance.querySelector("[data-total-delivered]").textContent = `${totalDelivered}`;
  balance.querySelector("[data-physical-increase]").textContent = `${physicalIncrease}`;
  balance.querySelector("[data-rejected-total]").textContent = `${rejected}`;

  const status = balance.querySelector("[data-balance-feedback]");
  if (status) {
    if (totalDelivered <= 0) status.innerHTML = `<p class="balance-status-text">Nhập số lượng kiểm nhận để tiếp tục.</p>`;
    else if (expected != null && accepted > expected) status.innerHTML = vBanner("warning", "Lượng đạt vượt chứng từ", `Lượng đạt ${accepted} ${product.uom}, vượt ${accepted - expected} ${product.uom} so với lượng còn được phép nhận. Hồ sơ sẽ được định tuyến phê duyệt.`);
    else if (expected != null && totalDelivered < expected) status.innerHTML = `<p class="balance-status-text">Nhận từng phần · đã phân loại ${totalDelivered} / ${expected} ${product.uom}.</p>`;
    else status.innerHTML = `<p class="balance-status-text balance-status-text--success">Đã phân loại ${totalDelivered} ${product.uom} thực nhận.</p>`;
  }

  let requiredLotValuesPresent = true;
  document.querySelectorAll("[data-lot-entry]").forEach((entry) => {
    const entryTotal = ["accepted", "quarantine", "damaged", "rejected"].reduce((sum, name) => sum + Math.max(0, Number(entry.querySelector(`[data-qty="${name}"]`)?.value) || 0), 0);
    const identity = entry.querySelector("[data-lot-identity]");
    if (identity) {
      identity.hidden = entryTotal <= 0;
      identity.classList.toggle("is-visible", entryTotal > 0);
    }
    if (entryTotal > 0 && product.trackingPolicy === "LOT") {
      const code = entry.querySelector("[data-lot-code]")?.value.trim() || "";
      const expiry = entry.querySelector("[data-lot-expiry]")?.value.trim() || "";
      if (!code || (product.expiryRequired && !expiry)) requiredLotValuesPresent = false;
    }
  });

  const addLot = document.querySelector('[data-action="add-lot"]');
  const currentState = stateByScreen[activeScreenId];
  if (addLot && !["LOCKED", "READ_ONLY"].includes(currentState)) addLot.disabled = totalDelivered <= 0;

  const reviewButton = document.querySelector('[data-next="SCR-010"]');
  const blockerStates = ["LOCKED", "READ_ONLY", "LOT_CONFLICT", "VALIDATION_FAILED", "APPROVER_CONFIGURATION_MISSING"];
  if (reviewButton && !blockerStates.includes(currentState)) reviewButton.disabled = totalDelivered <= 0 || !requiredLotValuesPresent;
  collectReceiptDraft();
}

function addLotEntry() {
  const list = document.getElementById("lot-entry-list");
  const product = activeReceivingProduct();
  if (!list || !product || product.trackingPolicy !== "LOT") return;
  collectReceiptDraft();
  lotSequence += 1;
  const newLot = { id: lotSequence, code: "", expiry: "", accepted: 0, quarantine: 0, damaged: 0, rejected: 0 };
  receiptDraft.lots.push(newLot);
  list.insertAdjacentHTML("beforeend", lotEntry(list.children.length + 1, newLot, { product }));
  updateReceiptBalance();
  list.lastElementChild?.scrollIntoView({ behavior: "smooth", block: "nearest" });
}

function removeLotEntry(button) {
  const entry = button.closest("[data-lot-entry]");
  if (!entry) return;
  entry.remove();
  updateReceiptBalance();
}

function hasReceiptLineInput() {
  const totals = receiptSummary();
  if (totals.totalDelivered > 0) return true;
  return receiptDraft.lots.some((lot) => Boolean(lot.code || lot.expiry));
}

function selectQuickProduct(productId) {
  const product = quickProductById(productId);
  if (!product) return;
  selectedQuickProductId = product.id;
  quickProductMenuOpen = false;
  receiptDraft = { lots: [{ id: 1, code: "", expiry: "", accepted: 0, quarantine: 0, damaged: 0, rejected: 0 }] };
  lotSequence = 1;
  renderAppScreen();
  document.querySelector('[data-qty="accepted"]')?.focus();
}

function resetQuickProduct() {
  selectedQuickProductId = null;
  quickProductMenuOpen = true;
  receiptDraft = { lots: [] };
  renderAppScreen();
  window.setTimeout(() => document.querySelector('[data-product-search]')?.focus(), 0);
}

function openChangeProductDialog() {
  const screen = document.getElementById("app-screen");
  if (screen.querySelector(".confirm-backdrop")) return;
  screen.insertAdjacentHTML("beforeend", `
    <div class="confirm-backdrop" data-action="close-product-change" data-ds-launcher="DS v2 / Confirmation Sheet">
      <section class="confirm-dialog" data-ds-component="DS v2 / Confirmation Sheet" data-figma-node="550:1058" data-ds-prop-content="Plain" data-ds-prop-title="Đổi sản phẩm?" data-ds-prop-cancel-label="Giữ sản phẩm" data-ds-prop-action-label="Đổi sản phẩm" data-ds-prop-is-destructive="true" role="dialog" aria-modal="true" aria-labelledby="change-product-title" onclick="event.stopPropagation()">
        <h3 id="change-product-title">Đổi sản phẩm?</h3>
        <p>Số lượng và thông tin lô đã nhập cho sản phẩm hiện tại sẽ bị xóa.</p>
        <div class="confirm-dialog-actions"><button class="button button--secondary" data-action="close-product-change" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.tertiary" type="button">Giữ sản phẩm</button><button class="button button--primary" data-action="confirm-product-change" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.primary" data-ds-prop-tone="VComponentTone.danger" type="button">Đổi sản phẩm</button></div>
      </section>
    </div>`);
}

function closeChangeProductDialog() { document.querySelector(".confirm-backdrop")?.remove(); }

function filterQuickProductOptions(query) {
  const menu = document.querySelector("[data-vcombobox-menu]");
  if (!menu) return;
  const normalized = query.trim().toLowerCase();
  let visible = 0;
  menu.querySelectorAll("[data-product-option]").forEach((option) => {
    const match = !normalized || option.dataset.productSearchText.includes(normalized);
    option.hidden = !match;
    if (match) visible += 1;
  });
  const empty = menu.querySelector("[data-product-empty]");
  if (empty) empty.hidden = visible > 0;
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
  if (!lineEditorValid()) return showToastBj02("Kiểm tra thông tin còn thiếu trước khi hoàn tất.", "warning");
  persistLineEditorDraft(true); lineEditorDirty = false; navigate("SCR-009");
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
  const supplier = supplierCatalog.find((item) => item.id === supplierId); if (!supplier) return;
  bj02Header.supplierId = supplier.id; bj02Header.supplier = supplier.name; supplierMenuOpen = false; supplierSearchQuery = ""; supplierValidationVisible = false; renderAppScreen();
}
function renderAppScreen() {
  const state = stateByScreen[activeScreenId];
  const effectiveRenderer = renderers[activeScreenId] || ((st) => appShell({title: screens.find(x=>x.id===activeScreenId)?.name || "Theme 7", body: ioEmpty("Đang hoàn thiện prototype","Màn hình này sẽ được tải khi lớp completion được khởi tạo."), back:false}));
  document.getElementById("app-screen").innerHTML = effectiveRenderer(state);
  updateReceiptBalance();
}

function render() {
  renderFlowSelector();
  renderNavigation();
  renderInspector();
  renderAppScreen();
  if (inspectEnabled) resetInspectSelection();
  requestAnimationFrame(fitReviewDeviceToViewport);
}

function syncReviewUrl() {
  const url = new URL(window.location.href);
  url.searchParams.set("uif", activeFlowId);
  url.searchParams.set("screen", activeScreenId);
  url.searchParams.set("state", stateByScreen[activeScreenId]);
  url.searchParams.set("flow", flowMode);
  url.searchParams.set("viewport", viewport);
  history.replaceState(null, "", url);
}

function navigate(screenId) {
  if (!renderers[screenId]) return;
  activeScreenId = screenId;
  syncReviewUrl();
  render();
}

function previousScreen() {
  if (activeFlowId === "UIF-06") {
    if (activeScreenId === "SCR-031") return navigate("SCR-030");
    if (activeScreenId === "SCR-032") return navigate("SCR-031");
    if (activeScreenId === "SCR-033") { io06ClassificationOpen=false; io06ClassificationDraft=null; return navigate("SCR-030"); }
    return;
  }
  if (activeFlowId === "UIF-02") {
    if (activeScreenId === "SCR-007" || activeScreenId === "SCR-008") return navigate("SCR-006");
    if (activeScreenId === "SCR-009") return navigate(flowMode === "quick" ? "SCR-008" : "SCR-007");
    if (activeScreenId === "SCR-084") { if (!lineEditorIsReadOnly()) persistLineEditorDraft(false); lineEditorReadOnly = false; lineEditorDirty = false; return navigate("SCR-009"); }
    if (activeScreenId === "SCR-010") return navigate("SCR-009");
    if (activeScreenId === "SCR-013") return navigate("SCR-012");
    return;
  }
  const list = activeFlow()?.screens || [];
  const idx = list.indexOf(activeScreenId);
  if (idx > 0) return navigate(list[idx - 1]);
}

function normalizeToastType(type = "success") {
  const raw=String(type||"success");
  const aliases={xCircle:"danger",error:"danger",danger:"danger",alert:"warning",warning:"warning",info:"info",rotate:"info",arrowLeft:"info",arrowRight:"info",shield:"info",layers:"info",checkCircle:"success",success:"success"};
  return aliases[raw]||"success";
}
function showToastCanonical(message, type = "success") {
  const screen=document.getElementById("app-screen");
  const oldToast=screen.querySelector(".toast");
  if(oldToast)oldToast.remove();
  const toastType=normalizeToastType(type);
  const iconName=toastType==="danger"?"xCircle":toastType==="warning"?"alert":toastType==="info"?"info":"checkCircle";
  const semanticIcon=toastType==="danger"?"VIcons.error":toastType==="warning"?"VIcons.warning":toastType==="info"?"VIcons.info":"VIcons.success";
  const toast=document.createElement("div");
  toast.className="toast";
  toast.dataset.dsComponent="VToast";
  toast.dataset.figmaNode="526:4305";
  toast.dataset.dsPropType=`VToastType.${toastType}`;
  toast.dataset.dsPropMessage=message;
  toast.innerHTML=`<span class="toast-icon-box" data-ds-component="VIconBox" data-ds-prop-is-circular="true" data-ds-prop-size="24" data-ds-prop-icon-size="14" data-ds-prop-icon="${semanticIcon}">${icon(iconName,"icon--sm")}</span><span class="toast-message" data-ds-internal="VToast.message">${esc(message)}</span><button class="toast-close" data-action="close-toast" type="button" aria-label="Đóng thông báo" data-ds-internal="VToast.close" data-ds-icon="VIcons.close">${icon("close","icon--sm")}</button>`;
  screen.appendChild(toast);
  window.clearTimeout(toastTimer);
  toastTimer=window.setTimeout(()=>toast.remove(),2600);
  return toast;
}
function showToast(message,type="success"){return showToastCanonical(message,type);}
function showToastBj02(message,type="success"){return showToastCanonical(message,type);}
function showToastLegacy(message,type="success"){return showToastCanonical(message,type);}

// Review-only Inspect state. Kept outside product UI.
let inspectEnabled = false;
let inspectPinned = false;
let inspectTarget = null;

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function inspectableFrom(target) {
  if (!(target instanceof Element)) return null;
  const hit = target.closest('[data-ds-component], [data-theme-component], [data-ds-internal]');
  return hit && hit.closest('#app-screen') ? hit : null;
}

function numberPx(style, property) {
  const value = Number.parseFloat(style.getPropertyValue(property));
  return Number.isFinite(value) ? value : 0;
}

function boxRect(rect, top, right, bottom, left, mode = "expand") {
  if (mode === "expand") {
    return { left: rect.left - left, top: rect.top - top, width: rect.width + left + right, height: rect.height + top + bottom };
  }
  return { left: rect.left + left, top: rect.top + top, width: Math.max(0, rect.width - left - right), height: Math.max(0, rect.height - top - bottom) };
}

function setInspectBox(node, box) {
  Object.assign(node.style, {
    left: `${box.left}px`, top: `${box.top}px`, width: `${box.width}px`, height: `${box.height}px`,
  });
}

function figmaAssetTarget(name, layer = "COMPONENT", status = "EXACT", note = "") {
  const asset = FIGMA_DS_MAP.assetIndex?.[name] || {};
  return { name, nodeId: asset.nodeId || null, assetType: asset.assetType || null, section: asset.section || null, layer, status, note };
}

function resolveFigmaMapping(element) {
  const ds = element.dataset.dsComponent || "";
  const theme = element.dataset.themeComponent || "";
  const internal = element.dataset.dsInternal || "";
  const profile = element.dataset.dsProfile || "";
  let source = "";
  let mapping = null;
  if (theme && FIGMA_DS_MAP.themeComponentMappings?.[theme]) { source = `theme:${theme}`; mapping = FIGMA_DS_MAP.themeComponentMappings[theme]; }
  else if (internal && FIGMA_DS_MAP.internalMappings?.[internal]) { source = `internal:${internal}`; mapping = FIGMA_DS_MAP.internalMappings[internal]; }
  else if (ds) {
    const base = FIGMA_DS_MAP.componentMappings?.[ds] || null;
    const contextual = profile ? (FIGMA_DS_MAP.profileMappings?.[`${ds}|${profile}`] || null) : null;
    if (base && contextual && ["PATTERN","TEMPLATE","FOUNDATION"].includes(contextual.layer) && ["EXACT","LEGACY_ALIAS","EXACT_FOUNDATION"].includes(base.status)) {
      source = `component:${ds}`; mapping = { ...base, contextMapping: contextual };
    } else if (contextual) { source = `profile:${ds}|${profile}`; mapping = contextual; }
    else if (base) { source = `component:${ds}`; mapping = base; }
    else if (FIGMA_DS_MAP.assetIndex?.[ds]) {
      const asset=FIGMA_DS_MAP.assetIndex[ds];
      const section=String(asset.section||"");
      const layer=section.includes("Patterns")||section.includes("Form Patterns")?"PATTERN":section.includes("Page Templates")?"TEMPLATE":"COMPONENT";
      source=`asset:${ds}`; mapping=figmaAssetTarget(ds,layer,"EXACT","Direct live Figma DS asset used by Phase 4 rollout.");
    }
  }

  // Dynamic legacy aliases that depend on actual rendered anatomy.
  if (ds === "VButton" && String(element.dataset.dsPropVariant || "").toLowerCase().includes("link")) {
    source = "dynamic:VButton.link"; mapping = figmaAssetTarget("DS v2 / Link", "COMPONENT", "LEGACY_ALIAS", "Legacy link-style button resolves to canonical Link component.");
  }
  if (ds === "VTextFormField" && element.querySelector("textarea")) {
    source = "dynamic:VTextFormField.multiline"; mapping = FIGMA_DS_MAP.componentMappings?.VTextarea || mapping;
  }
  if (ds === "VPageScaffold") {
    const explicitTemplate = element.dataset.figmaTemplate || "";
    if (explicitTemplate) {
      source = `phase5:template:${activeFlowId}:${activeScreenId}`;
      mapping = figmaAssetTarget(explicitTemplate, "TEMPLATE", "EXACT", "Phase 5 Theme 7 screen uses the explicit task-appropriate Figma page template.");
      return { ...mapping, source, legacy: { ds, theme, internal, profile } };
    }
    const surface = currentScreen()?.surface || "";
    let name = null;
    if (["result", "status / entry", "validation result"].includes(surface)) name = "Mobile / Detail";
    else if (surface === "form" || surface === "choice" || surface === "approval review") name = "Mobile / Form";
    else if (surface === "list") name = element.dataset.dsPropShowBackButton === "false" ? "Mobile / Root List" : "Mobile / Nested List";
    else if (["detail", "review", "timeline", "dashboard"].includes(surface)) name = "Mobile / Detail";
    if (name) { source = `dynamic:template:${surface}`; mapping = figmaAssetTarget(name, "TEMPLATE", "MIGRATION_TARGET", "Fallback template candidate derived from current task/surface; explicit Phase 5 mappings are authoritative."); }
  }
  if (!mapping) mapping = { name: ds || theme || internal || element.tagName.toLowerCase(), nodeId: null, assetType: null, section: null, layer: "UNMAPPED", status: "UNMAPPED", note: "No Phase 2 mapping rule." };
  return { ...mapping, source, legacy: { ds, theme, internal, profile } };
}

function figmaTextStyleFor(element) {
  const v = String(element.dataset.dsPropVariant || "");
  if (v.includes("headingH1")) return "VET45 v2 / Heading / H1";
  if (v.includes("headingH2")) return "VET45 v2 / Heading / H2";
  if (v.includes("headingH3")) return "VET45 v2 / Heading / H3";
  if (v.includes("headingH4")) return "VET45 v2 / Heading / H4";
  if (v.includes("bodySmall")) return "VET45 v2/Body/Small";
  if (v.includes("bodyDefault") || v.includes("bodyMedium")) return "VET45 v2 / Body / Default";
  if (element.matches("h1")) return "VET45 v2 / Heading / H1";
  if (element.matches("h2")) return "VET45 v2 / Heading / H3";
  if (element.matches("h3")) return "VET45 v2 / Heading / H4";
  if (element.matches("small")) return "VET45 v2/Body/Small";
  if (element.matches("strong")) return "VET45 v2 / Label / Default";
  return "VET45 v2 / Body / Default";
}

function canonicalFigmaProps(element, mapping) {
  const ds = element.dataset.dsComponent || "";
  const out = [];
  if (ds === "VButton") {
    const variant = String(element.dataset.dsPropVariant || "").toLowerCase();
    const tone = String(element.dataset.dsPropTone || "").toLowerCase();
    if (mapping.name === "DS v2 / Link") {
      out.push(["Tone", tone.includes("danger") ? "Danger" : "Default"]);
      out.push(["State", element.disabled ? "Disabled" : "Default"]);
    } else {
      let hierarchy = tone.includes("danger") ? "Danger" : variant.includes("secondary") ? "Secondary" : variant.includes("tertiary") ? "Tertiary" : "Primary";
      const size = String(element.dataset.dsPropSize || "").toLowerCase();
      out.push(["Hierarchy", hierarchy]);
      out.push(["State", element.disabled ? "Disabled" : element.classList.contains("is-loading") ? "Loading" : "Default"]);
      out.push(["Size", size.includes("small") ? "Small" : size.includes("large") ? "Large" : "Default"]);
    }
  } else if (ds === "VBadge") {
    const status = String(element.dataset.dsPropStatus || element.className || "").toLowerCase();
    const tone = status.includes("success") ? "Success" : status.includes("warning") ? "Warning" : status.includes("danger") || status.includes("error") ? "Danger" : status.includes("info") ? "Info" : "Neutral";
    out.push(["Tone", tone], ["Style", "Soft"]);
  } else if (ds === "VBanner") {
    const status = String(element.dataset.dsPropStatus || element.className || "").toLowerCase();
    const tone = status.includes("success") ? "Success" : status.includes("warning") ? "Warning" : status.includes("danger") || status.includes("error") ? "Danger" : "Info";
    out.push(["Tone", tone], ["Density", "Default"]);
  } else if (ds === "VChip") {
    const selected = element.dataset.dsPropSelected === "true" || element.classList.contains("is-active");
    out.push(["Tone", selected ? "Brand" : "Neutral"], ["State", element.disabled ? "Disabled" : "Default"]);
  } else if (ds === "VAppBar") {
    const back = element.querySelector('[data-ds-internal="VAppBar.leading"]') !== null;
    const subtitle = element.querySelector('[data-ds-component="VAppBarSubtitle"]') !== null;
    out.push(["Type", back && subtitle ? "Context" : back ? "Back" : subtitle ? "Root context" : "Root"]);
  } else if (ds === "VEmptyState") {
    const text = element.textContent || "";
    let type = element.dataset.themeComponent === "PermissionDeniedState" ? "No Permission" : /không có kết quả/i.test(text) ? "No Result" : /bị chặn|không thể tiếp tục/i.test(text) ? "Blocked" : /lỗi|không tải/i.test(text) ? "Error" : "Empty";
    out.push(["Type", type]);
  } else if (ds === "VSearchBar") {
    const input = element.querySelector("input");
    out.push(["State", element.matches(":focus-within") ? "Focused" : input?.disabled ? "Disabled" : input?.value ? "Filled" : "Default"]);
  } else if (["VTextField","VTextFormField","VNumberField","VDatePicker","VDatePickerField","VSelect"].includes(ds)) {
    const input = element.querySelector("input,textarea,select") || (element.matches("input,textarea,select") ? element : null);
    out.push(["State", element.matches(":focus-within") ? "Focused" : input?.disabled ? "Disabled" : input?.value ? "Filled" : "Default"]);
  } else if (ds === "VRadio") {
    const input = element.querySelector('input[type="radio"]');
    out.push(["State", input?.disabled ? (input.checked ? "Disabled On" : "Disabled Off") : input?.checked || element.classList.contains("is-selected") ? "On" : "Off"]);
  } else if (ds === "VSegmentedControl") {
    const items = [...element.querySelectorAll("button")];
    const selected = items.findIndex((x)=>x.classList.contains("is-selected") || x.getAttribute("aria-pressed") === "true");
    if (selected >= 0) out.push(["Selected", String(selected + 1)]);
  } else if (ds === "VText") {
    out.push(["Text style", figmaTextStyleFor(element)]);
  } else if (ds === "VIcon") {
    out.push(["Registry", "VET45 approved Icon Library"]);
    if (element.dataset.dsPropIcon) out.push(["Icon", element.dataset.dsPropIcon.replace(/^VIcons\./, "")]);
  }
  return out;
}

function inspectLabel(element) {
  const mapping = resolveFigmaMapping(element);
  return mapping.name || element.dataset.dsComponent || element.dataset.themeComponent || element.dataset.dsInternal || element.tagName.toLowerCase();
}

function collectInspectProps(element) {
  const props = [];
  for (const attr of element.attributes) {
    if (attr.name.startsWith('data-ds-prop-')) props.push([attr.name.slice('data-ds-prop-'.length), attr.value]);
  }
  if (element.dataset.dsProfile) props.unshift(['profile', element.dataset.dsProfile]);
  if (element.dataset.dsSlot) props.push(['slot', element.dataset.dsSlot]);
  if (element.dataset.dsDefaultIcon) props.push(['defaultIcon', element.dataset.dsDefaultIcon]);
  if (element.dataset.dsIcon) props.push(['icon', element.dataset.dsIcon]);
  if (element.dataset.composedFrom) props.push(['composedFrom', element.dataset.composedFrom]);
  if (element.dataset.dsGap) props.push(['DS gap', element.dataset.dsGap]);
  return props;
}

function inspectBoxValues(element) {
  const style = getComputedStyle(element);
  const rect = element.getBoundingClientRect();
  const margin = [numberPx(style,'margin-top'), numberPx(style,'margin-right'), numberPx(style,'margin-bottom'), numberPx(style,'margin-left')];
  const border = [numberPx(style,'border-top-width'), numberPx(style,'border-right-width'), numberPx(style,'border-bottom-width'), numberPx(style,'border-left-width')];
  const padding = [numberPx(style,'padding-top'), numberPx(style,'padding-right'), numberPx(style,'padding-bottom'), numberPx(style,'padding-left')];
  const marginRect = boxRect(rect, ...margin, 'expand');
  const paddingRect = boxRect(rect, ...border, 'shrink');
  const contentRect = boxRect(paddingRect, ...padding, 'shrink');
  return { style, rect, margin, border, padding, marginRect, borderRect: rect, paddingRect, contentRect };
}

function fourSides(values) {
  return `${Math.round(values[0] * 10) / 10} · ${Math.round(values[1] * 10) / 10} · ${Math.round(values[2] * 10) / 10} · ${Math.round(values[3] * 10) / 10}`;
}

function renderInspectDetails(element, boxes) {
  const panel = document.getElementById('inspect-details');
  const mapping = resolveFigmaMapping(element);
  const legacyProps = collectInspectProps(element);
  const figmaProps = canonicalFigmaProps(element, mapping);
  const figmaPropsHtml = figmaProps.length
    ? figmaProps.map(([k,v]) => `<div class="inspect-prop"><span>${escapeHtml(k)}</span><code>${escapeHtml(v)}</code></div>`).join('')
    : '<div class="inspect-muted">Không có variant/state canonical bổ sung cho node này.</div>';
  const legacyPropsHtml = legacyProps.length
    ? legacyProps.map(([k,v]) => `<div class="inspect-prop"><span>${escapeHtml(k)}</span><code>${escapeHtml(v)}</code></div>`).join('')
    : '<div class="inspect-muted">Không có legacy prop override.</div>';
  const legacyLabel = [mapping.legacy?.theme && `Theme7.${mapping.legacy.theme}`, mapping.legacy?.ds, mapping.legacy?.internal].filter(Boolean).join(' · ') || '—';
  panel.innerHTML = `
    <div class="inspect-component-name">${escapeHtml(mapping.name)}</div>
    <div class="inspect-meta-grid">
      <span>Figma node</span><strong>${escapeHtml(mapping.nodeId || '—')}</strong>
      <span>Layer</span><strong>${escapeHtml(mapping.layer || '—')}</strong>
      <span>Mapping</span><strong>${escapeHtml(mapping.status || '—')}</strong>
      <span>Section</span><strong>${escapeHtml(mapping.section || '—')}</strong>
      <span>Authority</span><strong>Figma DS v2.0.3</strong>
      <span>Legacy</span><strong>${escapeHtml(legacyLabel)}</strong>
      <span>Element</span><strong>${escapeHtml(element.tagName.toLowerCase())}</strong>
      ${mapping.contextMapping ? `<span>Context</span><strong>${escapeHtml(mapping.contextMapping.name)}${mapping.contextMapping.nodeId ? ` · ${escapeHtml(mapping.contextMapping.nodeId)}` : ''}</strong>` : ''}
    </div>
    ${mapping.note ? `<div class="inspect-mapping-note">${escapeHtml(mapping.note)}</div>` : ''}
    <div class="inspect-subtitle">Figma props / variant</div>
    <div class="inspect-props">${figmaPropsHtml}</div>
    <div class="inspect-subtitle">Legacy annotation / trace</div>
    <div class="inspect-props">${legacyPropsHtml}</div>
    <div class="inspect-subtitle">Box model · T/R/B/L (px)</div>
    <div class="box-model-readout">
      <div class="box-line box-line--margin"><span>margin</span><code>${fourSides(boxes.margin)}</code></div>
      <div class="box-line box-line--border"><span>border</span><code>${fourSides(boxes.border)}</code></div>
      <div class="box-line box-line--padding"><span>padding</span><code>${fourSides(boxes.padding)}</code></div>
      <div class="box-line box-line--content"><span>content</span><code>${Math.round(boxes.contentRect.width * 10) / 10} × ${Math.round(boxes.contentRect.height * 10) / 10}</code></div>
    </div>`;
}

function showInspectOverlay(element) {
  if (!inspectEnabled || !element || !element.isConnected) return;
  inspectTarget = element;
  const overlay = document.getElementById('inspect-overlay');
  const boxes = inspectBoxValues(element);
  overlay.hidden = false;
  setInspectBox(overlay.querySelector('.inspect-box--margin'), boxes.marginRect);
  setInspectBox(overlay.querySelector('.inspect-box--border'), boxes.borderRect);
  setInspectBox(overlay.querySelector('.inspect-box--padding'), boxes.paddingRect);
  setInspectBox(overlay.querySelector('.inspect-box--content'), boxes.contentRect);
  const tag = overlay.querySelector('.inspect-tag');
  tag.textContent = inspectLabel(element);
  const tagTop = Math.max(4, boxes.borderRect.top - 25);
  const tagLeft = Math.max(4, Math.min(boxes.borderRect.left, window.innerWidth - 280));
  tag.style.top = `${tagTop}px`;
  tag.style.left = `${tagLeft}px`;
  renderInspectDetails(element, boxes);
}

function hideInspectOverlay() {
  const overlay = document.getElementById('inspect-overlay');
  if (overlay) overlay.hidden = true;
}

function resetInspectSelection() {
  inspectPinned = false;
  inspectTarget = null;
  hideInspectOverlay();
  const status = document.getElementById('inspect-pin-status');
  if (status) status.textContent = inspectEnabled ? 'Hover component' : 'Inspect off';
  const details = document.getElementById('inspect-details');
  if (details && inspectEnabled) details.textContent = 'Rê chuột lên component; click để ghim. Esc để bỏ ghim.';
}

function toggleInspect(force) {
  inspectEnabled = typeof force === 'boolean' ? force : !inspectEnabled;
  document.body.classList.toggle('inspect-mode', inspectEnabled);
  const toggle = document.getElementById('inspect-toggle');
  toggle.classList.toggle('is-active', inspectEnabled);
  toggle.setAttribute('aria-pressed', String(inspectEnabled));
  toggle.textContent = inspectEnabled ? 'Inspect · On' : 'Inspect';
  document.getElementById('inspect-section').hidden = !inspectEnabled;
  const url = new URL(window.location.href);
  if (inspectEnabled) url.searchParams.set('inspect', '1'); else url.searchParams.delete('inspect');
  history.replaceState(null, '', url);
  resetInspectSelection();
}

document.getElementById('inspect-toggle')?.addEventListener('click', () => toggleInspect());
document.getElementById('app-screen')?.addEventListener('pointermove', (event) => {
  if (!inspectEnabled || inspectPinned) return;
  const target = inspectableFrom(event.target);
  if (target) showInspectOverlay(target); else hideInspectOverlay();
});
document.getElementById('app-screen')?.addEventListener('pointerleave', () => {
  if (inspectEnabled && !inspectPinned) hideInspectOverlay();
});

// Capture click inside product viewport while Inspect is on so prototype actions
// never fire accidentally. A click pins the selected component instead.
document.addEventListener('click', (event) => {
  if (!inspectEnabled || !event.target.closest?.('#app-screen')) return;
  const target = inspectableFrom(event.target);
  if (!target) return;
  event.preventDefault();
  event.stopImmediatePropagation();
  inspectPinned = true;
  showInspectOverlay(target);
  document.getElementById('inspect-pin-status').textContent = 'Pinned · Esc để bỏ ghim';
}, true);

document.addEventListener('keydown', (event) => {
  if (event.key !== 'Escape' || !inspectEnabled) return;
  resetInspectSelection();
});
window.addEventListener('resize', () => { if (inspectEnabled && inspectTarget) showInspectOverlay(inspectTarget); });
document.getElementById('app-screen')?.addEventListener('scroll', () => { if (inspectEnabled && inspectTarget) showInspectOverlay(inspectTarget); }, true);

document.addEventListener("click", (event) => {
  const documentCard = event.target.closest("[data-bj02-document-id]");
  if (documentCard) {
    event.preventDefault(); selectedDocumentId = documentCard.dataset.bj02DocumentId; flowMode = "document"; resetBj02Receipt("document"); return navigate("SCR-009");
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


document.addEventListener("click", (event) => {
  if (activeFlowId === "UIF-01") {
    const product = event.target.closest("[data-bj01-product]");
    if (product) { bj01SelectedProductId=product.dataset.bj01Product; bj01LotOpen=false; bj01ProvenanceOpen=false; return navigate("SCR-003"); }
    const lot = event.target.closest("[data-bj01-lot]");
    if (lot) { bj01SelectedLotCode=lot.dataset.bj01Lot; bj01LotOpen=true; bj01ProvenanceOpen=false; return renderAppScreen(); }
    const filter = event.target.closest("[data-bj01-filter]");
    if (filter) { bj01Filter=filter.dataset.bj01Filter; stateByScreen["SCR-001"]="READY"; return render(); }
    if (event.target.closest("[data-bj01-clear]")) { bj01Query=""; bj01Filter="ALL"; stateByScreen["SCR-001"]="READY"; return render(); }
    if (event.target.closest("[data-bj01-provenance]")) { bj01ProvenanceOpen=true; bj01LotOpen=false; return renderAppScreen(); }
    if (event.target.matches("[data-bj01-close-provenance]") || event.target.closest("button[data-bj01-close-provenance]")) { bj01ProvenanceOpen=false; return renderAppScreen(); }
    if (event.target.matches("[data-bj01-close-lot]") || event.target.closest("button[data-bj01-close-lot]")) { bj01LotOpen=false; return renderAppScreen(); }
    if (event.target.closest("[data-bj01-refresh]")) { bj01QueryAsOf=bj01RefreshSequence[Math.min(bj01RefreshIndex,bj01RefreshSequence.length-1)]; bj01RefreshIndex=Math.min(bj01RefreshIndex+1,bj01RefreshSequence.length-1); stateByScreen[activeScreenId]="READY"; return render(); }
    if (event.target.closest("[data-bj01-handoff]")) {
      bj01ProvenanceOpen=false; bj01LotOpen=false; activeFlowId="UIF-15"; activeScreenId="SCR-054"; syncReviewUrl(); return render();
    }
  }
  const screenButton = event.target.closest("[data-screen]");
  if (screenButton) return navigate(screenButton.dataset.screen);

  const stateButton = event.target.closest("[data-state]");
  if (stateButton) {
    stateByScreen[activeScreenId] = stateButton.dataset.state;
    syncReviewUrl();
    return render();
  }

  const viewportButton = event.target.closest("[data-viewport]");
  if (viewportButton) {
    viewport = viewportButton.dataset.viewport;
    syncReviewUrl();
    document.querySelectorAll(".viewport-button").forEach((button) => button.classList.toggle("is-active", button === viewportButton));
    
document.getElementById("device-preview").className = `device-preview is-${viewport}`;
    return;
  }

  const flowButton = event.target.closest("[data-flow]");
  if (flowButton) {
    const nextFlow = flowButton.dataset.flow;
    if (nextFlow !== flowMode) {
      flowMode = nextFlow;
      resetBj02Receipt(flowMode);
    }
    syncReviewUrl();
    if (flowButton.dataset.next) return navigate(flowButton.dataset.next);
    return navigate(flowMode === "quick" ? "SCR-008" : "SCR-007");
  }

  const productOption = event.target.closest("[data-product-option]");
  if (productOption) return selectQuickProduct(productOption.dataset.productOption);

  const nextButton = event.target.closest("[data-next]");
  if (nextButton) return navigate(nextButton.dataset.next);

  if (event.target.closest("[data-back]")) return previousScreen();

  const actionButton = event.target.closest("[data-action]");
  if (!actionButton) return;
  const action = actionButton.dataset.action;
  if (action === "close-toast") { actionButton.closest(".toast")?.remove(); return; }
  if (action === "change-product") {
    if (hasReceiptLineInput()) return openChangeProductDialog();
    return resetQuickProduct();
  }
  if (action === "close-product-change") return closeChangeProductDialog();
  if (action === "confirm-product-change") { closeChangeProductDialog(); return resetQuickProduct(); }
  if (action === "close-reject") return closeRejectSheet();
  if (action === "exit-flow") { flowMode = "document"; selectedDocumentId = "PN-260816-04"; resetBj02Receipt("document"); return navigate("SCR-006"); }
  if (action === "exit-approval") return showToast("Quay về danh sách việc cần duyệt của người phê duyệt", "info");
  if (action === "exit-inventory-product-context") { const p=bj01ProductById(bj01SelectedProductId); return showToast(`Quay về sản phẩm ${p?.name || "đang xem"}`, "info"); }
  if (action === "exit-receipt-document-context") return showToast(`Quay về chứng từ ${selectedDocumentId}`, "info");
  if (action === "exit-reservation-context") return showToast(`Quay về đơn bán ${io04Fixture.order}`, "info");
  if (action === "exit-io06-approval") { io06ApproverListMode=true; io06RejectOpen=false; return renderAppScreen(); }
  if (action === "add-lot") {
    addLotEntry();
    return;
  }
  if (action === "remove-lot") {
    removeLotEntry(actionButton);
    return;
  }
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
});

document.addEventListener("focusin", (event) => {
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
  if (!event.target.matches("[data-product-search]")) return;
  quickProductMenuOpen = true;
  const menu = document.querySelector("[data-vcombobox-menu]");
  if (menu) { menu.hidden = false; menu.classList.add("is-open"); }
  event.target.setAttribute("aria-expanded", "true");
  filterQuickProductOptions(event.target.value);
});

document.addEventListener("focusout", (event) => {
  if (!event.target.matches("[data-bj02-supplier-search]")) return;
  supplierValidationVisible = true;
  const valid = supplierCatalog.some((supplier) => supplier.id === bj02Header.supplierId && supplier.name === bj02Header.supplier.trim());
  const error = document.querySelector("[data-bj02-supplier-error]");
  if (error) error.hidden = valid;
});

document.addEventListener("pointerdown", (event) => {
  if (!event.target.closest(".quick-overview-search-wrap")) {
    const overviewMenu = document.querySelector("[data-bj02-overview-product-menu]");
    const overviewInput = document.querySelector("[data-bj02-overview-product-search]");
    if (overviewMenu) { overviewMenu.hidden = true; overviewMenu.classList.remove("is-open"); }
    if (overviewInput) overviewInput.setAttribute("aria-expanded", "false");
    quickOverviewProductMenuOpen = false;
  }
  if (event.target.closest(".bj02-select-sheet")) return;
  if (event.target.closest(".combobox-html-renderer")) return;
  const menu = document.querySelector("[data-vcombobox-menu]");
  const input = document.querySelector("[data-product-search]");
  if (menu) { menu.hidden = true; menu.classList.remove("is-open"); }
  if (input) input.setAttribute("aria-expanded", "false");
  quickProductMenuOpen = false;
  const supplierMenu = document.querySelector("[data-bj02-supplier-menu]");
  const supplierInput = document.querySelector("[data-bj02-supplier-search]");
  if (supplierMenu) { supplierMenu.hidden = true; supplierMenu.classList.remove("is-open"); }
  if (supplierInput) supplierInput.setAttribute("aria-expanded", "false");
  supplierMenuOpen = false;
});

document.addEventListener("change", (event) => {
  if (event.target.matches("[data-bj02-evidence-file]")) { bj02Header.evidence = event.target.files?.[0]?.name || ""; return renderAppScreen(); }
  if (event.target.matches("[data-bj02-line-uom-select]")) { if (lineEditorIsReadOnly() || !event.target.value) return; return chooseLineUom(event.target.value); }
  if (event.target.matches("[data-bj02-uom]")) { if (lineEditorIsReadOnly()) return; return chooseLineUom(event.target.value); }
});


document.addEventListener("input", (event) => {
  if (event.target.matches("[data-bj02-overview-product-search]")) {
    quickOverviewProductQuery = event.target.value;
    quickOverviewProductMenuOpen = true;
    const menu=document.querySelector("[data-bj02-overview-product-menu]");
    if(menu){menu.hidden=false;menu.classList.add("is-open");}
    event.target.setAttribute("aria-expanded","true");
    filterQuickOverviewProductOptions(event.target.value);
    return;
  }
  if (activeFlowId === "UIF-01" && event.target.matches("[data-bj01-search]")) {
    bj01Query=event.target.value;
    const q=bj01Query.trim().toLocaleLowerCase("vi");
    let visible=0;
    document.querySelectorAll("[data-bj01-search-text]").forEach((row)=>{ const show=!q || row.dataset.bj01SearchText.includes(q); row.hidden=!show; if(show) visible+=1; });
    const empty=document.querySelector("[data-bj01-empty]"); if(empty) empty.hidden=visible!==0;
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
  if (event.target.matches("[data-product-search]")) {
    quickProductMenuOpen = true;
    const menu = document.querySelector("[data-vcombobox-menu]");
    if (menu) { menu.hidden = false; menu.classList.add("is-open"); }
    filterQuickProductOptions(event.target.value);
  }
  if (event.target.matches("[data-qty], .lot-meta-grid input")) updateReceiptBalance();
  if (event.target.matches("[data-reject-reason]")) {
    const confirm = document.querySelector('[data-action="confirm-reject"]');
    if (confirm) confirm.disabled = event.target.value.trim().length === 0;
  }
});

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

document.getElementById("device-preview").className = `device-preview is-${viewport}`;
document.querySelectorAll(".viewport-button").forEach((button) => button.classList.toggle("is-active", button.dataset.viewport === viewport));
syncReviewUrl();


// Inventory Valuation interactions — UIF-03 v1.4.4.


// v1.7.0 Correction & Recovery interactions
 document.addEventListener("input",(event)=>{
  if(activeFlowId==="UIF-11"){
    if(event.target.matches("[data-cr11-search]")){cr11Query=event.target.value;return renderAppScreen();}
    if(event.target.matches("[data-cr11-correct-qty]")){cr11CorrectQty=Math.max(0,Number(event.target.value)||0);return renderAppScreen();}
    if(event.target.matches("[data-cr11-correction-reason]")){cr11CorrectionReason=event.target.value;return;}
    if(event.target.matches("[data-cr11-cancel-reason]")){cr11CancelReason=event.target.value;const btn=document.querySelector('[data-cr11-action="confirm-cancel"]');if(btn)btn.disabled=!cr11CancelReason.trim();return;}
    if(event.target.matches("[data-cr11-approval-reason]")){cr11ApprovalRejectReason=event.target.value;const btn=document.querySelector('[data-cr11-action="reject-confirm"]');if(btn)btn.disabled=!cr11ApprovalRejectReason.trim();return;}
  }
  if(["UIF-16","UIF-17"].includes(activeFlowId)&&event.target.matches("[data-cr-control-search]")){crControlQuery=event.target.value;return renderAppScreen();}
 },true);
 document.addEventListener("change",(event)=>{
  if(activeFlowId==="UIF-11"&&event.target.matches("[data-cr11-strategy]")){cr11Strategy=event.target.value;return renderAppScreen();}
 },true);
 document.addEventListener("click",(event)=>{
  if(activeFlowId==="UIF-11"){
    const filter=event.target.closest("[data-cr11-filter]");if(filter){event.preventDefault();cr11Filter=filter.dataset.cr11Filter;return renderAppScreen();}
    const row=event.target.closest("[data-cr11-operation]");if(row){event.preventDefault();cr11SelectedId=row.dataset.cr11Operation;const op=cr11Current();stateByScreen["SCR-049"]=cr11StateFor(op);return navigate("SCR-049");}
    const a=event.target.closest("[data-cr11-action]");if(a&&!a.disabled){event.preventDefault();const k=a.dataset.cr11Action;
      if(k==="to-list"){cr11Query="";stateByScreen["SCR-048"]="READY";return navigate("SCR-048");}
      if(k==="back-detail")return navigate("SCR-049");
      if(k==="open-cancel"){stateByScreen["SCR-052"]="CANCEL_UNEXECUTED";cr11CancelReason="";return navigate("SCR-052");}
      if(k==="confirm-cancel"){if(!cr11CancelReason.trim()){stateByScreen["SCR-052"]="VALIDATION_ERROR";return renderAppScreen();}stateByScreen["SCR-053"]="CANCELLED";return navigate("SCR-053");}
      if(k==="open-correction"){stateByScreen["SCR-052"]="CORRECTION_ROUTE";return navigate("SCR-052");}
      if(k==="edit-correction"){cr11CorrectQty=cr11Current().correctQty||cr11Current().qty;stateByScreen["SCR-050"]="READY";return navigate("SCR-050");}
      if(k==="submit-correction"){if(Number(cr11CorrectQty)<0||!cr11CorrectionReason.trim()){stateByScreen["SCR-050"]="VALIDATION_ERROR";return renderAppScreen();}stateByScreen["SCR-053"]="PENDING_APPROVAL";return navigate("SCR-053");}
      if(k==="reject-open"){cr11ApprovalRejectOpen=true;cr11ApprovalRejectReason="";return renderAppScreen();}
      if(k==="reject-close"){cr11ApprovalRejectOpen=false;return renderAppScreen();}
      if(k==="reject-confirm"){if(!cr11ApprovalRejectReason.trim()){stateByScreen["SCR-051"]="VALIDATION_ERROR";return renderAppScreen();}cr11ApprovalRejectOpen=false;stateByScreen["SCR-053"]="REJECTED";return navigate("SCR-053");}
      if(k==="approve"){stateByScreen["SCR-053"]="PROCESSING";navigate("SCR-053");setTimeout(()=>{if(activeFlowId==="UIF-11"&&activeScreenId==="SCR-053"&&stateByScreen["SCR-053"]==="PROCESSING"){stateByScreen["SCR-053"]="COMPLETED";syncReviewUrl();render();}},650);return;}
      if(k==="approval-result"){return navigate("SCR-053");}
      if(k==="handoff-unknown"){cr17SelectedId="REC-UNKNOWN-01";stateByScreen["SCR-079"]="UNKNOWN_EVIDENCE";return crSwitchFlow("UIF-17","SCR-079","UNKNOWN_EVIDENCE");}
    }
  }
  if(activeFlowId==="UIF-16"){
    const f=event.target.closest("[data-cr16-filter]");if(f){event.preventDefault();cr16Filter=f.dataset.cr16Filter;return renderAppScreen();}
  }
  if(activeFlowId==="UIF-17"){
    const f=event.target.closest("[data-cr17-filter]");if(f){event.preventDefault();cr17Filter=f.dataset.cr17Filter;return renderAppScreen();}
  }
  if(["UIF-16","UIF-17"].includes(activeFlowId)){
    const row=event.target.closest("[data-cr-case]");if(row){event.preventDefault();if(activeFlowId==="UIF-16"){cr16SelectedId=row.dataset.crCase;stateByScreen["SCR-079"]=cr079StateFor16(cr16Current());}else{cr17SelectedId=row.dataset.crCase;stateByScreen["SCR-079"]=cr079StateFor17(cr17Current());}return navigate("SCR-079");}
  }
  if(activeFlowId==="UIF-16"){
    const a=event.target.closest("[data-cr16-action]");if(a&&!a.disabled){event.preventDefault();const k=a.dataset.cr16Action;
      if(k==="open-plan"){stateByScreen["SCR-080"]="READY";return navigate("SCR-080");}
      if(k==="start-recovery"){stateByScreen["SCR-081"]="REBUILDING";navigate("SCR-081");setTimeout(()=>{if(activeFlowId==="UIF-16"&&activeScreenId==="SCR-081"&&stateByScreen["SCR-081"]==="REBUILDING"){stateByScreen["SCR-081"]="READY";syncReviewUrl();render();}},750);return;}
      if(k==="review-result"){stateByScreen["SCR-082"]="READY";return navigate("SCR-082");}
      if(k==="review-close"){stateByScreen["SCR-082"]="READY";return navigate("SCR-082");}
      if(k==="close-case"){stateByScreen["SCR-083"]="RESOLVED";return navigate("SCR-083");}
      if(k==="show-escalated"){stateByScreen["SCR-083"]="ESCALATED";return navigate("SCR-083");}
      if(k==="handoff-correction"){cr11SelectedId="IO-260901-014";stateByScreen["SCR-049"]="CORRECTABLE";return crSwitchFlow("UIF-11","SCR-049","CORRECTABLE");}
      if(k==="to-list"){crControlQuery="";stateByScreen["SCR-078"]="READY";return navigate("SCR-078");}
    }
  }
  if(activeFlowId==="UIF-17"){
    const a=event.target.closest("[data-cr17-action]");if(a&&!a.disabled){event.preventDefault();const k=a.dataset.cr17Action;
      if(k==="open-plan"){stateByScreen["SCR-080"]=cr17Current().evidence==="INSUFFICIENT"?"INSUFFICIENT_EVIDENCE":"READY";return navigate("SCR-080");}
      if(k==="execute-plan"){cr17ResolutionMode=cr17Current().evidence==="COMMITTED"?"COMMITTED":"CONTINUED";stateByScreen["SCR-082"]="READY";return navigate("SCR-082");}
      if(k==="finish-review"){stateByScreen["SCR-083"]="COMPLETED";return navigate("SCR-083");}
      if(k==="show-escalated"){stateByScreen["SCR-083"]="ESCALATED";return navigate("SCR-083");}
      if(k==="to-list"){crControlQuery="";cr17ResolutionMode="";stateByScreen["SCR-078"]="READY";return navigate("SCR-078");}
    }
  }
 },true);

// v2.4.1 Inventory Audit & Control interactions — BJ08 Product + DS correction; UIF09/10 carried forward.
 document.addEventListener("input",(event)=>{
  if(activeFlowId==="UIF-08"){
    if(event.target.matches("[data-ic08-reason]")){ic08Reason=event.target.value;return;}
    if(event.target.matches("[data-ic08-cancel-reason]")){ic08CancelReason=event.target.value;const b=document.querySelector('[data-ic08-action="confirm-cancel"]');if(b)b.disabled=!ic08CancelReason.trim();return;}
    if(event.target.matches("[data-ic08-review-reason]")){ic08ReviewReason=event.target.value;const b=document.querySelector('[data-ic08-action="confirm-request-review"]');if(b)b.disabled=!ic08ReviewReason.trim();return;}
  }
  if(activeFlowId==="UIF-09"&&event.target.matches("[data-ic09-search]")){ic09Query=event.target.value;return renderAppScreen();}
 });
 document.addEventListener("change",(event)=>{
  if(activeFlowId==="UIF-08"){
    if(event.target.matches("[data-ic08-scope]")){ic08Scope=event.target.value;ic08ScopeTarget="";ic08ScopeSheetOpen=false;return renderAppScreen();}
  }
  if(activeFlowId==="UIF-09"&&event.target.matches("[data-ic09-destination]")){ic09Destination=event.target.value;return renderAppScreen();}
 });
 document.addEventListener("click",(event)=>{
  if(activeFlowId==="UIF-08"){
    const key=event.target.closest("[data-ic08-key]");
    if(key){event.preventDefault();const k=key.dataset.ic08Key;if(k==="⌫")ic08KeypadDraft=ic08KeypadDraft.slice(0,-1);else if(k==="."){if(!ic08KeypadDraft.includes("."))ic08KeypadDraft=(ic08KeypadDraft||"0")+".";}else{ic08KeypadDraft=(ic08KeypadDraft==="0"?"":ic08KeypadDraft)+k;}return renderAppScreen();}
    const qty=event.target.closest("[data-ic08-keypad-open]");
    if(qty&&!qty.disabled){event.preventDefault();ic08KeypadTarget=qty.dataset.ic08KeypadOpen;const [mode,id]=ic08KeypadTarget.split(":");ic08KeypadDraft=mode==="recount"?(ic08Recounts[id]||"0"):(id==="unexpected"?(ic08UnexpectedLine?.value||"0"):(ic08Counts[id]||"0"));return renderAppScreen();}
    const scopeTarget=event.target.closest("[data-ic08-scope-target]");
    if(scopeTarget){event.preventDefault();ic08ScopeTarget=scopeTarget.dataset.name||scopeTarget.textContent.trim();ic08ScopeSheetOpen=false;return renderAppScreen();}
    const product=event.target.closest("[data-ic08-product]");
    if(product){event.preventDefault();const id=product.dataset.ic08Product;ic08UnexpectedLine=id==="vitc"?{id:"unexpected",name:"Vitamin C",lot:"L2501-C",uom:"hộp",value:"0"}:{id:"unexpected",name:"Amox 500",lot:"L2501-A",uom:"hộp",value:"0"};ic08ProductSheetOpen=false;return renderAppScreen();}
    const a=event.target.closest("[data-ic08-action]");
    if(a&&!a.disabled){event.preventDefault();const k=a.dataset.ic08Action;
      if(k==="create")return navigate("SCR-043");
      if(k==="resume"){stateByScreen["SCR-044"]="BLIND_COUNT";return navigate("SCR-044");}
      if(k==="scope-select-open"){ic08ScopeSheetOpen=true;ic08ProductSheetOpen=false;return renderAppScreen();}
      if(k==="add-actual-open"){ic08ProductSheetOpen=true;ic08ScopeSheetOpen=false;return renderAppScreen();}
      if(k==="select-close"){ic08ProductSheetOpen=false;ic08ScopeSheetOpen=false;return renderAppScreen();}
      if(k==="open-session"){ic08ConfirmKind="open-session";return renderAppScreen();}
      if(k==="confirm-open-session"){ic08ConfirmKind=null;stateByScreen["SCR-044"]="BLIND_COUNT";return navigate("SCR-044");}
      if(k==="submit-first"){ic08ConfirmKind="submit-first";return renderAppScreen();}
      if(k==="confirm-submit-first"){ic08ConfirmKind=null;stateByScreen["SCR-045"]="RECOUNT_REQUIRED";return navigate("SCR-045");}
      if(k==="submit-recount"){ic08ConfirmKind="submit-recount";return renderAppScreen();}
      if(k==="confirm-submit-recount"){ic08ConfirmKind=null;stateByScreen["SCR-042"]="PENDING_APPROVAL";return navigate("SCR-042");}
      if(k==="cancel-open"){ic08CancelReason="";ic08ConfirmKind="cancel";return renderAppScreen();}
      if(k==="confirm-cancel"){if(!ic08CancelReason.trim())return;ic08ConfirmKind=null;stateByScreen["SCR-047"]="CANCELLED";return navigate("SCR-047");}
      if(k==="confirm-close"){ic08ConfirmKind=null;return renderAppScreen();}
      if(k==="keypad-cancel"){ic08KeypadTarget=null;ic08KeypadDraft="";return renderAppScreen();}
      if(k==="keypad-save"){
        const [mode,id]=(ic08KeypadTarget||":").split(":");const v=ic08KeypadDraft||"0";
        if(mode==="recount"&&id)ic08Recounts[id]=v;else if(mode==="count"&&id==="unexpected"&&ic08UnexpectedLine)ic08UnexpectedLine.value=v;else if(mode==="count"&&id)ic08Counts[id]=v;
        ic08KeypadTarget=null;ic08KeypadDraft="";return renderAppScreen();
      }
      if(k==="approve"){ic08ConfirmKind="approve";return renderAppScreen();}
      if(k==="confirm-approve"){ic08ConfirmKind=null;stateByScreen["SCR-047"]="COMPLETED";return navigate("SCR-047");}
      if(k==="request-review"){ic08ReviewReason="";ic08ConfirmKind="request-review";return renderAppScreen();}
      if(k==="confirm-request-review"){if(!ic08ReviewReason.trim())return;ic08ConfirmKind=null;stateByScreen["SCR-045"]="RECOUNT_REQUIRED";return navigate("SCR-045");}
      if(k==="approval-result"){return navigate("SCR-047");}
      if(k==="verify-result")return renderAppScreen();
      if(k==="to-list"){stateByScreen["SCR-042"]="READY";return navigate("SCR-042");}
    }
  }
  if(activeFlowId==="UIF-09"){
    const f=event.target.closest("[data-ic09-filter]"); if(f){event.preventDefault();ic09Filter=f.dataset.ic09Filter;return renderAppScreen();}
    const item=event.target.closest("[data-ic09-item]"); if(item){event.preventDefault();ic09Selected=item.dataset.ic09Item;stateByScreen["SCR-037"]=ic09Current().state==="EXPIRED"?"EXPIRED":"READY";return navigate("SCR-037");}
    const a=event.target.closest("[data-ic09-action]"); if(a&&!a.disabled){event.preventDefault();const k=a.dataset.ic09Action;
      if(k==="change"){stateByScreen["SCR-038"]="READY";return navigate("SCR-038");} if(k==="history")return navigate("SCR-056");
      if(k==="submit"){stateByScreen["SCR-038"]="PENDING_APPROVAL";return render();} if(k==="approve"){stateByScreen["SCR-041"]="COMPLETED";return navigate("SCR-041");}
      if(k==="reject"){stateByScreen["SCR-041"]="REJECTED_EXECUTION";return navigate("SCR-041");} if(k==="verify")return renderAppScreen();
      if(k==="to-list"){stateByScreen["SCR-036"]="READY";return navigate("SCR-036");}
    }
  }
  if(activeFlowId==="UIF-10"){
    const item=event.target.closest("[data-ic10-item]"); if(item){event.preventDefault();ic10Selected=item.dataset.ic10Item;stateByScreen["SCR-037"]="READY";return navigate("SCR-037");}
    const a=event.target.closest("[data-ic10-action]"); if(a&&!a.disabled){event.preventDefault();const k=a.dataset.ic10Action;
      if(k==="request"){stateByScreen["SCR-040"]="READY";return navigate("SCR-040");} if(k==="submit"){stateByScreen["SCR-040"]="PENDING_APPROVAL";return render();}
      if(k==="approve"){stateByScreen["SCR-040"]="APPROVED_PENDING_DISPOSAL";return render();} if(k==="reject"){stateByScreen["SCR-041"]="REJECTED_EXECUTION";return navigate("SCR-041");}
      if(k==="complete"){stateByScreen["SCR-041"]="COMPLETED";return navigate("SCR-041");} if(k==="verify")return renderAppScreen();
      if(k==="to-list"){stateByScreen["SCR-036"]="READY";return navigate("SCR-036");}
    }
  }
 },true);

document.addEventListener("input",(event)=>{if(activeFlowId!=="UIF-03")return;if(event.target.matches("[data-val03-search]")){val03Query=event.target.value;return renderAppScreen();}if(event.target.matches("[data-val03-qty]")){const id=event.target.dataset.val03Qty;for(const g of val03Current().groups){const sl=g.slices.find(x=>x.id===id);if(sl){sl.selectedQty=Math.max(1,Math.min(Number(event.target.value)||1,sl.pendingQty));break;}}return;}if(event.target.matches("[data-val03-reason]")){const g=val03Current().groups.find(x=>x.id===event.target.dataset.val03Reason);if(g)g.reason=event.target.value;const reviewBtn=document.querySelector('[data-val03-action="open-review"]');if(reviewBtn)reviewBtn.disabled=!val03ScopeReady();const doneBtn=document.querySelector('.button--primary[data-val03-action="close-evidence-sheet"]');if(doneBtn)doneBtn.disabled=val03HasSelectedConflict()&&!val03ScopeReady();return;}});
document.addEventListener("click",(event)=>{if(activeFlowId!=="UIF-03")return;const filter=event.target.closest("[data-val03-filter]");if(filter){event.preventDefault();val03Filter=filter.dataset.val03Filter;return renderAppScreen();}const receipt=event.target.closest("[data-val03-receipt]");if(receipt){event.preventDefault();val03SelectedReceiptId=receipt.dataset.val03Receipt;val03LastSourceChange=null;val03EvidenceSheetOpen=false;return navigate("SCR-015");}const sliceBtn=event.target.closest("[data-val03-slice]");if(sliceBtn&&!sliceBtn.disabled){event.preventDefault();const id=sliceBtn.dataset.val03Slice;for(const g of val03Current().groups){const sl=g.slices.find(x=>x.id===id);if(sl){sl.selected=!sl.selected;sl.selectedQty=sl.pendingQty;sl.partialOpen=false;break;}}return renderAppScreen();}const partial=event.target.closest("[data-val03-partial]");if(partial){event.preventDefault();const id=partial.dataset.val03Partial;for(const g of val03Current().groups){const sl=g.slices.find(x=>x.id===id);if(sl){sl.partialOpen=!sl.partialOpen;sl.selectedQty=sl.pendingQty;break;}}return renderAppScreen();}const source=event.target.closest("[data-val03-source]");if(source){event.preventDefault();const g=val03Current().groups.find(x=>x.id===source.dataset.val03Source);if(g){g.selectedSource=source.dataset.val03SourceId;g.reason="";}return renderAppScreen();}const action=event.target.closest("[data-val03-action]");if(!action||action.disabled)return;event.preventDefault();const k=action.dataset.val03Action;if(k==="open-evidence-sheet"){val03EvidenceSheetOpen=true;return renderAppScreen();}if(k==="close-evidence-sheet"){val03EvidenceSheetOpen=false;if(activeScreenId==="SCR-017")val03ReviewSourceVersion=val03Current().sourceVersion;stateByScreen[activeScreenId]="READY";return renderAppScreen();}if(k==="open-review"){if(!val03ScopeReady()){val03EvidenceSheetOpen=true;return renderAppScreen();}val03EvidenceSheetOpen=false;val03ReviewSourceVersion=val03Current().sourceVersion;stateByScreen["SCR-017"]="READY";return navigate("SCR-017");}if(k==="retired-to-scope"){val03EvidenceSheetOpen=false;return navigate("SCR-015");}if(k==="confirm-value"){if(Number(val03ReviewSourceVersion)!==Number(val03Current().sourceVersion)){stateByScreen["SCR-017"]="SOURCE_CHANGED";val03EvidenceSheetOpen=true;return renderAppScreen();}if(!val03ScopeReady())return;val03Commit();val03EvidenceSheetOpen=false;stateByScreen["SCR-019"]="COMPLETED";return navigate("SCR-019");}if(k==="continue-remaining"){stateByScreen["SCR-015"]="ALREADY_CONFIRMED";return navigate("SCR-015");}if(k==="result-to-scope"){stateByScreen["SCR-015"]="READY";return navigate("SCR-015");}if(k==="result-to-queue"){val03Query="";val03Filter="ALL";val03LastSourceChange=null;val03EvidenceSheetOpen=false;return navigate("SCR-014");}},true);


// Inventory Valuation late-cost interactions — UIF-13 v1.4.5.
document.addEventListener("input",(event)=>{if(activeFlowId!=="UIF-13")return;if(event.target.matches("[data-val13-search]")){val13Query=event.target.value;return renderAppScreen();}});
document.addEventListener("change",(event)=>{if(activeFlowId!=="UIF-13")return;if(event.target.matches("[data-val13-method]")){const t=val13Current();if(t.allowedMethods.some(m=>m.id===event.target.value)){t.selectedMethod=event.target.value;val13PreviewHash=null;}stateByScreen["SCR-087"]="READY";return renderAppScreen();}});
document.addEventListener("click",(event)=>{if(activeFlowId!=="UIF-13")return;const filter=event.target.closest("[data-val13-filter]");if(filter){event.preventDefault();val13Filter=filter.dataset.val13Filter;return renderAppScreen();}const task=event.target.closest("[data-val13-task]");if(task){event.preventDefault();val13SelectedTaskId=task.dataset.val13Task;val13ResetTaskDraft(val13Current());stateByScreen["SCR-086"]="READY";return navigate("SCR-086");}const target=event.target.closest("[data-val13-target]");if(target){event.preventDefault();const t=val13Current(),line=t.targets.find(x=>x.id===target.dataset.val13Target);if(line)line.selected=!line.selected;val13PreviewHash=null;stateByScreen["SCR-086"]="READY";return renderAppScreen();}const action=event.target.closest("[data-val13-action]");if(!action||action.disabled)return;event.preventDefault();const k=action.dataset.val13Action;if(k==="scope-to-allocation"){if(!val13CanOpenAllocation()){stateByScreen["SCR-086"]="VALIDATION_ERROR";return renderAppScreen();}val13LastSourceChange=null;stateByScreen["SCR-087"]="READY";return navigate("SCR-087");}if(k==="open-review"){if(!val13CanPreview()){stateByScreen["SCR-087"]="VALIDATION_ERROR";return renderAppScreen();}val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();stateByScreen["SCR-088"]="READY";return navigate("SCR-088");}if(k==="back-scope"){stateByScreen["SCR-086"]="READY";return navigate("SCR-086");}if(k==="back-allocation"){stateByScreen["SCR-087"]="READY";return navigate("SCR-087");}if(k==="confirm-late-cost"){const t=val13Current();if(Number(val13ReviewSourceVersion)!==Number(t.sourceVersion)||val13PreviewHash!==val13PreviewHashOf(t)){stateByScreen["SCR-088"]="SOURCE_CHANGED";return renderAppScreen();}val13Commit();stateByScreen["SCR-089"]="COMPLETED";return navigate("SCR-089");}if(k==="result-to-queue"){val13Query="";val13Filter="ALL";val13LastSourceChange=null;stateByScreen["SCR-085"]="READY";return navigate("SCR-085");}},true);

document.addEventListener("change",(event)=>{if(activeFlowId!=="UIF-14")return;if(event.target.matches("[data-val14-period]")){val14SetupPeriod=event.target.value;return renderAppScreen();}if(event.target.matches("[data-val14-scope]")){val14SetupScope=event.target.value;return renderAppScreen();}});
document.addEventListener("click",(event)=>{if(activeFlowId!=="UIF-14")return;const runBtn=event.target.closest("[data-val14-run]");if(runBtn){event.preventDefault();val14SelectedRunId=runBtn.dataset.val14Run;const r=val14Current();if(r.status==="DIRTY"){val14SetupKind=r.kind;val14SetupPeriod=r.period;val14SetupScope="Sản phẩm cần tính lại";val14SuccessorOf=r.id;return navigate("SCR-073");}stateByScreen["SCR-074"]=r.status==="BLOCKED"?"BLOCKED":"READY";return navigate("SCR-074");}const kind=event.target.closest("[data-val14-kind]");if(kind){event.preventDefault();val14SetupKind=kind.dataset.val14Kind;val14SetupScope=val14SetupKind==="PERIOD_CLOSE"?"Toàn bộ sản phẩm":"Sản phẩm cần tính lại";return renderAppScreen();}const action=event.target.closest("[data-val14-action]");if(!action||action.disabled)return;event.preventDefault();const k=action.dataset.val14Action;if(k==="new-run"){val14SuccessorOf=null;val14SetupKind="PERIOD_CLOSE";val14SetupScope="Toàn bộ sản phẩm";return navigate("SCR-073");}if(k==="calculate"){val14CreateRun();stateByScreen["SCR-074"]="READY";return navigate("SCR-074");}if(k==="review-publish"){const r=val14Current();if(r.status!=="READY_FOR_REVIEW")return;val14PublishReviewVersion=r.runInputHash||String(r.inputVersion);stateByScreen["SCR-076"]="READY";return navigate("SCR-076");}if(k==="successor"){const r=val14Current();val14SuccessorOf=r.id;val14SetupKind=r.kind;val14SetupPeriod=r.period;val14SetupScope=r.scope.includes("sản phẩm")?"Sản phẩm cần tính lại":"Toàn bộ sản phẩm";return navigate("SCR-073");}if(k==="publish"){const r=val14Current();if(String(val14PublishReviewVersion)!==String(r.runInputHash||r.inputVersion)){stateByScreen["SCR-076"]="SOURCE_CHANGED";return renderAppScreen();}val14Commit();stateByScreen["SCR-077"]="COMPLETED";return navigate("SCR-077");}if(k==="result-to-list"){return navigate("SCR-072");}if(k==="result-to-run"||k==="retired-to-result"){stateByScreen["SCR-074"]="READY";return navigate("SCR-074");}},true);


// Inventory Operations interactions — UIF-05 baseline v1.3.7, UIF-06 deep-corrected v1.3.8; scoped to UIF-04/05/06/07.
document.addEventListener("input",(event)=>{
  if(activeFlowId==="UIF-05" && event.target.matches("[data-io05-search]")){io05Query=event.target.value;ioFilterRows("io05",io05Query);return;}
  if(activeFlowId==="UIF-06" && event.target.matches("[data-io06-search]")){io06Query=event.target.value;ioFilterRows("io06",io06Query);return;}
  if(activeFlowId==="UIF-07" && event.target.matches("[data-io07-search]")){io07Query=event.target.value;ioFilterRows("io07",io07Query);return;}
  if(activeFlowId==="UIF-07" && event.target.matches("[data-io07-scan-lot]")){io07ScanLot=event.target.value;const f=io07FindAllocation(io07ActiveAllocationId);if(!f)return;const expected=f.group.tracking==="LOT"?String(f.allocation.lot||""):"";const mismatch=Boolean(expected&&io07ScanLot.trim()&&io07ScanLot.trim().toLocaleUpperCase("vi")!==expected.toLocaleUpperCase("vi"));const feedback=document.querySelector("[data-io07-scan-feedback]");if(feedback)feedback.innerHTML=mismatch?vBanner("error","Lô không khớp",`Cần lô ${expected}. Kho không thay lô tại đây.`,"","Compact"):"";const b=document.querySelector('[data-io07-action="confirm-allocation"]');if(b)b.disabled=mismatch;return;}
  if(activeFlowId==="UIF-05" && event.target.matches("[data-io05-picked-allocation]")){updateIO05AllocationValidation(event.target);return;}
  if(activeFlowId==="UIF-05" && event.target.matches("[data-io05-handover-allocation]")){updateIO05HandoverValidation(event.target);return;}
  if(activeFlowId==="UIF-05" && event.target.matches("[data-io05-override-reason]")){io05OverrideReason=event.target.value;const b=document.querySelector('[data-io05-action="confirm-lot-override"]');if(b)b.disabled=!io05OverrideReason.trim()||!io05OverrideLot;return;}
  if(activeFlowId==="UIF-05" && event.target.matches("[data-io05-pick-draft]")){io05PickDraft=event.target.value;const a=io05CurrentAllocation();const b=document.querySelector('[data-io05-action="update-pick-allocation"]');if(b)b.disabled=Number(io05PickDraft)<Number(a?.consumedQty||0)||Number(io05PickDraft)>Number(a?.allocatedQty||0);return;}
  if(activeFlowId==="UIF-06" && event.target.matches("[data-io06-qty]")){const line=io06ActiveLine();line.qty=event.target.value===""?null:Math.max(0,Number(event.target.value)||0);io06SetLineDirty(line);updateIO06LineValidation();return;}
  if(activeFlowId==="UIF-06" && event.target.matches("[data-io06-actual-lot]")){const line=io06ActiveLine();line.actualLot=event.target.value;line.actualLotMode="OTHER";io06SetLineDirty(line);updateIO06LineValidation();return;}
  if(activeFlowId==="UIF-06" && event.target.matches("[data-io06-reason-detail]")){const line=io06ActiveLine();line.reasonDetail=event.target.value;io06SetLineDirty(line);updateIO06LineValidation();return;}
  if(activeFlowId==="UIF-06" && event.target.matches("[data-io06-reject-reason]")){io06RejectReason=event.target.value;const b=document.querySelector('[data-io06-action="confirm-reject"]');if(b)b.disabled=!io06RejectReason.trim();return;}
  if(activeFlowId==="UIF-06" && event.target.matches("[data-io06-class]")){updateIO06ClassificationLive();return;}
});
document.addEventListener("change",(event)=>{
  if(activeFlowId==="UIF-06" && event.target.matches("[data-io06-actual-lot]")){const line=io06ActiveLine();line.actualLot=event.target.value;line.actualLotMode="OTHER";io06SetLineDirty(line);return renderAppScreen();}
  if(activeFlowId==="UIF-06" && event.target.matches("[data-io06-evidence-file]")){const line=io06ActiveLine();const file=event.target.files?.[0];line.evidenceFile=file?.name||"";line.evidenceData="";io06SetLineDirty(line);if(file){const reader=new FileReader();reader.onload=()=>{line.evidenceData=String(reader.result||"");renderAppScreen();};reader.readAsDataURL(file);return;}return renderAppScreen();}
});
document.addEventListener("click",(event)=>{
  if(!["UIF-04","UIF-05","UIF-06","UIF-07"].includes(activeFlowId)) return;
  const f5=event.target.closest("[data-io05-filter]");if(f5){event.preventDefault();io05QueueFilter=f5.dataset.io05Filter;return renderAppScreen();}
  const o5=event.target.closest("[data-io05-order]");if(o5){event.preventDefault();io05SelectedOrderId=o5.dataset.io05Order;const order=io05CurrentOrder();if(order.queue==="WAITING"||order.queue==="VERIFYING")return;io05ActiveLineId=order.lines?.[0]?.id||"";io05ActiveAllocationId=order.lines?.[0]?.allocations?.[0]?.id||"";io05OverrideOpen=false;io05ResetHandover(order);stateByScreen["SCR-026"]="READY";return navigate("SCR-026");}
  const l5=event.target.closest("[data-io05-line]");if(l5&&!l5.disabled){event.preventDefault();io05ActiveLineId=l5.dataset.io05Line;const line=io05CurrentLines().find(l=>l.id===io05ActiveLineId);io05ActiveAllocationId=line?.allocations[0]?.id||"";return navigate("SCR-027");}
  const pickAllocation=event.target.closest("[data-io05-pick-allocation]");if(pickAllocation){event.preventDefault();io05ActiveAllocationId=pickAllocation.dataset.io05PickAllocation;const a=io05CurrentAllocation();io05PickDraft=String(Number(a?.pickedQty||0));io05PickEditorOpen=true;return renderAppScreen();}
  if(event.target.matches("[data-io05-pick-editor-backdrop]")){event.preventDefault();io05PickEditorOpen=false;io05PickDraft="";return renderAppScreen();}
  const openOverride=event.target.closest("[data-io05-open-override]");if(openOverride){event.preventDefault();io05ActiveAllocationId=openOverride.dataset.io05OpenOverride;io05PickEditorOpen=false;io05OverrideOpen=true;io05OverrideLot="";io05OverrideReason="";return renderAppScreen();}
  if(event.target.matches("[data-io05-override-backdrop]")){event.preventDefault();io05OverrideOpen=false;return renderAppScreen();}
  const selectLot=event.target.closest("[data-io05-select-lot]");if(selectLot){event.preventDefault();io05OverrideLot=selectLot.dataset.io05SelectLot;return renderAppScreen();}

  const f6=event.target.closest("[data-io06-filter]");if(f6){event.preventDefault();io06QueueFilter=f6.dataset.io06Filter;return renderAppScreen();}
  const r6=event.target.closest("[data-io06-request]");if(r6){event.preventDefault();io06SelectedRequestId=r6.dataset.io06Request;const lines=io06CurrentLines();io06ActiveLineId=lines[0]?.id||"";io06ClassificationOpen=false;io06ClassificationDraft=null;return navigate(r6.dataset.io06Target||"SCR-031");}
  const line6=event.target.closest("[data-io06-line]");if(line6){event.preventDefault();io06ActiveLineId=line6.dataset.io06Line;return navigate("SCR-032");}
  const classLine=event.target.closest("[data-io06-class-line]");if(classLine){event.preventDefault();io06ActiveLineId=classLine.dataset.io06ClassLine;io06ClassificationOpen=true;return renderAppScreen();}
  const reason6=event.target.closest("[data-io06-reason]");if(reason6){event.preventDefault();const line=io06ActiveLine();line.reasonCode=reason6.dataset.io06Reason;if(line.reasonCode!=="OTHER")line.reasonDetail="";io06SetLineDirty(line);return renderAppScreen();}
  const expectedLot6=event.target.closest("[data-io06-select-actual-lot]");if(expectedLot6){event.preventDefault();const line=io06ActiveLine();line.actualLot=expectedLot6.dataset.io06SelectActualLot;line.actualLotMode="EXPECTED";line.reasonCode="";line.reasonDetail="";line.evidenceFile="";line.evidenceData="";io06SetLineDirty(line);return renderAppScreen();}
  const otherLot6=event.target.closest("[data-io06-select-other-lot]");if(otherLot6){event.preventDefault();const line=io06ActiveLine();line.actualLotMode="OTHER";if(line.actualLot===line.expectedLot)line.actualLot="";io06SetLineDirty(line);return renderAppScreen();}
  const approvalCase6=event.target.closest("[data-io06-approval-case]");if(approvalCase6){event.preventDefault();io06SelectedApprovalCaseId=approvalCase6.dataset.io06ApprovalCase;io06ApproverListMode=false;io06RejectOpen=false;stateByScreen["SCR-034"]="READY";return renderAppScreen();}
  if(event.target.matches("[data-io06-reject-backdrop]")){event.preventDefault();io06RejectOpen=false;return renderAppScreen();}

  const f7=event.target.closest("[data-io07-filter]");if(f7){event.preventDefault();io07QueueFilter=f7.dataset.io07Filter;return renderAppScreen();}
  const r7=event.target.closest("[data-io07-request]");if(r7){event.preventDefault();io07Selected=r7.dataset.io07Request;const req=io07Current();if(req.queue==="WAITING"||req.closed||req.completed)return;io07VerifySheetOpen=false;io07ActiveAllocationId="";stateByScreen["SCR-037"]=req.changed?"SOURCE_UPDATED":"READY";return navigate("SCR-037");}
  const allocation7=event.target.closest("[data-io07-allocation]");if(allocation7){event.preventDefault();io07OpenVerification(allocation7.dataset.io07Allocation);return renderAppScreen();}
  if(event.target.matches("[data-io07-verify-backdrop]")){event.preventDefault();io07VerifySheetOpen=false;io07ScanLot="";return renderAppScreen();}

  const a=event.target.closest("[data-io05-action],[data-io06-action],[data-io07-action]");if(!a)return;
  event.preventDefault();event.stopPropagation();
  const k=a.dataset.io05Action||a.dataset.io06Action||a.dataset.io07Action;
  if(k==="review-handover"){if(activeFlowId==="UIF-05"){io05ResetHandover();stateByScreen["SCR-028"]=io05CurrentOrder().partialHandoverAllowed?"PARTIAL_ALLOWED":"READY";return navigate("SCR-028");}const req=io07Current();if(!io07AllVerified(req)||io07HasMismatch(req))return;req.reviewSourceVersion=req.sourceVersion;stateByScreen["SCR-039"]="READY";return navigate("SCR-039");}
  if(k==="close-verification"){io07VerifySheetOpen=false;io07ScanLot="";return renderAppScreen();}
  if(k==="confirm-allocation"){const f=io07FindAllocation(io07ActiveAllocationId);if(!f)return;const expected=f.group.tracking==="LOT"?String(f.allocation.lot||""):"";if(expected&&io07ScanLot.trim()&&io07ScanLot.trim().toLocaleUpperCase("vi")!==expected.toLocaleUpperCase("vi"))return;f.allocation.verified=true;f.allocation.physicalMismatch=false;f.allocation.affectedByChange=false;f.allocation.verifyMethod=io07ScanLot.trim()?"SCAN_OR_TYPED_MATCH":"VISUAL";io07VerifySheetOpen=false;io07ScanLot="";stateByScreen["SCR-037"]="READY";return renderAppScreen();}
  if(k==="mark-mismatch"){const f=io07FindAllocation(io07ActiveAllocationId);if(!f)return;f.allocation.verified=false;f.allocation.physicalMismatch=true;io07VerifySheetOpen=false;io07ScanLot="";stateByScreen["SCR-037"]="PHYSICAL_MISMATCH";return renderAppScreen();}
  if(k==="back-to-preparation"){io07VerifySheetOpen=false;stateByScreen["SCR-037"]=io07Current().changed?"SOURCE_UPDATED":"READY";return navigate("SCR-037");}
  if(k==="update-pick-allocation"){const a=io05CurrentAllocation();if(!a||Number(io05PickDraft)<Number(a.consumedQty||0)||Number(io05PickDraft)>Number(a.allocatedQty||0))return;a.pickedQty=Math.max(Number(a.consumedQty||0),Number(io05PickDraft)||0);io05HandoverByAllocation[a.id]=io05AllocationRemainingPicked(a);io05PickEditorOpen=false;io05PickDraft="";return renderAppScreen();}
  if(k==="close-lot-override"){io05OverrideOpen=false;return renderAppScreen();}
  if(k==="confirm-lot-override"){if(!io05OverrideReason.trim()||!io05OverrideLot)return;const allocation=io05CurrentAllocation();const line=io05CurrentLine();if(allocation&&line&&Number(allocation.consumedQty||0)<=0){const oldLot=allocation.lot,oldPicked=io05AllocationRemainingPicked(allocation);allocation.lot=io05OverrideLot;allocation.overrideReason=io05OverrideReason;if(oldPicked>0){allocation.pickedQty=Number(allocation.consumedQty||0);allocation.physicalCorrection={kind:"MANUAL",status:"PENDING",oldLot,returnQty:oldPicked,newLot:io05OverrideLot,repickQty:oldPicked,actor:null,confirmedAt:null};}io05HandoverByAllocation[allocation.id]=0;const order=io05CurrentOrder();order.allocationVersion=Number(order.allocationVersion||0)+1;}io05OverrideOpen=false;return renderAppScreen();}
  if(k==="confirm-physical-correction"){const a=io05CurrentAllocation();if(!a||!io05CorrectionPending(a)||Number(a.pickedQty||0)<Number(a.physicalCorrection.repickQty||0))return;a.physicalCorrection={...a.physicalCorrection,status:"CONFIRMED",actor:IO05_ACTOR.name,actorId:IO05_ACTOR.id,confirmedAt:"16/09/2026 13:06"};return renderAppScreen();}
  if(k==="save-pick"){io05PickEditorOpen=false;io05PickDraft="";const line=io05CurrentLine();if(!line||line.allocations.some(a=>Number(a.pickedQty||0)>Number(a.allocatedQty||0))||line.allocations.some(a=>io05CorrectionPending(a)))return;io05ResetHandover();return navigate("SCR-026");}
  if(k==="back-to-pick"){stateByScreen["SCR-026"]="READY";return navigate("SCR-026");}
  if(k==="result-to-queue"){io05QueueFilter="ALL";io05Query="";return navigate("SCR-025");}
  if(k==="continue-remaining"){stateByScreen["SCR-026"]="READY";return navigate("SCR-026");}
  if(k==="confirm-handover"){if(activeFlowId==="UIF-05"){if(io05HandoverInvalid()||io05HandoverTotal()<=0)return;const result=io05ApplyHandover();if(!result)return;stateByScreen["SCR-029"]=result.full?"COMPLETED":"PARTIAL_COMPLETED";return navigate("SCR-029");}const req=io07Current();if(Number(req.reviewSourceVersion||req.sourceVersion)!==Number(req.sourceVersion)){stateByScreen["SCR-039"]="SOURCE_CHANGED";return renderAppScreen();}if(!io07AllVerified(req)||io07HasMismatch(req))return;io07CreateResult(req);req.completed=true;req.queue="CLOSED";stateByScreen["SCR-041"]="COMPLETED";return navigate("SCR-041");}
  if(k==="result-to-rtv-queue"){io07QueueFilter="ALL";io07Query="";io07VerifySheetOpen=false;return navigate("SCR-036");}
  if(k==="back-to-rtv-request"){const req=io07Current();if(req.closed||req.completed)return navigate("SCR-036");stateByScreen["SCR-037"]=req.changed?"SOURCE_UPDATED":"READY";return navigate("SCR-037");}

  if(k==="save-return-line"){const line=io06ActiveLine();if(!line||Number(line.qty||0)<=0||Number(line.qty||0)>Number(line.remaining||0)||Boolean(line.expectedLot&&!line.actualLot))return;line.verified=true;if(!io06Mismatch(line)){const c=io06LineCase(line);if(c)c.status="INVALIDATED";line.exceptionCaseId=null;line.reasonCode="";line.reasonDetail="";line.evidenceFile="";line.evidenceData="";}io06RefreshRequestState(io06CurrentRequest());return navigate("SCR-031");}
  if(k==="save-return-exception"){const line=io06ActiveLine();if(!line||Number(line.qty||0)<=0||Number(line.qty||0)>Number(line.remaining||0)||!io06Mismatch(line)||!io06LineEvidenceReady(line))return;line.verified=true;io06InvalidateCaseIfChanged(line);io06RefreshRequestState(io06CurrentRequest());return navigate("SCR-031");}
  if(k==="submit-return-exceptions"){const req=io06CurrentRequest();if(!io06SubmitDraftExceptions(req))return;return renderAppScreen();}
  if(k==="approve-exception"){const c=io06SelectedApprovalCase();if(!c||c.status!=="PENDING")return;c.status="APPROVED";c.decisionReason="";io06AfterApprovalDecision(c);return renderAppScreen();}
  if(k==="open-reject"){io06RejectOpen=true;io06RejectReason="";return renderAppScreen();}
  if(k==="close-reject"){io06RejectOpen=false;return renderAppScreen();}
  if(k==="confirm-reject"){if(!io06RejectReason.trim())return;const c=io06SelectedApprovalCase();if(!c||c.status!=="PENDING")return;c.status="REJECTED";c.decisionReason=io06RejectReason.trim();io06RejectOpen=false;io06AfterApprovalDecision(c);return renderAppScreen();}
  if(k==="exit-approval-detail"){io06ApproverListMode=true;io06RejectOpen=false;return renderAppScreen();}
  if(k==="refresh-return-request"){const req=io06CurrentRequest();const line=io06CurrentLines()[0];if(stateByScreen["SCR-031"]==="RETURN_CAP_CHANGED"&&line){line.remaining=Math.max(1,Number(line.remaining||0)-1);if(Number(line.qty||0)>line.remaining){line.qty=null;line.verified=false;}}stateByScreen["SCR-031"]="READY";io06RefreshRequestState(req);return renderAppScreen();}
  if(k==="commit-receipt"){const req=io06CurrentRequest();if(!io06ReceiptReady(req))return;req.receiptCommitted=true;req.phase="CLASSIFICATION";req.status="Cần phân loại";req.queue="ACTIONABLE";io06CurrentLines().forEach(l=>{l.classification={sellable:0,quarantine:0,damaged:0,expired:0};});stateByScreen["SCR-035"]="RECEIVED_PENDING_CLASSIFICATION";return navigate("SCR-035");}
  if(k==="open-classification"){io06ClassificationOpen=false;io06ClassificationDraft=null;stateByScreen["SCR-033"]="READY";return navigate("SCR-033");}
  if(k==="cancel-classification-item"){io06ClassificationOpen=false;io06ClassificationDraft=null;return renderAppScreen();}
  if(k==="close-classification-item"){const line=io06ActiveLine();const draft=io06ClassificationDraftFor(line);if(!line||!io06ClassValid(line,stateByScreen["SCR-033"],draft))return;line.classification={sellable:Number(draft.sellable||0),quarantine:Number(draft.quarantine||0),damaged:Number(draft.damaged||0),expired:Number(draft.expired||0)};io06ClassificationOpen=false;io06ClassificationDraft=null;return renderAppScreen();}
  if(k==="confirm-classification"){if(!io06AllClassValid(stateByScreen["SCR-033"]))return;const req=io06CurrentRequest();req.classified=true;req.closed=true;req.status="Đã phân loại";req.queue="CLOSED";stateByScreen["SCR-035"]="COMPLETED";return navigate("SCR-035");}
  if(k==="result-to-return-queue"){io06QueueFilter="ALL";io06Query="";io06ClassificationOpen=false;io06ClassificationDraft=null;return navigate("SCR-030");}
  if(k==="back-to-return-request"){stateByScreen["SCR-031"]="READY";return navigate("SCR-031");}

},true);


// v1.8.0 — targeted interactions for UIF12 / UIF15. No backend calls are simulated.
document.addEventListener("input",(event)=>{
  if(activeFlowId==="UIF-12"){
    if(event.target.matches("[data-cf12-cutoff]")){cf12Cutoff=event.target.value;return;}
    if(event.target.matches("[data-cf12-control-qty]")){cf12ControlQty=event.target.value;return;}
    if(event.target.matches("[data-cf12-control-value]")){cf12ControlValue=String(event.target.value||"").replace(/[^0-9-]/g,"");return;}
    if(event.target.matches("[data-cf12-reject-reason]")){
      cf12RejectReason=event.target.value;
      const b=document.querySelector('[data-cf12-action="confirm-reject"]'); if(b)b.disabled=!cf12RejectReason.trim();
      return;
    }
  }
  if(activeFlowId==="UIF-15"){
    if(event.target.matches("[data-cf15-from]")){cf15From=event.target.value;return;}
    if(event.target.matches("[data-cf15-to]")){cf15To=event.target.value;return;}
  }
},true);

document.addEventListener("change",(event)=>{
  if(activeFlowId!=="UIF-15")return;
  if(event.target.matches("[data-cf15-warehouse]")){cf15Warehouse=event.target.value;return;}
  if(event.target.matches("[data-cf15-product]")){cf15Product=event.target.value;if(cf15Product!=="ALL")cf15SelectedProduct=cf15Product;return;}
},true);

document.addEventListener("click",(event)=>{
  if(activeFlowId==="UIF-12"){
    const a=event.target.closest("[data-cf12-action]"); if(!a||a.disabled)return;
    event.preventDefault(); event.stopPropagation(); const k=a.dataset.cf12Action;
    if(k==="start"||k==="continue-prepare"){stateByScreen["SCR-067"]="READY";return navigate("SCR-067");}
    if(k==="choose-file"){cf12FileName="ton-kho-dau-ky-2026.xlsx";stateByScreen["SCR-067"]="READY";return renderAppScreen();}
    if(k==="check"){
      const valid=Boolean(cf12FileName&&cf12Cutoff&&cf12ControlQty!==""&&cf12ControlValue!==""&&Number(cf12ControlQty)>=0&&Number(cf12ControlValue)>=0);
      if(!valid){stateByScreen["SCR-067"]="VALIDATION_ERROR";return renderAppScreen();}
      stateByScreen["SCR-068"]="READY";return navigate("SCR-068");
    }
    if(k==="back-file"){stateByScreen["SCR-067"]="READY";return navigate("SCR-067");}
    if(k==="review"){stateByScreen["SCR-069"]="READY";return navigate("SCR-069");}
    if(k==="back-check"){stateByScreen["SCR-068"]="READY";return navigate("SCR-068");}
    if(k==="send-approval"){stateByScreen["SCR-069"]="PENDING_APPROVAL";stateByScreen["SCR-066"]="PENDING_APPROVAL";return navigate("SCR-066");}
    if(k==="fix-rejected"){stateByScreen["SCR-067"]="READY";return navigate("SCR-067");}
    if(k==="open-reject"){cf12RejectOpen=true;cf12RejectReason="";return renderAppScreen();}
    if(k==="close-reject"){cf12RejectOpen=false;cf12RejectReason="";return renderAppScreen();}
    if(k==="confirm-reject"){
      if(!cf12RejectReason.trim())return;
      cf12RejectOpen=false;stateByScreen["SCR-070"]="APPROVAL_ALREADY_DECIDED";stateByScreen["SCR-066"]="REJECTED";return renderAppScreen();
    }
    if(k==="approve"){
      cf12RejectOpen=false;stateByScreen["SCR-071"]="PROCESSING";navigate("SCR-071");
      window.setTimeout(()=>{if(activeFlowId==="UIF-12"&&activeScreenId==="SCR-071"&&stateByScreen["SCR-071"]==="PROCESSING"){stateByScreen["SCR-071"]="COMPLETED";stateByScreen["SCR-066"]="ACTIVE_RECONCILED";render();}},420);
      return;
    }
    if(k==="result-home"){return navigate("SCR-066");}
    if(k==="see-inventory"){
      activeFlowId="UIF-01";activeScreenId="SCR-001";stateByScreen["SCR-001"]="READY";syncReviewUrl();return render();
    }
  }
  if(activeFlowId==="UIF-15"){
    const rt=event.target.closest("[data-cf15-report-type]"); if(rt){event.preventDefault();cf15ReportType=rt.dataset.cf15ReportType;if(cf15ReportType==="STOCK_CARD"&&cf15Product==="ALL"){cf15Product=cf15SelectedProduct;}stateByScreen["SCR-054"]="READY";return renderAppScreen();}
    const dm=event.target.closest("[data-cf15-date-mode]"); if(dm){event.preventDefault();cf15DateMode=dm.dataset.cf15DateMode;stateByScreen["SCR-054"]="READY";return renderAppScreen();}
    const pr=event.target.closest("[data-cf15-product-row]"); if(pr){event.preventDefault();cf15SelectedProduct=pr.dataset.cf15ProductRow;cf15ProductSheetOpen=true;return renderAppScreen();}
    const mv=event.target.closest("[data-cf15-movement]"); if(mv){event.preventDefault();cf15SelectedMovement=mv.dataset.cf15Movement;stateByScreen["SCR-056"]="READY";return navigate("SCR-056");}
    const action=event.target.closest("[data-cf15-action]"); if(!action||action.disabled)return;
    event.preventDefault();event.stopPropagation();const k=action.dataset.cf15Action;
    if(k==="query"){
      if(!cf15From||!cf15To||cfDateKey(cf15From)>cfDateKey(cf15To)||(cf15ReportType==="STOCK_CARD"&&cf15Product==="ALL")){stateByScreen["SCR-054"]="VALIDATION_ERROR";return renderAppScreen();}
      cf15ProductSheetOpen=false;stateByScreen["SCR-055"]="READY";return navigate("SCR-055");
    }
    if(k==="close-product-sheet"){cf15ProductSheetOpen=false;return renderAppScreen();}
    if(k==="product-stock-card"){
      const id=action.dataset.cf15ProductId||cf15SelectedProduct;cf15ReportType="STOCK_CARD";cf15Product=id;cf15SelectedProduct=id;cf15ProductSheetOpen=false;stateByScreen["SCR-055"]="READY";return renderAppScreen();
    }
    if(k==="source"){stateByScreen["SCR-057"]="READY";return navigate("SCR-057");}
    if(k==="export"||k==="export-source"){
      cf15ExportFrom=k==="export-source"?"SOURCE":"REPORT";cf15FinanceIncluded=stateByScreen[activeScreenId]!=="FINANCIAL_RESTRICTED";stateByScreen["SCR-058"]="READY";return navigate("SCR-058");
    }
    if(k==="confirm-export"){
      stateByScreen["SCR-059"]="PROCESSING";navigate("SCR-059");window.setTimeout(()=>{if(activeFlowId==="UIF-15"&&activeScreenId==="SCR-059"&&stateByScreen["SCR-059"]==="PROCESSING"){stateByScreen["SCR-059"]="COMPLETED";render();}},320);return;
    }
    if(k==="done-export"){stateByScreen[cf15ExportFrom==="SOURCE"?"SCR-057":"SCR-055"]="READY";return navigate(cf15ExportFrom==="SOURCE"?"SCR-057":"SCR-055");}
  }
  const customBack=event.target.closest('[data-action="cf15-back-export"]');
  if(customBack&&activeFlowId==="UIF-15"){event.preventDefault();event.stopPropagation();return navigate(cf15ExportFrom==="SOURCE"?"SCR-057":"SCR-055");}
},true);

const flowSelectorEl=document.getElementById("flow-selector");
flowSelectorEl?.addEventListener("change",(e)=>{activeFlowId=e.target.value; const f=activeFlow(); activeScreenId=f.screens[0]; syncReviewUrl(); render();});
document.addEventListener("click",(e)=>{
  const next=e.target.closest("[data-generic-next]"); if(next){ const ids=activeFlow()?.screens||[]; const i=ids.indexOf(activeScreenId); if(i>=0&&i<ids.length-1) navigate(ids[i+1]); else showToast("Đã hoàn thành flow demo", "checkCircle"); }
  const act=e.target.closest("[data-generic-action]"); if(act){ showToast(`${act.textContent.trim()} · prototype không gọi backend`, "checkCircle"); }
  const card=e.target.closest(".generic-data-card[data-ds-profile='card.interactive']"); if(card&&!inspectEnabled){ const ids=activeFlow()?.screens||[]; const i=ids.indexOf(activeScreenId); if(i>=0&&i<ids.length-1) navigate(ids[i+1]); }
});
render();

function fitReviewDeviceToViewport() {
  const device = document.getElementById("device-preview");
  const canvas = document.querySelector(".stage-canvas");
  if (!device || !canvas) return;
  if (window.innerWidth <= 840 || device.classList.contains("is-wide")) {
    device.style.setProperty("--vet45-review-scale", "1");
    return;
  }
  const canvasRect = canvas.getBoundingClientRect();
  const canvasStyle = getComputedStyle(canvas);
  const padTop = parseFloat(canvasStyle.paddingTop) || 0;
  const padLeft = parseFloat(canvasStyle.paddingLeft) || 0;
  const padRight = parseFloat(canvasStyle.paddingRight) || 0;
  const deviceTop = canvasRect.top + padTop;
  const availableHeight = Math.max(360, window.innerHeight - deviceTop - 8);
  const availableWidth = Math.max(240, canvas.clientWidth - padLeft - padRight);
  const scale = Math.min(1, availableHeight / 890, availableWidth / 418);
  device.style.setProperty("--vet45-review-scale", String(scale));
}
window.addEventListener("resize", fitReviewDeviceToViewport);
requestAnimationFrame(fitReviewDeviceToViewport);

window.__VET45_PROTOTYPE__ = {
  productKind: "mobile_app",
  version: "3.6.0",
  defaultViewport: { width: 402, height: 874 },
  offline: true,
  uiFlows: flowCatalog.map((f) => f.id),
  screens: screens.map((s) => s.id),
  roles: [...new Set(screens.flatMap((s) => s.actors || []))],
  states: [...new Set(screens.flatMap((s) => s.states || []))],
  scenarios: ["canonical", "document-receipt", "quick-receipt", "source-waiting", "stale-recovery", "partial-handover", "permission-denied"],
  devicePresets: [{ id: "iphone-402", kind: "mobile", width: 402, height: 874 }],
  inspect: { enabled: true, selectable: true }
};
if (initialParams.get("inspect") === "1") toggleInspect(true);
