/* BJ-03 — Xác lập giá trị nhập ban đầu (UIF-03). Màn: SCR-014, SCR-015, SCR-019 (SCR-016 / 017 / 018 là đường cũ, có alias).
 *
 * Thiết kế lại (T7-P BJ-03, 2026-10-22, v5.9.0): một khối dựng cho 014 / 015 / 019. 015 là bảng sản phẩm có ô tick
 * (web, K7; iPhone là danh sách thẻ) + sheet "Thêm căn cứ giá" (nhập nhanh, chỉ VND) + sheet "Cách tính" + sheet xác nhận (thay SCR-017).
 * Sửa BJ-03: sửa thẳng file này. Helper `VAL_UI_461` ở shared-valuation.js chỉ còn BJ-13 dùng (money / signed / pct).
 * Helper val03* bị gán trong khối chuẩn hoá (khai báo `let` một lần ở đầu file).
 * Dùng từ khuôn: k1Loading, k1Denied, k1Empty, k1Locked, k1ExitAttr (K1); k3Unknown (K3); k4Result, k4Footer (K4);
 * k7Table (cột chọn `select`), k7Split, k7FilterChips (K7); dsSegmented.
 *
 * Fixture chung chặng 2 (v5.8.0): phiếu PN-260816-04 khớp BJ-02 — Nobivac DHPPi SP-000184 (một lô DH2507) + Oxytetracycline LA SP-000147.
 * `val03OpenForReceipt(ref)` mở xác lập giá trị cho phiếu vừa nhận ở BJ-02 (đọc `bj02LastCommitted`).
 */
// UIF-03 / BJ-03 v1.4.4 — Inventory Valuation foundation correction.
// Preview is non-mutating; final commit is owned by BC-IV-01/API-C-20.
// ============================================================================
const val03Receipts = [
  {id:"VAL03-R1",receipt:"PN-260816-04",entryType:"DOCUMENT",supplier:"Minh Dũng",warehouse:"Kho chính",receivedAt:"16/08/2026",sourceVersion:3,ageDays:19,waitingOwner:"",groups:[
    {id:"VAL03-G1",name:"Nobivac DHPPi",code:"SP-000184",uom:"hộp",tracking:"LOT",officialCostStatus:"EXISTS",sources:[
      {id:"PO",label:"Đơn mua PO-2608-041",version:"v3",unitPrice:83000,currency:"VND",fxRate:1,fxLabel:"VND",unitLineDiscount:1000,unitDocDiscount:500,unitKnownCost:200,unitNonDeductibleVat:0,provenance:["Giá mua · PO-2608-041 v3","CK dòng · PO-2608-041 v3","CK phiếu · phân bổ theo giá trị dòng","Chi phí đã có · CTCP-2608-12 v1"]},
      {id:"SUP",label:"Xác nhận nhà cung cấp 02/09",version:"v1",unitPrice:83000,currency:"VND",fxRate:1,fxLabel:"VND",unitLineDiscount:1000,unitDocDiscount:500,unitKnownCost:200,unitNonDeductibleVat:0,provenance:["Giá mua · Xác nhận NCC 02/09 v1","CK dòng · theo PO v3","CK phiếu · phân bổ theo giá trị dòng","Chi phí đã có · CTCP-2608-12 v1"]}
    ],selectedSource:"PO",reason:"",slices:[
      {id:"VAL03-S1",scopeKey:"ROL-401|LOT-DH2507|SELLABLE",scopeVersion:1,lineId:"ROL-401",lot:"DH2507",physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:121,selected:false,selectedQty:121,partialOpen:false,availabilityDelta:121,availabilityNote:"Sẽ tăng khả dụng"}
    ]},
    {id:"VAL03-G2",name:"Oxytetracycline LA",code:"SP-000147",uom:"chai",tracking:"NONE",officialCostStatus:"NONE",sources:[
      {id:"PO",label:"Đơn mua PO-2608-041",version:"v3",unitPrice:120000,currency:"VND",fxRate:1,fxLabel:"VND",unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:0,provenance:["Giá mua · PO-2608-041 v3"]},
      {id:"SUP",label:"Xác nhận nhà cung cấp 02/09",version:"v2",unitPrice:121000,currency:"VND",fxRate:1,fxLabel:"VND",unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:0,provenance:["Giá mua · Xác nhận NCC 02/09 v2"]}
    ],selectedSource:"",reason:"",slices:[{id:"VAL03-S4",scopeKey:"ROL-404|NOLOT|SELLABLE",scopeVersion:1,lineId:"ROL-404",lot:null,physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:24,selected:false,selectedQty:24,partialOpen:false,availabilityDelta:24,availabilityNote:"Sẽ tăng khả dụng"}]}
  ]},
  {id:"VAL03-R2",receipt:"PN-260816-02",entryType:"QUICK",supplier:"An Việt",warehouse:"Kho chính",receivedAt:"16/08/2026",sourceVersion:1,ageDays:19,waitingOwner:"Chờ chứng từ mua",groups:[
    {id:"VAL03-G3",name:"Găng tay khám Nitrile",code:"SP-00310",uom:"hộp",tracking:"NONE",officialCostStatus:"EXISTS",officialCostVnd:135000,sources:[],selectedSource:"",reason:"",slices:[{id:"VAL03-S5",scopeKey:"ROL-405|NOLOT|SELLABLE",scopeVersion:1,lineId:"ROL-405",lot:null,physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:50,selected:false,selectedQty:50,partialOpen:false,availabilityDelta:50,availabilityNote:"Sẽ tăng khả dụng"}]}
  ]},
  {id:"VAL03-R3",receipt:"PN-260901-03",entryType:"QUICK",supplier:"Phương Nam",warehouse:"Kho chính",receivedAt:"01/09/2026",sourceVersion:2,ageDays:3,waitingOwner:"",groups:[
    {id:"VAL03-G4",name:"Vaccine Canine X",code:"SP-000421",uom:"lọ",tracking:"LOT",officialCostStatus:"NONE",sources:[
      {id:"SUP",label:"Xác nhận nhà cung cấp 01/09",version:"v2",unitPrice:4.1,currency:"USD",fxRate:24450,fxLabel:"FX authoritative",unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:0,provenance:["Giá mua · Xác nhận NCC 01/09","FX authoritative · provenance kỹ thuật"]}
    ],selectedSource:"SUP",reason:"",slices:[{id:"VAL03-S6",scopeKey:"ROL-406|LOT-CX2609|SELLABLE",scopeVersion:1,lineId:"ROL-406",lot:"CX2609",physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:10,selected:false,selectedQty:10,partialOpen:false,availabilityDelta:10,availabilityNote:"Sẽ tăng khả dụng"}]}
  ]},
  {id:"VAL03-R4",receipt:"PN-260902-07",entryType:"DOCUMENT",supplier:"VietVet",warehouse:"Kho chính",receivedAt:"02/09/2026",sourceVersion:1,ageDays:2,waitingOwner:"",groups:[
    {id:"VAL03-G5",name:"Dung dịch sát khuẩn",code:"SP-00510",uom:"chai",tracking:"NONE",officialCostStatus:"EXISTS",sources:[{id:"PO",label:"Đơn mua PO-2609-008",version:"v1",unitPrice:46000,currency:"VND",fxRate:1,fxLabel:"VND",unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:0,provenance:["Giá mua · PO-2609-008 v1"]}],selectedSource:"PO",reason:"",slices:[{id:"VAL03-S7",scopeKey:"ROL-407|NOLOT|SELLABLE",scopeVersion:1,lineId:"ROL-407",lot:null,physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:12,selected:false,selectedQty:12,partialOpen:false,availabilityDelta:12,availabilityNote:"Sẽ tăng khả dụng"}]},
    {id:"VAL03-G6",name:"Bơm tiêm 5ml",code:"SP-00511",uom:"hộp",tracking:"NONE",officialCostStatus:"EXISTS",sources:[],selectedSource:"",reason:"",slices:[{id:"VAL03-S8",scopeKey:"ROL-408|NOLOT|SELLABLE",scopeVersion:1,lineId:"ROL-408",lot:null,physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:8,selected:false,selectedQty:8,partialOpen:false,availabilityDelta:8,availabilityNote:"Sẽ tăng khả dụng"}]}
  ]}
];
let val03SelectedReceiptId="VAL03-R1", val03Query="", val03Filter="ALL", val03ReviewSourceVersion=null, val03LastResult=null, val03LastSourceChange=null, val03OperationSeq=1;
function val03Current(){return val03Receipts.find(r=>r.id===val03SelectedReceiptId)||val03Receipts[0];}
function val03PendingSlices(r=val03Current()){return r.groups.flatMap(g=>g.slices.map(s=>({group:g,slice:s}))).filter(x=>x.slice.pendingQty>0);}
// Helper BJ-03 — một định nghĩa duy nhất, gán trong khối chuẩn hoá bên dưới (cần biến cục bộ của khối).
let val03EvidenceState, val03Source, val03GroupSelectedQty, val03Calc, val03ActionablePairs, val03WaitingPairs, val03ReceiptState, val03HasSelectedConflict, val03ScopeReady, val03SourceDetail, val03SourcePriceText, val03TotalValue, val03ApplySourceUpdate, val03Commit, val03UnitActual, val03GroupAmount;
function val03SelectedSlices(r=val03Current()){return val03PendingSlices(r).filter(x=>x.slice.selected&&Number(x.slice.selectedQty)>0);}
function val03GroupReady(group){if(val03GroupSelectedQty(group)<=0)return true;const st=val03EvidenceState(group);if(st==="MISSING")return false;if(st==="CONFLICT"&&(!group.selectedSource||!group.reason.trim()))return false;return Boolean(val03Source(group));}
function val03FmtMoney(n){return t7FmtMoney(Number(n)||0);}
function val03FilterMatch(r){const st=val03ReceiptState(r);return val03Filter==="ALL"||(val03Filter==="READY"?st==="READY":st!=="READY");}
function val03ReceiptBadge(r){const st=val03ReceiptState(r);return st==="WAITING"?["Chờ căn cứ","neutral"]:st==="CONFLICT"?["Cần đối chiếu","warning"]:["Có thể xử lý","success"];}
function val03SelectedAvailability(g,s){const q=Math.min(Number(s.selectedQty)||0,s.pendingQty);const ratio=s.pendingQty?Math.min(1,q/s.pendingQty):0;return Math.round((s.availabilityDelta||0)*ratio*1000)/1000;}
function val03ResultSnapshot(){return val03LastResult||{receipt:val03Current().receipt,supplier:val03Current().supplier,groups:[],totalValue:0};}


// ============================================================================

/* chuẩn hoá fixture + helper thắng */
(()=>{
const fmt=(n)=>`${Math.round(Number(n)||0).toLocaleString('vi-VN')} đ`;
const stableHash=(parts)=>`sha256-fixture-${String(parts).replace(/[^a-zA-Z0-9]+/g,'-').toLowerCase()}`;

function basisCandidate({id,label,version,unitPrice,currency='VND',fxRate=1,fxLabel='VND',unitLineDiscount=0,unitDocDiscount=0,unitKnownCost=0,unitNonDeductibleVat=0,components=[],evidenceRefs=[]}){
  const unitActual=unitPrice*fxRate-unitLineDiscount-unitDocDiscount+unitKnownCost+unitNonDeductibleVat;
  return {id,label,version:`v${version}`,basisVersion:version,basisHash:stableHash(`${id}|${version}|${unitActual}|${currency}|${fxRate}|${components.map(x=>`${x.type}:${x.source}:${x.version}:${x.amount||''}`).join('|')}`),authoritativeValueHash:stableHash(`${currency}|${fxRate}|${unitActual}`),unitPrice,currency,fxRate,fxLabel,unitLineDiscount,unitDocDiscount,unitKnownCost,unitNonDeductibleVat,components,evidenceRefs,provenance:components.map(x=>`${x.label} · ${x.source} ${x.version||''}`.trim())};
}

// Recast legacy source fixtures as complete DirectCostBasis candidates.
for(const [ri,r] of val03Receipts.entries()){
  for(const [gi,g] of r.groups.entries()){
    g.receiptItemRef=g.receiptItemRef||`${r.id}-ITEM-${gi+1}`;
    g.valuationBasisKey=g.valuationBasisKey||`VB-${g.id}`;
    g.baseUom=g.baseUom||g.uom;
    g.conversionToBase=Number(g.conversionToBase||1);
    g.conversionVersion=g.conversionVersion||`CONV-${g.code}-v1`;
    g.basisDisplayLabel=g.basisDisplayLabel||`Dòng nguồn ${gi+1}`;
    for(const s of g.slices){
      s.originalQty=Number(s.originalQty??s.pendingQty);
      s.confirmedQty=Number(s.confirmedQty||0);
      s.confirmedValue=Number(s.confirmedValue||0);
    }
  }
}
const g1=val03Receipts[0].groups[0];
g1.baseUom='lọ'; g1.conversionToBase=10; g1.conversionVersion='CONV-SP000184-v2';
g1.sources=[basisCandidate({id:'BASIS-G1-A',label:'Đơn mua PO-2608-041 (v3)',version:4,unitPrice:83000,unitLineDiscount:1000,unitDocDiscount:500,unitKnownCost:200,components:[
  {type:'PURCHASE_PRICE',label:'Giá mua',source:'PO-2608-041',version:'v3',amount:83000},
  {type:'LINE_DISCOUNT',label:'Chiết khấu dòng',source:'PO-2608-041',version:'v3',amount:-1000},
  {type:'DOCUMENT_DISCOUNT',label:'Chiết khấu phiếu đã phân bổ',source:'PO-2608-041',version:'ALLOC-v2',amount:-500},
  {type:'KNOWN_PURCHASE_COST',label:'Chi phí mua đã có',source:'CTCP-2608-12',version:'v1',amount:200},
  {type:'SUPPLIER_CONFIRMATION',label:'Bằng chứng bổ sung',source:'Xác nhận NCC 02/09',version:'v1'}
],evidenceRefs:['PO-2608-041 v3','Xác nhận NCC 02/09 v1']})];
g1.selectedSource='BASIS-G1-A';

const g2=val03Receipts[0].groups[1];
g2.sources=[
  basisCandidate({id:'BASIS-G2-PO',label:'Đơn mua PO-2608-041',version:3,unitPrice:120000,components:[{type:'PURCHASE_PRICE',label:'Giá mua',source:'PO-2608-041',version:'v3',amount:120000}]}),
  basisCandidate({id:'BASIS-G2-SUP',label:'Xác nhận NCC 02/09',version:2,unitPrice:121000,components:[{type:'PURCHASE_PRICE',label:'Giá mua',source:'Xác nhận NCC 02/09',version:'v2',amount:121000}]})
];
g2.selectedSource='';

const g4=val03Receipts[2].groups[0];
g4.sources=[basisCandidate({id:'BASIS-G4-A',label:'Xác nhận NCC 01/09',version:2,unitPrice:4.1,currency:'USD',fxRate:24450,fxLabel:'Tỷ giá kế toán 24.450 VND/USD',components:[{type:'PURCHASE_PRICE',label:'Giá mua',source:'Xác nhận NCC 01/09',version:'v2',amount:4.1},{type:'FX',label:'Tỷ giá',source:'Kế toán',version:'FX-v7',amount:24450}]})];
g4.selectedSource='BASIS-G4-A';
const g5=val03Receipts[3].groups[0];
g5.sources=[basisCandidate({id:'BASIS-G5-A',label:'Đơn mua PO-2609-008',version:1,unitPrice:46000,components:[{type:'PURCHASE_PRICE',label:'Giá mua',source:'PO-2609-008',version:'v1',amount:46000}]})];
g5.selectedSource='BASIS-G5-A';

let reviewTokens=null;
function chosenBasis(g){return g.sources.find(x=>x.id===g.selectedSource)||null;}
function basisState(g){
  if(!g.sources.length) return 'MISSING';
  const valueHashes=new Set(g.sources.map(x=>x.authoritativeValueHash));
  return valueHashes.size>1?'CONFLICT':'READY';
}
function ensureSingleBasis(g){if(basisState(g)==='READY'&&g.sources.length&&!g.selectedSource) g.selectedSource=g.sources[0].id;}
function unitActual(g){const b=chosenBasis(g); if(!b) return null; return b.unitPrice*b.fxRate-(b.unitLineDiscount||0)-(b.unitDocDiscount||0)+(b.unitKnownCost||0)+(b.unitNonDeductibleVat||0);}
function normalizedBaseCost(g){const u=unitActual(g); return u==null?null:u/Math.max(1,Number(g.conversionToBase)||1);}
function selectedQty(g){return g.slices.filter(s=>s.selected&&s.pendingQty>0).reduce((n,s)=>n+Math.min(Number(s.selectedQty)||0,s.pendingQty),0);}
function confirmationAmount(g,s,q){
  const u=unitActual(g); if(u==null||q<=0) return 0;
  const original=Number(s.originalQty||s.pendingQty+s.confirmedQty||q);
  const fullScopeValue=Number(s.scopeAllocatedValue ?? Math.round(u*original));
  const newCumQty=Math.min(original,Number(s.confirmedQty||0)+q);
  const cumulativeTarget=Math.round(fullScopeValue*(newCumQty/original));
  return cumulativeTarget-Number(s.confirmedValue||0);
}
function calc(g){
  ensureSingleBasis(g);
  const b=chosenBasis(g),qty=selectedQty(g); if(!b||qty<=0) return null;
  let value=0;
  for(const s of g.slices.filter(x=>x.selected&&x.pendingQty>0)){
    const q=Math.min(Number(s.selectedQty)||0,s.pendingQty); value+=confirmationAmount(g,s,q);
  }
  const actual=unitActual(g),base=normalizedBaseCost(g);
  return {qty,value,unitActual:actual,normalizedBaseCost:base,baseVnd:b.unitPrice*b.fxRate,src:b};
}
function currentTokenMap(r=val03Current()){
  const out={};
  for(const g of r.groups.filter(x=>selectedQty(x)>0)){
    ensureSingleBasis(g); const b=chosenBasis(g); if(!b) continue;
    out[g.id]={basisKey:g.valuationBasisKey,basisVersion:b.basisVersion,basisHash:b.basisHash,scopes:g.slices.filter(s=>s.selected&&s.pendingQty>0).map(s=>({id:s.id,scopeVersion:s.scopeVersion}))};
  }
  return out;
}
function duplicateBasisMeta(r,g){
  const dup=r.groups.filter(x=>x.code===g.code&&x.uom===g.uom&&x.slices.some(s=>s.pendingQty>0));
  return dup.length>1?`${g.basisDisplayLabel} · ${g.receiptItemRef}`:'';
}
function bootstrapConflict(r=val03Current()){
  const byProduct=new Map();
  for(const g of r.groups.filter(x=>selectedQty(x)>0&&x.officialCostStatus==='NONE')){
    const c=calc(g); if(!c) continue; const key=g.code; const arr=byProduct.get(key)||[]; arr.push(Math.round(c.normalizedBaseCost*1e6)/1e6); byProduct.set(key,arr);
  }
  return [...byProduct.values()].some(a=>new Set(a).size>1);
}

val03EvidenceState=basisState;
val03UnitActual=unitActual;
val03GroupAmount=function(g){ensureSingleBasis(g);return g.slices.filter(s=>s.pendingQty>0).reduce((n,s)=>n+confirmationAmount(g,s,s.pendingQty),0);};
val03Source=chosenBasis;
val03GroupSelectedQty=selectedQty;
val03Calc=calc;
val03SourceDetail=function(g){const b=chosenBasis(g);return b?b.label:'Chưa chọn';};
val03ScopeReady=function(r=val03Current()){
  const sel=val03SelectedSlices(r); if(!sel.length||bootstrapConflict(r)) return false;
  return r.groups.every(g=>{
    if(selectedQty(g)<=0) return true; const st=basisState(g); if(st==='MISSING') return false; if(st==='CONFLICT'&&(!g.selectedSource||!g.reason.trim())) return false; return !!chosenBasis(g);
  });
};
val03HasSelectedConflict=function(r=val03Current()){return r.groups.some(g=>selectedQty(g)>0&&basisState(g)==='CONFLICT'&&(!g.selectedSource||!g.reason.trim()));};
val03TotalValue=function(r=val03Current()){return r.groups.reduce((n,g)=>n+(calc(g)?.value||0),0);};
val03ReceiptState=function(r){const a=val03PendingSlices(r).filter(x=>basisState(x.group)!=='MISSING');if(!a.length)return 'WAITING';return a.some(x=>basisState(x.group)==='CONFLICT')?'CONFLICT':'READY';};
val03ActionablePairs=function(r=val03Current()){return val03PendingSlices(r).filter(x=>basisState(x.group)!=='MISSING');};
val03WaitingPairs=function(r=val03Current()){return val03PendingSlices(r).filter(x=>basisState(x.group)==='MISSING');};
val03SourcePriceText=function(src,uom){return src.currency==='VND'?`${fmt(src.unitPrice)}/${uom}`:`${Number(src.unitPrice).toLocaleString('vi-VN')} ${src.currency}/${uom}`;};

val03ApplySourceUpdate=function(groupId,newPrice){
  const r=val03Current(),g=r.groups.find(x=>x.id===groupId); if(!g||!g.sources.length)return false;
  const b=g.sources[0],before=val03SourcePriceText(b,g.uom),selectedAffected=selectedQty(g)>0;
  b.unitPrice=newPrice; b.basisVersion=Number(b.basisVersion||1)+1; b.version=`v${b.basisVersion}`;
  const actual=b.unitPrice*b.fxRate-(b.unitLineDiscount||0)-(b.unitDocDiscount||0)+(b.unitKnownCost||0)+(b.unitNonDeductibleVat||0);
  b.basisHash=stableHash(`${b.id}|${b.basisVersion}|${actual}|${Date.now()}`); b.authoritativeValueHash=stableHash(`${b.currency}|${b.fxRate}|${actual}`);
  val03LastSourceChange={name:g.name,source:b.label,from:before,to:val03SourcePriceText(b,g.uom)};
  if(basisState(g)==='CONFLICT'){g.selectedSource='';g.reason='';}
  // Preserve legacy sourceVersion only as a compatibility trigger when the selected reviewed basis changed.
  if(selectedAffected) r.sourceVersion+=1;
  return true;
};


})();

screenAliases["UIF-03"] = Object.assign(screenAliases["UIF-03"] || {}, {
  "SCR-016": "SCR-015",
  "SCR-017": "SCR-015", // Rà soát → sheet xác nhận trong SCR-015 (v5.9.0)
  "SCR-018": ["UIF-13", "SCR-085"],
});
{ const a = screenAliases[activeFlowId]?.[activeScreenId]; if (Array.isArray(a)) { activeFlowId = a[0]; activeScreenId = a[1]; } else if (a) activeScreenId = a; }

/* --- SCR-014 / 015 / 019 — một khối dựng (v5.9.0) --- */
// Trạng thái giao diện của 015 / 019 (sheet đang mở, nháp căn cứ). `val03ResetUi` đưa về mặc định khi mở phiếu khác.
const val03UiDefaults = () => ({ basisGroup: null, basisDraft: null, basisShowErrors: false, confirmOpen: false, breakdownGroup: null, resultOpen: false, demo: null });
let val03Ui = val03UiDefaults();
function val03ResetUi() { val03Ui = val03UiDefaults(); }
// Kết quả mẫu cho ca vào thẳng SCR-019 (COMPLETED) khi chưa ghi gì: dựng từ R1 G1, còn Oxytetracycline LA chờ đối chiếu.
const VAL03_SAMPLE_RESULT = {
  operationId: "VAL-260925-001", receipt: "PN-260816-04", supplier: "Minh Dũng", businessDate: "16/08/2026", committedAt: "10:05 · 16/09/2026", remaining: 1,
  groups: [{ name: "Nobivac DHPPi", code: "SP-000184", uom: "hộp", qty: 121, value: 9885700, unitInitial: 81700, source: "Đơn mua PO-2608-041 (v3)", slices: [{ scopeKey: "ROL-401|LOT-DH2507|SELLABLE", lot: "DH2507", state: "Đủ điều kiện bán", qty: 121, value: 9885700 }] }],
  totalValue: 9885700, totalQty: 121, dirtyScope: ["Nobivac DHPPi · kỳ 08/2026"],
};
(()=>{
  const TITLE_LIST = "Hàng chờ xác lập giá trị", TITLE_FORM = "Xác lập giá trị nhập ban đầu", TITLE_RESULT = "Kết quả xác lập giá trị";
  const COMMITTED_AT = "10:05 · 16/09/2026", ACTOR = "Chủ cửa hàng";
  const NO_PICK = "Chọn ít nhất một sản phẩm đủ căn cứ";
  const money = val03FmtMoney;
  const unitText = (n, uom) => `${money(n)}/${uom}`;
  const qtyOf = (g) => (g.slices || []).filter((s) => Number(s.pendingQty || 0) > 0).reduce((n, s) => n + Number(s.pendingQty || 0), 0);
  const pendingGroups = (r) => (r.groups || []).filter((g) => qtyOf(g) > 0);
  const isQuick = (r) => r.entryType === "QUICK";
  const entryLabel = (r) => (isQuick(r) ? "Nhập nhanh" : "Theo chứng từ");
  const isOwner = () => currentActor() !== "staff";
  const taxPolicy = () => window.__VET45_TAX_TREATMENT_POLICY__ || { recoverableRate: 0, version: "UNSET" };
  const fxFor = (currency) => window.__VET45_FX_SOURCE_FIXTURE__?.[currency] || null;
  const shell = (opts) => appShell({ ...opts, extraClass: "k7-wide" });
  const muted = '<span class="k7-muted">—</span>';
  // Danh sách "nhãn — giá trị" cho khối Tóm tắt và sheet xác nhận (giá trị căn phải, tự xuống dòng khi hẹp).
  const facts = (rows) => `<dl class="bj03-facts" data-composed-from="DS v2 / Key-value Row">${rows.map(([l, v, strong]) => `<div class="${strong ? "is-strong" : ""}"><dt>${esc(l)}</dt><dd>${esc(v)}</dd></div>`).join("")}</dl>`;
  const srcUnit = (b) => b.unitPrice * b.fxRate - (b.unitLineDiscount || 0) - (b.unitDocDiscount || 0) + (b.unitKnownCost || 0) + (b.unitNonDeductibleVat || 0);
  // EVIDENCE_MISSING: dựng mọi dòng đủ căn cứ thành "chờ căn cứ" mà không sửa fixture.
  const forcedMissing = () => stateByScreen["SCR-015"] === "EVIDENCE_MISSING";
  const groupState = (r, g) => {
    const st = val03EvidenceState(g) === "READY" && forcedMissing() ? "MISSING" : val03EvidenceState(g);
    if (st === "READY") return "READY";
    if (st === "CONFLICT") return isQuick(r) ? "DIRECT_CONFLICT" : "COMMERCIAL_CONFLICT";
    return isQuick(r) ? "DIRECT_MISSING" : "COMMERCIAL_MISSING";
  };
  const selectGroup = (g, on) => (g.slices || []).filter((s) => Number(s.pendingQty || 0) > 0).forEach((s) => { s.selected = on; s.selectedQty = s.pendingQty; s.partialOpen = false; });
  const selectedGroups = (r = val03Current()) => pendingGroups(r).filter((g) => groupState(r, g) === "READY" && (g.slices || []).some((s) => s.selected && Number(s.pendingQty || 0) > 0));
  // Dòng đủ căn cứ được tick sẵn một lần khi mở phiếu (cũng khi vào thẳng SCR-015); bỏ tick rồi thì giữ.
  const tickReady = (r) => { if (r.ticked) return; r.ticked = true; pendingGroups(r).forEach((g) => selectGroup(g, val03EvidenceState(g) === "READY")); };
  const lotLines = (g) => (g.tracking === "LOT" ? (g.slices || []).filter((s) => s.pendingQty > 0).map((s) => `Lô ${s.lot} · ${s.pendingQty} ${g.uom}${s.physicalState === "SELLABLE" ? "" : ` · ${s.stateLabel}`}`) : []);
  const selectedTotal = (r) => selectedGroups(r).reduce((n, g) => n + Number(val03Calc(g)?.value || 0), 0);
  const denied = (title, back) => shell({ title, body: k1Denied({ what: "xác lập giá trị", next: "Chỉ chủ cửa hàng xem và ghi giá nhập.", exitAttr: k1ExitAttr("SCR-014") }), centered: true, back });
  const blocked = (state) => !isOwner() || state === "PERMISSION_DENIED" || state === "FINANCIAL_MASKED";
  // Phiếu vừa nhận ở BJ-02 đứng đầu danh sách.
  const justReceived = (r) => typeof bj02LastCommitted !== "undefined" && bj02LastCommitted?.ref === r.receipt;

  /* ---------- Sheet (hộp thoại giữa màn trên web) ---------- */
  function sheet({ title, intro = "", body, actions, extraClass = "", single = false }) {
    return `<div class="sheet-backdrop" data-bj03-backdrop><section class="bottom-sheet bj03-sheet ${extraClass}" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}" data-ds-component="VBottomSheet" data-figma-node="4695:6353"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(title)}</h3></div><div class="sheet-divider"></div><div class="sheet-content">${intro ? `<p class="bj03-sheet-intro">${esc(intro)}</p>` : ""}${body}</div><div class="sheet-actions${single ? " bj03-sheet-actions--single" : ""}">${actions}</div></section></div>`;
  }
  const secondaryBtn = (label, attr) => `<button class="button button--secondary" type="button" ${attr} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.medium">${esc(label)}</button>`;
  const primaryBtn = (label, attr, disabled = false) => `<button class="button button--primary" type="button" ${attr}${disabled ? " disabled" : ""} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.primary" data-ds-prop-size="VButtonSize.medium">${esc(label)}</button>`;
  const closeAttr = "data-bj03-sheet-close";
  function closeSheets() {
    const wasError = stateByScreen["SCR-015"] === "VALIDATION_ERROR";
    val03ResetUi();
    if (wasError) { stateByScreen["SCR-015"] = "READY"; syncReviewUrl(); }
  }

  /* ---------- SCR-014 Hàng chờ xác lập giá trị ---------- */
  const receiptBadge = (r) => { const [label, tone] = val03ReceiptBadge(r); return ds24Badge(label, tone === "warning" ? "Warning" : tone === "success" ? "Success" : "Neutral"); };
  function receiptMobileRow(row) {
    const trailing = `<span class="bj03-trail"><small>${row.count} sản phẩm chờ</small>${row.badge}</span>`;
    return ds24ListRow({ title: row.receipt, subtitle: `${row.supplier} · ${row.entry}`, trailing, leading: null, attrs: `data-bj03-receipt="${row.id}"`, type: "Navigation", density: "Compact" });
  }
  function render014BJ03(state) {
    if (activeFlowId !== "UIF-03") return renderGeneric(screens.find((s) => s.id === "SCR-014"), state);
    const title = TITLE_LIST;
    if (blocked(state)) return denied(title, false);
    if (state === "LOADING") return shell({ title, body: k1Loading({ blocks: ["search", "row", "row", "row"] }), back: false });
    const all = val03Receipts.filter((r) => pendingGroups(r).length);
    if (state === "EMPTY" || !all.length) return shell({ title, body: k1Empty({ title: "Không còn hàng chờ giá trị", description: "Các phiếu nhận đã được xác lập giá trị." }), back: false });
    const countBy = (f) => all.filter(f).length;
    const search = ds24Search(val03Query, "data-bj03-search", "Phiếu nhận hoặc nhà cung cấp");
    const chips = k7FilterChips({ items: [["ALL", "Tất cả", all.length], ["READY", "Có thể xác lập", countBy((r) => val03ReceiptState(r) === "READY")], ["ISSUE", "Cần xử lý", countBy((r) => val03ReceiptState(r) !== "READY")]], selected: val03Filter, attrName: "data-bj03-filter" });
    const emptyFiltered = { title: "Không có công việc phù hợp", description: "Đổi từ khóa hoặc bộ lọc để xem công việc khác.", actionLabel: "Xem tất cả", actionAttr: "data-bj03-show-all" };
    if (state === "FILTER_EMPTY") return shell({ title, body: `${search}${chips}${k1Empty(emptyFiltered)}`, back: false });
    const rows = all
      .filter((r) => ioMatchesSearch(val03Query, `${r.receipt} ${r.supplier}`))
      .filter(val03FilterMatch)
      .sort((a, b) => Number(justReceived(b)) - Number(justReceived(a)))
      .map((r) => ({ id: r.id, receipt: r.receipt, supplier: r.supplier, entry: entryLabel(r), date: r.receivedAt, count: pendingGroups(r).length, wait: `${r.ageDays} ngày`, badge: receiptBadge(r) }))
      .map((row) => ({ ...row, receiptHtml: `<button class="k7-row-link" type="button">${esc(row.receipt)}</button>` }));
    const columns = [
      { key: "receiptHtml", label: "Phiếu nhận", html: true },
      { key: "supplier", label: "Nhà cung cấp" },
      { key: "entry", label: "Cách nhận" },
      { key: "date", label: "Ngày nhận", mono: true },
      { key: "count", label: "Sản phẩm chờ", align: "end", mono: true },
      { key: "wait", label: "Chờ", align: "end", mono: true },
      { key: "badge", label: "Tình trạng", html: true },
    ];
    const table = k7Table({ columns, rows, mobileRow: receiptMobileRow, caption: "Phiếu nhận chờ xác lập giá trị", rowAttr: (row) => `data-bj03-receipt="${row.id}"`, empty: emptyFiltered });
    return shell({ title, body: `${search}${chips}<div class="bj03-list">${table}</div>`, back: false });
  }

  /* ---------- SCR-015 Xác lập giá trị nhập ban đầu ---------- */
  function rowModel(r, g) {
    const st = groupState(r, g), ready = st === "READY";
    const amount = ready ? val03GroupAmount(g) : 0; // gọi trước để chọn căn cứ duy nhất
    return { g, st, ready, selected: ready && selectedGroups(r).includes(g), qtyText: `${qtyOf(g)} ${g.uom}`, unit: ready ? val03UnitActual(g) : 0, amount, lots: lotLines(g) };
  }
  // Tình trạng của dòng: badge + dòng phụ + liên kết (theo bảng 0.4 mục 8).
  function statusParts(m) {
    const g = m.g, link = (attr, label) => `<button class="k7-row-link bj03-link" type="button" ${attr}>${esc(label)}</button>`;
    if (m.st === "READY") return { badge: ds24Badge("Đủ căn cứ", "Success"), notes: [`Căn cứ: ${val03Source(g)?.label || "—"}`], extra: link(`data-bj03-breakdown="${g.id}"`, "Cách tính") };
    if (m.st === "COMMERCIAL_CONFLICT") return { badge: ds24Badge("Cần đối chiếu", "Warning"), notes: [g.sources.map((b) => `${b.label} ${money(srcUnit(b))}`).join(" · "), "Thống nhất giá ở Mua hàng rồi quay lại."], extra: "" };
    if (m.st === "COMMERCIAL_MISSING") return { badge: ds24Badge("Chờ căn cứ", "Neutral"), notes: ["Chứng từ mua chưa có giá cho dòng này."], extra: "" };
    if (m.st === "DIRECT_MISSING") return { badge: ds24Badge("Chưa có căn cứ", "Neutral"), notes: ["Chưa có chứng từ mua — nhập giá theo hoá đơn hoặc báo giá của nhà cung cấp."], extra: "" };
    return { badge: ds24Badge("Cần kiểm tra", "Warning"), notes: [], extra: "" };
  }
  const productHtml = (m) => `<strong>${esc(m.g.name)}</strong><small>${esc(m.g.code)}</small>${m.lots.map((l) => `<small>${esc(l)}</small>`).join("")}`;
  const unitHtml = (m) => (m.ready ? esc(unitText(m.unit, m.g.uom)) : m.st === "DIRECT_MISSING" ? `<button class="button button--secondary bj03-add" type="button" data-bj03-add-basis="${m.g.id}" data-ds-component="VButton">Nhập giá</button>` : muted);
  const amountHtml = (m) => (m.ready ? esc(money(m.amount)) : muted);
  const statusHtml = (m) => { const p = statusParts(m); return `${p.badge}${p.notes.map((n) => `<small>${esc(n)}</small>`).join("")}${p.extra}`; };
  // iPhone: một thẻ cho mỗi sản phẩm; chạm phần đầu thẻ để tick (ô tick đầu thẻ).
  function productCard(m) {
    const g = m.g;
    const main = `<button type="button" class="bj03-card__main" role="checkbox" aria-checked="${m.selected}" aria-label="${escapeAttribute(g.name)}" data-bj03-select="${g.id}"${m.ready ? "" : ' disabled aria-disabled="true"'}>${k7CheckMark(m.selected, !m.ready)}<span class="bj03-card__copy"><strong>${esc(g.name)}</strong><small>${esc(g.code)} · ${esc(m.qtyText)}</small>${m.lots.map((l) => `<small>${esc(l)}</small>`).join("")}</span></button>`;
    const figures = `<dl class="bj03-card__figures"><div><dt>Đơn giá</dt><dd>${unitHtml(m)}</dd></div><div><dt>Thành tiền</dt><dd>${amountHtml(m)}</dd></div></dl>`;
    return `<div class="bj03-card${m.selected ? " is-selected" : ""}">${main}${figures}<div class="bj03-card__status">${statusHtml(m)}</div></div>`;
  }
  function breakdownRows(g) {
    const s = val03Source(g); if (!s) return "";
    const rows = [["Giá mua", unitText(s.unitPrice * s.fxRate, g.uom)]];
    if (s.unitLineDiscount) rows.push(["Chiết khấu dòng", `− ${unitText(s.unitLineDiscount, g.uom)}`]);
    if (s.unitDocDiscount) rows.push(["Chiết khấu chứng từ", `− ${unitText(s.unitDocDiscount, g.uom)}`]);
    if (s.unitKnownCost) rows.push(["Chi phí mua đã biết", `+ ${unitText(s.unitKnownCost, g.uom)}`]);
    if (s.unitNonDeductibleVat) rows.push(["Thuế/phí tính vào giá trị", `+ ${unitText(s.unitNonDeductibleVat, g.uom)}`]);
    const fx = s.currency !== "VND" ? `<p class="bj03-note">Quy đổi từ ${esc(s.currency)} theo tỷ giá kế toán</p>` : "";
    return `<div class="v430-key-stack bj03-breakdown" data-composed-from="DS v2 / Key-value Row">${rows.map(([l, v]) => ds24KeyValueRow(l, v)).join("")}${ds24KeyValueRow("Đơn giá ghi nhận ban đầu", unitText(val03UnitActual(g), g.uom), true)}</div>${fx}`;
  }
  function breakdownSheet(r) {
    const g = val03Ui.breakdownGroup && r.groups.find((x) => x.id === val03Ui.breakdownGroup);
    if (!g) return "";
    return sheet({ title: "Cách tính", intro: `${g.name} · ${g.code}`, body: breakdownRows(g), actions: primaryBtn("Đóng", closeAttr), single: true });
  }
  function confirmSheet(r) {
    if (!val03Ui.confirmOpen) return "";
    const groups = selectedGroups(r);
    const lines = groups.map((g) => { const c = val03Calc(g); return `<li>${esc(g.name)}: ${c.qty} ${esc(g.uom)} × ${esc(money(c.unitActual))} = <strong>${esc(money(c.value))}</strong></li>`; }).join("");
    const summary = facts([["Phiếu nhận", r.receipt], ["Sản phẩm", `${groups.length} sản phẩm`], ["Tổng giá trị sẽ ghi", money(selectedTotal(r)), true]]);
    return sheet({ title: "Ghi giá trị nhập ban đầu?", body: `${summary}<ul class="bj03-lines">${lines}</ul><p class="bj03-note">Ghi xong không sửa trực tiếp. Chi phí phát sinh sau dùng điều chỉnh giá trị.</p>`, actions: `${secondaryBtn("Quay lại", closeAttr)}${primaryBtn("Xác nhận giá trị", "data-bj03-confirm")}`, extraClass: "bj03-confirm" });
  }

  /* --- Sheet "Thêm căn cứ giá" (nhập nhanh, chỉ VND — JA-05) --- */
  const newDraft = (r) => ({ price: "", taxMode: "INCLUDED", tax: "", source: "", date: r.receivedAt, ref: "", reason: "" });
  function openBasis(g) { val03Ui.basisGroup = g.id; val03Ui.basisDraft = newDraft(val03Current()); val03Ui.basisShowErrors = false; }
  function basisErrors(d) {
    const e = {};
    if (!(Number(d.price) > 0)) e.price = "Nhập đơn giá lớn hơn 0.";
    if (!d.source) e.source = "Nhập căn cứ giá.";
    if (!d.date) e.date = "Nhập ngày căn cứ.";
    else if (!/^\d{2}\/\d{2}\/\d{4}$/.test(d.date)) e.date = "Dùng định dạng dd/mm/yyyy.";
    if (!d.reason) e.reason = "Nêu lý do xác lập trực tiếp.";
    return e;
  }
  // label bọc ô nhập; suffix = hậu tố đơn vị trong ô tiền; error hiện khi bấm "Lưu căn cứ" mà còn thiếu.
  function field({ label, key, value = "", helper = "", required = false, error = "", attrs = "", suffix = "", area = false, aria = "" }) {
    const common = `class="v430-control${area ? " v430-textarea" : ""}${error ? " is-error" : ""}" data-bj03-basis="${key}" ${attrs}${error ? ' aria-invalid="true"' : ""}${aria ? ` aria-label="${escapeAttribute(aria)}"` : ""}`;
    const input = area ? `<textarea rows="3" ${common}>${esc(value)}</textarea>` : `<input ${common} value="${escapeAttribute(value)}"/>`;
    const control = suffix ? `<div class="v430-money">${input}<span>${esc(suffix)}</span></div>` : input;
    return `<label class="v430-field" data-ds-component="${area ? "VTextarea" : suffix ? "VMoneyField" : "VTextField"}"><span>${esc(label)}${required ? " <b>*</b>" : ""}</span>${control}${helper ? `<small>${esc(helper)}</small>` : ""}<small class="v430-field-error" data-bj03-error="${key}"${error ? ' role="alert"' : " hidden"}>${esc(error)}</small></label>`;
  }
  function basisSheet(r) {
    const g = val03Ui.basisGroup && r.groups.find((x) => x.id === val03Ui.basisGroup);
    if (!g) return "";
    const d = val03Ui.basisDraft || newDraft(r), errs = val03Ui.basisShowErrors ? basisErrors(d) : {};
    const hint = g.officialCostVnd ? `Giá vốn hiện tại: ${t7FmtMoney(g.officialCostVnd)}/${g.uom}` : "";
    const taxField = d.taxMode === "EXCLUDED" ? field({ label: "Thuế trên căn cứ", key: "tax", value: d.tax, attrs: 'inputmode="decimal" type="number" min="0" step="1"', suffix: "đ", aria: "Thuế trên căn cứ (đ)" }) : "";
    const body = `<div class="bj03-form">${field({ label: "Đơn giá mua", key: "price", value: d.price, helper: hint, required: true, error: errs.price, attrs: 'inputmode="decimal" type="number" min="0" step="1"', suffix: `đ/${g.uom}`, aria: `Đơn giá mua (đ/${g.uom})` })}`
      + `<div class="v430-field" role="group" aria-label="Cách hiểu giá"><span>Cách hiểu giá <b>*</b></span>${dsSegmented({ items: [["INCLUDED", "Đã gồm thuế"], ["EXCLUDED", "Chưa gồm thuế"]], value: d.taxMode, attr: "data-bj03-tax-mode", label: "Cách hiểu giá" })}</div>`
      + `${taxField}${field({ label: "Căn cứ giá từ đâu?", key: "source", value: d.source, required: true, error: errs.source, attrs: 'placeholder="Ví dụ: Báo giá hoặc xác nhận giá của nhà cung cấp"' })}`
      + `${field({ label: "Ngày căn cứ", key: "date", value: d.date, required: true, error: errs.date, attrs: 'inputmode="numeric" placeholder="dd/mm/yyyy"' })}${field({ label: "Tham chiếu / bằng chứng", key: "ref", value: d.ref, attrs: 'placeholder="Mã báo giá, email, ghi chú..."' })}`
      + `${field({ label: "Lý do xác lập trực tiếp", key: "reason", value: d.reason, required: true, error: errs.reason, area: true, attrs: 'placeholder="Nêu ngắn gọn lý do"' })}</div>`;
    return sheet({ title: "Thêm căn cứ giá", intro: `${g.name} · ${qtyOf(g)} ${g.uom}`, body, actions: `${secondaryBtn("Quay lại", closeAttr)}${primaryBtn("Lưu căn cứ", "data-bj03-save-basis")}`, extraClass: "bj03-basis" });
  }
  function syncBasisDraft() {
    const root = document.querySelector(".bj03-basis"); if (!root || !val03Ui.basisDraft) return;
    const d = val03Ui.basisDraft;
    root.querySelectorAll("[data-bj03-basis]").forEach((el) => { const k = el.dataset.bj03Basis; d[k] = k === "price" || k === "tax" ? el.value : el.value.trim(); });
  }
  function saveBasis() {
    const r = val03Current(), g = r.groups.find((x) => x.id === val03Ui.basisGroup); if (!g) return;
    syncBasisDraft();
    const d = val03Ui.basisDraft;
    if (Object.keys(basisErrors(d)).length) {
      val03Ui.basisShowErrors = true; stateByScreen["SCR-015"] = "VALIDATION_ERROR"; syncReviewUrl(); renderAppScreen();
      document.querySelector(".bj03-basis .is-error")?.focus();
      return;
    }
    const price = Number(d.price), taxSource = d.taxMode === "EXCLUDED" ? Number(d.tax || 0) : 0;
    const fx = fxFor("VND") || { rate: 1, version: "VND" };
    const recoverable = Math.max(0, Math.min(1, Number(taxPolicy().recoverableRate || 0)));
    const nonRecoverable = Math.round(taxSource * Number(fx.rate || 1) * (1 - recoverable));
    const id = `DIRECT-${g.id}-${Date.now()}`;
    const components = [{ type: "PURCHASE_PRICE", label: "Giá mua", source: d.source, version: d.date, amount: price, currency: "VND" }];
    if (taxSource) components.push({ type: "SOURCE_TAX", label: "Thuế trên căn cứ", source: d.source, version: d.date, amount: taxSource, currency: "VND", taxPolicyVersion: taxPolicy().version, nonRecoverableAmountVnd: nonRecoverable });
    g.sources = [{ id, label: `${d.source} · ${d.date}`, sourceAuthorityLabel: d.source, version: "v1", basisVersion: 1, basisHash: `v5.9-${id}`, authoritativeValueHash: `v5.9-${price + nonRecoverable}`, unitPrice: price, currency: "VND", fxRate: 1, fxSourceVersion: fx.version, fxLabel: "VND", unitLineDiscount: 0, unitDocDiscount: 0, unitKnownCost: 0, unitNonDeductibleVat: nonRecoverable, components, evidenceRefs: d.ref ? [d.ref] : [], provenance: components.map((c) => `${c.label} · ${c.source}`), directReason: d.reason, taxMode: d.taxMode, sourceDate: d.date, reference: d.ref, taxPolicyVersion: taxPolicy().version }];
    g.selectedSource = id; r.sourceVersion = Number(r.sourceVersion || 0) + 1; selectGroup(g, true);
    closeSheets(); renderAppScreen();
  }

  // Ca `VALIDATION_ERROR` dựng từ ngoài: mở sheet căn cứ của dòng nhập nhanh còn thiếu (R2 G3) với lỗi tại ô.
  function openValidationDemo() {
    const q = val03Receipts.find((x) => x.id === "VAL03-R2"), g = q && pendingGroups(q).find((x) => val03EvidenceState(x) === "MISSING");
    if (!g) return;
    const prev = val03SelectedReceiptId;
    val03SelectedReceiptId = q.id; openBasis(g); val03Ui.basisShowErrors = true; val03Ui.demo = { prev };
  }
  // Rời trạng thái VALIDATION_ERROR dựng từ ngoài (đổi trạng thái ở bộ kiểm): đóng sheet mẫu, trả phiếu đang xem.
  function closeValidationDemo() { const prev = val03Ui.demo.prev; val03ResetUi(); val03SelectedReceiptId = prev; }

  function summaryAside(r, n, total, disabled) {
    const rows = [["Phiếu nhận", r.receipt], ["Nhà cung cấp", r.supplier], ["Ngày nhận", r.receivedAt], ["Đã chọn", `${n} sản phẩm`], ["Tổng giá trị", money(total), true]];
    return `<section class="ac310-surface bj03-summary" data-layout-pattern="Grouped surface"><div class="ac310-surface__head"><h2>Tóm tắt</h2></div>${facts(rows)}</section>${primaryBtn(`Ghi giá trị (${n})`, "data-bj03-open-confirm", disabled).replace('class="button button--primary"', 'class="button button--primary bj03-cta"')}${disabled ? `<p class="bj03-reason">${NO_PICK}</p>` : ""}`;
  }
  // Chân iPhone: dải tổng + (lý do khi tắt) + nút; web dùng nút trong khối "Tóm tắt".
  function mobileFooter(n, total, disabled) {
    const strip = `<p class="bj03-total-strip">Đã chọn ${n} sản phẩm · ${esc(money(total))}</p>${disabled ? `<p class="bj03-reason">${NO_PICK}</p>` : ""}`;
    return primaryFooter(`Ghi giá trị (${n})`, "data-bj03-open-confirm", disabled)
      .replace('class="app-actions', 'class="app-actions k7-mobile-only')
      .replace("<button", `<div class="bj03-footer-stack">${strip}<button`).replace("</button></footer>", "</button></div></footer>");
  }
  function render015BJ03(state) {
    if (activeFlowId !== "UIF-03") return renderGeneric(screens.find((s) => s.id === "SCR-015"), state);
    const title = TITLE_FORM;
    if (blocked(state)) return denied(title, true);
    if (state === "LOADING") return shell({ title, body: k1Loading({ blocks: ["heading", "row", "row", "row"] }) });
    if (state === "VALIDATION_ERROR" && !val03Ui.basisGroup) openValidationDemo();
    else if (state !== "VALIDATION_ERROR" && val03Ui.demo) closeValidationDemo();
    const r = val03Current();
    const context = `<div class="bj03-context">${ds24ListRow({ title: `${r.receipt} · ${r.supplier}`, subtitle: `${entryLabel(r)} · nhận ${r.receivedAt}`, leading: null, type: "Status", interactive: false, density: "Compact" })}</div>`;
    if (state === "ALREADY_CONFIRMED" || !pendingGroups(r).length) {
      return shell({ title, body: `${context}${k1Locked({ title: "Phiếu này đã được xác lập giá trị", description: "Chi phí phát sinh sau dùng điều chỉnh giá trị." })}`, actions: primaryFooter("Về danh sách", "data-bj03-result-list") });
    }
    tickReady(r);
    const models = pendingGroups(r).map((g) => rowModel(r, g));
    const sel = selectedGroups(r), n = sel.length, total = selectedTotal(r), disabled = n === 0;
    const notices = [];
    if (state === "SOURCE_CHANGED") notices.push(k1Stale({ title: "Căn cứ đã thay đổi", description: "Quay lại kiểm tra dữ liệu hiện hành trước khi xác nhận.", actionLabel: "Kiểm tra lại", actionAttr: "data-bj03-recheck" }));
    if (models.some((m) => m.st === "DIRECT_CONFLICT")) notices.push(vBanner("warning", "Có nhiều căn cứ trực tiếp cần kiểm tra", "Chỉ tiếp tục khi căn cứ sử dụng đã được xác định theo policy và có dấu vết rõ ràng."));
    const rows = models.map((m) => ({ ...m, productHtml: productHtml(m), unitHtml: unitHtml(m), amountHtml: amountHtml(m), statusHtml: statusHtml(m) }));
    const columns = [
      { key: "productHtml", label: "Sản phẩm", html: true },
      { key: "qtyText", label: "Số lượng", align: "end", mono: true },
      { key: "unitHtml", label: "Đơn giá", align: "end", html: true, mono: true },
      { key: "amountHtml", label: "Thành tiền", align: "end", html: true, mono: true },
      { key: "statusHtml", label: "Tình trạng", html: true, cls: () => "bj03-col-status" },
    ];
    const table = k7Table({ columns, rows, mobileRow: productCard, caption: "Sản phẩm chờ xác lập giá trị", select: (row) => ({ attr: `data-bj03-select="${row.g.id}"`, checked: row.selected, disabled: !row.ready, label: row.g.name }), selectLabel: "Chọn sản phẩm", rowAttr: (row) => `class="${row.selected ? "is-selected" : ""}"` });
    const body = `${notices.join("")}${context}${k7Split({ main: table, aside: summaryAside(r, n, total, disabled), wideMain: true, asideWebOnly: true })}${basisSheet(r)}${breakdownSheet(r)}${confirmSheet(r)}`;
    return shell({ title, body, actions: mobileFooter(n, total, disabled) });
  }

  /* ---------- SCR-019 Kết quả xác lập giá trị ---------- */
  function resultDetailSheet(res) {
    if (!val03Ui.resultOpen) return "";
    const rows = (res.groups || []).map((g) => ds24ListRow({ title: g.name, subtitle: `${g.qty} ${g.uom} · ${unitText(g.unitInitial, g.uom)}`, trailing: `<strong class="bj03-money">${esc(money(g.value))}</strong>`, leading: null, type: "Status", interactive: false, density: "Compact" })).join("");
    return sheet({ title: `Chi tiết ${(res.groups || []).length} sản phẩm`, body: `<section class="ds24-list-stack">${rows}</section>`, actions: primaryBtn("Đóng", closeAttr), single: true });
  }
  function render019BJ03(state) {
    if (activeFlowId !== "UIF-03") return renderGeneric(screens.find((s) => s.id === "SCR-019"), state);
    const title = TITLE_RESULT;
    if (blocked(state)) return denied(title, false);
    if (state === "PROCESSING") return shell({ title, body: k1Loading({ blocks: ["heading", "card", "row"] }), centered: true, back: false });
    const res = val03LastResult || VAL03_SAMPLE_RESULT, count = (res.groups || []).length;
    if (state === "UNKNOWN") return k3Unknown({ operation: "Xác lập giá trị nhập ban đầu", scope: `${res.receipt} · ${count} sản phẩm`, ref: res.operationId, sentAt: res.committedAt || COMMITTED_AT, safe: "Không gửi lại lệnh xác nhận.", sourceFlow: "UIF-03", exitAttr: k1ExitAttr("SCR-014") });
    if (state === "REJECTED_EXECUTION") return k4Result({ screenTitle: title, kind: "warning", title: "Chưa ghi giá trị nhập ban đầu", description: "Không có thay đổi. Kiểm tra lại căn cứ hiện hành.", facts: [["Phiếu nhận", esc(res.receipt)], ["Tác động", "Không thay đổi"]], next: [{ label: "Về Kho", attr: k1ExitAttr("SCR-014") }, { label: "Xem lại công việc", attr: "data-bj03-result-back", primary: true }] });
    const remaining = res.remaining || 0;
    const facts = [["Phiếu nhận", esc(res.receipt)], ["Sản phẩm đã xác lập", `${count}`], ["Tổng giá trị đã ghi", esc(money(res.totalValue))], ["Giá vốn", "Cần cập nhật"], ["Người ghi", ACTOR], ["Lúc", esc(res.committedAt || COMMITTED_AT)]];
    if (remaining) facts.push(["Còn chờ giá trị", `${remaining} sản phẩm`]);
    const detail = count ? `<button class="k7-row-link bj03-link bj03-detail-link" type="button" data-bj03-result-detail>Xem chi tiết ${count} sản phẩm</button>${resultDetailSheet(res)}` : "";
    const next = [bj14ReturnAction() || { label: "Cập nhật giá vốn", attr: "data-bj03-go-cost" }, remaining ? { label: "Tiếp tục xử lý", attr: "data-bj03-result-back", primary: true } : { label: "Về danh sách", attr: "data-bj03-result-list", primary: true }];
    return k4Result({ screenTitle: title, title: "Đã ghi giá trị nhập ban đầu", description: "Giá trị đã được ghi cho đúng phạm vi; sản phẩm liên quan cần cập nhật giá vốn.", facts, next, button: detail });
  }

  /* ---------- Ghi giá trị (xem xét lại ở BC-IV-01 / API-C-20) ---------- */
  val03Commit = function () {
    const r = val03Current(), groups = [];
    let totalValue = 0, totalQty = 0;
    for (const g of selectedGroups(r)) {
      const c = val03Calc(g); if (!c) continue;
      const lines = []; let groupQty = 0, groupValue = 0;
      for (const s of (g.slices || []).filter((x) => x.selected && Number(x.pendingQty || 0) > 0)) {
        const q = Number(s.pendingQty || 0), amount = Math.round(Number(c.unitActual || 0) * q);
        groupQty += q; groupValue += amount;
        lines.push({ scopeKey: s.scopeKey, lot: s.lot, state: s.stateLabel, qty: q, value: amount });
      }
      groups.push({ name: g.name, code: g.code, uom: g.uom, qty: groupQty, value: groupValue, unitInitial: c.unitActual, source: val03SourceDetail(g), slices: lines });
      totalQty += groupQty; totalValue += groupValue;
    }
    for (const g of selectedGroups(r)) for (const s of (g.slices || []).filter((x) => x.selected && Number(x.pendingQty || 0) > 0)) {
      const q = s.pendingQty, amount = Math.round((val03Calc(g)?.unitActual || 0) * q);
      s.pendingQty = 0; s.confirmedQty = Number(s.confirmedQty || 0) + q; s.confirmedValue = Number(s.confirmedValue || 0) + amount; s.scopeVersion = Number(s.scopeVersion || 0) + 1; s.selected = false; s.selectedQty = 0;
    }
    val03LastResult = { operationId: `VAL-260925-${String(val03OperationSeq++).padStart(3, "0")}`, receipt: r.receipt, receiptId: r.id, supplier: r.supplier, businessDate: r.receivedAt, groups, totalValue, totalQty, remaining: pendingGroups(r).length, committedAt: COMMITTED_AT, dirtyScope: groups.map((g) => `${g.name} · kỳ ${r.receivedAt.slice(3)}`) };
    val03ReviewSourceVersion = null;
    return val03LastResult;
  };

  /* ---------- Sự kiện ---------- */
  // Gõ ô tìm: dựng lại màn nhưng giữ con trỏ trong ô.
  function renderKeepFocus(sel) {
    const keep = document.activeElement?.matches?.(sel);
    renderAppScreen();
    if (!keep) return;
    const n = document.querySelector(sel);
    if (n) { n.focus(); const v = n.value; n.value = ""; n.value = v; }
  }
  // Bấm bằng bàn phím dựng lại cả màn: trả focus về đúng nút vừa bấm (nút đang hiện, cùng thuộc tính data-bj03-*).
  function renderRefocus(attr, value) {
    renderAppScreen();
    const sel = `[${attr}="${CSS.escape(value)}"]`;
    const n = [...document.querySelectorAll(sel)].find((e) => e.offsetParent !== null) || document.querySelector(sel);
    n?.focus({ preventScroll: true });
  }
  window.addEventListener("input", (event) => {
    if (activeFlowId !== "UIF-03") return;
    const t = event.target;
    if (t.matches?.("[data-bj03-search]")) { val03Query = t.value; return renderKeepFocus("[data-bj03-search]"); }
    if (val03Ui.basisGroup && t.matches?.("[data-bj03-basis]")) {
      syncBasisDraft();
      t.classList.remove("is-error"); t.removeAttribute("aria-invalid");
      const err = t.closest("label")?.querySelector("[data-bj03-error]"); if (err) { err.hidden = true; err.textContent = ""; }
    }
  }, true);
  onDialogClose["UIF-03"] = () => {
    const u = val03Ui;
    if (!(u.basisGroup || u.confirmOpen || u.breakdownGroup || u.resultOpen)) return false;
    closeSheets(); renderAppScreen(); return true;
  };
  // Nghe ở document (sau trình nhớ nút mở hộp thoại của core.js) để Esc / đóng trả focus về đúng nút.
  document.addEventListener("click", (event) => {
    if (activeFlowId !== "UIF-03") return;
    const t = event.target, hit = (sel) => t.closest?.(sel);
    const take = () => { event.preventDefault(); event.stopImmediatePropagation(); };
    let el;
    if (t.matches?.("[data-bj03-backdrop]") || hit("[data-bj03-sheet-close]")) { take(); closeSheets(); return renderAppScreen(); }
    // 014
    if ((el = hit("[data-bj03-filter]"))) { take(); val03Filter = el.dataset.bj03Filter; return renderAppScreen(); }
    if (hit("[data-bj03-show-all]")) { take(); val03Query = ""; val03Filter = "ALL"; if (stateByScreen["SCR-014"] === "FILTER_EMPTY") { stateByScreen["SCR-014"] = "READY"; syncReviewUrl(); } return renderAppScreen(); }
    if ((el = hit("[data-bj03-receipt]"))) {
      take(); val03SelectedReceiptId = el.dataset.bj03Receipt; val03ResetUi(); val03ReturnTo = null; stateByScreen["SCR-015"] = "READY";
      return navigate("SCR-015");
    }
    // 015
    if ((el = hit("[data-bj03-select]"))) {
      take(); if (el.disabled) return;
      const r = val03Current(), g = r.groups.find((x) => x.id === el.dataset.bj03Select);
      if (g && groupState(r, g) === "READY") selectGroup(g, !selectedGroups(r).includes(g));
      return renderRefocus("data-bj03-select", el.dataset.bj03Select);
    }
    if ((el = hit("[data-bj03-breakdown]"))) { take(); val03Ui.breakdownGroup = el.dataset.bj03Breakdown; return renderAppScreen(); }
    if ((el = hit("[data-bj03-add-basis]"))) { take(); const g = val03Current().groups.find((x) => x.id === el.dataset.bj03AddBasis); if (g) openBasis(g); return renderAppScreen(); }
    if ((el = hit("[data-bj03-tax-mode]"))) { take(); syncBasisDraft(); if (val03Ui.basisDraft) val03Ui.basisDraft.taxMode = el.dataset.bj03TaxMode; return renderRefocus("data-bj03-tax-mode", el.dataset.bj03TaxMode); }
    if (hit("[data-bj03-save-basis]")) { take(); return saveBasis(); }
    if ((el = hit("[data-bj03-open-confirm]"))) {
      take(); if (el.disabled) return;
      const r = val03Current(); if (!selectedGroups(r).length) return;
      val03ReviewSourceVersion = r.sourceVersion; val03Ui.confirmOpen = true;
      return renderAppScreen();
    }
    if (hit("[data-bj03-confirm]")) {
      take(); const r = val03Current(); val03Ui.confirmOpen = false;
      if (Number(val03ReviewSourceVersion) !== Number(r.sourceVersion)) { stateByScreen["SCR-015"] = "SOURCE_CHANGED"; syncReviewUrl(); return renderAppScreen(); }
      val03Commit(); stateByScreen["SCR-019"] = "COMPLETED";
      return navigate("SCR-019");
    }
    if (hit("[data-bj03-recheck]")) { take(); stateByScreen["SCR-015"] = "READY"; syncReviewUrl(); return renderAppScreen(); }
    // 019
    if (hit("[data-bj03-result-detail]")) { take(); val03Ui.resultOpen = true; return renderAppScreen(); }
    // Đã ghi xong: quay lại từ 015 về danh sách chờ xác lập (014), không về kết quả nhận hàng của BJ-02 nữa.
    if (hit("[data-bj03-result-back]")) { take(); val03ResetUi(); val03ReturnTo = null; stateByScreen["SCR-015"] = "READY"; return navigate("SCR-015"); }
    if (hit("[data-bj03-result-list]")) { take(); val03ResetUi(); val03Query = ""; val03Filter = "ALL"; val03ReturnTo = null; stateByScreen["SCR-014"] = "READY"; return navigate("SCR-014"); }
    if (hit("[data-bj03-go-cost]")) { take(); val03ResetUi(); return applyEntry("UIF-14", "dirty-scope", true); }
  }, true);

  Object.assign(renderers, {
    "SCR-014": render014BJ03,
    "SCR-015": render015BJ03,
    "SCR-019": render019BJ03,
  });
})();

/* --- Lối vào từ BJ-02: "Xác lập giá trị" ở SCR-012 (chủ cửa hàng) — mở SCR-015 cho đúng phiếu vừa nhận --- */
let val03ReturnTo=null; // { flow, screen } khi mở từ BJ-02: nút quay lại của SCR-015 về lại kết quả nhận hàng
(()=>{
  const SLICE_STATES=[["accepted","SELLABLE","Đủ điều kiện bán","Sẽ tăng khả dụng"],["quarantine","QUARANTINE","Cách ly","Giữ cách ly"],["damaged","DAMAGED","Hư hỏng","Giữ hư hỏng"]];
  function slicesOf(line,gid,committedLine){
    const parts=line.trackingPolicy==="LOT"?(line.lots||[]).map(l=>({lot:l.code||null,t:lotDraftTotals(l)})):[{lot:null,t:lineTotals(line)}];
    const out=[];
    for(const part of parts) for(const [key,state,label,note] of SLICE_STATES){
      const qty=Number(part.t[key])||0; if(qty<=0) continue;
      const lotKey=part.lot?`LOT-${part.lot}`:"NOLOT";
      out.push({id:`${gid}-S${out.length+1}`,scopeKey:`ROL-${line.id}|${lotKey}|${state}`,scopeVersion:1,lineId:`ROL-${line.id}`,lot:part.lot,physicalState:state,stateLabel:label,pendingQty:qty,selected:false,selectedQty:qty,partialOpen:false,availabilityDelta:state==="SELLABLE"?qty:0,availabilityNote:note,originalQty:qty,confirmedQty:0,confirmedValue:0});
    }
    return out;
  }
  function newGroup(r,line,n){
    const gid=`${r.id}-G${n}`, product=typeof productById==="function"?productById(line.productId):null;
    const officialCostVnd=Number(product?.priceBasisSnapshot?.unitPriceVndPerBase||0)*Number(line.conversionRatioSnapshot||1)||undefined; // gợi ý "Giá vốn hiện tại" ở sheet căn cứ
    return {id:gid,name:line.name,code:line.sku,uom:line.uom,tracking:line.trackingPolicy==="LOT"?"LOT":"NONE",officialCostStatus:"EXISTS",officialCostVnd,sources:[],selectedSource:"",reason:"",slices:[],
      receiptItemRef:`${r.id}-ITEM-${n}`,valuationBasisKey:`VB-${gid}`,baseUom:product?.baseUom||line.uom,conversionToBase:Number(line.conversionRatioSnapshot||1),conversionVersion:`CONV-${String(line.sku).replace(/[^A-Za-z0-9]/g,"")}-v1`,basisDisplayLabel:`Dòng nguồn ${n}`};
  }
  // Cập nhật phiếu theo hàng thực nhận của BJ-02: nhóm cùng mã lấy lô / số lượng mới; nhóm không có trong lần nhận hết chờ.
  function applyReceived(r,lines){
    const received=lines.filter(l=>l.status==="COMPLETED"&&lineTotals(l).physicalIncrease>0);
    r.groups.forEach(g=>{ if(!received.some(l=>l.sku===g.code)) g.slices=[]; });
    received.forEach(line=>{
      let g=r.groups.find(x=>x.code===line.sku);
      if(!g){ g=newGroup(r,line,r.groups.length+1); r.groups.push(g); }
      g.slices=slicesOf(line,g.id);
    });
  }
  function buildReceipt(ref,lines){
    const quick=bj02LastCommitted.mode==="quick";
    const r={id:`VAL03-${ref}`,receipt:ref,entryType:quick?"QUICK":"DOCUMENT",supplier:typeof currentReceiptSupplier==="function"?currentReceiptSupplier():"",warehouse:"Kho trung tâm",receivedAt:"16/09/2026",sourceVersion:1,ageDays:0,waitingOwner:"",groups:[]};
    val03Receipts.push(r); return r;
  }
  window.val03OpenForReceipt=function(ref){
    const committed=typeof bj02LastCommitted!=="undefined"&&bj02LastCommitted?.ref===ref?bj02LastCommitted:null;
    let r=val03Receipts.find(x=>x.receipt===ref);
    if(committed){ if(!r) r=buildReceipt(ref,committed.lines); applyReceived(r,committed.lines); }
    if(!r) r=val03Receipts[0];
    val03SelectedReceiptId=r.id;
    // Tick sẵn các nhóm đã đủ căn cứ (`ticked` báo 015 không tick lại); việc còn thiếu căn cứ hiện ở 015.
    r.groups.forEach(g=>{ const ready=val03EvidenceState(g)==="READY"; g.slices.forEach(s=>{ s.selected=ready&&s.pendingQty>0; s.selectedQty=s.pendingQty; s.partialOpen=false; }); });
    r.ticked=true; val03ResetUi();
    val03ReturnTo=committed?{flow:"UIF-02",screen:"SCR-012"}:null;
    activeFlowId="UIF-03"; activeScreenId="SCR-015"; stateByScreen["SCR-015"]="READY";
    syncReviewUrl(); render();
  };
  Object.assign(window.__VET45_QA__,{val03OpenForReceipt:window.val03OpenForReceipt});
  // Vào từ BJ-02 thì quay lại về kết quả nhận hàng; vào từ nơi khác về màn trước trong luồng (danh sách chờ xác lập).
  onPrevious["UIF-03"]=()=>{
    if(val03ReturnTo&&activeScreenId==="SCR-015"){ const to=val03ReturnTo; val03ReturnTo=null; activeFlowId=to.flow; activeScreenId=to.screen; syncReviewUrl(); return render(); }
    const list=activeFlow()?.screens||[]; const idx=list.indexOf(activeScreenId); if(idx>0) return navigate(list[idx-1]);
  };
})();

// Dòng hàng còn chờ xác lập giá của một sản phẩm (BJ-14 đọc để biết sản phẩm chưa có giá nhập thì chưa tính được giá vốn).
function val03PendingLines(code) {
  return val03Receipts.flatMap((r) => r.groups.filter((g) => g.code === code && (g.slices || []).some((s) => Number(s.pendingQty) > 0)).map((g) => ({ receipt: r.receipt, name: g.name })));
}
