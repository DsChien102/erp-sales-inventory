from pathlib import Path
from playwright.sync_api import sync_playwright
import re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent/'v272-prior-bj-captures'; OUT.mkdir(exist_ok=True)
html=(ROOT/'index.html').read_text()
for line in list(html.splitlines()):
    if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line: html=html.replace(line+'\n','').replace(line,'')
styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',html):
    p=ROOT/fn
    if p.exists(): styles.append(p.read_text()); html=html.replace(f'<link rel="stylesheet" href="{fn}" />','')
html=html.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
    html=html.replace(f'<script src="{fn}"></script>',f'<script>{(ROOT/fn).read_text()}</script>')
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    cases=[
      ('BJ01-SCR003.png',"()=>{activeFlowId='UIF-01';bj01SelectedProductId='P-001';activeScreenId='SCR-003';stateByScreen['SCR-003']='READY';render();}"),
      ('BJ04-SCR021.png',"()=>{activeFlowId='UIF-04';activeScreenId='SCR-021';stateByScreen['SCR-021']='FULL';render();}"),
      ('BJ08-SCR045.png',"()=>{activeFlowId='UIF-08';activeScreenId='SCR-045';stateByScreen['SCR-045']='RECOUNT_REQUIRED';render();}")]
    for name,setup in cases:
      p=b.new_page(viewport={'width':1200,'height':1000}); p.set_content(html,wait_until='load'); p.evaluate(setup); p.locator('#app-screen .v-page-scaffold').screenshot(path=str(OUT/name)); p.close()
    b.close()
print(OUT)
