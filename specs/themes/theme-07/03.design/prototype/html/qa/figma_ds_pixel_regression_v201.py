from pathlib import Path
from playwright.sync_api import sync_playwright
import hashlib,json,io
from PIL import Image
import numpy as np
CHILD=Path(__file__).resolve().parents[1]
PARENT=Path('/mnt/data/work_t07_v201/VET45-Theme7-Prototype-Harness-v2.0.0/specs/themes/theme-07/prototype/html')
OUT=Path(__file__).resolve().parent

def build(root, has_map):
 idx=(root/'index.html').read_text(encoding='utf-8')
 css=(root/'tokens.generated.css').read_text(encoding='utf-8')+'\n'+(root/'styles.css').read_text(encoding='utf-8')+'\n*{animation:none!important;transition:none!important;caret-color:transparent!important}'
 data=(root/'workbench-data.js').read_text(encoding='utf-8'); app=(root/'app.js').read_text(encoding='utf-8')
 h=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
 if has_map:
  mp=(root/'figma-ds-runtime-map.js').read_text(encoding='utf-8'); h=h.replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{mp}</script>')
 return h
parent_html=build(PARENT,False); child_html=build(CHILD,True)
setup='''(x)=>{activeFlowId=x.u;activeScreenId=x.s;if(x.u==="UIF-03"&&x.s==="SCR-017"){val03SelectedReceiptId="VAL03-R1";val03ReviewSourceVersion=val03Current().sourceVersion;}if(x.u==="UIF-13"&&x.s==="SCR-088"){val13SelectedTaskId="LC13-001";if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}if(x.u==="UIF-14"&&x.s==="SCR-076"){val14SelectedRunId="COST-0826";val14PublishReviewVersion=val14Current().inputVersion;}if(x.u==="UIF-08"&&x.s==="SCR-044")stateByScreen[x.s]="BLIND_COUNT";if(x.u==="UIF-08"&&x.s==="SCR-045")stateByScreen[x.s]="RECOUNT_REQUIRED";if(x.u==="UIF-08"&&x.s==="SCR-046")stateByScreen[x.s]="APPROVAL_REQUIRED";if((x.u==="UIF-08"&&x.s==="SCR-047")||((x.u==="UIF-09"||x.u==="UIF-10")&&x.s==="SCR-041"))stateByScreen[x.s]="COMPLETED";if(x.u==="UIF-12"&&x.s==="SCR-071")stateByScreen[x.s]="COMPLETED";if(x.u==="UIF-15"){cf15ReportType="INVENTORY";cf15Product="ALL";if(x.s==="SCR-059")stateByScreen[x.s]="COMPLETED";}render();}'''
fail=[]; total=0; errors=[]
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
 pp=b.new_page(viewport={'width':1400,'height':1100}); cp=b.new_page(viewport={'width':1400,'height':1100})
 pp.on('pageerror',lambda e:errors.append('parent:'+str(e))); cp.on('pageerror',lambda e:errors.append('child:'+str(e)))
 pp.set_content(parent_html,wait_until='load'); cp.set_content(child_html,wait_until='load')
 flows=pp.evaluate('flowCatalog.map(f=>({id:f.id,screens:f.screens}))')
 for f in flows:
  for s in f['screens']:
   total+=1
   try:
    pp.evaluate(setup,{'u':f['id'],'s':s}); cp.evaluate(setup,{'u':f['id'],'s':s})
    pp.locator('#app-screen').evaluate('(e)=>e.scrollTop=0'); cp.locator('#app-screen').evaluate('(e)=>e.scrollTop=0')
    pt=pp.locator('#app-screen').inner_text(); ct=cp.locator('#app-screen').inner_text(); pg=pp.locator('#app-screen').evaluate('(e)=>[e.clientWidth,e.clientHeight,e.scrollWidth,e.scrollHeight]'); cg=cp.locator('#app-screen').evaluate('(e)=>[e.clientWidth,e.clientHeight,e.scrollWidth,e.scrollHeight]')
    if pt!=ct or pg!=cg: fail.append(f'{f["id"]}/{s}: product text/geometry mismatch')
    a=pp.locator('#app-screen').screenshot(animations='disabled'); c=cp.locator('#app-screen').screenshot(animations='disabled')
    if a!=c:
     ai=np.array(Image.open(io.BytesIO(a)).convert('RGB')).astype(int); ci=np.array(Image.open(io.BytesIO(c)).convert('RGB')).astype(int); d=np.abs(ai-ci); pix=int(np.any(d!=0,axis=2).sum()); mean=float(d.mean())
     if pix>500 or mean>0.0015: fail.append(f'{f["id"]}/{s}: material pixel mismatch pixels={pix} mean={mean:.6f} {hashlib.sha256(a).hexdigest()[:10]} != {hashlib.sha256(c).hexdigest()[:10]}')
   except Exception as e: fail.append(f'{f["id"]}/{s}: {e}')
 b.close()
fail += errors
report=['# Phase 2 Product Pixel Regression v2.0.1','',f'**Result: {"PASS" if not fail else "FAIL"} · {total-len(fail)}/{total} active flow/screen renders visually identical to parent v2.0.0 with exact visible text/geometry and only ≤500 antialias-edge pixels / mean channel delta ≤0.0015**','','This gate compares only `#app-screen`; workbench/Inspect metadata is intentionally allowed to change in Phase 2.','','## Failures','']+(['- None.'] if not fail else [f'- {x}' for x in fail[:200]])
(OUT/'FIGMA-DS-PIXEL-REGRESSION-v2.0.1.md').write_text('\n'.join(report)+'\n',encoding='utf-8')
print(('PASS' if not fail else 'FAIL'),total-len(fail),'/',total)
if fail:
 print('\n'.join(fail[:50])); raise SystemExit(1)
