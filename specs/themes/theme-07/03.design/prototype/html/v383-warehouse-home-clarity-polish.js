/* VET45 Theme 7 v3.8.3 — Warehouse Home clarity polish
 * Parent: v3.8.2
 * Goals:
 *   1) Replace the visually mismatched inline disclosure + CTA action row with a section-level
 *      "Xem tất cả (5)" action and one canonical Navigation List Row for starting new work.
 *   2) Rename system-centric "Tạo thao tác" to user-centric "Bắt đầu việc mới".
 *   3) Remove explanatory badges from the full-function catalog; use row state/copy for context.
 */
(()=>{
  const VERSION="3.8.3";
  const currentRenderAppScreen=renderAppScreen;
  const currentRenderInspector=renderInspector;

  function params(){return new URLSearchParams(location.search);}
  function isThemeInventory(){const q=params();return document.body.dataset.workbenchMode==="theme"&&q.get("app")==="inventory";}

  function polishWorkSection(){
    if(!isThemeInventory())return;
    const home=document.querySelector('#app-screen .t380-warehouse-home');
    if(!home)return;
    const work=home.querySelector('.t380-work-section');
    if(!work)return;

    const list=work.querySelector('.t380-work-list');
    const itemCount=list?.querySelectorAll('.t380-work-item').length||0;
    const expanded=itemCount>3;
    const total=5;

    // Replace count metadata + detached action row with one section-header disclosure action.
    const title=work.querySelector('.t380-section-title');
    if(title){
      title.querySelector('span')?.remove();
      let disclosure=title.querySelector('[data-t380-task-toggle]');
      if(!disclosure){
        disclosure=document.createElement('button');
        disclosure.type='button';
        disclosure.className='t383-task-overview-action';
        disclosure.setAttribute('data-t380-task-toggle','');
        disclosure.setAttribute('data-ds-component','VButton');
        disclosure.setAttribute('data-ds-prop-variant','VButtonVariant.link');
        title.appendChild(disclosure);
      }
      disclosure.setAttribute('aria-expanded',String(expanded));
      disclosure.textContent=expanded?'Thu gọn':`Xem tất cả (${total})`;
    }

    work.querySelector('.t382-work-actions')?.remove();
    work.querySelectorAll(':scope > .t380-inline-toggle').forEach(n=>n.remove());

    // A new user-initiated job is a destination choice, not a global CTA.
    let start=work.querySelector('[data-t383-start-new]');
    if(!start&&list){
      const holder=document.createElement('div');
      holder.innerHTML=ds24ListRow({
        title:'Bắt đầu việc mới',
        subtitle:'Nhập hàng nhanh, kiểm kê hoặc xử lý hàng',
        leading:null,
        attrs:'data-t380-manual-open data-t383-start-new',
        theme:'Theme7WarehouseStartNewWork',
        extraClass:'t383-start-new-row'
      });
      start=holder.firstElementChild;
      list.insertAdjacentElement('afterend',start);
    }
  }

  function polishManualSheet(){
    const sheet=document.querySelector('.t380-manual-sheet');
    if(!sheet)return;
    sheet.setAttribute('aria-label','Bắt đầu việc mới');
    const h=sheet.querySelector('.t380-sheet-heading h3');
    if(h)h.textContent='Bắt đầu việc mới';
    sheet.querySelectorAll('.t380-sheet-heading p, button[data-t380-manual-close]').forEach(n=>n.remove());
  }

  function polishCatalog(){
    const catalog=document.querySelector('#app-screen .t381-catalog-screen');
    if(!catalog)return;
    // Conditions such as "Khi có sai sót" are not object statuses; do not render them as badges.
    catalog.querySelectorAll('.t381-catalog-row .ds24-badge').forEach(n=>n.remove());

    // Reservation is contextual from Sales Order. Keep the canonical Navigation row anatomy,
    // represent unavailability through the DS Disabled state instead of a custom explanatory badge.
    const contextual=catalog.querySelector('[data-t381-catalog-flow="UIF-04"]');
    if(contextual){
      contextual.setAttribute('disabled','');
      contextual.setAttribute('aria-disabled','true');
      contextual.setAttribute('data-ds-prop-state','Disabled');
      contextual.removeAttribute('data-theme-entry-flow');
      const helper=contextual.querySelector('.ds24-list-row__copy small');
      if(helper)helper.textContent='Thực hiện từ chi tiết đơn bán';
    }
  }

  function apply(){
    polishWorkSection();
    polishManualSheet();
    polishCatalog();
  }

  renderAppScreen=function(){
    currentRenderAppScreen();
    apply();
  };

  renderInspector=function(){
    currentRenderInspector();
    if(!isThemeInventory())return;
    const catalog=!!document.querySelector('#app-screen .t381-catalog-screen');
    const trace=document.getElementById('traceability');
    const rationale=document.getElementById('design-rationale');
    if(catalog){
      if(trace)trace.insertAdjacentHTML('beforeend','<div class="trace-row"><span>Catalog semantics</span><strong>Không dùng badge để giải thích điều kiện truy cập</strong></div>');
      if(rationale)rationale.textContent='Danh mục đầy đủ chỉ phục vụ discoverability cho nghiệp vụ ít dùng. Các điều kiện như “từ đơn bán” hoặc “khi có sai lệch” không phải trạng thái object nên không dùng VBadge; capability chỉ mở từ ngữ cảnh khác được thể hiện bằng chính state Disabled của List Row.';
    }else{
      if(trace)trace.insertAdjacentHTML('beforeend','<div class="trace-row"><span>Work actions</span><strong>Section disclosure + Navigation row “Bắt đầu việc mới”</strong></div>');
      if(rationale)rationale.textContent='Kho ưu tiên công việc đã phát sinh. Xem tất cả là action của chính section Việc của bạn; khởi tạo việc mới là một Navigation List Row độc lập, không phải CTA cạnh tranh với disclosure. Cách gọi “Bắt đầu việc mới” mô tả ý định người dùng thay cho thuật ngữ hệ thống “Tạo thao tác”.';
    }
  };

  const badge=document.querySelector('.review-meta > .review-badge:not(.review-badge--muted)');
  if(badge)badge.textContent='v3.8.3 · task-driven Kho · clearer work hierarchy';
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.scenarios=[...(window.__VET45_PROTOTYPE__.scenarios||[]),'warehouse-section-disclosure','start-new-work-navigation-row','catalog-no-explanatory-badges'];
  }
  render();
})();
