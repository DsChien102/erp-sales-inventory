/* VET45 Theme 7 v3.9.3 — BJ05 semantic hardening
 * Parent: v3.9.2
 * Keeps integrated Warehouse Home consistent with BJ05 UNKNOWN finality.
 */
(()=>{
  const v393Attr=(value)=>String(value??'').replace(/&/g,'&amp;').replace(/\"/g,'&quot;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
  const previousRender=renderAppScreen;
  const previous029=renderers['SCR-029'];
  renderers['SCR-029']=function(state){
    if(activeFlowId==='UIF-05'&&['UNKNOWN','COMMIT_UNKNOWN'].includes(state)){
      const o=io05CurrentOrder();io05MarkUnknown(o);o.unknownLocked=true;
      const operation=o.operationId||o.id;
      const scope=`${o.customer} · ${o.warehouse}`;
      const body=ioResult('Kết quả chưa xác định','Không gửi lại bàn giao. Giữ nguyên đúng lần xử lý này và chuyển sang xác minh trước khi cho phép lấy/bàn giao lại.',[['Nghiệp vụ',operation],['Phạm vi',scope],['Trạng thái','Đang xác minh bàn giao']],'warning');
      const attrs=`data-v350-action=\"handoff-unknown\" data-source-flow=\"UIF-05\" data-operation=\"${v393Attr(operation)}\" data-scope=\"${v393Attr(scope)}\"`;
      return appShell({title:'Xác minh kết quả',body,actions:primaryFooter('Chuyển sang xác minh',attrs),centered:true,back:false});
    }
    return previous029(state);
  };
  // v3.5.0 hid UNKNOWN rows completely; v3.9.3 supersedes that with a visible, disabled verification state.
  if(typeof io05VisibleOrders==='function') io05VisibleOrders=function(){return io05Orders.filter(o=>!o.closed);};
  function pickOrder(){return typeof io05Orders!=='undefined'?io05Orders.find(o=>o.id==='SO-260827-21'):null;}
  function patchIntegratedPickingTask(){
    const order=pickOrder();
    if(!order||order.queue!=='VERIFYING')return;
    const row=document.querySelector('[data-t390-task-id="PICK-SO26082721"]');
    if(!row)return;
    row.setAttribute('aria-disabled','true');
    row.setAttribute('data-ds-prop-state','Disabled');
    row.classList.add('is-disabled','v393-verifying-task');
    row.removeAttribute('data-theme-entry-flow');
    row.removeAttribute('data-t380-target-screen');
    row.removeAttribute('data-t380-context');
    const badge=row.querySelector('.ds24-badge'); if(badge){badge.textContent='Đang xác minh bàn giao';badge.setAttribute('data-ds-prop-tone','Warning');}
    const helper=row.querySelector('.ds24-list-row__copy small');if(helper&&!helper.textContent.includes('Đang xác minh'))helper.textContent=`${helper.textContent} · Đang xác minh kết quả trước`;
  }
  renderAppScreen=function(){const out=previousRender.apply(this,arguments);queueMicrotask(patchIntegratedPickingTask);return out;};
  document.addEventListener('click',(event)=>{
    const row=event.target.closest('[data-t390-task-id="PICK-SO26082721"]');
    if(row&&pickOrder()?.queue==='VERIFYING'){event.preventDefault();event.stopImmediatePropagation();}
  },true);
})();
