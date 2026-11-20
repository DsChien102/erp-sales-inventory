/* BJ-06 — Hàng khách trả (UIF-06). Màn: SCR-030, SCR-031, SCR-032, SCR-033, SCR-034, SCR-035.
 *
 * Thiết kế lại (T7-P BJ-06, 2026-10-24, v5.12.0): mọi fixture, trạng thái, helper io06* / bj06*, hàm dựng và xử lý sự kiện
 * của BJ-06 nằm ở đây; sửa BJ-06: sửa thẳng file này.
 * Dùng từ khuôn (shared-patterns.js): k1Loading, k1Denied, k1Empty, k1Stale, k1Locked, k1ExitAttr (K1); k2Pending, k2Decision,
 * k2RejectSheet (K2); k3Unknown (K3); k4Result, k4ReasonFooter (K4); k6TaskList (K6); k7Split, k7Table, k7EditCell (K7);
 * dsSegmented, dsChoiceRow.
 * Dùng chung từ app/core.js: appShell, ds24*, vBanner, esc, escapeAttribute, navigate, renderAppScreen, onScreenEnter, onPrevious.
 * 031 + 032 trên web là MỘT trang hai cột (bảng dòng hàng | chi tiết dòng đang chọn): render032BJ06 ở khung web dựng như 031.
 * Nguồn "Chờ duyệt" của Home Kho (K2): đăng ký ở cuối file; lối vào trực tiếp ca chờ qua window.__T7_DIRECT_CONTEXTS__["bj06-approval"].
 * Handoff UNKNOWN: đăng ký onUnknownHandoff["UIF-06"]; nút data-k3-action="handoff" do k3Unknown dựng → bj17.js.
 * Trạng thái đặt từ bộ kiểm (đổi trạng thái màn) dựng lại fixture từ bản gốc rồi chuẩn bị đúng yêu cầu cho trạng thái đó: xem io06Seed.
 */

/* ---------- Fixture ---------- */

function io06EvidenceSvg(lot){const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="320" height="180"><rect width="100%" height="100%" rx="12" fill="#f6f7f8"/><rect x="22" y="22" width="276" height="136" rx="8" fill="#fff" stroke="#c7cdd3"/><text x="42" y="70" font-family="Arial" font-size="16" fill="#4b5563">Ảnh nhãn lô thực nhận</text><text x="42" y="112" font-family="Arial" font-size="30" font-weight="700" fill="#111827">LOT ${lot}</text></svg>`;return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`;}
const bj06BlankClass=()=>({sellable:0,quarantine:0,damaged:0,expired:0});
function bj06MakeLine(o){return {qty:null,actualLot:"",actualLotMode:"",verified:false,reasonCode:"",reasonDetail:"",evidenceFile:"",evidenceData:"",exceptionCaseId:null,classification:bj06BlankClass(),...o};}
const io06Requests=[
  {id:"RET-260827-03",source:"SO-260812-44",sourceVersion:5,customer:"Phòng khám Minh Tâm",status:"Cần nhận",queue:"ACTIONABLE",phase:"RECEIPT",receiptCommitted:false,classified:false,closed:false},
  {id:"RET-260827-05",source:"SO-260815-19",sourceVersion:3,customer:"Đại lý Nam Việt",status:"Cần phân loại",queue:"ACTIONABLE",phase:"CLASSIFICATION",receiptCommitted:true,classified:false,closed:false},
  {id:"RET-260827-07",source:"SO-260820-08",sourceVersion:7,customer:"Nhà thuốc thú y Hòa Bình",status:"Đang chờ duyệt lô",queue:"WAITING",phase:"RECEIPT",receiptCommitted:false,classified:false,closed:false}
];
const io06LinesByRequest={
  "RET-260827-03":[
    bj06MakeLine({id:"RET-L1A",name:"Nobivac DHPPi",code:"SP-000184",uom:"hộp",shipped:6,returnedBefore:2,remaining:4,expectedLot:"DH2507"}),
    bj06MakeLine({id:"RET-L1B",name:"Nobivac DHPPi",code:"SP-000184",uom:"hộp",shipped:4,returnedBefore:0,remaining:4,expectedLot:"DH2509"}),
    bj06MakeLine({id:"RET-L2",name:"Amox 500",code:"SP-000066",uom:"hộp",shipped:6,returnedBefore:1,remaining:5,expectedLot:"AM2505"}),
    bj06MakeLine({id:"RET-L3",name:"Băng cuộn y tế",code:"SP-000351",uom:"cuộn",shipped:3,returnedBefore:0,remaining:3,expectedLot:null,actualLot:null,comboName:"Combo chăm sóc hậu phẫu"})
  ],
  "RET-260827-05":[
    bj06MakeLine({id:"RET-L4",name:"Nobivac DHPPi",code:"SP-000184",uom:"hộp",shipped:8,returnedBefore:0,remaining:8,expectedLot:"DH2509",qty:4,actualLot:"DH2509",actualLotMode:"EXPECTED",verified:true}),
    bj06MakeLine({id:"RET-L5",name:"Găng tay khám Nitrile",code:"SP-000271",uom:"hộp",shipped:10,returnedBefore:0,remaining:10,expectedLot:null,qty:5,actualLot:null,verified:true})
  ],
  "RET-260827-07":[
    bj06MakeLine({id:"RET-L6",name:"Nobivac DHPPi",code:"SP-000184",uom:"hộp",shipped:10,returnedBefore:2,remaining:8,expectedLot:"DH2507",qty:3,actualLot:"DH2509",actualLotMode:"OTHER",verified:true,reasonCode:"RETURNED_DIFFERENT_LOT",evidenceFile:"anh-nhan-lo-DH2509.jpg",evidenceData:io06EvidenceSvg("DH2509"),exceptionCaseId:"EX-06-001"})
  ]
};
let io06ApprovalSeq=2;
const io06ApprovalCases=[
  {id:"EX-06-001",requestId:"RET-260827-07",lineId:"RET-L6",status:"PENDING",maker:"Nguyễn Minh · Thủ kho",makerId:"USR-WH-014",createdAt:"03/09/2026 09:18",decisionReason:""}
];

const BJ06_BUSINESS_DATE='2026-09-16';
const BJ06_MAKER={id:'USR-WH-001',name:'Nguyễn Văn An · Thủ kho'};
const BJ06_ACTOR_NAME="Nguyễn Văn An";
const BJ06_NOW_ISO='2026-09-16T08:00:00.000Z';
const BJ06_LOTS={
  DH2507:{lotId:'LOT-DH2507',version:6,expiryDate:'2026-11-30',manufactureDate:'2025-07-01'},
  DH2509:{lotId:'LOT-DH2509',version:4,expiryDate:'2026-09-30',manufactureDate:'2025-09-01'},
  DH2408:{lotId:'LOT-DH2408',version:9,expiryDate:'2026-08-31',manufactureDate:'2024-08-01'},
  AM2505:{lotId:'LOT-AM2505',version:5,expiryDate:'2027-05-31',manufactureDate:'2025-05-02'}
};
const BJ06_CONDITIONS={'RET-L1A':'Còn nguyên bao bì','RET-L1B':'Còn nguyên bao bì','RET-L2':'Đã mở hộp','RET-L3':'Bao bì móp','RET-L4':'Bao bì móp','RET-L5':'Còn nguyên bao bì','RET-L6':'Đã mở hộp'};
const BJ06_AUTH={'RET-L1A':3,'RET-L1B':4,'RET-L2':2,'RET-L3':3,'RET-L4':4,'RET-L5':5,'RET-L6':3};
const BJ06_CLASSES=[["SELLABLE","sellable","Bán được","Success"],["QUARANTINE","quarantine","Cách ly","Warning"],["DAMAGED","damaged","Hỏng","Danger"]];
const BJ06_REASONS=[["RETURNED_DIFFERENT_LOT","Khách trả lô khác lô đã giao"],["OTHER","Khác"]];
const IO06_DENIED={what:"nhận hàng khách trả",next:"Liên hệ chủ cửa hàng để được cấp quyền."};

const bj06Attr=(v)=>escapeAttribute(String(v??''));
const bj06Upper=(v)=>String(v||'').trim().toUpperCase();
function bj06StableHash(input){let h1=2166136261>>>0,h2=2246822519>>>0;const s=typeof input==='string'?input:JSON.stringify(input);for(let i=0;i<s.length;i++){const c=s.charCodeAt(i);h1=Math.imul(h1^c,16777619);h2=Math.imul(h2^c,3266489917);}return `hash:${h1.toString(16).padStart(8,'0')}${h2.toString(16).padStart(8,'0')}`;}
function bj06IsoNow(){return BJ06_NOW_ISO;}
// "dd/mm/yyyy hh:mm" giờ Việt Nam (cố định theo bj06IsoNow để ảnh golden không đổi).
function bj06DisplayTime(iso){if(!iso)return '—';const d=new Date(new Date(iso).getTime()+7*3600*1000),p=(n)=>String(n).padStart(2,'0');return `${p(d.getUTCDate())}/${p(d.getUTCMonth()+1)}/${d.getUTCFullYear()} ${p(d.getUTCHours())}:${p(d.getUTCMinutes())}`;}
function bj06DateVN(iso){const m=String(iso||'').match(/^(\d{4})-(\d{2})-(\d{2})$/);return m?`${m[3]}/${m[2]}/${m[1]}`:String(iso||'—');}
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

// Chuẩn hoá fixture (không tạo đối tượng nghiệp vụ mới): thông tin theo dõi lô, lượng được phép, bằng chứng, ca duyệt đầu tiên.
io06Requests.forEach((r,i)=>{r.operationId=`IO-CRET-${String(i+1).padStart(3,'0')}`;r.returnRequestId=r.id;r.unknownLocked=false;});
Object.values(io06LinesByRequest).flat().forEach(line=>{
  line.tracking=line.expectedLot?'LOT':'NONE';line.expiryRequired=line.tracking==='LOT';line.quantityStep=1;
  line.authorizedQuantity=Number(BJ06_AUTH[line.id]??line.remaining??0);line.receivedAgainstAuthorization=0;line.remainingAuthorized=line.authorizedQuantity;
  line.declaredCondition=BJ06_CONDITIONS[line.id]||'Chưa khai báo';line.newLotExpiry='';line.newLotManufacture='';
  if(line.evidenceData){line.evidenceId=`EV-${line.id}-001`;line.evidenceVersion=1;line.evidenceHash='fixture:'+bj06StableHash(line.evidenceData).slice(5);}
  if(line.actualLot)bj06ResolveLot(line);
});
{
  const c=io06ApprovalCases[0],line=io06LinesByRequest["RET-260827-07"][0],req=io06Requests[2];
  c.approvalScope='LINE_EXCEPTION';c.subjectLineId=line.id;c.snapshot=bj06SnapshotCore(req,line);c.subjectSnapshotHash=bj06SubjectHash(req,line);c.snapshotHash=c.subjectSnapshotHash;
}
// Bản gốc để dựng lại khi bộ kiểm đặt trạng thái từ ngoài (io06Restore).
const IO06_INITIAL=structuredClone({requests:io06Requests,lines:io06LinesByRequest,cases:io06ApprovalCases});

let io06SelectedRequestId="RET-260827-03", io06ActiveLineId="RET-L1A", io06Query="", io06QueueFilter="ALL", io06ApprovalQuery="";
let io06RejectOpen=false, io06RejectReason="", io06ClassificationOpen=false, io06ClassificationDraft=null, io06ResultSheetOpen=false, io06SelectedApprovalCaseId="EX-06-001";

/* ---------- Dữ liệu và quy tắc ---------- */

function io06CurrentRequest(){return io06Requests.find(r=>r.id===io06SelectedRequestId)||io06Requests.find(r=>!r.closed)||io06Requests[0];}
function io06LinesForRequest(id){return io06LinesByRequest[id]||[];}
function io06CurrentLines(){return io06LinesForRequest(io06CurrentRequest().id);}
function io06FindLine(id){for(const lines of Object.values(io06LinesByRequest)){const l=lines.find(x=>x.id===id);if(l)return l;}return null;}
function io06ActiveLine(){const lines=io06CurrentLines();return lines.find(l=>l.id===io06ActiveLineId)||lines[0];}
function io06LineCase(line){return line?.exceptionCaseId?io06ApprovalCases.find(c=>c.id===line.exceptionCaseId):null;}
function io06PendingCasesForRequest(id){return io06ApprovalCases.filter(c=>c.requestId===id&&c.status==="PENDING");}
function io06CasesForRequest(id){return io06ApprovalCases.filter(c=>c.requestId===id&&!['INVALIDATED','SUPERSEDED'].includes(c.status));}
function io06Mismatch(line=io06ActiveLine()){return Boolean(line?.expectedLot)&&Boolean(String(line.actualLot||"").trim())&&String(line.actualLot||"").trim().toUpperCase()!==String(line.expectedLot||"").trim().toUpperCase();}
// Dòng đang ở "Lô khác": đã chọn "Lô khác" hoặc mã lô thực nhận khác lô giao.
function bj06IsOther(line){return line.tracking==='LOT'&&(line.actualLotMode==='OTHER'||Boolean(line.actualLot&&bj06Upper(line.actualLot)!==bj06Upper(line.expectedLot)));}
function io06RefreshRequestState(req=io06CurrentRequest()){
  if(req.closed){req.queue="CLOSED";return;}
  if(req.unknownLocked){req.queue="WAITING";req.status="Đang xác minh kết quả";return;}
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

function io06CaseSnapshot(req,line){return bj06SnapshotCore(req,line);}
function io06SnapshotMatches(line,caseObj){if(!line||!caseObj)return false;const req=io06Requests.find(r=>r.id===caseObj.requestId);if(!req)return false;return String(caseObj.subjectSnapshotHash||caseObj.snapshotHash||'')===bj06SubjectHash(req,line);}
function io06InvalidateCaseIfChanged(line){const c=io06LineCase(line);if(!c||io06SnapshotMatches(line,c))return;if(['APPROVED','REJECTED','PENDING'].includes(c.status)){c.status='SUPERSEDED';c.supersededAt=bj06IsoNow();line.exceptionCaseId=null;}}
function io06LinePhysicalValid(line){if(!line||!line.verified)return false;const q=Number(line.qty);if(!Number.isFinite(q)||q<0||q>bj06LineMax(line))return false;if(line.tracking==='LOT'&&!String(line.actualLot||'').trim())return false;if(!bj06LotDataReady(line))return false;return true;}
function io06LineEvidenceReady(line){if(!io06Mismatch(line))return true;return ['RETURNED_DIFFERENT_LOT','OTHER'].includes(line.reasonCode)&&Boolean(line.evidenceId&&line.evidenceVersion&&line.evidenceHash&&line.evidenceData)&&(line.reasonCode!=='OTHER'||Boolean((line.reasonDetail||'').trim()))&&bj06LotDataReady(line);}
function io06LineApprovalState(line){if(!io06Mismatch(line))return 'NOT_REQUIRED';const c=io06LineCase(line);if(c&&io06SnapshotMatches(line,c))return c.status;if(c&&!io06SnapshotMatches(line,c))return 'SUPERSEDED';return io06LineEvidenceReady(line)&&line.verified?'DRAFT':'NEEDS_EVIDENCE';}
function io06RequestAllVerified(req=io06CurrentRequest()){const lines=io06LinesForRequest(req.id);return lines.length>0&&lines.every(io06LinePhysicalValid)&&lines.some(l=>Number(l.qty||0)>0);}
function io06RequestCanSubmitExceptions(req=io06CurrentRequest()){const lines=io06LinesForRequest(req.id);return io06RequestAllVerified(req)&&lines.some(l=>io06Mismatch(l)&&!['PENDING','APPROVED'].includes(io06LineApprovalState(l)))&&lines.filter(io06Mismatch).every(l=>io06LineEvidenceReady(l));}
function io06ReceiptReady(req=io06CurrentRequest()){const lines=io06LinesForRequest(req.id);return io06RequestAllVerified(req)&&lines.every(l=>!io06Mismatch(l)||io06LineApprovalState(l)==='APPROVED');}
function io06CreateCase(req,line){const prev=io06LineCase(line);if(prev&&prev.status!=='SUPERSEDED'){prev.status='SUPERSEDED';prev.supersededAt=bj06IsoNow();}const snap=bj06SnapshotCore(req,line);const c={id:`EX-06-${String(io06ApprovalSeq++).padStart(3,'0')}`,requestId:req.id,lineId:line.id,subjectLineId:line.id,approvalScope:'LINE_EXCEPTION',status:'PENDING',maker:BJ06_MAKER.name,makerId:BJ06_MAKER.id,createdAt:bj06DisplayTime(bj06IsoNow()),decisionReason:'',snapshot:snap,subjectSnapshotHash:bj06StableHash(snap)};io06ApprovalCases.push(c);line.exceptionCaseId=c.id;return c;}
function io06SetLineDirty(line){if(!line)return;line.verified=false;io06InvalidateCaseIfChanged(line);}

// Phân loại. Lô hết hạn: toàn bộ "Hết hạn", hệ thống xác định, không ghi đè. Lượng chưa nhập (null) không bao giờ tính là xong.
function io06ClassTotal(line,c=line.classification||{}){return Number(c.sellable||0)+Number(c.quarantine||0)+Number(c.damaged||0)+Number(c.expired||0);}
function io06EffClass(line){return bj06IsExpired(line)?{sellable:0,quarantine:0,damaged:0,expired:Number(line.qty||0)}:(line.classification||bj06BlankClass());}
function io06ClassValid(line,c=io06EffClass(line)){
  if(!line||line.qty==null||line.qty==="")return false;
  const qty=Number(line.qty);if(!Number.isFinite(qty)||qty<0)return false;
  if(bj06IsExpired(line))return Number(c.expired||0)===qty&&Number(c.sellable||0)===0&&Number(c.quarantine||0)===0&&Number(c.damaged||0)===0;
  return Number(c.expired||0)===0&&Number(c.sellable||0)+Number(c.quarantine||0)+Number(c.damaged||0)===qty;
}
function io06AllClassValid(){const lines=io06CurrentLines();return lines.length>0&&lines.every(l=>io06ClassValid(l));}
function io06ClassModeOf(line){
  if(bj06IsExpired(line))return "EXPIRED";
  const q=Number(line.qty||0),c=line.classification||{};
  if(line.classMode==="SPLIT")return "SPLIT";
  const whole=BJ06_CLASSES.find(([,key])=>q>0&&Number(c[key])===q&&io06ClassTotal(line,c)===q);
  if(whole)return whole[0];
  return io06ClassTotal(line,c)>0?"SPLIT":null;
}
function io06ClassModeLabel(mode){return mode==="SPLIT"?"Chia nhiều loại":mode==="EXPIRED"?"Hết hạn":(BJ06_CLASSES.find(x=>x[0]===mode)||[])[2]||"";}
function bj06ClassifyWhole(line,mode){const key=(BJ06_CLASSES.find(x=>x[0]===mode)||BJ06_CLASSES[0])[1];line.classification={...bj06BlankClass(),[key]:Number(line.qty||0)};line.classMode=mode;}
function io06ClassificationDraftFor(line){
  if(!line)return null;
  if(!io06ClassificationDraft||io06ClassificationDraft.lineId!==line.id){const c=line.classification||bj06BlankClass();io06ClassificationDraft={lineId:line.id,mode:io06ClassModeOf(line),sellable:Number(c.sellable||0),quarantine:Number(c.quarantine||0),damaged:Number(c.damaged||0)};}
  return io06ClassificationDraft;
}
function io06DraftValid(line,d){return Number(d.sellable||0)+Number(d.quarantine||0)+Number(d.damaged||0)===Number(line.qty||0);}

// Nhận hàng (commit): hàng vào "chờ phân loại"; lô đã hết hạn tự xếp "Hết hạn". Giá trị ghi cùng lúc nhận.
function bj06CommitReceipt(req){
  req.receiptCommitted=true;req.recordedAt=bj06IsoNow();req.receivedBy=BJ06_ACTOR_NAME;req.phase="CLASSIFICATION";req.status="Cần phân loại";req.queue="ACTIONABLE";
  io06LinesForRequest(req.id).forEach((l)=>{l.receivedAgainstAuthorization=Number(l.qty||0);l.remainingAuthorized=Math.max(0,Number(l.authorizedQuantity||0)-l.receivedAgainstAuthorization);l.classMode=null;l.classification={...bj06BlankClass(),expired:bj06IsExpired(l)?Number(l.qty||0):0};});
}
// Chỉ dùng khi mở thẳng ảnh trạng thái: yêu cầu đã nhận đủ lượng được phép theo đúng lô đã giao.
// Phân loại xong là lúc hàng khách trả vào tồn theo từng tình trạng: ghi vào sổ chung (sản phẩm không có ở BJ-01 thì bỏ qua).
function bj06PostReturn(req,line){
  const c=line.classification||bj06BlankClass();
  [["Bán được","sellable"],["Cách ly","quarantine"],["Hỏng","damaged"],["Hết hạn","expired"]].forEach(([state,key])=>{
    const qty=Number(c[key]||0);
    if(qty>0)t7Ledger.post({key:`UIF-06:${req.id}:${line.id}:${state}`,productId:line.code,lot:line.actualLot||line.expectedLot||"",kind:"Nhận hàng khách trả",doc:req.id,delta:qty,state,sourceFlow:"UIF-06",opId:req.operationId});
  });
}
function bj06SeedReceived(reqId){
  const req=io06Requests.find(r=>r.id===reqId);if(!req||req.receiptCommitted)return;
  io06LinesForRequest(reqId).forEach((l)=>{l.qty=bj06LineMax(l);l.actualLot=l.tracking==='LOT'?l.expectedLot:null;l.actualLotMode=l.tracking==='LOT'?'EXPECTED':'';l.verified=true;if(l.actualLot)bj06ResolveLot(l);});
  bj06CommitReceipt(req);
}
function bj06SeedClassified(reqId){
  const req=io06Requests.find(r=>r.id===reqId);if(!req)return;
  bj06SeedReceived(reqId);
  io06LinesForRequest(reqId).forEach((l)=>{if(bj06IsExpired(l))return;if(l.id==="RET-L4"){l.classification={sellable:3,quarantine:1,damaged:0,expired:0};l.classMode="SPLIT";}else bj06ClassifyWhole(l,"SELLABLE");});
  req.classified=true;req.classifiedAt=bj06IsoNow();req.closed=true;req.status="Đã phân loại";req.queue="CLOSED";
}

/* ---------- Trạng thái trong luồng và trạng thái đặt từ bộ kiểm ----------
 * Đi bằng nút trong màn thì đặt trạng thái qua io06SetState (đánh dấu "đã biết"). Trạng thái khác với dấu đã biết nghĩa là
 * bộ kiểm / đường dẫn đặt từ ngoài: dựng lại fixture từ bản gốc rồi chuẩn bị đúng yêu cầu cho trạng thái đó, để ca này không
 * mang dữ liệu của ca trước. Lần dựng đầu của SCR-030 READY (vào luồng từ Hub) là tự nhiên: giữ nguyên dữ liệu. */
const io06ExpectedState={};
let io06Seeded=false;
function io06SetState(screenId,state){stateByScreen[screenId]=state;io06ExpectedState[screenId]=state;}
function io06Restore(){
  io06Requests.splice(0,io06Requests.length,...structuredClone(IO06_INITIAL.requests));
  io06ApprovalCases.splice(0,io06ApprovalCases.length,...structuredClone(IO06_INITIAL.cases));
  Object.keys(io06LinesByRequest).forEach((k)=>delete io06LinesByRequest[k]);
  Object.assign(io06LinesByRequest,structuredClone(IO06_INITIAL.lines));
  io06ApprovalSeq=2;io06Query="";io06QueueFilter="ALL";io06ApprovalQuery="";io06RejectOpen=false;io06RejectReason="";io06ClassificationOpen=false;io06ClassificationDraft=null;io06ResultSheetOpen=false;
  io06SelectedRequestId="RET-260827-03";io06ActiveLineId="RET-L1A";io06SelectedApprovalCaseId="EX-06-001";
}
function io06Select(reqId){io06SelectedRequestId=reqId;io06ActiveLineId=io06LinesForRequest(reqId)[0]?.id||"";io06ClassificationOpen=false;io06ClassificationDraft=null;}
function io06Seed(screenId,state){
  if(io06ExpectedState[screenId]===state)return;
  if(!io06Seeded&&screenId==="SCR-030"&&state==="READY"){io06ExpectedState[screenId]=state;return;}
  io06Seeded=true;
  Object.keys(io06ExpectedState).forEach((k)=>delete io06ExpectedState[k]);
  io06ExpectedState[screenId]=state;
  io06Restore();
  if(screenId==="SCR-030"){io06Query=state==="FILTER_EMPTY"?"zzz":"";return;}
  if(screenId==="SCR-031"){io06Select(state==="WAITING_APPROVAL"?"RET-260827-07":"RET-260827-03");return;}
  if(screenId==="SCR-032"){
    if(["PENDING_APPROVAL","APPROVED_EXCEPTION","REJECTED_EXCEPTION"].includes(state)){
      io06Select("RET-260827-07");const c=io06ApprovalCases[0];
      if(state==="APPROVED_EXCEPTION")c.status="APPROVED";
      if(state==="REJECTED_EXCEPTION"){c.status="REJECTED";c.decisionReason="Ảnh nhãn lô không rõ mã lô";}
      io06RefreshRequestState(io06Requests[2]);return;
    }
    io06Select("RET-260827-03");
    if(state==="VALIDATION_ERROR")io06LinesByRequest["RET-260827-03"][0].qty=5;
    return;
  }
  if(screenId==="SCR-033"){
    io06Select("RET-260827-05");const l4=io06FindLine("RET-L4");
    if(state==="VALIDATION_ERROR"){l4.classification={sellable:5,quarantine:0,damaged:0,expired:0};l4.classMode="SPLIT";io06ActiveLineId=l4.id;io06ClassificationOpen=true;}
    if(state==="EXPIRED_GUARD"){l4.expectedLot="DH2408";l4.actualLot="DH2408";bj06ResolveLot(l4);l4.classification={...bj06BlankClass(),expired:Number(l4.qty||0)};io06ActiveLineId=l4.id;io06ClassificationOpen=true;}
    return;
  }
  if(screenId==="SCR-034"){io06SelectedApprovalCaseId="EX-06-001";return;}
  if(screenId==="SCR-035"){
    if(state==="COMPLETED"){io06Select("RET-260827-05");bj06SeedClassified("RET-260827-05");return;}
    io06Select("RET-260827-03");if(state==="RECEIVED_PENDING_CLASSIFICATION")bj06SeedReceived("RET-260827-03");
  }
}

/* ---------- Dựng phần dùng chung ---------- */

function bj06Shell(opts){return appShell({...opts,extraClass:"k7-wide"});}
function bj06Denied(title,back=true){return bj06Shell({title,body:k1Denied({...IO06_DENIED,exitAttr:k1ExitAttr("SCR-030")}),centered:true,back});}
function bj06Loading(title,subtitle,blocks,back=true){return bj06Shell({title,subtitle,body:k1Loading({blocks}),back});}
function io06QtyDisplay(qty){return qty==null||qty===""||!Number.isFinite(Number(qty))?"—":Number(qty).toLocaleString("vi-VN");}
function bj06Progress(done,total,verb){
  if(!total)return "";
  return `<div class="bj02-progress-block bj06-progress" data-ds-component="VProgress"><div class="bj02-progress" role="progressbar" aria-label="Tiến độ ${verb}" aria-valuemin="0" aria-valuemax="${total}" aria-valuenow="${done}"><span style="width:${Math.round(done/total*100)}%"></span></div><small>Đã ${verb} ${done}/${total} dòng</small></div>`;
}
function bj06Head(step,done,total,verb){return `<div class="bj06-head"><p class="bj06-step" data-ds-component="VText">${esc(step)}</p>${bj06Progress(done,total,verb)}</div>`;}
function bj06Link(label,attrs=""){return `<button class="k7-row-link bj06-link" type="button" ${attrs}>${esc(label)}</button>`;}
// Khối chặn theo trạng thái: banner / k1Stale / k1Locked. refreshAttr: nút làm mới; staleLabel: nhãn nút.
function bj06Blocker(state,refreshAttr,staleLabel="Làm mới yêu cầu"){
  const stale=(title,description)=>k1Stale({title,description,actionLabel:staleLabel,actionAttr:refreshAttr});
  if(state==="RETURN_CAP_CHANGED")return stale("Lượng được nhận đã thay đổi","Làm mới và kiểm lại từng dòng trước khi tiếp tục.");
  if(state==="SOURCE_CHANGED")return stale("Yêu cầu đã thay đổi","Làm mới để dùng dữ liệu hiện hành.");
  if(state==="CONFLICT")return stale("Người khác vừa cập nhật yêu cầu này","Làm mới để dùng dữ liệu hiện hành.");
  if(state==="LOCKED")return k1Locked({title:"Yêu cầu đang được xử lý",description:"Đợi lần xử lý hiện tại xong rồi mở lại."});
  return "";
}
const BJ06_BLOCKED=["RETURN_CAP_CHANGED","SOURCE_CHANGED","CONFLICT","LOCKED"];

/* ---------- SCR-030 Hàng khách trả (K6) ---------- */

function bj06RequestBadge(r){
  if(r.unknownLocked)return {label:"Đang xác minh kết quả",tone:"Warning"};
  if(r.queue==="WAITING")return {label:"Chờ duyệt lô",tone:"Warning"};
  if(r.phase==="CLASSIFICATION")return {label:"Cần phân loại",tone:"Info"};
  if(r.status==="Cần xử lý ngoại lệ")return {label:r.status,tone:"Warning"};
  if(r.status==="Sẵn sàng ghi nhận")return {label:r.status,tone:"Success"};
  return {label:r.status,tone:"Neutral"};
}
// Mã đơn bán không gãy dòng giữa "SO-" và số (chữ phụ được xuống dòng).
function bj06RequestRow(m){const row=ds24ListRow({title:m.title,subtitle:m.subtitle,trailing:ds24Badge(m.status.label,m.status.tone),attrs:`data-io06-request="${bj06Attr(m.req.id)}" data-io06-target="${m.target}" data-io06-search-text="${bj06Attr(ioNormalizeSearch(`${m.req.id} ${m.req.source} ${m.req.customer}`))}"${m.disabled?' aria-disabled="true"':""}`,type:"Navigation",state:m.disabled?"Disabled":"Default",disabled:m.disabled});return row.replace(esc(m.req.source),`<span class="bj06-nowrap">${esc(m.req.source)}</span>`);}
function bj06RequestModel(r){
  const st=bj06RequestBadge(r);
  return {req:r,title:r.id,subtitle:`${r.customer} · ${r.source}`,status:st,statusHtml:ds24Badge(st.label,st.tone),idHtml:`<button class="k7-row-link" type="button" ${r.unknownLocked?"disabled":""}>${esc(r.id)}</button>`,customer:r.customer,source:r.source,items:String(io06LinesForRequest(r.id).length),disabled:r.unknownLocked,target:r.phase==="CLASSIFICATION"?"SCR-033":"SCR-031"};
}
function render030BJ06(state){
  const title="Hàng khách trả",subtitle="Yêu cầu trả đủ điều kiện để Kho xử lý";
  io06Seed("SCR-030",state);
  if(state==="PERMISSION_DENIED")return bj06Denied(title,false);
  if(state==="LOADING")return bj06Loading(title,subtitle,["search","row","row","row"],false);
  io06Requests.forEach(io06RefreshRequestState);
  const source=io06Requests.filter(r=>!r.closed).map(bj06RequestModel);
  const count=(key)=>key==="ALL"?source.length:source.filter(m=>m.req.queue===key).length;
  const items=[["ALL","Tất cả"],["ACTIONABLE","Cần xử lý"],["WAITING","Đang chờ"]].map(([k,l])=>[k,l,count(k)]);
  const rows=source.filter(m=>(io06QueueFilter==="ALL"||m.req.queue===io06QueueFilter)&&ioMatchesSearch(io06Query,`${m.req.id} ${m.req.source} ${m.req.customer}`));
  const columns=[{key:"idHtml",label:"Yêu cầu",html:true},{key:"customer",label:"Khách hàng"},{key:"source",label:"Đơn bán",mono:true},{key:"items",label:"Mặt hàng",align:"end",mono:true},{key:"statusHtml",label:"Tình trạng",html:true}];
  const body=k6TaskList({
    search:{value:io06Query,attr:"data-io06-search",placeholder:"Tìm yêu cầu, đơn bán hoặc khách hàng"},
    filters:{items,selected:io06QueueFilter,attrName:"data-io06-filter"},
    columns,rows:state==="EMPTY"?[]:rows,total:state==="EMPTY"?0:source.length,mobileRow:bj06RequestRow,
    rowAttr:(m)=>`data-io06-request="${bj06Attr(m.req.id)}" data-io06-target="${m.target}" data-io06-search-text="${bj06Attr(ioNormalizeSearch(`${m.req.id} ${m.req.source} ${m.req.customer}`))}"`,
    empty:{title:"Chưa có yêu cầu trả cần xử lý",description:"Yêu cầu trả hàng được Bán hàng chấp nhận sẽ hiện ở đây."},
    filterEmpty:{title:"Không tìm thấy yêu cầu phù hợp",description:"Thử từ khóa khác hoặc đổi bộ lọc.",actionLabel:"Xem tất cả",actionAttr:'data-io06-action="clear-filter"'},
    filterEmptyAttr:"data-io06-filter-empty"
  });
  return bj06Shell({title,subtitle,body,back:false,centered:state==="EMPTY"});
}

/* ---------- SCR-031 / SCR-032 Nhận hàng ---------- */

// Trạng thái nhãn của một dòng hàng (null = chưa kiểm).
function bj06LineStatus(line){
  const approval=io06LineApprovalState(line);
  if(approval==='PENDING')return {label:'Chờ duyệt lô',tone:'Warning'};
  if(approval==='REJECTED')return {label:'Bị từ chối',tone:'Danger'};
  if(approval==='APPROVED')return {label:'Đã duyệt',tone:'Success'};
  if(approval==='DRAFT')return {label:'Chờ gửi duyệt',tone:'Warning'};
  return line.verified?{label:'Đã kiểm',tone:'Success'}:null;
}
function bj06LineSub(line){return `${line.comboName?`Thuộc ${line.comboName} · `:""}${line.tracking==='LOT'?`Lô giao ${line.expectedLot}`:"Không theo lô"} · được nhận ${io06QtyDisplay(bj06LineMax(line))} ${line.uom}`;}
function io06ReturnLineRow(line,readOnly=false){
  const st=bj06LineStatus(line);
  const qty=line.verified?`<strong class="bj06-row-qty">${esc(io06QtyDisplay(line.qty))} ${esc(line.uom)}</strong>`:"";
  const trailing=qty||st?`<span class="bj06-row-trailing">${qty}${st?ds24Badge(st.label,st.tone):""}</span>`:"";
  return ds24ListRow({title:line.name,subtitle:bj06LineSub(line),trailing,leading:"package",attrs:readOnly?"":`data-io06-line="${bj06Attr(line.id)}" data-bj06-row`,type:readOnly?"Status":"Navigation",interactive:!readOnly,extraClass:"bj06-line-row"});
}
function bj06LineModel(line){
  const st=bj06LineStatus(line),lot=line.tracking==='LOT';
  return {line,productHtml:`<button class="k7-row-link bj06-line-link" type="button"><strong>${esc(line.name)}</strong><small>${esc(line.code)} · ${esc(line.uom)}${line.comboName?` · Thuộc ${esc(line.comboName)}`:""}</small></button>`,expectedLot:lot?line.expectedLot:"—",allowed:`${io06QtyDisplay(bj06LineMax(line))} ${line.uom}`,received:line.verified?`${io06QtyDisplay(line.qty)} ${line.uom}`:"—",actualLot:line.verified&&lot?bj06Upper(line.actualLot):"—",statusHtml:st?ds24Badge(st.label,st.tone):'<span class="k7-muted">Chưa kiểm</span>'};
}
function bj06NextLine(line){
  const lines=io06CurrentLines(),i=lines.indexOf(line);
  return [...lines.slice(i+1),...lines.slice(0,i)].find(l=>!l.verified)||null;
}

// Điều kiện lưu một dòng + lý do hiện trên chân khi nút tắt (chữ lý do: plan mục 11; ba chữ cuối ngoài danh sách plan).
function bj06LineBlock(line){
  const max=bj06LineMax(line),raw=line.qty,q=Number(raw),other=bj06IsOther(line);
  if(raw==null||raw===""||!Number.isFinite(q))return {blocked:true,reason:"Nhập số lượng thực nhận"};
  if(q<0||q>max)return {blocked:true,reason:""};
  if(line.tracking==='LOT'){
    if(!String(line.actualLot||'').trim())return {blocked:true,reason:"Chọn lô thực nhận"};
    if(other&&bj06Upper(line.actualLot)===bj06Upper(line.expectedLot))return {blocked:true,reason:""};
    if(!bj06LotDataReady(line))return {blocked:true,reason:"Nhập hạn dùng lô mới"};
    if(io06Mismatch(line)){
      if(!(line.evidenceId&&line.evidenceVersion&&line.evidenceHash&&line.evidenceData))return {blocked:true,reason:"Thêm ảnh nhãn lô"};
      if(line.reasonCode==='OTHER'&&!(line.reasonDetail||'').trim())return {blocked:true,reason:"Mô tả lý do ngoại lệ"};
      if(!io06LineEvidenceReady(line))return {blocked:true,reason:"Chọn lý do ngoại lệ"};
    }
  }
  return {blocked:false,reason:""};
}
function bj06LineActionKey(line){return bj06IsOther(line)&&io06LineApprovalState(line)!=="APPROVED"?{key:"save-return-exception",label:"Lưu ngoại lệ"}:{key:"save-return-line",label:"Xong"};}

function bj06EvidenceZone(line,readOnly){
  const has=Boolean(line.evidenceFile),dis=readOnly?" disabled":"",cls=readOnly?" is-disabled":"";
  const pick=`<label class="button button--secondary bj02-pick-file${cls}"><input data-io06-evidence-file type="file" accept="image/*"${dis}>Chọn tệp</label>`;
  const camera=`<label class="button button--secondary bj02-pick-file${cls}"><input data-io06-evidence-file type="file" accept="image/*" capture="environment"${dis}>Chụp ảnh</label>`;
  const copy=has?`<strong>${esc(line.evidenceFile)}</strong><small>Ảnh sẽ gửi kèm yêu cầu duyệt</small>`:`<strong>Ảnh rõ mã lô</strong><small class="k7-web-only">Kéo tệp vào đây hoặc Chọn tệp</small><small class="k7-mobile-only">Chụp ảnh nhãn lô hoặc chọn tệp có sẵn</small>`;
  const preview=line.evidenceData?`<div class="bj06-evidence-preview"><img src="${line.evidenceData}" alt="Ảnh nhãn lô thực nhận ${esc(bj06Upper(line.actualLot))}"><span>${esc(line.evidenceFile||'Ảnh nhãn lô')}</span></div>`:"";
  return `<div class="form-field bj02-evidence bj06-evidence" data-ds-component="VFileDropZone" data-figma-node="522:7507"><span class="c45-text-style-8">Ảnh nhãn lô thực nhận <span class="required">*</span></span><div class="bj02-evidence__zone">${icon("cloudUpload","icon--24")}<span class="bj02-evidence__copy">${copy}</span><div class="k7-mobile-only"><div class="bj02-evidence__actions">${camera}${pick}</div></div><div class="k7-web-only"><div class="bj02-evidence__actions">${pick}</div></div></div>${preview}</div>`;
}
function bj06LotDetailsHtml(line,readOnly){
  if(line.tracking!=='LOT'||!String(line.actualLot||'').trim())return '';
  const r=bj06ResolveLot(line);
  if(r.kind==='EXISTING')return ds24InfoGroup('Lô thực nhận đã có',`${ds24InfoRow('Mã lô',bj06Upper(line.actualLot))}${ds24InfoRow('Hạn dùng',bj06DateVN(r.expiryDate)||'Không có')}${r.manufactureDate?ds24InfoRow('Ngày sản xuất',bj06DateVN(r.manufactureDate)):''}`,'bj06-lot-resolved');
  const dis=readOnly?'disabled':'';
  return `<section class="bj06-section bj06-new-lot" data-ds-component="VSection">${ds24SectionTitle('Thông tin lô mới')}${ds24TextField(`Hạn dùng${line.expiryRequired?' *':''}`,line.newLotExpiry||'',`data-bj06-new-lot-expiry type="date" ${dis}`,line.expiryRequired?'Bắt buộc theo cấu hình sản phẩm.':'')}${ds24TextField('Ngày sản xuất',line.newLotManufacture||'',`data-bj06-new-lot-manufacture type="date" ${dis}`,'Không bắt buộc.')}</section>`;
}
// Phần dưới mã lô khi chọn "Lô khác": thông tin lô, lỗi trùng lô, banner, lý do, ảnh nhãn lô. Dựng lại tại chỗ khi gõ mã lô.
function bj06LotExtraHtml(line,readOnly){
  if(!bj06IsOther(line))return "";
  const same=Boolean(line.actualLot&&bj06Upper(line.actualLot)===bj06Upper(line.expectedLot));
  const reason=line.reasonCode||"RETURNED_DIFFERENT_LOT";
  const lotInvalid=Boolean(line.actualLot)&&!bj06LotDataReady(line);
  const reasons=`<section class="bj06-section">${ds24SectionTitle('Lý do ngoại lệ')}<div class="ds-choice-list" role="radiogroup" aria-label="Lý do ngoại lệ">${BJ06_REASONS.map(([k,l])=>dsChoiceRow({title:l,selected:reason===k,attrs:`data-io06-reason="${k}"`,disabled:readOnly})).join('')}</div></section>`;
  const detail=reason==='OTHER'?icTextarea('Mô tả thêm *',line.reasonDetail||'',`data-io06-reason-detail ${readOnly?'disabled':''}`,'Nêu ngắn gọn tình huống thực tế.'):'';
  return `${bj06LotDetailsHtml(line,readOnly)}${same?`<p class="field-error">Nếu lô thực nhận trùng lô đã giao, hãy chọn Lô ${esc(line.expectedLot)}.</p>`:''}${lotInvalid?`<p class="field-error">Cần hoàn thiện thông tin lô trước khi lưu.</p>`:''}${vBanner('warning','Lô thực nhận khác lô đã giao','Cần lý do, ảnh nhãn lô và phê duyệt trước khi ghi nhận.','','Compact')}${reasons}${detail}${bj06EvidenceZone(line,readOnly)}`;
}
function bj06InlineAction(line){
  const act=bj06LineActionKey(line),blk=bj06LineBlock(line);
  return `<div class="bj06-inline-actions k7-web-only"><p class="k4-reason-footer__reason" data-bj06-reason ${blk.blocked&&blk.reason?"":"hidden"}>${esc(blk.blocked?blk.reason:"")}</p><button class="button button--primary" type="button" data-io06-action="${act.key}" data-ds-component="VButton" ${blk.blocked?"disabled":""}>${act.label}</button></div>`;
}
// Chi tiết một dòng (thân SCR-032): iPhone là cả màn, web là cột phải của SCR-031. blocker: banner trạng thái (iPhone).
function bj06LineDetail(line,{blocker="",web=false,frozen=false}={}){
  const approval=io06LineApprovalState(line),pending=approval==='PENDING',approved=approval==='APPROVED',rejected=approval==='REJECTED';
  const readOnly=pending||frozen,c=io06LineCase(line);
  const max=bj06LineMax(line),raw=line.qty,qn=Number(raw),capInvalid=raw!=null&&raw!==""&&Number.isFinite(qn)&&qn>max,other=bj06IsOther(line);
  const status=pending?vBanner('warning','Ngoại lệ đang chờ duyệt','Dữ liệu đã gửi duyệt đang được khóa.','','Compact')
    :approved?vBanner('success','Ngoại lệ lô đã được duyệt','Sửa dòng này thì phải gửi duyệt lại.','','Compact')
    :rejected?vBanner('error','Ngoại lệ lô bị từ chối',`Cập nhật lô hoặc bằng chứng rồi gửi lại.${c?.decisionReason?` Lý do: ${esc(c.decisionReason)}`:''}`):'';
  const identity=ds24ListRow({title:line.name,subtitle:`${line.code} · ${line.uom}`,leading:'package',type:'Status',interactive:false,density:'Compact'});
  const facts=ds24InfoGroup('Căn cứ trả hàng',`${line.comboName?ds24InfoRow('Thuộc',line.comboName):''}${ds24InfoRow('Được phép nhận lần này',`${io06QtyDisplay(max)} ${line.uom}`)}${ds24InfoRow('Tình trạng khai báo',line.declaredCondition||'—')}${line.expectedLot?ds24InfoRow('Lô đã giao',line.expectedLot):''}`,'bj06-source-facts');
  const qty=`<div class="bj06-qty">${ds24TextField('Số lượng thực nhận *',raw==null?'':raw,`data-io06-qty type="number" min="0" max="${max}" step="${line.quantityStep||1}" inputmode="decimal" ${capInvalid?'aria-invalid="true"':''} ${readOnly?'disabled':''}`)}${readOnly?'':`<button class="button button--secondary bj06-fill-button" type="button" data-io06-fill-max data-ds-component="VButton">Nhận đủ ${esc(io06QtyDisplay(max))} ${esc(line.uom)}</button>`}<p class="field-error" data-io06-cap-error role="alert" ${capInvalid?'':'hidden'}>Không thể nhận vượt ${io06QtyDisplay(max)} ${esc(line.uom)} được phép trong yêu cầu hiện tại.</p></div>`;
  let lot='';
  if(line.tracking==='LOT'){
    const expectedSel=!other&&bj06Upper(line.actualLot)===bj06Upper(line.expectedLot);
    lot=`<section class="bj06-section">${ds24SectionTitle('Lô thực nhận')}<div class="ds-choice-list" role="radiogroup" aria-label="Lô thực nhận">${dsChoiceRow({title:`Lô ${line.expectedLot}`,subtitle:'Đúng lô đã giao',selected:expectedSel,attrs:`data-io06-select-actual-lot="${bj06Attr(line.expectedLot)}"`,disabled:readOnly})}${dsChoiceRow({title:'Lô khác',subtitle:'Thực nhận khác lô đã giao',selected:other,attrs:'data-io06-select-other-lot',disabled:readOnly})}</div></section>${other?ds24TextField('Mã lô thực nhận *',line.actualLot||'',`data-io06-actual-lot placeholder="Nhập hoặc quét mã lô" autocomplete="off" ${readOnly?'disabled':''}`):''}<div data-bj06-lot-extra>${bj06LotExtraHtml(line,readOnly)}</div>`;
  }
  return `<div class="bj06-detail">${blocker}${identity}${facts}${status}${qty}${lot}${web&&!readOnly?bj06InlineAction(line):''}</div>`;
}
function bj06LineFooter(line){
  const act=bj06LineActionKey(line),blk=bj06LineBlock(line);
  return k4ReasonFooter({label:act.label,attr:`data-io06-action="${act.key}"`,disabled:blk.blocked,reason:blk.reason});
}

// SCR-031 (và SCR-032 ở khung web): "Bước 1/2 · Nhận hàng".
function bj06ReceiptScreen(state,title="Kiểm hàng khách trả"){
  const req=io06CurrentRequest();io06RefreshRequestState(req);
  const lines=io06LinesForRequest(req.id),subtitle=`${req.id} · ${req.customer}`;
  const waiting=req.queue==="WAITING"&&!req.unknownLocked;
  const blocked=BJ06_BLOCKED.includes(state),frozen=blocked||waiting;
  const done=lines.filter(io06LinePhysicalValid).length;
  const head=bj06Head("Bước 1/2 · Nhận hàng",done,lines.length,"kiểm");
  const refreshAttr='data-io06-action="refresh-return-request"';
  const blocker=bj06Blocker(state,refreshAttr);
  const sentAt=(io06PendingCasesForRequest(req.id)[0]||{}).createdAt||bj06DisplayTime(bj06IsoNow());
  const pendingBox=waiting?k2Pending({approver:"chủ cửa hàng",sentAt}):"";
  const web=viewport==="web";
  const active=io06ActiveLine();
  const note=`<p class="bj06-note">Chỉ ghi nhận khi tất cả dòng hợp lệ; tồn kho chưa đổi trong lúc kiểm.</p>`;
  let body;
  if(web){
    const columns=[{key:"productHtml",label:"Sản phẩm",html:true},{key:"expectedLot",label:"Lô giao",mono:true},{key:"allowed",label:"Được nhận",align:"end",mono:true},{key:"received",label:"Thực nhận",align:"end",mono:true},{key:"actualLot",label:"Lô thực nhận",mono:true},{key:"statusHtml",label:"Tình trạng",html:true}];
    const table=k7Table({columns,rows:lines.map(bj06LineModel),caption:"Hàng thực nhận",mobileRow:(m)=>io06ReturnLineRow(m.line,frozen),rowAttr:(m)=>`data-io06-line="${bj06Attr(m.line.id)}" aria-selected="${m.line.id===active.id}"${m.line.id===active.id?' class="is-selected"':""}`});
    const main=`${head}${blocker}${pendingBox}${table}${note}`;
    body=`<div class="bj06-receipt">${k7Split({main,aside:active?bj06LineDetail(active,{web:true,frozen}):"",asideWebOnly:false})}</div>`;
  }else{
    body=`<div class="bj06-receipt">${head}${blocker}${pendingBox}<section class="bj06-section" data-ds-component="VSection">${ds24SectionTitle("Hàng thực nhận")}<div class="ds24-list-stack bj06-lines">${lines.map(l=>io06ReturnLineRow(l,frozen)).join("")}</div></section>${note}</div>`;
  }
  let actions="";
  if(!frozen){
    if(io06RequestCanSubmitExceptions(req))actions=k4ReasonFooter({label:"Gửi ngoại lệ duyệt",attr:'data-io06-action="submit-return-exceptions"'});
    else{
      const rejected=lines.some(l=>io06LineApprovalState(l)==="REJECTED"),open=lines.length-done;
      const reason=rejected?"Sửa dòng bị từ chối rồi gửi lại":open>0?`Còn ${open} dòng chưa kiểm`:!io06RequestAllVerified(req)?"Cần nhận ít nhất một dòng":"";
      actions=k4ReasonFooter({label:"Ghi nhận hàng trả",attr:'data-io06-action="commit-receipt"',disabled:!io06ReceiptReady(req),reason});
    }
  }
  return bj06Shell({title,subtitle,body,actions});
}
function render031BJ06(state){
  const title="Kiểm hàng khách trả";
  io06Seed("SCR-031",state);
  if(state==="PERMISSION_DENIED")return bj06Denied(title);
  if(state==="LOADING")return bj06Loading(title,`${io06CurrentRequest().id} · ${io06CurrentRequest().customer}`,["heading","row","row","row"]);
  return bj06ReceiptScreen(state,title);
}
function render032BJ06(state){
  const title="Chi tiết hàng trả";
  io06Seed("SCR-032",state);
  if(state==="PERMISSION_DENIED")return bj06Denied(title);
  if(state==="LOADING")return bj06Loading(title,undefined,["card","row","row","card"]);
  if(viewport==="web")return bj06ReceiptScreen(state,"Kiểm hàng khách trả");
  const line=io06ActiveLine();
  if(!line)return bj06Shell({title,body:ioEmpty("Không có dòng hàng","Quay lại yêu cầu để chọn dòng hàng."),centered:true});
  const frozen=BJ06_BLOCKED.includes(state);
  const blocker=bj06Blocker(state,'data-io06-action="refresh-return-request"');
  const pending=io06LineApprovalState(line)==="PENDING";
  return bj06Shell({title,body:bj06LineDetail(line,{blocker,frozen}),actions:pending||frozen?"":bj06LineFooter(line)});
}

/* ---------- SCR-034 Ngoại lệ lô cần duyệt (K2) ---------- */

function bj06ApprovalModel(c){
  const l=io06FindLine(c.lineId),r=io06Requests.find(x=>x.id===c.requestId),snap=c.snapshot||{};
  return {c,title:`${l?.name||"Mặt hàng"}`,subtitle:`${c.requestId} · ${r?.customer||""}`,status:{label:"Chờ quyết định",tone:"Warning"},statusHtml:ds24Badge("Chờ quyết định","Warning"),idHtml:`<button class="k7-row-link" type="button"><strong>${esc(l?.name||"Mặt hàng")}</strong></button>`,request:c.requestId,customer:r?.customer||"",lot:bj06Upper(snap.actualLot)};
}
function bj06TaskList034(){
  const source=io06ApprovalCases.filter(c=>c.status==="PENDING").map(bj06ApprovalModel);
  const rows=source.filter(m=>ioMatchesSearch(io06ApprovalQuery,`${m.title} ${m.request} ${m.customer}`));
  const columns=[{key:"idHtml",label:"Sản phẩm",html:true},{key:"request",label:"Yêu cầu trả",mono:true},{key:"customer",label:"Khách hàng"},{key:"lot",label:"Lô thực nhận",mono:true},{key:"statusHtml",label:"Tình trạng",html:true}];
  return k6TaskList({
    search:{value:io06ApprovalQuery,attr:"data-io06a-search",placeholder:"Tìm sản phẩm, yêu cầu hoặc khách hàng"},
    filters:{items:[["ALL","Tất cả",source.length]],selected:"ALL",attrName:"data-io06a-filter"},
    columns,rows,total:source.length,
    rowAttr:(m)=>`data-io06-approval-case="${bj06Attr(m.c.id)}" data-io06a-search-text="${bj06Attr(ioNormalizeSearch(`${m.title} ${m.request} ${m.customer}`))}"`,
    empty:{title:"Không còn ngoại lệ chờ duyệt",description:"Các quyết định đã hoàn tất hoặc chưa có yêu cầu mới."},
    filterEmpty:{title:"Không tìm thấy ngoại lệ phù hợp",description:"Thử từ khóa khác.",actionLabel:"Xem tất cả",actionAttr:'data-io06-action="clear-approval-filter"'},
    filterEmptyAttr:"data-io06a-filter-empty"
  });
}
function bj06EvidenceCard(c,line){
  const snap=c.snapshot||{};
  if(!(snap.evidence?.id&&line?.evidenceData))return `<div class="bj06-evidence-card bj06-evidence-card--empty">${icon('fileText','icon--sm')}<span>Chưa có ảnh nhãn lô</span></div>`;
  return `<div class="bj06-evidence-card"><img src="${line.evidenceData}" alt="Ảnh nhãn lô thực nhận ${esc(bj06Upper(snap.actualLot))}"><span>${esc(line.evidenceFile||'Ảnh nhãn lô')}</span></div>`;
}
function bj06ReasonLabel(snap){const label=(BJ06_REASONS.find(([k])=>k===snap.reasonCode)||[])[1];return label||snap.reasonCode||'—';}
function render034BJ06(state){
  io06Seed("SCR-034",state);
  const listTitle="Ngoại lệ lô cần duyệt",listSub="Việc dành cho người phê duyệt",decTitle="Duyệt ngoại lệ lô";
  if(state==="PERMISSION_DENIED")return bj06Shell({title:decTitle,body:k1Denied({what:"duyệt ngoại lệ lô",next:"Chỉ chủ cửa hàng duyệt ngoại lệ lô hàng trả.",exitAttr:k1ExitAttr("SCR-030")}),centered:true,back:false});
  if(state==="LOADING")return bj06Loading(decTitle,undefined,["heading","card","card"],false);
  if(state==="TASK_LIST")return bj06Shell({title:listTitle,subtitle:listSub,body:bj06TaskList034(),back:false});
  const c=io06SelectedApprovalCase()||io06ApprovalCases[0],line=io06ApprovalCaseLine(c),req=io06Requests.find(r=>r.id===c?.requestId);
  if(!c||!line)return bj06Shell({title:decTitle,body:ioEmpty("Không tìm thấy ngoại lệ","Quay lại danh sách phê duyệt."),centered:true,backAction:"exit-io06-approval"});
  const snap=c.snapshot||{};
  const view=state==="APPROVED"||state==="REJECTED"?state:(c.status==="APPROVED"||c.status==="REJECTED"?c.status:"READY");
  const exitAttr='data-io06-action="exit-approval-detail" data-theme-exit-to-pending';
  if(view!=="READY"){
    const approved=view==="APPROVED",reason=c.decisionReason||(c.status==="REJECTED"?"":"Ảnh nhãn lô không rõ mã lô");
    return k4Result({screenTitle:decTitle,kind:approved?"success":"warning",title:approved?"Đã duyệt ngoại lệ":"Đã từ chối ngoại lệ",description:approved?"Thủ kho ghi nhận hàng trả khi tất cả dòng hợp lệ.":`Lý do: ${reason||"—"}`,facts:[["Yêu cầu trả",req?.id||c.requestId],["Người duyệt","Chủ cửa hàng"]],next:[{label:"Về danh sách phê duyệt",attr:exitAttr,primary:true}]});
  }
  const selfBlocked=state==="SELF_APPROVAL_NOT_ALLOWED"?vBanner("warning","Không thể tự duyệt","Chỉ chủ cửa hàng duyệt ngoại lệ lô hàng trả. Người gửi không được tự quyết định."):"";
  const facts=[["Sản phẩm",`${snap.product||line.name} · ${snap.productCode||line.code}`],["Yêu cầu trả",req?.id||c.requestId],["Đơn bán",req?.source||snap.source||"—"],["Khách hàng",req?.customer||"—"],["Số lượng",`${io06QtyDisplay(snap.quantity??snap.qty)} ${snap.uom||line.uom}`],["Hạn dùng lô thực nhận",bj06DateVN(snap.expiryDate)],["Lý do",bj06ReasonLabel(snap)]];
  if(snap.reasonCode==="OTHER"&&snap.reasonDetail)facts.push(["Mô tả",snap.reasonDetail]);
  const decision=k2Decision({question:`Duyệt nhận lô ${bj06Upper(snap.actualLot)} thay cho lô ${bj06Upper(snap.sourceLot)}?`,maker:c.maker||BJ06_MAKER.name,sentAt:c.createdAt,attention:[["Lô thực nhận khác lô đã giao",`${bj06Upper(snap.actualLot)} · giao ${bj06Upper(snap.sourceLot)}`]],facts});
  const evidence=`<section class="bj06-section">${ds24SectionTitle("Ảnh nhãn lô thực nhận")}${bj06EvidenceCard(c,line)}</section>`;
  const sheet=k2RejectSheet({open:io06RejectOpen,title:"Từ chối ngoại lệ",reason:io06RejectReason,reasonAttr:"data-io06-reject-reason",confirmAttr:'data-io06-action="confirm-reject"',closeAttr:'data-io06-action="close-reject"'});
  const body=`${selfBlocked}${k7Split({main:decision,aside:evidence})}${sheet}`;
  return bj06Shell({title:decTitle,body,backAction:"exit-io06-approval",actions:ac310ApprovalFooter('data-io06-action="open-reject"','data-io06-action="approve-exception"',"Duyệt ngoại lệ")});
}

/* ---------- SCR-033 Phân loại ---------- */

function bj06ClassBadge(line){
  const mode=io06ClassModeOf(line);
  if(mode==="EXPIRED")return ds24Badge("Hết hạn","Warning");
  if(Number(line.qty||0)<=0)return ds24Badge("Không nhận","Neutral");
  if(!io06ClassValid(line)){return ds24Badge(io06ClassTotal(line)>0?"Chưa đủ":"Chưa phân loại",io06ClassTotal(line)>0?"Warning":"Neutral");}
  const found=BJ06_CLASSES.find(x=>x[0]===mode);
  return ds24Badge(io06ClassModeLabel(mode),found?found[3]:"Info");
}
function bj06ClassLot(line){return line.actualLot?`Lô ${line.actualLot}`:"Không theo lô";}
function io06ClassRow(line,readOnly){
  const expired=bj06IsExpired(line),qty=Number(line.qty||0);
  const trailing=`<span class="bj06-row-trailing"><strong class="bj06-row-qty">${esc(io06QtyDisplay(line.qty))} ${esc(line.uom)}</strong>${bj06ClassBadge(line)}</span>`;
  const sub=expired?`${bj06ClassLot(line)} · Hết hạn · hệ thống xác định`:bj06ClassLot(line);
  const auto=qty<=0;
  return ds24ListRow({title:line.name,subtitle:sub,trailing,leading:"package",attrs:readOnly||auto?"":`data-io06-class-line="${bj06Attr(line.id)}" data-bj06-row`,type:readOnly||auto?"Status":"Navigation",interactive:!(readOnly||auto),extraClass:"bj06-line-row"});
}
function bj06ClassModel(line){
  const mode=io06ClassModeOf(line),expired=mode==="EXPIRED",c=io06EffClass(line),qty=Number(line.qty||0);
  const split=mode==="SPLIT";
  const seg=expired||qty<=0?(expired?'<span class="bj06-expired-note">Hết hạn · hệ thống xác định</span>':'<span class="k7-muted">Không nhận</span>'):`${dsSegmented({items:[...BJ06_CLASSES.map(x=>[x[0],x[2]]),["SPLIT","Chia"]],value:mode,attr:`data-io06-class-line="${bj06Attr(line.id)}" data-io06-class-mode`,label:`Phân loại ${line.name} ${bj06ClassLot(line)}`})}<small class="bj06-class-hint" data-io06-class-hint="${bj06Attr(line.id)}">${bj06ClassHint(line)}</small>`;
  const cell=(key,label)=>split&&!expired?k7EditCell({value:c[key]??0,attr:`data-io06-class="${key}" data-io06-cell-line="${bj06Attr(line.id)}" max="${qty}"`,label:`${label} ${line.name} ${bj06ClassLot(line)}`}):`${io06QtyDisplay(c[key]||0)}`;
  return {line,productHtml:`<strong>${esc(line.name)}</strong><small>${esc(line.code)}</small>`,lot:esc(line.actualLot?bj06Upper(line.actualLot):"Không theo lô"),qty:`${io06QtyDisplay(line.qty)} ${esc(line.uom)}`,segHtml:seg,sellable:cell("sellable","Bán được"),quarantine:cell("quarantine","Cách ly"),damaged:cell("damaged","Hỏng")};
}
function bj06ClassHint(line){
  if(io06ClassModeOf(line)!=="SPLIT")return "";
  const left=Number(line.qty||0)-io06ClassTotal(line,line.classification);
  return left>0?`Còn ${left} ${esc(line.uom)} chưa phân loại`:left<0?`Vượt lượng cần phân loại ${-left} ${esc(line.uom)}`:"";
}
function bj06ClassSheet(line){
  if(!io06ClassificationOpen||!line)return "";
  const closeAttr='data-io06-sheet-backdrop';
  const declared=line.declaredCondition?`<p class="bj06-sheet-intro">Tình trạng khai báo: <strong>${esc(line.declaredCondition)}</strong>. Đây chỉ là thông tin đối chiếu.</p>`:"";
  if(bj06IsExpired(line)){
    const body=`${vBanner('warning','Lô đã hết hạn',`Toàn bộ ${io06QtyDisplay(line.qty)} ${esc(line.uom)} được hệ thống xác định là Hết hạn. Không thể phân bổ sang trạng thái khác.`)}${declared}${ds24InfoGroup('',ds24InfoRow('Hết hạn',`${io06QtyDisplay(line.qty)} ${line.uom}`),'bj06-expired-fact')}`;
    return `<div class="sheet-backdrop bj06-sheet-backdrop" ${closeAttr}><section class="bottom-sheet bj06-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="${bj06Attr(line.name)}"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(line.name)}</h3></div><div class="sheet-content bj06-sheet-content">${body}</div><div class="bj06-sheet-actions"><button class="button button--secondary" data-io06-action="cancel-classification-item" type="button">Đóng</button></div></section></div>`;
  }
  const draft=io06ClassificationDraftFor(line),qty=Number(line.qty||0),split=draft.mode==="SPLIT";
  const choices=[...BJ06_CLASSES.map(([k,,l])=>dsChoiceRow({title:l,subtitle:`Cả ${io06QtyDisplay(qty)} ${line.uom}`,selected:draft.mode===k,attrs:`data-io06-class-mode="${k}"`})),dsChoiceRow({title:"Chia nhiều loại",selected:split,attrs:'data-io06-class-mode="SPLIT"'})].join("");
  let splitHtml="";
  if(split){
    const total=Number(draft.sellable||0)+Number(draft.quarantine||0)+Number(draft.damaged||0);
    const fields=BJ06_CLASSES.map(([,k,l])=>ds24TextField(l,draft[k],`data-io06-class="${k}" type="number" min="0" step="${line.quantityStep||1}" inputmode="decimal"`)).join("");
    splitHtml=`${ds24KeyValueRow("Đã phân loại",`${total}/${io06QtyDisplay(qty)} ${line.uom}`,false,"data-io06-class-progress")}<div class="bj06-class-fields">${fields}</div><div data-io06-class-feedback>${bj06DraftFeedback(line,draft)}</div>`;
  }
  const actions=split?`<div class="bj06-sheet-actions"><button class="button button--secondary" data-io06-action="cancel-classification-item" type="button">Hủy</button><button class="button button--primary" data-io06-action="close-classification-item" type="button" ${io06DraftValid(line,draft)?"":"disabled"}>Xong</button></div>`:`<div class="bj06-sheet-actions"><button class="button button--secondary" data-io06-action="cancel-classification-item" type="button">Đóng</button></div>`;
  return `<div class="sheet-backdrop bj06-sheet-backdrop" ${closeAttr}><section class="bottom-sheet bj06-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="${bj06Attr(line.name)}"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(line.name)}</h3></div><div class="sheet-content bj06-sheet-content"><p class="bj06-sheet-intro">${esc(bj06ClassLot(line))} · ${io06QtyDisplay(qty)} ${esc(line.uom)}</p>${declared}<div class="ds-choice-list" role="radiogroup" aria-label="Phân loại">${choices}</div>${splitHtml}</div>${actions}</section></div>`;
}
function bj06DraftFeedback(line,draft){
  const total=Number(draft.sellable||0)+Number(draft.quarantine||0)+Number(draft.damaged||0),qty=Number(line.qty||0);
  if(total>qty)return vBanner('error','Vượt lượng cần phân loại',`Đang phân loại ${total}/${io06QtyDisplay(qty)} ${esc(line.uom)}.`,'','Compact');
  if(total<qty)return vBanner('warning',`Còn ${qty-total} ${esc(line.uom)} chưa phân loại`,'','','Compact');
  return "";
}
function render033BJ06(state){
  const title="Phân loại hàng trả";
  io06Seed("SCR-033",state);
  if(state==="PERMISSION_DENIED")return bj06Denied(title);
  const req=io06CurrentRequest(),lines=io06CurrentLines(),subtitle=`${req.id} · ${req.customer}`;
  if(state==="LOADING")return bj06Loading(title,subtitle,["heading","row","row","row"]);
  const blocked=["SOURCE_CHANGED","CONFLICT","LOCKED"].includes(state);
  const exitAttr='data-io06-action="result-to-return-queue"';
  const blocker=state==="SOURCE_CHANGED"?k1Stale({title:"Dữ liệu hàng trả đã thay đổi",description:"Về danh sách để mở lại dữ liệu hiện hành.",actionLabel:"Về Hàng khách trả",actionAttr:exitAttr})
    :state==="CONFLICT"?k1Stale({title:"Người khác vừa cập nhật yêu cầu này",description:"Về danh sách để mở lại dữ liệu hiện hành.",actionLabel:"Về Hàng khách trả",actionAttr:exitAttr})
    :state==="LOCKED"?k1Locked({title:"Yêu cầu đang được xử lý",description:"Đợi lần xử lý hiện tại xong rồi mở lại."}):"";
  const done=lines.filter(l=>io06ClassValid(l)).length;
  const head=bj06Head("Bước 2/2 · Phân loại",done,lines.length,"phân loại");
  const columns=[{key:"productHtml",label:"Sản phẩm",html:true},{key:"lot",label:"Lô",html:true,mono:true},{key:"qty",label:"Số lượng",html:true,align:"end",mono:true},{key:"segHtml",label:"Phân loại",html:true},{key:"sellable",label:"Bán được",html:true,align:"end"},{key:"quarantine",label:"Cách ly",html:true,align:"end"},{key:"damaged",label:"Hỏng",html:true,align:"end"}];
  const table=k7Table({columns,rows:lines.map(bj06ClassModel),caption:"Hàng cần phân loại",mobileRow:(m)=>io06ClassRow(m.line,blocked)});
  const sheet=blocked||viewport==="web"?"":bj06ClassSheet(io06ActiveLine());
  const body=`<div class="bj06-classify">${head}${blocker}<section class="bj06-section">${ds24SectionTitle("Hàng cần phân loại")}${table}</section></div>${sheet}`;
  const open=lines.length-done;
  const actions=blocked?"":k4ReasonFooter({label:"Hoàn tất phân loại",attr:'data-io06-action="confirm-classification"',disabled:!io06AllClassValid(),reason:open>0?`Còn ${open} dòng chưa phân loại`:""});
  return bj06Shell({title,subtitle,body,actions});
}

/* ---------- SCR-035 Kết quả hàng trả (K4 / K3) ---------- */

function bj06ResultGroupsHtml(lines,classified=false){
  const groups=new Map();
  for(const line of lines.filter(l=>Number(l.qty)>0)){const key=`${line.name}|${line.code}|${line.uom}`;if(!groups.has(key))groups.set(key,{name:line.name,code:line.code,uom:line.uom,lines:[]});groups.get(key).lines.push(line);}
  const subgroups=[...groups.values()].map(g=>{
    const head=ds24ContextStatusRow({title:g.name,subtitle:`${g.code} · ${g.uom}`,label:classified?'Đã phân loại':'Đã nhận',tone:classified?'Success':'Info',leading:'package'});
    const rows=g.lines.map(line=>{const lot=bj06ClassLot(line);if(!classified)return ds24InfoRow(lot,`${io06QtyDisplay(line.qty)} ${line.uom}`);const c=io06EffClass(line);return [["Bán được",c.sellable],["Cách ly",c.quarantine],["Hỏng",c.damaged],["Hết hạn",c.expired]].filter(([,q])=>Number(q)>0).map(([label,q])=>ds24InfoRow(`${lot} · ${label}`,`${q} ${line.uom}`)).join("");}).join("");
    return `<div class="bj06-result-group" data-composed-from="DS v2 / List Row,DS v2 / Info Row">${head}<div class="bj06-result-rows">${rows}</div></div>`;
  }).join("");
  return ds24GroupedCollection(subgroups,"bj06-result-groups","DS v2 / List Row,DS v2 / Info Row");
}
function bj06ResultSheet(lines,classified){
  if(!io06ResultSheetOpen)return "";
  return ds24Sheet({title:classified?"Kết quả theo sản phẩm và lô":"Hàng đã nhận",body:`${bj06ResultGroupsHtml(lines,classified)}<button class="button button--primary button--full" type="button" data-io06-sheet-close data-ds-component="VButton">Đóng</button>`,attrs:"data-io06-sheet-close-backdrop"});
}
function render035BJ06(state){
  const title="Kết quả hàng trả";
  io06Seed("SCR-035",state);
  if(state==="PERMISSION_DENIED")return bj06Denied(title,false);
  if(state==="LOADING")return bj06Loading(title,undefined,["heading","card","row"],false);
  const req=io06CurrentRequest(),lines=io06CurrentLines(),toQueue='data-io06-action="result-to-return-queue"';
  if(state==="UNKNOWN"){
    const scope=`${req.id} · ${req.source}`;
    return k3Unknown({operation:"Nhận hàng khách trả",scope,ref:req.operationId,sentAt:bj06DisplayTime(bj06IsoNow()),sourceFlow:"UIF-06",exitAttr:k1ExitAttr("SCR-030"),handoff:{operation:req.operationId,scope}});
  }
  if(state==="REJECTED_EXECUTION")return k4Result({screenTitle:title,kind:"warning",title:"Chưa thể ghi nhận",description:"Dữ liệu hiện hành đã thay đổi; tồn kho chưa bị tác động.",facts:[["Yêu cầu trả",req.id],["Đơn bán",req.source],["Tồn kho","Không thay đổi"]],next:[{label:req.receiptCommitted?"Xem phần phân loại đã cập nhật":"Xem yêu cầu đã cập nhật",attr:req.receiptCommitted?'data-io06-action="open-classification"':'data-io06-action="back-to-return-request"',primary:true}]});
  const completed=state==="COMPLETED"||req.classified;
  const received=lines.filter(l=>Number(l.qty)>0);
  const link=received.length?bj06Link(`Xem ${received.length} dòng hàng`,'data-io06-result-detail'):"";
  if(completed){
    const rows=[["Yêu cầu trả",req.id],["Đơn bán",req.source],["Phân loại lúc",bj06DisplayTime(req.classifiedAt)]];
    let hasHold=false;
    received.forEach(line=>{const c=io06EffClass(line);[["Bán được",c.sellable],["Cách ly",c.quarantine],["Hỏng",c.damaged],["Hết hạn",c.expired]].forEach(([label,q])=>{if(Number(q)>0){rows.push([`${line.name} · ${bj06ClassLot(line)} · ${label}`,`${q} ${line.uom}`]);if(label==="Cách ly"||label==="Hỏng")hasHold=true;}});});
    const note=hasHold?vBanner("info","Hàng cách ly / hỏng chờ xử lý ở Hàng cần xử lý.","","k7-banner--line","Compact"):"";
    return k4Result({screenTitle:title,title:"Đã phân loại hàng trả",description:"Chỉ phần đủ điều kiện mới trở lại khả dụng.",facts:rows,button:`${link}${note}${bj06ResultSheet(lines,true)}`,next:[{label:"Xem tồn kho",attr:'data-io06-action="see-inventory"'},{label:"Về Hàng khách trả",attr:toQueue,primary:true}]});
  }
  return k4Result({screenTitle:title,title:"Đã nhận hàng khách trả",description:"Hàng đang chờ phân loại; chưa tự trở lại bán được.",facts:[["Yêu cầu trả",req.id],["Đơn bán",req.source],["Ghi nhận lúc",bj06DisplayTime(req.recordedAt)],["Người nhận",req.receivedBy||BJ06_ACTOR_NAME]],button:`${link}${bj06ResultSheet(lines,false)}`,next:[{label:"Để sau",attr:toQueue},{label:"Phân loại ngay",attr:'data-io06-action="open-classification"',primary:true}]});
}

Object.assign(renderers, {
  "SCR-030": render030BJ06,
  "SCR-031": render031BJ06,
  "SCR-032": render032BJ06,
  "SCR-033": render033BJ06,
  "SCR-034": render034BJ06,
  "SCR-035": render035BJ06,
});

// Đi giữa các màn bằng navigate (kể cả nút quay lại) là đi trong luồng: trạng thái hiện tại là "đã biết", không dựng lại fixture.
["SCR-030","SCR-031","SCR-032","SCR-033","SCR-034","SCR-035"].forEach((id)=>{onScreenEnter[`UIF-06:${id}`]=()=>{io06ExpectedState[id]=stateByScreen[id];};});
onEntry["UIF-06:approver"]=()=>io06SetState("SCR-034","TASK_LIST");
onEntry["UIF-06:return-task"]=()=>{io06Select("RET-260827-03");io06SetState("SCR-031","READY");};
// Lối vào của người duyệt ở chế độ BJ (?entry=approver) mở danh sách ca chờ; core đã áp lối vào trước khi file này nạp.
if(activeFlowId==="UIF-06"&&entryMode==="approver"&&!requestedScreen)stateByScreen["SCR-034"]="TASK_LIST";

onUnknownHandoff["UIF-06"] = () => {
  const r = io06CurrentRequest();
  if (r) { r.unknownLocked = true; io06RefreshRequestState(r); }
};
onUnknownResolved["UIF-06"] = ({ operationId, outcome }) => {
  const r = io06Requests.find((x) => x.operationId === operationId) || io06Requests.find((x) => x.unknownLocked) || io06CurrentRequest();
  if (!r) return;
  r.unknownLocked = false;
  if (outcome === "RECORDED") r.receiptCommitted = true;
  io06RefreshRequestState(r);
};

/* ---------- Sự kiện ---------- */

// Dựng lại giữ vị trí cuộn, trả focus về ô / nút vừa dùng (cả hai khung cùng có trong DOM nên chọn phần tử đang hiện).
function bj06Rerender(focusSelector=""){
  const top=document.querySelector("#app-screen .app-content")?.scrollTop||0;
  renderAppScreen();
  const content=document.querySelector("#app-screen .app-content");if(content)content.scrollTop=top;
  if(focusSelector)[...document.querySelectorAll(focusSelector)].find(el=>el.offsetParent!==null)?.focus({preventScroll:true});
}
// Cập nhật tại chỗ (không dựng lại, giữ focus khi gõ): lỗi vượt lượng, nút lưu, lý do tắt, phần dưới mã lô.
function bj06RefreshDetail({lotExtra=false}={}){
  const line=io06ActiveLine();if(!line)return;
  const max=bj06LineMax(line),raw=line.qty,q=Number(raw),blk=bj06LineBlock(line);
  const err=document.querySelector("[data-io06-cap-error]");if(err){err.hidden=!(raw!=null&&raw!==""&&Number.isFinite(q)&&q>max);err.textContent=`Không thể nhận vượt ${io06QtyDisplay(max)} ${line.uom} được phép trong yêu cầu hiện tại.`;}
  document.querySelector("[data-io06-qty]")?.toggleAttribute("aria-invalid",Boolean(raw!=null&&raw!==""&&q>max));
  if(lotExtra){const holder=document.querySelector("[data-bj06-lot-extra]");if(holder)holder.innerHTML=bj06LotExtraHtml(line,false);}
  document.querySelectorAll('[data-io06-action="save-return-line"],[data-io06-action="save-return-exception"]').forEach(b=>{b.disabled=blk.blocked;});
  const reasonText=blk.blocked?blk.reason:"";
  document.querySelectorAll("[data-bj06-reason]").forEach(p=>{p.textContent=reasonText;p.hidden=!reasonText;});
  if(activeScreenId==="SCR-032"&&viewport!=="web")document.querySelectorAll(".app-actions [data-k4-reason]").forEach(p=>{p.textContent=reasonText;p.hidden=!reasonText;});
}
// Phân loại ở bảng web / sheet iPhone: nút "Xong" / "Hoàn tất", gợi ý còn thiếu.
function bj06RefreshClassify(line){
  document.querySelectorAll(`[data-io06-class-hint="${CSS.escape(line.id)}"]`).forEach(el=>{el.textContent=bj06ClassHint(line);});
  const done=io06AllClassValid(),open=io06CurrentLines().filter(l=>!io06ClassValid(l)).length;
  const btn=document.querySelector('[data-io06-action="confirm-classification"]');if(btn)btn.disabled=!done;
  document.querySelectorAll(".app-actions [data-k4-reason]").forEach(p=>{p.textContent=open>0?`Còn ${open} dòng chưa phân loại`:"";p.hidden=open<=0;});
}
function bj06RefreshDraft(){
  const line=io06ActiveLine(),draft=io06ClassificationDraftFor(line);if(!line||!draft)return;
  document.querySelectorAll("[data-io06-class]:not([data-io06-cell-line])").forEach(el=>{draft[el.dataset.io06Class]=Math.max(0,Number(el.value)||0);});
  const total=Number(draft.sellable||0)+Number(draft.quarantine||0)+Number(draft.damaged||0);
  const progress=document.querySelector("[data-io06-class-progress]");if(progress)progress.textContent=`${total}/${io06QtyDisplay(line.qty)} ${line.uom}`;
  const feedback=document.querySelector("[data-io06-class-feedback]");if(feedback)feedback.innerHTML=bj06DraftFeedback(line,draft);
  const done=document.querySelector('[data-io06-action="close-classification-item"]');if(done)done.disabled=!io06DraftValid(line,draft);
}
function bj06ApplyEvidence(line,file,name){
  line.evidenceFile=name;line.evidenceVersion=Number(line.evidenceVersion||0)+1;line.evidenceId=`EV-${line.id}-${String(line.evidenceVersion).padStart(3,"0")}`;line.evidenceHash=file.hash;line.evidenceData=file.data;
  io06SetLineDirty(line);
}

document.addEventListener("input", (event) => {
  if (activeFlowId !== "UIF-06") return;
  const t = event.target;
  if (t.matches("[data-io06-search]")) { io06Query = t.value; ioFilterRows("io06", io06Query); return; }
  if (t.matches("[data-io06a-search]")) { io06ApprovalQuery = t.value; ioFilterRows("io06a", io06ApprovalQuery); return; }
  if (t.matches("[data-io06-reason-detail]")) { const line = io06ActiveLine(); line.reasonDetail = t.value; io06SetLineDirty(line); bj06RefreshDetail(); return; }
  if (t.matches("[data-io06-reject-reason]")) { io06RejectReason = t.value; const b = document.querySelector('[data-io06-action="confirm-reject"]'); if (b) b.disabled = !io06RejectReason.trim(); return; }
  if (t.matches("[data-io06-class]")) {
    const cellLine = t.dataset.io06CellLine;
    if (cellLine) { const line = io06FindLine(cellLine); if (!line) return; line.classMode = "SPLIT"; line.classification = { ...(line.classification || bj06BlankClass()), [t.dataset.io06Class]: Math.max(0, Number(t.value) || 0), expired: 0 }; bj06RefreshClassify(line); return; }
    bj06RefreshDraft(); return;
  }
  if (t.matches("[data-io06-qty]")) { const line = io06ActiveLine(); const raw = t.value; line.qty = raw === "" ? null : Math.max(0, Number(raw) || 0); io06SetLineDirty(line); bj06RefreshDetail(); return; }
  if (t.matches("[data-io06-actual-lot]")) { const line = io06ActiveLine(); line.actualLot = t.value; line.actualLotMode = "OTHER"; if (!line.reasonCode) line.reasonCode = "RETURNED_DIFFERENT_LOT"; io06SetLineDirty(line); bj06RefreshDetail({ lotExtra: true }); return; }
  if (t.matches("[data-bj06-new-lot-expiry]")) { const line = io06ActiveLine(); line.newLotExpiry = t.value; io06SetLineDirty(line); bj06RefreshDetail(); return; }
  if (t.matches("[data-bj06-new-lot-manufacture]")) { const line = io06ActiveLine(); line.newLotManufacture = t.value; io06SetLineDirty(line); return; }
});

document.addEventListener("change", (event) => {
  if (activeFlowId !== "UIF-06") return;
  const t = event.target;
  if (t.matches("[data-io06-evidence-file]")) {
    const line = io06ActiveLine(), file = t.files?.[0];
    if (!file) { line.evidenceFile = ""; line.evidenceData = ""; line.evidenceId = ""; line.evidenceHash = ""; io06SetLineDirty(line); return bj06Rerender(); }
    const reader = new FileReader();
    reader.onload = async () => { bj06ApplyEvidence(line, { data: String(reader.result || ""), hash: await bj06FileSha256(file) }, file.name); bj06Rerender(); };
    reader.readAsDataURL(file);
  }
});

onDialogClose["UIF-06"] = () => {
  if (!(io06RejectOpen || io06ClassificationOpen || io06ResultSheetOpen)) return false;
  io06RejectOpen = false; io06ClassificationOpen = false; io06ClassificationDraft = null; io06ResultSheetOpen = false;
  renderAppScreen(); return true;
};

function bj06CanDecide() { return ["approver", "owner"].includes(currentActor()); }

// Ở pha capture: k2RejectSheet chặn nổi bọt (onclick stopPropagation) nên chỉ pha capture mới thấy nút trong sheet.
document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-06") return;
  const t = event.target, hit = (sel) => t.closest?.(sel);
  let el;
  if (hit('[data-action="exit-io06-approval"]')) { event.stopPropagation(); event.preventDefault(); io06RejectOpen = false; io06SetState("SCR-034", "TASK_LIST"); return renderAppScreen(); }
  if ((el = hit("[data-io06-filter]"))) { event.preventDefault(); io06QueueFilter = el.dataset.io06Filter; return renderAppScreen(); }
  if (hit("[data-io06a-filter]")) { event.preventDefault(); return renderAppScreen(); }
  if ((el = hit("[data-io06-request]"))) {
    event.preventDefault(); if (el.closest("[aria-disabled='true']") || el.disabled) return;
    io06Select(el.dataset.io06Request); const target = el.dataset.io06Target || "SCR-031";
    if (target === "SCR-033") io06SetState("SCR-033", "READY"); else io06SetState("SCR-031", "READY");
    return navigate(target);
  }
  if ((el = hit("[data-io06-line]"))) {
    event.preventDefault(); io06ActiveLineId = el.dataset.io06Line;
    if (viewport === "web") return bj06Rerender(`[data-io06-qty]`);
    return navigate("SCR-032");
  }
  if (hit("[data-io06-fill-max]")) { event.preventDefault(); const line = io06ActiveLine(); line.qty = bj06LineMax(line); io06SetLineDirty(line); return bj06Rerender("[data-io06-qty]"); }
  if ((el = hit("[data-io06-class-mode]"))) {
    event.preventDefault();
    const mode = el.dataset.io06ClassMode, lineId = el.dataset.io06ClassLine;
    if (lineId) { const line = io06FindLine(lineId); if (!line || bj06IsExpired(line)) return; if (mode === "SPLIT") line.classMode = "SPLIT"; else bj06ClassifyWhole(line, mode); io06ActiveLineId = line.id; return bj06Rerender(`[data-io06-class-line="${CSS.escape(line.id)}"][data-io06-class-mode="${mode}"]`); }
    const line = io06ActiveLine(), draft = io06ClassificationDraftFor(line);
    if (!line || !draft) return;
    if (mode === "SPLIT") { draft.mode = "SPLIT"; return bj06Rerender(`[data-io06-class-mode="SPLIT"]`); }
    bj06ClassifyWhole(line, mode); io06ClassificationOpen = false; io06ClassificationDraft = null; return bj06Rerender(`[data-io06-class-line="${CSS.escape(line.id)}"]`);
  }
  if ((el = hit("[data-io06-class-line]"))) { event.preventDefault(); io06ActiveLineId = el.dataset.io06ClassLine; io06ClassificationDraft = null; io06ClassificationOpen = true; return renderAppScreen(); }
  if ((el = hit("[data-io06-reason]"))) { event.preventDefault(); const line = io06ActiveLine(); line.reasonCode = el.dataset.io06Reason; if (line.reasonCode !== "OTHER") line.reasonDetail = ""; io06SetLineDirty(line); return bj06Rerender(`[data-io06-reason="${el.dataset.io06Reason}"]`); }
  if ((el = hit("[data-io06-select-actual-lot]"))) {
    event.preventDefault(); const line = io06ActiveLine();
    line.newLotExpiry = ""; line.newLotManufacture = ""; line.evidenceId = ""; line.evidenceVersion = 0; line.evidenceHash = "";
    line.actualLot = el.dataset.io06SelectActualLot; line.actualLotMode = "EXPECTED"; line.reasonCode = ""; line.reasonDetail = ""; line.evidenceFile = ""; line.evidenceData = "";
    io06SetLineDirty(line); return bj06Rerender(`[data-io06-select-actual-lot]`);
  }
  if (hit("[data-io06-select-other-lot]")) {
    event.preventDefault(); const line = io06ActiveLine();
    if (!line.reasonCode) line.reasonCode = "RETURNED_DIFFERENT_LOT";
    line.newLotExpiry = ""; line.newLotManufacture = ""; line.actualLotMode = "OTHER"; if (line.actualLot === line.expectedLot) line.actualLot = "";
    io06SetLineDirty(line); return bj06Rerender("[data-io06-actual-lot]");
  }
  if ((el = hit("[data-io06-approval-case]"))) { event.preventDefault(); io06SelectedApprovalCaseId = el.dataset.io06ApprovalCase; io06RejectOpen = false; io06SetState("SCR-034", "READY"); return renderAppScreen(); }
  if (hit("[data-io06-result-detail]")) { event.preventDefault(); io06ResultSheetOpen = true; return renderAppScreen(); }
  if (hit("[data-io06-sheet-close]") || t.matches?.("[data-io06-sheet-close-backdrop]")) { event.preventDefault(); io06ResultSheetOpen = false; return renderAppScreen(); }
  if (t.matches?.("[data-io06-sheet-backdrop]")) { event.preventDefault(); io06ClassificationOpen = false; io06ClassificationDraft = null; return renderAppScreen(); }

  const a = hit("[data-io06-action]"); if (!a) return;
  // Nền của k2RejectSheet mang data-io06-action="close-reject": chỉ đóng khi bấm đúng nền, không phải bên trong sheet.
  if (a.matches(".sheet-backdrop") && t !== a) return;
  event.preventDefault(); event.stopPropagation(); if (a.disabled) return;
  const k = a.dataset.io06Action;
  if (k === "clear-filter") { io06QueueFilter = "ALL"; io06Query = ""; if (stateByScreen["SCR-030"] === "FILTER_EMPTY") io06SetState("SCR-030", "READY"); return renderAppScreen(); }
  if (k === "clear-approval-filter") { io06ApprovalQuery = ""; return renderAppScreen(); }
  if (k === "save-return-line" || k === "save-return-exception") {
    const line = io06ActiveLine(), blk = line ? bj06LineBlock(line) : { blocked: true };
    if (!line || blk.blocked || (k === "save-return-exception" && !io06Mismatch(line))) return;
    line.verified = true;
    if (!io06Mismatch(line)) { const c = io06LineCase(line); if (c) { c.status = "SUPERSEDED"; c.supersededAt = bj06IsoNow(); } line.exceptionCaseId = null; line.reasonCode = ""; line.reasonDetail = ""; line.evidenceFile = ""; line.evidenceData = ""; line.evidenceId = ""; line.evidenceVersion = 0; line.evidenceHash = ""; }
    else io06InvalidateCaseIfChanged(line);
    io06RefreshRequestState(io06CurrentRequest());
    if (viewport === "web") { const next = bj06NextLine(line); if (next) io06ActiveLineId = next.id; return bj06Rerender(next ? "[data-io06-qty]" : ""); }
    return navigate("SCR-031");
  }
  if (k === "submit-return-exceptions") { const req = io06CurrentRequest(); if (!io06SubmitDraftExceptions(req)) return; return renderAppScreen(); }
  if (k === "commit-receipt") { const req = io06CurrentRequest(); if (!io06ReceiptReady(req)) return; bj06CommitReceipt(req); io06SetState("SCR-035", "RECEIVED_PENDING_CLASSIFICATION"); return navigate("SCR-035"); }
  if (k === "close-classification-item") { const line = io06ActiveLine(), draft = io06ClassificationDraftFor(line); if (!line || !io06DraftValid(line, draft)) return; line.classification = { sellable: Number(draft.sellable || 0), quarantine: Number(draft.quarantine || 0), damaged: Number(draft.damaged || 0), expired: 0 }; line.classMode = "SPLIT"; io06ClassificationOpen = false; io06ClassificationDraft = null; return bj06Rerender(`[data-io06-class-line="${CSS.escape(line.id)}"]`); }
  if (k === "cancel-classification-item") { io06ClassificationOpen = false; io06ClassificationDraft = null; return renderAppScreen(); }
  if (k === "confirm-classification") { if (!io06AllClassValid()) return; const req = io06CurrentRequest(); io06CurrentLines().forEach((l) => { l.classification = io06EffClass(l); bj06PostReturn(req, l); }); req.classified = true; req.classifiedAt = bj06IsoNow(); req.closed = true; req.status = "Đã phân loại"; req.queue = "CLOSED"; io06SetState("SCR-035", "COMPLETED"); return navigate("SCR-035"); }
  if (k === "approve-exception") {
    if (!bj06CanDecide()) { io06SetState("SCR-034", "SELF_APPROVAL_NOT_ALLOWED"); return renderAppScreen(); }
    const c = io06SelectedApprovalCase(); if (!c || c.status !== "PENDING") return; c.status = "APPROVED"; c.decisionReason = ""; io06AfterApprovalDecision(c); io06SetState("SCR-034", "APPROVED"); return renderAppScreen();
  }
  if (k === "open-reject") { io06RejectOpen = true; io06RejectReason = ""; return renderAppScreen(); }
  if (k === "close-reject") { io06RejectOpen = false; return renderAppScreen(); }
  if (k === "confirm-reject") {
    if (!io06RejectReason.trim()) return;
    if (!bj06CanDecide()) { io06RejectOpen = false; io06SetState("SCR-034", "SELF_APPROVAL_NOT_ALLOWED"); return renderAppScreen(); }
    const c = io06SelectedApprovalCase(); if (!c || c.status !== "PENDING") return; c.status = "REJECTED"; c.decisionReason = io06RejectReason.trim(); io06RejectOpen = false; io06AfterApprovalDecision(c); io06SetState("SCR-034", "REJECTED"); return renderAppScreen();
  }
  if (k === "exit-approval-detail") { io06RejectOpen = false; io06SetState("SCR-034", "TASK_LIST"); return renderAppScreen(); }
  if (k === "refresh-return-request") {
    const req = io06CurrentRequest(), line = io06CurrentLines()[0];
    if (stateByScreen[activeScreenId] === "RETURN_CAP_CHANGED" && line) { line.authorizedQuantity = Math.max(1, Number(line.authorizedQuantity || 0) - 1); line.remainingAuthorized = Math.max(1, Number(line.remainingAuthorized || 0) - 1); if (Number(line.qty || 0) > bj06LineMax(line)) { line.qty = null; line.verified = false; } }
    io06SetState(activeScreenId, "READY"); io06RefreshRequestState(req); return renderAppScreen();
  }
  if (k === "open-classification") { io06ClassificationOpen = false; io06ClassificationDraft = null; io06SetState("SCR-033", "READY"); return navigate("SCR-033"); }
  if (k === "result-to-return-queue") { io06QueueFilter = "ALL"; io06Query = ""; io06ClassificationOpen = false; io06ClassificationDraft = null; io06ResultSheetOpen = false; return navigate("SCR-030"); }
  if (k === "back-to-return-request") { io06SetState("SCR-031", "READY"); return navigate("SCR-031"); }
  if (k === "see-inventory") { activeFlowId = "UIF-01"; activeScreenId = "SCR-001"; stateByScreen["SCR-001"] = "READY"; syncReviewUrl(); return render(); }
}, true);

onPrevious["UIF-06"] = () => {
  if (activeScreenId === "SCR-031") return navigate("SCR-030");
  if (activeScreenId === "SCR-032") return navigate("SCR-031");
  if (activeScreenId === "SCR-033") { io06ClassificationOpen = false; io06ClassificationDraft = null; return navigate("SCR-030"); }
};

/* ---------- Home "Chờ duyệt" (K2) và lối vào trực tiếp ---------- */

// Mỗi ca chờ một dòng: "{sản phẩm} · Lô {lô thực nhận}" / "{mã yêu cầu} · {người gửi} gửi {lúc}"; mở thẳng SCR-034 với đúng ca.
(window.__T7_PENDING_SOURCES__ ||= []).push({
  id: "UIF-06",
  label: "ngoại lệ lô hàng trả",
  needsActivation: true,
  rows: () => io06ApprovalCases.filter((c) => c.status === "PENDING").map((c) => {
    const line = io06FindLine(c.lineId), snap = c.snapshot || {};
    return { title: `${line?.name || "Mặt hàng"} · Lô ${bj06Upper(snap.actualLot)}`, subtitle: `${c.requestId} · ${c.maker} gửi ${c.createdAt}`, icon: "rotate", attrs: `data-theme-entry-flow="UIF-06" data-t380-target-screen="SCR-034" data-t380-context="bj06-approval:${bj06Attr(c.id)}" data-theme-entry-actor="approver"` };
  }),
});
(window.__T7_DIRECT_CONTEXTS__ ||= {})["bj06-approval"] = (caseId) => { io06SelectedApprovalCaseId = caseId; io06RejectOpen = false; io06RejectReason = ""; io06SetState("SCR-034", "READY"); };

Object.assign(window.__C45_QA__, {
  bumpIO06Source(){const r=io06CurrentRequest();r.sourceVersion=Number(r.sourceVersion||0)+1;io06RefreshRequestState(r);return r.sourceVersion;},
  // Đặt ảnh nhãn lô mẫu cho dòng (mặc định dòng đang mở) thay cho việc chọn tệp thật.
  setIO06Evidence(lineId){
    const line=lineId?io06FindLine(lineId):io06ActiveLine();if(!line)return false;
    const lot=bj06Upper(line.actualLot)||"LOT",data=io06EvidenceSvg(lot);
    bj06ApplyEvidence(line,{data,hash:'fixture:'+bj06StableHash(data).slice(5)},`anh-nhan-lo-${lot}.jpg`);
    bj06Rerender();return true;
  }
});
