from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
CAP=OUT/'v291-review-captures'; CAP.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf-8'); styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    p=ROOT/fn
    if p.exists():
        styles.append(p.read_text(encoding='utf-8'))
        idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
    html=html.replace(f'<script src="{fn}"></script>',f'<script>{(ROOT/fn).read_text(encoding="utf-8")}</script>')
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
        if (w,h)==(1366,768): p.screenshot(path=str(CAP/'REVIEW-FIT-1366x768.png'),full_page=False)
        p.close()
    b.close()
status='PASS' if all(c['pass'] for c in checks) else 'FAIL'
res={'status':status,'passed':sum(c['pass'] for c in checks),'total':len(checks),'checks':checks}
(OUT/'REVIEW-WORKBENCH-FIT-QA-v2.9.1.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
(OUT/'REVIEW-WORKBENCH-FIT-QA-v2.9.1.md').write_text('\n'.join(['# Review Workbench Fit QA — v2.9.1','',f'**Result: {status} · {res["passed"]}/{res["total"]}**','']+[f'- {"PASS" if c["pass"] else "FAIL"} — {c["viewport"]}: Product {c["product"][0]}×{c["product"][1]}, review scale {c["reviewScale"]:.4f}, document {c["document"][0]}×{c["document"][1]}' for c in checks])+'\n')
print(status,res['passed'],res['total'])
raise SystemExit(0 if status=='PASS' else 1)
