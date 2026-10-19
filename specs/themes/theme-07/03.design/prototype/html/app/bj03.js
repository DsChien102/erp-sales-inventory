/* BJ-03 — Xác lập giá trị nhập ban đầu (UIF-03). Màn: SCR-014, SCR-015, SCR-017, SCR-019.
 *
 * Đã viết lại sạch (T7-P gói A5, 2026-10-17); tách đúng theo BJ ở A12 R7 (2026-10-19). Sửa BJ-03: sửa thẳng file này.
 * Màn dựng ở hai khối cuối: SCR-014 / 016 (bản v430), SCR-015 / 017 / 019 (bản v461); helper giao diện VAL_UI_430 /
 * VAL_UI_461 ở shared-valuation.js. Helper val03* bị gán trong khối chuẩn hoá v397 (khai báo `let` một lần ở đầu file).
 */
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
// Helper BJ-03 — một định nghĩa duy nhất, gán trong khối v397 bên dưới (cần biến cục bộ của khối).
let val03EvidenceState, val03Source, val03GroupSelectedQty, val03Calc, val03ActionablePairs, val03WaitingPairs, val03ReceiptState, val03HasSelectedConflict, val03ScopeReady, val03SourceDetail, val03SourcePriceText, val03TotalValue, val03ApplySourceUpdate, val03Commit, val03ScopeGroupsHtml, val03CalculationGroupsHtml, val03EvidenceSheet, val03ReviewGroupsHtml, val03ResultGroupsHtml;
function val03SelectedSlices(r=val03Current()){return val03PendingSlices(r).filter(x=>x.slice.selected&&Number(x.slice.selectedQty)>0);}
function val03GroupReady(group){if(val03GroupSelectedQty(group)<=0)return true;const st=val03EvidenceState(group);if(st==="MISSING")return false;if(st==="CONFLICT"&&(!group.selectedSource||!group.reason.trim()))return false;return Boolean(val03Source(group));}
function val03FmtMoney(n){return `${Math.round(Number(n)||0).toLocaleString("vi-VN")} đ`;}
function val03ScopeLabel(g,s){return g.tracking==="LOT"?`Lô ${s.lot}`:"Không theo lô";}
function val03SelectedGroupCount(r=val03Current()){return r.groups.filter(g=>val03GroupSelectedQty(g)>0).length;}
function val03FilterMatch(r){const st=val03ReceiptState(r);if(val03Filter==="READY")return st!=="WAITING";if(val03Filter==="WAITING")return st==="WAITING";return true;}
function val03ReceiptBadge(r){const st=val03ReceiptState(r);return st==="WAITING"?["Chờ căn cứ","neutral"]:st==="CONFLICT"?["Cần đối chiếu","warning"]:["Có thể xử lý","success"];}
function val03SelectedAvailability(g,s){const q=Math.min(Number(s.selectedQty)||0,s.pendingQty);const ratio=s.pendingQty?Math.min(1,q/s.pendingQty):0;return Math.round((s.availabilityDelta||0)*ratio*1000)/1000;}
function val03ResultSnapshot(){return val03LastResult||{receipt:val03Current().receipt,supplier:val03Current().supplier,groups:[],totalValue:0};}


// ============================================================================

/* chuẩn hoá fixture + helper thắng (v397) */
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
g1.baseUom='lọ'; g1.conversionToBase=10; g1.conversionVersion='CONV-SP00142-v2';
g1.sources=[basisCandidate({id:'BASIS-G1-A',label:'Căn cứ tổng hợp PO-2608-041',version:4,unitPrice:83000,unitLineDiscount:1000,unitDocDiscount:500,unitKnownCost:200,components:[
  {type:'PURCHASE_PRICE',label:'Giá mua',source:'PO-2608-041',version:'v3',amount:83000},
  {type:'LINE_DISCOUNT',label:'Chiết khấu dòng',source:'PO-2608-041',version:'v3',amount:-1000},
  {type:'DOCUMENT_DISCOUNT',label:'Chiết khấu phiếu đã phân bổ',source:'PO-2608-041',version:'ALLOC-v2',amount:-500},
  {type:'KNOWN_PURCHASE_COST',label:'Chi phí mua đã có',source:'CTCP-2608-12',version:'v1',amount:200},
  {type:'SUPPLIER_CONFIRMATION',label:'Bằng chứng bổ sung',source:'Xác nhận NCC 02/09',version:'v1'}
],evidenceRefs:['PO-2608-041 v3','Xác nhận NCC 02/09 v1']})];
g1.selectedSource='BASIS-G1-A';

const g2=val03Receipts[0].groups[1];
g2.sources=[
  basisCandidate({id:'BASIS-G2-PO',label:'Căn cứ theo PO-2608-041',version:3,unitPrice:120000,components:[{type:'PURCHASE_PRICE',label:'Giá mua',source:'PO-2608-041',version:'v3',amount:120000}]}),
  basisCandidate({id:'BASIS-G2-SUP',label:'Căn cứ theo xác nhận NCC 02/09',version:2,unitPrice:121000,components:[{type:'PURCHASE_PRICE',label:'Giá mua',source:'Xác nhận NCC 02/09',version:'v2',amount:121000}]})
];
g2.selectedSource='';

const g4=val03Receipts[2].groups[0];
g4.sources=[basisCandidate({id:'BASIS-G4-A',label:'Căn cứ xác nhận NCC 01/09 + tỷ giá kế toán',version:2,unitPrice:4.1,currency:'USD',fxRate:24450,fxLabel:'Tỷ giá kế toán 24.450 VND/USD',components:[{type:'PURCHASE_PRICE',label:'Giá mua',source:'Xác nhận NCC 01/09',version:'v2',amount:4.1},{type:'FX',label:'Tỷ giá',source:'Kế toán',version:'FX-v7',amount:24450}]})];
g4.selectedSource='BASIS-G4-A';
const g5=val03Receipts[3].groups[0];
g5.sources=[basisCandidate({id:'BASIS-G5-A',label:'Căn cứ theo PO-2609-008',version:1,unitPrice:46000,components:[{type:'PURCHASE_PRICE',label:'Giá mua',source:'PO-2609-008',version:'v1',amount:46000}]})];
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
function tokenStale(r=val03Current()){
  if(!reviewTokens) return false;
  const now=currentTokenMap(r);
  for(const [gid,t] of Object.entries(reviewTokens)){
    const n=now[gid]; if(!n||n.basisKey!==t.basisKey||n.basisVersion!==t.basisVersion||n.basisHash!==t.basisHash) return true;
    for(const s of t.scopes){const x=n.scopes.find(a=>a.id===s.id); if(!x||x.scopeVersion!==s.scopeVersion) return true;}
  }
  return false;
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
  const b=g.sources[0],before=val03SourcePriceText(b,g.uom),selectedAffected=activeScreenId==='SCR-017'&&selectedQty(g)>0;
  b.unitPrice=newPrice; b.basisVersion=Number(b.basisVersion||1)+1; b.version=`v${b.basisVersion}`;
  const actual=b.unitPrice*b.fxRate-(b.unitLineDiscount||0)-(b.unitDocDiscount||0)+(b.unitKnownCost||0)+(b.unitNonDeductibleVat||0);
  b.basisHash=stableHash(`${b.id}|${b.basisVersion}|${actual}|${Date.now()}`); b.authoritativeValueHash=stableHash(`${b.currency}|${b.fxRate}|${actual}`);
  val03LastSourceChange={name:g.name,source:b.label,from:before,to:val03SourcePriceText(b,g.uom)};
  if(basisState(g)==='CONFLICT'){g.selectedSource='';g.reason='';}
  // Preserve legacy sourceVersion only as a compatibility trigger when the selected reviewed basis changed.
  if(selectedAffected) r.sourceVersion+=1;
  return true;
};


val03ScopeGroupsHtml=function(r){
  const content=r.groups.filter(g=>g.slices.some(s=>s.pendingQty>0)).map(g=>{
    const st=basisState(g),badge=st==='MISSING'?['Chờ căn cứ','Neutral']:st==='CONFLICT'?['Cần đối chiếu','Warning']:['Đủ căn cứ','Success'];
    const rows=g.slices.filter(s=>s.pendingQty>0).map(s=>{
      const disabled=st==='MISSING',qty=Math.min(Number(s.selectedQty)||0,s.pendingQty),partial=s.selected?`<div class="val03-partial-controls"><button class="val03-partial-link" type="button" data-val03-partial="${s.id}" data-ds-component="DS v2 / Link" data-figma-node="4431:10396">${s.partialOpen?'Dùng toàn bộ':'Xác nhận một phần'}</button>${s.partialOpen?`<label class="val03-qty" data-ds-component="VTextField" data-figma-node="522:7186"><span>Số lượng lần này</span><input type="number" min="1" max="${s.pendingQty}" value="${qty}" data-val03-qty="${s.id}"/><small>Tối đa ${s.pendingQty} ${esc(g.uom)}</small></label>`:''}</div>`:'';
      return `<div class="valuation-child-item val03-scope-item${s.selected?' is-selected':''}${disabled?' is-disabled':''}"><button type="button" class="valuation-child-row val03-check" data-val03-slice="${s.id}" aria-pressed="${s.selected}" ${disabled?'disabled aria-disabled="true"':''} data-composed-from="VCheckbox,VText"><span class="valuation-child-branch" aria-hidden="true"></span><span class="valuation-selection-control val03-check-mark" aria-hidden="true" data-ds-component="VCheckbox" data-ds-prop-state="${disabled?'Disabled':s.selected?'Checked':'Unchecked'}">${s.selected?icon('check','icon--xs'):''}</span><span class="valuation-child-copy"><strong>${esc(val03ScopeLabel(g,s))}</strong><small>${esc(s.stateLabel)} · Chờ giá ${s.pendingQty} ${esc(g.uom)}</small></span></button>${partial}</div>`;
    }).join('');
    return `<div class="valuation-product-group" data-valuation-basis="${escapeAttribute(g.valuationBasisKey)}">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,status:badge[0],tone:badge[1],meta:duplicateBasisMeta(r,g)})}<div class="valuation-child-list">${rows}</div></div>`;
  }).join('');
  return ds24GroupedCollection(content,'valuation-product-collection val03-product-collection','DS v2 / Icon,VBadge,VCheckbox,VText,VTextField');
};

function componentsHtml(b){
  if(!b?.components?.length)return '';
  return `<div class="valuation-provenance" data-composed-from="VText"><strong>Thành phần của căn cứ</strong>${b.components.map(x=>`<p>${esc(`${x.label} · ${x.source}${x.version?` ${x.version}`:''}`)}</p>`).join('')}</div>`;
}
val03CalculationGroupsHtml=function(r){
  return r.groups.filter(g=>selectedQty(g)>0).map(g=>{
    const st=basisState(g); let basisUI='';
    if(st==='CONFLICT'){
      basisUI=`${vBanner('warning','Căn cứ giá đang mâu thuẫn','Chọn một căn cứ giá hoàn chỉnh có thẩm quyền và ghi lý do.')}<div class="valuation-source-list" data-composed-from="DS v2 / List Row,VRadio">${g.sources.map(b=>`<button type="button" class="val03-source-option ${g.selectedSource===b.id?'is-selected':''}" data-val03-source="${g.id}" data-val03-source-id="${b.id}" aria-pressed="${g.selectedSource===b.id}" data-ds-component="DS v2 / List Row"><span class="valuation-radio-control" aria-hidden="true"><span></span></span><span><strong>${esc(b.label)}</strong><small>${esc(val03SourcePriceText(b,g.uom))}</small></span></button>`).join('')}</div><label class="val03-reason" data-ds-component="VTextarea"><span>Lý do chọn căn cứ <b>*</b></span><textarea rows="3" data-val03-reason="${g.id}" placeholder="Nêu căn cứ để truy vết">${esc(g.reason||'')}</textarea></label>`;
    }else if(st==='MISSING') basisUI=vBanner('warning','Chưa đủ căn cứ','Phần này đang chờ căn cứ giá có thẩm quyền; không nhập giá tạm để đi tiếp.');
    else{ensureSingleBasis(g);const b=chosenBasis(g);basisUI=`${ds24InfoGroup('Căn cứ giá',ds24InfoRow('Căn cứ',b.label),'valuation-info-group valuation-info-group--wrap')}${componentsHtml(b)}`;}
    const c=calc(g),b=c?.src;
    const breakdown=c?`<div class="valuation-kv-stack" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow('Giá nguồn quy đổi',`${fmt(c.baseVnd)}/${g.uom}`)}${b.unitLineDiscount?ds24KeyValueRow('Chiết khấu dòng',`− ${fmt(b.unitLineDiscount)}/${g.uom}`):''}${b.unitDocDiscount?ds24KeyValueRow('Chiết khấu phiếu',`− ${fmt(b.unitDocDiscount)}/${g.uom}`):''}${b.unitKnownCost?ds24KeyValueRow('Chi phí mua đã có',`+ ${fmt(b.unitKnownCost)}/${g.uom}`):''}${b.unitNonDeductibleVat?ds24KeyValueRow('Thuế không khấu trừ',`+ ${fmt(b.unitNonDeductibleVat)}/${g.uom}`):''}${ds24KeyValueRow('Giá nhập thực tế',`${fmt(c.unitActual)}/${g.uom}`,true)}${g.baseUom!==g.uom?ds24KeyValueRow(`Quy đổi ${g.baseUom}`,`${fmt(c.normalizedBaseCost)}/${g.baseUom}`):''}${ds24KeyValueRow('Giá trị lần này',fmt(c.value),true)}</div>`:'';
    return `<section class="valuation-evidence-group" data-valuation-basis="${escapeAttribute(g.valuationBasisKey)}">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,meta:duplicateBasisMeta(r,g)})}<div class="valuation-evidence-body">${basisUI}${breakdown}</div></section>`;
  }).join('');
};
val03EvidenceSheet=function(r=val03Current()){
  if(!val03EvidenceSheetOpen)return '';
  const invalid=!val03ScopeReady(r),title=val03HasSelectedConflict(r)?'Đối chiếu căn cứ giá':'Căn cứ giá và cách tính';
  const feedback=val03LastSourceChange?vBanner('warning','Căn cứ giá vừa thay đổi',`${val03LastSourceChange.name}: ${val03LastSourceChange.from} → ${val03LastSourceChange.to}`):bootstrapConflict(r)?vBanner('error','Không thể khởi tạo nhiều đơn giá khác nhau','Sản phẩm chưa có đơn giá chính thức; hãy xác nhận một căn cứ chuẩn hóa trước.'):invalid&&val03HasSelectedConflict(r)?vBanner('error','Cần hoàn tất căn cứ giá','Chọn căn cứ có thẩm quyền và ghi lý do cho phần đang mâu thuẫn.'):'';
  const body=val03CalculationGroupsHtml(r)||ioEmpty('Chưa có phạm vi để xem căn cứ','Chọn ít nhất một phạm vi hàng trước khi xem căn cứ giá và cách tính.');
  return `<div class="sheet-backdrop valuation-sheet-backdrop" data-val03-action="close-evidence-sheet"><section class="bottom-sheet val03-evidence-sheet valuation-evidence-sheet" data-ds-component="VBottomSheet" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}" onclick="event.stopPropagation()"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(title)}</h3></div><div class="sheet-divider"></div><div class="sheet-content">${feedback}${body}<div class="sheet-actions"><button class="button button--primary" type="button" data-val03-action="close-evidence-sheet" ${val03HasSelectedConflict(r)&&!val03ScopeReady(r)?'disabled':''} data-ds-component="VButton">${val03HasSelectedConflict(r)?'Xong':'Đóng'}</button></div></div></section></div>`;
};

val03ReviewGroupsHtml=function(r){
  const content=r.groups.filter(g=>selectedQty(g)>0).map(g=>{
    const c=calc(g),facts=`<div class="valuation-product-facts" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow('Giá nhập thực tế',c?`${fmt(c.unitActual)}/${g.uom}`:'—')}${g.baseUom!==g.uom&&c?ds24KeyValueRow(`Quy đổi ${g.baseUom}`,`${fmt(c.normalizedBaseCost)}/${g.baseUom}`):''}${ds24KeyValueRow('Căn cứ giá',val03SourceDetail(g))}${g.officialCostStatus==='NONE'&&c?ds24KeyValueRow('Đơn giá chính thức khởi tạo',`${fmt(c.normalizedBaseCost)}/${g.baseUom}`):''}</div>`;
    const slices=g.slices.filter(s=>s.selected&&s.pendingQty>0).map(s=>{const q=Math.min(Number(s.selectedQty)||0,s.pendingQty),ad=val03SelectedAvailability(g,s),effect=ad>0?`+${ad} ${g.uom}`:s.availabilityNote;return valuationReadOnlyChild({title:val03ScopeLabel(g,s),subtitle:`${s.stateLabel} · ${q} ${g.uom}`,trailing:`<span class="valuation-child-value"><small>Khả dụng</small><strong>${esc(effect)}</strong></span>`});}).join('');
    return `<div class="valuation-product-group" data-valuation-basis="${escapeAttribute(g.valuationBasisKey)}">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,value:c?fmt(c.value):'—',meta:duplicateBasisMeta(r,g)})}${facts}<div class="valuation-child-list">${slices}</div></div>`;
  }).join('');
  return ds24GroupedCollection(content,'valuation-product-collection valuation-review-collection','DS v2 / Icon,DS v2 / Key-value Row,VText');
};
val03ResultGroupsHtml=function(res){
  const content=(res.groups||[]).map(g=>{
    const boot=g.officialCostBootstrapStatus==='INITIALIZED'?`Đã khởi tạo · ${fmt(g.normalizedBaseCost)}/${g.baseUom}`:g.officialCostBootstrapStatus==='ALREADY_INITIALIZED'?'Đã có trước đó · không ghi đè':'';
    const facts=`<div class="valuation-product-facts" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow('Giá nhập thực tế',`${fmt(g.unitActual)}/${g.uom}`)}${g.baseUom!==g.uom?ds24KeyValueRow(`Quy đổi ${g.baseUom}`,`${fmt(g.normalizedBaseCost)}/${g.baseUom}`):''}${boot?ds24KeyValueRow('Đơn giá chính thức',boot):''}</div>`;
    const slices=g.slices.map(s=>valuationReadOnlyChild({title:s.lot?`Lô ${s.lot}`:'Không theo lô',subtitle:`${s.state} · ${s.qty} ${g.uom} · ${fmt(s.value)}`,trailing:`<span class="valuation-child-value"><small>Khả dụng</small><strong>${esc(s.availabilityDelta>0?`+${s.availabilityDelta} ${g.uom}`:s.availabilityNote)}</strong></span>`})).join('');
    return `<div class="valuation-product-group">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,value:fmt(g.value),meta:g.receiptItemRef})}${facts}<div class="valuation-child-list">${slices}</div></div>`;
  }).join('');
  return ds24GroupedCollection(content,'valuation-product-collection valuation-result-collection','DS v2 / Icon,DS v2 / Key-value Row,VText');
};

})();

/* v313EntryType */
(()=>{
const types={"VAL03-R1":"DOCUMENT","VAL03-R2":"QUICK","VAL03-R3":"QUICK","VAL03-R4":"DOCUMENT"};
  val03Receipts.forEach(r=>{r.v313EntryType=types[r.id]||'DOCUMENT';});
})();

screenAliases["UIF-03"] = Object.assign(screenAliases["UIF-03"] || {}, {
  "SCR-016": "SCR-015",
  "SCR-018": ["UIF-13", "SCR-085"],
});
{ const a = screenAliases[activeFlowId]?.[activeScreenId]; if (Array.isArray(a)) { activeFlowId = a[0]; activeScreenId = a[1]; } else if (a) activeScreenId = a; }

/* --- SCR-014 + SCR-016 (danh sách / bản v430) — BJ-03 --- */
(()=>{
  const {money, row, heading, button, flatRows, keyRows, contextRow, textField, moneyField, textareaField, formSheet}=VAL_UI_430;
  const qty=g=>(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).reduce((n,s)=>n+Number(s.pendingQty||0),0);
  const pendingGroups=r=>(r.groups||[]).filter(g=>qty(g)>0);
  const entryType=r=>r.v313EntryType||({VAL03_R2:'QUICK'}[r.id])||'DOCUMENT';
  const entryLabel=r=>entryType(r)==='QUICK'?'Nhập nhanh':'Theo chứng từ';
  const stable=value=>{let h=2166136261>>>0;for(const c of String(value)){h^=c.charCodeAt(0);h=Math.imul(h,16777619)>>>0;}return `fixture-v430-${h.toString(16)}`;};
  let val03Filter430='ALL';
  let val03SheetGroup430=null;
  let val03TaxMode430='INCLUDED';
  function val03GroupState430(r,g){
    const st=val03EvidenceState(g);
    if(st==='READY') return 'READY';
    if(st==='CONFLICT') return entryType(r)==='DOCUMENT'?'COMMERCIAL_CONFLICT':'DIRECT_CONFLICT';
    return entryType(r)==='QUICK'?'DIRECT_MISSING':'COMMERCIAL_MISSING';
  }
  function val03ReceiptState430(r){const sts=pendingGroups(r).map(g=>val03GroupState430(r,g));if(sts.some(x=>x.includes('CONFLICT')))return 'CONFLICT';if(sts.length&&sts.every(x=>x.includes('MISSING')))return 'MISSING';return 'READY';}
  function val03Selected430(r=val03Current()){return pendingGroups(r).filter(g=>(g.slices||[]).some(s=>s.selected&&Number(s.pendingQty||0)>0));}
  function val03Select430(g,on){(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).forEach(s=>{s.selected=on;s.selectedQty=s.pendingQty;s.partialOpen=false;});}
  function val03Clear430(r=val03Current()){(r.groups||[]).forEach(g=>val03Select430(g,false));}
  function val03Actual430(g){const s=val03Source(g);if(!s)return null;return s.unitPrice*s.fxRate-(s.unitLineDiscount||0)-(s.unitDocDiscount||0)+(s.unitKnownCost||0)+(s.unitNonDeductibleVat||0);}
  function val03Basis430(g){const s=val03Source(g);return s?s.label:'Chưa có căn cứ';}
  function val03Breakdown430(g){
    const s=val03Source(g);if(!s)return '';
    const unit=s.unitPrice*s.fxRate,actual=val03Actual430(g);
    return keyRows(`${ds24KeyValueRow(s.currency==='VND'?'Giá mua':'Giá mua quy đổi',`${money(unit)}/${g.uom}`)}${s.unitLineDiscount?ds24KeyValueRow('Chiết khấu dòng',`− ${money(s.unitLineDiscount)}/${g.uom}`):''}${s.unitDocDiscount?ds24KeyValueRow('Chiết khấu chứng từ',`− ${money(s.unitDocDiscount)}/${g.uom}`):''}${s.unitKnownCost?ds24KeyValueRow('Chi phí mua đã biết',`+ ${money(s.unitKnownCost)}/${g.uom}`):''}${s.unitNonDeductibleVat?ds24KeyValueRow('Thuế tính vào giá trị',`+ ${money(s.unitNonDeductibleVat)}/${g.uom}`):''}${ds24KeyValueRow('Đơn giá ghi nhận ban đầu',`${money(actual)}/${g.uom}`,true)}`);
  }
  function val03CanReview430(r=val03Current()){const s=val03Selected430(r);return s.length>0&&s.every(g=>val03GroupState430(r,g)==='READY');}
  function val03Group430(r,g){
    const st=val03GroupState430(r,g),selected=val03Selected430(r).includes(g),pending=qty(g);
    const base=`${pending} ${g.uom} đang chờ${g.tracking==='LOT'?` · ${(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).length} lô`:''}`;
    if(st==='READY'){
      const source=val03Source(g),subtitle=`${base} · ${val03Basis430(g)}`;
      return `<section class="v430-task-block ${selected?'is-selected':''}">${row({title:g.name,subtitle,trailing:selected?icon('checkCircle','icon--sm'):'',leading:null,type:'Selection',state:selected?'Selected':'Default',attrs:`data-v430-val03-select="${g.id}"`})}${selected?`<div class="v430-expanded">${flatRows('Căn cứ giá',`${ds24InfoRow('Nguồn',source?.label||'—')}${source?.currency!=='VND'?ds24InfoRow('Tỷ giá',source?.fxLabel||'—'):''}`)}${val03Breakdown430(g)}</div>`:''}</section>`;
    }
    if(st==='COMMERCIAL_CONFLICT')return `<section class="v430-task-block">${contextRow(g.name,base,'Cần đối chiếu','Warning')}<div class="v430-support">${vBanner('warning','Căn cứ mua hàng đang mâu thuẫn','Đối chiếu chứng từ mua có thẩm quyền trước khi xác lập giá trị.')}</div></section>`;
    if(st==='COMMERCIAL_MISSING')return `<section class="v430-task-block">${contextRow(g.name,base,'Cần căn cứ','Warning')}<div class="v430-support">${vBanner('warning','Chưa đủ căn cứ mua hàng','Dòng nhận theo chứng từ chưa có căn cứ giá đủ điều kiện. Công việc sẽ cập nhật khi căn cứ mua hàng được bổ sung.')}</div></section>`;
    if(st==='DIRECT_MISSING')return `<section class="v430-task-block">${contextRow(g.name,base,'Chưa có căn cứ','Neutral')}<div class="v430-support"><p class="v430-helper">Nhập nhanh không cần chờ chứng từ mua. Kế toán có thể lập căn cứ giá trực tiếp và lưu dấu vết.</p>${button('Thêm căn cứ giá',`data-v430-val03-add-basis="${g.id}"`,'secondary')}</div></section>`;
    return `<section class="v430-task-block">${contextRow(g.name,base,'Cần kiểm tra','Warning')}</section>`;
  }
  function val03Form430(r,g){
    const body=`${moneyField('Đơn giá mua','data-v430-basis-price min="0" step="1"','',`Theo đơn vị ${g.uom}`,true)}<div class="v430-field" data-ds-component="VSegmentedControl" data-figma-node="1049:9598"><span>Cách hiểu giá</span><div class="v430-segment"><button type="button" class="${val03TaxMode430==='INCLUDED'?'is-selected':''}" data-v430-tax-mode="INCLUDED">Đã gồm thuế</button><button type="button" class="${val03TaxMode430==='EXCLUDED'?'is-selected':''}" data-v430-tax-mode="EXCLUDED">Chưa gồm thuế</button></div></div><div data-v430-tax-wrap ${val03TaxMode430==='EXCLUDED'?'':'hidden'}>${moneyField('Thuế tính vào giá trị','data-v430-basis-tax min="0" step="1"','0','Nhập phần thuế không được khấu trừ nếu có.')}</div>${textField('Nguồn căn cứ','data-v430-basis-source placeholder="Ví dụ: Xác nhận giá từ nhà cung cấp"','', '',true)}${textField('Ngày căn cứ','data-v430-basis-date inputmode="numeric" placeholder="dd/mm/yyyy"','24/09/2026')}${textField('Tham chiếu / bằng chứng','data-v430-basis-ref placeholder="Mã báo giá, email, ghi chú..."')}${textareaField('Lý do xác lập trực tiếp','data-v430-basis-reason placeholder="Nêu ngắn gọn lý do"','','Bắt buộc khi chưa có chứng từ mua có cấu trúc.',true)}`;
    return formSheet({title:'Thêm căn cứ giá',intro:`${g.name} · Nhập thông tin cần thiết để kế toán và người kiểm tra có thể truy vết căn cứ.`,body,saveLabel:'Lưu căn cứ',saveAttr:'data-v430-val03-sheet="save"',closeAttr:'data-v430-val03-sheet="close"'});
  }
  function val03SetError430(root,selector,msg){const input=root.querySelector(selector);const field=input?.closest('.v430-field');if(!input||!field)return null;input.classList.add('is-error');const e=field.querySelector('.v430-field-error');if(e){e.textContent=msg;e.hidden=false;}return input;}
  function val03SaveBasis430(groupId){
    const r=val03Current(),g=(r.groups||[]).find(x=>x.id===groupId),root=document.querySelector('.v430-form-sheet');if(!g||!root)return false;
    root.querySelectorAll('.is-error').forEach(x=>x.classList.remove('is-error'));root.querySelectorAll('.v430-field-error').forEach(x=>{x.hidden=true;x.textContent='';});
    const price=Number(root.querySelector('[data-v430-basis-price]')?.value||0),sourceLabel=String(root.querySelector('[data-v430-basis-source]')?.value||'').trim(),date=String(root.querySelector('[data-v430-basis-date]')?.value||'').trim(),ref=String(root.querySelector('[data-v430-basis-ref]')?.value||'').trim(),reason=String(root.querySelector('[data-v430-basis-reason]')?.value||'').trim(),tax=val03TaxMode430==='EXCLUDED'?Number(root.querySelector('[data-v430-basis-tax]')?.value||0):0;
    const errors=[];if(!(price>0))errors.push(val03SetError430(root,'[data-v430-basis-price]','Nhập đơn giá lớn hơn 0.'));if(!sourceLabel)errors.push(val03SetError430(root,'[data-v430-basis-source]','Nhập nguồn căn cứ.'));if(!reason)errors.push(val03SetError430(root,'[data-v430-basis-reason]','Nêu lý do xác lập trực tiếp.'));const first=errors.find(Boolean);if(first){first.focus();return false;}
    const id=`DIRECT-${g.id}-${Date.now()}`,components=[{type:'PURCHASE_PRICE',label:'Giá mua',source:sourceLabel,version:date||'Hiện hành',amount:price}];if(tax)components.push({type:'NON_RECOVERABLE_TAX',label:'Thuế tính vào giá trị',source:sourceLabel,version:date||'Hiện hành',amount:tax});
    g.sources=[{id,label:`${sourceLabel}${date?` · ${date}`:''}`,version:'v1',basisVersion:1,basisHash:stable(`${id}|${price}|${tax}|${date}`),authoritativeValueHash:stable(`${price+tax}`),unitPrice:price,currency:'VND',fxRate:1,fxLabel:'VND',unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:tax,components,evidenceRefs:[ref||reason],provenance:components.map(c=>`${c.label} · ${c.source}`),directReason:reason,taxMode:val03TaxMode430,sourceDate:date,reference:ref}];
    g.selectedSource=id;r.sourceVersion=Number(r.sourceVersion||0)+1;val03Select430(g,true);return true;
  }
  function val03Commit430(){
    const r=val03Current(),groups=[];let totalValue=0,totalQty=0;
    for(const g of val03Selected430(r)){const c=val03Calc(g);if(!c)continue;const lines=[];let groupQty=0,groupValue=0;for(const s of (g.slices||[]).filter(x=>x.selected&&Number(x.pendingQty||0)>0)){const q=Number(s.pendingQty||0),amount=Math.round(Number(c.unitActual||0)*q);groupQty+=q;groupValue+=amount;lines.push({scopeKey:s.scopeKey,lot:s.lot,state:s.stateLabel,qty:q,value:amount});}groups.push({name:g.name,code:g.code,uom:g.uom,qty:groupQty,value:groupValue,unitInitial:c.unitActual,source:val03SourceDetail(g),slices:lines});totalQty+=groupQty;totalValue+=groupValue;}
    val03LastResult={operationId:`VAL-260925-${String(val03OperationSeq++).padStart(3,'0')}`,receipt:r.receipt,supplier:r.supplier,businessDate:r.receivedAt,groups,totalValue,totalQty,dirtyScope:groups.map(g=>`${g.name} · kỳ ${r.receivedAt.slice(3)}`)};
    for(const g of val03Selected430(r))for(const s of (g.slices||[]).filter(x=>x.selected&&Number(x.pendingQty||0)>0)){const q=s.pendingQty,amount=Math.round((val03Calc(g)?.unitActual||0)*q);s.pendingQty=0;s.confirmedQty=Number(s.confirmedQty||0)+q;s.confirmedValue=Number(s.confirmedValue||0)+amount;s.scopeVersion=Number(s.scopeVersion||0)+1;s.selected=false;s.selectedQty=0;}
    val03ReviewSourceVersion=null;return val03LastResult;
  }
  val03Commit=val03Commit430;
  function render014BJ03(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-014'),state);if(state==='LOADING')return appShell({title:'Hàng chờ xác lập giá trị',body:loadingBody(),centered:true,back:false});if(state==='PERMISSION_DENIED')return appShell({title:'Hàng chờ xác lập giá trị',body:deniedBody(),centered:true,back:false});
    const q=String(val03Query||'').toLocaleLowerCase('vi'),rows=val03Receipts.filter(r=>pendingGroups(r).length).filter(r=>!q||`${r.receipt} ${r.supplier}`.toLocaleLowerCase('vi').includes(q)).filter(r=>{const st=val03ReceiptState430(r);return val03Filter430==='ALL'||(val03Filter430==='READY'&&st==='READY')||(val03Filter430==='ISSUE'&&st!=='READY');}).map(r=>{const st=val03ReceiptState430(r),trailing=st==='CONFLICT'?ds24Badge('Cần đối chiếu','Warning'):st==='MISSING'?ds24Badge('Cần căn cứ','Neutral'):'';return row({title:r.receipt,subtitle:`${r.supplier} · ${entryLabel(r)} · ${pendingGroups(r).length} dòng chờ`,trailing,leading:null,type:'Navigation',attrs:`data-v430-val03-receipt="${r.id}"`});}).join('');
    const body=`${ds24Search(val03Query,'data-v430-val03-search','Phiếu nhận hoặc nhà cung cấp')}<div class="ds24-chip-scroll">${ds24Chip('ALL','Tất cả',val03Filter430==='ALL','data-v430-val03-filter')}${ds24Chip('READY','Có thể xác lập',val03Filter430==='READY','data-v430-val03-filter')}${ds24Chip('ISSUE','Cần xử lý',val03Filter430==='ISSUE','data-v430-val03-filter')}</div>${rows?`<section class="ds24-list-stack v430-list">${rows}</section>`:ioEmpty('Không có công việc phù hợp','Đổi từ khóa hoặc bộ lọc để xem công việc khác.')}`;return appShell({title:'Hàng chờ xác lập giá trị',body,back:false});
  }
  function render015V430(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-015'),state);const r=val03Current();if(state==='LOADING')return appShell({title:'Xác lập giá trị nhập ban đầu',body:loadingBody(),centered:true});if(state==='PERMISSION_DENIED')return appShell({title:'Xác lập giá trị nhập ban đầu',body:deniedBody(),centered:true});
    const context=contextRow(r.receipt,`${r.supplier} · ${r.receivedAt}`,entryLabel(r),'Neutral'),work=pendingGroups(r).map(g=>val03Group430(r,g)).join(''),selected=val03Selected430(r),total=selected.reduce((n,g)=>n+(val03Calc(g)?.value||0),0),selection=selected.length?keyRows(ds24KeyValueRow(`Đã chọn ${selected.length} dòng`,money(total),true),'v430-selection-total'):'';
    const body=`${state==='SOURCE_CHANGED'?vBanner('warning','Căn cứ đã thay đổi','Kiểm tra lại giá và cấu thành trước khi tiếp tục.'):''}${context}${heading('Hàng chờ giá trị')}${work}${selection}${val03SheetGroup430?val03Form430(r,(r.groups||[]).find(g=>g.id===val03SheetGroup430)):''}`;return appShell({title:'Xác lập giá trị nhập ban đầu',body,actions:primaryFooter('Rà soát','data-v430-val03-review',!val03CanReview430(r))});
  }

  window.addEventListener('input',event=>{
    if(activeFlowId==='UIF-03'&&event.target.matches('[data-v430-val03-search]')){val03Query=event.target.value;return renderAppScreen();}
  },true);
  window.addEventListener('click',event=>{
    let el;
    if(activeFlowId==='UIF-03'){
      if((el=event.target.closest('[data-v430-val03-filter]'))){event.preventDefault();event.stopImmediatePropagation();val03Filter430=el.dataset.v430Val03Filter;return renderAppScreen();}
      if((el=event.target.closest('[data-v430-val03-receipt]'))){event.preventDefault();event.stopImmediatePropagation();val03SelectedReceiptId=el.dataset.v430Val03Receipt;val03Clear430();val03SheetGroup430=null;stateByScreen['SCR-015']='READY';return navigate('SCR-015');}
      if((el=event.target.closest('[data-v430-val03-select]'))){event.preventDefault();event.stopImmediatePropagation();const g=(val03Current().groups||[]).find(x=>x.id===el.dataset.v430Val03Select);if(g&&val03GroupState430(val03Current(),g)==='READY')val03Select430(g,!val03Selected430().includes(g));return renderAppScreen();}
      if((el=event.target.closest('[data-v430-val03-add-basis]'))){event.preventDefault();event.stopImmediatePropagation();val03SheetGroup430=el.dataset.v430Val03AddBasis;val03TaxMode430='INCLUDED';return renderAppScreen();}
      if((el=event.target.closest('[data-v430-tax-mode]'))){event.preventDefault();event.stopImmediatePropagation();val03TaxMode430=el.dataset.v430TaxMode;document.querySelectorAll('[data-v430-tax-mode]').forEach(x=>x.classList.toggle('is-selected',x.dataset.v430TaxMode===val03TaxMode430));const wrap=document.querySelector('[data-v430-tax-wrap]');if(wrap)wrap.hidden=val03TaxMode430!=='EXCLUDED';return;}
      if((el=event.target.closest('[data-v430-val03-sheet]'))){event.preventDefault();event.stopImmediatePropagation();if(el.dataset.v430Val03Sheet==='close'){val03SheetGroup430=null;return renderAppScreen();}if(el.dataset.v430Val03Sheet==='save'&&val03SaveBasis430(val03SheetGroup430)){val03SheetGroup430=null;return renderAppScreen();}return;}
      if((el=event.target.closest('[data-v430-val03-review]'))){event.preventDefault();event.stopImmediatePropagation();if(!val03CanReview430())return;val03ReviewSourceVersion=val03Current().sourceVersion;stateByScreen['SCR-017']='READY';return navigate('SCR-017');}
      if((el=event.target.closest('[data-v430-val03-back]'))){event.preventDefault();event.stopImmediatePropagation();stateByScreen['SCR-015']='READY';return navigate('SCR-015');}
      if((el=event.target.closest('[data-v430-val03-confirm]'))){event.preventDefault();event.stopImmediatePropagation();if(Number(val03ReviewSourceVersion)!==Number(val03Current().sourceVersion)){stateByScreen['SCR-017']='SOURCE_CHANGED';return renderAppScreen();}val03Commit430();stateByScreen['SCR-019']='COMPLETED';return navigate('SCR-019');}
      if((el=event.target.closest('[data-v430-val03-result-back]'))){event.preventDefault();event.stopImmediatePropagation();val03Clear430();stateByScreen['SCR-015']='READY';return navigate('SCR-015');}
      if((el=event.target.closest('[data-v430-val03-result-list]'))){event.preventDefault();event.stopImmediatePropagation();val03Query='';val03Filter430='ALL';return navigate('SCR-014');}
    }
  },true);
  Object.assign(renderers, {
    'SCR-014': render014BJ03,
    'SCR-016': render015V430,
  });
})();

/* --- SCR-015 / 017 / 019 (biểu mẫu, rà soát, kết quả — bản v461) — BJ-03 --- */
(()=>{
  const {money, row, heading, flat, keys, context, button, linkButton, textField, textarea, selectField, formSheet}=VAL_UI_461;
  let basisSheetGroup=null, basisDraft=null;
  const qty=g=>(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).reduce((n,s)=>n+Number(s.pendingQty||0),0);
  const pendingGroups=r=>(r.groups||[]).filter(g=>qty(g)>0);
  const selectedGroups=(r=val03Current())=>pendingGroups(r).filter(g=>(g.slices||[]).some(s=>s.selected&&Number(s.pendingQty||0)>0));
  const isQuick=r=>r.v313EntryType==='QUICK'||r.id==='VAL03-R2'||r.id==='VAL03-R3';
  const groupState=(r,g)=>{const st=val03EvidenceState(g);if(st==='READY')return 'READY';if(st==='CONFLICT')return isQuick(r)?'DIRECT_CONFLICT':'COMMERCIAL_CONFLICT';return isQuick(r)?'DIRECT_MISSING':'COMMERCIAL_MISSING';};
  const selectGroup=(g,on)=>(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).forEach(s=>{s.selected=on;s.selectedQty=s.pendingQty;s.partialOpen=false;});
  const actualUnit=g=>Number(val03Calc(g)?.unitActual||0);
  const breakdown=g=>{const s=val03Source(g),c=val03Calc(g);if(!s||!c)return '';const purchase=Number(s.unitPrice||0)*Number(s.fxRate||1);return keys(`${ds24KeyValueRow('Giá mua',`${money(purchase)}/${g.uom}`)}${s.unitLineDiscount?ds24KeyValueRow('Chiết khấu dòng',`− ${money(s.unitLineDiscount)}/${g.uom}`):''}${s.unitDocDiscount?ds24KeyValueRow('Chiết khấu chứng từ',`− ${money(s.unitDocDiscount)}/${g.uom}`):''}${s.unitKnownCost?ds24KeyValueRow('Chi phí mua đã biết',`+ ${money(s.unitKnownCost)}/${g.uom}`):''}${s.unitNonDeductibleVat?ds24KeyValueRow('Thuế/phí tính vào giá trị',`+ ${money(s.unitNonDeductibleVat)}/${g.uom}`):''}${ds24KeyValueRow('Đơn giá ghi nhận ban đầu',`${money(c.unitActual)}/${g.uom}`,true)}`);};
  function groupHtml(r,g){
    const st=groupState(r,g),selected=selectedGroups(r).includes(g),pending=qty(g),base=`${pending} ${g.uom} đang chờ${g.tracking==='LOT'?` · ${(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).length} lô`:''}`;
    if(st==='READY'){
      const s=val03Source(g),unit=actualUnit(g),subtitle=`${base} · ${money(unit)}/${g.uom}`;
      return `<section class="v460-task ${selected?'is-selected':''}">${row({title:g.name,subtitle,trailing:selected?icon('checkCircle','icon--sm'):'',leading:null,type:'Selection',state:selected?'Selected':'Default',attrs:`data-v461-val03-select="${g.id}"`})}${selected?`<div class="v460-task__detail">${flat('Căn cứ đang dùng',ds24InfoRow('Căn cứ',s?.label||'—'))}${breakdown(g)}</div>`:''}</section>`;
    }
    if(st==='COMMERCIAL_CONFLICT')return `<section class="v460-task">${context(g.name,base,'Cần đối chiếu','Warning')}<div class="v430-support">${vBanner('warning','Căn cứ mua hàng đang mâu thuẫn','Đối chiếu nguồn mua có thẩm quyền trước khi xác lập giá trị.')}</div></section>`;
    if(st==='COMMERCIAL_MISSING')return `<section class="v460-task">${context(g.name,base,'Cần căn cứ','Warning')}<div class="v430-support">${vBanner('warning','Chưa đủ căn cứ mua hàng','Công việc sẽ cập nhật khi nguồn mua có thẩm quyền cung cấp đủ giá trị.')}</div></section>`;
    if(st==='DIRECT_MISSING')return `<section class="v460-task">${context(g.name,base,'Chưa có căn cứ','Neutral')}<div class="v430-support"><p class="v430-helper">Chưa có nguồn mua cấu trúc đủ dùng. Kế toán có thể lập căn cứ trực tiếp khi có đủ thông tin và bằng chứng.</p>${button('Thêm căn cứ giá',`data-v461-val03-add-basis="${g.id}"`,'secondary')}</div></section>`;
    if(st==='DIRECT_CONFLICT')return `<section class="v460-task">${context(g.name,base,'Cần kiểm tra','Warning')}<div class="v430-support">${vBanner('warning','Có nhiều căn cứ trực tiếp cần kiểm tra','Chỉ tiếp tục khi căn cứ sử dụng đã được xác định theo policy và có dấu vết rõ ràng.')}</div></section>`;
    return `<section class="v460-task">${context(g.name,base,'Cần kiểm tra','Warning')}</section>`;
  }
  const currencyCatalog=()=>window.__VET45_MONEY_CURRENCY_CATALOG__||[];
  const taxPolicy=()=>window.__VET45_TAX_TREATMENT_POLICY__||{recoverableRate:0,version:'UNSET'};
  const fxFor=currency=>window.__VET45_FX_SOURCE_FIXTURE__?.[currency]||null;
  function ensureBasisDraft(){if(!basisDraft)basisDraft={price:'',currency:'',taxMode:'',tax:'',source:'',date:'',ref:'',reason:''};return basisDraft;}
  function amountField(label,attrs,value='',helper='',required=false,currency=''){
    return `<label class="v430-field" data-ds-component="VMoneyField" data-figma-node="522:7322"><span>${esc(label)}${required?' <b>*</b>':''}</span><div class="v430-money"><input class="v430-control" inputmode="decimal" type="number" ${attrs} value="${escapeAttribute(value)}"/><span data-v461-currency-suffix>${esc(currency||'—')}</span></div>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  }
  function taxChoice(){const d=ensureBasisDraft();const item=(id,label,desc)=>`<button type="button" class="v460-choice ${d.taxMode===id?'is-selected':''}" data-v461-tax-mode="${id}" data-ds-component="VRadio" data-figma-node="522:7410" aria-pressed="${d.taxMode===id}"><span class="v460-choice__radio"><span></span></span><span><strong>${esc(label)}</strong><small>${esc(desc)}</small></span></button>`;return `<div class="v460-field-group"><span class="v460-field-label">Cách hiểu giá <b>*</b></span><div class="v460-choice-list">${item('INCLUDED','Đã gồm thuế','Đơn giá trên căn cứ đã bao gồm phần thuế của nguồn.')}${item('EXCLUDED','Chưa gồm thuế','Đơn giá trên căn cứ chưa bao gồm phần thuế của nguồn.')}</div><small class="v430-field-error" data-v461-taxmode-error hidden></small></div>`;}
  function basisForm(g){
    const d=ensureBasisDraft(), opts=[`<option value="">Chọn tiền tệ</option>`,...currencyCatalog().map(x=>`<option value="${escapeAttribute(x.id)}" ${d.currency===x.id?'selected':''}>${esc(x.label)}</option>`)].join('');
    const body=`${selectField('Tiền tệ *','data-v461-basis-currency',opts)}${amountField('Đơn giá mua','data-v461-basis-price min="0" step="0.01"',d.price,`Theo đơn vị ${g.uom}`,true,d.currency)}${taxChoice()}<div data-v461-tax-wrap ${d.taxMode==='EXCLUDED'?'':'hidden'}>${amountField('Thuế trên căn cứ','data-v461-basis-tax min="0" step="0.01"',d.tax,'Nhập số thuế ghi trên căn cứ nếu có; hệ thống áp chính sách thuế để xác định phần đi vào giá trị.',false,d.currency)}</div>${textField('Căn cứ giá từ đâu?','data-v461-basis-source placeholder="Ví dụ: Báo giá hoặc xác nhận giá của nhà cung cấp"',d.source,'Ghi nguồn nghiệp vụ tạo ra đơn giá, không phải tên tệp.',true)}${textField('Ngày căn cứ','data-v461-basis-date inputmode="numeric" placeholder="dd/mm/yyyy"',d.date,'',true)}${textField('Tham chiếu / bằng chứng','data-v461-basis-ref placeholder="Mã báo giá, email, ghi chú..."',d.ref)}${textarea('Lý do xác lập trực tiếp','data-v461-basis-reason placeholder="Nêu ngắn gọn lý do"',d.reason,'Bắt buộc vì chưa có nguồn mua cấu trúc đủ dùng.',true)}`;
    return formSheet({title:'Thêm căn cứ giá',intro:`${g.name} · Ghi đơn giá, tiền tệ, nguồn và ngày căn cứ.`,body,saveLabel:'Lưu căn cứ',saveAttr:'data-v461-val03-sheet="save"',closeAttr:'data-v461-val03-sheet="close"'});
  }
  function setError(root,sel,msg){const input=root.querySelector(sel),field=input?.closest('.v430-field');if(!input||!field)return null;input.classList.add('is-error');const e=field.querySelector('.v430-field-error');if(e){e.textContent=msg;e.hidden=false;}return input;}
  function syncBasisDraft(root){const d=ensureBasisDraft();d.price=String(root.querySelector('[data-v461-basis-price]')?.value||'');d.currency=String(root.querySelector('[data-v461-basis-currency]')?.value||'');d.tax=String(root.querySelector('[data-v461-basis-tax]')?.value||'');d.source=String(root.querySelector('[data-v461-basis-source]')?.value||'').trim();d.date=String(root.querySelector('[data-v461-basis-date]')?.value||'').trim();d.ref=String(root.querySelector('[data-v461-basis-ref]')?.value||'').trim();d.reason=String(root.querySelector('[data-v461-basis-reason]')?.value||'').trim();return d;}
  function saveBasis(groupId){
    const r=val03Current(),g=(r.groups||[]).find(x=>x.id===groupId),root=document.querySelector('.v430-form-sheet');if(!g||!root)return false;
    root.querySelectorAll('.is-error').forEach(x=>x.classList.remove('is-error'));root.querySelectorAll('.v430-field-error').forEach(x=>{x.hidden=true;x.textContent='';});
    const d=syncBasisDraft(root), price=Number(d.price||0), taxSource=d.taxMode==='EXCLUDED'?Number(d.tax||0):0, errs=[];
    if(!d.currency)errs.push(setError(root,'[data-v461-basis-currency]','Chọn tiền tệ.'));
    if(!(price>0))errs.push(setError(root,'[data-v461-basis-price]','Nhập đơn giá lớn hơn 0.'));
    if(!d.taxMode){const e=root.querySelector('[data-v461-taxmode-error]');if(e){e.textContent='Chọn cách hiểu giá.';e.hidden=false;}errs.push(root.querySelector('[data-v461-tax-mode]'));}
    if(!d.source)errs.push(setError(root,'[data-v461-basis-source]','Nhập căn cứ giá.'));
    if(!d.date)errs.push(setError(root,'[data-v461-basis-date]','Nhập ngày căn cứ.'));
    else if(!/^\d{2}\/\d{2}\/\d{4}$/.test(d.date))errs.push(setError(root,'[data-v461-basis-date]','Dùng định dạng dd/mm/yyyy.'));
    if(!d.reason)errs.push(setError(root,'[data-v461-basis-reason]','Nêu lý do xác lập trực tiếp.'));
    const fx=fxFor(d.currency);if(d.currency&&!fx)errs.push(setError(root,'[data-v461-basis-currency]','Chưa có dữ liệu quy đổi có thẩm quyền cho tiền tệ này.'));
    const first=errs.find(Boolean);if(first){first.focus?.();return false;}
    const recoverable=Math.max(0,Math.min(1,Number(taxPolicy().recoverableRate||0))), fxRate=Number(fx.rate||1), nonRecoverableTax=Math.round(taxSource*fxRate*(1-recoverable));
    const id=`DIRECT-${g.id}-${Date.now()}`, components=[{type:'PURCHASE_PRICE',label:'Giá mua',source:d.source,version:d.date,amount:price,currency:d.currency}];
    if(taxSource)components.push({type:'SOURCE_TAX',label:'Thuế trên căn cứ',source:d.source,version:d.date,amount:taxSource,currency:d.currency,taxPolicyVersion:taxPolicy().version,nonRecoverableAmountVnd:nonRecoverableTax});
    g.sources=[{id,label:`${d.source} · ${d.date}`,sourceAuthorityLabel:d.source,version:'v1',basisVersion:1,basisHash:`v461-${id}`,authoritativeValueHash:`v461-${Math.round(price*fxRate)+nonRecoverableTax}`,unitPrice:price,currency:d.currency,fxRate,fxSourceVersion:fx.version,fxLabel:'INTERNAL',unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:nonRecoverableTax,components,evidenceRefs:d.ref?[d.ref]:[],provenance:components.map(c=>`${c.label} · ${c.source}`),directReason:d.reason,taxMode:d.taxMode,sourceDate:d.date,reference:d.ref,taxPolicyVersion:taxPolicy().version}];
    g.selectedSource=id;r.sourceVersion=Number(r.sourceVersion||0)+1;selectGroup(g,true);return true;
  }
  function canReview03(r=val03Current()){const a=selectedGroups(r);return a.length>0&&a.every(g=>groupState(r,g)==='READY');}
  function render015BJ03(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-015'),state);const r=val03Current();if(state==='PERMISSION_DENIED')return appShell({title:'Xác lập giá trị nhập ban đầu',body:deniedBody(),centered:true});
    const groups=pendingGroups(r).map(g=>groupHtml(r,g)).join(''),selected=selectedGroups(r),total=selected.reduce((n,g)=>n+Number(val03Calc(g)?.value||0),0),summary=selected.length?keys(`${ds24KeyValueRow(`${selected.length} sản phẩm đã chọn`,money(total),true)}`,'v460-selection-summary'):'';
    const body=`${context(r.receipt,`${r.supplier} · ${r.receivedAt}`,isQuick(r)?'Nhập nhanh':'Theo chứng từ','Neutral')}${groups||ioEmpty('Không còn hàng chờ giá trị','Các dòng thuộc phiếu nhận này đã được xử lý.')}${summary}${basisSheetGroup?basisForm((r.groups||[]).find(g=>g.id===basisSheetGroup)):''}`;
    return appShell({title:'Xác lập giá trị nhập ban đầu',body,actions:primaryFooter('Rà soát','data-v461-val03-review',!canReview03(r))});
  }
  function render017BJ03(state){ensureVal03ReviewFixture();
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-017'),state);const r=val03Current();if(state==='PERMISSION_DENIED')return appShell({title:'Rà soát giá trị nhập ban đầu',body:deniedBody(),centered:true});const stale=state==='SOURCE_CHANGED'||val03ReviewSourceVersion==null||Number(val03ReviewSourceVersion)!==Number(r.sourceVersion);if(stale)return appShell({title:'Rà soát giá trị nhập ban đầu',body:`${vBanner('warning','Căn cứ đã thay đổi','Quay lại kiểm tra dữ liệu hiện hành trước khi xác nhận.')}${context(r.receipt,r.supplier)}`,actions:primaryFooter('Kiểm tra lại','data-v461-val03-back')});
    const groups=selectedGroups(r),total=groups.reduce((n,g)=>n+Number(val03Calc(g)?.value||0),0),items=groups.map(g=>{const c=val03Calc(g),s=val03Source(g);return `<section class="v460-review-item">${row({title:g.name,subtitle:`${c.qty} ${g.uom} · ${money(c.unitActual)}/${g.uom}`,trailing:`<strong class="v460-money-trailing">${money(c.value)}</strong>`,leading:null,type:'Status',interactive:false})}<details class="v430-details v460-details"><summary>Chi tiết căn cứ</summary><div class="v430-details__body">${flat('',ds24InfoRow('Căn cứ',s?.label||'—'))}${breakdown(g)}</div></details></section>`;}).join('');
    const body=`${context(r.receipt,`${r.supplier} · ${r.receivedAt}`)}${ds24SummaryCard('Tổng giá trị sẽ ghi',`${money(total)} · ${groups.length} sản phẩm`,'data-ds-prop-tone="Neutral"')}${heading('Sản phẩm sẽ ghi',`${groups.length} sản phẩm`)}<div class="v460-review-list">${items}</div>${linkButton('Chỉnh sửa căn cứ','data-v461-val03-back')}`;
    return appShell({title:'Rà soát giá trị nhập ban đầu',body,actions:primaryFooter('Xác nhận giá trị','data-v461-val03-confirm')});
  }
  function render019BJ03(state){ensureVal03ResultFixture();
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-019'),state);const res=val03LastResult||{receipt:val03Current().receipt,groups:[],totalValue:0};if(state==='PROCESSING')return appShell({title:'Kết quả xác lập giá trị',body:loadingBody(),centered:true,back:false});if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-03" data-operation="${escapeAttribute(res.operationId||'VAL-UNKNOWN')}" data-scope="${escapeAttribute(res.receipt||'')}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định giá trị đã được ghi hay chưa','Không gửi lại lệnh xác nhận. Chuyển đúng lần xử lý này sang xác minh kết quả.',[['Phiếu nhận',res.receipt],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả xác lập giá trị',body:ioResult('Chưa ghi giá trị nhập ban đầu','Không có thay đổi. Kiểm tra lại căn cứ hiện hành.',[['Phiếu nhận',res.receipt],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại công việc','data-v461-val03-result-back')});
    const detail=(res.groups||[]).map(g=>row({title:g.name,subtitle:`${g.qty} ${g.uom} · ${money(g.unitInitial)}/${g.uom}`,trailing:`<strong class="v460-money-trailing">${money(g.value)}</strong>`,leading:null,type:'Status',interactive:false})).join(''),remaining=pendingGroups(val03Current()).length,summary=flat('Kết quả',`${ds24InfoRow('Phiếu nhận',res.receipt||'—')}${ds24InfoRow('Sản phẩm đã xác lập',String((res.groups||[]).length))}${ds24KeyValueRow('Tổng giá trị đã ghi',money(res.totalValue||0),true)}${ds24InfoRow('Giá vốn','Cần cập nhật')}`),details=detail?`<details class="v430-details v460-details"><summary>Xem chi tiết ${(res.groups||[]).length} sản phẩm</summary><div class="v430-details__body"><section class="ds24-list-stack v430-list">${detail}</section></div></details>`:'';
    const body=`<div class="io-result">${resultHero('Đã ghi giá trị nhập ban đầu','Giá trị đã được ghi cho đúng phạm vi; sản phẩm liên quan cần cập nhật giá vốn.')}${summary}${details}${remaining?vBanner('info','Còn hàng chờ giá trị',`${remaining} sản phẩm/dòng còn cần xử lý.`):''}</div>`;
    return appShell({title:'Kết quả xác lập giá trị',body,centered:true,back:false,actions:primaryFooter(remaining?'Tiếp tục xử lý':'Về danh sách',remaining?'data-v461-val03-result-back':'data-v461-val03-result-list')});
  }

  window.addEventListener('change',event=>{
    if(activeFlowId==='UIF-03'&&event.target.matches('[data-v461-basis-currency]')){event.stopImmediatePropagation();ensureBasisDraft().currency=event.target.value;return renderAppScreen();}
  },true);
  window.addEventListener('input',event=>{
    if(activeFlowId==='UIF-03'&&basisSheetGroup&&event.target.closest('.v430-form-sheet')){
      const root=document.querySelector('.v430-form-sheet');if(root)syncBasisDraft(root);
    }
  },true);
  window.addEventListener('click',event=>{
    let el;
    if(activeFlowId==='UIF-03'){
      if((el=event.target.closest('[data-v461-val03-select]'))){event.preventDefault();event.stopImmediatePropagation();const g=(val03Current().groups||[]).find(x=>x.id===el.dataset.v461Val03Select);if(g&&groupState(val03Current(),g)==='READY')selectGroup(g,!selectedGroups().includes(g));return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val03-add-basis]'))){event.preventDefault();event.stopImmediatePropagation();basisSheetGroup=el.dataset.v461Val03AddBasis;basisDraft={price:'',currency:'',taxMode:'',tax:'',source:'',date:'',ref:'',reason:''};return renderAppScreen();}
      if((el=event.target.closest('[data-v461-tax-mode]'))){event.preventDefault();event.stopImmediatePropagation();ensureBasisDraft().taxMode=el.dataset.v461TaxMode;return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val03-sheet]'))){event.preventDefault();event.stopImmediatePropagation();if(el.dataset.v461Val03Sheet==='close'){basisSheetGroup=null;basisDraft=null;return renderAppScreen();}if(el.dataset.v461Val03Sheet==='save'&&saveBasis(basisSheetGroup)){basisSheetGroup=null;basisDraft=null;return renderAppScreen();}return;}
      if((el=event.target.closest('[data-v461-val03-review]'))){event.preventDefault();event.stopImmediatePropagation();if(!canReview03())return;val03ReviewSourceVersion=val03Current().sourceVersion;stateByScreen['SCR-017']='READY';return navigate('SCR-017');}
      if((el=event.target.closest('[data-v461-val03-back]'))){event.preventDefault();event.stopImmediatePropagation();stateByScreen['SCR-015']='READY';return navigate('SCR-015');}
      if((el=event.target.closest('[data-v461-val03-confirm]'))){event.preventDefault();event.stopImmediatePropagation();if(Number(val03ReviewSourceVersion)!==Number(val03Current().sourceVersion)){stateByScreen['SCR-017']='SOURCE_CHANGED';return renderAppScreen();}val03Commit();stateByScreen['SCR-019']='COMPLETED';return navigate('SCR-019');}
      if((el=event.target.closest('[data-v461-val03-result-list]'))){event.preventDefault();event.stopImmediatePropagation();return navigate('SCR-014');}
    }
  },true);
  Object.assign(renderers, {
    'SCR-015': render015BJ03,
    'SCR-017': render017BJ03,
    'SCR-019': render019BJ03,
  });
})();


