/* BJ-03 — Xác lập giá trị nhập ban đầu (UIF-03). Màn: SCR-014, SCR-015, SCR-017, SCR-019.
 *
 * Đã viết lại sạch (T7-P gói A5, 2026-10-17). Sửa BJ-03: sửa thẳng file này (+ shared-valuation.js).
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
window.val03ApplySourceUpdate=val03ApplySourceUpdate;

val03Commit=function(){
  const r=val03Current(),selected=val03SelectedSlices(r),groups=[]; let totalValue=0;
  const productBootstrapTaken=new Set();
  for(const g of r.groups.filter(x=>selectedQty(x)>0)){
    const c=calc(g); if(!c) continue;
    const slices=[]; let groupValue=0;
    for(const s of g.slices.filter(x=>x.selected&&x.pendingQty>0)){
      const q=Math.min(Number(s.selectedQty)||0,s.pendingQty),amount=confirmationAmount(g,s,q),ad=val03SelectedAvailability(g,s);
      groupValue+=amount;
      slices.push({scopeKey:s.scopeKey,lot:s.lot,state:s.stateLabel,qty:q,value:amount,availabilityDelta:ad,availabilityNote:s.availabilityNote,businessDate:r.receivedAt});
    }
    let bootstrapStatus='NOT_APPLICABLE';
    if(g.officialCostStatus==='NONE'){
      if(!productBootstrapTaken.has(g.code)){bootstrapStatus='INITIALIZED';productBootstrapTaken.add(g.code);}
      else bootstrapStatus='ALREADY_INITIALIZED';
    }
    groups.push({name:g.name,code:g.code,uom:g.uom,baseUom:g.baseUom,receiptItemRef:g.receiptItemRef,basisKey:g.valuationBasisKey,basisHash:c.src.basisHash,tracking:g.tracking,qty:c.qty,value:groupValue,unitActual:c.unitActual,normalizedBaseCost:c.normalizedBaseCost,source:c.src.label,officialCostBootstrapStatus:bootstrapStatus,slices});
    totalValue+=groupValue;
  }
  val03LastResult={operationId:`VAL-260904-${String(val03OperationSeq++).padStart(3,'0')}`,receipt:r.receipt,supplier:r.supplier,businessDate:r.receivedAt,recordedAt:'16/09/2026 16:25',accountingPeriod:r.receivedAt.slice(3),groups,totalValue};
  for(const {group,slice} of selected){
    const q=Math.min(Number(slice.selectedQty)||0,slice.pendingQty),amount=confirmationAmount(group,slice,q);
    slice.pendingQty-=q; slice.confirmedQty=Number(slice.confirmedQty||0)+q; slice.confirmedValue=Number(slice.confirmedValue||0)+amount; slice.scopeVersion+=1; slice.selected=false; slice.partialOpen=false; slice.selectedQty=slice.pendingQty;
    if(group.officialCostStatus==='NONE') group.officialCostStatus='EXISTS';
  }
  val03ReviewSourceVersion=null; reviewTokens=null; return val03LastResult;
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

/* --- winning list renderers + listeners (from v430) --- */
(()=>{

  if(typeof renderers==='undefined') return;
  const VALUATION_FLOWS=new Set(['UIF-03','UIF-13','UIF-14']);
  const SCREEN_ALIAS={
    'UIF-03':{'SCR-016':'SCR-015'},
    'UIF-13':{'SCR-087':'SCR-086'},
    'UIF-14':{'SCR-073':'SCR-074','SCR-075':'SCR-074','SCR-076':'SCR-074'}
  };
  const money=n=>`${Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const signed=n=>`${Number(n||0)>0?'+ ':Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const qty=g=>(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).reduce((n,s)=>n+Number(s.pendingQty||0),0);
  const pendingGroups=r=>(r.groups||[]).filter(g=>qty(g)>0);
  const entryType=r=>r.v313EntryType||({VAL03_R2:'QUICK'}[r.id])||'DOCUMENT';
  const entryLabel=r=>entryType(r)==='QUICK'?'Nhập nhanh':'Theo chứng từ';
  const stable=value=>{let h=2166136261>>>0;for(const c of String(value)){h^=c.charCodeAt(0);h=Math.imul(h,16777619)>>>0;}return `fixture-v430-${h.toString(16)}`;};
  const row=args=>ds24ListRow({...args,density:args.density||'Compact'});
  const heading=(title,meta='')=>ds24SectionTitle(title,meta);
  const button=(label,attrs,kind='primary',disabled=false)=>`<button type="button" class="button button--${kind}" ${attrs} data-ds-component="VButton" data-figma-node="521:529" ${disabled?'disabled':''}>${esc(label)}</button>`;
  const linkButton=(label,attrs)=>`<button type="button" class="v430-link" ${attrs} data-ds-component="DS v2 / Link">${esc(label)}</button>`;
  const flatRows=(title,rows,extra='')=>`<section class="v430-flat ${extra}" data-composed-from="DS v2 / Info Row,DS v2 / Key-value Row">${title?heading(title):''}<div class="v430-flat__rows">${rows}</div></section>`;
  const keyRows=(rows,extra='')=>`<div class="v430-key-stack ${extra}" data-composed-from="DS v2 / Key-value Row">${rows}</div>`;
  const contextRow=(title,subtitle,badge='',tone='Neutral')=>row({title,subtitle,trailing:badge?ds24Badge(badge,tone):'',leading:null,type:'Status',interactive:false});
  const textField=(label,attrs,value='',helper='',required=false)=>`<label class="v430-field" data-ds-component="VTextField" data-figma-node="522:7186"><span>${esc(label)}${required?' <b>*</b>':''}</span><input class="v430-control" ${attrs} value="${escapeAttribute(value)}"/>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  const moneyField=(label,attrs,value='',helper='',required=false)=>`<label class="v430-field" data-ds-component="VMoneyField" data-figma-node="522:7322"><span>${esc(label)}${required?' <b>*</b>':''}</span><div class="v430-money"><input class="v430-control" inputmode="decimal" type="number" ${attrs} value="${escapeAttribute(value)}"/><span>đ</span></div>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  const textareaField=(label,attrs,value='',helper='',required=false)=>`<label class="v430-field" data-ds-component="VTextarea" data-figma-node="522:7212"><span>${esc(label)}${required?' <b>*</b>':''}</span><textarea class="v430-control v430-textarea" rows="3" ${attrs}>${esc(value)}</textarea>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  const selectField=(label,attrs,options)=>`<label class="v430-field" data-ds-component="VSelect" data-figma-node="522:7291"><span>${esc(label)}</span><select class="v430-control" ${attrs}>${options}</select></label>`;
  const formSheet=({title,intro,body,saveLabel='Lưu',saveAttr,closeAttr})=>`<div class="v430-overlay" data-v430-overlay><div class="v430-overlay__backdrop" ${closeAttr}></div><section class="v430-form-sheet" data-ds-component="DS v2 / Form Sheet" data-figma-node="1353:6355" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}"><div class="v430-sheet-handle-area"><div class="v430-sheet-handle"></div></div><header class="v430-sheet-header"><h2>${esc(title)}</h2><button type="button" class="v430-sheet-close" ${closeAttr} aria-label="Đóng" data-ds-component="DS v2 / Icon Button" data-figma-node="4431:10317">${icon('close','icon--sm')}</button></header>${intro?`<p class="v430-sheet-intro">${esc(intro)}</p>`:''}<div class="v430-form-sheet__body">${body}</div><footer class="v430-sheet-footer" data-ds-component="DS v2 / Sticky Footer" data-figma-node="549:927" data-ds-prop-layout="Single"><button type="button" class="button button--primary" ${saveAttr} data-ds-component="VButton" data-figma-node="521:529">${esc(saveLabel)}</button></footer></section></div>`;
  const confirmSheet=({title,desc,body,confirmLabel,confirmAttr,closeAttr})=>`<div class="sheet-backdrop ds24-overlay v430-confirm-overlay"><div class="v430-confirm-backdrop" ${closeAttr}></div><section class="ds24-confirmation v430-confirmation" data-ds-component="DS v2 / Confirmation Sheet" data-figma-node="550:1058" data-ds-prop-content="Plain" data-ds-prop-tone="Default" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}"><div class="ds24-confirmation__handle"></div><h3 class="vet45-text-style-4">${esc(title)}</h3><p class="vet45-text-style-6">${esc(desc)}</p>${body}<div class="ds24-confirmation__actions"><button type="button" class="ds24-button ds24-button--secondary" ${closeAttr} data-ds-component="VButton">Quay lại</button><button type="button" class="ds24-button ds24-button--primary" ${confirmAttr} data-ds-component="VButton">${esc(confirmLabel)}</button></div></section></div>`;
  const resultSummary=(title,body)=>ds24SummaryCard(title,body,'data-ds-prop-tone="Neutral"');

  // Hard-retire legacy valuation route nodes without deleting their historical evidence.

  // -------------------------------------------------------------------------
  // BJ03 — Xác lập giá trị nhập ban đầu
  // -------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // BJ13 — Điều chỉnh giá trị hàng nhập
  // -------------------------------------------------------------------------
  let val13Filter430='ALL';
  function val13Source430(t){return `${contextRow(t.sourceRef.replace(/ · dòng \d+$/,''),`${t.component} · ${t.supplier}`)}${keyRows(ds24KeyValueRow('Giá trị điều chỉnh',signed(t.normalizedAmount),true),'v430-source-amount')}`;}
  function val13Targets430(t){return (t.targets||[]).map(x=>row({title:x.product,subtitle:`${x.receipt} · ${x.qty} ${x.uom}${x.lot?` · Lô ${x.lot}`:''}`,trailing:t.targetScopeMode==='FIXED'?ds24Badge('Theo nguồn','Neutral'):(x.selected?icon('checkCircle','icon--sm'):''),leading:null,type:t.targetScopeMode==='FIXED'?'Status':'Selection',interactive:t.targetScopeMode!=='FIXED',state:x.selected?'Selected':'Default',attrs:t.targetScopeMode==='FIXED'?'':`data-v430-val13-target="${x.id}"`})).join('');}
  function val13Method430(t){const opts=`<option value="">Chọn cách phân bổ</option>`+(t.allowedMethods||[]).map(m=>`<option value="${m.id}" ${m.id===t.selectedMethod?'selected':''}>${esc(m.label)}</option>`).join('');return selectField('Cách phân bổ','data-v430-val13-method',opts);}
  function val13Preview430(t){const p=val13Preview(t);if(!p.length)return vBanner('info','Chưa có kết quả phân bổ','Chọn phạm vi và cách phân bổ để xem kết quả trước khi rà soát.','','Compact');return `<section class="v430-preview">${heading('Kết quả phân bổ',`${p.length} dòng`)}${keyRows(p.map(x=>ds24KeyValueRow(`${x.product} · ${x.receipt}`,signed(x.allocatedAmount))).join('')+ds24KeyValueRow('Tổng phân bổ',signed(p.reduce((n,x)=>n+x.allocatedAmount,0)),true))}</section>`;}
  function render085BJ13(state){if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-085'),state);if(state==='LOADING')return appShell({title:'Điều chỉnh giá trị hàng nhập',body:loadingBody(),centered:true,back:false});if(state==='PERMISSION_DENIED')return appShell({title:'Điều chỉnh giá trị hàng nhập',body:deniedBody(),centered:true,back:false});const q=String(val13Query||'').toLocaleLowerCase('vi'),tasks=val13Tasks.filter(t=>t.status!=='COMPLETED').filter(t=>!q||`${t.sourceRef} ${t.supplier} ${t.component}`.toLocaleLowerCase('vi').includes(q)).filter(t=>val13Filter430==='ALL'||(val13Filter430==='ACTIONABLE'&&t.status==='ACTIONABLE')||(val13Filter430==='WAITING'&&t.status==='WAITING')),rows=tasks.map(t=>row({title:t.sourceRef.replace(/ · dòng \d+$/,''),subtitle:`${t.component} · ${t.supplier} · ${signed(t.normalizedAmount)}`,trailing:t.status==='WAITING'?ds24Badge('Đang chờ','Neutral'):'',leading:null,type:'Navigation',attrs:`data-v430-val13-task="${t.id}"`})).join(''),body=`${ds24Search(val13Query,'data-v430-val13-search','Nguồn điều chỉnh hoặc đối tác')}<div class="ds24-chip-scroll">${ds24Chip('ALL','Tất cả',val13Filter430==='ALL','data-v430-val13-filter')}${ds24Chip('ACTIONABLE','Có thể xử lý',val13Filter430==='ACTIONABLE','data-v430-val13-filter')}${ds24Chip('WAITING','Đang chờ',val13Filter430==='WAITING','data-v430-val13-filter')}</div>${rows?`<section class="ds24-list-stack v430-list">${rows}</section>`:ioEmpty('Không có công việc phù hợp','Đổi từ khóa hoặc bộ lọc để xem công việc khác.')}`;return appShell({title:'Điều chỉnh giá trị hàng nhập',body,back:false});}

  // Latest valuation interaction layer. New data attributes avoid legacy handlers.
  window.addEventListener('input',event=>{
    if(activeFlowId==='UIF-03'&&event.target.matches('[data-v430-val03-search]')){val03Query=event.target.value;return renderAppScreen();}
    if(activeFlowId==='UIF-13'&&event.target.matches('[data-v430-val13-search]')){val13Query=event.target.value;return renderAppScreen();}
  },true);
  window.addEventListener('change',event=>{
    if(activeFlowId==='UIF-13'&&event.target.matches('[data-v430-val13-method]')){event.stopImmediatePropagation();const t=val13Current();if((t.allowedMethods||[]).some(m=>m.id===event.target.value)){t.selectedMethod=event.target.value;val13PreviewHash=null;}stateByScreen['SCR-086']='READY';return renderAppScreen();}
    if(activeFlowId==='UIF-14'&&event.target.matches('[data-v430-val14-period]')){event.stopImmediatePropagation();val14SetupPeriod=event.target.value;return renderAppScreen();}
    if(activeFlowId==='UIF-14'&&event.target.matches('[data-v430-val14-scope]')){event.stopImmediatePropagation();val14SetupScope=event.target.value;return renderAppScreen();}
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
    if(activeFlowId==='UIF-13'){
      if((el=event.target.closest('[data-v430-val13-filter]'))){event.preventDefault();event.stopImmediatePropagation();val13Filter430=el.dataset.v430Val13Filter;return renderAppScreen();}
      if((el=event.target.closest('[data-v430-val13-task]'))){event.preventDefault();event.stopImmediatePropagation();val13SelectedTaskId=el.dataset.v430Val13Task;val13ResetTaskDraft(val13Current());stateByScreen['SCR-086']='READY';return navigate('SCR-086');}
      if((el=event.target.closest('[data-v430-val13-target]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current(),line=(t.targets||[]).find(x=>x.id===el.dataset.v430Val13Target);if(line&&t.targetScopeMode!=='FIXED')line.selected=!line.selected;val13PreviewHash=null;return renderAppScreen();}
      if((el=event.target.closest('[data-v430-val13-review]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(!val13CanPreview(t)){stateByScreen['SCR-086']='VALIDATION_ERROR';return renderAppScreen();}val13ReviewSourceVersion=t.sourceVersion;val13PreviewHash=val13PreviewHashOf(t);stateByScreen['SCR-088']='READY';return navigate('SCR-088');}
      if((el=event.target.closest('[data-v430-val13-back]'))){event.preventDefault();event.stopImmediatePropagation();stateByScreen['SCR-086']='READY';return navigate('SCR-086');}
      if((el=event.target.closest('[data-v430-val13-confirm]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(Number(val13ReviewSourceVersion)!==Number(t.sourceVersion)||val13PreviewHash!==val13PreviewHashOf(t)){stateByScreen['SCR-088']='SOURCE_CHANGED';return renderAppScreen();}val13Commit();stateByScreen['SCR-089']='COMPLETED';return navigate('SCR-089');}
      if((el=event.target.closest('[data-v430-val13-list]'))){event.preventDefault();event.stopImmediatePropagation();val13Query='';val13Filter430='ALL';return navigate('SCR-085');}
    }
    if(activeFlowId==='UIF-14'){
      if((el=event.target.closest('[data-v430-val14-run]'))){event.preventDefault();event.stopImmediatePropagation();val14SelectedRunId=el.dataset.v430Val14Run;const r=enrich430(val14Current());val14Publish430=false;val14Compare430=false;if(r.status==='DIRTY'){val14SetupKind='AD_HOC';val14SetupPeriod=r.period;val14SetupScope='Sản phẩm cần tính lại';val14SuccessorOf=r.id;val14Mode430='DIRTY_SETUP';}else{val14Mode430='RESULT';stateByScreen['SCR-074']=r.status==='BLOCKED'?'BLOCKED':'READY';}return navigate('SCR-074');}
      if((el=event.target.closest('[data-v430-val14-close-period]'))){event.preventDefault();event.stopImmediatePropagation();val14SuccessorOf=null;val14SetupKind='PERIOD_CLOSE';val14SetupScope='Toàn bộ sản phẩm';val14Mode430='PERIOD_CLOSE_SETUP';return navigate('SCR-074');}
      if((el=event.target.closest('[data-v430-val14-calculate]'))){event.preventDefault();event.stopImmediatePropagation();val14SetupKind=val14Mode430==='DIRTY_SETUP'?'AD_HOC':'PERIOD_CLOSE';const run=val14CreateRun();enrich430(run);val14Mode430='RESULT';stateByScreen['SCR-074']='READY';return renderAppScreen();}
      if((el=event.target.closest('[data-v430-compare] summary'))){val14Compare430=!val14Compare430;return;}
      if((el=event.target.closest('[data-v430-val14-open-publish]'))){event.preventDefault();event.stopImmediatePropagation();const r=enrich430(val14Current());if(r.status!=='READY_FOR_REVIEW')return;val14PublishReviewVersion=r.runInputHash||String(r.inputVersion);val14Publish430=true;return renderAppScreen();}
      if((el=event.target.closest('[data-v430-val14-publish-close]'))){event.preventDefault();event.stopImmediatePropagation();val14Publish430=false;return renderAppScreen();}
      if((el=event.target.closest('[data-v430-val14-publish]'))){event.preventDefault();event.stopImmediatePropagation();const r=enrich430(val14Current());if(String(val14PublishReviewVersion)!==String(r.runInputHash||r.inputVersion)){r.status='INPUT_CHANGED';val14Publish430=false;stateByScreen['SCR-074']='INPUT_CHANGED';return renderAppScreen();}val14Commit();val14Publish430=false;stateByScreen['SCR-077']='COMPLETED';return navigate('SCR-077');}
      if((el=event.target.closest('[data-v430-val14-successor]'))){event.preventDefault();event.stopImmediatePropagation();const r=val14Current();val14SuccessorOf=r.id;val14SetupKind=r.kind;val14SetupPeriod=r.period;val14SetupScope=r.scopeOrigin==='DIRTY_SCOPE'?'Sản phẩm cần tính lại':'Toàn bộ sản phẩm';val14Mode430=r.scopeOrigin==='DIRTY_SCOPE'?'DIRTY_SETUP':'PERIOD_CLOSE_SETUP';return renderAppScreen();}
      if((el=event.target.closest('[data-v430-val14-list]'))){event.preventDefault();event.stopImmediatePropagation();val14Mode430='RESULT';val14Publish430=false;return navigate('SCR-072');}
    }
  },true);

  Object.assign(renderers, {
    'SCR-014': render014BJ03,
    'SCR-016': render015V430,
  });
  // expose for bj13 registration of SCR-085 (same IIFE scope — assign here too)
  Object.assign(renderers, { 'SCR-085': render085BJ13 });
  // expose commit
  val03Commit = val03Commit430;

})();

ownedFlows.add("UIF-03");

