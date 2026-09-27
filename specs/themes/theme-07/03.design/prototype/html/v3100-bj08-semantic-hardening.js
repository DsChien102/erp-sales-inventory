(function(){
  const baseRender042V3100=renderers['SCR-042'];
  const BOOK={amox:20,glove:6};
  const META={
    amox:{name:'Amox 500',code:'SP-00128',lot:'L2407-A',uom:'hộp',state:'Bán được'},
    glove:{name:'Găng tay M',code:'SP-00410',lot:'L2405-M',uom:'hộp',state:'Cách ly'}
  };
  let roundNo=1;
  let roundHistory=[];
  let resultSnapshot=null;
  let dialogKind=null;
  let approvalCaseNo=1;
  let contributorNames=['Nguyễn An'];

  const num=(v)=>Number(String(v||'0').replace(',','.'))||0;
  const signed=(n)=>`${n>0?'+':''}${n}`;
  const allZero=(vals)=>Object.keys(BOOK).every(k=>num(vals[k])===BOOK[k]) && (!ic08UnexpectedLine || num(ic08UnexpectedLine.value)===0);
  const currentVariance=(vals)=>Object.keys(BOOK).map(k=>({id:k,...META[k],book:BOOK[k],count:num(vals[k]),variance:num(vals[k])-BOOK[k]})).filter(x=>x.variance!==0);
  const info=(rows)=>ic08ContextRows(rows);
  const lineHead=(m,badge='')=>ds24ListRow({title:m.name,subtitle:`${m.code} · Lô ${m.lot} · ${m.state} · ${m.uom}`,trailing:badge?ds24Badge(badge,'Info'):'',leading:'package',type:'Status',density:'Compact',interactive:false});
  function blindRow(id){ const m=META[id]; return `<section class="ac321-product-input-group" data-theme-component="Theme7StockCountLine" data-physical-count-key="${id}">${lineHead(m)}<div class="ac321-product-field">${ic08QuantityTrigger('Số lượng thực tế',ic08Counts[id],`count:${id}`,m.uom,false)}</div></section>`; }
  function recountRow(id){ const m=META[id], book=BOOK[id], first=num(ic08Counts[id]), value=ic08Recounts[id], variance=first-book; return `<section class="ac321-product-input-group" data-theme-component="Theme7StockRecountLine" data-physical-count-key="${id}">${lineHead(m)}<div class="ac321-product-facts">${ds24KeyValueRow('Theo sổ',`${book} ${m.uom}`)}${ds24KeyValueRow('Lần đếm đầu',`${first} ${m.uom}`)}${ds24KeyValueRow('Chênh lệch',`${signed(variance)} ${m.uom}`)}</div><div class="ac321-product-field">${ic08QuantityTrigger('Số lượng đếm lại',value,`recount:${id}`,m.uom,false)}</div></section>`; }
  function unexpectedBlock(blind=true){
    if(!ic08UnexpectedLine) return '';
    const st=ic08UnexpectedLine.stockState||'';
    const select=`<label class="ds24-field" data-ds-component="VSelect"><span class="vet45-text-style-8">Trạng thái hàng</span><select class="ds24-field__control" data-v3100-stock-state><option value="">Chọn trạng thái</option><option value="SELLABLE" ${st==='SELLABLE'?'selected':''}>Bán được</option><option value="QUARANTINE" ${st==='QUARANTINE'?'selected':''}>Cách ly</option><option value="DAMAGED" ${st==='DAMAGED'?'selected':''}>Hỏng</option></select></label>`;
    const m={name:ic08UnexpectedLine.name,code:'Sản phẩm hiện có',lot:ic08UnexpectedLine.lot,uom:ic08UnexpectedLine.uom,state:st?({SELLABLE:'Bán được',QUARANTINE:'Cách ly',DAMAGED:'Hỏng'}[st]||st):'Chưa xác định trạng thái'};
    return `<section class="ac321-product-input-group" data-theme-component="Theme7UnexpectedPhysicalKey">${lineHead(m,'Hàng thực tế')}${select}<div class="ac321-product-field">${ic08QuantityTrigger('Số lượng thực tế',ic08UnexpectedLine.value,'count:unexpected',m.uom,false)}</div><small class="vet45-text-style-11">Giá trị hàng thừa do nguồn có thẩm quyền cung cấp; người đếm không nhập giá.</small></section>`;
  }
  function footer(primaryLabel,primaryAction,secondary=true){ return `<footer class="app-actions figma-sticky-footer ds24-footer-stack" data-ds-pattern="Sticky Footer"><button class="ds24-button ds24-button--primary" type="button" data-v3100-ic08-action="${primaryAction}" data-ds-component="VButton">${primaryLabel}</button>${secondary?`<button class="ds24-button ds24-button--secondary" type="button" data-v3100-ic08-action="cancel-open" data-action-contract="ACT-09-CANCEL" data-ds-component="VButton">Hủy phiên</button>`:''}</footer>`; }
  function confirmSheet(){
    if(!dialogKind)return '';
    const cfg={open:['Mở phiên kiểm kê?','Hệ thống khóa phạm vi trước khi chốt số sổ và mở phiên.','Mở phiên',false],first:['Nộp lần đếm đầu?','Sau khi nộp, số sổ và chênh lệch mới được hiển thị.','Nộp kết quả',false],recount:['Gửi kết quả đếm lại?','Kết quả được lưu thành một vòng đếm lại bất biến.','Gửi kết quả',false],approve:['Duyệt và điều chỉnh?','Hệ thống kiểm tra lại căn cứ giá, quyền và khóa trước khi ghi điều chỉnh.','Duyệt và điều chỉnh',false],review:['Yêu cầu đếm lại?','Vòng đếm hiện tại được giữ nguyên. Một vòng đếm lại mới sẽ được mở.','Yêu cầu đếm lại',true],cancel:['Hủy phiên kiểm kê?','Không tạo điều chỉnh; toàn bộ lịch sử đếm được giữ và phạm vi được mở khóa.','Hủy phiên',true]}[dialogKind];
    if(!cfg)return '';
    const [title,desc,label,reason]=cfg; const val=dialogKind==='cancel'?ic08CancelReason:ic08ReviewReason;
    const reasonHtml=reason?ds24TextField('Lý do',val,dialogKind==='cancel'?'data-v3100-cancel-reason':'data-v3100-review-reason','Bắt buộc để lưu lịch sử quyết định.'):'';
    return `<div class="sheet-backdrop ds24-overlay"><section class="ds24-confirmation" data-ds-component="DS v2 / Confirmation Sheet" role="dialog" aria-modal="true"><div class="ds24-confirmation__handle"></div><h3 class="vet45-text-style-4">${title}</h3><p class="vet45-text-style-6">${desc}</p>${reasonHtml}<div class="ds24-confirmation__actions"><button class="ds24-button ds24-button--secondary" data-v3100-ic08-action="dialog-close">Quay lại</button><button class="ds24-button ${dialogKind==='cancel'?'ds24-button--danger':'ds24-button--primary'}" data-v3100-ic08-action="confirm-${dialogKind}" ${reason&&!val.trim()?'disabled':''}>${label}</button></div></section></div>`;
  }
  function overlays(){ return `${ic08NumericSheet()}${ic08SelectSheet()}${confirmSheet()}`; }

  render042IC08=function(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-042'),state);
    // Preserve the previously approved interactive list/search/filter surface.
    // v3.10.0 changes stock-count semantics, not browse-list information architecture.
    const html=baseRender042V3100(state);
    return String(html).replace(/data-ic08-action=\"create\"/g,'data-v3100-ic08-action=\"new\"').replace(/data-ic08-action=\"resume\"/g,'data-v3100-ic08-action=\"resume-count\"');
  };

  render043IC08=function(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-043'),state);
    if(state==='COUNT_SCOPE_HAS_UNRESOLVED_VALUATION') return appShell({title:'Tạo phiên kiểm kê',body:`${vBanner('warning','Chưa thể mở phiên','Phạm vi còn hàng chờ xác nhận giá trị. Hoàn tất phần giá trị hàng nhận trước khi kiểm kê.')}${info([['Kho','Kho trung tâm'],['Người đếm',ic08AssignedCounter]])}`,actions:primaryFooter('Về kiểm kê','data-v3100-ic08-action="to-list"')});
    const scopeOptions=[['ALL','Toàn kho'],['PRODUCT','Sản phẩm'],['GROUP','Nhóm sản phẩm'],['LOT','Lô']];
    const target=ic08Scope==='ALL'?'':`<button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="scope-select-open">${ic08ScopeTarget||'Chọn phạm vi cụ thể'}</button>`;
    const body=`${info([['Kho','Kho trung tâm'],['Thời điểm chốt','Khi mở phiên'],['Người đếm',ic08AssignedCounter]])}${ds24SelectField('Phạm vi',ic08Scope,scopeOptions,'data-ic08-scope')}${target}${ds24TextField('Lý do kiểm kê',ic08Reason,'data-ic08-reason')}${vBanner('info','Phạm vi được khóa khi mở phiên','Hệ thống chốt số sổ sau khi phạm vi đã được khóa. Nhóm sản phẩm được cố định theo thành viên tại thời điểm mở.')}${overlays()}`;
    return appShell({title:'Tạo phiên kiểm kê',body,actions:primaryFooter('Mở phiên kiểm kê','data-v3100-ic08-action="open"')});
  };

  render044IC08=function(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-044'),state);
    const validation=state==='VALIDATION_ERROR'?vBanner('error','Chưa đủ kết quả đếm','Nhập số lượng thực tế cho tất cả dòng trước khi nộp.'):'';
    const body=`${validation}${vBanner('info','Đếm mù','Số lượng theo sổ chỉ xuất hiện sau khi nộp lần đếm đầu.')}${info([['Phiên','KK-1709-01'],['Kho','Kho trung tâm'],['Người đếm',ic08AssignedCounter]])}${ic08Section('Hàng trong phạm vi',blindRow('amox')+blindRow('glove'))}${unexpectedBlock(true)}<button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="add-actual-open">Thêm hàng thực tế</button>${overlays()}`;
    return appShell({title:'Đếm mù',body,actions:footer('Nộp kết quả đếm','submit-first',true)});
  };

  render045IC08=function(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-045'),state);
    const diffs=currentVariance(ic08Counts);
    const ids=diffs.map(x=>x.id);
    const rows=ids.map(recountRow).join('');
    const basisBlocked=state==='PRICE_BASIS_REQUIRED';
    const basis=basisBlocked?vBanner('warning','Thiếu căn cứ giá hàng thừa','Phiên vẫn được khóa. Căn cứ giá phải đến từ nguồn có thẩm quyền; người đếm không nhập giá.'):info([['Căn cứ giá hàng thừa',ids.includes('glove')?'Đã xác nhận':'Không phát sinh'],['Khóa phạm vi','Đang giữ']]);
    const validation=state==='VALIDATION_ERROR'?vBanner('error','Kết quả đếm lại chưa hợp lệ','Nhập số lượng đếm lại cho tất cả dòng chênh lệch.'):'';
    const body=`${validation}${vBanner('warning',`Đếm lại lần ${roundNo}`,`${ids.length} dòng còn chênh lệch. Kết quả vòng trước được giữ nguyên trong lịch sử.`)}${ic08Section('Dòng cần đếm lại',rows||'<p class="vet45-text-style-7">Không còn dòng chênh lệch.</p>')}${basis}${overlays()}`;
    return appShell({title:'Chênh lệch và đếm lại',body,actions:footer('Gửi kết quả đếm lại','submit-recount',true)});
  };

  render046IC08=function(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-046'),state);
    if(state==='PERMISSION_DENIED')return appShell({title:'Duyệt kết quả kiểm kê',body:deniedBody(),centered:true,back:false});
    if(state==='COUNT_APPROVAL_SNAPSHOT_STALE')return appShell({title:'Duyệt kết quả kiểm kê',body:`${vBanner('warning','Kết quả cần được lập lại','Căn cứ giá hoặc dữ liệu kiểm kê đã thay đổi. Không thể điều chỉnh theo lần duyệt cũ.')}${info([['Phiên','KK-1709-01'],['Tác động','Chưa ghi điều chỉnh']])}`,back:false});
    if(state==='SELF_APPROVAL_NOT_ALLOWED')return appShell({title:'Duyệt kết quả kiểm kê',body:vBanner('warning','Không thể tự duyệt','Bạn đã tham gia kiểm đếm của kết quả này. Công việc cần người duyệt độc lập.'),back:false});
    if(state==='APPROVAL_ALREADY_DECIDED')return appShell({title:'Duyệt kết quả kiểm kê',body:vBanner('info','Công việc đã có quyết định','Mở kết quả phiên để xem trạng thái hiện hành.'),actions:primaryFooter('Xem kết quả','data-v3100-ic08-action="approval-result"'),back:false});
    const vals={amox:String(ic08Recounts.amox??'').trim()!==''?ic08Recounts.amox:(String(ic08Counts.amox??'').trim()!==''?ic08Counts.amox:'18'),glove:String(ic08Recounts.glove??'').trim()!==''?ic08Recounts.glove:(String(ic08Counts.glove??'').trim()!==''?ic08Counts.glove:'7')};
    const diffs=Object.keys(BOOK).map(k=>({id:k,...META[k],book:BOOK[k],count:num(vals[k]),variance:num(vals[k])-BOOK[k]})).filter(x=>x.variance!==0);
    const lines=diffs.map(x=>ic08Section(`${x.name} · ${x.lot}`,info([['Trạng thái',x.state],['Theo sổ',`${x.book} ${x.uom}`],['Đếm lại',`${x.count} ${x.uom}`],['Chênh lệch',`${signed(x.variance)} ${x.uom}`],...(x.variance>0?[['Căn cứ giá hàng thừa','Đã xác nhận']]:[['Căn cứ giá thiếu','Giá vốn đã khóa']])]))).join('');
    const body=`${vBanner('info','Cần quyết định độc lập','Bạn chỉ rà soát kết quả và quyết định; không sửa số đếm.')}${info([['Phiên','KK-1709-01'],['Lần đếm lại',String(roundNo)],['Người đã tham gia đếm',contributorNames.join(', ')],['Mức duyệt','Đã xác định theo rủi ro hiện hành']])}${lines}${overlays()}`;
    const actions=`<footer class="app-actions figma-sticky-footer ds24-footer-stack"><button class="ds24-button ds24-button--primary" data-v3100-ic08-action="approve">Duyệt và điều chỉnh</button><button class="ds24-button ds24-button--secondary" data-v3100-ic08-action="request-review">Yêu cầu xem lại</button></footer>`;
    return appShell({title:'Duyệt kết quả kiểm kê',body,actions,back:false});
  };

  render047IC08=function(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-047'),state);
    const snap=resultSnapshot;
    if(state==='UNKNOWN')return appShell({title:'Kết quả kiểm kê',body:ds24Result('Đang xác minh kết quả','Không gửi lại thao tác. Hệ thống cần xác minh đúng lần xử lý này.',[['Phiên','KK-1709-01'],['Định danh xử lý','Giữ nguyên'],['Tồn kho','Chưa kết luận']],'warning'),actions:primaryFooter('Chuyển sang xác minh','data-v350-action="handoff-unknown" data-source-flow="UIF-08" data-operation="KK-1709-01" data-scope="Kho trung tâm · Kiểm kê"'),centered:true,back:false});
    if(state==='CANCELLED'||snap?.type==='CANCELLED')return appShell({title:'Kết quả kiểm kê',body:ds24Result('Đã hủy phiên','Không tạo điều chỉnh. Lịch sử đếm được giữ và phạm vi đã mở khóa.',[['Phiên','KK-1709-01'],['Điều chỉnh','Không tạo'],['Khóa phạm vi','Đã mở'],['Thời điểm','17/09/2026 09:52']],'warning'),actions:primaryFooter('Về kiểm kê','data-v3100-ic08-action="to-list"'),centered:true,back:false});
    if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả kiểm kê',body:ds24Result('Chưa thực hiện điều chỉnh','Điều kiện nghiệp vụ không đạt; không có tác động tồn kho.',[['Phiên','KK-1709-01'],['Tác động','Không ghi nhận']],'warning'),actions:primaryFooter('Về kiểm kê','data-v3100-ic08-action="to-list"'),centered:true,back:false});
    if(snap?.type==='ZERO')return appShell({title:'Kết quả kiểm kê',body:ds24Result('Đã hoàn tất kiểm kê','Kết quả thực tế khớp số sổ. Không cần tạo điều chỉnh và phạm vi đã mở khóa.',[['Phiên','KK-1709-01'],['Điều chỉnh','Không tạo'],['Khóa phạm vi','Đã mở'],['Hoàn tất lúc',snap.committedAt]]),actions:primaryFooter('Về kiểm kê','data-v3100-ic08-action="to-list"'),centered:true,back:false});
    return appShell({title:'Kết quả kiểm kê',body:ds24Result('Đã hoàn tất kiểm kê','Điều chỉnh chênh lệch đã được ghi và phạm vi đã mở khóa.',[['Phiên','KK-1709-01'],['Điều chỉnh',snap?.adjustmentId||'ADJ-1709-08'],['Đã điều chỉnh',`${snap?.lines||2} dòng`],['Khóa phạm vi','Đã mở'],['Ghi nhận lúc',snap?.committedAt||'17/09/2026 09:52']]),actions:primaryFooter('Về kiểm kê','data-v3100-ic08-action="to-list"'),centered:true,back:false});
  };

  renderers['SCR-042']=render042IC08; renderers['SCR-043']=render043IC08; renderers['SCR-044']=render044IC08; renderers['SCR-045']=render045IC08; renderers['SCR-046']=render046IC08; renderers['SCR-047']=render047IC08;

  function rerender(){ if(typeof renderAppScreen==='function')renderAppScreen(); }
  document.addEventListener('input',function(e){
    if(e.target.matches('[data-v3100-cancel-reason]')){ic08CancelReason=e.target.value;rerender();}
    if(e.target.matches('[data-v3100-review-reason]')){ic08ReviewReason=e.target.value;rerender();}
  },true);
  document.addEventListener('change',function(e){ if(e.target.matches('[data-v3100-stock-state]')&&ic08UnexpectedLine){ic08UnexpectedLine.stockState=e.target.value;rerender();}},true);
  document.addEventListener('click',function(e){
    const a=e.target.closest('[data-v3100-ic08-action]'); if(!a||a.disabled)return;
    e.preventDefault();e.stopImmediatePropagation(); const k=a.dataset.v3100Ic08Action;
    if(k==='new'){roundNo=1;roundHistory=[];resultSnapshot=null;dialogKind=null;approvalCaseNo=1;contributorNames=[ic08AssignedCounter];ic08Counts={amox:'',glove:''};ic08Recounts={amox:'',glove:''};ic08UnexpectedLine=null;ic08CancelReason='';ic08ReviewReason='';stateByScreen['SCR-043']='READY';return navigate('SCR-043');}
    if(k==='resume-count'){return navigate('SCR-044');}
    if(k==='to-list'){resultSnapshot=null;return navigate('SCR-042');}
    if(k==='open'){dialogKind='open';return rerender();}
    if(k==='confirm-open'){dialogKind=null;stateByScreen['SCR-044']='BLIND_COUNT';return navigate('SCR-044');}
    if(k==='submit-first'){dialogKind='first';return rerender();}
    if(k==='confirm-first'){
      dialogKind=null;
      const missing=Object.keys(BOOK).some(id=>String(ic08Counts[id]??'').trim()===''||!Number.isFinite(Number(ic08Counts[id]))||Number(ic08Counts[id])<0);
      if(missing||(ic08UnexpectedLine&&num(ic08UnexpectedLine.value)>0&&!ic08UnexpectedLine.stockState)){stateByScreen['SCR-044']='VALIDATION_ERROR';return rerender();}
      roundHistory.push({round:1,type:'FIRST',actor:ic08AssignedCounter,values:{...ic08Counts},hash:'cnt-first-v3100'});
      if(allZero(ic08Counts)){resultSnapshot={type:'ZERO',committedAt:'17/09/2026 09:50'};stateByScreen['SCR-047']='COMPLETED';return navigate('SCR-047');}
      roundNo=1;stateByScreen['SCR-045']='RECOUNT_REQUIRED';return navigate('SCR-045');
    }
    if(k==='submit-recount'){dialogKind='recount';return rerender();}
    if(k==='confirm-recount'){
      dialogKind=null;
      const ids=currentVariance(ic08Counts).map(x=>x.id);
      const missing=ids.some(id=>String(ic08Recounts[id]??'').trim()===''||!Number.isFinite(Number(ic08Recounts[id]))||Number(ic08Recounts[id])<0);
      if(missing){stateByScreen['SCR-045']='VALIDATION_ERROR';return rerender();}
      if(stateByScreen['SCR-045']==='PRICE_BASIS_REQUIRED'){return rerender();}
      roundHistory.push({round:roundNo+1,type:'RECOUNT',actor:ic08AssignedCounter,values:{...ic08Recounts},hash:`cnt-recount-${roundNo+1}-v3100`});
      if(allZero(ic08Recounts)){resultSnapshot={type:'ZERO',committedAt:'17/09/2026 09:51'};stateByScreen['SCR-047']='COMPLETED';return navigate('SCR-047');}
      stateByScreen['SCR-042']='PENDING_APPROVAL';approvalCaseNo+=1;return navigate('SCR-042');
    }
    if(k==='cancel-open'){ic08CancelReason='';dialogKind='cancel';return rerender();}
    if(k==='confirm-cancel'){if(!ic08CancelReason.trim())return;dialogKind=null;resultSnapshot={type:'CANCELLED',reason:ic08CancelReason};stateByScreen['SCR-047']='CANCELLED';return navigate('SCR-047');}
    if(k==='approve'){if(window.__VET45_V350__?.getActor?.()!=='approver'){stateByScreen['SCR-046']='SELF_APPROVAL_NOT_ALLOWED';return rerender();}dialogKind='approve';return rerender();}
    if(k==='confirm-approve'){if(window.__VET45_V350__?.getActor?.()!=='approver'){dialogKind=null;stateByScreen['SCR-046']='SELF_APPROVAL_NOT_ALLOWED';return rerender();}dialogKind=null;resultSnapshot={type:'ADJUSTED',adjustmentId:'ADJ-1709-08',lines:currentVariance(ic08Recounts).length,committedAt:'17/09/2026 09:52'};stateByScreen['SCR-047']='COMPLETED';return navigate('SCR-047');}
    if(k==='request-review'){if(window.__VET45_V350__?.getActor?.()!=='approver'){stateByScreen['SCR-046']='SELF_APPROVAL_NOT_ALLOWED';return rerender();}ic08ReviewReason='';dialogKind='review';return rerender();}
    if(k==='confirm-review'){if(!ic08ReviewReason.trim())return;dialogKind=null;roundNo+=1;stateByScreen['SCR-045']='RECOUNT_REQUIRED';return navigate('SCR-045');}
    if(k==='dialog-close'){dialogKind=null;return rerender();}
    if(k==='approval-result'){stateByScreen['SCR-047']='COMPLETED';return navigate('SCR-047');}
  },true);

  window.__VET45_V3100__={version:'3.10.0',decisions:[171,172,173,174,175,176,177],getRoundHistory:()=>roundHistory.slice(),getResult:()=>resultSnapshot};
})();
