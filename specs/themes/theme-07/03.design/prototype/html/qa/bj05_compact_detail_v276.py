from pathlib import Path
from playwright.sync_api import sync_playwright
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text()
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css','v253-info-row-live-sync.css','v254-bj02-input-ux-correction.css','v255-bj02-review-density.css','v260-bj04-ds-fidelity.css','v270-bj05-ds-fidelity.css','v271-figma-ds-corrections.css','v272-detail-composition-fidelity.css','v273-ui-hardening.css','v274-figma-ds-hard-gate.css','v275-cross-bj-ds-fidelity.css','v276-bj05-compact-detail.css']
css='\n'.join((ROOT/x).read_text() for x in cssfiles)
html=idx
for x in cssfiles: html=html.replace(f'<link rel="stylesheet" href="{x}" />','')
html=html.replace('</head>',f'<style>{css}</style></head>')
html=(html.replace('<script src="workbench-data.js"></script>',f'<script>{(ROOT/"workbench-data.js").read_text()}</script>')
          .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{(ROOT/"figma-ds-runtime-map.js").read_text()}</script>')
          .replace('<script src="app.js"></script>',f'<script>{(ROOT/"app.js").read_text()}</script>'))
checks=[]; errors=[]
def chk(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':note})
def r(p,sel): return p.locator(sel).first.evaluate('(e)=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {x:r.x,y:r.y,w:r.width,h:r.height,scrollH:e.scrollHeight,clientH:e.clientHeight,scrollW:e.scrollWidth,clientW:e.clientWidth,overflowY:s.overflowY,transform:s.transform}}')
CAP=OUT/'v276-bj05-captures'; CAP.mkdir(exist_ok=True)
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
 # desktop workbench at user's common 1920x1080-like viewport
 p=b.new_page(viewport={'width':1920,'height':900}); p.on('pageerror',lambda e:errors.append(str(e))); p.set_content(html,wait_until='load',timeout=30000)
 p.evaluate("()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';io05ActiveLineId='PK-21-01';io05ActiveAllocationId='AL-21-01';activeScreenId='SCR-027';stateByScreen['SCR-027']='READY';render();}")
 vp=r(p,'#app-screen .v-page-scaffold'); dev=r(p,'#device-preview'); canvas=r(p,'.stage-canvas')
 chk('Product viewport remains exact 402x874 CSS px',abs(p.locator('#app-screen .v-page-scaffold').evaluate('e=>e.offsetWidth')-402)<.5 and abs(p.locator('#app-screen .v-page-scaffold').evaluate('e=>e.offsetHeight')-874)<.5,str(vp))
 chk('Desktop review phone fits inside visible review canvas without page scroll',dev['y']>=canvas['y']-1 and dev['y']+dev['h']<=900+1 and p.evaluate('()=>document.documentElement.scrollHeight<=innerHeight+1'),f'device={dev}, canvas={canvas}, docH='+str(p.evaluate('()=>document.documentElement.scrollHeight')))
 chk('Review fit uses proportional transform, not product viewport resize',dev['transform']!='none' and abs(dev['w']/dev['h']-(418/890))<.01,str(dev))
 # SCR027 hierarchy / compactness
 product=r(p,'#app-screen .bj05-pick-product-row'); lots=r(p,'#app-screen .bj05-pick-lot-group')
 chk('SCR027 product context uses canonical List Row Status',p.locator('#app-screen .bj05-pick-product-row[data-ds-component="DS v2 / List Row"][data-ds-prop-type="Status"]').count()==1)
 chk('SCR027 product context uses canonical Compact 52px density',abs(product['h']-52*float(p.locator('#device-preview').evaluate("e=>getComputedStyle(e).getPropertyValue('--vet45-review-scale')||1")))<2,str(product))
 allocs=p.locator('#app-screen .bj05-allocation').count(); chk('SCR027 keeps clear per-LOT allocation structure',allocs==2,str(allocs))
 inner_scroll=p.locator('#app-screen .app-content').evaluate('(e)=>({scrollHeight:e.scrollHeight,clientHeight:e.clientHeight,scrollTop:e.scrollTop})')
 chk('SCR027 READY content fits product screen without internal scrolling',inner_scroll['scrollHeight']<=inner_scroll['clientHeight']+1,str(inner_scroll))
 footer=r(p,'#app-screen .app-actions'); chk('SCR027 primary footer remains visible',footer['y']+footer['h']<=dev['y']+dev['h']+1,str(footer))
 p.locator('#device-preview').screenshot(path=str(CAP/'BJ05-SCR027-COMPACT.png'))
 # sheet open
 p.locator('[data-io05-open-override="AL-21-01"]').click()
 p.wait_for_timeout(250)
 sheet=r(p,'#app-screen .bj05-lot-sheet'); chk('Lot replacement sheet hugs content and fits fully',sheet['h']<dev['h']*.86 and sheet['y']>=dev['y']-1 and sheet['y']+sheet['h']<=dev['y']+dev['h']+1,str(sheet))
 chk('Lot sheet still canonical VBottomSheet',p.locator('#app-screen .bj05-lot-sheet[data-ds-component="VBottomSheet"][data-figma-node="4695:6353"]').count()==1)
 chk('Lot sheet has no top-right close CTA',p.locator('#app-screen .bj05-lot-sheet [aria-label="Đóng"], #app-screen .bj05-lot-sheet .bj05-icon-button').count()==0)
 p.locator('#device-preview').screenshot(path=str(CAP/'BJ05-SCR027-LOT-SHEET.png'))
 p.close(); b.close()
chk('No browser errors',not errors,'; '.join(errors[:10]))
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/'BJ05-COMPACT-DETAIL-QA-v2.7.6.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
(OUT/'BJ05-COMPACT-DETAIL-QA-v2.7.6.md').write_text('\n'.join(['# BJ05 Compact Detail QA — v2.7.6','',f'**Result: {status} · {res["passed"]}/{res["total"]} checks**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f' — {x["note"]}' if x['note'] else '') for x in checks])+'\n')
print(status,res['passed'],res['total'])
for x in checks:
 if not x['pass']: print('FAIL',x['name'],x['note'])
raise SystemExit(0 if status=='PASS' else 1)
