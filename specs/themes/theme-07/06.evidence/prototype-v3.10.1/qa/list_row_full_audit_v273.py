from pathlib import Path
from playwright.sync_api import sync_playwright
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text()
for line in list(idx.splitlines()):
    if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line:
        idx=idx.replace(line+'\n','').replace(line,'')
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css','v253-info-row-live-sync.css','v254-bj02-input-ux-correction.css','v255-bj02-review-density.css','v260-bj04-ds-fidelity.css','v270-bj05-ds-fidelity.css','v271-figma-ds-corrections.css','v272-detail-composition-fidelity.css','v273-ui-hardening.css']
css='\n'.join((ROOT/x).read_text() for x in cssfiles)
html=idx
for x in cssfiles: html=html.replace(f'<link rel="stylesheet" href="{x}" />','')
html=html.replace('</head>',f'<style>{css}</style></head>')
html=(html.replace('<script src="workbench-data.js"></script>',f'<script>{(ROOT/"workbench-data.js").read_text()}</script>')
          .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{(ROOT/"figma-ds-runtime-map.js").read_text()}</script>')
          .replace('<script src="app.js"></script>',f'<script>{(ROOT/"app.js").read_text()}</script>'))
rows=[]; errors=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.on('pageerror',lambda e:errors.append(str(e))); p.set_content(html,wait_until='load',timeout=30000)
    combos=p.evaluate("()=>flowCatalog.flatMap(f=>f.screens.map(s=>[f.id,s,(screens.find(x=>x.id===s)?.states||['READY']).includes('READY')?'READY':((screens.find(x=>x.id===s)?.states||['READY']).find(x=>!['LOADING','PROCESSING'].includes(x))||'READY')]))")
    for f,s,st in combos:
        p.evaluate("([f,s,st])=>{activeFlowId=f;activeScreenId=s;stateByScreen[s]=st;if(f==='UIF-03'&&s==='SCR-017'){val03SelectedReceiptId='VAL03-R1';val03ReviewSourceVersion=val03Current().sourceVersion;}if(f==='UIF-13'&&s==='SCR-088'){val13SelectedTaskId='LC13-001';if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}if(f==='UIF-14'&&s==='SCR-076'){val14SelectedRunId='COST-0826';val14PublishReviewVersion=val14Current().inputVersion;}render();}",[f,s,st])
        vals=p.locator('[data-ds-component="DS v2 / List Row"]').evaluate_all("els=>els.map((e,i)=>{const r=e.getBoundingClientRect();return {i,type:e.dataset.dsPropType||'',density:e.dataset.dsPropDensity||'',state:e.dataset.dsPropState||'',w:r.width,h:r.height,chevron:!!e.querySelector('[data-ds-icon=\"VIcons.chevronRight\"]'),tag:e.tagName,cls:e.className}})")
        for v in vals: rows.append({'flow':f,'screen':s,**v})
    b.close()
issues=[]
for r in rows:
    if not r['type'] or not r['density'] or not r['state']: issues.append({**r,'issue':'missing variant metadata'})
    exp=76 if r['density']=='Default' else 52 if r['density']=='Compact' else None
    if exp is None: issues.append({**r,'issue':'unknown density'})
    elif abs(r['h']-exp)>.6: issues.append({**r,'issue':f'height {r["h"]} != {exp}'})
    if r['type']=='Navigation' and not r['chevron']: issues.append({**r,'issue':'Navigation missing chevron'})
    if r['type'] in ('Status','Selection') and r['chevron']: issues.append({**r,'issue':f'{r["type"]} must not show chevron'})
status='PASS' if not issues and not errors and rows else 'FAIL'
res={'status':status,'instances':len(rows),'issues':issues,'browserErrors':errors}
(OUT/'LIST-ROW-FULL-AUDIT-v2.7.3.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
lines=['# List Row full harness audit — v2.7.3','',f'**Result: {status} · {len(rows)} rendered List Row instances**','', '- Live master: `DS v2 / List Row` `525:519`.', '- Density invariant: Default 76px; Compact 52px.', '- Affordance invariant: Navigation = chevron; Status = no chevron; Selection = selection control/no chevron.', '- Every claimed instance must declare Type + Density + State.','']
if issues:
    lines += ['## Issues','']+[f"- {x['flow']}/{x['screen']} {x['type']}/{x['density']} {x['cls']}: {x['issue']}" for x in issues]
else: lines.append('No claimed List Row instance drift was found across the active flow/screen render set.')
if errors: lines += ['','## Browser errors','']+[f'- {e}' for e in errors]
(OUT/'LIST-ROW-FULL-AUDIT-v2.7.3.md').write_text('\n'.join(lines)+'\n')
print(status,'instances',len(rows),'issues',len(issues),'errors',len(errors))
if issues:
    for x in issues[:30]: print(x)
if status!='PASS': raise SystemExit(1)
