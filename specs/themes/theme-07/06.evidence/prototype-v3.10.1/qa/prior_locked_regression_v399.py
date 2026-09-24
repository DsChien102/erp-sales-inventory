#!/usr/bin/env python3
from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]; QA=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf-8'); styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
 p=ROOT/fn
 if p.exists(): styles.append(p.read_text(encoding='utf-8'))
 idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',html):
 p=ROOT/fn.split('?')[0]; html=html.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text(encoding="utf-8")}</script>' if p.exists() else '')
checks=[]; errors=[]
def ck(n,v,note=''): checks.append({'name':n,'pass':bool(v),'note':note})
def goto(p,f,s,st='READY'): p.evaluate('([f,s,st])=>{activeFlowId=f;activeScreenId=s;stateByScreen[s]=st;render();}',[f,s,st])
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); p=b.new_page(viewport={'width':1440,'height':1080}); p.on('pageerror',lambda e:errors.append(str(e))); p.set_content(html,wait_until='load',timeout=30000)
 # BJ01 protected semantic: one list, quantity is metric, LOT detail has physical/eligible and freshness.
 goto(p,'UIF-01','SCR-001'); txt=p.locator('#app-screen').inner_text()
 ck('BJ01 single-list stock entry remains available','Tồn kho' in txt and 'Nobivac DHPPi' in txt and 'Tra cứu' not in txt[:300],txt[:500])
 goto(p,'UIF-01','SCR-003'); txt=p.locator('#app-screen').inner_text()
 ck('BJ01 detail still separates physical/eligible/reserved/available facts',all(x in txt for x in ['Tồn vật lý','Đủ điều kiện','Đã giữ','Khả dụng']),txt[:900])
 # BJ02 protected semantic: review readiness and authoritative accepted total.
 goto(p,'UIF-02','SCR-010'); txt=p.locator('#app-screen').inner_text()
 ck('BJ02 review READY fixture remains actionable',p.locator('.app-actions button:not([disabled])').count()>=1 and 'Còn dòng hàng chưa hoàn tất' not in txt,txt[-700:])
 goto(p,'UIF-02','SCR-011'); txt=p.locator('#app-screen').inner_text()
 ck('BJ02 approval READY remains actionable without English leakage',p.locator('.app-actions button:not([disabled])').count()>=1 and 'Preview' not in txt,txt[-700:])
 # BJ05 protected semantic: allocation/picked/consumed and UNKNOWN verification lock.
 goto(p,'UIF-05','SCR-027');
 if p.locator('[data-io05-pick-allocation="AL-21-01"]').count(): p.locator('[data-io05-pick-allocation="AL-21-01"]').click()
 ck('BJ05 pick editor still uses explicit quantity precision',p.locator('[data-io05-pick-draft]').count()==1 and p.locator('[data-io05-pick-draft]').get_attribute('step')=='1')
 p.evaluate("()=>{const o=io05Orders.find(x=>x.id==='SO-260827-21');o.closed=false;o.queue='ACTIONABLE';io05SelectedOrderId=o.id;activeFlowId='UIF-05';activeScreenId='SCR-029';stateByScreen['SCR-029']='UNKNOWN';render();}")
 btn=p.locator('[data-v350-action="handoff-unknown"]'); op=p.evaluate('()=>io05CurrentOrder().operationId')
 ck('BJ05 UNKNOWN preserves exact operation identity',btn.count()==1 and btn.get_attribute('data-operation')==op,(btn.get_attribute('data-operation') if btn.count() else None,op))
 goto(p,'UIF-05','SCR-025'); row=p.locator('[data-io05-order="SO-260827-21"]')
 ck('BJ05 VERIFYING row remains non-actionable',row.count()==1 and row.get_attribute('aria-disabled')=='true' and 'Đang xác minh bàn giao' in row.inner_text(),row.inner_text() if row.count() else '')
 # BJ06 protected semantic: current return authorization caps receipt, pending approval is read-only, expiry is system-derived, UNKNOWN preserves operation identity.
 p.evaluate("()=>{io06SelectedRequestId='RET-260827-03';io06ActiveLineId='RET-L1A';activeFlowId='UIF-06';activeScreenId='SCR-032';stateByScreen['SCR-032']='READY';render();}")
 txt=p.locator('#app-screen').inner_text(); qty=p.locator('[data-io06-qty]')
 ck('BJ06 current ReturnExchangeLine authorization caps receipt',qty.count()==1 and qty.get_attribute('max')=='3' and 'Được phép nhận lần này' in txt and '3 hộp' in txt,txt[:1200])
 p.evaluate("()=>{io06SelectedRequestId='RET-260827-07';activeFlowId='UIF-06';activeScreenId='SCR-031';stateByScreen['SCR-031']='WAITING';render();}")
 txt=p.locator('#app-screen').inner_text()
 ck('BJ06 WAITING request is true read-only',p.locator('#app-screen [data-io06-line],#app-screen [data-io06-action]').count()==0 and 'chờ' in txt.lower(),txt[:1200])
 p.evaluate("()=>{io06SelectedRequestId='RET-260827-05';io06ActiveLineId='RET-L4';activeFlowId='UIF-06';activeScreenId='SCR-033';stateByScreen['SCR-033']='EXPIRED_GUARD';render();}")
 txt=p.locator('#app-screen').inner_text()
 ck('BJ06 expired quantity remains system-derived and non-editable',('Hết hạn' in txt) and p.locator('[data-io06-class]').count()==0,txt[:1200])
 p.evaluate("()=>{io06SelectedRequestId='RET-260827-03';const r=io06CurrentRequest();activeFlowId='UIF-06';activeScreenId='SCR-035';stateByScreen['SCR-035']='UNKNOWN';render();}")
 req_op=p.evaluate('()=>io06CurrentRequest().operationId'); handoff=p.locator('[data-v350-action="handoff-unknown"]')
 ck('BJ06 UNKNOWN preserves exact operation identity and BJ17 handoff',handoff.count()==1 and handoff.get_attribute('data-operation')==req_op,(handoff.get_attribute('data-operation') if handoff.count() else None,req_op))
 ck('No browser errors across BJ01/BJ02/BJ05/BJ06 regression',not errors,errors)
 # BJ07 protected semantic: source-owned queue/mismatch/finality remain intact.
 p.evaluate("()=>{io07SelectedRequestId='RTV-260827-02';activeFlowId='UIF-07';activeScreenId='SCR-036';stateByScreen['SCR-036']='READY';render();}")
 txt=p.locator('#app-screen').inner_text()
 ck('BJ07 queue remains source-owned with no fake RTV_PENDING CTA','Đưa hàng vào chờ trả' not in txt and 'Chuyển trạng thái' not in txt,txt[:1000])
 p.evaluate("()=>{io07SelectedRequestId='RTV-260827-02';activeFlowId='UIF-07';activeScreenId='SCR-037';stateByScreen['SCR-037']='READY';render();}")
 ck('BJ07 physical verification still uses source allocation identity',p.locator('[data-io07-allocation]').count()>=1)
 p.evaluate("()=>{io07SelectedRequestId='RTV-260827-02';activeFlowId='UIF-07';activeScreenId='SCR-041';stateByScreen['SCR-041']='UNKNOWN';render();}")
 txt=p.locator('#app-screen').inner_text()
 ck('BJ07 UNKNOWN remains non-blind-retry recovery','xác minh' in txt.lower() or 'không xác định' in txt.lower(),txt[:1000])

 # BJ04 protected semantic: reservation remains contextual read-only current facts.
 p.evaluate("()=>{activeFlowId='UIF-04';activeScreenId='SCR-021';stateByScreen['SCR-021']='READY';render();}")
 txt=p.locator('#app-screen').inner_text()
 ck('BJ04 reservation remains read-only current projection','Cần giữ còn lại 16 hộp' in txt and 'Đang giữ 16 hộp' in txt and 'Giữ hàng làm giảm khả dụng' not in txt,txt[:1200])
 ck('BJ04 has no manual mutation action',p.locator('#app-screen [data-io04-action],#app-screen [data-bj04-action]').count()==0)

 # BJ03 protected semantic: complete DirectCostBasis, normalized base-UOM consequence and retired SCR-016.
 p.evaluate("()=>{activeFlowId='UIF-03';val03SelectedReceiptId='VAL03-R1';activeScreenId='SCR-015';stateByScreen['SCR-015']='READY';render();}")
 txt=p.locator('#app-screen').inner_text()
 ck('BJ03 scope still separates presentation group from valuation basis','Nobivac DHPPi' in txt and 'SP-00142 · hộp' in txt and 'Lô DH2507' in txt,txt[:1200])
 p.evaluate("()=>{activeFlowId='UIF-03';val03SelectedReceiptId='VAL03-R1';val03ReviewSourceVersion=val03Current().sourceVersion;activeScreenId='SCR-017';stateByScreen['SCR-017']='READY';render();}")
 txt=p.locator('#app-screen').inner_text()
 ck('BJ03 review still shows normalized base-UOM consequence','Quy đổi lọ' in txt and '8.170 đ/lọ' in txt,txt[:1400])
 routes=p.evaluate("()=>flowCatalog.find(f=>f.id==='UIF-03').screens")
 ck('BJ03 historical SCR-016 remains outside active UIF03 route','SCR-016' not in routes,routes)

 # BJ13 protected semantic: fixed source-owned scope, deterministic allocation and authoritative result remain intact.
 p.evaluate("()=>{activeFlowId='UIF-13';activeScreenId='SCR-085';stateByScreen['SCR-085']='READY';render();}")
 row=p.locator('[data-val13-task="LC13-001"]'); ck('BJ13 actionable late-cost task remains available',row.count()==1 and 'Chi phí vận chuyển' in row.inner_text(),row.inner_text() if row.count() else '')
 row.click(); txt=p.locator('#app-screen').inner_text(); ck('BJ13 fixed source scope remains non-arbitrary',p.locator('[data-val13-target]').count()==0 and 'Phạm vi liên quan' in txt,txt[:1200])
 p.locator('[data-val13-action="scope-to-allocation"]').click(); p.locator('[data-val13-method]').select_option('FIXTURE_VALUE'); txt=p.locator('#app-screen').inner_text(); ck('BJ13 allocation still reconciles full source amount','Tổng phân bổ' in txt and '1.200.000' in txt,txt[:1400])
 p.locator('[data-val13-action="open-review"]').click(); ck('BJ13 review retains a single commit CTA',p.locator('[data-val13-action="confirm-late-cost"]').count()==1)
 p.locator('[data-val13-action="confirm-late-cost"]').click(); txt=p.locator('#app-screen').inner_text(); ck('BJ13 result still marks valuation work dirty','Đã ghi chi phí mua bổ sung' in txt and 'Cần tính lại' in txt,txt[:1600])
 ck('No browser errors across prior locked BJ regression including BJ13',not errors,errors)

 b.close()

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'; out={'version':'3.9.9','scope':'Prior locked regression: BJ01 + Wave 2 (BJ02/BJ05/BJ06/BJ07/BJ04) + BJ03 + BJ13','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(QA/'PRIOR-LOCKED-BJ-REGRESSION-v3.9.9.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(QA/'PRIOR-LOCKED-BJ-REGRESSION-v3.9.9.md').write_text('\n'.join(['# Prior Locked BJ Regression — v3.9.9','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','','Scope: BJ01, locked Wave 2 semantics (BJ02, BJ05, BJ06, BJ07, BJ04), BJ03 and BJ13 after BJ14 Atomic Change Set.','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' for x in checks])+'\n',encoding='utf-8')
print(status,out['passed'],out['total'])
if status!='PASS':
 for x in checks:
  if not x['pass']: print('FAIL',x)
 raise SystemExit(1)
