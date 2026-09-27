from pathlib import Path
from playwright.sync_api import sync_playwright
import re,json
ROOT=Path(__file__).resolve().parents[1];OUT=Path(__file__).resolve().parent
html=(ROOT/'index.html').read_text();styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',html):
 p=ROOT/fn
 if p.exists(): styles.append(p.read_text());html=html.replace(f'<link rel="stylesheet" href="{fn}" />','')
html=html.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']: html=html.replace(f'<script src="{fn}"></script>',f'<script>{(ROOT/fn).read_text()}</script>')
flows=['UIF-01','UIF-02','UIF-04','UIF-05','UIF-08'];checks=[];errors=[]
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
 p=b.new_page(viewport={'width':1600,'height':900});p.on('pageerror',lambda e:errors.append(str(e)));p.set_content(html,wait_until='load')
 for fid in flows:
  ids=p.evaluate('fid=>flowCatalog.find(f=>f.id===fid).screens',fid)
  for sid in ids:
   p.evaluate("([fid,sid])=>{activeFlowId=fid;activeScreenId=sid;stateByScreen[sid]=screens.find(s=>s.id===sid)?.defaultState||'READY';render();}",[fid,sid]);p.wait_for_timeout(10)
   m=p.locator('#app-screen .v-page-scaffold').evaluate('(e)=>({ow:e.offsetWidth,oh:e.offsetHeight,sw:e.scrollWidth})')
   c=p.locator('#app-screen .app-content').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})') if p.locator('#app-screen .app-content').count() else {'sw':0,'cw':0}
   checks.append({'flow':fid,'screen':sid,'pass':m['ow']==402 and m['oh']==874 and m['sw']<=402 and c['sw']<=c['cw']+1,'metrics':{'root':m,'content':c}})
 b.close()
status='PASS' if all(x['pass'] for x in checks) and not errors else 'FAIL'
res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/'PRIOR-BJ-REGRESSION-v2.9.3.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
(OUT/'PRIOR-BJ-REGRESSION-v2.9.3.md').write_text(f'# Prior BJ Regression — v2.9.3\n\n**{status} · {res["passed"]}/{res["total"]} default Product renders · browser errors {len(errors)}**\n')
print(status,res['passed'],res['total'],'errors',len(errors))
for x in checks:
 if not x['pass']:print('FAIL',x)
raise SystemExit(0 if status=='PASS' else 1)
