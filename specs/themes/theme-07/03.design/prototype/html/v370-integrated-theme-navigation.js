/* VET45 Theme 7 v3.7.0 — integrated app navigation + full-theme workbench mode
 * Parent: v3.6.4
 * Goal: preserve the BJ/UIF review harness and add a second workbench tab that starts at
 * VET45 > Them > Kho, then routes into the same cumulative Theme 7 screen renderers.
 * No business renderer is duplicated; both workbench tabs share one runtime/state source.
 */
(()=>{
  const VERSION="3.7.0";
  const qs=new URLSearchParams(window.location.search);
  let workbenchMode=qs.get("mode")==="theme"?"theme":"bj";
  let themeAppRoute=qs.get("app")|| (workbenchMode==="theme"?"more":null);
  if(!["more","inventory","flow"].includes(themeAppRoute)) themeAppRoute=workbenchMode==="theme"?"more":null;

  const FLOW_ENTRY_LABELS={
    "UIF-01":{label:"Tồn kho",subtitle:"Theo dõi tồn, khả dụng và chỉ báo vận hành",icon:"warehouse",group:"overview"},
    "UIF-02":{label:"Nhận hàng mua",subtitle:"Nhận hàng theo chứng từ hoặc nhập nhanh",icon:"cloudUpload",group:"operations"},
    "UIF-05":{label:"Lấy hàng & bàn giao",subtitle:"Chuẩn bị và bàn giao hàng cho đơn bán",icon:"package",group:"operations"},
    "UIF-06":{label:"Hàng khách trả",subtitle:"Tiếp nhận và phân loại hàng khách trả",icon:"rotate",group:"operations"},
    "UIF-07":{label:"Trả nhà cung cấp",subtitle:"Chuẩn bị và thực hiện trả hàng cho nhà cung cấp",icon:"arrowLeft",group:"operations"},
    "UIF-03":{label:"Xác nhận giá nhập",subtitle:"Xác nhận giá trị ban đầu của hàng nhận",icon:"checkCircle",group:"valuation"},
    "UIF-13":{label:"Chi phí mua bổ sung",subtitle:"Ghi nhận chi phí mua phát sinh đến muộn",icon:"fileText",group:"valuation"},
    "UIF-14":{label:"Giá vốn",subtitle:"Tính, rà soát và công bố giá vốn",icon:"layers",group:"valuation"},
    "UIF-08":{label:"Kiểm kê kho",subtitle:"Đếm, duyệt và điều chỉnh chênh lệch",icon:"listCheck",group:"control"},
    "UIF-09":{label:"Tình trạng hàng",subtitle:"Quản lý trạng thái bán, hỏng và dùng thử",icon:"shield",group:"control"},
    "UIF-10":{label:"Tiêu hủy hàng",subtitle:"Kiểm soát và hoàn tất tiêu hủy",icon:"xCircle",group:"control"},
    "UIF-11":{label:"Hủy & sửa sai nghiệp vụ",subtitle:"Xử lý nghiệp vụ kho cần hủy hoặc sửa sai",icon:"edit",group:"control"},
    "UIF-12":{label:"Khởi tạo tồn đầu kỳ",subtitle:"Thiết lập số dư tồn kho ban đầu",icon:"inbox",group:"control"},
    "UIF-16":{label:"Đối soát sai lệch",subtitle:"Điều tra và đối chiếu sai lệch tồn kho",icon:"search",group:"control"},
    "UIF-17":{label:"Xác minh kết quả",subtitle:"Phục hồi nghiệp vụ có kết quả chưa xác định",icon:"rotate",group:"control"},
    "UIF-15":{label:"Báo cáo tồn & thẻ kho",subtitle:"Tra cứu báo cáo tồn và lịch sử biến động",icon:"history",group:"report"},
    "UIF-04":{label:"Giữ hàng theo đơn bán",subtitle:"Xem và quản lý vòng đời hàng đang giữ",icon:"lock",group:"related"},
    "CAP-01":{label:"Chính sách tồn & cận hạn",subtitle:"Thiết lập ngưỡng tồn và chính sách cận hạn",icon:"shield",group:"related"},
  };
  const GROUPS=[
    {id:"overview",title:"Tổng quan"},
    {id:"operations",title:"Vận hành kho"},
    {id:"valuation",title:"Giá trị & giá vốn"},
    {id:"control",title:"Kiểm kê & kiểm soát"},
    {id:"report",title:"Báo cáo"},
    {id:"related",title:"Liên quan & thiết lập"},
  ];

  const originalRenderFlowSelector=renderFlowSelector;
  const originalRenderNavigation=renderNavigation;
  const originalRenderInspector=renderInspector;
  const originalRenderAppScreen=renderAppScreen;
  const originalSyncReviewUrl=syncReviewUrl;
  const originalPreviousScreen=previousScreen;

  function installModeTabs(){
    if(document.querySelector("[data-workbench-tabs]")) return;
    const meta=document.querySelector(".review-meta");
    if(!meta) return;
    const tabs=document.createElement("div");
    tabs.className="workbench-mode-tabs";
    tabs.setAttribute("data-workbench-tabs","");
    tabs.setAttribute("role","tablist");
    tabs.setAttribute("aria-label","Chế độ review");
    tabs.innerHTML=`<button type="button" role="tab" data-workbench-mode="bj">Theo BJ / UIF</button><button type="button" role="tab" data-workbench-mode="theme">Toàn Theme 7</button>`;
    meta.prepend(tabs);
  }

  function updateModeTabs(){
    document.querySelectorAll("button[data-workbench-mode]").forEach(btn=>{
      const active=btn.dataset.workbenchMode===workbenchMode;
      btn.classList.toggle("is-active",active);
      btn.setAttribute("aria-selected",String(active));
    });
    document.body.dataset.workbenchMode=workbenchMode;
  }

  function integratedBottomNav(){
    return `<nav class="t7-app-bottom-nav" aria-label="Điều hướng chính" data-theme-component="VET45BottomNavigation">
      <button type="button" disabled aria-label="Trang chủ">${icon("warehouse","icon--sm")}<span>Trang chủ</span></button>
      <button type="button" disabled aria-label="Bán hàng">${icon("package","icon--sm")}<span>Bán hàng</span></button>
      <button type="button" disabled aria-label="Đơn hàng">${icon("fileText","icon--sm")}<span>Đơn hàng</span></button>
      <button type="button" disabled aria-label="Đối tác">${icon("user","icon--sm")}<span>Đối tác</span></button>
      <button type="button" class="is-active" aria-current="page" data-theme-sidebar-route="more" aria-label="Thêm">${icon("more","icon--sm")}<span>Thêm</span></button>
    </nav>`;
  }

  function integratedAppShell({title,body,back=false}){
    return `<div class="v-page-scaffold figma-calibrated-shell t7-integrated-shell" data-mobile-product data-product-app data-inspectable="true" data-ds-component="VPageScaffold" data-ds-profile="screen.shell.standard" data-ds-prop-title="${escapeAttribute(title)}" data-ds-prop-center-title="false">
      ${statusBar()}
      <header class="app-header"><div class="app-appbar ${back?'has-back':'no-back'}" data-ds-component="VAppBar" data-ds-prop-center-title="false" data-ds-prop-actions="null" data-ds-prop-show-back-button="${back}">
        ${back?`<button class="app-icon-button app-back-button" data-theme-app-back type="button" aria-label="Quay lại" data-ds-internal="VAppBar.leading">${icon("chevronLeft","icon--24")}</button>`:""}
        <div class="app-appbar-copy" data-ds-component="VAppBarTitle"><h3>${esc(title)}</h3></div>
      </div></header>
      <div class="app-content" data-ds-component="VPagePadding" data-ds-profile="screen.body.standard"><div class="body-stack">${body}</div></div>
      ${integratedBottomNav()}
    </div>`;
  }

  function disabledMoreRow(title,subtitle,leading){
    return ds24ListRow({title,subtitle,leading,type:"Navigation",state:"Disabled",disabled:true,attrs:'data-theme-disabled-module="true"',theme:"VET45MoreNavigationRow"});
  }

  function renderMoreScreen(){
    const rows=[
      disabledMoreRow("Khách hàng & NCC","Quản lý khách hàng & nhà cung cấp","user"),
      disabledMoreRow("Đơn nhập","Nhập kho từ nhà cung cấp","cloudUpload"),
      ds24ListRow({title:"Kho",subtitle:"Tồn kho, vận hành, giá vốn và kiểm soát",leading:"warehouse",attrs:'data-theme-app-route="inventory"',theme:"Theme7ModuleEntry"}),
      disabledMoreRow("Báo cáo","Doanh thu, tồn kho, công nợ","history"),
      disabledMoreRow("Giá riêng / Nhớ giá","Giá riêng theo khách hàng và nhớ giá","layers"),
      disabledMoreRow("Người dùng & vai trò","Quản lý thành viên và quyền truy cập","user"),
      disabledMoreRow("Tài khoản của tôi","Xem và chỉnh sửa thông tin cá nhân","user"),
      disabledMoreRow("Thiết lập","Cấu hình hệ thống và hóa đơn điện tử","shield"),
    ].join("");
    return integratedAppShell({title:"Thêm",body:`<section class="ds24-list-stack t7-more-list" data-composed-from="DS v2 / List Row">${rows}</section>`});
  }

  function entryRow(flowId){
    const meta=FLOW_ENTRY_LABELS[flowId];
    const flow=flowCatalog.find(f=>f.id===flowId);
    if(!meta||!flow) return "";
    return ds24ListRow({title:meta.label,subtitle:meta.subtitle,leading:meta.icon,attrs:`data-theme-entry-flow="${flowId}"`,theme:"Theme7ModuleNavigation"});
  }

  function renderInventoryScreen(){
    const sections=GROUPS.map(group=>{
      const ids=Object.entries(FLOW_ENTRY_LABELS).filter(([,m])=>m.group===group.id).map(([id])=>id);
      const rows=ids.map(entryRow).join("");
      return `<section class="t7-module-section" data-ds-component="VSection"><h2 class="t7-module-section-title" data-ds-component="VText" data-ds-prop-style="Label/Default">${esc(group.title)}</h2><div class="ds24-list-stack">${rows}</div></section>`;
    }).join("");
    return integratedAppShell({title:"Kho",back:true,body:`<p class="t7-module-intro" data-ds-component="VText" data-ds-prop-style="Body/Small">Quản lý tồn kho, vận hành kho, giá trị hàng, kiểm kê và kiểm soát.</p>${sections}`});
  }

  function enterThemeFlow(flowId){
    const flow=flowCatalog.find(f=>f.id===flowId);
    if(!flow) return;
    activeFlowId=flow.id;
    activeScreenId=flow.screens[0];
    themeAppRoute="flow";
    syncReviewUrl();
    render();
  }

  function goThemeRoute(route){
    workbenchMode="theme";
    themeAppRoute=route;
    syncReviewUrl();
    render();
  }

  function setWorkbenchMode(mode){
    if(mode===workbenchMode) return;
    workbenchMode=mode;
    if(mode==="theme"){
      if(!["more","inventory","flow"].includes(themeAppRoute)) themeAppRoute="more";
      if(themeAppRoute==null) themeAppRoute="more";
    }else{
      themeAppRoute=null;
    }
    syncReviewUrl();
    render();
  }

  renderFlowSelector=function(){
    if(workbenchMode!=="theme"){
      originalRenderFlowSelector();
      document.body.dataset.workbenchMode="bj";
      updateModeTabs();
      return;
    }
    const f=activeFlow();
    document.body.dataset.workbenchMode="theme";
    document.body.dataset.activeUif=themeAppRoute==="flow"?f.id:"THEME-07-APP";
    const select=document.getElementById("flow-selector");
    if(select) select.innerHTML=flowCatalog.map(x=>`<option value="${x.id}" ${x.id===activeFlowId?'selected':''}>${x.bj} · ${x.name}</option>`).join("");
    const title=themeAppRoute==="more"?"Thêm":themeAppRoute==="inventory"?"Kho":`${f.bj} · ${f.name}`;
    document.getElementById("sidebar-flow-title").textContent=themeAppRoute==="flow"?"Toàn Theme 7 · Đang thao tác":"Toàn Theme 7";
    document.getElementById("sidebar-flow-intent").textContent=themeAppRoute==="flow"?`Đang dùng chung runtime ${f.id}; quay lại Kho để mở nghiệp vụ khác.`:"Đi từ Thêm → Kho và thao tác xuyên toàn bộ Theme 7 trên cùng runtime.";
    document.getElementById("workbench-title").textContent=`Theme 7 · ${title}`;
    document.getElementById("workbench-count").textContent="17 BJ + CAP-01";
    updateModeTabs();
  };

  renderNavigation=function(){
    if(workbenchMode!=="theme") return originalRenderNavigation();
    const navigation=document.getElementById("screen-navigation");
    const rootButtons=`<button class="screen-nav-item ${themeAppRoute==='more'?'is-active':''}" data-theme-sidebar-route="more" type="button"><span class="screen-nav-number">01</span><span class="screen-nav-copy"><strong>Thêm</strong><span>VET45 navigation</span></span><span class="nav-chevron">›</span></button><button class="screen-nav-item ${themeAppRoute==='inventory'?'is-active':''}" data-theme-sidebar-route="inventory" type="button"><span class="screen-nav-number">02</span><span class="screen-nav-copy"><strong>Kho</strong><span>Theme 7 module root</span></span><span class="nav-chevron">›</span></button>`;
    const current=themeAppRoute==="flow"?`<div class="nav-group"><span class="nav-group-label">Đang mở</span><button class="screen-nav-item is-active" type="button" disabled><span class="screen-nav-number">${esc(activeFlow().bj.replace('BJ-','').replace('CAP-','C'))}</span><span class="screen-nav-copy"><strong>${esc(FLOW_ENTRY_LABELS[activeFlowId]?.label||activeFlow().name)}</strong><span>${esc(activeFlowId)}</span></span></button><button class="screen-nav-item" data-theme-sidebar-route="inventory" type="button"><span class="screen-nav-number">←</span><span class="screen-nav-copy"><strong>Về Kho</strong><span>Chọn nghiệp vụ khác</span></span><span class="nav-chevron">›</span></button></div>`:"";
    navigation.innerHTML=`<div class="nav-group"><span class="nav-group-label">Điểm vào</span>${rootButtons}</div>${current}`;
  };

  renderInspector=function(){
    if(workbenchMode!=="theme" || themeAppRoute==="flow"){
      originalRenderInspector();
      if(workbenchMode==="theme"){
        const f=activeFlow();
        document.getElementById("workbench-title").textContent=`Theme 7 · ${FLOW_ENTRY_LABELS[f.id]?.label||f.name}`;
        document.getElementById("workbench-count").textContent="Toàn Theme 7";
      }
      return;
    }
    const isMore=themeAppRoute==="more";
    document.getElementById("current-screen-id").textContent=isMore?"VET45 · NAV-MORE":"THEME-07 · MODULE-ROOT";
    document.getElementById("current-screen-name").textContent=isMore?"Thêm":"Kho";
    document.getElementById("state-switcher").innerHTML='<span class="t7-inspector-static">READY · app navigation</span>';
    document.getElementById("traceability").innerHTML=`<div class="trace-row"><span>Entry</span><strong>${isMore?'Bottom navigation → Thêm':'Thêm → Kho'}</strong></div><div class="trace-row"><span>UI authority</span><strong>Figma DS · VAppBar · DS v2 / List Row</strong></div><div class="trace-row"><span>Runtime</span><strong>Shared with BJ / UIF tab</strong></div><div class="trace-row"><span>Coverage</span><strong>${isMore?'Kho entry':'17 BJ + CAP-01'}</strong></div>`;
    document.getElementById("design-rationale").textContent=isMore?"Tái hiện điểm vào hiện tại của VET45. Chỉ Kho được bật trong phạm vi prototype Theme 7; các module ngoài phạm vi giữ đúng trạng thái Disabled.":"Module root của Theme 7. Các nghiệp vụ được nhóm theo mental model vận hành; tất cả dùng chung renderer và state với tab Theo BJ / UIF.";
  };

  renderAppScreen=function(){
    if(workbenchMode==="theme" && themeAppRoute!=="flow"){
      document.getElementById("app-screen").innerHTML=themeAppRoute==="inventory"?renderInventoryScreen():renderMoreScreen();
      return;
    }
    originalRenderAppScreen();
    if(workbenchMode==="theme" && themeAppRoute==="flow"){
      const flow=activeFlow();
      const isEntry=activeScreenId===flow.screens[0];
      const bar=document.querySelector("#app-screen .app-appbar");
      if(isEntry && bar){
        bar.classList.remove("no-back");
        bar.classList.add("has-back");
        const existingBack=bar.querySelector(".app-back-button");
        if(existingBack){
          existingBack.removeAttribute("data-back");
          existingBack.removeAttribute("data-action");
          existingBack.setAttribute("data-theme-app-back-to-inventory","");
          existingBack.setAttribute("aria-label","Quay về Kho");
        }else{
          bar.insertAdjacentHTML("afterbegin",`<button class="app-icon-button app-back-button" data-theme-app-back-to-inventory type="button" aria-label="Quay về Kho" data-ds-internal="VAppBar.leading">${icon("chevronLeft","icon--24")}</button>`);
        }
      }
    }
  };

  syncReviewUrl=function(){
    originalSyncReviewUrl();
    const url=new URL(window.location.href);
    url.searchParams.set("mode",workbenchMode);
    if(workbenchMode==="theme") url.searchParams.set("app",themeAppRoute||"more");
    else url.searchParams.delete("app");
    history.replaceState(null,"",url);
  };

  previousScreen=function(){
    if(workbenchMode==="theme" && themeAppRoute==="flow"){
      const flow=activeFlow();
      if(activeScreenId===flow.screens[0]) return goThemeRoute("inventory");
    }
    return originalPreviousScreen();
  };

  document.addEventListener("click",event=>{
    const modeBtn=event.target.closest("button[data-workbench-mode]");
    if(modeBtn){event.preventDefault();return setWorkbenchMode(modeBtn.dataset.workbenchMode);}
    if(workbenchMode!=="theme") return;
    const root=event.target.closest("[data-theme-sidebar-route]");
    if(root){event.preventDefault();return goThemeRoute(root.dataset.themeSidebarRoute);}
    const appRoute=event.target.closest("[data-theme-app-route]");
    if(appRoute){event.preventDefault();return goThemeRoute(appRoute.dataset.themeAppRoute);}
    const entry=event.target.closest("[data-theme-entry-flow]");
    if(entry){event.preventDefault();return enterThemeFlow(entry.dataset.themeEntryFlow);}
    if(event.target.closest("[data-theme-app-back]")){event.preventDefault();return goThemeRoute("more");}
    if(event.target.closest("[data-theme-app-back-to-inventory]")){event.preventDefault();return goThemeRoute("inventory");}
  },true);

  installModeTabs();
  const metaBadge=document.querySelector(".review-meta > .review-badge:not(.review-badge--muted)");
  if(metaBadge) metaBadge.textContent="v3.7.0 · integrated Theme 7 · 17 BJ + CAP-01";
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.scenarios=[...(window.__VET45_PROTOTYPE__.scenarios||[]),"dual-workbench-tabs","vet45-more-to-inventory","full-theme-module-router"];
  }
  render();
})();
