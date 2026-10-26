/* shared-valuation.js — helpers dùng chung cụm giá trị BJ-03 / 13 (T7-P A5). VAL_UI_461 chỉ còn money / signed / pct cho BJ-13; BJ-14 (v5.19.0) tự dựng không qua helper này. */
function valuationDsTone(tone){const t=String(tone||"Neutral").toLowerCase();return ({success:"Success",warning:"Warning",danger:"Danger",error:"Danger",info:"Info",neutral:"Neutral",brand:"Brand"})[t]||"Neutral";}
function valuationProductHeader({name,code,uom,status="",tone="Neutral",value="",meta=""}){
  const trailing=value?`<span class="valuation-product-value"><small>Giá trị</small><strong>${esc(value)}</strong></span>`:(status?ds24Badge(status,valuationDsTone(tone)):"");
  const subtitle=`${code} · ${uom}${meta?` · ${meta}`:""}`;
  return ds24ListRow({title:name,subtitle,trailing,leading:"package",attrs:'data-layout-role="valuation-product-header" data-ds-role="valuation-product-summary"',type:"Status",density:"Compact",interactive:false});
}
function valuationReadOnlyChild({title,subtitle,trailing=""}){
  return `<div class="valuation-readonly-child" data-composed-from="VText"><span class="valuation-child-branch" aria-hidden="true"></span><span class="valuation-child-copy"><strong>${esc(title)}</strong><small>${esc(subtitle)}</small></span>${trailing?`<span class="valuation-child-trailing">${trailing}</span>`:""}</div>`;
}

/* Định dạng tiền có dấu cho BJ-13 (BJ-03 và BJ-14 dùng t7FmtMoney / hàm riêng; bộ dựng giao diện cũ của bản v461 bỏ ở v5.19.0). */
const VAL_UI_461=(()=>{
  const money=n=>`${Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const signed=n=>`${Number(n||0)>0?'+ ':Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const pct=n=>`${(Number(n||0)*100).toLocaleString('vi-VN',{maximumFractionDigits:1})}%`;
  return {money, signed, pct};
})();
