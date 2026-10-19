/* BJ-06 — Hàng khách trả (UIF-06). Màn: SCR-030, SCR-031, SCR-032, SCR-033, SCR-034, SCR-035.
 *
 * Đã viết lại sạch (T7-P gói A2, 2026-10-17): mọi fixture, trạng thái, helper io06*, hàm dựng và xử lý sự kiện của BJ-06
 * nằm ở đây; Sửa BJ-06: sửa thẳng file này.
 * Dùng chung từ app/core.js: appShell, ds24*, io* chung (ioMatchesSearch, ioNormalizeSearch, ioFilterRows, ioEmpty,
 * ioResult, resultHero, ioSecondary, ioMetaRow, ioReadCard), vBanner, deniedBody, loadingBody, esc, escapeAttribute,
 * icon, primaryFooter, navigate, renderAppScreen, onPrevious.
 * Handoff UNKNOWN: đăng ký onUnknownHandoff["UIF-06"] (A10); nút handoff-unknown → bj17.js.
 */


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
}
let io06ApprovalSeq=2;
const io06ApprovalCases=[
  {id:"EX-06-001",requestId:"RET-260827-07",lineId:"RET-L6",status:"PENDING",maker:"Nguyễn Minh · Thủ kho",createdAt:"03/09/2026 09:18",decisionReason:"",snapshot:{requestId:"RET-260827-07",source:"SO-260820-08",sourceVersion:7,lineId:"RET-L6",qty:3,uom:"hộp",expectedLot:"DH2507",actualLot:"DH2509",reasonCode:"ACTUAL_DIFF",reasonDetail:"",evidenceFile:"anh-nhan-lo-DH2509.jpg",evidenceData:io06EvidenceSvg("DH2509")}}
];
let io06SelectedRequestId="RET-260827-03", io06ActiveLineId="RET-L1A", io06Query="", io06QueueFilter="ALL", io06RejectOpen=false, io06RejectReason="", io06ClassificationOpen=false, io06ClassificationDraft=null, io06SelectedApprovalCaseId="EX-06-001", io06ApproverListMode=true;
io06Requests.forEach((r) => { r.unknownLocked ??= false; });

function io06CurrentRequest(){return io06Requests.find(r=>r.id===io06SelectedRequestId)||io06Requests.find(r=>!r.closed)||io06Requests[0];}
function io06LinesForRequest(id){return io06LinesByRequest[id]||[];}
function io06CurrentLines(){return io06LinesForRequest(io06SelectedRequestId);}
function io06FindLine(id){for(const lines of Object.values(io06LinesByRequest)){const l=lines.find(x=>x.id===id);if(l)return l;}return null;}
function io06ActiveLine(){return io06FindLine(io06ActiveLineId)||io06CurrentLines()[0];}
function io06LineCase(line){return line?.exceptionCaseId?io06ApprovalCases.find(c=>c.id===line.exceptionCaseId):null;}
function io06PendingCasesForRequest(id){return io06ApprovalCases.filter(c=>c.requestId===id&&c.status==="PENDING");}
function io06CasesForRequest(id){return io06ApprovalCases.filter(c=>c.requestId===id&&!['INVALIDATED','SUPERSEDED'].includes(c.status));}
function io06Mismatch(line=io06ActiveLine()){return Boolean(line?.expectedLot)&&Boolean(String(line.actualLot||"").trim())&&String(line.actualLot||"").trim().toUpperCase()!==String(line.expectedLot||"").trim().toUpperCase();}
function io06RequestHasMismatch(req=io06CurrentRequest()){return io06LinesForRequest(req.id).some(io06Mismatch);}
function io06RefreshRequestState(req=io06CurrentRequest()){
  if(req.closed){req.queue="CLOSED";return;}
  if(req.receiptCommitted&&!req.classified){req.phase="CLASSIFICATION";req.queue="ACTIONABLE";req.status="Cần phân loại";return;}
  const cases=io06CasesForRequest(req.id);if(cases.some(c=>c.status==="PENDING")){req.queue="WAITING";req.status="Đang chờ duyệt lô";return;}
  if(cases.some(c=>c.status==="REJECTED")){req.queue="ACTIONABLE";req.status="Cần xử lý ngoại lệ";return;}
  req.phase="RECEIPT";req.queue="ACTIONABLE";req.status=io06ReceiptReady(req)?"Sẵn sàng ghi nhận":"Cần nhận";
}
function io06SelectedApprovalCase(){const exact=io06ApprovalCases.find(c=>c.id===io06SelectedApprovalCaseId&&c.status!=="INVALIDATED");if(exact)return exact;const pending=io06ApprovalCases.find(c=>c.status==="PENDING");if(pending){io06SelectedApprovalCaseId=pending.id;return pending;}return null;}
function io06ApprovalCaseLine(c=io06SelectedApprovalCase()){return c?io06FindLine(c.lineId):null;}
function io06SubmitDraftExceptions(req=io06CurrentRequest()){
  if(!io06RequestCanSubmitExceptions(req))return false;
  io06LinesForRequest(req.id).filter(io06Mismatch).forEach(line=>{const st=io06LineApprovalState(line);if(st!=="APPROVED"&&st!=="PENDING")io06CreateCase(req,line);});io06RefreshRequestState(req);return true;
}
function io06AfterApprovalDecision(caseObj){const req=io06Requests.find(r=>r.id===caseObj.requestId);if(!req)return;io06RefreshRequestState(req);}

const BJ06_BUSINESS_DATE='2026-09-16';
const BJ06_MAKER={id:'USR-WH-014',name:'Nguyễn Minh · Thủ kho'};
const BJ06_LOTS={
  DH2507:{lotId:'LOT-DH2507',version:6,expiryDate:'2027-07-31',manufactureDate:'2025-07-01'},
  DH2509:{lotId:'LOT-DH2509',version:4,expiryDate:'2027-09-30',manufactureDate:'2025-09-01'},
  DH2408:{lotId:'LOT-DH2408',version:9,expiryDate:'2026-08-31',manufactureDate:'2024-08-01'},
  AM2505:{lotId:'LOT-AM2505',version:5,expiryDate:'2027-05-31',manufactureDate:'2025-05-02'}
};
const BJ06_CONDITIONS={
  'RET-L1A':'Còn nguyên bao bì','RET-L1B':'Còn nguyên bao bì','RET-L2':'Đã mở hộp','RET-L3':'Bao bì móp',
  'RET-L4':'Bao bì móp','RET-L5':'Còn nguyên bao bì','RET-L6':'Đã mở hộp'
};
const BJ06_AUTH={
  'RET-L1A':3,'RET-L1B':4,'RET-L2':2,'RET-L3':3,'RET-L4':4,'RET-L5':5,'RET-L6':3
};
const bj06Attr =(v)=>escapeAttribute(String(v??''));
const bj06Upper =(v)=>String(v||'').trim().toUpperCase();
function bj06StableHash(input){let h1=2166136261>>>0,h2=2246822519>>>0;const s=typeof input==='string'?input:JSON.stringify(input);for(let i=0;i<s.length;i++){const c=s.charCodeAt(i);h1=Math.imul(h1^c,16777619);h2=Math.imul(h2^c,3266489917);}return `hash:${h1.toString(16).padStart(8,'0')}${h2.toString(16).padStart(8,'0')}`;}
function bj06IsoNow(){return '2026-09-16T08:00:00.000Z';}
function bj06DisplayTime(iso){if(!iso)return '—';const d=new Date(iso);return d.toLocaleString('vi-VN',{timeZone:'Asia/Ho_Chi_Minh',hour12:false});}
function bj06LineMax(line){return Math.max(0,Math.min(Number(line?.remaining??0),Number(line?.remainingAuthorized??line?.authorizedQuantity??line?.remaining??0)));}
function bj06LotMeta(code){return BJ06_LOTS[bj06Upper(code)]||null;}
function bj06ResolveLot(line){
  if(!line||line.tracking!=='LOT')return {kind:'NONE'};
  const code=bj06Upper(line.actualLot);if(!code)return {kind:'MISSING'};
  const meta=bj06LotMeta(code);
  if(meta){line.actualLotResolution='EXISTING';line.actualLotId=meta.lotId;line.actualLotVersion=meta.version;line.actualLotExpiry=meta.expiryDate;line.actualLotManufacture=meta.manufactureDate;return {kind:'EXISTING',...meta};}
  line.actualLotResolution='NEW';line.actualLotId=null;line.actualLotVersion=null;line.actualLotExpiry=line.newLotExpiry||'';line.actualLotManufacture=line.newLotManufacture||'';return {kind:'NEW',expiryDate:line.actualLotExpiry,manufactureDate:line.actualLotManufacture};
}
function bj06LotDataReady(line){
  if(!line||line.tracking!=='LOT')return true;
  const r=bj06ResolveLot(line);if(r.kind==='MISSING')return false;
  if(r.kind==='NEW'&&line.expiryRequired&&!String(line.newLotExpiry||'').trim())return false;
  return true;
}
function bj06Expiry(line){const r=bj06ResolveLot(line);return r.expiryDate||'';}
function bj06IsExpired(line){const exp=bj06Expiry(line);return Boolean(exp&&exp<BJ06_BUSINESS_DATE);}
function bj06EvidenceIdentity(line){return {id:line.evidenceId||'',version:Number(line.evidenceVersion||0),contentHash:line.evidenceHash||''};}
function bj06SnapshotCore(req,line){
  const lot=bj06ResolveLot(line);
  return {requestId:req.id,source:req.source,sourceVersion:req.sourceVersion,lineId:line.id,product:line.name,productCode:line.code,uom:line.uom,quantity:Number(line.qty??0),authorizedQuantity:Number(line.authorizedQuantity??0),sourceLot:line.expectedLot||null,actualLot:line.actualLot||null,actualLotResolution:lot.kind,actualLotId:line.actualLotId||null,actualLotVersion:line.actualLotVersion||null,expiryDate:lot.expiryDate||null,manufactureDate:lot.manufactureDate||null,reasonCode:line.reasonCode||'',reasonDetail:(line.reasonDetail||'').trim(),evidence:bj06EvidenceIdentity(line)};
}
function bj06SubjectHash(req,line){return bj06StableHash(bj06SnapshotCore(req,line));}
async function bj06FileSha256(file){const buf=await file.arrayBuffer();if(globalThis.crypto?.subtle){const digest=await crypto.subtle.digest('SHA-256',buf);return 'sha256:'+Array.from(new Uint8Array(digest)).map(b=>b.toString(16).padStart(2,'0')).join('');}let h=2166136261>>>0;for(const b of new Uint8Array(buf))h=Math.imul(h^b,16777619);return 'fnv1a:'+h.toString(16).padStart(8,'0');}

// Normalize fixture semantics without inventing a new return-receipt business object.
io06Requests.forEach((r,i)=>{r.operationId=r.operationId||`IO-CRET-${String(i+1).padStart(3,'0')}`;r.returnRequestId=r.id;});
Object.values(io06LinesByRequest).flat().forEach(line=>{
  line.tracking=line.expectedLot?'LOT':'NONE';line.expiryRequired=line.tracking==='LOT';line.quantityStep=line.quantityStep||1;
  line.authorizedQuantity=Number(BJ06_AUTH[line.id]??line.remaining??0);line.receivedAgainstAuthorization=0;line.remainingAuthorized=line.authorizedQuantity;
  line.declaredCondition=BJ06_CONDITIONS[line.id]||'Chưa khai báo';line.newLotExpiry=line.newLotExpiry||'';line.newLotManufacture=line.newLotManufacture||'';
  if(line.evidenceData&&!line.evidenceId){line.evidenceId=`EV-${line.id}-001`;line.evidenceVersion=1;line.evidenceHash='fixture:'+bj06StableHash(line.evidenceData).slice(5);}
  if(line.actualLot)bj06ResolveLot(line);
});
// Expired demonstration is whole-lot/system-derived, never a user split.
const expiredFixture=io06FindLine('RET-L4');if(expiredFixture){expiredFixture.expectedLot='DH2408';expiredFixture.actualLot='DH2408';expiredFixture.actualLotMode='EXPECTED';expiredFixture.knownExpired=0;bj06ResolveLot(expiredFixture);expiredFixture.classification={sellable:0,quarantine:0,damaged:0,expired:Number(expiredFixture.qty||0)};}
const initialCase=io06ApprovalCases.find(c=>c.id==='EX-06-001');const initialLine=io06FindLine('RET-L6');const initialReq=io06Requests.find(r=>r.id==='RET-260827-07');
if(initialCase&&initialLine&&initialReq){initialLine.reasonCode='RETURNED_DIFFERENT_LOT';initialLine.reasonDetail='';if(!initialLine.evidenceId){initialLine.evidenceId='EV-RET-L6-001';initialLine.evidenceVersion=1;initialLine.evidenceHash='fixture:'+bj06StableHash(initialLine.evidenceData).slice(5);}initialCase.approvalScope='LINE_EXCEPTION';initialCase.subjectLineId=initialLine.id;initialCase.snapshot=bj06SnapshotCore(initialReq,initialLine);initialCase.subjectSnapshotHash=bj06SubjectHash(initialReq,initialLine);initialCase.snapshotHash=initialCase.subjectSnapshotHash;initialCase.makerId=BJ06_MAKER.id;}

// Shared runtime functions are overridden to match approved contracts.
function io06CaseSnapshot(req,line){return bj06SnapshotCore(req,line);}
function io06SnapshotMatches(line,caseObj){if(!line||!caseObj)return false;const req=io06Requests.find(r=>r.id===caseObj.requestId);if(!req)return false;return String(caseObj.subjectSnapshotHash||caseObj.snapshotHash||'')===bj06SubjectHash(req,line);}
function io06InvalidateCaseIfChanged(line){const c=io06LineCase(line);if(!c||io06SnapshotMatches(line,c))return;if(['APPROVED','REJECTED','PENDING'].includes(c.status)){c.status='SUPERSEDED';c.supersededAt=bj06IsoNow();line.exceptionCaseId=null;}}
function io06LinePhysicalValid(line){if(!line||!line.verified)return false;const q=Number(line.qty);if(!Number.isFinite(q)||q<0||q>bj06LineMax(line))return false;if(line.tracking==='LOT'&&!String(line.actualLot||'').trim())return false;if(!bj06LotDataReady(line))return false;return true;}
function io06LineEvidenceReady(line){if(!io06Mismatch(line))return true;return ['RETURNED_DIFFERENT_LOT','OTHER'].includes(line.reasonCode)&&Boolean(line.evidenceId&&line.evidenceVersion&&line.evidenceHash&&line.evidenceData)&&(line.reasonCode!=='OTHER'||Boolean((line.reasonDetail||'').trim()))&&bj06LotDataReady(line);}
function io06LineApprovalState(line){if(!io06Mismatch(line))return 'NOT_REQUIRED';const c=io06LineCase(line);if(c&&io06SnapshotMatches(line,c))return c.status;if(c&&!io06SnapshotMatches(line,c))return 'SUPERSEDED';return io06LineEvidenceReady(line)&&line.verified?'DRAFT':'NEEDS_EVIDENCE';}
function io06RequestAllVerified(req=io06CurrentRequest()){const lines=io06LinesForRequest(req.id);return lines.length>0&&lines.every(io06LinePhysicalValid)&&lines.some(l=>Number(l.qty||0)>0);};
function io06RequestCanSubmitExceptions(req=io06CurrentRequest()){const lines=io06LinesForRequest(req.id);return io06RequestAllVerified(req)&&lines.some(l=>io06Mismatch(l)&&!['PENDING','APPROVED'].includes(io06LineApprovalState(l)))&&lines.filter(io06Mismatch).every(l=>io06LineEvidenceReady(l));};
function io06ReceiptReady(req=io06CurrentRequest()){const lines=io06LinesForRequest(req.id);return io06RequestAllVerified(req)&&lines.every(l=>!io06Mismatch(l)||io06LineApprovalState(l)==='APPROVED');};
function io06CreateCase(req,line){const prev=io06LineCase(line);if(prev&&prev.status!=='SUPERSEDED'){prev.status='SUPERSEDED';prev.supersededAt=bj06IsoNow();}const snap=bj06SnapshotCore(req,line);const c={id:`EX-06-${String(io06ApprovalSeq++).padStart(3,'0')}`,requestId:req.id,lineId:line.id,subjectLineId:line.id,approvalScope:'LINE_EXCEPTION',status:'PENDING',maker:BJ06_MAKER.name,makerId:BJ06_MAKER.id,createdAt:new Date().toLocaleString('vi-VN',{timeZone:'Asia/Ho_Chi_Minh'}),decisionReason:'',snapshot:snap,subjectSnapshotHash:bj06StableHash(snap)};io06ApprovalCases.push(c);line.exceptionCaseId=c.id;return c;}
function io06SetLineDirty(line){if(!line)return;line.verified=false;io06InvalidateCaseIfChanged(line);}
function io06ClassTotal(line,c=line.classification||{}){return Number(c.sellable||0)+Number(c.quarantine||0)+Number(c.damaged||0)+Number(c.expired||0);}
function io06ClassValid(line,state='READY',c=line.classification||{}){const qty=Number(line?.qty);if(!line||!Number.isFinite(qty)||qty<0)return false;const expired=bj06IsExpired(line)||state==='EXPIRED_GUARD'&&line===io06ActiveLine();if(expired)return Number(c.expired||0)===qty&&Number(c.sellable||0)===0&&Number(c.quarantine||0)===0&&Number(c.damaged||0)===0;return Number(c.expired||0)===0&&(Number(c.sellable||0)+Number(c.quarantine||0)+Number(c.damaged||0)===qty);}
function io06AllClassValid(state='READY'){const lines=io06CurrentLines();return lines.length>0&&lines.every(l=>io06ClassValid(l,state));}
function io06ClassificationDraftFor(line){if(!line)return null;if(!io06ClassificationDraft||io06ClassificationDraft.lineId!==line.id){const expired=bj06IsExpired(line);io06ClassificationDraft={lineId:line.id,sellable:expired?0:Number(line.classification?.sellable||0),quarantine:expired?0:Number(line.classification?.quarantine||0),damaged:expired?0:Number(line.classification?.damaged||0),expired:expired?Number(line.qty||0):0};}return io06ClassificationDraft;}
function updateIO06ClassificationLive(){const line=io06ActiveLine();const draft=io06ClassificationDraftFor(line);if(!line||!draft)return;document.querySelectorAll('[data-io06-class]').forEach(el=>{draft[el.dataset.io06Class]=Math.max(0,Number(el.value)||0);});draft.expired=bj06IsExpired(line)?Number(line.qty||0):0;const total=io06ClassTotal(line,draft);const progress=document.querySelector('[data-io06-class-progress] .ds24-info-row__value,[data-io06-class-progress] strong');if(progress)progress.textContent=`${total}/${io06QtyDisplay(line.qty)} ${line.uom}`;const feedback=document.querySelector('[data-io06-class-feedback]');if(feedback)feedback.innerHTML=total>Number(line.qty||0)?vBanner('error','Vượt lượng cần phân loại',`Đang phân loại ${total}/${io06QtyDisplay(line.qty)} ${line.uom}.`,'','Compact'):'';const done=document.querySelector('[data-io06-action="close-classification-item"]');if(done)done.disabled=!io06ClassValid(line,stateByScreen['SCR-033'],draft);}

function bj06LotDetailsHtml(line,pending=false){
  if(line.tracking!=='LOT'||!String(line.actualLot||'').trim())return '';
  const r=bj06ResolveLot(line);if(r.kind==='EXISTING')return ds24InfoGroup('Lô thực nhận đã có',`${ds24InfoRow('Mã lô',bj06Upper(line.actualLot))}${ds24InfoRow('Hạn dùng',r.expiryDate||'Không có')}${r.manufactureDate?ds24InfoRow('Ngày sản xuất',r.manufactureDate):''}`,'v394-lot-resolved');
  const disabled=pending?'disabled':'';const expiry=io06TextField(`Hạn dùng${line.expiryRequired?' *':''}`,line.newLotExpiry||'',`data-v394-new-lot-expiry type="date" ${disabled}`,line.expiryRequired?'Bắt buộc theo cấu hình sản phẩm.':'','Default');const mfg=io06TextField('Ngày sản xuất',line.newLotManufacture||'',`data-v394-new-lot-manufacture type="date" ${disabled}`,'Không bắt buộc.','Default');return `<section class="io06-section v394-new-lot" data-ds-component="VSection">${ds24SectionTitle('Thông tin lô mới')}${expiry}${mfg}</section>`;
}
function bj06EvidenceHtml(line,pending,force=false){const mismatch=io06Mismatch(line);if(!mismatch&&!force)return '';const reasonLabels=[['RETURNED_DIFFERENT_LOT','Khách trả lô khác lô đã giao'],['OTHER','Khác']];const hashReady=Boolean(line.evidenceHash);return `${vBanner('warning','Lô thực nhận khác lô đã giao','Cần lý do, ảnh nhãn lô và phê duyệt trước khi ghi nhận.','','Compact')}<section class="io06-section">${ds24SectionTitle('Lý do ngoại lệ')}<div class="io06-selection-list io06-reason-list">${reasonLabels.map(([k,l])=>io06SelectionRow({title:l,selected:line.reasonCode===k,attrs:`data-io06-reason="${k}"`,disabled:pending,leading:'circleAlert'})).join('')}</div></section>${line.reasonCode==='OTHER'?io06Textarea('Mô tả thêm *',line.reasonDetail||'',`data-io06-reason-detail ${pending?'disabled':''}`,'Nêu ngắn gọn tình huống thực tế.'):''}<label class="io06-file-field" data-ds-component="VFileDropZone"><span class="io06-field__label">Ảnh nhãn lô thực nhận *</span><span class="io06-file-control">${icon('fileText','icon--sm')}<span><strong>${esc(line.evidenceFile||'Chọn ảnh nhãn lô')}</strong><small>${line.evidenceFile?(hashReady?'Ảnh đã khóa nội dung cho approval':'Đang xác minh nội dung ảnh'):'Ảnh rõ mã lô'}</small></span><input data-io06-evidence-file type="file" accept="image/*" ${pending?'disabled':''}/></span></label>${line.evidenceData?`<div class="io-evidence-preview"><img src="${line.evidenceData}" alt="Ảnh nhãn lô thực nhận"/><span>${esc(line.evidenceFile||'Ảnh nhãn lô')}</span></div>`:''}`;}
function io06RequestRow(r){
  const target=r.phase==='CLASSIFICATION'?'SCR-033':'SCR-031';const waiting=r.queue==='WAITING';const tone=waiting?'Warning':r.status.includes('phân loại')?'Info':r.status.includes('ngoại lệ')?'Warning':'Neutral';const label=waiting?'Chờ duyệt lô':r.status;
  return ds24ListRow({title:r.id,subtitle:`${r.customer} · ${r.source}`,trailing:ds24Badge(label,tone),leading:null,attrs:waiting?'':`data-io06-request="${bj06Attr(r.id)}" data-io06-target="${target}" data-io06-search-text="${bj06Attr(ioNormalizeSearch(`${r.id} ${r.source} ${r.customer}`))}"`,type:waiting?'Status':'Navigation',state:waiting?'Disabled':'Default',interactive:!waiting,disabled:waiting});
}
function io06ReturnLineRow(line,waiting=false){
  const approval=io06LineApprovalState(line);let badge='',tone='Neutral';if(approval==='PENDING'){badge='Chờ duyệt lô';tone='Warning';}else if(approval==='REJECTED'){badge='Bị từ chối';tone='Danger';}else if(approval==='APPROVED'){badge='Đã duyệt';tone='Success';}else if(approval==='DRAFT'){badge='Chờ gửi duyệt';tone='Warning';}else if(line.verified){badge='Đã kiểm';tone='Success';}
  const qty=line.verified?`${io06QtyDisplay(line.qty)} ${line.uom}`:`Tối đa ${io06QtyDisplay(bj06LineMax(line))} ${line.uom}`;const row=ds24ListRow({title:line.name,subtitle:`${line.code} · ${line.uom}`,trailing:`<span class="io06-row-trailing"><strong>${esc(qty)}</strong>${badge?ds24Badge(badge,tone):''}</span>`,leading:'package',attrs:waiting?'':`data-io06-line="${bj06Attr(line.id)}"`,type:waiting?'Status':'Navigation',state:waiting?'Disabled':'Default',interactive:!waiting,disabled:waiting});const lotFacts=line.tracking==='LOT'?`<div class="v394-lot-facts" data-composed-from="DS v2 / Info Row">${ds24InfoRow('Lô giao',line.expectedLot||'—')}${line.verified&&line.actualLot&&bj06Upper(line.actualLot)!==bj06Upper(line.expectedLot)?ds24InfoRow('Lô thực nhận',bj06Upper(line.actualLot)):''}</div>`:'';return `<div class="v394-return-line">${row}${lotFacts}</div>`;
}
function render032BJ06(state){const line=io06ActiveLine();if(!line)return appShell({title:'Chi tiết hàng trả',body:ioEmpty('Không có dòng hàng','Quay lại yêu cầu để chọn dòng hàng.'),centered:true});if(state==='PERMISSION_DENIED')return appShell({title:'Chi tiết hàng trả',body:deniedBody(),centered:true});
  const caseState=io06LineApprovalState(line),pending=caseState==='PENDING',approved=caseState==='APPROVED',rejected=caseState==='REJECTED';const max=bj06LineMax(line),q=Number(line.qty??0),capInvalid=Number.isFinite(q)&&q>max,mismatch=io06Mismatch(line);if(mismatch&&!line.reasonCode)line.reasonCode='RETURNED_DIFFERENT_LOT';
  const status=pending?vBanner('warning','Ngoại lệ đang chờ duyệt','Dữ liệu đã gửi duyệt đang được khóa.','','Compact'):approved?vBanner('success','Ngoại lệ lô đã được duyệt','Thay đổi dữ liệu sẽ tạo approval subject mới.','','Compact'):rejected?vBanner('error','Ngoại lệ lô bị từ chối','Cập nhật lô hoặc bằng chứng rồi gửi lại.','','Compact'):'';
  const identity=ds24ListRow({title:line.name,subtitle:`${line.code} · ${line.uom}`,leading:'package',type:'Status',interactive:false,density:'Compact'});
  const facts=ds24InfoGroup('Căn cứ trả hàng',`${line.comboName?ds24InfoRow('Thuộc',line.comboName):''}${ds24InfoRow('Được phép nhận lần này',`${io06QtyDisplay(max)} ${line.uom}`)}${ds24InfoRow('Tình trạng khai báo',line.declaredCondition||'—')}${line.expectedLot?ds24InfoRow('Lô đã giao',line.expectedLot):''}`,'io06-source-facts');
  const qty=io06TextField('Số lượng thực nhận *',line.qty==null?'':line.qty,`data-io06-qty type="number" min="0" max="${max}" step="${line.quantityStep||1}" inputmode="decimal" ${pending?'disabled':''}`,`Tối đa theo yêu cầu trả hiện tại: ${io06QtyDisplay(max)} ${line.uom}`,pending?'Disabled':'Default');
  const other=line.tracking==='LOT'&&(line.actualLotMode==='OTHER'||Boolean(line.actualLot&&bj06Upper(line.actualLot)!==bj06Upper(line.expectedLot)));let lotControl='';if(line.tracking==='LOT'){lotControl=`<section class="io06-section">${ds24SectionTitle('Lô thực nhận')}<div class="io06-selection-list">${io06SelectionRow({title:`Lô ${line.expectedLot}`,subtitle:'Đúng lô đã giao',selected:!other&&bj06Upper(line.actualLot)===bj06Upper(line.expectedLot),attrs:`data-io06-select-actual-lot="${bj06Attr(line.expectedLot)}"`,disabled:pending})}${io06SelectionRow({title:'Lô khác',subtitle:'Thực nhận khác lô đã giao',selected:other,attrs:'data-io06-select-other-lot',disabled:pending})}</div></section>${other?io06TextField('Mã lô thực nhận *',line.actualLot||'',`data-io06-actual-lot placeholder="Nhập hoặc quét mã lô" ${pending?'disabled':''}`,'',pending?'Disabled':'Default'):''}<div data-v394-lot-details>${other?bj06LotDetailsHtml(line,pending):''}</div>`;}
  const evidence=bj06EvidenceHtml(line,pending,other);const sameLotInOther=Boolean(other&&line.actualLot&&bj06Upper(line.actualLot)===bj06Upper(line.expectedLot));const lotInvalid=line.tracking==='LOT'&&!bj06LotDataReady(line);const body=`${identity}${facts}${status}${qty}<p class="field-error" data-io06-cap-error ${capInvalid?'':'hidden'}>Không thể nhận vượt ${io06QtyDisplay(max)} ${line.uom} được phép trong yêu cầu hiện tại.</p>${lotControl}${sameLotInOther?`<p class="field-error">Nếu lô thực nhận trùng lô đã giao, hãy chọn Lô ${esc(line.expectedLot)}.</p>`:''}${lotInvalid&&line.actualLot?`<p class="field-error">Cần hoàn thiện thông tin lô trước khi lưu.</p>`:''}${evidence}`;
  let actions='';if(!pending){const commonInvalid=capInvalid||q<0||!Number.isFinite(q)||lotInvalid||sameLotInOther;if(other&&!approved)actions=primaryFooter('Lưu ngoại lệ','data-io06-action="save-return-exception"',commonInvalid||!io06LineEvidenceReady(line));else actions=primaryFooter('Xong','data-io06-action="save-return-line"',commonInvalid||Boolean(line.tracking==='LOT'&&!line.actualLot));}
  return appShell({title:'Chi tiết hàng trả',body,actions});
};
function render034BJ06(state){if(state==='PERMISSION_DENIED')return appShell({title:'Ngoại lệ lô cần duyệt',subtitle:'Việc dành cho người phê duyệt',body:deniedBody(),centered:true,back:false,actions:primaryFooter('Về danh sách','data-v360-action="fallback-exit" data-v360-target="SCR-030"')});const pendingCases=io06ApprovalCases.filter(c=>c.status==='PENDING');
  if(io06ApproverListMode||state==='TASK_LIST'||!io06SelectedApprovalCase()){const rows=pendingCases.map(c=>{const l=io06ApprovalCaseLine(c),r=io06Requests.find(x=>x.id===c.requestId);return ds24ListRow({title:l?.name||'Mặt hàng',subtitle:`${r?.id||c.requestId} · ${r?.customer||''}`,trailing:ds24Badge('Chờ quyết định','Warning'),leading:'package',attrs:`data-io06-approval-case="${bj06Attr(c.id)}"`,type:'Navigation'});}).join('');return appShell({title:'Ngoại lệ lô cần duyệt',subtitle:'Việc dành cho người phê duyệt',body:`<section class="io06-section">${ds24SectionTitle('Cần bạn quyết định',`${pendingCases.length} ngoại lệ`)}${rows?`<div class="ds24-list-stack">${rows}</div>`:ioEmpty('Không còn ngoại lệ chờ duyệt','Các quyết định đã hoàn tất hoặc chưa có yêu cầu mới.')}</section>`,back:false});}
  const c=io06SelectedApprovalCase(),line=io06ApprovalCaseLine(c),req=io06Requests.find(r=>r.id===c?.requestId);if(!c||!line)return appShell({title:'Duyệt ngoại lệ lô',body:ioEmpty('Không tìm thấy ngoại lệ','Quay lại danh sách phê duyệt.'),centered:true,backAction:'exit-io06-approval'});const snap=c.snapshot||{};const labels={RETURNED_DIFFERENT_LOT:'Khách trả lô khác lô đã giao',OTHER:'Khác'};
  const rejectSheet=io06RejectOpen?`<div class="sheet-backdrop io06-sheet-backdrop" data-io06-reject-backdrop><section class="bottom-sheet io06-bottom-sheet io06-reject-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true"><div class="sheet-handle"></div><div class="sheet-title"><h3>Từ chối ngoại lệ</h3></div><div class="sheet-content io06-sheet-content">${io06Textarea('Lý do từ chối *',io06RejectReason,'data-io06-reject-reason placeholder="Nhập lý do"','Bắt buộc để lưu quyết định.')}<div class="io06-sheet-actions"><button class="button button--secondary" data-io06-action="close-reject" type="button">Hủy</button><button class="button button--primary" data-io06-action="confirm-reject" type="button" ${io06RejectReason.trim()?'':'disabled'}>Xác nhận từ chối</button></div></div></section></div>`:'';
  const final=c.status!=='PENDING',decisionBanner=c.status==='APPROVED'?vBanner('success','Đã duyệt ngoại lệ','Quyết định đã khóa đúng bằng chứng đã gửi.','','Compact'):c.status==='REJECTED'?vBanner('error','Đã từ chối ngoại lệ',`Lý do: ${c.decisionReason||'—'}`,'','Compact'):'';const identity=ds24ListRow({title:snap.product||line.name,subtitle:`${snap.productCode||line.code} · ${snap.uom||line.uom}`,trailing:`<strong>${io06QtyDisplay(snap.quantity??snap.qty)} ${esc(snap.uom||line.uom)}</strong>`,leading:'package',type:'Status',interactive:false,density:'Compact'});const facts=ds24InfoGroup('Thông tin để quyết định',`${ds24InfoRow('Người gửi',c.maker||BJ06_MAKER.name)}${ds24InfoRow('Yêu cầu trả',req?.id||c.requestId)}${ds24InfoRow('Đơn bán',req?.source||snap.source||'—')}${ds24InfoRow('Lô đã giao',snap.sourceLot||snap.expectedLot||'—')}${ds24InfoRow('Lô thực nhận',snap.actualLot||'—')}${snap.expiryDate?ds24InfoRow('Hạn dùng lô thực nhận',snap.expiryDate):''}`,'io06-approval-facts');const reason=ds24InfoGroup('Căn cứ ngoại lệ',`${ds24InfoRow('Lý do',labels[snap.reasonCode]||snap.reasonCode||'—')}${snap.reasonCode==='OTHER'&&snap.reasonDetail?ds24InfoRow('Mô tả',snap.reasonDetail):''}`,'io06-approval-reason');const evidence=snap.evidence?.id&&line.evidenceData?`<div class="io06-evidence-card"><img src="${line.evidenceData}" alt="Ảnh nhãn lô thực nhận"><span>${esc(line.evidenceFile||'Ảnh nhãn lô')}</span></div>`:`<div class="io06-file-summary">${icon('fileText','icon--sm')}<span>Ảnh nhãn lô đã được khóa theo evidence version</span></div>`;const body=`${decisionBanner}${identity}${facts}${reason}<section class="io06-section">${ds24SectionTitle('Ảnh nhãn lô thực nhận')}${evidence}</section>${final?'':ioSecondary('Từ chối','data-io06-action="open-reject"')}${rejectSheet}`;return appShell({title:'Duyệt ngoại lệ lô',body,back:true,backAction:'exit-io06-approval',actions:final?primaryFooter('Về danh sách phê duyệt','data-io06-action="exit-approval-detail"'):primaryFooter('Duyệt ngoại lệ','data-io06-action="approve-exception"')});
};
function render033BJ06(state){if(state==='PERMISSION_DENIED')return appShell({title:'Phân loại hàng trả',body:deniedBody(),centered:true});const req=io06CurrentRequest(),lines=io06CurrentLines(),active=io06ActiveLine();if(['CONFLICT','LOCKED','SOURCE_CHANGED'].includes(state))return appShell({title:'Phân loại hàng trả',body:`${vBanner('warning','Dữ liệu hàng trả đã thay đổi','Về danh sách để mở lại dữ liệu hiện hành.','','Compact')}${ds24InfoGroup('',`${ds24InfoRow('Yêu cầu',req.id)}${ds24InfoRow('Đơn bán',req.source)}`,'io06-context')}`,actions:primaryFooter('Về Hàng khách trả','data-io06-action="result-to-return-queue"')});
  const rows=lines.map(line=>{const expired=bj06IsExpired(line)||state==='EXPIRED_GUARD'&&line===active;if(expired)line.classification={sellable:0,quarantine:0,damaged:0,expired:Number(line.qty||0)};const valid=io06ClassValid(line,state),lot=line.actualLot?`Lô ${line.actualLot}`:'Không theo lô';const status=expired?`Hết hạn · hệ thống xác định`:valid?'Đã phân loại':'Cần phân loại';return ds24ListRow({title:line.name,subtitle:`${line.code} · ${lot}`,trailing:`<span class="io06-row-trailing"><strong>${io06QtyDisplay(line.qty)} ${line.uom}</strong>${valid?ds24Badge(expired?'Hết hạn':'Đã xong',expired?'Warning':'Success'):''}</span>`,leading:'package',attrs:expired?'':`data-io06-class-line="${bj06Attr(line.id)}"`,type:expired?'Status':'Navigation',state:'Default',interactive:!expired,extraClass:expired?'v394-system-expired':''});}).join('');
  let sheet='';if(io06ClassificationOpen&&active){const expired=bj06IsExpired(active)||state==='EXPIRED_GUARD';const draft=io06ClassificationDraftFor(active);draft.expired=expired?Number(active.qty||0):0;const total=io06ClassTotal(active,draft);const progress=ds24KeyValueRow('Đã phân loại',`${total}/${io06QtyDisplay(active.qty)} ${active.uom}`,false,'data-io06-class-progress');const declared=active.declaredCondition?`<p class="io06-sheet-intro">Tình trạng khai báo: <strong>${esc(active.declaredCondition)}</strong>. Đây chỉ là thông tin đối chiếu.</p>`:'';if(expired){sheet=`<div class="sheet-backdrop io06-sheet-backdrop"><section class="bottom-sheet io06-bottom-sheet io06-classification-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(active.name)}</h3></div><div class="sheet-content io06-sheet-content">${vBanner('warning','Lô đã hết hạn',`Toàn bộ ${io06QtyDisplay(active.qty)} ${active.uom} được hệ thống xác định là Hết hạn. Không thể phân bổ sang trạng thái khác.`,'','Compact')}${declared}${ds24InfoGroup('',ds24InfoRow('Hết hạn',`${io06QtyDisplay(active.qty)} ${active.uom}`),'v394-expired-fact')}<div class="io06-sheet-actions"><button class="button button--secondary" data-io06-action="cancel-classification-item" type="button">Đóng</button></div></div></section></div>`;}else{const feedback=total>Number(active.qty||0)?vBanner('error','Vượt lượng cần phân loại',`Đang phân loại ${total}/${io06QtyDisplay(active.qty)} ${active.uom}.`,'','Compact'):'';const fields=[['sellable','Bán được'],['quarantine','Cách ly'],['damaged','Hỏng']].map(([k,l])=>io06TextField(l,draft[k],`data-io06-class="${k}" type="number" min="0" step="${active.quantityStep||1}" inputmode="decimal"`,'')).join('');sheet=`<div class="sheet-backdrop io06-sheet-backdrop"><section class="bottom-sheet io06-bottom-sheet io06-classification-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(active.name)}</h3></div><div class="sheet-content io06-sheet-content"><p class="io06-sheet-intro">${active.actualLot?`Lô ${esc(active.actualLot)} · `:''}Phân bổ ${io06QtyDisplay(active.qty)} ${esc(active.uom)} vào trạng thái vật lý.</p>${declared}${progress}<div class="io06-class-fields">${fields}</div><div data-io06-class-feedback>${feedback}</div><div class="io06-sheet-actions"><button class="button button--secondary" data-io06-action="cancel-classification-item" type="button">Hủy</button><button class="button button--primary" data-io06-action="close-classification-item" type="button" ${io06ClassValid(active,state,draft)?'':'disabled'}>Xong</button></div></div></section></div>`;}}
  const done=lines.filter(l=>io06ClassValid(l,state)).length;const context=ds24ContextStatusRow({title:req.id,subtitle:`${req.customer} · ${req.source}`,label:`${done}/${lines.length} đã xong`,tone:'Neutral',leading:null,attrs:'data-layout-role="classification-request-context"'});return appShell({title:'Phân loại hàng trả',body:`${context}<section class="io06-section">${ds24SectionTitle('Hàng cần phân loại')}<div class="ds24-list-stack">${rows}</div></section>${sheet}`,actions:primaryFooter('Hoàn tất phân loại','data-io06-action="confirm-classification"',!io06AllClassValid(state))});
};
function render035BJ06(state){const req=io06CurrentRequest(),lines=io06CurrentLines();if(state==='UNKNOWN'){const body=ioResult('Đang xác minh kết quả','Không gửi lại thao tác. Hệ thống đang xác minh đúng lần xử lý này; tiếp tục bằng cùng operation identity.',[['Yêu cầu trả',req.id],['Đơn bán',req.source],['Tồn kho','Chưa kết luận']],'warning');const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-06" data-operation="${bj06Attr(req.operationId)}" data-scope="${bj06Attr(req.id+' · '+req.source)}"`;return appShell({title:'Xác minh kết quả',body,centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả hàng trả',body:ioResult('Chưa thể ghi nhận','Dữ liệu hiện hành đã thay đổi; tồn kho chưa bị tác động.',[['Yêu cầu trả',req.id],['Đơn bán',req.source],['Tồn kho','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter(req.receiptCommitted?'Xem phần phân loại đã cập nhật':'Xem yêu cầu đã cập nhật',req.receiptCommitted?'data-io06-action="open-classification"':'data-io06-action="back-to-return-request"')});if(state==='PERMISSION_DENIED')return appShell({title:'Kết quả hàng trả',body:ioResult('Không có quyền thực hiện','Tồn kho không thay đổi.',[['Yêu cầu trả',req.id],['Đơn bán',req.source],['Tồn kho','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Về Hàng khách trả','data-io06-action="result-to-return-queue"')});
  if(state==='COMPLETED'||req.classified){const body=`<div class="io-result io06-result">${resultHero('Đã phân loại hàng trả','Chỉ phần đủ điều kiện mới trở lại khả dụng.')}${ds24InfoGroup('',`${ds24InfoRow('Yêu cầu trả',req.id)}${ds24InfoRow('Đơn bán',req.source)}${ds24InfoRow('Phân loại lúc',bj06DisplayTime(req.classifiedAt))}`,'io06-result-summary')}<section class="io06-section">${ds24SectionTitle('Kết quả theo sản phẩm và lô')}${io06ResultGroupsHtml(lines,{classified:true})}</section></div>`;return appShell({title:'Kết quả phân loại hàng trả',subtitle:'Bước cuối của yêu cầu khách trả',body,centered:false,back:false,actions:primaryFooter('Về Hàng khách trả','data-io06-action="result-to-return-queue"')});}
  const body=`<div class="io-result io06-result">${resultHero('Đã nhận hàng khách trả','Hàng đang chờ phân loại; chưa tự trở lại bán được.')}${ds24InfoGroup('',`${ds24InfoRow('Yêu cầu trả',req.id)}${ds24InfoRow('Đơn bán',req.source)}${ds24InfoRow('Ghi nhận lúc',bj06DisplayTime(req.recordedAt))}`,'io06-result-summary')}<section class="io06-section">${ds24SectionTitle('Hàng đã nhận')}${io06ResultGroupsHtml(lines)}</section>${ioSecondary('Để sau','data-io06-action="result-to-return-queue"')}</div>`;return appShell({title:'Đã nhận hàng khách trả',subtitle:'Còn bước phân loại trước khi hoàn tất',body,centered:false,back:false,actions:primaryFooter('Phân loại ngay','data-io06-action="open-classification"')});
};

function updateIO06LineValidation(){
  const line=io06ActiveLine();if(!line)return;
  const capInvalid=Number(line.qty||0)>Number(line.remaining||0);const mismatch=io06Mismatch(line);const evidenceValid=io06LineEvidenceReady(line);
  const err=document.querySelector('[data-io06-cap-error]');if(err){err.hidden=!capInvalid;err.textContent=`Không thể nhận vượt ${line.remaining} ${line.uom} còn được phép trả.`;}
  const btn=document.querySelector('.app-actions [data-io06-action]');if(btn){if(mismatch&&io06LineApprovalState(line)!=="APPROVED")btn.disabled=Number(line.qty||0)<=0||capInvalid||!evidenceValid;else btn.disabled=Number(line.qty||0)<=0||capInvalid||Boolean(line.expectedLot&&!line.actualLot);}
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
function io06QtyDisplay(qty){return qty==null||qty===""||!Number.isFinite(Number(qty))?"—":Number(qty).toLocaleString("vi-VN");}
function io06ResultGroupsHtml(lines,{classified=false}={}){
  const groups=new Map();
  for(const line of lines){const key=`${line.name}|${line.code}|${line.uom}`;if(!groups.has(key))groups.set(key,{name:line.name,code:line.code,uom:line.uom,lines:[]});groups.get(key).lines.push(line);}
  const statusLabel=classified?'Đã phân loại':'Đã nhận';
  const statusTone=classified?'Success':'Info';
  const subgroups=[...groups.values()].map(g=>{const productSummary=ds24ContextStatusRow({title:g.name,subtitle:`${g.code} · ${g.uom}`,label:statusLabel,tone:statusTone,leading:'package',attrs:'data-layout-role="io06-result-product-summary" data-ds-role="return-result-product-summary"'});const rows=g.lines.map(line=>{const lot=line.actualLot?`Lô ${line.actualLot}`:"Không theo lô";if(!classified)return ds24InfoRow(lot,`${io06QtyDisplay(line.qty)} ${line.uom}`);const c=line.classification||{};const states=[["Bán được",c.sellable],["Cách ly",c.quarantine],["Hỏng",c.damaged],["Hết hạn",c.expired]].filter(([,q])=>Number(q)>0).map(([label,q])=>ds24InfoRow(`${lot} · ${label}`,`${q} ${line.uom}`)).join("");return states||ds24InfoRow(lot,`0 ${line.uom}`);}).join("");return `<div class="io06-result-group ds24-grouped-subgroup" data-layout-role="return-result-product-subgroup" data-composed-from="DS v2 / List Row,DS v2 / Info Row">${productSummary}<div class="io06-result-rows">${rows}</div></div>`;}).join("");
  return ds24GroupedCollection(subgroups,"io06-result-groups io06-grouped-collection io06-grouped-collection--results","DS v2 / List Row,DS v2 / Info Row");
}
function render030BJ06(state){  const subtitle="Yêu cầu trả đủ điều kiện để Kho xử lý";
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
function render031BJ06(state){  const entrySubtitle=entryMode==="return-task"?"Yêu cầu được giao cho Kho":null;
  if(state==="PERMISSION_DENIED") return appShell({title:"Kiểm hàng khách trả",subtitle:entrySubtitle,body:deniedBody(),centered:true});
  if(state==="LOADING") return appShell({title:"Kiểm hàng khách trả",subtitle:entrySubtitle,body:loadingBody()});
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
  return appShell({title:"Kiểm hàng khách trả",subtitle:entrySubtitle,body,actions});
}

Object.assign(renderers, {
  "SCR-030": render030BJ06,
  "SCR-031": render031BJ06,
  "SCR-032": render032BJ06,
  "SCR-033": render033BJ06,
  "SCR-034": render034BJ06,
  "SCR-035": render035BJ06,
});

onUnknownHandoff["UIF-06"] = () => {
  const r = io06CurrentRequest();
  if (r) {
    r.unknownLocked = true;
    r.queue = "WAITING";
    r.status = "Đang xác minh kết quả";
  }
};


document.addEventListener("input", (event) => {
  if (activeFlowId !== "UIF-06") return;
  const t = event.target;
  if (t.matches("[data-io06-search]")) { io06Query = t.value; ioFilterRows("io06", io06Query); return; }
  if (t.matches("[data-io06-reason-detail]")) { const line = io06ActiveLine(); line.reasonDetail = t.value; io06SetLineDirty(line); updateIO06LineValidation(); return; }
  if (t.matches("[data-io06-reject-reason]")) { io06RejectReason = t.value; const b = document.querySelector('[data-io06-action="confirm-reject"]'); if (b) b.disabled = !io06RejectReason.trim(); return; }
  if (t.matches("[data-io06-class]")) { updateIO06ClassificationLive(); return; }
  if (t.matches("[data-io06-qty]")) { const line = io06ActiveLine(); const raw = t.value; line.qty = raw === "" ? null : Math.max(0, Number(raw) || 0); io06SetLineDirty(line); const max = bj06LineMax(line), err = document.querySelector("[data-io06-cap-error]"); if (err) { err.hidden = !(Number(line.qty || 0) > max); err.textContent = `Không thể nhận vượt ${io06QtyDisplay(max)} ${line.uom} được phép trong yêu cầu hiện tại.`; } return; }
  if (t.matches("[data-io06-actual-lot]")) { const line = io06ActiveLine(); line.actualLot = t.value; line.actualLotMode = "OTHER"; if (!line.reasonCode) line.reasonCode = "RETURNED_DIFFERENT_LOT"; io06SetLineDirty(line); const holder = document.querySelector("[data-v394-lot-details]"); if (holder) holder.innerHTML = bj06LotDetailsHtml(line, false); return; }
  if (t.matches("[data-v394-new-lot-expiry]")) { const line = io06ActiveLine(); line.newLotExpiry = t.value; io06SetLineDirty(line); return; }
  if (t.matches("[data-v394-new-lot-manufacture]")) { const line = io06ActiveLine(); line.newLotManufacture = t.value; io06SetLineDirty(line); return; }
});

document.addEventListener("change", (event) => {
  if (activeFlowId !== "UIF-06") return;
  const t = event.target;
  if (t.matches("[data-io06-actual-lot]")) { const line = io06ActiveLine(); line.actualLot = t.value; line.actualLotMode = "OTHER"; io06SetLineDirty(line); return renderAppScreen(); }
  if (t.matches("[data-io06-evidence-file]")) {
    const line = io06ActiveLine(), file = t.files?.[0];
    if (!file) { line.evidenceFile = ""; line.evidenceData = ""; line.evidenceId = ""; line.evidenceHash = ""; io06SetLineDirty(line); return renderAppScreen(); }
    line.evidenceFile = file.name;
    line.evidenceId = line.evidenceId || `EV-${line.id}-${String((line.evidenceVersion || 0) + 1).padStart(3, "0")}`;
    line.evidenceVersion = Number(line.evidenceVersion || 0) + 1;
    line.evidenceHash = "";
    io06SetLineDirty(line);
    const reader = new FileReader();
    reader.onload = async () => { line.evidenceData = String(reader.result || ""); line.evidenceHash = await bj06FileSha256(file); renderAppScreen(); }
    reader.readAsDataURL(file);
  }
});

document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-06") return;
  if (event.target.closest('[data-action="exit-io06-approval"]')) { io06ApproverListMode = true; io06RejectOpen = false; event.stopPropagation(); return renderAppScreen(); }

  const f6 = event.target.closest("[data-io06-filter]"); if (f6) { event.preventDefault(); io06QueueFilter = f6.dataset.io06Filter; return renderAppScreen(); }
  const r6 = event.target.closest("[data-io06-request]"); if (r6) { event.preventDefault(); io06SelectedRequestId = r6.dataset.io06Request; const lines = io06CurrentLines(); io06ActiveLineId = lines[0]?.id || ""; io06ClassificationOpen = false; io06ClassificationDraft = null; return navigate(r6.dataset.io06Target || "SCR-031"); }
  const line6 = event.target.closest("[data-io06-line]"); if (line6) { event.preventDefault(); io06ActiveLineId = line6.dataset.io06Line; return navigate("SCR-032"); }
  const classLine = event.target.closest("[data-io06-class-line]"); if (classLine) { event.preventDefault(); io06ActiveLineId = classLine.dataset.io06ClassLine; io06ClassificationOpen = true; return renderAppScreen(); }
  const reason6 = event.target.closest("[data-io06-reason]"); if (reason6) { event.preventDefault(); const line = io06ActiveLine(); line.reasonCode = reason6.dataset.io06Reason; if (line.reasonCode !== "OTHER") line.reasonDetail = ""; io06SetLineDirty(line); return renderAppScreen(); }
  const expectedLot6 = event.target.closest("[data-io06-select-actual-lot]"); if (expectedLot6) {
    event.preventDefault();
    const line = io06ActiveLine();
    // v394 prefix
    if (line) { line.newLotExpiry = ""; line.newLotManufacture = ""; line.evidenceId = ""; line.evidenceVersion = 0; line.evidenceHash = ""; }
    line.actualLot = expectedLot6.dataset.io06SelectActualLot; line.actualLotMode = "EXPECTED"; line.reasonCode = ""; line.reasonDetail = ""; line.evidenceFile = ""; line.evidenceData = "";
    io06SetLineDirty(line); return renderAppScreen();
  }
  const otherLot6 = event.target.closest("[data-io06-select-other-lot]"); if (otherLot6) {
    event.preventDefault();
    const line = io06ActiveLine();
    // v394 prefix
    if (line && !line.reasonCode) line.reasonCode = "RETURNED_DIFFERENT_LOT";
    line.newLotExpiry = ""; line.newLotManufacture = "";
    line.actualLotMode = "OTHER"; if (line.actualLot === line.expectedLot) line.actualLot = "";
    io06SetLineDirty(line); return renderAppScreen();
  }
  const approvalCase6 = event.target.closest("[data-io06-approval-case]"); if (approvalCase6) { event.preventDefault(); io06SelectedApprovalCaseId = approvalCase6.dataset.io06ApprovalCase; io06ApproverListMode = false; io06RejectOpen = false; stateByScreen["SCR-034"] = "READY"; return renderAppScreen(); }
  if (event.target.matches("[data-io06-reject-backdrop]")) { event.preventDefault(); io06RejectOpen = false; return renderAppScreen(); }

  const a = event.target.closest("[data-io06-action]"); if (!a) return;
  event.preventDefault(); event.stopPropagation();
  const k = a.dataset.io06Action;
  // 5 keys from v394
  if (k === "save-return-line") { const line = io06ActiveLine(), q = Number(line?.qty); if (!line || !Number.isFinite(q) || q < 0 || q > bj06LineMax(line) || !bj06LotDataReady(line) || Boolean(line.tracking === "LOT" && !line.actualLot)) return; line.verified = true; if (!io06Mismatch(line)) { const c = io06LineCase(line); if (c) { c.status = "SUPERSEDED"; c.supersededAt = bj06IsoNow(); } line.exceptionCaseId = null; line.reasonCode = ""; line.reasonDetail = ""; line.evidenceFile = ""; line.evidenceData = ""; line.evidenceId = ""; line.evidenceVersion = 0; line.evidenceHash = ""; } io06RefreshRequestState(io06CurrentRequest()); return navigate("SCR-031"); }
  if (k === "save-return-exception") { const line = io06ActiveLine(), q = Number(line?.qty); if (!line || !Number.isFinite(q) || q < 0 || q > bj06LineMax(line) || !io06Mismatch(line) || !io06LineEvidenceReady(line) || !bj06LotDataReady(line)) return; line.verified = true; io06InvalidateCaseIfChanged(line); io06RefreshRequestState(io06CurrentRequest()); return navigate("SCR-031"); }
  if (k === "commit-receipt") { const req = io06CurrentRequest(); if (!io06ReceiptReady(req)) return; req.receiptCommitted = true; req.recordedAt = bj06IsoNow(); req.phase = "CLASSIFICATION"; req.status = "Cần phân loại"; req.queue = "ACTIONABLE"; io06CurrentLines().forEach((l) => { l.receivedAgainstAuthorization = Number(l.qty || 0); l.remainingAuthorized = Math.max(0, Number(l.authorizedQuantity || 0) - l.receivedAgainstAuthorization); const exp = bj06IsExpired(l); l.classification = { sellable: 0, quarantine: 0, damaged: 0, expired: exp ? Number(l.qty || 0) : 0 }; }); stateByScreen["SCR-035"] = "RECEIVED_PENDING_CLASSIFICATION"; return navigate("SCR-035"); }
  if (k === "close-classification-item") { const line = io06ActiveLine(), draft = io06ClassificationDraftFor(line); if (!line || !io06ClassValid(line, stateByScreen["SCR-033"], draft)) return; line.classification = { sellable: Number(draft.sellable || 0), quarantine: Number(draft.quarantine || 0), damaged: Number(draft.damaged || 0), expired: bj06IsExpired(line) ? Number(line.qty || 0) : 0 }; io06ClassificationOpen = false; io06ClassificationDraft = null; return renderAppScreen(); }
  if (k === "confirm-classification") { if (!io06AllClassValid(stateByScreen["SCR-033"])) return; const req = io06CurrentRequest(); req.classified = true; req.classifiedAt = bj06IsoNow(); req.closed = true; req.status = "Đã phân loại"; req.queue = "CLOSED"; stateByScreen["SCR-035"] = "COMPLETED"; return navigate("SCR-035"); }
  // 11 keys from shared listener
  if (k === "submit-return-exceptions") { const req = io06CurrentRequest(); if (!io06SubmitDraftExceptions(req)) return; return renderAppScreen(); }
  if (k === "approve-exception") { const c = io06SelectedApprovalCase(); if (!c || c.status !== "PENDING") return; c.status = "APPROVED"; c.decisionReason = ""; io06AfterApprovalDecision(c); return renderAppScreen(); }
  if (k === "open-reject") { io06RejectOpen = true; io06RejectReason = ""; return renderAppScreen(); }
  if (k === "close-reject") { io06RejectOpen = false; return renderAppScreen(); }
  if (k === "confirm-reject") { if (!io06RejectReason.trim()) return; const c = io06SelectedApprovalCase(); if (!c || c.status !== "PENDING") return; c.status = "REJECTED"; c.decisionReason = io06RejectReason.trim(); io06RejectOpen = false; io06AfterApprovalDecision(c); return renderAppScreen(); }
  if (k === "exit-approval-detail") { io06ApproverListMode = true; io06RejectOpen = false; return renderAppScreen(); }
  if (k === "refresh-return-request") { const req = io06CurrentRequest(); const line = io06CurrentLines()[0]; if (stateByScreen["SCR-031"] === "RETURN_CAP_CHANGED" && line) { line.remaining = Math.max(1, Number(line.remaining || 0) - 1); if (Number(line.qty || 0) > line.remaining) { line.qty = null; line.verified = false; } } stateByScreen["SCR-031"] = "READY"; io06RefreshRequestState(req); return renderAppScreen(); }
  if (k === "open-classification") { io06ClassificationOpen = false; io06ClassificationDraft = null; stateByScreen["SCR-033"] = "READY"; return navigate("SCR-033"); }
  if (k === "cancel-classification-item") { io06ClassificationOpen = false; io06ClassificationDraft = null; return renderAppScreen(); }
  if (k === "result-to-return-queue") { io06QueueFilter = "ALL"; io06Query = ""; io06ClassificationOpen = false; io06ClassificationDraft = null; return navigate("SCR-030"); }
  if (k === "back-to-return-request") { stateByScreen["SCR-031"] = "READY"; return navigate("SCR-031"); }

}, true);

onPrevious["UIF-06"] = () => {
  if (activeScreenId === "SCR-031") return navigate("SCR-030");
  if (activeScreenId === "SCR-032") return navigate("SCR-031");
  if (activeScreenId === "SCR-033") { io06ClassificationOpen = false; io06ClassificationDraft = null; return navigate("SCR-030"); }
};

Object.assign(window.__VET45_QA__, {
  bumpIO06Source(){const r=io06CurrentRequest();r.sourceVersion=Number(r.sourceVersion||0)+1;io06RefreshRequestState(r);return r.sourceVersion;}
});
