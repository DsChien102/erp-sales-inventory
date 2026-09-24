from pathlib import Path
from playwright.sync_api import sync_playwright
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css','v253-info-row-live-sync.css','v254-bj02-input-ux-correction.css','v255-bj02-review-density.css','v260-bj04-ds-fidelity.css','v270-bj05-ds-fidelity.css','v271-figma-ds-corrections.css','v272-detail-composition-fidelity.css','v273-ui-hardening.css','v274-figma-ds-hard-gate.css','v275-cross-bj-ds-fidelity.css','v276-bj05-compact-detail.css','v280-bj05-sheet-bj06-figma-ds.css','v281-device-frame-correction.css']
idx=(ROOT/'index.html').read_text(); css='\n'.join((ROOT/x).read_text() for x in cssfiles)
html=idx
for x in cssfiles: html=html.replace(f'<link rel="stylesheet" href="{x}" />','')
html=html.replace('</head>',f'<style>{css}</style></head>').replace('<script src="workbench-data.js"></script>',f'<script>{(ROOT/"workbench-data.js").read_text()}</script>').replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{(ROOT/"figma-ds-runtime-map.js").read_text()}</script>').replace('<script src="app.js"></script>',f'<script>{(ROOT/"app.js").read_text()}</script>')
checks=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    for w,h in [(1366,768),(1600,900),(1920,1080)]:
        p=b.new_page(viewport={'width':w,'height':h});p.set_content(html,wait_until='load')
        p.evaluate("()=>{activeFlowId='UIF-06';activeScreenId='SCR-030';stateByScreen['SCR-030']='READY';render();fitReviewDeviceToViewport();}");p.wait_for_timeout(60)
        d=p.locator('#device-preview').bounding_box(); pr=p.locator('#app-screen .v-page-scaffold')
        product=[pr.evaluate('e=>e.offsetWidth'),pr.evaluate('e=>e.offsetHeight')]
        doc=[p.evaluate('()=>document.documentElement.scrollWidth'),p.evaluate('()=>document.documentElement.scrollHeight')]
        scale=p.evaluate("()=>parseFloat(getComputedStyle(document.querySelector('#device-preview')).getPropertyValue('--vet45-review-scale'))")
        ok=product==[402,874] and doc[0]<=w+1 and doc[1]<=h+1 and d['x']>=-1 and d['y']>=-1 and d['x']+d['width']<=w+1 and d['y']+d['height']<=h+1
        checks.append({'viewport':f'{w}x{h}','pass':ok,'product':product,'document':doc,'device':d,'reviewScale':scale})
        if (w,h)==(1366,768): p.screenshot(path=str(OUT/'v290-review-captures'/'REVIEW-FIT-1366x768.png'),full_page=False)
        p.close()
    b.close()
status='PASS' if all(c['pass'] for c in checks) else 'FAIL'
res={'status':status,'passed':sum(c['pass'] for c in checks),'total':len(checks),'checks':checks}
(OUT/'REVIEW-WORKBENCH-FIT-QA-v2.9.0.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
(OUT/'REVIEW-WORKBENCH-FIT-QA-v2.9.0.md').write_text('\n'.join(['# Review Workbench Fit QA — v2.9.0','',f'**Result: {status} · {res["passed"]}/{res["total"]}**','']+[f'- {"PASS" if c["pass"] else "FAIL"} — {c["viewport"]}: Product {c["product"][0]}×{c["product"][1]}, review scale {c["reviewScale"]:.4f}, document {c["document"][0]}×{c["document"][1]}' for c in checks])+'\n')
print(status,res['passed'],res['total'])
raise SystemExit(0 if status=='PASS' else 1)
