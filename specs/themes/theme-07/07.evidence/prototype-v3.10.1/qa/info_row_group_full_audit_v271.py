from pathlib import Path
from playwright.sync_api import sync_playwright
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text()
for line in list(idx.splitlines()):
    if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line:
        idx=idx.replace(line+'\n','').replace(line,'')
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css','v253-info-row-live-sync.css','v254-bj02-input-ux-correction.css','v255-bj02-review-density.css','v260-bj04-ds-fidelity.css','v270-bj05-ds-fidelity.css','v271-figma-ds-corrections.css']
css='\n'.join((ROOT/x).read_text() for x in cssfiles)
html=idx
for x in cssfiles: html=html.replace(f'<link rel="stylesheet" href="{x}" />','')
html=html.replace('</head>',f'<style>{css}</style></head>')
html=(html.replace('<script src="workbench-data.js"></script>',f'<script>{(ROOT/"workbench-data.js").read_text()}</script>')
          .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{(ROOT/"figma-ds-runtime-map.js").read_text()}</script>')
          .replace('<script src="app.js"></script>',f'<script>{(ROOT/"app.js").read_text()}</script>'))
rows=[]; groups=[]; errors=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.on('pageerror',lambda e:errors.append(str(e))); p.set_content(html,wait_until='load',timeout=30000)
    combos=p.evaluate("()=>flowCatalog.flatMap(f=>f.screens.map(s=>[f.id,s,(screens.find(x=>x.id===s)?.states||['READY']).includes('READY')?'READY':((screens.find(x=>x.id===s)?.states||['READY']).find(x=>!['LOADING','PROCESSING'].includes(x))||'READY')]))")
    for f,s,st in combos:
        p.evaluate("([f,s,st])=>{activeFlowId=f;activeScreenId=s;stateByScreen[s]=st;if(f==='UIF-03'&&s==='SCR-017'){val03SelectedReceiptId='VAL03-R1';val03ReviewSourceVersion=val03Current().sourceVersion;}if(f==='UIF-13'&&s==='SCR-088'){val13SelectedTaskId='LC13-001';if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}if(f==='UIF-14'&&s==='SCR-076'){val14SelectedRunId='COST-0826';val14PublishReviewVersion=val14Current().inputVersion;}render();}",[f,s,st])
        vals=p.locator('[data-ds-component="DS v2 / Info Row"]').evaluate_all("""els=>els.map((e,i)=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e),par=e.parentElement;const sib=[...par.children].filter(x=>x.dataset?.dsComponent==='DS v2 / Info Row').length;let a=par, surface=null, depth=0;while(a && depth<4){const ar=a.getBoundingClientRect(),as=getComputedStyle(a);const bg=as.backgroundColor;const rad=parseFloat(as.borderRadius)||0;if(bg!=='rgba(0, 0, 0, 0)' && ar.width>=330 && ar.width<=373 && rad>=8){surface={tag:a.tagName,cls:a.className,w:ar.width,radius:as.borderRadius,bg};break;}a=a.parentElement;depth++;}return {i,w:r.width,h:r.height,bg:s.backgroundColor,parent:par.className,siblings:sib,surface};})""")
        for v in vals: rows.append({'flow':f,'screen':s,**v})
    b.close()
# Exact row anatomy is universal. Card grouping is required where two or more Info Rows share a direct composition parent.
issues=[]
for r in rows:
    if abs(r['w']-338)>.7 or abs(r['h']-44)>.7 or r['bg']!='rgba(0, 0, 0, 0)':
        issues.append({**r,'issue':'Info Row must remain transparent 338x44'})
    if r['siblings']>=2 and not r['surface']:
        issues.append({**r,'issue':'multi-row composition lacks nearby grouped information surface'})
status='PASS' if rows and not issues and not errors else 'FAIL'
res={'status':status,'instances':len(rows),'issues':issues,'browserErrors':errors}
(OUT/'INFO-ROW-GROUP-FULL-AUDIT-v2.7.1.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
lines=['# Info Row composition full harness audit — v2.7.1','',f'**Result: {status} · {len(rows)} rendered Info Row instances**','', '- Live master: `DS v2 / Info Row` `525:351`.', '- Primitive invariant: each Info Row remains transparent `338×44`.', '- Composition invariant: where two or more rows belong to one direct fact group, a nearby `370px` rounded information surface groups them; no new feature component is invented.','']
if issues: lines += ['## Issues','']+[f"- {x['flow']}/{x['screen']} parent={x['parent']}: {x['issue']}" for x in issues]
else: lines.append('No multi-row Info Row grouping drift was found across the active flow/screen render set.')
if errors: lines += ['','## Browser errors','']+[f'- {e}' for e in errors]
(OUT/'INFO-ROW-GROUP-FULL-AUDIT-v2.7.1.md').write_text('\n'.join(lines)+'\n')
print(status,'instances',len(rows),'issues',len(issues),'errors',len(errors))
if issues:
    for x in issues[:40]: print(x)
if status!='PASS': raise SystemExit(1)
