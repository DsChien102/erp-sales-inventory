/* VET45 Theme 7 v4.6.5 — Role-aware Warehouse Hub review profiles
 * Scope: HTML prototype/workbench only. This is a navigation-focus simulation, not a permission contract.
 * PAT-NAV and SCR-090–SCR-096 remain the canonical IA/navigation contracts from v4.6.4.
 */
(()=>{
  const VERSION='4.6.5';
  const ROLE_KEY='hubRole';
  const DEFAULT_ROLE='owner';
  const previousRenderAppScreen=renderAppScreen;
  const previousRenderInspector=renderInspector;
  const previousSyncReviewUrl=syncReviewUrl;

  const ROLE_PROFILES={
    owner:{
      label:'Chủ cửa hàng',profile:'FULL',
      quick:[
        ['Nhận hàng','cloudUpload','UIF-02'],['Lấy hàng','package','UIF-05'],['Kiểm kê','listCheck','UIF-08'],['Tra cứu tồn','search','UIF-01']
      ],
      attention:[
        ['Lô sắp hết hạn','Cần kiểm tra trước khi bán hoặc xuất','3 lô','UIF-09','shield'],
        ['Sai lệch cần đối soát','Tồn kho đang có chênh lệch cần xác minh','1','UIF-16','search'],
        ['Nghiệp vụ chưa xác định kết quả','Cần xác minh trước khi thao tác tiếp','1','UIF-17','rotate']
      ],
      workspaces:['inventory','movement','control','valuation','history'],setup:true
    },
    warehouse:{
      label:'Thủ kho',profile:'WAREHOUSE',
      quick:[
        ['Nhận hàng','cloudUpload','UIF-02'],['Lấy hàng','package','UIF-05'],['Kiểm kê','listCheck','UIF-08'],['Xử lý hàng','shield','UIF-09']
      ],
      attention:[
        ['Lô sắp hết hạn','Cần kiểm tra trước khi bán hoặc xuất','3 lô','UIF-09','shield'],
        ['Nghiệp vụ chưa xác định kết quả','Cần xác minh trước khi thao tác tiếp','1','UIF-17','rotate']
      ],
      workspaces:['movement','inventory','control','history'],setup:false
    },
    accounting:{
      label:'Kế toán',profile:'ACCOUNTING',
      quick:[
        ['Xác nhận giá','checkCircle','UIF-03'],['Chi phí mua','fileText','UIF-13'],['Giá vốn','layers','UIF-14'],['Tra cứu tồn','search','UIF-01']
      ],
      attention:[
        ['Sai lệch cần đối soát','Tồn kho đang có chênh lệch cần xác minh','1','UIF-16','search']
      ],
      workspaces:['valuation','history','inventory','control'],setup:false
    },
    sales:{
      label:'Nhân viên bán hàng',profile:'SALES',
      quick:[['Tra cứu tồn','search','UIF-01']],
      attention:[],
      workspaces:['inventory'],setup:false
    }
  };

  function params(){return new URLSearchParams(location.search);}
  function isThemeInventory(){const q=params();return document.body.dataset.workbenchMode==='theme'&&q.get('app')==='inventory';}
  function isCandidate(){return isThemeInventory()&&params().get('hub')==='candidate';}
  function currentRole(){const key=params().get(ROLE_KEY)||DEFAULT_ROLE;return ROLE_PROFILES[key]?key:DEFAULT_ROLE;}
  function profile(){return ROLE_PROFILES[currentRole()];}
  function escLocal(value){return String(value??'').replace(/[&<>"']/g,(m)=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));}

  function quickButton([label,iconName,flow]){
    return `<button class="t462-quick-action" type="button" data-theme-entry-flow="${flow}" data-t462-quick="${flow}" data-t465-role-entry="${currentRole()}" data-ds-component="VQuickActionButton" data-ds-prop-state="Default"><span class="t462-quick-action__icon">${icon(iconName,'icon--sm')}</span><span class="t462-quick-action__label">${escLocal(label)}</span></button>`;
  }
  function attentionButton([title,subtitle,count,flow,iconName]){
    return `<button class="t462-attention-row" type="button" data-theme-entry-flow="${flow}" data-t462-attention="${flow}" data-t465-role-entry="${currentRole()}"><span class="t462-attention-row__icon">${icon(iconName,'icon--sm')}</span><span class="t462-attention-row__copy"><strong>${escLocal(title)}</strong><span>${escLocal(subtitle)}</span></span><span class="t462-attention-row__count">${escLocal(count)}</span></button>`;
  }

  function applyRoleProfile(){
    if(!isCandidate())return;
    const hub=document.querySelector('.t462-warehouse-hub');
    if(!hub)return; // role profile only changes the Hub; business/workspace destinations stay canonical.
    const p=profile();
    hub.dataset.navigationProfile=p.profile;
    hub.dataset.reviewRole=currentRole();

    const quickGrid=hub.querySelector('.t462-quick-grid');
    if(quickGrid){
      quickGrid.innerHTML=p.quick.map(quickButton).join('');
      quickGrid.classList.toggle('t465-quick-grid--single',p.quick.length===1);
    }

    const attentionList=hub.querySelector('.t462-attention-list');
    const attentionSection=attentionList?.closest('.t462-section');
    if(attentionList&&attentionSection){
      attentionList.innerHTML=p.attention.map(attentionButton).join('');
      attentionSection.hidden=p.attention.length===0;
    }

    const list=hub.querySelector('.t462-workspace-list');
    if(list){
      const rows=new Map([...list.querySelectorAll('[data-t462-workspace]')].map((row)=>[row.dataset.t462Workspace,row]));
      rows.forEach((row,id)=>{row.hidden=!p.workspaces.includes(id);});
      p.workspaces.forEach((id)=>{const row=rows.get(id);if(row)list.appendChild(row);});
    }

    const setupRow=hub.querySelector('[data-t462-workspace="setup"]');
    const setupSection=setupRow?.closest('.t462-section');
    if(setupSection)setupSection.hidden=!p.setup;
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
    host.innerHTML=`<span class="t465-role-switch__label">Mô phỏng vai trò</span><div class="t465-role-switch__controls" role="group" aria-label="Chọn vai trò để review Hub Kho">${Object.entries(ROLE_PROFILES).map(([key,p])=>`<button type="button" data-t465-role="${key}" class="${key===role?'is-active':''}">${p.label}</button>`).join('')}</div><p class="t465-role-switch__note">Chỉ mô phỏng mức ưu tiên và khả năng nhìn thấy trên Hub; chưa phải kiểm soát quyền.</p>`;
    if(!existing)state.appendChild(host);
  }

  function updateInspectorRole(){
    if(!isCandidate())return;
    const p=profile();
    const trace=document.getElementById('traceability');
    if(trace&&!trace.querySelector('[data-t465-trace-role]')){
      trace.insertAdjacentHTML('beforeend',`<div class="trace-row" data-t465-trace-role><span>Navigation profile</span><strong>${p.profile} · ${p.label}</strong></div><div class="trace-row" data-t465-trace-role><span>Permission</span><strong>Chưa mô phỏng phân quyền</strong></div>`);
    }
    const rationale=document.getElementById('design-rationale');
    if(rationale)rationale.textContent=`${rationale.textContent} Role profile chỉ thay đổi mức ưu tiên/visibility trên Hub để review UX; business destination, BJ/UC/UIF và permission contract không đổi.`;
  }

  function setRole(role){
    if(!ROLE_PROFILES[role])role=DEFAULT_ROLE;
    const u=new URL(location.href);
    u.searchParams.set(ROLE_KEY,role);
    history.replaceState(null,'',u);
    const back=document.querySelector('#app-screen [data-t462-workspace-back]');
    if(back){back.click();return;}
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
  if(badge)badge.textContent='v4.6.5 · Role-aware Hub review';
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.navigationProfiles=Object.fromEntries(Object.entries(ROLE_PROFILES).map(([key,p])=>[key,{label:p.label,profile:p.profile}]));
    window.__VET45_PROTOTYPE__.scenarios=[...(window.__VET45_PROTOTYPE__.scenarios||[]),'warehouse-role-profile-owner','warehouse-role-profile-warehouse','warehouse-role-profile-accounting','warehouse-role-profile-sales'];
  }
  render();
})();
