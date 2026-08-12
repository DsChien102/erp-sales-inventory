from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text()
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css','v253-info-row-live-sync.css','v254-bj02-input-ux-correction.css','v255-bj02-review-density.css','v260-bj04-ds-fidelity.css','v270-bj05-ds-fidelity.css','v271-figma-ds-corrections.css','v272-detail-composition-fidelity.css','v273-ui-hardening.css','v274-figma-ds-hard-gate.css','v275-cross-bj-ds-fidelity.css']
css='\n'.join((ROOT/x).read_text() for x in cssfiles)
html=idx
for x in cssfiles: html=html.replace(f'<link rel="stylesheet" href="{x}" />','')
html=html.replace('</head>',f'<style>{css}</style></head>')
html=(html.replace('<script src="workbench-data.js"></script>',f'<script>{(ROOT/"workbench-data.js").read_text()}</script>')
          .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{(ROOT/"figma-ds-runtime-map.js").read_text()}</script>')
          .replace('<script src="app.js"></script>',f'<script>{(ROOT/"app.js").read_text()}</script>'))
checks=[]; errors=[]
def chk(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':note})
def rect(p,sel):
 return p.locator(sel).first.evaluate('(e)=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {w:r.width,h:r.height,x:r.x,y:r.y,font:s.fontFamily,size:s.fontSize,line:s.lineHeight,weight:s.fontWeight,opacity:s.opacity,display:s.display,overflowX:e.scrollWidth-e.clientWidth}}')
app=(ROOT/'app.js').read_text(); newcss=(ROOT/'v275-cross-bj-ds-fidelity.css').read_text()
chk('BJ05 lot replacement is canonical VBottomSheet, not Form Sheet','class="bottom-sheet bj05-lot-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353"' in app and 'data-ds-pattern="DS v2 / Form Sheet"' not in app[app.find('function bj05OverrideSheet'):app.find('function bj05ResultDetails')])
chunk=app[app.find('function bj05OverrideSheet'):app.find('function bj05ResultDetails')]
chk('Normal BJ05 lot sheet has no top-right close Icon Button','bj05-icon-button' not in chunk and 'close-lot-override' not in chunk)
chk('Lot sheet still dismisses from backdrop contract','data-io05-override-backdrop' in chunk and 'event.target.matches("[data-io05-override-backdrop]")' in app)
chk('All VBottomSheet claims use canonical Figma node 4695:6353', all('data-figma-node="4695:6353"' in x for x in re.findall(r'<section[^>]+data-ds-component="VBottomSheet"[^>]*>',app)), str(len(re.findall(r'<section[^>]+data-ds-component="VBottomSheet"[^>]*>',app))))
chk('Cross-BJ product typography is hard-gated through Figma sans token','[data-mobile-product]' in newcss and 'font-family: var(--figma-font-sans) !important' in newcss)
chk('SCR-028 uses clearer handover wording',all(x in app for x in ['Xác nhận hàng đã giao','Nhập lượng thực tế theo từng lô','Lượng thực giao']))
chk('SCR-028 product units are grouped surfaces with allocation separators','bj05-handover-product' in newcss and 'bj05-handover-allocation +' in newcss)
CAP=OUT/'v275-cross-bj-captures'; CAP.mkdir(exist_ok=True)
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
 def page():
  p=b.new_page(viewport={'width':1440,'height':1100}); p.set_default_timeout(5000); p.on('pageerror',lambda e:errors.append(str(e))); p.set_content(html,wait_until='load',timeout=30000); return p
 # SCR-028 handover visual/geometry
 p=page(); p.evaluate("()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';activeScreenId='SCR-028';stateByScreen['SCR-028']='PARTIAL_ALLOWED';render();}")
 root=p.locator('#app-screen .v-page-scaffold')
 chk('SCR-028 root is 402px product width',abs(rect(p,'#app-screen .v-page-scaffold')['w']-402)<.5,str(rect(p,'#app-screen .v-page-scaffold')))
 cards=p.locator('#app-screen .bj05-handover-product').count(); chk('SCR-028 renders grouped handover product surface',cards>0,str(cards))
 if cards:
  cr=rect(p,'#app-screen .bj05-handover-product'); chk('SCR-028 product surface is 370px and contained',abs(cr['w']-370)<.5 and cr['overflowX']<=.5,str(cr))
 fields=p.locator('#app-screen .bj05-handover-allocation .ds24-field__control').evaluate_all('(els)=>els.map(e=>{const r=e.getBoundingClientRect();return {w:r.width,h:r.height}})')
 chk('SCR-028 handover inputs fit 338px inner content',bool(fields) and all(abs(x['w']-338)<.5 and abs(x['h']-44)<.5 for x in fields),str(fields[:4]))
 p.locator('#app-screen .v-page-scaffold').screenshot(path=str(CAP/'BJ05-SCR028-OPTIMIZED.png')); p.close()
 # BJ05 normal bottom sheet
 p=page(); p.evaluate("()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';io05ActiveLineId='PK-21-01';io05ActiveAllocationId='AL-21-01';activeScreenId='SCR-027';stateByScreen['SCR-027']='READY';render();}"); p.locator('[data-io05-open-override="AL-21-01"]').click()
 sr=rect(p,'#app-screen .bj05-lot-sheet'); chk('BJ05 lot sheet hugs content below near-full Form Sheet height',sr['h']<700 and sr['h']>400,str(sr))
 chk('BJ05 lot sheet has no close control',p.locator('#app-screen .bj05-lot-sheet .bj05-icon-button, #app-screen .bj05-lot-sheet [aria-label="Đóng"]').count()==0)
 tr=rect(p,'#app-screen .bj05-textarea__control'); chk('Lot sheet VTextarea remains canonical 370x88 14/22',abs(tr['w']-370)<.5 and abs(tr['h']-88)<.5 and tr['size']=='14px' and tr['line']=='22px',str(tr))
 title=rect(p,'#app-screen .bj05-lot-sheet .sheet-title h3'); chk('Lot sheet title is Figma H3 18/24 Semi Bold',title['size']=='18px' and title['line']=='24px' and title['weight']=='600' and 'inter' in title['font'].lower(),str(title))
 btn=rect(p,'#app-screen [data-io05-action="confirm-lot-override"]'); chk('Disabled CTA is canonical 370x44 with 0.4 opacity',abs(btn['w']-370)<.5 and abs(btn['h']-44)<.5 and abs(float(btn['opacity'])-.4)<.02,str(btn))
 p.locator('#app-screen .bj05-lot-sheet').screenshot(path=str(CAP/'BJ05-LOT-BOTTOM-SHEET.png')); p.close()
 # all built screens: typography and root overflow, plus content clipping candidates
 p=page(); badfont=[]; over=[]; clipped=[]
 flows=p.evaluate('()=>window.VET45_HARNESS_DATA.flows.map(f=>({id:f.id,screens:f.screens}))')
 for f in flows:
  for sid in f['screens']:
   try:
    p.evaluate("([u,s])=>{activeFlowId=u;activeScreenId=s;stateByScreen[s]=(screens.find(x=>x.id===s)?.states||[]).includes('READY')?'READY':((screens.find(x=>x.id===s)?.states||[])[0]||'READY');render();}",[f['id'],sid])
    vals=p.locator('#app-screen [data-mobile-product]').evaluate('(e)=>{const s=getComputedStyle(e);return {font:s.fontFamily,over:e.scrollWidth-e.clientWidth}}')
    if 'serif' in vals['font'].lower() and 'sans-serif' not in vals['font'].lower(): badfont.append(f['id']+'/'+sid+':'+vals['font'])
    if vals['over']>.5: over.append(f['id']+'/'+sid+':'+str(vals['over']))
    bad=p.locator('#app-screen [data-mobile-product] *').evaluate_all('''els=>els.filter(e=>{const s=getComputedStyle(e);if(s.display==='none'||s.visibility==='hidden')return false;const clip=(s.overflow==='hidden'||s.overflowX==='hidden'||s.overflowY==='hidden');return clip&&(e.scrollWidth-e.clientWidth>1||e.scrollHeight-e.clientHeight>1)&&!e.classList.contains('app-content')}).slice(0,8).map(e=>e.className||e.tagName)''')
    if bad: clipped.append(f['id']+'/'+sid+':'+','.join(map(str,bad)))
   except Exception as ex: errors.append(f"{f['id']}/{sid}: {ex}")
 chk('All 85 built screens avoid UA serif fallback',not badfont,'; '.join(badfont[:10]))
 chk('All 85 built screens avoid product-root horizontal overflow',not over,'; '.join(over[:10]))
 # clipping list is advisory because icon wrappers/ellipsis can intentionally clip; require no known text component classes.
 textclips=[x for x in clipped if any(k in x for k in ['ds24-list-row__copy','v-banner-copy','sheet-title','bj05-handover'])]
 chk('No known DS text container is clipped across built screens',not textclips,'; '.join(textclips[:10]))
 p.close(); b.close()
chk('No browser errors during cross-BJ fidelity QA',not errors,'; '.join(errors[:10]))
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'; res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/'CROSS-BJ-FIGMA-FIDELITY-QA-v2.7.5.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
(OUT/'CROSS-BJ-FIGMA-FIDELITY-QA-v2.7.5.md').write_text('\n'.join(['# Cross-BJ Figma Fidelity QA — v2.7.5','',f'**Result: {status} · {res["passed"]}/{res["total"]} checks**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f' — {x["note"]}' if x['note'] else '') for x in checks])+'\n')
print(status,res['passed'],res['total'])
for x in checks:
 if not x['pass']: print('FAIL',x['name'],x['note'])
raise SystemExit(0 if status=='PASS' else 1)
