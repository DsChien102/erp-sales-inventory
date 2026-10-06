/* VET45 Theme 7 v4.6.4 — BJ02 pending-approval continuity
 * Parent: v4.6.3
 * Scope: design-only comparison. Existing Warehouse navigation remains default and untouched.
 * Candidate principle: one owner can operate the whole warehouse without learning 17 BJ names.
 */
(()=>{
  const VERSION='4.6.4';
  const qs=new URLSearchParams(location.search);
  let hubMode=qs.get('hub')==='candidate'?'candidate':'current';
  let candidateView=qs.get('hubView')||'home';
  const currentRenderAppScreen=renderAppScreen;
  const currentRenderInspector=renderInspector;
  const currentSyncReviewUrl=syncReviewUrl;

  const WORKSPACES={
    inventory:{title:'Tồn kho',subtitle:'Số lượng, khả dụng, lô và tình trạng hàng',icon:'warehouse',items:[
      {flow:'UIF-01',title:'Tồn kho & khả dụng',subtitle:'Tra cứu sản phẩm, số lượng, lô và khả dụng',icon:'warehouse'},
      {flow:'UIF-09',title:'Tình trạng hàng',subtitle:'Xem và xử lý trạng thái của sản phẩm hoặc lô',icon:'shield'},
      {flow:'CAP-01',title:'Chính sách tồn & cận hạn',subtitle:'Thiết lập ngưỡng tồn và chính sách cận hạn',icon:'shield'}
    ]},
    movement:{title:'Nhập, xuất & hoàn trả',subtitle:'Hàng đi vào, đi ra và quay lại kho',icon:'package',items:[
      {flow:'UIF-02',title:'Nhận hàng',subtitle:'Nhận theo chứng từ hoặc nhập nhanh',icon:'cloudUpload'},
      {flow:'UIF-05',title:'Lấy & bàn giao',subtitle:'Chuẩn bị hàng và bàn giao theo đơn bán',icon:'package'},
      {flow:'UIF-06',title:'Hàng khách trả',subtitle:'Tiếp nhận và phân loại hàng trả lại',icon:'rotate'},
      {flow:'UIF-07',title:'Trả nhà cung cấp',subtitle:'Chuẩn bị và thực hiện trả hàng',icon:'arrowLeft'}
    ]},
    control:{title:'Kiểm kê & xử lý',subtitle:'Kiểm tra thực tế, sai lệch và trường hợp bất thường',icon:'listCheck',items:[
      {flow:'UIF-08',title:'Kiểm kê kho',subtitle:'Đếm, rà soát và xử lý chênh lệch',icon:'listCheck'},
      {flow:'UIF-09',title:'Hàng cần xử lý',subtitle:'Bắt đầu từ sản phẩm hoặc lô có tình trạng cần xử lý',icon:'shield'},
      {flow:'UIF-11',title:'Hủy & sửa sai nghiệp vụ',subtitle:'Xử lý giao dịch kho có sai sót',icon:'edit'},
      {flow:'UIF-16',title:'Đối soát sai lệch',subtitle:'Điều tra khi số liệu giữa các nguồn không khớp',icon:'search'}
    ]},
    valuation:{title:'Giá trị kho',subtitle:'Giá nhập, chi phí mua và giá vốn',icon:'layers',items:[
      {flow:'UIF-03',title:'Giá trị hàng nhập',subtitle:'Xác nhận giá trị ban đầu của hàng đã nhận',icon:'checkCircle'},
      {flow:'UIF-13',title:'Chi phí mua bổ sung',subtitle:'Ghi nhận chi phí phát sinh đến muộn',icon:'fileText'},
      {flow:'UIF-14',title:'Giá vốn',subtitle:'Tính, rà soát và công bố giá vốn',icon:'layers'}
    ]},
    history:{title:'Báo cáo & lịch sử',subtitle:'Thẻ kho, biến động và số liệu tra cứu',icon:'history',items:[
      {flow:'UIF-15',title:'Báo cáo tồn & thẻ kho',subtitle:'Xem tồn tại thời điểm và lịch sử biến động',icon:'history'}
    ]},
    setup:{title:'Thiết lập kho',subtitle:'Các việc thiết lập ít dùng',icon:'inbox',items:[
      {flow:'UIF-12',title:'Khởi tạo tồn đầu kỳ',subtitle:'Thiết lập số dư tồn kho ban đầu',icon:'inbox'},
      {flow:'CAP-01',title:'Chính sách tồn & cận hạn',subtitle:'Thiết lập ngưỡng tồn và chính sách cảnh báo',icon:'shield'}
    ]}
  };

  function params(){return new URLSearchParams(location.search);}
  function isThemeInventory(){const q=params();return document.body.dataset.workbenchMode==='theme'&&q.get('app')==='inventory';}

  function bottomNav(){
    return `<nav class="t7-app-bottom-nav" aria-label="Điều hướng chính" data-theme-component="VET45BottomNavigation">
      <button type="button" disabled aria-label="Trang chủ">${icon('warehouse','icon--sm')}<span>Trang chủ</span></button>
      <button type="button" disabled aria-label="Bán hàng">${icon('package','icon--sm')}<span>Bán hàng</span></button>
      <button type="button" disabled aria-label="Đơn hàng">${icon('fileText','icon--sm')}<span>Đơn hàng</span></button>
      <button type="button" disabled aria-label="Đối tác">${icon('user','icon--sm')}<span>Đối tác</span></button>
      <button type="button" class="is-active" aria-current="page" data-theme-sidebar-route="more" aria-label="Thêm">${icon('more','icon--sm')}<span>Thêm</span></button>
    </nav>`;
  }

  function shell({title='Kho',body,back=false}){
    return `<div class="v-page-scaffold figma-calibrated-shell t7-integrated-shell ${back?'t462-workspace-screen':'t462-warehouse-hub'}" data-mobile-product data-product-app data-inspectable="true" data-ds-component="VPageScaffold" data-ds-profile="screen.shell.standard" data-ds-prop-title="${escapeAttribute(title)}" data-ds-prop-center-title="false">
      ${statusBar()}
      <header class="app-header"><div class="app-appbar ${back?'has-back':'has-back'}" data-ds-component="VAppBar" data-ds-prop-center-title="false" data-ds-prop-actions="null" data-ds-prop-show-back-button="true">
        <button class="app-icon-button app-back-button" ${back?'data-t462-workspace-back':'data-theme-app-back'} type="button" aria-label="Quay lại" data-ds-internal="VAppBar.leading">${icon('chevronLeft','icon--24')}</button>
        <div class="app-appbar-copy" data-ds-component="VAppBarTitle"><h3>${esc(title)}</h3></div>
      </div></header>
      <div class="app-content" data-ds-component="VPagePadding" data-ds-profile="screen.body.standard"><div class="body-stack">${body}</div></div>
      ${bottomNav()}
    </div>`;
  }

  function heading(title,meta=''){
    return `<div class="t462-section-heading"><h2 data-ds-component="VText" data-ds-prop-style="Label/Default">${esc(title)}</h2>${meta?`<span>${esc(meta)}</span>`:''}</div>`;
  }

  function quickAction({label,iconName,flow,screen='',context=''}){
    const attrs=screen?`data-t380-target-screen="${screen}" data-t380-context="${context}"`:`data-theme-entry-flow="${flow}"`;
    return `<button class="t462-quick-action" type="button" ${attrs} data-t462-quick="${flow}" data-ds-component="VQuickActionButton" data-ds-prop-state="Default"><span class="t462-quick-action__icon">${icon(iconName,'icon--sm')}</span><span class="t462-quick-action__label">${esc(label)}</span></button>`;
  }

  function attentionRow({title,subtitle,count,flow='',iconName='alertTriangle',attrs=''}){
    const routeAttrs=flow?`data-theme-entry-flow="${flow}" data-t462-attention="${flow}"`:'';
    return `<button class="t462-attention-row" type="button" ${routeAttrs} ${attrs}><span class="t462-attention-row__icon">${icon(iconName,'icon--sm')}</span><span class="t462-attention-row__copy"><strong>${esc(title)}</strong><span>${esc(subtitle)}</span></span><span class="t462-attention-row__count">${esc(count)}</span></button>`;
  }

  const PENDING_RECEIPTS=[
    {id:'REC-260916-01',supplier:'Minh Dũng',meta:'Kho trung tâm · 1 mặt hàng · Nguyễn Văn An gửi 09:41'},
    {id:'REC-260916-02',supplier:'An Việt',meta:'Kho trung tâm · 2 mặt hàng · Lê Thu Hà gửi 08:55'},
    {id:'REC-260916-03',supplier:'Minh Phát',meta:'Kho trung tâm · 4 mặt hàng · Trần Minh gửi 08:20'}
  ];

  function workspaceRow(id){
    const w=WORKSPACES[id];
    return ds24ListRow({title:w.title,subtitle:w.subtitle,leading:w.icon,attrs:`data-t462-workspace="${id}"`,theme:'Theme7WarehouseCandidateWorkspace',extraClass:'t462-workspace-row'});
  }

  function renderHome(){
    const quick=`<section class="t462-section t462-section--quick" data-ds-component="VSection"><div class="t462-quick-grid">
      ${quickAction({label:'Nhận hàng',iconName:'cloudUpload',flow:'UIF-02'})}
      ${quickAction({label:'Lấy hàng',iconName:'package',flow:'UIF-05'})}
      ${quickAction({label:'Kiểm kê',iconName:'listCheck',flow:'UIF-08'})}
      ${quickAction({label:'Tra cứu tồn',iconName:'search',flow:'UIF-01'})}
    </div></section>`;
    const attention=`<section class="t462-section" data-ds-component="VSection">${heading('Cần chú ý')}
      <div class="t462-attention-list">
        ${attentionRow({title:'Nhận hàng chờ phê duyệt',subtitle:'3 lần nhận đang chờ xử lý',count:'3',iconName:'clock',attrs:'data-v464-pending-approvals'})}
        ${attentionRow({title:'Lô sắp hết hạn',subtitle:'Cần kiểm tra trước khi bán hoặc xuất',count:'3 lô',flow:'UIF-09',iconName:'shield'})}
        ${attentionRow({title:'Sai lệch cần đối soát',subtitle:'Tồn kho đang có chênh lệch cần xác minh',count:'1',flow:'UIF-16',iconName:'search'})}
        ${attentionRow({title:'Nghiệp vụ chưa xác định kết quả',subtitle:'Cần xác minh trước khi thao tác tiếp',count:'1',flow:'UIF-17',iconName:'rotate'})}
      </div></section>`;
    const workspaces=`<section class="t462-section" data-ds-component="VSection">${heading('Quản lý kho')}
      <div class="t462-workspace-list ds24-list-stack">${['inventory','movement','control','valuation','history'].map(workspaceRow).join('')}</div>
    </section>`;
    const setup=`<section class="t462-section" data-ds-component="VSection">${ds24ListRow({title:'Thiết lập kho',subtitle:'Tồn đầu kỳ và chính sách ít dùng',leading:'inbox',attrs:'data-t462-workspace="setup"',theme:'Theme7WarehouseCandidateSetup',extraClass:'t462-workspace-row'})}</section>`;
    const search=`<div class="t462-search-wrap">${ds24Search('','data-t462-inventory-search','Tìm sản phẩm, SKU hoặc quét mã')}</div>`;
    return shell({body:`${search}${quick}${attention}${workspaces}${setup}`});
  }

  function renderWorkspace(id){
    const w=WORKSPACES[id]||WORKSPACES.inventory;
    const rows=w.items.map(item=>ds24ListRow({title:item.title,subtitle:item.subtitle,leading:item.icon,attrs:`data-theme-entry-flow="${item.flow}"`,theme:'Theme7WarehouseCandidateCapability',extraClass:'t462-capability-row'})).join('');
    return shell({title:w.title,back:true,body:`<section class="t462-section t462-section--workspace-list" data-ds-component="VSection"><div class="t462-sublist ds24-list-stack">${rows}</div></section>`});
  }

  function renderPendingApprovals(){
    const rows=PENDING_RECEIPTS.map(item=>ds24ListRow({
      title:item.supplier,
      subtitle:item.meta,
      leading:'cloudUpload',
      trailing:ds24Badge('Chờ duyệt','Warning'),
      attrs:`data-theme-entry-flow="UIF-02" data-t380-target-screen="SCR-011" data-t380-context="bj02-pending-approval" data-v464-pending-receipt="${item.id}"`,
      theme:'Theme7PendingReceiptApproval',
      extraClass:'t462-capability-row t464-pending-receipt-row'
    })).join('');
    return shell({title:'Nhận hàng chờ phê duyệt',back:true,body:`<section class="t462-section t462-section--workspace-list" data-ds-component="VSection">${heading('Đang chờ xử lý','3 lần nhận')}<div class="t462-sublist ds24-list-stack">${rows}</div></section>`});
  }

  function renderCandidate(){
    const app=document.getElementById('app-screen');
    if(!app)return;
    if(candidateView==='home') app.innerHTML=renderHome();
    else if(candidateView==='pending-approvals') app.innerHTML=renderPendingApprovals();
    else app.innerHTML=renderWorkspace(candidateView);
  }

  function installCompareControl(){
    if(!isThemeInventory())return;
    const state=document.getElementById('state-switcher');
    if(!state)return;
    let panel=state.querySelector('[data-t462-hub-switch]');
    if(!panel){
      panel=document.createElement('div');
      panel.className='t462-hub-switch';
      panel.setAttribute('data-t462-hub-switch','');
      state.prepend(panel);
    }
    panel.innerHTML=`<span class="t462-hub-switch__label">So sánh Hub Kho</span><div class="t462-hub-switch__controls" role="group" aria-label="Chọn thiết kế Hub Kho"><button type="button" data-t462-hub-mode="current" class="${hubMode==='current'?'is-active':''}">Hiện tại</button><button type="button" data-t462-hub-mode="candidate" class="${hubMode==='candidate'?'is-active':''}">Candidate</button></div><p class="t462-hub-switch__note">Candidate là thử nghiệm IA/UX, chưa thay navigation và chưa cập nhật Screen Contract.</p>`;
  }

  function updateInspector(){
    if(!isThemeInventory())return;
    const trace=document.getElementById('traceability');
    const rationale=document.getElementById('design-rationale');
    if(hubMode==='candidate'){
      if(trace)trace.innerHTML=`<div class="trace-row"><span>Review mode</span><strong>Hub Kho · Candidate UX</strong></div><div class="trace-row"><span>Baseline</span><strong>v4.6.1 navigation giữ nguyên</strong></div><div class="trace-row"><span>Primary IA</span><strong>Search + 4 Quick Actions + Cần chú ý + 5 workspace</strong></div><div class="trace-row"><span>Permission</span><strong>Không phụ thuộc role; thiết kế cho một Owner làm tất cả</strong></div><div class="trace-row"><span>Documentation</span><strong>Chưa propagate</strong></div>`;
      if(rationale)rationale.textContent='Candidate refinement giữ trọng tâm cho một người vận hành toàn bộ Kho, đồng thời bỏ các nhãn/copy giải thích nội bộ khỏi Product UI và chuẩn hóa hierarchy/spacing theo ngôn ngữ VET45. Navigation v4.6.1 vẫn được giữ để so sánh.';
      const id=document.getElementById('current-screen-id');if(id)id.textContent=candidateView==='home'?'THEME-07 · HUB-CANDIDATE':candidateView==='pending-approvals'?'BJ02 · PENDING-APPROVAL-WORKLIST':'THEME-07 · WORKSPACE-CANDIDATE';
      const name=document.getElementById('current-screen-name');if(name)name.textContent=candidateView==='home'?'Kho · Candidate':candidateView==='pending-approvals'?'Nhận hàng chờ phê duyệt':WORKSPACES[candidateView]?.title||'Kho · Candidate';
    }
    installCompareControl();
  }

  function setHubMode(mode){
    hubMode=mode==='candidate'?'candidate':'current';
    candidateView='home';
    const u=new URL(location.href);
    if(hubMode==='candidate')u.searchParams.set('hub','candidate');else u.searchParams.delete('hub');
    u.searchParams.delete('hubView');
    history.replaceState(null,'',u);
    render();
  }

  function setCandidateView(view){
    candidateView=view||'home';
    const u=new URL(location.href);u.searchParams.set('hub','candidate');
    if(candidateView==='home')u.searchParams.delete('hubView');else u.searchParams.set('hubView',candidateView);
    history.replaceState(null,'',u);render();
  }

  function augmentBj02PendingReview(){
    if(activeFlowId!=='UIF-02'||activeScreenId!=='SCR-010'||stateByScreen['SCR-010']!=='PENDING_APPROVAL')return;
    const app=document.getElementById('app-screen');
    if(!app)return;
    const scaffold=app.querySelector('.v-page-scaffold');
    if(!scaffold)return;
    const existing=scaffold.querySelector('[data-v464-action="to-warehouse"]');
    if(!existing){
      scaffold.insertAdjacentHTML('beforeend',`<footer class="app-actions figma-sticky-footer t464-pending-footer" data-ds-component="DS v2 / Sticky Footer" data-ds-prop-layout="Single"><button class="button button--primary button--full" type="button" data-v464-action="to-warehouse" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.primary" data-ds-prop-size="VButtonSize.medium">Về Kho</button></footer>`);
    }
    let back=scaffold.querySelector('.app-back-button');
    if(!back){
      const bar=scaffold.querySelector('.app-appbar');
      if(bar){
        bar.classList.remove('no-back');bar.classList.add('has-back');
        bar.insertAdjacentHTML('afterbegin',`<button class="app-icon-button app-back-button" type="button" aria-label="Quay về Kho" data-v464-action="to-warehouse" data-ds-internal="VAppBar.leading">${icon('chevronLeft','icon--24')}</button>`);
        back=bar.querySelector('.app-back-button');
      }
    }
    if(back){back.setAttribute('data-v464-action','to-warehouse');back.setAttribute('aria-label','Quay về Kho');}
  }

  renderAppScreen=function(){
    currentRenderAppScreen();
    if(isThemeInventory()&&hubMode==='candidate')renderCandidate();
    augmentBj02PendingReview();
  };

  renderInspector=function(){
    currentRenderInspector();
    updateInspector();
  };

  syncReviewUrl=function(){
    currentSyncReviewUrl();
    const u=new URL(location.href);
    if(hubMode==='candidate')u.searchParams.set('hub','candidate');else u.searchParams.delete('hub');
    if(hubMode==='candidate'&&candidateView!=='home')u.searchParams.set('hubView',candidateView);else u.searchParams.delete('hubView');
    history.replaceState(null,'',u);
  };

  function goCandidateInventory(view='home'){
    hubMode='candidate';candidateView=view;
    const u=new URL(location.href);
    u.searchParams.set('mode','theme');u.searchParams.set('app','inventory');u.searchParams.set('hub','candidate');
    if(view==='home')u.searchParams.delete('hubView');else u.searchParams.set('hubView',view);
    history.replaceState(null,'',u);render();
  }

  function prepareSubmittedPendingReceipt(){
    flowMode='document';
    selectedDocumentId='PN-260816-04';
    if(typeof resetBj02Receipt==='function')resetBj02Receipt('document');
    if(Array.isArray(bj02Lines)){
      bj02Lines=bj02Lines.map((line,index)=>{
        const qty=index===0?121:24;
        const lotCode=index===0?'NOB-2608-A':'AMX-2608-B';
        const expiry=index===0?'2027-08-31':'2028-03-31';
        return {...line,status:'COMPLETED',accepted:0,totalReceived:qty,quarantine:0,damaged:0,rejected:0,lots:[{id:`V464-LOT-${index+1}`,code:lotCode,expiry,expiryPrecision:'DAY',manufactureDate:'',manufacturePrecision:'DAY',accepted:qty,totalReceived:qty,quarantine:0,damaged:0,rejected:0}]};
      });
    }
    bj02Header={...bj02Header,businessDate:'2026-09-16'};
  }

  document.addEventListener('click',event=>{
    const action=event.target.closest?.('[data-v464-action]');
    if(action){event.preventDefault();event.stopImmediatePropagation();goCandidateInventory('home');return;}
    const exitApproval=event.target.closest?.('[data-action="exit-approval"]');
    if(exitApproval&&activeFlowId==='UIF-02'&&activeScreenId==='SCR-011'){event.preventDefault();event.stopImmediatePropagation();goCandidateInventory('pending-approvals');return;}
    const pendingReceipt=event.target.closest?.('[data-v464-pending-receipt]');
    if(pendingReceipt){
      prepareSubmittedPendingReceipt();
      stateByScreen['SCR-010']='PENDING_APPROVAL';stateByScreen['SCR-011']='READY';approvalRejectReason='';
    }
  },true);

  window.addEventListener('click',event=>{
    const pending=event.target.closest?.('[data-v464-pending-approvals]');
    if(pending&&isThemeInventory()&&hubMode==='candidate'){event.preventDefault();event.stopImmediatePropagation();setCandidateView('pending-approvals');return;}
    const switcher=event.target.closest?.('[data-t462-hub-mode]');
    if(switcher&&isThemeInventory()){
      event.preventDefault();event.stopImmediatePropagation();setHubMode(switcher.dataset.t462HubMode);return;
    }
    if(!isThemeInventory()||hubMode!=='candidate')return;
    const ws=event.target.closest?.('[data-t462-workspace]');
    if(ws){event.preventDefault();event.stopImmediatePropagation();setCandidateView(ws.dataset.t462Workspace);return;}
    const back=event.target.closest?.('[data-t462-workspace-back]');
    if(back){event.preventDefault();event.stopImmediatePropagation();setCandidateView('home');return;}
  },true);

  document.addEventListener('keydown',event=>{
    if(!isThemeInventory()||hubMode!=='candidate'||!event.target.matches('[data-t462-inventory-search]')||event.key!=='Enter')return;
    event.preventDefault();
    if(typeof bj01Query!=='undefined')bj01Query=event.target.value.trim();
    const uif=document.querySelector('[data-t462-quick="UIF-01"]');
    if(uif)uif.click();
  },true);

  const badge=document.querySelector('.review-meta > .review-badge:not(.review-badge--muted)');
  if(badge)badge.textContent='v4.6.4 · BJ02 approval continuity';
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.scenarios=[...(window.__VET45_PROTOTYPE__.scenarios||[]),'warehouse-hub-current-vs-candidate','warehouse-owner-full-scope-candidate','warehouse-five-workspace-ia','bj02-pending-review-return-to-hub','bj02-pending-approval-worklist'];
  }
  render();
})();
