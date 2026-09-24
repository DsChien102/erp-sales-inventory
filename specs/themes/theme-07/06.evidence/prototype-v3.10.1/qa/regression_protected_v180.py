from pathlib import Path
from playwright.sync_api import sync_playwright
CHILD=Path(__file__).resolve().parents[1]; PARENT=Path('/mnt/data/t07_v170_src/VET45-Theme7-Prototype-Harness-v1.7.0/specs/themes/theme-07/prototype/html'); OUT=Path(__file__).resolve().parent; TARGET={'UIF-12','UIF-15'}
def build(root):
 idx=(root/'index.html').read_text(); css=(root/'tokens.generated.css').read_text()+'\n'+(root/'styles.css').read_text(); data=(root/'workbench-data.js').read_text(); app=(root/'app.js').read_text(); return idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
parent_html,child_html=build(PARENT),build(CHILD); checks=[]; diffs=[]; errors=[]
def ck(n,c): checks.append((n,bool(c)))
def setup(page,h): page.goto('about:blank'); page.set_content(h,wait_until='load'); page.wait_for_timeout(20)
def norm(s): return '\n'.join(x.rstrip() for x in s.strip().splitlines())
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); pp=b.new_page(viewport={'width':1200,'height':950}); cp=b.new_page(viewport={'width':1200,'height':950}); pp.on('pageerror',lambda e:errors.append('parent:'+str(e))); cp.on('pageerror',lambda e:errors.append('child:'+str(e))); setup(pp,parent_html); setup(cp,child_html)
 pflows={x['id']:x['screens'] for x in pp.evaluate('flowCatalog') if x['id'] not in TARGET}; cflows={x['id']:x['screens'] for x in cp.evaluate('flowCatalog') if x['id'] not in TARGET}; ck('Protected flow topology exact',pflows==cflows); total=0
 for fid,sids in pflows.items():
  for sid in sids:
   total+=1
   setup_js='(x)=>{activeFlowId=x.f;activeScreenId=x.s;if(x.f==="UIF-02"&&x.s==="SCR-009"){flowMode="document";resetBj02Receipt("document");}if(x.f==="UIF-03"&&x.s==="SCR-017"){val03SelectedReceiptId="VAL03-R1";val03ReviewSourceVersion=val03Current().sourceVersion;}if(x.f==="UIF-13"&&x.s==="SCR-088"){val13SelectedTaskId="LC13-001";if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}if(x.f==="UIF-14"&&x.s==="SCR-076"){val14SelectedRunId="COST-0826";val14PublishReviewVersion=val14Current().inputVersion;}stateByScreen[x.s]="READY";render();}'
   pp.evaluate(setup_js,{'f':fid,'s':sid}); cp.evaluate(setup_js,{'f':fid,'s':sid}); a=norm(pp.locator('#app-screen').inner_text()); c=norm(cp.locator('#app-screen').inner_text());
   if a!=c: diffs.append(f'{fid}/{sid}')
 ck(f'Protected rendered text exact across {total} screens',not diffs); ck('No page JS errors',not errors); b.close()
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Protected-flow Regression v1.8.0','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} gates · {total} protected renders**','','- Parent: v1.7.0.','- Targets intentionally changed: UIF12, UIF15.','- Every other UIF topology and rendered Product text must remain exact.','','## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if diffs: lines+=['','## Render diffs']+[f'- {x}' for x in diffs]
if errors: lines+=['','## Page errors']+[f'- {x}' for x in errors]
(OUT/'REGRESSION-PROTECTED-FLOWS-v1.8.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8'); print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'protected renders',total)
if failed: print('diffs',diffs[:40]); print('\n'.join(errors[:20])); raise SystemExit(1)
