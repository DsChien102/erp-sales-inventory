/* VET45 Theme 7 v4.6.4 — Navigation contract alignment
 * Scope: review-workbench/runtime metadata only. Product UI stays visually identical to v4.6.3.
 */
(()=>{
  const VERSION='4.6.4';
  const NAV_SCREENS=['SCR-090','SCR-091','SCR-092','SCR-093','SCR-094','SCR-095','SCR-096'];
  const VIEW_TO_SCREEN={home:'SCR-090',inventory:'SCR-091',movement:'SCR-092',control:'SCR-093',valuation:'SCR-094',history:'SCR-095',setup:'SCR-096'};
  const VIEW_TO_NAME={home:'Kho',inventory:'Tồn kho',movement:'Nhập, xuất & hoàn trả',control:'Kiểm kê & xử lý',valuation:'Giá trị kho',history:'Báo cáo & lịch sử',setup:'Thiết lập kho'};
  const previousRenderInspector=renderInspector;

  function candidateContext(){
    const q=new URLSearchParams(location.search);
    if(document.body.dataset.workbenchMode!=='theme'||q.get('app')!=='inventory'||q.get('hub')!=='candidate')return null;
    const view=q.get('hubView')||'home';
    return {view,screen:VIEW_TO_SCREEN[view]||'SCR-090',name:VIEW_TO_NAME[view]||'Kho'};
  }

  renderInspector=function(){
    previousRenderInspector();
    const ctx=candidateContext();
    if(!ctx)return;
    const panel=document.querySelector('[data-t462-hub-switch]');
    if(panel){
      const note=panel.querySelector('.t462-hub-switch__note');
      if(note)note.textContent='Candidate Hub đã được formalize bằng PAT-NAV và SCR-090–SCR-096; Hub cũ vẫn giữ để so sánh.';
    }
    const id=document.getElementById('current-screen-id');
    const name=document.getElementById('current-screen-name');
    if(id)id.textContent=ctx.screen;
    if(name)name.textContent=ctx.name;
    const trace=document.getElementById('traceability');
    if(trace){
      trace.innerHTML=`<div class="trace-row"><span>Screen</span><strong>${ctx.screen}</strong></div><div class="trace-row"><span>Screen class</span><strong>NAVIGATION</strong></div><div class="trace-row"><span>Authority</span><strong>PAT-NAV</strong></div><div class="trace-row"><span>Business trace</span><strong>Destination → UIF → BJ/UC</strong></div><div class="trace-row"><span>Prototype</span><strong>v4.6.3 visual · v4.6.4 contract alignment</strong></div>`;
    }
    const rationale=document.getElementById('design-rationale');
    if(rationale)rationale.textContent='Navigation surface không sở hữu BJ/UC/UIF riêng. PAT-NAV sở hữu IA; từng entry trace xuống business destination và flow hiện hữu.';
  };

  const badge=document.querySelector('.review-meta > .review-badge:not(.review-badge--muted)');
  if(badge)badge.textContent='v4.6.4 · Navigation IA contract';
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.screens=[...new Set([...(window.__VET45_PROTOTYPE__.screens||[]),...NAV_SCREENS])];
    window.__VET45_PROTOTYPE__.scenarios=[...(window.__VET45_PROTOTYPE__.scenarios||[]),'warehouse-navigation-contract-v4.6.4'];
  }
  render();
})();
