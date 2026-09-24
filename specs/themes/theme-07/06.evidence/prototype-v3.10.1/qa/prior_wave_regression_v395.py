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
 b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'; out={'version':'3.9.5','scope':'Prior locked BJ regression: BJ01 + BJ02 + BJ05 + BJ06','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(QA/'PRIOR-LOCKED-BJ-REGRESSION-v3.9.5.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(QA/'PRIOR-LOCKED-BJ-REGRESSION-v3.9.5.md').write_text('\n'.join(['# Prior Locked BJ Regression — v3.9.5','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','','Scope: BJ01, BJ02, BJ05 and BJ06 protected semantics after BJ07 Atomic Change Set.','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' for x in checks])+'\n',encoding='utf-8')
print(status,out['passed'],out['total'])
if status!='PASS':
 for x in checks:
  if not x['pass']: print('FAIL',x)
 raise SystemExit(1)
