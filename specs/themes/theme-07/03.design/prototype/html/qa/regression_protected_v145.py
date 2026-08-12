from pathlib import Path
from playwright.sync_api import sync_playwright
CUR=Path(__file__).resolve().parents[1]
PAR=Path('/mnt/data/v144_work/VET45-Theme7-Prototype-Harness-v1.4.4/specs/themes/theme-07/prototype/html')
OUT=Path(__file__).resolve().parent
def build(root):
 idx=(root/'index.html').read_text(); css=(root/'tokens.generated.css').read_text()+'\n'+(root/'styles.css').read_text(); data=(root/'workbench-data.js').read_text(); app=(root/'app.js').read_text()
 return idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); pc=b.new_page(viewport={'width':1680,'height':1000}); pp=b.new_page(viewport={'width':1680,'height':1000}); ec=[]; ep=[]; pc.on('pageerror',lambda e:ec.append(str(e))); pp.on('pageerror',lambda e:ep.append(str(e))); pc.set_content(build(CUR),wait_until='load'); pp.set_content(build(PAR),wait_until='load')
 cf=pc.evaluate('flowCatalog.map(f=>({id:f.id,screens:f.screens}))'); pf={x['id']:x['screens'] for x in pp.evaluate('flowCatalog.map(f=>({id:f.id,screens:f.screens}))')}; checks=[]; diffs=[]
 for f in cf:
  if f['id']=='UIF-13': continue
  same=f['screens']==pf.get(f['id']); checks.append((f"{f['id']} topology",same));
  if not same: diffs.append(f"{f['id']} topology {pf.get(f['id'])} -> {f['screens']}"); continue
  for sid in f['screens']:
   js='(x)=>{activeFlowId=x.f;activeScreenId=x.s;if(x.f==="UIF-02"&&x.s==="SCR-009"){flowMode="document";resetBj02Receipt("document");}render();}'
   pc.evaluate(js,{'f':f['id'],'s':sid}); pp.evaluate(js,{'f':f['id'],'s':sid}); a=' '.join(pc.locator('#app-screen').inner_text().split()); z=' '.join(pp.locator('#app-screen').inner_text().split()); ok=a==z;checks.append((f"{f['id']}/{sid} text",ok));
   if not ok: diffs.append(f"{f['id']}/{sid}: rendered text differs")
 checks.append(('current no JS errors',not ec));checks.append(('parent no JS errors',not ep));b.close()
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Protected-flow Exact Regression v1.4.5','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', '- Target UIF13 excluded intentionally.', '- Every other UIF must keep parent v1.4.4 topology and normalized default rendered text.','', '## Diffs',''] + (['- None.'] if not diffs else [f'- {x}' for x in diffs])
(OUT/'REGRESSION-PROTECTED-FLOWS-v1.4.5.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed: print('\n'.join(failed[:40])); raise SystemExit(1)
