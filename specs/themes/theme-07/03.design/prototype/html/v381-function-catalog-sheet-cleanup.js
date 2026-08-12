/* VET45 Theme 7 v3.8.1 — secondary full-function access + bottom-sheet cleanup
 * Parent: v3.8.0
 * Goals:
 *   1) Keep Kho task-driven by default while restoring discoverability for all 17 BJ + CAP-01
 *      through one low-emphasis secondary route: "Tất cả chức năng kho".
 *   2) Keep long-tail discovery out of the primary Warehouse Home decision surface.
 *   3) Remove redundant "Đóng" CTA from dismissible/view-only bottom sheets. Stateful
 *      form/confirmation cancel actions remain because they protect user edits/decisions.
 */
(()=>{
  const VERSION="3.8.1";
  let catalogOpen=false;
  let catalogOrigin=false;
  const currentRenderAppScreen=renderAppScreen;
  const currentRenderInspector=renderInspector;

  const CATALOG={
    "UIF-01":{label:"Tồn kho",subtitle:"Tra cứu số lượng, lô và khả dụng",icon:"warehouse"},
    "UIF-02":{label:"Nhận hàng mua",subtitle:"Nhận hàng theo chứng từ hoặc nhập nhanh",icon:"cloudUpload"},
    "UIF-03":{label:"Xác nhận giá nhập",subtitle:"Xác nhận giá trị ban đầu của hàng nhận",icon:"checkCircle"},
    "UIF-04":{label:"Giữ hàng theo đơn bán",subtitle:"Theo dõi hàng giữ cho đơn bán",icon:"lock",badge:"Từ đơn bán",tone:"Neutral"},
    "UIF-05":{label:"Lấy hàng & bàn giao",subtitle:"Chuẩn bị và bàn giao hàng cho đơn bán",icon:"package"},
    "UIF-06":{label:"Hàng khách trả",subtitle:"Tiếp nhận và phân loại hàng khách trả",icon:"rotate"},
    "UIF-07":{label:"Trả nhà cung cấp",subtitle:"Chuẩn bị và thực hiện trả hàng",icon:"arrowLeft"},
    "UIF-08":{label:"Kiểm kê kho",subtitle:"Đếm, duyệt và xử lý chênh lệch",icon:"listCheck"},
    "UIF-09":{label:"Tình trạng hàng",subtitle:"Quản lý trạng thái bán, hỏng và dùng thử",icon:"shield"},
    "UIF-10":{label:"Tiêu hủy hàng",subtitle:"Kiểm soát và hoàn tất tiêu hủy",icon:"xCircle"},
    "UIF-11":{label:"Hủy & sửa sai nghiệp vụ",subtitle:"Xử lý nghiệp vụ kho cần hủy hoặc sửa",icon:"edit",badge:"Khi có sai sót",tone:"Neutral"},
    "UIF-12":{label:"Khởi tạo tồn đầu kỳ",subtitle:"Thiết lập số dư tồn kho ban đầu",icon:"inbox",badge:"Khởi tạo",tone:"Neutral"},
    "UIF-13":{label:"Chi phí mua bổ sung",subtitle:"Ghi nhận chi phí mua phát sinh đến muộn",icon:"fileText"},
    "UIF-14":{label:"Giá vốn",subtitle:"Tính, rà soát và công bố giá vốn",icon:"layers"},
    "UIF-15":{label:"Báo cáo & thẻ kho",subtitle:"Xem tồn tại thời điểm và lịch sử biến động",icon:"history"},
    "UIF-16":{label:"Đối soát sai lệch",subtitle:"Điều tra và đối chiếu sai lệch tồn kho",icon:"search",badge:"Khi có chênh lệch",tone:"Neutral"},
    "UIF-17":{label:"Xác minh kết quả",subtitle:"Xử lý nghiệp vụ có kết quả chưa xác định",icon:"rotate",badge:"Khi cần xác minh",tone:"Neutral"},
    "CAP-01":{label:"Chính sách tồn & cận hạn",subtitle:"Thiết lập ngưỡng tồn và chính sách cận hạn",icon:"shield",badge:"Thiết lập",tone:"Neutral"},
  };
  const GROUPS=[
    {title:"Tra cứu",ids:["UIF-01","UIF-15"]},
    {title:"Vận hành kho",ids:["UIF-02","UIF-05","UIF-06","UIF-07"]},
    {title:"Kiểm kê & chất lượng",ids:["UIF-08","UIF-09","UIF-10"]},
    {title:"Giá trị & giá vốn",ids:["UIF-03","UIF-13","UIF-14"]},
    {title:"Kiểm soát & khôi phục",ids:["UIF-11","UIF-16","UIF-17"]},
    {title:"Theo ngữ cảnh & thiết lập",ids:["UIF-04","UIF-12","CAP-01"]},
  ];

  function params(){return new URLSearchParams(location.search);}
  function isThemeInventory(){const q=params();return document.body.dataset.workbenchMode==="theme"&&q.get("app")==="inventory";}
  function isThemeFlow(){const q=params();return document.body.dataset.workbenchMode==="theme"&&q.get("app")==="flow";}

  function bottomNav(){
    return `<nav class="t7-app-bottom-nav" aria-label="Điều hướng chính" data-theme-component="VET45BottomNavigation">
      <button type="button" disabled aria-label="Trang chủ">${icon("warehouse","icon--sm")}<span>Trang chủ</span></button>
      <button type="button" disabled aria-label="Bán hàng">${icon("package","icon--sm")}<span>Bán hàng</span></button>
      <button type="button" disabled aria-label="Đơn hàng">${icon("fileText","icon--sm")}<span>Đơn hàng</span></button>
      <button type="button" disabled aria-label="Đối tác">${icon("user","icon--sm")}<span>Đối tác</span></button>
      <button type="button" class="is-active" aria-current="page" data-theme-sidebar-route="more" aria-label="Thêm">${icon("more","icon--sm")}<span>Thêm</span></button>
    </nav>`;
  }

  function catalogRow(id){
    const m=CATALOG[id];
    if(!m)return "";
    return ds24ListRow({
      title:m.label,
      subtitle:m.subtitle,
      leading:m.icon,
      trailing:m.badge?ds24Badge(m.badge,m.tone||"Neutral"):"",
      attrs:`data-theme-entry-flow="${id}" data-t381-catalog-flow="${id}"`,
      theme:"Theme7WarehouseFunctionCatalog",
      extraClass:"t381-catalog-row"
    });
  }

  function catalogScreen(){
    const sections=GROUPS.map(g=>`<section class="t381-catalog-section" data-ds-component="VSection"><h2 class="t381-catalog-section-title" data-ds-component="VText" data-ds-prop-style="Label/Default">${esc(g.title)}</h2><div class="ds24-list-stack">${g.ids.map(catalogRow).join("")}</div></section>`).join("");
    return `<div class="v-page-scaffold figma-calibrated-shell t7-integrated-shell t381-catalog-screen" data-mobile-product data-product-app data-inspectable="true" data-ds-component="VPageScaffold" data-ds-profile="screen.shell.standard" data-ds-prop-title="Tất cả chức năng kho" data-ds-prop-center-title="false">
      ${statusBar()}
      <header class="app-header"><div class="app-appbar has-back" data-ds-component="VAppBar" data-ds-prop-center-title="false" data-ds-prop-actions="null" data-ds-prop-show-back-button="true">
        <button class="app-icon-button app-back-button" data-t381-catalog-back type="button" aria-label="Quay về Kho" data-ds-internal="VAppBar.leading">${icon("chevronLeft","icon--24")}</button>
        <div class="app-appbar-copy" data-ds-component="VAppBarTitle"><h3>Tất cả chức năng kho</h3></div>
      </div></header>
      <div class="app-content" data-ds-component="VPagePadding" data-ds-profile="screen.body.standard"><div class="body-stack">${sections}</div></div>
      ${bottomNav()}
    </div>`;
  }

  function injectCatalogEntry(){
    if(!isThemeInventory()||catalogOpen)return;
    const home=document.querySelector('#app-screen .t380-warehouse-home');
    if(!home||home.querySelector('[data-t381-catalog-open]'))return;
    const stack=home.querySelector('.app-content .body-stack');
    if(!stack)return;
    const wrap=document.createElement('section');
    wrap.className='t380-section t381-catalog-entry-section';
    wrap.setAttribute('data-ds-component','VSection');
    wrap.innerHTML=ds24ListRow({
      title:'Tất cả chức năng kho',
      subtitle:'Xem các chức năng và thiết lập khác',
      leading:'listCheck',
      attrs:'data-t381-catalog-open',
      theme:'Theme7WarehouseFunctionCatalogEntry',
      extraClass:'t381-catalog-entry-row'
    });
    stack.appendChild(wrap);
  }

  function cleanupDismissibleSheets(){
    // Manual action chooser: heading is self-explanatory; backdrop/handle/system Back dismiss the sheet.
    document.querySelectorAll('.t380-manual-sheet .t380-sheet-heading > p').forEach(n=>n.remove());
    document.querySelectorAll('.t380-manual-sheet button[data-t380-manual-close]').forEach(n=>n.remove());

    // Read-only/detail/select sheets that already have backdrop dismissal should not spend a CTA on "Đóng".
    document.querySelectorAll('.bj02-review-detail-sheet .bj02-review-close-button').forEach(n=>n.remove());
    document.querySelectorAll('.ds24-select-sheet button[data-ic08-action="select-close"]').forEach(n=>n.remove());
    document.querySelectorAll('.cf15-sheet button[data-cf15-action="close-product-sheet"], .ac310-sheet button[data-cf15-action="close-product-sheet"]').forEach(n=>n.remove());

    document.querySelectorAll('.cf15-sheet .sheet-actions, .ac310-sheet .sheet-actions').forEach(actions=>{
      if(actions.children.length===1)actions.classList.add('t381-single-business-action');
    });
  }

  renderAppScreen=function(){
    currentRenderAppScreen();
    if(isThemeInventory()){
      const app=document.getElementById('app-screen');
      if(catalogOpen&&app)app.innerHTML=catalogScreen();
      else injectCatalogEntry();
    }
    cleanupDismissibleSheets();
  };

  renderInspector=function(){
    currentRenderInspector();
    if(!isThemeInventory())return;
    const trace=document.getElementById('traceability');
    const rationale=document.getElementById('design-rationale');
    if(catalogOpen){
      if(trace)trace.innerHTML=`<div class="trace-row"><span>Entry</span><strong>Kho → Tất cả chức năng kho</strong></div><div class="trace-row"><span>Role</span><strong>Secondary discoverability</strong></div><div class="trace-row"><span>Coverage</span><strong>17 BJ + CAP-01</strong></div><div class="trace-row"><span>Primary Home</span><strong>Vẫn task-driven</strong></div>`;
      if(rationale)rationale.textContent='Danh mục đầy đủ là đường phụ để tìm nghiệp vụ hiếm hoặc hiểu phạm vi Kho. Màn Kho chính vẫn ưu tiên công việc cụ thể và thao tác chủ động; catalog không thay thế Warehouse Home.';
    }else{
      if(trace)trace.insertAdjacentHTML('beforeend','<div class="trace-row"><span>Secondary access</span><strong>Tất cả chức năng kho</strong></div>');
      if(rationale)rationale.textContent='Kho ưu tiên công việc cụ thể, tra cứu và thao tác chủ động. Một entry phụ ở cuối màn bảo đảm các chức năng hiếm vẫn discoverable mà không làm tăng decision load của luồng thường ngày.';
    }
  };

  // Window capture executes before the v3.7 document-level router.
  window.addEventListener('click',event=>{
    const open=event.target.closest?.('[data-t381-catalog-open]');
    if(open&&isThemeInventory()){
      event.preventDefault();event.stopPropagation();catalogOpen=true;catalogOrigin=false;render();return;
    }
    const back=event.target.closest?.('[data-t381-catalog-back]');
    if(back&&isThemeInventory()){
      event.preventDefault();event.stopPropagation();catalogOpen=false;catalogOrigin=false;render();return;
    }
    const flow=event.target.closest?.('[data-t381-catalog-flow]');
    if(flow&&isThemeInventory()){
      catalogOrigin=true;catalogOpen=false;
      return; // v3.7 router consumes data-theme-entry-flow.
    }
    if(catalogOrigin&&isThemeFlow()&&event.target.closest?.('[data-theme-app-back-to-inventory]')){
      catalogOpen=true;catalogOrigin=false;
      return; // v3.7 router goes to inventory; v3.8.1 renderer restores the catalog.
    }
    if(event.target.closest?.('[data-workbench-mode],[data-theme-sidebar-route="more"],[data-theme-app-route="inventory"]')){
      if(!event.target.closest?.('[data-theme-app-back-to-inventory]')){catalogOpen=false;catalogOrigin=false;}
    }
  },true);

  // Escape dismisses the manual chooser through its existing backdrop close contract.
  window.addEventListener('keydown',event=>{
    if(event.key!=="Escape")return;
    const overlay=document.querySelector('.t380-manual-overlay[data-t380-manual-close]');
    if(overlay){event.preventDefault();overlay.click();}
  },true);

  const badge=document.querySelector('.review-meta > .review-badge:not(.review-badge--muted)');
  if(badge)badge.textContent='v3.8.1 · task-driven Kho + full-function secondary access';
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.scenarios=[...(window.__VET45_PROTOTYPE__.scenarios||[]),'warehouse-secondary-function-catalog','dismissible-sheet-no-close-cta','long-tail-discoverability'];
  }
  render();
})();
