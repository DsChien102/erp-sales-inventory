/* VET45 Theme 7 v4.6.6 — BJ/UIF role simulation in review workbench
 * Scope: review workbench only.
 * Role choices are derived only from existing screen.actors metadata.
 * No product permission, business rule, state transition, CTA, mutation, BJ/UC/UIF semantics are changed.
 */
(()=>{
  const VERSION='4.6.6';
  const ROLE_KEY='bjRole';
  const previousRenderNavigation=renderNavigation;
  const previousRenderInspector=renderInspector;
  const previousSyncReviewUrl=syncReviewUrl;

  function params(){return new URLSearchParams(location.search);}
  function isBjMode(){return params().get('mode')!=='theme';}
  function actorsOf(screen){
    const raw=screen?.actors;
    if(Array.isArray(raw)) return [...new Set(raw.filter(Boolean).map(String))];
    return raw?[String(raw)]:[];
  }
  function roleMap(){
    const map=new Map();
    flowScreens().forEach((screen)=>actorsOf(screen).forEach((role)=>{
      if(!map.has(role))map.set(role,[]);
      map.get(role).push(screen.id);
    }));
    return map;
  }
  function flowRoles(){return [...roleMap().keys()];}
  function fallbackRole(){
    const currentActors=actorsOf(currentScreen());
    if(currentActors.length)return currentActors[0];
    return flowRoles()[0]||'';
  }
  function currentRole(){
    const requested=params().get(ROLE_KEY)||'';
    return flowRoles().includes(requested)?requested:fallbackRole();
  }
  function escRole(value){return String(value??'').replace(/[&<>"']/g,(m)=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));}

  function applyNavigationRoleContext(){
    if(!isBjMode())return;
    const role=currentRole();
    if(!role)return;
    document.querySelectorAll('#screen-navigation [data-screen]').forEach((button)=>{
      const screen=screens.find((item)=>item.id===button.dataset.screen);
      const matches=actorsOf(screen).includes(role);
      button.classList.toggle('t466-screen-role-match',matches);
      button.classList.toggle('t466-screen-role-other',!matches);
      button.dataset.t466RoleMatch=String(matches);
      button.setAttribute('aria-description',matches?`Màn có vai trò ${role}`:`Màn thuộc vai trò khác trong cùng BJ`);
    });
  }

  function installBjRoleControl(){
    const state=document.getElementById('state-switcher');
    if(!state)return;
    const existing=state.querySelector('[data-t466-bj-role-switch]');
    const roles=flowRoles();
    if(!isBjMode()||roles.length===0){if(existing)existing.remove();return;}
    const selected=currentRole();
    const host=existing||document.createElement('div');
    host.className='t466-bj-role-switch';
    host.setAttribute('data-t466-bj-role-switch','');
    host.innerHTML=`<span class="t466-bj-role-switch__label">Mô phỏng vai trò</span><div class="t466-bj-role-switch__controls" role="group" aria-label="Chọn vai trò để review BJ hiện tại">${roles.map((role)=>`<button type="button" data-t466-bj-role="${escRole(role)}" class="${role===selected?'is-active':''}">${escRole(role)}</button>`).join('')}</div><p class="t466-bj-role-switch__note">Vai trò lấy từ Screen Contract hiện có. Chỉ đổi ngữ cảnh review; không thay quyền hoặc logic nghiệp vụ.</p>`;
    if(!existing)state.appendChild(host);
  }

  function updateBjRoleTrace(){
    if(!isBjMode())return;
    const trace=document.getElementById('traceability');
    if(!trace)return;
    trace.querySelectorAll('[data-t466-bj-role-trace]').forEach((node)=>node.remove());
    const role=currentRole();
    const screenActors=actorsOf(currentScreen());
    if(!role)return;
    trace.insertAdjacentHTML('beforeend',`<div class="trace-row" data-t466-bj-role-trace><span>Vai trò mô phỏng</span><strong>${escRole(role)}</strong></div><div class="trace-row" data-t466-bj-role-trace><span>Vai trò của màn</span><strong>${escRole(screenActors.join(' · ')||'—')}</strong></div><div class="trace-row" data-t466-bj-role-trace><span>Nguồn</span><strong>Screen Contract · actors</strong></div>`);
  }

  function setBjRole(role){
    const map=roleMap();
    if(!map.has(role))return;
    const url=new URL(location.href);
    url.searchParams.set(ROLE_KEY,role);
    history.replaceState(null,'',url);
    const currentActors=actorsOf(currentScreen());
    if(!currentActors.includes(role)){
      const candidates=map.get(role).map((id)=>screens.find((item)=>item.id===id)).filter(Boolean);
      const dedicated=candidates.find((screen)=>{const a=actorsOf(screen);return a.length===1&&a[0]===role;});
      const targetId=(dedicated||candidates[0])?.id;
      if(targetId&&targetId!==activeScreenId){
        activeScreenId=targetId;
        syncReviewUrl();
        render();
        return;
      }
    }
    syncReviewUrl();
    render();
  }

  renderNavigation=function(){
    previousRenderNavigation();
    applyNavigationRoleContext();
  };
  renderInspector=function(){
    previousRenderInspector();
    installBjRoleControl();
    updateBjRoleTrace();
  };
  syncReviewUrl=function(){
    previousSyncReviewUrl();
    const url=new URL(location.href);
    const mode=url.searchParams.get('mode');
    if(mode==='theme')url.searchParams.delete(ROLE_KEY);
    else{
      const role=currentRole();
      if(role)url.searchParams.set(ROLE_KEY,role);
      else url.searchParams.delete(ROLE_KEY);
    }
    history.replaceState(null,'',url);
  };

  window.addEventListener('click',(event)=>{
    const button=event.target.closest?.('[data-t466-bj-role]');
    if(!button||!isBjMode())return;
    event.preventDefault();
    event.stopImmediatePropagation();
    setBjRole(button.dataset.t466BjRole);
  },true);

  const badge=document.querySelector('.review-meta > .review-badge:not(.review-badge--muted)');
  if(badge)badge.textContent='v4.6.6 · Role simulation across Hub + BJ';
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.bjRoleSimulation={source:'screen.actors',workbenchOnly:true,changesBusinessLogic:false};
    window.__VET45_PROTOTYPE__.scenarios=[...(window.__VET45_PROTOTYPE__.scenarios||[]),'bj-role-simulation-from-screen-actors'];
  }
  render();
})();
