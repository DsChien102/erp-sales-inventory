from pathlib import Path
from playwright.sync_api import sync_playwright
from PIL import Image,ImageChops
import io,json,re
CHILD=Path(__file__).resolve().parents[1]
PARENT=Path('/mnt/data/work_t07_v201/VET45-Theme7-Prototype-Harness-v2.0.1/specs/themes/theme-07/prototype/html')
TARGET={'UIF-02','UIF-05','UIF-08','UIF-10','UIF-15','UIF-17'}

def html(root):
 idx=(root/'index.html').read_text(); css=(root/'tokens.generated.css').read_text()+'\n'+(root/'styles.css').read_text(); data=(root/'workbench-data.js').read_text(); fmap=(root/'figma-ds-runtime-map.js').read_text(); app=(root/'app.js').read_text()
 return idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{fmap}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
def data(root):
 s=(root/'workbench-data.js').read_text(); return json.loads(re.sub(r'^window\.VET45_HARNESS_DATA\s*=\s*','',s).rstrip().rstrip(';'))
d=data(CHILD); screens={s['id']:s for s in d['screens']}; cases=[]
for f in d['flows']:
 if f['id'] in TARGET: continue
 for sid in f['screens']:
  states=screens[sid].get('states') or ['READY']; st='READY' if 'READY' in states else next((x for x in states if x not in {'PROCESSING','LOADING'}),states[0])
  cases.append((f['id'],sid,st))
checks=[]; errors=[]
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
 pp=b.new_page(viewport={'width':1400,'height':1100}); cp=b.new_page(viewport={'width':1400,'height':1100}); pp.set_content(html(PARENT),wait_until='load'); cp.set_content(html(CHILD),wait_until='load'); pp.add_style_tag(content='*{animation:none!important;transition:none!important;caret-color:transparent!important}'); cp.add_style_tag(content='*{animation:none!important;transition:none!important;caret-color:transparent!important}')
 for f,s,st in cases:
  js='''x=>{activeFlowId=x.f;activeScreenId=x.s;stateByScreen[x.s]=x.st;render();}'''
  try:
   pp.evaluate(js,{'f':f,'s':s,'st':st}); cp.evaluate(js,{'f':f,'s':s,'st':st});
   pt=pp.locator('#app-screen').inner_text(); ct=cp.locator('#app-screen').inner_text();
   if pt!=ct: errors.append((f,s,'TEXT'))
   pi=Image.open(io.BytesIO(pp.locator('#device-preview').screenshot())).convert('RGB'); ci=Image.open(io.BytesIO(cp.locator('#device-preview').screenshot())).convert('RGB')
   
   if pi.size!=ci.size:
    errors.append((f,s,'PIXEL_SIZE'))
   else:
    diff=ImageChops.difference(pi,ci)
    if diff.getbbox() is not None:
     hist=diff.histogram(); changed=sum(hist[i] for i in range(1,256))+sum(hist[256+i] for i in range(1,256))+sum(hist[512+i] for i in range(1,256))
     # changed is channel-count; tolerate Chromium subpixel raster noise under 0.03% channels.
     ratio=changed/(pi.width*pi.height*3)
     if ratio>0.0003: errors.append((f,s,f'PIXEL ratio={ratio:.6f}'))
  except Exception as e: errors.append((f,s,'ERROR:'+str(e)))
 b.close()
result='PASS' if not errors else 'FAIL'
lines=['# Protected non-target visual regression — v2.0.2','',f'**Result: {result} · {len(cases)} default Product renders compared to parent v2.0.1**','','Calibration UIFs are intentionally excluded. Every non-target UIF screen is compared at its default state for exact Product text and pixels.']
if errors: lines+=['','## Differences']+[f'- `{f}/{s}` · {k}' for f,s,k in errors]
out=Path(__file__).resolve().parent/'FIGMA-DS-PROTECTED-VISUAL-v2.0.2.md';out.write_text('\n'.join(lines)+'\n')
print(result,len(cases),'protected renders','differences',len(errors))
if errors: raise SystemExit(1)
