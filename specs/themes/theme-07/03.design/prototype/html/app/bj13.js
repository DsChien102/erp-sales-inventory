/* BJ-13 — Điều chỉnh giá trị hàng nhập (UIF-13). Màn: SCR-085, SCR-086, SCR-089.
 *
 * Thiết kế lại (T7-P BJ-13, 2026-10-24, v5.10.0): một khối dựng cho 085 / 086 / 089 (087 / 088 là đường cũ, có alias về 086).
 * 085 bảng nguồn (web, K7; iPhone danh sách); 086 web hai cột (nguồn + cách phân bổ + kỳ | bảng phân bổ có dòng tổng),
 * iPhone xếp dọc; sheet xác nhận "Ghi điều chỉnh giá trị?" (hộp thoại giữa màn trên web); 089 K4 / K3.
 * Sửa BJ-13: sửa thẳng file này. Helper val13* gán trong khối chuẩn hoá v398; val13Engine dùng chung với BJ-14.
 * Dùng từ khuôn: k1Loading, k1Denied, k1Empty, k1ExitAttr (K1); k3Unknown (K3); k4Result, k4Footer (K4);
 * k7Split, k7Table, k7FilterChips (K7); dsChoiceRow. Số tiền có dấu: VAL_UI_461.signed.
 *
 * Fixture chung chặng 2: LC13-001 (VC-8842) phân bổ cho Nobivac DHPPi PN-260816-04 (121 hộp, 9.885.700 đ — số BJ-03 ghi)
 * + Vaccine Canine X. `val13SyncFromValuation()` lấy lại số lượng / giá trị nhập từ `val03LastResult` khi vào 085 / 086.
 */
// UIF-13 / BJ-13 v1.4.5 — Late landed cost deep Product correction.
// Allocation-method labels below are runtime fixtures returned by the preview
// model. They are not a canonical business enum; BC-IV-06/API-Q-12 owns the
// authoritative allowed set and calculation in production.
// ============================================================================
const val13Tasks = [
  {id:"LC13-001",sourceRef:"Hóa đơn vận chuyển VC-8842 · dòng 1",sourceVersion:2,evidence:"VC-8842.pdf",supplier:"Vận tải An Phát",component:"Chi phí vận chuyển",sourceAmount:1200000,currency:"VND",normalizedAmount:1200000,fxLabel:"VND",ageDays:4,status:"ACTIONABLE",waitingOwner:"",originalPeriod:"08/2026",postingPeriod:"09/2026",periodReason:"Kỳ gốc đã khóa; ghi điều chỉnh ở kỳ mở hiện tại",policyVersion:"ALC-POL-v5",allowedMethods:[{id:"FIXTURE_VALUE",label:"Theo giá trị nhập ban đầu"}],selectedMethod:"FIXTURE_VALUE",targets:[
    {id:"LC13-T1",receipt:"PN-260816-04",lineId:"ROL-401",product:"Nobivac DHPPi",code:"SP-000184",uom:"hộp",lot:"DH2507",qty:121,receivedValue:9885700,selected:true},
    {id:"LC13-T3",receipt:"PN-260821-03",lineId:"ROL-512",product:"Vaccine Canine X",code:"SP-00421",uom:"lọ",lot:"CX2608",qty:40,receivedValue:4010000,selected:true}
  ]},
  {id:"LC13-002",sourceRef:"Phí bảo hiểm INS-2609-17 · dòng 2",sourceVersion:1,evidence:"INS-2609-17.pdf",supplier:"Bảo hiểm Minh Thành",component:"Phí bảo hiểm hàng mua",sourceAmount:250,currency:"USD",normalizedAmount:6125000,fxRate:24500,fxLabel:"Tỷ giá kế toán 24.500 VND/USD",ageDays:2,status:"ACTIONABLE",waitingOwner:"",originalPeriod:"09/2026",postingPeriod:"09/2026",periodReason:"Kỳ gốc đang mở",policyVersion:"ALC-POL-v5",allowedMethods:[{id:"FIXTURE_VALUE",label:"Theo giá trị nhập ban đầu"}],selectedMethod:"FIXTURE_VALUE",targets:[
    {id:"LC13-T4",receipt:"PN-260901-03",lineId:"ROL-601",product:"Vaccine Canine X",code:"SP-00421",uom:"lọ",lot:"CX2609",qty:10,receivedValue:1002450,selected:true},
    {id:"LC13-T5",receipt:"PN-260901-08",lineId:"ROL-633",product:"Doxycycline 100mg",code:"SP-00611",uom:"hộp",lot:null,qty:60,receivedValue:7200000,selected:true}
  ]},
  {id:"LC13-003",sourceRef:"Hóa đơn vận chuyển VC-8890 · dòng 1",sourceVersion:1,evidence:"VC-8890.pdf",supplier:"Logistics Đông Dương",component:"Chi phí vận chuyển",sourceAmount:180,currency:"USD",normalizedAmount:null,fxLabel:"",ageDays:6,status:"WAITING",waitingOwner:"Chờ nguồn hoàn tất quy đổi giá trị",originalPeriod:"08/2026",postingPeriod:"",periodReason:"",policyVersion:"",allowedMethods:[],selectedMethod:"",targets:[]},
  {id:"LC13-004",sourceRef:"Điều chỉnh chiết khấu CK-2609-06 · dòng 1",sourceVersion:3,evidence:"CK-2609-06.pdf",supplier:"VietVet",component:"Điều chỉnh chiết khấu mua",sourceAmount:-350000,currency:"VND",normalizedAmount:-350000,fxLabel:"VND",ageDays:1,status:"ACTIONABLE",waitingOwner:"",originalPeriod:"09/2026",postingPeriod:"09/2026",periodReason:"Kỳ gốc đang mở",policyVersion:"ALC-POL-v5",allowedMethods:[{id:"FIXTURE_VALUE",label:"Theo giá trị nhập ban đầu"}],selectedMethod:"FIXTURE_VALUE",targets:[
    {id:"LC13-T6",receipt:"PN-260902-07",lineId:"ROL-407",product:"Dung dịch sát khuẩn",code:"SP-00510",uom:"chai",lot:null,qty:12,receivedValue:552000,selected:true},
    {id:"LC13-T7",receipt:"PN-260902-07",lineId:"ROL-408",product:"Bơm tiêm 5ml",code:"SP-00511",uom:"hộp",lot:null,qty:8,receivedValue:640000,selected:true}
  ]}
];
let val13SelectedTaskId="LC13-001", val13Query="", val13Filter="ALL", val13ReviewSourceVersion=null, val13PreviewHash=null, val13LastSourceChange=null, val13LastResult=null, val13OperationSeq=1;
function val13Current(){return val13Tasks.find(t=>t.id===val13SelectedTaskId)||val13Tasks[0];}
function val13FmtMoney(value){const n=Number(value||0);return `${new Intl.NumberFormat('vi-VN').format(n)} đ`;}
// Helper BJ-13 — một định nghĩa duy nhất, gán trong khối v398 bên dưới (cần biến cục bộ của khối).
let val13SelectedTargets, val13Preview, val13PreviewHashOf, val13CanOpenAllocation, val13CanPreview, val13ResetTaskDraft, val13SyncFromValuation, val13Commit, val13Result, val13ApplySourceUpdate;

// ============================================================================

/* chuẩn hoá + helper thắng (v398) */
(()=>{
if(typeof val13Tasks==='undefined') return;

const fmtMoney=(n)=>`${Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
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
val13Preview=allocate;
val13PreviewHashOf=combinedPreviewHash;
val13CanOpenAllocation=canOpen;
val13CanPreview=canPreview;
val13ResetTaskDraft=function(t){for(const x of (t.targets||[]))x.selected=true;const eligible=(t.allowedMethods||[]).filter(m=>methodEligible(t,m.id));t.selectedMethod=eligible.length===1?eligible[0].id:(eligible.some(m=>m.id===t.selectedMethod)?t.selectedMethod:'');val13ReviewSourceVersion=null;val13PreviewHash=null;val13LastSourceChange=null;};
// Lấy số lượng / giá trị nhập đã ghi ở BJ-03 (cùng phiếu nhận + mã sản phẩm). Chỉ gọi khi vào 085 / 086, trước khi tạo hash xem trước.
val13SyncFromValuation=function(){
  const res=typeof val03LastResult!=='undefined'?val03LastResult:null; if(!res?.groups?.length)return;
  for(const t of val13Tasks)for(const x of (t.targets||[])){
    const g=res.receipt===x.receipt&&res.groups.find(y=>y.code===x.code); if(!g)continue;
    x.qty=x.baseQty=Number(g.qty); x.receivedValue=x.initialDirectValue=Number(g.value);
    x.exposureHash=stableHash({key:x.valuationExposureKey,version:x.exposureVersion,qty:x.baseQty,value:x.initialDirectValue,refs:x.receiptValuationRefs,businessDate:x.businessDate,original:x.originalPeriod,posting:x.postingPeriod});
  }
};
val13Commit=function(){
  const t=val13Current(),rows=allocate(t),groups=periodGroups(t),basisHash=lateCostBasisHash(t),allocHash=allocationHash(t);
  const adjustmentBatches=groups.map((g,i)=>({id:`LC13-ADJ-${String(val13OperationSeq).padStart(3,'0')}-${i+1}`,postingPeriod:g.postingPeriod,originalPeriods:g.originalPeriods,allocationCount:g.count}));
  val13LastResult={operationId:t.operationId,taskId:t.id,sourceComponentKey:t.sourceComponentKey,sourceRevision:Number(t.sourceVersion||1),sourceRef:t.sourceRef,component:t.component,normalizedAmount:t.normalizedAmount,allocations:rows.map(x=>({...x})),dirtyScope:dirtyScopes(t),periodGroups:groups,adjustmentBatches,lateCostBasisHash:basisHash,allocationHash:allocHash};
  t.status='COMPLETED';return val13LastResult;
};
val13Result=function(){const t=val13Current();return val13LastResult||{operationId:t.operationId,taskId:t.id,sourceComponentKey:t.sourceComponentKey,sourceRevision:Number(t.sourceVersion||1),sourceRef:t.sourceRef,component:t.component,normalizedAmount:t.normalizedAmount,allocations:allocate(t),dirtyScope:dirtyScopes(t),periodGroups:periodGroups(t),adjustmentBatches:[],lateCostBasisHash:lateCostBasisHash(t),allocationHash:allocationHash(t)};};
val13ApplySourceUpdate=function(){const t=val13Current();if(t.status!=='ACTIONABLE')return;t.sourceVersion=Number(t.sourceVersion||1)+1;t.sourceRevision=t.sourceVersion;const before=t.normalizedAmount;t.normalizedAmount=Number(t.normalizedAmount||0)+100000;val13LastSourceChange={from:val13FmtMoney(before),to:val13FmtMoney(t.normalizedAmount),version:t.sourceVersion};render();};

const val13Engine={lateCostBasisPayload,lateCostBasisHash,allocationHash,combinedPreviewHash,metricSnapshot,methodEligible,allocate,dirtyScopes,periodGroups,allInitialValued,economicIdentity:(t=val13Current())=>t.sourceComponentKey,touchExposure:(id)=>{const t=val13Current(),x=t.targets.find(y=>y.id===id);if(!x)return false;x.exposureVersion+=1;x.exposureHash=stableHash({key:x.valuationExposureKey,version:x.exposureVersion,qty:x.baseQty,value:x.initialDirectValue,refs:x.receiptValuationRefs,businessDate:x.businessDate,original:x.originalPeriod,posting:x.postingPeriod});return true;},shuffleTargets:(t=val13Current())=>{t.targets.reverse();return true;}};
window.val13Engine=val13Engine;
})();
var val13Engine=window.val13Engine;

screenAliases["UIF-13"] = Object.assign(screenAliases["UIF-13"] || {}, {
  "SCR-087": "SCR-086",
  "SCR-088": "SCR-086",
});
{ const a = screenAliases[activeFlowId]?.[activeScreenId]; if (Array.isArray(a)) { activeFlowId = a[0]; activeScreenId = a[1]; } else if (a) activeScreenId = a; }

/* --- SCR-085 / 086 / 089 — một khối dựng (v5.10.0) --- */
// Trạng thái giao diện của 086 / 089 (sheet đang mở). `val13ResetUi` đưa về mặc định khi mở nguồn khác.
const val13UiDefaults = () => ({ confirmOpen: false, resultOpen: false });
let val13Ui = val13UiDefaults();
function val13ResetUi() { val13Ui = val13UiDefaults(); }
(()=>{
  const TITLE_LIST = "Điều chỉnh giá trị hàng nhập", TITLE_FORM = "Phân bổ điều chỉnh giá trị", TITLE_RESULT = "Kết quả điều chỉnh giá trị";
  const SENT_AT = "10:20 · 16/09/2026";
  const NO_METHOD = "Chưa có phương pháp phân bổ hợp lệ";
  const { money, signed, pct } = VAL_UI_461;
  const shell = (opts) => appShell({ ...opts, extraClass: "k7-wide" });
  const isOwner = () => currentActor() !== "staff";
  const blocked = (state) => !isOwner() || state === "PERMISSION_DENIED" || state === "FINANCIAL_MASKED";
  const denied = (title, back) => shell({ title, body: k1Denied({ what: "điều chỉnh giá trị", next: "Chỉ chủ cửa hàng xem và ghi điều chỉnh giá trị.", exitAttr: k1ExitAttr("SCR-085") }), centered: true, back });
  const sourceTitle = (t) => String(t.sourceRef || "").replace(/ · dòng \d+$/, "");
  // Số tiền có dấu (+ / −) và màu tăng / giảm; nguồn chưa quy đổi sang VND thì "Chờ quy đổi".
  const amountHtml = (n, extra = "") => (n == null ? `<span class="bj13-amount bj13-amount--pending${extra}">Chờ quy đổi</span>` : `<span class="bj13-amount${Number(n) < 0 ? " bj13-amount--down" : " bj13-amount--up"}${extra}">${esc(signed(n))}</span>`);
  const statusBadge = (t) => (t.status === "WAITING" ? ds24Badge("Đang chờ", "Neutral") : ds24Badge("Có thể xử lý", "Success"));
  const openTasks = () => val13Tasks.filter((t) => t.status !== "COMPLETED");
  const filterMatch = (t) => val13Filter === "ALL" || t.status === val13Filter;
  // Danh sách "nhãn — giá trị" cho sheet xác nhận (giá trị căn phải, tự xuống dòng khi hẹp).
  const facts = (rows) => `<dl class="bj13-facts" data-composed-from="DS v2 / Key-value Row">${rows.map(([l, v, strong]) => `<div class="${strong ? "is-strong" : ""}"><dt>${esc(l)}</dt><dd>${esc(v)}</dd></div>`).join("")}</dl>`;
  const surface = (title, body, extra = "") => `<section class="ac310-surface bj13-surface ${extra}" data-layout-pattern="Grouped surface"><div class="ac310-surface__head"><h2>${esc(title)}</h2></div><div class="bj13-surface__body">${body}</div></section>`;
  const postingPeriods = (t) => [...new Set(val13SelectedTargets(t).map((x) => x.postingPeriod).filter(Boolean))];

  /* ---------- Sheet (hộp thoại giữa màn trên web) ---------- */
  function sheet({ title, intro = "", body, actions, single = false }) {
    return `<div class="sheet-backdrop" data-bj13-backdrop><section class="bottom-sheet bj13-sheet" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}" data-ds-component="VBottomSheet" data-figma-node="4695:6353"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(title)}</h3></div><div class="sheet-divider"></div><div class="sheet-content">${intro ? `<p class="bj13-note">${esc(intro)}</p>` : ""}${body}</div><div class="sheet-actions${single ? " bj13-sheet-actions--single" : ""}">${actions}</div></section></div>`;
  }
  const button = (label, attr, primary) => `<button class="button button--${primary ? "primary" : "secondary"}" type="button" ${attr} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.${primary ? "primary" : "secondary"}" data-ds-prop-size="VButtonSize.medium">${esc(label)}</button>`;

  /* ---------- SCR-085 Điều chỉnh giá trị hàng nhập ---------- */
  function taskMobileRow(row) {
    const trailing = `<span class="bj13-trail">${amountHtml(row.t.normalizedAmount)}${row.badge}</span>`;
    return ds24ListRow({ title: row.source, subtitle: `${row.t.component} · ${row.t.supplier}`, trailing, leading: null, attrs: `data-bj13-task="${row.t.id}"`, type: "Navigation", density: "Compact" });
  }
  function render085BJ13(state) {
    if (activeFlowId !== "UIF-13") return renderGeneric(screens.find((s) => s.id === "SCR-085"), state);
    const title = TITLE_LIST;
    if (blocked(state)) return denied(title, false);
    if (state === "LOADING") return shell({ title, body: k1Loading({ blocks: ["search", "row", "row", "row"] }), back: false });
    val13SyncFromValuation();
    const all = openTasks();
    if (state === "EMPTY" || !all.length) return shell({ title, body: k1Empty({ title: "Không có khoản điều chỉnh nào", description: "Khoản phát sinh sau khi đã xác lập giá sẽ hiện ở đây." }), back: false });
    const count = (status) => all.filter((t) => t.status === status).length;
    const search = ds24Search(val13Query, "data-bj13-search", "Nguồn điều chỉnh hoặc đối tác");
    const chips = k7FilterChips({ items: [["ALL", "Tất cả", all.length], ["ACTIONABLE", "Có thể xử lý", count("ACTIONABLE")], ["WAITING", "Đang chờ", count("WAITING")]], selected: val13Filter, attrName: "data-bj13-filter" });
    const emptyFiltered = { title: "Không có công việc phù hợp", description: "Đổi từ khóa hoặc bộ lọc để xem công việc khác.", actionLabel: "Xem tất cả", actionAttr: "data-bj13-show-all" };
    if (state === "FILTER_EMPTY") return shell({ title, body: `${search}${chips}${k1Empty(emptyFiltered)}`, back: false });
    const rows = all
      .filter((t) => ioMatchesSearch(val13Query, `${t.sourceRef} ${t.supplier} ${t.component}`))
      .filter(filterMatch)
      .map((t) => ({ t, source: sourceTitle(t), badge: statusBadge(t), count: (t.targets || []).length }))
      .map((row) => ({ ...row, sourceHtml: `<button class="k7-row-link" type="button">${esc(row.source)}</button>`, amountHtml: amountHtml(row.t.normalizedAmount), countHtml: row.count ? String(row.count) : '<span class="k7-muted">—</span>', component: row.t.component, supplier: row.t.supplier }));
    const columns = [
      { key: "sourceHtml", label: "Nguồn", html: true },
      { key: "component", label: "Loại" },
      { key: "supplier", label: "Đối tác" },
      { key: "amountHtml", label: "Số tiền", align: "end", html: true, mono: true },
      { key: "countHtml", label: "Sản phẩm", align: "end", html: true, mono: true },
      { key: "badge", label: "Tình trạng", html: true },
    ];
    const table = k7Table({ columns, rows, mobileRow: taskMobileRow, caption: "Khoản điều chỉnh giá trị hàng nhập", rowAttr: (row) => `data-bj13-task="${row.t.id}"`, empty: emptyFiltered });
    return shell({ title, body: `${search}${chips}<div class="bj13-list">${table}</div>`, back: false });
  }

  /* ---------- SCR-086 Phân bổ điều chỉnh giá trị ---------- */
  const METHOD_DESC = {
    FIXTURE_VALUE: ["Phân bổ theo tỷ trọng giá trị nhập ban đầu của từng sản phẩm, trước các điều chỉnh phát sinh sau đó.", "Phân bổ theo tỷ trọng giá trị nhập ban đầu của từng sản phẩm"],
    FIXTURE_QTY: ["Chỉ dùng khi toàn bộ phạm vi có chỉ tiêu lượng chuẩn cùng đơn vị và có thể so sánh.", "Chỉ dùng khi toàn bộ phạm vi có chỉ tiêu lượng chuẩn cùng đơn vị"],
  };
  const eligibleMethods = (t) => (t.allowedMethods || []).filter((m) => val13Engine.methodEligible(t, m.id));
  const methodLabel = (t) => (t.allowedMethods || []).find((m) => m.id === t.selectedMethod)?.label || "—";
  function sourceCard(t) {
    const file = t.evidence ? `<div class="bj13-source__file"><small>${esc(t.evidence)}</small><button class="k7-row-link bj13-link" type="button" data-bj13-evidence aria-label="Xem chứng từ ${escapeAttribute(t.evidence)}">Xem chứng từ</button></div>` : "";
    return `<section class="ac310-surface bj13-source" data-layout-pattern="Grouped surface"><div class="bj13-source__copy"><strong>${esc(sourceTitle(t))}</strong><small>${esc(`${t.component} · ${t.supplier}`)}</small></div>${file}<div class="bj13-value"><span>Giá trị điều chỉnh</span>${amountHtml(t.normalizedAmount, " bj13-amount--lg")}</div></section>`;
  }
  // Một phương pháp: dòng chỉ đọc; nhiều phương pháp: chọn một, mỗi dòng kèm mô tả.
  function methodBlock(t) {
    const methods = eligibleMethods(t);
    if (methods.length > 1) {
      const rows = methods.map((m) => dsChoiceRow({ title: m.label, subtitle: METHOD_DESC[m.id]?.[1] || "", selected: t.selectedMethod === m.id, attrs: `data-bj13-method="${m.id}"` })).join("");
      return surface("Cách phân bổ", `<div class="bj13-choices" role="radiogroup" aria-label="Cách phân bổ">${rows}</div>`);
    }
    const m = methods[0];
    return surface("Cách phân bổ", m ? `<strong>${esc(m.label)}</strong><p>${esc(METHOD_DESC[m.id]?.[0] || "")}</p>` : `<p>${NO_METHOD}</p>`);
  }
  // Kỳ ghi nhận một dòng: kỳ gốc khoá thì ghi ở kỳ mở, vẫn nói kỳ gốc.
  function periodBlock(t) {
    const targets = val13SelectedTargets(t), posting = postingPeriods(t);
    if (!posting.length) return "";
    const locked = [...new Set(targets.filter((x) => x.originalPeriod && x.originalPeriod !== x.postingPeriod).map((x) => x.originalPeriod))];
    return surface("Kỳ ghi nhận", `<p>${esc(locked.length ? `Ghi vào kỳ ${posting.join(", ")} · kỳ gốc ${locked.join(", ")} đã khoá` : `Ghi vào kỳ ${posting.join(", ")}`)}</p>`);
  }
  // Bảng phân bổ (web) / thẻ (iPhone); withAllocation = false: không có cột tỷ trọng / phân bổ và dòng tổng (chưa có phương pháp hợp lệ).
  function allocationTable(t, withAllocation) {
    const items = withAllocation ? val13Preview(t) : val13SelectedTargets(t);
    const sum = items.reduce((n, x) => n + Number(x.allocationMetric?.metricValue || 0), 0);
    const rows = items.map((x) => {
      const ratio = sum ? Number(x.allocationMetric?.metricValue || 0) / sum : 0;
      return { x, productHtml: `<strong>${esc(x.product)}</strong><small>${esc(x.code)}</small>`, receipt: x.receipt, lot: x.lot || "—", qtyText: `${x.qty} ${x.uom}`, valueText: money(x.initialDirectValue ?? x.receivedValue), ratioText: pct(ratio), allocText: withAllocation ? signed(x.allocatedAmount) : "" };
    });
    const total = items.reduce((n, x) => n + Number(x.allocatedAmount || 0), 0);
    if (withAllocation) rows.push({ total: true, productHtml: "<strong>Tổng phân bổ</strong>", receipt: "", lot: "", qtyText: "", valueText: "", ratioText: "", allocText: signed(total) });
    const columns = [
      { key: "productHtml", label: "Sản phẩm", html: true },
      { key: "receipt", label: "Phiếu nhận", mono: true },
      { key: "lot", label: "Lô", mono: true },
      { key: "qtyText", label: "Số lượng", align: "end", mono: true },
      { key: "valueText", label: "Giá trị nhập", align: "end", mono: true },
      ...(withAllocation ? [{ key: "ratioText", label: "Tỷ trọng", align: "end", mono: true }, { key: "allocText", label: "Phân bổ", align: "end", mono: true }] : []),
    ];
    const card = (r) => {
      if (r.total) return `<div class="bj13-total"><span>Tổng phân bổ</span><strong>${esc(r.allocText)}</strong></div>`;
      const x = r.x, sub = `${x.receipt}${x.lot ? ` · Lô ${x.lot}` : ""} · ${r.qtyText}`;
      const figures = withAllocation ? `Giá trị nhập ${r.valueText} · Tỷ trọng ${r.ratioText}` : `Giá trị nhập ${r.valueText}`;
      return `<div class="bj13-card"><div class="bj13-card__head"><strong>${esc(x.product)}</strong>${withAllocation ? `<strong class="bj13-money">${esc(r.allocText)}</strong>` : ""}</div><small>${esc(sub)}</small><small>${esc(figures)}</small></div>`;
    };
    const table = k7Table({ columns, rows, mobileRow: card, caption: "Kết quả phân bổ", rowAttr: (r) => (r.total ? 'class="bj13-total-row"' : ""), footer: "Phạm vi do nguồn xác định, không bỏ bớt sản phẩm được." });
    return `<section class="bj13-allocation">${ds24SectionTitle("Kết quả phân bổ", `${items.length} sản phẩm`)}${table}</section>`;
  }
  function confirmSheet(t) {
    if (!val13Ui.confirmOpen) return "";
    const n = val13Preview(t).length;
    const summary = facts([["Nguồn", sourceTitle(t)], ["Sản phẩm", `${n} sản phẩm`], ["Cách phân bổ", methodLabel(t)], ["Kỳ ghi nhận", postingPeriods(t).join(", ") || "—"], ["Giá trị điều chỉnh", signed(t.normalizedAmount), true]]);
    return sheet({ title: "Ghi điều chỉnh giá trị?", intro: "Kiểm tra lại tổng tiền, phạm vi, cách phân bổ và kỳ ghi nhận trước khi ghi.", body: summary, actions: `${button("Quay lại", "data-bj13-confirm-close")}${button("Xác nhận", "data-bj13-confirm", true)}` });
  }
  // Chân màn: nút "Ghi điều chỉnh"; tắt thì kèm dòng lý do (iPhone trên nút, web bên trái).
  function footer(disabled) {
    const f = k4Footer([{ label: "Ghi điều chỉnh", attr: "data-bj13-open-confirm", primary: true, disabled }]);
    return disabled ? f.replace("<button", `<div class="bj13-footer-stack"><p class="bj13-reason">${NO_METHOD}</p><button`).replace("</button></footer>", "</button></div></footer>") : f;
  }
  function render086BJ13(state) {
    if (activeFlowId !== "UIF-13") return renderGeneric(screens.find((s) => s.id === "SCR-086"), state);
    const title = TITLE_FORM;
    if (blocked(state)) return denied(title, true);
    if (state === "LOADING") return shell({ title, body: k1Loading({ blocks: ["heading", "card", "row", "row"] }) });
    if (val13PreviewHash == null) val13SyncFromValuation();
    const t = val13Current();
    // Nguồn đang chờ (UIF-13-T03): mở chỉ đọc, nói lý do, không bảng phân bổ, không nút ghi.
    if (t.status === "WAITING" || !val13CanOpenAllocation(t)) {
      return shell({ title, body: `${vBanner("info", "Chưa thể xử lý", esc(t.waitingOwner || "Đang chờ nguồn hoàn tất dữ liệu cần thiết."))}${sourceCard(t)}` });
    }
    const methods = eligibleMethods(t);
    if (methods.length === 1 && t.selectedMethod !== methods[0].id) { t.selectedMethod = methods[0].id; val13PreviewHash = null; }
    const valid = state !== "VALIDATION_ERROR" && val13CanPreview(t);
    const notices = [];
    if (state === "SOURCE_CHANGED") notices.push(vBanner("warning", "Nguồn điều chỉnh đã thay đổi", "Kiểm tra lại dữ liệu hiện hành trước khi ghi."));
    if (!valid) notices.push(vBanner("error", NO_METHOD, "Hàng trong phạm vi chưa đủ dữ liệu để chia theo cùng một cách. Hệ thống không tự chia đều."));
    const source = sourceCard(t), method = methodBlock(t), period = periodBlock(t), table = allocationTable(t, valid);
    // Web hai cột; iPhone xếp dọc: nguồn → giá trị → bảng (thẻ) → cách phân bổ → kỳ.
    const layout = viewport === "web" ? `<div class="bj13-split">${k7Split({ main: `${source}${method}${period}`, aside: table })}</div>` : `${source}${table}${method}${period}`;
    return shell({ title, body: `${notices.join("")}${layout}${valid ? confirmSheet(t) : ""}`, actions: footer(!valid) });
  }

  /* ---------- SCR-089 Kết quả điều chỉnh giá trị ---------- */
  function resultDetailSheet(res) {
    if (!val13Ui.resultOpen) return "";
    const rows = (res.allocations || []).map((x) => ds24ListRow({ title: x.product, subtitle: `${x.receipt} · ${x.qty} ${x.uom}`, trailing: `<strong class="bj13-money">${esc(signed(x.allocatedAmount))}</strong>`, leading: null, type: "Status", interactive: false, density: "Compact" })).join("");
    return sheet({ title: "Kết quả phân bổ", body: `<section class="ds24-list-stack">${rows}</section>`, actions: button("Đóng", "data-bj13-sheet-close", true), single: true });
  }
  function render089BJ13(state) {
    if (activeFlowId !== "UIF-13") return renderGeneric(screens.find((s) => s.id === "SCR-089"), state);
    const title = TITLE_RESULT;
    if (blocked(state)) return denied(title, false);
    if (state === "PROCESSING") return shell({ title, body: k1Loading({ blocks: ["heading", "card", "row"] }), centered: true, back: false });
    const t = val13Current(), res = val13LastResult || val13Result(), n = (res.allocations || []).length;
    const source = sourceTitle(res.sourceRef ? res : t), amount = res.normalizedAmount ?? t.normalizedAmount;
    const ref = res.adjustmentBatches?.[0]?.id || `LC13-ADJ-${String(val13OperationSeq).padStart(3, "0")}-1`;
    if (state === "UNKNOWN") return k3Unknown({ operation: "Điều chỉnh giá trị hàng nhập", scope: `${source} · ${n} sản phẩm`, ref, sentAt: SENT_AT, safe: "Không ghi lại điều chỉnh. Chuyển đúng thao tác này sang xác minh.", sourceFlow: "UIF-13", exitAttr: k1ExitAttr("SCR-085") });
    if (state === "REJECTED_EXECUTION") return k4Result({ screenTitle: title, kind: "warning", title: "Chưa ghi điều chỉnh", description: "Không có thay đổi giá trị.", facts: [["Nguồn", esc(source)], ["Tác động", "Không thay đổi"]], next: [{ label: "Về Kho", attr: k1ExitAttr("SCR-085") }, { label: "Xem lại phân bổ", attr: "data-bj13-back", primary: true }] });
    const periods = [...new Set((res.allocations || []).map((x) => x.postingPeriod).filter(Boolean))];
    const facts = [["Nguồn", esc(source)], ["Tổng điều chỉnh", esc(signed(amount))], ["Sản phẩm bị ảnh hưởng", `${n}`], ["Kỳ ghi nhận", esc(periods.join(", ") || "—")], ["Giá vốn", "Cần cập nhật"]];
    const detail = n ? `<button class="k7-row-link bj13-link bj13-detail-link" type="button" data-bj13-result-detail>Xem chi tiết phân bổ (${n})</button>${resultDetailSheet(res)}` : "";
    const heading = Number(amount) < 0 ? "Đã ghi giảm giá trị hàng nhập" : "Đã ghi điều chỉnh giá trị hàng nhập";
    return k4Result({ screenTitle: title, title: heading, description: "Điều chỉnh đã được ghi; sản phẩm liên quan cần cập nhật giá vốn.", facts, button: detail, next: [{ label: "Cập nhật giá vốn", attr: "data-bj13-go-cost" }, { label: "Về công việc điều chỉnh", attr: "data-bj13-list", primary: true }] });
  }

  /* ---------- Sự kiện ---------- */
  // Gõ ô tìm: dựng lại màn nhưng giữ con trỏ trong ô.
  function renderKeepFocus(sel) {
    const keep = document.activeElement?.matches?.(sel);
    renderAppScreen();
    if (!keep) return;
    const n = document.querySelector(sel);
    if (n) { n.focus(); const v = n.value; n.value = ""; n.value = v; }
  }
  // Bấm bằng bàn phím dựng lại cả màn: trả focus về đúng nút vừa bấm.
  function renderRefocus(attr, value) {
    renderAppScreen();
    const sel = `[${attr}="${CSS.escape(value)}"]`;
    const n = [...document.querySelectorAll(sel)].find((e) => e.offsetParent !== null) || document.querySelector(sel);
    n?.focus({ preventScroll: true });
  }
  const setState = (screen, st) => { stateByScreen[screen] = st; syncReviewUrl(); };
  window.addEventListener("input", (event) => {
    if (activeFlowId !== "UIF-13" || !event.target.matches?.("[data-bj13-search]")) return;
    val13Query = event.target.value; renderKeepFocus("[data-bj13-search]");
  }, true);
  onDialogClose["UIF-13"] = () => {
    if (!(val13Ui.confirmOpen || val13Ui.resultOpen)) return false;
    val13ResetUi(); renderAppScreen(); return true;
  };
  // Nghe ở document (sau trình nhớ nút mở hộp thoại của core.js) để Esc / đóng trả focus về đúng nút.
  document.addEventListener("click", (event) => {
    if (activeFlowId !== "UIF-13") return;
    const t = event.target, hit = (sel) => t.closest?.(sel);
    const take = () => { event.preventDefault(); event.stopImmediatePropagation(); };
    let el;
    if (t.matches?.("[data-bj13-backdrop]") || hit("[data-bj13-confirm-close]") || hit("[data-bj13-sheet-close]")) { take(); val13ResetUi(); return renderAppScreen(); }
    // 085
    if ((el = hit("[data-bj13-filter]"))) { take(); val13Filter = el.dataset.bj13Filter; return renderRefocus("data-bj13-filter", val13Filter); }
    if (hit("[data-bj13-show-all]")) { take(); val13Query = ""; val13Filter = "ALL"; if (stateByScreen["SCR-085"] === "FILTER_EMPTY") setState("SCR-085", "READY"); return renderAppScreen(); }
    if ((el = hit("[data-bj13-task]"))) {
      take(); val13SelectedTaskId = el.dataset.bj13Task; val13SyncFromValuation(); val13ResetTaskDraft(val13Current()); val13ResetUi(); stateByScreen["SCR-086"] = "READY";
      return navigate("SCR-086");
    }
    // 086
    if (hit("[data-bj13-evidence]")) { take(); return showToast("Đã mở bản xem trước chứng từ trong chế độ prototype.", "info"); }
    if ((el = hit("[data-bj13-method]"))) {
      take(); const task = val13Current(), id = el.dataset.bj13Method;
      if (eligibleMethods(task).some((m) => m.id === id)) { task.selectedMethod = id; val13PreviewHash = null; }
      return renderRefocus("data-bj13-method", id);
    }
    if ((el = hit("[data-bj13-open-confirm]"))) {
      take(); if (el.disabled) return;
      const task = val13Current(); if (!val13CanPreview(task)) return;
      val13ReviewSourceVersion = task.sourceVersion; val13PreviewHash = val13PreviewHashOf(task); val13Ui.confirmOpen = true;
      return renderAppScreen();
    }
    if (hit("[data-bj13-confirm]")) {
      take(); const task = val13Current(); val13Ui.confirmOpen = false;
      if (Number(val13ReviewSourceVersion) !== Number(task.sourceVersion) || val13PreviewHash !== val13PreviewHashOf(task)) { val13PreviewHash = null; setState("SCR-086", "SOURCE_CHANGED"); return renderAppScreen(); }
      val13Commit(); val13PreviewHash = null; stateByScreen["SCR-089"] = "COMPLETED";
      return navigate("SCR-089");
    }
    // 089
    if (hit("[data-bj13-result-detail]")) { take(); val13Ui.resultOpen = true; return renderAppScreen(); }
    if (hit("[data-bj13-back]")) { take(); val13ResetUi(); stateByScreen["SCR-086"] = "READY"; return navigate("SCR-086"); }
    if (hit("[data-bj13-list]")) { take(); val13ResetUi(); val13Query = ""; val13Filter = "ALL"; stateByScreen["SCR-085"] = "READY"; return navigate("SCR-085"); }
    if (hit("[data-bj13-go-cost]")) { take(); val13ResetUi(); return applyEntry("UIF-14", "dirty-scope", true); }
  }, true);

  Object.assign(renderers, {
    "SCR-085": render085BJ13,
    "SCR-086": render086BJ13,
    "SCR-089": render089BJ13,
  });
})();
