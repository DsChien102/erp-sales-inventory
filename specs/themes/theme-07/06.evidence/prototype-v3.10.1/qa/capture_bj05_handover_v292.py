from pathlib import Path
from playwright.sync_api import sync_playwright
import re
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent/'v292-cross-bj-captures'; OUT.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf-8'); styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
 p=ROOT/fn
 if p.exists(): styles.append(p.read_text(encoding='utf-8')); idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
 html=html.replace(f'<script src="{fn}"></script>',f'<script>{(ROOT/fn).read_text(encoding="utf-8")}</script>')
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox']);p=b.new_page(viewport={'width':1600,'height':900});p.set_content(html,wait_until='load')
 p.evaluate("()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';const o=io05CurrentOrder();o.lines.forEach(l=>l.allocations.forEach(a=>a.picked=Math.min(Number(a.qty||0),Math.max(1,Number(a.picked||0)))));activeScreenId='SCR-028';stateByScreen['SCR-028']='PARTIAL_ALLOWED';render();}")
 p.wait_for_timeout(50);p.locator('#device-preview').screenshot(path=str(OUT/'BJ05-SCR028-PRODUCT-SURFACE.png'))
 p.evaluate("()=>{activeFlowId='UIF-06';io06SelectedRequestId='RET-260827-05';const r=io06CurrentRequest();r.classified=true;activeScreenId='SCR-035';stateByScreen['SCR-035']='COMPLETED';render();}")
 p.wait_for_timeout(50);p.locator('#device-preview').screenshot(path=str(OUT/'BJ06-SCR035-PRODUCT-SURFACE.png'))
 b.close()
