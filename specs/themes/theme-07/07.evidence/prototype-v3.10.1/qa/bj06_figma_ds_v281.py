from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
CAP=OUT/'v281-captures';CAP.mkdir(exist_ok=True)
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css','v253-info-row-live-sync.css','v254-bj02-input-ux-correction.css','v255-bj02-review-density.css','v260-bj04-ds-fidelity.css','v270-bj05-ds-fidelity.css','v271-figma-ds-corrections.css','v272-detail-composition-fidelity.css','v273-ui-hardening.css','v274-figma-ds-hard-gate.css','v275-cross-bj-ds-fidelity.css','v276-bj05-compact-detail.css','v280-bj05-sheet-bj06-figma-ds.css','v281-device-frame-correction.css']
idx=(ROOT/'index.html').read_text();css='\n'.join((ROOT/x).read_text() for x in cssfiles)
html=idx
for x in cssfiles: html=html.replace(f'<link rel="stylesheet" href="{x}" />','')
html=html.replace('</head>',f'<style>{css}</style></head>')
html=(html.replace('<script src="workbench-data.js"></script>',f'<script>{(ROOT/"workbench-data.js").read_text()}</script>').replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{(ROOT/"figma-ds-runtime-map.js").read_text()}</script>').replace('<script src="app.js"></script>',f'<script>{(ROOT/"app.js").read_text()}</script>'))
checks=[]; errors=[]
def chk(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':str(note)})
def rect(p,sel): return p.locator(sel).first.evaluate('(e)=>{const r=e.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height,sw:e.scrollWidth,cw:e.clientWidth,sh:e.scrollHeight,ch:e.clientHeight}}')
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
 p=b.new_page(viewport={'width':1600,'height':900});p.on('pageerror',lambda e:errors.append(str(e)));p.set_content(html,wait_until='load',timeout=30000)
 # Review frame and BJ05 correction
 p.evaluate("()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';io05ActiveLineId='PK-21-01';io05ActiveAllocationId='AL-21-01';activeScreenId='SCR-027';stateByScreen['SCR-027']='READY';render();}")
 prod=p.locator('#app-screen .v-page-scaffold');chk('Product viewport stays 402x874',prod.evaluate('e=>e.offsetWidth')==402 and prod.evaluate('e=>e.offsetHeight')==874)
 chk('Desktop review requires no document scroll',p.evaluate('()=>document.documentElement.scrollHeight<=innerHeight+1'),p.evaluate('()=>[document.documentElement.scrollHeight,innerHeight]'))
 p.locator('[data-io05-open-override="AL-21-01"]').click();p.wait_for_timeout(80)
 sheet=rect(p,'.bj05-lot-sheet');content=rect(p,'.bj05-lot-sheet__content')
 chk('BJ05 lot sheet hugs content',sheet['h']<540 and sheet['h']>content['h'] and sheet['h']-content['h']<120,sheet)
 chk('BJ05 lot sheet has canonical 48x4 handle',abs(rect(p,'.bj05-lot-sheet .sheet-handle')['w']-48*p.evaluate("()=>parseFloat(getComputedStyle(document.querySelector('#device-preview')).getPropertyValue('--vet45-review-scale'))"))<2,rect(p,'.bj05-lot-sheet .sheet-handle'))
 chk('BJ05 lot sheet has no close X',p.locator('.bj05-lot-sheet .sheet-close,.bj05-lot-sheet [aria-label="Đóng"]').count()==0)
 p.locator('#device-preview').screenshot(path=str(CAP/'BJ05-LOT-SHEET-CORRECTED.png'))
 # SCR030
 p.evaluate("()=>{activeFlowId='UIF-06';activeScreenId='SCR-030';io06QueueFilter='ALL';io06Query='';stateByScreen['SCR-030']='READY';render();}")
 rows=p.locator('#app-screen .io06-queue .ds24-list-row');chk('SCR030 uses one List Row Navigation collection',rows.count()==3 and rows.evaluate_all("els=>els.every(e=>e.dataset.dsPropType==='Navigation'&&e.dataset.dsPropDensity==='Default')"))
 chk('SCR030 default filter is Tất cả',p.locator('#app-screen [data-io06-filter="ALL"].is-selected').count()==1)
 chk('SCR030 rows share exact 76px product geometry',rows.evaluate_all('els=>els.every(e=>Math.abs(e.offsetHeight-76)<1)'))
 chk('SCR030 every navigable record keeps chevron',rows.evaluate_all("els=>els.every(e=>e.querySelector('.ds24-list-row__trailing .icon'))"))
 p.locator('#device-preview').screenshot(path=str(CAP/'SCR030-QUEUE.png'))
 # Navigate first request
 p.locator('[data-io06-request="RET-260827-03"]').click();p.wait_for_timeout(60)
 chk('SCR030 request opens SCR031',p.evaluate('()=>activeScreenId')=='SCR-031')
 chk('SCR031 uses grouped Info Row request context',p.locator('#app-screen .io06-context .ds24-info-row').count()==3)
 chk('SCR031 line rows use one Navigation variant',p.locator('#app-screen .io06-return-list .ds24-list-row[data-ds-prop-type="Navigation"]').count()==4)
 p.locator('#device-preview').screenshot(path=str(CAP/'SCR031-REQUEST.png'))
 # Detail line normal path
 p.locator('[data-io06-line="RET-L1A"]').click();p.wait_for_timeout(50)
 chk('SCR032 uses compact Status identity',p.locator('#app-screen [data-layout-role="return-line-context"][data-ds-prop-density="Compact"][data-ds-prop-type="Status"]').count()==1)
 chk('SCR032 uses canonical VTextField',p.locator('#app-screen .io06-field[data-ds-component="VTextField"][data-figma-node="522:7186"]').count()>=1)
 chk('SCR032 LOT options use consistent selection row geometry',p.locator('#app-screen .io06-selection-row').count()==2 and p.locator('#app-screen .io06-selection-row').evaluate_all('els=>els.every(e=>e.offsetHeight===76)'))
 p.locator('[data-io06-qty]').fill('3');p.locator('[data-io06-select-actual-lot="DH2507"]').click();p.wait_for_timeout(40)
 chk('SCR032 normal LOT enables Xong after valid qty and LOT',not p.locator('[data-io06-action="save-return-line"]').is_disabled())
 p.locator('#device-preview').screenshot(path=str(CAP/'SCR032-NORMAL.png'))
 p.locator('[data-io06-action="save-return-line"]').click();p.wait_for_timeout(40)
 chk('SCR032 saves real verification and returns SCR031',p.evaluate('()=>activeScreenId')=='SCR-031' and p.evaluate("()=>io06FindLine('RET-L1A').verified") is True)
 # waiting request: same line row family but disabled state / chevron preserved
 p.evaluate("()=>{io06SelectedRequestId='RET-260827-07';io06ActiveLineId='RET-L6';activeScreenId='SCR-031';stateByScreen['SCR-031']='WAITING_APPROVAL';render();}")
 waitrow=p.locator('#app-screen .io06-return-list .ds24-list-row').first
 chk('SCR031 waiting line stays Navigation Disabled, not a different row type',waitrow.get_attribute('data-ds-prop-type')=='Navigation' and waitrow.get_attribute('data-ds-prop-state')=='Disabled')
 chk('SCR031 disabled navigation retains chevron anatomy',waitrow.locator('.ds24-list-row__trailing .icon').count()==1)
 # Approver list and detail
 p.evaluate("()=>{activeFlowId='UIF-06';activeScreenId='SCR-034';io06ApproverListMode=true;stateByScreen['SCR-034']='TASK_LIST';render();}")
 chk('SCR034 approver queue uses canonical Navigation List Row',p.locator('#app-screen [data-io06-approval-case][data-ds-component="DS v2 / List Row"][data-ds-prop-type="Navigation"]').count()>=1)
 p.locator('#device-preview').screenshot(path=str(CAP/'SCR034-TASK-LIST.png'))
 p.locator('[data-io06-approval-case]').first.click();p.wait_for_timeout(50)
 chk('SCR034 detail uses grouped Info Row facts',p.locator('#app-screen .io06-approval-facts .ds24-info-row').count()>=4)
 p.locator('[data-io06-action="open-reject"]').click();p.wait_for_timeout(50)
 chk('SCR034 reject uses canonical VBottomSheet shell',p.locator('#app-screen .io06-reject-sheet[data-ds-component="VBottomSheet"][data-figma-node="4695:6353"]').count()==1)
 chk('SCR034 reject uses canonical VTextarea',p.locator('#app-screen .io06-reject-sheet [data-ds-component="VTextarea"][data-figma-node="522:7212"]').count()==1)
 p.locator('#device-preview').screenshot(path=str(CAP/'SCR034-REJECT-SHEET.png'))
 # Classification representative request
 p.evaluate("()=>{io06RejectOpen=false;io06SelectedRequestId='RET-260827-05';io06ActiveLineId='RET-L4';activeScreenId='SCR-033';io06ClassificationOpen=false;stateByScreen['SCR-033']='READY';render();}")
 chk('SCR033 classification rows use Navigation List Row consistently',p.locator('#app-screen [data-io06-class-line][data-ds-prop-type="Navigation"]').count()==2)
 p.locator('[data-io06-class-line="RET-L4"]').click();p.wait_for_timeout(40)
 chk('SCR033 item editor uses VBottomSheet',p.locator('#app-screen .io06-classification-sheet[data-ds-component="VBottomSheet"]').count()==1)
 chk('SCR033 editor has four canonical VTextFields',p.locator('#app-screen .io06-classification-sheet .io06-field[data-ds-component="VTextField"]').count()==4)
 p.locator('#device-preview').screenshot(path=str(CAP/'SCR033-CLASSIFICATION-SHEET.png'))
 # no overflow/cut across representative screens
 for sid, setup in [('SCR-030',"io06SelectedRequestId='RET-260827-03';io06ApproverListMode=true"),('SCR-031',"io06SelectedRequestId='RET-260827-03'"),('SCR-032',"io06SelectedRequestId='RET-260827-03';io06ActiveLineId='RET-L1B'"),('SCR-034',"io06ApproverListMode=true"),('SCR-033',"io06SelectedRequestId='RET-260827-05';io06ClassificationOpen=false"),('SCR-035',"io06SelectedRequestId='RET-260827-05'" )]:
  p.evaluate("([sid,setup])=>{eval(setup);activeScreenId=sid;stateByScreen[sid]=screens.find(s=>s.id===sid)?.defaultState||'READY';render();}",[sid,setup]);p.wait_for_timeout(20)
  c=p.locator('#app-screen .app-content').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})')
  chk(f'{sid} has no horizontal content overflow',c['sw']<=c['cw']+1,c)
 chk('No browser errors',not errors,'; '.join(errors[:8]))
 b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/'BJ06-FIGMA-DS-QA-v2.8.1.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
(OUT/'BJ06-FIGMA-DS-QA-v2.8.1.md').write_text('\n'.join(['# BJ06 Figma DS QA — v2.8.1','',f'**Result: {status} · {res["passed"]}/{res["total"]}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f' — {x["note"]}' if x['note'] else '') for x in checks])+'\n')
print(status,res['passed'],res['total'])
for x in checks:
 if not x['pass']:print('FAIL',x['name'],x['note'])
raise SystemExit(0 if status=='PASS' else 1)
