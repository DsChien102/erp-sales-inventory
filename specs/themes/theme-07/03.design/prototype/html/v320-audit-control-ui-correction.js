/* VET45 Theme 7 v3.2.0 — Audit & Control UI correction
 * Parent: v3.1.0
 * Scope: BJ08, BJ09, BJ10, BJ11, BJ12, BJ15, BJ16, BJ17.
 * Purpose: remove redundant list headings, remove destructive CTAs from browse/list surfaces,
 * and tighten dense filter/list presentation while preserving all business states and handlers.
 */

const AC320_SCOPE = ["UIF-08","UIF-09","UIF-10","UIF-11","UIF-12","UIF-15","UIF-16","UIF-17"];
const ac320Base = {
  "SCR-042": renderers["SCR-042"],
  "SCR-044": renderers["SCR-044"],
  "SCR-055": renderers["SCR-055"],
  "SCR-056": renderers["SCR-056"],
  "SCR-057": renderers["SCR-057"]
};

function ac320ListCount(count,label="mục") {
  return `<div class="ac320-list-meta" data-ds-component="DS v2 / List Top Bar" data-figma-node="547:2223" data-ds-prop-type="Count"><span>${esc(`${count} ${label}`)}</span></div>`;
}

function ac320SessionRow(){
  return `<div class="ac320-session-record" data-ds-pattern="Session record" data-composed-from="DS v2 / List Row,VBadge">
    ${ac310RecordRow({title:"KK-0709-03",subtitle:"Kho trung tâm · Toàn kho · 12/38 đã đếm",badge:"Đang đếm",tone:"Info",attrs:'data-ic08-action="resume"',leading:null})}
  </div>`;
}

function ac320Render042(state){
  if(activeFlowId!=="UIF-08" || !["READY","PENDING_APPROVAL"].includes(state)) return ac320Base["SCR-042"](state);
  if(state==="PENDING_APPROVAL") return ac320Base["SCR-042"](state);
  const chips=`<div class="ds24-chip-scroll ac320-chip-row" aria-label="Lọc phiên kiểm kê">${ds24Chip("ALL","Tất cả",true,"data-ic08-filter")}${ds24Chip("COUNTING","Đang đếm",false,"data-ic08-filter")}${ds24Chip("APPROVAL","Chờ duyệt",false,"data-ic08-filter")}</div>`;
  const body=`${ds24Search("","","Tìm phiên kiểm kê")}${chips}${ac320SessionRow()}${ic08Overlays()}`;
  return ac310Return(appShell({title:"Kiểm kê kho",body,actions:primaryFooter("Tạo phiên kiểm kê",'data-ic08-action="create"'),back:false}));
}

function ac320Render044(state){
  if(activeFlowId!=="UIF-08" || !["BLIND_COUNT","READY","VALIDATION_ERROR","LOCK_LOST"].includes(state)) return ac320Base["SCR-044"](state);
  const lost=state==="LOCK_LOST";
  const error=state==="VALIDATION_ERROR"?vBanner("error","Chưa nhập đủ kết quả","Nhập số đếm thực tế cho tất cả dòng trước khi nộp."):"";
  const notice=lost?vBanner("warning","Phiên không còn giữ khóa","Số đã nhập được giữ trên thiết bị. Quay về phiên kiểm kê để tải lại trạng thái hiện hành trước khi tiếp tục."):vBanner("info","Đang đếm mù","Chỉ nhập số thực tế. Số theo sổ và chênh lệch chỉ hiển thị sau lần nộp đầu.");
  const groups=[ac310CountGroup({id:"amox",name:"Amox 500",code:"SP-00128",lot:"L2407-A",uom:"hộp",value:ic08Counts.amox,disabled:lost}),ac310CountGroup({id:"glove",name:"Găng tay M",code:"SP-00410",lot:"L2405-M",uom:"hộp",value:ic08Counts.glove,disabled:lost})];
  if(ic08UnexpectedLine) groups.push(ac310CountGroup({id:"unexpected",name:ic08UnexpectedLine.name,code:"Hàng thực tế bổ sung",lot:ic08UnexpectedLine.lot,uom:ic08UnexpectedLine.uom,value:ic08UnexpectedLine.value,unexpected:true,disabled:lost}));
  const body=`${error}${notice}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03"],["Kho","Kho trung tâm"],["Thời điểm chốt","09/09/2026 · 08:00"]])}${ac320ListCount(groups.length,"dòng cần đếm")}<div class="ac310-product-control-list">${groups.join("")}</div>${!lost?`<button class="button button--secondary ac310-inline-button" type="button" data-ic08-action="add-actual-open" data-ds-component="VButton">Thêm hàng thực tế</button>`:""}${ic08Overlays()}`;
  return ac310Return(appShell({title:"Đếm mù",body,actions:lost?primaryFooter("Về phiên kiểm kê",'data-ic08-action="to-list"'):primaryFooter("Nộp kết quả đếm",'data-ic08-action="submit-first"')}));
}

function ac320Render055(state){
  if(activeFlowId!=="UIF-15") return ac320Base["SCR-055"](state);
  const html=ac320Base["SCR-055"](state);
  if(typeof html!=="string") return html;
  const t=document.createElement("template"); t.innerHTML=html;
  const title=[...t.content.querySelectorAll(".ac310-section-title,.ds24-section-title,.io-section-title")].find(x=>x.textContent.trim()==="Sản phẩm");
  if(title) title.remove();
  return t.innerHTML;
}

function ac320Render056(state){
  const html=ac320Base["SCR-056"](state);
  if(!AC320_SCOPE.includes(activeFlowId) || typeof html!=="string") return html;
  const t=document.createElement("template"); t.innerHTML=html;
  const shell=t.content.querySelector('.v-page-scaffold');
  const pageTitle=shell?.dataset.dsPropTitle||"";
  if(pageTitle==="Lịch sử tình trạng"){
    [...t.content.querySelectorAll(".ac310-section-title,.ds24-section-title,.io-section-title")].filter(x=>x.textContent.trim()==="Lịch sử").forEach(x=>x.remove());
  }
  return t.innerHTML;
}

function ac320Render057(state){
  const html=ac320Base["SCR-057"](state);
  if(activeFlowId!=="UIF-15" || typeof html!=="string") return html;
  const t=document.createElement("template"); t.innerHTML=html;
  const shell=t.content.querySelector('.v-page-scaffold');
  const pageTitle=shell?.dataset.dsPropTitle||"";
  if(pageTitle==="Nguồn nghiệp vụ"){
    [...t.content.querySelectorAll(".ac310-section-title,.ds24-section-title,.io-section-title")].filter(x=>x.textContent.trim()==="Dòng thời gian nghiệp vụ").forEach(x=>x.remove());
  }
  return t.innerHTML;
}

renderers["SCR-042"]=ac320Render042;
renderers["SCR-044"]=ac320Render044;
renderers["SCR-055"]=ac320Render055;
renderers["SCR-056"]=ac320Render056;
renderers["SCR-057"]=ac320Render057;

if (AC320_SCOPE.includes(activeFlowId)) render();
