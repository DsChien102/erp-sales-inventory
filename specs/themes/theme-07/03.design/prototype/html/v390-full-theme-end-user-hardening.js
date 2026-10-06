/* VET45 Theme 7 v3.9.0 — Full Theme end-user hardening
 * Parent: v3.8.3
 * Scope: orchestration across all Theme 7 journeys without changing BJ business decomposition.
 * - Work Queue is projected by persona and session state, not a fixed five-item catalog.
 * - Work items deep-link to the exact business object/case.
 * - Manual state-change/disposal starts from an object-selection list.
 * - Integrated results/handoffs return to their entry context and resolve the originating work item.
 * - Catalog is permission/persona-aware and searchable; exhaustive BJ review remains in the BJ/UIF tab.
 * - Submitted approval handoffs are locked from editing/backtracking.
 */
(()=>{
  const VERSION='3.9.0';
  const currentRenderAppScreen=renderAppScreen;
  const currentRenderInspector=renderInspector;
  let persona=(new URLSearchParams(location.search).get('persona')||'operator').toLowerCase();
  if(!['operator','controller','manager'].includes(persona))persona='operator';
  let currentOrigin=null; // task | manual | catalog | utility
  let currentTaskId=null;
  const resolvedTasks=new Set();
  const startedTasks=new Set();

  const PERSONAS={
    operator:{label:'Nhân viên kho',allowed:['UIF-01','UIF-02','UIF-05','UIF-06','UIF-07','UIF-08','UIF-09','UIF-10','UIF-15']},
    controller:{label:'Kiểm soát kho',allowed:['UIF-01','UIF-03','UIF-08','UIF-09','UIF-10','UIF-11','UIF-13','UIF-15','UIF-16','UIF-17']},
    manager:{label:'Quản lý kho',allowed:['UIF-01','UIF-02','UIF-03','UIF-05','UIF-06','UIF-07','UIF-08','UIF-09','UIF-10','UIF-11','UIF-12','UIF-13','UIF-14','UIF-15','UIF-16','UIF-17','CAP-01']}
  };

  const TASKS={
    operator:[
      {id:'RCV-PN26081604',flow:'UIF-02',screen:'SCR-009',title:'PN-260816-04',subtitle:'Minh Dũng · 2 dòng hàng',badge:'Cần nhận',tone:'Success',icon:'cloudUpload',context:'receipt-document'},
      {id:'PICK-SO26082721',flow:'UIF-05',screen:'SCR-026',title:'SO-260827-21',subtitle:'Đại lý An Phú · 2 sản phẩm',badge:'Đang lấy',tone:'Info',icon:'package',context:'picking'},
      {id:'COUNT-KK070903',flow:'UIF-08',screen:'SCR-044',title:'KK-0709-03',subtitle:'Kho trung tâm · 12/38 đã đếm',badge:'Đang đếm',tone:'Info',icon:'listCheck',context:'count'}
    ],
    controller:[
      {id:'VAL-PN26090103',flow:'UIF-03',screen:'SCR-015',title:'PN-260901-03',subtitle:'Phương Nam · 1 dòng hàng',badge:'Xác nhận giá',tone:'Warning',icon:'checkCircle',context:'valuation-r3'},
      {id:'REC-AMOX-L2407A',flow:'UIF-16',screen:'SCR-079',title:'Amox 500 · L2407-A',subtitle:'Hồ sơ REC-260907-04',badge:'Cần kiểm tra',tone:'Warning',icon:'search',context:'reconcile-amox'}
    ],
    manager:[
      {id:'APP-RCV-PN26081604',flow:'UIF-02',screen:'SCR-011',title:'PN-260816-04',subtitle:'Nhận hàng vượt chứng từ',badge:'Chờ duyệt',tone:'Warning',icon:'shield',context:'approve-receipt'},
      {id:'APP-COUNT-KK070903',flow:'UIF-08',screen:'SCR-046',title:'KK-0709-03',subtitle:'2 dòng chênh lệch',badge:'Chờ duyệt',tone:'Warning',icon:'listCheck',context:'approve-count'},
      {id:'APP-OPENING-0831',flow:'UIF-12',screen:'SCR-070',title:'Tồn đầu kỳ · 31/08/2026',subtitle:'36 sản phẩm',badge:'Chờ duyệt',tone:'Warning',icon:'inbox',context:'approve-opening'}
    ]
  };

  function params(){return new URLSearchParams(location.search);}
  function isThemeInventory(){const q=params();return document.body.dataset.workbenchMode==='theme'&&q.get('app')==='inventory';}
  function isThemeFlow(){const q=params();return document.body.dataset.workbenchMode==='theme'&&q.get('app')==='flow';}
  function taskList(){
    const base=[...(TASKS[persona]||[])];
    // A completed receipt can generate downstream valuation work for a controller.
    if(persona==='controller'&&resolvedTasks.has('RCV-PN26081604'))base.unshift({id:'VAL-PN26081604',flow:'UIF-03',screen:'SCR-015',title:'PN-260816-04',subtitle:'Minh Dũng · hàng đã nhận',badge:'Xác nhận giá',tone:'Warning',icon:'checkCircle',context:'valuation-r1'});
    return base.filter(t=>!resolvedTasks.has(t.id));
  }
  function taskRow(t){
    const started=startedTasks.has(t.id);
    return ds24ListRow({
      title:t.title,
      subtitle:t.subtitle,
      leading:t.icon,
      trailing:ds24Badge(started&&t.badge==='Cần nhận'?'Đang làm':t.badge,started&&t.badge==='Cần nhận'?'Info':t.tone),
      attrs:`data-theme-entry-flow="${t.flow}" data-t380-target-screen="${t.screen}" data-t380-context="${t.context}" data-t390-task-id="${t.id}"`,
      theme:'Theme7WarehouseWorkItem',extraClass:'t380-work-item t390-work-item'
    });
  }

  function rebuildWorkQueue(){
    if(!isThemeInventory())return;
    const home=document.querySelector('#app-screen .t380-warehouse-home');
    const work=home?.querySelector('.t380-work-section');
    if(!work)return;
    const tasks=taskList();
    const heading=`<div class="t380-section-title t390-work-heading"><h2 data-ds-component="VText" data-ds-prop-style="Label/Default">Việc của bạn</h2><span data-ds-component="VText" data-ds-prop-style="Caption">${tasks.length} việc</span></div>`;
    const rows=tasks.length?`<div class="ds24-list-stack t380-work-list">${tasks.map(taskRow).join('')}</div>`:`<div class="t390-no-work" data-ds-component="VEmptyState"><strong>Không có việc cần xử lý</strong><span>Công việc mới sẽ xuất hiện tại đây khi đến lượt bạn.</span></div>`;
    const start=ds24ListRow({title:'Bắt đầu việc mới',subtitle:'Nhập hàng nhanh, kiểm kê, đổi tình trạng hoặc tiêu hủy',leading:null,attrs:'data-t380-manual-open data-t383-start-new',theme:'Theme7WarehouseStartNewWork',extraClass:'t383-start-new-row'});
    work.innerHTML=`${heading}${rows}${start}`;

    // The top search is intentionally inventory lookup, not a promise of global search.
    const search=home.querySelector('[data-t380-inventory-search]');
    if(search){search.setAttribute('aria-label','Tra cứu tồn kho');search.setAttribute('placeholder','Tìm sản phẩm, SKU hoặc lô');}
    // Attention badges must deep-link to the corresponding state; until then do not imply a filtered destination.
    const inventory=[...home.querySelectorAll('.ds24-list-row')].find(r=>r.querySelector('.ds24-list-row__copy strong')?.textContent.trim()==='Tồn kho');
    inventory?.querySelector('.ds24-badge')?.remove();
  }

  function adjustManualChooser(){
    const sheet=document.querySelector('.t380-manual-sheet');
    if(!sheet)return;
    const stateRow=sheet.querySelector('[data-theme-entry-flow="UIF-09"]');
    if(stateRow){
      stateRow.setAttribute('data-t380-target-screen','SCR-036');stateRow.setAttribute('data-t380-context','state-list');
      const helper=stateRow.querySelector('.ds24-list-row__copy small');if(helper)helper.textContent='Chọn sản phẩm hoặc lô rồi đổi tình trạng';
    }
    const disposeRow=sheet.querySelector('[data-theme-entry-flow="UIF-10"]');
    if(disposeRow){
      disposeRow.setAttribute('data-t380-target-screen','SCR-036');disposeRow.setAttribute('data-t380-context','disposal-list');
      const helper=disposeRow.querySelector('.ds24-list-row__copy small');if(helper)helper.textContent='Chọn hàng đủ điều kiện rồi lập yêu cầu';
    }
    // Filter manual choices by the active persona.
    sheet.querySelectorAll('[data-theme-entry-flow]').forEach(row=>{row.hidden=!PERSONAS[persona].allowed.includes(row.dataset.themeEntryFlow);});
  }

  function adjustCatalog(){
    const catalog=document.querySelector('#app-screen .t381-catalog-screen');
    if(!catalog)return;
    const stack=catalog.querySelector('.app-content .body-stack');
    if(stack&&!stack.querySelector('[data-t390-catalog-search]')){
      const wrap=document.createElement('div');wrap.className='t390-catalog-search';wrap.innerHTML=ds24Search('','data-t390-catalog-search','Tìm chức năng kho');stack.prepend(wrap);
    }
    catalog.querySelectorAll('[data-t381-catalog-flow]').forEach(row=>{
      const id=row.dataset.t381CatalogFlow;
      row.hidden=!PERSONAS[persona].allowed.includes(id);
      // Opening balance is a one-time setup and disappears after successful initialization.
      if(id==='UIF-12'&&(stateByScreen['SCR-071']==='COMPLETED'||resolvedTasks.has('APP-OPENING-0831')))row.hidden=true;
    });
    catalog.querySelectorAll('.t381-catalog-section').forEach(section=>{section.hidden=![...section.querySelectorAll('.t381-catalog-row')].some(r=>!r.hidden);});
  }

  function setTaskContext(id){
    const all=Object.values(TASKS).flat();const t=all.find(x=>x.id===id)||taskList().find(x=>x.id===id);if(!t)return;
    startedTasks.add(id);currentOrigin='task';currentTaskId=id;
    if(t.context==='receipt-document'||t.context==='approve-receipt'){
      flowMode='document';selectedDocumentId='PN-260816-04';if(typeof resetBj02Receipt==='function')resetBj02Receipt('document');
      stateByScreen[t.screen]='READY';
    }else if(t.context==='picking'){
      io05SelectedOrderId='SO-260827-21';if(typeof io05ResetHandover==='function')io05ResetHandover();stateByScreen['SCR-026']='READY';
    }else if(t.context==='count'){stateByScreen['SCR-044']='BLIND_COUNT';}
    else if(t.context==='valuation-r3'){val03SelectedReceiptId='VAL03-R3';val03EvidenceSheetOpen=false;stateByScreen['SCR-015']='READY';}
    else if(t.context==='valuation-r1'){val03SelectedReceiptId='VAL03-R1';val03EvidenceSheetOpen=false;stateByScreen['SCR-015']='READY';}
    else if(t.context==='reconcile-amox'){cr16SelectedId='REC-260907-04';stateByScreen['SCR-079']=cr079StateFor16(cr16Current());}
    else if(t.context==='approve-count'){stateByScreen['SCR-046']='APPROVAL_REVIEW';}
    else if(t.context==='approve-opening'){stateByScreen['SCR-070']='READY';}
  }

  function isResolutionPoint(){
    const st=stateByScreen[activeScreenId];
    const terminalStates=new Set(['COMPLETED','CANCELLED','RESOLVED','REJECTED','REJECTED_EXECUTION','ACTIVE_RECONCILED','TERMINAL','VALUATION_PENDING_RESULT','PENDING_APPROVAL','APPROVED_PENDING_DISPOSAL']);
    const screenName=screens.find(s=>s.id===activeScreenId)?.name||'';
    if(currentOrigin&&terminalStates.has(st)&&(screenName.includes('Kết quả')||st==='PENDING_APPROVAL'||st==='APPROVED_PENDING_DISPOSAL'))return true;
    if(currentOrigin==='task'){
      if(activeFlowId==='UIF-02'&&((activeScreenId==='SCR-010'&&st==='PENDING_APPROVAL')||(activeScreenId==='SCR-012'&&['COMPLETED','VALUATION_PENDING_RESULT'].includes(st))))return true;
      if(activeFlowId==='UIF-03'&&activeScreenId==='SCR-019'&&st==='COMPLETED')return true;
      if(activeFlowId==='UIF-05'&&activeScreenId==='SCR-029'&&st==='COMPLETED')return true;
      if(activeFlowId==='UIF-08'&&((activeScreenId==='SCR-042'&&st==='PENDING_APPROVAL')||(activeScreenId==='SCR-047'&&['COMPLETED','CANCELLED'].includes(st))))return true;
      if(activeFlowId==='UIF-12'&&activeScreenId==='SCR-071'&&st==='COMPLETED')return true;
      if(activeFlowId==='UIF-16'&&activeScreenId==='SCR-083'&&['COMPLETED','RESOLVED'].includes(st))return true;
    }
    if(currentOrigin==='manual'){
      if(activeFlowId==='UIF-09'&&((activeScreenId==='SCR-038'&&st==='PENDING_APPROVAL')||(activeScreenId==='SCR-041'&&st==='COMPLETED')))return true;
      if(activeFlowId==='UIF-10'&&((activeScreenId==='SCR-040'&&['PENDING_APPROVAL','APPROVED_PENDING_DISPOSAL'].includes(st))||(activeScreenId==='SCR-041'&&st==='COMPLETED')))return true;
      if(activeFlowId==='UIF-02'&&activeScreenId==='SCR-010'&&st==='PENDING_APPROVAL')return true;
      if(activeFlowId==='UIF-08'&&activeScreenId==='SCR-042'&&st==='PENDING_APPROVAL')return true;
    }
    return false;
  }

  function replaceFooter(label,attr){
    const scaffold=document.querySelector('#app-screen .v-page-scaffold');if(!scaffold)return;
    scaffold.querySelector(':scope > .app-actions')?.remove();
    scaffold.insertAdjacentHTML('beforeend',primaryFooter(label,attr));
  }
  function lockSubmittedHandoff(){
    const st=stateByScreen[activeScreenId];
    const locked=(activeScreenId==='SCR-010'&&st==='PENDING_APPROVAL')||(activeScreenId==='SCR-038'&&st==='PENDING_APPROVAL')||(activeScreenId==='SCR-040'&&st==='PENDING_APPROVAL')||(activeScreenId==='SCR-069'&&st==='PENDING_APPROVAL');
    if(!locked)return;
    const bar=document.querySelector('#app-screen .app-appbar');
    bar?.querySelector('.app-back-button')?.remove();
    if(bar){bar.classList.remove('has-back');bar.classList.add('no-back');bar.setAttribute('data-ds-prop-show-back-button','false');}
  }
  function applyContextAwareExit(){
    if(!isThemeFlow())return;
    lockSubmittedHandoff();
    if(!isResolutionPoint())return;
    if(currentOrigin==='catalog')replaceFooter('Về tất cả chức năng kho','data-t390-return-catalog');
    else replaceFooter('Về Kho','data-t390-return-home');
  }

  function polishCrossThemeCopy(){
    // Approval is the actual next step in BJ09; make CTA explicit.
    if(activeFlowId==='UIF-09'&&activeScreenId==='SCR-038'&&stateByScreen['SCR-038']==='READY'){
      const b=document.querySelector('[data-ic09-action="submit"],[data-v350-action="ic09-submit"]');if(b)b.textContent='Gửi chờ duyệt';
    }
    // A completed approved over-receipt is no longer an unresolved warning.
    if(activeFlowId==='UIF-02'&&activeScreenId==='SCR-012'&&!['PROCESSING','UNKNOWN','COMMIT_UNKNOWN','REJECTED_EXECUTION'].includes(stateByScreen['SCR-012'])){
      document.querySelectorAll('#app-screen .status-badge').forEach(b=>{
        if(b.textContent.trim()==='Vượt chứng từ'){
          b.textContent='Đã duyệt vượt';
          b.classList.remove('status-badge--warning');
          b.classList.add('status-badge--success');
          b.setAttribute('data-ds-prop-status','VBadgeStatus.success');
        }
      });
    }
    // Avoid two consecutive screens carrying the same generic title in the customer-return flow.
    if(activeFlowId==='UIF-06'&&activeScreenId==='SCR-031'){
      const h=document.querySelector('#app-screen .app-appbar h3');if(h)h.textContent='Kiểm hàng khách trả';
    }
    // Recovery copy should describe the user's business object, not an implementation identity token.
    if(activeFlowId==='UIF-17'){
      document.querySelectorAll('#app-screen *').forEach(el=>{if(el.children.length===0&&el.textContent.trim()==='Định danh')el.textContent='Lần xử lý';});
    }
    document.querySelectorAll('.ds24-info-row,.info-row,.key-value-row').forEach(row=>{
      const key=row.querySelector(':scope > :first-child');if(key&&key.textContent.trim()==='Định danh xử lý')key.textContent='Lần xử lý';
    });
  }

  function apply(){
    rebuildWorkQueue();adjustManualChooser();adjustCatalog();applyContextAwareExit();polishCrossThemeCopy();
  }

  renderAppScreen=function(){currentRenderAppScreen();apply();};

  renderInspector=function(){
    currentRenderInspector();
    if(document.body.dataset.workbenchMode!=='theme')return;
    const state=document.getElementById('state-switcher');
    if(state&&(isThemeInventory()||document.querySelector('#app-screen .t381-catalog-screen'))){
      state.innerHTML=`<label class="t390-persona-control"><span>Vai trò mô phỏng</span><select data-t390-persona aria-label="Vai trò mô phỏng">${Object.entries(PERSONAS).map(([id,p])=>`<option value="${id}" ${persona===id?'selected':''}>${p.label}</option>`).join('')}</select></label>`;
    }
    const trace=document.getElementById('traceability');
    if(trace&&(isThemeInventory()||document.querySelector('#app-screen .t381-catalog-screen')))trace.insertAdjacentHTML('beforeend',`<div class="trace-row"><span>Work projection</span><strong>${PERSONAS[persona].label} · state × quyền × ngữ cảnh</strong></div>`);
  };

  window.addEventListener('click',event=>{
    const task=event.target.closest?.('[data-t390-task-id]');
    if(task){setTaskContext(task.dataset.t390TaskId);return;}
    const catalog=event.target.closest?.('.t381-catalog-row[data-theme-entry-flow]');
    if(catalog){currentOrigin='catalog';currentTaskId=null;return;}
    const manual=event.target.closest?.('.t380-manual-sheet [data-theme-entry-flow]');
    if(manual){currentOrigin='manual';currentTaskId=null;return;}
    if(isThemeInventory()&&event.target.closest?.('.t380-utility-section [data-theme-entry-flow]')){currentOrigin='utility';currentTaskId=null;return;}
    const home=event.target.closest?.('[data-t390-return-home]');
    if(home){
      event.preventDefault();event.stopImmediatePropagation();
      if(currentTaskId)resolvedTasks.add(currentTaskId);
      currentOrigin=null;currentTaskId=null;
      document.querySelector('[data-theme-sidebar-route="inventory"]')?.click();
      return;
    }
    const backCatalog=event.target.closest?.('[data-t390-return-catalog]');
    if(backCatalog){
      event.preventDefault();event.stopImmediatePropagation();
      if(currentTaskId)resolvedTasks.add(currentTaskId);
      currentOrigin=null;currentTaskId=null;
      document.querySelector('[data-theme-sidebar-route="inventory"]')?.click();
      setTimeout(()=>document.querySelector('[data-t381-catalog-open]')?.click(),0);
    }
  },true);

  document.addEventListener('change',event=>{
    if(event.target.matches('[data-t390-persona]')){
      persona=event.target.value;
      const u=new URL(location.href);u.searchParams.set('persona',persona);history.replaceState(null,'',u);
      currentOrigin=null;currentTaskId=null;render();
    }
  },true);

  document.addEventListener('input',event=>{
    if(!event.target.matches('[data-t390-catalog-search]'))return;
    const q=event.target.value.trim().toLowerCase();
    const catalog=document.querySelector('#app-screen .t381-catalog-screen');if(!catalog)return;
    catalog.querySelectorAll('.t381-catalog-row').forEach(row=>{
      if(!PERSONAS[persona].allowed.includes(row.dataset.t381CatalogFlow||'')){row.hidden=true;return;}
      row.hidden=q&&!row.innerText.toLowerCase().includes(q);
    });
    catalog.querySelectorAll('.t381-catalog-section').forEach(section=>{section.hidden=![...section.querySelectorAll('.t381-catalog-row')].some(r=>!r.hidden);});
  },true);

  const badge=document.querySelector('.review-meta > .review-badge:not(.review-badge--muted)');
  if(badge)badge.textContent='v3.9.0 · full-theme end-user hardening';
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.scenarios=[...(window.__VET45_PROTOTYPE__.scenarios||[]),'persona-work-queue-projection','exact-task-deep-link','manual-object-selection','context-aware-return','handoff-lock','permission-aware-catalog'];
  }
  render();
})();
