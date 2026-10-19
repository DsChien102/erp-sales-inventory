/* BJ-13 — Điều chỉnh giá trị hàng nhập (UIF-13). Màn: SCR-085, SCR-086, SCR-089.
 *
 * Đã viết lại sạch (T7-P gói A5, 2026-10-17); tách đúng theo BJ ở A12 R7 (2026-10-19). Sửa BJ-13: sửa thẳng file này.
 * Màn dựng ở hai khối cuối: SCR-085 (bản v430), SCR-086 / 089 (bản v461; 087 / 088 là đường cũ). Helper val13* gán trong
 * khối chuẩn hoá v398; val13Engine dùng chung với BJ-14.
 */
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
function val13TaskSearchText(t){return ioNormalizeSearch(`${t.id} ${t.sourceRef} ${t.supplier} ${t.component}`);}
function val13QueueTitle(t){return String(t.sourceRef||"").replace(/^(Hóa đơn vận chuyển|Phí bảo hiểm|Điều chỉnh chiết khấu)\s+/i,"");}
function val13AllocationWeight(target,method){return method==="FIXTURE_QTY"?Math.max(0,Number(target.qty)||0):Math.max(0,Number(target.receivedValue)||0);}
// Helper BJ-13 — một định nghĩa duy nhất, gán trong khối v398 bên dưới (cần biến cục bộ của khối).
let val13SelectedTargets, val13Preview, val13PreviewHashOf, val13CanOpenAllocation, val13CanPreview, val13StatusMeta, val13ResetTaskDraft, val13SourceCard, val13TargetHtml, val13AllocationRows, val13PeriodCard, val13ReviewBody, val13Commit, val13Result, val13ApplySourceUpdate;
function val13DirtyScope(t=val13Current()){return [...new Map(val13Preview(t).map(x=>[`${x.product}|${x.uom}`,`${x.product} · ${x.uom}`])).values()];}

// ============================================================================

/* chuẩn hoá + helper thắng (v398) */
(()=>{
if(typeof val13Tasks==='undefined') return;

const fmtMoney=(n)=>`${Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
const stable=(v)=>{
  const s=typeof v==='string'?v:JSON.stringify(v,Object.keys(v||{}).sort());
  let h=2166136261>>>0; for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619)>>>0;}
  return `fixture-hash-${h.toString(16).padStart(8,'0')}`;
};
const stableObj=(obj)=>{
  if(Array.isArray(obj)) return obj.map(stableObj);
  if(obj&&typeof obj==='object') return Object.fromEntries(Object.keys(obj).sort().map(k=>[k,stableObj(obj[k])]));
  return obj;
};
const stableHash=(obj)=>stable(JSON.stringify(stableObj(obj)));

function periodForReceipt(receipt){
  if(/2608/.test(receipt)) return {businessDate:'21/08/2026',originalPeriod:'08/2026',postingPeriod:'09/2026',periodReason:'Kỳ gốc đã khóa; ghi điều chỉnh ở kỳ mở hiện tại'};
  if(/2609/.test(receipt)) return {businessDate:'02/09/2026',originalPeriod:'09/2026',postingPeriod:'09/2026',periodReason:'Kỳ gốc đang mở'};
  return {businessDate:'16/09/2026',originalPeriod:'09/2026',postingPeriod:'09/2026',periodReason:'Kỳ gốc đang mở'};
}

// Convert legacy fixtures into the v3.9.8 economic-source / valuation-exposure model.
for(const t of val13Tasks){
  t.sourceComponentKey=t.sourceComponentKey||`LCOMP-${t.id.replace('LC13-','')}`;
  t.operationId=t.operationId||`LC13-CMD-${t.sourceComponentKey}`;
  t.sourceRevision=Number(t.sourceVersion||1);
  t.accountingRoute=t.accountingRoute||'LATE';
  t.taxTreatmentVersion=t.taxTreatmentVersion||'TAX-v3';
  t.fxSourceVersion=t.currency==='VND'?'VND':(t.fxSourceVersion||'FX-ACCOUNTING-v7');
  t.targetScopeMode=t.targetScopeMode||'FIXED';
  t.targetScopeKey=t.targetScopeKey||`TS-${t.sourceComponentKey}`;
  t.targetScopeVersion=t.targetScopeVersion||'v1';
  for(const x of (t.targets||[])){
    const p=periodForReceipt(x.receipt||'');
    x.initialValued=x.initialValued!==false;
    x.receiptItemRef=x.receiptItemRef||`${x.receipt}-ITEM-${x.lineId}`;
    x.valuationExposureKey=x.valuationExposureKey||`VE-${x.lineId}`;
    x.exposureVersion=Number(x.exposureVersion||1);
    x.baseQty=Number(x.baseQty||x.qty||0);
    x.initialDirectValue=Number(x.initialDirectValue??x.receivedValue??0);
    x.businessDate=x.businessDate||p.businessDate;
    x.originalPeriod=x.originalPeriod||p.originalPeriod;
    x.postingPeriod=x.postingPeriod||p.postingPeriod;
    x.periodReason=x.periodReason||p.periodReason;
    x.receiptValuationRefs=x.receiptValuationRefs||[`RV-${x.lineId}-1`];
    x.exposureHash=stableHash({key:x.valuationExposureKey,version:x.exposureVersion,qty:x.baseQty,value:x.initialDirectValue,refs:x.receiptValuationRefs,businessDate:x.businessDate,original:x.originalPeriod,posting:x.postingPeriod});
    x.selected=t.targetScopeMode==='FIXED'?true:(x.selected!==false);
  }
  t.targetScopeHash=stableHash({key:t.targetScopeKey,version:t.targetScopeVersion,members:(t.targets||[]).map(x=>x.valuationExposureKey).sort()});
}

// Add a representative late-route component that must wait for initial valuation.
if(!val13Tasks.some(t=>t.id==='LC13-005')){
  val13Tasks.push({id:'LC13-005',sourceRef:'Phí kiểm định QC-2609-22 · dòng 1',sourceVersion:1,sourceRevision:1,sourceComponentKey:'LCOMP-QC-2609-22-1',accountingRoute:'LATE',supplier:'Trung tâm kiểm định',component:'Phí kiểm định hàng mua',sourceAmount:420000,currency:'VND',normalizedAmount:420000,fxLabel:'VND',status:'WAITING',waitingOwner:'Chờ xác nhận giá ban đầu của 1 dòng',taxTreatmentVersion:'TAX-v3',fxSourceVersion:'VND',targetScopeMode:'FIXED',targetScopeKey:'TS-LCOMP-QC-2609-22-1',targetScopeVersion:'v1',policyVersion:'ALC-POL-v5',allowedMethods:[],selectedMethod:'',targets:[{id:'LC13-T8',receipt:'PN-260915-02',lineId:'ROL-702',product:'Oxytetracycline 20%',code:'SP-00702',uom:'chai',lot:null,qty:20,baseQty:20,initialDirectValue:0,initialValued:false,receiptItemRef:'PN-260915-02-ITEM-ROL-702',valuationExposureKey:'VE-ROL-702',exposureVersion:1,businessDate:'15/09/2026',originalPeriod:'09/2026',postingPeriod:'09/2026',periodReason:'Kỳ gốc đang mở',receiptValuationRefs:[],selected:true}]});
  const t=val13Tasks[val13Tasks.length-1],x=t.targets[0];x.exposureHash=stableHash({key:x.valuationExposureKey,version:1,qty:x.baseQty,value:0,refs:[],businessDate:x.businessDate,original:x.originalPeriod,posting:x.postingPeriod});t.targetScopeHash=stableHash({key:t.targetScopeKey,version:t.targetScopeVersion,members:[x.valuationExposureKey]});
}

function selectedTargets(t=val13Current()){
  return (t.targets||[]).filter(x=>t.targetScopeMode==='FIXED'?true:x.selected);
}
function metricSnapshot(t,x,method=t.selectedMethod){
  const quantityMethod=method==='FIXTURE_QTY';
  const value=quantityMethod?Math.max(0,Number(x.quantityMetricValue)||0):Math.max(0,Number(x.initialDirectValue)||0);
  const unit=quantityMethod?(x.quantityMetricUnit||''):'initial_valuation_value_vnd';
  const version=quantityMethod?(x.quantityMetricVersion||'METRIC-QTY-v2'):'METRIC-INITIAL-VALUE-v2';
  return {method,metricValue:value,unit,metricVersion:version,metricHash:stableHash({exposure:x.valuationExposureKey,method,value,unit,version})};
}
function methodEligible(t,method=t.selectedMethod){
  const targets=selectedTargets(t);if(!targets.length)return false;
  const metrics=targets.map(x=>metricSnapshot(t,x,method));
  if(method==='FIXTURE_QTY'){const units=new Set(metrics.map(m=>m.unit).filter(Boolean));if(units.size!==1||metrics.some(m=>!m.unit))return false;}
  return metrics.reduce((n,m)=>n+m.metricValue,0)>0;
}
function lateCostBasisPayload(t=val13Current()){
  const targets=selectedTargets(t).slice().sort((a,b)=>a.valuationExposureKey.localeCompare(b.valuationExposureKey));
  return {sourceComponentKey:t.sourceComponentKey,sourceRevision:Number(t.sourceVersion||t.sourceRevision||1),sourceRef:t.sourceRef,sourceAmount:t.sourceAmount,currency:t.currency,normalizedAmount:t.normalizedAmount,taxTreatmentVersion:t.taxTreatmentVersion,fxSourceVersion:t.fxSourceVersion,fxRate:t.fxRate||1,accountingRoute:t.accountingRoute,policyVersion:t.policyVersion,method:t.selectedMethod,targetScopeKey:t.targetScopeKey,targetScopeVersion:t.targetScopeVersion,targetScopeHash:t.targetScopeHash,exposures:targets.map(x=>({key:x.valuationExposureKey,version:x.exposureVersion,hash:x.exposureHash,metric:metricSnapshot(t,x),businessDate:x.businessDate,originalPeriod:x.originalPeriod,postingPeriod:x.postingPeriod}))};
}
function lateCostBasisHash(t=val13Current()){return stableHash(lateCostBasisPayload(t));}
function allocate(t=val13Current()){
  const selected=selectedTargets(t).slice().sort((a,b)=>a.valuationExposureKey.localeCompare(b.valuationExposureKey));
  const total=Number(t.normalizedAmount||0); if(!selected.length||t.normalizedAmount==null||!t.selectedMethod)return [];
  const metrics=selected.map(x=>metricSnapshot(t,x));
  const weightTotal=metrics.reduce((n,m)=>n+m.metricValue,0); if(weightTotal<=0||!methodEligible(t,t.selectedMethod))return [];
  const amounts=new Map(); let used=0;
  selected.forEach((x,i)=>{
    const weight=metrics[i].metricValue;
    const amount=i===selected.length-1?total-used:Math.round(total*(weight/weightTotal));
    used+=amount; amounts.set(x.valuationExposureKey,{amount,metric:metrics[i],ratio:weight/weightTotal});
  });
  return selected.map((x,i)=>({...x,allocatedAmount:amounts.get(x.valuationExposureKey).amount,allocationMetric:amounts.get(x.valuationExposureKey).metric,roundingAdjustment:i===selected.length-1?total-selected.slice(0,-1).reduce((n,y)=>n+amounts.get(y.valuationExposureKey).amount,0)-amounts.get(x.valuationExposureKey).amount:0}));
}
function allocationHash(t=val13Current()){
  return stableHash(allocate(t).map(x=>({key:x.valuationExposureKey,amount:x.allocatedAmount,metricHash:x.allocationMetric.metricHash,original:x.originalPeriod,posting:x.postingPeriod})));
}
function combinedPreviewHash(t=val13Current()){return `${lateCostBasisHash(t)}|${allocationHash(t)}`;}
function dirtyScopes(t=val13Current()){
  const m=new Map(); for(const x of allocate(t)){const k=`${x.code}|${x.postingPeriod}`;m.set(k,{product:x.product,code:x.code,postingPeriod:x.postingPeriod,label:`${x.product} · ${x.postingPeriod}`});} return [...m.values()];
}
function periodGroups(t=val13Current()){
  const map=new Map(); for(const x of allocate(t)){const k=x.postingPeriod;const g=map.get(k)||{postingPeriod:k,originalPeriods:new Set(),reason:new Set(),count:0};g.originalPeriods.add(x.originalPeriod);if(x.periodReason)g.reason.add(x.periodReason);g.count++;map.set(k,g);}return [...map.values()].map(g=>({...g,originalPeriods:[...g.originalPeriods],reason:[...g.reason]}));
}
function allInitialValued(t=val13Current()){return selectedTargets(t).every(x=>x.initialValued);}
function canOpen(t=val13Current()){return t.status==='ACTIONABLE'&&t.accountingRoute==='LATE'&&t.normalizedAmount!=null&&selectedTargets(t).length>0&&allInitialValued(t);}
function canPreview(t=val13Current()){return canOpen(t)&&t.allowedMethods.some(m=>m.id===t.selectedMethod)&&methodEligible(t,t.selectedMethod)&&allocate(t).length>0;}

val13SelectedTargets=selectedTargets;
val13AllocationWeight=(target,method)=>metricSnapshot(val13Current(),target,method).metricValue;
val13Preview=allocate;
val13PreviewHashOf=combinedPreviewHash;
val13CanOpenAllocation=canOpen;
val13CanPreview=canPreview;
val13DirtyScope=(t=val13Current())=>dirtyScopes(t).map(x=>x.label);
val13StatusMeta=function(t){if(t.status==='WAITING')return [t.waitingOwner||'Đang chờ','neutral'];return ['', 'neutral'];};
val13ResetTaskDraft=function(t){for(const x of (t.targets||[]))x.selected=true;const eligible=(t.allowedMethods||[]).filter(m=>methodEligible(t,m.id));t.selectedMethod=eligible.length===1?eligible[0].id:(eligible.some(m=>m.id===t.selectedMethod)?t.selectedMethod:'');val13ReviewSourceVersion=null;val13PreviewHash=null;val13LastSourceChange=null;};
val13SourceCard=function(t){
  const context=ds24ContextStatusRow({title:t.sourceRef,subtitle:`${t.component} · ${t.supplier}`,label:t.status==='WAITING'?'Đang chờ':'',tone:'neutral',leading:null});
  const facts=`${ds24InfoRow('Giá trị nguồn',val13FmtSourceAmount(t))}${t.currency!=='VND'&&t.fxLabel?ds24InfoRow('Tỷ giá',t.fxLabel):''}${t.normalizedAmount!=null?ds24KeyValueRow('Sau chuẩn hóa',val13FmtMoney(t.normalizedAmount),true):''}`;
  return `${context}${ds24InfoGroup('Chi tiết nguồn',facts,'valuation-info-group valuation-info-group--wrap val13-source-card')}`;
};
val13TargetHtml=function(t){
  const fixed=t.targetScopeMode==='FIXED';
  return (t.targets||[]).map(x=>{
    const subtitle=`${x.receipt} · ${x.code} · ${x.qty} ${x.uom}${x.lot?` · Lô ${x.lot}`:''}`;
    if(fixed)return `<div class="val13-target-row is-selected v398-fixed-scope" data-valuation-exposure="${esc(x.valuationExposureKey)}" data-composed-from="VText"><span class="valuation-selection-control val13-check-mark" aria-hidden="true">${icon('check','icon--xs')}</span><span class="val13-target-copy"><strong>${esc(x.product)}</strong><small>${esc(subtitle)}</small></span></div>`;
    return `<button type="button" class="val13-target-row ${x.selected?'is-selected':''}" data-val13-target="${x.id}" data-valuation-exposure="${esc(x.valuationExposureKey)}" aria-pressed="${x.selected}" data-composed-from="VCheckbox,VText"><span class="valuation-selection-control val13-check-mark" aria-hidden="true">${x.selected?icon('check','icon--xs'):''}</span><span class="val13-target-copy"><strong>${esc(x.product)}</strong><small>${esc(subtitle)}</small></span></button>`;
  }).join('');
};
val13AllocationRows=function(t=val13Current()){
  return allocate(t).map(x=>`<div class="val13-allocation-row valuation-allocation-row" data-valuation-exposure="${esc(x.valuationExposureKey)}" data-composed-from="VText"><span><strong>${esc(x.product)}</strong><small>${esc(x.receipt)} · ${x.qty} ${esc(x.uom)}${x.lot?` · Lô ${esc(x.lot)}`:''}</small></span><strong class="valuation-amount">${esc(val13FmtMoney(x.allocatedAmount))}</strong></div>`).join('');
};
val13PeriodCard=function(t){
  const groups=periodGroups(t); if(!groups.length)return '';
  const rows=groups.map(g=>ds24InfoRow(`Ghi nhận ${g.postingPeriod}`,g.originalPeriods.length===1&&g.originalPeriods[0]===g.postingPeriod?`${g.count} dòng · cùng kỳ`:`${g.count} dòng · từ kỳ ${g.originalPeriods.join(', ')}`)).join('');
  const moved=groups.some(g=>g.originalPeriods.some(p=>p!==g.postingPeriod));
  return `${moved?vBanner('info','Có chi phí ghi ở kỳ mở','Kỳ gốc đã khóa vẫn được giữ để truy vết; adjustment được ghi ở kỳ mở theo policy.') : ''}${ds24InfoGroup('Kỳ ghi nhận',rows,'valuation-info-group')}`;
};
val13ReviewBody=function(t){
  const rows=allocate(t),method=t.allowedMethods.find(m=>m.id===t.selectedMethod)?.label||'—',total=rows.reduce((n,x)=>n+x.allocatedAmount,0);
  const allocation=`${ds24SectionTitle('Phân bổ sẽ ghi',`${rows.length} dòng`)}${ds24GroupedCollection(`${val13AllocationRows(t)}<div class="valuation-total-strip valuation-total-strip--inside">${ds24KeyValueRow('Tổng phân bổ',val13FmtMoney(total),true)}</div>`,'valuation-allocation-collection val13-review-group','VText,DS v2 / Key-value Row')}`;
  const basis=ds24InfoGroup('Căn cứ phân bổ',`${ds24KeyValueRow('Chi phí sẽ ghi',val13FmtMoney(t.normalizedAmount),true)}${ds24InfoRow('Phương pháp',method)}`,'valuation-info-group');
  const effects=ds24InfoGroup('Sau khi ghi',`${ds24InfoRow('Cần tính lại',dirtyScopes(t).map(x=>x.label).join('; ')||'—')}`,'valuation-info-group valuation-info-group--wrap');
  return `${val13SourceCard(t)}${basis}${allocation}${val13PeriodCard(t)}${effects}`;
};
val13Commit=function(){
  const t=val13Current(),rows=allocate(t),groups=periodGroups(t),basisHash=lateCostBasisHash(t),allocHash=allocationHash(t);
  const adjustmentBatches=groups.map((g,i)=>({id:`LC13-ADJ-${String(val13OperationSeq).padStart(3,'0')}-${i+1}`,postingPeriod:g.postingPeriod,originalPeriods:g.originalPeriods,allocationCount:g.count}));
  val13LastResult={operationId:t.operationId,taskId:t.id,sourceComponentKey:t.sourceComponentKey,sourceRevision:Number(t.sourceVersion||1),sourceRef:t.sourceRef,component:t.component,normalizedAmount:t.normalizedAmount,allocations:rows.map(x=>({...x})),dirtyScope:dirtyScopes(t),periodGroups:groups,adjustmentBatches,lateCostBasisHash:basisHash,allocationHash:allocHash};
  t.status='COMPLETED';return val13LastResult;
};
val13Result=function(){const t=val13Current();return val13LastResult||{operationId:t.operationId,taskId:t.id,sourceComponentKey:t.sourceComponentKey,sourceRevision:Number(t.sourceVersion||1),sourceRef:t.sourceRef,component:t.component,normalizedAmount:t.normalizedAmount,allocations:allocate(t),dirtyScope:dirtyScopes(t),periodGroups:periodGroups(t),adjustmentBatches:[],lateCostBasisHash:lateCostBasisHash(t),allocationHash:allocationHash(t)};};
val13ApplySourceUpdate=function(){const t=val13Current();if(t.status!=='ACTIONABLE')return;t.sourceVersion=Number(t.sourceVersion||1)+1;t.sourceRevision=t.sourceVersion;const before=t.normalizedAmount;t.normalizedAmount=Number(t.normalizedAmount||0)+100000;val13LastSourceChange={from:val13FmtMoney(before),to:val13FmtMoney(t.normalizedAmount),version:t.sourceVersion};if(activeScreenId==='SCR-088')stateByScreen['SCR-088']='SOURCE_CHANGED';render();};

const val13Engine={lateCostBasisPayload,lateCostBasisHash,allocationHash,combinedPreviewHash,metricSnapshot,methodEligible,allocate,dirtyScopes,periodGroups,allInitialValued,economicIdentity:(t=val13Current())=>t.sourceComponentKey,touchExposure:(id)=>{const t=val13Current(),x=t.targets.find(y=>y.id===id);if(!x)return false;x.exposureVersion+=1;x.exposureHash=stableHash({key:x.valuationExposureKey,version:x.exposureVersion,qty:x.baseQty,value:x.initialDirectValue,refs:x.receiptValuationRefs,businessDate:x.businessDate,original:x.originalPeriod,posting:x.postingPeriod});return true;},shuffleTargets:(t=val13Current())=>{t.targets.reverse();return true;}};
window.val13Engine=val13Engine;
})();
var val13Engine=window.val13Engine;

screenAliases["UIF-13"] = Object.assign(screenAliases["UIF-13"] || {}, {
  "SCR-087": "SCR-086",
  "SCR-088": "SCR-086",
});
{ const a = screenAliases[activeFlowId]?.[activeScreenId]; if (Array.isArray(a)) { activeFlowId = a[0]; activeScreenId = a[1]; } else if (a) activeScreenId = a; }




/* --- SCR-085 (danh sách — bản v430) — BJ-13 --- */
(()=>{
  const {signed, row, heading, keyRows, contextRow, selectField}=VAL_UI_430;
  let val13Filter430='ALL';
  function val13Source430(t){return `${contextRow(t.sourceRef.replace(/ · dòng \d+$/,''),`${t.component} · ${t.supplier}`)}${keyRows(ds24KeyValueRow('Giá trị điều chỉnh',signed(t.normalizedAmount),true),'v430-source-amount')}`;}
  function val13Targets430(t){return (t.targets||[]).map(x=>row({title:x.product,subtitle:`${x.receipt} · ${x.qty} ${x.uom}${x.lot?` · Lô ${x.lot}`:''}`,trailing:t.targetScopeMode==='FIXED'?ds24Badge('Theo nguồn','Neutral'):(x.selected?icon('checkCircle','icon--sm'):''),leading:null,type:t.targetScopeMode==='FIXED'?'Status':'Selection',interactive:t.targetScopeMode!=='FIXED',state:x.selected?'Selected':'Default',attrs:t.targetScopeMode==='FIXED'?'':`data-v430-val13-target="${x.id}"`})).join('');}
  function val13Method430(t){const opts=`<option value="">Chọn cách phân bổ</option>`+(t.allowedMethods||[]).map(m=>`<option value="${m.id}" ${m.id===t.selectedMethod?'selected':''}>${esc(m.label)}</option>`).join('');return selectField('Cách phân bổ','data-v430-val13-method',opts);}
  function val13Preview430(t){const p=val13Preview(t);if(!p.length)return vBanner('info','Chưa có kết quả phân bổ','Chọn phạm vi và cách phân bổ để xem kết quả trước khi rà soát.','','Compact');return `<section class="v430-preview">${heading('Kết quả phân bổ',`${p.length} dòng`)}${keyRows(p.map(x=>ds24KeyValueRow(`${x.product} · ${x.receipt}`,signed(x.allocatedAmount))).join('')+ds24KeyValueRow('Tổng phân bổ',signed(p.reduce((n,x)=>n+x.allocatedAmount,0)),true))}</section>`;}
  function render085BJ13(state){if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-085'),state);if(state==='LOADING')return appShell({title:'Điều chỉnh giá trị hàng nhập',body:loadingBody(),centered:true,back:false});if(state==='PERMISSION_DENIED')return appShell({title:'Điều chỉnh giá trị hàng nhập',body:deniedBody(),centered:true,back:false});const q=String(val13Query||'').toLocaleLowerCase('vi'),tasks=val13Tasks.filter(t=>t.status!=='COMPLETED').filter(t=>!q||`${t.sourceRef} ${t.supplier} ${t.component}`.toLocaleLowerCase('vi').includes(q)).filter(t=>val13Filter430==='ALL'||(val13Filter430==='ACTIONABLE'&&t.status==='ACTIONABLE')||(val13Filter430==='WAITING'&&t.status==='WAITING')),rows=tasks.map(t=>row({title:t.sourceRef.replace(/ · dòng \d+$/,''),subtitle:`${t.component} · ${t.supplier} · ${signed(t.normalizedAmount)}`,trailing:t.status==='WAITING'?ds24Badge('Đang chờ','Neutral'):'',leading:null,type:'Navigation',attrs:`data-v430-val13-task="${t.id}"`})).join(''),body=`${ds24Search(val13Query,'data-v430-val13-search','Nguồn điều chỉnh hoặc đối tác')}<div class="ds24-chip-scroll">${ds24Chip('ALL','Tất cả',val13Filter430==='ALL','data-v430-val13-filter')}${ds24Chip('ACTIONABLE','Có thể xử lý',val13Filter430==='ACTIONABLE','data-v430-val13-filter')}${ds24Chip('WAITING','Đang chờ',val13Filter430==='WAITING','data-v430-val13-filter')}</div>${rows?`<section class="ds24-list-stack v430-list">${rows}</section>`:ioEmpty('Không có công việc phù hợp','Đổi từ khóa hoặc bộ lọc để xem công việc khác.')}`;return appShell({title:'Điều chỉnh giá trị hàng nhập',body,back:false});}

  window.addEventListener('input',event=>{
    if(activeFlowId==='UIF-13'&&event.target.matches('[data-v430-val13-search]')){val13Query=event.target.value;return renderAppScreen();}
  },true);
  window.addEventListener('change',event=>{
    if(activeFlowId==='UIF-13'&&event.target.matches('[data-v430-val13-method]')){event.stopImmediatePropagation();const t=val13Current();if((t.allowedMethods||[]).some(m=>m.id===event.target.value)){t.selectedMethod=event.target.value;val13PreviewHash=null;}stateByScreen['SCR-086']='READY';return renderAppScreen();}
  },true);
  window.addEventListener('click',event=>{
    let el;
    if(activeFlowId==='UIF-13'){
      if((el=event.target.closest('[data-v430-val13-filter]'))){event.preventDefault();event.stopImmediatePropagation();val13Filter430=el.dataset.v430Val13Filter;return renderAppScreen();}
      if((el=event.target.closest('[data-v430-val13-task]'))){event.preventDefault();event.stopImmediatePropagation();val13SelectedTaskId=el.dataset.v430Val13Task;val13ResetTaskDraft(val13Current());stateByScreen['SCR-086']='READY';return navigate('SCR-086');}
      if((el=event.target.closest('[data-v430-val13-target]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current(),line=(t.targets||[]).find(x=>x.id===el.dataset.v430Val13Target);if(line&&t.targetScopeMode!=='FIXED')line.selected=!line.selected;val13PreviewHash=null;return renderAppScreen();}
      if((el=event.target.closest('[data-v430-val13-review]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(!val13CanPreview(t)){stateByScreen['SCR-086']='VALIDATION_ERROR';return renderAppScreen();}val13ReviewSourceVersion=t.sourceVersion;val13PreviewHash=val13PreviewHashOf(t);stateByScreen['SCR-088']='READY';return navigate('SCR-088');}
      if((el=event.target.closest('[data-v430-val13-back]'))){event.preventDefault();event.stopImmediatePropagation();stateByScreen['SCR-086']='READY';return navigate('SCR-086');}
      if((el=event.target.closest('[data-v430-val13-confirm]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(Number(val13ReviewSourceVersion)!==Number(t.sourceVersion)||val13PreviewHash!==val13PreviewHashOf(t)){stateByScreen['SCR-088']='SOURCE_CHANGED';return renderAppScreen();}val13Commit();stateByScreen['SCR-089']='COMPLETED';return navigate('SCR-089');}
      if((el=event.target.closest('[data-v430-val13-list]'))){event.preventDefault();event.stopImmediatePropagation();val13Query='';val13Filter430='ALL';return navigate('SCR-085');}
    }
  },true);
  Object.assign(renderers, { 'SCR-085': render085BJ13 });
})();

/* --- SCR-086 / 089 (phân bổ, kết quả — bản v461) — BJ-13 --- */
(()=>{
  const {money, signed, pct, row, heading, flat, keys, context, button, confirmSheet}=VAL_UI_461;
  let confirm13=false,detail13=false;
  const eligibleMethods=t=>(t.allowedMethods||[]).filter(m=>val13Engine?.methodEligible?val13Engine.methodEligible(t,m.id):true);
  const methodLabel=(t,id=t.selectedMethod)=>eligibleMethods(t).find(m=>m.id===id)?.label||(t.allowedMethods||[]).find(m=>m.id===id)?.label||'—';
  const selectedTargets13=t=>(t.targets||[]).filter(x=>t.targetScopeMode==='FIXED'||x.selected);
  function allocationRows13(t){const rows=val13Preview(t),sum=rows.reduce((n,x)=>n+Number(x.allocationMetric?.metricValue||0),0);return rows.map(x=>{const metric=Number(x.allocationMetric?.metricValue||0),metricText=t.selectedMethod==='FIXTURE_VALUE'?`${money(metric)} · ${pct(sum?metric/sum:0)}`:`${metric.toLocaleString('vi-VN')} ${x.allocationMetric?.unit||''} · ${pct(sum?metric/sum:0)}`;return `<div class="v460-allocation-row" data-composed-from="VText,DS v2 / Key-value Row"><div><strong>${esc(x.product)}</strong><small>${esc(x.receipt)} · ${x.qty} ${esc(x.uom)}${x.lot?` · Lô ${esc(x.lot)}`:''}</small><small>Căn cứ phân bổ: ${esc(metricText)}</small></div><strong>${esc(signed(x.allocatedAmount))}</strong></div>`;}).join('');}
  function methodControl13(t){const methods=eligibleMethods(t);if(methods.length<=1){const m=methods[0];if(!m)return flat('Cách phân bổ',ds24InfoRow('Phương pháp','Chưa có phương pháp hợp lệ'),'v460-method-readonly');const desc=m.id==='FIXTURE_VALUE'?'Phân bổ theo tỷ trọng giá trị nhập ban đầu của từng sản phẩm, trước các điều chỉnh phát sinh sau đó.':'Chỉ dùng khi toàn bộ phạm vi có chỉ tiêu lượng chuẩn cùng đơn vị và có thể so sánh.';return `<section class="v460-methods v460-method-readonly">${heading('Cách phân bổ')}<div class="v460-method-summary" data-composed-from="VText,DS v2 / Summary Card"><strong>${esc(m.label)}</strong><span>${esc(desc)}</span></div></section>`;}return `<section class="v460-methods">${heading('Cách phân bổ')}<div class="v460-choice-list">${methods.map(m=>`<button type="button" class="v460-choice ${t.selectedMethod===m.id?'is-selected':''}" data-v461-val13-method="${m.id}" data-ds-component="VRadio" aria-pressed="${t.selectedMethod===m.id}"><span class="v460-choice__radio"><span></span></span><span><strong>${esc(m.label)}</strong><small>${m.id==='FIXTURE_VALUE'?'Phân bổ theo tỷ trọng giá trị nhập ban đầu của từng sản phẩm':'Chỉ dùng khi toàn bộ phạm vi có chỉ tiêu lượng chuẩn cùng đơn vị'}</small></span></button>`).join('')}</div></section>`;}
  function period13(t){const targets=selectedTargets13(t),posting=[...new Set(targets.map(x=>x.postingPeriod).filter(Boolean))],original=[...new Set(targets.map(x=>x.originalPeriod).filter(Boolean))],moved=targets.some(x=>x.originalPeriod&&x.postingPeriod&&x.originalPeriod!==x.postingPeriod);if(!posting.length)return '';if(!moved&&posting.length===1)return flat('Kỳ ghi nhận',ds24InfoRow('Kỳ ghi điều chỉnh',posting[0]));const originalLabel=original.join(', ')||'—',postingLabel=posting.join(', ')||'—';return `${vBanner('info','Kỳ của hàng gốc đã khóa',`Điều chỉnh được ghi ở kỳ ${postingLabel}; kỳ ${originalLabel} vẫn được giữ để truy vết.`)}${flat('Kỳ ghi nhận',`${ds24InfoRow('Kỳ của hàng gốc',originalLabel)}${ds24InfoRow('Kỳ ghi điều chỉnh',postingLabel)}`)}`;}
  function render086BJ13(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-086'),state);const t=val13Current();if(state==='LOADING')return appShell({title:'Phân bổ điều chỉnh giá trị',body:loadingBody(),centered:true});if(state==='PERMISSION_DENIED')return appShell({title:'Phân bổ điều chỉnh giá trị',body:deniedBody(),centered:true});if(t.status==='WAITING')return appShell({title:'Phân bổ điều chỉnh giá trị',body:`${vBanner('info','Chưa thể xử lý',t.waitingOwner||'Đang chờ nguồn hoàn tất dữ liệu cần thiết.')}${context(t.sourceRef.replace(/ · dòng \d+$/,''),`${t.component} · ${t.supplier}`)}`});
    const methods=eligibleMethods(t);if(methods.length===1&&t.selectedMethod!==methods[0].id){t.selectedMethod=methods[0].id;val13PreviewHash=null;}const preview=val13Preview(t),total=preview.reduce((n,x)=>n+Number(x.allocatedAmount||0),0),targets=(t.targets||[]).map(x=>row({title:x.product,subtitle:`${x.receipt} · ${x.qty} ${x.uom}${x.lot?` · Lô ${x.lot}`:''}`,trailing:'',leading:null,type:'Status',interactive:false})).join(''),valid=val13CanPreview(t)&&preview.length>0;
    const source=`${context(t.sourceRef.replace(/ · dòng \d+$/,''),`${t.component} · ${t.supplier}`)}${keys(ds24KeyValueRow('Giá trị điều chỉnh',signed(t.normalizedAmount),true))}`;
    const allocation=valid?`${heading('Kết quả phân bổ',`${preview.length} sản phẩm`)}<section class="v460-allocation-list">${allocationRows13(t)}${ds24KeyValueRow('Tổng phân bổ',signed(total),true)}</section>`:vBanner('warning','Chưa có phương pháp phân bổ hợp lệ','Cần metric hợp lệ và so sánh được trên toàn phạm vi; hệ thống không tự chia đều.');
    const body=`${state==='SOURCE_CHANGED'?vBanner('warning','Nguồn điều chỉnh đã thay đổi','Kiểm tra lại dữ liệu hiện hành trước khi ghi.'):''}${source}${heading('Phạm vi áp dụng','Theo nguồn xác định')}<section class="ds24-list-stack v430-list">${targets}</section>${methodControl13(t)}${allocation}${period13(t)}${confirm13?confirmSheet({title:'Ghi điều chỉnh giá trị?',desc:'Kiểm tra lại tổng tiền, phạm vi, cách phân bổ và kỳ ghi nhận trước khi ghi.',body:flat('Xác nhận',`${ds24InfoRow('Nguồn',t.sourceRef.replace(/ · dòng \d+$/,''))}${ds24InfoRow('Sản phẩm',String(preview.length))}${ds24InfoRow('Cách phân bổ',methodLabel(t))}${ds24InfoRow('Kỳ ghi nhận',[...new Set(preview.map(x=>x.postingPeriod))].join(', ')||'—')}${ds24KeyValueRow('Tổng điều chỉnh',signed(total),true)}`),confirmLabel:'Ghi điều chỉnh',confirmAttr:'data-v461-val13-confirm',closeAttr:'data-v461-val13-confirm-close'}):''}`;
    return appShell({title:'Phân bổ điều chỉnh giá trị',body,actions:primaryFooter('Ghi điều chỉnh','data-v461-val13-open-confirm',!valid)});
  }
  function render089BJ13(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-089'),state);const t=val13Current(),res=val13LastResult||val13Result();if(state==='PROCESSING')return appShell({title:'Kết quả điều chỉnh giá trị',body:loadingBody(),centered:true,back:false});if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-13" data-operation="${escapeAttribute(res.operationId||t.operationId)}" data-scope="${escapeAttribute(t.sourceComponentKey||t.id)}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định điều chỉnh đã được ghi hay chưa','Không ghi lại adjustment. Chuyển đúng thao tác này sang xác minh.',[['Nguồn',t.sourceRef],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả điều chỉnh giá trị',body:ioResult('Chưa ghi điều chỉnh','Không có thay đổi giá trị.',[['Nguồn',t.sourceRef],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại phân bổ','data-v461-val13-back')});
    const allocations=res.allocations||[],periods=[...new Set(allocations.map(x=>x.postingPeriod).filter(Boolean))],detailRows=allocations.map(x=>row({title:x.product,subtitle:`${x.receipt} · ${x.qty} ${x.uom}`,trailing:`<strong class="v460-money-trailing">${signed(x.allocatedAmount)}</strong>`,leading:null,type:'Status',interactive:false})).join('');
    const summary=flat('Kết quả',`${ds24InfoRow('Nguồn',String(res.sourceRef||t.sourceRef).replace(/ · dòng \d+$/,''))}${ds24InfoRow('Sản phẩm bị ảnh hưởng',String(allocations.length))}${ds24InfoRow('Kỳ ghi nhận',periods.join(', ')||'—')}${ds24InfoRow('Giá vốn','Cần cập nhật')}${ds24KeyValueRow('Tổng điều chỉnh',signed(res.normalizedAmount??t.normalizedAmount),true)}`),details=detailRows?`<details class="v430-details v460-details" ${detail13?'open':''}><summary>Xem chi tiết phân bổ (${allocations.length})</summary><div class="v430-details__body"><section class="ds24-list-stack v430-list">${detailRows}</section></div></details>`:'';
    const title=Number(res.normalizedAmount??t.normalizedAmount)<0?'Đã ghi giảm giá trị hàng nhập':'Đã ghi điều chỉnh giá trị hàng nhập';return appShell({title:'Kết quả điều chỉnh giá trị',body:`<div class="io-result">${resultHero(title,'Điều chỉnh đã được ghi; sản phẩm liên quan cần cập nhật giá vốn.')}${summary}${details}</div>`,centered:true,back:false,actions:primaryFooter('Về công việc điều chỉnh','data-v461-val13-list')});
  }

  window.addEventListener('click',event=>{
    let el;
    if(activeFlowId==='UIF-13'){
      if((el=event.target.closest('[data-v461-val13-method]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current(),id=el.dataset.v461Val13Method;if(eligibleMethods(t).some(m=>m.id===id)){t.selectedMethod=id;val13PreviewHash=null;}return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val13-open-confirm]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(!val13CanPreview(t))return;val13ReviewSourceVersion=t.sourceVersion;val13PreviewHash=val13PreviewHashOf(t);confirm13=true;return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val13-confirm-close]'))){event.preventDefault();event.stopImmediatePropagation();confirm13=false;return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val13-confirm]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(Number(val13ReviewSourceVersion)!==Number(t.sourceVersion)||val13PreviewHash!==val13PreviewHashOf(t)){confirm13=false;stateByScreen['SCR-086']='SOURCE_CHANGED';return renderAppScreen();}val13Commit();confirm13=false;stateByScreen['SCR-089']='COMPLETED';return navigate('SCR-089');}
      if((el=event.target.closest('[data-v461-val13-back]'))){event.preventDefault();event.stopImmediatePropagation();confirm13=false;stateByScreen['SCR-086']='READY';return navigate('SCR-086');}
      if((el=event.target.closest('[data-v461-val13-list]'))){event.preventDefault();event.stopImmediatePropagation();confirm13=false;return navigate('SCR-085');}
    }
  },true);
  Object.assign(renderers, {
    'SCR-086': render086BJ13,
    'SCR-087': render086BJ13,
    'SCR-088': function(state){ activeScreenId='SCR-086'; return render086BJ13(state); },
    'SCR-089': render089BJ13,
  });
})();
