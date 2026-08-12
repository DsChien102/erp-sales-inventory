from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,hashlib
CHILD=Path(__file__).resolve().parents[1]
PARENT=Path('/mnt/data/work_t07_v212/VET45-Theme7-Prototype-Harness-v2.1.2/specs/themes/theme-07/prototype/html')
OUT=Path(__file__).resolve().parent

def inline(root,child=False):
    idx=(root/'index.html').read_text()
    css=''
    for f in (['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css'] if child else ['tokens.generated.css','styles.css']): css += (root/f).read_text()+'\n'
    idx=re.sub(r'\s*<link rel="stylesheet" href="[^"]+" />','',idx)
    idx=idx.replace('</head>',f'<style>{css}</style></head>')
    for f in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
        idx=idx.replace(f'<script src="{f}"></script>',f'<script>{(root/f).read_text()}</script>')
    return idx

def data(root):
    s=(root/'workbench-data.js').read_text(); return json.loads(re.sub(r'^window\.VET45_HARNESS_DATA\s*=\s*','',s).rstrip().rstrip(';'))
def prep():
    return '''x=>{activeFlowId=x.f;activeScreenId=x.s;stateByScreen[x.s]=x.st;
      if(x.f==='UIF-02'&&x.s==='SCR-009'){flowMode='document';resetBj02Receipt('document');stateByScreen[x.s]=x.st;}
      if(x.f==='UIF-03'&&x.s==='SCR-017'){val03SelectedReceiptId='VAL03-R1';val03ReviewSourceVersion=val03Current().sourceVersion;}
      if(x.f==='UIF-13'&&x.s==='SCR-088'){val13SelectedTaskId='LC13-001';if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}
      if(x.f==='UIF-14'&&x.s==='SCR-076'){val14SelectedRunId='COST-0826';val14PublishReviewVersion=val14Current().inputVersion;}
      render();}'''
d=data(CHILD)
screens={s['id']:s for s in d['screens']}
def pick_state(sid):
    sts=screens[sid].get('states') or ['READY']
    for cand in ['READY','COMPLETED','PENDING_APPROVAL','PERMISSION_DENIED']:
        if cand in sts:return cand
    return sts[0]
cases=[(f['id'],sid,pick_state(sid)) for f in d['flows'] for sid in f['screens']]
parent_html=inline(PARENT,True); child_html=inline(CHILD,True)
mis=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    pp=b.new_page(viewport={'width':1440,'height':1100}); cp=b.new_page(viewport={'width':1440,'height':1100})
    pp.set_content(parent_html,wait_until='load'); cp.set_content(child_html,wait_until='load')
    for p in [pp,cp]: p.add_style_tag(content='*{animation:none!important;transition:none!important;caret-color:transparent!important}')
    for f,s,st in cases:
        pp.evaluate(prep(),{'f':f,'s':s,'st':st}); cp.evaluate(prep(),{'f':f,'s':s,'st':st})
        a=pp.locator('#app-screen').screenshot(); c=cp.locator('#app-screen').screenshot()
        if hashlib.sha256(a).digest()!=hashlib.sha256(c).digest(): mis.append(f'{f}/{s}/{st}')
    b.close()
result='PASS' if not mis else 'FAIL'
text=f'# v2.2.0 DS-runtime Product Visual Regression\n\n**Result: {result} · {len(cases)-len(mis)}/{len(cases)} active flow/screen renders pixel-exact vs v2.1.2**\n\nThe candidate changes only isolated Figma-DS runtime/readiness infrastructure. No UIF/BJ visual replacement is intended here.\n'
if mis: text+='\n## Differences\n'+'\n'.join('- '+x for x in mis)+'\n'
(OUT/'DS-RUNTIME-PRODUCT-VISUAL-REGRESSION-v2.2.0.md').write_text(text)
print(json.dumps({'result':result,'cases':len(cases),'mismatches':mis},ensure_ascii=False))
