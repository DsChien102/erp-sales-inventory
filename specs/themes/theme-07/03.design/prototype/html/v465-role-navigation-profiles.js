/* VET45 Theme 7 v4.6.5 — Role-aware flat Warehouse Hub
 * Parent: v4.6.4
 * Scope: Hub Kho navigation presentation + review role simulation only.
 * Business destinations stay canonical; contextual-only capabilities are not promoted into global menu rows.
 */
(()=>{
  const VERSION='4.6.5';
  const ROLE_KEY='hubRole';
  const DEFAULT_ROLE='owner';
  const previousRenderAppScreen=renderAppScreen;
  const previousRenderInspector=renderInspector;
  const previousSyncReviewUrl=syncReviewUrl;

  const CAPABILITIES={
    'UIF-01':{title:'Tồn kho & khả dụng',quickLabel:'Tra cứu tồn',subtitle:'Tra cứu sản phẩm, số lượng, lô và khả dụng',icon:'warehouse'},
    'UIF-02':{title:'Nhận hàng',quickLabel:'Nhận hàng',subtitle:'Nhận theo chứng từ hoặc nhập nhanh',icon:'cloudUpload'},
    'UIF-05':{title:'Lấy & bàn giao',quickLabel:'Lấy hàng',subtitle:'Chuẩn bị hàng và bàn giao theo đơn bán',icon:'package'},
    'UIF-06':{title:'Hàng khách trả',subtitle:'Tiếp nhận và phân loại hàng trả lại',icon:'rotate'},
    'UIF-07':{title:'Trả nhà cung cấp',subtitle:'Chuẩn bị và thực hiện trả hàng',icon:'arrowLeft'},
    'UIF-08':{title:'Kiểm kê kho',quickLabel:'Kiểm kê',subtitle:'Đếm, rà soát và xử lý chênh lệch',icon:'listCheck'},
    'UIF-09':{title:'Tình trạng hàng',subtitle:'Xem và xử lý trạng thái sản phẩm hoặc lô',icon:'shield'},
    'UIF-11':{title:'Hủy & sửa sai nghiệp vụ',subtitle:'Xử lý giao dịch kho có sai sót',icon:'edit'},
    'UIF-16':{title:'Đối soát sai lệch',subtitle:'Điều tra khi số liệu giữa các nguồn không khớp',icon:'search'},
    'UIF-03':{title:'Xác nhận giá nhập',quickLabel:'Xác nhận giá',subtitle:'Xác lập giá trị ban đầu của hàng đã nhận',icon:'checkCircle'},
    'UIF-13':{title:'Chi phí mua bổ sung',quickLabel:'Chi phí mua',subtitle:'Ghi nhận chi phí mua phát sinh đến muộn',icon:'fileText'},
    'UIF-14':{title:'Giá vốn',quickLabel:'Giá vốn',subtitle:'Tính, rà soát và công bố giá vốn',icon:'layers'},
    'UIF-15':{title:'Báo cáo tồn & thẻ kho',quickLabel:'Báo cáo tồn',subtitle:'Xem tồn tại thời điểm và lịch sử biến động',icon:'history'},
    'UIF-12':{title:'Khởi tạo tồn đầu kỳ',subtitle:'Thiết lập số dư tồn kho ban đầu',icon:'inbox'},
    'CAP-01':{title:'Chính sách tồn & cận hạn',subtitle:'Thiết lập ngưỡng tồn và chính sách cảnh báo',icon:'shield'}
  };

  const ROLE_PROFILES={
    owner:{
      label:'Chủ cửa hàng',profile:'FULL',
      quick:['UIF-02','UIF-05','UIF-08','UIF-01'],
      capabilities:['UIF-01','UIF-02','UIF-05','UIF-06','UIF-07','UIF-08','UIF-09','UIF-11','UIF-16','UIF-03','UIF-13','UIF-14','UIF-15','UIF-12','CAP-01'],
      attention:[
        {type:'pending',mode:'approver',title:'Nhận hàng chờ phê duyệt',subtitle:'3 lần nhận đang chờ xử lý',count:'3',icon:'clock'},
        {flow:'UIF-09',title:'Lô sắp hết hạn',subtitle:'Cần kiểm tra trước khi bán hoặc xuất',count:'3 lô',icon:'shield'},
        {flow:'UIF-16',title:'Sai lệch cần đối soát',subtitle:'Tồn kho đang có chênh lệch cần xác minh',count:'1',icon:'search'},
        {flow:'UIF-17',title:'Nghiệp vụ chưa xác định kết quả',subtitle:'Cần xác minh trước khi thao tác tiếp',count:'1',icon:'rotate'}
      ]
    },
    warehouse:{
      label:'Thủ kho',profile:'WAREHOUSE',
      quick:['UIF-02','UIF-05','UIF-08','UIF-01'],
      capabilities:['UIF-01','UIF-02','UIF-05','UIF-06','UIF-07','UIF-08','UIF-09','UIF-11','UIF-16','UIF-15'],
      attention:[
        {type:'pending',mode:'maker',title:'Nhận hàng đang chờ duyệt',subtitle:'3 lần nhận đã gửi, tồn kho chưa thay đổi',count:'3',icon:'clock'},
        {flow:'UIF-09',title:'Lô sắp hết hạn',subtitle:'Cần kiểm tra trước khi bán hoặc xuất',count:'3 lô',icon:'shield'},
        {flow:'UIF-17',title:'Nghiệp vụ chưa xác định kết quả',subtitle:'Cần xác minh trước khi thao tác tiếp',count:'1',icon:'rotate'}
      ]
    },
    accounting:{
      label:'Kế toán',profile:'ACCOUNTING',
      quick:['UIF-03','UIF-13','UIF-14','UIF-15'],
      capabilities:['UIF-03','UIF-13','UIF-14','UIF-15','UIF-01','UIF-16'],
      attention:[
        {flow:'UIF-16',title:'Sai lệch cần đối soát',subtitle:'Tồn kho đang có chênh lệch cần xác minh',count:'1',icon:'search'}
      ]
    },
    sales:{
      label:'Nhân viên bán hàng',profile:'SALES',
      quick:['UIF-01','UIF-05'],
      capabilities:['UIF-01','UIF-05'],
      attention:[]
    }
  };

  function params(){return new URLSearchParams(location.search);}
  function isThemeInventory(){const q=params();return document.body.dataset.workbenchMode==='theme'&&q.get('app')==='inventory';}
  function isCandidate(){return isThemeInventory()&&params().get('hub')==='candidate';}
  function currentRole(){const key=params().get(ROLE_KEY)||DEFAULT_ROLE;return ROLE_PROFILES[key]?key:DEFAULT_ROLE;}
  function profile(){return ROLE_PROFILES[currentRole()];}
  function escLocal(value){return String(value??'').replace(/[&<>"']/g,(m)=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));}

  function quickButton(flow){
    const item=CAPABILITIES[flow];
    if(!item)return '';
    return `<button class="t462-quick-action" type="button" data-theme-entry-flow="${flow}" data-t462-quick="${flow}" data-t465-role-entry="${currentRole()}" data-ds-component="VQuickActionButton" data-ds-prop-state="Default"><span class="t462-quick-action__icon">${icon(item.icon,'icon--sm')}</span><span class="t462-quick-action__label">${escLocal(item.quickLabel||item.title)}</span></button>`;
  }

  function attentionButton(item){
    if(item.type==='pending'){
      return `<button class="t462-attention-row" type="button" data-v464-pending-approvals data-v465-pending-mode="${item.mode}" data-t465-role-entry="${currentRole()}"><span class="t462-attention-row__icon">${icon(item.icon,'icon--sm')}</span><span class="t462-attention-row__copy"><strong>${escLocal(item.title)}</strong><span>${escLocal(item.subtitle)}</span></span><span class="t462-attention-row__count">${escLocal(item.count)}</span></button>`;
    }
    return `<button class="t462-attention-row" type="button" data-theme-entry-flow="${item.flow}" data-t462-attention="${item.flow}" data-t465-role-entry="${currentRole()}"><span class="t462-attention-row__icon">${icon(item.icon,'icon--sm')}</span><span class="t462-attention-row__copy"><strong>${escLocal(item.title)}</strong><span>${escLocal(item.subtitle)}</span></span><span class="t462-attention-row__count">${escLocal(item.count)}</span></button>`;
  }

  function capabilityRow(flow){
    const item=CAPABILITIES[flow];
    if(!item)return '';
    return ds24ListRow({
      title:item.title,
      subtitle:item.subtitle,
      leading:item.icon,
      attrs:`data-theme-entry-flow="${flow}" data-t465-capability="${flow}" data-t465-role-entry="${currentRole()}"`,
      theme:'Theme7WarehouseFlatCapability',
      extraClass:'t462-capability-row t465-flat-capability-row'
    });
  }

  function applyPendingWorklistMode(){
    const p=profile();
    const pendingConfig=p.attention.find(item=>item.type==='pending');
    if(!pendingConfig)return;
    const rows=[...document.querySelectorAll('#app-screen [data-v464-pending-receipt]')];
    if(!rows.length)return;
    const maker=pendingConfig.mode==='maker';
    rows.forEach(row=>{
      row.setAttribute('data-t380-target-screen',maker?'SCR-010':'SCR-011');
      row.setAttribute('data-t380-context',maker?'bj02-pending-maker-view':'bj02-pending-approval');
      row.setAttribute('data-v465-pending-mode',pendingConfig.mode);
      const badge=row.querySelector('[data-ds-component="VBadge"], .ds24-badge, .v-badge');
      if(badge)badge.textContent=maker?'Đang chờ':'Chờ duyệt';
    });
    const title=document.querySelector('#app-screen .app-appbar-copy h3');
    if(title)title.textContent=maker?'Nhận hàng đang chờ duyệt':'Nhận hàng chờ phê duyệt';
  }

  function applyRoleProfile(){
    if(!isCandidate())return;
    const p=profile();
    const hub=document.querySelector('.t462-warehouse-hub');
    if(!hub){
      applyPendingWorklistMode();
      return;
    }
    hub.dataset.navigationProfile=p.profile;
    hub.dataset.reviewRole=currentRole();

    const quickGrid=hub.querySelector('.t462-quick-grid');
    if(quickGrid){
      quickGrid.innerHTML=p.quick.map(quickButton).join('');
      quickGrid.dataset.count=String(p.quick.length);
      quickGrid.classList.toggle('t465-quick-grid--two',p.quick.length===2);
    }

    const attentionList=hub.querySelector('.t462-attention-list');
    const attentionSection=attentionList?.closest('.t462-section');
    if(attentionList&&attentionSection){
      attentionList.innerHTML=p.attention.map(attentionButton).join('');
      attentionSection.hidden=p.attention.length===0;
    }

    const quickSet=new Set(p.quick);
    const flatFlows=p.capabilities.filter(flow=>!quickSet.has(flow));
    const list=hub.querySelector('.t462-workspace-list');
    const managementSection=list?.closest('.t462-section');
    if(list&&managementSection){
      list.classList.add('t465-flat-capability-list');
      list.innerHTML=flatFlows.map(capabilityRow).join('');
      managementSection.hidden=flatFlows.length===0;
    }

    // Setup is no longer a separate group. Its capabilities live in the flat management list when role allows them.
    const setupRow=hub.querySelector('[data-t462-workspace="setup"]');
    const setupSection=setupRow?.closest('.t462-section');
    if(setupSection)setupSection.hidden=true;
  }

  function installRoleControl(){
    const state=document.getElementById('state-switcher');
    if(!state)return;
    const existing=state.querySelector('[data-t465-role-switch]');
    if(!isCandidate()){
      if(existing)existing.remove();
      return;
    }
    const role=currentRole();
    const host=existing||document.createElement('div');
    host.className='t465-role-switch';
    host.setAttribute('data-t465-role-switch','');
    host.innerHTML=`<span class="t465-role-switch__label">Mô phỏng vai trò</span><div class="t465-role-switch__controls" role="group" aria-label="Chọn vai trò để review Hub Kho">${Object.entries(ROLE_PROFILES).map(([key,p])=>`<button type="button" data-t465-role="${key}" class="${key===role?'is-active':''}">${escLocal(p.label)}</button>`).join('')}</div><p class="t465-role-switch__note">Vai trò chỉ dùng để review khả năng nhìn thấy và ưu tiên trên Hub; quyền thực tế vẫn do contract/allowed actions quyết định.</p>`;
    if(!existing)state.appendChild(host);
  }

  function updateInspectorRole(){
    if(!isCandidate())return;
    const p=profile();
    const quickSet=new Set(p.quick);
    const flatFlows=p.capabilities.filter(flow=>!quickSet.has(flow));
    const trace=document.getElementById('traceability');
    if(trace){
      trace.innerHTML=`<div class="trace-row"><span>Review mode</span><strong>Hub Kho · Flat role-aware</strong></div><div class="trace-row"><span>Vai trò mô phỏng</span><strong>${escLocal(p.label)} · ${p.profile}</strong></div><div class="trace-row"><span>Quick action</span><strong>${p.quick.length} chức năng ưu tiên</strong></div><div class="trace-row"><span>Quản lý kho</span><strong>${flatFlows.length} chức năng · list phẳng · không lặp quick action</strong></div><div class="trace-row"><span>Permission</span><strong>Prototype chỉ mô phỏng visibility; server contract vẫn authoritative</strong></div>`;
    }
    const rationale=document.getElementById('design-rationale');
    if(rationale)rationale.textContent='Hub Kho dùng một danh sách Quản lý kho phẳng thay cho các workspace trung gian. Mỗi vai trò chỉ thấy chức năng phù hợp; chức năng đã nổi lên thành Quick Action không lặp lại ở list. Các capability contextual-only như tiêu hủy, phục hồi UNKNOWN hoặc actor handoff vẫn chỉ xuất hiện từ đúng context.';
  }

  function setRole(role){
    if(!ROLE_PROFILES[role])role=DEFAULT_ROLE;
    const u=new URL(location.href);
    u.searchParams.set(ROLE_KEY,role);
    u.searchParams.delete('hubView');
    history.replaceState(null,'',u);
    render();
  }

  renderAppScreen=function(){
    previousRenderAppScreen();
    applyRoleProfile();
  };
  renderInspector=function(){
    previousRenderInspector();
    installRoleControl();
    updateInspectorRole();
  };
  syncReviewUrl=function(){
    previousSyncReviewUrl();
    const u=new URL(location.href);
    if(isCandidate())u.searchParams.set(ROLE_KEY,currentRole());
    else u.searchParams.delete(ROLE_KEY);
    history.replaceState(null,'',u);
  };

  window.addEventListener('click',(event)=>{
    const button=event.target.closest?.('[data-t465-role]');
    if(!button||!isCandidate())return;
    event.preventDefault();
    event.stopImmediatePropagation();
    setRole(button.dataset.t465Role);
  },true);

  const badge=document.querySelector('.review-meta > .review-badge:not(.review-badge--muted)');
  if(badge)badge.textContent='v4.6.5 · Flat role-aware Warehouse Hub';
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.navigationProfiles=Object.fromEntries(Object.entries(ROLE_PROFILES).map(([key,p])=>[key,{label:p.label,profile:p.profile,quick:p.quick,capabilities:p.capabilities}]));
    window.__VET45_PROTOTYPE__.scenarios=[...(window.__VET45_PROTOTYPE__.scenarios||[]),'warehouse-hub-flat-management-list','warehouse-role-profile-owner','warehouse-role-profile-warehouse','warehouse-role-profile-accounting','warehouse-role-profile-sales','warehouse-no-duplicate-quick-actions'];
  }
  render();
})();
