from pathlib import Path
from playwright.sync_api import sync_playwright
import re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent/'v321-review-captures'; OUT.mkdir(exist_ok=True)
def inline(root):
 h=(root/'index.html').read_text(); css=[]
 for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"\s*/?>',h):
  p=root/fn
  if p.exists(): css.append(p.read_text())
  h=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',h)
 h=h.replace('</head>','<style>'+"\n".join(css)+'</style></head>')
 for fn in re.findall(r'<script src="([^"]+\.js)"></script>',h):
  p=root/fn
  if p.exists(): h=h.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text()}</script>')
 return h
cases=[('BJ08-SCR044','UIF-08','SCR-044','BLIND_COUNT'),('BJ08-SCR045','UIF-08','SCR-045','RECOUNT_REQUIRED'),('BJ09-SCR036','UIF-09','SCR-036','READY'),('BJ07-SCR037','UIF-07','SCR-037','READY')]
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
 p=b.new_page(viewport={'width':1200,'height':1000}); p.set_content(inline(ROOT),wait_until='load')
 for name,u,s,st in cases:
  p.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]=x.st;render()}',{'u':u,'s':s,'st':st})
  p.locator('#app-screen').screenshot(path=str(OUT/f'{name}.png'))
 b.close()
print(OUT)
