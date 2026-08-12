/* VET45 Theme 7 v3.8.2 — Warehouse Home action hierarchy correction
 * Parent: v3.8.1
 * Goal: keep "Tạo thao tác" available without presenting it as the global primary CTA
 * after the Tra cứu section. It belongs to the work context: continue assigned work or
 * explicitly start a new warehouse task. The exhaustive catalog remains a secondary route.
 */
(()=>{
  const VERSION="3.8.2";
  const currentRenderAppScreen=renderAppScreen;
  const currentRenderInspector=renderInspector;

  function params(){return new URLSearchParams(location.search);}
  function isThemeInventory(){const q=params();return document.body.dataset.workbenchMode==="theme"&&q.get("app")==="inventory";}

  function arrangeWarehouseHome(){
    if(!isThemeInventory())return;
    const home=document.querySelector('#app-screen .t380-warehouse-home');
    if(!home)return;
    const work=home.querySelector('.t380-work-section');
    const createSection=home.querySelector('.t380-create-section');
    const createButton=createSection?.querySelector('[data-t380-manual-open]');
    if(!work||!createButton)return;

    let actions=work.querySelector('.t382-work-actions');
    if(!actions){
      actions=document.createElement('div');
      actions.className='t382-work-actions';
      actions.setAttribute('data-layout-role','warehouse-work-actions');
      work.appendChild(actions);
    }

    const toggle=work.querySelector('.t380-inline-toggle');
    if(toggle&&toggle.parentElement!==actions)actions.appendChild(toggle);

    createButton.classList.remove('ds24-button--primary','t380-create-button');
    createButton.classList.add('ds24-button--secondary','t382-create-action');
    createButton.setAttribute('data-ds-prop-variant','Secondary');
    createButton.setAttribute('aria-label','Tạo thao tác kho mới');
    if(createButton.parentElement!==actions)actions.appendChild(createButton);

    createSection.remove();
  }

  renderAppScreen=function(){
    currentRenderAppScreen();
    arrangeWarehouseHome();
  };

  renderInspector=function(){
    currentRenderInspector();
    if(!isThemeInventory())return;
    const trace=document.getElementById('traceability');
    const rationale=document.getElementById('design-rationale');
    if(trace&&!document.querySelector('#app-screen .t381-catalog-screen')){
      trace.insertAdjacentHTML('beforeend','<div class="trace-row"><span>Action hierarchy</span><strong>Tạo thao tác nằm cùng ngữ cảnh Việc của bạn · Secondary</strong></div>');
    }
    if(rationale&&!document.querySelector('#app-screen .t381-catalog-screen')){
      rationale.textContent='Kho ưu tiên tiếp tục công việc đang có. “Tạo thao tác” là lựa chọn phụ để chủ động bắt đầu việc mới nên được đặt cùng khu vực Việc của bạn với mức nhấn Secondary, không đứng thành CTA chính sau phần Tra cứu. Tất cả chức năng kho vẫn là đường discoverability phụ ở cuối màn.';
    }
  };

  const badge=document.querySelector('.review-meta > .review-badge:not(.review-badge--muted)');
  if(badge)badge.textContent='v3.8.2 · task-driven Kho · corrected action hierarchy';
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.scenarios=[...(window.__VET45_PROTOTYPE__.scenarios||[]),'warehouse-action-hierarchy','manual-action-secondary-placement'];
  }
  render();
})();
