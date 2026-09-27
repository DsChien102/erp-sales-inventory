/* VET45 Theme 7 v3.7.1 — flat hub + progressive disclosure navigation
 * Parent: v3.7.0
 * Goal: keep the two-tab workbench and integrated Thêm → Kho entry, but remove the
 * "business architecture = navigation architecture" anti-pattern from the Kho root.
 * The Kho screen becomes one flat task hub: priority work + frequent destinations +
 * inline progressive disclosure. Visual grouping never creates an intermediate route.
 */
(()=>{
  const VERSION="3.7.1";
  let moreExpanded=false;

  const currentRenderAppScreen=renderAppScreen;
  const currentRenderInspector=renderInspector;

  const META={
    "UIF-01":{label:"Tồn kho",subtitle:"Xem tồn, khả dụng, lô và chỉ báo cần chú ý",icon:"warehouse"},
    "UIF-02":{label:"Nhận hàng mua",subtitle:"Nhận hàng theo chứng từ hoặc nhập nhanh",icon:"cloudUpload"},
    "UIF-03":{label:"Xác nhận giá nhập",subtitle:"Xác nhận giá trị ban đầu của hàng nhận",icon:"checkCircle"},
    "UIF-04":{label:"Giữ hàng theo đơn bán",subtitle:"Xem và quản lý vòng đời hàng đang giữ",icon:"lock"},
    "UIF-05":{label:"Lấy hàng & bàn giao",subtitle:"Chuẩn bị và bàn giao hàng cho đơn bán",icon:"package"},
    "UIF-06":{label:"Hàng khách trả",subtitle:"Tiếp nhận và phân loại hàng khách trả",icon:"rotate"},
    "UIF-07":{label:"Trả nhà cung cấp",subtitle:"Chuẩn bị và thực hiện trả hàng cho nhà cung cấp",icon:"arrowLeft"},
    "UIF-08":{label:"Kiểm kê kho",subtitle:"Đếm, duyệt và điều chỉnh chênh lệch",icon:"listCheck"},
    "UIF-09":{label:"Tình trạng hàng",subtitle:"Quản lý trạng thái bán, hỏng và dùng thử",icon:"shield"},
    "UIF-10":{label:"Tiêu hủy hàng",subtitle:"Kiểm soát và hoàn tất tiêu hủy",icon:"xCircle"},
    "UIF-11":{label:"Hủy & sửa sai nghiệp vụ",subtitle:"Xử lý nghiệp vụ kho cần hủy hoặc sửa sai",icon:"edit"},
    "UIF-12":{label:"Khởi tạo tồn đầu kỳ",subtitle:"Thiết lập số dư tồn kho ban đầu",icon:"inbox"},
    "UIF-13":{label:"Chi phí mua bổ sung",subtitle:"Ghi nhận chi phí mua phát sinh đến muộn",icon:"fileText"},
    "UIF-14":{label:"Giá vốn",subtitle:"Tính, rà soát và công bố giá vốn",icon:"layers"},
    "UIF-15":{label:"Báo cáo tồn & thẻ kho",subtitle:"Tra cứu báo cáo tồn và lịch sử biến động",icon:"history"},
    "UIF-16":{label:"Đối soát sai lệch",subtitle:"Điều tra và đối chiếu sai lệch tồn kho",icon:"search"},
    "UIF-17":{label:"Xác minh kết quả",subtitle:"Phục hồi nghiệp vụ có kết quả chưa xác định",icon:"rotate"},
    "CAP-01":{label:"Chính sách tồn & cận hạn",subtitle:"Thiết lập ngưỡng tồn và chính sách cận hạn",icon:"shield"},
  };

  const FREQUENT=["UIF-01","UIF-02","UIF-05","UIF-06","UIF-08","UIF-14","UIF-15"];
  const MORE_GROUPS=[
    {title:"Vận hành khác",ids:["UIF-07"]},
    {title:"Giá trị & giá vốn",ids:["UIF-03","UIF-13"]},
    {title:"Kiểm kê & kiểm soát",ids:["UIF-09","UIF-10","UIF-11","UIF-16","UIF-17"]},
    {title:"Liên quan & thiết lập",ids:["UIF-12","UIF-04","CAP-01"]},
  ];
  const PRIORITY=[
    {flow:"UIF-02",title:"2 phiếu nhận hàng có thể xử lý",subtitle:"Nhận hàng mua",badge:"2",tone:"Success",icon:"cloudUpload"},
    {flow:"UIF-08",title:"1 phiên kiểm kê đang thực hiện",subtitle:"Kiểm kê kho",badge:"Đang đếm",tone:"Info",icon:"listCheck"},
  ];

  function inThemeInventory(){
    const q=new URLSearchParams(location.search);
    return document.body.dataset.workbenchMode==="theme" && q.get("app")==="inventory";
  }

  function row(flowId,{title=null,subtitle=null,badge=null,tone="Neutral",iconName=null,extraClass=""}={}){
    const m=META[flowId];
    if(!m) return "";
    return ds24ListRow({
      title:title||m.label,
      subtitle:subtitle||m.subtitle,
      leading:iconName||m.icon,
      trailing:badge?ds24Badge(badge,tone):"",
      attrs:`data-theme-entry-flow="${flowId}"`,
      theme:"Theme7HubNavigation",
      extraClass
    });
  }

  function section(title,content,extra=""){
    return `<section class="t7-hub-section ${extra}" data-ds-component="VSection"><h2 class="t7-hub-section-title" data-ds-component="VText" data-ds-prop-style="Label/Default">${esc(title)}</h2>${content}</section>`;
  }

  function bottomNav(){
    return `<nav class="t7-app-bottom-nav" aria-label="Điều hướng chính" data-theme-component="VET45BottomNavigation">
      <button type="button" disabled aria-label="Trang chủ">${icon("warehouse","icon--sm")}<span>Trang chủ</span></button>
      <button type="button" disabled aria-label="Bán hàng">${icon("package","icon--sm")}<span>Bán hàng</span></button>
      <button type="button" disabled aria-label="Đơn hàng">${icon("fileText","icon--sm")}<span>Đơn hàng</span></button>
      <button type="button" disabled aria-label="Đối tác">${icon("user","icon--sm")}<span>Đối tác</span></button>
      <button type="button" class="is-active" aria-current="page" data-theme-sidebar-route="more" aria-label="Thêm">${icon("more","icon--sm")}<span>Thêm</span></button>
    </nav>`;
  }

  function shell(body){
    return `<div class="v-page-scaffold figma-calibrated-shell t7-integrated-shell t7-flat-hub-shell" data-mobile-product data-product-app data-inspectable="true" data-ds-component="VPageScaffold" data-ds-profile="screen.shell.standard" data-ds-prop-title="Kho" data-ds-prop-center-title="false">
      ${statusBar()}
      <header class="app-header"><div class="app-appbar has-back" data-ds-component="VAppBar" data-ds-prop-center-title="false" data-ds-prop-actions="null" data-ds-prop-show-back-button="true">
        <button class="app-icon-button app-back-button" data-theme-app-back type="button" aria-label="Quay lại" data-ds-internal="VAppBar.leading">${icon("chevronLeft","icon--24")}</button>
        <div class="app-appbar-copy" data-ds-component="VAppBarTitle"><h3>Kho</h3></div>
      </div></header>
      <div class="app-content" data-ds-component="VPagePadding" data-ds-profile="screen.body.standard"><div class="body-stack">${body}</div></div>
      ${bottomNav()}
    </div>`;
  }

  function moreContent(){
    if(!moreExpanded) return "";
    return `<div class="t7-hub-more" data-theme-hub-more-content>${MORE_GROUPS.map(g=>`<div class="t7-hub-subgroup"><h3 class="t7-hub-subgroup-title">${esc(g.title)}</h3><div class="ds24-list-stack">${g.ids.map(id=>row(id)).join("")}</div></div>`).join("")}</div>`;
  }

  function renderFlatHub(){
    const priorityRows=PRIORITY.map(x=>row(x.flow,{title:x.title,subtitle:x.subtitle,badge:x.badge,tone:x.tone,iconName:x.icon,extraClass:"t7-hub-priority-row"})).join("");
    const frequentRows=FREQUENT.map(id=>row(id)).join("");
    const hiddenCount=MORE_GROUPS.reduce((n,g)=>n+g.ids.length,0);
    const disclosure=`<button class="ds24-button ds24-button--secondary t7-hub-disclosure" type="button" data-theme-hub-toggle data-ds-component="VButton" data-figma-node="521:529" aria-expanded="${moreExpanded}">${icon("chevronDown","icon--sm")}<span>${moreExpanded?"Thu gọn":`Xem thêm ${hiddenCount} nghiệp vụ`}</span></button>`;
    const body=`${section("Cần xử lý",`<div class="ds24-list-stack t7-hub-priority-list">${priorityRows}</div>`,"t7-hub-section--priority")}
      ${section("Dùng thường xuyên",`<div class="ds24-list-stack t7-hub-frequent-list">${frequentRows}</div>`)}
      ${section("Nghiệp vụ khác",`${disclosure}${moreContent()}`,"t7-hub-section--more")}`;
    return shell(body);
  }

  renderAppScreen=function(){
    currentRenderAppScreen();
    if(inThemeInventory()){
      const app=document.getElementById("app-screen");
      if(app) app.innerHTML=renderFlatHub();
    }
  };

  renderInspector=function(){
    currentRenderInspector();
    if(!inThemeInventory()) return;
    const trace=document.getElementById("traceability");
    if(trace) trace.innerHTML=`<div class="trace-row"><span>Entry</span><strong>Thêm → Kho</strong></div><div class="trace-row"><span>IA pattern</span><strong>Flat hub · priority + frequent + inline disclosure</strong></div><div class="trace-row"><span>Navigation depth</span><strong>Kho → BJ (không có category route)</strong></div><div class="trace-row"><span>Coverage</span><strong>17 BJ + CAP-01</strong></div>`;
    const rationale=document.getElementById("design-rationale");
    if(rationale) rationale.textContent="Kho là một task hub phẳng. Các nhóm chỉ tạo hierarchy thị giác; entry thường dùng đi thẳng vào BJ. Nghiệp vụ ít dùng được mở rộng ngay trên cùng màn hình, không push thêm navigation level.";
  };

  document.addEventListener("click",event=>{
    const toggle=event.target.closest("[data-theme-hub-toggle]");
    if(!toggle || !inThemeInventory()) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    moreExpanded=!moreExpanded;
    render();
  },true);

  const badge=document.querySelector(".review-meta > .review-badge:not(.review-badge--muted)");
  if(badge) badge.textContent="v3.7.1 · flat Theme 7 hub · 17 BJ + CAP-01";
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.scenarios=[...(window.__VET45_PROTOTYPE__.scenarios||[]),"flat-theme-hub","priority-work-surface","inline-progressive-disclosure"];
  }
  render();
})();
