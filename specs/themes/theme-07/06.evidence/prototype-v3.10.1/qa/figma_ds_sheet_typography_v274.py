from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text()
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css','v253-info-row-live-sync.css','v254-bj02-input-ux-correction.css','v255-bj02-review-density.css','v260-bj04-ds-fidelity.css','v270-bj05-ds-fidelity.css','v271-figma-ds-corrections.css','v272-detail-composition-fidelity.css','v273-ui-hardening.css','v274-figma-ds-hard-gate.css']
css='\n'.join((ROOT/x).read_text() for x in cssfiles)
html=idx
for x in cssfiles: html=html.replace(f'<link rel="stylesheet" href="{x}" />','')
html=html.replace('</head>',f'<style>{css}</style></head>')
html=(html.replace('<script src="workbench-data.js"></script>',f'<script>{(ROOT/"workbench-data.js").read_text()}</script>')
          .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{(ROOT/"figma-ds-runtime-map.js").read_text()}</script>')
          .replace('<script src="app.js"></script>',f'<script>{(ROOT/"app.js").read_text()}</script>'))
checks=[]; errors=[]
def chk(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':note})
newcss=(ROOT/'v274-figma-ds-hard-gate.css').read_text()
styles=(ROOT/'figma-ds.styles.exact.css').read_text()
app=(ROOT/'app.js').read_text()
chk('Hard-gate CSS contains no raw hex/rgb colors',not re.search(r'#[0-9a-fA-F]{3,8}|rgba?\(',newcss))
chk('Exact text styles keep Inter first with non-serif fallback', 'font-family: Inter, system-ui' in styles and 'font-family: Inter;' not in styles)
chk('Mono exact styles keep canonical mono first with fallback', '"JetBrains Mono", ui-monospace' in styles)
chk('BJ05 override maps exact live Form Sheet node', 'data-ds-pattern="DS v2 / Form Sheet" data-figma-node="1353:6355"' in app)
bottom_claims=re.findall(r'data-ds-component="VBottomSheet"[^>]*',app)
chk('All VBottomSheet claims map canonical live node 4695:6353', bool(bottom_claims) and all('data-figma-node="4695:6353"' in x for x in bottom_claims), f'{len(bottom_claims)} claims')
confirm_claims=re.findall(r'data-ds-component="DS v2 / Confirmation Sheet"[^>]*',app)
chk('All Confirmation Sheet claims map canonical node 550:1058', bool(confirm_claims) and all('data-figma-node="550:1058"' in x for x in confirm_claims), f'{len(confirm_claims)} claims')
keypad_claims=re.findall(r'data-ds-component="VNumericKeypadSheet"[^>]*',app)
chk('All Numeric Keypad claims use canonical master or Quantity variant node', bool(keypad_claims) and all(('data-figma-node="1829:16196"' in x or 'data-figma-node="1829:6657"' in x) for x in keypad_claims), f'{len(keypad_claims)} claims')
chk('BJ05 Form Sheet composes canonical fields/footer/actions', all(x in app[app.find('function bj05OverrideSheet'):app.find('function bj05ResultDetails')] for x in ['DS v2 / Icon Button','DS v2 / List Row','VRadio','VTextarea','DS v2 / Sticky Footer','VButton']))
chk('Primary disabled visual is state opacity, not gray replacement', '.button--primary:disabled' in newcss and 'background: var(--vet45-v2-action-primary-default)' in newcss and 'opacity: var(--vet45-v2-opacity-disabled)' in newcss)

CAP=OUT/'v274-sheet-captures'; CAP.mkdir(exist_ok=True)
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
 def page():
  p=b.new_page(viewport={'width':1440,'height':1100}); p.set_default_timeout(5000); p.on('pageerror',lambda e:errors.append(str(e))); p.set_content(html,wait_until='load',timeout=30000); return p
 def rect(p,sel): return p.locator(sel).first.evaluate('(e)=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {w:r.width,h:r.height,x:r.x,y:r.y,font:s.fontFamily,size:s.fontSize,line:s.lineHeight,weight:s.fontWeight,radius:s.borderRadius,opacity:s.opacity,bg:s.backgroundColor,overflowX:e.scrollWidth-e.clientWidth}}')
 # BJ05 exact Form Sheet
 p=page(); p.evaluate("()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';io05ActiveLineId='PK-21-01';io05ActiveAllocationId='AL-21-01';activeScreenId='SCR-027';stateByScreen['SCR-027']='READY';render();}"); p.locator('[data-io05-open-override="AL-21-01"]').click()
 sr=rect(p,'#app-screen .bj05-form-sheet'); chk('Form Sheet is exactly 402x764',abs(sr['w']-402)<.5 and abs(sr['h']-764)<.5,str(sr))
 for sel,h in [('.bj05-form-sheet__handle-area',24),('.bj05-form-sheet__header',44),('.bj05-form-sheet__intro',40),('.bj05-form-sheet__footer',92)]:
  r=rect(p,'#app-screen '+sel); chk(f'{sel} canonical height {h}',abs(r['h']-h)<.5,str(r))
 hr=rect(p,'#app-screen .bj05-form-sheet__header h3'); chk('Form Sheet title uses H3 18/24 Semi Bold Inter',hr['font'].lower().startswith('inter') and hr['size']=='18px' and hr['line']=='24px' and hr['weight']=='600',str(hr))
 ir=rect(p,'#app-screen .bj05-icon-button'); chk('Form Sheet close uses canonical 44x44 Icon Button',abs(ir['w']-44)<.5 and abs(ir['h']-44)<.5,str(ir))
 tr=rect(p,'#app-screen .bj05-textarea__control'); chk('VTextarea input is exactly 370x88 14/22',abs(tr['w']-370)<.5 and abs(tr['h']-88)<.5 and tr['size']=='14px' and tr['line']=='22px',str(tr))
 br=rect(p,'#app-screen [data-io05-action="confirm-lot-override"]'); chk('Disabled primary button is 370x44 and Opacity/Disabled .4',abs(br['w']-370)<.5 and abs(br['h']-44)<.5 and abs(float(br['opacity'])-.4)<.01 and br['font'].lower().startswith('inter'),str(br))
 chk('Selection rows are a single Default-density geometry',all(abs(x['w']-370)<.5 and abs(x['h']-76)<.5 for x in p.locator('#app-screen [data-io05-select-lot]').evaluate_all('(els)=>els.map(e=>{let r=e.getBoundingClientRect();return {w:r.width,h:r.height}})')))
 p.locator('#app-screen .bj05-form-sheet').screenshot(path=str(CAP/'BJ05-FORM-SHEET-DEFAULT.png'))
 p.locator('[data-io05-select-lot="DH2511"]').click(); p.locator('[data-io05-override-reason]').fill('Lô cũ không còn đủ điều kiện')
 br2=rect(p,'#app-screen [data-io05-action="confirm-lot-override"]'); chk('Enabled primary button returns to full-opacity canonical green state',br2['opacity']=='1',str(br2)); p.locator('#app-screen .bj05-form-sheet').screenshot(path=str(CAP/'BJ05-FORM-SHEET-FILLED.png')); p.close()
 # BJ01 VBottomSheet generic shell
 p=page(); p.evaluate("()=>{activeFlowId='UIF-01';activeScreenId='SCR-003';stateByScreen['SCR-003']='READY';render();}")
 # invoke provenance sheet directly because the public action varies by data
 p.evaluate("()=>{bj01ProvenanceOpen=true;render();}") if p.evaluate("()=>typeof bj01ProvenanceOpen!=='undefined'") else None
 if p.locator('#app-screen [data-ds-component="VBottomSheet"]').count():
  r=rect(p,'#app-screen [data-ds-component="VBottomSheet"]'); chk('BJ01 VBottomSheet keeps 402px canonical shell width',abs(r['w']-402)<.5,str(r)); p.locator('#app-screen [data-ds-component="VBottomSheet"]').first.screenshot(path=str(CAP/'BJ01-BOTTOM-SHEET.png'))
 else: chk('BJ01 VBottomSheet runtime specimen reachable',False,'No sheet rendered')
 p.close()
 # Global computed font sanity across every canonical screen; no serif UA fallback and no horizontal root overflow.
 p=page(); badfont=[]; over=[]
 flows=p.evaluate('()=>window.VET45_HARNESS_DATA.flows.map(f=>({id:f.id,screens:f.screens}))')
 for f in flows:
  for sid in f['screens']:
   try:
    p.evaluate("([u,s])=>{activeFlowId=u;activeScreenId=s;stateByScreen[s]='READY';render();}",[f['id'],sid])
    vals=p.locator('#app-screen .figma-calibrated-shell').evaluate('(e)=>{let s=getComputedStyle(e);return {font:s.fontFamily,overflow:e.scrollWidth-e.clientWidth}}')
    if 'serif' in vals['font'].lower() and 'sans-serif' not in vals['font'].lower(): badfont.append(f['id']+'/'+sid+':'+vals['font'])
    if vals['overflow']>.5: over.append(f['id']+'/'+sid+':'+str(vals['overflow']))
   except Exception as ex: errors.append(f"{f['id']}/{sid}: {ex}")
 chk('All canonical screens avoid UA serif fallback',not badfont,'; '.join(badfont[:10]))
 chk('All canonical screens avoid product-root horizontal overflow',not over,'; '.join(over[:10]))
 p.close(); b.close()
chk('No browser errors during sheet/typography hard gate',not errors,'; '.join(errors[:10]))
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'; res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/'FIGMA-DS-SHEET-TYPOGRAPHY-QA-v2.7.4.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
(OUT/'FIGMA-DS-SHEET-TYPOGRAPHY-QA-v2.7.4.md').write_text('\n'.join(['# Figma DS Sheet + Typography QA — v2.7.4','',f'**Result: {status} · {res["passed"]}/{res["total"]} checks**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f' — {x["note"]}' if x['note'] else '') for x in checks])+'\n')
print(status,res['passed'],res['total'])
for x in checks:
 if not x['pass']: print('FAIL',x['name'],x['note'])
raise SystemExit(0 if status=='PASS' else 1)
