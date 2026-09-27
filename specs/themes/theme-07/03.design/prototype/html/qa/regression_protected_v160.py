from pathlib import Path
from playwright.sync_api import sync_playwright
CHILD=Path(__file__).resolve().parents[1]
PARENT=Path('/mnt/data/t07_v150/VET45-Theme7-Prototype-Harness-v1.5.0/specs/themes/theme-07/prototype/html')
OUT=Path(__file__).resolve().parent
TARGET={'UIF-08','UIF-09','UIF-10'}
def build(root):
 idx=(root/'index.html').read_text(); css=(root/'tokens.generated.css').read_text()+'\n'+(root/'styles.css').read_text(); data=(root/'workbench-data.js').read_text(); app=(root/'app.js').read_text()
 return idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
parent_html,child_html=build(PARENT),build(CHILD); checks=[]; diffs=[]; errors=[]
def ck(n,c): checks.append((n,bool(c)))
def setup(page,html): page.goto('about:blank'); page.set_content(html,wait_until='load'); page.wait_for_timeout(20)
def norm(s): return '\n'.join(x.rstrip() for x in s.strip().splitlines())
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); pp=b.new_page(viewport={'width':1200,'height':950}); cp=b.new_page(viewport={'width':1200,'height':950}); pp.on('pageerror',lambda e:errors.append('parent:'+str(e))); cp.on('pageerror',lambda e:errors.append('child:'+str(e))); setup(pp,parent_html); setup(cp,child_html)
 pflows={x['id']:x['screens'] for x in pp.evaluate('flowCatalog') if x['id'] not in TARGET}; cflows={x['id']:x['screens'] for x in cp.evaluate('flowCatalog') if x['id'] not in TARGET}
 ck('Protected flow topology exact',pflows==cflows)
 total=0
 for fid,sids in pflows.items():
  for sid in sids:
   total+=1
   for page in (pp,cp): page.evaluate('(x)=>{activeFlowId=x.f;activeScreenId=x.s;if(x.f==="UIF-02"&&x.s==="SCR-009"){flowMode="document";resetBj02Receipt("document");}stateByScreen[x.s]="READY";render();}',{'f':fid,'s':sid})
   a=norm(pp.locator('#app-screen').inner_text()); c=norm(cp.locator('#app-screen').inner_text())
   if a!=c: diffs.append(f'{fid}/{sid}')
 ck(f'Protected rendered text exact across {total} screens',not diffs)
 ck('No page JS errors',not errors); b.close()
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Protected-flow Regression v1.6.0','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} gates · {total} protected renders**','', '- Parent: v1.5.0.', '- Targets intentionally changed: UIF08, UIF09, UIF10.', '- Every other UIF topology and rendered Product text must remain exact.','', '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if diffs: lines+=['','## Render diffs']+[f'- {x}' for x in diffs]
if errors: lines+=['','## Page errors']+[f'- {x}' for x in errors]
(OUT/'REGRESSION-PROTECTED-FLOWS-v1.6.0.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'protected renders',total)
if failed:
 print('diffs',diffs[:30]); print('\n'.join(errors[:10])); raise SystemExit(1)
