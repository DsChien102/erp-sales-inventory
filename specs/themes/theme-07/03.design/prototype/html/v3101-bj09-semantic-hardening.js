(function(){
  'use strict';
  const VERSION='3.10.1';
  const BUSINESS_DATE='17/09/2026';
  const POLICY={
    id:'STPOL-INVENTORY-STATE',versionId:'STPOL-V7-20260917-01',version:'7',fixtureHash:'fixture-sha256-policy-v7',
    transitions:{
      SELLABLE:{
        QUARANTINE:{label:'Cách ly',reason:true,evidence:false,approval:true,eligibility:'DECREASE'},
        DAMAGED:{label:'Hỏng',reason:true,evidence:true,approval:true,eligibility:'DECREASE'},
        DEMO:{label:'Dùng thử',reason:true,evidence:false,approval:false,eligibility:'DECREASE'}
      },
      QUARANTINE:{
        SELLABLE:{label:'Bán được',reason:true,evidence:true,approval:true,eligibility:'INCREASE'},
        DAMAGED:{label:'Hỏng',reason:true,evidence:false,approval:true,eligibility:'UNCHANGED'},
        DEMO:{label:'Dùng thử',reason:true,evidence:false,approval:false,eligibility:'UNCHANGED'}
      },
      DAMAGED:{QUARANTINE:{label:'Cách ly',reason:true,evidence:true,approval:true,eligibility:'UNCHANGED'}},
      DEMO:{
        SELLABLE:{label:'Bán được',reason:true,evidence:true,approval:true,eligibility:'INCREASE'},
        QUARANTINE:{label:'Cách ly',reason:true,evidence:false,approval:false,eligibility:'UNCHANGED'},
        DAMAGED:{label:'Hỏng',reason:true,evidence:true,approval:true,eligibility:'UNCHANGED'}
      },
      EXPIRED:{}
    }
  };
  const SOURCE={
    amox:{slices:[{balanceId:'BAL-AMOX-C',version:7,valuationState:'VALUATION_CONFIRMED',qty:12},{balanceId:'BAL-AMOX-P',version:4,valuationState:'VALUATION_PENDING',qty:6}],reservationBefore:10},
    'găng':{slices:[{balanceId:'BAL-GLOVE-C',version:3,valuationState:'VALUATION_CONFIRMED',qty:6}],reservationBefore:0},
    vitc:{slices:[{balanceId:'BAL-VITC-C',version:2,valuationState:'VALUATION_CONFIRMED',qty:4}],reservationBefore:0},
    dungthu:{slices:[{balanceId:'BAL-DEMO-C',version:5,valuationState:'VALUATION_CONFIRMED',qty:2}],reservationBefore:0}
  };
  let draft={destination:'QUARANTINE',quantity:'5',reason:'Bao bì có dấu hiệu bất thường',evidence:''};
  let basis=null, decision=null, rejectOpen=false, rejectReason='', movement=null, seq=1;
  let staleOnExecute=false;

  const escText=(v)=>typeof esc==='function'?esc(String(v??'')):String(v??'');
  const num=(v)=>Number(String(v??'').replace(',','.'))||0;
  const current=()=>ic09Current();
  const actor=()=>window.__VET45_V350__?.getActor?.()||'module';
  const stateLabel=(v)=>({SELLABLE:'Bán được',QUARANTINE:'Cách ly',DAMAGED:'Hỏng',DEMO:'Dùng thử',EXPIRED:'Hết hạn'}[v]||v);
  const transition=()=>POLICY.transitions[current().state]?.[draft.destination]||null;
  function fixtureHash(payload){
    // Deterministic harness fixture only. Production contract requires canonical SHA-256.
    const s=JSON.stringify(payload);let h=2166136261;
    for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619);}return `fixture-${(h>>>0).toString(16).padStart(8,'0')}`;
  }
  function resolveSlices(item,qty){
    const src=SOURCE[item.id]?.slices||[]; let remaining=qty,out=[];
    // Fixture resolver uses stable source-lineage order. Production resolver is server-owned.
    for(const slice of src){if(remaining<=0)break;const take=Math.min(remaining,slice.qty);if(take>0){out.push({...slice,quantity:take});remaining-=take;}}
    if(remaining>0)return null;
    return out;
  }
  function eligibleQty(item,slices){
    if(item.state!=='SELLABLE')return 0;
    return (slices||SOURCE[item.id]?.slices||[]).filter(x=>x.valuationState==='VALUATION_CONFIRMED').reduce((a,x)=>a+(x.qty??x.quantity??0),0);
  }
  function basisValid(){
    const x=current(),t=transition(),q=num(draft.quantity);
    if(!t||q<=0||q>x.qty||!draft.reason.trim())return false;
    if(t.evidence && !draft.evidence.trim())return false;
    return Boolean(resolveSlices(x,q));
  }
  function buildBasis(){
    const x=current(),t=transition(),q=num(draft.quantity),slices=resolveSlices(x,q);
    if(!t||!slices)return null;
    const src=SOURCE[x.id]||{reservationBefore:0};
    const beforeEligible=eligibleQty(x);
    const confirmedMoved=slices.filter(z=>z.valuationState==='VALUATION_CONFIRMED').reduce((a,z)=>a+z.quantity,0);
    const destinationEligible=draft.destination==='SELLABLE';
    const afterEligible=Math.max(0,beforeEligible-(x.state==='SELLABLE'?confirmedMoved:0)+(destinationEligible?confirmedMoved:0));
    const reservationAfter=Math.min(src.reservationBefore||0,afterEligible);
    const payload={
      basisId:`SCB-1709-${String(seq++).padStart(3,'0')}`,itemId:x.id,product:x.name,lot:x.lot,from:x.state,to:draft.destination,
      quantity:q,uom:x.uom,sourceSlices:slices,policyVersionId:POLICY.versionId,policyHash:POLICY.fixtureHash,
      reason:draft.reason.trim(),evidence:draft.evidence.trim(),businessDate:BUSINESS_DATE,expiry:x.expiry,
      reservationImpact:{before:src.reservationBefore||0,after:reservationAfter,shortfall:Math.max(0,(src.reservationBefore||0)-reservationAfter),allocationReviewRequired:(src.reservationBefore||0)>reservationAfter}
    };
    payload.basisHash=fixtureHash(payload);
    return Object.freeze(payload);
  }
  function resetDraft(){
    draft={destination:current().state==='SELLABLE'?'QUARANTINE':'SELLABLE',quantity:String(Math.min(current().qty,5)),reason:'',evidence:''};
    basis=null;decision=null;rejectOpen=false;rejectReason='';movement=null;staleOnExecute=false;
  }
  function approvalRows(b){
    return icHeaderRows([
      ['Sản phẩm',b.product,true],['Lô',b.lot],['Từ',stateLabel(b.from)],['Sang',stateLabel(b.to)],['Số lượng',`${b.quantity} ${b.uom}`],['Lý do',b.reason||'—'],
      ...(b.evidence?[['Bằng chứng',b.evidence]]:[]),
      ['Tác động khả dụng',b.reservationImpact.shortfall>0?`Giảm; ${b.reservationImpact.shortfall} ${b.uom} cần phân bổ lại`:'Đã kiểm tra']
    ]);
  }
  function rejectSheet(){
    if(!rejectOpen)return '';
    return `<div class="sheet-backdrop ds24-overlay"><section class="ds24-confirmation" data-ds-component="VBottomSheet" role="dialog" aria-modal="true"><div class="ds24-confirmation__handle"></div><h3>Từ chối yêu cầu?</h3><p>Lý do được lưu cùng quyết định và không làm thay đổi tồn kho.</p>${icTextarea('Lý do từ chối',rejectReason,'data-v3101-reject-reason','Bắt buộc')}<div class="ds24-confirmation__actions"><button class="ds24-button ds24-button--secondary" data-v3101-action="reject-close">Quay lại</button><button class="ds24-button ds24-button--danger" data-v3101-action="reject-confirm" ${rejectReason.trim()?'':'disabled'}>Xác nhận từ chối</button></div></section></div>`;
  }
  function destinationChoices(){
    const x=current();return Object.entries(POLICY.transitions[x.state]||{}).map(([code,cfg])=>`<label class="v364-radio-option" data-ds-component="VRadio" data-ds-prop-state="${draft.destination===code?'On':'Off'}"><input type="radio" name="v3101-destination" value="${code}" data-v3101-destination ${draft.destination===code?'checked':''}><span class="v364-radio-control" aria-hidden="true"></span><span class="v364-radio-copy"><strong>${cfg.label}</strong><small>${cfg.approval?'Cần người duyệt độc lập':'Có thể xử lý ngay theo quy tắc hiện hành'}</small></span></label>`).join('');
  }
  function infoCurrent(x){
    const src=SOURCE[x.id];const available=x.state==='SELLABLE'?eligibleQty(x):0;
    return icHeaderRows([['Sản phẩm',x.name,true],['Mã',x.code],['Lô',x.lot],['Hạn dùng',x.expiry],['Tình trạng',stateLabel(x.state)],['Tồn vật lý',`${x.qty} ${x.uom}`],['Khả dụng bán',`${available} ${x.uom}`]]);
  }

  const base036=renderers['SCR-036'],base037=renderers['SCR-037'],base038=renderers['SCR-038'],base041=renderers['SCR-041'],base056=renderers['SCR-056'];
  renderers['SCR-036']=function(state){
    if(activeFlowId!=='UIF-09')return base036(state);
    if(['PERMISSION_DENIED','LOADING','EMPTY'].includes(state))return base036(state);
    const labels=[['ALL','Tất cả'],['SELLABLE','Bán được'],['QUARANTINE','Cách ly'],['DAMAGED','Hỏng'],['DEMO','Dùng thử'],['EXPIRED','Hết hạn']];
    const q=ic09Query.trim().toLowerCase();
    const items=ic09Items.filter(x=>(ic09Filter==='ALL'||x.state===ic09Filter)&&(!q||`${x.name} ${x.code} ${x.lot}`.toLowerCase().includes(q)));
    const rows=items.map(x=>ioProductRow({name:x.name,code:x.code,primary:`${x.qty} ${x.uom}`,secondary:`Lô ${x.lot}`,badge:stateLabel(x.state),badgeStatus:ic09StatusTone(x.state),attr:`data-ic09-item="${x.id}"`})).join('');
    return appShell({title:'Tình trạng hàng',body:`${ds24Search(ic09Query,'data-ic09-search','Tìm sản phẩm hoặc lô')}<div class="ac321-chip-wrap" data-composed-from="VChip">${labels.map(([k,l])=>ds24Chip(k,l,ic09Filter===k,'data-ic09-filter')).join('')}</div>${rows?`<div class="io-list-card" data-ds-component="VSection"><div class="io-product-list">${rows}</div></div>`:ioEmpty('Không có hàng phù hợp','Thử đổi bộ lọc hoặc từ khóa tìm kiếm.')}`,back:false});
  };
  renderers['SCR-037']=function(state){
    if(activeFlowId!=='UIF-09')return base037(state);
    if(['PERMISSION_DENIED','LOADING'].includes(state))return base037(state);
    const x=current(),expired=x.state==='EXPIRED'||state==='EXPIRED';
    const notice=expired?vBanner('warning','Lô đã hết hạn',`Hết hạn theo ngày nghiệp vụ ${BUSINESS_DATE}; hệ thống tự loại khỏi khả dụng.`):state==='LOCKED'?vBanner('info','Đang thuộc phạm vi kiểm kê','Thông tin chỉ đọc cho đến khi phạm vi được mở khóa.'):'';
    const body=`${notice}${infoCurrent(x)}${ioSectionTitle('Tác động')}<p class="io-footnote">Đổi tình trạng chỉ phân loại lại cùng lượng hàng. Tổng tồn vật lý và giá trị ghi sổ không đổi.</p>${icSecondary('Xem lịch sử','data-ic09-action="history"')}`;
    return appShell({title:'Chi tiết tình trạng hàng',body,actions:expired||state==='LOCKED'?'':primaryFooter('Thay đổi tình trạng','data-ic09-action="change"')});
  };
  renderers['SCR-038']=function(state){
    if(activeFlowId!=='UIF-09')return base038(state);
    const x=current();
    if(state==='PERMISSION_DENIED')return appShell({title:'Chuyển tình trạng hàng',body:deniedBody(),centered:true,back:false});
    if(state==='LOCKED')return appShell({title:'Chuyển tình trạng hàng',body:`${vBanner('info','Đang thuộc phạm vi kiểm kê','Không thể đổi tình trạng khi phạm vi đang khóa.')}${icHeaderRows([['Sản phẩm',x.name,true],['Lô',x.lot],['Tình trạng hiện tại',stateLabel(x.state)]])}`,back:false});
    if(state==='SELF_APPROVAL_NOT_ALLOWED')return appShell({title:'Duyệt thay đổi tình trạng',body:vBanner('warning','Không thể tự duyệt','Người lập yêu cầu không được tự duyệt yêu cầu này.'),back:false});
    if(state==='STATE_CHANGE_BASIS_STALE'||state==='CONFLICT')return appShell({title:'Yêu cầu đã thay đổi',body:`${vBanner('warning','Cần lập lại yêu cầu','Dữ liệu đã thay đổi; quyết định cũ không còn hiệu lực.')}${basis?approvalRows(basis):infoCurrent(x)}`,actions:primaryFooter('Lập lại yêu cầu','data-v3101-action="rebuild"'),back:false});
    if(state==='PENDING_APPROVAL'){
      const b=basis;return appShell({title:'Chuyển tình trạng hàng',body:`${vBanner('info','Đã gửi chờ duyệt','Tồn kho chưa thay đổi; người duyệt nhận công việc riêng.')}${b?approvalRows(b):infoCurrent(x)}`,back:false});
    }
    if(state==='APPROVAL_REVIEW'){
      if(!basis)return appShell({title:'Duyệt thay đổi tình trạng',body:vBanner('warning','Không còn căn cứ hiện hành','Mở lại công việc từ danh sách được giao để lấy đúng phiên bản yêu cầu.'),back:false});
      const body=`${vBanner('info','Phê duyệt không ghi tồn','Quyết định chỉ áp dụng cho đúng yêu cầu này. Hệ thống sẽ kiểm tra lại trước khi thực thi.')}${approvalRows(basis)}${rejectSheet()}`;
      return appShell({title:'Duyệt thay đổi tình trạng',body,actions:`<div class="ic-action-stack">${icSecondary('Từ chối','data-v3101-action="reject-open"','danger')}${primaryFooter('Duyệt','data-v3101-action="approve"')}</div>`,back:false});
    }
    const t=transition();
    const error=state==='VALIDATION_ERROR'?vBanner('error','Chưa đủ thông tin','Kiểm tra tình trạng đích, số lượng và thông tin bắt buộc theo quy tắc hiện hành.'):'';
    const policyNote=t?`<small class="helper-text">${t.approval?'Yêu cầu này sẽ được gửi người duyệt độc lập.':'Quy tắc hiện hành cho phép hệ thống xử lý sau khi gửi.'}</small>`:'';
    const evidence=t?.evidence?icTextarea('Bằng chứng',draft.evidence,'data-v3101-evidence','Nhập hoặc tham chiếu bằng chứng'):'';
    const body=`${error}${icHeaderRows([['Sản phẩm',x.name,true],['Lô',x.lot],['Từ',stateLabel(x.state)],['Tồn vật lý',`${x.qty} ${x.uom}`]])}${ioSectionTitle('Tình trạng mới')}<div class="choice-list">${destinationChoices()}</div>${policyNote}${icField('Số lượng chuyển',draft.quantity,'data-v3101-qty','number',`Tối đa ${x.qty} ${x.uom}. Hệ thống tự xác định đúng phần tồn được chuyển.`)}${icTextarea('Lý do',draft.reason,'data-v3101-reason','Nhập lý do')}${evidence}`;
    return appShell({title:'Chuyển tình trạng hàng',body,actions:primaryFooter('Gửi xử lý','data-v3101-action="submit"')});
  };
  renderers['SCR-041']=function(state){
    if(activeFlowId!=='UIF-09')return base041(state);
    const x=current();
    if(state==='PROCESSING')return appShell({title:'Kết quả thay đổi',body:`${vBanner('info','Đang kiểm tra và ghi nhận','Hệ thống đang kiểm tra lại đúng căn cứ đã gửi trước khi cập nhật tồn.')}${basis?approvalRows(basis):''}`,centered:false,back:false});
    if(state==='UNKNOWN')return appShell({title:'Kết quả thay đổi',body:ioResult('Đang xác minh kết quả','Không gửi yêu cầu mới. Hệ thống đang kiểm tra cùng lần xử lý này.',[['Sản phẩm',basis?.product||x.name],['Tình trạng','Chưa kết luận']],'warning'),actions:primaryFooter('Chuyển sang xác minh','data-v350-action="handoff-unknown" data-source-flow="UIF-09"'),centered:true,back:false});
    if(state==='STATE_CHANGE_BASIS_STALE'||state==='REJECTED_EXECUTION')return appShell({title:'Kết quả thay đổi',body:ioResult('Yêu cầu chưa được thực hiện','Tình trạng và tồn kho không thay đổi. Nếu căn cứ đã thay đổi, cần lập yêu cầu mới.',[['Sản phẩm',basis?.product||x.name],['Tác động tồn kho','Không có']],'warning'),actions:primaryFooter('Về tình trạng hàng','data-ic09-action="to-list"'),centered:true,back:false});
    if(state==='EXPIRED')return appShell({title:'Tình trạng hàng',body:ioResult('Lô đã hết hạn',`Theo ngày nghiệp vụ ${BUSINESS_DATE}, hệ thống đã loại lượng hàng này khỏi khả dụng bán.`,[['Tồn vật lý',`${x.qty} ${x.uom}`],['Khả dụng bán',`0 ${x.uom}`],['Tác động giá trị','Không đổi']],'warning'),actions:primaryFooter('Về tình trạng hàng','data-ic09-action="to-list"'),centered:true,back:false});
    if(state==='COMPLETED'&&movement){
      const r=movement.reservationImpact;const rows=[['Sản phẩm',movement.product],['Đã chuyển',`${movement.quantity} ${movement.uom} · ${stateLabel(movement.from)} → ${stateLabel(movement.to)}`],['Còn ở trạng thái nguồn',`${movement.remainingSource} ${movement.uom}`],['Tồn vật lý','Không đổi'],['Giá trị ghi sổ','Không đổi']];
      if(r.shortfall>0)rows.push(['Cần phân bổ lại',`${r.shortfall} ${movement.uom}`]);
      return appShell({title:'Kết quả thay đổi',body:ioResult('Đã cập nhật tình trạng','Hệ thống đã ghi chuyển trạng thái trên đúng phạm vi và kiểm tra lại khả dụng.',rows),actions:`<div class="ic-action-stack">${movement.id?icSecondary('Xem biến động','data-ic09-action="history"'):''}${primaryFooter('Về tình trạng hàng','data-ic09-action="to-list"')}</div>`,centered:true,back:false});
    }
    return base041(state);
  };
  renderers['SCR-056']=function(state){
    if(activeFlowId!=='UIF-09')return base056(state);
    if(!movement)return base056(state);
    const body=`${icHeaderRows([['Sản phẩm',movement.product,true],['Lô',movement.lot],['Biến động',`${stateLabel(movement.from)} → ${stateLabel(movement.to)}`],['Số lượng',`${movement.quantity} ${movement.uom}`],['Ghi nhận lúc',movement.recordedAt]])}<p class="io-footnote">Việc đổi tình trạng không làm thay đổi giá trị ghi sổ của lượng hàng này.</p>`;
    return appShell({title:'Chi tiết biến động',body});
  };

  function systemCommit(){
    if(!basis)return false;
    stateByScreen['SCR-041']='PROCESSING';
    if(staleOnExecute){stateByScreen['SCR-041']='STATE_CHANGE_BASIS_STALE';renderAppScreen();return false;}
    const x=ic09Items.find(z=>z.id===basis.itemId);
    if(!x||x.state!==basis.from||x.qty<basis.quantity||POLICY.versionId!==basis.policyVersionId){stateByScreen['SCR-041']='STATE_CHANGE_BASIS_STALE';renderAppScreen();return false;}
    const slices=resolveSlices(x,basis.quantity);
    const currentHash=fixtureHash({...basis,basisHash:undefined,sourceSlices:slices});
    // Basis hash is frozen in this harness; runtime rechecks semantic facts rather than reproducing canonical production serialization.
    if(!slices){stateByScreen['SCR-041']='STATE_CHANGE_BASIS_STALE';renderAppScreen();return false;}
    const originalQty=x.qty;
    if(basis.quantity===x.qty){x.state=basis.to;x.label=stateLabel(basis.to);}
    else{
      x.qty=Number((x.qty-basis.quantity).toFixed(6));
      const splitId=`${x.id}-state-${Date.now()}`;
      ic09Items.push({id:splitId,name:x.name,code:x.code,lot:x.lot,qty:basis.quantity,uom:x.uom,state:basis.to,label:stateLabel(basis.to),expiry:x.expiry});
      SOURCE[splitId]={slices:basis.sourceSlices.map(z=>({balanceId:`${z.balanceId}-to`,version:1,valuationState:z.valuationState,qty:z.quantity})),reservationBefore:0};
    }
    const src=SOURCE[basis.itemId];
    // Reduce source fixture slices in the same deterministic slice order; preserve valuation state.
    let rem=basis.quantity; for(const sl of src.slices){if(rem<=0)break;const take=Math.min(rem,sl.qty);sl.qty-=take;rem-=take;}
    src.reservationBefore=basis.reservationImpact.after;
    movement={id:`MOV-STATE-${String(seq++).padStart(3,'0')}`,product:basis.product,lot:basis.lot,from:basis.from,to:basis.to,quantity:basis.quantity,uom:basis.uom,remainingSource:originalQty-basis.quantity,sourceSlices:basis.sourceSlices.map(z=>({...z,valuationStateSnapshot:z.valuationState})),valuationPreserved:true,valueMovementCreated:false,reservationImpact:basis.reservationImpact,recordedAt:'17/09/2026 · 15:04'};
    stateByScreen['SCR-041']='COMPLETED';renderAppScreen();return true;
  }
  function queueSystemCommit(){setTimeout(()=>{if(activeFlowId==='UIF-09'&&activeScreenId==='SCR-041'&&stateByScreen['SCR-041']==='PROCESSING')systemCommit();},180);}

  document.addEventListener('input',function(e){
    if(activeFlowId!=='UIF-09')return;
    if(e.target.matches('[data-v3101-qty]')){draft.quantity=e.target.value;}
    if(e.target.matches('[data-v3101-reason]')){draft.reason=e.target.value;}
    if(e.target.matches('[data-v3101-evidence]')){draft.evidence=e.target.value;}
    if(e.target.matches('[data-v3101-reject-reason]')){rejectReason=e.target.value;renderAppScreen();}
  },true);
  document.addEventListener('change',function(e){
    if(activeFlowId!=='UIF-09')return;
    if(e.target.matches('[data-v3101-destination]')){draft.destination=e.target.value;renderAppScreen();}
  },true);
  document.addEventListener('click',function(e){
    if(activeFlowId!=='UIF-09')return;
    if(e.target.closest('[data-ic09-item]')||e.target.closest('[data-ic09-action="change"]')){queueMicrotask(resetDraft);}
    const a=e.target.closest('[data-v3101-action]');if(!a||a.disabled)return;
    e.preventDefault();e.stopImmediatePropagation();const k=a.dataset.v3101Action;
    if(k==='submit'){
      if(!basisValid()){stateByScreen['SCR-038']='VALIDATION_ERROR';return renderAppScreen();}
      basis=buildBasis();decision=null;const t=transition();
      if(t?.approval){stateByScreen['SCR-038']='PENDING_APPROVAL';return renderAppScreen();}
      stateByScreen['SCR-041']='PROCESSING';navigate('SCR-041');queueSystemCommit();return;
    }
    if(k==='approve'){
      if(actor()!=='approver'){stateByScreen['SCR-038']='SELF_APPROVAL_NOT_ALLOWED';return renderAppScreen();}
      if(!basis){stateByScreen['SCR-038']='STATE_CHANGE_BASIS_STALE';return renderAppScreen();}
      decision={decision:'APPROVE',basisHash:basis.basisHash,actor:'approver',decidedAt:'17/09/2026 15:04'};
      stateByScreen['SCR-041']='PROCESSING';navigate('SCR-041');queueSystemCommit();return;
    }
    if(k==='reject-open'){if(actor()!=='approver'){stateByScreen['SCR-038']='SELF_APPROVAL_NOT_ALLOWED';return renderAppScreen();}rejectReason='';rejectOpen=true;return renderAppScreen();}
    if(k==='reject-close'){rejectOpen=false;rejectReason='';return renderAppScreen();}
    if(k==='reject-confirm'){
      if(actor()!=='approver'||!rejectReason.trim())return;
      decision={decision:'REJECT',basisHash:basis?.basisHash||null,reason:rejectReason.trim(),actor:'approver',decidedAt:'17/09/2026 15:04'};rejectOpen=false;
      stateByScreen['SCR-041']='REJECTED_EXECUTION';navigate('SCR-041');return;
    }
    if(k==='rebuild'){resetDraft();stateByScreen['SCR-038']='READY';return renderAppScreen();}
  },true);

  window.__VET45_V3101__={
    version:VERSION,decisions:[178,179,180,181,182,183,184],policy:POLICY,
    getDraft:()=>({...draft}),getBasis:()=>basis,getDecision:()=>decision,getMovement:()=>movement,
    getSource:(id)=>JSON.parse(JSON.stringify(SOURCE[id||current().id]||null)),
    setDraft(v={}){draft={...draft,...v};return {...draft};},
    setStaleOnExecute(v=true){staleOnExecute=Boolean(v);return staleOnExecute;},
    buildBasis(){basis=buildBasis();return basis;},systemCommit,
    fixtureHashNote:'Deterministic harness fixture hash only; production contract requires canonical SHA-256.'
  };
  if(window.__VET45_PROTOTYPE__)window.__VET45_PROTOTYPE__.version=VERSION;
  renderAppScreen();
})();
