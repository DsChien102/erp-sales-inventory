/* VET45 Theme 7 v3.9.5 — BJ07 supplier-return semantic hardening
 * Parent: v3.9.4
 * Approved decisions: T7-DR-138..143 / D07-01..D07-06
 */
(()=>{
  const ACTOR={id:'USR-WH-021',name:'Trần Huy · Thủ kho'};
  const STOCK_LABELS={SELLABLE:'Bán được',QUARANTINE:'Cách ly',DAMAGED:'Hỏng',EXPIRED:'Hết hạn'};
  const attr=(v)=>escapeAttribute(String(v??''));
  const num=(v)=>Number.isFinite(Number(v))?Number(v):0;
  const isoNow=()=>new Date().toISOString();
  const displayTime=(iso)=>{if(!iso)return '—';const d=new Date(iso);return d.toLocaleString('vi-VN',{timeZone:'Asia/Ho_Chi_Minh',hour12:false});};
  function stableHash(input){let h1=2166136261>>>0,h2=2246822519>>>0;const s=typeof input==='string'?input:JSON.stringify(input);for(let i=0;i<s.length;i++){const c=s.charCodeAt(i);h1=Math.imul(h1^c,16777619)>>>0;h2=Math.imul(h2^c,3266489917)>>>0;}const base=h1.toString(16).padStart(8,'0')+h2.toString(16).padStart(8,'0');return (base+base+base+base).slice(0,64);}
  function sourceBalanceId(a,state){return `BAL-${String(a.sourceAllocationId||a.id).replace(/[^A-Z0-9]/gi,'')}-${state}`;}
  function defaultCandidateState(group,a){
    if(a.id==='RTV-A1')return null;
    if(a.id==='RTV-A2')return 'DAMAGED';
    if(a.id==='RTV-A8')return 'QUARANTINE';
    return 'SELLABLE';
  }
  function seedCandidates(group,a,force=false){
    if(!force&&Array.isArray(a.sourceStateCandidates)&&a.sourceStateCandidates.length)return;
    if(a.id==='RTV-A1'){
      a.sourceStateCandidates=[
        {state:'SELLABLE',available:3,balanceId:sourceBalanceId(a,'SELLABLE'),balanceVersion:12},
        {state:'DAMAGED',available:2,balanceId:sourceBalanceId(a,'DAMAGED'),balanceVersion:7}
      ];
      a.sourceSlices=[];
      a.sourceSliceUserResolved=false;
      return;
    }
    const state=defaultCandidateState(group,a)||'SELLABLE';
    a.sourceStateCandidates=[{state,available:Math.max(num(a.qty),1),balanceId:sourceBalanceId(a,state),balanceVersion:5}];
    a.sourceSlices=[{state,qty:num(a.qty),balanceId:sourceBalanceId(a,state),balanceVersion:5}];
    a.sourceSliceUserResolved=false;
  }
  function seedAllocation(req,group,a,force=false){
    req.sourceRequestId=req.sourceRequestId||req.source;
    req.warehouseId=req.warehouseId||'WH-MAIN';
    req.operationId=req.operationId||`IO-RTV-${String(req.id).replace(/^RTV-/,'')}`;
    group.sourceLineId=group.sourceLineId||`SRC-LINE-${group.id}`;
    a.sourceAllocationId=a.sourceAllocationId||a.id;
    a.sourceLineId=a.sourceLineId||group.sourceLineId;
    a.sourceRequestId=req.sourceRequestId;
    a.sourceVersion=req.sourceVersion;
    seedCandidates(group,a,force);
    if(!a.physicalObservation)a.physicalObservation=null;
  }
  function seedRequest(req){for(const group of req.groups||[])for(const a of group.allocations||[])seedAllocation(req,group,a,false);}
  io07Requests.forEach(seedRequest);

  function sliceTotal(a){return (a.sourceSlices||[]).reduce((s,x)=>s+num(x.qty),0);}
  function slicesResolved(a){return num(a.qty)>=0 && Math.abs(sliceTotal(a)-num(a.qty))<0.000001 && (a.sourceSlices||[]).every(x=>num(x.qty)>=0);}
  function sourceSliceSummary(a){
    if(!slicesResolved(a))return 'Chưa xác định đủ nguồn tồn';
    return (a.sourceSlices||[]).filter(x=>num(x.qty)>0).map(x=>`${STOCK_LABELS[x.state]||x.state} ${num(x.qty)}`).join(' · ')||'—';
  }
  function activeFound(){return io07FindAllocation(io07ActiveAllocationId,io07Current());}
  function scanMatches(group,a){
    if(group.tracking!=='LOT')return true;
    const scanned=String(io07ScanLot||'').trim();
    return !scanned || scanned.toLocaleUpperCase('vi')===String(a.lot||'').trim().toLocaleUpperCase('vi');
  }
  io07AllVerified=function(req=io07Current()){
    const lines=io07Allocations(req);
    return lines.length>0&&lines.every(({allocation})=>allocation.verified&&!allocation.physicalMismatch&&slicesResolved(allocation));
  };

  function preparationGroups(req,readOnly=false){
    return (req.groups||[]).map(group=>{
      const progress=io07ProductProgress(group);
      const heading=io07ProductGroupHeader(group,{label:`${progress.verified}/${progress.total} đã kiểm`,tone:progress.tone,role:'rtv-product-summary'});
      const rows=(group.allocations||[]).map(a=>{
        const status=a.physicalMismatch?'Chờ cập nhật':a.affectedByChange?'Cần kiểm lại':a.verified?'Đã kiểm':'';
        let subtitle=`${a.qty} ${group.uom}`;
        if(a.expiry)subtitle+=` · HSD ${a.expiry}`;
        if(status)subtitle+=` · ${status}`;
        if(a.previousQty!=null&&a.affectedByChange)subtitle+=` · trước ${a.previousQty} ${group.uom}`;
        const sourceNote=(a.sourceStateCandidates||[]).length>1?(slicesResolved(a)?` · Nguồn tồn: ${sourceSliceSummary(a)}`:' · Cần xác định nguồn tồn'):'';
        subtitle+=sourceNote;
        return ds24ListRow({title:io07AllocationLabel(group,a),subtitle,leading:null,attrs:readOnly?'':`data-io07-allocation="${attr(a.id)}" data-layout-role="rtv-allocation-row"`,type:readOnly?'Status':'Navigation',density:'Default',interactive:!readOnly,state:readOnly?'Disabled':'Default',disabled:readOnly});
      }).join('');
      return `<div class="io07-product-group ds24-grouped-subgroup" data-layout-role="product-allocation-subgroup" data-composed-from="DS v2 / List Row,VBadge">${heading}<div class="io07-allocation-list">${rows}</div></div>`;
    }).join('');
  }

  io07ReviewGroups=function(reqOrLines,{statusLabel='Đã kiểm',statusTone='Success'}={}){
    let groups=[];
    if(Array.isArray(reqOrLines)){
      const map=new Map();
      for(const line of reqOrLines||[]){const key=`${line.name}|${line.code||''}|${line.uom}`;if(!map.has(key))map.set(key,{name:line.name,code:line.code||'',uom:line.uom,tracking:line.lot?'LOT':'NONE',allocations:[]});map.get(key).allocations.push({...line});}
      groups=[...map.values()];
    } else groups=(reqOrLines?.groups||[]);
    const subgroups=groups.map(group=>{
      const heading=io07ProductGroupHeader(group,{label:statusLabel,tone:statusTone,role:'rtv-review-product'});
      const rows=(group.allocations||[]).map(a=>{
        const left=a.lot?`Lô ${a.lot}${a.expiry?` · HSD ${a.expiry}`:''}`:'Không theo lô';
        const source=(a.sourceSliceUserResolved||(a.sourceSlices||[]).length>1)?ds24KeyValueRow('Nguồn tồn',sourceSliceSummary(a)):'';
        return `${ds24KeyValueRow(left,`${a.qty} ${group.uom}`)}${source}`;
      }).join('');
      return `<div class="io07-review-product ds24-grouped-subgroup" data-layout-role="product-fact-subgroup" data-composed-from="VIcon,VText,VBadge,DS v2 / Key-value Row">${heading}<div class="io07-review-kv">${rows}</div></div>`;
    }).join('');
    return ds24GroupedCollection(subgroups,'io07-review-products io07-grouped-collection io07-grouped-collection--facts','DS v2 / List Row,DS v2 / Key-value Row');
  };

  io07SourceDelta=function(req){
    const notes=(req.sourceChanges||[]).filter(Boolean);
    if(!req.changed&&!notes.length)return '';
    const detail=notes.length?notes.join(' '):'Yêu cầu nguồn đã thay đổi. Chỉ phần bị ảnh hưởng cần kiểm lại.';
    return vBanner('warning','Yêu cầu đã cập nhật',detail,'','Compact');
  };

  let mismatchSheetOpen=false,mismatchType='',mismatchQty='',mismatchLot='',mismatchNote='';
  function sourceSliceInputs(group,a){
    const candidates=a.sourceStateCandidates||[];
    if(candidates.length<=1)return '';
    const current=new Map((a.sourceSlices||[]).map(s=>[s.state,num(s.qty)]));
    const fields=candidates.map(c=>`<label class="ds24-field v395-source-slice-field" data-ds-component="VNumberField"><span class="vet45-text-style-8">${esc(STOCK_LABELS[c.state]||c.state)}</span><div class="v395-source-slice-control"><input class="ds24-field__control vet45-text-style-6" type="number" min="0" max="${c.available}" step="1" inputmode="decimal" value="${attr(current.get(c.state)||'')}" data-io07-source-slice="${attr(c.state)}"><small class="vet45-text-style-11">Tối đa ${c.available} ${esc(group.uom)}</small></div></label>`).join('');
    const ok=slicesResolved(a);
    return `<section class="v395-source-slices" data-composed-from="VNumberField,DS v2 / Key-value Row">${ds24SectionTitle('Xác định nguồn tồn',`${sliceTotal(a)}/${a.qty} ${group.uom}`)}<p class="vet45-text-style-11 v395-source-help">Cùng lô đang nằm ở nhiều trạng thái. Chọn đúng lượng thực tế cần trả từ từng trạng thái.</p>${fields}<div data-v395-source-feedback>${ok?'':vBanner('warning','Chưa đủ nguồn tồn',`Cần phân bổ đúng ${a.qty} ${group.uom}.`,'','Compact')}</div></section>`;
  }
  function verifyButtonDisabled(group,a){return !scanMatches(group,a)||!slicesResolved(a);}
  function syncVerifyButton(){
    const found=activeFound();if(!found)return;const {group,allocation:a}=found;
    const b=document.querySelector('[data-io07-action="confirm-allocation"]');if(b)b.disabled=verifyButtonDisabled(group,a);
    const fb=document.querySelector('[data-v395-source-feedback]');if(fb)fb.innerHTML=slicesResolved(a)?'':vBanner('warning','Chưa đủ nguồn tồn',`Cần phân bổ đúng ${a.qty} ${group.uom}.`,'','Compact');
    const title=document.querySelector('.v395-source-slices .ds24-section-title span');if(title)title.textContent=`${sliceTotal(a)}/${a.qty} ${group.uom}`;
  }
  io07VerificationSheet=function(req){
    if(!io07VerifySheetOpen)return '';const found=io07FindAllocation(io07ActiveAllocationId,req);if(!found)return '';const {group,allocation:a}=found;
    const expectedLot=group.tracking==='LOT'?String(a.lot||''):'';const mismatch=Boolean(expectedLot&&String(io07ScanLot||'').trim()&&String(io07ScanLot).trim().toLocaleUpperCase('vi')!==expectedLot.toLocaleUpperCase('vi'));
    const product=ds24ContextStatusRow({title:group.name,subtitle:`${group.code} · ${group.uom}`,label:a.verified?'Đã kiểm':'Cần kiểm',tone:a.verified?'Success':'Neutral',leading:'package',attrs:'data-layout-role="rtv-verify-product"'});
    const facts=ds24InfoGroup('',`${ds24InfoRow('Cần chuẩn bị',`${a.qty} ${group.uom}`)}${group.tracking==='LOT'?ds24InfoRow('Lô theo yêu cầu',a.lot):''}${a.expiry?ds24InfoRow('Hạn dùng',a.expiry):''}`,'ds24-info-group--untitled io07-sheet-facts');
    const lotInput=group.tracking==='LOT'?`${ds24TextField('Lô thực tế (không bắt buộc)',io07ScanLot,'data-io07-scan-lot autocomplete="off"','Chỉ đối chiếu với lô theo yêu cầu.')}<div data-io07-scan-feedback>${mismatch?vBanner('error','Lô không khớp',`Theo yêu cầu là lô ${expectedLot}. Hãy ghi nhận chênh lệch để Mua hàng cập nhật.`,'','Compact'):''}</div>`:'';
    const sources=sourceSliceInputs(group,a);
    return `<div class="sheet-backdrop io07-verify-backdrop" data-io07-verify-backdrop><section class="bottom-sheet io-bottom-sheet io07-verification-sheet v395-verification-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="Kiểm hàng thực tế"><div class="sheet-handle"></div><div class="sheet-title"><h3>Kiểm hàng thực tế</h3></div><div class="io07-verification-content">${product}${facts}${lotInput}${sources}<div class="io07-sheet-actions"><button class="button button--secondary" data-io07-action="mark-mismatch" type="button">Không khớp</button><button class="button button--primary" data-io07-action="confirm-allocation" type="button" ${verifyButtonDisabled(group,a)?'disabled':''}>Đúng hàng</button></div></div></section></div>`;
  };

  function mismatchSheet(req){
    if(!mismatchSheetOpen)return '';const found=io07FindAllocation(io07ActiveAllocationId,req);if(!found)return '';const {group,allocation:a}=found;
    const options=[['QUANTITY','Sai số lượng'],['LOT','Sai lô'],['ITEM_NOT_FOUND','Không thấy hàng'],['OTHER','Khác']].map(([v,l])=>`<button type="button" class="v395-mismatch-choice${mismatchType===v?' is-selected':''}" data-io07-action="select-mismatch" data-io07-mismatch-type="${v}" aria-pressed="${mismatchType===v?'true':'false'}">${l}</button>`).join('');
    const qty=mismatchType==='QUANTITY'?ds24TextField('Số lượng thực tế',mismatchQty,'data-io07-mismatch-qty type="number" min="0" step="1" inputmode="decimal"',`Theo yêu cầu: ${a.qty} ${group.uom}`):'';
    const lot=mismatchType==='LOT'?ds24TextField('Lô thực tế',mismatchLot,'data-io07-mismatch-lot autocomplete="off"',`Theo yêu cầu: ${a.lot||'—'}`):'';
    const note=mismatchType==='OTHER'?ds24TextField('Mô tả chênh lệch',mismatchNote,'data-io07-mismatch-note autocomplete="off"','Bắt buộc khi chọn Khác.'):'';
    const valid=Boolean(mismatchType&&(mismatchType!=='QUANTITY'||String(mismatchQty).trim()!=='')&&(mismatchType!=='LOT'||String(mismatchLot).trim())&&(mismatchType!=='OTHER'||String(mismatchNote).trim()));
    return `<div class="sheet-backdrop v395-mismatch-backdrop"><section class="bottom-sheet io-bottom-sheet v395-mismatch-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="Ghi nhận chênh lệch thực tế"><div class="sheet-handle"></div><div class="sheet-title"><h3>Ghi nhận chênh lệch</h3></div><div class="sheet-content"><p class="vet45-text-style-11 v395-source-help">Chỉ ghi nhận điều nhìn thấy thực tế. Kho không tự sửa yêu cầu trả hoặc thay lô.</p><div class="v395-mismatch-choices">${options}</div>${qty}${lot}${note}<div class="io07-sheet-actions"><button class="button button--secondary" data-io07-action="close-mismatch" type="button">Hủy</button><button class="button button--primary" data-io07-action="record-mismatch-observation" type="button" ${valid?'':'disabled'}>Gửi chênh lệch</button></div></div></section></div>`;
  }

  function mismatchValid(){return Boolean(mismatchType&&(mismatchType!=='QUANTITY'||String(mismatchQty).trim()!=='')&&(mismatchType!=='LOT'||String(mismatchLot).trim())&&(mismatchType!=='OTHER'||String(mismatchNote).trim()));}
  function syncMismatchButton(){const b=document.querySelector('[data-io07-action="record-mismatch-observation"]');if(b)b.disabled=!mismatchValid();}
  function recordObservation(req){
    const found=activeFound();if(!found)return false;const {group,allocation:a}=found;
    if(!mismatchValid())return false;
    const observation={
      observationId:`OBS-${a.sourceAllocationId}-${String((a.observationSeq||0)+1).padStart(3,'0')}`,
      sourceRequestId:req.sourceRequestId,sourceVersion:req.sourceVersion,sourceLineId:a.sourceLineId,sourceAllocationId:a.sourceAllocationId,
      mismatchType,expectedQuantity:a.qty,actualQuantity:mismatchType==='QUANTITY'?num(mismatchQty):null,expectedLot:a.lot||null,actualLot:mismatchType==='LOT'?String(mismatchLot).trim():null,note:mismatchType==='OTHER'?String(mismatchNote).trim():'',
      actorId:ACTOR.id,actor:ACTOR.name,observedAt:isoNow(),stockEffect:'NONE',status:'OPEN'
    };
    observation.observationHash=stableHash(observation);a.observationSeq=Number(a.observationSeq||0)+1;a.physicalObservation=observation;a.verified=false;a.physicalMismatch=true;a.affectedByChange=false;
    req.queue='WAITING';req.awaitingSourceAmendment=true;req.waitingReason='Đã gửi chênh lệch thực tế. Đang chờ Mua hàng cập nhật yêu cầu.';
    mismatchSheetOpen=false;io07VerifySheetOpen=false;io07ScanLot='';stateByScreen['SCR-037']='PHYSICAL_MISMATCH';return true;
  }

  io07ApplySourceUpdate=function(reqId,changes=[]){
    const req=io07Requests.find(r=>r.id===reqId);if(!req||req.completed||req.closed)return false;
    req.sourceVersion=Number(req.sourceVersion||0)+1;req.changed=true;const notes=[];const affected=new Set();
    for(const change of changes){
      if(change.type==='QTY'){
        const f=io07FindAllocation(change.allocationId,req);if(!f)continue;const a=f.allocation;a.previousQty=a.qty;a.qty=change.newQty;a.verified=false;a.physicalMismatch=false;a.affectedByChange=true;a.sourceVersion=req.sourceVersion;affected.add(a.id);
        // Keep stable source allocation identity; re-resolve source slices only when current exact composition no longer equals the new authorization.
        if(!slicesResolved(a)){seedCandidates(f.group,a,true);} else if((a.sourceStateCandidates||[]).length===1){a.sourceSlices[0].qty=num(a.qty);}
        notes.push(change.note||`${f.group.name} · ${f.group.uom}: ${a.previousQty} → ${change.newQty} ${f.group.uom}.`);
      } else if(change.type==='LOT'){
        const f=io07FindAllocation(change.allocationId,req);if(!f)continue;const a=f.allocation;a.previousLot=a.lot;a.lot=change.newLot;a.verified=false;a.physicalMismatch=false;a.affectedByChange=true;a.sourceVersion=req.sourceVersion;affected.add(a.id);seedCandidates(f.group,a,true);
        notes.push(change.note||`${f.group.name} · ${f.group.uom}: lô ${a.previousLot} → ${change.newLot}.`);
      } else if(change.type==='REMOVE'){
        for(const group of req.groups||[]){const idx=(group.allocations||[]).findIndex(a=>a.id===change.allocationId);if(idx>=0){const old=group.allocations[idx];group.allocations.splice(idx,1);affected.add(old.id);notes.push(change.note||`${group.name} · ${group.uom}${old.lot?` · lô ${old.lot}`:''}: bỏ khỏi yêu cầu; lượng chờ trả được trả về đúng trạng thái nguồn.`);break;}}
        req.groups=req.groups.filter(g=>(g.allocations||[]).length);
      } else if(change.type==='ADD'){
        let group=req.groups.find(g=>g.id===change.groupId);if(!group&&change.group){group={...change.group,allocations:[]};req.groups.push(group);}if(!group)continue;
        const a={...change.allocation,verified:false,physicalMismatch:false,affectedByChange:true};seedAllocation(req,group,a,true);group.allocations.push(a);affected.add(a.id);notes.push(change.note||`${group.name} · ${group.uom}${a.lot?` · lô ${a.lot}`:''}: thêm ${a.qty} ${group.uom} cần kiểm.`);
      }
    }
    for(const {allocation:a} of io07Allocations(req)){
      if(a.physicalObservation&&affected.has(a.id)){a.physicalObservation.status='RESOLVED_BY_SOURCE_VERSION';a.physicalObservation.resolvedSourceVersion=req.sourceVersion;}
      a.sourceVersion=req.sourceVersion;
    }
    req.sourceChanges=notes.length?notes:['Yêu cầu nguồn đã được cập nhật.'];req.awaitingSourceAmendment=false;req.queue='ACTIONABLE';return true;
  };

  io07CreateResult=function(req){
    const op=req.operationId||`IO-RTV-${String(req.id).replace(/^RTV-/,'')}`;req.operationId=op;const confirmedAt=isoNow();
    const lines=io07Allocations(req).map(({group,allocation:a})=>({groupId:group.id,sourceLineId:a.sourceLineId,sourceAllocationId:a.sourceAllocationId,name:group.name,code:group.code,uom:group.uom,lot:a.lot,expiry:a.expiry,qty:a.qty,sourceSlices:(a.sourceSlices||[]).map(s=>({...s})),sourceSliceUserResolved:!!a.sourceSliceUserResolved}));
    const evidence={handoverEvidenceId:`HE-${op}`,operationId:op,sourceType:'SUPPLIER_RETURN',sourceDocumentId:req.source,sourceVersion:req.sourceVersion,sourceContext:{sourceRequestId:req.sourceRequestId,inventoryRequestId:req.id},warehouseId:req.warehouseId,actorId:ACTOR.id,actor:ACTOR.name,confirmedAt,lineEvidence:lines.map(l=>({sourceLineId:l.sourceLineId,sourceAllocationId:l.sourceAllocationId,productCode:l.code,uom:l.uom,lot:l.lot,quantity:l.qty,sourceSlices:l.sourceSlices}))};
    evidence.evidenceHash=stableHash(evidence);
    io07LastResult={operationId:op,requestId:req.id,sourceRequestId:req.sourceRequestId,supplier:req.supplier,source:req.source,sourceVersion:req.sourceVersion,warehouse:req.warehouse,actorId:ACTOR.id,actor:ACTOR.name,confirmedAt,lines,handoverEvidence:evidence};req.handoverEvidence=evidence;req.confirmedAt=confirmedAt;return io07LastResult;
  };
  io07ResultSnapshot=function(){if(io07LastResult)return io07LastResult;const req=io07Current();return {operationId:req.operationId,requestId:req.id,sourceRequestId:req.sourceRequestId,supplier:req.supplier,source:req.source,sourceVersion:req.sourceVersion,warehouse:req.warehouse,actorId:ACTOR.id,actor:ACTOR.name,confirmedAt:req.confirmedAt||null,lines:io07Allocations(req).map(({group,allocation:a})=>({name:group.name,code:group.code,uom:group.uom,lot:a.lot,expiry:a.expiry,qty:a.qty,sourceLineId:a.sourceLineId,sourceAllocationId:a.sourceAllocationId,sourceSlices:(a.sourceSlices||[]).map(s=>({...s})),sourceSliceUserResolved:!!a.sourceSliceUserResolved}))};};

  const base036=renderers['SCR-036'];
  render036IO07=function(state){
    if(activeFlowId==='UIF-09')return render036IC09(state);if(activeFlowId==='UIF-10')return render036IC10(state);if(activeFlowId!=='UIF-07')return base036?base036(state):renderGeneric(screens.find(s=>s.id==='SCR-036'),state);
    if(state==='PERMISSION_DENIED')return appShell({title:'Hàng chờ trả nhà cung cấp',body:deniedBody(),centered:true,back:false});
    if(state==='LOADING')return appShell({title:'Hàng chờ trả nhà cung cấp',body:loadingBody(),back:false});
    const all=io07ActiveRequests().filter(r=>io07MatchesQueue(r));const candidates=all.filter(r=>ioMatchesSearch(io07Query,`${r.id} ${r.supplier} ${r.source}`));
    const search=ds24Search(io07Query,'data-io07-search','Tìm mã yêu cầu, NCC hoặc chứng từ');
    const filters=`<div class="io07-chip-scroll" data-composed-from="VChip">${[['ALL','Tất cả'],['ACTIONABLE','Cần chuẩn bị'],['READY','Sẵn sàng'],['WAITING','Đang chờ']].map(([k,l])=>ds24Chip(k,l,io07QueueFilter===k,'data-io07-filter')).join('')}</div>`;
    if(state==='EMPTY')return appShell({title:'Hàng chờ trả nhà cung cấp',body:`${search}${filters}${ioEmpty('Chưa có hàng chờ trả','Khi có yêu cầu trả đang hiệu lực, công việc sẽ xuất hiện tại đây.')}`,back:false});
    const queue=io07QueueList(candidates);const empty=`<div data-io07-filter-empty ${candidates.length?'hidden':''}>${ioEmpty('Không tìm thấy yêu cầu phù hợp','Đổi từ khóa hoặc bộ lọc để xem công việc khác.')}</div>`;
    return appShell({title:'Hàng chờ trả nhà cung cấp',body:`${search}${filters}${queue}${empty}`,back:false});
  };

  const base037=renderers['SCR-037'];
  render037IO07=function(state){
    if(activeFlowId==='UIF-09')return render037IC09(state);if(activeFlowId==='UIF-10')return render037IC10(state);if(activeFlowId!=='UIF-07')return base037?base037(state):renderGeneric(screens.find(s=>s.id==='SCR-037'),state);
    if(state==='PERMISSION_DENIED')return appShell({title:'Chuẩn bị hàng trả',body:deniedBody(),centered:true});if(state==='LOADING')return appShell({title:'Chuẩn bị hàng trả',body:loadingBody()});
    const req=io07Current(),total=io07Allocations(req).length,verified=io07VerifiedCount(req);const waiting=req.queue==='WAITING'||req.awaitingSourceAmendment;
    const requestContext=ds24ContextStatusRow({title:req.id,subtitle:`${req.supplier} · ${req.source}`,label:waiting?'Chờ cập nhật':`${verified}/${total}`,tone:waiting?'Info':io07HasMismatch(req)?'Danger':verified===total&&total?'Success':'Neutral',leading:null,attrs:'data-layout-role="rtv-request-context"'});
    if(req.sourceCancelled||req.closed)return appShell({title:'Chuẩn bị hàng trả',body:`${requestContext}${vBanner('info','Yêu cầu đã được hủy','Phần chờ trả đã được hệ thống trả về đúng trạng thái nguồn; Kho không cần thao tác thêm.','','Compact')}`,actions:primaryFooter('Về hàng chờ trả','data-io07-action="result-to-rtv-queue"')});
    const waitBanner=waiting?vBanner('info','Chờ cập nhật yêu cầu',req.waitingReason||'Kho chỉ xem trong lúc Mua hàng cập nhật yêu cầu theo chênh lệch thực tế.','','Compact'):'';
    const groups=preparationGroups(req,waiting);const collection=ds24GroupedCollection(groups,'io07-product-list io07-grouped-collection io07-grouped-collection--preparation','Product group header,Nested navigation row');
    const body=`${requestContext}${io07SourceDelta(req)}${waitBanner}${ds24SectionTitle('Hàng cần chuẩn bị',`${req.groups.length} nhóm sản phẩm`)}${collection}${waiting?'':io07VerificationSheet(req)}${waiting?'':mismatchSheet(req)}`;
    return appShell({title:'Chuẩn bị hàng trả',body,actions:waiting?'':primaryFooter('Rà soát bàn giao','data-io07-action="review-handover"',!io07AllVerified(req)||io07HasMismatch(req))});
  };

  const base039=renderers['SCR-039'];
  render039IO07=function(state){
    if(activeFlowId!=='UIF-07')return base039?base039(state):renderGeneric(screens.find(s=>s.id==='SCR-039'),state);if(state==='PERMISSION_DENIED')return appShell({title:'Bàn giao trả nhà cung cấp',body:deniedBody(),centered:true});
    const req=io07Current(),sourceChanged=state==='SOURCE_CHANGED'||Number(req.reviewSourceVersion||req.sourceVersion)!==Number(req.sourceVersion),mismatch=io07HasMismatch(req)||state==='PHYSICAL_MISMATCH',ready=io07AllVerified(req)&&!sourceChanged&&!mismatch&&req.queue!=='WAITING';
    const context=ds24InfoGroup('Thông tin bàn giao',`${ds24InfoRow('Nhà cung cấp',req.supplier)}${ds24InfoRow('Yêu cầu trả',req.id)}${ds24InfoRow('Chứng từ nguồn',req.source)}${ds24InfoRow('Kho',req.warehouse)}`,'io07-handover-context');
    const review=`${ds24SectionTitle('Hàng sẽ bàn giao',`${req.groups.length} nhóm sản phẩm`)}${io07ReviewGroups(req,{statusLabel:'Đã kiểm',statusTone:'Success'})}`;
    if(!ready){const why=sourceChanged?'Yêu cầu nguồn đã thay đổi sau khi mở rà soát. Chỉ phần bị ảnh hưởng cần kiểm lại.':'Có phần hàng chưa đủ điều kiện bàn giao theo yêu cầu hiện hành.';return appShell({title:'Bàn giao trả nhà cung cấp',body:`${context}${vBanner('warning','Cần kiểm lại trước khi bàn giao',why,'','Compact')}${review}`,actions:primaryFooter('Kiểm lại hàng','data-io07-action="back-to-preparation"')});}
    return appShell({title:'Bàn giao trả nhà cung cấp',body:`${context}${review}`,actions:primaryFooter('Xác nhận đã bàn giao','data-io07-action="confirm-handover"')});
  };

  const base041=renderers['SCR-041'];
  render041IO07=function(state){
    if(activeFlowId!=='UIF-07')return base041?base041(state):renderGeneric(screens.find(s=>s.id==='SCR-041'),state);
    const currentReq=io07Current();const result=state==='UNKNOWN'?{operationId:currentReq.operationId,requestId:currentReq.id,sourceRequestId:currentReq.sourceRequestId,supplier:currentReq.supplier,source:currentReq.source,sourceVersion:currentReq.sourceVersion,warehouse:currentReq.warehouse,confirmedAt:currentReq.confirmedAt||null,lines:io07Allocations(currentReq).map(({group,allocation:a})=>({name:group.name,code:group.code,uom:group.uom,lot:a.lot,expiry:a.expiry,qty:a.qty,sourceLineId:a.sourceLineId,sourceAllocationId:a.sourceAllocationId,sourceSlices:(a.sourceSlices||[]).map(s=>({...s})),sourceSliceUserResolved:!!a.sourceSliceUserResolved}))}:io07ResultSnapshot(),req=io07Requests.find(r=>r.id===result.requestId)||currentReq;
    if(state==='PROCESSING')return appShell({title:'Kết quả trả nhà cung cấp',body:loadingBody(),centered:true,back:false});
    if(state==='UNKNOWN'){
      const body=ioResult('Đang xác minh kết quả','Không gửi lại bàn giao. Hệ thống đang xác minh đúng lần xử lý này bằng cùng operation identity.',[['Yêu cầu',result.requestId],['Chứng từ nguồn',result.source],['Tồn vật lý','Chưa kết luận']],'warning');
      const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-07" data-operation="${attr(result.operationId||req.operationId)}" data-scope="${attr(result.requestId+' · '+result.source)}"`;
      return appShell({title:'Xác minh kết quả',body,centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});
    }
    if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả trả nhà cung cấp',body:ioResult('Chưa ghi nhận bàn giao','Không có tác động tồn kho mới. Xem lại yêu cầu hiện hành trước khi tiếp tục.',[['Yêu cầu',result.requestId],['Tồn kho','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter(req&&!req.closed&&!req.completed?'Xem yêu cầu hiện tại':'Về hàng chờ trả',req&&!req.closed&&!req.completed?'data-io07-action="back-to-rtv-request"':'data-io07-action="result-to-rtv-queue"')});
    if(state==='PERMISSION_DENIED')return appShell({title:'Kết quả trả nhà cung cấp',body:ioResult('Không có quyền thực hiện','Tồn kho không thay đổi.',[['Kết quả','Không ghi nhận bàn giao'],['Tồn kho','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Về hàng chờ trả','data-io07-action="result-to-rtv-queue"')});
    const resultGroupCount=new Set((result.lines||[]).map(line=>`${line.name}|${line.code||''}|${line.uom}`)).size;
    const context=ds24InfoGroup('Thông tin trả hàng',`${ds24InfoRow('Nhà cung cấp',result.supplier)}${ds24InfoRow('Yêu cầu trả',result.requestId)}${ds24InfoRow('Chứng từ nguồn',result.source)}${ds24InfoRow('Bàn giao lúc',displayTime(result.confirmedAt))}`,'io07-result-context');
    const body=`<div class="io-result io07-result">${resultHero('Đã bàn giao cho nhà cung cấp','Tồn vật lý và giá trị đã giảm theo đúng hàng bàn giao.')}${context}${ds24SectionTitle('Hàng đã bàn giao',`${resultGroupCount} nhóm sản phẩm`)}${io07ReviewGroups(result.lines||[],{statusLabel:'Đã bàn giao',statusTone:'Success'})}</div>`;
    return appShell({title:'Kết quả trả nhà cung cấp',body,centered:false,back:false,actions:primaryFooter('Về hàng chờ trả','data-io07-action="result-to-rtv-queue"')});
  };
  renderers['SCR-036']=render036IO07;renderers['SCR-037']=render037IO07;renderers['SCR-039']=render039IO07;renderers['SCR-041']=render041IO07;

  window.addEventListener('input',event=>{
    if(activeFlowId!=='UIF-07')return;const t=event.target;
    if(t.matches('[data-io07-scan-lot]')){event.stopImmediatePropagation();io07ScanLot=t.value;const found=activeFound();if(found){const expected=String(found.allocation.lot||''),bad=!scanMatches(found.group,found.allocation);const fb=document.querySelector('[data-io07-scan-feedback]');if(fb)fb.innerHTML=bad?vBanner('error','Lô không khớp',`Theo yêu cầu là lô ${expected}. Hãy ghi nhận chênh lệch để Mua hàng cập nhật.`,'','Compact'):'';syncVerifyButton();}return;}
    if(t.matches('[data-io07-source-slice]')){event.stopImmediatePropagation();const found=activeFound();if(!found)return;const a=found.allocation,state=t.dataset.io07SourceSlice,c=(a.sourceStateCandidates||[]).find(x=>x.state===state);if(!c)return;const q=Math.max(0,Math.min(num(t.value),num(c.available)));const map=new Map((a.sourceSlices||[]).map(s=>[s.state,{...s}]));if(q>0)map.set(state,{state,qty:q,balanceId:c.balanceId,balanceVersion:c.balanceVersion});else map.delete(state);a.sourceSlices=[...map.values()];a.sourceSliceUserResolved=true;a.verified=false;syncVerifyButton();return;}
    if(t.matches('[data-io07-mismatch-qty]')){event.stopImmediatePropagation();mismatchQty=t.value;syncMismatchButton();return;}
    if(t.matches('[data-io07-mismatch-lot]')){event.stopImmediatePropagation();mismatchLot=t.value;syncMismatchButton();return;}
    if(t.matches('[data-io07-mismatch-note]')){event.stopImmediatePropagation();mismatchNote=t.value;syncMismatchButton();return;}
  },true);

  window.addEventListener('click',event=>{
    if(activeFlowId!=='UIF-07')return;
    const a=event.target.closest('[data-io07-action]');if(!a)return;const k=a.dataset.io07Action;
    if(!['mark-mismatch','select-mismatch','close-mismatch','record-mismatch-observation','confirm-allocation','confirm-handover'].includes(k))return;
    event.preventDefault();event.stopImmediatePropagation();
    if(k==='mark-mismatch'){
      const found=activeFound();if(!found)return;mismatchSheetOpen=true;io07VerifySheetOpen=false;mismatchType='';mismatchQty='';mismatchLot=String(io07ScanLot||'').trim()||'';mismatchNote='';return renderAppScreen();
    }
    if(k==='select-mismatch'){mismatchType=a.dataset.io07MismatchType||'';if(mismatchType==='LOT'&&!mismatchLot)mismatchLot=String(io07ScanLot||'').trim();return renderAppScreen();}
    if(k==='close-mismatch'){mismatchSheetOpen=false;mismatchType='';return renderAppScreen();}
    if(k==='record-mismatch-observation'){if(recordObservation(io07Current()))return renderAppScreen();return;}
    if(k==='confirm-allocation'){
      const found=activeFound();if(!found)return;const {group,allocation:x}=found;if(verifyButtonDisabled(group,x))return;x.verified=true;x.physicalMismatch=false;x.affectedByChange=false;x.verifyMethod=String(io07ScanLot||'').trim()?'SCAN_OR_TYPED_MATCH':'VISUAL';x.verifiedSourceVersion=io07Current().sourceVersion;x.verifiedAt=isoNow();io07VerifySheetOpen=false;io07ScanLot='';stateByScreen['SCR-037']='READY';return renderAppScreen();
    }
    if(k==='confirm-handover'){
      const req=io07Current();if(Number(req.reviewSourceVersion||req.sourceVersion)!==Number(req.sourceVersion)){stateByScreen['SCR-039']='SOURCE_CHANGED';return renderAppScreen();}if(!io07AllVerified(req)||io07HasMismatch(req)||req.queue==='WAITING')return;io07CreateResult(req);req.completed=true;req.queue='CLOSED';stateByScreen['SCR-041']='COMPLETED';return navigate('SCR-041');
    }
  },true);

  if(window.__VET45_PROTOTYPE__)window.__VET45_PROTOTYPE__.version='3.9.5';
})();
